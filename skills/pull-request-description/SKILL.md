---
name: pull-request-description
description: Draft the title and description for a pull request in a Sage Bionetworks repo. Use whenever the user is opening a PR, asks for a PR title, PR summary, or PR description, wants an existing PR description rewritten or tightened, or has just finished a branch and is about to push. Reads the repo's pull_request_template.md, pulls the Jira ticket named in the branch for context, and scales the output — 3-5 bullets under the full template for complex changes, 1-2 sentences for simple ones.
---

# Pull request titles and descriptions

Produce the best possible **first draft** of a PR title and body — good enough that the
human author edits rather than rewrites it.

## Workflow

### 1. Read the change

Never describe a diff you haven't read. Gather, in order:

```bash
git branch --show-current
git merge-base --fork-point origin/HEAD HEAD 2>/dev/null || git merge-base origin/HEAD HEAD
git log --oneline <base>..HEAD
git diff <base>...HEAD --stat
git diff <base>...HEAD
```

Do not assume the base branch is `main` — repos here variously default to `main`,
`develop`, or `dev`. Read it off the remote:
`git remote show origin | grep 'HEAD branch'`. Be careful if this branch wasn't created
from that default — if its parent branch hasn't merged into `develop`/`main`/`dev` yet,
target the PR at the parent branch instead. Check similar recent PRs in the repo, or ask
the author, when it's unclear.

For a PR that already exists, `gh pr view <n> --json title,body,headRefName,baseRefName`
gives the current state; `gh pr diff <n>` gives the diff.

Read commit messages carefully. Commit bodies often carry the real reasoning — the
*why this and not that*, the thing reverted and why — which the diff alone cannot
show. That reasoning is usually the most valuable thing you can lift into the
description.

### 2. Pull the Jira ticket

Extract the ticket key (`SYNPY-1906`, `SNOW-513`, `IT-4153`, `PLFM-9608` — pattern
`[A-Za-z]{2,}-\d+`) from, in priority order: the branch name, the commit messages, the
existing PR title. Don't assume the key is upper-case where you find it — branches and
commit subjects are routinely lower- or mixed-case (`synpy-1906-fix-auth`). Match
case-insensitively, then upper-case the key before using it, since Jira itself is
upper-case in both the title and the browse URL.

If a key is found, fetch it. Try in this order:

1. **Atlassian MCP tools** if present — `getAccessibleAtlassianResources` for the
   cloudId, then `getJiraIssue` with the key. Site is `sagebionetworks.jira.com`.
2. `jira issue view <KEY>` if the CLI is installed and authenticated.
3. Neither available → say so in one line and draft from the diff; do not guess at
   ticket content.

From the ticket take: the summary, the problem statement, and above all the
**acceptance criteria**. Where the repo's template asks you to walk those criteria one
by one in the Solution section, they become the skeleton of the draft. Use the ticket for
*context you cannot see in the diff* (why this work exists, what the reporter observed)
— not as filler. Most contextual background belongs in Jira, not in the PR.

References to the ticket in the PR description's markdown should be linked, not bare —
write `[KEY-123](https://sagebionetworks.jira.com/browse/KEY-123)`, substituting the real
key, rather than plain text or a bare URL.

### 3. Read the repo's template

GitHub accepts a template at the repo root, in `docs/`, or in `.github/`, matched
case-insensitively, plus a `.github/PULL_REQUEST_TEMPLATE/` directory of multiple named
templates. Don't assume `.github/` — search for it:

```bash
find . -iname 'pull_request_template.md' -not -path '*/node_modules/*' 2>/dev/null
find . -type d -iname 'PULL_REQUEST_TEMPLATE' -not -path '*/node_modules/*' 2>/dev/null
```

One match → read it. No match → there is no template; fall back to plain
`# Problem` / `# Solution` / `# Testing` headings. More than one match (a template plus a
`PULL_REQUEST_TEMPLATE/` directory of variants) → don't guess which one applies; ask the
user which template to use.

The template is the contract, formatting included — follow it character for character.
Do not invent headings the file doesn't have, drop lines it requires, or reorder its
sections. Keep any checklist items it ships as unticked boxes for the human to confirm —
never tick a box on their behalf.

Also check for a repo-local override — `.github/skills/pull-request/SKILL.md`,
`.github/PR_GUIDELINES.md`, or PR guidance in `CONTRIBUTING.md`/`CLAUDE.md`. A repo-local
convention beats anything in this file.

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

