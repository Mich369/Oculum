"""Mirror platform packages from successful builds to immutable GitHub Releases.

Only metadata is merged into the central download page; old releases survive.
The optional Android index reads only the signed, expected APK member of a
verified archive. The publisher never runs artifact content. Tokens stay in GH_TOKEN.
"""
import hashlib
import base64
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import tempfile
from time import sleep, time_ns
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, build_opener, urlopen
from zipfile import BadZipFile, ZIP_DEFLATED, ZipFile, ZipInfo

try:
    from scripts import oculum_incremental_publish
except ModuleNotFoundError:
    import oculum_incremental_publish
try:
    from scripts import oculum_android_incremental_publish, verify_android_signing
except ImportError:
    import oculum_android_incremental_publish
    import verify_android_signing

REPO = os.environ.get("GH_REPO", "Mich369/Oculum")
CHANNEL = "oculum-downloads"
PUBLIC_BRANCH = "main"
MARKER = "<!-- OCULUM_DOWNLOADS:"
WORKFLOWS = {"Build distribution"}
WORKFLOW_PATHS = {".github/workflows/build_distribution.yml"}
PUBLIC_ARTIFACTS = (
    "Oculum-macOS", "Oculum-Windows", "Oculum-Test-Windows",
    "Oculum-Linux", "Oculum-Android", "Oculum-Web", "Oculum-iOS-unsigned",
    "Oculum-Windows-Folder", "Oculum-Test-Windows-Folder",
)
EXTRA_PUBLIC_ARTIFACTS = ("Oculum-Android-AAB", "Oculum-UI-Catture",
                          "Oculum-Verifica-Mostri")
LEGACY_ARCHIVES = {"Oculum-Windows-Folders"}
WINDOWS_RUNTIMES = {
    "Oculum-Windows-Folder.zip": ("normal", "Oculum-Windows"),
    "Oculum-Test-Windows-Folder.zip": ("test", "Oculum-Test-Windows"),
}
WINDOWS_MANIFEST_NAMES = {oculum_incremental_publish.windows_manifest_asset_name(edition)
                          for edition, _ in WINDOWS_RUNTIMES.values()}
MAX_INCREMENTAL_MANIFEST_BYTES = 12 * 1024 ** 2
WINDOWS_BOOTSTRAP_ASSET = "Oculum-Aggiornamento-Incrementale-Windows.zip"
WINDOWS_BOOTSTRAP_SCRIPTS = (
    "Oculum-Aggiornamento-Incrementale.ps1", "incremental_driver.ps1",
    "oculum_incremental_windows.ps1", "update.ps1",
)
ANDROID_APK_ASSET = oculum_android_incremental_publish.ANDROID_APK_ASSET
ANDROID_MANIFEST_ASSET = oculum_android_incremental_publish.ANDROID_MANIFEST_ASSET
ANDROID_INCREMENTAL_ASSETS = {ANDROID_APK_ASSET, ANDROID_MANIFEST_ASSET}
ANDROID_ARTIFACT_MEMBERS = {"Oculum-Android-release.apk", "distribution/Oculum-Android-release.apk"}


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
    """Mirror reviewed build outputs, preserving the complete platform set."""
    selected = select_public_artifacts(artifacts)
    seen = set(PUBLIC_ARTIFACTS)
    for artifact in artifacts:
        name = artifact.get("name")
        if name in PUBLIC_ARTIFACTS:
            continue
        if name not in (*EXTRA_PUBLIC_ARTIFACTS, *LEGACY_ARCHIVES) or name in seen:
            raise ValueError("Unreviewed or duplicate archive: " + str(name))
        seen.add(name)
    for name in EXTRA_PUBLIC_ARTIFACTS:
        selected.extend(artifact for artifact in artifacts if artifact.get("name") == name)
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
        if name in WINDOWS_MANIFEST_NAMES or name in ANDROID_INCREMENTAL_ASSETS or name == WINDOWS_BOOTSTRAP_ASSET:
            continue  # verified separately before any incremental option is advertised
        entry = expected.get(name)
        if (entry is None or name in verified or asset.get("state") != "uploaded"
                or (asset.get("size"), asset.get("digest"), asset.get("browser_download_url"))
                != (entry["bytes"], entry["sha256"], entry["url"])):
            raise ValueError(f"Release asset does not match the verified artifact: {name}")
        verified.add(name)
    return verified


