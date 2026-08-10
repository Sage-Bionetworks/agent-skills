# Agent Skills

A collection of agent skills for Sage Bionetworks — data science, bioinformatics, and research tooling for use with Claude Code.

## Install

```
/plugin marketplace add Sage-Bionetworks/agent-skills
/plugin install agent-skills
```

## Available Skills

| Skill | Description | Category |
|-------|-------------|----------|
| [synapse-python-client](skills/synapse-python-client/SKILL.md) | Interact with Synapse (synapse.org) for biomedical data sharing using the modern Python client | Bioinformatics |
| [nih-reporter](skills/nih-reporter/SKILL.md) | Query the NIH RePORTER API (projects + publications) — payload construction, pagination, rate-limit handling, and the criteria↔include↔response field-name mapping | Research |
| [synapse-data-curation](skills/synapse-data-curation/SKILL.md) | Advanced Synapse REST API patterns for data curation: annotations2 etag handling, Dataset entity creation with dynamic columns, JSON Schema binding, and wiki management | Bioinformatics |
| [scientific-metadata-extraction](skills/scientific-metadata-extraction/SKILL.md) | Extract and normalize scientific dataset metadata from GEO, SRA/ENA, PubMed, and BioSample: per-sample ID derivation, author normalization, assay type determination, and a 4-tier gap-fill strategy | Bioinformatics |
| [bootstrap-claudemd](skills/bootstrap-claudemd/SKILL.md) | Generate a new CLAUDE.md from scratch by exploring a codebase | Developer Tools |
| [evolve-claudemd](skills/evolve-claudemd/SKILL.md) | Update existing CLAUDE.md files by analyzing code changes and auditing accuracy | Developer Tools |
| [rewrites-bio](skills/rewrites-bio/SKILL.md) | Implement and review bioinformatics tool rewrites following the rewrites.bio framework: 4 phases / 12 principles, with checklists and artifact templates for credits, AI disclosure, equivalence specs, benchmarks, and governance | Bioinformatics |

## Contributing

Want to add a skill? See [CONTRIBUTING.md](CONTRIBUTING.md).
