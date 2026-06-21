class ProjectConfigProfile {
  const ProjectConfigProfile({
    required this.profileId,
    required this.displayName,
    required this.mode,
    required this.workspaceId,
    required this.storageConfigId,
    required this.modelConfigId,
    required this.modelGatewayConfigId,
    required this.embeddingConfigId,
    required this.searchProviderConfigId,
    required this.ocrProviderConfigId,
    required this.pdfParserProviderConfigId,
    required this.exporterConfigId,
    required this.redisConfigId,
    required this.vectorConfigId,
    required this.networkPolicyId,
    required this.agentMemoryPolicyId,
    required this.toolPolicyId,
    required this.isDefault,
    required this.isActive,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    required this.lastActivatedAt,
    required this.lastTestStatus,
    required this.lastTestSummary,
    required this.lastError,
    required this.rollbackFromProfileId,
  });

  final String profileId;
  final String displayName;
  final String mode;
  final String workspaceId;
  final String storageConfigId;
  final String modelConfigId;
  final String modelGatewayConfigId;
  final String embeddingConfigId;
  final String searchProviderConfigId;
  final String ocrProviderConfigId;
  final String pdfParserProviderConfigId;
  final String exporterConfigId;
  final String redisConfigId;
  final String vectorConfigId;
  final String networkPolicyId;
  final String agentMemoryPolicyId;
  final String toolPolicyId;
  final bool isDefault;
  final bool isActive;
  final int version;
  final String createdAt;
  final String updatedAt;
  final String lastActivatedAt;
  final String lastTestStatus;
  final String lastTestSummary;
  final String lastError;
  final String rollbackFromProfileId;

  factory ProjectConfigProfile.fromJson(Map<String, dynamic> json) {
    return ProjectConfigProfile(
      profileId: _string(json['profile_id']),
      displayName: _string(json['display_name']),
      mode: _string(json['mode']).isEmpty ? 'local' : _string(json['mode']),
      workspaceId: _string(json['workspace_id']),
      storageConfigId: _string(json['storage_config_id']),
      modelConfigId: _string(json['model_config_id']),
      modelGatewayConfigId: _string(json['model_gateway_config_id']).isEmpty
          ? 'gateway_not_configured'
          : _string(json['model_gateway_config_id']),
      embeddingConfigId: _string(json['embedding_config_id']),
      searchProviderConfigId: _string(json['search_provider_config_id']),
      ocrProviderConfigId: _string(json['ocr_provider_config_id']),
      pdfParserProviderConfigId: _string(json['pdf_parser_provider_config_id']),
      exporterConfigId: _string(json['exporter_config_id']),
      redisConfigId: _string(json['redis_config_id']),
      vectorConfigId: _string(json['vector_config_id']),
      networkPolicyId: _string(json['network_policy_id']),
      agentMemoryPolicyId: _string(json['agent_memory_policy_id']),
      toolPolicyId: _string(json['tool_policy_id']),
      isDefault: _bool(json['is_default']),
      isActive: _bool(json['is_active']),
      version: _int(json['version'], 1),
      createdAt: _string(json['created_at']),
      updatedAt: _string(json['updated_at']),
      lastActivatedAt: _string(json['last_activated_at']),
      lastTestStatus: _string(json['last_test_status']),
      lastTestSummary: _string(json['last_test_summary']),
      lastError: _string(json['last_error']),
      rollbackFromProfileId: _string(json['rollback_from_profile_id']),
    );
  }

  factory ProjectConfigProfile.localDefault({
    required String workspaceId,
    required String createdAt,
  }) {
    return ProjectConfigProfile(
      profileId: 'default_local',
      displayName: '默认本地配置',
      mode: 'local',
      workspaceId: workspaceId,
      storageConfigId: 'storage_local_workspace',
      modelConfigId: 'model_env_configured',
      modelGatewayConfigId: 'gateway_not_configured',
      embeddingConfigId: 'embedding_local_keyword',
      searchProviderConfigId: 'search_local_index',
      ocrProviderConfigId: 'ocr_not_configured',
      pdfParserProviderConfigId: 'pdf_parser_builtin',
      exporterConfigId: 'exporter_local_markdown_json_csv',
      redisConfigId: 'redis_not_configured',
      vectorConfigId: 'vector_local_keyword_index',
      networkPolicyId: 'network_local_only',
      agentMemoryPolicyId: 'agent_memory_local_file',
      toolPolicyId: 'tool_policy_simple_local',
      isDefault: true,
      isActive: true,
      version: 1,
      createdAt: createdAt,
      updatedAt: createdAt,
      lastActivatedAt: createdAt,
      lastTestStatus: '已配置未测试',
      lastTestSummary: '默认本地配置已创建，外部服务未启用。',
      lastError: '',
      rollbackFromProfileId: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'display_name': displayName,
      'mode': mode,
      'workspace_id': workspaceId,
      'storage_config_id': storageConfigId,
      'model_config_id': modelConfigId,
      'model_gateway_config_id': modelGatewayConfigId,
      'embedding_config_id': embeddingConfigId,
      'search_provider_config_id': searchProviderConfigId,
      'ocr_provider_config_id': ocrProviderConfigId,
      'pdf_parser_provider_config_id': pdfParserProviderConfigId,
      'exporter_config_id': exporterConfigId,
      'redis_config_id': redisConfigId,
      'vector_config_id': vectorConfigId,
      'network_policy_id': networkPolicyId,
      'agent_memory_policy_id': agentMemoryPolicyId,
      'tool_policy_id': toolPolicyId,
      'is_default': isDefault,
      'is_active': isActive,
      'version': version,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'last_activated_at': lastActivatedAt,
      'last_test_status': lastTestStatus,
      'last_test_summary': lastTestSummary,
      'last_error': lastError,
      'rollback_from_profile_id': rollbackFromProfileId,
    };
  }

  ProjectConfigProfile copyWith({
    String? profileId,
    String? displayName,
    String? mode,
    String? workspaceId,
    String? storageConfigId,
    String? modelConfigId,
    String? modelGatewayConfigId,
    String? embeddingConfigId,
    String? searchProviderConfigId,
    String? ocrProviderConfigId,
    String? pdfParserProviderConfigId,
    String? exporterConfigId,
    String? redisConfigId,
    String? vectorConfigId,
    String? networkPolicyId,
    String? agentMemoryPolicyId,
    String? toolPolicyId,
    bool? isDefault,
    bool? isActive,
    int? version,
    String? createdAt,
    String? updatedAt,
    String? lastActivatedAt,
    String? lastTestStatus,
    String? lastTestSummary,
    String? lastError,
    String? rollbackFromProfileId,
  }) {
    return ProjectConfigProfile(
      profileId: profileId ?? this.profileId,
      displayName: displayName ?? this.displayName,
      mode: mode ?? this.mode,
      workspaceId: workspaceId ?? this.workspaceId,
      storageConfigId: storageConfigId ?? this.storageConfigId,
      modelConfigId: modelConfigId ?? this.modelConfigId,
      modelGatewayConfigId: modelGatewayConfigId ?? this.modelGatewayConfigId,
      embeddingConfigId: embeddingConfigId ?? this.embeddingConfigId,
      searchProviderConfigId:
          searchProviderConfigId ?? this.searchProviderConfigId,
      ocrProviderConfigId: ocrProviderConfigId ?? this.ocrProviderConfigId,
      pdfParserProviderConfigId:
          pdfParserProviderConfigId ?? this.pdfParserProviderConfigId,
      exporterConfigId: exporterConfigId ?? this.exporterConfigId,
      redisConfigId: redisConfigId ?? this.redisConfigId,
      vectorConfigId: vectorConfigId ?? this.vectorConfigId,
      networkPolicyId: networkPolicyId ?? this.networkPolicyId,
      agentMemoryPolicyId: agentMemoryPolicyId ?? this.agentMemoryPolicyId,
      toolPolicyId: toolPolicyId ?? this.toolPolicyId,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActivatedAt: lastActivatedAt ?? this.lastActivatedAt,
      lastTestStatus: lastTestStatus ?? this.lastTestStatus,
      lastTestSummary: lastTestSummary ?? this.lastTestSummary,
      lastError: lastError ?? this.lastError,
      rollbackFromProfileId:
          rollbackFromProfileId ?? this.rollbackFromProfileId,
    );
  }
}

String _string(Object? value) => value?.toString() ?? '';

int _int(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _bool(Object? value) =>
    value is bool ? value : value?.toString().toLowerCase() == 'true';
