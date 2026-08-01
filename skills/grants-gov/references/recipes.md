# Grants.gov — Recipes for Sage-Aligned Searches

Copy-paste payloads and end-to-end workflows for the funding lanes Sage Bionetworks tracks: data sharing, data infrastructure, privacy / governance, atlasing, DCC roles, omics, and AI / digital twins / synthetic data in cancer, neurodegeneration, and rare disease.

**Scope assumption: Sage works in pre-clinical space.** The default negative filter below excludes any NOFO requiring a clinical trial ("Clinical Trial Required") and pure Clinical Coordinating Center roles. Data Coordinating Centers attached to clinical trials are still excluded by this filter — if Sage decides to pursue trial-attached DCC work, drop `Clinical Trial Required` and `Clinical Coordinating Center` from `NEGATIVE`.

---

## The `keyword` field is too loose — use title-pattern filtering instead

The `keyword` parameter does OR-matching of terms against title **and** description. A query like `keyword: "data resource"` returns ~700 hits because it matches anything mentioning *data* OR *resource* anywhere in the body. This is useless for surfacing actual DCC / data-infrastructure NOFOs.

**Workaround that actually works:**

1. Pull *every* posted/forecasted opportunity for your target agencies (a few hundred records, well under any limit).
2. Apply a curated regex set to the **title only** (titles are short and signal-dense).
3. Apply a negative filter to drop training / fellowship / SBIR / equipment / conference mechanisms that titles falsely match.
4. Score and rank by signal strength.

This pattern is durable across all the Sage-relevant lanes below.

---

## Workflow boilerplate (reuse across recipes)

```python
import urllib.request, urllib.parse, json, time, re
from collections import OrderedDict

SEARCH = "https://apply07.grants.gov/grantsws/rest/opportunities/search/"
DETAIL = "https://apply07.grants.gov/grantsws/rest/opportunity/details"
HDR_J  = {"Content-Type":"application/json", "User-Agent":"adam.taylor@sagebase.org"}
HDR_F  = {"Content-Type":"application/x-www-form-urlencoded", "User-Agent":"adam.taylor@sagebase.org"}

def search(criteria):
    req = urllib.request.Request(SEARCH, data=json.dumps(criteria).encode(), headers=HDR_J)
    return json.loads(urllib.request.urlopen(req, timeout=30).read())

def fetch(oid):
    req = urllib.request.Request(DETAIL,
        data=urllib.parse.urlencode({"oppId": oid}).encode(), headers=HDR_F)
    return json.loads(urllib.request.urlopen(req, timeout=30).read())

# Agencies Sage cares about — keep this list updated
SAGE_AGENCIES = [
    "HHS-NIH11",         # all NIH (NCI, NIA, NHGRI, NLM, NIBIB, etc.)
    "HHS-FDA",
    "HHS-CDC", "HHS-CDC-NCCDPHP", "HHS-CDC-NCIPC",
    "HHS-AHRQ", "HHS-HRSA",
    "NSF",               # cyberinfrastructure, FAIR
    "DOD-AMRAA",         # CDMRP — disease-specific programs (PCRP, BCRP, KCRP)
    "ARPAH",             # AI / breakthrough health
]

def pull_all(statuses="posted"):
    """Pull every opportunity across SAGE_AGENCIES at given statuses."""
    out = OrderedDict()
    for ag in SAGE_AGENCIES:
        off = 0
        while True:
            d = search({"agencies": ag, "oppStatuses": statuses, "rows": 200, "startRecordNum": off})
            for h in d['oppHits']:
                out[h['id']] = h
            off += 200
            if off >= d['hitCount']: break
            time.sleep(1.1)
        time.sleep(1.1)
    return out

# Negative filter — drop these regardless of title match
# Sage operates in pre-clinical space — exclude clinical-trial-required NOFOs
# ("Clinical Trial Optional" is borderline; "Clinical Trial Not Allowed" is the strongest fit)
NEGATIVE = re.compile(
    r'\b(career development|fellowship|F3\d|K0[0-9]|K2[0-9]|K23|K99'
    r'|training program|small business|SBIR|STTR|career transition'
    r'|loan repayment|prize challenge|conference grant|R13|R25'
    r'|equipment|construction|mentored|institutional research training'
    r'|summer institute|short course'
    r'|Clinical Trial Required'                # pre-clinical scope only
    r'|Clinical Coordinating Center'           # CCs run the trial; we don't
    r')\b', re.I)

# Optional secondary filter — if you also want to drop CT-Optional NOFOs,
# uncomment this and apply after NEGATIVE.
# CT_OPTIONAL = re.compile(r'\bClinical Trial Optional\b', re.I)

def filter_titles(all_hits, patterns, scorer=None):
    """Apply title regex set, drop negatives, optionally score."""
    out = []
    pats = [(re.compile(p, re.I), tag) for p, tag in patterns]
    for h in all_hits.values():
        title = h.get('title','')
        if NEGATIVE.search(title): continue
        tags = [t for r,t in pats if r.search(title)]
        if tags:
            out.append((h, tags))
    if scorer:
        out.sort(key=lambda m: -scorer(m))
    return out

def render(matches, n=30):
    for h, tags in matches[:n]:
        print(f"{h.get('oppStatus','?'):10} {h['number']:18} close={h.get('closeDate','?'):11}"
              f"  tags={','.join(tags)}")
        print(f"   {h['title'][:110]}")
        print(f"   https://www.grants.gov/search-results-detail/{h['id']}")
```

