from pathlib import Path
from typing import Any

from pydantic import ValidationError

from heitang_kb_forge.schemas.config_schema import ForgeConfig


def load_config(path: Path) -> ForgeConfig:
    if path.suffix.lower() not in {".yaml", ".yml"}:
        raise ValueError("Config file must use .yaml or .yml")
    if not path.exists():
        raise FileNotFoundError(f"Config file not found: {path}")

    text = path.read_text(encoding="utf-8")
    try:
        payload: Any = _safe_load_yaml(text)
    except Exception as exc:
        raise ValueError(f"YAML parse failed for {path}: {exc}") from exc

    if not isinstance(payload, dict):
        raise ValueError("Config top level must be a mapping/object")

    try:
        config = ForgeConfig.model_validate(payload)
    except ValidationError as exc:
        raise ValueError(_validation_message(exc)) from exc

    if config.task not in {"build", "batch"}:
        raise ValueError(f"Unsupported config task: {config.task}")
    return config


def _validation_message(exc: ValidationError) -> str:
    missing = []
    for error in exc.errors():
        if error.get("type") == "missing":
            missing.append(".".join(str(item) for item in error["loc"]))
    if missing:
        return f"Missing required config field: {', '.join(missing)}"
    return f"Invalid config: {exc.errors()[0]['msg']}"


def _safe_load_yaml(text: str) -> Any:
    try:
        import yaml

        return yaml.safe_load(text)
    except ModuleNotFoundError:
        return _load_simple_yaml(text)


def _load_simple_yaml(text: str) -> Any:
    root: dict[str, Any] = {}
    current_section: dict[str, Any] | None = None
    for raw_line in text.splitlines():
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue
        if raw_line.startswith("- "):
            return [raw_line[2:].strip()]
        if raw_line.startswith(" "):
            if current_section is None:
                raise ValueError("nested field without section")
            key, value = _split_yaml_pair(raw_line.strip())
            current_section[key] = _parse_scalar(value)
            continue
        key, value = _split_yaml_pair(raw_line.strip())
        if value == "":
            current_section = {}
            root[key] = current_section
        else:
            root[key] = _parse_scalar(value)
            current_section = None
    return root


def _split_yaml_pair(line: str) -> tuple[str, str]:
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
