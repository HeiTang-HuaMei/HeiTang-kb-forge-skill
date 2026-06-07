# v3.12 产品硬化与本地发布就绪

v3.12 收束 v4 规划前的本地产品硬化路径。它不是薄报告层，而是对诊断、命令、生成包、workspace 结构、Golden Demo 证据、隐私边界、合约漂移、安装就绪和 v4 RC gate 进行确定性的本地门禁检查。

## 范围

- doctor / diagnostics
- command audit
- package audit
- workspace audit
- Golden Demo verification
- 稳定的用户可见错误 taxonomy
- troubleshooting report
- optional dependency diagnostics
- no-secret / no-temp check
- local privacy boundary report
- contract drift check / 合约漂移检查
- installer readiness assessment
- local release readiness report
- v4 RC gate report
- `v312_external_absorption_map.json`

## CLI

```bash
heitang-kb-forge product-hardening --workspace . --package ./package --output ./hardening
```

`--allow-llm` 和 `--allow-network` 是保留开关，在 v3.12 必须保持 false。测试不需要真实 LLM、API 或网络访问。

## 配置

```yaml
product_hardening:
  enabled: true
  require_v37: true
  require_v38: true
  require_v39: true
  require_v310: true
  require_v311: true
  allow_llm: false
  allow_network: false
```

默认 build 行为不变。只有显式启用该配置块时，才运行产品硬化门禁。

## 输出

- `product_hardening_manifest.json`
- `doctor_diagnostics_report.json`
- `command_audit_report.json`
- `package_audit_report.json`
- `workspace_audit_report.json`
- `golden_demo_verification_report.json`
- `stable_error_taxonomy.json`
- `troubleshooting_report.json`
- `optional_dependency_diagnostics.json`
- `no_secret_no_temp_report.json`
- `local_privacy_boundary_report.json`
- `contract_drift_report.json`
- `installer_readiness_report.json`
- `local_release_readiness_result.json`
- `v4_rc_gate_report.json`
- `v312_external_absorption_map.json`

## 边界

v3.12 不实现新的 RAG 能力、Agent Runtime、存储后端、SaaS、多用户、云同步或 UI。它只验证本地 Core 发布边界，让 v4.0 规划可以基于明确证据继续。
