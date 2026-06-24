param(
  [string]$ExePath = "",
  [string]$OutputRoot = "",
  [int]$TimeoutSeconds = 300,
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
  [string]$ScreenshotPath,
  [string]$DataFilePath,
  [string]$ArtifactPath,
  [bool]$Persistent,
  [bool]$ReentryVerified,
  [bool]$RestartVerified,
  [string]$Conclusion,
  [string]$Blocker = ""
) {
  [void]$Rows.Add([ordered]@{
    path = $PathName
    step = $Step
    expected = $Expected
    actual = $Actual
    screenshot_path = $ScreenshotPath
    data_file_path = $DataFilePath
    artifact_path = $ArtifactPath
    persisted = $Persistent
    reentry_verified = $ReentryVerified
    exe_restart_verified = $RestartVerified
    current_conclusion = $Conclusion
    blocker = $Blocker
  })
}

function Write-TextFile([string]$Path, [string]$Content) {
  $parent = Split-Path -Parent $Path
  if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  $Content | Set-Content -Encoding UTF8 -Path $Path
}

function Write-Utf8NoBomFile([string]$Path, [string]$Content) {
  $parent = Split-Path -Parent $Path
  if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  $encoding = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Count-Lines([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return 0 }
  return @((Get-Content -LiteralPath $Path -Encoding UTF8) | Where-Object { $_.Trim().Length -gt 0 }).Count
}

function Import-ClipboardPath($Hwnd, [string]$PathValue) {
  Set-VerifierClipboardText $PathValue
  [void][HtkwNativeVerifierCommon]::SetForegroundWindow($Hwnd)
  [void](Invoke-RelativeClick $Hwnd 0.55 0.30)
  Send-FunctionKey "F5"
}

function Invoke-ControlAltAction($Hwnd, [string]$Key) {
  [void][HtkwNativeVerifierCommon]::SetForegroundWindow($Hwnd)
  [void](Invoke-RelativeClick $Hwnd 0.55 0.30)
  [System.Windows.Forms.SendKeys]::SendWait("^%$($Key.ToLowerInvariant())")
  Start-Sleep -Seconds 1
}

function Wait-ForPathSet([string[]]$Paths, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    $missing = @($Paths | Where-Object { -not (Test-Path -LiteralPath $_) })
    if ($missing.Count -eq 0) { return $true }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $false
}

function Wait-ForSourceCount([string]$Workspace, [int]$ExpectedCount, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    $info = Get-SourceManifestInfo $Workspace
    if ($info.exists -and $info.source_count -eq $ExpectedCount) { return $true }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $false
}

function Get-EventCount([string]$LedgerPath, [string]$EventType) {
  return @(Read-JsonlFile $LedgerPath | Where-Object { $_.event_type -eq $EventType }).Count
}

function Get-LatestEvent([string]$LedgerPath, [string]$EventType) {
  $events = @(Read-JsonlFile $LedgerPath | Where-Object { $_.event_type -eq $EventType })
  if ($events.Count -eq 0) { return $null }
  return $events | Sort-Object created_at -Descending | Select-Object -First 1
}

function Wait-ForLatestFailure([string]$LedgerPath, [string]$Contains, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    $events = @(Read-JsonlFile $LedgerPath | Where-Object {
      $_.event_type -eq "failure_event" -and ([string]$_.error_message).Contains($Contains)
    })
    if ($events.Count -gt 0) {
      return $events | Sort-Object created_at -Descending | Select-Object -First 1
    }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $null
}

function Wait-ForEventCountGreater([string]$LedgerPath, [string]$EventType, [int]$PreviousCount, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    $count = Get-EventCount $LedgerPath $EventType
    if ($count -gt $PreviousCount) { return $true }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $false
}

function Invoke-WorkbenchButtonUntilEventAndPaths(
  $Hwnd,
  [string]$LedgerPath,
  [string]$EventType,
  [int]$PreviousEventCount,
  [string[]]$Paths,
  [int]$TimeoutSeconds,
  [scriptblock]$ClickAction
) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    & $ClickAction
    $eventReady = Wait-ForEventCountGreater $LedgerPath $EventType $PreviousEventCount 18
    $pathsReady = Wait-ForPathSet $Paths 5
    if ($eventReady -and $pathsReady) { return $true }
    Start-Sleep -Seconds 2
  } while ((Get-Date) -lt $deadline)
  return $false
}

function Wait-ForQueryArtifacts([string]$Workspace, [string]$QueryValue, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    $summary = Test-QueryArtifactSummary $Workspace $QueryValue
    if ($summary.ok) { return $summary }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return Test-QueryArtifactSummary $Workspace $QueryValue
}

function Wait-ForValidationReport([string]$Workspace, [string]$LedgerPath, [string]$QueryValue, [int]$PreviousValidateCount, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    $summary = Test-ValidationReportSummary $Workspace $LedgerPath $QueryValue
    $eventReady = (Get-EventCount $LedgerPath "validate_knowledge_base") -gt $PreviousValidateCount
    if ($summary.ok -and $eventReady) { return $summary }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return Test-ValidationReportSummary $Workspace $LedgerPath $QueryValue
}

