"""Read-only verification of an existing, possibly unpublished app candidate."""

import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path, PurePosixPath
import zipfile


def digest(stream):
    value = hashlib.sha256()
    while chunk := stream.read(1024 * 1024):
        value.update(chunk)
    return value.hexdigest().upper()


def audit(root, expected_commit):
    root = root.resolve(strict=True)
    manifest = json.loads((root / "BUILD-VERIFICATE.json").read_text("utf-8-sig"))
    if manifest["commit"] != expected_commit:
        raise ValueError("Candidate source commit does not match")
    records = {}
    for record in manifest["files"]:
        relative = record["path"].replace("\\", "/")
        parts = PurePosixPath(relative)
        if parts.is_absolute() or ".." in parts.parts or ":" in relative:
            raise ValueError(f"Unsafe manifest path: {relative}")
        if relative.casefold() in records:
            raise ValueError(f"Duplicate manifest path: {relative}")
        records[relative.casefold()] = (relative, record)

    def verify_file(item):
        relative, record = item
        target = root / relative
        if not target.resolve(strict=True).is_relative_to(root):
            raise ValueError(f"File outside candidate: {relative}")
        if target.stat().st_size != record["bytes"]:
            raise ValueError(f"Wrong size: {relative}")
        with target.open("rb") as stream:
            if digest(stream) != record["sha256"].upper():
                raise ValueError(f"SHA-256 mismatch: {relative}")

    with ThreadPoolExecutor(max_workers=4) as executor:
        list(executor.map(verify_file, records.values()))
    actual = {
        str(path.relative_to(root)).replace("\\", "/").casefold()
        for path in root.rglob("*")
        if path.is_file()
    }
    if actual != set(records) | {"build-verificate.json"}:
        raise ValueError("Manifest and actual file lists do not match")
    print(f"Verified {len(records)} file sizes and SHA-256 hashes", flush=True)

    archives = []
    for folder, archive, executable in [
        ("windows", "Oculum-Windows.zip", "oculum.exe"),
        ("windows-test", "Oculum-Test-Windows.zip", "Oculum-Test.exe"),
    ]:
        prefix = folder + "/"
        expected = {
            key[len(prefix):]: record
            for key, (_, record) in records.items()
            if key.startswith(prefix)
        }
        for required in [executable, "flutter_windows.dll", "data/app.so", "data/icudtl.dat"]:
            if required.casefold() not in expected:
                raise ValueError(f"Missing runtime component: {folder}/{required}")
        with zipfile.ZipFile(root / archive) as zipped:
            names = set()
            for member in zipped.infolist():
                if member.is_dir():
                    continue
                key = member.filename.replace("\\", "/").casefold()
                if key in names or key not in expected:
                    raise ValueError(f"Unexpected or duplicate archive member: {archive}/{key}")
                names.add(key)
                record = expected[key]
                if member.file_size != record["bytes"]:
                    raise ValueError(f"Archive member size mismatch: {archive}/{key}")
                with zipped.open(member) as stream:
                    if digest(stream) != record["sha256"].upper():
                        raise ValueError(f"Archive content mismatch: {archive}/{key}")
            if names != set(expected):
                raise ValueError(f"Archive does not contain the complete runtime: {archive}")
            if folder == "windows" and any("oculum-test" in key or "windows-test/" in key for key in names):
                raise ValueError("Test edition included in normal Windows archive")
        archives.append({"path": archive, "verifiedMembers": len(expected)})
        print(f"Verified {archive}: {len(expected)} members match the runtime", flush=True)

    normal = records["windows/data/app.so"][1]["sha256"]
    test = records["windows-test/data/app.so"][1]["sha256"]
    if normal == test:
        raise ValueError("Normal and Test editions have identical AOT save profiles")

    apks = [relative for relative, _ in records.values() if relative.lower().endswith(".apk")]
    if not apks:
        raise ValueError("Candidate contains no Android APK")
    for apk in apks:
        with zipfile.ZipFile(root / apk) as zipped:
            if not {"AndroidManifest.xml", "classes.dex"}.issubset(zipped.namelist()):
                raise ValueError(f"Incomplete APK: {apk}")
            if zipped.testzip() is not None:
                raise ValueError(f"APK CRC failure: {apk}")
            log = "assets/flutter_assets/assets/update/oculum_cumulative_log.md"
            if zipped.read(log) != (root / "REGISTRO_AGGIORNAMENTI.md").read_bytes():
                raise ValueError("APK cumulative log differs from the packaged register")
        print(f"Verified APK integrity and bundled cumulative log: {apk}", flush=True)
    for folder in ["windows", "windows-test"]:
        log = root / folder / "data/flutter_assets/assets/update/oculum_cumulative_log.md"
        if log.read_bytes() != (root / "REGISTRO_AGGIORNAMENTI.md").read_bytes():
            raise ValueError(f"Cumulative log mismatch: {folder}")
    return {
        "sourceCommit": manifest["commit"],
        "sourceDirtyAtBuild": manifest.get("sourceDirty"),
        "buildId": manifest.get("buildId"),
        "verifiedFiles": len(records),
        "archives": archives,
        "androidApks": apks,
        "androidArtifact": manifest.get("androidArtifact"),
        "windowsAndTestSeparated": True,
        "cumulativeLogMatchesEveryPackage": True,
        "publicDistributionComplete": False,
        "verificationScope": "Local package integrity; no native launch, signing validation or live online test",
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--report", required=True, type=Path)
    args = parser.parse_args()
    result = audit(args.candidate, args.commit)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
