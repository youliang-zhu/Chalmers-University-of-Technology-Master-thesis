# 第四章 Experiment and Analysis 规划稿

本文档是第四章 `Experiment and Analysis` 的中文规划稿，不是最终 LaTeX 正文。本章将原来的 Results 和部分 Discussion 功能合并：先完整说明实验设置，再报告三个 benchmark 的结果，随后进行横向对比分析、架构消融和奖励消融，最后用简短小结回答本章实验证据支持了什么。第五章只保留更高层的 conclusion、limitations、ethics/societal aspects 和 future work。

本章写作必须以 NanoMem NeurIPS 最终版实验章节为标准。可以在硕士论文中扩写实验背景、配置和结果解释，但不能改变原文的实验边界、指标定义、baseline 类型、结果数字和主要结论。尤其注意：

- Benchmark 名称统一为 `TimeMemEval`，不要再使用旧内部名称。
- NanoMem-GRPO 的核心主结果为：LoCoMo 88.6%，LongMemEval 83.8%，TimeMemEval 51.5%。
- NanoMem-Vanilla 对应结果为：LoCoMo 85.0%，LongMemEval 78.7%，TimeMemEval 43.0%。
- LoCoMo 与 LongMemEval 是公开长期对话记忆 benchmark；TimeMemEval 是本文构造的 temporal-bridge diagnostic benchmark。
- Accuracy 由固定 GPT-5.1 judge 自动评估；对于 evidence-provider 方法，NanoMem 输出的是 compact evidence，由固定 Qwen3.5-9B downstream answerer 根据 evidence 生成答案。
- Token 列的含义必须谨慎：direct-answerer 行是 answer-output tokens；evidence-provider 行是 retrieved evidence/context tokens。不能把这些 token 数误写成所有方法的完整输入成本。

## 4.1 Experimental Setup

本节负责交代实验怎么做，而不是提前分析结果。它应把 datasets、baselines、metrics、training/evaluation split 和实现边界讲清楚，使读者理解后续表格的可比性。

### 4.1.1 Benchmarks

正文应介绍三个 benchmark 的角色：

**LoCoMo.** LoCoMo 提供高质量的长程多 session dialogue histories，问题类型包括 single-hop、multi-hop、temporal reasoning 和 open-domain。它用于检验 NanoMem 是否能在标准长期对话记忆任务上保持通用能力，特别是 cross-session evidence localization、multi-hop reasoning 和 temporal reasoning。

**LongMemEval.** LongMemEval 面向聊天助手长期记忆，覆盖 single-session user/assistant、knowledge update、temporal reasoning 和 multi-session reasoning。它的历史更长、更噪声化，适合检验 compact evidence construction 在长噪声历史中是否比 full-context prompting 更稳定。

**TimeMemEval.** TimeMemEval 是本文构造的 temporal-bridge benchmark。每个样本要求系统先找到 source event，推导目标时间窗口，再检索 destination event 并回答 terminal question。它不是为了覆盖所有时间推理现象，而是专门诊断 evidence addressability gap：原始 query 无法直接命中最终证据，必须通过中间 temporal bridge 才能继续检索。

正文中可以加入一个简洁表格：

**表 4.1：Evaluation benchmarks.**  
列为 benchmark、source、main question types、temporal grounding、hidden dependency、role in this chapter。该表用于说明三个 benchmark 是互补关系，而不是三个重复测试集。

### 4.1.2 Training and Held-out Evaluation Splits

硕士论文可以把 NeurIPS 附录中的 split 信息前移到正文，增强可复现性。正文应说明：

- GRPO training set 共 500 examples。
- 原始 pool：LoCoMo 1,986，LongMemEval 500，TimeMemEval 500。
- 过滤后 pool：LoCoMo 1,536，LongMemEval 469，TimeMemEval 374，总计 2,379。
- 训练集：LoCoMo 401，LongMemEval 0，TimeMemEval 99，总计 500。
- Held-out evaluation：LoCoMo 655，LongMemEval 469，TimeMemEval 275，总计 1,399。
- LoCoMo 按 conversation split 避免同一对话泄漏；LongMemEval 不用于 GRPO training，作为 zero-shot held-out evaluation；TimeMemEval 使用过滤后的 held-out records。

可以放一张表：

