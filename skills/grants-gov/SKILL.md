---
name: grants-gov
description: Query the Grants.gov public API for federal funding opportunities (NOFOs). Covers the search and fetch-details endpoints — JSON payload construction, the URL-vs-API gotcha, facet filtering (agencies, fundingCategories, eligibilities), pagination, and parsing the synopsis structure. Use this when the user wants to find live federal funding announcements, look up an opportunity number, or pull details on a specific NOFO.
---

# Grants.gov API

Public API exposing every U.S. federal funding opportunity (synopsis, forecast, modifications). No authentication required for the working endpoints. Returns JSON.

## The URL gotcha — start here

The grants.gov website surfaces URLs like `https://www.grants.gov/api/common/search2` and `https://www.grants.gov/api/common/fetchOpportunity` in the address bar. **These return HTML pages, not JSON.** They are frontend routes, not API endpoints.

The actual JSON API lives on a different host. There is also an `api.grants.gov` (AWS API Gateway) but it requires authentication and is not publicly usable.

## Endpoints — the ones that actually work

| Endpoint | Use | Body format |
|---|---|---|
| `POST https://apply07.grants.gov/grantsws/rest/opportunities/search/` | Search opportunities (analog of "search2") | JSON |
| `POST https://apply07.grants.gov/grantsws/rest/opportunity/details` | Full details for one opportunity (analog of "fetchOpportunity") | **form-encoded** (`oppId=<n>`) |
| `GET  https://apply07.grants.gov/grantsws/OppDetails?oppId=<n>` | Same details via GET (convenient for browsers) | n/a |

Trailing slash on `/search/` matters — without it you get HTML.

## Rate limits

No published quota. Be polite: ~1 req/sec sustained, exponential backoff on `5xx`, identify yourself with `User-Agent`. The service has been stable but is run by HHS — IP-blocking is possible for abusive traffic.

## Minimal search

```bash
curl -sS -X POST 'https://apply07.grants.gov/grantsws/rest/opportunities/search/' \
  -H 'Content-Type: application/json' \
  -d '{
    "rows": 25,
    "keyword": "cancer data coordinating",
    "oppStatuses": "posted|forecasted",
    "agencies": "HHS-NIH11"
  }'
```

Response includes `hitCount`, `oppHits[]`, and facet objects (`agencies`, `eligibilities`, `fundingCategories`, `fundingInstruments`) reflecting the *filtered* result set — useful for refining a query.

## Search payload — the criteria you actually need

```json
{
  "rows": 25,
  "startRecordNum": 0,
  "keyword": "natural language search terms",
  "oppNum": "PAR-25-242",
  "cfda": "93.395",
  "oppStatuses": "posted|forecasted",
  "agencies": "HHS-NIH11|HHS-FDA",
  "eligibilities": "12|20",
  "fundingCategories": "HL|ST",
  "fundingInstruments": "G|CA",
  "dateRange": "28",
  "sortBy": "openDate|desc"
}
```

**Important rules**

