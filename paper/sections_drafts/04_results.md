# 第四章 Results 规划稿

本文档是第四章 Results 的中文规划稿，不是最终 LaTeX 正文。本章的任务是把 NanoMem 的 NeurIPS 实验部分扩展成硕士论文中完整、可复现、可解释的实验与结果章节：先交代实验问题、数据集、baseline、指标和评估协议，再报告主结果、效率与紧凑性、消融实验、case study 和错误分析。最终正文不应只是把几张 NeurIPS 表格搬进 thesis，而要解释每个实验回答什么问题、为什么这个比较公平、结果说明了 NanoMem 的哪些设计有效，以及哪些现象还需要在 Discussion 中进一步解释。

本章应直接回答第一章提出的 RQ3，并回扣第二章与第三章的论证：如果 memory module 的目标是提供 compact、source-grounded、temporally grounded evidence，那么评估就不能只看 final answer accuracy，还要同时看 evidence 长度、是否需要多轮检索、verdict 是否正确、以及在 temporal bridge 或 hidden dependency 场景下是否真的恢复了间接 evidence。写作时要保持系统边界清楚：NanoMem 输出 evidence events 和 verdict，下游 Qwen3.5-9B answerer 负责根据 evidence 生成 final answer，GPT-5.1 judge 用于自动评估。

## 4.1 实验目标与章节结构

本小节负责把 Methods 的设计目标转成实验问题。正文开头应说明第四章围绕四类问题组织：

第一，NanoMem-GRPO 在标准 long-term memory benchmark 上是否达到或超过 full-context、write-time memory 和 search-time retrieval baseline，同时保持 compact evidence 输出。

第二，NanoMem 在 temporal reasoning、multi-session reasoning 和 TimeMemEval/ChainMem 这类 hidden-dependency temporal bridge 场景中是否有更明显优势。

第三，主要设计组件是否必要，包括 text normalization、Temporal Evidence Pool、multi-round retrieval、以及 GRPO 后的 Synthesizer policy。

第四，reward 设计是否真的改变了 evidence construction 行为，尤其是 verdict accuracy、平均轮数和 token compactness。

本小节还应提醒读者：Results 章节报告事实和直接解释，Discussion 章节再讨论局限、威胁、伦理和未来部署。因此本章可以指出某些失败模式，但不要把所有限制展开成最终讨论。

**计划图 4.1：Results 章节实验地图。** 放在 4.1 末尾。图中从研究问题出发，分成主结果、效率与 compactness、architecture ablation、reward ablation、case study/error analysis 五条路径，并标出对应数据集与指标。该图的作用是让读者在进入表格前知道每组实验服务于哪个 claim。若最终全文图数过多，可把该图降级为段落或表格。

## 4.2 数据集与评估任务

本小节介绍本章使用的数据集，但不重复 Methods 中 TimeMemEval/ChainMem 的构造细节。正文应把三个主要 benchmark 的角色区分清楚：

LoCoMo 提供长程多 session dialogue memory 问题，包含 single-hop、multi-hop、temporal 和 open-domain 类别。它用于检验 NanoMem 在标准长期对话记忆任务上是否保持通用能力，尤其是 multi-hop 与 temporal 子类是否受益于 iterative evidence search。

LongMemEval 面向聊天助手长期记忆，覆盖 SSU、SSA、knowledge update、temporal reasoning 和 multi-session reasoning。它的历史更长、更噪声化，适合检验 compact evidence provider 是否能在不传入大量原始上下文的情况下提升长期记忆回答质量。

TimeMemEval/ChainMem 是诊断性 temporal-bridge benchmark。它要求系统先找到 source event，推导 target temporal window，再检索 destination event。它不替代 LoCoMo 和 LongMemEval，而是专门检验 evidence addressability gap 中“下一步 retrieval cue 原始 query 中不存在”的情况。

正文还应交代训练与 held-out split 的原则：GRPO 训练使用 500 examples，其中 LoCoMo 按 conversation split 避免泄漏，LongMemEval 不用于 GRPO training，TimeMemEval/ChainMem 保留 filtered held-out evaluation。具体数字可在正文中给简短表述，详细数据构造放入附录或 Methods 的可复现部分。

