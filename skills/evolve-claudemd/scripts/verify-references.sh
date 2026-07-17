#!/usr/bin/env bash
# Step 3 (audit): mechanically flag the SUSPECT subset of references in a CLAUDE.md
# so the auditor agent reasons only about what's questionable, not every line.
#
# Usage: verify-references.sh <claude_md_path>
# Extracts backticked tokens and classifies each:
#   PATH_OK / PATH_MISSING   — token looks like a path (has / or a file extension)
#   SYMBOL_OK / SYMBOL_ABSENT— token looks like a Class/function name; checked via git grep
#   (tokens that are neither are skipped — too ambiguous to check mechanically)
# Output is a plain report grouped by verdict, with line numbers.
set -euo pipefail

file="${1:?usage: verify-references.sh <claude_md_path>}"
[ -f "$file" ] || { echo "ERROR: no such file: $file"; exit 1; }

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

path_missing=()
path_ok=()
symbol_absent=()
symbol_ok=()

# Pull every `backticked` token with its line number.
while IFS= read -r entry; do
  lineno="${entry%%:*}"
  token="${entry#*:}"
  [ -z "$token" ] && continue

  # Strip a trailing shell/pipe fragment: only look at the first whitespace-delimited word.
  first="${token%% *}"

  # Dotted lowercase token with no slash and no XML/markup — treat as a Java-style
  # package and resolve it to a source directory (dots -> slashes) before judging.
  if printf '%s' "$first" | grep -qE '^[a-z][a-z0-9_]*(\.[a-z0-9_]+){2,}$'; then
    pkgpath="${first//.//}"
    if find "$repo_root" -type d -path "*/$pkgpath" -not -path '*/target/*' -print -quit 2>/dev/null | grep -q .; then
      path_ok+=("L$lineno: $first (package)")
    else
      path_missing+=("L$lineno: $first (package)")
    fi
  # Classify: path-like if it contains a slash or a dotted extension.
  elif printf '%s' "$first" | grep -qE '(/|\.[a-zA-Z0-9]+$)'; then
    # Path candidate. Ignore obvious non-paths (URLs, globs handled loosely).
    clean="${first#./}"
    if [ -e "$repo_root/$clean" ] || compgen -G "$repo_root/$clean" >/dev/null 2>&1; then
      path_ok+=("L$lineno: $first")
    else
      path_missing+=("L$lineno: $first")
    fi
  elif printf '%s' "$first" | grep -qE '^[A-Z][A-Za-z0-9_]*$|^[a-z][A-Za-z0-9_]+\(?\)?$'; then
    # Symbol candidate: TypeName or functionName / functionName().
    sym="${first%\(\)}"
    sym="${sym%\(}"
    # Skip very short / common-word tokens to reduce noise.
    if [ "${#sym}" -lt 4 ]; then continue; fi
    if git -C "$repo_root" grep -qw "$sym" -- '*.java' '*.ts' '*.js' '*.py' '*.go' '*.kt' '*.rs' 2>/dev/null \
       || git -C "$repo_root" grep -qw "$sym" 2>/dev/null; then
      symbol_ok+=("L$lineno: $sym")
    else
      symbol_absent+=("L$lineno: $sym")
    fi
  fi
done < <(grep -noE '`[^`]+`' "$file" | sed -E 's/`//g')

emit() {
  local title="$1"; shift
  echo "## $title ($#)"
  if [ "$#" -gt 0 ]; then printf '  %s\n' "$@"; fi
  echo
}

echo "# Reference verification for $file"
echo
echo "SUSPECT (audit these):"
emit "PATH_MISSING" ${path_missing[@]+"${path_missing[@]}"}
emit "SYMBOL_ABSENT" ${symbol_absent[@]+"${symbol_absent[@]}"}
echo "RESOLVED (likely fine — spot-check only):"
emit "PATH_OK" ${path_ok[@]+"${path_ok[@]}"}
emit "SYMBOL_OK" ${symbol_ok[@]+"${symbol_ok[@]}"}
echo "NOTE: version numbers and command strings need judgment — cross-check against build files (pom.xml/package.json/Makefile) directly."
