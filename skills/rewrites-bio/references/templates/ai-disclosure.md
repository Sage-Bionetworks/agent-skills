# README block — AI tools & validation

Required by rewrites.bio Principle 1.3 ("Be Transparent about AI"). Code review alone is **not** an acceptable validation strategy; you must compare outputs.

```markdown
## AI assistance disclosure

This rewrite was developed with assistance from AI coding tools. We disclose
this in keeping with the [rewrites.bio](https://rewrites.bio/) framework.

### Tools used

| Tool | Role |
|------|------|
| {{tool-1, e.g. Claude Code (Opus 4.7)}} | {{role, e.g. core algorithm implementation, test scaffolding}} |
| {{tool-2}} | {{role, e.g. refactoring, doc generation}} |

### How AI output was validated

We do **not** rely on code review alone. Every claim of output equivalence is
backed by running the original tool and this rewrite on real input data and
comparing outputs:

- **Reference implementation:** `{{original-tool}}` v`{{upstream-version}}`
- **Comparison method:** {{e.g. byte-for-byte diff of output files; OR
  per-cell absolute tolerance ≤ 1e-6, relative tolerance ≤ 1e-9}}
- **Validation datasets:** see [`docs/benchmarks/`](./docs/benchmarks/) for
  full hardware, accessions, and commands.

### Known validation gaps

We are transparent about coverage we have **not** yet achieved:

- {{e.g. Long-read (ONT, PacBio) inputs are not yet validated.}}
- {{e.g. Non-model organisms with unusual contig naming are not yet tested.}}
- {{e.g. The `--legacy-format` flag is rejected with an error rather than
  emulated.}}

We welcome contributions that close these gaps.
```
