$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$TauriDir = Join-Path $Root "desktop\tauri"
$NsisDir = Join-Path $TauriDir "src-tauri\target\release\bundle\nsis"

Set-Location $TauriDir

$previousErrorActionPreference = $ErrorActionPreference
try {
    $ErrorActionPreference = "Continue"
    npm.cmd run tauri:build
    $buildExitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
}
finally {
    $ErrorActionPreference = $previousErrorActionPreference
}

Write-Host "tauri:build exit code: $buildExitCode"

if ($buildExitCode -ne 0) {
    exit $buildExitCode
}

$artifacts = Get-ChildItem -Path $NsisDir -Filter "*setup.exe" -File -ErrorAction SilentlyContinue
if (-not $artifacts) {
    Write-Error "tauri:build exited 0, but no NSIS setup artifact was found in $NsisDir"
    exit 1
}

exit 0
