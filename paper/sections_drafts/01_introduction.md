# 第一章 Introduction 规划稿

本文档是第一章 Introduction 的中文规划稿，不是最终 LaTeX 正文。本轮重构参考 `agents/resources/references/ref1.pdf` 的第一章组织方式：章节开头先用若干段自然引入研究背景，然后按 `1.1 Significance of the Study`、`1.2 Problem Description`、`1.3 Purpose of the Study`、`1.4 Thesis Outline` 展开。Introduction 不再采用会议论文式的“快速提出方法、列贡献、报结果”结构，而是先让读者理解研究场景、问题为什么重要、具体问题是什么、本文为什么研究它。

本章写作基准以 NanoMem 原文仓库中的会议论文最终方法描述为准。正式 thesis 中应采用最终 schema：Synthesizer 输出 structured events 和二值 verdict，即 `sufficient` 或 `insufficient`。`indicative` 不应作为当前系统字段写入正式正文；`inferred` 可以作为“event time 可能由上下文推断出来”的概念性描述，但不应写成最终 XML schema 中的 event attribute。

## 章开头背景：LLM agent、长期对话与 agent memory

Introduction 开头在进入 1.1 之前应先建立背景，写法可以参照 ref1：先讲广泛背景，再逐步缩小到本文研究对象。正文建议用 4 到 6 段完成，不急着给出 NanoMem 的完整方法。

第一段介绍 large language models。说明 LLM 已经从单轮文本生成工具发展为能够参与复杂任务、对话、规划和工具使用的基础模型。这里不需要过度技术化，只要让非 agent memory 方向读者理解：LLM 是当前对话式智能系统的核心组件，但单个 prompt 或固定 context window 并不能自然支持长期交互。

第二段介绍 LLM agents。说明 agent 是围绕 LLM 构建的系统，它可以在多轮交互中使用工具、调用外部资源、规划子任务，并根据环境反馈调整行为。与普通 chatbot 相比，agent 的关键不是只生成一句回答，而是在较长任务过程中维持状态、引用过去信息、完成跨步骤决策。

第三段介绍 agent memory。长期 agent 不能只依赖当前上下文窗口，因为用户的偏好、计划、历史事件、任务状态和纠正信息分散在多个 session 中。Agent memory 的作用是保存和重新访问这些历史，使 agent 在未来交互中保持连续性、个性化和任务一致性。这里可以简短提到现有 memory 系统常见做法：存储 raw conversation、抽取 memory records、建立索引、在 query time 检索相关内容。

在第三段之后插入一张 agent memory 背景图。图的内容是 naive long-context prompting 与 memory-augmented prompting 的对比：上半部分展示把完整 message history 和 current query 直接塞进 prompt，再交给 LLM 生成 response，这会带来 context overflow、token-intensive、high-latency 和 unreliable 等问题；下半部分展示 memory system 先根据 current query 从 message history 中筛选 relevant information，再把更短、更相关的 context 放入 prompt，目标是更 token-efficient、low-latency 和 reliable。正文要把这张图作为“为什么需要 memory system”的背景说明，而不是把它写成 NanoMem 方法图。当前图文件路径：`/mnt/models/youliang/master_thesis/paper/figure/intro_memory.png`。

第四段把背景收窄到 conversational agent memory。本文关注的是多 session 对话场景，而不是一般文档问答或静态知识库检索。对话历史有几个特点：它是按时间发生的；用户经常用相对时间表达；同一事件可能在发生后才被提到；不同 session 之间存在计划、因果、偏好和事件状态的延续。因此，memory 系统不能只看文本相似度，还需要理解历史信息在时间上的关系。

第五段引入 temporal reasoning 的重要性。对话 memory 中的很多问题天然带有时间结构，例如“我上次旅行之后改了什么计划”“我升职那周在读什么书”“那次会议前我答应了谁”。这些问题不只是问某个事实，而是要求系统区分 session_time 和 event_time，找到时间锚点，并把时间锚点转化为新的检索条件。