function Invoke-SaveValidationReportUntilEvent(
  $Hwnd,
  [string]$Workspace,
  [string]$LedgerPath,
  [string]$QueryValue,
  [int]$PreviousValidateCount,
  [int]$TimeoutSeconds
) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    Invoke-SaveValidationReportButton $Hwnd
    $summary = Wait-ForValidationReport $Workspace $LedgerPath $QueryValue $PreviousValidateCount 20
    if ($summary.ok) { return $summary }
    Start-Sleep -Seconds 1
  } while ((Get-Date) -lt $deadline)
  return Test-ValidationReportSummary $Workspace $LedgerPath $QueryValue
}

function Open-DocumentLibraryPage($Hwnd) {
  [void](Invoke-RelativeClick $Hwnd 0.09 0.29)
  Start-Sleep -Seconds 1
}

function Open-KnowledgeBasePage($Hwnd) {
  [void](Invoke-RelativeClick $Hwnd 0.09 0.345)
  Start-Sleep -Seconds 1
}

function Open-KnowledgeValidationTab($Hwnd) {
  Open-KnowledgeBasePage $Hwnd
  [void](Invoke-RelativeClick $Hwnd 0.326 0.277)
  Start-Sleep -Seconds 1
}

function Open-KnowledgeCitationTab($Hwnd) {
  Open-KnowledgeBasePage $Hwnd
  [void](Invoke-RelativeClick $Hwnd 0.372 0.277)
  Start-Sleep -Seconds 1
}

function Open-KnowledgeGapTab($Hwnd) {
  Open-KnowledgeBasePage $Hwnd
  [void](Invoke-RelativeClick $Hwnd 0.421 0.277)
  Start-Sleep -Seconds 1
}

function Invoke-OrganizeMaterialsButton($Hwnd) {
  Open-DocumentLibraryPage $Hwnd
  [void](Invoke-RelativeClick $Hwnd 0.48 0.76)
  Start-Sleep -Seconds 1
}

function Invoke-BuildKnowledgeBaseButton($Hwnd) {
  Open-KnowledgeBasePage $Hwnd
  [void](Invoke-RelativeClick $Hwnd 0.42 0.855)
  Start-Sleep -Seconds 1
}

function Invoke-VerifyKnowledgeBaseButton($Hwnd) {
  Open-KnowledgeValidationTab $Hwnd
  [void](Invoke-RelativeWheel $Hwnd 0.70 0.70 -5)
  [void](Invoke-RelativeClick $Hwnd 0.815 0.545)
  Start-Sleep -Seconds 1
}

function Invoke-SaveValidationReportButton($Hwnd) {
  Activate-NativeWindow $Hwnd
  [void](Invoke-RelativeClick $Hwnd 0.815 0.684)
  Start-Sleep -Seconds 1
}

function Get-KbCatalogRecords([string]$CatalogPath) {
  $catalog = Read-JsonFile $CatalogPath
  if ($null -eq $catalog -or $null -eq $catalog.knowledge_bases) { return @() }
  return @($catalog.knowledge_bases)
}

function Test-KbArtifacts([string]$Workspace) {
  $paths = [ordered]@{
    source_manifest = (Join-Path $Workspace "source_manifest.json")
    du_manifest = (Join-Path $Workspace "du\document_understanding_manifest.json")
    du_records = (Join-Path $Workspace "du\document_understanding_records.jsonl")
    parse_report = (Join-Path $Workspace "parse_report.json")
    kb_manifest = (Join-Path $Workspace "kb\manifest.json")
    chunks = (Join-Path $Workspace "kb\chunks.jsonl")
    cards = (Join-Path $Workspace "kb\cards.jsonl")
    qa_pairs = (Join-Path $Workspace "kb\qa_pairs.jsonl")
    source_map = (Join-Path $Workspace "kb\source_map.json")
    source_trace = (Join-Path $Workspace "kb\source_trace.json")
    catalog = (Join-Path $Workspace "knowledge_bases\kb_catalog.json")
    k1_manifest = (Join-Path $Workspace "knowledge_bases\K1\manifest.json")
    k1_chunks = (Join-Path $Workspace "knowledge_bases\K1\chunks.jsonl")
    k1_source_trace = (Join-Path $Workspace "knowledge_bases\K1\source_trace.json")
  }
  return [ordered]@{
    paths = $paths
    source_manifest = Test-Path -LiteralPath $paths.source_manifest
    du_manifest = Test-Path -LiteralPath $paths.du_manifest
    du_records = Test-Path -LiteralPath $paths.du_records
    du_record_count = Count-Lines $paths.du_records
    parse_report = Test-Path -LiteralPath $paths.parse_report
    kb_manifest = Test-Path -LiteralPath $paths.kb_manifest
    chunks = Test-Path -LiteralPath $paths.chunks
    chunk_count = Count-Lines $paths.chunks
    cards = Test-Path -LiteralPath $paths.cards
    card_count = Count-Lines $paths.cards
    qa_pairs = Test-Path -LiteralPath $paths.qa_pairs
    qa_count = Count-Lines $paths.qa_pairs
    source_map = Test-Path -LiteralPath $paths.source_map
    source_trace = Test-Path -LiteralPath $paths.source_trace
    catalog = Test-Path -LiteralPath $paths.catalog
    k1_manifest = Test-Path -LiteralPath $paths.k1_manifest
    k1_chunks = Test-Path -LiteralPath $paths.k1_chunks
    k1_source_trace = Test-Path -LiteralPath $paths.k1_source_trace
  }
}

