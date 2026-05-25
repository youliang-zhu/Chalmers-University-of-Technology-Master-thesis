
第一部分：系统完整流程

Ingest 侧（数据入库）
输入是多轮对话 session，每个 session 带有一个 session timestamp（入库时间）。
第一步，时间预处理：扫描 session 里每一句话中的相对时间表达（如 "last week"、"yesterday"、"next month"），用 regex 规则提取这些短语，结合该 session 的 timestamp 计算出绝对时间，然后把绝对时间直接插入到原文中该短语的后面。比如原文是 "last week I went to Paris"，处理后变成 "last week (2023-04-07 to 2023-04-13) I went to Paris"。这一步是确定性的规则处理，不涉及任何模型推理。
第二步，对处理后的 session 文本做 semantic chunking，切成若干语义连贯的小块。
第三步，对每个 chunk 做 embedding，连同原始文本一起存入向量数据库（SQLite）。
至此，数据库中每个 session 的文本已经自带绝对时间标注，后续 synthesizer 读到这些 session 时可以直接看到绝对时间，不需要自己从相对时间表达去推算。

Search 侧（搜索）
Step 1：Query 时间解析
用户提出原始 query，附带一个 query time（提问时间戳）。系统对原始 query 中的时间表达用同一套确定性规则进行提取和绝对时间计算，以 query time 为锚点。比如 query 是 "Did I go to the supermarket yesterday?"，query time 是 2023-04-21，则系统可以解析出 "yesterday" 对应 2023-04-20。这个解析结果有两个作用：第一，生成时间标注版 query，用于后续 BM25 检索增强；第二，作为 query-side temporal hints 输入给 synthesizer，帮助它理解用户问题里的相对时间表达。这里的 temporal hints 不是硬过滤条件，而是 deterministic parser aids。

Step 1.5：Query 文本时间标注（用于检索增强）
在 Step 1 完成 query 时间解析后，系统对 query 文本本身做时间标注：将解析出的绝对时间插入到 query 原文中对应的相对时间短语后面，生成一个时间标注版的 query，即最终论文中的 normalized query $\widetilde{q}=\mathrm{Norm}(q,t_q)$。比如原始 query 是 "Did I go to Paris last week?"，处理后变成 "Did I go to Paris last week (2023-04-14 to 2023-04-20)?"。这个标注后的 query 文本会被用于后续 Step 2 的 Planner 和 Step 3 的检索。由于 ingest 阶段已经对 session 文本做了同样的处理，当 session 中某个事件的绝对时间与 query 中的绝对时间完全重合时，BM25 会产生强烈的词汇匹配信号。这实质上是把一个时间推理问题转化成了词汇匹配问题，尤其能解决跨时间引用的场景——比如 session 里说的是 "next week I'm going to Paris"（ingest 时被解析成某个绝对时间），而 query 问的是 "two weeks ago"（解析成同一个绝对时间），语义上两者完全不匹配，但通过绝对时间戳的字面重合，BM25 可以把这条 session 捞出来。这一步本质是增强正确 session 被搜索到的几率，并为 synthesizer 提供 query-side temporal hints。

