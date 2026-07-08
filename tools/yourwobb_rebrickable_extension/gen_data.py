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

def pick_base(parts):
    """Prefer a pure-numeric id (mold base, e.g. 48729 over 48729a); else shortest, then lexicographic."""
    pure = [p for p in parts if re.fullmatch(r"\d+", p)]
    pool = pure if pure else parts
    return sorted(pool, key=lambda p: (len(p), p))[0]

gds_to_rb = {gds: pick_base(parts) for gds, parts in gds_to_rb_all.items()}

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
