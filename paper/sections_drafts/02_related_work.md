# 第二章 Related Work 规划稿

本文档是第二章 Related Work 的中文规划稿，不是最终 LaTeX 正文。本章的任务不是简单扩写 NeurIPS 论文中很短的 related work，而是为硕士论文建立一个可读、可追踪的研究地图：先解释 long-term agent memory 的基本范式，再逐层收窄到 NanoMem 所处理的 temporal-causal evidence search 问题。最终正文需要让读者理解：NanoMem 不是又一个通用 memory framework，也不是普通 RAG agent，而是把 memory module 明确定位为 query-time evidence provider，并研究如何构造 compact、faithful、temporally grounded evidence。

本章应承接第一章中的 evidence addressability gap。第一章已经说明“为什么需要 evidence provider”；第二章要说明“已有工作分别解决了哪些部分，为什么还留下 NanoMem 的问题空间”。因此，本章的写法应当先中立介绍每类工作，再在每小节末尾明确指出与 NanoMem 的差异。不要把所有相关工作写成被 NanoMem 否定的对象；很多系统在写入、组织、检索、压缩、RL 训练等方面提供了重要基础，只是它们的目标函数、输出形式或 search state 与本文不同。

## 2.1 章节导入：从 memory system 到 evidence synthesis

本小节负责给 Related Work 章节定调。正文开头应说明 LLM agent memory 研究已经形成多个相邻方向：长期记忆管理、memory retrieval、temporal reasoning、RAG/agentic search、faithful evidence synthesis、以及 RL-trained retrieval or memory policy。它们共同服务于长期交互，但关注的系统边界不同。

本小节需要明确本章的组织逻辑：先讨论 memory 生命周期中的 write-side 与 search-side 区别，再讨论时间推理和间接可寻址 evidence，然后讨论 evidence synthesis 与 faithfulness，最后讨论 RL 如何被用于 memory/retrieval policy。这样组织的好处是读者可以看到 NanoMem 逐步落在一个更窄的位置：search-side、query-conditioned、evidence-centric、temporally grounded、verdict-driven。

这里应避免提前进入具体论文细节，只给出分类框架。正文可以用一段话强调：传统 related work 常按论文逐篇列举，但硕士论文应更系统地解释每个研究方向的目标、输入输出、代表性系统和剩余问题。

**计划图 2.1：Related Work 分类地图。** 放在 2.1 末尾。图中横轴表示 memory lifecycle，从 write-time ingestion/organization 到 query-time retrieval/synthesis；纵轴表示输出层次，从 raw session、memory record、ranked evidence、structured evidence 到 final answer。把 MemGPT、Mem0、A-MEM、MemOS、Zep、Memory-R1、MemReader、Memory-T1、SUMER、MemR3、Self-RAG/Search-R1 和 NanoMem 放在大致位置。该图的作用是帮助读者在进入细节前理解本章分类，而不是给出精确 taxonomy 边界。

## 2.2 Long-term agent memory systems

本小节介绍长期 agent memory 的基本问题和主要系统形态。正文应先说明为什么长期交互需要外部 memory：context window 有限，用户历史跨 session 分散，信息有冗余、过期和冲突，agent 需要在当前 query 下重新访问历史。然后将 memory system 分成两类：write-side memory management 和 query-time memory access。

第一部分介绍 write-side memory systems。代表性工作包括 MemGPT、Mem0、MemOS、A-MEM、Zep、HyperMem、MemPalace、LightMem、MemoryBank、MemReader、Mem-alpha、Memory-R1 等。写作重点不是逐篇堆砌，而是解释它们共同面对的问题：如何把原始对话转化为更可管理的 memory units，如何做增删改查、链接、摘要、压缩、graph construction 或 memory evolution。正文可以分别用几个自然段覆盖：