---

## Recipe — DCCs and coordinating centers

The most direct Sage-fit mechanism. Use `posted` for active, `posted|forecasted` for planning.

```python
DCC_PATTERNS = [
    (r'\bdata coordinating center\b', 'DCC'),
    (r'\bcoordinating center\b', 'CC'),
    (r'\bdata.{0,20}coordinat', 'data-coord'),
    (r'\bdata management.{0,20}(center|unit|core)\b', 'data-mgmt-core'),
    (r'\bnetwork.{0,20}coordinat', 'net-coord'),
    (r'\bconsortium.{0,20}coordinat', 'cons-coord'),
    (r'\bbiostatistics.{0,20}(center|unit|core)\b', 'biostat-core'),
    (r'\bmulti[- ]?site\b', 'multi-site'),
]
def dcc_score(m):
    h, tags = m
    return 100*('DCC' in tags) + 50*('CC' in tags) + 30*('data-coord' in tags) + 20*('net-coord' in tags)

hits = pull_all("posted")
matches = filter_titles(hits, DCC_PATTERNS, dcc_score)
render(matches, 30)
```

**Known hits this surfaces (as of mid-2026):** PAR-27-013 (trans-NIH DCC U24), PAR-24-276/313 (NCCIH DCCs), PAR-23-204 (NEI vision CC), PAR-27-012 (clinical CC sister to PAR-27-013).

---

## Recipe — Data infrastructure, knowledge portals, atlases, commons

Sage's bread-and-butter beyond pure DCC roles.

```python
DATA_INFRA_PATTERNS = [
    (r'\bknowledge ?portal\b', 'portal'),
    (r'\bknowledge ?base\b', 'kbase'),
    (r'\bdata commons\b', 'commons'),
    (r'\bdata ecosystem\b', 'ecosystem'),
    (r'\bdata hub\b', 'hub'),
    (r'\bdata platform\b', 'platform'),
    (r'\bdata infrastructure\b', 'infra'),
    (r'\bdata resource\b', 'resource'),       # title-anchored, so less noisy than keyword
    (r'\bbiomedical data repository\b', 'biorepo'),
    (r'\bdata repository\b', 'repository'),
    (r'\bcyberinfrastructure\b', 'cyber-infra'),
    (r'\bdata generation.{0,20}(center|resource)\b', 'data-gen'),
    (r'\bresource (center|program|network)\b', 'resource-ctr'),
    (r'\b(P41)\b', 'P41'),                    # NIH resource grant mechanism
    (r'\batlas\b', 'atlas'),
    (r'\bcell atlas\b', 'cell-atlas'),
    (r'\btumor atlas\b', 'tumor-atlas'),
    (r'\bbrain atlas\b', 'brain-atlas'),
]
def infra_score(m):
    h, tags = m
    s = 0
    for tag, w in [('portal',40),('commons',40),('infra',35),('platform',30),
                   ('ecosystem',30),('atlas',25),('cell-atlas',35),('tumor-atlas',35),
                   ('resource-ctr',25),('P41',25),('biorepo',25),('repository',20)]:
        if tag in tags: s += w
    return s

matches = filter_titles(pull_all("posted|forecasted"), DATA_INFRA_PATTERNS, infra_score)
render(matches)
```

---

## Recipe — Privacy, governance, data sharing policy

Less commonly funded but Sage participates in shaping. NLM, NHGRI, ELSI, NIH OD are the usual sources.

