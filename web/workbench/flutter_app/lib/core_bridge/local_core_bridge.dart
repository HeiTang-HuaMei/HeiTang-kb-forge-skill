import 'dart:async';

import 'core_bridge_contract.dart';
import 'local_core_bridge_runner.dart';

enum CoreBridgeCapability {
  desktopLocalCli,
  webUnsupported,
}

class CoreBridgeCancellationToken {
  final Completer<void> _cancelled = Completer<void>();

  bool get isCancelled => _cancelled.isCompleted;
  Future<void> get whenCancelled => _cancelled.future;

  void cancel() {
    if (!_cancelled.isCompleted) {
      _cancelled.complete();
    }
  }
}

class CoreBridgeRequest {
  const CoreBridgeRequest({
    required this.actionId,
    required this.coreCli,
    required this.workingDirectory,
    required this.arguments,
    this.timeout = const Duration(seconds: 120),
    this.environment = const <String, String>{},
    this.outputPath,
    this.allowedOutputRoot,
    this.retryPolicy = const CoreBridgeRetryPolicy(),
    this.cancellationToken,
    this.attempt = 1,
  });

  final String actionId;
  final String coreCli;
  final String workingDirectory;
  final List<String> arguments;
  final Duration timeout;
  final Map<String, String> environment;
  final String? outputPath;
  final String? allowedOutputRoot;
  final CoreBridgeRetryPolicy retryPolicy;
  final CoreBridgeCancellationToken? cancellationToken;
  final int attempt;

  CoreBridgeRequest withCancellation(CoreBridgeCancellationToken token) {
    return CoreBridgeRequest(
      actionId: actionId,
      coreCli: coreCli,
      workingDirectory: workingDirectory,
      arguments: arguments,
      timeout: timeout,
      environment: environment,
      outputPath: outputPath,
      allowedOutputRoot: allowedOutputRoot,
      retryPolicy: retryPolicy,
      cancellationToken: token,
      attempt: attempt,
    );
  }

