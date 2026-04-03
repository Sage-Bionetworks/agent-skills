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
| [synapse-python-client](synapse/skills/synapse-python-client/SKILL.md) | Interact with Synapse (synapse.org) for biomedical data sharing using the modern Python client | Bioinformatics |
| [bootstrap-claudemd](sage-internal/skills/bootstrap-claudemd/SKILL.md) | Generate a new CLAUDE.md from scratch by exploring a codebase | Developer Tools |
| [evolve-claudemd](sage-internal/skills/evolve-claudemd/SKILL.md) | Update existing CLAUDE.md files by analyzing code changes and auditing accuracy | Developer Tools |

## Contributing

Want to add a skill? See [CONTRIBUTING.md](CONTRIBUTING.md).
