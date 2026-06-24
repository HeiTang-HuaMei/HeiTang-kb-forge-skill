part of '../../main.dart';

class _ArtifactCenterProductWorkflow extends StatefulWidget {
  const _ArtifactCenterProductWorkflow({required this.localeCode});

  final String localeCode;

  @override
  State<_ArtifactCenterProductWorkflow> createState() =>
      _ArtifactCenterProductWorkflowState();
}

class _ArtifactCenterProductWorkflowState
    extends State<_ArtifactCenterProductWorkflow> {
  int selectedIndex = 0;
  String _selectedInitialExportPath = '';

  bool get _zh => widget.localeCode == 'zh-CN';

  Future<void> _exportSelectedArtifact(
      Rc6RuntimeController? rc6, _ArtifactCenterItem item) async {
    if (rc6 == null || rc6.state.running || item.path.trim().isEmpty) return;
    final manifestPath = await rc6.exportWorkspaceArtifact(
      artifactPath: item.path,
      artifactLabel: item.label,
    );
    if (!mounted || manifestPath.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_zh ? '成果已导出' : 'Output exported'),
      ),
    );
  }

  Future<void> _deleteSelectedArtifact(
      Rc6RuntimeController? rc6, _ArtifactCenterItem item) async {
    if (rc6 == null || rc6.state.running || item.path.trim().isEmpty) return;
    final confirmed = await _confirmDestructiveAction(
      context,
      title: _zh ? '删除成果记录？' : 'Delete output record?',
      body: _zh
          ? '这会删除“${item.label}”所属业务阶段的真实产物记录；不会按任意文件路径删除工作区外内容。'
          : 'This deletes the real artifacts for the business stage that owns "${item.label}"; it never deletes arbitrary paths outside the workspace.',
    );
    if (!confirmed) return;
    await rc6.clearRecentTaskArtifacts(item.taskId);
    if (!mounted) return;
    setState(() => selectedIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final artifacts = _artifactCenterItems(runtime, _zh);
    if (selectedIndex >= artifacts.length) selectedIndex = 0;
    if (artifacts.isNotEmpty && artifacts[selectedIndex].path.trim().isEmpty) {
      final firstGenerated =
          artifacts.indexWhere((artifact) => artifact.path.trim().isNotEmpty);
      if (firstGenerated >= 0) selectedIndex = firstGenerated;
    }
    if (runtime.hasAgentDialogueExport &&
        _selectedInitialExportPath != runtime.agentDialogueExportPath) {
      final exportIndex = artifacts.indexWhere(
          (artifact) => artifact.path == runtime.agentDialogueExportPath);
      if (exportIndex >= 0) {
        selectedIndex = exportIndex;
        _selectedInitialExportPath = runtime.agentDialogueExportPath;
      }
    }
    final selected = artifacts.isEmpty ? null : artifacts[selectedIndex];
    final generatedCount =
        artifacts.where((artifact) => artifact.path.trim().isNotEmpty).length;
    final categories =
        artifacts.map((artifact) => artifact.category).toSet().length;
    return _FigmaPageCanvas(children: [
      _MetricStrip(
        items: [
          _MetricDatum(
            label: _zh ? '已生成成果' : 'Generated',
            value: '$generatedCount',
            detail: _zh ? '来自真实运行状态' : 'From runtime state',
            icon: Icons.task_alt_outlined,
          ),
          _MetricDatum(
            label: _zh ? '成果分类' : 'Categories',
            value: '$categories',
            detail: _zh ? '文档 / 知识库 / 应用' : 'Docs / KB / apps',
            icon: Icons.category_outlined,
          ),
          _MetricDatum(
            label: _zh ? '来源文档' : 'Sources',
            value: '${runtime.sourceCount}',
            detail: runtime.sourceNames.isEmpty
                ? (_zh ? '等待导入' : 'Waiting for import')
                : runtime.sourceNames.take(2).join(' · '),
            icon: Icons.article_outlined,
          ),
          _MetricDatum(
            label: _zh ? '知识库片段' : 'KB segments',
            value: '${runtime.chunkCount}',
            detail: runtime.hasKnowledgeBase
                ? (_zh ? '可检索' : 'Searchable')
                : (_zh ? '等待构建' : 'Build KB first'),
            icon: Icons.account_tree_outlined,
          ),
        ],
      ),
      SizedBox(
        height: 540,
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final catalog = _ProductPanel(
            keyName: 'artifact-center-catalog',
            icon: Icons.inventory_2_outlined,
            title: _zh ? '成果清单' : 'Output Catalog',
            subtitle: runtime.workspacePath.isEmpty
                ? (_zh ? '等待工作区初始化' : 'Waiting for workspace')
                : (_zh ? '用户工作区' : 'User workspace'),
            children: [
              _ProductTable(
                columns: _zh
                    ? ['分类', '产物', '状态']
                    : ['Category', 'Artifact', 'Status'],
                rows: artifacts
                    .map((artifact) => [
                          artifact.category,
                          artifact.label,
                          artifact.path.trim().isEmpty
                              ? (_zh ? '未生成' : 'Not generated')
                              : (_zh ? '已生成' : 'Generated'),
                        ])
                    .toList(growable: false),
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              _PageTabs(
                tabs: [
                  for (final artifact in artifacts)
                    '${artifact.shortLabel} ${artifact.path.trim().isEmpty ? "○" : "✓"}',
                ],
                selectedIndex: selectedIndex,
                keyPrefix: 'artifact-center-tab',
                onSelected: (index) => setState(() => selectedIndex = index),
              ),
            ],
          );
          final canPreview = selected != null &&
              selected.path.trim().isNotEmpty &&
              selected.previewable;
          final detail = _ProductPanel(
            keyName: 'artifact-center-detail',
            icon: Icons.article_outlined,
            title: _zh ? '成果详情' : 'Output Detail',
            children: [
              _FieldRow(
                label: _zh ? '分类' : 'Category',
                value: selected?.category ?? '-',
              ),
              const SizedBox(height: 8),
              _FieldRow(
                label: _zh ? '成果' : 'Output',
                value: selected?.label ?? '-',
              ),
              const SizedBox(height: 8),
              _FieldRow(
                label: _zh ? '状态' : 'Status',
                value: selected == null || selected.path.trim().isEmpty
                    ? (_zh ? '未生成' : 'Not generated')
                    : (_zh ? '已生成' : 'Generated'),
              ),
              const SizedBox(height: 8),
              _FieldRow(
                label: _zh ? '位置' : 'Location',
                value: selected == null || selected.path.trim().isEmpty
                    ? (_zh ? '对应页面完成后出现' : 'Appears after workflow run')
                    : _displayNameForPath(selected.path),
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              _EqualActionRow(children: [
                _DisplayAction(
                  label: canPreview
                      ? (_zh ? '打开产物' : 'Open artifact')
                      : selected != null && selected.path.trim().isNotEmpty
                          ? (_zh ? '目录产物' : 'Folder artifact')
                          : (_zh ? '等待成果' : 'Waiting for output'),
                  icon: Icons.visibility_outlined,
                  onPressed: canPreview
                      ? () => _showWorkspaceArtifactPreview(
                            context,
                            rc6: rc6,
                            title: selected.label,
                            path: selected.path,
                            unavailableMessage:
                                _zh ? '尚未生成可预览产物。' : 'No artifact generated.',
                            closeLabel: _zh ? '关闭' : 'Close',
                          )
                      : null,
                ),
                KeyedSubtree(
                  key: const Key('artifact-center-export-selected'),
                  child: _DisplayAction(
                    label: selected != null && selected.path.trim().isNotEmpty
                        ? (_zh ? '导出选中成果' : 'Export selected output')
                        : (_zh ? '等待可导出成果' : 'Waiting for exportable output'),
                    icon: Icons.file_download_outlined,
                    onPressed: selected != null &&
                            selected.path.trim().isNotEmpty &&
                            rc6 != null &&
                            !runtime.running
                        ? () => _exportSelectedArtifact(rc6, selected)
                        : null,
                  ),
                ),
                _DisplayAction(
                  label: selected != null && selected.path.trim().isNotEmpty
                      ? (_zh ? '删除成果记录' : 'Delete output record')
                      : (_zh ? '等待可删除成果' : 'Waiting for deletable output'),
                  icon: Icons.delete_outline,
                  onPressed: selected != null &&
                          selected.path.trim().isNotEmpty &&
                          rc6 != null &&
                          !runtime.running
                      ? () => _deleteSelectedArtifact(rc6, selected)
                      : null,
                ),
              ]),
            ],
          );
          if (!wide) {
            return Column(children: [
              catalog,
              const SizedBox(height: _DesktopGrid.gutter),
              detail
            ]);
          }
          return _EqualHeightRow(
            height: 540,
            flexes: const [7, 4],
            children: [catalog, detail],
          );
        }),
      ),
    ]);
  }
}

