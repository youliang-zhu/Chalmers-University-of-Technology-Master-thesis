# 第五章 Discussion 规划稿

本文档是第五章 Discussion 的中文规划稿，不是最终 LaTeX 正文。本章的任务不是重复第四章 Results，也不是只写一个简短 conclusion，而是把 NanoMem 的实验结果、方法边界和硕士论文层面的反思组织起来：先解释结果对 memory-as-evidence-provider 范式意味着什么，再讨论系统的局限、威胁、伦理与部署问题，最后提出未来工作并总结全文。最终正文应让读者看到：NanoMem 的贡献不仅是几个 benchmark 上的 accuracy 提升，而是把长期 agent memory 的接口从“返回更多上下文或直接回答”推进到“构造 compact、source-grounded、temporally grounded evidence”。

本章需要承接前四章。第一章提出 evidence addressability gap 和研究问题；第二章说明已有 memory、retrieval、temporal reasoning 和 RL 工作留下的空白；第三章给出 NanoMem 的 Temporal Evidence Pool、Planner-Retriever-Synthesizer loop 和 GRPO 训练；第四章报告主结果、compactness、architecture ablation、reward ablation 与错误类型。本章不再引入新的实验 claim，也不应补写未经核对的数字。所有数字性表述只回扣第四章已经计划报告的结果，例如 LoCoMo、LongMemEval、TimeMemEval/ChainMem 的主结果、ablation 现象和 token compactness。

## 5.1 章节导入：从实验结果回到研究问题

本小节负责把 Results 章节转化为 Discussion 的问题框架。正文开头应简短回顾本论文的核心问题：长期多 session memory 中的 evidence 往往不能被原始 query 直接寻址，尤其当 answer-bearing session 隐藏在 temporal bridge、causal predecessor 或先前 evidence 暴露的新 cue 之后时，一次性 retrieval 或 write-time memory record 不足以稳定解决问题。

随后按第一章的 research questions 回收答案：

RQ1 关注如何把 memory 表示为 structured evidence。Discussion 中应指出，Temporal Evidence Pool 证明了一个有用的 memory-side interface：每条 event 保留 source/session identifier、session_time 和 event_time，使下游 answer model 不必直接消费长而噪声化的 raw sessions。

RQ2 关注如何通过 iterative retrieval 找到 hidden evidence。Discussion 中应强调，NanoMem 的关键不是“多检索几轮”本身，而是让上一轮 evidence synthesis 产生下一轮可用的 retrieval cue。Results 中 single-round retrieval 与 Temporal Evidence Pool ablation 的差异可以作为证据：多轮机制在 hidden-dependency 场景下有价值，但不应被解释为所有问题都需要更多轮次。

RQ3 关注实验表现。Discussion 中应概括：NanoMem-GRPO 在 LoCoMo、LongMemEval 和 TimeMemEval/ChainMem 上同时改善 accuracy 与 evidence compactness，特别是在 multi-hop、temporal reasoning 和 temporal-bridge 类任务上收益更明显；但 TimeMemEval/ChainMem 的绝对准确率仍然有限，说明 evidence addressability gap 并未被完全解决。

本小节末尾应说明本章结构：5.2 解释 positive implications，5.3 分析失败模式，5.4 讨论 threats to validity，5.5 讨论 practical deployment，5.6 讨论伦理与隐私，5.7 提出未来工作，5.8 总结全文。

## 5.2 NanoMem 对 agent memory 设计的启示

本小节是 Discussion 的核心解释部分。正文应从实验现象中抽象出三个设计启示，而不是逐表复述数字。

第一，memory module 的输出形式会影响可诊断性。Write-time memory 和 passive retrieval 常把 memory output 表示为 memory records、raw chunks 或 ranked sessions；direct-answering memory 则把 retrieval、evidence compression 和 final reasoning 混在一起。NanoMem 的结果支持一个更窄但更可诊断的接口：memory module 只负责构造 evidence 和 sufficiency verdict，final answer 由 downstream answer model 完成。这样做使错误可以被拆成 retrieval miss、temporal grounding error、premature sufficiency、evidence bloat 或 answerer error，而不是只看到最终答案错了。

第二，event_time 应被视为 search state，而不仅是 metadata。Methods 章节会说明 session_time 与 event_time 的分离；Results 中 text normalization、Temporal Evidence Pool 和 multi-round retrieval 的 ablation 说明时间信息的作用分布不同。Discussion 应进一步解释：如果时间只作为 session filter，系统会错过“在某天提到过去事件”的证据；如果时间只作为 final reasoning 的自然语言上下文，下游模型又承担过多负担。NanoMem 的 design lesson 是把 event_time 作为 evidence state 维护，让它能参与下一轮 retrieval cue generation。

