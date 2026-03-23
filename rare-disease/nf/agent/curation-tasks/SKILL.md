# NF Curation Task Generation Skill

## Overview
Before data can be curated for the NF Portal, data managers need to know which Synapse folders require annotation and which metadata template applies to each. The [agent-at-work](https://github.com/nf-osi/agent-at-work) repo implements a 3-tier task generation pipeline that automates this assignment — from instant heuristic checks to AI-assisted classification for ambiguous cases.

## The 3-Tier System

```
Tier 0: Component annotation check       (instant, zero API cost)
    ↓ (if ambiguous or missing)
Tier 1: Rule-based template selection    (fast, regex patterns, no API calls)
    ↓ (confidence < 0.70 or ambiguous)
Tier 2: AI agent (task_generator recipe) (Claude Sonnet, for hard cases)
    ↓
task_list.json per project
    ↓
GitHub issues created as curation tasks
```

### Tier 0 — Component Annotations
`scripts/generate_folder_tasks_from_templates.py`

Checks whether files in a folder already have a `Component` annotation. If they do, the template is already known — skip Tier 1 and 2 entirely. This is the cheapest path and handles projects where previous curation has already established templates.

```bash
python scripts/generate_folder_tasks_from_templates.py \
  --study-id syn99999999 \
  --output recipes/curation/project_cache/syn99999999/task_list.json
```

### Tier 1 — Rule-Based Template Selection
`scripts/rule_based_template_selector.py`

Applies regex patterns against folder names, child folder names, file extensions, and existing annotations to assign templates with a confidence score (0.0–1.0). No API calls — runs in seconds.

```bash
python scripts/rule_based_template_selector.py \
  --study-id syn99999999 \
  --cache-dir recipes/curation/project_cache/syn99999999/ \
  --output recipes/curation/task_lists/syn99999999_tasks.json
```

**Exit codes:**
- `0` — all folders assigned with confidence ≥ 0.70 (no AI needed)
- `2` — partial — some folders ambiguous, forward to Tier 2
- other — fallback to Tier 2

**Template patterns covered (40+ templates):**
Common regex-matched templates include:
`ScRNASeqTemplate`, `RNASeqTemplate`, `WESTemplate`, `WGSTemplate`, `ProcessedGeneExpressionTemplate`, `MassSpecTemplate`, `ImagingTemplate`, `FlowCytometryTemplate`, `ClinicalDataTemplate`, `BulkRNASeqTemplate`, and more.

### Tier 2 — AI Task Generator
`recipes/curation/task_generator/task_generator.yaml`

Uses Claude Sonnet to handle folders that Tier 1 couldn't assign confidently. The agent:
1. Fetches the DSP to understand what data is expected (`get_data_sharing_plan`)
2. Walks the project tree (`walk_project_tree`)
3. Inspects folder contents and annotations (`get_entity_info`, `get_project_children`, `count_folder_contents`)
4. Compares against the full template table (80+ templates)
5. Assigns a template, confidence score, priority, and DSP mapping for each folder
6. Merges results with any Tier 0/1 output

```bash
# Run via Goose CLI (from agent-at-work/recipes/curation/)
goose run task_generator/task_generator.yaml --params studyId=syn99999999
```

## Task List Output Format

Each tier outputs a `task_list.json`. The final merged output has this structure:

```json
{
  "study_id": "syn99999999",
  "generated_at": "2026-03-23T10:00:00Z",
  "tasks": [
    {
      "folder_id": "syn12345678",
      "folder_name": "RNA_sequencing",
      "template": "RNASeqTemplate",
      "confidence": 0.95,
      "tier": 1,
      "priority": "ready",
      "dsp_mapping": "RNA_sequencing",
      "notes": "Matched by folder name pattern"
    },
    {
      "folder_id": "syn23456789",
      "folder_name": "misc_data",
      "template": null,
      "confidence": 0.0,
      "tier": 2,
      "priority": "blocked",
      "dsp_mapping": null,
      "notes": "Cannot determine template — no matching patterns or annotations"
    }
  ],
  "summary": {
    "total_folders": 5,
    "assigned": 4,
    "unassigned": 1,
    "ready_for_issue_creation": 4
  }
}
```

**Priority values:**
- `ready` — template assigned, confidence ≥ 0.70, create issue
- `pending` — template assigned but data not yet uploaded
- `blocked` — cannot assign template, needs human review
- `deferred` — skip for now (e.g., non-data folders like `docs/`)

**Confidence threshold for auto-issue creation:** 0.70

## GitHub Actions Pipeline

`generate-curation-tasks.yml` in agent-at-work orchestrates the full pipeline across all unreleased projects.

### Trigger
Manual dispatch (`workflow_dispatch`) or scheduled (configurable).

### Inputs
| Input | Default | Description |
|---|---|---|
| `run_mode` | `all_unreleased` | `all_unreleased` or `custom_projects` |
| `synapse_ids` | — | Comma-separated project IDs (for `custom_projects` mode) |
| `goose_model` | `claude-sonnet-4-5-20250929` | Model override for Tier 2 |
| `force_full` | `false` | Ignore cache, rerun all tiers |
| `dry_run` | `false` | Generate tasks but don't create GitHub issues |
| `skip_existing` | `true` | Skip folders that already have open task issues |

### Jobs
1. **prepare** — Fetches unreleased projects from syn52694652, filters by file view data status, prepares project matrix, caches task lists
2. **generate** — Matrix job: runs 3-tier pipeline per project, uploads task list artifacts (90-day retention)
3. **finalize** — Collects all task lists, triggers GitHub issue creation

### Running manually for a single project
```bash
gh workflow run generate-curation-tasks.yml \
  --repo nf-osi/agent-at-work \
  --field run_mode=custom_projects \
  --field synapse_ids=syn99999999 \
  --field dry_run=true   # preview first
```

### Caching
Task lists are cached per project in `recipes/curation/project_cache/`. On subsequent runs, cached results are reused unless `force_full: true`.

## Project Preparation Scripts

### Fetch and Filter Unreleased Projects
```bash
python scripts/prepare_project_list.py \
  --mode all_unreleased \
  --output project_list.json
```
Queries syn52694652 for projects with `dataStatus != 'Available'` and filters out those already fully cached.

### Pre-fetch Project Metadata (for faster task generation)
```bash
python scripts/prefetch_project_data.py \
  --project-list project_list.json \
  --output-dir recipes/curation/project_cache/
```
Caches folder trees, entity info, and DSP data locally to reduce API calls during generation.

## Reviewing and Acting on Task Lists

After the pipeline runs, data managers review tasks and create Synapse curation tasks for `ready` items:

```bash
# Create file-based curation tasks in nf-metadata-dictionary
cd /path/to/nf-metadata-dictionary

# For each ready task in the task list:
SYNAPSE_AUTH_TOKEN="$TOKEN" python utils/create_curation_task.py \
  --folder syn12345678 \
  --template RNASeqTemplate
```

Or use the nfty `submit_metadata` tool to directly annotate the folder with the `Component` field to record the template assignment:
```json
{
  "entity_id": "syn12345678",
  "metadata": { "Component": "RNASeqTemplate" }
}
```

## Required Environment Variables

```bash
export SYNAPSE_AUTH_TOKEN="your-synapse-token"
export GITHUB_TOKEN="your-github-token"       # for issue creation
# For Tier 2 (AI):
export ANTHROPIC_API_KEY="your-key"           # if using Claude directly
export OPENAI_API_KEY="your-key"              # if using OpenAI models
```

## Reference
- agent-at-work repo: https://github.com/nf-osi/agent-at-work
- Task generator recipe: `recipes/curation/task_generator/task_generator.yaml`
- Rule-based selector: `scripts/rule_based_template_selector.py`
- GitHub Actions workflow: `.github/workflows/generate-curation-tasks.yml`
- nf-metadata-dictionary templates: `modules/Template/` in nf-metadata-dictionary repo
