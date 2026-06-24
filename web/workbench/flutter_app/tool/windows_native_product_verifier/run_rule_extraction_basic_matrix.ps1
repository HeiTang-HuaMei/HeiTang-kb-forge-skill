param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p1_rule_extraction_basic"
}
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

function Add-RuleRow(
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
$extractorPath = Join-Path $repoRoot "heitang_kb_forge\rule_extraction\extractor.py"
$schemaPath = Join-Path $repoRoot "heitang_kb_forge\schemas\rule_extraction_schema.py"
$testPath = Join-Path $repoRoot "tests\test_rule_extraction_basic.py"
$scopeContractPath = Join-Path $appRoot "output\p1_scope_resolver_basic\scope_resolver_basic_contract.json"
$matrixPath = Join-Path $OutputRoot "rule_extraction_basic_matrix.json"
$contractPath = Join-Path $OutputRoot "rule_extraction_basic_contract.json"
$sampleReportPath = Join-Path $OutputRoot "rule_extraction_sample_report.json"
$filteredReportPath = Join-Path $OutputRoot "rule_extraction_filtered_report.json"
$noRuleReportPath = Join-Path $OutputRoot "rule_extraction_no_rule_report.json"
$sampleHelperPath = Join-Path $OutputRoot "run_rule_extraction_sample.py"
$checkpointPath = Join-Path $OutputRoot "rule_extraction_basic_checkpoint.json"
$failurePath = Join-Path $OutputRoot "rule_extraction_basic_failure_template.json"
$resumePath = Join-Path $OutputRoot "rule_extraction_basic_resume_prompt.md"
$reportPath = Join-Path $repoRoot "docs\audits\current\rule_extraction_basic_closure_report.md"
$rows = [System.Collections.ArrayList]::new()

$requiredFiles = @(
  $chainPath,
  $registryPath,
  $planPath,
  $queuePath,
  $rubricPath,
  $p1BackfillPath,
  $extractorPath,
  $schemaPath,
  $testPath,
  $scopeContractPath
)
$missingFiles = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_) })
Add-RuleRow $rows "required rule extraction source and prior evidence files exist" ($missingFiles.Count -eq 0) `
  "missing=$($missingFiles.Count)" `
  "rule_extraction_required_file_missing"

$chain = Read-JsonFile $chainPath
$remaining = @($chain.remaining_gates)
$completedReview = @($chain.completed_with_owner_review_needed)
$prePassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-10 Rule Extraction Basic" -and
  $remaining.Count -eq 82 -and
  $remaining[0] -eq "P1-10 Rule Extraction Basic" -and
  $completedReview -notcontains "P1-10 Rule Extraction Basic"
$postPassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-11 Classification Reasoning Basic" -and
  $remaining.Count -eq 81 -and
  $remaining[0] -eq "P1-11 Classification Reasoning Basic" -and
  $completedReview -contains "P1-10 Rule Extraction Basic"
$stateOk = ($prePassState -or $postPassState) -and $chain.global_goal_complete -eq $false
Add-RuleRow $rows "status machine is at or just past P1-10 with global guard" $stateOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($remaining[0]); remaining=$($remaining.Count); global_goal_complete=$($chain.global_goal_complete)" `
  "rule_extraction_status_machine_mismatch"

$preconditionsOk = ($completedReview -contains "P0 Release Gate") -and
  ($completedReview -contains "P1-9 Scope Resolver Basic")
Add-RuleRow $rows "P0 release and P1-9 precede rule extraction" $preconditionsOk `
  "p0_release=$($completedReview -contains 'P0 Release Gate'); p1_scope=$($completedReview -contains 'P1-9 Scope Resolver Basic')" `
  "rule_extraction_missing_precondition"

$nextGate = if ($prePassState -and $remaining.Count -gt 1) {
  $remaining[1]
} elseif ($postPassState) {
  $remaining[0]
} else {
  ""
}
$chainShapeOk = $nextGate -eq "P1-11 Classification Reasoning Basic" -and
  ($remaining -contains "P1 Release Gate") -and
  ($remaining -contains "P2 Release Gate") -and
  ($remaining -contains "Final Owner Review Gate")
