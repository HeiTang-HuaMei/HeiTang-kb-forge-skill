from __future__ import annotations

import json
import shutil
from datetime import datetime, timezone
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.llm.quality_gate_assist import run_llm_quality_gate_assist
from heitang_kb_forge.platform_distribution import export_platform_package
from heitang_kb_forge.provider_security import run_provider_security_audit
from heitang_kb_forge.quality_gate import evaluate_quality_gate
from heitang_kb_forge.release_readiness import evaluate_release_readiness


DEMO_E2E_OUTPUT_FILES = [
    "demo_e2e_result.json",
    "portfolio_demo_report.md",
    "runtime_limitations.md",
    "demo_evidence_pack/",
]


def run_demo_e2e(output: Path, input_path: Path | None = None, domain: str = "portfolio", mode: str = "demo") -> dict:
    output.mkdir(parents=True, exist_ok=True)
    source_dir = input_path or _write_demo_input(output / "_demo_input")
    package_dir = output / "knowledge_package"
    stages: list[dict] = []

    from heitang_kb_forge.cli_runtime import _build_package

    manifest = _build_package(source_dir, package_dir, domain, mode, 1200, 120)
    stages.append(_stage("build_knowledge_package", "success", [str(package_dir / "manifest.json")]))

    quality_result, quality_summary, acceptance = evaluate_quality_gate(package_dir)
    write_json(output / "quality_gate_result.json", quality_result)
    (output / "quality_gate_summary.md").write_text(quality_summary, encoding="utf-8")
    (output / "package_acceptance_report.md").write_text(acceptance, encoding="utf-8")
    stages.append(_stage("quality_gate", quality_result["status"], [str(output / "quality_gate_result.json")]))

    provider_security = run_provider_security_audit(output / "provider_workspace", output / "provider_security")
    stages.append(_stage("provider_security_audit", provider_security["status"], [str(output / "provider_security" / "provider_security_audit.json")]))

    llm_assist = run_llm_quality_gate_assist(output, output / "llm_quality_gate_assist", "mock")
    stages.append(_stage("llm_quality_gate_assist_mock", llm_assist["status"], [str(output / "llm_quality_gate_assist" / "llm_quality_gate_assist_result.json")]))

    platform_outputs = []
    for platform in ["generic", "codex", "openclaw"]:
        platform_dir = output / "platform_exports" / platform
        export_platform_package(output, None, platform_dir, platform)
        platform_outputs.append(str(platform_dir / "platform_manifest.json"))
    stages.append(_stage("export_platform_generic_codex_openclaw", "success", platform_outputs))

    release_readiness = evaluate_release_readiness(Path.cwd(), output / "release_readiness")
    stages.append(_stage("release_readiness", release_readiness.status, [str(output / "release_readiness" / "release_readiness_result.json")]))

    limitations = _runtime_limitations()
    (output / "runtime_limitations.md").write_text(limitations, encoding="utf-8")
    result = {
        "demo_e2e_version": "2.7.0-alpha.1",
        "generated_at": _now(),
        "status": _final_status(stages),
        "offline": True,
        "mock_provider": True,
        "network_called": False,
        "real_platform_runtime_executed": False,
        "mcp_server_started": False,
        "xhs_auto_publish": False,
        "input": str(source_dir).replace("\\", "/"),
        "output": str(output).replace("\\", "/"),
        "package_manifest": manifest.model_dump(mode="json"),
        "stages": stages,
        "output_files": DEMO_E2E_OUTPUT_FILES,
    }
    write_json(output / "demo_e2e_result.json", result)
    (output / "portfolio_demo_report.md").write_text(_render_portfolio_report(result), encoding="utf-8")
    _write_evidence_pack(output, result)
    return result


def _write_demo_input(input_dir: Path) -> Path:
    input_dir.mkdir(parents=True, exist_ok=True)
    (input_dir / "001_demo.md").write_text(
        "# HeiTang KB Forge Demo\n\n"
        "This local portfolio demo builds a knowledge package, checks quality, audits provider security, "
        "runs mock LLM quality gate assist, exports generic/Codex/OpenClaw packages, and records release readiness.\n",
        encoding="utf-8",
    )
    return input_dir


def _write_evidence_pack(output: Path, result: dict) -> None:
    pack = output / "demo_evidence_pack"
    pack.mkdir(parents=True, exist_ok=True)
    write_json(pack / "evidence_manifest.json", {"files": _evidence_files(), "network_called": False})
    for source, name in [
        (output / "demo_e2e_result.json", "demo_e2e_result.json"),
        (output / "portfolio_demo_report.md", "portfolio_demo_report.md"),
        (output / "runtime_limitations.md", "runtime_limitations.md"),
        (output / "quality_gate_result.json", "quality_gate_result.json"),
        (output / "provider_security" / "provider_security_audit.json", "provider_security_audit.json"),
        (output / "llm_quality_gate_assist" / "llm_quality_gate_assist_result.json", "llm_quality_gate_assist_result.json"),
        (output / "release_readiness" / "release_readiness_result.json", "release_readiness_result.json"),
    ]:
        if source.exists():
            shutil.copy2(source, pack / name)


def _evidence_files() -> list[str]:
    return [
        "demo_e2e_result.json",
        "portfolio_demo_report.md",
        "runtime_limitations.md",
        "quality_gate_result.json",
        "provider_security_audit.json",
        "llm_quality_gate_assist_result.json",
        "release_readiness_result.json",
    ]


def _render_portfolio_report(result: dict) -> str:
    stage_rows = "\n".join(f"| {item['name']} | {item['status']} |" for item in result["stages"])
    return f"""# HeiTang KB Forge Portfolio Demo Report

## Summary

- Status: {result['status']}
- Offline: {result['offline']}
- Mock provider: {result['mock_provider']}
- Network called: {result['network_called']}
- Real platform runtime executed: {result['real_platform_runtime_executed']}

## Workflow

| Stage | Status |
| --- | --- |
{stage_rows}

## Evidence

- `demo_e2e_result.json`
- `portfolio_demo_report.md`
- `demo_evidence_pack/`
- `runtime_limitations.md`

## Boundaries

This demo does not start a real MCP server, run OpenClaw/Codex runtime, publish to Xiaohongshu, or call live LLM providers.
"""


def _runtime_limitations() -> str:
    return """# Runtime Limitations

- No real platform runtime is executed.
- No MCP server is started.
- No Xiaohongshu note is published.
- No API key is required.
- No live provider call is made by default.
- Runtime compatibility remains reserved for later versions.
- Domain Skill factory is not implemented in v2.7.
"""


def _stage(name: str, status: str, output_files: list[str]) -> dict:
    return {"name": name, "status": status, "output_files": [item.replace("\\", "/") for item in output_files]}


def _final_status(stages: list[dict]) -> str:
    if any(item["status"] == "fail" for item in stages):
        return "fail"
    if any(item["status"] == "warning" for item in stages):
        return "warning"
    return "pass"


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()
