# Review p2 / results / round 1
verdict: needs_revision
artifacts: paper/include/Results.tex
writer_round_id: 20

## Blocking issues
1. LOCATION: `Main Benchmark Results`，尤其是表 `tab:results-main-summary`、`tab:results-locomo`、`tab:results-longmemeval`、`tab:results-chainmem` 以及第 496--498 行的总结性结论
   PROBLEM: 正文声称 NanoMem 与 full-context、write-time memory、search-time retrieval 和 temporal memory baselines 比较，并在总结中说 NanoMem-GRPO 相对这些 baseline “competitive with or stronger”。但是当前主结果表只保留了 full-context、Mem0、NanoMem-Vanilla、NanoMem-GRPO，遗漏了正文已经介绍的 A-Mem、MemR$^3$、Search-R1 和 Memory-T1。这样读者无法从 Results 章本身验证 “search-time retrieval baseline” 和 “temporal memory baseline” 的比较结论。
   WHY: Results 章的核心任务是支撑 RQ3：比较 NanoMem 与 write-time memory、retrieval agents、temporal memory baselines 和 full-context answer models 在 answer quality、compactness、temporal grounding、sufficiency judgment 上的表现。如果表格没有报告这些 baseline，结论就变成未证实的概括；这违反了 Chalmers 对结论必须有实验或文献可追溯依据的要求，也削弱了 thesis 的中心 claim。
   BASIS: spec 第 2.D 要求 Problem Formulation 与 Conclusions 直接相连且结论充分支撑；第 2.E 要求 Results/Discussion 对技术方案作 critical evaluation；第 6 条把 unsupported claim 视为 blocking。phase-1 Results 规划也明确要求 baseline 分成 full-context、write-time、search-time retrieval、temporal reasoning 四组，并在主结果表中体现这些比较。NanoMem 项目主线要求 RQ3 覆盖 Mem0、A-MEM、MemR3、Memory-T1、Memory-R1/RAG-style 等相关 baseline，而不是只和 Mem0 比。
   FIX: 在主结果摘要表和三个 category-level 表中补回 A-Mem、MemR$^3$、Search-R1、Memory-T1-Qwen 等已介绍 baseline，或明确把完整 baseline 表移到附录并在正文给出足够的 compact summary，使每个总结性比较都能由正文或可追溯表格支持。补表后逐段检查第 152--237 行和第 496--503 行的结论，只保留表格能直接支持的 claim。

2. LOCATION: `Architecture Ablation`，表 `tab:results-architecture-ablation` 第 311--329 行及其解释第 331--337 行
   PROBLEM: architecture ablation 表仍有大量 `TODO` 数值，正文也只说 “remaining rows must be filled”。这不是允许保留的 figure placeholder，而是 Results 章中用于验证组件必要性的实验数据缺失。并且该部分已经有可核对的 source artifact：原实验表给出了 w/o text normalization、w/o temporal evidence pool、single-round retrieval 的 LoCoMo-MH、LoCoMo-Temp、LME-TR、ChainMem 和 Avg. Rounds 数值。
   WHY: NanoMem 的方法贡献包括 temporal normalization、Temporal Evidence Pool 和 multi-round retrieval；Results 章必须用 ablation 证明这些组件分别解决什么失败模式。当前表格缺数会导致 RQ2/RQ3 与方法设计之间的证据链断开，也无法达到硕士论文要求的 critical evaluation。
   BASIS: spec 第 2.B 要求说明方法选择为什么适合问题，第 2.E 要求 ablations、alternatives considered、error analysis 和 failure cases；workflow 对 phase 2 的要求是实际 LaTeX 正文，不是计划稿。expert.md 只允许把 figure placeholders 当作正常占位；结果表中的 `TODO` 数字不是 figure placeholder。phase-1 Results 规划 4.6 明确要求报告 architecture ablation 并解释非单调现象。
   FIX: 用已验证实验 artifact 填完整 ablation 表，至少包括 w/o text normalization、w/o Temporal Evidence Pool、single-round retrieval 的所有列；随后把第 331--337 行从“待填写”改成结果解释：指出 text normalization 主要影响 temporal/ChainMem，Temporal Evidence Pool 影响更广且增加 rounds，single-round 对 hidden-dependency 下降但在部分 temporal 子类可能不降反升。不要写成每个组件在所有任务上单调提升。

3. LOCATION: `Qualitative Case Studies` 第 419--453 行与 `Error Analysis` 第 455--491 行
   PROBLEM: case study 仍是模板表和 `TODO`，error analysis 只有预期 taxonomy，没有真实 trace、代表性例子或可靠说明其依据。Results 章计划要求至少展示 2--3 个真实 case，其中包括一个 temporal bridge success、一个 baseline failure/NanoMem success 对比、一个 NanoMem failure；当前正文没有实际 query、session/source、event_time、verdict、answer/gold answer 或诊断证据。
   WHY: NanoMem 的贡献是过程性的 evidence search，而不只是 aggregate accuracy。没有真实 trace，读者看不到 event_time 如何成为下一轮 retrieval cue、verdict 如何驱动 stop/continue、错误如何在 Planner/Retriever/Synthesizer/answerer 间传播。这样 chapter 不能充分支撑 “evidence addressability gap 被 iterative evidence synthesis 缓解” 这一核心 thesis claim。
   BASIS: spec 第 2.E 要求技术方案必须 critical analysed，包括 error analysis 和 failure cases；第 2.G 要求 figures/tables 直接支持正文而不是空模板。phase-1 Results 规划 4.8 明确要求 case study 不能凭计划构造，必须来自真实 evaluation trace，并列出 query、关键 retrieved sessions、Synthesizer events、verdict、final answer、gold answer 和 diagnosis。Chalmers rules 对 traceability/honesty 的红线要求实验数字、结果和案例都必须可追溯，不能用未填模板替代结果。
   FIX: 从真实 LoCoMo、LongMemEval 或 ChainMem evaluation trace 中选至少两个高价值案例：一个成功的 temporal bridge trace，一个失败或 baseline 对比 trace。把模板表替换成真实字段值，并在 error analysis 中至少为每类主要错误给出代表性证据；如果不能可靠统计 counts，就明确写成“representative manual audit”并说明样本选择范围。保留 `TODO` 只可用于最终图像替换，不可替代 case content。

## Suggestions
- `Evaluation Protocol` 可以增加一张 baseline/model-configuration 表或把其附录位置交代清楚。basis：Chalmers/参考 thesis 的实验章节通常先界定 comparison setting，再解释结果；这能避免 reader 对不同 backbone、answerer、judge、token 含义产生误解。
- 第 354--401 行的 reward diagnostics 处理了 Methods 中的 unresolved marker，这是谨慎的；但最终修改时应让本节的 reward 名称与 Methods 的 executable reward subset 完全一致。basis：spec 的 traceability/honesty 要求不能把未同步的 intended reward 写成已经验证的 causal component。
- 图占位本身不是 blocking，但图 4.2/4.3/4.5 的 caption 应在最终图生成后与表格数值一致，尤其避免把 “output tokens” 误写成 full input/system cost。basis：phase-1 plan 已特别要求 token 指标解释要谨慎。

## Summary
本章结构总体符合 Results 章应有的顺序：protocol、main results、compactness、ablations、case studies、error analysis、summary。但当前稿件还有三个阻断问题：baseline 比较证据不完整、architecture ablation 表未填、case/error analysis 仍是模板而非真实结果。优先先补齐 baseline 和 ablation 表，因为它们直接支撑 RQ3 的定量结论；随后用真实 trace 替换 case-study 模板，使 chapter 能展示 NanoMem 的过程性贡献。
