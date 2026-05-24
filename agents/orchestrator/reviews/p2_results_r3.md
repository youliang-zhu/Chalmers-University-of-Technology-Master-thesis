# Review p2 / results / round 3
verdict: needs_revision
artifacts: paper/include/Results.tex
writer_round_id: 22

## Blocking issues
1. LOCATION: `Evaluation Protocol` 第 52--55 行，以及所有依赖该设定解释 benchmark accuracy 的段落和表注
   PROBLEM: Results 章把共同 evaluation boundary 写成 “downstream Qwen3.5-9B answerer then GPT-5.1 judge”，但可核对的同步结果 artifact 显示 NanoMem 的最终回答生成使用的是 GPT-5.1，而不是 Qwen3.5-9B。LoCoMo 运行记录在 `/mnt/models/yupan/llm/nanomem/task.md` 第 5 步明确写 `--answer-model gpt-5.1`，实际运行目录也包含 `answer_gpt51.json` 和 `openai_usage_answer_eval.jsonl`，其中 `model` 为 `gpt-5.1`。LongMemEval 和 ChainMem 的 NanoMem 运行同样存在 `answer_gpt51.json`；ChainMem 的 inspected trace 目录 `/mnt/models/yupan/llm/nanomem/tmp/search/chainmem2/nanomem/task8_chainmem2_combo2_gpt54pre_qwencomp_20260428_100723/` 也用 GPT-5.1 生成 answer 并再用 GPT-5.1 eval。
   WHY: 这是 Results 章的核心实验边界，不是措辞细节。若读者以为 NanoMem 的 evidence 是交给 Qwen3.5-9B answerer，会错误理解 accuracy 数值、full-context baseline 的可比性、以及 “memory module vs downstream answer model” 的责任划分。尤其当前章节多次把性能提升解释为 evidence selection 的收益；该解释必须建立在真实 answer/eval pipeline 上。
   BASIS: spec 第 1 条 traceability/honesty 要求所有技术声明和实验数字必须能追溯到真实 artifact，不能混用或误报实验设置；spec 第 2.E 要求 Results 对技术方案进行 critical evaluation，evaluation boundary 是判断 retrieval、synthesis、answerer 三类错误来源的前提；Chalmers 规则要求结论由可审查证据支撑。project goal 也要求始终区分 memory evidence、retrieved sessions、synthesized evidence 和 downstream answer model。
   FIX: 重新核对所有主结果、compactness、case study 和 error analysis 所用运行的 answer model / judge model。若同步结果确实都使用 GPT-5.1 answer + GPT-5.1 judge，则把第 52--55 行及相关表注改为这个设置，并说明 Qwen3.5-9B 在 NanoMem 运行中承担 Planner/Synthesizer 或 compressor 角色，而不是 final answerer。若存在某些表格使用 Qwen3.5-9B answerer，则按 benchmark/row 明确拆分设置，不能写成一个统一的 Qwen answer boundary。同步检查 “full-context reference”“frozen answer model”“answerer error” 等解释，保证它们与真实 pipeline 一致。

## Suggestions
- 主结果表已经开始用表注说明 A-Mem、MemR$^3$ audit cell 和 Search-R1 的可比性限制；修正 answer boundary 时，建议把这些说明集中成一个短段落或表注，明确哪些 cell 来自 full rerun、sample audit、公共 checkpoint 或被排除。依据：Results 章可以比较不完全同质的 baselines，但必须让读者知道比较边界。
- `Reward Diagnostics` 现在把 reward ablation 标成 unresolved diagnostic boundary，这是合理的；保留该谨慎措辞，直到 Methods 中的 reward implementation 与 reported objective 完全对齐。

## Summary
本轮已经修复了上一轮最严重的 architecture ablation 数字和 ChainMem case-study 错配，章节结构和案例解释明显更可靠。但还有一个阻断问题：Results 章误报了 NanoMem 结果的 downstream answer model，这会影响整章实验设置和结论解释。优先把 evaluation boundary 与实际 `answer_gpt51.json` / usage artifact 对齐，再让所有表注和错误归因跟随这个真实边界。
