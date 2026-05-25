# 论文审查报告：NanoMem 硕士毕业论文

生成日期：2026-05-25  
审查依据：Chalmers 规范 C 2025-0611、thesis_rules.md、project_contexts.md，以及三篇参考论文（ref1–ref3）  
审查范围：Introduction.tex、Theory.tex、Methods.tex、Results.tex、Conclusion.tex、Appendix_1.tex、frontmatter/\*、Settings.tex、Titlepage.tex

---

## 第一类：规则合规性错误（Rule Compliance Issues）

> 此类问题的判断依据是 Chalmers 规范 C 2025-0611 和 thesis_rules.md 中的硬性要求。

---

### ★★★ 高严重性

---

#### R1. Abstract 字数不足且风格不符合硕士论文要求

**问题位置：** `paper/include/frontmatter/Abstract.tex`

**问题描述：**  
当前摘要约 **220 词**，低于 Chalmers 规定的 **250–350 词**下限（C 2025-0611 第 8.2 节，Design and Publish 页面）。更重要的是，摘要的写法完全照搬了 NeurIPS 会议论文摘要的风格——开篇直接跳入技术问题，没有设置研究背景、目的和范围，整体是贡献导向的压缩式表述。这与 Chalmers 对硕士论文摘要的预期不符：摘要应当总结研究目的（purpose）、方法（method）和结论（results/conclusion），让非专业读者也能获得完整图景。

**规则证据：**  
- C 2025-0611 第 8.2 节："concise, between 250 and 350 words"，"summarize the work's essential problem, methods, and results"。
- thesis_rules.md 第 5 条。

**参考论文处理方式：**  
- **ref1（Test Maintenance）**：摘要先介绍研究背景和动机，再描述三阶段研究过程，最后报告发现，使用第三人称客观描述。
- **ref3（LLM Tools for Engineering）**：摘要先设置问题场景（"Generative AI shows great promise..."），介绍研究路径（文献研究+9次工程师访谈），然后描述系统设计，最后提出结论和局限。
- **改进思路：** 在现有内容前增加 2–3 句背景句（为什么长期记忆对 LLM agent 重要、现有系统的根本缺陷），在现有内容后增加 1–2 句研究局限/意义句，使总词数达到 260–300 词，并将第一人称 "We" 风格调整为 "This thesis investigates..." 或 "NanoMem is proposed as..."。

---

#### R2. Introduction 缺少 Scope and Delimitations 小节

**问题位置：** `paper/include/Introduction.tex`

**问题描述：**  
当前 Introduction 章节包含：Significance of the Study、Problem Description、Purpose of the Study、Thesis Outline，但**没有 Scope and Delimitations**（研究范围与界定）小节。这是 Chalmers 硕士论文引言的标准组成部分，也是 planning report 的必要内容（C 2025-0611 第 8.1 节）。该小节应说明研究边界：本文只研究查询时证据构建而非写入时记忆管理、只测试英文对话数据集、只训练 Synthesizer 而非完整系统、评估局限于三个基准测试等。

**规则证据：**  
- C 2025-0611 第 8.1 节 planning report 要求列出"Limitations"。
- thesis_rules.md "Practical Implications"节："The thesis should add explicit research questions; scope and delimitations..."
- Chalmers Writing Guide 强调 Introduction 需包含 scope/delimitations。

**参考论文处理方式：**  
- **ref1**：Introduction 章节有独立的 "Scope" 小节，明确说明不覆盖哪些情形。
- **ref3**：Introduction 中有 "Delimitations" 小节，说明不研究 fine-tuning 的哪些方向、不涵盖哪些工程场景。
- **改进思路：** 在 "Purpose of the Study" 之后、"Thesis Outline" 之前增加一个 `\section{Scope and Delimitations}` 小节，篇幅约 200–300 词，明确列出：(1) 只研究对话式 agent 记忆，不研究文档 RAG；(2) 评估仅限于 LoCoMo/LongMemEval/TimeMemEval；(3) 只训练 Synthesizer；(4) 不覆盖多语言、多模态、实时部署场景。

---

#### R3. Theory.tex 仅有 Related Work，缺少独立的理论/背景章节

