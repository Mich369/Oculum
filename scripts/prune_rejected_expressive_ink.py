"""Record gallery decisions and prune only expired, unchanged WebP candidates."""

import argparse
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import tempfile


ROOT = Path(__file__).absolute().parents[1]
BATCH_ID = "expressive_ink_lotto_01"
BATCH_PATH = Path("output", "artwork", BATCH_ID)
RECEIPT = "RIFIUTI-RICEVUTE.json"
WAIT_TIME = timedelta(minutes=60)
IMAGE_ID = re.compile(r"[a-z0-9_]+")
SHA256 = re.compile(r"[a-f0-9]{64}")
NEW_SLOT_CATEGORIES = {
    **dict.fromkeys("ABCDEF", "new_ink"),
    "G": "new_distant",
    "H": "alternate_palette",
}
METADATA = {
    ".csv", ".dart", ".htm", ".html", ".json", ".jsonl", ".md", ".ps1",
    ".py", ".toml", ".txt", ".xml", ".yaml", ".yml",
}


def is_link(info):
    return stat.S_ISLNK(info.st_mode) or bool(
        getattr(info, "st_file_attributes", 0) & stat.FILE_ATTRIBUTE_REPARSE_POINT
    )


def ordinary_file(path):
    info = path.lstat()
    if is_link(info) or not stat.S_ISREG(info.st_mode) or info.st_nlink != 1:
        raise ValueError(f"File non ordinario o condiviso: {path}")
    return info


def json_object(path):
    ordinary_file(path)
    with path.open(encoding="utf-8-sig") as stream:
        value = json.load(stream)
    if not isinstance(value, dict):
        raise ValueError(f"Oggetto JSON richiesto: {path}")
    return value


def check_batch(root):
    directory = root
    for part in BATCH_PATH.parts:
        directory /= part
        info = directory.lstat()
        if is_link(info) or not stat.S_ISDIR(info.st_mode):
            raise ValueError(f"Cartella del lotto non ordinaria: {directory}")
    if directory.resolve(strict=True) != directory:
        raise ValueError(f"Percorso fisico diverso dal lotto: {directory}")
    return directory


def utc_time(value):
    if not isinstance(value, str) or not value.endswith("Z"):
        raise ValueError("Istante UTC mancante")
    return datetime.fromisoformat(value.removesuffix("Z") + "+00:00")


def utc_string(value):
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def same_identity(a, b):
    return (a.st_dev, a.st_ino, a.st_size, a.st_mtime_ns) == (
        b.st_dev, b.st_ino, b.st_size, b.st_mtime_ns
    )


def read_manifest(batch):
    manifest = json_object(batch / "MANIFEST.json")
    revision = manifest.get("revision")
    if (
        manifest.get("schemaVersion") != 1 or manifest.get("batchId") != BATCH_ID
        or type(revision) is not int or revision < 1
    ):
        raise ValueError("Manifest del lotto non riconosciuto")
    slots = {}
    for entry in [*manifest["entries"], *manifest.get("referenceEntries", [])]:
        if not isinstance(entry["id"], str) or not IMAGE_ID.fullmatch(entry["id"]):
            raise ValueError("Identificatore mostro non riconosciuto")
        for slot in entry["slots"]:
            key = (entry["id"], slot["slot"])
            if key in slots or key[1] not in NEW_SLOT_CATEGORIES:
                raise ValueError("Posizione immagine non riconosciuta o duplicata")
            slots[key] = {**slot, "reviewClosed": entry.get("artworkReviewClosed") is True}
    return revision, slots


def candidate_path(batch, key, slot, sha256):
    category = NEW_SLOT_CATEGORIES.get(key[1])
    if (
        category is None
        or slot.get("category") != category
        or slot.get("reviewClosed")
        or slot.get("status") != "verified_new"
        or not isinstance(sha256, str) or not SHA256.fullmatch(sha256)
    ):
        return None
    artwork = slot.get("artwork", {})
    path = batch / f"{key[0]}-{key[1].lower()}.webp"
    declared = artwork.get("path")
    if (
        artwork.get("sha256") != sha256 or not isinstance(declared, str)
        or Path(declared) != path or type(artwork.get("bytes")) is not int
        or artwork["bytes"] <= 0
        or artwork.get("receipt")
    ):
        return None
    return path


def read_receipt(batch):
    try:
        receipt = json_object(batch / RECEIPT)
    except FileNotFoundError:
        return {"schemaVersion": 1, "batchId": BATCH_ID, "chosenHashes": [], "decisions": []}
    if (
        receipt.get("schemaVersion") != 1 or receipt.get("batchId") != BATCH_ID
        or not isinstance(receipt.get("decisions"), list)
        or not isinstance(receipt.get("chosenHashes"), list)
    ):
        raise ValueError("Ricevuta del lotto non riconosciuta")
    return receipt


def write_receipt(batch, receipt):
    destination = batch / RECEIPT
    try:
        ordinary_file(destination)
    except FileNotFoundError:
        pass
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", newline="\n", prefix=".rifiuti-",
        suffix=".tmp", dir=batch, delete=False,
    ) as stream:
        temporary = Path(stream.name)
        try:
            json.dump(receipt, stream, ensure_ascii=False, indent=2)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        except BaseException:
            stream.close()
            temporary.unlink()
            raise
    try:
        temporary.replace(destination)
    finally:
        temporary.unlink(missing_ok=True)


