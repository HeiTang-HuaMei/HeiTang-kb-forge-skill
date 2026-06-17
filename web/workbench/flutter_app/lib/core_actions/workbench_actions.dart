import '../contracts/workbench_contracts.dart';
import '../core_bridge/core_bridge_contract.dart';
import '../core_bridge/local_core_bridge.dart';

CoreBridgeRequest? coreRequestForAction({
  required ContractAction action,
  required String coreCli,
  required String workingDirectory,
  required String workspace,
  Map<String, String> placeholderOverrides = const <String, String>{},
}) {
  final deterministicSmoke = action.status == 'dry_run' &&
      action.commandKind == 'ui_safe_wrapper' &&
      action.desktopBlockedReason == 'mock_only';
  final realLocalWorkflow = action.status == 'ready' &&
      action.commandKind == 'core_cli' &&
      action.desktopEnabled;
  if (!realLocalWorkflow && !deterministicSmoke) {
    return null;
  }
  final outputContract = CoreOutputPathContract(workspace);
  final outputPath = outputContract.forAction(action.id);
  final arguments = argumentsForCoreCommand(
    action.command,
    actionId: action.id,
    workspace: workspace,
    workingDirectory: workingDirectory,
    outputPath: outputPath,
    placeholderOverrides: placeholderOverrides,
  );
  if (arguments == null) {
    return null;
  }

  return CoreBridgeRequest(
    actionId: action.id,
    coreCli: coreCli,
    workingDirectory: workingDirectory,
    arguments: arguments,
    outputPath: arguments.contains(outputPath) ? outputPath : null,
    allowedOutputRoot: workspace,
  );
}

List<String>? argumentsForCoreCommand(
  String command, {
  required String actionId,
  required String workspace,
  required String workingDirectory,
  String? outputPath,
  Map<String, String> placeholderOverrides = const <String, String>{},
}) {
  final parts = command
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return null;
  }
  final values = <String, String>{
    '<workspace>': workspace,
    '<package>': '$workspace/package',
    '<packages>': '$workspace/packages',
    '<methodology>': '$workspace/methodology',
    '<plan>': '$workspace/skill_plan',
    '<suite>': '$workspace/skill_suite',
    '<before>': '$workspace/skill_suite_before',
    '<after>': '$workspace/skill_suite',
    '<input>': '$workspace/input',
    '<source>': '$workspace/source',
    '<output>': outputPath ?? '$workspace/workbench_runs/$actionId',
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
  }..addAll(placeholderOverrides);
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
