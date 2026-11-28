"""Index the raw bytes of a previously verified Android release APK."""

import base64
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import zipfile

DEFAULT_REPOSITORY = 'Mich369/Oculum'
ANDROID_PACKAGE_ID = 'com.mich.oculum'
ANDROID_APK_ASSET = 'Oculum-Android-Incrementale.apk'
ANDROID_MANIFEST_ASSET = 'Oculum-Android-Incrementale.json'
ANDROID_SEGMENT_BYTES = 2 * 1024 * 1024
ANDROID_INLINE_SEGMENT_BYTES = 16 * 1024
ANDROID_INLINE_TOTAL_BYTES = 4 * 1024 * 1024
_ZIP_HEADER = struct.Struct('<4s5H3I2H')
_APK_BLOCK_MAGIC = b'APK Sig Block 42'
_APK_SIGNATURE_IDS = frozenset({0x7109871A, 0xF05368C0, 0x1B93AD61})
_APK_FOOTER = struct.Struct('<Q16s')


def _verified_apk(package, commit, run_id, android_version_code, repository):
    if not isinstance(commit, str) or not re.fullmatch(r'[a-f0-9]{40}', commit):
        raise ValueError('Invalid Android build commit')
    if type(run_id) is not int or not 0 < run_id <= (1 << 53) - 1:
        raise ValueError('Invalid Android build run ID')
    if type(android_version_code) is not int or not 0 < android_version_code < (1 << 31):
        raise ValueError('Invalid signed APK versionCode')
    if not re.fullmatch(r'[A-Za-z0-9_-]+/[A-Za-z0-9_.-]+', repository):
        raise ValueError('Invalid GitHub repository')
    url = f'https://github.com/{repository}/releases/download/oculum-build-{run_id}/{ANDROID_APK_ASSET}'
    size = package.get('bytes')
    digest = package.get('sha256')
    if (package.get('url') != url or type(size) is not int or not 0 < size < 2 ** 31
            or not isinstance(digest, str) or not re.fullmatch(r'(?:sha256:)?[a-f0-9]{64}', digest)):
        raise ValueError('Invalid verified Android release APK identity')
    return {'url': url, 'bytes': size, 'sha256': digest.removeprefix('sha256:')}


def _read_at(source, offset, length):
    source.seek(offset)
    raw = source.read(length)
    if len(raw) != length:
        raise ValueError('Truncated signed APK')
    return raw


def _signature_block_start(source, central_offset):
    if central_offset < _APK_FOOTER.size + 8:
        raise ValueError('Missing APK v2/v3 Signing Block')
    footer = central_offset - _APK_FOOTER.size
    size, magic = _APK_FOOTER.unpack(_read_at(source, footer, _APK_FOOTER.size))
    if magic != _APK_BLOCK_MAGIC or size < _APK_FOOTER.size or size > central_offset - 8:
        raise ValueError('Missing or invalid APK v2/v3 Signing Block')
    start = central_offset - size - 8
    if _read_at(source, start, 8) != size.to_bytes(8, 'little'):
        raise ValueError('APK Signing Block length fields disagree')

    cursor = start + 8
    found = False
    while cursor < footer:
        if footer - cursor < 12:
            raise ValueError('Incomplete APK Signing Block record')
        length, identity = struct.unpack('<QI', _read_at(source, cursor, 12))
        if not 4 <= length <= footer - cursor - 8:
            raise ValueError('APK Signing Block record overlaps the footer')
        found |= identity in _APK_SIGNATURE_IDS and length > 4
        cursor += 8 + length
    if not found:
        raise ValueError('No APK v2/v3 signer record in the Signing Block')
    return start


def _member_span(source, member, boundary):
    name = member.orig_filename
    parts = name.removesuffix('/').split('/')
    if (name != member.filename or any(part in ('', '.', '..') for part in parts)
            or '\\' in name or any(ord(character) < 32 or ord(character) == 127 for character in name)):
        raise ValueError(f'Unsafe APK ZIP member name: {name!r}')
    if member.compress_type not in (zipfile.ZIP_STORED, zipfile.ZIP_DEFLATED):
        raise ValueError(f'Unsupported APK ZIP compression: {name!r}')
    if member.flag_bits & ~0x080E:
        raise ValueError(f'Unsupported APK ZIP member flags: {name!r}')
    if (member.compress_type == zipfile.ZIP_STORED and member.file_size != member.compress_size):
        raise ValueError(f'Invalid stored APK ZIP entry length: {name!r}')
    header_start = member.header_offset
    if header_start < 0 or header_start + _ZIP_HEADER.size > boundary:
        raise ValueError(f'Invalid APK ZIP local header: {name!r}')
    raw = _read_at(source, header_start, _ZIP_HEADER.size)
    marker, _, flags, method, _, _, _, _, _, filename_length, extra_length = _ZIP_HEADER.unpack(raw)
    start = header_start + _ZIP_HEADER.size + filename_length + extra_length
    end = start + member.compress_size
    if (marker != b'PK\x03\x04' or flags != member.flag_bits or method != member.compress_type
            or end > boundary
            or _read_at(source, header_start + _ZIP_HEADER.size, filename_length) != name.encode('utf-8')):
        raise ValueError(f'APK ZIP local header does not match its central entry: {name!r}')
    return start, end


