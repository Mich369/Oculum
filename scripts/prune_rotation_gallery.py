"""Update a rotation gallery after its rejected plates have been verified."""

import json
from pathlib import Path
import re
import stat


ROTATION_DIRECTORY = re.compile(r'expressive_ink_giro_(\d{8})_(\d{4})')
PAYLOAD = re.compile(r'<script type="application/json" id="galleria-data">(.*?)</script>', re.DOTALL)
ARTICLE = re.compile(r'<article data-id="([a-z0-9_-]+)">(.*?)</article>', re.DOTALL)
PLATE_SELECT = re.compile(r'<select data-slot>(.*?)</select>', re.DOTALL)
PLATE_OPTION = re.compile(r'<option value="([A-H]?)">.*?</option>', re.DOTALL)
PLATE_SLOTS = frozenset('ABCDEFGH')


def _index_lots(data, source):
    if (not isinstance(data, dict) or type(data.get('schemaVersion')) is not int
            or data['schemaVersion'] != 1 or data.get('source') != source
            or not isinstance(data.get('lots'), list)):
        raise ValueError('Formato dei dati della galleria non riconosciuto')
    indexed = {}
    for lot in data['lots']:
        ident = lot.get('id') if isinstance(lot, dict) else None
        if not isinstance(ident, str) or not re.fullmatch(r'[a-z0-9_-]+', ident) or ident in indexed:
            raise ValueError('ID di lotto mancante, non valido o duplicato')
        indexed[ident] = lot
    return indexed


def _plate_options(lot):
    choices = lot.get('choices')
    ident = lot['id']
    if (not isinstance(choices, list) or len(choices) != 1 or not isinstance(choices[0], dict)
            or choices[0].get('surface') != 'desktop' or not isinstance(choices[0].get('options'), list)):
        raise ValueError(f'Opzioni desktop non riconosciute: {ident}')
    by_slot = {}
    for option in choices[0]['options']:
        slot = option.get('slot') if isinstance(option, dict) else None
        if (not isinstance(slot, str) or slot not in PLATE_SLOTS or slot in by_slot
                or option.get('file') != f'{ident}/{slot}.webp'
                or not isinstance(option.get('sha256'), str)
                or not re.fullmatch(r'[a-f0-9]{64}', option['sha256'])):
            raise ValueError(f'Tavola della galleria non valida: {ident}')
        by_slot[slot] = option
    return by_slot


def render_rotation_gallery(directory: Path, rejected: dict[str, set[str]]) -> dict[Path, str]:
    """Return pending file contents and allow interrupted writes to be retried."""
    tag = ROTATION_DIRECTORY.fullmatch(directory.name)
    if tag is None:
        raise ValueError(f'Nome della galleria non riconosciuto: {directory}')
    html_path = directory / 'GALLERIA.html'
    json_path = directory / 'SCELTE.json'
    try:
        for path in (html_path, json_path):
            info = path.lstat()
            if (not stat.S_ISREG(info.st_mode)
                    or getattr(info, 'st_file_attributes', 0) & stat.FILE_ATTRIBUTE_REPARSE_POINT):
                raise ValueError(f'File della galleria non regolare: {path}')
        html = html_path.read_text(encoding='utf-8-sig')
        json_text = json_path.read_text(encoding='utf-8-sig')
    except OSError as error:
        raise ValueError(f'File della galleria non accessibili: {directory}') from error
    scripts = list(PAYLOAD.finditer(html))
    if len(scripts) != 1:
        raise ValueError(f'Payload HTML mancante o duplicato: {html_path}')
    payload = scripts[0]
    gallery = json.loads(payload[1])
    choices = json.loads(json_text)
    source = f'galleria-lotti-{tag[1]}-{tag[2]}'
    gallery_lots = _index_lots(gallery, source)
    choice_lots = _index_lots(choices, source)

    articles = {}
    for article in ARTICLE.finditer(html):
        if article[1] in articles:
            raise ValueError(f'Articolo duplicato: {article[1]}')
        articles[article[1]] = article
    edits = []
    update_payload = update_choices = False
    for ident, removed in rejected.items():
        if (not isinstance(removed, set) or not removed or not removed <= PLATE_SLOTS or ident not in articles
                or ident not in gallery_lots or ident not in choice_lots):
            raise ValueError(f'Articolo o slot dei rifiuti non riconosciuti: {ident}')
        html_lot, json_lot = gallery_lots[ident], choice_lots[ident]
        html_options, json_options = _plate_options(html_lot), _plate_options(json_lot)
        if any(html_options[slot] != json_options[slot] for slot in html_options.keys() & json_options.keys()):
            raise ValueError(f'Dettaglio delle tavole incoerente: {ident}')
        for lot, options in ((html_lot, html_options), (json_lot, json_options)):
            confirmed = lot.get('confirmed')
            if confirmed is not None and (not isinstance(confirmed, dict)
                    or confirmed.get('slot') not in options.keys() - removed):
                raise ValueError(f'La pulizia coinvolge una tavola confermata: {ident}')
            if not (options.keys() - removed):
                raise ValueError(f'La pulizia lascerebbe il lotto senza tavole: {ident}')
            lot['choices'][0]['options'] = [option for slot, option in options.items() if slot not in removed]
        update_payload |= bool(removed & html_options.keys())
        update_choices |= bool(removed & json_options.keys())
        article = articles[ident]
        selects = list(PLATE_SELECT.finditer(article[2]))
        if len(selects) != 1:
            raise ValueError(f'Selettore della tavola mancante o duplicato: {ident}')
        select = selects[0]
        if (PLATE_OPTION.sub('', select[1]).strip()
                or [option[1] for option in PLATE_OPTION.finditer(select[1])] != ['', *html_options]):
            raise ValueError(f'Selettore e dati della galleria discordanti: {ident}')
        updated = PLATE_OPTION.sub(lambda option: '' if option[1] in removed else option[0], select[1])
        body = article[2][:select.start(1)] + updated + article[2][select.end(1):]
        body = body.replace('Apri le otto tavole in formato grande', 'Apri le tavole disponibili in formato grande')
        if body != article[2]:
            edits.append((article.start(2), article.end(2), body))
    if gallery != choices:
        raise ValueError(f'Dati HTML e SCELTE.json discordanti: {directory}')
    result = {}
    if update_payload:
        serialized = json.dumps(gallery, ensure_ascii=False).replace('<', '\\u003c')
        edits.append((payload.start(1), payload.end(1), serialized))
    if edits:
        for start, end, text in sorted(edits, reverse=True):
            html = html[:start] + text + html[end:]
        result[html_path] = html
    if update_choices:
        result[json_path] = json.dumps(choices, ensure_ascii=False, indent=2) + '\n'
    return result
