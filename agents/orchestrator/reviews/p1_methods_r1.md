# Review p1 / methods / round 1
verdict: pass
artifacts: paper/sections_drafts/03_methods.md
writer_round_id: 5

## Suggestions
- 进入第二阶段正文写作时，请优先统一 3.6/3.7 中关于 terminal evidence 的表述：NeurIPS 方法稿把最终 Temporal Evidence Pool 交给 answer model，而训练 notes 中又出现“只用最后一轮 events”或特定终止条件处理的演化痕迹。依据：spec 要求 Methods 的技术主张必须可追踪且不能把互相冲突的实现版本同时写成最终系统；Chalmers 方法章也要求方法选择和执行过程清楚、可复现。当前规划已经用 TODO 标出 reward/code 核对，这是正确的，后续 LaTeX 必须落实为单一版本。
- 3.8 建议在正式正文中固定 benchmark 命名层级：若最终论文宏 `\bench` 指 TimeMemEval，而数据构造历史中使用 ChainMem，请明确说明二者关系，例如“TimeMemEval is the final benchmark name; ChainMem denotes the earlier construction/design stream”或反之。依据：spec 的 traceability 要求读者能把 thesis claim 对应到代码、数据和论文源；名称混用会削弱 Methods 与 Results 的可核验性。
- 3.2、3.5、3.9 的实现细节可以继续保留“待核对事项”，但正文阶段不要把 dense/BM25 权重、top-k、reranker、model version、group size、max rounds 等数字写成确定事实，除非已经从最终 config 或脚本核实。依据：Chalmers 规则要求报告公开、可检查，spec 明确禁止编造或未核实的实验/实现细节。
- 本章计划 8 张图、6 张表是合理的技术核心章节配置，但后续写作时应合并功能重叠的训练图和 reward 图，避免把 Methods 变成图表目录。依据：spec 的图表标准是“真正帮助理解”，参考论文的 Method/Methodology 章通常用系统框架图、流程图、实验设计表来支撑叙述，而不是让图表替代方法论证。

## Summary
该规划稿达到 Phase 1 对 Methods 的要求，可以通过。它完整覆盖了问题形式化、Temporal Evidence Pool、时间归一化、Planner-Retriever-Synthesizer loop、GRPO 训练、reward、benchmark 构造和实现边界，且明显比 NeurIPS 方法段落更适合硕士论文。最重要的后续工作是在第二阶段把仍在演化的字段、reward 逻辑和 benchmark 命名核对为唯一、可追踪的最终版本。
