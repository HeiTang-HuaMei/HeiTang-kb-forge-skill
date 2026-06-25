part of '../../main.dart';

class _SettingsProductWorkflow extends StatelessWidget {
  const _SettingsProductWorkflow({
    required this.localeCode,
    required this.workspace,
    required this.runtimeController,
    required this.providerCapabilityStatus,
    required this.selectedTab,
    required this.onTabSelected,
    required this.isWebRuntime,
  });

  final String localeCode;
  final String workspace;
  final Rc6RuntimeController? runtimeController;
  final ProviderCapabilityStatus providerCapabilityStatus;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;
  final bool isWebRuntime;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final tabs = _zh
        ? ['工作区', '模型服务', '记忆与存储', '导出', '网络与安全']
        : [
            'Workspace',
            'Model Service',
            'Memory and Storage',
            'Export',
            'Network and Security',
          ];
    final body = selectedTab == 0
        ? SizedBox(
            height: 190,
            child: _LocalScrollBox(
              child: _SettingsWorkspaceView(
                zh: _zh,
                workspace: workspace,
                isWebRuntime: isWebRuntime,
              ),
            ),
          )
        : selectedTab == 1
            ? _SettingsProviderModelView(
                zh: _zh,
                runtimeController: runtimeController,
                providerCapabilityStatus: providerCapabilityStatus,
              )
            : selectedTab == 2
                ? _SettingsProvidersStorageView(
                    zh: _zh,
                    workspace: workspace,
                    runtimeController: runtimeController,
                  )
                : selectedTab == 3
                    ? _SettingsExporterView(
                        zh: _zh,
                        runtimeController: runtimeController,
                        workspace: workspace,
                      )
                    : _SettingsNetworkSecurityView(
                        zh: _zh,
                        isWebRuntime: isWebRuntime,
                      );
    return _FigmaPageCanvas(children: [
      _PageTabs(
          tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
      if (selectedTab == 0)
        SizedBox(
          height: 434,
          child: _SettingsOverviewCards(
            zh: _zh,
            selectedTab: selectedTab,
            onTabSelected: onTabSelected,
          ),
        ),
      body,
    ]);
  }
}

class _SettingsOverviewCards extends StatelessWidget {
  const _SettingsOverviewCards({
    required this.zh,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final bool zh;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final cards = zh
        ? const [
            _SettingsOverviewCardData(
              '语言与外观',
              '中文 / English，浅色 / 深色',
              Icons.palette_outlined,
              0,
            ),
            _SettingsOverviewCardData(
              '模型服务连接',
              '配置服务并测试连接',
              Icons.hub_outlined,
              1,
            ),
            _SettingsOverviewCardData(
              '本地存储',
              '工作区路径与本地缓存',
              Icons.folder_open_outlined,
              0,
            ),
            _SettingsOverviewCardData(
              '文档生成工具',
              'Markdown、Word、PDF、PPT、表格',
              Icons.file_download_outlined,
              3,
            ),
            _SettingsOverviewCardData(
              '内存与缓存',
              '本地模式与专业记忆服务',
              Icons.memory_outlined,
              2,
            ),
            _SettingsOverviewCardData(
              '安全与合规',
              '网络权限、密钥和保留策略',
              Icons.verified_user_outlined,
              4,
            ),
          ]
        : const [
            _SettingsOverviewCardData(
              'Language and appearance',
              'Chinese / English, light / dark',
              Icons.palette_outlined,
              0,
            ),
            _SettingsOverviewCardData(
              'Model service',
              'Configure and test service connection',
              Icons.hub_outlined,
              1,
            ),
            _SettingsOverviewCardData(
              'Local storage',
              'Workspace path and local cache',
              Icons.folder_open_outlined,
              0,
            ),
            _SettingsOverviewCardData(
              'Document generation tools',
              'Markdown, Word, PDF, PPT, tables',
              Icons.file_download_outlined,
              3,
            ),
            _SettingsOverviewCardData(
              'Memory and cache',
              'Local mode and professional memory service',
              Icons.memory_outlined,
              2,
            ),
            _SettingsOverviewCardData(
              'Security and compliance',
              'Network permission, keys, retention',
              Icons.verified_user_outlined,
              4,
            ),
          ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1050
          ? 3
          : constraints.maxWidth >= 680
              ? 2
              : 1;
      return GridView.builder(
        key: const Key('settings-overview-cards'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: _DesktopGrid.gutter,
          mainAxisSpacing: _DesktopGrid.gutter,
          mainAxisExtent: 164,
        ),
        itemBuilder: (context, index) {
          final card = cards[index];
          return _SettingsOverviewCard(
            data: card,
            active: card.tabIndex == selectedTab,
            onTap: () => onTabSelected(card.tabIndex),
          );
        },
      );
    });
  }
}

class _SettingsOverviewCardData {
  const _SettingsOverviewCardData(
    this.title,
    this.description,
    this.icon,
    this.tabIndex,
  );

  final String title;
  final String description;
  final IconData icon;
  final int tabIndex;
}

class _SettingsOverviewCard extends StatelessWidget {
  const _SettingsOverviewCard({
    required this.data,
    required this.active,
    required this.onTap,
  });

