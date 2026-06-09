# Metadata Submission

## Overview

End-to-end workflow for submitting and validating file-level metadata in a Synapse folder. Given a Synapse folder ID, this skill: detects the bound JSON Schema (the data standard), builds a CSV manifest template from the schema if the user doesn't have one, applies annotations from the manifest to each file, then runs schema validation and surfaces any errors for correction.

## Installation

```bash
pip install synapseclient pandas
```

If `synapseclient` cannot be installed, fall back to direct REST calls:

```bash
pip install httpx pandas
```

## Authentication

Set a Synapse Personal Access Token (PAT) with read + write permissions on the target project:

```bash
export SYNAPSE_AUTH_TOKEN="your_synapse_pat"
```

Or via `~/.synapseConfig` when the SDK is available:

```ini
[authentication]
authtoken = your_synapse_pat
```

## Setup: SDK vs REST Fallback

Check whether `synapseclient` is importable and branch accordingly. All functions below accept either a `syn` (SDK) or `session` (httpx) object.

```python
import importlib.util, json, os, time

USE_SDK = importlib.util.find_spec("synapseclient") is not None

if USE_SDK:
    import synapseclient
    syn = synapseclient.Synapse()
    syn.login(authToken=os.environ["SYNAPSE_AUTH_TOKEN"], silent=True)
    client = syn
else:
    import httpx
    session = httpx.Client(
        base_url="https://repo-prod.prod.sagebase.org/repo/v1",
        headers={"Authorization": f"Bearer {os.environ['SYNAPSE_AUTH_TOKEN']}"},
        timeout=30,
    )
    client = session

def syn_get(path: str) -> dict:
    if USE_SDK:
        return client.restGET(path)
    return client.get(path).raise_for_status().json()

def syn_put(path: str, body: dict) -> dict:
    if USE_SDK:
        return client.restPUT(path, json.dumps(body))
    return client.put(path, json=body).raise_for_status().json()

def syn_post(path: str, body: dict) -> dict:
    if USE_SDK:
        return client.restPOST(path, json.dumps(body))
    return client.post(path, json=body).raise_for_status().json()
```

## Core Concepts

- **Bound JSON Schema**: A JSON Schema registered in Synapse and attached to a folder via `/entity/{folderId}/schema/binding`. It defines required and optional annotation fields for every file in that folder.
- **annotations2**: REST endpoint for reading and writing entity-level annotations. Uses etag-based optimistic locking — always re-fetch before PUT. A stale etag returns `412 Precondition Failed`.
- **CSV manifest**: A CSV file with one row per file. Must include an `entityId` column (Synapse IDs, e.g. `syn12345678`). Columns correspond to schema property names.
- **Validation statistics**: `GET /entity/{folderId}/schema/validation/statistics` returns aggregate counts of valid/invalid/unknown files scoped to the folder's bound schema.

## Workflow

### Step 1 — Identify the Target Folder

Ask the user for the Synapse folder ID containing the files to annotate.

```python
folder_id = "syn12345678"   # user-supplied synID of the files folder
```

### Step 2 — Check for a Bound JSON Schema

This is a hard stop: without a bound schema there is no data standard to submit against, and no basis for building a manifest.

```python
def get_bound_schema(folder_id: str) -> dict | None:
    """Return the schema binding, or None if no schema is attached."""
    try:
        return syn_get(f"/entity/{folder_id}/schema/binding")
    except Exception as e:
        if "404" in str(e) or "does not have a bound" in str(e).lower():
            return None
        raise

binding = get_bound_schema(folder_id)

if binding is None:
    print(
        "No JSON Schema is bound to this folder.\n"
        "There is no data standard applied. The contributor should contact their "
        "data manager to bind a schema before metadata can be submitted."
    )
    # Stop here — do not proceed without a bound schema.
else:
    schema_uri = binding["jsonSchemaVersionInfo"]["$id"]
    print(f"Bound schema: {schema_uri}")
```

