# claude-statusline

Claude Code 自定义状态栏 Hook 脚本，优雅地展示模型、上下文使用和会话时长。

## 特性

- 🎨 三色进度条（绿/黄/红）
- 🧠 自动检测模型名称
- 📊 Token 使用量可视化
- ⏱ 会话时长显示
- ⚡ 高性能（单次 Python 调用提取所有字段）

## 安装

将 `statusline.sh` 放置到 Claude Code hooks 目录：

```bash
# macOS
cp statusline.sh ~/.claude/hooks/statusline.sh

# Linux
cp statusline.sh ~/.claude/hooks/statusline.sh

# Windows (WSL)
cp statusline.sh ~/.claude/hooks/statusline.sh
```

确保脚本可执行：

```bash
chmod +x ~/.claude/hooks/statusline.sh
```

## 用法

该脚本通过 Claude Code 的 hooks 机制自动运行。也可以手动测试：

```bash
bash statusline.sh <<< '{"model":{"id":"test"},"context_window":{"used_percentage":50,"context_window_size":200000,"current_usage":{"input_tokens":100000,"output_tokens":50000,"cache_creation_input_tokens":0,"cache_read_input_tokens":0}},"cost":{"total_duration_ms":60000},"effort":{"level":"balanced"},"thinking":{"enabled":true}}'
```

## 输出示例

```
➤ ~/projects/my-app · 🧠 Qwen3.6-35B-A3B-bf16 · 📋 150.5K/200K · ████████░░ 75% · ⏱ 1m0s · 🦾 [balanced] · 🤔 True
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