第六段给出本文定位。NanoMem 研究的是 memory module 如何为 downstream answer model 提供 compact、source-grounded、temporally grounded evidence，而不是让 memory module 直接输出最终答案。这个定位应在背景末尾自然出现：长期 agent memory 的关键挑战不是“记得更多”，而是“在当前 query 下找到并组织真正支持回答的 evidence”。

背景段落不要过早展开 Planner、Retriever、Synthesizer、GRPO 和实验数字。这些内容分别留给 Purpose、Methods 和 Results。Introduction 开头的目标是把读者带到一个清晰场景：长期对话 agent 需要 memory；对话 memory 强依赖时间；时间和多跳依赖让简单检索不够。

## 1.1 Significance of the Study

本小节回答“为什么这个研究重要”。写作重点不是重复 NanoMem 的方法贡献，而是说明 conversational agent memory 已经成为真实系统必须面对的问题；其中 temporal reasoning、multi-hop evidence search 和 compact evidence construction 不是局部工程细节，而是长期对话 agent 能否可靠工作的核心瓶颈。

1.1 的主线建议写成一条递进论证链：

第一，长期对话记忆已经从研究设想变成产业级需求。2024--2026 年间，OpenAI ChatGPT、Google Gemini、Anthropic Claude、Microsoft Copilot、xAI 等头部系统陆续把 memory、personal context 或 past-chat reference 做成产品功能。这个趋势说明 conversational agent 不再只是回答当前 prompt 的无状态模型，而正在转向能够持续理解用户偏好、历史任务、计划变化和个人上下文的长期交互系统。换句话说，研究 conversational agent memory 的重要性首先来自真实应用需求：用户希望 agent 不是每次重新认识自己，而是能在多次交互之间保持连续性。

第二，memory 的产业化并不意味着问题已经解决。长期对话记忆的难点不只是“把过去内容存起来”，而是在未来问题出现时找到真正支持回答的 evidence。公开 benchmark 已经把 temporal reasoning、multi-session reasoning、knowledge update、multi-hop reasoning 和 abstention 列为长期记忆系统的核心能力，例如 LongMemEval 和 LoCoMo 都把时间推理与跨 session 推理作为重要评测维度。Mem0 的公开评测也显示，时间类查询和多跳推理恰好是 memory algorithm 改进最明显、也最需要专门处理的类别。这些材料共同说明：本文 1.2 中提出的 temporal reasoning 和 hidden-dependency multi-hop retrieval 不是作者人为设定的小问题，而是领域公认的困难能力。

第三，现有 memory 系统的主流路线留下了一个清晰空白。许多系统倾向于在 write time 做较重的 memory extraction、summarization、linking 或 graph construction，例如 MemGPT/Letta、Mem0、Zep/Graphiti 等分别从 virtual context management、production memory service 和 temporal knowledge graph 的角度推进 agent memory。它们证明了 memory infrastructure 的价值，但也暴露出一个 tension：如果在入库时过早解释、压缩或图谱化对话，系统必须在未来 query 未知的情况下决定哪些信息重要、哪些时间关系成立、哪些事件应该被固化。对长期个人对话而言，这可能带来成本、延迟、过度解释和 memory structure 被破坏的问题。NanoMem 的意义在于研究另一条路线：保留较轻的 ingestion，把关键的 evidence selection、temporal grounding 和 evidence synthesis 放到 query time 完成。

第四，compact、source-grounded evidence 对真实 agent 部署尤其重要。商业系统已经证明个性化记忆有需求，但长期记忆越深入个人生活、工作和家庭场景，系统就越需要可检查、可追溯、可控制的 memory interface。Apple Intelligence 等产品把 personal context 与端侧处理、隐私保护和 Private Cloud Compute 绑定在一起，也说明未来 personal agent memory 不只是 accuracy 问题，还涉及成本、隐私、可审计性和用户信任。NanoMem 不声称解决完整隐私治理问题，但它把 memory module 的输出限制为 compact、source-grounded、temporally grounded evidence，而不是把大量 raw sessions 直接交给下游模型；这种接口更适合调试、审计和未来本地化或隐私优先的长期 agent memory。

