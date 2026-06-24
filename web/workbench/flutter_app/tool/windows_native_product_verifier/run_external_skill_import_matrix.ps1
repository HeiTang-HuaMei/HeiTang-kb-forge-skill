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
$validDir = Join-Path $sampleRoot "valid_skill"
$duplicateDir = Join-Path $sampleRoot "duplicate_skill"
$invalidDir = Join-Path $sampleRoot "invalid_skill"
$missingDir = Join-Path $sampleRoot "missing_fields_skill"
$dangerDir = Join-Path $sampleRoot "dangerous_override_skill"
New-Item -ItemType Directory -Force -Path $validDir,$duplicateDir,$invalidDir,$missingDir,$dangerDir | Out-Null

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

$workspace = Get-WorkspacePath
Clear-WorkbenchWorkspace
$launch = $null
try {
  $launch = Start-WorkbenchExeForMainChain $ExePath
  $hwnd = $launch.hwnd
  $mainReady = Wait-ForCondition { (Get-ArtifactChecks $workspace).skill } 300
  Send-ControlAlt "7"
  $skillPageShot = Save-NativeScreenshot $hwnd (Join-Path $outputDir "skill_page_before_import.png")
  function Invoke-SkillImportCase([string]$Name, [string]$PathValue, [string]$ExpectedResult) {
    Set-VerifierClipboardText $PathValue
    [void][HtkwNativeVerifierCommon]::SetForegroundWindow($hwnd)
    Invoke-RelativeClick $hwnd 0.55 0.30 | Out-Null
    Send-ControlAlt "X"
    Start-Sleep -Seconds 8
    $manifestPath = Join-Path $workspace "skill\external_imported_skill\S0\external_skill_manifest.json"
    $localizedPath = Join-Path $workspace "skill\localized_writing_skill\S2\localized_skill_manifest.json"
    $historyPath = Join-Path $workspace "skill\operations\skill_operation_history.json"
    $history = Read-JsonFile $historyPath
    $records = if ($history -and $history.records) { @($history.records) } else { @() }
    $success = (Test-Path -LiteralPath $manifestPath) -and (Test-Path -LiteralPath $localizedPath)
    $failedRecord = @($records | Where-Object { $_.action -eq "import_external_skill" -and $_.status -eq "failed" }).Count -gt 0
    $completedRecord = @($records | Where-Object { $_.action -eq "import_external_skill" -and $_.status -eq "completed" }).Count -gt 0
    return [ordered]@{
      case = $Name
      path = $PathValue
      expected = $ExpectedResult
      result = if ($ExpectedResult -eq "passed") {
        if ($success -and $completedRecord) { "passed" } else { "failed" }
      } else {
        if ($failedRecord -or -not $success) { "passed" } else { "failed" }
      }
      manifest_path = $manifestPath
      localized_manifest_path = $localizedPath
      operation_history_path = $historyPath
      success_artifact = $success
      failure_record = $failedRecord
      completed_record = $completedRecord
    }
  }
  $results = @()
  $results += Invoke-SkillImportCase "合法 Skill 真实导入" $validDir "passed"
  $results += Invoke-SkillImportCase "重复 Skill 策略" $duplicateDir "passed"
  $results += Invoke-SkillImportCase "非法 Skill 拒绝" $invalidDir "rejected"
  $results += Invoke-SkillImportCase "缺字段 Skill 拒绝" $missingDir "rejected"
  $results += Invoke-SkillImportCase "危险覆盖 Skill 拒绝" $dangerDir "rejected"
  $results += Invoke-SkillImportCase "不存在路径提示" (Join-Path $sampleRoot "missing") "rejected"
  $failed = @($results | Where-Object { $_.result -eq "failed" })
  $payload = [ordered]@{
    status = if ($mainReady -and $failed.Count -eq 0) { "passed" } else { "blocked" }
    output_dir = $outputDir
    exe_path = $ExePath
    workspace = $workspace
    sample_root = $sampleRoot
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
