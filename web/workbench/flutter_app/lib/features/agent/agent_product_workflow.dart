part of '../../main.dart';

class _AgentProductWorkflow extends StatelessWidget {
  const _AgentProductWorkflow({
    required this.localeCode,
    required this.workspace,
    required this.campaign6AgentRuntimeStatus,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final String localeCode;
  final String workspace;
  final Map<String, dynamic> campaign6AgentRuntimeStatus;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final tabs = _zh
        ? ['助手总览', '单个助手', '多个助手讨论', '使用记录']
        : [
            'Assistant Overview',
            'Single Assistant',
            'Assistant Discussion',
            'Usage Records'
          ];
    final activeTab =
        selectedTab >= tabs.length ? tabs.length - 1 : selectedTab;
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.smart_toy_outlined,
        title: _zh ? '我的助手' : 'My Assistants',
        description: _zh
            ? '创建助手、绑定知识库与技能，并在本页让多个助手一起讨论。'
            : 'Create assistants, bind knowledge bases and skills, and run assistant discussions here.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _MetricStrip(
        items: [
          _MetricDatum(
              label: _zh ? '助手模板' : 'Assistant templates',
              value: '5',
              detail: _zh
                  ? '问答 / 总结 / 质检 / 运营 / 产品'
                  : 'QA / summary / QA / ops / product',
              icon: Icons.psychology_alt_outlined),
          _MetricDatum(
              label: _zh ? '助手产物' : 'Assistant package',
              value: runtime.hasAgent ? 'real' : '0',
              detail: runtime.hasAgent
                  ? (_zh ? '已生成' : 'generated')
                  : (_zh ? '等待生成' : 'waiting generation'),
              icon: Icons.smart_toy_outlined),
          _MetricDatum(
              label: _zh ? '对话记录' : 'Dialogue',
              value: runtime.hasAgentDialogue ? '1' : '0',
              detail: runtime.hasAgentDialogue
                  ? (_zh ? '已保存' : 'saved')
                  : (_zh ? '等待对话' : 'waiting chat'),
              icon: Icons.chat_bubble_outline),
          _MetricDatum(
              label: _zh ? '讨论纪要' : 'Discussion notes',
              value: runtime.hasMultiAgentDiscussion ? '1' : '0',
              detail: runtime.hasMultiAgentDiscussion
                  ? (_zh ? '已生成' : 'generated')
                  : (_zh ? '等待讨论' : 'waiting discussion'),
              icon: Icons.groups_2_outlined),
        ],
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _PageTabs(
          tabs: tabs, selectedIndex: activeTab, onSelected: onTabSelected),
      const SizedBox(height: _DesktopGrid.gutter),
      switch (activeTab) {
        1 => _SingleAgentWorkspaceView(
            zh: _zh,
            workspace: workspace,
            onAgentCreated: () => onTabSelected(1),
          ),
        2 => _AgentDiscussionProductView(zh: _zh),
        3 => _AgentRunAuditView(zh: _zh),
        _ => _AgentWorkspaceProductView(zh: _zh, workspace: workspace),
      },
    ]);
  }
}

class _AgentRunAuditView extends StatelessWidget {
  const _AgentRunAuditView({required this.zh});

  final bool zh;

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final dialogueStatus = runtime.hasAgentDialogueHistory
        ? (zh ? '已记录' : 'Recorded')
        : (zh ? '未运行' : 'Not run');
    final exportStatus = runtime.hasAgentDialogueExport
        ? (zh ? '已导出' : 'Exported')
        : (zh ? '未导出' : 'Not exported');
    final a2aStatus = runtime.hasA2aSessionManifest
        ? (zh ? '已记录' : 'Recorded')
        : (zh ? '未运行' : 'Not run');
    final permissionStatus = runtime.hasAgentWorkspacePermissionMatrix
        ? (zh ? '已校验' : 'Checked')
        : (zh ? '等待助手工作区' : 'Waiting assistant workspace');
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final runRecords = _ProductPanel(
        keyName: 'agent-run-history',
        icon: Icons.fact_check_outlined,
        title: zh ? '使用记录' : 'Usage Records',
        subtitle: zh
            ? '查看助手对话、导出、协作讨论和权限校验状态。'
            : 'Review assistant chat, export, discussion, and permission status.',
        children: [
          _ProductTable(
            columns: zh ? ['对象', '状态', '用户可见结果'] : ['Item', 'Status', 'Result'],
            rows: zh
                ? [
                    [
                      '单个助手对话',
                      dialogueStatus,
                      '${runtime.agentDialogueTurnCount} 轮'
                    ],
                    [
                      '对话导出',
                      exportStatus,
                      runtime.hasAgentDialogueExport ? '可在成果中心查看' : '等待导出'
                    ],
                    [
                      '多个助手讨论',
                      a2aStatus,
                      runtime.a2aTopic.isEmpty ? '等待协作议题' : runtime.a2aTopic
                    ],
                    [
                      '权限校验',
                      permissionStatus,
                      runtime.hasAgentWorkspacePermissionMatrix
                          ? '工作区权限已留痕'
                          : '创建助手后生成'
                    ],
                  ]
                : [
                    [
                      'Single assistant dialogue',
                      dialogueStatus,
                      '${runtime.agentDialogueTurnCount} turns'
                    ],
                    [
                      'Dialogue export',
                      exportStatus,
                      runtime.hasAgentDialogueExport
                          ? 'Visible in Artifact Center'
                          : 'Waiting export'
                    ],
                    [
                      'Assistant discussion',
                      a2aStatus,
                      runtime.a2aTopic.isEmpty
                          ? 'Waiting topic'
                          : runtime.a2aTopic
                    ],
                    [
                      'Permission audit',
                      permissionStatus,
                      runtime.hasAgentWorkspacePermissionMatrix
                          ? 'Workspace permissions recorded'
                          : 'Generated after assistant creation'
                    ],
                  ],
          ),
        ],
      );
      final recovery = _ProductPanel(
        keyName: 'agent-audit-recovery',
        icon: Icons.restore_outlined,
        title: zh ? '异常记录' : 'Exception Records',
        children: [
          _ProductTable(
            columns: zh ? ['检查项', '状态'] : ['Check', 'Status'],
            rows: zh
                ? [
                    ['配置缺失', runtime.lastError.isEmpty ? '未发现' : '已记录'],
                    [
                      '对话失败',
                      runtime.hasAgentDialogueHistory ? '有运行记录' : '无运行记录'
                    ],
                    ['协作分歧', runtime.hasA2aSessionManifest ? '有协作记录' : '无协作记录'],
                    [
                      '权限异常',
                      runtime.hasAgentWorkspacePermissionMatrix ? '已记录' : '等待记录'
                    ],
                  ]
                : [
                    [
                      'Missing configuration',
                      runtime.lastError.isEmpty ? 'Not detected' : 'Recorded'
                    ],
                    [
                      'Dialogue failure',
                      runtime.hasAgentDialogueHistory
                          ? 'Run recorded'
                          : 'No run record'
                    ],
                    [
                      'Discussion conflict',
                      runtime.hasA2aSessionManifest
                          ? 'Collaboration recorded'
                          : 'No collaboration record'
                    ],
                    [
                      'Permission issue',
                      runtime.hasAgentWorkspacePermissionMatrix
                          ? 'Audited'
                          : 'Waiting audit'
                    ],
                  ],
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          runRecords,
          const SizedBox(height: _DesktopGrid.gutter),
          recovery,
        ]);
      }
      return _EqualHeightRow(
        height: 420,
        flexes: const [7, 4],
        children: [runRecords, recovery],
      );
    });
  }
}

