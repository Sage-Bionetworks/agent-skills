# Agent Skills
This repository contains agent skills that are leveraged across Sage Bionetworks

## Available Skills

| Skill | Description |
|---|---|
| `synapse-python-client` | General-purpose Synapse Python client operations (upload, download, tables, annotations, provenance) |
| `rare-disease/nf/tools/schema` | NF Research Tools data model (CSV schema, JSON-LD, JSON form schemas, submission pipeline) |
| `rare-disease/nf/tools/synapse-tables` | Query and update the NF Research Tools Central Synapse database (table IDs, SQL patterns, upsert) |
| `rare-disease/nf/tools/workflows` | GitHub Actions workflows in nf-research-tools-schema (publication mining, schema updates, Synapse upserts) |
| `rare-disease/nf/metadata-dictionary` | NF Metadata Dictionary (LinkML YAML modules, term contribution, schema generation, Synapse registration) |
| `rare-disease/nf/projects/provisioning` | DSP submission intake through Synapse project creation (dcc-site workflows, review validation, doc generation) |
| `rare-disease/nf/projects/lifecycle` | Project monitoring after provisioning (checkpoint system, data release, GitHub project board) |
| `rare-disease/nf/projects/atlassian` | Jira service desk triage and Confluence docs for NF-OSI using the Atlassian MCP server |
| `rare-disease/nf/portal/annotations-file-view` | NF Portal file view syn52702673 (querying, bulk annotation updates, search facets, schema binding) |
| `rare-disease/nf/portal/nfportalutils` | R package for NF portal project setup, study registration, and checkpoint reports |
| `rare-disease/nf/agent/nfty-mcp-server` | Install and configure the nfty MCP server with Claude Code or Goose; full tool reference |
| `rare-disease/nf/agent/portal-curation` | Project review and dataset metadata generation using nfty tools and agent-at-work recipes |
| `rare-disease/nf/agent/curation-tasks` | 3-tier curation task generation pipeline (Component → rule-based → AI), GitHub Actions workflow |
