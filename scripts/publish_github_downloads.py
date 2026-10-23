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
from urllib.parse import urlencode
from urllib.request import Request, urlopen

REPO = os.environ.get("GH_REPO", "Mich369/Oculum")
CHANNEL = "oculum-downloads"
MARKER = "<!-- OCULUM_DOWNLOADS:"
WORKFLOWS = {"Build distribution"}
WORKFLOW_PATHS = {".github/workflows/build_distribution.yml"}
PUBLIC_ARTIFACTS = (
    "Oculum-macOS", "Oculum-Windows", "Oculum-Test-Windows",
    "Oculum-Linux", "Oculum-Android",
)
EXTRA_ARCHIVES = (
    "Oculum-Web", "Oculum-iOS-unsigned", "Oculum-UI-Catture",
    "Oculum-Windows-Folders",
)


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


def validate_run(run, workflow):
    if (run.get("conclusion") != "success" or run.get("status") != "completed"
            or run.get("head_branch") != "main"
            or workflow.get("name") not in WORKFLOWS
            or workflow.get("path") not in WORKFLOW_PATHS
            or run.get("repository", {}).get("full_name") != REPO
            or run.get("head_repository", {}).get("full_name") != REPO
            or not re.fullmatch(r"[0-9a-f]{40}", run.get("head_sha", ""))):
        raise ValueError("Only successful trusted repository builds may be published")


def asset_name(artifact):
    if not re.fullmatch(r"[A-Za-z0-9_-]+", artifact.get("name", "")):
        raise ValueError("Unsafe artifact name")
    if artifact.get("expired") is not False or not isinstance(artifact.get("id"), int):
        raise ValueError("Missing or expired artifact")
    if artifact.get("size_in_bytes", 0) >= 2 * 1024 ** 3:
        raise ValueError("Artifact exceeds GitHub Release asset size limit")
    return artifact["name"] + ".zip"


def select_public_artifacts(artifacts):
    """Return the complete supported release set, excluding all other files."""
    selected = {}
    for artifact in artifacts:
        name = artifact.get("name")
        if name not in PUBLIC_ARTIFACTS:
            continue
        if name in selected:
            raise ValueError(f"Duplicate public artifact: {name}")
        selected[name] = artifact
    missing = [name for name in PUBLIC_ARTIFACTS if name not in selected]
    if missing:
        raise ValueError("Waiting for the complete platform set; missing: " + ", ".join(missing))
    return [selected[name] for name in PUBLIC_ARTIFACTS]


def select_release_archives(artifacts):
    """Publish every reviewed build archive; keep five platforms in the UI."""
    selected = select_public_artifacts(artifacts)
    seen = set(PUBLIC_ARTIFACTS)
    for artifact in artifacts:
        name = artifact.get("name")
        if name in PUBLIC_ARTIFACTS:
            continue
        if name not in EXTRA_ARCHIVES or name in seen:
            raise ValueError("Unreviewed or duplicate archive: " + str(name))
        seen.add(name)
        selected.append(artifact)
    for artifact in selected:
        asset_name(artifact)
    return selected


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
    lines = ["# Oculum â€” download pubblici", "",
             "Artifact completi delle ultime build riuscite, scaricabili senza account.",
             "Ogni gruppo indica il commit verificato. I file ZIP conservano gli artifact originali.", ""]
    for item in sorted(catalog.values(), key=lambda item: item["workflow"]):
        lines += [f"## {item['workflow']}", "",
                  f"Commit `{item['commit'][:7]}` Â· [Build verificata]({item['runUrl']})", ""]
        for artifact in item["artifacts"]:
            lines.append(f"- [{artifact['name']}]({artifact['url']}) â€” {artifact['bytes'] / 1024 ** 2:.1f} MB")
        if item.get("runId"):
            lines += ["", f"[Archivio completo della build](https://github.com/{REPO}/releases/tag/oculum-build-{item['runId']}) â€” include anche Web, iOS non firmato e catture di verifica."]
        lines.append("")
    lines.append(MARKER + json.dumps(catalog, ensure_ascii=True, separators=(",", ":")) + " -->")
    return "\n".join(lines)