class _SingleAgentWorkspaceView extends StatelessWidget {
  const _SingleAgentWorkspaceView({
    required this.zh,
    required this.workspace,
    required this.onAgentCreated,
  });

  final bool zh;
  final String workspace;
  final VoidCallback onAgentCreated;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _AgentCreationProductView(
        zh: zh,
        workspace: workspace,
        onAgentCreated: onAgentCreated,
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _AgentMinimalChatView(zh: zh),
    ]);
  }
}

class _AgentWorkspaceProductView extends StatelessWidget {
  const _AgentWorkspaceProductView({
    required this.zh,
    required this.workspace,
  });

  final bool zh;
  final String workspace;

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final capabilityAuditReady = runtime.hasProviderCapabilityUserCatalog;
    final modelStatus = capabilityAuditReady
        ? (zh ? '按当前配置执行' : 'Uses current configuration')
        : (zh ? '未配置模型时仅本地产物可用' : 'Local artifacts only without model');
    final memoryStatus = runtime.agentDialogueMemoryWriteStatus.isNotEmpty
        ? runtime.agentDialogueMemoryWriteStatus
        : capabilityAuditReady
            ? (zh ? '按当前配置，可降级本地文件' : 'Configured, local file fallback')
            : (zh ? '本地文件记忆' : 'Local file memory');
    final vectorMemoryStatus = runtime.memoryIndexReferencePath.isNotEmpty
        ? (zh ? '长期记忆索引已生成' : 'Long-term memory index generated')
        : capabilityAuditReady
            ? (zh
                ? '未连接时不影响单个助手对话'
                : 'Dialogue continues without professional memory')
            : (zh
                ? '未配置专业长期记忆'
                : 'Professional long-term memory not configured');
    final collaborationStatus = runtime.hasA2aSessionManifest
        ? (zh ? '协作记录已生成' : 'Collaboration recorded')
        : capabilityAuditReady
            ? (zh ? '本地协作报告可用' : 'Local discussion report available')
            : (zh ? '等待创建助手' : 'Waiting for assistant');
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final setup = _ProductPanel(
        keyName: 'agent-workspace-setup',
        icon: Icons.account_tree_outlined,
        title: zh ? '助手工作区' : 'Assistant Workspace',
        subtitle: runtime.hasAgent
            ? _displayNameForPath(runtime.agentPath)
            : (zh ? '当前工作区' : '$workspace/workbench_runs/agent/workspaces'),
        children: [
          _ProductTable(
            columns: zh
                ? ['列表', '用途', '当前状态']
                : ['List', 'Purpose', 'Current state'],
            rows: zh
                ? [
                    ['模型', '助手问答与协作', modelStatus],
                    ['短期记忆', '对话上下文', memoryStatus],
                    ['长期记忆', '知识记忆', vectorMemoryStatus],
                    ['协作导出', '多个助手讨论', collaborationStatus],
                    [
                      '助手列表',
                      '知识应用统一管理',
                      runtime.hasAgent ? 'K1 + S1' : '生成助手后写入'
                    ],
                    [
                      '会话列表',
                      '单个助手对话历史',
                      runtime.hasAgentDialogue ? '已有会话' : '创建后立即对话'
                    ],
                    [
                      '多个助手讨论区',
                      '协作会话管理',
                      runtime.hasAgent ? '各自知识库 / 技能' : '等待助手'
                    ],
                  ]
                : [
                    ['Model', 'Assistant chat and discussion', modelStatus],
                    ['Short-term memory', 'Dialogue context', memoryStatus],
                    [
                      'Long-term memory',
                      'Knowledge memory',
                      vectorMemoryStatus
                    ],
                    [
                      'Collaboration export',
                      'Assistant discussion',
                      collaborationStatus
                    ],
                    [
                      'Assistant list',
                      'Knowledge apps managed together',
                      runtime.hasAgent ? 'K1 + S1' : 'Written after generate'
                    ],
                    [
                      'Session list',
                      'Single assistant dialogue history',
                      runtime.hasAgentDialogue
                          ? 'Has session'
                          : 'Chat after creation'
                    ],
                    [
                      'Assistant discussion workspace',
                      'Collaboration session management',
                      runtime.hasAgent ? 'Own KB / Skill' : 'Waiting assistant'
                    ],
                  ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _PrimaryProductAction(
            label: zh ? '创建助手并进入对话' : 'Create assistant and chat',
            icon: Icons.account_tree_outlined,
            onPressed: runtime.running || rc6 == null
                ? null
                : () => rc6.completeAgentProductOperations(),
          ),
        ],
      );
      final boundaries = _ProductPanel(
        keyName: 'agent-workspace-boundary',
        icon: Icons.policy_outlined,
        title: zh ? '运行状态' : 'Run Status',
        children: [
          _ProductTable(
            columns: zh ? ['项目', '状态'] : ['Item', 'Status'],
            rows: zh
                ? [
                    ['绑定知识库', runtime.hasKnowledgeBase ? '已绑定' : '等待知识库'],
                    ['绑定技能', runtime.hasSkill ? '已绑定' : '等待技能'],
                    ['单个助手对话', runtime.hasAgentDialogue ? '已有记录' : '未运行'],
                    [
                      '多个助手讨论',
                      runtime.hasMultiAgentDiscussion ? '已有纪要' : '未运行'
                    ],
                  ]
                : [
                    [
                      'Knowledge Base',
                      runtime.hasKnowledgeBase ? 'Bound' : 'Waiting KB'
                    ],
                    ['Skill', runtime.hasSkill ? 'Bound' : 'Waiting Skill'],
                    [
                      'Single assistant chat',
                      runtime.hasAgentDialogue ? 'Has record' : 'Not run'
                    ],
                    [
                      'Assistant discussion',
                      runtime.hasMultiAgentDiscussion ? 'Has notes' : 'Not run'
                    ],
                  ],
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          setup,
          const SizedBox(height: _DesktopGrid.gutter),
          boundaries,
        ]);
      }
      return _EqualHeightRow(
        height: 420,
        flexes: const [7, 4],
        children: [setup, boundaries],
      );
    });
  }
}

