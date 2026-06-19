part of '../../main.dart';

class _WorkbookProductWorkflow extends StatefulWidget {
  const _WorkbookProductWorkflow({
    required this.localeCode,
    required this.workspace,
    required this.onPageChanged,
  });

  final String localeCode;
  final String workspace;
  final ValueChanged<int> onPageChanged;

  @override
  State<_WorkbookProductWorkflow> createState() =>
      _WorkbookProductWorkflowState();
}

class _WorkbookProductWorkflowState extends State<_WorkbookProductWorkflow> {
  final TextEditingController _workbookNameController =
      TextEditingController(text: '新知识工作本');

  bool get _zh => localeCode == 'zh-CN';

  String get localeCode => widget.localeCode;

  Future<void> _createOrSwitchWorkbook(Rc6RuntimeController? rc6,
      {String? name}) async {
    if (rc6 == null || rc6.state.running) return;
    final target = (name ?? _workbookNameController.text).trim();
    await rc6.createOrSwitchWorkbook(target);
  }

  Future<void> _confirmAndDeleteWorkbook(
    Rc6RuntimeController? rc6,
    String name,
  ) async {
    if (rc6 == null || rc6.state.running || name.trim().isEmpty) return;
    final confirmed = await _confirmDestructiveAction(
      context,
      title: _zh ? '删除工作本？' : 'Delete workbook?',
      body: _zh
          ? '这会从当前工作区删除“$name”的工作本记录；真实导入文件、知识库和产物仍保留在工作区，可由其他工作本继续引用。'
          : 'This deletes the "$name" workbook record from the current workspace. Imported files, knowledge bases, and artifacts remain in the workspace and can still be referenced by other workbooks.',
    );
    if (!confirmed) return;
    await rc6.deleteWorkbook(name);
  }

