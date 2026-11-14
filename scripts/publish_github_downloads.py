"""Mirror platform packages from successful builds to immutable GitHub Releases.

Only metadata is merged into the central download page; old releases survive.
Never execute or extract downloaded artifacts. Tokens stay in GH_TOKEN.
"""
import hashlib
import base64
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from time import sleep, time_ns
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

REPO = os.environ.get("GH_REPO", "Mich369/Oculum")
CHANNEL = "oculum-downloads"
MARKER = "<!-- OCULUM_DOWNLOADS:"
WORKFLOWS = {"Build distribution"}
WORKFLOW_PATHS = {".github/workflows/build_distribution.yml"}
PUBLIC_ARTIFACTS = (
    "Oculum-macOS", "Oculum-Windows", "Oculum-Test-Windows",
    "Oculum-Linux", "Oculum-Android", "Oculum-Web", "Oculum-iOS-unsigned",
    "Oculum-Windows-Folder", "Oculum-Test-Windows-Folder",
)
LEGACY_ARCHIVES = {"Oculum-Android-AAB", "Oculum-UI-Catture",
                   "Oculum-Windows-Folders", "Oculum-Verifica-Mostri"}


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
            or not isinstance(run.get("head_branch"), str) or not run["head_branch"]
            or run.get("event") in {"pull_request", "pull_request_target"}
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
    size = artifact.get("size_in_bytes")
    if type(size) is not int or size <= 0:
        raise ValueError("Missing artifact size")
    if size >= 2 * 1024 ** 3:
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
    """Publish only supported platform packages; keep known extras in Actions."""
    selected = select_public_artifacts(artifacts)
    seen = set(PUBLIC_ARTIFACTS)
    for artifact in artifacts:
        name = artifact.get("name")
        if name in PUBLIC_ARTIFACTS:
            continue
        if name not in LEGACY_ARCHIVES or name in seen:
            raise ValueError("Unreviewed or duplicate archive: " + str(name))
        seen.add(name)
    for artifact in selected:
        asset_name(artifact)
    return selected


def archive_entry(artifact, tag):
    filename = asset_name(artifact)
    digest = artifact.get("digest") or ""
    if not re.fullmatch(r"sha256:[0-9a-f]{64}", digest):
        raise ValueError(f"Missing or invalid artifact digest: {filename}")
    return {"name": artifact["name"], "bytes": artifact["size_in_bytes"],
            "sha256": digest,
            "url": f"https://github.com/{REPO}/releases/download/{tag}/{filename}"}


def verified_release_assets(released, tag, commit, expected):
    if (not released or released.get("tag_name") != tag or released.get("draft") is not False
            or released.get("target_commitish") != commit):
        raise ValueError("Versioned release does not match the verified build")
    verified = set()
    for asset in released.get("assets", []):
        name = asset.get("name")
        entry = expected.get(name)
        if (entry is None or name in verified or asset.get("state") != "uploaded"
                or (asset.get("size"), asset.get("digest"), asset.get("browser_download_url"))
                != (entry["bytes"], entry["sha256"], entry["url"])):
            raise ValueError(f"Release asset does not match the verified artifact: {name}")
        verified.add(name)
    return verified


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


def parse_update_notes(text):
    """Keep the human-written summary short; never render arbitrary HTML."""
    return [re.sub(r"[<>]", "", line.strip()[2:]).strip()[:160]
            for line in text.splitlines() if line.strip().startswith("- ")][:8]


def read_update_notes(commit):
    try:
        data = api("contents/docs/ULTIMO_AGGIORNAMENTO.md?" + urlencode({"ref": commit}))
    except subprocess.CalledProcessError as error:
        if b"404" in (error.stderr or b""):
            return []  # Earlier commits predate the concise update log.
        raise
    return parse_update_notes(base64.b64decode(data["content"]).decode("utf-8"))


def notes(catalog):
    lines = ["# Oculum — download pubblici", "",
             "Pacchetti delle ultime build riuscite, scaricabili senza account.",
             "Ogni gruppo indica il commit verificato. I file ZIP conservano gli artifact originali.", ""]
    for item in sorted(catalog.values(), key=lambda item: item["workflow"]):
        lines += [f"## {item.get('runName', item['workflow'])}", "",
                  f"Commit `{item['commit'][:7]}` · [Build verificata]({item['runUrl']})", ""]
        if item.get("changelogPath") == "docs/REGISTRO_AGGIORNAMENTI.md":
            lines += [f"[Registro completo dalla build b917217](https://github.com/{REPO}/blob/{item['commit']}/docs/REGISTRO_AGGIORNAMENTI.md) · [Versione di partenza](https://github.com/{REPO}/actions/runs/40242640717)", ""]
            lines += [f"[Come installare e aggiornare](https://github.com/{REPO}/blob/main/docs/AGGIORNARE_OCULUM.md)", ""]
        if item.get("changes"):
            lines += ["Log aggiornamento:", ""]
            lines += ["- " + change for change in item["changes"]]
            lines.append("")
        for artifact in item["artifacts"]:
            lines.append(f"- [{artifact['name']}]({artifact['url']}) — {artifact['bytes'] / 1024 ** 2:.1f} MB")
        lines.append("")
    lines.append(MARKER + json.dumps(catalog, ensure_ascii=True, separators=(",", ":")) + " -->")
    return "\n".join(lines)


