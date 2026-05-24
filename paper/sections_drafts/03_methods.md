# 第三章 Methods 规划稿

本文档是第三章 Methods 的中文规划稿，不是最终 LaTeX 正文。本章的任务是把 NanoMem 的会议论文方法压缩叙述扩展成硕士论文中的完整方法章节：先形式化长期对话 memory 中的 temporal-causal evidence search 问题，再逐层解释系统设计、Temporal Evidence Pool、时间归一化、Planner-Retriever-Synthesizer loop、GRPO 训练、TimeMemEval/ChainMem benchmark 构造，以及实现边界。最终正文应让读者能够从问题定义一路追踪到代码和实验设置，而不是只看到一个高层 pipeline。

本章应承接第一章和第二章的论证。第一章定义 evidence addressability gap，第二章说明相关工作为什么没有完整解决 search-side structured evidence synthesis；第三章需要回答“NanoMem 具体怎样把这个 gap 变成系统和训练目标”。写作时要避免把 NanoMem 描述成 final answer agent。本章的核心定位是：NanoMem 是 memory evidence provider，它的输出是 structured evidence events 和 sufficiency verdict，下游 answer model 只是 evidence consumer。

## 3.1 问题形式化：从 session retrieval 到 evidence-state construction

本小节负责建立全章符号系统。正文应定义 multi-session memory bank：

多会话历史可以表示为 $\mathcal{M}=[(t_1,S_1),\ldots,(t_N,S_N)]$，其中 $S_i$ 是第 $i$ 个历史 session，$t_i$ 是 session timestamp。每个 session 又由 message、turn 或 chunk 等 conversation units 组成。用户给出 query $q$ 后，传统 memory 方法通常把任务看成选出相关 session 并交给 answer model；NanoMem 则把任务重新定义为构造一个 Temporal Evidence Pool $H_T$，使下游 answer model 能仅基于 $(q,H_T)$ 生成答案。

正文需要清楚区分三个时间概念：

第一，session_time，即 session 被记录或交互发生的时间。它是 memory system 最容易获得的 metadata。

第二，event_time，即 evidence event 真实发生或有效的时间区间。它可能与 session_time 相同，也可能因为“last week”“next month”“during my Europe trip”等表达而偏离 session_time。

第三，query_time，即用户提出当前 query 的时间。query 中的相对时间表达需要用 query_time 作为锚点解析，而不是用某个历史 session 的时间。

本小节还要定义 event evidence 的最小 schema。根据当前 NeurIPS draft 与 GRPO parser，正式方法正文应优先采用最终实现的字段：event text、`session_id`、`session_time`、`event_time`，以及二值 `verdict`：`sufficient` 或 `insufficient`。第一章和项目背景中提到的 `inferred` 与三值 `indicative` 可以作为设计演化或历史动机在 Discussion 中解释，Methods 正文不要把它们写成最终系统字段，除非第二阶段重新核对代码后发现最终实现改变。

**计划图 3.1：从 session retrieval 到 Temporal Evidence Pool 的任务重定义。** 放在 3.1 末尾。左侧画传统 retrieval：query 输入后返回 raw sessions；右侧画 NanoMem：query 输入后生成结构化 events，每个 event 显式带 source/session_time/event_time，并由 verdict 判断是否继续。该图的作用是把前两章的概念转成方法章节的正式任务定义。

**计划表 3.1：本章核心符号与字段定义。** 放在 3.1 末尾或 3.2 开头。列为符号/字段、含义、来源、在系统中的作用。应包括 $\mathcal{M}$、$S_i$、$t_i$、$q$、$H_t$、event text、session_id、session_time、event_time、verdict。该表帮助硕士论文读者在后续公式和流程图中保持一致。

## 3.2 系统总览：NanoMem 作为 memory evidence provider

本小节给出 NanoMem 的整体架构，但不要马上进入训练公式。正文应把系统分成两个阶段：

第一，ingest/search preparation 阶段。系统对历史 sessions 做轻量 temporal normalization，把可规则解析的相对时间表达锚定到 session timestamp，并把带时间标注的文本写入可检索的 memory database。这个阶段的目标是降低后续模型推理压力，而不是提前抽取所有未来 query 可能需要的 facts。

第二，query-time evidence construction 阶段。用户 query 到来后，系统对 query 中的相对时间表达做同类解析，生成 temporal hints；Planner 产生 retrieval cues；Retriever 做候选 session 召回；Synthesizer 读取 query、temporal hints、retrieved sessions 和当前 evidence state，输出 reasoning、events 和 verdict。如果 verdict 为 `insufficient`，系统进入下一轮；如果为 `sufficient`，最终 events 被交给 downstream answer model。

