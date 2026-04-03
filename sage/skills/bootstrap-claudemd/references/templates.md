# CLAUDE.md Templates

Use these as starting structures. Only include sections relevant to the project. Customize every line — never ship a template placeholder.

---

## Template: Minimal Project Root

```markdown
<!-- Last reviewed: YYYY-MM -->

## Project

<2-4 sentences: what this does, what system it belongs to>

## Stack

<language, runtime, framework, versions>

## Commands

| Command | Description |
|---------|-------------|
| `<command>` | <description> |

## Conventions

- <non-obvious pattern>

## Gotchas

- <thing that causes issues if you don't know about it>
```

---

## Template: Comprehensive Project Root

```markdown
<!-- Last reviewed: YYYY-MM -->

## Project

<2-4 sentences>

## Stack

<language, runtime, framework, database, test runner, build tool — with versions>

## Commands

| Command | Description |
|---------|-------------|
| `<build>` | <description> |
| `<test>` | <description> |
| `<lint>` | <description> |
| `<dev>` | <description> |

## Data Models

- `<path/to/schema>` — <what it defines, who consumes it>
- <non-obvious shape constraint or codegen pipeline>

## Conventions

- <non-obvious pattern not enforced by tooling>

## Architecture

```
<dir>/    # <purpose>
<dir>/    # <purpose>
```

## Constraints

- Never do X — because Y
- Always do Z — because W

## Anti-Patterns — Do NOT

- Do NOT X — because Y (evidence: PR #N)

## Testing

- <non-standard test approach or pattern>

## Related Systems

- `<repo/service>` — <relationship>
```

---

## Template: Package/Module

```markdown
<!-- Last reviewed: YYYY-MM -->

## Project

<Purpose of this module within the larger system>

## Conventions

- <module-specific pattern differing from root>

## Constraints

- <module-specific hard rule with reason>
```

---

## Template: Monorepo Root

```markdown
<!-- Last reviewed: YYYY-MM -->

## Project

<Description of the monorepo and its orchestration>

## Stack

<Monorepo tooling: Nx/Turborepo/Lerna/Maven reactor + shared versions>

## Packages

| Package | Path | Purpose |
|---------|------|---------|
| `<name>` | `<path>` | <purpose> |

## Commands

| Command | Description |
|---------|-------------|
| `<command>` | <description> |

## Cross-Package Patterns

- <shared convention across packages>
- <generation/sync pattern>

## Constraints

- <monorepo-wide hard rule with reason>
```
