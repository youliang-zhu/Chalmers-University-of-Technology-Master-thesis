# Appendix 规划稿

本文档是硕士论文 Appendix 的中文规划稿，不是最终 LaTeX 正文。Appendix 的任务不是继续讲新的研究结论，而是补齐正文中为了可读性而压缩掉的实验细节、算法细节、数据构造细节和 prompt 模板，使论文具备更好的 reproducibility、auditability 和答辩支撑。

本规划主要参考 NanoMem NeurIPS 最终版附录：

```text
Experiment Details
  Model and Baseline Configurations
  Training Implementation Details
  Evaluation Protocol
  Main Benchmark Results
  Fixed Downstream Answerer
  Existing Memory-System Implementations

Algorithm Details
  NanoMem Training Procedure
  Reward Design
  Reward Coefficient Analysis

Dataset Details
  TimeMemEval Benchmark Construction
  Training and Held-out Evaluation Dataset Construction

Prompt Templates and Examples
  Initial Planner Prompt
  Planner Retry Prompt
  Synthesizer Prompt
  Temporal Bridge Retrieval Case Study
```

硕士论文中不需要完全照搬 NeurIPS 附录结构。因为第四章已经复用了主结果表，Appendix 不应重复 main benchmark tables；因为 Chalmers thesis 更重视可复现性和方法透明度，Appendix 应重点扩展 training configuration、baseline caveats、reward derivation、TimeMemEval construction 和 prompt templates。

最终建议将现有 `paper/include/backmatter/Appendix_1.tex` 从单一 appendix 扩展为多个 appendix chapters，或在同一个 `Supplementary Experimental Details` chapter 中用多个 section 组织。若模板不方便增加多个 appendix 文件，可以先全部写入 `Appendix_1.tex`，但结构上保持 A-D 的逻辑。

## Appendix A: Supplementary Experimental Details

Appendix A 负责补充第四章实验设置的细节。正文第四章只保留必要说明；Appendix A 写清楚 split、模型组合、训练实现、评估协议和 baseline 适配 caveat。

### A.1 Training and Evaluation Split

当前硕士论文已经有这一节，路径为：

`paper/include/backmatter/Appendix_1.tex`

现有内容应保留，并适当微调：

- 标题使用 `Training and Evaluation Split`，不要使用 `held-out`。
- 保留正文引用 label：`app:training-evaluation-split`。
- 保留表格 `tab:training-evaluation-split`。
- 数据与 NeurIPS 最终版一致：
  - Original questions: LoCoMo 1,986; LongMemEval 500; TimeMemEval 500; total 2,986.
  - Filtered questions: LoCoMo 1,536; LongMemEval 469; TimeMemEval 374; total 2,379.
  - Training: LoCoMo 401; LongMemEval 0; TimeMemEval 99; total 500.
  - Evaluation: LoCoMo 655; LongMemEval 469; TimeMemEval 275; total 1,399.

这一节还应补充一小段 `Example format`，说明每个训练样本存储的是 query、gold answer、gold evidence sessions、source identifier、user/speaker metadata、source bucket、difficulty label 和 evaluation mode，而不是固定 retrieved memories 或预计算 rollout traces。这样能解释为什么 GRPO 训练是 online memory-search behavior，而不是静态 context 上的 supervised learning。

### A.2 Model and Baseline Configurations

本节来自 NeurIPS 附录 `model_combo.tex` 和 `tbl/model_combo.tex`。正文第四章已经用 prose 介绍 baseline groups，但 Appendix 应给出更精确的模型组合表。

应包含：

- 每个方法的 role：full-context direct answerer、write-time memory system、search-time retrieval agent、NanoMem variant。
- Backbone / evidence model。
- Downstream answerer。
- 是否使用 fixed Qwen3.5-9B answerer。
- 是否使用 GPT-5.1 judge。
- 输出对象：final answer、retrieved notes、raw sessions、structured evidence。
- 关键 caveat：例如 Memory-T1-Qwen 不是官方 checkpoint；Search-R1 是 open-domain search QA checkpoint 适配到 memory setting。

