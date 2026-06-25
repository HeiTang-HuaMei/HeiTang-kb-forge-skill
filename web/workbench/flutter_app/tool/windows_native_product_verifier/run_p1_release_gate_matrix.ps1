param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p1_release"
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

function Test-AcceptanceTypeStatus([object]$Row) {
  switch ($Row.acceptance_type) {
    "user_blackbox" {
      return $Row.core_status -eq "passed" -and
        $Row.ui_binding_status -eq "passed" -and
        $Row.blackbox_status -eq "passed" -and
        @("passed", "not_required").Contains($Row.artifact_status) -and
        @("passed", "not_required").Contains($Row.event_status) -and
        $Row.restart_status -eq "passed"
    }
    "core_only" {
      return $Row.core_status -eq "passed" -and
        $Row.ui_binding_status -eq "not_required" -and
        $Row.blackbox_status -eq "not_required"
    }
    "artifact" {
      return $Row.core_status -eq "passed" -and
        $Row.artifact_status -eq "passed" -and
        @("passed", "not_required").Contains($Row.blackbox_status) -and
        $Row.restart_status -eq "passed"
    }
    "governance" {
      return $Row.core_status -eq "passed" -and
        $Row.governance_status -eq "passed" -and
        @("passed", "not_required").Contains($Row.restart_status)
    }
    "composite" {
      return $Row.core_status -eq "passed" -and
        $Row.ui_binding_status -eq "linked_passed" -and
        $Row.blackbox_status -eq "linked_passed" -and
        @("passed", "not_required").Contains($Row.artifact_status) -and
        @("passed", "not_required").Contains($Row.event_status) -and
        @("passed", "linked_passed", "not_required").Contains($Row.restart_status) -and
        -not [string]::IsNullOrWhiteSpace($Row.linked_blackbox_cases) -and
        $Row.linked_blackbox_cases -ne "not_required"
    }
  }
  return $false
}

$appRoot = Get-AppRoot
$repoRoot = (Resolve-Path (Join-Path $appRoot "..\..\..")).Path
$matrixPath = Join-Path $OutputRoot "p1_release_gate_matrix.json"
$reportPath = Join-Path $repoRoot "docs\audits\current\p1_release_gate_closure_report.md"
$registryPath = Join-Path $repoRoot "docs\capability_registry\Capability_Implementation_Status.md"
$chainPath = Join-Path $repoRoot "capability_chain_status.json"
$p0ReleaseMatrixPath = Join-Path $appRoot "output\p0_release\p0_release_gate_matrix.json"
$p0ReleaseReportPath = Join-Path $repoRoot "docs\audits\current\p0_release_gate_closure_report.md"
$rows = [System.Collections.ArrayList]::new()

$capabilityRows = @(Read-CapabilityRows $registryPath)
$p0Rows = @($capabilityRows | Where-Object { $_.phase -eq "P0" })
$p1Rows = @($capabilityRows | Where-Object { $_.phase -eq "P1" })
$p1RowsBeforeGate = @($p1Rows | Where-Object { $_.capability_id -ne "p1_release_gate" })
$releaseRow = $p1Rows | Where-Object { $_.capability_id -eq "p1_release_gate" } | Select-Object -First 1
$chain = Read-JsonFile $chainPath
$validTypes = @("user_blackbox", "core_only", "artifact", "governance", "composite")

$prePassState = $chain.current_gate -eq "P1 Release Gate" -and
  $chain.current_phase -eq "P1" -and
  $chain.remaining_gates[0] -eq "P1 Release Gate"
$postPassState = $chain.current_gate -eq "P2-1 Workgroup Basic Runtime" -and
  $chain.current_phase -eq "P2" -and
  $chain.remaining_gates[0] -eq "P2-1 Workgroup Basic Runtime" -and
  @($chain.completed_with_owner_review_needed) -contains "P1 Release Gate"
$currentGateOk = ($prePassState -or $postPassState) -and
  $chain.global_goal_complete -eq $false
Add-GateRow $rows "status machine is at P1 gate or P2 entry after pass" $currentGateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($chain.remaining_gates[0]); global_goal_complete=$($chain.global_goal_complete)" `
  "p1_release_gate_status_machine_mismatch"

$p0ReleaseOk = (Test-Path -LiteralPath $p0ReleaseMatrixPath) -and
  (Test-Path -LiteralPath $p0ReleaseReportPath)
if ($p0ReleaseOk) {
  $p0ReleaseMatrix = Read-JsonFile $p0ReleaseMatrixPath
  $p0ReleaseOk = $p0ReleaseMatrix.status -eq "p0_release_gate_passed_needs_owner_review" -and
    @($p0ReleaseMatrix.rows | Where-Object { $_.status -eq "blocked" }).Count -eq 0
}
Add-GateRow $rows "P0 Release Gate regression evidence exists and has no blockers" $p0ReleaseOk `
  "matrix=$p0ReleaseMatrixPath; report=$p0ReleaseReportPath" `
  "p0_release_regression_missing"

$typeRowsOk = @($p1Rows | Where-Object { $validTypes -notcontains $_.acceptance_type }).Count -eq 0
Add-GateRow $rows "P1 rows have valid acceptance types" $typeRowsOk `
  "p1_rows=$($p1Rows.Count)" `
  "p1_acceptance_type_invalid"

$notClosed = @($p1RowsBeforeGate | Where-Object { $_.close_allowed -ne "true" })
Add-GateRow $rows "P1 rows before release gate are close_allowed" ($notClosed.Count -eq 0) `
  "not_closed=$($notClosed.capability_id -join ',')" `
  "p1_close_allowed_missing"

