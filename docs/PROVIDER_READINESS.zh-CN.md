# Provider Readiness

Provider readiness 是对 provider 元数据的离线检查。

使用：

```powershell
python -m heitang_kb_forge.cli provider-readiness --workspace .\workspace --output .\provider_readiness
```

默认 provider 是 mock 或 disabled。不保存真实 API key，也不进行联网检查。