def download_verified_archive(artifact, entry, path):
    with path.open("wb") as stream:
        gh("api", f"repos/{REPO}/actions/artifacts/{artifact['id']}/zip", stdout=stream)
    with path.open("rb") as stream:
        digest = "sha256:" + hashlib.file_digest(stream, "sha256").hexdigest()
    if path.stat().st_size != entry["bytes"] or entry["sha256"] != digest:
        raise ValueError(f"Artifact integrity check failed: {path.name}")


def prepare_android_incremental(archive_path, output, run):
    """Extract the single expected APK, then verify its pinned, compiled identity."""
    version = 100000 + run["run_number"]
    apk_path = output / ANDROID_APK_ASSET
    with ZipFile(archive_path) as archive:
        members = [item for item in archive.infolist() if item.orig_filename in ANDROID_ARTIFACT_MEMBERS]
        if len(members) != 1:
            raise ValueError("Official Android artifact must contain exactly one release APK")
        member, = members
        if (stat.S_IFMT(member.external_attr >> 16) not in (0, stat.S_IFREG)
                or not 0 < member.file_size < 2 ** 31):
            raise ValueError("Official Android artifact APK is not a supported regular file")
        with archive.open(member) as source, apk_path.open("xb") as destination:
            shutil.copyfileobj(source, destination, length=1024 ** 2)
    sdk = os.environ.get("ANDROID_SDK_ROOT") or os.environ.get("ANDROID_HOME")
    java = shutil.which("java")
    if not sdk or not java:
        raise ValueError("Android incremental publishing requires Android SDK build-tools and Java")
    identity = api(f"contents/android/signing-certificate.sha256?ref={run['head_sha']}")
    certificate = base64.b64decode(identity["content"]).decode("ascii").strip().lower()
    proof = verify_android_signing.verify_apk(apk_path, Path(sdk), java, certificate, version)
    if not proof["signatureVerified"] or proof["versionCode"] != version:
        raise ValueError("Signed Android APK version does not match the verified build run number")
    base_url = f"https://github.com/{REPO}/releases/download/oculum-build-{run['id']}"
    manifest = oculum_android_incremental_publish.build_android_range_manifest(
        apk_path, commit=run["head_sha"], run_id=run["id"], android_version_code=version,
        package={"url": f"{base_url}/{ANDROID_APK_ASSET}", "bytes": proof["apkBytes"],
                 "sha256": proof["apkSha256"]}, repository=REPO,
    )
    raw = oculum_android_incremental_publish.serialize_android_range_manifest(manifest)
    if not 0 < len(raw) <= MAX_INCREMENTAL_MANIFEST_BYTES:
        raise ValueError("Android range manifest exceeds the distribution limit")
    manifest_path = output / ANDROID_MANIFEST_ASSET
    manifest_path.write_bytes(raw)
    catalog = {"artifact": "Oculum-Android", "edition": "android",
               "url": f"{base_url}/{ANDROID_MANIFEST_ASSET}", "bytes": len(raw),
               "sha256": "sha256:" + hashlib.sha256(raw).hexdigest(),
               "package": {**manifest["apk"], "sha256": "sha256:" + proof["apkSha256"]}}
    return manifest, raw, catalog


def matching_android_assets(released, catalog):
    """Check existing assets without replacing any published bytes."""
    expected = {ANDROID_MANIFEST_ASSET: catalog, ANDROID_APK_ASSET: catalog["package"]}
    matched = set()
    for asset in (released or {}).get("assets", []):
        name = asset.get("name")
        if name not in expected:
            continue
        entry = expected[name]
        if (name in matched or asset.get("state") != "uploaded"
                or (asset.get("browser_download_url"), asset.get("size"), asset.get("digest"))
                != (entry["url"], entry["bytes"], entry["sha256"])):
            raise ValueError(f"Existing Android incremental asset differs: {name}")
        matched.add(name)
    return matched


