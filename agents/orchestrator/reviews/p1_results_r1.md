# Review p1 / results / round 1
verdict: pass
artifacts: paper/sections_drafts/04_results.md
writer_round_id: 7

## Suggestions
- 在 4.3、4.5 和所有 accuracy-token 图表说明中，把 direct-answerer 的 output tokens 与 evidence-provider 的 evidence/context tokens 严格分开标注。依据：spec 要求技术结论可追溯、不可把不同计算对象混作同一指标；Chalmers 高质量结果章需要让比较协议和解释边界清楚。当前计划已经放了 TODO，第二阶段写正文时应把它落实到表注、图注和正文解释中。
- 如果真实 trace 支持，建议在 4.7 或 4.9 增加一个轻量的 evidence coverage / source-grounding audit，例如统计或人工核查 final evidence 是否覆盖 gold evidence sessions。依据：NanoMem 的主线不是只提高 final answer accuracy，而是提供 compact、source-grounded、temporally grounded evidence；spec 的贡献与技术评价轴要求结果能支撑核心 claim。若日志不足以可靠统计，则明确写成代表性案例和限制，不要过度量化。
- 在最终 LaTeX 写作前统一 `TimeMemEval`、`ChainMem`、`\bench` 的命名，并和 Methods 章保持一致。依据：Chalmers/参考 thesis 的 Results 章节通常先建立清晰实验对象和协议，再报告结果；同一 benchmark 的多重命名会削弱可复现性和读者理解。当前计划已提示“若采用 TimeMemEval 命名应全文统一”，后续需要执行。
- 保留本章“Results 报告事实和直接解释，Discussion 展开限制和伦理”的边界。依据：参考 thesis 的共同模式是 Results 章报告实验发现、case 和错误类型，Discussion/Conclusion 再回答研究问题、解释威胁、伦理与未来工作；当前计划符合这一模式，写正文时不要把 4.9 扩展成完整 Discussion。

## Summary
本轮 Results 规划达到 phase 1 要求，可以进入下一节。它把数据集、baseline、指标、主结果、compactness、architecture ablation、reward ablation、case study 和 error analysis 组织成完整实验叙事，并且大部分数字能在 NeurIPS 表格和 appendix 中找到依据。最重要的后续注意点是：第二阶段写正文时必须保持指标定义公平，尤其不要把 direct-answerer 的输出长度与 evidence-provider 的 evidence 长度混同。
