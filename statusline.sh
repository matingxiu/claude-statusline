#!/bin/bash
set -euo pipefail

# ── Constants ──
COLOR_THRESH_LO=50    # green → yellow
COLOR_THRESH_HI=80    # yellow → red
BAR_WIDTH=10
NUM_K=1000
NUM_M=1000000

INPUT=$(cat)

# ── Single python3 call: extract all fields (tab-separated) ──
read -r MODEL USED_PCT DURATION_MS EFFORT THINKING \
      CURRENT_IN CURRENT_OUT CURRENT_CACHE_CREATE CURRENT_CACHE_READ \
      TOTAL_SIZE \
<<< "$(python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
m = d.get('model', {})
if isinstance(m, dict):
    model = m.get('display_name') or m.get('id', 'unknown')
elif isinstance(m, str):
    model = m
elif isinstance(d.get('model_name'), str):
    model = d['model_name']
else:
    model = 'unknown'
ctx = d.get('context_window', {})
cc = ctx.get('current_usage', {})
thinking = str(d.get('thinking', {}).get('enabled', False)).lower()
print(f'{model}\t{ctx.get(\"used_percentage\", 0)}\t{d.get(\"cost\", {}).get(\"total_duration_ms\", 0)}\t{d.get(\"effort\", {}).get(\"level\", \"normal\")}\t{thinking}\t{cc.get(\"input_tokens\", 0)}\t{cc.get(\"output_tokens\", 0)}\t{cc.get(\"cache_creation_input_tokens\", 0)}\t{cc.get(\"cache_read_input_tokens\", 0)}\t{ctx.get(\"context_window_size\", 0)}')
" <<< "$INPUT")"

# ── Duration (ms → readable) ──
DURATION_S=$((DURATION_MS / 1000))
DURATION_M=$((DURATION_S / 60))
DURATION_LEFT=$((DURATION_S % 60))
if [ "$DURATION_M" -gt 0 ]; then
    DURATION="${DURATION_M}m${DURATION_LEFT}s"
else
    DURATION="${DURATION_LEFT}s"
fi

# ── Current token usage ──
CURRENT_USED=$((CURRENT_IN + CURRENT_OUT + CURRENT_CACHE_CREATE + CURRENT_CACHE_READ))

# ── Percentage ──
if [ "$USED_PCT" -gt 0 ] 2>/dev/null; then
    PCT="$USED_PCT"
elif [ "$TOTAL_SIZE" -gt 0 ] 2>/dev/null; then
    PCT=$((CURRENT_USED * 100 / TOTAL_SIZE))
else
    PCT=0
fi

# ── Format number (K / M) ──
fmt() {
    local n=$1
    if [ "$n" -ge "$NUM_M" ] 2>/dev/null; then
        local whole=$((n / NUM_M))
        local frac=$(( (n % NUM_M) / 100000 ))
        if [ "$frac" -eq 0 ]; then
            printf '%dM' "$whole"
        else
            printf '%d.%dM' "$whole" "$frac"
        fi
    elif [ "$n" -ge "$NUM_K" ] 2>/dev/null; then
        local whole=$((n / NUM_K))
        local frac=$(( (n % NUM_K) / 100 ))
        if [ "$frac" -eq 0 ]; then
            printf '%dK' "$whole"
        else
            printf '%d.%dK' "$whole" "$frac"
        fi
    else
        printf '%dK' "$n"
    fi
}

U=$(fmt "$CURRENT_USED")
T=$(fmt "$TOTAL_SIZE")

# ── Current directory ──
DIR="$PWD"

# ── Progress bar (10 chars, 3 colors) ──
F=$((PCT * BAR_WIDTH / 100))
E=$((BAR_WIDTH - F))
# Build filled + empty segments in one loop
B=""
for i in $(seq 1 "$F" 2>/dev/null); do B="${B}█"; done
for i in $(seq 1 "$E" 2>/dev/null); do B="${B}░"; done

# ── Color thresholds ──
C=$'\033'
if [ "$PCT" -lt "$COLOR_THRESH_LO" ] 2>/dev/null; then
    GREEN="${C}[32m"      # green
elif [ "$PCT" -le "$COLOR_THRESH_HI" ] 2>/dev/null; then
    GREEN="${C}[93m"      # yellow
else
    GREEN="${C}[91m"      # red
fi

# ── Output ──
CYAN="${C}[36m"
MAGENTA="${C}[35m"
RESET="${C}[0m"

echo "  ${CYAN}➤ $DIR${RESET} · ${MAGENTA}🧠${RESET} $MODEL · 📋 $U/$T · ${GREEN}$B${RESET} $PCT% · ⏱ $DURATION · 🦾 [$EFFORT] · 🤔 $THINKING"
