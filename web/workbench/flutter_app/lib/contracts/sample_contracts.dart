import 'dart:convert';

import 'contract_loader.dart';
import 'contract_models.dart';

final WorkbenchContracts sampleWorkbenchContracts = const WorkbenchContractLoader().loadFromBundleJson(
  jsonEncode({
    'manifest': {
      'workbench_contract_version': '3.5.0-alpha.1',
      'project_name': 'HeiTang Workbench',
      'status': 'ready',
      'output_files': [
        'workbench_contract_manifest.json',
        'workbench_navigation_contract.json',
        'workbench_action_contract.json',
        'workbench_asset_contract.json',
        'workbench_status_contract.json',
        'workbench_agent_contract.json',
        'workbench_hierarchy_contract.json',
        'workbench_memory_contract.json',
        'workbench_storage_contract.json',
        'workbench_error_contract.json',
        'workbench_contract_report.md',
        'workbench_contract_trace.json',
      ],
    },
    'navigation': {
      'views': [
        {'id': 'dashboard', 'label': 'Dashboard', 'asset_types': ['report']},
        {'id': 'file-upload', 'label': 'File upload', 'asset_types': ['knowledge_package']},
        {'id': 'job-progress', 'label': 'Job progress', 'asset_types': ['report']},
        {'id': 'knowledge-base-list', 'label': 'Knowledge base list', 'asset_types': ['knowledge_package']},
        {'id': 'knowledge-base-detail', 'label': 'Knowledge base detail', 'asset_types': ['knowledge_package']},
        {'id': 'review-queue', 'label': 'Review queue', 'asset_types': ['report']},
        {'id': 'corrected-text-editor', 'label': 'Corrected text editor', 'asset_types': ['report']},
        {'id': 'kb-query', 'label': 'KB query', 'asset_types': ['report']},
        {'id': 'document-generation', 'label': 'Document generation', 'asset_types': ['report']},
        {'id': 'agent-skill-management', 'label': 'Agent / Skill management', 'asset_types': ['agent_package', 'skill_package']},
        {'id': 'multi-agent-workflow', 'label': 'Agent hierarchy', 'asset_types': ['agent_package', 'report']},
        {'id': 'memory-scope-viewer', 'label': 'Memory policy', 'asset_types': ['report']},
        {'id': 'settings', 'label': 'Storage status', 'asset_types': ['storage', 'report']},
        {'id': 'export-center', 'label': 'Export center', 'asset_types': ['report']},
      ],
    },
    'actions': {
      'actions': [
        {'id': 'build_package', 'label': 'Build Package', 'command': 'build', 'requires': ['input', 'output']},
        {'id': 'kb_query', 'label': 'Query / Verify KB', 'command': 'kb-answer', 'requires': ['package', 'query', 'output']},
        {'id': 'generate_documents', 'label': 'Generate Documents', 'command': 'generate-documents', 'requires': ['package', 'output']},
        {'id': 'create_standalone_agent', 'label': 'Create Standalone Agent', 'command': 'generate-agent --mode standalone', 'requires': ['output']},
        {'id': 'create_kb_bound_agent', 'label': 'Create KB-bound Agent', 'command': 'generate-agent --mode kb_bound', 'requires': ['package', 'skill', 'output']},
        {'id': 'configure_agent_hierarchy', 'label': 'Configure Agent Hierarchy', 'command': 'orchestrate-multi-kb --mother-agent', 'requires': ['mother_agent', 'child_agents']},
        {'id': 'queue_memory_writeback', 'label': 'Queue Memory Writeback', 'command': 'orchestrate-multi-kb --parent-writeback', 'requires': ['child_agent', 'candidate']},
        {'id': 'run_agent', 'label': 'Run Local Agent', 'command': 'run-local-agent', 'requires': ['package', 'agent', 'task', 'output']},
        {'id': 'inspect_storage_status', 'label': 'Inspect Storage Status', 'command': 'workbench-contracts', 'requires': ['core_output']},
      ],
    },
    'assets': {
      'assets': [
        {'asset_id': 'manifest_json', 'asset_type': 'knowledge_package', 'path': 'manifest.json'},
        {'asset_id': 'generated_file_report_json', 'asset_type': 'report', 'path': 'generated_file_report.json'},
        {'asset_id': 'agent_profile_yaml', 'asset_type': 'agent_package', 'path': 'agent_package/agent_profile.yaml'},
        {'asset_id': 'skill_md', 'asset_type': 'skill_package', 'path': 'skill_package/SKILL.md'},
        {'asset_id': 'workbench_storage_contract_json', 'asset_type': 'storage', 'path': 'workbench_storage_contract.json'},
      ],
    },
    'status': {
      'status': 'ready',
      'asset_count': 5,
      'report_count': 2,
      'storage_backend': 'local_workspace',
      'compaction_status': 'not_required',
      'backup_export_status': 'available_local_export',
    },
    'agent': {
      'supported_agent_modes': ['standalone', 'kb_bound'],
      'standalone_agent_schema': {
        'required': ['agent_manifest.json', 'agent_profile.yaml', 'memory_policy.yaml', 'output_contract.yaml'],
      },
      'kb_bound_agent_schema': {
        'required': ['agent_profile.yaml', 'retrieval_config.yaml', 'skill_manifest.yaml', 'safety_boundary.md'],
      },
      'validation_states': ['pass', 'warning', 'fail'],
      'error_states': ['missing_required_file', 'invalid_mode', 'untrusted_kb', 'retrieval_binding_missing'],
    },
    'hierarchy': {
      'entities': {
        'mother_agent': {'role': 'parent_router', 'kb_binding': 'none_required'},
        'child_agents': {'role': 'task_executor', 'modes': ['standalone', 'kb_bound']},
        'parent_child_binding': {'required_fields': ['parent', 'child', 'child_mode', 'bound_kbs']},
      },
      'trace_files': ['hierarchy_trace.json', 'multi_agent_binding_graph.json'],
    },
    'memory': {
      'policy': {
        'child_private_memory_default': true,
        'workflow_shared_memory': 'explicit_only',
        'selective_parent_memory_writeback': 'candidate_queue_only',
      },
      'lifecycle_fields': ['session_log', 'short_term_memory', 'summary_memory', 'long_term_memory', 'memory_candidates', 'memory_index', 'retention_policy', 'compaction_policy', 'token_budget_policy'],
      'writeback_actions': ['queue_memory_writeback', 'review_memory_candidate', 'promote_memory_candidate'],
      'status_files': ['memory_candidate_queue.jsonl', 'memory_writeback_report.json', 'memory_isolation_report.json', 'memory_lifecycle_report.json'],
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
        'generated_document_storage': {'backend': 'local_workspace'},
      },
      'sizes': {'package_size_bytes': 1024, 'memory_size_bytes': 256, 'index_size_bytes': 128},
      'cleanup_suggestions': [],
      'compaction_status': 'not_required',
      'backup_export_status': 'available_local_export',
    },
    'errors': {
      'empty_states': [
        {'id': 'no_assets', 'label': 'No assets registered'},
        {'id': 'no_memory_trace', 'label': 'No memory trace available'},
      ],
      'error_states': [
        {'id': 'contract_file_missing', 'severity': 'warning'},
        {'id': 'contract_parse_error', 'severity': 'error'},
      ],
      'status_badges': ['ready', 'empty', 'warning', 'error', 'reserved'],
    },
  }),
);