**计划表 4.1：评估数据集与任务覆盖。** 放在 4.2 末尾。列为 benchmark、样本来源、主要问题类型、是否多 session、是否强调 temporal grounding、是否强调 hidden dependency、在本章中的用途。该表应与第二章的 benchmark 覆盖矩阵呼应，但这里更偏实验协议和样本用途。

**计划表 4.2：训练与 held-out evaluation split。** 放在 4.2 末尾或附录中。列为数据来源、原始问题数、过滤后问题数、训练数、held-out evaluation 数、泄漏控制方式。正文可使用来源中的数字：LoCoMo 原始 1,986、过滤 1,536、训练 401、held-out 655；LongMemEval 原始 500、过滤 469、训练 0、held-out 469；TimeMemEval/ChainMem 原始 500、过滤 374、训练 99、held-out 275。若第二阶段核对发现命名从 ChainMem 改为 TimeMemEval，应全文统一。

## 4.3 Baselines、模型配置与指标

本小节建立比较的公平性。正文应把 baseline 分成四组，而不是逐个孤立介绍：

第一组是 full-context baselines，包括 GPT-5.1 和 Qwen3.5-9B。它们把完整历史直接交给 answer model，代表“没有显式 memory system 时长上下文模型能做到什么”。GPT-5.1 full-context 应被表述为强 long-context reference，不是实际部署成本最低的 memory baseline。

第二组是 write-time memory systems，包括 Mem0 和 A-Mem。它们在 query 到来前抽取或组织 memory records，用于检验 query-agnostic memory construction 在 temporal 与 hidden-dependency 问题上的表现。

第三组是 search-time retrieval agents，包括 MemR3 和 Search-R1。它们能做 query-time search 或 reflective retrieval，但输出通常不是 NanoMem 这种 structured temporal evidence pool。

第四组是 temporal reasoning baseline，包括 Memory-T1-Qwen。它与 NanoMem 都关心 temporal memory，但主要比较点应是 session selection / temporal filtering 与 event-level evidence synthesis 的差异。

NanoMem 自身需要报告两个版本：NanoMem-Vanilla 使用同一框架但未经过 GRPO 训练的 Synthesizer；NanoMem-GRPO 使用训练后的 Synthesizer。这个对比用于区分 framework 贡献与 learned policy 贡献。

指标方面，正文应至少报告：

一是 answer accuracy，由固定 GPT-5.1 judge 对 predicted answer 与 gold answer 做语义等价判断。正文应说明不主用 BLEU/F1 的原因：长期记忆答案往往有同义表达、时间表达和自然语言变体，表面匹配可能误导。

二是 output tokens 或 evidence tokens。对 evidence-provider 方法，它表示传给下游 answerer 的 evidence 长度；对 direct-answerer 或 full-context 方法，要清楚标注它的 token 含义，避免把 final answer 长度与 evidence 长度混淆。

三是 retrieval rounds 和 verdict accuracy，用于解释 iterative loop 和 sufficiency supervision。它们主要出现在消融或 reward 分析中，不一定放入所有主结果表。

四是分任务 accuracy，例如 LoCoMo multi-hop/temporal、LongMemEval TR/MR、TimeMemEval/ChainMem normal/hard 与 terminal type。分任务结果比 overall 更能支持 thesis claim。

**计划表 4.3：baseline 与模型配置。** 放在 4.3 末尾或附录。列为方法、类别、backbone、是否直接回答、是否使用固定 downstream answerer、是否输出 structured evidence、备注。该表对应 NeurIPS appendix 中 model-combo 信息，硕士论文正文可放简化版，完整版入附录。

**计划表 4.4：评估指标定义。** 放在 4.3 末尾。列为指标、计算对象、适用方法、解释注意事项。特别要说明 accuracy、output tokens、average rounds、verdict accuracy 的含义。

## 4.4 主结果：标准长期记忆与 temporal-bridge benchmark

本小节是 Results 的核心，应按 benchmark 报告主结果，并在每个 benchmark 后给出解释，而不是先放三张大表再统一评论。