Step 2：Planner 改写
Planner（LLM）接收 normalized query，将其改写拆分为若干个 cue（检索子查询）。第一轮时，Planner 主要根据 normalized query 生成初始 cues；后续轮次中，Planner 接收 normalized query、历史 cues、上一轮 synthesizer reasoning，以及当前 Temporal Evidence Pool，用这些结构化 evidence state 和缺口说明生成下一轮 cues。Planner 的职责是生成适合检索的查询文本，不对 cue 自己做时间提取或时间标注；cue 里的时间处理由确定性 preprocessing 完成。
Step 3：并行检索
每个 cue 独立并行检索。对每个 cue，系统在数据库中做 embedding 相似度搜索和 BM25 关键词匹配的混合打分（大致权重为 0.75 dense + 0.25 BM25），按分数取 top-k session。不做任何基于时间的硬过滤。
多个 cue 检索到的 session 合并去重，按 session timestamp 升序排列。
Step 4：Synthesizer
Synthesizer（LLM，可以是 vanilla 或 GRPO 训练后的模型）接收三个输入：
第一，normalized query。
第二，累计检索到的 session 列表（这些 session 的文本已经在 ingest 阶段被插入了绝对时间标注）。
第三，Temporal Evidence Pool $H_t$，也就是历史轮次已经抽取出的结构化 evidence events。
第四，temporal hints，也就是 query 和 retrieved sessions 经过 deterministic temporal normalization 后得到的时间辅助信息。每条 temporal hint 包含原始时间短语和绝对时间范围，作为 synthesizer 解析 event_time 的辅助输入。需要注意：temporal hints 和 Temporal Evidence Pool 是两个不同概念。temporal hints 来自确定性时间解析；Temporal Evidence Pool 来自 synthesizer 的 evidence 输出。
Synthesizer 的输出包含三个部分：
Reasoning：推理过程，说明当前证据为什么充分或不充分，缺什么。
Events：一系列结构化的 evidence event，每个 event 包含：event text（自然语言描述的事实陈述）、session_id（来源 session，每个 event 只对应一个 session）、session_time（该 session 的入库时间）、event_time（synthesizer 推理得出的该事件真实发生的绝对时间，如果 session 里没有相对时间指代则等于 session_time，如果有则需要根据 session_time 和相对表达推算）。
Verdict：二值判断——sufficient（证据充分，终止 loop）、insufficient（证据不足，触发下一轮检索）。
概念上，每轮 synthesizer 新生成的 events 会被加入 Temporal Evidence Pool，即 $H_{t+1}=H_t\cup\{h(e)\mid e\in\mathcal{E}_t\}$。实现 prompt 中的 `<events>` 输出可以是 cumulative 的：先保留仍然有效的 previous events，再追加当前 retrieved sessions 中新抽取出的 events。
Step 5：Loop 或终止
如果 verdict 是 sufficient，流程终止。最终累计的 Temporal Evidence Pool 被送给下游 answer model（最终论文中使用 frozen Qwen3.5-9B answerer），由它根据 query 和这些结构化 evidence 生成最终答案。Synthesizer 本身不负责回答问题。
如果 verdict 是 insufficient，normalized query、历史 cues、synthesizer reasoning，以及更新后的 Temporal Evidence Pool 被送回 planner。Planner 根据 reasoning 中指出的缺失信息，并结合已经构造出的 evidence state，生成新的 cue。然后回到 Step 3 重新检索，进入下一轮。
循环终止条件：verdict 为 sufficient、没有新 session 被检索到、上下文预算耗尽、或达到最大轮次上限。


第二部分：解决的问题
这个系统解决的核心问题是长期对话记忆中的复杂时间推理。
具体来说，当用户向一个 memory 系统提问时，问题中涉及的事件发生时间往往和该事件被记录在 session 中的时间不同。用户说 "上周我去了北京"，这个事件被记录在今天的 session 里，但事件本身发生在上周。现有的 memory 系统要么完全忽略时间信息只靠语义检索，要么把 session time 当作事件时间来用（比如 Memory-T1 用 session time 做硬过滤，导致真正发生的event被过滤掉），两种做法在时间推理场景下都会出错。
这个系统通过 event time 建模来解决这个问题。它在整个 pipeline 中建立了一条完整的时间处理链条：ingest 阶段把 session 文本里的相对时间转成绝对时间嵌入文本，降低后续模型的推理压力；search 阶段把原始 query 中可规则解析的时间表达写回 query 文本，形成 normalized query 和 query-side temporal hints，用于检索增强和 synthesizer 的 event_time 解析；synthesizer 对每个检索到的 evidence event 显式推理其 event_time，输出带有时间标注的结构化证据，并把这些 events 累积进 Temporal Evidence Pool。
对于更困难的 case——时间推理和多跳推理交织的场景——系统通过 verdict 驱动的 loop 机制来处理。典型的例子是 "What book was I reading during the week I got promoted?"：第一轮需要找到 promotion 事件并推理出它的 event_time，第二轮才能用这个时间去搜索对应时间段的读书记录。这里 loop 的触发原因本身就是第一轮时间推理的结果，temporal reasoning 和 multi-hop retrieval 不是两个独立的问题，而是一个因果链——时间推理的输出驱动了下一跳的检索。




