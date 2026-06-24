param(
  [string]$ExePath = "",
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($ExePath)) { $ExePath = Get-DefaultExePath }
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\ui_full_visual_rework"
}

$outputDir = New-VerifierRunDir $OutputRoot "ui_full_campaign"
$screenshotsDir = Join-Path $outputDir "screenshots"
$regionsDir = Join-Path $outputDir "regions"
New-Item -ItemType Directory -Force -Path $regionsDir | Out-Null

function Add-CaptureResult(
  [System.Collections.ArrayList]$Results,
  [string]$Name,
  $Shot,
  $Tone,
  [string]$Expected
) {
  [void]$Results.Add([ordered]@{
    name = $Name
    expected = $Expected
    result = if ($Tone.non_white_screen -and $Tone.non_black_screen -and $Shot.size_bytes -gt 1000) { "passed" } else { "failed" }
    screenshot = $Shot.path
    width = $Shot.width
    height = $Shot.height
    size_bytes = $Shot.size_bytes
    tone = $Tone
  })
}

function Move-CursorAwayFromChrome($Hwnd) {
  Invoke-RelativeClick $Hwnd 0.50 0.94 | Out-Null
  Start-Sleep -Milliseconds 250
}

function Capture-Page(
  [System.Collections.ArrayList]$Results,
  $Hwnd,
  [string]$Name,
  [string]$ShortcutKey,
  [string]$Expected
) {
  Send-ControlAlt $ShortcutKey
  Start-Sleep -Milliseconds 500
  Move-CursorAwayFromChrome $Hwnd
  $shot = Save-NativeScreenshot $Hwnd (Join-Path $screenshotsDir "$Name.png")
  $tone = Test-ScreenshotTone $shot.path
  Add-CaptureResult $Results $Name $shot $tone $Expected
  return $shot
}

function Crop-Region(
  [System.Collections.ArrayList]$Regions,
  [string]$Name,
  [string]$SourcePath,
  [double]$Rx,
  [double]$Ry,
  [double]$Rw,
  [double]$Rh,
  [string]$Expected
) {
  $region = Save-ScreenshotRegion $SourcePath (Join-Path $regionsDir "$Name.png") $Rx $Ry $Rw $Rh
  $tone = Test-ScreenshotTone $region.path
  [void]$Regions.Add([ordered]@{
    name = $Name
    expected = $Expected
    result = if ($tone.non_white_screen -and $tone.non_black_screen -and $region.size_bytes -gt 800) { "passed" } else { "failed" }
    screenshot = $region.path
    width = $region.width
    height = $region.height
    size_bytes = $region.size_bytes
    source = $SourcePath
    tone = $tone
  })
  return $region
}

function Toggle-DarkTheme($Hwnd) {
  Send-ControlAlt "1"
  Start-Sleep -Milliseconds 400
  Invoke-RelativeClick $Hwnd 0.932 0.076 | Out-Null
  Start-Sleep -Milliseconds 900
}

function Capture-AgentScenario(
  [System.Collections.ArrayList]$Results,
  [string]$Scenario,
  [string]$Name,
  [string]$Expected
) {
  $env = @{ HEITANG_AGENT_CONSOLE_E2E = "1" }
  if (-not [string]::IsNullOrWhiteSpace($Scenario)) {
    $env.HEITANG_AGENT_CONSOLE_SCENARIO = $Scenario
  }
  $agentLaunch = $null
  try {
    $agentLaunch = Start-WorkbenchExeWithEnv $ExePath $env
    Set-NativeWindowSize $agentLaunch.hwnd 1440 900
    Start-Sleep -Milliseconds 1200
    Move-CursorAwayFromChrome $agentLaunch.hwnd
    $shot = Save-NativeScreenshot $agentLaunch.hwnd (Join-Path $screenshotsDir "$Name.png")
    $tone = Test-ScreenshotTone $shot.path
    Add-CaptureResult $Results $Name $shot $tone $Expected
    return $shot
  } finally {
    Stop-WorkbenchExe $agentLaunch
  }
}

$captures = [System.Collections.ArrayList]::new()
$regions = [System.Collections.ArrayList]::new()
$launch = $null

