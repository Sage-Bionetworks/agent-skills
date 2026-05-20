# CONTRIBUTING.md template

Required by rewrites.bio Principle 4.1 (Maintain and Govern). Drop in as `CONTRIBUTING.md`, edit `{{...}}` fields.

```markdown
# Contributing to {{rewrite-name}}

Thanks for considering a contribution. This project is a rewrite of
[`{{original-tool}}`]({{original-url}}) and follows the
[rewrites.bio](https://rewrites.bio/) framework. Please read this file before
opening a PR.

## The non-negotiable rule

**Output must match the original.** Every change must preserve our equivalence
target (see [`docs/validation-policy.md`](./docs/validation-policy.md)). If a
change alters output, it must either:

1. Be a bug fix where the original is also wrong (and we have filed upstream), or
2. Be opt-in behind a flag that defaults to original-matching behavior.

PRs that change output without one of the above will be rejected.

## How to propose a change

1. Open an issue first if the change is non-trivial.
2. For bug fixes: include a failing test against a minimal reproducible
   example, ideally on a small public dataset.
3. For new features: explain which real-pipeline usage requires it. We follow
   "build only what you need" (Principle 3.2) — unused features are
   maintenance debt.
4. Run the validation suite (`{{make validate / nextflow run validate.nf}}`)
   and include the comparison result in the PR description.

## Reporting upstream bugs

If your work uncovers a bug in `{{original-tool}}` itself:

1. Reproduce it manually with the **original** tool on clean, well-understood
   input.
2. Rule out our rewrite and rule out malformed input.
3. File the bug upstream **by hand** with a minimal reproducible example.
4. Do **not** submit AI-generated reproductions or automated bug reports
   (rewrites.bio Principle 4.4).

## AI assistance in contributions

You may use AI coding assistants. If you do:

- Disclose it in the PR description (tool + role).
- The output-equivalence requirement is the same as for human-written code.
- Do not paste AI-generated text into upstream bug reports.

## Code style

{{lints, formatters, etc.}}

## Releasing

- Versioning: {{semver / calver}}
- Tag releases; update [`CHANGELOG.md`](./CHANGELOG.md).
- Re-validate against the latest upstream patch release per
  [`docs/validation-policy.md`](./docs/validation-policy.md).
```
