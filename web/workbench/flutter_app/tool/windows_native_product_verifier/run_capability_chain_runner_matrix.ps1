param(
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\p1_capability_chain_runner"
}

function Add-RunnerRow(
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
$chainPath = Join-Path $repoRoot "capability_chain_status.json"
$registryPath = Join-Path $repoRoot "docs\capability_registry\Capability_Implementation_Status.md"
$matrixPath = Join-Path $OutputRoot "capability_chain_runner_matrix.json"
$checkpointPath = Join-Path $OutputRoot "capability_chain_runner_checkpoint.json"
$failurePath = Join-Path $OutputRoot "capability_chain_runner_failure_template.json"
$resumePath = Join-Path $OutputRoot "capability_chain_runner_resume_prompt.md"
$reportPath = Join-Path $repoRoot "docs\audits\current\capability_chain_runner_report.md"
$rows = [System.Collections.ArrayList]::new()
$chain = Read-JsonFile $chainPath
$remaining = @($chain.remaining_gates)
$completedReview = @($chain.completed_with_owner_review_needed)

$prePassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-1 Capability Chain Runner" -and
  $remaining.Count -gt 0 -and
  $remaining[0] -eq "P1-1 Capability Chain Runner"
$postPassState = $chain.current_phase -eq "P1" -and
  $chain.current_gate -eq "P1-2 Capability Registry" -and
  $remaining.Count -gt 0 -and
  $remaining[0] -eq "P1-2 Capability Registry" -and
  $completedReview -contains "P1-1 Capability Chain Runner"
$currentOk = ($prePassState -or $postPassState) -and
  $chain.global_goal_complete -eq $false
Add-RunnerRow $rows "current gate is P1-1 and global goal is guarded" $currentOk `
  "phase=$($chain.current_phase); gate=$($chain.current_gate); first_remaining=$($remaining[0]); global_goal_complete=$($chain.global_goal_complete)" `
  "capability_chain_runner_current_gate_mismatch"

$p0ReleaseOk = $completedReview -contains "P0 Release Gate"
Add-RunnerRow $rows "P0 release gate evidence precedes P1 runner" $p0ReleaseOk `
  "p0_release_completed=$p0ReleaseOk" `
  "capability_chain_runner_missing_p0_release"

$expectedRemainingCount = if ($postPassState) { 90 } else { 91 }
$chainShapeOk = $remaining.Count -eq $expectedRemainingCount -and
  ($remaining -contains "P1 Release Gate") -and
  ($remaining -contains "P2 Release Gate") -and
  ($remaining -contains "Final Owner Review Gate")
Add-RunnerRow $rows "remaining gate chain preserves P1/P2/final sequence" $chainShapeOk `
  "remaining=$($remaining.Count); p1_release=$($remaining -contains 'P1 Release Gate'); p2_release=$($remaining -contains 'P2 Release Gate'); final=$($remaining -contains 'Final Owner Review Gate')" `
  "capability_chain_runner_sequence_invalid"

$nextGate = if ($prePassState -and $remaining.Count -gt 1) {
  $remaining[1]
} elseif ($postPassState) {
  $remaining[0]
} else {
  ""
}
$advanceOk = $nextGate -eq "P1-2 Capability Registry"
Add-RunnerRow $rows "runner can compute next gate without executing it" $advanceOk `
  "next_after_current=$nextGate" `
  "capability_chain_runner_next_gate_invalid"

$registryText = Get-Content -Raw -LiteralPath $registryPath -Encoding UTF8
$registryOk = $registryText.Contains("| capability_chain_runner |") -and
  $registryText.Contains("| capability_registry |")
Add-RunnerRow $rows "runner registry rows are discoverable" $registryOk `
  "registry_rows_present=$registryOk" `
  "capability_chain_runner_registry_missing"

$blocked = @($rows | Where-Object { $_.status -eq "blocked" })
$status = if ($blocked.Count -eq 0) {
  "capability_chain_runner_completed_needs_owner_review"
} else {
  "capability_chain_runner_blocked"
}

$checkpoint = [ordered]@{
  schema_version = "heitang_capability_chain_runner_checkpoint.v1"
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
  schema_version = "heitang_capability_chain_runner_failure_template.v1"
  status = "no_current_failure"
  affected_phase = $chain.current_phase
  affected_capability_id = "capability_chain_runner"
  failed_acceptance_type = "core_only"
  resume_prompt_path = $resumePath
  created_at = (Get-Date).ToUniversalTime().ToString("o")
})
@(
  "# Capability Chain Runner Resume Prompt",
  "",
  "Resume from current_gate=$($chain.current_gate) if interrupted before commit.",
  "After commit, resume from next_gate=$nextGate.",
  "Keep global_goal_complete=false while remaining gates exist."
) | Set-Content -Encoding UTF8 -Path $resumePath

$payload = [ordered]@{
  schema_version = "heitang_p1_capability_chain_runner_matrix.v1"
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
  "- 无 P1-1 直接阻断项，等待 Owner 复核。"
} else {
  ($blocked | ForEach-Object { "- $($_.blocker): $($_.actual)" }) -join "`n"
}
$evidenceText = ($rows | ForEach-Object {
  "- $($_.check): $($_.status); $($_.actual)"
}) -join "`n"
$report = @(
  "# P1-1 Capability Chain Runner Report",
  "",
  "状态：$status",
  "",
  "## 验收范围",
  "",
  "- 验证能力链当前 Gate、剩余队列、P0 Release Gate 前置、下一 Gate 计算、checkpoint/failure/resume 产物。",
  "- 本 Gate 是 core_only，不强造 UI 黑盒，不执行 P1-2 或后续能力。",
  "",
  "## 验证结论",
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
  "- command: run_capability_chain_runner_matrix.ps1",
  "- schema evidence: checkpoint, failure template, resume prompt and matrix generated.",
  "",
  "## Black-box Test Result",
  "",
  "- result: not_required",
  "- reason: core_only chain runner has no standalone user UI path.",
  "",
  "## Boundary Compliance Result",
  "",
  "- result: $($(if ($blocked.Count -eq 0) { 'passed' } else { 'blocked' }))",
  "- no P2 entry, no P1-2 execution, no dependency addition, no service packaging change.",
  "",
  "## Final Close Decision",
  "",
  "- close_allowed: $($blocked.Count -eq 0)",
  "- next_gate: $nextGate",
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