  final _SettingsOverviewCardData data;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: active ? _HTKWTokens.goldSoft : colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? _HTKWTokens.gold : colors.outlineVariant,
            ),
            boxShadow: active ? const [] : _HTKWTokens.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: active ? colors.surface : _HTKWTokens.goldSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(data.icon, color: _HTKWTokens.gold, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            height: 1.24,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _StatePill(
                        label:
                            active ? (data.tabIndex == 0 ? '当前' : '已选') : '配置'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsProviderModelView extends StatelessWidget {
  const _SettingsProviderModelView({
    required this.zh,
    required this.runtimeController,
    required this.providerCapabilityStatus,
  });

  final bool zh;
  final Rc6RuntimeController? runtimeController;
  final ProviderCapabilityStatus providerCapabilityStatus;

  @override
  Widget build(BuildContext context) {
    return _SettingsProviderModelEditor(
      zh: zh,
      runtimeController: runtimeController,
      providerCapabilityStatus: providerCapabilityStatus,
    );
  }
}

class _SettingsProviderModelEditor extends StatefulWidget {
  const _SettingsProviderModelEditor({
    required this.zh,
    required this.runtimeController,
    required this.providerCapabilityStatus,
  });

  final bool zh;
  final Rc6RuntimeController? runtimeController;
  final ProviderCapabilityStatus providerCapabilityStatus;

  @override
  State<_SettingsProviderModelEditor> createState() =>
      _SettingsProviderModelEditorState();
}

class _SettingsProviderModelEditorState
    extends State<_SettingsProviderModelEditor> {
  bool loading = false;
  bool saved = false;
  bool validated = false;
  bool validatingConnectionConfiguration = false;
  bool profileLoading = false;
  String savedPath = '';
  String validationPath = '';
  String connectionConfigurationPath = '';
  String profileMessage = '';
  String capabilityMessage = '';
  String documentParsingMessage = '';
  List<ProjectConfigProfile> profiles = const [];
  List<Map<String, dynamic>> runtimeCapabilityEntries = const [];
  final TextEditingController _llmProviderController =
      TextEditingController(text: 'env_configured');
  final TextEditingController _modelController =
      TextEditingController(text: 'local-default-or-configured-provider');
  final TextEditingController _embeddingProviderController =
      TextEditingController(text: 'local_keyword_embedding');
  final TextEditingController _searchProviderController =
      TextEditingController(text: 'local_index');
  final TextEditingController _parserProviderController =
      TextEditingController(text: 'local_parser');
  final TextEditingController _ocrProviderController =
      TextEditingController(text: 'optional_ocr');
  final TextEditingController _apiKeyController =
      TextEditingController(text: '************');

  bool get zh => widget.zh;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadProfiles();
  }

  @override
  void dispose() {
    _llmProviderController.dispose();
    _modelController.dispose();
    _embeddingProviderController.dispose();
    _searchProviderController.dispose();
    _parserProviderController.dispose();
    _ocrProviderController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    setState(() => loading = true);
    final settings = await rc6.loadProviderRuntimeSettings();
    if (!mounted) return;
    final llm = _settingsMap(settings['llm']);
    final embedding = _settingsMap(settings['embedding']);
    final search = _settingsMap(settings['search']);
    final parser = _settingsMap(settings['parser']);
    final ocr = _settingsMap(settings['ocr']);
    setState(() {
      loading = false;
      _llmProviderController.text =
          _settingsText(llm, 'provider_id', 'env_configured');
      _modelController.text = _settingsText(
          llm, 'model_id', 'local-default-or-configured-provider');
      _embeddingProviderController.text =
          _settingsText(embedding, 'provider_id', 'local_keyword_embedding');
      _searchProviderController.text =
          _settingsText(search, 'provider_id', 'local_index');
      _parserProviderController.text =
          _settingsText(parser, 'provider_id', 'local_parser');
      _ocrProviderController.text =
          _settingsText(ocr, 'provider_id', 'optional_ocr');
      _apiKeyController.text =
          _settingsText(llm, 'api_key_display', '************');
      savedPath = rc6.state.providerRuntimeSettingsPath.isEmpty
          ? ''
          : 'config/provider_runtime_settings.json';
      validationPath = rc6.state.providerValidationReportPath.isEmpty
          ? ''
          : 'config/provider_validation_report.json';
    });
    await _loadRuntimeCapabilityCatalog();
  }

  Future<void> _loadProfiles() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    setState(() => profileLoading = true);
    final loaded = await rc6.loadProjectConfigProfiles();
    if (!mounted) return;
    setState(() {
      profiles = loaded;
      profileLoading = false;
    });
  }

  ProjectConfigProfile? get _activeProfile {
    for (final profile in profiles) {
      if (profile.isActive) return profile;
    }
    return profiles.isEmpty ? null : profiles.first;
  }

  Future<void> _createProfile() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    await rc6.createProjectConfigProfile(
      displayName: zh ? '云机/外部服务配置' : 'Cloud / external service profile',
      mode: 'hybrid',
    );
    if (!mounted) return;
    setState(() => profileMessage = zh ? '配置档已创建' : 'Profile created');
    await _loadProfiles();
  }

  Future<void> _copyProfile() async {
    final rc6 = widget.runtimeController;
    final active = _activeProfile;
    if (rc6 == null || active == null) return;
    await rc6.copyProjectConfigProfile(active.profileId);
    if (!mounted) return;
    setState(() => profileMessage = zh ? '配置档已复制' : 'Profile copied');
    await _loadProfiles();
  }

  Future<void> _testProfile() async {
    final rc6 = widget.runtimeController;
    final active = _activeProfile;
    if (rc6 == null || active == null) return;
    final testId = await rc6.testProjectConfigProfile(active.profileId);
    if (!mounted) return;
    setState(() => profileMessage =
        testId.isEmpty ? '' : (zh ? '配置档测试已记录' : 'Profile test logged'));
    await _loadProfiles();
  }

  Future<void> _activateNextProfile() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null || profiles.length < 2) return;
    final active = _activeProfile;
    final currentIndex = profiles
        .indexWhere((profile) => profile.profileId == active?.profileId);
    final next = profiles[(currentIndex + 1) % profiles.length];
    await rc6.activateProjectConfigProfile(next.profileId);
    if (!mounted) return;
    setState(() => profileMessage = zh ? '配置档已切换' : 'Profile activated');
    await _loadProfiles();
  }

  Future<void> _rollbackProfile() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    await rc6.rollbackProjectConfigProfile();
    if (!mounted) return;
    setState(() => profileMessage = zh ? '配置档已回滚' : 'Profile rolled back');
    await _loadProfiles();
  }

  Future<void> _deleteInactiveProfile() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    final inactive = profiles.where((profile) => !profile.isActive).toList();
    if (inactive.isEmpty) {
      setState(() => profileMessage =
          zh ? '当前配置档或最后一个配置档不能删除' : 'No inactive profile to delete');
      return;
    }
    final confirmed = await _confirmDestructiveAction(
      context,
      title: zh ? '删除未启用配置档？' : 'Delete inactive profile?',
      body: zh
          ? '这会删除一个未启用的配置档；当前启用配置、输入原文件和工作区产物不会被删除。'
          : 'This deletes one inactive profile; the active config, source files, and workspace artifacts are not deleted.',
    );
    if (!confirmed) return;
    final deleted =
        await rc6.deleteProjectConfigProfile(inactive.last.profileId);
    if (!mounted) return;
    setState(() => profileMessage = deleted
        ? (zh ? '未启用配置档已删除' : 'Inactive profile deleted')
        : (zh ? '删除被阻止' : 'Delete blocked'));
    await _loadProfiles();
  }

  Future<void> _saveSettings() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    final path = await rc6.saveProviderRuntimeSettings(
      llmProvider: _llmProviderController.text,
      modelId: _modelController.text,
      embeddingProvider: _embeddingProviderController.text,
      searchProvider: _searchProviderController.text,
      parserProvider: _parserProviderController.text,
      ocrProvider: _ocrProviderController.text,
      apiKey: _apiKeyController.text,
    );
    if (!mounted) return;
    setState(() {
      saved = path.isNotEmpty;
      savedPath = path.isEmpty ? '' : 'config/provider_runtime_settings.json';
      validationPath = path.isEmpty
          ? validationPath
          : 'config/provider_validation_report.json';
    });
  }

  Future<void> _validateSettings() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    final path = await rc6.validateProviderRuntimeSettings();
    await rc6.syncRegisteredProviderCapabilities();
    if (!mounted) return;
    setState(() {
      validated = path.isNotEmpty;
      validationPath =
          path.isEmpty ? '' : 'config/provider_validation_report.json';
    });
    await _loadRuntimeCapabilityCatalog();
  }

  Future<void> _runConnectionConfigurationAcceptance() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null || rc6.state.running || validatingConnectionConfiguration) {
      return;
    }
    setState(() => validatingConnectionConfiguration = true);
    final path = await rc6.runConnectionConfigurationAcceptance();
    if (!mounted) return;
    setState(() {
      connectionConfigurationPath = path;
      validatingConnectionConfiguration = false;
      saved = saved || path.isNotEmpty;
      validated = validated || path.isNotEmpty;
    });
    await _loadRuntimeCapabilityCatalog();
  }

  Future<void> _testCapabilityEnhancement() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    final providerRef = _firstProviderRef(widget.providerCapabilityStatus);
    if (providerRef.isEmpty) return;
    final activated =
        await rc6.activateRegisteredProviderCapability(providerRef);
    if (!mounted) return;
    setState(() {
      capabilityMessage = activated
          ? (zh ? '外部服务连接已启用' : 'External connection enabled')
          : (zh ? '需要处理，已写入操作记录' : 'Needs action; record written');
    });
  }

  Future<void> _testAllCapabilityEnhancements() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    final path = await rc6.testAllRegisteredProviderCapabilities();
    if (!mounted) return;
    setState(() {
      capabilityMessage = path.isEmpty
          ? (zh ? '需要桌面端执行连接检查' : 'Desktop app required')
          : (zh ? '外部服务连接检查已记录' : 'Connection check recorded');
    });
    await _loadRuntimeCapabilityCatalog();
  }

  Future<void> _testDocumentParsingCapability() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) {
      setState(() => documentParsingMessage =
          zh ? '需要桌面端执行文档解析测试。' : 'Desktop app is required.');
      return;
    }
    final path = await rc6.testAllRegisteredProviderCapabilities();
    if (!mounted) return;
    setState(() {
      documentParsingMessage = path.isEmpty
          ? (zh ? '需要处理，文档解析测试未完成。' : 'Needs action; test not completed.')
          : (zh ? '文档解析能力测试已记录。' : 'Document parsing check recorded.');
    });
    await _loadRuntimeCapabilityCatalog();
  }

  Future<void> _rollbackCapabilityEnhancement() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    final providerRef = _firstProviderRef(widget.providerCapabilityStatus);
    if (providerRef.isEmpty) return;
    final rolledBack =
        await rc6.rollbackRegisteredProviderCapability(providerRef);
    if (!mounted) return;
    setState(() {
      capabilityMessage = rolledBack
          ? (zh ? '已回滚到本地默认能力' : 'Rolled back to local default')
          : (zh ? '没有需要恢复的连接' : 'No connection to restore');
    });
    await _loadRuntimeCapabilityCatalog();
  }

  Future<void> _loadRuntimeCapabilityCatalog() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    final catalog = await rc6.loadProviderCapabilityUserCatalog();
    final entries = catalog['entries'];
    Rc6ArtifactRecord? latestConnectionSummary;
    for (final record in rc6.state.artifactRecords) {
      if (record.artifactId == 'connection_configuration_summary' &&
          record.isActive) {
        latestConnectionSummary = record;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      if (entries is List) {
        runtimeCapabilityEntries = entries
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(growable: false);
      }
      if (latestConnectionSummary != null) {
        connectionConfigurationPath = latestConnectionSummary.filePath;
        saved = true;
        validated = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final profilePanel = _SettingsProjectProfilePanel(
        zh: zh,
        profiles: profiles,
        loading: profileLoading,
        message: profileMessage,
        onCreate: _createProfile,
        onCopy: _copyProfile,
        onTest: _testProfile,
        onActivateNext: _activateNextProfile,
        onRollback: _rollbackProfile,
        onDeleteInactive: _deleteInactiveProfile,
      );
      final provider = _ProductPanel(
        keyName: 'settings-provider-model',
        icon: Icons.memory_outlined,
        title: zh ? 'AI 模型接口' : 'AI Model Interface',
        gap: true,
        children: [
          _ProductTable(
            columns: zh
                ? ['配置块', '当前状态', '下一步']
                : ['Config block', 'Status', 'Next step'],
            rows: zh
                ? [
                    [
                      'AI 模型接口',
                      _settingsSavedStatus(savedPath, validated, zh),
                      '测试连接'
                    ],
                    ['Embedding 接口', _configuredServiceDisplay(zh), '测试向量化'],
                    ['外部服务连接', _configuredServiceDisplay(zh), '按需测试连接'],
                  ]
                : [
                    [
                      'AI model interface',
                      _settingsSavedStatus(savedPath, validated, zh),
                      'Test connection'
                    ],
                    [
                      'Embedding interface',
                      _configuredServiceDisplay(zh),
                      'Test embedding'
                    ],
                    [
                      'External service connection',
                      _configuredServiceDisplay(zh),
                      'Test when needed'
                    ],
                  ],
          ),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '密钥展示' : 'Secret display',
              value: zh ? '只显示掩码，不展示明文' : 'Masked only, never plaintext'),
          const SizedBox(height: 8),
          _SectionCaption(zh ? '连接配置' : 'Connection config'),
          const SizedBox(height: 6),
          _SettingsConnectionForm(
            zh: zh,
            fields: [
              _SettingsTextFieldSpec(
                zh ? 'AI 能力' : 'AI capability',
                _llmProviderController,
                displayText: _configuredServiceDisplay(zh),
              ),
              _SettingsTextFieldSpec(
                zh ? '默认模型' : 'Default model',
                _modelController,
                displayText: zh ? '系统自动选择' : 'Selected automatically',
              ),
              _SettingsTextFieldSpec(
                zh ? '向量化能力' : 'Embedding capability',
                _embeddingProviderController,
                displayText: _configuredServiceDisplay(zh),
              ),
              _SettingsTextFieldSpec(
                zh ? '知识库问答能力' : 'Knowledge Q&A capability',
                _searchProviderController,
                displayText: _configuredServiceDisplay(zh),
              ),
              _SettingsTextFieldSpec(
                zh ? '文档解析能力' : 'Document parsing capability',
                _parserProviderController,
                displayText: zh ? '系统自动选择' : 'Selected automatically',
              ),
              _SettingsTextFieldSpec(
                zh ? '图片文字能力' : 'Image text capability',
                _ocrProviderController,
                displayText: zh ? '可选，未安装' : 'Optional, not installed',
              ),
              _SettingsTextFieldSpec(
                  zh ? '访问密钥' : 'Access key', _apiKeyController),
            ],
          ),
          const SizedBox(height: 8),
          _EqualActionRow(children: [
            _PrimaryProductAction(
              label: zh ? '保存接口配置' : 'Save interface config',
              icon: Icons.save_outlined,
              onPressed: _saveSettings,
            ),
            _PrimaryProductAction(
              label: zh ? '测试 AI 模型接口' : 'Test AI model interface',
              icon: Icons.fact_check_outlined,
              onPressed: _validateSettings,
            ),
          ]),
          const SizedBox(height: 8),
          _EqualActionRow(children: [
            _PrimaryProductAction(
              automationKey: 'connection-configuration-evidence-button',
              label: validatingConnectionConfiguration
                  ? (zh ? '正在生成连接配置证据' : 'Generating connection evidence')
                  : (zh ? '生成连接配置证据' : 'Generate connection evidence'),
              icon: Icons.cable_outlined,
              onPressed: widget.runtimeController == null ||
                      validatingConnectionConfiguration
                  ? null
                  : _runConnectionConfigurationAcceptance,
            ),
            _DisplayAction(
              label: connectionConfigurationPath.isEmpty
                  ? (zh ? '等待连接配置报告' : 'Waiting for connection report')
                  : (zh ? '预览连接配置报告' : 'Preview connection report'),
              icon: Icons.visibility_outlined,
              onPressed: connectionConfigurationPath.isEmpty
                  ? null
                  : () => _showWorkspaceArtifactPreview(
                        context,
                        rc6: widget.runtimeController,
                        title: zh ? '连接配置报告预览' : 'Connection report preview',
                        path: connectionConfigurationPath,
                        unavailableMessage: zh
                            ? '尚未生成连接配置报告。'
                            : 'No connection configuration report generated.',
                        closeLabel: zh ? '关闭' : 'Close',
                      ),
            ),
          ]),
          if (saved ||
              validated ||
              loading ||
              connectionConfigurationPath.isNotEmpty) ...[
            const SizedBox(height: 8),
            _RuntimeFeedbackBanner(
              title: connectionConfigurationPath.isNotEmpty
                  ? (zh ? '连接配置证据已生成' : 'Connection evidence generated')
                  : validated
                      ? (zh ? '接口测试报告已生成' : 'Interface test report generated')
                      : saved
                          ? (zh ? '接口配置已保存' : 'Interface config saved')
                          : (zh ? '正在加载配置' : 'Loading config'),
              detail: zh
                  ? '配置和测试记录已保存；访问密钥仅保存掩码或环境变量引用。'
                  : 'Configuration and test records are saved; access keys remain masked or environment references.',
              tone: _StatusTone.success,
              icon: Icons.verified_user_outlined,
            ),
          ],
        ],
      );
      final documentParsing = _ProductPanel(
        keyName: 'settings-document-parsing-capability',
        icon: Icons.description_outlined,
        title: zh ? '文档解析能力' : 'Document Parsing Capability',
        gap: true,
        children: [
          _ProductTable(
            columns: zh
                ? ['能力', '状态', '下一步']
                : ['Capability', 'Status', 'Next step'],
            rows: zh
                ? [
                    ['基础解析', '已可用', '上传文档后自动处理'],
                    ['高级解析', '可选，未安装', '需要时安装增强组件'],
                    ['OCR', '可选，未安装', '扫描件或图片文档需要时启用'],
                  ]
                : [
                    ['Basic parsing', 'Available', 'Runs after upload'],
                    [
                      'Advanced parsing',
                      'Optional, not installed',
                      'Install only when needed'
                    ],
                    [
                      'OCR',
                      'Optional, not installed',
                      'Use for scans and image documents'
                    ],
                  ],
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '自动处理' : 'Automatic handling',
            value: zh
                ? '上传后自动判断文档类型，并选择合适的解析路线。'
                : 'After upload, the app chooses a suitable parsing path.',
          ),
          const SizedBox(height: 8),
          _EqualActionRow(children: [
            _PrimaryProductAction(
              label: zh ? '测试文档解析' : 'Test document parsing',
              icon: Icons.fact_check_outlined,
              onPressed: _testDocumentParsingCapability,
            ),
          ]),
          if (documentParsingMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            _RuntimeFeedbackBanner(
              title: documentParsingMessage,
              detail: zh
                  ? '文档解析测试只记录能力状态，不展示底层实现名称。'
                  : 'The check records capability status without exposing implementation names.',
              tone: documentParsingMessage.contains(zh ? '需要处理' : 'Needs')
                  ? _StatusTone.warning
                  : _StatusTone.success,
              icon: Icons.description_outlined,
            ),
          ],
        ],
      );
      final model = _ProductPanel(
        keyName: 'settings-model-language',
        icon: Icons.tune_outlined,
        title: zh ? '模型、语言与主题' : 'Model, Language, and Theme',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? '默认模型' : 'Default model',
              value: loading
                  ? (zh ? '正在加载' : 'Loading')
                  : (zh ? '系统自动选择' : 'Selected automatically')),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '默认语言' : 'Default language',
              value:
                  zh ? '简体中文 / English 可切换' : 'Chinese / English switchable'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '主题' : 'Theme',
              value: zh ? '浅色 / 深色可切换' : 'Light / dark switchable'),
        ],
      );
      final capabilityStatus = _SettingsProviderCapabilityStatusPanel(
        zh: zh,
        status: widget.providerCapabilityStatus,
        runtimeEntries: runtimeCapabilityEntries,
        message: capabilityMessage,
        onTestCapability: _testCapabilityEnhancement,
        onTestAllCapabilities: _testAllCapabilityEnhancements,
        onRollbackCapability: _rollbackCapabilityEnhancement,
      );
      return Column(
        children: [
          profilePanel,
          const SizedBox(height: _DesktopGrid.gutter),
          provider,
          const SizedBox(height: _DesktopGrid.gutter),
          documentParsing,
          const SizedBox(height: _DesktopGrid.gutter),
          model,
          const SizedBox(height: _DesktopGrid.gutter),
          capabilityStatus,
        ],
      );
    });
  }
}

