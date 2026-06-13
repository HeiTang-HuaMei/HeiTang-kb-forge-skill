import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.external_sources import build_video_visual_evidence, validate_video_visual_evidence
import heitang_kb_forge.external_sources.video_visual as video_visual


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _jsonl(path: Path) -> list[dict]:
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def _subtitle(path: Path) -> Path:
    path.write_text(
        "1\n"
        "00:00:01,000 --> 00:00:03,500\n"
        "First visible claim from a video.\n\n"
        "2\n"
        "00:00:04,000 --> 00:00:07,000\n"
        "Second segment with timestamp trace.\n",
        encoding="utf-8",
    )
    return path


def _image(path: Path) -> Path:
    from PIL import Image, ImageDraw

    image = Image.new("RGB", (460, 120), "white")
    draw = ImageDraw.Draw(image)
    draw.text((20, 40), "VISUAL OCR CLAIM", fill="black")
    image.save(path)
    return path


def test_subtitle_and_image_build_traceable_multimodal_chunks(monkeypatch, tmp_path):
    monkeypatch.setattr(
        video_visual,
        "_ocr_image",
        lambda path: {
            "status": "passed",
            "text": "VISUAL OCR CLAIM",
            "message": "OCR text extracted.",
            "failure_reason": "",
            "repair_suggestion": "",
            "confidence": 0.8,
            "width": 460,
            "height": 120,
        },
    )
    subtitle = _subtitle(tmp_path / "sample.srt")
    image = _image(tmp_path / "frame_00m04s.png")

    manifest = build_video_visual_evidence(
        tmp_path / "out",
        subtitle_files=[subtitle],
        image_files=[image],
        source_url="https://video.example/watch/abc",
        title="Traceable video",
        author="Visible author",
        platform="example_video",
    )
    validation = validate_video_visual_evidence(tmp_path / "out")
    transcript = _jsonl(tmp_path / "out" / "video_transcript.jsonl")
    timestamp_trace = _json(tmp_path / "out" / "timestamp_trace.json")
    image_blocks = _jsonl(tmp_path / "out" / "image_ocr_blocks.jsonl")
    layout_blocks = _jsonl(tmp_path / "out" / "layout_blocks.jsonl")
    chunks = _jsonl(tmp_path / "out" / "multimodal_chunks.jsonl")
    evidence = _json(tmp_path / "out" / "visual_evidence_map.json")

    assert manifest["status"] == "passed"
    assert manifest["decision_qualifier"] == "video_visual_foundations_only"
    assert validation["status"] == "passed"
    assert len(transcript) == 2
    assert transcript[0]["timestamp_start"] == "00:00:01.000"
    assert transcript[0]["backlink"].endswith("#t=1")
    assert timestamp_trace["segment_count"] == 2
    assert image_blocks[0]["chunk_type"] == "image_ocr"
    assert image_blocks[0]["ocr_text"] == "VISUAL OCR CLAIM"
    assert image_blocks[0]["timestamp_start"] == "00:00:04.000"
    assert layout_blocks[0]["bbox"] == "full_image"
    assert {chunk["chunk_type"] for chunk in chunks} == {"video_segment", "image_ocr"}
    assert evidence["evidence_count"] == 3
    assert evidence["knowledge_verification_engine_complete"] is False


def test_user_supplied_keyframe_ocr_and_ffmpeg_missing_are_structured(monkeypatch, tmp_path):
    monkeypatch.setattr(video_visual.shutil, "which", lambda name: None)
    monkeypatch.setattr(
        video_visual,
        "_ocr_image",
        lambda path: {
            "status": "passed",
            "text": "KEYFRAME TEXT",
            "message": "OCR text extracted.",
            "failure_reason": "",
            "repair_suggestion": "",
            "confidence": 0.8,
            "width": 460,
            "height": 120,
        },
    )
    keyframe = _image(tmp_path / "keyframe_12s.png")
    video = tmp_path / "visible-video.mp4"
    video.write_bytes(b"not a real video; dependency check only")

    build_video_visual_evidence(
        tmp_path / "out",
        keyframe_files=[keyframe],
        video_files=[video],
        source_url="https://video.example/watch/abc",
        title="Traceable video",
    )
    manifest = _json(tmp_path / "out" / "visual_evidence_manifest.json")
    keyframes = _json(tmp_path / "out" / "video_keyframe_manifest.json")
    blocks = _jsonl(tmp_path / "out" / "video_keyframe_ocr_blocks.jsonl")
    progress = _jsonl(tmp_path / "out" / "progress_events.jsonl")

    assert manifest["status"] == "partial"
    assert manifest["runtime_boundary"]["automatic_keyframe_extraction_implemented"] is False
    assert manifest["runtime_boundary"]["audio_transcription_runtime_integrated"] is False
    assert keyframes["automatic_keyframe_extraction"]["status"] == "skipped"
    assert "ffmpeg/ffprobe" in keyframes["automatic_keyframe_extraction"]["failure_reason"]
    assert blocks[0]["chunk_type"] == "video_keyframe_ocr"
    assert blocks[0]["timestamp_start"] == "00:00:12.000"
    assert any(event["status"] == "skipped" for event in progress)


