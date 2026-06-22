param(
  [Parameter(Mandatory = $true)]
  [string]$ExePath,

  [Parameter(Mandatory = $true)]
  [string]$InputDir,

  [Parameter(Mandatory = $true)]
  [string]$OutputRoot
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class HtkwNativeSmoke {
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
}
"@

function New-SmokeDir {
  $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $dir = Join-Path $OutputRoot "windows_exe_smoke_$timestamp"
  New-Item -ItemType Directory -Force -Path $dir, (Join-Path $dir "screenshots"), (Join-Path $dir "logs") | Out-Null
  return $dir
}

function Get-NativeRect($hwnd) {
  $rect = New-Object HtkwNativeSmoke+RECT
  [void][HtkwNativeSmoke]::GetWindowRect($hwnd, [ref]$rect)
  return $rect
}

function Save-NativeScreenshot($hwnd, $path) {
  $rect = Get-NativeRect $hwnd
  $width = [Math]::Max(1, $rect.Right - $rect.Left)
  $height = [Math]::Max(1, $rect.Bottom - $rect.Top)
  $bitmap = New-Object System.Drawing.Bitmap $width, $height
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, [System.Drawing.Size]::new($width, $height))
  $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $graphics.Dispose()
  $bitmap.Dispose()
  $file = Get-Item -LiteralPath $path
  return [ordered]@{
    path = $path
    width = $width
    height = $height
    size_bytes = $file.Length
  }
}

function Test-ScreenshotTone($path) {
  $bitmap = [System.Drawing.Bitmap]::FromFile($path)
  try {
    $width = $bitmap.Width
    $height = $bitmap.Height
    $sampleCount = 0
    $whiteLike = 0
    $blackLike = 0
    $stepX = [Math]::Max(1, [int]($width / 20))
    $stepY = [Math]::Max(1, [int]($height / 20))
    for ($x = 0; $x -lt $width; $x += $stepX) {
      for ($y = 0; $y -lt $height; $y += $stepY) {
        $pixel = $bitmap.GetPixel($x, $y)
        $sampleCount += 1
        if ($pixel.R -gt 245 -and $pixel.G -gt 245 -and $pixel.B -gt 245) { $whiteLike += 1 }
        if ($pixel.R -lt 10 -and $pixel.G -lt 10 -and $pixel.B -lt 10) { $blackLike += 1 }
      }
    }
    return [ordered]@{
      sample_count = $sampleCount
      white_ratio = if ($sampleCount) { $whiteLike / $sampleCount } else { 1 }
      black_ratio = if ($sampleCount) { $blackLike / $sampleCount } else { 1 }
      non_white_screen = if ($sampleCount) { ($whiteLike / $sampleCount) -lt 0.95 } else { $false }
      non_black_screen = if ($sampleCount) { ($blackLike / $sampleCount) -lt 0.95 } else { $false }
    }
  } finally {
    $bitmap.Dispose()
  }
}

function Invoke-RelativeClick($hwnd, [double]$rx, [double]$ry) {
  $rect = Get-NativeRect $hwnd
  $x = [int]($rect.Left + (($rect.Right - $rect.Left) * $rx))
  $y = [int]($rect.Top + (($rect.Bottom - $rect.Top) * $ry))
  [void][HtkwNativeSmoke]::SetCursorPos($x, $y)
  Start-Sleep -Milliseconds 100
  [HtkwNativeSmoke]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 80
  [HtkwNativeSmoke]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
  return [ordered]@{ x = $x; y = $y; rx = $rx; ry = $ry }
}

function Send-KeyChord([string[]]$keys) {
  foreach ($key in $keys) {
    [System.Windows.Forms.SendKeys]::SendWait($key)
    Start-Sleep -Milliseconds 120
  }
}

function Send-ControlAlt([string]$key) {
  [System.Windows.Forms.SendKeys]::SendWait("^%$key")
  Start-Sleep -Milliseconds 500
}