**表 4.2：Training and held-out evaluation split.**  
列为 data stage、LoCoMo、LongMemEval、TimeMemEval、total、use。数字严格使用 NeurIPS 附录 `train-valid-data-distribution`。

### 4.1.3 Baselines

Baseline 应按类型介绍，而不是逐个孤立描述：

**Full-context baselines.** GPT-5.1 和 Qwen3.5-9B 直接接收完整 conversation history。它们是 strong long-context references，用来衡量没有显式 memory system 时模型能从完整上下文中恢复多少信息。正文要明确：full-context 是强参考基线，但不是实际部署成本最低的 memory baseline。

**Write-time memory systems.** Mem0 和 A-Mem 在 query 到来前抽取或组织 memory records。它们代表 write-time memory construction 路线，用来比较 query-agnostic memory 写入策略在 temporal 和 multi-hop 场景中的表现。

**Search-time retrieval agents.** MemR\(^3\) 和 Search-R1 代表 query-time retrieval/search 路线。它们能进行检索或搜索式回答，但不输出 NanoMem 这种 structured temporal evidence pool。

**Temporal reasoning baseline.** Memory-T1-Qwen 是 Memory-T1-style baseline。需要按 NeurIPS 附录准确表述：由于官方 trained checkpoint 不可用，实验中报告的是使用 Qwen3.5-9B 的 Memory-T1-style baseline，而不是官方 Memory-T1 checkpoint 性能。

**NanoMem variants.** 报告 NanoMem-Vanilla 和 NanoMem-GRPO。Vanilla 使用同一框架但没有 GRPO-trained Synthesizer；GRPO 使用经过 reward 训练的 Synthesizer。两者对比用于区分 framework 本身与 learned search/evidence policy 的贡献。

可以放一张简化表：

**表 4.3：Baseline groups and evaluation roles.**  
列为 group、methods、when memory is constructed、output mode、main comparison purpose、important caveat。更完整的 model/backbone/answerer 组合可以保留到附录。

### 4.1.4 Metrics and Evaluation Protocol

正文应说明四类指标：

**Accuracy.** 使用固定 GPT-5.1 judge 比较 predicted answer 和 gold answer 的语义等价性。正文应说明不主用 F1/BLEU 的原因：长期记忆答案可能包含同义表达、自然语言时间表达和细粒度改写，表面字符串匹配容易误导。

**Output tokens.** 对 NanoMem、Mem0、A-Mem、MemR\(^3\) 等 evidence/context provider，token 主要表示返回给下游 answerer 的 retrieved evidence/context 长度；对 direct-answerer，token 表示 final answer output 长度。正文必须在表注中提醒两者不可简单等同为总成本。

**Retrieval rounds.** 用于分析 NanoMem 是否通过多轮检索解决 hidden dependency。更少轮数不必然更好；关键是 evidence sufficient 时停止，不足时继续。

**Verdict accuracy.** 用于 reward ablation。它衡量 sufficient/insufficient verdict 与 gold evidence coverage 的一致性。该指标直接对应 NanoMem 的 stop/continue decision。

实验协议还应包括：

- LoCoMo 按传统方式对两个 speaker 分别搜索；LongMemEval 和 TimeMemEval 每个 query 只针对 user 做一次搜索。
- 训练时 actor 每个 prompt 采样 \(K=8\) trajectories，最多 3 retrieval rounds。
- 推理时最多 3 retrieval rounds，每轮 top-7 memories。
- 最终训练使用 4 NVIDIA GH200 96GB GPUs。
- GRPO reward 系数为 \((w_o,w_v,w_l)=(0.50,0.10,0.05)\)，format-failure penalty \(c=-0.20\)。

这些训练细节可以写成一段正文，也可以放入：

**表 4.4：Evaluation and training configuration.**  
列为 item、value、purpose。正文中只保留会影响理解结果的配置，过细优化器参数可放附录。

## 4.2 Benchmark Results

本节是主结果章节，统一报告 LoCoMo、LongMemEval 和 TimeMemEval 三个 benchmark。写作顺序建议为：先给 summary table，再分别解释三个 benchmark。TimeMemEval 不再单独开大节，而是作为三大 benchmark 之一放在同一主结果节中。

### 4.2.1 Overall Results Across Three Benchmarks

