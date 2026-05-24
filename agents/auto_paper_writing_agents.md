# AUTO PAPER WRITING SYSTEM — DESIGN SPEC

USAGE: roadmap for authoring the agent prompts. NOT loaded at runtime. YAML/paths below are design schema, not prompts.

## 0. SUMMARY
State-machine Writer–Reviewer sync protocol. Writer is the only role that writes paper sources. Expert only reads paper, only writes reviews. They never contend on one file; they exchange signals via two role-exclusive state files. Strictly turn-by-turn. No write conflict by construction.

## 1. INVARIANTS (system correctness depends only on these two)
- INV-1 SINGLE-WRITER: every writable file/dir has exactly one role allowed to write it.
- INV-2 TURN-MUTEX: at any instant only the token holder acts and advances state; the other only reads and waits.

## 2. ROLES
WRITER
- PURPOSE: write thesis content and revise it from Expert feedback.
- MAY WRITE: paper/**, orchestrator/writer_state.yaml
- MAY READ: writer prompt, workflow, project context, own state, reviewer state, Expert reviews, NanoMem source paper/repo/history/code/experiment artifacts.
- SHOULD NOT READ: control/spec.md, Chalmers rules, reference theses, or Expert-only grading resources unless the human explicitly overrides this.
- NEVER: evaluate; touch reviews/ or reviewer_state.yaml
EXPERT
- MAY WRITE: orchestrator/reviews/**, orchestrator/reviewer_state.yaml
- MAY READ: expert prompt, workflow, project context, spec.md, thesis_rules.md, Chalmers rules/sources, reference theses, Writer artifacts, prior reviews/states.
- NEVER: modify paper sources; write anything outside reviews/ and reviewer_state.yaml
HUMAN
- MAY WRITE: resources/**, control/**, paper/** when making manual decisions
- ROLE: provide inputs, define standards/prompts, resolve escalated questions, final arbiter.

## 3. LAYERS & FILES
agents/ and paper/ are siblings under MASTER_THESIS/.

RESOURCE LAYER — agents/resources/ (read-only to agents; human fills before start or provides pointers)
- project_contexts.md short project background; BOTH Writer and Expert read it
- git_history.md      distilled historical commit summary; Writer-facing content source
- thesis_rules.md     official requirements/template; Expert-facing evaluation source
- reference_theses/   3 prior master theses; Expert-facing exemplars
- sources/            downloaded Chalmers source pages/PDFs; Expert-facing evidence
- NOTE: the NanoMem NeurIPS paper, source code, and experiment artifacts are not
  required to be copied here. Writer should locate and read them from the source
  repository `/mnt/models/yupan/llm/nanomem` and its paper directory.

CONTROL LAYER — agents/control/ (identity + standards; mostly static; human writes)
- spec.md             Expert-only rubric / acceptance criteria / target. Derived from thesis_rules.md and reference theses. Writer does not read this directly.
- writer.md           Writer role prompt: how to write, revise from feedback, mark uncertainty, and update writer state
- expert.md           Expert role prompt: how to evaluate against spec/rules/exemplars and produce actionable feedback

ORCHESTRATION LAYER — agents/orchestrator/ (protocol + runtime state)
- workflow.md             phase defs, 3-round rule, handoff/commit conventions (static protocol; human writes)
- writer_state.yaml       WRITER-ONLY signal file
- reviewer_state.yaml     EXPERT-ONLY signal file
- reviews/                EXPERT-ONLY; one markdown per round (pX_sec_rN.md)

EXECUTION LAYER — paper/ (WRITER-ONLY)
- sections_drafts/01_introduction.md .. 05_discussion.md   PHASE-1 product: 5 pure-Chinese planning docs
- Main.tex, include/                               PHASE-2 product: LaTeX body
- figure/                                          figure placeholders (human places real figures)
- refs.bib                                         references (inserted during phase 2)
- Makefile, build/

DIRECTORY TREE
MASTER_THESIS/
  agents/
    resources/ { reference_theses/ sources/ thesis_rules.md git_history.md project_contexts.md }
    control/ { spec.md writer.md expert.md }
    orchestrator/ { workflow.md writer_state.yaml reviewer_state.yaml reviews/ }
    auto_paper_writing_agents.md   # this spec (not runtime)
  paper/
    sections_drafts/ { 01_introduction.md 02_related_work.md 03_methods.md 04_results.md 05_discussion.md }
    Main.tex include/ figure/ build/ refs.bib Makefile

OWNERSHIP (W=write, R=read)
  paper/**              writer:W  expert:R  human:R
  writer_state.yaml     writer:W  expert:R  human:R
  reviews/**            writer:R  expert:W  human:R
  reviewer_state.yaml   writer:R  expert:W  human:R
  project_contexts.md   writer:R  expert:R  human:W
  git_history.md        writer:R  expert:no human:W
  NanoMem source repo   writer:R  expert:no human:W
  thesis_rules.md       writer:no expert:R  human:W
  reference_theses/**   writer:no expert:R  human:W
  sources/**            writer:no expert:R  human:W
  control/spec.md       writer:no expert:R  human:W
  control/writer.md     writer:R  expert:no human:W
  control/expert.md     writer:no expert:R  human:W
  control/workflow.md   writer:R  expert:R  human:W

## 4. STATE PROTOCOL
Two role-exclusive files (so even coordination files satisfy INV-1).

writer_state.yaml (writer-only):
  round_id: int            # global monotonic; logging/ordering only
  phase: 1|2               # 1=Chinese outline, 2=LaTeX body
  section: string          # current section
  section_round: 1..3      # per-section round counter; resets each section; drives escalation
  status: drafting|ready_for_review|revising|escalated|done|all_complete
  artifact: path           # this round's product
  commit_hash: string      # commit of this product
  updated_at: ISO8601

reviewer_state.yaml (expert-only):
  round_id: int            # MUST echo writer's round_id being answered
  phase: 1|2
  section: string
  section_round: 1..3
  verdict: pass|needs_revision
  review_ref: path         # points to reviews/pX_sec_rN.md
  commit_hash: string
  updated_at: ISO8601

RULES
- R1 Turn decided by (round_id alignment) + (status/verdict), NOT by grabbing a shared file.
- R2 Expert acts only when writer.status==ready_for_review AND writer.round_id > expert's last handled round_id. After reviewing, expert sets reviewer_state.round_id := that writer.round_id (means "caught this round").
- R3 Writer acts on a round only after expert produced a verdict for the matching round_id.
- R4 ATOMIC WRITE: always write xxx.yaml.tmp then `mv` over xxx.yaml (atomic on same FS). Reader never sees a half-written file.
- R5 LONG FEEDBACK: each review is its own file reviews/pX_sec_rN.md; state file stores only review_ref. Never append long text to a state file.
- R6 GIT = handoff signal + history. After producing a product: commit, then write commit_hash into own state file.
- R7 COMMIT MSG: [writer|expert][p{phase}][{section}][r{section_round}] {note}, e.g. [expert][p1][intro][r2] needs_revision.
- R8 Same repo, same branch, shared working tree: expert reads working tree directly; commit_hash only confirms snapshot identity + leaves history.

## 5. POLLING / LIVENESS
FINAL DECISION: use one external orchestrator loop, not two independent self-polling agents.

The orchestrator owns liveness. Writer and Expert are role slots. Each slot should
prefer an existing Codex session/process when it is still alive, but must be able
to restart a fresh one if the old session is gone, stuck, or unusable.

Core principle:

```text
Codex session context = accelerator / convenience
filesystem state      = source of truth / durable memory
```

Therefore the system must remain correct even in the worst case where every
Writer or Expert call starts a brand-new Codex process. Persistent sessions are
useful for style continuity and short-term context, but no required state may
exist only inside a Codex conversation.

### 5.1 Single Orchestrator Loop

Run exactly one top-level loop:

```text
scripts/orchestrator_loop.sh
```

The loop repeatedly:

1. reads `agents/orchestrator/writer_state.yaml`;
2. reads `agents/orchestrator/reviewer_state.yaml`;
3. determines whose turn it is from `round_id`, `status`, and `verdict`;
4. invokes the correct role slot once;
5. sleeps briefly;
6. exits only when `writer_state.status == all_complete` or a human stop guard fires.

No Writer and Expert process should independently decide to run forever. They do
one unit of work when invoked, update their own state file atomically, commit, and
return control to the orchestrator.

### 5.2 Role Slots With Restart Fallback

There are exactly two logical slots:

```text
writer_slot
expert_slot
```

For each role invocation, the orchestrator follows this rule:

```text
if the role's existing Codex session/process is alive and accepts input:
    send this turn's task to that existing role session
else:
    start a new Codex process/session for that role
    the new process reconstructs context from files
```

This gives the desired behavior:

- best case: the same Writer and Expert sessions continue across many rounds and
  keep useful working context;
- fallback case: a dead or exhausted session is replaced automatically;
- worst case: every turn starts a fresh process, and the system still works
  because all state is stored in files.

### 5.3 Turn Decision

The orchestrator must not trigger work by checking whether a new file exists.
It must trigger work by reading the state fields.

Writer should run when one of these is true:

- `writer_state.status == drafting`;
- `writer_state.status == revising`;
- `reviewer_state.round_id == writer_state.round_id` and
  `reviewer_state.verdict == pass`;
- `reviewer_state.round_id == writer_state.round_id` and
  `reviewer_state.verdict == needs_revision`.

Expert should run when:

- `writer_state.status == ready_for_review`; and
- `writer_state.round_id > reviewer_state.round_id`.

The orchestrator should do nothing except sleep when no valid transition is
available.

### 5.4 Orchestrator Pseudocode

```bash
while true; do
  read writer_state.yaml
  read reviewer_state.yaml

  if writer.status == "all_complete"; then
    exit 0
  fi

  if writer.status in {"drafting", "revising"}; then
    invoke_writer_slot_once

  elif writer.status == "ready_for_review" \
       && writer.round_id > reviewer.round_id; then
    invoke_expert_slot_once

  elif reviewer.round_id == writer.round_id \
       && reviewer.verdict in {"pass", "needs_revision"}; then
    invoke_writer_slot_once

  else
    sleep 30
  fi
done
```

### 5.5 What Each Role Does When Invoked

Writer invocation:

1. read `agents/control/writer.md`;
2. read `agents/orchestrator/workflow.md`;
3. read `agents/resources/project_contexts.md`;
4. read both state files;
5. read the relevant review file if responding to a review;
6. read Writer-facing NanoMem content sources as needed:
   - NeurIPS paper repo `/mnt/models/yupan/llm/nanomem/paper`;
   - historical commit summary;
   - source code and experiment artifacts under `/mnt/models/yupan/llm/nanomem`;
7. write only Writer-owned files;
8. commit;
9. atomically update `writer_state.yaml`;
10. exit.

Writer must not read `agents/control/spec.md` as its normal input. The Expert is
responsible for translating spec/rule/exemplar failures into concrete review
feedback. Writer follows the feedback rather than grading itself against the
rubric.

Expert invocation:

1. read `agents/control/spec.md`;
2. read `agents/control/expert.md`;
3. read `agents/orchestrator/workflow.md`;
4. read `agents/resources/project_contexts.md`;
5. read Expert-facing evaluation sources as needed:
   - `agents/resources/thesis_rules.md`;
   - Chalmers official downloaded sources under `agents/resources/sources/`;
   - reference theses under `agents/resources/reference_theses/`;
6. read both state files;
7. read the artifact identified by `writer_state.artifact`;
8. write exactly one review file under `agents/orchestrator/reviews/`;
9. commit;
10. atomically update `reviewer_state.yaml`;
11. exit.

### 5.6 Required Durable Context

Because sessions may be restarted at any time, every new Writer/Expert process
must be able to reconstruct context from files. The context is role-specific.

Writer restart context:

```text
agents/control/writer.md
agents/orchestrator/workflow.md
agents/orchestrator/writer_state.yaml
agents/orchestrator/reviewer_state.yaml
agents/orchestrator/reviews/**
agents/resources/project_contexts.md
agents/resources/git_history.md
/mnt/models/yupan/llm/nanomem/paper
/mnt/models/yupan/llm/nanomem
paper/sections_drafts/**
paper/**
git log
```

Expert restart context:

```text
agents/control/spec.md
agents/control/expert.md
agents/orchestrator/workflow.md
agents/orchestrator/writer_state.yaml
agents/orchestrator/reviewer_state.yaml
agents/orchestrator/reviews/**
agents/resources/project_contexts.md
agents/resources/thesis_rules.md
agents/resources/sources/**
agents/resources/reference_theses/**
writer_state.artifact
git log
```

### 5.7 Git Lock

Even with one orchestrator, keep a git lock around commits to make failures
recoverable and to protect against accidental manual concurrent commits:

```text
agents/orchestrator/.git_lock
```

Before any role commits, it should acquire the lock with `flock`. If commit
fails because of `.git/index.lock`, retry with backoff instead of deleting locks
blindly.

### 5.8 Terminal Conditions

The loop stops when:

- `writer_state.status == all_complete`; or
- a human stop file exists, e.g. `agents/orchestrator/STOP`; or
- a max-walltime/max-idle guard triggers.

The final complete state is:

```text
phase == 2
section == discussion
status == all_complete
```

The Expert does not need its own persistent loop. It is invoked only by the
orchestrator when a review is needed.

## 6. WORKFLOW
PHASES (same protocol, different product target):
- PHASE 1: write the 5 pure-Chinese planning docs in paper/sections_drafts/. Each doc plans: section breakdown, per-subsection content, which figures/tables go where (figures: plan position + rationale only, do NOT generate; tables: may generate), target ~15 figures distributed across the thesis. English technical terms are allowed only when they are natural terminology, but the planning prose should be Chinese. Each doc runs its own ping-pong; advance to next doc only on pass. 5 docs done => phase 1 ends.
- PHASE 2: write LaTeX body following the phase-1 docs, starting from introduction; advance per-section on pass; insert references inline. Ignore acknowledgements etc. for now.

PER-SECTION PING-PONG (one round):
  writer: drafting -> produce -> commit -> writer_state:ready_for_review(round_id, commit_hash) -> wait
  expert: read product + spec -> write reviews/pX_sec_rN.md -> commit -> reviewer_state:verdict+review_ref(same round_id) -> wait
  writer: verdict==pass                          -> next section / next phase
          verdict==needs_revision & section_round<3  -> revising (section_round+1) -> repeat
          verdict==needs_revision & section_round==3 -> ESCALATE

ESCALATION (3-round cap):
  1. WRITER reads Expert's round-3 review and keeps unresolved issues in the artifact itself at the relevant location.
  2. Use `NOTSURE:` for uncertain facts, unclear arguments, unresolved wording, or places requiring human/advisor judgment.
  3. Use `TODO:` for missing figures, tables, citations, experiment numbers, implementation checks, or other concrete unfinished work.
  4. In LaTeX body, mark these visibly, e.g. `\textcolor{red}{NOTSURE: ...}` or `\textcolor{red}{TODO: ...}`.
  5. WRITER sets that section status=escalated, does NOT block, advances to next section, continues.
  RATIONALE: unresolved issues remain in their local writing context instead of being detached into a separate open-questions file.

STATE MACHINE (section level), transitions:
  drafting --ready_for_review--> reviewing
  reviewing --pass--> done -> next section/phase
  reviewing --needs_revision & round<3--> revising --> drafting(next round)
  reviewing --needs_revision & round==3--> escalated (mark NOTSURE/TODO in artifact, advance)

## 7. CONFLICT-SAFETY (four layers; any one ~suffices, stacked = robust)
- D1 SINGLE-WRITER (physical isolation): writer-write-set and expert-write-set are disjoint; paper body writable only by writer; concurrent writes target different files; read-read never conflicts.
- D2 TURN-MUTEX: round_id alignment + status/verdict => only holder acts.
- D3 ATOMIC WRITE: .tmp + mv => no half-read.
- D4 GIT-LOCK MITIGATION: flock / retry-backoff covers accidental concurrent manual commits or role-process restart edge cases.

## 8. PROMPT-AUTHORING CHECKLISTS (what each doc must cover; not the prompt text)
control/spec.md:
- Expert-only grading rubric; Writer does not read it during normal operation
- per-chapter "passing definition": required elements, required logic chain
- conference->thesis EXPANSION directions: systematic related work; add preliminaries/background; full method derivation; fuller experiments (ablations + more baselines); expanded discussion; Chinese academic writing norms; format + length
- figure/table norms: ~15 figures distribution; figures planned (position + why) not generated; tables may be generated
- citation rule: verifiable sources only; mark TODO rather than fabricate bibkeys
- review scoring dimensions: expert must check item-by-item and give ACTIONABLE edits, not vague praise
- evidence requirement: Expert should cite the basis for important criticism, e.g. Chalmers rules, reference thesis pattern, spec item, or project context
- treat as LIVING DOC: refill from gaps exposed by v1; do not aim for one-shot perfection

control/writer.md:
- boundary: WRITE ONLY; only own files; never evaluate; never touch reviews/ or reviewer_state.yaml
- do not read spec.md, thesis rules, or reference theses during normal operation; rely on Expert review for standards feedback
- read project_contexts.md every invocation; read NanoMem NeurIPS paper/repo/history/code/experiment artifacts as content sources
- Phase 1 output must be pure Chinese planning prose in paper/sections_drafts/
- when uncertain, mark in-place with NOTSURE; when missing concrete material, mark in-place with TODO
- fixed invocation sequence: read protocol -> read reviewer_state -> decide action -> work if assigned -> exit
- behavior: atomic write; commit + write commit_hash; commit-msg format; git-lock retry; no self-polling loop
- escalation handling: keep unresolved issues as in-place NOTSURE/TODO markers, set escalated, advance, do not block

control/expert.md:
- persona: strict master-thesis advisor; EVALUATE ONLY, never edit
- anchor to objective standards: score item-by-item vs spec.md + thesis_rules.md + 3 exemplars
- read project_contexts.md every invocation so reviews remain aligned with the NanoMem thesis goal
- output: specific actionable edits; explicit pass / needs_revision
- every important criticism must explain: problem, why it is a problem, evidence/basis, and concrete revision instruction
- Expert may mention the rule/reference basis in the review so Writer can revise without reading the Expert-only sources directly
- fixed invocation sequence; atomic write; review as its own file + review_ref; no self-polling loop
- anti-false-convergence: do not pass merely because writer phrased things persuasively (BadScientist caution)

orchestrator/workflow.md:
- two-phase defs + transition condition
- round_id vs section_round semantics + alignment rules
- 3-round escalation decision + in-place NOTSURE/TODO actions
- single-orchestrator loop decision rules
- role-slot reuse + restart fallback behavior
- terminal condition (all_complete) + max-idle guard
- state-file schemas (section 4)

## 9. BOOTSTRAP ORDER
1. human prepares project_contexts.md, thesis_rules.md, git_history.md, Chalmers sources, and reference theses; NanoMem paper/code/experiments remain in `/mnt/models/yupan/llm/nanomem` and are accessed by Writer from there.
2. human writes a COARSE spec.md for Expert only (stable form + standards; do not aim for complete)
3. human writes workflow.md + writer.md + expert.md + orchestrator_loop.sh
4. init state files (writer: phase:1 section:introduction status:drafting)
5. start the single orchestrator loop; produce v1
6. human inspects v1 -> refill exposed "fuzzy" standards into spec.md -> iterate
   (v1's value is not perfection but FORCING latent standards to surface; that is why "let it write v1 first" is not redundant.)

## 10. DISCIPLINE
Files are the only source of truth. Token decides the turn. Commits leave the trail. Three rounds cap the loop. Human is final arbiter. Roles separated, write-permissions physically isolated => safe unattended round-by-round progress.
