# NF Research Tools Schema Skill

## Overview
The NF Research Tools Central schema defines the data model for cataloging 9 types of NF (neurofibromatosis) research resources. The schema lives in [nf-research-tools-schema](https://github.com/nf-osi/nf-research-tools-schema) and drives both the Synapse database structure and the web submission forms.

## Schema Layers

```
nf_research_tools.rdb.model.csv   ← SOURCE OF TRUTH (edit this)
          │
          ▼ (schematic schema convert)
nf-research-tools.jsonld           ← auto-generated, do not edit directly
          │
NF-Tools-Schemas/{type}/           ← JSON Schema + UI Schema per resource type
  submit{Type}.json                 (submission form validation)
  submit{Type}UiSchema.json         (form rendering hints)
```

**Rule:** Never edit `.jsonld` directly. Modify the CSV, then regenerate the `.jsonld` via the `schematic-schema-convert` workflow.

## CSV Schema Format (`nf_research_tools.rdb.model.csv`)

Each row defines one attribute (field). Columns:

| Column | Purpose |
|---|---|
| `Attribute` | Field name (camelCase) |
| `Description` | Human-readable description |
| `Valid Values` | Comma-separated enum values (if applicable) |
| `DependsOn` | Other attributes this field depends on |
| `Required` | Whether the field is required |
| `Source` | Ontology or vocabulary source |
| `Parent` | Parent class in the schema hierarchy |
| `Properties` | Additional schema properties |
| `DependsOn Component` | Component dependency |
| `Validation Rules` | Validation logic |

## Resource Types

| Type | Description |
|---|---|
| `Animal Model` | Mouse, rat, or other animal models of NF |
| `Cell Line` | Established cell lines derived from NF patients or models |
| `Antibody` | NF-relevant antibodies |
| `Genetic Reagent` | CRISPR constructs, plasmids, viral vectors, etc. |
| `Biobank` | Biobanks with NF biospecimens |
| `Computational Tool` | Software, pipelines, packages |
| `Advanced Cellular Model` | Organoids, spheroids, 3D models |
| `Patient-Derived Model` | PDX, primary cultures from NF patients |
| `Clinical Assessment Tool` | Validated outcome measures (SF-36, PROMIS, PedsQL) |

## Common Schema Operations

### Regenerate the JSON-LD from the CSV
Push the updated CSV to a non-`main` branch — the `schematic-schema-convert` workflow runs automatically. Or run locally:
```bash
pip install schematicpy==24.7.2
schematic schema convert nf_research_tools.rdb.model.csv -o nf-research-tools.jsonld
```

### Add a New Field to an Existing Resource Type
1. Open `nf_research_tools.rdb.model.csv`
2. Add a new row:
   ```
   Attribute: myNewField
   Description: What this field captures
   Valid Values: (leave blank for free text, or list options)
   DependsOn: (parent attribute if conditional)
   Required: FALSE
   Source: (ontology URL if applicable)
   Parent: cellLineDetails   ← the component it belongs to
   ```
3. Commit the CSV to a branch — `.jsonld` auto-regenerates
4. Update `NF-Tools-Schemas/{type}/submit{Type}.json` to add the field to the form
5. Update `NF-Tools-Schemas/{type}/submit{Type}UiSchema.json` for rendering hints

### Add a New Resource Type
1. Add the type to `nf_research_tools.rdb.model.csv`:
   - Add a row for the component itself with `Parent: Component`
   - Add all fields with `Parent: newTypeDetails`
2. Create `NF-Tools-Schemas/new-type/submitNewType.json`
3. Create `NF-Tools-Schemas/new-type/submitNewTypeUiSchema.json`
4. Create a new Synapse table for the type
5. Update `upsert-tools.yml` to include the new table ID
6. Update `publication-mining.yml` if it should be mined from publications

### Add a New Enum Value to an Existing Field
1. Find the attribute row in `nf_research_tools.rdb.model.csv`
2. Add the new value to the `Valid Values` column (comma-separated)
3. Commit the CSV to trigger schema regeneration
4. If the field appears in a JSON Schema form, add the value to the `enum` array in the relevant `submit{Type}.json`

## JSON Form Schema Structure

Each resource type has two files under `NF-Tools-Schemas/{type}/`:

### `submit{Type}.json` — Validation Schema
Standard JSON Schema (draft-07) used for form validation:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema",
  "title": "Submit Computational Tool",
  "type": "object",
  "required": ["basicInfo"],
  "properties": {
    "basicInfo": {
      "type": "object",
      "title": "Basic Information",
      "required": ["softwareName", "description", "softwareType"],
      "properties": {
        "softwareName": { "type": "string", "title": "Software Name" },
        "softwareType": {
          "type": "string",
          "enum": ["Analysis Software", "Pipeline", "Package/Library", ...]
        }
      }
    }
  }
}
```

### `submit{Type}UiSchema.json` — UI Rendering Hints
Controls how the form renders (widget type, ordering, help text):
```json
{
  "basicInfo": {
    "ui:order": ["softwareName", "description", "softwareType", "*"],
    "description": {
      "ui:widget": "textarea",
      "ui:options": { "rows": 4 },
      "ui:help": "Describe the tool in 20-50 words."
    }
  }
}
```

## Submission JSON Format

Accepted submissions are stored as JSON files in `submissions/{type}/accepted/`. The structure mirrors the form schema sections:

```json
{
  "basicInfo": {
    "softwareName": "NF-Tools Analyzer",
    "description": "A pipeline for analyzing NF tumor genomics data.",
    "softwareType": "Pipeline",
    "version": "1.2.0",
    "programmingLanguage": ["Python"]
  },
  "itemAcquisition": {
    "acquisitionMethod": "GitHub/GitLab",
    "repositoryUrl": "https://github.com/example/nf-tools-analyzer"
  }
}
```

To accept a pending submission (move it from pending to accepted):
```bash
git mv submissions/computational-tool/pending/tool_123.json \
        submissions/computational-tool/accepted/tool_123.json
