param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p0_acceptance"
}

function Read-MatrixRows($Matrix) {
  if ($null -eq $Matrix) { return @() }
  if ($null -ne $Matrix.rows) { return @($Matrix.rows) }
  if ($null -ne $Matrix.matrix) { return @($Matrix.matrix) }
  return @()
}

function Count-BlockedRows($Rows) {
  return @($Rows | Where-Object {
    $_.conclusion -eq "blocked" -or $_.current_conclusion -eq "blocked"
  }).Count
}

function Add-AcceptanceRow(
  [System.Collections.ArrayList]$Rows,
  [string]$Gate,
  [string]$ExpectedStatus,
  [string]$MatrixPath,
  [string]$ReportPath
) {
  $matrixExists = Test-Path -LiteralPath $MatrixPath
  $reportExists = Test-Path -LiteralPath $ReportPath
  $matrix = if ($matrixExists) { Read-JsonFile $MatrixPath } else { $null }
  $matrixRows = Read-MatrixRows $matrix
  $blocked = Count-BlockedRows $matrixRows
  $status = if ($matrix) { [string]$matrix.status } else { "" }
  $statusOk = $status -eq $ExpectedStatus
  $ok = $matrixExists -and $reportExists -and $statusOk -and $blocked -eq 0
  [void]$Rows.Add([ordered]@{
    gate = $Gate
    expected_status = $ExpectedStatus
    actual_status = $status
    matrix_path = $MatrixPath
    report_path = $ReportPath
    matrix_exists = $matrixExists
    report_exists = $reportExists
    row_count = $matrixRows.Count
    blocked_rows = $blocked
    conclusion = if ($ok) { "p0_gate_evidence_verified" } else { "blocked" }
    blocker = if ($ok) { "" } else { "${Gate}_evidence_incomplete" }
  })
}

$appRoot = Get-AppRoot
$repoRoot = (Resolve-Path (Join-Path $appRoot "..\..\..")).Path
$capabilityStatusPath = Join-Path $repoRoot "capability_chain_status.json"
$matrixPath = Join-Path $OutputRoot "p0_core_lifecycle_matrix.json"
$reportPath = Join-Path $repoRoot "docs\audits\current\p0_core_lifecycle_acceptance_report.md"
$rows = [System.Collections.ArrayList]::new()

Add-AcceptanceRow $rows "P0-1 Event Ledger" "event_ledger_repair_completed_needs_owner_review" `
  (Join-Path $appRoot "output\event_ledger\event_ledger_blackbox_matrix.json") `
  (Join-Path $repoRoot "docs\audits\current\event_ledger_repair_report.md")
Add-AcceptanceRow $rows "P0-2 Artifact Lifecycle" "artifact_lifecycle_repair_completed_needs_owner_review" `
  (Join-Path $appRoot "output\artifact_lifecycle\artifact_lifecycle_blackbox_matrix.json") `
  (Join-Path $repoRoot "docs\audits\current\artifact_lifecycle_repair_report.md")
Add-AcceptanceRow $rows "P0-2b Industrial Scope Metadata" "industrial_scope_metadata_reserved_needs_review" `
  (Join-Path $appRoot "output\capability_blackbox\industrial_scope\industrial_scope_metadata_reservation_matrix.json") `
  (Join-Path $repoRoot "docs\audits\current\industrial_scope_metadata_reservation_report.md")
Add-AcceptanceRow $rows "P0-3 Document Library" "document_library_lifecycle_completed_needs_owner_review" `
  (Join-Path $appRoot "output\capability_blackbox\document_library_matrix.json") `
  (Join-Path $repoRoot "docs\audits\current\document_library_blackbox_report.md")
Add-AcceptanceRow $rows "P0-4 Knowledge Base Build" "knowledge_base_build_lifecycle_completed_needs_owner_review" `
  (Join-Path $appRoot "output\capability_blackbox\knowledge_base_build_matrix.json") `
  (Join-Path $repoRoot "docs\audits\current\knowledge_base_build_blackbox_report.md")
