# 第一章 Introduction 规划稿

本文档是第一章 Introduction 的中文规划稿，不是最终 LaTeX 正文。它的目标是把 NanoMem 的 NeurIPS 引言扩展成硕士论文的开篇：先建立长期 agent memory 的研究背景，再明确 evidence addressability gap，最后给出研究问题、贡献、范围和论文结构。最终正文需要比会议论文更慢、更清楚地解释概念，尤其要让不了解 agent memory、temporal reasoning 和 retrieval-augmented LLM system 的读者也能跟上。

## 1.1 研究背景：长期交互中的 agent memory

本小节负责打开论文的问题空间。正文应先说明 LLM agent 正在从单次问答走向长期、跨 session 的交互场景；在这种场景中，agent 不能只依赖当前 context window，而需要外部 memory 来保留用户历史、偏好、事件和长期任务状态。随后强调 memory 的目标不是简单存储文本，而是把历史对话转化为下游 answer model 可以使用的 evidence。

这一小节需要把 memory system 的职责边界讲清楚：NanoMem 研究的是 memory module 如何提供 compact、faithful、source-grounded evidence，而不是让 memory module 直接替代下游模型回答问题。这样可以为后续方法章节中的 Planner-Synthesizer loop、Temporal Evidence Pool 和 verdict 机制建立动机。

计划使用的例子是一个简单跨 session 问题，例如用户问“我升职那周在读什么书”。正文不在这里展开完整流程，只用它提示读者：答案不是来自一个显式命名的 session，而是需要先找到“升职”事件，再推断时间窗口，再检索“读书”相关证据。

**计划图 1.1：长期 agent memory 的职责边界。** 放在 1.1 末尾。图中左侧是多 session dialogue history，中间是 memory evidence provider，右侧是 downstream answer model。图的重点不是系统架构细节，而是说明 memory 输出的是 structured evidence，不是 final answer。该图可以作为全论文第一张概念图，帮助读者理解“memory as evidence provider”的定位。

## 1.2 核心问题：evidence addressability gap

本小节定义论文的核心问题。所谓 evidence addressability gap，是指回答 query 所需的 evidence 往往不能被 query 文本直接命中。它可能隐藏在相对时间表达、因果前置事件、用户记忆中的属性、或者前一轮检索后才暴露的实体和时间窗口之后。现有一次性 retrieval 或 write-time memory extraction 容易失败，是因为它们假设 query 中已经包含足够的检索 cue。

正文需要把这个 gap 拆成三个互相连接的挑战：

第一，event_time 与 session_time 的错位。session_time 表示用户何时提到某件事，event_time 表示事情何时发生。用户在 4 月 2 日说“我上周去了欧洲”时，mention event 发生在 4 月 2 日，而 travel event 发生在上一周。只按 session_time 检索会错过事件真实时间，只在 write-time 存一个固定 extracted memory 又可能丢掉 mention event。

第二，间接可寻址的 temporal evidence。系统先找到某个事件后，才能得到下一轮检索需要的时间窗口或实体 cue。例如先找到 promotion event，推断“升职那周”，再用这个时间窗口检索 book session。这里的关键不是普通 multi-hop reasoning，而是 retrieval cue 本身需要通过前一轮 evidence synthesis 才能形成。

第三，压缩 evidence 时的 faithfulness 风险。memory system 如果把跨 session 推断写成看似直接观察到的事实，下游模型无法判断哪些 evidence 是原文支持、哪些是推断。Introduction 中不需要展开 reward 细节，但要提前埋下 inferred 字段的动机。

**计划图 1.2：session_time、event_time 与间接 evidence search 示例。** 放在 1.2 中段，复用并扩展 NeurIPS intro figure 的概念：用户在一个 session 中提到未来或过去事件，系统需要区分 mention time 和 happened time；随后用推断出的 time span 检索另一个 session。图中应标出 one-shot session-time search、single-pass temporal search 和 NanoMem-style iterative evidence search 的差异。该图是 Introduction 的核心问题图。

## 1.3 现有方法为什么不足

本小节不做完整 related work survey，完整综述留给第二章。这里的任务是用少量类别说明 gap 为什么不是已有方法自然解决的问题。

第一类是 write-time memory 方法。它们在 query 到来之前抽取、压缩、链接或更新 memory records。这类方法适合降低存储和检索成本，但它们必须在不知道未来 query 的情况下决定什么值得保留、如何解释时间表达、哪些信息可以合并。正文需要强调：这不是说 write-time 方法没有价值，而是说 query-agnostic compression 很难处理未来才出现的 hidden dependency。

