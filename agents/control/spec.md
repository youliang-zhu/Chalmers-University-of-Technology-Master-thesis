# SPEC — GRADING RUBRIC (EXPERT-ONLY)

This is the Expert's yardstick: what counts as good, and what blocks a pass. The Writer NEVER
reads this file; that information asymmetry is intentional. Use this together with `expert.md`
(which tells you how to evaluate and how to write feedback). This is a LIVING DOCUMENT — unfilled
points are marked `SPEC-TODO`; where one is unresolved, judge by the reference theses + the
Chalmers criteria below and note the uncertainty rather than inventing a hard requirement.

Most of this rubric is NOT hardcoded by design. Your standard for structure, chapter
organization, per-chapter content, and writing tone is DERIVED, each invocation, by reading the
source materials below — not imposed from your own preferences.

---

## 0. GROUND YOURSELF BEFORE JUDGING (every invocation)

1. NanoMem mainline. Read the source paper at `/mnt/models/yupan/llm/nanomem/paper` and extract
   the thesis's mainline: the core contribution and its 1–3 key claims. EVERY chapter is judged
   on whether it serves this mainline. A section that drifts off the mainline is a blocking issue.
2. Structure & tone standard. Read/compare the three reference theses in
   `agents/resources/references/`. Extract their COMMON pattern: how they are structured,
   how chapters are organized and sequenced, and — most importantly — their writing TONE/voice.
   This shared pattern IS the standard. Do not substitute a structure or voice you happen to
   prefer. The NeurIPS paper (`/mnt/models/yupan/llm/nanomem/paper`) is an additional TONE
   reference: the thesis voice should stay close to the references AND to that paper.
3. Full rules. The condensed Chalmers red lines and assessment axes are below. For any detail
   beyond them, consult `agents/resources/thesis_rules.md` and `agents/resources/sources/`.

---

## 1. CHALMERS HARD RULES (condensed; violations are BLOCKING when applicable at the current stage)

Full authority: `agents/resources/thesis_rules.md` (regulation C 2025-0611). Condensed red lines:

- LANGUAGE: the final thesis is in English. NOTE: phase-1 planning docs are Chinese BY DESIGN —
  never flag phase-1 Chinese as a language violation. English applies to phase-2 prose.
- TEMPLATE & BUILD: must follow the Chalmers degree-project template; chapters live under
  `paper/include/`; the thesis must compile to PDF via
  `cd /mnt/models/youliang/master_thesis/paper && make pdf`, which has been tested and produces
  `paper/build/Main.pdf`. Structural non-conformance to the template the references follow is
  blocking.
- ABSTRACT (when present): 250–350 words, ending with ≤10 keywords.
- TRACEABILITY & HONESTY: every technical claim must be traceable to literature, code,
  experiments, or clearly marked reasoning. NO fabricated citations, bibkeys, experiment numbers,
  or results. A citation that looks invented is blocking.
- BIBLIOGRAPHY: complete; every in-text citation appears in the bibliography; direct quotations
  sparse and clearly marked.
- SOCIETAL / ETHICAL / ECOLOGICAL / SUSTAINABILITY: must be discussed (or explicitly justified if
  omitted). For NanoMem, expect: privacy of long-term conversational memory; faithfulness /
  hallucination risk in synthesized memory evidence; consent & data retention; safety of memory
  that influences downstream decisions; environmental cost of training/eval; benchmark data
  provenance & synthetic-data limits.
- PUBLIC / NON-CONFIDENTIAL: no API keys, private datasets, private user data, or confidential
  material required to assess the work.
- PERSONAL DATA: minimized/anonymized; prefer synthetic or public benchmark data; no identifiable
  user sessions.
- AI USE: recorded transparently; generated text is draft only; the student is responsible for
  verifying everything.

STAGE AWARENESS: many of the above are phase-2 / final-report concerns. At PHASE 1 you do not
require them to be present — you require the PLAN to PROVIDE for them (e.g. the plan allocates an
ethics/sustainability section, plans English prose, plans template-conformant chapters).

---

## 2. ASSESSMENT AXES (Chalmers C 2025-0611 Appendix 1; score each chapter on the axes that apply)

PASS BAR: a 30-credit Master's thesis passes only at "High Quality" on all objectives. Hold a
High-Quality bar — not a bare-minimum one. "Very High Quality" notes below are aspirational.

- A. KNOWLEDGE & RELATION TO RESEARCH (Theory / Related Work): not a list of papers — explain how
  NanoMem relates to current agent-memory, retrieval, temporal-reasoning, and evidence-synthesis
  research; a real literature review; reflection on the forefront. (Very High: extensive review,
  clear new-knowledge contribution.)
- B. METHOD CHOICE & JUSTIFICATION (Methods): justify WHY each NanoMem design choice suits the
  problem (read the paper to know the actual mechanisms); correct application; not just "what" but
  "why this".