def _android_public_asset(opener, url, size, digest, *, position=None, apk_size=None):
    headers = {"Accept-Encoding": "identity", "Cache-Control": "no-cache",
               "User-Agent": "Oculum-public-range-check"}
    if position is not None:
        end = position + size - 1
        headers["Range"] = f"bytes={position}-{end}"
    for delay in (2, 5, None):
        try:
            with opener.open(Request(url, headers=headers), timeout=60) as response:
                if response.headers.get("Content-Encoding", "identity").lower() != "identity":
                    raise ValueError("Public Android asset uses unexpected content encoding")
                if position is None and response.status != 200:
                    raise ValueError("Public Android manifest is unavailable")
                if position is not None and (response.status != 206
                        or response.headers.get("Content-Range") != f"bytes {position}-{end}/{apk_size}"):
                    raise ValueError("Public Android APK did not return the exact partial range")
                raw = response.read(size + 1)
            if len(raw) != size or hashlib.sha256(raw).hexdigest() != digest:
                raise ValueError("Public Android incremental bytes differ from the verified artifact")
            return raw
        except (URLError, TimeoutError) as error:
            if delay is None or (isinstance(error, HTTPError) and error.code not in {408, 429, 500, 502, 503, 504}):
                raise RuntimeError("Anonymous Android incremental asset request failed") from error
            sleep(delay)


def verify_public_android_incremental(manifest, raw, catalog):
    """Verify the exact manifest and multiple signed-APK ranges anonymously."""
    opener = build_opener(oculum_incremental_publish._GithubRedirect())
    downloaded = _android_public_asset(
        opener, catalog["url"], catalog["bytes"], catalog["sha256"].removeprefix("sha256:"),
    )
    if downloaded != raw or json.loads(downloaded) != manifest:
        raise ValueError("Public Android range manifest does not match the verified build")
    segments = manifest["segments"]
    first_member = next((segment for segment in segments if "member" in segment), None)
    if first_member is None or len(segments) < 3 or "member" in segments[-1]:
        raise ValueError("Too few APK regions to verify published Range support")
    package = manifest["apk"]
    for segment in (segments[0], first_member, segments[-1]):
        _android_public_asset(opener, package["url"], segment["bytes"], segment["sha256"],
                              position=segment["offset"], apk_size=package["bytes"])


def read_incremental_release_assets(released, tag, revision, run_id, expected):
    """Bind each public index to its exact verified runtime archive and edition."""
    by_name = {asset["name"]: asset for asset in released.get("assets", [])}
    found = []
    for archive, (edition, artifact) in WINDOWS_RUNTIMES.items():
        filename = oculum_incremental_publish.windows_manifest_asset_name(edition)
        asset = by_name.get(filename)
        if asset is None:
            continue
        url = f"https://github.com/{REPO}/releases/download/{tag}/{filename}"
        length, checksum = asset.get("size"), asset.get("digest")
        if (asset.get("state") != "uploaded" or asset.get("browser_download_url") != url
                or type(length) is not int or not 0 < length <= MAX_INCREMENTAL_MANIFEST_BYTES
                or not re.fullmatch(r"sha256:[0-9a-f]{64}", checksum or "")):
            raise ValueError(f"Invalid incremental asset metadata: {filename}")
        request = Request(url, headers={"User-Agent": "Oculum-public-download-check"})
        with urlopen(request, timeout=30) as response:
            raw = response.read(length + 1)
        if len(raw) != length or "sha256:" + hashlib.sha256(raw).hexdigest() != checksum:
            raise ValueError(f"Incremental manifest integrity check failed: {filename}")
        manifest = json.loads(raw)
        package = expected[archive]
        if (manifest.get("schemaVersion") != 1 or manifest.get("platform") != "windows"
                or manifest.get("edition") != edition or manifest.get("commit") != revision
                or manifest.get("runId") != int(run_id)
                or manifest.get("package") != {"url": package["url"], "bytes": package["bytes"],
                                                "sha256": package["sha256"].removeprefix("sha256:")}
                or not manifest.get("files")):
            raise ValueError(f"Incremental manifest does not match the build: {filename}")
        found.append({"artifact": artifact, "edition": edition, "url": url,
                      "bytes": length, "sha256": checksum})
    return found


def read_compiled_windows_bootstrap(revision):
    scripts = {}
    for name in WINDOWS_BOOTSTRAP_SCRIPTS:
        query = urlencode({"ref": revision})
        try:
            file = api(f"contents/assets/update/{name}?{query}")
        except subprocess.CalledProcessError as error:
            if b"404" in (error.stderr or b""):
                return {}  # a historical build can still publish complete packages
            raise
        if file.get("encoding") != "base64" or type(file.get("size")) is not int:
            raise ValueError(f"Unverified bundled updater source: {name}")
        blob = base64.b64decode(file["content"])
        if not 0 < len(blob) == file["size"] <= 128 * 1024:
            raise ValueError(f"Unexpected bundled updater source size: {name}")
        scripts[name] = blob
    return scripts


