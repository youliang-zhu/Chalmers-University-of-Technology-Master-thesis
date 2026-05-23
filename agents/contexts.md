# Master Thesis Writing Context

This file is the primary context document for future Codex/LLM agents working on
the master's thesis in this repository. It records what the thesis is about,
where the source research artifacts live, how the Chalmers LaTeX template is
organized, and how future agents should migrate the completed NanoMem work into
a Chalmers master's thesis.

## Goal

The task is to convert the completed NanoMem research project and its NeurIPS
paper into a master's thesis that follows the Chalmers University of Technology
LaTeX template currently stored in:

```text
/mnt/models/youliang/master_thesis/paper
```

The source project is:

```text
/mnt/models/yupan/llm/nanomem
```

The source NeurIPS paper is:

```text
/mnt/models/yupan/llm/nanomem/paper
```

The thesis should not merely copy the NeurIPS paper. It should use the NeurIPS
paper as the core technical contribution, then expand and reshape it into a
master's thesis with more background, design rationale, implementation detail,
experimental methodology, limitations, and appendix material.

## Research Topic

The work is about long-term memory for LLM agents. The central idea is that an
agent memory system should return compact, faithful, source-grounded evidence
for a downstream agent, rather than returning only raw retrieved sessions or
directly answering the user query.

The main project is NanoMem. The paper title in the NeurIPS draft is:

```text
NanoMem: Iterative Evidence Synthesis for Temporal-Causal Reasoning in Agent Memory
```

The core problem is the evidence addressability gap:

- The evidence needed to answer a query is often not directly named in the
  query text.
- The useful retrieval cue may be hidden behind a temporal qualifier, a causal
  predecessor, a remembered property, or a dependency discovered only after an
  earlier retrieval step.
- Agent memory therefore needs iterative evidence search, not just one-shot
  vector retrieval.

The system frames memory as an evidence provider. It should return structured
evidence that is inspectable by a downstream answer model. Final answer
generation remains outside the memory module.

## Core Contributions To Preserve

Future writing should preserve these contributions:

1. Formulate agent memory as temporal-causal evidence search.
2. Propose a Planner-Synthesizer loop for iterative retrieval and evidence
   construction.
3. Introduce structured evidence events with explicit `session_time`,
   `event_time`, `inferred`, and source/session identifiers.
4. Use a `verdict` signal to decide whether the current evidence is sufficient,
   indicative, or insufficient, and to drive further retrieval.
5. Train or evaluate the system using reward signals aligned with evidence
   quality, including temporal grounding, faithfulness, sufficiency/verdict
   accuracy, and final downstream answer quality.
6. Introduce or use ChainMem as a diagnostic benchmark for hidden-dependency
   evidence search, complementing LoCoMo and LongMemEval.
7. Compare against existing long-term memory baselines such as Mem0, A-MEM,
   MemOS, MemSifter, Memory-T1, Memory-R1, MemR3, and related RAG-style memory
   systems where applicable.

## Important Source Materials

Use the following source files first when writing or revising thesis content.

### NeurIPS Paper Source

```text
/mnt/models/yupan/llm/nanomem/paper/neurips_2026.tex
/mnt/models/yupan/llm/nanomem/paper/sections/abstract.tex
/mnt/models/yupan/llm/nanomem/paper/sections/introduction_v2.tex
/mnt/models/yupan/llm/nanomem/paper/sections/relw.tex
/mnt/models/yupan/llm/nanomem/paper/sections/arch_v3.tex
/mnt/models/yupan/llm/nanomem/paper/sections/eval_v2.tex
/mnt/models/yupan/llm/nanomem/paper/sections/conclusion_limitations.tex
/mnt/models/yupan/llm/nanomem/paper/sections/appendix/
/mnt/models/yupan/llm/nanomem/paper/refs.bib
```

These files contain the most polished paper text. The thesis should translate
their arguments into a longer report structure, not preserve the NeurIPS section
structure verbatim.

### Agent Context From The NeurIPS Writing Process

```text
/mnt/models/yupan/llm/nanomem/paper/agents/outline_en.md
/mnt/models/yupan/llm/nanomem/paper/agents/outline_zh.md
/mnt/models/yupan/llm/nanomem/paper/agents/draft.md
/mnt/models/yupan/llm/nanomem/paper/agents/related_work.md
/mnt/models/yupan/llm/nanomem/paper/agents/arch_design_idea.md
/mnt/models/yupan/llm/nanomem/paper/agents/reward.md
/mnt/models/yupan/llm/nanomem/paper/agents/reward_provement.md
/mnt/models/yupan/llm/nanomem/paper/agents/data_exp.md
/mnt/models/yupan/llm/nanomem/paper/agents/contrast_paper.md
/mnt/models/yupan/llm/nanomem/paper/agents/reframe_and_reward_test.md
```