def _apk_member_spans(source, archive):
    members = sorted(archive.infolist(), key=lambda member: member.header_offset)
    names = {member.orig_filename for member in members if not member.is_dir()}
    if not {'AndroidManifest.xml', 'classes.dex'}.issubset(names):
        raise ValueError('Expected one direct Android APK payload')
    if len({member.orig_filename for member in members}) != len(members):
        raise ValueError('Duplicate APK ZIP member names')
    boundaries = [member.header_offset for member in members[1:]]
    boundaries.append(_signature_block_start(source, archive.start_dir))
    for member, boundary in zip(members, boundaries, strict=True):
        start, end = _member_span(source, member, boundary)
        if start < end and not member.is_dir():
            yield start, end, member.orig_filename


def _read_segments(source, spans, whole_size):
    digest = hashlib.sha256()
    segments = []
    inline_bytes = 0

    def append(start, end, member=None):
        nonlocal inline_bytes
        for offset in range(start, end, ANDROID_SEGMENT_BYTES):
            length = min(ANDROID_SEGMENT_BYTES, end - offset)
            data = source.read(length)
            if len(data) != length:
                raise ValueError('Signed APK changed while indexing its segments')
            digest.update(data)
            segment = {'offset': offset, 'bytes': length, 'sha256': hashlib.sha256(data).hexdigest()}
            if member is not None:
                segment.update(member=member, relativeOffset=offset-start)
            elif (length <= ANDROID_INLINE_SEGMENT_BYTES
                  and inline_bytes + length <= ANDROID_INLINE_TOTAL_BYTES):
                segment['inline'] = base64.b64encode(data).decode('ascii')
                inline_bytes += length
            segments.append(segment)

    source.seek(0)
    cursor = 0
    for start, end, member in spans:
        if cursor > start:
            raise ValueError('Overlapping APK ZIP member data')
        append(cursor, start)
        append(start, end, member)
        cursor = end
    append(cursor, whole_size)
    return segments, digest.hexdigest()


def build_android_range_manifest(path, *, commit, run_id, android_version_code, package, repository=DEFAULT_REPOSITORY):
    """Index one direct APK after a trusted apksigner/package/version check.

    ZIP layout and the presence of a v2/v3 block alone do not verify a signer.
    The caller must verify the pinned certificate on these exact APK bytes.
    """
    apk = _verified_apk(package, commit, run_id, android_version_code, repository)
    with Path(path).open('rb') as source:
        initial = os.fstat(source.fileno())
        if initial.st_size != apk['bytes']:
            raise ValueError('APK size differs from the verified asset')
        try:
            with zipfile.ZipFile(source, metadata_encoding='utf-8') as archive:
                spans = list(_apk_member_spans(source, archive))
        except (zipfile.BadZipFile, UnicodeError) as error:
            raise ValueError('Invalid Android APK ZIP structure or UTF-8 member name') from error
        segments, actual = _read_segments(source, spans, initial.st_size)
        end = os.fstat(source.fileno())
        if (end.st_size, end.st_mtime_ns) != (initial.st_size, initial.st_mtime_ns):
            raise ValueError('APK changed while indexing its segments')
        if actual != apk['sha256']:
            raise ValueError('APK SHA-256 differs from the verified asset')
    return {
        'schemaVersion': 1,
        'platform': 'android',
        'commit': commit,
        'runId': run_id,
        'androidVersionCode': android_version_code,
        'packageId': ANDROID_PACKAGE_ID,
        'apk': apk,
        'segments': segments,
    }


def serialize_android_range_manifest(manifest):
    return (json.dumps(manifest, ensure_ascii=False, sort_keys=True, separators=(',', ':')) + '\n').encode('utf-8')
