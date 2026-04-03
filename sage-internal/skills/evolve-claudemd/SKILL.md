---
name: evolve-claudemd
description: Update stale CLAUDE.md files that already exist — analyzes code changes, PRs, Jira/Confluence since last edit, with accuracy audit. Do NOT use if no CLAUDE.md exists yet (use bootstrap-claudemd instead).
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
8. `## Anti-Patterns — Do NOT` — things Claude must AVOID doing, each with evidence and a reason. Sourced from: reverted PRs, reviewer pushback, HACK/FIXME comments protecting intentional patterns, production incidents. Format: "Do NOT X — because Y (evidence: PR #N / revert hash / Jira ticket)."
9. `## Testing` — only if non-standard
10. `## Related Systems` — sibling repos/services, only if non-obvious

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

**IMPORTANT: Always use MCP server tools for all GitHub, Jira, and Confluence operations. Never use the `gh` CLI — it may not be available. Use `mcp__github__*` for GitHub, `mcp__atlassian__*` for Jira/Confluence.**

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

- `mcp__github__list_pull_requests` — last 100 merged PRs since each CLAUDE.md's last update date. Focus on:
  - PR descriptions mentioning conventions, patterns, or architectural decisions
  - Review comments that establish new rules ("always do X", "never do Y", "use Z instead of W")
  - PRs that explicitly changed coding standards or added tooling configs
- **Mine anti-patterns from PR history**: Specifically search for:
  - **Reverted PRs** — each revert is a lesson learned. Document what was tried and why it failed as a "Do NOT" rule with the revert hash as evidence.
  - **Follow-up fix PRs** — PRs that fix mistakes from a previous PR (e.g., swapped test IDs, missed cleanup). These reveal patterns that are easy to get wrong.
  - **Reviewer pushback** — comments like "don't do this", "use existing utility instead", "this breaks X". Each is a candidate anti-pattern rule.
  - **Production incidents traced to PRs** — if a PR caused a bug that was later fixed, document the anti-pattern.
- `mcp__github__list_issues` — last 100 closed issues since last update (resolved architectural discussions). Last 100 open issues (planned changes, known problems).
- For the most significant PRs (convention-changing), read full details and review comments.

### Agent 3 — Jira/Confluence context
Use `mcp__atlassian__*` tools:

1. Call `mcp__atlassian__getAccessibleAtlassianResources` to get the cloudId.
2. Determine the Jira project key (from existing CLAUDE.md content, repo name patterns, or ask the user).
3. `mcp__atlassian__searchJiraIssuesUsingJql`:
   - Completed tickets (last 180 days): `project = <KEY> AND status = Done AND updated >= "<180_days_ago_date>" ORDER BY updated DESC`
   - Newly created or resolved epics: `project = <KEY> AND type = Epic AND updated >= "<180_days_ago_date>" ORDER BY updated DESC`
   - Look for tickets that changed architecture, conventions, data models, or constraints
4. `mcp__atlassian__searchConfluenceUsingCql`:
   - Pages modified since last update: `text ~ "<repo-name>" AND type = page AND lastModified >= "<last_update_date>" ORDER BY lastModified DESC`
   - Read top results for architecture changes, new ADRs, updated coding standards

---

## Step 3: Full Accuracy Audit

### Quality Scoring

Before auditing details, score each existing CLAUDE.md against this rubric to establish a baseline:

| Criterion | Max Points | What to check |
|-----------|-----------|---------------|
| Commands/workflows | 20 | Are build, test, lint, deploy commands present with context? |
| Architecture clarity | 20 | Can Claude understand codebase structure, module relationships, entry points? |
| Non-obvious patterns | 15 | Are gotchas, quirks, workarounds, and "why we do it this way" captured? |
| Conciseness | 15 | No filler, no obvious info, no redundancy with code comments? |
| Currency | 15 | Do commands work? Are file references accurate? Tech stack current? |
| Actionability | 15 | Are instructions executable and copy-paste ready? Paths real? |

Grades: **A** (90-100), **B** (70-89), **C** (50-69), **D** (30-49), **F** (0-29)

Record the baseline score. After proposing changes in Step 7, project the new score to show improvement.

### Line-by-Line Verification

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

### Validation Checklist

