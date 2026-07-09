#!/usr/bin/env python3
"""Regenerate rb_overrides.csv: the authoritative GoBricks->Rebrickable id for the
GoBricks parts that map to several LEGO ids (mould revisions / renumbers / prints).

The conversion table alone can't tell which LEGO id is the *current* Rebrickable
part, so we ask Rebrickable's API: the current part is the one still in production
(year_to = current year); ties are broken by the "primary hub" part (most mould +
alternate links), then the lowest/original number, then the newest mould letter.

Run occasionally (needs network); results are cached in rb_part_cache.json so it is
resumable and fast on re-runs. Then run gen_data.py to fold the result into data.js.
"""
import csv, re, collections, json, os, subprocess, time

BRICK_LIB = "/Users/wagenblast/develop/brick-lib/assets"
HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(HERE, "rb_part_cache.json")
OUT = os.path.join(HERE, "rb_overrides.csv")


def _api_key():
    """Rebrickable key from $REBRICKABLE_API_KEY, else reused from brick-lib's
    request.dart (avoids hardcoding a credential in this file)."""
    k = os.environ.get("REBRICKABLE_API_KEY")
    if k:
        return k
    try:
        src = open("/Users/wagenblast/develop/brick-lib/lib/request/request.dart").read()
        m = re.search(r'RB_API_KEY\s*=\s*"([^"]+)"', src)
        if m:
            return m.group(1)
    except OSError:
        pass
    raise SystemExit("Set REBRICKABLE_API_KEY (or ensure brick-lib is checked out).")


RB_API_KEY = _api_key()

# --- candidates: LEGO ids of GoBricks parts that map to more than one ------------
groups = collections.defaultdict(list)
with open(os.path.join(BRICK_LIB, "gobrick_conversion_table.csv"), newline="") as f:
    for row in csv.reader(f):
        if len(row) >= 2 and row[0].strip() and row[1].strip():
            groups[row[1].strip().upper()].append(row[0].strip())
multi = {g: ps for g, ps in groups.items() if len(ps) > 1}
candidates = sorted({p for ps in multi.values() for p in ps})

# --- fetch part details from Rebrickable (cached, resumable) ---------------------
cache = json.load(open(CACHE)) if os.path.exists(CACHE) else {}

def fetch(part):
    url = f"https://rebrickable.com/api/v3/lego/parts/{part}/"
    for attempt in range(6):
        out = subprocess.run(
            ["curl", "-sL", "--max-time", "25", "-w", "\n%{http_code}",
             "-H", f"Authorization: key {RB_API_KEY}", url],
            capture_output=True, text=True).stdout
        body, _, code = out.rpartition("\n")
        if code == "200":
            d = json.loads(body)
            return {"yto": d.get("year_to") or 0, "yfrom": d.get("year_from") or 0,
                    "ma": len(d.get("molds") or []) + len(d.get("alternates") or [])}
        if code == "404":
            return {"missing": True}
        time.sleep(2 * (attempt + 1))
    return None

todo = [p for p in candidates if p not in cache]
for i, p in enumerate(todo):
    v = fetch(p)
    if v is not None:
        cache[p] = v
    if i % 20 == 0:
        json.dump(cache, open(CACHE, "w"))
        print(f"  fetched {i}/{len(todo)}")
    time.sleep(0.6)
json.dump(cache, open(CACHE, "w"))

# --- resolve each group ----------------------------------------------------------
_PRINTED = re.compile(r"^(\d+[a-z]?)(p[a-z]*\d.*)$")

def base(p):
    return int(re.match(r"\d+", p).group())

def letter_rank(p):
    m = re.fullmatch(r"\d+([a-z])", p)
    return ord(m.group(1)) - 96 if m else 0

def rank(p):
    c = cache.get(p, {})
    # reverse=True: current part (year_to); non-printed; primary hub (molds+alts);
    # lowest original number; newest mould letter; newest design.
    return (c.get("yto", 0), not _PRINTED.match(p), c.get("ma", 0),
            -base(p), letter_rank(p), c.get("yfrom", 0), len(p), p)

def usable(p):
    return p in cache and not cache[p].get("missing")

resolved = {}
for g, ps in multi.items():
    ex = [p for p in ps if usable(p)]
    if ex:
        resolved[g] = sorted(ex, key=rank, reverse=True)[0]

with open(OUT, "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["gds", "rb"])
    for g in sorted(resolved):
        w.writerow([g, resolved[g]])
print(f"wrote {len(resolved)} overrides to {OUT}")