- **Multi-value fields use `|` (pipe) as the separator**, not commas. E.g., `"oppStatuses": "posted|forecasted"`. A comma will be treated as part of the value and match nothing.
- All values are **strings**, even numeric ones (`"rows": 25` works because JSON allows the number, but agency / category / eligibility codes are always strings).
- `keyword` is free text against title + description. The server URL-encodes it server-side (you don't need to pre-encode).
- `oppStatuses` defaults to `posted|forecasted`. To search archived NOFOs (3+ years old), explicitly include `archived` — most NIH parent NOFOs you'll cite are in `archived` once reissued.
- `dateRange` is the *posted-date* lookback in days. Preset values: `3,7,14,21,28,35,42,49,56` (visible in `dateRangeOptions` facet). Custom day counts return empty.
- `sortBy` format is `field|direction`. Useful fields: `openDate`, `closeDate`, `title`, `agency`. Default is by relevance when `keyword` set, otherwise post date desc.

For facet values (agency codes, eligibility codes, etc.), see `references/facet-codes.md` and `references/agencies.md`.

## Pagination

| Field | Default | Max | Notes |
|---|---|---|---|
| `rows` | 25 | **1000** (effective) | Larger than 1000 returns 1000 silently |
| `startRecordNum` | 0 | no hard cap observed | 0-indexed |

The response has `hitCount` — read it first to plan. To pull everything, loop `startRecordNum += rows` until `startRecordNum >= hitCount`.

## Fetch one opportunity — full detail

The detail endpoint takes the **internal opportunity ID** (`id` from search results), not the `opportunityNumber`. They're different:

| Field | Example | Where it comes from |
|---|---|---|
| `id` | `362217` | Internal numeric ID — what `oppId=` wants |
| `opportunityNumber` | `RFA-FD-26-004` | The human-readable NOFO number |

Two ways to fetch:

```bash
# Form-encoded POST (the "fetchOpportunity" analog)
curl -sS -X POST 'https://apply07.grants.gov/grantsws/rest/opportunity/details' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data 'oppId=362217'

# GET (more convenient)
curl -sS 'https://apply07.grants.gov/grantsws/OppDetails?oppId=362217'
```

Both return the same shape. Don't send a JSON body to `/opportunity/details` — it returns `415 Unsupported Media Type`.

## Response shape — details

```
id, opportunityNumber, opportunityTitle, owningAgencyCode
opportunityCategory       → {category, description}        # D=Discretionary, M=Mandatory, etc.
synopsis                  → {synopsisDesc (HTML),
                             postingDate, responseDate, archiveDate,
                             estimatedFunding, awardCeiling, awardFloor, numberOfAwards,
                             applicantTypes[], fundingInstruments[], fundingActivityCategories[],
                             agencyContactName, agencyContactEmail, agencyContactPhone}
synopsisAttachmentFolders[] → folder + synopsisAttachments[]  # PDF NOFO documents
cfdas[]                   → CFDA program(s)
opportunityPkgs[]         → application packages (forms, deadlines)
synopsisModifiedFields[]  → audit trail of edits
forecastModifiedFields[]
synopsisHistCount         → count of historical revisions
docType                   → "synopsis" | "forecast" | "modification"
ost                       → status: POSTED | FORECASTED | CLOSED | ARCHIVED
```

`synopsis.synopsisDesc` is HTML (the announcement narrative). Strip tags or render as HTML; do not trust it to be plain text.

Dates appear in two forms: `responseDate: "Jun 15, 2026 12:00:00 AM EDT"` *and* `responseDateStr: "2026-06-15-00-00-00"`. Use the `*Str` versions when parsing — they're locale-stable.

## Quick Python helper

```python
import urllib.request, urllib.parse, json, time

SEARCH = "https://apply07.grants.gov/grantsws/rest/opportunities/search/"
DETAIL = "https://apply07.grants.gov/grantsws/rest/opportunity/details"
HDR_J  = {"Content-Type": "application/json", "User-Agent": "your-email@example.org"}
HDR_F  = {"Content-Type": "application/x-www-form-urlencoded", "User-Agent": "your-email@example.org"}

def search(criteria):
    """One page of search results."""
    req = urllib.request.Request(SEARCH, data=json.dumps(criteria).encode(), headers=HDR_J)
    return json.loads(urllib.request.urlopen(req, timeout=30).read())

def search_all(criteria, page=200, sleep=1.1):
    """Paginate everything."""
    out, off = [], 0
    while True:
        body = {**criteria, "rows": page, "startRecordNum": off}
        d = search(body)
        out.extend(d["oppHits"])
        total = d["hitCount"]
        off += page
        if off >= total: break
        time.sleep(sleep)
    return out, total

def fetch(opp_id):
    """Full details for one opportunity (by internal numeric id)."""
    req = urllib.request.Request(DETAIL,
        data=urllib.parse.urlencode({"oppId": opp_id}).encode(),
        headers=HDR_F)
    return json.loads(urllib.request.urlopen(req, timeout=30).read())
```

## Common patterns

### Active NIH opportunities matching a topic
```json
{"keyword": "tumor atlas", "oppStatuses": "posted|forecasted", "agencies": "HHS-NIH11"}
```

### NCI specifically (sub-agency code)
NIH sub-IC codes are pipe-suffixed on `HHS-NIH`. NCI is `HHS-NIH11`. Full list in `references/agencies.md`. To search across multiple ICs:
```json
{"agencies": "HHS-NIH11|HHS-NIH09|HHS-NIH17"}
```

### NOFOs closing in the next 30 days
The API has no native `closeDate` filter. Pull `oppStatuses: "posted"`, then filter client-side on `responseDateStr`.

### Find by exact opportunity number
```json
{"oppNum": "PAR-25-242", "oppStatuses": "posted|forecasted|closed|archived"}
```
A reissued NOFO with the same number can appear multiple times across history — include all statuses to find the most recent.

### CFDA-scoped search
CFDA 93.393 = NCI Cancer Cause and Prevention Research; 93.395 = NCI Cancer Treatment Research; 93.397 = NCI Cancer Centers Support. Full crosswalk in `references/cfda-nih.md` (NIH only).
```json
{"cfda": "93.395", "oppStatuses": "posted"}
```

### Competing revision NOFOs
The Parent Revision NOFOs (PA-25-242 etc.) are searchable like any other:
```json
{"keyword": "revision applications", "agencies": "HHS-NIH11", "oppStatuses": "posted"}
```

## Gotchas

- **`www.grants.gov/api/common/search2` is an HTML page, not the API.** Use `apply07.grants.gov/grantsws/rest/opportunities/search/`.
- **The detail endpoint takes `oppId` (internal), not `opportunityNumber` (human-readable).** If you only have the NOFO number, search first to resolve it to an `id`.
- **Multi-value filters use `|`, not `,`.** A comma is treated as part of the value.
- **`oppStatuses` defaults to `posted|forecasted`.** To find a closed/archived NOFO (most parent NOFOs are archived), pass it explicitly.
- **Don't send JSON to `/opportunity/details`** — it requires `application/x-www-form-urlencoded`. JSON returns 415.
- **`synopsisDesc` is HTML**, not plain text. Render or strip before display.
- **Date strings have two formats** in the response; prefer the `*Str` (e.g., `responseDateStr`) versions.
- **Total max page size is ~1000 rows** despite no documented cap — larger values silently truncate.
- **The frontend at grants.gov shows extra fields** (subagency drill-downs, attachment previews) that come from secondary endpoints. The two endpoints above cover most needs but not full feature parity with the website.

## Reference sheets

Lookup tables for facet codes live in `references/`:

- `references/facet-codes.md` — `oppStatuses`, `fundingInstruments`, `fundingCategories`, `eligibilities` value codes
- `references/agencies.md` — top-level agency codes (HHS, DOD, NSF, etc.) and HHS sub-agency codes (NIH ICs, FDA, CDC, HRSA, AHRQ)
- `references/cfda-nih.md` — Assistance Listing (CFDA) numbers for NIH/HHS programs
- `references/recipes.md` — Sage-aligned query recipes: DCCs, data infrastructure, atlases, omics, AI/digital twins/synthetic data, privacy/governance, and disease-area sweeps (cancer, neurodegeneration, rare disease). **Critical workflow note: title-pattern filtering after broad agency pulls outperforms the `keyword` field, which is too loose.** Includes a pre-clinical scope filter (Sage doesn't run clinical trials).

## Why keyword search underperforms

The `keyword` field OR-matches terms across the full description. A query like `keyword: "data resource"` returns ~700 hits — most are irrelevant because they happen to contain the words "data" or "resource" in a methods paragraph.

**The pattern that works** (documented in `references/recipes.md`):
1. Pull *all* posted/forecasted opportunities for target agencies (~1,000 records, well under any limit)
2. Apply a curated regex set against **titles only** (titles are short and signal-dense)
3. Apply a negative filter to drop fellowships, training grants, SBIR, conferences, etc.
4. Score and rank

This surfaces ~50–80 high-relevance candidates from the ~1,000 total, vs the keyword-search ~700 mostly-irrelevant hits.

## Public opportunity page

Each opportunity has a stable URL:
```
https://www.grants.gov/search-results-detail/<id>
```
Use this in summaries and citations — it's user-facing and survives forever (even for archived NOFOs).
