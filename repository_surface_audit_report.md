# Repository Surface Audit Report

- Status: needs_review
- Tests require real LLM/API/network: False

```json
{
  "audit_version": "final-pre-v4.0",
  "status": "needs_review",
  "records": [
    {
      "file": ".env.example",
      "size_bytes": 775,
      "classification": "essential_root_file",
      "status": "pass",
      "reason": "Standard project surface file."
    },
    {
      "file": ".gitignore",
      "size_bytes": 306,
      "classification": "essential_root_file",
      "status": "pass",
      "reason": "Standard project surface file."
    },
    {
      "file": "AGENTS.md",
      "size_bytes": 1384,
      "classification": "essential_root_file",
      "status": "pass",
      "reason": "Standard project surface file."
    },
    {
      "file": "CHANGELOG.md",
      "size_bytes": 26768,
      "classification": "essential_root_file",
      "status": "pass",
      "reason": "Standard project surface file."
    },
    {
      "file": "LICENSE",
      "size_bytes": 1092,
      "classification": "essential_root_file",
      "status": "pass",
      "reason": "Standard project surface file."
    },
    {
      "file": "README.md",
      "size_bytes": 7709,
      "classification": "essential_root_file",
      "status": "pass",
      "reason": "Standard project surface file."
    },
    {
      "file": "README.zh-CN.md",
      "size_bytes": 7498,
      "classification": "essential_root_file",
      "status": "pass",
      "reason": "Standard project surface file."
    },
    {
      "file": "SKILL.md",
      "size_bytes": 2402,
      "classification": "essential_root_file",
      "status": "pass",
      "reason": "Standard project surface file."
    },
    {
      "file": "architecture_gap_audit_report.json",
      "size_bytes": 239814,
      "classification": "historical_machine_readable_evidence",
      "status": "pass",
      "reason": "Kept at root because existing tests and generated report references read it from root."
    },
    {
      "file": "artifact_openability_report.json",
      "size_bytes": 1471,
      "classification": "root_file_needs_review",
      "status": "needs_review",
      "reason": "Root file is not in the essential allowlist."
    },
    {
      "file": "batch_parallel_readiness_report.json",
      "size_bytes": 386,
      "classification": "root_file_needs_review",
      "status": "needs_review",
      "reason": "Root file is not in the essential allowlist."
    },
    {
      "file": "byo_storage_security_readiness_report.json",
      "size_bytes": 372,
      "classification": "root_file_needs_review",
      "status": "needs_review",
      "reason": "Root file is not in the essential allowlist."
    },
    {
      "file": "byo_storage_security_readiness_report.md",
      "size_bytes": 500,
      "classification": "root_file_needs_review",
      "status": "needs_review",
      "reason": "Root file is not in the essential allowlist."
    },
    {
      "file": "capability_gap_map.json",
      "size_bytes": 120681,
      "classification": "historical_machine_readable_evidence",
      "status": "pass",
      "reason": "Kept at root because existing tests and generated report references read it from root."
    },
    {
      "file": "cli_contract_audit_report.json",
      "size_bytes": 977,
      "classification": "root_file_needs_review",
      "status": "needs_review",
      "reason": "Root file is not in the essential allowlist."
    },
    {
      "file": "config_pipeline_audit_report.json",
      "size_bytes": 447,
      "classification": "root_file_needs_review",
      "status": "needs_review",
      "reason": "Root file is not in the essential allowlist."
    },
    {
      "file": "config_secret_handling_report.json",
      "size_bytes": 293,
      "classification": "root_file_needs_review",
      "status": "needs_review",
      "reason": "Root file is not in the essential allowlist."
    },
    {
      "file": "config_secret_handling_report.md",
      "size_bytes": 413,
      "classification": "root_file_needs_review",
      "status": "needs_review",
      "reason": "Root file is not in the essential allowlist."
    },
    {
      "file": "core_ui_contract_drift_final_report.json",
      "size_bytes": 2702,
      "classification": "root_file_needs_review",
      "status": "needs_review",
      "reason": "Root file is not in the essential allowlist."
    },
    {
      "file": "core_ui_contract_drift_final_report.md",
      "size_bytes": 2820,
      "classification": "root_file_needs_review",
      "status": "needs_review",
      "reason": "Root file is not in the essential allowlist."
    },
    {
      "file": "data_classification_report.json",
      "size_bytes": 1154,
      "classification": "root_file_needs_review",
      "status": "needs_review",
      "reason": "Root file is not in the essential allowlist."
    },
    {
      "file": "data_classification_report.md",
      "size_bytes": 1271,
      "classification": "root_file_needs_review",
      "status": "needs_review",
      "reason": "Root file is not in the essential allowlist."
    },
    {
      "file": "docs_truth_audit_report.json",
      "size_bytes": 492,
      "classification": "root_file_needs_review",
      "status": "needs_review",
      "reason": "Root file is not in the essential allowlist."
    },
    {
      "file": "error_stability_report.json",
      "size_bytes": 198,
      "classification": "root_file_needs_review",
      "status": "needs_review",
      "reason": "Root file is not in the essential allowlist."
    },
    {
      "file": "external_fusion_plan.json",
      "size_bytes": 5898,
      "classification": "historical_machine_readable_evidence",
      "status": "pass",
      "reason": "Kept at root because existing tests and generated report references read it from root."
    },
    {
      "file": "external_project_benchmark_report.json",
      "size_bytes": 22571,
      "classification": "historical_machine_readable_evidence",
      "status": "pass",
      "reason": "Kept at root because existing tests and generated report references read it from root."
    },
    {
```
