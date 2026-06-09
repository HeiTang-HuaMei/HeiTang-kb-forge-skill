import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class P1WorkflowEvidence {
  const P1WorkflowEvidence({
    required this.coreCommit,
    required this.status,
    required this.fullGateStatus,
    required this.readyForV4Rc,
    required this.readyForV4RcCandidate,
    required this.uiFullOperationPending,
    required this.notV4WorkbenchRc,
    required this.workflowCount,
    required this.driftCount,
    required this.fixtureOnlyCountedAsReal,
    required this.fullReadyActionExecutionComplete,
    required this.evidenceLevelCounts,
    required this.workflowIds,
    required this.remainingBlockers,
    required this.readyCoreCliActionCount,
    required this.executionTargetCount,
    required this.passedActionCount,
    required this.failedActionCount,
    required this.blockedActionCount,
    required this.actionResults,
    required this.artifactAssertionStatus,
    required this.reportAssertionStatus,
    required this.errorBoundaryStatus,
    required this.userPathClosureStatus,
    required this.userPathCount,
    required this.userPathPassedCount,
    required this.userPathBlockedCount,
    required this.userPaths,
    required this.blockedActions,
    required this.remainingRisks,
  });

  final String coreCommit;
  final String status;
  final String fullGateStatus;
  final bool readyForV4Rc;
  final bool readyForV4RcCandidate;
  final bool uiFullOperationPending;
  final bool notV4WorkbenchRc;
  final int workflowCount;
  final int driftCount;
  final bool fixtureOnlyCountedAsReal;
  final bool fullReadyActionExecutionComplete;
  final Map<String, int> evidenceLevelCounts;
  final List<String> workflowIds;
  final List<String> remainingBlockers;
  final int readyCoreCliActionCount;
  final int executionTargetCount;
  final int passedActionCount;
  final int failedActionCount;
  final int blockedActionCount;
  final List<P1ActionExecutionEvidence> actionResults;
  final String artifactAssertionStatus;
  final String reportAssertionStatus;
  final String errorBoundaryStatus;
  final String userPathClosureStatus;
  final int userPathCount;
  final int userPathPassedCount;
  final int userPathBlockedCount;
  final List<P1UserPathEvidence> userPaths;
  final List<P1BlockedActionEvidence> blockedActions;
  final List<String> remainingRisks;

  factory P1WorkflowEvidence.fromJson(Map<String, dynamic> json) {
    final source = _map(json['source']);
    final levels = _map(json['evidence_level_counts']);
    final actionResults = _list(json['action_results']).map((item) => P1ActionExecutionEvidence.fromJson(_map(item))).toList(growable: false);
    final userPaths = _list(json['user_paths']).map((item) => P1UserPathEvidence.fromJson(_map(item))).toList(growable: false);
    final blockedActions = _list(json['blocked_actions']).map((item) => P1BlockedActionEvidence.fromJson(_map(item))).toList(growable: false);
    return P1WorkflowEvidence(
      coreCommit: _string(source['core_commit'], ''),
      status: _string(json['p1_real_workflow_v2_status'], _string(json['p1_real_workflow_v1_status'], 'blocked')),
      fullGateStatus: _string(json['p1_full_operation_gate_status'], 'blocked'),
      readyForV4Rc: _bool(json['ready_for_v4_rc']),
      readyForV4RcCandidate: _bool(json['ready_for_v4_rc_candidate']),
      uiFullOperationPending: _bool(json['ui_full_operation_pending']),
      notV4WorkbenchRc: _bool(json['not_v4_0_workbench_rc']),
      workflowCount: _int(json['workflow_count']),
      driftCount: _int(json['command_surface_drift_count']),
      fixtureOnlyCountedAsReal: _bool(json['fixture_only_counted_as_real']),
      fullReadyActionExecutionComplete: _bool(json['full_57_ready_action_execution_complete']),
      evidenceLevelCounts: levels.map((key, value) => MapEntry(key, _int(value))),
      workflowIds: _strings(json['workflow_ids']),
      remainingBlockers: _list(json['remaining_blockers']).map((item) => _string(_map(item)['blocker_id'], '')).where((item) => item.isNotEmpty).toList(),
      readyCoreCliActionCount: _int(json['ready_core_cli_action_count']),
      executionTargetCount: _int(json['execution_target_count']),
      passedActionCount: _int(json['passed_action_count']),
      failedActionCount: _int(json['failed_action_count']),
      blockedActionCount: _int(json['blocked_action_count']),
      actionResults: actionResults,
      artifactAssertionStatus: _string(json['artifact_assertion_status'], ''),
      reportAssertionStatus: _string(json['report_assertion_status'], ''),
      errorBoundaryStatus: _string(json['error_boundary_status'], ''),
      userPathClosureStatus: _string(json['user_path_closure_status'], _string(json['status'], '')),
      userPathCount: _int(json['user_path_count']),
      userPathPassedCount: _int(json['user_path_passed_count'], fallback: _int(json['passed_count'])),
      userPathBlockedCount: _int(json['user_path_blocked_count'], fallback: _int(json['blocked_count'])),
      userPaths: userPaths,
      blockedActions: blockedActions,
      remainingRisks: _list(json['remaining_risks']).map((item) => _string(_map(item)['risk_id'], '')).where((item) => item.isNotEmpty).toList(),
    );
  }

  factory P1WorkflowEvidence.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('P1 workflow evidence must be a JSON object.');
    }
    return P1WorkflowEvidence.fromJson(decoded);
  }
}

