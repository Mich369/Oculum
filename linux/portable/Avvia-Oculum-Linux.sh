#!/usr/bin/env bash
set -euo pipefail

package_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
port="8765"
address="http://127.0.0.1:${port}"

app_dir=""
for candidate in \
  "${package_dir}/app" \
  "${package_dir}/Oculum-Linux-Portable-Web/app" \
  "${package_dir}"; do
  if [[ -f "${candidate}/index.html" && -f "${candidate}/main.dart.js" ]]; then
    app_dir="${candidate}"
    break
  fi
done

if [[ -z "${app_dir}" ]]; then
  while IFS= read -r -d '' index_file; do
    candidate="$(dirname "${index_file}")"
    if [[ -f "${candidate}/main.dart.js" ]]; then
      app_dir="${candidate}"
      break
    fi
  done < <(find "${package_dir}" -maxdepth 4 -type f -iname 'index.html' -print0)
fi

if [[ -z "${app_dir}" ]]; then
  echo "File dell'app non individuati nella cartella: ${package_dir}" >&2
  echo "Estrai tutto lo ZIP prima di avviare Oculum." >&2
  echo "Sono necessari index.html e main.dart.js nella stessa cartella." >&2
  exit 1
fi

if command -v python3 >/dev/null 2>&1; then
  python_command=(python3)
elif command -v python >/dev/null 2>&1; then
  python_command=(python)
else
  echo "Python non è installato." >&2
  echo "Su Ubuntu/Debian: sudo apt install python3" >&2
  exit 1
fi

cd "${app_dir}"
"${python_command[@]}" -m http.server "${port}" --bind 127.0.0.1 &
server_pid=$!

stop_server() {
  kill "${server_pid}" 2>/dev/null || true
}
trap stop_server EXIT INT TERM

sleep 1
if ! kill -0 "${server_pid}" 2>/dev/null; then
  echo "Impossibile avviare Oculum sulla porta ${port}." >&2
  echo "Chiudi eventuali programmi che usano ${address} e riprova." >&2
  exit 1
fi

if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "${address}" >/dev/null 2>&1 || true
else
  echo "Apri nel browser: ${address}"
fi

echo "Oculum è disponibile su ${address}"
echo "Lascia aperto questo terminale. Premi Ctrl+C per chiudere Oculum."
wait "${server_pid}"