这里要强调职责分离：Planner 负责检索 cue generation，Retriever 负责候选召回，Synthesizer 负责 event extraction、event_time reasoning 和 sufficiency judgment，answerer 不参与 memory module 的定义。Methods 正文应避免把 answer correctness 直接说成 NanoMem 输出；answer correctness 是评估 evidence usefulness 的外部信号。

**计划图 3.2：NanoMem 系统架构图。** 放在 3.2 中段。图应比 Introduction 的方法概览更细：包含 temporal normalization、memory database、Planner、Retriever、Synthesizer、Temporal Evidence Pool、verdict loop、downstream answerer。可参考 NeurIPS `arch_v3` 图，但 thesis 版应更适合整页阅读，明确区分 frozen components 与 trainable Synthesizer。该图是 Methods 章的主架构图。

## 3.3 Temporal Evidence Pool：结构化证据状态

本小节展开 $H_t$。正文应说明 Temporal Evidence Pool 不是简单的 retrieved context cache，而是跨轮次保留的 evidence state。每条 event record 至少包含：

一是 evidence text，用自然语言简洁描述与 query 相关的事实或事件。

二是 source/session identifier，用于追踪 event 来自哪个 session。每条 event 应只引用一个 source session，避免把跨 session 推断伪装成单条原文证据。

三是 session_time，记录该 source session 的时间。

四是 event_time，记录 event 真实发生或有效的时间，可以等于 session_time，也可以是从相对表达或上下文推理出的绝对时间区间。

正文应解释为什么 event_time 与 session_time 的分离是本方法的关键：用户在 4 月 2 日说“上周去了欧洲”时，session_time 是 4 月 2 日，但 travel event_time 是前一周。若系统只按 session_time 排序或过滤，会把 mention time 当成 happened time；若系统只做自然语言 summary，又可能丢掉 source 和时间锚点。

这一小节还要解释 pool 的两种功能：对外，它是下游 answer model 的 evidence input；对内，它是 search loop 的工作状态。尤其重要的是，Synthesizer 推理出的 event_time 可以成为下一轮检索的 temporal cue，从而让第一轮发现的 temporal anchor 驱动第二轮搜索 answer-bearing evidence。

**计划图 3.3：Temporal Evidence Pool record schema。** 放在 3.3 中段。图中展示一个 query、两条来源 session、两条 event record，以及字段间关系。应突出 session_time/event_time 分离、source grounding、verdict 与 pool 更新。该图不需要复杂流程，重点是让读者看懂结构化 evidence 的内容。

**TODO:** 第二阶段写 LaTeX 前再次核对最终代码和论文源是否完全移除了 `inferred` 字段。如果保留历史设计讨论，应放在 Discussion 或 appendix，不应混入最终 schema 定义。

## 3.4 Temporal normalization 与 temporal hints

本小节解释系统如何处理规则可解的时间表达。正文应先说明设计原则：能用确定性规则处理的时间解析尽早处理，必须依赖语义理解和跨 session 推理的部分才交给 Synthesizer。这样做可以减少 LLM 在低层日期算术上的错误，也让 BM25/dense retrieval 更容易找到时间相关 session。

Ingest 阶段的写法应包括：

系统扫描 session text 中的相对时间表达，例如 `yesterday`、`last week`、`next month`、星期/月名和若干 “N days ago” 类表达；以该 session 的 timestamp 为 reference time，解析为绝对日期或时间区间；再把解析结果插入文本，例如 “last week” 后追加绝对区间。这个处理让 session 文本在入库时同时保留原始表达和可匹配的绝对时间。

Query 阶段的写法应包括：

系统只从原始 query 中抽取 temporal hints，而不是从 Planner 生成的 cues 中再解析时间。理由是原始 query 是用户直接输入，噪声更少；Planner cue 是模型生成物，再从 cue 中抽取时间会把 query rewriting 错误传播到时间解析。每个 hint 应保留原始 phrase 与解析出的 absolute span，这样 Synthesizer 可以知道 query 中哪个表达对应哪个时间范围。

