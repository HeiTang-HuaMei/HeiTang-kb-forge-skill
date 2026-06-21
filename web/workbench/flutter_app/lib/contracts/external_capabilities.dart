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
      throw const FormatException(
          'External capability registry must be a JSON object.');
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
      internalCapabilityAnchorCount:
          _int(json['internal_capability_anchor_count']),
      projects: _list(json['projects'])
          .map((item) => ExternalCapabilityProject.fromJson(_map(item)))
          .toList(growable: false),
      releaseBoundary: _map(json['release_boundary']),
    );
  }

  int get plannedAdapterCount => projects
      .where((project) => project.contractStatus.contains('planned_adapter'))
      .length;

  int get futureAdapterCount => projects
      .where((project) => project.contractStatus.contains('future_adapter'))
      .length;

  int get providerRequiredCount => projects
      .where((project) => project.contractStatus.contains('provider_required'))
      .length;

  List<ExternalCapabilityProject> projectsForCorePage(String corePageId) {
    return projects
        .where(
            (project) => project.relatedWorkbenchPageIds.contains(corePageId))
        .toList(growable: false);
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
      relatedWorkbenchPageIds: _list(json['related_workbench_pages'])
          .map((item) => _string(_map(item)['page_id']))
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class ProviderCapabilityStatus {
  const ProviderCapabilityStatus({
    required this.schemaVersion,
    required this.productBaselineChain,
    required this.capabilityCount,
    required this.readyForUserSelectionCount,
    required this.providerNetworkApiReady,
    required this.userConceptBoundary,
    required this.registryEntryClassCounts,
    required this.architectureReferenceStatusCounts,
    required this.architectureReferenceResolutionPolicy,
    required this.futureReferenceResolutionCount,
    required this.futureReferenceClassCounts,
    required this.futureReferenceStatusCounts,
    required this.futureReferenceResolutions,
    required this.indefiniteReferenceStateAllowed,
    required this.legacyReferenceOnlyContractsAreTraceOnly,
    required this.capabilities,
  });

  final String schemaVersion;
  final String productBaselineChain;
  final int capabilityCount;
  final int readyForUserSelectionCount;
  final bool providerNetworkApiReady;
  final Map<String, dynamic> userConceptBoundary;
  final Map<String, dynamic> registryEntryClassCounts;
  final Map<String, dynamic> architectureReferenceStatusCounts;
  final Map<String, dynamic> architectureReferenceResolutionPolicy;
  final int futureReferenceResolutionCount;
  final Map<String, dynamic> futureReferenceClassCounts;
  final Map<String, dynamic> futureReferenceStatusCounts;
  final List<FutureReferenceResolution> futureReferenceResolutions;
  final bool indefiniteReferenceStateAllowed;
  final bool legacyReferenceOnlyContractsAreTraceOnly;
  final List<ProviderCapabilityEntry> capabilities;

  factory ProviderCapabilityStatus.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'Provider capability status must be a JSON object.');
    }
    return ProviderCapabilityStatus.fromJson(decoded);
  }

  factory ProviderCapabilityStatus.fromJson(Map<String, dynamic> json) {
    return ProviderCapabilityStatus(
      schemaVersion: _string(json['schema_version']),
      productBaselineChain: _string(json['product_baseline_chain']),
      capabilityCount: _int(json['capability_count']),
      readyForUserSelectionCount: _int(json['ready_for_user_selection_count']),
      providerNetworkApiReady: _bool(json['provider_network_api_ready']),
      userConceptBoundary: _map(json['user_concept_boundary']),
      registryEntryClassCounts: _map(json['registry_entry_class_counts']),
      architectureReferenceStatusCounts:
          _map(json['architecture_reference_status_counts']),
      architectureReferenceResolutionPolicy:
          _map(json['architecture_reference_resolution_policy']),
      futureReferenceResolutionCount:
          _int(json['future_reference_resolution_count']),
      futureReferenceClassCounts: _map(json['future_reference_class_counts']),
      futureReferenceStatusCounts: _map(json['future_reference_status_counts']),
      futureReferenceResolutions: _list(json['future_reference_resolutions'])
          .map((item) => FutureReferenceResolution.fromJson(_map(item)))
          .toList(growable: false),
      indefiniteReferenceStateAllowed:
          _bool(json['indefinite_reference_state_allowed']),
      legacyReferenceOnlyContractsAreTraceOnly:
          _bool(json['legacy_reference_only_contracts_are_trace_only']),
      capabilities: _list(json['capabilities'])
          .map((item) => ProviderCapabilityEntry.fromJson(_map(item)))
          .toList(growable: false),
    );
  }
}

