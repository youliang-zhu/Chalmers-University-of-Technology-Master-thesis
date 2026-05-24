# 第二章 Related Work 规划稿

本文档是第二章 Related Work 的中文规划稿，不是最终 LaTeX 正文。本轮重构的目标是把第二章从“论文列表式综述”改成一条清晰的研究脉络：先解释什么是 LLM agent，再解释长期 agent memory，接着单独讨论 RAG，随后收窄到 temporal reasoning in agent memory，最后讨论 reinforcement learning for agent memory。这样读者能看到 NanoMem 的位置：它不是普通 RAG，也不是重度 write-time memory extraction，而是一个面向长期对话 agent 的 query-time temporal evidence construction 研究。

本章建议结构如下：

```text
Chapter 2 Related Work
  2.1 LLM Agents
  2.2 Long-Term Agent Memory
  2.3 RAG
  2.4 Temporal Reasoning in Agent Memory
  2.5 Reinforcement Learning for Agent Memory
```

写作语气应中立。Related Work 不要把已有工作写成“都不行”，而要说明它们分别解决了什么问题、系统边界是什么、输出形式是什么，以及为什么 NanoMem 研究的是一个不同但相邻的问题。

## 2.1 LLM Agents

本小节负责给非 agent 方向读者建立最小背景。正文不要写成长篇 agent survey，只需要说明 LLM agent 是什么，以及为什么 memory 会成为 agent 的关键组件。

正文建议写 2 到 3 段。

第一段定义 LLM agent。LLM agent 可以被描述为以大语言模型为核心控制器的系统，它不仅生成文本，还可以规划子任务、调用工具、读取外部环境、接收反馈，并在多轮过程中调整行为。与普通 chatbot 相比，agent 的重点不是单次 response，而是在较长任务中维持状态并完成跨步骤决策。

第二段说明 agent 的典型模块。可以简单提到 planning、tool use、retrieval、memory、reflection 或 feedback loop，但不要展开每个方向。这里的目标只是让读者知道 memory 是 agent 系统中的一个子模块，而不是本文凭空引入的新组件。

第三段自然过渡到下一节：当 agent 面向长期用户、工作流或对话任务时，当前 prompt 不足以保存所有历史状态，agent 需要 long-term memory 来保存和重新访问过去的偏好、计划、事实、事件和修改信息。本文研究的就是这个 memory 方向中的一个具体问题。

## 2.2 Long-Term Agent Memory

本小节介绍长期 agent memory 是什么，以及现有 agent memory 框架通常由哪些部分组成。这里是本章的背景核心，要和第一章的 agent memory 背景衔接，但比第一章更系统。

正文开头先说明为什么需要 long-term agent memory。长期交互中，用户历史被分散在多个 session 里，包含偏好、事实、任务状态、事件、计划、纠正和更新。直接依赖当前 context window 会造成遗忘，也会让用户反复提供相同信息。因此，agent memory 的基本任务是把历史交互变成未来 query 可以重新访问和使用的 memory resource。

接着结合图 2.1 解释一个通用 long-term agent memory framework。当前图文件路径为：

`/mnt/models/youliang/master_thesis/paper/figure/realted_work_memory_framework.png`

**计划图 2.1：Generic long-term agent memory framework。** 放在 2.2 中前部，在第一次解释 agent memory framework 时插入。图展示从 message history 和 current query 到 agent memory system，再到 relevant information、LLM 和 response 的流程。图中 memory system 内部包含四类主要功能：

第一，Information Extraction。它决定历史交互如何进入 memory，包括 direct archiving、summarization-based extraction 和 graph-based extraction。这里要说明 extraction 是 write-side 行为：系统在 query 到来之前或写入时决定哪些信息要保存、怎样压缩、怎样结构化。

第二，Memory Storage。它决定 memory 如何被存储和索引，包括 flat、hierarchical、vector-based 和 graph-based storage。这部分对应很多 agent memory 系统的工程基础：不同存储方式会影响检索效率、可解释性、更新成本和结构化能力。

第三，Memory Management。它包括 connecting、integrating、transforming、filtering、updating 等操作，用来维护长期 memory 的一致性、去重、更新和组织。这说明 agent memory 不是单次 RAG 检索，而是一个持续维护的长期系统。