先放主结果摘要表，列出 LoCoMo、LongMemEval、TimeMemEval 的关键 category 和 overall accuracy。表格应使用 NeurIPS `main_summary.tex` 的数字，并把 `\bench` 全部替换为 `TimeMemEval`。如果沿用 NeurIPS summary 中 Search-R1 的 TimeMemEval placeholder，需要在正文写作前用 detailed TimeMemEval table 中的 6.5% 统一修正，避免正文出现未填数字。

应强调三点：

第一，NanoMem-GRPO 在三个 benchmark 上取得最高 overall accuracy：LoCoMo 88.6%，LongMemEval 83.8%，TimeMemEval 51.5%。

第二，NanoMem-GRPO 相比 NanoMem-Vanilla 均有提升：LoCoMo 从 85.0% 到 88.6%，LongMemEval 从 78.7% 到 83.8%，TimeMemEval 从 43.0% 到 51.5%。这说明提升不仅来自 framework，也来自 GRPO 学到的 search/evidence construction policy。

第三，最大相对提升出现在 TimeMemEval，因为该任务要求先恢复 temporal bridge 再继续搜索，正对应 NanoMem 的设计目标。

**表 4.5：Main benchmark summary.**  
列为 group、method、LoCoMo multi-hop/temporal/overall、LongMemEval TR/MR/overall、TimeMemEval normal/hard/overall。

### 4.2.2 LoCoMo Results

LoCoMo 段落应围绕 category-level 结果解释：

- NanoMem-GRPO overall 为 88.6%，略高于 GPT-5.1 full-context 的 87.7%。
- Multi-hop 从 NanoMem-Vanilla 的 84.0% 提升到 89.0%。
- Temporal 从 NanoMem-Vanilla 的 76.6% 提升到 87.5%。
- Single-hop 91.4%，说明 temporal/multi-hop 优化没有破坏普通记忆能力。
- Open-domain 为 65.2%，略低于 NanoMem-Vanilla 的 67.4%，正文不应声称每个类别都提升。更准确的说法是：NanoMem-GRPO 的优势集中在 thesis 关注的 multi-hop 与 temporal categories。
- Token 上，NanoMem-GRPO average output tokens 为 107，显著低于 NanoMem-Vanilla 的 264，也低于 Mem0 的 650 和 A-Mem 的 12.3k。

**表 4.6：LoCoMo category-level results.**  
使用 NeurIPS `locomo_main.tex`，保留 single-hop、multi-hop、temporal、open、overall 的 accuracy 和 tokens。

### 4.2.3 LongMemEval Results

LongMemEval 段落应突出长噪声历史下 evidence construction 的价值：

- NanoMem-GRPO overall 为 83.8%，高于 GPT-5.1 full-context 的 63.6%。
- Temporal reasoning 达到 86.4%，高于 Mem0 54.2%、MemR\(^3\) 55.0%、Memory-T1-Qwen 27.1%。
- Multi-session reasoning 为 71.4%，略高于 NanoMem-Vanilla 的 70.7%。
- Single-session categories 上也保持强竞争力：SSU 95.7%，SSA 98.2%。
- Token 上，NanoMem-GRPO average output tokens 为 119，低于 NanoMem-Vanilla 353、Mem0 217、A-Mem 18.1k。

正文要谨慎解释 full-context 的低分：不要说 GPT-5.1 “能力弱”，而是说在长噪声历史中，直接把完整历史交给 answerer 容易被无关上下文稀释；query-time evidence selection/synthesis 能更有效地把相关证据压缩给下游模型。

**表 4.7：LongMemEval category-level results.**  
使用 NeurIPS `longmemeval_main.tex`，保留 SSU、SSA、KU、TR、MR、overall 的 accuracy 和 tokens。

### 4.2.4 TimeMemEval Results

TimeMemEval 段落应作为 hidden-dependency temporal reasoning 的关键证据：

- NanoMem-GRPO overall 为 51.5%，高于 NanoMem-Vanilla 43.0%。
- Normal difficulty 为 57.0%，Hard difficulty 为 47.0%。
- Full-context GPT-5.1 overall 为 16.0%，Qwen3.5-9B 为 20.5%。
- Write-time systems 表现很低：Mem0 1.5%，A-Mem 7.5%。
- Search-time baselines 也显著低于 NanoMem：MemR\(^3\) 12.0%，Search-R1 6.5%，Memory-T1-Qwen 3.5%。
- 绝对 accuracy 仍然不高，这一点应主动说明：TimeMemEval 是困难诊断任务，低绝对分数说明 temporal bridge retrieval 尚未被解决；NanoMem 的贡献是显著提高而非完全解决。

