part of '../../main.dart';

class _KnowledgeProductWorkflow extends StatelessWidget {
  const _KnowledgeProductWorkflow({
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
    final tabs = _zh
        ? ['知识库', '向量索引', '质量记录', '存储边界']
        : ['Packages', 'Vector Index', 'Quality Records', 'Storage Boundary'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductHeader(
          icon: Icons.inventory_2_outlined,
          title: _zh ? '知识库' : 'Knowledge Base',
          description: _zh
              ? '管理知识库列表、向量索引、质量、版本、构建和验证记录。'
              : 'Manage knowledge bases, vector indexes, quality, versions, builds, and validation records.',
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _PageTabs(
            tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
        const SizedBox(height: _DesktopGrid.gutter),
        if (selectedTab == 1)
          _KnowledgeVectorIndexView(zh: _zh)
        else if (selectedTab == 2)
          _KnowledgeQualityRecordsView(zh: _zh)
        else if (selectedTab == 3)
          _KnowledgeStorageBoundaryView(zh: _zh)
        else
          _KnowledgePackageListView(zh: _zh, workspace: workspace),
      ],
    );
  }
}

class _KnowledgeStorageBoundaryView extends StatelessWidget {
  const _KnowledgeStorageBoundaryView({required this.zh});

  final bool zh;

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'knowledge-storage-boundary',
      icon: Icons.storage_outlined,
      title: zh ? '存储与 Provider 边界' : 'Storage and Provider Boundary',
      gap: true,
      subtitle: zh
          ? 'Provider、存储和应用工作区归设置；这里仅展示知识库侧引用边界。'
          : 'Providers, storage, and workspace live in Settings; this shows the Knowledge Base side boundary only.',
      children: [
        _ProductTable(
          columns: zh ? ['能力', '当前分类', '说明'] : ['Capability', 'Class', 'Note'],
          rows: zh
              ? [
                  ['本地知识库', '可用', '依赖已有本地产物'],
                  ['向量库 Provider', '未配置外部向量库', '本地索引可用，可在 Settings 配置'],
                  ['外部事实验证', '授权后可用', '联网 Provider 配置后执行'],
                ]
              : [
                  [
                    'Local package',
                    'Available',
                    'Depends on existing local artifacts'
                  ],
                  [
                    'Vector DB provider',
                    'External vector DB not configured',
                    'Local index available; configure in Settings'
                  ],
                  [
                    'External fact verification',
                    'Available after authorization',
                    'Runs after network Provider is configured'
                  ],
                ],
        ),
      ],
    );
  }
}

class _KnowledgePackageListView extends StatefulWidget {
  const _KnowledgePackageListView({required this.zh, required this.workspace});

  final bool zh;
  final String workspace;

  @override
  State<_KnowledgePackageListView> createState() =>
      _KnowledgePackageListViewState();
}

class _KnowledgePackageListViewState extends State<_KnowledgePackageListView> {
  bool qualityReportPrepared = false;
  bool llmEnhance = false;
  String kbType = 'basic';
  String storageTarget = 'local';
  int buildStep = 0;
  final Set<String> selectedSourceIds = <String>{};
  final TextEditingController _kbNameController =
      TextEditingController(text: '真实输入知识库');

  bool get zh => widget.zh;

