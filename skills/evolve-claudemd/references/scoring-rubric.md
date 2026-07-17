# Quality Scoring Rubric

Loaded on demand during Step 3 (audit). Score each existing CLAUDE.md against this rubric to establish a baseline before auditing details, then project the new score after proposing changes in Step 6.

| Criterion | Max Points | What to check |
|-----------|-----------|---------------|
| Commands/workflows | 20 | Are build, test, lint, deploy commands present with context? |
| Architecture clarity | 20 | Can Claude understand codebase structure, module relationships, entry points? |
| Non-obvious patterns | 15 | Are gotchas, quirks, workarounds, and "why we do it this way" captured? |
| Conciseness | 15 | No filler, no obvious info, no redundancy with code comments? |
| Currency | 15 | Do commands work? Are file references accurate? Tech stack current? |
| Actionability | 15 | Are instructions executable and copy-paste ready? Paths real? |

Grades: **A** (90-100), **B** (70-89), **C** (50-69), **D** (30-49), **F** (0-29)

Record the baseline score. After proposing changes, project the new score to show improvement.

## Line-by-Line Verification

The `verify-references.sh` script mechanically flags the *suspect* subset — audit only what it flags plus the judgment items below:

- **File paths mentioned** — still exist? (script flags missing)
- **Class/function/type names** — still exist? (script flags absent symbols)
- **Version numbers** — match current build files? (script flags mismatches)
- **Commands** — still present verbatim in package.json/Makefile/CI config? (script flags absent commands)
- **Constraints** — still relevant? Cross-reference with Jira (judgment, from tracker-analyst):
  - If a constraint references an in-progress migration and the related epic is now Done, the constraint may need to be lifted or updated.
  - If a constraint references a dependency version and that version has changed, update it.
- **Linter/formatter overlap** — were new configs added since last update? If so, any CLAUDE.md convention now enforced by tooling should be flagged for removal.
- **Data model accuracy**:
  - Have schemas/types been added, removed, or changed shape?
  - Have new fields been added that carry non-obvious constraints?
  - Have codegen pipelines changed (new plugins, different output directories)?
  - Have cross-boundary contracts shifted (API response shapes that downstream repos depend on)?
- **Architecture descriptions** — do they still match the actual module structure?
- **Related Systems** — are described relationships still accurate? Have new integrations been added?
