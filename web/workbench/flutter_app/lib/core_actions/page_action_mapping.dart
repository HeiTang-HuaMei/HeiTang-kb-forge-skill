import '../contracts/workbench_contracts.dart';

const pageCoreActionIds = <String, List<String>>{
  'workspace': <String>['workspace_inspect'],
  'retrieval-verification': <String>['rag_query'],
  'skill-factory': <String>['book_to_skill'],
  'agent-factory-runtime': <String>['run_agent'],
  'artifact-management': <String>['artifact_kb_package_inspect'],
  'vector-hub-provider-storage': <String>['llm_provider_validate'],
  'error-repair-center': <String>['repair_secret_risk'],
};

List<ContractAction> coreActionsForPage(String pageId, WorkbenchContracts contracts) {
  final actionIds = pageCoreActionIds[pageId] ?? const <String>[];
  return [
    for (final actionId in actionIds)
      for (final action in contracts.actions.actions)
        if (action.id == actionId) action,
  ];
}
