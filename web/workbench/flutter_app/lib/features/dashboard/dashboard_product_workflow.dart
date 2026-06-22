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
            ? (_zh ? '已生成' : 'generated')
            : (_zh ? '等待构建' : 'waiting build'),
        pageId: 'knowledge-package-management',
      ),
      _DashboardMetricData(
        icon: Icons.manage_search_outlined,
        label: _zh ? '测试结果' : 'Test Results',
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
        label: _zh ? '工作状态' : 'Work Status',
        value: _dashboardCurrentStage(runtime, _zh),
        detail: _dashboardCurrentStageDetail(runtime, _zh),
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

String _dashboardCurrentStage(Rc6RuntimeState runtime, bool zh) {
  if (!runtime.hasImportedFile) return zh ? '文档库' : 'Library';
  if (runtime.parseReportPath.isEmpty) return zh ? '整理资料' : 'Organizing';
  if (!runtime.hasKnowledgeBase) return zh ? '知识库' : 'Knowledge';
  if (runtime.searchStatus != Rc6SearchStatus.success) {
    return zh ? '测试' : 'Test';
  }
  if (!runtime.hasMarkdown) return zh ? '文档' : 'Docs';
  if (!runtime.hasExportedDocument) return zh ? '待导出' : 'Export';
  return zh ? '可交付' : 'Ready';
}

String _dashboardCurrentStageDetail(Rc6RuntimeState runtime, bool zh) {
  if (!runtime.hasImportedFile) return zh ? '等待来源文档' : 'waiting source docs';
  if (runtime.parseReportPath.isEmpty) {
    return zh ? '等待资料整理' : 'waiting organization';
  }
  if (!runtime.hasKnowledgeBase) return zh ? '等待知识库' : 'waiting knowledge base';
  if (runtime.searchStatus != Rc6SearchStatus.success) {
    return zh ? '等待证据记录' : 'waiting evidence record';
  }
  if (!runtime.hasMarkdown) return zh ? '等待文档产物' : 'waiting document artifact';
  if (!runtime.hasExportedDocument) {
    return zh ? 'Markdown 已生成' : 'Markdown generated';
  }
  return zh ? '导出文件已生成' : 'exported file ready';
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
    final action = _dashboardNextAction(runtime, _zh);
    return _FillProductPanel(
      keyName: 'dashboard-next-actions',
      icon: Icons.route_outlined,
      title: _zh ? '下一步' : 'Next Step',
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PrimaryProductAction(
              label: action.title,
              icon: action.icon,
              onPressed: () => onPageChanged(_pageIndexById(action.pageId)),
            ),
            const SizedBox(height: 8),
            _RuntimeFeedbackBanner(
              title: _zh ? '当前状态' : 'Current status',
              detail: action.detail,
              tone: action.done ? _StatusTone.success : _StatusTone.neutral,
              icon:
                  action.done ? Icons.check_circle_outline : Icons.info_outline,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _LocalScrollBox(
                child: _ProductTable(
                  columns: _zh ? ['环节', '状态'] : ['Step', 'Status'],
                  rows: _zh
                      ? [
                          ['资料', runtime.hasImportedFile ? '已添加' : '需要先添加资料'],
                          [
                            '整理',
                            runtime.parseReportPath.isNotEmpty ? '已整理' : '待整理'
                          ],
                          ['知识库', runtime.hasKnowledgeBase ? '已生成' : '未生成'],
                          [
                            '文档',
                            runtime.hasMarkdown
                                ? (runtime.hasExportedDocument ? '可导出' : '已生成')
                                : '未生成'
                          ],
                        ]
                      : [
                          [
                            'Materials',
                            runtime.hasImportedFile
                                ? 'Added'
                                : 'Add materials first'
                          ],
                          [
                            'Organizing',
                            runtime.parseReportPath.isNotEmpty
                                ? 'Organized'
                                : 'Waiting'
                          ],
                          [
                            'Knowledge Base',
                            runtime.hasKnowledgeBase
                                ? 'Generated'
                                : 'Not generated'
                          ],
                          [
                            'Document',
                            runtime.hasMarkdown
                                ? (runtime.hasExportedDocument
                                    ? 'Exportable'
                                    : 'Generated')
                                : 'Not generated'
                          ],
                        ],
                ),
              ),
            ),
          ],
        ),
      ),
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
              ? ['环节', '状态', '用户可见结果', '入口']
              : ['Step', 'Status', 'User result', 'Entry'],
          rows: _zh
              ? [
                  ['添加与整理资料', '可操作', '来源文档 / 整理结果', '进入文档库'],
                  ['生成知识库', '可操作', '知识库 / 质量记录', '测试知识库'],
                  ['测试知识库', '可操作', '证据片段 / 引用 / 测试记录', '生成文档'],
                  ['文档生成', '可操作', '文档草稿与导出文件', '生成技能'],
                  ['技能生成', '可操作', '技能草稿 / 检查记录 / 绑定清单', '进入我的助手'],
                  ['我的助手', '可操作', '助手对话 / 多助手讨论记录', '进入成果中心'],
                ]
              : [
                  [
                    'Import and parsing',
                    'Actionable',
                    'Source documents / parse results',
                    'Open library'
                  ],
                  [
                    'Knowledge build',
                    'Actionable',
                    'Knowledge Base / index / quality records',
                    'Search'
                  ],
                  [
                    'Retrieval and verification',
                    'Actionable',
                    'Evidence snippets / citations / validation report',
                    'Generate documents'
                  ],
                  [
                    'Document generation',
                    'Actionable',
                    'Markdown draft and export file',
                    'Generate Skill'
                  ],
                  [
                    'Skill Builder',
                    'Actionable',
                    'SKILL.md / validation report / binding manifest',
                    'Open My Assistants'
                  ],
                  [
                    'My Assistants',
                    'Actionable',
                    'Assistant dialogue / discussion records',
                    'Open outputs'
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
                  ['外部来源核对', '需要设置', '在设置中开启网络权限'],
                  ['专业记忆服务', '可选设置', '保存配置并测试连接'],
                  ['专业检索服务', '可选设置', '保存配置并测试连接'],
                ]
              : [
                  [
                    'External fact checking',
                    'Needs configuration',
                    'Configure network authorization in Settings'
                  ],
                  [
                    'Professional memory service',
                    'Optional configuration',
                    'Save config and test connection'
                  ],
                  [
                    'Professional retrieval service',
                    'Optional configuration',
                    'Save config and test connection'
                  ],
                ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _PrimaryProductAction(
          label: _zh ? '打开设置' : 'Open Settings',
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
                    '来源文档',
                    runtime.sourceManifestPath.isEmpty ? '未生成' : '已生成',
                    runtime.sourceCount == 0
                        ? '等待导入'
                        : '${runtime.sourceCount} 个来源'
                  ],
                  [
                    '解析结果',
                    runtime.parseReportPath.isEmpty ? '未生成' : '已生成',
                    runtime.chunkCount == 0
                        ? '等待整理'
                        : '${runtime.chunkCount} 个片段'
                  ],
                  [
                    '知识库',
                    runtime.kbManifestPath.isEmpty ? '未生成' : '已生成',
                    runtime.hasKnowledgeBase ? '可检索' : '等待构建'
                  ],
                  [
                    '导出文档',
                    runtime.exportedDocumentPath.isEmpty ? '未导出' : '已导出',
                    _displayNameForPath(runtime.exportedDocumentPath)
                  ],
                  [
                    '技能',
                    runtime.hasSkill ? '已生成' : '未生成',
                    _displayNameForPath(runtime.primarySkillPath)
                  ],
                  [
                    '助手',
                    runtime.hasAgent ? '已生成' : '未生成',
                    runtime.hasAgent ? '可对话' : '等待创建'
                  ],
                  [
                    '助手对话',
                    runtime.hasAgentDialogue ? '已保存' : '未生成',
                    runtime.hasAgentDialogue ? '可查看' : '等待运行'
                  ],
                  [
                    '多个助手讨论',
                    runtime.hasMultiAgentDiscussion ? '已生成' : '未生成',
                    runtime.hasMultiAgentDiscussion ? '可查看' : '等待运行'
                  ],
                  [
                    '知识生产链路',
                    runtime.hasPrdP0Evidence ? '已生成' : '未生成',
                    _displayNameForPath(runtime.prdP0EvidencePath)
                  ],
                ]
              : [
                  [
                    'Source documents',
                    runtime.sourceManifestPath.isEmpty
                        ? 'Not generated'
                        : 'Generated',
                    runtime.sourceCount == 0
                        ? 'Waiting import'
                        : '${runtime.sourceCount} sources'
                  ],
                  [
                    'Parse results',
                    runtime.parseReportPath.isEmpty
                        ? 'Not generated'
                        : 'Generated',
                    runtime.chunkCount == 0
                        ? 'Waiting parse'
                        : '${runtime.chunkCount} segments'
                  ],
                  [
                    'Knowledge Base',
                    runtime.kbManifestPath.isEmpty
                        ? 'Not generated'
                        : 'Generated',
                    runtime.hasKnowledgeBase ? 'Searchable' : 'Waiting build'
                  ],
                  [
                    'Exported document',
                    runtime.exportedDocumentPath.isEmpty
                        ? 'Not exported'
                        : 'Exported',
                    _displayNameForPath(runtime.exportedDocumentPath)
                  ],
                  [
                    'Skill',
                    runtime.hasSkill ? 'Generated' : 'Not generated',
                    _displayNameForPath(runtime.primarySkillPath)
                  ],
                  [
                    'Agent',
                    runtime.hasAgent ? 'Generated' : 'Not generated',
                    runtime.hasAgent ? 'Chat ready' : 'Waiting creation'
                  ],
                  [
                    'Agent dialogue',
                    runtime.hasAgentDialogue ? 'Saved' : 'Not generated',
                    runtime.hasAgentDialogue ? 'Viewable' : 'Waiting run'
                  ],
                  [
                    'Multi-Agent discussion',
                    runtime.hasMultiAgentDiscussion
                        ? 'Generated'
                        : 'Not generated',
                    runtime.hasMultiAgentDiscussion ? 'Viewable' : 'Waiting run'
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
            label: _zh ? '打开我的助手' : 'Open My Assistants',
            icon: Icons.groups_2_outlined,
            onPressed: runtime.hasAgent || runtime.hasSkill
                ? () => onPageChanged(_pageIndexById('agent-factory-runtime'))
                : null,
          ),
        ]),
      ],
    );
  }
}