LoCoMo 主结果应强调三个现象。第一，NanoMem-GRPO overall 达到 88.6%，略高于 GPT-5.1 full-context 的 87.7%，并高于 NanoMem-Vanilla 的 85.0%。第二，优势集中在 multi-hop 与 temporal 类别：multi-hop 达到 89.0%，temporal 达到 87.5%，说明 iterative evidence search 与 temporal grounding 对目标问题有效。第三，NanoMem-GRPO 的 evidence 输出平均约 107 tokens，明显短于 write-time memory baseline 的输出，说明准确率提升不是靠把大量 context 传给下游模型。

LongMemEval 主结果应强调更长、更噪声历史下的差异。NanoMem-GRPO overall 为 83.8%，比 GPT-5.1 full-context 的 63.6% 高 20.2 points；在 temporal reasoning 上达到 86.4%，高于 Mem0、MemR3 和 Memory-T1-Qwen。正文需要谨慎解释：这不是说 full-context 模型能力弱，而是说明在长噪声历史中，结构化 evidence selection/synthesis 可以比直接让 answerer 读完整历史更有效。

TimeMemEval/ChainMem 主结果应作为 hidden-dependency claim 的关键证据。NanoMem-GRPO overall 为 51.5%，高于 NanoMem-Vanilla 的 43.0%，也明显高于 full-context 与现有 memory baselines。正文应强调该 benchmark 的绝对准确率仍不高，这反而说明任务困难；NanoMem 的提升来自发现 bridge cue 后继续检索，而不是普通 one-shot matching。Normal 和 Hard、entity/condition/time terminal type 的分层结果可用于说明优势是否稳定。

**计划表 4.5：主结果摘要表。** 放在 4.4 开头或结尾。使用 summary table 汇总 LoCoMo multi-hop/temporal/overall、LongMemEval TR/MR/overall、TimeMemEval/ChainMem normal/hard/overall。该表用于快速支持 thesis 主 claim。

**计划表 4.6：LoCoMo category-level results。** 放在 LoCoMo 段落后。列出 single-hop、multi-hop、temporal、open、overall 的 accuracy 与 tokens。可从 NeurIPS `locomo_main` 表扩展排版。

**计划表 4.7：LongMemEval category-level results。** 放在 LongMemEval 段落后。列出 SSU、SSA、KU、TR、MR、overall 的 accuracy 与 tokens。正文解释重点放在 TR、MR 和 overall，不必逐列复述。

**计划表 4.8：TimeMemEval/ChainMem results by difficulty and terminal type。** 放在 TimeMemEval/ChainMem 段落后。保留 Normal/Hard 与 En/Cond/Time 分类。若最终 thesis 版采用 TimeMemEval 命名，应表题统一为 TimeMemEval；若保留 ChainMem 作为别名，第一次出现时解释二者关系。

**计划图 4.2：跨 benchmark accuracy 与 compactness 对照。** 放在 4.4 末尾。可用 grouped bar 或 scatter：横轴为方法，左侧显示 overall accuracy，右侧或点大小显示 evidence/output tokens。图的作用是把“准确率”和“紧凑性”同时可视化，避免读者只看 accuracy。若图数需要压缩，可只画 NanoMem-GRPO、NanoMem-Vanilla、GPT-5.1 full-context、Mem0、A-Mem、MemR3。

## 4.5 Compactness 与 practical efficiency 分析

本小节专门解释 token efficiency 和 practical significance。会议论文中 token 数多作为表格列出现；硕士论文应把它变成独立分析，因为 memory evidence provider 的目标之一就是减少下游模型负担。

正文应说明不同方法的 output token 含义：NanoMem 输出的是 structured evidence events；Mem0/A-Mem 输出 memory records 或 retrieved memory context；full-context 行的 token 数可能是 final answer 或报告输出，不应被误解为 full input context 成本。因此本小节应谨慎使用“output compactness”而不是笼统说“总成本”。若要讨论输入成本或 latency，需要第二阶段从日志或代码核对，不能凭表格推断。

分析重点包括：

第一，NanoMem-GRPO 相比 NanoMem-Vanilla 显著缩短 evidence：LoCoMo 从约 264 tokens 降到 107，LongMemEval 从约 353 降到 119，TimeMemEval/ChainMem 从约 287 降到 234，同时 accuracy 提升。这说明 GRPO 不只是提高 final answer，还改善 evidence compression 行为。

