# NF Project Provisioning Skill

## Overview
When a PI leading an NF research project submits a Data Sharing Plan (DSP), it kicks off an automated pipeline in the [dcc-site](https://github.com/nf-osi/dcc-site) repo that validates the submission, creates a review PR, and — once approved and merged with the `provision` label — creates the Synapse project, notifies stakeholders, and generates a DSP document. This skill covers that end-to-end flow.

- **DSP submission site:** https://dsp.nf.synapse.org
- **Synapse projects catalogue:** syn52694652 (materialized view)
- **GitHub project board:** https://github.com/orgs/nf-osi/projects/1

## End-to-End Pipeline

```
PI submits DSP via web form
        │
        ▼
handle_submission.yaml (repository_dispatch: "submission")
  ├─ Writes JSON → json/dsp/{FUNDER}/{NFID}.json
  ├─ Runs review.py → review_result.json + review_note.md
  └─ Creates PR: "Submission {NFID}"
        │ auto-labels based on review_result.json:
        ├─ provision         (if ready to create Synapse project)
        ├─ sync-synapse      (if grant/embargo dates changed)
        └─ doc-gen           (if DSP document needs regeneration)

Data manager reviews PR → merges to main
        │
        ▼
trigger_logic_pr_merged.yaml (routes by label)
  ├─ provision     → provision_project.yml
  │     ├─ Docker: ghcr.io/nf-osi/jobs-new-project
  │     ├─ Commits studyId (Synapse project ID) back to JSON
  │     ├─ Adds project to GitHub project board
  │     ├─ Posts Slack notification
  │     └─ Triggers doc-gen-and-send.yml
  │           ├─ Generates PDF (or DOCX for NTAP)
  │           ├─ Uploads to Synapse project folder
  │           └─ Emails PI + funder contacts
  │
  ├─ sync-synapse  → Updates Synapse annotations (grant/embargo dates)
  └─ sync-to-projectlive → Syncs to ProjectLive dashboard (syn51471723)
```

## DSP JSON Format and Storage

**Location:** `json/dsp/{FUNDER}/{NFID}.json`

**NFID naming convention:** `{INITIATIVE}_{LASTNAME}_{YEAR}` — e.g., `YIA_Doe_2022`, `VRI_Curie_Einstein_2022`

**Funders:** `NTAP`, `CTF`, `GFF`, `CDMRP`, `NIH-NCI`, `Other`

**Key fields:**
```json
{
  "NFID": "YIA_Doe_2022",
  "schemaVersion": "2023.11.29",
  "name": "Study of NF1 in pediatric tumors",
  "summary": "ASCII-safe description, no smart quotes or em-dashes",
  "fundingAgency": "NTAP",
  "initiative": "Young Investigator Award",
  "grantStartDate": "2022-01-01",
  "grantEndDate": "2025-12-31",
  "embargoEndDate": "2026-12-31",
  "PI": "Jane Doe",
  "PIEmail": "jane.doe@university.edu",
  "institution": { "name": "University of Example", "ROR": "..." },
  "synPrincipal": "jdoe_synapse",
  "dataLead": "John Smith",
  "dataLeadEmail": "john.smith@university.edu",
  "dataDeposit": [
    {
      "dataLabel": "RNA_sequencing",
      "dataType": "genomics",
      "assay": "RNA-seq"
    }
  ],
  "studyId": "syn99999999"   ← populated automatically after provisioning
}
```

## What `review.py` Validates (Provisioning Blockers)

The `review.py` script runs on every PR submission and sets `primeForProvisioning: true` only when all checks pass. These are the blocking conditions:

| Field | Validation |
|---|---|
| `name` | Valid characters after Unicode sanitization (no ™©®, smart quotes, em-dashes) |
| `studyId` | Must NOT already exist (no duplicate provisioning) |
| `PI` | Present and not a placeholder (TBD, N/A, Unknown, Pending, etc.) |
| `PIEmail` | Valid email format and not a placeholder |
| `institution` | Not a placeholder |
| `summary` | Not a placeholder |
| `synPrincipal` | Must be a valid existing Synapse username |
| `grantStartDate` | Must be present |
| `grantEndDate` | Must be present |
| `embargoEndDate` | Must be present |
| `dataDeposit` | Required unless `dataSharingWaived: true` |
| `dataLabel` in datasets | Valid characters after sanitization |

Other flags set by `review.py` (non-blocking but drive labeling):
- `syncSynapse: true` — grant or embargo dates changed
- `docgen: true` — governance, datasets, or dates changed; new submission

## Provisioning Workflow (`provision_project.yml`)

**Trigger:** PR with `provision` label merged to `main`, or manual dispatch

**Modes:**
- `auto` (default): detects changed JSON files via `git diff HEAD~1`
- `custom`: uses a specified file path (for manual reruns)

**What happens:**
1. Pulls Docker image `ghcr.io/nf-osi/jobs-new-project:latest`
2. Runs container with the study JSON config
3. Container creates the Synapse project and writes `studyId` back into the JSON
4. Validates `studyId` was populated (fails loudly if not)
5. Determines storage limit: NTAP → 100GB, CTF/GFF → unlimited
6. Adds project to GitHub project board (via `sync/to_project_board.sh`)
7. Posts Slack notification with NFID, PI, name, institution, Synapse ID, funder
8. Commits `studyId` back to `main` (rebases to handle concurrent provisions)
9. Triggers `doc-gen-and-send.yml`

**Concurrency:** Only one provision workflow runs at a time (queued, not cancelled).

## Document Generation (`doc-gen-and-send.yml`)

**Trigger:** Called by `provision_project.yml` or manual dispatch

**Format by funder:**
- NTAP → DOCX
- CTF, GFF, CDMRP, NIH-NCI, Other → PDF

**Output filename:** `{NFID}_dsp.{pdf|docx}`

**What happens:**
1. Verifies `studyId` is populated (retries up to 5× with 3s delay)
2. Runs Docker image `ghcr.io/nf-osi/dcc-site-doc-gen`
3. Finds or creates "Data Sharing Plan" folder in the Synapse project
4. Uploads document (versioned)
5. Emails: PI + funder contacts + data leads + nf-osi@sagebionetworks.org
   - Sent from `nf-service@sagebase.org` via Gmail App Password
   - Different template for new projects vs. DSP updates

## Reviewer Assignment Logic

PRs are auto-assigned based on:
1. `dccReviewer` field in the submitted form (initials → GitHub username):
   - `ANV` → `anngvu`
   - `AN` → `aditya-nath-sage`
   - `CIM` → `changtotheintothemoon`
   - `JB` → `jaybee84`
   - `RA` → `allaway`
2. Fallback by funding agency: NTAP → `changtotheintothemoon`, CTF → `aditya-nath-sage`, GFF → `anngvu`, other → `allaway`

## Manual Operations

### Re-run Provisioning for a Specific File
Use `workflow_dispatch` on `provision_project.yml` with:
- `mode: custom`
- `file: json/dsp/NTAP/YIA_Doe_2022.json`

### Manually Generate a DSP Document
Use `workflow_dispatch` on `doc-gen-and-send.yml` with:
- `mode: custom`
- `file: json/dsp/NTAP/YIA_Doe_2022.json`
- `send: Synapse` or `Synapse and email`

### Create a New Study Intake Entry
1. Create `json/dsp/{FUNDER}/{INITIATIVE}_{LASTNAME}_{YEAR}.json` with required fields
2. Open a PR titled `Submission {NFID}` manually
3. Add label `provision` when ready to create the Synapse project

### Sync Synapse Annotations Manually
The `sync-synapse` label on a merged PR updates Synapse entity annotations. To do this manually:
```bash
synapse set-annotations \
  --id syn99999999 \
  --annotations '{"grantStartDate": "2022-01-01", "grantEndDate": "2025-12-31", "embargoEndDate": "2026-12-31"}'
```

### Sync Data Model Updates from nf-metadata-dictionary
Run `handle_data_model_update.yaml` via `workflow_dispatch`. It:
1. Creates a branch `sync/dm-{run_id}`
2. Runs `sync/from_data_model.sh` to pull updated fields from nf-metadata-dictionary
3. Creates a PR for review

## Required Secrets

| Secret | Purpose |
|---|---|
| `SYNAPSE_AUTH_TOKEN` | Synapse project creation, annotation updates, document upload |
| `NF_SERVICE_DCC_SITE` | GitHub token (nfosi-service account) for committing studyId back |
| `GMAIL_APP_PASSWORD` | Email delivery from nf-service@sagebase.org |
| `GITHUB_TOKEN` | Standard GitHub Actions token |

## Study JSON Schema Constraints

Field format rules from `lib/study-schema.json`:
- `NFID`: No `/\:*?"<>|` characters
- `name`: Only `[a-zA-Z0-9,_. \-+()']+`
- `summary`: ASCII only, no smart characters (sanitized by `review.py`)
- `synPrincipal`: Alphanumeric only

## Synapse Projects Catalogue

All provisioned projects are catalogued in Synapse materialized view **syn52694652**. Query it to find projects by funder, PI, status, or dates:

```python
import synapseclient
syn = synapseclient.login()

results = syn.tableQuery(
    "SELECT NFID, name, PI, fundingAgency, studyId, grantEndDate, embargoEndDate "
    "FROM syn52694652 "
    "WHERE fundingAgency = 'NTAP'"
)
df = results.asDataFrame()
```

## Reference
- dcc-site repo: https://github.com/nf-osi/dcc-site
- DSP submission site: https://dsp.nf.synapse.org
- Synapse projects catalogue: https://www.synapse.org/Synapse:syn52694652/tables/
- GitHub project board: https://github.com/orgs/nf-osi/projects/1
- Intake SOP: `sop/intake.md` in dcc-site
- Technical SOP: `sop/technical.md` in dcc-site
