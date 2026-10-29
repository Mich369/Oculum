"""Build a local comparison page; never promote draft derivatives."""
import html
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output/artwork/proposte_prossima_patch_2026-10-29"
SOURCE = OUT / "derivati_canonici_cinque/manifest_derivati_cinque.json"


def main():
    data = json.loads(SOURCE.read_text(encoding="utf-8"))
    sections = []
    for entry in data["entries"]:
        cards = []
        sources = [("Desktop canonico", entry["canonical_desktop"]["path"])]
        sources.extend((("Telefono" if item["kind"] == "phone" else "Reliquia decorativa")
                        + (" · CANONICO" if item.get("user_approved") is True else " · proposta"),
                        item["output_path"]) for item in entry["derivatives"])
        for caption, path in sources:
            target = ROOT / path
            if not target.is_file():
                raise FileNotFoundError(target)
            url = html.escape(target.relative_to(OUT).as_posix(), quote=True)
            cards.append(f'<figure><a href="{url}"><img loading="lazy" src="{url}" alt="{caption}"></a><figcaption>{caption}</figcaption></figure>')
        sections.append(f'<section><h2>{html.escape(entry["id"].replace("_", " ").title())}</h2><div class="cards">{"".join(cards)}</div></section>')
    page = '''<!doctype html><html lang="it"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Oculum — telefono e reliquie</title>
<style>body{max-width:1500px;margin:24px auto;padding:0 18px;background:#15141a;color:#e4d4b0;font:17px system-ui}h1,h2{font-family:Georgia,serif}.cards{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:16px}figure{margin:0;background:#29252c;border:1px solid #645337;border-radius:8px;overflow:hidden}img{width:100%;height:420px;object-fit:contain;display:block}figcaption{padding:12px}section{margin:40px 0}a{color:inherit}p{line-height:1.6;max-width:85ch}@media(max-width:800px){.cards{grid-template-columns:1fr}img{height:auto;max-height:620px}}</style>
<h1>Telefono e reliquie — cinque creature</h1><p>Confronto fra il desktop e i suoi due adattamenti: sfondo telefono e reliquia trasparente. Le selezioni segnate CANONICO sono approvate esplicitamente; la reliquia è decorativa e non aggiunge bonus o drop. Premi un’immagine per vederla intera.</p><p><a href="GALLERIA.html">Torna alle proposte A/B/C</a></p>'''
    (OUT / "GALLERIA_DERIVATI.html").write_text(page + ''.join(sections) + '</html>\n', encoding="utf-8")
    print("Derivative gallery updated from explicit per-image approval records.")


if __name__ == "__main__":
    main()
