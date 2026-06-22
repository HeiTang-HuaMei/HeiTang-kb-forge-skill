part of '../../main.dart';

class _DocumentProductWorkflow extends StatelessWidget {
  const _DocumentProductWorkflow({
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
        ? ['生成任务', '文档模板', '导出预览']
        : ['Generation Tasks', 'Document Templates', 'Export Preview'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductHeader(
          icon: Icons.description_outlined,
          title: _zh ? '文档生成' : 'Document Generation',
          description: _zh
              ? '从知识库生成文档草稿，保存编辑，并导出已配置格式。'
              : 'Generate document drafts from Knowledge Bases, save edits, and export configured formats.',
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _PageTabs(
            tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
        const SizedBox(height: _DesktopGrid.gutter),
        if (selectedTab == 1)
          _DocumentTemplateView(zh: _zh)
        else if (selectedTab == 2)
          _DocumentExportPreviewView(zh: _zh, workspace: workspace)
        else
          _DocumentGenerationView(zh: _zh),
      ],
    );
  }
}

class _DocumentGenerationView extends StatefulWidget {
  const _DocumentGenerationView({required this.zh});

  final bool zh;

  @override
  State<_DocumentGenerationView> createState() =>
      _DocumentGenerationViewState();
}

class _DocumentGenerationViewState extends State<_DocumentGenerationView> {
  bool draftQueued = false;
  bool previewReady = false;
  String generationType = 'reading_notes';
  String outputFormat = 'md';
  String citationStrategy = 'source_filename';
  String templateMode = 'built_in';
  final TextEditingController _editorController = TextEditingController();
  String savedEditPath = '';

  bool get zh => widget.zh;

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final markdownStatus = runtime.hasMarkdown
        ? (zh ? '已生成' : 'Generated')
        : runtime.hasKnowledgeBase
            ? (zh ? '可生成' : 'Ready')
            : (zh ? '需要知识库' : 'Needs KB');
    final officeExporterStatus = zh ? '需要设置导出工具' : 'Export tool setup required';
    final officeExporterDetail = zh ? '在设置启用后可导出' : 'Enable in Settings';
    final exporterAuditReady =
        runtime.exporterValidationReportPath.isNotEmpty ||
            runtime.hasProviderCapabilityUserCatalog;
    final markdownCapabilityStatus = runtime.hasKnowledgeBase
        ? (zh ? 'Markdown 可生成' : 'Markdown available')
        : (zh ? '需要知识库' : 'Needs KB');
    final structuredExportStatus = runtime.hasMarkdown
        ? (zh ? 'JSON / CSV 可导出' : 'JSON / CSV available')
        : (zh ? '生成 Markdown 后可用' : 'Available after Markdown');
    final officeCapabilityStatus = exporterAuditReady
        ? officeExporterStatus
        : (zh ? '未配置，按钮不可执行' : 'Not configured, disabled');
    String statusForOutputFormat(String format) {
      if (format == 'md') return markdownStatus;
      if (format == 'json' || format == 'csv') {
        return runtime.hasMarkdown
            ? (zh ? '可导出' : 'Ready')
            : (zh ? '需要文档' : 'Needs document');
      }
      return officeExporterStatus;
    }

    Future<void> openGenerationDialog() async {
      final result = await showDialog<_DocumentGenerationConfig>(
        context: context,
        builder: (context) => _DocumentGenerationDialog(
          zh: zh,
          initial: _DocumentGenerationConfig(
            generationType: generationType,
            outputFormat:
                _documentOutputFormatRequiresConfiguration(outputFormat)
                    ? 'md'
                    : outputFormat,
            citationStrategy: citationStrategy,
            templateMode: templateMode,
          ),
        ),
      );
      if (result == null) return;
      final output =
          _documentOutputFormatRequiresConfiguration(result.outputFormat)
              ? 'md'
              : result.outputFormat;
      setState(() {
        generationType = result.generationType;
        outputFormat = output;
        citationStrategy = result.citationStrategy;
        templateMode = result.templateMode;
        draftQueued = true;
        previewReady = true;
      });
      if (rc6 == null || runtime.running) return;
      await rc6.generateMarkdown(
        config: Rc6DocumentGenerationConfig(
          generationType: result.generationType,
          outputFormat: output,
          citationStrategy: result.citationStrategy,
          templateMode: result.templateMode,
        ),
      );
      if ((output == 'json' || output == 'csv') &&
          rc6.state.lastResult?.passed == true) {
        await rc6.exportDocumentFormat(output);
      }
    }

    Future<void> loadGeneratedBody() async {
      if (rc6 == null) return;
      final content = runtime.hasDocumentGenerationHistory
          ? await rc6.readLatestDocumentGenerationHistoryMarkdown()
          : await rc6.readWorkspaceTextArtifact(
              runtime.readingNotesPath.isNotEmpty
                  ? runtime.readingNotesPath
                  : runtime.generatedMarkdownPath,
            );
      if (content.isEmpty) return;
      if (!mounted) return;
      setState(() {
        _editorController.text = content;
        previewReady = true;
      });
    }

    Future<void> saveEditedBody() async {
      if (rc6 == null) return;
      final path = await rc6.saveEditedDocument(_editorController.text);
      if (!mounted) return;
      setState(() => savedEditPath = path);
    }

    Future<void> clearGenerationHistory() async {
      if (rc6 == null) return;
      await rc6.clearDocumentGenerationHistory();
      if (!mounted) return;
      setState(() {});
    }

    Future<void> deleteLatestGenerationHistory() async {
      if (rc6 == null) return;
      await rc6.deleteLatestDocumentGenerationHistory();
      if (!mounted) return;
      setState(() {});
    }

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1040;
      final extraWide = constraints.maxWidth >= 1180;
      final tasks = _ProductPanel(
        keyName: 'document-generation-tasks',
        icon: Icons.post_add_outlined,
        title: zh ? '生成任务' : 'Generation Task',
        minHeight: 366,
        children: [
          SizedBox(
            height: 276,
            child: _FillPanelColumn(
              top: _LocalScrollBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProductTable(
                      columns: zh
                          ? ['配置', '当前选择', '状态']
                          : ['Config', 'Selection', 'Status'],
                      rows: zh
                          ? [
                              [
                                '知识库 / 来源',
                                runtime.hasKnowledgeBase
                                    ? '真实输入知识库'
                                    : '需要先完成知识库构建',
                                markdownStatus
                              ],
                              [
                                '生成类型',
                                _documentGenerationTypeLabel(
                                    generationType, zh),
                                '已选择'
                              ],
                              ['题材 / 模板', '内置读书笔记模板', '可用'],
                              [
                                '模板模式',
                                _templateModeLabel(templateMode, zh),
                                templateMode == 'agent' ? '使用内置助手题材' : '可用'
                              ],
                              [
                                '输出格式',
                                outputFormat.toUpperCase(),
                                statusForOutputFormat(outputFormat)
                              ],
                              ['Markdown', '默认输出', markdownCapabilityStatus],
                              ['JSON / CSV', '结构化导出', structuredExportStatus],
                              [
                                'DOCX / PDF / PPTX',
                                'Office 导出工具',
                                officeCapabilityStatus
                              ],
                              [
                                '引用策略',
                                _citationStrategyLabel(citationStrategy, zh),
                                '已选择'
                              ],
                            ]
                          : [
                              [
                                'KB / source',
                                runtime.hasKnowledgeBase
                                    ? 'Real input KB'
                                    : 'Complete KB build first',
                                markdownStatus
                              ],
                              [
                                'Generation type',
                                _documentGenerationTypeLabel(
                                    generationType, zh),
                                'Selected'
                              ],
                              [
                                'Genre / template',
                                'Built-in reading-notes template',
                                'Ready'
                              ],
                              [
                                'Template mode',
                                _templateModeLabel(templateMode, zh),
                                templateMode == 'agent'
                                    ? 'Built-in agent genre'
                                    : 'Ready'
                              ],
                              [
                                'Output format',
                                outputFormat.toUpperCase(),
                                statusForOutputFormat(outputFormat)
                              ],
                              [
                                'Markdown',
                                'Default output',
                                markdownCapabilityStatus
                              ],
                              [
                                'JSON / CSV',
                                'Structured export',
                                structuredExportStatus
                              ],
                              [
                                'DOCX / PDF / PPTX',
                                'Office exporter',
                                officeCapabilityStatus
                              ],
                              [
                                'Citation strategy',
                                _citationStrategyLabel(citationStrategy, zh),
                                'Selected'
                              ],
                            ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final item in const [
                        'reading_notes',
                        'summary',
                        'study_cards',
                        'structured_report',
                        'ppt_outline',
                        'operation_plan',
                        'product_analysis',
                        'qa_script',
                      ])
                        ChoiceChip(
                          label: Text(_documentGenerationTypeLabel(item, zh)),
                          selected: generationType == item,
                          onSelected: (_) =>
                              setState(() => generationType = item),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final item in const ['built_in', 'custom', 'agent'])
                        ChoiceChip(
                          label: Text(_templateModeLabel(item, zh)),
                          selected: templateMode == item,
                          onSelected: (_) =>
                              setState(() => templateMode = item),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final item in const [
                        'md',
                        'docx',
                        'pdf',
                        'pptx',
                        'json',
                        'csv'
                      ])
                        ChoiceChip(
                          label: Text(_documentOutputFormatLabel(item, zh)),
                          selected: outputFormat == item,
                          onSelected:
                              _documentOutputFormatRequiresConfiguration(item)
                                  ? null
                                  : (_) => setState(() => outputFormat = item),
                        ),
                    ]),
                  ],
                ),
              ),
              bottom: _EqualActionRow(children: [
                _PrimaryProductAction(
                  label: zh ? '生成文档' : 'Generate Document',
                  icon: Icons.notes_outlined,
                  onPressed: runtime.running || rc6 == null
                      ? null
                      : runtime.hasKnowledgeBase
                          ? openGenerationDialog
                          : null,
                ),
                _MoreActionsButton(
                  label: zh ? '更多生成操作' : 'More generation actions',
                  actions: [
                    _MoreMenuAction(
                      label: zh ? '重新生成' : 'Regenerate',
                      icon: Icons.restart_alt_outlined,
                      enabled: !runtime.running &&
                          rc6 != null &&
                          runtime.hasKnowledgeBase,
                      onSelected: openGenerationDialog,
                    ),
                    _MoreMenuAction(
                      label: zh ? '导出 Markdown' : 'Export Markdown',
                      icon: Icons.download_outlined,
                      enabled: rc6 != null &&
                          !runtime.running &&
                          runtime.hasMarkdown,
                      onSelected: () => rc6?.exportMarkdownDocument(),
                    ),
                    _MoreMenuAction(
                      label: zh ? '删除最近记录' : 'Delete latest record',
                      icon: Icons.delete_outline,
                      destructive: true,
                      enabled: rc6 != null &&
                          !runtime.running &&
                          runtime.hasDocumentGenerationHistory,
                      onSelected: deleteLatestGenerationHistory,
                    ),
                    _MoreMenuAction(
                      label: zh ? '清空历史' : 'Clear history',
                      icon: Icons.delete_sweep_outlined,
                      destructive: true,
                      enabled: rc6 != null &&
                          !runtime.running &&
                          runtime.hasDocumentGenerationHistory,
                      onSelected: clearGenerationHistory,
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      );
      final preview = _ProductPanel(
        keyName: 'document-live-preview',
        icon: Icons.article_outlined,
        title: zh ? '正文编辑' : 'Body Editor',
        minHeight: 366,
        children: [
          SizedBox(
            key: const Key('document-central-preview'),
            height: 184,
            child: TextField(
              key: const Key('document-body-editor'),
              controller: _editorController,
              maxLines: null,
              expands: true,
              enabled: rc6 != null,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: runtime.hasMarkdown
                    ? (zh
                        ? '加载生成稿后可编辑正文。'
                        : 'Load the generated body, then edit it.')
                    : (zh ? '请先生成正文。' : 'Generate the body first.'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.22,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          _EqualActionRow(children: [
            _DisplayAction(
              label: zh ? '重新打开生成稿' : 'Reopen Draft',
              icon: Icons.article_outlined,
              onPressed: rc6 == null || !runtime.hasMarkdown
                  ? null
                  : loadGeneratedBody,
            ),
            _PrimaryProductAction(
              label: zh ? '保存编辑' : 'Save Edit',
              icon: Icons.save_outlined,
              onPressed: rc6 == null ||
                      runtime.running ||
                      !runtime.hasMarkdown ||
                      _editorController.text.trim().isEmpty
                  ? null
                  : saveEditedBody,
            ),
          ]),
          if (runtime.generatedMarkdownPath.isNotEmpty) ...[
            const SizedBox(height: 8),
            _FieldRow(
              label: zh ? 'Markdown' : 'Markdown',
              value: _displayNameForPath(runtime.generatedMarkdownPath),
            ),
          ],
          if (runtime.readingNotesPath.isNotEmpty) ...[
            const SizedBox(height: 8),
            _FieldRow(
              label: zh ? '读书笔记' : 'Reading notes',
              value: _displayNameForPath(runtime.readingNotesPath),
            ),
          ],
          if (runtime.editedDocumentPath.isNotEmpty ||
              savedEditPath.isNotEmpty) ...[
            const SizedBox(height: 8),
            _FieldRow(
              label: zh ? '编辑稿' : 'Edited draft',
              value: _displayNameForPath(runtime.editedDocumentPath.isNotEmpty
                  ? runtime.editedDocumentPath
                  : savedEditPath),
            ),
          ],
        ],
      );
      final config = _FillProductPanel(
        icon: Icons.tune_outlined,
        title: zh ? '生成配置' : 'Generation Config',
        child: Align(
          alignment: Alignment.topCenter,
          child: _ProductTable(
            columns: zh ? ['配置', '值', '分类'] : ['Setting', 'Value', 'Class'],
            rows: zh
                ? [
                    [
                      '引用策略',
                      _citationStrategyLabel(citationStrategy, zh),
                      '来源文件名与知识库片段'
                    ],
                    ['脱敏检查', '本地检查', '不显示明文 secret'],
                    [
                      '引用验证',
                      runtime.searchStatus == Rc6SearchStatus.success
                          ? '检索结果可用'
                          : '需要先运行检索',
                      '引用来源可追踪'
                    ],
                    [
                      '引用清单',
                      runtime.documentCitationsPath.isNotEmpty
                          ? '已生成'
                          : runtime.queryResultPath.isNotEmpty
                              ? '使用检索结果'
                              : '等待检索结果',
                      '随文档保存'
                    ],
                    [
                      '大纲',
                      runtime.documentOutlinePath.isNotEmpty ? '已生成' : '等待生成',
                      '文档结构'
                    ],
                    [
                      '文档验证',
                      runtime.documentValidationReportPath.isNotEmpty
                          ? '已生成'
                          : '等待生成',
                      '引用与脱敏检查'
                    ],
                    [
                      '编辑保存',
                      runtime.hasEditedDocument ? '已保存' : '等待编辑',
                      '用户工作区'
                    ],
                    [
                      '生成历史',
                      runtime.hasDocumentGenerationHistory
                          ? '${runtime.documentGenerationHistoryCount} 条'
                          : '暂无历史',
                      '用户工作区'
                    ],
                  ]
                : [
                    [
                      'Citation strategy',
                      _citationStrategyLabel(citationStrategy, zh),
                      'Source names and KB snippets'
                    ],
                    ['Redaction check', 'Local check', 'No plaintext secret'],
                    [
                      'Citation validation',
                      runtime.searchStatus == Rc6SearchStatus.success
                          ? 'Search result ready'
                          : 'Run retrieval first',
                      'Sources traceable'
                    ],
                    [
                      'Citation list',
                      runtime.documentCitationsPath.isNotEmpty
                          ? 'Generated'
                          : runtime.queryResultPath.isNotEmpty
                              ? 'Uses retrieval result'
                              : 'Waiting retrieval',
                      'Saved with document'
                    ],
                    [
                      'Outline',
                      runtime.documentOutlinePath.isNotEmpty
                          ? 'Generated'
                          : 'Waiting generation',
                      'Document structure'
                    ],
                    [
                      'Document validation',
                      runtime.documentValidationReportPath.isNotEmpty
                          ? 'Generated'
                          : 'Waiting generation',
                      'Citation and redaction checks'
                    ],
                    [
                      'History',
                      runtime.hasDocumentGenerationHistory
                          ? '${runtime.documentGenerationHistoryCount} records'
                          : 'No history',
                      'User workspace'
                    ],
                    [
                      'Edit save',
                      runtime.hasEditedDocument ? 'Saved' : 'Waiting edit',
                      'User workspace'
                    ],
                  ],
          ),
        ),
      );
      final validation = _ProductPanel(
        icon: Icons.rule_outlined,
        title: zh ? '验证与导出' : 'Validation and Export',
        gap: true,
        minHeight: 198,
        children: [
          _FieldRow(
            label: zh ? 'Markdown 产物' : 'Markdown artifact',
            value: runtime.hasMarkdown
                ? _displayNameForPath(runtime.generatedMarkdownPath)
                : (zh ? '尚未生成' : 'Not generated'),
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '生成历史' : 'Generation history',
            value: runtime.hasDocumentGenerationHistory
                ? (zh
                    ? '${runtime.documentGenerationHistoryCount} 条记录'
                    : '${runtime.documentGenerationHistoryCount} records')
                : (zh ? '暂无历史' : 'No history'),
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '导出边界' : 'Export boundary',
            value: zh
                ? 'Markdown、JSON、CSV 为本地导出；DOCX/PDF/PPTX 需要先设置导出工具。'
                : 'Markdown, JSON, and CSV export locally; DOCX/PDF/PPTX require export tool setup.',
          ),
        ],
      );
      final outputFormats = _FillProductPanel(
        icon: Icons.output_outlined,
        title: zh ? '输出格式' : 'Output Formats',
        child: _CenteredOutputFormatGrid(
          items: [
            _MetricDatum(
                label: 'Markdown',
                value: markdownStatus,
                detail: runtime.hasMarkdown
                    ? (zh ? '真实文件' : 'real file')
                    : (zh ? '点击生成' : 'generate on click'),
                icon: Icons.notes_outlined),
            _MetricDatum(
                label: 'DOCX',
                value: officeExporterStatus,
                detail: officeExporterDetail,
                icon: Icons.description_outlined),
            _MetricDatum(
                label: 'PDF/PPTX',
                value: officeExporterStatus,
                detail: officeExporterDetail,
                icon: Icons.picture_as_pdf_outlined),
            _MetricDatum(
                label: 'JSON/CSV',
                value: zh ? '可导出' : 'enabled',
                detail: zh ? '本地结构化文件' : 'local structured files',
                icon: Icons.table_chart_outlined),
            _MetricDatum(
                label: zh ? '脱敏验证' : 'Redaction',
                value: zh ? '本地检查' : 'Local check',
                detail: zh ? '导出前执行' : 'before export',
                icon: Icons.account_tree_outlined),
          ],
        ),
      );
      if (!wide) {
        return Column(children: [
          if (draftQueued || previewReady) ...[
            _RuntimeFeedbackBanner(
              title: runtime.hasMarkdown
                  ? (zh ? '读书笔记已生成' : 'Reading notes generated')
                  : (zh ? '文档生成已触发' : 'Document generation started'),
              detail: zh
                  ? '文档产物保存在本地工作区，导出页可继续导出多格式文件。'
                  : 'Document artifacts are saved in the local workspace; export more formats from the export page.',
              tone: runtime.hasMarkdown
                  ? _StatusTone.success
                  : _StatusTone.neutral,
              icon: Icons.notes_outlined,
            ),
            const SizedBox(height: _DesktopGrid.gutter),
          ],
          tasks,
          const SizedBox(height: _DesktopGrid.gutter),
          preview,
          const SizedBox(height: _DesktopGrid.gutter),
          config,
          const SizedBox(height: _DesktopGrid.gutter),
          outputFormats,
          const SizedBox(height: _DesktopGrid.gutter),
          validation
        ]);
      }
      return Column(children: [
        if (draftQueued || previewReady) ...[
          _RuntimeFeedbackBanner(
            title: runtime.hasMarkdown
                ? (zh ? '读书笔记已生成' : 'Reading notes generated')
                : (zh ? '文档生成已触发' : 'Document generation started'),
            detail: zh
                ? '文档产物保存在本地工作区，导出页可继续导出多格式文件。'
                : 'Document artifacts are saved in the local workspace; export more formats from the export page.',
            tone:
                runtime.hasMarkdown ? _StatusTone.success : _StatusTone.neutral,
            icon: Icons.notes_outlined,
          ),
          const SizedBox(height: _DesktopGrid.gutter),
        ],
        _EqualHeightRow(
          height: 366,
          flexes: extraWide ? const [5, 7] : const [6, 6],
          children: [tasks, preview],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _EqualHeightRow(
          height: 326,
          flexes: const [6, 6],
          children: [config, outputFormats],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        validation,
      ]);
    });
  }
}

class _DocumentTemplateView extends StatefulWidget {
  const _DocumentTemplateView({required this.zh});

  final bool zh;

  @override
  State<_DocumentTemplateView> createState() => _DocumentTemplateViewState();
}

class _DocumentTemplateViewState extends State<_DocumentTemplateView> {
  bool templateSelected = false;

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1040;
      final templates = _ProductPanel(
        keyName: 'document-template-library',
        icon: Icons.dashboard_customize_outlined,
        title: zh ? '文档模板库' : 'Document Template Library',
        children: [
          _ProductTable(
            columns: zh
                ? ['模板', '输出', '变量', '状态']
                : ['Template', 'Output', 'Variables', 'Status'],
            rows: zh
                ? [
                    ['行业分析报告', 'DOCX / PDF', 'title, evidence, risk', '可预览'],
                    ['产品手册', 'Markdown / DOCX', 'feature, citation', '可预览'],
                    ['教学材料', 'PPTX / PDF', 'lesson, quiz, source', '可预览'],
                    ['自定义模板', '多格式', '用户变量', '需配置模板'],
                  ]
                : [
                    [
                      'Industry report',
                      'DOCX / PDF',
                      'title, evidence, risk',
                      'Previewable'
                    ],
                    [
                      'Product manual',
                      'Markdown / DOCX',
                      'feature, citation',
                      'Previewable'
                    ],
                    [
                      'Teaching material',
                      'PPTX / PDF',
                      'lesson, quiz, source',
                      'Previewable'
                    ],
                    [
                      'Custom template',
                      'Multi-format',
                      'User variables',
                      'Needs template config'
                    ],
                  ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _PrimaryProductAction(
            label: zh ? '选择模板预览' : 'Select template preview',
            icon: Icons.visibility_outlined,
            onPressed: () => setState(() => templateSelected = true),
          ),
        ],
      );
      final detail = _ProductPanel(
        keyName: 'document-template-detail',
        icon: Icons.code_outlined,
        title: zh ? '模板变量与验证' : 'Template Variables and Validation',
        children: [
          _FieldRow(
              label: zh ? '变量预览' : 'Variable preview',
              value: templateSelected
                  ? 'title / source / evidence / risk / export_manifest'
                  : (zh ? '等待选择模板' : 'Waiting for template selection')),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '归属' : 'Ownership',
              value: zh
                  ? '文档模板归文档生成'
                  : 'Document templates belong to Document Generation'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '导出边界' : 'Export boundary',
              value: zh
                  ? '本模块管理文档导出，不发布 Release'
                  : 'This module owns document export, no Release publication'),
        ],
      );
      if (!wide) {
        return Column(children: [
          templates,
          const SizedBox(height: _DesktopGrid.gutter),
          detail
        ]);
      }
      return _EqualHeightRow(
        height: 318,
        flexes: const [7, 4],
        children: [templates, detail],
      );
    });
  }
}

String _documentGenerationTypeLabel(String value, bool zh) {
  return switch (value) {
    'summary' => zh ? '摘要' : 'Summary',
    'study_cards' => zh ? '学习卡片' : 'Study cards',
    'structured_report' => zh ? '结构化报告' : 'Structured report',
    'ppt_outline' => zh ? 'PPT 大纲' : 'PPT outline',
    'operation_plan' => zh ? '运营方案' : 'Operation plan',
    'product_analysis' => zh ? '产品分析' : 'Product analysis',
    'qa_script' => zh ? '问答稿' : 'QA script',
    _ => zh ? '读书笔记' : 'Reading notes',
  };
}

String _templateModeLabel(String value, bool zh) {
  return switch (value) {
    'custom' => zh ? '自定义模板' : 'Custom template',
    'agent' => zh ? '内置助手题材' : 'Built-in assistant genre',
    _ => zh ? '通用内置模板' : 'Built-in template',
  };
}

String _citationStrategyLabel(String value, bool zh) {
  return switch (value) {
    'strict_citation' => zh ? '严格引用' : 'Strict citation',
    'filename_and_chunk' => zh ? '文件名 + 片段' : 'Filename + segment',
    _ => zh ? '来源文件名' : 'Source filename',
  };
}

bool _documentOutputFormatRequiresConfiguration(String value) {
  return const {'docx', 'pdf', 'pptx'}.contains(value);
}

String _documentOutputFormatLabel(String value, bool zh) {
  final upper = value.toUpperCase();
  if (_documentOutputFormatRequiresConfiguration(value)) {
    return zh ? '$upper（需配置）' : '$upper (config required)';
  }
  return upper;
}

class _DocumentGenerationConfig {
  const _DocumentGenerationConfig({
    required this.generationType,
    required this.outputFormat,
    required this.citationStrategy,
    required this.templateMode,
  });

  final String generationType;
  final String outputFormat;
  final String citationStrategy;
  final String templateMode;
}

class _DocumentGenerationDialog extends StatefulWidget {
  const _DocumentGenerationDialog({
    required this.zh,
    required this.initial,
  });

  final bool zh;
  final _DocumentGenerationConfig initial;

  @override
  State<_DocumentGenerationDialog> createState() =>
      _DocumentGenerationDialogState();
}

class _DocumentGenerationDialogState extends State<_DocumentGenerationDialog> {
  late String generationType = widget.initial.generationType;
  late String outputFormat = widget.initial.outputFormat;
  late String citationStrategy = widget.initial.citationStrategy;
  late String templateMode = widget.initial.templateMode;

  bool get zh => widget.zh;

  String _outputChoiceLabel(String item) {
    final upper = item.toUpperCase();
    if (item == 'docx' || item == 'pdf' || item == 'pptx') {
      return zh ? '$upper（需配置）' : '$upper (config required)';
    }
    return upper;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(zh ? '选择文档生成配置' : 'Choose document generation config'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCaption(zh ? '生成类型' : 'Generation type'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final item in const [
                  'reading_notes',
                  'summary',
                  'study_cards',
                  'structured_report',
                  'ppt_outline',
                  'operation_plan',
                  'product_analysis',
                  'qa_script',
                ])
                  ChoiceChip(
                    label: Text(_documentGenerationTypeLabel(item, zh)),
                    selected: generationType == item,
                    onSelected: (_) => setState(() => generationType = item),
                  ),
              ]),
              const SizedBox(height: 12),
              _SectionCaption(zh ? '题材 / 模板' : 'Genre / template'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final item in const ['built_in', 'custom', 'agent'])
                  ChoiceChip(
                    label: Text(_templateModeLabel(item, zh)),
                    selected: templateMode == item,
                    onSelected: (_) => setState(() => templateMode = item),
                  ),
              ]),
              const SizedBox(height: 12),
              _SectionCaption(zh ? '输出格式' : 'Output format'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final item in const [
                  'md',
                  'json',
                  'csv',
                  'docx',
                  'pdf',
                  'pptx'
                ])
                  ChoiceChip(
                    label: Text(_outputChoiceLabel(item)),
                    selected: outputFormat == item,
                    onSelected: (_) => setState(() => outputFormat = item),
                  ),
              ]),
              const SizedBox(height: 12),
              _SectionCaption(zh ? '引用策略' : 'Citation strategy'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final item in const [
                  'source_filename',
                  'filename_and_chunk',
                  'strict_citation',
                ])
                  ChoiceChip(
                    label: Text(_citationStrategyLabel(item, zh)),
                    selected: citationStrategy == item,
                    onSelected: (_) => setState(() => citationStrategy = item),
                  ),
              ]),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(
            _DocumentGenerationConfig(
              generationType: generationType,
              outputFormat: outputFormat,
              citationStrategy: citationStrategy,
              templateMode: templateMode,
            ),
          ),
          icon: const Icon(Icons.play_arrow_outlined),
          label: Text(zh ? '生成' : 'Generate'),
        ),
      ],
    );
  }
}