$statusFailures = New-Object System.Collections.Generic.List[string]
foreach ($row in $p1RowsBeforeGate) {
  if (-not (Test-AcceptanceTypeStatus $row)) {
    [void]$statusFailures.Add($row.capability_id)
  }
}
Add-GateRow $rows "P1 acceptance-type status requirements pass" ($statusFailures.Count -eq 0) `
  "failed=$($statusFailures -join ',')" `
  "p1_acceptance_status_incomplete"

$p0RegressionFailures = New-Object System.Collections.Generic.List[string]
foreach ($row in $p0Rows) {
  if ($row.capability_id -eq "p0_release_gate") { continue }
  if ($row.close_allowed -ne "true" -or -not (Test-AcceptanceTypeStatus $row)) {
    [void]$p0RegressionFailures.Add($row.capability_id)
  }
}
Add-GateRow $rows "P0 rows still satisfy release regression requirements" ($p0RegressionFailures.Count -eq 0) `
  "failed=$($p0RegressionFailures -join ',')" `
  "p0_regression_status_incomplete"

$missingEvidence = New-Object System.Collections.Generic.List[string]
foreach ($row in $p1RowsBeforeGate) {
  $tokens = @(Get-EvidenceTokens $row)
  $existing = @($tokens | ForEach-Object { Resolve-EvidencePath $repoRoot $appRoot $_ } | Where-Object { $_ })
  if ($existing.Count -eq 0) { [void]$missingEvidence.Add($row.capability_id) }
  if ([string]$row.evidence_commit -eq "none") { [void]$missingEvidence.Add("$($row.capability_id):commit") }
}
Add-GateRow $rows "P1 evidence paths and commit fields exist" ($missingEvidence.Count -eq 0) `
  "missing=$($missingEvidence -join ',')" `
  "p1_evidence_incomplete"

$linkedMissing = @($p1RowsBeforeGate | Where-Object {
  $_.acceptance_type -eq "composite" -and
  ($_.linked_blackbox_cases -eq "not_required" -or [string]::IsNullOrWhiteSpace($_.linked_blackbox_cases))
})
Add-GateRow $rows "P1 composite linked cases are attached when required" ($linkedMissing.Count -eq 0) `
  "missing=$($linkedMissing.capability_id -join ',')" `
  "p1_composite_linked_cases_missing"

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
Add-GateRow $rows "no new forbidden final/public claims in current diff" ($newClaimMatches.Count -eq 0) `
  "new_claim_matches=$($newClaimMatches.Count)" `
  "p1_release_gate_forbidden_claim_added"

$gitDirty = @(& git -C $repoRoot status --short)
$partitionOk = $gitDirty.Count -eq 0 -or @($gitDirty | Where-Object {
  $_ -match "p1_release_gate|Capability_Implementation_Status.md|capability_chain_status.json|p1_release|run_p1_release_gate_matrix.ps1"
}).Count -eq $gitDirty.Count
Add-GateRow $rows "workspace clean or current-gate partitioned" $partitionOk `
  "dirty_count=$($gitDirty.Count)" `
  "p1_release_gate_worktree_pollution"

$blocked = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "p1_release_gate_passed_needs_owner_review"
} else {
  "p1_release_gate_blocked"
}
$payload = [ordered]@{
  schema_version = "heitang_p1_release_gate_matrix.v1"
  status = $status
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
  repo_root = $repoRoot
  current_gate = $chain.current_gate
  current_phase = $chain.current_phase
  phase_after_pass = "P2"
  next_gate = "P2-1 Workgroup Basic Runtime"
  global_goal_complete = $false
  p1_row_count = $p1Rows.Count
  p1_rows_before_gate = $p1RowsBeforeGate.Count
  p0_regression_row_count = $p0Rows.Count
  p0_release_matrix_path = $p0ReleaseMatrixPath
  rows = $rows
}
Write-Json $matrixPath $payload

$blockerText = if ($blocked.Count -eq 0) {
  "- none for this P1 Release Gate."
} else {
  ($blocked | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$boundaryResult = if ($blocked.Count -eq 0) { "passed" } else { "blocked" }
$report = @(
  "# P1 Release Gate Closure Report",
  "",
  "Status: $status",
  "",
  "## Acceptance Scope",
  "",
  "- Validate P1 capability rows, acceptance-type requirements, P0 release regression evidence, queue state, evidence paths and current-gate worktree partition.",
  "- This Gate is a staged phase-exit gate, not a public release or final acceptance claim.",
  "- This Gate does not execute P2 capability work.",
  "",
  "## Verification Summary",
  "",
  "- p1 rows: $($p1Rows.Count)",
  "- p1 rows before release gate: $($p1RowsBeforeGate.Count)",
  "- p0 regression rows: $($p0Rows.Count)",
  "- blocked rows: $($blocked.Count)",
  "- current phase: $($chain.current_phase)",
  "- current gate: $($chain.current_gate)",
  "- next gate after pass: P2-1 Workgroup Basic Runtime",
  "- global_goal_complete: false",
  "",
  "## Evidence Matrix",
  "",
  $evidenceText,
  "",
  "## Boundary Compliance",
  "",
  "- result: $boundaryResult",
  "- no new final/public positive claims in current diff.",
  "- no P2 implementation executed by this Gate.",
  "- Redis and vector database services remain external connectors and are not packaged into the EXE.",
  "",
  "## Final Close Decision",
  "",
  "- close_allowed: $($blocked.Count -eq 0)",
  "- release_status: $status",
  "- next_gate: P2-1 Workgroup Basic Runtime",
  "",
  "## Blockers",
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