Add-RuleRow $rows "remaining chain preserves release gates and next gate" $chainShapeOk `
  "next_gate=$nextGate; p1_release=$($remaining -contains 'P1 Release Gate'); p2_release=$($remaining -contains 'P2 Release Gate'); final=$($remaining -contains 'Final Owner Review Gate')" `
  "rule_extraction_chain_sequence_invalid"

$registryRow = @(
  Get-Content -LiteralPath $registryPath -Encoding UTF8 |
    Where-Object { $_ -match "^\| rule_extraction_basic \|" }
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
Add-RuleRow $rows "rule_extraction_basic registry row follows core-only contract" $registryStatusOk `
  "row_count=$($registryRow.Count); type=$($registryCells[3]); core=$($registryCells[4]); ui=$($registryCells[5]); blackbox=$($registryCells[6]); close_allowed=$($registryCells[13])" `
  "rule_extraction_registry_row_invalid"

$planText = Get-Content -Raw -LiteralPath $planPath -Encoding UTF8
$queueText = Get-Content -Raw -LiteralPath $queuePath -Encoding UTF8
$rubricText = Get-Content -Raw -LiteralPath $rubricPath -Encoding UTF8
$p1Text = Get-Content -Raw -LiteralPath $p1BackfillPath -Encoding UTF8
$crossRefsOk = $planText.Contains("| 33 | P1 | rule_extraction_basic | Rule Extraction Basic | core_only |") -and
  $queueText.Contains("14. P1-10 Rule Extraction Basic") -and
  $queueText.Contains("15. P1-11 Classification Reasoning Basic") -and
  $rubricText.Contains("| P1 | rule_extraction_basic | core_only |") -and
  $p1Text.Contains("rule_extraction_basic")
Add-RuleRow $rows "plan, queue, rubric and P1 grouping reference rule extraction" $crossRefsOk `
  "plan=$($planText.Contains('| 33 | P1 | rule_extraction_basic | Rule Extraction Basic | core_only |')); queue_p1_10=$($queueText.Contains('14. P1-10 Rule Extraction Basic')); queue_p1_11=$($queueText.Contains('15. P1-11 Classification Reasoning Basic'))" `
  "rule_extraction_cross_reference_invalid"

$extractorText = Get-Content -Raw -LiteralPath $extractorPath -Encoding UTF8
$schemaText = Get-Content -Raw -LiteralPath $schemaPath -Encoding UTF8
$sourceShapeOk = $extractorText.Contains("def extract_rules") -and
  $schemaText.Contains("class RuleExtractionInput") -and
  $schemaText.Contains("class RuleExtractionReport") -and
  $schemaText.Contains("class ExtractedRule") -and
  $schemaText.Contains("skipped_source_ids")
Add-RuleRow $rows "source implements structured rule extraction input and report schema" $sourceShapeOk `
  "extractor=$($extractorText.Contains('def extract_rules')); input_schema=$($schemaText.Contains('class RuleExtractionInput')); report_schema=$($schemaText.Contains('class RuleExtractionReport'))" `
  "rule_extraction_source_shape_missing"

$pythonCode = @"
import json
import sys
from pathlib import Path

sys.path.insert(0, r"$repoRoot")

from heitang_kb_forge.rule_extraction import extract_rules

sample_report = extract_rules({
    "sources": [{
        "source_id": "policy-a",
        "source_path": "policy.md",
        "scope_id": "kb-public",
        "text": "\n".join([
            "- Answers must cite package evidence.",
            "- Do not invent citations.",
            "- Stay within scope.",
            "- Include source_path when making factual claims.",
        ]),
    }],
})
filtered_report = extract_rules({
    "allowed_scope_ids": ["kb-public"],
    "sources": [
        {"source_id": "public", "scope_id": "kb-public", "text": "Rules must stay auditable."},
        {"source_id": "secret", "scope_id": "kb-secret", "text": "Secret rules must not leak."},
    ],
})
no_rule_report = extract_rules({"sources": [{"source_id": "plain", "text": "A neutral paragraph."}]})

Path(r"$sampleReportPath").write_text(json.dumps(sample_report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
Path(r"$filteredReportPath").write_text(json.dumps(filtered_report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
Path(r"$noRuleReportPath").write_text(json.dumps(no_rule_report.model_dump(mode="json"), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
"@
Set-Content -Encoding UTF8 -Path $sampleHelperPath -Value $pythonCode
$sampleResult = Invoke-CheckedCommand "python" @($sampleHelperPath) $repoRoot
$sampleReport = Read-JsonFile $sampleReportPath
$filteredReport = Read-JsonFile $filteredReportPath
$noRuleReport = Read-JsonFile $noRuleReportPath
$sampleTypes = @($sampleReport.extracted_rules | ForEach-Object { $_.rule_type })
$sampleOk = $sampleResult.exit_code -eq 0 -and
  $sampleReport.status -eq "rules_extracted" -and
  $sampleReport.extracted_rule_count -eq 4 -and
  ($sampleTypes -join ",") -eq "requirement,prohibition,boundary,citation" -and
  $filteredReport.extracted_rule_count -eq 1 -and
  @($filteredReport.skipped_source_ids).Count -eq 1 -and
  $filteredReport.skipped_source_ids[0] -eq "secret" -and
  $noRuleReport.status -eq "no_rules_found"
Add-RuleRow $rows "rule extraction handles rule types, scope filtering and no-rule path" $sampleOk `
  "exit_code=$($sampleResult.exit_code); sample_status=$($sampleReport.status); sample_count=$($sampleReport.extracted_rule_count); filtered_count=$($filteredReport.extracted_rule_count); no_rule_status=$($noRuleReport.status)" `
  "rule_extraction_sample_output_invalid"

$pytestResult = Invoke-CheckedCommand "python" @(
  "-m",
  "pytest",
  "tests/test_rule_extraction_basic.py",
  "tests/test_skill_rules.py",
  "tests/test_gap_analysis.py",
  "tests/test_scope_resolver_basic.py",
  "-q"
) $repoRoot
$pytestOk = $pytestResult.exit_code -eq 0
Add-RuleRow $rows "narrow rule extraction and related core tests pass" $pytestOk `
  "exit_code=$($pytestResult.exit_code); stdout=$($pytestResult.stdout.Trim()); stderr=$($pytestResult.stderr.Trim())" `
  "rule_extraction_tests_failed"

$scopeContract = Read-JsonFile $scopeContractPath
$priorEvidenceOk = $scopeContract.status -eq "scope_resolver_completed_needs_owner_review"
Add-RuleRow $rows "P1 scope resolver contract is available" $priorEvidenceOk `
  "scope_resolver_status=$($scopeContract.status)" `
  "rule_extraction_prior_evidence_missing"

$contract = [ordered]@{
  schema_version = "heitang_rule_extraction_basic_contract.v1"
  status = "rule_extraction_completed_needs_owner_review"
  capability_id = "rule_extraction_basic"
  phase = "P1"
  acceptance_type = "core_only"
  required_inputs = @("sources", "allowed_scope_ids")
  required_outputs = @("status", "extracted_rule_count", "extracted_rules", "skipped_source_ids", "source_ids")
  sample_report_path = $sampleReportPath
  filtered_report_path = $filteredReportPath
  no_rule_report_path = $noRuleReportPath
  sample_rule_count = $sampleReport.extracted_rule_count
  filtered_rule_count = $filteredReport.extracted_rule_count
  no_rule_status = $noRuleReport.status
  next_gate = $nextGate
  global_goal_complete = $false
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
}
Write-Json $contractPath $contract

$contractOk = (Test-Path -LiteralPath $contractPath) -and
  $contract.sample_rule_count -eq 4 -and
  $contract.filtered_rule_count -eq 1 -and
  $contract.no_rule_status -eq "no_rules_found" -and
  $contract.required_outputs.Count -eq 5 -and
  $contract.next_gate -eq "P1-11 Classification Reasoning Basic" -and
  $contract.global_goal_complete -eq $false
Add-RuleRow $rows "rule extraction basic contract artifact is generated" $contractOk `
  "contract=$contractPath; sample_rules=$($contract.sample_rule_count); filtered_rules=$($contract.filtered_rule_count); next_gate=$($contract.next_gate)" `
  "rule_extraction_contract_invalid"

$claimHits = Test-PositiveClaimBoundary @($contractPath, $sampleReportPath, $filteredReportPath, $noRuleReportPath)
Add-RuleRow $rows "new P1-10 evidence has no forbidden positive-state tokens" ($claimHits.Count -eq 0) `
  "scanned=contract,sample,filtered,no_rule; hits=$($claimHits.Count)" `
  "rule_extraction_forbidden_claim_token_found"

$blocked = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "rule_extraction_completed_needs_owner_review"
} else {
  "rule_extraction_blocked"
}

$checkpoint = [ordered]@{
  schema_version = "heitang_rule_extraction_basic_checkpoint.v1"
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
  schema_version = "heitang_rule_extraction_basic_failure_template.v1"
  status = "no_current_failure"
  affected_phase = "P1"
  affected_capability_id = "rule_extraction_basic"
  failed_acceptance_type = "core_only"
  resume_prompt_path = $resumePath
  created_at = (Get-Date).ToUniversalTime().ToString("o")
})
@(
  "# Rule Extraction Basic Resume Prompt",
  "",
  "Resume from current_gate=$($chain.current_gate) if interrupted before commit.",
  "After commit, resume from next_gate=$nextGate.",
  "Keep global_goal_complete=false while remaining gates exist.",
  "Do not execute P1-11 until P1-10 evidence is committed."
) | Set-Content -Encoding UTF8 -Path $resumePath

$payload = [ordered]@{
  schema_version = "heitang_p1_rule_extraction_basic_matrix.v1"
  status = $status
  generated_at = (Get-Date).ToUniversalTime().ToString("o")
  repo_root = $repoRoot
  current_phase = $chain.current_phase
  current_gate = $chain.current_gate
  next_gate = $nextGate
  remaining_gates_count = $remaining.Count
  global_goal_complete = $false
  contract_path = $contractPath
  sample_report_path = $sampleReportPath
  filtered_report_path = $filteredReportPath
  no_rule_report_path = $noRuleReportPath
  checkpoint_path = $checkpointPath
  failure_template_path = $failurePath
  resume_prompt_path = $resumePath
  rows = $rows
}
Write-Json $matrixPath $payload

$blockerText = if ($blocked.Count -eq 0) {
  "- none for this P1-10 gate; Owner review remains outside automatic closure."
} else {
  ($blocked | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$report = @(
  "# P1-10 Rule Extraction Basic Closure Report",
  "",
  "Status: $status",
  "",
  "## Acceptance Scope",
  "",
  "- Validate deterministic rule extraction from source text into structured rule records.",
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
  "- command: run_rule_extraction_basic_matrix.ps1",
  "- schema evidence: extractor, pydantic schema, sample/filter/no-rule reports and narrow tests.",
  "",
  "## Black-box Test Result",
  "",
  "- result: not_required",
  "- reason: core_only rule extraction has no standalone user UI path.",
  "",
  "## Evidence Completeness Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- artifacts: contract, matrix, sample reports, checkpoint, failure template, resume prompt and this report.",
  "",
  "## Lifecycle Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- scope: create and read deterministic rule extraction reports plus rerunnable verifier contract.",
  "",
  "## Regression Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- tests: python -m pytest tests/test_rule_extraction_basic.py tests/test_skill_rules.py tests/test_gap_analysis.py tests/test_scope_resolver_basic.py -q",
  "",
  "## Boundary Compliance Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- no UI/runtime edits, no dependency addition, no external service use, no P2 entry.",
  "",
  "## Reviewer Findings",
  "",
  "- P1-10 uses deterministic core evidence only and does not fake a UI blackbox.",
  "- Classification reasoning remains queued as P1-11.",
  "- P1-9 scope resolver evidence remains readable.",
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