第二类是 retrieval 或 reranking 方法。它们保留原始 session，并在 query time 召回或排序候选内容。相比 write-time 方法，这类方法更接近 evidence provider 的方向；但如果输出仍然是原始 session list，下游 answer model 必须同时完成噪声过滤、时间推断、跨 session 连接和最终作答，memory module 没有显式告诉下游 evidence 是否充分。

第三类是 end-to-end 或 reflective retrieval agent。它们可能做多轮检索或直接输出答案，但 memory 质量、检索轨迹和 answer generation 容易混在一起评估。Introduction 中只需要指出 NanoMem 与这些方向的区别：NanoMem 把 memory module 明确限制为 evidence synthesis，并通过 verdict 判断是否继续检索或停止。

**计划表 1.1：Introduction 中的简化方法对比。** 放在 1.3 末尾。列为方法范式、典型输出、主要优势、对 evidence addressability gap 的不足。表只用于快速定位问题，不替代第二章的系统综述。相关工作章节再扩展具体论文和 citation。

## 1.4 本论文的目标与研究问题

本小节把动机转化为硕士论文的研究目标。总目标可以写成：研究一个 long-term conversational memory system 能否在 query time 构造 compact、faithful、temporally grounded evidence，并把 evidence 是否充分的判断显式暴露给下游 answer model。

计划提出三个 research questions：

RQ1：如何把长期对话 memory 表示为带有 source、session_time、event_time 和 inferred 标注的 structured evidence，而不是只返回 raw sessions 或 final answer？

RQ2：如何通过 Planner-Synthesizer loop 逐轮利用已有 evidence 产生新的 retrieval cues，从而恢复原始 query 中没有直接命名的 temporal-causal evidence？

RQ3：在 LoCoMo、LongMemEval 和 ChainMem 等 benchmark 上，NanoMem 相比 write-time memory、reranking memory 和 iterative retrieval baseline 在 answer quality、evidence compactness、temporal grounding 和 sufficiency 判断上有什么表现差异？

正文中需要说明这些 RQ 分别对应 thesis 后续章节：RQ1 主要由 Methods 的 schema 和 Temporal Evidence Pool 回答；RQ2 由 iterative search、Planner、Synthesizer 和 verdict loop 回答；RQ3 由 Results 的主结果、消融和 case study 回答。

## 1.5 NanoMem 方法概览

本小节给出高层方法概览，但不抢 Methods 章节的细节。正文应介绍 NanoMem 的三层思想：

第一，ingestion 阶段进行轻量 temporal normalization 和 indexing，为 search-time reasoning 提供候选材料，但不把全部未来 query 相关解释提前写死。

第二，query time 使用 Planner-Synthesizer loop。Planner 根据用户 query 和上一轮 Synthesizer 的 reasoning/gap 生成 retrieval cues；Retriever 召回候选 sessions 或 chunks；Synthesizer 把检索结果转化为 structured events，并维护 Temporal Evidence Pool。

第三，Synthesizer 输出 verdict：sufficient 表示 evidence 足以交给下游 answer model；insufficient 表示需要继续检索；indicative 表示有相关 evidence 但仍需要保留不确定性。Introduction 中要强调 verdict 是 evidence sufficiency 的控制信号，而不是最终答案置信度。

这里还要简短交代训练思想：Synthesizer 不是只靠 prompting，而是通过 SFT warm-up 和 GRPO 训练；reward 覆盖 parseable format、compactness、answer usefulness、faithfulness、temporal grounding 和 verdict accuracy。具体公式和实现留到 Methods。

**计划图 1.3：NanoMem 高层工作流。** 放在 1.5 中段。图从 query 开始，展示 Planner、retrieval、Synthesizer、Temporal Evidence Pool、verdict loop 和 downstream answer model。与图 1.1 的区别是：图 1.1 讲职责边界，图 1.3 讲 NanoMem 自身的核心流程。Methods 章节会有更细的系统架构图，因此 Introduction 图应保持简洁。

## 1.6 贡献总结

本小节用 4 个贡献点结束技术动机部分。写作时应避免只照搬 NeurIPS 贡献列表，而要以 thesis 的更宽视角表达：