@contextmanager
def lock_batch(batch):
    lock = batch / ".rifiuti.lock"
    try:
        ordinary_file(lock)
    except FileNotFoundError:
        pass
    # The OS releases the lock when the process exits, including after a crash.
    with lock.open("a+b") as stream:
        if not same_identity(ordinary_file(lock), os.fstat(stream.fileno())):
            raise ValueError("File di blocco del lotto sostituito")
        stream.seek(0)
        if os.name == "nt":
            import msvcrt

            msvcrt.locking(stream.fileno(), msvcrt.LK_NBLCK, 1)
        else:
            import fcntl

            fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
        yield


def vote_snapshot(batch, slots, revision, source, now):
    payload = json_object(source)
    if (
        payload.get("batchId") != BATCH_ID or payload.get("revision") != revision
        or not isinstance(payload.get("votes"), list)
    ):
        raise ValueError("La bozza deve appartenere alla revisione corrente del lotto")
    exported_at = payload.get("exportedAtUtc")
    latest_decision = now if exported_at is None else utc_time(exported_at)
    if latest_decision > now:
        raise ValueError("Il momento di esportazione della bozza è futuro")
    rejected = {}
    chosen_hashes = set()
    seen_ids = set()
    for vote in payload["votes"]:
        monster = vote["id"]
        if (
            vote.get("batchId") != BATCH_ID or vote.get("revision") != revision
            or monster in seen_ids or not any(key[0] == monster for key in slots)
        ):
            raise ValueError("Voto fuori lotto, duplicato o obsoleto")
        seen_ids.add(monster)
        selected = vote.get("slot")
        if selected is not None:
            artwork = slots.get((monster, selected), {}).get("artwork", {})
            sha256 = vote.get("sha256")
            if not isinstance(sha256, str) or not SHA256.fullmatch(sha256) or artwork.get("sha256") != sha256:
                raise ValueError("La scelta non corrisponde al manifest")
            chosen_hashes.add(sha256)
        for record in vote.get("rejections", []):
            key = (monster, record["slot"])
            sha256 = record.get("sha256")
            rejected_at = record["rejectedAt"]
            if (
                selected == key[1] or key in rejected or utc_time(rejected_at) > latest_decision
                or candidate_path(batch, key, slots.get(key, {}), sha256) is None
            ):
                raise ValueError("Rifiuto in conflitto, fuori lotto o con immagine cambiata")
            rejected[key] = (sha256, rejected_at)
    return rejected, chosen_hashes, exported_at


def record_snapshot(batch, slots, revision, receipt, source, now):
    rejected, chosen_hashes, exported_at = vote_snapshot(batch, slots, revision, source, now)
    previous_export = receipt.get("exportedAtUtc")
    if previous_export is not None and (
        exported_at is None or utc_time(exported_at) < utc_time(previous_export)
    ):
        raise ValueError("Una bozza più recente è già stata registrata")
    if exported_at is not None:
        receipt["exportedAtUtc"] = exported_at
    receipt["chosenHashes"] = sorted(chosen_hashes.union(receipt["chosenHashes"]))
    stamp = utc_string(now)
    for record in receipt["decisions"]:
        if record["state"] != "pending":
            continue
        key = (record["id"], record["slot"])
        if (
            record["revision"] == revision
            and rejected.get(key) == (record["sha256"], record["rejectedAt"])
            and record["sha256"] not in receipt["chosenHashes"]
        ):
            del rejected[key]
        else:
            record.update(state="revoked", resolvedAt=stamp)
    for (monster, slot), (sha256, rejected_at) in rejected.items():
        if sha256 in receipt["chosenHashes"]:
            continue
        receipt["decisions"].append({
            "id": monster, "slot": slot, "sha256": sha256, "revision": revision,
            "rejectedAt": rejected_at, "receivedAt": stamp, "state": "pending",
        })
    write_receipt(batch, receipt)


def tracked_artwork(root):
    result = subprocess.run(
        ["git", "-C", str(root), "ls-files", "-z", "--", BATCH_PATH.as_posix()],
        capture_output=True, check=True,
    )
    return {os.fsdecode(item).casefold() for item in result.stdout.split(b"\0") if item}


def cross_references(root, batch, candidates):
    tokens = {
        token: path
        for record, path in candidates
        for token in (path.name.casefold().encode(), record["sha256"].encode())
    }
    if not tokens:
        return set()
    pattern = re.compile(rb"|".join(re.escape(token) for token in tokens), re.IGNORECASE)
    found = set()
    directories = ("docs", "design", "assets", "lib", "scripts", ".github")
    for base in (*(root / name for name in directories), batch.parent):
        if not base.exists():
            continue
        if is_link(base.lstat()):
            raise ValueError(f"Cartella dei riferimenti non ordinaria: {base}")
        for directory, dirs, files in os.walk(base, followlinks=False, onerror=raise_scan_error):
            folder = Path(directory)
            dirs[:] = [name for name in dirs if not is_link((folder / name).lstat())]
            for name in files:
                path = folder / name
                if path.suffix.lower() not in METADATA:
                    continue
                if folder == batch and name in {"MANIFEST.json", "GALLERIA.html", RECEIPT}:
                    continue
                info = path.lstat()
                if is_link(info) or not stat.S_ISREG(info.st_mode):
                    continue
                with path.open("rb") as stream:
                    for match in pattern.finditer(stream.read()):
                        found.add(tokens[match.group().lower()])
    return found


