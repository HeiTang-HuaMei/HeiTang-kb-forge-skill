part of '../../main.dart';

class _ValidateExportProductWorkflow extends StatelessWidget {
  const _ValidateExportProductWorkflow({
    required this.localeCode,
    required this.workspace,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final String localeCode;
  final String workspace;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final tabs = _zh
        ? ['执行记录', '失败记录', '审计导出']
        : ['Execution Records', 'Failure Records', 'Audit Export'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.fact_check_outlined,
        title: _zh ? '治理与审计' : 'Governance & Audit',
        description: _zh
            ? '统一查看真实执行记录、失败记录和产物记录，并导出当前工作区审计报告。'
            : 'Review real execution, failure, and artifact records, then export the current workspace audit report.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _PageTabs(
          tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
      const SizedBox(height: _DesktopGrid.gutter),
      if (selectedTab == 1)
        _ReportsEvidenceView(zh: _zh, runtimeController: rc6)
      else if (selectedTab == 2)
        _ControlledExportView(
            zh: _zh, workspace: workspace, runtimeController: rc6)
      else
        _ValidationChecklistView(zh: _zh, runtimeController: rc6),
    ]);
  }
}

class _ValidationChecklistView extends StatefulWidget {
  const _ValidationChecklistView({
    required this.zh,
    required this.runtimeController,
  });
  final bool zh;
  final Rc6RuntimeController? runtimeController;

  @override
  State<_ValidationChecklistView> createState() =>
      _ValidationChecklistViewState();
}

class _ValidationChecklistViewState extends State<_ValidationChecklistView> {
  String moduleFilter = 'all';
  String statusFilter = 'all';

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    final runtime =
        widget.runtimeController?.state ?? Rc6RuntimeState.initial();
    final records = _auditRecordRows(runtime, zh);
    final modules = [
      'all',
      ...records.map((row) => row.first).toSet(),
    ];
    final filteredRecords = records.where((row) {
      final moduleMatches = moduleFilter == 'all' || row.first == moduleFilter;
      final status = row.length > 2 ? row[2] : '';
      final completed =
          status == (zh ? '已完成' : 'Done') || status == (zh ? '执行中' : 'Running');
      final statusMatches = statusFilter == 'all' ||
          (statusFilter == 'done' && completed) ||
          (statusFilter == 'open' && !completed);
      return moduleMatches && statusMatches;
    }).toList(growable: false);
    final failureRows = _auditFailureRows(runtime, zh);
    final artifactRows = _auditArtifactRows(runtime, zh);
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final center = _ProductPanel(
        keyName: 'validation-checklist',
        icon: Icons.receipt_long_outlined,
        title: zh ? '执行记录' : 'Execution Records',
        children: [
          _MetricStrip(
            items: [
              _MetricDatum(
                  label: zh ? '执行记录' : 'Records',
                  value: '${filteredRecords.length}/${records.length}',
                  detail: zh ? '来自运行状态' : 'From runtime state',
                  icon: Icons.receipt_long_outlined),
              _MetricDatum(
                  label: zh ? '失败记录' : 'Failures',
                  value: '${failureRows.length}',
                  detail: failureRows.isEmpty
                      ? (zh ? '当前无失败' : 'No current failure')
                      : (zh ? '需要查看详情' : 'Inspect detail'),
                  icon: Icons.warning_amber_outlined),
              _MetricDatum(
                  label: zh ? '产物记录' : 'Artifacts',
                  value: '${artifactRows.length}',
                  detail: runtime.workspacePath.isEmpty
                      ? (zh ? '等待工作区' : 'Waiting for workspace')
                      : (zh ? '可追踪产物' : 'Traceable artifacts'),
                  icon: Icons.folder_copy_outlined),
            ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _SectionCaption(zh ? '筛选执行记录' : 'Filter execution records'),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final module in modules)
              ChoiceChip(
                key: Key('audit-module-filter-$module'),
                label: Text(
                    module == 'all' ? (zh ? '全部模块' : 'All modules') : module),
                selected: moduleFilter == module,
                onSelected: (_) => setState(() => moduleFilter = module),
              ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(
              key: const Key('audit-status-filter-all'),
              label: Text(zh ? '全部状态' : 'All status'),
              selected: statusFilter == 'all',
              onSelected: (_) => setState(() => statusFilter = 'all'),
            ),
            ChoiceChip(
              key: const Key('audit-status-filter-done'),
              label: Text(zh ? '已完成 / 执行中' : 'Done / running'),
              selected: statusFilter == 'done',
              onSelected: (_) => setState(() => statusFilter = 'done'),
            ),
            ChoiceChip(
              key: const Key('audit-status-filter-open'),
              label: Text(zh ? '未运行' : 'Not run'),
              selected: statusFilter == 'open',
              onSelected: (_) => setState(() => statusFilter = 'open'),
            ),
          ]),
          const SizedBox(height: _DesktopGrid.gutter),
          _ProductTable(
            columns: zh
                ? ['模块', '事件', '状态', '产物']
                : ['Module', 'Event', 'Status', 'Artifact'],
            rows: filteredRecords.isEmpty
                ? [
                    [
                      zh ? '当前筛选' : 'Current filter',
                      zh ? '无匹配记录' : 'No matching record',
                      zh ? '请调整模块或状态' : 'Adjust module or status',
                      zh ? '无产物' : 'No artifact',
                    ]
                  ]
                : filteredRecords,
          ),
        ],
      );
      final issues = _ProductPanel(
        icon: Icons.report_problem_outlined,
        title: zh ? '失败记录' : 'Failure Records',
        gap: failureRows.isNotEmpty,
        children: [
          _ProductTable(
            columns: zh ? ['模块', '状态', '原因'] : ['Module', 'Status', 'Reason'],
            rows: failureRows.isEmpty
                ? [
                    [
                      zh ? '当前工作区' : 'Current workspace',
                      zh ? '无失败' : 'No failure',
                      runtime.lastMessage,
                    ]
                  ]
                : failureRows,
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          center,
          const SizedBox(height: _DesktopGrid.gutter),
          issues
        ]);
      }
      return _EqualHeightRow(
        height: 452,
        flexes: const [7, 4],
        children: [center, issues],
      );
    });
  }
}

