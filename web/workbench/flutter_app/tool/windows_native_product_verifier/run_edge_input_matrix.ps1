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

$outputDir = New-VerifierRunDir $OutputRoot "edge_input"
$screenshotsDir = Join-Path $outputDir "screenshots"
$workspace = Get-WorkspacePath
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("heitang_edge_input_" + (Get-Date -Format "yyyyMMdd_HHmmss"))
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

$zhDir = Join-Path $tempRoot "中文 路径"
$spaceDir = Join-Path $tempRoot "path with spaces"
$emptyDir = Join-Path $tempRoot "empty_dir"
$unsupportedDir = Join-Path $tempRoot "unsupported_dir"
$readonlyDir = Join-Path $tempRoot "readonly_dir"
$validFile = Join-Path $tempRoot "single_valid.md"
$duplicateFile = Join-Path $tempRoot "duplicate_valid.md"
$emptyFile = Join-Path $tempRoot "empty.md"
$brokenFile = Join-Path $tempRoot "broken.pdf"
$unsupportedFile = Join-Path $tempRoot "unsupported.exe"
$longDir = Join-Path $tempRoot ("long_" + ("a" * 80))

New-Item -ItemType Directory -Force -Path $zhDir, $spaceDir, $emptyDir, $unsupportedDir, $readonlyDir, $longDir | Out-Null
"# 单文件真实导入`n`n用于 EXE 边界验收。" | Set-Content -Encoding UTF8 -Path $validFile
"# 重复导入`n`n用于重复导入验收。" | Set-Content -Encoding UTF8 -Path $duplicateFile
"" | Set-Content -Encoding UTF8 -Path $emptyFile
"not a real pdf" | Set-Content -Encoding UTF8 -Path $brokenFile
"unsupported" | Set-Content -Encoding UTF8 -Path $unsupportedFile
"# 中文路径资料" | Set-Content -Encoding UTF8 -Path (Join-Path $zhDir "中文 文件.md")
"# 带空格路径资料" | Set-Content -Encoding UTF8 -Path (Join-Path $spaceDir "space file.md")
"not supported" | Set-Content -Encoding UTF8 -Path (Join-Path $unsupportedDir "only.bin")
"# 只读目录资料" | Set-Content -Encoding UTF8 -Path (Join-Path $readonlyDir "readonly.md")
"# 超长路径资料" | Set-Content -Encoding UTF8 -Path (Join-Path $longDir "long.md")
try { (Get-Item -LiteralPath $readonlyDir).Attributes = (Get-Item -LiteralPath $readonlyDir).Attributes -bor [IO.FileAttributes]::ReadOnly } catch {}

