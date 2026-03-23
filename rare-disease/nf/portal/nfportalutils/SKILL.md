# nfportalutils Skill

## Overview
`nfportalutils` is an R package providing convenience functions for project and metadata management in the NF-OSI data portal scope. It is used in the dcc-site checkpoint workflow for generating project status reports, and provides utilities for Synapse project creation and portal study registration.

- **Repo:** https://github.com/nf-osi/nfportalutils
- **Docs:** https://nf-osi.github.io/nfportalutils/
- **Docker image:** `ghcr.io/nf-osi/nfportalutils:v0.97-rc4`
- **Interops with:** Python synapseclient via `reticulate` (tested: synapseclient 4.3.1, reticulate 1.39.0)

## Installation

### R Package
```r
# Install from GitHub
devtools::install_github("nf-osi/nfportalutils")

# Or using pak
pak::pkg_install("nf-osi/nfportalutils")
```

### Docker (for CI/CD use)
```bash
docker pull ghcr.io/nf-osi/nfportalutils:v0.97-rc4
```

## Authentication

nfportalutils accesses Synapse via the Python client through reticulate:
```r
library(nfportalutils)
library(reticulate)

# Uses SYNAPSE_AUTH_TOKEN environment variable
syn <- reticulate::import("synapseclient")
syn$login()

# Or pass token directly
syn$login(authToken = Sys.getenv("SYNAPSE_AUTH_TOKEN"))
```

## Core Functions

### Project Setup

#### `new_project()`
Creates a new Synapse project from a DSP configuration. Used internally by the `provision_project.yml` workflow via the Docker image `ghcr.io/nf-osi/jobs-new-project` (which wraps nfportalutils).
```r
new_project(
  config_file = "json/dsp/NTAP/YIA_Doe_2022.json",
  auth_token = Sys.getenv("SYNAPSE_AUTH_TOKEN")
)
```

#### `register_study()`
Registers a provisioned Synapse project on the NF Data Portal (Portal - Studies table). Required fields: `name`, `summary`, `fundingAgency`, `initiative`, `PI`, `synPrincipal`, `diseaseFocus`.
```r
register_study(
  study_id = "syn99999999",
  config_file = "json/dsp/NTAP/YIA_Doe_2022.json"
)
```

### Checkpoint Reports

The primary use of nfportalutils in the automated pipeline is generating checkpoint reports via R Markdown. This is triggered by `checkpoint_report.yaml` in dcc-site.

#### Running a Checkpoint Report (via Docker)
```bash
# The checkpoint_report.yaml workflow does this automatically, but to run manually:
docker run --rm \
  -e SYNAPSE_AUTH_TOKEN="$SYNAPSE_AUTH_TOKEN" \
  -v "$(pwd)/output:/output" \
  ghcr.io/nf-osi/nfportalutils:v0.97-rc4 \
  Rscript -e "
    rmarkdown::render(
      system.file('rmarkdown/templates/checkpoint-report/skeleton/skeleton.Rmd',
                  package = 'nfportalutils'),
      params = list(study_id = 'syn99999999'),
      output_file = '/output/checkpoint_report.html'
    )
  "
```

#### Running via the dcc-site Workflow
```bash
gh workflow run checkpoint_report.yaml \
  --repo nf-osi/dcc-site \
  --field issue_number=42
```

The workflow uses `sop/get_study_params.sh` to extract the study ID from the GitHub issue, then runs the Docker container to generate the report, which is posted as a comment on the issue.

### Data Analysis Utilities

nfportalutils provides functions for working with the NF Portal data programmatically. Common patterns (see full docs at https://nf-osi.github.io/nfportalutils/):

```r
library(nfportalutils)

# Query portal data (wraps synapseclient table queries)
# The package provides helpers for common portal tables

# Analyze annotation completeness for a study
# (used in checkpoint reports)

# Portal - Files table analysis
# Checks for missing required annotations across a project's files
```

### Metadata Validation

```r
# Validate study metadata against portal requirements
# (used before portal registration)
validate_study_meta(
  config = list(
    name = "Study Name",
    diseaseFocus = "Neurofibromatosis 1",
    fundingAgency = "NTAP"
  )
)
```

## Common Use Cases

### Generate a Checkpoint Report Locally
```r
library(nfportalutils)
library(rmarkdown)

Sys.setenv(SYNAPSE_AUTH_TOKEN = "your-token")

rmarkdown::render(
  system.file("rmarkdown/templates/checkpoint-report/skeleton/skeleton.Rmd",
              package = "nfportalutils"),
  params = list(study_id = "syn99999999"),
  output_file = "checkpoint_syn99999999.html"
)
```

### Check Data Completeness for a Study
```r
# The checkpoint report template internally checks:
# - File annotation completeness (against syn52702673)
# - Whether datasets are created and have metadata
# - Expected vs. actual data types per the DSP
# - Embargo and grant date status

# Use the report template for the full analysis, or
# query syn52702673 directly for custom checks:
library(synapseclient)
syn <- import("synapseclient")$login()
# ... query syn52702673 as documented in annotations-file-view skill
```

## Integration with dcc-site Workflows

| Workflow | Usage |
|---|---|
| `provision_project.yml` | Uses `ghcr.io/nf-osi/jobs-new-project` (wraps nfportalutils `new_project()`) |
| `checkpoint_report.yaml` | Uses `ghcr.io/nf-osi/nfportalutils:v0.97-rc4` for R Markdown report |

The checkpoint report is the primary automated use. It is triggered when a project issue is labeled `checkpoint:grant-end` or `checkpoint:data-release` via `checkpoint_support.yaml`.

## Docker Image Versioning

The dcc-site workflows pin to `ghcr.io/nf-osi/nfportalutils:v0.97-rc4`. To update to a newer version:
1. Check for new releases: https://github.com/nf-osi/nfportalutils/releases
2. Update the image tag in `checkpoint_report.yaml`
3. Test with a dry-run dispatch before merging

## Reference
- Package docs: https://nf-osi.github.io/nfportalutils/
- GitHub: https://github.com/nf-osi/nfportalutils
- Checkpoint report workflow: `.github/workflows/checkpoint_report.yaml` in dcc-site
- Docker image: `ghcr.io/nf-osi/nfportalutils`