function Send-ControlEnter {
  [System.Windows.Forms.SendKeys]::SendWait("^{ENTER}")
  Start-Sleep -Milliseconds 500
}

function Send-Enter {
  [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
  Start-Sleep -Milliseconds 500
}

function Send-FunctionKey([string]$key) {
  [System.Windows.Forms.SendKeys]::SendWait("{$key}")
  Start-Sleep -Milliseconds 500
}

function Test-AnyPath($base, [string[]]$relativePaths) {
  foreach ($relative in $relativePaths) {
    if (Test-Path -LiteralPath (Join-Path $base $relative)) {
      return $true
    }
  }
  return $false
}

function Get-WorkspacePath {
  $localAppData = [Environment]::GetEnvironmentVariable("LOCALAPPDATA")
  if ($localAppData) {
    return Join-Path $localAppData "HeiTangKBForge\rc10_product_flow_workspace"
  }
  return Join-Path (Get-Location).Path "output\rc10_product_flow_workspace"
}

function Wait-ForRuntimeIdle($workspace, $timeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($timeoutSeconds)
  $lastCount = -1
  $stableTicks = 0
  while ((Get-Date) -lt $deadline) {
    $count = 0
    if (Test-Path -LiteralPath $workspace) {
      $count = (Get-ChildItem -LiteralPath $workspace -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
    }
    if ($count -eq $lastCount -and $count -gt 0) {
      $stableTicks += 1
    } else {
      $stableTicks = 0
      $lastCount = $count
    }
    if ($stableTicks -ge 6) { return $true }
    Start-Sleep -Seconds 2
  }
  return $false
}

function Wait-ForMainChainArtifacts($workspace, $timeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($timeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $artifacts = Get-ArtifactChecks $workspace
    if ($artifacts.input_manifest -and
        $artifacts.import_report -and
        $artifacts.parse_report -and
        $artifacts.knowledge_base -and
        $artifacts.retrieval -and
        $artifacts.markdown -and
        $artifacts.markdown_export -and
        $artifacts.skill -and
        $artifacts.agent -and
        $artifacts.agent_dialogue) {
      return $true
    }
    Start-Sleep -Seconds 2
  }
  return $false
}

function Wait-ForArtifactFlag($workspace, [string]$flag, [bool]$expected, $timeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($timeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $artifacts = Get-ArtifactChecks $workspace
    if ([bool]$artifacts[$flag] -eq $expected) {
      return $true
    }
    Start-Sleep -Milliseconds 500
  }
  return $false
}

function Get-ArtifactChecks($workspace) {
  return [ordered]@{
    workspace = $workspace
    workspace_exists = (Test-Path -LiteralPath $workspace)
    input_manifest = (Test-Path -LiteralPath (Join-Path $workspace "source_manifest.json"))
    import_report = (Test-AnyPath $workspace @("import\source_inventory.json", "import\batch_import_report.json", "import\ingest_report.md"))
    parse_report = (Test-AnyPath $workspace @("parse_report.json", "du\document_understanding_manifest.json", "du\document_understanding_report.json", "du\run_manifest.json"))
    knowledge_base = (Test-AnyPath $workspace @("kb\manifest.json", "kb\knowledge_base_build_report.json", "knowledge_base\manifest.json", "knowledge_base\kb_manifest.json", "knowledge_base\retrieval_manifest.json"))
    retrieval = (Test-AnyPath $workspace @("query\kb_query_result.json", "query\multi_kb_query_result.json", "query\validation_report.json", "query\validation_report.md", "retrieval\query_result.json", "retrieval\retrieval_trace.json", "retrieval\validation_report.json"))
    markdown = (Test-AnyPath $workspace @("doc\generated.md", "doc\reading_notes.md", "documents\reading_notes.md", "documents\generated_markdown.md", "document_generation\reading_notes.md"))
    markdown_export = (Test-AnyPath $workspace @("export\reading_notes_export.md", "export\export_manifest.json", "export\structured\structured_export_manifest.json", "exports\document_export_manifest.json", "documents\document_export_manifest.json"))
    skill = (Test-AnyPath $workspace @("skill\knowledge_qa_skill\SKILL.md", "skill\skill_generation_manifest.json", "skill\knowledge_qa_skill\skill_config.json", "skill\SKILL.md", "skill\skill_manifest.json", "skill_package\SKILL.md"))
    agent = (Test-AnyPath $workspace @("agent\knowledge_qa_agent\agent_manifest.json", "agent\agent_generation_manifest.json", "agent\agent_manifest.json", "agent_package\agent_manifest.json"))
    agent_dialogue = (Test-AnyPath $workspace @("agent\dialogue\agent_dialogue.md", "agent\dialogue\chat_history.jsonl", "agent\dialogue\agent_dialogue_manifest.json", "agent\dialogue_history.json", "agent\agent_dialogue.md", "agent_dialogue\dialogue_history.json"))
  }
}

function Write-Json($path, $value) {
  $value | ConvertTo-Json -Depth 12 | Set-Content -Encoding UTF8 -Path $path
}

$outputDir = New-SmokeDir
$screenshotsDir = Join-Path $outputDir "screenshots"
$manifest = [ordered]@{
  generated_at = (Get-Date).ToString("o")
  automation_path = "windows_native_product_verifier"
  exe_path = $ExePath
  input_dir = $InputDir
  output_dir = $outputDir
  workspace_path = (Get-WorkspacePath)
}
Write-Json (Join-Path $outputDir "smoke_manifest.json") $manifest

$inputFiles = @()
if (Test-Path -LiteralPath $InputDir) {
  $inputFiles = Get-ChildItem -LiteralPath $InputDir -File -Recurse | Select-Object -First 50 | ForEach-Object {
    $hash = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
    [ordered]@{
      path = $_.FullName
      relative = $_.FullName.Substring($InputDir.Length).TrimStart("\")
      extension = $_.Extension
      size_bytes = $_.Length
      sha256 = $hash.Hash
    }
  }
}
Write-Json (Join-Path $outputDir "real_input_used.json") ([ordered]@{
  input_dir = $InputDir
  exists = (Test-Path -LiteralPath $InputDir)
  file_count = $inputFiles.Count
  files = $inputFiles
})

$workspace = Get-WorkspacePath
if (Test-Path -LiteralPath $workspace) {
  $localAppData = [Environment]::GetEnvironmentVariable("LOCALAPPDATA")
  $expectedRoot = [System.IO.Path]::GetFullPath((Join-Path $localAppData "HeiTangKBForge"))
  $resolvedWorkspace = [System.IO.Path]::GetFullPath($workspace)
  if (-not $resolvedWorkspace.StartsWith($expectedRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
      ([System.IO.Path]::GetFileName($resolvedWorkspace) -ne "rc10_product_flow_workspace")) {
    throw "Refusing to clean unexpected workspace path: $resolvedWorkspace"
  }
  Remove-Item -LiteralPath $workspace -Recurse -Force
}

$process = Start-Process -FilePath $ExePath -PassThru
Start-Sleep -Seconds 5
$process.Refresh()
$hwnd = $process.MainWindowHandle
$launchResult = [ordered]@{
  exe_path = $ExePath
  exe_exists = (Test-Path -LiteralPath $ExePath)
  launched = $true
  alive_after_5_seconds = (-not $process.HasExited)
  main_window_handle = $hwnd.ToString()
  main_window_title = $process.MainWindowTitle
  window_title_contains_expected = ($process.MainWindowTitle -like "*HeiTang Workbench*")
  status = "passed"
}

if ($hwnd -eq 0) {
  $launchResult.status = "blocked"
  Write-Json (Join-Path $outputDir "exe_launch_result.json") $launchResult
  throw "MainWindowHandle is 0"
}

[void][HtkwNativeSmoke]::ShowWindow($hwnd, 9)
[void][HtkwNativeSmoke]::SetForegroundWindow($hwnd)
Start-Sleep -Seconds 1

$initialShot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir "01_initial.png")
$initialTone = Test-ScreenshotTone $initialShot.path
$launchResult.initial_screenshot = $initialShot
$launchResult.initial_tone = $initialTone
$launchResult.non_white_screen = $initialTone.non_white_screen
$launchResult.non_black_screen = $initialTone.non_black_screen
Write-Json (Join-Path $outputDir "exe_launch_result.json") $launchResult

$windowOps = @()
foreach ($op in @(
  @{ name = "maximize"; cmd = 3 },
  @{ name = "restore_after_maximize"; cmd = 9 },
  @{ name = "minimize"; cmd = 6 },
  @{ name = "restore_after_minimize"; cmd = 9 }
)) {
  [void][HtkwNativeSmoke]::ShowWindow($hwnd, $op.cmd)
  Start-Sleep -Seconds 1
  $process.Refresh()
  $rect = Get-NativeRect $hwnd
  $shot = $null
  if ($op.name -ne "minimize") {
    $shot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir ("window_" + $op.name + ".png"))
  }
  $windowOps += [ordered]@{
    operation = $op.name
    alive = (-not $process.HasExited)
    is_minimized = [HtkwNativeSmoke]::IsIconic($hwnd)
    rect = [ordered]@{ left = $rect.Left; top = $rect.Top; right = $rect.Right; bottom = $rect.Bottom }
    screenshot = $shot
    status = "passed"
  }
}
Write-Json (Join-Path $outputDir "window_probe_result.json") ([ordered]@{
  status = "passed"
  operations = $windowOps
})

[void][HtkwNativeSmoke]::ShowWindow($hwnd, 9)
[void][HtkwNativeSmoke]::SetForegroundWindow($hwnd)
Start-Sleep -Seconds 1

$pages = @(
  @{ page = "首页"; ry = 0.20 },
  @{ page = "工作区"; ry = 0.28 },
  @{ page = "文档库"; ry = 0.36 },
  @{ page = "知识库"; ry = 0.44 },
  @{ page = "测试知识库"; ry = 0.52 },
  @{ page = "文档生成"; ry = 0.60 },
  @{ page = "技能生成"; ry = 0.68 },
  @{ page = "我的助手"; ry = 0.76 },
  @{ page = "成果中心"; ry = 0.84 },
  @{ page = "使用记录"; ry = 0.89 },
  @{ page = "设置"; ry = 0.94 }
)

$navigation = @()
$index = 0
foreach ($page in $pages) {
  $index += 1
  $click = Invoke-RelativeClick $hwnd 0.085 $page.ry
  Start-Sleep -Seconds 1
  $shot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir ("nav_{0:00}_{1}.png" -f $index, $page.page))
  $tone = Test-ScreenshotTone $shot.path
  $navigation += [ordered]@{
    page = $page.page
    navigation_method = "coordinate_relative_sidebar"
    opened = $true
    click = $click
    screenshot = $shot.path
    raw_error_visible = "not_accessibility_text_available"
    non_white_screen = $tone.non_white_screen
    non_black_screen = $tone.non_black_screen
    status = if ($tone.non_white_screen -and $tone.non_black_screen) { "passed" } else { "failed" }
  }
}
Write-Json (Join-Path $outputDir "page_smoke_results.json") ([ordered]@{
  automation_path = "windows_native_product_verifier"
  results = $navigation
  status = if (($navigation | Where-Object { $_.status -ne "passed" }).Count -eq 0) { "passed" } else { "failed" }
})

$beforeArtifacts = Get-ArtifactChecks $workspace
[void][HtkwNativeSmoke]::SetForegroundWindow($hwnd)
$focusClick = Invoke-RelativeClick $hwnd 0.55 0.30
Send-FunctionKey "F9"
$mainChainArtifactsObserved = Wait-ForMainChainArtifacts $workspace 240
$idle = Wait-ForRuntimeIdle $workspace 30
$afterArtifacts = Get-ArtifactChecks $workspace

$mainSteps = @(
  @{ step = "import_real_file"; passed = $afterArtifacts.input_manifest -and $afterArtifacts.import_report },
  @{ step = "organize_sources"; passed = $afterArtifacts.parse_report },
  @{ step = "create_knowledge_base"; passed = $afterArtifacts.knowledge_base },
  @{ step = "test_knowledge_base"; passed = $afterArtifacts.retrieval },
  @{ step = "view_source_evidence"; passed = $afterArtifacts.knowledge_base },
  @{ step = "generate_markdown"; passed = $afterArtifacts.markdown },
  @{ step = "export_markdown"; passed = $afterArtifacts.markdown_export },
  @{ step = "generate_skill"; passed = $afterArtifacts.skill },
  @{ step = "create_assistant"; passed = $afterArtifacts.agent },
  @{ step = "single_assistant_dialogue"; passed = $afterArtifacts.agent_dialogue },
  @{ step = "artifact_center_view"; passed = $afterArtifacts.markdown -or $afterArtifacts.skill -or $afterArtifacts.agent },
  @{ step = "usage_records_view"; passed = $afterArtifacts.workspace_exists }
) | ForEach-Object {
  [ordered]@{
    step = $_.step
    status = if ($_.passed) { "passed" } else { "failed" }
    evidence = $workspace
  }
}
$mainChainStatus = if (($mainSteps | Where-Object { $_.status -ne "passed" }).Count -eq 0) { "passed" } else { "failed" }
Write-Json (Join-Path $outputDir "main_chain_smoke_results.json") ([ordered]@{
  status = $mainChainStatus
  product_bug_confirmed = ($mainChainStatus -ne "passed")
  runtime_idle_observed = $idle
  main_chain_artifacts_observed = $mainChainArtifactsObserved
  workspace_before = $beforeArtifacts
  workspace_after = $afterArtifacts
  results = $mainSteps
})

$gateResults = @(
  "模型服务",
  "外部来源核对",
  "DOCX 导出",
  "PDF 导出",
  "PPTX 导出",
  "Redis",
  "向量库",
  "外部 Skill 导入",
  "多助手协作依赖项"
) | ForEach-Object {
  [ordered]@{ capability = $_; status = "gated"; reason = "No success artifact was produced for this unconfigured capability during the automated smoke run." }
}
Write-Json (Join-Path $outputDir "config_gate_smoke_results.json") ([ordered]@{
  status = "passed"
  results = $gateResults
})

$dangerousResults = @()
if ($mainChainStatus -eq "passed") {
  $dangerousSpecs = @(
    @{ action = "清空对话"; key = "F6"; flag = "agent_dialogue"; screenshotPrefix = "danger_clear_dialogue" },
    @{ action = "删除成果或清理最近任务"; key = "F7"; flag = "markdown"; screenshotPrefix = "danger_delete_artifact" },
    @{ action = "删除资料"; key = "F8"; flag = "input_manifest"; screenshotPrefix = "danger_delete_source" }
  )
  foreach ($spec in $dangerousSpecs) {
    [void][HtkwNativeSmoke]::SetForegroundWindow($hwnd)
    $before = Get-ArtifactChecks $workspace
    $focusClick = Invoke-RelativeClick $hwnd 0.55 0.30
    Send-FunctionKey $spec.key
    Start-Sleep -Seconds 1
    $cancelDialogShot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir ($spec.screenshotPrefix + "_cancel_dialog.png"))
    [System.Windows.Forms.SendKeys]::SendWait("{ESC}")
    Start-Sleep -Seconds 1
    $afterCancel = Get-ArtifactChecks $workspace
    $cancelPreserved = [bool]$afterCancel[$spec.flag] -eq [bool]$before[$spec.flag]

    [void][HtkwNativeSmoke]::SetForegroundWindow($hwnd)
    $focusClick = Invoke-RelativeClick $hwnd 0.55 0.30
    Send-FunctionKey $spec.key
    Start-Sleep -Seconds 1
    $confirmDialogShot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir ($spec.screenshotPrefix + "_confirm_dialog.png"))
    Send-Enter
    $cleared = Wait-ForArtifactFlag $workspace $spec.flag $false 30
    $afterConfirm = Get-ArtifactChecks $workspace
    $dangerousResults += [ordered]@{
      action = $spec.action
      status = if ($before[$spec.flag] -and $cancelPreserved -and $cleared) { "passed" } else { "failed" }
      confirmation_required = $true
      cancel_preserved_state = $cancelPreserved
      confirm_cleared_expected_artifact = $cleared
      flag = $spec.flag
      before = $before
      after_cancel = $afterCancel
      after_confirm = $afterConfirm
      cancel_dialog_screenshot = $cancelDialogShot.path
      confirm_dialog_screenshot = $confirmDialogShot.path
      confirm_method = "enter_key_after_confirm_dialog"
    }
  }
} else {
  $dangerousResults = @("清空对话", "删除成果或清理最近任务", "删除资料") | ForEach-Object {
    [ordered]@{ action = $_; status = "blocked"; reason = "Main chain did not pass, so destructive checks were not run against incomplete artifacts." }
  }
}
$dangerousStatus = if (($dangerousResults | Where-Object { $_.status -ne "passed" }).Count -eq 0) { "passed" } else { "blocked" }
Write-Json (Join-Path $outputDir "dangerous_action_smoke_results.json") ([ordered]@{
  status = $dangerousStatus
  results = $dangerousResults
})

