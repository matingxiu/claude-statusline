#!/bin/bash
set -euo pipefail

INPUT=$(cat)

# 一次 python3 调用取出所有字段
read -r MODEL USED_PCT DURATION_MS EFFORT THINKING \
      CURRENT_IN CURRENT_OUT CURRENT_CACHE_CREATE CURRENT_CACHE_READ \
      TOTAL_SIZE \
<<< "$(python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
m = d.get('model', {})
if isinstance(m, dict): model = m.get('display_name') or m.get('id', 'unknown')
elif isinstance(m, str): model = m
elif isinstance(d.get('model_name'), str): model = d['model_name']
else: model = 'unknown'

ctx = d.get('context_window', {})
cc = ctx.get('current_usage', {})
print(f'{model}\t{ctx.get(\"used_percentage\", 0)}\t{d.get(\"cost\", {}).get(\"total_duration_ms\", 0)}\t{d.get(\"effort\", {}).get(\"level\", \"normal\")}\t{d.get(\"thinking\", {}).get(\"enabled\", False)}\t{cc.get(\"input_tokens\", 0)}\t{cc.get(\"output_tokens\", 0)}\t{cc.get(\"cache_creation_input_tokens\", 0)}\t{cc.get(\"cache_read_input_tokens\", 0)}\t{ctx.get(\"context_window_size\", 0)}')
" <<< "$INPUT")"

# 解析时长 (ms → 可读)
DURATION_S=$((DURATION_MS / 1000))
DURATION_M=$((DURATION_S / 60))
DURATION_LEFT=$((DURATION_S % 60))
if [ "$DURATION_M" -gt 0 ]; then
    DURATION="${DURATION_M}m${DURATION_LEFT}s"
else
    DURATION="${DURATION_LEFT}s"
fi

# 当前使用的 token 总数
CURRENT_USED=$((CURRENT_IN + CURRENT_OUT + CURRENT_CACHE_CREATE + CURRENT_CACHE_READ))

# 计算百分比
if [ "$USED_PCT" -gt 0 ] 2>/dev/null; then
    PCT="$USED_PCT"
elif [ "$TOTAL_SIZE" -gt 0 ] 2>/dev/null; then
    PCT=$((CURRENT_USED * 100 / TOTAL_SIZE))
else
    PCT=0
fi

# 格式化数字
fmt() {
    local n=$1
    if [ "$n" -ge 1000000 ] 2>/dev/null; then
        local whole=$((n / 1000000))
        local frac=$(( (n % 1000000) / 100000 ))
        if [ "$frac" -eq 0 ]; then
            printf '%dM' "$whole"
        else
            printf '%d.%dM' "$whole" "$frac"
        fi
    elif [ "$n" -ge 1000 ] 2>/dev/null; then
        local whole=$((n / 1000))
        local frac=$(( (n % 1000) / 100 ))
        if [ "$frac" -eq 0 ]; then
            printf '%dK' "$whole"
        else
            printf '%d.%dK' "$whole" "$frac"
        fi
    else
        printf '0K'
    fi
}

U=$(fmt "$CURRENT_USED")
T=$(fmt "$TOTAL_SIZE")

# 当前目录
DIR=$(pwd)

# 进度条 (10 格) — 三色
W=10; F=$((PCT*W/100)); E=$((W-F))
B=""
if [ "$F" -gt 0 ]; then
    for i in $(seq 1 "$F"); do B="${B}█"; done
fi
for i in $(seq 1 "$E"); do B="${B}░"; done

# 根据百分比选择颜色
C=$'\033'
if [ "$PCT" -lt 50 ] 2>/dev/null; then
    GREEN="${C}[32m"
elif [ "$PCT" -le 80 ] 2>/dev/null; then
    GREEN="${C}[93m"
else
    GREEN="${C}[91m"
fi

# 输出
CYAN="${C}[36m"
MAGENTA="${C}[35m"
RESET="${C}[0m"

echo "  ${CYAN}➤ $DIR${RESET} · ${MAGENTA}🧠${RESET} $MODEL · 📋 $U/$T · ${GREEN}$B${RESET} $PCT% · ⏱ $DURATION · 🦾 [$EFFORT] · 🤔 $THINKING"
