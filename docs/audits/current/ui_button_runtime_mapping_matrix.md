# UI Button Runtime Mapping Matrix

生成日期：2026-06-23

状态：

```text
ui_core_operation_alignment_required
button_runtime_mapping_required
industrial_full_product_acceptance_blocked
```

说明：

```text
本矩阵只对普通用户 UI 的主要按钮做 runtime / route / artifact / settings 对齐。
没有真实动作的按钮必须隐藏、降级为查看、禁用并提示需要设置。
完整 EXE 全按钮点击矩阵尚未覆盖所有控件，因此保留 industrial_full_product_acceptance_blocked。
```

| 页面 | 区域 | 按钮文案 | 按钮类型 | 用户意图 | 真实动作 | Runtime 方法 | 是否需要配置 | 未配置显示 | 成功后产物 | 失败后提示 | 是否写入最近动态 | 是否写入使用记录 | 验收方式 | 当前结论 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 首页 | Hero | 整理资料 | route_action | 进入资料整理 | 跳转文档库 | _pageIndexById('document-library') | 否 | 不适用 | 无 | 不适用 | 否 | 否 | 截图 + 路由映射 | passed |
| 首页 | Hero | 查看流程 | route_action | 查看资料到成果流程 | 跳转文档库 / 流程起点 | _pageIndexById('document-library') | 否 | 不适用 | 无 | 不适用 | 否 | 否 | 截图 + 路由映射 | passed |
| 首页 | 最近成果 | 查看全部成果 | route_action | 查看所有真实成果 | 打开全部成果二级页 | _pageIndexById('artifact-center') | 否 | 无成果时显示空状态 | 真实 artifact 列表 | 空状态 | 否 | 否 | 截图 + artifact 列表 | passed |
| 首页 | 最近动态 | 查看全部动态 | route_action | 查看操作记录 | 打开操作记录二级页 | _pageIndexById('reports-audit') | 否 | 无记录时显示空状态 | audit report / runtime records | 空状态 | 否 | 否 | 截图 + audit 页 | passed |
| 首页 | 继续任务 | 继续任务 | route_action | 回到下一步页面 | 按任务 pageId 跳转 | _pageIndexById(row.pageId) | 否 | 不适用 | 无 | 不适用 | 否 | 否 | 截图 + 路由映射 | passed |
| 文档库 | 导入 | 添加资料 | primary_action | 导入资料 | 导入本地路径 / 文件夹 | importLocalPath / importExternalSkillPath 按入口区分 | 否 | 路径为空时禁用或提示 | source_manifest / source records | 显示导入错误 | 是 | 是 | runtime 产物 | mapped |
| 文档库 | 导入 | 整理资料 | primary_action | 解析并整理资料 | 解析、分块、生成整理报告 | parseAndChunkSources | 否 | 未导入时禁用 | parse_report / chunks | 显示解析错误 | 是 | 是 | runtime 产物 | mapped |
| 文档库 | 列表 | 查看资料 | view_action | 查看来源详情 | 打开预览 / 详情 | artifact preview helper | 否 | 无资料显示空状态 | 无新增产物 | 不适用 | 否 | 否 | UI 预览 | mapped |
| 文档库 | 列表 | 删除资料 | destructive_action | 移除来源 | 删除导入来源记录 | deleteImportedSource / clearImportedSources | 否 | 无资料时禁用 | source manifest 更新 | 确认弹窗 + 错误提示 | 是 | 是 | runtime 状态 | mapped |
| 知识库 | 概览 | 生成知识库 | primary_action | 构建知识库 | 生成 KB 产物 | buildKnowledgeBase | 否 | 未导入/未选择来源时禁用 | kb manifest / catalog / quality report | 显示构建错误 | 是 | 是 | runtime 产物 | mapped |
| 知识库 | 概览 | 打开知识库 | view_action | 查看 KB 产物 | 打开当前 KB 记录 | artifact preview helper | 否 | 无 KB 显示等待 | 无新增产物 | 空状态 | 否 | 否 | UI 预览 | mapped |
| 知识库 | 验证 | 验证 | primary_action | 验证证据与引用 | 执行知识库查询 | search | 否 | 无 KB 时禁用 | query result / validation report | 显示检索错误 | 是 | 是 | runtime 产物 | mapped |
| 知识库 | 引用 | 查看引用 | view_action | 查看引用证据 | 读取 searchResults / citation artifact | runtime state read | 否 | 无验证结果显示空状态 | 无新增产物 | 空状态 | 否 | 否 | 截图 + runtime 状态 | mapped |
| 知识库 | 缺口 | 查看缺口 | view_action | 查看覆盖缺口 | 读取 validation / conflict / coverage artifact | runtime state read | 否 | 无验证结果显示空状态 | 无新增产物 | 空状态 | 否 | 否 | 截图 + runtime 状态 | mapped |
| 知识库 | 快捷 | 生成文档 | route_action | 从 KB 进入文档生成 | 跳转文档生成 | _pageIndexById('document-generation') | 否 | 无 KB 时提示先生成 | 无 | 不适用 | 否 | 否 | 路由映射 | mapped |
| 知识库 | 快捷 | 生成技能 | route_action | 从 KB 进入技能生成 | 跳转技能生成 | _pageIndexById('skill-factory') | 否 | 无 KB 时提示先生成 | 无 | 不适用 | 否 | 否 | 路由映射 | mapped |
| 知识库 | 快捷 | 创建助手 | route_action | 从 KB 进入助手配置 | 跳转我的助手 | _pageIndexById('agent-factory-runtime') | 否 | 无 KB 时提示先生成 | 无 | 不适用 | 否 | 否 | 路由映射 | mapped |
| 文档生成 | 主操作 | 生成文档 | primary_action | 生成 Markdown 文档 | 生成文档草稿 | generateMarkdown | 否 | 无 KB 时禁用 | generated markdown | 显示生成错误 | 是 | 是 | runtime 产物 | mapped |
| 文档生成 | 草稿 | 保存草稿 | secondary_action | 保存编辑内容 | 保存草稿状态 / 当前文档 | document workflow state / export helper | 否 | 无草稿时禁用 | draft / markdown | 显示保存错误 | 是 | 是 | 产物路径 | mapped |
| 文档生成 | 导出 | 导出 | primary_action | 导出文档 | 导出 Markdown / 配置格式 | exportMarkdownDocument | 可选 | 未配置格式显示需要设置 | exported document | 显示导出错误 | 是 | 是 | runtime 产物 | mapped |
| 文档生成 | 成果 | 打开成果 | view_action | 查看生成结果 | 打开全部成果二级页 / 产物预览 | _showWorkspaceArtifactPreview / _pageIndexById('artifact-center') | 否 | 无成果显示空状态 | 无新增产物 | 空状态 | 否 | 否 | 截图 + 预览 | mapped |
| 技能生成 | 主操作 | 生成技能 | primary_action | 生成 Skill | 生成技能产物 | generateSkill | 否 | 无 KB 时禁用 | SKILL.md / skill report | 显示生成错误 | 是 | 是 | runtime 产物 | mapped |
| 技能生成 | 验收 | 验证技能 | secondary_action | 检查技能 | 验证技能报告 | skill verification runtime action | 否 | 无技能时禁用 | skill validation report | 显示验证错误 | 是 | 是 | runtime 产物 | mapped |
| 技能生成 | 导出 | 导出技能 | primary_action | 导出技能包 | 导出技能 | skill export runtime action | 否 | 无技能时禁用 | skill export package | 显示导出错误 | 是 | 是 | runtime 产物 | mapped |
| 技能生成 | 助手 | 绑定助手 | route_action | 用技能配置助手 | 跳转我的助手配置 | _pageIndexById('agent-factory-runtime') | 否 | 无技能时提示先生成 | 无 | 不适用 | 否 | 否 | 路由映射 | mapped |
| 我的助手 | 左侧 | 创建助手 | primary_action | 创建助手配置 | 生成助手产物 | completeAgentProductOperations | 否 | running 时禁用 | agent manifest | 显示创建错误 | 是 | 是 | runtime 产物 | mapped |
| 我的助手 | 助手对话 | 助手对话 | primary_action | 发起对话 | 运行助手对话 | runAgentDialogue | 需要助手和技能 | 未创建助手/技能时禁用并提示需要设置 | dialogue history / exportable result | 显示对话错误 | 是 | 是 | runtime 产物 | mapped |
| 我的助手 | 工作小组 | 启动工作小组 | primary_action | 多助手任务流处理 | 运行工作小组 | runMultiAgentDiscussion | 需要助手/技能/知识库 | 未满足时禁用或显示需要设置 | stage summary / final result | 显示运行错误 | 是 | 是 | runtime 产物 | mapped |
| 我的助手 | 右侧 | 保存到成果 | secondary_action | 保存当前结果 | 生成或打开成果记录 | run/export action + artifact preview | 视产物而定 | 无结果时禁用 | assistant / work group artifact | 显示保存错误 | 是 | 是 | artifact 记录 | mapped |
| 我的助手 | 右侧 | 查看记录 | view_action | 查看操作轨迹 | 打开操作记录二级页 | _pageIndexById('reports-audit') | 否 | 无记录显示空状态 | 无新增产物 | 空状态 | 否 | 否 | 路由映射 | mapped |
| 我的助手 | 助手配置 | 绑定知识库 | settings_action | 给助手绑定 KB | 读取当前 KB / 生成助手配置 | completeAgentProductOperations | 需要 KB | 无 KB 时提示先生成 | agent config | 显示配置错误 | 是 | 是 | runtime 产物 | mapped |
| 我的助手 | 助手配置 | 绑定技能 | settings_action | 给助手绑定技能 | 读取当前技能 / 生成助手配置 | completeAgentProductOperations | 需要技能 | 无技能时提示先生成 | agent config | 显示配置错误 | 是 | 是 | runtime 产物 | mapped |
| 设置 | 基础 | 保存设置 | settings_action | 保存连接配置 | 写入设置文件 | saveProviderRuntimeSettings / project config methods | 否 | 表单无效时禁用 | provider settings | 显示保存错误 | 是 | 是 | settings artifact | mapped |
| 设置 | 连接 | 测试连接 | settings_action | 校验连接 | 运行连接验证 | validateProviderRuntimeSettings / testProjectConfigProfile | 是 | 未配置显示需要设置 | validation report | 显示连接错误 | 是 | 是 | runtime 产物 | mapped |
| 设置 | 高级 | 打开高级设置 | route_action | 查看高级配置 | 切换设置内部 Tab | _PageTabs selectedTab | 否 | 不适用 | 无 | 不适用 | 否 | 否 | 截图 | mapped |
| 设置 | 高级 | 配置连接 | settings_action | 配置外部能力 | 编辑并保存连接配置 | saveProviderRuntimeSettings / storage config methods | 是 | 未保存前显示需要设置 | config artifact | 显示保存错误 | 是 | 是 | settings artifact | mapped |
