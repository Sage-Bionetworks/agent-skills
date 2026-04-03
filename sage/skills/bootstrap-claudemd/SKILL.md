---
name: bootstrap-claudemd
description: Create initial CLAUDE.md files for a repo with none — auto-detects stack, pulls context from GitHub/Jira/Confluence, produces concise files focused on non-obvious patterns.
---

# Bootstrap CLAUDE.md

Create initial CLAUDE.md files for a repository that has none. Auto-detect the stack, gather ecosystem context, and produce concise files containing only what Claude cannot infer from the code itself.

The user may pass a repo path as an argument, or default to the current working directory.

---

## Core Generation Rules

These rules govern every line written. Violating them produces files that are too long, too vague, or duplicate what tooling already enforces.

1. **Explore before writing.** Read directory structure, manifests, configs, README, and source samples. Never guess or invent details.
2. **Don't restate tooling.** If a convention is enforced by a linter, formatter, or type checker config in the repo, leave it out.
3. **Only verified commands.** Copy commands verbatim from package.json scripts, Makefile, justfile, README, or CI config. Mark inferred commands with `# inferred`.
4. **Every constraint needs a reason.** "Never do X — because Y." Without a reason, Claude follows the rule in obvious cases and misses edge cases.
5. **No secrets.** Env var names are fine; values, tokens, and connection strings are not.
6. **Be specific or say nothing.** Name exact paths, tools, patterns. Vague guidance produces vague results.
7. **Keep files concise but complete.** Every line must change how Claude behaves. Cut anything inferable from the codebase, anything restating the README, any empty section headers. But do NOT sacrifice coverage for brevity — a thorough 200-line file is better than a thin 50-line file that misses critical patterns.
8. **Imperative voice.** "Use named exports" not "We tend to prefer named exports."
9. **Focus on non-obvious.** Surface what Claude cannot infer from code alone: unusual tooling, generated files that must not be edited, non-standard layouts, monorepo conventions, gotchas.
10. **Quality test for every line:** "If I remove this, will Claude mess up?" No -> delete it. Yes -> keep it.
11. **Document data models and their flow.** Identify key input/output data shapes (JSON schemas, API types, database structures, dbt models, Terraform state, protobuf, CSV/Parquet schemas). Document: where defined, how they flow through the system, non-obvious shape constraints, what generates or consumes them. Critical when data shapes cross module or repo boundaries.

---

## Output Format

Each CLAUDE.md starts with:
```
<!-- Last reviewed: YYYY-MM -->
```

