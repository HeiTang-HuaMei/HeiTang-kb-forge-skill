import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class P1WorkflowEvidence {
  const P1WorkflowEvidence({
    required this.coreCommit,
    required this.status,
    required this.fullGateStatus,
    required this.readyForV4Rc,
    required this.notV4WorkbenchRc,
    required this.workflowCount,
    required this.driftCount,
    required this.fixtureOnlyCountedAsReal,
    required this.fullReadyActionExecutionComplete,
    required this.evidenceLevelCounts,
    required this.workflowIds,
    required this.remainingBlockers,
  });

  final String coreCommit;
  final String status;
  final String fullGateStatus;
  final bool readyForV4Rc;
  final bool notV4WorkbenchRc;
  final int workflowCount;
  final int driftCount;
  final bool fixtureOnlyCountedAsReal;
  final bool fullReadyActionExecutionComplete;
  final Map<String, int> evidenceLevelCounts;
  final List<String> workflowIds;
  final List<String> remainingBlockers;

  factory P1WorkflowEvidence.fromJson(Map<String, dynamic> json) {
    final source = _map(json['source']);
    final levels = _map(json['evidence_level_counts']);
    return P1WorkflowEvidence(
      coreCommit: _string(source['core_commit'], ''),
      status: _string(json['p1_real_workflow_v1_status'], 'blocked'),
      fullGateStatus: _string(json['p1_full_operation_gate_status'], 'blocked'),
      readyForV4Rc: _bool(json['ready_for_v4_rc']),
      notV4WorkbenchRc: _bool(json['not_v4_0_workbench_rc']),
      workflowCount: _int(json['workflow_count']),
      driftCount: _int(json['command_surface_drift_count']),
      fixtureOnlyCountedAsReal: _bool(json['fixture_only_counted_as_real']),
      fullReadyActionExecutionComplete: _bool(json['full_57_ready_action_execution_complete']),
      evidenceLevelCounts: levels.map((key, value) => MapEntry(key, _int(value))),
      workflowIds: _strings(json['workflow_ids']),
      remainingBlockers: _list(json['remaining_blockers']).map((item) => _string(_map(item)['blocker_id'], '')).where((item) => item.isNotEmpty).toList(),
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

class P1WorkflowEvidenceLoader {
  const P1WorkflowEvidenceLoader();

  Future<P1WorkflowEvidence> loadFromAsset(String path) async {
    return P1WorkflowEvidence.fromJsonString(await rootBundle.loadString(path));
  }
}

final sampleP1WorkflowEvidence = P1WorkflowEvidence.fromJson({
  'source': {'core_commit': 'fa00d6c00a11e7fda62919318f4cf17f9b72bfd9'},
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

Map<String, dynamic> _map(Object? value) => value is Map<String, dynamic> ? value : <String, dynamic>{};

List<dynamic> _list(Object? value) => value is List ? value : <dynamic>[];

List<String> _strings(Object? value) => _list(value).map((item) => item.toString()).toList();

String _string(Object? value, String fallback) => value?.toString() ?? fallback;

int _int(Object? value) => value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

bool _bool(Object? value) => value is bool ? value : value?.toString().toLowerCase() == 'true';