If no schema is bound, **stop and direct the contributor to their data manager**. Do not invent a schema or continue.

### Step 3 — Fetch Schema Properties

```python
def get_schema_properties(schema_uri: str) -> tuple[dict, list[str]]:
    """Return (properties dict, required field names) from the registered schema."""
    schema_id = schema_uri.split("/")[-1]
    result = syn_get(f"/schema/type/registered/{schema_id}")
    vs = result.get("validationSchema", {})
    return vs.get("properties", {}), vs.get("required", [])

properties, required_fields = get_schema_properties(schema_uri)
print(f"{len(properties)} fields in schema, {len(required_fields)} required")
print(f"Required: {required_fields}")
```

Fields with `"enum": []` (an empty list) have no valid values in the current schema — skip them or any value set on them will fail validation.

### Step 4 — Confirm Files Exist in the Folder

```python
def count_folder_files(folder_id: str) -> int:
    """Return the number of FILE children in the folder."""
    resp = syn_post("/entity/children", {
        "parentId": folder_id,
        "includeTypes": ["file"],
        "includeTotalChildCount": True,
    })
    return resp.get("totalChildCount", 0)

n_files = count_folder_files(folder_id)
print(f"{n_files} file(s) in {folder_id}")
```

If `n_files == 0`, data hasn't been uploaded yet. Ask the user for the **local directory path**, then follow Steps 4a–4b before continuing.

#### 4a — Review Filenames for Sensitive Content

Sample filenames from the local directory, review them yourself for anything sensitive (patient names, clinical record numbers, PII-suggestive terms), then report what you observed. For example: _"I reviewed a sample of 20 filenames — they appear to follow a `sampleID_assay_fileformat` convention with no obvious identifiers."_ Ask the user to confirm that the files not in the sample are also safe to upload before proceeding.

```python
from pathlib import Path
import random

def sample_filenames(local_dir: str, n: int = 20) -> list[str]:
    """Return up to n filenames from the local directory (recursive)."""
    all_files = [p.name for p in Path(local_dir).rglob("*") if p.is_file()]
    return random.sample(all_files, min(n, len(all_files)))

names = sample_filenames("/path/to/local/data/")
```

#### 4b — Generate Upload Manifest and Sync

Once the user confirms the filenames are safe, generate the upload manifest. The `synapse manifest` command produces a TSV with `path` and `parent` columns — you can add metadata columns from the schema directly to this TSV before syncing, combining upload and annotation in a single step.

```
# 1. Generate the upload manifest
synapse manifest --parent-id syn12345678 /path/to/local/data/ --manifest-file manifest.tsv
```

Open `manifest.tsv` and add columns for the schema's required fields (from `required_fields`) and any optional fields the user can populate now. Valid enum values for each field are in `properties[field]["enum"]`. Then sync:

```
# 2. (Optional) validate without uploading
synapse sync --dryRun manifest.tsv

# 3. Upload files to Synapse
synapse sync manifest.tsv
```

After upload completes, re-run `count_folder_files(folder_id)` to confirm files are present, then continue to Step 5.

### Step 5A — Accept an Existing CSV Manifest

If the user already has a manifest CSV, load and validate it:

```python
import pandas as pd

def load_manifest(csv_path: str, required_fields: list[str]) -> pd.DataFrame:
    df = pd.read_csv(csv_path, dtype=str)
    if "entityId" not in df.columns:
        raise ValueError("Manifest must have an 'entityId' column with Synapse IDs.")
    missing_cols = [f for f in required_fields if f not in df.columns]
    if missing_cols:
        print(f"Manifest is missing required columns: {missing_cols}")
    return df

manifest = load_manifest("my_manifest.csv", required_fields)
```

### Step 5B — Build a CSV Manifest Template from the Schema

If the user has no manifest, scaffold one from the schema and the files currently in the folder:

