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
      if (runtime.hasSkill) _zh ? '技能' : 'Skill',
      if (runtime.hasAgent) _zh ? '助手' : 'Assistant',
    ];
    return _FigmaPageCanvas(children: [
      SizedBox(
        height: 120,
        child: _FigmaHighlightCard(
          keyName: 'workbook-hero',
          icon: Icons.workspaces_outline,
          title: _zh ? '工作区' : 'Workspace',
          description: _zh
              ? '每个工作区独立保存资料、知识库、技能、助手和成果。'
              : 'Each workspace keeps materials, knowledge bases, skills, assistants, and outputs isolated.',
          actions: [
            SizedBox(
              width: 150,
              child: _PrimaryProductAction(
                label: _zh ? '创建工作区' : 'Create workspace',
                icon: Icons.add_to_photos_outlined,
                onPressed: rc6 == null || runtime.running
                    ? null
                    : () => _createOrSwitchWorkbook(rc6),
              ),
            ),
          ],
        ),
      ),
      SizedBox(
        height: 116,
        child: _FigmaCard(
          keyName: 'workbook-boundary',
          padding: const EdgeInsets.fromLTRB(30, 22, 30, 22),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _HTKWTokens.sageSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.lock_outline,
                    color: _HTKWTokens.sage, size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _zh ? '隔离边界真实生效' : 'Isolation boundary is enforced',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _zh
                          ? '工作区之间默认不共享文档库、知识库、技能、助手记忆和工作小组记录。'
                          : 'Workspaces do not share document libraries, knowledge bases, skills, assistant memory, or discussion records by default.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _HTKWTokens.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      _FigmaFixedRow(
        height: 360,
        widths: const [540, 542],
        children: [
          _FigmaCard(
            keyName: 'workbook-overview',
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: _LocalScrollBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FigmaSectionHeader(
                    icon: Icons.space_dashboard_outlined,
                    title: _zh ? '工作区资产' : 'Workspace Assets',
                  ),
                  const SizedBox(height: 18),
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
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ProductTable(
                    columns:
                        _zh ? ['项目', '状态', '说明'] : ['Item', 'Status', 'Note'],
                    rows: _zh
                        ? [
                            [
                              '位置',
                              '用户工作区',
                              _displayNameForPath(widget.workspace)
                            ],
                            [
                              '已就绪资产',
                              readySummary.isEmpty
                                  ? '暂无'
                                  : readySummary.join(' / '),
                              '来自真实工作区状态'
                            ],
                            [
                              '当前工作本',
                              runtime.currentWorkbookName,
                              runtime.hasWorkbookManifest ? '已保存' : '等待保存'
                            ],
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
                              'Current workbook',
                              runtime.currentWorkbookName,
                              runtime.hasWorkbookManifest
                                  ? 'Saved'
                                  : 'Waiting save'
                            ],
                          ],
                  ),
                ],
              ),
            ),
          ),
          _FigmaCard(
            keyName: 'workbook-boundary-detail',
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: _LocalScrollBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FigmaSectionHeader(
                    icon: Icons.rule_folder_outlined,
                    title: _zh ? '边界说明' : 'Boundary Detail',
                  ),
                  const SizedBox(height: 18),
                  _ProductTable(
                    columns: _zh
                        ? ['资产层', '隔离方式', '默认行为']
                        : ['Layer', 'Boundary', 'Default'],
                    rows: _zh
                        ? [
                            ['文档库', '按工作区保存', '不跨工作区串联'],
                            ['知识库', '按来源文档生成', '不共享索引'],
                            ['技能', '按工作区产物保存', '可手动复用'],
                            ['助手记忆', '按助手与任务保存', '协作记忆不跨区'],
                          ]
                        : [
                            [
                              'Document library',
                              'workspace scoped',
                              'not shared'
                            ],
                            [
                              'Knowledge base',
                              'source scoped',
                              'index isolated'
                            ],
                            [
                              'Skills',
                              'workspace artifacts',
                              'manual reuse only'
                            ],
                            [
                              'Assistant memory',
                              'assistant/task scoped',
                              'not cross-workspace'
                            ],
                          ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _zh ? '创建 / 切换工作本' : 'Create / switch workbook',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: _HTKWTokens.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('workbook-name-input'),
                    controller: _workbookNameController,
                    decoration: InputDecoration(
                      labelText: _zh ? '工作区名称' : 'Workspace name',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _createOrSwitchWorkbook(rc6),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: runtime.workbookNames.length > 1 &&
                              rc6 != null &&
                              !runtime.running
                          ? () => _confirmAndDeleteWorkbook(
                              rc6, runtime.currentWorkbookName)
                          : null,
                      child: Text(_zh
                          ? '删除 ${runtime.currentWorkbookName}'
                          : 'Delete ${runtime.currentWorkbookName}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      SizedBox(
        height: 80,
        child: _FigmaCard(
          keyName: 'workbook-next-actions',
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _zh ? '继续任务' : 'Continue Work',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              SizedBox(
                width: 190,
                child: _PrimaryProductAction(
                  label: _zh ? '进入文档库' : 'Open Library',
                  icon: Icons.library_books_outlined,
                  onPressed: () =>
                      widget.onPageChanged(_pageIndexById('document-library')),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 190,
                child: _DisplayAction(
                  label: _zh ? '生成知识库' : 'Create KB',
                  icon: Icons.account_tree_outlined,
                  onPressed: runtime.hasImportedFile
                      ? () => widget.onPageChanged(
                          _pageIndexById('knowledge-package-management'))
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 190,
                child: _MoreActionsButton(
                  label: _zh ? '更多工作区操作' : 'More workspace actions',
                  actions: [
                    for (final name in runtime.workbookNames.take(3))
                      _MoreMenuAction(
                        label: name == runtime.currentWorkbookName
                            ? (_zh ? '当前：$name' : 'Current: $name')
                            : (_zh ? '切换到 $name' : 'Switch to $name'),
                        icon: Icons.workspaces_outline,
                        enabled: rc6 != null &&
                            !runtime.running &&
                            name != runtime.currentWorkbookName,
                        onSelected: () =>
                            _createOrSwitchWorkbook(rc6, name: name),
                      ),
                    for (final name in runtime.workbookNames.take(3))
                      _MoreMenuAction(
                        label: _zh ? '删除 $name' : 'Delete $name',
                        icon: Icons.delete_outline,
                        destructive: true,
                        enabled: rc6 != null &&
                            !runtime.running &&
                            runtime.workbookNames.length > 1,
                        onSelected: () => _confirmAndDeleteWorkbook(rc6, name),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}