**问题位置：** `paper/include/Theory.tex`（文件名为 Theory，但 `\chapter{Related Work}`）

**问题描述：**  
文件 Theory.tex 的章节标题是 `\chapter{Related Work}`，内容也完全是五个相关工作综述小节（LLM Agents、Long-Term Agent Memory、RAG、Temporal Reasoning、RL for Agent Memory）。**没有独立的理论背景章节**，没有对 LLM 技术本身的基础介绍，没有对 evidence synthesis/faithfulness 概念的教学性解释，没有对 GRPO 算法的独立背景介绍。对于一个可能对 LLM 细节不熟悉的 Chalmers 审查委员，缺少这个层次的背景解释会导致后续 Methods 章节难以评估。

同时，文件名是 Theory.tex 但内容是 Related Work，导致目录中显示 "Related Work" 而非预期的 "Background" 或 "Theory"。

**规则证据：**  
- thesis_rules.md "Suggested Thesis Structure / Background/Theory" 节列出需要覆盖的背景内容包括：LLM agents 和 long-term memory、RAG、write-time vs search-time memory、temporal reasoning、**evidence synthesis/faithfulness/hallucination**、RL 或 preference optimization 概念。
- C 2025-0611 Appendix 1 "Knowledge and Relation to Current Research"：High Quality 要求"written literature review"并"reflection on how the thesis connects to the forefront of knowledge"。

**参考论文处理方式：**  
- **ref1**：有独立的 "Background" 章节（LLM 基础、agent 架构基础），之后才是 "Related Work"。
- **ref3**：有 "Theoretical Background" 章节，提供 LLM、RAG 等技术的教学性介绍，之后另有 "Related Work" 节。
- **改进思路：** 有两种处理方案：(A) 将现有 Related Work 内容的章节名改为 "Background and Related Work"，并在每个小节的开头增加 1–2 段教学性解释（而非直接列举文献）；(B) 新建 `Background.tex`，提供 LLM/Transformer/RLHF/temporal reasoning 的基础背景，并把当前内容定位为 Related Work，形成两个独立章节。方案 A 改动较小，但仍需要在每节前增加 pedagogical 内容。

---

#### R4. Acknowledgements 中 Per Thoren 与 Titlepage 中督导列表不一致

**问题位置：** `Acknowledgements.tex` 第 1–2 行 vs `Titlepage.tex` 第 9 行

**问题描述：**  
Acknowledgements 第一句："I would first like to express my sincere gratitude to Mats Granath and **Per Thoren** for their continuous support throughout my master's thesis work at EPFL." 但 Titlepage 中的督导列表只有：`\ThesisSupervisor{Mats Granath and Sanidhya Kashyap}`，**Per Thoren 从未出现在标题页**。同时后续文字把 Sanidhya Kashyap 单独介绍为"my supervisor at EPFL RS3Lab"。

这会让考官产生困惑：论文的正式督导到底是谁？若 Per Thoren 是官方督导之一，应加入标题页；若 Per Thoren 仅是同事，Acknowledgements 的措辞需要修正。无论如何，目前两处信息相互矛盾，不符合学术诚信规范。

**规则证据：**  
- C 2025-0611 第 8.2 节：imprint page 需正确记录 supervisor/examiner 信息。
- 三篇参考论文 imprint 页都与 acknowledgements 中提及的督导姓名一致。

**改进思路：** 明确 Per Thoren 的实际角色，与督导和系主任确认。若是正式联合督导，在标题页中加入；若只是协助者，将 Acknowledgements 第一句改为"I would like to thank Mats Granath, Per Thoren, and Sanidhya Kashyap for their support..."，并在之后分别介绍各人的角色，避免混淆正式督导关系。

---

### ★★ 中严重性

---

#### R5. Imprint 页缺少打印公司信息

**问题位置：** `Titlepage.tex` 第 146 行

**问题描述：**  
Imprint 页有一行被注释掉：`%Printed by Chalmers Reproservice\\`。Chalmers 格式要求 imprint 包含"name of printing firm or department"。三篇参考论文 imprint 页均写有 "Printed by Chalmers Reproservice"（ref2 ref3 均可见）。