def verify_anonymous_download(entry):
    """Verify public redirects, size and ZIP header without sending credentials."""
    request = Request(entry["url"], headers={"Range": "bytes=0-3", "User-Agent": "Oculum-public-download-check"})
    with urlopen(request, timeout=60) as response:
        if response.status not in (200, 206) or response.read(4) != b"PK\x03\x04":
            raise ValueError("Public download is unavailable or not an archive: " + entry["name"])
        total = response.headers.get("Content-Range", "").split("/")[-1]
        if response.status == 200:
            total = response.headers.get("Content-Length", "")
        if total and (not total.isdigit() or int(total) != entry["bytes"]):
            raise ValueError("Public download size mismatch: " + entry["name"])


def can_promote_channel(catalog, run_id):
    """A slow build from another branch cannot roll the public channel back."""
    return all(int(item.get("runId", 0)) <= int(run_id) for item in catalog.values()
               if item.get("workflow") == "Build distribution")


def resolve_run_id(run_id):
    candidate = (run_id or "").strip()
    if candidate:
        if not re.fullmatch(r"[1-9][0-9]*", candidate):
            raise ValueError("Invalid run id: enter a positive number or leave blank")
        return candidate
    query = urlencode({"branch": "main", "status": "success", "per_page": 20})
    runs = api(f"actions/workflows/build_distribution.yml/runs?{query}").get("workflow_runs", [])
    for run in runs:
        if (run.get("status") == "completed" and run.get("conclusion") == "success"
                and run.get("head_branch") == "main"
                and run.get("head_repository", {}).get("full_name") == REPO
                and type(run.get("id")) is int and run["id"] > 0):
            return str(run["id"])
    raise ValueError("No successful Build distribution on main available to publish")


def publish(run_id):
    run_id = resolve_run_id(run_id)
    run = api(f"actions/runs/{run_id}")
    workflow = api(f"actions/workflows/{run['workflow_id']}")
    validate_run(run, workflow)
    workflow_id = run["workflow_id"]
    branch_query = urlencode({"branch": run["head_branch"], "status": "success", "per_page": 1})
    latest = api(f"actions/workflows/{workflow_id}/runs?{branch_query}")
    if not latest.get("workflow_runs") or latest["workflow_runs"][0]["id"] != run["id"]:
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
        raise ValueError("Successful distribution has no downloadable artifacts")
    artifacts = select_release_archives(artifacts)
    tag = f"oculum-build-{run_id}"
    current = release(CHANNEL)
    catalog = read_catalog(current.get("body") or "") if current else {}
    promote = can_promote_channel(catalog, run_id)
    # The public channel lists only the coordinated five-platform build. Other
    # older per-workflow releases remain intact and directly accessible.
    catalog = {
        key: value for key, value in catalog.items()
        if value.get("workflow") == "Build distribution"
    }
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        if not release(tag):
            gh("release", "create", tag, "--repo", REPO, "--target", run["head_sha"],
               "--title", f"{run['name']} â€” {run['head_sha'][:7]}", "--prerelease",
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
        for entry in entries:
            verify_anonymous_download(entry)
        if not promote:
            print("Archived verified build without rolling back the public channel")
            return
        catalog[str(workflow_id)] = {
            "workflow": run["name"], "runId": run["id"], "commit": run["head_sha"],
            "runUrl": run["html_url"],
            "artifacts": entries,
        }
        note_file = root / "downloads.md"
        note_file.write_text(notes(catalog), encoding="utf-8")
        if current:
            gh("release", "edit", CHANNEL, "--repo", REPO, "--notes-file", str(note_file))
        else:
            gh("release", "create", CHANNEL, "--repo", REPO, "--target", run["head_sha"],
               "--title", "Oculum â€” download pubblici", "--notes-file", str(note_file),
               "--latest=false")
    print(f"Published {len(entries)} verified public artifacts for run {run_id}")


if __name__ == "__main__":
    publish(sys.argv[1])