class FutureReferenceResolution {
  const FutureReferenceResolution({
    required this.projectId,
    required this.projectName,
    required this.legacyStatus,
    required this.stage3CurrentClassification,
    required this.registryEntryClass,
    required this.architectureReferenceStatus,
    required this.runtimeLoadClass,
    required this.worthAbsorbing,
    required this.architectureGainAssessment,
    required this.architectureDeliveryRequired,
    required this.learningNoteOnly,
    required this.indefiniteReferenceAllowed,
    required this.absorbedTargets,
    required this.blocker,
    required this.rejectionReason,
    required this.runtimeDependencyAdded,
    required this.normalUiVisible,
    required this.productBehavior,
  });

  final String projectId;
  final String projectName;
  final String legacyStatus;
  final String stage3CurrentClassification;
  final String registryEntryClass;
  final String architectureReferenceStatus;
  final String runtimeLoadClass;
  final bool worthAbsorbing;
  final Map<String, dynamic> architectureGainAssessment;
  final bool architectureDeliveryRequired;
  final bool learningNoteOnly;
  final bool indefiniteReferenceAllowed;
  final List<String> absorbedTargets;
  final String blocker;
  final String rejectionReason;
  final bool runtimeDependencyAdded;
  final bool normalUiVisible;
  final String productBehavior;

  factory FutureReferenceResolution.fromJson(Map<String, dynamic> json) {
    return FutureReferenceResolution(
      projectId: _string(json['project_id']),
      projectName: _string(json['project_name']),
      legacyStatus: _string(json['legacy_status']),
      stage3CurrentClassification:
          _string(json['stage3_current_classification']),
      registryEntryClass: _string(json['registry_entry_class']),
      architectureReferenceStatus:
          _string(json['architecture_reference_status']),
      runtimeLoadClass: _string(json['runtime_load_class']),
      worthAbsorbing: _bool(json['worth_absorbing']),
      architectureGainAssessment: _map(json['architecture_gain_assessment']),
      architectureDeliveryRequired:
          _bool(json['architecture_delivery_required']),
      learningNoteOnly: _bool(json['learning_note_only']),
      indefiniteReferenceAllowed: _bool(json['indefinite_reference_allowed']),
      absorbedTargets: _strings(json['absorbed_targets']),
      blocker: _string(json['blocker']),
      rejectionReason: _string(json['rejection_reason']),
      runtimeDependencyAdded: _bool(json['runtime_dependency_added']),
      normalUiVisible: _bool(json['normal_ui_visible']),
      productBehavior: _string(json['product_behavior']),
    );
  }
}

class ProviderCapabilityEntry {
  const ProviderCapabilityEntry({
    required this.capabilityId,
    required this.capabilityArea,
    required this.userVisibleName,
    required this.zhUserVisibleName,
    required this.providerType,
    required this.status,
    required this.readyForUserSelection,
    required this.defaultFallback,
    required this.requiresNetwork,
    required this.requiresSecret,
    required this.requiresExternalRuntime,
    required this.requiresDependencyInstall,
    required this.needsVerification,
    required this.auditEventRequired,
    required this.rollbackSupported,
    required this.userVisibleBehavior,
    required this.zhUserVisibleBehavior,
    required this.providerStateCount,
    required this.readyProviderStateCount,
    required this.providerRefs,
    required this.registryEntryClassCounts,
    required this.architectureReferenceStatusCounts,
    required this.providerRuntimeLoadClasses,
  });

  final String capabilityId;
  final String capabilityArea;
  final String userVisibleName;
  final String zhUserVisibleName;
  final String providerType;
  final String status;
  final bool readyForUserSelection;
  final String defaultFallback;
  final bool requiresNetwork;
  final bool requiresSecret;
  final bool requiresExternalRuntime;
  final bool requiresDependencyInstall;
  final bool needsVerification;
  final bool auditEventRequired;
  final bool rollbackSupported;
  final String userVisibleBehavior;
  final String zhUserVisibleBehavior;
  final int providerStateCount;
  final int readyProviderStateCount;
  final List<String> providerRefs;
  final Map<String, dynamic> registryEntryClassCounts;
  final Map<String, dynamic> architectureReferenceStatusCounts;
  final List<String> providerRuntimeLoadClasses;