class _AgentCreationProductView extends StatefulWidget {
  const _AgentCreationProductView({
    required this.zh,
    required this.workspace,
    required this.onAgentCreated,
  });

  final bool zh;
  final String workspace;
  final VoidCallback onAgentCreated;

  @override
  State<_AgentCreationProductView> createState() =>
      _AgentCreationProductViewState();
}

class _AgentCreationProductViewState extends State<_AgentCreationProductView> {
  String creationMode = 'simple';
  String agentType = 'knowledge_qa';
  String outputFormat = 'markdown';
  final TextEditingController _agentNameController =
      TextEditingController(text: '知识问答助手');
  final TextEditingController _modelConfigController =
      TextEditingController(text: 'local-default-or-configured-provider');
  final TextEditingController _roleGoalController =
      TextEditingController(text: '只基于绑定知识库和技能回答，输出必须带引用。');

  bool get zh => widget.zh;
  String get workspace => widget.workspace;

  Rc6AgentGenerationConfig get _agentConfig => Rc6AgentGenerationConfig(
        customAgentName: _agentNameController.text,
        creationMode: creationMode,
        agentType: agentType,
        modelConfigId: _modelConfigController.text.trim().isEmpty
            ? 'local-default-or-configured-provider'
            : _modelConfigController.text.trim(),
        outputFormat: outputFormat,
        roleGoal: _roleGoalController.text,
      );

  @override
  void dispose() {
    _agentNameController.dispose();
    _modelConfigController.dispose();
    _roleGoalController.dispose();
    super.dispose();
  }

  String _creationModeLabel(String value) => value == 'advanced'
      ? (zh ? '复杂构造' : 'Advanced build')
      : (zh ? '简单构造' : 'Simple build');

  String _agentTypeLabel(String value) => switch (value) {
        'reading_summary' => zh ? '阅读总结助手' : 'Reading Summary Assistant',
        'quality_qa' => zh ? '质检助手' : 'Quality Assistant',
        'operation_conversion' => zh ? '运营转化助手' : 'Ops Conversion Assistant',
        'product_analysis' => zh ? '产品分析助手' : 'Product Analysis Assistant',
        _ => zh ? '知识问答助手' : 'Knowledge QA Assistant',
      };

