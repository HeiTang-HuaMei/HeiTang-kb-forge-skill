$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$Out = Join-Path $Root "tmp_quickstart"

Set-Location $Root

python -m heitang_kb_forge.cli doctor --output "$Out\doctor"
python -m heitang_kb_forge.cli build --input ".\examples\quickstart\input" --output "$Out\package" --domain demo --mode quickstart --rag-export --agent-template --validate-package --quality-gate --run-manifest
python -m heitang_kb_forge.cli store init --db "$Out\kb_forge_workspace.db"
python -m heitang_kb_forge.cli store import-package --db "$Out\kb_forge_workspace.db" --package "$Out\package"
python -m heitang_kb_forge.cli retrieve --package "$Out\package" --query "这个知识包解决什么问题？" --output "$Out\retrieve"
python -m heitang_kb_forge.cli ask --package "$Out\package" --query "请总结这个知识包的核心能力。" --output "$Out\ask" --citation-required
python -m heitang_kb_forge.cli tools export --output "$Out\tools"
python -m heitang_kb_forge.cli mcp export-config --output "$Out\mcp"

Get-ChildItem -Path $Out -Recurse -File | Select-Object FullName
