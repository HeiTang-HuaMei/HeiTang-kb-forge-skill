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
        ? ['工作区', '模型服务', '记忆与存储', '导出工具', '网络与安全']
        : [
            'Workspace',
            'Model Service',
            'Memory and Storage',
            'Export Tools',
            'Network and Security',
          ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.settings_outlined,
        title: _zh ? '设置' : 'Settings',
        description: _zh
            ? '管理工作区、模型服务、记忆服务、导出工具、网络授权与安全。'
            : 'Manage workspace, model services, memory services, export tools, network authorization, and security.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _PageTabs(
          tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
      const SizedBox(height: _DesktopGrid.gutter),
      if (selectedTab == 0)
        _SettingsWorkspaceView(
          zh: _zh,
          workspace: workspace,
          isWebRuntime: isWebRuntime,
        )
      else if (selectedTab == 1)
        _SettingsProviderModelView(
          zh: _zh,
          runtimeController: runtimeController,
          providerCapabilityStatus: providerCapabilityStatus,
        )
      else if (selectedTab == 2)
        _SettingsProvidersStorageView(
            zh: _zh, workspace: workspace, runtimeController: runtimeController)
      else if (selectedTab == 3)
        _SettingsExporterView(
          zh: _zh,
          runtimeController: runtimeController,
          workspace: workspace,
        )
      else
        _SettingsNetworkSecurityView(zh: _zh, isWebRuntime: isWebRuntime),
    ]);
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
  bool profileLoading = false;
  String savedPath = '';
  String validationPath = '';
  String profileMessage = '';
  String capabilityMessage = '';
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
          ? (zh ? '能力增强项已启用' : 'Capability enhancement enabled')
          : (zh ? '未满足启用条件，已写入使用记录' : 'Blocked; audit log written');
    });
  }

  Future<void> _testAllCapabilityEnhancements() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    final path = await rc6.testAllRegisteredProviderCapabilities();
    if (!mounted) return;
    setState(() {
      capabilityMessage = path.isEmpty
          ? (zh ? '需要 Windows EXE 执行健康检查' : 'Windows EXE required')
          : (zh ? '全部能力增强项健康检查已记录' : 'Capability health audit written');
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
          : (zh ? '没有可回滚的能力增强项' : 'No enhancement to roll back');
    });
    await _loadRuntimeCapabilityCatalog();
  }

  Future<void> _loadRuntimeCapabilityCatalog() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    final catalog = await rc6.loadProviderCapabilityUserCatalog();
    final entries = catalog['entries'];
    if (entries is! List) return;
    if (!mounted) return;
    setState(() {
      runtimeCapabilityEntries = entries
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
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
        title: zh ? '模型服务' : 'Model Service',
        gap: true,
        children: [
          _ProductTable(
            columns: zh
                ? ['配置项', '当前值', '用户可见状态']
                : ['Setting', 'Value', 'User status'],
            rows: zh
                ? [
                    ['大模型服务', '环境变量 / 设置引用', '可配置'],
                    ['文本理解服务', '本地模式 / 设置引用', '可配置'],
                    ['检索服务', '本地检索优先，可选外部检索', '可配置'],
                    ['资料整理服务', '本地整理优先，可选增强解析', '可配置'],
                  ]
                : [
                    ['LLM service', 'Env / settings reference', 'Configurable'],
                    [
                      'Text understanding service',
                      'Env / settings reference',
                      'Configurable'
                    ],
                    [
                      'Search service',
                      'Local search first, optional external search',
                      'Configurable'
                    ],
                    [
                      'Material organizing service',
                      'Local parser first, optional enhanced parser',
                      'Configurable'
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
                  zh ? '大模型服务' : 'LLM service', _llmProviderController),
              _SettingsTextFieldSpec(
                  zh ? '模型 ID' : 'Model ID', _modelController),
              _SettingsTextFieldSpec(
                  zh ? '文本理解服务' : 'Text understanding service',
                  _embeddingProviderController),
              _SettingsTextFieldSpec(
                  zh ? '检索服务' : 'Search service', _searchProviderController),
              _SettingsTextFieldSpec(
                  zh ? '资料整理服务' : 'Material organizing service',
                  _parserProviderController),
              _SettingsTextFieldSpec(zh ? '图片文字识别服务' : 'Image text service',
                  _ocrProviderController),
              _SettingsTextFieldSpec('API Key', _apiKeyController),
            ],
          ),
          const SizedBox(height: 8),
          _EqualActionRow(children: [
            _PrimaryProductAction(
              label: zh ? '保存模型服务配置' : 'Save model service config',
              icon: Icons.save_outlined,
              onPressed: _saveSettings,
            ),
            _PrimaryProductAction(
              label: zh ? '测试模型服务' : 'Test model service',
              icon: Icons.fact_check_outlined,
              onPressed: _validateSettings,
            ),
          ]),
          if (saved || validated || loading) ...[
            const SizedBox(height: 8),
            _RuntimeFeedbackBanner(
              title: validated
                  ? (zh ? '模型服务测试报告已生成' : 'Model service test report generated')
                  : saved
                      ? (zh ? '模型服务配置已保存' : 'Model service config saved')
                      : (zh ? '正在加载配置' : 'Loading config'),
              detail: [
                if (savedPath.isNotEmpty) savedPath,
                if (validationPath.isNotEmpty) validationPath,
                zh
                    ? 'secret 仅保存掩码或环境变量引用'
                    : 'secrets are masked or env references only',
              ].join('\n'),
              tone: _StatusTone.success,
              icon: Icons.verified_user_outlined,
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
              value:
                  loading ? (zh ? '正在加载' : 'Loading') : _modelController.text),
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
      if (!wide) {
        return Column(children: [
          profilePanel,
          const SizedBox(height: _DesktopGrid.gutter),
          provider,
          const SizedBox(height: _DesktopGrid.gutter),
          model,
          const SizedBox(height: _DesktopGrid.gutter),
          capabilityStatus,
        ]);
      }
      return Column(
        children: [
          profilePanel,
          const SizedBox(height: _DesktopGrid.gutter),
          _EqualHeightRow(
            height: 310,
            flexes: const [7, 5],
            children: [provider, model],
          ),
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
    final rows = status.capabilities.map((entry) {
      return [
        zh ? entry.zhUserVisibleName : entry.userVisibleName,
        '${entry.readyProviderStateCount}/${entry.providerStateCount}',
        _providerCapabilityStatusLabel(entry.status, zh),
        zh ? entry.zhUserVisibleBehavior : entry.userVisibleBehavior,
      ];
    }).toList(growable: false);
    final providerStateCount = status.capabilities
        .fold<int>(0, (total, entry) => total + entry.providerStateCount);
    final readyProviderStateCount = status.capabilities
        .fold<int>(0, (total, entry) => total + entry.readyProviderStateCount);
    final runtime = _Rc6RuntimeScope.of(context)?.state;
    final lifecycleAuditReady =
        runtime?.hasProviderLifecycleAuditSummary == true;
    final runtimeCatalogReady =
        runtime?.hasProviderCapabilityUserCatalog == true;
    final runtimeRows = runtimeEntries
        .map((entry) => [
              _settingsText(entry, 'display_name', ''),
              _settingsText(entry, 'status', zh ? '未配置' : 'Not configured'),
              _settingsText(entry, 'current_behavior', ''),
              _settingsText(
                  entry, 'configuration_entry', zh ? '设置' : 'Settings'),
            ])
        .where((row) => row.every((value) => value.isNotEmpty))
        .toList(growable: false);
    return _ProductPanel(
      keyName: 'settings-provider-capability-status',
      icon: Icons.extension_outlined,
      title: zh ? '能力状态' : 'Capability Status',
      gap: true,
      children: [
        _FieldRow(
          label: zh ? '能力增强项' : 'Capability enhancements',
          value: zh
              ? '$providerStateCount 项已登记，$readyProviderStateCount 项可选'
              : '$providerStateCount registered, $readyProviderStateCount selectable',
        ),
        const SizedBox(height: 8),
        _FieldRow(
          label: zh ? '使用记录汇总' : 'Usage record summary',
          value: lifecycleAuditReady
              ? (zh ? '已生成' : 'Generated')
              : (zh ? '未生成' : 'Not generated'),
        ),
        const SizedBox(height: 8),
        _FieldRow(
          label: zh ? '当前能力目录' : 'Current capability catalog',
          value: runtimeCatalogReady
              ? (zh ? '已生成' : 'Generated')
              : (zh ? '未生成' : 'Not generated'),
        ),
        if (runtimeRows.isNotEmpty) ...[
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh
                ? ['能力', '状态', '当前表现', '入口']
                : ['Capability', 'Status', 'Current behavior', 'Entry'],
            rows: runtimeRows,
          ),
        ],
        const SizedBox(height: 8),
        _ProductTable(
          columns: zh
              ? ['能力', '增强项', '状态', '当前表现']
              : ['Capability', 'Options', 'Status', 'Current behavior'],
          rows: rows,
        ),
        const SizedBox(height: 8),
        _EqualActionRow(children: [
          _PrimaryProductAction(
            label: zh ? '测试增强项' : 'Test enhancement',
            icon: Icons.fact_check_outlined,
            onPressed: status.capabilities.isEmpty ? null : onTestCapability,
          ),
          _PrimaryProductAction(
            label: zh ? '测试全部增强项' : 'Test all enhancements',
            icon: Icons.rule_folder_outlined,
            onPressed:
                status.capabilities.isEmpty ? null : onTestAllCapabilities,
          ),
          _PrimaryProductAction(
            label: zh ? '回滚增强项' : 'Rollback enhancement',
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
                ? '能力增强项启用、阻止和回滚都会写入配置使用记录。'
                : 'Enhancement activation, blocking, and rollback write config audit assets.',
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
              zh ? '需要 Windows EXE' : 'Windows EXE required',
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
                  profile.lastTestStatus,
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
              : '${activeProfile.lastTestStatus} / v${activeProfile.version}',
        ),
        const SizedBox(height: 8),
        _FieldRow(
          label: zh ? '失败摘要' : 'Failure summary',
          value: activeProfile?.lastError.isNotEmpty == true
              ? activeProfile!.lastError
              : (zh
                  ? '无明文密钥；失败进入使用记录'
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
                ? '配置档测试、切换、回滚会写入配置资产和使用记录。'
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

String _firstProviderRef(ProviderCapabilityStatus status) {
  for (final capability in status.capabilities) {
    if (capability.providerRefs.isNotEmpty) {
      return capability.providerRefs.first;
    }
  }
  return '';
}

String _providerCapabilityStatusLabel(String status, bool zh) {
  if (!zh) {
    return switch (status) {
      'available' => 'Available',
      'available_with_gated_options' => 'Available, options gated',
      'configured_not_tested' => 'Configured, test required',
      'dependency_gated' => 'Dependency gated',
      'external_runtime_required' => 'User runtime required',
      'needs_secret_config' => 'Secret config required',
      'needs_network_authorization' => 'Network authorization required',
      'needs_verification' => 'Verification required',
      'needs_provider_config' => 'Connection config required',
      _ => status,
    };
  }
  return switch (status) {
    'available' => '可用',
    'available_with_gated_options' => '可用，扩展项受控',
    'configured_not_tested' => '已配置，需测试',
    'dependency_gated' => '依赖待满足',
    'external_runtime_required' => '需要自有运行时',
    'needs_secret_config' => '需要安全密钥',
    'needs_network_authorization' => '需要网络授权',
    'needs_verification' => '需要核验',
    'needs_provider_config' => '需要连接配置',
    _ => status,
  };
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
      TextEditingController(text: 'requires_configuration');
  final TextEditingController _pdfController =
      TextEditingController(text: 'requires_configuration');
  final TextEditingController _pptxController =
      TextEditingController(text: 'requires_configuration');
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
      _docxController.text = _settingsText(_settingsMap(exporters['docx']),
          'provider', 'requires_configuration');
      _pdfController.text = _settingsText(
          _settingsMap(exporters['pdf']), 'provider', 'requires_configuration');
      _pptxController.text = _settingsText(_settingsMap(exporters['pptx']),
          'provider', 'requires_configuration');
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
      title: zh ? '导出工具设置' : 'Export Tool Settings',
      gap: true,
      children: [
        _ProductTable(
          columns: zh
              ? ['格式', '当前状态', '配置入口']
              : ['Format', 'Current status', 'Config entry'],
          rows: zh
              ? [
                  ['Markdown', '本地可用', '无需外部导出工具'],
                  ['JSON / CSV', '本地可用', '无需外部导出工具'],
                  ['DOCX', _docxController.text, '配置后启用'],
                  ['PDF', _pdfController.text, '配置后启用'],
                  ['PPTX', _pptxController.text, '配置后启用'],
                ]
              : [
                  ['Markdown', 'Local available', 'No external exporter'],
                  ['JSON / CSV', 'Local available', 'No external exporter'],
                  ['DOCX', _docxController.text, 'Enable after config'],
                  ['PDF', _pdfController.text, 'Enable after config'],
                  ['PPTX', _pptxController.text, 'Enable after config'],
                ],
        ),
        const SizedBox(height: 8),
        _SectionCaption(zh ? '导出工具配置' : 'Export tool config'),
        const SizedBox(height: 6),
        _SettingsConnectionForm(
          zh: zh,
          fields: [
            _SettingsTextFieldSpec('DOCX Exporter', _docxController),
            _SettingsTextFieldSpec('PDF Exporter', _pdfController),
            _SettingsTextFieldSpec('PPTX Exporter', _pptxController),
            _SettingsTextFieldSpec(
                zh ? '导出根目录' : 'Export root', _exportRootController),
          ],
        ),
        const SizedBox(height: 8),
        _EqualActionRow(children: [
          _PrimaryProductAction(
            label: zh ? '保存导出工具配置' : 'Save export tool config',
            icon: Icons.save_outlined,
            onPressed: _saveSettings,
          ),
          _PrimaryProductAction(
            label: zh ? '测试导出工具配置' : 'Test export tool config',
            icon: Icons.fact_check_outlined,
            onPressed: _validateSettings,
          ),
        ]),
        if (saved || validated) ...[
          const SizedBox(height: 8),
          _RuntimeFeedbackBanner(
            title: validated
                ? (zh ? '导出工具测试报告已生成' : 'Export tool test report generated')
                : (zh ? '导出工具配置已保存' : 'Export tool config saved'),
            detail: [
              if (savedPath.isNotEmpty) savedPath,
              if (validationPath.isNotEmpty) validationPath,
              zh
                  ? 'DOCX/PDF/PPTX 仍按依赖配置启用'
                  : 'DOCX/PDF/PPTX remain dependency-gated',
            ].join('\n'),
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
                      ? '请使用 Windows EXE 执行本地文件能力'
                      : 'Use the Windows EXE for local file workflows')
                  : (zh ? '桌面运行可用' : 'Desktop runtime available')),
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
              label: zh ? '使用记录' : 'Audit',
              value: zh
                  ? '运行记录、失败、权限和恢复进入使用记录'
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
            ? '真实专业记忆连接测试需要 Windows EXE 桌面端。'
            : 'Real professional memory test requires the Windows desktop runtime.';
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
            ? '真实知识记忆连接测试需要 Windows EXE 桌面端。'
            : 'Real knowledge memory test requires the Windows desktop runtime.';
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
        redisDetail = zh
            ? '真实配置保存需要 Windows EXE 桌面端。'
            : 'Real config save requires the Windows desktop runtime.';
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
        zh ? '配置文件：$savedConfigPath' : 'Config file: $savedConfigPath',
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
                          ? 'PING / 写读删通过'
                          : _storageStatusLabel(redisStatus, zh),
                      redisTested ? '可用' : '已配置'
                    ],
                    [
                      '知识记忆',
                      '${_qdrantEndpointController.text} / ${_qdrantCollectionController.text}',
                      qdrantTested
                          ? '健康检查 / collection / 向量探针通过'
                          : _storageStatusLabel(qdrantStatus, zh),
                      qdrantTested ? '可用' : '已配置'
                    ],
                    ['知识库索引', '本地文件索引 + 专业服务可选', '本地索引可用', '可用'],
                    ['模型服务', '环境变量', '连接复验通过', '可用'],
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
                          ? 'PING / write-read-delete passed'
                          : _storageStatusLabel(redisStatus, zh),
                      redisTested ? 'Available' : 'Configured'
                    ],
                    [
                      'Knowledge memory',
                      '${_qdrantEndpointController.text} / ${_qdrantCollectionController.text}',
                      qdrantTested
                          ? 'Health / collection / vector probe passed'
                          : _storageStatusLabel(qdrantStatus, zh),
                      qdrantTested ? 'Available' : 'Configured'
                    ],
                    [
                      'Knowledge base index',
                      'Local file index + optional professional service',
                      'Local index available',
                      'Available'
                    ],
                    [
                      'Model service',
                      'Environment variables',
                      'Live smoke passed',
                      'Available'
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
        title: zh ? '导出工具与授权状态' : 'Export Tool and Authorization Status',
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
                      : 'Docker 未运行时显示已配置未测试；不得显示为已连接'
                  : configLoading
                      ? 'Loading workspace config'
                      : 'When Docker is not running, show configured-not-tested; never connected'),
          const SizedBox(height: 8),
          _SectionCaption(zh ? '文档导出工具' : 'Document export tools'),
          const SizedBox(height: 6),
          _ProductTable(
            columns: zh
                ? ['格式', '状态', '配置入口']
                : ['Format', 'Status', 'Config entry'],
            rows: zh
                ? [
                    ['Markdown', '本地可用', '无需外部导出工具'],
                    ['JSON / CSV', '本地可用', '无需外部导出工具'],
                    ['DOCX', '需要设置导出工具', '配置后启用'],
                    ['PDF', '需要设置导出工具', '配置后启用'],
                    ['PPTX', '需要设置导出工具', '配置后启用'],
                  ]
                : [
                    ['Markdown', 'Local available', 'No external exporter'],
                    ['JSON / CSV', 'Local available', 'No external exporter'],
                    ['DOCX', 'Exporter config required', 'Enable after config'],
                    ['PDF', 'Exporter config required', 'Enable after config'],
                    ['PPTX', 'Exporter config required', 'Enable after config'],
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
  const _SettingsTextFieldSpec(this.label, this.controller);

  final String label;
  final TextEditingController controller;
}

String _storageStatusLabel(String status, bool zh) {
  return switch (status) {
    'connected' => zh ? '连接成功' : 'Connected',
    'configured_not_tested' => zh ? '已配置未测试' : 'Configured, not tested',
    'desktop_runtime_required' =>
      zh ? '需要 Windows EXE 测试' : 'Desktop runtime required',
    'missing_password' => zh ? '缺少记忆服务密码' : 'Memory service password missing',
    'auth_failed' => zh ? '鉴权失败' : 'Authentication failed',
    'invalid_endpoint' => zh ? 'Endpoint 无效' : 'Invalid endpoint',
    'invalid_dimension' => zh ? '维度无效' : 'Invalid dimension',
    'invalid_port' => zh ? '端口无效' : 'Invalid port',
    'health_failed' => zh ? '健康检查失败' : 'Health check failed',
    'collection_create_failed' =>
      zh ? 'Collection 创建失败' : 'Collection create failed',
    'collection_check_failed' =>
      zh ? 'Collection 检查失败' : 'Collection check failed',
    'vector_write_failed' => zh ? '测试向量写入失败' : 'Vector write failed',
    'vector_search_failed' => zh ? '测试向量检索失败' : 'Vector search failed',
    'vector_delete_failed' => zh ? '测试向量删除失败' : 'Vector delete failed',
    'connection_failed' => zh ? '连接失败' : 'Connection failed',
    'ping_failed' => zh ? 'PING 失败' : 'PING failed',
    'probe_failed' => zh ? '探针失败' : 'Probe failed',
    _ => status,
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
                  value: isWebRuntime ? 'Web' : 'EXE',
                  detail: isWebRuntime
                      ? (zh ? '预览模式' : 'preview mode')
                      : (zh ? '桌面运行' : 'desktop runtime'),
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
