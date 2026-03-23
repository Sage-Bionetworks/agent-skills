---
name: evolve-claudemd
description: Update existing CLAUDE.md files by analyzing code changes, GitHub PRs/issues, Jira/Confluence since last modification, with full accuracy audit.
---

# Evolve CLAUDE.md

Update existing CLAUDE.md files by analyzing what changed in the codebase, GitHub, Jira, and Confluence since each file was last modified. Perform a full accuracy audit of existing content. Produce targeted, user-approved edits.

---

## Core Generation Rules

These rules govern every line written or kept. Apply them to both new content and existing content under audit.

1. **Explore before writing.** Read directory structure, manifests, configs, README, and source samples. Never guess or invent details.
2. **Don't restate tooling.** If a convention is enforced by a linter, formatter, or type checker config in the repo, leave it out. If a new config was added since the last update, the corresponding CLAUDE.md line should be removed.
3. **Only verified commands.** Copy commands verbatim from package.json scripts, Makefile, justfile, README, or CI config. Mark inferred commands with `# inferred`.
4. **Every constraint needs a reason.** "Never do X — because Y." Without a reason, Claude follows the rule in obvious cases and misses edge cases.
5. **No secrets.** Env var names are fine; values, tokens, and connection strings are not.
6. **Be specific or say nothing.** Name exact paths, tools, patterns. Vague guidance produces vague results.
7. **Keep files concise but complete.** Every line must change how Claude behaves. Cut anything inferable from the codebase, anything restating the README, any empty section headers. But do NOT sacrifice coverage for brevity — a thorough 200-line file is better than a thin 50-line file that misses critical patterns.
8. **Imperative voice.** "Use named exports" not "We tend to prefer named exports."
9. **Focus on non-obvious.** Surface what Claude cannot infer from code alone.
10. **Quality test for every line:** "If I remove this, will Claude mess up?" No -> delete it. Yes -> keep it.
11. **Document data models and their flow.** Identify key input/output data shapes and document: where defined, how they flow, non-obvious shape constraints, what generates or consumes them. Critical when data shapes cross module or repo boundaries.

---

## Output Format

Same as bootstrap. Each CLAUDE.md uses:
```
<!-- Last reviewed: YYYY-MM -->
```

