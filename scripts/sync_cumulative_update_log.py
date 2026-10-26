from pathlib import Path
root = Path(__file__).resolve().parents[1]
source = root / "docs/REGISTRO_AGGIORNAMENTI.md"
target = root / "assets/update/oculum_cumulative_log.md"
target.write_bytes(source.read_bytes())
print("Synchronized cumulative player log from build b917217.")