第五，因此，本研究的重要性可以概括为：它把 conversational agent memory 中一个正在变成产业基础设施的问题，具体化为 query-time temporal evidence construction 问题；它把长期记忆评测中公认困难的 temporal 和 multi-hop 能力，转化为可诊断的 evidence search 与 synthesis 过程；它还探索了一种比 raw context injection 更紧凑、比 final-answer-only memory 更可检查的中间接口。Introduction 正文中应把这段写成 motivation，而不是 contribution list。

正式英文正文可以按下面顺序展开：

1. 先用一段说明 conversational memory 的现实重要性：头部公司集中上线 memory/personal context，证明 personalized long-term conversational agents 已经是产业方向。
2. 再用一段说明技术困难：LongMemEval、LoCoMo 和 Mem0 评测共同表明 temporal reasoning 与 multi-hop reasoning 是长期 memory 的核心难点。
3. 再用一段说明系统空白：现有 write-time heavy memory infrastructure 有价值，但 query-time compact source-grounded evidence construction 仍然值得单独研究。
4. 最后一段收束到 NanoMem：本文的重要性在于研究一种 query-time、temporally grounded、source-grounded 的 evidence provider interface，为长期对话 agent 提供更可诊断、更紧凑的 memory access 方式。

**写作提醒，不直接写入 1.1 正文：** 这一节不要写成 OpenAI、Claude、Gemini、Mem0、Zep 的横向 survey。产品时间线只作为开头动机证据；具体系统比较、存储形态差异、Zep/Graphiti 的 temporal KG、Mem0 的 token/benchmark 数字、LiCoMemory、Cognee、Apple Intelligence 等细节应主要放到 Related Work 或 Discussion。1.1 的任务是证明“为什么 conversational agent memory 和 temporal evidence construction 值得研究”，不是提前完成第二章。正式引用建议优先使用：LongMemEval `\cite{wu2024longmemeval}`、LoCoMo `\cite{maharana2024locomo}`、Mem0 `\cite{chhikara2025mem0}`、Zep/Graphiti `\cite{rasmussen2025zep}`、MemGPT/Letta `\cite{packer2023memgpt}`，以及后续补充的 OpenAI/Gemini/Anthropic/Apple 官方产品文档 `@misc`。

## 1.2 Problem Description

本小节负责把背景中的一般问题转化为本文研究的具体问题。写作上应像 ref1 的 `Problem Description` 一样，直接说明当前场景中“困难在哪里”，而不是先宣传本文方法。

核心问题可以定义为：在长期多 session 对话记忆中，回答用户 query 所需的 evidence 往往不能从 query 文本中直接寻址。用户的问题可能只给出一个时间描述、一个事件别名、一个因果结果或一个模糊条件，而真正包含答案的 session 需要先通过其他 evidence 才能定位。本文将这种现象称为 evidence addressability gap。

问题描述应拆成三个层次。正文在这里只需要把问题讲清楚，不展开 NanoMem 的解决方案；方法设计和训练细节留到后续章节。

第一，temporal reasoning 本身困难。这里需要先补充一个背景判断：已有研究表明，即使是很强的 LLM，在处理时间顺序、相对日期、事件持续时间、事件更新和跨文本时间约束时也容易出错。Introduction 正文可以引用 TimeBench、Test of Time、LoCoMo 或其他 temporal reasoning / long-memory benchmark 来支持这一点。这个问题在 conversational memory 中更严重，因为对话 session 有 session_time，即用户何时说出某句话；但一句话描述的事件有 event_time，即事件实际发生或生效的时间。二者经常不一致。例如用户在 April 2 说 “I travelled to Europe last week”，session_time 是 April 2，而 travel event_time 是前一周。如果系统把这两个时间混在一起，后续检索和回答都会建立在错误的时间基础上。

第二，多跳或 hidden-dependency retrieval 困难。很多对话问题不是一步检索能解决的。用户问 “What book was I reading during the week I got promoted?” 时，query 并没有直接给出 book session 的日期。系统需要先找到 promotion 事件，再得到 promotion week，然后用这个时间窗口检索 reading/book 相关 session。第一轮 evidence 不直接回答问题，但它提供了第二轮检索所需的 address。这里的难点不是普通 chain-of-thought，而是 retrieval cue 本身在原始 query 中不存在，必须由前一轮 evidence 暴露出来。

