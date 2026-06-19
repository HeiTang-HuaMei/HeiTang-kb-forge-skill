# Owner 复验清单

当前复验以 v3 功能评审矩阵为准。

## 基线

- 三份 v3 文档存在于 `docs/product/`。
- `docs/current/CURRENT_PRODUCT_BASELINE_2026-06-19.md` 指向三基线。
- 主链路统一为“文档库 → 知识库 → 索引层 → RAG → 编排层 → 文档/Skill/Agent/A2A”。

## 手工复验

1. 启动 EXE。
2. 创建或选择工作区。
3. 导入真实文件或文件夹。
4. 解析并确认文档库有正文、chunks 和报告。
5. 构建知识库并确认 manifest、quality report、index metadata。
6. 运行检索 / RAG 并确认引用和来源 KB。
7. 生成文档。
8. 生成 Skill 并确认来源 KB。
9. 创建单 Agent 并确认 KB / Skill 绑定。
10. 运行 A2A 讨论并确认议题、轮次、子 Agent 和报告。
11. 打开产物中心和审计中心确认记录。
12. 重启后确认状态一致。

## 禁止通过

- OKF 显示为当前 runtime 或一级页面。
- 登记项目显示为已接入。
- 未配置 provider 却显示成功。
- stable v4.3.0 或 GitHub Release 被误写为已发布。
