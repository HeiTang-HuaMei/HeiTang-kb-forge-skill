part of '../../main.dart';

class _SettingsProductWorkflow extends StatelessWidget {
  const _SettingsProductWorkflow({
    required this.localeCode,
    required this.workspace,
    required this.runtimeController,
    required this.selectedTab,
    required this.onTabSelected,
    required this.isWebRuntime,
    required this.campaign7ConfigurationStatus,
    required this.campaign9DesktopDeliveryStatus,
  });

  final String localeCode;
  final String workspace;
  final Rc6RuntimeController? runtimeController;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;
  final bool isWebRuntime;
  final Map<String, dynamic> campaign7ConfigurationStatus;
  final Map<String, dynamic> campaign9DesktopDeliveryStatus;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final tabs = _zh
        ? ['工作区', 'Provider 与存储', '配置系统', '模型与语言', '安全授权', '桌面交付']
        : [
            'Workspace',
            'Providers and Storage',
            'Configuration System',
            'Models and Language',
            'Security Authorization',
            'Desktop Delivery',
          ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.settings_outlined,
        title: _zh ? '运行设置' : 'Run Settings',
        description: _zh
            ? '管理应用工作区、Provider、存储、模型、语言、主题和安全授权。'
            : 'Manage workspace, providers, storage, models, language, theme, and authorization.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _PageTabs(
          tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
      const SizedBox(height: _DesktopGrid.gutter),
      if (selectedTab == 1)
        _SettingsProvidersStorageView(
            zh: _zh, workspace: workspace, runtimeController: runtimeController)
      else if (selectedTab == 2)
        _SettingsConfigurationSystemView(
          zh: _zh,
          campaign7ConfigurationStatus: campaign7ConfigurationStatus,
        )
      else if (selectedTab == 5)
        _SettingsDesktopDeliveryView(
          zh: _zh,
          campaign9DesktopDeliveryStatus: campaign9DesktopDeliveryStatus,
        )
      else if (selectedTab == 0)
        _SettingsWorkspaceView(
          zh: _zh,
          workspace: workspace,
          isWebRuntime: isWebRuntime,
        )
      else
        _ProductPanel(
          keyName: 'settings-groups',
          icon: selectedTab == 3
              ? Icons.memory_outlined
              : selectedTab == 4
                  ? Icons.shield_outlined
                  : Icons.folder_outlined,
          title: tabs[selectedTab],
          children: selectedTab == 3
              ? [
                  _ProductTable(
                    columns: _zh
                        ? ['配置项', '当前值', '状态']
                        : ['Setting', 'Value', 'Status'],
                    rows: _zh
                        ? [
                            ['LLM Provider', 'live smoke 通过', '可用'],
                            [
                              'Embedding 模型',
                              'Provider Runtime env-only',
                              '环境配置'
                            ],
                            ['默认语言', '简体中文 / Chinese', '可用'],
                            ['主题', '浅色 / 深色可切换', '可用'],
                          ]
                        : [
                            ['LLM Provider', 'Live smoke passed', 'Available'],
                            [
                              'Embedding model',
                              'Provider Runtime env-only',
                              'Env config'
                            ],
                            [
                              'Default language',
                              'Simplified Chinese / Chinese',
                              'Available'
                            ],
                            ['Theme', 'Light / dark switchable', 'Available'],
                          ],
                  ),
                  const SizedBox(height: 8),
                  _FieldRow(
                      label: _zh ? '当前语言' : 'Current language',
                      value: _zh ? '中文' : 'English'),
                  const SizedBox(height: 8),
                  _FieldRow(
                      label: _zh ? '主题' : 'Theme',
                      value: _zh ? '跟随切换' : 'Switchable'),
                ]
              : selectedTab == 4
                  ? [
                      _FieldRow(
                          label: _zh ? '云服务' : 'Cloud services',
                          value: _zh ? '默认关闭' : 'Off by default'),
                      const SizedBox(height: 8),
                      _FieldRow(
                          label: _zh ? '敏感信息' : 'Sensitive data',
                          value: _zh
                              ? 'Secret 不直接展示'
                              : 'Secrets are not displayed directly'),
                      const SizedBox(height: 8),
                      _FieldRow(
                          label: _zh ? '桌面能力' : 'Desktop features',
                          value: isWebRuntime
                              ? (_zh
                                  ? '请使用 Windows EXE 执行本地文件能力'
                                  : 'Use the Windows EXE for local file workflows')
                              : (_zh ? '桌面可用' : 'Desktop available')),
                    ]
                  : [
                      _FieldRow(
                          label: _zh ? '工作区' : 'Workspace', value: workspace),
                      const SizedBox(height: 8),
                      _FieldRow(
                          label: _zh ? '输出目录' : 'Output directory',
                          value: _zh ? '当前用户工作区' : 'Current user workspace'),
                    ],
        ),
    ]);
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
            ? '真实 Redis 连接测试需要 Windows EXE 桌面端。'
            : 'Real Redis test requires the Windows desktop runtime.';
      });
      return;
    }
    final port = int.tryParse(_redisPortController.text.trim());
    if (port == null || port <= 0) {
      setState(() {
        storageTested = true;
        redisTested = false;
        redisStatus = 'invalid_port';
        redisDetail = zh ? 'Redis 端口必须是正整数。' : 'Redis port must be positive.';
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
            ? '真实 Qdrant 连接测试需要 Windows EXE 桌面端。'
            : 'Real Qdrant test requires the Windows desktop runtime.';
      });
      return;
    }
    final dimension = int.tryParse(_qdrantDimensionController.text.trim());
    if (dimension == null || dimension <= 0) {
      setState(() {
        storageTested = true;
        qdrantTested = false;
        qdrantStatus = 'invalid_dimension';
        qdrantDetail =
            zh ? 'Qdrant 向量维度必须是正整数。' : 'Qdrant dimension must be positive.';
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
        redisDetail = zh ? 'Redis 端口必须是正整数。' : 'Redis port must be positive.';
      });
      return;
    }
    if (qdrantDimension == null || qdrantDimension <= 0) {
      setState(() {
        configSaved = false;
        storageTested = true;
        qdrantStatus = 'invalid_dimension';
        qdrantDetail =
            zh ? 'Qdrant 向量维度必须是正整数。' : 'Qdrant dimension must be positive.';
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
      if (redisDetail.isNotEmpty) 'Redis: $redisDetail',
      if (qdrantDetail.isNotEmpty) 'Qdrant: $qdrantDetail',
    ];
    if (details.isEmpty) {
      return zh
          ? 'Redis 密码和 Qdrant API Key 只以掩码输入；测试失败不会展示明文 secret。'
          : 'Redis password and Qdrant API key remain masked; failed tests never show plaintext secrets.';
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
        title: zh ? 'Provider 与存储配置' : 'Providers and Storage Config',
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
                      'Redis',
                      '${_redisHostController.text}:${_redisPortController.text} / ${_redisPrefixController.text}',
                      redisTested
                          ? 'PING / 写读删通过'
                          : _storageStatusLabel(redisStatus, zh),
                      redisTested ? '可用' : '已配置'
                    ],
                    [
                      'Qdrant',
                      '${_qdrantEndpointController.text} / ${_qdrantCollectionController.text}',
                      qdrantTested
                          ? '健康检查 / collection / 向量探针通过'
                          : _storageStatusLabel(qdrantStatus, zh),
                      qdrantTested ? '可用' : '已配置'
                    ],
                    ['向量数据库', '本地文件索引 + Qdrant 可选', '本地索引可用', '可用'],
                    ['LLM Provider', '环境变量', 'live smoke 通过', '可用'],
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
                      'Redis',
                      '${_redisHostController.text}:${_redisPortController.text} / ${_redisPrefixController.text}',
                      redisTested
                          ? 'PING / write-read-delete passed'
                          : _storageStatusLabel(redisStatus, zh),
                      redisTested ? 'Available' : 'Configured'
                    ],
                    [
                      'Qdrant',
                      '${_qdrantEndpointController.text} / ${_qdrantCollectionController.text}',
                      qdrantTested
                          ? 'Health / collection / vector probe passed'
                          : _storageStatusLabel(qdrantStatus, zh),
                      qdrantTested ? 'Available' : 'Configured'
                    ],
                    [
                      'Vector DB',
                      'Local file index + optional Qdrant',
                      'Local index available',
                      'Available'
                    ],
                    [
                      'LLM Provider',
                      'Environment variables',
                      'Live smoke passed',
                      'Available'
                    ],
                    ['API Key', '************', 'Masked', 'Protected'],
                  ],
          ),
          const SizedBox(height: 8),
          _SectionCaption(zh ? 'Redis 记忆缓存' : 'Redis memory cache'),
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
          _SectionCaption(zh ? 'Qdrant 知识库检索' : 'Qdrant KB retrieval'),
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
                  ? (zh ? '正在测试 Redis' : 'Testing Redis')
                  : (zh ? '测试 Redis 连接' : 'Test Redis connection'),
              icon: Icons.cable_outlined,
              onPressed: redisTesting ? null : _testRedisConnection,
            ),
          ]),
          const SizedBox(height: 8),
          _EqualActionRow(children: [
            _PrimaryProductAction(
              label: qdrantTesting
                  ? (zh ? '正在测试 Qdrant' : 'Testing Qdrant')
                  : (zh ? '测试 Qdrant 连接' : 'Test Qdrant connection'),
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
          const SizedBox(height: 8),
          _SectionCaption(zh ? 'Provider 运行状态' : 'Provider Runtime Status'),
          const SizedBox(height: 6),
          _ProductTable(
            columns: zh
                ? ['状态', '用户可见含义', '处理方式']
                : ['Status', 'User meaning', 'Handling'],
            rows: zh
                ? [
                    ['connected', 'official_openai 可用', '继续执行'],
                    ['unavailable', 'Provider 暂不可达', '本地能力继续可用'],
                    ['missing_key', '缺少安全环境变量', '提示配置，不显示明文'],
                    ['timeout', '请求超时', '可重试并保留日志编号'],
                    ['fallback_used', '已降级到本地路径', '显示降级原因'],
                    ['cost_blocked', '超过成本/Token 边界', '停止外部调用'],
                  ]
                : [
                    ['connected', 'official_openai available', 'Continue'],
                    [
                      'unavailable',
                      'Provider temporarily unavailable',
                      'Local capabilities continue'
                    ],
                    [
                      'missing_key',
                      'Secure env is missing',
                      'Prompt setup, never show plaintext'
                    ],
                    ['timeout', 'Request timed out', 'Retry with log id'],
                    [
                      'fallback_used',
                      'Local degraded path used',
                      'Show degraded reason'
                    ],
                    [
                      'cost_blocked',
                      'Cost/token boundary exceeded',
                      'Stop external call'
                    ],
                  ],
          ),
        ],
      );
      final detail = _ProductPanel(
        keyName: 'settings-provider-detail',
        icon: Icons.tune_outlined,
        title: zh ? '导出器与授权状态' : 'Exporter and Authorization Status',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? 'Provider 状态' : 'Provider status',
              value: zh
                  ? '真实 live smoke 复验已通过'
                  : 'Real live-smoke reacceptance passed'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? 'Secret 展示' : 'Secret display',
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
          _SectionCaption(zh ? '文档导出器' : 'Document exporters'),
          const SizedBox(height: 6),
          _ProductTable(
            columns: zh
                ? ['格式', '状态', '配置入口']
                : ['Format', 'Status', 'Config entry'],
            rows: zh
                ? [
                    ['Markdown', '本地可用', '无需外部导出器'],
                    ['JSON / CSV', '本地可用', '无需外部导出器'],
                    ['DOCX', '需要导出器配置', '配置导出器后启用'],
                    ['PDF', '需要导出器配置', '配置导出器后启用'],
                    ['PPTX', '需要导出器配置', '配置导出器后启用'],
                  ]
                : [
                    ['Markdown', 'Local available', 'No external exporter'],
                    ['JSON / CSV', 'Local available', 'No external exporter'],
                    ['DOCX', 'Exporter config required', 'Enable after config'],
                    ['PDF', 'Exporter config required', 'Enable after config'],
                    ['PPTX', 'Exporter config required', 'Enable after config'],
                  ],
          ),
          const SizedBox(height: 8),
          _DisplayAction(
              label: zh ? '查看 Provider 状态' : 'View Provider status',
              icon: Icons.verified_outlined),
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
    'missing_password' => zh ? '缺少 Redis 密码' : 'Redis password missing',
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

class _SettingsConfigurationSystemView extends StatelessWidget {
  const _SettingsConfigurationSystemView({
    required this.zh,
    required this.campaign7ConfigurationStatus,
  });

  final bool zh;
  final Map<String, dynamic> campaign7ConfigurationStatus;

  @override
  Widget build(BuildContext context) {
    final schema = _campaign6Map(campaign7ConfigurationStatus['config_schema']);
    final diagnostics =
        _campaign6Map(campaign7ConfigurationStatus['diagnostics']);
    final security =
        _campaign6Map(campaign7ConfigurationStatus['security_boundaries']);
    final statusRows =
        _campaign6List(campaign7ConfigurationStatus['status_matrix'])
            .map((item) => [
                  _campaignText(item['capability']),
                  _campaignText(item['status']),
                  _campaignText(item['ui_state']),
                ])
            .toList(growable: false);
    final degradedRows =
        _campaign6List(campaign7ConfigurationStatus['degraded_modes'])
            .map((item) => [
                  _campaignText(item['condition']),
                  _campaignText(item['runtime_status']),
                  _campaignText(item['user_message']),
                ])
            .toList(growable: false);
    final securityRows = security.entries
        .map((entry) => [
              entry.key,
              entry.value == true ? 'pass' : 'fail',
            ])
        .toList(growable: false);
    final sourcePrecedence =
        _campaignStringList(schema['source_precedence']).join(' > ');

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 980;
      final overview = _ProductPanel(
        keyName: 'settings-configuration-system',
        icon: Icons.rule_folder_outlined,
        title: zh ? '配置系统' : 'Configuration System',
        gap: true,
        children: [
          _MetricStrip(
            items: [
              _MetricDatum(
                  label: zh ? '总状态' : 'Overall',
                  value: _campaignText(
                      campaign7ConfigurationStatus['overall_status']),
                  detail: zh ? '已绑定 UI' : 'UI-bound',
                  icon: Icons.fact_check_outlined),
              _MetricDatum(
                  label: zh ? 'Schema' : 'Schema',
                  value: _campaignText(schema['schema_version']),
                  detail: zh ? '统一配置' : 'unified config',
                  icon: Icons.schema_outlined),
              _MetricDatum(
                  label: zh ? 'UI' : 'UI',
                  value: _capabilityStatusLabel(
                      _campaignText(_campaign6Map(
                              campaign7ConfigurationStatus['ui_settings'])[
                          'ui_state']),
                      zh),
                  detail: zh ? 'Settings 绑定' : 'Settings binding',
                  icon: Icons.settings_outlined),
            ],
          ),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '配置来源优先级' : 'Config source precedence',
              value: sourcePrecedence),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? 'Secret 展示' : 'Secret display',
              value: _campaignText(
                  _campaign6Map(campaign7ConfigurationStatus['ui_settings'])[
                      'masked_secret_display'])),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh
                ? ['能力', '状态', 'UI 状态']
                : ['Capability', 'Status', 'UI state'],
            rows: statusRows
                .map((row) =>
                    [row[0], row[1], _capabilityStatusLabel(row[2], zh)])
                .toList(growable: false),
          ),
        ],
      );
      final diagnosticsPanel = _ProductPanel(
        keyName: 'settings-configuration-diagnostics',
        icon: Icons.health_and_safety_outlined,
        title: zh ? '配置健康' : 'Configuration Health',
        gap: true,
        children: [
          _ProductTable(
            columns: zh ? ['配置项', '状态'] : ['Configuration item', 'Status'],
            rows: zh
                ? [
                    [
                      '模型 Provider',
                      _settingsHealthLabel(diagnostics['provider_runtime'], zh)
                    ],
                    [
                      'Agent 工作台配置',
                      _settingsHealthLabel(diagnostics['agent_runtime'], zh)
                    ],
                    [
                      '知识库 / RAG 配置',
                      _settingsHealthLabel(diagnostics['rag'], zh)
                    ],
                    [
                      '工作区路径',
                      _settingsHealthLabel(diagnostics['workspace'], zh)
                    ],
                    [
                      '界面设置',
                      _settingsHealthLabel(diagnostics['ui_settings'], zh)
                    ],
                  ]
                : [
                    [
                      'Model Provider',
                      _settingsHealthLabel(diagnostics['provider_runtime'], zh)
                    ],
                    [
                      'Agent Workbench config',
                      _settingsHealthLabel(diagnostics['agent_runtime'], zh)
                    ],
                    [
                      'Knowledge Base / RAG config',
                      _settingsHealthLabel(diagnostics['rag'], zh)
                    ],
                    [
                      'Workspace path',
                      _settingsHealthLabel(diagnostics['workspace'], zh)
                    ],
                    [
                      'UI settings',
                      _settingsHealthLabel(diagnostics['ui_settings'], zh)
                    ],
                  ],
          ),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh
                ? ['条件', '当前状态', '用户提示']
                : ['Condition', 'Status', 'User prompt'],
            rows: degradedRows,
          ),
        ],
      );
      final securityPanel = _ProductPanel(
        keyName: 'settings-configuration-security',
        icon: Icons.verified_user_outlined,
        title: zh ? '安全授权' : 'Security Authorization',
        gap: true,
        children: [
          _ProductTable(
            columns: zh ? ['检查', '结果'] : ['Check', 'Result'],
            rows: securityRows,
          ),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '模型 Provider 复用' : 'Model Provider reuse',
              value: _campaignText(
                  _campaign6Map(schema['runtime_reuse'])['provider_runtime'])),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? 'Agent 工作台复用' : 'Agent Workbench reuse',
              value: _campaignText(
                  _campaign6Map(schema['runtime_reuse'])['agent_runtime'])),
        ],
      );
      if (!wide) {
        return Column(children: [
          overview,
          const SizedBox(height: _DesktopGrid.gutter),
          diagnosticsPanel,
          const SizedBox(height: _DesktopGrid.gutter),
          securityPanel,
        ]);
      }
      return Column(children: [
        _EqualHeightRow(
          height: 430,
          flexes: const [7, 5],
          children: [overview, diagnosticsPanel],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        securityPanel,
      ]);
    });
  }
}