第二，write-time memory baseline 可能输出大量上下文，例如 A-Mem 在 LoCoMo/LongMemEval 中达到数千到上万 tokens。正文应把这解释为 practical memory-use tradeoff：高召回或大量 memory records 可能给下游 answerer 带来噪声和成本。

第三，compact evidence 也有风险：过度压缩可能丢失 source nuance 或 uncertainty。因此本节应为后续 reward ablation 和 error analysis 铺垫，不要把“越短越好”绝对化。

**计划图 4.3：accuracy-token tradeoff。** 放在 4.5 中段。用 scatter plot 表示每个方法在 LoCoMo、LongMemEval 和 TimeMemEval/ChainMem 上的 overall accuracy 与 output tokens。横轴为 tokens，纵轴为 accuracy，NanoMem-GRPO 应位于较高准确率、较低 token 区域。该图是 Results 章节最有价值的可视化之一。

**计划表 4.9：NanoMem-Vanilla 与 NanoMem-GRPO compactness 对比。** 放在 4.5 末尾。列为 benchmark、Vanilla accuracy/tokens、GRPO accuracy/tokens、accuracy gain、token reduction。该表用于单独展示训练后的行为变化。

**TODO:** 第二阶段写正文前核对 token 列到底是 evidence output tokens、answer output tokens、还是传入 answerer 的 context tokens。若不同 baseline 的 token 定义不完全相同，应在表注中明确，避免不公平比较。

## 4.6 Architecture ablation：组件对结果的贡献

本小节对应 NeurIPS 的 architecture ablation，但硕士论文需要解释每个 ablation 的假设、预期失败模式和观察结果。

第一，移除 text normalization。预期影响主要集中在 temporal 类任务，因为相对时间表达不能被转成可检索的绝对时间提示。结果显示 LoCoMo multi-hop 下降较小，但 LoCoMo temporal、LongMemEval TR 和 TimeMemEval/ChainMem 下降更明显，说明 normalization 主要服务 temporal grounding。

第二，移除 Temporal Evidence Pool。预期影响更广，因为系统失去跨轮结构化 state，后续 Planner/Synthesizer 不能稳定利用前一轮 event_time/source 信息。结果显示该 ablation 对 LongMemEval TR 和 TimeMemEval/ChainMem 损害最大，也增加 average rounds，说明没有结构化 evidence state 时，多轮检索更容易变成低效重复搜索。

第三，限制为 single-round retrieval。预期它对直接可寻址问题影响有限，甚至可能减少噪声；但对 multi-hop 和 hidden-dependency 任务有害。结果确实显示 single-round 在 LoCoMo temporal 或 LME-TR 上不一定最差，但在 LoCoMo-MH 和 TimeMemEval/ChainMem 上明显下降。这一现象非常适合 thesis 解释：multi-round search 的价值不是普遍增加轮数，而是在缺 evidence 时继续。

正文应避免把 ablation 写成“每个组件在所有任务上都单调提升”。更准确的结论是：组件价值取决于任务是否需要 temporal grounding、state carry-over 或 hidden cue discovery。

**计划表 4.10：architecture ablation。** 放在 4.6 中段。列为 variant、LoCoMo-MH、LoCoMo-Temp、LME-TR、TimeMemEval/ChainMem、Avg. Rounds。使用 Full NanoMem-Vanilla、w/o text normalization、w/o Temporal Evidence Pool、single-round retrieval。

**计划图 4.4：组件移除造成的相对下降。** 放在 4.6 末尾。可用 heatmap：行是 ablation，列是任务，颜色表示 accuracy drop。该图帮助读者看到 text normalization、pool、single-round 的影响分布不同。若图数过多，可把该 heatmap 省略，保留表格。

## 4.7 Reward ablation：GRPO 学到了什么

本小节解释 reward design 的作用。它应从 Methods 的 reward components 回来，验证 format/length、verdict 和 outcome-oriented evidence usefulness 是否改变 policy 行为。