Diff size isn't a proxy for complexity. When it's genuinely borderline, go complex but keep it tight. 

### 5. Write the title

Format: `[TICKET-###] Short imperative description`

- Bracketed ticket key first, then a space. No key → skip the bracket entirely rather
  than inventing one.
- State the outcome, not the mechanism: "Point RDS snapshot finalizer notification to
  env-specific Slack integration", not "Update V2.74.3 SQL file".
- Imperative mood, sentence case, no trailing period, aim for under ~70 characters.
- A conventional-commit verb (`fix:`, `feat:`) after the bracket is accepted but optional
  — match what the repo's recent merged PRs do.

Real merged titles live in `references/examples.md` for calibration. Since a repo's actual convention can drift from any example there, the repo's own recent merged PR titles are the ground truth.

### 6. Write the body

#### Complex changes — follow the template, 3-5 bullets

Fill every section the template defines with high-level information essential to the
section. Do not include file references unless essential to fulfilling the requirements
of the section.

- **Problem** — the technical problem, in 1-3 sentences, plus the `Ticket:` link where
  the template asks for it. Not a restatement of the title. Write it in the register the
  author would type it in: short declarative sentences, concrete nouns, no rhetorical
  framing. "We don't have a common interface for writing PR descriptions. Each dev has
  to use their own AI agent." is a finished Problem section. Prose that diagnoses costs
  and consequences you did not observe is not — it reads like a press release and the
  author will cut it.

  **The reason the work exists is usually not in the diff, and you cannot deduce it.** A
  diff shows what changed; it cannot show what the author was fed up with, what the team
  was missing, or what decision upstream produced the change. If the ticket and the
  commit bodies don't state the why, do **not** synthesize a plausible one from the
  change itself — a well-written invented motivation is the single most likely reason an
  author rewrites your draft instead of editing it. Ask them in one line ("what prompted
  this?"), or leave a checkpoint — `- [ ] ⚠️ **TODO(author):** why does this work exist?`
  — and draft everything else. 
- **Solution** — **at most 3-5 bullets** of high-level information essential to
  understanding the solution. This cap is the point: a reviewer should be able to read
  the bullets and know where to look and what to scrutinize. Lead each with a bolded
  noun: the component, file, or decision. Then one or two sentences on what changed
  and *why that choice*. Where the template
  asks for acceptance criteria, number the bullets to match the ticket's criteria. Name
  what you deliberately did *not* touch when a reviewer might expect otherwise.
- **Testing** — how it was verified, with commands or results a reviewer could rerun.
  State plainly what could not be tested and why; that is more useful than silence.

Optional sections, used in these repos and worth adding when they apply: **Not in this
PR** (deliberate scope cuts, follow-up tickets), **Note / dependency** (companion PRs,
merge ordering).

#### Simple changes — 1-2 sentences

With a template, keep its headings but put one line under each, and drop Testing when CI
is the whole story. Without one, drop the headings too — two or three plain sentences are
enough.

For example: 

```markdown
# **Problem:**

Dependabot is reporting vulnerabilities in `cryptography` and `pytest`.
See: https://github.com/Sage-Bionetworks/synapsePythonClient/security/dependabot

# **Solution:**

- Relocked the Pipfile.
- Updated `setup.cfg` to `cryptography >= 50.0.0` and `pytest ~= 9.0.3`.
```

That's a complete, merged PR description, quoted as-is. Nothing more was needed. If
Testing genuinely has content ("ran the affected DAG locally"), one line is enough.

#### Author checkpoints

Anything you could not verify or were not told becomes a **checkpoint** — a task the
author ticks off, not a sentence they have to spot. Always this shape:

```markdown
- [ ] ⚠️ **TODO(author):** confirm the finalizer task resumed in prod
```

An unticked box, the ⚠️, and the bolded `TODO(author):` label, in that order. The reason
for all three: the checkbox makes it an item of work that stays visibly open in the PR
UI, the emoji survives skimming, and the label says who owns it. Keep the boxes unticked
— the same rule as the checklist items a template ships.

Put each checkpoint in the section it belongs to (an unverified test under Testing, an
unknown motivation under Problem), not in a pile at the bottom, so the gap sits where a
reviewer would otherwise read a claim. If the draft has several, that is fine and worth
saying in your handover line. 

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

Some repos require a line disclosing AI assistance. Check the template,
`CONTRIBUTING.md`, and `CLAUDE.md`, and if one applies, append it verbatim — the wording
is usually fixed.