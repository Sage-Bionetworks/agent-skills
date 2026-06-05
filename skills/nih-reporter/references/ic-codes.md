# NIH IC Codes

For the `agencies` criteria parameter use the **acronym** (column 1). The 2-letter organizational code (column 3) appears inside project numbers and in `agency_ic_admin.code` / `agency_ic_fundings[].code`.

| Acronym | Full Name | Org Code |
|---|---|---|
| CC | Clinical Center | CC |
| CIT | Center for Information Technology | CIT |
| CSR | Center for Scientific Review | RG |
| FIC | John E. Fogarty International Center | TW |
| NCATS | National Center for Advancing Translational Sciences | TR |
| NCCIH | National Center for Complementary and Integrative Health | AT |
| NCI | National Cancer Institute | CA |
| NCRR | National Center for Research Resources (dissolved 12/2011) | RR |
| NEI | National Eye Institute | EY |
| NHGRI | National Human Genome Research Institute | HG |
| NHLBI | National Heart, Lung, and Blood Institute | HL |
| NIA | National Institute on Aging | AG |
| NIAAA | National Institute on Alcohol Abuse and Alcoholism | AA |
| NIAID | National Institute of Allergy and Infectious Diseases | AI |
| NIAMS | National Institute of Arthritis and Musculoskeletal and Skin Diseases | AR |
| NIBIB | National Institute of Biomedical Imaging and Bioengineering | EB |
| NICHD | Eunice Kennedy Shriver National Institute of Child Health and Human Development | HD |
| NIDA | National Institute on Drug Abuse | DA |
| NIDCD | National Institute on Deafness and Other Communication Disorders | DC |
| NIDCR | National Institute of Dental and Craniofacial Research | DE |
| NIDDK | National Institute of Diabetes and Digestive and Kidney Diseases | DK |
| NIEHS | National Institute of Environmental Health Sciences | ES |
| NIGMS | National Institute of General Medical Sciences | GM |
| NIMH | National Institute of Mental Health | MH |
| NIMHD | National Institute on Minority Health and Health Disparities | MD |
| NINDS | National Institute of Neurological Disorders and Stroke | NS |
| NINR | National Institute of Nursing Research | NR |
| NLM | National Library of Medicine | LM |
| OD | Office of the Director | OD |

## Non-NIH HHS Agencies in RePORTER

These can also appear in `agencies`:

- `AHRQ` — Agency for Healthcare Research and Quality
- `CDC` — Centers for Disease Control and Prevention
- `FDA` — Food and Drug Administration
- `ACF` — Administration for Children and Families
- `VA` — Department of Veterans Affairs

Cost figures (`direct_cost_amt`, `indirect_cost_amt`, `agency_ic_fundings[].total_cost`) are populated only for NIH, CDC, FDA, and ACF.

## Funding Mechanism Codes

For the `funding_mechanism` criteria (array of strings):

| Code | Meaning |
|---|---|
| `RP` | Non-SBIR/STTR Research Projects |
| `SB` | SBIR/STTR Research Projects |
| `RC` | Research Centers |
| `OR` | Other Research-Related |
| `TR` | Training, Individual |
| `TI` | Training, Institutional |
| `CO` | Construction Grants |
| `NSRDC` | Non-SBIR/STTR Contracts |
| `SRDC` | SBIR/STTR Contracts |
| `IAA` | Interagency Agreements |
| `IM` | Intramural Research |
| `Other` | Combined Other (OT) + Unknown (UK) + Cancer Control (CP) |

`"UK"`, `"OT"`, `"CP"` are **not** valid input values — use `"Other"` to search them as a group.

## Application Type Codes (`award_types`)

| Code | Meaning |
|---|---|
| `1` | New application |
| `2` | Competing continuation / renewal |
| `3` | Supplement (competing revision or administrative) |
| `4C` | Competing Type 4 (R37 extension; Fast-Track SBIR/STTR first non-competing year) |
| `4N` | Non-competing Type 4 |
| `5` | Non-competing continuation |
| `6` | Change of Organization Status (Successor-In-Interest) |
| `7` | Change of grantee institution |
| `8` | Type 5 transfer to another NIH IC |
| `9` | Change of NIH awarding IC (on competing continuation) |

Pass as **strings**, including for `4C`/`4N`. Bare `"4"` does **not** match; you must use the sub-types.