**改进思路：** 取消注释即可：`Printed by Chalmers Reproservice\\`。如果最终选择不打印，也建议保留电子出版备注。

---

#### R6. 封面 Programme 名称为"Physics"，须确认准确性

**问题位置：** `Titlepage.tex` 第 8 行：`\ThesisProgramme{Physics}`

**问题描述：**  
封面生成文字"Master's Thesis in Physics"。这对于一篇关于 LLM Agent 记忆的 AI 论文来说非常反常。如果学生确实在物理专业项目，这个信息是正确的；但如果实际专业是 Computer Science and Engineering 或 Applied Mathematics，这是一个严重错误。

**改进思路：** 确认 Chalmers 学籍系统中的正式专业名称，并对应更新 `\ThesisProgramme` 和 `\ThesisDepartment`。参考论文显示专业名称格式如："Computer Science and Engineering"（ref1）、"Systems, Control and Mechatronics"（ref2）。

---

#### R7. Conclusion 章节中 RQ 小节标题过于简化

**问题位置：** `Conclusion.tex` 第 16、59、110 行

**问题描述：**  
三个研究问题的小节直接标题为 `\section{RQ1}`、`\section{RQ2}`、`\section{RQ3}`。这不符合 Chalmers 对章节结构的质量期望（"good coherence, structure, and layout"）。审查委员在目录中看到的是 "4.1 RQ1 / 4.2 RQ2 / 4.3 RQ3"，没有任何信息传达各部分的论点内容。

**参考论文处理方式：**  
- **ref1** Conclusion 章节用描述性标题，如 "Conclusions on RQ1: Predicting Test Maintenance Need"。
- **改进思路：** 将三个标题改为描述性形式，例如：
  - `\section{RQ1: Query-Time Evidence Construction}` 
  - `\section{RQ2: Multi-Hop Temporal Evidence Recovery}`
  - `\section{RQ3: Reinforcement Learning for Synthesizer Training}`

---

#### R8. Methods 章节缺少研究方法论定位

**问题位置：** `Methods.tex` 整体结构

**问题描述：**  
Methods 章节直接进入问题形式化和系统设计，没有说明这是什么**类型的研究**（设计科学？实验研究？原型研究？），以及为什么这种方法适合这个研究问题。C 2025-0611 Appendix 1 "Method Choice and Justification" 明确要求："identification of relevant theories/methods, justified choice of theory/method, and correct application."

**参考论文处理方式：**  
- **ref1**：Method 章节开头有一节专门说明研究方法论（exploratory case study），并论证为什么 case study 适合这类 AI 系统研究。
- **ref3**：Method 章节开头介绍 "Research Methodology"，说明是 iterative design approach。
- **改进思路：** 在 Methods 章节开头（Problem Formulation 之前）增加一个 `\section{Research Approach}` 或将 Overview 节改写为先说明方法论立场：这是一项设计性实验研究，通过系统设计 + 基准实验来回答研究问题。

---

#### R9. 缺少明确的 Validity Threats 讨论

**问题位置：** `Conclusion.tex`（Limitations 小节）

**问题描述：**  
论文有 Limitations 小节，列出了 6 条局限性，但没有明确的研究有效性威胁分析（threats to validity），包括内部有效性（internal validity）、外部有效性（external validity）、构建有效性（construct validity）。这是 Chalmers 硕士论文质量标准中的常见要求——Limitations 和 Validity Threats 是不同层次的讨论。

**参考论文处理方式：**  
- **ref1**：有单独的 "Threats to Validity" 小节，分析 internal/external/construct validity。
- **改进思路：** 可在现有 Limitations 小节中加入一个子节 `\subsection{Threats to Validity}`，或扩展现有第 4 条（evaluation dependence）和第 5 条（benchmark coverage）内容，用 validity 框架重新组织，明确哪些威胁影响内部有效性（如 judge 偏差），哪些影响外部有效性（如 benchmark 覆盖范围）。

---

## 第二类：逻辑与语言错误（Logic and Language Issues）

> 此类问题基于论文内容与 NeurIPS 原文的一致性、前后逻辑连贯性和学术语言规范。

---

### ★★★ 高严重性

---

#### L1. Abstract 中的百分比改进数字与正文无法对应，基线未明确

