# Provider Readiness

Provider readiness is an offline check for configured provider metadata.

Use:

```powershell
python -m heitang_kb_forge.cli provider-readiness --workspace .\workspace --output .\provider_readiness
```

The default provider is mock or disabled. Real API keys are not stored and no network checks are performed.
