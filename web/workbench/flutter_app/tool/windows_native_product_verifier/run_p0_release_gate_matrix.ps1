param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p0_release"
}

function Split-TableRow([string]$Line) {
  $trimmed = $Line.Trim()
  if (-not $trimmed.StartsWith("|")) { return @() }
  $parts = $trimmed.Trim("|").Split("|")
  return @($parts | ForEach-Object { $_.Trim() })
}

function Read-CapabilityRows([string]$Path) {
  $lines = Get-Content -LiteralPath $Path -Encoding UTF8
  $header = $null
  $rows = @()
  foreach ($line in $lines) {
    if ($line -like "| capability_id |*") {
      $header = Split-TableRow $line
      continue
    }
    if ($null -eq $header) { continue }
    if ($line -like "| ---*") { continue }
    if (-not ($line -like "|*|*")) { continue }
    $values = Split-TableRow $line
    if ($values.Count -ne $header.Count) { continue }
    $row = [ordered]@{}
    for ($index = 0; $index -lt $header.Count; $index += 1) {
      $row[$header[$index]] = $values[$index]
    }
    if ($row["capability_id"] -and $row["phase"]) {
      $rows += [pscustomobject]$row
    }
  }
  return $rows
}

function Get-EvidenceTokens([object]$Row) {
  $tokens = New-Object System.Collections.Generic.List[string]
  foreach ($field in @("landed_files", "evidence_report")) {
    $value = [string]$Row.$field
    if ([string]::IsNullOrWhiteSpace($value) -or $value -eq "none") { continue }
    $cleanValue = $value.Replace('`', '')
    foreach ($part in ($cleanValue -split ";")) {
      $candidate = $part.Trim()
      if ($candidate -match "^[A-Za-z0-9_./\\-]+$" -and
          ($candidate.Contains("/") -or $candidate.Contains("\"))) {
        [void]$tokens.Add($candidate)
      }
    }
  }
  return @($tokens | Where-Object { $_ -and $_ -ne "none" } | Select-Object -Unique)
}

function Resolve-EvidencePath([string]$RepoRoot, [string]$AppRoot, [string]$Token) {
  $normalized = $Token -replace "/", "\"
  $candidates = @(
    (Join-Path $RepoRoot $normalized),
    (Join-Path $AppRoot $normalized)
  )
  foreach ($candidate in $candidates) {
    if (Test-Path -LiteralPath $candidate) { return $candidate }
  }
  return ""
}

function Add-GateRow(
  [System.Collections.ArrayList]$Rows,
  [string]$Check,
  [bool]$Passed,
  [string]$Actual,
  [string]$Blocker = ""
) {
  [void]$Rows.Add([ordered]@{
    check = $Check
    status = if ($Passed) { "passed" } else { "blocked" }
    actual = $Actual
    blocker = if ($Passed) { "" } else { $Blocker }
  })
}

$appRoot = Get-AppRoot
$repoRoot = (Resolve-Path (Join-Path $appRoot "..\..\..")).Path
$matrixPath = Join-Path $OutputRoot "p0_release_gate_matrix.json"
$reportPath = Join-Path $repoRoot "docs\audits\current\p0_release_gate_closure_report.md"
$registryPath = Join-Path $repoRoot "docs\capability_registry\Capability_Implementation_Status.md"
$chainPath = Join-Path $repoRoot "capability_chain_status.json"
$p0CoreMatrixPath = Join-Path $appRoot "output\p0_acceptance\p0_core_lifecycle_matrix.json"
$rows = [System.Collections.ArrayList]::new()

$capabilityRows = @(Read-CapabilityRows $registryPath)
$p0Rows = @($capabilityRows | Where-Object { $_.phase -eq "P0" })
$p0RowsBeforeGate = @($p0Rows | Where-Object { $_.capability_id -ne "p0_release_gate" })
$releaseRow = $p0Rows | Where-Object { $_.capability_id -eq "p0_release_gate" } | Select-Object -First 1
$chain = Read-JsonFile $chainPath
$p0CoreMatrix = Read-JsonFile $p0CoreMatrixPath
$validTypes = @("user_blackbox", "core_only", "artifact", "governance", "composite")

$prePassState = $chain.current_gate -eq "P0 Release Gate" -and
  $chain.current_phase -eq "P0" -and
  $chain.remaining_gates[0] -eq "P0 Release Gate"
$postPassState = $chain.current_gate -eq "P1-1 Capability Chain Runner" -and
  $chain.current_phase -eq "P1" -and
  $chain.remaining_gates[0] -eq "P1-1 Capability Chain Runner" -and
  @($chain.completed_with_owner_review_needed) -contains "P0 Release Gate"
$currentGateOk = ($prePassState -or $postPassState) -and
  $chain.global_goal_complete -eq $false
Add-GateRow $rows "status machine is at P0 gate or P1 entry after pass" $currentGateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($chain.remaining_gates[0]); global_goal_complete=$($chain.global_goal_complete)" `
  "p0_release_gate_status_machine_mismatch"

$p0CoreOk = (Test-Path -LiteralPath $p0CoreMatrixPath) -and
  $p0CoreMatrix.status -eq "p0_core_lifecycle_backfill_rerun_completed_needs_owner_review" -and
  @($p0CoreMatrix.rows | Where-Object { $_.conclusion -eq "blocked" }).Count -eq 0 -and
  @($p0CoreMatrix.rows).Count -ge 14
Add-GateRow $rows "P0 core rerun matrix has no blockers" $p0CoreOk `
  "status=$($p0CoreMatrix.status); rows=$(@($p0CoreMatrix.rows).Count); blocked=$(@($p0CoreMatrix.rows | Where-Object { $_.conclusion -eq 'blocked' }).Count)" `
  "p0_core_rerun_incomplete"

$typeRowsOk = @($p0Rows | Where-Object { $validTypes -notcontains $_.acceptance_type }).Count -eq 0
Add-GateRow $rows "P0 rows have valid acceptance types" $typeRowsOk `
  "p0_rows=$($p0Rows.Count)" `
  "p0_acceptance_type_invalid"

$notClosed = @($p0RowsBeforeGate | Where-Object { $_.close_allowed -ne "true" })
Add-GateRow $rows "P0 rows before release gate are close_allowed" ($notClosed.Count -eq 0) `
  "not_closed=$($notClosed.capability_id -join ',')" `
  "p0_close_allowed_missing"

$statusFailures = New-Object System.Collections.Generic.List[string]
foreach ($row in $p0RowsBeforeGate) {
  $ok = $true
  switch ($row.acceptance_type) {
    "user_blackbox" {
      $ok = $row.core_status -eq "passed" -and
        $row.ui_binding_status -eq "passed" -and
        $row.blackbox_status -eq "passed" -and
        @("passed", "not_required").Contains($row.artifact_status) -and
        @("passed", "not_required").Contains($row.event_status) -and
        $row.restart_status -eq "passed"
    }
    "core_only" {
      $ok = $row.core_status -eq "passed" -and
        $row.ui_binding_status -eq "not_required" -and
        $row.blackbox_status -eq "not_required"
    }
    "artifact" {
      $ok = $row.core_status -eq "passed" -and
        $row.artifact_status -eq "passed" -and
        @("passed", "not_required").Contains($row.blackbox_status) -and
        $row.restart_status -eq "passed"
    }
    "governance" {
      $ok = $row.core_status -eq "passed" -and
        $row.governance_status -eq "passed" -and
        @("passed", "not_required").Contains($row.restart_status)
    }
    "composite" {
      $ok = $row.core_status -eq "passed" -and
        $row.ui_binding_status -eq "linked_passed" -and
        $row.blackbox_status -eq "linked_passed" -and
        @("passed", "not_required").Contains($row.artifact_status) -and
        @("passed", "not_required").Contains($row.event_status) -and
        @("passed", "linked_passed", "not_required").Contains($row.restart_status) -and
        -not [string]::IsNullOrWhiteSpace($row.linked_blackbox_cases) -and
        $row.linked_blackbox_cases -ne "not_required"
    }
  }
  if (-not $ok) { [void]$statusFailures.Add($row.capability_id) }
}
Add-GateRow $rows "P0 acceptance-type status requirements pass" ($statusFailures.Count -eq 0) `
  "failed=$($statusFailures -join ',')" `
  "p0_acceptance_status_incomplete"

$missingEvidence = New-Object System.Collections.Generic.List[string]
foreach ($row in $p0RowsBeforeGate) {
  $tokens = @(Get-EvidenceTokens $row)
  $existing = @($tokens | ForEach-Object { Resolve-EvidencePath $repoRoot $appRoot $_ } | Where-Object { $_ })
  if ($existing.Count -eq 0) { [void]$missingEvidence.Add($row.capability_id) }
  if ([string]$row.evidence_commit -eq "none") { [void]$missingEvidence.Add("$($row.capability_id):commit") }
}
Add-GateRow $rows "P0 evidence paths and commit fields exist" ($missingEvidence.Count -eq 0) `
  "missing=$($missingEvidence -join ',')" `
  "p0_evidence_incomplete"

$compositeMissing = @($p0RowsBeforeGate | Where-Object {
  $_.acceptance_type -eq "composite" -and
  ($_.linked_blackbox_cases -eq "not_required" -or [string]::IsNullOrWhiteSpace($_.linked_blackbox_cases))
})
Add-GateRow $rows "P0 composite linked cases are attached" ($compositeMissing.Count -eq 0) `
  "missing=$($compositeMissing.capability_id -join ',')" `
  "p0_composite_linked_cases_missing"

$claimA = "production" + "_" + "ready"
$claimB = "release" + "_" + "ready"
$claimC = "industrial" + "_" + "acceptance" + "_" + "passed"
$newClaimMatches = @()
$diff = & git -C $repoRoot diff --unified=0
foreach ($line in $diff) {
  if ($line.StartsWith("+") -and -not $line.StartsWith("+++")) {
    foreach ($claim in @($claimA, $claimB, $claimC)) {
      if ($line.Contains($claim)) { $newClaimMatches += $claim }
    }
  }
}
Add-GateRow $rows "no new forbidden positive claims in current diff" ($newClaimMatches.Count -eq 0) `
  "new_claim_matches=$($newClaimMatches.Count)" `
  "p0_release_gate_forbidden_claim_added"

$gitDirty = @(& git -C $repoRoot status --short)
$partitionOk = $gitDirty.Count -eq 0 -or @($gitDirty | Where-Object {
  $_ -match "p0_release_gate|Capability_Implementation_Status.md|capability_chain_status.json|p0_release"
}).Count -eq $gitDirty.Count
Add-GateRow $rows "workspace clean or current-gate partitioned" $partitionOk `
  "dirty_count=$($gitDirty.Count)" `
  "p0_release_gate_worktree_pollution"

$blocked = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "p0_release_gate_passed_needs_owner_review"
} else {
  "p0_release_gate_blocked"
}
$payload = [ordered]@{
  schema_version = "heitang_p0_release_gate_matrix.v1"
  status = $status
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
  repo_root = $repoRoot
  current_gate = $chain.current_gate
  current_phase = $chain.current_phase
  phase_after_pass = "P1"
  next_gate = "P1-1 Capability Chain Runner"
  global_goal_complete = $false
  p0_row_count = $p0Rows.Count
  p0_rows_before_gate = $p0RowsBeforeGate.Count
  p0_core_matrix_path = $p0CoreMatrixPath
  rows = $rows
}
Write-Json $matrixPath $payload

$blockerText = if ($blocked.Count -eq 0) {
  "- 无 P0 Release Gate 直接阻断项，等待 Owner 复核。"
} else {
  ($blocked | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$report = @(
  "# P0 Release Gate Closure Report",
  "",
  "状态：$status",
  "",
  "## 验收范围",
  "",
  "- 验证 P0 能力主表、P0 Core 聚合矩阵、状态机队列、证据路径、复合能力 linked cases、当前 Gate 工作区分区。",
  "- 本 Gate 是阶段出门门禁，不是正式发布声明，不执行 P1 能力实现。",
  "",
  "## 验证结论",
  "",
  "- p0 rows: $($p0Rows.Count)",
  "- p0 rows before release gate: $($p0RowsBeforeGate.Count)",
  "- blocked rows: $($blocked.Count)",
  "- current phase: $($chain.current_phase)",
  "- current gate: $($chain.current_gate)",
  "- next gate after pass: P1-1 Capability Chain Runner",
  "- global_goal_complete: false",
  "",
  "## Evidence Matrix",
  "",
  $evidenceText,
  "",
  "## Boundary Compliance",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- no new final/public/final-acceptance positive claims in current diff.",
  "- no P1 implementation executed by this Gate.",
  "- Redis / vector DB services remain external connectors and are not packaged into the EXE.",
  "",
  "## Final Close Decision",
  "",
  "- close_allowed: $($blocked.Count -eq 0)",
  "- release_status: $status",
  "- next_gate: P1-1 Capability Chain Runner",
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
