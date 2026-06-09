import 'dart:convert';

import 'contract_loader.dart';
import 'contract_models.dart';

final WorkbenchContracts sampleWorkbenchContracts = const WorkbenchContractLoader().loadFromBundleJson(
  jsonEncode({
    'source': {
      'copied_from': 'Core workbench-contracts --profile p1',
      'core_commit': 'f9c9718666376adf8540fea075f916b3f22b85e4',
    },
    'manifest': {
      'project_name': 'HeiTang P1 Workbench UI',
      'status': 'blocked',
      'output_files': [
        'workbench_action_contracts.json',
        'workbench_capability_matrix.json',
        'workbench_report_registry.json',
        'workbench_artifact_registry.json',
        'workbench_error_taxonomy.json',
        'workbench_task_schema.json',
        'workbench_template_registry.json',
        'workbench_p1_gate_report.json',
      ],
    },
    'navigation': {
      'views': [
        for (final view in _p1Views) view,
      ],
    },
    'actions': {
      'actions': [
        _action('workspace_inspect', 'workspace', 'Inspect workspace', 'workspace-list', true),
        _action('llm_provider_validate', 'vector_hub_provider_storage', 'Validate LLM provider', 'provider-readiness', false, blocked: 'provider_required'),
        _action('book_to_skill', 'skill_factory', 'Book to Skill', 'book-to-skill', true),
        _action('artifact_kb_package_inspect', 'artifact_management', 'Inspect KB package', 'check-contract', true),
        _action('repair_secret_risk', 'error_repair_center', 'Repair secret risk', '', false, blocked: 'secret_required'),
        _action('p1_workbench_gate', 'reports_audit', 'Read P1 Workbench gate', 'workbench-smoke', false, blocked: 'mock_only', status: 'dry_run'),
        _action('rag_query', 'retrieval_verification', 'Run RAG query', 'kb-query', true),
        _action('run_agent', 'agent_factory_runtime', 'Run Agent', 'run-local-agent', true),
      ],
    },
    'assets': {
      'assets': [
        {'asset_id': 'artifact_workspace_registry_snapshot', 'asset_type': 'workspace', 'deterministic_fixture_path': 'fixtures/p1/workspace.json', 'page_id': 'workspace'},
        {'asset_id': 'artifact_vector_storage_profile', 'asset_type': 'storage', 'deterministic_fixture_path': 'fixtures/p1/vector.json', 'page_id': 'vector_hub_provider_storage'},
        {'asset_id': 'artifact_skill_package', 'asset_type': 'skill_package', 'deterministic_fixture_path': 'fixtures/p1/skill.json', 'page_id': 'skill_factory'},
        {'asset_id': 'artifact_repair_secret_fixture', 'asset_type': 'repair_fixture', 'deterministic_fixture_path': 'fixtures/p1/repair.json', 'page_id': 'error_repair_center'},
      ],
    },
    'reports': {
      'reports': [
        {'report_id': 'report_workspace_health', 'page_id': 'workspace', 'title': 'Workspace health'},
        {'report_id': 'report_provider_readiness', 'page_id': 'vector_hub_provider_storage', 'title': 'Provider readiness'},
        {'report_id': 'report_book_to_skill', 'page_id': 'skill_factory', 'title': 'Book to Skill'},
        {'report_id': 'report_p1_gate_summary', 'page_id': 'reports_audit', 'title': 'P1 gate summary'},
      ],
    },
    'capabilities': {
      'capability_areas': [
        for (final view in _p1Views)
          {'page_id': view['core_page_id'], 'title': view['label'], 'action_ids': <String>[], 'report_ids': <String>[], 'artifact_ids': <String>[]},
      ],
    },
    'task_schema': {
      'statuses': ['queued', 'running', 'succeeded', 'failed', 'blocked', 'cancelled', 'timed_out', 'review_required'],
    },
    'templates': {
      'templates': [
        {'template_id': 'template_product_manager_kb', 'title': 'Product manager KB'},
        {'template_id': 'template_book_publisher_kb', 'title': 'Book publisher KB'},
        {'template_id': 'template_enterprise_policy_kb', 'title': 'Enterprise policy KB'},
        {'template_id': 'template_education_companion', 'title': 'Education companion'},
        {'template_id': 'template_shopping_ops_agent', 'title': 'Shopping ops Agent'},
        {'template_id': 'template_manual_operation_skill', 'title': 'Manual operation Skill'},
      ],
    },
    'gate': {
      'p1_full_operation_gate_status': 'blocked',
      'not_v4_0_workbench_rc': true,
      'ui_full_operation_pending': true,
      'blocker_ids': ['ui_full_operation_pending', 'planned_adapter_backends_not_ready'],
    },
    'status': {
      'status': 'blocked',
      'asset_count': 101,
      'report_count': 109,
      'storage_backend': 'local_workspace',
      'compaction_status': 'not_required',
      'backup_export_status': 'available_local_export',
    },
    'agent': {
      'supported_agent_modes': ['standalone', 'kb_bound'],
      'standalone_agent_schema': {'required': ['agent_manifest.json', 'agent_profile.yaml', 'memory_policy.yaml', 'output_contract.yaml']},
      'kb_bound_agent_schema': {'required': ['agent_profile.yaml', 'retrieval_config.yaml', 'skill_manifest.yaml', 'safety_boundary.md']},
      'validation_states': ['pass', 'warning', 'fail'],
      'error_states': ['missing_required_file', 'invalid_mode', 'untrusted_kb', 'retrieval_binding_missing'],
    },
    'hierarchy': {
      'entities': {
        'child_agents': {'modes': ['standalone', 'kb_bound']},
        'parent_child_binding': {'required_fields': ['parent', 'child', 'child_mode', 'bound_kbs']},
      },
      'trace_files': ['hierarchy_trace.json', 'multi_agent_binding_graph.json'],
    },
    'memory': {
      'policy': {'child_private_memory_default': true, 'workflow_shared_memory': 'explicit_only'},
      'lifecycle_fields': ['session_log', 'summary_memory', 'token_budget_policy'],
      'writeback_actions': ['queue_memory_writeback', 'review_memory_candidate'],
      'status_files': ['memory_isolation_report.json'],
    },
    'storage': {
      'storage_backend': 'local_workspace',
      'supported_storage_backends': ['local_workspace', 'local_db', 'byo_cloud'],
      'storage_areas': {
        'package_storage': {'backend': 'local_workspace'},
        'skill_storage': {'backend': 'local_workspace'},
        'agent_storage': {'backend': 'local_workspace'},
        'memory_storage': {'backend': 'local_workspace'},
        'index_storage': {'backend': 'local_workspace'},
      },
      'sizes': {'package_size_bytes': 1024, 'memory_size_bytes': 256, 'index_size_bytes': 128},
      'cleanup_suggestions': [],
      'compaction_status': 'not_required',
      'backup_export_status': 'available_local_export',
    },
    'errors': {
      'empty_states': [{'id': 'no_assets'}, {'id': 'no_memory_trace'}],
      'error_states': [{'id': 'secret_risk'}, {'id': 'provider_auth_failed'}, {'id': 'contract_drift'}],
      'status_badges': ['ready', 'dry_run', 'blocked', 'planned_adapter', 'ui_pending'],
    },
  }),
);