如果 NeurIPS 的 `tbl/model_combo.tex` 可直接复用，可以复制到硕士论文 `paper/tbl/` 中并在 appendix input。若表格太宽，可以改写成 thesis 风格表。

### A.3 Training Implementation Details

本节来自 NeurIPS 附录 `training_hyperparameters.tex`。正文第四章已经写了部分关键配置，但 Appendix 应写完整版本。

应包含：

- Trainable policy：Qwen3.5-9B Synthesizer。
- Frozen components：Planner、NanoMem retriever、Qwen3.5-9B answerer、GPT-5.1 judge、reference policy。
- Algorithm：full-parameter GRPO with VERL/HybridFlow。
- Rollout：每个 prompt 采样 `K=8` trajectories，最大 3 retrieval rounds。
- Inference：最大 3 rounds，每轮 top-7 memories。
- Context / sequence limits：rollout prompt tokens、response tokens、SGLang context。
- Optimizer：AdamW。
- Learning rate：`2e-6`。
- Weight decay：`0.01`。
- Betas：`(0.9, 0.999)`。
- Adam epsilon：`1e-8`。
- Schedule：constant with 3% warmup，9 warmup steps over 300 global steps。
- PPO / GRPO details：mini-batch size 1、micro-batch size 1、clip ratio 0.2、actor KL coefficient 0.001、low-variance KL。
- Training precision / distribution：bf16、FSDP parameter and optimizer offload。
- Checkpoint：final run resumes from global step 170 and continues to step 300，save every 10 steps。
- Hardware：4 NVIDIA GH200 96GB GPUs。
- Reward setting：`(w_o,w_v,w_l)=(0.50,0.10,0.05)`，format-failure penalty `c=-0.20`。

写作提醒：这里不要重新推导 reward 公式；公式和系数分析放到 Appendix B。

### A.4 Evaluation Protocol

本节来自 NeurIPS 附录 `evaluation_protocol.tex`，但原文较短，硕士论文可以写得更完整。

应包含：

- 主指标是 answer accuracy。
- 使用 GPT-5.1 作为固定 LLM judge。
- Judge prompt 对所有方法保持一致。
- 不用 BLEU/F1 作为主指标的原因：答案可能是语义等价自然语言，尤其是时间表达和事件描述。
- LoCoMo 的 evaluation 需要注意双 speaker / conversation memory setting；如果当前实现对每个 speaker 做两次 search，应解释清楚。
- LongMemEval 和 TimeMemEval 是单用户 query setting，每个 query 独立搜索。
- Token 统计解释：
  - direct answerer: answer output tokens。
  - evidence provider: retrieved evidence / memory context tokens。
  - 不能直接等同于 full serving cost。
- Verdict accuracy 和 rounds 是 NanoMem-specific diagnostics。

### A.5 Baseline Implementation Notes

本节来自 NeurIPS 附录 `existing_system.tex`。这是 Appendix 中很重要的一节，因为 baseline 的公平性和 caveat 需要透明说明。

建议按方法逐段写：

1. **Full Context**
   - 不调用 memory system。
   - LoCoMo 使用 conversation full-history prefix。
   - LongMemEval 使用 query 的 haystack sessions。
   - TimeMemEval 使用 sample 中全部 sessions。
   - 是 strong reference baseline，但不是 memory system。

2. **Mem0**
   - 使用 local OSS Mem0 codebase。
   - Session-level ingestion。
   - 返回 Mem0 notes，而不是 raw transcripts。
   - 使用 pgvector，无 graph-store retrieval。
   - 加入同步 ingestion、JSON repair/retry、custom prompts、top-k 修复等适配。

