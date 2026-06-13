from __future__ import annotations

import hashlib
import importlib.util
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit
from uuid import uuid4

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


VIDEO_VISUAL_FILES = [
    "video_transcript.jsonl",
    "video_timestamp_trace.json",
    "video_keyframe_manifest.json",
    "video_keyframe_ocr_blocks.jsonl",
    "visual_evidence_manifest.json",
    "image_ocr_blocks.jsonl",
    "layout_blocks.jsonl",
    "multimodal_chunks.jsonl",
    "image_trace.json",
    "timestamp_trace.json",
    "visual_evidence_map.json",
    "visual_understanding_report.md",
    "video_visual_validation_report.json",
    "progress_events.jsonl",
    "run_manifest.json",
    "run_summary.md",
]

_STATUS_PASSED = "passed"
_STATUS_PARTIAL = "partial"
_STATUS_FAILED = "failed"
_STATUS_SKIPPED = "skipped"


def build_video_visual_evidence(
    output: Path,
    *,
    subtitle_files: list[Path] | None = None,
    image_files: list[Path] | None = None,
    keyframe_files: list[Path] | None = None,
    video_files: list[Path] | None = None,
    source_url: str = "",
    title: str = "",
    author: str = "",
    platform: str = "",
    created_at: str | None = None,
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    created_at = created_at or _now()
    source_url = source_url.strip()
    title = title.strip() or "External video/visual evidence"
    platform = platform.strip() or _platform_from_url(source_url)

    progress: list[dict[str, Any]] = []
    transcript_rows = _parse_subtitles(
        subtitle_files or [],
        source_url=source_url,
        title=title,
        author=author,
        platform=platform,
        created_at=created_at,
        progress=progress,
    )
    video_records = _video_records(
        video_files or [],
        source_url=source_url,
        title=title,
        created_at=created_at,
        progress=progress,
    )
    keyframe_manifest, keyframe_ocr_blocks, keyframe_layout_blocks = _process_images(
        keyframe_files or [],
        source_url=source_url,
        title=title,
        author=author,
        platform=platform,
        created_at=created_at,
        chunk_type="video_keyframe_ocr",
        source_type="video_keyframe_image",
        progress=progress,
    )
    image_manifest, image_ocr_blocks, image_layout_blocks = _process_images(
        image_files or [],
        source_url=source_url,
        title=title,
        author=author,
        platform=platform,
        created_at=created_at,
        chunk_type="image_ocr",
        source_type="visual_image",
        progress=progress,
    )

    video_keyframe_manifest = {
        "schema_version": "video_keyframe_manifest.v1",
        "generated_at": created_at,
        "ffmpeg_available": shutil.which("ffmpeg") is not None,
        "ffprobe_available": shutil.which("ffprobe") is not None,
        "automatic_keyframe_extraction": _automatic_keyframe_status(video_records),
        "user_supplied_keyframe_count": len(keyframe_manifest),
        "video_records": video_records,
        "keyframes": keyframe_manifest,
    }
    timestamp_trace = _timestamp_trace(transcript_rows, created_at=created_at)
    image_trace = _image_trace(image_manifest + keyframe_manifest, created_at=created_at)
    layout_blocks = image_layout_blocks + keyframe_layout_blocks
    multimodal_chunks = _multimodal_chunks(
        transcript_rows + image_ocr_blocks + keyframe_ocr_blocks,
        created_at=created_at,
    )
    evidence_map = _visual_evidence_map(
        transcript_rows=transcript_rows,
        image_blocks=image_ocr_blocks,
        keyframe_blocks=keyframe_ocr_blocks,
        created_at=created_at,
    )
    status = _overall_status(
        transcript_rows=transcript_rows,
        image_blocks=image_ocr_blocks,
        keyframe_blocks=keyframe_ocr_blocks,
        video_records=video_records,
    )
    manifest = {
        "schema_version": "visual_evidence_manifest.v1",
        "section": "5.3.0-P1",
        "campaign": "Campaign 3",
        "supplement": "3.0 External Source Memory & Verification",
        "step": "P1 Video-to-Knowledge and Visual Evidence Understanding foundations",
        "status": status,
        "integration_decision": "real_integration",
        "decision_qualifier": "video_visual_foundations_only",
        "integration_mode": "subtitle_image_keyframe_ocr_to_traceable_multimodal_chunks",
        "generated_at": created_at,
        "source_url": source_url,
        "title": title,
        "transcript_count": len(transcript_rows),
        "image_ocr_count": len(image_ocr_blocks),
        "keyframe_ocr_count": len(keyframe_ocr_blocks),
        "layout_block_count": len(layout_blocks),
        "multimodal_chunk_count": len(multimodal_chunks),
        "video_count": len(video_records),
        "failure_isolation": True,
        "runtime_boundary": _runtime_boundary(video_records, image_ocr_blocks, keyframe_ocr_blocks),
        "safety_boundary": _safety_boundary(),
        "output_files": VIDEO_VISUAL_FILES,
        "not_goal_complete": True,
    }
    validation = _validate_payloads(
        manifest=manifest,
        timestamp_trace=timestamp_trace,
        image_trace=image_trace,
        evidence_map=evidence_map,
        video_keyframe_manifest=video_keyframe_manifest,
    )
    _write_outputs(
        output,
        manifest=manifest,
        transcript_rows=transcript_rows,
        timestamp_trace=timestamp_trace,
        video_keyframe_manifest=video_keyframe_manifest,
        keyframe_ocr_blocks=keyframe_ocr_blocks,
        image_ocr_blocks=image_ocr_blocks,
        layout_blocks=layout_blocks,
        multimodal_chunks=multimodal_chunks,
        image_trace=image_trace,
        evidence_map=evidence_map,
        validation=validation,
        progress=progress,
    )
    return manifest


def validate_video_visual_evidence(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [name for name in VIDEO_VISUAL_FILES if not (library / name).exists()]
    errors = [f"missing_file:{name}" for name in missing]
    manifest = _read_json(library / "visual_evidence_manifest.json")
    timestamp_trace = _read_json(library / "timestamp_trace.json")
    image_trace = _read_json(library / "image_trace.json")
    evidence_map = _read_json(library / "visual_evidence_map.json")
    video_keyframe_manifest = _read_json(library / "video_keyframe_manifest.json")
    if manifest:
        errors.extend(
            _validate_payloads(
                manifest=manifest,
                timestamp_trace=timestamp_trace,
                image_trace=image_trace,
                evidence_map=evidence_map,
                video_keyframe_manifest=video_keyframe_manifest,
            )["boundary_errors"]
        )
    return {
        "schema_version": "video_visual_validation_report.v1",
        "status": "passed" if not errors else "failed",
        "boundary_errors": errors,
        "missing_files": missing,
        "video_visual_foundations_complete": not errors,
        "ffmpeg_available": bool(video_keyframe_manifest.get("ffmpeg_available")),
        "automatic_keyframe_extraction_accepted": (
            video_keyframe_manifest.get("automatic_keyframe_extraction", {}).get("status")
            == "passed"
        ),
        "audio_transcription_runtime_integrated": False,
        "knowledge_verification_engine_complete": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "bridge_execution_accepted": False,
        "supplement_3_0_complete": False,
        "not_goal_complete": True,
    }


def write_video_visual_validation(library: Path, output: Path) -> dict[str, Any]:
    result = validate_video_visual_evidence(library)
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    write_json(output / "video_visual_validation_report.json", result)
    return result


def _parse_subtitles(
    paths: list[Path],
    *,
    source_url: str,
    title: str,
    author: str,
    platform: str,
    created_at: str,
    progress: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for path in paths:
        path = Path(path)
        if not path.exists():
            _progress(progress, "subtitle_import", "failed", f"Subtitle file missing: {path.name}")
            continue
        text = path.read_text(encoding="utf-8")
        cues = _parse_subtitle_text(text)
        for index, cue in enumerate(cues):
            normalized = _normalize(cue["text"])
            content_hash = _hash_text(normalized)
            start = cue["timestamp_start"]
            end = cue["timestamp_end"]
            rows.append(
                {
                    "chunk_id": f"video_segment_{content_hash[:16]}",
                    "chunk_type": "video_segment",
                    "source_type": "subtitle_file",
                    "source_url": source_url,
                    "platform": platform,
                    "title": title,
                    "author": author,
                    "duration": "",
                    "timestamp_start": start,
                    "timestamp_end": end,
                    "transcript": normalized,
                    "ocr_text": "",
                    "visual_summary": "",
                    "evidence_id": f"evidence_{content_hash[:16]}",
                    "content_hash": content_hash,
                    "chunk_index": index,
                    "backlink": _timestamp_backlink(source_url, start),
                    "source_file_name": path.name,
                    "source_path_hash": _path_hash(path),
                    "created_at": created_at,
                    "status": "accepted",
                    "confidence": 1.0,
                }
            )
        _progress(progress, "subtitle_import", "passed", f"Imported {len(cues)} subtitle cues from {path.name}")
    return rows


def _parse_subtitle_text(text: str) -> list[dict[str, str]]:
    blocks = re.split(r"\n\s*\n", text.replace("\r\n", "\n").strip())
    cues: list[dict[str, str]] = []
    for block in blocks:
        lines = [line.strip() for line in block.splitlines() if line.strip()]
        if not lines:
            continue
        timestamp_line = next((line for line in lines if "-->" in line), "")
        if timestamp_line:
            start_raw, end_raw = [part.strip() for part in timestamp_line.split("-->", 1)]
            body_start = lines.index(timestamp_line) + 1
            body = " ".join(lines[body_start:])
            cues.append(
                {
                    "timestamp_start": _normalize_timestamp(start_raw),
                    "timestamp_end": _normalize_timestamp(end_raw),
                    "text": body,
                }
            )
        else:
            body = " ".join(lines)
            if body:
                cues.append({"timestamp_start": "00:00:00.000", "timestamp_end": "", "text": body})
    return [cue for cue in cues if cue["text"]]


def _video_records(
    paths: list[Path],
    *,
    source_url: str,
    title: str,
    created_at: str,
    progress: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    records = []
    ffmpeg_available = shutil.which("ffmpeg") is not None
    ffprobe_available = shutil.which("ffprobe") is not None
    for index, path in enumerate(paths):
        path = Path(path)
        status = _STATUS_SKIPPED
        reason = "ffmpeg/ffprobe are unavailable, so automatic keyframe extraction and audio transcription are skipped."
        suggestion = "Install ffmpeg/ffprobe or provide subtitle files and user-supplied keyframe images."
        if not path.exists():
            status = _STATUS_FAILED
            reason = "Video file does not exist."
            suggestion = "Provide an existing user-selected video file."
        records.append(
            {
                "video_id": f"video_{index + 1:04d}",
                "source_url": source_url,
                "title": title,
                "source_file_name": path.name,
                "source_path_hash": _path_hash(path),
                "status": status,
                "ffmpeg_available": ffmpeg_available,
                "ffprobe_available": ffprobe_available,
                "audio_transcription_status": _STATUS_SKIPPED,
                "keyframe_extraction_status": status,
                "failure_reason": reason,
                "repair_suggestion": suggestion,
                "created_at": created_at,
            }
        )
        _progress(progress, "video_dependency_check", status, f"{path.name}: {reason}")
    return records


def _process_images(
    paths: list[Path],
    *,
    source_url: str,
    title: str,
    author: str,
    platform: str,
    created_at: str,
    chunk_type: str,
    source_type: str,
    progress: list[dict[str, Any]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]]]:
    manifest_rows: list[dict[str, Any]] = []
    ocr_blocks: list[dict[str, Any]] = []
    layout_blocks: list[dict[str, Any]] = []
    for index, path in enumerate(paths):
        path = Path(path)
        base = {
            "image_id": f"{source_type}_{index + 1:04d}",
            "image_index": index,
            "source_file_name": path.name,
            "source_path_hash": _path_hash(path),
            "source_url": source_url,
            "title": title,
            "source_type": source_type,
            "created_at": created_at,
        }
        if not path.exists():
            manifest_rows.append(
                base
                | {
                    "status": _STATUS_FAILED,
                    "failure_reason": "Image file does not exist.",
                    "repair_suggestion": "Provide an existing user-selected image file.",
                }
            )
            _progress(progress, "image_ocr", "failed", f"Image file missing: {path.name}")
            continue
        ocr_result = _ocr_image(path)
        status = "accepted" if ocr_result["status"] == "passed" else _STATUS_FAILED
        content_hash = _hash_text(ocr_result["text"] or path.name)
        manifest_rows.append(
            base
            | {
                "status": status,
                "failure_reason": ocr_result["failure_reason"],
                "repair_suggestion": ocr_result["repair_suggestion"],
                "content_hash": content_hash,
                "width": ocr_result.get("width"),
                "height": ocr_result.get("height"),
            }
        )
        if status == "accepted":
            evidence_id = f"evidence_{content_hash[:16]}"
            block = {
                "chunk_id": f"{chunk_type}_{content_hash[:16]}",
                "chunk_type": chunk_type,
                "source_type": source_type,
                "source_url": source_url,
                "platform": platform,
                "title": title,
                "author": author,
                "published_at": "",
                "retrieved_at": created_at,
                "content_hash": content_hash,
                "text": ocr_result["text"],
                "ocr_text": ocr_result["text"],
                "visual_summary": _visual_summary(ocr_result["text"]),
                "timestamp_start": _timestamp_from_name(path.name),
                "timestamp_end": "",
                "image_index": str(index),
                "bbox": "full_image",
                "backlink": _image_backlink(source_url, index),
                "evidence_id": evidence_id,
                "confidence": ocr_result["confidence"],
                "source_file_name": path.name,
                "source_path_hash": _path_hash(path),
                "status": "accepted",
            }
            ocr_blocks.append(block)
            layout_blocks.append(
                {
                    "layout_block_id": f"layout_{content_hash[:16]}",
                    "chunk_type": "layout_block",
                    "source_type": source_type,
                    "image_index": index,
                    "bbox": "full_image",
                    "text": ocr_result["text"],
                    "ocr_text": ocr_result["text"],
                    "content_hash": content_hash,
                    "evidence_id": evidence_id,
                    "status": "accepted",
                }
            )
        _progress(progress, "image_ocr", status, f"{path.name}: {ocr_result['message']}")
    return manifest_rows, ocr_blocks, layout_blocks


def _ocr_image(path: Path) -> dict[str, Any]:
    if importlib.util.find_spec("PIL") is None or importlib.util.find_spec("pytesseract") is None:
        return {
            "status": "failed",
            "text": "",
            "message": "Pillow or pytesseract is unavailable.",
            "failure_reason": "OCR dependency missing.",
            "repair_suggestion": "Install Pillow and pytesseract, or provide subtitle/manual evidence.",
            "confidence": 0.0,
        }
    try:
        from PIL import Image
        import pytesseract

        with Image.open(path) as image:
            text = (pytesseract.image_to_string(image) or "").strip()
            width, height = image.size
    except Exception as exc:  # pragma: no cover - dependent on native OCR runtime
        return {
            "status": "failed",
            "text": "",
            "message": f"OCR failed: {exc}",
            "failure_reason": f"OCR failed: {exc}",
            "repair_suggestion": "Check image readability or OCR installation.",
            "confidence": 0.0,
        }
    return {
        "status": "passed" if text else "failed",
        "text": text,
        "message": "OCR text extracted." if text else "OCR returned empty text.",
        "failure_reason": "" if text else "OCR returned empty text.",
        "repair_suggestion": "" if text else "Provide a clearer image or manual evidence.",
        "confidence": 0.8 if text else 0.0,
        "width": width,
        "height": height,
    }


def _timestamp_trace(rows: list[dict[str, Any]], *, created_at: str) -> dict[str, Any]:
    return {
        "schema_version": "timestamp_trace.v1",
        "generated_at": created_at,
        "segment_count": len(rows),
        "segments": [
            {
                "chunk_id": row["chunk_id"],
                "evidence_id": row["evidence_id"],
                "timestamp_start": row["timestamp_start"],
                "timestamp_end": row["timestamp_end"],
                "backlink": row["backlink"],
                "content_hash": row["content_hash"],
            }
            for row in rows
        ],
    }


def _image_trace(rows: list[dict[str, Any]], *, created_at: str) -> dict[str, Any]:
    return {
        "schema_version": "image_trace.v1",
        "generated_at": created_at,
        "image_count": len(rows),
        "images": [
            {
                "image_id": row["image_id"],
                "image_index": row["image_index"],
                "source_type": row["source_type"],
                "source_file_name": row["source_file_name"],
                "source_path_hash": row["source_path_hash"],
                "source_url": row["source_url"],
                "status": row["status"],
                "content_hash": row.get("content_hash", ""),
                "failure_reason": row.get("failure_reason", ""),
            }
            for row in rows
        ],
    }


def _visual_evidence_map(
    *,
    transcript_rows: list[dict[str, Any]],
    image_blocks: list[dict[str, Any]],
    keyframe_blocks: list[dict[str, Any]],
    created_at: str,
) -> dict[str, Any]:
    rows = transcript_rows + image_blocks + keyframe_blocks
    return {
        "schema_version": "visual_evidence_map.v1",
        "generated_at": created_at,
        "evidence_count": len(rows),
        "evidence": [
            {
                "source_id": _source_id(row.get("source_url", "") or row.get("source_file_name", "")),
                "evidence_id": row["evidence_id"],
                "chunk_id": row["chunk_id"],
                "chunk_type": row["chunk_type"],
                "source_type": row["source_type"],
                "content_hash": row["content_hash"],
                "integration_mode": "video_visual_foundations",
                "backlink": row["backlink"],
            }
            for row in rows
        ],
        "knowledge_verification_engine_complete": False,
    }


def _multimodal_chunks(rows: list[dict[str, Any]], *, created_at: str) -> list[dict[str, Any]]:
    chunks = []
    for row in rows:
        chunks.append(
            {
                "chunk_id": row["chunk_id"],
                "chunk_type": row["chunk_type"],
                "source_type": row["source_type"],
                "source_url": row.get("source_url", ""),
                "title": row.get("title", ""),
                "text": row.get("transcript") or row.get("text") or row.get("ocr_text", ""),
                "ocr_text": row.get("ocr_text", ""),
                "visual_summary": row.get("visual_summary", ""),
                "timestamp_start": row.get("timestamp_start", ""),
                "timestamp_end": row.get("timestamp_end", ""),
                "image_index": row.get("image_index", ""),
                "bbox": row.get("bbox", ""),
                "backlink": row.get("backlink", ""),
                "evidence_id": row["evidence_id"],
                "content_hash": row["content_hash"],
                "created_at": created_at,
            }
        )
    return chunks


def _runtime_boundary(
    video_records: list[dict[str, Any]],
    image_blocks: list[dict[str, Any]],
    keyframe_blocks: list[dict[str, Any]],
) -> dict[str, bool]:
    return {
        "subtitle_transcript_import_implemented": True,
        "timestamp_trace_implemented": True,
        "image_ocr_runtime_integrated": bool(image_blocks or keyframe_blocks),
        "keyframe_ocr_runtime_integrated": bool(keyframe_blocks),
        "user_supplied_keyframe_ocr_supported": True,
        "automatic_keyframe_extraction_implemented": any(
            record["keyframe_extraction_status"] == _STATUS_PASSED for record in video_records
        ),
        "audio_transcription_runtime_integrated": False,
        "video_file_metadata_handled": bool(video_records),
        "layout_blocks_implemented": True,
        "multimodal_chunks_implemented": True,
        "knowledge_verification_runtime_implemented": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "bridge_execution_accepted": False,
        "supplement_3_0_complete": False,
    }


def _safety_boundary() -> dict[str, bool]:
    return {
        "user_supplied_files_only": True,
        "no_cookie_import": True,
        "no_login_bypass": True,
        "no_paywall_bypass": True,
        "no_platform_control_bypass": True,
        "no_unlimited_crawler": True,
        "no_arbitrary_shell_execution": True,
        "failure_isolation": True,
    }


def _validate_payloads(
    *,
    manifest: dict[str, Any],
    timestamp_trace: dict[str, Any],
    image_trace: dict[str, Any],
    evidence_map: dict[str, Any],
    video_keyframe_manifest: dict[str, Any],
) -> dict[str, Any]:
    errors = []
    runtime = manifest.get("runtime_boundary", {})
    safety = manifest.get("safety_boundary", {})
    if runtime.get("knowledge_verification_runtime_implemented") is not False:
        errors.append("knowledge_verification_runtime_must_be_false")
    if runtime.get("campaign_4_active") is not False or runtime.get("campaign_5_active") is not False:
        errors.append("campaign_4_5_must_be_false")
    if runtime.get("audio_transcription_runtime_integrated") is not False:
        errors.append("audio_transcription_must_not_be_overclaimed")
    if safety.get("no_arbitrary_shell_execution") is not True:
        errors.append("no_arbitrary_shell_execution_required")
    if evidence_map.get("knowledge_verification_engine_complete") is not False:
        errors.append("visual_evidence_map_must_not_complete_knowledge_verification")
    if "segments" not in timestamp_trace:
        errors.append("timestamp_trace_segments_missing")
    if "images" not in image_trace:
        errors.append("image_trace_images_missing")
    extraction = video_keyframe_manifest.get("automatic_keyframe_extraction", {})
    if extraction.get("status") == _STATUS_PASSED and not extraction.get("artifact_count", 0):
        errors.append("automatic_keyframe_passed_without_artifacts")
    return {
        "schema_version": "video_visual_validation_report.v1",
        "status": "passed" if not errors else "failed",
        "boundary_errors": errors,
        "missing_files": [],
        "video_visual_foundations_complete": not errors,
        "knowledge_verification_engine_complete": False,
        "campaign_4_active": False,
        "campaign_5_active": False,
        "bridge_execution_accepted": False,
        "supplement_3_0_complete": False,
        "not_goal_complete": True,
    }


def _write_outputs(
    output: Path,
    *,
    manifest: dict[str, Any],
    transcript_rows: list[dict[str, Any]],
    timestamp_trace: dict[str, Any],
    video_keyframe_manifest: dict[str, Any],
    keyframe_ocr_blocks: list[dict[str, Any]],
    image_ocr_blocks: list[dict[str, Any]],
    layout_blocks: list[dict[str, Any]],
    multimodal_chunks: list[dict[str, Any]],
    image_trace: dict[str, Any],
    evidence_map: dict[str, Any],
    validation: dict[str, Any],
    progress: list[dict[str, Any]],
) -> None:
    write_jsonl(output / "video_transcript.jsonl", transcript_rows)
    write_json(output / "video_timestamp_trace.json", timestamp_trace)
    write_json(output / "timestamp_trace.json", timestamp_trace)
    write_json(output / "video_keyframe_manifest.json", video_keyframe_manifest)
    write_jsonl(output / "video_keyframe_ocr_blocks.jsonl", keyframe_ocr_blocks)
    write_json(output / "visual_evidence_manifest.json", manifest)
    write_jsonl(output / "image_ocr_blocks.jsonl", image_ocr_blocks)
    write_jsonl(output / "layout_blocks.jsonl", layout_blocks)
    write_jsonl(output / "multimodal_chunks.jsonl", multimodal_chunks)
    write_json(output / "image_trace.json", image_trace)
    write_json(output / "visual_evidence_map.json", evidence_map)
    write_json(output / "video_visual_validation_report.json", validation)
    write_jsonl(output / "progress_events.jsonl", progress)
    (output / "visual_understanding_report.md").write_text(
        _render_report(manifest, validation), encoding="utf-8"
    )
    run_manifest = {
        "schema_version": "audit_run_manifest.v1",
        "run_id": "external_source_video_visual_foundations",
        "generated_at": manifest["generated_at"],
        "type": "section_5_supplement_3_0_p1_video_visual_foundations",
        "scope": "CAMPAIGN_3_SUPPLEMENT_3_0_P1_VIDEO_VISUAL_FOUNDATIONS",
        "status": validation["status"],
        "integration_decision": manifest["integration_decision"],
        "decision_qualifier": manifest["decision_qualifier"],
        "evidence_files": VIDEO_VISUAL_FILES,
        "next_business_item": "Campaign 3 Supplement 3.0 P1 Knowledge Verification Engine and dashboard foundations",
        "campaign_4_active": False,
        "campaign_5_active": False,
        "bridge_execution_accepted": False,
        "supplement_3_0_complete": False,
        "not_goal_complete": True,
    }
    write_json(output / "run_manifest.json", run_manifest)
    (output / "run_summary.md").write_text(_render_summary(run_manifest), encoding="utf-8")


def _overall_status(
    *,
    transcript_rows: list[dict[str, Any]],
    image_blocks: list[dict[str, Any]],
    keyframe_blocks: list[dict[str, Any]],
    video_records: list[dict[str, Any]],
) -> str:
    accepted = bool(transcript_rows or image_blocks or keyframe_blocks)
    failed = any(record["status"] == _STATUS_FAILED for record in video_records)
    skipped = any(record["status"] == _STATUS_SKIPPED for record in video_records)
    if accepted and (failed or skipped):
        return _STATUS_PARTIAL
    if accepted:
        return _STATUS_PASSED
    if skipped and not failed:
        return _STATUS_SKIPPED
    return _STATUS_FAILED


def _automatic_keyframe_status(video_records: list[dict[str, Any]]) -> dict[str, Any]:
    if not video_records:
        return {
            "status": _STATUS_SKIPPED,
            "artifact_count": 0,
            "failure_reason": "No video files were provided for automatic keyframe extraction.",
            "repair_suggestion": "Provide video files or user-supplied keyframe images.",
        }
    if any(record["keyframe_extraction_status"] == _STATUS_PASSED for record in video_records):
        return {"status": _STATUS_PASSED, "artifact_count": 1, "failure_reason": "", "repair_suggestion": ""}
    return {
        "status": _STATUS_SKIPPED,
        "artifact_count": 0,
        "failure_reason": video_records[0]["failure_reason"],
        "repair_suggestion": video_records[0]["repair_suggestion"],
    }


def _progress(events: list[dict[str, Any]], stage: str, status: str, message: str) -> None:
    events.append(
        {
            "event_id": f"evt_{uuid4().hex[:12]}",
            "stage": stage,
            "status": status,
            "timestamp": _now(),
            "message": message,
            "artifact_path": "",
        }
    )


def _normalize_timestamp(value: str) -> str:
    cleaned = value.strip().replace(",", ".")
    match = re.search(r"(\d{1,2}:\d{2}:\d{2}(?:\.\d{1,3})?)", cleaned)
    if not match:
        return cleaned
    parsed = match.group(1)
    if "." not in parsed:
        parsed += ".000"
    return parsed


def _timestamp_seconds(value: str) -> int:
    match = re.match(r"(?P<h>\d+):(?P<m>\d+):(?P<s>\d+)", value or "")
    if not match:
        return 0
    return int(match.group("h")) * 3600 + int(match.group("m")) * 60 + int(match.group("s"))


def _timestamp_backlink(source_url: str, timestamp: str) -> str:
    if not source_url:
        return f"timestamp_trace.json#{timestamp}"
    return f"{source_url}#t={_timestamp_seconds(timestamp)}"


def _image_backlink(source_url: str, index: int) -> str:
    if not source_url:
        return f"image_trace.json#image-{index}"
    return f"{source_url}#image={index}"


def _timestamp_from_name(name: str) -> str:
    match = re.search(r"(?P<m>\d{1,2})m(?P<s>\d{1,2})s", name)
    if match:
        return f"00:{int(match.group('m')):02d}:{int(match.group('s')):02d}.000"
    match = re.search(r"(?P<s>\d{1,5})s", name)
    if match:
        seconds = int(match.group("s"))
        return f"{seconds // 3600:02d}:{(seconds % 3600) // 60:02d}:{seconds % 60:02d}.000"
    return ""


def _visual_summary(text: str) -> str:
    normalized = _normalize(text)
    return f"OCR visible text: {normalized[:120]}" if normalized else ""


def _normalize(text: str) -> str:
    return " ".join((text or "").split())


def _hash_text(text: str) -> str:
    return hashlib.sha256(_normalize(text).encode("utf-8")).hexdigest()


def _path_hash(path: Path) -> str:
    return hashlib.sha256(str(Path(path).name).encode("utf-8")).hexdigest()


def _source_id(value: str) -> str:
    return f"source_{hashlib.sha256(value.encode('utf-8')).hexdigest()[:16]}"


def _platform_from_url(source_url: str) -> str:
    return urlsplit(source_url).hostname or ""


def _read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    import json

    return json.loads(path.read_text(encoding="utf-8"))


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _render_report(manifest: dict[str, Any], validation: dict[str, Any]) -> str:
    failures = "\n".join(f"- {error}" for error in validation["boundary_errors"]) or "- None"
    return (
        "# Video / Visual Evidence Foundations Report\n\n"
        f"- Status: `{validation['status']}`\n"
        f"- Decision: `{manifest['integration_decision']} / {manifest['decision_qualifier']}`\n"
        f"- Transcripts: `{manifest['transcript_count']}`\n"
        f"- Image OCR blocks: `{manifest['image_ocr_count']}`\n"
        f"- Keyframe OCR blocks: `{manifest['keyframe_ocr_count']}`\n"
        "- Automatic video keyframe extraction is dependency-aware and remains skipped when ffmpeg/ffprobe are unavailable.\n"
        "- Audio transcription runtime, Knowledge Verification, Campaign 4, Campaign 5, and Supplement 3.0 acceptance remain false.\n\n"
        "## Validation Errors\n\n"
        f"{failures}\n"
    )


def _render_summary(run_manifest: dict[str, Any]) -> str:
    return (
        "# Video / Visual Evidence Foundations Summary\n\n"
        f"- Status: `{run_manifest['status']}`\n"
        f"- Decision: `{run_manifest['integration_decision']} / {run_manifest['decision_qualifier']}`\n"
        f"- Next business item: `{run_manifest['next_business_item']}`\n"
        "- This is still Campaign 3 Supplement 3.0 internal work, not Supplement 4.0, Campaign 4, or Campaign 5.\n"
    )
