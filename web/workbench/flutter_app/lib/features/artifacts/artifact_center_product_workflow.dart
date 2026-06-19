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
              columns: _zh
                  ? ['分类', '产物', '状态', '文件']
                  : ['Category', 'Artifact', 'Status', 'File'],
              rows: artifacts
                  .map((artifact) => [
                        artifact.category,
                        artifact.label,
                        artifact.path.trim().isEmpty
                            ? (_zh ? '未生成' : 'Not generated')
                            : (_zh ? '已生成' : 'Generated'),
                        artifact.path.trim().isEmpty
                            ? (_zh ? '去对应页面生成' : 'Generate on owner page')
                            : _displayNameForPath(artifact.path),
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
              label: _zh ? '文件' : 'File',
              value: selected == null || selected.path.trim().isEmpty
                  ? (_zh ? '对应业务页面完成后出现' : 'Appears after workflow run')
                  : _displayNameForPath(selected.path),
            ),
            const SizedBox(height: _DesktopGrid.gutter),
            _EqualActionRow(children: [
              _DisplayAction(
                label: selected != null && selected.path.trim().isNotEmpty
                    ? (_zh ? '复制产物路径' : 'Copy artifact path')
                    : (_zh ? '等待产物路径' : 'Waiting for artifact path'),
                icon: Icons.copy_outlined,
                onPressed: selected != null && selected.path.trim().isNotEmpty
                    ? () => _copyArtifactPath(
                          context,
                          path: selected.path,
                          successMessage:
                              _zh ? '产物路径已复制' : 'Artifact path copied',
                        )
                    : null,
              ),
              _DisplayAction(
                label: canPreview
                    ? (_zh ? '预览文本产物' : 'Preview text artifact')
                    : selected != null && selected.path.trim().isNotEmpty
                        ? (_zh ? '目录产物请复制路径打开' : 'Copy path to open folder')
                        : (_zh
                            ? '等待可预览产物'
                            : 'Waiting for previewable artifact'),
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
    item('文档库', 'Document Library', '导入清单 source_manifest.json',
        'Source manifest', 'manifest', runtime.sourceManifestPath, 'import'),
    item('文档库', 'Document Library', '解析报告 parse_report.json', 'Parse report',
        'parse', runtime.parseReportPath, 'parse'),
    item(
        '标准知识包',
        'Standard Package',
        '标准知识包 manifest',
        'Standard package manifest',
        'std pkg',
        runtime.standardKnowledgePackageManifestPath,
        'standard-package'),
    item(
        '标准知识包',
        'Standard Package',
        '标准知识包内容包',
        'Standard content package',
        'content',
        runtime.standardKnowledgePackageContentPath,
        'standard-package'),
    item(
        '标准知识包',
        'Standard Package',
        '标准包审计历史',
        'Standard package audit history',
        'std audit',
        runtime.standardKnowledgePackageAuditPath,
        'standard-package'),
    item('知识库', 'Knowledge Base', '知识库 manifest.json', 'KB manifest', 'kb',
        runtime.kbManifestPath, 'kb'),
    item('知识库', 'Knowledge Base', 'chunks.jsonl', 'Chunks', 'chunks',
        runtime.chunksPath, 'kb'),
    item('知识库', 'Knowledge Base', 'cards.jsonl', 'Cards', 'cards',
        runtime.cardsPath, 'kb'),
    item('知识库', 'Knowledge Base', 'qa_pairs.jsonl', 'QA pairs', 'qa',
        runtime.qaPairsPath, 'kb'),
    item('知识库', 'Knowledge Base', 'source_map.json', 'Source map', 'source map',
        runtime.sourceMapPath, 'kb'),
    item('知识库', 'Knowledge Base', 'index_metadata.json', 'Index metadata',
        'index', runtime.indexMetadataPath, 'kb'),
    item('知识库', 'Knowledge Base', 'index_profile.json', 'Index profile',
        'profile', runtime.indexProfilePath, 'kb'),
    item('知识库', 'Knowledge Base', 'keyword_index.json', 'Keyword index',
        'keyword', runtime.keywordIndexPath, 'kb'),
    item(
        '知识库',
        'Knowledge Base',
        'vector_index_reference.json',
        'Vector index reference',
        'vector',
        runtime.vectorIndexReferencePath,
        'kb'),
    item('知识库', 'Knowledge Base', 'metadata_index.json', 'Metadata index',
        'metadata', runtime.metadataIndexPath, 'kb'),
    item('知识库', 'Knowledge Base', 'citation_index.json', 'Citation index',
        'citation', runtime.citationIndexPath, 'kb'),
    item(
        '知识库',
        'Knowledge Base',
        'memory_index_reference.json',
        'Memory index reference',
        'memory',
        runtime.memoryIndexReferencePath,
        'kb'),
    item(
        '知识库',
        'Knowledge Base',
        'index_build_report.json',
        'Index build report',
        'index report',
        runtime.indexBuildReportPath,
        'kb'),
    item('知识库', 'Knowledge Base', 'quality_report.json', 'Quality report',
        'quality', runtime.qualityReportPath, 'kb'),
    item('知识库', 'Knowledge Base', 'build.log', 'Build log', 'build log',
        runtime.buildLogPath, 'kb'),
    item('知识库', 'Knowledge Base', 'error.log', 'Error log', 'error log',
        runtime.errorLogPath, 'kb'),
    item('检索验证', 'Retrieval', '检索结果', 'Retrieval result', 'retrieval',
        runtime.queryResultPath, 'search'),
    item('检索验证', 'Retrieval', 'retrieval_plan.json', 'Retrieval plan', 'plan',
        runtime.retrievalPlanPath, 'search'),
    item('检索验证', 'Retrieval', 'rerank_report.json', 'Rerank report', 'rerank',
        runtime.retrievalRerankReportPath, 'search'),
    item(
        '检索验证',
        'Retrieval',
        'citation_coverage_report.json',
        'Citation coverage report',
        'coverage',
        runtime.retrievalCitationCoveragePath,
        'search'),
    item('检索验证', 'Retrieval', 'conflict_report.json', 'Conflict report',
        'conflict', runtime.retrievalConflictReportPath, 'search'),
    item(
        '检索验证',
        'Retrieval',
        'external_validation_boundary.json',
        'External validation boundary',
        'boundary',
        runtime.externalValidationBoundaryPath,
        'search'),
    item('检索验证', 'Retrieval', 'validation_report.json', 'Validation report',
        'validation', runtime.retrievalValidationReportPath, 'search'),
    item('检索验证', 'Retrieval', 'validation_report.md', 'Validation markdown',
        'validation md', runtime.retrievalValidationMarkdownPath, 'search'),
    item('检索验证', 'Retrieval', 'validation_history.jsonl', 'Validation history',
        'history', runtime.retrievalValidationHistoryPath, 'search'),
    item('文档生成', 'Document Generation', 'Markdown 草稿', 'Markdown draft', 'md',
        runtime.generatedMarkdownPath, 'doc'),
    item('文档生成', 'Document Generation', '读书笔记', 'Reading notes', 'notes',
        runtime.readingNotesPath, 'doc'),
    item('文档生成', 'Document Generation', 'outline.json', 'Document outline',
        'outline', runtime.documentOutlinePath, 'doc'),
    item('文档生成', 'Document Generation', 'citations.json', 'Document citations',
        'citations', runtime.documentCitationsPath, 'doc'),
    item(
        '文档生成',
        'Document Generation',
        'document_validation_report.json',
        'Document validation report',
        'doc validation',
        runtime.documentValidationReportPath,
        'doc'),
    item('文档生成', 'Document Generation', '导出文档', 'Exported document', 'export',
        runtime.exportedDocumentPath, 'doc'),
    item('文档生成', 'Document Generation', '导出清单', 'Export manifest',
        'export manifest', runtime.exportManifestPath, 'doc'),
    item('Skill 工厂', 'Skill Factory', 'SKILL.md 草稿', 'SKILL.md draft', 'skill',
        runtime.primarySkillPath, 'skill'),
    item('Skill 工厂', 'Skill Factory', 'Skill metadata', 'Skill metadata',
        'metadata', runtime.skillConfigPath, 'skill'),
    item('Skill 工厂', 'Skill Factory', 'Skill 验证报告', 'Skill validation report',
        'validation', runtime.skillVerificationReportPath, 'skill'),
    item('Skill 工厂', 'Skill Factory', 'Skill 生成清单', 'Skill generation manifest',
        'skill manifest', runtime.skillGenerationManifestPath, 'skill'),
    item(
        'Skill 工厂',
        'Skill Factory',
        '本地化 Skill 清单',
        'Localized Skill manifest',
        'localized',
        runtime.localizedSkillManifestPath,
        'skill'),
    item('Skill 工厂', 'Skill Factory', '本地化差异说明', 'Localization diff summary',
        'diff', runtime.localizedSkillDiffPath, 'skill'),
    item('Skill 工厂', 'Skill Factory', 'Skill 操作清单', 'Skill operation manifest',
        'operations', runtime.skillOperationManifestPath, 'skill'),
    item('Skill 工厂', 'Skill Factory', 'Skill 操作历史', 'Skill operation history',
        'skill history', runtime.skillOperationHistoryPath, 'skill'),
    item('Skill 工厂', 'Skill Factory', 'Skill 导出包', 'Skill export package',
        'skill export', runtime.skillExportPath, 'skill'),
    item('Skill 工厂', 'Skill Factory', 'Agent 绑定清单', 'Agent binding manifest',
        'agent binding', runtime.skillAgentBindingManifestPath, 'skill'),
    item('Agent 工作台', 'Agent Workbench', 'Agent manifest', 'Agent manifest',
        'agent', runtime.primaryAgentManifestPath, 'agent'),
    item('Agent 工作台', 'Agent Workbench', 'Agent profile', 'Agent profile',
        'profile', runtime.agentProfilePath, 'agent'),
    item(
        'Agent 工作台',
        'Agent Workbench',
        'Agent 生成清单',
        'Agent generation manifest',
        'agent manifest',
        runtime.agentGenerationManifestPath,
        'agent'),
    item('Agent 工作台', 'Agent Workbench', '复杂 Agent 配置', 'Advanced Agent config',
        'advanced config', runtime.agentAdvancedConfigPath, 'agent'),
    item('Agent 工作台', 'Agent Workbench', 'Agent 权限审计', 'Agent permission audit',
        'permission', runtime.agentPermissionAuditPath, 'agent'),
    item('Agent 工作台', 'Agent Workbench', 'Agent 导出清单', 'Agent export manifest',
        'agent export', runtime.agentPackageManifestPath, 'agent'),
    item('Agent 工作台', 'Agent Workbench', 'Agent 导出说明', 'Agent export README',
        'agent readme', runtime.agentPackageReadmePath, 'agent'),
    item('Agent 工作台', 'Agent Workbench', 'Agent 对话记录', 'Agent dialogue', 'chat',
        runtime.agentDialoguePath, 'agent'),
    item('Agent 工作台', 'Agent Workbench', 'Agent 会话历史', 'Agent chat history',
        'history', runtime.agentDialogueHistoryPath, 'agent'),
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
    item('治理', 'Governance', '产品链路验证证据', 'Product-flow evidence', 'evidence',
        runtime.prdP0EvidencePath, 'doc'),
    item('治理', 'Governance', '知识库目录', 'Knowledge Base catalog', 'catalog',
        runtime.knowledgeBaseCatalogPath, 'kb'),
  ];
}
