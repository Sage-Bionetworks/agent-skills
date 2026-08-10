# Manuscript skeleton for a rewrites.bio writeup

A bioRxiv-style preprint structure derived from the canonical exemplar: **Allaway RJ (2026). mafsmith: a Rust reimplementation of vcf2maf. bioRxiv 2026.05.12.724685.** That paper rewrote a Perl bioinformatics tool (`vcf2maf`) in Rust and is the cleanest published example of a rewrites.bio-compliant writeup.

Source of the skeleton: <https://github.com/nf-osi/mafsmith/tree/main/manuscript> (Pandoc Markdown + BibTeX). The repo also publishes `results/README.md` mapping each manuscript table to the script that produced it — copy this pattern, it makes the paper reproducible.

## Frontmatter (Pandoc YAML)

```yaml
---
title: "{{rewrite-name}}: a {{new-language}} reimplementation of {{original-tool}}"
author: "{{Author Name}}^1^"
bibliography: references.bib
link-citations: true
csl: https://www.zotero.org/styles/nature
geometry: margin=0.75in
header-includes:
  - \usepackage{newunicodechar}
  - \newunicodechar{≠}{\ensuremath{\neq}}
  - \newunicodechar{≥}{\ensuremath{\geq}}
  - \newunicodechar{≤}{\ensuremath{\leq}}
  - \usepackage{xurl}
  - \usepackage[table]{xcolor}
  - \AtBeginEnvironment{longtable}{\scriptsize\rowcolors{2}{gray!12}{white}}
---

^1^ {{Affiliation, City, State, Country}}

ORCID: [{{0000-0000-0000-0000}}](https://orcid.org/{{0000-0000-0000-0000}})

**Corresponding author:** {{email}}
```

bioRxiv default license is **CC BY 4.0** unless you opt out — note this in your submission metadata. Confirm it's compatible with the original tool's license (it almost always is for permissive-licensed originals; check carefully for GPL/copyleft).

## Required sections (in order)

### Abstract — one paragraph

A rewrites.bio abstract is a tight checklist. Hit every item in this order:

1. What the data format / problem domain is and who consumes it.
2. What the canonical tool does and why it's the reference implementation.
3. Why it's a performance bottleneck (language, single-threaded, install pain).
4. What this rewrite is, the language, and the integration story (e.g. pairs with `<other rewrite>`).
5. **Equivalence claim with a number**: "field-for-field identical output across `{{N}}` validated `{{caller types / formats / dataset classes}}`" and "`{{0}}` conversion differences versus `{{original}}` across `{{N}}` datasets aligned to `{{reference builds}}`".
6. Companion subcommand validation if applicable.
7. **Speedup with range**: "approximately `{{N}}`-fold faster (range `{{lo}}`–`{{hi}}`×) on `{{total variants}}` totalling `{{M}}` million records".
8. Availability sentence: **"{{rewrite-name}} is open source under the same license as {{original-tool}} and available at {{URL}}."**

### Introduction (~3–4 paragraphs)

1. The data format and downstream consumers (concrete tool names + citations).
2. The original tool: what it does, why it became canonical, what edge cases it absorbed over years of production use.
3. The original tool's limitations (performance, dependencies, install friction). Mention any *related* recent rewrites of upstream/adjacent components (e.g. `fastVEP` is to mafsmith what your equivalent is to your tool).
4. Positioning paragraph: what your rewrite is, what it pairs with, and the headline equivalence + speedup claims with quantities. Foreshadow that you "describe the specific edge cases and caller-specific conventions that required careful evaluation to achieve full concordance".

### Methods

#### Development approach (1 paragraph)
- **Disclose AI tooling explicitly**: model name + version, CLI tool. The exemplar reads:
  > "implemented in `{{language}}` using `{{vendor}}`'s `{{model}}` language model assisted by the `{{CLI/agent}}` command-line interface."