class P1ActionExecutionEvidence {
  const P1ActionExecutionEvidence({
    required this.actionId,
    required this.status,
    required this.evidenceLevel,
    required this.assertionStatus,
    required this.classification,
    required this.executionTarget,
    required this.gateImpact,
    required this.artifactAssertionStatus,
    required this.artifactCount,
    required this.reportAssertionStatus,
    required this.reportCount,
    required this.blockedReason,
  });

  final String actionId;
  final String status;
  final String evidenceLevel;
  final String assertionStatus;
  final String classification;
  final bool executionTarget;
  final String gateImpact;
  final String artifactAssertionStatus;
  final int artifactCount;
  final String reportAssertionStatus;
  final int reportCount;
  final String blockedReason;

  factory P1ActionExecutionEvidence.fromJson(Map<String, dynamic> json) {
    return P1ActionExecutionEvidence(
      actionId: _string(json['action_id'], ''),
      status: _string(json['status'], ''),
      evidenceLevel: _string(json['evidence_level'], ''),
      assertionStatus: _string(json['assertion_status'], ''),
      classification: _string(json['classification'], ''),
      executionTarget: _bool(json['execution_target']),
      gateImpact: _string(json['gate_impact'], ''),
      artifactAssertionStatus: _string(json['artifact_assertion_status'], ''),
      artifactCount: _int(json['artifact_count']),
      reportAssertionStatus: _string(json['report_assertion_status'], ''),
      reportCount: _int(json['report_count']),
      blockedReason: _string(json['blocked_reason'], ''),
    );
  }
}

class P1UserPathEvidence {
  const P1UserPathEvidence({
    required this.userPathId,
    required this.status,
    required this.evidenceLevel,
    required this.actionCount,
    required this.reportCount,
    required this.artifactCount,
    required this.gateImpact,
  });

  final String userPathId;
  final String status;
  final String evidenceLevel;
  final int actionCount;
  final int reportCount;
  final int artifactCount;
  final String gateImpact;

  factory P1UserPathEvidence.fromJson(Map<String, dynamic> json) {
    return P1UserPathEvidence(
      userPathId: _string(json['user_path_id'], ''),
      status: _string(json['status'], ''),
      evidenceLevel: _string(json['evidence_level'], ''),
      actionCount: _int(json['action_count'], fallback: _list(json['actions_used']).length),
      reportCount: _int(json['report_count'], fallback: _list(json['reports_generated']).length),
      artifactCount: _int(json['artifact_count'], fallback: _list(json['artifacts_generated']).length),
      gateImpact: _string(json['gate_impact'], ''),
    );
  }
}

class P1BlockedActionEvidence {
  const P1BlockedActionEvidence({
    required this.actionId,
    required this.classification,
    required this.blockedReason,
  });

  final String actionId;
  final String classification;
  final String blockedReason;

  factory P1BlockedActionEvidence.fromJson(Map<String, dynamic> json) {
    return P1BlockedActionEvidence(
      actionId: _string(json['action_id'], ''),
      classification: _string(json['classification'], ''),
      blockedReason: _string(json['blocked_reason'], ''),
    );
  }
}

class P1WorkflowEvidenceLoader {
  const P1WorkflowEvidenceLoader();

  Future<P1WorkflowEvidence> loadFromAsset(String path) async {
    return P1WorkflowEvidence.fromJsonString(await rootBundle.loadString(path));
  }
}

