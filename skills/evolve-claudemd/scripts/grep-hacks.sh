#!/usr/bin/env bash
# Step 5 (coverage): find hack/gotcha comments in a directory. Each hit is a
# candidate anti-pattern guardrail — something that must NOT be changed and why.
#
# Usage: grep-hacks.sh <dir>
# Prints file:line:text hits (bounded), then a per-file count summary.
set -euo pipefail

dir="${1:?usage: grep-hacks.sh <dir>}"

pattern='HACK|FIXME|WORKAROUND|XXX|DO NOT|NEVER|WARNING|CAREFUL|TODO'

grep -rEn "$pattern" "$dir" \
  --exclude-dir=node_modules \
  --exclude-dir=target \
  --exclude-dir=.git \
  --exclude-dir=dist \
  --exclude-dir=build \
  2>/dev/null | head -200 || true

echo "---"
echo "hit counts by file:"
grep -rEln "$pattern" "$dir" \
  --exclude-dir=node_modules \
  --exclude-dir=target \
  --exclude-dir=.git \
  --exclude-dir=dist \
  --exclude-dir=build \
  2>/dev/null | while IFS= read -r f; do
    c="$(grep -Ec "$pattern" "$f" 2>/dev/null || echo 0)"
    echo "$c  $f"
  done | sort -rn | head -40 || true
