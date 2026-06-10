"""Validation gate selection helpers for test governance."""

from importlib import import_module

__all__ = [
    "DEFAULT_MANIFEST_PATH",
    "build_validation_plan",
    "load_manifest",
    "select_impact_rules",
    "validate_manifest",
]


def __getattr__(name: str):
    if name in __all__:
        return getattr(import_module("heitang_kb_forge.test_governance.gates"), name)
    raise AttributeError(name)