  CoreBridgeRequest withAttempt(int nextAttempt) {
    return CoreBridgeRequest(
      actionId: actionId,
      coreCli: coreCli,
      workingDirectory: workingDirectory,
      arguments: arguments,
      timeout: timeout,
      environment: environment,
      outputPath: outputPath,
      allowedOutputRoot: allowedOutputRoot,
      retryPolicy: retryPolicy,
      cancellationToken: cancellationToken,
      attempt: nextAttempt,
    );
  }
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
    required this.cancelled,
    required this.retryable,
    required this.outputPath,
    required this.attempt,
  });

  final String status;
  final String actionId;
  final int? exitCode;
  final String stdout;
  final String stderr;
  final List<String> commandPreview;
  final String errorId;
  final bool timedOut;
  final bool cancelled;
  final bool retryable;
  final String? outputPath;
  final int attempt;

  bool get passed => status == 'pass';

  String get productStatus {
    if (cancelled) {
      return 'cancelled';
    }
    if (status == 'pass') {
      return 'succeeded';
    }
    if (status == 'blocked') {
      return 'blocked';
    }
    if (timedOut || retryable) {
      return 'degraded';
    }
    return 'failed';
  }

  String get userReason {
    if (passed) {
      return 'Action succeeded and evidence can be inspected.';
    }
    if (cancelled) {
      return 'The local action was cancelled before completion.';
    }
    if (errorId == 'core_bridge_web_unsupported') {
      return 'Local Core actions are disabled in Flutter Web preview.';
    }
    if (errorId == 'core_bridge_secret_env_rejected') {
      return 'Provider secrets must stay outside UI bridge requests.';
    }
    if (errorId == 'core_bridge_output_path_rejected') {
      return 'Core bridge output must stay inside the configured workspace.';
    }
    if (timedOut) {
      return 'The local Core action timed out.';
    }
    if (stderr.isNotEmpty) {
      return stderr;
    }
    return errorId.isEmpty ? 'Core action did not complete.' : errorId;
  }

  String get retrySuggestion {
    if (passed) {
      return 'No retry is required.';
    }
    if (status == 'blocked') {
      return 'Resolve the boundary condition before retrying.';
    }
    if (retryable) {
      return 'Use bounded retry from the same allowlisted action.';
    }
    return 'Inspect the sanitized result and start a new action if needed.';
  }
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
    'check_skill_suite_installability': <String>[
      'check-skill-suite-installability'
    ],
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
    'agent_checkpoint_retry': <String>['workbench-action-dry-run'],
    'child_agent_access': <String>['workbench-action-dry-run'],
    'session_memory_inspect': <String>['workbench-action-dry-run'],
    'memory_isolation': <String>['workbench-action-dry-run'],
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
    'artifact_config_profiles_inspect': <String>['workbench-action-dry-run'],
    'artifact_acceptance_proof_inspect': <String>['run-golden-demo-acceptance'],
  };

  final Map<String, List<String>> allowedActions;
  final Future<CoreBridgeProcessResult> Function(CoreBridgeRequest request)
      runner;

  CoreBridgeCapability capability({bool isWeb = false}) => isWeb
      ? CoreBridgeCapability.webUnsupported
      : CoreBridgeCapability.desktopLocalCli;

  List<String> buildCommand(CoreBridgeRequest request, {bool isWeb = false}) {
    _validateRequest(request, isWeb: isWeb);
    return <String>[request.coreCli, ...request.arguments];
  }

  Future<CoreBridgeResult> run(CoreBridgeRequest request,
      {bool isWeb = false}) async {
    List<String>? command;
    try {
      command = buildCommand(request, isWeb: isWeb);
      final processFuture = _runSafely(request).timeout(
        request.timeout,
        onTimeout: () => const CoreBridgeProcessResult(
            exitCode: -1,
            stdout: '',
            stderr: 'Core operation timed out.',
            timedOut: true),
      );
      final token = request.cancellationToken;
      final result = token == null
          ? await processFuture
          : await Future.any([
              processFuture,
              token.whenCancelled.then(
                (_) => const CoreBridgeProcessResult(
                  exitCode: -1,
                  stdout: '',
                  stderr: 'Core operation cancelled.',
                  cancelled: true,
                ),
              ),
            ]);
      final cancelled = result.cancelled || (token?.isCancelled ?? false);
      final passed = result.exitCode == 0 && !result.timedOut && !cancelled;
      final retryable = !passed &&
          !cancelled &&
          request.attempt < request.retryPolicy.maxAttempts &&
          ((result.timedOut && request.retryPolicy.retryOnTimeout) ||
              (!result.timedOut && request.retryPolicy.retryOnProcessFailure));
      return CoreBridgeResult(
        status: cancelled
            ? 'cancelled'
            : passed
                ? 'pass'
                : retryable
                    ? 'retryable'
                    : 'fail',
        actionId: request.actionId,
        exitCode: result.exitCode,
        stdout: redactSecrets(result.stdout),
        stderr: redactSecrets(result.stderr),
        commandPreview: redactCommand(command),
        errorId: cancelled ? 'core_operation_cancelled' : _errorIdFor(result),
        timedOut: result.timedOut,
        cancelled: cancelled,
        retryable: retryable,
        outputPath: request.outputPath,
        attempt: request.attempt,
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
        cancelled: false,
        retryable: false,
        outputPath: request.outputPath,
        attempt: request.attempt,
      );
    } catch (error) {
      return _exceptionResult(
        request: request,
        command: command,
        error: error,
      );
    }
  }

  Future<CoreBridgeProcessResult> _runSafely(CoreBridgeRequest request) async {
    try {
      return await runner(request);
    } catch (error) {
      return CoreBridgeProcessResult(
        exitCode: -1,
        stdout: '',
        stderr: 'Core operation failed to start: $error',
        startFailed: true,
      );
    }
  }

  CoreBridgeResult _exceptionResult({
    required CoreBridgeRequest request,
    required List<String>? command,
    required Object error,
  }) {
    final retryable = request.attempt < request.retryPolicy.maxAttempts &&
        request.retryPolicy.retryOnProcessFailure;
    return CoreBridgeResult(
      status: retryable ? 'retryable' : 'fail',
      actionId: request.actionId,
      exitCode: -1,
      stdout: '',
      stderr: redactSecrets('Core operation failed to start: $error'),
      commandPreview:
          command == null ? const <String>[] : redactCommand(command),
      errorId: 'core_operation_start_failed',
      timedOut: false,
      cancelled: false,
      retryable: retryable,
      outputPath: request.outputPath,
      attempt: request.attempt,
    );
  }

  void _validateRequest(CoreBridgeRequest request, {required bool isWeb}) {
    if (request.attempt < 1 ||
        request.attempt > request.retryPolicy.maxAttempts) {
      throw const CoreBridgeException('core_bridge_attempt_rejected',
          'Core bridge attempt is outside the configured retry policy.');
    }
    if (isWeb) {
      throw const CoreBridgeException('core_bridge_web_unsupported',
          'Local Core CLI operations are available only in desktop/local runtime.');
    }
    if (_containsShellSyntax(request.coreCli) ||
        request.arguments.any(_containsShellSyntax)) {
      throw const CoreBridgeException('core_bridge_shell_syntax_rejected',
          'Shell metacharacters are not allowed in Core operation arguments.');
    }
    if (_isShellExecutable(request.coreCli)) {
      throw const CoreBridgeException('core_bridge_shell_executable_rejected',
          'Shell executables are not allowed as the Core bridge process.');
    }
    final allowedCommands = allowedActions[request.actionId];
    if (allowedCommands == null) {
      throw CoreBridgeException('core_bridge_action_not_allowed',
          'Action ${request.actionId} is not allowlisted for local Core execution.');
    }
    if (request.arguments.isEmpty ||
        !allowedCommands.contains(request.arguments.first)) {
      throw CoreBridgeException('core_bridge_command_not_allowed',
          'Command ${request.arguments.isEmpty ? '<empty>' : request.arguments.first} is not allowed for ${request.actionId}.');
    }
    if (request.environment.keys.any((key) =>
        key.toUpperCase().contains('KEY') ||
        key.toUpperCase().contains('SECRET') ||
        key.toUpperCase().contains('TOKEN'))) {
      throw const CoreBridgeException('core_bridge_secret_env_rejected',
          'Provider secrets must stay outside UI bridge requests.');
    }
    if (request.outputPath != null) {
      final root = request.allowedOutputRoot;
      if (root == null || root.trim().isEmpty) {
        throw const CoreBridgeException('core_bridge_output_root_required',
            'A local output root is required for Core bridge outputs.');
      }
      if (!CoreOutputPathContract(root).contains(request.outputPath!)) {
        throw const CoreBridgeException('core_bridge_output_path_rejected',
            'Core bridge output must stay inside the configured workspace.');
      }
      if (!request.arguments.contains(request.outputPath)) {
        throw const CoreBridgeException('core_bridge_output_argument_mismatch',
            'The declared output path must be present in Core arguments.');
      }
    }
  }

  static bool _containsShellSyntax(String value) {
    const blocked = <String>['&&', '||', ';', '|', '`', r'$(', '>', '<'];
    return blocked.any(value.contains);
  }

  static bool _isShellExecutable(String value) {
    final executable =
        value.trim().replaceAll('\\', '/').split('/').last.toLowerCase();
    return const {
      'cmd',
      'cmd.exe',
      'powershell',
      'powershell.exe',
      'pwsh',
      'pwsh.exe',
      'bash',
      'bash.exe',
      'sh',
      'sh.exe',
      'zsh',
      'zsh.exe',
    }.contains(executable);
  }
}

String _errorIdFor(CoreBridgeProcessResult result) {
  if (result.timedOut) {
    return 'core_operation_timeout';
  }
  if (result.startFailed) {
    return 'core_operation_start_failed';
  }
  if (result.exitCode == 0) {
    return '';
  }
  return 'core_operation_failed';
}

class CoreBridgeProcessResult {
  const CoreBridgeProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.timedOut = false,
    this.cancelled = false,
    this.startFailed = false,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
  final bool timedOut;
  final bool cancelled;
  final bool startFailed;
}

class CoreBridgeException implements Exception {
  const CoreBridgeException(this.errorId, this.message);

  final String errorId;
  final String message;
}

List<String> redactCommand(List<String> command) =>
    command.map((part) => redactSecrets(part)).toList(growable: false);

String redactSecrets(String value) {
  var redacted = value.replaceAll(RegExp(r'sk-[A-Za-z0-9_-]+'), '<redacted>');
  redacted = redacted.replaceAll(
      RegExp(r'(api[_-]?key|token|secret)=\S+', caseSensitive: false),
      '<redacted>');
  return redacted;
}