  Future<void> _confirmAndDeleteAgent(
      BuildContext context, Rc6RuntimeController? rc6) async {
    if (rc6 == null || rc6.state.running || !rc6.state.hasAgent) return;
    final confirmed = await _confirmDestructiveAction(
      context,
      title: zh ? '删除助手产物？' : 'Delete assistant artifacts?',
      body: zh
          ? '这会删除当前工作区里的助手、对话和联合讨论产物；知识库和技能保留。'
          : 'This deletes assistant, chat, and team discussion artifacts in this workspace; KB and Skill are kept.',
    );
    if (!confirmed) return;
    await rc6.clearAgentArtifacts();
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final simpleMode = creationMode == 'simple';
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final create = _ProductPanel(
        keyName: 'agent-create-product-flow',
        icon: Icons.smart_toy_outlined,
        title: zh ? '创建助手' : 'Create Assistant',
        subtitle: runtime.hasAgent
            ? _displayNameForPath(runtime.agentPath)
            : (zh ? '当前工作区' : '$workspace/workbench_runs/agent'),
        children: [
          _FieldRow(
              label: zh ? '当前构造模式' : 'Current build mode',
              value: _creationModeLabel(creationMode)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final item in const ['simple', 'advanced'])
              ChoiceChip(
                label: Text(_creationModeLabel(item)),
                selected: creationMode == item,
                onSelected: (_) => setState(() => creationMode = item),
              ),
          ]),
          const SizedBox(height: 8),
          TextField(
            key: const Key('agent-name-input'),
            controller: _agentNameController,
            enabled: rc6 != null && !runtime.running,
            decoration: InputDecoration(
              labelText: zh ? '助手名称' : 'Assistant name',
              helperText: zh
                  ? '创建后保存到当前助手工作区。'
                  : 'Saved to the current assistant workspace after creation.',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '助手类型' : 'Assistant type',
              value: _agentTypeLabel(agentType)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final item in const [
              'knowledge_qa',
              'reading_summary',
              'quality_qa',
              'operation_conversion',
              'product_analysis',
            ])
              ChoiceChip(
                label: Text(_agentTypeLabel(item)),
                selected: agentType == item,
                onSelected: (_) => setState(() => agentType = item),
              ),
          ]),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '输出格式' : 'Output format',
              value: outputFormat.toUpperCase()),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final item in const ['markdown', 'json', 'report', 'chat'])
              ChoiceChip(
                label: Text(item.toUpperCase()),
                selected: outputFormat == item,
                onSelected: (_) => setState(() => outputFormat = item),
              ),
          ]),
          const SizedBox(height: 8),
          TextField(
            key: const Key('agent-model-config-input'),
            controller: _modelConfigController,
            enabled: rc6 != null && !runtime.running,
            decoration: InputDecoration(
              labelText: zh ? '模型配置' : 'Model config',
              helperText: zh
                  ? '引用设置页已保存的模型服务；密钥仍只掩码显示。'
                  : 'References saved model service settings; secrets stay masked.',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('agent-role-goal-input'),
            controller: _roleGoalController,
            enabled: rc6 != null && !runtime.running,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: zh ? '角色说明' : 'Role instructions',
              helperText: zh
                  ? '用于生成助手配置、对话上下文和使用记录。'
                  : 'Used in assistant configuration, chat context, and usage records.',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _ProductTable(
            columns: zh
                ? ['助手', '构造模式', '知识库', '技能', '创建后动作']
                : ['Assistant', 'Build mode', 'KB', 'Skill', 'After creation'],
            rows: zh
                ? [
                    [
                      '知识问答助手',
                      '简单助手',
                      runtime.hasKnowledgeBase ? '已绑定' : '请先构建知识库',
                      runtime.hasSkill ? '已绑定' : '请先生成技能',
                      '立即进入单个助手对话'
                    ],
                    [
                      '阅读总结助手',
                      '简单助手',
                      runtime.hasKnowledgeBase ? '已绑定' : '请先构建知识库',
                      runtime.hasSkill ? '已绑定' : '请先生成技能',
                      '立即进入单个助手对话'
                    ],
                    [
                      '质检 / 运营 / 产品分析助手',
                      '复杂助手',
                      runtime.hasKnowledgeBase ? '已绑定' : '请先构建知识库',
                      runtime.hasSkill ? '已绑定' : '请先生成技能',
                      '写入记忆 / 工具设置 / 使用记录'
                    ],
                  ]
                : [
                    [
                      'Knowledge QA Assistant',
                      'Simple Assistant',
                      runtime.hasKnowledgeBase ? 'Bound' : 'Build KB first',
                      runtime.hasSkill ? 'Bound' : 'Generate Skill first',
                      'Enter single assistant chat'
                    ],
                    [
                      'Reading Summary Assistant',
                      'Simple Assistant',
                      runtime.hasKnowledgeBase ? 'Bound' : 'Build KB first',
                      runtime.hasSkill ? 'Bound' : 'Generate Skill first',
                      'Enter single assistant chat'
                    ],
                    [
                      'QA / Ops / Product Analysis Assistants',
                      'Advanced Assistant',
                      runtime.hasKnowledgeBase ? 'Bound' : 'Build KB first',
                      runtime.hasSkill ? 'Bound' : 'Generate Skill first',
                      'Write memory / tool / audit config'
                    ],
                  ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _PrimaryProductAction(
            label: zh ? '创建助手并进入对话' : 'Create assistant and open chat',
            icon: Icons.smart_toy_outlined,
            onPressed: runtime.running || rc6 == null
                ? null
                : () async {
                    await rc6.completeAgentProductOperations(
                      config: _agentConfig,
                    );
                    if (mounted) widget.onAgentCreated();
                  },
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _MoreActionsButton(
            label: zh ? '更多助手操作' : 'More assistant actions',
            actions: [
              _MoreMenuAction(
                label: zh ? '删除助手产物' : 'Delete assistant artifacts',
                icon: Icons.delete_outline,
                destructive: true,
                enabled: runtime.hasAgent,
                onSelected: () => _confirmAndDeleteAgent(context, rc6),
              ),
            ],
          ),
        ],
      );
      final detail = _ProductPanel(
        keyName: 'agent-binding-detail',
        icon: Icons.link_outlined,
        title: simpleMode
            ? (zh ? '简单助手对话配置' : 'Simple Assistant Chat Config')
            : (zh ? '复杂助手运行配置' : 'Advanced Assistant Runtime Config'),
        children: [
          _FieldRow(
            label: zh ? '知识库' : 'Knowledge Base',
            value: runtime.hasKnowledgeBase
                ? _displayNameForPath(runtime.kbManifestPath)
                : (zh ? '等待知识库' : 'Waiting KB'),
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '技能' : 'Skill',
            value: runtime.hasSkill
                ? _displayNameForPath(runtime.skillPath)
                : (zh ? '等待技能' : 'Waiting Skill'),
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '创建后动作' : 'After creation',
            value: zh
                ? '创建后立即进入单个助手对话'
                : 'Open single assistant chat immediately after creation',
          ),
          if (simpleMode) ...[
            const SizedBox(height: 8),
            _FieldRow(
              label: zh ? '对话历史' : 'Dialogue history',
              value: runtime.hasAgentDialogue
                  ? (zh ? '已有会话记录' : 'Conversation saved')
                  : (zh ? '首次对话后写入' : 'Written after first chat'),
            ),
          ] else ...[
            const SizedBox(height: 8),
            _FieldRow(
              label: zh ? '专业短期记忆' : 'Professional short-term memory',
              value: zh
                  ? '使用设置中的专业记忆服务；未通过连接测试时回退本地会话'
                  : 'Uses configured memory service; falls back to local session if untested',
            ),
            const SizedBox(height: 8),
            _FieldRow(
              label: zh ? '专业长期记忆' : 'Professional long-term memory',
              value: zh
                  ? '绑定设置中的知识记忆服务；未配置时使用本地模式'
                  : 'Uses configured knowledge memory service; local mode when unconfigured',
            ),
            const SizedBox(height: 8),
            _FieldRow(
              label: zh ? '输出格式' : 'Output',
              value: zh
                  ? 'Markdown / JSON / report / chat'
                  : 'Markdown / JSON / report / chat',
            ),
          ],
        ],
      );
      if (!wide) {
        return Column(children: [
          create,
          const SizedBox(height: _DesktopGrid.gutter),
          detail
        ]);
      }
      return _EqualHeightRow(
        height: 420,
        flexes: const [7, 4],
        children: [create, detail],
      );
    });
  }
}

class _AgentDiscussionProductView extends StatefulWidget {
  const _AgentDiscussionProductView({required this.zh});

  final bool zh;

  @override
  State<_AgentDiscussionProductView> createState() =>
      _AgentDiscussionProductViewState();
}

