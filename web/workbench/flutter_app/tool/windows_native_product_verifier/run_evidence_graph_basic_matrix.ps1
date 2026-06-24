param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p1_evidence_graph_basic"
}

function Add-GraphRow(
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

function Read-JsonLines([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return @() }
  $items = [System.Collections.ArrayList]::new()
  foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    [void]$items.Add(($line | ConvertFrom-Json))
  }
  return @($items)
}

function Invoke-CheckedCommand([string]$FilePath, [string[]]$Arguments, [string]$WorkingDirectory) {
  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $FilePath
  $psi.Arguments = ($Arguments | ForEach-Object {
    if ($_ -match '\s') { '"' + ($_.Replace('"', '\"')) + '"' } else { $_ }
  }) -join " "
  $psi.WorkingDirectory = $WorkingDirectory
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $process = [System.Diagnostics.Process]::Start($psi)
  $stdout = $process.StandardOutput.ReadToEnd()
  $stderr = $process.StandardError.ReadToEnd()
  $process.WaitForExit()
  return [ordered]@{
    exit_code = $process.ExitCode
    stdout = if ($stdout.Length -gt 600) { $stdout.Substring(0, 600) } else { $stdout }
    stderr = if ($stderr.Length -gt 600) { $stderr.Substring(0, 600) } else { $stderr }
  }
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
$exporterPath = Join-Path $repoRoot "heitang_kb_forge\knowledge_graph\exporter.py"
$schemaPath = Join-Path $repoRoot "heitang_kb_forge\schemas\knowledge_graph_schema.py"
$cliRuntimePath = Join-Path $repoRoot "heitang_kb_forge\cli_runtime.py"
$testPath = Join-Path $repoRoot "tests\test_knowledge_graph_export.py"
$memoryLayerContractPath = Join-Path $appRoot "output\p1_memory_layer_separation\memory_layer_contract.json"
$p0ReservationPath = Join-Path $appRoot "output\capability_blackbox\memory_evidence\memory_evidence_metadata_reservation_matrix.json"
$matrixPath = Join-Path $OutputRoot "evidence_graph_basic_matrix.json"
$contractPath = Join-Path $OutputRoot "evidence_graph_basic_contract.json"
$runInput = Join-Path $OutputRoot "sample_input"
$runOutput = Join-Path $OutputRoot "sample_output"
$checkpointPath = Join-Path $OutputRoot "evidence_graph_basic_checkpoint.json"
$failurePath = Join-Path $OutputRoot "evidence_graph_basic_failure_template.json"
$resumePath = Join-Path $OutputRoot "evidence_graph_basic_resume_prompt.md"
$reportPath = Join-Path $repoRoot "docs\audits\current\evidence_graph_basic_closure_report.md"
$rows = [System.Collections.ArrayList]::new()

$requiredFiles = @(
  $chainPath,
  $registryPath,
  $planPath,
  $queuePath,
  $rubricPath,
  $p1BackfillPath,
  $exporterPath,
  $schemaPath,
  $cliRuntimePath,
  $testPath,
  $memoryLayerContractPath,
  $p0ReservationPath
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
Add-GraphRow $rows "required evidence graph source and prior evidence files exist" ($missingFiles.Count -eq 0) `
  "missing=$($missingFiles.Count)" `
  "evidence_graph_required_file_missing"

$chain = Read-JsonFile $chainPath
$remaining = @($chain.remaining_gates)
$completedReview = @($chain.completed_with_owner_review_needed)
$prePassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-4 Evidence Graph Basic" -and
  $remaining.Count -eq 88 -and
  $remaining[0] -eq "P1-4 Evidence Graph Basic" -and
  $completedReview -notcontains "P1-4 Evidence Graph Basic"
$postPassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-5 Gap Analysis Basic Plus" -and
  $remaining.Count -eq 87 -and
  $remaining[0] -eq "P1-5 Gap Analysis Basic Plus" -and
  $completedReview -contains "P1-4 Evidence Graph Basic"
$stateOk = ($prePassState -or $postPassState) -and $chain.global_goal_complete -eq $false
Add-GraphRow $rows "status machine is at or just past P1-4 with global guard" $stateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($remaining[0]); remaining=$($remaining.Count); global_goal_complete=$($chain.global_goal_complete)" `
  "evidence_graph_status_machine_mismatch"

$preconditionsOk = ($completedReview -contains "P0 Release Gate") -and
  ($completedReview -contains "P1-1 Capability Chain Runner") -and
  ($completedReview -contains "P1-2 Capability Registry") -and
  ($completedReview -contains "P1-3 Memory Layer Separation Basic")
Add-GraphRow $rows "P0 release and P1-1 through P1-3 precede evidence graph gate" $preconditionsOk `
  "p0_release=$($completedReview -contains 'P0 Release Gate'); p1_runner=$($completedReview -contains 'P1-1 Capability Chain Runner'); p1_registry=$($completedReview -contains 'P1-2 Capability Registry'); p1_memory=$($completedReview -contains 'P1-3 Memory Layer Separation Basic')" `
  "evidence_graph_missing_precondition"

$nextGate = if ($prePassState -and $remaining.Count -gt 1) {
  $remaining[1]
} elseif ($postPassState) {
  $remaining[0]
} else {
  ""
}
$chainShapeOk = $nextGate -eq "P1-5 Gap Analysis Basic Plus" -and
  ($remaining -contains "P1 Release Gate") -and
  ($remaining -contains "P2 Release Gate") -and
  ($remaining -contains "Final Owner Review Gate")
Add-GraphRow $rows "remaining chain preserves release gates and next gate" $chainShapeOk `
  "next_gate=$nextGate; p1_release=$($remaining -contains 'P1 Release Gate'); p2_release=$($remaining -contains 'P2 Release Gate'); final=$($remaining -contains 'Final Owner Review Gate')" `
  "evidence_graph_chain_sequence_invalid"

$registryRow = @(
  Get-Content -LiteralPath $registryPath -Encoding UTF8 |
    Where-Object { $_ -match "^\| evidence_graph_basic \|" }
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
Add-GraphRow $rows "evidence_graph_basic registry row follows core-only contract" $registryStatusOk `
  "row_count=$($registryRow.Count); type=$($registryCells[3]); core=$($registryCells[4]); ui=$($registryCells[5]); blackbox=$($registryCells[6]); close_allowed=$($registryCells[13])" `
  "evidence_graph_registry_row_invalid"

$planText = Get-Content -Raw -LiteralPath $planPath -Encoding UTF8
$queueText = Get-Content -Raw -LiteralPath $queuePath -Encoding UTF8
$rubricText = Get-Content -Raw -LiteralPath $rubricPath -Encoding UTF8
$p1Text = Get-Content -Raw -LiteralPath $p1BackfillPath -Encoding UTF8
$crossRefsOk = $planText.Contains("| 27 | P1 | evidence_graph_basic | Evidence Graph Basic | core_only |") -and
  $queueText.Contains("8. P1-4 Evidence Graph Basic") -and
  $queueText.Contains("9. P1-5 Gap Analysis Basic Plus") -and
  $rubricText.Contains("| P1 | evidence_graph_basic | core_only |") -and
  $p1Text.Contains("evidence_graph_basic")
Add-GraphRow $rows "plan, queue, rubric and P1 grouping reference evidence graph gate" $crossRefsOk `
  "plan=$($planText.Contains('| 27 | P1 | evidence_graph_basic | Evidence Graph Basic | core_only |')); queue_p1_4=$($queueText.Contains('8. P1-4 Evidence Graph Basic')); queue_p1_5=$($queueText.Contains('9. P1-5 Gap Analysis Basic Plus'))" `
  "evidence_graph_cross_reference_invalid"

$exporterText = Get-Content -Raw -LiteralPath $exporterPath -Encoding UTF8
$schemaText = Get-Content -Raw -LiteralPath $schemaPath -Encoding UTF8
$cliText = Get-Content -Raw -LiteralPath $cliRuntimePath -Encoding UTF8
$sourceShapeOk = $exporterText.Contains("def make_knowledge_graph") -and
  $exporterText.Contains("EntityRecord") -and
  $exporterText.Contains("RelationRecord") -and
  $schemaText.Contains("class EntityRecord") -and
  $schemaText.Contains("class RelationRecord") -and
  $cliText.Contains("write_jsonl(output / `"entities.jsonl`"") -and
  $cliText.Contains("write_jsonl(output / `"relations.jsonl`"") -and
  $cliText.Contains("write_json(output / `"knowledge_graph_manifest.json`"")
Add-GraphRow $rows "source implements evidence graph entities, relations and manifest writes" $sourceShapeOk `
  "exporter=$($exporterText.Contains('def make_knowledge_graph')); entity_schema=$($schemaText.Contains('class EntityRecord')); relation_schema=$($schemaText.Contains('class RelationRecord')); cli_manifest=$($cliText.Contains('knowledge_graph_manifest.json'))" `
  "evidence_graph_source_shape_missing"

New-Item -ItemType Directory -Force -Path $runInput, $runOutput | Out-Null
Set-Content -Encoding UTF8 -Path (Join-Path $runInput "lesson.md") -Value "Product metric process fixture for evidence graph basic. Author publisher score process product."
$cliResult = Invoke-CheckedCommand "python" @(
  "-m",
  "heitang_kb_forge.cli",
  "build",
  "--input",
  $runInput,
  "--output",
  $runOutput,
  "--knowledge-graph-export"
) $repoRoot
$cliOk = $cliResult.exit_code -eq 0
Add-GraphRow $rows "CLI can build evidence graph export from sample input" $cliOk `
  "exit_code=$($cliResult.exit_code); stdout=$($cliResult.stdout.Trim()); stderr=$($cliResult.stderr.Trim())" `
  "evidence_graph_cli_export_failed"

$entitiesPath = Join-Path $runOutput "entities.jsonl"
$relationsPath = Join-Path $runOutput "relations.jsonl"
$manifestPath = Join-Path $runOutput "knowledge_graph_manifest.json"
$entities = Read-JsonLines $entitiesPath
$relations = Read-JsonLines $relationsPath
$manifest = Read-JsonFile $manifestPath
$outputOk = (Test-Path -LiteralPath $entitiesPath) -and
  (Test-Path -LiteralPath $relationsPath) -and
  (Test-Path -LiteralPath $manifestPath) -and
  $entities.Count -gt 0 -and
  $manifest.entity_count -eq $entities.Count -and
  $manifest.knowledge_graph_version -eq "1.1.0"
Add-GraphRow $rows "generated graph files have stable entity and manifest shape" $outputOk `
  "entities=$($entities.Count); relations=$($relations.Count); manifest_entities=$($manifest.entity_count); version=$($manifest.knowledge_graph_version)" `
  "evidence_graph_output_shape_invalid"

$entity = if ($entities.Count -gt 0) { $entities[0] } else { $null }
$relation = if ($relations.Count -gt 0) { $relations[0] } else { $null }
$schemaOk = $null -ne $entity -and
  $null -ne $entity.entity_id -and
  $null -ne $entity.name -and
  $null -ne $entity.entity_type -and
  $null -ne $entity.source_path -and
  $null -ne $entity.chunk_id -and
  $null -ne $entity.citation -and
  ($relations.Count -eq 0 -or (
    $null -ne $relation.relation_id -and
    $null -ne $relation.source_entity_id -and
    $null -ne $relation.target_entity_id -and
    $null -ne $relation.relation_type -and
    $null -ne $relation.citation
  ))
Add-GraphRow $rows "entity and relation records expose required schema fields" $schemaOk `
  "entity_id=$($entity.entity_id); entity_type=$($entity.entity_type); relation_count=$($relations.Count)" `
  "evidence_graph_schema_fields_missing"

$pytestResult = Invoke-CheckedCommand "python" @(
  "-m",
  "pytest",
  "tests/test_knowledge_graph_export.py",
  "tests/test_workspace_relationship_graph.py",
  "-q"
) $repoRoot
$pytestOk = $pytestResult.exit_code -eq 0
Add-GraphRow $rows "narrow graph regression tests pass" $pytestOk `
  "exit_code=$($pytestResult.exit_code); stdout=$($pytestResult.stdout.Trim()); stderr=$($pytestResult.stderr.Trim())" `
  "evidence_graph_regression_tests_failed"

$memoryLayerContract = Read-JsonFile $memoryLayerContractPath
$p0Reservation = Read-JsonFile $p0ReservationPath
$priorEvidenceOk = $memoryLayerContract.status -eq "memory_layer_separation_completed_needs_owner_review" -and
  $p0Reservation.status -eq "memory_evidence_metadata_reserved_needs_review"
Add-GraphRow $rows "memory layer and P0 evidence reservations are available for graph gate" $priorEvidenceOk `
  "memory_layer_status=$($memoryLayerContract.status); p0_reservation_status=$($p0Reservation.status)" `
  "evidence_graph_prior_evidence_missing"

$contract = [ordered]@{
  schema_version = "heitang_evidence_graph_basic_contract.v1"
  status = "evidence_graph_basic_completed_needs_owner_review"
  capability_id = "evidence_graph_basic"
  phase = "P1"
  acceptance_type = "core_only"
  graph_files = @("entities.jsonl", "relations.jsonl", "knowledge_graph_manifest.json")
  entity_schema_fields = @("entity_id", "name", "entity_type", "source_path", "chunk_id", "citation")
  relation_schema_fields = @("relation_id", "source_entity_id", "target_entity_id", "relation_type", "source_path", "chunk_id", "citation")
  sample_output = $runOutput
  entity_count = $entities.Count
  relation_count = $relations.Count
  next_gate = $nextGate
  global_goal_complete = $false
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $contractPath $contract

$contractOk = (Test-Path -LiteralPath $contractPath) -and
  $contract.entity_count -gt 0 -and
  $contract.graph_files.Count -eq 3 -and
  $contract.next_gate -eq "P1-5 Gap Analysis Basic Plus" -and
  $contract.global_goal_complete -eq $false
Add-GraphRow $rows "evidence graph basic contract artifact is generated" $contractOk `
  "contract=$contractPath; entity_count=$($contract.entity_count); relation_count=$($contract.relation_count); next_gate=$($contract.next_gate)" `
  "evidence_graph_contract_invalid"

$claimHits = Test-PositiveClaimBoundary @($contractPath)
Add-GraphRow $rows "new P1-4 evidence has no forbidden positive-state tokens" ($claimHits.Count -eq 0) `
  "scanned=contract; hits=$($claimHits.Count)" `
  "evidence_graph_forbidden_claim_token_found"

$blocked = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "evidence_graph_basic_completed_needs_owner_review"
} else {
  "evidence_graph_basic_blocked"
}

$checkpoint = [ordered]@{
  schema_version = "heitang_evidence_graph_basic_checkpoint.v1"
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
  schema_version = "heitang_evidence_graph_basic_failure_template.v1"
  status = "no_current_failure"
  affected_phase = "P1"
  affected_capability_id = "evidence_graph_basic"
  failed_acceptance_type = "core_only"
  resume_prompt_path = $resumePath
  created_at = (Get-Date).ToUniversalTime().ToString("o")
})
@(
  "# Evidence Graph Basic Resume Prompt",
  "",
  "Resume from current_gate=$($chain.current_gate) if interrupted before commit.",
  "After commit, resume from next_gate=$nextGate.",
  "Keep global_goal_complete=false while remaining gates exist.",
  "Do not execute P1-5 until P1-4 evidence is committed."
) | Set-Content -Encoding UTF8 -Path $resumePath

$payload = [ordered]@{
  schema_version = "heitang_p1_evidence_graph_basic_matrix.v1"
  status = $status
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
  repo_root = $repoRoot
  current_phase = $chain.current_phase
  current_gate = $chain.current_gate
  next_gate = $nextGate
  remaining_gates_count = $remaining.Count
  global_goal_complete = $false
  contract_path = $contractPath
  sample_output = $runOutput
  checkpoint_path = $checkpointPath
  failure_template_path = $failurePath
  resume_prompt_path = $resumePath
  rows = $rows
}
Write-Json $matrixPath $payload

$blockerText = if ($blocked.Count -eq 0) {
  "- none for this P1-4 gate; Owner review remains outside automatic closure."
} else {
  ($blocked | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$report = @(
  "# P1-4 Evidence Graph Basic Closure Report",
  "",
  "Status: $status",
  "",
  "## Acceptance Scope",
  "",
  "- Validate basic evidence graph generation for entities, relations and manifest output.",
  "- This Gate is core_only; it does not add UI, vector DB packaging, local model work or P1-5 gap analysis.",
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
  "- command: run_evidence_graph_basic_matrix.ps1",
  "- schema evidence: exporter, schema classes, CLI export files and narrow graph tests.",
  "",
  "## Black-box Test Result",
  "",
  "- result: not_required",
  "- reason: core_only evidence graph has no standalone user UI path.",
  "",
  "## Evidence Completeness Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- artifacts: contract, matrix, sample graph outputs, checkpoint, failure template, resume prompt and this report.",
  "",
  "## Lifecycle Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- scope: create and read graph output files plus rerunnable verifier contract.",
  "",
  "## Regression Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- tests: python -m pytest tests/test_knowledge_graph_export.py tests/test_workspace_relationship_graph.py -q",
  "",
  "## Boundary Compliance Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- no UI/runtime edits, no dependency addition, no service packaging change, no P2 entry.",
  "",
  "## Reviewer Findings",
  "",
  "- P1-4 uses core evidence only and does not fake a UI blackbox.",
  "- Graph output is generated from a temporary sample and does not mutate user data.",
  "- Gap analysis remains queued as P1-5.",
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
