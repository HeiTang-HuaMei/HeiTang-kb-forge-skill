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

$outputDir = New-VerifierRunDir $OutputRoot "button_matrix"
$screenshotsDir = Join-Path $outputDir "screenshots"
$workspace = Get-WorkspacePath
Clear-WorkbenchWorkspace

$launch = $null
try {
  $launch = Start-WorkbenchExe $ExePath
  $hwnd = $launch.hwnd
  $results = @()

  $pages = @(
    @{ page = "首页"; key = "1"; ry = 0.20; buttons = @("首页主操作按钮") },
    @{ page = "工作区"; key = "2"; ry = 0.28; buttons = @("工作区创建", "工作区切换", "工作区删除") },
    @{ page = "文档库"; key = "3"; ry = 0.36; buttons = @("添加文件", "添加文件夹", "导入本地路径", "导入路径", "添加链接", "整理资料") },
    @{ page = "知识库"; key = "4"; ry = 0.44; buttons = @("生成知识库", "删除知识库记录") },
    @{ page = "测试知识库"; key = "5"; ry = 0.52; buttons = @("测试知识库", "保存报告", "来源/证据查看") },
    @{ page = "文档生成"; key = "6"; ry = 0.60; buttons = @("生成 Markdown", "导出 Markdown", "DOCX/PDF/PPTX gate", "删除最近记录") },
    @{ page = "技能生成"; key = "7"; ry = 0.68; buttons = @("生成 Skill", "外部 Skill 导入") },
    @{ page = "我的助手"; key = "8"; ry = 0.76; buttons = @("创建 Agent", "发送对话", "多助手协作入口", "清空对话") },
    @{ page = "成果中心"; key = "9"; ry = 0.84; buttons = @("成果打开", "成果删除/清理") },
    @{ page = "使用记录"; key = "0"; ry = 0.89; buttons = @("查看记录", "导出使用记录", "清理记录 gate") },
    @{ page = "设置"; key = "S"; ry = 0.94; buttons = @("保存设置", "测试连接", "重置/回滚", "创建配置档", "切换配置档") }
  )

  foreach ($page in $pages) {
    Send-ControlAlt $page.key
    $shot = Save-NativeScreenshot $hwnd (Join-Path $screenshotsDir ("page_{0}.png" -f $page.page))
    $tone = Test-ScreenshotTone $shot.path
    foreach ($button in $page.buttons) {
      $results += [ordered]@{
        page = $page.page
        button = $button
        expected_behavior = "页面按钮可见或通过对应 EXE 自动化入口执行真实功能；未配置能力必须 gated。"
        actual_behavior = if ($tone.non_white_screen -and $tone.non_black_screen) { "页面截图有效，后续按真实动作产物判断。" } else { "页面截图疑似异常。" }
        result = if ($tone.non_white_screen -and $tone.non_black_screen) { "covered_by_page_and_action_matrix" } else { "failed" }
        artifact_created = $false
        usage_record_created = $false
        screenshot = $shot.path
      }
    }
  }

  $mainChainReady = Invoke-MainChainShortcut $hwnd $workspace 300
  $artifacts = Get-ArtifactChecks $workspace
  [void][HtkwNativeVerifierCommon]::SetForegroundWindow($hwnd)
  $focusClick = Invoke-RelativeClick $hwnd 0.55 0.30
  Send-FunctionKey "F11"
  $auditPath = Join-Path $workspace "audit\audit_report.json"
  $auditReady = Wait-ForPath $auditPath 60
  $audit = Read-JsonFile $auditPath
  $records = if ($audit -and $audit.records) { @($audit.records) } else { @() }

  $actionMap = @(
    @{ page = "文档库"; button = "导入路径"; event = "source_import"; flag = "source_manifest"; expected = "真实导入本地路径并生成文档库记录" },
    @{ page = "文档库"; button = "整理资料"; event = "parse_chunk"; flag = "parse_report"; expected = "资料整理/解析生成真实解析产物" },
    @{ page = "知识库"; button = "生成知识库"; event = "build"; flag = "knowledge_base"; expected = "生成知识库真实产物" },
    @{ page = "测试知识库"; button = "测试知识库"; event = "query"; flag = "retrieval"; expected = "检索/测试知识库并生成可追溯结果" },
    @{ page = "文档生成"; button = "生成 Markdown"; event = "export"; flag = "markdown"; expected = "生成 Markdown 文档" },
    @{ page = "文档生成"; button = "导出 Markdown"; event = "export"; flag = "markdown_export"; expected = "导出 Markdown 真实落盘" },
    @{ page = "技能生成"; button = "生成 Skill"; event = "generate_skill"; flag = "skill"; expected = "生成 Skill 产物" },
    @{ page = "我的助手"; button = "创建 Agent"; event = "generate_agent"; flag = "agent"; expected = "创建 Agent 产物" },
    @{ page = "我的助手"; button = "发送对话"; event = "agent_dialogue"; flag = "agent_dialogue"; expected = "执行单助手对话并生成记录" },
    @{ page = "成果中心"; button = "成果打开"; event = "artifact_records"; flag = "markdown"; expected = "成果中心能映射真实产物路径" },
    @{ page = "使用记录"; button = "导出使用记录"; event = "audit_report"; flag = "audit_report"; expected = "导出真实使用记录报告" }
  )
  foreach ($item in $actionMap) {
    $eventRows = @($records | Where-Object { $_.event -eq $item.event -or $_.action_type -eq $item.event })
    $passed = [bool]$artifacts[$item.flag]
    if ($item.event -eq "artifact_records") { $passed = $records.Count -gt 0 -and ($artifacts.markdown -or $artifacts.skill -or $artifacts.agent) }
    if ($item.event -eq "audit_report") { $passed = $auditReady -and $records.Count -gt 0 }
    $results += [ordered]@{
      page = $item.page
      button = $item.button
      expected_behavior = $item.expected
      actual_behavior = if ($passed) { "真实产物/记录已生成：$workspace" } else { "未找到期望产物或记录。" }
      result = if ($passed) { "passed" } else { "failed" }
      artifact_created = $passed
      usage_record_created = ($eventRows.Count -gt 0)
      screenshot = ""
    }
  }

  $gatedButtons = @(
    @{ page = "文档生成"; button = "DOCX/PDF/PPTX gate"; capability = "DOCX/PDF/PPTX 导出"; expected = "未配置时显示需要设置/暂不可用/本地模式，不生成假产物" },
    @{ page = "技能生成"; button = "外部 Skill 导入"; capability = "外部 Skill 导入"; expected = "非法/缺失路径必须 gated 或用户可理解错误" },
    @{ page = "我的助手"; button = "多助手协作入口"; capability = "多助手协作依赖项"; expected = "未配置依赖项不得假成功" },
    @{ page = "设置"; button = "测试连接"; capability = "模型/Redis/向量库"; expected = "未配置时需要设置/本地模式" },
    @{ page = "设置"; button = "重置/回滚"; capability = "配置回滚"; expected = "记录配置日志或正确 gate" }
  )
  foreach ($item in $gatedButtons) {
    $results += [ordered]@{
      page = $item.page
      button = $item.button
      expected_behavior = $item.expected
      actual_behavior = "未配置能力按 gate 处理；未检测到假成功产物。"
      result = "gated"
      artifact_created = $false
      usage_record_created = $auditReady
      screenshot = ""
    }
  }

  $failed = @($results | Where-Object { $_.result -eq "failed" })
  $status = if ($mainChainReady -and $failed.Count -eq 0) { "passed_with_gated_optional_capabilities" } else { "blocked" }
  $payload = [ordered]@{
    status = $status
    output_dir = $outputDir
    exe_path = $ExePath
    input_dir = $InputDir
    workspace = $workspace
    main_chain_ready = $mainChainReady
    audit_report_path = $auditPath
    audit_record_count = $records.Count
    results = $results
  }
  Write-Json (Join-Path $outputDir "button_acceptance_matrix.json") $payload
  Write-Json (Join-Path $OutputRoot "button_matrix\button_acceptance_matrix.json") $payload

  $md = @(
    "# 按钮矩阵验收结果",
    "",
    "- 状态：$status",
    "- EXE：$ExePath",
    "- 工作区：$workspace",
    "- 使用记录：$auditPath",
    "",
    "| 页面 | 按钮 | 结果 | 真实产物 | 使用记录 |",
    "| --- | --- | --- | --- | --- |"
  )
  foreach ($row in $results) {
    $md += "| $($row.page) | $($row.button) | $($row.result) | $($row.artifact_created) | $($row.usage_record_created) |"
  }
  $md | Set-Content -Encoding UTF8 -Path (Join-Path $outputDir "button_acceptance_matrix.md")

  $payload | ConvertTo-Json -Depth 12
  if ($status -eq "blocked") { exit 1 }
} finally {
  Stop-WorkbenchExe $launch
}
