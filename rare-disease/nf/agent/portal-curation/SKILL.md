# NF Portal Data Curation Skill

## Overview
Data curation for the NF Portal involves two recurring workflows: reviewing a Synapse project's contents against its Data Sharing Plan (DSP), then generating and submitting portal-facing metadata for each dataset. Both workflows are defined as agent recipes in [agent-at-work](https://github.com/nf-osi/agent-at-work) and use the `nfty` MCP server for Synapse access.

**Prerequisites:** `nfty` MCP server configured and `SYNAPSE_AUTH_TOKEN` set (see `nfty-mcp-server` skill).

## Workflow Overview

```
1. PROJECT REVIEW (project_review recipe)
   DSP ──► walk project tree ──► classify folders ──► {studyId}_review.yaml

2. DATASET CURATION (dataset_curation recipe)
   review.yaml ──► fetch schema ──► generate metadata ──► validate ──► submit to Synapse
```

---

## Workflow 1: Project Review

**Recipe:** `recipes/curation/project_review.yaml` in agent-at-work
**Output:** `{studyId}_review.yaml` — classified dataset inventory with gap analysis

### What the agent does
1. Fetches the DSP for the study (`get_data_sharing_plan`)
2. Fetches data classification templates (`get_data_classes`)
3. Recursively walks the project folder tree (`walk_project_tree`)
4. For each folder: gets entity info and annotations (`get_entity_info`), counts contents (`count_folder_contents`)
5. Classifies each folder as a dataset type (e.g., `RNASeqTemplate`, `WGSTemplate`) based on annotations, file extensions, and folder names
6. Compares classified datasets against what the DSP says should be there
7. Produces a YAML summary with dataset classifications, confidence scores, and a gap report

### Review YAML output structure
```yaml
study_id: syn99999999
dsp_datasets:
  - dataLabel: RNA_sequencing
    assay: RNA-seq
    matched: true
    folder_id: syn12345678
    template: RNASeqTemplate
    confidence: 0.95

gaps:
  - dataLabel: proteomics
    status: missing
    note: "No folder found matching this dataset"

summary:
  total_dsp_datasets: 3
  matched: 2
  unmatched: 1
  completeness_score: 0.67
```

### Running with Goose CLI
```bash
cd /path/to/agent-at-work/recipes/curation
goose run project_review.yaml --params studyId=syn99999999
# Output: syn99999999_review.yaml
```

### Running manually with nfty tools (Claude Code)
When using Claude Code with nfty connected, you can drive this workflow interactively:
1. Call `get_data_sharing_plan` with the study ID to understand what data is expected
2. Call `walk_project_tree` to map the project structure
3. Call `get_entity_info` on each folder to check existing annotations and classify
4. Call `get_data_classes` to compare folder contents against available templates
5. Call `count_folder_contents` to confirm which folders have data

---

## Workflow 2: Dataset Metadata Curation

**Recipe:** `recipes/curation/dataset_curation.yaml` in agent-at-work
**Output:** `{studyId}_metadata.json` files per dataset + summary JSON

### What the agent does
1. Fetches and saves the `PortalDataset` JSON schema (`fetch_schema`)
2. Retrieves the DSP to understand expected datasets (`get_data_sharing_plan`)
3. For each dataset folder:
   - Converts folder to Dataset entity if needed (`create_dataset`)
   - Queries file-level metadata (`synapse_query`) to infer dataset-level values
   - Gets existing entity annotations (`get_entity_info`)
   - Generates a complete `PortalDataset` metadata object
   - Validates against the schema (`validate_metadata`)
   - Submits to the Dataset entity (`submit_metadata`)
4. Produces a summary JSON with completeness and confidence scores per dataset

### Running with Goose CLI
```bash
cd /path/to/agent-at-work/recipes/curation

# Curate all datasets in a study
goose run dataset_curation.yaml --params studyId=syn99999999

# Curate specific datasets only
goose run dataset_curation.yaml --params studyId=syn99999999,datasetIds=syn11111111,syn22222222
```

### Running manually with nfty tools (Claude Code)
For a single dataset folder:
1. `fetch_schema` → save the `PortalDataset` schema locally
2. `get_data_sharing_plan` → understand the study context
3. `create_dataset` on the folder (if not already a Dataset entity)
4. `synapse_query` to inspect file-level annotations:
   ```sql
   SELECT DISTINCT assay, dataType, species, platform FROM <dataset_id>
   ```
5. `get_entity_info` on the dataset to see existing annotations
6. Compose the metadata JSON from steps 4–5
7. `validate_metadata` — check completeness score and fix any errors
8. `submit_metadata` — write annotations to the Dataset entity

### PortalDataset Key Fields

| Field | Source | Notes |
|---|---|---|
| `name` | DSP `dataLabel` or folder name | Display name on portal |
| `assay` | File-level annotations | Query `DISTINCT assay FROM <dataset>` |
| `dataType` | File-level annotations | Query `DISTINCT dataType FROM <dataset>` |
| `species` | File-level annotations | |
| `tumorType` | File-level annotations | ONCOTREE values |
| `diagnosis` | File-level annotations | |
| `fundingAgency` | DSP `fundingAgency` | |
| `studyId` | Synapse project ID | |
| `accessType` | DSP governance | `"Open"` or `"Controlled"` |

### Validation and Completeness
The `validate_metadata` tool returns:
```json
{
  "valid": true,
  "errors": [],
  "warnings": ["Missing optional field: tissue"],
  "completeness_score": 0.87
}
```
A completeness score ≥ 0.80 is generally acceptable for portal submission. Scores below 0.70 usually indicate missing required fields.

---

## Common Patterns and Tips

### Inferring Dataset Metadata from Files
When file-level annotations exist, query them to derive dataset-level values:
```sql
-- Discover what's in a dataset
SELECT DISTINCT dataType, assay, species, diagnosis, tumorType, platform
FROM <dataset_id>
WHERE dataType IS NOT NULL
```

### Handling Folders Without Annotations
If file-level annotations are missing (common for newly uploaded data), check the DSP `dataDeposit` array for declared intent, then use the task generation workflow to create annotation curation tasks before attempting dataset curation.

### Checking if a Folder is Already a Dataset
```python
# via synapseclient
entity = syn.get("syn12345678")
print(type(entity))  # synapseclient.models.Dataset vs Folder
```
Or via `get_entity_info` — the returned `entity_type` field will say `"Dataset"` or `"Folder"`.

### Batch Curation Across Multiple Studies
The `generate-curation-tasks.yml` GitHub Actions workflow in agent-at-work runs the task generator across all unreleased projects. For batch dataset curation, run the `dataset_curation` recipe per study via the workflow matrix.

---

## Key Synapse Table References

| Table | Synapse ID | Used For |
|---|---|---|
| Portal file view (annotations) | syn52702673 | Querying file-level metadata to infer dataset values |
| Portal - Datasets | (via submit_metadata) | Dataset entity annotations |
| Projects catalogue | syn52694652 | Finding unreleased studies to curate |

## Reference
- agent-at-work recipes: https://github.com/nf-osi/agent-at-work/tree/main/recipes/curation
- mcp-server / nfty tools: https://github.com/nf-osi/mcp-server
- PortalDataset schema: `registered-json-schemas/PortalDataset.json` in nf-metadata-dictionary
- DSP site: https://dsp.nf.synapse.org
