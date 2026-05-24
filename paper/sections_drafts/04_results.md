# Results Planning Notes

This document is a planning scaffold for the thesis Results chapter. It is not
final thesis prose.

## Target Role

The Results chapter should report what was evaluated and what was found. It
should be more complete than the NeurIPS experiments section, but should avoid
turning into interpretation-heavy discussion. Interpretation belongs mainly in
the Discussion chapter.

## Proposed Structure

1. Experimental setup summary
   - Datasets and benchmarks.
   - Models and baselines.
   - Metrics.
   - Evaluation protocol.
   - This can be either at the start of Results or in a separate Methods
     subsection, depending on final chapter organization.

2. Main benchmark results
   - Present main performance tables from the NeurIPS paper.
   - Include LoCoMo, LongMemEval, ChainMem, TimeDialog, or other benchmarks
     actually used in the final source project.
   - Explain what each table measures without over-interpreting.

3. Ablation studies
   - Planner/Synthesizer loop ablation.
   - Reward ablation.
   - Architecture ablation.
   - Model combination ablation.
   - Any benchmark-specific ablations from the source paper.

4. Efficiency and compactness
   - Evidence length or token savings.
   - Number of retrieval rounds.
   - Runtime or cost if available.
   - Be careful not to overclaim if numbers are not available.

5. Case studies
   - Show one or more temporal bridge retrieval examples.
   - Contrast full-context, one-shot retrieval, and NanoMem evidence synthesis.
   - Use source-grounded examples from appendix/prompt files.

6. Error analysis
   - Cases where temporal grounding fails.
   - Cases where retriever misses the key session.
   - Cases where Synthesizer marks insufficient/sufficient incorrectly.
   - Cases where evidence is correct but downstream answerer fails.

## Source Material To Reuse

- `/mnt/models/yupan/llm/nanomem/paper/sections/eval_v2.tex`
- `/mnt/models/yupan/llm/nanomem/paper/tbl/`
- `/mnt/models/yupan/llm/nanomem/paper/sections/appendix/main_results_tables.tex`
- `/mnt/models/yupan/llm/nanomem/paper/sections/appendix/evaluation_protocol.tex`
- `/mnt/models/yupan/llm/nanomem/paper/sections/appendix/model_combo.tex`
- `/mnt/models/yupan/llm/nanomem/paper/sections/appendix/local_answerer.tex`
- `/mnt/models/yupan/llm/nanomem/paper/agents/data_exp.md`

## Thesis Expansion Needed

- Add more explanation of what each benchmark is testing.
- Include more complete tables than the NeurIPS main text if useful.
- Add case studies and failure cases, which are often too long for a conference
  paper but valuable in a thesis.

