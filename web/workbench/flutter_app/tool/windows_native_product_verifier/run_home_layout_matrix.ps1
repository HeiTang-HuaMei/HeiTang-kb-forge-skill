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
  $OutputRoot = Join-Path (Get-AppRoot) "output\ui_responsive_layout_repair"
}

$outputDir = New-VerifierRunDir $OutputRoot "home_layout"
$screenshotsDir = Join-Path $outputDir "screenshots"
$regionsDir = Join-Path $outputDir "regions"
New-Item -ItemType Directory -Force -Path $regionsDir | Out-Null
$workspace = Get-WorkspacePath
$launch = $null
try {
  $launch = Start-WorkbenchExe $ExePath
  $hwnd = $launch.hwnd
  $sizes = @(
    @{ name = "1440x900"; width = 1440; height = 900 },
    @{ name = "1920x1080"; width = 1920; height = 1080 },
    @{ name = "2560x1440"; width = 2560; height = 1440 }
  )
  $results = @()
  $regions = @()
  foreach ($size in $sizes) {
    Set-NativeWindowSize $hwnd $size.width $size.height
    [System.Windows.Forms.SendKeys]::SendWait("^%1")
    Start-Sleep -Milliseconds 700
    $shot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir ("home_{0}.png" -f $size.name))
    $tone = Test-ScreenshotTone $shot.path
    $results += [ordered]@{
      viewport = $size.name
      expected = "首页响应式铺开，CTA、Hero 三阶段图形、底部默认隔离提示可见且页面非白屏/黑屏。"
      result = if ($tone.non_white_screen -and $tone.non_black_screen) { "passed" } else { "failed" }
      screenshot = $shot.path
      tone = $tone
      responsive_width = ("captured_{0}" -f $size.name)
      cta_not_clipped = "visual_region_required"
      isolation_notice_not_clipped = "visual_region_required"
      hero_three_stage_colors = "visual_region_required"
    }
  }
  [void][HtkwNativeVerifierCommon]::ShowWindow($hwnd, 3)
  Start-Sleep -Milliseconds 900
  [System.Windows.Forms.SendKeys]::SendWait("^%1")
  Start-Sleep -Milliseconds 700
  $wideShot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir "home_maximized_wide.png")
  $wideTone = Test-ScreenshotTone $wideShot.path
  $results += [ordered]@{
    viewport = "maximized_wide"
    expected = "最大化宽屏首页响应式扩展，内容不再锁在小画布。"
    result = if ($wideTone.non_white_screen -and $wideTone.non_black_screen) { "passed" } else { "failed" }
    screenshot = $wideShot.path
    tone = $wideTone
    responsive_width = "captured_maximized"
    cta_not_clipped = "visual_region_required"
    isolation_notice_not_clipped = "visual_region_required"
    hero_three_stage_colors = "visual_region_required"
  }
  $regionSpecs = @(
    @{ name = "cta_organize_and_flow"; rx = 0.18; ry = 0.19; rw = 0.30; rh = 0.10; expected = "CTA 局部：整理资料/查看流程按钮文字和图标完整显示。" },
    @{ name = "hero_knowledge_asset_glyph"; rx = 0.66; ry = 0.12; rw = 0.30; rh = 0.19; expected = "Hero 右侧：资料 -> 知识库 -> 成果三阶段图形，三阶段颜色不同。" },
    @{ name = "isolation_notice"; rx = 0.17; ry = 0.89; rw = 0.80; rh = 0.08; expected = "默认隔离提示条局部：文字不被固定高度裁切。" }
  )
  foreach ($spec in $regionSpecs) {
    $region = Save-ScreenshotRegion $wideShot.path (Join-Path $regionsDir ("{0}.png" -f $spec.name)) $spec.rx $spec.ry $spec.rw $spec.rh
    $tone = Test-ScreenshotTone $region.path
    $regions += [ordered]@{
      name = $spec.name
      expected = $spec.expected
      result = if ($tone.non_white_screen -and $tone.non_black_screen -and $region.size_bytes -gt 800) { "passed" } else { "failed" }
      screenshot = $region.path
      tone = $tone
      width = $region.width
      height = $region.height
      source = $wideShot.path
    }
  }
  $failed = @($results | Where-Object { $_.result -eq "failed" })
  $failedRegions = @($regions | Where-Object { $_.result -eq "failed" })
  $payload = [ordered]@{
    status = if ($failed.Count -eq 0 -and $failedRegions.Count -eq 0) { "passed" } else { "blocked" }
    output_dir = $outputDir
    exe_path = $ExePath
    input_dir = $InputDir
    workspace = $workspace
    results = $results
    regions = $regions
    screenshots = @{
      home_1440x900 = ($results | Where-Object { $_.viewport -eq "1440x900" } | Select-Object -First 1).screenshot
      home_1920x1080 = ($results | Where-Object { $_.viewport -eq "1920x1080" } | Select-Object -First 1).screenshot
      home_maximized_wide = $wideShot.path
      cta_region = ($regions | Where-Object { $_.name -eq "cta_organize_and_flow" } | Select-Object -First 1).screenshot
      isolation_notice_region = ($regions | Where-Object { $_.name -eq "isolation_notice" } | Select-Object -First 1).screenshot
      hero_glyph_region = ($regions | Where-Object { $_.name -eq "hero_knowledge_asset_glyph" } | Select-Object -First 1).screenshot
    }
  }
  Write-Json (Join-Path $outputDir "home_layout_results.json") $payload
  Write-Json (Join-Path $OutputRoot "home_layout_results.json") $payload
  Write-Json (Join-Path $OutputRoot "responsive_results.json") $payload
  $payload | ConvertTo-Json -Depth 10
  if ($payload.status -ne "passed") { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
