param(
  [string]$ExePath = "",
  [string]$InputDir = "",
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($ExePath)) { $ExePath = Get-DefaultExePath }
if ([string]::IsNullOrWhiteSpace($InputDir)) { $InputDir = "D:\HeiTang-Codex-WorkSpace\input" }
if ([string]::IsNullOrWhiteSpace($OutputRoot)) { $OutputRoot = Get-DefaultIndustrialOutputRoot }

$outputDir = New-VerifierRunDir $OutputRoot "a2a_10_agents"
$workspace = Get-WorkspacePath
Clear-WorkbenchWorkspace
$launch = $null
try {
  $launch = Start-WorkbenchExeForMainChain $ExePath
  $mainReady = Wait-ForCondition { (Get-ArtifactChecks $workspace).a2a } 360
  $manifestPath = Join-Path $workspace "multi_agent\multi_agent_discussion_manifest.json"
  $taskMatrixPath = Join-Path $workspace "multi_agent\a2a_10_agent_task_matrix.json"
  $taskRecordsPath = Join-Path $workspace "multi_agent\a2a_agent_task_records.jsonl"
  $runHistoryPath = Join-Path $workspace "agent\audit\run_history.json"
  $manifest = Read-JsonFile $manifestPath
  $taskMatrix = Read-JsonFile $taskMatrixPath
  $taskRecords = Read-JsonlFile $taskRecordsPath
  $runHistory = Read-JsonFile $runHistoryPath
  $runRecords = if ($runHistory -and $runHistory.records) { @($runHistory.records) } else { @() }
  $participantCount = if ($manifest -and $manifest.participant_count) { [int]$manifest.participant_count } else { 0 }
  $completedCount = if ($taskMatrix -and $taskMatrix.completed_count) { [int]$taskMatrix.completed_count } else { 0 }
  $hasUsage = @($runRecords | Where-Object { $_.action -eq "run_a2a_discussion" }).Count -gt 0
  $results = @(
    [ordered]@{ check = "同一工作区 >=10 Agent"; result = if ($participantCount -ge 10) { "passed" } else { "failed" }; participant_count = $participantCount },
    [ordered]@{ check = "Agent 输入输出状态可追踪"; result = if ($taskRecords.Count -ge 10) { "passed" } else { "failed" }; task_record_count = $taskRecords.Count },
    [ordered]@{ check = "单 Agent 失败不拖垮协作"; result = if ($taskMatrix.single_agent_failure_isolated -eq $true) { "passed" } else { "failed" } },
    [ordered]@{ check = "协作结果真实落盘"; result = if (Test-Path -LiteralPath (Join-Path $workspace "multi_agent\multi_agent_discussion.md")) { "passed" } else { "failed" } },
    [ordered]@{ check = "使用记录记录协作"; result = if ($hasUsage) { "passed" } else { "failed" } },
    [ordered]@{ check = "工作区与记忆隔离"; result = if ($taskMatrix.workspace_isolated -eq $true -and $taskMatrix.memory_isolated -eq $true) { "passed" } else { "failed" } }
  )
  $failed = @($results | Where-Object { $_.result -eq "failed" })
  $payload = [ordered]@{
    status = if ($mainReady -and $failed.Count -eq 0) { "passed" } else { "blocked" }
    output_dir = $outputDir
    exe_path = $ExePath
    workspace = $workspace
    manifest_path = $manifestPath
    task_matrix_path = $taskMatrixPath
    task_records_path = $taskRecordsPath
    run_history_path = $runHistoryPath
    participant_count = $participantCount
    completed_count = $completedCount
    results = $results
  }
  Write-Json (Join-Path $outputDir "a2a_10_agents_results.json") $payload
  Write-Json (Join-Path $OutputRoot "a2a_10_agents\a2a_10_agents_results.json") $payload
  $payload | ConvertTo-Json -Depth 12
  if ($payload.status -ne "passed") { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