  @override
  void dispose() {
    _workbookNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final latestArtifact = runtime.hasExportedDocument
        ? _displayNameForPath(runtime.exportedDocumentPath)
        : runtime.hasMarkdown
            ? _displayNameForPath(runtime.generatedMarkdownPath)
            : runtime.hasKnowledgeBase
                ? _displayNameForPath(runtime.kbManifestPath)
                : runtime.hasImportedFile
                    ? _displayNameForPath(runtime.sourceManifestPath)
                    : (_zh ? '暂无产物' : 'No artifacts yet');
    final readySummary = [
      if (runtime.hasImportedFile) _zh ? '文档库' : 'Document Library',
      if (runtime.hasKnowledgeBase) _zh ? '知识库' : 'Knowledge Base',
      if (runtime.searchStatus == Rc6SearchStatus.success)
        _zh ? '检索报告' : 'Retrieval Report',
      if (runtime.hasMarkdown) _zh ? '生成文档' : 'Generated Document',
      if (runtime.hasSkill) 'Skill',
      if (runtime.hasAgent) 'Agent',
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.workspaces_outline,
        title: _zh ? '工作本管理' : 'Workbook',
        description: _zh
            ? '工作本隔离文档、知识库、应用产物和审计记录，并承接下一步任务。'
            : 'The workbook isolates documents, knowledge bases, application artifacts, and audit records.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _MetricStrip(
        items: [
          _MetricDatum(
            label: _zh ? '来源文档' : 'Source Docs',
            value: runtime.sourceCount.toString(),
            detail: runtime.hasImportedFile
                ? (_zh ? '已持久化' : 'persisted')
                : (_zh ? '等待导入' : 'waiting'),
            icon: Icons.article_outlined,
          ),
          _MetricDatum(
            label: _zh ? '知识库' : 'Knowledge Bases',
            value: runtime.knowledgeBases.isNotEmpty
                ? runtime.knowledgeBases.length.toString()
                : runtime.hasKnowledgeBase
                    ? '1'
                    : '0',
            detail: runtime.hasKnowledgeBase
                ? '${runtime.chunkCount} chunks'
                : (_zh ? '等待构建' : 'waiting build'),
            icon: Icons.account_tree_outlined,
          ),
          _MetricDatum(
            label: _zh ? '应用产物' : 'App Artifacts',
            value: [
              runtime.hasMarkdown,
              runtime.hasSkill,
              runtime.hasAgent,
              runtime.hasAgentDialogue,
              runtime.hasAgentDialogueExport,
              runtime.hasMultiAgentDiscussion,
            ].where((value) => value).length.toString(),
            detail: latestArtifact,
            icon: Icons.folder_copy_outlined,
          ),
          _MetricDatum(
            label: _zh ? '最近结果' : 'Latest Result',
            value: runtime.lastError.isEmpty
                ? (_zh ? '正常' : 'OK')
                : (_zh ? '失败' : 'Failed'),
            detail: runtime.lastError.isEmpty
                ? (runtime.lastMessage.isEmpty
                    ? (_zh ? '等待任务' : 'idle')
                    : runtime.lastMessage)
                : runtime.lastError,
            icon: runtime.lastError.isEmpty
                ? Icons.verified_outlined
                : Icons.error_outline,
          ),
        ],
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final overview = _ProductPanel(
          keyName: 'workbook-overview',
          icon: Icons.space_dashboard_outlined,
          title: _zh ? '当前工作本' : 'Current Workbook',
          minHeight: 320,
          children: [
            _ProductTable(
              columns: _zh ? ['项目', '状态', '说明'] : ['Item', 'Status', 'Note'],
              rows: _zh
                  ? [
                      ['位置', '用户工作区', _displayNameForPath(widget.workspace)],
                      [
                        '已就绪资产',
                        readySummary.isEmpty ? '暂无' : readySummary.join(' / '),
                        '来自真实工作区状态'
                      ],
                      [
                        '持久化',
                        runtime.hasImportedFile ? '已有记录' : '等待首个任务',
                        runtime.hasImportedFile ? '重启后可继续' : '导入资料后写入工作本'
                      ],
                      [
                        '当前工作本',
                        runtime.currentWorkbookName,
                        runtime.hasWorkbookManifest ? '已保存' : '等待保存'
                      ],
                      [
                        '工作本数量',
                        '${runtime.workbookNames.length}',
                        runtime.workbookNames.join(' / ')
                      ],
                      ['下一步', _dashboardNextStep(runtime, true), '从右侧入口继续'],
                    ]
                  : [
                      [
                        'Location',
                        'User workspace',
                        _displayNameForPath(widget.workspace)
                      ],
                      [
                        'Ready assets',
                        readySummary.isEmpty
                            ? 'None'
                            : readySummary.join(' / '),
                        'From real workspace state'
                      ],
                      [
                        'Persistence',
                        runtime.hasImportedFile ? 'Recorded' : 'Waiting',
                        runtime.hasImportedFile
                            ? 'Can continue after restart'
                            : 'Import sources to persist'
                      ],
                      [
                        'Current workbook',
                        runtime.currentWorkbookName,
                        runtime.hasWorkbookManifest ? 'Saved' : 'Waiting save'
                      ],
                      [
                        'Workbook count',
                        '${runtime.workbookNames.length}',
                        runtime.workbookNames.join(' / ')
                      ],
                      [
                        'Next',
                        _dashboardNextStep(runtime, false),
                        'Continue from the actions panel'
                      ],
                    ],
            ),
            const SizedBox(height: _DesktopGrid.gutter),
            TextField(
              key: const Key('workbook-name-input'),
              controller: _workbookNameController,
              decoration: InputDecoration(
                labelText: _zh ? '工作本名称' : 'Workbook name',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _createOrSwitchWorkbook(rc6),
            ),
            const SizedBox(height: 8),
            _EqualActionRow(children: [
              _PrimaryProductAction(
                label: _zh ? '创建 / 切换工作本' : 'Create / switch workbook',
                icon: Icons.add_to_photos_outlined,
                onPressed: rc6 == null || runtime.running
                    ? null
                    : () => _createOrSwitchWorkbook(rc6),
              ),
              for (final name in runtime.workbookNames.take(3))
                _DisplayAction(
                  label: name == runtime.currentWorkbookName
                      ? (_zh ? '当前：$name' : 'Current: $name')
                      : (_zh ? '切换到 $name' : 'Switch to $name'),
                  icon: Icons.workspaces_outline,
                  onPressed: rc6 == null ||
                          runtime.running ||
                          name == runtime.currentWorkbookName
                      ? null
                      : () => _createOrSwitchWorkbook(rc6, name: name),
                ),
              for (final name in runtime.workbookNames.take(3))
                _DisplayAction(
                  label: _zh ? '删除 $name' : 'Delete $name',
                  icon: Icons.delete_outline,
                  onPressed: rc6 == null ||
                          runtime.running ||
                          runtime.workbookNames.length <= 1
                      ? null
                      : () => _confirmAndDeleteWorkbook(rc6, name),
                ),
            ]),
          ],
        );
        final actions = _ProductPanel(
          keyName: 'workbook-next-actions',
          icon: Icons.route_outlined,
          title: _zh ? '继续任务' : 'Continue Work',
          minHeight: 320,
          children: [
            _PrimaryProductAction(
              label: _zh ? '进入文档库导入资料' : 'Open Document Library',
              icon: Icons.library_books_outlined,
              onPressed: () =>
                  widget.onPageChanged(_pageIndexById('document-library')),
            ),
            const SizedBox(height: 8),
            _DisplayAction(
              label: _zh ? '创建或更新知识库' : 'Create or update KB',
              icon: Icons.account_tree_outlined,
              onPressed: runtime.hasImportedFile
                  ? () => widget.onPageChanged(
                      _pageIndexById('knowledge-package-management'))
                  : null,
            ),
            const SizedBox(height: 8),
            _DisplayAction(
              label: _zh ? '检索验证证据' : 'Search and verify evidence',
              icon: Icons.manage_search_outlined,
              onPressed: runtime.hasKnowledgeBase
                  ? () => widget
                      .onPageChanged(_pageIndexById('retrieval-verification'))
                  : null,
            ),
            const SizedBox(height: 8),
            _DisplayAction(
              label: _zh ? '生成交付文档' : 'Generate deliverable document',
              icon: Icons.edit_document,
              onPressed: runtime.hasKnowledgeBase
                  ? () => widget
                      .onPageChanged(_pageIndexById('document-generation'))
                  : null,
            ),
          ],
        );
        final handoff = _ProductPanel(
          keyName: 'workbook-handoff',
          icon: Icons.inventory_2_outlined,
          title: _zh ? '资产承接' : 'Asset Handoff',
          minHeight: 260,
          children: [
            _ProductTable(
              columns: _zh
                  ? ['阶段', '输入', '输出', '下一步']
                  : ['Stage', 'Input', 'Output', 'Next'],
              rows: _zh
                  ? [
                      ['文档库', '本地资料', '来源文档 / 解析报告', '知识库'],
                      ['知识库', '来源文档', 'chunks / manifest / 质量报告', '检索验证'],
                      ['检索验证', '知识库', '证据片段 / 验证记录', '文档生成'],
                      ['知识应用', '可信证据', '文档 / Skill / Agent', '治理审计'],
                    ]
                  : [
                      [
                        'Document Library',
                        'Local sources',
                        'Documents / parse report',
                        'Knowledge Base'
                      ],
                      [
                        'Knowledge Base',
                        'Source documents',
                        'chunks / manifest / quality',
                        'Retrieval'
                      ],
                      [
                        'Retrieval',
                        'Knowledge bases',
                        'Evidence / validation record',
                        'Document Generation'
                      ],
                      [
                        'Knowledge Apps',
                        'Trusted evidence',
                        'Docs / Skills / Agents',
                        'Governance'
                      ],
                    ],
            ),
          ],
        );
        if (!wide) {
          return Column(children: [
            overview,
            const SizedBox(height: _DesktopGrid.gutter),
            actions,
            const SizedBox(height: _DesktopGrid.gutter),
            handoff,
          ]);
        }
        return Column(children: [
          _EqualHeightRow(
            height: 320,
            flexes: const [7, 5],
            children: [overview, actions],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          handoff,
        ]);
      }),
    ]);
  }
}