还要说明不使用 hard temporal filtering 的理由。由于 event_time 和 session_time 可能不同，按 session_time 做硬过滤会丢掉在错误时间被提及的目标 evidence。NanoMem 更倾向于把时间作为 retrieval enhancement 和 evidence reasoning hint：它可以增强 BM25 的字面匹配，也可以提示 Synthesizer 当前 query 的时间目标，但不把非匹配 session 直接排除。

**计划图 3.4：时间归一化与 hints 生成流程。** 放在 3.4 末尾。图分三行：session text + session_time 经过 normalization 变成带绝对时间标注的 indexed text；query + query_time 变成 temporal hints；Synthesizer 输出 event_time 后可把新的 temporal hint 放入下一轮。该图的作用是展示确定性规则和模型推理之间的边界。

**计划表 3.2：时间处理设计选择。** 放在 3.4 末尾。列为设计问题、采用方案、原因、风险。条目包括：从原始 query 抽取 hints、不从 cues 抽取；使用 phrase+span pairing；不用 hard session-time filtering；event_time 允许不同于 session_time；相对时间解析失败时保留原文并标记不确定。该表体现 thesis 相比会议论文更深入的设计 rationale。

## 3.5 Planner-Retriever-Synthesizer loop

本小节是系统方法的核心。正文应按一轮 loop 的实际顺序描述：

第一，Planner 接收原始 query；在后续轮次还接收 previous cues 和上一轮 Synthesizer reasoning；输出若干 retrieval cues。Planner 的目标是 query rewriting 和 search decomposition，而不是回答问题或判断证据充分性。

第二，Retriever 对每个 cue 召回候选 sessions。根据源码与历史 notes，候选方法应描述为 dense embedding similarity 与 BM25 的 hybrid retrieval，多个 cue 的结果合并去重，再按 session timestamp 或系统需要的顺序整理。具体 dense/BM25 权重、top-k、reranker 开关等数字必须在第二阶段从最终 config 或实验脚本核对后再写入正文。

第三，Synthesizer 接收 query、temporal hints、候选 sessions 和当前 evidence state，输出 XML 形式的 reasoning、events 和 verdict。这里要写清楚 output schema：`<reasoning>` 解释当前证据状态和缺口；`<events>` 包含若干 `<event session_id="..." session_time="..." event_time="...">...</event>`；`<verdict>` 是 `sufficient` 或 `insufficient`。如果输出 malformed XML，训练时由 format reward/penalty 处理，评估时则记为系统失败或低质量输出。

第四，verdict 控制 loop。如果 `sufficient`，当前 final events 被送给 answer model；如果 `insufficient`，Synthesizer 的 reasoning 和 previous cues 反馈给 Planner 产生新 cues。需要强调：loop 的目的不是让模型不断思考，而是让上一轮 evidence 暴露新的检索 cue，尤其是 event_time、entity 或 causal predecessor。

正文可以使用“我升职那周读什么书”的例子贯穿本小节：第一轮检索 promotion session，Synthesizer 推断 promotion event_time 并判断还缺 book evidence；第二轮用这个时间窗口和 reasoning 触发 book-related retrieval；最终输出 answer-bearing events。

**计划图 3.5：Planner-Retriever-Synthesizer 单轮与多轮状态转移。** 放在 3.5 中段。图中应有 round 1 和 round 2，展示 cues、retrieved sessions、Synthesizer output、verdict、Temporal Evidence Pool 更新。该图与 3.2 的架构图不同：3.2 是组件图，3.5 是动态 loop 图。

**计划表 3.3：Synthesizer XML 输出字段与约束。** 放在 3.5 末尾。列为 XML 部分、必需字段、含义、错误风险、训练/评估处理。表中包括 reasoning、event attributes、event text、verdict。该表对读者理解 format reward 和后续 implementation details 有帮助。

## 3.6 训练目标：只训练 Synthesizer 的 GRPO

本小节解释为什么训练对象是 Synthesizer。正文应说明 Planner、Retriever、answerer、judge 和 reference policy 在 GRPO 训练中冻结；只有 Synthesizer/Compressor policy 的输出 token 参与梯度更新。理由是 Planner 更接近标准 query rewriting，而 Synthesizer 承担 event extraction、event_time reasoning 和 sufficiency judgment；若同时训练 Planner 和 Synthesizer，answer failure 的 credit assignment 会变得不清楚。

训练流程应写成完整 trajectory：