  factory ProviderCapabilityEntry.fromJson(Map<String, dynamic> json) {
    return ProviderCapabilityEntry(
      capabilityId: _string(json['capability_id']),
      capabilityArea: _string(json['capability_area']),
      userVisibleName: _string(json['user_visible_name']),
      zhUserVisibleName: _string(json['zh_user_visible_name']),
      providerType: _string(json['provider_type']),
      status: _string(json['status']),
      readyForUserSelection: _bool(json['ready_for_user_selection']),
      defaultFallback: _string(json['default_fallback']),
      requiresNetwork: _bool(json['requires_network']),
      requiresSecret: _bool(json['requires_secret']),
      requiresExternalRuntime: _bool(json['requires_external_runtime']),
      requiresDependencyInstall: _bool(json['requires_dependency_install']),
      needsVerification: _bool(json['needs_verification']),
      auditEventRequired: _bool(json['audit_event_required']),
      rollbackSupported: _bool(json['rollback_supported']),
      userVisibleBehavior: _string(json['user_visible_behavior']),
      zhUserVisibleBehavior: _string(json['zh_user_visible_behavior']),
      providerStateCount: _list(json['related_provider_states']).length,
      readyProviderStateCount: _list(json['related_provider_states'])
          .where((item) => _bool(_map(item)['ready_for_user_selection']))
          .length,
      providerRefs: _list(json['related_provider_states'])
          .map((item) => _string(_map(item)['provider_ref']))
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      registryEntryClassCounts: _map(json['registry_entry_class_counts']),
      architectureReferenceStatusCounts:
          _map(json['architecture_reference_status_counts']),
      providerRuntimeLoadClasses: _list(json['related_provider_states'])
          .map((item) => _string(_map(item)['runtime_load_class']))
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: false),
    );
  }
}

class ExternalCapabilityLoader {
  const ExternalCapabilityLoader();

  Future<ExternalCapabilityRegistry> loadFromAsset(String path) async {
    return ExternalCapabilityRegistry.fromJsonString(
        await rootBundle.loadString(path));
  }
}

class ProviderCapabilityStatusLoader {
  const ProviderCapabilityStatusLoader();

  Future<ProviderCapabilityStatus> loadFromAsset(String path) async {
    return ProviderCapabilityStatus.fromJsonString(
        await rootBundle.loadString(path));
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
      'blocked_reasons': [
        'external_project_registry_only',
        'future_adapter_after_v4',
        'not_p1_blocker'
      ],
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
      'contract_status': ['provider_required', 'planned_adapter'],
      'blocked_reason': 'external_project_registry_only',
      'blocked_reasons': [
        'external_project_registry_only',
        'provider_required',
        'network_required',
        'secret_required'
      ],
      'requires_api_key': true,
      'requires_network': true,
      'requires_external_runtime': false,
      'can_execute_locally_before_v4': false,
      'post_v4_target': 'P2.3',
      'ui_visibility': 'visible_boundary_only',
      'related_workbench_pages': [
        {'page_id': 'retrieval_verification'},
        {'page_id': 'vector_hub_provider_storage'},
      ],
    },
  ],
});

