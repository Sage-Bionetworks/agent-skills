# rewrites.bio — 12-Principle Checklist

Score each item: **pass / partial / fail / n/a**, with a one-line evidence pointer (path:line). Group blockers at the top of the review.

## Phase 1 — Philosophy

### 1.1 Credit Original Authors
- [ ] README has a prominent "Original tool" / "How to cite" section
- [ ] Citation includes DOI, author list, and upstream version tracked
- [ ] `CITATION.cff` exists and references the **upstream** paper, not just the rewrite
- [ ] Downstream reports / generated outputs include attribution to the original tool
- [ ] If the rewrite has multiple ancestors, a dedicated `CREDITS.md` exists

### 1.2 Emulate Exactly
- [ ] README states the equivalence target precisely
- [ ] For deterministic tools: "byte-for-byte identical output files" is stated
- [ ] For floating-point/probabilistic tools: a **named numerical tolerance** is stated (not "scientifically equivalent")
- [ ] Header formats, column ordering, file naming, and summary statistics are all in scope
- [ ] Equivalence is reproducible from the README by a third party

### 1.3 Be Transparent about AI
- [ ] README discloses which AI tools were used (model name + role: codegen / refactor / test gen / doc)
- [ ] Verification methodology is documented ("vs `<tool>` v`<ver>` on `<dataset>`")
- [ ] Validation coverage gaps are explicitly acknowledged
- [ ] No implicit claim that code review alone validates output

## Phase 2 — Planning

### 2.1 Think Big
- [ ] A design doc / README architecture section explains *why these boundaries*
- [ ] Considered folding in upstream preprocessing
- [ ] Considered eliminating intermediate files via in-memory data sharing
- [ ] Decision to keep / change the tool's boundary is documented

### 2.2 Work Small
- [ ] Commit history shows incremental work (not one giant initial commit)
- [ ] Tests cover individual functions, not just end-to-end
- [ ] Each function has a corresponding output comparison against the original

## Phase 3 — Building

### 3.1 Test and Benchmark with Real Data
- [ ] Benchmarks use real sequencing data (not only synthetic)
- [ ] Multiple organisms / platforms / library preps covered
- [ ] Edge cases: empty input, very large input, malformed-but-tolerated input
- [ ] Hardware, dataset accessions, and exact commands documented
- [ ] Output comparison method documented (and matches Principle 1.2 tolerance)

### 3.2 Build Only What You Need
- [ ] Supported feature set is documented and matches real pipeline usage
- [ ] Unsupported flags **fail loudly** with a clear message (not silently dropped)
- [ ] No silent fallback to incorrect output
- [ ] `grep -r 'TODO\|FIXME\|not.implemented' src/` reveals no silently-skipped paths

### 3.3 Pin Versions and Document
- [ ] Upstream tool version(s) validated against are listed
- [ ] Exact command lines for original vs. rewrite are recorded
- [ ] Dataset accessions / hashes are recorded
- [ ] Validation methodology is described in enough detail to reproduce
- [ ] Policy for handling upstream updates is documented

## Phase 4 — Stewardship

### 4.1 Maintain and Govern
- [ ] `CONTRIBUTING.md` exists and is non-trivial
- [ ] `CHANGELOG.md` exists and is updated per release
- [ ] Releases use versioned tags (semver or calver)
- [ ] Issue triage process is documented
- [ ] Re-validation policy on upstream updates is documented

### 4.2 Preserve Compatibility (release blocker)
- [ ] CLI flags match the original (or any divergence is justified in README)
- [ ] Output filenames match the original
- [ ] Output column headers and ordering match
- [ ] File formats match (delimiter, line endings, encoding)
- [ ] Swap-in / swap-out is reversible without pipeline changes

### 4.3 Release as Open Source
- [ ] `LICENSE` exists
- [ ] License is compatible with the upstream tool's license
- [ ] If upstream is GPL/copyleft, this project's license respects that
- [ ] SPDX identifiers in source headers (if the project uses them)
- [ ] Source is hosted publicly (GitHub / GitLab / equivalent)

### 4.4 Contribute Upstream Responsibly
- [ ] Documented process: verify with original tool before filing upstream
- [ ] No automated bug-report submission
- [ ] No AI-generated reproductions submitted as evidence
- [ ] Bug reports include minimal reproducible examples

## Badge eligibility

All 12 principles must be **pass** (or **n/a** with written justification) before adding:

```markdown
[![rewrites.bio](https://rewrites.bio/badges/rewrites-bio.svg)](https://rewrites.bio/)
```