对每个 training query，从同一 query 采样一组 rollout trajectories。每条 trajectory 包含多轮 Planner cue generation、online retrieval、Synthesizer XML generation、verdict-based stopping 和 terminal answer evaluation。每个 rollout 最多运行有限轮数；若 verdict 为 `sufficient`、无新 evidence、XML 无效、上下文预算超限或达到最大轮次，则终止。最终 reward 用于计算 group-relative advantage，并通过 GRPO 更新 Synthesizer。

正文中需要明确 masking：Planner output、retrieved sessions、environment text、cue XML 等不属于 trainable policy action，policy loss 只覆盖 Synthesizer 生成的 XML tokens。这个细节很适合硕士论文，因为它解释了系统环境和可训练模型之间的边界。

**计划图 3.6：GRPO 训练 rollout 与 token masking。** 放在 3.6 中段。图中展示一个 query 生成 $G$ 条 trajectories，每条包含多轮 search；只有 Synthesizer XML token 被 mask 为 trainable，其余环境文本为 non-trainable。该图帮助读者理解为什么 NanoMem 的 RL 训练不是普通 single-turn instruction tuning。

## 3.7 Reward design：格式、verdict、outcome 与 compactness

本小节展开 reward。正文应比 NeurIPS 正文更详细，说明每个 reward component 的必要性、触发条件和失败模式。

第一，format reward/penalty。Synthesizer 必须输出可解析 XML，且每个 event 包含 required fields。格式无效时其他 reward 无法可靠计算，因此 format validity 应作为 gate 或强 penalty。正文应说明这不是为了追求 XML 本身，而是为了保证 evidence event 可被程序解析、可追踪、可评估。

第二，verdict reward。它监督 stop/continue decision。正确标准不应只看 Synthesizer 引用了哪些 events，而应看 retrieval system 到当前轮为止是否已经覆盖 gold evidence sessions。若 gold evidence 已经被检索到，正确 verdict 应为 `sufficient`；若尚未覆盖，正确 verdict 应为 `insufficient`。这个设计防止 Synthesizer 故意忽略已检索到的 gold session 然后继续搜索。

第三，outcome reward。terminal evidence 被交给 frozen answer model，answer 再由 judge 与 gold answer 比较。这个 signal 连接 evidence construction 与最终任务效用，但正文要强调 outcome reward 评估的是 evidence usefulness，不意味着 NanoMem 本身输出 final answer。

第四，length/compactness reward。它鼓励证据简洁，但应在 outcome 正确或主要质量条件满足后才有意义。否则模型可能通过输出极短无用 evidence 获得长度收益。正文应解释 compactness 是 memory evidence provider 的目标之一：下游 answer model 不应被大量噪声 session 淹没。

第五，为什么不单独设计 event-time reward 或 faithfulness reward。根据当前 appendix 与历史 notes，最终论文倾向于把 event-time 错误通过后续 retrieval drift 和 outcome failure 间接惩罚；faithfulness 可能作为 diagnostic 或早期组件存在，但最终 reward v2 是否保留需要核对训练实现。正式正文应谨慎：可以说明“本设计优先使用 format/verdict/outcome/length 四类信号”，并把实现仍在变化的 faithfulness classifier 写成 **TODO:** 或 appendix note，避免把未确认实现写死。

**计划图 3.7：Reward signals 在 trajectory 中的作用位置。** 放在 3.7 中段。图中在每轮 Synthesizer 输出处标出 format 和 verdict，在 terminal answer 处标出 outcome，在输出长度统计处标出 compactness。该图与 3.6 互补：3.6 讲训练流程，3.7 讲 reward 信号在哪里进入。

**计划表 3.4：Reward component 设计理由。** 放在 3.7 末尾。列为 component、衡量对象、计算时机、主要防止的 failure、可能风险。表中要明确 verdict reward 是 process supervision，outcome reward 是 terminal utility，length reward 不能无条件鼓励短输出。

**TODO:** 第二阶段写正文前核对 `training/grpo/trainer/rewards.py`、appendix algorithm 和最终实验 config 是否已经完全统一。当前 notes 中 reward v2 和部分代码片段对 faithfulness/verdict 的处理存在演化痕迹，最终 LaTeX 不能同时声称互相冲突的 reward 版本。

## 3.8 TimeMemEval/ChainMem benchmark construction

本小节解释诊断 benchmark 的构造。Related Work 已经说明 LoCoMo 与 LongMemEval 不一定密集覆盖 hidden-dependency evidence search；Methods 要说明 TimeMemEval/ChainMem 如何专门构造 temporal bridge cases。

