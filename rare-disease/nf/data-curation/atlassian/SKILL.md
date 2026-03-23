# NF Atlassian (Jira & Confluence) Skill

## Overview
The NF-OSI team uses Atlassian tools for support ticket management (Jira Service Desk) and internal documentation (Confluence). An `atlassian` MCP server is available for AI-assisted work on these platforms, referenced as `"atlassian"` in the agent-at-work reflection schema alongside the `"accent"` (Synapse) server.

- **Jira Service Desk:** https://sagebionetworks.jira.com/jira/servicedesk/projects/NFOSI/queues/custom/7
- **Project key:** `NFOSI`
- **Support email:** nf-osi@sagebionetworks.org (routes to Jira)

## Jira Service Desk Queue

External requests from PIs, data contributors, and funders arrive via nf-osi@sagebionetworks.org or the portal contact form and appear in the NFOSI service desk queue.

### Common Ticket Categories
| Category | Examples |
|---|---|
| Data upload access | Synapse permissions, storage quota, team membership |
| Metadata annotation | Template questions, valid values, schema clarifications |
| DSP updates | PI change, date extension, new datasets added |
| Embargo extension | Request to extend embargo end date |
| Portal listing | How to list a study, update a portal entry |
| Metadata dictionary | New term requests, synonym questions |
| Tool registration | Adding to NF Research Tools Central |

### Ticket Triage Process
1. Assess category and urgency
2. Link to relevant GitHub issue or DSP PR if applicable
3. For metadata dictionary requests: check if the term is a synonym of an existing value before adding a new term (see `training/CLAUDE.md` guidance — e.g., "transwell" → "Migration Assay", "xlsx" → "excel")
4. For DSP updates: update `json/dsp/{FUNDER}/{NFID}.json` in dcc-site and open a PR
5. For access issues: verify the user's Synapse username (`synPrincipal`) and check project ACLs

## Using the Atlassian MCP Server

The atlassian MCP server provides AI agents with direct access to Jira and Confluence. It is configured as the `"atlassian"` server in agent-at-work recipes.

### Connecting to Claude Code
Add to your MCP configuration (`~/.claude/settings.json`):
```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-atlassian"],
      "env": {
        "ATLASSIAN_URL": "https://sagebionetworks.jira.com",
        "ATLASSIAN_EMAIL": "your-email@sagebase.org",
        "ATLASSIAN_API_TOKEN": "${ATLASSIAN_API_TOKEN}"
      }
    }
  }
}
```

Get your API token at: https://id.atlassian.com/manage-profile/security/api-tokens

### Configuring in a Goose Recipe
```yaml
extensions:
  - type: mcp
    name: atlassian
    command: npx
    args:
      - -y
      - "@modelcontextprotocol/server-atlassian"
    env:
      ATLASSIAN_URL: https://sagebionetworks.jira.com
      ATLASSIAN_EMAIL: your-email@sagebase.org
      ATLASSIAN_API_TOKEN: ${ATLASSIAN_API_TOKEN}
```

## Common Jira Operations

### Retrieve Issues from the NFOSI Queue
```
# Via MCP tool (ask Claude to):
Get issues from NFOSI project with status "Open" in the custom queue
```

Issues in the queue have:
- `project`: NFOSI
- `issuetype`: Service Request or Bug
- `status`: Open, In Progress, Waiting for Customer, Resolved

### Add a Comment to a Ticket
```
# Ask Claude to:
Add a comment to NFOSI-1234: "Investigated — the term 'transwell' is a synonym for
'Migration Assay' in the metadata dictionary. Recommend using the existing term."
```

### Transition an Issue
Known limitation from task history: Service Desk workflow transitions (e.g., moving to "Resolved") may be restricted via API. If a transition fails, resolve through the Jira web UI instead.

### Search for Related Issues
```
# JQL (Jira Query Language) examples:
project = NFOSI AND status = "Open" AND created >= -7d
project = NFOSI AND text ~ "metadata dictionary"
project = NFOSI AND text ~ "cell line" AND status != "Resolved"
```

## Confluence Documentation

Confluence is used for internal data management documentation, SOPs, and team knowledge sharing.

### Common Documentation Tasks
- **Update SOPs** — when workflows in dcc-site or nf-metadata-dictionary change
- **Draft release notes** — for new schema versions (after running `release-new-version.yaml`)
- **Document known issues** — annotation problems, schema edge cases
- **Team onboarding** — project context for new data managers

### Known API Limitations (from task history)
- Service Desk workflow transitions are restricted for some statuses — use the web UI
- Internal comments (visible only to agents) behave differently from public customer-facing comments; check the comment type before submitting
- Field update permissions vary by issue type — some fields on Service Request tickets can't be updated via API

## Cross-System Workflows

### Jira Ticket → DSP Update
When a ticket requests a DSP change (new PI, date extension, new dataset):
1. Retrieve the ticket details via atlassian MCP
2. Identify the NFID from the ticket or by querying syn52694652
3. Update `json/dsp/{FUNDER}/{NFID}.json` in dcc-site
4. Open a PR — the `review.py` validation will catch any field errors
5. Comment on the Jira ticket with the PR link

### Jira Ticket → Metadata Dictionary Request
When a ticket requests a new metadata term:
1. Check if the term is a synonym of an existing value (search `term_synonyms.csv` in nf-metadata-dictionary)
2. If synonym: add to `term_synonyms.csv`, run `synonyms.yml` workflow
3. If genuinely new: add to the appropriate YAML module in `modules/`, open a PR
4. Comment on the ticket with resolution and expected release version

### Jira Ticket → Synapse Access Issue
1. Verify the user's Synapse username exists: `synapse_query` on a user lookup or check via `validate_synapse_user` logic in `review.py`
2. Check project ACLs and team membership via synapseclient
3. Add user to appropriate team or project with needed permissions

## Environment Variables

```bash
export ATLASSIAN_API_TOKEN="your-atlassian-api-token"
# ATLASSIAN_URL and ATLASSIAN_EMAIL configured in MCP settings
```

## Reference
- NFOSI Jira queue: https://sagebionetworks.jira.com/jira/servicedesk/projects/NFOSI/queues/custom/7
- Atlassian API tokens: https://id.atlassian.com/manage-profile/security/api-tokens
- agent-at-work task history: `training/task/validate-and-close-jira-issues.txt`
- MCP Atlassian server: https://github.com/modelcontextprotocol/servers/tree/main/src/atlassian
