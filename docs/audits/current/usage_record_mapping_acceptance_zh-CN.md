# 使用记录逐条映射验收报告

生成日期：2026-06-22

## 结论

```text
passed_with_gated_optional_capabilities
```

## 验收方式

使用 Windows EXE 自动运行真实主链路后导出 `audit_report.json`，逐条检查使用记录字段：

```text
action_type
time
object
result
```

本轮 verifier 已收紧规则：`not_run` 占位记录不算通过，只有真实 success / ready 等非占位记录才能作为映射证据。

## 证据

```text
web/workbench/flutter_app/output/industrial_acceptance/usage_mapping/usage_record_mapping_results.json
```

## 已映射动作

| 动作 | 结果 | 说明 |
| --- | --- | --- |
| 导入路径 / 导入文件 | passed | 映射到 `source_import` |
| 资料整理 | passed | 映射到 `parse_chunk` |
| 知识库创建 / 测试 / 检索 | passed | 映射到 `build` / `query` |
| Markdown 生成 / 导出 | passed | 映射到 `export` |
| Skill 生成 | passed | 映射到 `generate_skill` |
| Agent 创建 / Agent 对话 | passed | 映射到 `generate_agent` / `agent_dialogue` |
| 成果打开 | passed | 映射到真实 artifact records |
| 设置保存 / 配置切换 | passed | 映射到配置日志或 audit |
| 外部 Skill 导入 | gated | 未完整落地，不写 passed |
| 成果删除 / 清空记录 / 危险操作取消确认 | gated | 由危险操作 smoke 证明二次确认，不伪造使用记录 |

## 风险

UI 页面仍以截图方式确认可见；逐条机器映射以导出的真实 audit JSON 为准。
