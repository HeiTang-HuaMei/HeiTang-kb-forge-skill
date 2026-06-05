from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.platform_distribution_schema import MockPublishResult


def mock_publish_package(export: Path, platform: str, output: Path | None = None) -> MockPublishResult:
    target = output or export
    target.mkdir(parents=True, exist_ok=True)
    result = MockPublishResult(
        platform=platform,
        note=(
            "Mock publish only. No external platform API was called, no network request was made, "
            "and no real account or runtime was used."
        ),
    )
    write_json(target / "mock_publish_result.json", result)
    return result
