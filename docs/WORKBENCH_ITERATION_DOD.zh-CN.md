# Workbench 迭代 DoD 与验收规则

## 总规则

每个版本必须解决一个大问题，不允许把核心缺口留到补丁版本。

## 每版必须包含

1. 功能实现。
2. CLI 或 API 入口。
3. JSON 机器可读输出。
4. Markdown 人类可读报告。
5. 文档。
6. 英文 / 中文关键文档。
7. 测试。
8. smoke 命令。
9. release-readiness 检查。
10. README 边界检查。
11. CHANGELOG 更新。
12. Capability Status 更新。
13. Version Matrix 更新。
14. Known Limits。
15. 不进入下一版本的自审报告。

## 每版禁止

1. CI 红进入下一版。
2. README 声明未完成能力。
3. mock 冒充 live。
4. 强制依赖外部网络。
5. 默认保存 API key。
6. 将 optional heavy backend 变成默认依赖。
7. 只做壳不做真实 smoke。
8. 把 P0 留给 x.x.1。
9. 同时做多个主线大问题。
10. 临时目录残留。

## v2.8 DoD

必须证明：

1. Docling / Marker 至少一个本地 smoke 可跑。
2. 未安装后端时有清晰错误提示。
3. builtin parser 不受影响。
4. parser_backend_result.json 存在。
5. parse_compare_report.md 存在。
6. high_risk_parse_pages.jsonl 存在。
7. manual_review_queue.jsonl 存在。
8. corrected_text re-import 可跑。
9. before / after quality diff 可生成。
10. full pytest 通过。

## v2.9 DoD

必须证明：

1. 知识包可以 index。
2. 可以 query。
3. 可以 answer。
4. answer 必须带 citation。
5. 找不到证据时必须拒答。
6. query trace 存在。
7. retrieval quality report 存在。
8. RAG eval baseline 存在。
9. 不需要 live key 也能跑 mock smoke。
10. full pytest 通过。

## v3.0 DoD

必须证明：

1. generate-md 成功。
2. generate-docx 成功。
3. generate-pdf 成功。
4. generate-pptx 成功。
5. 每个文件都带 source evidence appendix 或 citation。
6. generated_file_report.json 存在。
7. export validation 通过。
8. 模板可配置。
9. 输出文件可打开。
10. full pytest 通过。

## v3.1 DoD

必须证明：

1. 选择知识库 + 行业模板能生成 Agent / Skill。
2. 生成物包含知识库绑定。
3. 生成物包含检索配置。
4. 生成物包含 Provider 配置。
5. 生成物包含证据策略。
6. 生成物包含拒答策略。
7. agent test cases 存在。
8. agent smoke test 通过。
9. skill validation report 存在。
10. full pytest 通过。

## v3.2 DoD

必须证明：

1. 可以导入外部 Skill。
2. 可以提取 instruction。
3. 可以提取 tools/schema。
4. 可以提取 examples。
5. 可以生成 capability map。
6. 可以生成 prompt pattern map。
7. 可以生成 fusion plan。
8. 可以生成 fused skill。
9. 可以输出 diff report。
10. 可以输出 safety boundary report。
11. full pytest 通过。

## v3.3 DoD

必须证明：

1. 本地 UI 可启动。
2. 可上传文件。
3. 可查看任务队列。
4. 可查看进度。
5. 可浏览知识包。
6. 可查看 review queue。
7. 可编辑 corrected text。
8. 可查询知识库。
9. 可生成文档。
10. 可生成 Agent / Skill。
11. 可导出结果。
12. UI smoke 通过。
13. full pytest 通过。

## v3.4 DoD

必须证明：

1. 新机器可安装。
2. 一键启动。
3. doctor 能检查依赖。
4. parser backend doctor 可跑。
5. OCR doctor 可跑。
6. 任务失败可重试。
7. job resume 可用。
8. workspace 可备份。
9. workspace 可恢复。
10. demo mode 稳定。
11. release candidate checklist 通过。
12. full pytest 通过。
