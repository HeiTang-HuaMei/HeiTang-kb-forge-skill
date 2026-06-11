import 'dart:async';

import 'local_core_bridge_runner.dart';

enum CoreBridgeCapability {
  desktopLocalCli,
  webUnsupported,
}

class CoreBridgeRequest {
  const CoreBridgeRequest({
    required this.actionId,
    required this.coreCli,
    required this.workingDirectory,
    required this.arguments,
    this.timeout = const Duration(seconds: 120),
    this.environment = const <String, String>{},
  });

  final String actionId;
  final String coreCli;
  final String workingDirectory;
  final List<String> arguments;
  final Duration timeout;
  final Map<String, String> environment;
}

class CoreBridgeResult {
  const CoreBridgeResult({
    required this.status,
    required this.actionId,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.commandPreview,
    required this.errorId,
    required this.timedOut,
  });

  final String status;
  final String actionId;
  final int? exitCode;
  final String stdout;
  final String stderr;
  final List<String> commandPreview;
  final String errorId;
  final bool timedOut;

  bool get passed => status == 'pass';
}

class LocalCoreBridge {
  const LocalCoreBridge({
    this.allowedActions = defaultAllowedActions,
    this.runner = runCoreBridgeProcess,
  });

  static const defaultAllowedActions = <String, List<String>>{
    'inspect_dashboard_status': <String>['workbench-smoke'],
    'inspect_recent_tasks': <String>['workbench-smoke'],
    'inspect_next_actions': <String>['workbench-action-dry-run'],
    'workspace_inspect': <String>['workspace-list'],
    'workspace_paths_inspect': <String>['workbench-action-dry-run'],
    'workspace_health': <String>['workspace-health'],
    'workspace_storage_usage': <String>['report-storage'],
    'workspace_cleanup_plan': <String>['plan-cleanup'],
    'input_file_folder_glob': <String>['workbench-action-dry-run'],
    'source_validate': <String>['check-contract'],
    'source_inventory': <String>['workbench-action-dry-run'],
    'format_support_matrix': <String>['parser-backend-list'],
    'parser_preflight': <String>['parse-quality-gate'],
    'ocr_required_detection': <String>['full-ocr-acceptance'],
    'parse_repair_suggest': <String>['parse-reimport-corrected-text'],
    'pdf_token_reduction': <String>['report-pdf-token-reduction'],
    'package_build': <String>['build'],
    'package_batch': <String>['batch-run'],
    'package_pipeline': <String>['pipeline'],
    'package_validation': <String>['check-contract'],
    'package_diff': <String>['lifecycle-check'],
    'incremental_update': <String>['refresh-check'],
    'stale_index_detect': <String>['kb-index'],
    'package_export': <String>['export-platform'],
    'retrieval_purpose_switch': <String>['workbench-action-dry-run'],
    'query_rewrite': <String>['rewrite-query'],
    'retrieval_planning': <String>['plan-retrieval'],
    'rag_query': <String>['kb-query'],
    'hybrid_retrieval': <String>['eval-retrieval'],
    'rerank': <String>['rerank-results'],
    'evidence_selection': <String>['select-evidence'],
    'claim_verification': <String>['verify-claims'],
    'contradiction_detection': <String>['check-knowledge-accuracy'],
    'freshness_check': <String>['check-knowledge-accuracy'],
    'generate_markdown': <String>['generate-md'],
    'generate_docx': <String>['generate-docx'],
    'generate_pdf': <String>['generate-pdf'],
    'generate_pptx': <String>['generate-pptx'],
    'generate_manual_user_guide': <String>['generate-documents'],
    'evidence_appendix': <String>['select-evidence'],
    'openability_check': <String>['run-golden-demo-acceptance'],
    'book_to_skill': <String>['book-to-skill'],
    'extract_methodology': <String>['extract-methodology'],
    'plan_skill_suite': <String>['plan-skill-suite'],
    'build_skill_suite': <String>['build-skill-suite'],
    'validate_skill_suite': <String>['validate-skill-suite'],
    'diff_skill_suite': <String>['diff-skill-suite'],
    'check_skill_suite_installability': <String>['check-skill-suite-installability'],
    'skill_suite_governance_report': <String>['skill-suite-governance-report'],
    'export_skill_pack': <String>['export-skill-pack'],
    'template_skill_generation': <String>['workbench-action-dry-run'],
    'package_to_skill': <String>['generate-skill'],
    'skill_manifest_validate': <String>['validate-skill-package'],
    'skill_diff': <String>['diff-skill-package'],
    'skill_governance_report': <String>['skill-governance-report'],
    'skill_runtime_profile': <String>['workbench-action-dry-run'],
    'agent_profile_inspect': <String>['workbench-action-dry-run'],
    'standalone_agent_generation': <String>['generate-agent'],
    'kb_bound_agent_generation': <String>['generate-agent'],
    'run_agent': <String>['run-local-agent'],
    'agent_checkpoint_retry': <String>['workbench-action-dry-run'],
    'child_agent_access': <String>['workbench-action-dry-run'],
    'multi_agent_orchestration': <String>['orchestrate-multi-kb'],
    'session_memory_inspect': <String>['workbench-action-dry-run'],
    'summary_memory_lifecycle': <String>['plan-memory-lifecycle'],
    'memory_isolation': <String>['workbench-action-dry-run'],
    'memory_compression': <String>['estimate-token-budget'],
    'memory_cleanup': <String>['plan-memory-lifecycle'],
    'no_all_history_injection': <String>['workbench-action-dry-run'],
    'do_not_ingest_policy': <String>['workbench-action-dry-run'],
    'document_owner_inspect': <String>['govern'],
    'stale_document_detect': <String>['govern'],
    'conflict_document_detect': <String>['govern'],
    'no_answer_sop': <String>['workbench-action-dry-run'],
    'template_product_manager_kb': <String>['workbench-action-dry-run'],
    'template_book_publisher_kb': <String>['workbench-action-dry-run'],
    'template_enterprise_policy_kb': <String>['workbench-action-dry-run'],
    'template_education_companion': <String>['workbench-action-dry-run'],
    'template_shopping_ops_agent': <String>['workbench-action-dry-run'],
    'template_manual_operation_skill': <String>['workbench-action-dry-run'],
    'report_registry_inspect': <String>['workbench-action-dry-run'],
    'artifact_registry_inspect': <String>['workbench-action-dry-run'],
    'p1_workbench_gate': <String>['workbench-smoke'],
    'blocker_tracker': <String>['workbench-action-dry-run'],
    'repair_file_path_error': <String>['workbench-action-dry-run'],
    'repair_parse_failed': <String>['workbench-action-dry-run'],
    'repair_contract_drift': <String>['workbench-smoke'],
    'task_queue_inspect': <String>['workbench-action-dry-run'],
    'task_retry': <String>['workbench-action-dry-run'],
    'task_output_inspect': <String>['workbench-action-dry-run'],
    'product_hardening': <String>['product-hardening'],
    'final_gate': <String>['final-pre-v4-audit'],
    'artifact_kb_package_inspect': <String>['check-contract'],
    'artifact_chunks_inspect': <String>['workbench-action-dry-run'],
    'artifact_vector_index_inspect': <String>['kb-index'],
    'artifact_generated_docs_inspect': <String>['generate-documents'],
    'artifact_skill_package_inspect': <String>['validate-skill-package'],
    'artifact_agent_package_inspect': <String>['generate-agent'],
    'artifact_runtime_trace_inspect': <String>['run-local-agent'],
    'artifact_memory_files_inspect': <String>['workbench-action-dry-run'],
    'artifact_config_profiles_inspect': <String>['workbench-action-dry-run'],
    'artifact_acceptance_proof_inspect': <String>['run-golden-demo-acceptance'],
  };

