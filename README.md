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
| [synapse-data-curation](skills/synapse-data-curation/SKILL.md) | Advanced Synapse REST API patterns for data curation: annotations2 etag handling, Dataset entity creation with dynamic columns, JSON Schema binding, and wiki management | Bioinformatics |
| [scientific-metadata-extraction](skills/scientific-metadata-extraction/SKILL.md) | Extract and normalize scientific dataset metadata from GEO, SRA/ENA, PubMed, and BioSample: per-sample ID derivation, author normalization, assay type determination, and a 4-tier gap-fill strategy | Bioinformatics |
| [grants-gov](skills/grants-gov/SKILL.md) | Query the Grants.gov public API for federal funding opportunities (NOFOs). Documents the URL-vs-API gotcha, covers search and fetch-details endpoints, and ships Sage-aligned recipes for finding DCC / data-infrastructure / atlas / omics / AI / digital-twin opportunities across cancer, neurodegeneration, and rare disease | Research Tooling |
| [bootstrap-claudemd](skills/bootstrap-claudemd/SKILL.md) | Generate a new CLAUDE.md from scratch by exploring a codebase | Developer Tools |
| [evolve-claudemd](skills/evolve-claudemd/SKILL.md) | Update existing CLAUDE.md files by analyzing code changes and auditing accuracy | Developer Tools |

## Contributing

Want to add a skill? See [CONTRIBUTING.md](CONTRIBUTING.md).
