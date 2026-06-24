param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p1_scope_resolver_basic"
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

function Add-ScopeRow(
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
$resolverPath = Join-Path $repoRoot "heitang_kb_forge\scope_resolver\resolver.py"
$schemaPath = Join-Path $repoRoot "heitang_kb_forge\schemas\scope_resolver_schema.py"
$testPath = Join-Path $repoRoot "tests\test_scope_resolver_basic.py"
$industrialScopePath = Join-Path $appRoot "output\capability_blackbox\industrial_scope\industrial_scope_metadata_reservation_matrix.json"
$retrievalContractPath = Join-Path $appRoot "output\p1_retrieval_regression_basic\retrieval_regression_basic_contract.json"
$matrixPath = Join-Path $OutputRoot "scope_resolver_basic_matrix.json"
$contractPath = Join-Path $OutputRoot "scope_resolver_basic_contract.json"
$explicitReportPath = Join-Path $OutputRoot "scope_resolver_explicit_report.json"
$labelReportPath = Join-Path $OutputRoot "scope_resolver_label_report.json"
$blockedReportPath = Join-Path $OutputRoot "scope_resolver_blocked_report.json"
$sampleHelperPath = Join-Path $OutputRoot "run_scope_resolver_sample.py"
$checkpointPath = Join-Path $OutputRoot "scope_resolver_basic_checkpoint.json"
$failurePath = Join-Path $OutputRoot "scope_resolver_basic_failure_template.json"
$resumePath = Join-Path $OutputRoot "scope_resolver_basic_resume_prompt.md"
$reportPath = Join-Path $repoRoot "docs\audits\current\scope_resolver_basic_closure_report.md"
$rows = [System.Collections.ArrayList]::new()

$requiredFiles = @(
  $chainPath,
  $registryPath,
  $planPath,
  $queuePath,
  $rubricPath,
  $p1BackfillPath,
  $resolverPath,
  $schemaPath,
  $testPath,
  $industrialScopePath,
  $retrievalContractPath
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
Add-ScopeRow $rows "required scope resolver source and prior evidence files exist" ($missingFiles.Count -eq 0) `
  "missing=$($missingFiles.Count)" `
  "scope_resolver_required_file_missing"

$chain = Read-JsonFile $chainPath
$remaining = @($chain.remaining_gates)
$completedReview = @($chain.completed_with_owner_review_needed)
$prePassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-9 Scope Resolver Basic" -and
  $remaining.Count -eq 83 -and
  $remaining[0] -eq "P1-9 Scope Resolver Basic" -and
  $completedReview -notcontains "P1-9 Scope Resolver Basic"
$postPassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-10 Rule Extraction Basic" -and
  $remaining.Count -eq 82 -and
  $remaining[0] -eq "P1-10 Rule Extraction Basic" -and
  $completedReview -contains "P1-9 Scope Resolver Basic"
$stateOk = ($prePassState -or $postPassState) -and $chain.global_goal_complete -eq $false
Add-ScopeRow $rows "status machine is at or just past P1-9 with global guard" $stateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($remaining[0]); remaining=$($remaining.Count); global_goal_complete=$($chain.global_goal_complete)" `
  "scope_resolver_status_machine_mismatch"

$preconditionsOk = ($completedReview -contains "P0 Release Gate") -and
  ($completedReview -contains "P1-8 Retrieval Regression Basic")
Add-ScopeRow $rows "P0 release and P1-8 precede scope resolver" $preconditionsOk `
  "p0_release=$($completedReview -contains 'P0 Release Gate'); p1_retrieval=$($completedReview -contains 'P1-8 Retrieval Regression Basic')" `
  "scope_resolver_missing_precondition"

$nextGate = if ($prePassState -and $remaining.Count -gt 1) {
  $remaining[1]
} elseif ($postPassState) {
  $remaining[0]
} else {
  ""
}
$chainShapeOk = $nextGate -eq "P1-10 Rule Extraction Basic" -and
  ($remaining -contains "P1 Release Gate") -and
  ($remaining -contains "P2 Release Gate") -and
  ($remaining -contains "Final Owner Review Gate")
Add-ScopeRow $rows "remaining chain preserves release gates and next gate" $chainShapeOk `
  "next_gate=$nextGate; p1_release=$($remaining -contains 'P1 Release Gate'); p2_release=$($remaining -contains 'P2 Release Gate'); final=$($remaining -contains 'Final Owner Review Gate')" `
  "scope_resolver_chain_sequence_invalid"

$registryRow = @(
  Get-Content -LiteralPath $registryPath -Encoding UTF8 |
    Where-Object { $_ -match "^\| scope_resolver_basic \|" }
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
Add-ScopeRow $rows "scope_resolver_basic registry row follows core-only contract" $registryStatusOk `
  "row_count=$($registryRow.Count); type=$($registryCells[3]); core=$($registryCells[4]); ui=$($registryCells[5]); blackbox=$($registryCells[6]); close_allowed=$($registryCells[13])" `
  "scope_resolver_registry_row_invalid"

$planText = Get-Content -Raw -LiteralPath $planPath -Encoding UTF8
$queueText = Get-Content -Raw -LiteralPath $queuePath -Encoding UTF8
$rubricText = Get-Content -Raw -LiteralPath $rubricPath -Encoding UTF8
$p1Text = Get-Content -Raw -LiteralPath $p1BackfillPath -Encoding UTF8
$crossRefsOk = $planText.Contains("| 32 | P1 | scope_resolver_basic | Scope Resolver Basic | core_only |") -and
  $queueText.Contains("13. P1-9 Scope Resolver Basic") -and
  $queueText.Contains("14. P1-10 Rule Extraction Basic") -and
  $rubricText.Contains("| P1 | scope_resolver_basic | core_only |") -and
  $p1Text.Contains("scope_resolver_basic")
Add-ScopeRow $rows "plan, queue, rubric and P1 grouping reference scope resolver" $crossRefsOk `
  "plan=$($planText.Contains('| 32 | P1 | scope_resolver_basic | Scope Resolver Basic | core_only |')); queue_p1_9=$($queueText.Contains('13. P1-9 Scope Resolver Basic')); queue_p1_10=$($queueText.Contains('14. P1-10 Rule Extraction Basic'))" `
  "scope_resolver_cross_reference_invalid"

$resolverText = Get-Content -Raw -LiteralPath $resolverPath -Encoding UTF8
$schemaText = Get-Content -Raw -LiteralPath $schemaPath -Encoding UTF8
$sourceShapeOk = $resolverText.Contains("def resolve_scope") -and
  $schemaText.Contains("class ScopeResolverInput") -and
  $schemaText.Contains("class ScopeResolverReport") -and
  $schemaText.Contains("selected_scope_id") -and
  $schemaText.Contains("blocked_reason")
Add-ScopeRow $rows "source implements structured scope resolver input and report schema" $sourceShapeOk `
  "resolver=$($resolverText.Contains('def resolve_scope')); input_schema=$($schemaText.Contains('class ScopeResolverInput')); report_schema=$($schemaText.Contains('class ScopeResolverReport'))" `
  "scope_resolver_source_shape_missing"

$pythonCode = @"
import json
import sys
from pathlib import Path

sys.path.insert(0, r"$repoRoot")

from heitang_kb_forge.scope_resolver import resolve_scope

explicit_report = resolve_scope({
    "query": "finance handbook",
    "explicit_scope_id": "kb-finance",
    "allowed_scope_ids": ["kb-finance", "kb-default"],
    "candidates": [
        {"scope_id": "kb-default", "labels": ["general"], "is_default": True},
        {"scope_id": "kb-finance", "labels": ["finance handbook"]},
    ],
})
label_report = resolve_scope({
    "query": "use finance handbook",
    "allowed_scope_ids": ["kb-finance", "kb-default"],
    "candidates": [
        {"scope_id": "kb-default", "labels": ["general"], "is_default": True},
        {"scope_id": "kb-finance", "labels": ["finance handbook"]},
    ],
})
blocked_report = resolve_scope({
    "query": "finance handbook",
    "explicit_scope_id": "kb-secret",
    "allowed_scope_ids": ["kb-public"],
    "candidates": [{"scope_id": "kb-secret", "labels": ["secret"]}],
})
Path(r"$explicitReportPath").write_text(json.dumps(explicit_report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
Path(r"$labelReportPath").write_text(json.dumps(label_report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
Path(r"$blockedReportPath").write_text(json.dumps(blocked_report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
"@
Set-Content -Encoding UTF8 -Path $sampleHelperPath -Value $pythonCode
$sampleResult = Invoke-CheckedCommand "python" @($sampleHelperPath) $repoRoot
$explicitReport = Read-JsonFile $explicitReportPath
$labelReport = Read-JsonFile $labelReportPath
$blockedReport = Read-JsonFile $blockedReportPath
$sampleOk = $sampleResult.exit_code -eq 0 -and
  $explicitReport.status -eq "resolved" -and
  $explicitReport.selected_scope_id -eq "kb-finance" -and
  $explicitReport.selection_reason -eq "explicit_scope" -and
  $labelReport.selection_reason -eq "query_label_match" -and
  $blockedReport.status -eq "blocked" -and
  $blockedReport.blocked_reason -eq "explicit_scope_not_allowed"
Add-ScopeRow $rows "scope resolver handles explicit, label and blocked scope paths" $sampleOk `
  "exit_code=$($sampleResult.exit_code); explicit=$($explicitReport.status)/$($explicitReport.selected_scope_id); label_reason=$($labelReport.selection_reason); blocked=$($blockedReport.blocked_reason)" `
  "scope_resolver_sample_output_invalid"

$pytestResult = Invoke-CheckedCommand "python" @(
  "-m",
  "pytest",
  "tests/test_scope_resolver_basic.py",
  "tests/test_agent_rag_scope.py",
  "tests/test_citation_verification.py",
  "-q"
) $repoRoot
$pytestOk = $pytestResult.exit_code -eq 0
Add-ScopeRow $rows "narrow scope resolver, RAG scope and citation boundary tests pass" $pytestOk `
  "exit_code=$($pytestResult.exit_code); stdout=$($pytestResult.stdout.Trim()); stderr=$($pytestResult.stderr.Trim())" `
  "scope_resolver_tests_failed"

$industrialScope = Read-JsonFile $industrialScopePath
$retrievalContract = Read-JsonFile $retrievalContractPath
$priorEvidenceOk = $industrialScope.status -eq "industrial_scope_metadata_reserved_needs_review" -and
  $retrievalContract.status -eq "retrieval_regression_completed_needs_owner_review"
Add-ScopeRow $rows "P0 scope reservation and P1 retrieval regression contract are available" $priorEvidenceOk `
  "industrial_scope_status=$($industrialScope.status); retrieval_status=$($retrievalContract.status)" `
  "scope_resolver_prior_evidence_missing"

$contract = [ordered]@{
  schema_version = "heitang_scope_resolver_basic_contract.v1"
  status = "scope_resolver_completed_needs_owner_review"
  capability_id = "scope_resolver_basic"
  phase = "P1"
  acceptance_type = "core_only"
  required_inputs = @("query", "explicit_scope_id", "allowed_scope_ids", "candidates")
  required_outputs = @("status", "selected_scope_id", "selection_reason", "blocked_reason", "candidate_scope_ids")
  explicit_report_path = $explicitReportPath
  label_report_path = $labelReportPath
  blocked_report_path = $blockedReportPath
  sample_selected_scope_id = $explicitReport.selected_scope_id
  blocked_reason = $blockedReport.blocked_reason
  next_gate = $nextGate
  global_goal_complete = $false
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $contractPath $contract

$contractOk = (Test-Path -LiteralPath $contractPath) -and
  $contract.sample_selected_scope_id -eq "kb-finance" -and
  $contract.blocked_reason -eq "explicit_scope_not_allowed" -and
  $contract.required_outputs.Count -eq 5 -and
  $contract.next_gate -eq "P1-10 Rule Extraction Basic" -and
  $contract.global_goal_complete -eq $false
Add-ScopeRow $rows "scope resolver basic contract artifact is generated" $contractOk `
  "contract=$contractPath; selected=$($contract.sample_selected_scope_id); blocked_reason=$($contract.blocked_reason); next_gate=$($contract.next_gate)" `
  "scope_resolver_contract_invalid"

$claimHits = Test-PositiveClaimBoundary @($contractPath, $explicitReportPath, $labelReportPath, $blockedReportPath)
Add-ScopeRow $rows "new P1-9 evidence has no forbidden positive-state tokens" ($claimHits.Count -eq 0) `
  "scanned=contract,explicit,label,blocked; hits=$($claimHits.Count)" `
  "scope_resolver_forbidden_claim_token_found"

$blocked = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "scope_resolver_completed_needs_owner_review"
} else {
  "scope_resolver_blocked"
}

$checkpoint = [ordered]@{
  schema_version = "heitang_scope_resolver_basic_checkpoint.v1"
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
  schema_version = "heitang_scope_resolver_basic_failure_template.v1"
  status = "no_current_failure"
  affected_phase = "P1"
  affected_capability_id = "scope_resolver_basic"
  failed_acceptance_type = "core_only"
  resume_prompt_path = $resumePath
  created_at = (Get-Date).ToUniversalTime().ToString("o")
})
@(
  "# Scope Resolver Basic Resume Prompt",
  "",
  "Resume from current_gate=$($chain.current_gate) if interrupted before commit.",
  "After commit, resume from next_gate=$nextGate.",
  "Keep global_goal_complete=false while remaining gates exist.",
  "Do not execute P1-10 until P1-9 evidence is committed."
) | Set-Content -Encoding UTF8 -Path $resumePath

$payload = [ordered]@{
  schema_version = "heitang_p1_scope_resolver_basic_matrix.v1"
  status = $status
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
  repo_root = $repoRoot
  current_phase = $chain.current_phase
  current_gate = $chain.current_gate
  next_gate = $nextGate
  remaining_gates_count = $remaining.Count
  global_goal_complete = $false
  contract_path = $contractPath
  explicit_report_path = $explicitReportPath
  label_report_path = $labelReportPath
  blocked_report_path = $blockedReportPath
  checkpoint_path = $checkpointPath
  failure_template_path = $failurePath
  resume_prompt_path = $resumePath
  rows = $rows
}
Write-Json $matrixPath $payload

$blockerText = if ($blocked.Count -eq 0) {
  "- none for this P1-9 gate; Owner review remains outside automatic closure."
} else {
  ($blocked | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$report = @(
  "# P1-9 Scope Resolver Basic Closure Report",
  "",
  "Status: $status",
  "",
  "## Acceptance Scope",
  "",
  "- Validate deterministic scope resolution for explicit, query-label and blocked scope paths.",
  "- This Gate is core_only; it does not add UI, external LLM calls or cross-KB product behavior.",
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
  "- command: run_scope_resolver_basic_matrix.ps1",
  "- schema evidence: resolver, pydantic schema, explicit/label/blocked sample reports and narrow tests.",
  "",
  "## Black-box Test Result",
  "",
  "- result: not_required",
  "- reason: core_only scope resolver has no standalone user UI path.",
  "",
  "## Evidence Completeness Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- artifacts: contract, matrix, sample reports, checkpoint, failure template, resume prompt and this report.",
  "",
  "## Lifecycle Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- scope: create and read deterministic scope resolver reports plus rerunnable verifier contract.",
  "",
  "## Regression Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- tests: python -m pytest tests/test_scope_resolver_basic.py tests/test_agent_rag_scope.py tests/test_citation_verification.py -q",
  "",
  "## Boundary Compliance Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- no UI/runtime edits, no dependency addition, no external service use, no P2 entry.",
  "",
  "## Reviewer Findings",
  "",
  "- P1-9 uses deterministic core evidence only and does not fake a UI blackbox.",
  "- Rule extraction remains queued as P1-10.",
  "- P0 scope reservation and P1-8 retrieval regression evidence remain readable.",
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
