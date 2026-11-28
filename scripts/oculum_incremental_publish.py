"""Index the public Windows folder ZIP by compressed member range.

The manifest describes the complete destination build. Clients can reuse
verified installed files and fetch only members whose contents differ.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import struct
from urllib.parse import urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener
import zipfile


DEFAULT_REPOSITORY = "Mich369/Oculum"
WINDOWS_NAMES = {
    "normal": ("Oculum-Windows", "oculum.exe", ("Windows",)),
    "test": ("Oculum-Test-Windows", "Oculum-Test.exe", ("Windows Test", "windows-test")),
}
RUNTIME_PATHS = {
    "flutter_windows.dll",
    "webview2loader.dll",
    "data/app.so",
    "data/icudtl.dat",
    "data/flutter_assets/assetmanifest.bin",
}
BLOCK_SIZE = 1024 * 1024
ZIP_LOCAL_HEADER = struct.Struct("<4s5H3I2H")
WINDOWS_FORBIDDEN = re.compile(r'[\x00-\x1f<>:"\\|?*]')
WINDOWS_RESERVED = re.compile(r"(?:CON|PRN|AUX|NUL|CONIN\$|CONOUT\$|(?:COM|LPT)[1-9¹²³])", re.I)
GITHUB_DOWNLOAD_HOSTS = {"github.com", "release-assets.githubusercontent.com", "objects.githubusercontent.com"}


def _edition_names(edition):
    if edition not in WINDOWS_NAMES:
        raise ValueError("Windows edition must be normal or test")
    return WINDOWS_NAMES[edition]


def windows_manifest_asset_name(edition):
    return _edition_names(edition)[0] + "-Incrementale.json"


def _verified_package(package, edition, commit, run_id, repository):
    name, _, _ = _edition_names(edition)
    if not isinstance(commit, str) or not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("Invalid build commit")
    if type(run_id) is not int or run_id <= 0:
        raise ValueError("Invalid build run ID")
    if not re.fullmatch(r"[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+", repository):
        raise ValueError("Invalid GitHub repository")
    url = f"https://github.com/{repository}/releases/download/oculum-build-{run_id}/{name}-Folder.zip"
    size = package.get("bytes")
    digest = package.get("sha256", "")
    if (package.get("url") != url or type(size) is not int or not 0 < size < 2 * 1024 ** 3
            or not isinstance(digest, str) or not re.fullmatch(r"(?:sha256:)?[0-9a-f]{64}", digest)):
        raise ValueError("Invalid verified Windows folder asset identity")
    return {"url": url, "bytes": size, "sha256": digest.removeprefix("sha256:")}


def _member_parts(member):
    path = member.orig_filename
    parts = path.removesuffix("/").split("/")
    for part in parts:
        if (not part or WINDOWS_FORBIDDEN.search(part) or part.endswith((" ", "."))
                or WINDOWS_RESERVED.fullmatch(part.split(".", 1)[0].rstrip(" "))):
            raise ValueError(f"Unsafe Windows ZIP path: {path!r}")
    file_type = stat.S_IFMT(member.external_attr >> 16)
    expected = stat.S_IFDIR if member.is_dir() else stat.S_IFREG
    if (file_type not in {0, expected} or member.external_attr & 0x0400
            or (member.external_attr & 0x10 and not member.is_dir())):
        raise ValueError(f"Unsupported Windows ZIP member type: {path!r}")
    return tuple(parts)


def _runtime_entries(members, edition):
    _, exe, prefixes = _edition_names(edition)
    partition = [(member, _member_parts(member)) for member in members]
    files = {"/".join(parts).casefold() for member, parts in partition if not member.is_dir()}
    required = {exe.casefold(), *RUNTIME_PATHS}
    prefix = ""
    if not required.issubset(files):
        prefix = next((prefix.casefold() for prefix in prefixes
                       if all(f"{prefix.casefold()}/{path}" in files for path in required)), "")
        if not prefix:
            raise ValueError(f"Missing {edition} Windows runtime in a direct folder ZIP")

    output = {}
    known_paths = {}
    explicit_paths = set()
    for member, parts in partition:
        if prefix:
            if parts[0].casefold() != prefix:
                raise ValueError("ZIP contains entries outside the selected Windows folder")
            if len(parts) == 1 and member.is_dir():
                continue
            parts = parts[1:]
        if not parts:
            raise ValueError("ZIP file conflicts with the selected Windows folder")
        path = "/".join(parts)
        key = path.casefold()
        if key in explicit_paths:
            raise ValueError(f"Duplicate Windows ZIP path: {path!r}")
        explicit_paths.add(key)
        for length in range(1, len(parts) + 1):
            partial = "/".join(parts[:length])
            directory = length < len(parts) or member.is_dir()
            if known_paths.setdefault(partial.casefold(), (partial, directory)) != (partial, directory):
                raise ValueError(f"Conflicting Windows ZIP path: {path!r}")
        if not member.is_dir():
            output[path] = member
    other_exes = {names[1].casefold() for key, names in WINDOWS_NAMES.items() if key != edition}
    if any(path.rsplit("/", 1)[-1] in other_exes for path in explicit_paths):
        raise ValueError("Windows folder contains the executable for another edition")
    return output


def _member_data_offset(source, entry, boundary):
    if entry.compress_type not in {zipfile.ZIP_STORED, zipfile.ZIP_DEFLATED}:
        raise ValueError(f"Unsupported ZIP compression method for {entry.filename!r}")
    if entry.flag_bits & ~0x080E:
        raise ValueError(f"Unsupported ZIP flags for {entry.filename!r}")
    if entry.compress_type == zipfile.ZIP_STORED and entry.file_size != entry.compress_size:
        raise ValueError(f"Invalid stored ZIP size for {entry.filename!r}")
    if entry.header_offset < 0 or entry.header_offset + ZIP_LOCAL_HEADER.size > boundary:
        raise ValueError(f"Invalid ZIP local header offset for {entry.filename!r}")
    source.seek(entry.header_offset)
    header = source.read(ZIP_LOCAL_HEADER.size)
    if len(header) != ZIP_LOCAL_HEADER.size:
        raise ValueError(f"Truncated ZIP local header for {entry.filename!r}")
    signature, _, flags, method, _, _, _, _, _, filename_size, extra_size = ZIP_LOCAL_HEADER.unpack(header)
    offset = entry.header_offset + ZIP_LOCAL_HEADER.size + filename_size + extra_size
    encoding = "utf-8" if flags & 0x0800 else "cp437"
    if (signature != b"PK\x03\x04" or flags != entry.flag_bits or method != entry.compress_type
            or offset + entry.compress_size > boundary
            or source.read(filename_size) != entry.orig_filename.encode(encoding)):
        raise ValueError(f"ZIP local header disagrees with the central directory for {entry.filename!r}")
    return offset


def _sha256(stream):
    digest = hashlib.sha256()
    while chunk := stream.read(BLOCK_SIZE):
        digest.update(chunk)
    return digest.hexdigest()


def build_windows_range_manifest(path, *, edition, commit, run_id, package, repository=DEFAULT_REPOSITORY):
    """Index the exact verified GitHub folder asset, including ZIP64 headers.

    A wrapper containing only another ZIP uses the existing complete download.
    A compressed inner ZIP cannot serve direct member ranges from the outer URL.
    """
    package = _verified_package(package, edition, commit, run_id, repository)
    files = []
    with Path(path).open("rb") as source:
        before = os.fstat(source.fileno())
        if before.st_size != package["bytes"] or _sha256(source) != package["sha256"]:
            raise ValueError("Local ZIP size or SHA-256 differs from the verified release asset")
        with zipfile.ZipFile(source) as archive:
            members = archive.infolist()
            entries = _runtime_entries(members, edition)
            offsets = sorted(member.header_offset for member in members)
            if len(set(offsets)) != len(offsets):
                raise ValueError("Duplicate ZIP local header offsets")
            ends = dict(zip(offsets, [*offsets[1:], archive.start_dir], strict=True))
            for path, member in sorted(entries.items()):
                offset = _member_data_offset(source, member, ends[member.header_offset])
                with archive.open(member) as stream:
                    digest = _sha256(stream)
                files.append({
                    "path": path, "bytes": member.file_size, "sha256": digest, "offset": offset,
                    "compressedBytes": member.compress_size, "method": member.compress_type,
                })
        after = os.fstat(source.fileno())
        if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
            raise ValueError("Windows ZIP changed while it was being indexed")
    return {
        "schemaVersion": 1, "platform": "windows", "edition": edition, "commit": commit, "runId": run_id,
        "package": package, "files": files,
    }


def serialize_windows_range_manifest(manifest):
    return (json.dumps(manifest, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode("utf-8")


class _GithubRedirect(HTTPRedirectHandler):
    def redirect_request(self, request, file, code, message, headers, new_url):
        target = urlsplit(new_url)
        if target.scheme != "https" or target.netloc not in GITHUB_DOWNLOAD_HOSTS:
            raise ValueError("Unexpected GitHub release asset redirect")
        return super().redirect_request(request, file, code, message, headers, new_url)


def verify_public_archive_ranges(manifest, archive_path, *, repository=DEFAULT_REPOSITORY):
    """Probe two real member ranges through the public URL, without credentials."""
    package = _verified_package(manifest["package"], manifest["edition"], manifest["commit"],
                                manifest["runId"], repository)
    members = sorted((entry for entry in manifest["files"] if entry["compressedBytes"] > 0),
                     key=lambda entry: entry["offset"])
    if len(members) < 2:
        raise ValueError("Windows ZIP has too few nonempty members for range verification")
    opener = build_opener(_GithubRedirect())
    with Path(archive_path).open("rb") as source:
        if os.fstat(source.fileno()).st_size != package["bytes"]:
            raise ValueError("Local archive has changed before range verification")
        for entry in (members[0], members[-1]):
            start = entry["offset"]
            length = min(entry["compressedBytes"], 16)
            end = start + length - 1
            if not 0 < start <= end < package["bytes"]:
                raise ValueError("Invalid Windows member range")
            source.seek(start)
            expected = source.read(length)
            if len(expected) != length:
                raise ValueError("Local archive changed during range verification")
            request = Request(package["url"], headers={
                "Range": f"bytes={start}-{end}", "Accept-Encoding": "identity", "Cache-Control": "no-cache",
                "User-Agent": "Oculum-public-range-check",
            })
            with opener.open(request, timeout=60) as response:
                if (response.status != 206 or response.headers.get("Content-Encoding", "identity").lower() != "identity"
                        or response.headers.get("Content-Range") != f"bytes {start}-{end}/{package['bytes']}"
                        or response.read(length + 1) != expected):
                    raise ValueError(f"Public Windows member range differs for {entry['path']!r}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("--edition", required=True, choices=WINDOWS_NAMES)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--run-id", required=True, type=int)
    parser.add_argument("--repository", default=DEFAULT_REPOSITORY)
    parser.add_argument("--url", required=True, help="Verified public URL of the Windows folder ZIP")
    parser.add_argument("--bytes", required=True, type=int, help="Size of the verified release asset")
    parser.add_argument("--sha256", required=True, help="SHA-256 of the verified release asset")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--verify-public-ranges", action="store_true")
    args = parser.parse_args()
    manifest = build_windows_range_manifest(
        args.archive, edition=args.edition, commit=args.commit, run_id=args.run_id, repository=args.repository,
        package={"url": args.url, "bytes": args.bytes, "sha256": args.sha256},
    )
    if args.verify_public_ranges:
        verify_public_archive_ranges(manifest, args.archive, repository=args.repository)
    args.output.write_bytes(serialize_windows_range_manifest(manifest))


if __name__ == "__main__":
    main()
