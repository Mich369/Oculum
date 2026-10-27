import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("verify_android_signing", ROOT / "scripts/verify_android_signing.py")
signing = importlib.util.module_from_spec(spec)
spec.loader.exec_module(signing)
CERT = "a" * 64


class AndroidSigningTests(unittest.TestCase):
    def test_release_certificate_pin_exists_and_has_valid_sha256(self):
        pin = ROOT / "android/signing-certificate.sha256"
        self.assertTrue(pin.is_file(), "The public signing certificate pin must ship with the checkout")
        self.assertRegex(pin.read_text(encoding="utf-8").strip(), r"^[a-f0-9]{64}$")

    def test_runner_signing_path_is_defined_in_a_step_not_job_env(self):
        workflow = (ROOT / '.github/workflows/build_distribution.yml').read_text(encoding='utf-8')
        self.assertNotIn('OCULUM_ANDROID_KEYSTORE_PATH: ${{ runner.temp }}', workflow)
        self.assertIn('OCULUM_ANDROID_KEYSTORE_PATH="$RUNNER_TEMP/oculum-release.keystore"', workflow)
        self.assertIn('echo "OCULUM_ANDROID_KEYSTORE_PATH=$OCULUM_ANDROID_KEYSTORE_PATH" >> "$GITHUB_ENV"', workflow)

    def test_verified_update_keeps_same_package_and_certificate(self):
        package = signing.package_identity("package: name='com.mich.oculum' versionCode='100112' versionName='1.0.0'")
        certificate = signing.certificate_digest(f"Signer #1 certificate DN: CN=Android Debug\r\r\nSigner #1 certificate SHA-256 digest: {CERT}\r\r\n")
        signing.assert_identity(certificate, package, CERT, 100112)

    def test_different_key_cannot_be_published_as_an_update(self):
        with self.assertRaisesRegex(ValueError, "Firma APK differente"):
            signing.assert_identity("b" * 64, dict(package="com.mich.oculum", versionCode=100112), CERT, 100112)

    def test_android_37_scheme_labels_keep_the_same_certificate(self):
        self.assertEqual(signing.certificate_digest(f"V2 Signer: certificate SHA-256 digest: {CERT}\r\nV3 Signer: certificate SHA-256 digest: {CERT}\r\n"), CERT)

    def test_different_application_id_and_downgrade_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "applicationId changed"):
            signing.assert_identity(CERT, dict(package="com.mich.oculum.new", versionCode=100112), CERT, 100112)
        with self.assertRaisesRegex(ValueError, "versionCode"):
            signing.assert_identity(CERT, dict(package="com.mich.oculum", versionCode=5), CERT, 100112)

    def test_missing_or_multiple_signers_are_not_accepted(self):
        for text in ("", f"Signer #1 certificate SHA-256 digest: {CERT}\nSigner #2 certificate SHA-256 digest: {CERT}\n"):
            with self.assertRaises(ValueError):
                signing.certificate_digest(text)


if __name__ == "__main__":
    unittest.main()