def test_ocr_failure_is_isolated_without_breaking_subtitle_import(monkeypatch, tmp_path):
    monkeypatch.setattr(
        video_visual,
        "_ocr_image",
        lambda path: {
            "status": "failed",
            "text": "",
            "message": "OCR returned empty text.",
            "failure_reason": "OCR returned empty text.",
            "repair_suggestion": "Provide a clearer image or manual evidence.",
            "confidence": 0.0,
        },
    )
    subtitle = _subtitle(tmp_path / "sample.srt")
    image = _image(tmp_path / "empty.png")

    build_video_visual_evidence(tmp_path / "out", subtitle_files=[subtitle], image_files=[image])
    manifest = _json(tmp_path / "out" / "visual_evidence_manifest.json")
    image_trace = _json(tmp_path / "out" / "image_trace.json")
    transcript = _jsonl(tmp_path / "out" / "video_transcript.jsonl")

    assert manifest["status"] == "passed"
    assert manifest["failure_isolation"] is True
    assert len(transcript) == 2
    assert image_trace["images"][0]["status"] == "failed"
    assert image_trace["images"][0]["failure_reason"] == "OCR returned empty text."


def test_cli_build_and_validate_video_visual_evidence(monkeypatch, tmp_path):
    monkeypatch.setattr(
        video_visual,
        "_ocr_image",
        lambda path: {
            "status": "passed",
            "text": "CLI OCR TEXT",
            "message": "OCR text extracted.",
            "failure_reason": "",
            "repair_suggestion": "",
            "confidence": 0.8,
            "width": 460,
            "height": 120,
        },
    )
    runner = CliRunner()
    output = tmp_path / "out"
    subtitle = _subtitle(tmp_path / "sample.srt")
    image = _image(tmp_path / "image.png")

    build = runner.invoke(
        app,
        [
            "build-video-visual-evidence",
            "--output",
            str(output),
            "--subtitle",
            str(subtitle),
            "--image",
            str(image),
            "--source-url",
            "https://video.example/watch/abc",
            "--title",
            "CLI video",
        ],
    )
    validate = runner.invoke(
        app,
        ["validate-video-visual-evidence", "--library", str(output), "--output", str(output)],
    )

    assert build.exit_code == 0, build.output
    assert "video_visual_foundations_only" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output


def test_video_visual_does_not_claim_later_campaigns_or_knowledge_verification(tmp_path):
    subtitle = _subtitle(tmp_path / "sample.srt")
    build_video_visual_evidence(tmp_path / "out", subtitle_files=[subtitle])
    manifest = _json(tmp_path / "out" / "visual_evidence_manifest.json")
    validation = validate_video_visual_evidence(tmp_path / "out")
    run_manifest = _json(tmp_path / "out" / "run_manifest.json")

    assert manifest["runtime_boundary"]["knowledge_verification_runtime_implemented"] is False
    assert manifest["runtime_boundary"]["campaign_4_active"] is False
    assert manifest["runtime_boundary"]["campaign_5_active"] is False
    assert manifest["runtime_boundary"]["bridge_execution_accepted"] is False
    assert manifest["runtime_boundary"]["supplement_3_0_complete"] is False
    assert validation["knowledge_verification_engine_complete"] is False
    assert validation["supplement_3_0_complete"] is False
    assert run_manifest["next_business_item"] == (
        "Campaign 3 Supplement 3.0 P1 Knowledge Verification Engine and dashboard foundations"
    )