机制讨论总结与设计要点

一、Query 和 session 的时间解析共同形成 temporal hints
最终论文中，temporal hints 指的是 deterministic temporal normalization 产生的时间辅助信息。系统会对 session 文本和 query 文本都做相对时间解析，并把绝对时间写回文本。query 是用户直接说出来的，确实是最干净、最确定的时间信号源，因此 query-side temporal hints 会进入 synthesizer，帮助它把用户问题里的相对时间表达映射到绝对时间范围。与此同时，这些解析结果也服务 BM25 检索增强。Temporal hints 不做硬过滤，只是 parser aids。

二、Temporal hints 与 Temporal Evidence Pool 是两个不同概念
Temporal hints 来自确定性时间解析，通常包含原始时间短语和绝对时间范围，用于辅助 synthesizer 解析 `event_time`。Temporal Evidence Pool 来自 synthesizer 输出，是跨轮累计的结构化 evidence state。每条 evidence event 至少包含 event text、event_time、session_time 和 session_id。下一轮中，Planner 和 Synthesizer 都可以读取 Temporal Evidence Pool：Planner 用它避免重复搜索并生成更有针对性的 cues；Synthesizer 用它做 sufficiency 判断、去重和继续追加 evidence。

三、跨轮次累积的是 Temporal Evidence Pool
第一轮时 Temporal Evidence Pool 为空；当 synthesizer 输出第一轮 events 后，这些 events 会进入 $H_1$。后续每一轮也是同样机制：新 events 会被追加到 pool 中，形成 $H_{t+1}$。这个 pool 可以做去重和预算控制，但不按 event_time 与 session_time 的差异筛选。第一轮输出可能包含时间窗口，也可能包含人物、地点、活动、任务状态或因果线索；这些信息都可能成为下一轮检索和判断证据充分性的桥梁。
因此，最终论文的核心不是“temporal hints 池累积”，而是“Temporal Evidence Pool 累积”。Temporal hints 辅助时间解析，Temporal Evidence Pool 承担跨轮 search state。

四、不再用 event_time ≠ session_time 筛选进入 pool 的 events
旧设计中曾考虑用 event_time 是否显著偏离 session_time 来判断哪些 events 应该回流。最终论文采用更统一的 Temporal Evidence Pool 更新规则：synthesizer 输出的 evidence events 都可以进入 pool。原因是 event_time 与 session_time 相等并不代表这个 event 对后续轮次没有价值。它仍然可能包含下一跳需要的实体、活动、地点、状态更新、用户偏好或因果关系。相反，如果只保留 event_time 与 session_time 不一致的 events，就会把很多非时间偏移但检索上有用的 bridge evidence 丢掉。

五、训练闭环：event_time 推理错误会被 RL 自然惩罚
这是这个系统设计在训练层面的闭环。由于 synthesizer 输出的 events 会进入 Temporal Evidence Pool，错误的 event_time、错误的 event text、错误的 source attribution 或错误的事件选择都会影响后续轮次的 planning、retrieval 和最终 evidence state。如果这些错误导致最后 answer model 给出错误答案，outcome reward 为零，GRPO 会惩罚产生这些误导性 events 的 synthesizer policy。也就是说，event_time 的推理质量和 evidence construction 的整体质量都可以通过 outcome reward 的反向传导被覆盖。最终论文因此不单独设计 event-time reward。