第一，context management 与 virtual memory。MemGPT 类工作把 memory 看作 active context 与 external storage 之间的管理问题，强调何时把信息放入当前上下文、何时分页到长期存储。它为 agent memory 的系统边界提供了早期范式，但不专门解决 query-time temporal evidence synthesis。

第二，production-oriented persistent memory。Mem0、MemOS 等把 user history 管理成可复用的 memory service，关注可扩展存储、更新、去重和 API 化。它们对实际 agent deployment 很重要，但其主要输出通常是 memory records 或 retrieved memories，而不是带有 event_time/session_time/source/verdict 的 evidence state。

第三，structured and evolving memory organization。A-MEM、Zep、HyperMem 等工作通过 note linking、temporal knowledge graph、hypergraph 或动态组织机制提升 memory 的可检索性。它们说明 memory organization 本身很关键，但也带来一个论文需要强调的 tension：write-time extraction 必须在未来 query 未知时决定什么值得保留、如何解释时间表达、哪些关系应该固化。

第四，compression and efficient retention。LightMem、R3MEM 等方向通过压缩、topic segmentation、reversible representation 或 token reduction 降低长期历史的成本。这里应承认这些方法与 NanoMem 互补：压缩可以改善存储与检索效率，但如果压缩结果丢失了未来 query 需要的 hidden dependency，则 search-time evidence construction 仍然困难。

本小节末尾要收束到 NanoMem 的定位：NanoMem 不否认 write-side memory 的价值，但它研究的是 query 到来之后如何从保留的历史中构造 evidence。其核心差异在于 memory output 的目标不是“更好的 memory record”或“更高召回的 session list”，而是下游 answer model 可以检查和使用的 structured evidence。

**计划表 2.1：长期 agent memory 系统对比。** 放在 2.2 末尾。列为工作类别、代表系统、主要处理阶段、典型 memory 表示、典型输出、与 NanoMem 的关系。表中不要写过多论文细节，每类保留 2 到 4 个代表。该表用于把硕士论文读者带入领域，避免正文变成散乱论文列表。

**TODO:** 第二阶段写正文时核对最终可引用 bibkey，特别是 MemoryBank、GMemory、MemSifter、MemPalace 等是否已经在 NanoMem `refs.bib` 中完整存在；没有可核对来源的系统只作为 TODO，不写成正式引用。

## 2.3 Search-side memory retrieval and reflective retrieval

本小节从 write-side 转向 query-time。它应解释为什么只讨论 memory organization 不够：用户 query 到来时，系统还必须决定检索什么、如何排序、是否继续检索、以及把检索结果以什么形式交给下游模型。

正文可以把 search-side memory retrieval 分成三层。

第一层是 passive retrieval。标准 RAG 或 embedding-based top-k retrieval 根据 query 与 memory chunk/session 的相似度召回若干内容，然后直接交给下游 LLM。许多 memory framework 的检索阶段也可以落入这一类。它的优点是简单、通用、可扩展；局限是 query 中没有显式命名的 evidence 很难被召回，召回结果通常仍是 raw sessions 或 chunks，下游模型必须自己处理噪声、时间关系和证据充分性。

第二层是 ranking or selection proxy。MemSifter、Memory-T1 等工作不只是召回 top-k，而是学习排序或选择策略，让候选 evidence 更相关、更符合时间约束。Memory-T1 尤其重要，因为它直接针对 multi-session temporal reasoning，并使用 temporal-aware RL 信号训练 session selection。正文应清楚区分：这类方法提升的是 session-level selection 或 utterance-level selection，而 NanoMem 进一步研究 event-level evidence synthesis，即把 retrieved sessions 转化为结构化 evidence events，并显式判断当前 evidence 是否 sufficient。

