"""Verify and safely unpack the web bundle built by a successful Oculum CI run."""
import argparse
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import zipfile


MAX_UNPACKED_BYTES = 1_500_000_000
REQUIRED_FILES = ("index.html", "flutter_bootstrap.js", "main.dart.js")


def _normalized_name(info):
    name = info.filename
    if "\\" in name or name.startswith("/"):
        raise ValueError(f"Unsafe ZIP entry path: {name!r}")
    path = PurePosixPath(name)
    parts = tuple(part for part in path.parts if part not in ("", "."))
    if not parts:
        return ""
    if any(part == ".." for part in parts) or ":" in parts[0]:
        raise ValueError(f"Unsafe ZIP entry path: {name!r}")
    mode = info.external_attr >> 16
    if stat.S_ISLNK(mode):
        raise ValueError(f"Symbolic links are not allowed in the web ZIP: {name!r}")
    return "/".join(parts)


def prepare(archive_path, output_path, commit, base_path="/Oculum/"):
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("The source commit must be a full lowercase Git SHA")
    if not base_path.startswith("/") or not base_path.endswith("/") or ".." in base_path:
        raise ValueError("The Pages base path must be an absolute path ending with '/'")

    archive_path = Path(archive_path)
    output_path = Path(output_path)
    if not archive_path.is_file() or archive_path.stat().st_size == 0:
        raise ValueError("The Oculum web archive is missing or empty")
    output_path.mkdir(parents=True, exist_ok=True)
    if output_path.is_symlink() or any(output_path.iterdir()):
        raise ValueError("The Pages output folder must be empty and must not be a link")
    root = output_path.resolve()

    with zipfile.ZipFile(archive_path) as bundle:
        entries = {}
        total_size = 0
        for info in bundle.infolist():
            name = _normalized_name(info)
            if not name:
                continue
            if name in entries:
                raise ValueError(f"Duplicate ZIP entry: {name}")
            if info.flag_bits & 0x1:
                raise ValueError(f"Encrypted ZIP entry is not supported: {name}")
            total_size += info.file_size
            if total_size > MAX_UNPACKED_BYTES:
                raise ValueError("The web archive expands beyond the safety limit")
            entries[name] = info

        for name in REQUIRED_FILES:
            if name not in entries:
                raise ValueError(f"The web archive is missing {name}")

        index = bundle.read(entries["index.html"]).decode("utf-8")
        bootstrap = bundle.read(entries["flutter_bootstrap.js"]).decode("utf-8")
        if f'<base href="{base_path}">' not in index:
            raise ValueError("The web build does not target the configured GitHub Pages path")
        if commit not in index or commit not in bootstrap:
            raise ValueError("The web archive commit stamp does not match the source build")

        for name, info in entries.items():
            target = root.joinpath(*PurePosixPath(name).parts)
            if os.path.commonpath((str(root), str(target.resolve()))) != str(root):
                raise ValueError(f"ZIP entry escapes the Pages output folder: {name}")
            if info.is_dir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            with bundle.open(info) as source, target.open("xb") as destination:
                shutil.copyfileobj(source, destination)
            if target.stat().st_size != info.file_size:
                raise ValueError(f"Extracted file size mismatch: {name}")

    return len(entries)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--base-path", default="/Oculum/")
    args = parser.parse_args()
    count = prepare(args.archive, args.output, args.commit, args.base_path)
    print(f"VERIFIED and prepared {count} web entries for {args.commit}")


if __name__ == "__main__":
    main()