def build_windows_bootstrap_zip(path, scripts, tag):
    with ZipFile(path, "w", compression=ZIP_DEFLATED, compresslevel=9) as bundle:
        for name in WINDOWS_BOOTSTRAP_SCRIPTS:
            info = ZipInfo(name)
            bundle.writestr(info, scripts[name], compress_type=ZIP_DEFLATED, compresslevel=9)
    with path.open("rb") as stream:
        digest = "sha256:" + hashlib.file_digest(stream, "sha256").hexdigest()
    return {"name": WINDOWS_BOOTSTRAP_ASSET.removesuffix(".zip"), "bytes": path.stat().st_size,
            "sha256": digest, "url": f"https://github.com/{REPO}/releases/download/{tag}/{path.name}"}


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
        if bootstrap := item.get("windowsIncrementalBootstrap"):
            lines.append(f"- [Aggiornamento incrementale per installazioni Windows esistenti]({bootstrap['url']})")
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
    query = urlencode({"branch": PUBLIC_BRANCH, "status": "success", "per_page": 20})
    runs = api(f"actions/workflows/build_distribution.yml/runs?{query}").get("workflow_runs", [])
    for run in runs:
        if (run.get("status") == "completed" and run.get("conclusion") == "success"
                and run.get("head_branch") == PUBLIC_BRANCH
                and run.get("event") not in {"pull_request", "pull_request_target"}
                and run.get("head_repository", {}).get("full_name") == REPO
                and type(run.get("id")) is int and run["id"] > 0):
            return str(run["id"])
    raise ValueError("No successful trusted Build distribution available to publish")