class _ReportsEvidenceView extends StatefulWidget {
  const _ReportsEvidenceView({
    required this.zh,
    required this.runtimeController,
  });
  final bool zh;
  final Rc6RuntimeController? runtimeController;

  @override
  State<_ReportsEvidenceView> createState() => _ReportsEvidenceViewState();
}

class _ReportsEvidenceViewState extends State<_ReportsEvidenceView> {
  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    final runtime =
        widget.runtimeController?.state ?? Rc6RuntimeState.initial();
    final failureRows = _auditFailureRows(runtime, zh);
    final artifactRows = _auditArtifactRows(runtime, zh);
    final previewPath = _firstAuditPreviewPath(runtime);
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final list = _ProductPanel(
        keyName: 'report-evidence-list',
        icon: Icons.receipt_long_outlined,
        title: zh ? '失败记录' : 'Failure Records',
        children: [
          _ProductTable(
            columns: zh ? ['模块', '状态', '原因'] : ['Module', 'Status', 'Reason'],
            rows: failureRows.isEmpty
                ? [
                    [
                      zh ? '当前工作区' : 'Current workspace',
                      zh ? '无失败' : 'No failure',
                      runtime.lastMessage,
                    ]
                  ]
                : failureRows,
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _EqualActionRow(children: [
            _DisplayAction(
              label: previewPath.isEmpty
                  ? (zh ? '等待可预览产物' : 'Waiting for previewable artifact')
                  : (zh ? '预览最近产物记录' : 'Preview latest artifact record'),
              icon: Icons.receipt_long_outlined,
              onPressed: previewPath.isEmpty
                  ? null
                  : () => _showWorkspaceArtifactPreview(
                        context,
                        rc6: widget.runtimeController,
                        title: zh ? '审计产物预览' : 'Audit artifact preview',
                        path: previewPath,
                        unavailableMessage:
                            zh ? '尚未生成可预览产物。' : 'No previewable artifact.',
                        closeLabel: zh ? '关闭' : 'Close',
                      ),
            ),
          ]),
        ],
      );
      final detail = _ProductPanel(
        keyName: 'selected-report-detail',
        icon: Icons.plagiarism_outlined,
        title: zh ? '产物记录' : 'Artifact Records',
        children: [
          _ProductTable(
            columns: zh ? ['模块', '产物', '文件'] : ['Module', 'Artifact', 'File'],
            rows: artifactRows.isEmpty
                ? [
                    [
                      zh ? '当前工作区' : 'Current workspace',
                      zh ? '暂无产物' : 'No artifact',
                      zh ? '执行主链路后出现' : 'Run product flow first',
                    ]
                  ]
                : artifactRows,
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          list,
          const SizedBox(height: _DesktopGrid.gutter),
          detail
        ]);
      }
      return _EqualHeightRow(
        height: 388,
        flexes: const [7, 4],
        children: [list, detail],
      );
    });
  }
}

