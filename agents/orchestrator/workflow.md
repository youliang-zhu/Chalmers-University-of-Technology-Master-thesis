# WORKFLOW PROTOCOL

AUTHORITY: this file is the single source of truth for the run loop, the state machine,
turn decisions, escalation, and termination. Writer, Expert, and the orchestrator all
follow it. Where any prompt disagrees with this file, this file wins.

READERS: orchestrator (loop logic), Writer (its obligations), Expert (its obligations).

LIVENESS MODEL: exactly ONE external orchestrator loop owns liveness. Writer and Expert
do not self-poll. Each is invoked, does exactly one unit of work, commits, atomically
updates its own state file, and exits. The orchestrator decides the next turn by reading
state files only — never by checking whether some file merely exists.

DURABILITY: Codex session memory is an accelerator only and is lossy (auto-compaction can
drop anything). No required state may live only in a session. All required state lives in
files. Any role process must be reconstructible from files at any time.

---

## 1. STATE FILES (authoritative schema)

`agents/orchestrator/writer_state.yaml` — WRITER-ONLY writer:
```yaml
round_id: int            # global monotonic. Incremented by exactly 1 on each
                         # Writer state advance; every ready_for_review handoff
                         # MUST use a strictly newer round_id.
phase: 1 | 2             # 1 = Chinese planning docs, 2 = LaTeX body
section: string          # one of the canonical section ids (see §3)
section_round: 1 | 2 | 3 # round within current section; =1 on entering a section; +1 per revision
status: drafting | ready_for_review | all_complete
artifacts: [string]       # current review target(s), or next target(s) when status=drafting
commit_hash: string      # commit of the latest paper product; may be unchanged/empty for state-only transitions
updated_at: ISO8601
```

`agents/orchestrator/reviewer_state.yaml` — EXPERT-ONLY writer:
```yaml
round_id: int            # MUST equal the writer round_id this verdict answers
phase: 1 | 2
section: string
section_round: 1 | 2 | 3
verdict: pass | needs_revision | null
review_ref: string       # path to reviews/pX_<section>_rN.md
commit_hash: string
updated_at: ISO8601
```

STATUS SEMANTICS (writer):
- `drafting`        : a section product must be produced and there is NO verdict to consume.
                      Occurs at bootstrap and on restart-after-crash-mid-draft.
- `ready_for_review`: a product exists at the current round_id, awaiting Expert.
- `all_complete`    : terminal. The whole thesis loop is done.
There is no persistent `revising` or `escalated` status. Revision and escalation are
ACTIONS performed inside a single Writer invocation; that invocation always ends at
`drafting`, `ready_for_review` (next product to review), or `all_complete`.

---

## 2. ID SEMANTICS & ALIGNMENT

- `round_id`: global monotonic counter. Writer increments it by exactly 1 when it advances
  the workflow state, including each `ready_for_review` handoff, each pass-based section
  advance, and each escalation advance. The blocker rule is strict: every
  `ready_for_review` handoff MUST have a `round_id` greater than the previous Writer state.
- `section_round`: 1..3, local to the current section. Set to 1 when a section is first
  drafted. Incremented by 1 on each revision of the SAME section. At 3 + needs_revision the
  section escalates (see §5).
- ALIGNMENT: a verdict in reviewer_state applies to writer round R iff
  `reviewer_state.round_id == R`. Expert echoes the writer round_id it answered.

---

## 3. SECTIONS & PHASES

CANONICAL SECTION ORDER (both phases use the same list):
```
introduction -> related_work -> methods -> results -> discussion
```
- "next section" = the successor in this list.
- "last section" = discussion.

PHASE OUTPUT CONTRACT (both Writer and Expert rely on this; the grading rubric lives in
spec.md and is Expert-only):
- PHASE 1 product: five planning docs at `paper/sections_drafts/0N_<section>.md`.
  Prose is pure Chinese; English allowed only for natural technical terms. Each doc plans:
  section breakdown, per-subsection content, and which figures/tables go where. Figures are
  PLANNED (position + rationale) only, NOT generated. Tables MAY be generated. The whole
  thesis targets ~15 figures, distributed across sections.
  For a W0 draft, any pre-existing target file is not authority: it may be a placeholder or stale
  scaffold. Writer may use already passed earlier section plans for continuity, but must not use
  current stale target content or future section drafts as planning evidence.
