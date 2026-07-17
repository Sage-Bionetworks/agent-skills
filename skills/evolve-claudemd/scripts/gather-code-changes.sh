#!/usr/bin/env bash
# Step 2 (code): summarize what changed in a scope since a commit, bucketed by
# change type and file category — so the code-analyst reasons about WHY changes
# matter, not WHAT type each file is.
#
# Usage: gather-code-changes.sh <scope_dir> <since_commit>
# Emits JSON: {commit_count, commits:[...], added:[...], deleted:[...], modified:[...],
#              build_files:[...], linter_configs:[...], data_model_files:[...]}
set -euo pipefail

scope="${1:?usage: gather-code-changes.sh <scope_dir> <since_commit>}"
since="${2:?usage: gather-code-changes.sh <scope_dir> <since_commit>}"

json_array() {
  # Read newline-delimited stdin into a JSON string array.
  local first=1 line
  printf '['
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    line="${line//\\/\\\\}"; line="${line//\"/\\\"}"
    [ $first -eq 0 ] && printf ','
    first=0
    printf '"%s"' "$line"
  done
  printf ']'
}

namestatus="$(git diff --name-status "${since}..HEAD" -- "$scope" 2>/dev/null || true)"

added="$(printf '%s\n' "$namestatus"    | awk '$1 ~ /^A/  {print $2}')"
deleted="$(printf '%s\n' "$namestatus"  | awk '$1 ~ /^D/  {print $2}')"
modified="$(printf '%s\n' "$namestatus" | awk '$1 ~ /^M/  {print $2}')"
# Renames (R100 old new) surface the new path as modified-ish.
renamed="$(printf '%s\n' "$namestatus"  | awk '$1 ~ /^R/  {print $3}')"
modified="$(printf '%s\n%s\n' "$modified" "$renamed" | sed '/^$/d')"

all_paths="$(printf '%s\n' "$namestatus" | awk '{if ($1 ~ /^R/) print $3; else print $2}' | sed '/^$/d')"

build_files="$(printf '%s\n' "$all_paths" | grep -E '(^|/)(pom\.xml|build\.gradle(\.kts)?|package\.json|Makefile|justfile|Cargo\.toml|go\.mod|setup\.py|pyproject\.toml|requirements.*\.txt|build\.sbt)$' || true)"
linter_configs="$(printf '%s\n' "$all_paths" | grep -E '(^|/)(\.eslintrc.*|\.prettierrc.*|checkstyle.*\.xml|\.editorconfig|tsconfig.*\.json|ruff\.toml|\.flake8|\.pylintrc|spotless.*|\.rustfmt\.toml)$' || true)"
data_model_files="$(printf '%s\n' "$all_paths" | grep -E '\.(json|proto|sql|ts|graphql|avsc|yaml|yml)$' | grep -iE '(schema|model|ddl|dto|type|contract|openapi|swagger|migration|entity)' || true)"

commit_count="$(git rev-list --count "${since}..HEAD" -- "$scope" 2>/dev/null || echo 0)"
commits="$(git log --oneline "${since}..HEAD" -- "$scope" 2>/dev/null || true)"

printf '{'
printf '"scope":"%s","commit_count":%s,' "${scope//\"/\\\"}" "${commit_count:-0}"
printf '"commits":%s,'          "$(printf '%s\n' "$commits"          | json_array)"
printf '"added":%s,'            "$(printf '%s\n' "$added"            | json_array)"
printf '"deleted":%s,'          "$(printf '%s\n' "$deleted"          | json_array)"
printf '"modified":%s,'         "$(printf '%s\n' "$modified"         | json_array)"
printf '"build_files":%s,'      "$(printf '%s\n' "$build_files"      | json_array)"
printf '"linter_configs":%s,'   "$(printf '%s\n' "$linter_configs"   | json_array)"
printf '"data_model_files":%s'  "$(printf '%s\n' "$data_model_files" | json_array)"
printf '}\n'