These files contain design notes, Chinese drafts, English outlines, reward
design notes, experiment descriptions, related work notes, and unresolved
questions. They are useful for expanding the thesis beyond the compressed
conference-paper version.

### Code And Experiment Artifacts

The code, datasets, evaluation scripts, and generated experiment artifacts are
under:

```text
/mnt/models/yupan/llm/nanomem
```

Important subareas to inspect when writing implementation and experiment
chapters:

```text
/mnt/models/yupan/llm/nanomem/src
/mnt/models/yupan/llm/nanomem/prompt
/mnt/models/yupan/llm/nanomem/evals
/mnt/models/yupan/llm/nanomem/scripts
/mnt/models/yupan/llm/nanomem/dataset
/mnt/models/yupan/llm/nanomem/training
```

Do not invent implementation details. If a method, prompt, dataset split,
baseline, metric, or hyperparameter is described in the thesis, verify it
against these files or the NeurIPS paper first.

## Current Thesis Template

The Chalmers thesis template is in:

```text
/mnt/models/youliang/master_thesis/paper
```

The main LaTeX entry point is:

```text
/mnt/models/youliang/master_thesis/paper/Main.tex
```

The current chapter files are:

```text
/mnt/models/youliang/master_thesis/paper/include/Introduction.tex
/mnt/models/youliang/master_thesis/paper/include/Theory.tex
/mnt/models/youliang/master_thesis/paper/include/Methods.tex
/mnt/models/youliang/master_thesis/paper/include/Results.tex
/mnt/models/youliang/master_thesis/paper/include/Conclusion.tex
```

Front matter:

```text
/mnt/models/youliang/master_thesis/paper/include/frontmatter/Titlepage.tex
/mnt/models/youliang/master_thesis/paper/include/frontmatter/Abstract.tex
/mnt/models/youliang/master_thesis/paper/include/frontmatter/Acknowledgements.tex
/mnt/models/youliang/master_thesis/paper/include/frontmatter/Acronyms.tex
/mnt/models/youliang/master_thesis/paper/include/frontmatter/Nomenclature.tex
```

Back matter:

```text
/mnt/models/youliang/master_thesis/paper/include/backmatter/References.tex
/mnt/models/youliang/master_thesis/paper/include/backmatter/Appendix_1.tex
/mnt/models/youliang/master_thesis/paper/include/backmatter/Lastpage.tex
```

Settings:

```text
/mnt/models/youliang/master_thesis/paper/include/settings/Settings.tex
```

The template currently uses `report` class and a manual `thebibliography`
environment. A later setup step should decide whether to keep this or migrate to
BibTeX using the existing NanoMem `refs.bib`. Since the source NeurIPS paper
already has a substantial BibTeX database, using BibTeX is likely preferable for
the thesis.

Important template setting to update early:

```tex
\def\ThesisType{B}
```

This should be changed to:

```tex
\def\ThesisType{M}
```

because the target document is a master's thesis.

## Environment To Mimic From NanoMem Paper

The NanoMem paper uses a simple and robust LaTeX workflow:

```text
/mnt/models/yupan/llm/nanomem/paper/Makefile
/mnt/models/yupan/llm/nanomem/paper/prerequisites.sh
```

The important build behavior is:

```bash
latexmk -xelatex -shell-escape -interaction=nonstopmode -halt-on-error -file-line-error -outdir=build MAIN_TEX
```

The thesis repository should get a similar setup:

- Add a `paper/Makefile` with targets such as `pdf`, `watch`, `clean`,
  `distclean`, and optionally `pack`.
- Use `latexmk` as the primary build tool.
- Prefer an output directory such as `paper/build`.
- Keep generated files ignored by Git.
- Add or adapt a `paper/prerequisites.sh` so a fresh environment can install
  `make`, `latexmk`, a complete TeX distribution, `ghostscript`, and
  `poppler-utils`.
- Use a stable command such as:

```bash
cd /mnt/models/youliang/master_thesis/paper
make pdf
```

The current template already includes a compiled `Main.pdf`, but future agents
should compile from source after any nontrivial edit.

## Suggested Thesis Structure

The default template chapters are too generic but can be reused. A likely
mapping is:

### Introduction

Use and expand the NeurIPS introduction. It should explain:

- Why long-term memory matters for LLM agents.
- Why memory should provide evidence rather than direct answers.
- The evidence addressability gap.
- Temporal grounding mismatch between `session_time` and `event_time`.
- Faithfulness risks when compressing retrieved sessions into evidence.
- Hidden dependency and multi-hop retrieval problems.
- Thesis research questions and contributions.

### Background / Theory

This should be broader than the NeurIPS related work section. It should explain:

- LLM agents and long-term memory.
- Retrieval-augmented generation and vector retrieval.
- Write-time memory systems.
- Search-time memory systems.
- Temporal reasoning in dialogue memory.
- Evidence synthesis, faithfulness, and hallucination.
- Reinforcement learning or preference optimization concepts needed to
  understand the reward design, if used in the final thesis.