- PHASE 2 product: LaTeX body (`Main.tex` + `include/`), written per the phase-1 docs,
  starting at introduction, advancing per section. References inserted inline into
  `refs.bib`. Acknowledgements and other non-core matter are out of scope for now.
- PHASE 2 section-to-file mapping:
  - `introduction` -> `paper/include/Introduction.tex`
  - `related_work` -> `paper/include/Theory.tex`
  - `methods` -> `paper/include/Methods.tex`
  - `results` -> `paper/include/Results.tex`
  - `discussion` -> `paper/include/Conclusion.tex`

PHASE TRANSITION:
- pass on `discussion` in phase 1  -> switch to phase 2, section=introduction, section_round=1.
- pass on `discussion` in phase 2  -> all_complete.

---

## 4. STATE MACHINE (authoritative transition table)

Each row is one Writer invocation. The trigger is the orchestrator turn decision (§6).
Writer performs the action atomically: produce files when the row requires paper changes ->
commit changed files -> write new state -> commit state -> exit.

| # | Trigger (state read at invocation start) | Writer action | Resulting writer_state |
|---|---|---|---|
| W0 | status==drafting | draft current section | round_id+1; status=ready_for_review; artifacts set; section_round unchanged |
| W1 | verdict==pass AND section != discussion | advance to next section; no paper edit | section=next; section_round=1; round_id+1; status=drafting; artifacts set to next section target |
| W2 | verdict==pass AND section==discussion AND phase==1 | switch to phase 2; no paper edit | phase=2; section=introduction; section_round=1; round_id+1; status=drafting; artifacts set to phase-2 introduction target(s) |
| W3 | verdict==pass AND section==discussion AND phase==2 | finish; no paper edit | status=all_complete |
| W4 | verdict==needs_revision AND section_round < 3 | revise current section per review | section_round+1; round_id+1; status=ready_for_review |
| W5 | verdict==needs_revision AND section_round == 3 | ESCALATE current section, then advance | see §5; ends as W1/W2/W3-style drafting advance (or all_complete if section==discussion) |

EXPERT invocation (single row): trigger = §6 expert branch. Action: read
`writer_state.artifacts`, evaluate against spec/rules/exemplars, write exactly one review
file, commit, then set reviewer_state {round_id := writer.round_id, verdict, review_ref,
section, section_round, phase, commit_hash}. Expert NEVER edits writer_state or paper files.

KEY PROPERTY: every Writer invocation ends at `drafting`, `ready_for_review` (with round_id
strictly greater than reviewer_state.round_id), or `all_complete`. There is never a state
in which the orchestrator can find no valid transition while work remains — no deadlock,
no livelock.

---

## 5. ESCALATION (3-round cap)

When a section reaches `section_round == 3` and the Expert verdict is still
`needs_revision`, the Writer, in the SAME invocation:

1. Reads the round-3 review and keeps every unresolved issue IN PLACE inside the section
   artifact, at the exact location it concerns. Issues are NOT moved to a separate file.
   - `NOTSURE:` for uncertain facts, weak/unclear arguments, unresolved wording, or anything
     needing human/advisor judgment.
   - `TODO:` for missing figures, tables, citations, experiment numbers, implementation
     checks, or other concrete unfinished work.
   - Phase 1 (markdown): inline `**NOTSURE:** ...` / `**TODO:** ...`.
   - Phase 2 (LaTeX): `\textcolor{red}{NOTSURE: ...}` / `\textcolor{red}{TODO: ...}`
     (requires `\usepackage{xcolor}` in Main.tex).
2. Commits the marked section (commit note: `escalated after r3`).
3. ADVANCES exactly as a pass would (rows W1 / W2 / W3 by current section+phase): the
   escalated section is frozen with its markers; the invocation ends at the next section's
   `drafting` state, the phase-2 introduction `drafting` state, or `all_complete`. The
   escalated section is therefore never re-reviewed; it is left for the human.

