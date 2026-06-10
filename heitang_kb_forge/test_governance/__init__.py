"""Helpers for v4.1.1 validation gate governance."""

from __future__ import annotations

from typing import Any


def __getattr__(name: str) -> Any:
    if name in {
        "build_validation_plan",
        "load_manifest",
        "run_validation_plan",
        "select_impact_rules",
        "summarize_log",
        "validate_manifest",
    }:
        from . import gates

        return getattr(gates, name)
    raise AttributeError(name)


__all__ = [
    "build_validation_plan",
    "load_manifest",
    "run_validation_plan",
    "select_impact_rules",
    "summarize_log",
    "validate_manifest",
]
