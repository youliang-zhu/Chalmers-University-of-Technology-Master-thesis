
第一部分：系统完整流程

Ingest 侧（数据入库）
输入是多轮对话 session，每个 session 带有一个 session timestamp（入库时间）。
第一步，时间预处理：扫描 session 里每一句话中的相对时间表达（如 "last week"、"yesterday"、"next month"），用 regex 规则提取这些短语，结合该 session 的 timestamp 计算出绝对时间，然后把绝对时间直接插入到原文中该短语的后面。比如原文是 "last week I went to Paris"，处理后变成 "last week (2023-04-07 to 2023-04-13) I went to Paris"。这一步是确定性的规则处理，不涉及任何模型推理。
第二步，对处理后的 session 文本做 semantic chunking，切成若干语义连贯的小块。
第三步，对每个 chunk 做 embedding，连同原始文本一起存入向量数据库（SQLite）。
至此，数据库中每个 session 的文本已经自带绝对时间标注，后续 synthesizer 读到这些 session 时可以直接看到绝对时间，不需要自己从相对时间表达去推算。

Search 侧（搜索）
Step 1：Query 时间解析
用户提出原始 query，附带一个 query time（提问时间戳）。系统对原始 query 中的时间表达用同一套 regex 规则进行提取和绝对时间计算，以 query time 为锚点。比如 query 是 "Did I go to the supermarket yesterday?"，query time 是 2023-04-21，则提取出 temporal hint：("yesterday", "2023-04-20")。如果 query 里有多个时间表达，则提取多个 temporal hints。如果 query 里没有可识别的时间表达，temporal hints 为空。
这些 temporal hints 由原始短语和对应的绝对时间配对组成，不做任何硬过滤，只作为后续 synthesizer 的辅助输入。

Step 1.5：Query 文本时间标注（用于检索增强）
在 Step 1 完成 temporal hints 提取的同时，系统对 query 文本本身也做同样的处理：将解析出的绝对时间插入到 query 原文中对应的相对时间短语后面，生成一个时间标注版的 query。比如原始 query 是 "Did I go to Paris last week?"，处理后变成 "Did I go to Paris last week (2023-04-14 to 2023-04-20)?"。这个标注后的 query 文本会被用于后续 Step 3 的 BM25 检索。由于 ingest 阶段已经对 session 文本做了同样的处理，当 session 中某个事件的绝对时间与 query 中的绝对时间完全重合时，BM25 会产生强烈的词汇匹配信号。这实质上是把一个时间推理问题转化成了词汇匹配问题，尤其能解决跨时间引用的场景——比如 session 里说的是 "next week I'm going to Paris"（ingest 时被解析成某个绝对时间），而 query 问的是 "two weeks ago"（解析成同一个绝对时间），语义上两者完全不匹配，但通过绝对时间戳的字面重合，BM25 可以把这条 session 捞出来。这一步本质只是增强正确session被搜索到的几率。

Step 2：Planner 改写
Planner（LLM）接收原始 query，将其改写拆分为若干个 cue（检索子查询）。Planner 的职责仅仅是生成适合检索的查询文本，不对 cue 做任何时间提取或时间处理。
Step 3：并行检索
每个 cue 独立并行检索。对每个 cue，系统在数据库中做 embedding 相似度搜索和 BM25 关键词匹配的混合打分（大致权重为 0.75 dense + 0.25 BM25），按分数取 top-k session。不做任何基于时间的硬过滤。
多个 cue 检索到的 session 合并去重，按 session timestamp 升序排列。
Step 4：Synthesizer
Synthesizer（LLM，可以是 vanilla 或 GRPO 训练后的模型）接收三个输入：
第一，原始 query。
第二，合并后的 session 列表（这些 session 的文本已经在 ingest 阶段被插入了绝对时间标注）。
第三，temporal hints 池。第一轮时，这个池子里只有从原始 query 解析出的 temporal hints（短语 + 绝对时间的配对）。后续轮次中，如果上一轮 synthesizer 输出的某个 event 的 event_time 与 session_time 存在显著偏差（说明模型做了时间推理），则该 event 的 text + event_time 也会被加入 temporal hints 池。
Synthesizer 的输出包含三个部分：
Reasoning：推理过程，说明当前证据为什么充分或不充分，缺什么。
Events：一系列结构化的 evidence event，每个 event 包含：event text（自然语言描述的事实陈述）、session_id（来源 session，每个 event 只对应一个 session）、session_time（该 session 的入库时间）、event_time（synthesizer 推理得出的该事件真实发生的绝对时间，如果 session 里没有相对时间指代则等于 session_time，如果有则需要根据 session_time 和相对表达推算）。
Verdict：二值判断——sufficient（证据充分，终止 loop）、insufficient（证据不足，触发下一轮检索）。
Step 5：Loop 或终止
如果 verdict 是 sufficient，流程终止。synthesizer 输出的 events 被送给下游 answer model（如 GPT-5.1），由它根据这些结构化 evidence 生成最终答案。Synthesizer 本身不负责回答问题。
如果 verdict 是 insufficient，原始 query、历史 cues 以及 synthesizer 的 reasoning 被送回 planner。Planner 根据 reasoning 中指出的缺失信息，并结合此前已经搜索过的 cues，生成新的 cue；events 本身不作为 planner 的直接输入。同时，上一轮 synthesizer 输出中 event_time ≠ session_time 的 event，其 event text + event_time 被加入 temporal hints 池。然后回到 Step 3 重新检索，进入下一轮。
循环终止条件：verdict 为 sufficient、没有新 session 被检索到、上下文预算耗尽、或达到最大轮次上限。