AGGREGATION: there is no separate open-questions file. To collect all leftovers, the human
(or a Makefile target) greps the markers:
```
cd paper && make notsure
```
Equivalent root-level command:
```
rg -n "NOTSURE:|TODO:" paper/sections_drafts paper/Main.tex paper/include agents/orchestrator/reviews
```

---

## 6. ORCHESTRATOR LOOP

Run exactly one loop (`scripts/orchestrator_loop.sh`). `invoke_*` is SYNCHRONOUS: the
orchestrator blocks until the role process exits AND its state file is updated, then loops
and re-reads state. It must not pipeline or run roles concurrently.

The loop must also hold an exclusive process lock at `agents/orchestrator/.orch_lock`. If a
second orchestrator is started accidentally, it must exit before invoking any role.

```text
loop:
  W  = read writer_state.yaml
  Rv = read reviewer_state.yaml

  if W.status == "all_complete":
      exit 0
  if stop_file_exists("agents/orchestrator/STOP"):
      exit 0

  if W.status == "drafting":
      invoke_writer_once          # blocking; handles W0 (and crash-restart redraft)
      idle = 0

  elif W.status == "ready_for_review" and W.round_id > Rv.round_id:
      invoke_expert_once          # blocking; Expert reviews this round
      idle = 0

  elif W.status == "ready_for_review" and Rv.round_id == W.round_id \
       and Rv.verdict in {"pass","needs_revision"}:
      invoke_writer_once          # blocking; handles W1..W5
      idle = 0

  else:
      sleep(T)                    # no valid transition; wait
      idle += 1
      if idle > MAX_IDLE:
          alert_human(); exit 1   # stuck guard

  repeat
```

Branch order matters: `drafting` is checked before the verdict branches, so a verdict that
remains in reviewer_state after the Writer has advanced is never re-consumed. The next
Writer invocation drafts the new target and creates a fresh `ready_for_review` handoff.

SMOKE TEST STATUS (2026-05-24):
- `scripts/orchestrator_loop.sh --dry-run --once` selects Writer from the initialized state
  (`writer_state.status=drafting`), which is the expected first transition.
- A minimal `codex exec -C /mnt/models/youliang/master_thesis -s danger-full-access -`
  invocation starts successfully and returns normally.
- This local Codex CLI supports `codex exec` sandbox flags but not `codex exec -a never`;
  the orchestrator therefore does not pass `-a/--ask-for-approval`.
- The tested implementation is the robust baseline: each role invocation is a fresh,
  synchronous `codex exec` process that reconstructs context from files.

---

## 7. ROLE INVOCATION CONTRACTS (protocol-level; full behavior in writer.md / expert.md)

Common to both:
- Do exactly ONE unit of work, then exit. No internal long-running poll loop.
- Reconstruct all needed context from files (sessions are lossy).
- Write ONLY files this role owns (see ownership in the design spec).
- Shared lock exception: both roles may touch `agents/orchestrator/.git_lock` only through
  `flock` for git operations. It is not content, state, or a communication channel.
- Update the OWN state file LAST and ATOMICALLY (`tmp` + `mv`); this is the commit point of
  the transition. If the process dies before this step, the unfinished unit is simply redone
  on the next invocation (the state still shows the pre-transition value).
- Acquire `flock agents/orchestrator/.git_lock` around git operations; keep the same lock
  across the product/review commit and the state commit. If the lock was released, re-acquire it
  before committing state. On `.git/index.lock` failure, retry with backoff — never delete locks
  blindly.
- Tool calls are separate processes, so a `flock` cannot be kept across multiple tool calls.
  In practice, roles should put the full git sequence for one turn inside ONE shell invocation,
  e.g. `flock agents/orchestrator/.git_lock bash -c 'git add ...; git commit ...; mv ...; git add ...; git commit ...'`.

