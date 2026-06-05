# Prompt Profile Versioning

Prompt profile versioning 会记录本地 prompt profile 文件 hash。

使用：

```powershell
python -m heitang_kb_forge.cli prompt-profile-versioning --workspace .\workspace --output .\prompt_versions
```

输出：

- `prompt_profile_versions.json`
- `prompt_profile_usage_report.md`
- `prompt_profile_hashes.json`