class _SettingsProviderCapabilityStatusPanel extends StatelessWidget {
  const _SettingsProviderCapabilityStatusPanel({
    required this.zh,
    required this.status,
    required this.runtimeEntries,
    required this.message,
    required this.onTestCapability,
    required this.onTestAllCapabilities,
    required this.onRollbackCapability,
  });

  final bool zh;
  final ProviderCapabilityStatus status;
  final List<Map<String, dynamic>> runtimeEntries;
  final String message;
  final VoidCallback onTestCapability;
  final VoidCallback onTestAllCapabilities;
  final VoidCallback onRollbackCapability;

  @override
  Widget build(BuildContext context) {
    final runtime = _Rc6RuntimeScope.of(context)?.state;
    final lifecycleAuditReady =
        runtime?.hasProviderLifecycleAuditSummary == true;
    final runtimeCatalogReady =
        runtime?.hasProviderCapabilityUserCatalog == true;
    final rows = _publicCapabilityRows(status, zh);
    final diagnosticRows = [
      [
        zh ? '模型服务' : 'Model service',
        _publicConnectionStatus(
          status.capabilities
              .where(
                  (entry) => _capabilityMatches(entry, const ['llm', 'model']))
              .toList(growable: false),
          zh,
        ),
      ],
      [
        zh ? '向量化服务' : 'Embedding service',
        _publicConnectionStatus(
          status.capabilities
              .where((entry) => _capabilityMatches(
                  entry, const ['embedding', 'vector', 'retrieval', 'search']))
              .toList(growable: false),
          zh,
        ),
      ],
      [
        zh ? '记忆存储' : 'Memory storage',
        runtimeCatalogReady ? _availableLabel(zh) : _needsActionLabel(zh),
      ],
      [
        zh ? '向量数据库' : 'Vector database',
        runtimeCatalogReady ? _availableLabel(zh) : _needsActionLabel(zh),
      ],
      [
        zh ? '文档解析' : 'Document parsing',
        _publicConnectionStatus(
          status.capabilities
              .where((entry) => _capabilityMatches(
                  entry, const ['parser', 'ocr', 'document_parser']))
              .toList(growable: false),
          zh,
        ),
      ],
      [zh ? '网络访问' : 'Network access', _availableLabel(zh)],
      [
        zh ? '本地权限' : 'Local permission',
        lifecycleAuditReady ? _availableLabel(zh) : _needsActionLabel(zh),
      ],
    ]
        .where((row) => row.every((value) => value.isNotEmpty))
        .toList(growable: false);
    return _ProductPanel(
      keyName: 'settings-provider-capability-status',
      icon: Icons.extension_outlined,
      title: zh ? '能力摘要' : 'Capability Summary',
      gap: true,
      children: [
        _FieldRow(
          label: zh ? '外部服务连接能力' : 'External service connectivity',
          value: runtimeCatalogReady
              ? (zh ? '已可用' : 'Available')
              : (zh ? '已配置，待测试' : 'Configured, needs test'),
        ),
        const SizedBox(height: 8),
        _FieldRow(
          label: zh ? '操作记录汇总' : 'Operation record summary',
          value: lifecycleAuditReady
              ? (zh ? '已生成' : 'Generated')
              : (zh ? '未生成' : 'Not generated'),
        ),
        const SizedBox(height: 8),
        _FieldRow(
          label: zh ? '连接摘要' : 'Connection summary',
          value: runtimeCatalogReady
              ? (zh ? '已生成' : 'Generated')
              : (zh ? '未生成' : 'Not generated'),
        ),
        const SizedBox(height: 8),
        _ProductTable(
          columns:
              zh ? ['能力', '状态', '下一步'] : ['Capability', 'Status', 'Next step'],
          rows: rows,
        ),
        if (diagnosticRows.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh ? ['诊断项', '状态'] : ['Diagnostic item', 'Status'],
            rows: diagnosticRows,
          ),
        ],
        const SizedBox(height: 8),
        _EqualActionRow(children: [
          _PrimaryProductAction(
            label: zh ? '测试连接' : 'Test connection',
            icon: Icons.fact_check_outlined,
            onPressed: status.capabilities.isEmpty ? null : onTestCapability,
          ),
          _PrimaryProductAction(
            label: zh ? '测试全部连接' : 'Test all connections',
            icon: Icons.rule_folder_outlined,
            onPressed:
                status.capabilities.isEmpty ? null : onTestAllCapabilities,
          ),
          _PrimaryProductAction(
            label: zh ? '恢复默认连接' : 'Restore default',
            icon: Icons.restore_outlined,
            onPressed:
                status.capabilities.isEmpty ? null : onRollbackCapability,
          ),
        ]),
        if (message.isNotEmpty) ...[
          const SizedBox(height: 8),
          _RuntimeFeedbackBanner(
            title: message,
            detail: zh
                ? '连接启用、阻止和恢复都会写入配置操作记录。'
                : 'Connection changes are recorded in configuration history.',
            tone: _StatusTone.neutral,
            icon: Icons.rule_folder_outlined,
          ),
        ],
      ],
    );
  }
}

