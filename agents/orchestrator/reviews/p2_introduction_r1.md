# Review p2 / introduction / round 1
verdict: needs_revision
artifacts: paper/include/Introduction.tex; paper/include/settings/Settings.tex; paper/include/backmatter/References.tex
writer_round_id: 11

## Blocking issues
1. LOCATION: `paper/include/Introduction.tex` 的 `Scope and Delimitations`，第 304--306 行
   PROBLEM: 正文中仍保留了一个非图表类的红色 TODO，要求在最终版本前核对 ingestion、retrieval、answerer models 和 ChainMem 的命名及实现描述。这说明 Introduction 当前对 NanoMem 实现边界和术语的一部分尚未完成核验。
   WHY: Phase 2 产物是 LaTeX 正文，不是规划稿。图占位符可以保留，因为 workflow 明确允许 Writer 规划/标记后续由人工提供的 figures；但技术实现、benchmark 名称、answerer/retriever 设置等不是图形资产，而是正文技术 claim。若这些 claim 未核对就进入评审，会违反 traceability/honesty 要求，也会削弱 Introduction 对 RQ、scope 和后续章节结构的可靠约束。
   BASIS: spec 的 Chalmers hard rules 要求每个技术 claim 都能追溯到 literature、code、experiments 或明确标注的 reasoning，且不得留下未核实的实验、实现或 citation 信息；Phase 2 评价标准要求判断实际英文正文的 correctness 和 completeness。workflow 只把 figure placeholders 视为预期事项，并未把正文中的普通技术 TODO 视为可通过状态。project context 也明确要求不要 invent implementation details，凡是 method、dataset split、baseline、metric 或 hyperparameter 都要先对照 NanoMem paper/code 核验。
   FIX: 核对 NanoMem paper/code/experiment artifacts 后，删除该 TODO，并把 scope 句子改成已核验的范围声明。具体做法是：确认 Introduction 中使用的 ingestion、retrieval、answerer model、ChainMem、benchmark 和 evaluation protocol 名称与最终源码/论文一致；若某项仍未最终确定，不要把 TODO 留在正文里，而是在 scope 中用保守、可验证的表述限制 claim，例如只说明“the experiments described in Chapter 4 define the concrete retriever, answer model, and evaluation protocol”。不要加入未经核验的具体模型名或实验配置。

## Suggestions
- `Research Aim and Questions` 中的 RQ3 可以更明确地列出评估维度，例如 answer quality、evidence compactness、temporal grounding 和 sufficiency/verdict accuracy。依据是 phase-1 Introduction 规划稿要求 RQ3 覆盖这些维度，Chalmers/Spec 也强调 Introduction 的问题 formulation 后续要能被 Results/Discussion 直接回答。当前 RQ3 可通过，但稍显宽泛。
- `NanoMem Overview` 对 verdict 的描述应继续保持与实现一致。已读到 NanoMem reward notes/architecture 中当前 schema 使用 `sufficient` 和 `insufficient`，且 `indicative` 被标为 invalid；因此不要恢复早期规划稿中的三分类 verdict，除非代码和最终 paper 已经重新采用该 schema。
- 三个 Introduction 图占位符的位置和 caption 基本符合 phase-1 规划；后续替换图时应保持它们的功能分工：职责边界、evidence addressability gap、NanoMem workflow，避免让第一章重复 Methods 章节的细粒度架构图。

## Summary
本章整体结构、学术语气、研究问题、贡献和 Chalmers 模板设置都基本达到第一章 Phase 2 的要求；`Settings.tex` 已设置为 Master's thesis，`References.tex` 也已经切换到 BibTeX。唯一阻塞点是正文中仍有一个非图表 TODO，明确暴露实现描述尚未核验。优先处理该 TODO：完成核验、删除标记，并把范围声明改成可追溯且保守的正式正文。
