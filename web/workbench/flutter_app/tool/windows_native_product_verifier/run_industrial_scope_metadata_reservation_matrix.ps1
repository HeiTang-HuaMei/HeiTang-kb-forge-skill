param(
  [string]$ExePath = "",
  [string]$OutputRoot = "",
  [int]$TimeoutSeconds = 420,
  [switch]$ClearWorkspace
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($ExePath)) {
  $ExePath = Get-DefaultExePath
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
  $OutputRoot = Join-Path (Get-AppRoot) "output\capability_blackbox"
}

function Add-MatrixRow(
  [System.Collections.ArrayList]$Rows,
  [string]$PathName,
  [string]$Step,
  [string]$Expected,
  [string]$Actual,
  [string]$DataFilePath,
  [bool]$Persistent,
  [bool]$RestartVerified,
  [string]$Conclusion,
  [string]$Blocker = ""
) {
  [void]$Rows.Add([ordered]@{
    path = $PathName
    step = $Step
    expected = $Expected
    actual = $Actual
    data_file_path = $DataFilePath
    persisted = $Persistent
    exe_restart_verified = $RestartVerified
    current_conclusion = $Conclusion
    blocker = $Blocker
  })
}

function Test-HasField($Object, [string]$Name) {
  if ($null -eq $Object) { return $false }
  return $null -ne ($Object.PSObject.Properties[$Name])
}

function Test-Fields($Object, [string[]]$Fields) {
  $missing = @()
  foreach ($field in $Fields) {
    if (-not (Test-HasField $Object $field)) { $missing += $field }
  }
  return $missing
}

function Wait-ForScopeArtifacts([string[]]$Paths, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    $missing = @($Paths | Where-Object { -not (Test-Path -LiteralPath $_) })
    if ($missing.Count -eq 0) { return $true }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $false
}

function Write-GateReport(
  [string]$Path,
  [string]$Status,
  [string]$MatrixPath,
  [string]$Workspace,
  [int]$BlockedCount,
  [string[]]$Blockers
) {
  $blockerText = if ($BlockedCount -eq 0) {
    "- 无 P0 元数据预留阻断项，等待 Owner 复核。"
  } else {
    ($Blockers | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { "- $_" }) -join "`n"
  }
  $report = @(
    "# Industrial Scope Metadata Reservation Report",
    "",
    "## Current Status",
    "",
    $Status,
    "",
    "## Scope",
    "",
    "- 验证 Event Ledger / Artifact Catalog / Knowledge Catalog / Agent Manifest / Validation Report / AI Config Governance 的工业级知识作用域字段预留。",
    "- 本 Gate 只验证 metadata reservation，不验证 Evidence Graph、Rule Engine、跨库推理或语义推理。",
    "",
    "## Blackbox Evidence",
    "",
    "- Matrix: $MatrixPath",
    "- Workspace: $Workspace",
    "",
    "## Allowed Status",
    "",
    "- industrial_scope_metadata_reserved_needs_review",
    "- event_scope_reserved_needs_review",
    "- artifact_scope_reserved_needs_review",
    "- ai_config_governance_reserved_needs_review",
    "- semantic_reasoning_not_implemented",
    "- rule_engine_not_implemented",
    "",
    "## Verification Result",
    "",
    "- blocked rows: $BlockedCount",
    "- current status: $Status",
    "",
    "## Remaining Blockers",
    "",
    $blockerText
  ) -join "`n"
  $parent = Split-Path -Parent $Path
  if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  $report | Set-Content -Encoding UTF8 -Path $Path
}

if ($ClearWorkspace) {
  Clear-WorkbenchWorkspace
}

