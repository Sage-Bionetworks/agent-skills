# Field Mapping — Criteria ↔ Include ↔ Response

The three different naming conventions for the same logical field. Use this table when constructing requests.

- **Criteria name** is what you put inside `"criteria": {...}` — snake_case.
- **Include name** is what you put inside `"include_fields": [...]` — PascalCase.
- **Response key** is the JSON key in `results[i]` — snake_case (often, but not always, the same as criteria name).
- `NA` means the field is available in only one direction.

## Project IDs / Numbers

| Field | Criteria | Include | Response | Type |
|---|---|---|---|---|
| Application ID | `appl_ids` | `ApplId` | `appl_id` | int |
| Subproject ID | `exclude_subprojects` / `sub_project_only` | `SubprojectId` | `subproject_id` | int |
| Full project number | `project_nums` (wildcard `*` ok) | `ProjectNum` | `project_num` | string |
| Core project number | `project_nums` | `CoreProjectNum` | `core_project_num` | string |
| Project serial num | `serial_num` (inside `project_num_split`) | `ProjectSerialNum` | `project_serial_num` | string |
| Project number components | `project_num_split` (object) | `ProjectNumSplit` | `project_num_split` | object |

`project_num_split` sub-fields: `appl_type_code`, `activity_code`, `ic_code`, `serial_num`, `support_year`, `full_support_year`, `suffix_code`.

## Award / Funding

| Field | Criteria | Include | Response | Type |
|---|---|---|---|---|
| Application type | `award_types` (use `4C`/`4N` for type 4) | `AwardType` | `award_type` | string |
| Activity code | `activity_codes` | `ActivityCode` | `activity_code` | string |
| Award amount (total) | `award_amount_range` (`{min_amount,max_amount}`) | `AwardAmount` | `award_amount` | number |
| Direct cost | NA | `DirectCostAmt` | `direct_cost_amt` | number |
| Indirect cost | NA | `IndirectCostAmt` | `indirect_cost_amt` | number |
| Award notice date | `award_notice_date` (`{from_date,to_date}`) | `AwardNoticeDate` | `award_notice_date` | date |
| Budget start | NA | `BudgetStart` | `budget_start` | date |
| Budget end | NA | `BudgetEnd` | `budget_end` | date |
| Project start | `project_start_date` (`{from_date,to_date}`) | `ProjectStartDate` | `project_start_date` | date |
| Project end | `project_end_date` (`{from_date,to_date}`) | `ProjectEndDate` | `project_end_date` | date |
| Fiscal year | `fiscal_years` (array of int) | `FiscalYear` | `fiscal_year` | int |
| Funding mechanism | `funding_mechanism` (array; `Other` = UK+OT+CP) | `FundingMechanism` / `MechanismCodeDc` | `funding_mechanism` / `mechanism_code_dc` | string |
| Opportunity number (FOA) | `opportunity_number` | `OpportunityNumber` | `opportunity_number` | string |
| CFDA code | NA | `CfdaCode` | `cfda_code` | string |
| ARRA indicator | NA | `ArraFunded` | `arra_funded` | string (Y/N) |

## Agency / IC

| Field | Criteria | Include | Response | Type |
|---|---|---|---|---|
| Agency code | `agencies` | `AgencyCode` | `agency_code` | string |
| Administering IC | `is_agency_admin` | `AgencyIcAdmin` | `agency_ic_admin` | object `{code,abbreviation,name}` |
| Funding ICs | `is_agency_funding` | `AgencyIcFundings` | `agency_ic_fundings` | array `[{fy,code,name,abbreviation,total_cost}]` |

`agencies` takes the IC acronym (e.g. `NCI`, `NIGMS`), not the 2-letter org code.

## Organization