function Test-KbSourceTraceability([string]$Workspace) {
  $sourceManifest = Read-JsonFile (Join-Path $Workspace "source_manifest.json")
  $sourceDocs = @()
  if ($null -ne $sourceManifest -and $null -ne $sourceManifest.sources) {
    $sourceDocs = @($sourceManifest.sources)
  }
  $sourceIds = @($sourceDocs | ForEach-Object {
    if ($_.document_id) { [string]$_.document_id } elseif ($_.source_id) { [string]$_.source_id } else { "" }
  } | Where-Object { $_.Trim().Length -gt 0 })

  $chunks = @(Read-JsonlFile (Join-Path $Workspace "kb\chunks.jsonl"))
  $cards = @(Read-JsonlFile (Join-Path $Workspace "kb\cards.jsonl"))
  $qaPairs = @(Read-JsonlFile (Join-Path $Workspace "kb\qa_pairs.jsonl"))
  $trace = Read-JsonFile (Join-Path $Workspace "kb\source_trace.json")
  $sourceMap = Read-JsonFile (Join-Path $Workspace "kb\source_map.json")

  $chunkRefs = @($chunks | Where-Object {
    ([string]$_.document_id).Trim().Length -gt 0 -or
    ([string]$_.source_id).Trim().Length -gt 0 -or
    ([string]$_.source_path).Trim().Length -gt 0 -or
    ([string]$_.citation).Trim().Length -gt 0
  }).Count
  $cardRefs = @($cards | Where-Object {
    ([string]$_.document_id).Trim().Length -gt 0 -or
    ([string]$_.source_id).Trim().Length -gt 0 -or
    ([string]$_.source_path).Trim().Length -gt 0 -or
    ([string]$_.citation).Trim().Length -gt 0
  }).Count
  $qaRefs = @($qaPairs | Where-Object {
    ([string]$_.document_id).Trim().Length -gt 0 -or
    ([string]$_.source_id).Trim().Length -gt 0 -or
    ([string]$_.source_path).Trim().Length -gt 0 -or
    ([string]$_.citation).Trim().Length -gt 0
  }).Count

  $traceSources = @()
  $traceChunks = @()
  if ($null -ne $trace) {
    if ($null -ne $trace.source_documents) { $traceSources = @($trace.source_documents) }
    if ($null -ne $trace.chunks) { $traceChunks = @($trace.chunks) }
  }
  $sourceMapDocs = @()
  if ($null -ne $sourceMap -and $null -ne $sourceMap.documents) {
    $sourceMapDocs = @($sourceMap.documents)
  }
  $traceDocumentIds = @($traceSources | ForEach-Object {
    if ($_.document_id) { [string]$_.document_id } elseif ($_.source_id) { [string]$_.source_id } else { "" }
  } | Where-Object { $_.Trim().Length -gt 0 })
  $mapDocumentIds = @($sourceMapDocs | ForEach-Object {
    if ($_.document_id) { [string]$_.document_id } elseif ($_.source_id) { [string]$_.source_id } else { "" }
  } | Where-Object { $_.Trim().Length -gt 0 })

  return [ordered]@{
    source_count = $sourceDocs.Count
    source_id_count = $sourceIds.Count
    chunk_count = $chunks.Count
    chunk_ref_count = $chunkRefs
    card_count = $cards.Count
    card_ref_count = $cardRefs
    qa_count = $qaPairs.Count
    qa_ref_count = $qaRefs
    trace_source_count = $traceSources.Count
    trace_chunk_count = $traceChunks.Count
    trace_document_id_count = $traceDocumentIds.Count
    source_map_document_count = $sourceMapDocs.Count
    source_map_document_id_count = $mapDocumentIds.Count
    ok = (
      $sourceDocs.Count -ge 2 -and
      $sourceIds.Count -ge 2 -and
      $chunks.Count -gt 0 -and
      $chunkRefs -gt 0 -and
      $cards.Count -gt 0 -and
      $cardRefs -gt 0 -and
      $qaPairs.Count -gt 0 -and
      $qaRefs -gt 0 -and
      $traceSources.Count -ge 2 -and
      $traceDocumentIds.Count -ge 2 -and
      $traceChunks.Count -gt 0 -and
      $sourceMapDocs.Count -ge 2 -and
      $mapDocumentIds.Count -ge 2
    )
  }
}

function Get-QueryPaths([string]$Workspace) {
  $queryDir = Join-Path $Workspace "query"
  return [ordered]@{
    query_dir = $queryDir
    query_result = (Join-Path $queryDir "multi_kb_query_result.json")
    retrieval_plan = (Join-Path $queryDir "retrieval_plan.json")
    rerank_report = (Join-Path $queryDir "rerank_report.json")
    citation_coverage = (Join-Path $queryDir "citation_coverage_report.json")
    conflict_report = (Join-Path $queryDir "conflict_report.json")
    external_boundary = (Join-Path $queryDir "external_validation_boundary.json")
    validation_report = (Join-Path $queryDir "validation_report.json")
    validation_markdown = (Join-Path $queryDir "validation_report.md")
    validation_history = (Join-Path $queryDir "validation_history.jsonl")
  }
}

