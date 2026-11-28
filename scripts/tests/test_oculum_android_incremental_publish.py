"""The small fixtures model APK byte layout; apksigner is tested with actual APKs."""

import base64
import hashlib
import io
from pathlib import Path
import struct
import tempfile
import unittest
import zipfile

from unittest.mock import patch

try:
    from scripts import oculum_android_incremental_publish as android
except ImportError:
    import oculum_android_incremental_publish as android

ANDROID_APK_ASSET = android.ANDROID_APK_ASSET
ANDROID_SEGMENT_BYTES = android.ANDROID_SEGMENT_BYTES
build_android_range_manifest = android.build_android_range_manifest
serialize_android_range_manifest = android.serialize_android_range_manifest

REVISION = 'b' * 40
RUN = 23
VERSION = 100362
ASSET = f'https://github.com/Mich369/Oculum/releases/download/oculum-build-{RUN}/{ANDROID_APK_ASSET}'
SIGNED_PAYLOAD = b'fixture byte layout, not an actual cryptographic signer'
REUSABLE = 'assets/flutter_assets/tema-ghiaccio-é.webp'
COMPRESSED = 'assets/linee.txt'


def digest(value):
    return hashlib.sha256(value).hexdigest()


class OnePassBuffer(io.BytesIO):
    def seek(self, *_args, **_kwargs):
        raise io.UnsupportedOperation('Streaming ZIP fixture')


def make_zip(*, prepend=b'first', streamed=False):
    destination = OnePassBuffer() if streamed else io.BytesIO()
    with zipfile.ZipFile(destination, 'w') as archive:
        archive.writestr('AndroidManifest.xml', b'placeholder manifest')
        archive.writestr('classes.dex', b'placeholder DEX')
        archive.writestr('assets/layout-offset.bin', prepend)
        archive.writestr(REUSABLE, b'G' * ANDROID_SEGMENT_BYTES + b'Marker')
        archive.writestr(COMPRESSED, b'repeated text\n' * 750, compress_type=zipfile.ZIP_DEFLATED)
        archive.writestr('assets/empty.bin', b'')
        archive.writestr('assets/empty-dir/', b'')
    return destination.getvalue()


def apk_block(signer=SIGNED_PAYLOAD, padding=0):
    pair = struct.pack('<QI', len(signer) + 4, 0x7109871A) + signer
    if padding:
        pair += struct.pack('<QI', padding + 4, 0x42726577) + b'\x00' * padding
    size = len(pair) + 24
    return struct.pack('<Q', size) + pair + struct.pack('<Q', size) + b'APK Sig Block 42'


def add_block(payload, block):
    payload = bytearray(payload)
    eocd = payload.rindex(b'PK\x05\x06')
    cd = struct.unpack_from('<I', payload, eocd + 16)[0]
    struct.pack_into('<I', payload, eocd + 16, cd + len(block))
    return bytes(payload[:cd]) + block + bytes(payload[cd:]), cd


