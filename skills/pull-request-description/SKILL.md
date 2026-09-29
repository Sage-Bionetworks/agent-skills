---
name: pull-request-description
description: Draft the title and description for a pull request in a Sage Bionetworks repo. Use whenever the user is opening a PR, asks for a PR title, PR summary, or PR description, wants an existing PR description rewritten or tightened, or has just finished a branch and is about to push. Reads the repo's pull_request_template.md, pulls the Jira ticket named in the branch for context, and scales the output — 3-5 bullets under the full template for complex changes, 1-2 sentences for simple ones.
---

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

Do not assume the base branch is `main` — repos here variously default to `main`,
`develop`, or `dev`. Read it off the remote:
`git remote show origin | grep 'HEAD branch'`.

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

The template is the contract, and its formatting is part of it. Copy the headings
character for character — whether a repo writes `# **Problem:**` with the colon inside
the bold or a plain `# Problem` is not a detail you get to normalize. Do not invent
headings the file doesn't have, drop lines it requires, or reorder its sections. Keep any
checklist items it ships as unticked boxes for the human to confirm — never tick a box on
their behalf.

Also check for a repo-local override — `.github/skills/pull-request/SKILL.md`,
`.github/PR_GUIDELINES.md`, or PR guidance in `CONTRIBUTING.md`/`CLAUDE.md`. A repo-local
convention beats anything in this file.

Nothing in this file hardcodes which repo you are in, and it never should — base
branches, ticket prefixes, template shapes, and disclosure lines belong to the repo, not
to this skill. Re-derive them each time from the repo's own artifacts (the live template,
`CONTRIBUTING.md`, `CLAUDE.md`, its recent merged PRs) rather than from anything cached
here. A second, shadow copy of a repo's conventions would only drift from the real thing
and cost you a cross-reference for no benefit.

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

Real merged titles live in `references/examples.md` for calibration — not as a source
of ticket prefixes or conventions to copy, since a repo's actual convention can drift
from any example there. The repo's own recent merged PR titles are the ground truth.

### 6. Write the body

#### Complex changes — follow the template, 3-5 bullets

Fill every section the template defines. The Solution section carries the weight, and it
gets **at most 3-5 bullets**. This cap is the point of the skill: a reviewer should be
able to read those bullets and know where to look and what to scrutinize. If the change
seems to need eight bullets, you are listing files instead of decisions — collapse them
into the 3-5 things that actually change behavior.

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
  — and draft everything else. An
  empty Problem section costs the author thirty seconds; a convincing wrong one costs a
  rewrite, or ships and misleads the reviewer.
- **Solution** — 3-5 bullets. Lead each with a bolded noun: the component, file, or
  decision (`**Points to the correct Slack integration per environment**`,
  `**docker-compose.yaml**`). Then one or two sentences on what changed and *why that
  choice*. Where the template asks for acceptance criteria, number the bullets to match
  the ticket's criteria. Name what you deliberately did *not* touch when a reviewer might
  expect otherwise.
- **Testing** — how it was verified, with commands or results a reviewer could rerun.
  State plainly what could not be tested and why; that is more useful than silence.

Optional sections, used in these repos and worth adding when they apply: **Not in this
PR** (deliberate scope cuts, follow-up tickets), **Note / dependency** (companion PRs,
merge ordering).

#### Simple changes — 1-2 sentences

Do not force the full framework onto a small change. Where the repo ships a template,
keep its headings so the PR still looks like the others, but put one line under each and
drop Testing entirely when CI is the whole story. Where the repo ships **no** template,
drop the headings too — two or three plain sentences are a complete description for a
small change, and Problem/Solution scaffolding over them is ceremony that hides how
little there is to review. The framework serves changes a reviewer would otherwise have
to reverse-engineer; a version pin is not one of them.

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
saying in your handover line — a PR that admits four open questions is more useful than
one that quietly answers them wrong.

### 7. Check the draft before handing it over

- **Nothing invented.** This is the one that matters, and it covers the Problem section
  as much as Testing. Do not write that tests passed, that a script was run, or that a
  value was verified unless it happened in this session or appears in the commits — and
  do not state *why* the work exists unless the ticket, the commits, or the user said so.
  When something is needed but unknown, write it as an author checkpoint —
  `- [ ] ⚠️ **TODO(author):** confirm the DAG run` — rather than a confident sentence
  they might not catch.
- Every claim traceable to the diff, the commits, the ticket, or the user — motivation
  included.
- Read the Problem section back and ask: could I have written this without knowing
  anything the diff doesn't show? If yes, it is filler, and the real problem statement is
  still missing.
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

Some repos require a line disclosing AI assistance. Check the template,
`CONTRIBUTING.md`, and `CLAUDE.md`, and if one applies, append it verbatim — the wording
is usually fixed.

## Reference files

- `references/examples.md` — annotated real PR descriptions: two complex, one simple,
  plus two contrast cases showing an over-written simple PR and an invented problem
  statement next to the author's real one. Read it when drafting a complex body, when the
  right level of detail is unclear, or before writing any Problem section.