final sampleP1WorkflowEvidence = P1WorkflowEvidence.fromJson({
  'source': {'core_commit': 'f5fa13bb11211abb0bcecaccd845e545a2dacad3'},
  'p1_real_workflow_v1_status': 'passed',
  'p1_full_operation_gate_status': 'blocked',
  'ready_for_v4_rc': false,
  'not_v4_0_workbench_rc': true,
  'workflow_count': 8,
  'workflow_ids': [
    'workspace_lifecycle',
    'import_parse_build',
    'rag_retrieval_verification_smoke',
    'document_generation_smoke',
    'skill_factory_smoke',
    'agent_factory_runtime_smoke',
    'error_repair_task_artifact',
    'template_to_workflow',
  ],
  'command_surface_drift_count': 0,
  'fixture_only_counted_as_real': false,
  'full_57_ready_action_execution_complete': false,
  'evidence_level_counts': {'real_local_workflow': 6, 'deterministic_smoke': 2},
  'remaining_blockers': [
    {'blocker_id': 'full_57_ready_action_business_input_execution_not_complete'},
    {'blocker_id': 'rag_retrieval_verification_smoke_review_required'},
    {'blocker_id': 'agent_factory_runtime_smoke_review_required'},
  ],
});

final sampleP1WorkflowV2Evidence = P1WorkflowEvidence.fromJson({
  'source': {'core_commit': 'f5fa13bb11211abb0bcecaccd845e545a2dacad3'},
  'p1_real_workflow_v2_status': 'passed',
  'p1_final_gate_status': 'ready_for_v4_rc',
  'p1_full_operation_gate_status': 'ready_for_v4_rc',
  'ui_full_operation_pending': false,
  'ready_for_v4_rc_candidate': true,
  'ready_for_v4_rc': true,
  'not_v4_0_workbench_rc': true,
  'ready_core_cli_action_count': 62,
  'execution_target_count': 57,
  'passed_action_count': 57,
  'failed_action_count': 0,
  'blocked_action_count': 5,
  'full_57_ready_action_execution_complete': true,
  'command_surface_drift_count': 0,
  'fixture_only_counted_as_real': false,
  'artifact_assertion_status': 'pass',
  'report_assertion_status': 'pass',
  'error_boundary_status': 'pass',
  'user_path_closure_status': 'pass',
  'user_path_count': 10,
  'user_path_passed_count': 10,
  'user_path_blocked_count': 0,
  'action_results': [
    {'action_id': 'workspace_inspect', 'status': 'passed', 'evidence_level': 'real_local_workflow', 'assertion_status': 'passed', 'classification': 'executable_with_generated_workspace', 'execution_target': true, 'gate_impact': 'contributes_to_p1_real_workflow_v2', 'artifact_assertion_status': 'passed', 'artifact_count': 2, 'report_assertion_status': 'passed', 'report_count': 1},
    {'action_id': 'provider_redaction_check', 'status': 'blocked', 'evidence_level': 'blocked', 'assertion_status': 'passed', 'classification': 'blocked_secret_required', 'execution_target': false, 'gate_impact': 'excluded_from_57_ready_action_execution', 'artifact_assertion_status': 'passed', 'artifact_count': 1, 'report_assertion_status': 'passed', 'report_count': 1, 'blocked_reason': 'Excluded from the 57 local execution targets because secret-risk handling must remain blocked.'},
  ],
  'user_paths': [
    {'user_path_id': 'workspace_import_build_validate_artifact', 'status': 'passed', 'evidence_level': 'real_local_workflow', 'action_count': 6, 'report_count': 6, 'artifact_count': 6, 'gate_impact': 'contributes_to_p1_real_workflow_v2'},
  ],
  'blocked_actions': [
    {'action_id': 'provider_redaction_check', 'classification': 'blocked_secret_required', 'blocked_reason': 'Excluded from the 57 local execution targets because secret-risk handling must remain blocked.'},
  ],
  'remaining_blockers': [],
  'remaining_risks': [
    {'risk_id': 'provider_secret_network_actions_remain_explicit_config_only'},
  ],
});

Map<String, dynamic> _map(Object? value) => value is Map<String, dynamic> ? value : <String, dynamic>{};

List<dynamic> _list(Object? value) => value is List ? value : <dynamic>[];

List<String> _strings(Object? value) => _list(value).map((item) => item.toString()).toList();

String _string(Object? value, String fallback) => value?.toString() ?? fallback;

int _int(Object? value, {int fallback = 0}) => value is int ? value : int.tryParse(value?.toString() ?? '') ?? fallback;

bool _bool(Object? value) => value is bool ? value : value?.toString().toLowerCase() == 'true';
