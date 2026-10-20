"""Mirror successful build artifacts to anonymous, immutable GitHub Releases.

Only metadata is merged into the central download page; old releases survive.
Never execute or extract downloaded artifacts. Tokens stay in GH_TOKEN.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

REPO = os.environ.get("GH_REPO", "Mich369/Oculum")
CHANNEL = "oculum-downloads"
MARKER = "<!-- OCULUM_DOWNLOADS:"
WORKFLOWS = {
    "Build distribution", "Oculum Test Windows distribution",
    "Crea e aggiorna macOS", "Play Oculum on GitHub Pages",
    "Diari and Mappa tests",
}


def gh(*args, **kwargs):
    return subprocess.run(["gh", *args], check=True, **kwargs)


def api(path):
    return json.loads(gh("api", f"repos/{REPO}/{path}", capture_output=True).stdout)


def release(tag):
    result = subprocess.run(
        ["gh", "api", f"repos/{REPO}/releases/tags/{tag}"], capture_output=True,
    )
    if result.returncode == 0:
        return json.loads(result.stdout)
    if b"404" in result.stderr:
        return None
    result.check_returncode()


def validate_run(run):
    if (run.get("conclusion") != "success" or run.get("status") != "completed"
            or run.get("head_branch") != "main" or run.get("name") not in WORKFLOWS
            or run.get("repository", {}).get("full_name") != REPO
            or run.get("head_repository", {}).get("full_name") != REPO
            or not re.fullmatch(r"[0-9a-f]{40}", run.get("head_sha", ""))):
        raise ValueError("Only successful trusted main-branch builds may be published")


def asset_name(artifact):
    if not re.fullmatch(r"[A-Za-z0-9_-]+", artifact.get("name", "")):
        raise ValueError("Unsafe artifact name")
    if artifact.get("expired") is not False or not isinstance(artifact.get("id"), int):
        raise ValueError("Missing or expired artifact")
    if artifact.get("size_in_bytes", 0) >= 2 * 1024 ** 3:
        raise ValueError("Artifact exceeds GitHub Release asset size limit")
    return artifact["name"] + ".zip"


def read_catalog(body):
    if MARKER not in body:
        if body.strip():
            raise ValueError("Existing download catalog has an unknown format")
        return {}
    raw = body.split(MARKER, 1)[1].split(" -->", 1)[0]
    result = json.loads(raw)
    if not isinstance(result, dict):
        raise ValueError("Invalid download catalog")
    return result


def notes(catalog):
    lines = ["# Oculum — download pubblici", "",
             "Artifact completi delle ultime build riuscite, scaricabili senza account.",
             "Ogni gruppo indica il commit verificato. I file ZIP conservano gli artifact originali.", ""]
    for item in sorted(catalog.values(), key=lambda item: item["workflow"]):
        lines += [f"## {item['workflow']}", "",
                  f"Commit `{item['commit'][:7]}` · [Build verificata]({item['runUrl']})", ""]
        for artifact in item["artifacts"]:
            lines.append(f"- [{artifact['name']}]({artifact['url']}) — {artifact['bytes'] / 1024 ** 2:.1f} MB")
        lines.append("")
    lines.append(MARKER + json.dumps(catalog, ensure_ascii=True, separators=(",", ":")) + " -->")
    return "\n".join(lines)


def publish(run_id):
    if not re.fullmatch(r"[1-9][0-9]*", run_id):
        raise ValueError("Invalid run id")
    run = api(f"actions/runs/{run_id}")
    validate_run(run)
    workflow_id = run["workflow_id"]
    latest = api(f"actions/workflows/{workflow_id}/runs?branch=main&status=success&per_page=1")
    if latest["workflow_runs"][0]["id"] != run["id"]:
        print("A newer successful build exists; keeping its download channel")
        return
    artifacts = []
    page = 1
    while True:
        batch = api(f"actions/runs/{run_id}/artifacts?per_page=100&page={page}")["artifacts"]
        artifacts.extend(batch)
        if len(batch) < 100:
            break
        page += 1
    if not artifacts:
        print("This successful workflow produced no downloadable artifacts")
        return
    tag = f"oculum-build-{run_id}"
    current = release(CHANNEL)
    catalog = read_catalog(current.get("body") or "") if current else {}
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        if not release(tag):
            gh("release", "create", tag, "--repo", REPO, "--target", run["head_sha"],
               "--title", f"{run['name']} — {run['head_sha'][:7]}", "--prerelease",
               "--latest=false", "--notes", f"Verified build: {run['html_url']}")
        entries = []
        for artifact in artifacts:
            filename = asset_name(artifact)
            path = root / filename
            with path.open("wb") as stream:
                gh("api", f"repos/{REPO}/actions/artifacts/{artifact['id']}/zip", stdout=stream)
            with path.open("rb") as stream:
                digest = "sha256:" + hashlib.file_digest(stream, "sha256").hexdigest()
            if path.stat().st_size != artifact["size_in_bytes"] or artifact.get("digest") != digest:
                raise ValueError(f"Artifact integrity check failed: {filename}")
            gh("release", "upload", tag, str(path), "--repo", REPO, "--clobber")
            entries.append({"name": artifact["name"], "bytes": path.stat().st_size,
                            "sha256": digest,
                            "url": f"https://github.com/{REPO}/releases/download/{tag}/{filename}"})
        catalog[str(workflow_id)] = {
            "workflow": run["name"], "runId": run["id"], "commit": run["head_sha"],
            "runUrl": run["html_url"], "artifacts": entries,
        }
        note_file = root / "downloads.md"
        note_file.write_text(notes(catalog), encoding="utf-8")
        if current:
            gh("release", "edit", CHANNEL, "--repo", REPO, "--notes-file", str(note_file))
        else:
            gh("release", "create", CHANNEL, "--repo", REPO, "--target", run["head_sha"],
               "--title", "Oculum — download pubblici", "--notes-file", str(note_file),
               "--latest=false")
    print(f"Published {len(entries)} verified public artifacts for run {run_id}")


if __name__ == "__main__":
    publish(sys.argv[1])
