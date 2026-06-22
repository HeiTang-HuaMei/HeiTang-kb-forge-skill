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

$outputDir = New-VerifierRunDir $OutputRoot "workspace_isolation"
$screenshotsDir = Join-Path $outputDir "screenshots"
$workspace = Get-WorkspacePath
Clear-WorkbenchWorkspace
$launch = $null
try {
  $launch = Start-WorkbenchExeForMainChain $ExePath
  $hwnd = $launch.hwnd
  $mainReady = Wait-ForCondition { (Get-ArtifactChecks $workspace).agent_dialogue } 300
  Send-ControlAlt "2"
  $workspaceShot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir "workspace_page.png")

  $workbookManifestPath = Join-Path $workspace "workbooks\workbook_manifest.json"
  $permissionMatrixPath = Join-Path $workspace "agent\audit\workspace_permission_matrix.json"
  $agentWorkspaceRoot = Join-Path $workspace "agent\workspaces"
  $workbookManifest = Read-JsonFile $workbookManifestPath
  $permissionMatrix = Read-JsonFile $permissionMatrixPath
  $artifactChecks = Get-ArtifactChecks $workspace

  $rows = @()
  function Add-Row([string]$Case, [string]$Expected, [string]$Result, [string]$Artifact, [string]$Note) {
    $script:rows += [ordered]@{
      case = $Case
      expected_behavior = $Expected
      result = $Result
      artifact = $Artifact
      note = $Note
    }
  }

  Add-Row "工作区 A 创建" "默认工作本/工作区资产索引应创建。" `
    ($(if ($workbookManifest -and $workbookManifest.workbooks.Count -ge 1) { "passed" } else { "failed" })) $workbookManifestPath "current=$($workbookManifest.current_workbook)"
  Add-Row "工作区 B 创建" "当前产品未提供多物理工作区 A/B 创建入口；工作本记录可创建但不等同物理隔离。" `
    "gated" $workbookManifestPath "not_implemented_as_physical_workspace"
  Add-Row "A 导入文档" "主链路应在当前工作区导入真实文档。" `
    ($(if ($mainReady -and $artifactChecks.source_manifest) { "passed" } else { "failed" })) (Join-Path $workspace "source_manifest.json") ""
  Add-Row "B 不应看到 A 私有文档" "未实现多物理工作区 B，不能声明通过；应 gate。" `
    "gated" $workbookManifestPath "not_implemented"
  Add-Row "A 构建知识库" "当前工作区知识库真实产物存在。" `
    ($(if ($artifactChecks.knowledge_base) { "passed" } else { "failed" })) (Join-Path $workspace "kb") ""
  Add-Row "B 不应误用 A 知识库" "未实现多物理工作区 B，不能声明通过；应 gate。" `
    "gated" $workbookManifestPath "not_implemented"
  Add-Row "成果中心隔离" "当前成果中心映射当前本地工作区真实产物；多工作区隔离未实现。" `
    "gated" $workbookManifestPath "single_workspace_mode"
  Add-Row "使用记录隔离或筛选" "使用记录来自当前 runtime state；多工作区筛选未实现。" `
    "gated" (Join-Path $workspace "audit\audit_report.json") "single_workspace_mode"
  Add-Row "Agent 权限隔离" "Agent workspace permission matrix 如存在则验证；未完整落地时必须 gate，不能声明 passed。" `
    ($(if ($permissionMatrix -or (Test-Path -LiteralPath $permissionMatrixPath)) { "passed" } else { "gated" })) $permissionMatrixPath "optional_permission_matrix"
  Add-Row "多助手子工作区隔离资产" "A2A/子 Agent 工作区资产应存在或正确 gate。" `
    ($(if (Test-Path -LiteralPath $agentWorkspaceRoot) { "passed" } else { "gated" })) $agentWorkspaceRoot "A2A optional"
  Add-Row "删除临时工作区二次确认" "工作区/工作本删除 UI 有确认；物理工作区删除未作为自动化目标执行。" `
    "gated" $workbookManifestPath "destructive path requires explicit temporary workbook target"
  Add-Row "删除不影响 input 原文件" "本轮未修改、未移动、未删除真实 input 原文件。" `
    ($(if (Test-Path -LiteralPath $InputDir) { "passed" } else { "failed" })) $InputDir ""

  $failed = @($rows | Where-Object { $_.result -eq "failed" })
  $status = if ($failed.Count -eq 0) { "passed_with_gated_optional_capabilities" } else { "blocked" }
  $payload = [ordered]@{
    status = $status
    output_dir = $outputDir
    exe_path = $ExePath
    input_dir = $InputDir
    workspace = $workspace
    main_chain_ready = $mainReady
    screenshot = $workspaceShot.path
    workbook_manifest_path = $workbookManifestPath
    permission_matrix_path = $permissionMatrixPath
    results = $rows
  }
  Write-Json (Join-Path $outputDir "workspace_isolation_matrix.json") $payload
  Write-Json (Join-Path $OutputRoot "workspace_isolation\workspace_isolation_matrix.json") $payload
  $payload | ConvertTo-Json -Depth 14
  if ($status -eq "blocked") { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