function Test-QueryArtifactSummary([string]$Workspace, [string]$QueryValue) {
  $paths = Get-QueryPaths $Workspace
  $query = Read-JsonFile $paths.query_result
  $plan = Read-JsonFile $paths.retrieval_plan
  $rerank = Read-JsonFile $paths.rerank_report
  $citation = Read-JsonFile $paths.citation_coverage
  $conflict = Read-JsonFile $paths.conflict_report
  $external = Read-JsonFile $paths.external_boundary
  $results = if ($null -ne $query -and $null -ne $query.results) { @($query.results) } else { @() }
  $selectedKbIds = if ($null -ne $query -and $null -ne $query.selected_kb_ids) { @($query.selected_kb_ids) } else { @() }
  $citationCoverage = if ($null -ne $citation -and $null -ne $citation.citation_coverage) { [double]$citation.citation_coverage } else { -1 }
  $conflictCount = if ($null -ne $conflict -and $null -ne $conflict.conflict_count) { [int]$conflict.conflict_count } else { -1 }
  $allPaths = @(
    $paths.query_result,
    $paths.retrieval_plan,
    $paths.rerank_report,
    $paths.citation_coverage,
    $paths.conflict_report,
    $paths.external_boundary
  )
  $ok = (
    (Wait-ForPathSet $allPaths 1) -and
    $null -ne $query -and
    $query.schema_version -eq "prd_v3_multi_kb_query_result.v1" -and
    $query.query -eq $QueryValue -and
    $selectedKbIds -contains "K1" -and
    $results.Count -gt 0 -and
    $null -ne $plan -and
    $plan.schema_version -eq "prd_v3_retrieval_plan.v1" -and
    @($plan.selected_kb_ids) -contains "K1" -and
    $null -ne $rerank -and
    $rerank.schema_version -eq "prd_v3_retrieval_rerank_report.v1" -and
    $null -ne $citation -and
    $citation.schema_version -eq "prd_v3_retrieval_citation_coverage.v1" -and
    $citationCoverage -ge 0 -and
    $null -ne $conflict -and
    $conflict.schema_version -eq "prd_v3_retrieval_conflict_report.v1" -and
    $conflictCount -ge 0 -and
    $null -ne $external -and
    $external.schema_version -eq "prd_v3_external_validation_boundary.v1" -and
    $external.status -eq "not_enabled_local_only" -and
    $external.external_calls_made -eq $false -and
    $external.secret_plaintext_written -eq $false
  )
  return [ordered]@{
    ok = $ok
    paths = $paths
    query = if ($null -ne $query) { $query.query } else { "" }
    selected_kb_ids = $selectedKbIds
    result_count = $results.Count
    citation_coverage = $citationCoverage
    conflict_count = $conflictCount
    external_validation_status = if ($null -ne $external) { [string]$external.status } else { "" }
    external_calls_made = if ($null -ne $external) { [bool]$external.external_calls_made } else { $true }
    secret_plaintext_written = if ($null -ne $external) { [bool]$external.secret_plaintext_written } else { $true }
  }
}

function Test-ValidationReportSummary([string]$Workspace, [string]$LedgerPath, [string]$QueryValue) {
  $paths = Get-QueryPaths $Workspace
  $report = Read-JsonFile $paths.validation_report
  $historyCount = Count-Lines $paths.validation_history
  $latestEvent = Get-LatestEvent $LedgerPath "validate_knowledge_base"
  $selectedKbIds = if ($null -ne $report -and $null -ne $report.selected_kb_ids) { @($report.selected_kb_ids) } else { @() }
  $resultCount = if ($null -ne $report -and $null -ne $report.result_count) { [int]$report.result_count } else { 0 }
  $citationCoverage = if ($null -ne $report -and $null -ne $report.citation_coverage) { [double]$report.citation_coverage } else { -1 }
  $conflictCount = if ($null -ne $report -and $null -ne $report.conflict_count) { [int]$report.conflict_count } else { -1 }
  $ok = (
    (Test-Path -LiteralPath $paths.validation_report) -and
    (Test-Path -LiteralPath $paths.validation_markdown) -and
    (Test-Path -LiteralPath $paths.validation_history) -and
    $null -ne $report -and
    $report.schema_version -eq "prd_v3_retrieval_validation_report.v1" -and
    $report.query -eq $QueryValue -and
    $selectedKbIds -contains "K1" -and
    $resultCount -gt 0 -and
    $citationCoverage -ge 0 -and
    $conflictCount -ge 0 -and
    $report.external_validation_status -eq "not_enabled_local_only" -and
    $report.query_result_path -eq $paths.query_result -and
    $report.citation_coverage_report_path -eq $paths.citation_coverage -and
    $report.conflict_report_path -eq $paths.conflict_report -and
    $historyCount -gt 0 -and
    $null -ne $latestEvent -and
    $latestEvent.status -eq "completed"
  )
  return [ordered]@{
    ok = $ok
    paths = $paths
    schema_version = if ($null -ne $report) { [string]$report.schema_version } else { "" }
    query = if ($null -ne $report) { [string]$report.query } else { "" }
    selected_kb_ids = $selectedKbIds
    result_count = $resultCount
    citation_coverage = $citationCoverage
    conflict_count = $conflictCount
    external_validation_status = if ($null -ne $report) { [string]$report.external_validation_status } else { "" }
    history_count = $historyCount
    latest_event_type = if ($null -ne $latestEvent) { [string]$latestEvent.event_type } else { "" }
    latest_event_status = if ($null -ne $latestEvent) { [string]$latestEvent.status } else { "" }
    latest_event_target_id = if ($null -ne $latestEvent) { [string]$latestEvent.target_id } else { "" }
  }
}

if ($ClearWorkspace) {
  Clear-WorkbenchWorkspace
}

