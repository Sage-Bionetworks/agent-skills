# nfty MCP Server Skill

## Overview
`nfty` ("Nifty") is the NF-OSI MCP (Model Context Protocol) server that gives AI agents direct access to Synapse data and the NF metadata dictionary. It powers the curation recipes in [agent-at-work](https://github.com/nf-osi/agent-at-work) and can be connected to Claude Code for interactive data curation work.

- **Repo:** https://github.com/nf-osi/mcp-server
- **Requires:** Python 3.10+, `SYNAPSE_AUTH_TOKEN`

## Installation

### Recommended: uvx (no separate install needed)
```bash
# From the mcp-server repo root:
uvx --from . nfty
```

### Alternative: pip
```bash
cd /path/to/mcp-server
pip install .          # production
pip install -e .       # development (editable)
```

Verify it runs:
```bash
export SYNAPSE_AUTH_TOKEN="your-token"
nfty
```

## Connecting to Claude Code

Add nfty to your Claude Code MCP configuration (`~/.claude/settings.json` or project-level `.claude/settings.json`):

```json
{
  "mcpServers": {
    "nfty": {
      "command": "uvx",
      "args": ["--from", "/path/to/mcp-server", "nfty"],
      "env": {
        "SYNAPSE_AUTH_TOKEN": "${SYNAPSE_AUTH_TOKEN}"
      }
    }
  }
}
```

Or if installed via pip:
```json
{
  "mcpServers": {
    "nfty": {
      "command": "nfty",
      "env": {
        "SYNAPSE_AUTH_TOKEN": "${SYNAPSE_AUTH_TOKEN}"
      }
    }
  }
}
```

Then restart Claude Code. The tools will appear as available MCP tools.

## Tool Reference

### Portal Metadata Tools
Used for generating and submitting dataset metadata (the `dataset_curation` recipe).

#### `synapse_query`
Execute SQL against any Synapse table or dataset.
```json
{
  "table_id": "syn51234567",
  "query": "SELECT DISTINCT assay, dataType FROM <table_id>"
}
```
Returns: `{ "row_count": N, "columns": [...], "data": [...] }`

**Note:** Use `<table_id>` as a placeholder in the query string — the tool substitutes the actual ID.

**Important:** `synapse_query` only works on Dataset entities, not raw Folders. Use `create_dataset` first to convert a folder.

---

#### `fetch_schema`
Retrieve a JSON schema from the NF metadata dictionary.
```json
{ "schema_name": "PortalDataset" }   // default
{ "schema_name": "PortalPublication" }
{ "schema_name": "PortalStudy" }
{ "schema_url": "https://..." }       // custom URL
```
Returns the full JSON schema definition.

**Workflow:** Always fetch and save the schema once, then reuse it for validating multiple datasets.

---

#### `validate_metadata`
Validate a metadata object against a saved schema file.
```json
{
  "metadata": { "name": "My Dataset", "assay": "RNA-seq", "... ": "..." },
  "schema_file": "PortalDataset.json"
}
```
Returns: validation errors, warnings, and a completeness score (0.0–1.0).

---

#### `create_dataset`
Convert a Synapse Folder into a Dataset entity so it can be queried with SQL.
```json
{
  "folder_id": "syn12345678",
  "name": "RNA-seq Dataset",        // optional, defaults to folder name + " Dataset"
  "parent_id": "syn99999999"        // optional, defaults to folder's parent
}
```
Returns: `{ "dataset_id": "syn87654321", "item_count": 150, ... }`

---

#### `submit_metadata`
Submit validated metadata as annotations on any Synapse entity.
```json
{
  "entity_id": "syn12345678",
  "metadata": {
    "name": "My Dataset",
    "assay": ["RNA-seq"],
    "dataType": ["geneExpression"],
    "species": ["Homo sapiens"]
  }
}
```
Works on Dataset, File, Folder, Project, or any annotatable Synapse entity.

---

### Project Review Tools
Used for reviewing project contents against a DSP (the `project_review` recipe).

#### `get_data_classes`
Fetch all available data classification templates from the metadata dictionary.
```json
{}   // no parameters required
{ "templates_url": "https://..." }  // optional custom URL
```
Returns YAML content with all data class templates.

---

#### `walk_project_tree`
Recursively traverse a Synapse project to find all folders.
```json
{
  "project_id": "syn99999999",
  "max_depth": 5             // optional, default 5
}
```
Returns: complete folder tree with paths and depth for each folder.

---

#### `get_project_children`
Get immediate children (folders/files) of a Synapse container.
```json
{
  "entity_id": "syn99999999",
  "include_types": ["folder", "file"]   // optional, default both
}
```
Returns: list of children with `id`, `name`, and `type`.

---

#### `count_folder_contents`
Count files and subfolders in a folder to determine if data exists.
```json
{ "folder_id": "syn12345678" }
```
Returns: `{ "file_count": N, "folder_count": M, "has_data": true }`

---

### Shared Tools

#### `get_entity_info`
Get detailed entity information including annotations.
```json
{
  "entity_id": "syn12345678",
  "include_annotations": true    // optional, default true
}
```
Returns full entity metadata and all current annotations.

---

#### `get_data_sharing_plan`
Retrieve the Data Sharing Plan JSON for a study.
```json
{ "study_id": "syn99999999" }
```
Returns the full DSP JSON document from `https://dsp.nf.synapse.org/api/dsp/json/{study_id}`.

---

## Tool-to-Workflow Mapping

| Tool | Portal Metadata | Project Review | Task Generation |
|---|:---:|:---:|:---:|
| `synapse_query` | ✓ | | |
| `fetch_schema` | ✓ | | |
| `validate_metadata` | ✓ | | |
| `create_dataset` | ✓ | | |
| `submit_metadata` | ✓ | | |
| `get_data_classes` | | ✓ | ✓ |
| `walk_project_tree` | | ✓ | ✓ |
| `get_project_children` | | ✓ | ✓ |
| `count_folder_contents` | | ✓ | ✓ |
| `get_entity_info` | ✓ | ✓ | ✓ |
| `get_data_sharing_plan` | ✓ | ✓ | ✓ |

## Configuring in a Goose Recipe

When used with Goose (agent-at-work recipes), nfty is configured per-recipe to expose only the tools needed:

```yaml
extensions:
  - type: mcp
    name: nfty
    command: uvx
    args:
      - --from
      - /path/to/mcp-server
      - nfty
    available_tools:
      - synapse_query
      - fetch_schema
      - validate_metadata
      - submit_metadata
      - get_data_sharing_plan
      - get_entity_info
```

## Error Handling

All tools return errors in a consistent format:
```json
{
  "error": "Error description",
  "details": "Additional context"
}
```

Common errors:
- **Authentication** — `SYNAPSE_AUTH_TOKEN` not set or expired
- **Not Found** — entity or DSP doesn't exist
- **Permission Denied** — token lacks access to the resource
- **Validation** — metadata doesn't conform to schema

## Troubleshooting

**Tool not appearing in Claude Code:** Restart Claude Code after editing MCP config. Check the config path is correct for your scope (user vs. project settings).

**"Tool not found" error in a recipe:** The tool must be listed in `available_tools` for that recipe. The server exposes all tools but each recipe restricts which ones the agent can call.

**Import errors with uvx:** Make sure you're running `uvx --from /path/to/mcp-server nfty` from a directory where the `pyproject.toml` is reachable.

## Reference
- Repo: https://github.com/nf-osi/mcp-server
- Full tool reference: `nfty/TOOLS.md` in the repo
- MCP protocol docs: https://modelcontextprotocol.io/
