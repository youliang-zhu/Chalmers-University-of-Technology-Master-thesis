# Review p1 / discussion / round 1
verdict: pass
artifacts: paper/sections_drafts/05_discussion.md
writer_round_id: 9

## Suggestions
- 在第二阶段写正文前，统一 `TimeMemEval`、`ChainMem` 和 `\bench` 的命名，并在第一次出现时解释是否为同一诊断 benchmark 的正式名与别名。依据：spec 要求技术 claim 和实验对象可追溯，Chalmers 高质量论文写作要求 Results/Discussion 中的术语和对象保持一致；当前 Results 规划也已经提示需要统一命名。
- 5.1 和 5.8 已经计划回扣 RQ，但最终正文应显式把每个 research question 的回答与第四章证据对应起来，而不是只做总括性总结。依据：Chalmers assessment 强调 problem formulation 与 conclusions 必须直接相连；参考 thesis 的 Discussion/Conclusion 通常先回答研究问题，再展开 limitations、validity、ethics 和 future work。
- 5.3 中关于 “删除 `inferred` 字段和三值 `indicative` verdict” 的表述，第二阶段写正文时要以 Methods 章最终 schema 和源码/论文 prompt 为准逐项核对。依据：NanoMem 当前 NeurIPS 方法稿使用包含 `event_time`、`session_time`、source/session id 和二值 `sufficient|insufficient` verdict 的 XML schema；project context 中仍保留过 `inferred` 与三值 verdict 的早期表述。最终 thesis 不能让 Discussion 与 Methods/Appendix 的 schema 冲突。
- 5.6 的伦理、隐私与安全覆盖了长期 memory 的核心风险；最终正文还应至少一句说明生态/计算成本边界，例如 iterative retrieval 的额外 LLM 调用、训练/评估成本和部署中的 cost-aware control。依据：Chalmers rules 要求 societal、ethical and ecological aspects 被讨论或说明为何不适用；当前 5.5 已经讨论 latency/cost，5.6 可轻量连接到 ecological/sustainability 维度。
- 图表计划总体合理，但 5.2 的诊断边界图如果保留，应避免和 Methods 架构图重复。依据：spec 的图表标准是“图表必须真实帮助理解，而不是填数量”；本图的价值应定位为 failure boundary / responsibility boundary，而不是再次画系统流程。

## Summary
本轮 Discussion 规划达到 phase 1 要求，可以通过。它显著扩展了 NeurIPS 的压缩 conclusion，把研究问题回答、设计启示、失败模式、validity threats、部署治理、伦理隐私、future work 和最终结论组织成了完整的硕士论文讨论框架。后续最需要注意的是术语/schema 一致性，以及在最终 Conclusion 中明确逐条回答研究问题，避免只做宽泛总结。
