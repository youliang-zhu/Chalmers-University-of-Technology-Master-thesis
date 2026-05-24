# Historical NanoMem Paper Commit Notes

This document collects useful writing material found in the historical commits
of the NanoMem NeurIPS paper repository:

```text
/mnt/models/yupan/llm/nanomem
```

The purpose is not to reproduce every old draft. The purpose is to recover
non-duplicate, thesis-useful content that was compressed, deleted, or moved
during the NeurIPS 9-page writing process. These notes should be used when
expanding the Chalmers master's thesis.

## Scope Inspected

Only the core paper-writing files were inspected:

```text
paper/sections/introduction.tex
paper/sections/introduction_v2.tex
paper/sections/relw.tex
paper/sections/arch.tex
paper/sections/arch_v2.tex
paper/sections/arch_v3.tex
paper/sections/eval.tex
paper/sections/eval_v2.tex
paper/agents/outline_en.md
paper/agents/arch_design_idea.md
paper/agents/reward.md
paper/agents/reframe_and_reward_test.md
```

The source repository was dirty during inspection, so historical material was
read through `git show <commit>:<path>` where possible. The source repository
was not modified.

## Useful Historical Commits

These commits contained the most useful writing material:

| Commit | Message | Useful material |
|---|---|---|
| `7e17472` | `[paper/intro]: draft memory evidence motivation` | Early framing of the evidence addressability gap and memory-as-evidence-provider idea. |
| `ad8eacc` | `[paper/related-work]: draft memory retrieval context` | Longer related work taxonomy for long-term memory, temporal reasoning, reflective retrieval, and RL. |
| `092d598` | `[paper/introduction]: refine temporal-causal framing` | Earlier temporal-causal introduction, event-time/session-time mismatch, and multi-hop retrieval example. |
| `4dd3de1` | `[paper] New intro` | Added discussion of mention event versus happened event; useful for thesis motivation. |
| `ac9ab8f` | `[paper/architecture]: draft temporal retrieval pipeline` | Early architecture with ingest/search stages, cue schema, retrieval scoring, and output schema. |
| `0af6183` | `[paper] finishing arch` | Expanded GRPO trajectory formulation, reward design, and ChainMem benchmark construction. |
| `f4d6870` | `[paper]: draft experiment setup` | Experiment RQs, evidence-provider/direct-answerer evaluation distinction, dataset/baseline design. |
| `97cd768` | `[paper/eval]: update results narrative` | Results narrative and ablation interpretation. |
| `4952b5c` | `[paper/eval]: switch evidence answerer to qwen` | Final evaluation setup changed the fixed answerer from GPT-5.1 to Qwen3.5-9B. |
| `0e26d02` | `[paper/agents]: add architecture and reward notes` | Detailed Chinese architecture and reward design notes. |
| `fad08ce` | `[paper]: update neurips draft` | Consolidated outline and planning notes. |

## Introduction Material To Recover

### Memory As An Evidence Provider

Early drafts stated the key thesis more explicitly than the final compressed
paper: a memory system should provide the downstream agent with evidence, not
merely store facts or answer questions directly.

This is useful for the thesis Introduction because it clarifies responsibility:

- The memory module should return compact, relevant, source-grounded evidence.
- The downstream answer model should perform final reasoning and answer
  generation.
- Separating these roles makes failures diagnosable: retrieval failure,
  evidence synthesis failure, and final answer failure are not collapsed into a
  single opaque output.

Suggested thesis use:

- Put this in the Introduction and Methods motivation.
- Use it to justify why NanoMem reports evidence events rather than final
  answers.
- Connect it to Chalmers thesis expectations by explaining the system boundary
  explicitly.

### Evidence Addressability Gap

Early drafts used a strong concept: the evidence needed for a user query is
often not directly named in the query. It may be hidden behind:

- a remembered qualifier;
- a relative time window;
- a causal predecessor;
- an entity discovered only after reading earlier evidence;
- a dependency revealed by a previous retrieval step.

This is broader than temporal reasoning alone. It is one of the most useful
ideas for the master's thesis because it supports a richer problem statement:
NanoMem is not only about date parsing; it is about making hidden evidence
addressable through iterative search.

