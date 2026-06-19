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
        ? ['工作区', '创建 Agent', '单 Agent 对话', 'A2A 协作', '运行审计']
        : [
            'Workspace',
            'Create Agent',
            'Single-Agent Chat',
            'A2A Collaboration',
            'Run Audit'
          ];
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.smart_toy_outlined,
        title: _zh ? 'Agent 工作台' : 'Agent Workbench',
        description: _zh
            ? '创建 Agent、绑定知识库与 Skill，并在本页启动多 Agent 联合讨论。'
            : 'Create Agents, bind Knowledge Base and Skill, and run multi-agent discussion here.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _MetricStrip(
        items: [
          _MetricDatum(
              label: _zh ? 'Agent 模板' : 'Agent templates',
              value: '5',
              detail: _zh
                  ? '问答 / 总结 / 质检 / 运营 / 产品'
                  : 'QA / summary / QA / ops / product',
              icon: Icons.psychology_alt_outlined),
          _MetricDatum(
              label: _zh ? 'Agent 产物' : 'Agent package',
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
          tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
      const SizedBox(height: _DesktopGrid.gutter),
      switch (selectedTab) {
        1 => _AgentCreationProductView(
            zh: _zh,
            workspace: workspace,
            onAgentCreated: () => onTabSelected(2),
          ),
        2 => _AgentMinimalChatView(zh: _zh),
        3 => _AgentDiscussionProductView(zh: _zh),
        4 => _AgentRunHistoryView(zh: _zh),
        _ => _AgentWorkspaceProductView(zh: _zh, workspace: workspace),
      },
    ]);
  }
}

