#!/usr/bin/env bash
# Step 1 discover: find every CLAUDE.md and compute its age/drift deterministically.
# Emits a JSON array, one object per file:
#   {path, scope_dir, last_commit, last_date, last_subject, commits_since, files_changed}
# scope_dir is the file's directory ("." for the repo root) — the subtree the file governs.
set -euo pipefail

emit_json_string() {
  # Escape a value for embedding in a JSON string.
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

first=1
printf '['
while IFS= read -r file; do
  scope_dir="$(dirname "$file")"

  # Last commit that touched this CLAUDE.md, as hash|iso-date|subject.
  logline="$(git log -1 --format="%H|%ai|%s" -- "$file" 2>/dev/null || true)"

  if [ -z "$logline" ]; then
    last_commit=""
    last_date=""
    last_subject="(uncommitted — no git history)"
    commits_since="null"
    files_changed="0"
  else
    IFS='|' read -r last_commit last_date last_subject <<< "$logline"
    commits_since="$(git rev-list --count "${last_commit}..HEAD" -- "$scope_dir" 2>/dev/null || echo 0)"
    files_changed="$(git diff --stat "${last_commit}..HEAD" -- "$scope_dir" 2>/dev/null | tail -1 | grep -oE '[0-9]+ files? changed' | grep -oE '[0-9]+' | head -1 || echo 0)"
    [ -z "$files_changed" ] && files_changed=0
  fi

  [ $first -eq 0 ] && printf ','
  first=0
  printf '{"path":"%s","scope_dir":"%s","last_commit":"%s","last_date":"%s","last_subject":"%s","commits_since":%s,"files_changed":%s}' \
    "$(emit_json_string "$file")" \
    "$(emit_json_string "$scope_dir")" \
    "$(emit_json_string "$last_commit")" \
    "$(emit_json_string "$last_date")" \
    "$(emit_json_string "$last_subject")" \
    "${commits_since:-null}" \
    "${files_changed:-0}"
done < <(find . -name "CLAUDE.md" \
  -not -path "*/node_modules/*" \
  -not -path "*/target/*" \
  -not -path "*/.git/*" \
  -not -path "*/dist/*" \
  -not -path "*/build/*" | sort)
printf ']\n'