- Describe the **iterative cycle**: implementation pass → field-by-field comparison on real VCFs → diagnose discrepancies to root cause → targeted fix → next cycle.
- State explicitly that **validation data IS also the data the conversion logic was refined against**. Do not hide this.

#### Datasets (1 paragraph + Table 1)
- Enumerate caller types / formats with citations.
- Justify breadth: organisms, platforms, library preps, reference builds (e.g. both GRCh38 and GRCh37).
- Explain why each category was included (e.g. why germline benchmarks alongside somatic).
- Say what was full-cohort vs. sampled (e.g. "2,000 variants per dataset; full cohort for `{{...}}`").
- Mention any **ad-hoc edge-case files** surfaced during development (the mafsmith paper names a specific Ion Torrent multi-allelic VCF that exposed an `AO` indexing bug — this kind of specificity strengthens the validation story).

#### Compute cost and carbon estimation (1 paragraph)
- Instance type and price (e.g. AWS c6a.4xlarge $0.612/hr us-east-1).
- Power model with **explicit coefficients** (CCF methodology with vendor-specific CPU coefficients, DRAM W/GB, PUE).
- Carbon intensity source and value (e.g. EPA eGRID 2022 subregion).

### Implementation

Section per architectural concern. The exemplar uses:

- **Overview** — subcommand list, pipeline stages (1)–(N), brief role of each stage.
- **Annotation** — engine integration, fallback (`--skip-annotation`), compatibility with the original annotation engine.
- **Transcript / record / entity selection** — priority order matching the reference implementation, tiebreaker behaviour.
- **Allele / record normalisation** — approach + special cases (symbolic ALTs, BND notation, etc.) + statement of any deviation from the original.
- **Genotype / depth / field extraction** — bullet list of preserved caller-specific behaviours, naming each caller. **Name the original behaviour you matched and the flag/mode that controls strict matching** (`--strict` in the exemplar).
- **Parallelism and performance** — libraries used (`rayon`, `jemalloc`, …), lazy-parsing strategies.

### Results

#### Validation (1 paragraph + Table 1)
- List the conversion fields you compared verbatim.
- State the mismatch count, mode (`--strict`), and total variants compared.
- Characterise *remaining* differences honestly (e.g. "restricted to `Variant_Classification` for 2–5 variants per dataset at gene-boundary regions where tools select different canonical transcripts").
- **Table 1 columns:** Caller | Source (with citation) | Variants compared.
- A second paragraph for the **end-to-end pipeline comparison** with the same annotation engine on both sides (run against two upstream versions, e.g. VEP 112 and VEP 115). State that the cache used for the equivalence run is the same one used for timing benchmarks — this ties the two experiments together.

#### Subcommand validation (1 paragraph + Table 2)
- One table per ancillary subcommand class. Document: dataset | genome | subcommands validated.
- Explain how inputs were normalized between the two implementations (e.g. "input MAFs were generated by running `{{rewrite}} {{cmd}} --skip-annotation` on the same VCFs, so both maf2vcf tools received byte-identical inputs").
- Paragraph on **non-obvious behaviours discovered during concordance** — specific bug fixes named.

#### Performance (multiple paragraphs + Tables 3–5)
- **Hardware spec** (instance, CPU, vCPU, RAM).
- **Conversion-only benchmark** isolating the rewrite from upstream annotation cost.
- Run at **1 core AND N cores** to separate algorithmic speedup from parallelism gains. Compute the parallel scaling factor explicitly.
- **Table 3** columns: Sample | Variants | Rewrite 1-core (s) | Rewrite N-core (s) | Original (s) | Speedup 1-core | Speedup N-core. Include mean ± SD row.
- Second benchmark for a different input regime (e.g. paired tumour/normal) — Table 4.
- **Full-pipeline symmetric comparison** (Table 5) — give the original tool every parallelism advantage available (`--vep-forks N`) so the comparison is fair.
- Note in-passing differences between annotation engines that are *not* the subject of this work (e.g. gene-model version drift).

