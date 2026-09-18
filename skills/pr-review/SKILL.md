# Pull request titles and descriptions

Produce the best possible **first draft** of a PR title and body — good enough that the
human author edits rather than rewrites it. The reviewer's time is the scarce resource:
a description that makes them read the diff twice has failed, and so has one that pads a
one-line dependency bump into three headed sections.

## Workflow

### 1. Read the change

Never describe a diff you haven't read. Gather, in order:

```bash
git branch --show-current
git merge-base --fork-point origin/HEAD HEAD 2>/dev/null || git merge-base origin/HEAD HEAD
git log --oneline <base>..HEAD
git diff <base>...HEAD --stat
git diff <base>...HEAD            # skip lock files, generated output, vendored dirs
```

Base branch differs by repo — `develop` for synapsePythonClient, `main` for orca-recipes,
`dev` for snowflake. Check `git remote show origin | grep 'HEAD branch'` if unsure.

For a PR that already exists, `gh pr view <n> --json title,body,headRefName,baseRefName`
gives the current state; `gh pr diff <n>` gives the diff.

Read commit messages carefully. In these repos commit bodies often carry the real
reasoning — the *why this and not that*, the thing reverted and why — which the diff
alone cannot show. That reasoning is usually the most valuable thing you can lift into
the description.

### 2. Pull the Jira ticket

Extract the ticket key (`SYNPY-1906`, `SNOW-513`, `IT-4153`, `PLFM-9608` — pattern
`[A-Z]{2,}-\d+`) from, in priority order: the branch name, the commit messages, the
existing PR title.

If a key is found, fetch it. Try in this order:

1. **Atlassian MCP tools** if present — `getAccessibleAtlassianResources` for the
   cloudId, then `getJiraIssue` with the key. Site is `sagebionetworks.jira.com`.
2. `jira issue view <KEY>` if the CLI is installed and authenticated.
3. Neither available → say so in one line and draft from the diff; do not guess at
   ticket content.

From the ticket take: the summary, the problem statement, and above all the
**acceptance criteria**. Snowflake's template asks you to walk the acceptance criteria
one by one in the Solution section, so those become the skeleton of the draft. Use the
ticket for *context you cannot see in the diff* (why this work exists, what the reporter
observed) — not as filler. Most contextual background belongs in Jira, not in the PR.

Link it as `[SNOW-513](https://sagebionetworks.jira.com/browse/SNOW-513)`.

### 3. Read the repo's template

```bash
cat .github/pull_request_template.md 2>/dev/null || cat .github/PULL_REQUEST_TEMPLATE.md
```

