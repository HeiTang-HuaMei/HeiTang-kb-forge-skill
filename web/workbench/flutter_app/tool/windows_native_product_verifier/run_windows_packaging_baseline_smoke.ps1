param(
  [string]$ExePath = "",
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($ExePath)) {
  $ExePath = Get-DefaultExePath
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\windows_packaging_baseline_smoke"
}

function Test-BundledServiceExecutables([string]$ReleaseRoot) {
  $forbiddenNames = @(
    "redis-server.exe",
    "redis.exe",
    "qdrant.exe",
    "milvus.exe",
    "minio.exe",
    "vectordb.exe"
  )
  $matches = @()
  if (Test-Path -LiteralPath $ReleaseRoot) {
    $files = Get-ChildItem -LiteralPath $ReleaseRoot -Recurse -File -ErrorAction SilentlyContinue
    foreach ($file in $files) {
      if ($forbiddenNames -contains $file.Name.ToLowerInvariant()) {
        $matches += $file.FullName
      }
    }
  }
  return [ordered]@{
    release_root = $ReleaseRoot
    forbidden_matches = @($matches)
    passed = ($matches.Count -eq 0)
  }
}

$outputDir = New-VerifierRunDir $OutputRoot "windows_packaging_baseline_smoke"
$screenshotsDir = Join-Path $outputDir "screenshots"
$workspace = Get-WorkspacePath
$workspaceProbeRoot = Join-Path $workspace "packaging_baseline_probe"
$configProbeRoot = Join-Path $workspace "config\packaging_baseline_probe"
$releaseRoot = Split-Path -Parent $ExePath
$launch = $null
$restartLaunch = $null

Clear-WorkbenchWorkspace