3. **A-Mem**
   - 使用 released codebase。
   - 每个 session 通过 `add_note()` 插入。
   - Stored content 是 full transcript，而不是 atomic fact。
   - 使用 ChromaDB 和原始 add/search/evolution path。
   - token count 反映 transcript-level evidence。

4. **MemR3**
   - 使用 released codebase 和 retrieve/generate/reflect/answer workflow。
   - 将 benchmark item 转为 conversation-plus-QA format。
   - Chunk size 256、top-k 7、max iterations 5、no reranker。
   - 没有训练 MemR3。
   - caveat：禁用 reranker 可能低估最佳性能；score 是 retrieval + answer generation，不是 pure retrieval accuracy。

5. **Search-R1**
   - 使用 public HuggingFace checkpoint。
   - 作为 direct answerer 使用，遵循 `<think>/<search>/<answer>` protocol。
   - 最多 3 search calls。
   - 搜索结果以 `<information>` blocks 返回。
   - checkpoint 是 open-domain search QA 训练，不是 timestamped long-term memory 训练。

6. **Memory-T1-Qwen**
   - 官方 trained checkpoint 不可用。
   - 报告的是 Memory-T1-style Qwen3.5-9B baseline，不是官方 Memory-T1 performance。
   - 使用 session-level SimpleBM25、top-k 7、15,500-token prompt budget、temperature 0、JSON mode。
   - caveat：session-level BM25 可能漏掉 temporal bridge 的一端，Qwen3.5-9B 也没有针对 Memory-T1-style long-term temporal reasoning 训练。

正文中不要写这么细；Appendix 中写清楚即可。

## Appendix B: Algorithm and Reward Details

Appendix B 负责补充第三章 Methods 中没有完全展开的算法和 reward 公式。这里是硕士论文中最值得扩写的部分，因为 NeurIPS 受篇幅限制，reward 设计和系数推导在正文里很压缩。

### B.1 GRPO Training Procedure

本节来自 NeurIPS 附录 `algorithm_details.tex` 中的 `NanoMem Training Procedure`。

应以 algorithm block 或 enumerated procedure 展示完整 online GRPO 训练流程：

1. 输入训练样本：query、gold answer、gold evidence sessions、source DB path、user id、metadata。
2. 冻结 Planner、Retriever、Answerer、Judge、Reference policy。
3. 对每个 prompt 采样 `G=8` rollouts。
4. 每个 rollout 最多 `R_max=3` rounds。
5. 每轮：
   - Planner 生成 retrieval cues。
   - Retriever 搜索 sessions。
   - 构造 temporal hints。
   - Synthesizer 采样 XML。
   - 解析 reasoning、events、verdict。
   - 若 `sufficient`、no new evidence 或 XML invalid，则终止。
6. 使用 frozen answerer 从 terminal Temporal Evidence Pool 生成 final answer。
7. 使用 judge 评估 answer。
8. 计算 format、verdict、outcome、length reward。
9. 进行 group-relative advantage 计算。
10. 用 GRPO 更新 Synthesizer policy，且只更新 Synthesizer tokens / parameters。

写作提醒：这里要与 Methods 正文统一。Planner、Retriever、answerer、judge 都是 frozen environment components；只训练 Synthesizer。

### B.2 Reward Definition

本节来自 NeurIPS 附录 `algorithm_details.tex` 中的 `Reward Design`，也是最应该完整迁移的部分。

必须使用最终版 reward 定义：

- Trajectory: `\tau=\{(h_1,z_1),...,(h_T,z_T)\}`。
- Synthesizer action: `z_t=(r_t,\mathcal{E}_t,\hat{v}_t)`。
- Abstract trajectory: `\tau=(f,T,\mathbf{v},o,\ell)`。
- Format validity: `f(\tau)\in\{0,1\}`。
- Format gate:
  \[
  R(\tau)=c,\quad f(\tau)=0
  \]
  且不计算其他 reward。
