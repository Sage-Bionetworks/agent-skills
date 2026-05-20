# Benchmark record template

One file per benchmark run, under `docs/benchmarks/{{date}}-{{dataset-slug}}.md`. Required by rewrites.bio Principle 3.1.

```markdown
# Benchmark: {{dataset-name}} on {{hardware-shortname}} ({{YYYY-MM-DD}})

## Dataset

- **Name:** {{e.g. NA12878 WGS, chr20 subset}}
- **Accession / source:** {{SRA / ENA / synthetic-with-seed}}
- **Size:** {{e.g. 12 GB compressed FASTQ, 280 M reads}}
- **Why this dataset:** {{covers diploid human variants on a real platform}}
- **Preprocessing:** {{exact commands to get from accession → input file}}

## Hardware

- CPU: {{model, sockets × cores}}
- RAM: {{GB}}
- Storage: {{local NVMe / network FS}}
- OS / kernel: {{...}}
- Container runtime (if any): {{Docker 25.0 / Singularity 4.1}}

## Versions

- Original: `{{tool}}` `{{v1.4.2}}` (build hash {{...}})
- Rewrite: `{{rewrite}}` `{{v0.3.0}}` (commit {{sha}})

## Commands

```bash
# Original
/usr/bin/time -v {{tool}} --flag1 --flag2 input.fq > original.out 2> original.err

# Rewrite
/usr/bin/time -v {{rewrite}} --flag1 --flag2 input.fq > rewrite.out 2> rewrite.err
```

## Output comparison

- **Method:** {{cmp -l / picard CompareSAMs / custom diff script}}
- **Tolerance applied:** {{byte-identical / abs ≤ 1e-6 / Jaccard ≥ 0.999}}
- **Result:** {{PASS / FAIL with details}}
- **Diff artifact:** [{{path-to-diff-or-summary}}]({{...}})

## Performance

| Metric | Original | Rewrite | Speedup |
|--------|----------|---------|---------|
| Wall time | {{...s}} | {{...s}} | {{Nx}} |
| Peak RSS | {{...GB}} | {{...GB}} | {{...}} |
| CPU time | {{...s}} | {{...s}} | {{...}} |

## Notes

{{Anything unusual: thermal throttling, NUMA effects, IO bound vs CPU bound,
unexpected memory behavior, threads used, warmup runs discarded, etc.}}
```
