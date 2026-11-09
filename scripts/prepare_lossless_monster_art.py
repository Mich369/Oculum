"""Derive smaller, pixel-exact WebP copies for the bundled monster artwork."""

from concurrent.futures import ThreadPoolExecutor
from hashlib import sha256
from io import BytesIO
import json
from pathlib import Path, PurePosixPath
import re
import sys

from PIL import Image, features


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = PurePosixPath('assets/oculum/home_art')
RUNTIME_DIR = PurePosixPath('assets/oculum/home_art_webp')
ASSET_MARKER_START = '    # BEGIN generated monster artwork assets\n'
ASSET_MARKER_END = '    # END generated monster artwork assets\n'
OLD_FOLDER_ENTRY = f'    - {SOURCE_DIR}/\n'


def read_candidates(path):
    data = json.loads(path.read_text(encoding='utf-8-sig'))
    if isinstance(data, dict):
        data = [record['original'] for record in data['files']]
    if not isinstance(data, list) or not data:
        raise ValueError('Expected a nonempty list of monster source PNG paths')
    if len(set(data)) != len(data):
        raise ValueError('Duplicate source PNG in artwork inventory')
    for asset in data:
        relative = PurePosixPath(asset)
        if relative.parent != SOURCE_DIR or not re.fullmatch(r'[a-z0-9_-]+\.png', relative.name):
            raise ValueError(f'Unexpected artwork path: {asset}')
        if not (ROOT / relative).is_file():
            raise ValueError(f'Source PNG missing: {asset}')
    return sorted(data)


def exact_webp(source, encoded, properties, pixels):
    with Image.open(BytesIO(encoded)) as decoded:
        if (decoded.format != 'WEBP' or decoded.size != source.size
                or decoded.convert('RGBA').tobytes() != pixels
                or any(decoded.info.get(key) != value for key, value in properties.items())):
            raise ValueError('WebP differs from the original pixels or profile')


def derive(asset):
    original = ROOT / asset
    original_bytes = original.read_bytes()
    runtime = RUNTIME_DIR / (PurePosixPath(asset).stem + '.webp')
    result = {
        'original': asset,
        'originalSha256': sha256(original_bytes).hexdigest(),
        'originalBytes': len(original_bytes),
    }
    with Image.open(BytesIO(original_bytes)) as source:
        if source.format != 'PNG':
            raise ValueError(f'Original is not PNG: {asset}')
        result['width'], result['height'] = source.size
        if source.n_frames != 1 or original_bytes[24] > 8:
            return {**result, 'status': 'kept_png_format'}
        rgba = source.convert('RGBA')
        pixels = rgba.tobytes()
        properties = {key: source.info[key] for key in ('icc_profile', 'exif') if source.info.get(key)}
        destination = ROOT / runtime
        if destination.exists():
            compressed = destination.read_bytes()
        else:
            buffer = BytesIO()
            rgba.save(buffer, 'WEBP', lossless=True, method=4, quality=90, exact=True, **properties)
            compressed = buffer.getvalue()
        exact_webp(source, compressed, properties, pixels)
        if len(compressed) >= len(original_bytes):
            if destination.exists():
                raise ValueError(f'Unexpected unused WebP in the bundle: {runtime}')
            return {**result, 'status': 'kept_smaller_png'}
        if not destination.exists():
            with destination.open('xb') as stream:
                stream.write(compressed)
        return {
            **result,
            'status': 'webp_lossless',
            'runtime': runtime.as_posix(),
            'runtimeSha256': sha256(compressed).hexdigest(),
            'runtimeBytes': len(compressed),
            'rgbaSha256': sha256(pixels).hexdigest(),
        }


def write_text(path, contents):
    if path.exists() and path.read_text(encoding='utf-8') == contents:
        return
    temporary = path.with_name(path.name + '.pending')
    temporary.write_text(contents, encoding='utf-8', newline='\n')
    temporary.replace(path)


def update_bundle(files):
    optimized = {file['original'] for file in files if file['status'] == 'webp_lossless'}
    expected = {file['runtime'] for file in files if file['status'] == 'webp_lossless'}
    actual = {path.relative_to(ROOT).as_posix() for path in (ROOT / RUNTIME_DIR).iterdir()}
    if not expected or actual != expected:
        raise ValueError('The optimized folder differs from the verified WebP inventory')
    bundled_originals = sorted(
        path.relative_to(ROOT).as_posix()
        for path in (ROOT / SOURCE_DIR).iterdir()
        if path.is_file() and path.relative_to(ROOT).as_posix() not in optimized
    )
    if any(not re.fullmatch(r'assets/oculum/home_art/[a-zA-Z0-9_.-]+', asset) for asset in bundled_originals):
        raise ValueError('An original asset needs an explicit quoted YAML path')

    pubspec = ROOT / 'pubspec.yaml'
    contents = pubspec.read_text(encoding='utf-8')
    if contents.count(OLD_FOLDER_ENTRY) == 1:
        contents = contents.replace(OLD_FOLDER_ENTRY, ASSET_MARKER_START + ASSET_MARKER_END)
    if contents.count(ASSET_MARKER_START) != 1 or contents.count(ASSET_MARKER_END) != 1:
        raise ValueError('Generated asset bundle block is missing or duplicated')
    head, tail = contents.split(ASSET_MARKER_START)
    _, tail = tail.split(ASSET_MARKER_END)
    bundle = f'    - {RUNTIME_DIR}/\n' + ''.join(f'    - {asset}\n' for asset in bundled_originals)
    write_text(pubspec, head + ASSET_MARKER_START + bundle + ASSET_MARKER_END + tail)

    filenames = sorted(PurePosixPath(asset).name for asset in optimized)
    declarations = '\n'.join(f"  '{name}'," for name in filenames)
    write_text(
        ROOT / 'lib/widgets/oculum_optimized_monster_art_assets.dart',
        '// Generated by scripts/prepare_lossless_monster_art.py.\n'
        f'const oculumOptimizedMonsterArtFilenames = <String>{{\n{declarations}\n}};\n',
    )


def main():
    if len(sys.argv) != 2 or not features.check('webp'):
        raise SystemExit('Usage: Python with Pillow WebP support, script and artwork inventory path')
    candidates = read_candidates(Path(sys.argv[1]))
    (ROOT / RUNTIME_DIR).mkdir(exist_ok=True)
    files = []
    with ThreadPoolExecutor(max_workers=4) as executor:
        for number, result in enumerate(executor.map(derive, candidates), 1):
            files.append(result)
            if number % 50 == 0:
                print(f'Verified {number}/{len(candidates)} images', flush=True)
    update_bundle(files)
    report = {'schemaVersion': 1, 'codec': 'WebP lossless', 'files': files}
    write_text(ROOT / 'design/optimized-monster-art.json', json.dumps(report, indent=2) + '\n')
    webps = [file for file in files if file['status'] == 'webp_lossless']
    before = sum(file['originalBytes'] for file in webps)
    after = sum(file['runtimeBytes'] for file in webps)
    print(f'{len(webps)}/{len(files)} WebPs verified, {before} -> {after} bytes')


if __name__ == '__main__':
    main()
