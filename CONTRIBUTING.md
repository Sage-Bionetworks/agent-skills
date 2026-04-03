# Contributing a Skill

Thanks for contributing to Agent Skills! Follow these steps to add a new skill.

## Steps

1. **Fork** this repository and create a branch.

2. **Create your skill directory** under the appropriate plugin:
   - `synapse/skills/<your-skill-name>/` — for skills useful to anyone working with Synapse or Sage open science tools
   - `sage-internal/skills/<your-skill-name>/` — for Sage team workflows or internal tooling

   Use lowercase kebab-case for the directory name (e.g., `my-tool-python-client`).

3. **Write your skill** using the template at [`sage-internal/skills/_template/SKILL.md`](sage-internal/skills/_template/SKILL.md) as a guide. See [`synapse/skills/synapse-python-client/SKILL.md`](synapse/skills/synapse-python-client/SKILL.md) for a complete example.

4. **Add your skill to the table** in `README.md`.

5. **Open a pull request** with a brief description of what the skill covers.

## Skill Guidelines

- Cover one tool or service per skill directory.
- Include working code examples that follow current best practices.
- Document authentication clearly — this is often the hardest part for new users.
- Keep the skill focused on what Claude needs to know to use the tool, not a full API reference.