```python
def list_folder_files(folder_id: str) -> list[dict]:
    """Page through /entity/children to collect all FILE entities."""
    files, token = [], None
    while True:
        body = {"parentId": folder_id, "includeTypes": ["file"]}
        if token:
            body["nextPageToken"] = token
        resp = syn_post("/entity/children", body)
        files.extend(resp.get("page", []))
        token = resp.get("nextPageToken")
        if not token:
            break
    return files

def build_manifest_template(folder_id: str, properties: dict,
                             required_fields: list[str]) -> pd.DataFrame:
    files = list_folder_files(folder_id)
    if not files:
        raise RuntimeError(f"No files found in {folder_id}.")

    # Ordered columns: entityId, name, required fields, then optional
    optional = [k for k in sorted(properties) if k not in required_fields]
    columns = ["entityId", "name"] + required_fields + optional

    rows = []
    for f in files:
        row = {"entityId": f["id"], "name": f["name"]}
        for col in required_fields + optional:
            prop = properties.get(col, {})
            enums = prop.get("enum", [])
            # Comment cell with allowed values where known
            row[col] = f"[one of: {', '.join(str(e) for e in enums)}]" if enums else ""
        rows.append(row)

    df = pd.DataFrame(rows, columns=columns)
    out = f"{folder_id}_manifest_template.csv"
    df.to_csv(out, index=False)
    print(f"Template written to {out} ({len(files)} files, {len(columns)-2} metadata columns)")
    print("Fill in the required columns, then re-run with load_manifest().")
    return df

template = build_manifest_template(folder_id, properties, required_fields)
```

After building the template, pause and ask the user to fill in the CSV. Once they return it, continue with `load_manifest()`.

### Step 6 — Apply Annotations from the Manifest

```python
def set_file_annotations(entity_id: str, fields: dict, max_attempts: int = 3):
    """Write annotations, retrying on 412 stale-etag errors."""
    for attempt in range(max_attempts):
        try:
            ann = syn_get(f"/entity/{entity_id}/annotations2")
            for k, v in fields.items():
                if isinstance(v, list):
                    ann["annotations"][k] = {"type": "STRING", "value": [str(i) for i in v]}
                elif isinstance(v, float) and not str(v).replace(".", "").isdigit():
                    continue   # NaN — skip
                elif isinstance(v, float):
                    ann["annotations"][k] = {"type": "DOUBLE", "value": [v]}
                elif isinstance(v, int):
                    ann["annotations"][k] = {"type": "INTEGER", "value": [v]}
                else:
                    ann["annotations"][k] = {"type": "STRING", "value": [str(v)]}
            syn_put(f"/entity/{entity_id}/annotations2", ann)
            return
        except Exception as e:
            if "412" in str(e) and attempt < max_attempts - 1:
                time.sleep(1)
            else:
                raise

def apply_manifest(manifest: pd.DataFrame, required_fields: list[str],
                   skip_cols: set[str] | None = None) -> list[dict]:
    """Write every non-empty manifest cell as a file annotation."""
    skip = (skip_cols or set()) | {"entityId", "name"}
    failures = []
    for _, row in manifest.iterrows():
        entity_id = row["entityId"]
        fields = {}
        for col in manifest.columns:
            if col in skip:
                continue
            val = row[col]
            # Skip empties and template hint strings
            if pd.isna(val) or str(val).strip() == "" or str(val).startswith("[one of:"):
                continue
            fields[col] = val

        missing = [f for f in required_fields if f not in fields]
        if missing:
            print(f"  {entity_id}: missing required fields {missing} — setting what's available")

        try:
            set_file_annotations(entity_id, fields)
            print(f"  {entity_id}: OK ({len(fields)} fields)")
        except Exception as e:
            print(f"  {entity_id}: FAILED — {e}")
            failures.append({"entityId": entity_id, "error": str(e)})

    return failures

failures = apply_manifest(manifest, required_fields)
```

### Step 7 — Validate and Report Statistics