Add-AcceptanceRow $rows "P0-5 Knowledge Validation" "knowledge_validation_lifecycle_completed_needs_owner_review" `
  (Join-Path $appRoot "output\capability_blackbox\knowledge_validation_matrix.json") `
  (Join-Path $repoRoot "docs\audits\current\knowledge_validation_blackbox_report.md")
Add-AcceptanceRow $rows "P0-6 Document Generation" "document_generation_lifecycle_completed_needs_owner_review" `
  (Join-Path $appRoot "output\capability_blackbox\document_generation_matrix.json") `
  (Join-Path $repoRoot "docs\audits\current\document_generation_blackbox_report.md")
Add-AcceptanceRow $rows "P0-7 Skill Generation" "skill_generation_lifecycle_completed_needs_owner_review" `
  (Join-Path $appRoot "output\capability_blackbox\skill_generation_matrix.json") `
  (Join-Path $repoRoot "docs\audits\current\skill_generation_blackbox_report.md")
Add-AcceptanceRow $rows "P0-8 Settings / Path / Export" "settings_export_basic_completed_needs_owner_review" `
  (Join-Path $appRoot "output\capability_blackbox\settings_export_matrix.json") `
  (Join-Path $repoRoot "docs\audits\current\settings_export_blackbox_report.md")
Add-AcceptanceRow $rows "P0-9 Memory and Evidence Metadata Reservation" "memory_evidence_metadata_reserved_needs_review" `
  (Join-Path $appRoot "output\capability_blackbox\memory_evidence\memory_evidence_metadata_reservation_matrix.json") `
  (Join-Path $repoRoot "docs\audits\current\memory_evidence_metadata_reservation_report.md")

$blocked = @($rows | Where-Object { $_.conclusion -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "p0_core_lifecycle_pre_backfill_snapshot_needs_owner_review"
} else {
  "p0_core_lifecycle_blocked"
}

$payload = [ordered]@{
  schema_version = "heitang_p0_core_lifecycle_acceptance_matrix.v1"
  status = $status
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
  repo_root = $repoRoot
  global_goal_complete = $false
  p1_started = $false
  backfill_required = $true
  next_gate = "P0-4B OKF Minimal Core Gate"
  rows = $rows
  capability_chain_status_path = $capabilityStatusPath
}
Write-Json $matrixPath $payload

$blockerText = if ($blocked.Count -eq 0) {
  "- 无 P0 Core Lifecycle 直接阻断项，等待 Owner 复核。"
} else {
  ($blocked | ForEach-Object { "- $($_.blocker)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.gate): $($_.actual_status), blocked=$($_.blocked_rows)"
}) -join "`n"
$report = @(
  "# P0 Core Lifecycle Acceptance Report",
  "",
  "状态：$status",
  "",
  "## 验收范围",
  "",
  "- 聚合 P0-1 到 P0-9 的当前黑盒矩阵和审计报告。",
  "- 本 Gate 不重复执行 Night Long Build，只检查各 Gate 的权威证据文件、状态和 blocked rows。",
  "- 本 Gate 不进入 P1 / P2 实现。",
  "",
  "## 验证结论",
  "",
  "- gate rows: $($rows.Count)",
  "- blocked rows: $($blocked.Count)",
  "- global_goal_complete: false",
  "- backfill_required: true",
  "- next gate: P0-4B OKF Minimal Core Gate",
  "",
  "## 证据矩阵",
  "",
  $evidenceText,
  "",
  "## 边界",
  "",
  "- 本报告是 P0-1 到 P0-9 的 pre-backfill snapshot，不是最终 P0 Core Acceptance。",
  "- P0-4B OKF Minimal Core Gate 和 P0-5B Knowledge Reliability Minimal Core Gate 必须先通过。",
  "- P0 主链路进入 Owner Review，不代表生产、发布或工业级验收完成。",
  "- P1 / P2 队列仍未执行，能力链总目标继续保持未完成。",
  "- A2A、工作小组、多模型调度、远程控制和发布均未进入本 Gate。",
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
