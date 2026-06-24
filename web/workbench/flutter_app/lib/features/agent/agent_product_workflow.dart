part of '../../main.dart';

class _AgentProductWorkflow extends StatefulWidget {
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

  @override
  State<_AgentProductWorkflow> createState() => _AgentProductWorkflowState();
}

class _AgentProductWorkflowState extends State<_AgentProductWorkflow> {
  final TextEditingController _promptController = TextEditingController(
    text: '请基于当前知识库总结核心要点，并列出引用来源。',
  );
  final Map<String, String> _drafts = {};

  late int _modeIndex;
  bool _agentListDrawerOpen = false;
  bool _contextDrawerOpen = false;
  String _selectedAgentId = '';
  String _appliedVerifierScenario = '';

  bool get _zh => widget.localeCode == 'zh-CN';

  @override
  void initState() {
    super.initState();
    _modeIndex = switch (widget.selectedTab) {
      0 || 3 => 2,
      2 => 1,
      _ => 0,
    };
  }

  @override
  void didUpdateWidget(covariant _AgentProductWorkflow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTab != widget.selectedTab) {
      _modeIndex = switch (widget.selectedTab) {
        0 || 3 => 2,
        2 => 1,
        _ => 0,
      };
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  List<_AgentConsoleItem> _agents(Rc6RuntimeState runtime) {
    return runtime.agentProfiles.map((profile) {
      final conversation = _conversationFor(runtime, profile.id);
      return _AgentConsoleItem(
        id: profile.id,
        name: profile.name,
        role: profile.role.isEmpty
            ? (_zh ? '处理当前工作区任务' : 'Handles workspace tasks')
            : profile.role,
        icon: Icons.smart_toy_outlined,
        status: profile.status == 'available'
            ? (_zh ? '本地可用' : 'Local ready')
            : profile.status,
        knowledgeBaseCount: profile.boundKnowledgeBaseIds.length,
        skillCount: profile.boundSkillIds.length,
        taskCount: conversation.messages
            .where((message) => message.role == 'user')
            .length,
        profile: profile,
      );
    }).toList(growable: false);
  }

  _AgentConsoleItem _emptyAgent(Rc6RuntimeState runtime) => _AgentConsoleItem(
        id: '',
        name: _zh ? '尚未创建助手' : 'No assistant yet',
        role: _zh ? '先创建一个助手，再开始对话。' : 'Create an assistant first.',
        icon: Icons.smart_toy_outlined,
        status: _zh ? '需要创建' : 'Create needed',
        knowledgeBaseCount: 0,
        skillCount: 0,
        taskCount: 0,
      );

  Rc6AgentConversation _conversationFor(
    Rc6RuntimeState runtime,
    String agentId,
  ) {
    return runtime.agentConversations.firstWhere(
      (conversation) => conversation.agentId == agentId,
      orElse: () => Rc6AgentConversation.empty(agentId),
    );
  }

  List<_AgentConsoleMessage> _threadFor(
    _AgentConsoleItem agent,
    Rc6RuntimeState runtime,
  ) {
    if (agent.id.isEmpty) {
      return [
        _AgentConsoleMessage(
          author: _zh ? '系统' : 'System',
          body: _zh
              ? '当前还没有助手。请先创建助手，保存后可以重新进入、编辑、删除，并开始本地占位对话。'
              : 'No assistant exists yet. Create one first; it can then be reopened, edited, deleted, and used for local fallback chat.',
          meta: _zh ? '空状态' : 'Empty state',
          isUser: false,
          steps: _zh
              ? const ['创建助手', '保存配置', '发送消息']
              : const ['Create assistant', 'Save config', 'Send message'],
        ),
      ];
    }
    final conversation = _conversationFor(runtime, agent.id);
    if (conversation.messages.isEmpty) {
      return [
        _AgentConsoleMessage(
          author: agent.name,
          body: _zh
              ? '助手已保存。当前没有对话历史，发送消息后会写入本地会话并在重新进入后保留。'
              : 'Assistant saved. No chat history yet; messages are persisted locally and remain after reopening.',
          meta: _zh ? '等待输入' : 'Waiting input',
          isUser: false,
          status: _zh ? '本地模式' : 'Local mode',
          citations: _zh ? const ['当前工作区'] : const ['Current workspace'],
        ),
      ];
    }
    return conversation.messages
        .map((message) => _AgentConsoleMessage(
              id: message.id,
              author: message.isUser ? (_zh ? '你' : 'You') : agent.name,
              body: _agentMessageBody(message),
              meta: message.status == 'local_fallback'
                  ? (_zh ? '当前为本地占位回复' : 'Local fallback reply')
                  : message.createdAt,
              isUser: message.isUser,
              status: _agentMessageStatus(message),
            ))
        .toList(growable: false);
  }

  String _agentMessageBody(Rc6AgentMessage message) {
    if (message.status != 'local_fallback') {
      return message.content;
    }
    final lines = message.content
        .split('\n')
        .where((line) =>
            !line.contains('FormatException') &&
            !line.contains('<!doctype') &&
            line.trim() != '^')
        .map((line) => line.startsWith('原因：')
            ? (_zh
                ? '原因：模型连接未完成或调用失败。'
                : 'Reason: the model connection is not ready or the call failed.')
            : line)
        .toList(growable: false);
    return lines.join('\n').trim();
  }

  String? _agentMessageStatus(Rc6AgentMessage message) {
    if (message.status == 'local_fallback') {
      return _zh ? '本地占位回复' : 'Local fallback';
    }
    if (message.error.isNotEmpty) {
      return _zh ? '发送失败，请检查连接配置' : 'Send failed; check connection settings';
    }
    return null;
  }

  void _selectAgent(String agentId) {
    if (agentId == _selectedAgentId) {
      setState(() => _agentListDrawerOpen = false);
      return;
    }
    _drafts[_selectedAgentId] = _promptController.text;
    final runtime =
        _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
    final agent = _agents(runtime).firstWhere(
      (agent) => agent.id == agentId,
      orElse: () => _emptyAgent(runtime),
    );
    _threadFor(agent, runtime);
    setState(() {
      _selectedAgentId = agentId;
      _agentListDrawerOpen = false;
      _promptController.text = _drafts[agentId] ?? '';
    });
  }

  void _selectMode(int index) {
    setState(() {
      _modeIndex = index;
      _contextDrawerOpen = false;
      _agentListDrawerOpen = false;
    });
    widget.onTabSelected(switch (index) {
      0 => 1,
      1 => 2,
      _ => 3,
    });
  }

  void _toggleAgentListDrawer() {
    setState(() => _agentListDrawerOpen = !_agentListDrawerOpen);
  }

  void _toggleContextDrawer() {
    setState(() => _contextDrawerOpen = !_contextDrawerOpen);
  }

  void _applyVerifierScenario(
    String scenario,
    List<_AgentConsoleItem> agents,
  ) {
    if (scenario.isEmpty || scenario == _appliedVerifierScenario) return;
    if (agents.isEmpty) return;
    _appliedVerifierScenario = scenario;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nextAgentId = switch (scenario) {
        'agent_b' => agents.length > 1 ? agents[1].id : _selectedAgentId,
        'agent_c' => agents.length > 2 ? agents[2].id : _selectedAgentId,
        _ => agents.first.id,
      };
      final nextAgent = agents.firstWhere(
        (agent) => agent.id == nextAgentId,
        orElse: () => agents.first,
      );
      final runtime =
          _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
      _threadFor(nextAgent, runtime);
      setState(() {
        _selectedAgentId = nextAgentId;
        _modeIndex = scenario == 'agent_config'
            ? 2
            : scenario == 'multi_agent'
                ? 1
                : 0;
        _agentListDrawerOpen = scenario == 'agent_list';
        _contextDrawerOpen = scenario == 'context_panel';
        _promptController.text = _drafts[_selectedAgentId] ?? '';
      });
    });
  }

  Future<void> _sendPrompt(
    Rc6RuntimeController? rc6,
    Rc6RuntimeState runtime,
    _AgentConsoleItem agent,
  ) async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || runtime.running || agent.id.isEmpty) return;
    if (rc6 == null || !runtime.hasAgentProfiles) {
      return;
    }
    await rc6.sendAgentMessage(agentId: agent.id, content: prompt);
    if (!mounted) return;
    _drafts[agent.id] = '';
    setState(() => _promptController.clear());
  }

  Future<void> _createDefaultAgent(Rc6RuntimeController? rc6) async {
    if (rc6 == null || rc6.state.running) return;
    final profile = await rc6.createAgentProfile(
      name: _zh ? '任务总控' : 'Task Lead',
      description: _zh
          ? '处理当前工作区的问答、整理和成果沉淀。'
          : 'Handles chat, organization, and output capture for this workspace.',
      role: _zh ? '处理当前工作区任务' : 'Handles workspace tasks',
      boundKnowledgeBaseIds:
          rc6.state.knowledgeBases.map((kb) => kb.id).toList(growable: false),
      boundSkillIds: rc6.state.hasSkill ? const ['primary_skill'] : const [],
    );
    if (!mounted || profile == null) return;
    setState(() {
      _selectedAgentId = profile.id;
      _modeIndex = 0;
      _agentListDrawerOpen = false;
    });
    widget.onTabSelected(1);
  }

  Future<void> _confirmAndClearDialogue(
    BuildContext context,
    Rc6RuntimeController? rc6,
  ) async {
    if (rc6 == null ||
        rc6.state.running ||
        !rc6.state.hasAgentDialogueHistory) {
      return;
    }
    final confirmed = await _confirmDestructiveAction(
      context,
      title: _zh ? '清空助手对话？' : 'Clear assistant chat?',
      body: _zh
          ? '这会删除当前助手的对话内容、会话历史和对话导出；助手配置、技能、知识库和工作小组成果不会被删除。'
          : 'This deletes the current assistant dialogue, chat history, and dialogue export; assistant config, skill, knowledge base, and discussion outputs are kept.',
    );
    if (!confirmed) return;
    await rc6.clearAgentDialogueHistory();
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final agents = _agents(runtime);
    _applyVerifierScenario(rc6?.agentConsoleVerifierScenario ?? '', agents);
    final selectedAgent = agents.firstWhere(
      (agent) => agent.id == _selectedAgentId,
      orElse: () => agents.isNotEmpty ? agents.first : _emptyAgent(runtime),
    );
    if (selectedAgent.id.isNotEmpty && selectedAgent.id != _selectedAgentId) {
      _selectedAgentId = selectedAgent.id;
    }
    final selectedThread = _threadFor(selectedAgent, runtime);
    return LayoutBuilder(builder: (context, constraints) {
      final screenHeight = MediaQuery.sizeOf(context).height;
      final compactHeight = screenHeight <= 760;
      final availableHeight = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : (screenHeight - 150).clamp(480.0, 820.0).toDouble();
      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: availableHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AgentPrimaryEntrySwitch(
                zh: _zh,
                selectedIndex: _modeIndex,
                onSelected: _selectMode,
                compact: compactHeight,
              ),
              SizedBox(height: compactHeight ? 8 : 12),
              Expanded(
                child: _AgentConsoleResetWorkbench(
                  zh: _zh,
                  workspace: widget.workspace,
                  agents: agents,
                  selectedAgent: selectedAgent,
                  thread: selectedThread,
                  runtime: runtime,
                  rc6: rc6,
                  modeIndex: _modeIndex,
                  promptController: _promptController,
                  onAgentSelected: _selectAgent,
                  onModeSelected: _selectMode,
                  agentListDrawerOpen: _agentListDrawerOpen,
                  contextDrawerOpen: _contextDrawerOpen,
                  onToggleAgentList: _toggleAgentListDrawer,
                  onToggleContext: _toggleContextDrawer,
                  onCreateAgent: runtime.running || rc6 == null
                      ? null
                      : () => _createDefaultAgent(rc6),
                  onSend: () => _sendPrompt(rc6, runtime, selectedAgent),
                  onClearDialogue: () => _confirmAndClearDialogue(context, rc6),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _AgentPrimaryEntrySwitch extends StatelessWidget {
  const _AgentPrimaryEntrySwitch({
    required this.zh,
    required this.selectedIndex,
    required this.onSelected,
    required this.compact,
  });

  final bool zh;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final labels = zh
        ? const ['助手对话', '工作小组', '助手配置']
        : const ['Assistant Chat', 'Work Group', 'Assistant Config'];
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const Key('agent-primary-entry-switch'),
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _HTKWTokens.visualTokens(brightness).borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < labels.length; index++)
              Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
                child: _AgentPrimaryEntryButton(
                  label: labels[index],
                  selected: selectedIndex == index,
                  minWidth: zh
                      ? const [104.0, 104.0, 96.0][index]
                      : const [126.0, 112.0, 132.0][index],
                  compact: compact,
                  onTap: () => onSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AgentPrimaryEntryButton extends StatelessWidget {
  const _AgentPrimaryEntryButton({
    required this.label,
    required this.selected,
    required this.minWidth,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double minWidth;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? colors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          key: Key('agent-primary-entry-$label'),
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 16,
                vertical: 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    Icon(Icons.check, size: 14, color: colors.onPrimary),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: selected ? colors.onPrimary : colors.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgentConsoleItem {
  const _AgentConsoleItem({
    required this.id,
    required this.name,
    required this.role,
    required this.icon,
    required this.status,
    required this.knowledgeBaseCount,
    required this.skillCount,
    required this.taskCount,
    this.profile,
  });

  final String id;
  final String name;
  final String role;
  final IconData icon;
  final String status;
  final int knowledgeBaseCount;
  final int skillCount;
  final int taskCount;
  final Rc6AgentProfile? profile;
}

class _AgentConsoleMessage {
  const _AgentConsoleMessage({
    required this.author,
    required this.body,
    required this.meta,
    required this.isUser,
    this.id = '',
    this.status,
    this.steps = const [],
    this.citations = const [],
  });

  final String id;
  final String author;
  final String body;
  final String meta;
  final bool isUser;
  final String? status;
  final List<String> steps;
  final List<String> citations;
}

class _AgentConsoleResetWorkbench extends StatelessWidget {
  const _AgentConsoleResetWorkbench({
    required this.zh,
    required this.workspace,
    required this.agents,
    required this.selectedAgent,
    required this.thread,
    required this.runtime,
    required this.rc6,
    required this.modeIndex,
    required this.promptController,
    required this.onAgentSelected,
    required this.onModeSelected,
    required this.agentListDrawerOpen,
    required this.contextDrawerOpen,
    required this.onToggleAgentList,
    required this.onToggleContext,
    required this.onCreateAgent,
    required this.onSend,
    required this.onClearDialogue,
  });

  final bool zh;
  final String workspace;
  final List<_AgentConsoleItem> agents;
  final _AgentConsoleItem selectedAgent;
  final List<_AgentConsoleMessage> thread;
  final Rc6RuntimeState runtime;
  final Rc6RuntimeController? rc6;
  final int modeIndex;
  final TextEditingController promptController;
  final ValueChanged<String> onAgentSelected;
  final ValueChanged<int> onModeSelected;
  final bool agentListDrawerOpen;
  final bool contextDrawerOpen;
  final VoidCallback onToggleAgentList;
  final VoidCallback onToggleContext;
  final VoidCallback? onCreateAgent;
  final VoidCallback onSend;
  final VoidCallback onClearDialogue;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _compactAgentTheme(context),
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isSmall = width <= 960;
        final isWide = width >= 1360;
        final leftWidth = isWide ? 270.0 : 228.0;
        final rightWidth = isWide ? 300.0 : 270.0;
        final showLeft = !isSmall;
        final showRight = width >= 1120;
        final left = _AgentConversationListPanel(
          zh: zh,
          agents: agents,
          selectedAgentId: selectedAgent.id,
          onAgentSelected: onAgentSelected,
          onCreateAgent: onCreateAgent,
        );
        final right = _AgentContextPanel(
          zh: zh,
          agent: selectedAgent,
          runtime: runtime,
          rc6: rc6,
          onModeSelected: onModeSelected,
        );
        return Column(
          key: const Key('agent-console-reset-workbench'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AgentConsoleResetTopBar(
              zh: zh,
              workspace: workspace,
              runtime: runtime,
              showAgentButton: isSmall,
              showContextButton: !showRight,
              onToggleAgentList: onToggleAgentList,
              onToggleContext: onToggleContext,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showLeft) ...[
                        SizedBox(width: leftWidth, child: left),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: switch (modeIndex) {
                          0 => _AgentImDialoguePane(
                              zh: zh,
                              agent: selectedAgent,
                              thread: thread,
                              runtime: runtime,
                              promptController: promptController,
                              onSend: onSend,
                              onClearDialogue: onClearDialogue,
                            ),
                          1 => _AgentOrchestratorFlowPane(zh: zh),
                          _ => _AgentConfigWorkbenchPane(
                              zh: zh,
                              workspace: workspace,
                              selectedAgent: selectedAgent,
                              onAgentCreated: () => onModeSelected(0),
                            ),
                        },
                      ),
                      if (showRight) ...[
                        const SizedBox(width: 8),
                        SizedBox(width: rightWidth, child: right),
                      ],
                    ],
                  ),
                  if (isSmall && agentListDrawerOpen)
                    Positioned.fill(
                      child: _AgentSideDrawerShell(
                        alignRight: false,
                        width: 292,
                        child: left,
                      ),
                    ),
                  if (!showRight && contextDrawerOpen)
                    Positioned.fill(
                      child: _AgentSideDrawerShell(
                        alignRight: true,
                        width: 310,
                        child: right,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

ThemeData _compactAgentTheme(BuildContext context) {
  final base = Theme.of(context);
  TextStyle? shrink(TextStyle? style) {
    if (style == null) return null;
    final fontSize = style.fontSize;
    return style.copyWith(fontSize: fontSize == null ? 13 : fontSize - 1);
  }

  final textTheme = base.textTheme.copyWith(
    displayLarge: shrink(base.textTheme.displayLarge),
    displayMedium: shrink(base.textTheme.displayMedium),
    displaySmall: shrink(base.textTheme.displaySmall),
    headlineLarge: shrink(base.textTheme.headlineLarge),
    headlineMedium: shrink(base.textTheme.headlineMedium),
    headlineSmall: shrink(base.textTheme.headlineSmall),
    titleLarge: shrink(base.textTheme.titleLarge),
    titleMedium: shrink(base.textTheme.titleMedium),
    titleSmall: shrink(base.textTheme.titleSmall),
    bodyLarge: shrink(base.textTheme.bodyLarge),
    bodyMedium: shrink(base.textTheme.bodyMedium),
    bodySmall: shrink(base.textTheme.bodySmall),
    labelLarge: shrink(base.textTheme.labelLarge),
    labelMedium: shrink(base.textTheme.labelMedium),
    labelSmall: shrink(base.textTheme.labelSmall),
  );
  return base.copyWith(
    textTheme: textTheme,
    chipTheme: base.chipTheme.copyWith(
      labelStyle: shrink(base.chipTheme.labelStyle),
      secondaryLabelStyle: shrink(base.chipTheme.secondaryLabelStyle),
    ),
  );
}

class _AgentConsoleResetTopBar extends StatelessWidget {
  const _AgentConsoleResetTopBar({
    required this.zh,
    required this.workspace,
    required this.runtime,
    required this.showAgentButton,
    required this.showContextButton,
    required this.onToggleAgentList,
    required this.onToggleContext,
  });

  final bool zh;
  final String workspace;
  final Rc6RuntimeState runtime;
  final bool showAgentButton;
  final bool showContextButton;
  final VoidCallback onToggleAgentList;
  final VoidCallback onToggleContext;

  @override
  Widget build(BuildContext context) {
    final rawWorkspaceLabel = _displayNameForPath(workspace).trim();
    final workspaceLabel = rawWorkspaceLabel.isEmpty || rawWorkspaceLabel == '-'
        ? (zh ? '默认工作区' : 'Default Workspace')
        : rawWorkspaceLabel;
    final compact = showAgentButton || showContextButton;
    final brightness = Theme.of(context).brightness;
    return Container(
      key: const Key('agent-console-reset-top-bar'),
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          _HTKWTokens.moduleAssistant.withValues(
            alpha: brightness == Brightness.dark ? 0.045 : 0.025,
          ),
          _HTKWTokens.glassSurface(brightness),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _HTKWTokens.visualTokens(brightness).borderSubtle),
      ),
      child: compact
          ? Row(
              children: [
                if (showAgentButton) ...[
                  _AgentIconCommand(
                    tooltip: zh ? '助手与会话' : 'Assistants and sessions',
                    icon: Icons.people_alt_outlined,
                    onPressed: onToggleAgentList,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                    child: _AgentResetWorkspaceSummary(
                  zh: zh,
                  title: zh ? '助手工作台' : 'Assistant Workbench',
                  workspaceLabel: workspaceLabel,
                  runtime: runtime,
                )),
                if (showContextButton) ...[
                  const SizedBox(width: 8),
                  _AgentIconCommand(
                    tooltip: zh ? '工作区上下文' : 'Workspace context',
                    icon: Icons.folder_open_outlined,
                    onPressed: onToggleContext,
                  ),
                ],
              ],
            )
          : Row(
              children: [
                Expanded(
                    child: _AgentResetWorkspaceSummary(
                  zh: zh,
                  title: zh ? '助手工作台' : 'Assistant Workbench',
                  workspaceLabel: workspaceLabel,
                  runtime: runtime,
                )),
              ],
            ),
    );
  }
}

class _AgentResetWorkspaceSummary extends StatelessWidget {
  const _AgentResetWorkspaceSummary({
    required this.zh,
    required this.title,
    required this.workspaceLabel,
    required this.runtime,
  });

  final bool zh;
  final String title;
  final String workspaceLabel;
  final Rc6RuntimeState runtime;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: _HTKWTokens.moduleAssistant.withValues(alpha: 0.1),
          child: const Icon(Icons.people_alt_outlined,
              color: _HTKWTokens.moduleAssistant, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _AgentMiniChip(label: workspaceLabel),
                    const SizedBox(width: 6),
                    _AgentMiniChip(
                      label: runtime.memoryIndexReferencePath.isNotEmpty
                          ? (zh ? '增强记忆' : 'Enhanced memory')
                          : (zh ? '本地模式' : 'Local mode'),
                    ),
                    const SizedBox(width: 6),
                    _AgentMiniChip(
                      label: runtime.hasSkill
                          ? (zh ? '技能已加载' : 'Skill loaded')
                          : (zh ? '技能需要设置' : 'Skill needed'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgentIconCommand extends StatelessWidget {
  const _AgentIconCommand({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 36,
        child: IconButton.filledTonal(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _AgentSideDrawerShell extends StatelessWidget {
  const _AgentSideDrawerShell({
    required this.alignRight,
    required this.width,
    required this.child,
  });

  final bool alignRight;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      color: Colors.black.withValues(alpha: 0.06),
      child: SizedBox(
        width: width,
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}

class _AgentConversationListPanel extends StatelessWidget {
  const _AgentConversationListPanel({
    required this.zh,
    required this.agents,
    required this.selectedAgentId,
    required this.onAgentSelected,
    required this.onCreateAgent,
  });

  final bool zh;
  final List<_AgentConsoleItem> agents;
  final String selectedAgentId;
  final ValueChanged<String> onAgentSelected;
  final VoidCallback? onCreateAgent;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      key: const Key('agent-conversation-list-panel'),
      decoration: BoxDecoration(
        color: _HTKWTokens.panelSurface(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _HTKWTokens.visualTokens(brightness).borderSubtle,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    zh ? '助手 / 会话' : 'Assistants / Sessions',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: zh ? '新建助手' : 'New assistant',
                  onPressed: onCreateAgent,
                  icon: const Icon(Icons.add, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              key: const Key('agent-conversation-list-scroll'),
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              primary: false,
              itemCount: agents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final agent = agents[index];
                final selected = agent.id == selectedAgentId;
                return _AgentConversationTile(
                  zh: zh,
                  agent: agent,
                  selected: selected,
                  onTap: () => onAgentSelected(agent.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentConversationTile extends StatelessWidget {
  const _AgentConversationTile({
    required this.zh,
    required this.agent,
    required this.selected,
    required this.onTap,
  });

  final bool zh;
  final _AgentConsoleItem agent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    return Material(
      color: selected
          ? _HTKWTokens.moduleAssistant.withValues(
              alpha: brightness == Brightness.dark ? 0.14 : 0.08,
            )
          : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: Key('agent-im-contact-${agent.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: selected
                    ? _HTKWTokens.moduleAssistant.withValues(alpha: 0.1)
                    : colors.surfaceContainerHigh,
                child: Icon(
                  agent.icon,
                  size: 18,
                  color: selected
                      ? _HTKWTokens.moduleAssistant
                      : _HTKWTokens.moduleAssistant.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            agent.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (agent.taskCount > 0)
                          _AgentBadge(label: agent.taskCount.toString()),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      agent.role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _AgentMiniChip(label: agent.status),
                        _AgentMiniChip(
                          label: zh
                              ? '知识库 ${agent.knowledgeBaseCount}'
                              : 'Knowledge ${agent.knowledgeBaseCount}',
                        ),
                        if (agent.skillCount > 0)
                          _AgentMiniChip(
                            label: zh
                                ? '+${agent.skillCount} 技能'
                                : '+${agent.skillCount} skills',
                          ),
                      ],
                    ),
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

class _AgentImDialoguePane extends StatelessWidget {
  const _AgentImDialoguePane({
    required this.zh,
    required this.agent,
    required this.thread,
    required this.runtime,
    required this.promptController,
    required this.onSend,
    required this.onClearDialogue,
  });

  final bool zh;
  final _AgentConsoleItem agent;
  final List<_AgentConsoleMessage> thread;
  final Rc6RuntimeState runtime;
  final TextEditingController promptController;
  final VoidCallback onSend;
  final VoidCallback onClearDialogue;

  @override
  Widget build(BuildContext context) {
    final modelGate = runtime.hasAgentProfiles
        ? (zh ? '本地模式可运行' : 'Local mode runnable')
        : (zh ? '需要设置' : 'Needs setup');
    final brightness = Theme.of(context).brightness;
    return Container(
      key: const Key('agent-im-dialogue-pane'),
      decoration: BoxDecoration(
        color: _HTKWTokens.panelSurface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _HTKWTokens.visualTokens(brightness).borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 54,
            child: _AgentDialogueTitleBar(
              zh: zh,
              compact: true,
              agent: agent,
              runtime: runtime,
              modelGate: modelGate,
              onClearDialogue: onClearDialogue,
            ),
          ),
          Expanded(
            child: Container(
              key: const Key('agent-im-message-stream'),
              margin: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _HTKWTokens.recessedSurface(brightness),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.12),
                ),
              ),
              child: ListView.separated(
                key: Key('agent-im-message-stream-${agent.id}'),
                primary: false,
                itemCount: thread.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _AgentMessageBubble(
                  message: thread[index],
                  compact: true,
                ),
              ),
            ),
          ),
          SizedBox(
            key: const Key('agent-im-input-anchor'),
            height: 96,
            child: _AgentDialogueInputBar(
              zh: zh,
              compact: false,
              runtime: runtime,
              promptController: promptController,
              onSend: onSend,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentOrchestratorFlowPane extends StatelessWidget {
  const _AgentOrchestratorFlowPane({required this.zh});

  final bool zh;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      key: const Key('agent-orchestrator-flow-pane'),
      decoration: BoxDecoration(
        color: _HTKWTokens.panelSurface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _HTKWTokens.visualTokens(brightness).borderSubtle,
        ),
      ),
      child: _LocalScrollBox(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _AgentDiscussionProductView(zh: zh),
        ),
      ),
    );
  }
}

class _AgentConfigWorkbenchPane extends StatelessWidget {
  const _AgentConfigWorkbenchPane({
    required this.zh,
    required this.workspace,
    required this.selectedAgent,
    required this.onAgentCreated,
  });

  final bool zh;
  final String workspace;
  final _AgentConsoleItem selectedAgent;
  final VoidCallback onAgentCreated;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      key: const Key('agent-config-workbench-pane'),
      decoration: BoxDecoration(
        color: _HTKWTokens.panelSurface(brightness),
        borderRadius: BorderRadius.circular(_DesktopGrid.radiusLarge),
        border: Border.all(
          color: _HTKWTokens.visualTokens(brightness).borderSubtle,
        ),
      ),
      child: _LocalScrollBox(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _AgentProfileConfigPanel(
                zh: zh,
                selectedAgent: selectedAgent,
                onAgentCreated: onAgentCreated,
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              _AgentCreationProductView(
                zh: zh,
                workspace: workspace,
                onAgentCreated: onAgentCreated,
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              _AgentWorkspaceProductView(
                zh: zh,
                workspace: workspace,
                onAgentCreated: onAgentCreated,
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              _AgentRunAuditView(zh: zh),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentDialogueTitleBar extends StatelessWidget {
  const _AgentDialogueTitleBar({
    required this.zh,
    required this.compact,
    required this.agent,
    required this.runtime,
    required this.modelGate,
    required this.onClearDialogue,
  });

  final bool zh;
  final bool compact;
  final _AgentConsoleItem agent;
  final Rc6RuntimeState runtime;
  final String modelGate;
  final VoidCallback onClearDialogue;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      key: const Key('agent-dialogue-title-bar'),
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
      constraints: BoxConstraints(maxHeight: compact ? 46 : 58),
      decoration: BoxDecoration(
        color: _HTKWTokens.moduleAssistant.withValues(
          alpha: brightness == Brightness.dark ? 0.1 : 0.055,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _HTKWTokens.moduleAssistant.withValues(
            alpha: brightness == Brightness.dark ? 0.16 : 0.1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(agent.icon,
              color: _HTKWTokens.moduleAssistant, size: compact ? 18 : 20),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (compact
                          ? Theme.of(context).textTheme.titleSmall
                          : Theme.of(context).textTheme.titleMedium)
                      ?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 3),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _AgentMiniChip(label: agent.status),
                        const SizedBox(width: 8),
                        _AgentMiniChip(
                            label: runtime.hasKnowledgeBase
                                ? (zh ? '知识库已绑定' : 'Knowledge bound')
                                : (zh ? '知识库需要设置' : 'Knowledge needed')),
                        const SizedBox(width: 8),
                        _AgentMiniChip(
                            label: runtime.hasSkill
                                ? (zh ? '技能已绑定' : 'Skill bound')
                                : (zh ? '技能需要设置' : 'Skill needed')),
                        const SizedBox(width: 8),
                        _AgentMiniChip(label: modelGate),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: zh ? '固定助手' : 'Pin assistant',
            onPressed: null,
            icon: const Icon(Icons.push_pin_outlined),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: zh ? '清空当前对话' : 'Clear dialogue',
            onPressed: runtime.hasAgentDialogueHistory ? onClearDialogue : null,
            icon: const Icon(Icons.delete_sweep_outlined),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _AgentDialogueInputBar extends StatelessWidget {
  const _AgentDialogueInputBar({
    required this.zh,
    required this.compact,
    required this.runtime,
    required this.promptController,
    required this.onSend,
  });

  final bool zh;
  final bool compact;
  final Rc6RuntimeState runtime;
  final TextEditingController promptController;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final canSend = !runtime.running && runtime.hasAgentProfiles;
    final brightness = Theme.of(context).brightness;
    return Container(
      key: const Key('agent-dialogue-input-bar'),
      padding: EdgeInsets.all(compact ? 4 : 6),
      constraints: BoxConstraints(maxHeight: compact ? 78 : 92),
      decoration: BoxDecoration(
        color: _HTKWTokens.glassSurface(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _HTKWTokens.moduleAssistant.withValues(
            alpha: brightness == Brightness.dark ? 0.18 : 0.12,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const Key('agent-dialogue-input'),
              controller: promptController,
              minLines: 1,
              maxLines: compact ? 1 : 2,
              enabled: !runtime.running,
              decoration: InputDecoration(
                labelText: zh ? '输入你的问题' : 'Ask a question',
                helperText: compact
                    ? null
                    : (canSend
                        ? null
                        : (zh
                            ? '需要先创建助手；未配置连接时会保存本地占位回复。'
                            : 'Create an assistant first; unconfigured connections save a local fallback reply.')),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          SizedBox(
            width: compact ? 88 : 112,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PrimaryProductAction(
                  automationKey: 'agent-dialogue-send-button',
                  label: zh ? '发送' : 'Send',
                  icon: Icons.send_outlined,
                  onPressed: canSend ? onSend : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentProfileConfigPanel extends StatefulWidget {
  const _AgentProfileConfigPanel({
    required this.zh,
    required this.selectedAgent,
    required this.onAgentCreated,
  });

  final bool zh;
  final _AgentConsoleItem selectedAgent;
  final VoidCallback onAgentCreated;

  @override
  State<_AgentProfileConfigPanel> createState() =>
      _AgentProfileConfigPanelState();
}

class _AgentProfileConfigPanelState extends State<_AgentProfileConfigPanel> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _roleController;
  final Set<String> _selectedKbIds = {};
  final Set<String> _selectedSkillIds = {};
  String _loadedAgentId = '';
  String _savedName = '';
  String _savedDescription = '';
  String _savedRole = '';
  Set<String> _savedKbIds = {};
  Set<String> _savedSkillIds = {};

  bool get zh => widget.zh;
  bool get _hasUnsavedChanges =>
      _nameController.text.trim() != _savedName ||
      _descriptionController.text.trim() != _savedDescription ||
      _roleController.text.trim() != _savedRole ||
      !_setEquals(_selectedKbIds, _savedKbIds) ||
      !_setEquals(_selectedSkillIds, _savedSkillIds);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _roleController = TextEditingController();
    _nameController.addListener(_markDirty);
    _descriptionController.addListener(_markDirty);
    _roleController.addListener(_markDirty);
    _syncFromAgent(widget.selectedAgent);
  }

  @override
  void didUpdateWidget(covariant _AgentProfileConfigPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedAgent.id != widget.selectedAgent.id) {
      _syncFromAgent(widget.selectedAgent);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_markDirty);
    _descriptionController.removeListener(_markDirty);
    _roleController.removeListener(_markDirty);
    _nameController.dispose();
    _descriptionController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (mounted) setState(() {});
  }

  bool _setEquals(Set<String> left, Set<String> right) {
    return left.length == right.length && left.containsAll(right);
  }

  void _syncFromAgent(_AgentConsoleItem agent) {
    final profile = agent.profile;
    _loadedAgentId = agent.id;
    _nameController.text = profile?.name ?? '';
    _descriptionController.text = profile?.description ?? '';
    _roleController.text = profile?.role ?? '';
    _savedName = _nameController.text.trim();
    _savedDescription = _descriptionController.text.trim();
    _savedRole = _roleController.text.trim();
    _selectedKbIds
      ..clear()
      ..addAll(profile?.boundKnowledgeBaseIds ?? const <String>[]);
    _selectedSkillIds
      ..clear()
      ..addAll(profile?.boundSkillIds ?? const <String>[]);
    _savedKbIds = Set<String>.from(_selectedKbIds);
    _savedSkillIds = Set<String>.from(_selectedSkillIds);
  }

  void _syncSavedProfile(Rc6AgentProfile profile) {
    _savedName = profile.name.trim();
    _savedDescription = profile.description.trim();
    _savedRole = profile.role.trim();
    _savedKbIds = Set<String>.from(profile.boundKnowledgeBaseIds);
    _savedSkillIds = Set<String>.from(profile.boundSkillIds);
    _nameController.text = _savedName;
    _descriptionController.text = _savedDescription;
    _roleController.text = _savedRole;
    _selectedKbIds
      ..clear()
      ..addAll(_savedKbIds);
    _selectedSkillIds
      ..clear()
      ..addAll(_savedSkillIds);
  }

  Future<void> _save(Rc6RuntimeController? rc6) async {
    if (rc6 == null || _loadedAgentId.isEmpty) return;
    final updated = await rc6.updateAgentProfile(
      agentId: _loadedAgentId,
      name: _nameController.text,
      description: _descriptionController.text,
      role: _roleController.text,
      boundKnowledgeBaseIds: _selectedKbIds.toList(growable: false),
      boundSkillIds: _selectedSkillIds.toList(growable: false),
      settings: const {'reply_mode': 'local_fallback_until_configured'},
    );
    if (updated != null && mounted) {
      setState(() => _syncSavedProfile(updated));
    }
  }

  void _restoreSaved() {
    setState(() {
      _nameController.text = _savedName;
      _descriptionController.text = _savedDescription;
      _roleController.text = _savedRole;
      _selectedKbIds
        ..clear()
        ..addAll(_savedKbIds);
      _selectedSkillIds
        ..clear()
        ..addAll(_savedSkillIds);
    });
  }

  Future<void> _delete(
    BuildContext context,
    Rc6RuntimeController? rc6,
  ) async {
    if (rc6 == null || _loadedAgentId.isEmpty) return;
    final confirmed = await _confirmDestructiveAction(
      context,
      title: zh ? '删除助手？' : 'Delete assistant?',
      body: zh
          ? '这会删除该助手和本地会话；知识库、技能和其它助手保留。'
          : 'This deletes this assistant and local conversation; knowledge bases, skills, and other assistants remain.',
    );
    if (!confirmed) return;
    await rc6.deleteAgentProfile(_loadedAgentId);
  }

  Future<void> _saveLatestReply(Rc6RuntimeController? rc6) async {
    if (rc6 == null || _loadedAgentId.isEmpty) return;
    final conversation = rc6.state.agentConversations.firstWhere(
      (item) => item.agentId == _loadedAgentId,
      orElse: () => Rc6AgentConversation.empty(_loadedAgentId),
    );
    final replies = conversation.messages
        .where((message) => message.role == 'assistant')
        .toList(growable: false);
    if (replies.isEmpty) return;
    await rc6.saveAgentReplyToArtifact(
      agentId: _loadedAgentId,
      messageId: replies.last.id,
    );
  }

  Future<void> _runBackendSeparationEvidence(
    Rc6RuntimeController? rc6,
  ) async {
    if (rc6 == null || _loadedAgentId.isEmpty) return;
    await rc6.runAssistantBackendSeparationAcceptance();
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final profile = widget.selectedAgent.profile;
    final skillOptions = <String>[
      if (runtime.hasSkill) 'primary_skill',
      if (runtime.hasLocalizedSkillManifest) 'localized_skill',
    ];
    final canEdit = rc6 != null && !runtime.running && profile != null;
    final canSave = canEdit && _hasUnsavedChanges;
    final latestReplyExists = _loadedAgentId.isNotEmpty &&
        runtime.agentConversations
            .where((item) => item.agentId == _loadedAgentId)
            .expand((item) => item.messages)
            .any((message) => message.role == 'assistant');
    return _ProductPanel(
      keyName: 'agent-profile-runtime-config',
      icon: Icons.tune_outlined,
      title: zh ? '助手配置' : 'Assistant Config',
      subtitle: profile == null
          ? (zh ? '先创建助手，再保存配置。' : 'Create an assistant before saving config.')
          : (zh
              ? '配置会写入本地助手目录，重新进入后保留。'
              : 'Saved locally and kept after reopening.'),
      children: [
        if (profile == null) ...[
          _FieldRow(
            label: zh ? '当前状态' : 'Current state',
            value: zh ? '尚未创建助手' : 'No assistant created',
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _PrimaryProductAction(
            label: zh ? '创建助手' : 'Create assistant',
            icon: Icons.add,
            onPressed: rc6 == null || runtime.running
                ? null
                : () async {
                    await rc6.createAgentProfile(
                      name: zh ? '任务总控' : 'Task Lead',
                      description:
                          zh ? '处理当前工作区任务。' : 'Handles workspace tasks.',
                      role: zh ? '处理当前工作区任务' : 'Handles workspace tasks',
                      boundKnowledgeBaseIds: runtime.knowledgeBases
                          .map((kb) => kb.id)
                          .toList(growable: false),
                      boundSkillIds:
                          runtime.hasSkill ? const ['primary_skill'] : const [],
                    );
                    widget.onAgentCreated();
                  },
          ),
        ] else ...[
          Row(
            children: [
              Icon(
                _hasUnsavedChanges
                    ? Icons.edit_note_outlined
                    : Icons.check_circle_outline,
                size: 18,
                color: _hasUnsavedChanges
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _hasUnsavedChanges
                      ? (zh ? '有未保存更改' : 'Unsaved changes')
                      : (zh ? '当前配置已保存' : 'Current config saved'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: _hasUnsavedChanges ? _restoreSaved : null,
                icon: const Icon(Icons.restore_outlined, size: 18),
                label: Text(zh ? '还原' : 'Restore'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('agent-profile-name-input'),
            controller: _nameController,
            enabled: canEdit,
            decoration: InputDecoration(
              labelText: zh ? '助手名称' : 'Assistant name',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('agent-profile-description-input'),
            controller: _descriptionController,
            enabled: canEdit,
            decoration: InputDecoration(
              labelText: zh ? '助手说明' : 'Description',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('agent-profile-role-input'),
            controller: _roleController,
            enabled: canEdit,
            minLines: 1,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: zh ? '角色说明' : 'Role',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _SectionCaption(zh ? '绑定知识库' : 'Bound knowledge bases'),
          const SizedBox(height: 8),
          if (runtime.knowledgeBases.isEmpty)
            _FieldRow(
              label: zh ? '知识库' : 'Knowledge base',
              value: zh ? '暂无可绑定知识库' : 'No knowledge base available',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kb in runtime.knowledgeBases)
                  FilterChip(
                    label: Text(kb.name),
                    selected: _selectedKbIds.contains(kb.id),
                    onSelected: canEdit
                        ? (selected) => setState(() {
                              if (selected) {
                                _selectedKbIds.add(kb.id);
                              } else {
                                _selectedKbIds.remove(kb.id);
                              }
                            })
                        : null,
                  ),
              ],
            ),
          const SizedBox(height: _DesktopGrid.gutter),
          _SectionCaption(zh ? '绑定技能' : 'Bound skills'),
          const SizedBox(height: 8),
          if (skillOptions.isEmpty)
            _FieldRow(
              label: zh ? '技能' : 'Skill',
              value: zh ? '暂无可绑定技能' : 'No skill available',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skillId in skillOptions)
                  FilterChip(
                    label: Text(skillId == 'primary_skill'
                        ? (zh ? '当前技能' : 'Current skill')
                        : (zh ? '本地化技能' : 'Localized skill')),
                    selected: _selectedSkillIds.contains(skillId),
                    onSelected: canEdit
                        ? (selected) => setState(() {
                              if (selected) {
                                _selectedSkillIds.add(skillId);
                              } else {
                                _selectedSkillIds.remove(skillId);
                              }
                            })
                        : null,
                  ),
              ],
            ),
          const SizedBox(height: _DesktopGrid.gutter),
          _ProductTable(
            columns: zh
                ? const ['后端项', '绑定值', '状态']
                : const ['Backend item', 'Binding', 'Status'],
            rows: [
              [
                zh ? '配置档' : 'Config profile',
                profile.settings['active_profile_id'] ?? '-',
                zh ? '与助手配置分离保存' : 'Saved separately'
              ],
              [
                zh ? '模型配置' : 'Model config',
                profile.settings['model_config_id'] ?? '-',
                zh ? '只保存引用' : 'Reference only'
              ],
              [
                zh ? '模型网关' : 'Model gateway',
                profile.settings['model_gateway_config_id'] ?? '-',
                zh ? '只保存引用' : 'Reference only'
              ],
            ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          Row(
            children: [
              Expanded(
                child: _PrimaryProductAction(
                  automationKey: 'agent-profile-save-button',
                  label: zh ? '保存配置' : 'Save config',
                  icon: Icons.save_outlined,
                  onPressed: canSave ? () => _save(rc6) : null,
                ),
              ),
              const SizedBox(width: _DesktopGrid.gutter),
              Expanded(
                child: _DisplayAction(
                  label: zh ? '保存到成果' : 'Save to outputs',
                  icon: Icons.folder_copy_outlined,
                  onPressed:
                      latestReplyExists ? () => _saveLatestReply(rc6) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _PrimaryProductAction(
            automationKey: 'agent-backend-separation-evidence-button',
            label: zh ? '生成后端分离证据' : 'Generate backend separation evidence',
            icon: Icons.hub_outlined,
            onPressed:
                canEdit ? () => _runBackendSeparationEvidence(rc6) : null,
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('agent-profile-delete-button'),
              onPressed: canEdit ? () => _delete(context, rc6) : null,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(zh ? '删除助手' : 'Delete assistant'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.42),
                ),
                minimumSize: const Size.fromHeight(42),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AgentMessageBubble extends StatefulWidget {
  const _AgentMessageBubble({
    required this.message,
    required this.compact,
  });

  final _AgentConsoleMessage message;
  final bool compact;

  @override
  State<_AgentMessageBubble> createState() => _AgentMessageBubbleState();
}

class _AgentMessageBubbleState extends State<_AgentMessageBubble> {
  bool _stepsExpanded = false;
  bool _citationsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final message = widget.message;
    final compact = widget.compact;
    final alignment =
        message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final body = Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        color: message.isUser
            ? Color.alphaBlend(
                _HTKWTokens.moduleAssistant.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.12
                      : 0.07,
                ),
                colors.surface,
              )
            : colors.surface,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(
          color: message.isUser
              ? _HTKWTokens.moduleAssistant.withValues(alpha: 0.18)
              : colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.status != null) ...[
            _AgentMessageSectionHeader(
              label: message.status!,
              icon: Icons.task_alt_outlined,
            ),
            SizedBox(height: compact ? 6 : 8),
          ],
          Text(
            message.body,
            style: (compact
                    ? Theme.of(context).textTheme.bodySmall
                    : Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.28,
            ),
          ),
          if (message.steps.isNotEmpty) ...[
            SizedBox(height: compact ? 6 : 10),
            _AgentExpandableMessageSection(
              title: '执行步骤',
              expanded: _stepsExpanded,
              onToggle: () => setState(() => _stepsExpanded = !_stepsExpanded),
              children: [
                for (final step in message.steps)
                  Padding(
                    padding: EdgeInsets.only(bottom: compact ? 3 : 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 15),
                        const SizedBox(width: 6),
                        Expanded(child: Text(step)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (message.citations.isNotEmpty) ...[
            SizedBox(height: compact ? 6 : 8),
            _AgentExpandableMessageSection(
              title: '引用来源',
              expanded: _citationsExpanded,
              onToggle: () =>
                  setState(() => _citationsExpanded = !_citationsExpanded),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final citation in message.citations) ...[
                        _AgentMiniChip(label: citation),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          message.author,
          style: (compact
                  ? Theme.of(context).textTheme.labelMedium
                  : Theme.of(context).textTheme.labelLarge)
              ?.copyWith(
            fontWeight: FontWeight.w900,
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: compact ? 3 : 5),
        FractionallySizedBox(
          widthFactor: message.isUser ? 0.78 : 1,
          alignment:
              message.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: body,
        ),
        SizedBox(height: compact ? 2 : 4),
        Text(
          message.meta,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _AgentMessageSectionHeader extends StatelessWidget {
  const _AgentMessageSectionHeader({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _HTKWTokens.moduleAssistant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ],
    );
  }
}

class _AgentExpandableMessageSection extends StatelessWidget {
  const _AgentExpandableMessageSection({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _HTKWTokens.visualTokens(brightness).borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                Icon(expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 6),
            ...children,
          ],
        ],
      ),
    );
  }
}

class _AgentContextPanel extends StatelessWidget {
  const _AgentContextPanel({
    required this.zh,
    required this.agent,
    required this.runtime,
    required this.rc6,
    required this.onModeSelected,
  });

  final bool zh;
  final _AgentConsoleItem agent;
  final Rc6RuntimeState runtime;
  final Rc6RuntimeController? rc6;
  final ValueChanged<int> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxHeight <= 110) {
        return _CompactAgentContextBar(
          zh: zh,
          runtime: runtime,
          onModeSelected: onModeSelected,
        );
      }
      return _AgentContextCard(
        zh: zh,
        agent: agent,
        runtime: runtime,
        rc6: rc6,
        onModeSelected: onModeSelected,
      );
    });
  }
}

class _CompactAgentContextBar extends StatelessWidget {
  const _CompactAgentContextBar({
    required this.zh,
    required this.runtime,
    required this.onModeSelected,
  });

  final bool zh;
  final Rc6RuntimeState runtime;
  final ValueChanged<int> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return _FigmaCard(
      keyName: 'agent-context-panel',
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _AgentContextSummary(
                    label: zh ? '当前知识库' : 'Current KB',
                    value: runtime.hasKnowledgeBase
                        ? (zh
                            ? '产品文档库 / FAQ / 行业报告'
                            : 'Product / FAQ / Reports')
                        : (zh ? '需要设置' : 'Needs setup'),
                  ),
                  const SizedBox(width: 12),
                  _AgentContextSummary(
                    label: zh ? '技能' : 'Skill',
                    value: runtime.hasSkill
                        ? (zh
                            ? '知识整理 / 文档生成 / 检索'
                            : 'Knowledge / Document / Retrieval')
                        : (zh ? '暂不可用' : 'Unavailable'),
                  ),
                  const SizedBox(width: 12),
                  _AgentContextSummary(
                    label: zh ? '记忆' : 'Memory',
                    value: runtime.memoryIndexReferencePath.isNotEmpty
                        ? (zh ? '增强记忆' : 'Enhanced')
                        : (zh ? '本地模式' : 'Local mode'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 136,
            child: _PrimaryProductAction(
              automationKey: 'agent-multi-assistant-entry',
              label: zh ? '工作小组暂不可用' : 'Work Group Unavailable',
              icon: Icons.groups_2_outlined,
              onPressed: null,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentContextSummary extends StatelessWidget {
  const _AgentContextSummary({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _AgentContextCard extends StatelessWidget {
  const _AgentContextCard({
    required this.zh,
    required this.agent,
    required this.runtime,
    required this.rc6,
    required this.onModeSelected,
  });

  final bool zh;
  final _AgentConsoleItem agent;
  final Rc6RuntimeState runtime;
  final Rc6RuntimeController? rc6;
  final ValueChanged<int> onModeSelected;

  @override
  Widget build(BuildContext context) {
    final selectedAgentArtifacts = runtime.agentArtifacts
        .where((artifact) => artifact.agentId == agent.id)
        .where((artifact) => artifact.path.isNotEmpty)
        .toList(growable: false);
    final agentReplyOutputPath =
        selectedAgentArtifacts.isEmpty ? '' : selectedAgentArtifacts.last.path;
    final outputPath = agentReplyOutputPath.isNotEmpty
        ? agentReplyOutputPath
        : runtime.hasAgentDialogueExport
            ? runtime.agentDialogueExportPath
            : runtime.hasMultiAgentDiscussion
                ? runtime.multiAgentDiscussionPath
                : '';
    return _FigmaCard(
      keyName: 'agent-context-panel',
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            zh ? '上下文与成果承接' : 'Context and Outputs',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _LocalScrollBox(
              child: Column(
                children: [
                  _FieldRow(
                    label: zh ? '当前知识库' : 'Current knowledge base',
                    value: runtime.hasKnowledgeBase
                        ? (zh
                            ? '产品文档库 / FAQ 知识库 / 行业报告库'
                            : 'Product Docs / FAQ / Industry Reports')
                        : (zh ? '需要设置' : 'Needs setup'),
                  ),
                  const SizedBox(height: 8),
                  _FieldRow(
                    label: zh ? '已加载技能' : 'Loaded skill',
                    value: runtime.hasSkill
                        ? (zh
                            ? '知识整理 / 文档生成 / 检索验证'
                            : 'Knowledge / Document / Retrieval')
                        : (zh ? '暂不可用' : 'Unavailable'),
                  ),
                  const SizedBox(height: 8),
                  _FieldRow(
                    label: zh ? '工作区记忆' : 'Workspace Memory',
                    value: runtime.memoryIndexReferencePath.isNotEmpty
                        ? (zh ? '增强记忆已生成' : 'Enhanced memory generated')
                        : (zh ? '本地模式' : 'Local mode'),
                  ),
                  const SizedBox(height: 8),
                  _FieldRow(
                    label: zh ? '当前任务链' : 'Task Chain',
                    value: runtime.hasAgentDialogue
                        ? (zh
                            ? '${runtime.agentDialogueTurnCount} 轮对话'
                            : '${runtime.agentDialogueTurnCount} turns')
                        : (zh ? '等待助手对话' : 'Waiting assistant chat'),
                  ),
                  const SizedBox(height: 8),
                  _FieldRow(
                    label: zh ? '最近引用来源' : 'Recent Sources',
                    value: runtime.hasAgentDialogue
                        ? (zh
                            ? '${runtime.agentDialogueEvidenceCount} 条证据'
                            : '${runtime.agentDialogueEvidenceCount} citations')
                        : (zh ? '运行后显示' : 'Visible after run'),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryProductAction(
                    automationKey: 'agent-multi-assistant-entry',
                    label: zh ? '工作小组暂不可用' : 'Work Group Unavailable',
                    icon: Icons.groups_2_outlined,
                    onPressed: null,
                  ),
                  const SizedBox(height: 8),
                  _DisplayAction(
                    label: zh ? '查看工作区记忆' : 'View workspace memory',
                    icon: Icons.memory_outlined,
                    onPressed: runtime.memoryIndexReferencePath.isEmpty
                        ? null
                        : () => _showWorkspaceArtifactPreview(
                              context,
                              rc6: rc6,
                              title: zh ? '工作区记忆' : 'Workspace memory',
                              path: runtime.memoryIndexReferencePath,
                              unavailableMessage: zh
                                  ? '尚未生成可预览记忆。'
                                  : 'No previewable memory generated.',
                              closeLabel: zh ? '关闭' : 'Close',
                            ),
                  ),
                  const SizedBox(height: 8),
                  _DisplayAction(
                    label: zh ? '打开成果' : 'Open output',
                    icon: Icons.folder_copy_outlined,
                    onPressed: outputPath.isNotEmpty
                        ? () => _showWorkspaceArtifactPreview(
                              context,
                              rc6: rc6,
                              title: zh ? '当前助手成果' : 'Current assistant output',
                              path: outputPath,
                              unavailableMessage: zh
                                  ? '尚未生成可预览成果。'
                                  : 'No previewable output generated.',
                              closeLabel: zh ? '关闭' : 'Close',
                            )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  _DisplayAction(
                    label: zh ? '切换到工作小组' : 'Switch to work group',
                    icon: Icons.swap_horiz_outlined,
                    onPressed: () => onModeSelected(1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentMiniChip extends StatelessWidget {
  const _AgentMiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _HTKWTokens.visualTokens(brightness).borderSubtle,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
      ),
    );
  }
}

class _AgentBadge extends StatelessWidget {
  const _AgentBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _HTKWTokens.moduleAssistant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

// ignore: unused_element
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
        title: zh ? '操作记录' : 'Operation Records',
        subtitle: zh
            ? '查看助手对话、导出、工作小组和权限校验状态。'
            : 'Review assistant chat, export, discussion, and permission status.',
        children: [
          _ProductTable(
            columns: zh ? ['对象', '状态', '用户可见结果'] : ['Item', 'Status', 'Result'],
            rows: zh
                ? [
                    [
                      '助手对话',
                      dialogueStatus,
                      '${runtime.agentDialogueTurnCount} 轮'
                    ],
                    [
                      '对话导出',
                      exportStatus,
                      runtime.hasAgentDialogueExport ? '可在当前成果查看' : '等待导出'
                    ],
                    [
                      '工作小组',
                      a2aStatus,
                      runtime.a2aTopic.isEmpty ? '等待任务主题' : runtime.a2aTopic
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
                    ['小组分歧', runtime.hasA2aSessionManifest ? '有小组记录' : '无小组记录'],
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

// ignore: unused_element
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

// ignore: unused_element
class _AgentWorkspaceProductView extends StatelessWidget {
  const _AgentWorkspaceProductView({
    required this.zh,
    required this.workspace,
    required this.onAgentCreated,
  });

  final bool zh;
  final String workspace;
  final VoidCallback onAgentCreated;

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
                ? '未连接时不影响助手对话'
                : 'Dialogue continues without professional memory')
            : (zh
                ? '未配置专业长期记忆'
                : 'Professional long-term memory not configured');
    final collaborationStatus = runtime.hasA2aSessionManifest
        ? (zh ? '工作小组记录已生成' : 'Work group recorded')
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
                    ['模型', '助手问答与工作小组', modelStatus],
                    ['短期记忆', '对话上下文', memoryStatus],
                    ['长期记忆', '知识记忆', vectorMemoryStatus],
                    ['工作小组导出', '小组处理记录', collaborationStatus],
                    [
                      '助手列表',
                      '知识应用统一管理',
                      runtime.hasAgent ? 'K1 + S1' : '生成助手后写入'
                    ],
                    [
                      '会话列表',
                      '助手对话历史',
                      runtime.hasAgentDialogue ? '已有会话' : '创建后立即对话'
                    ],
                    [
                      '工作小组',
                      '小组记录管理',
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
                : () async {
                    await rc6.completeAgentProductOperations();
                    onAgentCreated();
                  },
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
                    ['助手对话', runtime.hasAgentDialogue ? '已有记录' : '未运行'],
                    ['工作小组', runtime.hasMultiAgentDiscussion ? '已有纪要' : '未运行'],
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
                  ? '用于生成助手配置、对话上下文和操作记录。'
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
                      '立即进入助手对话'
                    ],
                    [
                      '阅读总结助手',
                      '简单助手',
                      runtime.hasKnowledgeBase ? '已绑定' : '请先构建知识库',
                      runtime.hasSkill ? '已绑定' : '请先生成技能',
                      '立即进入助手对话'
                    ],
                    [
                      '质检 / 运营 / 产品分析助手',
                      '复杂助手',
                      runtime.hasKnowledgeBase ? '已绑定' : '请先构建知识库',
                      runtime.hasSkill ? '已绑定' : '请先生成技能',
                      '写入记忆 / 工具设置 / 操作记录'
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
            automationKey: 'workbench.agent.create_and_chat_button',
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
            ? (zh ? '助手对话配置' : 'Assistant Chat Config')
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
                ? '创建后立即进入助手对话'
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

  bool get zh => widget.zh;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'multi-agent-discussion-product-flow',
      icon: Icons.groups_2_outlined,
      title: zh ? '工作小组' : 'Work Group',
      subtitle: zh
          ? '暂不可用：需要先完成单助手创建、配置、对话和成果保存。'
          : 'Unavailable: finish single assistant creation, config, chat, and output save first.',
      children: [
        TextField(
          key: const Key('a2a-topic-input'),
          controller: _topicController,
          enabled: false,
          decoration: InputDecoration(
            labelText: zh ? '协作任务输入' : 'Collaboration task input',
            helperText: zh
                ? '工作小组暂不可用，当前仅保留入口状态。'
                : 'Work group is unavailable; only the gated entry is shown.',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          minLines: 1,
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        _FieldRow(
          label: zh ? '当前状态' : 'Current state',
          value: zh
              ? '暂不可用：需要先完成单助手能力。'
              : 'Unavailable: finish single assistant capability first.',
        ),
        const SizedBox(height: 8),
        _FieldRow(
          label: zh ? '本轮结论' : 'Gate result',
          value: zh
              ? '工作小组 / 多助手协作已降级，禁止假可用。'
              : 'Work group and multi-assistant collaboration are gated.',
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _PrimaryProductAction(
          label: zh ? '启动工作小组' : 'Start Work Group',
          icon: Icons.forum_outlined,
          onPressed: null,
        ),
      ],
    );
  }
}

// ignore: unused_element
class _A2aExecutionCard extends StatelessWidget {
  const _A2aExecutionCard({
    required this.agentName,
    required this.status,
    required this.input,
    required this.output,
    required this.icon,
    required this.pageId,
    required this.index,
    required this.last,
  });

  final String agentName;
  final String status;
  final String input;
  final String output;
  final IconData icon;
  final String pageId;
  final int index;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final accent = _HTKWTokens.moduleColor(pageId);
    return Container(
      key: Key('a2a-execution-$agentName'),
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
      decoration: BoxDecoration(
        color: accent.withValues(
          alpha: brightness == Brightness.dark ? 0.08 : 0.045,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(
            alpha: brightness == Brightness.dark ? 0.14 : 0.09,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(
                      alpha: brightness == Brightness.dark ? 0.16 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: accent, size: 16),
                ),
                if (!last)
                  Container(
                    width: 1,
                    height: 24,
                    margin: const EdgeInsets.only(top: 6),
                    color: _HTKWTokens.visualTokens(brightness).borderSubtle,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        agentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    _AgentMiniChip(label: status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  input,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  output,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _A2aResultPanel extends StatelessWidget {
  const _A2aResultPanel({
    required this.zh,
    required this.sessionId,
    required this.topic,
    required this.participants,
    required this.status,
    required this.evidenceCount,
    required this.conflictStatus,
    required this.consensusStatus,
  });

  final bool zh;
  final String sessionId;
  final String topic;
  final String participants;
  final String status;
  final String evidenceCount;
  final String conflictStatus;
  final String consensusStatus;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      key: const Key('a2a-result-panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _HTKWTokens.visualTokens(brightness).borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldRow(label: zh ? '小组记录' : 'Work group record', value: sessionId),
          const SizedBox(height: 8),
          _FieldRow(label: zh ? '任务主题' : 'Topic', value: topic),
          const SizedBox(height: 8),
          _FieldRow(label: zh ? '参与助手' : 'Participants', value: participants),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AgentMiniChip(label: '${zh ? '状态' : 'Status'}：$status'),
              _AgentMiniChip(
                  label: '${zh ? '引用' : 'Citations'}：$evidenceCount'),
              _AgentMiniChip(
                  label: '${zh ? '冲突' : 'Conflict'}：$conflictStatus'),
              _AgentMiniChip(
                  label: '${zh ? '共识' : 'Consensus'}：$consensusStatus'),
            ],
          ),
        ],
      ),
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
      title: zh ? '清空助手对话？' : 'Clear assistant chat?',
      body: zh
          ? '这会删除当前助手的对话内容、会话历史和对话导出；助手配置、技能、知识库和工作小组成果不会被删除。'
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
                      'Assistant',
                      runtime.hasAgent
                          ? 'Generated'
                          : 'Generate Assistant first',
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
        'Connection credentials remain env/secret-store only and are never bundled.',
  },
  'degraded_modes': <Map<String, dynamic>>[
    {
      'condition': 'missing_provider_env',
      'runtime_status': 'degraded',
      'user_message':
          'Connection-backed actions stay disabled until setup is repaired.',
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
