# Scientific Metadata Extraction

## Overview

Patterns for extracting and normalizing metadata from scientific data repositories (GEO, SRA/ENA, PRIDE, BioStudies, PubMed) and publication sources. Covers per-sample identifier derivation, author name normalization, assay type determination, species verification, file format normalization, and a 4-tier gap-fill strategy for resolving missing annotation fields.

## Installation

```bash
pip install biopython httpx
```

## Authentication

```python
from Bio import Entrez
import os

Entrez.email = "your@email.com"
if os.environ.get("NCBI_API_KEY"):
    Entrez.api_key = os.environ["NCBI_API_KEY"]   # raises limit from 3 to 10 req/s
```

## Core Concepts

- **Per-sample metadata**: Annotation fields that describe biological properties (tissue, genotype, sex, condition) vary between samples and must be fetched from per-sample records — never copied from a single study-level value.
- **Repository submitter ≠ PI**: Repository submitter fields reflect whoever deposited the files, often a postdoc or research engineer. Investigator/PI fields should come from the PubMed AuthorList.
- **Run accession ≠ biological ID**: SRR/ERR/DRR accessions identify sequencing runs, not specimens. Use BioSample IDs or sample titles as specimen identifiers.
- **Assay type from library metadata**: Publication titles describe biology, not technology. Always verify assay type from `library_strategy`/`library_source` in repository records.

## Common Operations

### Fetch Study Leads from PubMed

Always derive investigator names from the PubMed AuthorList — first author + last/corresponding author in `"Firstname Lastname"` format.

```python
from Bio import Entrez

def fetch_study_leads(pmid: str) -> list[str]:
    """Return [first_author, last_author] as 'Firstname Lastname' strings."""
    handle = Entrez.efetch(db="pubmed", id=str(pmid), rettype="xml", retmode="xml")
    recs = Entrez.read(handle)
    authors = recs["PubmedArticle"][0]["MedlineCitation"]["Article"]["AuthorList"]

    def fmt(auth) -> str:
        fore = str(auth.get("ForeName", ""))
        last = str(auth.get("LastName", ""))
        return f"{fore} {last}".strip()

    leads = [fmt(authors[0]), fmt(authors[-1])]
    return list(dict.fromkeys(leads))   # deduplicate if single-author paper

# Reformat GEO-style "Lastname FI" contributors
import re
def normalize_author_name(name: str) -> str:
    """'Smith JP' → 'J Smith', 'Doe, Jane' → 'Jane Doe'"""
    if "," in name:
        parts = [p.strip() for p in name.split(",", 1)]
        return f"{parts[1]} {parts[0]}"
    tokens = name.split()
    if len(tokens) == 2 and len(tokens[1]) <= 3 and tokens[1].isupper():
        return f"{tokens[1][0]} {tokens[0]}"
    return name
```

### Derive Per-Sample IDs from ENA Filereport

Map run accessions (SRR/ERR) to biological sample identifiers. Strip paired-end suffixes before lookup.

```python
import httpx, re

def get_ena_filereport(accession: str) -> list[dict]:
    """Fetch per-run metadata for a study or experiment accession."""
    resp = httpx.get(
        "https://www.ebi.ac.uk/ena/portal/api/filereport",
        params={
            "accession": accession,
            "result": "read_run",
            "fields": ("run_accession,sample_accession,sample_title,sample_alias,"
                       "scientific_name,instrument_model,library_strategy,"
                       "library_source,library_layout,fastq_ftp,submitted_ftp"),
            "format": "json",
        },
        timeout=30,
    )
    return resp.json() if resp.status_code == 200 else []

def strip_paired_suffix(filename: str) -> str:
    """'SRR12345_1.fastq.gz' → 'SRR12345'"""
    stem = filename.split(".")[0]
    return re.sub(r"_\d+$", "", stem)

# Build SRR → specimen_id map
filereport = get_ena_filereport("SRP123456")
srr_to_specimen = {
    r["run_accession"]: r.get("sample_title") or r.get("sample_alias", "N/A")
    for r in filereport
}

# Look up specimen ID for a file
srr_id = strip_paired_suffix(filename)
specimen_id = srr_to_specimen.get(srr_id, "N/A")
```

### Fetch BioSample Attributes for Per-Sample Metadata

```python
from Bio import Entrez
from xml.etree import ElementTree as ET

def get_biosample_attrs(biosample_acc: str) -> dict[str, str]:
    """Return attribute dict from a BioSample record (SAMN/SAME/SAMD)."""
    handle = Entrez.efetch(db="biosample", id=biosample_acc, rettype="xml")
    root = ET.parse(handle).getroot()
    attrs = {}
    for attr in root.iter("Attribute"):
        name = attr.get("attribute_name") or attr.get("harmonized_name", "")
        if name:
            attrs[name] = attr.text
    return attrs
# common keys: sex, age, tissue, disease, genotype, cell_type
```

### Parse GEO GSM Characteristics

