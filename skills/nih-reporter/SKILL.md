---
name: nih-reporter
description: Query the NIH RePORTER API (api.reporter.nih.gov) for federally-funded research projects and publications. Covers POST /v2/projects/search and POST /v2/publications/search — criteria payload construction, pagination, rate-limit handling, and the criteria→response field-name mapping that trips up most callers.
---

# NIH RePORTER API

Public API exposing NIH and non-NIH agency awards (and linked publications). No authentication. Two endpoints — projects and publications. Returns JSON.

## Endpoints

| Endpoint | Use |
|---|---|
| `POST https://api.reporter.nih.gov/v2/projects/search` | Awards / projects |
| `POST https://api.reporter.nih.gov/v2/publications/search` | Publications linked to awards |

Both are `POST` only (`GET` returns 405). Body is JSON, `Content-Type: application/json`.

Interactive Swagger docs: <https://api.reporter.nih.gov/?urls.primaryName=V2.0>

## Rate Limits — Do Not Ignore

NIH publishes hard guidance, with IP-blocking as the stated consequence:

- **≤ 1 request per second** sustained.
- **Large jobs** (anything that paginates beyond a few pages): run **weekends, or weekdays 9pm–5am EST**.
- Backoff on `429` and `5xx`; do not retry tight.

For any pull > ~50 pages, add `time.sleep(1.1)` between requests and schedule for off-hours. Use a `User-Agent` that identifies you.

## Pagination Limits

| Field | Default | Max |
|---|---|---|
| `limit` | 50 | **500** |
| `offset` (projects) | 0 | **14,999** (offset+limit ≤ 15,000) |
| `offset` (publications) | 0 | **9,999** |

The 15k cap is hard — if your result set exceeds it, **split the query by fiscal year, IC, or activity code** rather than trying to page past it.

To know total results before paginating: the response includes `meta.total`. Issue one request with `limit: 1` first if you need to plan a pull.

## Minimal Request

```bash
curl -sS -X POST https://api.reporter.nih.gov/v2/projects/search \
  -H 'Content-Type: application/json' \
  -d '{
    "criteria": {"fiscal_years": [2024], "pi_names": [{"any_name": "Mitchell"}]},
    "include_fields": ["ProjectNum","ProjectTitle","Organization","AwardAmount","FiscalYear","PrincipalInvestigators"],
    "limit": 25,
    "offset": 0,
    "sort_field": "project_start_date",
    "sort_order": "desc"
  }' | jq .
```

## Payload Shape

```json
{
  "criteria": { ... filters ... },
  "include_fields": [ ... PascalCase field names ... ],
  "exclude_fields": [ ... ],
  "offset": 0,
  "limit": 50,
  "sort_field": "project_start_date",
  "sort_order": "desc",
  "use_relevance": false
}
```

**Three name conventions in the same payload — this is the #1 source of bugs:**

| Where | Convention | Example |
|---|---|---|
| `criteria` keys | `snake_case` | `fiscal_years`, `pi_names`, `org_states` |
| `include_fields` values | `PascalCase` | `FiscalYear`, `PrincipalInvestigators`, `OrgState` |
| Response JSON keys | `snake_case` | `fiscal_year`, `principal_investigators`, `org_state` |

If you send `"include_fields": ["fiscal_year"]` it is silently ignored — the API returns everything. Always PascalCase the include list.

For the full criteria↔include↔response mapping, see `references/field-mapping.md`.

## Common Criteria Patterns

### Text search (title / abstract / terms)
```json
"advanced_text_search": {
  "operator": "and",
  "search_field": "projecttitle,abstracttext,terms",
  "search_text": "single-cell pancreatic"
}
```
- `operator`: `"and"`, `"or"`, or `"advanced"` (advanced supports `AND`/`OR`/`NOT` + quoted phrases).
- `search_field`: comma-joined subset of `projecttitle`, `abstracttext`, `terms`.
- Stop-words ignored automatically. Quote phrases for exact match: `"\"breast cancer\""`.

