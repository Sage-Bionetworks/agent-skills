# Agent Skills
This repository contains agent skills that are leveraged across Sage Bionetworks

## Available Skills

| Skill | Description |
|---|---|
| `synapse-python-client` | General-purpose Synapse Python client operations (upload, download, tables, annotations, provenance) |
| `rare-disease/nf/tools/synapse-tables` | Query and update the NF Research Tools Central Synapse database (table IDs, SQL patterns, upsert workflows) |
| `rare-disease/nf/tools/workflows` | Understand and revise the GitHub Actions workflows in nf-research-tools-schema (publication mining, schema updates, Synapse upserts) |
| `rare-disease/nf/tools/schema` | Work with the NF Research Tools data model (CSV schema, JSON-LD, JSON form schemas, submission pipeline) |
| `rare-disease/nf/data-management/metadata-dictionary` | Work with the NF Metadata Dictionary (LinkML YAML modules, term contribution, schema generation, Synapse registration) |
| `rare-disease/nf/data-management/project-provisioning` | DSP submission intake through Synapse project creation (dcc-site workflows, review validation, doc generation) |
| `rare-disease/nf/data-management/project-lifecycle` | Project monitoring after provisioning (checkpoint system, data release, GitHub project board, Jira support tickets) |
| `rare-disease/nf/data-management/annotations-file-view` | NF Portal annotations file view syn52702673 (querying, bulk updates, search facets, schema binding, curation tasks) |
| `rare-disease/nf/data-management/nfportalutils` | R package for NF portal project setup, study registration, and checkpoint reports |
| `rare-disease/nf/data-curation/nfty-mcp-server` | Install and configure the nfty MCP server with Claude Code or Goose; full tool reference |
| `rare-disease/nf/data-curation/portal-curation` | Project review and dataset metadata generation workflows using nfty MCP tools and agent-at-work recipes |
| `rare-disease/nf/data-curation/curation-tasks` | 3-tier curation task generation pipeline (Component → rule-based → AI), GitHub Actions workflow |
| `rare-disease/nf/data-curation/atlassian` | Jira service desk triage and Confluence docs for NF-OSI using the Atlassian MCP server |
