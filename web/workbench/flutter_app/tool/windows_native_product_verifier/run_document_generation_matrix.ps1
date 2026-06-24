param(
  [string]$ExePath = "",
  [string]$OutputRoot = "",
  [int]$TimeoutSeconds = 360,
  [switch]$ClearWorkspace
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($ExePath)) {
  $ExePath = Get-DefaultExePath
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\capability_blackbox"
}

function Get-FileHeaderHex([string]$Path, [int]$Count = 8) {
  if (-not (Test-Path -LiteralPath $Path)) { return "" }
  $bytes = [System.IO.File]::ReadAllBytes($Path)
  if ($bytes.Length -eq 0) { return "" }
  $take = [Math]::Min($Count, $bytes.Length)
  return (($bytes[0..($take - 1)] | ForEach-Object { $_.ToString("X2") }) -join "")
}

function Test-ExportFile([string]$Path, [string]$Format) {
  $exists = Test-Path -LiteralPath $Path
  $size = if ($exists) { (Get-Item -LiteralPath $Path).Length } else { 0 }
  $header = Get-FileHeaderHex $Path 8
  $expected = switch ($Format) {
    "docx" { "504B0304" }
    "pptx" { "504B0304" }
    "xlsx" { "504B0304" }
    "pdf" { "25504446" }
    default { "" }
  }
  $headerOk = if ($expected.Length -gt 0) { $header.StartsWith($expected) } else { $exists -and $size -gt 0 }
  return [ordered]@{
    path = $Path
    exists = $exists
    size_bytes = $size
    header_hex = $header
    expected_header_prefix = $expected
    header_ok = $headerOk
    non_empty = $size -gt 0
  }
}

function Wait-ForExportOutputs([array]$Exports, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    $pending = @($Exports | Where-Object {
      $check = Test-ExportFile $_.path $_.format
      -not ($check.exists -and $check.non_empty -and $check.header_ok -and (Test-Path -LiteralPath $_.manifest))
    })
    if ($pending.Count -eq 0) { return $true }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $false
}

function Add-MatrixRow(
  [System.Collections.ArrayList]$Rows,
  [string]$PathName,
  [string]$Step,
  [string]$Expected,
  [string]$Actual,
  [string]$ScreenshotPath,
  [string]$DataFilePath,
  [bool]$Persistent,
  [bool]$ReentryVerified,
  [bool]$RestartVerified,
  [string]$Conclusion,
  [string]$Blocker = ""
) {
  [void]$Rows.Add([ordered]@{
    path = $PathName
    step = $Step
    expected_result = $Expected
    actual_result = $Actual
    screenshot_path = $ScreenshotPath
    data_file_path = $DataFilePath
    is_persistent = $Persistent
    reentry_verified = $ReentryVerified
    restart_exe_verified = $RestartVerified
    conclusion = $Conclusion
    blocker = $Blocker
  })
}

if ($ClearWorkspace) {
  Clear-WorkbenchWorkspace
}

$workspace = Get-WorkspacePath
$runDir = New-VerifierRunDir $OutputRoot "document_generation"
$matrixPath = Join-Path $OutputRoot "document_generation_matrix.json"
$reportPath = Join-Path (Get-AppRoot) "..\..\..\docs\audits\current\document_generation_blackbox_report.md"
$rows = [System.Collections.ArrayList]::new()
$launch = $null

