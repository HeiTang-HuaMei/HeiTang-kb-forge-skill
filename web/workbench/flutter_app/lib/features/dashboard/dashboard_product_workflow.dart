part of '../../main.dart';

class _DesktopDashboardSurface extends StatelessWidget {
  const _DesktopDashboardSurface({
    required this.localeCode,
    required this.contracts,
    required this.workflowV2Evidence,
    required this.parserBackends,
    required this.externalCapabilities,
    required this.workspace,
    required this.isWebRuntime,
    required this.onPageChanged,
  });

  final String localeCode;
  final WorkbenchContracts contracts;
  final P1WorkflowEvidence workflowV2Evidence;
  final ParserBackendMatrix parserBackends;
  final ExternalCapabilityRegistry externalCapabilities;
  final String workspace;
  final bool isWebRuntime;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return _FigmaPageCanvas(
      spacing: 22,
      children: [
        _FigmaFixedRow(
          height: 190,
          widths: const [540, 542],
          children: [
            _DashboardHeroCard(
              localeCode: localeCode,
              runtime: _Rc6RuntimeScope.of(context)?.state ??
                  Rc6RuntimeState.initial(),
              onPageChanged: onPageChanged,
            ),
            _DashboardAssetOverviewCard(
              localeCode: localeCode,
              workspace: workspace,
              runtime: _Rc6RuntimeScope.of(context)?.state ??
                  Rc6RuntimeState.initial(),
            ),
          ],
        ),
        SizedBox(
          height: 178,
          child: _DashboardMainFlowCard(
            localeCode: localeCode,
            onPageChanged: onPageChanged,
          ),
        ),
        _FigmaFixedRow(
          height: 230,
          widths: const [520, 260, 268],
          spacing: 32,
          children: [
            _DashboardRecentTasks(
              localeCode: localeCode,
              onPageChanged: onPageChanged,
            ),
            _DashboardRecentActivity(
              localeCode: localeCode,
              workflowV2Evidence: workflowV2Evidence,
              parserBackends: parserBackends,
            ),
            _DashboardArtifactOverview(
              localeCode: localeCode,
              onPageChanged: onPageChanged,
            ),
          ],
        ),
        SizedBox(
          height: 48,
          child: _DashboardIsolationNotice(localeCode: localeCode),
        ),
      ],
    );
  }
}

class _DashboardHeroCard extends StatelessWidget {
  const _DashboardHeroCard({
    required this.localeCode,
    required this.runtime,
    required this.onPageChanged,
  });