List<Map<String, dynamic>> _campaign6List(Object? value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

Map<String, dynamic> _campaign6Map(Object? value) {
  if (value is! Map) {
    return const <String, dynamic>{};
  }
  return Map<String, dynamic>.from(value);
}

String _campaignText(Object? value) {
  return value?.toString() ?? '-';
}

String _productRecordText(Object? value) {
  final text = _campaignText(value);
  if (text == '-') return text;
  final normalized = text.replaceAll('\\', '/');
  if (normalized.contains('/')) {
    return normalized.split('/').where((part) => part.isNotEmpty).last;
  }
  return text;
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
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final setup = _ProductPanel(
        keyName: 'agent-workspace-setup',
        icon: Icons.account_tree_outlined,
        title: zh ? 'Agent 与会话列表' : 'Agent and Session Lists',
        subtitle: runtime.hasAgent
            ? _displayNameForPath(runtime.agentPath)
            : '$workspace/workbench_runs/agent/workspaces',
        children: [
          _ProductTable(
            columns: zh
                ? ['列表', '用途', '当前状态']
                : ['List', 'Purpose', 'Current state'],
            rows: zh
                ? [
                    [
                      'Agent 列表',
                      '简单 / 复杂 Agent 统一管理',
                      runtime.hasAgent ? 'K1 + S1' : '生成 Agent 后写入'
                    ],
                    [
                      '会话列表',
                      '单 Agent 对话历史',
                      runtime.hasAgentDialogue ? '已有会话' : '创建后立即对话'
                    ],
                    [
                      '多 Agent 工作区',
                      '总工作区与子工作区隔离',
                      runtime.hasAgent ? '各自 KB / Skill' : '等待 Agent'
                    ],
                  ]
                : [
                    [
                      'Agent list',
                      'Simple / advanced Agents managed together',
                      runtime.hasAgent ? 'K1 + S1' : 'Written after generate'
                    ],
                    [
                      'Session list',
                      'Single-Agent dialogue history',
                      runtime.hasAgentDialogue
                          ? 'Has session'
                          : 'Chat after creation'
                    ],
                    [
                      'Multi-Agent workspace',
                      'Parent and child workspaces isolated',
                      runtime.hasAgent ? 'Own KB / Skill' : 'Waiting Agent'
                    ],
                  ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _PrimaryProductAction(
            label: zh ? '创建 Agent 工作区并进入对话' : 'Create Agent workspace and chat',
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
        title: zh ? '访问边界' : 'Access Boundary',
        children: [
          _ProductTable(
            columns: zh ? ['规则', '状态'] : ['Rule', 'Status'],
            rows: zh
                ? [
                    ['单 Agent 只访问自己的工作区', runtime.hasAgent ? '已写入' : '等待生成'],
                    ['子 Agent 不覆盖彼此配置', runtime.hasAgent ? '已隔离' : '等待生成'],
                    ['不开放高风险系统能力', '保持关闭'],
                    ['不展示明文 secret', '保持掩码'],
                  ]
                : [
                    [
                      'Single Agent uses own workspace only',
                      runtime.hasAgent ? 'Written' : 'Waiting'
                    ],
                    [
                      'Child Agents do not overwrite each other',
                      runtime.hasAgent ? 'Isolated' : 'Waiting'
                    ],
                    ['High-risk system capabilities', 'Kept closed'],
                    ['Plaintext secrets', 'Masked'],
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

List<String> _campaignStringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value.map((item) => item.toString()).toList(growable: false);
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
      TextEditingController(text: '知识问答 Agent');
  final TextEditingController _modelConfigController =
      TextEditingController(text: 'local-default-or-configured-provider');
  final TextEditingController _roleGoalController =
      TextEditingController(text: '只基于绑定知识库和 Skill 回答，输出必须带引用。');

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
        'reading_summary' => zh ? '阅读总结 Agent' : 'Reading Summary Agent',
        'quality_qa' => zh ? '质检 Agent' : 'Quality Agent',
        'operation_conversion' => zh ? '运营转化 Agent' : 'Ops Conversion Agent',
        'product_analysis' => zh ? '产品分析 Agent' : 'Product Analysis Agent',
        _ => zh ? '知识问答 Agent' : 'Knowledge QA Agent',
      };

  Future<void> _confirmAndDeleteAgent(
      BuildContext context, Rc6RuntimeController? rc6) async {
    if (rc6 == null || rc6.state.running || !rc6.state.hasAgent) return;
    final confirmed = await _confirmDestructiveAction(
      context,
      title: zh ? '删除 Agent 产物？' : 'Delete Agent artifacts?',
      body: zh
          ? '这会删除当前工作区里的 Agent、最小对话和联合讨论产物；知识库和 Skill 保留。'
          : 'This deletes Agent, minimal chat, and team discussion artifacts in this workspace; KB and Skill are kept.',
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
        title: zh ? '创建 Agent' : 'Create Agent',
        subtitle: runtime.hasAgent
            ? _displayNameForPath(runtime.agentPath)
            : '$workspace/workbench_runs/agent',
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
              labelText: zh ? 'Agent 名称' : 'Agent name',
              helperText: zh
                  ? '写入 Agent 配置、工作区和运行审计。'
                  : 'Written to Agent config, workspace, and run audit.',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? 'Agent 类型' : 'Agent type',
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
                  ? '引用设置页已保存的 Provider/模型配置；密钥仍只掩码显示。'
                  : 'References saved Provider/model settings; secrets stay masked.',
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
                  ? '用于生成 Agent profile、对话上下文和审计记录。'
                  : 'Used in Agent profile, chat context, and audit records.',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _ProductTable(
            columns: zh
                ? ['Agent', '构造模式', '知识库', 'Skill', '创建后动作']
                : ['Agent', 'Build mode', 'KB', 'Skill', 'After creation'],
            rows: zh
                ? [
                    [
                      '知识问答 Agent',
                      '简单 Agent',
                      runtime.hasKnowledgeBase ? '已绑定' : '请先构建知识库',
                      runtime.hasSkill ? '已绑定' : '请先生成 Skill',
                      '立即进入单 Agent 对话'
                    ],
                    [
                      '阅读总结 Agent',
                      '简单 Agent',
                      runtime.hasKnowledgeBase ? '已绑定' : '请先构建知识库',
                      runtime.hasSkill ? '已绑定' : '请先生成 Skill',
                      '立即进入单 Agent 对话'
                    ],
                    [
                      '质检 / 运营 / 产品分析 Agent',
                      '复杂 Agent',
                      runtime.hasKnowledgeBase ? '已绑定' : '请先构建知识库',
                      runtime.hasSkill ? '已绑定' : '请先生成 Skill',
                      '写入记忆 / Tool / 审计配置'
                    ],
                  ]
                : [
                    [
                      'Knowledge QA Agent',
                      'Simple Agent',
                      runtime.hasKnowledgeBase ? 'Bound' : 'Build KB first',
                      runtime.hasSkill ? 'Bound' : 'Generate Skill first',
                      'Enter single-Agent chat'
                    ],
                    [
                      'Reading Summary Agent',
                      'Simple Agent',
                      runtime.hasKnowledgeBase ? 'Bound' : 'Build KB first',
                      runtime.hasSkill ? 'Bound' : 'Generate Skill first',
                      'Enter single-Agent chat'
                    ],
                    [
                      'QA / Ops / Product Analysis Agents',
                      'Advanced Agent',
                      runtime.hasKnowledgeBase ? 'Bound' : 'Build KB first',
                      runtime.hasSkill ? 'Bound' : 'Generate Skill first',
                      'Write memory / tool / audit config'
                    ],
                  ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _PrimaryProductAction(
            label: zh ? '创建 Agent 并进入对话' : 'Create Agent and open chat',
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
          _EqualActionRow(children: [
            _DisplayAction(
              label: runtime.hasAgent
                  ? (zh ? '复制 Agent 路径' : 'Copy Agent path')
                  : (zh ? '等待真实 Agent 产物' : 'Waiting for real Agent'),
              icon: Icons.copy_outlined,
              onPressed: runtime.hasAgent
                  ? () => _copyArtifactPath(
                        context,
                        path: runtime.agentPath,
                        successMessage:
                            zh ? 'Agent 产物路径已复制' : 'Agent artifact path copied',
                      )
                  : null,
            ),
            _DisplayAction(
              label: runtime.hasAgent
                  ? (zh ? '查看 Agent 配置' : 'View Agent config')
                  : (zh ? '等待可预览 Agent' : 'Waiting for previewable Agent'),
              icon: Icons.article_outlined,
              onPressed: runtime.hasAgent
                  ? () => _showWorkspaceArtifactPreview(
                        context,
                        rc6: rc6,
                        title: zh ? 'Agent 配置预览' : 'Agent config preview',
                        path:
                            '${runtime.agentPath}/agent_generation_manifest.json',
                        unavailableMessage: zh
                            ? '尚未生成可预览 Agent 配置。'
                            : 'No previewable Agent config has been generated.',
                        closeLabel: zh ? '关闭' : 'Close',
                      )
                  : null,
            ),
            _DisplayAction(
              label: runtime.hasAgent
                  ? (zh ? '删除 Agent 产物' : 'Delete Agent artifacts')
                  : (zh ? '等待真实 Agent 产物' : 'Waiting for real Agent'),
              icon: runtime.hasAgent
                  ? Icons.delete_outline
                  : Icons.smart_toy_outlined,
              onPressed: runtime.hasAgent
                  ? () => _confirmAndDeleteAgent(context, rc6)
                  : null,
            ),
          ]),
        ],
      );
      final detail = _ProductPanel(
        keyName: 'agent-binding-detail',
        icon: Icons.link_outlined,
        title: simpleMode
            ? (zh ? '简单 Agent 对话配置' : 'Simple Agent Chat Config')
            : (zh ? '复杂 Agent 运行配置' : 'Advanced Agent Runtime Config'),
        children: [
          _FieldRow(
            label: zh ? '知识库' : 'Knowledge Base',
            value: runtime.hasKnowledgeBase
                ? _displayNameForPath(runtime.kbManifestPath)
                : (zh ? '等待知识库' : 'Waiting KB'),
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: 'Skill',
            value: runtime.hasSkill
                ? _displayNameForPath(runtime.skillPath)
                : (zh ? '等待 Skill' : 'Waiting Skill'),
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '创建后动作' : 'After creation',
            value: zh
                ? '创建后立即进入单 Agent 对话'
                : 'Open single-Agent chat immediately after creation',
          ),
          if (simpleMode) ...[
            const SizedBox(height: 8),
            _FieldRow(
              label: zh ? '对话历史' : 'Dialogue history',
              value: runtime.hasAgentDialogue
                  ? (zh ? '已有会话记录' : 'Conversation saved')
                  : (zh ? '首次对话后写入' : 'Written after first chat'),
            ),
            const SizedBox(height: 8),
            _FieldRow(
              label: zh ? '运行审计' : 'Run audit',
              value: zh
                  ? '记录模型、知识库、Skill、引用和错误状态'
                  : 'Records model, KB, Skill, citations, and errors',
            ),
          ] else ...[
            const SizedBox(height: 8),
            _FieldRow(
              label: zh ? 'Redis 短期记忆' : 'Redis short-term memory',
              value: zh
                  ? '使用运行设置中的 Redis 配置；未通过连接测试时回退本地会话'
                  : 'Uses Run Settings Redis; falls back to local session if untested',
            ),
            const SizedBox(height: 8),
            _FieldRow(
              label: zh ? '向量长期记忆' : 'Vector long-term memory',
              value: zh
                  ? '绑定运行设置中的 Qdrant / 本地索引配置'
                  : 'Binds Qdrant / local index from Run Settings',
            ),
            const SizedBox(height: 8),
            _FieldRow(
              label: zh ? 'Tool 配置' : 'Tool config',
              value: zh
                  ? '仅允许白名单业务工具，不开放任意系统命令'
                  : 'Allowlisted product tools only; arbitrary system commands are not exposed',
            ),
            const SizedBox(height: 8),
            _FieldRow(
              label: zh ? '输出格式' : 'Output',
              value: zh
                  ? 'Markdown / JSON / report / chat'
                  : 'Markdown / JSON / report / chat',
            ),
            const SizedBox(height: 8),
            _FieldRow(
              label: zh ? '审计策略' : 'Audit policy',
              value: zh
                  ? '创建、对话、A2A、权限审计均写入运行记录'
                  : 'Creation, chat, A2A, and permission checks are written to run history',
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
        'reading_summary_agent' => zh ? '阅读总结 Agent' : 'Reading Summary',
        'knowledge_qa_agent' => zh ? '知识问答 Agent' : 'Knowledge QA',
        'quality_qa_agent' => zh ? '质检 Agent' : 'Quality',
        'operation_conversion_agent' => zh ? '运营转化 Agent' : 'Ops Conversion',
        'product_analysis_agent' => zh ? '产品分析 Agent' : 'Product Analysis',
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
      title: zh ? 'A2A 协作' : 'A2A Collaboration',
      subtitle: runtime.hasMultiAgentDiscussion
          ? _displayNameForPath(runtime.multiAgentDiscussionPath)
          : (zh ? '等待 Agent 产物' : 'Waiting for Agent package'),
      children: [
        _ProductTable(
          columns: zh
              ? ['工作区 / Agent', '输入', '输出']
              : ['Workspace / Agent', 'Input', 'Output'],
          rows: zh
              ? [
                  ['W_M 总工作区', '协作议题', '共识 / 冲突 / 行动建议'],
                  ['W_B 运营 Agent', 'K2 + S2', '运营转化观点'],
                  ['W_C 产品分析 Agent', 'K3 + 产品分析 Skill', '产品判断'],
                  ['质检 Agent', '解析与 Chunk', '风险与复核点'],
                ]
              : [
                  [
                    'W_M parent workspace',
                    'Collaboration topic',
                    'Consensus / conflict / actions'
                  ],
                  ['W_B Ops Agent', 'K2 + S2', 'Ops conversion view'],
                  [
                    'W_C Product Agent',
                    'K3 + product Skill',
                    'Product judgement'
                  ],
                  ['Quality Agent', 'Parse and chunks', 'Review risks'],
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
                ? '写入 A2A 会话、讨论纪要和审计清单。'
                : 'Written to A2A session, discussion notes, and audit manifests.',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          minLines: 2,
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        _SectionCaption(zh ? '选择参与 Agent' : 'Select participant Agents'),
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
          label: zh ? 'A2A Session' : 'A2A Session',
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
          columns: zh ? ['追踪项', '真实值'] : ['Trace item', 'Real value'],
          rows: zh
              ? [
                  ['参与 Agent', participants],
                  [
                    '证据引用',
                    runtime.hasMultiAgentDiscussion
                        ? '${runtime.a2aEvidenceCount} 条'
                        : '启动后统计'
                  ],
                  ['会话状态', a2aStatus],
                  ['运行前置', runtime.hasSkill ? 'Skill 已生成' : '请先生成 Skill'],
                  [
                    '会话审计',
                    runtime.hasA2aSessionManifest
                        ? _displayNameForPath(runtime.a2aSessionManifestPath)
                        : '启动后写入'
                  ],
                  [
                    '讨论审计',
                    runtime.hasMultiAgentDiscussionManifest
                        ? _displayNameForPath(
                            runtime.multiAgentDiscussionManifestPath)
                        : '启动后写入'
                  ],
                ]
              : [
                  ['Participant Agents', participants],
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
                    'Session audit',
                    runtime.hasA2aSessionManifest
                        ? _displayNameForPath(runtime.a2aSessionManifestPath)
                        : 'Written after start'
                  ],
                  [
                    'Discussion audit',
                    runtime.hasMultiAgentDiscussionManifest
                        ? _displayNameForPath(
                            runtime.multiAgentDiscussionManifestPath)
                        : 'Written after start'
                  ],
                ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _PrimaryProductAction(
          label: zh ? '启动联合讨论' : 'Start discussion',
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
              ? (zh ? '复制讨论纪要路径' : 'Copy discussion notes path')
              : (zh ? '等待讨论纪要' : 'Waiting for discussion notes'),
          icon: Icons.copy_outlined,
          onPressed: runtime.hasMultiAgentDiscussion
              ? () => _copyArtifactPath(
                    context,
                    path: runtime.multiAgentDiscussionPath,
                    successMessage:
                        zh ? '讨论纪要路径已复制' : 'Discussion notes path copied',
                  )
              : null,
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
        const SizedBox(height: _DesktopGrid.gutter),
        _EqualActionRow(children: [
          _DisplayAction(
            label: runtime.hasA2aSessionManifest
                ? (zh ? '查看会话审计' : 'View session audit')
                : (zh ? '等待会话审计' : 'Waiting for session audit'),
            icon: Icons.fact_check_outlined,
            onPressed: runtime.hasA2aSessionManifest
                ? () => _showWorkspaceArtifactPreview(
                      context,
                      rc6: rc6,
                      title: zh ? 'A2A 会话审计' : 'A2A session audit',
                      path: runtime.a2aSessionManifestPath,
                      unavailableMessage: zh
                          ? '尚未生成 A2A 会话审计。'
                          : 'No A2A session audit generated.',
                      closeLabel: zh ? '关闭' : 'Close',
                    )
                : null,
          ),
          _DisplayAction(
            label: runtime.hasMultiAgentDiscussionManifest
                ? (zh ? '查看讨论审计' : 'View discussion audit')
                : (zh ? '等待讨论审计' : 'Waiting for discussion audit'),
            icon: Icons.article_outlined,
            onPressed: runtime.hasMultiAgentDiscussionManifest
                ? () => _showWorkspaceArtifactPreview(
                      context,
                      rc6: rc6,
                      title: zh ? '多 Agent 讨论审计' : 'Discussion audit',
                      path: runtime.multiAgentDiscussionManifestPath,
                      unavailableMessage: zh
                          ? '尚未生成多 Agent 讨论审计。'
                          : 'No multi-agent discussion audit generated.',
                      closeLabel: zh ? '关闭' : 'Close',
                    )
                : null,
          ),
        ]),
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
      title: zh ? '清空单 Agent 对话？' : 'Clear single-Agent dialogue?',
      body: zh
          ? '这会删除当前 Agent 的对话内容、会话历史和对话导出；Agent 配置、Skill、知识库和 A2A 产物不会被删除。'
          : 'This deletes the current Agent dialogue, chat history, and dialogue export; Agent config, Skill, KB, and A2A artifacts are kept.',
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
      final outputFormat = runtime.agentDialogueOutputFormat.isEmpty
          ? (zh ? '运行后读取' : 'Read after run')
          : runtime.agentDialogueOutputFormat.toUpperCase();
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
        title: zh ? '最小对话入口' : 'Minimal Chat Entry',
        gap: true,
        children: [
          TextField(
            controller: _promptController,
            enabled: !runtime.running,
            decoration: InputDecoration(
              labelText: zh ? '对话问题' : 'Prompt',
              helperText: zh
                  ? '基于已生成 Agent、知识库和 Skill 生成本地可追踪对话记录；创建后可立即运行。'
                  : 'Creates a local traceable dialogue from the generated Agent, KB, and Skill; runnable immediately after creation.',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _PrimaryProductAction(
            label: zh ? '运行最小对话' : 'Run minimal chat',
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
            label: zh ? '对话产物' : 'Dialogue artifact',
            value: runtime.hasAgentDialogue
                ? _displayNameForPath(runtime.agentDialoguePath)
                : (zh ? '尚未生成' : 'Not generated'),
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '会话历史' : 'Chat history',
            value: runtime.hasAgentDialogueHistory
                ? (zh
                    ? '${runtime.agentDialogueTurnCount} 轮 · ${_displayNameForPath(runtime.agentDialogueHistoryPath)}'
                    : '${runtime.agentDialogueTurnCount} turns · ${_displayNameForPath(runtime.agentDialogueHistoryPath)}')
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
          _FieldRow(
            label: zh ? '审计清单' : 'Audit manifest',
            value: runtime.hasAgentDialogueManifest
                ? _displayNameForPath(runtime.agentDialogueManifestPath)
                : (zh ? '运行后生成' : 'Generated after running chat'),
          ),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh ? ['追踪项', '真实值'] : ['Trace item', 'Real value'],
            rows: zh
                ? [
                    ['模型配置', modelConfig],
                    ['绑定知识库', kbIds],
                    ['绑定 Skill', skillIds],
                    ['输出格式', outputFormat],
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
                    ['Model config', modelConfig],
                    ['Bound KB', kbIds],
                    ['Bound Skill', skillIds],
                    ['Output format', outputFormat],
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
                  ? (zh ? '复制对话产物路径' : 'Copy dialogue artifact path')
                  : (zh ? '等待对话产物' : 'Waiting for dialogue artifact'),
              icon: Icons.copy_outlined,
              onPressed: runtime.hasAgentDialogue
                  ? () => _copyArtifactPath(
                        context,
                        path: runtime.agentDialoguePath,
                        successMessage:
                            zh ? '对话产物路径已复制' : 'Dialogue artifact path copied',
                      )
                  : null,
            ),
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
            _DisplayAction(
              label: runtime.hasAgentDialogueHistory
                  ? (zh ? '复制会话历史路径' : 'Copy chat history path')
                  : (zh ? '等待会话历史' : 'Waiting for chat history'),
              icon: Icons.copy_outlined,
              onPressed: runtime.hasAgentDialogueHistory
                  ? () => _copyArtifactPath(
                        context,
                        path: runtime.agentDialogueHistoryPath,
                        successMessage:
                            zh ? '会话历史路径已复制' : 'Chat history path copied',
                      )
                  : null,
            ),
            _DisplayAction(
              label: runtime.hasAgentDialogueHistory
                  ? (zh ? '查看会话历史' : 'View chat history')
                  : (zh ? '等待可预览历史' : 'Waiting for previewable history'),
              icon: Icons.article_outlined,
              onPressed: runtime.hasAgentDialogueHistory
                  ? () => _showWorkspaceArtifactPreview(
                        context,
                        rc6: rc6,
                        title: zh ? '会话历史预览' : 'Chat history preview',
                        path: runtime.agentDialogueHistoryPath,
                        unavailableMessage:
                            zh ? '尚未生成可预览会话历史。' : 'No chat history generated.',
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
            _DisplayAction(
              label: runtime.hasAgentDialogueExport
                  ? (zh ? '查看导出记录' : 'View export')
                  : (zh ? '等待导出记录' : 'Waiting for export'),
              icon: Icons.article_outlined,
              onPressed: runtime.hasAgentDialogueExport
                  ? () => _showWorkspaceArtifactPreview(
                        context,
                        rc6: rc6,
                        title: zh ? '导出对话预览' : 'Dialogue export preview',
                        path: runtime.agentDialogueExportPath,
                        unavailableMessage:
                            zh ? '尚未生成可预览导出。' : 'No dialogue export generated.',
                        closeLabel: zh ? '关闭' : 'Close',
                      )
                  : null,
            ),
            _DisplayAction(
              label: runtime.hasAgentDialogueHistory
                  ? (zh ? '清空对话历史' : 'Clear dialogue history')
                  : (zh ? '等待可清空历史' : 'Waiting for history'),
              icon: Icons.delete_sweep_outlined,
              onPressed: runtime.hasAgentDialogueHistory &&
                      rc6 != null &&
                      !runtime.running
                  ? () => _confirmAndClearDialogue(context, rc6)
                  : null,
            ),
          ]),
        ],
      );
      final bindings = _ProductPanel(
        keyName: 'agent-chat-bindings',
        icon: Icons.link_outlined,
        title: zh ? '对话输入来源' : 'Chat Inputs',
        children: [
          _ProductTable(
            columns: zh ? ['输入', '状态', '说明'] : ['Input', 'Status', 'Note'],
            rows: zh
                ? [
                    [
                      '知识库',
                      runtime.hasKnowledgeBase ? '已绑定' : '请先构建知识库',
                      runtime.hasKnowledgeBase
                          ? _displayNameForPath(runtime.kbManifestPath)
                          : '知识库页构建'
                    ],
                    [
                      'Skill',
                      runtime.hasSkill ? '已绑定' : '请先生成 Skill',
                      runtime.hasSkill
                          ? _displayNameForPath(runtime.skillPath)
                          : 'Skill 工厂生成'
                    ],
                    [
                      'Agent',
                      runtime.hasAgent ? '已生成' : '请先生成 Agent',
                      runtime.hasAgent
                          ? _displayNameForPath(runtime.agentPath)
                          : 'Agent 工作台创建'
                    ],
                    ['模型', modelConfig, '密钥仅从环境/设置读取并掩码显示'],
                    [
                      '对话审计',
                      runtime.hasAgentDialogueManifest ? '已写入' : '运行后写入',
                      runtime.hasAgentDialogueManifest
                          ? _displayNameForPath(
                              runtime.agentDialogueManifestPath)
                          : 'agent_dialogue_manifest.json'
                    ],
                  ]
                : [
                    [
                      'Knowledge Base',
                      runtime.hasKnowledgeBase ? 'Bound' : 'Build KB first',
                      runtime.hasKnowledgeBase
                          ? _displayNameForPath(runtime.kbManifestPath)
                          : 'Build on Knowledge Base page'
                    ],
                    [
                      'Skill',
                      runtime.hasSkill ? 'Bound' : 'Generate Skill first',
                      runtime.hasSkill
                          ? _displayNameForPath(runtime.skillPath)
                          : 'Generate in Skill Factory'
                    ],
                    [
                      'Agent',
                      runtime.hasAgent ? 'Generated' : 'Generate Agent first',
                      runtime.hasAgent
                          ? _displayNameForPath(runtime.agentPath)
                          : 'Create in Agent Workbench'
                    ],
                    [
                      'Model',
                      modelConfig,
                      'Secrets are read from environment/settings and masked'
                    ],
                    [
                      'Dialogue audit',
                      runtime.hasAgentDialogueManifest
                          ? 'Written'
                          : 'Written after run',
                      runtime.hasAgentDialogueManifest
                          ? _displayNameForPath(
                              runtime.agentDialogueManifestPath)
                          : 'agent_dialogue_manifest.json'
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

class _AgentRunHistoryView extends StatelessWidget {
  const _AgentRunHistoryView({required this.zh});

  final bool zh;

  @override
  Widget build(BuildContext context) {
    final runtime =
        _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
    return _ProductPanel(
      keyName: 'agent-run-history',
      icon: Icons.history_outlined,
      title: zh ? '运行记录' : 'Run History',
      children: [
        _ProductTable(
          columns: zh ? ['记录', '状态', '产物'] : ['Record', 'Status', 'Artifact'],
          rows: zh
              ? [
                  [
                    'Agent 创建',
                    runtime.hasAgent ? '已完成' : '未运行',
                    runtime.hasAgent
                        ? _displayNameForPath(runtime.agentPath)
                        : '无产物'
                  ],
                  [
                    '最小对话',
                    runtime.hasAgentDialogue ? '已完成' : '未运行',
                    runtime.hasAgentDialogue
                        ? '${runtime.agentDialogueTurnCount} 轮 · ${_displayNameForPath(runtime.agentDialoguePath)}'
                        : '无产物'
                  ],
                  [
                    '联合讨论',
                    runtime.hasMultiAgentDiscussion ? '已完成' : '未运行',
                    runtime.hasMultiAgentDiscussion
                        ? _displayNameForPath(runtime.multiAgentDiscussionPath)
                        : '无产物'
                  ],
                  [
                    '多 Agent 总工作区',
                    runtime.hasPrdP0Evidence ? '已完成' : '未运行',
                    runtime.hasPrdP0Evidence
                        ? _displayNameForPath(runtime.prdP0EvidencePath)
                        : '无产物'
                  ],
                  [
                    'Agent 工作区审计',
                    runtime.hasAgent ? '已写入' : '未运行',
                    runtime.hasAgent ? 'agent_generation_manifest.json' : '无产物'
                  ],
                ]
              : [
                  [
                    'Agent creation',
                    runtime.hasAgent ? 'Done' : 'Not run',
                    runtime.hasAgent
                        ? _displayNameForPath(runtime.agentPath)
                        : 'No artifact'
                  ],
                  [
                    'Minimal chat',
                    runtime.hasAgentDialogue ? 'Done' : 'Not run',
                    runtime.hasAgentDialogue
                        ? '${runtime.agentDialogueTurnCount} turns · ${_displayNameForPath(runtime.agentDialoguePath)}'
                        : 'No artifact'
                  ],
                  [
                    'Team discussion',
                    runtime.hasMultiAgentDiscussion ? 'Done' : 'Not run',
                    runtime.hasMultiAgentDiscussion
                        ? _displayNameForPath(runtime.multiAgentDiscussionPath)
                        : 'No artifact'
                  ],
                  [
                    'Multi-Agent parent workspace',
                    runtime.hasPrdP0Evidence ? 'Done' : 'Not run',
                    runtime.hasPrdP0Evidence
                        ? _displayNameForPath(runtime.prdP0EvidencePath)
                        : 'No artifact'
                  ],
                  [
                    'Agent workspace audit',
                    runtime.hasAgent ? 'Written' : 'Not run',
                    runtime.hasAgent
                        ? 'agent_generation_manifest.json'
                        : 'No artifact'
                  ],
                ],
        ),
      ],
    );
  }
}

// ignore: unused_element
class _Campaign6RuntimeOverviewView extends StatelessWidget {
  const _Campaign6RuntimeOverviewView({
    required this.zh,
    required this.phases,
    required this.security,
  });

  final bool zh;
  final List<Map<String, dynamic>> phases;
  final Map<String, dynamic> security;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final phasePanel = _ProductPanel(
        keyName: 'campaign6-runtime-overview',
        icon: Icons.route_outlined,
        title: zh ? 'Campaign 6 执行总览' : 'Campaign 6 Execution Overview',
        subtitle: zh
            ? '6A -> 6B -> Tool Adapter Configuration Gate'
            : '6A -> 6B -> Tool Adapter Configuration Gate',
        children: [
          _ProductTable(
            columns: zh
                ? ['阶段', 'UI 状态', '运行状态', '证据']
                : ['Phase', 'UI state', 'Runtime', 'Evidence'],
            rows: phases
                .map((phase) => [
                      phase['phase_id']?.toString() ?? '-',
                      phase['ui_state']?.toString() ?? '-',
                      phase['runtime_status']?.toString() ?? '-',
                      phase['evidence_path']?.toString() ?? '-',
                    ])
                .toList(growable: false),
          ),
        ],
      );
      final securityPanel = _ProductPanel(
        keyName: 'campaign6-security-boundaries',
        icon: Icons.security_outlined,
        title: zh ? '安全边界' : 'Security Boundaries',
        gap: security['no_campaign_7_8_9'] != true,
        children: [
          _ProductTable(
            columns: zh ? ['边界', '状态'] : ['Boundary', 'Status'],
            rows: [
              ['no_secret_plaintext', '${security['no_secret_plaintext']}'],
              ['no_arbitrary_shell', '${security['no_arbitrary_shell']}'],
              [
                'no_agent_self_authorized_tool',
                '${security['no_agent_self_authorized_tool']}'
              ],
              [
                'no_cross_agent_secret_or_workspace_access',
                '${security['no_cross_agent_secret_or_workspace_access']}'
              ],
              ['no_campaign_7_8_9', '${security['no_campaign_7_8_9']}'],
            ],
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          phasePanel,
          const SizedBox(height: _DesktopGrid.gutter),
          securityPanel,
        ]);
      }
      return _EqualHeightRow(
        height: 430,
        flexes: const [7, 4],
        children: [phasePanel, securityPanel],
      );
    });
  }
}

// ignore: unused_element
class _Campaign6SingleAgentStatusView extends StatelessWidget {
  const _Campaign6SingleAgentStatusView({
    required this.zh,
    required this.agents,
  });

  final bool zh;
  final List<Map<String, dynamic>> agents;

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'campaign6-single-agent-status',
      icon: Icons.psychology_alt_outlined,
      title: zh ? '6A 单 Agent Runtime' : '6A Single Agent Runtime',
      subtitle: zh
          ? '每类 Agent 绑定真实 Tool / Skill / RAG / Bridge'
          : 'Each Agent type binds real Tool / Skill / RAG / Bridge paths',
      children: [
        _ProductTable(
          columns: zh
              ? ['Agent', 'UI 状态', '运行状态', '降级 / 回滚']
              : ['Agent', 'UI state', 'Runtime', 'Degraded / rollback'],
          rows: agents.map((agent) {
            final modes = (agent['degraded_modes'] as List<dynamic>? ?? [])
                .map((item) => item.toString())
                .join(', ');
            return [
              agent['display_name']?.toString() ??
                  agent['agent_type']?.toString() ??
                  '-',
              agent['ui_state']?.toString() ?? '-',
              agent['runtime_status']?.toString() ?? '-',
              modes.isEmpty
                  ? agent['rollback_strategy']?.toString() ?? '-'
                  : '$modes | ${agent['rollback_strategy']}',
            ];
          }).toList(growable: false),
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _FieldRow(
          label: zh ? '验收规则' : 'Acceptance rule',
          value: zh
              ? '不允许 hardcoded demo、display_only 或 mock/offline 冒充 accepted'
              : 'No hardcoded demo, display_only, or mock/offline accepted as runtime',
        ),
      ],
    );
  }
}

// ignore: unused_element
class _Campaign6AdvancedRuntimeStatusView extends StatelessWidget {
  const _Campaign6AdvancedRuntimeStatusView({
    required this.zh,
    required this.capabilities,
  });

  final bool zh;
  final List<Map<String, dynamic>> capabilities;

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'campaign6-advanced-runtime-status',
      icon: Icons.hub_outlined,
      title: zh ? '6B Advanced Agent Runtime' : '6B Advanced Agent Runtime',
      subtitle: zh
          ? 'Long-term Memory、Multi-Agent、A2A、Teams 与安全回归'
          : 'Long-term Memory, Multi-Agent, A2A, Teams, and security regression',
      children: [
        _ProductTable(
          columns: zh
              ? ['能力', 'UI 状态', '运行状态', '覆盖']
              : ['Capability', 'UI state', 'Runtime', 'Coverage'],
          rows: capabilities.map((capability) {
            final coverage = (capability['coverage'] as List<dynamic>? ?? [])
                .map((item) => item.toString())
                .join(', ');
            return [
              capability['capability_id']?.toString() ?? '-',
              capability['ui_state']?.toString() ?? '-',
              capability['runtime_status']?.toString() ?? '-',
              coverage,
            ];
          }).toList(growable: false),
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _FieldRow(
          label: zh ? 'Computer Use' : 'Computer Use',
          value: 'disabled_boundary',
        ),
      ],
    );
  }
}

// ignore: unused_element
class _Campaign6ToolAdapterStatusView extends StatelessWidget {
  const _Campaign6ToolAdapterStatusView({
    required this.zh,
    required this.toolAdapter,
    required this.workspace,
  });

  final bool zh;
  final Map<String, dynamic> toolAdapter;
  final String workspace;

  @override
  Widget build(BuildContext context) {
    final fields = (toolAdapter['api_config_schema_fields'] as List<dynamic>? ??
            const <dynamic>[])
        .map((item) => item.toString())
        .toList(growable: false);
    return _ProductPanel(
      keyName: 'campaign6-tool-adapter-status',
      icon: Icons.settings_ethernet_outlined,
      title: zh
          ? 'Tool Adapter Configuration Gate'
          : 'Tool Adapter Configuration Gate',
      subtitle: '$workspace/workbench_runs/campaign6_tool_adapter',
      children: [
        _ProductTable(
          columns: zh ? ['规则', '状态'] : ['Rule', 'Status'],
          rows: [
            ['final_status', toolAdapter['final_status']?.toString() ?? '-'],
            ['ui_state', toolAdapter['ui_state']?.toString() ?? '-'],
            [
              'provider_runtime_reimplemented',
              '${toolAdapter['provider_runtime_reimplemented']}'
            ],
            [
              'unregistered_third_party_api_integrated',
              '${toolAdapter['unregistered_third_party_api_integrated']}'
            ],
            [
              'official_channel_tool_adapter_gate_required',
              '${toolAdapter['official_channel_tool_adapter_gate_required']}'
            ],
            [
              'secret_plaintext_written',
              '${toolAdapter['secret_plaintext_written']}'
            ],
            [
              'live_smoke_status',
              toolAdapter['live_smoke_status']?.toString() ?? '-'
            ],
            [
              'official_channel_live_smoke',
              toolAdapter['official_channel_live_smoke']?.toString() ?? '-'
            ],
          ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _FieldRow(
          label: zh ? 'API config schema' : 'API config schema',
          value: fields.join(', '),
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _ProductTable(
          columns: zh
              ? ['Adapter', 'UI 状态', 'Auth', 'Live smoke']
              : ['Adapter', 'UI state', 'Auth', 'Live smoke'],
          rows: _campaign6List(toolAdapter['adapters']).map((adapter) {
            return [
              adapter['adapter_id']?.toString() ?? '-',
              adapter['ui_state']?.toString() ?? '-',
              adapter['auth_type']?.toString() ?? '-',
              adapter['live_smoke_status']?.toString() ?? '-',
            ];
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class _DeveloperDiagnosticsDetails extends StatelessWidget {
  const _DeveloperDiagnosticsDetails({
    required this.localeCode,
    required this.cards,
    required this.columns,
    required this.corePanels,
    this.parserBackends,
    this.skillFactoryWorkflow,
  });

  final String localeCode;
  final List<_CardCopy> cards;
  final int columns;
  final List<Widget> corePanels;
  final ParserBackendMatrix? parserBackends;
  final Map<String, dynamic>? skillFactoryWorkflow;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExpansionTile(
      key: const Key('developer-diagnostics-details'),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      title: Text(_zh ? '高级只读记录' : 'Advanced Read-only Records',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800)),
      subtitle: Text(_zh
          ? '默认折叠；仅记录执行证据、契约字段、解析能力和本地动作请求。'
          : 'Collapsed by default; records execution evidence, contract fields, parser capabilities, and local action requests.'),
      children: [
        _AdvancedBoundarySummary(
          localeCode: localeCode,
          contractCount: cards.length,
          coreActionCount: corePanels.length,
          hasParserBackends: parserBackends != null,
          hasSkillWorkflow: skillFactoryWorkflow != null,
        ),
        const SizedBox(height: 16),
        if (skillFactoryWorkflow != null) ...[
          _AdvancedBoundarySectionHeader(
            icon: Icons.account_tree_outlined,
            title: _zh ? 'Skill 工作流证据' : 'Skill Workflow Evidence',
            body: _zh
                ? '展示工作流快照，不宣称运行时完成。'
                : 'Shows the workflow snapshot without claiming runtime completion.',
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          SkillFactoryWorkflowSurface(
            localeCode: localeCode,
            workflow: skillFactoryWorkflow,
          ),
          const SizedBox(height: 20),
        ],
        if (cards.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdvancedBoundarySectionHeader(
                icon: Icons.rule_folder_outlined,
                title: _zh ? '契约证据' : 'Contract Evidence',
                body: _zh
                    ? '保留 Core 契约、门禁、产物和报告字段，只在高级详情中展示。'
                    : 'Keeps Core contract, gate, artifact, and report fields inside advanced details.',
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: columns == 1 ? 196 : 180,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) => _WorkbenchCard(
                  title: cards[index].title,
                  body: cards[index].body,
                  localeCode: localeCode,
                ),
              ),
            ],
          ),
        if (parserBackends != null) ...[
          if (cards.isNotEmpty) const SizedBox(height: 20),
          _AdvancedBoundarySectionHeader(
            icon: Icons.storage_outlined,
            title: _zh ? '解析能力记录' : 'Parser Capability Records',
            body: _zh
                ? '展示解析后端能力边界，不启用重型默认依赖。'
                : 'Shows parser backend boundaries without enabling heavy default dependencies.',
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          ParserBackendEvidenceDashboard(
            matrix: parserBackends!,
            localeCode: localeCode,
          ),
        ],
        if (corePanels.isNotEmpty) ...[
          const SizedBox(height: 20),
          _AdvancedBoundarySectionHeader(
            icon: Icons.terminal_outlined,
            title: _zh ? '本地动作请求记录' : 'Local Action Request Records',
            body: _zh
                ? '仅记录允许列表内的本地动作请求；Web 中保持安全禁用。'
                : 'Records allowlisted local action requests only; they remain safely disabled on Web.',
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          for (var index = 0; index < corePanels.length; index++) ...[
            if (index > 0) const SizedBox(height: _DesktopGrid.gutter),
            corePanels[index],
          ],
        ],
      ],
    );
  }
}

class _AdvancedBoundarySummary extends StatelessWidget {
  const _AdvancedBoundarySummary({
    required this.localeCode,
    required this.contractCount,
    required this.coreActionCount,
    required this.hasParserBackends,
    required this.hasSkillWorkflow,
  });

  final String localeCode;
  final int contractCount;
  final int coreActionCount;
  final bool hasParserBackends;
  final bool hasSkillWorkflow;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: colors.primary),
              const SizedBox(width: _DesktopGrid.gutter),
              Expanded(
                child: Text(
                  _zh ? '边界摘要' : 'Boundary Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AdvancedBoundaryChip(
                label: _zh ? '契约字段' : 'Contract fields',
                value: '$contractCount',
              ),
              _AdvancedBoundaryChip(
                label: _zh ? '本地动作请求' : 'Local action requests',
                value: '$coreActionCount',
              ),
              _AdvancedBoundaryChip(
                label: _zh ? '解析能力' : 'Parser capability',
                value: hasParserBackends
                    ? (_zh ? '可查看' : 'available')
                    : (_zh ? '无' : 'none'),
              ),
              _AdvancedBoundaryChip(
                label: _zh ? 'Skill 工作流' : 'Skill workflow',
                value: hasSkillWorkflow
                    ? (_zh ? '可查看' : 'available')
                    : (_zh ? '无' : 'none'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdvancedBoundaryChip extends StatelessWidget {
  const _AdvancedBoundaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedBoundarySectionHeader extends StatelessWidget {
  const _AdvancedBoundarySectionHeader({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Icon(icon, size: 18, color: colors.onSurfaceVariant),
        ),
        const SizedBox(width: _DesktopGrid.gutter),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

ContractView _contractViewForId(String pageId, WorkbenchContracts contracts) {
  for (final view in contracts.navigation.views) {
    if (view.id == pageId) {
      return view;
    }
  }
  return ContractView(
      id: pageId,
      label: pageId,
      assetTypes: const [],
      corePageId: pageId,
      zhLabel: pageId);
}

List<ContractAction> _actionsForView(
    ContractView view, WorkbenchContracts contracts) {
  return contracts.actions.actions
      .where((action) => action.pageId == view.corePageId)
      .toList(growable: false);
}

List<ContractReport> _reportsForView(
    ContractView view, WorkbenchContracts contracts) {
  return contracts.reports.reports
      .where((report) => report.pageId == view.corePageId)
      .toList(growable: false);
}

List<ContractAsset> _artifactsForView(
    ContractView view, WorkbenchContracts contracts) {
  return contracts.assets.assets
      .where((asset) => asset.pageId == view.corePageId)
      .toList(growable: false);
}

bool _showsWorkflowEvidence(String pageId) {
  return const {
    'dashboard',
    'operation-gate',
    'task-job-center',
    'artifact-management',
    'error-repair-center',
    'reports-audit',
  }.contains(pageId);
}

bool _showsV2Evidence(String pageId) {
  return const {
    'dashboard',
    'operation-gate',
    'capability-matrix',
    'task-job-center',
    'artifact-management',
    'error-repair-center',
    'reports-audit',
  }.contains(pageId);
}

bool _showsExternalCapabilities(String pageId) {
  return const {
    'dashboard',
    'operation-gate',
    'capability-matrix',
    'vector-hub-provider-storage',
    'retrieval-verification',
    'reports-audit',
    'skill-factory',
    'memory-center',
  }.contains(pageId);
}

bool _showsParserBackends(String pageId) {
  return const {
    'dashboard',
    'import-parsing',
    'capability-matrix',
    'operation-gate',
    'reports-audit',
    'artifact-management',
    'error-repair-center',
  }.contains(pageId);
}

bool _showsSkillGovernance(String pageId) {
  return pageId == 'skill-factory';
}

bool _showsMethodology(String pageId) {
  return pageId == 'skill-factory';
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
