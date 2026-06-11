import json

import pytest
from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.methodology import extract_methodology
from heitang_kb_forge.schemas.methodology_schema import EvidenceWindowBundle, MethodologyMap
from tests.p0_helpers import make_p0_package, write_jsonl


def _read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def test_extract_methodology_cli_builds_source_traced_outputs(tmp_path):
    package = make_p0_package(tmp_path)
    write_jsonl(
        package / "chunks.jsonl",
        [
            {
                "chunk_id": "c0",
                "source_path": "operations.md",
                "title": "Evidence-led Operations",
                "text": (
                    "Use local evidence and prefer narrow scope. "
                    "When evidence is missing, stop and request review.\n"
                    "1. First inspect the source. 2. Then apply the decision rule.\n"
                    "Avoid unsupported claims. This method applies to local knowledge workflows."
                ),
                "metadata": {"parse_confidence": 0.92},
            }
        ],
    )
    output = tmp_path / "methodology"

    result = CliRunner().invoke(
        app,
        ["extract-methodology", "--kb", str(package), "--out", str(output)],
    )

    assert result.exit_code == 0, result.output
    assert set(path.name for path in output.iterdir()) == {
        "evidence_windows.json",
        "methodology_map.json",
        "methodology_map.md",
        "source_trace.json",
    }
    windows = EvidenceWindowBundle.model_validate(_read_json(output / "evidence_windows.json"))
    methodology = MethodologyMap.model_validate(_read_json(output / "methodology_map.json"))
    trace = _read_json(output / "source_trace.json")
    assert windows.window_count == 1
    assert windows.windows[0].source_evidence[0].citation == "operations.md#chunk=c0"
    assert methodology.module_count == 1
    assert methodology.principles
    assert methodology.decision_rules
    assert methodology.workflows
    assert methodology.anti_patterns
    assert methodology.applicability_boundary
    assert all(item.source_evidence == ["window_001"] for item in methodology.principles)
    assert methodology.unsupported_claim_detection == {"status": "pass", "excluded_count": 0}
    assert trace["source_trace_preserved"] is True
    assert "Modules: 1" in result.output


def test_extract_methodology_marks_low_confidence_and_missing_execution_evidence(tmp_path):
    package = make_p0_package(tmp_path)
    write_jsonl(
        package / "chunks.jsonl",
        [
            {
                "chunk_id": "c0",
                "source_path": "fragment.md",
                "title": "Fragment",
                "text": "A short descriptive fragment.",
                "metadata": {"parse_confidence": 0.4},
            }
        ],
    )

    result = extract_methodology(package, tmp_path / "methodology")

    assert "low_confidence_evidence" in result["risk_flags"]
    assert "missing_principle_evidence" in result["risk_flags"]
    assert "missing_execution_evidence" in result["risk_flags"]
    assert result["confidence"] < 0.4


def test_extract_methodology_requires_non_empty_chunks(tmp_path):
    package = tmp_path / "package"
    package.mkdir()
    write_jsonl(package / "chunks.jsonl", [])

    with pytest.raises(ValueError, match="non-empty chunks.jsonl"):
        extract_methodology(package, tmp_path / "methodology")


def test_extract_methodology_marks_empty_chunk_as_missing_evidence(tmp_path):
    package = make_p0_package(tmp_path)
    write_jsonl(
        package / "chunks.jsonl",
        [{"chunk_id": "c0", "source_path": "empty.md", "title": "Empty", "text": ""}],
    )

    result = extract_methodology(package, tmp_path / "methodology")

    assert "missing_evidence_text" in result["risk_flags"]
    assert "low_confidence_evidence" in result["risk_flags"]
    assert result["confidence"] == 0.0
