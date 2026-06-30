import runpy
import sys
import time
from pathlib import Path
from heitang_kb_forge import cli_runtime

orig = cli_runtime.clean_text

def slow_clean(text):
    time.sleep(2)
    return orig(text)

cli_runtime.clean_text = slow_clean
sys.argv = [
    'heitang-kb-forge', 'build',
    '--input', sys.argv[1],
    '--output', sys.argv[2],
    '--rag-export', '--retrieval-index', '--evidence-gate', '--run-manifest', '--progress-jsonl', '--contract-version', 'v2'
]
runpy.run_module('heitang_kb_forge.cli', run_name='__main__')