def verify_anonymous_download(entry, asset_id=None):
    """Verify public redirects, size and ZIP header without sending credentials."""
    url = entry["url"]
    for delay in (2, 5, None):
        try:
            _check_public_zip(entry, url)
            return
        except (URLError, TimeoutError) as error:
            retryable = not isinstance(error, HTTPError) or error.code in {
                408, 429, 500, 502, 503, 504,
            }
            if delay is None or not retryable:
                raise RuntimeError(f"Public download failed for {entry['name']}: {error}") from error
            print(f"Retrying anonymous download check for {entry['name']}: {error}", flush=True)
            sleep(delay)
            base_url = entry["url"]
            if delay == 5 and type(asset_id) is int and asset_id > 0:
                base_url = f"https://api.github.com/repos/{REPO}/releases/assets/{asset_id}"
            url = f"{base_url}?oculum_check={time_ns()}"


def _check_public_zip(entry, url):
    headers = {"Range": "bytes=0-3", "Cache-Control": "no-cache",
               "User-Agent": "Oculum-public-download-check"}
    if url.startswith("https://api.github.com/"):
        headers.update({"Accept": "application/octet-stream", "X-GitHub-Api-Version": "2022-11-28"})
    request = Request(url, headers=headers)
    with urlopen(request, timeout=60) as response:
        if response.status not in (200, 206) or response.read(4) != b"PK\x03\x04":
            raise ValueError("Public download is unavailable or not an archive: " + entry["name"])
        valid_size = (response.headers.get("Content-Range") == f"bytes 0-3/{entry['bytes']}"
                      if response.status == 206
                      else response.headers.get("Content-Length") == str(entry["bytes"]))
        if not valid_size:
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
    query = urlencode({"status": "success", "per_page": 20})
    runs = api(f"actions/workflows/build_distribution.yml/runs?{query}").get("workflow_runs", [])
    for run in runs:
        if (run.get("status") == "completed" and run.get("conclusion") == "success"
                and run.get("head_branch")
                and run.get("event") not in {"pull_request", "pull_request_target"}
                and run.get("head_repository", {}).get("full_name") == REPO
                and type(run.get("id")) is int and run["id"] > 0):
            return str(run["id"])
    raise ValueError("No successful trusted Build distribution available to publish")


def publish(run_id):
    run_id = resolve_run_id(run_id)
    run = api(f"actions/runs/{run_id}")
    workflow = api(f"actions/workflows/{run['workflow_id']}")
    validate_run(run, workflow)
    workflow_id = run["workflow_id"]
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
    selected = select_release_archives(artifacts)
    tag = f"oculum-build-{run_id}"
    entries = [archive_entry(artifact, tag) for artifact in selected]
    expected = {entry["name"] + ".zip": entry for entry in entries}
    existing = release(tag)
    present = set()
    if existing:
        # A previously published full mirror can be re-indexed in place. Do
        # not add, remove or replace its internal artifacts.
        existing_names = {asset.get("name") for asset in existing.get("assets", [])}
        for artifact in artifacts:
            name = artifact.get("name")
            if name in LEGACY_ARCHIVES and name + ".zip" in existing_names:
                expected[name + ".zip"] = archive_entry(artifact, tag)
        present = verified_release_assets(existing, tag, run["head_sha"], expected)
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        if not existing:
            gh("release", "create", tag, "--repo", REPO, "--target", run["head_sha"],
               "--title", f"{run['name']} — {run['head_sha'][:7]}", "--prerelease",
               "--latest=false", "--notes", f"Verified build: {run['html_url']}")
        for artifact, entry in zip(selected, entries, strict=True):
            filename = entry["name"] + ".zip"
            if filename in present:
                continue
            path = root / filename
            with path.open("wb") as stream:
                gh("api", f"repos/{REPO}/actions/artifacts/{artifact['id']}/zip", stdout=stream)
            with path.open("rb") as stream:
                digest = "sha256:" + hashlib.file_digest(stream, "sha256").hexdigest()
            if path.stat().st_size != entry["bytes"] or entry["sha256"] != digest:
                raise ValueError(f"Artifact integrity check failed: {filename}")
            gh("release", "upload", tag, str(path), "--repo", REPO)
        published = release(tag)
        if verified_release_assets(published, tag, run["head_sha"], expected) != set(expected):
            raise ValueError("Versioned release is missing verified assets")
        asset_ids = {asset["name"]: asset.get("id") for asset in published["assets"]}
        for entry in entries:
            verify_anonymous_download(entry, asset_ids[entry["name"] + ".zip"])
        # The listing can lag the completion event. A missing or older listed
        # run cannot invalidate the requested run's verified release.
        branch_query = urlencode({"branch": run["head_branch"], "status": "success", "per_page": 1})
        latest = api(f"actions/workflows/{workflow_id}/runs?{branch_query}")
        newer_run_exists = any(
            type(candidate.get("id")) is int and candidate["id"] > run["id"]
            and candidate.get("status") == "completed" and candidate.get("conclusion") == "success"
            and candidate.get("event") not in {"pull_request", "pull_request_target"}
            and candidate.get("head_repository", {}).get("full_name") == REPO
            for candidate in latest.get("workflow_runs", [])
        )
        current = release(CHANNEL)
        catalog = read_catalog(current.get("body") or "") if current else {}
        if newer_run_exists or not can_promote_channel(catalog, run_id):
            print("Archived verified build without rolling back the public channel")
            return
        # The channel points to one latest platform build. Versioned releases
        # and their historical archives remain available at their own tags.
        catalog = {str(workflow_id): {
            "workflow": workflow["name"], "runName": run["name"],
            "runId": run["id"], "commit": run["head_sha"],
            "runUrl": run["html_url"],
            "changes": read_update_notes(run["head_sha"]),
            "changelogPath": "docs/REGISTRO_AGGIORNAMENTI.md",
            "changelogBaseline": "b917217d98d16861a5bbaf1706d78825d883c970",
            "artifacts": entries,
        }}
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