- Length reward:
  \[
  \ell(\tau)=\mathbb{I}\{R_{\mathrm{out}}(\tau)=1\}
  \cdot
  \mathrm{clip}\left(
  1-\frac{1}{Tm_{\max}}\sum_{t=1}^{T}m(z_t),
  0,1
  \right)
  \]
- Verdict reward：
  根据 accumulated retrieved sessions 是否覆盖 gold evidence sessions 判断 `sufficient/insufficient` 是否正确。
- Outcome reward：
  最终 Temporal Evidence Pool 输入 frozen answerer，judge 判断与 gold answer 是否语义等价。
- Total reward:
  \[
  R(\tau)
  =
  \begin{cases}
  c, & f(\tau)=0,\\
  w_o o(\tau)+w_v\sum_{t=1}^{T}v_t+w_l\ell(\tau), & f(\tau)=1.
  \end{cases}
  \]
- 不引入单独 event-time reward；错误 event_time 会通过 retrieval drift 和 final answer failure 反映到 outcome reward。

必须避免旧 reward 版本：

- 不写 format 是 additive positive reward。
- 不写 verdict reward 是平均而不是累积。
- 不写 outcome 只用最后一轮 events；最终版应使用 accumulated Temporal Evidence Pool。
- 不写 `inferred` 字段或三值 verdict。
- 不写单独 temporal consistency reward / event-time reward。

### B.3 Reward Coefficient Analysis

本节来自 NeurIPS 附录 `Reward Coefficient Analysis`。硕士论文可以完整放入，因为它证明为什么系数设计不是拍脑袋。

应包含：

1. Abstract trajectory:
   \[
   \tau=(f,T,\mathbf{v},o,\ell)
   \]
2. Reward:
   \[
   R(\tau)=
   \begin{cases}
   c, & f=0,\\
   w_vV+w_o o+w_l\ell, & f=1.
   \end{cases}
   \]
3. 设计目标：
   - Format gate。
   - Outcome dominance。
   - Verdict discrimination。
   - Multi-round credit。
   - Compactness preference。
   - Verdict over length。
4. Margin definitions：
   - `\Delta_1=-3w_v-c`
   - `\Delta_2=w_o-6w_v`
   - `\Delta_3=2w_v`
   - `\Delta_4=w_l`
5. Gap hierarchy：
   \[
   \Delta_1>\Delta_2>\Delta_3>\Delta_4>0
   \]
6. Feasible coefficient region：
   \[
   \mathcal{W}=
   \left\{(c,w_v,w_o,w_l)\mid
   w_v>0,\,
   w_o>8w_v,\,
   c<3w_v-w_o,\,
   2w_v>w_l
   \right\}
   \]
7. Final coefficient choice：
   \[
   (w_o,w_v,w_l)=(0.50,0.10,0.05),\quad c=-0.20
   \]

写作提醒：这里可以比 NeurIPS 原文略微解释得更清楚，但公式必须与最终版一致。若正文 Methods 已经写过部分公式，Appendix 可以说 “This appendix expands the reward definition used in Section ...”。

## Appendix C: TimeMemEval Construction

Appendix C 负责详细说明 TimeMemEval 是怎么构造的。正文第四章只需要说明它是 diagnostic temporal-bridge benchmark；Appendix C 需要给出生成过程、验证过程和限制。

### C.1 Benchmark Construction Procedure

本节来自 NeurIPS 附录 `dataset_details.tex` 的 `TimeMemEval Benchmark Construction`。

应包含算法式描述：

1. 采样 persona/theme context。
2. 生成 source event `e_s` 和 temporal anchor。
3. 采样 bridge scope `\beta` 和 offset `\delta`。
4. 计算 target window `W^\star`。
5. 采样 terminal type `y` 和 compatible event family。
6. 在 `W^\star` 内生成 destination event `e_d`。
7. 生成 probe question `q` 和 answer `a`。
8. 生成 hard distractors：
   - same-activity distractor。
   - answer-alias distractor。
   - near-window distractor。
   - source-anchor-alias distractor。