**问题位置：** `Abstract.tex` 最后两句

**问题描述：**  
摘要末尾写道："improving over the strongest prior memory methods by **12.5, 11.8, and 31.0 percentage points** on LoCoMo, LongMemEval, and TimeMemEval, respectively"。但在 Results 章节：

- LoCoMo：NanoMem-GRPO = 88.6%，最接近的竞争者是 GPT-5.1 full context = 87.7%（差距仅 0.9pp），而非 12.5pp。如果是与 Mem0 对比，Mem0 的 LoCoMo 总体分数在正文中**没有直接列出**。
- LongMemEval：NanoMem-GRPO = 83.8%，GPT-5.1 FC = 63.6%（差距 20.2pp，超过 11.8pp）。
- TimeMemEval：NanoMem-GRPO = 51.5%，MemR³ = 12.0%（差距 39.5pp，超过 31.0pp）。

这些数字**在正文中无法找到对应的明确基线比较**，读者无法验证摘要中的宣称。这是从 NeurIPS 论文摘要直接照搬造成的，会导致论文逻辑上不自洽。

**改进思路：** 在摘要中指明基线，例如："improving over the best competing memory method (MemR³) by X.X, X.X, and X.X percentage points"。或者改用在正文中明确出现的比较数字。同时确保 Results 章节有对应的明确对比句子。

---

#### L2. Abstract 声称"state-of-the-art"但正文始终使用"best overall accuracy"，且 TimeMemEval 为自建数据集

**问题位置：** `Abstract.tex` 第 35–36 行 vs `Results.tex` 各处

**问题描述：**  
摘要："NanoMem achieves **state-of-the-art performance** across all three benchmarks."  
Results 章节始终用："NanoMem-GRPO obtains the **best overall accuracy**"。

两者用词不一致。更重要的是，TimeMemEval 是本论文自己构建的诊断基准——在自建测试集上声称 SOTA 有潜在的循环论证问题，因为没有其他独立工作能提前针对这个测试集优化。NeurIPS 论文在这种声明上可能可以接受，但硕士论文的评审更严格，这种表述可能被考官质疑。

**改进思路：** 将摘要中"state-of-the-art"替换为"best reported accuracy"或"highest accuracy among compared methods"，与正文措辞保持一致，并加注脚说明 TimeMemEval 是本论文构建的诊断测试集，其结果仅为诊断性比较。

---

#### L3. 全文正文使用"we"但这是单人作者论文

**问题位置：** Results.tex、Methods.tex、Conclusion.tex 各处

**问题描述：**  
论文正文自始至终使用第一人称复数 "we"（"We evaluate NanoMem on..."，"We compare NanoMem with four groups..."，"We start from 1,986 LoCoMo questions..."），但这是 Youliang Zhu 一人的硕士论文（Acknowledgements 和 Titlepage 均确认是单人作者）。这种写法来自 NeurIPS 多作者论文，移植进单人硕士论文后显得不自然，且与论文的 single-author 性质矛盾。

**改进思路：** 有两种选择：(A) 全文将 "we" 替换为被动语态或第三人称（"NanoMem is evaluated on..."，"The experiment compares..."），这是 Chalmers 学术写作更传统的风格；(B) 保留 "we"，在 Methods 章节或序言中注明 "this thesis was conducted as part of a research collaboration"，表明 "we" 指研究团队而非仅作者本人。从 Acknowledgements 内容来看，选项 B 有依据（Pan、Zheng 等人参与了工作）。建议与导师确认后统一处理。

---

### ★★ 中严重性

---

#### L4. Introduction 和 Theory 章节对 session time/event time 的例子重复

**问题位置：** `Introduction.tex` 第 130–135 行 vs `Theory.tex` 第 147–153 行

**问题描述：**  
Introduction 的 Problem Description 节和 Theory 的 RAG 节都使用了**完全相同的 April 2 旅行例子**来解释 session time 和 event time 的区别：
- Introduction："If a user says on April 2 that they travelled to Europe last week, April 2 is the session time, but the travel event belongs to the previous week."
- Theory："If a user says in an April 2 session that they travelled to Europe last week, the session date and the travel date are different."