- C. CONTRIBUTION CLEARLY PRESENTED: explicitly state what is new versus prior memory systems
  (e.g. the comparators named in the paper / thesis_rules). The reader must not have to guess the
  delta.
- D. PROBLEM FORMULATION ↔ CONCLUSIONS: Introduction defines clear research questions/objectives;
  Results/Discussion/Conclusion answer THEM directly; explicit links; well-substantiated
  conclusions.
- E. TECHNICAL SOLUTIONS & CRITICAL EVALUATION: developed solutions that are critically analysed —
  ablations, alternatives considered, error analysis, failure cases. (Very High: alternatives
  developed and processed exhaustively.)
- F. INTEGRATION OF KNOWLEDGE: connect the relevant subfields (LLM agents, memory, retrieval,
  temporal reasoning, structured evidence, benchmark construction, RL/reward design where
  applicable).
- G. WRITTEN PRESENTATION: coherence, structure, layout; define terms before use; figures/tables
  directly support the text; avoid conference-paper compression (the thesis must go DEEPER than
  the NeurIPS paper, not restate it).
- H. SOCIETAL / ETHICAL / ECOLOGICAL / SUSTAINABILITY: identified and discussed (see the list in §1).
- I. ETHICS OF R&D: possible ethical consequences of the work presented — expect a dedicated
  subsection (likely in Discussion/Conclusion).
- J. INDEPENDENCE: where relevant, clarify what the student implemented, evaluated, and wrote.

---

## 3. STRUCTURE & TONE (high weight; reference-derived; DO NOT hardcode your own)

STRUCTURE & ORGANIZATION: must match the COMMON pattern of the three reference theses and the
Chalmers template. The working section ids used by the loop (introduction, related_work, methods,
results, discussion) map onto the Chalmers template chapters (Introduction; Theory ≈ related work
/ background; Methods; Results; Conclusion, optionally a separate Discussion). Verify the thesis
conforms to the template the references follow. Chapter GRANULARITY may take the references as a
guide but is soft — do not force a specific subsection count.

TONE / VOICE — TOP PRIORITY, HARD REQUIREMENT: the writing voice MUST imitate the three reference
theses and stay close to the NeurIPS paper's voice. The Writer must NOT invent its own style or
free-form the register. Treat tonal drift as a BLOCKING issue: too casual / bloggy, inconsistent
register, marketing-speak, or a voice that does not read like the academic register of the
references. This is one of the most important things you check — weight it heavily and, in your
review BASIS, point to the specific reference-thesis voice the Writer should match.

---

## 4. FIGURES & TABLES (soft)

No hard rule. Use judgment: a figure/table earns its place only if it genuinely aids
understanding. Aim for roughly ~15 figures across the whole thesis, distributed sensibly — insert
where it helps, don't pad to hit a number. Figures are PLANNED (phase 1) or left as placeholders
(phase 2) by design — never fail a section merely because a figure is absent/placeholder; instead
judge whether the figure is well-motivated and well-placed. Tables may be generated. (Final print
quality — vector diagrams, ≥300 dpi raster — is a final-report concern, not a per-round blocker.)

---

## 5. PHASE-AWARE APPLICATION

- PHASE 1 (Chinese planning doc): judge the PLAN. Does it (a) follow the reference theses' common
  structure, (b) lay out chapters/subsections that will satisfy the relevant axes in §2, (c)
  provide for the §1 hard rules (ethics/sustainability section planned, English prose planned,
  template-conformant), (d) plan figures/tables with rationale toward ~15, (e) make the
  conference→thesis EXPANSION concrete rather than restating the paper, (f) intend the
  reference/NeurIPS voice? Chinese planning prose is expected.
- PHASE 2 (LaTeX): judge the actual English prose against §1 hard rules, §2 axes, §3 structure &
  tone. Citations must be present and verifiable.

---

## 6. BLOCKING vs NON-BLOCKING (decision rule)

BLOCKING (→ needs_revision): violates a §1 red line applicable at this stage; misses required
content for the chapter's §2 axes; drifts off the NanoMem mainline; fabricated/unverifiable
citation; structural non-conformance to the reference pattern/template; tonal drift from the
reference/NeurIPS voice; a mis-planned (not merely absent) figure; conclusions not linked to the
stated research questions.

NON-BLOCKING (→ may still pass; list as suggestions): optional polish, stylistic nice-to-haves,
improvements that do not threaten the High-Quality bar on any axis.

---

## 7. LIVING-DOC PLACEHOLDERS (refilled by the human after v1)

- SPEC-TODO: precise per-chapter passing definitions, once v1 reveals what the human actually
  wants for each chapter.
- SPEC-TODO: any specific must-have experiments/ablations or must-have figures the human decides
  are mandatory.
- SPEC-TODO: examiner-specific requirements (e.g. whether an AI-use appendix/methodology note is
  required) once known.

Until a SPEC-TODO is filled, do not invent a hard requirement for it — judge by the reference
theses and the Chalmers criteria above, and surface the open question in your review.
