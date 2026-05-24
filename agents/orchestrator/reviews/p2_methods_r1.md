# Review p2 / methods / round 1
verdict: needs_revision
artifacts: paper/include/Methods.tex
writer_round_id: 16

## Blocking issues
1. LOCATION: `Temporal Normalization and Hints`, lines 198-211; `Planner--Retriever--Synthesizer Loop`, lines 264-271; `Implementation Boundary`, lines 576-580
   PROBLEM: 正文同时声称 temporal information 应作为 hint 而不是 universal hard filter，又留下 TODO 说明 GRPO rollout path 可能使用 `temporal_filter_mode=hard_mention` 且关闭 reranker。后文还把 dense/BM25 权重、top-k、reranker 设置推迟到 Chapter 4 或 appendix，但 Methods 章没有给出本章方法到底采用哪一种 retrieval/temporal-filter 行为。
   WHY: Methods 章必须给出可追踪的方法定义和方法选择理由；这里的检索边界是 NanoMem 的核心机制之一，直接影响“event_time 如何成为下一轮 search cue”和后续 Results 的可解释性。若 final experiments 实际使用 hard mention filter，而正文主张 soft hint，读者会误解系统行为；若 soft hint 是设计目标但代码/配置未对齐，正文又会变成未验证声明。
   BASIS: spec 对 Methods 的标准是“justify WHY each NanoMem design choice suits the problem”并且“every technical claim must be traceable to literature, code, experiments, or clearly marked reasoning”。Chalmers rules 要求方法、结果、讨论逻辑相连且技术 claim 可公开审查。Phase-1 Methods 计划也明确要求“正式正文应让读者能够从问题定义一路追踪到代码和实验设置”，并列出 dense/BM25、top-k、reranker、hard filtering 必须在第二阶段核对。
   FIX: 核对最终用于报告实验的 retrieval 配置和代码路径后，把这一组段落改成单一一致版本。若实验使用 `hard_mention`，就明确说明 hard filter 的适用范围、为什么仍符合 NanoMem 的方法边界、它带来的 recall 风险，以及表 3.2 中“Prefer hints over universal session-time filtering”如何改写。若实验不使用 hard filter，就删除 hard-filter TODO，并在 Methods 或实现映射表中指出实际配置来源和 Chapter 4 将报告的参数。

2. LOCATION: `Reward Design`, lines 392-453; `Training the Synthesizer with GRPO`, lines 361-374; `Implementation Boundary`, lines 569-597
   PROBLEM: reward 描述与当前实现不一致。正文把 reward 定义为 format, verdict, outcome, compactness 四项，并给出 `R_ver` 公式；但当前 `training/grpo/trainer/rewards.py` 的 active components 是 `format`, `faithfulness`, `length`, `outcome`，没有 verdict reward component，而且该 faithfulness path 仍引用 `event.inferred`。正文自己在 lines 448-453 留下 TODO 说明这个冲突尚未解决。
   WHY: GRPO training objective 是本章的核心方法之一；如果 reward component 写错，后续 Results 中任何训练效果、消融、失败分析都无法被正确解释。把未实现或旧版本的 reward 写成 final method 也违反技术 claim traceability，尤其是 verdict correctness 是 NanoMem 的关键贡献，不能在没有实现证据时作为训练信号陈述。
   BASIS: spec 的 Methods 通过标准要求“correct application; not just what but why this”，并要求训练、reward、verdict 等 claim 对应代码、实验或明确 reasoning；Chalmers condensed rule 也强调 no fabricated experiment numbers/results/technical claims。Phase-1 Methods 计划第 3.7 节特别要求核对 `training/grpo/trainer/rewards.py`、appendix algorithm 和最终实验 config，不能同时声称互相冲突的 reward 版本。
   FIX: 先确定 reported checkpoint 实际使用的 reward pipeline，然后重写本节的 component list、公式、表 3.4 和 implementation mapping。若最终代码确实使用 faithfulness reward，就把它作为正式 component 解释清楚，并说明它如何处理或不再需要 `inferred` 字段；若 verdict reward 是最终方法，就必须指向实现它的代码/config，并删除旧 faithfulness path 对 final method 的影响。不要保留“当前 paper draft 与训练 module 不一致”的 TODO 作为 Methods 正文的一部分。

3. LOCATION: `Planner--Retriever--Synthesizer Loop`, lines 282-288; chapter-level consistency with the thesis RQs
   PROBLEM: Methods 章断言 final schema 是 binary verdict 且删除了 `inferred` attribute 和 `indicative` verdict，但 thesis 当前 Introduction/RQ 仍把 inference markers 写成 NanoMem 表征的一部分，frontmatter/nomenclature 也仍出现 `indicative`。本章没有说明这个设计收缩如何影响 RQ1 中“source-grounded structured evidence with explicit session time, event time, and inference markers”的承诺。
   WHY: 方法章不能只在局部宣布 schema 改动而不维护 thesis mainline。若最终 schema 没有 inference marker，RQ1、Abstract、Nomenclature 和 Methods 的贡献定义会互相冲突；若 schema 仍需要 inference marker，则 Methods 当前字段定义不完整。
   BASIS: spec 要求“Contribution clearly presented”和“Problem formulation ↔ conclusions”直接对齐，读者不应猜测 NanoMem 的新意到底包含哪些字段。Phase-1 plan 第 3.1 节允许最终实现优先采用 event text、`session_id`、`session_time`、`event_time` 和二值 verdict，但也明确要求设计演化不能在核心方法里产生冲突。
   FIX: 在 Methods 中明确 final schema 相对 RQ1 的解释：要么恢复/定义 inference marker 并与 parser/reward 对齐；要么把 RQ1 的“inference markers”降级为早期设计动机或 Discussion 中的设计演化，并在允许修改相关章节时同步 Introduction、Abstract、Nomenclature。当前 Methods 至少要避免把“removed”写成孤立结论；需要说明删除后的 faithfulness/grounding 风险如何被 schema 或 reward 处理。

## Suggestions
- `Problem Formulation` 的符号表可以加入 event text 字段本身；Phase-1 表 3.1 计划列出了 event text，目前表中只有 XML attributes 和 verdict，读者要到 3.3 才看到 text 字段。
- `ChainMem Benchmark Construction` 已有流程和变量表，但没有说明样本规模、split 或 filtering statistics 将在哪里报告。可以在本节末尾加一句指向 Results/appendix 的具体接口，避免 Methods 和 Results 脱节。
- 多个 figure placeholder 是允许的，但 caption 里最好保持“planned/placeholder”之外的最终学术语气；人类替换图后 caption 应能直接保留。

## Summary
本章结构完整，基本覆盖了 Phase-1 Methods 规划中的问题形式化、架构、evidence pool、loop、GRPO、reward、ChainMem 和实现边界。但当前不能 pass，因为两处核心方法声明仍未和实现对齐：retrieval/temporal filtering 与 reward objective。优先先固定 reward section，因为它决定了 NanoMem 到底训练了什么；随后统一 temporal hint/hard filter 的方法描述和实现映射。
