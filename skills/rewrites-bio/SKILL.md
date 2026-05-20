---
name: rewrites-bio
description: Implement and review bioinformatics tool rewrites following the rewrites.bio framework (Seqera). Walks through the four phases — Philosophy, Planning, Building, Stewardship — and their 12 principles, with concrete checks, artifact templates (README credit + AI disclosure, CHANGELOG, validation policy), and review checklists. Use when starting a rewrite of an existing bioinformatics tool, reviewing one against the framework, or producing the artifacts (credits, AI disclosure, benchmark docs, governance files) the framework requires.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - WebFetch
  - AskUserQuestion
---

# rewrites.bio — Implementation & Review Skill

The framework (rewrites.bio, maintained by Seqera) is a manifesto for responsibly rewriting established bioinformatics tools with AI assistance. It has **4 phases / 12 principles**. This skill operationalizes each one for two workflows:

- **Implement** — you are starting or in the middle of a rewrite and need to do a step right.
- **Review** — you are auditing an existing rewrite repository against the framework.

Canonical source: <https://rewrites.bio/>. Repo: github.com/seqeralabs/rewrites.bio.

## When to invoke

- "I want to rewrite `<tool>` in Rust / Python / …" → start at Phase 1.
- "Review this repo against rewrites.bio" → run the full checklist (`references/checklist.md`) against the working dir.
- "Generate the AI-disclosure / credits / validation section for our README" → use `references/templates/`.
- "Is our benchmarking sufficient?" → jump to Phase 3.1.
- "We're about to release — what's missing?" → run the Phase 4 checklist.
- "Write up the rewrite as a preprint / paper" → use `references/templates/manuscript-skeleton.md` (modeled on the canonical mafsmith preprint).

## First action — pick the mode

Before doing anything else, decide which mode you are in. If the user has not made this clear, ask once:

1. **New rewrite** — walk forward through phases 1 → 4, producing artifacts as you go.
2. **Mid-project** — diagnose which phase the project is in (look for README, src/, tests/, benchmarks/, CHANGELOG.md, CONTRIBUTING.md), then jump in there.
3. **Review** — run the full checklist (`references/checklist.md`), produce a pass/fail/missing report. Do not edit files unless asked.
4. **Single artifact** — generate one document (e.g. AI disclosure block, validation methodology section). Use the matching template.
5. **Write up** — produce a preprint-style manuscript from an existing rewrite. Use `references/templates/manuscript-skeleton.md`; the structure is derived from the canonical published exemplar (`mafsmith`, Allaway 2026).

## The four phases

### Phase 1 — Philosophy (pre-code commitments)

These are commitments, not code. Get them in writing in the README *before* the first src/ file lands. Missing this phase is the most common failure mode of AI-assisted rewrites.

**1.1 Credit Original Authors.** Visible attribution in README, docs, papers, downstream reports, and a dedicated credits page if the tool has multiple ancestors. Include **citations (DOI), author lists, and the exact upstream version the rewrite tracks**. Cite-the-original guidance must appear where users would look for citation info (README "How to cite", `CITATION.cff`).
- *Check:* `grep -i 'original\|cite\|credit' README.md` returns something substantive. `CITATION.cff` exists and references the upstream paper, not just your repo.
- *Generate:* `references/templates/credits-block.md`.

**1.2 Emulate Exactly.** State up-front what "equivalent output" means for this tool.
- Deterministic tools → **byte-for-byte identical** output files. State this.
- Floating-point / probabilistic tools → **named, numerical tolerance** (e.g. "abs ≤ 1e-6, rel ≤ 1e-9 per cell" or "Jaccard ≥ 0.999 on variant sets"). Generic phrases like "scientifically equivalent" are not acceptable.
- Header formats, column ordering, file naming, and summary statistics all count.
- *Check:* the validation policy is explicit enough that a third party could reproduce the comparison.

**1.3 Be Transparent about AI.** Document which AI tools were used and their role (codegen, refactor, test generation, doc generation). State the **verification methodology** ("against mytool v1.0 on `<dataset>`") and **acknowledge coverage gaps** (e.g. "no validation yet on long-read inputs"). Code review alone is not a substitute for output comparison.
- *Generate:* `references/templates/ai-disclosure.md`.

### Phase 2 — Planning (scope)

**2.1 Think Big.** Before porting line-by-line, ask whether the boundary of the original tool is still the right boundary. Can upstream preprocessing be folded in? Can intermediate files be eliminated by in-memory data sharing with downstream steps? A pure 1:1 port often misses the larger speedup available from re-architecting.
- *Action:* sketch the data flow on both sides — original vs. proposed — and identify which intermediate files survive.

**2.2 Work Small.** Implementation cadence is the opposite of architecture: **smallest testable function first**, validate against the original, then extend. Each iteration loop should produce a comparison against the original on real input.
- *Anti-pattern:* "I had Claude generate the whole tool, then I'll validate at the end." Reject this; the debugging surface is too large.

### Phase 3 — Building

**3.1 Test and Benchmark with Real Data.** Synthetic data is fine for iteration, insufficient for validation. Diverse organisms, platforms, library preparations, and edge cases (empty files, very large files, malformed-but-tolerated inputs). **Document hardware, dataset (with accession), exact commands, and the output comparison method.**
- *Generate:* `references/templates/benchmark-record.md`.