第二部分：解决的问题
这个系统解决的核心问题是长期对话记忆中的复杂时间推理。
具体来说，当用户向一个 memory 系统提问时，问题中涉及的事件发生时间往往和该事件被记录在 session 中的时间不同。用户说 "上周我去了北京"，这个事件被记录在今天的 session 里，但事件本身发生在上周。现有的 memory 系统要么完全忽略时间信息只靠语义检索，要么把 session time 当作事件时间来用（比如 Memory-T1 用 session time 做硬过滤，导致真正发生的event被过滤掉），两种做法在时间推理场景下都会出错。
这个系统通过 event time 建模来解决这个问题。它在整个 pipeline 中建立了一条完整的时间推理链条：ingest 阶段把 session 文本里的相对时间转成绝对时间嵌入文本，降低后续模型的推理压力；search 阶段从原始 query 解析出 event time 作为 temporal hints，告诉 synthesizer 目标事件的真实时间范围；synthesizer 对每个检索到的 evidence event 显式推理其 event_time，输出带有时间标注的结构化证据。
对于更困难的 case——时间推理和多跳推理交织的场景——系统通过 verdict 驱动的 loop 机制来处理。典型的例子是 "What book was I reading during the week I got promoted?"：第一轮需要找到 promotion 事件并推理出它的 event_time，第二轮才能用这个时间去搜索对应时间段的读书记录。这里 loop 的触发原因本身就是第一轮时间推理的结果，temporal reasoning 和 multi-hop retrieval 不是两个独立的问题，而是一个因果链——时间推理的输出驱动了下一跳的检索。




机制讨论总结与设计要点

一、Temporal hints 只从原始 query 提取，不从改写后的 cue 提取
我们讨论过一个问题：时间信息应该从哪里提取？从每个 cue 提取还是从原始 query 提取？最终决定只从原始 query 提取。理由是 query 是用户直接说出来的，是最干净、最确定的信号源。cue 是 planner 改写的产物，从 cue 提取等于让 planner 的改写质量影响时间解析的准确性，多引入一层模型就多一层不确定性。这个设计原则贯穿了整个系统：凡是能用确定性规则处理的，就不交给模型；只有必须推理的部分才交给模型。

二、Temporal hints 的格式：原始短语 + 绝对时间配对
我们讨论过 temporal hints 应该只传绝对时间还是连同原始短语一起传。最终决定配对传入，比如 ("last week", "2023-04-14 to 2023-04-20")。原因是如果只传一个裸的绝对时间范围，synthesizer 不知道这个时间对应 query 里的哪个表达，还得自己猜，多了一步不必要的推理。配对传入后，模型看到 query 里的 "last week"，再看到 hints 里的对应关系，直接就能建立映射。这个设计同样适用于 synthesizer 推理出的 event_time——和 event text 绑定打包，格式统一。

