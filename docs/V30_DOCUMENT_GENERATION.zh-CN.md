# v3.0 Document Generation Loop

v3.0.0-alpha.1 新增可选本地 Document Generation Loop，用已有知识包生成有证据边界的 Markdown、DOCX、PDF 和 PPTX 文档导出。

## 范围

- 从 build 输出知识包生成文档导出。
- 支持 Markdown、DOCX、PDF 和 PPTX 格式。
- 默认使用 strict grounded 生成策略。
- strict 模式会阻止 draft 或 untrusted parser 输出。
- 可显式使用 creative grounded 模式，并写出 review 标记。
- 写出 generation、quality、file 和 export validation 报告。
- 未启用 document generation 时，默认 build、run 和 pipeline 行为不变。

## 命令

```powershell
python -m heitang_kb_forge.cli generate-md --package .\tmp_quickstart_output --output .\tmp_docs
python -m heitang_kb_forge.cli generate-docx --package .\tmp_quickstart_output --output .\tmp_docs
python -m heitang_kb_forge.cli generate-pdf --package .\tmp_quickstart_output --output .\tmp_docs
python -m heitang_kb_forge.cli generate-pptx --package .\tmp_quickstart_output --output .\tmp_docs
python -m heitang_kb_forge.cli generate-documents --package .\tmp_quickstart_output --output .\tmp_docs --formats md,docx,pdf,pptx
```

显式开启后，build 也可以写出文档输出：

```powershell
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_build --document-generation --document-formats md,docx,pdf,pptx
```

配置驱动运行支持：

```yaml
document_generation:
  enabled: true
  formats: [md, docx, pdf, pptx]
  template: default_report
  grounding_policy: strict_grounded
```

## 输出文件

- `generated.md`
- `generated.docx`
- `generated.pdf`
- `generated.pptx`
- `generated_file_report.json`
- `generated_file_report.md`
- `document_generation_trace.json`
- `document_quality_report.json`
- `export_validation_report.json`
- `export_validation_report.md`

## 边界

v3.0 document generation 是本地、可选能力。它不调用 LLM API，不调用 embedding API，不写入向量库，不运行外部 Agent runtime，也不涉及飞书、移动端、安装器、iOS、SaaS 权限或团队协作服务。