一个读者在两处会读到几乎相同的例子和解释，造成内容冗余感。

**改进思路：** 在 Introduction 中保留该例子（作为问题引入），在 Theory/RAG 节中换用不同的例子，或直接交叉引用（"as illustrated earlier in Section~\ref{sec:intro-problem-description}"），避免重复。

---

#### L5. Conclusion 首段在未介绍宏的情况下使用 `\sys{}` 和 `\bench{}`

**问题位置：** `Conclusion.tex` 第 8–9 行

**问题描述：**  
Conclusion 章节开篇第一句就使用了 `\sys{}` 和 `\bench{}` 宏（展开为 NanoMem 和 TimeMemEval）。虽然这些宏在 Settings.tex 中全局定义，LaTeX 能正常展开，但在章节第一次出现这些术语时，学术写作惯例要求先用全名，括号内跟缩写，例如 "NanoMem (hereafter NanoMem)" 或 "TimeMemEval (referred to as \bench{})"。

这主要是一个写作规范问题，但在 Chalmers 对文章清晰度的要求下值得注意。

**改进思路：** 将 Conclusion 开篇第一次出现改为全称，例如："Chapter~\ref{chap:experiment-analysis} showed that NanoMem improves accuracy..."，之后继续使用宏。

---

#### L6. Results 章节有两个重复的 `\label` 命令

**问题位置：** `Results.tex` 第 3–4 行

**问题描述：**  
```latex
\label{chap:experiment-analysis}
\label{chap:results}
```
同一个 `\chapter` 命令后面跟着两个不同的 label，这会产生 LaTeX 警告，且容易造成维护混乱。Introduction 的 Thesis Outline 通过 `\ref{chap:results}` 引用该章节，而同一章节还有 `chap:experiment-analysis` 标签。

**改进思路：** 统一使用一个标签（如 `\label{chap:results}`），然后全文检索是否有其他地方使用了 `chap:experiment-analysis`，将其改为一致的标签。

---

#### L7. Abstract 关键词未覆盖论文核心概念"evidence synthesis"和"conversational memory"

**问题位置：** `Abstract.tex` 第 42–43 行

**问题描述：**  
当前 8 个关键词："agent memory, large language models, retrieval, RAG, reinforcement learning, GRPO, temporal reasoning, NanoMem"。

论文的核心概念 **"evidence synthesis"**（证据合成，整个论文的核心术语）和 **"conversational memory"**（对话式记忆，区分本文与文档 RAG 的关键词）均不在关键词中。同时 "NanoMem" 作为系统名称放入关键词，对数据库检索价值有限。

**改进思路：** 调整关键词，例如："agent memory, large language models, evidence synthesis, conversational memory, iterative retrieval, temporal reasoning, reinforcement learning, GRPO"（共 8 个，仍在 10 个上限内）。

---

#### L8. Conclusion 中 Implications 小节与 RQ 缺乏显式映射

**问题位置：** `Conclusion.tex`，Implications 小节（第 153–186 行）

**问题描述：**  
Implications 小节提出了四个"含义"，但没有明确说明哪个 implication 是对哪个 RQ 的延伸，也没有说明这些 implications 在多大程度上超出了 RQ 的答案范围。读者（以及考官）需要自行判断 RQ1/2/3 与四个 implications 的关系，这降低了论文结构的透明度。

**改进思路：** 在 Implications 小节开头加一句导引："These implications follow from the answers to RQ1, RQ2, and RQ3. The first implication (evidence construction vs. storage capacity) extends RQ1; the second (output boundary design) bridges RQ1 and RQ2; the third (event time as search state) is central to RQ2; the fourth (complementarity of write-time and query-time) integrates all three."

---

### ★ 低严重性

---

#### L9. 标题页"master thesis"缺少所有格撇号

**问题位置：** `Titlepage.tex` 第 97 行

**问题描述：**  
```latex
\textsc{\large Master thesis 2026}
```
应为：
```latex
\textsc{\large Master's thesis 2026}
```
封面和 imprint 页都使用了 "Master's Thesis"（带撇号），但内页标题行漏掉了撇号。三篇参考论文内页标题均使用 "Master's Thesis 20XX"。