第三层是 iterative or reflective retrieval。SUMER、MemR3、Self-RAG、Search-R1、SmartRAG 等工作说明检索可以是多轮的：系统可以反思缺口、改写 query、调用工具或继续搜索。这与 NanoMem 的 Planner-Synthesizer loop 有明显联系。正文应指出相似点是 adaptive search；差异在于 loop state。许多 reflective RAG 或 search agent 的 state 是 text snippets、reasoning trace、evidence gap description 或 final-answer-oriented context，而 NanoMem 的 state 是 Temporal Evidence Pool：每个 event 都保留 event_time、session_time、source identifier，并通过 verdict 决定是否继续。

这一小节需要解释“search-side”和“answer-side”不要混淆。有些系统直接在检索 loop 末尾回答问题，这会把 retrieval failure、evidence synthesis failure 和 answer generation failure 混在一起。NanoMem 的 thesis framing 应强调 memory module 的输出是 evidence，final answer generation 在系统边界之外或作为评测消费端存在。

**计划图 2.2：search-side memory 方法的输出层次。** 放在 2.3 中段。图从 query 开始，展示三条路径：passive retrieval 输出 raw sessions；ranking proxy 输出 ranked sessions/evidence sessions；reflective retrieval 输出多轮检索轨迹或 final answer；NanoMem 输出 Temporal Evidence Pool 和 verdict。该图与 2.1 不重复：2.1 是领域地图，2.2 是 search-time output pipeline 对比。

**计划表 2.2：query-time memory retrieval 范式对比。** 放在 2.3 末尾。列为方法范式、是否多轮、loop state、输出对象、是否显式 evidence sufficiency、主要风险。该表应突出 NanoMem 的定位：多轮、structured event state、explicit verdict、source-grounded evidence。

## 2.4 Temporal reasoning in dialogue and agent memory

本小节承接第一章的 event_time/session_time mismatch，系统介绍 temporal reasoning 为什么在 dialogue memory 中特别困难。正文应先说明长期对话中的时间信息有几种形式：绝对日期、相对表达、事件顺序、持续区间、过去/未来计划、更新后的事实、以及跨 session 的时间依赖。用户往往不会直接问“某年某月某日的 session 中说了什么”，而是问“我升职那周”“上次旅行前”“那次会议之后”等带有隐含时间锚点的 query。

接着介绍相关 benchmark 和系统。TimeBench 说明 LLM 普遍存在时间推理脆弱性；LoCoMo 和 LongMemEval 提供长期对话和交互记忆评测；TReMu、Zep、Memory-T1 等系统开始显式建模 temporal structure。这里要区分三种时间处理方式：

第一，把时间作为 memory metadata 或 graph structure。Zep 等 temporal knowledge graph 方向把时间关系编码进存储结构，适合长期事实组织，但它们仍可能在 query-time 面对相对表达、event interpretation 和 hidden dependency。

第二，把时间总结成 timeline summaries。TReMu 等方向尝试把多 session 对话组织为 timeline，并结合 symbolic or neuro-symbolic reasoning。它们有助于解释多 session 时间线，但 summary 一旦生成也会面对压缩与误差传播问题。

第三，把时间作为 retrieval or selection signal。Memory-T1 等方法用 predicted temporal window、temporal consistency 或 RL-trained selection 改善候选 session 选择。正文需要谨慎指出：如果系统 hard filter session_time，就可能错过 event_time 与 session_time 不一致的 session；如果只选择 sessions 而不构造 event-level evidence，下游仍要完成事件解释。

本小节应把 temporal reasoning 与 evidence addressability gap 联系起来：NanoMem 关心的不只是“能否解析日期”，而是解析出的 event_time 能否成为下一轮 retrieval cue。也就是说，时间推理在 NanoMem 中是 search state 的一部分，而不是静态 metadata。

这里可以计划一个小例子贯穿正文：用户在 4 月 2 日说“上周去了欧洲”，后来问“那次欧洲旅行期间我说过在读什么书”。这个例子展示 mention/session time 与 event time 的差异，以及为什么 event-time grounding 后还需要继续检索 book session。这个例子可以和第一章图 1.2 呼应，但第二章中不再画完整场景图，只用作文字对照。