$workspace = Get-WorkspacePath
$runDir = New-VerifierRunDir $OutputRoot "knowledge_validation_blackbox"
$matrixPath = Join-Path $OutputRoot "knowledge_validation_matrix.json"
$reportPath = Join-Path (Get-AppRoot) "..\..\..\docs\audits\current\knowledge_validation_blackbox_report.md"
$ledgerPath = Join-Path $workspace "audit\event_ledger.jsonl"
$catalogPath = Join-Path $workspace "knowledge_bases\kb_catalog.json"
$fixtureRoot = Join-Path $runDir "input_sources"
$queryValue = "heitang-rc6-needle"
$rows = [System.Collections.ArrayList]::new()
$launch = $null

New-Item -ItemType Directory -Force -Path $fixtureRoot | Out-Null
Write-TextFile (Join-Path $fixtureRoot "validation_source_a.md") "# Knowledge Validation Source A`n`nheitang-rc6-needle is the controlled evidence term for knowledge validation. The workbench must keep source_id, citation, and validation report evidence for this material."
Write-TextFile (Join-Path $fixtureRoot "validation_source_b.txt") "Knowledge Validation Source B`nThe heitang-rc6-needle evidence proves that retrieval can return cited local material, write coverage reports, and keep gaps or conflicts explicit."

