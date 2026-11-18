#!/usr/bin/env python3
"""Prepare the v0.26.0 browser assets from the official source archive."""

import gzip
import re
import sys
import tarfile
from pathlib import Path


source = Path(sys.argv[1])
prefix = "alertmanager-0.26.0"
destination = Path(__file__).resolve().parent / "artifacts/alertmanager-ui-0.26.0"
with tarfile.open(source, "r:gz") as archive:
    generated = archive.extractfile(f"{prefix}/asset/assets_vfsdata.go").read().decode()
    match = re.search(
        r'"/static/script\.js": &[^\n]+\n[^}]+?compressedContent: \[\]byte\("((?:\\x[0-9a-f]{2})+)"\)',
        generated,
    )
    if not match:
        raise SystemExit("Compiled script.js was not found in the official assets")
    javascript = gzip.decompress(bytes.fromhex(match[1].replace("\\x", "")))

    asset_prefix = f"{prefix}/ui/app/"
    for member in archive:
        relative = member.name.removeprefix(asset_prefix)
        if member.isfile() and (
            relative in ("index.html", "favicon.ico") or relative.startswith("lib/")
        ):
            target = destination / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(archive.extractfile(member).read())
    for name in ("LICENSE", "NOTICE"):
        (destination / name).write_bytes(archive.extractfile(f"{prefix}/{name}").read())
    (destination / "script.js").write_bytes(javascript)
