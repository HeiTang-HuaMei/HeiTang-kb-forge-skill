import json
import os
import threading
import time
from pathlib import Path
from typing import Iterable

from pydantic import BaseModel


def write_jsonl(path: Path, rows: Iterable[BaseModel | dict]) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = _tmp_path(path)
    count = 0
    with tmp_path.open("w", encoding="utf-8", newline="\n") as handle:
        for row in rows:
            payload = row.model_dump(mode="json") if isinstance(row, BaseModel) else row
            handle.write(json.dumps(payload, ensure_ascii=False) + "\n")
            count += 1
    _replace_with_retry(tmp_path, path)
    return count


def write_json(path: Path, row: BaseModel | dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = row.model_dump(mode="json") if isinstance(row, BaseModel) else row
    tmp_path = _tmp_path(path)
    tmp_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    _replace_with_retry(tmp_path, path)


def _tmp_path(path: Path) -> Path:
    return path.with_name(f".{path.name}.{os.getpid()}.{threading.get_ident()}.tmp")


def _replace_with_retry(tmp_path: Path, path: Path) -> None:
    last_error: PermissionError | None = None
    for _ in range(5):
        try:
            tmp_path.replace(path)
            return
        except PermissionError as exc:
            last_error = exc
            time.sleep(0.05)
    try:
        tmp_path.unlink()
    except FileNotFoundError:
        pass
    if last_error is not None:
        raise last_error
