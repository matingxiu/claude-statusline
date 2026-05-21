# claude-statusline

Claude Code 自定义状态栏 Hook 脚本，优雅地展示模型、上下文使用和会话时长。

## 特性

- 🎨 三色进度条（绿/黄/红）
- 🧠 自动检测模型名称
- 📊 Token 使用量可视化
- ⏱ 会话时长显示
- ⚡ 高性能（单次 Python 调用提取所有字段）

## 安装

### 1. 复制脚本

将 `statusline.sh` 放置到 Claude Code hooks 目录：

```bash
cp statusline.sh ~/.claude/hooks/statusline.sh
chmod +x ~/.claude/hooks/statusline.sh
```

### 2. 配置 Claude Code

在 `~/.claude/settings.json` 中添加 `statusLine` 配置（如果 `settings.json` 不存在，直接创建）：

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash \"~/.claude/hooks/statusline.sh\""
  }
}
```

**注意**：
- 如果 `settings.json` 已存在其他配置（如 `hooks`、`theme` 等），只需添加 `statusLine` 字段，不要覆盖整个文件
- 路径中的 `~` 会被 Claude Code 正确展开；也可以写成绝对路径
- Windows (WSL) 和 macOS/Linux 配置相同

### 3. 重启 Claude Code

保存配置文件后，重启 Claude Code 即可看到状态栏。

## 手动测试

```bash
bash statusline.sh <<< '{"model":{"id":"claude-sonnet-4-20250514","context_window":{"used_percentage":50,"context_window_size":200000,"current_usage":{"input_tokens":100000,"output_tokens":50000,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}},"cost":{"total_duration_ms":60000},"effort":{"level":"balanced"},"thinking":{"enabled":true}}'
```

预期输出：
```
  ➤ ~/projects/my-app · 🧠 claude-sonnet-4-20250514 · 📋 150K/200K · ████████░░ 75% · ⏱ 1m0s · 🦾 [balanced] · 🤔 true
```

## 进度条颜色

| 百分比 | 颜色 |
|--------|------|
| < 50%  | 🟢 绿色 |
| 50% - 80% | 🟡 黄色 |
| > 80%  | 🔴 红色 |

## 依赖

- `bash`
- `python3`（推荐，已做单调用优化）

## 许可证

MIT