### PI / PO names (object array)
```json
"pi_names": [{"any_name": "Smith"}],
"pi_names": [{"last_name": "Welch", "first_name": "John"}]
```
Each list element is an object with one of `any_name`, `first_name`, `middle_name`, `last_name`. Multiple list elements are OR'd. `any_name: ""` is a no-op placeholder when only specifying a sub-field — keep it if you copy from NIH examples.

### Organization
```json
"org_names": ["EMORY UNIVERSITY", "JOHNS HOPKINS UNIVERSITY"],
"org_names_exact_match": ["FRED HUTCHINSON CANCER CENTER"],
"org_states": ["WA","CA"],
"org_countries": ["UNITED STATES"],
"org_cities": ["SEATTLE"]
```
- `org_names` is wildcard/partial by default — `"HARVARD"` matches `HARVARD UNIVERSITY`, `HARVARD MEDICAL SCHOOL`, etc.
- Use `org_names_exact_match` when you need exactly one institution.

### Fiscal year / dates
```json
"fiscal_years": [2023, 2024, 2025],
"project_start_date": {"from_date":"2024-01-01","to_date":"2024-12-31"},
"project_end_date":   {"from_date":"2024-01-01","to_date":"2026-12-31"},
"award_notice_date":  {"from_date":"2024-01-01","to_date":"2024-12-31"},
"date_added":         {"from_date":"2024-01-01","to_date":"2024-12-31"}
```
`fiscal_years: []` matches all years. `date_added` is only populated from 2011-01-01 forward.

### IC / agency / activity / mechanism
```json
"agencies": ["NCI","NIGMS","NHGRI"],
"activity_codes": ["R01","R35","P20","U54"],
"award_types": ["1","2","5","4C","4N"],
"funding_mechanism": ["RP","SB","RC","OR","TR","TI","CO","NSRDC","SRDC","IAA","IM","Other"]
```
- `agencies` takes IC acronyms (`NCI`, not `CA`). Full list in `references/ic-codes.md`.
- `award_types` is the application type code (1=new, 2=renewal, 3=supplement, 4C/4N=Type 4 sub-types, 5=non-competing continuation, etc.).
- For `funding_mechanism`, value `"Other"` is a *combined* search for `UK + OT + CP` — there is no `"UK"` value you can pass directly.

### Amounts
```json
"award_amount_range": {"min_amount": 250000, "max_amount": 5000000}
```
Both fields required. Costs only populated from FY 2012 onward (and never for SBIR/STTR).

### Project numbers
```json
"project_nums": ["R01CA123456*", "5R01HG*"],
"project_num_split": {
  "appl_type_code":"1","activity_code":"R01","ic_code":"CA",
  "serial_num":"123456","support_year":"01","suffix_code":""
}
```
- `project_nums` accepts wildcards with `*`. Matches both `core_project_num` and `project_num`.
- `project_num_split` matches exactly on components — useful for parsing/joining ExPORTER-style IDs.

### Spending categories (RCDC)
```json
"spending_categories": {"values": [27, 60, 105], "match_all": false}
```
- `match_all: true` returns projects in **all** listed categories (intersection); `false` returns projects in **any** (union).
- IDs are numeric — see `references/spending-categories.md` for the FY2024 list (e.g. 27=Aging, 105=Brain Disorders, 132=Cancer).

### COVID-19
```json
"covid_response": ["Reg-CV","CV","C3","C4","C5","C6"]
```
Or `"All"` for any COVID-funded project. `Reg-CV` = regular appropriations; `CV/C3/C4/C5/C6` = the five supplemental appropriations acts.

### Booleans / flags
```json
"include_active_projects": true,
"exclude_subprojects": true,
"sub_project_only": false,
"multi_pi_only": false,
"newly_added_projects_only": false,
"is_agency_admin": true,
"is_agency_funding": true
```
`include_active_projects: true` restricts to currently-active awards (budget end date ≥ today).

