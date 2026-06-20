part of '../../main.dart';

class _DocumentLibraryView extends StatefulWidget {
  const _DocumentLibraryView({
    required this.zh,
    required this.onBuildKnowledgeBase,
  });

  final bool zh;
  final VoidCallback onBuildKnowledgeBase;

  @override
  State<_DocumentLibraryView> createState() => _DocumentLibraryViewState();
}

class _DocumentLibraryViewState extends State<_DocumentLibraryView> {
  bool indexed = true;
  String selectedType = 'all';
  String sortMode = 'name_asc';
  int selectedDocumentIndex = 0;
  final Set<String> selectedDocuments = <String>{};
  final TextEditingController _documentSearchController =
      TextEditingController();

  bool get zh => widget.zh;

  @override
  void dispose() {
    _documentSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final hasRealDocument = runtime.hasImportedFile;
    final parsed = runtime.parseReportPath.isNotEmpty;
    final chunkCount = runtime.chunkCount;
    final importedSources = runtime.sourceRecords.isEmpty
        ? <Rc6SourceRecord>[
            for (final name in runtime.sourceNames)
              Rc6SourceRecord(
                documentId: '',
                sourceName: name,
                relativePath: name,
                sourceType: 'local_file',
                extension: '',
                sizeBytes: 0,
                wordCount: 0,
                imageCount: 0,
                tableCount: 0,
                linkCount: 0,
                structureStatus: 'not_scanned',
              ),
            if (runtime.sourceNames.isEmpty && hasRealDocument)
              Rc6SourceRecord(
                documentId: '',
                sourceName: _displayNameForPath(runtime.selectedFilePath),
                relativePath: _displayNameForPath(runtime.selectedFilePath),
                sourceType: 'local_file',
                extension: '',
                sizeBytes: 0,
                wordCount: 0,
                imageCount: 0,
                tableCount: 0,
                linkCount: 0,
                structureStatus: 'not_scanned',
              ),
          ]
        : runtime.sourceRecords;
    final searchText = _documentSearchController.text.trim().toLowerCase();
    final filteredSources = (selectedType == 'all'
            ? importedSources
            : importedSources.where(
                (source) => _documentTypeForSource(source) == selectedType))
        .where((source) =>
            searchText.isEmpty ||
            source.sourceName.toLowerCase().contains(searchText) ||
            source.relativePath.toLowerCase().contains(searchText) ||
            source.documentId.toLowerCase().contains(searchText))
        .toList(growable: true);
    _sortDocumentSources(filteredSources, sortMode);
    final filteredKeys = filteredSources.map(_documentKey).toSet();
    selectedDocuments.removeWhere((name) => !filteredKeys.contains(name));
    if (selectedDocumentIndex >= filteredSources.length) {
      selectedDocumentIndex =
          filteredSources.isEmpty ? 0 : filteredSources.length - 1;
    }
    final selectedSource =
        filteredSources.isEmpty ? null : filteredSources[selectedDocumentIndex];
    final selectedName = selectedSource?.sourceName ?? '';
    final selectedKey =
        selectedSource == null ? '' : _documentKey(selectedSource);
    Future<void> deleteSelectedDocument() async {
      if (rc6 == null || runtime.running || selectedSource == null) return;
      final confirmed = await _confirmDestructiveAction(
        context,
        title: zh ? '删除来源文档？' : 'Delete source document?',
        body: zh
            ? '这会从当前工作区删除“$selectedName”，并清理解析、知识库、检索和文档产物。'
            : 'This removes "$selectedName" from the current workspace and clears parsing, KB, retrieval, and document artifacts.',
      );
      if (!confirmed) return;
      await rc6.deleteImportedSource(selectedSource.relativePath);
      if (mounted) {
        setState(() => selectedDocumentIndex = 0);
      }
    }

    Future<void> deleteSelectedDocuments() async {
      if (rc6 == null || runtime.running || selectedDocuments.isEmpty) return;
      final count = selectedDocuments.length;
      final confirmed = await _confirmDestructiveAction(
        context,
        title: zh ? '批量删除来源文档？' : 'Delete selected source documents?',
        body: zh
            ? '这会删除 $count 个已选来源文档，并清理解析、知识库、检索和文档产物。'
            : 'This removes $count selected source documents and clears parsing, KB, retrieval, and document artifacts.',
      );
      if (!confirmed) return;
      final byKey = {
        for (final source in filteredSources) _documentKey(source): source,
      };
      final toDelete = selectedDocuments.toList(growable: false);
      for (final key in toDelete) {
        final source = byKey[key];
        if (source != null) {
          await rc6.deleteImportedSource(source.relativePath);
        }
      }
      if (mounted) {
        setState(() {
          selectedDocuments.clear();
          selectedDocumentIndex = 0;
        });
      }
    }

    final documentRows = filteredSources.isEmpty
        ? [
            [
              zh ? '请先导入真实文件' : 'Import real files first',
              '-',
              selectedType == 'all'
                  ? '-'
                  : _documentTypeLabel(selectedType, zh),
              zh ? '尚未导入' : 'Not imported',
              '0',
              '0',
            ]
          ]
        : filteredSources
            .map((source) => [
                  source.sourceName,
                  source.documentId.isEmpty ? '-' : source.documentId,
                  _documentTypeLabel(_documentTypeForSource(source), zh),
                  _structureStatusLabel(source.structureStatus, zh),
                  parsed ? (zh ? '已解析' : 'Parsed') : (zh ? '已导入' : 'Imported'),
                  source.wordCount.toString(),
                ])
            .toList(growable: false);
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1500;
      final docs = _FillProductPanel(
        keyName: 'document-library',
        icon: Icons.article_outlined,
        title: zh ? '来源文档管理' : 'Source Document Management',
        child: _FillPanelColumn(
          top: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final type in const [
                  'all',
                  'pdf',
                  'docx',
                  'md',
                  'txt',
                  'image',
                  'web',
                ])
                  ChoiceChip(
                    label: Text(_documentTypeLabel(type, zh)),
                    selected: selectedType == type,
                    onSelected: (_) => setState(() {
                      selectedType = type;
                      selectedDocumentIndex = 0;
                    }),
                  ),
              ]),
              const SizedBox(height: 8),
              TextField(
                key: const Key('document-library-search-input'),
                controller: _documentSearchController,
                onChanged: (_) => setState(() {
                  selectedDocumentIndex = 0;
                  selectedDocuments.clear();
                }),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_outlined),
                  labelText: zh ? '搜索来源文档' : 'Search source documents',
                  helperText: zh
                      ? '按文件名、网页来源记录过滤文档库。'
                      : 'Filter library documents by file name or web source record.',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ChoiceChip(
                  label: Text(zh ? '名称升序' : 'Name A-Z'),
                  selected: sortMode == 'name_asc',
                  onSelected: (_) => setState(() => sortMode = 'name_asc'),
                ),
                ChoiceChip(
                  label: Text(zh ? '名称降序' : 'Name Z-A'),
                  selected: sortMode == 'name_desc',
                  onSelected: (_) => setState(() => sortMode = 'name_desc'),
                ),
                ChoiceChip(
                  label: Text(zh ? '类型排序' : 'Type sort'),
                  selected: sortMode == 'type',
                  onSelected: (_) => setState(() => sortMode = 'type'),
                ),
              ]),
              const SizedBox(height: _DesktopGrid.gutter),
              _RuntimeFeedbackBanner(
                title: hasRealDocument
                    ? (zh ? '真实文档已进入文档库' : 'Real document is in library')
                    : (zh ? '等待导入真实文档' : 'Waiting for real document import'),
                detail: hasRealDocument
                    ? _displayNameForPath(runtime.sourceManifestPath)
                    : (zh
                        ? '请在导入与解析页签选择真实文件或文件夹。'
                        : 'Choose real files or a folder from the Import and Parsing tab.'),
                tone:
                    hasRealDocument ? _StatusTone.success : _StatusTone.warning,
                icon: hasRealDocument
                    ? Icons.verified_outlined
                    : Icons.upload_file_outlined,
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              Expanded(
                child: _BoundedScrollRegion(
                  child: _LocalScrollBox(
                    child: _ProductTable(
                      columns: zh
                          ? ['文档', 'Document ID', '类型', '结构', '解析', '字数']
                          : [
                              'Document',
                              'Document ID',
                              'Type',
                              'Structure',
                              'Parsing',
                              'Words'
                            ],
                      rows: documentRows,
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottom: _PrimaryProductAction(
            label: zh ? '用文档构建知识库' : 'Build KB from documents',
            icon: Icons.account_tree_outlined,
            onPressed: hasRealDocument ? widget.onBuildKnowledgeBase : null,
          ),
        ),
      );
      final detail = _FillProductPanel(
        keyName: 'document-detail',
        icon: Icons.subject_outlined,
        title: zh ? '文档详情抽屉' : 'Document Detail Drawer',
        child: _FillPanelColumn(
          top: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricStrip(
                items: [
                  _MetricDatum(
                      label: zh ? '字数' : 'Words',
                      value: selectedSource == null
                          ? '-'
                          : selectedSource.wordCount.toString(),
                      detail: zh ? '来源统计' : 'source stats',
                      icon: Icons.text_fields_outlined),
                  _MetricDatum(
                      label: zh ? '图片' : 'Images',
                      value: selectedSource == null
                          ? '-'
                          : selectedSource.imageCount.toString(),
                      detail: zh ? '来源统计' : 'source count',
                      icon: Icons.image_outlined),
                  _MetricDatum(
                      label: zh ? '表格' : 'Tables',
                      value: selectedSource == null
                          ? '-'
                          : selectedSource.tableCount.toString(),
                      detail: zh ? '来源统计' : 'source count',
                      icon: Icons.table_chart_outlined),
                  _MetricDatum(
                      label: zh ? '链接' : 'Links',
                      value: selectedSource == null
                          ? '-'
                          : selectedSource.linkCount.toString(),
                      detail: zh ? '来源统计' : 'source count',
                      icon: Icons.link_outlined),
                ],
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              Expanded(
                child: _BoundedScrollRegion(
                  child: _LocalScrollBox(
                    child: _EqualFieldGrid(
                      columns: 1,
                      children: [
                        _FieldRow(
                            label: zh ? 'Document ID' : 'Document ID',
                            value: selectedSource?.documentId.isNotEmpty == true
                                ? selectedSource!.documentId
                                : (zh ? '等待真实文件' : 'Waiting for real file')),
                        _FieldRow(
                            label: zh ? '来源路径' : 'Source path',
                            value: selectedName.isNotEmpty
                                ? (selectedSource?.relativePath ?? selectedName)
                                : (zh ? '等待真实文件' : 'Waiting for real file')),
                        _FieldRow(
                            label: zh ? '解析摘要' : 'Parse summary',
                            value: parsed
                                ? (zh
                                    ? '$chunkCount 个 chunks，解析报告已生成'
                                    : '$chunkCount chunks, parse report generated')
                                : (zh ? '尚无解析结果' : 'No parse result yet')),
                        _FieldRow(
                            label: zh ? '下游使用' : 'Downstream use',
                            value: zh
                                ? '知识库构建 / 文档生成 / 检索验证'
                                : 'Knowledge Base build / document generation / retrieval verification'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottom: _MoreActionsButton(
            label: zh ? '更多文档操作' : 'More document actions',
            actions: [
              _MoreMenuAction(
                label: zh ? '重新解析当前文档' : 'Re-parse selected document',
                icon: Icons.restart_alt_outlined,
                enabled: hasRealDocument && rc6 != null && !runtime.running,
                onSelected: () => rc6?.parseAndChunkSources(),
              ),
              _MoreMenuAction(
                label: selectedDocuments.isEmpty
                    ? (zh ? '删除当前文档' : 'Delete current document')
                    : (zh
                        ? '删除已选 ${selectedDocuments.length} 个文档'
                        : 'Delete ${selectedDocuments.length} selected docs'),
                icon: Icons.delete_outline,
                destructive: true,
                enabled: selectedDocuments.isEmpty
                    ? selectedKey.isNotEmpty
                    : selectedDocuments.isNotEmpty,
                onSelected: selectedDocuments.isEmpty
                    ? deleteSelectedDocument
                    : deleteSelectedDocuments,
              ),
              _MoreMenuAction(
                label: zh ? '生成标准知识包' : 'Create standard package',
                icon: Icons.inventory_2_outlined,
                enabled: hasRealDocument && parsed && rc6 != null && !runtime.running,
                onSelected: () => rc6?.exportStandardKnowledgePackage(),
              ),
            ],
          ),
        ),
      );
      final preview = _FillProductPanel(
        icon: Icons.preview_outlined,
        title: zh ? '来源预览' : 'Source Preview',
        child: _FillPanelColumn(
          top: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 212,
                child: _SourceDocumentPreviewPanel(
                  zh: zh,
                  ready: indexed && selectedName.isNotEmpty,
                  sourceName: selectedName,
                ),
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              Expanded(
                child: _BoundedScrollRegion(
                  child: _LocalScrollBox(
                    child: _DocumentSelectionList(
                      zh: zh,
                      sources: filteredSources,
                      selectedIndex: selectedDocumentIndex,
                      selectedDocuments: selectedDocuments,
                      onSelected: (index) =>
                          setState(() => selectedDocumentIndex = index),
                      onSelectionChanged: (name, selected) => setState(() {
                        if (selected) {
                          selectedDocuments.add(name);
                        } else {
                          selectedDocuments.remove(name);
                        }
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottom: _EqualFieldGrid(
            columns: 2,
            children: [
              _FieldRow(
                  label: zh ? '当前预览' : 'Current preview',
                  value: selectedName.isEmpty
                      ? (zh ? '无匹配文件' : 'No matching file')
                      : selectedName),
              _FieldRow(
                  label: zh ? '联动筛选' : 'Linked filter',
                  value: _documentTypeLabel(selectedType, zh)),
            ],
          ),
        ),
      );
      if (!wide) {
        return Column(children: [
          SizedBox(height: 620, child: docs),
          const SizedBox(height: _DesktopGrid.gutter),
          SizedBox(height: 500, child: preview),
          const SizedBox(height: _DesktopGrid.gutter),
          SizedBox(height: 460, child: detail),
        ]);
      }
      return Column(children: [
        _EqualHeightRow(
          height: 672,
          flexes: const [4, 4, 4],
          children: [docs, preview, detail],
        ),
      ]);
    });
  }
}

class _DocumentLibraryProductWorkflow extends StatefulWidget {
  const _DocumentLibraryProductWorkflow({
    required this.localeCode,
    required this.workspace,
    required this.isWebRuntime,
    required this.onPageChanged,
  });

  final String localeCode;
  final String workspace;
  final bool isWebRuntime;
  final ValueChanged<int> onPageChanged;

  @override
  State<_DocumentLibraryProductWorkflow> createState() =>
      _DocumentLibraryProductWorkflowState();
}

class _DocumentLibraryProductWorkflowState
    extends State<_DocumentLibraryProductWorkflow> {
  int selectedTab = 0;

  bool get _zh => widget.localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final tabs =
        _zh ? ['导入与解析', '来源文档'] : ['Import and Parsing', 'Source Documents'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.library_books_outlined,
        title: _zh ? '文档库' : 'Document Library',
        description: _zh
            ? '导入资料、解析/OCR/分块，并管理进入工作本的来源文档。'
            : 'Import sources, parse/OCR/chunk them, and manage source documents in the workbook.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _PageTabs(
        tabs: tabs,
        selectedIndex: selectedTab,
        onSelected: (index) => setState(() => selectedTab = index),
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      if (selectedTab == 0)
        _ImportProductWorkflow(
          localeCode: widget.localeCode,
          workspace: widget.workspace,
          isWebRuntime: widget.isWebRuntime,
        )
      else
        _DocumentLibraryView(
          zh: _zh,
          onBuildKnowledgeBase: () => widget
              .onPageChanged(_pageIndexById('knowledge-package-management')),
        ),
    ]);
  }
}
