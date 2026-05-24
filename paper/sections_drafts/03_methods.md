# Methods Planning Notes

This document is a planning scaffold for the thesis Methodology/Methods chapter.
It is not final thesis prose.

## Target Role

The Methods chapter should explain exactly what NanoMem is, how it works, and how
the research project was carried out. This chapter should be much more detailed
than the NeurIPS method section.

## Proposed Structure

1. Problem formulation
   - Define multi-session memory bank.
   - Define query, answer, session, conversation unit, event, session time, and
     event time.
   - Define the goal: construct a Temporal Evidence Pool sufficient for a
     downstream answer model.

2. System overview
   - Present NanoMem as a memory system, not as the final answer generator.
   - Components: temporal normalization, Planner, Retriever, Synthesizer,
     Temporal Evidence Pool, downstream answerer.
   - Include architecture figure from the NeurIPS paper.

3. Temporal Evidence Pool
   - Structured records should include evidence text, event time, session time,
     source session, and whether the evidence is directly supported or inferred.
   - Explain why separating event time and session time matters.

4. Temporal normalization
   - Explain how relative temporal expressions are grounded.
   - Clarify whether this is deterministic, model-based, or implemented through
     prompts/code in the source repository.
   - Verify implementation details before writing final prose.

5. Planner-Retriever-Synthesizer loop
   - Planner creates retrieval cues.
   - Retriever returns candidate sessions.
   - Synthesizer converts retrieved sessions into structured evidence events.
   - Verdict decides whether evidence is sufficient, indicative, or insufficient.
   - Insufficient evidence feeds back into another planning/retrieval round.

6. Training procedure
   - Explain SFT warm-up if used.
   - Explain GRPO or other RL procedure if used.
   - Explain reward design:
     - final answer reward
     - evidence faithfulness
     - temporal grounding
     - sufficiency/verdict reward
     - compactness/length reward if used
   - Do not invent hyperparameters; verify from source files.

7. Benchmark construction
   - Explain ChainMem or TimeMemEval construction if it is part of the thesis.
   - Explain why existing benchmarks do not fully test hidden dependency or
     temporal-causal retrieval.

8. Implementation details
   - Describe codebase organization and main scripts.
   - Explain prompts, model choices, retrieval backend, training/eval pipeline,
     and data artifacts.
   - Move very long prompt templates and hyperparameters to appendix.

## Source Material To Reuse

- `/mnt/models/yupan/llm/nanomem/paper/sections/arch_v3.tex`
- `/mnt/models/yupan/llm/nanomem/paper/sections/appendix/algorithm_details.tex`
- `/mnt/models/yupan/llm/nanomem/paper/sections/appendix/dataset_details.tex`
- `/mnt/models/yupan/llm/nanomem/paper/sections/appendix/prompt_templates.tex`
- `/mnt/models/yupan/llm/nanomem/paper/agents/arch_design_idea.md`
- `/mnt/models/yupan/llm/nanomem/paper/agents/reward.md`
- `/mnt/models/yupan/llm/nanomem/paper/agents/data_exp.md`

## Thesis Expansion Needed

- The NeurIPS method section can remain mathematically concise.
- The thesis should add diagrams, examples, and step-by-step explanation.
- Every important design choice should include a rationale.
- Implementation details should be grounded in the actual NanoMem codebase.

