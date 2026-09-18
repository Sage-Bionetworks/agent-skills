# Annotated examples

Real merged PRs from Sage Bionetworks repos, lightly abridged. Read these for calibration
on *level of detail*, not as templates to fill in.

---

## Complex: snowflake #405

Title: `[SNOW-513] Point RDS snapshot finalizer notification to env-specific Slack integration`

```markdown
# Problem

Ticket: [SNOW-513](https://sagebionetworks.jira.com/browse/SNOW-513)

The failure of the finalizer task in prod (SYNAPSE_DATA_WAREHOUSE) is causing the root
task to auto-suspend. I manually resumed the tasks in the graph the other day, but the
graph will auto-suspend again soon unless we disable the auto-suspension or fix the
finalizer task (this PR).

Separately, while fixing this, we noticed the finalizer's Slack message reports
`X/157 record types loaded`, but only 14 `COPY_*` load tasks actually exist. The prior
count also relied on `information_schema.load_history` with a `last_load_time` filter,
which the code's own TODO admitted didn't reliably scope to a single graph run.

# Solution

New versioned script `V2.74.3__fix_rds_snapshot_finalizer_slack_integration.sql` which:

1. **Points to the correct Slack integration per environment** — a Jinja
   `{% if database_name == 'SYNAPSE_DATA_WAREHOUSE' %}` conditional selects the bare prod
   name `SLACK_INGEST_UPDATES`; every other case falls through to `DEV_SLACK_INGEST_UPDATES`.
2. **Fixes the record-count reporting** — replaces the hardcoded `157` and the
   `load_history` lookup with a single `task_history()` query scoped by
   `graph_run_group_id` and `STARTSWITH(UPPER(name), 'COPY_')`, giving an exact,
   run-scoped count that tracks additions/removals of `COPY_*` tasks going forward.

The script follows the same suspend-root → `CREATE OR REPLACE TASK` → resume shape as
`V2.71.5`, since `CREATE OR REPLACE TASK` on a task with a `FINALIZE` relationship needs
the root suspended first.

Only the finalizer task is recreated; the 14 `COPY_*` child tasks and `PROXY_TASK_A` are
untouched.

# Testing

- Verified the Jinja conditional renders to valid SQL for both `database_name` values via
  a local `jinja2.Template` render.
- Deployed `V2.74.3` to this PR's zero-copy dev clone via `test_with_clone` CI (passed)
  and confirmed via `GET_DDL('TASK', ...)` that the rendered body selected
  `DEV_SLACK_INGEST_UPDATES` for the non-prod clone database.
- **Caught and fixed a real bug during validation**: the filter originally used
  `LIKE 'COPY\_%' ESCAPE '\'`, an invalid Snowflake string literal. `CREATE TASK` doesn't
  eagerly validate its body, so this would only have surfaced at execution time, silently
  re-breaking the finalizer. Simplified to `STARTSWITH(UPPER(name), 'COPY_')`, which has
  no escape semantics at all.
- Could not fully execute the task graph end-to-end in the clone: manual triggering hit
  `EXECUTE MANAGED TASK privilege must be granted to owner role`. This is a pre-existing
  gap in the clone-testing workflow, unrelated to this fix, and worth a follow-up ticket.

A related, independently-shippable change for SNOW-513 is tracked in #406. Neither PR
depends on the other.

[SNOW-513]: https://sagebionetworks.jira.com/browse/SNOW-513
```

**Why it works.** Two Solution bullets, each a decision rather than a file. The Problem
says what is actively breaking and what happens if nobody merges this. Testing admits
what could not be verified and why, and separates a pre-existing gap from this change.
The last paragraph tells the reviewer they don't need to sequence this with #406.

---

## Complex: orca-recipes #171

Title: `[IT-4153] Use developer AWS SSO credentials instead of shared IAM key`

```markdown
# **Problem:**

