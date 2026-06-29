$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$TauriDir = Join-Path $Root "desktop\tauri"
$FlutterAppDir = Join-Path $Root "web\workbench\flutter_app"
$FlutterWebDist = Join-Path $FlutterAppDir "build\web"
$NsisDir = Join-Path $TauriDir "src-tauri\target\release\bundle\nsis"

$previousErrorActionPreference = $ErrorActionPreference
try {
    $ErrorActionPreference = "Continue"

    Set-Location $FlutterAppDir
    flutter.cmd build web
    $flutterBuildExitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    Write-Host "flutter build web exit code: $flutterBuildExitCode"

    if ($flutterBuildExitCode -ne 0) {
        exit $flutterBuildExitCode
    }

    if (-not (Test-Path (Join-Path $FlutterWebDist "index.html"))) {
        Write-Error "flutter build web exited 0, but no index.html was found in $FlutterWebDist"
        exit 1
    }

    Set-Location $TauriDir
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