  final Map<String, List<String>> allowedActions;
  final Future<CoreBridgeProcessResult> Function(CoreBridgeRequest request) runner;

  CoreBridgeCapability capability({bool isWeb = false}) => isWeb ? CoreBridgeCapability.webUnsupported : CoreBridgeCapability.desktopLocalCli;

  List<String> buildCommand(CoreBridgeRequest request, {bool isWeb = false}) {
    _validateRequest(request, isWeb: isWeb);
    return <String>[request.coreCli, ...request.arguments];
  }

  Future<CoreBridgeResult> run(CoreBridgeRequest request, {bool isWeb = false}) async {
    try {
      final command = buildCommand(request, isWeb: isWeb);
      final result = await runner(request).timeout(
        request.timeout,
        onTimeout: () => const CoreBridgeProcessResult(exitCode: -1, stdout: '', stderr: 'Core operation timed out.', timedOut: true),
      );
      return CoreBridgeResult(
        status: result.exitCode == 0 && !result.timedOut ? 'pass' : 'fail',
        actionId: request.actionId,
        exitCode: result.exitCode,
        stdout: redactSecrets(result.stdout),
        stderr: redactSecrets(result.stderr),
        commandPreview: redactCommand(command),
        errorId: result.timedOut ? 'core_operation_timeout' : result.exitCode == 0 ? '' : 'core_operation_failed',
        timedOut: result.timedOut,
      );
    } on CoreBridgeException catch (error) {
      return CoreBridgeResult(
        status: 'blocked',
        actionId: request.actionId,
        exitCode: null,
        stdout: '',
        stderr: error.message,
        commandPreview: const <String>[],
        errorId: error.errorId,
        timedOut: false,
      );
    }
  }

