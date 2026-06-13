from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from hashlib import sha256
from pathlib import Path
from typing import Any

from heitang_kb_forge.contracts.checker import check_package_contract
from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.progress.reporter import ProgressReporter, make_progress_reporter
from heitang_kb_forge.validation.package_validator import validate_package


def run_document_understanding(
    input_path: Path,
    preflight_path: Path,
    output: Path,
    *,
    runtime_config_path: Path | None = None,
    progress: bool = False,
    progress_jsonl: bool = True,
    progress_log: Path | None = None,
    continue_on_error: bool = True,
    resume: bool = False,
) -> dict[str, Any]:
    if output.exists() and any(output.iterdir()) and not resume:
        raise FileExistsError(f"Document Understanding output already exists: {output}")
    output.mkdir(parents=True, exist_ok=True)
    reporter = make_progress_reporter(
        progress=progress,
        progress_jsonl=progress_jsonl,
        progress_log=progress_log,
    )
    if reporter:
        reporter.configure_default_log(output)

    preflight_dir = preflight_path if preflight_path.is_dir() else preflight_path.parent
    recommendation_path = (
        preflight_path
        if preflight_path.is_file()
        else preflight_path / "backend_recommendation.json"
    )
    inventory_path = preflight_dir / "document_inventory.json"
    recommendations = _read_json(recommendation_path)["recommendations"]
    inventory_rows = {
        row["relative_path"]: row
        for row in _read_json(inventory_path).get("files", [])
    }
    runtime_config = _load_runtime_config(runtime_config_path)
    routes = runtime_config.get("routes", {})
    total = len(recommendations)
    if reporter:
        reporter.emit(
            "document_understanding_started",
            "started",
            f"Document Understanding started with {total} preflight items",
            total_files=total,
            output_path=str(output),
        )

    normalized_dir = output / "normalized_sources"
    run_root = output / "backend_runs"
    normalized_dir.mkdir(parents=True, exist_ok=True)
    run_root.mkdir(parents=True, exist_ok=True)
    items: list[dict[str, Any]] = []
    normalized_records: list[dict[str, Any]] = []

    for index, recommendation in enumerate(recommendations, start=1):
        relative_path = str(recommendation["relative_path"])
        inventory = inventory_rows.get(relative_path, {})
        item_id = f"doc-{index:04d}"
        source = _resolve_source(input_path, relative_path)
        selected_backend = recommendation.get("selected_backend")
        backend = routes.get(relative_path) or routes.get(source.suffix.lower()) or selected_backend
        route_source = "runtime_config_override" if backend != selected_backend else "preflight_recommendation"
        item_output = run_root / item_id
        item = {
            "item_id": item_id,
            "relative_path": relative_path,
            "source_path": _safe_path(source),
            "preflight_backend": selected_backend,
            "executed_backend": backend,
            "route_source": route_source,
            "status": "pending",
            "runtime_invoked": False,
            "normalized_path": None,
            "parser_result_path": None,
            "error": None,
        }
        if inventory.get("status") in {"duplicate", "unsupported", "failed"}:
            item["status"] = "skipped"
            item["error"] = inventory.get("error") or inventory.get("status")
            items.append(item)
            if reporter:
                reporter.emit(
                    "document_understanding_item",
                    "skipped",
                    f"Skipped {relative_path}: {item['error']}",
                    current_file=_safe_path(source),
                    current_file_index=index,
                    total_files=total,
                    warning=str(item["error"]),
                )
            continue
        if not backend:
            item["status"] = "failed"
            item["error"] = "backend_route_missing"
            items.append(item)
            if not continue_on_error:
                break
            continue

        if reporter:
            reporter.emit(
                "document_understanding_item",
                "running",
                f"Running {backend} for {relative_path}",
                current_file=_safe_path(source),
                current_file_index=index,
                total_files=total,
                output_path=str(item_output),
                metadata={"backend": backend},
            )
        try:
            payload, runtime_invoked = _run_backend(
                source,
                backend,
                item_output,
                runtime_config,
                resume=resume,
            )
            records = payload.get("records", [])
            successful = [record for record in records if record.get("status") == "success" and str(record.get("text", "")).strip()]
            if payload.get("status") != "success" or not successful:
                raise RuntimeError(
                    f"backend_status={payload.get('status')}; "
                    f"record_statuses={[record.get('status') for record in records]}"
                )
            record = successful[0]
            normalized_path = normalized_dir / f"{index:04d}_{_safe_name(source.stem)}.md"
            normalized_path.write_text(str(record["text"]).strip() + "\n", encoding="utf-8")
            normalized_record = {
                "item_id": item_id,
                "source_path": _safe_path(source),
                "relative_path": relative_path,
                "normalized_path": _safe_path(normalized_path),
                "backend": backend,
                "backend_version": payload.get("backend_version"),
                "confidence": record.get("confidence"),
                "text_length": len(str(record["text"])),
                "warnings": record.get("warnings", []),
                "metadata": record.get("metadata", {}),
                "parser_result_path": _safe_path(item_output / "parser_backend_result.json"),
            }
            normalized_records.append(normalized_record)
            item.update(
                {
                    "status": "success",
                    "runtime_invoked": runtime_invoked,
                    "normalized_path": normalized_record["normalized_path"],
                    "parser_result_path": normalized_record["parser_result_path"],
                }
            )
            if reporter:
                reporter.emit(
                    "document_understanding_item",
                    "success",
                    f"Completed {backend} for {relative_path}",
                    current_file=_safe_path(source),
                    current_file_index=index,
                    total_files=total,
                    output_path=normalized_record["normalized_path"],
                    metadata={
                        "backend": backend,
                        "text_length": normalized_record["text_length"],
                    },
                )
        except Exception as exc:
            item["status"] = "failed"
            item["error"] = str(exc)
            if reporter:
                reporter.emit(
                    "document_understanding_item",
                    "failed",
                    f"Failed {backend} for {relative_path}",
                    current_file=_safe_path(source),
                    current_file_index=index,
                    total_files=total,
                    output_path=str(item_output),
                    error=str(exc),
                    metadata={"backend": backend},
                )
        items.append(item)
        if item["status"] == "failed" and not continue_on_error:
            break

    success_count = sum(item["status"] == "success" for item in items)
    failed_count = sum(item["status"] == "failed" for item in items)
    skipped_count = sum(item["status"] == "skipped" for item in items)
    status = (
        "completed"
        if success_count and failed_count == 0
        else "completed_with_issues"
        if success_count
        else "failed"
    )
    manifest = {
        "schema_version": "document_understanding_workflow.v1",
        "status": status,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "input_path": _safe_path(input_path),
        "preflight_path": _safe_path(preflight_dir),
        "runtime_config_path": _safe_path(runtime_config_path) if runtime_config_path else None,
        "total_items": len(items),
        "success_count": success_count,
        "failed_count": failed_count,
        "skipped_count": skipped_count,
        "normalized_source_count": len(normalized_records),
        "runtime_invoked_count": sum(bool(item["runtime_invoked"]) for item in items),
        "progress_events_path": _safe_path(reporter.log_path) if reporter and reporter.log_path else None,
        "items": items,
        "output_files": [
            "document_understanding_manifest.json",
            "document_understanding_report.md",
            "document_understanding_records.jsonl",
            "runtime_configuration_report.json",
            "normalized_sources/",
            "backend_runs/",
            "progress_events.jsonl",
        ],
    }
    write_json(output / "document_understanding_manifest.json", manifest)
    write_jsonl(output / "document_understanding_records.jsonl", normalized_records)
    write_json(
        output / "runtime_configuration_report.json",
        _runtime_configuration_report(runtime_config, runtime_config_path),
    )
    (output / "document_understanding_report.md").write_text(
        _render_document_understanding_report(manifest),
        encoding="utf-8",
    )
    if reporter:
        reporter.emit(
            "document_understanding_done",
            "success" if status == "completed" else "warning" if success_count else "failed",
            f"Document Understanding {status}: {success_count} succeeded, {failed_count} failed",
            total_files=len(items),
            output_path=str(output),
            metadata={
                "success_count": success_count,
                "failed_count": failed_count,
                "skipped_count": skipped_count,
            },
        )
    return manifest


