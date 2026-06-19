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
    return Column(
      key: const Key('desktop-dashboard-surface'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DashboardMetricGrid(
          localeCode: localeCode,
          contracts: contracts,
          workflowV2Evidence: workflowV2Evidence,
          parserBackends: parserBackends,
          onPageChanged: onPageChanged,
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        LayoutBuilder(builder: (context, constraints) {
          final threeColumns = constraints.maxWidth >= 1320;
          final main = _ProductColumn(
            children: [
              _EqualHeightRow(
                height: 316,
                children: [
                  _DashboardRecentTasks(
                    localeCode: localeCode,
                    onPageChanged: onPageChanged,
                  ),
                  _DashboardNextActions(
                      localeCode: localeCode, onPageChanged: onPageChanged),
                ],
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              _DashboardReportSummary(
                localeCode: localeCode,
                workflowV2Evidence: workflowV2Evidence,
                parserBackends: parserBackends,
              ),
            ],
          );
          final side = _ProductColumn(
            children: [
              _DashboardArtifactOverview(
                localeCode: localeCode,
                onPageChanged: onPageChanged,
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              _DashboardAuthorizationCard(
                localeCode: localeCode,
                onPageChanged: onPageChanged,
              ),
            ],
          );
          if (!threeColumns) {
            return Column(children: [
              main,
              const SizedBox(height: _DesktopGrid.gutter),
              side,
            ]);
          }
          return _Grid12Row(cells: [
            _Grid12Cell(span: 9, child: main),
            _Grid12Cell(span: 3, child: side),
          ]);
        }),
      ],
    );
  }
}

class _DashboardMetricGrid extends StatelessWidget {
  const _DashboardMetricGrid({
    required this.localeCode,
    required this.contracts,
    required this.workflowV2Evidence,
    required this.parserBackends,
    required this.onPageChanged,
  });

  final String localeCode;
  final WorkbenchContracts contracts;
  final P1WorkflowEvidence workflowV2Evidence;
  final ParserBackendMatrix parserBackends;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final metrics = [
      _DashboardMetricData(
        icon: Icons.inventory_2_outlined,
        label: _zh ? '来源文档' : 'Source Docs',
        value: runtime.sourceCount.toString(),
        detail: runtime.hasImportedFile
            ? (_zh ? '已进入文档库' : 'in library')
            : (_zh ? '等待导入' : 'waiting import'),
        pageId: 'document-library',
      ),
      _DashboardMetricData(
        icon: Icons.storage_outlined,
        label: _zh ? '知识库' : 'Knowledge Base',
        value: runtime.hasKnowledgeBase ? '1' : '0',
        detail: runtime.hasKnowledgeBase
            ? '${runtime.chunkCount} chunks'
            : (_zh ? '等待构建' : 'waiting build'),
        pageId: 'knowledge-package-management',
      ),
      _DashboardMetricData(
        icon: Icons.manage_search_outlined,
        label: _zh ? '检索结果' : 'Search Results',
        value: runtime.searchResults.length.toString(),
        detail: runtime.searchStatus == Rc6SearchStatus.success
            ? (_zh ? '来自所选知识库' : 'from selected KB')
            : (_zh ? '等待查询' : 'waiting query'),
        pageId: 'retrieval-verification',
      ),
      _DashboardMetricData(
        icon: Icons.description_outlined,
        label: _zh ? '生成文档' : 'Generated Docs',
        value: runtime.hasMarkdown ? '1' : '0',
        detail: runtime.hasExportedDocument
            ? (_zh ? '已导出' : 'exported')
            : runtime.hasMarkdown
                ? (_zh ? '已生成，待导出' : 'generated, export next')
                : (_zh ? '尚未生成' : 'not generated'),
        pageId: 'document-generation',
      ),
      _DashboardMetricData(
        icon: Icons.route_outlined,
        label: _zh ? '下一步' : 'Next Step',
        value: _zh ? '继续' : 'Continue',
        detail: _dashboardNextStep(runtime, _zh),
        pageId: _dashboardNextPageId(runtime),
      ),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 1180
          ? 5
          : width >= 900
              ? 3
              : width >= 620
                  ? 2
                  : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: metrics.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: _DesktopGrid.gutter,
          crossAxisSpacing: _DesktopGrid.gutter,
          mainAxisExtent: 150,
        ),
        itemBuilder: (context, index) => _DashboardMetricCard(
          metrics[index],
          onTap: () => onPageChanged(_pageIndexById(metrics[index].pageId)),
        ),
      );
    });
  }
}