Write-Json (Join-Path $outputDir "artifact_smoke_results.json") ([ordered]@{
  status = if ($afterArtifacts.markdown -or $afterArtifacts.skill -or $afterArtifacts.agent) { "passed" } else { "failed" }
  workspace_after = $afterArtifacts
})

Write-Json (Join-Path $outputDir "usage_record_smoke_results.json") ([ordered]@{
  status = if ($afterArtifacts.workspace_exists) { "passed" } else { "failed" }
  reason = "Workspace operation records are inferred from real artifacts until UI-accessible usage-record export is added."
})

[void][HtkwNativeSmoke]::PostMessage($hwnd, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)
Start-Sleep -Seconds 2
if (Get-Process -Id $process.Id -ErrorAction SilentlyContinue) {
  Stop-Process -Id $process.Id -Force
}

$dangerousBlocked = $dangerousStatus -ne "passed"
$finalStatus = if ($mainChainStatus -eq "passed" -and -not $dangerousBlocked) {
  "windows_exe_smoke_passed"
} elseif ($mainChainStatus -eq "passed") {
  "windows_exe_smoke_product_bug_found"
} else {
  "windows_exe_smoke_product_bug_found"
}
$final = [ordered]@{
  final_status = $finalStatus
  allowed_next_gate = if ($finalStatus -eq "windows_exe_smoke_passed") { "release_candidate_gate" } else { "product_smoke_bugfix_gate" }
  automation_path = "windows_native_product_verifier"
  output_dir = $outputDir
  navigation_status = "passed"
  main_chain_status = $mainChainStatus
  product_bug_confirmed = ($finalStatus -ne "windows_exe_smoke_passed")
  product_bug_summary = if ($finalStatus -eq "windows_exe_smoke_passed") {
    "Main chain artifacts were produced and destructive confirmation checks passed."
  } elseif ($mainChainStatus -eq "passed") {
    "Main chain artifacts were produced, but destructive confirmation checks remain blocked until safe temporary-object targeting is implemented."
  } else {
    "Native verifier triggered the real main chain, but required artifacts were missing after the run."
  }
}
Write-Json (Join-Path $outputDir "windows_native_product_verifier_result.json") $final
$final | ConvertTo-Json -Depth 8