def attach_document_understanding_lineage(
    knowledge_base: Path,
    document_understanding: Path,
    *,
    chunk_count: int,
    source_count: int,
) -> dict[str, Any]:
    du_manifest = _read_json(document_understanding / "document_understanding_manifest.json")
    records = _read_jsonl(document_understanding / "document_understanding_records.jsonl")
    lineage = {
        "schema_version": "knowledge_base.document_understanding_lineage.v1",
        "status": "pass" if du_manifest.get("status") == "completed" and records else "warning",
        "document_understanding_path": _safe_path(document_understanding),
        "document_understanding_status": du_manifest.get("status"),
        "normalized_source_count": len(records),
        "knowledge_base_source_count": source_count,
        "knowledge_base_chunk_count": chunk_count,
        "backend_counts": _count_by(records, "backend"),
        "runtime_invoked_count": du_manifest.get("runtime_invoked_count", 0),
        "records": records,
    }
    write_json(knowledge_base / "document_understanding_lineage.json", lineage)
    manifest_path = knowledge_base / "manifest.json"
    manifest = _read_json(manifest_path)
    files = list(manifest.get("files", []))
    for name in [
        "document_understanding_lineage.json",
        "knowledge_base_build_report.json",
        "knowledge_base_build_report.md",
    ]:
        if name not in files:
            files.append(name)
    manifest.update(
        {
            "files": files,
            "document_understanding_lineage_file": "document_understanding_lineage.json",
            "document_understanding_status": du_manifest.get("status"),
            "document_understanding_backend_counts": lineage["backend_counts"],
        }
    )
    write_json(manifest_path, manifest)
    return lineage


