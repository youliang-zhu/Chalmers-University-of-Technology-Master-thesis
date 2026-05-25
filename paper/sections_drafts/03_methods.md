# 第三章 Methods 规划稿

本文档是第三章 Methods 的中文规划稿，不是最终 LaTeX 正文。本章应采用更接近 NanoMem NeurIPS 最终论文的方法写法：重点讲清楚 NanoMem 的问题形式化、系统架构、Temporal Evidence Pool、Planner-Retriever-Synthesizer loop、GRPO 训练、reward design 和 TimeMemEval 构造。实验设置、baseline、metrics、模型版本、具体数据 split 和结果表应放到第四章 `Results` 或 `Experimental Evaluation`，不要混入本章主线。

本章写作要参考 `agents/arch_design_idea.md`。那个文档已经把系统流程、Temporal Evidence Pool 与 temporal hints 的区分、Planner 为什么需要 pool、GRPO rollout、reward 设计，以及“不要主动过滤非理想轨迹”的训练直觉讲清楚了。Methods 正文要把这些内容组织成一个完整、连贯、可审阅的方法故事。

本章核心定位：NanoMem 是一个 query-time memory evidence provider。它不直接回答用户问题，而是构造 compact、source-grounded、temporally grounded 的 Temporal Evidence Pool，并输出二值 sufficiency verdict。最终答案由 downstream answerer 基于这个 evidence pool 生成。

写正式正文时，硕士论文不受 NeurIPS 篇幅限制，因此可以比会议论文更充分地展开必要公式。原则是：能帮助读者理解机制边界、状态更新、训练目标和 reward 层次的公式可以补充；但所有符号定义、reward 形式、verdict schema、Temporal Evidence Pool 更新和 GRPO objective 必须与 NeurIPS 最终版保持一致，不能为了讲解而引入另一套不兼容定义。

建议结构如下：

```text
Chapter 3 Methods
  3.1 Problem Formulation
  3.2 NanoMem Overview
  3.3 Temporal Evidence Representation and Normalization
  3.4 Planner-Retriever-Synthesizer Loop
  3.5 GRPO Training of the Synthesizer
  3.6 Reward Design
  3.7 TimeMemEval Construction
```

## 3.1 Problem Formulation

本节负责建立问题定义和符号系统。正文应先定义 multi-session memory bank：

多会话历史表示为 $\mathcal{M}=[(t_1,S_1),\ldots,(t_N,S_N)]$，其中 $S_i$ 是第 $i$ 个历史 session，$t_i$ 是 session timestamp。每个 session 可以由 message、turn 或 chunk 等 conversation units 组成。给定用户 query $q$，传统 memory 方法通常把任务看成从 $\mathcal{M}$ 中检索相关 sessions；NanoMem 则把任务重新定义为构造一个 Temporal Evidence Pool $H_T$，使下游 answerer 能够基于 $(q,H_T)$ 生成答案。

正文需要强调这个转变：NanoMem 不是 session retriever，也不是 final answer agent，而是 evidence-state constructor。其目标不是“找到一些看起来相关的原始对话”，而是把检索到的对话转化为结构化、可追踪、可用于回答的 evidence events。

本节需要定义三个时间概念：

- `session_time`：session 被记录或发生交互的时间，是 memory system 最容易获得的 metadata。
- `event_time`：evidence event 真实发生或有效的时间区间，可能等于 session_time，也可能因为 “last week”“next month”“during my trip” 等表达而偏离 session_time。
- `query_time`：用户提出当前 query 的时间，用于解析 query 中的相对时间表达。

本节还要定义最终 schema 的边界：event 包含 event text、`session_id`、`session_time`、`event_time`；verdict 只有 `sufficient` 和 `insufficient`。不要在 Methods 正文中把旧设计里的三值 verdict 或 `indicative` 写成当前系统字段。

## 3.2 NanoMem Overview

本节给出系统总览，不进入 reward 公式。正文应把 NanoMem 分成两个阶段。

第一，lightweight ingest / preparation stage。系统对历史 sessions 做轻量时间归一化和索引。这个阶段的职责是保留原始 memory 结构，同时把可规则解析的相对时间表达显式化，降低后续检索和 Synthesizer 推理压力。这里要避免写成 heavy write-time extraction：NanoMem 不试图在入库时提前解释所有未来 query 可能需要的 facts。

第二，query-time evidence construction stage。用户 query 到来后，系统对 query 做同样的时间归一化，Planner 生成 retrieval cues，Retriever 召回 candidate sessions，Synthesizer 读取 normalized query、temporal hints、retrieved sessions 和当前 Temporal Evidence Pool，输出 reasoning、events 和 verdict。如果 verdict 为 `insufficient`，系统进入下一轮；如果为 `sufficient`，最终 Temporal Evidence Pool 交给 downstream answerer。