The template is the contract. Use its exact headings and its exact formatting —
`# **Problem:**` with the bold and the colon in synapsePythonClient and orca-recipes,
plain `# Problem` in snowflake. Do not invent headings it doesn't have, drop required
lines (snowflake's `Ticket:` line), or reorder sections. Keep any checklist items the
template ships (orca-recipes has an integration-test-DAG checkbox) as unticked boxes for
the human to confirm — never tick a box on their behalf.

Also check for a repo-local override — `.github/skills/pull-request/SKILL.md`,
`.github/PR_GUIDELINES.md`, or PR guidance in `CONTRIBUTING.md`/`CLAUDE.md`. A repo-local
convention beats anything in this file.

See `references/repo-conventions.md` for what's already known about each repo.

### 4. Decide: simple or complex

This choice sets everything downstream, so make it deliberately rather than by diff size
alone.

**Simple** — one self-evident change a reviewer can hold in their head:
dependency bumps and relocks, version pins, typo and docs fixes, config or constant
changes, renames, a single-function bug fix, test-only tweaks, reverts. The reviewer will
understand it from the diff; prose only has to say *what* and *why*.

**Complex** — anything where the diff alone leaves a reviewer guessing:
new features, refactors spanning modules, schema or data-model changes, migrations,
infrastructure and CI changes, anything with a design decision, a tradeoff, a rejected
alternative, a follow-up, or an effect beyond the files touched.

When it's genuinely borderline, go complex but keep it tight — an under-described complex
change costs a review cycle; an over-described simple one only costs a little reading.

### 5. Write the title

Format: `[TICKET-###] Short imperative description`

- Bracketed ticket key first, then a space. No key → skip the bracket entirely rather
  than inventing one.
- State the outcome, not the mechanism: "Point RDS snapshot finalizer notification to
  env-specific Slack integration", not "Update V2.74.3 SQL file".
- Imperative mood, sentence case, no trailing period, aim for under ~70 characters.
- A conventional-commit verb (`fix:`, `feat:`) after the bracket is accepted but optional
  — match what the repo's recent merged PRs do.

Real examples from these repos:

```
[SYNPY-1892] Integration test cuts
[SYNPY-1906] fix: resolve security vulnerabilities
[SNOW-513] Point RDS snapshot finalizer notification to env-specific Slack integration
[SNOW-558] Move SAML2 IdP metadata to prod environment variables
[IT-4153] Use developer AWS SSO credentials instead of shared IAM key
```

### 6. Write the body

#### Complex changes — follow the template, 3-5 bullets

Fill every section the template defines. The Solution section carries the weight, and it
gets **at most 3-5 bullets**. This cap is the point of the skill: a reviewer should be
able to read those bullets and know where to look and what to scrutinize. If the change
seems to need eight bullets, you are listing files instead of decisions — collapse them
into the 3-5 things that actually change behavior.

- **Problem** — the technical problem, in 1-3 sentences, plus the `Ticket:` link where
  the template asks for it. What breaks, what was observed, what the current code does
  wrong. Not a restatement of the title.
- **Solution** — 3-5 bullets. Lead each with a bolded noun: the component, file, or
  decision (`**Points to the correct Slack integration per environment**`,
  `**docker-compose.yaml**`). Then one or two sentences on what changed and *why that
  choice*. Where the template asks for acceptance criteria (snowflake), number the
  bullets to match the ticket's criteria. Name what you deliberately did *not* touch when
  a reviewer might expect otherwise.
- **Testing** — how it was verified, with commands or results a reviewer could rerun.
  State plainly what could not be tested and why; that is more useful than silence.

Optional sections, used in these repos and worth adding when they apply: **Not in this
PR** (deliberate scope cuts, follow-up tickets), **Note / dependency** (companion PRs,
merge ordering).

#### Simple changes — 1-2 sentences

Do not force the full framework onto a small change. Keep the template's headings so the
PR still looks like the others in the repo, but put one line under each and drop Testing
entirely when CI is the whole story:

```markdown
# **Problem:**

Dependabot is reporting vulnerabilities in `cryptography` and `pytest`.
See: https://github.com/Sage-Bionetworks/synapsePythonClient/security/dependabot

# **Solution:**

- Relocked the Pipfile.
- Updated `setup.cfg` to `cryptography >= 50.0.0` and `pytest ~= 9.0.3`.
```

That's a complete, merged PR description from this repo. Nothing more was needed. If
Testing genuinely has content ("ran the affected DAG locally"), one line is enough.

### 7. Check the draft before handing it over

- **Nothing invented.** This is the one that matters. Do not write that tests passed,
  that a script was run, or that a value was verified unless it happened in this session
  or appears in the commits. When verification is needed but hasn't happened, write it as
  a placeholder the human will notice — `TODO(author): confirm the DAG run` — rather than
  a confident sentence they might not catch.
- Every claim traceable to the diff, the commits, or the ticket.
- Solution bullets ≤ 5, each about a decision rather than a file.
- Headings match the template exactly; required lines present; checkboxes unticked.
- Title has the ticket key and reads as an outcome.
- No secrets, tokens, credentials, internal hostnames, or PHI — including in pasted test
  output.
- Jira links use the full `https://sagebionetworks.jira.com/browse/KEY` form.

Flag anything you had to guess at, in one line outside the draft.

### 8. Hand it over

Output the title and the body as copy-pasteable markdown in the reply (fenced, so the
markdown survives), then offer to open or update the PR:

```bash
gh pr create --title "..." --body-file <file> --base <base> --draft
gh pr edit <n> --title "..." --body-file <file>
```

Never push, open, or edit a PR without the user asking. This skill produces a draft for a
human editor — say so briefly, and mention anything you weren't sure about so they know
where to look first.

If the repo's convention is to disclose AI assistance, append the line the repo uses; in
snowflake that is:

```
*This text was generated in whole or part by AI and has been reviewed for correctness by myself.*
```

## Reference files

- `references/examples.md` — annotated real PR descriptions from these repos: two complex,
  one simple, plus what makes each work. Read it when drafting a complex body or when the
  right level of detail is unclear.
- `references/repo-conventions.md` — per-repo template shapes, base branches, and quirks.
  Read it when working in one of the known repos; the live template still wins.