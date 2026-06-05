# 版本溯源

## v1.6 负责范围

v1.6 负责：

- progress 与大文件 / OCR 性能基线
- 多模态知识资产
- 多模态 evidence map
- Knowledge Package Contract v2
- contract checker
- Knowledge Package Builder UI v1
- v1.6 中英文双语文档
- v1.6 验证测试

## 后续问题优先追溯 v1.6

以下问题优先从 v1.6 排查：

- 大文件处理进度问题
- OCR cache / resume 问题
- 多模态资产缺失
- `multimodal_evidence_map.json` 错误
- manifest v2 字段不稳定
- evidence v2 字段不稳定
- contract checker 判定错误

## 边界

v1.6 不做 Evidence Gate、高精度检索索引、Skill 生成、Agent Runtime、Tool Runtime 或外部 connector。
# v1.7 可追溯性

v1.7 新增治理、检索、Evidence Gate 和 LLM 证据校验输出。这些文件都是 opt-in，不改变默认离线知识包契约。