def build_knowledge_package(
    knowledge_base: Path,
    output: Path,
    *,
    progress: bool = False,
    progress_jsonl: bool = True,
    progress_log: Path | None = None,
) -> dict[str, Any]:
    if output.exists() and any(output.iterdir()):
        raise FileExistsError(f"Knowledge package output already exists: {output}")
    output.mkdir(parents=True, exist_ok=True)
    reporter = make_progress_reporter(
        progress=progress,
        progress_jsonl=progress_jsonl,
        progress_log=progress_log,
    )
    if reporter:
        reporter.configure_default_log(output)
        reporter.emit(
            "knowledge_package_started",
            "started",
            "Knowledge package build started",
            output_path=str(output),
        )

    source_contract = check_package_contract(knowledge_base)
    if source_contract.status == "fail":
        raise RuntimeError(
            "Knowledge base contract failed: "
            + "; ".join(source_contract.errors + source_contract.missing_required_files)
        )
    if reporter:
        reporter.emit(
            "validation",
            "success",
            f"Knowledge base contract: {source_contract.status}",
            output_path=str(knowledge_base),
        )

    copied_files = []
    for source in sorted(knowledge_base.rglob("*")):
        if not source.is_file() or source.name == "progress_events.jsonl":
            continue
        relative = source.relative_to(knowledge_base)
        target = output / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        copied_files.append(relative.as_posix())
    if reporter:
        reporter.emit(
            "write_outputs",
            "success",
            f"Copied {len(copied_files)} knowledge artifacts",
            output_path=str(output),
            metadata={"copied_file_count": len(copied_files)},
        )

    package_validation, readiness_md = validate_package(output)
    write_json(
        output / "package_validation_report.json",
        package_validation.model_dump(mode="json"),
    )
    (output / "package_readiness_report.md").write_text(readiness_md, encoding="utf-8")
    inventory = _artifact_inventory(output)
    write_json(output / "artifact_inventory.json", inventory)
    manifest_path = output / "manifest.json"
    manifest = _read_json(manifest_path)
    files = list(manifest.get("files", []))
    for name in [
        "artifact_inventory.json",
        "knowledge_package_build_report.json",
        "knowledge_package_build_report.md",
        "progress_events.jsonl",
    ]:
        if name not in files:
            files.append(name)
    manifest.update(
        {
            "files": files,
            "knowledge_package_status": "completed",
            "knowledge_package_artifact_inventory": "artifact_inventory.json",
        }
    )
    write_json(manifest_path, manifest)
    target_contract = check_package_contract(output)
    report = {
        "schema_version": "knowledge_package_build.v1",
        "status": "pass"
        if target_contract.status != "fail"
        and package_validation.standard_files_present
        and inventory["file_count"] > 0
        else "fail",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "knowledge_base_path": _safe_path(knowledge_base),
        "knowledge_package_path": _safe_path(output),
        "copied_file_count": len(copied_files),
        "artifact_file_count": inventory["file_count"],
        "artifact_total_bytes": inventory["total_bytes"],
        "source_contract_status": source_contract.status,
        "target_contract_status": target_contract.status,
        "package_readiness": package_validation.readiness_level,
        "standard_files_present": package_validation.standard_files_present,
        "progress_events_path": _safe_path(reporter.log_path) if reporter and reporter.log_path else None,
        "exe_packaging_proven": False,
    }
    write_json(output / "knowledge_package_build_report.json", report)
    (output / "knowledge_package_build_report.md").write_text(
        _render_knowledge_package_report(report),
        encoding="utf-8",
    )
    if reporter:
        reporter.emit(
            "knowledge_package_done",
            "success" if report["status"] == "pass" else "failed",
            f"Knowledge package build {report['status']}",
            output_path=str(output),
            metadata={
                "artifact_file_count": inventory["file_count"],
                "artifact_total_bytes": inventory["total_bytes"],
            },
        )
    return report


