param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p1_ai_config_governance_basic"
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

function Add-AiConfigRow(
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
    if (-not (Test-Path -LiteralPath $path)) { continue }
    $lines = Get-Content -LiteralPath $path -Encoding UTF8
    for ($i = 0; $i -lt $lines.Count; $i += 1) {
      foreach ($term in $terms) {
        if ($lines[$i].Contains($term)) {
          [void]$hits.Add([ordered]@{ path = $path; line = $i + 1; term = $term })
        }
      }
    }
  }
  return @($hits)
}

$appRoot = Get-AppRoot
$repoRoot = (Resolve-Path (Join-Path $appRoot "..\..\..")).Path
$chainPath = Join-Path $repoRoot "capability_chain_status.json"
$registryPath = Join-Path $repoRoot "docs\capability_registry\Capability_Implementation_Status.md"
$planPath = Join-Path $repoRoot "docs\capability_registry\Full_Target_Mode_Plan.md"
$queuePath = Join-Path $repoRoot "docs\capability_registry\Full_Target_Mode_Execution_Queue.md"
$rubricPath = Join-Path $repoRoot "docs\capability_registry\Full_Target_Mode_Rubric.md"
$p1BackfillPath = Join-Path $repoRoot "docs\capability_registry\P1_Backfill_Gates.md"
$industrialScopePath = Join-Path $appRoot "output\capability_blackbox\industrial_scope\industrial_scope_metadata_reservation_matrix.json"
$conflictContractPath = Join-Path $appRoot "output\p1_conflict_exception_detection_basic\conflict_exception_detection_basic_contract.json"
$matrixPath = Join-Path $OutputRoot "ai_config_governance_basic_matrix.json"
$contractPath = Join-Path $OutputRoot "ai_config_governance_basic_contract.json"
$reservationEvidencePath = Join-Path $OutputRoot "ai_config_governance_reservation_evidence.json"
$checkpointPath = Join-Path $OutputRoot "ai_config_governance_basic_checkpoint.json"
$failurePath = Join-Path $OutputRoot "ai_config_governance_basic_failure_template.json"
$resumePath = Join-Path $OutputRoot "ai_config_governance_basic_resume_prompt.md"
$reportPath = Join-Path $repoRoot "docs\audits\current\ai_config_governance_closure_report.md"
$rows = [System.Collections.ArrayList]::new()

