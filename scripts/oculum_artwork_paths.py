"""Keep project references on C while artwork storage is reached through G.

The artwork junction changes storage, not repository identity. Resolve paths only
for physical comparisons; manifests and HTML references retain their logical
project paths. Native originals outside the artwork tree remain external.
"""
from __future__ import annotations

import os
from pathlib import Path
from typing import NamedTuple


def _absolute(path: str | os.PathLike[str]) -> Path:
    """Normalize dot segments without following a junction."""
    return Path(os.path.abspath(os.fspath(path)))


def repository_root(repo_root: str | os.PathLike[str] | None = None) -> Path:
    root = _absolute(repo_root if repo_root is not None else Path(__file__).parent.parent)
    missing = [name for name in ('lib', 'docs', 'scripts') if not (root / name).is_dir()]
    if missing:
        raise ValueError(f'Invalid Oculum repository root {root}: missing {", ".join(missing)}')
    return root


def logical_path(path: str | os.PathLike[str], *, repo_root=None) -> Path:
    root = repository_root(repo_root)
    value = Path(path)
    value = _absolute(value if value.is_absolute() else root / value)
    if value.is_relative_to(root):
        return value
    artwork = root / 'output' / 'artwork'
    physical_artwork = artwork.resolve()
    if value.is_relative_to(physical_artwork):
        return artwork / value.relative_to(physical_artwork)
    return value


class ArtworkPaths(NamedTuple):
    root: Path
    artwork: Path
    folder: Path
    script: Path
    physical_artwork: Path

    def logical(self, path: str | os.PathLike[str]) -> Path:
        return logical_path(path, repo_root=self.root)

    def reference(self, path: str | os.PathLike[str]) -> str:
        value = self.logical(path)
        return value.relative_to(self.root).as_posix() if value.is_relative_to(self.root) else str(value)

    def relative_url(self, path: str | os.PathLike[str], folder=None) -> str:
        base = self.folder if folder is None else self.logical(folder)
        return Path(os.path.relpath(self.logical(path), base)).as_posix()

    def same_folder(self, path: str | os.PathLike[str], folder=None) -> bool:
        base = self.folder if folder is None else Path(folder)
        return self.logical(path).resolve().parent == base.resolve()


def artwork_paths(script_file: str | os.PathLike[str], *, repo_root=None) -> ArtworkPaths:
    root = repository_root(repo_root)
    artwork = root / 'output' / 'artwork'
    script = logical_path(script_file, repo_root=root)
    if not script.is_relative_to(artwork):
        raise ValueError(f'Artwork helper is outside the project artwork tree: {script_file}')
    return ArtworkPaths(root, artwork, script.parent, script, artwork.resolve())