```python
PRIVACY_GOV_PATTERNS = [
    (r'\bprivacy\b', 'privacy'),
    (r'\bELSI\b', 'ELSI'),
    (r'\bethical.{0,30}(legal|social)', 'ELSI-fulltext'),
    (r'\bdata governance\b', 'governance'),
    (r'\bconsent\b', 'consent'),
    (r'\bdata access\b', 'data-access'),
    (r'\bdata sharing.{0,30}(policy|practice|standard)', 'sharing-policy'),
    (r'\bsecure data\b', 'secure'),
    (r'\bcybersecurity\b', 'cyber-sec'),
    (r'\bdata stewardship\b', 'stewardship'),
    (r'\bbroad consent\b', 'broad-consent'),
    (r'\bdifferential privacy\b', 'diff-privacy'),
    (r'\bfederated.{0,20}(learning|analysis|data)', 'federated'),
]
matches = filter_titles(pull_all("posted|forecasted"), PRIVACY_GOV_PATTERNS)
render(matches)
```

---

## Recipe — Omics

Single-cell, spatial, multi-omics, integration.

```python
OMICS_PATTERNS = [
    (r'\bsingle[- ]?cell\b', 'sc'),
    (r'\bspatial.{0,20}(omics|transcriptomic)', 'spatial'),
    (r'\bspatial transcriptomic', 'spatial-tx'),
    (r'\bmulti[- ]?omic', 'multi-omics'),
    (r'\bgenomic', 'genomic'),
    (r'\bproteomic', 'proteomic'),
    (r'\btranscriptomic', 'transcriptomic'),
    (r'\bepigenomic', 'epigenomic'),
    (r'\bmetabolomic', 'metabolomic'),
    (r'\bmicrobiom', 'microbiome'),
    (r'\b(scRNA|snRNA|CITE-seq)\b', 'sc-method'),
    (r'\bbiomarker.{0,20}discover', 'biomarker'),
]
matches = filter_titles(pull_all("posted|forecasted"), OMICS_PATTERNS)
render(matches)
```

---

## Recipe — AI / ML / digital twins / synthetic data in life science

The frontier lane — fast-growing.

```python
AI_LIFESCI_PATTERNS = [
    (r'\bartificial intelligence\b', 'AI'),
    (r'\bmachine learning\b', 'ML'),
    (r'\bAI/ML\b', 'AI/ML'),
    (r'\bdeep learning\b', 'DL'),
    (r'\bfoundation model\b', 'foundation-model'),
    (r'\bdigital twin\b', 'digital-twin'),
    (r'\bdigital twins\b', 'digital-twins'),
    (r'\bin silico\b', 'in-silico'),
    (r'\bsynthetic data\b', 'synthetic-data'),
    (r'\bgenerative.{0,15}(model|AI)\b', 'genai'),
    (r'\bcomputational model\b', 'compute-model'),
    (r'\bbridge to AI\b', 'bridge2AI'),
    (r'\bnatural language processing\b', 'NLP'),
    (r'\b(predictive|prediction) (model|algorithm)\b', 'predictive'),
]
matches = filter_titles(pull_all("posted|forecasted"), AI_LIFESCI_PATTERNS)
render(matches)
```

ARPAH (`agencies: "ARPAH"`) is worth a separate sweep — it's the breakthrough-health analog of DARPA and currently lists few opportunities, but they're high-ceiling and AI-heavy.

---

## Recipe — Cancer (Sage's NCI portfolio)

Use CFDA filtering since `HHS-NIH11` lumps all of NIH.

```python
NCI_CFDAS = ["93.393","93.394","93.395","93.396","93.397","93.398","93.399"]
nci_hits = OrderedDict()
for cfda in NCI_CFDAS:
    off = 0
    while True:
        d = search({"cfda": cfda, "oppStatuses": "posted|forecasted",
                    "rows": 200, "startRecordNum": off})
        for h in d['oppHits']:
            nci_hits[h['id']] = h
        off += 200
        if off >= d['hitCount']: break
        time.sleep(1.1)
    time.sleep(1.1)
print(f"NCI hits: {len(nci_hits)}")
```

Then layer the DCC/data-infra/omics title patterns on top to surface the data-related subset. NCI cancer atlas / data ecosystem RFAs (Cancer Moonshot, HTAN successors) typically appear under 93.395 or 93.396.

---

## Recipe — Neurodegeneration (AD/ADRD, PD, FTD)

```python
NEURO_CFDAS = [
    "93.866",   # NIA (aging, AD/ADRD primary)
    "93.853",   # NINDS (Parkinson's, stroke, FTD)
    "93.242",   # NIMH (some overlap with neurodegeneration via biomarkers)
    "93.173",   # NIDCD (auditory in aging)
]
neuro_hits = OrderedDict()
for cfda in NEURO_CFDAS:
    off = 0
    while True:
        d = search({"cfda": cfda, "oppStatuses": "posted|forecasted",
                    "rows": 200, "startRecordNum": off})
        for h in d['oppHits']:
            neuro_hits[h['id']] = h
        off += 200
        if off >= d['hitCount']: break
        time.sleep(1.1)
    time.sleep(1.1)
matches = filter_titles(neuro_hits, DATA_INFRA_PATTERNS + DCC_PATTERNS + OMICS_PATTERNS + AI_LIFESCI_PATTERNS)
render(matches)
```

