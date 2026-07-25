#!/usr/bin/env bash
set -euo pipefail

APP_PATH=${1:?"Uso: sign_and_notarize_macos.sh <app-path> <output-zip>"}
OUTPUT_ZIP=${2:?"Uso: sign_and_notarize_macos.sh <app-path> <output-zip>"}

required_secrets=(
  APPLE_DEVELOPER_ID_CERTIFICATE_BASE64
  APPLE_DEVELOPER_ID_CERTIFICATE_PASSWORD
  APPLE_ID
  APPLE_APP_SPECIFIC_PASSWORD
  APPLE_TEAM_ID
)

for secret_name in "${required_secrets[@]}"; do
  if [[ -z "${!secret_name:-}" ]]; then
    echo "Secret GitHub obbligatorio mancante: ${secret_name}" >&2
    exit 1
  fi
done

if [[ ! -d "$APP_PATH" ]]; then
  echo "Bundle macOS non trovato: $APP_PATH" >&2
  exit 1
fi

CERTIFICATE_PATH="$RUNNER_TEMP/oculum-developer-id.p12"
KEYCHAIN_PATH="$RUNNER_TEMP/oculum-signing.keychain-db"
NOTARY_ZIP="$RUNNER_TEMP/oculum-notarization.zip"
KEYCHAIN_PASSWORD=$(openssl rand -hex 24)

cleanup() {
  security delete-keychain "$KEYCHAIN_PATH" >/dev/null 2>&1 || true
  rm -f "$CERTIFICATE_PATH" "$NOTARY_ZIP"
}
trap cleanup EXIT

printf '%s' "$APPLE_DEVELOPER_ID_CERTIFICATE_BASE64" | base64 --decode > "$CERTIFICATE_PATH"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security import "$CERTIFICATE_PATH" \
  -k "$KEYCHAIN_PATH" \
  -P "$APPLE_DEVELOPER_ID_CERTIFICATE_PASSWORD" \
  -A \
  -t cert \
  -f pkcs12
security set-key-partition-list \
  -S apple-tool:,apple:,codesign: \
  -s \
  -k "$KEYCHAIN_PASSWORD" \
  "$KEYCHAIN_PATH"
security list-keychains -d user -s "$KEYCHAIN_PATH"

SIGNING_IDENTITY=$(
  security find-identity -v -p codesigning "$KEYCHAIN_PATH" |
    sed -n 's/.*"\(Developer ID Application:.*\)"/\1/p' |
    head -n 1
)

if [[ -z "$SIGNING_IDENTITY" ]]; then
  echo "Nel certificato importato non esiste una identita Developer ID Application valida." >&2
  exit 1
fi

echo "Firma del bundle con identita Developer ID Application."
codesign \
  --deep \
  --force \
  --options runtime \
  --timestamp \
  --entitlements macos/Runner/Release.entitlements \
  --sign "$SIGNING_IDENTITY" \
  "$APP_PATH"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign --display --verbose=2 "$APP_PATH"

rm -f "$NOTARY_ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$NOTARY_ZIP"

echo "Invio ad Apple Notary Service."
xcrun notarytool submit "$NOTARY_ZIP" \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_APP_SPECIFIC_PASSWORD" \
  --team-id "$APPLE_TEAM_ID" \
  --wait

echo "Applicazione del ticket di notarizzazione al bundle."
xcrun stapler staple -v "$APP_PATH"
xcrun stapler validate -v "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH"

mkdir -p "$(dirname "$OUTPUT_ZIP")"
rm -f "$OUTPUT_ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$OUTPUT_ZIP"
shasum -a 256 "$OUTPUT_ZIP"