六、从 ingest 到 search 的时间处理形成统一的设计哲学
回顾整个系统，时间处理在三个阶段出现，每个阶段的职责清晰且不重叠：
Ingest 阶段：用确定性规则（regex + session timestamp）把 session 文本里的相对时间转绝对时间，嵌入文本。目的是降低下游模型的推理压力，让 synthesizer 看到的 session 自带绝对时间。
Query 解析阶段：用同一套确定性规则（regex + query time）把 query 里的相对时间转绝对时间，并写回 query 文本。目的是增强 BM25 检索召回，同时形成 query-side temporal hints，辅助 synthesizer 解析用户问题中的相对时间。
Synthesizer 阶段：模型结合 normalized query、temporal hints、检索到的 session 文本、以及历史轮次累积的 Temporal Evidence Pool，推理出每个 evidence event 的真实 event_time。这个推理结果既是当前轮次的输出，也会作为下一轮的 Temporal Evidence Pool 状态。
这三个阶段形成一个层次递进的结构：确定性规则能处理的尽早处理（ingest 和 query annotation），用于提高检索召回并生成 temporal hints；必须结合 query 与 evidence 才能判断的部分留给模型（synthesizer）；而模型推理出的结构化 evidence 会回流成下一轮的 Temporal Evidence Pool。整个设计的哲学是让规则处理服务检索和时间解析，让 synthesizer 负责 evidence state construction。


# GRPO 训练：算法流程与实现细节

训练对象
只训练 Synthesizer/Compressor policy。Planner、preprocessor、retriever、answerer、judge 和 reference policy 都是 frozen environment components，不参与 GRPO 训练；训练 loss 只作用在 Synthesizer 生成的 tokens 上。Format 采用 gate 机制来保证输出可解析。
Rollout 结构
每个 query 采样 8 条 trajectory（group size = 8）。每条 trajectory 是一个完整的多轮流程：planner 根据 normalized query、历史 cues、上一轮 synthesizer reasoning 和 Temporal Evidence Pool 生成 cue → 检索系统在线搜索数据库 → synthesizer 生成 reasoning + events + verdict → 如果 verdict 为 insufficient 则回到 planner 继续下一轮。整个流程中只有 synthesizer 的输出 token 参与梯度更新，planner、检索系统、answerer、judge 和环境文本都不计算梯度。
Trajectory 终止条件：verdict 为 sufficient、没有新 session 被检索到、上下文预算耗尽、或达到最大轮次上限。
如果 trajectory 因为 no-new-evidence、XML invalid、上下文预算或最大轮次而终止，它仍然作为一条 rollout trace 进入 reward computation；最终 outcome 由终止时的 Temporal Evidence Pool 交给 frozen answerer 和 judge 评估。
Reward 设计
总 reward 由四个组件构成，不同组件有不同的聚合方式：
Format gate（f）： 检查整条 trajectory 中所有 synthesizer 输出是否都符合 XML schema 规范（必须包含 reasoning、events block、valid verdict，每个 event 必须引用一个 source session 并包含 session_time 和 event_time 字段）。最终论文中的 format 不是逐轮累积惩罚，而是 gate：如果任意输出不可解析或不符合 schema，则 $f(\tau)=0$，其他 reward 项不再计算，整条 trajectory 得到固定惩罚 $c<0$；如果所有输出格式有效，则 $f(\tau)=1$，才继续计算 verdict、outcome 和 length。
Verdict reward/惩罚（Rver）： 逐轮独立判断。判断标准是将检索系统累积找到的 session（注意是检索系统找到的，不是 synthesizer 引用的）与该 query 的 gold evidence sessions 进行比较。如果 gold sessions 已全部被检索到，此时 sufficient 是正确的给奖励，insufficient 是错误的给惩罚；如果 gold sessions 尚未被完全覆盖，此时 insufficient 是正确的给奖励，sufficient 是错误的给惩罚。每一轮独立计算奖惩，并且不管 trajectory 如何终止，verdict 项都采用累加聚合而不是平均聚合。这样持续错误的 verdict 判断会持续拉低总 reward，与 verdict 和 answer 都正确的 trajectory 形成区分。
Length reward/惩罚（Rlen）： 只在 outcome 正确时触发，用于在答对的 trajectory 中区分输出长度。正确的情况下越短奖励越高，越长越低，超出设定阈值转变为惩罚。多轮时用各轮 synthesizer 输出 token 数的平均值来计算。Outcome 不正确时此项为零。
Outcome reward（Rout）： 在 trajectory 终止后计算一次。将最终累计的 Temporal Evidence Pool $H_{T+1}$ 送给 frozen answer model 生成答案，再由 frozen judge 对比答案与 gold label，输出 yes/no，对应 outcome $o(\tau)\in\{0,1\}$。最终论文中的 answerer 是 Qwen3.5-9B，judge 是 GPT-5.1。
总 reward 公式的直觉：format gate 保证输出可解析，verdict reward 教会模型正确判断证据是否充分，length reward 在答对的前提下鼓励紧凑输出，outcome reward 将整个 evidence construction 过程与最终任务效用挂钩。这里不单独设计 temporal consistency/event-time reward；如果 synthesizer 推理出的 event_time 错误，或者它输出了错误的 event text、source attribution、事件选择，这些错误都会影响后续检索与最终 Temporal Evidence Pool，最终反映为 answer 错误并被 outcome reward 惩罚。
最终论文中的 reward 定义为：
如果 $f(\tau)=0$，则 $R(\tau)=c$；
如果 $f(\tau)=1$，则 $R(\tau)=w_o o(\tau)+w_v\sum_{t=1}^{T}v_t+w_l\ell(\tau)$。
其中最终采用的系数为 $(w_o,w_v,w_l)=(0.50,0.10,0.05)$，format-failure penalty 为 $c=-0.20$。

