import '../contracts/workbench_contracts.dart';

List<ContractAction> coreActionsForPage(String pageId, WorkbenchContracts contracts) {
  final view = _viewForPage(pageId, contracts);
  if (view == null) {
    return const <ContractAction>[];
  }
  final actions = contracts.actions.actions.where((action) => action.pageId == view.corePageId).toList();
  if (pageId == 'skill-factory') {
    final existingIds = actions.map((action) => action.id).toSet();
    actions.addAll(_skillSuiteActions.where((action) => !existingIds.contains(action.id)));
  }
  return actions;
}

ContractView? _viewForPage(String pageId, WorkbenchContracts contracts) {
  for (final view in contracts.navigation.views) {
    if (view.id == pageId) {
      return view;
    }
  }
  return null;
}

const _skillSuiteActions = <ContractAction>[
  ContractAction(
    id: 'plan_skill_suite',
    label: 'Plan Skill Suite',
    command: 'plan-skill-suite --methodology <methodology> --out <output>',
    requires: <String>['workspace', 'methodology_map'],
    pageId: 'skill_factory',
    status: 'ready',
    commandKind: 'core_cli',
    blockedReason: '',
    desktopEnabled: true,
    webEnabled: false,
    desktopBlockedReason: '',
    webBlockedReason: 'web_local_cli_unsupported',
    reportIds: <String>['candidate_planning_report'],
    artifactIds: <String>['skill_plan'],
    errorCodes: <String>['invalid_methodology_contract'],
  ),
  ContractAction(
    id: 'build_skill_suite',
    label: 'Build Skill Suite',
    command: 'build-skill-suite --plan <plan> --out <output>',
    requires: <String>['workspace', 'skill_plan'],
    pageId: 'skill_factory',
    status: 'ready',
    commandKind: 'core_cli',
    blockedReason: '',
    desktopEnabled: true,
    webEnabled: false,
    desktopBlockedReason: '',
    webBlockedReason: 'web_local_cli_unsupported',
    reportIds: <String>['hierarchy_analysis'],
    artifactIds: <String>['skill_suite'],
    errorCodes: <String>['invalid_skill_plan'],
  ),
  ContractAction(
    id: 'validate_skill_suite',
    label: 'Validate Skill Suite',
    command: 'validate-skill-suite --suite <suite> --output <output>',
    requires: <String>['workspace', 'skill_suite'],
    pageId: 'skill_factory',
    status: 'ready',
    commandKind: 'core_cli',
    blockedReason: '',
    desktopEnabled: true,
    webEnabled: false,
    desktopBlockedReason: '',
    webBlockedReason: 'web_local_cli_unsupported',
    reportIds: <String>['suite_validation_report'],
    artifactIds: <String>['skill_suite'],
    errorCodes: <String>['suite_validation_failed'],
  ),
  ContractAction(
    id: 'diff_skill_suite',
    label: 'Diff Skill Suite',
    command: 'diff-skill-suite --before <before> --after <after> --output <output>',
    requires: <String>['workspace', 'suite_baseline', 'skill_suite'],
    pageId: 'skill_factory',
    status: 'ready',
    commandKind: 'core_cli',
    blockedReason: '',
    desktopEnabled: true,
    webEnabled: false,
    desktopBlockedReason: '',
    webBlockedReason: 'web_local_cli_unsupported',
    reportIds: <String>['suite_diff_report'],
    artifactIds: <String>['skill_suite'],
    errorCodes: <String>['suite_diff_failed'],
  ),
  ContractAction(
    id: 'check_skill_suite_installability',
    label: 'Check Skill Suite Installability',
    command: 'check-skill-suite-installability --suite <suite> --output <output>',
    requires: <String>['workspace', 'skill_suite'],
    pageId: 'skill_factory',
    status: 'ready',
    commandKind: 'core_cli',
    blockedReason: '',
    desktopEnabled: true,
    webEnabled: false,
    desktopBlockedReason: '',
    webBlockedReason: 'web_local_cli_unsupported',
    reportIds: <String>['suite_installability_report'],
    artifactIds: <String>['skill_suite'],
    errorCodes: <String>['suite_installability_failed'],
  ),
  ContractAction(
    id: 'skill_suite_governance_report',
    label: 'Skill Suite Governance Report',
    command: 'skill-suite-governance-report --suite <suite> --old-suite <before> --output <output>',
    requires: <String>['workspace', 'suite_baseline', 'skill_suite'],
    pageId: 'skill_factory',
    status: 'ready',
    commandKind: 'core_cli',
    blockedReason: '',
    desktopEnabled: true,
    webEnabled: false,
    desktopBlockedReason: '',
    webBlockedReason: 'web_local_cli_unsupported',
    reportIds: <String>['suite_governance_report'],
    artifactIds: <String>['skill_suite'],
    errorCodes: <String>['suite_governance_failed'],
  ),
  ContractAction(
    id: 'export_skill_pack',
    label: 'Export Skill Pack',
    command: 'export-skill-pack --suite <suite> --out <output>',
    requires: <String>['workspace', 'skill_suite'],
    pageId: 'skill_factory',
    status: 'ready',
    commandKind: 'core_cli',
    blockedReason: '',
    desktopEnabled: true,
    webEnabled: false,
    desktopBlockedReason: '',
    webBlockedReason: 'web_local_cli_unsupported',
    reportIds: <String>['skill_pack_manifest'],
    artifactIds: <String>['skill_pack'],
    errorCodes: <String>['skill_pack_export_failed'],
  ),
];