  void _validateRequest(CoreBridgeRequest request, {required bool isWeb}) {
    if (isWeb) {
      throw const CoreBridgeException('core_bridge_web_unsupported', 'Local Core CLI operations are available only in desktop/local runtime.');
    }
    if (_containsShellSyntax(request.coreCli) || request.arguments.any(_containsShellSyntax)) {
      throw const CoreBridgeException('core_bridge_shell_syntax_rejected', 'Shell metacharacters are not allowed in Core operation arguments.');
    }
    final allowedCommands = allowedActions[request.actionId];
    if (allowedCommands == null) {
      throw CoreBridgeException('core_bridge_action_not_allowed', 'Action ${request.actionId} is not allowlisted for local Core execution.');
    }
    if (request.arguments.isEmpty || !allowedCommands.contains(request.arguments.first)) {
      throw CoreBridgeException('core_bridge_command_not_allowed', 'Command ${request.arguments.isEmpty ? '<empty>' : request.arguments.first} is not allowed for ${request.actionId}.');
    }
    if (request.environment.keys.any((key) => key.toUpperCase().contains('KEY') || key.toUpperCase().contains('SECRET') || key.toUpperCase().contains('TOKEN'))) {
      throw const CoreBridgeException('core_bridge_secret_env_rejected', 'Provider secrets must stay outside UI bridge requests.');
    }
  }

  static bool _containsShellSyntax(String value) {
    const blocked = <String>['&&', '||', ';', '|', '`', r'$(', '>', '<'];
    return blocked.any(value.contains);
  }
}

class CoreBridgeProcessResult {
  const CoreBridgeProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.timedOut = false,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
  final bool timedOut;
}

class CoreBridgeException implements Exception {
  const CoreBridgeException(this.errorId, this.message);

  final String errorId;
  final String message;
}

List<String> redactCommand(List<String> command) => command.map((part) => redactSecrets(part)).toList(growable: false);

String redactSecrets(String value) {
  var redacted = value.replaceAll(RegExp(r'sk-[A-Za-z0-9_-]+'), '<redacted>');
  redacted = redacted.replaceAll(RegExp(r'(api[_-]?key|token|secret)=\S+', caseSensitive: false), '<redacted>');
  return redacted;
}
