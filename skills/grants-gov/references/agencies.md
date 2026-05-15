# Grants.gov — Agency Codes

The `agencies` parameter takes pipe-separated codes. Codes are case-sensitive (always uppercase).

## Top-level agencies (departments)

| Code | Department |
|---|---|
| `USDA` | Department of Agriculture |
| `DOC` | Department of Commerce |
| `DOD` | Department of Defense |
| `ED` | Department of Education |
| `DOE` | Department of Energy |
| `HHS` | Department of Health and Human Services |
| `DHS` | Department of Homeland Security |
| `HUD` | Department of Housing and Urban Development |
| `USDOJ` | Department of Justice |
| `DOL` | Department of Labor |
| `DOS` | Department of State |
| `DOI` | Department of the Interior |
| `USDOT` | Department of the Treasury |
| `DOT` | Department of Transportation |
| `VA` | Department of Veterans Affairs |
| `ARPAH` | Advanced Research Projects Agency for Health |
| `USAID` | Agency for International Development |
| `EPA` | Environmental Protection Agency |
| `NASA` | National Aeronautics and Space Administration |
| `NEA` | National Endowment for the Arts |
| `NEH` | National Endowment for the Humanities |
| `NSF` | U.S. National Science Foundation |
| `SBA` | Small Business Administration |
| `IMLS` | Institute of Museum and Library Services |

Bare `HHS` returns zero — the system requires the sub-agency code. Same for most departments with sub-agencies.

## HHS sub-agencies (the codes you'll actually use)

| Code | Agency |
|---|---|
| `HHS-NIH11` | **National Institutes of Health (all ICs)** |
| `HHS-FDA` | Food and Drug Administration |
| `HHS-CDC` | Centers for Disease Control and Prevention |
| `HHS-CDC-NCCDPHP` | CDC – National Center for Chronic Disease Prevention and Health Promotion |
| `HHS-CDC-NCIPC` | CDC – National Center for Injury Prevention and Control |
| `HHS-HRSA` | Health Resources and Services Administration |
| `HHS-AHRQ` | Agency for Healthcare Research and Quality |
| `HHS-CMS` | Centers for Medicare and Medicaid Services |
| `HHS-ACL` | Administration for Community Living |
| `HHS-ACF` | Administration for Children and Families |
| `HHS-IHS` | Indian Health Service |
| `HHS-SAMHS` | SAMHSA (legacy code, still active) |
| `HHS-SAMHS-SAMHSA` | SAMHSA (newer variant) |
| `HHS-OPHS` | Office of the Assistant Secretary for Health |
| `HHS-OS-ASPE` | Office of the Assistant Secretary for Planning and Evaluation |

## Critical caveat: NIH ICs are not separable at the agency level

**All NIH opportunities — NCI, NHLBI, NIAID, NHGRI, every IC — use the same agency code `HHS-NIH11`.** Grants.gov does not expose IC granularity through `agencies`. To filter to one IC:

1. **By CFDA / Assistance Listing** — each IC has its own CFDA number(s). See `references/cfda-nih.md`. For NCI: `"cfda": "93.395"` (treatment), `93.397` (centers support), `93.393`, `93.394`, `93.396`, `93.398`, `93.399`.
2. **By NOFO number prefix** — RFA-CA = NCI, RFA-HL = NHLBI, RFA-AI = NIAID, RFA-AG = NIA, etc. Use `keyword` or `oppNum` patterns.
3. **Client-side filter** after pulling HHS-NIH11 results — look at the `cfdaList` array on each hit.

Example: pull all currently-posted NCI cooperative agreements:
```json
{
  "agencies": "HHS-NIH11",
  "fundingInstruments": "CA",
  "cfda": "93.395",
  "oppStatuses": "posted"
}
```

## DOD sub-agencies

| Code | Agency |
|---|---|
| `DOD-AMRAA` | Army Medical Research Acquisition Activity (CDMRP) |
| `DOD-AMC-ACCAPG-DAHA` | Army Materiel Command |
| `DOD-ONR` | Office of Naval Research |
| `DOD-DARPA` | Defense Advanced Research Projects Agency |
| `DOD-AFRL` | Air Force Research Laboratory |

(Many more — the agencies facet in a `{"agencies":"DOD"}` response enumerates all current DOD sub-agencies.)

## How to discover other sub-agency codes

The facet response from any search includes an `agencies` array with codes that *actually have hits* in the filtered set. Run a broad search and read the facet:

```bash
curl -sS -X POST 'https://apply07.grants.gov/grantsws/rest/opportunities/search/' \
  -H 'Content-Type: application/json' \
  --data '{"rows":1,"keyword":"YOUR-TARGET-AGENCY-NAME","oppStatuses":"posted|forecasted|closed|archived"}' \
  | python3 -c "import json,sys; d=json.load(sys.stdin); [print(o['value'], o['label']) for o in d['agencies']]"
```

Or sample 500 hits and tally `agencyCode` client-side — that surfaces the deepest sub-agency level present in the data.
