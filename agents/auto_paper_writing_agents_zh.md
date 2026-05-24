# 自动化毕业论文写作系统 —— 中文设计说明

本文档是给作者本人看的总体方案说明,不作为运行时 prompt 直接喂给
Writer 或 Expert。运行时真正读取的是:

- `agents/control/writer.md`
- `agents/control/expert.md`
- `agents/control/spec.md`
- `agents/orchestrator/workflow.md`
- 两个状态文件和对应资源文件

英文版 `agents/auto_paper_writing_agents.md` 是主设计文档;本文档保持同一
协议,用于中文快速阅读。

## 0. 核心思路

系统由一个外部 orchestrator 驱动两个角色槽位:

- Writer: 只写论文内容和 `writer_state.yaml`;
- Expert: 只写评审和 `reviewer_state.yaml`;
- Human: 准备资源、制定规则、最终裁决。

正确性依赖两条不变量:

1. 单写者: 每个会被写的文件只有一个角色能写。
2. 回合互斥: orchestrator 根据状态文件决定当前只唤起一个角色。

Codex session 可以长期复用,也可以失效后重启。长期上下文只是加速器,
文件系统状态才是唯一真实状态。即使每一轮都启动新的 Codex 进程,系统也
应该正确。

## 1. 目录与职责

```text
MASTER_THESIS/
  agents/
    project_contexts.md        # Writer 和 Expert 都读
    resources/
      history_paper_commit.md  # Writer 内容来源
      thesis_rules.md          # Expert 评估依据
      sources/                 # Chalmers 官方来源,Expert 读
      references/              # 三篇参考 thesis,Expert 读
    control/
      writer.md                # Writer prompt + Writer 可见任务规格
      expert.md                # Expert prompt
      spec.md                  # Expert-only rubric,Writer 不读
    orchestrator/
      workflow.md              # 静态协议
      writer_state.yaml        # 只由 Writer 写
      reviewer_state.yaml      # 只由 Expert 写
      reviews/                 # 只由 Expert 写
  paper/
    sections_drafts/
      01_introduction.md
      02_related_work.md
      03_methods.md
      04_results.md
      05_discussion.md
    Main.tex include/ figure/ refs.bib Makefile build/
```

NanoMem 的 NeurIPS 论文、代码、实验数据不复制到 `resources/` 里。Writer
需要时直接去 `/mnt/models/yupan/llm/nanomem` 和
`/mnt/models/yupan/llm/nanomem/paper` 读取。

## 2. Writer 和 Expert 的上下文分工

Writer 读:

- `writer.md`
- `workflow.md`
- `agents/project_contexts.md`
- `agents/resources/history_paper_commit.md`
- 两个状态文件
- Expert 给出的 review
- NanoMem 论文、代码、实验材料

Writer 不读:

- `spec.md`
- `thesis_rules.md`
- `sources/**`
- `agents/resources/references/**`

Expert 读:

- `expert.md`
- `spec.md`
- `workflow.md`
- `agents/project_contexts.md`
- `thesis_rules.md`
- Chalmers 官方来源
- 三篇参考 thesis
- Writer 当前产物

这样做的目的不是让 Writer 盲写。`writer.md` 里必须写清楚基本任务规格:
章节顺序、阶段产物、语言要求、引用/TODO 规则、图表规划要求、状态更新
规则。真正隐藏的是 Expert 的评分 rubric 和质量线,也就是 `spec.md`。

## 3. 状态文件 schema

`writer_state.yaml`:

```yaml
round_id: 0
phase: 1
section: introduction
section_round: 1
status: drafting
artifacts:
  - paper/sections_drafts/01_introduction.md
commit_hash: ""
updated_at: "ISO8601"
```

允许持久存在的 Writer status 只有:

```text
drafting
ready_for_review
all_complete
```

`escalated` 不能写成 `writer_state.status` 的休止状态。它只能出现在 commit
message 或日志里。

`reviewer_state.yaml`:

```yaml
round_id: 0
phase: 1
section: introduction
section_round: 1
verdict: pass|needs_revision
review_ref: agents/orchestrator/reviews/p1_introduction_r1.md
commit_hash: ""
updated_at: "ISO8601"
```

关键点:

- 初始 `writer_state.round_id=0`, `reviewer_state.round_id=0`。
- Writer 首次交审时把 `round_id` 增加到 1,Expert 才能看到 `1 > 0` 并触发。
- Writer 每次推进 workflow state 都必须让 `round_id+1`;每次产生新的
  `ready_for_review` 时,新的 `round_id` 必须严格大于 Expert 已处理的轮次。
- Expert 只处理 `writer.status == ready_for_review` 且
  `writer.round_id > reviewer.round_id` 的轮次。
- `artifacts` 必须是列表。Phase 1 通常只有一个 `.md`;Phase 2 可能跨多个
  LaTeX include 文件。

## 4. Orchestrator 轮询方案

采用一个顶层 orchestrator loop,而不是两个 agent 自己无限轮询。
orchestrator 自身必须持有 `agents/orchestrator/.orch_lock`,避免误启动两个 loop
实例并发唤起角色。

每轮 loop:

1. 读取 `writer_state.yaml`;
2. 读取 `reviewer_state.yaml`;
3. 根据 `round_id`、`status`、`verdict` 判断该唤起谁;
4. 同步阻塞地调用对应 role slot 一次;
5. 等角色进程完成、commit、原子写入状态文件后,再回到循环顶部;
6. 如果 `writer_state.status == all_complete` 则退出。