第一，full reward 作为基准，在 LoCoMo-MH、LoCoMo-Temp、LME-TR 和 TimeMemEval/ChainMem 上分别达到 89.0、87.5、86.4 和 51.5，verdict accuracy 约 84.0，平均轮数约 1.1，平均输出约 110 tokens。

第二，移除 format 与 length reward 后，accuracy 下降中等，但平均输出长度从 110 增加到 359 tokens。正文应解释这说明 format/length 不只是美观约束，而是在防止 Synthesizer 把大量冗余 evidence 交给下游 answerer。

第三，移除 verdict reward 后，LoCoMo-Temp 和 LME-TR 可能上升，但 LoCoMo-MH 和 TimeMemEval/ChainMem 明显下降，verdict accuracy 从 84.0 降到 72.9，平均轮数和 token 数上升。这个现象是本节的核心：outcome-only training 在第一轮 evidence 常够的任务上可能表现不错，但在需要判断“当前 evidence 不足、应继续搜索”的任务上缺少过程监督。

正文应把 reward ablation 与 research claim 连接起来：NanoMem 不只是训练一个更会回答的模型，而是训练 Synthesizer 更会判断 evidence sufficiency、何时停止、何时继续，以及如何保持 evidence 紧凑。

**计划表 4.11：reward ablation。** 放在 4.7 中段。列为 variant、LoCoMo-MH、LoCoMo-Temp、LME-TR、TimeMemEval/ChainMem、Verdict Acc.、Avg. Rounds、Avg. Tok.。表注说明 verdict accuracy 是逐轮 sufficient/insufficient 判断与 gold evidence coverage 的一致率。

**计划图 4.5：reward component 对 accuracy、verdict 与 tokens 的影响。** 放在 4.7 末尾。可用三个小面板：关键任务 accuracy、verdict accuracy、average tokens。该图应突出 remove verdict 与 remove format/length 的不同失败模式。

## 4.8 Qualitative case studies

本小节用少量 case 把表格中的机制讲清楚。硕士论文需要至少 2 到 3 个 case study，因为 NanoMem 的贡献是过程性的，单纯 accuracy 表无法展示 evidence search 如何发生。

Case 1：temporal bridge success。使用“升职那周在读什么书”或 TimeMemEval 中类似样本。正文展示第一轮检索找到 source/promotion event，Synthesizer 输出 event_time 并给出 insufficient verdict；第二轮 Planner 使用该时间窗口检索 destination/book session；最终 Synthesizer 输出 sufficient events。这个 case 用来展示 event_time 如何成为下一轮 retrieval cue。

Case 2：full-context 或 write-time baseline 失败，而 NanoMem 成功。选择一个长历史噪声较多的 LongMemEval 或 LoCoMo temporal 样本，展示 baseline 被 surface keyword 或 session_time 误导，而 NanoMem 通过 source-grounded event evidence 缩小上下文。

Case 3：NanoMem failure。必须包含一个失败案例，避免 Results 过度正向。可能失败模式包括 temporal normalization 没有覆盖的表达、Planner 生成错误 cue、Retriever 未召回 destination session、Synthesizer verdict 过早 sufficient、或 evidence 过度压缩导致 answerer 缺少关键限定。正文只做结果层面的错误展示，原因归纳和改进方向留到 Discussion。

每个 case 不应贴长对话全文，而应用小表呈现 query、关键 retrieved sessions、Synthesizer events、verdict、final answer、gold answer 和诊断。原始长 transcript 可放附录。

**计划表 4.12：case study 1 temporal bridge trace。** 放在 4.8 中段。列为 round、retrieval cue、retrieved evidence summary、event_time、verdict、下一步。该表展示 NanoMem 的 iterative mechanism。

**计划表 4.13：case study 对比。** 放在 4.8 后半。列为方法、返回内容、answer、错误原因或成功原因。用于比较 NanoMem 与一个 baseline。

**计划图 4.6：成功案例的两轮 evidence chain。** 放在 4.8 中段，可选。图中只画 source event、derived window、destination event 和 final evidence，适合读者直观看到 hidden dependency search。若全文图数已超预算，可用表 4.12 替代。

**TODO:** 第二阶段写正文前从真实评估 trace 中选择 case。不能凭计划构造虚假 trace；必须核对 query、session_id、event_time、verdict 和 final answer 是否来自真实运行日志。

