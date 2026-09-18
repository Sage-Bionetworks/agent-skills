# Per-repo conventions

Snapshot of what these repos expect. The live `.github/pull_request_template.md` always
wins over this file — re-read it each time, since templates change.

## Sage-Bionetworks/synapsePythonClient

- Base branch: `develop`
- Ticket prefix: `SYNPY-`
- Headings: `# **Problem:**`, `# **Solution:**`, `# **Testing:**` — bold, colon inside the
  bold, exactly as written.
- Template prompts for: how the problem was reproduced and what code is affected; why this
  solution, any technical debt incurred, links to design docs; how the solution was tested
  and which automated tests were added.
- Testing sections here often carry measured before/after numbers (API call counts,
  runtime) in fenced blocks. Include them when the change is a performance or
  test-load change and the numbers exist — never invent them.
- Simple PRs in this repo routinely ship with Problem + Solution only, no Testing section.

## Sage-Bionetworks-Workflows/orca-recipes

- Base branch: `main`
- Ticket prefixes: `IT-`, `DPE-`, `ORCA-`
- Headings: identical to synapsePythonClient (`# **Problem:**` etc.).
- The Testing section ships a checklist item:
  `- [ ] Ran the relevant integration test DAGs and they PASS.` Keep it, leave it
  unticked, and link the CONTRIBUTING.md section it references.
- Airflow/infra changes benefit from an explicit "Reviewer verification" list of commands
  — this repo's reviewers run them.

## Sage-Bionetworks/snowflake

- Base branch: `dev` (changes flow dev → main; `snowsql_admin` runs only on `main`)
- Ticket prefix: `SNOW-`
- Title **must** be prefixed with the Jira ticket — the template says so explicitly.
- Headings: plain `# Problem`, `# Solution`, `# Testing` (no bold, no colon).
- A `Ticket: [SNOW-###](https://sagebionetworks.jira.com/browse/SNOW-###)` line under
  `# Problem` is required.
- Solution must walk the ticket's **acceptance criteria as a numbered list**, one entry
  per criterion, each saying how it was addressed — with permalinks to specific lines
  where that helps. Pull the criteria from Jira; if Jira is unreachable, leave numbered
  placeholders rather than guessing.
- Testing must give *reproducible, self-contained* code blocks a reviewer can paste into a
  fresh worksheet. If something genuinely can't be tested (account-level changes, anything
  gated on `main`), say why — the template explicitly allows this.
- Schema-free changes note `skip_cloning` applied. Migrations are versioned SQL files
  (`V<major>.<minor>.<patch>__description.sql`); name the new file in the Solution.
- Reference-style Jira link definitions at the bottom of the body are common here:
  `[SNOW-558]: https://sagebionetworks.jira.com/browse/SNOW-558`
- AI-assistance disclosure line is used in this repo:
  `*This text was generated in whole or part by AI and has been reviewed for correctness by myself.*`

## Other Sage repos

No template found → default to the Problem / Solution / Testing shape above with
`# **Problem:**` styling, since that's the house standard. Ticket prefixes seen across the
org include `PLFM-`, `SYNPY-`, `SNOW-`, `IT-`, `DPE-`; all live at
`sagebionetworks.jira.com`.

## Repo-local overrides

A repo may ship its own PR guidance that supersedes this skill. Check, in order:

1. `.github/skills/pull-request/SKILL.md`
2. `.github/PR_GUIDELINES.md`
3. PR sections of `CONTRIBUTING.md` or `CLAUDE.md`

If one exists, follow it and mention in one line which file you followed.