from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.release_blockers.report import render_release_blockers_report
from heitang_kb_forge.schemas.release_blocker_schema import ReleaseBlockerFinding, ReleaseBlockerResult


def detect_release_blockers(workspace: Path, output: Path) -> ReleaseBlockerResult:
    output.mkdir(parents=True, exist_ok=True)
    blockers: list[ReleaseBlockerFinding] = []
    _check_file(workspace, "manifest.json", "missing_required_file", blockers)
    _check_platform_boundaries(workspace, blockers)
    critical_count = sum(1 for item in blockers if item.severity == "critical")
    status = "fail" if critical_count else "warning" if blockers else "pass"
    result = ReleaseBlockerResult(
        status=status,
        release_ready=critical_count == 0,
        blocker_count=len(blockers),
        critical_count=critical_count,
        blockers=blockers,
    )
    write_json(output / "release_blockers.json", result)
    write_jsonl(output / "release_blocker_findings.jsonl", [item.model_dump(mode="json") for item in blockers])
    (output / "release_blockers.md").write_text(render_release_blockers_report(result), encoding="utf-8")
    return result


def _check_file(workspace: Path, relative: str, blocker_type: str, blockers: list[ReleaseBlockerFinding]) -> None:
    if not (workspace / relative).exists():
        blockers.append(
            ReleaseBlockerFinding(blocker_type=blocker_type, severity="medium", message=f"Missing {relative}", path=relative)
        )


def _check_platform_boundaries(workspace: Path, blockers: list[ReleaseBlockerFinding]) -> None:
    docs = "\n".join(path.read_text(encoding="utf-8", errors="ignore") for path in workspace.rglob("*.md"))
    if "xhs" in docs.lower() and "official XHS upload API" not in docs and "官方上传 API" not in docs:
        blockers.append(
            ReleaseBlockerFinding(
                blocker_type="unsupported_real_runtime_claim",
                severity="critical",
                message="XHS documentation must state it is not an official upload API.",
            )
        )
    if "mcp" in docs.lower() and "stub" not in docs.lower() and "不启动 MCP Server" not in docs:
        blockers.append(
            ReleaseBlockerFinding(
                blocker_type="unsupported_real_runtime_claim",
                severity="critical",
                message="MCP documentation must state it is stub-only or no server is started.",
            )
        )

