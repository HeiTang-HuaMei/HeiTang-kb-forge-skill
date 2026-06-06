from __future__ import annotations

import json
from pathlib import Path

from heitang_kb_forge.parser_backends.base import LEGACY_TRUST_STATUS, TRUSTED_STATUSES, TRUST_STATUSES, UNTRUSTED_STATUSES


def read_kb_trust_status(package: Path) -> str:
    status_file = package / "kb_trust_status.json"
    if status_file.exists():
        try:
            payload = json.loads(status_file.read_text(encoding="utf-8"))
            return str(payload.get("kb_trust_status") or LEGACY_TRUST_STATUS)
        except json.JSONDecodeError:
            return "raw_parse_output"
    manifest = package / "manifest.json"
    if manifest.exists():
        try:
            payload = json.loads(manifest.read_text(encoding="utf-8"))
            return str(payload.get("kb_trust_status") or LEGACY_TRUST_STATUS)
        except json.JSONDecodeError:
            return "raw_parse_output"
    return LEGACY_TRUST_STATUS


def read_skill_trust_status(skill: Path) -> str:
    manifest = skill / "skill_manifest.yaml"
    if not manifest.exists():
        return LEGACY_TRUST_STATUS
    for line in manifest.read_text(encoding="utf-8", errors="ignore").splitlines():
        if line.startswith("kb_trust_status:"):
            return line.split(":", 1)[1].strip()
    return LEGACY_TRUST_STATUS


def trust_gate_result(status: str, allow_untrusted: bool = False) -> dict:
    known_status = status in TRUST_STATUSES or status == LEGACY_TRUST_STATUS
    blocked = (status in UNTRUSTED_STATUSES or not known_status) and not allow_untrusted
    return {
        "trusted_kb_gate_version": "2.8.0-alpha.1",
        "status": "fail" if blocked else "pass",
        "kb_trust_status": status,
        "allow_untrusted": allow_untrusted,
        "trusted": status in TRUSTED_STATUSES,
        "blocked": blocked,
        "warnings": [] if not blocked else [_trust_gate_warning(status, known_status)],
    }


def _trust_gate_warning(status: str, known_status: bool) -> str:
    if not known_status:
        return f"unknown_kb_trust_status:{status}"
    return "untrusted_kb_requires_explicit_allow_untrusted"


def assert_trusted_for_export(path: Path, allow_untrusted: bool = False, from_skill: bool = False) -> dict:
    status = read_skill_trust_status(path) if from_skill else read_kb_trust_status(path)
    result = trust_gate_result(status, allow_untrusted)
    if result["blocked"]:
        raise ValueError(
            f"Untrusted KB cannot be exported or bound without --allow-untrusted: {status}. "
            "Review parser output or re-import corrected text first."
        )
    return result
