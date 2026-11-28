"""Write one consistent build identity into the browser bundle and its marker."""

import hashlib
import json
from pathlib import Path
import re
import sys
from urllib.parse import quote


MAX_CACHE_FILE_BYTES = 24 * 1024 * 1024


def write_resource_manifest(build: Path, commit: str) -> None:
    files = {}
    for path in sorted(build.rglob("*")):
        if not path.is_file():
            continue
        relative = path.relative_to(build).as_posix()
        cacheable = relative.startswith(("assets/", "canvaskit/")) or re.fullmatch(
            r"(?:main\.dart|main\.dart\.js_\d+\.part)\.(?:js|mjs|wasm)", relative
        )
        size = path.stat().st_size
        if not cacheable or size > MAX_CACHE_FILE_BYTES:
            continue
        with path.open("rb") as contents:
            digest = hashlib.file_digest(contents, "sha256").hexdigest()
        files[quote(relative, safe="/")] = [digest, size]
    raw = json.dumps({"commit": commit, "files": files}, separators=(",", ":"))
    (build / "oculum-resources.json").write_text(raw + "\n", encoding="utf-8")


def stamp_web_version(build: Path, commit: str) -> None:
    if re.fullmatch(r"[0-9a-f]{40}", commit) is None:
        raise ValueError("Invalid compiled source commit")
    files = {name: (build / name).read_text(encoding="utf-8")
             for name in ("index.html", "flutter_bootstrap.js")}
    if not all("__OCULUM_BUILD__" in source for source in files.values()):
        raise ValueError("Missing browser build identity placeholder")
    for name, source in files.items():
        (build / name).write_text(source.replace("__OCULUM_BUILD__", commit), encoding="utf-8")
    (build / "oculum-build.json").write_text(json.dumps({"commit": commit}) + "\n", encoding="utf-8")
    if (build / "oculum_resource_worker.js").is_file():
        write_resource_manifest(build, commit)


if __name__ == "__main__":
    stamp_web_version(Path("build/web"), sys.argv[1])
