# 固定测试样本

## 目的

本文件定义 UI closure 修复阶段使用的固定样本。测试样本必须可识别、可清理、可复现，不得污染 Owner 真实工作区。

## 命名规则

所有 UI closure 测试数据必须带测试标记：

```text
UI008_
```

推荐工作区：

```text
UI008_GoldenWorkspace
UI008_DeleteTmp
UI008_DirtyDataCompat
```

推荐对象命名：

```text
UI008_PDF_A
UI008_PDF_B
UI008_DUPLICATE_A
UI008_BAD_FILE
UI008_LONG_NAME_...
UI008_KB_A
UI008_KB_B
UI008_KB_MERGED
UI008_DOC_REPORT
UI008_SKILL_A
UI008_AGENT_A
```

## 样本 A：PDF_A / TXT_A

用途：

- 验证导入、解析、文档库预览、KB 生成。
- 验证 KB_A 可回答 A 独有问题。

内容要求：

- 包含一个明确事实 A。
- 包含标题、段落、页码或章节。
- 不包含 B 独有事实。

后台真值：

- source_doc_count 增加 1。
- chunk_count 大于 0。
- KB_A source_docs 包含 A。
- KB_A 引用能追到 A 的页码或片段。

## 样本 B：PDF_B / TXT_B

用途：

- 验证第二个知识库。
- 验证 KB_A 不能回答 B 独有问题。
- 验证合并 KB 可回答 A 和 B。

内容要求：

- 包含一个明确事实 B。
- 不包含 A 独有事实。

后台真值：

- KB_B source_docs 包含 B。
- KB_B chunks 不污染 KB_A。
- KB_A 对 B 问题应无依据。

## 重复样本

用途：

- 验证文件导入、文件夹导入、链接导入的去重一致性。

样本：

```text
UI008_DUPLICATE_A_COPY1
UI008_DUPLICATE_A_COPY2
```

预期：

- 相同 content_hash 被识别为重复。
- UI 显示去重结果。
- 不生成多个无法解释的普通成果。

## 冲突样本

用途：

- 验证合并 KB 的冲突标记。

内容要求：

- A 与 B 对同一主题给出不同说法。

预期：

- 合并 KB 不自动覆盖。
- 标记“发现冲突 / 待核查”。
- 验证问题 C 时列出两个来源。

## 坏文件样本

用途：

- 验证可解释失败。

样本类型：

- 空文件。
- 损坏 PDF。
- 不支持格式。

预期：

- UI 显示失败原因。
- 有下一步动作。
- 操作记录可查看、重试、忽略或导出诊断。
- 不显示假成功。

## 长名称样本

用途：

- 验证默认窗口、双语、长文本、导出路径。

命名包含：

- 超长中文。
- 超长英文。
- 空格。
- 中文标点。
- 英文括号。
- 路径敏感字符替代测试：`: * ?` 必须被拦截或转义。

预期：

- UI 不截断关键动作。
- tooltip 或省略策略合理。
- 导出文件名安全。
- 重启后可恢复。

## KB 外问题

用途：

- 验证 Agent / KB 验证不编造。

问题：

```text
请回答只存在于 UI008_PDF_B 的事实，但当前只选择 UI008_KB_A。
```

预期：

- 明确当前知识库无依据。
- 不编造。
- 不引用 B 来源。

## 合并 KB 样本

任务：

```text
UI008_KB_A + UI008_KB_B -> UI008_KB_MERGED
```

预期：

- UI008_KB_A 不变。
- UI008_KB_B 不变。
- UI008_KB_MERGED 是新知识库。
- parent_kbs = [UI008_KB_A, UI008_KB_B]。
- source_docs 是 A 和 B 的并集。
- duplicate_count、near_duplicate_count、conflict_count 有记录。
- 删除 UI008_KB_MERGED 不误删 A/B。

## 导出异常样本

用途：

- 验证导出失败解释。

场景：

- 路径不存在。
- 目标文件已存在。
- 文件被占用。
- 目录不可写。

预期：

- UI 不显示成功。
- 显示失败原因。
- 提供重新选择位置或重试。
- 操作记录保留失败。

## 旧数据 / 脏数据样本

用途：

- 验证旧 workspace、旧 KB、旧成果打开最新 UI。

预期：

- 能读取则正常显示。
- 不能读取则可解释失败。
- 不污染普通成果。
- 不把旧测试报告当用户成果。

## 样本清理规则

测试结束必须检查：

- 测试 workspace 是否仍带 `UI008_` 标记。
- 普通成果页没有遗留工程报告。
- Owner 真实 workspace 未被修改。
- 删除动作只影响 test-marked 对象。

## 最小后台真值表

每次 E2E 至少记录：

| 字段 | 预期 |
| --- | --- |
| workspace_id | UI008 标记 |
| source_doc_count | 与导入样本一致，重复样本去重 |
| chunk_count | 大于 0，坏文件不生成可用 chunk |
| kb_count | 与生成 / 删除 / 合并动作一致 |
| parent_kbs | 合并 KB 可追溯 |
| source_docs | 来源并集正确 |
| artifact_types | 只允许知识库、文档、Skill 包、Agent 包 |
| operation_record_count | 操作有记录，失败可重试 |
| restart_state | 重启后一致 |
