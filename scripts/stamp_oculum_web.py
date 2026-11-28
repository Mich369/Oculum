"""Write one consistent build identity into the browser bundle and its marker."""

import json
from pathlib import Path
import re
import sys


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


if __name__ == "__main__":
    stamp_web_version(Path("build/web"), sys.argv[1])