## 4.9 Error analysis 与结果边界

本小节总结错误类型，但不展开完整 Discussion。正文应基于 case study 和评估 trace，把失败分成几类：

第一，retrieval miss。Planner cue 或 retriever 没有召回 gold evidence session，Synthesizer 即使判断正确也缺少可用 evidence。这类错误说明 evidence synthesis 不能弥补召回缺口。

第二，temporal grounding error。相对时间表达解析失败、event_time 推断偏移、或者 session_time 与 event_time 混淆，导致后续搜索窗口错误。

第三，premature sufficiency。Synthesizer 在 evidence 未覆盖 gold sessions 时输出 sufficient，导致 loop 过早停止。该错误与 verdict reward 直接相关。

第四，over-search 或 evidence bloat。系统在已经有足够 evidence 时继续检索，可能引入噪声并增加 tokens。移除 verdict reward 或 format/length reward 时这类错误更明显。

第五，downstream answerer error。NanoMem evidence 正确但 Qwen3.5-9B answerer 仍然作答错误，说明 memory module 评估受到 answerer 能力影响。正文应保留这个边界，避免把所有 answer failure 都归咎于 memory。

这一小节可以报告错误类型的定性比例或样本数，但只有在第二阶段能从 trace 中可靠统计时才写数字。否则使用定性分析，并明确这是人工检查的 representative cases。

**计划表 4.14：错误类型 taxonomy。** 放在 4.9 中段。列为错误类型、可观察信号、典型原因、影响的指标、对应改进方向。该表为第五章 Discussion 的 limitations 和 future work 做铺垫。

**计划图 4.7：错误传播路径。** 放在 4.9 末尾，可选。图从 Planner/Retriever miss、temporal grounding error、Synthesizer verdict error、answerer error 到 final answer failure，展示系统边界。若第五章计划使用 failure taxonomy 图，则本章不重复画图。

## 4.10 小结：Results 对研究问题的回答

本章最后一小节用简短段落回收实验证据：

第一，主结果表明 NanoMem-GRPO 在 LoCoMo、LongMemEval 和 TimeMemEval/ChainMem 上整体优于或强竞争于 full-context、write-time memory、search-time retrieval 和 temporal baseline，同时输出更紧凑的 evidence。

第二，分任务结果说明收益主要集中在 multi-hop、temporal reasoning 和 hidden-dependency temporal bridge 场景，这正对应 evidence addressability gap。

第三，architecture ablation 说明 text normalization、Temporal Evidence Pool 和 multi-round retrieval 分别服务于不同失败模式，不是简单堆叠组件。

第四，reward ablation 说明 GRPO 的作用不仅是提升 accuracy，还包括训练 sufficiency judgment 和 compact evidence behavior。

最后一句应过渡到 Discussion：第五章将讨论这些结果对 memory-as-evidence-provider 范式的意义、当前实验设计的威胁、部署中的隐私与成本问题，以及未来如何扩展到更长 causal chain、belief revision 和更可靠的 evidence auditing。

## 与 NeurIPS 论文相比的扩展要求

会议论文的 Experiments 需要在有限篇幅内快速报告主结果和两个 ablation；硕士论文 Results 应显著扩展以下内容。

一是把实验 protocol 写完整，包括数据集角色、split、baseline 类别、模型配置、judge、answerer、token 指标和评估边界。

二是把表格解释从“谁最高”扩展为“为什么这些结果支持 evidence-provider 设计”。尤其要把 LoCoMo/LongMemEval 的通用长期记忆结果与 TimeMemEval/ChainMem 的 hidden-dependency 诊断结果分开解释。

三是单独分析 compactness。NanoMem 的目标不是只提高 answer accuracy，而是以更短、结构化、可追踪的 evidence 支持下游 answerer。

四是更深入解释 ablation。text normalization、Temporal Evidence Pool、multi-round retrieval、verdict reward、format/length reward 的效果在不同任务上不完全相同，硕士论文应解释这些非单调现象。

五是增加 qualitative case study 和 error analysis。NanoMem 的机制是过程性的，必须展示 evidence chain、verdict loop 和失败传播路径，不能只依赖 aggregate accuracy。