| Field | Criteria | Include | Response | Type |
|---|---|---|---|---|
| Org block | NA | `Organization` | `organization` | object |
| Org name (partial) | `org_names` | (in `Organization`) | `org_name` | string |
| Org name (exact) | `org_names_exact_match` | (in `Organization`) | `org_name` | string |
| Org city | `org_cities` | (in `Organization`) | `org_city` | string |
| Org state | `org_states` | (in `Organization`) | `org_state` | string |
| Org country | `org_countries` | (in `Organization`) | `org_country` | string |
| Org ZIP | NA | (in `Organization`) | `org_zipcode` | string |
| Org FIPS | NA | (in `Organization`) | `org_fips` | string |
| Org DUNS | NA | (in `Organization`) | `org_duns` | array |
| Org UEI | NA | (in `Organization`) | `org_ueis` | array |
| Org IPF code | NA | (in `Organization`) | `org_ipf_code` | string |
| Department type | `dept_types` | (in `Organization`) | `dept_type` | string |
| External org ID | NA | (in `Organization`) | `external_org_id` | int |
| Congressional district | `cong_dists` | `CongDist` | `cong_dist` | string (e.g. `"FL-26"`) |
| Org type | `organization_type` | `OrganizationType` | `organization_type` | object `{code,name,is_other}` |

The `Organization` include returns the whole nested object; selectively projecting sub-fields is not supported — you get them all.

## People

| Field | Criteria | Include | Response | Type |
|---|---|---|---|---|
| Principal investigators | `pi_names` (array of objs) / `multi_pi_only` | `PrincipalInvestigators` | `principal_investigators` | array of objects |
| PI profile ID | `pi_profile_ids` | (in `PrincipalInvestigators`) | `profile_id` | int |
| PI contact name | `pi_names` | `ContactPiName` | `contact_pi_name` | string |
| Program officers | `po_names` (array of objs) | `ProgramOfficers` | `program_officers` | array of objects |

Each `pi_names` / `po_names` element is an object with one of: `any_name`, `first_name`, `middle_name`, `last_name`. PI profile IDs are stable across years and projects.

PI object fields: `profile_id`, `first_name`, `middle_name`, `last_name`, `full_name`, `is_contact_pi`, `title`, `email`.

## Study Section

| Field | Criteria | Include | Response | Type |
|---|---|---|---|---|
| Full study section | NA | `FullStudySection` | `full_study_section` | object |

Object fields: `srg_code`, `srg_flex`, `sra_designator_code`, `sra_flex_code`, `group_code`, `name`.

## Text / Categorization

| Field | Criteria | Include | Response | Type |
|---|---|---|---|---|
| Title / abstract / terms text | `advanced_text_search` (object) | (see specific fields below) | (see below) | — |
| Project title | (via `advanced_text_search.search_field=projecttitle`) | `ProjectTitle` | `project_title` | string |
| Abstract | (via `advanced_text_search.search_field=abstracttext`) | `AbstractText` | `abstract_text` | string |
| Public health relevance | NA | `PhrText` | `phr_text` | string |
| Preferred terms (RCDC) | (via `advanced_text_search.search_field=terms`) | `PrefTerms` | `pref_terms` | string |
| Project terms | NA | `Terms` | `terms` | string |
| Spending categories | `spending_categories` (`{values:[…], match_all:bool}`) | `SpendingCategoriesDesc` / `SpendingCategories` | `spending_categories_desc` / `spending_categories` | array |
| COVID response | `covid_response` (array) | `CovidResponse` | `covid_response` | string |

`advanced_text_search` shape: `{"operator": "and|or|advanced", "search_field": "projecttitle,abstracttext,terms", "search_text": "..."}`. Commas in `search_field` are required to AND across fields.

## State Flags

| Field | Criteria | Include | Response | Type |
|---|---|---|---|---|
| Active flag | `include_active_projects` | `IsActive` | `is_active` | bool |
| Newly-added flag | `newly_added_projects_only` | `IsNew` | `is_new` | bool |
| Date added | `date_added` (`{from_date,to_date}`; ≥ 2011-01-01) | `DateAdded` | `date_added` | date |
| Project detail URL | NA | `ProjectDetailUrl` | `project_detail_url` | string |

## Recommended Minimal `include_fields`

For most exploratory queries this set gives 90% of what you need without bloating the response:

```json
["ApplId","ProjectNum","CoreProjectNum","ProjectTitle","FiscalYear",
 "AwardAmount","ActivityCode","AwardType","FundingMechanism",
 "Organization","PrincipalInvestigators","ProgramOfficers",
 "AgencyIcAdmin","ProjectStartDate","ProjectEndDate","OpportunityNumber",
 "AbstractText","PrefTerms","ProjectDetailUrl"]
```

Drop `AbstractText` and `PrefTerms` if you only need the row metadata — they account for most of the response size.