class _AgentDiscussionProductViewState
    extends State<_AgentDiscussionProductView> {
  final TextEditingController _topicController =
      TextEditingController(text: '围绕当前知识库形成产品与运营行动建议。');
  final Set<String> _selectedParticipants = {
    'reading_summary_agent',
    'operation_conversion_agent',
    'product_analysis_agent',
  };

  bool get zh => widget.zh;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  String _agentLabel(String id) => switch (id) {
        'reading_summary_agent' => zh ? '阅读总结助手' : 'Reading Summary',
        'knowledge_qa_agent' => zh ? '知识问答助手' : 'Knowledge QA',
        'quality_qa_agent' => zh ? '质检助手' : 'Quality',
        'operation_conversion_agent' => zh ? '运营转化助手' : 'Ops Conversion',
        'product_analysis_agent' => zh ? '产品分析助手' : 'Product Analysis',
        _ => id,
      };

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final sessionId = runtime.a2aSessionId.isEmpty
        ? (zh ? '尚未启动' : 'Not started')
        : runtime.a2aSessionId;
    final topic = runtime.a2aTopic.isEmpty
        ? (zh ? '启动后读取协作议题' : 'Topic read after start')
        : runtime.a2aTopic;
    final participants = runtime.a2aParticipantAgentIds.isEmpty
        ? (zh ? '启动后读取' : 'Read after start')
        : runtime.a2aParticipantAgentIds.join(' / ');
    final a2aStatus = runtime.a2aStatus.isEmpty
        ? (runtime.hasMultiAgentDiscussion
            ? (zh ? '已生成' : 'Generated')
            : (zh ? '未运行' : 'Not run'))
        : runtime.a2aStatus;
    return _ProductPanel(
      keyName: 'multi-agent-discussion-product-flow',
      icon: Icons.groups_2_outlined,
      title: zh ? '多个助手一起讨论' : 'Assistant Discussion',
      subtitle: runtime.hasMultiAgentDiscussion
          ? _displayNameForPath(runtime.multiAgentDiscussionPath)
          : (zh ? '等待助手产物' : 'Waiting for assistant package'),
      children: [
        _ProductTable(
          columns: zh
              ? ['工作区 / 助手', '输入', '输出']
              : ['Workspace / Assistant', 'Input', 'Output'],
          rows: zh
              ? [
                  ['W_M 总工作区', '协作议题', '共识 / 冲突 / 行动建议'],
                  ['W_B 运营助手', 'K2 + S2', '运营转化观点'],
                  ['W_C 产品分析助手', 'K3 + 产品分析技能', '产品判断'],
                  ['质检助手', '已整理资料', '风险与复核点'],
                ]
              : [
                  [
                    'W_M parent workspace',
                    'Collaboration topic',
                    'Consensus / conflict / actions'
                  ],
                  ['W_B Ops Assistant', 'K2 + S2', 'Ops conversion view'],
                  [
                    'W_C Product Assistant',
                    'K3 + product Skill',
                    'Product judgement'
                  ],
                  ['Quality Assistant', 'Organized materials', 'Review risks'],
                ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        TextField(
          key: const Key('a2a-topic-input'),
          controller: _topicController,
          enabled: !runtime.running,
          decoration: InputDecoration(
            labelText: zh ? '协作议题' : 'Collaboration topic',
            helperText: zh
                ? '写入协作会话、讨论纪要和使用记录。'
                : 'Written to discussion session, notes, and usage records.',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          minLines: 2,
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        _SectionCaption(zh ? '选择参与助手' : 'Select participant assistants'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final id in const [
            'reading_summary_agent',
            'knowledge_qa_agent',
            'quality_qa_agent',
            'operation_conversion_agent',
            'product_analysis_agent',
          ])
            FilterChip(
              key: Key('a2a-agent-$id'),
              label: Text(_agentLabel(id)),
              selected: _selectedParticipants.contains(id),
              onSelected: runtime.running
                  ? null
                  : (selected) => setState(() {
                        if (selected) {
                          _selectedParticipants.add(id);
                        } else if (_selectedParticipants.length > 1) {
                          _selectedParticipants.remove(id);
                        }
                      }),
            ),
        ]),
        const SizedBox(height: _DesktopGrid.gutter),
        _FieldRow(
          label: zh ? '协作会话' : 'Discussion session',
          value: sessionId,
        ),
        const SizedBox(height: 8),
        _FieldRow(
          label: zh ? '协作议题' : 'Collaboration topic',
          value: topic,
        ),
        const SizedBox(height: 8),
        _FieldRow(
          label: zh ? '讨论纪要' : 'Discussion notes',
          value: runtime.hasMultiAgentDiscussion
              ? _displayNameForPath(runtime.multiAgentDiscussionPath)
              : (zh ? '尚未生成' : 'Not generated'),
        ),
        const SizedBox(height: 8),
        _ProductTable(
          columns: zh ? ['项目', '状态'] : ['Item', 'Status'],
          rows: zh
              ? [
                  ['参与助手', participants],
                  [
                    '证据引用',
                    runtime.hasMultiAgentDiscussion
                        ? '${runtime.a2aEvidenceCount} 条'
                        : '启动后统计'
                  ],
                  ['会话状态', a2aStatus],
                  ['运行前置', runtime.hasSkill ? '技能已生成' : '请先生成技能'],
                  ['冲突报告', runtime.hasA2aConflictReport ? '已生成' : '启动后生成'],
                  ['共识报告', runtime.hasA2aConsensusReport ? '已生成' : '启动后生成'],
                ]
              : [
                  ['Participant assistants', participants],
                  [
                    'Evidence citations',
                    runtime.hasMultiAgentDiscussion
                        ? '${runtime.a2aEvidenceCount}'
                        : 'Counted after start'
                  ],
                  ['Session status', a2aStatus],
                  [
                    'Prerequisite',
                    runtime.hasSkill
                        ? 'Skill generated'
                        : 'Generate Skill first'
                  ],
                  [
                    'Conflict report',
                    runtime.hasA2aConflictReport ? 'Generated' : 'After start'
                  ],
                  [
                    'Consensus report',
                    runtime.hasA2aConsensusReport ? 'Generated' : 'After start'
                  ],
                ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _PrimaryProductAction(
          label: zh ? '让多个助手一起讨论' : 'Start assistant discussion',
          icon: Icons.forum_outlined,
          onPressed: runtime.running ||
                  rc6 == null ||
                  !runtime.hasAgent ||
                  !runtime.hasSkill
              ? null
              : () => rc6.runMultiAgentDiscussion(
                    topic: _topicController.text,
                    participantAgentIds: _selectedParticipants.toList(),
                  ),
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _DisplayAction(
          label: runtime.hasMultiAgentDiscussion
              ? (zh ? '查看讨论纪要' : 'View discussion notes')
              : (zh ? '等待可预览纪要' : 'Waiting for previewable notes'),
          icon: Icons.article_outlined,
          onPressed: runtime.hasMultiAgentDiscussion
              ? () => _showWorkspaceArtifactPreview(
                    context,
                    rc6: rc6,
                    title: zh ? '联合讨论纪要预览' : 'Discussion notes preview',
                    path: runtime.multiAgentDiscussionPath,
                    unavailableMessage:
                        zh ? '尚未生成可预览讨论纪要。' : 'No discussion notes generated.',
                    closeLabel: zh ? '关闭' : 'Close',
                  )
              : null,
        ),
      ],
    );
  }
}

class _AgentMinimalChatView extends StatefulWidget {
  const _AgentMinimalChatView({required this.zh});

  final bool zh;

  @override
  State<_AgentMinimalChatView> createState() => _AgentMinimalChatViewState();
}

class _AgentMinimalChatViewState extends State<_AgentMinimalChatView> {
  final TextEditingController _promptController =
      TextEditingController(text: '请基于当前知识库总结核心要点。');

  bool get zh => widget.zh;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndClearDialogue(
      BuildContext context, Rc6RuntimeController? rc6) async {
    if (rc6 == null ||
        rc6.state.running ||
        !rc6.state.hasAgentDialogueHistory) {
      return;
    }
    final confirmed = await _confirmDestructiveAction(
      context,
      title: zh ? '清空单个助手对话？' : 'Clear single assistant dialogue?',
      body: zh
          ? '这会删除当前助手的对话内容、会话历史和对话导出；助手配置、技能、知识库和协作产物不会被删除。'
          : 'This deletes the current assistant dialogue, chat history, and dialogue export; assistant config, Skill, KB, and discussion artifacts are kept.',
    );
    if (!confirmed) return;
    await rc6.clearAgentDialogueHistory();
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final kbIds = runtime.agentDialogueUsedKbIds.isEmpty
          ? (zh ? '运行后读取' : 'Read after run')
          : runtime.agentDialogueUsedKbIds.join(' / ');
      final skillIds = runtime.agentDialogueUsedSkillIds.isEmpty
          ? (zh ? '运行后读取' : 'Read after run')
          : runtime.agentDialogueUsedSkillIds.join(' / ');
      final modelConfig = runtime.agentDialogueModelConfigId.isEmpty
          ? (zh ? '运行后读取' : 'Read after run')
          : runtime.agentDialogueModelConfigId;
      final memoryStatus = runtime.agentDialogueMemoryWriteStatus.isEmpty
          ? (zh ? '运行后写入' : 'Written after run')
          : runtime.agentDialogueMemoryWriteStatus;
      final errorStatus = runtime.agentDialogueErrorMessage.isEmpty
          ? (runtime.hasAgentDialogue
              ? (zh ? '无错误' : 'No error')
              : (zh ? '未运行' : 'Not run'))
          : runtime.agentDialogueErrorMessage;
      final chat = _ProductPanel(
        keyName: 'agent-minimal-chat',
        icon: Icons.chat_bubble_outline,
        title: zh ? '助手对话' : 'Assistant Chat',
        gap: true,
        children: [
          TextField(
            controller: _promptController,
            enabled: !runtime.running,
            decoration: InputDecoration(
              labelText: zh ? '对话问题' : 'Prompt',
              helperText: zh
                  ? '基于已生成助手、知识库和技能生成本地可追踪对话记录；创建后可立即运行。'
                  : 'Creates a local traceable dialogue from the generated assistant, KB, and Skill; runnable immediately after creation.',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _PrimaryProductAction(
            label: zh ? '开始对话' : 'Start chat',
            icon: Icons.play_arrow_outlined,
            onPressed: runtime.running ||
                    rc6 == null ||
                    !runtime.hasAgent ||
                    !runtime.hasSkill
                ? null
                : () => rc6.runAgentDialogue(prompt: _promptController.text),
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _FieldRow(
            label: zh ? '对话记录' : 'Dialogue',
            value: runtime.hasAgentDialogue
                ? (zh ? '已保存' : 'Saved')
                : (zh ? '尚未生成' : 'Not generated'),
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '会话历史' : 'Chat history',
            value: runtime.hasAgentDialogueHistory
                ? (zh
                    ? '${runtime.agentDialogueTurnCount} 轮'
                    : '${runtime.agentDialogueTurnCount} turns')
                : (zh ? '尚未生成' : 'Not generated'),
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '导出记录' : 'Exported dialogue',
            value: runtime.hasAgentDialogueExport
                ? _displayNameForPath(runtime.agentDialogueExportPath)
                : (zh ? '尚未导出' : 'Not exported'),
          ),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh ? ['项目', '状态'] : ['Item', 'Status'],
            rows: zh
                ? [
                    ['绑定知识库', kbIds],
                    ['绑定技能', skillIds],
                    [
                      '引用证据',
                      runtime.hasAgentDialogue
                          ? '${runtime.agentDialogueEvidenceCount} 条'
                          : '运行后统计'
                    ],
                    ['记忆写入', memoryStatus],
                    ['错误状态', errorStatus],
                  ]
                : [
                    ['Bound KB', kbIds],
                    ['Bound Skill', skillIds],
                    [
                      'Citations',
                      runtime.hasAgentDialogue
                          ? '${runtime.agentDialogueEvidenceCount}'
                          : 'Counted after run'
                    ],
                    ['Memory write', memoryStatus],
                    ['Error status', errorStatus],
                  ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _EqualActionRow(children: [
            _DisplayAction(
              label: runtime.hasAgentDialogue
                  ? (zh ? '查看对话内容' : 'View dialogue content')
                  : (zh ? '等待可预览对话' : 'Waiting for previewable dialogue'),
              icon: Icons.article_outlined,
              onPressed: runtime.hasAgentDialogue
                  ? () => _showWorkspaceArtifactPreview(
                        context,
                        rc6: rc6,
                        title: zh ? '对话内容预览' : 'Dialogue content preview',
                        path: runtime.agentDialoguePath,
                        unavailableMessage:
                            zh ? '尚未生成可预览对话。' : 'No dialogue generated.',
                        closeLabel: zh ? '关闭' : 'Close',
                      )
                  : null,
            ),
            _PrimaryProductAction(
              label: runtime.hasAgentDialogueHistory
                  ? (zh ? '导出对话记录' : 'Export dialogue')
                  : (zh ? '等待可导出历史' : 'Waiting for exportable history'),
              icon: Icons.file_download_outlined,
              onPressed: runtime.hasAgentDialogueHistory &&
                      rc6 != null &&
                      !runtime.running
                  ? () => rc6.exportAgentDialogue()
                  : null,
            ),
          ]),
          const SizedBox(height: _DesktopGrid.gutter),
          _MoreActionsButton(
            label: zh ? '更多对话操作' : 'More chat actions',
            actions: [
              _MoreMenuAction(
                label: zh ? '查看会话历史' : 'View chat history',
                icon: Icons.article_outlined,
                enabled: runtime.hasAgentDialogueHistory,
                onSelected: () => _showWorkspaceArtifactPreview(
                  context,
                  rc6: rc6,
                  title: zh ? '会话历史预览' : 'Chat history preview',
                  path: runtime.agentDialogueHistoryPath,
                  unavailableMessage:
                      zh ? '尚未生成可预览会话历史。' : 'No chat history generated.',
                  closeLabel: zh ? '关闭' : 'Close',
                ),
              ),
              _MoreMenuAction(
                label: zh ? '查看导出记录' : 'View export',
                icon: Icons.article_outlined,
                enabled: runtime.hasAgentDialogueExport,
                onSelected: () => _showWorkspaceArtifactPreview(
                  context,
                  rc6: rc6,
                  title: zh ? '导出对话预览' : 'Dialogue export preview',
                  path: runtime.agentDialogueExportPath,
                  unavailableMessage:
                      zh ? '尚未生成可预览导出。' : 'No dialogue export generated.',
                  closeLabel: zh ? '关闭' : 'Close',
                ),
              ),
              _MoreMenuAction(
                label: zh ? '清空对话历史' : 'Clear dialogue history',
                icon: Icons.delete_sweep_outlined,
                destructive: true,
                enabled: runtime.hasAgentDialogueHistory &&
                    rc6 != null &&
                    !runtime.running,
                onSelected: () => _confirmAndClearDialogue(context, rc6),
              ),
            ],
          ),
        ],
      );
      final bindings = _ProductPanel(
        keyName: 'agent-chat-bindings',
        icon: Icons.link_outlined,
        title: zh ? '绑定状态' : 'Binding Status',
        children: [
          _ProductTable(
            columns: zh ? ['输入', '状态'] : ['Input', 'Status'],
            rows: zh
                ? [
                    [
                      '知识库',
                      runtime.hasKnowledgeBase ? '已绑定' : '请先构建知识库',
                    ],
                    [
                      '技能',
                      runtime.hasSkill ? '已绑定' : '请先生成技能',
                    ],
                    [
                      '助手',
                      runtime.hasAgent ? '已生成' : '请先生成助手',
                    ],
                    ['模型', modelConfig],
                    ['对话记录', runtime.hasAgentDialogue ? '已保存' : '未运行'],
                  ]
                : [
                    [
                      'Knowledge Base',
                      runtime.hasKnowledgeBase ? 'Bound' : 'Build KB first',
                    ],
                    [
                      'Skill',
                      runtime.hasSkill ? 'Bound' : 'Generate Skill first',
                    ],
                    [
                      'Agent',
                      runtime.hasAgent ? 'Generated' : 'Generate Agent first',
                    ],
                    ['Model', modelConfig],
                    [
                      'Dialogue',
                      runtime.hasAgentDialogue ? 'Saved' : 'Not run'
                    ],
                  ],
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          chat,
          const SizedBox(height: _DesktopGrid.gutter),
          bindings
        ]);
      }
      return _EqualHeightRow(
        height: 362,
        flexes: const [6, 5],
        children: [chat, bindings],
      );
    });
  }
}

const sampleCampaign7ConfigurationStatus = <String, dynamic>{
  'schema_id': 'campaign7_configuration_system_status',
  'schema_version': '2026-06-17',
  'overall_status':
      'campaign7_configuration_system_production_grade_accepted_ui_bound',
  'final_target':
      'campaign7_configuration_system_production_grade_accepted_pushed_ci_green',
  'scope': {
    'campaign_7_started': true,
    'campaign_8_started': false,
    'campaign_9_started': false,
    'provider_runtime_reimplemented': false,
    'agent_runtime_reimplemented': false,
    'arbitrary_shell_allowed': false,
    'computer_use_runtime_enabled': false,
    'tag_or_release_allowed': false,
    'secret_plaintext_written': false,
  },
  'config_schema': {
    'schema_version': 'campaign7.config.v1',
    'ui_state': 'enabled_real',
    'sections': <String>[
      'provider_profiles',
      'agent_profiles',
      'tool_adapters',
      'skills',
      'rag',
      'workspace',
      'ui_settings',
    ],
    'source_precedence': <String>['default', 'workspace', 'user', 'env'],
    'runtime_reuse': {
      'provider_runtime': 'accepted_env_only_provider_runtime',
      'agent_runtime': 'campaign6_agent_runtime',
      'tool_runtime': 'campaign6_registered_tool_adapter_gate',
      'workbench_bridge': 'campaign5_allowlisted_workbench_bridge',
    },
  },
  'status_matrix': <Map<String, dynamic>>[
    {
      'capability': 'unified_config_schema',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'provider_profile_persistence',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'agent_profile_persistence',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'tool_adapter_config_persistence',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'skill_rag_workspace_binding_config',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'override_precedence',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'env_only_secret_injection',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'masked_ui_secret_display',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'config_validation',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'config_migration',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'config_rollback',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'config_diagnostics',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'config_import_export',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'degraded_status_mapping',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'ui_settings_binding',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
  ],
  'diagnostics': {
    'status': 'pass',
    'provider_runtime': 'available',
    'agent_runtime': 'available',
    'tool_adapter_registry': 'available',
    'rag': 'available',
    'workspace': 'available',
    'ui_settings': 'available',
  },
  'degraded_modes': <Map<String, dynamic>>[
    {
      'condition': 'missing_env_secret',
      'runtime_status': 'blocked',
      'user_message': 'Prompt env/secret-store setup; never echo plaintext.',
    },
    {
      'condition': 'rollback_restore',
      'runtime_status': 'degraded',
      'user_message': 'Restore last valid snapshot and preserve audit log.',
    },
    {
      'condition': 'tool_adapter_disabled',
      'runtime_status': 'disabled_boundary',
      'user_message': 'Do not execute disabled or unregistered adapters.',
    },
  ],
  'security_boundaries': {
    'no_plaintext_secret': true,
    'secret_env_names_only': true,
    'ui_secret_masked': true,
    'no_arbitrary_shell': true,
    'computer_use_disabled': true,
    'no_provider_runtime_rewrite': true,
    'no_agent_runtime_rewrite': true,
  },
  'ui_settings': {
    'ui_state': 'enabled_real',
    'masked_secret_display': 'sk-************',
    'profile_lifecycle_status': 'pass',
    'validation_status': 'pass',
    'migration_status': 'pass',
    'rollback_status': 'pass',
    'diagnostics_status': 'pass',
    'import_export_status': 'pass',
  },
};

const sampleCampaign9DesktopDeliveryStatus = <String, dynamic>{
  'schema_id': 'campaign9_desktop_delivery_status',
  'schema_version': '2026-06-17',
  'overall_status':
      'v4.3.0-rc10_product_flow_truth_ui_closure_real_exe_verified_pending_owner_retest',
  'final_target_status':
      'v4.3.0-rc10_product_flow_truth_ui_closure_real_exe_verified_pending_owner_retest',
  'release_candidate_tag': 'v4.3.0-rc10',
  'package_version_baseline': '4.3.0-rc10',
  'github_release_created': false,
  'stable_release_tag_authorized': false,
  'campaign_scope': {
    'campaign_7_restarted': false,
    'campaign_8_restarted': false,
    'campaign_9_started': true,
    'campaign_7_8_9_boundary_preserved': true,
    'computer_use_runtime_enabled': false,
    'arbitrary_shell_allowed': false,
    'github_release_created': false,
    'tauri_accepted_path': false,
  },
  'delivery_path': {
    'accepted_packaging_path': 'flutter_windows_runner',
    'legacy_tauri_status':
        'legacy_optional_scaffold_not_campaign9_accepted_path',
    'production_build_command': 'flutter build windows',
    'desktop_shell_runtime': 'Flutter Windows runner',
    'web_build_supported': true,
    'development_path_dependency_required': false,
  },
  'package': {
    'platform': 'windows',
    'build_status': 'pass',
    'release_dir': 'build/windows/x64/runner/Release',
    'exe': 'heitang_workbench.exe',
    'file_count': 49,
    'total_size_bytes': 31756336,
    'required_files_present': {
      'exe': true,
      'flutter_windows_dll': true,
      'data_dir': true,
      'flutter_assets': true,
      'icu': true,
    },
  },
  'checksum': {
    'status': 'pass',
    'manifest_path':
        'output/rc10_product_flow_truth_ui_closure/release_bundle_manifest.json',
    'exe_sha256':
        'd8e58accd56571fc08cfec3178b77ef7e1c3a58c5930c7d9d37718b1253e9d87',
  },
  'desktop_shell_smoke': {
    'status': 'pass',
    'evidence_path':
        'output/rc10_product_flow_truth_ui_closure/exe_smoke/rc10_exe_launch_smoke.json',
    'steps': <Map<String, dynamic>>[
      {'step': 'launch', 'result': 'pass'},
      {'step': 'minimize', 'result': 'pass'},
      {'step': 'restore_after_minimize', 'result': 'pass'},
      {'step': 'maximize', 'result': 'pass'},
      {'step': 'restore_after_maximize', 'result': 'pass'},
      {'step': 'resize', 'result': 'pass'},
      {'step': 'close', 'result': 'pass'},
    ],
  },
  'validation_matrix': <Map<String, dynamic>>[
    {
      'capability': 'windows_package_build',
      'status': 'pass',
      'ui_state': 'available',
      'evidence': 'campaign9_flutter_build_windows.log',
    },
    {
      'capability': 'desktop_shell_real_smoke',
      'status': 'pass',
      'ui_state': 'available',
      'evidence':
          'output/rc10_product_flow_truth_ui_closure/exe_smoke/rc10_exe_launch_smoke.json',
    },
    {
      'capability': 'full_capability_runtime_chain',
      'status': 'pass',
      'ui_state': 'available',
      'evidence':
          'kb-forge-skill/output/rc10_validation_chain/rc10_core_chain_probe.log',
    },
    {
      'capability': 'page_button_tab_audit',
      'status': 'pass',
      'ui_state': 'available',
      'evidence':
          'v4.3.0-rc10_Product_Flow_Truth_UI_Closure_Report_2026-06-18.md',
    },
    {
      'capability': 'release_bundle_manifest',
      'status': 'pass',
      'ui_state': 'available',
      'evidence':
          'output/rc10_product_flow_truth_ui_closure/release_bundle_manifest.json',
    },
    {
      'capability': 'provider_secret_handling',
      'status': 'pass',
      'ui_state': 'available',
      'evidence': 'env_only_no_secret_bundle_boundary',
    },
    {
      'capability': 'config_workspace_log_cache_paths',
      'status': 'pass',
      'ui_state': 'available',
      'evidence': 'configuration_system_reuse',
    },
    {
      'capability': 'github_release_creation',
      'status': 'not_created',
      'ui_state': 'owner_authorization_required',
      'evidence': 'owner_authorization_required',
    },
    {
      'capability': 'computer_use_runtime',
      'status': 'not_available_in_product_flow',
      'ui_state': 'not_available_in_product_flow',
      'evidence': 'high_risk_runtime_not_opened',
    },
  ],
  'path_rules': {
    'config_path':
        'Configuration precedence persists default/workspace/user/env values.',
    'workspace_path':
        'Workspace selection remains user-controlled and must not require a development checkout.',
    'logs_path':
        'Packaged app logs use local application log storage and never write raw credentials.',
    'cache_path':
        'Packaged app cache is local, clearable, and non-authoritative.',
    'secret_path':
        'Provider and tool credentials remain env/secret-store only and are never bundled.',
  },
  'degraded_modes': <Map<String, dynamic>>[
    {
      'condition': 'missing_provider_env',
      'runtime_status': 'degraded',
      'user_message':
          'Provider-backed actions stay disabled until env/secret-store setup is repaired.',
    },
    {
      'condition': 'workspace_path_unavailable',
      'runtime_status': 'blocked',
      'user_message':
          'Prompt for a valid workspace path before starting local workflows.',
    },
    {
      'condition': 'bundle_file_missing',
      'runtime_status': 'blocked',
      'user_message':
          'Do not mark the package accepted until required runtime files are restored.',
    },
    {
      'condition': 'desktop_shell_smoke_failure',
      'runtime_status': 'blocked',
      'user_message':
          'Stop the candidate and repair the desktop shell behavior before tagging.',
    },
    {
      'condition': 'github_release_requested',
      'runtime_status': 'blocked_pending_owner',
      'user_message':
          'GitHub Release creation requires separate Owner authorization.',
    },
  ],
  'rollback_matrix': <Map<String, dynamic>>[
    {
      'area': 'package_artifact',
      'rollback':
          'Discard the candidate bundle and rebuild from the accepted commit.',
    },
    {
      'area': 'config_profile',
      'rollback':
          'Use configuration rollback snapshots and preserve diagnostics.',
    },
    {
      'area': 'workspace_state',
      'rollback':
          'Do not mutate workspace data during package smoke; restore from user backup if a later workflow mutates data.',
    },
    {
      'area': 'tag_policy',
      'rollback':
          'Do not move or force-push tags; create a new authorized candidate only after Owner review.',
    },
  ],
  'security_boundaries': {
    'no_plaintext_secret_bundled': true,
    'no_secret_in_ui_log_report_fixture': true,
    'env_only_provider_secret_reuse': true,
    'no_arbitrary_shell': true,
    'computer_use_disabled': true,
    'no_github_release_created': true,
    'no_stable_release_without_owner': true,
    'no_campaign_7_8_9_scope_violation': true,
    'legacy_tauri_not_accepted_path': true,
  },
};
