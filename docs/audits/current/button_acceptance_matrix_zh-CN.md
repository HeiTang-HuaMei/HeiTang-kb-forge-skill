# 按钮矩阵验收报告

生成日期：2026-06-22

## 结论

```text
passed_with_gated_optional_capabilities
```

## 验收方式

使用 Windows 原生 Product Verifier 启动真实 EXE，覆盖 11 个页面的主操作入口、次操作入口、危险操作入口和未配置能力 gate。Flutter 控件树不能稳定被 Windows UIAutomation 完整读取，因此按钮矩阵采用：

```text
页面截图非白屏 / 非黑屏
相对坐标导航
稳定快捷入口
真实文件系统产物
audit_report.json 使用记录字段
未配置能力不产生假产物
```

## 证据

```text
web/workbench/flutter_app/output/industrial_acceptance/button_matrix/button_acceptance_matrix.json
web/workbench/flutter_app/output/industrial_acceptance/button_matrix/button_acceptance_matrix.md
```

## 关键结果

| 类别 | 结果 | 说明 |
| --- | --- | --- |
| 首页 / 工作区 / 文档库 / 知识库 / 测试知识库 / 文档生成 / 技能生成 / 我的助手 / 成果中心 / 使用记录 / 设置 | passed | 页面可打开，截图有效 |
| 导入路径、整理资料、生成知识库、测试知识库、生成 Markdown、导出 Markdown | passed | 产生真实工作区产物和使用记录 |
| 生成 Skill、创建 Agent、发送对话 | passed | 产生真实 Skill / Agent / 对话产物 |
| DOCX / PDF / PPTX 导出 | gated | 未配置时不得假成功 |
| 外部 Skill 导入 | gated | 当前未作为完整可用能力宣传 |
| 多助手协作入口 | gated | 未配置依赖时不得假成功 |
| 设置测试连接 / 重置回滚 | gated | 未配置外部服务时显示需要设置 / 本地模式 |

## 风险

Windows 原生自动化仍依赖相对坐标和文件产物交叉验证，不等同于完整 Flutter accessibility tree 断言。
