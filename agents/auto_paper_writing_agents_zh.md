# 自动化毕业论文写作系统 —— 架构与工作流思路文档

> **本文档定位**:这是一份写给**作者本人**的 roadmap / 思路文档,用来指导你在本地编写两个 agent 的提示词、组织目录、搭建工作流。它**不投入运行时**,两个 agent 不会读它。文档里出现的 YAML / 目录结构是**设计规格**,不是要直接交给 agent 的 prompt。真正的 prompt(`writer.md` / `expert.md`)由你照着本文最后的"字段清单"自己写。

---

## 0. 一句话概括

把整套系统理解为一个**基于状态机的 Writer–Reviewer 同步协议**:写作 agent 是唯一能改论文源文件的人,评估 agent 只读论文、只写评审;两者从不抢同一个文件,而是通过各自专属的状态文件交换信号,按"一轮一轮"严格推进,因此天然无写冲突。

整个系统的正确性只依赖**两条不变量**:

1. **写权限单一所有者**:每个会被写的文件/目录,有且只有一个角色能写。
2. **回合互斥**:任意时刻,只有"持球方"在干活并推进状态;非持球方只读、只等待。

只要这两条守住,后面所有"为什么不冲突"的论证都成立。

---

## 1. 四层架构

顶层有两个平级目录:`agents/`(系统的全部控制/资源/编排逻辑)和 `paper/`(论文真实产物)。三个子层放在 `agents/` 下,执行层就是 `paper/`。

### 1.1 资源层 —— `agents/resources/`(对 agent 只读)

存放一切**输入上下文**,任何 agent 只读不写。它是"原材料仓库",内容在项目开始前就基本固定。

| 文件/目录 | 内容 | 谁写 |
|---|---|---|
| `neurips_paper/` | 会议论文原文 + tex 源 | human(项目初始化时放入) |
| `source_code/` | 实验项目代码 | human |
| `reference_theses/` | 三篇往届硕士毕业论文范文 | human |
| `thesis_rules.md` | 学校官方要求与模板**原文**(不可变) | human |
| `git_history.md` | 提炼过的历史 commit 摘要 | human |
| `project_contexts.md` | 项目简单背景说明,帮 agent 快速进入状态 | human |

> **关键区分**:`thesis_rules.md` 是"法律原文",只读、不可变;而下面控制层里的 `spec.md` 是从它派生出来、且会随迭代不断补全的"判例细则"。两者不要混。

### 1.2 控制层 —— `agents/control/`(身份与标准,基本静态,human 写)

回答**"他们是谁 + 什么算好"**。这一层管"评判尺子",改它 = 改评判标准。

| 文件 | 作用 | 谁写 |
|---|---|---|
| `spec.md` | 验收标准 / rubric / 最终目标。派生自 `thesis_rules.md`,**活文档**(随 v1 暴露的缺口持续补全) | human |
| `writer.md` | 写作 agent 的角色定义(prompt) | human |
| `expert.md` | 评估 agent 的角色定义(prompt) | human |

### 1.3 编排层 —— `agents/orchestrator/`(协议 + 运行时状态)

回答**"怎么交接 + 现在到哪了"**。这一层管"传球规则和比分牌",改它 = 改流程。

| 文件/目录 | 作用 | 谁写 |
|---|---|---|
| `workflow.md` | 阶段定义、三轮升级规则、交接/commit 约定(静态协议) | human |
| `writer_state.yaml` | 写作 agent 的状态信号文件 | **仅写作 agent** |
| `reviewer_state.yaml` | 评估 agent 的状态信号文件 | **仅评估 agent** |
| `open_questions.md` | 三轮未收敛的遗留疑问,留给 human 裁决 | **仅写作 agent** |
| `reviews/` | 每轮单独成文件的评审记录 | **仅评估 agent** |

### 1.4 执行层 —— `paper/`(论文产物,仅写作 agent 写)

