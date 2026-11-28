import json
import hashlib
import struct
import sys
from pathlib import Path
from zipfile import ZipFile


def digest(stream):
    return hashlib.file_digest(stream, "sha256").hexdigest()


def create_index(archive, version, edition):
    files = []
    with archive.open("rb") as raw, ZipFile(archive) as zipped:
        archive_hash = digest(raw)
        for entry in zipped.infolist():
            if entry.is_dir():
                continue
            raw.seek(entry.header_offset)
            header = raw.read(30)
            if len(header) != 30 or header[:4] != b"PK\x03\x04":
                raise ValueError(f"Invalid local ZIP header: {entry.filename}")
            flags, method = struct.unpack_from("<HH", header, 6)
            name_size, extra_size = struct.unpack_from("<HH", header, 26)
            if flags & 1 or method != entry.compress_type or method not in (0, 8):
                raise ValueError(f"Unsupported ZIP member: {entry.filename}")
            offset = entry.header_offset + 30 + name_size + extra_size
            with zipped.open(entry) as contents:
                sha = digest(contents)
            files.append({
                "path": entry.filename,
                "size": entry.file_size,
                "sha256": sha,
                "offset": offset,
                "length": entry.compress_size,
                "method": method,
            })

    if len(files) > 4000 or sum(row["size"] for row in files) > 768 * 1024 * 1024:
        raise ValueError("The runtime exceeds updater limits")
    return {
        "schemaVersion": 1,
        "version": version,
        "edition": edition,
        "archiveBytes": archive.stat().st_size,
        "archiveSha256": archive_hash,
        "files": sorted(files, key=lambda row: row["path"]),
    }


if __name__ == "__main__":
    archive_name, version, edition = sys.argv[1:]
    archive = Path(archive_name)
    manifest = create_index(archive, version, edition)
    destination = archive.with_suffix(".index.json")
    with destination.open("x", encoding="utf-8", newline="\n") as output:
        json.dump(manifest, output, separators=(",", ":"), ensure_ascii=False)
        output.write("\n")
