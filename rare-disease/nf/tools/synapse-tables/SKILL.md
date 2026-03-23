# NF Research Tools Synapse Tables Skill

## Overview
The NF Research Tools Central database lives in Synapse project **syn26338068** as a set of relational tables. This skill covers querying, updating, and maintaining those tables programmatically using the `synapseclient` Python package (see the `synapse-python-client` skill for general client setup).

## Synapse Table IDs

### Core Registry
| Table | Synapse ID | Description |
|---|---|---|
| Resource (all tools) | `syn51730943` | Master registry — one row per tool across all types |
| Tool Datasets (linkages) | `syn26486839` | Links tools to Synapse datasets |
| Portal root | `syn26338068` | Parent project; use for browsing the full hierarchy |

### Type-Specific Detail Tables
| Resource Type | Synapse ID |
|---|---|
| Animal Models | `syn26486808` |
| Antibodies | `syn26486811` |
| Cell Lines | `syn26486823` |
| Genetic Reagents | `syn26486832` |
| Computational Tools | (query `syn51730943` filtered by `resourceType`) |

### Supporting Tables
| Table | Synapse ID | Description |
|---|---|---|
| Cell Line Annotations | `syn52702673` | `individualID` annotations on files in the NF portal — used to identify which cell lines have datasets |

## Schema Structure