**TODO:** 第二阶段写正文时需要核对 NanoMem 最终实现到底使用 `inferred` 字段和三值 verdict，还是采用最终 NeurIPS draft 中更简化的 schema。Related Work 可以讨论概念差异，但正式 Methods 必须以代码和最终论文源为准。

## 2.5 Evidence synthesis, faithfulness, and source grounding

本小节介绍从 retrieved text 到 usable evidence 的问题。它的核心论点是：retrieval 不是终点。长期记忆中的 raw sessions 往往很长、噪声多、包含多件无关事件；直接交给下游模型会增加幻觉和错误归因风险。因此 memory system 需要把检索结果压缩成 compact evidence，同时保留足够的 source grounding。

正文应先定义 evidence synthesis 在本文中的含义：不是最终 answer generation，而是把检索到的 session/chunk 转化为结构化、可检查、可追溯的 evidence records。每条 evidence 应回答几个问题：它说了什么；它来自哪个 session/source；session 是什么时候发生的；事件本身什么时候发生；该信息是直接观察还是由多个证据推断而来；当前 evidence 是否足以支持下游回答。

这一小节可以联系 general RAG 中的 faithfulness、attribution、citation 和 context compression 研究，但不要展开成完整 hallucination survey。重点是 memory-specific risk：当系统把跨 session 推断压缩成一句自然语言时，下游模型可能看不出哪些内容是原文支持、哪些是模型推断；当 source identifiers 缺失时，人和评测器也难以诊断错误来自检索还是 synthesis。

正文应把 NanoMem 与普通 summarization/answer generation 区分开。NanoMem 的 evidence event 不应像 final answer 那样追求自然语言完整性，而应追求 inspectability：字段明确、source 明确、时间明确、verdict 明确。这样才能支持后续实验中的 evidence-provider/direct-answerer 对比，也能解释为什么 verdict 是 memory-side sufficiency signal，不是 answer confidence。

本小节末尾可以埋下 Methods 的接口需求：后续章节会定义 Temporal Evidence Pool，说明 Planner、Retriever、Synthesizer 如何围绕 evidence state 工作；Results 章节会评估 compactness、answer usefulness、temporal grounding 和 sufficiency/verdict behavior。Related Work 不需要给 reward 公式，但要说明为什么这些评价维度不是附加指标，而是 memory-as-evidence-provider 的自然要求。

## 2.6 Reinforcement learning for memory and retrieval policies

本小节讨论 RL 在 memory 和 retrieval 中的作用。正文应先说明为什么 RL 被引入：memory/retrieval policy 的好坏往往不能只靠 next-token likelihood 衡量；系统需要学习何时写入、何时检索、检索哪些 evidence、何时停止、以及输出是否对最终任务有帮助。于是近期工作开始用 PPO、GRPO、preference optimization 或 outcome reward 训练 memory manager、retrieval agent、search agent 或 answerer。

本小节可分成三类。

第一，write-side RL for memory management。Memory-R1、Mem-alpha、MemReader 等工作使用 RL 或 learnable policy 训练 memory extraction、ADD/UPDATE/DELETE、active memory construction 或 memory utilization。它们说明 memory 操作可以被训练，而不是完全依赖手写规则；但其 action space 多在写入或 memory lifecycle 管理，不直接对应 query-time evidence event synthesis。

第二，search-side RL for retrieval and RAG。Search-R1、Self-RAG、RAG-RL、RPO、SSFO、TreeGRPO、Stratified GRPO、SUMER 等工作把 RL 用于多步搜索、检索决策、query rewriting、tool use 或 reflective retrieval。它们与 NanoMem 共享“多轮搜索可以训练”的思想，但很多 reward 主要来自最终答案正确性或搜索成功，而不是中间 evidence 的 temporal grounding 和 sufficiency state。