本节要明确组件职责：

- Planner：生成 retrieval cues，不负责回答问题。
- Retriever：召回 candidate sessions，是 frozen environment component。
- Synthesizer：构造 evidence events、推理 event_time、判断 sufficiency，是唯一训练对象。
- Answerer：消费最终 Temporal Evidence Pool 生成答案，不属于 NanoMem memory module 的输出。
- Judge：训练/评估中用于判断 answer correctness，不参与 evidence construction。

<!-- 计划图：
/mnt/models/youliang/master_thesis/paper/figure/arch_v3_cropped.pdf -->

## 3.3 Temporal Evidence Representation and Normalization

本节合并讲 Temporal Evidence Pool 和 temporal normalization。它们是同一个时间证据表示链条的两部分：normalization 负责让可规则解析的时间显式化，Temporal Evidence Pool 负责把模型构造出的 query-conditioned evidence 结构化和跨轮累计。

### Evidence Record

正文应定义 Temporal Evidence Pool $H_t$。它不是 raw retrieved sessions 的缓存，而是跨轮维护的 structured evidence state。每条 evidence record 至少包含：

- event text：简洁描述与当前 query 相关的事实或事件。
- `session_id`：来源 session，用于 source grounding。每条 event 只引用一个 source session，避免把跨 session 推断伪装成单条原文证据。
- `session_time`：该 source session 的 timestamp。
- `event_time`：事件真实发生或有效的时间，可以等于 session_time，也可以由相对时间表达和上下文推理得到。

正文要解释为什么 `session_time` / `event_time` 分离重要。例如用户在 April 2 说 “I travelled to Europe last week”，session_time 是 April 2，但 travel event_time 是前一周。若系统把 session_time 当作 event_time，就会错误地定位后续检索。

### Temporal Normalization and Hints

正文应说明 NanoMem 使用 deterministic temporal normalization 处理规则可解的时间表达。session text 以 session timestamp 为 anchor；query text 以 query_time 为 anchor。系统保留原始短语，并在文本中追加绝对时间范围，形成 normalized sessions 和 normalized query。

这里需要与 NeurIPS 最终版统一：`temporal hints` 指 deterministic temporal normalization 产生的时间辅助信息，包括 query-side hints 和 session-side parser aids。它们不是 hard filtering 的最终答案，也不是 Temporal Evidence Pool。Temporal hints 帮助 Synthesizer 解析 `event_time`；Temporal Evidence Pool 则来自 Synthesizer 输出，是跨轮累计的 evidence state。

正文还要强调不应把所有时间问题都交给规则。规则只处理 “last week”“yesterday”“next month” 这类可解析表达；复杂的 query-conditioned event interpretation 仍由 Synthesizer 完成。

<!-- 计划表：核心字段定义表。列出 `session_id`、`session_time`、`event_time`、event text、verdict、temporal hints、Temporal Evidence Pool 的含义和来源。 -->

## 3.4 Planner-Retriever-Synthesizer Loop

本节是方法章核心。正文应按一轮 loop 的实际顺序写。

第一，Planner。第一轮中，Planner 基于 normalized query 生成初始 retrieval cues。后续轮次中，Planner 接收 normalized query、previous cues、上一轮 Synthesizer reasoning 和当前 Temporal Evidence Pool。Planner 需要 pool 的原因是它不只要知道“缺什么”，还要知道“已经找到了什么”：已有的 anchor event、event_time、entity、location 或 state 都可能帮助它生成下一轮更有针对性的 retrieval cue，并避免重复搜索已经找到的 source evidence。

第二，Retriever。Retriever 对每个 cue 执行检索，召回 candidate sessions，并合并多 cue 的结果。正式正文中可以说它使用 lexical/dense hybrid retrieval 和 memory DB，但具体 top-k、权重、reranker、模型版本等实验配置应留到第四章或实验设置小节，不要在 Methods 主线中写死。

第三，Synthesizer。Synthesizer 读取 normalized query、temporal hints、retrieved sessions 和当前 Temporal Evidence Pool，输出 XML：`<reasoning>`、`<events>`、`<verdict>`。`<events>` 是 cumulative 的：保留仍然有效的 previous events，再追加当前 retrieved sessions 中新抽取出的 events。verdict 是 `sufficient` 或 `insufficient`。