try {
  $launch = Start-WorkbenchExe $ExePath
  $hwnd = $launch.hwnd
  Set-NativeWindowSize $hwnd 1440 900

  $homeLight = Capture-Page $captures $hwnd "home_light_1440x900" "1" "首页浅色模式，知识资产 Hero、资产概览、供应链流程和底部状态栏可见。"
  Crop-Region $regions "home_hero_detail" $homeLight.path 0.18 0.09 0.80 0.21 "Hero 局部：知识资产转化主视觉、指标胶囊和主/次按钮。"
  Crop-Region $regions "home_hero_asset_glyph_detail" $homeLight.path 0.80 0.13 0.17 0.18 "Hero 右侧图形局部：文档资料 -> 知识库 -> 成果输出。"
  Crop-Region $regions "workspace_assets_detail" $homeLight.path 0.18 0.30 0.33 0.34 "资产概览局部：语义色图标、状态点和轻分隔。"
  Crop-Region $regions "knowledge_supply_chain_detail" $homeLight.path 0.50 0.30 0.48 0.34 "知识供应链局部：纵向 stepper、当前状态和进度。"
  Crop-Region $regions "continue_activity_outputs_detail" $homeLight.path 0.18 0.63 0.80 0.26 "继续任务、最近动态、最近成果局部。"
  Crop-Region $regions "sidebar_detail_light" $homeLight.path 0.00 0.00 0.18 0.96 "侧边栏浅色局部。"
  Crop-Region $regions "topbar_detail_light" $homeLight.path 0.17 0.00 0.83 0.09 "顶部栏浅色局部。"
  Crop-Region $regions "statusbar_detail_light" $homeLight.path 0.17 0.965 0.83 0.035 "底部状态栏浅色局部。"
  Crop-Region $regions "button_card_detail_light" $homeLight.path 0.18 0.18 0.38 0.12 "按钮和 Hero 卡片浅色局部。"

  $documentLight = Capture-Page $captures $hwnd "document_library_light_1440x900" "3" "我的资料/文档库浅色模式。"
  Crop-Region $regions "input_card_detail_light" $documentLight.path 0.18 0.20 0.46 0.28 "输入框、卡片和资料导入控件浅色局部。"

  $knowledgeLight = Capture-Page $captures $hwnd "knowledge_base_light_1440x900" "4" "知识库浅色模式，验证为内部 Tab，不在一级导航。"
  Invoke-RelativeClick $hwnd 0.365 0.218 | Out-Null
  Start-Sleep -Milliseconds 450
  Move-CursorAwayFromChrome $hwnd
  $knowledgeVerifyLight = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir "knowledge_base_verification_tab_1440x900.png")
  $knowledgeVerifyTone = Test-ScreenshotTone $knowledgeVerifyLight.path
  Add-CaptureResult $captures "knowledge_base_verification_tab_1440x900" $knowledgeVerifyLight $knowledgeVerifyTone "知识库内部验证 Tab：验证位于知识库内部。"
  Crop-Region $regions "knowledge_internal_verification_tab_detail" $knowledgeVerifyLight.path 0.18 0.17 0.80 0.55 "知识库内部验证 Tab 局部。"
  $artifactLight = Capture-Page $captures $hwnd "all_outputs_light_1440x900" "9" "全部成果二级页面浅色模式，不在一级导航。"
  $settingsLight = Capture-Page $captures $hwnd "settings_advanced_light_1440x900" "S" "设置页高级配置区域浅色模式。"

  Toggle-DarkTheme $hwnd
  $homeDark = Capture-Page $captures $hwnd "home_dark_1440x900" "1" "首页暗夜模式，macOS 深灰分层和局部玻璃浮层可见。"
  Crop-Region $regions "sidebar_detail_dark" $homeDark.path 0.00 0.00 0.18 0.96 "侧边栏暗夜局部。"
  Crop-Region $regions "topbar_detail_dark" $homeDark.path 0.17 0.00 0.83 0.09 "顶部栏暗夜局部。"
  Crop-Region $regions "statusbar_detail_dark" $homeDark.path 0.17 0.965 0.83 0.035 "底部状态栏暗夜局部。"
  Crop-Region $regions "button_card_detail_dark" $homeDark.path 0.18 0.18 0.38 0.12 "按钮和 Hero 卡片暗夜局部。"

  $documentDark = Capture-Page $captures $hwnd "document_library_dark_1440x900" "3" "我的资料/文档库暗夜模式。"
  Crop-Region $regions "input_card_detail_dark" $documentDark.path 0.18 0.20 0.46 0.28 "输入框、卡片和资料导入控件暗夜局部。"
  $knowledgeDark = Capture-Page $captures $hwnd "knowledge_base_dark_1440x900" "4" "知识库暗夜模式。"
  $artifactDark = Capture-Page $captures $hwnd "all_outputs_dark_1440x900" "9" "全部成果二级页面暗夜模式，不在一级导航。"
  $settingsDark = Capture-Page $captures $hwnd "settings_advanced_dark_1440x900" "S" "设置页高级配置区域暗夜模式。"

  $homeThemeDiff = Compare-ScreenshotDifference $homeLight.path $homeDark.path
  $documentThemeDiff = Compare-ScreenshotDifference $documentLight.path $documentDark.path
  $knowledgeThemeDiff = Compare-ScreenshotDifference $knowledgeLight.path $knowledgeDark.path
  $artifactThemeDiff = Compare-ScreenshotDifference $artifactLight.path $artifactDark.path
  $settingsThemeDiff = Compare-ScreenshotDifference $settingsLight.path $settingsDark.path
} finally {
  Stop-WorkbenchExe $launch
}