9. 生成 filler events。
10. 用 judge 检查 uniqueness 和 answerability。
11. 将事件 realization 成 multi-turn sessions。
12. 对 session temporal consistency 做验证。
13. 输出 record、sessions、traces、split metadata 和 validation logs。

本节应强调：TimeMemEval 不是通用 temporal reasoning benchmark，而是 targeted temporal-bridge retrieval stress test。

### C.2 Filtering and Validation

本节扩展 TimeMemEval filtering 逻辑。

应说明：

- 原始生成 500 candidates。
- 过滤 invalid generation attempts。
- 过滤 duplicates。
- 过滤 split leakage。
- 过滤 incomplete metadata。
- 过滤 temporal inconsistency。
- 过滤 answer non-uniqueness。
- 最终保留 374 filtered records。
- 其中 99 training，275 evaluation。

同时说明 benchmark 限制：

- 不覆盖所有 temporal reasoning。
- 不覆盖复杂长因果链、belief revision、recurring habits、partial temporal order、contradictory memories。
- 它的价值在于可控地测试 evidence addressability gap。

## Appendix D: Prompt Templates and Case Study

Appendix D 负责提供 prompt 细节和一个可读案例。Prompt 模板对于复现实验非常重要，也能帮助读者理解 NanoMem 的 planner/synthesizer 角色边界。

### D.1 Initial Planner Prompt

来自 NeurIPS 附录 `prompt_templates.tex` 的 `Prompt Template of Initial Planner`。

应完整放入 prompt box，内容包括：

- Planner 角色：memory retrieval planner。
- 输入：user query。
- 输出：XML `<cues>`。
- Rules：
  - 分解 query 为 focused retrieval cues。
  - 保留 named entities、dates、locations、event types、quantities、temporal semantics。
  - dependent temporal questions 需要 original standalone cue + support cues。
  - 不 annotate temporal phrases，因为 deterministic preprocessing 会处理。

### D.2 Retry Planner Prompt

来自 NeurIPS 附录 `Prompt Template of Planner Retry`。

应完整放入 prompt box，内容包括：

- 输入：
  - original query。
  - previous cues。
  - Temporal Evidence Pool。
  - previous Synthesizer reasoning。
- 输出：新的 XML `<cues>`。
- 规则强调：
  - 根据 previous reasoning 中 identified gap 生成 1--3 cues。
  - 如果发现 anchor/bridge entity/place/time，就用它生成新 cue。
  - 不重复 previous cues，除非换 temporal anchor 或 framing。

### D.3 Synthesizer Prompt

来自 NeurIPS 附录 `Prompt Template of Synthesizer`。

应完整放入 prompt box。必须保持最终 schema：

```xml
<reasoning>...</reasoning>
<events>
  <event
    session_id="..."
    session_time="..."
    event_time="...">
    ...
  </event>
</events>
<verdict>sufficient|insufficient</verdict>
```

Prompt 中应保留：

- 输入：
  - normalized query。
  - retrieved sessions。
  - temporal hints。
  - Temporal Evidence Pool / previous events。
- rules：
  - verdict only `sufficient|insufficient`。
  - event_time 解析相对表达。
  - final events output cumulative。
  - previous events still valid 时原样保留。
  - one event per distinct evidence item。
  - no nested tags / no markdown。
  - all three attributes required。

注意：如果 prompt 原文中出现 “temporal hints from query” 等表述，应与当前 thesis Methods 对齐：temporal hints 可以包含 query temporal extraction 与 previous Synthesizer outputs，但最终正文必须以 NeurIPS 最终版为准。

### D.4 Temporal Bridge Case Study

来自 NeurIPS 附录 `Case Study: Temporal Bridge Retrieval`。