| 文件/目录 | 作用 | 谁写 |
|---|---|---|
| `outline/01_introduction.md … 05_discussion.md` | **阶段一**产物:五份中文思路文档 | **仅写作 agent** |
| `Main.tex` / `include/` | **阶段二**产物:LaTeX 正文 | **仅写作 agent** |
| `figure/` | 图占位(图本身后续由 human 放) | human / 写作 agent 占位 |
| `refs.bib` | 参考文献(阶段二边写边插) | **仅写作 agent** |
| `Makefile` / `build/` | 编译 | — |

### 1.5 完整目录树

```
MASTER_THESIS/
├── agents/
│   ├── resources/                 # 资源层(只读)
│   │   ├── neurips_paper/
│   │   ├── source_code/
│   │   ├── reference_theses/
│   │   ├── thesis_rules.md
│   │   ├── git_history.md
│   │   └── project_contexts.md
│   ├── control/                   # 控制层(身份与标准,human 写)
│   │   ├── spec.md
│   │   ├── writer.md
│   │   └── expert.md
│   ├── orchestrator/              # 编排层(协议 + 运行时状态)
│   │   ├── workflow.md
│   │   ├── writer_state.yaml       # 仅 writer 写
│   │   ├── reviewer_state.yaml      # 仅 expert 写
│   │   ├── open_questions.md        # 仅 writer 写
│   │   └── reviews/                 # 仅 expert 写
│   │       ├── p1_intro_r1.md
│   │       └── ...
│   ├── auto_paper_writing_agents.md  # ← 本文档(roadmap,不投入运行)
│   └── README.md
└── paper/                          # 执行层(仅 writer 写)
    ├── outline/
    │   ├── 01_introduction.md
    │   ├── 02_related_work.md
    │   ├── 03_methods.md
    │   ├── 04_results.md
    │   └── 05_discussion.md
    ├── Main.tex
    ├── include/   figure/   build/
    ├── refs.bib
    └── Makefile
```

---

## 2. 通信与状态协议

### 2.1 两个状态文件:各自单写者

不用一个共享 state 文件,而用两个专属文件,这样连"协调文件"本身都满足单写者不变量:

- `writer_state.yaml` —— **只有写作 agent 写**,评估 agent 只读。
- `reviewer_state.yaml` —— **只有评估 agent 写**,写作 agent 只读。

任意时刻,谁该动取决于自己读到的对方状态,而不是去抢一个共享文件。

### 2.2 字段设计(schema,非 prompt)

`writer_state.yaml` 建议字段:

```yaml
round_id: 7                  # 全局单调递增,仅用于日志/排序
phase: 1                     # 1 = 写中文 outline;2 = 写 LaTeX 正文
section: introduction        # 当前章节
section_round: 2             # 本章节第几轮(1..3),触发三轮升级用
status: ready_for_review     # drafting | ready_for_review | revising | escalated | done
artifact: paper/outline/01_introduction.md   # 本轮产物路径
commit_hash: a1b2c3d         # 本轮产物对应的 commit,供 reviewer 确认快照
updated_at: 2026-05-24T10:30:00Z
```

`reviewer_state.yaml` 建议字段:

```yaml
round_id: 7                  # 必须回指 writer 的同一 round_id(对齐用)
phase: 1
section: introduction
section_round: 2
verdict: needs_revision      # pass | needs_revision
review_ref: agents/orchestrator/reviews/p1_intro_r2.md   # 指向本轮评审正文
commit_hash: d4e5f6g
updated_at: 2026-05-24T10:45:00Z
```

**字段设计要点(写 prompt 时要落实的约定)**:

- `round_id` 全局单调递增,只用来排序和肉眼看进度;**真正决定"轮到谁"的是 `round_id` 对齐 + `status`/`verdict` 的组合**。
- `section_round`(1→2→3)是触发三轮升级的关键计数器,**按章节重置**,不要跟全局 `round_id` 混用。
- 评估 agent 只有看到 writer 的 `status == ready_for_review` **且** `round_id` 比自己上次处理的更新时,才开始评估;评估完把 `reviewer_state.round_id` 设成与之相同,表示"这一轮我接住了"。
- 写作 agent 只有看到 reviewer 针对**对应 round_id** 给出 `verdict` 后,才继续动作。