  final String localeCode;
  final Rc6RuntimeState runtime;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final action = _dashboardNextAction(runtime, _zh);
    final colors = Theme.of(context).colorScheme;
    final decoration = BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: colors.outlineVariant),
      boxShadow: _HTKWTokens.cardShadow,
    );
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 280;
      if (narrow) {
        return Container(
          key: const Key('dashboard-hero-card'),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: decoration,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _zh ? '知识资产' : 'Knowledge assets',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              _PrimaryProductAction(
                label: action.title,
                icon: action.icon,
                onPressed: () => onPageChanged(_pageIndexById(action.pageId)),
              ),
            ],
          ),
        );
      }
      return Container(
        key: const Key('dashboard-hero-card'),
        padding: const EdgeInsets.fromLTRB(26, 16, 24, 16),
        decoration: decoration,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _zh
                        ? '把资料变成可用的知识资产'
                        : 'Turn materials into usable knowledge assets',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _zh
                        ? '先整理文档库，再构建知识库，最后生成文档、技能与助手。'
                        : 'Organize the library, build a knowledge base, then generate documents, skills, and assistants.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.24,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: 150,
                        child: _PrimaryProductAction(
                          label: action.title,
                          icon: action.icon,
                          onPressed: () =>
                              onPageChanged(_pageIndexById(action.pageId)),
                        ),
                      ),
                      SizedBox(
                        width: 124,
                        child: _DisplayAction(
                          label: _zh ? '查看流程' : 'View flow',
                          icon: Icons.route_outlined,
                          onPressed: () =>
                              onPageChanged(_pageIndexById('document-library')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 22),
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _HTKWTokens.goldSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.dashboard_customize_outlined,
                color: _HTKWTokens.gold,
                size: 28,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _DashboardAssetOverviewCard extends StatelessWidget {
  const _DashboardAssetOverviewCard({
    required this.localeCode,
    required this.workspace,
    required this.runtime,
  });

  final String localeCode;
  final String workspace;
  final Rc6RuntimeState runtime;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final generatedCount = [
      runtime.hasMarkdown,
      runtime.hasExportedDocument,
      runtime.hasSkill,
      runtime.hasAgent,
      runtime.hasAgentDialogue,
      runtime.hasMultiAgentDiscussion,
    ].where((value) => value).length;
    return _FigmaCard(
      keyName: 'dashboard-asset-overview',
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FigmaSectionHeader(
            icon: Icons.space_dashboard_outlined,
            title: _zh ? '工作区资产概览' : 'Workspace Asset Overview',
            subtitle: _zh
                ? '当前工作区：${_displayNameForPath(workspace)}'
                : 'Current workspace: ${_displayNameForPath(workspace)}',
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _MetricStrip(items: [
              _MetricDatum(
                label: _zh ? '配置状态' : 'Configuration',
                value: runtime.sourceCount.toString(),
                detail: runtime.parseReportPath.isEmpty
                    ? (_zh ? '等待整理' : 'Waiting organize')
                    : (_zh ? '已整理' : 'Organized'),
                icon: Icons.library_books_outlined,
              ),
              _MetricDatum(
                label: _zh ? '知识库' : 'Knowledge Bases',
                value: runtime.hasKnowledgeBase ? '1' : '0',
                detail: runtime.hasKnowledgeBase
                    ? (_zh ? '可测试' : 'Ready to test')
                    : (_zh ? '等待生成' : 'Waiting build'),
                icon: Icons.account_tree_outlined,
              ),
              _MetricDatum(
                label: _zh ? '成果' : 'Outputs',
                value: generatedCount.toString(),
                detail: generatedCount == 0
                    ? (_zh ? '等待生成' : 'Waiting output')
                    : (_zh ? '可查看' : 'Available'),
                icon: Icons.folder_copy_outlined,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _DashboardMainFlowCard extends StatelessWidget {
  const _DashboardMainFlowCard({
    required this.localeCode,
    required this.onPageChanged,
  });

  final String localeCode;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final steps = _zh
        ? const [
            _DashboardFlowStep('1', '添加资料', 'document-library'),
            _DashboardFlowStep('2', '整理资料', 'document-library'),
            _DashboardFlowStep('3', '生成知识库', 'knowledge-package-management'),
            _DashboardFlowStep('4', '生成文档 / 技能', 'document-generation'),
            _DashboardFlowStep('5', '创建助手', 'agent-factory-runtime'),
          ]
        : const [
            _DashboardFlowStep('1', 'Add materials', 'document-library'),
            _DashboardFlowStep('2', 'Organize', 'document-library'),
            _DashboardFlowStep('3', 'Build KB', 'knowledge-package-management'),
            _DashboardFlowStep('4', 'Docs / Skills', 'document-generation'),
            _DashboardFlowStep(
                '5', 'Create assistant', 'agent-factory-runtime'),
          ];
    return _FigmaCard(
      keyName: 'dashboard-main-flow',
      padding: const EdgeInsets.fromLTRB(30, 24, 30, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FigmaSectionHeader(
            icon: Icons.route_outlined,
            title: _zh ? '知识供应链进度' : 'Knowledge Workflow Progress',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxWidth < 980;
              if (compact) {
                return _LocalScrollBox(
                  child: Column(
                    children: [
                      for (var index = 0; index < steps.length; index++) ...[
                        _DashboardFlowStepCard(
                          step: steps[index],
                          active: index == 1,
                          onTap: () => onPageChanged(
                              _pageIndexById(steps[index].pageId)),
                        ),
                        if (index < steps.length - 1)
                          const SizedBox(height: _DesktopGrid.gutter),
                      ],
                    ],
                  ),
                );
              }
              return Row(
                children: [
                  for (var index = 0; index < steps.length; index++) ...[
                    Expanded(
                      child: _DashboardFlowStepCard(
                        step: steps[index],
                        active: index == 1,
                        onTap: () =>
                            onPageChanged(_pageIndexById(steps[index].pageId)),
                      ),
                    ),
                    if (index < steps.length - 1) ...[
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.arrow_forward_outlined,
                        color: _HTKWTokens.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                    ],
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DashboardFlowStep {
  const _DashboardFlowStep(this.number, this.title, this.pageId);

  final String number;
  final String title;
  final String pageId;
}

class _DashboardFlowStepCard extends StatelessWidget {
  const _DashboardFlowStepCard({
    required this.step,
    required this.active,
    required this.onTap,
  });

  final _DashboardFlowStep step;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: active ? _HTKWTokens.goldSoft : colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active ? _HTKWTokens.gold : colors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? _HTKWTokens.gold : colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  step.number,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color:
                            active ? colors.surface : colors.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardIsolationNotice extends StatelessWidget {
  const _DashboardIsolationNotice({required this.localeCode});

  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final zh = localeCode == 'zh-CN';
    return Container(
      key: const Key('dashboard-isolation-notice'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: _HTKWTokens.goldSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _HTKWTokens.gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: _HTKWTokens.gold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              zh
                  ? '默认隔离：当前工作区的资料、知识库、技能、助手与记忆不会和其他工作区串联。'
                  : 'Default isolation: materials, knowledge bases, skills, assistants, and memory stay inside the current workspace.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _HTKWTokens.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardRecentTasks extends StatefulWidget {
  const _DashboardRecentTasks({
    required this.localeCode,
    required this.onPageChanged,
  });

  final String localeCode;
  final ValueChanged<int> onPageChanged;

  @override
  State<_DashboardRecentTasks> createState() => _DashboardRecentTasksState();
}

class _DashboardRecentTasksState extends State<_DashboardRecentTasks> {
  bool get _zh => widget.localeCode == 'zh-CN';

  Future<void> _clearTasks(
      Rc6RuntimeController? rc6, List<_DashboardTaskRow> rows) async {
    if (rc6 == null || rc6.state.running || rows.isEmpty) return;
    final confirmed = await _confirmDestructiveAction(
      context,
      title: _zh ? '清空最近任务？' : 'Clear recent tasks?',
      body: _zh
          ? '这会删除当前显示的真实任务记录和对应产物；原始输入文件夹不会被删除。'
          : 'This deletes the currently displayed real task records and artifacts; original source folders are not deleted.',
    );
    if (!confirmed) return;
    for (final row in rows.reversed) {
      await rc6.clearRecentTaskArtifacts(row.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final rows = <_DashboardTaskRow>[
      if (runtime.hasImportedFile)
        _DashboardTaskRow(
          'import',
          _zh ? '导入来源文件' : 'Import sources',
          _zh ? '文档库' : 'Document Library',
          _zh ? '${runtime.sourceCount} 个文件' : '${runtime.sourceCount} files',
          Icons.upload_file_outlined,
          'document-library',
        ),
      if (runtime.parseReportPath.isNotEmpty)
        _DashboardTaskRow(
          'parse',
          _zh ? '整理资料' : 'Organize materials',
          _zh ? '文档库' : 'Document Library',
          _zh ? '整理结果已生成' : 'organized result ready',
          Icons.document_scanner_outlined,
          'document-library',
        ),
      if (runtime.hasKnowledgeBase)
        _DashboardTaskRow(
          'kb',
          _zh ? '生成知识库' : 'Generate knowledge base',
          _zh ? '知识库' : 'Knowledge',
          _zh ? '可测试' : 'ready to test',
          Icons.storage_outlined,
          'knowledge-package-management',
        ),
      if (runtime.searchStatus == Rc6SearchStatus.success)
        _DashboardTaskRow(
          'search',
          _zh ? '测试知识库' : 'Test knowledge base',
          _zh ? '测试知识库' : 'Knowledge Test',
          _zh
              ? '${runtime.searchResults.length} 条结果'
              : '${runtime.searchResults.length} results',
          Icons.manage_search_outlined,
          'retrieval-verification',
        ),
      if (runtime.hasMarkdown)
        _DashboardTaskRow(
          'doc',
          _zh ? '生成文档' : 'Generate document',
          _zh ? '文档生成' : 'Generation',
          runtime.hasExportedDocument
              ? (_zh ? '已导出' : 'exported')
              : (_zh ? '待导出' : 'waiting export'),
          Icons.description_outlined,
          'document-generation',
        ),
      if (runtime.hasSkill)
        _DashboardTaskRow(
          'skill',
          _zh ? '生成技能' : 'Generate skill',
          _zh ? '技能生成' : 'Skill Builder',
          _displayNameForPath(runtime.skillPath),
          Icons.extension_outlined,
          'skill-factory',
        ),
      if (runtime.hasAgent)
        _DashboardTaskRow(
          'agent',
          _zh ? '创建助手' : 'Create assistant',
          _zh ? '我的助手' : 'My Assistants',
          runtime.hasAgentDialogueExport
              ? (_zh ? '已导出对话' : 'dialogue exported')
              : runtime.hasAgentDialogue
                  ? (_zh ? '已对话' : 'chat saved')
                  : runtime.hasMultiAgentDiscussion
                      ? (_zh ? '已讨论' : 'discussion saved')
                      : (_zh ? '已生成' : 'generated'),
          Icons.smart_toy_outlined,
          'agent-factory-runtime',
        ),
    ];
    final visibleRows = rows;
    return _FigmaCard(
      keyName: 'dashboard-next-actions',
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 42,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: _HTKWTokens.softSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _HTKWTokens.border),
            ),
            child: Text(
              _zh ? '继续任务' : 'Continue Tasks',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: visibleRows.isEmpty
                ? Center(
                    child: SizedBox(
                      width: 180,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _zh ? '下一步' : 'Next Step',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),
                          _PrimaryProductAction(
                            label: _zh ? '添加资料' : 'Add materials',
                            icon: Icons.upload_file_outlined,
                            onPressed: () => widget.onPageChanged(
                                _pageIndexById('document-library')),
                          ),
                        ],
                      ),
                    ),
                  )
                : _LocalScrollBox(
                    child: Column(
                      children: [
                        for (final row in visibleRows) ...[
                          _DashboardCompactRow(
                            title: row.title,
                            detail: row.status,
                            onTap: () => widget
                                .onPageChanged(_pageIndexById(row.pageId)),
                          ),
                          if (row != visibleRows.last)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
          ),
          SizedBox(
            height: 34,
            child: _DisplayAction(
              label: _zh ? '清空最近任务' : 'Clear recent tasks',
              icon: Icons.delete_sweep_outlined,
              onPressed: visibleRows.isEmpty
                  ? null
                  : () => _clearTasks(rc6, visibleRows),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardRecentActivity extends StatelessWidget {
  const _DashboardRecentActivity({
    required this.localeCode,
    required this.workflowV2Evidence,
    required this.parserBackends,
  });

  final String localeCode;
  final P1WorkflowEvidence workflowV2Evidence;
  final ParserBackendMatrix parserBackends;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final runtime =
        _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
    final rows = [
      if (runtime.hasImportedFile)
        _DashboardActivityRow(
          _zh ? '新增资料' : 'Materials added',
          _zh ? '${runtime.sourceCount} 个来源' : '${runtime.sourceCount} sources',
        ),
      if (runtime.parseReportPath.isNotEmpty)
        _DashboardActivityRow(
          _zh ? '资料已整理' : 'Materials organized',
          _zh ? '${runtime.chunkCount} 个片段' : '${runtime.chunkCount} chunks',
        ),
      if (runtime.hasKnowledgeBase)
        _DashboardActivityRow(
          _zh ? '知识库已更新' : 'Knowledge base updated',
          _zh ? '本地可测试' : 'local test ready',
        ),
      if (runtime.hasMarkdown)
        _DashboardActivityRow(
          _zh ? '文档已生成' : 'Document generated',
          _displayNameForPath(runtime.generatedMarkdownPath),
        ),
      if (runtime.hasAgent || runtime.hasMultiAgentDiscussion)
        _DashboardActivityRow(
          _zh ? '助手有新记录' : 'Assistant activity',
          runtime.hasMultiAgentDiscussion
              ? (_zh ? '讨论报告' : 'discussion report')
              : (_zh ? '对话记录' : 'dialogue record'),
        ),
    ];
    final fallback = [
      _DashboardActivityRow(
        _zh ? '配置状态' : 'Configuration',
        _zh ? '本地模式' : 'local mode',
      ),
      _DashboardActivityRow(
        _zh ? '技能' : 'Skills',
        runtime.hasSkill
            ? (_zh ? '已生成' : 'generated')
            : (_zh ? '等待生成' : 'waiting'),
      ),
      _DashboardActivityRow(
        _zh ? '助手' : 'Assistants',
        runtime.hasAgent
            ? (_zh ? '已创建' : 'created')
            : (_zh ? '等待创建' : 'waiting'),
      ),
      _DashboardActivityRow(
        _zh ? '助手对话' : 'Assistant dialogue',
        runtime.hasAgentDialogue
            ? (_zh ? '已保存' : 'saved')
            : (_zh ? '等待对话' : 'waiting'),
      ),
      _DashboardActivityRow(
        _zh ? '多个助手讨论' : 'Assistant discussion',
        runtime.hasMultiAgentDiscussion
            ? (_zh ? '已生成' : 'generated')
            : (_zh ? '等待讨论' : 'waiting'),
      ),
    ];
    return _FigmaCard(
      keyName: 'dashboard-recent-activity',
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: _HTKWTokens.softSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _HTKWTokens.border),
            ),
            child: Text(
              _zh ? '最近动态' : 'Recent Activity',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _LocalScrollBox(
              child: Column(
                children: [
                  for (final row in (rows.isEmpty ? fallback : rows).take(5))
                    _DashboardCompactRow(title: row.title, detail: row.detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardActivityRow {
  const _DashboardActivityRow(this.title, this.detail);

  final String title;
  final String detail;
}

class _DashboardCompactRow extends StatelessWidget {
  const _DashboardCompactRow({
    required this.title,
    required this.detail,
    this.onTap,
  });

  final String title;
  final String detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final child = Container(
      height: 46,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    )),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: child,
    );
  }
}

_DashboardActionRow _dashboardNextAction(Rc6RuntimeState runtime, bool zh) {
  if (!runtime.hasImportedFile) {
    return _DashboardActionRow(
      zh ? '添加资料' : 'Add materials',
      zh ? '当前工作区还没有资料。' : 'The current workspace has no materials yet.',
      Icons.file_upload_outlined,
      'document-library',
      false,
    );
  }
  if (runtime.parseReportPath.isEmpty) {
    return _DashboardActionRow(
      zh ? '整理资料' : 'Organize materials',
      zh
          ? '已有资料，下一步需要整理后才能生成知识库。'
          : 'Materials exist; organize them before building a knowledge base.',
      Icons.document_scanner_outlined,
      'document-library',
      false,
    );
  }
  if (!runtime.hasKnowledgeBase) {
    return _DashboardActionRow(
      zh ? '生成知识库' : 'Generate knowledge base',
      zh
          ? '资料已整理，可以从文档库生成知识库。'
          : 'Materials are organized and ready for a knowledge base.',
      Icons.account_tree_outlined,
      'knowledge-package-management',
      false,
    );
  }
  if (runtime.searchStatus != Rc6SearchStatus.success) {
    return _DashboardActionRow(
      zh ? '测试知识库' : 'Test knowledge base',
      zh
          ? '知识库已生成，建议先用问题验证证据和引用。'
          : 'Knowledge base exists; test evidence and citations next.',
      Icons.manage_search_outlined,
      'retrieval-verification',
      false,
    );
  }
  if (!runtime.hasMarkdown) {
    return _DashboardActionRow(
      zh ? '生成文档' : 'Generate document',
      zh
          ? '知识库已通过测试，可以生成文档草稿。'
          : 'The knowledge base has test results; generate a document draft.',
      Icons.edit_document,
      'document-generation',
      false,
    );
  }
  if (runtime.hasExportedDocument || runtime.hasSkill || runtime.hasAgent) {
    return _DashboardActionRow(
      zh ? '查看成果' : 'View outputs',
      zh
          ? '已有可查看成果，可以进入成果中心导出或追溯。'
          : 'Outputs are available for preview, export, or trace.',
      Icons.folder_copy_outlined,
      'artifact-center',
      true,
    );
  }
  return _DashboardActionRow(
    zh ? '生成技能' : 'Generate skill',
    zh
        ? '已有文档草稿，可以继续生成技能或创建助手。'
        : 'A document draft exists; continue with skills or assistants.',
    Icons.extension_outlined,
    'skill-factory',
    false,
  );
}

class _DashboardActionRow {
  const _DashboardActionRow(
      this.title, this.detail, this.icon, this.pageId, this.done);

  final String title;
  final String detail;
  final IconData icon;
  final String pageId;
  final bool done;
}

class _DashboardTaskRow {
  const _DashboardTaskRow(
      this.id, this.title, this.type, this.status, this.icon, this.pageId);

  final String id;
  final String title;
  final String type;
  final String status;
  final IconData icon;
  final String pageId;
}

class _DashboardArtifactOverview extends StatelessWidget {
  const _DashboardArtifactOverview({
    required this.localeCode,
    required this.onPageChanged,
  });

  final String localeCode;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final runtime =
        _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
    final rows = [
      if (runtime.hasMarkdown)
        _DashboardActivityRow(
          _zh ? '生成文档' : 'Generated document',
          _zh ? '文档' : 'Doc',
        ),
      if (runtime.hasExportedDocument)
        _DashboardActivityRow(
          _zh ? '导出文档' : 'Exported document',
          _zh ? '导出' : 'Export',
        ),
      if (runtime.hasSkill)
        _DashboardActivityRow(
          _zh ? '知识技能' : 'Knowledge skill',
          'Skill',
        ),
      if (runtime.hasAgent)
        _DashboardActivityRow(
          _zh ? '知识助手' : 'Knowledge assistant',
          _zh ? '助手' : 'Assistant',
        ),
      if (runtime.hasMultiAgentDiscussion)
        _DashboardActivityRow(
          _zh ? '助手讨论报告' : 'Assistant discussion',
          _zh ? '讨论' : 'Discussion',
        ),
    ];
    return _FigmaCard(
      keyName: 'dashboard-artifact-overview',
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: _HTKWTokens.softSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _HTKWTokens.border),
            ),
            child: Text(
              _zh ? '最近成果' : 'Recent Outputs',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _LocalScrollBox(
              child: Column(
                children: [
                  for (final row in (rows.isEmpty
                          ? [
                              _DashboardActivityRow(
                                _zh ? '等待生成成果' : 'Waiting output',
                                _zh ? '先生成文档' : 'generate doc',
                              )
                            ]
                          : rows)
                      .take(3))
                    _DashboardCompactRow(
                      title: row.title,
                      detail: row.detail,
                      onTap: () =>
                          onPageChanged(_pageIndexById('artifact-center')),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 34,
            child: _DisplayAction(
              label: _zh ? '查看成果' : 'View outputs',
              icon: Icons.folder_copy_outlined,
              onPressed: () => onPageChanged(_pageIndexById('artifact-center')),
            ),
          ),
        ],
      ),
    );
  }
}