第四，Information Retrieval。图中右侧展示 query time 的 memory access，包括 lexical-based retrieval、vector-based retrieval、structure-based retrieval 和 LLM-assisted retrieval。正文应强调：现有 agent memory 框架往往同时包含 write-side extraction/storage/management 和 query-side retrieval。NanoMem 的定位不是否认 extraction，而是采用轻量 write-side temporal enhancement，并把主要研究重点放在 query-time evidence construction。

然后介绍代表性 long-term agent memory 工作，建议按系统功能分类，而不是逐篇罗列：context management / virtual memory，persistent memory services，structured or graph-based memory，compression and retention。

本节末尾要引出 conversational agent memory。本文关注的是对话式长期 agent memory，而不是一般静态知识库。对话 memory 的特殊性在于：历史按 session 发生，信息会被更新或纠正，用户经常使用相对时间表达，事件的发生时间和提到时间可能不同。因此，长期对话 memory 需要的不只是“存储更多历史”，还需要在 query time 重新解释 memory 与当前问题之间的关系。

## 2.3 RAG

本小节单独讨论 RAG。它的任务是回答一个读者很可能会问的问题：NanoMem 看起来也在检索信息并交给 LLM，为什么它不是普通 RAG？

正文第一部分先说明 RAG 在做什么。Retrieval-Augmented Generation 的基本思想是：给定一个 query，从外部语料库中检索相关文档或片段，把检索结果放入 prompt，然后由生成模型基于这些外部 context 生成答案。经典 RAG 工作可以包括 REALM、DPR、RAG、FiD、Atlas 等。已有 `refs.bib` 中已经包含的 RAG/reflective RAG/search-side 工作包括 Self-RAG、SmartRAG、Search-R1、RAG-RL、RPO、SSFO、TreeGRPO、Stratified GRPO、MMOA-RAG、EMG-RAG 等。

第二部分介绍 RAG 的主要研究问题。传统 RAG 主要关心：如何构建或选择外部知识库，如何提高 retriever recall，如何 rerank retrieved passages，如何让 generator 忠实使用 retrieved context，如何减少 hallucination，如何判断什么时候需要检索，以及如何通过 RL 或 preference optimization 改善 retrieval/generation behavior。Self-RAG、SmartRAG、Search-R1、RAG-RL、RPO、SSFO 等工作体现了 RAG 从 one-shot retrieve-then-generate 向 reflective retrieval、multi-step search、faithfulness optimization 和 RL-trained search agent 的发展。

第三部分明确 RAG 与 long-term conversational agent memory 的本质差异。RAG 通常面向相对静态的外部文档库、网页、百科、论文或工具搜索结果；agent memory 面向某个 agent 与用户长期交互产生的个人化、多 session、可更新历史。后者不是普通 corpus，而是用户状态的一部分。RAG 的目标通常是回答当前信息需求；agent memory 的目标是让 agent 在长期交互中保持连续性、个性化和状态一致性。NanoMem 更进一步，把 memory module 的输出定义为 evidence，而不是 final answer。

第四部分写 NanoMem 与 RAG 的联系和区别。NanoMem 继承了 RAG 的 query-time retrieval 思想，也受 reflective RAG 和 search-agent RL 的启发；但 NanoMem 的研究对象不是开放域知识检索，而是长期对话 memory 中的 query-time temporal evidence construction。NanoMem 不是完全不做写入侧处理，而是在 write side 做轻量 temporal enhancement 和 indexing，避免重度 extraction 过早解释或破坏 memory 本身结构；主要推理与 evidence synthesis 放在 query time。

## 2.4 Temporal Reasoning in Agent Memory

本小节是 Related Work 的核心。写法可以参考 NanoMem 会议论文 `sections/relw.tex`：先说明 temporal reasoning 已经成为 agentic memory 的关键问题，再介绍 benchmark 和系统，最后说明 NanoMem 的不同点。

正文第一段解释为什么时间推理在 agent memory 中特殊。长期对话中的时间信息包括绝对日期、相对表达、事件顺序、持续区间、过去或未来计划、事实更新，以及跨 session 的隐含时间依赖。用户不会总是问“某年某月某日的 session 中说了什么”，而是会问“我升职那周”“上次旅行前”“那次会议之后”。这类 query 要求系统先找到 temporal anchor，再用这个 anchor 继续检索或判断证据。