class _DocumentExportPreviewView extends StatefulWidget {
  const _DocumentExportPreviewView({
    required this.zh,
    required this.workspace,
  });

  final bool zh;
  final String workspace;

  @override
  State<_DocumentExportPreviewView> createState() =>
      _DocumentExportPreviewViewState();
}

class _DocumentExportPreviewViewState
    extends State<_DocumentExportPreviewView> {
  bool exportPreviewReady = false;
  String selectedExportFormat = 'md';

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final officeExporterStatus = zh ? '需要设置导出工具' : 'Export tool setup required';
    final officeExporterValidation = zh ? '未启用' : 'Not enabled';
    final officeExporterArtifact =
        zh ? '在设置启用导出工具' : 'Enable export tools in Settings';

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= _DesktopGrid.rowBreakpoint;
      final export = _ProductPanel(
        keyName: 'document-export-preview',
        icon: Icons.file_download_outlined,
        title: zh ? '文档导出' : 'Document Export',
        children: [
          _SectionCaption(zh
              ? 'Markdown、JSON、CSV 通过本地工作区真实导出；DOCX/PDF/PPTX 需要在设置启用导出工具。'
              : 'Markdown, JSON, and CSV export through the local workspace; DOCX/PDF/PPTX require export tools in Settings.'),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh
                ? ['格式', '状态', '验证', '产物']
                : ['Format', 'Status', 'Validation', 'Artifact'],
            rows: zh
                ? [
                    [
                      'Markdown',
                      runtime.hasExportedDocument
                          ? '已导出'
                          : runtime.hasMarkdown
                              ? '可导出'
                              : '需要 Markdown',
                      runtime.hasExportedDocument ? '通过' : '尚未导出',
                      runtime.hasExportedDocument
                          ? _displayNameForPath(runtime.exportedDocumentPath)
                          : '尚未生成导出文件'
                    ],
                    [
                      'JSON',
                      runtime.hasMarkdown ? '可导出' : '需要 Markdown',
                      '本地结构化',
                      'knowledge_export.json'
                    ],
                    [
                      'CSV',
                      runtime.hasMarkdown ? '可导出' : '需要 Markdown',
                      '本地结构化',
                      'knowledge_export.csv'
                    ],
                    [
                      'DOCX',
                      officeExporterStatus,
                      officeExporterValidation,
                      officeExporterArtifact
                    ],
                    [
                      'PDF',
                      officeExporterStatus,
                      officeExporterValidation,
                      officeExporterArtifact
                    ],
                    [
                      'PPTX',
                      officeExporterStatus,
                      officeExporterValidation,
                      officeExporterArtifact
                    ],
                  ]
                : [
                    [
                      'Markdown',
                      runtime.hasExportedDocument
                          ? 'Exported'
                          : runtime.hasMarkdown
                              ? 'Ready'
                              : 'Needs Markdown',
                      runtime.hasExportedDocument ? 'Passed' : 'Not exported',
                      runtime.hasExportedDocument
                          ? _displayNameForPath(runtime.exportedDocumentPath)
                          : 'No export file yet'
                    ],
                    [
                      'JSON',
                      runtime.hasMarkdown ? 'Ready' : 'Needs Markdown',
                      'Local structured',
                      'knowledge_export.json'
                    ],
                    [
                      'CSV',
                      runtime.hasMarkdown ? 'Ready' : 'Needs Markdown',
                      'Local structured',
                      'knowledge_export.csv'
                    ],
                    [
                      'DOCX',
                      officeExporterStatus,
                      officeExporterValidation,
                      officeExporterArtifact
                    ],
                    [
                      'PDF',
                      officeExporterStatus,
                      officeExporterValidation,
                      officeExporterArtifact
                    ],
                    [
                      'PPTX',
                      officeExporterStatus,
                      officeExporterValidation,
                      officeExporterArtifact
                    ],
                  ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final item in const [
              'md',
              'json',
              'csv',
              'docx',
              'pdf',
              'pptx'
            ])
              ChoiceChip(
                label: Text(_documentOutputFormatLabel(item, zh)),
                selected: selectedExportFormat == item,
                onSelected: _documentOutputFormatRequiresConfiguration(item)
                    ? null
                    : (_) => setState(() => selectedExportFormat = item),
              ),
          ]),
          const SizedBox(height: _DesktopGrid.gutter),
          _PrimaryProductAction(
            label: zh
                ? '导出 ${selectedExportFormat.toUpperCase()} 文件'
                : 'Export ${selectedExportFormat.toUpperCase()} file',
            icon: Icons.file_download_outlined,
            onPressed: runtime.running ||
                    rc6 == null ||
                    !runtime.hasMarkdown ||
                    _documentOutputFormatRequiresConfiguration(
                        selectedExportFormat)
                ? null
                : () {
                    setState(() => exportPreviewReady = true);
                    rc6.exportDocumentFormat(selectedExportFormat);
                  },
          ),
        ],
      );
      final checks = _ProductPanel(
        icon: Icons.verified_outlined,
        title: zh ? '文档验证' : 'Document Validation',
        children: [
          _FieldRow(
              label: zh ? '内容完整性' : 'Completeness',
              value: runtime.hasExportedDocument
                  ? (zh ? '导出文件非空' : 'Export file non-empty')
                  : (zh ? '等待导出' : 'Waiting')),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '引用有效性' : 'Citation validity',
              value: runtime.hasExportedDocument
                  ? (zh ? '引用来源已写入' : 'Sources written')
                  : '-'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '敏感信息检查' : 'Sensitive content',
              value: zh ? '本地检查，不联网' : 'Local check, no network'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '导出清单' : 'Export manifest',
              value: runtime.exportManifestPath.isEmpty
                  ? (zh ? '等待导出' : 'Waiting export')
                  : _displayNameForPath(runtime.exportManifestPath)),
        ],
      );
      if (!wide) {
        return Column(children: [
          if (exportPreviewReady || runtime.hasExportedDocument) ...[
            _RuntimeFeedbackBanner(
              title: runtime.hasExportedDocument
                  ? (zh ? 'Markdown 文件已导出' : 'Markdown file exported')
                  : (zh ? '正在导出 Markdown' : 'Exporting Markdown'),
              detail: runtime.hasExportedDocument
                  ? _displayNameForPath(runtime.exportedDocumentPath)
                  : (zh ? '正在写入用户工作区。' : 'Writing to user workspace.'),
              tone: runtime.hasExportedDocument
                  ? _StatusTone.success
                  : _StatusTone.neutral,
              icon: Icons.file_download_outlined,
            ),
            const SizedBox(height: _DesktopGrid.gutter),
          ],
          export,
          const SizedBox(height: _DesktopGrid.gutter),
          checks
        ]);
      }
      return Column(children: [
        if (exportPreviewReady || runtime.hasExportedDocument) ...[
          _RuntimeFeedbackBanner(
            title: runtime.hasExportedDocument
                ? (zh ? 'Markdown 文件已导出' : 'Markdown file exported')
                : (zh ? '正在导出 Markdown' : 'Exporting Markdown'),
            detail: runtime.hasExportedDocument
                ? _displayNameForPath(runtime.exportedDocumentPath)
                : (zh ? '正在写入用户工作区。' : 'Writing to user workspace.'),
            tone: runtime.hasExportedDocument
                ? _StatusTone.success
                : _StatusTone.neutral,
            icon: Icons.file_download_outlined,
          ),
          const SizedBox(height: _DesktopGrid.gutter),
        ],
        _EqualHeightRow(
          height: 342,
          flexes: const [7, 4],
          children: [export, checks],
        ),
      ]);
    });
  }
}