### 2.3 原子写,防半写入

状态文件必须 **先写 `xxx.yaml.tmp`、再 `mv` 覆盖** `xxx.yaml`。`mv`(同文件系统下)是原子操作,保证对方永远不会读到写了一半的文件。这条要明确写进两个 agent 的 prompt 行为约定里。

### 2.4 长反馈单独成文件

评审正文(可能很长)**每轮单独生成一个 markdown**(如 `reviews/p1_intro_r2.md`),状态文件里只用 `review_ref` 指向它。不要把长反馈反复 append 到状态文件——状态文件要小、要能被频繁原子覆盖。

### 2.5 git 在协议里的角色

- **git commit = 交接的硬信号 + 完整可追溯历史**。每个 agent 干完活,先 commit 自己的产物,再把 `commit_hash` 写进自己的状态文件。
- 因为同仓同分支、两个进程共享同一个工作树,reviewer 其实直接读工作树里的文件即可;`commit_hash` 主要用于**确认"我读到的快照确实是 writer 声明的那一版"**,以及留历史。
- **commit message 约定**(便于 `git log` 一眼看清乒乓链):
  `[writer][p1][intro][r2] draft ready` / `[expert][p1][intro][r2] needs_revision`

---

## 3. 自动轮询机制(本系统最关键、最易踩坑的一节)

**核心事实:coding agent 执行完一个 turn 就会停止,它不会自己挂着无限轮询等文件变化。** 所以"自动"必须靠外部机制反复把它唤醒。有两种实现:

### 方案 A(推荐):外部 wrapper 脚本反复 headless 调起

写一个极简 shell 脚本,每隔 N 秒以 headless 模式(如 `claude -p "<指令>"` 之类)重新调起一次对应 agent。每次调起时,agent 的指令固定为:

> "读你的协议 + 对方状态文件;若轮到你则干活、commit、更新状态、退出;若没轮到你,什么都不做、直接退出。"

```
# writer_loop.sh(示意,非最终实现)
while true; do
  调起写作 agent(headless,一次性)
  sleep 30
  检查终止条件(见 3.3),满足则 break
done
```

reviewer 同理一个 `reviewer_loop.sh`。两个脚本各跑在一个终端窗口。

**优点**:每次调起都是**全新上下文**,agent 被迫从文件(状态 + 评审 + spec)重建认知,而不是依赖会话记忆——这反而强制了"以文件为唯一真相"的纪律,也省 token。
**缺点**:要写个小脚本;每次重建上下文略慢。对一篇毕业论文完全可接受。

### 方案 B:agent 内部跑 bash 轮询循环

让 agent 自己执行一个 `while ... sleep ... 检查状态` 的 bash 循环,检测到轮到自己就跳出循环干活。
**缺点**:agent 被一个 sleep 循环占住,较脆弱,出错难恢复,长时间挂起也更不可控。**不推荐作为主方案。**

### 3.3 终止条件(必须有,否则永远轮询下去)

- 设一个终态,例如 writer 把 `status: all_complete` 写进 `writer_state.yaml`(五章全部 pass 或 escalated,且阶段二也完成)。两个 loop 脚本检测到该终态就 `break` 退出。
- 再加一个保险:**最大空转次数 / 最大墙钟时间**,超过就停下并提醒你来看,避免卡死空跑。

### 3.4 git 锁的注意点(同仓同分支双进程)

两个进程共享一个 `.git`,若**恰好同时** commit,可能撞 `.git/index.lock` 报 "Another git process is running"。

- 在严格的回合互斥下,这几乎不会发生(任意时刻只有持球方 commit)。
- 但自动轮询会让两边可能**几乎同时醒来**。缓解办法:让每个 agent 在 commit 前用 `flock` 抢一个轻量锁文件(如 `agents/orchestrator/.git_lock`),或在 commit 失败时**重试 + 短暂退避**。把这条写进两个 agent 的 prompt 行为约定即可。

---

## 4. 完整工作流

### 4.1 两个阶段(共用同一套协议,只是产物目标不同)