# GRPO 训练：思路细节与思考
GRPO 训练：思路细节与思考

一、为什么只训 Synthesizer 不训 Planner
整个系统中，Planner 的职责是把 query 和当前 Temporal Evidence Pool 转换成适合检索的 cues，这是环境中的 frozen component。而 Synthesizer 承担的任务才是真正需要训练的——它需要从检索到的 session 中提取与 query 相关的 event、推理 event_time、判断证据充分性，并维护累计 evidence state。如果同时训 Planner 和 Synthesizer，不仅训练复杂度大幅增加，而且 reward 信号会互相干扰——answer 错了到底是 planner 改写得不好、retriever 没搜到，还是 synthesizer evidence construction 做错？冻结 planner 和 retriever 让 policy-gradient 信号主要归因到 Synthesizer，训练信号更干净。

二、为什么不做 SFT warm-up 直接从 base model 开始 GRPO
早期版本做了 SFT warm-up（用强模型生成 demonstrations），但后来发现 base model 已经具备基本的 XML schema 输出能力，不需要 SFT 来教它"怎么输出"。直接做 GRPO 的好处是避免 SFT 阶段引入的 bias——SFT demonstrations 是强模型生成的，它的推理风格和时间判断方式会固化到 policy 里，可能限制 GRPO 阶段的探索空间。最终训练中使用 format gate 作为稳定机制：如果 trajectory 中任意 Synthesizer 输出不可解析，其他 reward 不计算，整条 trajectory 得到固定 format-failure penalty。

三、为什么 Outcome reward 是 binary 的（1/0）而不是连续的
最终论文用 frozen answerer 先基于 Temporal Evidence Pool 生成答案，再用 frozen judge 判断答案是否与 gold answer 语义等价，输出 yes/no，对应 1 和 0。这个选择的理由是简洁和稳定。如果用 F1 之类的连续分数，需要处理部分正确的情况，而 memory 场景下大多数问题是事实性的（"我读了什么书""我去了哪里"），答案要么对要么错，部分正确的情况很少。Binary reward 让 advantage 的计算更清晰——在 8 条 trajectory 里，答对的和答错的之间有明确的分界，GRPO 的 group-wise normalization 能有效地把答对的 trajectory 推高、答错的拉低。

四、为什么 Length reward 只在 outcome 正确时触发
如果 length reward 无条件生效，模型会学到一个捷径：输出极短的、什么都不说的 events 来获取 length 奖励，哪怕答案是错的。把 length reward 限定在 outcome 正确的条件下，它的语义变成了"在答对的前提下，越简洁越好"。这让 length reward 成为一个区分器——在同一个 group 里，多条都答对的 trajectory 之间，输出更紧凑的那些会获得额外奖励。本质上是在 outcome reward 已经保证了质量下限之后，再用 length reward 做效率优化。