**改进思路：** 将第 97 行改为 `\textsc{\large Master's thesis 2026}`。

---

#### L10. Introduction 的 Thesis Outline 中缩写词首次出现时未展开

**问题位置：** `Introduction.tex` 第 226–232 行（Thesis Outline 节）

**问题描述：**  
Thesis Outline 提到："including temporal evidence representation, the Planner--Retriever--Synthesizer loop, **GRPO** training, reward design, and the construction of TimeMemEval."这是 GRPO 在论文中第一次出现（摘要在 frontmatter 属于独立部分），但没有在此展开定义（Group Relative Policy Optimization）。读者在 Thesis Outline 中第一次遇到这个缩写时，Methods 章节还没有开始，因此无法预知其含义。

**改进思路：** 改写为 "GRPO (Group Relative Policy Optimization) training"，或在此处加一个简短括号说明 "GRPO, a reinforcement learning algorithm,"。

---

#### L11. 论文缺少 Contributions 小节或清单

**问题位置：** `Introduction.tex`（Purpose 节 vs 无 Contributions 小节）

**问题描述：**  
论文用 RQ 组织了研究目的，但没有明确的 "Contributions" 小节，没有逐条列出本论文的贡献。三篇参考论文均在 Introduction 的 Purpose/Aim 节后有"Contributions"小节或对贡献的逐条总结。Chalmers 评分标准要求"contribution to research and development work must be clearly presented"。

**改进思路：** 在 "Purpose of the Study" 节末或 "Thesis Outline" 前增加一个简短段落或 itemize 列表，明确列出本论文的四到五项主要贡献，例如：(1) 形式化 temporal evidence-state construction 问题；(2) 提出 Planner-Retriever-Synthesizer 循环；(3) 设计包含 verdict 信号的多层奖励；(4) 构建 TimeMemEval 基准；(5) 展示 GRPO 对 Synthesizer 的有效性。

---

## 汇总优先级列表

| 优先级 | 编号 | 类型 | 一句话描述 |
|--------|------|------|-----------|
| P1 | R1 | 规则 | Abstract 字数不足（220词，低于250词最低要求）且风格为NeurIPS论文风格 |
| P1 | L1 | 逻辑 | Abstract 改进百分比（12.5/11.8/31.0pp）在正文中无法找到对应基线比较 |
| P1 | L2 | 逻辑 | Abstract 中"state-of-the-art"与正文"best accuracy"措辞不一致，自建集上宣称SOTA有逻辑问题 |
| P1 | R4 | 规则 | Acknowledgements 中 Per Thoren 与 Titlepage 督导名单不一致 |
| P2 | R2 | 规则 | Introduction 缺少 Scope and Delimitations 小节 |
| P2 | R3 | 规则 | Theory.tex 只有 Related Work，缺少教学性理论背景，章节名与文件名不匹配 |
| P2 | L3 | 语言 | 全文使用"we"但单人作者，需统一处理策略并与导师确认 |
| P3 | R5 | 规则 | Imprint 页打印公司行被注释，需取消注释 |
| P3 | R6 | 规则 | 封面专业名称"Physics"需确认是否准确 |
| P3 | R7 | 规则 | Conclusion RQ 小节标题太简短，应改为描述性标题 |
| P3 | R8 | 规则 | Methods 章节缺少研究方法论定位段落 |
| P3 | R9 | 规则 | 缺少明确的 Threats to Validity 讨论 |
| P4 | L4 | 逻辑 | Introduction 和 Theory 章节对 April 2 例子重复使用 |
| P4 | L5 | 语言 | Conclusion 首段宏首次出现未展开全名 |
| P4 | L6 | 语言 | Results.tex 有两个重复的 `\label` 命令 |
| P4 | L7 | 逻辑 | 关键词缺少"evidence synthesis"和"conversational memory" |
| P4 | L8 | 逻辑 | Implications 小节与 RQ 缺乏显式映射 |
| P5 | L9 | 语言 | 标题页"master thesis"缺少撇号 |
| P5 | L10 | 语言 | GRPO 在 Thesis Outline 首次出现时未展开 |
| P5 | L11 | 逻辑 | 缺少明确的贡献（Contributions）小节或清单 |