def _run_backend(
    source: Path,
    backend: str,
    output: Path,
    runtime_config: dict[str, Any],
    *,
    resume: bool,
) -> tuple[dict[str, Any], bool]:
    result_path = output / "parser_backend_result.json"
    if resume and result_path.exists():
        return _read_json(result_path), False

    backend_config = runtime_config.get("backends", {}).get(backend, {})
    python_path = Path(backend_config.get("python") or sys.executable).expanduser().resolve()
    if not python_path.is_file():
        raise FileNotFoundError(f"Backend Python not found for {backend}: {python_path}")
    output.mkdir(parents=True, exist_ok=True)
    command = [
        str(python_path),
        "-m",
        "heitang_kb_forge.cli",
        "parse-with-backend",
        "--input",
        str(source),
        "--output",
        str(output),
        "--backend",
        backend,
    ]
    model_cache = backend_config.get("model_cache")
    if model_cache and backend in {"marker", "surya"}:
        command.extend(["--model-cache", str(Path(model_cache).expanduser().resolve())])
    environment = os.environ.copy()
    environment["PYTHONUTF8"] = "1"
    environment.update(
        {str(key): str(value) for key, value in backend_config.get("environment", {}).items()}
    )
    if model_cache:
        environment["MODEL_CACHE_DIR"] = str(Path(model_cache).expanduser().resolve())
    timeout = int(backend_config.get("timeout_seconds", 900))
    working_directory = Path(
        backend_config.get("working_directory")
        or runtime_config.get("working_directory")
        or Path.cwd()
    ).expanduser().resolve()
    completed = subprocess.run(
        command,
        cwd=working_directory,
        env=environment,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=timeout,
    )
    (output / "backend_run.log").write_text(
        "\n".join(
            [
                f"command={' '.join(command)}",
                f"exit_code={completed.returncode}",
                "--- stdout ---",
                completed.stdout,
                "--- stderr ---",
                completed.stderr,
            ]
        ),
        encoding="utf-8",
    )
    if completed.returncode != 0:
        detail = (completed.stderr or completed.stdout or "backend_process_failed").strip()
        raise RuntimeError(f"{backend} exited {completed.returncode}: {detail[-800:]}")
    if not result_path.exists():
        raise FileNotFoundError(f"Backend result missing: {result_path}")
    return _read_json(result_path), True


def _load_runtime_config(path: Path | None) -> dict[str, Any]:
    if path is None:
        return {
            "schema_version": "document_understanding_runtime_config.v1",
            "working_directory": str(Path.cwd()),
            "routes": {},
            "backends": {},
        }
    payload = _read_json(path)
    if not isinstance(payload.get("backends", {}), dict):
        raise ValueError("runtime config backends must be an object")
    if not isinstance(payload.get("routes", {}), dict):
        raise ValueError("runtime config routes must be an object")
    return payload