final sampleProviderCapabilityStatus = ProviderCapabilityStatus.fromJson({
  'schema_version': 'prd_v3_provider_capability_status.v2',
  'product_baseline_chain':
      '文档库 -> 知识库 -> 索引层 -> RAG -> 编排层 -> 文档/Skill/Agent/A2A',
  'capability_count': 2,
  'ready_for_user_selection_count': 0,
  'provider_network_api_ready': false,
  'registry_entry_class_counts': {
    'capability_provider': 2,
    'template_asset': 0,
    'architecture_reference': 0,
  },
  'architecture_reference_status_counts': {
    'candidate_reference': 0,
    'absorbed_into_architecture': 2,
    'rejected_no_architecture_gain': 0,
    'deferred_with_blocker': 0,
  },
  'architecture_reference_resolution_policy': {
    'candidate_reference_allowed': false,
    'learning_note_only_allowed': false,
    'indefinite_reference_allowed': false,
    'architecture_gain_criteria': [
      'fills_current_architecture_gap',
      'reduces_complexity',
      'improves_extensibility',
      'improves_stability_audit_or_rollback',
      'improves_core_abstraction',
    ],
    'absorbed_requires_parallel_architecture_delivery': true,
    'deferred_requires_named_blocker': true,
    'rejected_requires_rejection_reason': true,
  },
  'future_reference_resolution_count': 1,
  'future_reference_class_counts': {
    'capability_provider': 0,
    'template_asset': 1,
    'architecture_reference': 0,
  },
  'future_reference_status_counts': {
    'candidate_reference': 0,
    'absorbed_into_architecture': 1,
    'rejected_no_architecture_gain': 0,
    'deferred_with_blocker': 0,
  },
  'future_reference_resolutions': [
    {
      'project_id': 'andrej_karpathy_skills',
      'project_name': 'andrej-karpathy-skills',
      'legacy_status': 'reference_only',
      'stage3_current_classification': 'template_asset',
      'registry_entry_class': 'template_asset',
      'architecture_reference_status': 'absorbed_into_architecture',
      'runtime_load_class': 'template_asset_manifest_only',
      'worth_absorbing': true,
      'architecture_gain_assessment': {
        'fills_current_architecture_gap': true,
        'reduces_complexity': false,
        'improves_extensibility': true,
        'improves_stability_audit_or_rollback': true,
        'improves_core_abstraction': false,
      },
      'architecture_delivery_required': true,
      'learning_note_only': false,
      'indefinite_reference_allowed': false,
      'absorbed_targets': ['contract', 'schema'],
      'blocker': '',
      'rejection_reason': '',
      'runtime_dependency_added': false,
      'normal_ui_visible': false,
      'product_behavior': 'architecture_rule_absorbed_no_runtime',
    },
  ],
  'indefinite_reference_state_allowed': false,
  'legacy_reference_only_contracts_are_trace_only': true,
  'user_concept_boundary': {
    'external_project_names_visible_in_normal_ui': false,
    'hot_swap_project_concept_visible': false,
    'unverified_entries_marked_ready': false,
    'planned_adapters_marked_ready': false,
    'okf_runtime_added': false,
  },
  'capabilities': [
    {
      'capability_id': 'document_parser_ocr',
      'capability_area': 'document_library',
      'user_visible_name': 'Parser / OCR',
      'zh_user_visible_name': '解析 / OCR',
      'provider_type': 'parser_ocr',
      'status': 'dependency_gated',
      'ready_for_user_selection': false,
      'default_fallback': 'local_parser',
      'requires_network': false,
      'requires_secret': false,
      'requires_external_runtime': false,
      'requires_dependency_install': true,
      'needs_verification': false,
      'audit_event_required': true,
      'rollback_supported': true,
      'registry_entry_class_counts': {
        'capability_provider': 1,
        'template_asset': 0,
        'architecture_reference': 0,
      },
      'architecture_reference_status_counts': {
        'candidate_reference': 0,
        'absorbed_into_architecture': 1,
        'rejected_no_architecture_gain': 0,
        'deferred_with_blocker': 0,
      },
      'user_visible_behavior':
          'Requires dependency install or adapter completion',
      'zh_user_visible_behavior': '需要安装或完成适配后启用',
      'related_provider_states': [
        {
          'provider_ref': 'docling',
          'ready_for_user_selection': false,
          'runtime_load_class': 'provider_capability_config_gated',
        },
      ],
    },
    {
      'capability_id': 'retrieval_provider',
      'capability_area': 'retrieval_rag',
      'user_visible_name': 'Search / Retrieval',
      'zh_user_visible_name': '检索 / 召回',
      'provider_type': 'search_retrieval',
      'status': 'needs_network_authorization',
      'ready_for_user_selection': false,
      'default_fallback': 'local_rag_retrieval',
      'requires_network': true,
      'requires_secret': false,
      'requires_external_runtime': false,
      'requires_dependency_install': false,
      'needs_verification': false,
      'audit_event_required': true,
      'rollback_supported': true,
      'registry_entry_class_counts': {
        'capability_provider': 1,
        'template_asset': 0,
        'architecture_reference': 0,
      },
      'architecture_reference_status_counts': {
        'candidate_reference': 0,
        'absorbed_into_architecture': 1,
        'rejected_no_architecture_gain': 0,
        'deferred_with_blocker': 0,
      },
      'user_visible_behavior': 'Requires network authorization and validation',
      'zh_user_visible_behavior': '需要网络授权与验证',
      'related_provider_states': [
        {
          'provider_ref': 'anysearchskill',
          'ready_for_user_selection': false,
          'runtime_load_class': 'provider_capability_config_gated',
        },
      ],
    },
  ],
});

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};

List<dynamic> _list(Object? value) => value is List ? value : <dynamic>[];

List<String> _strings(Object? value) =>
    _list(value).map((item) => item.toString()).toList(growable: false);

String _string(Object? value) => value?.toString() ?? '';

int _int(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

bool _bool(Object? value) =>
    value is bool ? value : value?.toString().toLowerCase() == 'true';