try {
  $launch = Start-WorkbenchExeWithEnv $ExePath @{ HEITANG_RC10_DOCUMENT_FLOW_E2E = "1" }
  Set-NativeWindowSize $launch.hwnd 1440 900
  $initialShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\document_generation_initial.png")

  $docManifestPath = Join-Path $workspace "doc\generation_manifest.json"
  $exports = @(
    @{ format = "md"; path = (Join-Path $workspace "export\reading_notes_export.md"); manifest = (Join-Path $workspace "export\export_manifest.json") },
    @{ format = "txt"; path = (Join-Path $workspace "export\txt\generated.txt"); manifest = (Join-Path $workspace "export\txt\generated_file_report.json") },
    @{ format = "json"; path = (Join-Path $workspace "export\structured\knowledge_export.json"); manifest = (Join-Path $workspace "export\structured\structured_export_manifest.json") },
    @{ format = "csv"; path = (Join-Path $workspace "export\structured\knowledge_export.csv"); manifest = (Join-Path $workspace "export\structured\structured_export_manifest.json") },
    @{ format = "docx"; path = (Join-Path $workspace "export\docx\generated.docx"); manifest = (Join-Path $workspace "export\docx\generated_file_report.json") },
    @{ format = "pdf"; path = (Join-Path $workspace "export\pdf\generated.pdf"); manifest = (Join-Path $workspace "export\pdf\generated_file_report.json") },
    @{ format = "pptx"; path = (Join-Path $workspace "export\pptx\generated.pptx"); manifest = (Join-Path $workspace "export\pptx\generated_file_report.json") },
    @{ format = "xlsx"; path = (Join-Path $workspace "export\xlsx\generated.xlsx"); manifest = (Join-Path $workspace "export\xlsx\generated_file_report.json") }
  )
  $manifestReady = Wait-ForPath $docManifestPath $TimeoutSeconds
  $exportsReady = Wait-ForExportOutputs $exports $TimeoutSeconds
  $ready = $manifestReady -and $exportsReady
  $afterShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\document_generation_after_e2e.png")

  Add-MatrixRow $rows "P0-6 Document Generation" "启动真实 EXE 文档链路" `
    "EXE 通过真实输入资料生成 doc/generation_manifest.json 并完成八种默认导出" `
    ($(if ($ready) { "generation_manifest and export outputs written" } else { "manifest_ready=$manifestReady; exports_ready=$exportsReady" })) `
    $afterShot.path $docManifestPath $ready $ready $false `
    ($(if ($ready) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($ready) { "" } else { "document_generation_outputs_missing" }))

  foreach ($export in $exports) {
    $format = $export.format
    $check = Test-ExportFile $export.path $format
    $manifestExists = Test-Path -LiteralPath $export.manifest
    $ok = $check.exists -and $check.non_empty -and $check.header_ok -and $manifestExists
    Add-MatrixRow $rows "P0-6 Document Generation" "导出 $($format.ToUpper())" `
      "$format 文件真实落盘、非空、manifest 存在，二进制格式有正确文件头" `
      ("exists={0}; non_empty={1}; header_ok={2}; manifest={3}" -f $check.exists, $check.non_empty, $check.header_ok, $manifestExists) `
      $afterShot.path $export.path $ok $ok $false `
      ($(if ($ok) { "blackbox_lifecycle_verified" } else { "blocked" })) `
      ($(if ($ok) { "" } else { "document_export_${format}_blocked" }))
  }

  $artifactCatalogPath = Join-Path $workspace "artifacts\catalog.json"
  $eventLedgerPath = Join-Path $workspace "audit\event_ledger.jsonl"
  $artifactCatalog = Read-JsonFile $artifactCatalogPath
  $events = Read-JsonlFile $eventLedgerPath
  $activeDocumentArtifacts = @()
  if ($null -ne $artifactCatalog -and $null -ne $artifactCatalog.artifacts) {
    $activeDocumentArtifacts = @($artifactCatalog.artifacts | Where-Object {
      $_.artifact_type -eq "generated_document" -and $_.status -eq "completed"
    })
  }
  $exportEvents = @($events | Where-Object {
    ($_.event_type -eq "export_document" -or $_.event_type -eq "export_artifact") -and $_.module -eq "document_generation"
  })
  $generateEvents = @($events | Where-Object {
    $_.event_type -eq "generate_document" -or $_.action -eq "generate_markdown"
  })
  $artifactOk = $activeDocumentArtifacts.Count -ge 6
  $eventsOk = $exportEvents.Count -ge 5 -and $generateEvents.Count -ge 1

  Add-MatrixRow $rows "P0-6 Document Generation" "成果目录联动" `
    "artifact catalog 出现文档生成和导出成果" `
    "active_generated_document_artifacts=$($activeDocumentArtifacts.Count)" `
    $afterShot.path $artifactCatalogPath $artifactOk $artifactOk $false `
    ($(if ($artifactOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($artifactOk) { "" } else { "document_artifact_catalog_link_blocked" }))

  Add-MatrixRow $rows "P0-6 Document Generation" "最近动态事件账本联动" `
    "event ledger 记录 generate_document 与 export_document 真实事件" `
    "generate_events=$($generateEvents.Count); export_events=$($exportEvents.Count)" `
    $afterShot.path $eventLedgerPath $eventsOk $eventsOk $false `
    ($(if ($eventsOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($eventsOk) { "" } else { "document_generation_event_ledger_link_blocked" }))

  Stop-WorkbenchExe $launch
  $launch = Start-WorkbenchExe $ExePath
  Set-NativeWindowSize $launch.hwnd 1440 900
  $restartShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\document_generation_after_restart.png")
  $restartChecks = @($exports | ForEach-Object { Test-ExportFile $_.path $_.format })
  $restartOk = ($restartChecks | Where-Object { -not ($_.exists -and $_.non_empty -and $_.header_ok) }).Count -eq 0
  Add-MatrixRow $rows "P0-6 Document Generation" "重启 EXE 后导出产物仍存在" `
    "重启后八种导出文件仍可通过文件检查" `
    "restart_export_files_ok=$restartOk" `
    $restartShot.path $workspace $restartOk $restartOk $true `
    ($(if ($restartOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($restartOk) { "" } else { "document_generation_restart_persistence_blocked" }))

  $blocked = @($rows | Where-Object { $_.conclusion -eq "blocked" })
  $status = if ($blocked.Count -eq 0) {
    "document_generation_lifecycle_completed_needs_owner_review"
  } else {
    "document_generation_lifecycle_blocked"
  }

  $payload = [ordered]@{
    schema_version = "heitang_p0_document_generation_blackbox_matrix.v1"
    status = $status
    workspace = $workspace
    run_dir = $runDir
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    rows = $rows
    export_checks = $restartChecks
    artifact_catalog_path = $artifactCatalogPath
    event_ledger_path = $eventLedgerPath
  }
  Write-Json $matrixPath $payload
  Write-Json (Join-Path $runDir "document_generation_matrix.json") $payload

  $blockerText = if ($blocked.Count -eq 0) {
    "- 无 P0-6 直接阻断项，等待 Owner 复核。"
  } else {
    ($blocked | ForEach-Object { "- $($_.blocker)" }) -join "`n"
  }
  $report = @(
    "# P0-6 Document Generation Blackbox Report",
    "",
    "状态：$status",
    "",
    "## 黑盒路径",
    "",
    "1. 启动真实 Windows EXE，并通过 HEITANG_RC10_DOCUMENT_FLOW_E2E=1 执行真实文档链路。",
    "2. 基于真实输入资料生成知识库、检索、Markdown 文档。",
    "3. 导出默认内置格式：md / txt / json / csv / docx / pdf / pptx / xlsx。",
    "4. 检查导出文件非空、manifest 存在，二进制格式检查文件头。",
    "5. 检查 artifact catalog 与 event ledger 联动。",
    "6. 重启 EXE 后再次检查导出产物存在。",
    "",
    "## 数据文件路径",
    "",
    "- workspace: $workspace",
    "- matrix: $matrixPath",
    "- run dir: $runDir",
    "- doc manifest: $docManifestPath",
    "- artifact catalog: $artifactCatalogPath",
    "- event ledger: $eventLedgerPath",
    "",
    "## 截图路径",
    "",
    "- initial: $($initialShot.path)",
    "- after e2e: $($afterShot.path)",
    "- after restart: $($restartShot.path)",
    "",
    "## 验证结论",
    "",
    "- blocked rows: $($blocked.Count)",
    "- current status: $status",
    "",
    "## 未验证内容",
    "",
    "- 未做人工打开 Office/PDF 应用的视觉检查。",
    "- 未做导出成果删除后的完整 UI 黑盒删除路径；删除能力归入 Artifact Lifecycle Gate。",
    "",
    "## 仍阻断项",
    "",
    $blockerText
  ) -join "`n"
  $reportParent = Split-Path -Parent $reportPath
  if ($reportParent) { New-Item -ItemType Directory -Force -Path $reportParent | Out-Null }
  $report | Set-Content -Encoding UTF8 -Path $reportPath

  Write-Json (Join-Path $runDir "summary.json") ([ordered]@{
    status = $status
    matrix_path = $matrixPath
    report_path = $reportPath
    blocked_count = $blocked.Count
  })
  Write-Output "status=$status"
  Write-Output "matrix=$matrixPath"
  Write-Output "report=$reportPath"
  if ($blocked.Count -gt 0) { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
