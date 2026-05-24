# Review p2 / methods / round 3
verdict: needs_revision
artifacts: paper/include/Methods.tex
writer_round_id: 18

## Blocking issues
1. LOCATION: `Reward Design`, lines 411-424, 426-492; `Implementation Boundary`, lines 624-634; `Chapter Summary`, lines 663-667
   PROBLEM: 本章仍没有把 GRPO reward contract 固定成一个可作为 thesis 方法的最终版本。当前正文一方面承认 faithfulness reward 还不能作为 verified active component，并保留非图表类 `TODO`；另一方面又给出 “intended full reward” 和 “executable reward subset” 两套公式，并说明 verdict 不是 active additive reward，只通过终止行为间接影响 outcome。读者无法判断 Chapter 4 到底应该评估哪一个训练目标：是包含 faithfulness 的计划版本、只含 format/outcome/length 的可执行版本，还是还要恢复 phase-1 规划和 NeurIPS appendix 中的 verdict reward。
   WHY: Methods 章必须定义实际使用并将被 Results 检验的方法，而不能把核心训练目标留成条件分支。Reward 是 NanoMem 方法的关键组成部分，直接关系到 sufficiency behavior、source faithfulness、compactness 和 downstream answer quality 的解释。如果本章不决定最终 reward 版本，后续 Results 章关于 GRPO 训练、reward ablation、verdict behavior 或 learned evidence faithfulness 的任何结论都会缺少可追踪的方法基础。
   BASIS: spec 对 Phase 2 的要求是评价“actual writing”的正确性、完整性、与 phase-1 plan 的一致性、可追踪性和学术严谨性；Chalmers 规则要求 Method、Results、Discussion 逻辑相连，技术 claim 必须可由代码、实验或明确 reasoning 支撑；phase-1 Methods 计划第 3.6-3.7 节要求正文给出完整 trajectory、token masking 和 reward components，并明确 Results 的接口；三篇 Chalmers 范文的 Method/Methodology 章共同模式都是说明已选择的方法、实现流程和实验设置，而不是在核心方法处留下未决实现 `TODO`。当前源码也支持这个问题判断：`training/grpo/trainer/schemas.py` 的 `SynthesizerEvent` 没有 `inferred` 字段，而 `training/grpo/trainer/rewards.py` line 133 仍访问 `event.inferred`；同时该 reward pipeline 没有单独的 verdict reward component。
   FIX: 必须把正文改成一个单一、可追踪、可被 Results 复用的最终方法版本。若最终论文要报告包含 faithfulness 和/或 verdict supervision 的 GRPO，则先同步实现或实验记录，再在 Methods 中只保留那一套 reward 公式、权重、触发条件和 failure modes，并删除 “planned/executable subset” 的分叉叙述和非图表 `TODO`。若实际可报告的训练只使用 format、outcome、length，则正文应明确这就是 final reported reward objective，删除 intended full reward 公式，把 faithfulness 与 verdict supervision 降级为 method requirement、diagnostic analysis 或 limitation，并同步修改 chapter summary 和 Chapter 4 接口，避免声称训练直接优化 source faithfulness 或 verdict correctness。

## Suggestions
- `Temporal Normalization and Hints` 与 `Planner--Retriever--Synthesizer Loop` 已经把 `hard_mention`、BM25/dense 权重、top-seven 和 reranker-off 的实现边界写清楚；后续 Results 章需要按同一配置解释 retrieval failure，否则会削弱方法-结果对应关系。
- 图表占位符本身可以保留；这些 TODO 属于预期的 figure placeholders，不是本轮的阻塞问题。

## Summary
本轮 Methods 的整体结构、学术语气、系统边界、temporal evidence schema、ChainMem 构造和实现映射已经基本达到方法章节要求。仍然不能通过的唯一阻塞点是 reward contract 没有收敛：本章必须决定最终训练目标，而不能把核心 GRPO 方法写成计划版与可执行版并存。优先固定 reward 版本，并让 Methods、Implementation Boundary、Chapter Summary 和后续 Results 接口保持同一套说法。
