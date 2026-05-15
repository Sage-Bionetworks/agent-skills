# Grants.gov — Facet Code Reference

Pipe-separate multiple values in a single field. Counts shown are total opportunities of all statuses in each bucket as of mid-2026 (approximate — refresh occasionally).

## `oppStatuses`

| Code | Meaning |
|---|---|
| `posted` | Currently accepting applications |
| `forecasted` | Announced but not yet open |
| `closed` | Past due date, not yet archived |
| `archived` | Permanent record (most NOFOs end up here ~3 years after close) |

Default if omitted: `posted|forecasted`. Pass all four to search history.

## `fundingInstruments`

| Code | Meaning |
|---|---|
| `G` | Grant |
| `CA` | Cooperative Agreement |
| `PC` | Procurement Contract |
| `O` | Other |

NIH-style awards: R-series is `G`, U-series is `CA`, R&D contracts (N01) are `PC`.

## `fundingCategories`

| Code | Category |
|---|---|
| `ACA` | Affordable Care Act |
| `AG` | Agriculture |
| `AR` | Arts |
| `BC` | Business and Commerce |
| `CD` | Community Development |
| `CP` | Consumer Protection |
| `DPR` | Disaster Prevention and Relief |
| `ED` | Education |
| `ELT` | Employment, Labor and Training |
| `EN` | Energy |
| `EIC` | Energy Infrastructure and Critical Mineral and Material |
| `ENV` | Environment |
| `FN` | Food and Nutrition |
| `HL` | **Health** (NIH/CDC/HRSA cluster here) |
| `HO` | Housing |
| `HU` | Humanities |
| `ISS` | Income Security and Social Services |
| `IS` | Information and Statistics |
| `IIJ` | Infrastructure Investment and Jobs Act (IIJA) |
| `LJL` | Law, Justice and Legal Services |
| `NR` | Natural Resources |
| `OZ` | Opportunity Zone Benefits |
| `O` | Other |
| `RA` | Recovery Act |
| `RD` | Regional Development |
| `ST` | **Science and Technology and other Research and Development** (NSF/DOE/DOD R&D) |
| `T` | Transportation |

For biomedical research, the relevant filters are usually `HL|ST`.

## `eligibilities`

| Code | Eligible applicant type |
|---|---|
| `00` | State governments |
| `01` | County governments |
| `02` | City or township governments |
| `04` | Special district governments |
| `05` | Independent school districts |
| `06` | Public and State controlled institutions of higher education |
| `07` | Native American tribal governments (Federally recognized) |
| `08` | Public housing authorities/Indian housing authorities |
| `11` | Native American tribal organizations (non-federally recognized) |
| `12` | **Nonprofits with 501(c)(3) status** other than IHEs (Sage falls here) |
| `13` | Nonprofits without 501(c)(3) status |
| `20` | **Private institutions of higher education** |
| `21` | Individuals |
| `22` | For profit organizations other than small businesses |
| `23` | Small businesses |
| `25` | Others (see additional info field) |
| `99` | Unrestricted — open to any applicant type |

Common combination for R01-style NIH research nonprofits + universities:
```json
{"eligibilities": "12|20|06|99"}
```