class _ArtifactCenterItem {
  const _ArtifactCenterItem({
    required this.category,
    required this.label,
    required this.shortLabel,
    required this.path,
    required this.taskId,
    this.previewable = true,
  });

  final String category;
  final String label;
  final String shortLabel;
  final String path;
  final String taskId;
  final bool previewable;
}

String _artifactRecordCategory(Rc6ArtifactRecord artifact, bool zh) {
  return switch (artifact.sourceModule) {
    'agent' => zh ? '我的助手' : 'My Assistants',
    'artifact_center' => zh ? '成果' : 'Outputs',
    'document_generation' => zh ? '文档生成' : 'Document Generation',
    'skill' => zh ? '技能生成' : 'Skill Builder',
    'knowledge_base' => zh ? '知识库' : 'Knowledge Base',
    'document_library' => zh ? '文档库' : 'Document Library',
    _ => zh ? '成果' : 'Outputs',
  };
}

List<_ArtifactCenterItem> _artifactCenterItems(
    Rc6RuntimeState runtime, bool zh) {
  _ArtifactCenterItem item(String zhCategory, String enCategory, String zhLabel,
          String enLabel, String shortLabel, String path, String taskId,
          {bool previewable = true}) =>
      _ArtifactCenterItem(
        category: zh ? zhCategory : enCategory,
        label: zh ? zhLabel : enLabel,
        shortLabel: shortLabel,
        path: path,
        taskId: taskId,
        previewable: previewable,
      );
  final catalogItems = runtime.artifactRecords
      .where((artifact) => artifact.isActive)
      .map(
        (artifact) => _ArtifactCenterItem(
          category: _artifactRecordCategory(artifact, zh),
          label: artifact.title.trim().isEmpty
              ? (zh ? '成果' : 'Output')
              : artifact.title.trim(),
          shortLabel: artifact.artifactType.trim().isEmpty
              ? 'artifact'
              : artifact.artifactType.trim(),
          path: artifact.filePath,
          taskId: artifact.artifactType == 'agent_reply'
              ? 'agent_reply:${artifact.artifactId}'
              : 'artifact_record:${artifact.artifactId}',
        ),
      )
      .toList(growable: false);
  return [
    ...catalogItems,
    item('文档库', 'Document Library', '来源文档', 'Source documents', 'source',
        runtime.sourceManifestPath, 'import'),
    item('文档库', 'Document Library', '整理结果', 'Organized results', 'organized',
        runtime.parseReportPath, 'parse'),
    item('标准知识包', 'Standard Package', '标准知识包', 'Standard package', 'package',
        runtime.standardKnowledgePackageManifestPath, 'standard-package'),
    item('知识库', 'Knowledge Base', '知识库', 'Knowledge Base', 'kb',
        runtime.kbManifestPath, 'kb'),
    item('知识库', 'Knowledge Base', '索引与质量记录', 'Index and quality records',
        'quality', runtime.qualityReportPath, 'kb'),
    item('知识库', 'Knowledge Base', '验证结果', 'Verification result', 'retrieval',
        runtime.queryResultPath, 'search'),
    item(
        '知识库',
        'Knowledge Base',
        '验证报告',
        'Validation report',
        'validation',
        runtime.retrievalValidationMarkdownPath.isNotEmpty
            ? runtime.retrievalValidationMarkdownPath
            : runtime.retrievalValidationReportPath,
        'search'),
    item('文档生成', 'Document Generation', '生成文档', 'Generated document', 'doc',
        runtime.generatedMarkdownPath, 'doc'),
    item('文档生成', 'Document Generation', '读书笔记', 'Reading notes', 'notes',
        runtime.readingNotesPath, 'doc'),
    item('文档生成', 'Document Generation', '导出文档', 'Exported document', 'export',
        runtime.exportedDocumentPath, 'doc'),
    item('技能生成', 'Skill Builder', '技能草稿', 'Skill draft', 'skill',
        runtime.primarySkillPath, 'skill'),
    item('技能生成', 'Skill Builder', '技能验证报告', 'Skill validation report',
        'validation', runtime.skillVerificationReportPath, 'skill'),
    item('技能生成', 'Skill Builder', '技能导出包', 'Skill export package',
        'skill export', runtime.skillExportPath, 'skill'),
    item('我的助手', 'My Assistants', '助手', 'Assistant', 'assistant',
        runtime.primaryAgentManifestPath, 'agent'),
    item('我的助手', 'My Assistants', '助手对话记录', 'Assistant dialogue', 'chat',
        runtime.agentDialoguePath, 'agent'),
    item('我的助手', 'My Assistants', '助手对话导出', 'Assistant dialogue export',
        'chat export', runtime.agentDialogueExportPath, 'agent'),
    for (var index = 0; index < runtime.agentArtifacts.length; index++)
      item(
        '我的助手',
        'My Assistants',
        runtime.agentArtifacts[index].agentName.isEmpty
            ? '助手回复成果'
            : '${runtime.agentArtifacts[index].agentName}回复成果',
        runtime.agentArtifacts[index].agentName.isEmpty
            ? 'Assistant reply output'
            : '${runtime.agentArtifacts[index].agentName} reply output',
        'reply ${index + 1}',
        runtime.agentArtifacts[index].path,
        'agent_reply:${runtime.agentArtifacts[index].artifactId}',
      ),
    item('我的助手', 'My Assistants', '工作小组纪要', 'Work group notes', 'discussion',
        runtime.multiAgentDiscussionPath, 'agent'),
    item('我的助手', 'My Assistants', '工作小组报告', 'Work group report',
        'discussion report', runtime.a2aWorkspaceReportPath, 'agent'),
    item('治理', 'Governance', '产品链路记录', 'Product-flow record', 'flow',
        runtime.prdP0EvidencePath, 'doc'),
    item('设置', 'Settings', '模型服务配置', 'Model service settings', 'model',
        runtime.providerRuntimeSettingsPath, 'settings'),
    item('设置', 'Settings', '存储配置', 'Storage settings', 'storage',
        runtime.storageProviderSettingsPath, 'settings'),
    item('设置', 'Settings', '操作记录汇总', 'Operation record summary', 'usage',
        runtime.providerLifecycleAuditSummaryPath, 'settings'),
    item('治理', 'Governance', '并行任务报告', 'Parallel task report', 'parallel',
        runtime.parallelTaskCapacityReportPath, 'parallel-tasks'),
    item('治理', 'Governance', '知识库目录', 'Knowledge Base catalog', 'catalog',
        runtime.knowledgeBaseCatalogPath, 'kb'),
  ];
}