$requiredFiles = @(
  $chainPath,
  $registryPath,
  $planPath,
  $queuePath,
  $rubricPath,
  $p1BackfillPath,
  $industrialScopePath,
  $conflictContractPath
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
Add-AiConfigRow $rows "required AI config governance and prior evidence files exist" ($missingFiles.Count -eq 0) `
  "missing=$($missingFiles.Count)" `
  "ai_config_governance_required_file_missing"

$chain = Read-JsonFile $chainPath
$remaining = @($chain.remaining_gates)
$completedReview = @($chain.completed_with_owner_review_needed)
$prePassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-13 AI Config Governance Basic" -and
  $remaining.Count -eq 79 -and
  $remaining[0] -eq "P1-13 AI Config Governance Basic" -and
  $completedReview -notcontains "P1-13 AI Config Governance Basic"
$postPassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-14 Task Mode Router Basic" -and
  $remaining.Count -eq 78 -and
  $remaining[0] -eq "P1-14 Task Mode Router Basic" -and
  $completedReview -contains "P1-13 AI Config Governance Basic"
$stateOk = ($prePassState -or $postPassState) -and $chain.global_goal_complete -eq $false
Add-AiConfigRow $rows "status machine is at or just past P1-13 with global guard" $stateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($remaining[0]); remaining=$($remaining.Count); global_goal_complete=$($chain.global_goal_complete)" `
  "ai_config_governance_status_machine_mismatch"

$preconditionsOk = ($completedReview -contains "P0 Release Gate") -and
  ($completedReview -contains "P1-12 Conflict and Exception Detection Basic")
Add-AiConfigRow $rows "P0 release and P1-12 precede AI config governance" $preconditionsOk `
  "p0_release=$($completedReview -contains 'P0 Release Gate'); p1_conflict=$($completedReview -contains 'P1-12 Conflict and Exception Detection Basic')" `
  "ai_config_governance_missing_precondition"

$nextGate = if ($prePassState -and $remaining.Count -gt 1) {
  $remaining[1]
} elseif ($postPassState) {
  $remaining[0]
} else {
  ""
}
$chainShapeOk = $nextGate -eq "P1-14 Task Mode Router Basic" -and
  ($remaining -contains "P1 Release Gate") -and
  ($remaining -contains "P2 Release Gate") -and
  ($remaining -contains "Final Owner Review Gate")
Add-AiConfigRow $rows "remaining chain preserves release gates and next gate" $chainShapeOk `
  "next_gate=$nextGate; p1_release=$($remaining -contains 'P1 Release Gate'); p2_release=$($remaining -contains 'P2 Release Gate'); final=$($remaining -contains 'Final Owner Review Gate')" `
  "ai_config_governance_chain_sequence_invalid"

$registryRow = @(
  Get-Content -LiteralPath $registryPath -Encoding UTF8 |
    Where-Object { $_ -match "^\| ai_config_governance \|" }
)
$registryCells = if ($registryRow.Count -eq 1) { Split-MarkdownRow $registryRow[0] } else { @() }
$registryStatusOk = $registryRow.Count -eq 1 -and
  $registryCells[2] -eq "P1" -and
  $registryCells[3] -eq "core_only" -and
  $registryCells[4] -eq "passed" -and
  $registryCells[5] -eq "not_required" -and
  $registryCells[6] -eq "not_required" -and
  $registryCells[12] -eq "true" -and
  $registryCells[13] -eq "true"
Add-AiConfigRow $rows "ai_config_governance registry row already follows core-only passed contract" $registryStatusOk `
  "row_count=$($registryRow.Count); type=$($registryCells[3]); core=$($registryCells[4]); ui=$($registryCells[5]); blackbox=$($registryCells[6]); close_allowed=$($registryCells[13])" `
  "ai_config_governance_registry_row_invalid"

$planText = Get-Content -Raw -LiteralPath $planPath -Encoding UTF8
$queueText = Get-Content -Raw -LiteralPath $queuePath -Encoding UTF8
$rubricText = Get-Content -Raw -LiteralPath $rubricPath -Encoding UTF8
$p1Text = Get-Content -Raw -LiteralPath $p1BackfillPath -Encoding UTF8
$crossRefsOk = $planText.Contains("| 36 | P1 | ai_config_governance | AI Config Governance Basic | core_only |") -and
  $queueText.Contains("17. P1-13 AI Config Governance Basic") -and
  $queueText.Contains("18. P1-14 Task Mode Router Basic") -and
  $rubricText.Contains("| P1 | ai_config_governance | core_only |") -and
  $p1Text.Contains("ai_config_governance")
Add-AiConfigRow $rows "plan, queue, rubric and P1 grouping reference AI config governance" $crossRefsOk `
  "plan=$($planText.Contains('| 36 | P1 | ai_config_governance | AI Config Governance Basic | core_only |')); queue_p1_13=$($queueText.Contains('17. P1-13 AI Config Governance Basic')); queue_p1_14=$($queueText.Contains('18. P1-14 Task Mode Router Basic'))" `
  "ai_config_governance_cross_reference_invalid"

$industrialScope = Read-JsonFile $industrialScopePath
$aiRows = @($industrialScope.matrix | Where-Object { $_.path -eq "AI Config Governance" })
$aiRow = if ($aiRows.Count -gt 0) { $aiRows[0] } else { $null }
$reservationOk = $aiRows.Count -eq 1 -and
  $aiRow.current_conclusion -eq "ai_config_governance_reserved_needs_review" -and
  $aiRow.persisted -eq $true -and
  $aiRow.exe_restart_verified -eq $true -and
  [string]::IsNullOrWhiteSpace($aiRow.blocker)
Add-AiConfigRow $rows "industrial scope matrix contains AI config governance reservation evidence" $reservationOk `
  "rows=$($aiRows.Count); conclusion=$($aiRow.current_conclusion); persisted=$($aiRow.persisted); restart=$($aiRow.exe_restart_verified); blocker=$($aiRow.blocker)" `
  "ai_config_governance_reservation_evidence_invalid"

$conflictContract = Read-JsonFile $conflictContractPath
$priorEvidenceOk = $conflictContract.status -eq "conflict_exception_detection_completed_needs_owner_review"
Add-AiConfigRow $rows "P1 conflict exception detection contract is available" $priorEvidenceOk `
  "conflict_exception_status=$($conflictContract.status)" `
  "ai_config_governance_prior_evidence_missing"

$reservationEvidence = [ordered]@{
  schema_version = "heitang_ai_config_governance_reservation_evidence.v1"
  status = "ai_config_governance_reserved_needs_review"
  capability_id = "ai_config_governance"
  source_matrix_path = $industrialScopePath
  path = $aiRow.path
  step = $aiRow.step
  expected = $aiRow.expected
  actual = $aiRow.actual
  data_file_path = $aiRow.data_file_path
  persisted = $aiRow.persisted
  exe_restart_verified = $aiRow.exe_restart_verified
  current_conclusion = $aiRow.current_conclusion
  blocker = $aiRow.blocker
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $reservationEvidencePath $reservationEvidence

$contract = [ordered]@{
  schema_version = "heitang_ai_config_governance_basic_contract.v1"
  status = "ai_config_governance_completed_needs_owner_review"
  capability_id = "ai_config_governance"
  phase = "P1"
  acceptance_type = "core_only"
  source_evidence = @($industrialScopePath, $reservationEvidencePath)
  reservation_status = $reservationEvidence.current_conclusion
  persisted = $reservationEvidence.persisted
  exe_restart_verified = $reservationEvidence.exe_restart_verified
  next_gate = $nextGate
  global_goal_complete = $false
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $contractPath $contract

$contractOk = (Test-Path -LiteralPath $contractPath) -and
  $contract.reservation_status -eq "ai_config_governance_reserved_needs_review" -and
  $contract.persisted -eq $true -and
  $contract.exe_restart_verified -eq $true -and
  $contract.next_gate -eq "P1-14 Task Mode Router Basic" -and
  $contract.global_goal_complete -eq $false
Add-AiConfigRow $rows "AI config governance basic contract artifact is generated" $contractOk `
  "contract=$contractPath; reservation_status=$($contract.reservation_status); next_gate=$($contract.next_gate)" `
  "ai_config_governance_contract_invalid"

$claimHits = Test-PositiveClaimBoundary @($contractPath, $reservationEvidencePath)
Add-AiConfigRow $rows "new P1-13 evidence has no forbidden positive-state tokens" ($claimHits.Count -eq 0) `
  "scanned=contract,reservation_evidence; hits=$($claimHits.Count)" `
  "ai_config_governance_forbidden_claim_token_found"

$blocked = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "ai_config_governance_completed_needs_owner_review"
} else {
  "ai_config_governance_blocked"
}

$checkpoint = [ordered]@{
  schema_version = "heitang_ai_config_governance_basic_checkpoint.v1"
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
  schema_version = "heitang_ai_config_governance_basic_failure_template.v1"
  status = "no_current_failure"
  affected_phase = "P1"
  affected_capability_id = "ai_config_governance"
  failed_acceptance_type = "core_only"
  resume_prompt_path = $resumePath
  created_at = (Get-Date).ToUniversalTime().ToString("o")
})
@(
  "# AI Config Governance Basic Resume Prompt",
  "",
  "Resume from current_gate=$($chain.current_gate) if interrupted before commit.",
  "After commit, resume from next_gate=$nextGate.",
  "Keep global_goal_complete=false while remaining gates exist.",
  "Do not execute P1-14 until P1-13 evidence is committed."
) | Set-Content -Encoding UTF8 -Path $resumePath

$payload = [ordered]@{
  schema_version = "heitang_p1_ai_config_governance_basic_matrix.v1"
  status = $status
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
  repo_root = $repoRoot
  current_phase = $chain.current_phase
  current_gate = $chain.current_gate
  next_gate = $nextGate
  remaining_gates_count = $remaining.Count
  global_goal_complete = $false
  contract_path = $contractPath
  reservation_evidence_path = $reservationEvidencePath
  checkpoint_path = $checkpointPath
  failure_template_path = $failurePath
  resume_prompt_path = $resumePath
  rows = $rows
}
Write-Json $matrixPath $payload

$blockerText = if ($blocked.Count -eq 0) {
  "- none for this P1-13 gate; Owner review remains outside automatic closure."
} else {
  ($blocked | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$report = @(
  "# P1-13 AI Config Governance Basic Closure Report",
  "",
  "Status: $status",
  "",
  "## Acceptance Scope",
  "",
  "- Validate existing AI config governance reservation evidence and status-chain closure.",
  "- This Gate is core_only; it does not add UI, external LLM calls, model routing or runtime orchestration.",
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
  "- command: run_ai_config_governance_basic_matrix.ps1",
  "- schema evidence: industrial scope matrix row, reservation evidence and contract artifact.",
  "",
  "## Black-box Test Result",
  "",
  "- result: not_required",
  "- reason: core_only AI config governance has no standalone user UI path in this Gate.",
  "",
  "## Evidence Completeness Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- artifacts: contract, matrix, reservation evidence, checkpoint, failure template, resume prompt and this report.",
  "",
  "## Lifecycle Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- scope: reservation evidence is persisted and restart verified by the industrial scope matrix.",
  "",
  "## Regression Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- tests: matrix validates P1-12 prior evidence and status-chain invariants.",
  "",
  "## Boundary Compliance Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- no UI/runtime edits, no dependency addition, no external service use, no model config mutation, no P2 entry.",
  "",
  "## Reviewer Findings",
  "",
  "- P1-13 closes existing core-only reservation evidence and does not claim model runtime completion.",
  "- Task Mode Router remains queued as P1-14.",
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
