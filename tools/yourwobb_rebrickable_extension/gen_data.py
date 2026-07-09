#!/usr/bin/env python3
"""Generate data.js for the yourwobb->Rebrickable Chrome extension from brick-lib CSVs."""
import csv, json, os, re, collections

BRICK_LIB = "/Users/wagenblast/develop/brick-lib/assets"
OUT_DIR = "/Users/wagenblast/develop/brick_collector/tools/yourwobb_rebrickable_extension"
os.makedirs(OUT_DIR, exist_ok=True)

# --- GoBricks part -> Rebrickable part (invert the conversion table) ---------
gds_to_rb_all = collections.defaultdict(list)
with open(os.path.join(BRICK_LIB, "gobrick_conversion_table.csv"), newline="") as f:
    for row in csv.reader(f):
        if len(row) < 2:
            continue
        rb, gds = row[0].strip(), row[1].strip()
        if not rb or not gds:
            continue
        gds_to_rb_all[gds.upper()].append(rb)

# A "plain" part is digits + an optional single mould letter (3069, 3069b). A
# printed/patterned part embeds its base then a print token (3069bpb0856,
# 3070pb089); the second group makes sure the token's leading "p" is not read as
# a mould letter.
_PLAIN = re.compile(r"^\d+[a-z]?$")
_PRINTED = re.compile(r"^(\d+[a-z]?)(p[a-z]*\d.*)$")


def pick_base(parts):
    """Pick the canonical Rebrickable id among the LEGO ids that map to one
    GoBricks part. Printed/patterned variants are printed on the *current* mould,
    so their base is the best answer (e.g. 3069bpb0856 -> 3069b, not the
    deprecated 3069). Falls back to the pure-numeric mould base when there is no
    printed variant to learn the current mould from."""
    plains = [p for p in parts if _PLAIN.match(p)]
    bases = collections.Counter(
        m.group(1) for p in parts if (m := _PRINTED.match(p)))
    for base, _ in bases.most_common():
        if base in plains:
            return base
    if bases:
        return bases.most_common(1)[0][0]
    pure = [p for p in plains if p.isdigit()]
    pool = pure if pure else (plains if plains else parts)
    return sorted(pool, key=lambda p: (len(p), p))[0]

# Authoritative overrides for GoBricks parts that map to several LEGO ids. The
# conversion table alone can't say which variant is the *current* Rebrickable
# part (e.g. GDS-866 -> 2453b not 2453; GDS-540 -> 3003 not 6223), so rb_overrides.csv
# was resolved from Rebrickable's part data (year_to for the current mould, plus
# mould/alternate relationships). Regenerate it with resolve_overrides.py if the
# conversion table changes; anything not listed falls back to pick_base().
overrides = {}
_ov_path = os.path.join(OUT_DIR, "rb_overrides.csv")
if os.path.exists(_ov_path):
    with open(_ov_path, newline="") as f:
        _r = csv.reader(f); next(_r, None)
        for row in _r:
            if len(row) >= 2 and row[0].strip():
                overrides[row[0].strip().upper()] = row[1].strip()

gds_to_rb = {gds: overrides.get(gds) or pick_base(parts)
             for gds, parts in gds_to_rb_all.items()}
print(f"GDS overrides applied: {sum(1 for g in gds_to_rb_all if g in overrides)}")

# --- Colors ------------------------------------------------------------------
# Columns: LEGO,Bricklink,Rebrickable,Gobricks,LDD Name,Name,RGB
lego_color_to_rb = {}       # LEGO color id -> rebrickable color id (yourwobb shows the LEGO id)
gobricks_color_to_rb = {}   # gobricks color id -> rebrickable color id
name_to_rb = {}             # lowercased color name -> rebrickable color id
rb_meta = {}                # rebrickable id -> {name, rgb}

with open(os.path.join(BRICK_LIB, "color_table.csv"), newline="") as f:
    reader = csv.reader(f)
    next(reader, None)  # header
    for row in reader:
        if len(row) < 7:
            continue
        lego, bl, rb, gob, ldd, name, rgb = (c.strip() for c in row[:7])
        if not rb:
            continue
        rb_meta.setdefault(rb, {"name": name, "rgb": rgb})
        # LEGO color id (numeric only) — this is what appears in the cart's
        # "Color: <Name> <id>" line, so it's the primary lookup.
        if re.fullmatch(r"\d+", lego):
            lego_color_to_rb.setdefault(lego, rb)
        # GoBricks color id (numeric only; skip blanks and "xxx")
        if re.fullmatch(r"\d+", gob):
            gobricks_color_to_rb.setdefault(gob, rb)
        # Name-based lookup (both the short "Name" and the LDD name), first wins
        for n in (name, ldd):
            key = n.strip().lower()
            if key:
                name_to_rb.setdefault(key, rb)

banner = "// AUTO-GENERATED from brick-lib/assets/*.csv by gen_data.py. Do not edit by hand.\n"
with open(os.path.join(OUT_DIR, "data.js"), "w") as f:
    f.write(banner)
    f.write("const GDS_TO_RB = " + json.dumps(gds_to_rb, ensure_ascii=False, sort_keys=True) + ";\n")
    f.write("const LEGO_COLOR_TO_RB = " + json.dumps(lego_color_to_rb, ensure_ascii=False, sort_keys=True) + ";\n")
    f.write("const GOBRICKS_COLOR_TO_RB = " + json.dumps(gobricks_color_to_rb, ensure_ascii=False, sort_keys=True) + ";\n")
    f.write("const NAME_TO_RB = " + json.dumps(name_to_rb, ensure_ascii=False, sort_keys=True) + ";\n")
    f.write("const RB_COLOR_META = " + json.dumps(rb_meta, ensure_ascii=False, sort_keys=True) + ";\n")

print(f"GDS entries: {len(gds_to_rb)} (of {len(gds_to_rb_all)} unique GDS; {sum(1 for v in gds_to_rb_all.values() if len(v) > 1)} had multiple mold variants)")
print(f"LEGO-color entries: {len(lego_color_to_rb)}")
print(f"GoBricks-color entries: {len(gobricks_color_to_rb)}")
print(f"Name entries: {len(name_to_rb)}")
print(f"Rebrickable color meta: {len(rb_meta)}")
