# 实施路线图

## 目的

本文件定义从 0 开发或大修时的实施顺序。当前项目已存在实现，因此本文件也可作为修复排序参考。

## 总原则

- 先数据闭环，再 UI polish。
- 先本地基础链路，再外部增强服务。
- 先单对象生命周期，再组合和并发。
- 先 running UI 可见，再 package candidate。
- 每个阶段都必须有可验证退出条件。

## M0：工程骨架

目标：

- Flutter Windows 可启动。
- 七个主导航存在。
- 当前工作区可见。
- 空状态可理解。

验收：

- `flutter analyze`
- `flutter run -d windows`
- 默认窗口下 7 页可打开。

## M1：工作区与存储

目标：

- 创建、切换、删除、重建工作区。
- workspace manifest 持久化。
- 重启恢复当前工作区。

验收：

- 删除 / 清空 -> 重新创建 -> 重启恢复。
- 后台 workspace_manifest 对账。

## M2：导入资料与文档库

目标：

- 文件、文件夹、链接入口。
- 去重。
- 解析进度。
- 文档库真实来源。
- 摘要 / 正文预览 / 暂无状态。

验收：

- PDF_A / PDF_B / 重复样本 / 坏文件。
- source_manifest、documents、operation records 对账。

## M3：知识库生命周期

目标：

- 从来源生成 KB。
- 查看来源和片段。
- 删除、导出、重启恢复。

验收：

- 文档库 -> 生成 KB -> 查看来源/片段 -> 删除/导出 -> 重启恢复。
- chunks、source_map、kb_catalog 对账。

## M4：多知识库合并

目标：

- 合并创建新知识库。
- parent_kbs 可追溯。
- 去重和冲突标记。
- 删除合并 KB 不误删来源 KB。

验收：

- KB_A + KB_B -> KB_MERGED。
- 中断恢复。
- 重复合并。
- 删除安全。
- 引用追溯。

## M5：知识库验证

目标：

- 清晰选择 KB。
- 输入问题。
- 回答、依据来源、发现问题、建议补充资料。
- 保存、重试、查看来源片段。

验收：

- A 问题、B 问题、冲突问题、KB 外问题。
- 不编造。
- 引用可追溯。

## M6：文档生成

目标：

- 选择 KB。
- 命名文档。
- 选择类型、模板、格式。
- 生成后显示保存位置。
- 打开、导出、删除。

验收：

- 生成报告 / 方案 / 手册。
- 导出路径异常。
- 重启恢复。
- 成果页只作为“文档”。

## M7：Skill

目标：

- 从 KB 生成 Skill。
- 导入 Skill。
- 命名、查看、导出、删除。
- 说明快照型 / 指针型依赖。

验收：

- 删除源资料后 Skill 行为可解释。
- 成果页只作为 Skill 包。

## M8：Agent

目标：

- 创建助手。
- 命名。
- 绑定 KB / Skill。
- 知识边界回答。
- 最近引用来源可查看。

验收：

- KB 内问题回答并引用。
- KB 外问题拒答。
- 通用知识显式开启并标注。
- 保存、删除、重启恢复。

## M9：任务工作台与成果页

目标：

- 成果只显示四类。
- 操作记录可清理。
- 失败记录可重试。
- 支持诊断包导出。

验收：

- KB / 文档 / Skill / Agent 包出现在成果页。
- 工程证据不混入成果页。
- 删除成果不误删来源资产。

## M10：配置与外部增强

目标：

- AI、Embedding、Redis、向量库、文档解析增强、外部连接配置。
- 连接测试。
- 未配置不阻断本地基础链路。

验收：

- 清空配置后本地链路仍可跑。
- 配置错误可解释。
- 不泄露密钥。

## M11：全局 UI closure

目标：

- 双语。
- 默认窗口。
- 长文本。
- 视觉一致。
- running UI 旧词扫描。

验收：

- 中文 / 英文 7 页 smoke。
- forbidden/internal wording scan。
- screenshot / accessibility tree 检查。

## M12：Package candidate

只在 UI closure 通过后进入。

目标：

- analyze 通过。
- targeted smoke 通过。
- Windows candidate build 通过。
- EXE smoke 通过。
- 外部服务边界和密钥扫描通过。

注意：

- 不等于 production ready。
- 不等于 release ready。
- 不等于 Final Owner Review 通过。