正文应解释 TimeMemEval 的重要性：原始 query 不包含 destination evidence 的直接检索 cue，系统必须先从 source event 推导 temporal window，再用该 window 检索 destination event。NanoMem-GRPO 相比 Vanilla 的提升说明 GRPO 训练改进了 bridge discovery、stop/continue decision 和 evidence synthesis。

**表 4.8：TimeMemEval results by difficulty and terminal type.**  
使用 NeurIPS `chainmem_main.tex` 的数字，但表名和正文统一改为 TimeMemEval。列为 Normal/Hard 下的 entity、condition、time terminal type，以及 overall accuracy/tokens。

## 4.3 Comparative Analysis

本节不新增实验表格，而是横向解释 4.2 的结果。它的任务是把三个 benchmark 的数字连成 thesis argument。

### 4.3.1 Full-context Prompting vs Memory Evidence Construction

应比较 GPT-5.1 full-context 和 NanoMem-GRPO：

- LoCoMo 上 NanoMem-GRPO 88.6% vs GPT-5.1 full-context 87.7%，差距较小但 NanoMem 返回 compact evidence，而不是依赖完整历史。
- LongMemEval 上 NanoMem-GRPO 83.8% vs GPT-5.1 full-context 63.6%，说明长噪声历史下 full-context 不是可靠上限。
- TimeMemEval 上 GPT-5.1 full-context 16.0%，说明即使完整上下文存在，模型仍可能无法完成隐藏 temporal bridge 的定位和推理。

结论应是：full-context prompting 可以作为强 reference，但不能替代 memory evidence construction。长期对话记忆的关键不是“把所有历史放进去”，而是构造紧凑、可追踪、时间上可解释的 evidence state。

### 4.3.2 Write-time Memory vs Query-time Evidence Synthesis

比较 Mem0、A-Mem 与 NanoMem：

- Write-time systems 在 query 到来前组织 memory，可能适合偏好、事实、长期 profile 等稳定信息。
- 但 temporal bridge 问题的关键关系往往只有在 query 给出后才显现，因此 query-time evidence synthesis 更合适。
- Mem0 和 A-Mem 在 TimeMemEval 上分别为 1.5% 和 7.5%，说明单纯 write-time memory records 很难恢复 query-specific hidden dependency。
- A-Mem token 数很大：LoCoMo 12.3k、LongMemEval 18.1k、TimeMemEval 3.8k。正文应把它解释为 practical trade-off，而不是简单贬低：更高召回或 transcript-level evidence 可能带来更高 token cost 和更多噪声。

### 4.3.3 Search-time Retrieval vs Structured Temporal Evidence State

比较 MemR\(^3\)、Search-R1 与 NanoMem：

- Search-time retrieval 能根据 query 进行搜索，比纯 write-time memory 更接近 NanoMem 的方向。
- 但 NanoMem 的差异是维护 Temporal Evidence Pool，并让 Synthesizer 输出 structured events 与 binary verdict。
- MemR\(^3\) 在 LongMemEval TR 上有 55.0%，但 NanoMem-GRPO 达到 86.4%；在 TimeMemEval 上 MemR\(^3\) 为 12.0%，NanoMem-GRPO 为 51.5%。
- Search-R1 是 open-domain search QA checkpoint，本文将其适配到 memory search，但它并非为 timestamped long-term dialogue memory 训练，因此结果应作为 search-style baseline，而不是对 Search-R1 原方法能力的全面否定。

### 4.3.4 Accuracy--Compactness Trade-off

这一小节可以加入全章唯一的核心图：

**图 4.1：Accuracy-token trade-off across benchmarks.**  
横轴 output tokens，纵轴 overall accuracy，按 benchmark 分面或用不同 marker 表示 LoCoMo、LongMemEval、TimeMemEval。重点突出 NanoMem-GRPO 位于高 accuracy、低 token 区域。

正文应说明：