Section order (omit any that don't apply):
1. `## Project` — 2-4 sentences
2. `## Stack` — language, runtime, framework, database, test runner, build tool, with versions
3. `## Commands` — verified build, test, lint, run commands
4. `## Data Models` — key data shapes, flows, codegen pipelines, cross-boundary contracts
5. `## Conventions` — non-obvious patterns not enforced by tooling
6. `## Architecture` — module boundaries or data flow, only if non-obvious
7. `## Constraints` — hard rules with reasons
8. `## Testing` — only if non-standard
9. `## Related Systems` — sibling repos/services, only if non-obvious

---

## Step 1: Discover Existing CLAUDE.md Files and Their Age

1. Find all CLAUDE.md files in the repo:
   ```bash
   find . -name "CLAUDE.md" -not -path "*/node_modules/*" -not -path "*/target/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/build/*"
   ```

2. For each file, get the last commit that touched it:
   ```bash
   git log -1 --format="%H %ai %s" -- <path>
   ```

3. Count commits and changed files since that commit within the file's scope:
   ```bash
   git rev-list --count <last_commit>..HEAD -- <scope_dir>
   git diff --stat <last_commit>..HEAD -- <scope_dir> | tail -1
   ```

4. Display a status table:
   ```
   | File | Last Updated | Commits Since | Summary |
   |------|-------------|---------------|---------|
   | ./CLAUDE.md | 2026-01-15 | 147 | 312 files changed |
   | ./lib/jdomodels/CLAUDE.md | 2026-02-20 | 43 | 89 files changed |
   ```

5. Extract GitHub remote URL for API calls: `git remote get-url origin`

---

## Step 2: Gather Evolution Context (parallel agents)

Launch up to 3 agents in parallel:

### Agent 1 — Code & data model changes
For each CLAUDE.md, determine its scope (root = whole repo, module = that directory subtree).

Run `git diff --stat <last_commit>..HEAD -- <scope_dir>` and `git log --oneline <last_commit>..HEAD -- <scope_dir>`.

Categorize changes:
- **New files/directories** — potential new sections or new module CLAUDE.md files
- **Deleted files/directories** — potentially stale references
- **Modified source files** — patterns may have changed
- **Build file changes** — new dependencies, version bumps, changed commands
- **New linter/formatter configs** — conventions that should now be REMOVED from CLAUDE.md
- **Data model changes** (flag prominently):
  - New/modified/deleted schema files (JSON schemas, protobuf, OpenAPI, DDL, dbt models, TypeScript types, Pydantic models)
  - Changes to codegen configs or pipelines
  - New fields on existing models, removed fields, changed enum values
  - New cross-boundary contracts (API shapes, shared types)
  - Data model changes often have ripple effects across modules and repos

### Agent 2 — GitHub context
Use `mcp__github__*` tools. Parse org/repo from the remote URL.

- `mcp__github__list_pull_requests` — merged PRs since each CLAUDE.md's last update date. Focus on:
  - PR descriptions mentioning conventions, patterns, or architectural decisions
  - Review comments that establish new rules ("always do X", "never do Y", "use Z instead of W")
  - PRs that explicitly changed coding standards or added tooling configs
- `mcp__github__list_issues` — closed issues since last update (resolved architectural discussions). Open issues (planned changes, known problems).
- For the most significant PRs (convention-changing), read full details and review comments.

### Agent 3 — Jira/Confluence context
Use `mcp__atlassian__*` tools:

1. Call `mcp__atlassian__getAccessibleAtlassianResources` to get the cloudId.
2. Determine the Jira project key (from existing CLAUDE.md content, repo name patterns, or ask the user).
3. `mcp__atlassian__searchJiraIssuesUsingJql`:
   - Completed tickets since last update: `project = <KEY> AND status = Done AND updated >= "<last_update_date>" ORDER BY updated DESC`
   - Newly created or resolved epics: `project = <KEY> AND type = Epic AND updated >= "<last_update_date>" ORDER BY updated DESC`
   - Look for tickets that changed architecture, conventions, data models, or constraints
4. `mcp__atlassian__searchConfluenceUsingCql`:
   - Pages modified since last update: `text ~ "<repo-name>" AND type = page AND lastModified >= "<last_update_date>" ORDER BY lastModified DESC`
   - Read top results for architecture changes, new ADRs, updated coding standards

---

## Step 3: Full Accuracy Audit

For each CLAUDE.md, read its content line by line and verify every concrete reference:

- **File paths mentioned** — still exist? Use Glob to check.
- **Class/function/type names** — still exist? Use Grep to check.
- **Version numbers** — match current build files? Read the manifest and compare.
- **Commands** — still present verbatim in package.json/Makefile/CI config? Read the source of truth and compare.
- **Constraints** — still relevant? Cross-reference with Jira:
  - If a constraint references an in-progress migration and the related epic is now Done, the constraint may need to be lifted or updated.
  - If a constraint references a dependency version and that version has changed, update it.
- **Linter/formatter overlap** — were new configs added since last update? If so, any CLAUDE.md convention now enforced by tooling should be flagged for removal.
- **Data model accuracy**:
  - Have schemas/types been added, removed, or changed shape?
  - Have new fields been added that carry non-obvious constraints?
  - Have codegen pipelines changed (new plugins, different output directories)?
  - Have cross-boundary contracts shifted (API response shapes that downstream repos depend on)?
- **Architecture descriptions** — do they still match the actual module structure?
- **Related Systems** — are described relationships still accurate? Have new integrations been added?

---

## Step 4: Apply Generation Rules Filter

Before presenting changes to the user:

1. **New content must pass the quality test**: "If I remove this, will Claude mess up?"
2. **New constraints must have reasons.** Do not propose a constraint without a "— because Y" explanation.
3. **Remove anything now enforced by new tooling configs.** If `.eslintrc` was added and it enforces a convention currently in CLAUDE.md, flag that line for removal.
4. **Keep files concise but complete.** Every line must earn its place, but do not cut behavioral conventions, reusable utility lists, or hack documentation just to stay short. Thoroughness over brevity.
5. **Data model items**: only include shape constraints Claude would get wrong without guidance.

---

## Step 5: Check for Coverage Gaps (with Deep-Dive)

**Every directory is a candidate for CLAUDE.md coverage.** Scan all directories in the repo and verify that each one's non-obvious patterns are documented *somewhere* — either in its own CLAUDE.md, a parent's, or an ancestor's.

### Deep-dive for convention density

For each directory that currently lacks its own CLAUDE.md, launch Explore agents to **read source files deeply** (not just list them). Look for:
- **Return type conventions** — inconsistencies, reversed parameter orders, non-obvious tuple structures
- **Conditional/hidden behavior** — template method steps that are skipped under certain conditions
- **Reusable utility functions** — that Claude would reinvent if not told they exist
- **Hack comments** — grep for `HACK`, `FIXME`, `WORKAROUND`, `XXX`
- **Strict enforcement** — kwargs assertions, ordering dependencies, required parameters
- **Naming inconsistencies** — mixed conventions that Claude might "fix" incorrectly
- **Hardcoded values** — IDs, URLs, magic numbers duplicated across files
- **Test patterns** — custom mock helpers, fixture composition, parametrization conventions
- **External tool invocations** — subprocess calls with hack flags (e.g., `; exit 0`)
- **Concurrency/locking patterns** — mutex flags, processing locks, retry logic

A directory with many of these patterns has **high convention density** and needs its own CLAUDE.md, even if it has few files or no separate build config.

### Coverage decisions

1. **Needs own file**: Has conventions, constraints, or patterns that differ from its parent. Indicators: own build file, specialized tech, distinct coding patterns, high dependency fan-in, gotcha patterns from bug-fix PRs, **high convention density** (many behavioral patterns even with few files).
2. **Roll up to parent**: Simple enough (few files, no distinct patterns, follows sibling conventions, **low convention density**) that a mention in the parent CLAUDE.md suffices.
3. **Already covered by ancestor**: Patterns are already documented in an existing ancestor's CLAUDE.md.

Build a coverage map showing where every directory's patterns are (or should be) documented. Present gaps in the change analysis (Step 7) so no directory falls through the cracks.

Also check if recent commits/PRs introduced significant new directories or areas.

---

## Step 6: Check Cross-Repo Evolution

If sibling repos are accessible (in the same workspace directory):
- Have their CLAUDE.md files changed in ways that affect this repo?
- Have API contracts or shared dependencies changed?
- Have new cross-repo data flows been introduced?

If not accessible locally, check via GitHub API if possible.

---

## Step 7: Present Change Analysis

**For large change sets** (many commits since last update): chunk findings by directory/module. Process each chunk fully (code + PRs + Jira). Present findings incrementally so the user can approve as you go. Large change sets deserve MORE scrutiny, not less — they represent the highest risk of CLAUDE.md drift.

For each CLAUDE.md, present a structured report:

```
## ./CLAUDE.md (last updated: YYYY-MM-DD, N commits since)

### Accuracy issues:
- Line 12: `DBOSearchIndex` renamed to `DBOSearchConfiguration` — update reference
- Line 34: Spring version "5.3.34" -> now "5.3.39" per pom.xml
- Line 78: Command `mvn test -pl lib/old-module` — module was renamed to `lib/new-module`

### Lines to remove:
- Line 45: "Use semicolons" — .eslintrc now enforces this (added in PR #412)
- Line 67: "Do not upgrade to React Router v6" — epic PORTALS-2847 completed

### Lines to add:
- Constraint: "Never use @Autowired on fields — constructor injection required for testability" (from PR #4521 review)
- Data Models: New search configuration schema in lib/lib-auto-generated — generates POJOs consumed by 3 modules
- Convention: Workers in search/ package use ConcurrentWorkerStack exclusively

### Data model changes:
- New JSON schemas: SearchConfiguration.json, SynonymSet.json — codegen pipeline produces POJOs
- New DDL: SearchConfiguration-ddl.sql, SynonymSet-ddl.sql — DBO classes consume these
- New enum values added to MigrationType.json — migration order matters

### Coverage gaps:
#### Needs own CLAUDE.md:
- lib/lib-grid/ — CRDT implementation, specialized patterns, 15 files, non-obvious @GridTransaction annotation

#### Should roll up into parent:
- lib/lib-grid/util/ → cover in lib/lib-grid/CLAUDE.md — only 2 helper files, no distinct patterns

#### Already covered:
- lib/lib-common/ → covered by ./CLAUDE.md architecture section

### Line count: currently 120, after changes ~145 (concise but complete)
```

Ask the user to approve, modify, or skip each change set.

---

## Step 8: Apply Approved Changes

For each approved change:

1. **Updates to existing files**: Use the Edit tool. Preserve the overall document structure and voice. Update the `<!-- Last reviewed: YYYY-MM -->` date to the current month.
2. **New module CLAUDE.md files**: Use the Write tool. Follow the bootstrap generation approach:
   - Read source files deeply from the module (not just 3-5 samples — read all key files for behavioral conventions)
   - Apply all generation rules
   - Include: reusable utilities, non-obvious return types, conditional behavior, mock/test patterns, hack workarounds, naming inconsistencies
3. **Removals**: Delete the flagged lines. Do not leave empty section headers.

---

## Step 9: Optional Commit

Offer to commit the changes. Suggested message format:
```
Update CLAUDE.md files to reflect codebase evolution

- Updated N existing files
- Created N new module files
- Removed N stale references
```

Do NOT commit without explicit user approval.

---

## Edge Cases

- **CLAUDE.md has never been committed** (only in working tree): Use the file's modification time as a baseline, or treat as needing a full audit with no "since last update" scope — audit against the entire current state.
- **Massive change set** (hundreds of commits since last update): These are the highest-priority files to evolve — large drift means the CLAUDE.md is most likely to mislead. Chunk by directory/module. Process each chunk fully (code + PRs + Jira). Present findings incrementally so the user can approve as you go. Do NOT skip or summarize away detail.
- **Module was deleted but CLAUDE.md remains**: Flag the file for deletion. Show what was deleted and when.
- **Jira/Confluence unavailable**: Proceed with code + GitHub only. Note the gap in the analysis. Constraint relevance checks that depend on epic status will be skipped — flag these for manual review.
- **No GitHub remote**: Proceed with local git history only.
- **Cross-repo changes detected but can't verify**: Note the potential impact. Let the user decide whether to investigate further.
- **Completed Jira epic lifts a constraint**: Flag the constraint for removal or update. Include the epic key and completion date as evidence.
- **File growing very large (200+ lines)**: Consider whether a child directory deserves its own CLAUDE.md to offload content. Present the split option to the user.
- **Repo has no existing CLAUDE.md files**: Warn the user and suggest using `/bootstrap-claudemd` instead.
