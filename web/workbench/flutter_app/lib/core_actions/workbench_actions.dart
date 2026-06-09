import '../contracts/workbench_contracts.dart';
import '../core_bridge/local_core_bridge.dart';

CoreBridgeRequest? coreRequestForAction({
  required ContractAction action,
  required String coreCli,
  required String workingDirectory,
  required String workspace,
}) {
  final arguments = _argumentsForAction(action.id, workspace);
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

List<String>? _argumentsForAction(String actionId, String workspace) {
  final packagePath = '$workspace/package';
  final outputPath = '$workspace/workbench_runs/$actionId';

  return switch (actionId) {
    'workspace_inspect' => <String>[
      'workspace-list',
      '--workspace',
      workspace,
    ],
    'rag_query' => <String>[
      'kb-query',
      '--package',
      packagePath,
      '--query',
      'Summarize this knowledge package.',
      '--output',
      outputPath,
    ],
    'book_to_skill' => <String>[
      'book-to-skill',
      '--input',
      '$workspace/source',
      '--output',
      outputPath,
      '--skill-name',
      'contract-reviewer',
    ],
    'run_agent' => <String>[
      'run-local-agent',
      '--package',
      packagePath,
      '--agent',
      '$workspace/agents/local-agent',
      '--task',
      'Summarize relevant evidence.',
      '--output',
      outputPath,
    ],
    'artifact_kb_package_inspect' => <String>[
      'check-contract',
      '--package',
      packagePath,
      '--output',
      outputPath,
    ],
    _ => null,
  };
}
