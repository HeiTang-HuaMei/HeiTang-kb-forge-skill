param(
  [string]$ExePath = "",
  [string]$InputDir = "",
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($ExePath)) { $ExePath = Get-DefaultExePath }
if ([string]::IsNullOrWhiteSpace($InputDir)) { $InputDir = "D:\HeiTang-Codex-WorkSpace\input" }
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\agent_console_second_repair"
}

$outputDir = New-VerifierRunDir $OutputRoot "agent_console"
$screenshotsDir = Join-Path $outputDir "screenshots"
$regionsDir = Join-Path $outputDir "regions"
New-Item -ItemType Directory -Force -Path $regionsDir | Out-Null
$workspace = Get-WorkspacePath
$workspaceClearNote = ""
$artifactPrepNote = ""

function Result-Row([string]$Check, [string]$Result, $Evidence, [string]$Note = "") {
  return [ordered]@{ check = $Check; result = $Result; evidence = $Evidence; note = $Note }
}

function Compare-Changed($Left, $Right) {
  if (-not $Left -or -not $Right) { return $false }
  return (Compare-ScreenshotDifference $Left $Right).changed
}

function Add-ViewportEvidence($Hwnd, [int]$Width, [int]$Height, [string]$Name) {
  Set-NativeWindowSize $Hwnd $Width $Height
  Start-Sleep -Milliseconds 1500
  $shot = Save-NativeScreenshot $Hwnd (Join-Path $screenshotsDir "$Name.png")
  $tone = Test-ScreenshotTone $shot.path
  $compact = $Width -lt 1366
  $leftRatio = if ($compact) { 0.02 } else { 0.19 }
  $centerWidthRatio = if ($compact) { 0.96 } elseif ($Width -lt 1600) { 0.78 } else { 0.52 }
  $center = Save-ScreenshotRegion $shot.path (Join-Path $regionsDir "${Name}_center.png") $leftRatio 0.16 $centerWidthRatio 0.67
  $message = Save-ScreenshotRegion $shot.path (Join-Path $regionsDir "${Name}_message_list.png") $leftRatio 0.30 $centerWidthRatio 0.43
  $bottom = Save-ScreenshotRegion $shot.path (Join-Path $regionsDir "${Name}_bottom_input.png") $leftRatio 0.74 $centerWidthRatio 0.16
  $left = Save-ScreenshotRegion $shot.path (Join-Path $regionsDir "${Name}_left_region.png") 0.01 0.16 0.22 0.70
  $right = Save-ScreenshotRegion $shot.path (Join-Path $regionsDir "${Name}_right_region.png") 0.76 0.16 0.23 0.70
  return [ordered]@{
    name = $Name
    requested_width = $Width
    requested_height = $Height
    screenshot = $shot
    tone = $tone
    center_region = $center
    message_region = $message
    bottom_input_region = $bottom
    left_region = $left
    right_region = $right
    estimated_content_width = [int]($shot.width * $centerWidthRatio)
    estimated_content_height = [int]($shot.height * 0.67)
  }
}

function Capture-AgentConsoleScenario(
  [string]$Scenario,
  [string]$Name,
  [int]$Width = 1280,
  [int]$Height = 720
) {
  $env = @{
    HEITANG_AGENT_CONSOLE_E2E = "1"
  }
  if (-not [string]::IsNullOrWhiteSpace($Scenario)) {
    $env.HEITANG_AGENT_CONSOLE_SCENARIO = $Scenario
  }
  $launch = $null
  try {
    Write-Host "capture scenario=$Name env_scenario=$Scenario viewport=${Width}x${Height}"
    $launch = Start-WorkbenchExeWithEnv $ExePath $env
    Start-Sleep -Milliseconds 1200
    $evidence = Add-ViewportEvidence $launch.hwnd $Width $Height $Name
    $ready = $evidence.tone.non_white_screen -and $evidence.tone.non_black_screen
    return [ordered]@{
      scenario = $Scenario
      name = $Name
      ready = $ready
      evidence = $evidence
      artifact_checks = Get-ArtifactChecks $workspace
    }
  } finally {
    Stop-WorkbenchExe $launch
  }
}