class _SettingsProjectProfilePanel extends StatelessWidget {
  const _SettingsProjectProfilePanel({
    required this.zh,
    required this.profiles,
    required this.loading,
    required this.message,
    required this.onCreate,
    required this.onCopy,
    required this.onTest,
    required this.onActivateNext,
    required this.onRollback,
    required this.onDeleteInactive,
  });

  final bool zh;
  final List<ProjectConfigProfile> profiles;
  final bool loading;
  final String message;
  final VoidCallback onCreate;
  final VoidCallback onCopy;
  final VoidCallback onTest;
  final VoidCallback onActivateNext;
  final VoidCallback onRollback;
  final VoidCallback onDeleteInactive;

  ProjectConfigProfile? get active {
    for (final profile in profiles) {
      if (profile.isActive) return profile;
    }
    return profiles.isEmpty ? null : profiles.first;
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = active;
    final rows = profiles.isEmpty
        ? [
            [
              zh ? '暂无配置档' : 'No profile',
              zh ? '未配置' : 'Not configured',
              zh ? '需要处理' : 'Needs action',
              '',
            ]
          ]
        : profiles
            .map((profile) => [
                  profile.displayName,
                  _profileModeLabel(profile.mode, zh),
                  profile.isActive
                      ? (zh ? '当前启用' : 'Active')
                      : (zh ? '未启用' : 'Inactive'),
                  _publicProfileStatus(profile.lastTestStatus, zh),
                ])
            .toList(growable: false);
    return _ProductPanel(
      keyName: 'settings-project-config-profile',
      icon: Icons.account_tree_outlined,
      title: zh ? '配置档' : 'Configuration',
      gap: true,
      children: [
        _ProductTable(
          columns: zh
              ? ['配置档', '模式', '启用状态', '最近测试']
              : ['Configuration', 'Mode', 'Active', 'Last test'],
          rows: rows,
        ),
        const SizedBox(height: 8),
        _FieldRow(
          label: zh ? '当前配置档' : 'Active configuration',
          value: loading
              ? (zh ? '正在加载' : 'Loading')
              : activeProfile?.displayName ?? (zh ? '未配置' : 'Not configured'),
        ),
        const SizedBox(height: 8),
        _FieldRow(
          label: zh ? '健康度' : 'Health',
          value: activeProfile == null
              ? (zh ? '未配置' : 'Not configured')
              : _publicProfileStatus(activeProfile.lastTestStatus, zh),
        ),
        const SizedBox(height: 8),
        _FieldRow(
          label: zh ? '失败摘要' : 'Failure summary',
          value: activeProfile?.lastError.isNotEmpty == true
              ? activeProfile!.lastError
              : (zh
                  ? '无明文密钥；失败进入操作记录'
                  : 'No plaintext secrets; failures go to audit logs'),
        ),
        const SizedBox(height: 8),
        _EqualActionRow(children: [
          _PrimaryProductAction(
            label: zh ? '创建配置档' : 'Create profile',
            icon: Icons.add_circle_outline,
            onPressed: onCreate,
          ),
          _PrimaryProductAction(
            label: zh ? '复制配置档' : 'Copy profile',
            icon: Icons.copy_outlined,
            onPressed: activeProfile == null ? null : onCopy,
          ),
        ]),
        const SizedBox(height: 8),
        _EqualActionRow(children: [
          _PrimaryProductAction(
            label: zh ? '测试配置档' : 'Test profile',
            icon: Icons.fact_check_outlined,
            onPressed: activeProfile == null ? null : onTest,
          ),
          _PrimaryProductAction(
            label: zh ? '切换配置档' : 'Switch profile',
            icon: Icons.swap_horiz_outlined,
            onPressed: profiles.length < 2 ? null : onActivateNext,
          ),
        ]),
        const SizedBox(height: 8),
        _EqualActionRow(children: [
          _PrimaryProductAction(
            label: zh ? '回滚配置档' : 'Rollback profile',
            icon: Icons.restore_outlined,
            onPressed: activeProfile == null ? null : onRollback,
          ),
          _PrimaryProductAction(
            label: zh ? '删除未启用配置档' : 'Delete inactive',
            icon: Icons.delete_outline,
            onPressed: profiles.where((profile) => !profile.isActive).isEmpty
                ? null
                : onDeleteInactive,
          ),
        ]),
        if (message.isNotEmpty) ...[
          const SizedBox(height: 8),
          _RuntimeFeedbackBanner(
            title: message,
            detail: zh
                ? '配置档测试、切换、回滚会写入配置资产和操作记录。'
                : 'Configuration changes, tests, activation, and rollback write config assets and usage records.',
            tone: _StatusTone.success,
            icon: Icons.verified_outlined,
          ),
        ],
      ],
    );
  }
}

String _profileModeLabel(String mode, bool zh) {
  return switch (mode) {
    'cloud' => zh ? '云机模式' : 'Cloud',
    'hybrid' => zh ? '混合模式' : 'Hybrid',
    _ => zh ? '本地模式' : 'Local',
  };
}

String _publicProfileStatus(String status, bool zh) {
  final lower = status.toLowerCase();
  if (lower.contains('pass') ||
      lower.contains('success') ||
      lower.contains('connected')) {
    return _connectedLabel(zh);
  }
  if (lower.contains('fail') || lower.contains('error')) {
    return _failedLabel(zh);
  }
  if (lower.contains('configured') || lower.contains('test')) {
    return _configuredServiceDisplay(zh);
  }
  return _needsActionLabel(zh);
}

String _firstProviderRef(ProviderCapabilityStatus status) {
  for (final capability in status.capabilities) {
    if (capability.providerRefs.isNotEmpty) {
      return capability.providerRefs.first;
    }
  }
  return '';
}

String _availableLabel(bool zh) => zh ? '已可用' : 'Available';

String _connectedLabel(bool zh) => zh ? '已连接' : 'Connected';

String _configuredServiceDisplay(bool zh) =>
    zh ? '已配置，待测试' : 'Configured, needs test';

String _notConfiguredLabel(bool zh) => zh ? '未配置' : 'Not configured';

String _failedLabel(bool zh) => zh ? '测试失败' : 'Test failed';

String _optionalNotInstalledLabel(bool zh) =>
    zh ? '可选，未安装' : 'Optional, not installed';

String _needsActionLabel(bool zh) => zh ? '需要处理' : 'Needs action';

String _settingsSavedStatus(String savedPath, bool validated, bool zh) {
  if (validated) return _connectedLabel(zh);
  if (savedPath.isNotEmpty) return _configuredServiceDisplay(zh);
  return _notConfiguredLabel(zh);
}

String _publicCapabilityStatusLabel(String status, bool zh) {
  return switch (status) {
    'available' => _availableLabel(zh),
    'connected' => _connectedLabel(zh),
    'configured_not_tested' => _configuredServiceDisplay(zh),
    'available_with_gated_options' => _availableLabel(zh),
    'dependency_gated' => _optionalNotInstalledLabel(zh),
    'external_runtime_required' => _optionalNotInstalledLabel(zh),
    'needs_secret_config' => _notConfiguredLabel(zh),
    'needs_network_authorization' => _needsActionLabel(zh),
    'needs_verification' => _configuredServiceDisplay(zh),
    'needs_provider_config' => _notConfiguredLabel(zh),
    'connection_failed' => _failedLabel(zh),
    'auth_failed' => _failedLabel(zh),
    _ => status.contains('failed')
        ? _failedLabel(zh)
        : status.contains('missing') || status.contains('required')
            ? _notConfiguredLabel(zh)
            : _needsActionLabel(zh),
  };
}

