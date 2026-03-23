# NF Metadata Dictionary Skill

## Overview
The [nf-metadata-dictionary](https://github.com/nf-osi/nf-metadata-dictionary) defines the controlled vocabulary and data templates used across the NF Data Portal. It is the authoritative source of metadata terms, enumerated values, and submission templates for all NF research data.

## Architecture

```
modules/*.yaml           ← SOURCE OF TRUTH (edit these)
      │
      ▼ (retold + LinkML + schematic — runs in CI)
NF.jsonld                ← Schematic-compatible JSON-LD (not committed; generated in PR)
dist/NF.yaml             ← Merged LinkML YAML (not committed; generated in PR)
dist/NF.ttl              ← RDF Turtle (not committed; generated in PR)
registered-json-schemas/*.json  ← Synapse JSON schemas (not committed; registered on release)
```

**Rule:** Never edit `NF.jsonld` directly. All changes go through the YAML modules.

## Module Structure (`modules/`)

| Directory | Contents |
|---|---|
| `modules/props.yaml` | All slot/property definitions (54KB — the field definitions) |
| `modules/Assay/` | Assay types, platforms, parameters |
| `modules/Data/` | Data types, file formats, resources |
| `modules/Sample/` | Biological specimens: animal models, cell lines, species, diagnosis, tumor, demographics, body parts |
| `modules/Experiment/` | Antibodies, genetic reagents, methods, factors, units |
| `modules/DCC/` | Portal configuration enums |
| `modules/Other/` | Organizations, publications |
| `modules/Template/` | Data submission templates (the manifest schemas) |

### Key Template Files
| Template | Purpose |
|---|---|
| `Template/Biosample.yaml` | Individual/specimen metadata |
| `Template/Data_Genomics.yaml` | RNA-seq, WGS, WES, scRNA-seq, etc. |
| `Template/Data_Imaging.yaml` | Imaging assays |
| `Template/Data_Clinical.yaml` | Clinical data |
| `Template/Data_Proteomics.yaml` | Proteomics |
| `Template/Data_CellAssays.yaml` | Cell-based assays |
| `Template/PortalDataset.yaml` | Portal dataset metadata |
| `Template/PortalStudy.yaml` | Study metadata |
| `Template/PortalPublication.yaml` | Publication metadata |
| `Template/Protocol.yaml` | Protocol metadata |
| `Template/Tool.yaml` | Tool/software metadata |

## LinkML YAML Structure

### Defining a Template (Class)
```yaml
RNASeqTemplate:
  is_a: SequencingTemplate        # inherits slots from parent
  description: "Template for RNA sequencing data"
  slots:
    - filename
    - specimenID
    - assay
    - platform
    - libraryPrep
    - readLength
```

### Defining a Slot (Property)
In `props.yaml`:
```yaml
slots:
  libraryPrep:
    description: "Method used to prepare the sequencing library"
    range: LibraryPrepEnum        # references an enum
    required: false
    multivalued: false
```

### Defining an Enum (Controlled Vocabulary)
```yaml
enums:
  LibraryPrepEnum:
    permissible_values:
      polyA selection:
        description: "Selection for poly-A tail"
        meaning: NCIT:C123456     # ontology mapping
      rRNA depletion:
        description: "Ribosomal RNA depletion"
```

### Contextual Enum Subsets (Key Pattern)
Use `slot_usage` to restrict enums within a specific template context — this keeps dropdowns manageable for users:
```yaml
SequencingTemplate:
  slot_usage:
    assay:
      range: SequencingAssayEnum      # restricts to sequencing assays only
    platform:
      range: SequencingPlatformEnum
    fileFormat:
      range: SequencingFileFormatEnum
```

For templates spanning multiple domains, use `any_of`:
```yaml
EpigenomicsAssayTemplate:
  slot_usage:
    platform:
      any_of:
        - range: SequencingPlatformEnum
        - range: ArrayPlatformEnum
```

### Conditional Validation Rules
Two approaches — prefer LinkML rules for new additions:

**Legacy (Schematic-compatible):**
```yaml
slots:
  ageUnit:
    annotations:
      requiresDependency: age    # ageUnit required when age is provided
```

**LinkML rules (preferred):**
```yaml
RNASeqTemplate:
  rules:
    - preconditions:
        slot_conditions:
          age:
            value_presence: PRESENT
      postconditions:
        slot_conditions:
          ageUnit:
            required: true
```

**Documented conditional dependencies:**
- `age` → `ageUnit`
- `aliquotID` → `specimenID`
- `compoundDose` → `compoundDoseUnit`
- `dataType` → `dataSubtype`
- And 11 more (see `docs/DEVELOPMENT.md`)

## Common Operations

### Add a New Term to an Enum
1. Find the enum in the relevant `modules/*.yaml` file
2. Add the new permissible value:
   ```yaml
   MyNewAssay:
     description: "Description of the assay"
     meaning: NCIT:CXXXXXX    # ontology URI if available
   ```
3. Commit to a branch — CI validates automatically on PR

### Add a New Slot (Field)
1. Add the slot definition to `modules/props.yaml`:
   ```yaml
   slots:
     myNewField:
       description: "What this captures"
       range: string           # or an enum name
       required: false
   ```
2. Add the slot name to the relevant template in `modules/Template/*.yaml`
3. If it needs contextual restriction, add `slot_usage` to the template

### Add a New Template
1. Create a new YAML file in `modules/Template/`:
   ```yaml
   MyNewTemplate:
     is_a: Template
     description: "Template for X data"
     slots:
       - filename
       - specimenID
       - myNewField
   ```
2. CI generates the corresponding JSON schema at `registered-json-schemas/MyNewTemplate.json`

### Add a New Enum Value with Ontology Mapping
1. Add the value to the YAML module with a `meaning` mapping
2. Optionally run the synonyms workflow or add synonyms to `term_synonyms.csv`:
   ```
   Term, URLs, Synonyms
   My New Assay, https://purl.obolibrary.org/obo/NCIT_CXXXXXX, "alternative name 1, alt name 2"
   ```

### Guidelines for Specific Term Types
- **tumorType**: Use ONCOTREE names
- **drugs**: Search EMBL-EBI OLS, NCIT, or MeSH
- **species**: Use NCBI Taxonomy — format: `"Species name with taxonomy ID: XXX and Genbank common name: name"`
- **file formats**: Use EDAM, NCIT, Wikipedia, or vendor documentation
- All new terms should reference a standard ontology (EDAM, EFO, OBI, NCIT preferred)

## Synapse Platform Limits (Hard Constraints)

| Constraint | Limit | Notes |
|---|---|---|
| Enum values (for annotations) | 100 max | Larger enums still work for form validation |
| String length (file view column) | 80 chars | Per enum value |
| List items | 40 max × 80 chars | |
| Row size (file view) | 64KB hard limit | PortalDataset approaches this |
| Name column | 256 chars | |

Run the check before releasing:
```bash
python utils/check_schema_limits.py
```

Known large schemas that exceed the 100-value annotation limit (but are valid for form validation): `CellLineModel` (638 values), `Institution` (335 values).

## Build Commands

```bash
# Build all artifacts (runs full retold + LinkML + schematic pipeline)
make all

# Validate all JSON schemas against Synapse limits
python utils/check_schema_limits.py

# Generate JSON schemas (optionally with a version for Synapse registration)
python utils/gen-json-schema-class.py
SYNAPSE_AUTH_TOKEN="$TOKEN" python utils/gen-json-schema-class.py --version 1.2.3

# Generate a single class schema (skip validation for speed)
python utils/gen-json-schema-class.py --class DataLandscape --skip-validation
```

## Workflows

### `main-ci.yml` — PR Validation
**Trigger:** Any PR

Runs four jobs:
1. **build** — generates all artifacts (NF.jsonld, NF.yaml, NF.ttl, JSON schemas), validates against Synapse API
2. **analyze** — RDF-based diff of data model changes vs. main
3. **test** — schematic validation tests (can be skipped with label)
4. **check-schema-limits** — enforces the platform constraints above

### `release-new-version.yaml` — Schema Registration
**Trigger:** Manual dispatch with version input, or tag push (e.g., `git tag v1.2.3`)

What it does:
- Versions all schema names: `org.synapse.nf-template` → `org.synapse.nf-template-1.2.3`
- Registers all schemas with Synapse
- Creates GitHub release with tarball

**Schema naming convention:** `org.synapse.nf-{templatename-lowercase}`

### `synonyms.yml` — Ontology Synonym Management
**Trigger:** Manual dispatch with action choice

Actions:
- `extract-and-inject` — query ontologies + apply to modules
- `extract-only` — query ontologies, save to CSV
- `inject-only` — apply existing synonyms CSV to modules
- `test-inject` — dry run

Uses fuzzy matching (90% similarity threshold) and deduplicates case-only differences. Creates a PR for review.

### `weekly-model-system-sync.yml` — External Model System Sync
**Trigger:** Weekly cron

Runs `utils/sync_model_systems.py` to pull updated lists of animal models, cell lines, genetic reagents, and antibodies from external databases into the `modules/Sample/` and `modules/Experiment/` YAML files.

### `rebuild-artifacts-on-main.yml`
**Trigger:** Push to `main`

Rebuilds all artifacts after merging so the committed files stay current.

### `dispatch-downstream-staging.yml`
**Trigger:** After main CI passes on `main`

Notifies downstream repos (e.g., dcc-site) that the data model has been updated.

## Curation Task Utilities

### Create a File-Based Curation Task
Used when a Synapse folder needs file metadata annotation:
```bash
SYNAPSE_AUTH_TOKEN="$TOKEN" python utils/create_curation_task.py \
  --folder syn12345678 \
  --template RNASeqTemplate
```
Creates: EntityView (with schema-derived columns) + CurationTask bound to the folder.

### Create a Record-Based Curation Task
Used for non-file records (e.g., clinical data, datasets):
```bash
SYNAPSE_AUTH_TOKEN="$TOKEN" python utils/create_recordset_task.py \
  --parent syn12345678 \
  --schema org.synapse.nf-portalstudytemplate
```
Creates: RecordSet + CurationTask with DataGrid interface.

### Configure File View Columns from Schema
```bash
SYNAPSE_AUTH_TOKEN="$TOKEN" python utils/json_schema_entity_view.py \
  --view syn52702673 \
  --schema org.synapse.nf-partialtemplate
```
Updates the columns and search facets of a Synapse file view to match the current schema.

## Release Process
1. Create and merge PR with schema changes
2. Verify CI passes (all 4 jobs)
3. Determine version bump: MAJOR (breaking), MINOR (new concepts), PATCH (new child terms or definitions)
4. Run `release-new-version.yaml` with the new version
5. Update Data Curator App configuration with the new schema version

## Reference
- Repo: https://github.com/nf-osi/nf-metadata-dictionary
- Development guide: `docs/DEVELOPMENT.md`
- Design patterns: `docs/DESIGN.md`
- LinkML docs: https://linkml.io/linkml/
- EMBL-EBI Ontology Lookup: https://www.ebi.ac.uk/ols4/
- ONCOTREE (tumorType): https://oncotree.mskcc.org/