三、跨轮次的 temporal hints 池累积机制
这是我们讨论出的一个关键机制。temporal hints 池不是静态的，它会跨轮次累积。第一轮时，池子里只有从原始 query regex 解析出的时间。当 synthesizer 第一轮输出的某个 event 的 event_time 与 session_time 存在显著偏差时，说明 synthesizer 做了时间推理（比如从 session 里的 "last week" 推算出 promotion 发生在 5 月 8 号），这个 event text + event_time 就被加入 temporal hints 池，供第二轮使用。
这个设计精妙在于：它把 synthesizer 的推理产物直接变成了下一轮的确定性输入。 第一轮的时间推理结果不需要再经过 planner 重新处理或二次提取，而是干净地直接进入 hints 池。整个信息流是 query regex → synthesizer 推理 → hints 池，每一步都是最短路径，没有多余的模型处理环节。

四、event_time ≠ session_time 作为"是否做了时间推理"的判断标准
我们讨论了怎么判断哪些 event 的时间应该回流到 hints 池。最终用的标准是 event_time 是否与 session_time 存在显著偏差。如果相等，说明事件就发生在对话当天，没有新的时间信息可贡献；如果不等，说明 synthesizer 从 session 文本中的相对时间表达推算出了一个不同于对话时间的真实事件时间，这个推理结果对后续轮次有价值。这个标准简单、确定、不需要额外的模型判断。

五、训练闭环：event_time 推理错误会被 RL 自然惩罚
这是这个系统设计在训练层面的闭环。如果 synthesizer 推理出的 event_time 是错的，那么这个错误的时间会进入 temporal hints 池，导致第二轮检索方向偏差，最终 answer model 给出错误答案，outcome reward 为零或负值，GRPO 会惩罚产生这个错误 event_time 的 synthesizer policy。也就是说，event_time 的推理质量不需要单独设计 reward 来监督——它通过 outcome reward 的反向传导被自然覆盖了。 这让 reward 设计可以更简洁，不需要为时间推理准确性单独造标注数据或设计 judge。

六、从 ingest 到 search 的时间处理形成统一的设计哲学
回顾整个系统，时间处理在三个阶段出现，每个阶段的职责清晰且不重叠：
Ingest 阶段：用确定性规则（regex + session timestamp）把 session 文本里的相对时间转绝对时间，嵌入文本。目的是降低下游模型的推理压力，让 synthesizer 看到的 session 自带绝对时间。
Query 解析阶段：用同一套确定性规则（regex + query time）把 query 里的相对时间转绝对时间，作为独立的 temporal hints 输入。目的是显式告诉 synthesizer 用户问的事件的时间范围。
Synthesizer 阶段：这是唯一需要模型推理的地方。 模型结合 temporal hints 和 session 文本中已标注的绝对时间，推理出每个 evidence event 的真实 event_time。这个推理结果既是当前轮次的输出，也可以成为下一轮的输入。
这三个阶段形成一个层次递进的结构：确定性规则能处理的尽早处理（ingest 和 query 解析），只把必须推理的部分留给模型（synthesizer），而模型推理的结果又可以回流成下一轮的确定性输入（temporal hints 池累积）。 整个设计的哲学是把不确定性压缩到最小的范围内。


# GRPO 训练：算法流程与实现细节

