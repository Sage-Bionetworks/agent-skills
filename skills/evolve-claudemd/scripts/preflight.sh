#!/usr/bin/env bash
# Step 0 pre-flight: verify the environment before the skill gathers anything.
# Exits non-zero with a one-line reason on failure. On success prints the git
# remote (may be empty) so the orchestrator can parse org/repo for GitHub calls.
set -euo pipefail

command -v git >/dev/null 2>&1 || { echo "PREFLIGHT FAIL: git not found on PATH"; exit 1; }

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "PREFLIGHT FAIL: not inside a git repository — run /evolve-claudemd from a repo working tree"
  exit 1
fi

remote="$(git remote get-url origin 2>/dev/null || true)"
echo "PREFLIGHT OK"
echo "remote=${remote}"
