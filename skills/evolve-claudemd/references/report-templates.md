# Change-Analysis Report Templates

Loaded on demand during Step 6 (present analysis). Fill these skeletons from the sub-agent digests.

**For large change sets** (many commits since last update): chunk findings by directory/module. Process each chunk fully. Present findings incrementally so the user can approve as you go. Large change sets deserve MORE scrutiny, not less — they represent the highest risk of CLAUDE.md drift.

## Executive Summary

```
## Evolution Summary

| File | Last Updated | Commits Since | Current Score | Projected Score |
|------|-------------|---------------|---------------|-----------------|
| ./CLAUDE.md | 2026-01-15 | 147 | 62/100 (C) | 85/100 (B) |
| ./lib/jdomodels/CLAUDE.md | 2026-02-20 | 43 | 78/100 (B) | 91/100 (A) |

- Files found: X
- Files needing update: X
- Stale references found: X
- New anti-patterns discovered: X
- Coverage gaps: X directories
```

## Per-File Report

```
## ./CLAUDE.md (last updated: YYYY-MM-DD, N commits since)

### Accuracy issues:
- Line 12: `DBOSearchIndex` renamed to `DBOSearchConfiguration` — update reference
- Line 34: Spring version "5.3.34" -> now "5.3.39" per pom.xml
- Line 78: Command `mvn test -pl lib/old-module` — module was renamed to `lib/new-module`

### Lines to remove:
- Line 45: "Use semicolons" — .eslintrc now enforces this (added in PR #412)
- Line 67: "Do not upgrade to React Router v6" — epic PORTALS-2847 completed

### Lines to add:
- Constraint: "Never use @Autowired on fields — constructor injection required for testability" (from PR #4521 review)
- Data Models: New search configuration schema in lib/lib-auto-generated — generates POJOs consumed by 3 modules
- Convention: Workers in search/ package use ConcurrentWorkerStack exclusively

### Anti-pattern guardrails to add:
- Do NOT: "Do NOT refactor X to Y — a previous attempt was reverted (hash) because Z" (from reverted PR)
- Do NOT: "Do NOT use bare set() for DataFrame construction — non-deterministic ordering broke tests (PR #621)" (from production incident)
- Do NOT: "Do NOT write custom column checks — use existing utility process_functions.checkColExist()" (from reviewer pushback in PR #622)

### Data model changes:
- New JSON schemas: SearchConfiguration.json, SynonymSet.json — codegen pipeline produces POJOs
- New DDL: SearchConfiguration-ddl.sql, SynonymSet-ddl.sql — DBO classes consume these
- New enum values added to MigrationType.json — migration order matters

### Coverage gaps:
#### Needs own CLAUDE.md:
- lib/lib-grid/ — CRDT implementation, specialized patterns, 15 files, non-obvious @GridTransaction annotation

#### Should roll up into parent:
- lib/lib-grid/util/ → cover in lib/lib-grid/CLAUDE.md — only 2 helper files, no distinct patterns

#### Already covered:
- lib/lib-common/ → covered by ./CLAUDE.md architecture section

### Line count: currently 120, after changes ~145 (concise but complete)
```

Ask the user to approve, modify, or skip each change set.