String _publicCapabilityName(ProviderCapabilityEntry entry, bool zh) {
  final text = [
    entry.capabilityId,
    entry.capabilityArea,
    entry.providerType,
    entry.userVisibleName,
    entry.zhUserVisibleName,
  ].join(' ').toLowerCase();
  if (text.contains('parser') ||
      text.contains('ocr') ||
      text.contains('document')) {
    return zh ? '文档解析能力' : 'Document parsing capability';
  }
  if (text.contains('embedding') || text.contains('vector')) {
    return zh ? '外部服务连接能力' : 'External service connectivity';
  }
  if (text.contains('retrieval') ||
      text.contains('search') ||
      text.contains('rag') ||
      text.contains('knowledge')) {
    return zh ? '知识库问答能力' : 'Knowledge Q&A capability';
  }
  if (text.contains('skill')) {
    return zh ? 'Skill 生成能力' : 'Skill generation capability';
  }
  if (text.contains('agent') || text.contains('workflow')) {
    return zh ? 'Agent 执行能力' : 'Agent execution capability';
  }
  if (text.contains('export') || text.contains('artifact')) {
    return zh ? '文档生成能力' : 'Document generation capability';
  }
  if (text.contains('llm') || text.contains('model')) {
    return zh ? 'AI 能力' : 'AI capability';
  }
  return zh ? '外部服务连接能力' : 'External service connectivity';
}

String _publicCapabilityNextStep(ProviderCapabilityEntry entry, bool zh) {
  final status = _publicCapabilityStatusLabel(entry.status, zh);
  if (status == _availableLabel(zh) || status == _connectedLabel(zh)) {
    return zh ? '可直接使用' : 'Ready to use';
  }
  if (status == _configuredServiceDisplay(zh)) {
    return zh ? '测试连接' : 'Test connection';
  }
  if (status == _optionalNotInstalledLabel(zh)) {
    return zh ? '需要时安装' : 'Install when needed';
  }
  if (status == _notConfiguredLabel(zh)) {
    return zh ? '补充配置' : 'Add configuration';
  }
  if (status == _failedLabel(zh)) {
    return zh ? '检查配置后重试' : 'Check config and retry';
  }
  return zh ? '查看提示并处理' : 'Review prompt and fix';
}

bool _capabilityMatches(ProviderCapabilityEntry entry, List<String> keywords) {
  final text = [
    entry.capabilityId,
    entry.capabilityArea,
    entry.providerType,
    entry.userVisibleName,
    entry.zhUserVisibleName,
  ].join(' ').toLowerCase();
  return keywords.any(text.contains);
}

List<List<String>> _publicCapabilityRows(
    ProviderCapabilityStatus status, bool zh) {
  final rows = <String, List<String>>{};
  for (final entry in status.capabilities) {
    final name = _publicCapabilityName(entry, zh);
    final statusLabel = _publicCapabilityStatusLabel(entry.status, zh);
    final nextStep = _publicCapabilityNextStep(entry, zh);
    final existing = rows[name];
    if (existing == null ||
        existing[1] == _optionalNotInstalledLabel(zh) ||
        existing[1] == _notConfiguredLabel(zh)) {
      rows[name] = [name, statusLabel, nextStep];
    }
  }
  final orderedNames = zh
      ? const [
          '文档解析能力',
          'AI 能力',
          '知识库问答能力',
          'Skill 生成能力',
          'Agent 执行能力',
          '文档生成能力',
          '外部服务连接能力',
        ]
      : const [
          'Document parsing capability',
          'AI capability',
          'Knowledge Q&A capability',
          'Skill generation capability',
          'Agent execution capability',
          'Document generation capability',
          'External service connectivity',
        ];
  for (final name in orderedNames) {
    rows.putIfAbsent(
      name,
      () => [
        name,
        name == (zh ? '文档解析能力' : 'Document parsing capability')
            ? _availableLabel(zh)
            : _configuredServiceDisplay(zh),
        name == (zh ? '文档解析能力' : 'Document parsing capability')
            ? (zh ? '上传文档后自动处理' : 'Runs after upload')
            : (zh ? '按需测试连接' : 'Test when needed'),
      ],
    );
  }
  return orderedNames.map((name) => rows[name]!).toList(growable: false);
}

String _publicConnectionStatus(List<ProviderCapabilityEntry> entries, bool zh) {
  if (entries.isEmpty) return _configuredServiceDisplay(zh);
  if (entries.any((entry) =>
      _publicCapabilityStatusLabel(entry.status, zh) == _connectedLabel(zh) ||
      _publicCapabilityStatusLabel(entry.status, zh) == _availableLabel(zh))) {
    return _connectedLabel(zh);
  }
  if (entries.any((entry) =>
      _publicCapabilityStatusLabel(entry.status, zh) == _failedLabel(zh))) {
    return zh ? '连接失败' : 'Connection failed';
  }
  return _configuredServiceDisplay(zh);
}

class _SettingsExporterView extends StatelessWidget {
  const _SettingsExporterView({
    required this.zh,
    required this.runtimeController,
    required this.workspace,
  });

  final bool zh;
  final Rc6RuntimeController? runtimeController;
  final String workspace;

  @override
  Widget build(BuildContext context) {
    return _SettingsExporterEditor(
      zh: zh,
      runtimeController: runtimeController,
      workspace: workspace,
    );
  }
}

class _SettingsExporterEditor extends StatefulWidget {
  const _SettingsExporterEditor({
    required this.zh,
    required this.runtimeController,
    required this.workspace,
  });

  final bool zh;
  final Rc6RuntimeController? runtimeController;
  final String workspace;

  @override
  State<_SettingsExporterEditor> createState() =>
      _SettingsExporterEditorState();
}

class _SettingsExporterEditorState extends State<_SettingsExporterEditor> {
  bool saved = false;
  bool validated = false;
  String savedPath = '';
  String validationPath = '';
  final TextEditingController _docxController =
      TextEditingController(text: 'builtin_local_docx');
  final TextEditingController _pdfController =
      TextEditingController(text: 'builtin_local_pdf');
  final TextEditingController _pptxController =
      TextEditingController(text: 'builtin_local_pptx');
  final TextEditingController _exportRootController = TextEditingController();

  bool get zh => widget.zh;

  @override
  void initState() {
    super.initState();
    _exportRootController.text = '${widget.workspace}\\export';
    _loadSettings();
  }

  @override
  void dispose() {
    _docxController.dispose();
    _pdfController.dispose();
    _pptxController.dispose();
    _exportRootController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    final settings = await rc6.loadExporterSettings();
    if (!mounted) return;
    final exporters = _settingsMap(settings['exporters']);
    setState(() {
      _docxController.text = _settingsText(
          _settingsMap(exporters['docx']), 'provider', 'builtin_local_docx');
      _pdfController.text = _settingsText(
          _settingsMap(exporters['pdf']), 'provider', 'builtin_local_pdf');
      _pptxController.text = _settingsText(
          _settingsMap(exporters['pptx']), 'provider', 'builtin_local_pptx');
      _exportRootController.text =
          _settingsText(settings, 'export_root', '${widget.workspace}\\export');
      validationPath = rc6.state.exporterValidationReportPath.isEmpty
          ? ''
          : 'config/exporter_validation_report.json';
    });
  }

  Future<void> _saveSettings() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    final path = await rc6.saveExporterSettings(
      docxExporter: _docxController.text,
      pdfExporter: _pdfController.text,
      pptxExporter: _pptxController.text,
      exportRoot: _exportRootController.text,
    );
    if (!mounted) return;
    setState(() {
      saved = path.isNotEmpty;
      savedPath = path.isEmpty ? '' : 'config/exporter_settings.json';
      validationPath = path.isEmpty
          ? validationPath
          : 'config/exporter_validation_report.json';
    });
  }

  Future<void> _validateSettings() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    final path = await rc6.validateExporterSettings();
    if (!mounted) return;
    setState(() {
      validated = path.isNotEmpty;
      validationPath =
          path.isEmpty ? '' : 'config/exporter_validation_report.json';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'settings-exporter',
      icon: Icons.file_download_outlined,
      title: zh ? '文档生成工具设置' : 'Document Generation Tools',
      gap: true,
      children: [
        _ProductTable(
          columns: zh
              ? ['格式', '当前状态', '配置入口']
              : ['Format', 'Current status', 'Config entry'],
          rows: zh
              ? [
                  [
                    '内置生成器',
                    '已可用',
                    'md / txt / json / csv / docx / pdf / pptx / xlsx'
                  ],
                  ['Markdown / TXT', '已可用', '无需额外工具'],
                  ['JSON / CSV / XLSX', '已可用', '结构化和表格输出'],
                  ['DOCX / PDF / PPTX', '已可用', '内置轻量生成'],
                  ['高级文档生成工具', '可选，未安装', '需要高保真排版时按提示安装'],
                ]
              : [
                  [
                    'Built-in generator',
                    'Available',
                    'md / txt / json / csv / docx / pdf / pptx / xlsx'
                  ],
                  ['Markdown / TXT', 'Available', 'No extra tool required'],
                  [
                    'JSON / CSV / XLSX',
                    'Available',
                    'Structured and table output'
                  ],
                  [
                    'DOCX / PDF / PPTX',
                    'Available',
                    'Built-in lightweight generation'
                  ],
                  [
                    'Advanced document generation tools',
                    'Optional, not installed',
                    'Install only for high-fidelity layout'
                  ],
                ],
        ),
        const SizedBox(height: 8),
        _SectionCaption(zh
            ? '高级文档生成工具（高保真排版、复杂模板、企业格式）'
            : 'Advanced document generation tools for high-fidelity layout and enterprise formats'),
        const SizedBox(height: 6),
        _SettingsConnectionForm(
          zh: zh,
          fields: [
            _SettingsTextFieldSpec(
                zh ? 'DOCX 生成工具' : 'DOCX generation tool', _docxController),
            _SettingsTextFieldSpec(
                zh ? 'PDF 生成工具' : 'PDF generation tool', _pdfController),
            _SettingsTextFieldSpec(
                zh ? 'PPTX 生成工具' : 'PPTX generation tool', _pptxController),
            _SettingsTextFieldSpec(
                zh ? '导出根目录' : 'Export root', _exportRootController),
          ],
        ),
        const SizedBox(height: 8),
        _EqualActionRow(children: [
          _PrimaryProductAction(
            label: zh ? '保存文档生成配置' : 'Save document generation config',
            icon: Icons.save_outlined,
            onPressed: _saveSettings,
          ),
          _PrimaryProductAction(
            label: zh ? '测试文档生成配置' : 'Test document generation config',
            icon: Icons.fact_check_outlined,
            onPressed: _validateSettings,
          ),
        ]),
        if (saved || validated) ...[
          const SizedBox(height: 8),
          _RuntimeFeedbackBanner(
            title: validated
                ? (zh
                    ? '文档生成测试报告已生成'
                    : 'Document generation test report generated')
                : (zh ? '文档生成配置已保存' : 'Document generation config saved'),
            detail: zh
                ? '文档生成工具按需启用；普通格式无需额外安装。'
                : 'Document generation tools are enabled only when needed; common formats need no extra install.',
            tone: _StatusTone.success,
            icon: Icons.file_download_done_outlined,
          ),
        ],
      ],
    );
  }
}