**3.2 Build Only What You Need.** Feature completeness is not the goal — **output correctness on features that matter** is. Audit actual pipeline usage of the original tool. For unsupported flags, **fail loudly with a clear message**; never silently drop them or produce incorrect output.
- *Check:* `grep -r 'TODO\|FIXME\|not.implemented\|ignored' src/` — any unsupported-flag path that returns success rather than erroring is a bug.

**3.3 Pin Versions and Document.** Every equivalence claim is implicitly about a specific version of the original. Record: **upstream version**, **command lines**, **datasets/accessions**, **validation methodology**, and the **policy for handling upstream updates** (e.g. "we re-validate within 2 weeks of each minor release").
- *Generate:* `references/templates/validation-policy.md`.

### Phase 4 — Stewardship (post-release)

**4.1 Maintain and Govern.** Visible governance **before release**: `CONTRIBUTING.md`, `CHANGELOG.md`, versioned tags, an issue triage process, a re-validation policy.
- *Check:* files exist and are non-trivial (more than a stub).

**4.2 Preserve Compatibility.** Drop-in replacement means **identical file names, formats, column headers, ordering**. Reversibility ("if it breaks, swap the binary back") is what makes adoption risk-free for production pipelines.
- *Check:* any CLI flag, output filename, or column header that differs from the original is a release blocker unless explicitly justified.

**4.3 Release as Open Source.** Required for transparency, HPC accessibility, project continuity, and reproducibility. **Check the original's license first** — GPL/copyleft constrains your license choice; permissive (MIT, Apache-2.0, BSD) allows flexibility.
- *Check:* `LICENSE` exists; compatible with upstream's license; SPDX identifier in source headers if the project uses them.

**4.4 Contribute Upstream Responsibly.** Bugs found in the original during validation: **verify manually with the original tool on clean, well-understood input** before reporting. Rule out your reimplementation and malformed input first. **Never automate bug reports**; never paste AI-generated reproductions as evidence. File minimal, human-verified, reproducible examples.

## The badge

When a project passes all 12 principles, it can display the rewrites.bio badge:

```markdown
[![rewrites.bio](https://rewrites.bio/badges/rewrites-bio.svg)](https://rewrites.bio/)
```

Do not add the badge until every checklist item in `references/checklist.md` passes.

## Workflow — implement mode

1. Confirm working directory is the rewrite project root.
2. Detect current state: which phase artifacts already exist?
3. Walk forward from the earliest unmet principle. For each:
   - State the principle in one sentence.
   - Apply the *Check* from above to the repo.
   - If failing, propose the concrete artifact / code change, then apply with Edit/Write.
   - Mark done; move to next.
4. End with the checklist report (pass/fail/missing per principle).

## Workflow — review mode

1. Run `references/checklist.md` top-to-bottom against the repo. Do not edit.
2. For each principle, classify: **pass / partial / fail / not-applicable**, with a one-line evidence pointer (file path + line number where possible).
3. Group findings by phase. Surface blockers (Phase 4.2 compatibility, 1.2 equivalence spec) at the top.
4. End with a prioritized punch list. Do not generate fixes unless asked.

## Workflow — single-artifact mode

Pick the matching template from `references/templates/` and fill it in with project-specific values. Ask the user for any value that cannot be inferred from the repo (upstream version, validation datasets, AI tools used, hardware).

## Files

- `references/checklist.md` — the 12-principle pass/fail checklist used by review mode.
- `references/templates/credits-block.md` — README "Original tool & how to cite" block.
- `references/templates/ai-disclosure.md` — README AI-tools-and-validation block.
- `references/templates/validation-policy.md` — pinned-versions + upstream-update policy.
- `references/templates/benchmark-record.md` — one benchmark run, fully documented.
- `references/templates/contributing.md` — minimal `CONTRIBUTING.md` aligned with 4.1.
- `references/templates/manuscript-skeleton.md` — preprint structure for writing up a rewrite, derived from the published `mafsmith` paper (Allaway 2026, bioRxiv 2026.05.12.724685). Includes the abstract checklist, per-section requirements, validation/benchmark table schemas, compute-cost + carbon table format, and an acknowledgements pattern that satisfies Principles 1.1 + 1.3.

## Canonical exemplar

When a user asks "what does a finished rewrites.bio project look like?", point them at:

- **Repo:** <https://github.com/nf-osi/mafsmith> — a Rust rewrite of `vcf2maf`. Inspect: `README.md`, `manuscript/manuscript.md`, `results/README.md` (per-table source-data manifest), `benches/`, `tests/`.
- **Preprint:** Allaway RJ (2026). *mafsmith: a Rust reimplementation of vcf2maf.* bioRxiv 2026.05.12.724685. DOI: 10.64898/2026.05.12.724685.
- **What makes it exemplary:** explicit `--strict` mode for byte-identical comparison; full-cohort validation on 87.2 M variants with 0 conversion-field mismatches; 1-core AND N-core benchmarks to separate algorithmic from parallelism gains; named acknowledgement of `vcf2maf` authors; separate AI disclosures for implementation (Methods) and manuscript drafting (Acknowledgements); per-table source-data manifest in `results/README.md`.

## What this skill will not do

- Generate the actual rewrite code — that is the user's engineering work; this skill governs *how* the rewrite is structured and documented.
- Compare outputs for you. It will produce the comparison plan and the docs template, but running the original tool and the rewrite on real data is the user's job.
- File upstream bug reports (principle 4.4 explicitly prohibits automation).