第三，temporal-aware or evidence-aware RL in memory。Memory-T1 与 NanoMem 最接近，因为它把 temporal consistency 纳入训练信号，面向 multi-session temporal reasoning。正文要清楚解释差异：Memory-T1 的训练目标主要服务于 session selection and answer generation，而 NanoMem 训练 Synthesizer 作为 intermediate evidence construction policy，奖励 parseable format、compactness、answer usefulness 和 verdict/sufficiency behavior。

本小节应强调 thesis 的一个重要论证：只用 terminal answer reward 不够。对于 temporal-causal evidence search，系统可能第一轮找到 temporal anchor 但还没有找到 answer-bearing session；此时如果只看最后答案，很难给“继续检索”这个中间决策分配 credit。NanoMem 的 verdict reward 或 sufficiency supervision 正是为了给每轮 stop/continue decision 提供过程信号。

**计划表 2.3：RL 信号与训练对象对比。** 放在 2.6 末尾。列为代表工作、训练对象、action space、主要 reward、是否监督 stop/continue、是否输出 structured evidence。表中 NanoMem 的行要突出：训练对象是 Synthesizer/evidence construction policy，action 包括 reasoning、events、verdict，reward 覆盖格式、结果、长度和 verdict。

## 2.7 Benchmarks for long-term and temporal memory

本小节为后续 Results 章节做铺垫，介绍为什么现有 benchmark 不能完全覆盖 NanoMem 的目标。正文应讨论 LoCoMo、LongMemEval、TimeBench 以及 ChainMem 或自建 temporal-causal benchmark 的角色。

LoCoMo 和 LongMemEval 适合评估长期对话记忆与多 session answer quality，但它们的问题不一定都要求真正的 hidden-dependency evidence search。有些问题可以通过一次高召回检索或 full-context answerer 解决。因此它们是必要 benchmark，但不足以单独证明 iterative evidence search 的价值。

TimeBench 更关注一般 LLM temporal reasoning 能力，可用于说明时间推理是广泛困难点，但它不一定具备 agent memory 中的 session/source/evidence construction setting。

ChainMem 或 NanoMem 自建 benchmark 应被定位为 diagnostic benchmark：它专门构造“下一步检索 cue 必须由上一轮 evidence 推断出来”的样本，用于测试 evidence addressability gap。正文应说明它不是取代 LoCoMo/LongMemEval，而是补充它们未充分覆盖的 hidden-dependency search 场景。

本小节不要提前写具体实验数字，也不要重复 Results 的主表。它只需要让读者理解为什么第四章会同时报告多个 benchmark：通用长期记忆、长期交互记忆、时间推理诊断、多跳/hidden dependency 诊断分别检验不同能力。

**计划表 2.4：benchmark 能力覆盖矩阵。** 放在 2.7 末尾。列为 benchmark、主要场景、是否多 session、是否需要 temporal grounding、是否强调 hidden dependency、是否提供 evidence/source supervision、在本文中的用途。这个表能帮助 Results 章节自然引出实验设置。

## 2.8 小结：NanoMem 的研究空白

本章最后一小节负责把分类重新收束为明确的 research gap。正文应避免写成“现有方法都不行”，而应更精确地总结：

第一，write-side memory systems 解决了长期历史如何被存储、压缩、链接和更新的问题，但在未来 query 未知时很难预先保留所有 hidden dependency，也难以把 query-conditioned event interpretation 固化为 memory records。

第二，search-side retrieval and reflective RAG 证明了 query-time adaptive search 的必要性，但常见输出仍是 raw snippets、ranked sessions、reasoning traces 或 final answers，缺少面向 downstream answer model 的 structured evidence state。

第三，temporal memory systems 开始显式处理时间，但很多方法把时间作为 metadata、timeline summary 或 filtering signal，而 NanoMem 需要把 event_time 作为跨轮检索的工作状态。