String _dashboardNextPageId(Rc6RuntimeState runtime) {
  if (!runtime.hasImportedFile || runtime.parseReportPath.isEmpty) {
    return 'document-library';
  }
  if (!runtime.hasKnowledgeBase) return 'knowledge-package-management';
  if (runtime.searchStatus != Rc6SearchStatus.success) {
    return 'retrieval-verification';
  }
  return 'document-generation';
}

String _dashboardNextStep(Rc6RuntimeState runtime, bool zh) {
  if (!runtime.hasImportedFile) return zh ? '导入文件夹' : 'import folder';
  if (runtime.parseReportPath.isEmpty) return zh ? '解析/OCR' : 'parse/OCR';
  if (!runtime.hasKnowledgeBase) return zh ? '构建知识库' : 'build KB';
  if (runtime.searchStatus != Rc6SearchStatus.success) {
    return zh ? '检索验证' : 'search';
  }
  if (!runtime.hasMarkdown) return zh ? '生成文档' : 'generate doc';
  if (!runtime.hasExportedDocument) return zh ? '导出文件' : 'export file';
  return zh ? '产物可复用' : 'artifacts reusable';
}

class _DashboardMetricData {
  const _DashboardMetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.pageId,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final String pageId;
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard(this.metric, {required this.onTap});

