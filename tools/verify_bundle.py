"""Check the player ZIP and the cooked SGA members it actually contains."""

import argparse
from collections import Counter
from hashlib import sha256
import json
from pathlib import Path, PurePosixPath
import shutil
import subprocess
from tempfile import TemporaryDirectory
from zipfile import BadZipFile, ZipFile


MAX_BYTES = 500_000_000
TARGET_BYTES = 420_000_000
SOLO_MEMBERS = {
    ("attrib", "attrib/ebps/garrison/aoe4_dota_mod/lane_stronghold.rgd"),
    ("attrib", "attrib/ebps/garrison/aoe4_dota_mod/lane_tower.rgd"),
    ("attrib", "attrib/sbps/garrison/aoe4_dota_mod/shield_captain.rgd"),
    ("attrib", "attrib/sbps/garrison/aoe4_dota_mod/bow_skirmisher.rgd"),
    ("data", "scar/winconditions/aoe4_dota_mod.scar"),
    ("data", "scar/winconditions/aoe4_dota_mod.bin"),
    ("data", "scar/gameplay/proving_ground.scar"),
    ("data", "scar/ui/lane_wars_ui.scar"),
    ("data", "scar/ui/lane_wars_views.scar"),
    ("data", "scenarios/multiplayer/proving_ground/proving_ground.info"),
    ("data", "scenarios/multiplayer/proving_ground/proving_ground.scar"),
    ("data", "scenarios/multiplayer/proving_ground/proving_ground.scenario"),
    ("locale", "en/en.ucs"),
}


def digest(path):
    checksum = sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            checksum.update(block)
    return checksum.hexdigest()


def member_path(name):
    path = PurePosixPath(name)
    if not name or path.is_absolute() or ".." in path.parts or "\\" in name or ":" in name:
        raise ValueError(f"Unsafe bundle member path {name!r}")
    return path


def category(entry):
    path = entry["path"]
    if path.startswith("audio/"):
        return "audio"
    if path.startswith("scenarios/"):
        return "map"
    if path.startswith("art/"):
        return "art"
    return "scripts, tuning, UI and metadata"


def verify(bundle_path, archiver, solo):
    size = bundle_path.stat().st_size
    if size > MAX_BYTES:
        raise ValueError(f"Player ZIP has {size:,} bytes and exceeds the {MAX_BYTES:,}-byte cap")

    with ZipFile(bundle_path) as bundle, TemporaryDirectory(dir=bundle_path.parent) as temp:
        files = [member_path(entry.filename) for entry in bundle.infolist() if not entry.is_dir()]
        if len(files) != len({str(path).casefold() for path in files}):
            raise ValueError("Duplicate paths in the ZIP")
        manifests = [path for path in files if path.name.casefold() == "garrison.json"]
        if len(manifests) != 1:
            raise ValueError("The ZIP must contain exactly one garrison.json")
        damaged = bundle.testzip()
        if damaged:
            raise ValueError(f"ZIP CRC mismatch for {damaged}")

        manifest_path = manifests[0]
        manifest = json.loads(bundle.read(str(manifest_path)))
        if manifest.get("schema") != "garrison.mod/v1" or not manifest.get("members"):
            raise ValueError("Invalid Garrison manifest schema or empty payload")

        expected = set()
        cooked = set()
        totals = Counter()
        for index, declaration in enumerate(manifest["members"]):
            path = manifest_path.parent / member_path(declaration["path"])
            if path in expected or path not in files or path.suffix.lower() != ".sga":
                raise ValueError(f"Duplicate, missing, or invalid declared SGA {path}")
            expected.add(path)
            archive = Path(temp) / f"{index}.sga"
            with bundle.open(str(path)) as source, archive.open("wb") as target:
                shutil.copyfileobj(source, target)
            if digest(archive) != declaration["sha256"].lower():
                raise ValueError(f"SHA-256 mismatch for {path}")

            result = subprocess.run(
                [archiver, "list", str(archive), "--verify"],
                check=True,
                capture_output=True,
                text=True,
                encoding="utf-8",
            )
            listing = json.loads(result.stdout)
            integrity = listing["archive"]["verification"]
            if not integrity["verified"]:
                raise ValueError(f"SGA integrity check failed for {path}")
            for entry in listing["members"]:
                cooked.add((entry["toc"], entry["path"]))
                totals[category(entry)] += entry["stored_size"]

        if {path for path in files if path.suffix.lower() == ".sga"} != expected:
            raise ValueError("The ZIP contains an undeclared SGA")
        if solo and (missing := SOLO_MEMBERS - cooked):
            raise ValueError(f"Missing solo fixture members {sorted(missing)}")

    print(f"{bundle_path.name}  {size:,} bytes")
    print(f"SHA-256  {digest(bundle_path)}")
    print(f"Verified {len(expected)} SGA(s) with {len(cooked)} distinct members")
    for name, total in sorted(totals.items()):
        print(f"  {name}  {total:,} stored SGA bytes")
    if size > TARGET_BYTES:
        print(f"Above the {TARGET_BYTES:,}-byte working target")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bundle", type=Path)
    parser.add_argument("--archiver", type=Path, required=True)
    parser.add_argument("--solo", action="store_true", help="Require the Proving Ground fixture files")
    args = parser.parse_args()
    try:
        verify(args.bundle, args.archiver, args.solo)
    except (BadZipFile, KeyError, OSError, ValueError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Bundle check failed. {error}\n")


if __name__ == "__main__":
    main()
