---
name: evolve-claudemd
description: Update existing CLAUDE.md files by analyzing code changes, GitHub PRs/issues, Jira/Confluence since last modification, with full accuracy audit.
hooks:
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: bash "${CLAUDE_PLUGIN_ROOT}"/skills/evolve-claudemd/scripts/claudemd-writeguard.sh
          timeout: 10
---

# Evolve CLAUDE.md

Update existing CLAUDE.md files by analyzing what changed in the codebase, GitHub, Jira, and Confluence since each file was last modified. Perform a full accuracy audit. Produce targeted, user-approved edits.

## How this skill runs

This skill is an **orchestrator**. It keeps your (the top-level agent's) context lean by pushing work down two layers:

- **Scripts** (`scripts/*.sh`) do the deterministic git/grep/parse plumbing and emit compact output. Run them; don't reimplement their logic inline.
- **Sub-agents** (`claudemd-*` agent types) do the context-heavy gathering — 100s of PRs, Jira/Confluence, deep source reads. They burn that raw data in their own context and return only short digests. Dispatch them; do not pull raw PR bodies, full Confluence pages, or whole source trees into this conversation yourself.
- **On-demand references** (`references/*.md`) hold the bulky rules/rubrics/templates. Read each only at the step that consumes it.
- A **PostToolUse write-guard hook** validates every CLAUDE.md you write (no empty section headers). If it reports an issue, fix and rewrite.

Run the steps in order. Steps 2 and 5 dispatch sub-agents; Step 6 is the user-approval gate; nothing is written before approval.

---

## Step 0 — Pre-flight

Run `bash "${CLAUDE_PLUGIN_ROOT}"/skills/evolve-claudemd/scripts/preflight.sh`. If it fails, stop and show its message. On success it prints the git `remote=` line — parse `owner/repo` from it for the GitHub sub-agent.

## Step 1 — Discover

Run `bash "${CLAUDE_PLUGIN_ROOT}"/skills/evolve-claudemd/scripts/discover.sh`. It returns a JSON array (one record per CLAUDE.md: path, scope_dir, last_commit, last_date, commits_since, files_changed). Render a status table for the user:

```
| File | Last Updated | Commits Since | Files Changed |
|------|-------------|---------------|---------------|
```

Files with a null `last_commit` are uncommitted — audit against current state (see Edge Cases). If `discover.sh` returns `[]`, warn the user there are no CLAUDE.md files and suggest `/bootstrap-claudemd`, then stop.

## Step 2 — Gather (parallel sub-agents)

Dispatch these three agents **in one message** (independent work, run concurrently). Give each the scope info it needs; collect only their returned digests.

- **`claudemd-code-analyst`** — per scope_dir + since_commit: what code/data-model changes imply CLAUDE.md edits.
- **`claudemd-github-analyst`** — owner/repo + each file's since_date: convention & anti-pattern candidates with PR/issue evidence.
- **`claudemd-tracker-analyst`** — Jira project key + since_date: constraints to add/lift with ticket/page evidence. (If you don't know the project key, ask the user.)

For many CLAUDE.md files, run one code-analyst per scope; the github/tracker analysts can cover the repo once using the oldest since_date.

## Step 3 — Audit

For each existing CLAUDE.md, dispatch **`claudemd-auditor`** (one per file, may run in parallel). It returns a baseline score and confirmed accuracy issues. The rubric lives in `"${CLAUDE_PLUGIN_ROOT}"/skills/evolve-claudemd/references/scoring-rubric.md` (the agent reads it).

## Step 4 — Filter

Read `"${CLAUDE_PLUGIN_ROOT}"/skills/evolve-claudemd/references/generation-rules.md`. Apply the Generation Rules Filter and Validation Checklist to every proposed addition/removal from Steps 2–3 before presenting. Drop anything that fails the "if I remove this, will Claude mess up?" test or lacks a reason.

## Step 5 — Coverage

Dispatch **`claudemd-coverage-scout`** with the directories that lack their own CLAUDE.md and the existing CLAUDE.md locations. It returns own-file / roll-up / already-covered decisions plus anti-pattern guardrails from hack comments.

Scout the **whole tree, depth-agnostically** — not just top-level modules. The highest-value new files are often deeply nested sub-packages with a distinct sub-architecture (e.g. `manager/search/`, `grid/internal/replica/`, `dbo/migration/`). Gate every candidate on the evidence test **"would an agent working from the parent CLAUDE.md make a mistake here?"** — **never** on file count. Load-bearing directories are frequently small (a 4-file `id-generator` with a transaction gotcha warrants a note; a 50-file "more of the same DAOs" package does not). For a large tree, fan out several coverage-scout agents over disjoint subtrees in one message. Feed the confirmed guardrails and roll-up detail back down per the altitude rule (Step 4 / generation-rules rule 12): a roll-up bullet lands in its parent, a distinct sub-architecture becomes its own child file so its detail leaves the parent.

## Step 6 — Present analysis (approval gate)

Read `"${CLAUDE_PLUGIN_ROOT}"/skills/evolve-claudemd/references/report-templates.md`. Build the executive summary (with current + projected scores) and a per-file report from the digests. For large change sets, chunk by module and present incrementally — large drift gets MORE scrutiny, not less.

**Ask the user to approve, modify, or skip each change set. Write nothing until they approve.**

## Step 7 — Apply approved changes

For each approved set:
- **Updates**: use Edit. Preserve structure and voice.
- **New module files**: use Write. Follow `"${CLAUDE_PLUGIN_ROOT}"/skills/evolve-claudemd/references/generation-rules.md` (Output Format + section order). Have the coverage-scout's findings in hand; deep-read the module's key files before writing.
- **Removals**: delete flagged lines; leave no empty section headers.

**Verify every specific claim against source before writing it.** Sub-agent digests are a map, not ground truth — before committing a bean name, class name, line number, constant, magic value, or exact behavior to a file, confirm it directly in the code (a targeted `grep`/Read). This catches digest generalizations (e.g. an autowired-`List` registry vs an explicit-arg setter) that would otherwise ship as authoritative-but-wrong guidance.

The write-guard hook runs after each write. If it reports an issue (empty section header), fix and rewrite.

## Step 8 — Optional commit

Offer a commit; never commit without explicit approval. Suggested message:
```
Update CLAUDE.md files to reflect codebase evolution

- Updated N existing files
- Created N new module files
- Removed N stale references
```

---

## Edge Cases

- **CLAUDE.md never committed** (null last_commit): audit against the entire current state — no "since" scope.
- **Massive change set** (hundreds of commits): highest priority — large drift means the file most likely misleads. Chunk by module, process each fully, present incrementally. Do NOT summarize away detail.
- **Module deleted but CLAUDE.md remains**: flag the file for deletion with what was removed and when.
- **Jira/Confluence unavailable**: tracker-analyst returns a note; proceed with code + GitHub only and flag constraint-relevance checks for manual review.
- **No GitHub remote**: preflight prints an empty remote; skip the github-analyst, proceed with local git only.
- **Completed epic lifts a constraint**: flag the constraint for removal/update with the epic key + completion date.
- **File growing very large (200+ lines)**: consider splitting a child directory into its own CLAUDE.md; present the option.
- **Repo has no CLAUDE.md files**: suggest `/bootstrap-claudemd`.

## User Tips

- **Keep it concise**: CLAUDE.md is part of the prompt — every line costs context. Dense beats verbose.
- **Actionable commands**: all documented commands should be copy-paste ready.
- **Regular maintenance**: run `/evolve-claudemd` periodically (monthly or after major feature work) to prevent drift.