def publish(run_id, *, incremental_updates=False, android_incremental_updates=False):
    run_id = resolve_run_id(run_id)
    run = api(f"actions/runs/{run_id}")
    workflow = api(f"actions/workflows/{run['workflow_id']}")
    validate_run(run, workflow)
    if android_incremental_updates:
        if (run["head_branch"] != PUBLIC_BRANCH or type(run.get("id")) is not int
                or str(run["id"]) != run_id or resolve_run_id(None) != run_id):
            raise ValueError("Android incremental publishing requires the latest verified main build")
        if type(run.get("run_number")) is not int or not 0 < run["run_number"] < (2 ** 31) - 100000:
            raise ValueError("Latest main build lacks a valid Android run number")
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
    bootstrap_scripts = read_compiled_windows_bootstrap(run["head_sha"]) if incremental_updates else {}
    existing = release(tag)
    present = set()
    existing_indices = set()
    if existing:
        # A previously published full mirror can be re-indexed in place. Do
        # not add, remove or replace its internal artifacts.
        existing_names = {asset.get("name") for asset in existing.get("assets", [])}
        existing_indices = existing_names & WINDOWS_MANIFEST_NAMES
        for artifact in artifacts:
            name = artifact.get("name")
            if name in LEGACY_ARCHIVES and name + ".zip" in existing_names:
                expected[name + ".zip"] = archive_entry(artifact, tag)
        present = verified_release_assets(existing, tag, run["head_sha"], expected)
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        android = None
        android_archive_path = root / "Oculum-Android.zip"
        if android_incremental_updates:
            android_artifact = next(artifact for artifact in selected if artifact["name"] == "Oculum-Android")
            download_verified_archive(android_artifact, expected[android_archive_path.name], android_archive_path)
            android = prepare_android_incremental(android_archive_path, root, run)
            matching_android_assets(existing, android[2])
            if android_archive_path.name in present:
                android_archive_path.unlink()
        if not existing:
            gh("release", "create", tag, "--repo", REPO, "--target", run["head_sha"],
               "--title", f"{run['name']} — {run['head_sha'][:7]}", "--prerelease",
               "--latest=false", "--notes", f"Verified build: {run['html_url']}")
        for artifact, entry in zip(selected, entries, strict=True):
            filename = entry["name"] + ".zip"
            incremental = WINDOWS_RUNTIMES.get(filename)
            make_index = (
                bootstrap_scripts and incremental
                and oculum_incremental_publish.windows_manifest_asset_name(incremental[0]) not in existing_indices
            )
            if filename in present and not make_index:
                continue
            path = root / filename
            if path != android_archive_path or not android_incremental_updates:
                download_verified_archive(artifact, entry, path)
            if filename not in present:
                gh("release", "upload", tag, str(path), "--repo", REPO)
            if make_index:
                edition, _ = incremental
                try:
                    manifest = oculum_incremental_publish.build_windows_range_manifest(
                        path, edition=edition, commit=run["head_sha"],
                        run_id=int(run_id), package=entry, repository=REPO,
                    )
                    oculum_incremental_publish.verify_public_archive_ranges(manifest, path)
                except (BadZipFile, URLError, TimeoutError, ValueError, RuntimeError) as error:
                    print(f"Incremental option unavailable for {edition}; full package retained: {error}")
                else:
                    manifest_path = root / oculum_incremental_publish.windows_manifest_asset_name(edition)
                    manifest_path.write_bytes(oculum_incremental_publish.serialize_windows_range_manifest(manifest))
                    gh("release", "upload", tag, str(manifest_path), "--repo", REPO)
            path.unlink()
        published = release(tag)
        if verified_release_assets(published, tag, run["head_sha"], expected) != set(expected):
            raise ValueError("Versioned release is missing verified assets")
        try:
            incremental_entries = read_incremental_release_assets(published, tag, run["head_sha"], run_id, expected)
        except (URLError, TimeoutError, ValueError, TypeError) as error:
            print(f"Incremental index could not be verified; complete packages retained: {error}")
            incremental_entries = []
        bootstrap = None
        if bootstrap_scripts and len(incremental_entries) == len(WINDOWS_RUNTIMES):
            bootstrap_path = root / WINDOWS_BOOTSTRAP_ASSET
            bootstrap = build_windows_bootstrap_zip(bootstrap_path, bootstrap_scripts, tag)
            if not any(asset["name"] == WINDOWS_BOOTSTRAP_ASSET for asset in published["assets"]):
                gh("release", "upload", tag, str(bootstrap_path), "--repo", REPO)
                published = release(tag)
            item, = [asset for asset in published["assets"] if asset["name"] == WINDOWS_BOOTSTRAP_ASSET]
            if (item["state"], item["size"], item["digest"], item["browser_download_url"]) != (
                    "uploaded", bootstrap["bytes"], bootstrap["sha256"], bootstrap["url"]):
                raise ValueError("Existing Windows incremental updater does not match the compiled source")
            verify_anonymous_download(bootstrap, item.get("id"))
        asset_ids = {asset["name"]: asset.get("id") for asset in published["assets"]}
        for entry in entries:
            verify_anonymous_download(entry, asset_ids[entry["name"] + ".zip"])
        if run["head_branch"] != PUBLIC_BRANCH:
            print(f"Archived {len(entries)} verified artifacts for {run['head_branch']}; public channel unchanged")
            return
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
        if android is not None:
            android_manifest, android_raw, android_entry = android
            already_present = matching_android_assets(published, android_entry)
            for filename in (ANDROID_APK_ASSET, ANDROID_MANIFEST_ASSET):
                if filename not in already_present:
                    gh("release", "upload", tag, str(root / filename), "--repo", REPO)
            published = release(tag)
            if (verified_release_assets(published, tag, run["head_sha"], expected) != set(expected)
                    or matching_android_assets(published, android_entry) != ANDROID_INCREMENTAL_ASSETS):
                raise ValueError("Versioned release is missing verified Android incremental assets")
            verify_public_android_incremental(android_manifest, android_raw, android_entry)
            incremental_entries.append(android_entry)
        elif any(item.get("runId") == run["id"] and item.get("commit") == run["head_sha"]
                 and any(entry.get("edition") == "android" for entry in item.get("incremental", []))
                 for item in catalog.values()):
            # A repeated automatic job must preserve an explicitly verified opt-in on this exact build.
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
            "incremental": incremental_entries,
        }}
        if bootstrap:
            catalog[str(workflow_id)]["windowsIncrementalBootstrap"] = bootstrap
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
    publish(sys.argv[1], incremental_updates="--incremental-windows" in sys.argv[2:],
            android_incremental_updates="--incremental-android" in sys.argv[2:])