class _SettingsNetworkSecurityView extends StatelessWidget {
  const _SettingsNetworkSecurityView({
    required this.zh,
    required this.isWebRuntime,
  });

  final bool zh;
  final bool isWebRuntime;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final network = _ProductPanel(
        keyName: 'settings-network-authorization',
        icon: Icons.public_off_outlined,
        title: zh ? '网络授权' : 'Network Authorization',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? '默认网络' : 'Default network',
              value: zh
                  ? '本地优先，外部调用需显式配置'
                  : 'Local-first; external calls require explicit config'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '桌面能力' : 'Desktop capability',
              value: isWebRuntime
                  ? (zh
                      ? '请使用桌面端执行本地文件能力'
                      : 'Use the desktop app for local file workflows')
                  : (zh ? '桌面端可用' : 'Desktop app available')),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '失败处理' : 'Failure handling',
              value: zh
                  ? '保留失败原因，可回退本地路径'
                  : 'Keep failure reasons and fall back to local paths'),
        ],
      );
      final security = _ProductPanel(
        keyName: 'settings-security-policy',
        icon: Icons.shield_outlined,
        title: zh ? '安全策略' : 'Security Policy',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? '密钥' : 'Secret',
              value: zh
                  ? '只保存或读取掩码引用，不展示明文'
                  : 'Store/read masked references only; never show plaintext'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '高风险能力' : 'High-risk capability',
              value: zh
                  ? '普通 UI 不开放任意系统命令'
                  : 'Arbitrary system commands are not exposed in ordinary UI'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '操作记录' : 'Audit',
              value: zh
                  ? '运行记录、失败、权限和恢复进入操作记录'
                  : 'Runs, failures, permissions, and recovery go to Governance & Audit'),
        ],
      );
      if (!wide) {
        return Column(children: [
          network,
          const SizedBox(height: _DesktopGrid.gutter),
          security,
        ]);
      }
      return _EqualHeightRow(
        height: 320,
        flexes: const [6, 6],
        children: [network, security],
      );
    });
  }
}

class _SettingsProvidersStorageView extends StatefulWidget {
  const _SettingsProvidersStorageView({
    required this.zh,
    required this.workspace,
    required this.runtimeController,
  });

  final bool zh;
  final String workspace;
  final Rc6RuntimeController? runtimeController;

  @override
  State<_SettingsProvidersStorageView> createState() =>
      _SettingsProvidersStorageViewState();
}

