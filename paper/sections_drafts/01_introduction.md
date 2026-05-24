# Introduction Planning Notes

This document is a planning scaffold for the thesis Introduction chapter. It is
not final thesis prose. The purpose is to decide the argument flow before writing
the LaTeX chapter.

## Target Role

The Introduction should transform the NeurIPS-style problem framing into a
master's thesis opening. It should be slower and more explicit than the conference
paper, because a thesis reader may not already know agent memory, temporal
reasoning, or retrieval-based LLM systems.

## Core Story

Long-running LLM agents need memory to remain coherent and useful across
sessions. Existing memory systems often retrieve raw sessions or compressed
memory items, but many real queries require evidence that is not directly named
in the query. The agent must discover intermediate temporal or causal evidence
before it can retrieve the final supporting evidence. NanoMem addresses this by
treating memory retrieval as iterative evidence synthesis.

## Recommended Chapter Flow

1. Background and motivation
   - LLM agents increasingly interact with users over long periods.
   - Long-term memory is necessary for personalization, continuity, and grounded
     responses.
   - Memory is not just storage; it must provide useful evidence for downstream
     reasoning.

2. Problem setting
   - Dialogue histories are multi-session, noisy, and temporally structured.
   - A session timestamp is not always the event time.
   - User queries may contain implicit or relative temporal references.
   - Evidence may be indirectly addressable: one retrieval step reveals the cue
     needed for the next step.

3. Gap in existing approaches
   - One-shot retrieval cannot maintain evolving temporal evidence state.
   - Write-time memory systems commit to fixed extracted memories before the
     query is known.
   - Direct-answer memory systems obscure what evidence was used.

4. Thesis purpose
   - Study whether a memory system can construct compact, faithful, temporally
     grounded evidence for downstream answer generation.
   - Adapt the completed NanoMem research project and NeurIPS paper into a
     broader Chalmers master's thesis.

5. Research questions
   - RQ1: How can long-term conversational memory be represented as structured,
     temporally grounded evidence?
   - RQ2: How can iterative planning, retrieval, and synthesis recover evidence
     that is not directly addressable from the original query?
   - RQ3: How does NanoMem perform on long-term memory benchmarks compared with
     existing memory and retrieval baselines?

6. Contributions
   - Formulate temporal-causal evidence synthesis for agent memory.
   - Introduce NanoMem's Planner-Retriever-Synthesizer loop.
   - Use a Temporal Evidence Pool separating event time and session time.
   - Train/evaluate evidence synthesis using sufficiency, faithfulness, temporal
     grounding, and answer-quality signals.
   - Evaluate on LoCoMo, LongMemEval, ChainMem, and other benchmarks used in the
     source project.

7. Scope and delimitations
   - The thesis focuses on memory evidence construction, not general-purpose
     final answer generation.
   - The downstream answerer should be treated as a consumer of evidence.
   - Claims must be limited to the datasets and evaluation protocols actually
     implemented in the NanoMem repository.

8. Thesis outline
   - Briefly introduce each following chapter.

## NeurIPS Material To Reuse

- `/mnt/models/yupan/llm/nanomem/paper/sections/introduction_v2.tex`
- Intro figure and the event-time/session-time example.
- The motivation around indirectly addressable temporal evidence.

## Thesis Expansion Needed

- Add explicit research questions.
- Add a clearer scope statement.
- Add a thesis outline.
- Explain concepts more slowly than the NeurIPS paper.