  final _DashboardMetricData metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(_DesktopGrid.panelRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_DesktopGrid.panelRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(_DesktopGrid.panelPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_DesktopGrid.panelRadius),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(metric.icon, size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(metric.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.12,
                            )),
                  ),
                ],
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(metric.value,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1.08,
                              )),
                      const SizedBox(height: 5),
                      Text(metric.detail,
                          maxLines: 1,
                          softWrap: true,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
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

  Future<void> _deleteTask(
      Rc6RuntimeController? rc6, _DashboardTaskRow row) async {
    if (rc6 == null || rc6.state.running) return;
    final confirmed = await _confirmDestructiveAction(
      context,
      title: _zh ? '删除任务记录？' : 'Delete task record?',
      body: _zh
          ? '这会删除“${row.title}”对应的真实工作区记录和下游产物；原始输入文件夹不会被删除。'
          : 'This deletes the real workspace records and downstream artifacts for "${row.title}"; original source folders are not deleted.',
    );
    if (!confirmed) return;
    await rc6.clearRecentTaskArtifacts(row.id);
  }

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
          _zh ? '解析 / OCR / Chunking' : 'Parse / OCR / Chunking',
          _zh ? '文档库' : 'Document Library',
          _zh ? '解析报告已生成' : 'parse report ready',
          Icons.document_scanner_outlined,
          'document-library',
        ),
      if (runtime.hasKnowledgeBase)
        _DashboardTaskRow(
          'kb',
          _zh ? '构建知识库' : 'Build knowledge base',
          _zh ? '知识库' : 'Knowledge',
          '${runtime.chunkCount} chunks',
          Icons.storage_outlined,
          'knowledge-package-management',
        ),
      if (runtime.searchStatus == Rc6SearchStatus.success)
        _DashboardTaskRow(
          'search',
          _zh ? '检索验证' : 'Search and verify',
          _zh ? '检索' : 'Retrieval',
          _zh
              ? '${runtime.searchResults.length} 条结果'
              : '${runtime.searchResults.length} results',
          Icons.manage_search_outlined,
          'retrieval-verification',
        ),
      if (runtime.hasMarkdown)
        _DashboardTaskRow(
          'doc',
          _zh ? '生成 Markdown 文档' : 'Generate Markdown document',
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
          _zh ? '生成 Skill' : 'Generate Skill',
          _zh ? 'Skill 工厂' : 'Skill Factory',
          _displayNameForPath(runtime.skillPath),
          Icons.extension_outlined,
          'skill-factory',
        ),
      if (runtime.hasAgent)
        _DashboardTaskRow(
          'agent',
          _zh ? '创建 Agent' : 'Create Agent',
          _zh ? 'Agent 工作台' : 'Agent Workbench',
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
    return _FillProductPanel(
      keyName: 'dashboard-recent-tasks',
      icon: Icons.list_alt_outlined,
      title: _zh ? '最近任务' : 'Recent Tasks',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: visibleRows.isEmpty
                ? Center(
                    child: Text(
                      _zh
                          ? '暂无真实任务。请从“文档库导入资料”开始。'
                          : 'No real tasks yet. Start from the Document Library import.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  )
                : _LocalScrollBox(
                    child: Column(
                      children: [
                        for (final row in visibleRows) ...[
                          _DashboardTaskTile(
                            row: row,
                            onOpen: () => widget
                                .onPageChanged(_pageIndexById(row.pageId)),
                            onDelete: () => _deleteTask(rc6, row),
                          ),
                          if (row != visibleRows.last)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: visibleRows.isEmpty
                      ? null
                      : () => _clearTasks(rc6, visibleRows),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(_zh ? '清空最近任务' : 'Clear recent tasks'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardNextActions extends StatelessWidget {
  const _DashboardNextActions({
    required this.localeCode,
    required this.onPageChanged,
  });

  final String localeCode;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final actions = <_DashboardActionRow>[
      _DashboardActionRow(
        _zh ? '文档库导入资料' : 'Import sources to document library',
        _dashboardImportActionLabel(runtime, _zh),
        Icons.file_upload_outlined,
        'document-library',
        runtime.hasImportedFile && runtime.parseReportPath.isNotEmpty,
      ),
      _DashboardActionRow(
        _zh ? '构建知识库' : 'Build knowledge base',
        runtime.hasKnowledgeBase
            ? (_zh
                ? '${runtime.chunkCount} chunks 已生成'
                : '${runtime.chunkCount} chunks ready')
            : (_zh ? '从文档库选择来源后构建' : 'Select sources from library and build'),
        Icons.storage_outlined,
        'knowledge-package-management',
        runtime.hasKnowledgeBase,
      ),
      _DashboardActionRow(
        _zh ? '检索验证' : 'Search and verify',
        runtime.searchStatus == Rc6SearchStatus.success
            ? (_zh
                ? '${runtime.searchResults.length} 条真实结果'
                : '${runtime.searchResults.length} real results')
            : (_zh ? '选择知识库并查询证据' : 'Choose KB and query evidence'),
        Icons.manage_search_outlined,
        'retrieval-verification',
        runtime.searchStatus == Rc6SearchStatus.success,
      ),
      _DashboardActionRow(
        _zh ? '生成并导出文档' : 'Generate and export documents',
        runtime.hasExportedDocument
            ? (_zh ? '导出文件可追踪' : 'Exported file is traceable')
            : (_zh ? '选择类型、格式和引用策略' : 'Choose type, format, and citations'),
        Icons.edit_document,
        'document-generation',
        runtime.hasExportedDocument,
      ),
    ];
    return _FillProductPanel(
      keyName: 'dashboard-next-actions',
      icon: Icons.route_outlined,
      title: _zh ? '下一步行动' : 'Next Actions',
      child: _LocalScrollBox(
        child: Column(
          children: [
            for (final action in actions) ...[
              _DashboardActionTile(
                action: action,
                onTap: () => onPageChanged(_pageIndexById(action.pageId)),
              ),
              if (action != actions.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

String _dashboardImportActionLabel(Rc6RuntimeState runtime, bool zh) {
  if (!runtime.hasImportedFile) {
    return zh ? '选择来源并导入队列' : 'Choose source and import queue';
  }
  if (runtime.parseReportPath.isEmpty) {
    return zh ? '继续解析 / OCR / 分块' : 'Continue parse / OCR / chunk';
  }
  return zh ? '解析报告已生成' : 'Parse report ready';
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

class _DashboardActionTile extends StatelessWidget {
  const _DashboardActionTile({required this.action, required this.onTap});

  final _DashboardActionRow action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tone = action.done ? _StatusTone.success : _StatusTone.neutral;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(action.icon, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            )),
                    const SizedBox(height: 2),
                    Text(action.detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            )),
                  ],
                ),
              ),
              _StatusBadge(
                label: action.done ? 'OK' : 'Open',
                tone: tone,
                icon: action.done
                    ? Icons.check_circle_outline
                    : Icons.open_in_new_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
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

class _DashboardTaskTile extends StatelessWidget {
  const _DashboardTaskTile({
    required this.row,
    required this.onOpen,
    required this.onDelete,
  });

  final _DashboardTaskRow row;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(row.icon, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            )),
                    const SizedBox(height: 2),
                    Text('${row.type} · ${row.status}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            )),
                  ],
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardReportSummary extends StatelessWidget {
  const _DashboardReportSummary({
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
    return _ProductPanel(
      keyName: 'dashboard-report-summary',
      icon: Icons.analytics_outlined,
      title: _zh ? '知识供应链进度' : 'Knowledge Supply Chain',
      children: [
        _ProductTable(
          columns: _zh
              ? ['环节', '状态', '用户可见结果', '下一步']
              : ['Step', 'Status', 'User result', 'Next'],
          rows: _zh
              ? [
                  [
                    '文档库导入与解析',
                    '可操作',
                    'source_manifest.json / parse_report.json',
                    '进入文档库'
                  ],
                  [
                    '知识库构建',
                    '可操作',
                    'chunks / cards / qa_pairs / manifest',
                    '检索验证'
                  ],
                  ['文档生成', '可操作', 'Markdown 草稿与导出文件', '进入产物中心'],
                ]
              : [
                  [
                    'Import and parsing',
                    'Actionable',
                    'source_manifest.json / parse_report.json',
                    'Open library'
                  ],
                  [
                    'Knowledge build',
                    'Actionable',
                    'chunks / cards / qa_pairs / manifest',
                    'Search'
                  ],
                  [
                    'Document generation',
                    'Actionable',
                    'Markdown draft and export file',
                    'Open artifacts'
                  ],
                ],
        ),
      ],
    );
  }
}

class _DashboardAuthorizationCard extends StatelessWidget {
  const _DashboardAuthorizationCard({
    required this.localeCode,
    required this.onPageChanged,
  });

  final String localeCode;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'dashboard-authorization',
      icon: Icons.admin_panel_settings_outlined,
      title: _zh ? '配置状态' : 'Configuration Status',
      gap: true,
      children: [
        _ProductTable(
          columns: _zh
              ? ['能力', '当前处理', '用户动作']
              : ['Capability', 'Handling', 'User action'],
          rows: _zh
              ? [
                  ['外部事实验证', '需要配置', '在运行设置中配置联网 Provider'],
                  ['Redis 记忆缓存', '可选配置', '保存配置并测试连接'],
                  ['Qdrant 向量库', '可选配置', '保存配置并测试连接'],
                ]
              : [
                  [
                    'External fact checking',
                    'Needs configuration',
                    'Configure network Provider in Settings'
                  ],
                  [
                    'Redis memory cache',
                    'Optional configuration',
                    'Save config and test connection'
                  ],
                  [
                    'Qdrant vector DB',
                    'Optional configuration',
                    'Save config and test connection'
                  ],
                ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _PrimaryProductAction(
          label: _zh
              ? '打开设置配置 Provider / Redis / Qdrant'
              : 'Open Settings for Provider / Redis / Qdrant',
          icon: Icons.settings_outlined,
          onPressed: () => onPageChanged(_pageIndexById('workspace')),
        ),
      ],
    );
  }
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
    return _ProductPanel(
      keyName: 'dashboard-artifact-overview',
      icon: Icons.folder_copy_outlined,
      title: _zh ? '生成产物' : 'Generated Artifacts',
      gap: true,
      children: [
        _ProductTable(
          columns:
              _zh ? ['产物', '状态', '位置'] : ['Artifact', 'Status', 'Location'],
          rows: _zh
              ? [
                  [
                    'source_manifest.json',
                    runtime.sourceManifestPath.isEmpty ? '未生成' : '已生成',
                    _displayNameForPath(runtime.sourceManifestPath)
                  ],
                  [
                    'parse_report.json',
                    runtime.parseReportPath.isEmpty ? '未生成' : '已生成',
                    _displayNameForPath(runtime.parseReportPath)
                  ],
                  [
                    'kb/manifest.json',
                    runtime.kbManifestPath.isEmpty ? '未生成' : '已生成',
                    _displayNameForPath(runtime.kbManifestPath)
                  ],
                  [
                    'reading_notes_export.md',
                    runtime.exportedDocumentPath.isEmpty ? '未导出' : '已导出',
                    _displayNameForPath(runtime.exportedDocumentPath)
                  ],
                  [
                    'SKILL.md',
                    runtime.hasSkill ? '已生成' : '未生成',
                    _displayNameForPath(runtime.primarySkillPath)
                  ],
                  [
                    'agent_manifest.json',
                    runtime.hasAgent ? '已生成' : '未生成',
                    _displayNameForPath(runtime.primaryAgentManifestPath)
                  ],
                  [
                    'agent_dialogue.md',
                    runtime.hasAgentDialogue ? '已保存' : '未生成',
                    _displayNameForPath(runtime.agentDialoguePath)
                  ],
                  [
                    'multi_agent_discussion.md',
                    runtime.hasMultiAgentDiscussion ? '已生成' : '未生成',
                    _displayNameForPath(runtime.multiAgentDiscussionPath)
                  ],
                  [
                    '知识生产链路',
                    runtime.hasPrdP0Evidence ? '已生成' : '未生成',
                    _displayNameForPath(runtime.prdP0EvidencePath)
                  ],
                ]
              : [
                  [
                    'source_manifest.json',
                    runtime.sourceManifestPath.isEmpty
                        ? 'Not generated'
                        : 'Generated',
                    _displayNameForPath(runtime.sourceManifestPath)
                  ],
                  [
                    'parse_report.json',
                    runtime.parseReportPath.isEmpty
                        ? 'Not generated'
                        : 'Generated',
                    _displayNameForPath(runtime.parseReportPath)
                  ],
                  [
                    'kb/manifest.json',
                    runtime.kbManifestPath.isEmpty
                        ? 'Not generated'
                        : 'Generated',
                    _displayNameForPath(runtime.kbManifestPath)
                  ],
                  [
                    'reading_notes_export.md',
                    runtime.exportedDocumentPath.isEmpty
                        ? 'Not exported'
                        : 'Exported',
                    _displayNameForPath(runtime.exportedDocumentPath)
                  ],
                  [
                    'SKILL.md',
                    runtime.hasSkill ? 'Generated' : 'Not generated',
                    _displayNameForPath(runtime.primarySkillPath)
                  ],
                  [
                    'agent_manifest.json',
                    runtime.hasAgent ? 'Generated' : 'Not generated',
                    _displayNameForPath(runtime.primaryAgentManifestPath)
                  ],
                  [
                    'agent_dialogue.md',
                    runtime.hasAgentDialogue ? 'Saved' : 'Not generated',
                    _displayNameForPath(runtime.agentDialoguePath)
                  ],
                  [
                    'multi_agent_discussion.md',
                    runtime.hasMultiAgentDiscussion
                        ? 'Generated'
                        : 'Not generated',
                    _displayNameForPath(runtime.multiAgentDiscussionPath)
                  ],
                  [
                    'Knowledge production flow',
                    runtime.hasPrdP0Evidence ? 'Generated' : 'Not generated',
                    _displayNameForPath(runtime.prdP0EvidencePath)
                  ],
                ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _EqualActionRow(children: [
          _DisplayAction(
            label: _zh ? '查看文档库' : 'Open document library',
            icon: Icons.library_books_outlined,
            onPressed: () => onPageChanged(_pageIndexById('document-library')),
          ),
          _DisplayAction(
            label: _zh ? '查看导出文件' : 'Open generated documents',
            icon: Icons.file_download_outlined,
            onPressed: () =>
                onPageChanged(_pageIndexById('document-generation')),
          ),
          _DisplayAction(
            label: _zh ? '查看 Agent / A2A' : 'Open Agent / A2A',
            icon: Icons.groups_2_outlined,
            onPressed: runtime.hasPrdP0Evidence
                ? () => onPageChanged(_pageIndexById('agent-factory-runtime'))
                : null,
          ),
        ]),
      ],
    );
  }
}
