---
name: skill-name
description: |
  Write 1-2 sentences that answer: WHEN should Claude pick this skill over others?
  Lead with the precondition ("Use when X exists / is needed"), not just what it does.
  Call out what it does NOT do if there's a sibling skill that overlaps (e.g., "Do NOT use if Y — use skill-z instead").
  Good: "Use when writing code that interacts with Synapse (synapse.org) — uploads, downloads, table queries. Uses the modern synapseclient.models API."
  Bad: "Helps with Synapse." (too vague — Claude can't disambiguate from this)
  HARD LIMIT: 250 characters max — Claude Code truncates at 250. Front-load the key signal.
---

# [Skill Name]

## Overview

Brief description of what this skill enables Claude to do and what tool/service it covers.

## Installation

```bash
# How to install the underlying tool or package
pip install <package>
```

## Authentication

How to authenticate with the service (API keys, config files, environment variables, etc.).

```python
# Example authentication code
```

## Core Concepts

Key concepts the user needs to understand before using the skill:

- **Concept 1**: Description
- **Concept 2**: Description

## Common Operations

### Operation 1

Description of what this operation does.

```python
# Example code
```

### Operation 2

Description of what this operation does.

```python
# Example code
```

## Best Practices

- Tip 1
- Tip 2
- Link to official documentation: https://...
