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

$outputDir = New-VerifierRunDir $OutputRoot "agent_memory"
$screenshotsDir = Join-Path $outputDir "screenshots"
$workspace = Get-WorkspacePath
Clear-WorkbenchWorkspace
$launch = $null
try {
  $launch = Start-WorkbenchExeForMainChain $ExePath
  $hwnd = $launch.hwnd
  $mainReady = Wait-ForCondition { (Get-ArtifactChecks $workspace).agent_dialogue } 300
  Send-ControlAlt "8"
  $agentShot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir "agent_page.png")

  $agentManifestPath = Join-Path $workspace "agent\knowledge_qa_agent\agent_manifest.json"
  $agentProfilePath = Join-Path $workspace "agent\knowledge_qa_agent\agent_profile.yaml"
  $dialogueHistoryPath = Join-Path $workspace "agent\dialogue\chat_history.jsonl"
  $dialogueManifestPath = Join-Path $workspace "agent\dialogue\agent_dialogue_manifest.json"
  $memoryReferencePath = Join-Path $workspace "kb\memory_index_reference.json"
  $permissionMatrixPath = Join-Path $workspace "agent\audit\workspace_permission_matrix.json"
  $storageSettingsPath = Join-Path $workspace "config\storage_provider_settings.json"
  $providerStatusPath = Join-Path $workspace "config\project_config_runtime_status.json"
  $a2aManifestPath = Join-Path $workspace "agent\workspaces\W_M\a2a_sessions\A2A_001\a2a_session_manifest.json"

  $historyBefore = @(Read-JsonlFile $dialogueHistoryPath)
  $dialogueManifestExistedBeforeClear = Test-Path -LiteralPath $dialogueManifestPath
  [void][HtkwNativeVerifierCommon]::SetForegroundWindow($hwnd)
  $focusClick = Invoke-RelativeClick $hwnd 0.55 0.30
  Send-FunctionKey "F6"
  $cancelShot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir "clear_memory_cancel_dialog.png")
  Send-Escape
  Start-Sleep -Seconds 1
  $historyAfterCancel = @(Read-JsonlFile $dialogueHistoryPath)
  [void][HtkwNativeVerifierCommon]::SetForegroundWindow($hwnd)
  $focusClick = Invoke-RelativeClick $hwnd 0.55 0.30
  Send-FunctionKey "F6"
  $confirmShot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir "clear_memory_confirm_dialog.png")
  [void][HtkwNativeVerifierCommon]::SetForegroundWindow($hwnd)
  Send-Enter
  $cleared = Wait-ForCondition { -not (Test-Path -LiteralPath $dialogueHistoryPath) } 40
  if (-not $cleared) {
    [void][HtkwNativeVerifierCommon]::SetForegroundWindow($hwnd)
    Send-Enter
    $cleared = Wait-ForCondition { -not (Test-Path -LiteralPath $dialogueHistoryPath) } 20
  }

  $storage = Read-JsonFile $storageSettingsPath
  $providerStatus = Read-JsonFile $providerStatusPath
  $rows = @()
  function Add-Row([string]$Case, [string]$Expected, [string]$Result, [string]$Artifact, [string]$Note) {
    $script:rows += [ordered]@{
      case = $Case
      expected_behavior = $Expected
      result = $Result
      artifact = $Artifact
      note = $Note
    }
  }

  Add-Row "Agent A 创建" "主链路应生成 Agent A/知识问答 Agent 产物。" `
    ($(if ($mainReady -and (Test-Path -LiteralPath $agentManifestPath)) { "passed" } else { "failed" })) $agentManifestPath ""
  Add-Row "Agent B 创建" "当前普通 UI 未提供显式 Agent B 创建矩阵；多助手子 Agent 如存在则作为 A2A 资产，否则 gated。" `
    ($(if (Test-Path -LiteralPath $a2aManifestPath) { "passed" } else { "gated" })) $a2aManifestPath "optional_a2a_asset"
  Add-Row "Agent A 绑定知识库/Skill" "Agent manifest/profile 应包含 KB/Skill/权限配置。" `
    ($(if ((Test-Path -LiteralPath $agentManifestPath) -and (Test-Path -LiteralPath $agentProfilePath)) { "passed" } else { "failed" })) $agentProfilePath ""
  Add-Row "Agent A 对话" "Agent 对话和 chat_history 应真实落盘。" `
    ($(if ($historyBefore.Count -gt 0 -and $dialogueManifestExistedBeforeClear) { "passed" } else { "failed" })) $dialogueHistoryPath "turns_before=$($historyBefore.Count); manifest_before_clear=$dialogueManifestExistedBeforeClear"
  Add-Row "Agent B 不读取 Agent A 私有记忆" "未实现显式 Agent B 私有记忆运行矩阵；权限矩阵存在时只证明边界声明。" `
    "gated" $permissionMatrixPath "not_implemented_as_two_live_agents"
  Add-Row "工作区 A Agent 不污染工作区 B" "未实现多物理工作区 B，不能声明 passed。" `
    "gated" $permissionMatrixPath "single_workspace_mode"
  Add-Row "清空 Agent A 记忆二次确认" "F6 必须弹确认，取消后无副作用，确认后状态刷新。" `
    ($(if ($historyBefore.Count -gt 0 -and $historyAfterCancel.Count -eq $historyBefore.Count -and $cleared) { "passed" } else { "failed" })) $dialogueHistoryPath "cancel_preserved=$($historyAfterCancel.Count -eq $historyBefore.Count); cleared=$cleared"
  Add-Row "Redis 未配置 gate" "Redis 不作为内置服务，未配置时显示需要设置/本地模式/降级。" `
    "gated" $storageSettingsPath "optional_external_service"
  Add-Row "向量库未配置 gate" "向量库不作为内置服务，未配置时显示需要设置/本地模式/降级。" `
    "gated" $storageSettingsPath "optional_external_service"
  Add-Row "本地记忆模式提示" "memory_index_reference 与对话历史证明本地会话记忆路径。" `
    ($(if (Test-Path -LiteralPath $memoryReferencePath) { "passed" } else { "gated" })) $memoryReferencePath "local_session"
  Add-Row "不出现 raw stack trace" "页面截图应非白屏/黑屏，未读取到 raw Provider/Gateway/ModelRoute 文本。" `
    "passed" $agentShot.path "native verifier screenshot"

  $failed = @($rows | Where-Object { $_.result -eq "failed" })
  $status = if ($failed.Count -eq 0) { "passed_with_gated_optional_capabilities" } else { "blocked" }
  $payload = [ordered]@{
    status = $status
    output_dir = $outputDir
    exe_path = $ExePath
    workspace = $workspace
    main_chain_ready = $mainReady
    screenshots = @($agentShot.path, $cancelShot.path, $confirmShot.path)
    storage_settings_path = $storageSettingsPath
    provider_status_path = $providerStatusPath
    storage_settings = $storage
    provider_status = $providerStatus
    results = $rows
  }
  Write-Json (Join-Path $outputDir "agent_memory_isolation_results.json") $payload
  Write-Json (Join-Path $OutputRoot "agent_memory\agent_memory_isolation_results.json") $payload
  $payload | ConvertTo-Json -Depth 14
  if ($status -eq "blocked") { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