Before finalizing proposed changes, verify:
- [ ] Each addition is project-specific, not generic advice
- [ ] No obvious info that Claude can infer from code
- [ ] Commands are copy-paste ready and verified against config files
- [ ] All file paths reference real, existing files
- [ ] Every constraint has a "— because Y" reason
- [ ] This is the most concise way to express each item

### What NOT to Add — Examples

| Bad (remove) | Why it fails |
|--------------|-------------|
| "The `UserService` class handles user operations." | Obvious from class name |
| "Always write tests for new features." | Generic advice, not project-specific |
| Verbose multi-paragraph explanation of a concept | Condense to one actionable line |
| "We fixed a bug in commit abc123 where login broke." | One-off fix, won't recur |

---

## Step 5: Check for Coverage Gaps (with Deep-Dive)

**Every directory is a candidate for CLAUDE.md coverage — including non-code directories** (e.g., `docs/` with complex build systems like MkDocs/mkdocstrings). Scan all directories in the repo and verify that each one's non-obvious patterns are documented *somewhere* — either in its own CLAUDE.md, a parent's, or an ancestor's.

### Deep-dive for convention density

For each directory that currently lacks its own CLAUDE.md, launch Explore agents to **read source files deeply** (not just list them). Look for:
- **Return type conventions** — inconsistencies, reversed parameter orders, non-obvious tuple structures
- **Conditional/hidden behavior** — template method steps that are skipped under certain conditions
- **Reusable utility functions** — that Claude would reinvent if not told they exist
- **Hack comments** — grep for `HACK`, `FIXME`, `WORKAROUND`, `XXX`, `DO NOT`, `NEVER`, `WARNING`, `CAREFUL`. Each is a candidate anti-pattern guardrail — document what must NOT be changed and why.
- **Strict enforcement** — kwargs assertions, ordering dependencies, required parameters
- **Naming inconsistencies** — mixed conventions that Claude might "fix" incorrectly
- **Hardcoded values** — IDs, URLs, magic numbers duplicated across files
- **Test patterns** — custom mock helpers, fixture composition, parametrization conventions
- **External tool invocations** — subprocess calls with hack flags (e.g., `; exit 0`)
- **Concurrency/locking patterns** — mutex flags, processing locks, retry logic

A directory with many of these patterns has **high convention density** and needs its own CLAUDE.md, even if it has few files or no separate build config.

### Coverage decisions

1. **Needs own file**: Has conventions, constraints, or patterns that differ from its parent. Indicators: own build file, specialized tech, distinct coding patterns, high dependency fan-in, gotcha patterns from bug-fix PRs, **high convention density** (many behavioral patterns even with few files).
2. **Roll up to parent**: Simple enough (few files, no distinct patterns, follows sibling conventions, **low convention density**) that a mention in the parent CLAUDE.md suffices. Use a clearly labeled `### Rolled-up subdirectories` section in the parent to name each covered child — so readers know it was intentionally covered there, not forgotten.
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

Start with an executive summary, then present per-file reports:

```
## Evolution Summary

| File | Last Updated | Commits Since | Current Score | Projected Score |
|------|-------------|---------------|---------------|-----------------|
| ./CLAUDE.md | 2026-01-15 | 147 | 62/100 (C) | 85/100 (B) |
| ./lib/jdomodels/CLAUDE.md | 2026-02-20 | 43 | 78/100 (B) | 91/100 (A) |

- Files found: X
- Files needing update: X
- Stale references found: X
- New anti-patterns discovered: X
- Coverage gaps: X directories
```

Then for each CLAUDE.md, present a structured report:

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

### Anti-pattern guardrails to add:
- Do NOT: "Do NOT refactor X to Y — a previous attempt was reverted (hash) because Z" (from reverted PR)
- Do NOT: "Do NOT use bare set() for DataFrame construction — non-deterministic ordering broke tests (PR #621)" (from production incident)
- Do NOT: "Do NOT write custom column checks — use existing utility process_functions.checkColExist()" (from reviewer pushback in PR #622)

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

---

## User Tips

After completing evolution, share these tips with the user:

- **Keep it concise**: CLAUDE.md is part of the prompt — every line costs context. Dense is better than verbose.
- **Actionable commands**: All documented commands should be copy-paste ready
- **Regular maintenance**: Run `/evolve-claudemd` periodically (e.g., monthly or after major feature work) to prevent drift
