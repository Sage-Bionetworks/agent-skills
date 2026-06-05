# Synapse Data Curation

## Overview

Advanced patterns for curating data in Synapse (synapse.org) via the REST API. Covers the `annotations2` endpoint with etag/optimistic-locking, Dataset entity creation with dynamically-derived column schemas, JSON Schema binding for metadata validation, team permissions, and wiki management. Complements the `synapse-python-client` skill, which covers the high-level `synapseclient.models` SDK.

## Installation

```bash
pip install synapseclient pyyaml
```

## Authentication

```python
import synapseclient

# Via environment variable (recommended for automated workflows)
syn = synapseclient.Synapse()
syn.login(authToken=os.environ["SYNAPSE_AUTH_TOKEN"], silent=True)

# Via cached credentials (~/.synapseConfig)
syn = synapseclient.Synapse()
syn.login(silent=True)
```

## Core Concepts

- **annotations2**: The REST endpoint for reading and writing entity annotations. Uses etag-based optimistic locking — always re-fetch before PUT.
- **Dataset entity**: `org.sagebionetworks.repo.model.table.Dataset` — a typed table entity that must be a direct child of its project and whose `columnIds` should be derived dynamically from the annotation keys present on its files.
- **Schema binding**: JSON Schema is bound to a files folder (not the Dataset entity) to enable validation in Curator Grid.
- **412 Precondition Failed**: The server rejects a PUT when your etag is stale. Always retry after re-fetching.

## Common Operations

### Reading and Writing Annotations

```python
import json, time

def set_annotations(syn, entity_id: str, fields: dict, max_attempts: int = 3):
    """Set annotations on an entity, handling 412 stale-etag retries."""
    for attempt in range(max_attempts):
        try:
            ann = syn.restGET(f"/entity/{entity_id}/annotations2")
            for k, v in fields.items():
                if isinstance(v, list):
                    ann["annotations"][k] = {"type": "STRING", "value": v}
                elif isinstance(v, str):
                    ann["annotations"][k] = {"type": "STRING", "value": [v]}
                elif isinstance(v, int):
                    ann["annotations"][k] = {"type": "INTEGER", "value": [v]}
                elif isinstance(v, float):
                    ann["annotations"][k] = {"type": "DOUBLE", "value": [v]}
            syn.restPUT(f"/entity/{entity_id}/annotations2", json.dumps(ann))
            return
        except Exception as e:
            if "412" in str(e) and attempt < max_attempts - 1:
                time.sleep(1)
            else:
                raise

# Remove a single field
ann = syn.restGET(f"/entity/{entity_id}/annotations2")
ann["annotations"].pop("fieldName", None)
syn.restPUT(f"/entity/{entity_id}/annotations2", json.dumps(ann))
```

Individual string annotation values are limited to 500 characters — truncate before storing.

### Creating a Dataset Entity with Dynamic Columns

Dataset `columnIds` must be derived from the actual annotation keys present on the files — never hardcoded.

```python
import json

HIGH_CARDINALITY = {"specimenID", "individualID", "externalAccessionID",
                    "sampleId", "runAccession", "biosampleId"}
EXCLUDE_COLS     = {"resourceStatus", "filename"}   # never in Dataset columns
FACET_COLS       = {"assay", "species", "dataType", "fileFormat", "platform",
                    "tumorType", "diagnosis", "resourceType"}

def build_dataset(syn, project_id: str, files: list[dict],
                  dataset_name: str, dataset_annotations: dict) -> str:
    """Create a Dataset entity as a direct child of project_id."""
    # 1. Collect all annotation keys from the files
    all_keys = {}
    for f in files:
        fa = syn.restGET(f"/entity/{f['id']}/annotations2")
        for k, v in fa.get("annotations", {}).items():
            if k not in all_keys:
                all_keys[k] = v

    # 2. Create columns (LONG must map to INTEGER — Synapse has no LONG type)
    col_ids = []
    for col_name in sorted(all_keys):
        if col_name in EXCLUDE_COLS:
            continue
        val = all_keys[col_name]
        val_type = val.get("type", "STRING") if isinstance(val, dict) else "STRING"
        col_type = {"LONG": "INTEGER"}.get(val_type, val_type) \
                   if val_type in ("DOUBLE", "INTEGER", "LONG") else "STRING"
        col_body = {
            "name": col_name,
            "columnType": col_type,
            "maximumSize": 1000 if col_name in HIGH_CARDINALITY else 250,
        }
        if col_name in FACET_COLS and col_type == "STRING":
            col_body["facetType"] = "enumeration"
        col_ids.append(syn.restPOST("/column", json.dumps(col_body))["id"])

    # 3. Create Dataset
    body = {
        "name": dataset_name,
        "parentId": project_id,
        "concreteType": "org.sagebionetworks.repo.model.table.Dataset",
        "columnIds": col_ids,
        "items": [{"entityId": f["id"], "versionNumber": 1} for f in files],
    }
    dataset = syn.restPOST("/entity", json.dumps(body))
    dataset_id = dataset["id"]

    # 4. Set annotations
    set_annotations(syn, dataset_id, dataset_annotations)

    # 5. Mint a stable version
    syn.restPOST(f"/entity/{dataset_id}/version", json.dumps({}))
    return dataset_id
```

