# README block — Original tool & how to cite

Drop this into the README. Replace `{{...}}` placeholders. Keep the structure; the rewrites.bio framework expects citation guidance to appear where users would look for it.

```markdown
## Original tool

`{{rewrite-name}}` is a rewrite of [`{{original-tool}}`]({{original-url}}) by
{{original-authors}} ({{original-affiliation}}). All algorithmic credit belongs
to the original authors; this project re-implements their work to obtain
performance improvements while producing equivalent outputs.

This rewrite tracks **{{original-tool}} v{{upstream-version}}**.

## How to cite

If you use `{{rewrite-name}}` in published work, please cite **both** the
original tool and this rewrite:

**Original (required):**
> {{original-citation-apa}}
> DOI: {{original-doi}}

**This rewrite (optional):**
> {{rewrite-citation}}

A machine-readable citation is provided in [`CITATION.cff`](./CITATION.cff).
```

## CITATION.cff companion

```yaml
cff-version: 1.2.0
message: "If you use this software, please cite both the original tool and this rewrite."
title: "{{rewrite-name}}"
version: "{{rewrite-version}}"
authors:
  - family-names: "{{rewrite-author-family}}"
    given-names: "{{rewrite-author-given}}"
references:
  - type: article
    title: "{{original-paper-title}}"
    authors:
      - family-names: "{{original-author-family}}"
        given-names: "{{original-author-given}}"
    doi: "{{original-doi}}"
    year: {{original-year}}
    journal: "{{original-journal}}"
```