建议保留这个案例，因为它直观展示 NanoMem 如何把 first-round bridge evidence 转换成 second-round temporal retrieval cue。

案例核心：

- Query: “What did Haruki read 4 months after sorting through old notebooks and setting aside pages that could become personal essays?”
- Round 1 找到 notebook-sorting bridge session。
- Session timestamp 是 2024-04-18，文本中 “2 months ago” 推出 sorting event 在 February 2024。
- 问题问 four months after，所以目标窗口是 June 2024。
- Round 1 没有 June reading evidence，因此 verdict 是 `insufficient`。
- Retry cues 包含 June 2024 reading。
- Round 2 找到 2024-06-08 session，Haruki read *The Death and Life of Great American Cities*。
- Final synthesis 保留 bridge event，追加 June reading event，verdict `sufficient`。

这个案例可以作为 Appendix 最后一节，也可以在答辩时用来解释 evidence addressability gap。

## 不建议迁移的内容

以下 NeurIPS 附录内容不建议直接放入硕士论文，或只需要很轻量提及。

### Main Benchmark Results

NeurIPS 附录中 `main_results_tables.tex` 只是引用主文中的详细表。硕士论文第四章已经放了核心主结果表和各 benchmark 表，不需要在 Appendix 重复。

### Time-Dialog Full-Context Prompting

`timedialog_full_context.tex` 是关于 Time-Dialog full-context rows 的说明。当前硕士论文正文没有围绕 Time-Dialog 展开，且 benchmark 名称和重点已经统一为 LoCoMo、LongMemEval 和 TimeMemEval，因此不建议迁移。

### NeurIPS Checklist

`checklist.tex` 是 NeurIPS 投稿要求，不属于 Chalmers thesis appendix。不要迁移。

### 旧名字与旧 schema

迁移任何内容时必须统一：

- 正文可见名称使用 `TimeMemEval`，不使用 `ChainMem`。
- verdict 是二值：`sufficient` / `insufficient`。
- event schema 不包含 `inferred` 字段。
- 不使用 `indicative` verdict。
- reward 按最终版 format gate + outcome/verdict/length 组合。

## 计划中的最终 Appendix 目录

建议最终 LaTeX 结构如下：

```text
Appendix A Supplementary Experimental Details
  A.1 Training and Evaluation Split
  A.2 Model and Baseline Configurations
  A.3 Training Implementation Details
  A.4 Evaluation Protocol
  A.5 Baseline Implementation Notes

Appendix B Algorithm and Reward Details
  B.1 GRPO Training Procedure
  B.2 Reward Definition
  B.3 Reward Coefficient Analysis

Appendix C TimeMemEval Construction
  C.1 Benchmark Construction Procedure
  C.2 Filtering and Validation

Appendix D Prompt Templates and Case Study
  D.1 Initial Planner Prompt
  D.2 Retry Planner Prompt
  D.3 Synthesizer Prompt
  D.4 Temporal Bridge Case Study
```

如果不想创建多个 appendix files，可以先把所有内容写入 `paper/include/backmatter/Appendix_1.tex`，使用 `\chapter` 和 `\section` 区分。若后续内容过长，再拆成 `Appendix_2.tex`、`Appendix_3.tex` 等，并在 `Main.tex` 中分别 input。

## 写作优先级

如果时间有限，优先级如下：

1. **必须写**：A.1、A.3、B.2、B.3、C.1、D.3。
2. **强烈建议写**：A.2、A.4、A.5、B.1、C.2。
3. **可选但很有用**：D.1、D.2、D.4。

理由：

- A.1/A.3 保证实验可复现。
- B.2/B.3 保证 reward 设计严谨且与 NeurIPS 最终版一致。
- C.1 解释 TimeMemEval 作为本文核心 diagnostic benchmark 的来源。
- D.3 解释 Synthesizer 最关键的行为约束。
- Baseline notes 和 case study 则用于增强透明度和可读性。
