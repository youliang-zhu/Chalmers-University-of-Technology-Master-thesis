# Review p2 / results / round 2
verdict: needs_revision
artifacts: paper/include/Results.tex
writer_round_id: 21

## Blocking issues
1. LOCATION: `Architecture Ablation`，表 `tab:results-architecture-ablation` 第 329--347 行及解释第 349--359 行
   PROBLEM: architecture ablation 的若干数值与可核对的 NanoMem 结果表不一致。当前稿件写 `w/o Temporal Evidence Pool` 为 80.5 / 68.8 / 60.6 / 25.0，`single-round retrieval` 为 78.0 / 79.2 / 69.7 / 32.0；但我核对到的可用结果表 `/mnt/models/yupan/llm/nanomem/paper/tbl/arch_ablation.tex` 对应为 77.0 / 67.6 / 60.6 / 25.0，single-round 为 78.0 / 78.5 / 78.0 / 32.0。当前解释也据此写了 “LongMemEval-TR from 75.8% to 69.7%”，这会改变 single-round 对 LME-TR 的结论。
   WHY: Results 章的实验数字必须能追溯到真实实验 artifact。这里不是四舍五入差异，而是足以改变消融解释的数值不一致；如果留下，读者会得到错误的组件贡献判断，尤其是 multi-round retrieval 是否伤害或帮助 LME-TR。
   BASIS: spec 第 1 条 traceability/honesty 要求所有 experiment numbers 可追溯，且禁止编造或混用结果；spec 第 2.E 要求 Results 对技术方案进行 critical evaluation，ablation 是判断组件必要性的核心证据。Chalmers rules 也要求结论由实验或其他可审查证据支撑。
   FIX: 重新核对 architecture ablation 的唯一权威来源。如果使用 `/mnt/models/yupan/llm/nanomem/paper/tbl/arch_ablation.tex`，把表和解释统一到其中的数值；如果你有更新的同步实验 artifact，则在正文或表注中标明该 artifact/运行名，并保证表格、段落解释和 Summary 使用同一套数字。特别检查 single-round retrieval 对 LME-TR 的方向性结论，不要把 reward ablation 的 80.5 等数字误混进 architecture ablation。

2. LOCATION: `Qualitative Case Studies` 第 444--480 行，尤其是 Noor 和 Hiroshi 两个 ChainMem case
   PROBLEM: case-study 描述与可核对 trace 不匹配。Noor case 被写成成功的 two-event temporal bridge，第二个事件回答 “beans used for a chocolatey drip coffee”；但 trace `/mnt/models/yupan/llm/nanomem/tmp/search/chainmem2/nanomem/task8_chainmem2_combo2_gpt54pre_qwencomp_20260428_100723/eval_gpt51.json` 中该问题的 gold answer 是 “the beans they used for a chocolatey drip coffee”，而 NanoMem response 是 “Her regular order at Third Street Roasters”，evidence 也只有一个 event，内容是 “regular order at Third Street Roasters”。这更像没有恢复 answer-bearing evidence 的失败/不充分案例，而不是成功案例。Hiroshi case 中正文说第二个 event 被标记为 inferred，但同一 trace 的对应 event 标记是 `inferred="false"`。
   WHY: NanoMem 的 Results 章必须用真实 trace 展示 iterative evidence synthesis、verdict 和 failure boundary。当前 case-study 把失败或不完整 evidence 写成成功，并错误描述 inferred 标记，会直接破坏结果诚实性，也会误导读者对 evidence addressability gap 的理解。
   BASIS: phase-1 Results 规划 4.8 明确要求 case study 必须来自真实 evaluation trace，包含 query、retrieved sessions、Synthesizer events、verdict、final answer、gold answer 和 diagnosis，不能凭计划构造。spec 第 1 条将不可追溯或不真实的实验案例视为 blocking；spec 第 2.E 要求 failure cases 和 error analysis 必须支撑 critical evaluation。
   FIX: 把 Noor case 改判为 failure/partial-failure，或换成一个真正 successful 的 ChainMem trace。无论保留哪个 case，都要在表或正文中列出 trace 文件路径、user/case id、gold answer、model response、event session_id、event_time、verdict 和 `inferred` 标记，并逐项与 artifact 一致。Hiroshi case 若保留，不要说 event 是 inferred，除非换用的 trace 实际标记为 `inferred="true"`。

3. LOCATION: `Error Analysis` 第 495--536 行
   PROBLEM: error analysis 现在声称基于 “trace families used above”，但它没有吸收 Noor case 实际暴露的错误：evidence 与 gold answer 不一致、verdict 仍为 sufficient、response 回答了 regular order 而不是 beans。相反，正文把这个 case 放在成功段落，使错误分类与前文证据相冲突。
   WHY: Results 章可以做 representative manual audit，但必须准确连接到所展示的案例。若最关键的 ChainMem case 实际是 premature sufficiency 或 answer-bearing evidence miss，却被成功段落掩盖，error analysis 就无法支持 NanoMem 的 failure boundary，也无法为 Discussion 提供可靠基础。
   BASIS: spec 第 2.E 要求 error analysis 和 failure cases；第 2.G 要求 figures/tables 直接支持正文。Chalmers assessment 强调 conclusions must be well substantiated；一个代表性 audit 也必须把观察信号、错误类型和影响指标对应起来。
   FIX: 在修正 case-study 后同步修正 error taxonomy。至少为 Noor 这类情况增加或明确归入一个错误类型，例如 “answer-bearing evidence missing despite sufficient verdict”，并说明可观察信号是 gold answer 与 evidence/response 不一致。若 Noor 被替换为成功 case，则另选一个真实失败 trace 支撑 premature sufficiency、retrieval miss 或 answerer error，不能只保留抽象 taxonomy。

## Suggestions
- `Reward Diagnostics` 第 388--402 行仍使用 “planned reward diagnostic values” 和 “should be finalized” 这类措辞。若这些数字就是当前同步实验结果，应改成“diagnostic”而不是“planned”；若还未最终同步，应把这部分明确标成 unresolved boundary，避免读者误读为最终因果结论。basis：Results 正文应报告已核对结果，未核对内容只能作为清楚标记的限制。
- 主结果表现在补回了更多 baselines，这是上一轮的实质改进。建议给 LongMemEval MemR$^3$ / audit cell、A-Mem 缺失 cell、Search-R1 排除或保留的规则加一条简短表注，避免读者把不同样本规模的 cell 当成完全同质比较。

## Summary
本轮稿件已经补齐了大量上一轮缺失的 baseline 和 ablation 内容，章节结构也基本符合 Results 章要求。但仍有阻断问题：architecture ablation 数字与可核对结果不一致，qualitative case-study 把实际 trace 描述错了，并且 error analysis 没有处理这个错配。优先修正所有可追溯性问题；Results 章宁可少放一个 case，也不能把 case 的 gold answer、response、event 或 verdict 写错。
