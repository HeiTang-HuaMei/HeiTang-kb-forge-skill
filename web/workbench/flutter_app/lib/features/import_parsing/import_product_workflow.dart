part of '../../main.dart';

class _ImportStepAction {
  const _ImportStepAction(
      this.label, this.detail, this.icon, this.done, this.onPressed);

  final String label;
  final String detail;
  final IconData icon;
  final bool done;
  final VoidCallback? onPressed;
}

class _ImportStepActionGrid extends StatelessWidget {
  const _ImportStepActionGrid({required this.steps});

  final List<_ImportStepAction> steps;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 760
          ? 3
          : constraints.maxWidth >= 480
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
          mainAxisExtent: 86,
        ),
        itemBuilder: (context, index) {
          final step = steps[index];
          final enabled = step.onPressed != null;
          return Material(
            color: step.done
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
                    color: step.done ? colors.primary : colors.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(step.done ? Icons.check_circle_outline : step.icon,
                        color: enabled || step.done
                            ? colors.primary
                            : colors.onSurfaceVariant,
                        size: 20),
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

class _MiniProgressBar extends StatelessWidget {
  const _MiniProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 7,
        value: value,
        backgroundColor: colors.surfaceContainerHigh,
      ),
    );
  }
}

class _ImportHistoryList extends StatelessWidget {
  const _ImportHistoryList({
    required this.zh,
    required this.rows,
    required this.selectedRows,
    required this.onToggle,
    required this.onDelete,
    required this.onDeleteSelected,
    required this.onClear,
  });