正文应定义 benchmark 的基本 invariant：一个有效样本必须包含至少一个原始 query 不能直接给出的 search cue；该 cue 必须从早期 retrieved evidence 中发现。典型结构为 source event、bridge temporal window 和 destination event。query 能定位 source event，但最终答案在 destination event 中；系统必须先恢复 source event_time，计算目标时间窗口，再检索 destination event。

构造流程可以写成 event-graph-first：

第一，采样 persona/theme 和 source event。

第二，采样 bridge scope 与 offset，计算目标窗口。

第三，在目标窗口内生成 destination event 和 answer。

第四，生成 hard distractors，例如同活动、近时间窗口、answer alias、source-anchor alias 等，使 surface matching 不足以解题。

第五，将 events realized 成 multi-turn sessions，并使用 relative、calendar-based 或 indirect temporal phrasing。

第六，通过 automatic checks 过滤 generation validity、temporal consistency、split leakage 和 answer uniqueness。

正文应说明 benchmark 的边界：它是 temporal-bridge retrieval stress test，不声称覆盖所有时间推理、长期因果链、belief revision 或矛盾 memory。这个限制应放在 Methods 中，后续 Discussion 再展开。

**计划图 3.8：TimeMemEval/ChainMem 样本构造流程。** 放在 3.8 中段。图从 source event 开始，经 bridge window 到 destination event，并在旁边显示 distractors 和 session realization。该图帮助读者理解为什么这个 benchmark 专门测试 hidden-dependency temporal search。

**计划表 3.5：Benchmark 构造变量与过滤条件。** 放在 3.8 末尾。列为变量/检查、取值或含义、为什么重要。包括 bridge scope、offset、terminal type、distractor mode、surface temporal style、temporal validation、answer uniqueness、split leakage。该表为 Results 中的 stratified analysis 做铺垫。

## 3.9 实现细节与可复现边界

本小节把方法落到代码组织和实验管线，但不要把所有脚本列表塞进正文。正文应概述：

NanoMem 核心代码位于 `src/nanomem`，其中 `time_utils.py` 提供相对时间解析与文本改写；storage/vector store 模块负责 memory database；operators 与 query/compressor 相关模块负责 read path、cue parsing 和 evidence compression；server/service 模块提供服务封装。

训练代码位于 `training/grpo`，包括 prompts、schemas、rollout、rewards、integration 和 dataset sampling。正文可以解释 schema parser 用于验证 Synthesizer XML，rollout 负责在线调用 Planner、retriever 和 Synthesizer，reward pipeline 负责打分，verl/GRPO glue 负责策略更新。

评估代码位于 `evals`，其中 LoCoMo、LongMemEval、ChainMem/TimeMemEval 各有 dataset 和 runner。Methods 只需说明这些模块如何对应实验设计；具体结果、baseline 数字和表格留给第四章。

本小节还要列出不能在正文中未核实就写死的实现细节：dense/BM25 权重、per-cue top-k、reranker 是否关闭、answer model 版本、judge model 版本、training group size、max rounds、具体数据 split 数字、final checkpoint selection。若第二阶段无法确认，应以 `TODO:` 留在 LaTeX 对应位置。

**计划表 3.6：代码模块到方法组件的映射。** 放在 3.9 中段。列为方法组件、主要代码位置、输入、输出、第二阶段需核对事项。该表可以帮助答辩或审阅者把论文方法与实际 artifact 联系起来。

## 3.10 小结：方法章节与实验章节的接口

本章最后一小节不再引入新方法，而是总结 NanoMem 如何回答研究问题：

第一，Temporal Evidence Pool 将 raw sessions 转化为 source-grounded event evidence，回答 RQ1。

第二，Planner-Retriever-Synthesizer loop 让上一轮 evidence 暴露的 time/entity/causal cue 驱动下一轮检索，回答 RQ2。

第三，GRPO reward 把 evidence usefulness、verdict correctness、format validity 和 compactness 与训练目标对齐，为第四章的评估指标和消融实验建立基础。

最后一句应自然过渡到 Results：第四章将检验这些设计是否在 LoCoMo、LongMemEval 和 TimeMemEval/ChainMem 上提高 answer quality、evidence compactness、temporal grounding 与 sufficiency behavior。

## 与 NeurIPS 论文相比的扩展要求

会议论文的 Methods 需要在有限篇幅中给出 problem formulation、architecture 和 reward 公式；硕士论文 Methods 应显著扩展以下内容。

一是把问题定义讲慢：从 session retrieval 到 evidence-state construction 的转变要有符号、例子和图，而不是直接进入架构图。