第四，loop control。如果 verdict 为 `sufficient`，系统停止并把最终 $H_T$ 给 downstream answerer。如果 verdict 为 `insufficient`，当前 reasoning 和 pool 回到 Planner，产生下一轮 cues。loop 终止条件包括 sufficient、no-new-evidence、XML invalid、context budget、max rounds 等；这些终止轨迹仍进入训练和评估，不因为“不理想”而被主动丢弃。

正文可以用“我升职那周读什么书”的例子贯穿本节：第一轮找到 promotion event 并推断 event_time；由于缺少 book evidence，Synthesizer 输出 insufficient；第二轮 Planner 用 promotion week 生成 reading-related cue；最终找到 answer-bearing event。

## 3.5 GRPO Training of the Synthesizer

本节讲训练流程，但不讲实验结果。正文应明确：训练对象只有 Synthesizer/Compressor policy。Planner、preprocessor、retriever、answerer、judge 和 reference policy 都是 frozen environment components；policy loss 只作用在 Synthesizer 生成的 XML tokens 上。

训练 trajectory 应描述为 online multi-turn rollout：

1. 对同一个 training query 采样 $G$ 条 trajectories。
2. 每条 trajectory 从 Planner cue generation 开始，在线调用 Retriever 搜索 memory DB。
3. Synthesizer 输出 reasoning、events、verdict。
4. 如果 insufficient，则进入下一轮；如果 sufficient 或触发 terminal condition，则停止。
5. 终止后，最终 Temporal Evidence Pool 交给 frozen answerer 生成答案，再由 judge 得到 outcome。
6. 每条 trajectory 得到 scalar reward，组内归一化得到 GRPO advantage。
7. 只更新 Synthesizer policy。

本节应解释为什么只训练 Synthesizer：它承担 event extraction、event_time inference、evidence synthesis 和 sufficiency judgment；如果同时训练 Planner 和 Synthesizer，credit assignment 会混乱，answer 错误很难归因。

正文中可以先用一小段简单介绍 GRPO：GRPO 来自 DeepSeekMath / DeepSeek-R1-Zero 这一类 reasoning model 训练范式，图里的 `DeepSeek-R1-Zero` 是原始示意图中的 policy model 名称，在本文中应理解为 NanoMem 的 Synthesizer policy。GRPO 对同一个 query 采样一组 $G$ 条输出/trajectory，reward computation 给每条 trajectory 打分，group computation 将组内 reward 归一化成 advantage，并用 KL 约束当前 policy 不要偏离 frozen reference model。然后再说明 NanoMem 的特殊化：这里的 output 不是普通 single-turn response，而是完整的 multi-round evidence-construction trajectory；reward 也不是通用偏好模型，而是 format、verdict、outcome 和 compactness 组成的任务 reward。

还要加入 `arch_design_idea.md` 里的重要训练直觉：不要把 rollout 数据清洗得过于理想。no-new-evidence、XML invalid、max-round insufficient、检索到近似但不完整 evidence、早停或过度搜索等都是真实环境会出现的情况。如果训练时主动丢弃这些非理想 trajectories，模型只会看到“检索顺利、证据干净、格式正确”的世界，学不会失败检索和证据缺口下的 stop/continue 行为。因此这些 trajectories 应被记录 terminal reason 并进入 reward computation。

<!-- 计划图：GRPO 算法图。参考用户提供的 GRPO 图：query 输入 policy model，采样 $G$ 条 outputs/trajectories，经 reference model 和 reward computation 得到 rewards，再经 group computation 得到 advantages。正文需要说明在 NanoMem 中 outputs 是 multi-round evidence-construction trajectories，只有 Synthesizer XML tokens 被更新，其他环境组件 frozen。 -->

## 3.6 Reward Design

本节按 NeurIPS 最终版和 appendix reward design 写，必须避免旧 reward 版本。最终 reward 包含 format gate、verdict reward、outcome reward 和 length/compactness reward。

### Format Gate

Format 不是逐轮累积惩罚，而是 gate。定义 $f(\tau)\in\{0,1\}$ 表示整条 trajectory 中所有 Synthesizer 输出是否可解析且符合 XML schema。如果 $f(\tau)=0$，其他 reward 不计算，整条 trajectory 得固定惩罚 $c<0$。这个设计保证后续 reward 能可靠读取 events 和 verdict。

### Verdict Reward

Verdict reward 监督 stop/continue decision。它不是根据 Synthesizer 引用了哪些 sessions 判断，而是根据截至当前轮累计 retrieved sessions 是否覆盖 gold evidence sessions 判断。如果 gold evidence 已全部检索到，正确 verdict 是 `sufficient`；如果还没覆盖，正确 verdict 是 `insufficient`。这个设计防止 Synthesizer 故意忽略已检索到的 gold sessions 来延长搜索。