class AndroidPublisherTest(unittest.TestCase):
    def index(self, data, **changes):
        options = {
            'commit': REVISION, 'run_id': RUN, 'android_version_code': VERSION,
            'package': {'url': ASSET, 'bytes': len(data), 'sha256': 'sha256:' + digest(data)},
        }
        options.update(changes)
        with tempfile.TemporaryDirectory(prefix='verify-apk-range-', dir=Path(__file__).parent) as work:
            apk = Path(work) / 'signed-fixture.apk'
            apk.write_bytes(data)
            result = build_android_range_manifest(apk, **options)
            self.assertEqual(apk.read_bytes(), data)
            return result

    def coverage(self, data, manifest):
        rebuilt = bytearray()
        for record in manifest['segments']:
            self.assertEqual(record['offset'], len(rebuilt))
            self.assertGreater(record['bytes'], 0)
            self.assertLessEqual(record['bytes'], ANDROID_SEGMENT_BYTES)
            portion = data[record['offset']:record['offset'] + record['bytes']]
            self.assertEqual(len(portion), record['bytes'])
            self.assertEqual(digest(portion), record['sha256'])
            self.assertEqual('member' in record, 'relativeOffset' in record)
            if 'inline' in record:
                self.assertNotIn('member', record)
                self.assertLessEqual(record['bytes'], android.ANDROID_INLINE_SEGMENT_BYTES)
                self.assertEqual(base64.b64decode(record['inline'], validate=True), portion)
                self.assertEqual(base64.b64encode(portion).decode('ascii'), record['inline'])
            rebuilt.extend(portion)
        self.assertEqual(bytes(rebuilt), data)
        self.assertEqual(manifest['apk']['sha256'], digest(rebuilt))

    def test_ordered_raw_coverage_and_member_chunking(self):
        data, start_of_signing = add_block(make_zip(), apk_block(padding=ANDROID_SEGMENT_BYTES+64))
        manifest = self.index(data)
        self.assertEqual(manifest['schemaVersion'], 1)
        self.assertEqual(manifest['platform'], 'android')
        self.assertEqual(manifest['packageId'], 'com.mich.oculum')
        self.assertEqual(manifest['androidVersionCode'], VERSION)
        self.assertEqual(manifest['commit'], REVISION)
        self.assertEqual(manifest['runId'], RUN)
        self.assertEqual(manifest['apk'], {'url': ASSET, 'bytes': len(data), 'sha256': digest(data)})
        self.coverage(data, manifest)
        segments = manifest['segments']
        reused = [item for item in segments if item.get('member') == REUSABLE]
        self.assertEqual([item['relativeOffset'] for item in reused], [0, ANDROID_SEGMENT_BYTES])
        self.assertEqual([item['bytes'] for item in reused], [ANDROID_SEGMENT_BYTES, 6])
        compressed, = (item for item in segments if item.get('member') == COMPRESSED)
        self.assertLess(compressed['bytes'], 750 * len(b'repeated text\n'))
        self.assertFalse(any(item.get('member', '').startswith('assets/empty') for item in segments))
        terminal = [item for item in segments if item['offset'] + item['bytes'] > start_of_signing]
        self.assertGreater(len(terminal), 1)
        self.assertTrue(all('member' not in item for item in terminal))
        self.assertNotIn('inline', terminal[0])
        self.assertIn('inline', segments[0])
        encoded = serialize_android_range_manifest(manifest)
        self.assertEqual(encoded, serialize_android_range_manifest(self.index(data)))
        self.assertIn(REUSABLE.encode('utf-8'), encoded)

    def test_entry_can_be_reused_after_archive_offsets_shift(self):
        old, _ = add_block(make_zip(prepend=b'A'), apk_block(b'old block'))
        new, _ = add_block(make_zip(prepend=b'ABCDEFG'*100), apk_block(b'new block'))
        old_index, new_index = (self.index(apk) for apk in (old, new))
        old_records = [record for record in old_index['segments'] if record.get('member') == REUSABLE]
        new_records = [record for record in new_index['segments'] if record.get('member') == REUSABLE]
        self.assertNotEqual(old_records[0]['offset'], new_records[0]['offset'])
        for old_record, new_record in zip(old_records, new_records, strict=True):
            for key in ('member', 'relativeOffset', 'bytes', 'sha256'):
                self.assertEqual(old_record[key], new_record[key])

    def test_data_descriptors_remain_unattributed(self):
        data, _ = add_block(make_zip(streamed=True), apk_block())
        manifest = self.index(data)
        self.coverage(data, manifest)
        positions = [index for index, value in enumerate(manifest['segments']) if 'member' in value]
        self.assertTrue(positions)
        descriptors = 0
        for index in positions:
            record = manifest['segments'][index]
            end = record['offset'] + record['bytes']
            if data[end:end+4] == b'PK\x07\x08':
                descriptors += 1
                self.assertNotIn('member', manifest['segments'][index+1])
        self.assertGreater(descriptors, 0)

    def test_gap_inline_budget_keeps_later_gaps_downloadable(self):
        data, _ = add_block(make_zip(), apk_block())
        with patch.object(android, 'ANDROID_INLINE_TOTAL_BYTES', 50):
            manifest = self.index(data)
        inline = [item for item in manifest['segments'] if 'inline' in item]
        self.assertEqual(len(inline), 1)
        self.assertLessEqual(sum(item['bytes'] for item in inline), 50)
        self.assertTrue(any('inline' not in item and 'member' not in item for item in manifest['segments']))
        self.coverage(data, manifest)

    def test_unsigned_or_corrupt_signing_layout_is_rejected(self):
        original = make_zip()
        with self.assertRaisesRegex(ValueError, 'Signing Block'):
            self.index(original)
        valid, start = add_block(original, apk_block())
        changed = bytearray(valid)
        changed[start] ^= 0xFF
        with self.assertRaisesRegex(ValueError, 'length fields'):
            self.index(bytes(changed))
        bogus, _ = add_block(original, apk_block(b''))
        with self.assertRaisesRegex(ValueError, 'signer record'):
            self.index(bogus)

    def test_local_header_cannot_overlap_another_entry(self):
        data, _ = add_block(make_zip(), apk_block())
        corrupt = bytearray(data)
        struct.pack_into('<H', corrupt, 28, 65535)
        with self.assertRaisesRegex(ValueError, 'local header'):
            self.index(bytes(corrupt))

    def test_whole_sha_and_exact_package_identity(self):
        data, _ = add_block(make_zip(), apk_block())
        for package, error in (
            ({'url': ASSET, 'bytes': len(data), 'sha256': '0'*64}, 'APK SHA-256'),
            ({'url': ASSET, 'bytes': len(data)+1, 'sha256': digest(data)}, 'APK size'),
            ({'url': ASSET + '?other', 'bytes': len(data), 'sha256': digest(data)}, 'APK identity'),
        ):
            with self.subTest(error=error):
                with self.assertRaisesRegex(ValueError, error):
                    self.index(data, package=package)
        with self.assertRaisesRegex(ValueError, 'commit'):
            self.index(data, commit='B'*40)
        with self.assertRaisesRegex(ValueError, 'run ID'):
            self.index(data, run_id=True)
        with self.assertRaisesRegex(ValueError, 'versionCode'):
            self.index(data, android_version_code=0)


if __name__ == '__main__':
    unittest.main()