  final bool zh;
  final List<List<String>> rows;
  final Set<int> selectedRows;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onDelete;
  final VoidCallback? onDeleteSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (var index = 0; index < rows.length; index++)
        MapEntry(index, rows[index])
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (visible.isEmpty)
          _RuntimeFeedbackBanner(
            title: zh ? '历史记录已清空' : 'History cleared',
            detail: zh
                ? '导入清单和下游产物已从当前工作区删除。'
                : 'Import manifest and downstream artifacts were deleted from this workspace.',
            tone: _StatusTone.neutral,
            icon: Icons.delete_sweep_outlined,
          )
        else ...[
          for (final entry in visible) ...[
            Material(
              type: MaterialType.transparency,
              child: CheckboxListTile(
                dense: true,
                value: selectedRows.contains(entry.key),
                onChanged: (_) => onToggle(entry.key),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(entry.value[0],
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${entry.value[1]} · ${entry.value[2]}',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                secondary: IconButton(
                  tooltip:
                      MaterialLocalizations.of(context).deleteButtonTooltip,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDelete(entry.key),
                ),
              ),
            ),
            if (entry != visible.last) const Divider(height: 8),
          ],
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDeleteSelected,
                icon: const Icon(Icons.delete_outline),
                label: Text(zh ? '删除选中' : 'Delete selected'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: visible.isEmpty ? null : onClear,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(zh ? '全部删除' : 'Delete all'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ImportProductWorkflow extends StatefulWidget {
  const _ImportProductWorkflow({
    required this.localeCode,
    required this.workspace,
    required this.isWebRuntime,
  });

  final String localeCode;
  final String workspace;
  final bool isWebRuntime;

  @override
  State<_ImportProductWorkflow> createState() => _ImportProductWorkflowState();
}

class _ImportProductWorkflowState extends State<_ImportProductWorkflow> {
  int stagedSources = 0;
  int preparedManifests = 0;
  final Set<int> selectedHistoryRows = <int>{};

  bool get _zh => widget.localeCode == 'zh-CN';

  Future<void> _chooseSource(Rc6RuntimeController? rc6) async {
    if (rc6 == null || rc6.state.running) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_zh ? '选择来源' : 'Choose source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(_zh ? '选择文件' : 'Choose file'),
                subtitle: Text(_zh ? '导入单个真实文档' : 'Import one real document'),
                onTap: () => Navigator.of(context).pop('file'),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: const Icon(Icons.drive_folder_upload_outlined),
                title: Text(_zh ? '选择文件夹' : 'Choose folder'),
                subtitle: Text(_zh
                    ? '批量导入文件夹内全部支持文件'
                    : 'Import supported files in a folder'),
                onTap: () => Navigator.of(context).pop('folder'),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: const Icon(Icons.link_outlined),
                title: Text(_zh ? '输入网页链接' : 'Enter web link'),
                subtitle: Text(_zh
                    ? '保存为文档库来源记录，授权后可联网抓取'
                    : 'Save as a library source record; fetching needs authorization'),
                onTap: () => Navigator.of(context).pop('web'),
              ),
            ),
          ],
        ),
      ),
    );
    if (choice == 'file') {
      await rc6.pickAndImportFile();
    } else if (choice == 'folder') {
      await rc6.pickAndImportFolder();
    } else if (choice == 'web') {
      final url = await _promptWebLink();
      if (url != null && url.trim().isNotEmpty) {
        await rc6.importWebLink(url);
      }
    }
  }

  Future<String?> _promptWebLink() {
    final controller = TextEditingController(text: 'https://');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_zh ? '输入网页链接' : 'Enter web link'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: _zh ? 'URL' : 'URL',
            helperText: _zh
                ? '未授权联网前只保存来源记录，不抓取正文。'
                : 'Without network authorization, only the source record is saved.',
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_zh ? '取消' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(_zh ? '导入链接' : 'Import link'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _confirmAndDeleteImport(Rc6RuntimeController? rc6) async {
    if (rc6 == null || rc6.state.running) return;
    final confirmed = await _confirmDestructiveAction(
      context,
      title: _zh ? '删除导入记录？' : 'Delete import records?',
      body: _zh
          ? '这会删除当前工作区内的导入清单、解析、知识库、检索和文档导出产物；不会删除原始输入文件夹。'
          : 'This deletes imported manifest, parsing, KB, retrieval, and document export artifacts in this workspace; the original source folder is not touched.',
    );
    if (!confirmed) return;
    setState(() => selectedHistoryRows.clear());
    await rc6.clearImportedSources();
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final hasSources = stagedSources > 0 || runtime.sourceCount > 0;
    final hasManifest = preparedManifests > 0 || runtime.hasImportedFile;
    final hasRealImport = runtime.hasImportedFile;
    final steps = <_ImportStepAction>[
      _ImportStepAction(
        _zh ? '1. 选择来源' : '1. Choose source',
        _zh ? '选择文件或文件夹' : 'Choose files or a folder',
        Icons.folder_open_outlined,
        runtime.hasImportedFile,
        runtime.running || rc6 == null ? null : () => _chooseSource(rc6),
      ),
      _ImportStepAction(
        _zh ? '2. 导入队列' : '2. Import queue',
        hasManifest
            ? (_zh
                ? '${runtime.sourceCount} 个文件已入队'
                : '${runtime.sourceCount} files queued')
            : (_zh ? '等待来源' : 'Waiting for source'),
        Icons.playlist_add_check_outlined,
        hasManifest,
        runtime.hasImportedFile ? () {} : null,
      ),
      _ImportStepAction(
        _zh ? '3. 解析' : '3. Parse',
        runtime.parseReportPath.isNotEmpty
            ? (_zh ? '解析报告已生成' : 'Parse report generated')
            : (_zh
                ? '运行 Parser / OCR / Chunking'
                : 'Run parser / OCR / chunking'),
        Icons.document_scanner_outlined,
        runtime.parseReportPath.isNotEmpty,
        runtime.running || rc6 == null || !runtime.hasImportedFile
            ? null
            : () => rc6.parseAndChunkSources(),
      ),
      _ImportStepAction(
        _zh ? '4. OCR 验收' : '4. OCR acceptance',
        runtime.parseReportPath.isNotEmpty
            ? (_zh ? 'OCR 记录进入 parse_report' : 'OCR record is in parse_report')
            : (_zh ? '解析完成后验收' : 'Accepted after parsing'),
        Icons.image_search_outlined,
        runtime.parseReportPath.isNotEmpty,
        runtime.parseReportPath.isNotEmpty ? () {} : null,
      ),
      _ImportStepAction(
        _zh ? '5. Chunking 验收' : '5. Chunking acceptance',
        runtime.chunkCount > 0
            ? '${runtime.chunkCount} chunks'
            : (_zh ? '等待切分产物' : 'Waiting for chunks'),
        Icons.segment_outlined,
        runtime.chunkCount > 0,
        runtime.chunkCount > 0 ? () {} : null,
      ),
      _ImportStepAction(
        _zh ? '6. 查看报告' : '6. View report',
        runtime.parseReportPath.isNotEmpty
            ? _displayNameForPath(runtime.parseReportPath)
            : (_zh ? '等待 parse_report.json' : 'Waiting for parse_report.json'),
        Icons.receipt_long_outlined,
        runtime.parseReportPath.isNotEmpty,
        runtime.parseReportPath.isNotEmpty ? () {} : null,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductHeader(
          icon: Icons.upload_file_outlined,
          title: _zh ? '导入与解析' : 'Import and Parsing',
          description: _zh
              ? '文件、文件夹与网页链接进入同一队列；解析器、OCR、分块和失败恢复在本页完成。'
              : 'Files, folders, and web links enter one queue; parser, OCR, chunking, and recovery are handled here.',
          trailing: _StatePill(
            label: widget.isWebRuntime
                ? (_zh ? 'Web 预览模式' : 'Web preview mode')
                : (_zh ? '桌面输入' : 'Desktop input'),
            icon: Icons.shield_outlined,
          ),
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _MetricStrip(
          items: [
            _MetricDatum(
                label: _zh ? '排队文件' : 'Queued files',
                value: runtime.sourceCount.toString(),
                detail: _zh ? '等待解析' : 'waiting',
                icon: Icons.file_present_outlined),
            _MetricDatum(
                label: _zh ? '解析后端' : 'Parser backends',
                value: '4',
                detail: _zh ? '证据登记' : 'registered',
                icon: Icons.document_scanner_outlined),
            _MetricDatum(
                label: _zh ? 'OCR' : 'OCR',
                value: _zh ? '已验收' : 'Accepted',
                detail: _zh ? 'PaddleOCR 本地运行' : 'PaddleOCR local',
                icon: Icons.image_search_outlined),
            _MetricDatum(
                label: _zh ? '失败恢复' : 'Recovery',
                value: hasManifest ? '2' : '0',
                detail: _zh ? '可重试项' : 'retryable',
                icon: Icons.restart_alt_outlined),
          ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _ImportStepActionGrid(steps: steps),
        const SizedBox(height: _DesktopGrid.gutter),
        if (hasSources || hasManifest) ...[
          _RuntimeFeedbackBanner(
            title: hasRealImport
                ? (_zh ? '真实导入清单已生成' : 'Real import manifest created')
                : hasManifest
                    ? (_zh ? '导入清单已准备' : 'Import manifest prepared')
                    : (_zh ? '等待真实来源' : 'Waiting for real source'),
            detail: hasRealImport
                ? runtime.sourceManifestPath
                : (_zh
                    ? '请选择真实文件或文件夹以生成 source_manifest.json。'
                    : 'Choose real files or a folder to write source_manifest.json.'),
            tone: hasRealImport ? _StatusTone.success : _StatusTone.warning,
            icon: hasRealImport ? Icons.verified_outlined : Icons.info_outline,
          ),
          const SizedBox(height: _DesktopGrid.gutter),
        ],
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;
          final intake = _ProductPanel(
            keyName: 'import-intake-surface',
            accent: true,
            icon: Icons.folder_open_outlined,
            title: _zh ? '来源入口' : 'Source Intake',
            minHeight: 410,
            subtitle: _zh
                ? '选择文件或文件夹后进入同一导入队列；网页链接由授权 Provider 配置后启用。'
                : 'Files and folders enter one queue; web links require authorized Provider config.',
            children: [
              _ImportStepActionGrid(steps: steps),
              const SizedBox(height: _DesktopGrid.gutter),
              _PrimaryProductAction(
                label: _zh ? '选择来源' : 'Choose source',
                onPressed: runtime.running || rc6 == null
                    ? null
                    : () => _chooseSource(rc6),
                icon: Icons.folder_open_outlined,
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              _MiniProgressBar(
                  value: runtime.parseReportPath.isNotEmpty
                      ? 1
                      : hasManifest
                          ? 0.68
                          : 0.12),
              const SizedBox(height: 8),
              _PrimaryProductAction(
                label: _zh ? '解析 / OCR / Chunking' : 'Parse / OCR / Chunking',
                onPressed: runtime.running || rc6 == null
                    ? null
                    : () => rc6.parseAndChunkSources(),
                icon: Icons.document_scanner_outlined,
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              _DisplayAction(
                label: _zh ? '一键完成到解析报告' : 'Run source-to-parse in one click',
                icon: Icons.auto_mode_outlined,
                onPressed:
                    runtime.running || rc6 == null || !runtime.hasImportedFile
                        ? null
                        : () => rc6.parseAndChunkSources(),
              ),
            ],
          );
          final queue = _ProductPanel(
            keyName: 'import-queue',
            icon: Icons.list_alt_outlined,
            title: _zh ? '文件队列与进度' : 'File Queue and Progress',
            minHeight: 326,
            children: [
              _ProductTable(
                columns: _zh
                    ? ['文件', '来源类型', '进度', '状态', '失败恢复', '输出产物']
                    : [
                        'File',
                        'Source type',
                        'Progress',
                        'Status',
                        'Recovery',
                        'Output artifact'
                      ],
                rows: _zh
                    ? [
                        [
                          hasRealImport
                              ? _displayNameForPath(runtime.selectedFilePath)
                              : '等待本地文件',
                          '文件',
                          hasManifest ? '100%' : '0%',
                          hasRealImport ? '已导入' : '待输入',
                          hasManifest ? '无需恢复' : '待生成清单',
                          'source_manifest.json'
                        ],
                        if (hasManifest)
                          [
                            '解析 / OCR / Chunking',
                            '本地解析',
                            runtime.parseReportPath.isNotEmpty ? '100%' : '处理中',
                            runtime.parseReportPath.isNotEmpty ? '已解析' : '排队',
                            '失败可重试',
                            'parse_report.json'
                          ],
                      ]
                    : [
                        [
                          hasRealImport
                              ? _displayNameForPath(runtime.selectedFilePath)
                              : 'Waiting for local files',
                          'File',
                          hasManifest ? '100%' : '0%',
                          hasRealImport ? 'Imported' : 'Pending',
                          hasManifest ? 'No recovery' : 'Prepare manifest',
                          'source_manifest.json'
                        ],
                        if (hasManifest)
                          [
                            'Parse / OCR / Chunking',
                            'Local parser',
                            runtime.parseReportPath.isNotEmpty
                                ? '100%'
                                : 'Running',
                            runtime.parseReportPath.isNotEmpty
                                ? 'Parsed'
                                : 'Queued',
                            'Retryable on failure',
                            'parse_report.json'
                          ],
                      ],
              ),
            ],
          );
          final settings = _ProductPanel(
            keyName: 'parser-settings',
            icon: Icons.tune_outlined,
            title: _zh ? '解析器 / OCR / 分块' : 'Parser / OCR / Chunking',
            minHeight: 410,
            children: [
              _ProductTable(
                columns:
                    _zh ? ['配置项', '当前值', '分类'] : ['Setting', 'Value', 'Class'],
                rows: _zh
                    ? [
                        ['解析器', 'HeiTang Parser / builtin', '可用'],
                        ['OCR', 'PaddleOCR PP-OCRv6 local runtime', '可用'],
                        ['分块', '语义切分，800 tokens，120 overlap', '可用'],
                        ['语言', '中文 + 英文', '可用'],
                      ]
                    : [
                        ['Parser', 'HeiTang Parser / builtin', 'Available'],
                        [
                          'OCR',
                          'PaddleOCR PP-OCRv6 local runtime',
                          'Available'
                        ],
                        [
                          'Chunking',
                          'Semantic, 800 tokens, 120 overlap',
                          'Available'
                        ],
                        ['Language', 'Chinese + English', 'Available'],
                      ],
              ),
            ],
          );
          final manifest = _ProductPanel(
            keyName: 'manifest-preview',
            icon: Icons.description_outlined,
            title: _zh ? '导入历史与输出清单' : 'Import History and Manifest',
            minHeight: 326,
            children: [
              _ImportHistoryList(
                zh: _zh,
                rows: _zh
                    ? [
                        [
                          'source_manifest.json',
                          hasRealImport ? '已生成' : '等待',
                          '来源清单'
                        ],
                        [
                          'parse_report.json',
                          runtime.parseReportPath.isNotEmpty ? '已生成' : '等待',
                          '解析报告'
                        ],
                        [
                          '失败恢复',
                          hasManifest ? '可重试 / 可跳过 / 可查看错误' : '等待解析',
                          '恢复操作'
                        ],
                        ['下一阶段', '文档库', '来源文档管理'],
                      ]
                    : [
                        [
                          'source_manifest.json',
                          hasRealImport ? 'Written' : 'Waiting',
                          'Source inventory'
                        ],
                        [
                          'parse_report.json',
                          runtime.parseReportPath.isNotEmpty
                              ? 'Written'
                              : 'Waiting',
                          'Parsing report'
                        ],
                        [
                          'Failure recovery',
                          hasManifest
                              ? 'Retry / skip / view error'
                              : 'Waiting parse',
                          'Recovery actions'
                        ],
                        ['Next stage', 'Document Library', 'Source management'],
                      ],
                selectedRows: selectedHistoryRows,
                onToggle: (index) => setState(() {
                  if (!selectedHistoryRows.add(index)) {
                    selectedHistoryRows.remove(index);
                  }
                }),
                onDelete: (_) => _confirmAndDeleteImport(rc6),
                onDeleteSelected: selectedHistoryRows.isEmpty
                    ? null
                    : () => _confirmAndDeleteImport(rc6),
                onClear: () => _confirmAndDeleteImport(rc6),
              ),
            ],
          );
          if (!wide) {
            return Column(children: [
              intake,
              const SizedBox(height: _DesktopGrid.gutter),
              settings,
              const SizedBox(height: _DesktopGrid.gutter),
              queue,
              const SizedBox(height: _DesktopGrid.gutter),
              manifest,
            ]);
          }
          return Column(children: [
            _EqualHeightRow(
              height: 410,
              flexes: const [7, 5],
              children: [intake, settings],
            ),
            const SizedBox(height: _DesktopGrid.gutter),
            _EqualHeightRow(
              height: 326,
              flexes: const [7, 5],
              children: [queue, manifest],
            ),
          ]);
        }),
      ],
    );
  }
}
