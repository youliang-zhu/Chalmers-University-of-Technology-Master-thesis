#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WRITER_STATE="$ROOT_DIR/agents/orchestrator/writer_state.yaml"
REVIEWER_STATE="$ROOT_DIR/agents/orchestrator/reviewer_state.yaml"
STOP_FILE="$ROOT_DIR/agents/orchestrator/STOP"
ORCH_LOCK="$ROOT_DIR/agents/orchestrator/.orch_lock"

CODEX_BIN="${CODEX_BIN:-codex}"
CODEX_MODEL="${CODEX_MODEL:-}"
CODEX_SANDBOX="${CODEX_SANDBOX:-danger-full-access}"
CODEX_BYPASS="${CODEX_BYPASS:-0}"
SLEEP_SECONDS="${ORCH_SLEEP_SECONDS:-30}"
MAX_IDLE="${ORCH_MAX_IDLE:-120}"
MAX_TURNS="${ORCH_MAX_TURNS:-0}"
DRY_RUN=0
ONCE=0

# This is the robust baseline implementation: every role invocation is a fresh,
# synchronous `codex exec` call that reconstructs context from files. Persistent
# role-session reuse can be added later without changing the state protocol.

usage() {
  cat <<'EOF'
Usage: scripts/orchestrator_loop.sh [options]

Options:
  --once              Run at most one eligible Writer/Expert turn, then exit.
  --dry-run           Print the selected action without invoking Codex.
  --sleep SECONDS     Sleep duration when no transition is available. Default: 30.
  --max-idle N        Stop after N idle sleeps. Default: 120.
  --max-turns N       Stop after N role invocations. 0 means unlimited.
  -h, --help          Show this help.

Environment:
  CODEX_BIN           Codex executable. Default: codex.
  CODEX_MODEL         Optional model passed as: -m "$CODEX_MODEL".
  CODEX_SANDBOX       Sandbox mode for codex exec. Default: danger-full-access.
  CODEX_BYPASS        If 1, pass --dangerously-bypass-approvals-and-sandbox.
  ORCH_SLEEP_SECONDS  Same as --sleep.
  ORCH_MAX_IDLE       Same as --max-idle.
  ORCH_MAX_TURNS      Same as --max-turns.

The loop is synchronous: it invokes exactly one role, waits until Codex exits,
then re-reads the state files from disk.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --once)
      ONCE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --sleep)
      SLEEP_SECONDS="${2:?missing value for --sleep}"
      shift 2
      ;;
    --max-idle)
      MAX_IDLE="${2:?missing value for --max-idle}"
      shift 2
      ;;
    --max-turns)
      MAX_TURNS="${2:?missing value for --max-turns}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

yaml_get() {
  local file="$1"
  local key="$2"
  ruby -ryaml -e '
    file, key = ARGV
    data = YAML.load_file(file) || {}
    value = data[key]
    if value.nil?
      exit 0
    elsif value.is_a?(Array)
      puts value.join("\n")
    else
      puts value
    end
  ' "$file" "$key"
}

require_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "Required file missing: $file" >&2
    exit 1
  fi
}

require_int() {
  local name="$1"
  local value="$2"
  if [[ ! "$value" =~ ^[0-9]+$ ]]; then
    echo "Invalid integer for $name: '$value'" >&2
    exit 1
  fi
}

iso_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

writer_prompt() {
  local reason="$1"
  cat <<EOF
You are being invoked by scripts/orchestrator_loop.sh as the WRITER role.

Route selected by orchestrator: $reason

Follow these files as authority:
- agents/control/writer.md
- agents/orchestrator/workflow.md

Minimum required sequence:
1. Read writer.md, workflow.md, agents/project_contexts.md, and both state files.
2. Confirm the selected route from current state.
3. For W0/W4, write or revise the current paper artifact; for W5, mark unresolved issues and
   advance; for W1/W2/W3, do only the state transition.
   For Phase 1 W0, do not rely on stale target-file scaffold content or future section drafts;
   use authoritative NanoMem sources and already passed earlier section plans only.
4. Use agents/orchestrator/.git_lock for all git operations, including the state commit.
5. Atomically update agents/orchestrator/writer_state.yaml and commit it.
6. Exit without polling.

Read the current state files and do exactly ONE Writer unit of work for the selected route.
Respect the Writer hard boundaries. Do not poll. Do not wait for the Expert. Commit as required,
atomically update agents/orchestrator/writer_state.yaml, then exit.
EOF
}

expert_prompt() {
  local reason="$1"
  cat <<EOF
You are being invoked by scripts/orchestrator_loop.sh as the EXPERT role.

Route selected by orchestrator: $reason

Follow these files as authority:
- agents/control/expert.md
- agents/control/spec.md
- agents/orchestrator/workflow.md

Minimum required sequence:
1. Read expert.md, spec.md, workflow.md, agents/project_contexts.md, and both state files.
2. Confirm writer.status=ready_for_review and writer.round_id > reviewer.round_id.
3. Read every artifact listed in writer_state.artifacts.
4. Write exactly one review file under agents/orchestrator/reviews/.
5. Use agents/orchestrator/.git_lock for all git operations, including the state commit.
6. Atomically update agents/orchestrator/reviewer_state.yaml and commit it.
7. Exit without polling.

Read the current state files and do exactly ONE Expert review for the selected route.
Respect the Expert hard boundaries. Do not poll. Do not wait for the Writer. Commit as required,
atomically update agents/orchestrator/reviewer_state.yaml, then exit.
EOF
}