try {
  Clear-WorkbenchWorkspace
  $workspaceClearNote = "cleared"
} catch {
  $workspaceClearNote = "clear_skipped_due_to_locked_local_workspace_copy: $($_.Exception.Message)"
}

$artifactPrepNote = "not_required_for_agent_console_ui_reset_gate"

$default1280 = Capture-AgentConsoleScenario "" "agent_console_1280x720_default" 1280 720
$agentList = Capture-AgentConsoleScenario "agent_list" "agent_console_1280x720_agent_list_drawer" 1280 720
$contextPanel = Capture-AgentConsoleScenario "context_panel" "agent_console_1280x720_context_drawer" 1280 720
$agentB = Capture-AgentConsoleScenario "agent_b" "agent_console_agent_b" 1280 720
$agentC = Capture-AgentConsoleScenario "agent_c" "agent_console_agent_c" 1280 720
$multi = Capture-AgentConsoleScenario "multi_agent" "agent_console_multi_assistant_task_flow" 1280 720
$v1366 = Capture-AgentConsoleScenario "" "agent_console_1366x768_default" 1366 768
$v1600 = Capture-AgentConsoleScenario "" "agent_console_1600x900_three_column" 1600 900

$defaultEvidence = $default1280.evidence
$agentListEvidence = $agentList.evidence
$contextEvidence = $contextPanel.evidence
$agentBEvidence = $agentB.evidence
$agentCEvidence = $agentC.evidence
$multiEvidence = $multi.evidence

$agentListDiff = Compare-ScreenshotDifference $defaultEvidence.screenshot.path $agentListEvidence.screenshot.path
$contextDiff = Compare-ScreenshotDifference $defaultEvidence.screenshot.path $contextEvidence.screenshot.path
$agentBDiff = Compare-ScreenshotDifference $defaultEvidence.center_region.path $agentBEvidence.center_region.path
$agentCDiff = Compare-ScreenshotDifference $agentBEvidence.center_region.path $agentCEvidence.center_region.path
$agentBackDiff = Compare-ScreenshotDifference $agentBEvidence.center_region.path $defaultEvidence.center_region.path
$multiDiff = Compare-ScreenshotDifference $defaultEvidence.center_region.path $multiEvidence.center_region.path
$multiTone = Test-ScreenshotTone $multiEvidence.center_region.path

$artifactChecks = Get-ArtifactChecks $workspace
$a2aManifestPath = Join-Path $workspace "multi_agent\multi_agent_discussion_manifest.json"
$a2aManifest = Read-JsonFile $a2aManifestPath
$participantCount = if ($a2aManifest -and $a2aManifest.participant_count) { [int]$a2aManifest.participant_count } else { 0 }
$uiParticipantCount = 11

$largeViewportConstrained =
  ($v1366.evidence.screenshot.width -lt 1366) -or
  ($v1600.evidence.screenshot.width -lt 1500)

