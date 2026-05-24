# Discussion Planning Notes

This document is a planning scaffold for the thesis Discussion chapter. It is not
final thesis prose.

## Target Role

The Discussion chapter should interpret the Results chapter, answer the research
questions, compare the findings with prior work, and discuss limitations. This is
one of the major differences between a Chalmers master's thesis and a NeurIPS
paper: the thesis should be more reflective and explicit about what the work does
and does not show.

## Proposed Structure

1. Answers to research questions
   - RQ1: Explain how structured temporal evidence represents memory.
   - RQ2: Explain how iterative planning/retrieval/synthesis helps recover
     indirectly addressable evidence.
   - RQ3: Summarize how NanoMem performs against baselines and what the results
     imply.

2. Why NanoMem works
   - Event-time/session-time separation reduces temporal mismatch.
   - Temporal Evidence Pool carries intermediate evidence between rounds.
   - Verdict-driven iteration avoids stopping too early or retrieving blindly.
   - Structured evidence makes the memory output more inspectable.

3. Comparison with related work
   - Compare with write-time memory extraction.
   - Compare with one-shot RAG or session retrieval.
   - Compare with direct-answer memory systems.
   - Compare with RL-based memory systems if relevant.

4. Practical implications
   - Evidence-centric memory can support downstream agents that need traceable
     context.
   - The system may reduce context size by passing structured evidence instead
     of raw sessions.
   - The architecture is useful when queries require hidden temporal or causal
     bridges.

5. Limitations
   - Dependence on retriever recall.
   - Dependence on temporal normalization quality.
   - Risk of synthesized evidence being unsupported or over-inferred.
   - Benchmark coverage may not represent all real agent memory settings.
   - Training/evaluation may depend on specific model choices.
   - Cost and latency of multi-round retrieval.

6. Threats to validity
   - Dataset construction and annotation assumptions.
   - Baseline implementation differences.
   - Metric limitations.
   - Randomness and model variance.
   - Generalization beyond tested benchmarks.

7. Ethical and practical considerations
   - Agent memory may store sensitive personal information.
   - Evidence synthesis must avoid fabricating user facts.
   - Transparent source attribution is important for trust and correction.
   - Chalmers rules require transparent use of AI tools in thesis work.

8. Future work
   - Better temporal normalization.
   - Stronger retrievers and hybrid search.
   - Human-correctable memory evidence.
   - Better uncertainty calibration for sufficiency verdicts.
   - Real-world long-running agent deployments.

## Source Material To Reuse

- `/mnt/models/yupan/llm/nanomem/paper/sections/conclusion_limitations.tex`
- `/mnt/models/yupan/llm/nanomem/paper/sections/eval_v2.tex`
- `/mnt/models/yupan/llm/nanomem/paper/agents/contrast_paper.md`
- `/mnt/models/yupan/llm/nanomem/paper/agents/reframe_and_reward_test.md`

## Thesis Expansion Needed

- The NeurIPS conclusion is likely too short.
- The thesis should explicitly answer RQs and include limitations/threats to
  validity.
- Discussion should be more honest about failure modes and scope than a
  conference paper.

