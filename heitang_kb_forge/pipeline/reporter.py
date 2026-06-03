from pathlib import Path

from heitang_kb_forge.agent.templates import AGENT_OUTPUT_FILES
from heitang_kb_forge.eval.demo import DEMO_OUTPUT_FILES
from heitang_kb_forge.llm.extractor import OUTPUT_FILES
from heitang_kb_forge.llm.quality import LLM_QUALITY_OUTPUT_FILES
from heitang_kb_forge.rag.exporter import RAG_OUTPUT_FILES
from heitang_kb_forge.schemas.config_schema import ForgeConfig
from heitang_kb_forge.schemas.pipeline_schema import PipelineManifest, PipelineStage

PIPELINE_OUTPUT_FILES = ["pipeline_report.md", "pipeline_manifest.json"]
STANDARD_PACKAGE_FILES = [
    "chunks.jsonl",
    "cards.jsonl",
    "qa_pairs.jsonl",
    "glossary.jsonl",
    "manifest.json",
    "ingest_report.md",
    "quality_report.json",
]


def make_pipeline_report(*, config_file: Path, config: ForgeConfig, output: Path) -> tuple[PipelineManifest, str]:
    stages = [
        _stage("source_ingestion", True, output, ["chunks.jsonl"], config.task),
        _stage("knowledge_package", True, output, STANDARD_PACKAGE_FILES, config.task),
        _stage("quality_report", True, output, ["quality_report.json"], config.task),
        _stage("llm_extraction", config.llm.enabled, output, _llm_output_files(config), config.task),
        _stage("rag_export", config.rag.enabled, output, RAG_OUTPUT_FILES, config.task),
        _stage("agent_template", config.agent.enabled, output, AGENT_OUTPUT_FILES, config.task),
        _stage("demo_report", config.demo.enabled, output, DEMO_OUTPUT_FILES, config.task),
    ]
    warnings = [f"Stage failed: {stage.name}" for stage in stages if stage.status == "failed"]
    final_status = "fail" if warnings else "pass"
    manifest = PipelineManifest(
        config_file=str(config_file).replace("\\", "/"),
        task=config.task,
        input=str(config.input).replace("\\", "/"),
        output=str(output).replace("\\", "/"),
        domain=config.domain,
        mode=config.mode,
        stages=stages,
        final_status=final_status,
        warnings=warnings,
    )
    return manifest, _render_report(manifest)


def _stage(name: str, enabled: bool, output: Path, expected_files: list[str], task: str) -> PipelineStage:
    if not enabled:
        return PipelineStage(name=name, enabled=False, status="skipped", output_files=[])
    status = "success" if _files_exist(output, expected_files, task) else "failed"
    return PipelineStage(name=name, enabled=True, status=status, output_files=expected_files)


def _llm_output_files(config: ForgeConfig) -> list[str]:
    files = list(OUTPUT_FILES.values())
    if config.llm.quality_report:
        files.extend(LLM_QUALITY_OUTPUT_FILES)
    return files


def _files_exist(output: Path, expected_files: list[str], task: str) -> bool:
    if task == "build":
        return all((output / name).exists() for name in expected_files)
    manifest_path = output / "batch_manifest.json"
    if not manifest_path.exists():
        return False
    if expected_files == ["chunks.jsonl"]:
        return True
    return True


def _render_report(manifest: PipelineManifest) -> str:
    enabled_stages = "\n".join(
        f"- {stage.name}: {stage.status}" for stage in manifest.stages if stage.enabled
    ) or "- None"
    output_files = "\n".join(
        f"- {file_name}"
        for stage in manifest.stages
        for file_name in stage.output_files
    ) or "- None"
    stage_rows = "\n".join(
        f"| {stage.name} | {stage.enabled} | {stage.status} | {', '.join(stage.output_files) or '-'} |"
        for stage in manifest.stages
    )
    warnings = "\n".join(f"- {warning}" for warning in manifest.warnings) or "- None"
    return f"""# HeiTang KB Forge Pipeline Report

## Pipeline Summary

- Task: {manifest.task}
- Input: {manifest.input}
- Output: {manifest.output}
- Domain: {manifest.domain}
- Mode: {manifest.mode}

## Enabled Stages

{enabled_stages}

## Output Files

{output_files}

## Stage Status

| Stage | Enabled | Status | Output Files |
| --- | --- | --- | --- |
{stage_rows}

## Final Result

- Status: {manifest.final_status}
- Warnings:
{warnings}

## Next Steps

- Inspect demo_report.md
- Inspect quality_report.json
- Inspect rag_manifest.json
- Inspect agent_profile.yaml
"""
