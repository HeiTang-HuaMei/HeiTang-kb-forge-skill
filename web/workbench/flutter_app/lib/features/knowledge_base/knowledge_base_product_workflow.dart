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
        ? ['知识库', '检索设置', '质量记录', '高级边界']
        : [
            'Knowledge Bases',
            'Search Settings',
            'Quality Records',
            'Advanced Boundary'
          ];
    return _FigmaPageCanvas(children: [
      SizedBox(
        height: 78,
        child: _FigmaCard(
          keyName: 'knowledge-boundary-note',
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          background: _HTKWTokens.goldSoft,
          borderColor: _HTKWTokens.gold.withValues(alpha: 0.22),
          child: Row(
            children: [
              const Icon(Icons.account_tree_outlined,
                  color: _HTKWTokens.gold, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _zh
                      ? '从文档库选择已整理资料生成知识库；测试、来源和版本操作都绑定真实本地产物。'
                      : 'Build knowledge bases from organized library materials; tests, sources, and versions bind to real local artifacts.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _HTKWTokens.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
      _PageTabs(
        tabs: tabs,
        selectedIndex: selectedTab,
        onSelected: onTabSelected,
      ),
      SizedBox(
        height: 560,
        child: selectedTab == 1
            ? _KnowledgeVectorIndexView(zh: _zh)
            : selectedTab == 2
                ? _KnowledgeQualityRecordsView(zh: _zh)
                : selectedTab == 3
                    ? _KnowledgeStorageBoundaryView(zh: _zh)
                    : _KnowledgePackageListView(zh: _zh, workspace: workspace),
      ),
      SizedBox(
        height: 48,
        child: _FigmaCard(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          background: _HTKWTokens.softSurface,
          child: Text(
            _zh
                ? '知识库只承接当前工作区文档库来源；外部来源核对未配置时显示需要设置。'
                : 'Knowledge bases use only current workspace sources; external checking stays gated until configured.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _HTKWTokens.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    ]);
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
      title: zh ? '高级边界' : 'Advanced Boundary',
      gap: true,
      subtitle: zh
          ? '外部服务、存储和工作区归设置管理；这里仅展示知识库侧引用边界。'
          : 'External services, storage, and workspace live in Settings; this only shows KB-side boundaries.',
      children: [
        _ProductTable(
          columns: zh ? ['能力', '当前分类', '说明'] : ['Capability', 'Class', 'Note'],
          rows: zh
              ? [
                  ['本地知识库', '可用', '依赖已有本地产物'],
                  ['专业检索服务', '未配置', '本地检索可用，可在设置配置'],
                  ['外部来源核对', '授权后可用', '网络权限开启后执行'],
                ]
              : [
                  [
                    'Local package',
                    'Available',
                    'Depends on existing local artifacts'
                  ],
                  [
                    'Professional retrieval service',
                    'Not configured',
                    'Local index available; configure in Settings'
                  ],
                  [
                    'External fact verification',
                    'Available after authorization',
                    'Runs after network authorization is configured'
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
    final knowledgeBases = runtime.knowledgeBases;
    final capabilityAuditReady = runtime.hasProviderCapabilityUserCatalog;
    final indexBackendStatus = runtime.vectorIndexReferencePath.isNotEmpty
        ? (zh ? '检索数据已生成' : 'Search data generated')
        : capabilityAuditReady
            ? (zh ? '当前配置可用，等待生成' : 'Configured, waiting build')
            : (zh ? '本地模式可用' : 'Local mode available');
    final embeddingStatus = capabilityAuditReady
        ? (zh ? '按当前配置记录' : 'Recorded by current profile')
        : (zh ? '使用本地模式' : 'Using local mode');
    final vectorStatus = runtime.vectorIndexReferencePath.isNotEmpty
        ? (zh ? '已绑定知识库检索数据' : 'Bound to KB search data')
        : capabilityAuditReady
            ? (zh ? '未连接时使用本地模式' : 'Falls back to local mode')
            : (zh ? '未配置专业检索服务' : 'Professional retrieval not configured');
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
                            '模型服务增强',
                            llmEnhance ? '启用，使用已配置模型服务' : '关闭，使用本地构建',
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
                                ? 'Enabled with configured model service'
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
                const SizedBox(height: _DesktopGrid.gutter),
                _ProductTable(
                  columns: zh
                      ? ['能力', '当前状态', '用户可见结果']
                      : ['Capability', 'Current status', 'User result'],
                  rows: zh
                      ? [
                          ['当前检索', indexBackendStatus, '知识库可生成和更新'],
                          ['文本理解', embeddingStatus, '配置变化时可能需要重建知识库'],
                          ['专业检索', vectorStatus, '连接失败不影响本地检索'],
                        ]
                      : [
                          [
                            'Current search',
                            indexBackendStatus,
                            'KB can be built and updated'
                          ],
                          [
                            'Text understanding',
                            embeddingStatus,
                            'Dimension changes require KB rebuild'
                          ],
                          [
                            'Professional retrieval',
                            vectorStatus,
                            'Local retrieval remains available on failure'
                          ],
                        ],
                ),
                if (sourceRecords.isNotEmpty) ...[
                  const SizedBox(height: _DesktopGrid.gutter),
                  _SectionCaption(zh ? '来源文档选择器' : 'Source document selector'),
                  const SizedBox(height: 8),
                  _ProductTable(
                    columns: zh
                        ? ['选择', '文档', '资料编号', '类型']
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
                    label: Text(zh ? '专业检索知识库' : 'Professional search KB'),
                    selected: kbType == 'vector',
                    onSelected: (_) => setState(() => kbType = 'vector'),
                  ),
                ]),
                const SizedBox(height: 8),
                Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                        zh ? '使用模型服务增强构建' : 'Use model service enhancement'),
                    subtitle: Text(zh
                        ? '默认关闭；开启后使用已授权模型服务，不写入明文密钥。'
                        : 'Off by default; when enabled it uses authorized model service without plaintext secrets.'),
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
              label: runtime.hasKnowledgeBase
                  ? (zh ? '更新知识库' : 'Update Knowledge Base')
                  : (zh ? '生成知识库' : 'Generate Knowledge Base'),
              icon: Icons.build_outlined,
              onPressed: runtime.running || rc6 == null || !buildReady
                  ? null
                  : () {
                      rc6.buildKnowledgeBase(
                          documentIds:
                              selectedSourceIds.toList(growable: false));
                    },
            ),
            _MoreActionsButton(
              label: zh ? '更多知识库操作' : 'More KB actions',
              actions: [
                _MoreMenuAction(
                  label: zh ? '选择全部文档' : 'Select all documents',
                  icon: Icons.library_books_outlined,
                  enabled: sourceRecords.isNotEmpty,
                  onSelected: () => setState(() {
                    if (selectedSourceIds.length == availableSourceIds.length) {
                      selectedSourceIds.clear();
                    } else {
                      selectedSourceIds
                        ..clear()
                        ..addAll(availableSourceIds);
                    }
                    buildStep = 1;
                  }),
                ),
                _MoreMenuAction(
                  label: zh ? '从标准包构建' : 'Build from package',
                  icon: Icons.inventory_2_outlined,
                  enabled: !runtime.running &&
                      rc6 != null &&
                      runtime.hasStandardKnowledgePackage,
                  onSelected: () =>
                      rc6?.buildKnowledgeBaseFromStandardPackage(),
                ),
                _MoreMenuAction(
                  label: zh ? '删除知识库' : 'Delete KB',
                  icon: Icons.delete_outline,
                  destructive: true,
                  enabled: runtime.hasKnowledgeBase,
                  onSelected: () => _confirmAndDeleteKnowledgeBase(rc6),
                ),
              ],
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
                      label: zh ? '片段' : 'Segments',
                      value: runtime.chunkCount.toString(),
                      detail: zh ? '本地模式' : 'local mode',
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
                      ? ['ID', '名称', '版本', '来源', '片段', '状态']
                      : [
                          'ID',
                          'Name',
                          'Version',
                          'Sources',
                          'Segments',
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
                const SizedBox(height: 8),
                _MoreActionsButton(
                  label: zh ? '更多版本操作' : 'More version actions',
                  actions: [
                    _MoreMenuAction(
                      label: zh ? '复制知识库' : 'Copy KB',
                      icon: Icons.copy_outlined,
                      enabled: rc6 != null && knowledgeBases.isNotEmpty,
                      onSelected: () =>
                          rc6?.copyKnowledgeBase(knowledgeBases.first.id),
                    ),
                    _MoreMenuAction(
                      label: zh ? '合并知识库' : 'Merge KBs',
                      icon: Icons.merge_type_outlined,
                      enabled: rc6 != null && knowledgeBases.length >= 2,
                      onSelected: () => rc6?.mergeKnowledgeBases(
                          knowledgeBases.take(2).map((kb) => kb.id).toList()),
                    ),
                    _MoreMenuAction(
                      label: zh ? '拆分知识库' : 'Split KB',
                      icon: Icons.call_split_outlined,
                      enabled: rc6 != null && knowledgeBases.isNotEmpty,
                      onSelected: () =>
                          rc6?.splitKnowledgeBase(knowledgeBases.first.id),
                    ),
                    _MoreMenuAction(
                      label: zh ? '增量更新' : 'Incremental update',
                      icon: Icons.update_outlined,
                      enabled: rc6 != null && knowledgeBases.isNotEmpty,
                      onSelected: () => rc6?.updateKnowledgeBaseIncremental(
                          knowledgeBases.first.id),
                    ),
                    _MoreMenuAction(
                      label: zh ? '全量重建' : 'Full rebuild',
                      icon: Icons.refresh_outlined,
                      enabled: rc6 != null && knowledgeBases.isNotEmpty,
                      onSelected: () => rc6
                          ?.rebuildKnowledgeBaseFull(knowledgeBases.first.id),
                    ),
                    _MoreMenuAction(
                      label: zh ? '版本对比' : 'Compare versions',
                      icon: Icons.compare_arrows_outlined,
                      enabled: rc6 != null && knowledgeBases.isNotEmpty,
                      onSelected: () => rc6?.compareKnowledgeBaseVersions(
                          knowledgeBases.first.id),
                    ),
                    _MoreMenuAction(
                      label: zh ? '回滚上一版本' : 'Rollback previous version',
                      icon: Icons.restore_outlined,
                      enabled: rc6 != null &&
                          knowledgeBases.isNotEmpty &&
                          knowledgeBases.first.versionCount >= 2,
                      onSelected: () => rc6?.rollbackKnowledgeBaseVersion(
                          knowledgeBases.first.id),
                    ),
                    _MoreMenuAction(
                      label: zh ? '删除知识库记录' : 'Delete KB record',
                      icon: Icons.delete_outline,
                      destructive: true,
                      enabled: rc6 != null && knowledgeBases.isNotEmpty,
                      onSelected: () => _confirmAndDeleteKnowledgeBase(rc6),
                    ),
                  ],
                ),
                const SizedBox(height: _DesktopGrid.gutter),
              ],
              _ProductTable(
                columns: zh ? ['项目', '状态', '说明'] : ['Item', 'Status', 'Note'],
                rows: _knowledgeArtifactRows(runtime, zh),
              ),
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
    'vector' => zh ? '专业检索知识库' : 'Professional search KB',
    _ => zh ? '基础知识库' : 'Basic KB',
  };
}

String _knowledgeStorageLabel(String value, bool zh) {
  return switch (value) {
    'qdrant' => zh ? '专业检索服务' : 'Professional retrieval service',
    _ => zh ? '本地模式' : 'Local mode',
  };
}

List<List<String>> _knowledgeArtifactRows(Rc6RuntimeState runtime, bool zh) {
  List<String> row(String name, bool ready, String waiting,
      {String? readyStatus}) {
    return [
      name,
      ready ? (readyStatus ?? (zh ? '完成' : 'Done')) : (zh ? '等待' : 'Waiting'),
      waiting,
    ];
  }

  return [
    row(
      zh ? '来源文档' : 'Source documents',
      runtime.sourceManifestPath.isNotEmpty,
      zh ? '${runtime.sourceCount} 个来源' : '${runtime.sourceCount} sources',
    ),
    row(
      zh ? '标准知识包' : 'Standard package',
      runtime.standardKnowledgePackageManifestPath.isNotEmpty,
      zh ? '可用于重建知识库' : 'Reusable for KB rebuild',
    ),
    row(
      zh ? '知识库' : 'Knowledge Base',
      runtime.kbManifestPath.isNotEmpty,
      runtime.hasKnowledgeBase
          ? (zh ? '可检索' : 'Searchable')
          : (zh ? '等待构建' : 'Waiting build'),
    ),
    row(
      zh ? '检索数据' : 'Search data',
      runtime.indexMetadataPath.isNotEmpty || runtime.chunksPath.isNotEmpty,
      runtime.chunkCount > 0
          ? (zh
              ? '${runtime.chunkCount} 个片段'
              : '${runtime.chunkCount} segments')
          : (zh ? '等待整理' : 'Waiting organization'),
    ),
    row(zh ? '质量记录' : 'Quality records', runtime.qualityReportPath.isNotEmpty,
        zh ? '质量报告' : 'Quality report',
        readyStatus: zh ? '通过' : 'Passed'),
  ];
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
        title: zh ? '检索服务状态' : 'Search Service Status',
        children: [
          _ProductTable(
            columns: zh
                ? ['检索方式', '知识库', '服务', '规模', '状态', '分类']
                : [
                    'Search mode',
                    'Base',
                    'Service',
                    'Scale',
                    'Status',
                    'Class'
                  ],
            rows: zh
                ? [
                    [
                      '本地知识库索引',
                      runtime.hasKnowledgeBase ? '真实输入知识库' : '等待知识库',
                      '本地索引',
                      runtime.chunkCount.toString(),
                      runtime.hasKnowledgeBase ? '本地索引可用' : '等待构建',
                      runtime.hasKnowledgeBase ? '可用' : '请先构建'
                    ],
                    [
                      '知识卡片与问答',
                      runtime.cardsPath.isNotEmpty ? '已生成' : '等待产物',
                      '本地索引',
                      runtime.cardsPath.isNotEmpty ? 'ready' : '-',
                      runtime.cardsPath.isNotEmpty ? '已生成' : '等待构建',
                      runtime.cardsPath.isNotEmpty ? '可用' : '请先构建'
                    ],
                    ['专业检索服务', '专业模式', '未配置', '-', '使用本地索引', '设置中可配置'],
                  ]
                : [
                    [
                      'Local KB index',
                      runtime.hasKnowledgeBase
                          ? 'Real input Knowledge Base'
                          : 'Waiting for KB',
                      'Local index',
                      runtime.chunkCount.toString(),
                      runtime.hasKnowledgeBase
                          ? 'Local index ready'
                          : 'Build first',
                      runtime.hasKnowledgeBase ? 'Available' : 'Build first'
                    ],
                    [
                      'Knowledge cards and QA',
                      runtime.cardsPath.isNotEmpty ? 'Generated' : 'Waiting',
                      'Local index',
                      runtime.cardsPath.isNotEmpty ? 'ready' : '-',
                      runtime.cardsPath.isNotEmpty
                          ? 'Generated'
                          : 'Build first',
                      runtime.cardsPath.isNotEmpty ? 'Available' : 'Build first'
                    ],
                    [
                      'Professional search service',
                      'Professional mode',
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
        title: zh ? '检索配置与边界' : 'Search Config and Boundary',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? '排序' : 'Sort',
              value: zh
                  ? '质量分 / 更新时间 / 片段数'
                  : 'Quality / updated time / chunk count'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '批量操作' : 'Bulk actions',
              value: zh
                  ? '重建、验证、归档均需本地证据'
                  : 'Rebuild, validate, archive require local evidence'),
          const SizedBox(height: 8),
          _DisplayAction(
            label: zh
                ? '去设置中配置专业检索服务'
                : 'Configure professional search in Settings',
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
                      runtime.parseReportPath.isNotEmpty ? '已生成' : '等待解析结果',
                      runtime.parseReportPath.isNotEmpty ? '保持' : '先解析来源'
                    ],
                    [
                      '重复片段',
                      qualityReady ? '通过' : '等待构建',
                      qualityReady ? '已生成' : '等待质量记录',
                      qualityReady ? '已生成建议' : '先构建知识库'
                    ],
                    [
                      '知识卡片与问答',
                      runtime.cardsPath.isNotEmpty ? '已生成' : '等待构建',
                      runtime.cardsPath.isNotEmpty ? '已生成' : '等待知识库构建',
                      runtime.qaPairsPath.isNotEmpty ? '可检索' : '先构建知识库'
                    ],
                    ['外部新鲜度', '授权后启用', '设置外部来源核对服务后执行', '不影响本地知识库'],
                  ]
                : [
                    [
                      'Parse integrity',
                      runtime.parseReportPath.isNotEmpty ? 'Passed' : 'Waiting',
                      runtime.parseReportPath.isNotEmpty
                          ? 'Generated'
                          : 'Waiting parse results',
                      runtime.parseReportPath.isNotEmpty
                          ? 'Keep'
                          : 'Parse sources first'
                    ],
                    [
                      'Duplicate chunks',
                      qualityReady ? 'Passed' : 'Waiting',
                      qualityReady ? 'Generated' : 'Waiting quality records',
                      qualityReady ? 'Suggestions generated' : 'Build KB first'
                    ],
                    [
                      'Knowledge cards and QA',
                      runtime.cardsPath.isNotEmpty ? 'Generated' : 'Waiting',
                      runtime.cardsPath.isNotEmpty
                          ? 'Generated'
                          : 'Waiting KB build',
                      runtime.qaPairsPath.isNotEmpty
                          ? 'Searchable'
                          : 'Build KB first'
                    ],
                    [
                      'External freshness',
                      'Enable after authorization',
                      'Configure external source checking first',
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
