"""Verify the actual APK before distributing an update; never reads app data."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def certificate_digest(output):
    rows = re.findall(r"^((?:Signer #\d+|V\d+(?:\.\d+)? Signer(?: #\d+)?)):? certificate SHA-256 digest: ([a-fA-F0-9]{64})$", output.replace("\r", ""), re.M)
    digests = {digest.lower() for _, digest in rows}
    if len(digests) != 1 or any(re.search(r"#(?!1$)\d+$", signer) for signer, _ in rows):
        raise ValueError("Expected exactly one verified APK signing certificate")
    return digests.pop()


def package_identity(output):
    match = re.search(r"^package: name='([^']+)' versionCode='(\d+)' versionName='([^']*)'", output, re.M)
    if not match:
        raise ValueError("Cannot read APK package and version")
    return dict(package=match[1], versionCode=int(match[2]), versionName=match[3])


def assert_identity(certificate, package, expected, minimum_version):
    if not re.fullmatch(r"[a-f0-9]{64}", expected):
        raise ValueError("Invalid pinned Android signing fingerprint")
    if certificate != expected:
        raise ValueError(f"Firma APK differente: attesa {expected}, trovata {certificate}. Pubblicazione annullata.")
    if package["package"] != "com.mich.oculum":
        raise ValueError("Android applicationId changed: existing saves and sessions would not be reused")
    if package["versionCode"] < minimum_version:
        raise ValueError("Android versionCode is older than the expected update")


def sdk_build_tools(sdk):
    candidates = [p for p in (sdk / "build-tools").iterdir() if (p / "lib/apksigner.jar").is_file()]
    if not candidates:
        raise ValueError("Android SDK build-tools with apksigner are required")
    return max(candidates, key=lambda p: tuple(int(n) for n in re.findall(r"\d+", p.name)))


def run_checked(command):
    result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180)
    if result.returncode:
        raise ValueError(f"Android verification failed ({Path(command[0]).name}, exit {result.returncode}): {result.stderr[-1500:]}")
    return result.stdout


def verify_apk(apk, sdk, java, expected, minimum_version):
    tools = sdk_build_tools(sdk)
    signature = run_checked([java, "-jar", str(tools / "lib/apksigner.jar"), "verify", "--print-certs", str(apk)])
    aapt = tools / ("aapt.exe" if os.name == "nt" else "aapt")
    package = package_identity(run_checked([str(aapt), "dump", "badging", str(apk)]))
    certificate = certificate_digest(signature)
    assert_identity(certificate, package, expected, minimum_version)
    with apk.open("rb") as source:
        sha256 = hashlib.file_digest(source, "sha256").hexdigest()
    return dict(**package, signingCertificateSha256=certificate, apkSha256=sha256, apkBytes=apk.stat().st_size,
                signatureVerified=True, existingDataRequiresSameInstalledCertificate=True,
                applicationDataModified=False)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apk", type=Path, required=True)
    parser.add_argument("--sdk", type=Path)
    parser.add_argument("--java")
    parser.add_argument("--expected-certificate", type=Path, default=ROOT / "android/signing-certificate.sha256")
    parser.add_argument("--min-version-code", type=int, default=5)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    sdk = args.sdk or Path(os.environ.get("ANDROID_SDK_ROOT") or os.environ.get("ANDROID_HOME") or Path.home() / "AppData/Local/Android/Sdk")
    java = args.java
    if not java and os.environ.get("JAVA_HOME"):
        java = str(Path(os.environ["JAVA_HOME"]) / "bin" / ("java.exe" if os.name == "nt" else "java"))
    java = java or shutil.which("java")
    if not java:
        parser.error("Java is required; set JAVA_HOME or --java")
    result = verify_apk(args.apk, sdk, java, args.expected_certificate.read_text().strip().lower(), args.min_version_code)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