第三，直接把大量 raw retrieved memories 交给下游模型并不可靠。长期对话 memory 检索出的候选 session 往往很多、很长、噪声很高，而且包含多个相近事件、过时信息和无关上下文。如果一次性把这些 raw context 全部输入给 downstream LLM，相当于让模型在大海捞针式的长上下文中同时做 evidence selection、temporal reasoning、multi-hop linking 和 final answer generation。即使使用强模型，这也会带来高成本、长上下文注意力稀释、needle-in-a-haystack 失败和时间关系误判的问题。若多轮检索继续累积未压缩的 raw sessions，context budget 也会迅速膨胀。

本小节应明确：NanoMem 面对的问题不是“LLM 不会算日期”这么窄，也不是普通 RAG 的 top-k recall 问题，而是 temporal-causal evidence search。时间信息不仅影响最终推理，也影响要检索什么；retrieved memories 也不应直接等同于可用 evidence。

**计划图 1.2：Problem Description 图。** 放在 1.2 中段或末尾，是 Introduction 中最重要的问题图。图应展示 evidence addressability gap，而不是展示完整 NanoMem 架构。当前图文件路径：`/mnt/models/youliang/master_thesis/paper/figure/intro_latest.svg`。

图的 caption 应强调：问题的关键是 answer-bearing evidence 的检索 cue 在原始 query 中不存在，需要由先前 evidence 暴露出来；同时，检索到的 raw memories 不能直接等同于可用 evidence。

**写作提醒，不直接写入 1.2 正文：** 上面三个问题分别对应后续方法动机。Temporal reasoning 困难会在 Methods 中引出 temporal normalization、session_time/event_time 分离、temporal hints 和对 Synthesizer temporal grounding 能力的训练；hidden-dependency retrieval 会引出 binary verdict 和 multi-round Planner-Retriever-Synthesizer loop；raw memory 过长过噪会引出 evidence synthesis 和 Temporal Evidence Pool，用 compact source-grounded evidence 替代直接传递所有 retrieved sessions。这些解决方案不要在 Problem Description 中展开，否则会抢 Methods 章节的内容。

## 1.3 Purpose of the Study

本小节回答“本文研究目的是什么”。写作上应从 1.2 的问题自然过渡：既然长期对话 memory 中存在 temporal reasoning、hidden-dependency retrieval 和 raw context 过载的问题，本文的目的就是研究如何在 query time 构造 compact、source-grounded、temporally grounded evidence，而不是在 memory 入库时预先做重度解释。

总目的可以写成：

> The purpose of this study is to investigate how a long-term conversational agent memory system can construct compact and temporally grounded evidence for questions whose supporting information is distributed across multiple sessions and is not directly addressable from the original query.

具体目的建议写成三点。

第一，本文研究 query-time memory evidence construction。NanoMem 的研究重点不是在 ingestion 阶段对历史对话做重度抽取、总结或解释，而是在用户 query 到来之后，根据当前 query 建模问题与 memory 之间的关系。入库阶段只应保留轻量处理、索引和时间辅助信息，避免在未来 query 未知时过度压缩、过度解释或破坏原始 memory 结构。正式正文可以把这一点写成 study boundary：本文关注 search-side / query-time memory agent，而不是 write-time heavy memory rewriting system。

第二，本文研究如何处理长期对话 memory 中的复杂时间推理和多跳 evidence search。Problem Description 中的 temporal reasoning 和 hidden-dependency retrieval 在这里合并成一个研究目的：本文希望解决的问题是，当答案证据分散在多个 session 中、且下一步检索线索需要由前一轮 evidence 暴露时，memory system 如何找到并组织这些 evidence。这里可以强调 temporal-causal evidence search，而不是泛泛地说 long-term memory retrieval。

第三，本文研究如何训练一个适配该框架的 Synthesizer / evidence construction policy。NanoMem 不只是手写一个 retrieval pipeline，还希望通过强化学习训练模型，使其更适合在这个框架中完成 temporally grounded evidence construction、evidence synthesis、compactness control 和 sufficiency judgment。Introduction 中只需要说明这是研究目的之一，不展开 reward 公式、训练轨迹或具体实现细节。

