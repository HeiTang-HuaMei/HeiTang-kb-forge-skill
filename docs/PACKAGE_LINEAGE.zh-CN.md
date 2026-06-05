# 知识包版本关系

v2.3 增加知识包版本图，用于长期治理和追溯。

输出：

- `package_version_graph.json`
- `package_lineage_report.md`
- `package_dependency_report.md`

使用：

```powershell
python -m heitang_kb_forge.cli package-lineage --workspace .\workspace --output .\lineage_output
```

版本图只是本地追溯产物，不做发布或上传。