五、为什么 Verdict reward 基于检索系统找到的 session 而不是 Synthesizer 引用的 session
这个选择的核心是职责分离。Verdict 判断的是"当前证据是否充分"，而"当前可用的证据"应该是检索系统已经找到的所有 session，不是 synthesizer 选择引用的那些。如果用 synthesizer 引用的 session 来评判，就会出现一个问题：synthesizer 可能故意不引用某些已经检索到的 gold session，然后输出 insufficient 来触发下一轮——这在 reward 上是"正确的"（因为从它引用的角度看确实不充分），但在系统行为上是浪费的。用检索系统找到的 session 作为判断标准，verdict reward 衡量的就是 synthesizer 对客观证据状态的感知能力——检索系统已经把 gold session 端到你面前了，你还说不够，那就是你判断错了。

六、为什么 Verdict reward/惩罚始终累积而不平均
Verdict 是 loop control 的核心信号，衡量 synthesizer 是否准确判断当前检索状态已经足够。这里不做 per-round 平均，而是对每一轮 verdict 奖惩做累加：持续正确判断应该持续贡献正信号，持续错误判断也应该持续付出代价。这样可以区分两类 trajectory：一条在第一轮就正确输出 sufficient 并终止，另一条虽然最终 events 可能答对了问题，但多轮里持续错误输出 insufficient 或过早 sufficient。后者的 verdict 判断错误会通过累积惩罚拉低总 reward，从而让模型学习更准确的停止与继续搜索策略。

七、no-new-evidence 的 trajectory 如何处理
当检索系统在某一轮没有返回任何新 session 时，这条 trajectory 会终止，但不会被丢弃。最终论文的算法把 terminal reason、retrieved sessions、compressor XML、reasoning、events、verdicts 和 answer 都存入 rollout trace，然后照常进入 reward computation。这样 GRPO 学到的是完整在线 memory-search 行为，而不是只在“理想检索成功”的轨迹上训练。

这里有一个重要的 RL 训练直觉：训练数据不能被清洗得过于理想化。真实 rollout 中会出现 no-new-evidence、XML invalid、max-round 仍 insufficient、检索返回近似但不完整 evidence、早停或过度搜索等情况。如果为了训练稳定性把这些异常轨迹主动过滤掉，模型就只会看到“检索顺利、证据干净、格式正确”的成功世界，无法学习遇到失败检索、证据缺口或格式风险时应该如何判断和停止。保留这些非理想轨迹，并用 format gate、verdict reward 和 outcome reward 给出相应反馈，能让 policy 学到真实环境下的 recovery 和 stop/continue 行为。这也是为什么最终论文把 no-new-evidence 当作 terminal reason 记录并继续评分，而不是简单丢弃。

八、为什么用最终累计的 Temporal Evidence Pool 送给 answer model
最终论文的 outcome reward 使用终止时的 Temporal Evidence Pool $H_{T+1}$，也就是累计 evidence state，而不是只使用最后一轮新增 events。原因是 NanoMem 的目标本来就是跨轮构造 evidence state：第一轮可能找到 bridge event，第二轮找到 answer-bearing event，最终答案依赖二者共同构成的 pool。实现 prompt 中也要求 `<events>` 输出是 cumulative 的：保留仍然有效的 previous events，再追加新 events。因此，answer model 接收的是最终累计 pool，judge 根据 answer 是否匹配 gold label 给出 outcome reward。

九、四个 reward 组件之间的层次关系
四个 reward 不是平等并列的，而是有层次递进的关系。Format 是 gate：如果输出格式不可解析，其他 reward 无从计算，整条 trajectory 直接得到固定惩罚。Outcome reward 是最终任务目标，连接 evidence construction 和 task utility。Verdict reward 是流程控制层，提供逐轮 stop/continue 的过程监督。Length reward 是效率优化，只在答对的前提下鼓励更紧凑的 evidence。最终论文的系数设计让 outcome correctness 主导 process quality，process quality 又主导 compactness。