class _ControlledExportView extends StatefulWidget {
  const _ControlledExportView({
    required this.zh,
    required this.workspace,
    required this.runtimeController,
  });
  final bool zh;
  final String workspace;
  final Rc6RuntimeController? runtimeController;

  @override
  State<_ControlledExportView> createState() => _ControlledExportViewState();
}

class _ControlledExportViewState extends State<_ControlledExportView> {
  String auditReportPath = '';
  bool exporting = false;

  bool get zh => widget.zh;

  Future<void> _exportAuditReport() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null || rc6.state.running || exporting) return;
    setState(() => exporting = true);
    final path = await rc6.exportAuditReport();
    if (!mounted) return;
    setState(() {
      auditReportPath = path;
      exporting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final runtime =
        widget.runtimeController?.state ?? Rc6RuntimeState.initial();
    return _ProductPanel(
      keyName: 'controlled-export-summary',
      icon: Icons.outbox_outlined,
      title: zh ? '审计导出' : 'Audit Export',
      subtitle: widget.workspace,
      children: [
        _ProductTable(
          columns: zh ? ['项目', '状态', '说明'] : ['Item', 'Status', 'Note'],
          rows: zh
              ? [
                  [
                    '执行记录',
                    '${_auditRecordRows(runtime, zh).length} 条',
                    '来自当前运行状态'
                  ],
                  [
                    '失败记录',
                    '${_auditFailureRows(runtime, zh).length} 条',
                    runtime.lastError.isEmpty ? '无当前失败' : runtime.lastError
                  ],
                  [
                    '产物记录',
                    '${_auditArtifactRows(runtime, zh).length} 条',
                    '可在产物中心继续查看'
                  ],
                  [
                    '审计报告',
                    auditReportPath.isEmpty ? '未导出' : '已导出',
                    auditReportPath.isEmpty
                        ? '点击下方按钮生成'
                        : _displayNameForPath(auditReportPath)
                  ],
                ]
              : [
                  [
                    'Execution records',
                    '${_auditRecordRows(runtime, zh).length}',
                    'From current runtime state'
                  ],
                  [
                    'Failure records',
                    '${_auditFailureRows(runtime, zh).length}',
                    runtime.lastError.isEmpty
                        ? 'No current failure'
                        : runtime.lastError
                  ],
                  [
                    'Artifact records',
                    '${_auditArtifactRows(runtime, zh).length}',
                    'Continue in Artifact Center'
                  ],
                  [
                    'Audit report',
                    auditReportPath.isEmpty ? 'Not exported' : 'Exported',
                    auditReportPath.isEmpty
                        ? 'Use the action below'
                        : _displayNameForPath(auditReportPath)
                  ],
                ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _EqualActionRow(children: [
          _PrimaryProductAction(
            label: exporting
                ? (zh ? '正在导出审计报告' : 'Exporting audit report')
                : (zh ? '导出审计报告' : 'Export audit report'),
            onPressed: widget.runtimeController == null || exporting
                ? null
                : _exportAuditReport,
            icon: Icons.archive_outlined,
          ),
          _DisplayAction(
            label: auditReportPath.isEmpty
                ? (zh ? '等待审计报告路径' : 'Waiting for audit report path')
                : (zh ? '复制审计报告路径' : 'Copy audit report path'),
            icon: Icons.copy_outlined,
            onPressed: auditReportPath.isEmpty
                ? null
                : () => _copyArtifactPath(
                      context,
                      path: auditReportPath,
                      successMessage:
                          zh ? '审计报告路径已复制' : 'Audit report path copied',
                    ),
          ),
          _DisplayAction(
            label: auditReportPath.isEmpty
                ? (zh ? '等待可预览报告' : 'Waiting for previewable report')
                : (zh ? '预览审计报告' : 'Preview audit report'),
            icon: Icons.visibility_outlined,
            onPressed: auditReportPath.isEmpty
                ? null
                : () => _showWorkspaceArtifactPreview(
                      context,
                      rc6: widget.runtimeController,
                      title: zh ? '审计报告预览' : 'Audit report preview',
                      path: auditReportPath,
                      unavailableMessage:
                          zh ? '尚未生成审计报告。' : 'No audit report generated.',
                      closeLabel: zh ? '关闭' : 'Close',
                    ),
          ),
        ]),
      ],
    );
  }
}

List<List<String>> _auditRecordRows(Rc6RuntimeState runtime, bool zh) {
  List<String> row(String zhModule, String enModule, String zhEvent,
          String enEvent, bool done, String artifact) =>
      [
        zh ? zhModule : enModule,
        zh ? zhEvent : enEvent,
        done ? (zh ? '已完成' : 'Done') : (zh ? '未运行' : 'Not run'),
        artifact.trim().isEmpty
            ? (zh ? '无产物' : 'No artifact')
            : _displayNameForPath(artifact),
      ];
  return [
    row('文档库', 'Document Library', '导入来源', 'Import sources',
        runtime.hasImportedFile, runtime.sourceManifestPath),
    row('文档库', 'Document Library', '解析与分块', 'Parse and chunk',
        runtime.parseReportPath.isNotEmpty, runtime.parseReportPath),
    row('知识库', 'Knowledge Base', '构建知识库', 'Build Knowledge Base',
        runtime.hasKnowledgeBase, runtime.kbManifestPath),
    row('检索验证', 'Retrieval', '检索证据', 'Retrieve evidence',
        runtime.queryResultPath.isNotEmpty, runtime.queryResultPath),
    row('文档生成', 'Document Generation', '导出文档', 'Export document',
        runtime.exportedDocumentPath.isNotEmpty, runtime.exportedDocumentPath),
    row('Skill 工厂', 'Skill Factory', '生成 Skill', 'Generate Skill',
        runtime.hasPrimarySkill, runtime.primarySkillPath),
    row('Agent 工作台', 'Agent Workbench', '生成 Agent', 'Generate Agent',
        runtime.hasAgent, runtime.agentPath),
    row('Agent 工作台', 'Agent Workbench', 'Agent 对话', 'Agent dialogue',
        runtime.hasAgentDialogue, runtime.agentDialoguePath),
    row('Agent 工作台', 'Agent Workbench', '多 Agent / A2A', 'Multi-Agent / A2A',
        runtime.hasMultiAgentDiscussion, runtime.multiAgentDiscussionPath),
    [
      zh ? '运行状态' : 'Runtime',
      zh ? '最近消息' : 'Latest message',
      runtime.running ? (zh ? '执行中' : 'Running') : runtime.phase.name,
      runtime.lastMessage,
    ],
  ];
}

List<List<String>> _auditFailureRows(Rc6RuntimeState runtime, bool zh) {
  final rows = <List<String>>[];
  if (runtime.lastError.trim().isNotEmpty) {
    rows.add([
      zh ? '运行状态' : 'Runtime',
      runtime.phase.name,
      runtime.lastError,
    ]);
  }
  final last = runtime.lastResult;
  if (last != null && !last.passed) {
    rows.add([
      last.actionId,
      last.productStatus,
      last.userReason,
    ]);
  }
  return rows;
}

List<List<String>> _auditArtifactRows(Rc6RuntimeState runtime, bool zh) {
  final artifacts = _artifactCenterItems(runtime, zh)
      .where((artifact) => artifact.path.trim().isNotEmpty)
      .toList(growable: false);
  return [
    for (final artifact in artifacts)
      [
        artifact.category,
        artifact.label,
        _displayNameForPath(artifact.path),
      ],
  ];
}

String _firstAuditPreviewPath(Rc6RuntimeState runtime) {
  for (final path in [
    runtime.queryResultPath,
    runtime.retrievalValidationReportPath,
    runtime.retrievalPlanPath,
    runtime.retrievalRerankReportPath,
    runtime.retrievalCitationCoveragePath,
    runtime.retrievalConflictReportPath,
    runtime.externalValidationBoundaryPath,
    runtime.standardKnowledgePackageManifestPath,
    runtime.indexBuildReportPath,
    runtime.indexProfilePath,
    runtime.exportManifestPath,
    runtime.qualityReportPath,
    runtime.parseReportPath,
    runtime.sourceManifestPath,
    runtime.skillVerificationReportPath,
    runtime.skillGenerationManifestPath,
    runtime.skillExportPath,
    runtime.agentGenerationManifestPath,
    runtime.agentPermissionAuditPath,
    runtime.agentPackageManifestPath,
    runtime.generatedMarkdownPath,
    runtime.agentDialoguePath,
    runtime.agentDialogueExportPath,
    runtime.multiAgentDiscussionPath,
  ]) {
    if (path.trim().isNotEmpty) return path;
  }
  return '';
}
