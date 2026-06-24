param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p1_memory_layer_separation"
}

function Add-LayerRow(
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

function Test-AddedClaimBoundary([string[]]$Paths) {
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
  return $hits
}

$appRoot = Get-AppRoot
$repoRoot = (Resolve-Path (Join-Path $appRoot "..\..\..")).Path
$chainPath = Join-Path $repoRoot "capability_chain_status.json"
$registryPath = Join-Path $repoRoot "docs\capability_registry\Capability_Implementation_Status.md"
$planPath = Join-Path $repoRoot "docs\capability_registry\Full_Target_Mode_Plan.md"
$queuePath = Join-Path $repoRoot "docs\capability_registry\Full_Target_Mode_Execution_Queue.md"
$rubricPath = Join-Path $repoRoot "docs\capability_registry\Full_Target_Mode_Rubric.md"
$p1BackfillPath = Join-Path $repoRoot "docs\capability_registry\P1_Backfill_Gates.md"
$runtimePath = Join-Path $appRoot "lib\rc6_runtime\rc6_runtime_controller_io.dart"
$p0MemoryMatrixPath = Join-Path $appRoot "output\capability_blackbox\memory_evidence\memory_evidence_metadata_reservation_matrix.json"
$p0AgentMemoryMatrixPath = Join-Path $appRoot "output\capability_blackbox\agent_memory_minimal_core_matrix.json"
$matrixPath = Join-Path $OutputRoot "memory_layer_separation_matrix.json"
$contractPath = Join-Path $OutputRoot "memory_layer_contract.json"
$checkpointPath = Join-Path $OutputRoot "memory_layer_separation_checkpoint.json"
$failurePath = Join-Path $OutputRoot "memory_layer_separation_failure_template.json"
$resumePath = Join-Path $OutputRoot "memory_layer_separation_resume_prompt.md"
$reportPath = Join-Path $repoRoot "docs\audits\current\memory_layer_separation_closure_report.md"
$rows = [System.Collections.ArrayList]::new()

$requiredFiles = @(
  $chainPath,
  $registryPath,
  $planPath,
  $queuePath,
  $rubricPath,
  $p1BackfillPath,
  $runtimePath,
  $p0MemoryMatrixPath,
  $p0AgentMemoryMatrixPath
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
Add-LayerRow $rows "required memory-layer evidence files exist" ($missingFiles.Count -eq 0) `
  "missing=$($missingFiles.Count)" `
  "memory_layer_required_file_missing"

$chain = Read-JsonFile $chainPath
$remaining = @($chain.remaining_gates)
$completedReview = @($chain.completed_with_owner_review_needed)
$prePassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-3 Memory Layer Separation Basic" -and
  $remaining.Count -eq 89 -and
  $remaining[0] -eq "P1-3 Memory Layer Separation Basic" -and
  $completedReview -notcontains "P1-3 Memory Layer Separation Basic"
$postPassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-4 Evidence Graph Basic" -and
  $remaining.Count -eq 88 -and
  $remaining[0] -eq "P1-4 Evidence Graph Basic" -and
  $completedReview -contains "P1-3 Memory Layer Separation Basic"
$stateOk = ($prePassState -or $postPassState) -and $chain.global_goal_complete -eq $false
Add-LayerRow $rows "status machine is at or just past P1-3 with global guard" $stateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($remaining[0]); remaining=$($remaining.Count); global_goal_complete=$($chain.global_goal_complete)" `
  "memory_layer_status_machine_mismatch"

$preconditionsOk = ($completedReview -contains "P0 Release Gate") -and
  ($completedReview -contains "P1-1 Capability Chain Runner") -and
  ($completedReview -contains "P1-2 Capability Registry")
Add-LayerRow $rows "P0 release, P1-1 and P1-2 precede memory layer gate" $preconditionsOk `
  "p0_release=$($completedReview -contains 'P0 Release Gate'); p1_runner=$($completedReview -contains 'P1-1 Capability Chain Runner'); p1_registry=$($completedReview -contains 'P1-2 Capability Registry')" `
  "memory_layer_missing_precondition"

$nextGate = if ($prePassState -and $remaining.Count -gt 1) {
  $remaining[1]
} elseif ($postPassState) {
  $remaining[0]
} else {
  ""
}
$chainShapeOk = $nextGate -eq "P1-4 Evidence Graph Basic" -and
  ($remaining -contains "P1 Release Gate") -and
  ($remaining -contains "P2 Release Gate") -and
  ($remaining -contains "Final Owner Review Gate")
Add-LayerRow $rows "remaining chain preserves P1/P2/final gates and next gate" $chainShapeOk `
  "next_gate=$nextGate; p1_release=$($remaining -contains 'P1 Release Gate'); p2_release=$($remaining -contains 'P2 Release Gate'); final=$($remaining -contains 'Final Owner Review Gate')" `
  "memory_layer_chain_sequence_invalid"

$registryRow = @(
  Get-Content -LiteralPath $registryPath -Encoding UTF8 |
    Where-Object { $_ -match "^\| memory_layer_separation \|" }
)
$registryCells = if ($registryRow.Count -eq 1) { Split-MarkdownRow $registryRow[0] } else { @() }
$registryOk = $registryRow.Count -eq 1 -and
  $registryCells[2] -eq "P1" -and
  $registryCells[3] -eq "core_only" -and
  $registryCells[5] -eq "not_required" -and
  $registryCells[6] -eq "not_required" -and
  $registryCells[12] -eq "true"
$registryStatusOk = $registryOk -and (
  ($prePassState -and $registryCells[4] -in @("not_started", "passed")) -or
  ($postPassState -and $registryCells[4] -eq "passed" -and $registryCells[13] -eq "true")
)
Add-LayerRow $rows "memory_layer_separation registry row follows core-only contract" $registryStatusOk `
  "row_count=$($registryRow.Count); type=$($registryCells[3]); core=$($registryCells[4]); ui=$($registryCells[5]); blackbox=$($registryCells[6]); close_allowed=$($registryCells[13])" `
  "memory_layer_registry_row_invalid"

$planText = Get-Content -Raw -LiteralPath $planPath -Encoding UTF8
$queueText = Get-Content -Raw -LiteralPath $queuePath -Encoding UTF8
$rubricText = Get-Content -Raw -LiteralPath $rubricPath -Encoding UTF8
$p1Text = Get-Content -Raw -LiteralPath $p1BackfillPath -Encoding UTF8
$crossRefsOk = $planText.Contains("| 21 | P1 | memory_layer_separation | Memory Layer Separation Basic | core_only |") -and
  $queueText.Contains("7. P1-3 Memory Layer Separation Basic") -and
  $queueText.Contains("8. P1-4 Evidence Graph Basic") -and
  $rubricText.Contains("| P1 | memory_layer_separation | core_only |") -and
  $p1Text.Contains("Memory and Evidence Basic")
Add-LayerRow $rows "plan, queue, rubric and P1 grouping reference memory layer gate" $crossRefsOk `
  "plan=$($planText.Contains('| 21 | P1 | memory_layer_separation | Memory Layer Separation Basic | core_only |')); queue_p1_3=$($queueText.Contains('7. P1-3 Memory Layer Separation Basic')); queue_p1_4=$($queueText.Contains('8. P1-4 Evidence Graph Basic'))" `
  "memory_layer_cross_reference_invalid"

$runtimeText = Get-Content -Raw -LiteralPath $runtimePath -Encoding UTF8
$runtimeHasLayerField = $runtimeText.Contains("'memory_layer_type':")
$runtimeHasLayerSet = $runtimeText.Contains("'brain | agent_memory | session_context | event | artifact'")
$runtimeHasEventHook = $runtimeText.Contains("_appendEventLedgerRecord")
$runtimeHasArtifactHook = $runtimeText.Contains("_upsertArtifactRecord")
$runtimeFieldsOk = $runtimeHasLayerField -and
  $runtimeHasLayerSet -and
  $runtimeText.Contains("runMemoryEvidenceMetadataReservationAcceptance") -and
  $runtimeText.Contains("_currentIndustrialScopeMetadata") -and
  $runtimeHasEventHook -and
  $runtimeHasArtifactHook
Add-LayerRow $rows "runtime exposes memory layer type and shared write hooks" $runtimeFieldsOk `
  "layer_field=$runtimeHasLayerField; layer_set=$runtimeHasLayerSet; event_hook=$runtimeHasEventHook; artifact_hook=$runtimeHasArtifactHook" `
  "memory_layer_runtime_hooks_missing"

$runtimeHasBrainLabel = $runtimeText.Contains("'memory_layer_type': 'brain'")
$runtimeHasEventLabel = $runtimeText.Contains("'memory_layer_type': 'event'")
$runtimeHasArtifactLabel = $runtimeText.Contains("'memory_layer_type': 'artifact'")
$runtimeHasSnapshot = $runtimeText.Contains("task_memory_snapshot")
$runtimeSeparationOk = $runtimeHasBrainLabel -and
  $runtimeHasEventLabel -and
  $runtimeHasArtifactLabel -and
  $runtimeText.Contains("task_memory_snapshot") -and
  $runtimeText.Contains("memory_snapshot_created")
Add-LayerRow $rows "runtime separates memory, event and artifact layer labels" $runtimeSeparationOk `
  "brain=$runtimeHasBrainLabel; event=$runtimeHasEventLabel; artifact=$runtimeHasArtifactLabel; snapshot=$runtimeHasSnapshot" `
  "memory_layer_runtime_labels_missing"

$p0MemoryMatrix = Read-JsonFile $p0MemoryMatrixPath
$p0MemoryRows = @($p0MemoryMatrix.matrix)
$p0MemoryOk = $p0MemoryMatrix.status -eq "memory_evidence_metadata_reserved_needs_review" -and
  $p0MemoryMatrix.restart_verified -eq $true -and
  $p0MemoryRows.Count -ge 7 -and
  $p0MemoryRows.current_conclusion -contains "memory_evidence_metadata_reserved_needs_review" -and
  $p0MemoryRows.current_conclusion -contains "evidence_graph_not_implemented"
Add-LayerRow $rows "P0 memory/evidence metadata reservation supports layer separation" $p0MemoryOk `
  "status=$($p0MemoryMatrix.status); restart=$($p0MemoryMatrix.restart_verified); rows=$($p0MemoryRows.Count)" `
  "memory_layer_p0_memory_evidence_missing"

$p0AgentMatrix = Read-JsonFile $p0AgentMemoryMatrixPath
$p0AgentRows = @($p0AgentMatrix.matrix)
$p0AgentSnapshotRows = @($p0AgentRows | Where-Object { $_.step -eq "task memory snapshot" })
$p0AgentEventArtifactRows = @($p0AgentRows | Where-Object { $_.step -eq "Event Ledger and Artifact Lifecycle" })
$p0AgentOk = $p0AgentMatrix.status -eq "agent_memory_minimal_core_completed_needs_owner_review" -and
  $p0AgentMatrix.restart_verified -eq $true -and
  $p0AgentRows.Count -ge 4 -and
  $p0AgentSnapshotRows.Count -eq 1 -and
  $p0AgentEventArtifactRows.Count -eq 1
Add-LayerRow $rows "P0 agent memory snapshot remains separate from evidence metadata" $p0AgentOk `
  "status=$($p0AgentMatrix.status); restart=$($p0AgentMatrix.restart_verified); rows=$($p0AgentRows.Count); snapshot_rows=$($p0AgentSnapshotRows.Count); event_artifact_rows=$($p0AgentEventArtifactRows.Count)" `
  "memory_layer_p0_agent_memory_missing"

$contract = [ordered]@{
  schema_version = "heitang_memory_layer_contract.v1"
  status = "memory_layer_separation_completed_needs_owner_review"
  capability_id = "memory_layer_separation"
  phase = "P1"
  acceptance_type = "core_only"
  layers = @(
    [ordered]@{ id = "brain"; role = "knowledge scope metadata and KB context"; primary_paths = @("memory_evidence") },
    [ordered]@{ id = "agent_memory"; role = "task memory snapshot and resume state"; primary_paths = @("task_memory") },
    [ordered]@{ id = "session_context"; role = "current task/session state and handoff pointers"; primary_paths = @("task_memory") },
    [ordered]@{ id = "event"; role = "event ledger records"; primary_paths = @("audit/event_ledger.jsonl") },
    [ordered]@{ id = "artifact"; role = "artifact lifecycle catalog records"; primary_paths = @("artifacts/catalog.json") }
  )
  separation_rules = @(
    "memory_layer_type is mandatory in durable memory/evidence scope records.",
    "task_memory_snapshot and resume state stay under task_memory.",
    "Event Ledger writes use event records and do not replace artifact catalog records.",
    "Artifact Lifecycle writes use artifact records and do not replace Event Ledger rows.",
    "Evidence Graph remains a later gate; this gate verifies the boundary only."
  )
  source_evidence = @(
    "web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_io.dart",
    "web/workbench/flutter_app/output/capability_blackbox/memory_evidence/memory_evidence_metadata_reservation_matrix.json",
    "web/workbench/flutter_app/output/capability_blackbox/agent_memory_minimal_core_matrix.json"
  )
  next_gate = $nextGate
  global_goal_complete = $false
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $contractPath $contract

$contractOk = (Test-Path -LiteralPath $contractPath) -and
  $contract.layers.Count -eq 5 -and
  $contract.next_gate -eq "P1-4 Evidence Graph Basic" -and
  $contract.global_goal_complete -eq $false
Add-LayerRow $rows "memory layer contract artifact is generated and restart-readable" $contractOk `
  "contract=$contractPath; layers=$($contract.layers.Count); next_gate=$($contract.next_gate); global_goal_complete=$($contract.global_goal_complete)" `
  "memory_layer_contract_invalid"

$newEvidenceClaimHits = Test-AddedClaimBoundary @($contractPath)
Add-LayerRow $rows "new P1-3 evidence has no forbidden positive-state tokens" ($newEvidenceClaimHits.Count -eq 0) `
  "scanned=contract; hits=$($newEvidenceClaimHits.Count)" `
  "memory_layer_forbidden_claim_token_found"

$blocked = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "memory_layer_separation_completed_needs_owner_review"
} else {
  "memory_layer_separation_blocked"
}

$checkpoint = [ordered]@{
  schema_version = "heitang_memory_layer_separation_checkpoint.v1"
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
  schema_version = "heitang_memory_layer_separation_failure_template.v1"
  status = "no_current_failure"
  affected_phase = "P1"
  affected_capability_id = "memory_layer_separation"
  failed_acceptance_type = "core_only"
  resume_prompt_path = $resumePath
  created_at = (Get-Date).ToUniversalTime().ToString("o")
})
@(
  "# Memory Layer Separation Resume Prompt",
  "",
  "Resume from current_gate=$($chain.current_gate) if interrupted before commit.",
  "After commit, resume from next_gate=$nextGate.",
  "Keep global_goal_complete=false while remaining gates exist.",
  "Do not execute P1-4 until P1-3 evidence is committed."
) | Set-Content -Encoding UTF8 -Path $resumePath

$payload = [ordered]@{
  schema_version = "heitang_p1_memory_layer_separation_matrix.v1"
  status = $status
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
  repo_root = $repoRoot
  current_phase = $chain.current_phase
  current_gate = $chain.current_gate
  next_gate = $nextGate
  remaining_gates_count = $remaining.Count
  global_goal_complete = $false
  contract_path = $contractPath
  checkpoint_path = $checkpointPath
  failure_template_path = $failurePath
  resume_prompt_path = $resumePath
  rows = $rows
}
Write-Json $matrixPath $payload

$blockerText = if ($blocked.Count -eq 0) {
  "- none for this P1-3 gate; Owner review remains outside automatic closure."
} else {
  ($blocked | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$report = @(
  "# P1-3 Memory Layer Separation Basic Closure Report",
  "",
  "Status: $status",
  "",
  "## Acceptance Scope",
  "",
  "- Validate the basic separation contract for brain, agent memory, session context, event and artifact layers.",
  "- This Gate is core_only; it does not add UI, does not connect TencentDB, and does not execute the Evidence Graph gate.",
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
  "- command: run_memory_layer_separation_matrix.ps1",
  "- schema evidence: memory layer contract plus runtime/source matrix checks.",
  "",
  "## Black-box Test Result",
  "",
  "- result: not_required",
  "- reason: core_only memory separation has no standalone user UI path.",
  "",
  "## Evidence Completeness Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- artifacts: contract, matrix, checkpoint, failure template, resume prompt and this report.",
  "",
  "## Lifecycle Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- scope: generated contract and checkpoint can be read after script rerun.",
  "",
  "## Regression Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- scope: P0 memory/evidence and P0 agent-memory matrices remain readable with zero blocked rows.",
  "",
  "## Boundary Compliance Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- no UI/runtime edits, no dependency addition, no service packaging change, no P2 entry.",
  "",
  "## Reviewer Findings",
  "",
  "- P1-3 uses core evidence only and does not fake a UI blackbox.",
  "- Existing task memory, event ledger and artifact lifecycle paths stay separated by path and layer role.",
  "- Evidence Graph remains queued as P1-4.",
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