class _SettingsProvidersStorageViewState
    extends State<_SettingsProvidersStorageView> {
  bool storageTested = false;
  bool configSaved = false;
  bool redisTested = false;
  bool qdrantTested = false;
  bool redisTesting = false;
  bool qdrantTesting = false;
  bool configLoading = false;
  String redisStatus = 'configured_not_tested';
  String qdrantStatus = 'configured_not_tested';
  String redisDetail = '';
  String qdrantDetail = '';
  String savedConfigPath = '';
  final TextEditingController _redisHostController =
      TextEditingController(text: '127.0.0.1');
  final TextEditingController _redisPortController =
      TextEditingController(text: '6379');
  final TextEditingController _redisPrefixController =
      TextEditingController(text: 'heitang:');
  final TextEditingController _qdrantEndpointController =
      TextEditingController(text: 'http://127.0.0.1:6333');
  final TextEditingController _qdrantCollectionController =
      TextEditingController(text: 'heitang_kb');
  final TextEditingController _qdrantDimensionController =
      TextEditingController(text: '1536');
  final TextEditingController _maskedRedisPasswordController =
      TextEditingController(text: '********');
  final TextEditingController _blankQdrantApiKeyController =
      TextEditingController(text: '留空 / blank');

  bool get zh => widget.zh;

  @override
  void initState() {
    super.initState();
    _loadStoredConfig();
  }

  @override
  void dispose() {
    _redisHostController.dispose();
    _redisPortController.dispose();
    _redisPrefixController.dispose();
    _qdrantEndpointController.dispose();
    _qdrantCollectionController.dispose();
    _qdrantDimensionController.dispose();
    _maskedRedisPasswordController.dispose();
    _blankQdrantApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredConfig() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    setState(() => configLoading = true);
    final settings = await rc6.loadStorageProviderSettings();
    if (!mounted) return;
    final redis = _settingsMap(settings['redis']);
    final qdrant = _settingsMap(settings['qdrant']);
    setState(() {
      configLoading = false;
      _redisHostController.text = _settingsText(redis, 'host', '127.0.0.1');
      _redisPortController.text = _settingsInt(redis, 'port', 6379).toString();
      _redisPrefixController.text =
          _settingsText(redis, 'key_prefix', 'heitang:');
      _maskedRedisPasswordController.text =
          _settingsText(redis, 'password_display', '********');
      redisStatus = _settingsText(redis, 'status', 'configured_not_tested');
      redisDetail = _settingsText(redis, 'last_test_detail', '');
      redisTested = redisStatus == 'connected';
      _qdrantEndpointController.text =
          _settingsText(qdrant, 'endpoint', 'http://127.0.0.1:6333');
      _qdrantCollectionController.text =
          _settingsText(qdrant, 'collection', 'heitang_kb');
      _qdrantDimensionController.text =
          _settingsInt(qdrant, 'dimension', 1536).toString();
      _blankQdrantApiKeyController.text =
          _settingsText(qdrant, 'api_key_display', '').isEmpty
              ? (zh ? '留空 / blank' : 'blank')
              : '********';
      qdrantStatus = _settingsText(qdrant, 'status', 'configured_not_tested');
      qdrantDetail = _settingsText(qdrant, 'last_test_detail', '');
      qdrantTested = qdrantStatus == 'connected';
      savedConfigPath = settings['workspace']?.toString().isNotEmpty == true
          ? 'config/storage_provider_settings.json'
          : '';
    });
  }

  Future<void> _testRedisConnection() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) {
      setState(() {
        storageTested = true;
        redisTested = false;
        redisStatus = 'desktop_runtime_required';
        redisDetail = zh
            ? '真实专业记忆连接测试需要桌面端。'
            : 'Real professional memory test requires the desktop app.';
      });
      return;
    }
    final port = int.tryParse(_redisPortController.text.trim());
    if (port == null || port <= 0) {
      setState(() {
        storageTested = true;
        redisTested = false;
        redisStatus = 'invalid_port';
        redisDetail = zh
            ? '专业短期记忆端口必须是正整数。'
            : 'Professional short-term memory port must be positive.';
      });
      return;
    }
    setState(() {
      redisTesting = true;
      storageTested = true;
    });
    final result = await rc6.testRedisConnection(
      host: _redisHostController.text,
      port: port,
      keyPrefix: _redisPrefixController.text,
      password: _maskedRedisPasswordController.text,
    );
    if (!mounted) return;
    setState(() {
      redisTesting = false;
      redisTested = result.passed;
      redisStatus = result.status;
      redisDetail = result.detail;
      savedConfigPath = 'config/storage_provider_settings.json';
    });
  }

  Future<void> _testQdrantConnection() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) {
      setState(() {
        storageTested = true;
        qdrantTested = false;
        qdrantStatus = 'desktop_runtime_required';
        qdrantDetail = zh
            ? '真实知识记忆连接测试需要桌面端。'
            : 'Real knowledge memory test requires the desktop app.';
      });
      return;
    }
    final dimension = int.tryParse(_qdrantDimensionController.text.trim());
    if (dimension == null || dimension <= 0) {
      setState(() {
        storageTested = true;
        qdrantTested = false;
        qdrantStatus = 'invalid_dimension';
        qdrantDetail = zh
            ? '知识记忆维度必须是正整数。'
            : 'Knowledge memory dimension must be positive.';
      });
      return;
    }
    setState(() {
      qdrantTesting = true;
      storageTested = true;
    });
    final result = await rc6.testQdrantConnection(
      endpoint: _qdrantEndpointController.text,
      collection: _qdrantCollectionController.text,
      dimension: dimension,
      apiKey: _blankQdrantApiKeyController.text,
    );
    if (!mounted) return;
    setState(() {
      qdrantTesting = false;
      qdrantTested = result.passed;
      qdrantStatus = result.status;
      qdrantDetail = result.detail;
      savedConfigPath = 'config/storage_provider_settings.json';
    });
  }

  Future<void> _testStorageConnections() async {
    await _testRedisConnection();
    if (!mounted) return;
    await _testQdrantConnection();
  }

  Future<void> _saveStorageProviderSettings() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) {
      setState(() {
        configSaved = false;
        storageTested = true;
        redisStatus = 'desktop_runtime_required';
        qdrantStatus = 'desktop_runtime_required';
        redisDetail =
            zh ? '真实配置保存需要桌面端。' : 'Real config save requires the desktop app.';
      });
      return;
    }
    final redisPort = int.tryParse(_redisPortController.text.trim());
    final qdrantDimension =
        int.tryParse(_qdrantDimensionController.text.trim());
    if (redisPort == null || redisPort <= 0) {
      setState(() {
        configSaved = false;
        storageTested = true;
        redisStatus = 'invalid_port';
        redisDetail = zh
            ? '专业短期记忆端口必须是正整数。'
            : 'Professional short-term memory port must be positive.';
      });
      return;
    }
    if (qdrantDimension == null || qdrantDimension <= 0) {
      setState(() {
        configSaved = false;
        storageTested = true;
        qdrantStatus = 'invalid_dimension';
        qdrantDetail = zh
            ? '知识记忆维度必须是正整数。'
            : 'Knowledge memory dimension must be positive.';
      });
      return;
    }
    final path = await rc6.saveStorageProviderSettings(
      redisHost: _redisHostController.text,
      redisPort: redisPort,
      redisKeyPrefix: _redisPrefixController.text,
      redisPassword: _maskedRedisPasswordController.text,
      qdrantEndpoint: _qdrantEndpointController.text,
      qdrantCollection: _qdrantCollectionController.text,
      qdrantDimension: qdrantDimension,
      qdrantApiKey: _blankQdrantApiKeyController.text,
    );
    if (!mounted) return;
    setState(() {
      configSaved = path.isNotEmpty;
      storageTested = true;
      savedConfigPath =
          path.isEmpty ? '' : 'config/storage_provider_settings.json';
      redisStatus = 'configured_not_tested';
      qdrantStatus = 'configured_not_tested';
      redisDetail = '';
      qdrantDetail = '';
      redisTested = false;
      qdrantTested = false;
    });
  }

  String _storageFeedbackDetail() {
    final details = <String>[
      if (savedConfigPath.isNotEmpty)
        zh ? '存储配置已保存' : 'Storage configuration saved',
      if (redisDetail.isNotEmpty)
        '${zh ? '专业短期记忆' : 'Short-term memory'}: $redisDetail',
      if (qdrantDetail.isNotEmpty)
        '${zh ? '知识记忆' : 'Knowledge memory'}: $qdrantDetail',
    ];
    if (details.isEmpty) {
      return zh
          ? '记忆服务密钥只以掩码输入；测试失败不会展示明文密钥。'
          : 'Memory service secrets remain masked; failed tests never show plaintext secrets.';
    }
    return details.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final providers = _ProductPanel(
        keyName: 'settings-provider-storage',
        icon: Icons.storage_outlined,
        title: zh ? '记忆与存储配置' : 'Memory and Storage Config',
        gap: true,
        children: [
          _ProductTable(
            columns: zh
                ? ['配置项', '当前值', '连接状态', '分类']
                : ['Setting', 'Value', 'Connection', 'Class'],
            rows: zh
                ? [
                    ['应用工作区', widget.workspace, '本地可用', '可用'],
                    ['对象存储', '本地文件系统', '本地可用', '可用'],
                    [
                      '专业短期记忆',
                      '${_redisHostController.text}:${_redisPortController.text} / ${_redisPrefixController.text}',
                      redisTested
                          ? '已连接'
                          : _storageStatusLabel(redisStatus, zh),
                      redisTested ? '已连接' : '已配置，待测试'
                    ],
                    [
                      '知识记忆',
                      '${_qdrantEndpointController.text} / ${_qdrantCollectionController.text}',
                      qdrantTested
                          ? '已连接'
                          : _storageStatusLabel(qdrantStatus, zh),
                      qdrantTested ? '已连接' : '已配置，待测试'
                    ],
                    ['知识库索引', '本地文件索引 + 专业服务可选', '已可用', '已可用'],
                    ['模型服务', '环境变量', '已连接', '已连接'],
                    ['API Key', '************', '掩码展示', '已保护'],
                  ]
                : [
                    [
                      'App workspace',
                      widget.workspace,
                      'Local available',
                      'Available'
                    ],
                    [
                      'Object storage',
                      'Local filesystem',
                      'Local available',
                      'Available'
                    ],
                    [
                      'Professional short-term memory',
                      '${_redisHostController.text}:${_redisPortController.text} / ${_redisPrefixController.text}',
                      redisTested
                          ? 'Connected'
                          : _storageStatusLabel(redisStatus, zh),
                      redisTested ? 'Connected' : 'Configured, needs test'
                    ],
                    [
                      'Knowledge memory',
                      '${_qdrantEndpointController.text} / ${_qdrantCollectionController.text}',
                      qdrantTested
                          ? 'Connected'
                          : _storageStatusLabel(qdrantStatus, zh),
                      qdrantTested ? 'Connected' : 'Configured, needs test'
                    ],
                    [
                      'Knowledge base index',
                      'Local file index + optional professional service',
                      'Available',
                      'Available'
                    ],
                    [
                      'Model service',
                      'Environment variables',
                      'Connected',
                      'Connected'
                    ],
                    ['API Key', '************', 'Masked', 'Protected'],
                  ],
          ),
          const SizedBox(height: 8),
          _SectionCaption(zh ? '专业短期记忆' : 'Professional short-term memory'),
          const SizedBox(height: 6),
          _SettingsConnectionForm(
            zh: zh,
            fields: [
              _SettingsTextFieldSpec(
                  zh ? 'Host' : 'Host', _redisHostController),
              _SettingsTextFieldSpec(
                  zh ? 'Port' : 'Port', _redisPortController),
              _SettingsTextFieldSpec(
                  zh ? 'Key Prefix' : 'Key Prefix', _redisPrefixController),
              _SettingsTextFieldSpec(
                  zh ? 'Password' : 'Password', _maskedRedisPasswordController),
            ],
          ),
          const SizedBox(height: 8),
          _SectionCaption(zh ? '知识记忆服务' : 'Knowledge memory service'),
          const SizedBox(height: 6),
          _SettingsConnectionForm(
            zh: zh,
            fields: [
              _SettingsTextFieldSpec(
                  zh ? 'Endpoint' : 'Endpoint', _qdrantEndpointController),
              _SettingsTextFieldSpec(zh ? 'Collection' : 'Collection',
                  _qdrantCollectionController),
              _SettingsTextFieldSpec(
                  zh ? 'Dimension' : 'Dimension', _qdrantDimensionController),
              _SettingsTextFieldSpec(
                  zh ? 'API Key' : 'API Key', _blankQdrantApiKeyController),
            ],
          ),
          const SizedBox(height: 8),
          _EqualActionRow(children: [
            _PrimaryProductAction(
              label: zh ? '测试存储连接' : 'Test storage connections',
              icon: Icons.fact_check_outlined,
              onPressed: redisTesting || qdrantTesting
                  ? null
                  : _testStorageConnections,
            ),
            _PrimaryProductAction(
              label: redisTesting
                  ? (zh ? '正在测试短期记忆' : 'Testing short-term memory')
                  : (zh ? '测试短期记忆连接' : 'Test short-term memory connection'),
              icon: Icons.cable_outlined,
              onPressed: redisTesting ? null : _testRedisConnection,
            ),
          ]),
          const SizedBox(height: 8),
          _EqualActionRow(children: [
            _PrimaryProductAction(
              label: qdrantTesting
                  ? (zh ? '正在测试知识记忆' : 'Testing knowledge memory')
                  : (zh ? '测试知识记忆连接' : 'Test knowledge memory connection'),
              icon: Icons.hub_outlined,
              onPressed: qdrantTesting ? null : _testQdrantConnection,
            ),
            _PrimaryProductAction(
              label: zh ? '保存配置' : 'Save config',
              icon: Icons.save_outlined,
              onPressed: _saveStorageProviderSettings,
            ),
          ]),
          if (storageTested || configSaved) ...[
            const SizedBox(height: 8),
            _RuntimeFeedbackBanner(
              title: configSaved
                  ? (zh ? '配置已保存' : 'Config saved')
                  : (zh
                      ? '本地存储连接状态已更新'
                      : 'Local storage connection status updated'),
              detail: _storageFeedbackDetail(),
              tone: (redisStatus.contains('failed') ||
                      redisStatus.contains('missing') ||
                      redisStatus.contains('invalid') ||
                      qdrantStatus.contains('failed') ||
                      qdrantStatus.contains('missing') ||
                      qdrantStatus.contains('invalid'))
                  ? _StatusTone.warning
                  : _StatusTone.success,
              icon: configSaved ? Icons.save_outlined : Icons.cable_outlined,
            ),
          ],
        ],
      );
      final detail = _ProductPanel(
        keyName: 'settings-provider-detail',
        icon: Icons.tune_outlined,
        title:
            zh ? '文档生成与授权状态' : 'Document Generation and Authorization Status',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? '连接状态' : 'Connection status',
              value: zh ? '真实连接复验已通过' : 'Real connection reacceptance passed'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '密钥展示' : 'Secret display',
              value: zh ? '只显示掩码，不直接展示明文' : 'Masked only, plaintext hidden'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '连接测试' : 'Connection tests',
              value: zh
                  ? configLoading
                      ? '正在加载工作区配置'
                      : '未完成测试时显示已配置，待测试'
                  : configLoading
                      ? 'Loading workspace config'
                      : 'Show configured, needs test until a connection test passes'),
          const SizedBox(height: 8),
          _SectionCaption(zh ? '文档格式输出' : 'Document format output'),
          const SizedBox(height: 6),
          _ProductTable(
            columns: zh
                ? ['格式', '状态', '配置入口']
                : ['Format', 'Status', 'Config entry'],
            rows: zh
                ? [
                    ['Markdown', '已可用', '无需额外工具'],
                    ['JSON / CSV', '已可用', '无需额外工具'],
                    ['DOCX', '可选，未安装', '需要时配置'],
                    ['PDF', '可选，未安装', '需要时配置'],
                    ['PPTX', '可选，未安装', '需要时配置'],
                  ]
                : [
                    ['Markdown', 'Available', 'No extra tool required'],
                    ['JSON / CSV', 'Available', 'No extra tool required'],
                    [
                      'DOCX',
                      'Optional, not installed',
                      'Configure when needed'
                    ],
                    ['PDF', 'Optional, not installed', 'Configure when needed'],
                    [
                      'PPTX',
                      'Optional, not installed',
                      'Configure when needed'
                    ],
                  ],
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          providers,
          const SizedBox(height: _DesktopGrid.gutter),
          detail
        ]);
      }
      return _EqualHeightRow(
        height: 386,
        flexes: const [7, 5],
        children: [providers, detail],
      );
    });
  }
}

