"""Compatibility entrypoint for the HeiTang KB Forge CLI.

Command implementations are registered by `heitang_kb_forge.cli_runtime`.
The runtime module is re-exported here to preserve `python -m heitang_kb_forge.cli`,
the console script entrypoint, and existing internal test imports.
"""

from heitang_kb_forge import cli_runtime as _runtime
from heitang_kb_forge.cli_runtime import *  # noqa: F401,F403
from heitang_kb_forge.cli_runtime import V21Options, _build_package, app

PARSERS = _runtime.PARSERS


if __name__ == "__main__":
    app()