第三，sufficiency supervision 是 iterative memory search 的关键控制信号。Reward ablation 中移除 verdict reward 后，某些 temporal 子任务可能上升，但 hidden-dependency 和 multi-hop 任务下降、verdict accuracy 降低、平均轮数和 tokens 增加。Discussion 应解释这个非单调现象：outcome-only reward 可以在第一轮 evidence 已经足够的任务上表现不错，但它无法稳定训练“当前证据还不够，应继续搜索”的中间决策。verdict reward 的价值在于把 stop/continue 从隐含副作用变成可训练的 memory-side decision。

**计划图 5.1：NanoMem 的错误诊断边界图。** 放在 5.2 末尾或 5.3 开头。图中从 query 进入 Planner、Retriever、Synthesizer、Temporal Evidence Pool、downstream answerer，并在每个组件旁标出可观察失败类型：cue error、retrieval miss、event_time error、premature sufficient、evidence bloat、answerer error。该图不是新架构图，而是 Discussion 用的 diagnostic boundary 图，帮助读者理解 memory-as-evidence-provider 如何拆分责任。若全文图数超出预算，本图优先保留，Results 中可选错误路径图可省略。

## 5.3 失败模式与系统局限

本小节讨论 NanoMem 本身仍然失败的地方。正文应避免泛泛写“未来还可以改进”，而要把局限绑定到第四章 error analysis 和 NeurIPS conclusion 中已经识别的 failure sources。

第一，retrieval recall 仍然是上限。NanoMem 的 Synthesizer 只能从已经召回的 sessions 中构造 evidence；如果 Planner cue 错误、retriever 未召回 destination session，或者 candidate budget 太小，Temporal Evidence Pool 无法凭空恢复缺失证据。Discussion 应明确：structured evidence synthesis 不能替代高召回 retrieval，尤其在 answer-bearing session 与 query surface form 差距很大时。

第二，rule-based temporal normalization 覆盖有限。NanoMem 使用 deterministic normalization 处理 `last week`、`yesterday`、月份、星期和若干 offset 表达，这能减少低层日期算术错误，但无法覆盖所有自然语言时间表达、模糊区间、文化日历、时区、重复事件和长期计划变化。正文应指出，normalization 的失败可能有两种后果：检索阶段缺少有用时间 cue，或 Synthesizer 基于错误 time span 继续搜索。

第三，event-time grounding 仍可能产生错误传播。即使 retriever 找到了相关 session，Synthesizer 也可能把 session_time 当成 event_time、错误解析相对表达、或把宽泛时间区间压缩成过窄窗口。由于 NanoMem 把 event_time 作为下一轮 retrieval cue，这类错误会传播成 retrieval drift。Discussion 中应解释这是 iterative search 的双刃剑：正确 evidence state 能暴露 hidden cue，错误 evidence state 也会强化错误路径。

第四，structured output 带来 parseability 与 expressiveness tradeoff。XML schema 让 events 和 verdict 可解析、可训练、可评估；但它也要求模型稳定输出合法结构，并可能难以表达 uncertainty、conflict、multi-source inference 或部分支持。最终系统删除了 `inferred` 字段和三值 `indicative` verdict，换来更简单的训练与评估，但也减少了显式表达不确定性的空间。该点适合在 Discussion 中作为设计取舍，而不是 Methods 的最终 schema 冲突。

第五，iterative retrieval 增加 latency 和 token cost。虽然 NanoMem 输出给下游 answerer 的 evidence 更紧凑，但 search loop 本身需要 Planner、Retriever、Synthesizer 和可能多轮 LLM 调用。正文应区分“output compactness”和“end-to-end serving cost”：第四章的 token compactness 不能直接证明部署 latency 更低。若第二阶段没有真实 latency 统计，应明确写成 limitation，不要臆造效率数字。

第六，downstream answerer 仍然影响最终指标。NanoMem 评估中 answer quality 由固定 downstream answerer 消费 evidence 后产生；如果 evidence 正确但 answerer 推理失败，accuracy 仍会下降。反过来，强 answerer 也可能弥补部分 evidence 缺陷。因此 Discussion 应把 final answer accuracy 解释为 memory evidence usefulness 的外部代理，而不是纯粹的 memory correctness。

**计划表 5.1：NanoMem 失败模式、可观察信号与缓解方向。** 放在 5.3 末尾。列为失败类型、发生组件、可观察信号、对结果的影响、可能缓解方向。行包括 retrieval miss、temporal normalization failure、event_time drift、premature sufficiency、over-search/evidence bloat、structured parse failure、downstream answerer error。该表与 Results 的 error taxonomy 呼应，但 Discussion 版更强调系统限制和改进方向。

