"""Build a self-contained local review page without copying any artwork."""

import argparse
import json
from pathlib import Path
import re


PROPOSAL_CATEGORIES = {
    **dict.fromkeys("ABCDEF", "new_ink"),
    "G": "new_distant",
    "H": "alternate_palette",
}
SHA256 = re.compile(r"[a-fA-F0-9]{64}")


def hide_deleted_proposals(manifest, directory):
    receipt_path = directory / "RIFIUTI-RICEVUTE.json"
    deleted = set()
    if receipt_path.is_file():
        receipt = json.loads(receipt_path.read_text(encoding="utf-8-sig"))
        if receipt.get("schemaVersion") != 1 or receipt.get("batchId") != manifest["batchId"]:
            raise ValueError("Ricevuta rifiuti incompatibile con il lotto")
        deleted = {
            (row["id"], row["slot"], row["sha256"])
            for row in receipt["decisions"]
            if row["state"] == "deleted" and row["revision"] <= manifest["revision"]
        }
    hidden = []
    for entry in manifest["entries"]:
        if entry.get("artworkReviewClosed") is True:
            continue
        identifier = entry["id"]
        for slot in entry.get("slots", []):
            artwork = slot.get("artwork") or {}
            letter = slot.get("slot")
            if slot.get("status") == "rejected_deleted" and not artwork:
                for key in ("choiceCleanup", "removedArtwork"):
                    record = slot.get(key)
                    sha256 = record.get("sha256") if isinstance(record, dict) else None
                    if isinstance(sha256, str) and SHA256.fullmatch(sha256):
                        hidden.append({"id": identifier, "slot": letter, "sha256": sha256})
                        break
                continue
            if (
                letter not in PROPOSAL_CATEGORIES
                or slot.get("status") != "verified_new"
                or slot.get("category") != PROPOSAL_CATEGORIES[letter]
                or artwork.get("receipt")
                or (identifier, letter, artwork.get("sha256")) not in deleted
            ):
                continue
            expected = directory / f"{identifier}-{letter.lower()}.webp"
            if Path(artwork.get("path", "")) != expected or expected.exists():
                continue
            hidden.append({"id": identifier, "slot": letter, "sha256": artwork["sha256"]})
            slot.pop("artwork")
            slot["status"] = "rejected_deleted"
    manifest.pop("galleryDeletedImages", None)
    if hidden:
        manifest["galleryDeletedImages"] = hidden


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    args = parser.parse_args()
    manifest = json.loads(args.manifest.read_text(encoding="utf-8-sig"))
    if not isinstance(manifest.get("entries"), list) or not manifest.get("batchId"):
        parser.error("The manifest must contain a batch ID and an entries list.")
    hide_deleted_proposals(manifest, args.manifest.absolute().parent)
    template = Path(__file__).with_name("expressive_ink_gallery.html")
    source = json.dumps(manifest, ensure_ascii=False, separators=(",", ":"))
    # A raw-text script node must survive literal markup in editable names.
    source = source.replace("<", "\\u003c").replace(">", "\\u003e").replace("&", "\\u0026")
    html = template.read_text(encoding="utf-8").replace("__EXPRESSIVE_INK_MANIFEST__", source, 1)
    destination = args.manifest.with_name("GALLERIA.html")
    temporary = destination.with_suffix(".html.tmp")
    temporary.write_text(html, encoding="utf-8")
    temporary.replace(destination)
    print(destination.resolve())


if __name__ == "__main__":
    main()