git commit -m "Accept computational tool submission: NF-Tools Analyzer"
git push origin main
# This triggers upsert-tools.yml automatically
```

## Observation Schema (`NF-Tools-Schemas/observations/`)

The observation form captures literature evidence linking a tool to an NF study. Key fields:
- `resourceType` — enum auto-synced from the master resource table
- `resourceName` — enum auto-synced from the master resource table
- `observationType` — type of evidence (e.g., `in vivo`, `in vitro`, `clinical`)
- `publicationDOI` — DOI of the source publication

The `update-observation-schema.yml` workflow automatically keeps `resourceType` and `resourceName` enums in sync with the live Synapse data after each upsert.

To manually update observation schema enums:
```bash
pip install synapseclient
export SYNAPSE_AUTH_TOKEN=your_token
python scripts/update_observation_schema.py
```

## Schema Visualization

The schema is visualized at the GitHub Pages site deployed from `schema-viz/`. It auto-deploys on push to `main` via `publish-schema-viz.yml`.

To rebuild locally:
```bash
# Requires schematic or a compatible JSON-LD viewer
# See schema-viz/ directory for the visualization tooling used
```

## Validation

To validate submission CSVs against the schema:
```bash
python build_db/clean_submission_csvs.py --validate ACCEPTED_cell_line.csv
```

To rebuild the entire database from manifests (uses schematic-db):
```bash
pip install schematic-db
export NF_SERVICE_TOKEN=your_token
python build_db/build_db.py
```

The database config in `build_db/build_db.py` defines all tables, primary keys, and foreign key relationships. Use this as the authoritative reference for the relational structure.

## Key File Paths in the Schema Repo

```
nf_research_tools.rdb.model.csv     ← edit to change the schema
nf-research-tools.jsonld             ← auto-generated, do not edit
NF-Tools-Schemas/
  {type}/submit{Type}.json           ← form validation schema
  {type}/submit{Type}UiSchema.json   ← form UI hints
  observations/SubmitObservationSchema.json   ← auto-updated by workflow
submissions/
  {type}/pending/*.json              ← pending review
  {type}/accepted/*.json             ← triggers database upsert on push to main
build_db/
  build_db.py                        ← full database rebuild script
  create_new_tool_tables.py          ← create new Synapse tables for a type
scripts/
  review_tool_annotations.py         ← monthly cell line annotation check
  update_observation_schema.py       ← sync observation form enums
  upsert_tool_datasets.py            ← upload tool-dataset linkages
  fix_mutation_junction_keys.py      ← one-off mutation key fix utility
```

## Reference
- Schema repo: https://github.com/nf-osi/nf-research-tools-schema
- NF Tools Portal: https://www.synapse.org/Synapse:syn26338068/tables/
- Schematic docs: https://schematic.readthedocs.io/
- JSON Schema docs: https://json-schema.org/
