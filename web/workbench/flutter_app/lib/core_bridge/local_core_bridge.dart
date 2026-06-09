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
    'build_package': <String>['build'],
    'generate_documents': <String>['generate-documents'],
    'create_standalone_agent': <String>['generate-agent'],
    'create_kb_bound_agent': <String>['generate-agent'],
    'configure_agent_hierarchy': <String>['orchestrate-multi-kb'],
    'queue_memory_writeback': <String>['orchestrate-multi-kb'],
    'inspect_storage_status': <String>['workbench-contracts'],
    'workspace_inspect': <String>['workspace-list'],
    'rag_query': <String>['kb-query'],
    'book_to_skill': <String>['book-to-skill'],
    'run_agent': <String>['run-local-agent'],
    'artifact_kb_package_inspect': <String>['check-contract'],
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
