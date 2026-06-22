param(
  [string]$ExePath = "",
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($ExePath)) { $ExePath = Get-DefaultExePath }
if ([string]::IsNullOrWhiteSpace($OutputRoot)) { $OutputRoot = Get-DefaultIndustrialOutputRoot }

$outputDir = New-VerifierRunDir $OutputRoot "single_instance"
$screenshotsDir = Join-Path $outputDir "screenshots"
$first = $null
$second = $null
try {
  $first = Start-WorkbenchExe $ExePath
  $firstProcess = $first.process
  $firstHwnd = $first.hwnd
  $firstShot = Save-NativeScreenshot $firstHwnd (Join-Path $screenshotsDir "first_instance.png")
  [void][HtkwNativeVerifierCommon]::ShowWindow($firstHwnd, 6)
  Start-Sleep -Seconds 1
  $second = Start-Process -FilePath $ExePath -PassThru
  Start-Sleep -Seconds 3
  $second.Refresh()
  $firstProcess.Refresh()
  $secondExited = $second.HasExited
  $firstAlive = -not $firstProcess.HasExited
  $restored = -not [HtkwNativeVerifierCommon]::IsIconic($firstHwnd)
  $processName = [System.IO.Path]::GetFileNameWithoutExtension($ExePath)
  $runningInstances = @(Get-Process -Name $processName -ErrorAction SilentlyContinue)
  $afterShot = Save-NativeScreenshot $firstHwnd (Join-Path $screenshotsDir "after_second_launch.png")
  $status = if ($secondExited -and $firstAlive -and $restored -and $runningInstances.Count -eq 1) { "passed" } else { "failed" }
  $payload = [ordered]@{
    status = $status
    output_dir = $outputDir
    exe_path = $ExePath
    first_process_id = $firstProcess.Id
    second_process_id = $second.Id
    second_process_exited = $secondExited
    first_process_alive = $firstAlive
    first_window_restored = $restored
    running_instance_count_after_second_launch = $runningInstances.Count
    running_instance_ids_after_second_launch = @($runningInstances | ForEach-Object { $_.Id })
    only_one_instance_running = ($runningInstances.Count -eq 1)
    screenshots = @($firstShot.path, $afterShot.path)
  }
  Write-Json (Join-Path $outputDir "single_instance_result.json") $payload
  Write-Json (Join-Path $OutputRoot "single_instance\single_instance_result.json") $payload
  $payload | ConvertTo-Json -Depth 10
  if ($status -ne "passed") { exit 1 }
} finally {
  if ($second -and (Get-Process -Id $second.Id -ErrorAction SilentlyContinue)) {
    Stop-Process -Id $second.Id -Force
  }
  Stop-WorkbenchExe $first
}
