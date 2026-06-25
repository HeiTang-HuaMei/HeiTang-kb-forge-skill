import 'package:flutter/foundation.dart';

import '../core_bridge/local_core_bridge.dart';
import 'project_config_profile.dart';

class Rc6RuntimeController extends ChangeNotifier {
  Rc6RuntimeController({
    required this.coreBridge,
    required this.coreCli,
    required this.coreWorkingDirectory,
    required this.configuredWorkspace,
    required this.isWebRuntime,
  });

  final LocalCoreBridge coreBridge;
  final String coreCli;
  final String coreWorkingDirectory;
  final String configuredWorkspace;
  final bool isWebRuntime;

  Rc6RuntimeState state = Rc6RuntimeState.initial();

  bool get prefersAgentConsoleInitialPage => false;
  String get agentConsoleVerifierScenario => '';

  Future<void> initialize() async {
    state = state.copyWith(
      phase: Rc6RuntimePhase.blocked,
      lastMessage: '真实文件链路需要 Windows EXE 桌面端；Flutter Web 不执行本地文件操作。',
      lastError: 'desktop_runtime_required',
    );
    notifyListeners();
  }

  Future<void> pickAndImportFile() async => initialize();
  Future<void> pickAndImportFolder() async => initialize();
  Future<void> importOwnerInputFolder() async => initialize();
  Future<void> pickAndRunRealInputFolderE2E({String query = '赚钱 小生意'}) async =>
      initialize();
  Future<void> importLocalPath(String path) async => initialize();
  Future<void> importFilePath(String filePath) async => initialize();
  Future<void> importFolderPath(String folderPath) async => initialize();
  Future<void> importWebLink(String url) async => initialize();
  Future<void> createOrSwitchWorkbook(String name) async => initialize();
  Future<void> deleteWorkbook(String name) async => initialize();
  Future<void> parseAndChunkSources() async => initialize();
  Future<void> buildKnowledgeBase(
          {List<String> documentIds = const []}) async =>
      initialize();
  Future<String> exportStandardKnowledgePackage() async {
    await initialize();
    return '';
  }

  Future<String> importStandardKnowledgePackagePath(String path) async {
    await initialize();
    return '';
  }

  Future<void> buildKnowledgeBaseFromStandardPackage() async => initialize();
  Future<void> copyKnowledgeBase(String sourceKbId) async => initialize();
  Future<void> mergeKnowledgeBases(List<String> sourceKbIds) async =>
      initialize();
  Future<void> splitKnowledgeBase(String sourceKbId) async => initialize();
  Future<void> updateKnowledgeBaseIncremental(String kbId) async =>
      initialize();
  Future<void> rebuildKnowledgeBaseFull(String kbId) async => initialize();
  Future<void> compareKnowledgeBaseVersions(String kbId) async => initialize();
  Future<void> rollbackKnowledgeBaseVersion(String kbId) async => initialize();
  Future<void> deleteKnowledgeBaseRecord(String kbId) async => initialize();
  Future<void> search(String query) async => initialize();
  Future<void> searchKnowledgeBases(String query, List<String> kbIds) async =>
      initialize();
  Future<String> saveRetrievalValidationReport(
      Map<int, String> corrections) async {
    await initialize();
    return '';
  }

  Future<void> generateMarkdown({
    Rc6DocumentGenerationConfig config = const Rc6DocumentGenerationConfig(),
  }) async =>
      initialize();
  Future<void> exportMarkdownDocument() async => initialize();
  Future<void> exportDocumentFormat(String format) async => initialize();
  Future<void> clearDocumentGenerationHistory() async => initialize();
  Future<void> deleteLatestDocumentGenerationHistory() async => initialize();
  Future<String> registerDocumentTemplateLibrary({
    bool includeTestTemplate = false,
  }) async {
    await initialize();
    return '';
  }

  Future<String> readDocumentTemplateRegistryPreview({
    int maxCharacters = 6000,
  }) async {
    await initialize();
    return '';
  }

  Future<String> exportDocumentTemplateRegistry() async {
    await initialize();
    return '';
  }

  Future<void> deleteTestDocumentTemplateRegistryEntry() async => initialize();
  Future<String> runDocumentTemplateRegistryAcceptance() async {
    await initialize();
    return '';
  }

  Future<String> runOfficeArtifactAdapterAcceptance() async {
    await initialize();
    return '';
  }

  Future<void> deleteTestOfficeDocxAdapterArtifact() async => initialize();

  Future<String> readLatestDocumentGenerationHistoryMarkdown({
    int maxCharacters = 6000,
  }) async {
    await initialize();
    return '';
  }

  Future<String> saveEditedDocument(String markdown) async {
    await initialize();
    return '';
  }

  Future<String> exportAuditReport() async {
    await initialize();
    return '';
  }

  Future<void> clearImportedSources() async => initialize();
  Future<void> clearKnowledgeBaseArtifacts() async => initialize();
  Future<void> clearParseArtifacts() async => initialize();
  Future<void> clearSearchArtifacts() async => initialize();
  Future<void> clearDocumentArtifacts() async => initialize();
  Future<void> clearSkillArtifacts() async => initialize();
  Future<void> clearAgentArtifacts() async => initialize();
  Future<void> clearSettingsValidationArtifacts() async => initialize();
  Future<void> clearParallelTaskValidationArtifacts() async => initialize();
  Future<void> clearRecentTaskArtifacts(String taskId) async => initialize();
  Future<void> deleteArtifactRecord(String artifactId) async => initialize();
  Future<void> deleteImportedSource(String sourceNameOrRelativePath) async =>
      initialize();
  Future<String> readWorkspaceTextArtifact(String path,
          {int maxCharacters = 6000}) async =>
      '真实产物预览需要 Windows EXE 桌面端。';
  Future<String> exportWorkspaceArtifact({
    required String artifactPath,
    required String artifactLabel,
  }) async {
    await initialize();
    return '';
  }

  Future<Rc6StorageTestResult> testRedisConnection({
    required String host,
    required int port,
    required String keyPrefix,
    String password = '',
  }) async =>
      const Rc6StorageTestResult(
        passed: false,
        status: 'desktop_runtime_required',
        detail: '真实 Redis 连接测试需要 Windows EXE 桌面端。',
      );
  Future<Rc6StorageTestResult> testQdrantConnection({
    required String endpoint,
    required String collection,
    required int dimension,
    String apiKey = '',
  }) async =>
      const Rc6StorageTestResult(
        passed: false,
        status: 'desktop_runtime_required',
        detail: '真实 Qdrant 连接测试需要 Windows EXE 桌面端。',
      );
  Future<void> runStorageConnectionAcceptance() async => initialize();
  Future<String> runMemoryEvidenceMetadataReservationAcceptance() async {
    await initialize();
    return '';
  }

  Future<String> runOkfMinimalCoreAcceptance() async {
    await initialize();
    return '';
  }

  Future<String> runAgentMemoryMinimalCoreAcceptance() async {
    await initialize();
    return '';
  }

  Future<String> runKnowledgeReliabilityMinimalCoreAcceptance() async {
    await initialize();
    return '';
  }

  Future<String> runAssistantBoundKbIntegrationAcceptance() async {
    await initialize();
    return '';
  }

  Future<String> runAssistantBackendSeparationAcceptance() async {
    await initialize();
    return '';
  }

  Future<String> runUiTasteGateAcceptance() async {
    await initialize();
    return '';
  }

  Future<String> runFullRouteResponsiveReviewAcceptance() async {
    await initialize();
    return '';
  }

  Future<Map<String, dynamic>> loadStorageProviderSettings() async => {
        'schema_version': 'heitang_storage_provider_settings.v1',
        'workspace': '',
        'provider': {
          'llm_provider': 'env_configured',
          'secret_source': 'env_only',
          'api_key_display': '************',
          'status': 'configured',
        },
        'redis': {
          'host': '127.0.0.1',
          'port': 6379,
          'key_prefix': 'heitang:',
          'password_display': '********',
          'password_secret_ref': 'env:HEITANG_REDIS_PASSWORD',
          'status': 'desktop_runtime_required',
          'last_test_detail': '',
        },
        'qdrant': {
          'provider': 'qdrant',
          'endpoint': 'http://127.0.0.1:6333',
          'collection': 'heitang_kb',
          'dimension': 1536,
          'api_key_display': '',
          'api_key_secret_ref': 'none',
          'status': 'desktop_runtime_required',
          'last_test_detail': '',
        },
        'exporters': {
          'markdown': {'status': 'connected', 'extension': 'md'},
          'txt': {'status': 'desktop_runtime_required', 'extension': 'txt'},
          'docx': {'status': 'desktop_runtime_required', 'extension': 'docx'},
          'pdf': {'status': 'desktop_runtime_required', 'extension': 'pdf'},
          'pptx': {'status': 'desktop_runtime_required', 'extension': 'pptx'},
          'xlsx': {'status': 'desktop_runtime_required', 'extension': 'xlsx'},
          'json': {'status': 'desktop_runtime_required', 'extension': 'json'},
          'csv': {'status': 'desktop_runtime_required', 'extension': 'csv'},
        },
      };

