# Package Lineage

v2.3 adds package version graph outputs for long-term package governance.

Outputs:

- `package_version_graph.json`
- `package_lineage_report.md`
- `package_dependency_report.md`

Use:

```powershell
python -m heitang_kb_forge.cli package-lineage --workspace .\workspace --output .\lineage_output
```

The graph is a local traceability artifact. It does not publish or upload packages.