## 5.4 实验有效性威胁

本小节讨论 threats to validity，按硕士论文常见结构组织为 internal validity、construct validity、external validity 和 reproducibility。

Internal validity 方面，正文应讨论自动评估和实验实现可能影响结论。NanoMem 使用 GPT-5.1 作为固定 LLM judge，所有方法使用同一 judge prompt，这保证了相对一致性，但 LLM judge 仍可能偏好某些表达风格、误判等价答案或忽略 source grounding 错误。若 baseline 实现来自不同代码库或 public checkpoint，也可能存在 prompt、retriever、context budget、model backbone 的不完全公平。正文应说明第四章会通过 model-combo 表和统一 answerer 尽量控制这些因素，但无法完全消除。

Construct validity 方面，正文应讨论指标是否准确衡量 memory-as-evidence-provider。Final answer accuracy 衡量 evidence 对下游 answerer 的有用性，但不直接等同于 evidence faithfulness 或 source correctness。Output tokens 衡量 evidence compactness，但不同 baseline 的 token 含义可能不同：有些是 memory records，有些是 raw context，有些是 final answer。Verdict accuracy 衡量 stop/continue 是否与 gold evidence coverage 一致，但它依赖 gold evidence session 标注，无法完全覆盖部分证据或 alternative evidence path。

External validity 方面，正文应讨论 benchmark 的代表性。LoCoMo 和 LongMemEval 是重要 public benchmarks，但它们仍是有限数据集；TimeMemEval/ChainMem 是 diagnostic benchmark，更强地测试 temporal bridge 和 hidden dependency，但生成式构造可能与真实用户记忆问题有分布差异。NanoMem 在这些 benchmark 上有效，并不自动意味着它能处理所有长期个人记忆、工作流记忆、医疗/法律记忆或开放世界 causal reasoning。

Reproducibility 方面，正文应讨论模型版本、API judge、训练随机性、retriever index、数据过滤和 hardware 影响。GRPO rollout、LLM judge 和 downstream answerer 都可能受模型版本变化影响。最终 thesis 正文应把可复现边界写清楚：哪些配置来自代码和 appendix，哪些结果依赖外部模型服务，哪些超参数必须在附录中固定。

**计划表 5.2：实验有效性威胁与论文中的缓解措施。** 放在 5.4 末尾。列为威胁类别、具体威胁、可能影响、已采用缓解、仍残留的风险。该表有助于把 Discussion 写得系统，而不是零散列 limitation。

## 5.5 部署与工程实践讨论

本小节把 NanoMem 从 benchmark setting 放到实际 agent memory service 中讨论。正文应保持务实：NanoMem 是 research prototype，不能直接宣称生产可用；但它暴露了 production memory system 需要面对的接口与治理问题。

第一，serving pipeline 需要 budget-aware control。实际系统中，每次 query 不能无限多轮检索，也不能把每轮都交给大模型。部署版需要设置 max rounds、candidate budget、timeout、fallback policy 和 cache。NanoMem 的 verdict 机制提供了 stop/continue signal，但还需要和 latency、cost、user urgency 结合。

第二，memory evidence provider 应支持 audit trail。因为 NanoMem 输出 source/session identifiers、session_time 和 event_time，系统可以给用户或开发者展示“为什么这么回答”。这比直接 answer-only memory 更利于调试和信任建立。但 audit trail 也要求 evidence events 不泄露无关私人内容，source access control 必须贯穿 retrieval 和 display。

第三，personal memory 需要更新、删除和 access control。NanoMem 的研究重点是 read-time evidence construction；但真实 memory service 还需要 write/update/delete、user isolation、agent isolation、retention policy 和 consent management。项目代码中存在 server delete 和 memory service 相关接口，但 thesis Discussion 应只把它们作为部署边界，不把 read-time NanoMem 夸大成完整 memory governance solution。

第四，schema 与 API 稳定性很重要。Temporal Evidence Pool 可以作为 memory service 的中间 API，但生产系统需要版本化 schema、向后兼容、错误处理和 monitoring。XML 输出在研究中方便 parser 和 reward；实际系统中可能需要 JSON schema、typed protobuf 或严格 validator。

第五，人机交互层需要决定 evidence 的可见性。某些应用可能只把 final answer 展示给用户，另一些应用则展示 supporting evidence。Discussion 中可以提出一个原则：当 memory 内容敏感、答案影响决策或用户可能需要纠错时，系统应优先展示 source-grounded evidence 或至少允许用户展开查看；当问题低风险且证据不敏感时，可隐藏细节以减少界面负担。