Writer per invocation (ordered):
1. read writer.md, workflow.md, `agents/project_contexts.md`, both state files;
2. if responding to a review, read the review file at reviewer_state.review_ref;
3. read Writer content sources as needed: code/experiments under
   `/mnt/models/yupan/llm/nanomem`, accepted thesis plans/artifacts in the current repo, and
   current `paper/**` for template/layout context. Writer must not read or rely on old
   conference-paper prose, old paper-agent notes, or the historical paper-commit summary,
   including `/mnt/models/yupan/llm/nanomem/paper/**`,
   `/mnt/models/yupan/llm/nanomem/paper/agents/**`, and
   `agents/resources/history_paper_commit.md`;
4. perform the triggered row (W0..W5): produce/revise paper artifacts only for rows that
   require paper changes; use state-only updates for W1/W2/W3;
5. commit paper product if the row changed paper files (capture hash);
6. atomically update writer_state.yaml (incl. round_id per RULE-INC, status, artifacts,
   commit_hash); commit state. For W1/W2/W3, where no paper product changes, leave
   `commit_hash` unchanged or empty; do not try to predict the state commit hash inside the
   state file. The state commit must also be protected by `agents/orchestrator/.git_lock`;
7. exit.
Writer does NOT read spec.md, thesis_rules.md, references, or sources/ during normal
operation. It learns standards only through Expert feedback. It DOES know the Phase Output
Contract (§3) and its task constraints from writer.md.

Expert per invocation (ordered):
1. read expert.md, spec.md, workflow.md, `agents/project_contexts.md`;
2. read evaluation sources as needed: thesis_rules.md, sources/, references/;
3. read both state files and every artifact in writer_state.artifacts;
4. write exactly one review file `reviews/pX_<section>_rN.md`;
5. commit review (capture hash);
6. atomically update reviewer_state.yaml (round_id := writer.round_id, verdict, review_ref,
   section/section_round/phase, commit_hash); commit state under `agents/orchestrator/.git_lock`;
7. exit.

---

## 8. GIT / COMMIT CONVENTIONS

- Commit message: `[writer|expert][p{phase}][{section}][r{section_round}] {note}`
  - e.g. `[writer][p1][introduction][r1] draft`, `[expert][p1][introduction][r2] needs_revision`,
    `[writer][p2][methods][r3] escalated after r3`.
- Same repo, same branch, shared working tree. Expert reads the working tree directly;
  `commit_hash` is for snapshot confirmation and history, not for checkout.
- Product commit precedes state commit when there is a product. For state-only transitions,
  `commit_hash` may remain unchanged or empty.

---

## 9. TERMINATION & GUARDS

The orchestrator exits when ANY holds:
- `writer_state.status == all_complete`; or
- the human stop file `agents/orchestrator/STOP` exists; or
- the idle guard fires (`idle > MAX_IDLE` consecutive sleeps with no valid transition).

Final complete state:
```
phase == 2 ; section == discussion ; status == all_complete
```

---

## 10. INITIALIZATION

`writer_state.yaml`:
```yaml
round_id: 0
phase: 1
section: introduction
section_round: 1
status: drafting
artifacts:
  - paper/sections_drafts/01_introduction.md
commit_hash: ""
updated_at: <now>
```
`reviewer_state.yaml`:
```yaml
round_id: 0
phase: 1
section: introduction
section_round: 1
verdict: null
review_ref: ""
commit_hash: ""
updated_at: <now>
```
First loop iteration sees status=drafting -> W0 -> round_id becomes 1, status=ready_for_review.
Then `1 > 0` routes to Expert. The pingpong proceeds from there.

---

## 11. INVARIANTS RECAP

- INV-1 SINGLE-WRITER: disjoint write sets (Writer: paper/** + writer_state.yaml; Expert:
  reviews/** + reviewer_state.yaml). No file has two writers.
- INV-2 TURN-MUTEX: the orchestrator invokes exactly one role at a time, synchronously,
  chosen solely from state fields.
- RULE-INC: round_id increases by 1 on every Writer state advance, and every new
  `ready_for_review` product strictly outranks the last Expert verdict.
- LIVENESS: every Writer invocation ends at drafting, ready_for_review, or all_complete;
  no reachable state stalls the loop while work remains.
- DURABILITY: files are the only source of truth; any role is reconstructible from files.
