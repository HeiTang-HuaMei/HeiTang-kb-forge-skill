import '../contracts/workbench_contracts.dart';
import '../core_bridge/local_core_bridge.dart';

CoreBridgeRequest? coreRequestForAction({
  required ContractAction action,
  required String coreCli,
  required String workingDirectory,
  required String workspace,
}) {
  final deterministicSmoke = action.status == 'dry_run' && action.commandKind == 'ui_safe_wrapper' && action.desktopBlockedReason == 'mock_only';
  final realLocalWorkflow = action.status == 'ready' && action.commandKind == 'core_cli' && action.desktopEnabled;
  if (!realLocalWorkflow && !deterministicSmoke) {
    return null;
  }
  final arguments = argumentsForCoreCommand(action.command, actionId: action.id, workspace: workspace, workingDirectory: workingDirectory);
  if (arguments == null) {
    return null;
  }

  return CoreBridgeRequest(
    actionId: action.id,
    coreCli: coreCli,
    workingDirectory: workingDirectory,
    arguments: arguments,
  );
}

List<String>? argumentsForCoreCommand(String command, {required String actionId, required String workspace, required String workingDirectory}) {
  final parts = command.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList(growable: false);
  if (parts.isEmpty) {
    return null;
  }
  final values = <String, String>{
    '<workspace>': workspace,
    '<package>': '$workspace/package',
    '<packages>': '$workspace/packages',
    '<input>': '$workspace/input',
    '<source>': '$workspace/source',
    '<output>': '$workspace/workbench_runs/$actionId',
    '<query>': 'Summarize this knowledge package.',
    '<task>': 'Summarize relevant evidence.',
    '<agent>': '$workspace/agents/local-agent',
    '<skill>': '$workspace/skill',
    '<old>': '$workspace/skill-old',
    '<new>': '$workspace/skill-new',
    '<file>': '$workspace/input/corrected.txt',
    '<config>': '$workspace/config.yaml',
    '<repo>': workingDirectory,
    '<name>': 'contract-reviewer',
  };
  final arguments = <String>[];
  for (final part in parts) {
    final replacement = values[part];
    if (replacement != null) {
      arguments.add(replacement);
    } else if (part.startsWith('<') && part.endsWith('>')) {
      return null;
    } else {
      arguments.add(part);
    }
  }
  return arguments;
}
