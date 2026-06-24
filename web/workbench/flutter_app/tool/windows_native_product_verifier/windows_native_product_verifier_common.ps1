$ErrorActionPreference = "Stop"

function Get-AppRoot {
  return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Get-DefaultExePath {
  return (Join-Path (Get-AppRoot) "build\windows\x64\runner\Release\heitang_workbench.exe")
}

function Get-DefaultIndustrialOutputRoot {
  return (Join-Path (Get-AppRoot) "output\industrial_acceptance")
}

function Get-DefaultSmokeOutputRoot {
  return (Join-Path (Get-AppRoot) "output\windows_exe_smoke")
}

function Get-WorkspacePath {
  $localAppData = [Environment]::GetEnvironmentVariable("LOCALAPPDATA")
  if ($localAppData) {
    return Join-Path $localAppData "HeiTangKBForge\rc10_product_flow_workspace"
  }
  return Join-Path (Get-Location).Path "output\rc10_product_flow_workspace"
}

function Assert-SafeWorkspacePath([string]$Workspace) {
  $localAppData = [Environment]::GetEnvironmentVariable("LOCALAPPDATA")
  if (-not $localAppData) { throw "LOCALAPPDATA is unavailable." }
  $expectedRoot = [System.IO.Path]::GetFullPath((Join-Path $localAppData "HeiTangKBForge"))
  $resolvedWorkspace = [System.IO.Path]::GetFullPath($Workspace)
  if (-not $resolvedWorkspace.StartsWith($expectedRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
      ([System.IO.Path]::GetFileName($resolvedWorkspace) -ne "rc10_product_flow_workspace")) {
    throw "Refusing to operate on unexpected workspace path: $resolvedWorkspace"
  }
}

function Clear-WorkbenchWorkspace {
  $workspace = Get-WorkspacePath
  if (Test-Path -LiteralPath $workspace) {
    Assert-SafeWorkspacePath $workspace
    Remove-Item -LiteralPath $workspace -Recurse -Force
  }
}

function Write-Json($Path, $Value) {
  $parent = Split-Path -Parent $Path
  if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  $Value | ConvertTo-Json -Depth 20 | Set-Content -Encoding UTF8 -Path $Path
}

function Read-JsonFile([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  try {
    return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
  } catch {
    return $null
  }
}

function Read-JsonlFile([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return @() }
  $rows = @()
  foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
    if ($line.Trim().Length -eq 0) { continue }
    try { $rows += ($line | ConvertFrom-Json) } catch {}
  }
  return $rows
}

function New-VerifierRunDir([string]$OutputRoot, [string]$ModuleName) {
  $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $root = Join-Path $OutputRoot $ModuleName
  $dir = Join-Path $root "${ModuleName}_$timestamp"
  New-Item -ItemType Directory -Force -Path $dir, (Join-Path $dir "screenshots"), (Join-Path $dir "logs") | Out-Null
  return $dir
}

function Initialize-NativeVerifierTypes {
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing
  if (-not ("HtkwNativeVerifierCommon" -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class HtkwNativeVerifierCommon {
  public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, int dwData, UIntPtr dwExtraInfo);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
}
"@
  }
}

function Activate-NativeWindow($Hwnd) {
  if (-not $Hwnd -or $Hwnd -eq 0) { return }
  $hwndTopmost = [IntPtr]::new(-1)
  $hwndNotTopmost = [IntPtr]::new(-2)
  $noMoveNoSize = 0x0001 -bor 0x0002 -bor 0x0040
  [void][HtkwNativeVerifierCommon]::ShowWindow($Hwnd, 9)
  [void][HtkwNativeVerifierCommon]::SetWindowPos($Hwnd, $hwndTopmost, 0, 0, 0, 0, $noMoveNoSize)
  Start-Sleep -Milliseconds 120
  [void][HtkwNativeVerifierCommon]::SetForegroundWindow($Hwnd)
  Start-Sleep -Milliseconds 120
  [void][HtkwNativeVerifierCommon]::SetWindowPos($Hwnd, $hwndNotTopmost, 0, 0, 0, 0, $noMoveNoSize)
  Start-Sleep -Milliseconds 180
}

function Set-NativeWindowSize($Hwnd, [int]$Width, [int]$Height) {
  if (-not $Hwnd -or $Hwnd -eq 0) { return }
  Activate-NativeWindow $Hwnd
  $noMoveNoZOrderShow = 0x0002 -bor 0x0004 -bor 0x0040
  [void][HtkwNativeVerifierCommon]::SetWindowPos($Hwnd, [IntPtr]::Zero, 0, 0, $Width, $Height, $noMoveNoZOrderShow)
  Start-Sleep -Milliseconds 700
}

function Resolve-WorkbenchMainWindowHandle($Process) {
  if ($null -eq $Process) { return [IntPtr]::Zero }
  $candidates = New-Object System.Collections.Generic.List[object]
  $callback = [HtkwNativeVerifierCommon+EnumWindowsProc]{
    param([IntPtr]$hWnd, [IntPtr]$lParam)
    $windowProcessId = 0
    [void][HtkwNativeVerifierCommon]::GetWindowThreadProcessId($hWnd, [ref]$windowProcessId)
    if ($windowProcessId -eq $Process.Id -and [HtkwNativeVerifierCommon]::IsWindowVisible($hWnd)) {
      $rect = Get-NativeRect $hWnd
      $width = $rect.Right - $rect.Left
      $height = $rect.Bottom - $rect.Top
      if ($width -gt 500 -and $height -gt 300) {
        $candidates.Add([ordered]@{ hwnd = $hWnd; width = $width; height = $height; area = $width * $height }) | Out-Null
      }
    }
    return $true
  }
  [void][HtkwNativeVerifierCommon]::EnumWindows($callback, [IntPtr]::Zero)
  if ($candidates.Count -gt 0) {
    return ($candidates | Sort-Object area -Descending | Select-Object -First 1).hwnd
  }
  return $Process.MainWindowHandle
}

function Wait-WorkbenchMainWindowHandle($Process, [int]$TimeoutSeconds = 30) {
  if ($null -eq $Process) { return [IntPtr]::Zero }
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $Process.Refresh()
    if ($Process.HasExited) { return [IntPtr]::Zero }
    $hwnd = Resolve-WorkbenchMainWindowHandle $Process
    if ($hwnd -and $hwnd -ne 0) { return $hwnd }
    Start-Sleep -Milliseconds 500
  }
  $Process.Refresh()
  return Resolve-WorkbenchMainWindowHandle $Process
}

function Get-NativeRect($Hwnd) {
  $rect = New-Object HtkwNativeVerifierCommon+RECT
  [void][HtkwNativeVerifierCommon]::GetWindowRect($Hwnd, [ref]$rect)
  return $rect
}

function Save-NativeScreenshot($Hwnd, [string]$Path) {
  Activate-NativeWindow $Hwnd
  $rect = Get-NativeRect $Hwnd
  $width = [Math]::Max(1, $rect.Right - $rect.Left)
  $height = [Math]::Max(1, $rect.Bottom - $rect.Top)
  $bitmap = New-Object System.Drawing.Bitmap $width, $height
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, [System.Drawing.Size]::new($width, $height))
  $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  $graphics.Dispose()
  $bitmap.Dispose()
  $file = Get-Item -LiteralPath $Path
  return [ordered]@{ path = $Path; width = $width; height = $height; size_bytes = $file.Length }
}