调用必须是阻塞的。如果 `invoke_writer_slot_once` 或
`invoke_expert_slot_once` 还没结束,orchestrator 不能重新读旧状态,否则会重复
唤起同一个角色。

角色槽位规则:

```text
如果原来的 Codex session/process 还活着且能接收任务:
    继续把本轮任务发给这个 session,并等待完成
否则:
    启动新的 Codex session/process
    新进程从文件重建上下文,并等待完成
```

## 5. Turn Decision

Writer 运行条件:

- `writer_state.status == drafting`;
- `reviewer_state.round_id == writer_state.round_id` 且
  `reviewer_state.verdict == pass`;
- `reviewer_state.round_id == writer_state.round_id` 且
  `reviewer_state.verdict == needs_revision`。

Expert 运行条件:

- `writer_state.status == ready_for_review`;
- `writer_state.round_id > reviewer_state.round_id`。

其他情况 orchestrator 只 sleep,不做事。

## 6. 两阶段写作流程

章节顺序固定为:

```text
introduction -> related_work -> methods -> results -> discussion
```

Phase 1:

- 产出 `paper/sections_drafts/*.md`;
- 每份文档只写中文规划;
- 英文只用于技术术语、系统名、数据集名、metric、代码标识符;
- 规划小节结构、内容来源、扩写方向、图表位置和理由;
- 不生成最终图,只规划图。

Phase 2:

- 根据 Phase 1 通过后的规划写 LaTeX 正文;
- 从 introduction 开始逐章推进;
- 使用 NanoMem NeurIPS 论文和历史 commit 中被压缩掉的材料扩写;
- 引用必须可核验,不确定的 bibkey 用 TODO 标出,不要编造。

全文最终目标可以按约 15 张图规划,但图必须服务于论文论证,不能为了凑数。

## 7. 三轮上限与升级规则

每个章节最多三轮 review。

如果 `section_round < 3` 且 Expert 给 `needs_revision`:

1. Writer 读 review;
2. 修改当前 artifacts;
3. `section_round += 1`;
4. commit;
5. 设置 `status=ready_for_review`;
6. 严格增加 `round_id`;
7. 原子更新 `writer_state.yaml`;
8. 退出。

如果 `section_round == 3` 仍然 `needs_revision`:

1. Writer 应用所有可行修改;
2. 未解决问题直接写在原文对应位置;
3. Phase 1 Markdown 用 `**NOTSURE:** ...` 或 `**TODO:** ...`;
4. Phase 2 LaTeX 用 `\textcolor{red}{NOTSURE: ...}` 或
   `\textcolor{red}{TODO: ...}`;
5. commit message/log 中可写 escalated;
6. 不写 `status=escalated`;
7. 立即进入下一个 `drafting` 状态,或进入 phase 2,或在 phase 2 discussion
   后设置 `all_complete`。

不再使用 `open_questions.md`。人工复查时直接聚合全文标记:

```bash
cd paper && make notsure
```

等价的仓库根目录命令是:

```bash
rg -n "NOTSURE:|TODO:" paper/sections_drafts paper/Main.tex paper/include agents/orchestrator/reviews
```

## 8. Pass 转移规则

Expert 给 `pass` 后:

- 如果当前不是 `discussion`,Writer 进入下一节:
  `section_round=1`, `round_id+1`, `status=drafting`;这一轮只推进状态,不写新的论文 artifact。
- 如果当前是 phase 1 的 `discussion`,Writer 进入 phase 2:
  `section=introduction`, `section_round=1`, `round_id+1`,
  `status=drafting`;这一轮只推进状态,不写新的论文 artifact。
- 如果当前是 phase 2 的 `discussion`,Writer 设置
  `status=all_complete`;这一轮只推进状态。

## 9. 各文档接下来要写什么

`agents/control/writer.md`:

- Writer 角色边界;
- Writer 可见任务规格;
- Phase 1 / Phase 2 产物要求;
- 不确定项标记规则;
- `round_id`、`section_round`、`artifacts` 更新规则;
- commit 和原子写规则。

`agents/control/spec.md`:

- Expert-only rubric;
- 每章 passing definition;
- Chalmers 规则和参考 thesis 中总结出的质量标准;
- 会议论文扩写成硕士论文的判断标准;
- Expert 审稿时的逐项评分/反馈要求。

`agents/control/expert.md`:

- Expert 只评估不改稿;
- 每条重要批评必须说明问题、原因、依据、具体修改建议;
- 依据可以来自 spec、Chalmers 规则、参考 thesis、项目 context;
- 输出明确 `pass` 或 `needs_revision`。

`agents/orchestrator/workflow.md`:

- 状态机细节;
- 同步阻塞调用;
- 角色槽位复用 + 重启兜底;
- 三轮上限和升级规则;
- 初始状态与终止条件。

## 10. 初始状态

初始化时:

```yaml
# writer_state.yaml
round_id: 0
phase: 1
section: introduction
section_round: 1
status: drafting
artifacts:
  - paper/sections_drafts/01_introduction.md
commit_hash: ""
updated_at: ""
```

```yaml
# reviewer_state.yaml
round_id: 0
phase: 1
section: introduction
section_round: 1
verdict: ""
review_ref: ""
commit_hash: ""
updated_at: ""
```

## 11. 纪律

文件是唯一真相。状态决定回合。调用必须阻塞。`round_id` 必须单调推进。
三轮不收敛就就地标红并继续前进。Human 最终裁决。
