"""Build and run auditable validation plans from the gate manifest."""

from __future__ import annotations

import argparse
import fnmatch
import json
import subprocess
from pathlib import Path
from typing import Any


DEFAULT_MANIFEST_PATH = Path(__file__).resolve().parents[2] / "docs" / "testing" / "VALIDATION_GATE_MANIFEST.json"
VALID_PHASES = {"development", "phase_closure", "release"}
VALID_GATE_LEVELS = {"fast", "medium", "chunked_full"}
FAILURE_PATTERNS = ("FAILED", "ERROR", "Traceback", "AssertionError", "Exception")


def load_manifest(path: Path | str = DEFAULT_MANIFEST_PATH) -> dict[str, Any]:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def _gate_names(manifest: dict[str, Any]) -> set[str]:
    return {gate.get("name", "") for gate in manifest.get("gates", [])}


def validate_manifest(manifest: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    gate_names = _gate_names(manifest)
    log_root = manifest.get("log_root", "")

    for required in [
        "schema_version",
        "release_version",
        "gates",
        "impact_rules",
        "release_gate_sequence",
        "default_gates",
        "reporting_policy",
        "obsolete_test_pruning",
        "post_codex_review_gate",
    ]:
        if required not in manifest:
            errors.append(f"missing top-level field: {required}")

    if len(gate_names) != len(manifest.get("gates", [])):
        errors.append("gate names must be unique")

    for gate in manifest.get("gates", []):
        name = gate.get("name", "<unnamed>")
        for required in [
            "level",
            "repository",
            "command",
            "log_path",
            "exit_code_required",
            "release_blocking",
            "impacted_surfaces",
        ]:
            if required not in gate:
                errors.append(f"{name}: missing {required}")
        if gate.get("level") not in VALID_GATE_LEVELS:
            errors.append(f"{name}: unsupported level {gate.get('level')}")
        if gate.get("log_path") and log_root and not str(gate["log_path"]).startswith(log_root):
            errors.append(f"{name}: log_path must live under {log_root}")
        if gate.get("level") == "chunked_full" and not gate.get("exit_code_required"):
            errors.append(f"{name}: chunked full gates must require exit codes")
        if gate.get("level") == "chunked_full" and not gate.get("release_blocking"):
            errors.append(f"{name}: chunked full gates must be release-blocking")

    for phase, default_gates in manifest.get("default_gates", {}).items():
        if phase not in {"development", "phase_closure"}:
            errors.append(f"default_gates contains unsupported phase: {phase}")
        for gate_name in default_gates:
            if gate_name not in gate_names:
                errors.append(f"default_gates.{phase} references unknown gate: {gate_name}")

    for rule in manifest.get("impact_rules", []):
        name = rule.get("name", "<unnamed>")
        if not rule.get("patterns"):
            errors.append(f"{name}: impact rule must include patterns")
        for field in ["fast_gates", "medium_gates"]:
            for gate_name in rule.get(field, []):
                if gate_name not in gate_names:
                    errors.append(f"{name}: unknown gate {gate_name} in {field}")

    release_gates = set(manifest.get("release_gate_sequence", []))
    for gate_name in release_gates:
        if gate_name not in gate_names:
            errors.append(f"release_gate_sequence references unknown gate: {gate_name}")
            continue
        gate = next(gate for gate in manifest["gates"] if gate["name"] == gate_name)
        if gate.get("level") != "chunked_full":
            errors.append(f"{gate_name}: release gate must be chunked_full")
        if gate.get("release_blocking") is not True:
            errors.append(f"{gate_name}: release gate must be release-blocking")
        if gate.get("exit_code_required") is not True:
            errors.append(f"{gate_name}: release gate must require exit code")

    policy = manifest.get("reporting_policy", {})
    if policy.get("never_report_skipped_or_deferred_as_passed") is not True:
        errors.append("reporting_policy must forbid skipped/deferred as passed")
    if "passed" in policy.get("allowed_non_pass_status", []):
        errors.append("passed cannot be listed as a non-pass status")
    for required in ["command", "exit_code", "status", "log_path", "summary"]:
        if required not in policy.get("required_command_fields", []):
            errors.append(f"reporting_policy missing required command field: {required}")

    review_gate = manifest.get("post_codex_review_gate", {})
    if review_gate.get("required") is not True:
        errors.append("post_codex_review_gate must be required")
    for level in ["light", "medium", "full"]:
        if level not in review_gate.get("levels", {}):
            errors.append(f"post_codex_review_gate missing level: {level}")
    for required in ["id", "severity", "surface", "file/path", "evidence", "impact", "recommended_fix", "blocks_release"]:
        if required not in review_gate.get("issue_schema", []):
            errors.append(f"post_codex_review_gate issue_schema missing: {required}")
    full_review = review_gate.get("levels", {}).get("full", {})
    if "before_tag_or_release" != full_review.get("when"):
        errors.append("post_codex_review_gate.full must run before tag/release")

    return errors


def select_impact_rules(changed_files: list[str], manifest: dict[str, Any] | None = None) -> list[dict[str, Any]]:
    manifest = manifest or load_manifest()
    normalized = [path.replace("\\", "/") for path in changed_files]
    matched: list[dict[str, Any]] = []
    for rule in manifest.get("impact_rules", []):
        patterns = rule.get("patterns", [])
        if any(fnmatch.fnmatch(path, pattern) for path in normalized for pattern in patterns):
            matched.append(rule)
    return matched


def build_validation_plan(
    changed_files: list[str],
    phase: str = "development",
    manifest: dict[str, Any] | None = None,
) -> dict[str, Any]:
    if phase not in VALID_PHASES:
        raise ValueError(f"phase must be one of {sorted(VALID_PHASES)}")

    manifest = manifest or load_manifest()
    errors = validate_manifest(manifest)
    if errors:
        raise ValueError("invalid validation manifest: " + "; ".join(errors))

    gates_by_name = {gate["name"]: gate for gate in manifest["gates"]}
    matched_rules = select_impact_rules(changed_files, manifest)
    selected_names: list[str] = []

    if phase == "release":
        selected_names.extend(manifest["release_gate_sequence"])
    else:
        field = "fast_gates" if phase == "development" else "medium_gates"
        for rule in matched_rules:
            selected_names.extend(rule.get(field, []))
        if not selected_names:
            selected_names.extend(manifest["default_gates"][phase])

    deduped_names = list(dict.fromkeys(selected_names))
    return {
        "manifest_version": manifest["release_version"],
        "phase": phase,
        "changed_files": changed_files,
        "matched_rules": [rule["name"] for rule in matched_rules],
        "impacted_surfaces": sorted({surface for rule in matched_rules for surface in rule.get("impacted_surfaces", [])}),
        "selected_gates": [gates_by_name[name] for name in deduped_names],
        "release_blocking": phase == "release",
    }


def summarize_log(log_path: Path, max_lines: int = 20) -> str:
    if not log_path.exists():
        return "log missing"
    lines = log_path.read_text(encoding="utf-8", errors="replace").splitlines()
    failure_lines = [line for line in lines if any(pattern in line for pattern in FAILURE_PATTERNS)]
    selected = failure_lines[:max_lines] if failure_lines else [line for line in lines if line.strip()][-max_lines:]
    return "\n".join(selected) if selected else "log empty"


def _strip_log_trailing_whitespace(log_path: Path) -> None:
    content = log_path.read_text(encoding="utf-8", errors="replace")
    normalized = "\n".join(line.rstrip(" \t") for line in content.splitlines())
    if content.endswith(("\n", "\r")):
        normalized += "\n"
    log_path.write_text(normalized, encoding="utf-8")


def build_gate_command(gate: dict[str, Any], working_directory: Path) -> str:
    patterns = gate.get("test_file_patterns", [])
    if not patterns:
        return gate["command"]

    matched: set[str] = set()
    for pattern in patterns:
        for path in working_directory.glob(pattern):
            if path.is_file():
                matched.add(str(path.relative_to(working_directory)).replace("\\", "/"))

    if not matched:
        raise ValueError(f"{gate['name']}: test_file_patterns matched no files")
    return " ".join([gate["command"], *sorted(matched)])


def run_validation_plan(plan: dict[str, Any], repo_root: Path) -> dict[str, Any]:
    results = []
    for gate in plan["selected_gates"]:
        log_path = repo_root / gate["log_path"]
        log_path.parent.mkdir(parents=True, exist_ok=True)
        working_directory = repo_root / gate.get("working_directory", ".")
        command = build_gate_command(gate, working_directory)
        with log_path.open("w", encoding="utf-8", errors="replace") as log_file:
            completed = subprocess.run(
                command,
                cwd=working_directory,
                shell=True,
                text=True,
                stdout=log_file,
                stderr=subprocess.STDOUT,
            )
        _strip_log_trailing_whitespace(log_path)
        exit_code_path = log_path.with_name(f"{log_path.name}.exitcode")
        result_path = log_path.with_name(f"{log_path.name}.result.json")
        exit_code_path.write_text(f"{completed.returncode}\n", encoding="utf-8")
        result = {
            "name": gate["name"],
            "command": command,
            "exit_code": completed.returncode,
            "exit_code_path": str(exit_code_path.relative_to(repo_root)).replace("\\", "/"),
            "status": "passed" if completed.returncode == 0 else "failed",
            "log_path": gate["log_path"],
            "summary": summarize_log(log_path),
        }
        result_path.write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")
        results.append(result)
    return {**plan, "results": results}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Build or execute a validation gate plan.")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST_PATH)
    parser.add_argument("--phase", choices=sorted(VALID_PHASES), default="development")
    parser.add_argument("--changed-file", action="append", default=[])
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--execute", action="store_true")
    args = parser.parse_args(argv)

    manifest = load_manifest(args.manifest)
    plan = build_validation_plan(args.changed_file, phase=args.phase, manifest=manifest)
    output = run_validation_plan(plan, args.repo_root) if args.execute else plan
    print(json.dumps(output, indent=2, ensure_ascii=False))
    if args.execute and any(result["status"] != "passed" for result in output.get("results", [])):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