class _SettingsDesktopDeliveryView extends StatelessWidget {
  const _SettingsDesktopDeliveryView({
    required this.zh,
    required this.campaign9DesktopDeliveryStatus,
  });

  final bool zh;
  final Map<String, dynamic> campaign9DesktopDeliveryStatus;

  @override
  Widget build(BuildContext context) {
    final delivery =
        _campaign6Map(campaign9DesktopDeliveryStatus['delivery_path']);
    final packageInfo =
        _campaign6Map(campaign9DesktopDeliveryStatus['package']);
    final checksum = _campaign6Map(campaign9DesktopDeliveryStatus['checksum']);
    final smoke =
        _campaign6Map(campaign9DesktopDeliveryStatus['desktop_shell_smoke']);
    final pathRules =
        _campaign6Map(campaign9DesktopDeliveryStatus['path_rules']);
    final security =
        _campaign6Map(campaign9DesktopDeliveryStatus['security_boundaries']);
    final validationRows =
        _campaign6List(campaign9DesktopDeliveryStatus['validation_matrix'])
            .map((item) => [
                  _campaignText(item['capability']),
                  _campaignText(item['status']),
                  _campaignText(item['ui_state']),
                  _productRecordText(item['evidence']),
                ])
            .toList(growable: false);
    final smokeRows = _campaign6List(smoke['steps'])
        .map((item) => [
              _campaignText(item['step']),
              _campaignText(item['result']),
            ])
        .toList(growable: false);
    final degradedRows =
        _campaign6List(campaign9DesktopDeliveryStatus['degraded_modes'])
            .map((item) => [
                  _campaignText(item['condition']),
                  _campaignText(item['runtime_status']),
                  _campaignText(item['user_message']),
                ])
            .toList(growable: false);
    final securityRows = security.entries
        .map((entry) => [
              entry.key,
              entry.value == true ? 'pass' : 'fail',
            ])
        .toList(growable: false);
    final pathRows = pathRules.entries
        .map((entry) => [entry.key, _campaignText(entry.value)])
        .toList(growable: false);

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 980;
      final overview = _ProductPanel(
        keyName: 'settings-desktop-delivery',
        icon: Icons.desktop_windows_outlined,
        title: zh ? '桌面交付' : 'Desktop Delivery',
        gap: true,
        children: [
          _MetricStrip(
            items: [
              _MetricDatum(
                  label: zh ? '本地状态' : 'Local status',
                  value: _campaignText(
                      campaign9DesktopDeliveryStatus['overall_status']),
                  detail: zh ? '等待人工复查' : 'pending manual review',
                  icon: Icons.fact_check_outlined),
              _MetricDatum(
                  label: zh ? '候选标签' : 'Candidate tag',
                  value: _campaignText(
                      campaign9DesktopDeliveryStatus['release_candidate_tag']),
                  detail: zh ? '未发布稳定版' : 'no stable release',
                  icon: Icons.local_offer_outlined),
              _MetricDatum(
                  label: zh ? '包版本' : 'Package version',
                  value: _campaignText(campaign9DesktopDeliveryStatus[
                      'package_version_baseline']),
                  detail: zh ? '候选包' : 'candidate package',
                  icon: Icons.inventory_2_outlined),
            ],
          ),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh
                ? ['能力', '状态', '用户可见状态', '验证记录']
                : ['Capability', 'Status', 'User status', 'Validation record'],
            rows: validationRows
                .map((row) => [
                      row[0],
                      row[1],
                      _capabilityStatusLabel(row[2], zh),
                      row[3]
                    ])
                .toList(growable: false),
          ),
        ],
      );
      final packagePanel = _ProductPanel(
        keyName: 'settings-desktop-package',
        icon: Icons.inventory_outlined,
        title: zh ? 'Windows 包与校验' : 'Windows Package and Checksum',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? '交付路径' : 'Delivery path',
              value: _campaignText(delivery['accepted_packaging_path'])),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? 'EXE' : 'EXE',
              value: _campaignText(packageInfo['exe'])),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '文件数量 / 大小' : 'Files / size',
              value:
                  '${_campaignText(packageInfo['file_count'])} / ${_campaignText(packageInfo['total_size_bytes'])} bytes'),
          const SizedBox(height: 8),
          _FieldRow(
              label: 'SHA-256', value: _campaignText(checksum['exe_sha256'])),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '桌面外壳' : 'Desktop shell',
              value: _campaignText(delivery['legacy_tauri_status'])),
        ],
      );
      final smokePanel = _ProductPanel(
        keyName: 'settings-desktop-smoke',
        icon: Icons.monitor_heart_outlined,
        title: zh ? '真实桌面冒烟' : 'Real Desktop Smoke',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? '冒烟状态' : 'Smoke status',
              value: _campaignText(smoke['status'])),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '验证记录' : 'Validation record',
              value: _productRecordText(smoke['evidence_path'])),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh ? ['步骤', '结果'] : ['Step', 'Result'],
            rows: smokeRows,
          ),
        ],
      );
      final boundaryPanel = _ProductPanel(
        keyName: 'settings-desktop-boundary',
        icon: Icons.verified_user_outlined,
        title: zh ? '路径、恢复与安全授权' : 'Paths, Recovery, and Security',
        gap: true,
        children: [
          _ProductTable(
            columns: zh ? ['路径规则', '说明'] : ['Path rule', 'Description'],
            rows: pathRows,
          ),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh
                ? ['场景', '当前状态', '用户提示']
                : ['Scenario', 'Status', 'User prompt'],
            rows: degradedRows,
          ),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh ? ['安全检查', '结果'] : ['Security check', 'Result'],
            rows: securityRows,
          ),
        ],
      );

      if (!wide) {
        return Column(children: [
          overview,
          const SizedBox(height: _DesktopGrid.gutter),
          packagePanel,
          const SizedBox(height: _DesktopGrid.gutter),
          smokePanel,
          const SizedBox(height: _DesktopGrid.gutter),
          boundaryPanel,
        ]);
      }
      return Column(children: [
        _EqualHeightRow(
          height: 470,
          flexes: const [7, 5],
          children: [overview, packagePanel],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _EqualHeightRow(
          height: 520,
          flexes: const [5, 7],
          children: [smokePanel, boundaryPanel],
        ),
      ]);
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
                    ['向量索引目录', './data/vector', '本地索引'],
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
                    ['来源文档', 'Document', '已登记', '文档库管理'],
                    ['知识库', 'Knowledge Base', '已登记', '知识库管理'],
                    ['Skill 草稿', 'Skill', '已登记', 'Skill 工厂管理'],
                    [
                      'Agent Creation Package',
                      'Agent Package',
                      '已登记',
                      'Agent 工作台管理'
                    ],
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
                    ['Skill draft', 'Skill', 'Registered', 'Skill Factory'],
                    [
                      'Agent Creation Package',
                      'Agent Package',
                      'Registered',
                      'Agent Workbench'
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
              label: zh ? 'Secret' : 'Secret',
              value: zh ? '不直接展示明文' : 'Plaintext is never shown'),
          const SizedBox(height: 8),
          _DisplayAction(
            label: zh ? '查看 Provider 验收证据' : 'View Provider evidence',
            icon: Icons.verified_outlined,
          ),
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