def raise_scan_error(error):
    raise error


def matches_content(path, slot, sha256):
    info = ordinary_file(path)
    with path.open("rb") as stream:
        opened = os.fstat(stream.fileno())
        if not same_identity(info, opened):
            return None
        check = hashlib.file_digest(stream, "sha256").hexdigest()
        unchanged = same_identity(opened, os.fstat(stream.fileno()))
    if unchanged and info.st_size == slot["artwork"]["bytes"] and check == sha256:
        return info
    return None


def prune(root, batch, slots, revision, receipt, now, apply):
    protected = set(receipt["chosenHashes"])
    candidates = []
    for record in receipt["decisions"]:
        if record["state"] != "pending" or record["revision"] != revision:
            continue
        if now - utc_time(record["receivedAt"]) < WAIT_TIME:
            continue
        key = (record["id"], record["slot"])
        sha256 = record["sha256"]
        slot = slots.get(key, {})
        path = candidate_path(batch, key, slot, sha256)
        if path is None or sha256 in protected:
            continue
        if any(
            other.get("artwork", {}).get("sha256") == sha256
            or Path(other.get("artwork", {}).get("path", "")) == path
            for other_key, other in slots.items() if other_key != key
        ):
            continue
        candidates.append((record, path))
    if not candidates:
        return []

    tracked = tracked_artwork(root)
    references = cross_references(root, batch, candidates)
    eligible = []
    for record, path in candidates:
        if path.relative_to(root).as_posix().casefold() in tracked or path in references:
            continue
        slot = slots[(record["id"], record["slot"])]
        try:
            info = matches_content(path, slot, record["sha256"])
        except (OSError, ValueError):
            continue
        if info is None:
            continue
        if apply:
            check_batch(root)
            current_revision, current_slots = read_manifest(batch)
            if current_revision != revision or current_slots != slots:
                raise ValueError("Manifest modificato durante la pulizia")
            if not same_identity(info, ordinary_file(path)):
                continue
            record.update(state="deleting", verifiedAt=utc_string(now), bytes=info.st_size)
            write_receipt(batch, receipt)
            if not same_identity(info, ordinary_file(path)):
                record.update(state="pending")
                write_receipt(batch, receipt)
                continue
            path.unlink()
            record.update(state="deleted", resolvedAt=utc_string(now))
            write_receipt(batch, receipt)
        eligible.append((path, info.st_size))
    return eligible


def complete_interrupted(batch, receipt, now):
    for record in receipt["decisions"]:
        if record["state"] != "deleting":
            continue
        if not IMAGE_ID.fullmatch(record["id"]) or record["slot"] not in NEW_SLOT_CATEGORIES:
            raise ValueError("Destinazione non valida nella ricevuta")
        path = batch / f"{record['id']}-{record['slot'].lower()}.webp"
        try:
            path.lstat()
        except FileNotFoundError:
            record.update(state="deleted", resolvedAt=utc_string(now))
        else:
            record.update(state="pending")
        write_receipt(batch, receipt)


def run(root, *, record=None, apply=False, now=None):
    now = now or datetime.now(timezone.utc)
    batch = check_batch(root)
    if record is not None or apply:
        with lock_batch(batch):
            revision, slots = read_manifest(batch)
            receipt = read_receipt(batch)
            complete_interrupted(batch, receipt, now)
            if record is not None:
                record_snapshot(batch, slots, revision, receipt, record, now)
                return []
            return prune(root, batch, slots, revision, receipt, now, apply=True)
    revision, slots = read_manifest(batch)
    return prune(root, batch, slots, revision, read_receipt(batch), now, apply=False)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    actions = parser.add_mutually_exclusive_group()
    actions.add_argument("--record", type=Path, metavar="BOZZA.json", help="Registra l'intera bozza senza cancellare immagini")
    actions.add_argument("--apply", action="store_true", help="Rimuove i rifiuti verificati e scaduti")
    args = parser.parse_args()
    try:
        result = run(ROOT, record=args.record, apply=args.apply)
    except (OSError, ValueError, KeyError, TypeError, subprocess.CalledProcessError) as error:
        parser.exit(2, f"{error}\n")
    if args.record:
        print(f"Bozza registrata in {ROOT / BATCH_PATH / RECEIPT}.")
        return
    for path, size in result:
        print(f"{path.name}\t{size} byte")
    action = "rimossi" if args.apply else "rimovibili in anteprima"
    print(f"{len(result)} file {action}, {sum(size for _, size in result)} byte.")


if __name__ == "__main__":
    main()
