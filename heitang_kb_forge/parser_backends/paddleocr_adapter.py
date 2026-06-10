from __future__ import annotations

import json
import os
from importlib.util import find_spec
from pathlib import Path
from typing import Any

from heitang_kb_forge.parser_backends.base import ParserBackend, ParserBackendRecord, failure_metadata
from heitang_kb_forge.parser_backends.normalize import column_safe_path, normalize_text, source_type


class PaddleOCRParserBackend(ParserBackend):
    name = "paddleocr"
    version = "optional"
    description = "Optional PaddleOCR runtime adapter for local image/PDF OCR when paddleocr is installed."
    supported_extensions = frozenset({".bmp", ".jpeg", ".jpg", ".pdf", ".png", ".tif", ".tiff"})

    def is_available(self) -> tuple[bool, str | None]:
        if find_spec("paddleocr") is None:
            return False, "Optional dependency 'paddleocr' is not installed. Install the parser-paddleocr extra or use backend=builtin."
        return True, None

    def parse_source(self, path: Path, command: str) -> ParserBackendRecord:
        available, reason = self.is_available()
        if not available:
            return _record(
                self,
                path,
                command,
                "unavailable",
                [reason or "paddleocr_adapter_unavailable"],
                0.0,
                False,
                "optional_runtime_dependency_missing",
            )
        try:
            engine = _make_paddleocr()
            raw_result = _run_paddleocr(engine, path)
            texts: list[str] = []
            scores: list[float] = []
            _collect_text_and_scores(raw_result, texts, scores)
            text = normalize_text("\n".join(dict.fromkeys(item.strip() for item in texts if item and item.strip())))
        except Exception as exc:
            return _record(self, path, command, "failed", [f"paddleocr_parse_failed:{exc}"], 0.0, True, "backend_runtime_exception")
        confidence = round(sum(scores) / len(scores), 3) if scores else (0.74 if text else 0.0)
        return ParserBackendRecord(
            source_path=column_safe_path(path),
            source_type=source_type(path),
            backend_name=self.name,
            backend_version=self.version,
            command=command,
            status="success" if text else "empty",
            text=text,
            warnings=[] if text else ["empty_text"],
            confidence=confidence,
            metadata={"adapter": "paddleocr", "runtime_invoked": True, "text_item_count": len(texts)}
            if text
            else {
                "adapter": "paddleocr",
                "runtime_invoked": True,
                "text_item_count": len(texts),
                **failure_metadata(
                    self.name,
                    "empty_parse_result",
                    repair_suggestion="Use an image/PDF with visible text, verify OCR language/model availability, or rerun with backend=builtin for supported text sources.",
                ),
            },
        )


def _make_paddleocr() -> object:
    _ensure_paddlex_cache_home()
    from paddleocr import PaddleOCR

    attempts = (
        {
            "device": "cpu",
            "enable_mkldnn": False,
            "lang": "ch",
            "use_doc_orientation_classify": False,
            "use_doc_unwarping": False,
            "use_textline_orientation": False,
        },
        {
            "device": "cpu",
            "enable_mkldnn": False,
            "lang": "en",
            "use_doc_orientation_classify": False,
            "use_doc_unwarping": False,
            "use_textline_orientation": False,
        },
        {
            "enable_mkldnn": False,
            "lang": "ch",
            "use_doc_orientation_classify": False,
            "use_doc_unwarping": False,
            "use_textline_orientation": False,
        },
        {"use_angle_cls": True, "lang": "ch"},
        {"lang": "ch"},
        {},
    )
    last_error: Exception | None = None
    for kwargs in attempts:
        try:
            return PaddleOCR(**kwargs)
        except TypeError as exc:
            last_error = exc
    if last_error is not None:
        raise last_error
    return PaddleOCR()


