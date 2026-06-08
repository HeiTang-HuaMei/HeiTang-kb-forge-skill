import '../contracts/workbench_contracts.dart';

const pageCoreActionIds = <String, List<String>>{
  'kb-query': <String>['kb_query'],
  'agent-skill-management': <String>['run_agent'],
};

List<ContractAction> coreActionsForPage(String pageId, WorkbenchContracts contracts) {
  final actionIds = pageCoreActionIds[pageId] ?? const <String>[];
  return [
    for (final actionId in actionIds)
      for (final action in contracts.actions.actions)
        if (action.id == actionId) action,
  ];
}
