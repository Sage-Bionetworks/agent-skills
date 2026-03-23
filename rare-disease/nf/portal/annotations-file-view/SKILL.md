# NF Annotations & File View Skill

## Overview
The NF Portal file view **syn52702673** is a Synapse EntityView that aggregates file-level metadata annotations across all NF research projects. It defines the searchable facets on the NF Data Portal and is the primary surface for querying what data exists and how it is annotated. This skill covers querying, maintaining, and configuring this table and the underlying file-level annotations.

- **Annotations file view:** https://www.synapse.org/Synapse:syn52702673/tables/
- **Schema source:** [nf-metadata-dictionary](https://github.com/nf-osi/nf-metadata-dictionary) (`modules/Template/`)
- **Synapse ID:** `syn52702673`

## What syn52702673 Contains

Each row represents a file in the NF Data Portal. Key columns (search facets) include:

| Column | Description |
|---|---|
| `individualID` | Unique identifier for the donor/individual |
| `specimenID` | Identifier for the biospecimen |
| `dataType` | High-level data category (e.g., `genomicVariants`, `geneExpression`) |
| `assay` | Assay type (e.g., `RNA-seq`, `WGS`, `scRNA-seq`) |
| `species` | Organism (e.g., `Homo sapiens`, `Mus musculus`) |
| `diagnosis` | Disease diagnosis (e.g., `Neurofibromatosis 1`) |
| `tumorType` | ONCOTREE tumor type |
| `tissue` | Source tissue |
| `fileFormat` | File format (e.g., `fastq`, `bam`, `csv`) |
| `platform` | Sequencing/imaging platform |
| `resourceType` | Resource category |
| `studyId` | Synapse project ID of the owning study |
| `fundingAgency` | Funder (NTAP, CTF, GFF, etc.) |
| `contentType` | Content classification |
| `ROW_ID`, `ROW_VERSION` | Synapse internal identifiers |

The columns are derived from the `PartialTemplate` and other shared templates in `registered-json-schemas/`.

## Querying the File View

```python
import synapseclient
import pandas as pd

syn = synapseclient.login()

# All files with a specific assay type
results = syn.tableQuery(
    "SELECT individualID, specimenID, assay, fileFormat, studyId "
    "FROM syn52702673 "
    "WHERE assay = 'RNA-seq'"
)
df = results.asDataFrame()

# Files for a specific study
results = syn.tableQuery(
    "SELECT * FROM syn52702673 WHERE studyId = 'syn99999999'"
)

# Count files by assay type
results = syn.tableQuery(
    "SELECT assay, COUNT(*) as fileCount "
    "FROM syn52702673 "
    "GROUP BY assay "
    "ORDER BY fileCount DESC"
)
df = results.asDataFrame()
print(df)

# Find all distinct individualIDs with RNA-seq data (used by monthly cell line check)
results = syn.tableQuery(
    "SELECT DISTINCT individualID "
    "FROM syn52702673 "
    "WHERE assay = 'RNA-seq' AND species = 'Homo sapiens'"
)
annotated_individuals = set(results.asDataFrame()["individualID"])
```

## Checking Annotation Completeness

```python
import synapseclient
import pandas as pd

syn = synapseclient.login()

# Find files missing key annotations
results = syn.tableQuery(
    "SELECT id, name, studyId, dataType, assay, specimenID, individualID "
    "FROM syn52702673 "
    "WHERE studyId = 'syn99999999'"
)
df = results.asDataFrame()

required_cols = ['dataType', 'assay', 'specimenID', 'individualID']
for col in required_cols:
    missing = df[df[col].isna() | (df[col] == '')]
    if not missing.empty:
        print(f"Missing {col}: {len(missing)} files")
        print(missing[['id', 'name']].head())
```

## Updating File Annotations

### Update Annotations on Individual Files
```python
import synapseclient

syn = synapseclient.login()

# Get and update a single file's annotations
entity = syn.get("syn12345678", downloadFile=False)
entity.annotations["assay"] = ["RNA-seq"]
entity.annotations["dataType"] = ["geneExpression"]
entity.annotations["specimenID"] = ["SP001"]
entity.annotations["individualID"] = ["ID001"]
syn.store(entity)
```

### Bulk Update via DataFrame
```python
import synapseclient
import pandas as pd
from synapseclient import Table

syn = synapseclient.login()

# Query and update annotations in bulk via the file view
table_id = "syn52702673"
results = syn.tableQuery(
    "SELECT ROW_ID, ROW_VERSION, id, assay "
    "FROM syn52702673 "
    "WHERE studyId = 'syn99999999' AND assay IS NULL"
)
df = results.asDataFrame()

# Set assay for all files in this query
df['assay'] = 'RNA-seq'

# Store updates back through the file view
table = syn.get(table_id)
syn.store(Table(table, df[['ROW_ID', 'ROW_VERSION', 'assay']]))
```

## Configuring File View Columns and Search Facets

The columns and facets of the file view are configured from the schema. When the metadata dictionary releases a new version, the file view may need its columns updated.

### Using the json_schema_entity_view.py Utility
From the `nf-metadata-dictionary` repo:
```bash
SYNAPSE_AUTH_TOKEN="$TOKEN" python utils/json_schema_entity_view.py \
  --view syn52702673 \
  --schema org.synapse.nf-partialtemplate
```
This updates the EntityView column definitions to match the current registered schema.

### Manually Add or Update a Column via synapseclient
```python
import synapseclient
from synapseclient import EntityViewSchema, Column

syn = synapseclient.login()

view = syn.get("syn52702673")

# Add a new column
new_col = Column(name="newAnnotationField", columnType="STRING", maximumSize=80)
view.addColumn(new_col)
syn.store(view)
```

### Set Search Facets (Columns Exposed as Filters on Portal)
```python
import synapseclient
from synapseclient import EntityViewSchema

syn = synapseclient.login()
view = syn.get("syn52702673")

# facetType options: "enumeration" (dropdown filter) or "range" (slider)
for col in view.columns_to_get:
    if col.name in ["assay", "dataType", "species", "diagnosis", "tumorType", "tissue", "fundingAgency"]:
        col.facetType = "enumeration"
    elif col.name in ["fileSize"]:
        col.facetType = "range"

syn.store(view)
```

## Scope of the File View

The EntityView at syn52702673 is scoped to include files from specific Synapse projects. To add a newly provisioned project to the view's scope:

```python
import synapseclient
from synapseclient import EntityViewSchema

syn = synapseclient.login()
view = syn.get("syn52702673")

# Add the new project's Synapse ID to the scope
view.set_entity_types(["file"])
current_scope = view.scopeIds
current_scope.append("syn99999999")   # new project ID
view.scopeIds = current_scope
syn.store(view)
```

## Binding JSON Schemas to Files and Folders

To enforce annotation validation on files uploaded to a Synapse project, bind the appropriate JSON schema to the folder:

```python
import synapseclient
from synapseclient import Folder

syn = synapseclient.login()

# Bind a schema to a folder (enforces validation on all files uploaded to it)
syn.set_entity_schema_binding(
    entity="syn12345678",   # folder syn ID
    schema_id="org.synapse.nf-rnaseqtemplate"
)
```

To bind via the Synapse UI: Folder → Settings → JSON Schema → select schema.

## Creating Curation Tasks for a Study

When a study folder needs metadata annotation, create a curation task from the `nf-metadata-dictionary` repo:

### File-Based Curation Task (most common)
```bash
cd /path/to/nf-metadata-dictionary
SYNAPSE_AUTH_TOKEN="$TOKEN" python utils/create_curation_task.py \
  --folder syn12345678 \
  --template RNASeqTemplate
```
Creates an EntityView filtered to the folder + a CurationTask that data managers use to fill in missing annotations.

### Record-Based Curation Task
```bash
SYNAPSE_AUTH_TOKEN="$TOKEN" python utils/create_recordset_task.py \
  --parent syn12345678 \
  --schema org.synapse.nf-portalstudytemplate
```

## How syn52702673 Feeds Other Workflows

### Monthly Cell Line Check (`nf-research-tools-schema`)
The `monthly-submission-check.yml` workflow in nf-research-tools-schema queries syn52702673 to find `individualID` values associated with files that haven't been registered as Cell Lines in the NF Research Tools registry (syn51730943). This is how new cell line tool registrations are identified automatically.

### NF Data Portal Search
The portal uses syn52702673 as its file search index. The columns configured as `facetType: enumeration` appear as filter options in the portal UI.

### Publication Mining
The publication mining workflow in nf-research-tools-schema also queries syn52702673 to identify tools from the NF portal that are not yet linked to publications.

## Common Annotation Issues and Fixes

### Smart Characters in Annotation Values
The metadata dictionary schema requires ASCII-safe annotation values. If smart quotes, em-dashes, or other Unicode characters appear in annotations, they need to be removed:
```python
import re
import synapseclient

def sanitize(value):
    # Remove common problematic Unicode characters
    value = re.sub(r'[\u2018\u2019]', "'", value)   # smart single quotes
    value = re.sub(r'[\u201c\u201d]', '"', value)   # smart double quotes
    value = re.sub(r'\u2013|\u2014', '-', value)    # en/em dash
    value = re.sub(r'[\u00ae\u00a9\u2122]', '', value)  # ®©™
    return value.strip()
```

### Synapse Platform Limits for File View Columns
- String column max: 80 characters per value
- List column max: 40 items × 80 characters
- Row size: 64KB hard limit (sum of all column values per row)

If a row exceeds 64KB (most likely for studies with very long annotation values), the file view will fail to include that row. Run `utils/check_schema_limits.py` from nf-metadata-dictionary to check.

## Reference
- File view: https://www.synapse.org/Synapse:syn52702673/tables/
- nf-metadata-dictionary repo: https://github.com/nf-osi/nf-metadata-dictionary
- Synapse Entity Views docs: https://help.synapse.org/docs/Views.2011070739.html
- Synapse JSON Schema binding: https://help.synapse.org/docs/JSON-Schemas.2644955932.html
- Synapse SQL reference: https://help.synapse.org/docs/Synapse-SQL-Reference.2046679903.html
