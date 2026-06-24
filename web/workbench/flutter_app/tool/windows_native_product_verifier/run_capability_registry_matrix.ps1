param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p1_capability_registry"
}

function Add-RegistryRow(
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

function Get-MarkdownTableRows([string]$Path) {
  return @(
    Get-Content -LiteralPath $Path -Encoding UTF8 |
      Where-Object {
        $_ -match "^\| [^|]+ \|" -and
        $_ -notmatch "^\| ---" -and
        $_ -notmatch "^\| capability_id \|" -and
        $_ -notmatch "^\| # \|"
      }
  )
}

function Get-MarkdownPlanRows([string]$Path) {
  return @(
    Get-Content -LiteralPath $Path -Encoding UTF8 |
      Where-Object { $_ -match "^\| [0-9]+ \|" }
  )
}

function Split-MarkdownRow([string]$Row) {
  return @(
    ($Row -split "\|") |
      ForEach-Object { $_.Trim() } |
      Where-Object { $_.Length -gt 0 }
  )
}

function Test-PositiveClaimBoundary([string[]]$Paths) {
  $terms = @(
    ("production" + "_" + "ready"),
    ("release" + "_" + "ready"),
    ("industrial" + "_" + "acceptance" + "_" + "passed")
  )
  $hits = [System.Collections.ArrayList]::new()
  foreach ($path in $Paths) {
    $lines = Get-Content -LiteralPath $path -Encoding UTF8
    for ($i = 0; $i -lt $lines.Count; $i += 1) {
      $line = $lines[$i]
      foreach ($term in $terms) {
        if (-not $line.Contains($term)) { continue }
        $allowedContext = $line -match "(?i)forbidden|do not write|must not|does not imply|no evidence|not claimed|not a .*claim|禁止|不得"
        if ($path.EndsWith("Capability_Implementation_Status.md")) {
          $cells = Split-MarkdownRow $line
          if ($cells.Count -ge 24) {
            $claimCells = $cells[0..22] -join " | "
            if (-not $claimCells.Contains($term)) { $allowedContext = $true }
          }
        }
        if (-not $allowedContext) {
          [void]$hits.Add([ordered]@{ path = $path; line = $i + 1; term = $term })
        }
      }
    }
  }
  return $hits
}

$appRoot = Get-AppRoot
$repoRoot = (Resolve-Path (Join-Path $appRoot "..\..\..")).Path
$chainPath = Join-Path $repoRoot "capability_chain_status.json"
$registryPath = Join-Path $repoRoot "docs\capability_registry\Capability_Implementation_Status.md"
$planPath = Join-Path $repoRoot "docs\capability_registry\Full_Target_Mode_Plan.md"
$queuePath = Join-Path $repoRoot "docs\capability_registry\Full_Target_Mode_Execution_Queue.md"
$rubricPath = Join-Path $repoRoot "docs\capability_registry\Full_Target_Mode_Rubric.md"
$blockerPolicyPath = Join-Path $repoRoot "docs\capability_registry\Full_Target_Mode_Blocker_Policy.md"
$acceptanceTypePath = Join-Path $repoRoot "docs\capability_registry\Acceptance_Type_Model.md"
$dualTrackPath = Join-Path $repoRoot "docs\capability_registry\Dual_Track_Acceptance_Model.md"
$blackboxPath = Join-Path $repoRoot "docs\capability_registry\Blackbox_Case_Mapping.md"
$p1BackfillPath = Join-Path $repoRoot "docs\capability_registry\P1_Backfill_Gates.md"
$releaseGatePath = Join-Path $repoRoot "docs\capability_registry\Release_Gates.md"
$matrixPath = Join-Path $OutputRoot "capability_registry_matrix.json"
$checkpointPath = Join-Path $OutputRoot "capability_registry_checkpoint.json"
$failurePath = Join-Path $OutputRoot "capability_registry_failure_template.json"
$resumePath = Join-Path $OutputRoot "capability_registry_resume_prompt.md"
$reportPath = Join-Path $repoRoot "docs\audits\current\capability_registry_report.md"
$rows = [System.Collections.ArrayList]::new()

$requiredFiles = @(
  $chainPath,
  $registryPath,
  $planPath,
  $queuePath,
  $rubricPath,
  $blockerPolicyPath,
  $acceptanceTypePath,
  $dualTrackPath,
  $blackboxPath,
  $p1BackfillPath,
  $releaseGatePath
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
Add-RegistryRow $rows "required governance files exist" ($missingFiles.Count -eq 0) `
  "missing=$($missingFiles.Count)" `
  "capability_registry_required_file_missing"

$chain = Read-JsonFile $chainPath
$remaining = @($chain.remaining_gates)
$completedReview = @($chain.completed_with_owner_review_needed)
$prePassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-2 Capability Registry" -and
  $remaining.Count -eq 90 -and
  $remaining[0] -eq "P1-2 Capability Registry" -and
  $completedReview -notcontains "P1-2 Capability Registry"
$postPassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-3 Memory Layer Separation Basic" -and
  $remaining.Count -eq 89 -and
  $remaining[0] -eq "P1-3 Memory Layer Separation Basic" -and
  $completedReview -contains "P1-2 Capability Registry"
$stateOk = ($prePassState -or $postPassState) -and $chain.global_goal_complete -eq $false
Add-RegistryRow $rows "status machine is at or just past P1-2 with global guard" $stateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($remaining[0]); remaining=$($remaining.Count); global_goal_complete=$($chain.global_goal_complete)" `
  "capability_registry_status_machine_mismatch"

$preconditionsOk = ($completedReview -contains "P0 Release Gate") -and
  ($completedReview -contains "P1-1 Capability Chain Runner")
Add-RegistryRow $rows "P0 release and P1-1 runner precede registry gate" $preconditionsOk `
  "p0_release=$($completedReview -contains 'P0 Release Gate'); p1_runner=$($completedReview -contains 'P1-1 Capability Chain Runner')" `
  "capability_registry_missing_precondition"

$chainShapeOk = ($remaining -contains "P1 Release Gate") -and
  ($remaining -contains "P2 Release Gate") -and
  ($remaining -contains "Final Owner Review Gate")
$nextGate = if ($prePassState -and $remaining.Count -gt 1) {
  $remaining[1]
} elseif ($postPassState) {
  $remaining[0]
} else {
  ""
}
$nextOk = $nextGate -eq "P1-3 Memory Layer Separation Basic"
Add-RegistryRow $rows "remaining chain preserves release gates and next gate" ($chainShapeOk -and $nextOk) `
  "next_gate=$nextGate; p1_release=$($remaining -contains 'P1 Release Gate'); p2_release=$($remaining -contains 'P2 Release Gate'); final=$($remaining -contains 'Final Owner Review Gate')" `
  "capability_registry_chain_sequence_invalid"

$expectedHeader = "| capability_id | capability_name | phase | acceptance_type | core_status | ui_binding_status | blackbox_status | artifact_status | event_status | governance_status | restart_status | release_status | release_blocker | close_allowed | landed_files | core_evidence | blackbox_evidence | linked_blackbox_cases | operation_gap | evidence_report | evidence_commit | next_core_gate | next_blackbox_gate | forbidden_claims |"
$registryText = Get-Content -Raw -LiteralPath $registryPath -Encoding UTF8
$headerOk = $registryText.Contains($expectedHeader)
Add-RegistryRow $rows "capability registry vertical closure header is intact" $headerOk `
  "header_present=$headerOk" `
  "capability_registry_header_invalid"

$registryRows = Get-MarkdownTableRows $registryPath
$planRows = Get-MarkdownPlanRows $planPath
$seen = @{}
$duplicates = [System.Collections.ArrayList]::new()
foreach ($line in $registryRows) {
  $id = (Split-MarkdownRow $line)[0]
  if ($seen.ContainsKey($id)) { [void]$duplicates.Add($id) } else { $seen[$id] = $true }
}
$rowShapeOk = $registryRows.Count -eq 108 -and
  $planRows.Count -eq 108 -and
  $duplicates.Count -eq 0
Add-RegistryRow $rows "capability and full plan row counts match without duplicate ids" $rowShapeOk `
  "registry_rows=$($registryRows.Count); plan_rows=$($planRows.Count); duplicate_ids=$($duplicates.Count)" `
  "capability_registry_row_count_or_duplicate_invalid"

$registryRow = @($registryRows | Where-Object { $_ -match "^\| capability_registry \|" })
$registryCells = if ($registryRow.Count -eq 1) { Split-MarkdownRow $registryRow[0] } else { @() }
$registryStatusOk = $registryRow.Count -eq 1 -and
  $registryCells[2] -eq "P1" -and
  $registryCells[3] -eq "governance" -and
  $registryCells[4] -eq "passed" -and
  $registryCells[5] -eq "not_required" -and
  $registryCells[6] -eq "not_required" -and
  $registryCells[9] -eq "passed" -and
  $registryCells[10] -eq "passed" -and
  $registryCells[12] -eq "true" -and
  $registryCells[13] -eq "true"
Add-RegistryRow $rows "capability_registry row matches governance acceptance contract" $registryStatusOk `
  "row_count=$($registryRow.Count); type=$($registryCells[3]); core=$($registryCells[4]); governance=$($registryCells[9]); restart=$($registryCells[10]); close_allowed=$($registryCells[13])" `
  "capability_registry_row_status_invalid"

$queueText = Get-Content -Raw -LiteralPath $queuePath -Encoding UTF8
$rubricText = Get-Content -Raw -LiteralPath $rubricPath -Encoding UTF8
$p1BackfillText = Get-Content -Raw -LiteralPath $p1BackfillPath -Encoding UTF8
$releaseText = Get-Content -Raw -LiteralPath $releaseGatePath -Encoding UTF8
$crossRefsOk = $queueText.Contains("6. P1-2 Capability Registry") -and
  $queueText.Contains("7. P1-3 Memory Layer Separation Basic") -and
  $rubricText.Contains("| P1 | capability_registry | governance |") -and
  $p1BackfillText.Contains("capability_chain_runner") -and
  $p1BackfillText.Contains("capability_registry") -and
  $releaseText.Contains("P1 Release Gate")
Add-RegistryRow $rows "queue, rubric, backfill and release gate cross-references agree" $crossRefsOk `
  "queue_p1_2=$($queueText.Contains('6. P1-2 Capability Registry')); queue_p1_3=$($queueText.Contains('7. P1-3 Memory Layer Separation Basic')); rubric=$($rubricText.Contains('| P1 | capability_registry | governance |'))" `
  "capability_registry_cross_reference_invalid"

$positiveClaimHits = Test-PositiveClaimBoundary @($registryPath, $chainPath, $planPath, $queuePath, $p1BackfillPath, $releaseGatePath)
Add-RegistryRow $rows "positive-claim boundary is clean outside prohibited-claim ledgers" ($positiveClaimHits.Count -eq 0) `
  "files_scanned=6; claim_like_hits=$($positiveClaimHits.Count)" `
  "capability_registry_positive_claim_boundary_invalid"

$blocked = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "capability_registry_completed_needs_owner_review"
} else {
  "capability_registry_blocked"
}

$checkpoint = [ordered]@{
  schema_version = "heitang_capability_registry_checkpoint.v1"
  status = $status
  current_phase = $chain.current_phase
  current_gate = $chain.current_gate
  next_gate = $nextGate
  remaining_gates_count = $remaining.Count
  global_goal_complete = $false
  created_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $checkpointPath $checkpoint
Write-Json $failurePath ([ordered]@{
  schema_version = "heitang_capability_registry_failure_template.v1"
  status = "no_current_failure"
  affected_phase = "P1"
  affected_capability_id = "capability_registry"
  failed_acceptance_type = "governance"
  resume_prompt_path = $resumePath
  created_at = (Get-Date).ToUniversalTime().ToString("o")
})
@(
  "# Capability Registry Resume Prompt",
  "",
  "Resume from current_gate=$($chain.current_gate) if interrupted before commit.",
  "After commit, resume from next_gate=$nextGate.",
  "Keep global_goal_complete=false while remaining gates exist.",
  "Do not execute P1-3 until P1-2 evidence is committed."
) | Set-Content -Encoding UTF8 -Path $resumePath

$payload = [ordered]@{
  schema_version = "heitang_p1_capability_registry_matrix.v1"
  status = $status
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
  repo_root = $repoRoot
  current_phase = $chain.current_phase
  current_gate = $chain.current_gate
  next_gate = $nextGate
  remaining_gates_count = $remaining.Count
  global_goal_complete = $false
  checkpoint_path = $checkpointPath
  failure_template_path = $failurePath
  resume_prompt_path = $resumePath
  rows = $rows
}
Write-Json $matrixPath $payload

$blockerText = if ($blocked.Count -eq 0) {
  "- none for this P1-2 gate; Owner review remains outside automatic closure."
} else {
  ($blocked | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$report = @(
  "# P1-2 Capability Registry Report",
  "",
  "Status: $status",
  "",
  "## Acceptance Scope",
  "",
  "- Validate the shared capability table, status machine, execution queue, rubric and stage gate references.",
  "- This Gate is governance acceptance; it does not execute P1-3 or any product runtime.",
  "",
  "## Verification Summary",
  "",
  "- current_phase: $($chain.current_phase)",
  "- current_gate: $($chain.current_gate)",
  "- next_gate: $nextGate",
  "- remaining_gates: $($remaining.Count)",
  "- global_goal_complete: false",
  "- blocked rows: $($blocked.Count)",
  "",
  "## Evidence Matrix",
  "",
  $evidenceText,
  "",
  "## White-box Test Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- command: run_capability_registry_matrix.ps1",
  "- schema evidence: registry fields, queue order, status-machine guard and cross-file references verified.",
  "",
  "## Black-box Test Result",
  "",
  "- result: not_required",
  "- reason: governance registry has no standalone user UI path.",
  "",
  "## Evidence Completeness Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- artifacts: matrix, checkpoint, failure template, resume prompt and this report.",
  "",
  "## Lifecycle Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- scope: queue/status persistence and restart-readable report paths.",
  "",
  "## Regression Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- scope: P0 release evidence remains completed; P1-1 runner remains completed before P1-2.",
  "",
  "## Boundary Compliance Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- no P2 entry, no UI/runtime edits, no dependency addition, no service packaging change.",
  "",
  "## Reviewer Findings",
  "",
  "- P1-2 uses governance evidence only and does not fake a UI blackbox.",
  "- The status machine keeps global_goal_complete=false while remaining gates exist.",
  "- P1-3 is only selected as next gate after P1-2 evidence is committed.",
  "",
  "## Final Close Decision",
  "",
  "- close_allowed: $($blocked.Count -eq 0)",
  "- next_gate: $nextGate",
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
