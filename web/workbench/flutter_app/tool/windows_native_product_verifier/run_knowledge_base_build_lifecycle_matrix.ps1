param(
  [string]$ExePath = "",
  [string]$OutputRoot = "",
  [int]$TimeoutSeconds = 240,
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

function Count-Lines([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return 0 }
  return @((Get-Content -LiteralPath $Path -Encoding UTF8) | Where-Object { $_.Trim().Length -gt 0 }).Count
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

function Wait-ForPathSet([string[]]$Paths, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    $missing = @($Paths | Where-Object { -not (Test-Path -LiteralPath $_) })
    if ($missing.Count -eq 0) { return $true }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $false
}

function Wait-ForLatestFailure([string]$LedgerPath, [string]$Contains, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    $events = @(Read-JsonlFile $LedgerPath | Where-Object {
      $_.event_type -eq "failure_event" -and ([string]$_.error_message).Contains($Contains)
    })
    if ($events.Count -gt 0) { return $events | Sort-Object created_at -Descending | Select-Object -First 1 }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $null
}

function Get-LatestEvent([string]$LedgerPath, [string]$EventType) {
  $events = @(Read-JsonlFile $LedgerPath | Where-Object { $_.event_type -eq $EventType })
  if ($events.Count -eq 0) { return $null }
  return $events | Sort-Object created_at -Descending | Select-Object -First 1
}

function Get-EventCount([string]$LedgerPath, [string]$EventType) {
  return @(Read-JsonlFile $LedgerPath | Where-Object { $_.event_type -eq $EventType }).Count
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

function Wait-ForLatestEvent([string]$LedgerPath, [string]$EventType, [int]$TimeoutSeconds) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    $event = Get-LatestEvent $LedgerPath $EventType
    if ($null -ne $event -and $event.status -eq "completed") { return $event }
    Start-Sleep -Milliseconds 500
  } while ((Get-Date) -lt $deadline)
  return $null
}

function Invoke-ControlAltUntilEventAndPaths(
  $Hwnd,
  [string]$Key,
  [string]$LedgerPath,
  [string]$EventType,
  [int]$PreviousEventCount,
  [string[]]$Paths,
  [int]$TimeoutSeconds
) {
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    Invoke-ControlAltAction $Hwnd $Key
    $eventReady = Wait-ForEventCountGreater $LedgerPath $EventType $PreviousEventCount 12
    $pathsReady = Wait-ForPathSet $Paths 3
    if ($eventReady -and $pathsReady) { return $true }
    Start-Sleep -Seconds 2
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

function Open-DocumentLibraryPage($Hwnd) {
  [void](Invoke-RelativeClick $Hwnd 0.09 0.29)
  Start-Sleep -Seconds 1
}

function Open-KnowledgeBasePage($Hwnd) {
  [void](Invoke-RelativeClick $Hwnd 0.09 0.345)
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

  $chunksPath = Join-Path $Workspace "kb\chunks.jsonl"
  $cardsPath = Join-Path $Workspace "kb\cards.jsonl"
  $qaPath = Join-Path $Workspace "kb\qa_pairs.jsonl"
  $tracePath = Join-Path $Workspace "kb\source_trace.json"
  $sourceMapPath = Join-Path $Workspace "kb\source_map.json"

  $chunks = @(Read-JsonlFile $chunksPath)
  $cards = @(Read-JsonlFile $cardsPath)
  $qaPairs = @(Read-JsonlFile $qaPath)
  $trace = Read-JsonFile $tracePath
  $sourceMap = Read-JsonFile $sourceMapPath

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

if ($ClearWorkspace) {
  Clear-WorkbenchWorkspace
}

$workspace = Get-WorkspacePath
$runDir = New-VerifierRunDir $OutputRoot "knowledge_base_build_blackbox"
$matrixPath = Join-Path $OutputRoot "knowledge_base_build_matrix.json"
$reportPath = Join-Path (Get-AppRoot) "..\..\..\docs\audits\current\knowledge_base_build_blackbox_report.md"
$ledgerPath = Join-Path $workspace "audit\event_ledger.jsonl"
$catalogPath = Join-Path $workspace "knowledge_bases\kb_catalog.json"
$fixtureRoot = Join-Path $runDir "input_sources"
$rows = [System.Collections.ArrayList]::new()
$launch = $null

New-Item -ItemType Directory -Force -Path $fixtureRoot | Out-Null
Write-TextFile (Join-Path $fixtureRoot "kb_lifecycle_a.md") "# 知识库生命周期 A`n`n黑糖工作台会把资料导入、整理为片段，再生成知识卡片、问答和来源追溯。"
Write-TextFile (Join-Path $fixtureRoot "kb_lifecycle_b.txt") "知识库生命周期 B`n用于验证 txt 来源、chunk、card、qa pair 和 source_trace。"

try {
  $launch = Start-WorkbenchExe $ExePath
  Set-NativeWindowSize $launch.hwnd 1440 900
  [void](Wait-ForCondition { Test-Path -LiteralPath $workspace } 30)
  Start-Sleep -Seconds 2
  Open-DocumentLibraryPage $launch.hwnd
  $initialShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\knowledge_base_initial_empty.png")

  $organizeEventCountBeforeEmptyClick = Get-EventCount $ledgerPath "organize_document"
  Invoke-OrganizeMaterialsButton $launch.hwnd
  Start-Sleep -Seconds 2
  $emptyOrganizeShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\knowledge_base_empty_organize_gate.png")
  $emptyOrganizeOk = -not (Test-Path -LiteralPath (Join-Path $workspace "du\document_understanding_manifest.json")) -and
    -not (Test-Path -LiteralPath (Join-Path $workspace "parse_report.json")) -and
    (Get-EventCount $ledgerPath "organize_document") -eq $organizeEventCountBeforeEmptyClick
  Add-MatrixRow $rows "failure_case" "空工作区整理资料 UI gate" `
    "未导入资料时用户可见整理入口不假执行，不生成整理产物、不写 completed 事件" `
    "du_manifest_exists=$(Test-Path -LiteralPath (Join-Path $workspace 'du\document_understanding_manifest.json')); parse_report_exists=$(Test-Path -LiteralPath (Join-Path $workspace 'parse_report.json')); organize_events_before=$organizeEventCountBeforeEmptyClick; organize_events_after=$(Get-EventCount $ledgerPath 'organize_document')" `
    $emptyOrganizeShot.path $ledgerPath $false $false $false `
    ($(if ($emptyOrganizeOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($emptyOrganizeOk) { "" } else { "document_organize_empty_gate_false_success" }))

  Open-DocumentLibraryPage $launch.hwnd
  Import-ClipboardPath $launch.hwnd $fixtureRoot
  $importReady = Wait-ForSourceCount $workspace 2 $TimeoutSeconds
  $importEvent = Wait-ForLatestEvent $ledgerPath "import_document" $TimeoutSeconds
  Start-Sleep -Seconds 3
  $importShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\knowledge_base_after_import.png")
  $importOk = $importReady -and $null -ne $importEvent
  Add-MatrixRow $rows "import_sources" "导入两个受控资料文件" `
    "source_manifest 与 input 文件真实落盘" `
    "source_count=$((Get-SourceManifestInfo $workspace).source_count); import_event=$($null -ne $importEvent)" `
    $importShot.path (Join-Path $workspace "source_manifest.json") $importOk $importOk $false `
    ($(if ($importOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($importOk) { "" } else { "knowledge_base_input_import_blocked" }))

  $generateBeforeParseCount = Get-EventCount $ledgerPath "generate_knowledge_base"
  Invoke-BuildKnowledgeBaseButton $launch.hwnd
  $kbFailure = Wait-ForLatestFailure $ledgerPath "请先在导入与解析页完成解析" 30
  $preOrganizeKbShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\knowledge_base_pre_organize_build_gate.png")
  $kbFailureOk = $null -ne $kbFailure -and
    -not (Test-Path -LiteralPath (Join-Path $workspace "kb\manifest.json")) -and
    (Get-EventCount $ledgerPath "generate_knowledge_base") -eq $generateBeforeParseCount
  Add-MatrixRow $rows "failure_case" "未整理资料时生成知识库失败 gate" `
    "已导入但未完成资料整理时生成知识库不假成功，并写 failure_event" `
    "failure_event=$($null -ne $kbFailure); error=$([string]$kbFailure.error_message); kb_manifest_exists=$(Test-Path -LiteralPath (Join-Path $workspace 'kb\manifest.json')); generate_events_before=$generateBeforeParseCount; generate_events_after=$(Get-EventCount $ledgerPath 'generate_knowledge_base')" `
    $preOrganizeKbShot.path $ledgerPath $false $false $false `
    ($(if ($kbFailureOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($kbFailureOk) { "" } else { "knowledge_base_failure_gate_blocked" }))

  $duPaths = @(
    (Join-Path $workspace "du\document_understanding_manifest.json"),
    (Join-Path $workspace "du\document_understanding_records.jsonl"),
    (Join-Path $workspace "parse_report.json")
  )
  $organizeEventCount = Get-EventCount $ledgerPath "organize_document"
  $organizeReady = Invoke-WorkbenchButtonUntilEventAndPaths `
    $launch.hwnd $ledgerPath "organize_document" $organizeEventCount $duPaths $TimeoutSeconds `
    { Invoke-OrganizeMaterialsButton $launch.hwnd }
  $organizeShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\knowledge_base_after_organize.png")
  $checks = Test-KbArtifacts $workspace
  $organizeOk = $organizeReady -and $checks.du_record_count -ge 2
  Add-MatrixRow $rows "organize_materials" "整理资料生成解析产物" `
    "du manifest、records、parse_report 真实生成，records 至少包含两个来源" `
    "du_manifest=$($checks.du_manifest); records=$($checks.du_record_count); parse_report=$($checks.parse_report)" `
    $organizeShot.path $checks.paths.du_manifest $organizeOk $organizeOk $false `
    ($(if ($organizeOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($organizeOk) { "" } else { "document_organize_artifacts_blocked" }))

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
  $kbShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\knowledge_base_after_build.png")
  $checks = Test-KbArtifacts $workspace
  $traceability = Test-KbSourceTraceability $workspace
  $catalogRecords = @(Get-KbCatalogRecords $catalogPath)
  $generateEvent = Get-LatestEvent $ledgerPath "generate_knowledge_base"
  $kbOk = $kbReady -and $checks.chunk_count -gt 0 -and $checks.card_count -gt 0 -and $checks.qa_count -gt 0 -and $catalogRecords.Count -ge 1 -and $null -ne $generateEvent -and $traceability.ok
  Add-MatrixRow $rows "build_knowledge_base" "生成知识库核心产物" `
    "manifest/chunks/cards/qa/source_map/source_trace/catalog/materialized K1 真实生成，且 chunks/cards/qa/source_trace 可追溯来源" `
    "chunks=$($checks.chunk_count); cards=$($checks.card_count); qa=$($checks.qa_count); catalog_count=$($catalogRecords.Count); generate_event=$($null -ne $generateEvent); trace_ok=$($traceability.ok); source_ids=$($traceability.source_id_count); trace_sources=$($traceability.trace_source_count)" `
    $kbShot.path $catalogPath $kbOk $kbOk $false `
    ($(if ($kbOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($kbOk) { "" } else { "knowledge_base_build_artifacts_blocked" }))

  Stop-WorkbenchExe $launch
  $launch = Start-WorkbenchExe $ExePath
  Set-NativeWindowSize $launch.hwnd 1440 900
  Open-KnowledgeBasePage $launch.hwnd
  $restartReady = Wait-ForPathSet $kbPaths 30
  $restartShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\knowledge_base_after_restart.png")
  $restartChecks = Test-KbArtifacts $workspace
  $restartCatalogRecords = @(Get-KbCatalogRecords $catalogPath)
  $restartOk = $restartReady -and $restartChecks.chunk_count -gt 0 -and $restartCatalogRecords.Count -eq 1
  Add-MatrixRow $rows "restart_persistence" "关闭 EXE 后重新打开知识库页" `
    "K1 与 runtime KB 产物仍可从磁盘加载" `
    "catalog_count=$($restartCatalogRecords.Count); chunks=$($restartChecks.chunk_count); k1_source_trace=$($restartChecks.k1_source_trace)" `
    $restartShot.path $catalogPath $restartOk $restartOk $true `
    ($(if ($restartOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($restartOk) { "" } else { "knowledge_base_restart_persistence_blocked" }))

  $upsertEventCount = Get-EventCount $ledgerPath "generate_knowledge_base"
  $upsertReady = Invoke-WorkbenchButtonUntilEventAndPaths `
    $launch.hwnd $ledgerPath "generate_knowledge_base" $upsertEventCount $kbPaths $TimeoutSeconds `
    { Invoke-BuildKnowledgeBaseButton $launch.hwnd }
  Start-Sleep -Seconds 1
  $upsertCatalogRecords = @(Get-KbCatalogRecords $catalogPath)
  $hasK3 = @($upsertCatalogRecords | Where-Object { $_.kb_id -eq "K3" }).Count -gt 0
  $upsertOk = $upsertReady -and $upsertCatalogRecords.Count -eq 1 -and -not $hasK3
  $upsertShot = Save-NativeScreenshot $launch.hwnd (Join-Path $runDir "screenshots\knowledge_base_after_upsert.png")
  Add-MatrixRow $rows "update_upsert" "已有知识库时再次生成知识库" `
    "更新现有 K1，不继续追加 K2/K3" `
    "catalog_ids=$(@($upsertCatalogRecords | ForEach-Object { $_.kb_id }) -join ','); has_k3=$hasK3" `
    $upsertShot.path $catalogPath $upsertOk $upsertOk $false `
    ($(if ($upsertOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($upsertOk) { "" } else { "knowledge_base_upsert_created_extra_kb" }))

  $events = @(Read-JsonlFile $ledgerPath)
  $importEvents = @($events | Where-Object { $_.event_type -eq "import_document" }).Count
  $organizeEvents = @($events | Where-Object { $_.event_type -eq "organize_document" }).Count
  $generateEvents = @($events | Where-Object { $_.event_type -eq "generate_knowledge_base" }).Count
  $eventOk = $importEvents -ge 1 -and $organizeEvents -ge 1 -and $generateEvents -ge 1
  Add-MatrixRow $rows "recent_activity_events" "检查最近动态事件来源" `
    "真实事件 import/organize/generate 写入 event_ledger" `
    "import_document=$importEvents; organize_document=$organizeEvents; generate_knowledge_base=$generateEvents" `
    $upsertShot.path $ledgerPath $eventOk $eventOk $false `
    ($(if ($eventOk) { "blackbox_lifecycle_verified" } else { "blocked" })) `
    ($(if ($eventOk) { "" } else { "knowledge_base_event_ledger_blocked" }))

  $blocked = @($rows | Where-Object { $_.current_conclusion -eq "blocked" })
  $status = if ($blocked.Count -eq 0) {
    "knowledge_base_build_lifecycle_completed_needs_owner_review"
  } else {
    "knowledge_base_build_lifecycle_blocked"
  }
  $finalChecks = Test-KbArtifacts $workspace
  $payload = [ordered]@{
    schema_version = "heitang_knowledge_base_build_blackbox_matrix.v1"
    status = $status
    exe_path = $ExePath
    workspace = $workspace
    event_ledger_path = $ledgerPath
    kb_catalog_path = $catalogPath
    fixture_input_path = $fixtureRoot
    artifact_checks = $finalChecks
    source_traceability = (Test-KbSourceTraceability $workspace)
    rows = $rows
    run_dir = $runDir
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
  }
  Write-Json $matrixPath $payload
  Write-Json (Join-Path $runDir "knowledge_base_build_matrix.json") $payload

  $blockerText = if ($blocked.Count -eq 0) {
    "- 无 P0-4 直接阻断项，等待 Owner 复核。"
  } else {
    ($blocked | ForEach-Object { "- $($_.blocker)" }) -join "`n"
  }
  $report = @(
    "# Knowledge Base Build Blackbox Report",
    "",
    "## Current Status",
    "",
    $status,
    "",
    "## Scope",
    "",
    "This gate validates P0-4 material organization plus knowledge-base generation in the real Windows EXE. It does not claim full product acceptance.",
    "",
    "## Blackbox Evidence",
    "",
    "- Workspace: $workspace",
    "- Matrix: $matrixPath",
    "- Catalog: $catalogPath",
    "- Event ledger: $ledgerPath",
    "- Screenshot: $($organizeShot.path)",
    "- Screenshot: $($kbShot.path)",
    "- Screenshot: $($restartShot.path)",
    "- Screenshot: $($upsertShot.path)",
    "",
    "Verified evidence:",
    "",
    "- Empty organize UI gate did not create false completed events or artifacts.",
    "- Knowledge-base build before organization wrote a real failure_event and did not create KB artifacts.",
    "- source_manifest.json exists after controlled import.",
    "- du/document_understanding_manifest.json exists.",
    "- du/document_understanding_records.jsonl has $($finalChecks.du_record_count) records.",
    "- parse_report.json exists.",
    "- kb/manifest.json, chunks.jsonl, cards.jsonl, qa_pairs.jsonl, source_map.json, source_trace.json exist.",
    "- chunks/cards/qa/source_trace/source_map retain source references and source IDs for imported files.",
    "- materialized knowledge_bases/K1/source_trace.json exists.",
    "- EXE restart preserved the KB catalog and runtime KB artifacts.",
    "- Re-running knowledge-base generation updated K1 and did not create K3.",
    "- Event ledger includes real import_document, organize_document, and generate_knowledge_base events.",
    "",
    "## Validation Result",
    "",
    "- blocked rows: $($blocked.Count)",
    "- current status: $status",
    "",
    "## Known Residual",
    "",
    "- This gate does not delete K1 after verification; KB deletion is covered by the knowledge validation cleanup gate and delete_knowledge_base event evidence.",
    "- Owner review is still required. This report does not claim final product acceptance.",
    "",
    "## Blocked Items",
    "",
    $blockerText
  ) -join "`n"
  $reportParent = Split-Path -Parent $reportPath
  if ($reportParent) { New-Item -ItemType Directory -Force -Path $reportParent | Out-Null }
  $report | Set-Content -Encoding UTF8 -Path $reportPath

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
