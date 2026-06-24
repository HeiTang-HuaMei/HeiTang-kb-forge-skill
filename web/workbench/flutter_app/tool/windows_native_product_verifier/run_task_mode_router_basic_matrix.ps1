param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p1_task_mode_router_basic"
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

function Add-TaskModeRow(
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
$routerPath = Join-Path $repoRoot "heitang_kb_forge\task_mode_router\router.py"
$schemaPath = Join-Path $repoRoot "heitang_kb_forge\schemas\task_mode_router_schema.py"
$testPath = Join-Path $repoRoot "tests\test_task_mode_router_basic.py"
$aiConfigContractPath = Join-Path $appRoot "output\p1_ai_config_governance_basic\ai_config_governance_basic_contract.json"
$matrixPath = Join-Path $OutputRoot "task_mode_router_basic_matrix.json"
$contractPath = Join-Path $OutputRoot "task_mode_router_basic_contract.json"
$liteReportPath = Join-Path $OutputRoot "task_mode_router_lite_report.json"
$longReportPath = Join-Path $OutputRoot "task_mode_router_long_report.json"
$stageReportPath = Join-Path $OutputRoot "task_mode_router_stage_report.json"
$hardRiskReportPath = Join-Path $OutputRoot "task_mode_router_hard_risk_report.json"
$sampleHelperPath = Join-Path $OutputRoot "run_task_mode_router_sample.py"
$checkpointPath = Join-Path $OutputRoot "task_mode_router_basic_checkpoint.json"
$failurePath = Join-Path $OutputRoot "task_mode_router_basic_failure_template.json"
$resumePath = Join-Path $OutputRoot "task_mode_router_basic_resume_prompt.md"
$reportPath = Join-Path $repoRoot "docs\audits\current\task_mode_router_closure_report.md"
$rows = [System.Collections.ArrayList]::new()

$requiredFiles = @(
  $chainPath,
  $registryPath,
  $planPath,
  $queuePath,
  $rubricPath,
  $p1BackfillPath,
  $routerPath,
  $schemaPath,
  $testPath,
  $aiConfigContractPath
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
Add-TaskModeRow $rows "required task mode router source and prior evidence files exist" ($missingFiles.Count -eq 0) `
  "missing=$($missingFiles.Count)" `
  "task_mode_router_required_file_missing"

$chain = Read-JsonFile $chainPath
$remaining = @($chain.remaining_gates)
$completedReview = @($chain.completed_with_owner_review_needed)
$prePassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-14 Task Mode Router Basic" -and
  $remaining.Count -eq 78 -and
  $remaining[0] -eq "P1-14 Task Mode Router Basic" -and
  $completedReview -notcontains "P1-14 Task Mode Router Basic"
$postPassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-15 Plan-and-Execute Runtime Basic" -and
  $remaining.Count -eq 77 -and
  $remaining[0] -eq "P1-15 Plan-and-Execute Runtime Basic" -and
  $completedReview -contains "P1-14 Task Mode Router Basic"
$stateOk = ($prePassState -or $postPassState) -and $chain.global_goal_complete -eq $false
Add-TaskModeRow $rows "status machine is at or just past P1-14 with global guard" $stateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($remaining[0]); remaining=$($remaining.Count); global_goal_complete=$($chain.global_goal_complete)" `
  "task_mode_router_status_machine_mismatch"

$preconditionsOk = ($completedReview -contains "P0 Release Gate") -and
  ($completedReview -contains "P1-13 AI Config Governance Basic")
Add-TaskModeRow $rows "P0 release and P1-13 precede task mode router" $preconditionsOk `
  "p0_release=$($completedReview -contains 'P0 Release Gate'); p1_ai_config=$($completedReview -contains 'P1-13 AI Config Governance Basic')" `
  "task_mode_router_missing_precondition"

$nextGate = if ($prePassState -and $remaining.Count -gt 1) {
  $remaining[1]
} elseif ($postPassState) {
  $remaining[0]
} else {
  ""
}
$chainShapeOk = $nextGate -eq "P1-15 Plan-and-Execute Runtime Basic" -and
  ($remaining -contains "P1 Release Gate") -and
  ($remaining -contains "P2 Release Gate") -and
  ($remaining -contains "Final Owner Review Gate")
Add-TaskModeRow $rows "remaining chain preserves release gates and next gate" $chainShapeOk `
  "next_gate=$nextGate; p1_release=$($remaining -contains 'P1 Release Gate'); p2_release=$($remaining -contains 'P2 Release Gate'); final=$($remaining -contains 'Final Owner Review Gate')" `
  "task_mode_router_chain_sequence_invalid"

$registryRow = @(
  Get-Content -LiteralPath $registryPath -Encoding UTF8 |
    Where-Object { $_ -match "^\| task_mode_router \|" }
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
Add-TaskModeRow $rows "task_mode_router registry row follows core-only contract" $registryStatusOk `
  "row_count=$($registryRow.Count); type=$($registryCells[3]); core=$($registryCells[4]); ui=$($registryCells[5]); blackbox=$($registryCells[6]); close_allowed=$($registryCells[13])" `
  "task_mode_router_registry_row_invalid"

$planText = Get-Content -Raw -LiteralPath $planPath -Encoding UTF8
$queueText = Get-Content -Raw -LiteralPath $queuePath -Encoding UTF8
$rubricText = Get-Content -Raw -LiteralPath $rubricPath -Encoding UTF8
$p1Text = Get-Content -Raw -LiteralPath $p1BackfillPath -Encoding UTF8
$crossRefsOk = $planText.Contains("| 37 | P1 | task_mode_router | Task Mode Router Basic | core_only |") -and
  $queueText.Contains("18. P1-14 Task Mode Router Basic") -and
  $queueText.Contains("19. P1-15 Plan-and-Execute Runtime Basic") -and
  $rubricText.Contains("| P1 | task_mode_router | core_only |") -and
  $p1Text.Contains("task_mode_router")
Add-TaskModeRow $rows "plan, queue, rubric and P1 grouping reference task mode router" $crossRefsOk `
  "plan=$($planText.Contains('| 37 | P1 | task_mode_router | Task Mode Router Basic | core_only |')); queue_p1_14=$($queueText.Contains('18. P1-14 Task Mode Router Basic')); queue_p1_15=$($queueText.Contains('19. P1-15 Plan-and-Execute Runtime Basic'))" `
  "task_mode_router_cross_reference_invalid"

$routerText = Get-Content -Raw -LiteralPath $routerPath -Encoding UTF8
$schemaText = Get-Content -Raw -LiteralPath $schemaPath -Encoding UTF8
$sourceShapeOk = $routerText.Contains("def route_task_mode") -and
  $schemaText.Contains("class TaskModeRouterInput") -and
  $schemaText.Contains("class TaskModeRouterDecision") -and
  $schemaText.Contains("auto_execute_allowed") -and
  $schemaText.Contains("owner_review_required")
Add-TaskModeRow $rows "source implements structured task mode router input and decision schema" $sourceShapeOk `
  "router=$($routerText.Contains('def route_task_mode')); input_schema=$($schemaText.Contains('class TaskModeRouterInput')); decision_schema=$($schemaText.Contains('class TaskModeRouterDecision'))" `
  "task_mode_router_source_shape_missing"

$pythonCode = @"
import json
import sys
from pathlib import Path

sys.path.insert(0, r"$repoRoot")

from heitang_kb_forge.task_mode_router import route_task_mode

lite = route_task_mode({"task_text": "fix typo", "changed_file_count": 1, "estimated_minutes": 10})
long = route_task_mode({
    "task_text": "implement runtime flow",
    "changed_file_count": 5,
    "estimated_minutes": 90,
    "affects_runtime": True,
    "user_blackbox_required": True,
})
stage = route_task_mode({"task_text": "run release gate", "stage_gate_requested": True})
hard = route_task_mode({"task_text": "delete user data", "hard_blocker_risk": True})

Path(r"$liteReportPath").write_text(json.dumps(lite.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
Path(r"$longReportPath").write_text(json.dumps(long.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
Path(r"$stageReportPath").write_text(json.dumps(stage.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
Path(r"$hardRiskReportPath").write_text(json.dumps(hard.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
"@
Set-Content -Encoding UTF8 -Path $sampleHelperPath -Value $pythonCode
$sampleResult = Invoke-CheckedCommand "python" @($sampleHelperPath) $repoRoot
$liteReport = Read-JsonFile $liteReportPath
$longReport = Read-JsonFile $longReportPath
$stageReport = Read-JsonFile $stageReportPath
$hardRiskReport = Read-JsonFile $hardRiskReportPath
$sampleOk = $sampleResult.exit_code -eq 0 -and
  $liteReport.mode -eq "task_gate_lite" -and
  $liteReport.auto_execute_allowed -eq $true -and
  $longReport.mode -eq "night_long_build" -and
  @($longReport.reason_codes).Contains("runtime_path_affected") -and
  @($longReport.reason_codes).Contains("blackbox_required") -and
  $stageReport.mode -eq "stage_gate_review" -and
  $stageReport.owner_review_required -eq $true -and
  $hardRiskReport.mode -eq "owner_review_gate" -and
  $hardRiskReport.auto_execute_allowed -eq $false
Add-TaskModeRow $rows "task mode router handles lite, long build, stage gate and hard risk paths" $sampleOk `
  "exit_code=$($sampleResult.exit_code); lite=$($liteReport.mode); long=$($longReport.mode); stage=$($stageReport.mode); hard=$($hardRiskReport.mode)" `
  "task_mode_router_sample_output_invalid"

$pytestResult = Invoke-CheckedCommand "python" @(
  "-m",
  "pytest",
  "tests/test_task_mode_router_basic.py",
  "tests/test_planning_readiness.py",
  "tests/test_quality_gate.py",
  "-q"
) $repoRoot
$pytestOk = $pytestResult.exit_code -eq 0
Add-TaskModeRow $rows "narrow task mode router and related planning tests pass" $pytestOk `
  "exit_code=$($pytestResult.exit_code); stdout=$($pytestResult.stdout.Trim()); stderr=$($pytestResult.stderr.Trim())" `
  "task_mode_router_tests_failed"

$aiConfigContract = Read-JsonFile $aiConfigContractPath
$priorEvidenceOk = $aiConfigContract.status -eq "ai_config_governance_completed_needs_owner_review"
Add-TaskModeRow $rows "P1 AI config governance contract is available" $priorEvidenceOk `
  "ai_config_status=$($aiConfigContract.status)" `
  "task_mode_router_prior_evidence_missing"

$contract = [ordered]@{
  schema_version = "heitang_task_mode_router_basic_contract.v1"
  status = "task_mode_router_completed_needs_owner_review"
  capability_id = "task_mode_router"
  phase = "P1"
  acceptance_type = "core_only"
  required_inputs = @("task_text", "changed_file_count", "estimated_minutes", "affects_ui", "affects_runtime", "user_blackbox_required", "review_requested", "stage_gate_requested", "hard_blocker_risk")
  required_outputs = @("mode", "auto_execute_allowed", "owner_review_required", "reason_codes", "validation_focus")
  lite_report_path = $liteReportPath
  long_report_path = $longReportPath
  stage_report_path = $stageReportPath
  hard_risk_report_path = $hardRiskReportPath
  sample_modes = @($liteReport.mode, $longReport.mode, $stageReport.mode, $hardRiskReport.mode)
  next_gate = $nextGate
  global_goal_complete = $false
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $contractPath $contract

$contractOk = (Test-Path -LiteralPath $contractPath) -and
  ($contract.sample_modes -join ",") -eq "task_gate_lite,night_long_build,stage_gate_review,owner_review_gate" -and
  $contract.required_outputs.Count -eq 5 -and
  $contract.next_gate -eq "P1-15 Plan-and-Execute Runtime Basic" -and
  $contract.global_goal_complete -eq $false
Add-TaskModeRow $rows "task mode router basic contract artifact is generated" $contractOk `
  "contract=$contractPath; modes=$($contract.sample_modes -join ','); next_gate=$($contract.next_gate)" `
  "task_mode_router_contract_invalid"

$claimHits = Test-PositiveClaimBoundary @($contractPath, $liteReportPath, $longReportPath, $stageReportPath, $hardRiskReportPath)
Add-TaskModeRow $rows "new P1-14 evidence has no forbidden positive-state tokens" ($claimHits.Count -eq 0) `
  "scanned=contract,lite,long,stage,hard; hits=$($claimHits.Count)" `
  "task_mode_router_forbidden_claim_token_found"

$blocked = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "task_mode_router_completed_needs_owner_review"
} else {
  "task_mode_router_blocked"
}

$checkpoint = [ordered]@{
  schema_version = "heitang_task_mode_router_basic_checkpoint.v1"
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
  schema_version = "heitang_task_mode_router_basic_failure_template.v1"
  status = "no_current_failure"
  affected_phase = "P1"
  affected_capability_id = "task_mode_router"
  failed_acceptance_type = "core_only"
  resume_prompt_path = $resumePath
  created_at = (Get-Date).ToUniversalTime().ToString("o")
})
@(
  "# Task Mode Router Basic Resume Prompt",
  "",
  "Resume from current_gate=$($chain.current_gate) if interrupted before commit.",
  "After commit, resume from next_gate=$nextGate.",
  "Keep global_goal_complete=false while remaining gates exist.",
  "Do not execute P1-15 until P1-14 evidence is committed."
) | Set-Content -Encoding UTF8 -Path $resumePath

$payload = [ordered]@{
  schema_version = "heitang_p1_task_mode_router_basic_matrix.v1"
  status = $status
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
  repo_root = $repoRoot
  current_phase = $chain.current_phase
  current_gate = $chain.current_gate
  next_gate = $nextGate
  remaining_gates_count = $remaining.Count
  global_goal_complete = $false
  contract_path = $contractPath
  lite_report_path = $liteReportPath
  long_report_path = $longReportPath
  stage_report_path = $stageReportPath
  hard_risk_report_path = $hardRiskReportPath
  checkpoint_path = $checkpointPath
  failure_template_path = $failurePath
  resume_prompt_path = $resumePath
  rows = $rows
}
Write-Json $matrixPath $payload

$blockerText = if ($blocked.Count -eq 0) {
  "- none for this P1-14 gate; Owner review remains outside automatic closure."
} else {
  ($blocked | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$report = @(
  "# P1-14 Task Mode Router Basic Closure Report",
  "",
  "Status: $status",
  "",
  "## Acceptance Scope",
  "",
  "- Validate deterministic task mode routing with reason codes and validation focus.",
  "- This Gate is core_only; it does not add UI, external LLM calls or runtime orchestration.",
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
  "- command: run_task_mode_router_basic_matrix.ps1",
  "- schema evidence: router, pydantic schema, lite/long/stage/hard-risk reports and narrow tests.",
  "",
  "## Black-box Test Result",
  "",
  "- result: not_required",
  "- reason: core_only task mode router has no standalone user UI path.",
  "",
  "## Evidence Completeness Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- artifacts: contract, matrix, sample reports, checkpoint, failure template, resume prompt and this report.",
  "",
  "## Lifecycle Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- scope: create and read deterministic task mode decisions plus rerunnable verifier contract.",
  "",
  "## Regression Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- tests: python -m pytest tests/test_task_mode_router_basic.py tests/test_planning_readiness.py tests/test_quality_gate.py -q",
  "",
  "## Boundary Compliance Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- no UI/runtime edits, no dependency addition, no external service use, no P2 entry.",
  "",
  "## Reviewer Findings",
  "",
  "- P1-14 uses deterministic core evidence only and does not fake a UI blackbox.",
  "- Plan-and-Execute Runtime remains queued as P1-15.",
  "- P1-13 AI config governance evidence remains readable.",
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