function Test-ScreenshotTone([string]$Path) {
  $bitmap = [System.Drawing.Bitmap]::FromFile($Path)
  try {
    $sampleCount = 0
    $whiteLike = 0
    $blackLike = 0
    $stepX = [Math]::Max(1, [int]($bitmap.Width / 20))
    $stepY = [Math]::Max(1, [int]($bitmap.Height / 20))
    for ($x = 0; $x -lt $bitmap.Width; $x += $stepX) {
      for ($y = 0; $y -lt $bitmap.Height; $y += $stepY) {
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

function Compare-ScreenshotDifference([string]$LeftPath, [string]$RightPath) {
  $left = [System.Drawing.Bitmap]::FromFile($LeftPath)
  $right = [System.Drawing.Bitmap]::FromFile($RightPath)
  try {
    $width = [Math]::Min($left.Width, $right.Width)
    $height = [Math]::Min($left.Height, $right.Height)
    $sampleCount = 0
    $changed = 0
    $stepX = [Math]::Max(1, [int]($width / 36))
    $stepY = [Math]::Max(1, [int]($height / 24))
    for ($x = 0; $x -lt $width; $x += $stepX) {
      for ($y = 0; $y -lt $height; $y += $stepY) {
        $lp = $left.GetPixel($x, $y)
        $rp = $right.GetPixel($x, $y)
        $delta = [Math]::Abs($lp.R - $rp.R) + [Math]::Abs($lp.G - $rp.G) + [Math]::Abs($lp.B - $rp.B)
        $sampleCount += 1
        if ($delta -gt 35) { $changed += 1 }
      }
    }
    return [ordered]@{
      sample_count = $sampleCount
      changed_count = $changed
      changed_ratio = if ($sampleCount) { $changed / $sampleCount } else { 0 }
      changed = if ($sampleCount) { ($changed / $sampleCount) -gt 0.015 } else { $false }
    }
  } finally {
    $left.Dispose()
    $right.Dispose()
  }
}

function Save-ScreenshotRegion(
  [string]$SourcePath,
  [string]$TargetPath,
  [double]$Rx,
  [double]$Ry,
  [double]$Rw,
  [double]$Rh
) {
  $source = [System.Drawing.Bitmap]::FromFile($SourcePath)
  try {
    $x = [Math]::Max(0, [int]($source.Width * $Rx))
    $y = [Math]::Max(0, [int]($source.Height * $Ry))
    $w = [Math]::Min($source.Width - $x, [Math]::Max(1, [int]($source.Width * $Rw)))
    $h = [Math]::Min($source.Height - $y, [Math]::Max(1, [int]($source.Height * $Rh)))
    $target = New-Object System.Drawing.Bitmap $w, $h
    $graphics = [System.Drawing.Graphics]::FromImage($target)
    try {
      $graphics.DrawImage(
        $source,
        [System.Drawing.Rectangle]::new(0, 0, $w, $h),
        [System.Drawing.Rectangle]::new($x, $y, $w, $h),
        [System.Drawing.GraphicsUnit]::Pixel
      )
      $parent = Split-Path -Parent $TargetPath
      if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
      $target.Save($TargetPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
      $graphics.Dispose()
      $target.Dispose()
    }
    $file = Get-Item -LiteralPath $TargetPath
    return [ordered]@{
      path = $TargetPath
      width = $w
      height = $h
      size_bytes = $file.Length
      source_path = $SourcePath
      source_width = $source.Width
      source_height = $source.Height
      rect = [ordered]@{ rx = $Rx; ry = $Ry; rw = $Rw; rh = $Rh; x = $x; y = $y; width = $w; height = $h }
    }
  } finally {
    $source.Dispose()
  }
}

function Invoke-RelativeClick($Hwnd, [double]$Rx, [double]$Ry) {
  Activate-NativeWindow $Hwnd
  $rect = Get-NativeRect $Hwnd
  $x = [int]($rect.Left + (($rect.Right - $rect.Left) * $Rx))
  $y = [int]($rect.Top + (($rect.Bottom - $rect.Top) * $Ry))
  [void][HtkwNativeVerifierCommon]::SetCursorPos($x, $y)
  Start-Sleep -Milliseconds 100
  [HtkwNativeVerifierCommon]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 80
  [HtkwNativeVerifierCommon]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
  return [ordered]@{ x = $x; y = $y; rx = $Rx; ry = $Ry }
}

function Invoke-RelativeWheel($Hwnd, [double]$Rx, [double]$Ry, [int]$Clicks) {
  Activate-NativeWindow $Hwnd
  $rect = Get-NativeRect $Hwnd
  $x = [int]($rect.Left + (($rect.Right - $rect.Left) * $Rx))
  $y = [int]($rect.Top + (($rect.Bottom - $rect.Top) * $Ry))
  [void][HtkwNativeVerifierCommon]::SetCursorPos($x, $y)
  Start-Sleep -Milliseconds 100
  [HtkwNativeVerifierCommon]::mouse_event(0x0800, 0, 0, ($Clicks * 120), [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 500
  return [ordered]@{ x = $x; y = $y; rx = $Rx; ry = $Ry; clicks = $Clicks }
}

function Send-ControlAlt([string]$Key) {
  [System.Windows.Forms.SendKeys]::SendWait("^%$Key")
  Start-Sleep -Milliseconds 700
}

function Send-FunctionKey([string]$Key) {
  [System.Windows.Forms.SendKeys]::SendWait("{$Key}")
  Start-Sleep -Milliseconds 700
}

function Send-Escape {
  [System.Windows.Forms.SendKeys]::SendWait("{ESC}")
  Start-Sleep -Milliseconds 500
}

function Send-Enter {
  [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
  Start-Sleep -Milliseconds 500
}

function Set-VerifierClipboardText([string]$Text) {
  if ($null -eq $Text) { $Text = "" }
  if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
    if ($Text.Length -eq 0) {
      Set-Clipboard -Value " "
    } else {
      Set-Clipboard -Value $Text
    }
  } else {
    [System.Windows.Forms.Clipboard]::SetText($(if ($Text.Length -eq 0) { " " } else { $Text }))
  }
  Start-Sleep -Milliseconds 200
}

function Invoke-MainChainShortcut($Hwnd, [string]$Workspace, [int]$TimeoutSeconds = 300) {
  [void][HtkwNativeVerifierCommon]::SetForegroundWindow($Hwnd)
  Start-Sleep -Seconds 2
  $focusClick = Invoke-RelativeClick $Hwnd 0.55 0.30
  Send-FunctionKey "F9"
  $ready = Wait-ForCondition { (Get-ArtifactChecks $Workspace).agent_dialogue } $TimeoutSeconds
  if (-not $ready) {
    [void][HtkwNativeVerifierCommon]::SetForegroundWindow($Hwnd)
    $focusClick = Invoke-RelativeClick $Hwnd 0.55 0.30
    Send-ControlAlt "R"
    $ready = Wait-ForCondition { (Get-ArtifactChecks $Workspace).agent_dialogue } 120
  }
  return $ready
}

function Start-WorkbenchExe([string]$ExePath) {
  Initialize-NativeVerifierTypes
  if (-not (Test-Path -LiteralPath $ExePath)) { throw "EXE not found: $ExePath" }
  $process = Start-Process -FilePath $ExePath -PassThru
  $hwnd = Wait-WorkbenchMainWindowHandle $process 45
  if ($process.HasExited -or $hwnd -eq 0) {
    throw "EXE launch failed or MainWindowHandle is 0."
  }
  Activate-NativeWindow $hwnd
  Start-Sleep -Seconds 1
  return [ordered]@{ process = $process; hwnd = $hwnd; title = $process.MainWindowTitle }
}

function Start-WorkbenchExeWithEnv([string]$ExePath, [hashtable]$Environment) {
  Initialize-NativeVerifierTypes
  if (-not (Test-Path -LiteralPath $ExePath)) { throw "EXE not found: $ExePath" }
  $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = $ExePath
  $startInfo.UseShellExecute = $false
  foreach ($key in $Environment.Keys) {
    $startInfo.Environment[$key] = [string]$Environment[$key]
  }
  $process = [System.Diagnostics.Process]::Start($startInfo)
  $hwnd = Wait-WorkbenchMainWindowHandle $process 45
  if ($process.HasExited -or $hwnd -eq 0) {
    throw "EXE launch failed or MainWindowHandle is 0."
  }
  Activate-NativeWindow $hwnd
  Start-Sleep -Seconds 1
  return [ordered]@{ process = $process; hwnd = $hwnd; title = $process.MainWindowTitle }
}

function Start-WorkbenchExeForMainChain([string]$ExePath) {
  return Start-WorkbenchExeWithEnv $ExePath @{ HEITANG_RC10_OWNER_INPUT_E2E = "1" }
}

function Stop-WorkbenchExe($Launch) {
  if ($null -eq $Launch) { return }
  $process = $Launch.process
  $hwnd = $Launch.hwnd
  if ($hwnd -and $hwnd -ne 0) {
    [void][HtkwNativeVerifierCommon]::PostMessage($hwnd, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)
    Start-Sleep -Seconds 2
  }
  if ($process -and (Get-Process -Id $process.Id -ErrorAction SilentlyContinue)) {
    Stop-Process -Id $process.Id -Force
  }
}

function Wait-ForPath([string]$Path, [int]$TimeoutSeconds = 60) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    if (Test-Path -LiteralPath $Path) { return $true }
    Start-Sleep -Milliseconds 500
  }
  return $false
}

function Wait-ForCondition([scriptblock]$Condition, [int]$TimeoutSeconds = 60) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    if (& $Condition) { return $true }
    Start-Sleep -Milliseconds 500
  }
  return $false
}

function Test-AnyPath($Base, [string[]]$RelativePaths) {
  foreach ($relative in $RelativePaths) {
    if (Test-Path -LiteralPath (Join-Path $Base $relative)) { return $true }
  }
  return $false
}

function Get-ArtifactChecks([string]$Workspace) {
  return [ordered]@{
    workspace = $Workspace
    workspace_exists = (Test-Path -LiteralPath $Workspace)
    source_manifest = (Test-Path -LiteralPath (Join-Path $Workspace "source_manifest.json"))
    import_report = (Test-AnyPath $Workspace @("import\source_inventory.json", "import\batch_import_report.json", "import\ingest_report.md"))
    parse_report = (Test-AnyPath $Workspace @("parse_report.json", "du\document_understanding_manifest.json", "du\document_understanding_report.json", "du\run_manifest.json"))
    knowledge_base = (Test-AnyPath $Workspace @("kb\manifest.json", "kb\knowledge_base_build_report.json", "knowledge_base\manifest.json", "knowledge_bases\kb_catalog.json"))
    retrieval = (Test-AnyPath $Workspace @("query\kb_query_result.json", "query\multi_kb_query_result.json", "query\validation_report.json", "query\validation_report.md"))
    markdown = (Test-AnyPath $Workspace @("doc\generated.md", "doc\reading_notes.md", "document_generation\reading_notes.md"))
    markdown_export = (Test-AnyPath $Workspace @("export\reading_notes_export.md", "export\export_manifest.json", "export\structured\structured_export_manifest.json"))
    skill = (Test-AnyPath $Workspace @("skill\knowledge_qa_skill\SKILL.md", "skill\skill_generation_manifest.json", "skill\skill_manifest.json"))
    agent = (Test-AnyPath $Workspace @("agent\knowledge_qa_agent\agent_manifest.json", "agent\agent_generation_manifest.json", "agent\agent_manifest.json"))
    agent_dialogue = (Test-AnyPath $Workspace @("agent\dialogue\agent_dialogue.md", "agent\dialogue\chat_history.jsonl", "agent\dialogue\agent_dialogue_manifest.json"))
    a2a = (Test-AnyPath $Workspace @("multi_agent\multi_agent_discussion.md", "agent\workspaces\W_M\a2a_sessions\A2A_001\a2a_session_manifest.json"))
    audit_report = (Test-AnyPath $Workspace @("audit\audit_report.json"))
    profile_smoke = (Test-AnyPath $Workspace @("acceptance\stage3_profile_persistence_smoke_report.json"))
    parallel_isolation = (Test-AnyPath $Workspace @("tasks\parallel_validation\task_isolation_matrix.json"))
  }
}

function Get-SourceManifestInfo([string]$Workspace) {
  $path = Join-Path $Workspace "source_manifest.json"
  $json = Read-JsonFile $path
  if ($null -eq $json) {
    return [ordered]@{ exists = $false; path = $path; source_count = 0; sources = @() }
  }
  $sourceCount = 0
  if ($null -ne $json.source_count) { $sourceCount = [int]$json.source_count }
  return [ordered]@{
    exists = $true
    path = $path
    source_count = $sourceCount
    sources = @($json.sources)
  }
}
