param(
  [string]$OutputRoot = "",
  [string]$UiFullCampaignResult = "",
  [string]$PackagingResult = "",
  [string]$ExternalSourceEvidenceRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p2_release"
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
      if ($candidate -match "^[A-Za-z]:[\\/].+" -or
          ($candidate -match "^[A-Za-z0-9_./\\:-]+$" -and ($candidate.Contains("/") -or $candidate.Contains("\")))) {
        [void]$tokens.Add($candidate)
      }
    }
  }
  return @($tokens | Where-Object { $_ -and $_ -ne "none" } | Select-Object -Unique)
}

function Resolve-EvidencePath([string]$RepoRoot, [string]$AppRoot, [string]$Token) {
  $normalized = $Token -replace "/", "\"
  if ([System.IO.Path]::IsPathRooted($normalized)) {
    if (Test-Path -LiteralPath $normalized) { return $normalized }
    return ""
  }
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

function Find-LatestJson([string]$Root, [string]$Name) {
  if ([string]::IsNullOrWhiteSpace($Root) -or -not (Test-Path -LiteralPath $Root)) { return "" }
  $match = Get-ChildItem -LiteralPath $Root -Recurse -Filter $Name -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  if ($match) { return $match.FullName }
  return ""
}

function Test-JsonStatus([string]$Path, [string[]]$AllowedStatuses, [string[]]$AllowedFinalStatuses) {
  if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
    return [ordered]@{ passed = $false; actual = "missing:$Path" }
  }
  $json = Read-JsonFile $Path
  if ($null -eq $json) { return [ordered]@{ passed = $false; actual = "unreadable:$Path" } }
  $status = [string]$json.status
  $finalStatus = [string]$json.final_status
  $statusOk = [string]::IsNullOrWhiteSpace($status) -or $AllowedStatuses.Contains($status)
  $finalOk = [string]::IsNullOrWhiteSpace($finalStatus) -or $AllowedFinalStatuses.Contains($finalStatus)
  return [ordered]@{
    passed = ($statusOk -and $finalOk)
    actual = "path=$Path; status=$status; final_status=$finalStatus"
  }
}

$appRoot = Get-AppRoot
$repoRoot = (Resolve-Path (Join-Path $appRoot "..\..\..")).Path
$matrixPath = Join-Path $OutputRoot "p2_release_gate_matrix.json"
$reportPath = Join-Path $repoRoot "docs\audits\current\p2_release_gate_closure_report.md"
$registryPath = Join-Path $repoRoot "docs\capability_registry\Capability_Implementation_Status.md"
$chainPath = Join-Path $repoRoot "capability_chain_status.json"
$p0ReleaseMatrixPath = Join-Path $appRoot "output\p0_release\p0_release_gate_matrix.json"
$p1ReleaseMatrixPath = Join-Path $appRoot "output\p1_release\p1_release_gate_matrix.json"
$p0ReleaseReportPath = Join-Path $repoRoot "docs\audits\current\p0_release_gate_closure_report.md"
$p1ReleaseReportPath = Join-Path $repoRoot "docs\audits\current\p1_release_gate_closure_report.md"
if ([string]::IsNullOrWhiteSpace($UiFullCampaignResult)) {
  $UiFullCampaignResult = Find-LatestJson (Join-Path $appRoot "output\p2_release_gate\ui") "ui_full_campaign_results.json"
}
if ([string]::IsNullOrWhiteSpace($PackagingResult)) {
  $PackagingResult = Find-LatestJson (Join-Path $appRoot "output\p2_release_gate\packaging") "windows_native_product_verifier_result.json"
}
if ([string]::IsNullOrWhiteSpace($ExternalSourceEvidenceRoot)) {
  $ExternalSourceEvidenceRoot = Join-Path $appRoot "output\p2_release_gate\external_source"
}

$rows = [System.Collections.ArrayList]::new()
$capabilityRows = @(Read-CapabilityRows $registryPath)
$p0Rows = @($capabilityRows | Where-Object { $_.phase -eq "P0" })
$p1Rows = @($capabilityRows | Where-Object { $_.phase -eq "P1" })
$p2Rows = @($capabilityRows | Where-Object { $_.phase -eq "P2" })
$p2RowsBeforeGate = @($p2Rows | Where-Object { $_.capability_id -ne "p2_release_gate" })
$validTypes = @("user_blackbox", "core_only", "artifact", "governance", "composite")
$chain = Read-JsonFile $chainPath

$p2ReleaseGateActiveOk = $chain.current_gate -eq "P2 Release Gate" -and
  $chain.current_phase -eq "P2" -and
  $chain.remaining_gates[0] -eq "P2 Release Gate"
$p2ReleaseGateAdvancedOk = $chain.current_gate -eq "Final Owner Review Gate" -and
  $chain.current_phase -eq "Release" -and
  $chain.remaining_gates[0] -eq "Final Owner Review Gate" -and
  $chain.completed_with_owner_review_needed -contains "P2 Release Gate"
$currentGateOk = ($p2ReleaseGateActiveOk -or $p2ReleaseGateAdvancedOk) -and
  $chain.global_goal_complete -eq $false
Add-GateRow $rows "status machine is at or has passed P2 Release Gate" $currentGateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($chain.remaining_gates[0]); global_goal_complete=$($chain.global_goal_complete)" `
  "p2_release_gate_status_machine_mismatch"

foreach ($release in @(
  @{ name = "P0"; matrix = $p0ReleaseMatrixPath; report = $p0ReleaseReportPath; status = "p0_release_gate_passed_needs_owner_review" },
  @{ name = "P1"; matrix = $p1ReleaseMatrixPath; report = $p1ReleaseReportPath; status = "p1_release_gate_passed_needs_owner_review" }
)) {
  $ok = (Test-Path -LiteralPath $release.matrix) -and (Test-Path -LiteralPath $release.report)
  if ($ok) {
    $matrix = Read-JsonFile $release.matrix
    $ok = $matrix.status -eq $release.status -and
      @($matrix.rows | Where-Object { $_.status -eq "blocked" }).Count -eq 0
  }
  Add-GateRow $rows "$($release.name) Release Gate regression evidence exists and has no blockers" $ok `
    "matrix=$($release.matrix); report=$($release.report)" `
    "$($release.name.ToLowerInvariant())_release_regression_missing"
}

foreach ($phase in @("P0", "P1", "P2")) {
  $phaseRows = @($capabilityRows | Where-Object {
    $_.phase -eq $phase -and
      $_.capability_id -notin @("p0_release_gate", "p1_release_gate", "p2_release_gate")
  })
  $typeRowsOk = @($phaseRows | Where-Object { $validTypes -notcontains $_.acceptance_type }).Count -eq 0
  Add-GateRow $rows "$phase rows have valid acceptance types" $typeRowsOk `
    "rows=$($phaseRows.Count)" `
    "$($phase.ToLowerInvariant())_acceptance_type_invalid"

  $notClosed = @($phaseRows | Where-Object { $_.close_allowed -ne "true" })
  Add-GateRow $rows "$phase rows before release gate are close_allowed" ($notClosed.Count -eq 0) `
    "not_closed=$($notClosed.capability_id -join ',')" `
    "$($phase.ToLowerInvariant())_close_allowed_missing"

  $statusFailures = New-Object System.Collections.Generic.List[string]
  foreach ($row in $phaseRows) {
    if (-not (Test-AcceptanceTypeStatus $row)) {
      [void]$statusFailures.Add($row.capability_id)
    }
  }
  Add-GateRow $rows "$phase acceptance-type status requirements pass" ($statusFailures.Count -eq 0) `
    "failed=$($statusFailures -join ',')" `
    "$($phase.ToLowerInvariant())_acceptance_status_incomplete"
}

$missingEvidence = New-Object System.Collections.Generic.List[string]
foreach ($row in $p2RowsBeforeGate) {
  $tokens = @(Get-EvidenceTokens $row)
  $existing = @($tokens | ForEach-Object { Resolve-EvidencePath $repoRoot $appRoot $_ } | Where-Object { $_ })
  if ($existing.Count -eq 0) { [void]$missingEvidence.Add($row.capability_id) }
  if ([string]$row.evidence_commit -eq "none") { [void]$missingEvidence.Add("$($row.capability_id):commit") }
}
Add-GateRow $rows "P2 evidence paths and commit fields exist" ($missingEvidence.Count -eq 0) `
  "missing=$($missingEvidence -join ',')" `
  "p2_evidence_incomplete"

$uiResult = Test-JsonStatus $UiFullCampaignResult @("passed") @()
Add-GateRow $rows "final UI full campaign matrix passes" $uiResult.passed `
  $uiResult.actual `
  "p2_release_final_ui_blackbox_missing"

$packagingResultCheck = Test-JsonStatus $PackagingResult @() @("windows_packaging_baseline_smoke_passed")
Add-GateRow $rows "final Windows packaging/config/permission/restart boundary smoke passes" $packagingResultCheck.passed `
  $packagingResultCheck.actual `
  "p2_release_final_packaging_missing"

$externalTrace = Join-Path $ExternalSourceEvidenceRoot "source_trace.jsonl"
$externalEvidenceMap = Join-Path $ExternalSourceEvidenceRoot "evidence_map.json"
$externalValidation = Join-Path $ExternalSourceEvidenceRoot "validation_report.json"
$externalUiReport = Join-Path $ExternalSourceEvidenceRoot "ordinary_ui_external_source_verification_report.json"
$externalSourceOk = (Test-Path -LiteralPath $externalTrace) -and
  (Test-Path -LiteralPath $externalEvidenceMap) -and
  (Test-Path -LiteralPath $externalValidation) -and
  (Test-Path -LiteralPath $externalUiReport)
if ($externalSourceOk) {
  $validation = Read-JsonFile $externalValidation
  $uiReport = Read-JsonFile $externalUiReport
  $externalSourceOk = $validation.status -eq "passed" -and
    $uiReport.status -eq "passed" -and
    $uiReport.ordinary_ui_path_verified -eq $true -and
    $uiReport.implementation_name_leakage -eq $false
}
Add-GateRow $rows "ordinary UI external source verification evidence exists" $externalSourceOk `
  "root=$ExternalSourceEvidenceRoot; source_trace=$externalTrace; evidence_map=$externalEvidenceMap; validation_report=$externalValidation; ui_report=$externalUiReport" `
  "p2_release_external_source_ui_evidence_missing"

$claimA = "production" + "_" + "ready"
$claimB = "release" + "_" + "ready"
$claimC = "industrial" + "_" + "acceptance" + "_" + "passed"
$authHeaderPattern = "Authorization" + ":"
$cookieHeaderPattern = "Cookie" + ":"
$secretPatterns = @("sk-[A-Za-z0-9]", "api[_-]?key\s*=", "token\s*=", $authHeaderPattern, $cookieHeaderPattern)
$newClaimMatches = @()
$secretMatches = @()
$diff = & git -C $repoRoot diff --unified=0
foreach ($line in $diff) {
  if ($line.StartsWith("+") -and -not $line.StartsWith("+++")) {
    foreach ($claim in @($claimA, $claimB, $claimC)) {
      if ($line.Contains($claim)) { $newClaimMatches += $claim }
    }
    foreach ($pattern in $secretPatterns) {
      if ($line -match $pattern) { $secretMatches += $pattern }
    }
  }
}
Add-GateRow $rows "no new forbidden final/public claims in current diff" ($newClaimMatches.Count -eq 0) `
  "new_claim_matches=$($newClaimMatches.Count)" `
  "p2_release_gate_forbidden_claim_added"
Add-GateRow $rows "no obvious plaintext secrets in current diff" ($secretMatches.Count -eq 0) `
  "secret_pattern_matches=$($secretMatches.Count)" `
  "p2_release_gate_secret_leakage"

$gitDirty = @(& git -C $repoRoot status --short --untracked-files=all)
$partitionOk = $gitDirty.Count -eq 0 -or @($gitDirty | Where-Object {
  $_ -match "p2_release_gate|Capability_Implementation_Status.md|capability_chain_status.json|run_p2_release_gate_matrix.ps1|PRE_LAUNCH_FINAL_ACCEPTANCE_RELEASE_DATA_AND_LAUNCH_READINESS_DRILL.md|POST_P2_UI_POLISH_AND_CLOSURE_PLAN.md|workgroup_basic_runtime_preclosure_partition_report.md"
}).Count -eq $gitDirty.Count
Add-GateRow $rows "workspace clean or explicitly partitioned for P2 Release Gate" $partitionOk `
  "dirty_count=$($gitDirty.Count); dirty=$($gitDirty -join ' | ')" `
  "p2_release_gate_worktree_pollution"

$blocked = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "p2_release_gate_passed_needs_owner_review"
} else {
  "p2_release_gate_blocked"
}
$payload = [ordered]@{
  schema_version = "heitang_p2_release_gate_matrix.v1"
  status = $status
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
  repo_root = $repoRoot
  current_gate = $chain.current_gate
  current_phase = $chain.current_phase
  phase_after_pass = "Release"
  next_gate = "Final Owner Review Gate"
  global_goal_complete = $false
  p0_row_count = $p0Rows.Count
  p1_row_count = $p1Rows.Count
  p2_row_count = $p2Rows.Count
  p2_rows_before_gate = $p2RowsBeforeGate.Count
  p0_release_matrix_path = $p0ReleaseMatrixPath
  p1_release_matrix_path = $p1ReleaseMatrixPath
  ui_full_campaign_result = $UiFullCampaignResult
  packaging_result = $PackagingResult
  external_source_evidence_root = $ExternalSourceEvidenceRoot
  rows = $rows
}
Write-Json $matrixPath $payload