```python
def get_validation_stats(folder_id: str) -> dict:
    return syn_get(f"/entity/{folder_id}/schema/validation/statistics")

def get_validation_errors(folder_id: str) -> list[dict]:
    """Return per-entity details for files that failed validation."""
    errors, token = [], None
    while True:
        path = f"/entity/{folder_id}/schema/validation/results"
        if token:
            path += f"?nextPageToken={token}"
        resp = syn_get(path)
        for item in resp.get("page", []):
            if item.get("validationState") == "INVALID":
                errors.append({
                    "entityId": item["objectId"],
                    "errors": [e.get("message", str(e)) for e in
                               item.get("validationErrorMessages", [])],
                })
        token = resp.get("nextPageToken")
        if not token:
            break
    return errors

stats = get_validation_stats(folder_id)
n_valid   = stats.get("numberOfValidResults", 0)
n_invalid = stats.get("numberOfInvalidResults", 0)
n_unknown = stats.get("numberOfUnknownResults", 0)
print(f"Validation — Valid: {n_valid}  Invalid: {n_invalid}  Unknown: {n_unknown}")

if n_invalid > 0:
    errors = get_validation_errors(folder_id)
    for e in errors:
        print(f"\n{e['entityId']}:")
        for msg in e["errors"]:
            print(f"  - {msg}")
```

### Step 8 — Triage and Correct Errors

Classify each error, correct in the manifest, and re-run Steps 6–7.

| Error message pattern | Cause | Action |
|---|---|---|
| `required key [X] not found` | Missing annotation | Add `X` to manifest rows and re-submit |
| `[X] is not one of [...]` | Value outside enum | Replace with a valid enum value from schema `properties[X]["enum"]` |
| `[X] is not of type 'number'` | String stored for numeric field | Re-submit as `int` or `float` |
| `[X] is not of type 'array'` | Single value where list expected | Wrap in a Python list before calling `set_file_annotations` |
| Valid enum list is empty | `enum: []` in schema | Do not set this field; flag to data manager to extend schema |

```python
def correction_manifest(errors: list[dict], manifest: pd.DataFrame) -> pd.DataFrame:
    """Subset manifest to only the files with validation failures."""
    ids = {e["entityId"] for e in errors}
    return manifest[manifest["entityId"].isin(ids)].copy()

fix_df = correction_manifest(errors, manifest)
# Edit fix_df values, then:
apply_manifest(fix_df, required_fields)
stats = get_validation_stats(folder_id)
print(f"After corrections — Valid: {stats.get('numberOfValidResults', 0)}  "
      f"Invalid: {stats.get('numberOfInvalidResults', 0)}")
```

## Gotchas

- **No bound schema = stop**: A `404` from `/entity/{folderId}/schema/binding` means no data standard is applied. Do not invent fields or proceed — direct the contributor to their data manager.
- **Empty enum `[]`**: Some properties carry `"enum": []` in the schema — no valid values exist. Setting any value on these fields causes validation failure. Skip them.
- **Annotation values capped at 500 characters**: Truncate string values before storing.
- **`/entity/children` returns direct children only**: If files are nested in sub-folders, recurse into each sub-folder — call `list_folder_files` on each child folder whose type is `"org.sagebionetworks.repo.model.Folder"`.
- **Schema is bound to the folder, not individual files**: Always resolve the immediate parent folder containing the files, not the project root or a Dataset entity.
- **Never set `resourceStatus` on File entities**: It belongs only on Project and Dataset entities; setting it on files creates a spurious portal column.

## Best Practices

- Always run Step 2 before building a template — the schema defines the exact required column set.
- Include `entityId` and `name` in the manifest for readability; skip them when calling `set_file_annotations`.
- Prefer idempotent runs: `apply_manifest` overwrites existing annotation values cleanly, so it is safe to re-run after corrections.
- Log each entity ID and outcome — useful for resuming if a run is interrupted.
- Official REST API docs: https://rest-docs.synapse.org/rest/
- Python client docs: https://python-docs.synapse.org/