invoke_codex() {
  local role="$1"
  local reason="$2"
  local prompt
  local cmd=("$CODEX_BIN" exec -C "$ROOT_DIR" -s "$CODEX_SANDBOX")

  if [[ -n "$CODEX_MODEL" ]]; then
    cmd+=(-m "$CODEX_MODEL")
  fi
  if [[ "$CODEX_BYPASS" == "1" ]]; then
    cmd+=(--dangerously-bypass-approvals-and-sandbox)
  fi

  case "$role" in
    writer) prompt="$(writer_prompt "$reason")" ;;
    expert) prompt="$(expert_prompt "$reason")" ;;
    *) echo "Unknown role: $role" >&2; exit 1 ;;
  esac

  echo "[$(iso_now)] invoking $role: $reason"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "DRY RUN: would execute: $(printf '%q ' "${cmd[@]}") -"
    return 0
  fi

  printf '%s\n' "$prompt" | "${cmd[@]}" -
}

select_turn() {
  local writer_round="$1"
  local writer_status="$2"
  local reviewer_round="$3"
  local reviewer_verdict="$4"

  if [[ "$writer_status" == "all_complete" ]]; then
    echo "complete:"
  elif [[ "$writer_status" == "drafting" ]]; then
    echo "writer:status=drafting"
  elif [[ "$writer_status" == "ready_for_review" && "$writer_round" -gt "$reviewer_round" ]]; then
    echo "expert:writer ready_for_review and writer.round_id($writer_round) > reviewer.round_id($reviewer_round)"
  elif [[ "$writer_status" == "ready_for_review" && "$writer_round" -eq "$reviewer_round" \
      && ( "$reviewer_verdict" == "pass" || "$reviewer_verdict" == "needs_revision" ) ]]; then
    echo "writer:reviewer verdict=$reviewer_verdict for round_id=$writer_round"
  else
    echo "idle:no valid transition"
  fi
}

main() {
  require_file "$WRITER_STATE"
  require_file "$REVIEWER_STATE"
  command -v ruby >/dev/null 2>&1 || {
    echo "Ruby is required for YAML parsing but was not found in PATH." >&2
    exit 1
  }
  command -v flock >/dev/null 2>&1 || {
    echo "flock is required for orchestrator and git locks but was not found in PATH." >&2
    exit 1
  }
  command -v "$CODEX_BIN" >/dev/null 2>&1 || {
    echo "Codex executable not found: $CODEX_BIN" >&2
    exit 1
  }

  exec 9>"$ORCH_LOCK"
  flock -n 9 || {
    echo "Another orchestrator is already running (lock: $ORCH_LOCK)." >&2
    exit 1
  }

  local idle=0
  local turns=0

  while true; do
    if [[ -f "$STOP_FILE" ]]; then
      echo "[$(iso_now)] stop file exists: $STOP_FILE"
      exit 0
    fi

    local writer_round writer_status reviewer_round reviewer_verdict
    writer_round="$(yaml_get "$WRITER_STATE" round_id)"
    writer_status="$(yaml_get "$WRITER_STATE" status)"
    reviewer_round="$(yaml_get "$REVIEWER_STATE" round_id)"
    reviewer_verdict="$(yaml_get "$REVIEWER_STATE" verdict)"

    require_int "writer_state.round_id" "$writer_round"
    require_int "reviewer_state.round_id" "$reviewer_round"

    local selected role reason
    selected="$(select_turn "$writer_round" "$writer_status" "$reviewer_round" "$reviewer_verdict")"
    role="${selected%%:*}"
    reason="${selected#*:}"

    case "$role" in
      complete)
        echo "[$(iso_now)] writer_state.status is all_complete; exiting."
        exit 0
        ;;
      writer|expert)
        idle=0
        turns=$((turns + 1))
        invoke_codex "$role" "$reason"
        if [[ "$ONCE" -eq 1 ]]; then
          echo "[$(iso_now)] --once requested; exiting after one invocation."
          exit 0
        fi
        if [[ "$MAX_TURNS" -gt 0 && "$turns" -ge "$MAX_TURNS" ]]; then
          echo "[$(iso_now)] reached --max-turns=$MAX_TURNS; exiting."
          exit 0
        fi
        ;;
      idle)
        idle=$((idle + 1))
        echo "[$(iso_now)] idle $idle/$MAX_IDLE: $reason"
        echo "  writer: round=$writer_round status='$writer_status'"
        echo "  reviewer: round=$reviewer_round verdict='$reviewer_verdict'"
        if [[ "$ONCE" -eq 1 || "$DRY_RUN" -eq 1 ]]; then
          exit 0
        fi
        if [[ "$idle" -gt "$MAX_IDLE" ]]; then
          echo "[$(iso_now)] max idle exceeded; stopping." >&2
          exit 1
        fi
        sleep "$SLEEP_SECONDS"
        ;;
      *)
        echo "Unexpected turn selection: $selected" >&2
        exit 1
        ;;
    esac
  done
}

main "$@"