  Future<List<ProjectConfigProfile>> loadProjectConfigProfiles() async => [
        ProjectConfigProfile.localDefault(
          workspaceId: '',
          createdAt: '',
        ).copyWith(
          lastTestStatus: '需启动外部服务',
          lastTestSummary: '真实 Profile 配置需要 Windows EXE 桌面端。',
        ),
      ];

  Future<ProjectConfigProfile> createProjectConfigProfile({
    required String displayName,
    String mode = 'local',
  }) async {
    await initialize();
    return ProjectConfigProfile.localDefault(workspaceId: '', createdAt: '');
  }

  Future<ProjectConfigProfile> copyProjectConfigProfile(
      String sourceProfileId) async {
    await initialize();
    return ProjectConfigProfile.localDefault(workspaceId: '', createdAt: '');
  }

  Future<ProjectConfigProfile> updateProjectConfigProfile(
    String profileId, {
    required String displayName,
    required String mode,
  }) async {
    await initialize();
    return ProjectConfigProfile.localDefault(workspaceId: '', createdAt: '');
  }

  Future<ProjectConfigProfile> activateProjectConfigProfile(
      String profileId) async {
    await initialize();
    return ProjectConfigProfile.localDefault(workspaceId: '', createdAt: '');
  }

  Future<bool> deleteProjectConfigProfile(String profileId) async {
    await initialize();
    return false;
  }

  Future<ProjectConfigProfile> rollbackProjectConfigProfile() async {
    await initialize();
    return ProjectConfigProfile.localDefault(workspaceId: '', createdAt: '');
  }

  Future<String> testProjectConfigProfile(String profileId) async {
    await initialize();
    return '';
  }

  Future<String> runStage3ProfilePersistenceSmoke() async {
    await initialize();
    return '';
  }

  Future<String> syncRegisteredProviderCapabilities() async {
    await initialize();
    return '';
  }

  Future<String> testAllRegisteredProviderCapabilities() async {
    await initialize();
    return '';
  }

  Future<bool> activateRegisteredProviderCapability(String providerRef) async {
    await initialize();
    return false;
  }

  Future<bool> rollbackRegisteredProviderCapability(String providerRef) async {
    await initialize();
    return false;
  }

  Future<String> saveStorageProviderSettings({
    required String redisHost,
    required int redisPort,
    required String redisKeyPrefix,
    required String redisPassword,
    required String qdrantEndpoint,
    required String qdrantCollection,
    required int qdrantDimension,
    required String qdrantApiKey,
  }) async {
    await initialize();
    return '';
  }

  Future<Map<String, dynamic>> loadProviderRuntimeSettings() async => {
        'schema_version': 'prd_v3_provider_runtime_settings.v1',
        'workspace': '',
        'provider_crud_status': 'desktop_runtime_required',
        'llm': {
          'provider_id': 'env_configured',
          'model_id': 'local-default-or-configured-provider',
          'api_key_display': '************',
          'api_key_secret_ref': 'env:HEITANG_LLM_API_KEY',
          'status': 'desktop_runtime_required',
        },
        'model_gateway': {
          'gateway_id': 'gateway_not_configured',
          'display_name': '未配置 Model Gateway',
          'gateway_type': 'direct',
          'base_url': '',
          'api_key_ref': 'none',
          'admin_url': '',
          'supports_streaming': false,
          'supports_embeddings': false,
          'supports_fallback': false,
          'supports_usage_stats': false,
          'timeout_seconds': 30,
          'retry_policy': {
            'max_retries': 0,
            'retry_on': const <String>[],
          },
          'status': '需启动外部服务',
          'last_test_at': '',
          'last_error': '真实 Model Gateway 配置只能在 Windows EXE 中执行。',
          'masked_key_preview': '',
        },
        'embedding': {
          'provider_id': 'local_keyword_embedding',
          'status': 'desktop_runtime_required',
        },
        'search': {
          'provider_id': 'local_index',
          'network_required': false,
          'status': 'desktop_runtime_required',
        },
        'parser': {
          'provider_id': 'local_parser',
          'status': 'desktop_runtime_required',
        },
        'ocr': {
          'provider_id': 'optional_ocr',
          'status': 'desktop_runtime_required',
        },
        'secret_plaintext_written': false,
      };

  Future<Map<String, dynamic>> loadProviderCapabilityUserCatalog() async =>
      const <String, dynamic>{};

  Future<String> saveProviderRuntimeSettings({
    required String llmProvider,
    required String modelId,
    required String embeddingProvider,
    required String searchProvider,
    required String parserProvider,
    required String ocrProvider,
    required String apiKey,
  }) async {
    await initialize();
    return '';
  }

  Future<String> validateProviderRuntimeSettings() async {
    await initialize();
    return '';
  }

  Future<String> saveModelGatewayProviderConfig({
    required String displayName,
    required String gatewayType,
    required String baseUrl,
    required String credential,
    String adminUrl = '',
    bool supportsStreaming = true,
    bool supportsEmbeddings = false,
    bool supportsFallback = true,
    bool supportsUsageStats = true,
  }) async {
    await initialize();
    return '';
  }

  Future<String> testModelGatewayProvider({
    String simulatedStatus = 'success',
  }) async {
    await initialize();
    return '';
  }

  Future<Map<String, dynamic>> loadExporterSettings() async => {
        'schema_version': 'prd_v3_exporter_settings.v1',
        'workspace': '',
        'export_root': '',
        'exporters': {
          'markdown': {'provider': 'local_markdown', 'status': 'connected'},
          'json': {'provider': 'local_json', 'status': 'connected'},
          'csv': {'provider': 'local_csv', 'status': 'connected'},
          'txt': {'provider': 'builtin_local_txt', 'status': 'connected'},
          'docx': {
            'provider': 'builtin_local_docx',
            'status': 'desktop_runtime_required',
          },
          'pdf': {
            'provider': 'builtin_local_pdf',
            'status': 'desktop_runtime_required',
          },
          'pptx': {
            'provider': 'builtin_local_pptx',
            'status': 'desktop_runtime_required',
          },
          'xlsx': {'provider': 'builtin_local_xlsx', 'status': 'connected'},
        },
      };
  Future<String> saveExporterSettings({
    required String docxExporter,
    required String pdfExporter,
    required String pptxExporter,
    required String exportRoot,
  }) async {
    await initialize();
    return '';
  }

  Future<String> validateExporterSettings() async {
    await initialize();
    return '';
  }

  Future<String> runSettingsExportBasicAcceptance() async {
    await initialize();
    return '';
  }

  Future<String> runParallelTaskCapacityValidation({int taskCount = 8}) async {
    await initialize();
    return '';
  }

  Future<void> generateSkill({
    Rc6SkillGenerationConfig config = const Rc6SkillGenerationConfig(),
  }) async =>
      initialize();
  Future<void> runSkillOperation(String operation) async => initialize();
  Future<void> pickAndImportExternalSkill() async => initialize();
  Future<void> importExternalSkillPath(String path) async => initialize();
  Future<void> completeSkillProductOperations() async => initialize();
  Future<String> saveEditedSkill(String skillMarkdown) async {
    await initialize();
    return '';
  }

  Future<void> generateAgent({
    Rc6AgentGenerationConfig config = const Rc6AgentGenerationConfig(),
  }) async =>
      initialize();
  Future<void> completeAgentProductOperations({
    Rc6AgentGenerationConfig config = const Rc6AgentGenerationConfig(),
  }) async =>
      initialize();
  Future<void> runAgentDialogue({String prompt = '请基于当前知识库总结核心要点。'}) async =>
      initialize();
  Future<String> exportAgentDialogue() async {
    await initialize();
    return '';
  }

