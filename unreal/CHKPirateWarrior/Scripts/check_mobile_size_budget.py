#!/usr/bin/env python3
"""Contrôle le budget disque de CHK Pirate Warrior sur Android.

Le plafond utilisateur est fixé à 5 Gio pour l'ensemble livré sur le téléphone.
Le script peut contrôler soit les sources du projet, soit un dossier de build Android.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

GIB = 1024 ** 3
MIB = 1024 ** 2
HARD_LIMIT_BYTES = 5 * GIB
WARNING_LIMIT_BYTES = 4 * GIB
SOURCE_ASSET_LIMIT_BYTES = 256 * MIB


def iter_files(root: Path):
    for path in root.rglob("*"):
        if path.is_file() and not any(part in {".git", "Binaries", "DerivedDataCache", "Intermediate", "Saved"} for part in path.parts):
            yield path


def human_size(value: int) -> str:
    if value >= GIB:
        return f"{value / GIB:.2f} Gio"
    if value >= MIB:
        return f"{value / MIB:.1f} Mio"
    return f"{value / 1024:.1f} Kio"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("path", type=Path, help="Dossier du projet ou dossier Android empaqueté")
    parser.add_argument("--build", action="store_true", help="Applique le plafond final strict de 5 Gio")
    args = parser.parse_args()

    root = args.path.resolve()
    if not root.exists():
        print(f"ERREUR: chemin introuvable: {root}", file=sys.stderr)
        return 2

    files = list(iter_files(root))
    total = sum(path.stat().st_size for path in files)
    largest = sorted(((path.stat().st_size, path) for path in files), reverse=True)[:20]

    print(f"CHK_MOBILE_SIZE_TOTAL={human_size(total)}")
    print(f"CHK_MOBILE_FILE_COUNT={len(files)}")
    print("CHK_MOBILE_LARGEST_FILES:")
    for size, path in largest:
        print(f"  {human_size(size):>10}  {path.relative_to(root)}")

    oversized_sources = []
    if not args.build:
        asset_extensions = {".uasset", ".umap", ".fbx", ".glb", ".gltf", ".obj", ".wav", ".flac", ".png", ".tga", ".exr"}
        oversized_sources = [
            path for path in files
            if path.suffix.lower() in asset_extensions and path.stat().st_size > SOURCE_ASSET_LIMIT_BYTES
        ]
        for path in oversized_sources:
            print(
                f"ERREUR: asset source supérieur à 256 Mio: "
                f"{path.relative_to(root)} ({human_size(path.stat().st_size)})",
                file=sys.stderr,
            )

    if total > HARD_LIMIT_BYTES:
        print(
            f"ERREUR: budget dépassé: {human_size(total)} > 5.00 Gio.",
            file=sys.stderr,
        )
        return 1

    if total > WARNING_LIMIT_BYTES:
        print(f"AVERTISSEMENT: le projet approche du plafond: {human_size(total)}.")

    if oversized_sources:
        return 1

    print("CHK_MOBILE_SIZE_BUDGET_OK=1")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