训练对象
只训练 Synthesizer。Planner 通过 SFT 蒸馏获得基础能力，不参与 GRPO 训练，在 rollout 过程中 planner 参数冻结。训练初期加入 format 惩罚机制来确保稳定性。
Rollout 结构
每个 query 采样 8 条 trajectory（group size = 8）。每条 trajectory 是一个完整的多轮流程：planner 根据原始 query、历史 cues 和上一轮 synthesizer reasoning 生成 cue → 检索系统在线搜索数据库 → synthesizer 生成 reasoning + events + verdict → 如果 verdict 为 insufficient 则回到 planner 继续下一轮。整个流程中只有 synthesizer 的输出 token 参与梯度更新，planner 和检索系统的部分不计算梯度。
Trajectory 终止条件：verdict 为 sufficient、没有新 session 被检索到、上下文预算耗尽、或达到最大轮次上限。
待确认特殊情况：如果 trajectory 因为 no-new-evidence 而终止，暂定候选处理是丢弃该 trajectory，不参与整组的 reward 计算和梯度更新；但这一点尚未最终确认，论文正文中暂时不写、不展开。
Reward 设计
总 reward 由四个组件构成，不同组件有不同的聚合方式：
Format 惩罚（Rfmt）： 检查 synthesizer 输出是否符合 XML schema 规范（必须包含 reasoning、events block、valid verdict，每个 event 必须引用一个 source session 并包含 session_time 和 event_time 字段）。论文写法上可以把它称为一个 reward component，但实际数值设计是 penalty-only：base model 格式遵守率已达 98%，不需要正向激励，只需要防止退化。多轮时做累积不做平均，多轮格式错误受更重惩罚。
Verdict reward/惩罚（Rver）： 逐轮独立判断。判断标准是将检索系统累积找到的 session（注意是检索系统找到的，不是 synthesizer 引用的）与该 query 的 gold evidence sessions 进行比较。如果 gold sessions 已全部被检索到，此时 sufficient 是正确的给奖励，insufficient 是错误的给惩罚；如果 gold sessions 尚未被完全覆盖，此时 insufficient 是正确的给奖励，sufficient 是错误的给惩罚。每一轮独立计算奖惩，并且不管 trajectory 如何终止，verdict 项都采用累加聚合而不是平均聚合。这样持续错误的 verdict 判断会持续拉低总 reward，与 verdict 和 answer 都正确的 trajectory 形成区分。
Length reward/惩罚（Rlen）： 只在 outcome 正确时触发，用于在答对的 trajectory 中区分输出长度。正确的情况下越短奖励越高，越长越低，超出设定阈值转变为惩罚。多轮时用各轮 synthesizer 输出 token 数的平均值来计算。Outcome 不正确时此项为零。
Outcome reward（Rout）： 在 trajectory 终止后计算一次。将最后一轮 synthesizer 输出的 events（不包含之前轮次的 events）送给下游 answer model，由一个强 LLM 作为 eval model 对比答案与 gold label，输出 yes/no，对应 reward 为 1 或 0。对于 max-round-insufficient 的 trajectory，正常计算 outcome——用最后一轮的 events 送给 answer model 评估。
总 reward 公式的直觉： format 惩罚保证输出可解析，verdict reward 教会模型正确判断证据是否充分，length reward 在答对的前提下鼓励紧凑输出，outcome reward 将整个 evidence construction 过程与最终任务效用挂钩。这里不单独设计 temporal consistency/event-time reward；如果 synthesizer 推理出的 event_time 错误，它会进入后续检索与最终 events，最终反映为 answer 错误并被 outcome reward 惩罚。四个组件各自负责一个层面，通过加权组合得到最终 reward，用 GRPO 的 group-wise advantage 计算更新 synthesizer 的 policy。

# GRPO 训练：思路细节与思考
GRPO 训练：思路细节与思考

一、为什么只训 Synthesizer 不训 Planner
整个系统中，Planner 的职责是把 query 改写成适合检索的 cue，这是一个相对标准的 query rewriting 任务，强模型蒸馏或 SFT 就能获得足够的能力。而 Synthesizer 承担的任务才是真正需要训练的——它需要从检索到的 session 中提取与 query 相关的 event、推理 event_time、判断证据充分性，这些能力 base model 不具备或做得不好，必须通过 RL 来习得。如果同时训两个模型，不仅训练复杂度大幅增加，而且两个模型的 reward 信号会互相干扰——answer 错了到底是 planner 改写得不好还是 synthesizer 推理得不好？冻结 planner 让 reward 信号完全归因到 synthesizer，训练信号更干净。

二、为什么不做 SFT warm-up 直接从 base model 开始 GRPO
早期版本做了 SFT warm-up（用强模型生成 demonstrations），但后来发现 base model 对 XML schema 的格式遵守率已经达到 98%，说明 base model 已经具备基本的格式输出能力，不需要 SFT 来教它"怎么输出"。直接做 GRPO 的好处是避免 SFT 阶段引入的 bias——SFT demonstrations 是强模型生成的，它的推理风格和时间判断方式会固化到 policy 里，可能限制 GRPO 阶段的探索空间。加入 format 惩罚机制作为替代，在训练初期如果 base model 偶尔输出格式错误就施加惩罚，足以维持稳定性。

