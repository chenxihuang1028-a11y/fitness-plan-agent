# fitness-plan-agent

把"收藏了从不看"的健身视频，自动转成一份真正能照着练的训练计划的 Claude Skill。

核心逻辑：**抓取视频 → 识别动作 → 与已有计划查重/冲突检查 → 更新计划**。全程本地文件读写，不依赖数据库或云服务，也不上传视频/音频等二进制内容。这不只是一份说明文档——仓库里带着可以直接复制去用的页面模板和数据模板，装好就能跑。

## 适用场景

- 刷小红书/抖音/YouTube/B站时随手收藏的健身视频，从来没打开看过
- 想要一份"随时随地能做"的懒人训练计划，而不是要求每天固定时间去健身房
- 同时有"偶尔能去健身房"和"大部分时间只能见缝插针"两种情况，希望一份计划两条轨道都能用
- 收藏的视频质量参差不齐（有的详细讲解、有的只有动作名单、有的纯画面无字幕），需要一套能处理这些差异并如实标注置信度的流程

## 核心设计

- **两条训练轨道并存**：`structured`（规律课表）和 `lazy`（懒人应急池，场景绑定 + 固定动作，不是每次现挑）可以同时开启，不是互斥的"人设"标签。
- **多层视频抓取**：官方字幕 → 网页文案摘要 → 下载视频 + 关键帧读图 + 音频转写（ffmpeg + whisper.cpp）→ 最后才退回问用户要截图。
- **宽进策略**：档案里没写的器械不等于用户没有，默认排入计划并标注缺口，而不是默认排除。
- **人体部位示意图**：根据动作的目标肌群自动生成高亮示意图，不用手画。
- **肌肉松解 & 康复建议**：根据当前计划里的动作自动推导对应的拉伸/放松动作。
- **完整动作库可见**：不只是排进计划的动作，识别过的全部动作都在页面上可查，待定项可勾选、一键复制成处理请求发回给 Claude。
- **计划自带记忆**：每次处理新链接的判断（采纳/替换/拒绝/为什么）都写入变更记录，不是每次重新生成、看不出历史。

## 包含内容

```text
fitness-plan-agent/
  SKILL.md                          Skill 主体说明：数据结构、抓取流程、冲突判定规则、页面维护方法
  templates/
    plan.html                       单页应用模板（计划视图 + 编辑档案 + 动作库 + 康复建议），空状态、可直接发布成 Artifact
    profile.example.json            profile.json 的示例（双轨道、完整字段）
    moves_library.example.json      moves_library.json 的空模板
    training_plan.example.json      training_plan.json 的空模板
    CURRENT_PLAN.example.md         CURRENT_PLAN.md 的空模板
    intake_log.example.md           intake_log.md 的空模板
  scripts/
    check_deps.sh                   检查第二层抓取需要的本地依赖（ffmpeg / whisper-cli / whisper 模型）
```

## 安装方式

把 `fitness-plan-agent` 目录复制到 Claude Code 的 skills 目录：

```bash
cp -R fitness-plan-agent ~/.claude/skills/
```

### 首次使用（跟 Claude 说一遍就行，不用自己动手）

1. **初始化数据目录**：把 `templates/` 下的文件复制到 `~/Documents/fitness-plan-agent-data/`，去掉 `.example` 后缀（`plan.html` 除外，直接用）。
   ```bash
   mkdir -p ~/Documents/fitness-plan-agent-data
   cp templates/plan.html ~/Documents/fitness-plan-agent-data/plan.html
   cp templates/moves_library.example.json ~/Documents/fitness-plan-agent-data/moves_library.json
   cp templates/training_plan.example.json ~/Documents/fitness-plan-agent-data/training_plan.json
   cp templates/CURRENT_PLAN.example.md ~/Documents/fitness-plan-agent-data/CURRENT_PLAN.md
   cp templates/intake_log.example.md ~/Documents/fitness-plan-agent-data/intake_log.md
   ```
2. **（可选）检查依赖**：`bash scripts/check_deps.sh`，缺什么装什么。不装也能用，Skill 会自动退回轻量抓取方式，只是拿不到画面烧录字幕/语音讲解那类细节。
3. **建档**：跟 Claude 说"帮我建个健身档案"，或者直接把 `templates/plan.html` 发布成 Artifact，点"编辑档案"填一遍。
4. **发链接**：把收藏的健身视频链接发给 Claude，Skill 自动触发。

以上这些 Claude 看到 `SKILL.md` 后会自动执行，你只需要说"帮我整理健身视频"或者直接甩链接过去。

## 使用流程

1. **建档**：填一次身高体重、目标、训练轨道、器械、伤病史。
2. **发链接**：把收藏的健身视频链接发给 Claude。
3. **自动处理**：抓取内容 → 识别动作 → 和已有动作库/计划做查重与冲突判定 → 更新计划。
4. **查看结果**：一份带人体部位示意图、康复建议和完整动作库的可视化训练计划页面，随时可以在页面里直接编辑档案。

## 数据与隐私

Skill 本体（本仓库内容）不包含任何真实用户数据——`templates/` 下的都是空模板或示例数据。运行时产生的个人档案、动作库、训练计划等数据全部存在使用者本地的 `~/Documents/fitness-plan-agent-data/`，不会自动同步到这个仓库，也不会上传到任何服务器。处理视频时临时下载的视频/音频/帧图文件，处理完会立即删除，不做本地留存。

## 仓库可见性

这个仓库适合公开发布，用于分享和复用 Claude Skill。已确认仓库中不包含个人隐私、密钥、未授权素材或不希望公开的测试文件——当前发布内容仅包含 Skill 说明本体、空白页面模板和示例数据，不含任何真实用户的档案或训练数据。