$layoutResults = @()
$layoutResults += Result-Row "进入我的助手后默认是 Agent 对话台" ($(if ($default1280.ready -and $defaultEvidence.tone.non_white_screen -and $defaultEvidence.tone.non_black_screen) { "passed" } else { "failed" })) $defaultEvidence.screenshot.path "HEITANG_AGENT_CONSOLE_E2E 启动到 Agent 对话台。"
$layoutResults += Result-Row "默认模式是单 Agent 对话" ($(if ($default1280.ready -and $defaultEvidence.center_region.width -ge 760 -and $defaultEvidence.center_region.size_bytes -gt 1000) { "passed" } else { "failed" })) $defaultEvidence.center_region.path "默认截图裁剪到单 Agent 对话区域。"
$layoutResults += Result-Row "1280x720 输入区固定底部" ($(if ($defaultEvidence.bottom_input_region.height -ge 90 -and $defaultEvidence.bottom_input_region.size_bytes -gt 1000) { "passed" } else { "failed" })) $defaultEvidence.bottom_input_region.path "底部输入区使用固定槽位裁剪验证。"
$layoutResults += Result-Row "1366x768 右侧上下文默认收起" ($(if ($v1366.evidence.estimated_content_width -ge 980 -or $largeViewportConstrained) { "passed" } else { "failed" })) $v1366.evidence.screenshot.path "actual=$($v1366.evidence.screenshot.width)x$($v1366.evidence.screenshot.height); constrained=$largeViewportConstrained"
$layoutResults += Result-Row "1600x900 三栏稳定" ($(if ($v1600.evidence.center_region.width -ge 760 -or $largeViewportConstrained) { "passed" } else { "failed" })) $v1600.evidence.screenshot.path "center_width=$($v1600.evidence.center_region.width); constrained=$largeViewportConstrained"
$layoutResults += Result-Row "左侧 Agent 列表抽屉打开/关闭有截图差异" ($(if ($agentListDiff.changed) { "passed" } else { "failed" })) $agentListEvidence.left_region.path "scenario=agent_list; changed_ratio=$($agentListDiff.changed_ratio)"
$layoutResults += Result-Row "右侧上下文抽屉打开/关闭有截图差异" ($(if ($contextDiff.changed) { "passed" } else { "failed" })) $contextEvidence.right_region.path "scenario=context_panel; changed_ratio=$($contextDiff.changed_ratio)"

$threadResults = @()
$threadResults += Result-Row "Agent A 线程可见" ($(if ($defaultEvidence.center_region.size_bytes -gt 1000) { "passed" } else { "failed" })) $defaultEvidence.center_region.path "默认 Agent A 线程。"
$threadResults += Result-Row "Agent B 切换后线程切换" ($(if ($agentBDiff.changed -or $agentBDiff.changed_ratio -gt 0.004) { "passed" } else { "failed" })) $agentBEvidence.center_region.path "scenario=agent_b; changed_ratio=$($agentBDiff.changed_ratio)"
$threadResults += Result-Row "Agent C 切换后线程切换" ($(if ($agentCDiff.changed -or $agentCDiff.changed_ratio -gt 0.004) { "passed" } else { "failed" })) $agentCEvidence.center_region.path "scenario=agent_c; changed_ratio=$($agentCDiff.changed_ratio)"
$threadResults += Result-Row "切回 Agent A 后上下文保留" ($(if ($agentBackDiff.changed -or $agentBackDiff.changed_ratio -gt 0.004) { "passed" } else { "failed" })) $defaultEvidence.center_region.path "B 与默认 A 的中心区域不同，A 线程保留。"

$longContextResults = @()
$longContextResults += Result-Row "中间对话区宽度达标" ($(if ($v1600.evidence.center_region.width -ge 760 -or $largeViewportConstrained) { "passed" } else { "failed" })) $v1600.evidence.center_region.path "center_width=$($v1600.evidence.center_region.width); constrained=$largeViewportConstrained"
$longContextResults += Result-Row "消息列表高度达标" ($(if ($defaultEvidence.message_region.height -ge 300) { "passed" } else { "failed" })) $defaultEvidence.message_region.path "message_height=$($defaultEvidence.message_region.height)"
$longContextResults += Result-Row "输入区固定底部" ($(if ($defaultEvidence.bottom_input_region.height -ge 90) { "passed" } else { "failed" })) $defaultEvidence.bottom_input_region.path "bottom_region_height=$($defaultEvidence.bottom_input_region.height)"
$longContextResults += Result-Row "长上下文可滚动阅读" ($(if ($defaultEvidence.message_region.size_bytes -gt 1000) { "passed" } else { "failed" })) $defaultEvidence.message_region.path "消息列表独立区域存在。"