$agentSingle = Capture-AgentScenario $captures "" "my_assistant_single_dialogue_1440x900" "我的助手：助手对话模式。"
$agentMulti = Capture-AgentScenario $captures "multi_agent" "my_assistant_multi_discussion_1440x900" "我的助手：工作小组模式。"
$agentConfig = Capture-AgentScenario $captures "agent_config" "my_assistant_config_1440x900" "我的助手：助手配置模式。"
Crop-Region $regions "my_assistant_topbar_title_detail" $agentSingle.path 0.17 0.00 0.83 0.18 "我的助手顶部局部：标题显示我的助手，顶部栏、标题区和模式切换区不遮挡。"
Crop-Region $regions "my_assistant_segmented_control_detail" $agentSingle.path 0.18 0.125 0.42 0.085 "模式切换局部：助手对话、工作小组、助手配置文字完整显示。"
Crop-Region $regions "my_assistant_single_center_detail" $agentSingle.path 0.18 0.08 0.58 0.83 "助手对话主工作区局部。"
Crop-Region $regions "my_assistant_multi_flow_detail" $agentMulti.path 0.18 0.08 0.58 0.83 "工作小组任务流局部。"
Crop-Region $regions "my_assistant_context_detail" $agentMulti.path 0.76 0.08 0.23 0.83 "我的助手右侧上下文与成果承接局部。"
Crop-Region $regions "my_assistant_config_detail" $agentConfig.path 0.18 0.08 0.58 0.83 "助手配置模式局部。"
Crop-Region $regions "my_assistant_sidebar_active_detail" $agentSingle.path 0.00 0.00 0.18 0.96 "侧边栏 active 状态局部：我的助手为当前选中页面。"
Crop-Region $regions "my_assistant_statusbar_detail" $agentSingle.path 0.17 0.965 0.83 0.035 "底部状态栏局部。"

$themeDiffs = @(
  [ordered]@{ name = "home_light_vs_dark"; result = if ($homeThemeDiff.changed) { "passed" } else { "failed" }; diff = $homeThemeDiff },
  [ordered]@{ name = "document_library_light_vs_dark"; result = if ($documentThemeDiff.changed) { "passed" } else { "failed" }; diff = $documentThemeDiff },
  [ordered]@{ name = "knowledge_base_light_vs_dark"; result = if ($knowledgeThemeDiff.changed) { "passed" } else { "failed" }; diff = $knowledgeThemeDiff },
  [ordered]@{ name = "artifact_center_light_vs_dark"; result = if ($artifactThemeDiff.changed) { "passed" } else { "failed" }; diff = $artifactThemeDiff },
  [ordered]@{ name = "settings_light_vs_dark"; result = if ($settingsThemeDiff.changed) { "passed" } else { "failed" }; diff = $settingsThemeDiff }
)

$failedCaptures = @($captures | Where-Object { $_.result -ne "passed" })
$failedRegions = @($regions | Where-Object { $_.result -ne "passed" })
$failedThemeDiffs = @($themeDiffs | Where-Object { $_.result -ne "passed" })
$status = if ($failedCaptures.Count -eq 0 -and $failedRegions.Count -eq 0 -and $failedThemeDiffs.Count -eq 0) { "passed" } else { "blocked" }

$payload = [ordered]@{
  status = $status
  output_dir = $outputDir
  exe_path = $ExePath
  screenshots_dir = $screenshotsDir
  regions_dir = $regionsDir
  captures = $captures
  regions = $regions
  theme_differences = $themeDiffs
  failed_captures = $failedCaptures
  failed_regions = $failedRegions
  failed_theme_differences = $failedThemeDiffs
}

Write-Json (Join-Path $outputDir "ui_full_campaign_results.json") $payload
Write-Json (Join-Path $OutputRoot "ui_full_campaign_results.json") $payload
$payload | ConvertTo-Json -Depth 12
if ($status -ne "passed") { exit 1 }
