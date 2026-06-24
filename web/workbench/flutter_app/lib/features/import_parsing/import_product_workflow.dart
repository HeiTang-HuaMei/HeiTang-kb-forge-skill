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
  final TextEditingController _localPathController =
      TextEditingController(text: r'D:\HeiTang-Codex-WorkSpace\input');

  bool get _zh => widget.localeCode == 'zh-CN';

  @override
  void dispose() {
    _localPathController.dispose();
    super.dispose();
  }

  Future<void> _importFile(Rc6RuntimeController? rc6) async {
    if (rc6 == null || rc6.state.running) return;
    await rc6.pickAndImportFile();
  }

  Future<void> _importFolder(Rc6RuntimeController? rc6) async {
    if (rc6 == null || rc6.state.running) return;
    await rc6.pickAndImportFolder();
  }

  Future<void> _importLocalPath(Rc6RuntimeController? rc6) async {
    if (rc6 == null || rc6.state.running) return;
    await rc6.importLocalPath(_localPathController.text);
  }

  Future<void> _importWebLink(Rc6RuntimeController? rc6) async {
    if (rc6 == null || rc6.state.running) return;
    final url = await _promptWebLink();
    if (url != null && url.trim().isNotEmpty) {
      await rc6.importWebLink(url);
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
    final hasManifest = preparedManifests > 0 || runtime.hasImportedFile;
    final hasRealImport = runtime.hasImportedFile;
    final capabilityAuditReady = runtime.hasProviderCapabilityUserCatalog;
    final ocrCapabilityStatus = capabilityAuditReady
        ? (_zh ? '按当前配置可用' : 'Available in current profile')
        : (_zh ? '未配置，使用本地模式' : 'Not configured, local mode');
    final webImportStatus = capabilityAuditReady
        ? (_zh ? '按网络授权显示' : 'Controlled by network authorization')
        : (_zh ? '本地资料可用' : 'Local sources available');
    Widget statCard({
      required String label,
      required String value,
      required String detail,
      required IconData icon,
    }) {
      final colors = Theme.of(context).colorScheme;
      return Expanded(
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _HTKWTokens.goldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _HTKWTokens.gold, size: 19),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                              height: 1.08,
                            )),
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.labelMedium,
                        children: [
                          TextSpan(
                            text: value,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: _HTKWTokens.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                ),
                          ),
                          TextSpan(
                            text: '  $detail',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: _HTKWTokens.textTertiary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.05,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget actionTile({
      required String label,
      required IconData icon,
      required VoidCallback? onPressed,
      bool primary = false,
      String? automationKey,
    }) {
      final child = primary
          ? FilledButton.icon(
              key: automationKey == null
                  ? null
                  : ValueKey<String>(automationKey),
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label, overflow: TextOverflow.ellipsis),
            )
          : OutlinedButton.icon(
              key: automationKey == null
                  ? null
                  : ValueKey<String>(automationKey),
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label, overflow: TextOverflow.ellipsis),
            );
      return Expanded(
        child: Semantics(
          button: true,
          label: automationKey ?? label,
          child: Tooltip(
            message: label,
            child: SizedBox(height: 42, child: child),
          ),
        ),
      );
    }

    Widget queueRow({
      required String name,
      required String status,
      required String result,
      required _StatusTone tone,
    }) {
      final color = _HTKWTokens.toneColor(tone);
      return Container(
        height: 39,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
            ),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: _HTKWTokens.toneSurface(tone),
                    borderRadius:
                        BorderRadius.circular(_DesktopGrid.chipRadius),
                    border: Border.all(color: color.withValues(alpha: 0.24)),
                  ),
                  child: Text(status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          )),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(result,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: _HTKWTokens.textSecondary,
                        fontWeight: FontWeight.w800,
                      )),
            ),
          ],
        ),
      );
    }

    Widget historyCell(String label, String value) {
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _HTKWTokens.textTertiary,
                      fontWeight: FontWeight.w900,
                    )),
            const SizedBox(height: 4),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    )),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 920;
      final localCount = runtime.sourceRecords
          .where((source) => source.sourceType != 'web')
          .length;
      final webCount = runtime.sourceRecords
          .where((source) => source.sourceType == 'web')
          .length;
      final importedCount = runtime.sourceRecords.isEmpty
          ? runtime.sourceCount
          : runtime.sourceRecords.length;
      final organizedStatus = runtime.parseReportPath.isNotEmpty
          ? (_zh ? '已整理' : 'Organized')
          : hasRealImport
              ? (_zh ? '待整理' : 'Waiting')
              : (_zh ? '需要先添加资料' : 'Add materials first');
      final left = _ProductPanel(
        keyName: 'import-intake-surface',
        accent: true,
        icon: Icons.folder_open_outlined,
        title: _zh ? '添加与整理资料' : 'Add and Organize Materials',
        minHeight: 360,
        children: [
          Row(children: [
            statCard(
              label: _zh ? '本地资料' : 'Local materials',
              value: localCount.toString(),
              detail: hasRealImport
                  ? (_zh ? '已导入' : 'Imported')
                  : (_zh ? '等待添加' : 'Waiting'),
              icon: Icons.insert_drive_file_outlined,
            ),
            const SizedBox(width: 12),
            statCard(
              label: _zh ? '外部链接' : 'External links',
              value: webCount.toString(),
              detail: capabilityAuditReady
                  ? (_zh ? '按授权处理' : 'By authorization')
                  : (_zh ? '本地模式' : 'Local mode'),
              icon: Icons.link_outlined,
            ),
          ]),
          const SizedBox(height: 14),
          _SectionCaption(_zh ? '资料入口' : 'Material Intake'),
          const SizedBox(height: 8),
          Column(children: [
            Row(children: [
              actionTile(
                label: _zh ? '添加文件' : 'Add file',
                icon: Icons.upload_file_outlined,
                onPressed: runtime.running || rc6 == null
                    ? null
                    : () => _importFile(rc6),
                automationKey: 'workbench.import.add_file',
                primary: true,
              ),
              const SizedBox(width: 10),
              actionTile(
                label: _zh ? '添加文件夹' : 'Add folder',
                icon: Icons.drive_folder_upload_outlined,
                onPressed: runtime.running || rc6 == null
                    ? null
                    : () => _importFolder(rc6),
                automationKey: 'workbench.import.add_folder',
              ),
            ]),
            const SizedBox(height: 10),
            Semantics(
              textField: true,
              label: 'workbench.import.local_path_input',
              child: TextField(
                key:
                    const ValueKey<String>('workbench.import.local_path_input'),
                controller: _localPathController,
                enabled: !runtime.running && rc6 != null,
                onSubmitted: (_) => _importLocalPath(rc6),
                decoration: InputDecoration(
                  labelText: _zh ? '导入本地路径' : 'Import local path',
                  hintText: _zh
                      ? r'粘贴文件或文件夹路径，例如 D:\HeiTang-Codex-WorkSpace\input'
                      : r'Paste a file or folder path, e.g. D:\HeiTang-Codex-WorkSpace\input',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              actionTile(
                label: _zh ? '导入路径' : 'Import path',
                icon: Icons.input_outlined,
                onPressed: runtime.running || rc6 == null
                    ? null
                    : () => _importLocalPath(rc6),
                automationKey: 'workbench.import.local_path_button',
                primary: true,
              ),
              const SizedBox(width: 10),
              actionTile(
                label: _zh ? '运行主链路' : 'Run main chain',
                icon: Icons.play_circle_outline,
                onPressed: runtime.running || rc6 == null
                    ? null
                    : () => rc6.runRealInputFolderE2E(
                          _localPathController.text,
                        ),
                automationKey: 'workbench.import.run_main_chain_button',
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              actionTile(
                label: _zh ? '添加链接' : 'Add link',
                icon: Icons.link_outlined,
                onPressed: runtime.running || rc6 == null
                    ? null
                    : () => _importWebLink(rc6),
                automationKey: 'workbench.import.add_link',
              ),
              const SizedBox(width: 10),
              actionTile(
                label: _zh ? '整理资料' : 'Organize',
                icon: Icons.document_scanner_outlined,
                onPressed:
                    runtime.running || rc6 == null || !runtime.hasImportedFile
                        ? null
                        : () => rc6.parseAndChunkSources(),
                automationKey: 'workbench.import.organize_button',
                primary: true,
              ),
            ]),
          ]),
          const SizedBox(height: 14),
          _MiniProgressBar(
              value: runtime.parseReportPath.isNotEmpty
                  ? 1
                  : hasManifest
                      ? 0.68
                      : 0.12),
          const SizedBox(height: 8),
          _RuntimeFeedbackBanner(
            title: hasRealImport
                ? (_zh ? '来源已进入文档库' : 'Sources are in the library')
                : (_zh ? '需要先添加资料' : 'Add materials first'),
            detail: _zh
                ? '资料整理后可用于生成知识库、验证知识库和生成文档。'
                : 'Organized materials can be used to build KBs, test KBs, and generate documents.',
            tone: hasRealImport ? _StatusTone.success : _StatusTone.warning,
            icon: hasRealImport ? Icons.verified_outlined : Icons.info_outline,
          ),
        ],
      );
      final right = _ProductPanel(
        keyName: 'import-queue',
        icon: Icons.list_alt_outlined,
        title: _zh ? '资料队列与进度' : 'Material Queue and Progress',
        minHeight: 360,
        children: [
          Row(children: [
            statCard(
              label: _zh ? '已整理' : 'Organized',
              value: runtime.parseReportPath.isNotEmpty
                  ? importedCount.toString()
                  : '0',
              detail: runtime.chunkCount > 0
                  ? (_zh
                      ? '${runtime.chunkCount} 片段'
                      : '${runtime.chunkCount} chunks')
                  : (_zh ? '等待整理' : 'Waiting'),
              icon: Icons.task_alt_outlined,
            ),
            const SizedBox(width: 10),
            statCard(
              label: _zh ? '待整理' : 'Pending',
              value: runtime.parseReportPath.isNotEmpty
                  ? '0'
                  : importedCount.toString(),
              detail: hasRealImport
                  ? (_zh ? '可整理' : 'Ready')
                  : (_zh ? '无资料' : 'No source'),
              icon: Icons.pending_actions_outlined,
            ),
            const SizedBox(width: 10),
            statCard(
              label: _zh ? '需要设置' : 'Needs setup',
              value: capabilityAuditReady ? '0' : '1',
              detail: capabilityAuditReady
                  ? (_zh ? '已配置' : 'Configured')
                  : (_zh ? '本地模式' : 'Local mode'),
              icon: Icons.tune_outlined,
            ),
          ]),
          const SizedBox(height: 14),
          _SectionCaption(_zh ? '处理队列' : 'Processing queue'),
          const SizedBox(height: 8),
          queueRow(
            name: _zh ? '来源文档' : 'Source documents',
            status: hasRealImport
                ? (_zh ? '已导入' : 'Imported')
                : (_zh ? '待添加' : 'Pending'),
            result: hasRealImport
                ? '${runtime.sourceCount} ${_zh ? '个来源' : 'sources'}'
                : (_zh ? '添加后出现' : 'Shown after import'),
            tone: hasRealImport ? _StatusTone.success : _StatusTone.warning,
          ),
          const SizedBox(height: 8),
          queueRow(
            name: _zh ? '资料整理' : 'Organization',
            status: organizedStatus,
            result: runtime.chunkCount > 0
                ? (_zh
                    ? '${runtime.chunkCount} 个片段'
                    : '${runtime.chunkCount} chunks')
                : (_zh ? '等待整理结果' : 'Waiting result'),
            tone: runtime.parseReportPath.isNotEmpty
                ? _StatusTone.success
                : _StatusTone.warning,
          ),
          const SizedBox(height: 8),
          queueRow(
            name: _zh ? '图片文字识别' : 'Image text',
            status: ocrCapabilityStatus,
            result: _zh ? '随整理记录' : 'With organization',
            tone: capabilityAuditReady
                ? _StatusTone.success
                : _StatusTone.neutral,
          ),
          const SizedBox(height: 8),
          queueRow(
            name: _zh ? '网页导入' : 'Web import',
            status: webImportStatus,
            result: _zh ? '未授权时只保存来源' : 'Source-only if unauthorized',
            tone: capabilityAuditReady
                ? _StatusTone.success
                : _StatusTone.neutral,
          ),
        ],
      );
      final history = SizedBox(
        height: 118,
        child: _FigmaCard(
          keyName: 'manifest-preview',
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Row(
            children: [
              SizedBox(
                width: 190,
                child: _FigmaSectionHeader(
                  icon: Icons.history_outlined,
                  title: _zh ? '导入历史' : 'Import History',
                  subtitle: _zh ? '最近记录' : 'Recent records',
                ),
              ),
              const SizedBox(width: 18),
              historyCell(
                  _zh ? '最近导入' : 'Latest import',
                  hasRealImport
                      ? _displayNameForPath(runtime.selectedFilePath)
                      : (_zh ? '等待资料' : 'Waiting')),
              historyCell(
                  _zh ? '来源' : 'Source',
                  hasRealImport
                      ? (_zh ? '本地文件' : 'Local file')
                      : (_zh ? '未添加' : 'Not added')),
              historyCell(_zh ? '状态' : 'Status', organizedStatus),
              historyCell(_zh ? '使用去向' : 'Used by',
                  _zh ? '知识库 / 文档' : 'KB / documents'),
              const SizedBox(width: 16),
              SizedBox(
                width: 126,
                child: OutlinedButton.icon(
                  onPressed: rc6 == null || runtime.running || !hasManifest
                      ? null
                      : () => _confirmAndDeleteImport(rc6),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(_zh ? '清空记录' : 'Clear'),
                ),
              ),
            ],
          ),
        ),
      );

      if (!wide) {
        return Column(children: [
          left,
          const SizedBox(height: _DesktopGrid.gutter),
          right,
          const SizedBox(height: _DesktopGrid.gutter),
          history,
        ]);
      }
      return Column(children: [
        _EqualHeightRow(
          height: 388,
          flexes: const [1, 1],
          children: [left, right],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        history,
      ]);
    });
  }
}