def _runtime_configuration_report(
    config: dict[str, Any],
    config_path: Path | None,
) -> dict[str, Any]:
    return {
        "schema_version": "document_understanding.runtime_configuration_report.v1",
        "config_path": _safe_path(config_path) if config_path else None,
        "working_directory": config.get("working_directory"),
        "routes": config.get("routes", {}),
        "backends": {
            backend: {
                "python": values.get("python"),
                "model_cache": values.get("model_cache"),
                "timeout_seconds": values.get("timeout_seconds", 900),
                "environment_keys": sorted(values.get("environment", {})),
            }
            for backend, values in config.get("backends", {}).items()
        },
        "secrets_persisted": False,
    }


def _resolve_source(input_path: Path, relative_path: str) -> Path:
    if input_path.is_file():
        source = input_path.resolve()
    else:
        root = input_path.resolve()
        source = (root / relative_path).resolve()
        if not source.is_relative_to(root):
            raise ValueError(f"Preflight source escapes input root: {relative_path}")
    if not source.is_file():
        raise FileNotFoundError(f"Preflight source missing: {source}")
    return source


def _artifact_inventory(root: Path) -> dict[str, Any]:
    artifacts = []
    for path in sorted(root.rglob("*")):
        if not path.is_file() or path.name == "artifact_inventory.json":
            continue
        data = path.read_bytes()
        artifacts.append(
            {
                "path": path.relative_to(root).as_posix(),
                "size_bytes": len(data),
                "sha256": sha256(data).hexdigest(),
            }
        )
    return {
        "schema_version": "knowledge_package.artifact_inventory.v1",
        "file_count": len(artifacts),
        "total_bytes": sum(item["size_bytes"] for item in artifacts),
        "artifacts": artifacts,
    }


def _count_by(rows: list[dict[str, Any]], key: str) -> dict[str, int]:
    counts: dict[str, int] = {}
    for row in rows:
        value = str(row.get(key) or "unknown")
        counts[value] = counts.get(value, 0) + 1
    return counts


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8-sig").splitlines()
        if line.strip()
    ]


def _safe_name(value: str) -> str:
    normalized = re.sub(r"[^A-Za-z0-9._-]+", "_", value).strip("._")
    return normalized or "document"


def _safe_path(path: Path | None) -> str | None:
    return str(path).replace("\\", "/") if path is not None else None


def _render_document_understanding_report(report: dict[str, Any]) -> str:
    lines = [
        "# Document Understanding Report",
        "",
        f"- Status: `{report['status']}`",
        f"- Total items: `{report['total_items']}`",
        f"- Success: `{report['success_count']}`",
        f"- Failed: `{report['failed_count']}`",
        f"- Skipped: `{report['skipped_count']}`",
        f"- Runtime invoked: `{report['runtime_invoked_count']}`",
        f"- Normalized sources: `{report['normalized_source_count']}`",
        f"- Progress events: `{report.get('progress_events_path')}`",
        "",
        "| File | Preflight | Executed | Runtime | Status |",
        "| --- | --- | --- | --- | --- |",
    ]
    for item in report["items"]:
        lines.append(
            f"| {item['relative_path']} | {item.get('preflight_backend')} | "
            f"{item.get('executed_backend')} | {str(item['runtime_invoked']).lower()} | "
            f"{item['status']} |"
        )
    return "\n".join(lines).rstrip() + "\n"


def _render_knowledge_package_report(report: dict[str, Any]) -> str:
    return (
        "# Knowledge Package Build Report\n\n"
        f"- Status: `{report['status']}`\n"
        f"- Knowledge base: `{report['knowledge_base_path']}`\n"
        f"- Knowledge package: `{report['knowledge_package_path']}`\n"
        f"- Copied files: `{report['copied_file_count']}`\n"
        f"- Artifact files: `{report['artifact_file_count']}`\n"
        f"- Artifact bytes: `{report['artifact_total_bytes']}`\n"
        f"- Source contract: `{report['source_contract_status']}`\n"
        f"- Target contract: `{report['target_contract_status']}`\n"
        f"- Package readiness: `{report['package_readiness']}`\n"
        f"- Standard files present: `{str(report['standard_files_present']).lower()}`\n"
        f"- Progress events: `{report.get('progress_events_path')}`\n"
        f"- EXE packaging proven: `{str(report['exe_packaging_proven']).lower()}`\n"
    )
