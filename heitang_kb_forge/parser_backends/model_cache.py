from __future__ import annotations

import os
from contextlib import contextmanager
from pathlib import Path
from typing import Iterator


RUNTIME_MODEL_CACHE_ENV = "HEITANG_RUNTIME_MODEL_CACHE"


def backend_model_cache_env(backend_id: str) -> str:
    return f"HEITANG_{backend_id.strip().upper()}_MODEL_CACHE"


def resolve_backend_model_cache(
    backend_id: str,
    cache_dir: Path | str | None = None,
) -> Path:
    normalized = backend_id.strip().lower()
    if cache_dir is not None:
        return Path(cache_dir).expanduser().resolve()

    backend_specific = os.environ.get(backend_model_cache_env(normalized))
    if backend_specific:
        return Path(backend_specific).expanduser().resolve()

    shared_root = os.environ.get(RUNTIME_MODEL_CACHE_ENV)
    if shared_root:
        return (Path(shared_root).expanduser() / normalized).resolve()

    project_root = Path(__file__).resolve().parents[2]
    return (project_root / ".heitang" / "runtime_cache" / normalized).resolve()


@contextmanager
def backend_model_cache_environment(
    backend_id: str,
    cache_dir: Path | str | None = None,
) -> Iterator[Path]:
    normalized = backend_id.strip().lower()
    resolved = resolve_backend_model_cache(normalized, cache_dir)
    resolved.mkdir(parents=True, exist_ok=True)
    keys = {
        backend_model_cache_env(normalized): str(resolved),
        "MODEL_CACHE_DIR": str(resolved),
    }
    if normalized in {"marker", "surya"}:
        keys["TORCH_DEVICE"] = "cpu"
    previous = {key: os.environ.get(key) for key in keys}
    os.environ.update(keys)
    try:
        yield resolved
    finally:
        for key, value in previous.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value
