# Contributing a Skill

Thanks for contributing to Agent Skills! Follow these steps to add a new skill.

## Steps

1. **Fork** this repository and create a branch.

2. **Create your skill directory** under `skills/`:
   ```
   skills/<your-skill-name>/
     SKILL.md
   ```
   Use lowercase kebab-case for the directory name (e.g., `my-tool-python-client`).

3. **Write your skill** using the template at [`skills/_template/SKILL.md`](skills/_template/SKILL.md) as a guide. See [`skills/synapse-python-client/SKILL.md`](skills/synapse-python-client/SKILL.md) for a complete example.

4. **Add your skill to the table** in `README.md`.

5. **Open a pull request** with a brief description of what the skill covers.

## Skill Guidelines

- Cover one tool or service per skill directory.
- Include working code examples that follow current best practices.
- Document authentication clearly — this is often the hardest part for new users.
- Keep the skill focused on what Claude needs to know to use the tool, not a full API reference.