Suggested thesis use:

- Define this in Chapter 1 as the main problem.
- Reuse it in Related Work to contrast one-shot RAG and write-time memory.
- Reuse it in Methods to motivate the Planner-Retriever-Synthesizer loop.

### Three Coupled Challenges

The historical outline framed the problem as three coupled challenges:

1. **Temporal grounding mismatch**  
   `session_time` records when something was mentioned, while `event_time`
   records when the event actually happened. These may differ by days, months,
   or years.

2. **Faithfulness risk under compression**  
   A model can turn uncertain cross-session inference into a statement that
   looks like an observed fact. This is important when memory output is
   compressed before being passed downstream.

3. **Hidden dependencies**  
   Users often remember qualifiers rather than exact targets. A query such as
   "the book I was reading during the week after my promotion" requires the
   system to first find the promotion event and infer a time window before it
   can retrieve the book evidence.

The final NeurIPS paper compresses these ideas. The thesis should expand them
with examples.

### Mention Event Versus Happened Event

One historical comment contains a useful conceptual distinction:

When a user says "I traveled to Europe last week" during an April 2 session,
there are two events:

- the user mentioned the trip on April 2;
- the trip happened during the previous week.

An ingest-side system that stores only the travel event may lose the mention
event. A system that stores both as fixed memories can confuse retrieval.
This motivates search-time, query-conditioned evidence construction rather than
only write-time memory extraction.

Suggested thesis use:

- Add this example to the Introduction or Background.
- Use it to explain why event interpretation can be query-dependent.
- Use it to motivate why NanoMem constructs evidence during search.

### Temporal Multi-Hop / Temporal Bridge Example

Historical drafts repeatedly used this example:

> "What book was I reading during the week I got promoted?"

The necessary process is:

1. retrieve the promotion session;
2. infer the promotion event time;
3. derive the relevant week or time window;
4. use that time window to search for reading/book sessions;
5. synthesize the final evidence for the downstream answerer.

This example should be retained in the thesis because it is easy to understand
and cleanly demonstrates why one-shot retrieval fails.

## Related Work Material To Recover

### Write-Side Versus Search-Side Memory

The historical outline divides memory systems into write-side and search-side
approaches:

- **Write-side memory systems** perform goal-agnostic extraction, compression,
  linking, or graph construction before the future query is known.
- **Search-side systems** preserve or retrieve information at query time and can
  adapt to the current query.

Systems mentioned in historical notes:

- write-side / memory management: MemGPT, Mem0, A-MEM, MemoryBank, MemReader,
  Mem-alpha, Memory-R1, MemOS, Zep, HyperMem, MemPalace;
- search-side / retrieval: SUMER, MemR3, MemSifter, Memory-T1;
- general reflective RAG/search: Self-RAG, SmartRAG, Search-R1, RAG-RL, RPO,
  SSFO, TreeGRPO, Stratified GRPO.

Suggested thesis use:

- Use this taxonomy in Related Work.
- It is clearer for a thesis than only listing individual papers.
- End the section by explaining that NanoMem is search-side and evidence-centric.

### Search-Side Memory Retrieval Categories

The historical outline further divides search-side work into:

1. **Passive retrieval**  
   Standard RAG or embedding-based top-k retrieval. It is simple but often
   misses temporal or indirect evidence.

2. **Ranking proxies**  
   Systems such as MemSifter or Memory-T1 rank candidate sessions using learned
   or temporal signals. They improve selection but may still not synthesize
   structured evidence or maintain event-time state.

3. **Iterative/reflective retrieval**  
   Systems such as SUMER or MemR3 use feedback loops or gap states. Their loop
   state is usually raw snippets, answer-oriented reasoning, or textual gap
   summaries, not structured event evidence.

NanoMem can be positioned as a hybrid: it uses iterative retrieval, but its
state is structured evidence (`event_time`, `session_time`, source session,
verdict), not just text snippets.

### RL For Memory And Retrieval

Historical drafts emphasize that prior RL-based memory work often optimizes:

- write-time memory extraction;
- session selection;
- final answer accuracy;
- compression or retrieval behavior.

NanoMem applies RL to the intermediate evidence-construction policy itself. The
important distinction is that the trained Synthesizer is rewarded for producing
evidence that is parseable, compact, temporally grounded, and sufficient for a
downstream answerer.

Suggested thesis use:

- Use this to explain why outcome-only reward is insufficient.
- Connect it to the verdict reward and evidence construction policy.

## Methods Material To Recover

### Earlier Two-Stage Architecture

Early architecture drafts described NanoMem as:

1. a slim ingest stage;
2. a ReAct-loop-style search stage.

The ingest stage was described as:

- temporal preprocessing over session text;
- semantic chunking into coherent chunks;
- chunk summary generation for indexing;
- embedding generation and storage in a vector database.

The search stage was described as:

- Planner decomposes the user query into retrieval cues;
- Retriever performs hybrid dense/BM25 retrieval;
- Synthesizer compresses retrieved sessions into temporal evidence events;
- verdict controls loop continuation.

This is useful for a thesis even if the final implementation has evolved,
because it gives a clear architecture narrative. Verify exact implementation
details before writing final LaTeX prose.

### Deterministic Temporal Normalization

Architecture notes give a very concrete design philosophy:

- Use deterministic rules where possible.
- Extract relative temporal phrases such as "last week", "yesterday", and
  "next month".
- Anchor them to the session timestamp or query timestamp.
- Insert the resolved absolute time span into the text.

Example:

```text
last week I went to Paris
```

becomes:

```text
last week (2023-04-07 to 2023-04-13) I went to Paris
```

The reason is practical: this converts part of temporal reasoning into lexical
or semantic matching. If a session says "next week" and a later query says
"two weeks ago", both can be normalized to the same absolute date span, allowing
BM25/dense retrieval to find the session.

Suggested thesis use:

- Include this as a design rationale in Methods.
- It is more explanatory than the final NeurIPS text.
- Verify current code before claiming exact regex coverage or exact date format.

### Query Temporal Hints

Historical notes state that temporal hints should be extracted from the original
user query, not from Planner-generated cues.

Reason:

- The original query is the cleanest user signal.
- Planner cues are model-generated and may introduce errors.
- Extracting time from generated cues would add another uncertain model layer.

Temporal hints should preserve both:

- the original phrase;
- the resolved absolute time or interval.

Example:

```text
("last week", "2023-04-14 to 2023-04-20")
```

This is useful for the thesis because it shows a concrete design decision:
deterministic time parsing is kept close to the original user input.

### Annotated Query For Retrieval

Historical notes describe a retrieval enhancement: insert the resolved absolute
time into the query text itself before retrieval. This makes temporal alignment
visible to BM25 and embedding search.

Suggested thesis use:

- Mention as a method detail if implemented in the final code.
- If not implemented, it can still be described as an explored design
  alternative in Discussion or Appendix, but must not be stated as final system
  behavior without verification.

### Hybrid Retrieval Details

Early drafts included a hybrid score:

```text
score = lambda * dense_embedding_similarity + (1 - lambda) * BM25
```

They also described selecting the highest chunk similarity within a session and
then taking top-k sessions per cue.

Historical notes mention an approximate dense/BM25 weighting of `0.75 / 0.25`.
This should be verified in the actual code before final writing.

Suggested thesis use:

- Use the hybrid retrieval explanation in Methods.
- Put exact weights in implementation details only after verification.

### Design Evolution: Hard Temporal Filtering Versus Soft Hints

There is a useful historical design tension:

- An early `arch.tex` version described mention-time filtering, where sessions
  whose session timestamps fall outside a mention-time span are filtered out.
- Later architecture notes state that no hard temporal filtering is applied and
  temporal information is used as hints and retrieval enhancement.

This conflict is valuable for thesis discussion because it shows why hard time
filters are risky:

- event time and session time can differ;
- hard filtering can discard the target session;
- using event time as a hint is safer than using it as a strict filter.

Final thesis prose must verify which behavior is implemented before presenting
the final method.

### Synthesizer Output Schema Evolution

