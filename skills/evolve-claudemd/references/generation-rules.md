# Generation Rules & Output Format

Loaded on demand during Step 4 (filter) and whenever writing/editing CLAUDE.md content in Step 7. These rules govern every line written or kept — apply them to both new content and existing content under audit.

## Core Generation Rules

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
12. **Altitude — write detail at the lowest level that covers its scope.** A parent/ancestor CLAUDE.md loads into *every* agent's context regardless of the task, so subsystem-specific detail parked in a parent is a token tax on all unrelated work. Put deep detail in the child CLAUDE.md that owns that scope; a parent keeps only genuinely cross-cutting facts plus a one-line pointer to the child (e.g. "see `manager/search/CLAUDE.md`"). A convention recurring across N sibling subsystems is stated once at the parent as a pattern + pointers, not duplicated per child. When a subsystem has enough distinct detail to warrant it, prefer creating/deepening its child file over enlarging the parent.

## Output Format

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

## Generation Rules Filter (Step 4)

Before presenting changes to the user:

1. **New content must pass the quality test**: "If I remove this, will Claude mess up?"
2. **New constraints must have reasons.** Do not propose a constraint without a "— because Y" explanation.
3. **Remove anything now enforced by new tooling configs.** If `.eslintrc` was added and it enforces a convention currently in CLAUDE.md, flag that line for removal.
4. **Keep files concise but complete.** Every line must earn its place, but do not cut behavioral conventions, reusable utility lists, or hack documentation just to stay short. Thoroughness over brevity.
5. **Data model items**: only include shape constraints Claude would get wrong without guidance.
6. **Altitude check**: for each proposed parent-file line, ask "does an agent working on an unrelated part of this module need this?" If it's specific to one sub-package, route it to that sub-package's CLAUDE.md (creating one if warranted) and leave only a pointer in the parent.

### Validation Checklist

Before finalizing proposed changes, verify:
- [ ] Each addition is project-specific, not generic advice
- [ ] No obvious info that Claude can infer from code
- [ ] Commands are copy-paste ready and verified against config files
- [ ] All file paths reference real, existing files
- [ ] Every constraint has a "— because Y" reason
- [ ] This is the most concise way to express each item
- [ ] Detail sits at the lowest CLAUDE.md that covers its scope; parents carry cross-cutting facts + pointers, not sub-package specifics

### What NOT to Add — Examples

| Bad (remove) | Why it fails |
|--------------|-------------|
| "The `UserService` class handles user operations." | Obvious from class name |
| "Always write tests for new features." | Generic advice, not project-specific |
| Verbose multi-paragraph explanation of a concept | Condense to one actionable line |
| "We fixed a bug in commit abc123 where login broke." | One-off fix, won't recur |