The database is derived from `nf_research_tools.rdb.model.csv` in the [nf-research-tools-schema](https://github.com/nf-osi/nf-research-tools-schema) repo. Core fields shared across all resource types:

| Field | Type | Notes |
|---|---|---|
| `resourceId` | STRING (PK) | Unique identifier (e.g., `NF-R-0001`) |
| `resourceName` | STRING | Display name |
| `resourceType` | STRING | One of the 9 types below |
| `description` | STRING | Free-text description |
| `dateAdded` | DATE | When first entered |
| `dateModified` | DATE | Last updated |

### Resource Types (valid `resourceType` values)
- `Animal Model`
- `Cell Line`
- `Antibody`
- `Genetic Reagent`
- `Biobank`
- `Computational Tool`
- `Advanced Cellular Model`
- `Patient-Derived Model`
- `Clinical Assessment Tool`

### Relational Structure (key foreign key relationships)
```
Resource (syn51730943)
  ├── AnimalModelDetails   (animalModelId)
  ├── AntibodyDetails      (antibodyId)
  ├── CellLineDetails      (cellLineId) → Donor (donorId)
  │     └── Mutation       (cellLineId) → MutationDetails
  ├── GeneticReagentDetails (geneticReagentId)
  ├── BiobankDetails       (biobankId)
  ├── ComputationalToolDetails (computationalToolId)
  ├── AdvancedCellularModelDetails (advancedCellularModelId)
  ├── PatientDerivedModelDetails (patientDerivedModelId)
  ├── ClinicalAssessmentToolDetails (clinicalAssessmentToolId)
  ├── VendorItem           (resourceId) → Vendor (vendorId)
  ├── Observation          (resourceId, publicationId)
  ├── ResourceApplication  (resourceId)
  ├── Development          (resourceId, investigatorId, publicationId, funderId)
  └── Usage                (resourceId, publicationId)
```

## Common Operations

### Query the Master Resource Table
```python
import synapseclient
import pandas as pd

syn = synapseclient.login()  # uses SYNAPSE_AUTH_TOKEN env var or ~/.synapseConfig

# Get all tools
results = syn.tableQuery("SELECT * FROM syn51730943")
df = results.asDataFrame()

# Filter by resource type
df_cell_lines = df[df["resourceType"] == "Cell Line"]

# Get specific fields for computational tools
results = syn.tableQuery(
    "SELECT resourceId, resourceName, description, dateAdded "
    "FROM syn51730943 "
    "WHERE resourceType = 'Computational Tool'"
)
df = results.asDataFrame()
```

### Query via SQL with Synapse Table Query
```python
# Find tools added in the last 30 days
results = syn.tableQuery(
    "SELECT resourceId, resourceName, resourceType "
    "FROM syn51730943 "
    "WHERE dateAdded > UNIX_MILLIS() - 2592000000"
)

# Count tools by type
results = syn.tableQuery(
    "SELECT resourceType, COUNT(*) as count "
    "FROM syn51730943 "
    "GROUP BY resourceType"
)
df = results.asDataFrame()
print(df)
```

### Check Cell Line Annotations Against Registry
```python
# Get cell lines with NF portal datasets (syn52702673 stores individualID annotations)
annotations = syn.tableQuery(
    "SELECT individualID, dataType, assay "
    "FROM syn52702673"
)
ann_df = annotations.asDataFrame()

# Get cell lines in the registry
registry = syn.tableQuery(
    "SELECT resourceId, resourceName FROM syn51730943 "
    "WHERE resourceType = 'Cell Line'"
)
reg_df = registry.asDataFrame()

# Find annotated cell lines NOT in registry
unregistered = set(ann_df["individualID"]) - set(reg_df["resourceName"])
print(f"Cell lines with data but not in registry: {unregistered}")
```

### Update a Row (Upsert Pattern)
```python
import synapseclient
from synapseclient import Table

syn = synapseclient.login()

# Get the current table schema + data
table = syn.get("syn51730943")
results = syn.tableQuery(
    "SELECT * FROM syn51730943 WHERE resourceId = 'NF-R-0001'"
)
df = results.asDataFrame()

# Modify
df.loc[0, "description"] = "Updated description text."
df.loc[0, "dateModified"] = "2026-03-23"

# Store back (upsert)
syn.store(Table(table, df))
```

### Append New Rows from a DataFrame
```python
import pandas as pd
import synapseclient
from synapseclient import Table

syn = synapseclient.login()
table_id = "syn51730943"

new_rows = pd.DataFrame([{
    "resourceId": "NF-R-9999",
    "resourceName": "My New Tool",
    "resourceType": "Computational Tool",
    "description": "A tool for NF research.",
    "dateAdded": "2026-03-23",
    "dateModified": "2026-03-23"
}])

table = syn.get(table_id)
syn.store(Table(table, new_rows))
```

### Delete Rows
```python
# Delete rows by ROW_ID (Synapse internal row identifiers)
results = syn.tableQuery(
    "SELECT * FROM syn51730943 WHERE resourceId = 'NF-R-9999'"
)
syn.delete(results)
```

### Inspect Table Schema (Columns)
```python
cols = syn.getTableColumns("syn51730943")
for col in cols:
    print(f"{col.name:30s} {col.columnType}")
```

### Query Tool-Dataset Linkages
```python
# Find which datasets are linked to a specific tool
results = syn.tableQuery(
    "SELECT * FROM syn26486839 "
    "WHERE resourceId = 'NF-R-0001'"
)
df = results.asDataFrame()
```

### Upsert Tool-Dataset Linkages
```python
# Add a dataset link for a tool
import pandas as pd
from synapseclient import Table

new_link = pd.DataFrame([{
    "resourceId": "NF-R-0001",
    "datasetId": "syn99999999",
    "datasetName": "NF1 RNA-seq Dataset",
}])

table = syn.get("syn26486839")
syn.store(Table(table, new_link))
```

## Handling the Submissions Pipeline Locally

Accepted submissions are JSON files in `submissions/{type}/accepted/` in the nf-research-tools-schema repo. They are compiled to CSV and uploaded by the `upsert-tools` workflow. To replicate this locally:

```python
import json, glob, pandas as pd

# Compile accepted cell line submissions
files = glob.glob("submissions/cell-line/accepted/**/*.json", recursive=True)
records = []
for f in files:
    with open(f) as fh:
        records.append(json.load(fh))
df = pd.DataFrame(records)

# Then upsert to Synapse
import synapseclient
from synapseclient import Table
syn = synapseclient.login()
table = syn.get("syn26486823")  # Cell Lines table
syn.store(Table(table, df))
```

## Best Practices
- Always use `SYNAPSE_AUTH_TOKEN` env var (never hardcode tokens); the workflows use the `SYNAPSE_AUTH_TOKEN` secret
- Prefer SQL queries over downloading the full table when checking for existence or doing aggregations
- The `resourceId` field is the stable primary key — use it for cross-table joins, not `resourceName` (which can change)
- After upserting to `syn51730943`, trigger `update-observation-schema` to keep the observation form's enum values in sync
- Use `dry_run` mode (available in `upsert-tools.yml` via `workflow_dispatch`) to preview changes before committing

### Snapshot Tables Before and After Changes

Synapse tables support versioned snapshots. Always create a snapshot immediately before and after any bulk modification so changes are auditable and reversible.

```python
import synapseclient

syn = synapseclient.login()

# --- BEFORE making changes ---
before = syn.create_snapshot_version(
    "syn51730943",
    comment="Pre-update snapshot before adding Q1 2026 tool submissions"
)
print(f"Before snapshot version: {before}")

# ... make your changes (upsert, delete, etc.) ...

# --- AFTER making changes ---
after = syn.create_snapshot_version(
    "syn51730943",
    comment="Post-update snapshot after adding Q1 2026 tool submissions"
)
print(f"After snapshot version: {after}")
```

**Querying a specific snapshot version:**
```python
# Query a historical snapshot rather than the current table
results = syn.tableQuery(
    "SELECT * FROM syn51730943",
    snapshotVersion=before
)
df = results.asDataFrame()
```

**Listing all snapshots for a table:**
```python
snapshots = syn.get_snapshot_versions("syn51730943")
for s in snapshots:
    print(f"Version {s['snapshotVersion']}: {s.get('snapshotComment', '')} ({s['createdOn']})")
```

Apply this pattern to any table you modify: `syn51730943`, `syn26486808`, `syn26486811`, `syn26486823`, `syn26486832`, `syn26486839`.

## Reference
- NF Tools Portal: https://www.synapse.org/Synapse:syn26338068/tables/
- Schema source: https://github.com/nf-osi/nf-research-tools-schema
- Synapse SQL documentation: https://help.synapse.org/docs/Synapse-SQL-Reference.2046679903.html
- synapseclient docs: https://python-docs.synapse.org/en/stable/
