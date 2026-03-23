# NF Research Tools GitHub Workflows Skill

## Overview
The [nf-research-tools-schema](https://github.com/nf-osi/nf-research-tools-schema) repository uses a set of GitHub Actions workflows to automate the monthly publication mining, tool submission review, Synapse database updates, and schema maintenance pipeline. This skill documents each workflow, their trigger chains, required secrets, and guidance for revising them.

## Pipeline Architecture

```
[1st of month]
  └─► monthly-submission-check.yml
        Creates GitHub issue (label: tool-submissions)

[Issue closed]
  └─► publication-mining.yml
        Mines PubMed + NF Portal, AI screens with Claude
        Opens PR (label: tool-submissions)

[PR merged to main]
  ├─► upsert-tools.yml
  │     Compiles accepted JSONs → CSV → uploads to Synapse
  │     └─► (workflow_run) update-observation-schema.yml
  │               Updates SubmitObservationSchema.json enums
  └─► score-tools.yml
        Calculates tool completeness scores, generates PDF

[Push to non-main with schema CSV changed]
  └─► schematic-schema-convert.yml
        Regenerates nf-research-tools.jsonld from CSV

[Push to main with SUBMIT_tool_datasets.csv]
  └─► upsert-tool-datasets.yml
        Uploads tool-dataset linkages to Synapse
```

## Required Secrets

| Secret | Workflows | Purpose |
|---|---|---|
| `SYNAPSE_AUTH_TOKEN` | upsert-tools, score-tools, update-observation-schema, upsert-tool-datasets, publication-mining | Read/write access to Synapse tables |
| `NF_SERVICE_GIT_TOKEN` | update-observation-schema | GitHub PAT for creating PRs (needs `contents:write`, `pull-requests:write`) |
| `ANTHROPIC_API_KEY` | publication-mining | Claude API for title/abstract screening and tool validation |

## Workflow Details

### 1. `monthly-submission-check.yml`
**Trigger:** Cron `0 9 1 * *` (monthly) or `workflow_dispatch`

**What it does:**
1. Runs `scripts/review_tool_annotations.py` — compares `individualID` annotations (syn52702673) against the tools registry (syn51730943)
2. Converts new cell line suggestions to `submissions/cell_lines/annotation_*.json`
3. Creates a PR with label `annotation-submissions` if new cell lines are found
4. Always creates a monthly GitHub issue labeled `tool-submissions` with results + submission checklist

**When to revise:**
- To change the check day/time: edit the `cron` expression
- To expand beyond cell lines: modify `scripts/review_tool_annotations.py` to check other resource types
- To change the issue template or checklist items: edit the step that creates the issue body

**Common revision pattern:**
```yaml
on:
  schedule:
    - cron: '0 9 1 * *'   # ← change schedule here
  workflow_dispatch:
```

---

### 2. `publication-mining.yml`
**Trigger:** Issue closed with label `tool-submissions`, or `workflow_dispatch`

**Inputs (for manual dispatch):**
| Input | Default | Description |
|---|---|---|
| `ai_validation` | `true` | Enable Claude AI validation |
| `max_publications` | — | Cap total publications processed |
| `force_rereviews` | `false` | Re-review previously reviewed tools |
| `skip_title_screening` | `false` | Skip title screening step |
| `skip_abstract_screening` | `false` | Skip abstract screening step |
| `max_reviews` | — | Cap number of AI full-text reviews |

**Pipeline stages:**
```
PubMed query (bench) ──┐
PubMed query (clinical) ├──► merge by PMID
NF Portal candidates ───┘
         │
         ▼
   Title screening (claude-haiku)
         │
         ▼
   Abstract screening (claude-haiku)
         │
         ▼
   Phase 1 cache: title+abstract+methods fetch
         │
         ▼
   AI validation (claude-sonnet, 4 parallel workers)
         │
         ▼
   Post-filter + dedup
         │
  confidence ≥ 0.8?
       YES ──► Phase 2 cache upgrade (Results+Discussion)
                    │
                    ▼
             Observation extraction
         │
         ▼
   Format as submission JSONs → submissions/{type}/*.json
         │
         ▼
   Open PR (label: tool-submissions, assignee: BelindaBGarana)
```

**When to revise:**
- Change AI model: update the `model:` parameter in the screening/validation steps
- Change parallel worker count: edit the `--workers 4` flag in `run_publication_reviews.py` call
- Add a new PubMed query: add a new step that calls `prepare_publication_list.py` and merge results
- Change the confidence threshold for Phase 2: edit the `--min-confidence 0.8` flag
- Change the PR assignee: edit the `assignee` field in the `gh pr create` step

**Key timeout consideration:** The workflow has a 360-minute timeout. The publication cap (`max_publications`) prevents overruns. If you add more resource types or phases, re-evaluate the timeout and cap logic.

---

### 3. `upsert-tools.yml`
**Trigger:** Push to `main` with files in `submissions/*/accepted/**/*.json`, or `workflow_dispatch` (with optional `dry_run: true`)

**What it does:**
1. Diffs changed files vs. previous commit (only processes newly accepted files, not the whole corpus)
2. Compiles `submissions/{type}/accepted/**/*.json` → `ACCEPTED_*.csv` per type
3. Validates CSV schemas with `clean_submission_csvs.py --validate`
4. Dry-run preview, then upload to Synapse tables
5. Regenerates tool coverage report and completeness scores

**Synapse upload targets:**
| Resource Type | Table ID |
|---|---|
| Animal Models | syn26486808 |
| Antibodies | syn26486811 |
| Cell Lines | syn26486823 |
| Genetic Reagents | syn26486832 |
| Resources (master) | syn51730943 |

**When to revise:**
- Add a new resource type: add a new upload step and corresponding table ID
- Change validation strictness: modify flags passed to `clean_submission_csvs.py`
- Disable dry-run preview: remove the dry-run step (not recommended)
- Change the diff strategy: edit the `git diff` command that identifies changed files

---

### 4. `score-tools.yml`
**Trigger:** PR with label `tool-submissions` merged to `main`, or `workflow_dispatch`

**What it does:**
- Runs `tool_scoring.py` to compute completeness scores for all tools
- Generates a PDF summary report via `tool_scoring_report.py`
- Uploads scores to Synapse
- Stores report as 90-day artifact `tool-scoring-report`

**When to revise:**
- Change scoring criteria: edit `tool_scoring.py`
- Change report format: edit `tool_scoring_report.py`
- Change artifact retention: modify `retention-days: 90`

---

### 5. `update-observation-schema.yml`
**Trigger:** After `Upsert Tools to Synapse` workflow completes on `main` (`workflow_run`), or `workflow_dispatch`

**What it does:**
1. Fetches current tool data from `syn51730943`
2. Updates `resourceType` and `resourceName` enum values in `NF-Tools-Schemas/observations/SubmitObservationSchema.json`
3. Creates a PR with label `schema-update` only if changes are detected (uses `NF_SERVICE_GIT_TOKEN`)

**When to revise:**
- Add more enum fields to auto-sync: extend `scripts/update_observation_schema.py`
- Change the PR label: edit the `--label schema-update` flag in the `gh pr create` step
- Run after a different upstream workflow: change the `workflows:` name in the `workflow_run` trigger

---

### 6. `upsert-tool-datasets.yml`
**Trigger:** Push to `main` with `SUBMIT_tool_datasets.csv`, or `workflow_dispatch` (default `dry_run: true`)

**What it does:** Runs `scripts/upsert_tool_datasets.py` to upload tool-dataset linkage data to Synapse (syn26486839, syn26338068).

**When to revise:**
- Change the triggering file path: edit the `paths:` filter
- Default to live run instead of dry-run: change `default: 'true'` on the `dry_run` input

---

### 7. `schematic-schema-convert.yml`
**Trigger:** Push to any non-`main` branch when `nf_research_tools.rdb.model.csv` changes, or `workflow_dispatch`

**What it does:** Installs `schematicpy==24.7.2`, runs `schematic schema convert nf_research_tools.rdb.model.csv -o nf-research-tools.jsonld`, commits and pushes the updated `.jsonld`.

**When to revise:**
- Update schematic version: change `schematicpy==24.7.2` (test carefully — schema format can change between versions)
- Change output file name: update the `-o` argument
- Run on `main` too: remove the branch exclusion filter

---

### 8. `check-tool-coverage.yml`
**Trigger:** PR with label `automated-annotation-review` merged to `main`, or `workflow_dispatch`

**What it does:** Older parallel version of publication mining that uses **Goose CLI** instead of direct Anthropic API calls. Follows the same broad pipeline but also applies `apply_pattern_suggestions.py` for mining pattern improvements.

**When to revise:** Prefer updating `publication-mining.yml` for new features. This workflow exists for backward compatibility with the Goose-based toolchain.

---

### 9. `publish-schema-viz.yml`
**Trigger:** Push to `main`

**What it does:** Deploys the `schema-viz/` directory to GitHub Pages for schema visualization.

## Common Workflow Revision Patterns

### Add a New Resource Type to the Pipeline
1. Create `NF-Tools-Schemas/{new-type}/submit{NewType}.json` (submission form schema)
2. Add the type to `nf_research_tools.rdb.model.csv` (source of truth)
3. Run `schematic-schema-convert.yml` (or trigger it by pushing the CSV change to a branch)
4. Add a new Synapse table and note its ID
5. Add an upload step in `upsert-tools.yml` for the new table ID
6. Update `publication-mining.yml` to include the new type in PubMed query logic if applicable

### Modify Claude Model Used for Screening
In `publication-mining.yml`, find the step that calls `screen_publication_titles.py` or `screen_publication_abstracts.py` and change the `--model` flag:
```yaml
- name: Screen titles
  run: python screen_publication_titles.py --model claude-haiku-4-5-20251001
```

### Add a New Required Secret
1. Add the secret to the repo under **Settings → Secrets and variables → Actions**
2. Reference it in the workflow:
```yaml
env:
  MY_NEW_SECRET: ${{ secrets.MY_NEW_SECRET }}
```

### Test a Workflow Without Triggering the Full Chain
Use `workflow_dispatch` with appropriate inputs. All workflows support manual dispatch. For `upsert-tools.yml` and `upsert-tool-datasets.yml`, always test with `dry_run: true` first.

### Change Monthly Issue Labels
```yaml
- name: Create monthly issue
  run: |
    gh issue create \
      --title "Monthly Tool Submissions - $(date +%B %Y)" \
      --label "tool-submissions" \    # ← change label here
      --body "$ISSUE_BODY"
```

## Workflow Permissions
All workflows that create PRs or issues need these permissions set at the workflow level:
```yaml
permissions:
  contents: write
  pull-requests: write
  issues: write
```

## Reference
- Workflow source: https://github.com/nf-osi/nf-research-tools-schema/tree/main/.github/workflows
- Workflow README: https://github.com/nf-osi/nf-research-tools-schema/blob/main/.github/workflows/README.md
- Scripts README: https://github.com/nf-osi/nf-research-tools-schema/blob/main/scripts/README.md
