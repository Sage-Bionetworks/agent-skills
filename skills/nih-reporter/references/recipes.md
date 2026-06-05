# Recipes — Copy-Paste Payloads

Common questions and the exact `POST /v2/projects/search` body that answers them. All bodies omit `Content-Type` and headers — those are constant.

## All R01 awards to a PI in a fiscal year

```json
{
  "criteria": {
    "pi_names": [{"last_name": "Doe", "first_name": "Jane"}],
    "activity_codes": ["R01"],
    "fiscal_years": [2024]
  },
  "include_fields": ["ProjectNum","CoreProjectNum","ProjectTitle","FiscalYear","AwardAmount","Organization","AgencyIcAdmin","ProjectDetailUrl"],
  "limit": 100, "offset": 0,
  "sort_field": "award_amount", "sort_order": "desc"
}
```

## Everything ever funded for one PI (by NIH profile_id, the safest identifier)

```json
{
  "criteria": { "pi_profile_ids": [10601669] },
  "include_fields": ["ProjectNum","CoreProjectNum","ProjectTitle","FiscalYear","AwardAmount","ActivityCode","AwardType","Organization","AgencyIcAdmin","ProjectStartDate","ProjectEndDate","ProjectDetailUrl"],
  "limit": 500, "offset": 0,
  "sort_field": "fiscal_year", "sort_order": "desc"
}
```
Find the profile_id once by name search, then reuse — much cleaner than name matching.

## All NIH funding to one institution, last 5 FYs

```json
{
  "criteria": {
    "org_names_exact_match": ["FRED HUTCHINSON CANCER CENTER"],
    "fiscal_years": [2021, 2022, 2023, 2024, 2025]
  },
  "include_fields": ["CoreProjectNum","ProjectTitle","FiscalYear","AwardAmount","ActivityCode","AgencyIcAdmin","PrincipalInvestigators","ProjectDetailUrl"],
  "limit": 500, "offset": 0,
  "sort_field": "award_amount", "sort_order": "desc"
}
```

## NCI U54 / U24 consortium awards (atlases, networks)

```json
{
  "criteria": {
    "agencies": ["NCI"],
    "activity_codes": ["U54","U24","U2C"],
    "include_active_projects": true
  },
  "include_fields": ["CoreProjectNum","ProjectTitle","Organization","PrincipalInvestigators","AwardAmount","FiscalYear","ProjectStartDate","ProjectEndDate","OpportunityNumber","AbstractText","ProjectDetailUrl"],
  "limit": 500, "offset": 0,
  "sort_field": "award_amount", "sort_order": "desc"
}
```

## Text search across title + abstract + terms

```json
{
  "criteria": {
    "advanced_text_search": {
      "operator": "and",
      "search_field": "projecttitle,abstracttext,terms",
      "search_text": "spatial transcriptomics tumor microenvironment"
    },
    "fiscal_years": [2024, 2025]
  },
  "include_fields": ["CoreProjectNum","ProjectTitle","Organization","PrincipalInvestigators","AwardAmount","FiscalYear","AgencyIcAdmin","ProjectDetailUrl"],
  "limit": 100, "offset": 0,
  "use_relevance": true,
  "sort_order": "desc"
}
```

`use_relevance: true` returns results ranked by text-match score instead of by `sort_field`.

## Advanced boolean text search

```json
{
  "criteria": {
    "advanced_text_search": {
      "operator": "advanced",
      "search_field": "projecttitle,abstracttext",
      "search_text": "(\"single cell\" OR \"single-cell\") AND (cancer OR tumor) NOT mouse"
    }
  },
  "include_fields": ["CoreProjectNum","ProjectTitle","AbstractText","ProjectDetailUrl"],
  "limit": 50, "offset": 0
}
```

## Newly-released projects (the past two data refreshes)

```json
{
  "criteria": { "newly_added_projects_only": true },
  "include_fields": ["ApplId","ProjectNum","ProjectTitle","FiscalYear","AwardAmount","Organization","DateAdded","ProjectDetailUrl"],
  "limit": 500, "offset": 0,
  "sort_field": "award_notice_date", "sort_order": "desc"
}
```

Useful for tracking new awards weekly. Combine with `fiscal_years: [2025]` to scope.

## Projects added in a date window (more reliable than newly_added)