$workspace = Get-WorkspacePath
$matrixDir = Join-Path $OutputRoot "industrial_scope"
$runDir = New-VerifierRunDir $matrixDir "industrial_scope_metadata"
$matrixPath = Join-Path $matrixDir "industrial_scope_metadata_reservation_matrix.json"
$reportPath = Join-Path (Get-AppRoot) "..\..\..\docs\audits\current\industrial_scope_metadata_reservation_report.md"
$ledgerPath = Join-Path $workspace "audit\event_ledger.jsonl"
$artifactCatalogPath = Join-Path $workspace "artifacts\catalog.json"
$kbCatalogPath = Join-Path $workspace "knowledge_bases\kb_catalog.json"
$validationReportPath = Join-Path $workspace "query\validation_report.json"
$agentManifestPath = Join-Path $workspace "agent\knowledge_qa_agent\agent_manifest.json"
$agentCatalogPath = Join-Path $workspace "agent\catalog\agents.json"
$configAssetsPath = Join-Path $workspace "config\project_config_assets.json"
$rows = [System.Collections.ArrayList]::new()
$launch = $null

try {
  $launch = Start-WorkbenchExeWithEnv $ExePath @{ HEITANG_RC10_OWNER_INPUT_E2E = "1" }
  Set-NativeWindowSize $launch.hwnd 1440 900

  $requiredPaths = @(
    $ledgerPath,
    $artifactCatalogPath,
    $kbCatalogPath,
    $validationReportPath,
    $agentManifestPath,
    $configAssetsPath
  )
  $pathsReady = Wait-ForScopeArtifacts $requiredPaths $TimeoutSeconds

  Stop-WorkbenchExe $launch
  $launch = $null
  $launch = Start-WorkbenchExe $ExePath
  Set-NativeWindowSize $launch.hwnd 1440 900
  $restartReady = Wait-ForScopeArtifacts $requiredPaths 60

  $kbCatalog = Read-JsonFile $kbCatalogPath
  [array]$kbRows = if ($null -ne $kbCatalog -and $null -ne $kbCatalog.knowledge_bases) { $kbCatalog.knowledge_bases } else { @() }
  $kb = if ($kbRows.Count -gt 0) { $kbRows[0] } else { $null }
  $kbMissing = Test-Fields $kb @(
    "workspace_id",
    "project_id",
    "version_id",
    "knowledge_base_version_id",
    "domain",
    "risk_level",
    "jurisdiction_scope",
    "time_scope",
    "default_answer_policy",
    "cross_kb_default",
    "permission_scope",
    "scope_metadata_reserved",
    "semantic_reasoning_status",
    "rule_engine_status"
  )
  $kbOk = $pathsReady -and $restartReady -and $kbMissing.Count -eq 0
  Add-MatrixRow $rows "Knowledge Catalog" "reserve KB scope metadata" `
    "kb_catalog.json 每条知识库记录保留 workspace/project/version/domain/risk/jurisdiction/time/policy 字段" `
    "kb_count=$($kbRows.Count); missing=$($kbMissing -join ',')" `
    $kbCatalogPath $kbOk $restartReady `
    ($(if ($kbOk) { "industrial_scope_metadata_reserved_needs_review" } else { "blocked" })) `
    ($(if ($kbOk) { "" } else { "kb_scope_fields_missing" }))

  $events = @(Read-JsonlFile $ledgerPath)
  $event = $events | Where-Object { $_.primary_knowledge_base_id -or $_.metadata.primary_knowledge_base_id } | Select-Object -First 1
  $eventMissing = Test-Fields $event @(
    "workspace_id",
    "project_id",
    "assistant_id",
    "task_id",
    "user_id",
    "primary_knowledge_base_id",
    "used_knowledge_base_ids",
    "knowledge_base_version_ids",
    "kb_scope_mode",
    "permission_scope",
    "domain_scope",
    "jurisdiction_scope",
    "time_scope",
    "answer_status",
    "evidence_status",
    "risk_level"
  )
  $eventOk = $pathsReady -and $restartReady -and $events.Count -gt 0 -and $eventMissing.Count -eq 0
  Add-MatrixRow $rows "Event Ledger" "reserve event scope fields" `
    "event_ledger.jsonl 事件记录保留 scope/evidence/answer/risk 字段" `
    "event_count=$($events.Count); missing=$($eventMissing -join ',')" `
    $ledgerPath $eventOk $restartReady `
    ($(if ($eventOk) { "event_scope_reserved_needs_review" } else { "blocked" })) `
    ($(if ($eventOk) { "" } else { "event_scope_fields_missing" }))

  $artifactCatalog = Read-JsonFile $artifactCatalogPath
  [array]$artifactRows = if ($null -ne $artifactCatalog -and $null -ne $artifactCatalog.artifacts) { $artifactCatalog.artifacts } else { @() }
  $artifact = $artifactRows | Where-Object { $_.status -ne "deleted" -and $_.primary_knowledge_base_id } | Select-Object -First 1
  $artifactMissing = Test-Fields $artifact @(
    "workspace_id",
    "project_id",
    "assistant_id",
    "task_id",
    "user_id",
    "primary_knowledge_base_id",
    "used_knowledge_base_ids",
    "knowledge_base_version_ids",
    "source_document_ids",
    "source_chunk_ids",
    "answer_status",
    "evidence_status",
    "risk_level",
    "validation_report_path",
    "reasoning_report_path"
  )
  $artifactOk = $pathsReady -and $restartReady -and $artifactRows.Count -gt 0 -and $artifactMissing.Count -eq 0
  Add-MatrixRow $rows "Artifact Catalog" "reserve artifact scope fields" `
    "artifacts/catalog.json 成果记录保留来源知识库、版本、source_trace、answer/evidence/risk/report 字段" `
    "artifact_count=$($artifactRows.Count); missing=$($artifactMissing -join ',')" `
    $artifactCatalogPath $artifactOk $restartReady `
    ($(if ($artifactOk) { "artifact_scope_reserved_needs_review" } else { "blocked" })) `
    ($(if ($artifactOk) { "" } else { "artifact_scope_fields_missing" }))

  $validationReport = Read-JsonFile $validationReportPath
  $validationMissing = Test-Fields $validationReport @(
    "scope_resolution",
    "primary_knowledge_base_id",
    "used_knowledge_base_ids",
    "knowledge_base_version_ids",
    "answer_status",
    "evidence_status",
    "risk_level",
    "missing_evidence",
    "exception_count",
    "human_review_required",
    "semantic_reasoning_status",
    "rule_engine_status"
  )
  $validationOk = $pathsReady -and $restartReady -and $validationMissing.Count -eq 0
  Add-MatrixRow $rows "Validation Report" "reserve answer/evidence reliability fields" `
    "validation_report.json 保留 scope_resolution、answer_status、evidence_status、risk 和 not_implemented 边界" `
    "missing=$($validationMissing -join ','); answer_status=$($validationReport.answer_status); evidence_status=$($validationReport.evidence_status)" `
    $validationReportPath $validationOk $restartReady `
    ($(if ($validationOk) { "industrial_scope_metadata_reserved_needs_review" } else { "blocked" })) `
    ($(if ($validationOk) { "" } else { "validation_scope_fields_missing" }))

  $agentManifest = Read-JsonFile $agentManifestPath
  $agentMissing = Test-Fields $agentManifest @(
    "scope_metadata_schema_version",
    "scope_metadata_reserved",
    "bound_knowledge_base_ids",
    "primary_knowledge_base_id",
    "allowed_reference_kb_ids",
    "knowledge_base_version_ids",
    "kb_scope_mode",
    "permission_scope",
    "answer_policy_id",
    "ai_profile_id",
    "risk_level",
    "semantic_reasoning_status",
    "rule_engine_status"
  )
  $agentOk = $pathsReady -and $restartReady -and $agentMissing.Count -eq 0
  Add-MatrixRow $rows "Agent Manifest" "reserve assistant KB scope fields" `
    "knowledge_qa_agent/agent_manifest.json 保留 primary/reference/scope/policy/ai_profile 字段" `
    "missing=$($agentMissing -join ','); kb_scope_mode=$($agentManifest.kb_scope_mode)" `
    $agentManifestPath $agentOk $restartReady `
    ($(if ($agentOk) { "industrial_scope_metadata_reserved_needs_review" } else { "blocked" })) `
    ($(if ($agentOk) { "" } else { "agent_scope_fields_missing" }))

  $agentCatalog = Read-JsonFile $agentCatalogPath
  [array]$agentCatalogRows = if ($null -ne $agentCatalog -and $null -ne $agentCatalog.agents) { $agentCatalog.agents } else { @() }
  $agentProfile = $agentCatalogRows | Select-Object -First 1
  $agentProfileMissing = if ($null -eq $agentProfile) {
    @("agent_profile_absent")
  } else {
    Test-Fields $agentProfile @(
      "workspace_id",
      "primary_knowledge_base_id",
      "allowed_reference_kb_ids",
      "kb_scope_mode",
      "answer_policy_id",
      "ai_profile_id"
    )
  }
  $agentProfileOk = $pathsReady -and $restartReady -and ($agentCatalogRows.Count -eq 0 -or $agentProfileMissing.Count -eq 0)
  Add-MatrixRow $rows "Agent Catalog" "reserve persisted assistant profile fields" `
    "agent/catalog/agents.json 若存在用户助手配置，必须保留 workspace/primary/reference/scope/policy/ai_profile 字段" `
    "agent_profile_count=$($agentCatalogRows.Count); missing=$($agentProfileMissing -join ',')" `
    $agentCatalogPath $agentProfileOk $restartReady `
    ($(if ($agentProfileOk) { "industrial_scope_metadata_reserved_needs_review" } else { "blocked" })) `
    ($(if ($agentProfileOk) { "" } else { "agent_profile_scope_fields_missing" }))

  $configAssets = Read-JsonFile $configAssetsPath
  $aiGovernance = $configAssets.config_assets.ai_config_governance
  $aiMissing = Test-Fields $aiGovernance @(
    "schema_version",
    "status",
    "task_profiles",
    "kb_profiles",
    "risk_profiles",
    "answer_policies",
    "verifier_profiles",
    "semantic_reasoning_status",
    "rule_engine_status"
  )
  $aiOk = $pathsReady -and $restartReady -and $aiMissing.Count -eq 0 -and $aiGovernance.status -eq "ai_config_governance_reserved_needs_review"
  Add-MatrixRow $rows "AI Config Governance" "reserve AI profile governance fields" `
    "project_config_assets.json 保留 task/kb/risk/answer/verifier profile，且状态只为 needs_review" `
    "missing=$($aiMissing -join ','); status=$($aiGovernance.status)" `
    $configAssetsPath $aiOk $restartReady `
    ($(if ($aiOk) { "ai_config_governance_reserved_needs_review" } else { "blocked" })) `
    ($(if ($aiOk) { "" } else { "ai_config_governance_fields_missing" }))

  $blocked = @($rows | Where-Object { $_.current_conclusion -eq "blocked" })
  $status = if ($blocked.Count -eq 0) {
    "industrial_scope_metadata_reserved_needs_review"
  } else {
    "industrial_scope_metadata_reservation_blocked"
  }
  $payload = [ordered]@{
    status = $status
    workspace = $workspace
    matrix = $rows
    run_dir = $runDir
    paths_ready = $pathsReady
    restart_verified = $restartReady
    semantic_reasoning_status = "semantic_reasoning_not_implemented"
    rule_engine_status = "rule_engine_not_implemented"
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Json $matrixPath $payload
  Write-Json (Join-Path $runDir "industrial_scope_metadata_reservation_matrix.json") $payload
  Write-GateReport `
    -Path $reportPath `
    -Status $status `
    -MatrixPath $matrixPath `
    -Workspace $workspace `
    -BlockedCount $blocked.Count `
    -Blockers @($blocked | ForEach-Object { $_.blocker })

  Write-Output "status=$status"
  Write-Output "matrix=$matrixPath"
  Write-Output "report=$reportPath"
  if ($blocked.Count -gt 0) { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
