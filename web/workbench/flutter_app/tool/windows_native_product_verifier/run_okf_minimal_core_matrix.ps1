param(
  [string]$ExePath = "",
  [string]$OutputRoot = "",
  [int]$TimeoutSeconds = 240,
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

function Add-MatrixRow(
  [System.Collections.ArrayList]$Rows,
  [string]$PathName,
  [string]$Step,
  [string]$Expected,
  [string]$Actual,
  [string]$DataFilePath,
  [bool]$Persistent,
  [bool]$RestartVerified,
  [string]$Conclusion,
  [string]$Blocker = ""
) {
  [void]$Rows.Add([ordered]@{
    path = $PathName
    step = $Step
    expected = $Expected
    actual = $Actual
    data_file_path = $DataFilePath
    persisted = $Persistent
    exe_restart_verified = $RestartVerified
    current_conclusion = $Conclusion
    blocker = $Blocker
  })
}

function Test-HasField($Object, [string]$Name) {
  if ($null -eq $Object) { return $false }
  return $null -ne ($Object.PSObject.Properties[$Name])
}

function Wait-ForArtifacts([string[]]$Paths, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    $missing = @($Paths | Where-Object { -not (Test-Path -LiteralPath $_) })
    if ($missing.Count -eq 0) { return $true }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $false
}

if ($ClearWorkspace) {
  Clear-WorkbenchWorkspace
}

$workspace = Get-WorkspacePath
$matrixDir = Join-Path $OutputRoot "okf_minimal_core"
$runDir = New-VerifierRunDir $matrixDir "okf_minimal_core"
$matrixPath = Join-Path $OutputRoot "okf_minimal_core_matrix.json"
$reportPath = Join-Path (Get-AppRoot) "..\..\..\docs\audits\current\okf_minimal_core_report.md"
$standardRoot = Join-Path $workspace "standard_packages\current"
$manifestPath = Join-Path $standardRoot "standard_package_manifest.json"
$sourceRefsPath = Join-Path $standardRoot "source_references.json"
$contentPath = Join-Path $standardRoot "content_package.jsonl"
$okfRuntimePath = Join-Path $workspace "standard_packages\okf_runtime_manifest.json"
$auditPath = Join-Path $workspace "standard_packages\audit_history.jsonl"
$orchestrationPath = Join-Path $workspace "orchestration\orchestration_plan.jsonl"
$kbManifestPath = Join-Path $workspace "kb\manifest.json"
$kbChunksPath = Join-Path $workspace "kb\chunks.jsonl"
$kbCatalogPath = Join-Path $workspace "knowledge_bases\kb_catalog.json"
$summaryPath = Join-Path $workspace "acceptance\okf_minimal_core_summary.json"
$ledgerPath = Join-Path $workspace "audit\event_ledger.jsonl"
$artifactCatalogPath = Join-Path $workspace "artifacts\catalog.json"
$rows = [System.Collections.ArrayList]::new()
$launch = $null

try {
  $launch = Start-WorkbenchExeWithEnv $ExePath @{ HEITANG_P0_OKF_MINIMAL_CORE_E2E = "1" }
  Set-NativeWindowSize $launch.hwnd 1440 900

  $requiredPaths = @(
    $manifestPath,
    $sourceRefsPath,
    $contentPath,
    $okfRuntimePath,
    $auditPath,
    $orchestrationPath,
    $kbManifestPath,
    $kbChunksPath,
    $kbCatalogPath,
    $summaryPath,
    $ledgerPath,
    $artifactCatalogPath
  )
  $pathsReady = Wait-ForArtifacts $requiredPaths $TimeoutSeconds

  Stop-WorkbenchExe $launch
  $launch = $null
  $launch = Start-WorkbenchExe $ExePath
  Set-NativeWindowSize $launch.hwnd 1440 900
  $restartReady = Wait-ForArtifacts $requiredPaths 60

  $manifest = Read-JsonFile $manifestPath
  $contentRows = @(Read-JsonlFile $contentPath)
  $manifestOk = $pathsReady -and $restartReady -and
    $manifest.schema_version -eq "prd_v3_standard_knowledge_package_manifest.v1" -and
    $manifest.standard -eq "okf_candidate" -and
    $manifest.okf_runtime_enabled -eq $true -and
    $manifest.independent_agent_runtime -eq $false -and
    $contentRows.Count -gt 0
  Add-MatrixRow $rows "P0-4B OKF Minimal Core" "standard package manifest and content" `
    "标准知识包必须有 manifest、source references、content_package，且只标记为 okf_candidate 内部标准包。" `
    "schema=$($manifest.schema_version); standard=$($manifest.standard); content_rows=$($contentRows.Count); independent_agent_runtime=$($manifest.independent_agent_runtime)" `
    $manifestPath $manifestOk $restartReady `
    ($(if ($manifestOk) { "okf_minimal_core_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($manifestOk) { "" } else { "okf_standard_package_manifest_blocked" }))

  $runtime = Read-JsonFile $okfRuntimePath
  $runtimeOk = $pathsReady -and $restartReady -and
    $runtime.schema_version -eq "prd_v3_okf_runtime_manifest.v1" -and
    $runtime.runtime_loaded -eq $true -and
    $runtime.external_runtime -eq $false -and
    $runtime.user_visible_top_level_page -eq $false -and
    $runtime.export_import_runtime_available -eq $true -and
    $runtime.kb_build_runtime_available -eq $true
  Add-MatrixRow $rows "P0-4B OKF Minimal Core" "runtime boundary manifest" `
    "okf_runtime_manifest.json 必须证明内部标准包 runtime 可用，同时不得接外部 runtime 或一级 OKF 页面。" `
    "schema=$($runtime.schema_version); loaded=$($runtime.runtime_loaded); external=$($runtime.external_runtime); top_level=$($runtime.user_visible_top_level_page); kb_build=$($runtime.kb_build_runtime_available)" `
    $okfRuntimePath $runtimeOk $restartReady `
    ($(if ($runtimeOk) { "okf_minimal_core_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($runtimeOk) { "" } else { "okf_runtime_boundary_blocked" }))

  $kbManifest = Read-JsonFile $kbManifestPath
  $kbCatalog = Read-JsonFile $kbCatalogPath
  [array]$kbRecords = if ($null -ne $kbCatalog -and $null -ne $kbCatalog.knowledge_bases) { $kbCatalog.knowledge_bases } else { @() }
  $okfKbRecord = $kbRecords | Where-Object { $_.kb_id -eq "K_OKF1" } | Select-Object -First 1
  $kbOk = $pathsReady -and $restartReady -and
    $kbManifest.schema_version -eq "prd_v3_kb_from_standard_package.v1" -and
    $kbManifest.status -eq "pass" -and
    $kbManifest.okf_runtime_enabled -eq $true -and
    $null -ne $okfKbRecord -and
    $okfKbRecord.okf_runtime_enabled -eq $true -and
    -not [string]::IsNullOrWhiteSpace([string]$okfKbRecord.source_standard_package_manifest)
  Add-MatrixRow $rows "P0-4B OKF Minimal Core" "KB materialized from standard package" `
    "标准包必须能构建真实 KB，并在 kb_catalog 中绑定 K_OKF1 与 source_standard_package_manifest。" `
    "kb_schema=$($kbManifest.schema_version); kb_status=$($kbManifest.status); catalog_has_kokf1=$($null -ne $okfKbRecord)" `
    $kbManifestPath $kbOk $restartReady `
    ($(if ($kbOk) { "okf_minimal_core_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($kbOk) { "" } else { "okf_kb_materialization_blocked" }))

  $auditRows = @(Read-JsonlFile $auditPath)
  $orchestrationRows = @(Read-JsonlFile $orchestrationPath)
  $auditExportRows = @($auditRows | Where-Object {
      $_.action -eq "export_standard_knowledge_package" -and
      $_.status -eq "completed"
    })
  $auditBuildRows = @($auditRows | Where-Object {
      $_.action -eq "build_kb_from_standard_package" -and
      $_.status -eq "completed"
    })
  $orchestrationExportRows = @($orchestrationRows | Where-Object {
      $_.action -eq "export_standard_knowledge_package" -and
      $_.boundary.okf_runtime_enabled -eq $true
    })
  $orchestrationBuildRows = @($orchestrationRows | Where-Object {
      $_.action -eq "build_kb_from_standard_package" -and
      $_.boundary.okf_runtime_enabled -eq $true
    })
  $auditOk = $pathsReady -and $restartReady -and
    $auditExportRows.Count -gt 0 -and
    $auditBuildRows.Count -gt 0 -and
    $orchestrationExportRows.Count -gt 0 -and
    $orchestrationBuildRows.Count -gt 0
  Add-MatrixRow $rows "P0-4B OKF Minimal Core" "audit and orchestration records" `
    "标准包导出和从标准包构建 KB 必须写入 audit_history 与 orchestration_plan。" `
    "audit_rows=$($auditRows.Count); orchestration_rows=$($orchestrationRows.Count); audit_export=$($auditExportRows.Count); audit_build=$($auditBuildRows.Count); orch_export=$($orchestrationExportRows.Count); orch_build=$($orchestrationBuildRows.Count)" `
    $auditPath $auditOk $restartReady `
    ($(if ($auditOk) { "okf_minimal_core_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($auditOk) { "" } else { "okf_audit_orchestration_blocked" }))

  $summary = Read-JsonFile $summaryPath
  $summaryOk = $pathsReady -and $restartReady -and
    $summary.status -eq "okf_minimal_core_completed_needs_owner_review" -and
    $summary.external_okf_service_connected -eq $false -and
    $summary.user_visible_top_level_okf_page -eq $false -and
    $summary.shipping_claim_absent -eq $true -and
    $summary.stage_exit_claim_absent -eq $true -and
    $summary.final_acceptance_claim_absent -eq $true
  Add-MatrixRow $rows "P0-4B OKF Minimal Core" "summary boundary" `
    "summary 必须写 needs_owner_review，且不得声明外部 OKF、一级页面或越界完成状态。" `
    "status=$($summary.status); external=$($summary.external_okf_service_connected); top_level=$($summary.user_visible_top_level_okf_page)" `
    $summaryPath $summaryOk $restartReady `
    ($(if ($summaryOk) { "okf_minimal_core_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($summaryOk) { "" } else { "okf_summary_boundary_blocked" }))

  $events = @(Read-JsonlFile $ledgerPath)
  $event = $events | Where-Object { $_.event_type -eq "okf_minimal_core_validated" } | Select-Object -Last 1
  $artifactCatalog = Read-JsonFile $artifactCatalogPath
  [array]$artifacts = if ($null -ne $artifactCatalog -and $null -ne $artifactCatalog.artifacts) { $artifactCatalog.artifacts } else { @() }
  $artifact = $artifacts | Where-Object { $_.artifact_id -eq "okf_minimal_core_summary" } | Select-Object -First 1
  $ledgerArtifactOk = $pathsReady -and $restartReady -and
    $null -ne $event -and
    $event.status -eq "okf_minimal_core_completed_needs_owner_review" -and
    $null -ne $artifact -and
    $artifact.status -eq "okf_minimal_core_completed_needs_owner_review"
  Add-MatrixRow $rows "P0-4B OKF Minimal Core" "Event Ledger and Artifact Lifecycle" `
    "P0-4B 验收本身必须写入 Event Ledger 并登记为 Artifact。" `
    "event_found=$($null -ne $event); artifact_found=$($null -ne $artifact)" `
    $artifactCatalogPath $ledgerArtifactOk $restartReady `
    ($(if ($ledgerArtifactOk) { "okf_minimal_core_completed_needs_owner_review" } else { "blocked" })) `
    ($(if ($ledgerArtifactOk) { "" } else { "okf_event_artifact_record_blocked" }))

  $blocked = @($rows | Where-Object { $_.current_conclusion -eq "blocked" })
  $status = if ($blocked.Count -eq 0) {
    "okf_minimal_core_completed_needs_owner_review"
  } else {
    "okf_minimal_core_blocked"
  }
  $payload = [ordered]@{
    schema_version = "heitang_p0_okf_minimal_core_matrix.v1"
    status = $status
    workspace = $workspace
    matrix = $rows
    run_dir = $runDir
    paths_ready = $pathsReady
    restart_verified = $restartReady
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Json $matrixPath $payload
  Write-Json (Join-Path $runDir "okf_minimal_core_matrix.json") $payload

  $blockerText = if ($blocked.Count -eq 0) {
    "- 无 P0-4B 直接阻断项，等待 Owner 复核。"
  } else {
    ($blocked | ForEach-Object { "- $($_.blocker)" }) -join "`n"
  }
  $report = @(
    "# P0-4B OKF Minimal Core Report",
    "",
    "状态：$status",
    "",
    "## 验收范围",
    "",
    "- 验证标准知识包 / OKF candidate 最小核心：manifest、source references、content package、KB materialization、audit、orchestration、Event Ledger、Artifact Lifecycle。",
    "- 本 Gate 不新增 OKF 一级页面，不接外部 OKF 服务，不写越界出门或最终验收声明。",
    "",
    "## 数据文件路径",
    "",
    "- workspace: $workspace",
    "- matrix: $matrixPath",
    "- run dir: $runDir",
    "- summary: $summaryPath",
    "- standard package manifest: $manifestPath",
    "- OKF runtime manifest: $okfRuntimePath",
    "- KB manifest: $kbManifestPath",
    "",
    "## 验证结论",
    "",
    "- rows: $($rows.Count)",
    "- blocked rows: $($blocked.Count)",
    "- restart_verified: $restartReady",
    "",
    "## 仍阻断项",
    "",
    $blockerText
  ) -join "`n"
  $reportParent = Split-Path -Parent $reportPath
  if ($reportParent) { New-Item -ItemType Directory -Force -Path $reportParent | Out-Null }
  $report | Set-Content -Encoding UTF8 -Path $reportPath

  Write-Output "status=$status"
  Write-Output "matrix=$matrixPath"
  Write-Output "report=$reportPath"
  if ($blocked.Count -gt 0) { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