Section order (omit any section that doesn't apply — no empty headings):

1. `## Project` — 2-4 sentences: what this does, what system it belongs to
2. `## Stack` — language, runtime, framework, database, test runner, build tool, with versions where visible
3. `## Commands` — build, test, lint, run, and any other commands developers use regularly
4. `## Data Models` — key input/output data shapes and how they flow. Where schemas/types are defined, what generates them (codegen, ORM, manual), what consumes them, non-obvious shape constraints (backwards-compatibility rules, required-but-not-validated fields, enum evolution rules), cross-boundary contracts (API shapes shared between repos, database schemas consumed by multiple services). Only what Claude would get wrong without guidance.
5. `## Conventions` — non-obvious patterns not enforced by tooling
6. `## Architecture` — key module boundaries or data flow, only if non-obvious from directory structure
7. `## Constraints` — hard rules Claude must never violate, each with a reason
8. `## Anti-Patterns — Do NOT` — things Claude must AVOID doing, each with evidence and a reason. Sourced from: reverted PRs, reviewer pushback, HACK/FIXME comments protecting intentional patterns, production incidents. Format: "Do NOT X — because Y (evidence: PR #N / revert hash / Jira ticket)."
9. `## Testing` — only if the approach is non-standard
10. `## Related Systems` — sibling repos/services this interacts with, only if the relationship is non-obvious

### CLAUDE.md File Types & Locations

| Type | Location | Purpose |
|------|----------|---------|
| Project root | `./CLAUDE.md` | Primary project context (checked into git, shared with team) |
| Package-specific | `./packages/*/CLAUDE.md` | Module-level context in monorepos |
| Subdirectory | Any nested location | Feature/domain-specific context |

### Module-Level Files
Same format but scoped to the module. Even shorter — often just Project + Conventions + Constraints.

**Every directory is a candidate.** The question is not "is this complex enough?" but "does this directory (or its children) have anything non-obvious that Claude needs to know?" Use these rules to decide placement:

- **Create a CLAUDE.md in a directory** when it has its own conventions, constraints, data flow patterns, or gotchas that differ from or extend the parent CLAUDE.md. Indicators: own build file, specialized tech, distinct coding patterns, high dependency fan-in, **high convention density** (many behavioral patterns even with few files — e.g., non-obvious return types, reusable utilities, conditional template methods, mock patterns, hack workarounds).
- **Roll up into the parent** when a subdirectory is simple enough that a brief mention in the parent's CLAUDE.md fully covers it. Indicators for rollup: fewer than 3 source files, no distinct conventions, follows the same patterns as siblings, **low convention density** (no behavioral surprises found during Step 2b deep-dive).
- **Cover children from the parent** when multiple subdirectories share the same patterns — document once in the parent rather than repeating in each child. Use a clearly labeled `### Rolled-up subdirectories` section in the parent to name each covered child and briefly describe what it contains — so readers know the child was intentionally covered here, not forgotten.

The goal is full coverage: every directory's non-obvious patterns should be documented *somewhere* — either in its own CLAUDE.md or in an ancestor's. No directory should fall through the cracks.

---

## Quality Validation

Before presenting generated content to the user, score each file against this rubric. Include the score in the Step 5 discovery summary.

### Scoring Rubric

| Criterion | Max Points | What to check |
|-----------|-----------|---------------|
| Commands/workflows | 20 | Are build, test, lint, deploy commands present with context? |
| Architecture clarity | 20 | Can Claude understand codebase structure, module relationships, entry points? |
| Non-obvious patterns | 15 | Are gotchas, quirks, workarounds, and "why we do it this way" captured? |
| Conciseness | 15 | No filler, no obvious info, no redundancy with code comments? |
| Currency | 15 | Do commands work? Are file references accurate? Tech stack current? |
| Actionability | 15 | Are instructions executable and copy-paste ready? Paths real? |

### Grades

- **A (90-100)**: Comprehensive, current, actionable
- **B (70-89)**: Good coverage, minor gaps
- **C (50-69)**: Basic info, missing key sections
- **D (30-49)**: Sparse or outdated
- **F (0-29)**: Missing or severely outdated

Target grade A for all generated files. If a file scores below B, revisit the generation rules and fill gaps before presenting.

### Red Flags Checklist

Before finalizing any file, verify none of these are present:
- Commands that would fail (wrong paths, missing deps)
- References to files/folders that don't exist
- Outdated tech versions
- Generic advice not specific to the project
- Empty "TODO" items
- Duplicate info across multiple CLAUDE.md files
- Copy-paste from templates without customization

---

## Step 1: Identify Target Repo

Default to the current working directory. If the user passed a path argument, use that instead.

1. Verify the directory is a git repo (`git rev-parse --git-dir`).
2. Extract the GitHub remote URL: `git remote get-url origin`.
3. Parse the org/repo name for GitHub API calls (e.g., `Sage-Bionetworks/Synapse-Repository-Services`).
4. If no remote or not a GitHub repo, note the gap and proceed with local-only analysis.

---

## Step 2: Explore the Repository (parallel agents)

Launch up to 3 Explore agents in parallel:

### Agent 1 — Build system & stack detection
Find and read:
- Manifests: `pom.xml`, `package.json`, `go.mod`, `Cargo.toml`, `requirements.txt`, `pyproject.toml`, `build.gradle`, `Gemfile`, `*.csproj`, `Makefile`, `CMakeLists.txt`, `*.sln`
- Version files: `.nvmrc`, `.java-version`, `.python-version`, `.tool-versions`, `rust-toolchain.toml`
- CI configs: `.github/workflows/*.yml`, `Jenkinsfile`, `.gitlab-ci.yml`, `buildspec.yml`, `.circleci/config.yml`
- Linter/formatter configs: `.eslintrc*`, `.prettierrc*`, `tsconfig.json`, `.flake8`, `pyproject.toml [tool.*]`, `rustfmt.toml`, `.editorconfig`, `checkstyle.xml`

Extract:
- Language + version
- Frameworks + versions
- Build/test/lint commands (verbatim from config files)
- List of linter/formatter configs (to know what NOT to put in CLAUDE.md)

### Agent 2 — Structure, module candidates & data models
- Map the full directory tree (all levels, not just top-level)
- **Include non-code directories.** Documentation directories (e.g., `docs/`) with their own build systems, conventions, or content frameworks are candidates — not just source code directories. Any directory with non-obvious patterns needs coverage.
- **Treat every directory as a CLAUDE.md candidate.** For each directory, determine:
  1. **Own file**: Does it have conventions, constraints, or patterns that differ from its parent? Indicators: own build file, specialized tech (IaC, codegen, CRDT, DDL, security, custom protocols), distinct coding patterns, high dependency fan-in, history of gotcha patterns, 5+ source files with unique conventions.
  2. **Roll up to parent**: Is it simple enough (few files, no distinct patterns, follows sibling conventions) that a mention in the parent CLAUDE.md suffices?
  3. **Covered by ancestor**: Are its patterns already documented in an ancestor's CLAUDE.md?
- Build a coverage map: for every directory in the repo, note where its patterns will be documented (own file, parent, or ancestor). Present this map in Step 5 so no directory is missed.
- Find generated code directories (flag as "never edit")
- **Locate data model definitions**: JSON schemas, protobuf files, OpenAPI/Swagger specs, GraphQL schemas, database DDL/migrations, dbt models, TypeScript type definition files, Pydantic models, dataclasses, Terraform resource definitions, Avro/Parquet schemas
- **Trace data flow**: which modules define schemas, which consume generated types, which share data shapes across boundaries
- **Identify codegen pipelines**: schema-to-POJO, proto-to-code, OpenAPI-to-client, dbt model compilation

### Agent 3 — Conventions & gotchas
- Sample 3-5 source files from different areas of the repo
- Look for non-obvious patterns: unusual import styles, custom error handling, serialization approaches, naming conventions that differ from language defaults
- Read test files for non-standard test patterns (custom runners, unusual directory layouts, integration test infrastructure)
- Check README.md for constraints or setup gotchas
- Look at recent git log (20 commits) for commit message conventions and active areas

---

## Step 2b: Deep-Dive Exploration (parallel agents)

**This step is critical.** Step 2 gives a structural overview. Step 2b reads source files deeply to find behavioral conventions — the non-obvious patterns that cause the most mistakes. Skip this step only for trivially small repos (<10 source files total).

Launch up to 3 Explore agents in parallel, one per major source directory. For each, instruct the agent to **read entire files** (not sample), focusing on:

### What to look for in EVERY major module:
1. **Return type conventions** — Do functions return tuples, dataclasses, booleans, strings? Are there inconsistencies (e.g., one function returns `(error, warning)` while all others return `(warning, error)`)? Document ALL non-obvious return types.
2. **Conditional/hidden behavior** — Template method patterns where some steps are skipped under certain conditions. Methods that behave differently based on a type field or mode flag. Document when things DON'T run, not just when they do.
3. **Reusable utility functions** — Functions that exist for common operations (validation, data loading, formatting). List them explicitly so Claude uses them instead of writing new ones. Include the module path, function name, parameters, and what it returns.
4. **Hack comments and workarounds** — Grep for `HACK`, `FIXME`, `WORKAROUND`, `XXX`. These are documented gotchas from the original authors. Each one likely needs a CLAUDE.md entry.
5. **Strict enforcement patterns** — kwargs validated via assertions, required parameters, ordering dependencies between steps. Where will Claude crash if it gets the order wrong?
6. **Naming inconsistencies** — Mixed case conventions (camelCase args but snake_case params), inconsistent class naming (some lowercase, some PascalCase). Document these so Claude matches existing patterns rather than "fixing" them.
7. **Hardcoded values** — IDs, URLs, magic numbers that appear in multiple files. If they must stay in sync, document where they all live.
8. **Test patterns** — Mock helpers (especially custom ones not in conftest), fixture composition, how test data is created, parametrization conventions, naming conventions.
9. **External tool invocations** — Subprocess calls, CLI wrappers, inter-language bridges (Python calling R, Java calling shell). Document the invocation pattern and any hacks (like `; exit 0` to suppress errors).
10. **Concurrency/locking patterns** — Mutex locks, processing flags, retry logic, timeout handling.
11. **Anti-patterns from git history** — Search for reverted commits (`git log --oneline --all --grep="Revert"`). Each revert is a lesson learned — document what was tried and why it failed as a "Do NOT" rule. Also search for defensive comments: `grep -rn "DO NOT\|NEVER\|WARNING\|CAREFUL\|don't remove\|do not change" --include="*.py" --include="*.ts" --include="*.java" --include="*.go"`.

---

## Step 3: Gather Ecosystem Context (parallel with Step 2)

**IMPORTANT: Always use MCP server tools for all GitHub, Jira, and Confluence operations. Never use the `gh` CLI — it may not be available. Use `mcp__github__*` for GitHub, `mcp__atlassian__*` for Jira/Confluence.**

### GitHub context
Use `mcp__github__*` tools:
- `mcp__github__list_pull_requests` — last 100 merged PRs. Read titles and descriptions for convention signals.
- For the 5 most interesting PRs (those mentioning conventions, architecture, or "do not"), fetch full details and review comments.
- **Mine anti-patterns from PR reviews**: Look for reviewer pushback ("don't do this", "change this approach", "use existing utility instead"), reverted PRs, and PRs that were follow-up fixes for mistakes in previous PRs. Each of these is a candidate "Do NOT" rule.
- `mcp__github__list_issues` — last 100 open issues. Look for architectural discussions, planned changes, known gotchas.
- Repository description and topics.

### Jira context
Use `mcp__atlassian__*` tools:
1. Call `mcp__atlassian__getAccessibleAtlassianResources` to get the cloudId.
2. Determine the Jira project key for this repo. Try: repo name patterns (e.g., `Synapse-Repository-Services` -> `PLFM`), or search issues mentioning the repo name.
3. `mcp__atlassian__searchJiraIssuesUsingJql` — active epics: `project = <KEY> AND type = Epic AND status != Done ORDER BY updated DESC` (limit 10).
4. Recent completed tickets (last 180 days) for work patterns.

If the project key cannot be determined, ask the user.

### Confluence context
Use `mcp__atlassian__*` tools:
1. `mcp__atlassian__searchConfluenceUsingCql` — search for `text ~ "<repo-name>" AND type = page ORDER BY lastModified DESC` (limit 10).
2. Read the top 2-3 results looking for: architecture docs, ADRs, coding standards, design decisions.

### Cross-repo detection
- Look for import/dependency references to other repos in build files (e.g., Maven groupId references, npm package names matching other Sage repos)
- Check CI/CD configs for cross-repo triggers or deployments
- If in a workspace with multiple repos, scan sibling directories for related projects

---

## Step 4: Filter Through Generation Rules

Before presenting anything to the user, apply the content principles:

1. **Remove anything enforced by existing linter/formatter/type checker configs.** If `.eslintrc` enforces semicolons, don't put "Use semicolons" in CLAUDE.md.
2. **Remove anything obvious from reading the code.** If every file uses the same import style, Claude will pick it up.
3. **Remove anything that restates the README.**
4. **Ensure every remaining item passes the quality test**: "If I remove this, will Claude mess up?"
5. **Ensure every constraint has a reason.**
6. **Check data model items**: only include shape constraints Claude would get wrong without guidance. Skip shapes that are self-evident from reading schema files.

### What NOT to Add — Examples

| Bad (remove) | Why it fails | Good (keep) |
|--------------|-------------|-------------|
| "The `UserService` class handles user operations." | Obvious from class name | *(omit entirely)* |
| "Always write tests for new features." | Generic advice, not project-specific | *(omit entirely)* |
| "The authentication system uses JWT tokens. JWT (JSON Web Tokens) are an open standard (RFC 7519)..." | Verbose, encyclopedic | "Auth: JWT with HS256, tokens in `Authorization: Bearer <token>` header." |
| "Use meaningful variable names." | Universal advice | *(omit entirely)* |
| "We fixed a bug in commit abc123 where login broke." | One-off fix, won't recur | *(omit entirely)* |

### Validation Checklist

Before finalizing, verify:
- [ ] Each item is project-specific, not generic advice
- [ ] No obvious info that Claude can infer from code
- [ ] Commands are copy-paste ready and verified against config files
- [ ] All file paths reference real, existing files
- [ ] Every constraint has a "— because Y" reason
- [ ] This is the most concise way to express each item

---

## Step 5: Present Discovery Summary

Show the user what was found and what will be generated:

```
## Repo: <name>
Examined: <list of key files read>

### Root CLAUDE.md will cover:
- Project: <2-4 sentence draft>
- Stack: <detected stack with versions>
- Commands: <N verified commands from configs>
- Data Models: <N data model flows identified>
- Conventions: <N non-obvious patterns found>
- Constraints: <N hard rules with reasons>
- [other applicable sections]

### CLAUDE.md placement plan:
#### Own file:
- <dir> — <why it needs its own file>

#### Rolled up into parent:
- <dir> → covered in <parent>/CLAUDE.md — <brief reason>

#### Covered by ancestor:
- <dir> → already covered by <ancestor>/CLAUDE.md

### From GitHub PRs:
- <convention or constraint discovered from PR reviews>

### From Jira:
- <active epic creating a constraint>

### From Confluence:
- <architectural decision affecting conventions>

### Estimated total: ~X lines root, ~Y lines per module
```

Ask the user to confirm, correct, or skip sections before generating.

---

## Step 6: Generate Files

See [references/templates.md](references/templates.md) for starter templates by project type.

For each approved CLAUDE.md:

1. Start with `<!-- Last reviewed: YYYY-MM -->` using the current month.
2. Write each applicable section following the output format.
3. Omit sections that don't apply — no empty headings.
4. Use imperative voice throughout.
5. Keep files concise but complete. Every line must earn its place, but do NOT cut behavioral conventions or reusable utility lists just to hit an arbitrary line count. Thoroughness over brevity.
6. For module-level files, only include what differs from the root CLAUDE.md. Include: reusable utilities that must not be reinvented, non-obvious return types, conditional behavior, mock/test patterns, hack workarounds, naming inconsistencies.

---

## Step 7: Review and Write

1. Present each generated file's full content to the user using diff format for easy review:
   ```
   ### File: ./CLAUDE.md
   **Quality Score: XX/100 (Grade: X)**

   ```diff
   + ## Project
   +
   + <content>
   ```

   > **Why this section helps:** <one-line justification>
   ```
2. Run the Red Flags Checklist from the Quality Validation section before presenting.
3. Apply any corrections the user requests.
4. Write all files using the Write tool.
5. Optionally commit with message: `Add initial CLAUDE.md files for AI-assisted development`

---

## Edge Cases

- **No Jira/Confluence access or credentials**: Proceed with code + GitHub only. Note the gap in the discovery summary.
- **No GitHub remote**: Proceed with local git history only.
- **Monorepo with multiple languages**: Per-module stack detection. Root file covers the monorepo orchestration tooling (Nx, Turborepo, Lerna, Maven reactor, etc.).
- **Existing README.md**: Read for context but do NOT duplicate content into CLAUDE.md. Reference it: `See README.md for setup instructions.`
- **Very large repos (many module candidates)**: Show the candidate list with justifications and let the user select which to document first. Do not generate all at once.
- **No linter/formatter configs**: More conventions may need to go in CLAUDE.md since there's no tooling enforcement. Note this in the discovery summary.
- **Repo already has CLAUDE.md files**: Warn the user and suggest using `/evolve-claudemd` instead. Do not overwrite existing files without explicit confirmation.