try {
  $launch = Start-WorkbenchExe $ExePath
  $hwnd = $launch.hwnd
  Start-Sleep -Seconds 5
  $launch.process.Refresh()

  $initialShot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir "launch_initial.png")
  $launchTone = Test-ScreenshotTone $initialShot.path
  $launchResult = [ordered]@{
    exe_path = $ExePath
    exe_exists = (Test-Path -LiteralPath $ExePath)
    launched = (-not $launch.process.HasExited)
    alive_after_5_seconds = (-not $launch.process.HasExited)
    main_window_handle = [string]$hwnd
    main_window_title = $launch.title
    window_title_contains_expected = ($launch.title -like "*HeiTang Workbench*")
    screenshot = $initialShot
    non_white_screen = $launchTone.non_white_screen
    non_black_screen = $launchTone.non_black_screen
    status = if ((Test-Path -LiteralPath $ExePath) -and (-not $launch.process.HasExited) -and ($launch.title -like "*HeiTang Workbench*") -and $launchTone.non_white_screen -and $launchTone.non_black_screen) { "passed" } else { "failed" }
  }
  Write-Json (Join-Path $outputDir "exe_launch_result.json") $launchResult

  [void][HtkwNativeVerifierCommon]::ShowWindow($hwnd, 3)
  Start-Sleep -Seconds 1
  $maximizeShot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir "window_maximize.png")
  [void][HtkwNativeVerifierCommon]::ShowWindow($hwnd, 9)
  Start-Sleep -Seconds 1
  $restoreShot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir "window_restore.png")
  [void][HtkwNativeVerifierCommon]::ShowWindow($hwnd, 6)
  Start-Sleep -Seconds 1
  [void][HtkwNativeVerifierCommon]::ShowWindow($hwnd, 9)
  Start-Sleep -Seconds 1
  $restoreAfterMinimizeShot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir "window_restore_after_minimize.png")

  $windowOps = @(
    [ordered]@{
      operation = "maximize"
      alive = (-not $launch.process.HasExited)
      is_minimized = [HtkwNativeVerifierCommon]::IsIconic($hwnd)
      screenshot = $maximizeShot
      status = if ((-not $launch.process.HasExited) -and $maximizeShot.size_bytes -gt 1000) { "passed" } else { "failed" }
    },
    [ordered]@{
      operation = "restore"
      alive = (-not $launch.process.HasExited)
      is_minimized = [HtkwNativeVerifierCommon]::IsIconic($hwnd)
      screenshot = $restoreShot
      status = if ((-not $launch.process.HasExited) -and $restoreShot.size_bytes -gt 1000) { "passed" } else { "failed" }
    },
    [ordered]@{
      operation = "restore_after_minimize"
      alive = (-not $launch.process.HasExited)
      is_minimized = [HtkwNativeVerifierCommon]::IsIconic($hwnd)
      screenshot = $restoreAfterMinimizeShot
      status = if ((-not $launch.process.HasExited) -and $restoreAfterMinimizeShot.size_bytes -gt 1000) { "passed" } else { "failed" }
    }
  )
  Write-Json (Join-Path $outputDir "window_probe_result.json") ([ordered]@{
    status = if (($windowOps | Where-Object { $_.status -ne "passed" }).Count -eq 0) { "passed" } else { "failed" }
    operations = $windowOps
  })

  $workspaceWritable = $false
  $configWritable = $false
  $workspaceProbePath = Join-Path $workspaceProbeRoot "workspace_probe.json"
  $configProbePath = Join-Path $configProbeRoot "config_probe.json"
  New-Item -ItemType Directory -Force -Path $workspaceProbeRoot, $configProbeRoot | Out-Null
  Write-Json $workspaceProbePath ([ordered]@{
    gate = "P2-9 Windows Packaging Baseline Smoke"
    probe = "workspace_write"
    workspace = $workspace
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
  })
  Write-Json $configProbePath ([ordered]@{
    gate = "P2-9 Windows Packaging Baseline Smoke"
    probe = "config_write"
    config_root = (Join-Path $workspace "config")
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
  })
  $workspaceWritable = [bool](Read-JsonFile $workspaceProbePath)
  $configWritable = [bool](Read-JsonFile $configProbePath)

  Stop-WorkbenchExe $launch
  $launch = $null

  $restartLaunch = Start-WorkbenchExe $ExePath
  $restartHwnd = $restartLaunch.hwnd
  Start-Sleep -Seconds 2
  $restartShot = Save-NativeScreenshot $restartHwnd (Join-Path $screenshotsDir "window_after_restart.png")
  $workspaceProbeAfterRestart = Read-JsonFile $workspaceProbePath
  $configProbeAfterRestart = Read-JsonFile $configProbePath
  $restartResult = [ordered]@{
    restart_launched = (-not $restartLaunch.process.HasExited)
    workspace_probe_persisted = [bool]$workspaceProbeAfterRestart
    config_probe_persisted = [bool]$configProbeAfterRestart
    screenshot = $restartShot
    status = if ((-not $restartLaunch.process.HasExited) -and $workspaceProbeAfterRestart -and $configProbeAfterRestart -and $restartShot.size_bytes -gt 1000) { "passed" } else { "failed" }
  }
  Write-Json (Join-Path $outputDir "restart_probe_result.json") $restartResult

  $connectorBoundary = Test-BundledServiceExecutables $releaseRoot
  Write-Json (Join-Path $outputDir "connector_boundary_result.json") $connectorBoundary

  $cleanupErrors = @()
  foreach ($path in @($workspaceProbeRoot, $configProbeRoot)) {
    if (Test-Path -LiteralPath $path) {
      try {
        Remove-Item -LiteralPath $path -Recurse -Force
      } catch {
        $cleanupErrors += $_.Exception.Message
      }
    }
  }

  $windowStatus = if (($windowOps | Where-Object { $_.status -ne "passed" }).Count -eq 0) { "passed" } else { "failed" }
  $launchStatus = $launchResult.status
  $workspaceStatus = if ($workspaceWritable) { "passed" } else { "failed" }
  $configStatus = if ($configWritable) { "passed" } else { "failed" }
  $restartStatus = $restartResult.status
  $connectorStatus = if ($connectorBoundary.passed) { "passed" } else { "failed" }
  $cleanupStatus = if ($cleanupErrors.Count -eq 0) { "passed" } else { "failed" }
  $finalStatus = if ($launchStatus -eq "passed" -and $windowStatus -eq "passed" -and $workspaceStatus -eq "passed" -and $configStatus -eq "passed" -and $restartStatus -eq "passed" -and $connectorStatus -eq "passed" -and $cleanupStatus -eq "passed") {
    "windows_packaging_baseline_smoke_passed"
  } else {
    "windows_packaging_baseline_smoke_product_bug_found"
  }

  $result = [ordered]@{
    final_status = $finalStatus
    allowed_next_gate = if ($finalStatus -eq "windows_packaging_baseline_smoke_passed") { "P2-10 Role-based Workgroup" } else { "product_smoke_bugfix_gate" }
    automation_path = "windows_native_product_verifier"
    output_dir = $outputDir
    exe_path = $ExePath
    workspace = $workspace
    launch_status = $launchStatus
    window_status = $windowStatus
    workspace_status = $workspaceStatus
    config_status = $configStatus
    restart_status = $restartStatus
    connector_boundary_status = $connectorStatus
    cleanup_status = $cleanupStatus
    product_bug_confirmed = ($finalStatus -ne "windows_packaging_baseline_smoke_passed")
    product_bug_summary = if ($finalStatus -eq "windows_packaging_baseline_smoke_passed") {
      "Windows packaging baseline smoke passed with writable workspace/config probes, restart verification, and no bundled connector services."
    } else {
      "Packaging baseline smoke found a product bug or boundary failure."
    }
    workspace_probe_path = $workspaceProbePath
    config_probe_path = $configProbePath
    release_root = $releaseRoot
    forbidden_bundle_matches = @($connectorBoundary.forbidden_matches)
    cleanup_errors = @($cleanupErrors)
  }
  Write-Json (Join-Path $outputDir "windows_native_product_verifier_result.json") $result
  Write-Json (Join-Path $outputDir "windows_packaging_baseline_smoke_results.json") $result
  $result | ConvertTo-Json -Depth 8
  if ($finalStatus -ne "windows_packaging_baseline_smoke_passed") { exit 1 }
} finally {
  if ($restartLaunch -and (Get-Process -Id $restartLaunch.process.Id -ErrorAction SilentlyContinue)) {
    Stop-WorkbenchExe $restartLaunch
  }
  if ($launch) {
    Stop-WorkbenchExe $launch
  }
}
