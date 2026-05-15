# CFDA / Assistance Listing Numbers — NIH & HHS

CFDA numbers (now called Assistance Listings) are the primary way to filter NIH opportunities to a specific Institute or Center, since the `agencies` field treats all of NIH as `HHS-NIH11`.

Pass via `"cfda": "93.395"` in the search payload. Only one CFDA per query — to search multiple, run parallel queries and merge.

## NIH Institutes (93.xxx)

| CFDA | IC | Focus |
|---|---|---|
| 93.286 | NIBIB | National Institute of Biomedical Imaging and Bioengineering |
| 93.213 | NCCIH | National Center for Complementary and Integrative Health |
| 93.242 | NIMH | National Institute of Mental Health |
| 93.273 | NIAAA | National Institute on Alcohol Abuse and Alcoholism |
| 93.279 | NIDA | National Institute on Drug Abuse |
| 93.307 | NIMHD | National Institute on Minority Health and Health Disparities |
| 93.310 | NIH OD | NIH Office of the Director (Common Fund, DPCPSI) |
| 93.350 | NCATS | National Center for Advancing Translational Sciences |
| **93.393** | **NCI** | Cancer Cause and Prevention Research |
| **93.394** | **NCI** | Cancer Detection and Diagnosis Research |
| **93.395** | **NCI** | Cancer Treatment Research |
| **93.396** | **NCI** | Cancer Biology Research |
| **93.397** | **NCI** | Cancer Centers Support (P30 CCSGs) |
| **93.398** | **NCI** | Cancer Research Manpower (T32, F-series, K-series) |
| **93.399** | **NCI** | Cancer Control |
| 93.701 | NIH OD | Trans-NIH Recovery Act |
| 93.837 | NHLBI | Cardiovascular Research |
| 93.838 | NHLBI | Lung Research |
| 93.839 | NHLBI | Blood Research |
| 93.846 | NIAMS | National Institute of Arthritis and Musculoskeletal and Skin Diseases |
| 93.847 | NIDDK | National Institute of Diabetes and Digestive and Kidney Diseases |
| 93.853 | NINDS | Extramural Research Programs in the Neurosciences |
| 93.855 | NIAID | Allergy and Infectious Diseases Research |
| 93.856 | NIAID | Microbiology and Infectious Diseases Research |
| 93.859 | NIGMS | Biomedical Research and Research Training |
| 93.865 | NICHD | Child Health and Human Development Extramural Research |
| 93.866 | NIA | Aging Research |
| 93.867 | NEI | National Eye Institute |
| 93.879 | NLM | National Library of Medicine |
| 93.989 | FIC | Fogarty International Center |
| 93.172 | NHGRI | National Human Genome Research Institute |
| 93.121 | NIDCR | National Institute of Dental and Craniofacial Research |
| 93.113 | NIEHS | National Institute of Environmental Health Sciences |
| 93.361 | NINR | National Institute of Nursing Research |
| 93.173 | NIDCD | National Institute on Deafness and Other Communication Disorders |

## NCI in detail

NCI is split across **7 CFDAs**. To capture all NCI opportunities in one logical query, you'll need to make 7 calls or use post-hoc filtering. The split:

| CFDA | What goes here |
|---|---|
| 93.393 | Etiology, prevention, behavioral research |
| 93.394 | Imaging, biomarkers, diagnostics |
| 93.395 | Therapeutics development, clinical trials |
| 93.396 | Basic cancer biology, cell/molecular mechanisms |
| 93.397 | Cancer Center Support Grants (P30), SPOREs (P50), CCN |
| 93.398 | Training (T/F/K), career development |
| 93.399 | Population science, control, dissemination |

Most U54/U01/U19 cooperative agreements end up under 93.395 or 93.396; CCSGs under 93.397; data coordinating centers under whichever scientific CFDA the parent program lives in.

## Other major HHS programs

| CFDA | Program |
|---|---|
| 93.103 | FDA Research |
| 93.226 | AHRQ Research and Development |
| 93.231 | CDC Epidemiology and Laboratory Capacity |
| 93.243 | SAMHSA — Mental Health Services |
| 93.847 | NIDDK |
| 93.860 | HRSA — Health Centers |

## Looking up unfamiliar CFDAs

Each opportunity's detail response has `cfdas[].programTitle` — read those to learn the canonical name. The authoritative list is at <https://sam.gov/content/assistance-listings>.
