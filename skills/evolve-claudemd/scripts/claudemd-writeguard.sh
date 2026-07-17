#!/usr/bin/env bash
# PostToolUse hook: after any Write/Edit, if the target file is a CLAUDE.md,
# deterministically enforce this skill's own output invariants. Inert for every
# other file (exits 0 silently). Reads the hook payload as JSON on stdin.
#
# Feedback protocol: on a violation, print guidance to stderr and exit 2 so the
# agent sees it and can fix the file. On success, exit 0 (optionally noting the
# line count on stderr for visibility).
set -euo pipefail

payload="$(cat 2>/dev/null || true)"

# Extract the written file path from the hook payload. Prefer jq; degrade gracefully.
fp=""
if command -v jq >/dev/null 2>&1 && [ -n "$payload" ]; then
  fp="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)"
fi

# Only act on CLAUDE.md writes.
[ -n "$fp" ] || exit 0
[ "$(basename "$fp")" = "CLAUDE.md" ] || exit 0
[ -f "$fp" ] || exit 0

problems=()

# No empty section headers (a '## Heading' with no non-blank content before the next header/EOF).
empty_headers="$(awk '
  /^##[[:space:]]/ {
    if (prev_header != "" && !had_content) print prev_header;
    prev_header = $0; had_content = 0; next
  }
  /[^[:space:]]/ { had_content = 1 }
  END { if (prev_header != "" && !had_content) print prev_header }
' "$fp" || true)"
if [ -n "$empty_headers" ]; then
  while IFS= read -r h; do
    [ -n "$h" ] && problems+=("Empty section header (no content): '$h'")
  done <<< "$empty_headers"
fi

if [ "${#problems[@]}" -gt 0 ]; then
  {
    echo "CLAUDE.md write-guard found issues in $fp:"
    printf '  - %s\n' "${problems[@]}"
  } >&2
  exit 2
fi

echo "CLAUDE.md write-guard OK: $fp ($(wc -l < "$fp") lines)" >&2
exit 0
