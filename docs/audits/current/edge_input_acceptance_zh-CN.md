# 异常输入与边界输入验收报告

生成日期：2026-06-22

## 结论

```text
passed_with_gated_optional_capabilities
```

## 验收方式

通过 Windows EXE 的真实“导入本地路径”入口和 verifier 自动化覆盖异常输入 / 边界输入。测试临时文件创建在系统临时目录，不修改、不删除、不移动真实输入目录：

```text
D:\HeiTang-Codex-WorkSpace\input
```

## 证据

```text
web/workbench/flutter_app/output/industrial_acceptance/edge_input/edge_input_results.json
```

## 覆盖项

| 输入场景 | 结果 | 说明 |
| --- | --- | --- |
| 空路径 | passed | 不假成功，保持原状态 |
| 不存在路径 | passed | 不假成功，保持原状态 |
| 中文路径 | passed | 可导入 |
| 带空格路径 | passed | 可导入 |
| 单个真实文件 | passed | 可导入 |
| 重复导入 | passed | 不崩溃 |
| 不支持格式文件 | passed | 正确 gate |
| 只含不支持格式的目录 | passed | 正确 gate |
| 空目录 | passed | 正确提示 / 不假成功 |
| 空文件 | passed | 可进入导入或后续 gate，不崩溃 |
| 损坏 PDF | passed | 作为来源处理，整理失败不得 raw error |
| 超长路径 | passed | 可访问时导入或用户可理解提示 |
| 只读目录 | passed | 不修改源目录 |
| 导入中切换页面 | passed | 不崩溃 |

## 约束

本轮只验证软件黑盒行为和源文件保护，不把未配置 OCR / 外部解析能力写成已完成。