- **阶段一(phase 1)**:把五个章节的**中文思路文档**逐份写好(`paper/outline/*.md`)。每份文档要规划:章节如何切分、每节写什么、插哪些图/表(图只规划位置和理由,不生成;表可生成)、全文约 15 张图的分布。每份文档单独走一遍乒乓循环,达成 pass 才进入下一份。五份全部完成,phase 1 结束。
- **阶段二(phase 2)**:按阶段一定下的思路文档,从 introduction 开始写 LaTeX 正文,逐章 pass 后推进下一章,reference 边写边插。其余部分(致谢等)暂不管。

### 4.2 单轮乒乓时序(以某一章节的一轮为例)

```
writer:  drafting → 写产物 → git commit → writer_state: ready_for_review(带 round_id, commit_hash)→ 退出
              ↓(reviewer loop 下次唤醒,检测到新 round_id 且 status=ready_for_review)
expert:  读产物 + spec → 写 reviews/pX_sec_rN.md → git commit
         → reviewer_state: verdict + review_ref + 同一 round_id → 退出
              ↓(writer loop 下次唤醒,检测到对应 round_id 的 verdict)
writer:  if verdict == pass        → 进入下一章节 / 下一阶段
         if verdict == needs_revision 且 section_round < 3 → revising(section_round +1)→ 回到顶部
         if verdict == needs_revision 且 section_round == 3 → 触发升级(见 4.3)
```

### 4.3 三轮升级(escalate)逻辑

某章节走到第 3 轮仍是 `needs_revision` 时:

1. **由写作 agent**(不是评估 agent)读评估 agent 第 3 轮的评审,把所有未解决项誊写进 `open_questions.md`,标 `[待人工裁决]`,注明章节与对应 `review_ref`。
2. 写作 agent 把该章节 `status` 置为 `escalated`,**不卡住**,直接推进到下一章节,翻转/更新状态继续跑。
3. 你(human)事后只需扫 `open_questions.md` 一个文件,集中处理全部遗留问题。

> 注意:让"写遗留疑问"这个动作由写作 agent 完成,是为了守住"评估 agent 永远只写 `reviews/` 和 `reviewer_state.yaml`"这条边界,不破坏写权限分区。

### 4.4 状态机(章节级)

```
        ┌─────────┐  ready_for_review   ┌───────────┐
        │ drafting │────────────────────▶│ reviewing │
        └─────────┘                      └───────────┘
             ▲                              │      │
   revising  │            needs_revision    │      │ pass
 (round<3)   │◀─────────────────────────────┘      ▼
             │                              ┌───────────┐
             │  needs_revision & round==3   │   done    │→ 下一章节/阶段
             └──────────────────────────────▶ escalated │
                                            └───────────┘
                                            (写入 open_questions,推进)
```

---

## 5. 为什么不会冲突(完整论证)

把"无冲突"建立在四道防线上,任意一道单独基本就够,叠加起来非常稳:

1. **写权限单一所有者(物理隔离)**。两个 agent 的写入集合完全不相交:writer 只写 `paper/`、`writer_state.yaml`、`open_questions.md`;expert 只写 `reviews/`、`reviewer_state.yaml`。两进程同时往**不同文件**写,本就不冲突;读—读永不冲突。论文正文只有 writer 能动,从根上杜绝了"两个 agent 同时改同一文件"。

2. **回合互斥(令牌)**。靠 `round_id` 对齐 + `status`/`verdict` 组合,任意时刻只有持球方在干活和推进,非持球方只读、只等。

3. **原子写(防半写)**。状态文件 `.tmp` + `mv`,对方永不读到半成品。

4. **git 锁缓解(防极端并发)**。commit 前 `flock` 抢锁 + 失败重试退避,兜住自动轮询下两边几乎同醒的极端情况。