## Sorting

`sort_field` accepts the `criteria` (snake_case) name of the field. Common ones: `project_start_date`, `project_end_date`, `award_notice_date`, `award_amount`, `fiscal_year`, `appl_id`. `sort_order`: `"asc"` or `"desc"`. Default `use_relevance: false`; set `true` only when combined with a text search.

## Publications Endpoint

Much narrower — only three criteria fields:

```json
{
  "criteria": {
    "pmids": [12345678, 23456789],
    "appl_ids": [10372367],
    "core_project_nums": ["R01CA123456", "R01HG*"]
  },
  "limit": 500,
  "offset": 0
}
```

Response per row: `coreproject` (core project num), `pmid`, `applid` (latest application ID). To enrich (title, journal, authors): pass the `pmid` list to PubMed via the `plugin_pubmed_PubMed` MCP tools.

## Reference Sheets

Field mapping, IC code list, and spending category IDs live in `references/`:

- `references/field-mapping.md` — every `criteria` → `include_fields` → response-key triple, with types and notes.
- `references/ic-codes.md` — IC acronyms (use in `agencies`) ↔ org code ↔ full name.
- `references/spending-categories.md` — FY2024 numeric IDs ↔ names.
- `references/recipes.md` — copy-paste payloads for common questions (who funds X, awards at org Y, all R01s in FY2024, etc.).

## Quick Python Helper

```python
import requests, time

URL = "https://api.reporter.nih.gov/v2/projects/search"
HEADERS = {"Content-Type": "application/json", "User-Agent": "your-email@example.org"}

def search_all(criteria, include_fields, page_size=500, sleep=1.1):
    """Paginate through all results. Stops at the 15k offset cap."""
    offset, out = 0, []
    while offset < 15000:
        body = {"criteria": criteria, "include_fields": include_fields,
                "offset": offset, "limit": page_size,
                "sort_field": "project_start_date", "sort_order": "desc"}
        r = requests.post(URL, json=body, headers=HEADERS, timeout=60)
        r.raise_for_status()
        data = r.json()
        out.extend(data["results"])
        total = data["meta"]["total"]
        if offset + page_size >= total: break
        offset += page_size
        time.sleep(sleep)
    return out, total
```

If `total > 15000`, partition by `fiscal_years` (one year at a time) or by `agencies` and concatenate.

## Common Gotchas

- **`include_fields` is PascalCase**, not the criteria name or the response name. `FiscalYear`, not `fiscal_year`. Wrong casing → silently ignored, full payload returned (slow).
- **`fiscal_years: []` ≠ omitting the key.** Empty array = "all years"; omitting the key may default to recent years depending on other filters.
- **`org_names` is partial-match** — `"WASHINGTON"` matches University of Washington, Washington State, Washington University in St. Louis. Use `org_names_exact_match` for precision.
- **`award_types: ["4"]` does not match Type 4 awards** — use `["4C","4N"]` (the documented sub-types).
- **Direct/indirect cost fields are null for SBIR/STTR and for pre-FY2012 awards.** Don't trust 0 = $0 funding; check the year/mechanism.
- **Offset cap is 15,000.** Beyond that, the API returns an error. Partition the query.
- **`pi_names` / `po_names` items are objects, not strings.** `["Smith"]` errors; `[{"any_name": "Smith"}]` works.
- **Dates in responses are ISO timestamps with Z** (`"2021-03-15T04:00:00Z"`), not date-only. Parse as datetime, not date.
- **`agency_ic_fundings` is a list** — a project funded by multiple ICs has multiple rows. Sum `total_cost` across the list if you want total project funding for that FY.
- **Stale or experimental wrappers exist** (`repoRter.nih` for R, `pynih` for Python). The R one is well-maintained as of 2024; useful as a reference for payload shape but not required.

## Project Detail Page

Each project has a human-readable page: `https://reporter.nih.gov/project-details/{appl_id}`. Useful for spot-checking API results and for citations in summaries.
