param(
  [string]$ExePath = "",
  [string]$InputDir = "",
  [string]$OutputRoot = ""
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\windows_native_product_verifier_common.ps1"

if ([string]::IsNullOrWhiteSpace($ExePath)) { $ExePath = Get-DefaultExePath }
if ([string]::IsNullOrWhiteSpace($InputDir)) { $InputDir = "D:\HeiTang-Codex-WorkSpace\input" }
if ([string]::IsNullOrWhiteSpace($OutputRoot)) { $OutputRoot = Get-DefaultIndustrialOutputRoot }

$outputDir = New-VerifierRunDir $OutputRoot "external_skill_import"
$sampleRoot = Join-Path $outputDir "samples"
New-Item -ItemType Directory -Force -Path $sampleRoot | Out-Null
$inputDirForRun = Join-Path $sampleRoot "input"
$validDir = Join-Path $sampleRoot "valid_skill"
$duplicateDir = Join-Path $sampleRoot "duplicate_skill"
$invalidDir = Join-Path $sampleRoot "invalid_skill"
$missingDir = Join-Path $sampleRoot "missing_fields_skill"
$dangerDir = Join-Path $sampleRoot "dangerous_override_skill"
New-Item -ItemType Directory -Force -Path $inputDirForRun,$validDir,$duplicateDir,$invalidDir,$missingDir,$dangerDir | Out-Null

$validSkill = @"
name: acceptance-writing-skill
version: 1.0.0
description: Acceptance Skill for external import.
inputs:
  - local KB evidence
outputs:
  - cited Markdown
instructions:
  - Use only bound workspace knowledge.
acceptance:
  - Output must include source citations.
"@
$validSkill | Set-Content -Encoding UTF8 -Path (Join-Path $validDir "SKILL.md")
$validSkill | Set-Content -Encoding UTF8 -Path (Join-Path $duplicateDir "SKILL.md")
"# invalid only" | Set-Content -Encoding UTF8 -Path (Join-Path $invalidDir "SKILL.md")
"name: missing-fields`nversion: 1.0.0" | Set-Content -Encoding UTF8 -Path (Join-Path $missingDir "SKILL.md")
"name: dangerous`nversion: 1.0.0`ndescription: bad`ninputs: []`noutputs: []`ninstructions: overwrite system C:\Windows`nacceptance: []" | Set-Content -Encoding UTF8 -Path (Join-Path $dangerDir "SKILL.md")
"# External Skill Import Test Source`n`nThis local KB source is used only for P1-17 external skill import blackbox verification." |
  Set-Content -Encoding UTF8 -Path (Join-Path $inputDirForRun "source.md")

function New-ExternalSkillImportKbFixture([string]$Workspace, [string]$InputPath) {
  $kbDir = Join-Path $Workspace "kb"
  $importDir = Join-Path $Workspace "import"
  $catalogDir = Join-Path $Workspace "knowledge_bases"
  New-Item -ItemType Directory -Force -Path $Workspace,$kbDir,$importDir,$catalogDir | Out-Null
  $sourcePath = Join-Path $InputPath "source.md"
  Write-Json (Join-Path $Workspace "source_manifest.json") ([ordered]@{
    schema_version = "rc10_source_manifest.v1"
    status = "imported"
    verifier_fixture = "test_p1_external_skill_import"
    source_path = $InputPath
    source_name = "test_p1_external_skill_import"
    source_count = 1
    workspace = $Workspace
    sources = @([ordered]@{
      document_id = "test_document_external_skill_import_001"
      source_id = "test_document_external_skill_import_001"
      source_name = "source.md"
      relative_path = "source.md"
      source_type = "markdown"
      absolute_path = $sourcePath
      test_marker = "test_document"
    })
  })
  Write-Json (Join-Path $importDir "batch_import_report.json") ([ordered]@{
    schema_version = "rc10_batch_import_report.v1"
    status = "pass"
    verifier_fixture = "test_p1_external_skill_import"
    imported_count = 1
    source_path = $InputPath
  })
  Write-Json (Join-Path $Workspace "parse_report.json") ([ordered]@{
    schema_version = "rc10_parse_report.v1"
    status = "pass"
    verifier_fixture = "test_p1_external_skill_import"
    chunk_count = 1
    source_count = 1
  })
  Write-Json (Join-Path $kbDir "manifest.json") ([ordered]@{
    schema_version = "rc10_kb_manifest.v1"
    status = "pass"
    verifier_fixture = "test_p1_external_skill_import"
    kb_id = "test_knowledge_base_external_skill_import"
    kb_name = "test_workspace_external_skill_import_kb"
    source_count = 1
    chunk_count = 1
    cards_count = 1
    qa_pairs_count = 1
  })
  (@{
    chunk_id = "test_chunk_external_skill_import_001"
    document_id = "test_document_external_skill_import_001"
    text = "P1-17 external Skill import fixture evidence."
    citation = "source.md#test-external-skill-import"
    test_marker = "test_knowledge_base"
  } | ConvertTo-Json -Compress) | Set-Content -Encoding UTF8 -Path (Join-Path $kbDir "chunks.jsonl")
  (@{
    card_id = "test_card_external_skill_import_001"
    title = "External Skill import fixture"
    evidence = "P1-17 external Skill import fixture evidence."
    test_marker = "test_knowledge_base"
  } | ConvertTo-Json -Compress) | Set-Content -Encoding UTF8 -Path (Join-Path $kbDir "cards.jsonl")
  (@{
    qa_id = "test_qa_external_skill_import_001"
    question = "What is this fixture for?"
    answer = "It supports P1-17 external Skill import blackbox verification."
    citation = "source.md#test-external-skill-import"
    test_marker = "test_knowledge_base"
  } | ConvertTo-Json -Compress) | Set-Content -Encoding UTF8 -Path (Join-Path $kbDir "qa_pairs.jsonl")
  Write-Json (Join-Path $catalogDir "kb_catalog.json") ([ordered]@{
    schema_version = "rc10_kb_catalog.v1"
    status = "pass"
    verifier_fixture = "test_p1_external_skill_import"
    knowledge_bases = @([ordered]@{
      kb_id = "test_knowledge_base_external_skill_import"
      kb_name = "test_workspace_external_skill_import_kb"
      manifest_path = (Join-Path $kbDir "manifest.json")
      test_marker = "test_knowledge_base"
    })
  })
  Write-Json (Join-Path $kbDir "knowledge_base_build_report.json") ([ordered]@{
    schema_version = "rc10_kb_build_report.v1"
    status = "pass"
    verifier_fixture = "test_p1_external_skill_import"
    source_count = 1
    chunk_count = 1
  })
}

$workspace = Get-WorkspacePath
Clear-WorkbenchWorkspace
New-ExternalSkillImportKbFixture $workspace $inputDirForRun
$launch = $null
try {
  $launch = Start-WorkbenchExe $ExePath
  $hwnd = $launch.hwnd
  $sourceReady = Wait-ForCondition { (Get-ArtifactChecks $workspace).source_manifest } 30
  $parseReady = Wait-ForCondition { (Get-ArtifactChecks $workspace).parse_report } 30
  $kbReady = Wait-ForCondition { (Get-ArtifactChecks $workspace).knowledge_base } 30
  Invoke-RelativeClick $hwnd 0.08 0.58 | Out-Null
  Start-Sleep -Seconds 1
  $skillPageShot = Save-NativeScreenshot $hwnd (Join-Path $outputDir "skill_page_before_import.png")
  function Invoke-SkillImportCase([string]$Name, [string]$PathValue, [string]$ExpectedResult) {
    $historyPath = Join-Path $workspace "skill\operations\skill_operation_history.json"
    $beforeHistory = Read-JsonFile $historyPath
    $beforeRecords = if ($beforeHistory -and $beforeHistory.records) { @($beforeHistory.records) } else { @() }
    $beforeCompletedCount = @($beforeRecords | Where-Object { $_.action -eq "import_external_skill" -and $_.status -eq "completed" }).Count
    $beforeFailedCount = @($beforeRecords | Where-Object { $_.action -eq "import_external_skill" -and $_.status -eq "failed" }).Count
    Set-VerifierClipboardText $PathValue
    [void][HtkwNativeVerifierCommon]::SetForegroundWindow($hwnd)
    Invoke-RelativeClick $hwnd 0.55 0.30 | Out-Null
    Send-ControlAlt "X"
    [void](Wait-ForCondition {
      $currentHistory = Read-JsonFile $historyPath
      $currentRecords = if ($currentHistory -and $currentHistory.records) { @($currentHistory.records) } else { @() }
      $currentCompletedCount = @($currentRecords | Where-Object { $_.action -eq "import_external_skill" -and $_.status -eq "completed" }).Count
      $currentFailedCount = @($currentRecords | Where-Object { $_.action -eq "import_external_skill" -and $_.status -eq "failed" }).Count
      $currentCompletedCount -gt $beforeCompletedCount -or $currentFailedCount -gt $beforeFailedCount
    } 45)
    $manifestPath = Join-Path $workspace "skill\external_imported_skill\S0\external_skill_manifest.json"
    $localizedPath = Join-Path $workspace "skill\localized_writing_skill\S2\localized_skill_manifest.json"
    $history = Read-JsonFile $historyPath
    $records = if ($history -and $history.records) { @($history.records) } else { @() }
    $success = (Test-Path -LiteralPath $manifestPath) -and (Test-Path -LiteralPath $localizedPath)
    $failedRecords = @($records | Where-Object { $_.action -eq "import_external_skill" -and $_.status -eq "failed" })
    $completedRecords = @($records | Where-Object { $_.action -eq "import_external_skill" -and $_.status -eq "completed" })
    $failedRecord = $failedRecords.Count -gt $beforeFailedCount
    $completedRecord = $completedRecords.Count -gt $beforeCompletedCount
    $latestImportRecord = @($records | Where-Object { $_.action -eq "import_external_skill" } | Select-Object -Last 1)
    return [ordered]@{
      case = $Name
      path = $PathValue
      expected = $ExpectedResult
      result = if ($ExpectedResult -eq "passed") {
        if ($success -and $completedRecord) { "passed" } else { "failed" }
      } else {
        if ($failedRecord -and -not $completedRecord) { "passed" } else { "failed" }
      }
      manifest_path = $manifestPath
      localized_manifest_path = $localizedPath
      operation_history_path = $historyPath
      success_artifact = $success
      failure_record = $failedRecord
      completed_record = $completedRecord
      latest_import_status = if ($latestImportRecord.Count -gt 0) { $latestImportRecord[0].status } else { "" }
      latest_import_reason = if ($latestImportRecord.Count -gt 0 -and $latestImportRecord[0].details) { $latestImportRecord[0].details.reason } else { "" }
    }
  }
  $results = @()
  if ($sourceReady -and $parseReady -and $kbReady) {
    $results += Invoke-SkillImportCase "合法 Skill 真实导入" $validDir "passed"
    $results += Invoke-SkillImportCase "重复 Skill 策略" $duplicateDir "passed"
    $results += Invoke-SkillImportCase "非法 Skill 拒绝" $invalidDir "rejected"
    $results += Invoke-SkillImportCase "缺字段 Skill 拒绝" $missingDir "rejected"
    $results += Invoke-SkillImportCase "危险覆盖 Skill 拒绝" $dangerDir "rejected"
    $results += Invoke-SkillImportCase "不存在路径提示" (Join-Path $sampleRoot "missing") "rejected"
  } else {
    $results += [ordered]@{
      case = "前置 KB 构建"
      path = $inputDirForRun
      expected = "passed"
      result = "failed"
      source_ready = $sourceReady
      parse_ready = $parseReady
      kb_ready = $kbReady
      blocker = "external_skill_import_precondition_chain_not_ready"
    }
  }
  $failed = @($results | Where-Object { $_.result -eq "failed" })
  $payload = [ordered]@{
    status = if ($kbReady -and $failed.Count -eq 0) { "passed" } else { "blocked" }
    output_dir = $outputDir
    exe_path = $ExePath
    workspace = $workspace
    sample_root = $sampleRoot
    input_dir = $inputDirForRun
    source_ready = $sourceReady
    parse_ready = $parseReady
    kb_ready = $kbReady
    screenshot = $skillPageShot.path
    results = $results
  }
  Write-Json (Join-Path $outputDir "external_skill_import_results.json") $payload
  Write-Json (Join-Path $OutputRoot "external_skill_import\external_skill_import_results.json") $payload
  $payload | ConvertTo-Json -Depth 12
  if ($payload.status -ne "passed") { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