  Future<void> clearAgentDialogueHistory() async => initialize();

  Future<void> runMultiAgentDiscussion({
    String topic = '',
    List<String> participantAgentIds = const [],
  }) async =>
      initialize();
  Future<List<Rc6AgentProfile>> loadAgentProfiles() async {
    await initialize();
    return const <Rc6AgentProfile>[];
  }

  Future<Rc6AgentConversation> loadAgentConversation(String agentId) async {
    await initialize();
    return Rc6AgentConversation.empty(agentId);
  }

  Future<Rc6AgentProfile?> createAgentProfile({
    required String name,
    String description = '',
    String role = '',
    List<String> boundKnowledgeBaseIds = const [],
    List<String> boundSkillIds = const [],
    Map<String, String> settings = const {},
  }) async {
    await initialize();
    return null;
  }

  Future<Rc6AgentProfile?> updateAgentProfile({
    required String agentId,
    required String name,
    String description = '',
    String role = '',
    List<String> boundKnowledgeBaseIds = const [],
    List<String> boundSkillIds = const [],
    Map<String, String> settings = const {},
  }) async {
    await initialize();
    return null;
  }

  Future<void> deleteAgentProfile(String agentId) async => initialize();

  Future<Rc6AgentConversation> sendAgentMessage({
    required String agentId,
    required String content,
  }) async {
    await initialize();
    return Rc6AgentConversation.empty(agentId);
  }

  Future<String> saveAgentReplyToArtifact({
    required String agentId,
    required String messageId,
  }) async {
    await initialize();
    return '';
  }

  Future<void> runRealInputFolderE2E(String folderPath,
          {String query = '赚钱 小生意'}) async =>
      initialize();
  Future<void> runOwnerInputFolderE2E({String query = '赚钱 小生意'}) async =>
      initialize();
  Future<void> runPrdP0ProductE2E(String folderPath,
          {String query = '赚钱 小生意'}) async =>
      initialize();
  Future<void> runOwnerInputPrdP0E2E({String query = '赚钱 小生意'}) async =>
      initialize();
  Future<void> runDocumentFlowE2E(String folderPath,
          {String query = '赚钱 小生意'}) async =>
      initialize();
  Future<void> runOwnerInputDocumentFlowE2E({String query = '赚钱 小生意'}) async =>
      initialize();
  Future<void> runMinimumE2E({String query = 'heitang-rc6-needle'}) async =>
      initialize();
}

enum Rc6RuntimePhase {
  initial,
  ready,
  imported,
  documentUnderstanding,
  knowledgeBuilt,
  searched,
  documentGenerated,
  skillGenerated,
  agentGenerated,
  failed,
  blocked,
}

enum Rc6SearchStatus { idle, loading, success, empty, error }

class Rc6SearchResult {
  const Rc6SearchResult({
    required this.title,
    required this.excerpt,
    required this.citation,
    required this.score,
    this.kbId = '',
    this.kbName = '',
  });

  final String title;
  final String excerpt;
  final String citation;
  final String score;
  final String kbId;
  final String kbName;
}

class Rc6DocumentGenerationConfig {
  const Rc6DocumentGenerationConfig({
    this.generationType = 'reading_notes',
    this.outputFormat = 'md',
    this.citationStrategy = 'source_filename',
    this.templateMode = 'built_in',
  });

  final String generationType;
  final String outputFormat;
  final String citationStrategy;
  final String templateMode;
}

class Rc6SkillGenerationConfig {
  const Rc6SkillGenerationConfig({
    this.customSkillName = '',
    this.skillType = 'analysis',
    this.targetPlatform = 'codex',
    this.personalizationGoal = '',
  });

  final String customSkillName;
  final String skillType;
  final String targetPlatform;
  final String personalizationGoal;
}

class Rc6AgentGenerationConfig {
  const Rc6AgentGenerationConfig({
    this.customAgentName = '',
    this.creationMode = 'simple',
    this.agentType = 'knowledge_qa',
    this.modelConfigId = 'local-default-or-configured-provider',
    this.outputFormat = 'markdown',
    this.roleGoal = '只基于绑定知识库和 Skill 回答，输出必须带引用。',
  });

  final String customAgentName;
  final String creationMode;
  final String agentType;
  final String modelConfigId;
  final String outputFormat;
  final String roleGoal;
}

class Rc6AgentProfile {
  const Rc6AgentProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.workspaceId,
    required this.primaryKnowledgeBaseId,
    required this.allowedReferenceKbIds,
    required this.kbScopeMode,
    required this.answerPolicyId,
    required this.aiProfileId,
    required this.boundKnowledgeBaseIds,
    required this.boundSkillIds,
    required this.settings,
  });

  factory Rc6AgentProfile.fromJson(Map<String, dynamic> json) {
    return Rc6AgentProfile(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      status: (json['status'] ?? 'available').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      workspaceId: (json['workspace_id'] ?? '').toString(),
      primaryKnowledgeBaseId:
          (json['primary_knowledge_base_id'] ?? '').toString(),
      allowedReferenceKbIds: _stringList(json['allowed_reference_kb_ids']),
      kbScopeMode: (json['kb_scope_mode'] ??
              (_stringList(json['bound_knowledge_base_ids']).isEmpty
                  ? 'none'
                  : 'single'))
          .toString(),
      answerPolicyId:
          (json['answer_policy_id'] ?? 'strict_evidence').toString(),
      aiProfileId:
          (json['ai_profile_id'] ?? 'ai_profile_default_local').toString(),
      boundKnowledgeBaseIds: _stringList(json['bound_knowledge_base_ids']),
      boundSkillIds: _stringList(json['bound_skill_ids']),
      settings: _stringMap(json['settings']),
    );
  }

  final String id;
  final String name;
  final String description;
  final String role;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String workspaceId;
  final String primaryKnowledgeBaseId;
  final List<String> allowedReferenceKbIds;
  final String kbScopeMode;
  final String answerPolicyId;
  final String aiProfileId;
  final List<String> boundKnowledgeBaseIds;
  final List<String> boundSkillIds;
  final Map<String, String> settings;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'role': role,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'workspace_id': workspaceId,
        'primary_knowledge_base_id': primaryKnowledgeBaseId,
        'allowed_reference_kb_ids': allowedReferenceKbIds,
        'kb_scope_mode': kbScopeMode,
        'answer_policy_id': answerPolicyId,
        'ai_profile_id': aiProfileId,
        'bound_knowledge_base_ids': boundKnowledgeBaseIds,
        'bound_skill_ids': boundSkillIds,
        'settings': settings,
      };

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const <String, String>{};
    return value.map((key, item) => MapEntry(key.toString(), item.toString()));
  }
}

class Rc6AgentMessage {
  const Rc6AgentMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    required this.status,
    this.error = '',
  });

  factory Rc6AgentMessage.fromJson(Map<String, dynamic> json) {
    return Rc6AgentMessage(
      id: (json['id'] ?? '').toString(),
      role: (json['role'] ?? 'assistant').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      status: (json['status'] ?? 'saved').toString(),
      error: (json['error'] ?? '').toString(),
    );
  }

  final String id;
  final String role;
  final String content;
  final String createdAt;
  final String status;
  final String error;

  bool get isUser => role == 'user';

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'created_at': createdAt,
        'status': status,
        'error': error,
      };
}