class _SettingsTextFieldSpec {
  const _SettingsTextFieldSpec(this.label, this.controller, {this.displayText});

  final String label;
  final TextEditingController controller;
  final String? displayText;
}

String _storageStatusLabel(String status, bool zh) {
  return switch (status) {
    'connected' => zh ? '已连接' : 'Connected',
    'configured_not_tested' => zh ? '已配置，待测试' : 'Configured, needs test',
    'desktop_runtime_required' => zh ? '需要处理' : 'Needs action',
    'missing_password' => zh ? '未配置' : 'Not configured',
    'auth_failed' => zh ? '测试失败' : 'Test failed',
    'invalid_endpoint' => zh ? '测试失败' : 'Test failed',
    'invalid_dimension' => zh ? '测试失败' : 'Test failed',
    'invalid_port' => zh ? '测试失败' : 'Test failed',
    'health_failed' => zh ? '测试失败' : 'Test failed',
    'collection_create_failed' => zh ? '测试失败' : 'Test failed',
    'collection_check_failed' => zh ? '测试失败' : 'Test failed',
    'vector_write_failed' => zh ? '测试失败' : 'Test failed',
    'vector_search_failed' => zh ? '测试失败' : 'Test failed',
    'vector_delete_failed' => zh ? '测试失败' : 'Test failed',
    'connection_failed' => zh ? '连接失败' : 'Connection failed',
    'ping_failed' => zh ? '测试失败' : 'Test failed',
    'probe_failed' => zh ? '测试失败' : 'Test failed',
    _ => zh ? '需要处理' : 'Needs action',
  };
}

Map<String, dynamic> _settingsMap(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const {};
}

String _settingsText(Map<String, dynamic> source, String key, String fallback) {
  final value = source[key]?.toString();
  return value == null || value.isEmpty ? fallback : value;
}

int _settingsInt(Map<String, dynamic> source, String key, int fallback) {
  final value = source[key];
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

class _SettingsConnectionForm extends StatelessWidget {
  const _SettingsConnectionForm({
    required this.zh,
    required this.fields,
  });

  final bool zh;
  final List<_SettingsTextFieldSpec> fields;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 760 ? 2 : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: fields.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: _DesktopGrid.gutter,
          mainAxisSpacing: _DesktopGrid.gutter,
          mainAxisExtent: 58,
        ),
        itemBuilder: (context, index) {
          final field = fields[index];
          final displayText = field.displayText;
          if (displayText != null) {
            return TextFormField(
              key: ValueKey<String>('settings-display-${field.label}'),
              initialValue: displayText,
              readOnly: true,
              decoration: InputDecoration(
                labelText: field.label,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            );
          }
          return TextField(
            controller: field.controller,
            obscureText: field.label.toLowerCase().contains('password') ||
                field.label.toLowerCase().contains('key'),
            decoration: InputDecoration(
              labelText: field.label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          );
        },
      );
    });
  }
}

class _SettingsWorkspaceView extends StatelessWidget {
  const _SettingsWorkspaceView({
    required this.zh,
    required this.workspace,
    required this.isWebRuntime,
  });

  final bool zh;
  final String workspace;
  final bool isWebRuntime;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final overview = _ProductPanel(
        keyName: 'settings-workspace-overview',
        icon: Icons.folder_open_outlined,
        title: zh ? '应用工作区' : 'Application Workspace',
        children: [
          _MetricStrip(
            items: [
              _MetricDatum(
                  label: zh ? '工作区' : 'Workspace',
                  value: workspace == '.' ? 'local' : 'set',
                  detail: zh ? '本地路径' : 'local path',
                  icon: Icons.folder_outlined),
              _MetricDatum(
                  label: zh ? '存储' : 'Storage',
                  value: 'local',
                  detail: zh ? '默认' : 'default',
                  icon: Icons.storage_outlined),
              _MetricDatum(
                  label: zh ? '模式' : 'Mode',
                  value: isWebRuntime
                      ? (zh ? '预览' : 'Preview')
                      : (zh ? '桌面端' : 'Desktop'),
                  detail: isWebRuntime
                      ? (zh ? '预览模式' : 'preview mode')
                      : (zh ? '本地文件能力可用' : 'local files available'),
                  icon: isWebRuntime
                      ? Icons.public_outlined
                      : Icons.desktop_windows_outlined),
            ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _ProductTable(
            columns: zh ? ['路径', '当前值', '分类'] : ['Path', 'Value', 'Class'],
            rows: zh
                ? [
                    ['工作区根目录', workspace, '可用'],
                    ['输出目录', '当前用户工作区', '可用'],
                    ['文档缓存', './data/documents', '本地路径'],
                    ['检索数据目录', './data/vector', '本地检索'],
                  ]
                : [
                    ['Workspace root', workspace, 'Available'],
                    ['Output directory', 'Current user workspace', 'Available'],
                    ['Document cache', './data/documents', 'Local path'],
                    ['Vector index dir', './data/vector', 'Local index'],
                  ],
          ),
        ],
      );
      final registry = _ProductPanel(
        keyName: 'settings-asset-registry',
        icon: Icons.inventory_2_outlined,
        title: zh ? '资产注册表' : 'Asset Registry',
        children: [
          _ProductTable(
            columns: zh
                ? ['资产', '类型', '状态', '说明']
                : ['Asset', 'Type', 'Status', 'Note'],
            rows: zh
                ? [
                    ['来源文档', '文档', '已登记', '文档库管理'],
                    ['知识库', '知识库', '已登记', '知识库管理'],
                    ['技能草稿', '技能', '已登记', '技能生成管理'],
                    ['助手创建包', '助手包', '已登记', '我的助手管理'],
                  ]
                : [
                    [
                      'Source documents',
                      'Document',
                      'Registered',
                      'Document Library'
                    ],
                    [
                      'Knowledge Base',
                      'Knowledge Base',
                      'Registered',
                      'Knowledge module'
                    ],
                    ['Skill draft', 'Skill', 'Registered', 'Skill Builder'],
                    [
                      'Assistant package',
                      'Assistant package',
                      'Registered',
                      'My Assistants'
                    ],
                  ],
          ),
        ],
      );
      final policy = _ProductPanel(
        keyName: 'settings-workspace-policy',
        icon: Icons.policy_outlined,
        title: zh ? '备份与保留策略' : 'Backup and Retention Policy',
        gap: true,
        children: [
          _ProductTable(
            columns: zh ? ['项目', '策略', '分类'] : ['Item', 'Policy', 'Class'],
            rows: zh
                ? [
                    ['增量备份', '每日 02:00', '本地计划'],
                    ['本地保留', '30 天，最多 30 个备份', '已配置'],
                    ['缓存清理', '超过保留策略自动删除', '本地策略'],
                    ['云备份', '未启用', '本地优先'],
                  ]
                : [
                    ['Incremental backup', 'Daily 02:00', 'Local schedule'],
                    [
                      'Local retention',
                      '30 days, max 30 backups',
                      'Configured'
                    ],
                    [
                      'Cache cleanup',
                      'Deletes past retention policy',
                      'Local policy'
                    ],
                    ['Cloud backup', 'Not enabled', 'Local-first'],
                  ],
          ),
        ],
      );
      final safety = _ProductPanel(
        keyName: 'settings-local-safety',
        icon: Icons.shield_outlined,
        title: zh ? '本地优先边界' : 'Local-first Boundary',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? '默认网络' : 'Default network',
              value: zh ? '不访问外网' : 'No external network by default'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '密钥' : 'Secret',
              value: zh ? '不直接展示明文' : 'Plaintext is never shown'),
        ],
      );
      if (!wide) {
        return Column(children: [
          overview,
          const SizedBox(height: _DesktopGrid.gutter),
          registry,
          const SizedBox(height: _DesktopGrid.gutter),
          policy,
          const SizedBox(height: _DesktopGrid.gutter),
          safety,
        ]);
      }
      return _EqualHeightRow(
        height: 578,
        flexes: const [7, 5],
        children: [
          _ProductColumn(children: [
            overview,
            const SizedBox(height: _DesktopGrid.gutter),
            registry,
          ]),
          _ProductColumn(children: [
            policy,
            const SizedBox(height: _DesktopGrid.gutter),
            safety,
          ]),
        ],
      );
    });
  }
}