**计划表 5.3：从研究原型到部署系统的工程需求。** 放在 5.5 末尾。列为需求、NanoMem 当前支持程度、缺口、可能实现方向。行包括 budget control、audit trail、access control、deletion/update、schema validation、monitoring、human feedback。

## 5.6 伦理、隐私与安全

本小节讨论长期 agent memory 的高风险属性。正文应明确：NanoMem 处理的是 personal or conversational memory，天然涉及隐私、同意、访问控制和错误归因风险。本节不需要泛泛写 AI ethics，而要围绕 memory evidence construction 的具体风险。

第一，长期 memory 会积累敏感信息。即使单条 session 看似无害，跨 session evidence synthesis 可能揭示用户健康、财务、关系、工作计划或位置模式。NanoMem 的 iterative search 能把间接 evidence 连接起来，因此隐私风险不只来自存储，也来自 query-time inference。

第二，source-grounded evidence 有助于 audit，但也可能放大泄露。系统如果把过多 source context 展示给下游 agent 或用户界面，可能暴露与 query 无关的私人内容。Compact evidence 是一种风险缓解，但只有在 Synthesizer 不引入错误、不遗漏必要限定且遵守 access policy 时才有效。

第三，用户需要控制 memory lifecycle。部署系统应提供 consent、inspection、correction、deletion 和 retention controls。用户应该能知道系统记住了什么、为何使用某条 evidence、如何删除或纠正错误 memory。NanoMem 本身主要研究 read-time search，不完整解决这些治理问题；Discussion 应把这作为 future production requirement。

第四，错误 memory evidence 可能造成现实伤害。Premature sufficient、event_time drift 或错误 source attribution 可能导致 agent 给出错误建议，尤其在医疗、法律、财务、心理健康等高风险场景。正文应建议在高风险场景中把 NanoMem evidence 作为辅助信息，并要求 human verification 或 domain-specific safeguards。

第五，benchmark 成功不等于安全部署。LoCoMo、LongMemEval 和 TimeMemEval/ChainMem 能测试 answer quality 与 temporal bridge search，但不能全面评估 privacy leakage、data retention、adversarial queries、cross-user contamination 或 policy compliance。Discussion 应明确这些是超出当前实验范围的安全评估方向。

## 5.7 未来工作

本小节应提出具体、可执行的未来方向，而不是泛泛写“提升性能”。建议按五个方向组织。

第一，更强的 retrieval 与 planning policy。目前 NanoMem 主要训练 Synthesizer，Planner 和 Retriever 多数情况下冻结或由既有模块驱动。未来可以训练 Planner 生成更稳定的 multi-hop cues，或让 retrieval policy 学习在 dense、BM25、temporal hints 和 source constraints 之间动态分配 budget。

第二，更丰富的 evidence schema。当前最终 schema 保留 event text、session_id、session_time、event_time 和 binary verdict。未来可以研究 uncertainty、conflict、multi-source support、evidence relation type、negative evidence、belief update 和 source confidence。但这些字段必须配套可靠标注、reward 和评估，否则会增加模型输出负担。

第三，更可靠的 temporal and causal reasoning。Rule-based temporal normalization 可以扩展到更多语言、时区、模糊时间、周期性事件和 calendar constraints。更进一步，系统可以结合 symbolic temporal reasoner 或 constraint solver，减少 LLM 在日期算术和区间推理上的错误。

第四，直接评估 evidence quality。当前 final answer accuracy 是重要但间接的代理指标。未来可以加入人工或半自动 evidence evaluation，分别测量 source faithfulness、event_time correctness、minimality、coverage、uncertainty calibration 和 verdict reliability。这样可以更清楚地区分 retrieval 成功但 evidence synthesis 失败、evidence 正确但 answerer 失败等情况。

第五，真实用户与长期部署评估。未来需要在持续交互场景中评估 NanoMem，包括 memory update、用户纠错、删除请求、privacy policy、latency budget、longitudinal drift 和 trust calibration。TimeMemEval/ChainMem 可以继续作为 diagnostic benchmark，但最终仍需要真实或更真实的 longitudinal agent tasks。

第六，多语言与跨域 memory。当前论文主要围绕英文 benchmark 和技术场景。未来可以测试中文、瑞典语或多语言会话中的相对时间表达，也可以评估工作流 agent、教育 tutor、个人助理、代码 agent 和研究助手等不同 domain 的 evidence addressability gap 是否相同。