  @override
  void dispose() {
    _kbNameController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDeleteKnowledgeBase(Rc6RuntimeController? rc6) async {
    if (rc6 == null ||
        rc6.state.running ||
        (!rc6.state.hasKnowledgeBase && rc6.state.knowledgeBases.isEmpty)) {
      return;
    }
    final firstKbId = rc6.state.knowledgeBases.isNotEmpty
        ? rc6.state.knowledgeBases.first.id
        : '';
    final confirmed = await _confirmDestructiveAction(
      context,
      title: firstKbId.isEmpty
          ? (zh ? '删除当前知识库？' : 'Delete current knowledge base?')
          : (zh ? '删除知识库 $firstKbId？' : 'Delete KB $firstKbId?'),
      body: firstKbId.isEmpty
          ? (zh
              ? '这会删除当前工作区内的知识库、检索结果和文档导出产物；导入文件和解析报告保留，可重新构建。'
              : 'This deletes KB, retrieval, and document export artifacts in this workspace; imported files and parse reports are kept for rebuild.')
          : (zh
              ? '这会删除该知识库 catalog 记录和独立索引目录；文档库来源保留。'
              : 'This deletes the catalog record and isolated index directory; source documents remain.'),
    );
    if (!confirmed) return;
    if (firstKbId.isEmpty) {
      await rc6.clearKnowledgeBaseArtifacts();
    } else {
      await rc6.deleteKnowledgeBaseRecord(firstKbId);
    }
    if (mounted) {
      setState(() {
        selectedSourceIds.clear();
        buildStep = 0;
        qualityReportPrepared = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final hasKbName = _kbNameController.text.trim().isNotEmpty;
    final localStorageReady = storageTarget == 'local';
    final sourceRecords = runtime.sourceRecords;
    final availableSourceIds = sourceRecords
        .map((source) => source.documentId)
        .where((id) => id.isNotEmpty)
        .toSet();
    selectedSourceIds.removeWhere((id) => !availableSourceIds.contains(id));
    if (selectedSourceIds.isEmpty && sourceRecords.isNotEmpty) {
      selectedSourceIds.addAll(availableSourceIds);
    }
    final selectedSourceCount = selectedSourceIds.length;
    final buildReady = runtime.hasImportedFile &&
        selectedSourceCount > 0 &&
        hasKbName &&
        localStorageReady;
    final artifactsReady = runtime.hasKnowledgeBase &&
        runtime.chunksPath.isNotEmpty &&
        runtime.qualityReportPath.isNotEmpty;
    final knowledgeBases = runtime.knowledgeBases;
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final builder = _FillProductPanel(
        keyName: 'knowledge-package-list',
        icon: Icons.account_tree_outlined,
        title: zh ? '知识库构建流程' : 'Knowledge Base Build Flow',
        child: _FillPanelColumn(
          top: _LocalScrollBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _KnowledgeBuildActionGrid(
                  zh: zh,
                  activeStep: runtime.hasKnowledgeBase ? 6 : buildStep,
                  steps: [
                    _KnowledgeBuildStep(
                      zh ? '1. 选择来源文档' : '1. Select source docs',
                      runtime.hasImportedFile
                          ? (zh
                              ? '已选择 $selectedSourceCount / ${runtime.sourceCount} 个文档'
                              : '$selectedSourceCount / ${runtime.sourceCount} docs selected')
                          : (zh ? '请先导入文件' : 'Import files first'),
                      Icons.library_books_outlined,
                      selectedSourceCount > 0,
                      runtime.hasImportedFile
                          ? () => setState(() {
                                buildStep = 1;
                              })
                          : null,
                    ),
                    _KnowledgeBuildStep(
                      zh ? '2. 命名知识库' : '2. Name KB',
                      _kbNameController.text.trim().isEmpty
                          ? (zh ? '待命名' : 'Needs name')
                          : _kbNameController.text.trim(),
                      Icons.drive_file_rename_outline,
                      hasKbName,
                      () => setState(() => buildStep = 2),
                    ),
                    _KnowledgeBuildStep(
                      zh ? '3. 选择类型' : '3. Choose type',
                      _knowledgeTypeLabel(kbType, zh),
                      Icons.category_outlined,
                      true,
                      () => setState(() => buildStep = 3),
                    ),
                    _KnowledgeBuildStep(
                      zh ? '4. 增强选项' : '4. Enhance',
                      llmEnhance
                          ? (zh
                              ? '授权 Provider 增强'
                              : 'Authorized Provider enhancement')
                          : (zh ? '本地构建' : 'Local build'),
                      Icons.auto_fix_high_outlined,
                      true,
                      () => setState(() => buildStep = 4),
                    ),
                    _KnowledgeBuildStep(
                      zh ? '5. 选择存储' : '5. Storage',
                      _knowledgeStorageLabel(storageTarget, zh),
                      Icons.storage_outlined,
                      localStorageReady,
                      () => setState(() => buildStep = 5),
                    ),
                    _KnowledgeBuildStep(
                      zh ? '6. 构建' : '6. Build',
                      runtime.hasKnowledgeBase
                          ? (zh ? '已构建' : 'Built')
                          : (zh
                              ? '点击后生成 chunks / manifest'
                              : 'Click to write chunks / manifest'),
                      Icons.build_outlined,
                      runtime.hasKnowledgeBase,
                      runtime.running || rc6 == null || !buildReady
                          ? null
                          : () {
                              setState(() {
                                buildStep = 6;
                              });
                              rc6.buildKnowledgeBase(
                                  documentIds: selectedSourceIds.toList(
                                      growable: false));
                            },
                    ),
                    _KnowledgeBuildStep(
                      zh ? '7. 查看产物' : '7. Artifacts',
                      artifactsReady
                          ? _displayNameForPath(runtime.kbManifestPath)
                          : (zh ? '等待构建' : 'Waiting build'),
                      Icons.folder_open_outlined,
                      artifactsReady,
                      artifactsReady
                          ? () => setState(() => qualityReportPrepared = true)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: _DesktopGrid.gutter),
                TextField(
                  controller: _kbNameController,
                  onChanged: (_) => setState(() => buildStep = 2),
                  decoration: InputDecoration(
                    labelText: zh ? '知识库名称' : 'Knowledge base name',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: _DesktopGrid.gutter),
                _ProductTable(
                  columns: zh
                      ? ['步骤', '用户选择', '状态']
                      : ['Step', 'User choice', 'Status'],
                  rows: zh
                      ? [
                          [
                            '来源文档',
                            selectedSourceCount > 0
                                ? '已选择 $selectedSourceCount 个来源文档'
                                : '请先导入文件夹',
                            selectedSourceCount > 0 ? '已选择' : '等待选择'
                          ],
                          [
                            '知识库名称',
                            _kbNameController.text.trim().isEmpty
                                ? '待命名'
                                : _kbNameController.text.trim(),
                            _kbNameController.text.trim().isEmpty
                                ? '待命名'
                                : '已命名'
                          ],
                          ['知识库类型', _knowledgeTypeLabel(kbType, zh), '已选择'],
                          [
                            'LLM 增强',
                            llmEnhance ? '启用，使用已配置 Provider' : '关闭，使用本地构建',
                            llmEnhance ? '需要授权配置' : '本地可用'
                          ],
                          [
                            '存储路径',
                            _knowledgeStorageLabel(storageTarget, zh),
                            storageTarget == 'local' ? '本地可用' : '需连接测试'
                          ],
                        ]
                      : [
                          [
                            'Source docs',
                            selectedSourceCount > 0
                                ? '$selectedSourceCount source docs selected'
                                : 'Import a folder first',
                            selectedSourceCount > 0
                                ? 'Selected'
                                : 'Waiting selection'
                          ],
                          [
                            'KB name',
                            _kbNameController.text.trim().isEmpty
                                ? 'Needs name'
                                : _kbNameController.text.trim(),
                            _kbNameController.text.trim().isEmpty
                                ? 'Needs name'
                                : 'Named'
                          ],
                          [
                            'KB type',
                            _knowledgeTypeLabel(kbType, zh),
                            'Selected'
                          ],
                          [
                            'LLM enhance',
                            llmEnhance
                                ? 'Enabled with configured Provider'
                                : 'Off, local build',
                            llmEnhance
                                ? 'Authorization config required'
                                : 'Local ready'
                          ],
                          [
                            'Storage path',
                            _knowledgeStorageLabel(storageTarget, zh),
                            storageTarget == 'local'
                                ? 'Local ready'
                                : 'Connection test required'
                          ],
                        ],
                ),
                if (sourceRecords.isNotEmpty) ...[
                  const SizedBox(height: _DesktopGrid.gutter),
                  _SectionCaption(zh ? '来源文档选择器' : 'Source document selector'),
                  const SizedBox(height: 8),
                  _ProductTable(
                    columns: zh
                        ? ['选择', '文档', 'Document ID', '类型']
                        : ['Selected', 'Document', 'Document ID', 'Type'],
                    rows: sourceRecords
                        .map((source) => [
                              selectedSourceIds.contains(source.documentId)
                                  ? (zh ? '已选' : 'Selected')
                                  : (zh ? '未选' : 'Not selected'),
                              source.sourceName,
                              source.documentId,
                              _documentTypeLabel(
                                  _documentTypeForSource(source), zh),
                            ])
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final source in sourceRecords)
                      FilterChip(
                        label: Text(source.sourceName,
                            overflow: TextOverflow.ellipsis),
                        selected: selectedSourceIds.contains(source.documentId),
                        onSelected: source.documentId.isEmpty
                            ? null
                            : (selected) => setState(() {
                                  if (selected) {
                                    selectedSourceIds.add(source.documentId);
                                  } else {
                                    selectedSourceIds.remove(source.documentId);
                                  }
                                  buildStep = 1;
                                }),
                      ),
                  ]),
                ],
                const SizedBox(height: _DesktopGrid.gutter),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ChoiceChip(
                    label: Text(zh ? '基础知识库' : 'Basic KB'),
                    selected: kbType == 'basic',
                    onSelected: (_) => setState(() => kbType = 'basic'),
                  ),
                  ChoiceChip(
                    label: Text(zh ? '问答知识库' : 'QA KB'),
                    selected: kbType == 'qa',
                    onSelected: (_) => setState(() => kbType = 'qa'),
                  ),
                  ChoiceChip(
                    label: Text(zh ? '结构化知识库' : 'Structured KB'),
                    selected: kbType == 'structured',
                    onSelected: (_) => setState(() => kbType = 'structured'),
                  ),
                  ChoiceChip(
                    label: Text(zh ? '向量索引知识库' : 'Vector index KB'),
                    selected: kbType == 'vector',
                    onSelected: (_) => setState(() => kbType = 'vector'),
                  ),
                ]),
                const SizedBox(height: 8),
                Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(zh ? '使用 LLM 增强构建' : 'Use LLM enhancement'),
                    subtitle: Text(zh
                        ? '默认关闭；开启后使用已授权 Provider，不写入明文 secret。'
                        : 'Off by default; when enabled it uses authorized Provider without plaintext secrets.'),
                    value: llmEnhance,
                    onChanged: (value) => setState(() => llmEnhance = value),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final item in const ['local', 'qdrant'])
                    ChoiceChip(
                      label: Text(_knowledgeStorageLabel(item, zh)),
                      selected: storageTarget == item,
                      onSelected: (_) => setState(() {
                        storageTarget = item;
                        buildStep = 5;
                      }),
                    ),
                ]),
              ],
            ),
          ),
          bottom: _EqualActionRow(children: [
            _PrimaryProductAction(
              label: zh ? '选择已导入文档' : 'Select imported documents',
              icon: Icons.library_books_outlined,
              onPressed: sourceRecords.isNotEmpty
                  ? () => setState(() {
                        if (selectedSourceIds.length ==
                            availableSourceIds.length) {
                          selectedSourceIds.clear();
                        } else {
                          selectedSourceIds
                            ..clear()
                            ..addAll(availableSourceIds);
                        }
                        buildStep = 1;
                      })
                  : null,
            ),
            _PrimaryProductAction(
              label: zh ? '开始构建知识库' : 'Build Knowledge Base',
              icon: Icons.build_outlined,
              onPressed: runtime.running || rc6 == null || !buildReady
                  ? null
                  : () {
                      rc6.buildKnowledgeBase(
                          documentIds:
                              selectedSourceIds.toList(growable: false));
                    },
            ),
            _PrimaryProductAction(
              label: zh ? '从标准包构建' : 'Build from package',
              icon: Icons.inventory_2_outlined,
              onPressed: runtime.running ||
                      rc6 == null ||
                      !runtime.hasStandardKnowledgePackage
                  ? null
                  : () => rc6.buildKnowledgeBaseFromStandardPackage(),
            ),
            _DisplayAction(
              label: zh ? '删除旧知识库版本' : 'Delete old KB version',
              icon: Icons.delete_outline,
              onPressed: runtime.hasKnowledgeBase
                  ? () => _confirmAndDeleteKnowledgeBase(rc6)
                  : null,
            ),
          ]),
        ),
      );
      final artifacts = _FillProductPanel(
        keyName: 'selected-package-detail',
        icon: Icons.folder_open_outlined,
        title: zh ? '构建产物' : 'Build Artifacts',
        child: _LocalScrollBox(
          child: Column(
            children: [
              _MetricStrip(
                items: [
                  _MetricDatum(
                      label: zh ? '来源' : 'Sources',
                      value: runtime.sourceCount.toString(),
                      detail: zh ? '已选文档' : 'selected docs',
                      icon: Icons.article_outlined),
                  _MetricDatum(
                      label: 'chunks',
                      value: runtime.chunkCount.toString(),
                      detail: zh ? '本地索引' : 'local index',
                      icon: Icons.segment_outlined),
                  _MetricDatum(
                      label: zh ? '质量报告' : 'Quality',
                      value:
                          runtime.qualityReportPath.isNotEmpty ? '已生成' : '等待',
                      detail: zh ? '可查看' : 'viewable',
                      icon: Icons.verified_outlined),
                ],
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              if (knowledgeBases.isNotEmpty) ...[
                _SectionCaption(zh ? '知识库列表' : 'Knowledge bases'),
                const SizedBox(height: 8),
                _ProductTable(
                  columns: zh
                      ? ['ID', '名称', '版本', '来源', 'chunks', '状态']
                      : [
                          'ID',
                          'Name',
                          'Version',
                          'Sources',
                          'Chunks',
                          'Status'
                        ],
                  rows: knowledgeBases
                      .map((kb) => [
                            kb.id,
                            kb.name,
                            kb.currentVersion.isEmpty
                                ? (zh ? 'v1' : 'v1')
                                : kb.currentVersion,
                            kb.sourceCount.toString(),
                            kb.chunkCount.toString(),
                            kb.status,
                          ])
                      .toList(growable: false),
                ),
                const SizedBox(height: 8),
                _EqualActionRow(children: [
                  _PrimaryProductAction(
                    label: zh ? '复制知识库' : 'Copy KB',
                    icon: Icons.copy_outlined,
                    onPressed: rc6 == null || knowledgeBases.isEmpty
                        ? null
                        : () => rc6.copyKnowledgeBase(knowledgeBases.first.id),
                  ),
                  _PrimaryProductAction(
                    label: zh ? '合并知识库' : 'Merge KBs',
                    icon: Icons.merge_type_outlined,
                    onPressed: rc6 == null || knowledgeBases.length < 2
                        ? null
                        : () => rc6.mergeKnowledgeBases(
                            knowledgeBases.take(2).map((kb) => kb.id).toList()),
                  ),
                ]),
                const SizedBox(height: 8),
                _EqualActionRow(children: [
                  _PrimaryProductAction(
                    label: zh ? '拆分知识库' : 'Split KB',
                    icon: Icons.call_split_outlined,
                    onPressed: rc6 == null || knowledgeBases.isEmpty
                        ? null
                        : () => rc6.splitKnowledgeBase(knowledgeBases.first.id),
                  ),
                  _DisplayAction(
                    label: zh ? '删除知识库记录' : 'Delete KB record',
                    icon: Icons.delete_outline,
                    onPressed: rc6 == null || knowledgeBases.isEmpty
                        ? null
                        : () => _confirmAndDeleteKnowledgeBase(rc6),
                  ),
                ]),
                const SizedBox(height: _DesktopGrid.gutter),
                _SectionCaption(zh ? '迭代更新与版本管理' : 'Iteration and versions'),
                const SizedBox(height: 8),
                _ProductTable(
                  columns: zh
                      ? ['能力', '真实产物', '状态']
                      : ['Capability', 'Artifact', 'Status'],
                  rows:
                      _knowledgeVersionRows(knowledgeBases.first, runtime, zh),
                ),
                const SizedBox(height: 8),
                _EqualActionRow(children: [
                  _PrimaryProductAction(
                    label: zh ? '增量更新' : 'Incremental update',
                    icon: Icons.update_outlined,
                    onPressed: rc6 == null || knowledgeBases.isEmpty
                        ? null
                        : () => rc6.updateKnowledgeBaseIncremental(
                            knowledgeBases.first.id),
                  ),
                  _PrimaryProductAction(
                    label: zh ? '全量重建' : 'Full rebuild',
                    icon: Icons.refresh_outlined,
                    onPressed: rc6 == null || knowledgeBases.isEmpty
                        ? null
                        : () => rc6
                            .rebuildKnowledgeBaseFull(knowledgeBases.first.id),
                  ),
                ]),
                const SizedBox(height: 8),
                _EqualActionRow(children: [
                  _PrimaryProductAction(
                    label: zh ? '版本对比' : 'Compare versions',
                    icon: Icons.compare_arrows_outlined,
                    onPressed: rc6 == null || knowledgeBases.isEmpty
                        ? null
                        : () => rc6.compareKnowledgeBaseVersions(
                            knowledgeBases.first.id),
                  ),
                  _DisplayAction(
                    label: zh ? '回滚上一版本' : 'Rollback previous version',
                    icon: Icons.restore_outlined,
                    onPressed: rc6 == null ||
                            knowledgeBases.isEmpty ||
                            knowledgeBases.first.versionCount < 2
                        ? null
                        : () => rc6.rollbackKnowledgeBaseVersion(
                            knowledgeBases.first.id),
                  ),
                ]),
                const SizedBox(height: _DesktopGrid.gutter),
              ],
              _ProductTable(
                columns:
                    zh ? ['产物', '状态', '查看'] : ['Artifact', 'Status', 'View'],
                rows: _knowledgeArtifactRows(runtime, zh),
              ),
              const SizedBox(height: 8),
              _EqualActionRow(children: [
                _DisplayAction(
                  label: zh ? '查看质量报告' : 'View quality report',
                  icon: Icons.rule_outlined,
                  onPressed: () => setState(() => qualityReportPrepared = true),
                ),
                if (qualityReportPrepared)
                  _RuntimeFeedbackBanner(
                    title: zh ? '质量报告评分标准' : 'Quality report scoring rubric',
                    detail: runtime.qualityReportPath.isEmpty
                        ? (zh
                            ? '等待 quality_report.json。'
                            : 'Waiting for quality_report.json.')
                        : (zh
                            ? '评分 = 非空 chunks、来源覆盖、QA/cards 完整性和 manifest 可追踪性。'
                            : 'Score = non-empty chunks, source coverage, QA/cards completeness, and manifest traceability.'),
                    tone: runtime.qualityReportPath.isEmpty
                        ? _StatusTone.warning
                        : _StatusTone.success,
                    icon: Icons.rule_outlined,
                  ),
              ]),
            ],
          ),
        ),
      );
      if (!wide) {
        return Column(children: [
          builder,
          const SizedBox(height: _DesktopGrid.gutter),
          artifacts
        ]);
      }
      return _EqualHeightRow(
        height: 656,
        flexes: const [7, 5],
        children: [builder, artifacts],
      );
    });
  }
}