```python
from Bio import Entrez

def get_gsm_characteristics(gsm_accession: str) -> dict[str, str]:
    """Return sample characteristics for a GEO GSM record."""
    handle = Entrez.efetch(db="gds", id=gsm_accession, rettype="full", retmode="text")
    attrs = {}
    for line in handle.read().splitlines():
        if line.startswith("!Sample_characteristics_ch1"):
            val = line.split("=", 1)[-1].strip()
            if ":" in val:
                k, v = val.split(":", 1)
                attrs[k.strip().lower()] = v.strip()
    return attrs
```

### Determine Assay Type from Library Metadata

Never infer assay type from paper title — verify from repository library strategy and source fields.

```python
SCRNA_SIGNALS = {
    "transcriptomic single cell",   # ENA library_source
    "scrna-seq",                    # library_strategy variants
    "10x chromium", "drop-seq", "indrop", "smart-seq2", "fluidigm c1",
}

def determine_assay(library_source: str = "", library_strategy: str = "",
                    protocol: str = "") -> str | None:
    combined = f"{library_source} {library_strategy} {protocol}".lower()
    if any(s in combined for s in SCRNA_SIGNALS):
        return "single-cell RNA-seq"
    if "rna" in combined or "transcriptomic" in combined:
        return "RNA-seq"
    if "atac" in combined:
        return "ATAC-seq"
    if "chip" in combined:
        return "ChIP-seq"
    if "wgs" in combined or "whole genome" in combined:
        return "WGS"
    if "wes" in combined or "exome" in combined:
        return "WES"
    if "bisulfite" in combined or "methyl" in combined:
        return "Bisulfite-seq"
    if "hi-c" in combined or "hic" in combined:
        return "Hi-C"
    return None   # unknown — flag for human review
```

### Normalize File Formats

Strip compression suffixes before storing file format annotations.

```python
COMPRESSION_SUFFIXES = {".gz", ".bz2", ".zip", ".zst", ".xz"}

def normalize_file_format(filename: str) -> str:
    """'sample.fastq.gz' → 'fastq', 'counts.txt.gz' → 'txt'"""
    parts = filename.lower().split(".")
    while parts and f".{parts[-1]}" in COMPRESSION_SUFFIXES:
        parts.pop()
    return parts[-1] if len(parts) > 1 else ""
```

### 4-Tier Gap-Fill Strategy

When a required annotation field is missing, work through these tiers in order. Stop at the first tier that yields a valid, unambiguous value.

**Tier 1 — Structured repository metadata**
Primary source: ENA filereport columns, BioSample XML, GEO GSM `!Sample_characteristics_ch1`, SRA RunInfo.

**Tier 2 — Publication metadata**
PMC full-text methods section, CrossRef funder info, supplementary tables (download and parse).

**Tier 3 — Text extraction via reasoning**
Abstract and methods text — extract only unambiguous values explicitly stated (e.g., "all mice were female"). Flag in review comments when using this tier.

**Tier 4 — Data file inspection**
h5ad/loom `.obs` columns, BAM `@RG` tags, FASTQ headers, count matrix column headers.

Only after exhausting all four tiers should a field be marked unresolvable. Document each unresolvable field and its reason in the curation review comment.

```python
def resolve_field(field_name: str, filereport_row: dict,
                  biosample_attrs: dict, gsm_chars: dict) -> str | None:
    """Tier 1 lookup across structured repository sources."""
    # ENA filereport first
    for key in [field_name, field_name.lower(), field_name.replace("_", " ")]:
        if key in filereport_row and filereport_row[key]:
            return filereport_row[key]
    # BioSample attributes
    for key in [field_name, field_name.lower()]:
        if key in biosample_attrs and biosample_attrs[key]:
            return biosample_attrs[key]
    # GEO characteristics
    for key in [field_name, field_name.lower()]:
        if key in gsm_chars and gsm_chars[key]:
            return gsm_chars[key]
    return None   # move to Tier 2+
```

## Best Practices

- **Species from repository, never inferred**: Use ENA `scientific_name`, GEO `!Series_sample_taxid`, or BioStudies `Organism` — never assume species from disease context or model name.
- **Verify accession ownership before use**: NCBI elink frequently returns accessions from different papers. For GEO, confirm `Entrez.esummary(db='gds', ...)["PubMedIds"]` matches the PMID being processed.
- **Per-sample fields must vary per file**: If a field like tissue, genotype, sex, or condition has the same value on every file in a multi-group study, it was set at study level rather than per-sample — re-derive from per-sample metadata.
- **Empty schema enum = skip field**: If a controlled-vocabulary field's enum list is `[]`, no valid values exist in the current schema — do not set the field.
- **Document gaps in review comments**: When a field cannot be resolved from any source, or when a value was approximated, document it explicitly so human reviewers know what needs attention.
- NCBI Entrez rate limit: 3 req/s without API key, 10 req/s with `NCBI_API_KEY`. Add `time.sleep(0.12)` between Entrez calls without an API key.
- ENA Portal API docs: https://www.ebi.ac.uk/ena/portal/api/
- NCBI Entrez utilities: https://www.ncbi.nlm.nih.gov/books/NBK25501/
- BioSample attribute harmonization: https://www.ncbi.nlm.nih.gov/biosample/docs/attributes/
