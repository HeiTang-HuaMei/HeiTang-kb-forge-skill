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
        content: Text(_zh ? '产物已导出' : 'Artifact exported'),
      ),
    );
  }

  Future<void> _deleteSelectedArtifact(
      Rc6RuntimeController? rc6, _ArtifactCenterItem item) async {
    if (rc6 == null || rc6.state.running || item.path.trim().isEmpty) return;
    final confirmed = await _confirmDestructiveAction(
      context,
      title: _zh ? '删除产物记录？' : 'Delete artifact record?',
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.folder_copy_outlined,
        title: _zh ? '产物中心' : 'Artifact Center',
        description: _zh
            ? '集中查看真实工作区中已经生成的文档、知识库、检索、Skill、Agent 和对话产物。'
            : 'Browse generated document, KB, retrieval, Skill, Agent, and dialogue artifacts from the real workspace.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _MetricStrip(
        items: [
          _MetricDatum(
            label: _zh ? '已生成产物' : 'Generated',
            value: '$generatedCount',
            detail: _zh ? '来自真实运行状态' : 'From runtime state',
            icon: Icons.task_alt_outlined,
          ),
          _MetricDatum(
            label: _zh ? '产物分类' : 'Categories',
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
            label: _zh ? '知识库 chunks' : 'KB chunks',
            value: '${runtime.chunkCount}',
            detail: runtime.hasKnowledgeBase
                ? (_zh ? '可检索' : 'Searchable')
                : (_zh ? '等待构建' : 'Build KB first'),
            icon: Icons.account_tree_outlined,
          ),
        ],
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final catalog = _ProductPanel(
          keyName: 'artifact-center-catalog',
          icon: Icons.inventory_2_outlined,
          title: _zh ? '产物清单' : 'Artifact Catalog',
          subtitle: runtime.workspacePath.isEmpty
              ? (_zh ? '等待工作区初始化' : 'Waiting for workspace')
              : (_zh ? '用户工作区' : 'User workspace'),
          children: [
            _ProductTable(
              columns:
                  _zh ? ['分类', '产物', '状态'] : ['Category', 'Artifact', 'Status'],
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
          title: _zh ? '产物详情' : 'Artifact Detail',
          children: [
            _FieldRow(
              label: _zh ? '分类' : 'Category',
              value: selected?.category ?? '-',
            ),
            const SizedBox(height: 8),
            _FieldRow(
              label: _zh ? '产物' : 'Artifact',
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
                        : (_zh ? '等待产物' : 'Waiting for artifact'),
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
                      ? (_zh ? '导出选中产物' : 'Export selected artifact')
                      : (_zh ? '等待可导出产物' : 'Waiting for exportable artifact'),
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
                    ? (_zh ? '删除产物记录' : 'Delete artifact record')
                    : (_zh ? '等待可删除产物' : 'Waiting for deletable artifact'),
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
  return [
    item('文档库', 'Document Library', '来源文档', 'Source documents', 'source',
        runtime.sourceManifestPath, 'import'),
    item('文档库', 'Document Library', '解析结果', 'Parse results', 'parse',
        runtime.parseReportPath, 'parse'),
    item('标准知识包', 'Standard Package', '标准知识包', 'Standard package', 'package',
        runtime.standardKnowledgePackageManifestPath, 'standard-package'),
    item('知识库', 'Knowledge Base', '知识库', 'Knowledge Base', 'kb',
        runtime.kbManifestPath, 'kb'),
    item('知识库', 'Knowledge Base', '索引与质量记录', 'Index and quality records',
        'quality', runtime.qualityReportPath, 'kb'),
    item('检索验证', 'Retrieval', '检索结果', 'Retrieval result', 'retrieval',
        runtime.queryResultPath, 'search'),
    item(
        '检索验证',
        'Retrieval',
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
    item('Skill 工厂', 'Skill Factory', 'Skill 草稿', 'Skill draft', 'skill',
        runtime.primarySkillPath, 'skill'),
    item('Skill 工厂', 'Skill Factory', 'Skill 验证报告', 'Skill validation report',
        'validation', runtime.skillVerificationReportPath, 'skill'),
    item('Skill 工厂', 'Skill Factory', 'Skill 导出包', 'Skill export package',
        'skill export', runtime.skillExportPath, 'skill'),
    item('Agent 工作台', 'Agent Workbench', 'Agent', 'Agent', 'agent',
        runtime.primaryAgentManifestPath, 'agent'),
    item('Agent 工作台', 'Agent Workbench', 'Agent 对话记录', 'Agent dialogue', 'chat',
        runtime.agentDialoguePath, 'agent'),
    item('Agent 工作台', 'Agent Workbench', 'Agent 对话导出', 'Agent dialogue export',
        'chat export', runtime.agentDialogueExportPath, 'agent'),
    item(
        'Agent 工作台',
        'Agent Workbench',
        '多 Agent 讨论纪要',
        'Multi-agent discussion',
        'a2a',
        runtime.multiAgentDiscussionPath,
        'agent'),
    item('Agent 工作台', 'Agent Workbench', 'A2A 协作报告', 'A2A collaboration report',
        'a2a report', runtime.a2aWorkspaceReportPath, 'agent'),
    item('治理', 'Governance', '产品链路记录', 'Product-flow record', 'flow',
        runtime.prdP0EvidencePath, 'doc'),
    item('设置', 'Settings', 'Provider 配置', 'Provider settings', 'provider',
        runtime.providerRuntimeSettingsPath, 'settings'),
    item('设置', 'Settings', '存储配置', 'Storage settings', 'storage',
        runtime.storageProviderSettingsPath, 'settings'),
    item('设置', 'Settings', '能力审计汇总', 'Capability audit summary', 'audit',
        runtime.providerLifecycleAuditSummaryPath, 'settings'),
    item('治理', 'Governance', '并行任务报告', 'Parallel task report', 'parallel',
        runtime.parallelTaskCapacityReportPath, 'parallel-tasks'),
    item('治理', 'Governance', '知识库目录', 'Knowledge Base catalog', 'catalog',
        runtime.knowledgeBaseCatalogPath, 'kb'),
  ];
}