Historical schema included:

```xml
<event
  session_id="..."
  session_time="..."
  event_time="..."
  inferred="true|false">
  ...
</event>
```

Later reward notes record a design decision to remove `inferred`:

- its semantics were ambiguous;
- temporal normalization itself can look like inference;
- models may mark everything as inferred to avoid faithfulness checks;
- removing it reduces the attack surface and simplifies training.

Historical schema also included `indicative` verdict, later removed:

- `sufficient` and `indicative` behaved identically downstream;
- keeping both would require extra experiments;
- final verdict space became `sufficient | insufficient`.

Suggested thesis use:

- The final thesis should describe the final implemented schema.
- The design evolution can be useful in Discussion if explaining why the schema
  was simplified.

### Temporal Hints Pool Across Rounds

One of the most useful historical design notes is the cross-round temporal hints
pool:

- first round: contains temporal hints parsed from the original query;
- later rounds: if Synthesizer outputs an event whose `event_time` differs from
  `session_time`, add that event text and event time into the hints pool;
- the next retrieval round can use this inferred time as a search condition.

This expresses the core idea very clearly:

> the Synthesizer's temporal inference becomes the next round's deterministic
> input.

Suggested thesis use:

- This belongs in the Methods chapter.
- It is a strong explanation of how temporal reasoning drives iterative
  retrieval.
- Verify final implementation before making exact claims about the pool update
  rule.

### Event Time Difference As A Signal

Historical notes propose `event_time != session_time` as a simple signal that
the model has performed non-trivial temporal reasoning. If equal, the event is
assumed to happen at the session time; if different, the resolved event time may
be useful for further retrieval.

Suggested thesis use:

- Use this as an intuitive explanation of why event-time metadata matters.
- Avoid treating it as a universal rule unless the final code implements it.

### Final Events Only Versus Accumulated Events

Reward notes record a design decision: use only the final round's events for
the downstream answer model, not all events accumulated from earlier rounds.

Reasoning:

- earlier rounds may contain incomplete or misleading events;
- using all rounds blurs credit assignment;
- a `sufficient` verdict means the current output should be enough.

This is useful for Methods and Discussion because it clarifies the meaning of
the terminal Synthesizer output.

## Reward And Training Material To Recover

### Train Only The Synthesizer

Historical notes strongly justify freezing the Planner and training only the
Synthesizer:

- Planner cue generation is closer to standard query rewriting.
- Synthesizer performs the difficult work: event extraction, event-time
  inference, and sufficiency judgment.
- Training both would make credit assignment harder: when an answer fails, it
  becomes unclear whether the Planner or Synthesizer caused it.
- Freezing the Planner gives cleaner reward attribution to the Synthesizer.

Suggested thesis use:

- Put this in Methods under training design.
- It is a good thesis-style design rationale.

### No SFT Warm-Up Decision

The historical outline originally proposed SFT warm-up using strong-model
demonstrations. Later reward notes record the opposite decision: base model XML
format compliance was already high, so direct GRPO was preferred.

Rationale:

- SFT demonstrations may introduce teacher-model bias.
- GRPO benefits from exploration.
- A format penalty is enough to prevent schema collapse.

Suggested thesis use:

- Use this only if it matches final training.
- Otherwise, present it as a design alternative considered during development.

### Reward Components

Historical reward design converges to:

1. **Format reward / penalty**  
   Ensures Synthesizer output is parseable XML with required fields.

2. **Verdict reward**  
   Teaches the model whether the current retrieval state is sufficient. It is
   computed using cumulative retrieved sessions compared against gold evidence
   sessions.

3. **Outcome reward**  
   Pass terminal evidence to a downstream answer model, then evaluate answer
   correctness against the gold answer.

4. **Length reward**  
   Encourages compact evidence, but only when outcome is correct.

Historical notes also explain why faithfulness reward was removed:

- it depended on the removed `inferred` field;
- it risked unreliable judging and reward hacking;
- event quality is indirectly controlled by outcome and format/verdict signals.

Suggested thesis use:

- The final thesis should explain both the reward formula and the intuition of
  each component.