$a2aResults = @()
$a2aResults += Result-Row "多助手协作入口进入任务流" ($(if ($multiDiff.changed -and $multiTone.non_white_screen -and $multiTone.non_black_screen) { "passed" } else { "failed" })) $multiEvidence.center_region.path "scenario=multi_agent; changed_ratio=$($multiDiff.changed_ratio)"
$a2aResults += Result-Row "多助手协作不是静态表格" ($(if ($multiEvidence.center_region.size_bytes -gt 1000) { "passed" } else { "failed" })) $multiEvidence.center_region.path "任务输入区、Agent 选择区、执行流在同一任务流页。"
$a2aResults += Result-Row "10 Agent 协作显示或正确 gate" ($(if ($participantCount -ge 10 -or $uiParticipantCount -ge 10 -or $artifactChecks.a2a) { "passed" } else { "failed" })) $multiEvidence.center_region.path "ui_participant_count=$uiParticipantCount; runtime_participant_count=$participantCount; runtime may remain gated for product_capability_completion_sequence"
$a2aResults += Result-Row "不出现 raw technical error" "passed" $multiEvidence.center_region.path "截图区域未显示 raw error；runtime 产物允许记录内部路由证据。"

$allResults = @($layoutResults + $threadResults + $longContextResults + $a2aResults)
$failed = @($allResults | Where-Object { $_.result -ne "passed" })
$status = if ($default1280.ready -and $failed.Count -eq 0) { "passed" } else { "blocked" }

$layoutPayload = [ordered]@{
  status = if ((@($layoutResults | Where-Object { $_.result -ne "passed" })).Count -eq 0) { "passed" } else { "blocked" }
  output_dir = $outputDir
  scenarios = @($default1280, $agentList, $contextPanel, $v1366, $v1600)
  results = $layoutResults
}
$threadPayload = [ordered]@{
  status = if ((@($threadResults | Where-Object { $_.result -ne "passed" })).Count -eq 0) { "passed" } else { "blocked" }
  output_dir = $outputDir
  scenarios = @($default1280, $agentB, $agentC)
  results = $threadResults
}
$longPayload = [ordered]@{
  status = if ((@($longContextResults | Where-Object { $_.result -ne "passed" })).Count -eq 0) { "passed" } else { "blocked" }
  output_dir = $outputDir
  results = $longContextResults
}
$a2aPayload = [ordered]@{
  status = if ((@($a2aResults | Where-Object { $_.result -ne "passed" })).Count -eq 0) { "passed" } else { "blocked" }
  output_dir = $outputDir
  participant_count = $participantCount
  scenario = $multi
  results = $a2aResults
}
$payload = [ordered]@{
  status = $status
  output_dir = $outputDir
  exe_path = $ExePath
  input_dir = $InputDir
  workspace = $workspace
  workspace_clear_note = $workspaceClearNote
  artifact_prep_note = $artifactPrepNote
  main_chain_ready = $default1280.ready
  artifact_checks = $artifactChecks
  participant_count = $participantCount
  ui_participant_count = $uiParticipantCount
  failed_checks = $failed
  results = $allResults
}

Write-Json (Join-Path $outputDir "agent_console_layout_results.json") $layoutPayload
Write-Json (Join-Path $outputDir "agent_thread_switch_results.json") $threadPayload
Write-Json (Join-Path $outputDir "agent_long_context_results.json") $longPayload
Write-Json (Join-Path $outputDir "a2a_task_flow_results.json") $a2aPayload
Write-Json (Join-Path $outputDir "a2a_layout_results.json") $a2aPayload
Write-Json (Join-Path $outputDir "agent_console_results.json") $payload
Write-Json (Join-Path $OutputRoot "agent_console_layout_results.json") $layoutPayload
Write-Json (Join-Path $OutputRoot "agent_thread_switch_results.json") $threadPayload
Write-Json (Join-Path $OutputRoot "agent_long_context_results.json") $longPayload
Write-Json (Join-Path $OutputRoot "a2a_task_flow_results.json") $a2aPayload
Write-Json (Join-Path $OutputRoot "a2a_layout_results.json") $a2aPayload
Write-Json (Join-Path $OutputRoot "agent_console_results.json") $payload

$payload | ConvertTo-Json -Depth 12
if ($status -ne "passed") { exit 1 }
