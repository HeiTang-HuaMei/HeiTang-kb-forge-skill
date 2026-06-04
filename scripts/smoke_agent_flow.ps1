$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$Out = Join-Path $Root "tmp_agent_flow"

Set-Location $Root

python -m heitang_kb_forge.cli build --input ".\examples\quickstart\input" --output "$Out\package" --domain demo --mode agent_flow --rag-export --agent-template
python -m heitang_kb_forge.cli retrieve --package "$Out\package" --query "Agent Tool MCP readiness" --output "$Out\retrieve"
python -m heitang_kb_forge.cli ask --package "$Out\package" --query "Summarize Agent integration." --output "$Out\ask" --citation-required
python -m heitang_kb_forge.cli tools export --output "$Out\tools"
python -m heitang_kb_forge.cli tools list
python -m heitang_kb_forge.cli tools describe --name retrieve_knowledge
python -m heitang_kb_forge.cli mcp export-config --output "$Out\mcp"