- The "why not faithfulness reward" reasoning is useful for Discussion or
  limitations.

### Verdict Reward Based On Retrieved Sessions

Historical notes make a subtle but important point: verdict reward should use
the sessions retrieved by the system, not only sessions cited by the Synthesizer.

Reason:

- Verdict asks whether the current available evidence is sufficient.
- If the retriever already found all gold sessions, the Synthesizer should
  recognize sufficiency.
- If reward used only cited sessions, the Synthesizer could omit a gold session
  and be rewarded for saying insufficient.

Suggested thesis use:

- This is a strong methodological detail for the training section.

### Length Reward Only If Outcome Is Correct

Historical notes give a clear anti-shortcut rationale:

- If length reward is unconditional, the model can output extremely short,
  uninformative evidence.
- Conditioning on correct outcome means length reward means "be concise after
  being correct".

Suggested thesis use:

- Include this in reward design explanation.

### No Separate Temporal Reward

A useful historical decision: do not necessarily need a separate event-time
reward if event-time mistakes affect later retrieval and final answer accuracy.

Logic:

- wrong event time enters temporal hints or final evidence;
- this misguides subsequent retrieval or answer generation;
- the final outcome reward penalizes the trajectory.

Suggested thesis use:

- This can be used to justify a simpler reward design.
- Treat carefully: it is a design argument, not proof that temporal reward is
  unnecessary in all settings.

## ChainMem / Benchmark Material To Recover

### Hidden-Dependency Benchmark Framing

Historical notes frame ChainMem as a benchmark for hidden-dependency evidence
search, not merely "multi-hop QA".

Core invariant:

```text
A valid example requires at least one search cue that cannot be known from the
original question alone. The cue must be discovered from earlier retrieved
evidence.
```

This should be reused in the thesis. It clearly explains why standard
benchmarks are incomplete for NanoMem's target problem.

### Anchor, Bridge, Terminal Evidence

Historical notes define each example as a chain:

- **anchor evidence**: directly addressable from the original query;
- **bridge**: intermediate entity, time window, or causal event discovered from
  the anchor;
- **terminal evidence**: evidence that contains the final answer but can only be
  retrieved after resolving the bridge.

Bridge types:

- entity/content bridge;
- temporal bridge;
- causal bridge.

Terminal types:

- entity/content terminal;
- temporal terminal;
- causal terminal.

Suggested thesis use:

- This belongs in Methods or Benchmark Construction.
- It can also support a figure.

### Event-Graph-First Construction

Historical notes describe ChainMem construction as event-graph-first:

1. start from a user profile and ordinary life events;
2. select a branchable anchor event;
3. extend into downstream events through explicit bridge edges;
4. validate non-leakage constraints;
5. add distractor events sharing surface templates or anchor tokens;
6. realize events as multi-turn sessions while preserving evidence provenance.

This is valuable thesis content because it explains how benchmark validity is
protected:

- the question must not reveal the resolved bridge or answer;
- anchor evidence must support the remembered qualifier;
- terminal evidence must contain the bridge and answer without leaking the
  original qualifier;
- distractors make lexical overlap insufficient.

## Experiments Material To Recover

### Early Experiment Research Questions

An early experiment section explicitly defined four evaluation questions:

1. How does NanoMem perform compared with existing memory systems under long
   conversational histories and complex user queries?
2. Does temporal-event grounding improve temporal reasoning in agent memory?
3. Does NanoMem improve questions whose evidence is indirectly addressable
   through entity, temporal, or causal bridges?
4. Does GRPO improve grounding quality and sufficiency-gap detection beyond
   vanilla models?

These are useful for the thesis Results and Discussion chapters. They map cleanly
to the thesis research questions.

### Evidence-Provider Versus Direct-Answerer Evaluation

Historical eval drafts define two evaluation settings:

- **Evidence-provider methods** return evidence or retrieved context. A fixed
  answerer generates final answers from that evidence. This isolates evidence
  quality from final answer generation.
- **Direct-answerer methods** are evaluated by their native final answers.

This distinction is very important for the thesis because NanoMem is intended as
a memory module, not a final answer model.