When *updating* an existing Dataset, always update `annotations2` before the entity PUT to avoid a cascading 412:

```python
for attempt in range(3):
    try:
        ds_ann = syn.restGET(f"/entity/{dataset_id}/annotations2")
        syn.restPUT(f"/entity/{dataset_id}/annotations2", json.dumps(ds_ann))  # refresh etag
        ds = syn.restGET(f"/entity/{dataset_id}")
        ds["columnIds"] = new_col_ids
        syn.restPUT(f"/entity/{dataset_id}", json.dumps(ds))
        break
    except Exception as e:
        if "412" in str(e) and attempt < 2:
            time.sleep(2)
        else:
            raise
```

### Binding a JSON Schema to a Files Folder

```python
import httpx

def bind_json_schema(syn, schema_uri: str, folder_id: str) -> dict:
    """Bind a JSON Schema to a folder for metadata validation."""
    body = {
        "concreteType": "org.sagebionetworks.repo.model.schema.BindSchemaToEntityRequest",
        "entityId": folder_id,
        "schema$id": schema_uri,
        "enableDerivedAnnotations": False,
    }
    return syn.restPUT(f"/entity/{folder_id}/schema/binding", json.dumps(body))

def fetch_schema_properties(syn, schema_uri: str) -> dict:
    """Return the schema's property definitions including enum constraints."""
    schema_id = schema_uri.split("/")[-1]
    result = syn.restGET(f"/schema/type/registered/{schema_id}")
    return result.get("validationSchema", {}).get("properties", {})

# Bind schema to files folder (NOT the Dataset entity or project)
bind_json_schema(syn, "org.foo.something-v1.0.0", files_folder_id)
props = fetch_schema_properties(syn, "org.foo.something-v1.0.0")
# props["assay"]["enum"] → list of valid assay values; [] means no valid values → skip field
```

**If a field's `enum` list is empty (`[]`), do not set it — no valid values exist in the current schema version.**

### Team Permissions

```python
syn.setPermissions(
    project_id,
    principalId=team_id,
    accessType=["READ", "DOWNLOAD", "CREATE", "UPDATE", "DELETE",
                "CHANGE_PERMISSIONS", "CHANGE_SETTINGS", "MODERATE",
                "UPDATE_SUBMISSION", "READ_PRIVATE_SUBMISSION"],
    warn_if_inherits=False,
)
```

### Wiki Management

```python
import json

# Create
wiki = synapseclient.Wiki(title=project_name, owner=project_id, markdown=content)
syn.store(wiki)

# Update via REST (avoids object overhead)
wiki = syn.restGET(f"/entity/{project_id}/wiki")
wiki["markdown"] = updated_content
syn.restPUT(f"/entity/{project_id}/wiki/{wiki['id']}", json.dumps(wiki))
```

## Best Practices

- **Never set `resourceStatus` on File entities** — it belongs only on Project and Dataset entities. Setting it on files creates a spurious column in portal Dataset views.
- **Never add a custom `filename` annotation to File entities** — the Synapse `name` property is the filename column in Dataset views; a duplicate annotation creates a second column.
- **`columnIds` are always derived dynamically** from actual file annotation keys. A hardcoded list goes stale as annotations evolve.
- **Portal tables are read-only** — never mutate the live studies, files, or datasets portal tables.
- **`syn.restPUT()` cannot move entities** — use the REST API directly for structural changes.
- Use `path=url, synapseStore=False` when creating File entities for externally-hosted files (do not use `externalURL=`).
- Official REST API docs: https://rest-docs.synapse.org/rest/
- Python client docs: https://python-docs.synapse.org/