String _knowledgeTypeLabel(String value, bool zh) {
  return switch (value) {
    'qa' => zh ? '问答知识库' : 'QA KB',
    'structured' => zh ? '结构化知识库' : 'Structured KB',
    'vector' => zh ? '向量索引知识库' : 'Vector index KB',
    _ => zh ? '基础知识库' : 'Basic KB',
  };
}

String _knowledgeStorageLabel(String value, bool zh) {
  return switch (value) {
    'qdrant' => zh ? 'Qdrant 本机向量库' : 'Local Qdrant vector DB',
    _ => zh ? '本地文件索引' : 'Local file index',
  };
}

List<List<String>> _knowledgeArtifactRows(Rc6RuntimeState runtime, bool zh) {
  List<String> row(String name, String path, String waiting,
      {String? readyStatus}) {
    final ready = path.isNotEmpty;
    return [
      name,
      ready ? (readyStatus ?? (zh ? '完成' : 'Done')) : (zh ? '等待' : 'Waiting'),
      ready ? _displayNameForPath(path) : waiting,
    ];
  }

  return [
    row('source_manifest.json', runtime.sourceManifestPath,
        zh ? '来源清单' : 'source manifest'),
    row(
        'standard_package_manifest.json',
        runtime.standardKnowledgePackageManifestPath,
        zh ? '标准知识包' : 'standard package'),
    row('content_package.jsonl', runtime.standardKnowledgePackageContentPath,
        zh ? '标准包内容' : 'package content'),
    row('manifest.json', runtime.kbManifestPath, zh ? '知识库清单' : 'KB manifest'),
    row('chunks.jsonl', runtime.chunksPath, 'chunks.jsonl'),
    row('source_map.json', runtime.sourceMapPath, 'source_map.json'),
    row('index_metadata.json', runtime.indexMetadataPath,
        'index_metadata.json'),
    row('index_profile.json', runtime.indexProfilePath, 'index_profile.json'),
    row('keyword_index.json', runtime.keywordIndexPath, 'keyword_index.json'),
    row('vector_index_reference.json', runtime.vectorIndexReferencePath,
        'vector_index_reference.json'),
    row('metadata_index.json', runtime.metadataIndexPath,
        'metadata_index.json'),
    row('citation_index.json', runtime.citationIndexPath,
        'citation_index.json'),
    row('memory_index_reference.json', runtime.memoryIndexReferencePath,
        'memory_index_reference.json'),
    row('index_build_report.json', runtime.indexBuildReportPath,
        'index_build_report.json'),
    row('quality_report.json', runtime.qualityReportPath,
        zh ? '质量报告' : 'quality report',
        readyStatus: zh ? '通过' : 'Passed'),
    row('build.log', runtime.buildLogPath, 'build.log'),
    row('error.log', runtime.errorLogPath, 'error.log'),
  ];
}