| 文件/目录 | writer | expert | human |
|---|:---:|:---:|:---:|
| `paper/**` | ✍️ | 👁 | 👁 |
| `writer_state.yaml` | ✍️ | 👁 | 👁 |
| `open_questions.md` | ✍️ | 👁 | ✍️(裁决) |
| `reviews/**` | 👁 | ✍️ | 👁 |
| `reviewer_state.yaml` | 👁 | ✍️ | 👁 |
| `resources/**` | 👁 | 👁 | ✍️ |
| `control/spec.md` | 👁 | 👁 | ✍️ |
| `control/workflow.md` | 👁 | 👁 | ✍️ |

(✍️=可写,👁=只读)

---

## 6. 各文档要点清单(写 prompt / 配置时照这个填)

> 以下只列**该覆盖哪些点**,不代写 prompt 正文。

### 6.1 `control/spec.md`(rubric / 验收标准,活文档)

- 五章各自的"合格定义":必须包含的要素、逻辑链要求。
- 会议论文 → 毕业论文的**扩写方向**:related work 系统化、增设 preliminaries/背景、method 讲透推导、实验更全(消融 + 更多 baseline)、discussion 更展开、中文学术写作规范、格式与字数。
- 图表规范:全文约 15 张图的分布预期;图只规划"位置 + 为什么要这张图",不生成;表可生成。
- 引用规矩:只允许可核验来源,宁标 TODO 不许编造 bibkey。
- 评审打分维度(让 expert 逐条对照,给**可执行**的具体修改项,而非泛泛评价)。
- **预期它是活文档**:看到 v1 暴露的缺口再回填,别追求一次写完美。

### 6.2 `control/writer.md`(写作 agent 角色)要覆盖

- 职责边界:**只写作**,只能写自己那几个文件,绝不评估、绝不碰 `reviews/` 和 `reviewer_state.yaml`。
- 每次唤醒的固定动作序列:读协议 → 读 `reviewer_state` → 判断是否轮到自己 → 干活 / 退出。
- 行为约定:原子写、commit + 写 `commit_hash`、commit message 格式、git 锁重试。
- 三轮升级时的处置:写 `open_questions.md`、置 `escalated`、推进、不卡住。

### 6.3 `control/expert.md`(评估 agent 角色)要覆盖

- 角色设定:严厉的硕士论文导师;**只评估,不改稿**。
- 锚定客观标准:逐条对照 `spec.md` + `thesis_rules.md` + 三篇范文打分。
- 输出要求:具体、可执行的修改项;明确给 `pass` / `needs_revision`。
- 每次唤醒的固定动作序列;原子写;评审单独成文件 + `review_ref`。
- 防"虚假收敛":不得因 writer 措辞讨巧就放水(参考 BadScientist 的警示)。

### 6.4 `orchestrator/workflow.md`(协议)要覆盖

- 两阶段定义与切换条件。
- `round_id` / `section_round` 语义与对齐规则。
- 三轮升级的判定与动作。
- 终止条件(`all_complete` + 最大空转保险)。
- 两个状态文件的字段 schema(即第 2.2 节)。

### 6.5 `orchestrator/open_questions.md`(格式约定)

- 每条:章节、轮次、对应 `review_ref`、未解决问题摘要、`[待人工裁决]` 标记。
- 供 human 集中处理。

---

## 7. 启动顺序(bootstrap)

1. human 先把 `resources/` 填满(原文、代码、范文、`thesis_rules.md`、`git_history.md`)。
2. human 写**粗版** `spec.md`(只覆盖稳定的"形式与标准"部分,别求全)。
3. human 写 `workflow.md` 协议 + `writer.md` / `expert.md` 角色 prompt。
4. 初始化两个状态文件(writer: `phase:1, section:introduction, status:drafting`)。
5. 启两个 loop 脚本(或两个窗口),让系统先产出 **v1**。
6. human 查验 v1 → 把暴露出的"模糊地带"回填进 `spec.md` → 再迭代。
   (v1 的价值不在于完美,而在于把你没想清的标准**逼显**出来——这正是"先让它写一版"不冗余的原因。)

---

## 8. 一句话收尾的纪律

> **以文件为唯一真相,以令牌定回合,以 commit 留痕迹,以三轮设上限,以人类做终裁。**
> agent 各司其职、写权限物理隔离,系统就能在无人值守下安全地一轮一轮推进。