第二段介绍 benchmark 支撑。TimeBench 和 Test of Time 说明 LLM 在一般 temporal reasoning 上仍然脆弱；LoCoMo 和 LongMemEval 把 temporal reasoning、multi-session reasoning、knowledge update 等作为长期对话 memory 的重要能力。这些 benchmark 合法化了本文的问题设定：temporal reasoning 不是一个附属功能，而是长期 memory 的核心能力之一。

第三段介绍已有 temporal memory 系统。Zep/Graphiti 将时间关系编码进 temporal knowledge graph 中，适合长期事实组织和历史关系维护。TReMu 等方向使用 timeline summaries 或 neuro-symbolic temporal reasoning 来处理多 session 时间线。Memory-T1 针对 multi-session temporal reasoning，用 temporal-aware RL 或 temporal consistency 信号训练模型选择或利用 temporally relevant sessions。

第四段明确 NanoMem 区别。NanoMem 不只是把时间作为 metadata、timeline summary 或 filtering signal，而是把 event_time 作为 query-time search state。一个 evidence event 中的 event_time 可以暴露下一轮检索需要的 temporal cue。换句话说，时间不是静态属性，而是 iterative evidence search 的工作状态。

## 2.5 Reinforcement Learning for Agent Memory

本小节讨论为什么 reinforcement learning 与 agent memory 有关，以及 NanoMem 的 RL 训练和已有 memory/RAG RL 的区别。

正文第一段说明引入 RL 的原因。Memory 系统中的很多决策不是简单 next-token likelihood 可以监督的：应该写入什么、更新什么、检索什么、是否继续检索、当前 evidence 是否足够、输出是否 compact、是否能帮助最终回答。这些决策更像 policy learning，因此近期工作开始把 PPO、GRPO、preference optimization 或 outcome reward 用于 memory manager、retrieval agent、search agent 或 answerer。

第二段介绍 write-side RL for memory。Memory-R1、MemReader、Mem-alpha 等工作使用 RL 或 learnable policy 训练 memory extraction、memory utilization、ADD/UPDATE/DELETE、active extraction 或 memory construction。它们证明 memory 操作可以被训练，而不必完全依赖手写规则。但这类工作主要作用在 ingestion 或 memory lifecycle 管理阶段，和 NanoMem 的 query-time evidence construction policy 不同。

第三段介绍 search-side RL for RAG and retrieval agents。Search-R1、RAG-RL、RPO、SSFO、TreeGRPO、Stratified GRPO、Self-RAG、SmartRAG、SUMER 等工作研究如何训练模型进行多步检索、query rewriting、tool use、faithfulness optimization 或 reflective search。这些工作与 NanoMem 共享一个思想：query-time search behavior 可以学习，而不是固定 top-k retrieval。但许多 reward 主要来自最终答案正确性、搜索成功或 faithfulness proxy，并不直接监督 memory evidence 是否 temporally grounded or sufficient。

第四段介绍 temporal-aware memory RL。Memory-T1 与 NanoMem 最接近，因为它关注 multi-session temporal reasoning，并把 temporal consistency 或 temporal selection 纳入训练。区别在于：Memory-T1 的核心目标更接近 session selection / temporal answer generation，而 NanoMem 训练的是 Synthesizer / evidence construction policy。NanoMem 的中间输出是 structured evidence events 和 sufficiency verdict，而不是只输出答案或候选 session。

本节最后一句可以自然过渡到 Methods：这些工作说明 memory 和 retrieval policy 可以被训练，但 NanoMem 将训练目标进一步对准 query-time evidence synthesis，尤其是 temporally grounded evidence 和 sufficiency judgment。

## 写作边界提醒

第一，Related Work 中不要提前报告实验结果，也不要写 NanoMem 的完整架构细节。Planner、Retriever、Synthesizer、Temporal Evidence Pool、GRPO reward 的具体公式和实现留到 Methods。

第二，RAG 部分要避免写成“RAG 很弱”。应写成：RAG 是 query-time external knowledge retrieval 的基础范式，NanoMem 借鉴了检索增强思想，但研究对象是长期对话 memory 中的 temporal evidence construction，二者任务边界不同。

第三，Long-Term Agent Memory 部分要明确：NanoMem 不是完全没有 write-side processing。它做轻量 extraction / temporal enhancement / indexing，但避免在 ingestion 阶段做重度解释或破坏原始 memory 结构；关键 reasoning 放在 query time。

第四，Temporal Reasoning 部分要保持最终 schema 一致：正式正文只写 binary verdict `sufficient` / `insufficient`。`indicative` 不作为当前系统字段。