The AD Knowledge Portal angle hits hardest under CFDA 93.866 (NIA). FTD and PD work shows up under 93.853 (NINDS).

---

## Recipe — Rare disease

Rare-disease NOFOs cluster at NCATS (rare-disease coordinating role) and at IC-specific RFAs.

```python
RARE_DISEASE_CFDAS = [
    "93.350",   # NCATS — Office of Rare Diseases Research lives here
]
RARE_PATTERNS = [
    (r'\brare disease', 'rare-disease'),
    (r'\bRDCRN\b', 'RDCRN'),
    (r'\bundiagnosed', 'undiagnosed'),
    (r'\bn[- ]?of[- ]?1', 'n-of-1'),
    (r'\bnatural history\b', 'nat-history'),
    (r'\borphan\b', 'orphan'),
    (r'\bgene therapy.{0,30}rare', 'rare-gtx'),
]
# Two passes: (1) NCATS CFDA scope, (2) any title containing rare-disease language
rare_hits = OrderedDict()
off = 0
while True:
    d = search({"cfda": "93.350", "oppStatuses": "posted|forecasted",
                "rows": 200, "startRecordNum": off})
    for h in d['oppHits']: rare_hits[h['id']] = h
    off += 200
    if off >= d['hitCount']: break
    time.sleep(1.1)
# Add cross-IC title matches
all_h = pull_all("posted|forecasted")
for h, _ in filter_titles(all_h, RARE_PATTERNS):
    rare_hits[h['id']] = h
print(f"Rare disease candidates: {len(rare_hits)}")
```

---

## Recipe — Forecasted opportunities (advance planning)

Sage's grant calendar runs ~9 months ahead. Forecasted NOFOs give the longest lead time.

```python
forecasted = pull_all("forecasted")
matches = filter_titles(forecasted, DCC_PATTERNS + DATA_INFRA_PATTERNS, dcc_score)
# Sort by expected post date if present (synopsis only — most forecasts hide this)
for h, tags in matches[:40]:
    print(f"{h['number']:18}  {h['title'][:90]}")
```

Forecasted records carry less metadata than posted ones. To get the expected publication window, hit `fetch(oid)` and read `synopsis.estimatedSynopsisPostDate` if populated, or read `synopsis.synopsisDesc` for "anticipated FY26 Q3" style hints.

---

## Recipe — Combined Sage sweep (everything above, deduped)

For a quarterly "what should we apply for" review:

```python
ALL_PATTERNS = (
    DCC_PATTERNS + DATA_INFRA_PATTERNS + PRIVACY_GOV_PATTERNS
    + OMICS_PATTERNS + AI_LIFESCI_PATTERNS + RARE_PATTERNS
)

hits = pull_all("posted|forecasted")
matches = filter_titles(hits, ALL_PATTERNS)

# Group by status, sort each by score
def combined_score(m):
    return dcc_score(m) + infra_score(m)
matches.sort(key=lambda m: -combined_score(m))

for h, tags in matches[:50]:
    badge = "POSTED " if h.get('oppStatus')=='posted' else "FORECAST"
    print(f"{badge} {h['number']:18}  close={h.get('closeDate','?'):11}  tags={','.join(tags[:3])}")
    print(f"   {h['title'][:100]}")
```

---

## Notes on filter quality

- **Title regexes outperform keyword search ~10×** for surfacing relevant NOFOs (in one run: keyword returned 700+ hits per term and was useless; title regex returned 66 candidates with ~80% relevance after negative filtering).
- **NIH IC granularity comes from CFDA**, not the agencies field. Build `cfda` queries when you need to slice by IC; build agency-wide pulls when you need cross-IC pattern surveys.
- **Forecasted records are sparse on detail** — `fetch(oid)` often returns just title and high-level scope. Treat them as alerts to track, not actionable proposals.
- **Reissued NOFOs** (e.g., the trans-NIH DCC moved from PAR-24-XXX → PAR-27-013) live as separate entries — the older one becomes `archived` or `closed`. Always pull both statuses if you want history.
- **The `cfdaList` on search hits is shorter than `cfdas[]` on the detail record.** If you need the full CFDA set, fetch the detail.
