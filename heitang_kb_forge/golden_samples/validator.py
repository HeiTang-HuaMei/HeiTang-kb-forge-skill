from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.golden_samples.registry import make_registry
from heitang_kb_forge.golden_samples.report import render_golden_sample_report
from heitang_kb_forge.schemas.golden_sample_schema import GoldenSampleRecord, GoldenSampleValidation


def validate_golden_samples(samples_root: Path, output: Path) -> GoldenSampleValidation:
    output.mkdir(parents=True, exist_ok=True)
    registry = make_registry(samples_root)
    samples = [
        GoldenSampleRecord(
            sample_id=item["sample_id"],
            path=str(Path(item["path"])).replace("\\", "/"),
            status="pass" if Path(item["path"]).exists() else "fail",
        )
        for item in registry
    ]
    failed = [sample for sample in samples if sample.status == "fail"]
    result = GoldenSampleValidation(
        status="fail" if failed else "pass",
        sample_count=len(samples),
        passed=len(samples) - len(failed),
        failed=len(failed),
        samples=samples,
    )
    write_json(output / "golden_sample_registry.json", {"samples": registry})
    write_json(output / "golden_sample_validation.json", result)
    write_json(output / "golden_sample_diff.json", {"changed": [], "missing": [sample.sample_id for sample in failed]})
    (output / "golden_sample_validation_report.md").write_text(render_golden_sample_report(result), encoding="utf-8")
    return result