六是明确哪些结论尚受限制：LLM judge、固定 downstream answerer、baseline token 定义、未统计 latency、TimeMemEval/ChainMem 的生成式 benchmark 偏差等问题应在 Results 中标注，Discussion 中展开。

## 本章计划图表汇总

| 编号 | 位置 | 类型 | 内容 | 作用 |
|---|---|---|---|---|
| 图 4.1 | 4.1 末尾 | 实验地图 | RQ3 到主结果、compactness、ablation、case study、error analysis 的映射 | 帮助读者理解实验组织逻辑 |
| 表 4.1 | 4.2 末尾 | 数据集表 | LoCoMo、LongMemEval、TimeMemEval/ChainMem 的任务覆盖与用途 | 说明多个 benchmark 的互补性 |
| 表 4.2 | 4.2 末尾/附录 | split 表 | 原始、过滤、训练、held-out evaluation 数量与泄漏控制 | 支撑可复现性 |
| 表 4.3 | 4.3 末尾/附录 | baseline 表 | baseline 类别、backbone、answerer、输出形式 | 建立比较公平性 |
| 表 4.4 | 4.3 末尾 | 指标表 | accuracy、tokens、rounds、verdict accuracy 的定义 | 避免指标解释混乱 |
| 表 4.5 | 4.4 开头/末尾 | 主结果摘要 | 三个 benchmark 的关键 accuracy 摘要 | 快速支撑主 claim |
| 表 4.6 | 4.4 | 结果表 | LoCoMo category-level accuracy/tokens | 展示标准长对话记忆表现 |
| 表 4.7 | 4.4 | 结果表 | LongMemEval category-level accuracy/tokens | 展示长噪声历史中的表现 |
| 表 4.8 | 4.4 | 结果表 | TimeMemEval/ChainMem difficulty 与 terminal type 结果 | 展示 hidden-dependency temporal bridge 能力 |
| 图 4.2 | 4.4 末尾 | 对比图 | 跨 benchmark accuracy 与 compactness 总览 | 可视化准确率和输出长度的共同变化 |
| 图 4.3 | 4.5 中段 | scatter 图 | accuracy-token tradeoff | 强化 compact evidence 的 practical significance |
| 表 4.9 | 4.5 末尾 | 对比表 | Vanilla 与 GRPO 的 accuracy/token gain | 分离 framework 与 training effect |
| 表 4.10 | 4.6 中段 | 消融表 | text normalization、Temporal Evidence Pool、single-round retrieval | 验证 architecture component |
| 图 4.4 | 4.6 末尾 | heatmap | 组件移除造成的任务级下降 | 可选，用于展示不同组件影响不同任务 |
| 表 4.11 | 4.7 中段 | reward 表 | full reward、remove format/length、remove verdict | 验证 reward design |
| 图 4.5 | 4.7 末尾 | 多面板图 | reward ablation 对 accuracy、verdict、tokens 的影响 | 展示 reward 失败模式差异 |
| 表 4.12 | 4.8 中段 | trace 表 | temporal bridge success 的多轮 evidence chain | 展示 NanoMem 机制 |
| 表 4.13 | 4.8 后半 | case 对比表 | NanoMem 与 baseline 在具体样本上的输出差异 | 解释表格背后的机制 |
| 图 4.6 | 4.8 中段 | evidence chain 图 | source event、derived window、destination event | 可选，直观展示 hidden dependency |
| 表 4.14 | 4.9 中段 | 错误表 | retrieval miss、temporal error、premature sufficient、over-search、answerer error | 为 Discussion 铺垫 |
| 图 4.7 | 4.9 末尾 | 错误路径图 | 系统组件错误如何传播到 final answer failure | 可选，若第五章不重复使用 |

本章计划 7 张图、14 张表，其中图 4.1、4.4、4.6、4.7 都是可选图。考虑到前三章计划图数已经较多，最终 LaTeX 写作时建议 Results 保留 2 到 3 张核心图：accuracy-token tradeoff、reward ablation 多面板图、以及一个 evidence chain/case 图；其他信息主要用表格承载。这样全论文总图数可以控制在约 15 张，同时 Results 仍能充分展示实验结论。