$blockerText = if ($blocked.Count -eq 0) {
  "- none for this P2 Release Gate."
} else {
  ($blocked | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$boundaryResult = if ($blocked.Count -eq 0) { "passed" } else { "blocked" }
$report = @(
  "# P2 Release Gate Closure Report",
  "",
  "Status: $status",
  "",
  "## Acceptance Scope",
  "",
  "- Validate P2 capability rows, P0 and P1 release regression evidence, final UI blackbox evidence, final Windows packaging/config/permission/restart smoke, ordinary UI external source verification evidence, queue state, evidence paths and current-gate worktree partition.",
  "- This Gate is a staged phase-exit gate, not a public release or final acceptance claim.",
  "- This Gate does not execute Final Owner Review.",
  "",
  "## Verification Summary",
  "",
  "- p0 rows: $($p0Rows.Count)",
  "- p1 rows: $($p1Rows.Count)",
  "- p2 rows: $($p2Rows.Count)",
  "- p2 rows before release gate: $($p2RowsBeforeGate.Count)",
  "- blocked rows: $($blocked.Count)",
  "- current phase: $($chain.current_phase)",
  "- current gate: $($chain.current_gate)",
  "- next gate after pass: Final Owner Review Gate",
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
  "- no obvious plaintext secrets in current diff.",
  "- Redis and vector database services remain external connectors and are not packaged into the EXE.",
  "- isolated planning/audit drafts are not used as release-gate evidence.",
  "",
  "## Final Close Decision",
  "",
  "- close_allowed: $($blocked.Count -eq 0)",
  "- release_status: $status",
  "- next_gate: Final Owner Review Gate",
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