Local development authenticates to AWS Secrets Manager (`dpe-prod`) using a **shared**
`airflow-secrets-backend` IAM access key, fanned out as GitHub Codespace secrets and
injected into the docker-compose stack. That key must be manually rotated every 90 days
for CIS 1.14 ([IT-4153](https://sagebionetworks.jira.com/browse/IT-4153)), and a shared
long-lived key handed to every developer is itself a security smell.

# **Solution:**

Developers authenticate with their **own** AWS Identity Center (SSO) credentials — the
existing `dpe-prod` `Developer` permission set — so there is no shared key to rotate. The
secrets backend uses boto3's default credential chain, so SSO-derived credentials resolve
transparently.

- **`docker-compose.yaml`**: add `AWS_PROFILE` / `AWS_REGION` passthrough and an optional
  read-only `~/.aws` mount, while keeping the existing exported-credential passthrough.
- **`scripts/aws-sso-to-env.sh`** (new): logs in via SSO and writes short-lived
  credentials into `.env` (strips any stale ones first).
- **`.env.example`**: two labeled, mutually-exclusive credential blocks.
- **`README.md` / `CONTRIBUTING.md`**: new "AWS credentials" section; removed the
  shared-IAM-user and manual-90-day-rotation guidance.

Codespaces remains supported — just SSO-authenticated per developer.

# **Testing:**

- `docker compose config` renders successfully: `AWS_PROFILE` interpolates, `AWS_REGION`
  defaults to `us-east-1`, and the `~/.aws` mount resolves read-only at
  `/home/airflow/.aws`.
- `bash -n` syntax check on the helper script.

Reviewer verification:

1. `aws sso login --profile <p>`; set `AWS_PROFILE` in `.env`; `docker compose up --build
   --detach`; run the boto3 snippet in the README → lists secrets with no
   `UnrecognizedClientException`.
2. Codespaces path: unset `AWS_PROFILE`; `bash scripts/aws-sso-to-env.sh <p>`; same
   snippet succeeds.

## Note / dependency

Deployed Airflow's keyless access is handled by companion PR #88. The shared key and its
Codespace secrets should be deleted only **after both PRs are live and verified**.
```

**Why it works.** Four bullets, each naming the file plus what it now does. A short lead
paragraph carries the design decision so the bullets don't have to. The "Reviewer
verification" block is a script the reviewer can run — much stronger than "tested
locally". The dependency note prevents someone deleting the key too early.

---

## Simple: synapsePythonClient #1441

Title: `[SYNPY-1906] fix: resolve security vulnerabilities`

```markdown
# **Problem:**

See: <https://github.com/Sage-Bionetworks/synapsePythonClient/security/dependabot>

# **Solution:**

- Relock the pipfile
- Updated `setup.cfg` to have `cryptography >= 50.0.0` and `pytest ~= 9.0.3`
```

**Why it works.** Two bullets and a link, no Testing section, and it merged. The change
is self-evident from the diff; more prose would have added reading time without adding
information. This is the target for simple PRs — do not expand it.

---

## Contrast: what an over-written simple PR looks like

Same change, padded:

> # **Problem:**
> The repository currently has several outstanding security advisories reported by GitHub
> Dependabot affecting transitive and direct dependencies. These vulnerabilities pose a
> potential risk to the security posture of the project and should be addressed promptly
> to maintain compliance...
>
> # **Solution:**
> - Regenerated the `Pipfile.lock` to pick up patched versions
> - Bumped `cryptography` to `>= 50.0.0` in `setup.cfg`
> - Bumped `pytest` to `~= 9.0.3` in `setup.cfg`
> - Updated `tests_require` and `extras_require` accordingly
> - Verified no breaking API changes in the updated packages
>
> # **Testing:**
> - CI passed on all supported Python versions
> - No regressions observed in the existing test suite

Three problems: the Problem section says nothing the title didn't, the Solution splits
one edit across three bullets, and the Testing claims ("verified no breaking API
changes", "no regressions observed") are things the author may not have actually done.
That last one is the most damaging — a reviewer who trusts it skips a check.
---

## Contrast: an invented problem statement vs. the author's

From this skill's own PR (agent-skills #15). The draft's Problem section, written from
the diff alone:

> PR descriptions across our repos are inconsistent in a way that costs reviewers time in
> both directions: some changes ship with a title and nothing else, while one-line
> dependency bumps arrive padded into three headed sections. Each repo also has its own
> template shape — `# **Problem:**` with the bold and colon in synapsePythonClient and
> orca-recipes, plain `# Problem` plus a required `Ticket:` line in snowflake — and those
> differences are easy to get wrong when writing by hand or from memory.

What the author actually wrote:

> For simple changes, we can't force them into a problem-solution framework. We don't have
> a "common interface" for writing PR descriptions. Each dev has to use their own AI agent
> to generate the PR description.

The draft is three times longer and carries less. Every symptom in it was reverse-engineered
from the skill's contents — nobody observed reviewers losing time "in both directions," and
the repo-template paragraph is a summary of the diff wearing a problem's clothes. The
author's version names the actual driver, which is organizational and appears nowhere in
the diff: there is no shared interface, so every developer improvises one with their own
agent. No amount of reading the change would have produced that sentence.

Two lessons, in order of importance:

1. **The motivation is an input, not an output.** It comes from the ticket, the commit
   bodies, or the author. When none of them supply it, ask or leave
   `- [ ] ⚠️ **TODO(author):** why does this work exist?` as a checkpoint. Do not derive
   it from the diff — a fluent invented
   rationale is harder for the author to catch than a blank.
2. **Match the author's register.** Short declarative sentences, plain nouns, no
   consequence-diagnosis. If a line would not survive the author saying it out loud to a
   teammate, cut it.