三、为什么 Outcome reward 是 binary 的（1/0）而不是连续的
用强 LLM 作为 eval model 只输出 yes/no，对应 1 和 0。这个选择的理由是简洁和稳定。如果用 F1 之类的连续分数，需要处理部分正确的情况，而 memory 场景下大多数问题是事实性的（"我读了什么书""我去了哪里"），答案要么对要么错，部分正确的情况很少。Binary reward 让 advantage 的计算更清晰——在 8 条 trajectory 里，答对的和答错的之间有明确的分界，GRPO 的 group-wise normalization 能有效地把答对的 trajectory 推高、答错的拉低。

四、为什么 Length reward 只在 outcome 正确时触发
如果 length reward 无条件生效，模型会学到一个捷径：输出极短的、什么都不说的 events 来获取 length 奖励，哪怕答案是错的。把 length reward 限定在 outcome 正确的条件下，它的语义变成了"在答对的前提下，越简洁越好"。这让 length reward 成为一个区分器——在同一个 group 里，多条都答对的 trajectory 之间，输出更紧凑的那些会获得额外奖励。本质上是在 outcome reward 已经保证了质量下限之后，再用 length reward 做效率优化。

五、为什么 Verdict reward 基于检索系统找到的 session 而不是 Synthesizer 引用的 session
这个选择的核心是职责分离。Verdict 判断的是"当前证据是否充分"，而"当前可用的证据"应该是检索系统已经找到的所有 session，不是 synthesizer 选择引用的那些。如果用 synthesizer 引用的 session 来评判，就会出现一个问题：synthesizer 可能故意不引用某些已经检索到的 gold session，然后输出 insufficient 来触发下一轮——这在 reward 上是"正确的"（因为从它引用的角度看确实不充分），但在系统行为上是浪费的。用检索系统找到的 session 作为判断标准，verdict reward 衡量的就是 synthesizer 对客观证据状态的感知能力——检索系统已经把 gold session 端到你面前了，你还说不够，那就是你判断错了。

六、为什么 Verdict reward/惩罚始终累积而不平均
Verdict 是 loop control 的核心信号，衡量 synthesizer 是否准确判断当前检索状态已经足够。这里不做 per-round 平均，而是对每一轮 verdict 奖惩做累加：持续正确判断应该持续贡献正信号，持续错误判断也应该持续付出代价。这样可以区分两类 trajectory：一条在第一轮就正确输出 sufficient 并终止，另一条虽然最终 events 可能答对了问题，但多轮里持续错误输出 insufficient 或过早 sufficient。后者的 verdict 判断错误会通过累积惩罚拉低总 reward，从而让模型学习更准确的停止与继续搜索策略。

七、待确认：no-new-evidence 的 trajectory 如何处理
当检索系统在某一轮没有返回任何新 session 时，这条 trajectory 的终止不是因为 synthesizer 的判断（好或坏），而是因为检索系统的客观限制。候选方案是丢弃这类 trajectory，使 GRPO 的 advantage 计算只基于 synthesizer 自身行为能影响的 trajectory；但这一点尚未最终确认。论文正文中暂时不写这个处理，后续等实现和实验策略确定后再决定是否放入方法或附录。

八、为什么只用最后一轮的 events 送给 answer model 而不是所有轮次累积
如果把所有轮次的 events 累积起来送给 answer model，早期轮次输出的不准确或不完整的 events 会混入最终评估。这会产生两个问题：第一，answer model 可能被早期错误的 events 误导；第二，outcome reward 的信号变得模糊——答错了到底是因为最后一轮 synthesizer 做得不好，还是因为第一轮的 events 有问题？只用最后一轮的 events 让 outcome reward 清晰地归因到最终状态的 synthesizer 输出质量上。而且从系统设计逻辑来看，最后一轮 verdict 为 sufficient 意味着 synthesizer 认为当前 events 已经足以回答问题，那就用这一轮的 events 来验证它的判断是否正确，这是自洽的。

九、四个 reward 组件之间的层次关系
四个 reward 不是平等并列的，而是有层次递进的关系。Format 惩罚是最底层的保障——如果输出格式都不对，其他三个 reward 无从计算。Verdict reward 是流程控制层——教模型什么时候停、什么时候继续。Outcome reward 是最终目标——连接 evidence construction 和 task utility。Length reward 是锦上添花——在答对的前提下优化效率。这个层次关系通过各自的触发条件自然体现：format 无条件生效，verdict 无条件生效，outcome 在 trajectory 终止后生效，length 只在 outcome 正确时生效。