第一，本文把 long-term agent memory 重新表述为 temporal-causal evidence synthesis 问题，并明确 memory module 的职责是向下游 answer model 提供 inspectable evidence。

第二，本文提出 NanoMem 的 Planner-Synthesizer loop 和 Temporal Evidence Pool，用 session_time、event_time、inferred、source identifiers 和 verdict 来表示 evidence search 的中间状态。

第三，本文通过 SFT 与 GRPO 训练 Synthesizer，使 evidence construction 受到 answer quality、faithfulness、temporal grounding、compactness 和 sufficiency/verdict signal 的约束。

第四，本文在 LoCoMo、LongMemEval 和 ChainMem 上评估 NanoMem，并用 ablation 与 case study 分析 event_time、inferred 和 verdict 等设计在不同失败模式中的作用。

如果最终实验数字在第二阶段写正文时尚未完全核对，Introduction 中不要写具体百分比；只写定性贡献，并在 Results 章节核对后再回填。

## 1.7 范围与限制

本小节是硕士论文需要比会议论文更明确的部分。正文应说明 thesis 的范围：

本文关注 memory evidence construction，不研究通用 final answer generation；下游 answer model 只是 evidence consumer。

本文的 temporal reasoning 主要围绕 multi-session conversational memory 中的相对时间、event-time grounding 和由时间窗口触发的后续检索，不声称解决所有时间逻辑推理问题。

本文的实验结论受数据集、retriever 设置、base model、answerer 和 evaluation protocol 限制。Introduction 只做范围声明，详细威胁与限制放到 Discussion。

这里可以加入一个简短 **TODO:** 第二阶段写正文前核对最终实现中 ingestion、retrieval、answerer 和 ChainMem 命名是否与 NeurIPS 最终版本完全一致。

## 1.8 论文结构

最后一小节用一段或五个短段说明全文结构：

第二章介绍 long-term agent memory、temporal reasoning、search-side retrieval、evidence synthesis 和 RL for memory 的相关工作。

第三章介绍 NanoMem 的 problem formulation、system design、Temporal Evidence Pool、Planner-Synthesizer loop、training objective 和 benchmark construction。

第四章介绍实验设置、benchmark、baseline、evaluation metrics、主结果、消融和 case study。

第五章讨论 NanoMem 的意义、限制、伦理与隐私风险、可扩展性、未来工作，并总结全文。

## 与 NeurIPS 论文相比的扩展要求

会议论文的 Introduction 需要快速进入方法和贡献；硕士论文的 Introduction 应当显著扩展以下内容：

一是增加 memory system 职责边界的解释，让读者理解为什么 NanoMem 不直接输出 final answer。

二是更系统地定义 evidence addressability gap，把 event-time/session-time mismatch、hidden dependency 和 faithfulness risk 组织成同一个问题框架。

三是加入明确 research questions，并在后续章节形成可追踪的回答。

四是加入 scope and delimitations，避免把 NanoMem 的能力表述成泛化到所有 agent memory 或所有 temporal reasoning 问题。

五是把图的功能分层：第一张图讲职责边界，第二张图讲核心失败模式，第三张图讲 NanoMem 高层流程。Introduction 不应放过多实验结果图，实验相关图表留到 Results。

## 本章计划图表汇总

| 编号 | 位置 | 类型 | 内容 | 作用 |
|---|---|---|---|---|
| 图 1.1 | 1.1 末尾 | 概念图 | dialogue history、memory evidence provider、downstream answer model 的职责边界 | 建立 memory as evidence provider 的论文定位 |
| 图 1.2 | 1.2 中段 | 问题图 | session_time/event_time 错位与间接 evidence search 示例 | 展示 evidence addressability gap 的核心失败模式 |
| 图 1.3 | 1.5 中段 | 流程图 | Planner、retrieval、Synthesizer、Temporal Evidence Pool、verdict loop | 给出 NanoMem 方法概览，为 Methods 铺垫 |
| 表 1.1 | 1.3 末尾 | 对比表 | write-time memory、retrieval/reranking、iterative retrieval agent、NanoMem 的简化对比 | 用最小篇幅说明现有范式不足，避免 Introduction 变成完整 related work |

本章计划 3 张图、1 张表。全论文目标约 15 张图，Introduction 占用 3 张是合理的：它们分别承担定位、问题和方法概览三种不同功能，后续章节再展开架构、训练、benchmark、结果和案例图。