List<List<String>> _knowledgeVersionRows(
    Rc6KnowledgeBaseRecord kb, Rc6RuntimeState runtime, bool zh) {
  final compareReady = kb.versionComparePath.isNotEmpty;
  final rollbackReady = kb.versionCount > 1;
  return [
    [
      zh ? '版本记录' : 'Version history',
      kb.currentVersion.isEmpty ? 'v1' : kb.currentVersion,
      zh ? '${kb.versionCount} 个版本' : '${kb.versionCount} versions',
    ],
    [
      zh ? '构建日志' : 'Build log',
      runtime.buildLogPath.isEmpty
          ? (zh ? '等待构建' : 'Waiting build')
          : _displayNameForPath(runtime.buildLogPath),
      runtime.buildLogPath.isEmpty ? (zh ? '未生成' : 'Not generated') : 'ready',
    ],
    [
      zh ? '版本对比' : 'Version compare',
      compareReady
          ? _displayNameForPath(kb.versionComparePath)
          : (zh ? '点击版本对比后生成' : 'Run compare to generate'),
      compareReady ? (zh ? '已生成' : 'Generated') : (zh ? '点击生成' : 'Run compare'),
    ],
    [
      zh ? '回滚' : 'Rollback',
      rollbackReady
          ? (zh ? '可回滚到上一版本' : 'Previous version available')
          : (zh ? '更新后可回滚' : 'Available after update'),
      rollbackReady ? (zh ? '可用' : 'Ready') : (zh ? '等待版本' : 'Need version'),
    ],
  ];
}

