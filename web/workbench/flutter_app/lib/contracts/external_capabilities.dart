import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class ExternalCapabilityRegistry {
  const ExternalCapabilityRegistry({
    required this.version,
    required this.sourceRegistry,
    required this.sProjectCount,
    required this.aProjectCount,
    required this.externalProjectCount,
    required this.internalCapabilityAnchorCount,
    required this.projects,
    required this.releaseBoundary,
  });

  final String version;
  final String sourceRegistry;
  final int sProjectCount;
  final int aProjectCount;
  final int externalProjectCount;
  final int internalCapabilityAnchorCount;
  final List<ExternalCapabilityProject> projects;
  final Map<String, dynamic> releaseBoundary;

  factory ExternalCapabilityRegistry.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('External capability registry must be a JSON object.');
    }
    return ExternalCapabilityRegistry.fromJson(decoded);
  }

  factory ExternalCapabilityRegistry.fromJson(Map<String, dynamic> json) {
    final counts = _map(json['rating_counts']);
    return ExternalCapabilityRegistry(
      version: _string(json['version']),
      sourceRegistry: _string(json['source_registry']),
      sProjectCount: _int(counts['S']),
      aProjectCount: _int(counts['A']),
      externalProjectCount: _int(json['external_project_count']),
      internalCapabilityAnchorCount: _int(json['internal_capability_anchor_count']),
      projects: _list(json['projects']).map((item) => ExternalCapabilityProject.fromJson(_map(item))).toList(growable: false),
      releaseBoundary: _map(json['release_boundary']),
    );
  }

  int get plannedAdapterCount => projects.where((project) => project.contractStatus.contains('planned_adapter')).length;

  int get futureAdapterCount => projects.where((project) => project.contractStatus.contains('future_adapter')).length;

  int get providerRequiredCount => projects.where((project) => project.contractStatus.contains('provider_required')).length;

  List<ExternalCapabilityProject> projectsForCorePage(String corePageId) {
    return projects.where((project) => project.relatedWorkbenchPageIds.contains(corePageId)).toList(growable: false);
  }
}

class ExternalCapabilityProject {
  const ExternalCapabilityProject({
    required this.projectId,
    required this.projectName,
    required this.rating,
    required this.githubUrl,
    required this.contractStatus,
    required this.blockedReason,
    required this.blockedReasons,
    required this.requiresApiKey,
    required this.requiresNetwork,
    required this.requiresExternalRuntime,
    required this.canExecuteLocallyBeforeV4,
    required this.postV4Target,
    required this.uiVisibility,
    required this.relatedWorkbenchPageIds,
    required this.ready,
    required this.localReady,
    required this.executableAction,
  });

  final String projectId;
  final String projectName;
  final String rating;
  final String githubUrl;
  final List<String> contractStatus;
  final String blockedReason;
  final List<String> blockedReasons;
  final bool requiresApiKey;
  final bool requiresNetwork;
  final bool requiresExternalRuntime;
  final bool canExecuteLocallyBeforeV4;
  final String postV4Target;
  final String uiVisibility;
  final List<String> relatedWorkbenchPageIds;
  final bool ready;
  final bool localReady;
  final bool executableAction;

  factory ExternalCapabilityProject.fromJson(Map<String, dynamic> json) {
    return ExternalCapabilityProject(
      projectId: _string(json['project_id']),
      projectName: _string(json['project_name']),
      rating: _string(json['rating']),
      githubUrl: _string(json['github_url']),
      contractStatus: _strings(json['contract_status']),
      blockedReason: _string(json['blocked_reason']),
      blockedReasons: _strings(json['blocked_reasons']),
      requiresApiKey: _bool(json['requires_api_key']),
      requiresNetwork: _bool(json['requires_network']),
      requiresExternalRuntime: _bool(json['requires_external_runtime']),
      canExecuteLocallyBeforeV4: _bool(json['can_execute_locally_before_v4']),
      postV4Target: _string(json['post_v4_target']),
      uiVisibility: _string(json['ui_visibility']),
      relatedWorkbenchPageIds: _list(json['related_workbench_pages']).map((item) => _string(_map(item)['page_id'])).where((value) => value.isNotEmpty).toList(growable: false),
      ready: _bool(json['ready']),
      localReady: _bool(json['local_ready']),
      executableAction: _bool(json['executable_action']),
    );
  }
}

class ExternalCapabilityLoader {
  const ExternalCapabilityLoader();

  Future<ExternalCapabilityRegistry> loadFromAsset(String path) async {
    return ExternalCapabilityRegistry.fromJsonString(await rootBundle.loadString(path));
  }
}

final sampleExternalCapabilityRegistry = ExternalCapabilityRegistry.fromJson({
  'version': 'sample',
  'source_registry': 'sample',
  'rating_counts': {'S': 1, 'A': 1},
  'external_project_count': 2,
  'internal_capability_anchor_count': 0,
  'release_boundary': {
    'p1_gate_changed': false,
    'v4_0_started': false,
    'external_features_implemented': false,
    'planned_adapters_marked_ready': false,
    'provider_network_api_ready': false,
  },
  'projects': [
    {
      'project_id': 'llm_wiki_v2',
      'project_name': 'LLM Wiki v2',
      'rating': 'S',
      'github_url': 'https://github.com/karpathy/llm-wiki',
      'contract_status': ['future_adapter', 'capability_anchor'],
      'blocked_reason': 'external_project_registry_only',
      'blocked_reasons': ['external_project_registry_only', 'future_adapter_after_v4', 'not_p1_blocker'],
      'requires_api_key': false,
      'requires_network': false,
      'requires_external_runtime': false,
      'can_execute_locally_before_v4': false,
      'post_v4_target': 'P2.4',
      'ui_visibility': 'visible_boundary_only',
      'related_workbench_pages': [
        {'page_id': 'memory_center'},
      ],
    },
    {
      'project_id': 'anysearchskill',
      'project_name': 'AnySearchSkill',
      'rating': 'A',
      'github_url': 'https://github.com/anysearch-ai/anysearch-skill',
      'contract_status': [
        'provider_adapter',
        'real_smoke_passed',
        'needs_strengthening'
      ],
      'blocked_reason': 'ui_configuration_pending',
      'blocked_reasons': [
        'network_required',
        'ui_configuration_pending',
        'provider_terms_review_pending'
      ],
      'requires_api_key': false,
      'requires_network': true,
      'requires_external_runtime': false,
      'can_execute_locally_before_v4': false,
      'post_v4_target': 'P2.3',
      'ui_visibility': 'visible_status_only',
      'related_workbench_pages': [
        {'page_id': 'retrieval_verification'},
        {'page_id': 'vector_hub_provider_storage'},
      ],
    },
  ],
});

Map<String, dynamic> _map(Object? value) => value is Map<String, dynamic> ? value : <String, dynamic>{};

List<dynamic> _list(Object? value) => value is List ? value : <dynamic>[];

List<String> _strings(Object? value) => _list(value).map((item) => item.toString()).toList(growable: false);

String _string(Object? value) => value?.toString() ?? '';

int _int(Object? value) => value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

bool _bool(Object? value) => value is bool ? value : value?.toString().toLowerCase() == 'true';
