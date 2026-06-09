import '../contracts/workbench_contracts.dart';

List<ContractAction> coreActionsForPage(String pageId, WorkbenchContracts contracts) {
  final view = _viewForPage(pageId, contracts);
  if (view == null) {
    return const <ContractAction>[];
  }
  return contracts.actions.actions.where((action) => action.pageId == view.corePageId).toList(growable: false);
}

ContractView? _viewForPage(String pageId, WorkbenchContracts contracts) {
  for (final view in contracts.navigation.views) {
    if (view.id == pageId) {
      return view;
    }
  }
  return null;
}