class _KnowledgeBuildStep {
  const _KnowledgeBuildStep(
      this.label, this.detail, this.icon, this.done, this.onPressed);

  final String label;
  final String detail;
  final IconData icon;
  final bool done;
  final VoidCallback? onPressed;
}

class _KnowledgeBuildActionGrid extends StatelessWidget {
  const _KnowledgeBuildActionGrid({
    required this.zh,
    required this.activeStep,
    required this.steps,
  });

  final bool zh;
  final int activeStep;
  final List<_KnowledgeBuildStep> steps;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 820
          ? 3
          : constraints.maxWidth >= 520
              ? 2
              : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: steps.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: _DesktopGrid.gutter,
          mainAxisSpacing: _DesktopGrid.gutter,
          mainAxisExtent: 92,
        ),
        itemBuilder: (context, index) {
          final step = steps[index];
          final selected = activeStep == index || step.done;
          return Material(
            color: selected
                ? colors.primary.withValues(alpha: 0.08)
                : colors.surface,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: step.onPressed,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? colors.primary : colors.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      step.done ? Icons.check_circle_outline : step.icon,
                      size: 20,
                      color:
                          selected ? colors.primary : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(step.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text(step.detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _KnowledgeVectorIndexView extends StatelessWidget {
  const _KnowledgeVectorIndexView({required this.zh});

  final bool zh;

  @override
  Widget build(BuildContext context) {
    final runtime =
        _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final indexPanel = _ProductPanel(
        keyName: 'knowledge-vector-index',
        icon: Icons.hub_outlined,
        title: zh ? '向量索引中心' : 'Vector Index Center',
        children: [
          _ProductTable(
            columns: zh
                ? ['索引', '知识库', '模型', '维度', '状态', '分类']
                : ['Index', 'Base', 'Model', 'Dims', 'Status', 'Class'],
            rows: zh
                ? [
                    [
                      'local_kb_chunks',
                      runtime.hasKnowledgeBase ? '真实输入知识库' : '等待知识库',
                      '本地 chunks.jsonl',
                      runtime.chunkCount.toString(),
                      runtime.hasKnowledgeBase ? '本地索引可用' : '等待构建',
                      runtime.hasKnowledgeBase ? '可用' : '请先构建'
                    ],
                    [
                      'local_cards_qa',
                      runtime.cardsPath.isNotEmpty
                          ? 'cards / qa_pairs'
                          : '等待产物',
                      '本地 JSONL',
                      runtime.cardsPath.isNotEmpty ? 'ready' : '-',
                      runtime.cardsPath.isNotEmpty ? '已生成' : '等待构建',
                      runtime.cardsPath.isNotEmpty ? '可用' : '请先构建'
                    ],
                    [
                      'external_vector_db',
                      '外部向量库',
                      '未配置',
                      '-',
                      '使用本地索引',
                      '设置中可配置'
                    ],
                  ]
                : [
                    [
                      'local_kb_chunks',
                      runtime.hasKnowledgeBase
                          ? 'Real input Knowledge Base'
                          : 'Waiting for KB',
                      'Local chunks.jsonl',
                      runtime.chunkCount.toString(),
                      runtime.hasKnowledgeBase
                          ? 'Local index ready'
                          : 'Build first',
                      runtime.hasKnowledgeBase ? 'Available' : 'Build first'
                    ],
                    [
                      'local_cards_qa',
                      runtime.cardsPath.isNotEmpty
                          ? 'cards / qa_pairs'
                          : 'Waiting',
                      'Local JSONL',
                      runtime.cardsPath.isNotEmpty ? 'ready' : '-',
                      runtime.cardsPath.isNotEmpty
                          ? 'Generated'
                          : 'Build first',
                      runtime.cardsPath.isNotEmpty ? 'Available' : 'Build first'
                    ],
                    [
                      'external_vector_db',
                      'External Vector DB',
                      'Not configured',
                      '-',
                      'Using local index',
                      'Configurable in Settings'
                    ],
                  ],
          ),
        ],
      );
      final detail = _ProductPanel(
        icon: Icons.tune_outlined,
        title: zh ? '索引配置与边界' : 'Index Config and Boundary',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? '排序' : 'Sort',
              value: zh
                  ? '质量分 / 更新时间 / chunks'
                  : 'Quality / updated time / chunks'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '批量操作' : 'Bulk actions',
              value: zh
                  ? '重建、验证、归档均需本地证据'
                  : 'Rebuild, validate, archive require local evidence'),
          const SizedBox(height: 8),
          _DisplayAction(
            label: zh ? '去设置中配置向量库连接' : 'Configure vector DB in Settings',
            icon: Icons.settings_outlined,
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          indexPanel,
          const SizedBox(height: _DesktopGrid.gutter),
          detail
        ]);
      }
      return _EqualHeightRow(
        height: 326,
        flexes: const [7, 4],
        children: [indexPanel, detail],
      );
    });
  }
}