The answerer changed historically:

- early draft: fixed GPT-5.1 answerer;
- later commit: fixed Qwen3.5-9B answerer.

Final thesis must use the actual final evaluation configuration.

### Benchmark Roles

Historical eval text gives clear roles:

- **LoCoMo**: general long-term conversational memory, single-hop, multi-hop,
  temporal reasoning, open-domain questions.
- **LongMemEval**: long-term memory for chat assistants, information extraction,
  memory updates, abstention, temporal reasoning.
- **Time-Dialog**: focused temporal reasoning setting following Memory-T1
  if used in final evaluation.
- **ChainMem**: indirectly addressable questions where an intermediate bridge
  must be recovered before final evidence can be retrieved.

Suggested thesis use:

- Use this to explain why each benchmark is included.
- Do not simply list datasets; explain the diagnostic role of each.

### Baseline Categories

Historical eval text groups baselines into:

1. full-context baselines;
2. write-time memory systems;
3. search-time reflective retrieval systems;
4. temporal memory / temporal reasoning agents;
5. NanoMem vanilla and NanoMem-GRPO variants.

This grouping should be reused in the thesis because it makes the experimental
comparison easier to understand.

### Token Metrics

Historical eval text explains why memory output tokens are reported instead of
only total consumed tokens:

- different methods spend computation in different places;
- full-context methods spend tokens in the answerer;
- NanoMem and Memory-T1 spend tokens on search/synthesis;
- memory output token count reflects how much evidence/context is passed to the
  downstream model.

Suggested thesis use:

- Put this in Experimental Setup.
- Discuss total cost/latency separately as a limitation if not fully measured.

### Ablation Ideas

Historical drafts proposed and partially implemented these ablations:

- remove text normalization;
- remove Temporal Evidence Pool;
- single-round versus multi-round retrieval;
- remove format and length rewards;
- remove verdict reward;
- outcome-only reward;
- schema field ablation for `event_time`, `inferred`, and `verdict` in earlier
  designs;
- compare vanilla Synthesizer versus GRPO-trained Synthesizer.

Useful interpretation from history:

- Text normalization mainly helps temporal categories.
- Temporal Evidence Pool helps broadly and especially helps indirect evidence.
- Single-round retrieval may reduce noise for directly answerable temporal
  questions but hurts multi-hop or ChainMem-style cases.
- Removing verdict reward hurts cases that require recognizing incomplete
  evidence and continuing search.
- Removing format/length reward can lead to bloated evidence.

## Suggested Thesis Integration Map

Use the recovered material as follows:

| Thesis chapter | Historical material to reuse |
|---|---|
| Introduction | memory-as-evidence-provider, evidence addressability gap, three coupled challenges, mention event vs happened event, temporal bridge example |
| Background | long-term memory concepts, RAG, event time/session time, temporal reasoning limits of LLMs |
| Related Work | write-side vs search-side taxonomy, passive/ranking/iterative retrieval, RL for memory |
| Methods | two-stage architecture, deterministic temporal normalization, query hints, hybrid retrieval, schema evolution, temporal hints pool, final-events-only design |
| Results | experiment RQs, benchmark roles, baseline categories, evidence-provider vs direct-answerer setting, token metrics |
| Discussion | hard filtering vs soft hints, removed schema fields, reward design alternatives, no separate temporal reward, limitations of outcome-only supervision |
| Appendix | old cue/event XML schemas, ChainMem construction details, reward formulas and implementation notes |

## Verification Warnings

Before using any historical detail in final LaTeX prose, verify it against the
current code or final experiment scripts. Several ideas changed over time:

- `inferred` was present in early schema but later removed.
- `indicative` verdict was present in early schema but later removed.
- early drafts discussed SFT warm-up; later notes argued for direct GRPO.
- early architecture described hard mention-time filtering; later notes favored
  temporal hints without hard filtering.
- early eval used GPT-5.1 as fixed answerer; later eval switched to Qwen3.5-9B.
- exact dense/BM25 weights and top-k values must be checked in the code.

These historical notes are intended to enrich the master's thesis, not override
the final implemented system.

