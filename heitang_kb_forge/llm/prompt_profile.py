import hashlib
import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.schemas.prompt_profile_schema import PromptProfile


def load_prompt_profile(path: Path) -> tuple[PromptProfile, str]:
    if not path.exists():
        raise FileNotFoundError(f"Prompt profile not found: {path}")
    if path.suffix.lower() not in {".yaml", ".yml"}:
        raise ValueError("Prompt profile must use .yaml or .yml")

    try:
        payload = _load_yaml(path.read_text(encoding="utf-8"))
    except Exception as exc:
        raise ValueError(f"Failed to parse prompt profile: {path}") from exc

    if not isinstance(payload, dict):
        raise ValueError("Prompt profile must contain a mapping/object")
    if not payload.get("profile_name"):
        raise ValueError("Prompt profile field 'profile_name' is required")
    if "preferred_outputs" in payload and not isinstance(payload["preferred_outputs"], dict):
        raise ValueError("Prompt profile field 'preferred_outputs' must be a mapping/object")
    if "extraction_rules" in payload and not isinstance(payload["extraction_rules"], list):
        raise ValueError("Prompt profile field 'extraction_rules' must be a list")

    profile = PromptProfile.model_validate(payload)
    return profile, prompt_profile_hash(profile)


def prompt_profile_hash(profile: PromptProfile) -> str:
    payload = profile.model_dump(mode="json")
    canonical = json.dumps(payload, ensure_ascii=False, sort_keys=True)
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def render_prompt_profile_context(profile: PromptProfile | None) -> str:
    if profile is None:
        return ""
    focus = ", ".join(profile.focus) if profile.focus else "None"
    rules = "\n".join(f"- {rule}" for rule in profile.extraction_rules) or "- None"
    return f"""Prompt profile:
- profile_name: {profile.profile_name}
- language: {profile.language or 'None'}
- focus: {focus}
- extraction_rules:
{rules}
"""


def _load_yaml(text: str) -> Any:
    try:
        import yaml

        return yaml.safe_load(text)
    except ModuleNotFoundError:
        return _load_simple_yaml(text)


def _load_simple_yaml(text: str) -> dict[str, Any]:
    root: dict[str, Any] = {}
    current_key: str | None = None
    current_mapping: dict[str, Any] | None = None
    for raw_line in text.splitlines():
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue
        if raw_line.startswith("- "):
            raise ValueError("top-level lists are not supported")
        if raw_line.startswith("  - "):
            if current_key is not None and current_mapping is not None:
                root[current_key] = [raw_line.strip()[2:].strip()]
                current_mapping = None
                continue
            if current_key is None or not isinstance(root.get(current_key), list):
                raise ValueError("list item without list field")
            root[current_key].append(raw_line.strip()[2:].strip())
            continue
        if raw_line.startswith("  "):
            if current_key is not None and isinstance(root.get(current_key), list):
                key, value = _split_pair(raw_line.strip())
                root[current_key] = {key: _parse_scalar(value)}
                continue
            if current_mapping is None:
                raise ValueError("nested field without mapping")
            key, value = _split_pair(raw_line.strip())
            current_mapping[key] = _parse_scalar(value)
            continue

        key, value = _split_pair(raw_line.strip())
        if value == "":
            if key in {"focus", "extraction_rules"}:
                root[key] = []
                current_key = key
                current_mapping = None
            else:
                current_mapping = {}
                root[key] = current_mapping
                current_key = key
        else:
            root[key] = _parse_scalar(value)
            current_key = None
            current_mapping = None
    return root


def _split_pair(line: str) -> tuple[str, str]:
    if ":" not in line:
        raise ValueError(f"invalid mapping line: {line}")
    key, value = line.split(":", 1)
    if value.strip() in {"[", "{", "]", "}"}:
        raise ValueError(f"unsupported YAML syntax: {line}")
    return key.strip(), value.strip()


def _parse_scalar(value: str) -> Any:
    if value.lower() == "true":
        return True
    if value.lower() == "false":
        return False
    if value.lower() in {"null", "none", "~"}:
        return None
    return value.strip('"').strip("'")
