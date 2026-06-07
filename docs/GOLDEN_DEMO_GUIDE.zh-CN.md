# Golden Demo 指南

Golden Demo acceptance 是 v3.11 的本地真实工作流 smoke。它本身不等于 v4.0 release claim。

## 准备 package

```powershell
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_package
```

## 运行 Golden Demo Acceptance

```powershell
python -m heitang_kb_forge.cli run-golden-demo-acceptance --package .\tmp_package --output .\tmp_golden --no-require-v37 --no-require-v38 --no-require-v39 --no-require-v310
```

准备 final release evidence 时，应在 v3.7-v3.10 artifacts 都存在后移除 `--no-require-*`。

## 预期报告

- `golden_demo_manifest.json`
- `real_acceptance_smoke_result.json`
- `real_acceptance_smoke_report.md`
- `sample_coverage_report.json`
- `artifact_openability_report.json`
- `generated_package_compatibility_report.json`
- `smoke_realism_report.json`
- `v311_acceptance_trace.json`

## Acceptance Standard

如果 artifacts 缺失、为空、placeholder-only 或无法打开，Golden Demo 不能视为已验证。最终 pre-v4 审计必须把无法证明的 promised demo path 标记为 P0。
