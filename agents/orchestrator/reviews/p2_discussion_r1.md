# Review p2 / discussion / round 1
verdict: needs_revision
artifacts: paper/include/Conclusion.tex
writer_round_id: 24

## Blocking issues
1. LOCATION: `paper/include/Conclusion.tex`，第 311--348 行，`\section{Ethical, Privacy, and Safety Considerations}`
   PROBLEM: 本节系统讨论了隐私、同意、访问控制、高风险场景和 benchmark safety gap，但没有讨论生态/环境/可持续性影响，也没有明确说明为何该维度可以省略。
   WHY: 这是最终 Discussion/Conclusion 章，不只是技术总结。Chalmers 评价维度要求 thesis 处理 societal、ethical、ecological、sustainability aspects；对 NanoMem 这类 LLM memory 系统，环境成本尤其来自训练、GRPO rollout、LLM judge、下游 answer model、重复检索和多轮推理。当前章节若只写 privacy/safety，会让论文在 Chalmers hard rule 的 sustainability 维度上不完整。
   BASIS: `spec.md` 的 Chalmers hard rules 明确要求 “SOCIETAL / ETHICAL / ECOLOGICAL / SUSTAINABILITY: must be discussed (or explicitly justified if omitted)”，并对 NanoMem 预期包含 “environmental cost of training/eval”。`thesis_rules.md` 也要求加入清晰的 sustainability/ethics/societal-impact discussion。参考 thesis 的共同模式是把 ethics/environmental/validity/limitations 作为结论或讨论中的显式评价维度，而不是只覆盖隐私。
   FIX: 在本节或单独新增一个短小 subsection，补充 NanoMem 的环境与可持续性讨论：说明多轮 retrieval、Synthesizer 训练、GRPO rollout、GPT-5.1 answer/judge evaluation 和 benchmark reruns 带来的计算/能源成本；区分 NanoMem 减少 downstream evidence tokens 与没有证明 end-to-end carbon/energy efficiency；给出实际缓解方向，如缓存、预算控制、小模型/本地模型、减少不必要 rerun、报告硬件/模型调用边界。若没有能量或碳排数据，应明确写成 limitation，而不是给出未验证数字。

2. LOCATION: `paper/include/Conclusion.tex`，第 30--38 行，`Answers to the Research Questions` 对 RQ1 的回答
   PROBLEM: RQ1 在 Introduction 中要求 “source-grounded structured evidence, with explicit session time, event time, and inference markers”，但本章对 RQ1 的回答只提到 evidence statement、source session identifier、session time 和 event time，没有解释最终方法已经取消独立 `inferred` 字段后，论文如何满足或修正 “inference markers” 这一要求。
   WHY: Discussion/Conclusion 必须直接回答 Introduction 中提出的研究问题，并且回答要与 Methods 的最终 schema 一致。当前 Methods 第 298--304 行已经说明旧的 `inferred` attribute 被删除，inference boundary 改由 source attribution、separate events 和 reasoning field 表达；如果 Conclusion 不显式回收这个变化，读者会看到 RQ1 承诺了 explicit inference markers，但最终答案没有说明该承诺是如何被实现、替代或限定的。
   BASIS: `spec.md` 的 assessment axis D 要求 Problem formulation 与 Conclusions 直接对应；axis C 要求贡献清楚呈现；Chalmers high-quality bar 要求结论有充分依据而不是留下概念断裂。项目主线要求一直区分 raw sessions、retrieved chunks、synthesized evidence、final answers，以及 supported facts、cross-session reasoning 和 unsupported claims。
   FIX: 修改 RQ1 的回答，使其明确对齐最终 schema：说明 NanoMem 保留了 source/session identifier、session_time 和 event_time；同时说明最终实现没有独立 `inferred` XML attribute，而是通过 single-source event attribution、多个 source-grounded events、以及 `reasoning`/verdict 边界来避免把跨 session 推理伪装成直接观察。若 Introduction 的 RQ1 wording 保持不变，本章必须解释这种替代关系；若后续允许修改 Introduction，也应让 RQ wording 与 final schema 同步。

## Suggestions
- 第 86--95 行关于 verdict 和 reward diagnostics 的表述已经比较谨慎，但建议再避免 “sufficiency control must be trained” 这种容易被读成已验证 reward 因果结论的句式。依据是 Methods 和 Results 均保留了 reward synchronization marker；Discussion 最好始终说 “the observed diagnostics support treating stop/continue as an explicit supervised or controlled decision”，而不是暗示当前 reward 已完整证明该点。
- 第 190--230 行的 validity discussion 很有用；建议在修订 sustainability 时也与 reproducibility threat 衔接，提醒最终 appendix 记录模型调用边界和 run directories。依据是 Chalmers traceability/honesty 要求以及 Results 章中已有的 synchronized artifact caveats。

## Summary
本章整体结构符合 phase-1 规划：它回答 RQs，讨论 design lessons、failure modes、validity、deployment、ethics、future work，并且语气克制，基本接近 Chalmers thesis 的 discussion/conclusion register。阻塞点不是篇章框架，而是两个必需对齐项：Chalmers 要求的生态/可持续性维度缺失，以及 RQ1 与最终 evidence schema 之间的 “inference markers” 断裂没有在结论中解释清楚。优先先补 sustainability/ecological discussion，再修正 RQ1 answer 与 Methods schema 的一致性。