- NanoMem-GRPO 不靠 context bloat 提升准确率。
- GRPO 显著压缩 NanoMem 输出：LoCoMo 264 -> 107，LongMemEval 353 -> 119，TimeMemEval 287 -> 234。
- Compactness 不能被绝对化为越短越好；它的意义是减少下游 answerer 需要处理的噪声，同时保留 source-grounded evidence。

如果最终不画图，也可以用一张小表替代：

**表 4.9：NanoMem-Vanilla vs NanoMem-GRPO accuracy and token comparison.**  
列为 benchmark、Vanilla accuracy/tokens、GRPO accuracy/tokens、accuracy gain、token reduction。

## 4.4 Architecture Ablation

本节直接报告并分析 architecture ablation，不再另开单独结果分析小节。它应验证 NanoMem 的关键结构组件是否必要。

使用 NeurIPS `arch_ablation.tex` 的表：

**表 4.10：Architecture ablation.**  
列为 variant、LoCoMo-MH、LoCoMo-Temp、LME-TR、TimeMemEval、Avg. Rounds。Variant 包括 Full NanoMem-Vanilla、w/o text normalization、w/o temporal evidence pool、single-round retrieval。

正文应按组件解释：

**Text normalization.**  
Text normalization 主要服务 temporal grounding。移除后 LoCoMo-MH 从 84.0 降到 82.3，影响较小；但 LoCoMo-Temp 从 76.6 降到 71.3，LME-TR 从 75.8 降到 64.9，TimeMemEval 从 43.0 降到 33.5。说明当问题依赖相对时间、session time 和 event time 的对齐时，显式 normalization 很关键。

**Temporal Evidence Pool.**  
Temporal Evidence Pool 更广泛地影响多轮搜索。移除后 LoCoMo-MH 降到 77.0，LoCoMo-Temp 降到 67.6，LME-TR 降到 60.6，TimeMemEval 降到 25.0；平均轮数从 1.25 增加到 1.45。解释应与 NeurIPS 一致：没有 temporally resolved events 作为 search state，后续 Planner/Synthesizer 更难利用前一轮发现，容易重复或偏离搜索。

**Single-round retrieval.**  
限制为单轮检索后，LoCoMo-MH 从 84.0 降到 78.0，TimeMemEval 从 43.0 降到 32.0，说明 multi-hop 和 hidden dependency 任务需要继续搜索。但 LoCoMo-Temp 和 LME-TR 分别略升到 78.5 和 78.0，正文必须解释这一非单调现象：许多 temporal questions 在第一轮证据已经足够，额外轮次可能引入噪声。因此 NanoMem 的目标不是盲目增加轮数，而是通过 verdict 判断何时停、何时继续。

本节结论：三个组件不是在所有任务上都单调提升，而是分别服务不同失败模式：normalization 处理时间表达，evidence pool 维护跨轮状态，multi-round retrieval 解决第一轮 evidence 不足的问题。

## 4.5 Reward Ablation

本节直接报告并分析 reward ablation，不再另开单独结果分析小节。它应验证 GRPO reward 是否真的改变 Synthesizer 的 evidence construction 行为。

使用 NeurIPS `reward_ablation.tex` 的表：

**表 4.11：Reward ablation.**  
列为 variant、LoCoMo-MH、LoCoMo-Temp、LME-TR、TimeMemEval、Verdict Acc.、Avg. Rounds、Avg. Tok.。Variant 包括 Full reward、remove \(R_{fmt}\) and \(R_{len}\)、remove \(R_{verdict}\)。

正文应按 reward component 解释：

**Full reward.**  
Full reward 在 LoCoMo-MH、LoCoMo-Temp、LME-TR 和 TimeMemEval 上分别达到 89.0、87.5、86.4 和 51.5；verdict accuracy 为 84.0，平均轮数 1.1，平均 tokens 110。这是最终 NanoMem-GRPO 设置。

**Removing format and length rewards.**  
移除 \(R_{fmt}\) 和 \(R_{len}\) 后，accuracy 有中等但一致下降：LoCoMo-MH 87.6，LoCoMo-Temp 85.4，LME-TR 84.1，TimeMemEval 48.0。同时平均 tokens 从 110 增加到 359，约 3.3 倍。正文应说明：format/length reward 不只是格式约束，它们防止 Synthesizer 把大量冗余 evidence 交给下游 answerer，从而正则化 evidence compactness。

