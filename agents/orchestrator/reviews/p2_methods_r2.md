# Review p2 / methods / round 2
verdict: needs_revision
artifacts: paper/include/Methods.tex
writer_round_id: 17

## Blocking issues
1. LOCATION: `Reward Design`, lines 411-458; `Implementation Boundary`, lines 591-595; `tab:methods-implementation`, line 614
   PROBLEM: Reward 部分仍把“checked/active reward implementation”写成可用的 format + faithfulness + outcome + length 四项，但这个技术声明还不能成立。当前 `training/grpo/trainer/schemas.py` 中的 `SynthesizerEvent` 只有 `session_id`, `session_time`, `event_time`, `text` 字段；同时 `training/grpo/trainer/rewards.py` 的 `compute_faithfulness` 仍执行 `direct_events = [event for event in parsed.events if not event.inferred]`。也就是说，一旦 parser 成功解析出非空 events，faithfulness reward path 会访问不存在的 `event.inferred` 字段，而不是按正文所说“当前 parser 不暴露 inferred 字段，因此每个 event 都按 source-grounded claim 检查”。
   WHY: Methods 章不能把一个尚未同步、可能在正常 trajectory 上报错的 reward path 当作 final method。GRPO reward 是本章的核心方法定义之一；如果 faithfulness component 的 schema contract 与 parser 不一致，后续 Results 中关于训练、reward 权重、evidence faithfulness 或 compactness/outcome trade-off 的解释都没有可靠基础。正文 line 593-595 只说“reported training run must keep the faithfulness reward path synchronized”，但 line 411-458 又把它写成已经 checked 的 active implementation，这会让读者误以为实现已经可追踪且可复现。
   BASIS: spec 对 Methods 的通过标准要求“correct application; not just what but why this”，并要求每个技术 claim 可追踪到代码、实验或明确标注的 reasoning；Chalmers 规则也要求方法、结果、讨论逻辑相连，不能陈述未验证或与实现冲突的技术细节。上一轮 review 的第二个 blocking issue 已明确指出 reward/parser/schema 必须先统一，不能在 Methods 正文中保留互相冲突的 reward 版本。
   FIX: 先把 final reward/schema 事实固定为一个一致版本，再改正文。若最终方法确实保留 faithfulness reward 且当前 parser 没有 `inferred` 字段，则需要在实现或实验记录中确认 faithfulness 对所有 parsed events 检查 source support，并在 Methods 中明确这是最终可运行路径；同时删除或改写 line 593-595 中“must keep synchronized”的条件式警告，使其成为已完成的实现映射。若 final reported run 尚未修复该 path，则 Methods 不能称其为 “checked active implementation”；应把 reward 叙述降级为 planned/partially implemented component，并明确 Results 不能把 GRPO training claims 建立在该 faithfulness reward 上。

## Suggestions
- `Reward Design` 可以补一句说明 `length` reward 是负项还是正向 compactness score；当前公式使用 `+ w_l R_len`，而代码里 `compute_length_reward` 返回负的 token ratio。这个不是 blocker，但写清楚符号约定能避免读者误读。
- `Temporal Normalization and Hints` 现在承认 `hard_mention` 的 recall 风险，这是正确方向。后续 Results 章应至少报告或讨论该风险如何影响 retrieval failures，否则 Methods 与 Results 的接口会偏弱。

## Summary
本轮 Methods 在结构、学术语气、retrieval 配置和 binary schema 解释上比 round 1 明显更一致，且大多数图表规划符合 Phase-1 Methods 方案。仍不能 pass 的原因集中在 reward traceability：正文把 faithfulness reward 写成 active final method，但当前 parser/schema 与 reward code 仍不一致。优先修复或重新界定 reward path；修好后本章主要剩余问题会变成非阻塞的符号说明和 Results 接口细化。