### Outcome Reward

Outcome reward 在 trajectory 终止后计算。最终累计 Temporal Evidence Pool $H_T$ 被送给 frozen answerer，answerer 生成答案，再由 frozen judge 与 gold answer 比较，得到 binary outcome $o(\tau)\in\{0,1\}$。这个 reward 衡量 evidence usefulness，不代表 NanoMem 自己输出 final answer。

### Length / Compactness Reward

Length reward 只在 outcome 正确时激活，用于鼓励正确 trajectories 中更紧凑的 evidence。这样可以避免模型通过输出极短但无用的 evidence 获得奖励。Compactness 是 memory evidence provider 的重要目标，因为下游 answerer 不应该被大量 noisy sessions 淹没。

### Final Formula

正文应给出最终 reward：

```text
if f(tau)=0:
    R(tau)=c
else:
    R(tau)=w_o o(tau) + w_v sum_t v_t + w_l l(tau)
```

并写明最终论文使用的系数：$(w_o,w_v,w_l)=(0.50,0.10,0.05)$，format-failure penalty $c=-0.20$。如果正文篇幅允许，可以简短解释 appendix 的系数分析：outcome correctness 应主导 process quality，verdict quality 应主导 compactness。

还要明确不单独设计 event-time reward。错误 event_time 会通过后续 retrieval drift 和 final answer failure 反映到 outcome reward 中。

## 3.7 TimeMemEval Construction

本节讲 TimeMemEval 作为本文方法/评估设计的一部分。全文统一使用 `TimeMemEval` 这一名称。

正文应说明为什么需要 TimeMemEval：LoCoMo 和 LongMemEval 能评估长期记忆能力，但其中很多问题可以通过一次高召回检索解决，不一定集中测试 hidden-dependency temporal search。TimeMemEval 专门构造“答案证据必须先通过中间 temporal bridge 才能变得可检索”的样本。

每个 TimeMemEval 样本应包含：

- source event：query 可以直接或较容易定位的 anchor event。
- bridge temporal window：由 source event 的 event_time 推导出的目标时间窗口。
- destination event：真正包含答案的 event。
- distractors：同主题、近时间、相似实体或错误时间窗口中的干扰 evidence。

基本解题过程是：先找到 source event，推断它的 event_time 或目标窗口，再用这个 window 检索 destination event，最后构造 sufficient evidence pool。这个设计直接检验 NanoMem 的 iterative evidence synthesis，而不是普通 one-shot retrieval。

正文可以描述构造流程：采样人物/主题，生成 source event，设定 temporal offset，生成 destination event 和 answer，加入 hard distractors，把 events realization 成 multi-session dialogues，再通过 automatic checks 过滤 temporal consistency、answer uniqueness、split leakage 和 generation validity。

本节要说明 TimeMemEval 的边界：它是 temporal bridge retrieval stress test，不声称覆盖所有现实 memory failure，例如长期 belief revision、矛盾信息、隐私约束或开放式多目标任务。这些限制可在 Discussion 中展开。

## 与 NeurIPS 论文相比的扩展要求

硕士论文 Methods 应比 NeurIPS 正文更展开，但不要把第四章实验内容提前塞进来。

需要扩展：

- 问题定义要更慢地讲清楚：为什么 session retrieval 不够，为什么要 evidence-state construction。
- 能公式化的核心机制要适度公式化，包括 memory bank、Temporal Evidence Pool、normalization、Planner cue generation、Retriever output、Synthesizer policy、pool update、GRPO advantage/objective、format gate、verdict reward、outcome reward、length reward 和 total reward。
- Temporal Evidence Pool 的字段和作用要更明确，尤其是 source grounding 和 session_time/event_time 分离。
- Planner 为什么需要读取 Temporal Evidence Pool 要讲清楚：它需要知道已经找到什么，才能生成下一轮更好的 cues。
- GRPO 训练要解释 frozen components、token masking、online rollout 和异常 trajectories 为什么不丢弃。
- Reward design 要按最终版写清楚 format gate、verdict、outcome、length 的层次关系。
- TimeMemEval 构造要比会议论文更详细，因为它是 thesis 中解释 hidden-dependency temporal search 的关键诊断 benchmark。

不应该放在 Methods 主体：

- 主结果数字。
- baseline 对比表。
- LoCoMo/LongMemEval/TimeMemEval 的最终 split 数字。
- model version、top-k、BM25/dense 权重、judge prompt 等实验配置细节。
- error analysis 和 case study 结果。

这些内容放到第四章 `Results` / `Experimental Evaluation` 更清楚。