**Removing verdict reward.**  
移除 \(R_{verdict}\) 后出现不同失败模式：LoCoMo-Temp 和 LME-TR 分别升到 89.1 和 90.2，但 LoCoMo-MH 从 89.0 降到 80.5，TimeMemEval 从 51.5 降到 41.5；verdict accuracy 从 84.0 降到 72.9，平均轮数从 1.1 增加到 1.25，平均 tokens 增加到 361。正文应严格按照 NeurIPS 解释：outcome-only training 在第一轮证据通常足够的任务上可能表现不错，但在 LoCoMo-MH 和 TimeMemEval 这类需要判断 evidence incomplete 并继续搜索的任务上缺少直接监督，因此容易过早停止、错误继续或产生冗余 evidence。

本节结论：GRPO 的作用不是简单提高 final answer accuracy，而是训练 Synthesizer 学会 evidence sufficiency judgment、compact evidence synthesis 和 stop/continue behavior。

## 4.6 Summary of Findings

本节只做简短总结，避免展开成完整 Discussion。建议用 4 个段落收束：

第一，主 benchmark 结果表明 NanoMem-GRPO 在 LoCoMo、LongMemEval 和 TimeMemEval 上达到最高 overall accuracy，并且在 multi-hop、temporal reasoning 和 hidden-dependency temporal bridge 场景中优势最明显。

第二，横向对比说明 full-context prompting、write-time memory 和 search-time retrieval 都不能完全解决 temporal evidence addressability gap。NanoMem 的优势来自 query-time evidence synthesis、Temporal Evidence Pool 和 structured verdict loop。

第三，compactness 分析说明 NanoMem-GRPO 的提升不是靠传入更多上下文，而是通过 GRPO 训练输出更短、更结构化的 evidence。LoCoMo 和 LongMemEval 上平均 tokens 分别为 107 和 119，明显低于大量 memory baseline。

第四，消融实验说明每个核心设计都有作用但作用范围不同：text normalization 支持 temporal grounding，Temporal Evidence Pool 支持跨轮状态传递，multi-round retrieval 支持 hidden dependency search，reward components 分别约束格式/紧凑性和 sufficiency judgment。

最后一句可以过渡到第五章：

第五章将基于这些实验证据回答研究问题，并讨论当前评估仍然受到的限制，包括自动 judge、baseline 适配边界、token 指标不可完全等价、TimeMemEval 的诊断性范围，以及长期个人记忆系统在隐私、成本和可审计性方面的部署问题。

## 本章建议图表清单

最终正文不应保留旧稿中 14 张表、7 张图的规模。建议正文保留以下核心图表，其余细节放附录：

| 编号 | 类型 | 内容 | 位置 |
|---|---|---|---|
| 表 4.1 | 数据集表 | LoCoMo、LongMemEval、TimeMemEval 的任务覆盖和用途 | 4.1 |
| 表 4.2 | split 表 | 原始、过滤、训练、held-out evaluation 数量 | 4.1 |
| 表 4.3 | baseline 表 | baseline groups、output mode、comparison purpose | 4.1 |
| 表 4.4 | 配置表 | judge、answerer、rounds、top-k、training hardware、reward weights | 4.1 |
| 表 4.5 | 主结果摘要 | 三个 benchmark 的关键 accuracy | 4.2 |
| 表 4.6 | 结果表 | LoCoMo category-level accuracy/tokens | 4.2 |
| 表 4.7 | 结果表 | LongMemEval category-level accuracy/tokens | 4.2 |
| 表 4.8 | 结果表 | TimeMemEval difficulty/terminal-type results | 4.2 |
| 图 4.1 | 可选图 | Accuracy-token trade-off | 4.3 |
| 表 4.9 | 可选表 | Vanilla vs GRPO accuracy/token comparison | 4.3 |
| 表 4.10 | 消融表 | Architecture ablation | 4.4 |
| 表 4.11 | 消融表 | Reward ablation | 4.5 |

如果篇幅紧张，优先保留表 4.5--4.8、表 4.10、表 4.11；表 4.1--4.4 可以压缩或迁入附录。图 4.1 只在能清楚呈现 accuracy--compactness trade-off 时加入。