### Method

Use and expand the NeurIPS methodology/architecture section. It should cover:

- Problem formulation.
- Memory evidence schema.
- Planner / cue rewriter.
- Retrieval path and temporal controls.
- Synthesizer / temporal compressor.
- Verdict-driven iterative loop.
- ChainMem construction if it is a core method contribution.
- Training setup: SFT warm-up, reward design, GRPO or other RL procedure,
  depending on what is actually implemented.
- Implementation details that are too long for a NeurIPS paper.

### Experiments / Results

Use and expand the NeurIPS evaluation section. It should cover:

- Datasets: LoCoMo, LongMemEval, TimeDialog if used, ChainMem if used.
- Baselines.
- Metrics.
- Experimental protocol.
- Main results.
- Ablations.
- Case studies.
- Error analysis.
- Discussion of statistical or practical significance.

### Conclusion

Use and expand the NeurIPS conclusion and limitations. It should cover:

- Summary of findings.
- What the thesis demonstrates about evidence-centric memory.
- Limitations.
- Ethical and practical considerations if relevant.
- Future work.

### Appendices

Move long material out of the main body:

- Full prompts.
- Additional tables.
- Dataset generation details.
- Hyperparameters.
- Extra case studies.
- Full benchmark examples.
- Implementation listings only when necessary.

## Writing Principles

Future agents should follow these principles:

- Write in clear academic English suitable for a Chalmers master's thesis.
- Do not preserve conference-paper compression when the thesis benefits from
  fuller explanation.
- Do not overclaim. If the source project does not prove a claim, phrase it as
  a design motivation, hypothesis, limitation, or future work.
- Keep the distinction between raw sessions, retrieved chunks, synthesized
  evidence, and final answers explicit.
- Keep the distinction between directly supported facts and inferred evidence
  explicit.
- Use `event_time` and `session_time` consistently.
- Use the term "downstream answer model" or "downstream agent" when discussing
  the component that consumes memory evidence.
- Avoid mixing Chinese notes into final thesis prose, but Chinese planning notes
  can be kept in `agents/` documents.
- Prefer structured LaTeX chapters over large monolithic files.
- After edits, compile the thesis and fix LaTeX errors immediately.

## Migration Notes From NeurIPS To Thesis

The NeurIPS paper is short and contribution-focused. The master's thesis should
expand it in these ways:

- Add a longer background chapter that teaches the reader the problem area.
- Add a more explicit problem formulation and research-question section.
- Explain why existing write-time and retrieval-only memory systems fail under
  temporal and hidden-dependency queries.
- Explain the architecture step by step, including input/output formats.
- Describe implementation choices from the actual codebase.
- Provide more detail on datasets and benchmark construction.
- Include additional result tables and case studies from appendices.
- Discuss negative results, failure cases, and limitations more openly than a
  conference paper would.
- Use the Chalmers front matter, title page, acknowledgements, acronyms,
  nomenclature, bibliography, and appendices correctly.

## Immediate Setup Tasks For Future Agents

The core local writing environment has now been initialized. Completed setup:

- `paper/Makefile` exists and uses `MAIN_TEX := Main.tex`.
- `paper/prerequisites.sh` exists and is executable.
- Root and paper-level `.gitignore` files ignore LaTeX build artifacts.
- `\ThesisType` has been changed from `B` to `M`.
- `paper/refs.bib` has been copied from the NanoMem NeurIPS paper for future
  bibliography migration.
- `make pdf` has been tested successfully and produces `paper/build/Main.pdf`.

Remaining setup tasks before or during substantial writing:

1. Decide whether to migrate bibliography handling from manual
   `thebibliography` to BibTeX using NanoMem's `refs.bib`.
2. Replace placeholder title page fields with the real thesis title, author,
   department, programme, supervisor, and examiner when known.

## Current Known Commands

The NanoMem source paper can be compiled with:

```bash
cd /mnt/models/yupan/llm/nanomem/paper
make pdf
```

The target thesis should eventually compile with:

```bash
cd /mnt/models/youliang/master_thesis/paper
make pdf
```

Until the thesis Makefile exists, compile manually with:

```bash
cd /mnt/models/youliang/master_thesis/paper
latexmk -pdf -interaction=nonstopmode -halt-on-error -file-line-error -outdir=build Main.tex
```

If the template's EPS assets cause issues under `pdflatex`, use `xelatex` or
adapt the Makefile after testing the local TeX environment.

## What Not To Do

- Do not edit the source NanoMem project when the task is thesis writing unless
  explicitly requested.
- Do not copy generated build artifacts into Git-tracked thesis source files.
- Do not invent experiment numbers or citations.
- Do not silently change the scientific story from the NanoMem paper.
- Do not collapse the thesis into a conference-paper style document; the thesis
  should be explanatory and self-contained.
