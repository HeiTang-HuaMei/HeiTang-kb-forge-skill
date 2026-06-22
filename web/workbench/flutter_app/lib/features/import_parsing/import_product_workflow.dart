part of '../../main.dart';

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
    final capabilityAuditReady = runtime.hasProviderCapabilityUserCatalog;
    final parserCapabilityStatus = runtime.parseReportPath.isNotEmpty
        ? (_zh ? '已整理' : 'Organized')
        : capabilityAuditReady
            ? (_zh ? '已配置，等待整理' : 'Configured, waiting organization')
            : (_zh ? '使用本地模式' : 'Using local mode');
    final ocrCapabilityStatus = capabilityAuditReady
        ? (_zh ? '按当前配置可用' : 'Available in current profile')
        : (_zh ? '未配置，使用本地模式' : 'Not configured, local mode');
    final webImportStatus = capabilityAuditReady
        ? (_zh ? '按网络授权显示' : 'Controlled by network authorization')
        : (_zh ? '本地资料可用' : 'Local sources available');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductHeader(
          icon: Icons.upload_file_outlined,
          title: _zh ? '添加与整理资料' : 'Add and Organize Materials',
          description: _zh
              ? '文件、文件夹与网页链接进入同一队列；整理资料和失败恢复在本页完成。'
              : 'Files, folders, and web links enter one queue; organization and recovery are handled here.',
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
                label: _zh ? '来源文档' : 'Sources',
                value: runtime.sourceCount.toString(),
                detail: hasRealImport
                    ? (_zh ? '已导入' : 'imported')
                    : (_zh ? '等待导入' : 'waiting'),
                icon: Icons.file_present_outlined),
            _MetricDatum(
                label: _zh ? '整理状态' : 'Organization status',
                value: runtime.parseReportPath.isNotEmpty
                    ? (_zh ? '已完成' : 'Done')
                    : (_zh ? '待整理' : 'Waiting'),
                detail: runtime.chunkCount > 0
                    ? (_zh
                        ? '${runtime.chunkCount} 个片段'
                        : '${runtime.chunkCount} segments')
                    : (_zh ? '等待整理' : 'waiting'),
                icon: Icons.document_scanner_outlined),
          ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        if (hasSources || hasManifest) ...[
          _RuntimeFeedbackBanner(
            title: hasRealImport
                ? (_zh ? '来源已导入' : 'Sources imported')
                : hasManifest
                    ? (_zh ? '来源已准备' : 'Sources prepared')
                    : (_zh ? '等待真实来源' : 'Waiting for real source'),
            detail: hasRealImport
                ? '${runtime.sourceCount} ${_zh ? '个来源文档' : 'source documents'}'
                : (_zh ? '暂无来源文档' : 'No source documents'),
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
            title: _zh ? '资料入口' : 'Material Intake',
            minHeight: 410,
            children: [
              _PrimaryProductAction(
                label: _zh ? '添加资料' : 'Add materials',
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
                label: _zh ? '整理资料' : 'Organize materials',
                onPressed:
                    runtime.running || rc6 == null || !runtime.hasImportedFile
                        ? null
                        : () => rc6.parseAndChunkSources(),
                icon: Icons.document_scanner_outlined,
              ),
            ],
          );
          final queue = _ProductPanel(
            keyName: 'import-queue',
            icon: Icons.list_alt_outlined,
            title: _zh ? '资料队列与进度' : 'Material Queue and Progress',
            minHeight: 326,
            children: [
              _ProductTable(
                columns: _zh
                    ? ['资料', '来源类型', '处理状态', '状态', '失败恢复', '输出结果']
                    : [
                        'File',
                        'Source type',
                        'Processing',
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
                          hasManifest ? '已完成' : '未完成',
                          hasRealImport ? '已导入' : '待输入',
                          hasManifest ? '无需恢复' : '待生成清单',
                          '来源文档'
                        ],
                        if (hasManifest)
                          [
                            '整理资料',
                            '本地模式',
                            runtime.parseReportPath.isNotEmpty ? '已完成' : '处理中',
                            runtime.parseReportPath.isNotEmpty ? '已整理' : '排队',
                            '失败可重试',
                            '整理结果'
                          ],
                      ]
                    : [
                        [
                          hasRealImport
                              ? _displayNameForPath(runtime.selectedFilePath)
                              : 'Waiting for local files',
                          'File',
                          hasManifest ? 'Done' : 'Not done',
                          hasRealImport ? 'Imported' : 'Pending',
                          hasManifest ? 'No recovery' : 'Prepare manifest',
                          'Source documents'
                        ],
                        if (hasManifest)
                          [
                            'Organize materials',
                            'Local mode',
                            runtime.parseReportPath.isNotEmpty
                                ? 'Done'
                                : 'Running',
                            runtime.parseReportPath.isNotEmpty
                                ? 'Organized'
                                : 'Queued',
                            'Retryable on failure',
                            'Organized results'
                          ],
                      ],
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              _ProductTable(
                columns: _zh
                    ? ['能力', '当前状态', '用户可见结果']
                    : ['Capability', 'Current status', 'User result'],
                rows: _zh
                    ? [
                        ['资料整理', parserCapabilityStatus, '整理后进入文档库'],
                        ['图片文字识别', ocrCapabilityStatus, '图片文本随整理记录留痕'],
                        ['网页导入', webImportStatus, '关闭时本地导入不受影响'],
                      ]
                    : [
                        [
                          'Material organization',
                          parserCapabilityStatus,
                          'Organized content enters the library'
                        ],
                        [
                          'Image text recognition',
                          ocrCapabilityStatus,
                          'Image text is recorded with organization'
                        ],
                        [
                          'Web import',
                          webImportStatus,
                          'Local import remains available when disabled'
                        ],
                      ],
              ),
            ],
          );
          final manifest = _ProductPanel(
            keyName: 'manifest-preview',
            icon: Icons.description_outlined,
            title: _zh ? '导入历史' : 'Import History',
            minHeight: 326,
            children: [
              _ImportHistoryList(
                zh: _zh,
                rows: _zh
                    ? [
                        [
                          '来源文档',
                          hasRealImport ? '已生成' : '等待',
                          '${runtime.sourceCount} 个来源'
                        ],
                        [
                          '解析结果',
                          runtime.parseReportPath.isNotEmpty ? '已生成' : '等待',
                          runtime.chunkCount > 0
                              ? '${runtime.chunkCount} 个片段'
                              : '等待整理'
                        ],
                        [
                          '失败恢复',
                          hasManifest ? '可重试 / 可跳过 / 可查看错误' : '等待整理',
                          '恢复操作'
                        ],
                        ['下一阶段', '文档库', '来源文档管理'],
                      ]
                    : [
                        [
                          'Source documents',
                          hasRealImport ? 'Written' : 'Waiting',
                          '${runtime.sourceCount} sources'
                        ],
                        [
                          'Parse results',
                          runtime.parseReportPath.isNotEmpty
                              ? 'Written'
                              : 'Waiting',
                          runtime.chunkCount > 0
                              ? '${runtime.chunkCount} segments'
                              : 'Waiting organization'
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
              queue,
              const SizedBox(height: _DesktopGrid.gutter),
              manifest,
            ]);
          }
          return Column(children: [
            _EqualHeightRow(
              height: 410,
              flexes: const [7, 5],
              children: [intake, queue],
            ),
            const SizedBox(height: _DesktopGrid.gutter),
            manifest,
          ]);
        }),
      ],
    );
  }
}