**计划表 5.4：未来工作路线图。** 放在 5.7 末尾。列为方向、当前限制、需要的新方法、需要的新评估。该表让 future work 更具体，也能帮助答辩时说明 thesis 后续价值。

## 5.8 结论

本小节是整篇 thesis 的最终 conclusion，应短而有力，不再引入新 limitation 或新实验。正文可以分三段。

第一段回到问题：长期 agent memory 的核心挑战不是把更多历史塞进 context window，而是在当前 query 下找到并组织真正支持回答的 evidence。Evidence addressability gap 使很多必要 evidence 不能被原始 query 直接召回，尤其在 temporal-causal、multi-session 和 hidden-dependency 场景中。

第二段总结方法：NanoMem 把 memory 重新定义为 evidence provider，通过 deterministic temporal normalization、Planner-Retriever-Synthesizer loop、Temporal Evidence Pool 和 GRPO-trained sufficiency verdict，在 query time 构造 compact、source-grounded、temporally grounded evidence。它把 final answer generation 留给 downstream answer model，从而保持 memory module 的可诊断边界。

第三段总结实证和意义：实验计划在 LoCoMo、LongMemEval 和 TimeMemEval/ChainMem 上展示 NanoMem-GRPO 的优势，尤其是在 multi-hop、temporal reasoning 和 hidden-dependency temporal bridge 任务上，同时显著减少传给 answerer 的 evidence tokens。与此同时，系统仍受 retrieval recall、temporal normalization、structured output、LLM judge、latency 和 privacy governance 限制。最终结论应强调：NanoMem 不是长期 agent memory 的完整终点，而是证明了一个有价值的方向——把 memory search 作为 iterative evidence synthesis 来设计、训练和评估。

## 与 NeurIPS 论文相比的扩展要求

NeurIPS 论文的 Conclusion and Limitations 只有一个压缩段落；硕士论文 Discussion 应显著扩展以下内容。

一是把结果解释成设计启示。会议论文只需说明 NanoMem 有效；硕士论文应解释为什么 memory-as-evidence-provider、event_time as search state 和 sufficiency verdict 是更一般的 agent memory 设计原则。

二是系统化分析 failure modes。不要只列 limitation，而要把 retrieval miss、temporal grounding error、premature sufficient、over-search、structured parse failure 和 answerer error 对应到系统组件与可观察信号。

三是加入 threats to validity。硕士论文需要讨论 LLM judge、benchmark representativeness、token metric definition、baseline fairness、external model versions 和 reproducibility risk。

四是讨论部署与治理。NanoMem 处理长期 personal memory，因此必须讨论 latency/cost、audit trail、access control、deletion、consent、source exposure 和 high-risk domain safeguards。

五是提出具体 future work。未来方向应围绕 trainable Planner/Retriever、更丰富 evidence schema、symbolic temporal reasoning、direct evidence evaluation、真实长期部署和多语言/跨域评估展开。

六是保持最终结论克制。不要把 benchmark 成功写成通用长期记忆已经解决；应强调 NanoMem 推进了 iterative temporal evidence synthesis，但仍需要更强 retrieval、更可靠 evidence auditing 和完整 privacy governance。

## 本章计划图表汇总

| 编号 | 位置 | 类型 | 内容 | 作用 |
|---|---|---|---|---|
| 图 5.1 | 5.2 末尾或 5.3 开头 | 诊断边界图 | Planner、Retriever、Synthesizer、Temporal Evidence Pool、answerer 的错误边界 | 展示 memory-as-evidence-provider 如何拆分系统责任与失败来源 |
| 表 5.1 | 5.3 末尾 | 失败模式表 | retrieval miss、temporal normalization failure、event_time drift、premature sufficiency、over-search、parse failure、answerer error | 系统化总结 NanoMem 局限与缓解方向 |
| 表 5.2 | 5.4 末尾 | threats 表 | internal、construct、external、reproducibility validity threats | 满足硕士论文对实验有效性反思的要求 |
| 表 5.3 | 5.5 末尾 | 部署需求表 | budget control、audit trail、access control、deletion/update、schema validation、monitoring、human feedback | 把研究原型和 production memory service 的差距讲清楚 |
| 表 5.4 | 5.7 末尾 | future work 表 | future directions、当前限制、新方法、新评估 | 让未来工作具体且可执行 |

本章计划 1 张图、4 张表。考虑到前三章已经计划较多方法图，Discussion 应保持视觉元素克制：只保留一张 diagnostic boundary 图，主要用表格承担反思、局限和未来工作。这样全论文总图数仍可控制在约 15 张以内；若第四章保留较多结果图，则第五章可以只保留表格而取消图 5.1。