#### Compute cost and carbon (Tables 6–9)
- **Per-sample** table: wall time, instance cost, power draw, energy Wh, CO₂e g.
- **Cohort-scale** table: 100 / 1,000 / 10,000 / 100,000 / 1,000,000 samples. This is the table that lands in talks.
- Repeat both for conversion-only and full-pipeline.

### Discussion

1. **Motivation paragraph** — restate why throughput matters in the target domain, then state the headline numbers in plain English with the algorithmic-vs-parallelism breakdown.
2. **Non-obvious behaviours paragraph** — list the production quirks that had to be replicated, by name. This is where you credit the original tool's accumulated wisdom.
3. **Known differences paragraph** — be explicit about intentional divergences, the `--strict` mode that disables them, and what's planned for future releases. Do not hide them.
4. **Sustainability paragraph** — per-sample → cohort-scale carbon savings.
5. **One-sentence summary** — "{{rewrite-name}} is a complete, self-contained rewrite of {{original-tool}} in {{language}}, designed as a drop-in replacement. It produces field-for-field identical output … while achieving {{N}}× faster conversion …"

### Data and code availability

- Repo URL with a sentence: "together with the validation, benchmarking, and compute-cost scripts used to produce every table and figure in this paper".
- **Per-table source-data manifest:** "the `results/README.md` file in the repository gives a per-table mapping from each manuscript table to its source data and generating script". Build this.
- Bulleted list of every dataset source with citation key and access URL.

### Acknowledgements

Two sentences only:

1. **Credit the original tool's authors by name.** The exemplar: "We are grateful to `{{names}}` for their sustained work developing and maintaining `{{original-tool}}` without which this rewrite would not have been possible."
2. **Disclose AI assistance in writing the manuscript itself** (separate from the implementation disclosure in Methods): "This article was drafted with the assistance of large language models (`{{vendor}} {{model}}`), with the author reviewing, editing, and verifying all content."

### Funding

The exemplar lists **two distinct funders** in its JATS `funding-group`, each with a ROR ID:

1. **Research funding body** — e.g. "Neurofibromatosis Therapeutic Acceleration Program" (ROR `01359dk79`).
2. **AI-vendor compute credits** — e.g. "API credits from Anthropic's AI for Science program" (ROR `056y0v115`).

If you used AI-vendor credits, declare them as a separate funder, not as a subordinate clause. This is the cleanest way to record the AI relationship in machine-readable form.

### JATS back-matter ordering (for the published paper)

The bioRxiv JATS structures the back as: `<sec>` Data and code availability → `<ack>` Acknowledgements → `<sec>` Funding → `<ref-list>` References. Pandoc will produce this ordering automatically if you write the sections in that order in your Markdown.

### References

Standard `::: {#refs} :::` block for Pandoc + Nature CSL. Use citation keys for: original tool, every benchmark dataset, every library you depend on, every downstream consumer named in the Introduction.

## Build

The exemplar uses a `manuscript/Makefile` with Pandoc:

```makefile
manuscript.pdf: manuscript.md references.bib
	pandoc manuscript.md \
	  --bibliography references.bib \
	  --citeproc \
	  --pdf-engine=xelatex \
	  -o manuscript.pdf
```

## What this skeleton enforces (mapped to the 12 principles)

| Section | Principle |
|---------|-----------|
| Abstract: "open source under the same license as `{{original}}`" | 4.3 |
| Abstract + Validation: explicit equivalence numbers | 1.2 |
| Methods → Development approach | 1.3 |
| Methods → Datasets | 3.1 |
| Implementation → `--strict` mode and named caller behaviours | 3.2 |
| Results → 1-core + N-core split | 3.1 (rigour) |
| Discussion → Known differences paragraph | 1.2, 1.3 |
| Data and code availability → per-table manifest | 3.3 |
| Acknowledgements → original authors named | 1.1 |
| Acknowledgements → manuscript-AI disclosure | 1.3 |
| Funding → AI compute credits | 1.3 |