```json
{
  "criteria": {
    "date_added": {"from_date":"2025-01-01","to_date":"2025-03-31"}
  },
  "include_fields": ["ApplId","ProjectNum","ProjectTitle","FiscalYear","AwardAmount","Organization","AgencyIcAdmin","DateAdded","ProjectDetailUrl"],
  "limit": 500, "offset": 0,
  "sort_field": "date_added", "sort_order": "desc"
}
```

## Funding by RCDC spending category — Cancer + AI/ML

```json
{
  "criteria": {
    "spending_categories": {"values": [132, 4372], "match_all": true},
    "fiscal_years": [2024]
  },
  "include_fields": ["CoreProjectNum","ProjectTitle","Organization","AwardAmount","AgencyIcAdmin","SpendingCategoriesDesc","ProjectDetailUrl"],
  "limit": 500, "offset": 0,
  "sort_field": "award_amount", "sort_order": "desc"
}
```

## All COVID-era awards

```json
{
  "criteria": { "covid_response": ["All"] },
  "include_fields": ["CoreProjectNum","ProjectTitle","FiscalYear","AwardAmount","Organization","CovidResponse","AgencyIcAdmin","ProjectDetailUrl"],
  "limit": 500, "offset": 0,
  "sort_field": "fiscal_year", "sort_order": "desc"
}
```

## Awards above an amount threshold

```json
{
  "criteria": {
    "fiscal_years": [2024],
    "award_amount_range": {"min_amount": 5000000, "max_amount": 1000000000}
  },
  "include_fields": ["CoreProjectNum","ProjectTitle","Organization","PrincipalInvestigators","AwardAmount","ActivityCode","AgencyIcAdmin","ProjectDetailUrl"],
  "limit": 500, "offset": 0,
  "sort_field": "award_amount", "sort_order": "desc"
}
```

## Resolve an ExPORTER-style project number

```json
{
  "criteria": {
    "project_num_split": {
      "appl_type_code": "5", "activity_code": "U24",
      "ic_code": "CA", "serial_num": "233280",
      "support_year": "05", "suffix_code": ""
    }
  },
  "include_fields": ["ApplId","ProjectNum","CoreProjectNum","ProjectTitle","FiscalYear","AwardAmount","Organization","PrincipalInvestigators"],
  "limit": 10, "offset": 0
}
```

## Lookup by core project number wildcard

```json
{
  "criteria": { "project_nums": ["U24CA233280*","U2CCA233291*"] },
  "include_fields": ["ApplId","ProjectNum","CoreProjectNum","FiscalYear","AwardAmount","ProjectTitle"],
  "limit": 50, "offset": 0,
  "sort_field": "fiscal_year", "sort_order": "asc"
}
```

## Multi-PI projects only at a state

```json
{
  "criteria": {
    "multi_pi_only": true,
    "org_states": ["WA"],
    "fiscal_years": [2024]
  },
  "include_fields": ["CoreProjectNum","ProjectTitle","Organization","PrincipalInvestigators","AwardAmount","ActivityCode","ProjectDetailUrl"],
  "limit": 500, "offset": 0
}
```

## Publications linked to a core project

```json
POST /v2/publications/search
{
  "criteria": { "core_project_nums": ["U24CA233280"] },
  "limit": 500, "offset": 0
}
```
Returns `{coreproject, pmid, applid}`. Pipe the `pmid` list into the `plugin_pubmed_PubMed` MCP tools for titles, authors, journals.

## Cohort: how to handle > 15,000 results

When `meta.total > 15000`, split by year and concatenate. Example pseudocode:

```python
all_rows, totals = [], {}
for fy in range(2015, 2026):
    rows, total = search_all(
        criteria={"fiscal_years":[fy], "agencies":["NCI"]},
        include_fields=[...],
    )
    all_rows.extend(rows); totals[fy] = total
```

If a single year still exceeds 15k (e.g. all-NIH for a recent year), split additionally by `agencies` or `activity_codes`.

## Counting only (no row data)

The cheapest way to get a count: one request with `limit: 1` and the smallest possible `include_fields`. Read `meta.total`.

```json
{
  "criteria": { "agencies": ["NCI"], "fiscal_years": [2024] },
  "include_fields": ["ApplId"],
  "limit": 1, "offset": 0
}
```
