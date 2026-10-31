"""Copy the eighteen approved PNGs without modifying pixels or old assets."""
import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "output/artwork/derivati_scelte_2026-10-31/manifest_pacchetti_approvati.json"
RECEIPT = ROOT / "design/approved-six-monster-packs-2026-10-31.json"


def main():
    packs = json.loads(SOURCE.read_text(encoding="utf-8"))["packs"]
    assert len(packs) == len({p["id"] for p in packs}) == 6
    files = []
    for pack in packs:
        for kind, prefix, suffix in (
            ("desktop", "theme", ""),
            ("phone", "theme", "_mobile"),
            ("relic", "relic", ""),
        ):
            record = pack[kind]
            assert record["user_approved"] is True
            source = ROOT / record["canonical_copy"]
            data = source.read_bytes()
            digest = hashlib.sha256(data).hexdigest()
            assert digest == record["sha256"], source
            asset = f"assets/oculum/home_art/{prefix}_{pack['id']}{suffix}_canon_20261031.png"
            target = ROOT / asset
            if target.exists() and target.read_bytes() != data:
                raise RuntimeError(f"Refusing to replace different existing asset: {target}")
            shutil.copyfile(source, target)
            assert target.read_bytes() == data
            files.append({
                "species": pack["id"], "kind": kind, "asset": asset,
                "sha256": digest, "bytes": len(data),
                "source": record["output_path"],
                "revision": record.get("revision"),
                "user_approved": True,
                "approval_quote": record.get("approval_quote", pack.get("approval_quote", "")),
                "decorative_only": True,
            })
    RECEIPT.write_text(json.dumps({
        "date": "2026-10-31", "provider": "builtin image_gen.imagegen",
        "scope": "Six approved desktop/phone/relic packs; no new drops or powers.",
        "files": files,
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Copied and SHA-verified {len(files)} approved PNGs; existing assets preserved.")


if __name__ == "__main__":
    main()
