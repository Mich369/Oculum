"""Copy only human-approved selections, preserving originals and byte hashes."""
import hashlib
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
DRAFTS = ROOT / "output/artwork/drafts_2026-10-29"
ASSETS = ROOT / "assets/oculum/home_art"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    selections = []
    for creature, desktop, phone, relic in [
        ("funghetto_cappuccio_rosso", 1, "phone", 2),
        ("costrutto_minore", 1, "phone", 2),
        ("shadow_devil", 1, "phone", 2),
        ("mostro_sabbia", 2, "phone", 2),
        ("gigante_sabbia", 6, "mobile", 1),
    ]:
        selections.extend([
            (creature, "desktop", f"{creature}_background_draft_v{desktop}.png",
             f"theme_{creature}_v1.png"),
            (creature, "phone", f"{creature}_{phone}_draft_v1.png",
             f"theme_{creature}_mobile_v1.png"),
            (creature, "relic", f"{creature}_relic_draft_v{relic}.png",
             f"relic_{creature}_v1.png"),
        ])
    for creature, version in [("sharp", 3), ("topino_avventuroso", 2), ("mosca_campana", 3)]:
        selections.append((creature, "desktop",
            f"{creature}_background_draft_v{version}.png", f"theme_{creature}_v1.png"))
    selection_file = ROOT / "output/artwork/proposte_prossima_patch_2026-10-29/selezione_canonica_cinque_2026-10-29.json"
    if selection_file.exists():
        selection = json.loads(selection_file.read_text(encoding="utf-8"))
        if selection.get("approval_quote") != "Sì, queste cinque sono canoniche":
            raise RuntimeError("Missing explicit human approval for the five desktop selections")
        for item in selection["files"]:
            source = ROOT / item["output_path"]
            if digest(source) != item["sha256"]:
                raise RuntimeError(f"Selected artwork changed: {source}")
            selections.append((item["id"], "desktop",
                str(source), f"theme_{item['id']}_v1.png"))
    derivatives_file = ROOT / "output/artwork/proposte_prossima_patch_2026-10-29/derivati_canonici_cinque/manifest_derivati_cinque.json"
    if derivatives_file.exists():
        derivatives = json.loads(derivatives_file.read_text(encoding="utf-8"))
        if derivatives["counts"].get("derivative_user_approved") == 10:
            approved_ids = {item["id"] for item in selection["files"]}
            for entry in derivatives["entries"]:
                if entry["id"] not in approved_ids:
                    raise RuntimeError("Derivative belongs to a different selection")
                for item in entry["derivatives"]:
                    if item.get("user_approved") is not True:
                        raise RuntimeError("Unapproved derivative in selected pack")
                    source = ROOT / item["output_path"]
                    if digest(source) != item["sha256"]:
                        raise RuntimeError(f"Derivative changed: {source}")
                    kind = item["kind"]
                    asset = (f"theme_{entry['id']}_mobile_v1.png" if kind == "phone"
                             else f"relic_{entry['id']}_v1.png")
                    selections.append((entry["id"], kind, str(source), asset))
    records = []
    for creature, kind, source_name, asset_name in selections:
        source = (DRAFTS / source_name).resolve()
        if not source.is_relative_to(ROOT) or source.suffix.lower() != ".png":
            raise RuntimeError(f"Artwork source is outside the project: {source}")
        target = ASSETS / asset_name
        source_hash = digest(source)
        if target.exists() and digest(target) != source_hash:
            raise RuntimeError(f"Refusing to overwrite different artwork: {target}")
        if not target.exists():
            shutil.copyfile(source, target)
        if digest(target) != source_hash:
            raise RuntimeError(f"Copy mismatch: {target}")
        records.append({"monsterId": creature, "kind": kind,
            "approvedSource": source.relative_to(ROOT).as_posix(),
            "runtimeAsset": target.relative_to(ROOT).as_posix(),
            "sha256": source_hash, "bytes": target.stat().st_size,
            "humanApproved": True})
    report = {"schemaVersion": 1, "date": "2026-10-29", "selections": records,
        "note": "Byte copy only; only explicitly approved selections are canonical. Renderer/CI/package checks are separate."}
    output = ROOT / "output/artwork/APPROVED_NEXT_PATCH_ASSETS_2026-10-29.json"
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Verified {len(records)} approved copies; report: {output.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
