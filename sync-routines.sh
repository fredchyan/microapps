#!/bin/bash
# Reads Obsidian Routines/*.md → generates routinery/routines.json
# Run this whenever routines change, or via cron

VAULT_DIR="${1:-/Users/mochi/Matcha/Routines}"
OUT_DIR="$(dirname "$0")/routinery"
OUT_FILE="$OUT_DIR/routines.json"

mkdir -p "$OUT_DIR"

python3 << 'PYEOF'
import os, json, re, sys, glob

vault = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("VAULT_DIR", "/Users/mochi/Matcha/Routines")
out = sys.argv[2] if len(sys.argv) > 2 else os.environ.get("OUT_FILE", "routinery/routines.json")

routines = []
for fp in sorted(glob.glob(os.path.join(vault, "*.md"))):
    with open(fp) as f:
        text = f.read()
    
    # Parse frontmatter
    fm = {}
    if text.startswith("---"):
        end = text.index("---", 3)
        for line in text[3:end].strip().split("\n"):
            if ":" in line:
                k, v = line.split(":", 1)
                fm[k.strip()] = v.strip().strip('"')
        text = text[end+3:]
    
    # Parse steps
    steps = []
    for line in text.strip().split("\n"):
        line = line.strip()
        if not line.startswith("- "):
            continue
        line = line[2:]
        parts = [p.strip() for p in line.split("|")]
        name = parts[0]
        mins = 1
        if len(parts) > 1:
            m = re.match(r"(\d+)", parts[1])
            if m:
                mins = int(m.group(1))
        steps.append({"name": name, "minutes": mins})
    
    total = sum(s["minutes"] for s in steps)
    routines.append({
        "id": os.path.splitext(os.path.basename(fp))[0].lower().replace(" ", "-"),
        "name": fm.get("name", os.path.splitext(os.path.basename(fp))[0]),
        "time": fm.get("time", "anytime"),
        "icon": fm.get("icon", "📋"),
        "totalMinutes": total,
        "steps": steps
    })

os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w") as f:
    json.dump(routines, f, indent=2, ensure_ascii=False)

print(f"✅ Synced {len(routines)} routines → {out}")
PYEOF
