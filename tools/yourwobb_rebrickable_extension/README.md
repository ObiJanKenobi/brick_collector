# yourwobb → Rebrickable CSV (Chrome extension)

Scans a [yourwobb.com](https://www.yourwobb.com) GoBricks **cart / checkout** page,
converts the GoBricks parts and colours to Rebrickable part & colour IDs, and
downloads a Rebrickable-importable CSV (`Part,Color,Quantity`).

Everything is offline — no API calls. The GoBricks→Rebrickable part map and the
colour map are baked into `data.js`, generated from `brick-lib`'s conversion
tables.

## Install (unpacked)

1. Open `chrome://extensions`.
2. Enable **Developer mode** (top-right).
3. Click **Load unpacked** and select this folder
   (`tools/yourwobb_rebrickable_extension`).
4. Pin the extension if you like.

## Use

1. Go to your yourwobb **cart** or **checkout** page so the item list is visible.
2. Click the extension icon → **Scan cart**.
3. Review the preview: pieces total, how many parts mapped, and any warnings.
4. Click **Download CSV** (or **Copy CSV**).
5. In Rebrickable: *My Parts / Part Lists → Add/Upload → paste or upload the CSV*.

## How it maps things

- **Part** — the SKU on each row is `GDS-<code>-<colorSuffix>` (e.g. `GDS-90531-040`).
  The `GDS-<code>` is looked up in `GDS_TO_RB`. When a GoBricks number maps to
  several Rebrickable mould variants (`48729` / `48729a` / `48729b`), the base
  number is used.
- **Colour** — the row's `Color: <Name> <id>` line carries the **LEGO** colour id;
  it's mapped via `LEGO_COLOR_TO_RB`, falling back to the colour name, then to
  `9999` (Any Color) if unknown.
- **Quantity** — the page badge caps at `99+`, so exact counts are read from the
  page's cart object (`_GET_C_SETTING_('cart').items`, matched to rows by order).
  If that can't be read, a `99+` row defaults to 100 and is flagged.

## Warnings you may see

- **Part not in the GoBricks table** — that row is *not* written to the CSV
  (listed so you can add it in Rebrickable manually).
- **Colour not recognised** — exported as `9999` (Any Color).
- **Quantity showed "99+"** and couldn't be recovered — defaulted to 100; verify it.

Use **Copy debug info** (bottom link) to copy the raw scrape result to the
clipboard — handy if yourwobb changes their markup and a scan comes back empty.

## Files

| File | Purpose |
|------|---------|
| `manifest.json` | MV3 manifest (permissions: `scripting`, `activeTab`, `downloads`; host: yourwobb.com) |
| `popup.html` / `popup.js` | UI, the in-page scraper, conversion, CSV download |
| `data.js` | **Generated** lookup tables (do not hand-edit) |
| `gen_data.py` | Regenerates `data.js` from `brick-lib/assets/*.csv` |

## Regenerating the data

If `brick-lib`'s conversion tables change:

```bash
python3 gen_data.py    # reads /Users/wagenblast/develop/brick-lib/assets/*.csv
```