第四，RL for memory/retrieval 已经证明 policy learning 的价值，但 outcome-only reward 难以监督 evidence construction 中的中间决策，尤其是当前 evidence 是否 sufficient 以及何时继续检索。

最后一句应自然过渡到 Methods：因此，本文研究的是一个 search-time memory evidence provider：它通过 Planner-Synthesizer loop 构造 Temporal Evidence Pool，用 structured events 表示 source-grounded temporal evidence，并用 verdict 驱动 iterative retrieval，直到 evidence 足够交给下游 answer model。

## 与 NeurIPS 论文相比的扩展要求

NeurIPS related work 的目标是压缩地定位贡献，硕士论文 Related Work 应显著扩展以下内容。

一是从“列举相关系统”扩展为“解释研究版图”。每个方向都要先说明基本目标和系统边界，再讨论代表工作，最后说明 NanoMem 继承了什么、不同在哪里。

二是增加 write-side/search-side 的 taxonomy。会议论文只需要说明 NanoMem 不同于现有 memory framework；硕士论文应系统解释为什么 query-agnostic write-time processing 与 query-time evidence synthesis 是不同问题。

三是更完整地讨论 temporal reasoning。第二章应把 TimeBench、LoCoMo、LongMemEval、TReMu、Zep、Memory-T1 等放进同一叙事中，说明时间可以作为 metadata、summary、filtering signal、selection reward 或 search state。

四是单独讨论 evidence synthesis 与 faithfulness。会议论文可以把 evidence record 当作方法设计；硕士论文需要解释为什么 raw retrieved sessions 不等于 evidence，以及 source grounding、event_time、inferred/verdict 等字段为什么服务于可诊断性。

五是把 RL 相关工作拆清楚：write-side memory RL、search-side RAG RL、temporal-aware memory RL 和 NanoMem 的 evidence construction RL 分别训练不同对象，不能混为一类。

六是补充 benchmark 视角。Related Work 应提前说明为什么单一 benchmark 不能完全覆盖 long-term memory、temporal reasoning 和 hidden-dependency search，帮助第四章的实验设计显得合理。

## 本章计划图表汇总

| 编号 | 位置 | 类型 | 内容 | 作用 |
|---|---|---|---|---|
| 图 2.1 | 2.1 末尾 | 分类图 | memory lifecycle 与输出层次上的相关工作地图 | 帮助读者建立 long-term memory、retrieval、evidence synthesis 的整体坐标 |
| 表 2.1 | 2.2 末尾 | 对比表 | 长期 agent memory 系统的阶段、表示和输出 | 系统介绍 write-side memory framework，并定位 NanoMem 的 search-side 角色 |
| 图 2.2 | 2.3 中段 | 流程对比图 | passive retrieval、ranking proxy、reflective retrieval、NanoMem 的 query-time 输出差异 | 直观展示 raw sessions、ranked sessions、final answer 与 Temporal Evidence Pool 的区别 |
| 表 2.2 | 2.3 末尾 | 对比表 | query-time retrieval 范式、loop state、sufficiency signal | 支撑 NanoMem 与 search-side/reflective retrieval 的差异论证 |
| 表 2.3 | 2.6 末尾 | 对比表 | RL 工作的训练对象、action space、reward 和 evidence 输出 | 说明 NanoMem 的 reward 设计为何针对 intermediate evidence construction |
| 表 2.4 | 2.7 末尾 | 覆盖矩阵 | LoCoMo、LongMemEval、TimeBench、ChainMem 等 benchmark 覆盖能力 | 为 Results 章节的多 benchmark 评估做铺垫 |

本章计划 2 张图、4 张表。全论文目标约 15 张图，第二章使用 2 张图较合适：Related Work 的主要负担是分类与比较，因此表格比图更重要。第一章已计划 3 张图，第二章后全论文累计 5 张图；剩余图应主要留给 Methods 的系统架构/训练流程、Results 的主结果/消融/case study，以及 Discussion 的 failure taxonomy 或 deployment boundary。