class Rc6AgentConversation {
  const Rc6AgentConversation({
    required this.conversationId,
    required this.agentId,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rc6AgentConversation.empty(String agentId) {
    return Rc6AgentConversation(
      conversationId: 'conv_$agentId',
      agentId: agentId,
      messages: const <Rc6AgentMessage>[],
      createdAt: '',
      updatedAt: '',
    );
  }

  factory Rc6AgentConversation.fromJson(Map<String, dynamic> json) {
    final messages = json['messages'] is List
        ? (json['messages'] as List)
            .whereType<Map>()
            .map((item) =>
                Rc6AgentMessage.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <Rc6AgentMessage>[];
    return Rc6AgentConversation(
      conversationId: (json['conversation_id'] ?? '').toString(),
      agentId: (json['agent_id'] ?? '').toString(),
      messages: messages,
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
    );
  }

  final String conversationId;
  final String agentId;
  final List<Rc6AgentMessage> messages;
  final String createdAt;
  final String updatedAt;

  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'agent_id': agentId,
        'messages': messages.map((message) => message.toJson()).toList(),
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

class Rc6AgentArtifact {
  const Rc6AgentArtifact({
    required this.artifactId,
    required this.agentId,
    required this.agentName,
    required this.messageId,
    required this.path,
    required this.status,
    required this.createdAt,
  });

  factory Rc6AgentArtifact.fromJson(Map<String, dynamic> json) {
    return Rc6AgentArtifact(
      artifactId: (json['artifact_id'] ?? '').toString(),
      agentId: (json['agent_id'] ?? '').toString(),
      agentName: (json['agent_name'] ?? '').toString(),
      messageId: (json['message_id'] ?? '').toString(),
      path: (json['path'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }

  final String artifactId;
  final String agentId;
  final String agentName;
  final String messageId;
  final String path;
  final String status;
  final String createdAt;
}

class Rc6EventLedgerRecord {
  const Rc6EventLedgerRecord({
    required this.eventId,
    required this.eventType,
    required this.module,
    required this.action,
    required this.targetId,
    required this.targetName,
    required this.workspaceId,
    required this.status,
    required this.createdAt,
    required this.source,
    required this.artifactPath,
    required this.errorMessage,
    required this.metadata,
  });

  factory Rc6EventLedgerRecord.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : const <String, dynamic>{};
    return Rc6EventLedgerRecord(
      eventId: (json['event_id'] ?? '').toString(),
      eventType: (json['event_type'] ?? '').toString(),
      module: (json['module'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      targetId: (json['target_id'] ?? '').toString(),
      targetName: (json['target_name'] ?? '').toString(),
      workspaceId: (json['workspace_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      artifactPath: (json['artifact_path'] ?? '').toString(),
      errorMessage: (json['error_message'] ?? '').toString(),
      metadata: metadata,
    );
  }

  final String eventId;
  final String eventType;
  final String module;
  final String action;
  final String targetId;
  final String targetName;
  final String workspaceId;
  final String status;
  final String createdAt;
  final String source;
  final String artifactPath;
  final String errorMessage;
  final Map<String, dynamic> metadata;
}

class Rc6ArtifactRecord {
  const Rc6ArtifactRecord({
    required this.artifactId,
    required this.artifactType,
    required this.title,
    required this.sourceModule,
    required this.sourceId,
    required this.workspaceId,
    required this.filePath,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.metadata,
  });

  factory Rc6ArtifactRecord.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : const <String, dynamic>{};
    return Rc6ArtifactRecord(
      artifactId: (json['artifact_id'] ?? '').toString(),
      artifactType: (json['artifact_type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      sourceModule: (json['source_module'] ?? '').toString(),
      sourceId: (json['source_id'] ?? '').toString(),
      workspaceId: (json['workspace_id'] ?? '').toString(),
      filePath: (json['file_path'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      metadata: metadata,
    );
  }

  final String artifactId;
  final String artifactType;
  final String title;
  final String sourceModule;
  final String sourceId;
  final String workspaceId;
  final String filePath;
  final String createdAt;
  final String updatedAt;
  final String status;
  final Map<String, dynamic> metadata;

  bool get isActive => status != 'deleted' && filePath.trim().isNotEmpty;
}

class Rc6StorageTestResult {
  const Rc6StorageTestResult({
    required this.passed,
    required this.status,
    required this.detail,
  });

  final bool passed;
  final String status;
  final String detail;
}

class Rc6KnowledgeBaseRecord {
  const Rc6KnowledgeBaseRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.currentVersion,
    required this.versionCount,
    required this.sourceCount,
    required this.chunkCount,
    required this.manifestPath,
    required this.qualityReportPath,
    required this.versionComparePath,
    required this.operation,
  });

  final String id;
  final String name;
  final String type;
  final String status;
  final String currentVersion;
  final int versionCount;
  final int sourceCount;
  final int chunkCount;
  final String manifestPath;
  final String qualityReportPath;
  final String versionComparePath;
  final String operation;
}

class Rc6SourceRecord {
  const Rc6SourceRecord({
    required this.documentId,
    required this.sourceName,
    required this.relativePath,
    required this.sourceType,
    required this.extension,
    required this.sizeBytes,
    required this.wordCount,
    required this.imageCount,
    required this.tableCount,
    required this.linkCount,
    required this.structureStatus,
  });

  final String documentId;
  final String sourceName;
  final String relativePath;
  final String sourceType;
  final String extension;
  final int sizeBytes;
  final int wordCount;
  final int imageCount;
  final int tableCount;
  final int linkCount;
  final String structureStatus;
}

class Rc6RuntimeState {
  const Rc6RuntimeState({
    required this.phase,
    required this.running,
    required this.workspacePath,
    required this.selectedFilePath,
    required this.sourceManifestPath,
    required this.parseReportPath,
    required this.standardKnowledgePackagePath,
    required this.standardKnowledgePackageManifestPath,
    required this.standardKnowledgePackageContentPath,
    required this.standardKnowledgePackageAuditPath,
    required this.chunksPath,
    required this.kbManifestPath,
    required this.qualityReportPath,
    required this.cardsPath,
    required this.qaPairsPath,
    required this.sourceMapPath,
    required this.indexMetadataPath,
    required this.indexProfilePath,
    required this.keywordIndexPath,
    required this.vectorIndexReferencePath,
    required this.metadataIndexPath,
    required this.citationIndexPath,
    required this.memoryIndexReferencePath,
    required this.indexBuildReportPath,
    required this.buildLogPath,
    required this.errorLogPath,
    required this.queryResultPath,
    required this.retrievalPlanPath,
    required this.retrievalRerankReportPath,
    required this.retrievalCitationCoveragePath,
    required this.retrievalConflictReportPath,
    required this.externalValidationBoundaryPath,
    required this.retrievalValidationReportPath,
    required this.retrievalValidationMarkdownPath,
    required this.retrievalValidationHistoryPath,
    required this.generatedMarkdownPath,
    required this.readingNotesPath,
    required this.editedDocumentPath,
    required this.editManifestPath,
    required this.documentOutlinePath,
    required this.documentCitationsPath,
    required this.documentValidationReportPath,
    required this.exportedDocumentPath,
    required this.exportManifestPath,
    required this.documentGenerationHistoryCount,
    required this.skillVersionCount,
    required this.skillPath,
    required this.primarySkillPath,
    required this.skillConfigPath,
    required this.skillVerificationReportPath,
    required this.skillGenerationManifestPath,
    required this.skillPackageManifestPath,
    required this.skillValidationReportPath,
    required this.localizedSkillManifestPath,
    required this.localizedSkillDiffPath,
    required this.skillVersionManifestPath,
    required this.skillOperationManifestPath,
    required this.skillOperationHistoryPath,
    required this.skillFactoryAuditPath,
    required this.skillExportPath,
    required this.skillAgentBindingManifestPath,
    required this.skillOperationStatus,
    required this.skillAgentBindingStatus,
    required this.agentPath,
    required this.primaryAgentManifestPath,
    required this.agentProfilePath,
    required this.agentGenerationManifestPath,
    required this.agentAdvancedConfigPath,
    required this.agentPermissionAuditPath,
    required this.agentWorkspacePermissionMatrixPath,
    required this.agentValidationReportPath,
    required this.agentPackageManifestPath,
    required this.agentPackageReadmePath,
    required this.agentDialoguePath,
    required this.agentDialogueManifestPath,
    required this.agentDialogueHistoryPath,
    required this.agentDialogueExportPath,
    required this.agentDialogueTurnCount,
    required this.agentDialogueModelConfigId,
    required this.agentDialogueUsedKbIds,
    required this.agentDialogueUsedSkillIds,
    required this.agentDialogueOutputFormat,
    required this.agentDialogueEvidenceCount,
    required this.agentDialogueMemoryWriteStatus,
    required this.agentDialogueErrorMessage,
    required this.multiAgentDiscussionPath,
    required this.multiAgentDiscussionManifestPath,
    required this.a2aSessionManifestPath,
    required this.a2aWorkspaceReportPath,
    required this.a2aConflictReportPath,
    required this.a2aConsensusReportPath,
    required this.a2aSessionId,
    required this.a2aTopic,
    required this.a2aParticipantAgentIds,
    required this.a2aEvidenceCount,
    required this.a2aStatus,
    required this.prdP0EvidencePath,
    required this.providerRuntimeSettingsPath,
    required this.storageProviderSettingsPath,
    required this.providerValidationReportPath,
    required this.providerLifecycleAuditSummaryPath,
    required this.providerCapabilityUserCatalogPath,
    required this.exporterValidationReportPath,
    required this.parallelTaskCapacityReportPath,
    required this.taskIsolationMatrixPath,
    required this.taskRecoveryReportPath,
    required this.knowledgeBaseCatalogPath,
    required this.workbookManifestPath,
    required this.currentWorkbookName,
    required this.workbookNames,
    required this.knowledgeBases,
    required this.agentProfiles,
    required this.agentConversations,
    required this.agentArtifacts,
    required this.agentActivityLogPath,
    required this.agentArtifactCatalogPath,
    required this.eventLedgerPath,
    required this.eventLedgerRecords,
    required this.artifactCatalogPath,
    required this.artifactRecords,
    required this.sourceCount,
    required this.sourceNames,
    required this.sourceRecords,
    required this.chunkCount,
    required this.searchQuery,
    required this.searchStatus,
    required this.searchResults,
    required this.lastMessage,
    required this.lastError,
    required this.lastResult,
  });

  factory Rc6RuntimeState.initial() => const Rc6RuntimeState(
        phase: Rc6RuntimePhase.initial,
        running: false,
        workspacePath: '',
        selectedFilePath: '',
        sourceManifestPath: '',
        parseReportPath: '',
        standardKnowledgePackagePath: '',
        standardKnowledgePackageManifestPath: '',
        standardKnowledgePackageContentPath: '',
        standardKnowledgePackageAuditPath: '',
        chunksPath: '',
        kbManifestPath: '',
        qualityReportPath: '',
        cardsPath: '',
        qaPairsPath: '',
        sourceMapPath: '',
        indexMetadataPath: '',
        indexProfilePath: '',
        keywordIndexPath: '',
        vectorIndexReferencePath: '',
        metadataIndexPath: '',
        citationIndexPath: '',
        memoryIndexReferencePath: '',
        indexBuildReportPath: '',
        buildLogPath: '',
        errorLogPath: '',
        queryResultPath: '',
        retrievalPlanPath: '',
        retrievalRerankReportPath: '',
        retrievalCitationCoveragePath: '',
        retrievalConflictReportPath: '',
        externalValidationBoundaryPath: '',
        retrievalValidationReportPath: '',
        retrievalValidationMarkdownPath: '',
        retrievalValidationHistoryPath: '',
        generatedMarkdownPath: '',
        readingNotesPath: '',
        editedDocumentPath: '',
        editManifestPath: '',
        documentOutlinePath: '',
        documentCitationsPath: '',
        documentValidationReportPath: '',
        exportedDocumentPath: '',
        exportManifestPath: '',
        documentGenerationHistoryCount: 0,
        skillVersionCount: 0,
        skillPath: '',
        primarySkillPath: '',
        skillConfigPath: '',
        skillVerificationReportPath: '',
        skillGenerationManifestPath: '',
        skillPackageManifestPath: '',
        skillValidationReportPath: '',
        localizedSkillManifestPath: '',
        localizedSkillDiffPath: '',
        skillVersionManifestPath: '',
        skillOperationManifestPath: '',
        skillOperationHistoryPath: '',
        skillFactoryAuditPath: '',
        skillExportPath: '',
        skillAgentBindingManifestPath: '',
        skillOperationStatus: '',
        skillAgentBindingStatus: '',
        agentPath: '',
        primaryAgentManifestPath: '',
        agentProfilePath: '',
        agentGenerationManifestPath: '',
        agentAdvancedConfigPath: '',
        agentPermissionAuditPath: '',
        agentWorkspacePermissionMatrixPath: '',
        agentValidationReportPath: '',
        agentPackageManifestPath: '',
        agentPackageReadmePath: '',
        agentDialoguePath: '',
        agentDialogueManifestPath: '',
        agentDialogueHistoryPath: '',
        agentDialogueExportPath: '',
        agentDialogueTurnCount: 0,
        agentDialogueModelConfigId: '',
        agentDialogueUsedKbIds: [],
        agentDialogueUsedSkillIds: [],
        agentDialogueOutputFormat: '',
        agentDialogueEvidenceCount: 0,
        agentDialogueMemoryWriteStatus: '',
        agentDialogueErrorMessage: '',
        multiAgentDiscussionPath: '',
        multiAgentDiscussionManifestPath: '',
        a2aSessionManifestPath: '',
        a2aWorkspaceReportPath: '',
        a2aConflictReportPath: '',
        a2aConsensusReportPath: '',
        a2aSessionId: '',
        a2aTopic: '',
        a2aParticipantAgentIds: [],
        a2aEvidenceCount: 0,
        a2aStatus: '',
        prdP0EvidencePath: '',
        providerRuntimeSettingsPath: '',
        storageProviderSettingsPath: '',
        providerValidationReportPath: '',
        providerLifecycleAuditSummaryPath: '',
        providerCapabilityUserCatalogPath: '',
        exporterValidationReportPath: '',
        parallelTaskCapacityReportPath: '',
        taskIsolationMatrixPath: '',
        taskRecoveryReportPath: '',
        knowledgeBaseCatalogPath: '',
        workbookManifestPath: '',
        currentWorkbookName: '默认工作本',
        workbookNames: ['默认工作本'],
        knowledgeBases: [],
        agentProfiles: [],
        agentConversations: [],
        agentArtifacts: [],
        agentActivityLogPath: '',
        agentArtifactCatalogPath: '',
        eventLedgerPath: '',
        eventLedgerRecords: [],
        artifactCatalogPath: '',
        artifactRecords: [],
        sourceCount: 0,
        sourceNames: [],
        sourceRecords: [],
        chunkCount: 0,
        searchQuery: '',
        searchStatus: Rc6SearchStatus.idle,
        searchResults: [],
        lastMessage: '等待初始化。',
        lastError: '',
        lastResult: null,
      );

  final Rc6RuntimePhase phase;
  final bool running;
  final String workspacePath;
  final String selectedFilePath;
  final String sourceManifestPath;
  final String parseReportPath;
  final String standardKnowledgePackagePath;
  final String standardKnowledgePackageManifestPath;
  final String standardKnowledgePackageContentPath;
  final String standardKnowledgePackageAuditPath;
  final String chunksPath;
  final String kbManifestPath;
  final String qualityReportPath;
  final String cardsPath;
  final String qaPairsPath;
  final String sourceMapPath;
  final String indexMetadataPath;
  final String indexProfilePath;
  final String keywordIndexPath;
  final String vectorIndexReferencePath;
  final String metadataIndexPath;
  final String citationIndexPath;
  final String memoryIndexReferencePath;
  final String indexBuildReportPath;
  final String buildLogPath;
  final String errorLogPath;
  final String queryResultPath;
  final String retrievalPlanPath;
  final String retrievalRerankReportPath;
  final String retrievalCitationCoveragePath;
  final String retrievalConflictReportPath;
  final String externalValidationBoundaryPath;
  final String retrievalValidationReportPath;
  final String retrievalValidationMarkdownPath;
  final String retrievalValidationHistoryPath;
  final String generatedMarkdownPath;
  final String readingNotesPath;
  final String editedDocumentPath;
  final String editManifestPath;
  final String documentOutlinePath;
  final String documentCitationsPath;
  final String documentValidationReportPath;
  final String exportedDocumentPath;
  final String exportManifestPath;
  final int documentGenerationHistoryCount;
  final int skillVersionCount;
  final String skillPath;
  final String primarySkillPath;
  final String skillConfigPath;
  final String skillVerificationReportPath;
  final String skillGenerationManifestPath;
  final String skillPackageManifestPath;
  final String skillValidationReportPath;
  final String localizedSkillManifestPath;
  final String localizedSkillDiffPath;
  final String skillVersionManifestPath;
  final String skillOperationManifestPath;
  final String skillOperationHistoryPath;
  final String skillFactoryAuditPath;
  final String skillExportPath;
  final String skillAgentBindingManifestPath;
  final String skillOperationStatus;
  final String skillAgentBindingStatus;
  final String agentPath;
  final String primaryAgentManifestPath;
  final String agentProfilePath;
  final String agentGenerationManifestPath;
  final String agentAdvancedConfigPath;
  final String agentPermissionAuditPath;
  final String agentWorkspacePermissionMatrixPath;
  final String agentValidationReportPath;
  final String agentPackageManifestPath;
  final String agentPackageReadmePath;
  final String agentDialoguePath;
  final String agentDialogueManifestPath;
  final String agentDialogueHistoryPath;
  final String agentDialogueExportPath;
  final int agentDialogueTurnCount;
  final String agentDialogueModelConfigId;
  final List<String> agentDialogueUsedKbIds;
  final List<String> agentDialogueUsedSkillIds;
  final String agentDialogueOutputFormat;
  final int agentDialogueEvidenceCount;
  final String agentDialogueMemoryWriteStatus;
  final String agentDialogueErrorMessage;
  final String multiAgentDiscussionPath;
  final String multiAgentDiscussionManifestPath;
  final String a2aSessionManifestPath;
  final String a2aWorkspaceReportPath;
  final String a2aConflictReportPath;
  final String a2aConsensusReportPath;
  final String a2aSessionId;
  final String a2aTopic;
  final List<String> a2aParticipantAgentIds;
  final int a2aEvidenceCount;
  final String a2aStatus;
  final String prdP0EvidencePath;
  final String providerRuntimeSettingsPath;
  final String storageProviderSettingsPath;
  final String providerValidationReportPath;
  final String providerLifecycleAuditSummaryPath;
  final String providerCapabilityUserCatalogPath;
  final String exporterValidationReportPath;
  final String parallelTaskCapacityReportPath;
  final String taskIsolationMatrixPath;
  final String taskRecoveryReportPath;
  final String knowledgeBaseCatalogPath;
  final String workbookManifestPath;
  final String currentWorkbookName;
  final List<String> workbookNames;
  final List<Rc6KnowledgeBaseRecord> knowledgeBases;
  final List<Rc6AgentProfile> agentProfiles;
  final List<Rc6AgentConversation> agentConversations;
  final List<Rc6AgentArtifact> agentArtifacts;
  final String agentActivityLogPath;
  final String agentArtifactCatalogPath;
  final String eventLedgerPath;
  final List<Rc6EventLedgerRecord> eventLedgerRecords;
  final String artifactCatalogPath;
  final List<Rc6ArtifactRecord> artifactRecords;
  final int sourceCount;
  final List<String> sourceNames;
  final List<Rc6SourceRecord> sourceRecords;
  final int chunkCount;
  final String searchQuery;
  final Rc6SearchStatus searchStatus;
  final List<Rc6SearchResult> searchResults;
  final String lastMessage;
  final String lastError;
  final CoreBridgeResult? lastResult;

  bool get hasImportedFile => sourceManifestPath.isNotEmpty;
  bool get hasStandardKnowledgePackage =>
      standardKnowledgePackageManifestPath.isNotEmpty &&
      standardKnowledgePackageContentPath.isNotEmpty;
  bool get hasKnowledgeBase => kbManifestPath.isNotEmpty && chunkCount > 0;
  bool get hasMarkdown => generatedMarkdownPath.isNotEmpty;
  bool get hasReadingNotes => readingNotesPath.isNotEmpty;
  bool get hasEditedDocument => editedDocumentPath.isNotEmpty;
  bool get hasExportedDocument => exportedDocumentPath.isNotEmpty;
  bool get hasDocumentGenerationHistory => documentGenerationHistoryCount > 0;
  bool get hasSkill => skillPath.isNotEmpty;
  bool get hasPrimarySkill => primarySkillPath.isNotEmpty;
  bool get hasSkillConfig => skillConfigPath.isNotEmpty;
  bool get hasSkillVerificationReport => skillVerificationReportPath.isNotEmpty;
  bool get hasSkillGenerationManifest => skillGenerationManifestPath.isNotEmpty;
  bool get hasSkillPackageManifest => skillPackageManifestPath.isNotEmpty;
  bool get hasSkillValidationReport => skillValidationReportPath.isNotEmpty;
  bool get hasLocalizedSkillManifest => localizedSkillManifestPath.isNotEmpty;
  bool get hasLocalizedSkillDiff => localizedSkillDiffPath.isNotEmpty;
  bool get hasSkillVersions => skillVersionCount > 0;
  bool get hasSkillVersionManifest => skillVersionManifestPath.isNotEmpty;
  bool get hasSkillOperationManifest => skillOperationManifestPath.isNotEmpty;
  bool get hasSkillOperationHistory => skillOperationHistoryPath.isNotEmpty;
  bool get hasSkillExport => skillExportPath.isNotEmpty;
  bool get hasSkillAgentBindingManifest =>
      skillAgentBindingManifestPath.isNotEmpty;
  bool get hasAgent => agentPath.isNotEmpty;
  bool get hasPrimaryAgentManifest => primaryAgentManifestPath.isNotEmpty;
  bool get hasAgentProfile => agentProfilePath.isNotEmpty;
  bool get hasAgentGenerationManifest => agentGenerationManifestPath.isNotEmpty;
  bool get hasAgentAdvancedConfig => agentAdvancedConfigPath.isNotEmpty;
  bool get hasAgentPermissionAudit => agentPermissionAuditPath.isNotEmpty;
  bool get hasAgentWorkspacePermissionMatrix =>
      agentWorkspacePermissionMatrixPath.isNotEmpty;
  bool get hasAgentValidationReport => agentValidationReportPath.isNotEmpty;
  bool get hasAgentPackageManifest => agentPackageManifestPath.isNotEmpty;
  bool get hasAgentPackageReadme => agentPackageReadmePath.isNotEmpty;
  bool get hasAgentDialogue => agentDialoguePath.isNotEmpty;
  bool get hasAgentDialogueManifest => agentDialogueManifestPath.isNotEmpty;
  bool get hasAgentDialogueHistory => agentDialogueHistoryPath.isNotEmpty;
  bool get hasAgentDialogueExport => agentDialogueExportPath.isNotEmpty;
  bool get hasMultiAgentDiscussion => multiAgentDiscussionPath.isNotEmpty;
  bool get hasMultiAgentDiscussionManifest =>
      multiAgentDiscussionManifestPath.isNotEmpty;
  bool get hasA2aSessionManifest => a2aSessionManifestPath.isNotEmpty;
  bool get hasA2aConflictReport => a2aConflictReportPath.isNotEmpty;
  bool get hasA2aConsensusReport => a2aConsensusReportPath.isNotEmpty;
  bool get hasPrdP0Evidence => prdP0EvidencePath.isNotEmpty;
  bool get hasProviderRuntimeSettings => providerRuntimeSettingsPath.isNotEmpty;
  bool get hasProviderValidationReport =>
      providerValidationReportPath.isNotEmpty;
  bool get hasProviderLifecycleAuditSummary =>
      providerLifecycleAuditSummaryPath.isNotEmpty;
  bool get hasProviderCapabilityUserCatalog =>
      providerCapabilityUserCatalogPath.isNotEmpty;
  bool get hasParallelTaskCapacityReport =>
      parallelTaskCapacityReportPath.isNotEmpty;
  bool get hasKnowledgeBaseCatalog => knowledgeBaseCatalogPath.isNotEmpty;
  bool get hasWorkbookManifest => workbookManifestPath.isNotEmpty;
  bool get hasAgentProfiles => agentProfiles.isNotEmpty;
  bool get hasAgentArtifacts => agentArtifacts.isNotEmpty;
  bool get hasAgentActivityLog => agentActivityLogPath.isNotEmpty;
  bool get hasAgentArtifactCatalog => agentArtifactCatalogPath.isNotEmpty;
  bool get hasEventLedger => eventLedgerPath.isNotEmpty;
  bool get hasEventLedgerRecords => eventLedgerRecords.isNotEmpty;
  bool get hasArtifactCatalog => artifactCatalogPath.isNotEmpty;
  bool get hasArtifactRecords => artifactRecords.any((item) => item.isActive);

  Rc6RuntimeState copyWith({
    Rc6RuntimePhase? phase,
    bool? running,
    String? workspacePath,
    String? selectedFilePath,
    String? sourceManifestPath,
    String? parseReportPath,
    String? standardKnowledgePackagePath,
    String? standardKnowledgePackageManifestPath,
    String? standardKnowledgePackageContentPath,
    String? standardKnowledgePackageAuditPath,
    String? chunksPath,
    String? kbManifestPath,
    String? qualityReportPath,
    String? cardsPath,
    String? qaPairsPath,
    String? sourceMapPath,
    String? indexMetadataPath,
    String? indexProfilePath,
    String? keywordIndexPath,
    String? vectorIndexReferencePath,
    String? metadataIndexPath,
    String? citationIndexPath,
    String? memoryIndexReferencePath,
    String? indexBuildReportPath,
    String? buildLogPath,
    String? errorLogPath,
    String? queryResultPath,
    String? retrievalPlanPath,
    String? retrievalRerankReportPath,
    String? retrievalCitationCoveragePath,
    String? retrievalConflictReportPath,
    String? externalValidationBoundaryPath,
    String? retrievalValidationReportPath,
    String? retrievalValidationMarkdownPath,
    String? retrievalValidationHistoryPath,
    String? generatedMarkdownPath,
    String? readingNotesPath,
    String? editedDocumentPath,
    String? editManifestPath,
    String? documentOutlinePath,
    String? documentCitationsPath,
    String? documentValidationReportPath,
    String? exportedDocumentPath,
    String? exportManifestPath,
    int? documentGenerationHistoryCount,
    int? skillVersionCount,
    String? skillPath,
    String? primarySkillPath,
    String? skillConfigPath,
    String? skillVerificationReportPath,
    String? skillGenerationManifestPath,
    String? skillPackageManifestPath,
    String? skillValidationReportPath,
    String? localizedSkillManifestPath,
    String? localizedSkillDiffPath,
    String? skillVersionManifestPath,
    String? skillOperationManifestPath,
    String? skillOperationHistoryPath,
    String? skillFactoryAuditPath,
    String? skillExportPath,
    String? skillAgentBindingManifestPath,
    String? skillOperationStatus,
    String? skillAgentBindingStatus,
    String? agentPath,
    String? primaryAgentManifestPath,
    String? agentProfilePath,
    String? agentGenerationManifestPath,
    String? agentAdvancedConfigPath,
    String? agentPermissionAuditPath,
    String? agentWorkspacePermissionMatrixPath,
    String? agentValidationReportPath,
    String? agentPackageManifestPath,
    String? agentPackageReadmePath,
    String? agentDialoguePath,
    String? agentDialogueManifestPath,
    String? agentDialogueHistoryPath,
    String? agentDialogueExportPath,
    int? agentDialogueTurnCount,
    String? agentDialogueModelConfigId,
    List<String>? agentDialogueUsedKbIds,
    List<String>? agentDialogueUsedSkillIds,
    String? agentDialogueOutputFormat,
    int? agentDialogueEvidenceCount,
    String? agentDialogueMemoryWriteStatus,
    String? agentDialogueErrorMessage,
    String? multiAgentDiscussionPath,
    String? multiAgentDiscussionManifestPath,
    String? a2aSessionManifestPath,
    String? a2aWorkspaceReportPath,
    String? a2aConflictReportPath,
    String? a2aConsensusReportPath,
    String? a2aSessionId,
    String? a2aTopic,
    List<String>? a2aParticipantAgentIds,
    int? a2aEvidenceCount,
    String? a2aStatus,
    String? prdP0EvidencePath,
    String? providerRuntimeSettingsPath,
    String? storageProviderSettingsPath,
    String? providerValidationReportPath,
    String? providerLifecycleAuditSummaryPath,
    String? providerCapabilityUserCatalogPath,
    String? exporterValidationReportPath,
    String? parallelTaskCapacityReportPath,
    String? taskIsolationMatrixPath,
    String? taskRecoveryReportPath,
    String? knowledgeBaseCatalogPath,
    String? workbookManifestPath,
    String? currentWorkbookName,
    List<String>? workbookNames,
    List<Rc6KnowledgeBaseRecord>? knowledgeBases,
    List<Rc6AgentProfile>? agentProfiles,
    List<Rc6AgentConversation>? agentConversations,
    List<Rc6AgentArtifact>? agentArtifacts,
    String? agentActivityLogPath,
    String? agentArtifactCatalogPath,
    String? eventLedgerPath,
    List<Rc6EventLedgerRecord>? eventLedgerRecords,
    String? artifactCatalogPath,
    List<Rc6ArtifactRecord>? artifactRecords,
    int? sourceCount,
    List<String>? sourceNames,
    List<Rc6SourceRecord>? sourceRecords,
    int? chunkCount,
    String? searchQuery,
    Rc6SearchStatus? searchStatus,
    List<Rc6SearchResult>? searchResults,
    String? lastMessage,
    String? lastError,
    CoreBridgeResult? lastResult,
  }) {
    return Rc6RuntimeState(
      phase: phase ?? this.phase,
      running: running ?? this.running,
      workspacePath: workspacePath ?? this.workspacePath,
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
      sourceManifestPath: sourceManifestPath ?? this.sourceManifestPath,
      parseReportPath: parseReportPath ?? this.parseReportPath,
      standardKnowledgePackagePath:
          standardKnowledgePackagePath ?? this.standardKnowledgePackagePath,
      standardKnowledgePackageManifestPath:
          standardKnowledgePackageManifestPath ??
              this.standardKnowledgePackageManifestPath,
      standardKnowledgePackageContentPath:
          standardKnowledgePackageContentPath ??
              this.standardKnowledgePackageContentPath,
      standardKnowledgePackageAuditPath: standardKnowledgePackageAuditPath ??
          this.standardKnowledgePackageAuditPath,
      chunksPath: chunksPath ?? this.chunksPath,
      kbManifestPath: kbManifestPath ?? this.kbManifestPath,
      qualityReportPath: qualityReportPath ?? this.qualityReportPath,
      cardsPath: cardsPath ?? this.cardsPath,
      qaPairsPath: qaPairsPath ?? this.qaPairsPath,
      sourceMapPath: sourceMapPath ?? this.sourceMapPath,
      indexMetadataPath: indexMetadataPath ?? this.indexMetadataPath,
      indexProfilePath: indexProfilePath ?? this.indexProfilePath,
      keywordIndexPath: keywordIndexPath ?? this.keywordIndexPath,
      vectorIndexReferencePath:
          vectorIndexReferencePath ?? this.vectorIndexReferencePath,
      metadataIndexPath: metadataIndexPath ?? this.metadataIndexPath,
      citationIndexPath: citationIndexPath ?? this.citationIndexPath,
      memoryIndexReferencePath:
          memoryIndexReferencePath ?? this.memoryIndexReferencePath,
      indexBuildReportPath: indexBuildReportPath ?? this.indexBuildReportPath,
      buildLogPath: buildLogPath ?? this.buildLogPath,
      errorLogPath: errorLogPath ?? this.errorLogPath,
      queryResultPath: queryResultPath ?? this.queryResultPath,
      retrievalPlanPath: retrievalPlanPath ?? this.retrievalPlanPath,
      retrievalRerankReportPath:
          retrievalRerankReportPath ?? this.retrievalRerankReportPath,
      retrievalCitationCoveragePath:
          retrievalCitationCoveragePath ?? this.retrievalCitationCoveragePath,
      retrievalConflictReportPath:
          retrievalConflictReportPath ?? this.retrievalConflictReportPath,
      externalValidationBoundaryPath:
          externalValidationBoundaryPath ?? this.externalValidationBoundaryPath,
      retrievalValidationReportPath:
          retrievalValidationReportPath ?? this.retrievalValidationReportPath,
      retrievalValidationMarkdownPath: retrievalValidationMarkdownPath ??
          this.retrievalValidationMarkdownPath,
      retrievalValidationHistoryPath:
          retrievalValidationHistoryPath ?? this.retrievalValidationHistoryPath,
      generatedMarkdownPath:
          generatedMarkdownPath ?? this.generatedMarkdownPath,
      readingNotesPath: readingNotesPath ?? this.readingNotesPath,
      editedDocumentPath: editedDocumentPath ?? this.editedDocumentPath,
      editManifestPath: editManifestPath ?? this.editManifestPath,
      documentOutlinePath: documentOutlinePath ?? this.documentOutlinePath,
      documentCitationsPath:
          documentCitationsPath ?? this.documentCitationsPath,
      documentValidationReportPath:
          documentValidationReportPath ?? this.documentValidationReportPath,
      exportedDocumentPath: exportedDocumentPath ?? this.exportedDocumentPath,
      exportManifestPath: exportManifestPath ?? this.exportManifestPath,
      documentGenerationHistoryCount:
          documentGenerationHistoryCount ?? this.documentGenerationHistoryCount,
      skillVersionCount: skillVersionCount ?? this.skillVersionCount,
      skillPath: skillPath ?? this.skillPath,
      primarySkillPath: primarySkillPath ?? this.primarySkillPath,
      skillConfigPath: skillConfigPath ?? this.skillConfigPath,
      skillVerificationReportPath:
          skillVerificationReportPath ?? this.skillVerificationReportPath,
      skillGenerationManifestPath:
          skillGenerationManifestPath ?? this.skillGenerationManifestPath,
      skillPackageManifestPath:
          skillPackageManifestPath ?? this.skillPackageManifestPath,
      skillValidationReportPath:
          skillValidationReportPath ?? this.skillValidationReportPath,
      localizedSkillManifestPath:
          localizedSkillManifestPath ?? this.localizedSkillManifestPath,
      localizedSkillDiffPath:
          localizedSkillDiffPath ?? this.localizedSkillDiffPath,
      skillVersionManifestPath:
          skillVersionManifestPath ?? this.skillVersionManifestPath,
      skillOperationManifestPath:
          skillOperationManifestPath ?? this.skillOperationManifestPath,
      skillOperationHistoryPath:
          skillOperationHistoryPath ?? this.skillOperationHistoryPath,
      skillFactoryAuditPath:
          skillFactoryAuditPath ?? this.skillFactoryAuditPath,
      skillExportPath: skillExportPath ?? this.skillExportPath,
      skillAgentBindingManifestPath:
          skillAgentBindingManifestPath ?? this.skillAgentBindingManifestPath,
      skillOperationStatus: skillOperationStatus ?? this.skillOperationStatus,
      skillAgentBindingStatus:
          skillAgentBindingStatus ?? this.skillAgentBindingStatus,
      agentPath: agentPath ?? this.agentPath,
      primaryAgentManifestPath:
          primaryAgentManifestPath ?? this.primaryAgentManifestPath,
      agentProfilePath: agentProfilePath ?? this.agentProfilePath,
      agentGenerationManifestPath:
          agentGenerationManifestPath ?? this.agentGenerationManifestPath,
      agentAdvancedConfigPath:
          agentAdvancedConfigPath ?? this.agentAdvancedConfigPath,
      agentPermissionAuditPath:
          agentPermissionAuditPath ?? this.agentPermissionAuditPath,
      agentWorkspacePermissionMatrixPath: agentWorkspacePermissionMatrixPath ??
          this.agentWorkspacePermissionMatrixPath,
      agentValidationReportPath:
          agentValidationReportPath ?? this.agentValidationReportPath,
      agentPackageManifestPath:
          agentPackageManifestPath ?? this.agentPackageManifestPath,
      agentPackageReadmePath:
          agentPackageReadmePath ?? this.agentPackageReadmePath,
      agentDialoguePath: agentDialoguePath ?? this.agentDialoguePath,
      agentDialogueManifestPath:
          agentDialogueManifestPath ?? this.agentDialogueManifestPath,
      agentDialogueHistoryPath:
          agentDialogueHistoryPath ?? this.agentDialogueHistoryPath,
      agentDialogueExportPath:
          agentDialogueExportPath ?? this.agentDialogueExportPath,
      agentDialogueTurnCount:
          agentDialogueTurnCount ?? this.agentDialogueTurnCount,
      agentDialogueModelConfigId:
          agentDialogueModelConfigId ?? this.agentDialogueModelConfigId,
      agentDialogueUsedKbIds:
          agentDialogueUsedKbIds ?? this.agentDialogueUsedKbIds,
      agentDialogueUsedSkillIds:
          agentDialogueUsedSkillIds ?? this.agentDialogueUsedSkillIds,
      agentDialogueOutputFormat:
          agentDialogueOutputFormat ?? this.agentDialogueOutputFormat,
      agentDialogueEvidenceCount:
          agentDialogueEvidenceCount ?? this.agentDialogueEvidenceCount,
      agentDialogueMemoryWriteStatus:
          agentDialogueMemoryWriteStatus ?? this.agentDialogueMemoryWriteStatus,
      agentDialogueErrorMessage:
          agentDialogueErrorMessage ?? this.agentDialogueErrorMessage,
      multiAgentDiscussionPath:
          multiAgentDiscussionPath ?? this.multiAgentDiscussionPath,
      multiAgentDiscussionManifestPath: multiAgentDiscussionManifestPath ??
          this.multiAgentDiscussionManifestPath,
      a2aSessionManifestPath:
          a2aSessionManifestPath ?? this.a2aSessionManifestPath,
      a2aWorkspaceReportPath:
          a2aWorkspaceReportPath ?? this.a2aWorkspaceReportPath,
      a2aConflictReportPath:
          a2aConflictReportPath ?? this.a2aConflictReportPath,
      a2aConsensusReportPath:
          a2aConsensusReportPath ?? this.a2aConsensusReportPath,
      a2aSessionId: a2aSessionId ?? this.a2aSessionId,
      a2aTopic: a2aTopic ?? this.a2aTopic,
      a2aParticipantAgentIds:
          a2aParticipantAgentIds ?? this.a2aParticipantAgentIds,
      a2aEvidenceCount: a2aEvidenceCount ?? this.a2aEvidenceCount,
      a2aStatus: a2aStatus ?? this.a2aStatus,
      prdP0EvidencePath: prdP0EvidencePath ?? this.prdP0EvidencePath,
      providerRuntimeSettingsPath:
          providerRuntimeSettingsPath ?? this.providerRuntimeSettingsPath,
      storageProviderSettingsPath:
          storageProviderSettingsPath ?? this.storageProviderSettingsPath,
      providerValidationReportPath:
          providerValidationReportPath ?? this.providerValidationReportPath,
      providerLifecycleAuditSummaryPath: providerLifecycleAuditSummaryPath ??
          this.providerLifecycleAuditSummaryPath,
      providerCapabilityUserCatalogPath: providerCapabilityUserCatalogPath ??
          this.providerCapabilityUserCatalogPath,
      exporterValidationReportPath:
          exporterValidationReportPath ?? this.exporterValidationReportPath,
      parallelTaskCapacityReportPath:
          parallelTaskCapacityReportPath ?? this.parallelTaskCapacityReportPath,
      taskIsolationMatrixPath:
          taskIsolationMatrixPath ?? this.taskIsolationMatrixPath,
      taskRecoveryReportPath:
          taskRecoveryReportPath ?? this.taskRecoveryReportPath,
      knowledgeBaseCatalogPath:
          knowledgeBaseCatalogPath ?? this.knowledgeBaseCatalogPath,
      workbookManifestPath: workbookManifestPath ?? this.workbookManifestPath,
      currentWorkbookName: currentWorkbookName ?? this.currentWorkbookName,
      workbookNames: workbookNames ?? this.workbookNames,
      knowledgeBases: knowledgeBases ?? this.knowledgeBases,
      agentProfiles: agentProfiles ?? this.agentProfiles,
      agentConversations: agentConversations ?? this.agentConversations,
      agentArtifacts: agentArtifacts ?? this.agentArtifacts,
      agentActivityLogPath: agentActivityLogPath ?? this.agentActivityLogPath,
      agentArtifactCatalogPath:
          agentArtifactCatalogPath ?? this.agentArtifactCatalogPath,
      eventLedgerPath: eventLedgerPath ?? this.eventLedgerPath,
      eventLedgerRecords: eventLedgerRecords ?? this.eventLedgerRecords,
      artifactCatalogPath: artifactCatalogPath ?? this.artifactCatalogPath,
      artifactRecords: artifactRecords ?? this.artifactRecords,
      sourceCount: sourceCount ?? this.sourceCount,
      sourceNames: sourceNames ?? this.sourceNames,
      sourceRecords: sourceRecords ?? this.sourceRecords,
      chunkCount: chunkCount ?? this.chunkCount,
      searchQuery: searchQuery ?? this.searchQuery,
      searchStatus: searchStatus ?? this.searchStatus,
      searchResults: searchResults ?? this.searchResults,
      lastMessage: lastMessage ?? this.lastMessage,
      lastError: lastError ?? this.lastError,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}