try {
  $launch = Start-WorkbenchExe $ExePath
  Set-NativeWindowSize $launch.hwnd 1440 900
  [void](Wait-ForCondition { Test-Path -LiteralPath $workspace } 30)
  Start-Sleep -Seconds 2

  $validateCountBeforeEmpty = Get-EventCount $ledgerPath "validate_knowledge_base"
  Invoke-VerifyKnowledgeBaseButton $launch.hwnd
  $emptyFailure = Wait-ForLatestFailure $ledgerPath "请先构建知识库" 30
  $emptyFailureShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\knowledge_validation_empty_failure_gate.png")
  $emptyFailureOk = $null -ne $emptyFailure -and
    -not (Test-Path -LiteralPath (Join-Path $workspace "query\validation_report.json")) -and
    (Get-EventCount $ledgerPath "validate_knowledge_base") -eq $validateCountBeforeEmpty
  Add-MatrixRow $rows "failure_case_no_kb" "空知识库验证失败路径" `
    "未构建知识库时点击验证，不写 validate_knowledge_base 成功事件，不生成验证报告，并写 failure_event" `
    "failure_event=$($null -ne $emptyFailure); error=$([string]$emptyFailure.error_message); validate_events_before=$validateCountBeforeEmpty; validate_events_after=$(Get-EventCount $ledgerPath 'validate_knowledge_base'); validation_report_exists=$(Test-Path -LiteralPath (Join-Path $workspace 'query\validation_report.json'))" `
    $emptyFailureShot.path $ledgerPath "" $false $false $false `
    ($(if ($emptyFailureOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($emptyFailureOk) { "" } else { "knowledge_validation_failure_gate_blocked" }))

  Open-DocumentLibraryPage $launch.hwnd
  Import-ClipboardPath $launch.hwnd $fixtureRoot
  $importReady = Wait-ForSourceCount $workspace 2 $TimeoutSeconds
  Start-Sleep -Seconds 2
  $importShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\knowledge_validation_after_import.png")
  $sourceInfo = Get-SourceManifestInfo $workspace
  Add-MatrixRow $rows "prepare_import_sources" "导入两个受控验证资料" `
    "source_manifest 真实落盘，且包含两个 source_id 来源" `
    "source_count=$($sourceInfo.source_count); source_manifest=$($sourceInfo.exists)" `
    $importShot.path $sourceInfo.path "" $importReady $importReady $false `
    ($(if ($importReady) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($importReady) { "" } else { "knowledge_validation_import_blocked" }))

  $duPaths = @(
    (Join-Path $workspace "du\document_understanding_manifest.json"),
    (Join-Path $workspace "du\document_understanding_records.jsonl"),
    (Join-Path $workspace "parse_report.json")
  )
  $organizeEventCount = Get-EventCount $ledgerPath "organize_document"
  $organizeReady = Invoke-WorkbenchButtonUntilEventAndPaths `
    $launch.hwnd $ledgerPath "organize_document" $organizeEventCount $duPaths $TimeoutSeconds `
    { Invoke-OrganizeMaterialsButton $launch.hwnd }
  $organizeShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\knowledge_validation_after_organize.png")
  $checks = Test-KbArtifacts $workspace
  $organizeOk = $organizeReady -and $checks.du_record_count -ge 2
  Add-MatrixRow $rows "prepare_organize_materials" "整理资料生成可验证来源" `
    "du manifest、records、parse_report 真实生成，records 至少包含两个来源" `
    "du_manifest=$($checks.du_manifest); records=$($checks.du_record_count); parse_report=$($checks.parse_report)" `
    $organizeShot.path $checks.paths.du_manifest $checks.paths.du_records $organizeOk $organizeOk $false `
    ($(if ($organizeOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($organizeOk) { "" } else { "knowledge_validation_organize_blocked" }))

  $kbPaths = @(
    (Join-Path $workspace "kb\manifest.json"),
    (Join-Path $workspace "kb\chunks.jsonl"),
    (Join-Path $workspace "kb\cards.jsonl"),
    (Join-Path $workspace "kb\qa_pairs.jsonl"),
    (Join-Path $workspace "kb\source_map.json"),
    (Join-Path $workspace "kb\source_trace.json"),
    (Join-Path $workspace "knowledge_bases\kb_catalog.json"),
    (Join-Path $workspace "knowledge_bases\K1\manifest.json"),
    (Join-Path $workspace "knowledge_bases\K1\source_trace.json")
  )
  $generateEventCount = Get-EventCount $ledgerPath "generate_knowledge_base"
  $kbReady = Invoke-WorkbenchButtonUntilEventAndPaths `
    $launch.hwnd $ledgerPath "generate_knowledge_base" $generateEventCount $kbPaths $TimeoutSeconds `
    { Invoke-BuildKnowledgeBaseButton $launch.hwnd }
  $kbShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\knowledge_validation_after_kb_build.png")
  $checks = Test-KbArtifacts $workspace
  $traceability = Test-KbSourceTraceability $workspace
  $catalogRecords = @(Get-KbCatalogRecords $catalogPath)
  $kbOk = $kbReady -and $checks.chunk_count -gt 0 -and $checks.card_count -gt 0 -and $checks.qa_count -gt 0 -and $catalogRecords.Count -eq 1 -and $traceability.ok
  Add-MatrixRow $rows "prepare_real_kb" "生成 K1 真实知识库" `
    "K1 catalog、chunks、cards、qa、source_trace 真实生成，验证输入可追溯 source_id" `
    "chunks=$($checks.chunk_count); cards=$($checks.card_count); qa=$($checks.qa_count); catalog_count=$($catalogRecords.Count); trace_ok=$($traceability.ok)" `
    $kbShot.path $catalogPath $checks.paths.k1_manifest $kbOk $kbOk $false `
    ($(if ($kbOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($kbOk) { "" } else { "knowledge_validation_kb_prepare_blocked" }))

  $queryPaths = Get-QueryPaths $workspace
  $queryPathSet = @(
    $queryPaths.query_result,
    $queryPaths.retrieval_plan,
    $queryPaths.rerank_report,
    $queryPaths.citation_coverage,
    $queryPaths.conflict_report,
    $queryPaths.external_boundary
  )
  Invoke-VerifyKnowledgeBaseButton $launch.hwnd
  $querySummary = Wait-ForQueryArtifacts $workspace $queryValue $TimeoutSeconds
  Start-Sleep -Seconds 3
  $queryShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\knowledge_validation_after_query.png")
  $queryOk = $querySummary.ok -and (Wait-ForPathSet $queryPathSet 1)
  Add-MatrixRow $rows "run_validation_query" "点击验证知识库执行真实查询" `
    "生成 multi_kb_query_result、retrieval_plan、rerank、citation_coverage、conflict、external_boundary 产物" `
    "query=$($querySummary.query); selected_kb_ids=$($querySummary.selected_kb_ids -join ','); result_count=$($querySummary.result_count); citation_coverage=$($querySummary.citation_coverage); conflict_count=$($querySummary.conflict_count); external_status=$($querySummary.external_validation_status)" `
    $queryShot.path $queryPaths.query_result $queryPaths.retrieval_plan $queryOk $queryOk $false `
    ($(if ($queryOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($queryOk) { "" } else { "knowledge_validation_query_artifacts_blocked" }))

  $citationOk = $querySummary.ok -and $querySummary.citation_coverage -ge 0
  Add-MatrixRow $rows "citation_coverage_artifact" "检查引用覆盖产物" `
    "citation_coverage_report.json 真实生成并包含覆盖率" `
    "citation_coverage=$($querySummary.citation_coverage); external_calls_made=$($querySummary.external_calls_made); secret_plaintext_written=$($querySummary.secret_plaintext_written)" `
    "" $queryPaths.citation_coverage $queryPaths.citation_coverage $citationOk $citationOk $false `
    ($(if ($citationOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($citationOk) { "" } else { "knowledge_validation_citation_coverage_blocked" }))

  $conflictOk = $querySummary.ok -and $querySummary.conflict_count -ge 0
  Add-MatrixRow $rows "conflict_gap_artifact" "检查冲突和缺口相关产物" `
    "conflict_report.json 真实生成，缺口页可从验证报告、引用覆盖、冲突记录读取状态" `
    "conflict_count=$($querySummary.conflict_count); external_validation_status=$($querySummary.external_validation_status)" `
    "" $queryPaths.conflict_report $queryPaths.conflict_report $conflictOk $conflictOk $false `
    ($(if ($conflictOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($conflictOk) { "" } else { "knowledge_validation_conflict_gap_blocked" }))

  $validateEventCount = Get-EventCount $ledgerPath "validate_knowledge_base"
  $validationSummary = Invoke-SaveValidationReportUntilEvent $launch.hwnd $workspace $ledgerPath $queryValue $validateEventCount $TimeoutSeconds
  $saveShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\knowledge_validation_after_save_report.png")
  Add-MatrixRow $rows "save_validation_report" "点击保存验证报告" `
    "validation_report.json/md/history 真实生成，并写入 validate_knowledge_base 事件" `
    "schema=$($validationSummary.schema_version); query=$($validationSummary.query); result_count=$($validationSummary.result_count); citation_coverage=$($validationSummary.citation_coverage); event=$($validationSummary.latest_event_type)/$($validationSummary.latest_event_status)" `
    $saveShot.path $queryPaths.validation_report $queryPaths.validation_markdown $validationSummary.ok $validationSummary.ok $false `
    ($(if ($validationSummary.ok) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($validationSummary.ok) { "" } else { "knowledge_validation_report_save_blocked" }))

  $historyOk = $validationSummary.ok -and $validationSummary.history_count -gt 0
  Add-MatrixRow $rows "validation_history" "检查验证历史记录" `
    "validation_history.jsonl 追加本轮验证保存记录" `
    "history_count=$($validationSummary.history_count); selected_kb_ids=$($validationSummary.selected_kb_ids -join ','); latest_event_target_id=$($validationSummary.latest_event_target_id)" `
    "" $queryPaths.validation_history $queryPaths.validation_history $historyOk $historyOk $false `
    ($(if ($historyOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($historyOk) { "" } else { "knowledge_validation_history_blocked" }))

  Stop-WorkbenchExe $launch
  $launch = Start-WorkbenchExe $ExePath
  Set-NativeWindowSize $launch.hwnd 1440 900
  Open-KnowledgeValidationTab $launch.hwnd
  [void](Invoke-RelativeWheel $launch.hwnd 0.70 0.70 -4)
  $restartShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\knowledge_validation_after_restart_validation_tab.png")
  $restartQuerySummary = Test-QueryArtifactSummary $workspace $queryValue
  $restartValidationSummary = Test-ValidationReportSummary $workspace $ledgerPath $queryValue
  $restartOk = $restartQuerySummary.ok -and $restartValidationSummary.ok
  Add-MatrixRow $rows "restart_restore_validation_tab" "重启 EXE 后恢复知识库验证页" `
    "重启后 K1、query artifacts、validation report 仍可从磁盘加载" `
    "query_ok=$($restartQuerySummary.ok); validation_ok=$($restartValidationSummary.ok); result_count=$($restartValidationSummary.result_count); history_count=$($restartValidationSummary.history_count)" `
    $restartShot.path $queryPaths.query_result $queryPaths.validation_report $restartOk $restartOk $true `
    ($(if ($restartOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($restartOk) { "" } else { "knowledge_validation_restart_restore_blocked" }))

  Open-KnowledgeCitationTab $launch.hwnd
  $citationTabShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\knowledge_validation_after_restart_citation_tab.png")
  Open-KnowledgeGapTab $launch.hwnd
  $gapTabShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\knowledge_validation_after_restart_gap_tab.png")
  $tabsOk = $restartQuerySummary.ok -and
    (Test-Path -LiteralPath $queryPaths.citation_coverage) -and
    (Test-Path -LiteralPath $queryPaths.conflict_report) -and
    (Test-Path -LiteralPath $queryPaths.validation_report)
  Add-MatrixRow $rows "citation_gap_tabs_post_restart" "重启后切换引用和缺口 Tab" `
    "引用 Tab 可读取真实检索结果，缺口 Tab 可读取验证报告、引用覆盖和冲突记录" `
    "citation_tab_screenshot=$($citationTabShot.path); gap_tab_screenshot=$($gapTabShot.path); validation_report_exists=$(Test-Path -LiteralPath $queryPaths.validation_report); citation_coverage_exists=$(Test-Path -LiteralPath $queryPaths.citation_coverage); conflict_report_exists=$(Test-Path -LiteralPath $queryPaths.conflict_report)" `
    $gapTabShot.path $queryPaths.validation_report $queryPaths.citation_coverage $tabsOk $tabsOk $true `
    ($(if ($tabsOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($tabsOk) { "" } else { "knowledge_validation_tabs_reentry_blocked" }))

  $events = @(Read-JsonlFile $ledgerPath)
  $failureEvents = @($events | Where-Object { $_.event_type -eq "failure_event" }).Count
  $validateEvents = @($events | Where-Object { $_.event_type -eq "validate_knowledge_base" }).Count
  $generateEvents = @($events | Where-Object { $_.event_type -eq "generate_knowledge_base" }).Count
  $eventOk = $failureEvents -ge 1 -and $validateEvents -ge 1 -and $generateEvents -ge 1
  Add-MatrixRow $rows "recent_activity_events" "检查事件账本来源" `
    "真实事件 failure/generate/validate 写入 event_ledger，首页最近动态可从账本读取" `
    "failure_event=$failureEvents; generate_knowledge_base=$generateEvents; validate_knowledge_base=$validateEvents" `
    "" $ledgerPath $queryPaths.validation_report $eventOk $eventOk $true `
    ($(if ($eventOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($eventOk) { "" } else { "knowledge_validation_event_ledger_blocked" }))

  $blocked = @($rows | Where-Object { $_.current_conclusion -eq "blocked" })
  $status = if ($blocked.Count -eq 0) {
    "knowledge_validation_lifecycle_completed_needs_owner_review"
  } else {
    "knowledge_validation_lifecycle_blocked"
  }
  $finalQuerySummary = Test-QueryArtifactSummary $workspace $queryValue
  $finalValidationSummary = Test-ValidationReportSummary $workspace $ledgerPath $queryValue
  $payload = [ordered]@{
    schema_version = "heitang_knowledge_validation_blackbox_matrix.v1"
    status = $status
    exe_path = $ExePath
    workspace = $workspace
    kb_catalog_path = $catalogPath
    query_dir = (Join-Path $workspace "query")
    event_ledger_path = $ledgerPath
    fixture_input_path = $fixtureRoot
    artifact_summary = [ordered]@{
      kb_id = "K1"
      query = $queryValue
      result_count = $finalValidationSummary.result_count
      citation_coverage = $finalValidationSummary.citation_coverage
      conflict_count = $finalValidationSummary.conflict_count
      validation_report_schema = $finalValidationSummary.schema_version
      external_validation_status = $finalValidationSummary.external_validation_status
      latest_validate_event_type = $finalValidationSummary.latest_event_type
      latest_validate_event_status = $finalValidationSummary.latest_event_status
      query_artifacts_ok = $finalQuerySummary.ok
      validation_report_ok = $finalValidationSummary.ok
    }
    query_artifacts = $finalQuerySummary
    validation_report = $finalValidationSummary
    rows = $rows
    run_dir = $runDir
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Json $matrixPath $payload
  Write-Json (Join-Path $runDir "knowledge_validation_matrix.json") $payload

  $blockerText = if ($blocked.Count -eq 0) {
    "- 无 P0-5 直接阻断项，等待 Owner 复核。"
  } else {
    ($blocked | ForEach-Object { "- $($_.blocker)" }) -join "`n"
  }
  $report = @(
    "# Knowledge Validation Blackbox Lifecycle Report",
    "",
    "Status: $status",
    "",
    "## Scope",
    "",
    "This gate validates P0-5 knowledge validation in the real Windows EXE. It does not change the P0 order and does not enter P1/P2 supplement work.",
    "",
    "## Files Changed For This Gate",
    "",
    "- docs/audits/current/knowledge_validation_blackbox_report.md",
    "- web/workbench/flutter_app/output/capability_blackbox/knowledge_validation_matrix.json",
    "- web/workbench/flutter_app/tool/windows_native_product_verifier/run_knowledge_validation_lifecycle_matrix.ps1",
    "",
    "## Blackbox Evidence",
    "",
    "- Workspace: $workspace",
    "- Matrix: $matrixPath",
    "- Catalog: $catalogPath",
    "- Event ledger: $ledgerPath",
    "- Screenshot: $($emptyFailureShot.path)",
    "- Screenshot: $($queryShot.path)",
    "- Screenshot: $($saveShot.path)",
    "- Screenshot: $($restartShot.path)",
    "- Screenshot: $($citationTabShot.path)",
    "- Screenshot: $($gapTabShot.path)",
    "",
    "Verified evidence:",
    "",
    "- Empty knowledge validation path wrote a real failure_event and did not create a successful validation report.",
    "- Two controlled local sources were imported through the real EXE path.",
    "- Material organization generated du records and parse report for the imported sources.",
    "- K1 was built through the real EXE and retained source traceability across chunks, cards, qa pairs, source_map, and source_trace.",
    "- The Knowledge Base validation tab executed a real query for $queryValue against K1.",
    "- multi_kb_query_result.json, retrieval_plan.json, rerank_report.json, citation_coverage_report.json, conflict_report.json, and external_validation_boundary.json were generated.",
    "- Saving the validation report generated validation_report.json, validation_report.md, validation_history.jsonl, and a validate_knowledge_base event.",
    "- External validation stayed gated as local-only; no external call or secret plaintext was recorded.",
    "- Restarting the EXE preserved query artifacts, validation report artifacts, and citation/gap tab backing files.",
    "- Event ledger includes real failure_event, generate_knowledge_base, and validate_knowledge_base events.",
    "",
    "## Current Artifact Summary",
    "",
    "- validation_report.json schema: $($finalValidationSummary.schema_version)",
    "- Query: $($finalValidationSummary.query)",
    "- Selected KB: $($finalValidationSummary.selected_kb_ids -join ',')",
    "- Result count: $($finalValidationSummary.result_count)",
    "- Citation coverage: $($finalValidationSummary.citation_coverage)",
    "- Conflict count: $($finalValidationSummary.conflict_count)",
    "- External validation status: $($finalValidationSummary.external_validation_status)",
    "- Latest event: $($finalValidationSummary.latest_event_type), status=$($finalValidationSummary.latest_event_status), target_id=$($finalValidationSummary.latest_event_target_id)",
    "",
    "## Remaining Risk",
    "",
    "- This gate leaves the controlled K1 knowledge base in the local product workspace so the next P0 gate can reuse a verified knowledge base.",
    "- Screenshots are saved under the run directory for evidence, but the matrix and report remain the committed durable evidence.",
    "- External source validation remained correctly gated as local-only; this gate did not verify real external source calls.",
    "",
    "## Validation Commands",
    "",
    "- powershell -NoProfile -ExecutionPolicy Bypass -File web\\workbench\\flutter_app\\tool\\windows_native_product_verifier\\run_knowledge_validation_lifecycle_matrix.ps1 -TimeoutSeconds $TimeoutSeconds -ClearWorkspace",
    "",
    "## Current Status",
    "",
    $status,
    "",
    "## Next Gate",
    "",
    "P0-6 Document Generation.",
    "",
    "## Blocked Items",
    "",
    $blockerText
  ) -join "`n"
  Write-Utf8NoBomFile $reportPath $report

  Write-Json (Join-Path $runDir "summary.json") ([ordered]@{
    status = $status
    matrix_path = $matrixPath
    report_path = $reportPath
    blocked_count = $blocked.Count
  })
  Write-Output "status=$status"
  Write-Output "matrix=$matrixPath"
  Write-Output "report=$reportPath"
  if ($blocked.Count -gt 0) { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
