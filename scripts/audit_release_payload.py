"""Inspect Oculum release archive members without extracting or changing files."""

import argparse
from collections import defaultdict
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import stat
from zipfile import BadZipFile, ZipFile


PACKAGES = {
    "windows": "Oculum-Windows.zip",
    "windows-test": "Oculum-Test-Windows.zip",
    "android": "Oculum-Android-release.apk",
}
DEBUG_SUFFIXES = {".dbg", ".dwarf", ".ilk", ".map", ".pdb", ".sym", ".symbols"}
ARCHIVE_SUFFIXES = {".7z", ".aab", ".apk", ".gz", ".ipa", ".rar", ".tar", ".zip"}
TEMP_SUFFIXES = {".bak", ".log", ".old", ".orig", ".temp", ".tmp"}
DEV_DIRECTORIES = {".dart_tool", ".git", ".venv", "node_modules"}
TEMP_DIRECTORIES = {"backup", "backups", "temp", "tmp"}
RUNTIME_ARCHIVES = {"okhttp3/internal/publicsuffix/publicsuffixes.gz"}
WINDOWS_RESERVED = {
    "AUX", "CON", "NUL", "PRN",
    *(f"{prefix}{number}" for prefix in ("COM", "LPT") for number in range(1, 10)),
}


def member_name(info, *, windows):
    original = info.orig_filename
    path = original.removesuffix("/")
    parts = path.split("/")
    if (
        not path
        or any(not part or part in {".", ".."} for part in parts)
        or any(character in original for character in ("\\", ":", "\x00"))
        or any(part.endswith((" ", ".")) for part in parts)
    ):
        raise ValueError(f"Unsafe archive member: {original!r}")
    if windows and any(
        part.split(".", 1)[0].upper() in WINDOWS_RESERVED
        or any(character in '<>"|?*' or ord(character) < 32 for character in part)
        for part in parts
    ):
        raise ValueError(f"Unsafe Windows archive member: {original!r}")
    mode = info.external_attr >> 16
    kind = stat.S_IFMT(mode)
    if kind not in {0, stat.S_IFREG, stat.S_IFDIR} or (
        kind != 0 and (kind == stat.S_IFDIR) != info.is_dir()
    ):
        raise ValueError(f"Special archive member: {original!r}")
    return path


def member_category(path):
    lower = path.lower()
    parts = lower.split("/")
    directories = set(parts[:-1])
    suffix = PurePosixPath(lower).suffix
    if lower in RUNTIME_ARCHIVES:
        return "runtime_archive"
    if (
        suffix in DEBUG_SUFFIXES
        or "debug" in directories
        or any(part.endswith(".dsym") for part in parts)
    ):
        return "debug_symbol"
    if set(parts) & DEV_DIRECTORIES:
        return "development"
    if suffix in TEMP_SUFFIXES or directories & TEMP_DIRECTORIES:
        return "temporary"
    if suffix in ARCHIVE_SUFFIXES:
        return "embedded_archive"
    if "flutter_assets" in parts:
        return "flutter_asset"
    if len(parts) == 3 and parts[0] == "lib" and suffix == ".so":
        return f"native/{parts[1]}"
    return "runtime"


def required_members(platform):
    if platform == "android":
        return {"AndroidManifest.xml", "classes.dex"}
    return {
        "Oculum-Test.exe" if platform == "windows-test" else "oculum.exe",
        "WebView2Loader.dll",
        "data/app.so",
        "data/icudtl.dat",
        "flutter_windows.dll",
    }


def sha256_file(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def audit_archive(path, platform):
    categories = defaultdict(lambda: {"files": 0, "bytes": 0, "compressedBytes": 0})
    all_paths = {}
    files = set()
    flagged = []
    windows = platform != "android"
    with ZipFile(path) as archive:
        for member in archive.infolist():
            name = member_name(member, windows=windows)
            identity = name.casefold() if windows else name
            if identity in all_paths:
                raise ValueError(f"Duplicate archive member: {name}")
            all_paths[identity] = member.is_dir()
            if member.is_dir():
                continue
            files.add(name)
            category = member_category(name)
            summary = categories[category]
            summary["files"] += 1
            summary["bytes"] += member.file_size
            summary["compressedBytes"] += member.compress_size
            if category in {
                "debug_symbol", "development", "temporary", "embedded_archive",
            }:
                flagged.append({"path": name, "category": category, "bytes": member.file_size})
    for name in all_paths:
        for parent in PurePosixPath(name).parents:
            if all_paths.get(parent.as_posix()) is False:
                raise ValueError(f"Archive member uses a file as directory: {name}")
    missing = sorted(required_members(platform) - files)
    if not categories["flutter_asset"]["files"]:
        missing.append("flutter_assets/")
    if platform == "android" and not any(key.startswith("native/") for key in categories):
        missing.append("lib/<ABI>/*.so")
    if windows:
        other_exe = "oculum.exe" if platform == "windows-test" else "Oculum-Test.exe"
        if any(PurePosixPath(name).name.casefold() == other_exe.casefold() for name in files):
            raise ValueError(f"{platform} also contains the other edition: {other_exe}")
    if missing:
        raise ValueError(f"{platform} is missing required runtime: {', '.join(missing)}")
    return {
        "platform": platform,
        "filename": path.name,
        "archiveBytes": path.stat().st_size,
        "archiveSha256": sha256_file(path),
        "files": len(files),
        "expandedBytes": sum(item["bytes"] for item in categories.values()),
        "compressedMemberBytes": sum(item["compressedBytes"] for item in categories.values()),
        "categories": dict(sorted(categories.items())),
        "candidatesForReview": sorted(flagged, key=lambda item: item["path"]),
    }


def verify_android_receipt(report, receipt_path):
    receipt = json.loads(receipt_path.read_text(encoding="utf-8-sig"))
    if not isinstance(receipt, dict):
        raise ValueError("Invalid Android signing receipt")
    certificate = receipt.get("signingCertificateSha256", "")
    if (
        receipt.get("signatureVerified") is not True
        or receipt.get("apkBytes") != report["archiveBytes"]
        or receipt.get("apkSha256") != report["archiveSha256"]
        or receipt.get("package") != "com.mich.oculum"
        or type(receipt.get("versionCode")) is not int
        or receipt["versionCode"] < 1
        or not isinstance(certificate, str)
        or not re.fullmatch(r"[a-fA-F0-9]{64}", certificate)
    ):
        raise ValueError("Android signing receipt does not verify these APK bytes")
    return {
        "receiptMatchesArchive": True,
        "package": receipt["package"],
        "versionCode": receipt["versionCode"],
        "signingCertificateSha256": certificate.lower(),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("distribution", type=Path)
    parser.add_argument("--android-signing-receipt", type=Path)
    args = parser.parse_args()
    try:
        packages = {
            platform: audit_archive(args.distribution / filename, platform)
            for platform, filename in PACKAGES.items()
        }
        android = packages["android"]
        android["signingReceipt"] = (
            verify_android_receipt(android, args.android_signing_receipt)
            if args.android_signing_receipt else {"receiptMatchesArchive": None}
        )
    except (BadZipFile, OSError, ValueError) as error:
        parser.exit(1, f"{error}\n")
    print(json.dumps({"packages": packages}, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
