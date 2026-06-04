from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Callable

from heitang_kb_forge.progress.events import ProgressEvent


class ProgressReporter:
    def __init__(
        self,
        *,
        terminal: bool = False,
        jsonl: bool = False,
        log_path: Path | None = None,
        verbose: bool = False,
    ) -> None:
        self.terminal = terminal
        self.jsonl = jsonl or log_path is not None
        self.log_path = log_path
        self.verbose = verbose
        self._started = time.monotonic()

    def configure_default_log(self, output: Path) -> None:
        if self.jsonl and self.log_path is None:
            self.log_path = output / "progress_events.jsonl"

    def emit(self, stage: str, status: str, message: str, **kwargs) -> ProgressEvent:
        event = ProgressEvent(
            stage=stage,
            status=status,
            message=message,
            duration_ms=int((time.monotonic() - self._started) * 1000),
            **kwargs,
        )
        if self.terminal:
            self._print(event)
        if self.jsonl and self.log_path:
            self.log_path.parent.mkdir(parents=True, exist_ok=True)
            with self.log_path.open("a", encoding="utf-8", newline="\n") as handle:
                handle.write(json.dumps(event.model_dump(mode="json"), ensure_ascii=False) + "\n")
        return event

    def callback(self) -> Callable[[ProgressEvent], None]:
        def _emit(event: ProgressEvent) -> None:
            self.emit(**event.model_dump(exclude={"event_id", "timestamp", "duration_ms"}, exclude_none=True))

        return _emit

    def _print(self, event: ProgressEvent) -> None:
        prefix = f"[{event.stage}]"
        if event.current_file_index and event.total_files:
            prefix = f"[{event.current_file_index}/{event.total_files}] {prefix}"
        if event.current_page and event.total_pages:
            prefix = f"{prefix} page {event.current_page}/{event.total_pages}"
        detail = f" - {event.current_file}" if event.current_file and self.verbose else ""
        warning = f" warning={event.warning}" if event.warning else ""
        error = f" error={event.error}" if event.error else ""
        print(f"{prefix} {event.message}{detail}{warning}{error}")


def make_progress_reporter(
    *,
    progress: bool = False,
    progress_jsonl: bool = False,
    progress_log: Path | None = None,
    verbose: bool = False,
) -> ProgressReporter | None:
    if not (progress or progress_jsonl or progress_log):
        return None
    return ProgressReporter(terminal=progress, jsonl=progress_jsonl, log_path=progress_log, verbose=verbose)
