# Validation policy template

One file under `docs/validation-policy.md`. Required by rewrites.bio Principle 3.3 — every equivalence claim is implicitly version-scoped.

```markdown
# Validation policy

## Equivalence target

{{One of:
- "Byte-for-byte identical output files."
- "Per-element absolute tolerance ≤ {{abs}}, relative tolerance ≤ {{rel}}."
- "Set-similarity Jaccard ≥ {{j}} on the output records."
}}

This applies to: {{list output files / columns / metrics in scope}}.

Out of scope: {{e.g. log file timestamps, temp file names, run-id headers}}.

## Pinned upstream version(s)

| Upstream version | This rewrite version | Validated on | Last re-validated |
|------------------|----------------------|--------------|-------------------|
| {{v1.4.2}}       | {{v0.3.0}}           | {{2026-04-01}} | {{2026-05-15}}  |
| {{v1.5.0}}       | {{v0.4.0}}           | {{2026-05-10}} | {{2026-05-10}}  |

## Validation datasets

| Dataset | Accession / source | Why this dataset | Notes |
|---------|-------------------|------------------|-------|
| {{e.g. NA12878 WGS subset}} | {{SRA SRR...}} | {{covers diploid human, ~30x}} | {{subset to chr20}} |
| {{e.g. mock community 16S}} | {{ENA PRJ...}} | {{tests amplicon path}} | |

## Validation commands

```bash
# Original
{{original-tool}} {{exact flags}} input.fq > original_out.bam

# This rewrite
{{rewrite-name}} {{exact flags}} input.fq > rewrite_out.bam

# Comparison
{{comparison-cmd e.g. cmp / picard CompareSAMs / custom script}}
```

## Hardware

| Component | Detail |
|-----------|--------|
| CPU | {{e.g. AMD EPYC 7763, 64 cores}} |
| RAM | {{e.g. 512 GB}} |
| Storage | {{e.g. local NVMe}} |
| OS | {{e.g. Ubuntu 22.04, kernel 5.15}} |

## Policy for upstream updates

- **Minor releases:** re-validate within {{N}} weeks. Open a tracking issue
  on release day.
- **Major releases:** treat as a new equivalence target; do not claim
  equivalence with the new version until benchmarks pass.
- **Patch releases:** spot-check; full re-validation only if release notes
  mention output-affecting changes.

## Reproducibility

Every entry in the table above must be reproducible by a third party using
only this document, the linked datasets, and the pinned versions.
```
