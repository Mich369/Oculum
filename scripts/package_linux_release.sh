#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
requested_bundle="${1:-}"
distribution_root="${2:-${project_root}/build/distribution}"

find_linux_bundle() {
  local candidate
  if [[ -n "${requested_bundle}" ]]; then
    candidate="${requested_bundle}"
    if [[ -x "${candidate}/oculum" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
    return 1
  fi

  for candidate in \
    "${project_root}/build/linux/x64/release/bundle" \
    "${project_root}/build/linux/arm64/release/bundle"; do
    if [[ -x "${candidate}/oculum" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done
  return 1
}

bundle_source="$(find_linux_bundle || true)"
if [[ -z "${bundle_source}" && -z "${requested_bundle}" ]]; then
  if [[ "$(uname -s)" != "Linux" ]]; then
    echo "The Linux executable must be built on Linux or by GitHub Actions." >&2
    exit 1
  fi
  if [[ ! -f "${project_root}/pubspec.yaml" ]]; then
    echo "Oculum project not found at: ${project_root}" >&2
    echo "Download the ready Oculum-Linux artifact instead of this script alone." >&2
    exit 1
  fi
  if ! command -v flutter >/dev/null 2>&1; then
    echo "Flutter is not installed, so the missing Linux executable cannot be built." >&2
    echo "Download Oculum-Linux from GitHub Actions, extract it, then run Avvia-Oculum.sh." >&2
    exit 1
  fi

  echo "Linux release is missing; building Oculum now..."
  (
    cd "${project_root}"
    flutter config --enable-linux-desktop
    flutter pub get
    flutter build linux --release
  )
  bundle_source="$(find_linux_bundle || true)"
fi

if [[ -z "${bundle_source}" ]]; then
  missing_bundle="${requested_bundle:-${project_root}/build/linux/{x64,arm64}/release/bundle}"
  echo "Linux release executable not found below: ${missing_bundle}" >&2
  echo "Run 'flutter build linux --release' first, or omit the first argument to build automatically." >&2
  exit 1
fi

linux_arch="$(basename "$(dirname "$(dirname "${bundle_source}")")")"
package_root="${distribution_root}/Oculum-Linux"
archive_path="${distribution_root}/Oculum-Linux-${linux_arch}.tar.gz"

mkdir -p "${distribution_root}"
rm -rf "${package_root}"
mkdir -p "${package_root}/app"
cp -a "${bundle_source}/." "${package_root}/app/"

cat > "${package_root}/Avvia-Oculum.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
package_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${package_dir}/app/oculum" "$@"
EOF
chmod +x "${package_root}/Avvia-Oculum.sh"

cat > "${package_root}/LEGGIMI-LINUX.txt" <<EOF
OCULUM PER LINUX (${linux_arch})

1. Estrai tutto l'archivio senza spostare singolarmente i file interni.
2. Apri un terminale nella cartella estratta.
3. Avvia: ./Avvia-Oculum.sh

Su Ubuntu, Debian o Linux Mint, se mancano librerie di sistema:
sudo apt update
sudo apt install libgtk-3-0 libsecret-1-0 liblzma5

I salvataggi restano locali al profilo dell'utente Linux.
Non eseguire direttamente file presi dalla sottocartella lib: usa lo script.
EOF

tar -C "${distribution_root}" -czf "${archive_path}" "Oculum-Linux"
echo "Linux distribution created: ${archive_path}"
