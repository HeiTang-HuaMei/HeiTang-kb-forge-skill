$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$TauriDir = Join-Path $Root "desktop\tauri"
$FlutterAppDir = Join-Path $Root "web\workbench\flutter_app"
$FlutterWebDist = Join-Path $FlutterAppDir "build\web"
$NsisDir = Join-Path $TauriDir "src-tauri\target\release\bundle\nsis"

function Resolve-FlutterExecutable {
    $candidates = @()

    if ($env:FLUTTER_BIN) {
        $candidates += $env:FLUTTER_BIN
    }

    if ($env:FLUTTER_ROOT) {
        $candidates += (Join-Path $env:FLUTTER_ROOT "bin\flutter.bat")
    }

    if ($env:FLUTTER_HOME) {
        $candidates += (Join-Path $env:FLUTTER_HOME "bin\flutter.bat")
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }

        if (Test-Path -LiteralPath $candidate -PathType Container) {
            $candidateBat = Join-Path $candidate "flutter.bat"
            if (Test-Path -LiteralPath $candidateBat -PathType Leaf) {
                return (Resolve-Path -LiteralPath $candidateBat).Path
            }
        }
    }

    foreach ($commandName in @("flutter", "flutter.bat", "flutter.cmd")) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }
    }

    [Console]::Error.WriteLine("Flutter executable not found. Set FLUTTER_BIN or add Flutter bin to PATH.")
    exit 1
}

$FlutterExecutable = Resolve-FlutterExecutable
Write-Host "Flutter executable: $FlutterExecutable"

$previousErrorActionPreference = $ErrorActionPreference
try {
    $ErrorActionPreference = "Continue"

    Set-Location $FlutterAppDir
    & $FlutterExecutable build web
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
