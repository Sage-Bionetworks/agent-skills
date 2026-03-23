# NF Project Lifecycle Skill

## Overview
After a Synapse project is provisioned, data managers monitor it through its active phase, approach to grant end, and data release (embargo end). This is tracked on the GitHub project board, automated via checkpoint workflows in dcc-site, and supported via Jira for external tickets.

- **GitHub project board:** https://github.com/orgs/nf-osi/projects/1 ("Managed Synapse Projects")
- **Synapse projects catalogue:** syn52694652
- **Support tickets:** nf-osi@sagebionetworks.org → [NFOSI Jira queue](https://sagebionetworks.jira.com/jira/servicedesk/projects/NFOSI/queues/custom/7)

## Project Status Lifecycle

```
Provisioned
    │
    ▼
Active  ──(30 days before grantEndDate)──►  checkpoint:grant-end
    │
    │   DCC reviews data completeness,
    │   prepares for project closure
    │
    ▼
Completed
    │
    ▼ (30 days before embargoEndDate)
checkpoint:data-release
    │
    │   DCC checks annotations,
    │   file-level metadata, access controls
    │
    ▼
Data: Under Embargo → Partially Available or Available
```

## GitHub Project Board

The board at https://github.com/orgs/nf-osi/projects/1 tracks every provisioned Synapse project. Fields populated automatically at provisioning:

| Field | Populated By |
|---|---|
| Synapse Project ID | `sync/to_project_board.sh` after provisioning |
| Study Status | Default: "Active" |
| PI name + email | From DSP JSON |
| Grant start/end dates | From DSP JSON |
| Embargo end date | From DSP JSON |

**Updating board fields manually:**
Use the GitHub UI or `gh` CLI to update project item fields:
```bash
gh project item-edit \
  --project-id PVT_kwDOBEGo_s4AFMDD \
  --id <item-id> \
  --field-id PVTSSF_lADOBEGo_s4AFMDDzgC_mJI \
  --single-select-option-id <option-id>
```

## Checkpoint System (Automated Reminders)

### How It Works
The `checkpoint_scheduler.yaml` workflow runs daily and scans all project issues for upcoming dates. When a project enters a 30-day window before its `grantEndDate` or `embargoEndDate`, the corresponding label is automatically added to its GitHub issue.

### checkpoint:grant-end
**Triggered:** 30 days before `grantEndDate`

**What happens automatically:**
1. `checkpoint_support.yaml` adds the grant-end checklist from `sop/project-grant-end-checklist.md` as a comment on the issue
2. `checkpoint_report.yaml` generates an R-based data status report (via `ghcr.io/nf-osi/nfportalutils`) and posts it as a comment

**Data manager actions (from checklist):**
- Confirm data deposit completeness against DSP
- Check file-level metadata annotations are complete
- Confirm embargo end date is correct
- Update study status to "Completed" in Synapse and on the board
- Notify PI of upcoming data release

### checkpoint:data-release
**Triggered:** 30 days before `embargoEndDate`

**What happens automatically:**
1. `checkpoint_support.yaml` adds the data-release checklist from `sop/project-data-release-checklist.md`
2. Report generated as above

**Data manager actions (from checklist):**
- Review all files for annotation completeness (individualID, specimenID, dataType, assay, etc.)
- Confirm access permissions (ACLs) allow public access for release
- Update `dataStatus` annotation on the Synapse project
- Update portal tables (Portal - Studies, Portal - Files)
- Notify PI

### Manually Triggering a Checkpoint Report
```bash
# Run workflow_dispatch on checkpoint_report.yaml with the issue number
gh workflow run checkpoint_report.yaml \
  --repo nf-osi/dcc-site \
  --field issue_number=42
```

### Manually Triggering the Scheduler
```bash
gh workflow run checkpoint_scheduler.yaml --repo nf-osi/dcc-site
```

## Querying Project Status from Synapse

```python
import synapseclient
import pandas as pd
from datetime import datetime, timedelta

syn = synapseclient.login()

# All active projects approaching grant end in next 90 days
results = syn.tableQuery("""
    SELECT NFID, name, PI, fundingAgency, studyId, grantEndDate, embargoEndDate
    FROM syn52694652
    WHERE studyStatus = 'Active'
""")
df = results.asDataFrame()

# Find projects with grant end within 90 days
df['grantEndDate'] = pd.to_datetime(df['grantEndDate'])
cutoff = datetime.now() + timedelta(days=90)
approaching = df[df['grantEndDate'] <= cutoff]
print(approaching[['NFID', 'name', 'PI', 'grantEndDate']])
```

```python
# Projects with embargo ending soon
results = syn.tableQuery("""
    SELECT NFID, name, studyId, embargoEndDate
    FROM syn52694652
    WHERE dataStatus = 'Under Embargo'
    ORDER BY embargoEndDate ASC
""")
df = results.asDataFrame()
```

## Updating Synapse Project Annotations

When grant or embargo dates change (PR merged with `sync-synapse` label), the workflow runs:
```bash
synapse set-annotations \
  --id syn99999999 \
  --annotations '{
    "grantStartDate": "2022-01-01T00:00:00.000-08:00",
    "grantEndDate": "2025-12-31T00:00:00.000-08:00",
    "embargoEndDate": "2026-12-31T00:00:00.000-08:00"
  }'
```
Dates are stored in PT timezone. To do this manually:
```python
import synapseclient
syn = synapseclient.login()

entity = syn.get("syn99999999")
entity.annotations["grantEndDate"] = ["2025-12-31T00:00:00.000-08:00"]
entity.annotations["embargoEndDate"] = ["2026-12-31T00:00:00.000-08:00"]
entity.annotations["studyStatus"] = ["Completed"]
syn.store(entity)
```

## ProjectLive Dashboard Sync

When a PR is merged with the `sync-to-projectlive` label, `sync/to_projectlive.py` syncs the study to the ProjectLive dashboard table (syn51471723). To run manually:
```bash
cd /path/to/dcc-site
SYNAPSE_AUTH_TOKEN="$TOKEN" python3 sync/to_projectlive.py
```

## Support Tickets (Jira)

External support requests from PIs, data contributors, and funders are submitted to **nf-osi@sagebionetworks.org**, which routes to the NFOSI Jira service desk.

- **Queue:** https://sagebionetworks.jira.com/jira/servicedesk/projects/NFOSI/queues/custom/7
- **Project key:** NFOSI

Common ticket categories:
- Data upload access issues (Synapse permissions)
- Metadata annotation questions
- Data sharing plan updates
- Embargo extension requests
- Portal listing questions

When a ticket requires a DSP update or re-provisioning, cross-reference the NFID and update `json/dsp/{FUNDER}/{NFID}.json` in dcc-site, then open a PR as usual.

## Adding a New Funder

From `sop/technical.md`, the 7 steps to add a new funder:
1. Add funder JSON config to `lib/{FUNDER}.json` (contact emails, embargo period, full name, initiatives)
2. Add funder to the `fundingAgency` enum in `lib/study-schema.json`
3. Create API route directory `pages/api/dsp/{FUNDER}/`
4. Add `[onfile].js` and `submit.js` API routes
5. Create `json/dsp/{FUNDER}/` directory
6. Add funder view to frontend (`pages/dsp/`)
7. Update reviewer assignment logic in `handle_submission.yaml`

## Deployment

The dcc-site app deploys automatically:
- **Production:** push to `main` → `deploy.yaml` → Vercel
- **Preview:** push to any branch → `preview.yaml` → Vercel preview URL
- Production deployments should be committed from the `nfosi-service` account

## Required Secrets

| Secret | Purpose |
|---|---|
| `SYNAPSE_AUTH_TOKEN` | Synapse annotation updates, report generation |
| `NF_SERVICE_DCC_SITE` | GitHub token for committing back to repo |
| `GITHUB_TOKEN` | Issue/PR/project board management |
| `GMAIL_APP_PASSWORD` | Email notifications from nf-service@sagebase.org |
| `VERCEL_*` | Deployment |

## Reference
- dcc-site repo: https://github.com/nf-osi/dcc-site
- GitHub project board: https://github.com/orgs/nf-osi/projects/1
- Synapse projects catalogue: https://www.synapse.org/Synapse:syn52694652/tables/
- NFOSI Jira queue: https://sagebionetworks.jira.com/jira/servicedesk/projects/NFOSI/queues/custom/7
- Managed projects automation SOP: `sop/managed-projects-automation.md` in dcc-site
- Grant-end checklist: `sop/project-grant-end-checklist.md` in dcc-site
- Data-release checklist: `sop/project-data-release-checklist.md` in dcc-site
