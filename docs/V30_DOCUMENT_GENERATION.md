# v3.0 Document Generation Loop

v3.0.0-alpha.1 adds an opt-in local Document Generation Loop for producing grounded Markdown, DOCX, PDF, and PPTX exports from an existing knowledge package.

## Scope

- Generate document exports from the build output package.
- Support Markdown, DOCX, PDF, and PPTX formats.
- Keep strict grounded generation as the default policy.
- Block strict generation from draft or untrusted parser output.
- Allow explicitly reviewed creative grounded generation with review markers.
- Write generation, quality, file, and export validation reports.
- Keep default build, run, and pipeline behavior unchanged unless document generation is enabled.

## Commands

```powershell
python -m heitang_kb_forge.cli generate-md --package .\tmp_quickstart_output --output .\tmp_docs
python -m heitang_kb_forge.cli generate-docx --package .\tmp_quickstart_output --output .\tmp_docs
python -m heitang_kb_forge.cli generate-pdf --package .\tmp_quickstart_output --output .\tmp_docs
python -m heitang_kb_forge.cli generate-pptx --package .\tmp_quickstart_output --output .\tmp_docs
python -m heitang_kb_forge.cli generate-documents --package .\tmp_quickstart_output --output .\tmp_docs --formats md,docx,pdf,pptx
```

Build can also emit document outputs when explicitly enabled:

```powershell
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_build --document-generation --document-formats md,docx,pdf,pptx
```

Config-driven runs support:

```yaml
document_generation:
  enabled: true
  formats: [md, docx, pdf, pptx]
  template: default_report
  grounding_policy: strict_grounded
```

## Output Files

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

## Boundaries

v3.0 document generation is local and opt-in. It does not call LLM APIs, embedding APIs, vector databases, external Agent runtimes, Feishu, mobile clients, installers, iOS surfaces, SaaS permissions, or team collaboration services.
