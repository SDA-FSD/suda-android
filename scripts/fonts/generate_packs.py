#!/usr/bin/env python3
"""가변 TTF 원본에서 스크립트 팩을 만든다.

원본은 리포 `assets/fonts` 또는 CDN `/fonts/source`에서 가져온다.
산출물은 업로드용 `build/font-packs/{version}/` (git 미추적).

  python3 -m pip install fonttools brotli
  python3 scripts/fonts/generate_packs.py
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE = ROOT / "assets" / "fonts"
DEFAULT_MANIFEST = Path(__file__).resolve().parent / "packs.json"
DEFAULT_OUT = ROOT / "build" / "font-packs"


def _pyftsubset() -> list[str]:
    return [sys.executable, "-m", "fontTools.subset"]


def subset_one(
    source: Path,
    dest: Path,
    unicodes: str,
) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        *_pyftsubset(),
        str(source),
        f"--output-file={dest}",
        f"--unicodes={unicodes}",
        "--ignore-missing-unicodes",
        "--layout-features=*",
        "--glyph-names",
        "--notdef-glyph",
        "--notdef-outline",
        "--recommended-glyphs",
        "--name-IDs=*",
        "--name-legacy",
        "--name-languages=*",
        "--legacy-kern",
    ]
    subprocess.run(cmd, check=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-dir", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    version = manifest["version"]
    packs = manifest["packs"]
    family_packs = manifest["familyPacks"]
    source_files = manifest["sourceFiles"]
    out_root = args.out_dir / version
    out_root.mkdir(parents=True, exist_ok=True)

    for family, filename in source_files.items():
        src = args.source_dir / filename
        if not src.is_file():
            print(f"missing source: {src}", file=sys.stderr)
            return 1
        for pack_id in family_packs[family]:
            unicodes = packs[pack_id]["unicodes"]
            dest = out_root / f"{family}-{pack_id}.ttf"
            print(f"subset {family} {pack_id} -> {dest.name}")
            subset_one(src, dest, unicodes)
            size_mb = dest.stat().st_size / (1024 * 1024)
            print(f"  {size_mb:.1f} MB")

    print(f"done: {out_root}")
    print(
        "upload: {cdn}/fonts/source/<original.ttf> "
        "and {cdn}/fonts/packs/{version}/<Family>-{pack}.ttf"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as e:
        print("fontTools.subset failed. pip install fonttools brotli", file=sys.stderr)
        raise SystemExit(e.returncode) from e