本小节可以在目的之后列出研究问题。建议保留 3 个 RQ，但要让 RQ 对应上述三个目的，而不是沿用旧稿的贡献列表式写法。

RQ1: How can a long-term conversational memory system construct evidence at query time while preserving the original memory structure and avoiding heavy query-agnostic interpretation during ingestion?

RQ2: How can a memory agent recover temporally grounded and multi-hop evidence when the retrieval cue needed for the answer is not directly present in the original query?

RQ3: How can reinforcement learning be used to train the Synthesizer to produce useful, compact, temporally grounded evidence and to judge whether the current evidence is sufficient for downstream answering?

本小节可以简短介绍 NanoMem 是为回答这些问题而构建的研究原型，但不要展开架构细节。可以只写：NanoMem is developed as a query-time memory evidence provider for long-term conversational agents. 详细系统设计放到 Methods。

**写作提醒，不直接写入 1.3 正文：** 上述目的背后对应若干方法细节，但这些细节不应在 Purpose of the Study 中展开。第一点后续会在 Methods 中对应轻量 ingestion、temporal normalization、indexing 和避免 write-time heavy interpretation；第二点会对应 Planner-Retriever-Synthesizer loop、Temporal Evidence Pool 和 binary verdict；第三点会对应 GRPO、reward design、token masking、answer usefulness、compactness 和 sufficiency judgment。Purpose 只写研究要解决什么和研究对象是什么，不写完整解决方案。

## 1.4 Thesis Outline

TODO: 等 Chapter 2 到 Chapter 5 的最终标题和内容稳定后，再回填本小节。当前先留空，不在草稿中展开。

## 本章图表计划

本轮重构后，Introduction 应控制图表数量，避免像会议论文一样在第一章放太多方法图。

| 编号 | 位置 | 类型 | 内容 | 作用 |
|---|---|---|---|---|
| 图 1.1 | 章开头背景 | 背景图 | naive long-context prompting 与 memory-augmented prompting 的对比 | 说明为什么长期对话 agent 需要 memory system，而不能只依赖把完整历史塞进 prompt |
| 图 1.2 | 1.2 Problem Description | 问题图 | 多 session 对话中 session_time/event_time 错位、promotion-to-book 的 hidden retrieval cue、one-shot retrieval 失败路径 | 用一个图解释 evidence addressability gap 是什么 |

暂时不建议在 Introduction 放方法架构图和详细 workflow 图。NanoMem 的完整架构、Temporal Evidence Pool schema、Planner-Retriever-Synthesizer loop 和 GRPO training 图应放到 Methods 章节。Introduction 可以保留一张背景图和一张问题图：背景图解释为什么需要 agent memory，问题图解释为什么普通 memory retrieval 仍然不够。

## 从旧 Introduction 规划稿迁移时需要删除或降级的内容

旧稿中的若干内容应移动或改写：

| 旧内容 | 新处理方式 |
|---|---|
| `1.5 NanoMem 方法概览` 的详细 workflow | 大部分移到 Methods；Introduction 只在 Purpose 中简短说明研究原型 |
| `1.6 贡献总结` | 不单独作为 Introduction 小节；贡献含义融入 Purpose 和 Significance |
| `1.7 范围与限制` | 简化后融入 Purpose；详细 limitation 留给 Discussion |
| 三张 Introduction 图 | 缩减为一张核心 Problem Description 图 |
| `indicative` verdict | 删除，不作为最终系统字段 |
| `inferred` event attribute | 删除为 schema 字段；只保留“event_time may be inferred”这种概念表达 |
| 具体实验提升数字 | 不放 Introduction；留到 Results |

最终写 LaTeX 正文时，第一章结构应为：

```text
Chapter 1 Introduction
  Opening background paragraphs
  1.1 Significance of the Study
  1.2 Problem Description
  1.3 Purpose of the Study
  1.4 Thesis Outline
```

这个结构与 ref1 的第一章一致，同时保留 NanoMem 论文自身的问题线：long-term conversational agent memory -> temporal reasoning -> hidden-dependency retrieval -> evidence provider interface.
