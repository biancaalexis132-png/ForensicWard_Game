"""Portable provenance paths for repository and external character inputs."""
from pathlib import Path


def provenance_path(path: Path, root: Path) -> str:
    """Use a repo-relative path when possible, otherwise an honest absolute path."""
    resolved = path.resolve()
    try:
        return resolved.relative_to(root.resolve()).as_posix()
    except ValueError:
        return str(resolved)