def _ensure_paddlex_cache_home() -> None:
    cache_home = os.environ.get("PADDLE_PDX_CACHE_HOME")
    if not cache_home:
        cache_home = str(Path.cwd() / ".heitang_cache" / "paddlex")
        os.environ["PADDLE_PDX_CACHE_HOME"] = cache_home
    cache_root = Path(cache_home)
    cache_root.mkdir(parents=True, exist_ok=True)
    cache_defaults = {
        "MODELSCOPE_CACHE": cache_root / "modelscope",
        "HF_HOME": cache_root / "huggingface",
        "HF_HUB_CACHE": cache_root / "huggingface" / "hub",
        "PADDLE_HOME": cache_root / "paddle",
    }
    for name, path in cache_defaults.items():
        if name not in os.environ:
            path.mkdir(parents=True, exist_ok=True)
            os.environ[name] = str(path)
    os.environ.setdefault("PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK", "True")


def _run_paddleocr(engine: object, path: Path) -> object:
    if hasattr(engine, "ocr"):
        try:
            return engine.ocr(str(path), cls=True)
        except TypeError:
            return engine.ocr(str(path))
    if hasattr(engine, "predict"):
        try:
            return engine.predict(input=str(path))
        except TypeError:
            return engine.predict(str(path))
    raise RuntimeError("PaddleOCR runtime exposes neither ocr() nor predict().")


def _collect_text_and_scores(value: Any, texts: list[str], scores: list[float]) -> None:
    if value is None:
        return
    if isinstance(value, dict):
        for key in ("rec_texts", "texts"):
            items = value.get(key)
            if isinstance(items, list):
                texts.extend(str(item) for item in items if isinstance(item, str))
        for key in ("rec_scores", "scores"):
            items = value.get(key)
            if isinstance(items, list):
                scores.extend(float(item) for item in items if isinstance(item, int | float))
        for key in ("text", "rec_text", "transcription"):
            item = value.get(key)
            if isinstance(item, str):
                texts.append(item)
        for item in value.values():
            _collect_text_and_scores(item, texts, scores)
        return
    if isinstance(value, tuple | list):
        if len(value) == 2 and isinstance(value[0], str) and isinstance(value[1], int | float):
            texts.append(value[0])
            scores.append(float(value[1]))
            return
        if len(value) == 2 and isinstance(value[1], tuple | list) and value[1] and isinstance(value[1][0], str):
            texts.append(value[1][0])
            if len(value[1]) > 1 and isinstance(value[1][1], int | float):
                scores.append(float(value[1][1]))
            return
        for item in value:
            _collect_text_and_scores(item, texts, scores)
        return
    json_payload = getattr(value, "json", None)
    if callable(json_payload):
        try:
            json_payload = json_payload()
        except TypeError:
            json_payload = None
    if isinstance(json_payload, str):
        try:
            json_payload = json.loads(json_payload)
        except json.JSONDecodeError:
            json_payload = None
    if isinstance(json_payload, dict):
        _collect_text_and_scores(json_payload, texts, scores)
        return
    dict_payload = getattr(value, "to_dict", None)
    if callable(dict_payload):
        _collect_text_and_scores(dict_payload(), texts, scores)
        return
    res_payload = getattr(value, "res", None)
    if isinstance(res_payload, dict):
        _collect_text_and_scores(res_payload, texts, scores)


def _record(
    backend: ParserBackend,
    path: Path,
    command: str,
    status: str,
    warnings: list[str],
    confidence: float,
    runtime_invoked: bool,
    error_code: str,
) -> ParserBackendRecord:
    return ParserBackendRecord(
        source_path=column_safe_path(path),
        source_type=source_type(path),
        backend_name=backend.name,
        backend_version=backend.version,
        command=command,
        status=status,
        warnings=warnings,
        confidence=confidence,
        metadata={
            "adapter": backend.name,
            "runtime_invoked": runtime_invoked,
            **failure_metadata(
                backend.name,
                error_code,
                repair_suggestion="Install parser-paddleocr, verify local OCR model/cache availability, or rerun with backend=builtin for supported text sources.",
            ),
        },
    )
