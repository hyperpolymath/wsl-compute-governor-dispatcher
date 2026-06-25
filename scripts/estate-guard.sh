#!/usr/bin/env bash
# estate-guard — early-warning + throttle + GC hygiene for the WSL2 dev VM.
# Runs via the estate-guard.timer systemd *user* unit (every ~2 min).
# Purpose: catch the conditions that cause the WSL2 OOM crash-loop BEFORE the
# VM dies, slow runaway builds, and keep git healthy.
#
# Side effects (deliberately conservative):
#   - renice (CPU-politeness) of runaway BUILD tools only — never `claude`.
#   - `git worktree prune` (only removes entries whose dir is already gone — safe).
#   - `git gc --auto` (no-op unless a repo actually needs packing).
# It does NOT kill processes or remove present worktrees (those can hold work).
set -uo pipefail

LOG="$HOME/.local/state/estate-guard.log"
STAMP_GC="$HOME/.local/state/estate-guard.gc.stamp"
REPOS="$HOME/developer/repos"

# Heavy = counts toward pressure.  Build = safe to throttle (excludes claude/node/deno).
HEAVY_RE='claude|node|deno|rustc|cc1|cc1plus|lld|idris2|gnatprove|gprbuild|z3|cvc5|boolector|wasm-opt|chez'
BUILD_RE='rustc|cc1|cc1plus|lld|idris2|gnatprove|gprbuild|z3|cvc5|boolector|wasm-opt'
MAX_HEAVY=10          # warn + throttle above this many heavy processes
MIN_AVAIL_MB=1500     # warn + throttle below this much available memory
GC_EVERY_S=3600       # run git hygiene at most hourly

ts()  { date '+%Y-%m-%dT%H:%M:%S'; }
logm() { echo "$(ts) $*" >>"$LOG"; }

avail_mb=$(awk '/MemAvailable/{print int($2/1024)}' /proc/meminfo)
heavy=$(ps -eo comm= 2>/dev/null | grep -Ec "$HEAVY_RE")
load=$(awk '{print $1}' /proc/loadavg)

warn=0
[ "${heavy:-0}" -gt "$MAX_HEAVY" ] && warn=1
[ "${avail_mb:-9999}" -lt "$MIN_AVAIL_MB" ] && warn=1

if [ "$warn" = 1 ]; then
  msg="PRESSURE heavy_procs=$heavy/${MAX_HEAVY} mem_avail=${avail_mb}MB/${MIN_AVAIL_MB} load=$load"
  logm "$msg"
  command -v wall >/dev/null 2>&1 && echo "[estate-guard] $msg — throttling runaway builds" | wall 2>/dev/null
  for pid in $(pgrep -f "$BUILD_RE" 2>/dev/null); do
    ni=$(ps -o ni= -p "$pid" 2>/dev/null | tr -d ' ')
    if [ -n "$ni" ] && [ "$ni" -lt 15 ] 2>/dev/null; then
      renice -n 15 -p "$pid" >/dev/null 2>&1 && logm "  throttled pid $pid $(ps -o comm= -p "$pid" 2>/dev/null) nice $ni->15"
    fi
  done
fi

# --- GC hygiene, at most hourly ---
now=$(date +%s); last=0
[ -f "$STAMP_GC" ] && last=$(cat "$STAMP_GC" 2>/dev/null || echo 0)
if [ $(( now - last )) -ge "$GC_EVERY_S" ]; then
  echo "$now" >"$STAMP_GC"
  pruned=0; gced=0
  while IFS= read -r gitpath; do
    repo=$(dirname "$gitpath")
    timeout 30  git -C "$repo" worktree prune          >/dev/null 2>&1 && pruned=$((pruned+1))
    timeout 120 git -C "$repo" gc --auto --quiet        >/dev/null 2>&1 && gced=$((gced+1))
  done < <(find "$REPOS" -mindepth 2 -maxdepth 2 -name .git 2>/dev/null)
  logm "GC hygiene: worktree-pruned ${pruned} repos, gc --auto ${gced} repos"
fi
exit 0
