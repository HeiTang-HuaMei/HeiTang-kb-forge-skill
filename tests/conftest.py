from __future__ import annotations

from pathlib import Path

import pytest

from tests.legacy_public_reset_evidence import ensure_legacy_public_reset_evidence


def pytest_configure(config: pytest.Config) -> None:
    repo_root = Path(__file__).resolve().parents[1]
    ensure_legacy_public_reset_evidence(repo_root)


@pytest.fixture(scope="session", autouse=True)
def _v4_2_clean_main_legacy_evidence() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    ensure_legacy_public_reset_evidence(repo_root)
