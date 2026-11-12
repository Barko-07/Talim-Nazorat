"""Give every font in a Flutter web build a content-hashed file name.

Flutter trims icon fonts to the icons in use at each build, but keeps the file
name (e.g. lucide.ttf). A browser that cached an older font keeps showing it
with new code, so a newly used icon is blank. Renaming each font to
<name>.<hash>.<ext> and pointing FontManifest.json at the new name makes every
build fetch its own fonts. The original files stay, so nothing breaks for a
page that is still running the previous build.

Usage: python tool/version_fonts.py build/web_server
"""
import hashlib
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
manifest_path = root / "assets" / "FontManifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
renamed = 0
for family in manifest:
    for font in family["fonts"]:
        rel = font["asset"]
        src = root / "assets" / rel
        if not src.is_file():
            continue
        digest = hashlib.sha256(src.read_bytes()).hexdigest()[:10]
        new_rel = f"{rel.rsplit('.', 1)[0]}.{digest}.{rel.rsplit('.', 1)[1]}"
        (root / "assets" / new_rel).write_bytes(src.read_bytes())
        font["asset"] = new_rel
        renamed += 1
manifest_path.write_text(json.dumps(manifest, separators=(",", ":")), encoding="utf-8")
print(f"fonts versioned: {renamed}")