二是把系统职责边界写清楚：NanoMem 输出 evidence events 和 verdict；answer model、judge、retriever、Planner、Synthesizer 的训练状态都要分开解释。

三是增加 design rationale。时间归一化为什么是 deterministic、为什么不从 Planner cues 提取 temporal hints、为什么不用 hard filtering、为什么只训练 Synthesizer、为什么 verdict reward 基于 retrieved sessions，这些都应作为 thesis 的方法贡献解释。

四是补充数据与 benchmark 构造。NeurIPS 正文只能简述 TimeMemEval/ChainMem，硕士论文应展示 source event、bridge window、destination event、distractors 和 validation 的完整流程。

五是加入实现映射和可复现边界。正文应让读者知道哪些 claims 来自 paper source，哪些来自 code/config，哪些还需要第二阶段最终核对。

六是合理处理设计演化。`inferred`、`indicative`、faithfulness reward、SFT warm-up、hard temporal filtering 等都在历史 notes 中出现过，但最终 Methods 必须只描述最终系统；设计演化可放到 Discussion 或 appendix，不能在核心方法里产生冲突。

## 本章计划图表汇总

| 编号 | 位置 | 类型 | 内容 | 作用 |
|---|---|---|---|---|
| 图 3.1 | 3.1 末尾 | 任务定义图 | session retrieval 与 Temporal Evidence Pool construction 的对比 | 把 thesis 的方法目标从“找 session”转成“构造 evidence state” |
| 表 3.1 | 3.1/3.2 | 符号表 | memory bank、session、event、time、verdict 等核心定义 | 统一后续公式和流程图的术语 |
| 图 3.2 | 3.2 中段 | 系统架构图 | temporal normalization、Planner、Retriever、Synthesizer、pool、verdict loop、answerer | Methods 主图，展示 NanoMem 的完整组件边界 |
| 图 3.3 | 3.3 中段 | schema 图 | Temporal Evidence Pool 中 event record 的字段和 source/time 关系 | 解释 structured evidence 为什么可检查、可追踪 |
| 图 3.4 | 3.4 末尾 | 流程图 | session normalization、query temporal hints、跨轮次 hints 回流 | 展示 deterministic temporal processing 与模型推理边界 |
| 表 3.2 | 3.4 末尾 | 设计选择表 | temporal hints、hard filtering、phrase+span pairing 等方案对比 | 解释时间处理策略的 rationale 和风险 |
| 图 3.5 | 3.5 中段 | 动态 loop 图 | 两轮 Planner-Retriever-Synthesizer 状态转移 | 展示 hidden dependency 如何通过 iterative retrieval 被发现 |
| 表 3.3 | 3.5 末尾 | schema 表 | Synthesizer XML 输出字段、约束和错误处理 | 为 format reward、parser 和 evaluation 建立依据 |
| 图 3.6 | 3.6 中段 | 训练流程图 | GRPO group rollout、frozen components、trainable token mask | 说明训练只更新 Synthesizer 且在线检索 |
| 图 3.7 | 3.7 中段 | reward 图 | format、verdict、outcome、compactness 在 trajectory 中的位置 | 解释每个 reward signal 的作用层级 |
| 表 3.4 | 3.7 末尾 | reward 表 | reward component、计算时机、failure mode、风险 | 帮助读者理解 reward 不是只看 final answer |
| 图 3.8 | 3.8 中段 | benchmark 构造图 | source event、bridge window、destination event、distractors、session realization | 展示 TimeMemEval/ChainMem 的 hidden-dependency 构造 |
| 表 3.5 | 3.8 末尾 | benchmark 表 | bridge scope、terminal type、distractor、validation checks | 为 Results 的分层分析做铺垫 |
| 表 3.6 | 3.9 中段 | 实现映射表 | 方法组件到代码模块、输入输出和待核对事项 | 提升可复现性，避免方法描述脱离 artifact |

本章计划 8 张图、6 张表。全论文目标约 15 张图，第一章已计划 3 张图、第二章已计划 2 张图，前三章累计约 13 张图。Methods 是核心技术章节，因此图较多是合理的；第四章 Results 应优先使用结果表和少量主结果/消融/case study 图，第五章 Discussion 可只保留 1 到 2 张 failure taxonomy 或 deployment boundary 图。如果后续总图数过多，优先合并图 3.6 与图 3.7，或把图 3.4 的细节改成表格说明。
