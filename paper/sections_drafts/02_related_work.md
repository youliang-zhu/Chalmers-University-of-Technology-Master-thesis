# Related Work Planning Notes

This document is a planning scaffold for the thesis Related Work chapter. It is
not final thesis prose.

## Target Role

The Related Work chapter should position NanoMem against existing work. Unlike a
NeurIPS paper, the thesis may also use this chapter to teach the reader the
research landscape in a more complete and categorized way.

## Proposed Structure

1. Long-term memory for LLM agents
   - Memory as external storage for multi-session interaction.
   - Write-time memory extraction and organization.
   - Search-time retrieval and memory access.
   - Systems to compare against may include Mem0, A-MEM, MemOS, MemSifter,
     Memory-T1, Memory-R1, MemR3, Zep, GMemory, and related systems, depending
     on what is cited in the source paper.

2. Retrieval-augmented generation and agentic retrieval
   - Standard RAG retrieves context for generation.
   - Agentic retrieval introduces planning, query rewriting, tool use, and
     iterative search.
   - NanoMem differs because it constructs structured evidence state rather than
     only retrieving more text.

3. Temporal reasoning in dialogue and memory
   - Temporal expressions can be relative, implicit, or anchored to session time.
   - Event time differs from mention/session time.
   - Existing temporal memory systems often fail when evidence must be recovered
     across multiple steps.

4. Evidence synthesis and faithfulness
   - Retrieved text must be compressed into usable evidence.
   - Compression introduces hallucination and attribution risks.
   - NanoMem's evidence records should preserve source session, event time,
     session time, and direct/inferred support status.

5. Reinforcement learning for retrieval and agent memory
   - RL or preference optimization can train search and synthesis policies.
   - The relevant thesis focus is why terminal answer reward is not enough and
     why process-level sufficiency/verdict signals matter.

6. Summary and research gap
   - Existing methods either retrieve sessions, write memories before knowing the
     query, or answer directly.
   - The missing capability is query-conditioned iterative construction of
     temporally grounded evidence.

## Source Material To Reuse

- `/mnt/models/yupan/llm/nanomem/paper/sections/relw.tex`
- `/mnt/models/yupan/llm/nanomem/paper/agents/related_work.md`
- BibTeX entries from `/mnt/models/yupan/llm/nanomem/paper/refs.bib`

## Difference From NeurIPS Related Work

The NeurIPS related work is short and contrastive. The thesis version should be
more explanatory:

- Define each category before critiquing it.
- Give enough detail for a master's thesis reader outside the exact subfield.
- End each subsection with the specific limitation that motivates NanoMem.