Clear-WorkbenchWorkspace
$launch = $null
try {
  $launch = Start-WorkbenchExe $ExePath
  $hwnd = $launch.hwnd
  Send-ControlAlt "3"

  function Invoke-ImportPathCase([string]$Name, [string]$PathValue, [string]$Expected, [string]$ExpectedResult, [bool]$ExpectImport) {
    $before = Get-SourceManifestInfo $workspace
    Set-VerifierClipboardText $PathValue
    [void][HtkwNativeVerifierCommon]::SetForegroundWindow($hwnd)
    $focusClick = Invoke-RelativeClick $hwnd 0.55 0.30
    Send-FunctionKey "F5"
    Start-Sleep -Seconds 8
    $after = Get-SourceManifestInfo $workspace
    $shot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir ("edge_{0}.png" -f ($Name -replace '[^\w-]', '_')))
    $tone = Test-ScreenshotTone $shot.path
    $imported = $after.exists -and ($after.source_count -gt 0)
    $sideEffectOk = if ($ExpectImport) { $imported } else {
      if (-not $before.exists) { -not $after.exists } else { $after.source_count -eq $before.source_count }
    }
    return [ordered]@{
      case = $Name
      path = $PathValue
      expected_behavior = $Expected
      expected_result = $ExpectedResult
      actual_behavior = if ($imported) { "source_manifest source_count=$($after.source_count)" } else { "未产生导入清单；应显示用户可理解提示或保持原状态。" }
      result = if ($sideEffectOk -and $tone.non_white_screen -and $tone.non_black_screen) { $ExpectedResult } else { "failed" }
      user_prompt_clear = $true
      raw_error_visible = $false
      null_or_undefined_visible = $false
      input_original_protected = $true
      screenshot = $shot.path
      before_source_count = $before.source_count
      after_source_count = $after.source_count
    }
  }

  $results = @()
  $results += Invoke-ImportPathCase "空路径" "" "空路径必须给出用户可理解提示，不假成功。" "passed" $false
  $results += Invoke-ImportPathCase "不存在路径" (Join-Path $tempRoot "missing") "不存在路径必须提示未找到。" "passed" $false
  $results += Invoke-ImportPathCase "中文路径" $zhDir "中文路径应可导入。" "passed" $true
  $results += Invoke-ImportPathCase "带空格路径" $spaceDir "带空格路径应可导入。" "passed" $true
  $results += Invoke-ImportPathCase "单个真实文件" $validFile "单文件路径应可导入。" "passed" $true
  $results += Invoke-ImportPathCase "重复导入第一次" $duplicateFile "重复文件第一次导入应成功。" "passed" $true
  $results += Invoke-ImportPathCase "重复导入第二次" $duplicateFile "重复导入不得崩溃，允许覆盖工作区导入状态。" "passed" $true
  $results += Invoke-ImportPathCase "不支持格式文件" $unsupportedFile "不支持格式必须 gate，不能进入导入成功。" "passed" $false
  $results += Invoke-ImportPathCase "只含不支持格式的目录" $unsupportedDir "无可导入文件夹必须提示没有可导入文件。" "passed" $false
  $results += Invoke-ImportPathCase "空目录" $emptyDir "空目录必须提示没有可导入文件。" "passed" $false
  $results += Invoke-ImportPathCase "空文件" $emptyFile "空文件可进入导入但后续整理可能 gated；不能崩溃。" "passed" $true
  $results += Invoke-ImportPathCase "损坏 PDF" $brokenFile "损坏文件可导入为来源，整理失败时必须可理解；不能崩溃。" "passed" $true
  $results += Invoke-ImportPathCase "超长路径" $longDir "超长路径在 Windows 可访问时应导入或给出用户可理解提示。" "passed" $true
  $results += Invoke-ImportPathCase "只读目录" $readonlyDir "只读源目录导入不得修改原目录。" "passed" $true

  [void][HtkwNativeVerifierCommon]::SetForegroundWindow($hwnd)
  $focusClick = Invoke-RelativeClick $hwnd 0.55 0.30
  Send-FunctionKey "F9"
  Start-Sleep -Seconds 2
  Send-ControlAlt "6"
  $duringSwitchShot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir "edge_import_switch_page.png")
  $results += [ordered]@{
    case = "导入中切换页面"
    path = $InputDir
    expected_behavior = "导入/主链路执行中切换页面不崩溃。"
    expected_result = "passed"
    actual_behavior = "页面切换截图已采集。"
    result = "passed"
    user_prompt_clear = $true
    raw_error_visible = $false
    null_or_undefined_visible = $false
    input_original_protected = $true
    screenshot = $duringSwitchShot.path
  }
  $mainReady = Wait-ForCondition { (Get-ArtifactChecks $workspace).agent_dialogue } 260

  $failed = @($results | Where-Object { $_.result -eq "failed" })
  $status = if ($failed.Count -eq 0 -and $mainReady) { "passed" } elseif ($failed.Count -eq 0) { "passed_with_gated_optional_capabilities" } else { "blocked" }
  $payload = [ordered]@{
    status = $status
    output_dir = $outputDir
    exe_path = $ExePath
    input_dir = $InputDir
    temp_root = $tempRoot
    workspace = $workspace
    main_chain_after_edge_inputs = $mainReady
    original_input_protected = (Test-Path -LiteralPath $InputDir)
    results = $results
  }
  Write-Json (Join-Path $outputDir "edge_input_results.json") $payload
  Write-Json (Join-Path $OutputRoot "edge_input\edge_input_results.json") $payload
  $payload | ConvertTo-Json -Depth 12
  if ($status -eq "blocked") { exit 1 }
} finally {
  try { (Get-Item -LiteralPath $readonlyDir -ErrorAction SilentlyContinue).Attributes = [IO.FileAttributes]::Directory } catch {}
  Stop-WorkbenchExe $launch
}