const _p1Views = [
  {'id': 'dashboard', 'core_page_id': 'dashboard', 'label': 'Dashboard', 'label_zh': '仪表盘', 'asset_types': ['report']},
  {'id': 'workspace', 'core_page_id': 'workspace', 'label': 'Workspace', 'label_zh': '工作空间', 'asset_types': ['workspace']},
  {'id': 'import-parsing', 'core_page_id': 'import_parsing', 'label': 'Import & Parsing', 'label_zh': '导入与解析', 'asset_types': ['knowledge_package']},
  {'id': 'knowledge-package-management', 'core_page_id': 'knowledge_package_management', 'label': 'Knowledge Package Management', 'label_zh': '知识包管理', 'asset_types': ['knowledge_package']},
  {'id': 'retrieval-verification', 'core_page_id': 'retrieval_verification', 'label': 'Retrieval & Verification', 'label_zh': '检索与验证', 'asset_types': ['report']},
  {'id': 'vector-hub-provider-storage', 'core_page_id': 'vector_hub_provider_storage', 'label': 'Vector Hub / Provider / Storage', 'label_zh': '向量索引 / 提供方 / 存储', 'asset_types': ['storage']},
  {'id': 'document-generation', 'core_page_id': 'document_generation', 'label': 'Document Generation', 'label_zh': '文档生成', 'asset_types': ['report']},
  {'id': 'skill-factory', 'core_page_id': 'skill_factory', 'label': 'Skill Factory', 'label_zh': '技能工厂', 'asset_types': ['skill_package']},
  {'id': 'agent-factory-runtime', 'core_page_id': 'agent_factory_runtime', 'label': 'Agent Factory & Runtime', 'label_zh': 'Agent 工厂与运行', 'asset_types': ['agent_package']},
  {'id': 'memory-center', 'core_page_id': 'memory_center', 'label': 'Memory Center', 'label_zh': '记忆中心', 'asset_types': ['report']},
  {'id': 'task-job-center', 'core_page_id': 'task_job_center', 'label': 'Task / Job Center', 'label_zh': '任务 / 作业中心', 'asset_types': ['report']},
  {'id': 'artifact-management', 'core_page_id': 'artifact_management', 'label': 'Artifact Management', 'label_zh': '产物管理', 'asset_types': ['artifact']},
  {'id': 'error-repair-center', 'core_page_id': 'error_repair_center', 'label': 'Error Repair Center', 'label_zh': '错误修复中心', 'asset_types': ['repair']},
  {'id': 'operation-gate', 'core_page_id': 'reports_audit', 'label': 'Operation Gate', 'label_zh': '运行门禁', 'asset_types': ['gate']},
  {'id': 'capability-matrix', 'core_page_id': 'capability_matrix', 'label': 'Capability Matrix', 'label_zh': '能力矩阵', 'asset_types': ['matrix']},
  {'id': 'reports-audit', 'core_page_id': 'reports_audit', 'label': 'Reports & Audit', 'label_zh': '报表与审计', 'asset_types': ['report']},
  {'id': 'governance', 'core_page_id': 'governance', 'label': 'Governance', 'label_zh': '治理与合规', 'asset_types': ['report']},
  {'id': 'template-library', 'core_page_id': 'template_library', 'label': 'Template Library', 'label_zh': '模板库', 'asset_types': ['template']},
];

Map<String, Object?> _action(String id, String pageId, String label, String command, bool enabled, {String? blocked, String status = 'ready'}) {
  return {
    'action_id': id,
    'page_id': pageId,
    'label': label,
    'status': status,
    'command_kind': enabled ? 'core_cli' : 'not_runnable',
    'command': command,
    'requires': ['workspace'],
    'desktop_enabled': enabled,
    'web_enabled': false,
    'desktop_blocked_reason': enabled ? null : blocked,
    'web_blocked_reason': 'web_local_cli_unsupported',
    'blocked_reason': blocked,
    'report_ids': ['report_p1_gate_summary'],
    'artifact_ids': ['artifact_workspace_registry_snapshot'],
    'error_codes': ['secret_risk', 'provider_auth_failed'],
  };
}
