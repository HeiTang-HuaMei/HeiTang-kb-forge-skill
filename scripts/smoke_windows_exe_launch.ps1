param(
  [string]$ExePath = "",
  [string]$WorkspacePath = "",
  [int]$StartupSeconds = 8
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
if ([string]::IsNullOrWhiteSpace($ExePath)) {
  $ExePath = Join-Path $Root "web\workbench\flutter_app\build\windows\x64\runner\Release\heitang_workbench.exe"
}
if ([string]::IsNullOrWhiteSpace($WorkspacePath)) {
  $WorkspacePath = Join-Path $Root "web\workbench\flutter_app\output\stage2_exe_launch_smoke_workspace"
}

$AcceptanceDir = Join-Path $WorkspacePath "acceptance"
$LogPath = Join-Path $AcceptanceDir "exe_launch_smoke.log"
$ReportPath = Join-Path $AcceptanceDir "exe_launch_smoke_report.json"
New-Item -ItemType Directory -Force -Path $AcceptanceDir | Out-Null

$started = $false
$crashed = $false
$startupTimeout = $false
$exitCode = $null
$processId = 0
$errorMessage = ""
$resolvedExePath = ""
$exeSizeBytes = 0
$exeSha256 = ""
$exeHeader = ""

try {
  if (-not (Test-Path -LiteralPath $ExePath)) {
    throw "EXE not found: $ExePath"
  }
  $resolvedExePath = (Resolve-Path -LiteralPath $ExePath).Path
  $exeItem = Get-Item -LiteralPath $resolvedExePath
  $exeSizeBytes = $exeItem.Length
  $exeSha256 = (Get-FileHash -LiteralPath $resolvedExePath -Algorithm SHA256).Hash.ToLowerInvariant()
  $headerBytes = [System.IO.File]::ReadAllBytes($resolvedExePath)
  if ($headerBytes.Length -ge 2) {
    $exeHeader = [System.Text.Encoding]::ASCII.GetString($headerBytes, 0, 2)
  }

  "Starting EXE: $ExePath" | Set-Content -LiteralPath $LogPath -Encoding UTF8
  $process = Start-Process -FilePath $ExePath -PassThru -WindowStyle Hidden
  $started = $true
  $processId = $process.Id
  Start-Sleep -Seconds $StartupSeconds
  $process.Refresh()
  if ($process.HasExited) {
    $exitCode = $process.ExitCode
    $crashed = $exitCode -ne 0
  } else {
    Stop-Process -Id $process.Id -Force
    "Stopped smoke process after startup window." | Add-Content -LiteralPath $LogPath -Encoding UTF8
  }
} catch {
  $errorMessage = $_.Exception.Message
  $crashed = $true
  $errorMessage | Add-Content -LiteralPath $LogPath -Encoding UTF8
}

$status = if ($started -and -not $crashed -and -not $startupTimeout -and (Test-Path -LiteralPath $LogPath)) { "passed" } else { "failed" }
$report = [ordered]@{
  schema_version = "prd_v3_exe_launch_smoke_report.v1"
  status = $status
  platform = "windows"
  generated_by = "scripts/smoke_windows_exe_launch.ps1"
  exe_path = $resolvedExePath
  exe_size_bytes = $exeSizeBytes
  exe_sha256 = $exeSha256
  exe_header = $exeHeader
  workspace_path = (Resolve-Path -LiteralPath $WorkspacePath).Path
  log_path = (Resolve-Path -LiteralPath $LogPath).Path
  launched = $started
  process_started = $started
  process_id = $processId
  exit_code = $exitCode
  crashed = $crashed
  startup_timeout = $startupTimeout
  startup_seconds = $StartupSeconds
  error_message = $errorMessage
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
  secret_plaintext_written = $false
}
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ReportPath -Encoding UTF8
Write-Host "EXE launch smoke report: $ReportPath"
if ($status -ne "passed") {
  exit 1
}