class _KnowledgeQualityRecordsView extends StatelessWidget {
  const _KnowledgeQualityRecordsView({required this.zh});

  final bool zh;

  @override
  Widget build(BuildContext context) {
    final runtime =
        _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
    final qualityReady = runtime.qualityReportPath.isNotEmpty;
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final records = _ProductPanel(
        keyName: 'knowledge-quality-records',
        icon: Icons.rule_outlined,
        title: zh ? '质量与验证记录' : 'Quality and Validation Records',
        children: [
          _MetricStrip(
            items: [
              _MetricDatum(
                  label: zh ? '准确性' : 'Accuracy',
                  value: qualityReady ? 'pass' : '-',
                  detail: zh ? '质量报告' : 'quality report',
                  icon: Icons.track_changes_outlined),
              _MetricDatum(
                  label: zh ? '覆盖率' : 'Coverage',
                  value: runtime.sourceCount.toString(),
                  detail: zh ? '来源文档' : 'sources',
                  icon: Icons.pie_chart_outline),
              _MetricDatum(
                  label: zh ? '冲突' : 'Conflicts',
                  value: qualityReady ? '0' : '-',
                  detail: zh ? '本地质量门禁' : 'local quality gate',
                  icon: Icons.warning_amber_outlined),
            ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _ProductTable(
            columns: zh
                ? ['检查项', '状态', '证据', '建议']
                : ['Check', 'Status', 'Evidence', 'Suggestion'],
            rows: zh
                ? [
                    [
                      '解析完整性',
                      runtime.parseReportPath.isNotEmpty ? '通过' : '等待解析',
                      runtime.parseReportPath.isNotEmpty
                          ? _displayNameForPath(runtime.parseReportPath)
                          : 'parse_report.json',
                      runtime.parseReportPath.isNotEmpty ? '保持' : '先解析来源'
                    ],
                    [
                      '重复片段',
                      qualityReady ? '通过' : '等待构建',
                      qualityReady
                          ? _displayNameForPath(runtime.qualityReportPath)
                          : 'quality_report.json',
                      qualityReady ? '已生成建议' : '先构建知识库'
                    ],
                    [
                      'cards / qa_pairs',
                      runtime.cardsPath.isNotEmpty ? '已生成' : '等待构建',
                      runtime.cardsPath.isNotEmpty
                          ? _displayNameForPath(runtime.cardsPath)
                          : 'cards.jsonl',
                      runtime.qaPairsPath.isNotEmpty ? '可检索' : '先构建知识库'
                    ],
                    ['外部新鲜度', '授权后启用', '设置联网 Provider 后执行', '不影响本地知识库'],
                  ]
                : [
                    [
                      'Parse integrity',
                      runtime.parseReportPath.isNotEmpty ? 'Passed' : 'Waiting',
                      runtime.parseReportPath.isNotEmpty
                          ? _displayNameForPath(runtime.parseReportPath)
                          : 'parse_report.json',
                      runtime.parseReportPath.isNotEmpty
                          ? 'Keep'
                          : 'Parse sources first'
                    ],
                    [
                      'Duplicate chunks',
                      qualityReady ? 'Passed' : 'Waiting',
                      qualityReady
                          ? _displayNameForPath(runtime.qualityReportPath)
                          : 'quality_report.json',
                      qualityReady ? 'Suggestions generated' : 'Build KB first'
                    ],
                    [
                      'cards / qa_pairs',
                      runtime.cardsPath.isNotEmpty ? 'Generated' : 'Waiting',
                      runtime.cardsPath.isNotEmpty
                          ? _displayNameForPath(runtime.cardsPath)
                          : 'cards.jsonl',
                      runtime.qaPairsPath.isNotEmpty
                          ? 'Searchable'
                          : 'Build KB first'
                    ],
                    [
                      'External freshness',
                      'Enable after authorization',
                      'Configure network Provider first',
                      'Does not block local KB'
                    ],
                  ],
          ),
        ],
      );
      final detail = _ProductPanel(
        icon: Icons.assignment_turned_in_outlined,
        title: zh ? '验证记录详情' : 'Validation Record Detail',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? '验证范围' : 'Scope',
              value: zh ? '仅针对已有本地证据' : 'Existing local evidence only'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '外部比对' : 'External comparison',
              value: zh
                  ? '本地/手动证据与实时外部比对均已验收；联网执行需 opt-in'
                  : 'Local/manual evidence and live external comparison are accepted; network execution requires opt-in'),
          const SizedBox(height: 8),
          _DisplayAction(
            label: zh ? '查看质量报告证据' : 'View quality report evidence',
            icon: Icons.receipt_long_outlined,
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          records,
          const SizedBox(height: _DesktopGrid.gutter),
          detail
        ]);
      }
      return _EqualHeightRow(
        height: 408,
        flexes: const [7, 4],
        children: [records, detail],
      );
    });
  }
}
