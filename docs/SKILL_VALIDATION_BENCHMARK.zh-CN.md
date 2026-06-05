# Skill Validation 与 Benchmark

v1.8 新增本地 Skill 校验与 benchmark cases。

```powershell
python -m heitang_kb_forge.cli validate-skill --skill .\tmp_v18_skill --package .\tmp_v18_package --output .\tmp_v18_skill_validation
```

输出：

* skill_validation_result.json
* skill_validation_report.md
* skill_benchmark_cases.jsonl

校验维度包括证据充分性、边界控制、拒答规则、citation policy、风格一致性、eval 覆盖和 release_ready。
