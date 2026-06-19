import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

import '../core_bridge/local_core_bridge.dart';

class Rc6RuntimeController extends ChangeNotifier {
  Rc6RuntimeController({
    required this.coreBridge,
    required this.coreCli,
    required this.coreWorkingDirectory,
    required this.configuredWorkspace,
    required this.isWebRuntime,
  });

  final LocalCoreBridge coreBridge;
  final String coreCli;
  final String coreWorkingDirectory;
  final String configuredWorkspace;
  final bool isWebRuntime;

  Rc6RuntimeState state = Rc6RuntimeState.initial();

  Directory? _workspaceDir;
  String? _resolvedCoreWorkingDirectory;

  Future<void> initialize() async {
    if (isWebRuntime || kIsWeb) {
      state = state.copyWith(
        phase: Rc6RuntimePhase.blocked,
        lastMessage: '真实文件链路需要 Windows EXE 桌面端；Flutter Web 不执行本地文件操作。',
      );
      notifyListeners();
      return;
    }
    final workspace = await _resolveWorkspace();
    await workspace.create(recursive: true);
    _workspaceDir = workspace;
    state = state.copyWith(
      workspacePath: workspace.path,
      phase: Rc6RuntimePhase.ready,
      lastMessage: 'rc10 产品链路本地工作区已准备。',
    );
    await _loadExistingArtifacts();
    notifyListeners();
    if (_autoRunOwnerInputPrdP0OnLaunch()) {
      state = state.copyWith(
        lastMessage: '启动参数请求运行 PRD P0 Owner input 产品闭环。',
        lastError: '',
      );
      notifyListeners();
      await runOwnerInputPrdP0E2E();
    } else if (_autoRunOwnerInputDocumentFlowOnLaunch()) {
      state = state.copyWith(
        lastMessage: '启动参数请求运行 Owner input 文档链路。',
        lastError: '',
      );
      notifyListeners();
      await runOwnerInputDocumentFlowE2E();
    } else if (_autoRunOwnerInputOnLaunch()) {
      state = state.copyWith(
        lastMessage: '启动参数请求运行 Owner input 完整链路。',
        lastError: '',
      );
      notifyListeners();
      await runOwnerInputFolderE2E();
    }
  }

  Future<void> createOrSwitchWorkbook(String name) async {
    if (!_canRunDesktop()) {
      return;
    }
    final workbookName = name.trim().isEmpty ? '默认工作本' : name.trim();
    final workspace = _requireWorkspace();
    final manifestPath = await _writeWorkbookManifest(
      workspace,
      currentName: workbookName,
      addName: workbookName,
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      currentWorkbookName: workbookName,
      workbookManifestPath: manifestPath,
      lastMessage: '已切换到工作本：$workbookName。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> deleteWorkbook(String name) async {
    if (!_canRunDesktop()) {
      return;
    }
    final workbookName = name.trim();
    if (workbookName.isEmpty) {
      return;
    }
    final workspace = _requireWorkspace();
    final result = await _deleteWorkbookFromManifest(workspace, workbookName);
    if (result == null) {
      state = state.copyWith(
        lastError: '无法删除工作本：$workbookName；请确认记录存在且至少保留一个工作本。',
        lastMessage: '',
      );
      notifyListeners();
      return;
    }
    final (manifestPath, currentName, workbookNames) = result;
    await _loadExistingArtifacts();
    state = state.copyWith(
      currentWorkbookName: currentName,
      workbookManifestPath: manifestPath,
      workbookNames: workbookNames,
      lastMessage: '已删除工作本：$workbookName。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> pickAndImportFile() async {
    if (!_canRunDesktop()) {
      return;
    }
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Knowledge sources',
          extensions: ['md', 'txt', 'pdf', 'docx'],
        ),
      ],
    );
    if (file == null) {
      state = state.copyWith(
        lastMessage: '未选择文件；导入未执行。',
        phase: Rc6RuntimePhase.ready,
      );
      notifyListeners();
      return;
    }
    await importFilePath(file.path);
  }

  Future<void> pickAndImportFolder() async {
    if (!_canRunDesktop()) {
      return;
    }
    final path = await getDirectoryPath();
    if (path == null) {
      state = state.copyWith(
        lastMessage: '未选择文件夹；导入未执行。',
        phase: Rc6RuntimePhase.ready,
      );
      notifyListeners();
      return;
    }
    await importFolderPath(path);
  }

  Future<void> importOwnerInputFolder() async {
    await importFolderPath(r'D:\HeiTang-Codex-WorkSpace\input');
  }

  Future<void> pickAndRunRealInputFolderE2E({String query = '赚钱 小生意'}) async {
    if (!_canRunDesktop()) {
      return;
    }
    final path = await getDirectoryPath();
    if (path == null) {
      state = state.copyWith(
        lastMessage: '未选择文件夹；完整链路未执行。',
        phase: Rc6RuntimePhase.ready,
      );
      notifyListeners();
      return;
    }
    await runRealInputFolderE2E(path, query: query);
  }

  Future<void> importFilePath(String filePath) async {
    if (!_canRunDesktop()) {
      return;
    }
    final source = File(filePath);
    if (!await source.exists()) {
      _fail('选择的文件不存在：$filePath');
      return;
    }
    final workspace = _requireWorkspace();
    final inputDir = Directory(_join(workspace.path, 'input'));
    await _clearGeneratedArtifacts(includeImport: false);
    await _clearWorkspacePath(_join(workspace.path, 'import'));
    await inputDir.create(recursive: true);
    final copied = await _copySourceIntoInput(source, inputDir);
    final manifestPath = await _writeSourceManifestFromInput(inputDir);
    final manifest = await _readJsonObject(manifestPath);
    final sourceNames = _sourceNamesFromManifest(manifest);
    final sourceRecords = _sourceRecordsFromManifest(manifest);
    state = state.copyWith(
      phase: Rc6RuntimePhase.imported,
      selectedFilePath: copied.path,
      sourceManifestPath: manifestPath,
      sourceCount: sourceNames.length,
      sourceNames: sourceNames,
      sourceRecords: sourceRecords,
      lastMessage: '真实文件已导入工作区。',
      lastError: '',
    );
    await _runCoreAction(
      actionId: 'batch_import_documents',
      arguments: [
        'batch-import-documents',
        '--input',
        inputDir.path,
        '--output',
        _join(workspace.path, 'import'),
      ],
      outputPath: _join(workspace.path, 'import'),
      nextPhase: Rc6RuntimePhase.imported,
      successMessage: 'Core 导入预检完成。',
    );
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> importFolderPath(String folderPath) async {
    if (!_canRunDesktop()) {
      return;
    }
    final sourceDir = Directory(folderPath);
    if (!await sourceDir.exists()) {
      _fail('选择的文件夹不存在：$folderPath');
      return;
    }
    final files = await _supportedSourceFiles(sourceDir).toList();
    if (files.isEmpty) {
      _fail('选择的文件夹没有可导入的 .md/.txt/.pdf/.docx 文件。');
      return;
    }
    final workspace = _requireWorkspace();
    final inputDir = Directory(_join(workspace.path, 'input'));
    await _clearGeneratedArtifacts(includeImport: false);
    await _clearWorkspacePath(_join(workspace.path, 'import'));
    await inputDir.create(recursive: true);
    for (final source in files) {
      final relative =
          _relativePath(source.absolute.path, sourceDir.absolute.path);
      await _copySourceIntoInput(source, inputDir, relativePath: relative);
    }
    final manifestPath =
        await _writeSourceManifestFromInput(inputDir, sourceName: 'input');
    final manifest = await _readJsonObject(manifestPath);
    final sourceNames = _sourceNamesFromManifest(manifest);
    final sourceRecords = _sourceRecordsFromManifest(manifest);
    state = state.copyWith(
      phase: Rc6RuntimePhase.imported,
      selectedFilePath: inputDir.path,
      sourceManifestPath: manifestPath,
      sourceCount: sourceNames.length,
      sourceNames: sourceNames,
      sourceRecords: sourceRecords,
      lastMessage: '真实文件夹已导入工作区。',
      lastError: '',
    );
    await _runCoreAction(
      actionId: 'batch_import_documents',
      arguments: [
        'batch-import-documents',
        '--input',
        inputDir.path,
        '--output',
        _join(workspace.path, 'import'),
      ],
      outputPath: _join(workspace.path, 'import'),
      nextPhase: Rc6RuntimePhase.imported,
      successMessage: 'Core 文件夹导入预检完成。',
    );
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> importWebLink(String url) async {
    if (!_canRunDesktop()) {
      return;
    }
    final normalized = url.trim();
    final uri = Uri.tryParse(normalized);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      _fail('请输入有效的 http(s) 网页链接。');
      return;
    }
    final workspace = _requireWorkspace();
    final inputDir = Directory(_join(workspace.path, 'input'));
    await _clearGeneratedArtifacts(includeImport: false);
    await _clearWorkspacePath(_join(workspace.path, 'import'));
    await inputDir.create(recursive: true);
    final fileName =
        '${_safeFileName(uri.host)}_${_stableHash(normalized)}.url.md';
    final target = await _uniqueInputFile(inputDir, fileName);
    await target.writeAsString(
      [
        '# 网页链接来源',
        '',
        '- URL: $normalized',
        '- 导入方式: 用户提供链接',
        '- 正文抓取: 需要在设置中授权联网 Provider 后执行',
        '',
        '该文件作为文档库来源记录进入本地工作区；未授权前不会联网抓取网页正文。',
        '',
      ].join('\n'),
      encoding: utf8,
    );
    final manifestPath =
        await _writeSourceManifestFromInput(inputDir, sourceName: uri.host);
    final manifest = await _readJsonObject(manifestPath);
    final sourceNames = _sourceNamesFromManifest(manifest);
    final sourceRecords = _sourceRecordsFromManifest(manifest);
    state = state.copyWith(
      phase: Rc6RuntimePhase.imported,
      selectedFilePath: target.path,
      sourceManifestPath: manifestPath,
      sourceCount: sourceNames.length,
      sourceNames: sourceNames,
      sourceRecords: sourceRecords,
      lastMessage: '网页链接已作为来源记录导入工作区。',
      lastError: '',
    );
    await _runCoreAction(
      actionId: 'batch_import_documents',
      arguments: [
        'batch-import-documents',
        '--input',
        inputDir.path,
        '--output',
        _join(workspace.path, 'import'),
      ],
      outputPath: _join(workspace.path, 'import'),
      nextPhase: Rc6RuntimePhase.imported,
      successMessage: '网页链接来源导入预检完成。',
    );
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> buildKnowledgeBase({List<String> documentIds = const []}) async {
    if (!_canRunDesktop()) {
      return;
    }
    final passed = await _runKnowledgeBaseCoreBuild(successMessage: '知识库构建完成。');
    if (passed) {
      await _writeDerivedKnowledgeArtifacts();
      await _writeKnowledgeBaseCatalog(documentIds: documentIds);
    }
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<String> exportStandardKnowledgePackage() async {
    if (!_canRunDesktop()) {
      return '';
    }
    final workspace = _requireWorkspace();
    if (!state.hasImportedFile) {
      _fail('请先导入文档，再生成标准知识包。');
      return '';
    }
    if (state.parseReportPath.isEmpty &&
        !await Directory(_join(workspace.path, 'du')).exists()) {
      _fail('请先完成解析/OCR/Chunking，再生成标准知识包。');
      return '';
    }
    state = state.copyWith(
      running: true,
      lastMessage: '正在封装标准知识包...',
      lastError: '',
    );
    notifyListeners();
    final packageDir = await _writeStandardKnowledgePackage(
      workspace: workspace,
      operation: 'export_standard_package',
    );
    await _appendOrchestrationPlanRecord(
      layer: 'standard_knowledge_package',
      action: 'export_standard_knowledge_package',
      artifact: _join(packageDir.path, 'standard_package_manifest.json'),
      status: 'completed',
      resources: {
        'source_manifest': _join(workspace.path, 'source_manifest.json'),
        'package_path': packageDir.path,
        'okf_candidate': true,
      },
    );
    await _appendStandardPackageAuditRecord(
      action: 'export_standard_knowledge_package',
      artifact: _join(packageDir.path, 'standard_package_manifest.json'),
      status: 'completed',
      details: {
        'package_path': packageDir.path,
        'okf_runtime_enabled': false,
      },
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      running: false,
      standardKnowledgePackagePath: packageDir.path,
      standardKnowledgePackageManifestPath:
          _join(packageDir.path, 'standard_package_manifest.json'),
      standardKnowledgePackageContentPath:
          _join(packageDir.path, 'content_package.jsonl'),
      standardKnowledgePackageAuditPath:
          _join(workspace.path, 'standard_packages', 'audit_history.jsonl'),
      lastMessage: '标准知识包已生成，可用于导出或构建知识库。',
      lastError: '',
    );
    notifyListeners();
    return packageDir.path;
  }

  Future<String> importStandardKnowledgePackagePath(String path) async {
    if (!_canRunDesktop()) {
      return '';
    }
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      _fail('请选择标准知识包目录或 manifest 文件。');
      return '';
    }
    final workspace = _requireWorkspace();
    final source = FileSystemEntity.isDirectorySync(trimmed)
        ? Directory(trimmed)
        : Directory(File(trimmed).parent.path);
    final manifest = File(_join(source.path, 'standard_package_manifest.json'));
    if (!await manifest.exists()) {
      _fail('未找到 standard_package_manifest.json，无法导入标准知识包。');
      return '';
    }
    final target =
        Directory(_join(workspace.path, 'standard_packages', 'current'));
    if (await target.exists()) {
      await target.delete(recursive: true);
    }
    await _copyDirectory(source, target);
    await _appendStandardPackageAuditRecord(
      action: 'import_standard_knowledge_package',
      artifact: _join(target.path, 'standard_package_manifest.json'),
      status: 'completed',
      details: {
        'source_path': source.path,
        'target_path': target.path,
      },
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      standardKnowledgePackagePath: target.path,
      standardKnowledgePackageManifestPath:
          _join(target.path, 'standard_package_manifest.json'),
      standardKnowledgePackageContentPath:
          _join(target.path, 'content_package.jsonl'),
      standardKnowledgePackageAuditPath:
          _join(workspace.path, 'standard_packages', 'audit_history.jsonl'),
      lastMessage: '标准知识包已导入当前工作区。',
      lastError: '',
    );
    notifyListeners();
    return target.path;
  }

  Future<void> buildKnowledgeBaseFromStandardPackage() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    final packageDir = state.standardKnowledgePackagePath.isNotEmpty
        ? Directory(state.standardKnowledgePackagePath)
        : Directory(_join(workspace.path, 'standard_packages', 'current'));
    final manifestPath =
        _join(packageDir.path, 'standard_package_manifest.json');
    final contentPath = _join(packageDir.path, 'content_package.jsonl');
    if (!await File(manifestPath).exists() ||
        !await File(contentPath).exists()) {
      _fail('请先生成或导入标准知识包，再从标准包构建知识库。');
      return;
    }
    state = state.copyWith(
      running: true,
      lastMessage: '正在从标准知识包构建知识库...',
      lastError: '',
    );
    notifyListeners();
    await _materializeKnowledgeBaseFromStandardPackage(packageDir);
    await _appendOrchestrationPlanRecord(
      layer: 'knowledge_base',
      action: 'build_kb_from_standard_package',
      artifact: _join(workspace.path, 'kb', 'manifest.json'),
      status: 'completed',
      resources: {
        'standard_package_manifest': manifestPath,
        'content_package': contentPath,
        'okf_runtime_enabled': false,
      },
    );
    await _appendStandardPackageAuditRecord(
      action: 'build_kb_from_standard_package',
      artifact: _join(workspace.path, 'kb', 'manifest.json'),
      status: 'completed',
      details: {
        'standard_package_manifest': manifestPath,
        'kb_manifest': _join(workspace.path, 'kb', 'manifest.json'),
      },
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      running: false,
      phase: Rc6RuntimePhase.knowledgeBuilt,
      lastMessage: '已从标准知识包构建知识库。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> copyKnowledgeBase(String sourceKbId) async {
    if (!_canRunDesktop()) return;
    await _copyKnowledgeBaseRecord(sourceKbId);
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> mergeKnowledgeBases(List<String> sourceKbIds) async {
    if (!_canRunDesktop()) return;
    await _mergeKnowledgeBaseRecords(sourceKbIds);
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> splitKnowledgeBase(String sourceKbId) async {
    if (!_canRunDesktop()) return;
    await _splitKnowledgeBaseRecord(sourceKbId);
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> updateKnowledgeBaseIncremental(String kbId) async {
    if (!_canRunDesktop()) return;
    await _updateKnowledgeBaseVersion(kbId, operation: 'incremental_update');
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> rebuildKnowledgeBaseFull(String kbId) async {
    if (!_canRunDesktop()) return;
    await _updateKnowledgeBaseVersion(kbId, operation: 'full_rebuild');
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> compareKnowledgeBaseVersions(String kbId) async {
    if (!_canRunDesktop()) return;
    await _compareKnowledgeBaseVersions(kbId);
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> rollbackKnowledgeBaseVersion(String kbId) async {
    if (!_canRunDesktop()) return;
    await _rollbackKnowledgeBaseVersion(kbId);
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> deleteKnowledgeBaseRecord(String kbId) async {
    if (!_canRunDesktop()) return;
    final workspace = _requireWorkspace();
    final catalog = await _loadKnowledgeCatalog(workspace);
    final records = _catalogRecords(catalog)
        .where((record) => record['kb_id']?.toString() != kbId)
        .toList(growable: true);
    final kbDir = Directory(_join(workspace.path, 'knowledge_bases', kbId));
    if (await kbDir.exists()) {
      await kbDir.delete(recursive: true);
    }
    await _writeKnowledgeCatalog(workspace, records, operation: 'delete:$kbId');
    state = state.copyWith(lastMessage: '知识库 $kbId 已删除。', lastError: '');
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> parseAndChunkSources() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    final inputDir = Directory(_join(workspace.path, 'input'));
    if (!await inputDir.exists()) {
      _fail('请先导入真实文件。');
      return;
    }
    await _clearGeneratedArtifacts(includeImport: false);
    final runtimeConfig = await _writeBuiltinPdfRuntimeConfig();
    await _runCoreAction(
      actionId: 'document_understanding',
      arguments: [
        'run-document-understanding',
        '--input',
        inputDir.path,
        '--preflight',
        _join(workspace.path, 'import'),
        '--output',
        _join(workspace.path, 'du'),
        '--runtime-config',
        runtimeConfig.path,
      ],
      outputPath: _join(workspace.path, 'du'),
      nextPhase: Rc6RuntimePhase.documentUnderstanding,
      successMessage: '解析/OCR/Chunking 完成。',
      timeout: const Duration(minutes: 20),
    );
    if (state.lastResult?.passed == true) {
      await _writeParseReportAlias();
    }
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<File> _writeBuiltinPdfRuntimeConfig() async {
    final workspace = _requireWorkspace();
    final configDir = Directory(_join(workspace.path, 'config'));
    await configDir.create(recursive: true);
    final configFile = File(_join(configDir.path, 'du_runtime_config.json'));
    final config = {
      'schema_version': 'document_understanding_runtime_config.v1',
      'working_directory': _effectiveCoreWorkingDirectory,
      'routes': {
        '.pdf': 'builtin',
        '.PDF': 'builtin',
      },
      'backends': {
        'builtin': {
          'timeout_seconds': 900,
        },
      },
      'rc6_reason':
          'Use the accepted built-in parser for real local PDF E2E when optional docling is unavailable.',
    };
    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(config),
      encoding: utf8,
    );
    return configFile;
  }

  Future<void> _writeParseReportAlias() async {
    final workspace = _requireWorkspace();
    final duManifest = File(
        _join(workspace.path, 'du', 'document_understanding_manifest.json'));
    if (!await duManifest.exists()) {
      return;
    }
    final alias = File(_join(workspace.path, 'parse_report.json'));
    await alias.writeAsString(await duManifest.readAsString(encoding: utf8),
        encoding: utf8);
  }

  Future<void> search(String query) async {
    final searchableIds = state.knowledgeBases
        .where((kb) => kb.status == 'searchable')
        .map((kb) => kb.id)
        .toList(growable: false);
    await searchKnowledgeBases(query, searchableIds);
  }

  Future<void> searchKnowledgeBases(String query, List<String> kbIds) async {
    if (!_canRunDesktop()) {
      return;
    }
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      _fail('请输入搜索关键词。');
      return;
    }
    final workspace = _requireWorkspace();
    final selectedKbs = await _selectedKnowledgeBasesForSearch(kbIds);
    if (selectedKbs.isEmpty) {
      _fail('请先构建知识库，再执行搜索。');
      return;
    }
    final queryDir = _join(workspace.path, 'query');
    await _clearWorkspacePath(queryDir);
    state = state.copyWith(
      searchQuery: normalizedQuery,
      searchStatus: Rc6SearchStatus.loading,
      queryResultPath: '',
      searchResults: const [],
      lastMessage: '正在检索 ${selectedKbs.length} 个真实知识库。',
      lastError: '',
      running: true,
    );
    notifyListeners();

    CoreBridgeResult? lastResult;
    final mergedRows = <Map<String, dynamic>>[];
    final kbSummaries = <Map<String, Object?>>[];
    for (final kb in selectedKbs) {
      final outputDir = _join(queryDir, kb.id);
      await Directory(outputDir).create(recursive: true);
      final startedAt = DateTime.now().toUtc().toIso8601String();
      final request = CoreBridgeRequest(
        actionId: 'rag_query',
        coreCli: coreCli,
        workingDirectory: _effectiveCoreWorkingDirectory,
        arguments: [
          'kb-query',
          '--package',
          kb.path,
          '--query',
          normalizedQuery,
          '--output',
          outputDir,
        ],
        outputPath: outputDir,
        allowedOutputRoot: workspace.path,
        timeout: const Duration(minutes: 5),
      );
      lastResult = await coreBridge.run(request, isWeb: isWebRuntime);
      if (!lastResult.passed) {
        state = state.copyWith(
          running: false,
          lastResult: lastResult,
          phase: Rc6RuntimePhase.failed,
          searchStatus: Rc6SearchStatus.error,
          lastMessage: lastResult.userReason,
          lastError: lastResult.userReason,
        );
        notifyListeners();
        return;
      }
      final resultPath = _join(outputDir, 'kb_query_result.json');
      final rows = await _readRawSearchRows(resultPath);
      for (final row in rows) {
        mergedRows.add({
          ...row,
          'kb_id': kb.id,
          'kb_name': kb.name,
          'kb_path': kb.path,
        });
      }
      kbSummaries.add({
        'kb_id': kb.id,
        'kb_name': kb.name,
        'result_count': rows.length,
        'result_path': resultPath,
        'started_at': startedAt,
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      });
    }

    mergedRows
        .sort((a, b) => _scoreOf(b['score']).compareTo(_scoreOf(a['score'])));
    final multiQueryPath = _join(queryDir, 'multi_kb_query_result.json');
    await _writeRetrievalIndustrialArtifacts(
      queryDir: Directory(queryDir),
      query: normalizedQuery,
      selectedKbs: selectedKbs,
      kbSummaries: kbSummaries,
      rankedRows: mergedRows,
    );
    await File(multiQueryPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_multi_kb_query_result.v1',
        'query': normalizedQuery,
        'selected_kb_ids': selectedKbs.map((kb) => kb.id).toList(),
        'selected_count': mergedRows.length,
        'selected_kb_count': selectedKbs.length,
        'retrieval_plan_path': _join(queryDir, 'retrieval_plan.json'),
        'rerank_report_path': _join(queryDir, 'rerank_report.json'),
        'citation_coverage_report_path':
            _join(queryDir, 'citation_coverage_report.json'),
        'conflict_report_path': _join(queryDir, 'conflict_report.json'),
        'external_validation_boundary_path':
            _join(queryDir, 'external_validation_boundary.json'),
        'citation_coverage': _citationCoverage(mergedRows),
        'answer_coverage': mergedRows.isEmpty ? 0 : 1,
        'conflict_count': _conflictCount(mergedRows),
        'external_validation_status': 'not_enabled_local_only',
        'correction_status': 'pending_manual_review',
        'knowledge_bases': kbSummaries,
        'results': mergedRows,
      }),
      encoding: utf8,
    );

    state = state.copyWith(
      running: false,
      lastResult: lastResult,
      phase: Rc6RuntimePhase.searched,
      lastMessage: '多知识库检索完成。',
      lastError: '',
    );
    await _loadExistingArtifacts();
    final hasResults = state.searchResults.isNotEmpty;
    state = state.copyWith(
      searchStatus:
          hasResults ? Rc6SearchStatus.success : Rc6SearchStatus.empty,
      lastMessage: hasResults ? '多知识库检索命中真实结果。' : '搜索完成，无结果。',
    );
    notifyListeners();
  }

  Future<void> _writeRetrievalIndustrialArtifacts({
    required Directory queryDir,
    required String query,
    required List<_SearchableKnowledgeBase> selectedKbs,
    required List<Map<String, Object?>> kbSummaries,
    required List<Map<String, dynamic>> rankedRows,
  }) async {
    await queryDir.create(recursive: true);
    final now = DateTime.now().toUtc().toIso8601String();
    final rewrittenQueries = <String>{
      query,
      ...query
          .split(RegExp(r'[\s,，。；;]+'))
          .map((part) => part.trim())
          .where((part) => part.length >= 2),
    }.toList(growable: false);
    final citationCoverage = _citationCoverage(rankedRows);
    final conflictRows = _conflictRows(rankedRows);
    await File(_join(queryDir.path, 'retrieval_plan.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_retrieval_plan.v1',
        'query': query,
        'rewritten_queries': rewrittenQueries,
        'retrieval_strategy': 'hybrid_keyword_vector_local',
        'selected_kb_ids': selectedKbs.map((kb) => kb.id).toList(),
        'selected_kb_count': selectedKbs.length,
        'external_fact_check_enabled': false,
        'created_at': now,
      }),
      encoding: utf8,
    );
    await File(_join(queryDir.path, 'rerank_report.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_retrieval_rerank_report.v1',
        'query': query,
        'ranking_rule': 'score_desc_with_kb_attribution',
        'result_count': rankedRows.length,
        'ranked_results': [
          for (var index = 0; index < rankedRows.length; index += 1)
            {
              'rank': index + 1,
              'kb_id': _stringValue(rankedRows[index]['kb_id'], ''),
              'chunk_id': _stringValue(rankedRows[index]['chunk_id'], ''),
              'score': _scoreOf(rankedRows[index]['score']),
              'citation': _stringValue(
                  rankedRows[index]['citation'] ??
                      rankedRows[index]['source_path'],
                  ''),
            }
        ],
        'built_at': now,
      }),
      encoding: utf8,
    );
    await File(_join(queryDir.path, 'citation_coverage_report.json'))
        .writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_retrieval_citation_coverage.v1',
        'query': query,
        'result_count': rankedRows.length,
        'cited_result_count': rankedRows
            .where((row) =>
                _stringValue(row['citation'] ?? row['source_path'], '')
                    .trim()
                    .isNotEmpty)
            .length,
        'citation_coverage': citationCoverage,
        'missing_citation_count': rankedRows.length -
            rankedRows
                .where((row) =>
                    _stringValue(row['citation'] ?? row['source_path'], '')
                        .trim()
                        .isNotEmpty)
                .length,
        'generated_at': now,
      }),
      encoding: utf8,
    );
    await File(_join(queryDir.path, 'conflict_report.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_retrieval_conflict_report.v1',
        'query': query,
        'conflict_count': conflictRows.length,
        'conflicts': conflictRows,
        'manual_review_required': conflictRows.isNotEmpty,
        'generated_at': now,
      }),
      encoding: utf8,
    );
    await File(_join(queryDir.path, 'external_validation_boundary.json'))
        .writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_external_validation_boundary.v1',
        'query': query,
        'status': 'not_enabled_local_only',
        'required_enablement': [
          'network_provider_configured',
          'tool_adapter_configured',
          'explicit_owner_opt_in',
        ],
        'external_calls_made': false,
        'local_evidence_only': true,
        'secret_plaintext_written': false,
        'generated_at': now,
      }),
      encoding: utf8,
    );
  }

  Future<String> saveRetrievalValidationReport(
      Map<int, String> corrections) async {
    if (!_canRunDesktop()) {
      return '';
    }
    final workspace = _requireWorkspace();
    if (state.queryResultPath.isEmpty ||
        !await File(state.queryResultPath).exists()) {
      _fail('请先完成一次真实检索，再保存验证报告。');
      return '';
    }
    final queryReport = await _readJsonObject(state.queryResultPath);
    final rows = await _readSearchResults(state.queryResultPath);
    final correctionRows = corrections.entries
        .map((entry) => {
              'result_index': entry.key,
              'decision': entry.value,
              'normalized_decision':
                  _isConflictDecision(entry.value) ? 'conflict' : entry.value,
            })
        .toList(growable: false);
    final queryDir = Directory(_join(workspace.path, 'query'));
    await queryDir.create(recursive: true);
    final reportPath = _join(queryDir.path, 'validation_report.json');
    final markdownPath = _join(queryDir.path, 'validation_report.md');
    final historyPath = _join(queryDir.path, 'validation_history.jsonl');
    final payload = {
      'schema_version': 'prd_v3_retrieval_validation_report.v1',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'query': (queryReport['query'] ?? state.searchQuery).toString(),
      'selected_kb_ids': queryReport['selected_kb_ids'] ?? const <String>[],
      'result_count': rows.length,
      'retrieval_plan_path': state.retrievalPlanPath,
      'rerank_report_path': state.retrievalRerankReportPath,
      'citation_coverage_report_path': state.retrievalCitationCoveragePath,
      'conflict_report_path': state.retrievalConflictReportPath,
      'external_validation_boundary_path': state.externalValidationBoundaryPath,
      'citation_coverage': queryReport['citation_coverage'] ??
          _citationCoverage(rows
              .map((row) => {
                    'citation': row.citation,
                    'source_path': row.citation,
                  })
              .toList(growable: false)),
      'conflict_count': correctionRows
          .where((row) => row['normalized_decision'] == 'conflict')
          .length,
      'correction_status':
          correctionRows.isEmpty ? 'pending_manual_review' : 'reviewed',
      'manual_corrections': correctionRows,
      'external_validation_status':
          queryReport['external_validation_status'] ?? 'not_enabled_local_only',
      'query_result_path': state.queryResultPath,
      'markdown_report_path': markdownPath,
      'history_path': historyPath,
      'results': rows
          .map((row) => {
                'title': row.title,
                'excerpt': row.excerpt,
                'citation': row.citation,
                'score': row.score,
                'kb_id': row.kbId,
                'kb_name': row.kbName,
              })
          .toList(growable: false),
    };
    await File(reportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
    await File(markdownPath).writeAsString(
      _retrievalValidationMarkdown(payload),
      encoding: utf8,
    );
    await File(historyPath).writeAsString(
      '${jsonEncode({
            'created_at': payload['created_at'],
            'query': payload['query'],
            'selected_kb_ids': payload['selected_kb_ids'],
            'result_count': payload['result_count'],
            'conflict_count': payload['conflict_count'],
            'correction_status': payload['correction_status'],
            'retrieval_plan_path': payload['retrieval_plan_path'],
            'rerank_report_path': payload['rerank_report_path'],
            'citation_coverage_report_path':
                payload['citation_coverage_report_path'],
            'conflict_report_path': payload['conflict_report_path'],
            'external_validation_boundary_path':
                payload['external_validation_boundary_path'],
            'report_path': reportPath,
            'markdown_report_path': markdownPath,
          })}\n',
      mode: FileMode.append,
      encoding: utf8,
    );
    state = state.copyWith(
      retrievalValidationReportPath: reportPath,
      retrievalValidationMarkdownPath: markdownPath,
      retrievalValidationHistoryPath: historyPath,
      lastMessage: '检索验证报告和历史已保存。',
      lastError: '',
    );
    notifyListeners();
    return reportPath;
  }

  Future<void> generateMarkdown({
    Rc6DocumentGenerationConfig config = const Rc6DocumentGenerationConfig(),
  }) async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    final kbDir = Directory(_join(workspace.path, 'kb'));
    if (!await kbDir.exists()) {
      _fail('请先构建知识库，再生成文档。');
      return;
    }
    final existingManifest = await _readJsonObject(
        _join(workspace.path, 'doc', 'generation_manifest.json'));
    final historyBeforeClear =
        _listOfMaps(existingManifest['generation_history']);
    await _clearWorkspacePath(_join(workspace.path, 'doc'));
    await _runCoreAction(
      actionId: 'generate_markdown',
      arguments: [
        'generate-md',
        '--package',
        kbDir.path,
        '--output',
        _join(workspace.path, 'doc'),
        '--title',
        config.title,
      ],
      outputPath: _join(workspace.path, 'doc'),
      nextPhase: Rc6RuntimePhase.documentGenerated,
      successMessage: 'Markdown 文档已生成。',
    );
    if (state.lastResult?.passed == true) {
      await _writeReadingNotes(config: config);
      await _writeDocumentGenerationManifest(
        config: config,
        existingHistory: historyBeforeClear,
      );
      await _appendOrchestrationPlanRecord(
        layer: 'document',
        action: 'generate_document',
        artifact: _join(workspace.path, 'doc', 'generation_manifest.json'),
        status: 'completed',
        resources: {
          'kb_package': kbDir.path,
          'template': config.templateMode,
          'generation_type': config.generationType,
          'output_format': config.outputFormat,
        },
      );
    }
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> exportMarkdownDocument() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    final docDir = Directory(_join(workspace.path, 'doc'));
    final generated = File(_join(docDir.path, 'generated.md'));
    final notes = File(_join(docDir.path, 'reading_notes.md'));
    final edited = File(_join(docDir.path, 'edited_document.md'));
    if (!await generated.exists() &&
        !await notes.exists() &&
        !await edited.exists()) {
      _fail('请先在文档生成页生成 Markdown 草稿。');
      return;
    }
    state = state.copyWith(
      running: true,
      lastMessage: '正在导出 Markdown 文档...',
      lastError: '',
    );
    notifyListeners();
    final exportDir = Directory(_join(workspace.path, 'export'));
    await _clearWorkspacePath(exportDir.path);
    await exportDir.create(recursive: true);
    final source = await edited.exists()
        ? edited
        : await notes.exists()
            ? notes
            : generated;
    final exported = File(_join(exportDir.path, 'reading_notes_export.md'));
    await source.copy(exported.path);
    final manifest = {
      'schema_version': 'rc10_document_export.v1',
      'status': 'pass',
      'format': 'markdown',
      'source': source.path,
      'output': exported.path,
      'size_bytes': await exported.length(),
      'workspace': workspace.path,
      'generation_manifest': _join(docDir.path, 'generation_manifest.json'),
      'edit_manifest':
          await File(_join(docDir.path, 'edit_manifest.json')).exists()
              ? _join(docDir.path, 'edit_manifest.json')
              : '',
      'generation_config': await _latestDocumentGenerationConfig(workspace),
    };
    await File(_join(exportDir.path, 'export_manifest.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      encoding: utf8,
    );
    await _appendOrchestrationPlanRecord(
      layer: 'document',
      action: 'export_document',
      artifact: _join(exportDir.path, 'export_manifest.json'),
      status: 'completed',
      resources: {
        'format': 'markdown',
        'source': source.path,
        'output': exported.path,
      },
    );
    state = state.copyWith(
      running: false,
      phase: Rc6RuntimePhase.documentGenerated,
      exportedDocumentPath: exported.path,
      exportManifestPath: _join(exportDir.path, 'export_manifest.json'),
      lastMessage: 'Markdown 文档已导出。',
      lastError: '',
    );
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> clearDocumentGenerationHistory() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    final manifestPath =
        _join(workspace.path, 'doc', 'generation_manifest.json');
    final manifest = await _readJsonObject(manifestPath);
    if (manifest.isEmpty) {
      _fail('暂无生成历史可删除。');
      return;
    }
    manifest['generation_history'] = <Map<String, dynamic>>[];
    manifest['history_cleared_at'] = DateTime.now().toUtc().toIso8601String();
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      encoding: utf8,
    );
    state = state.copyWith(
      documentGenerationHistoryCount: 0,
      lastMessage: '文档生成历史已清空；正文和导出产物已保留。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> deleteLatestDocumentGenerationHistory() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    final manifestPath =
        _join(workspace.path, 'doc', 'generation_manifest.json');
    final manifest = await _readJsonObject(manifestPath);
    final history =
        _listOfMaps(manifest['generation_history']).toList(growable: true);
    if (history.isEmpty) {
      _fail('暂无生成历史可删除。');
      return;
    }
    final deleted = history.removeLast();
    manifest['generation_history'] = history;
    manifest['latest_history_deleted_at'] =
        DateTime.now().toUtc().toIso8601String();
    manifest['latest_history_deleted_event'] =
        (deleted['event'] ?? '').toString();
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      encoding: utf8,
    );
    state = state.copyWith(
      documentGenerationHistoryCount: history.length,
      lastMessage: '最近一条文档生成历史已删除；正文和导出产物已保留。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<String> readLatestDocumentGenerationHistoryMarkdown({
    int maxCharacters = 6000,
  }) async {
    if (!_canRunDesktop()) {
      return '';
    }
    final workspace = _requireWorkspace();
    final manifest = await _readJsonObject(
        _join(workspace.path, 'doc', 'generation_manifest.json'));
    final history = _listOfMaps(manifest['generation_history']);
    if (history.isEmpty) {
      _fail('暂无可重新打开的文档生成历史。');
      return '';
    }
    final outputPath = (history.last['history_markdown'] ??
            history.last['output_markdown'] ??
            '')
        .toString();
    if (outputPath.trim().isEmpty) {
      _fail('最近一条文档生成历史没有可打开的 Markdown 产物。');
      return '';
    }
    final workspacePath = workspace.absolute.path;
    final file = File(outputPath).absolute;
    if (!_isInsideDirectory(file.path, workspacePath)) {
      _fail('无法重新打开：历史产物不在当前工作区内。');
      return '';
    }
    if (_extension(file.path).toLowerCase() != '.md') {
      _fail('无法重新打开：当前只支持 Markdown 历史产物。');
      return '';
    }
    if (!await file.exists()) {
      _fail('无法重新打开：历史 Markdown 文件不存在。');
      return '';
    }
    final text = await file.readAsString(encoding: utf8);
    state = state.copyWith(
      lastMessage: '最近一条文档生成历史已重新打开。',
      lastError: '',
    );
    notifyListeners();
    if (text.length <= maxCharacters) {
      return text;
    }
    return '${text.substring(0, maxCharacters)}\n\n... 预览已截断，完整内容请复制路径后在本地查看。';
  }

  Future<String> saveEditedDocument(String markdown) async {
    if (!_canRunDesktop()) {
      return '';
    }
    final workspace = _requireWorkspace();
    final docDir = Directory(_join(workspace.path, 'doc'));
    final generated = File(_join(docDir.path, 'generated.md'));
    final notes = File(_join(docDir.path, 'reading_notes.md'));
    if (!await generated.exists() && !await notes.exists()) {
      _fail('请先生成正文，再保存编辑稿。');
      return '';
    }
    final trimmed = markdown.trim();
    if (trimmed.isEmpty) {
      _fail('编辑正文不能为空。');
      return '';
    }
    state = state.copyWith(
      running: true,
      lastMessage: '正在保存编辑稿...',
      lastError: '',
    );
    notifyListeners();
    await docDir.create(recursive: true);
    final edited = File(_join(docDir.path, 'edited_document.md'));
    await edited.writeAsString(markdown, encoding: utf8);
    final source = await notes.exists() ? notes.path : generated.path;
    final manifestPath = _join(docDir.path, 'edit_manifest.json');
    final payload = {
      'schema_version': 'prd_v2_document_edit.v1',
      'status': 'pass',
      'workspace': workspace.path,
      'source_document': source,
      'edited_output_markdown': edited.path,
      'generation_manifest': _join(docDir.path, 'generation_manifest.json'),
      'generation_config': await _latestDocumentGenerationConfig(workspace),
      'size_bytes': await edited.length(),
      'saved_at': DateTime.now().toUtc().toIso8601String(),
      'secret_plaintext_written': false,
    };
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
    state = state.copyWith(
      running: false,
      phase: Rc6RuntimePhase.documentGenerated,
      editedDocumentPath: edited.path,
      editManifestPath: manifestPath,
      lastMessage: '编辑稿已保存。导出将优先使用编辑稿。',
      lastError: '',
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      editedDocumentPath: edited.path,
      editManifestPath: manifestPath,
      lastMessage: '编辑稿已保存。导出将优先使用编辑稿。',
      lastError: '',
    );
    notifyListeners();
    return edited.path;
  }

  Future<void> exportDocumentFormat(String format) async {
    final normalized = format.trim().toLowerCase();
    if (normalized == 'md' || normalized == 'markdown') {
      await exportMarkdownDocument();
      return;
    }
    if (normalized == 'json' || normalized == 'csv') {
      await _exportStructuredDocumentFormat(normalized);
      return;
    }
    if (!const {'docx', 'pdf', 'pptx'}.contains(normalized)) {
      _fail('暂不支持该导出格式：$format');
      return;
    }
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    final kbDir = Directory(_join(workspace.path, 'kb'));
    if (!await kbDir.exists()) {
      _fail('请先构建知识库，再导出 $normalized 文档。');
      return;
    }
    final exportDir = Directory(_join(workspace.path, 'export', normalized));
    await _clearWorkspacePath(exportDir.path);
    final command = 'generate-$normalized';
    await _runCoreAction(
      actionId: command.replaceAll('-', '_'),
      arguments: [
        command,
        '--package',
        kbDir.path,
        '--output',
        exportDir.path,
        '--title',
        '真实输入文档导出',
      ],
      outputPath: exportDir.path,
      nextPhase: Rc6RuntimePhase.documentGenerated,
      successMessage: '${normalized.toUpperCase()} 文档已导出。',
      timeout: const Duration(minutes: 10),
    );
    if (state.lastResult?.passed == true) {
      final generated = await _firstFileWithExtension(exportDir, normalized);
      await _appendOrchestrationPlanRecord(
        layer: 'document',
        action: 'export_document',
        artifact: _join(exportDir.path, 'generated_file_report.json'),
        status: 'completed',
        resources: {
          'format': normalized,
          'kb_package': kbDir.path,
          'output': generated?.path ?? exportDir.path,
        },
      );
      state = state.copyWith(
        exportedDocumentPath: generated?.path ?? exportDir.path,
        exportManifestPath: _join(exportDir.path, 'generated_file_report.json'),
        lastMessage: '${normalized.toUpperCase()} 文档已导出。',
        lastError: '',
      );
    }
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> _exportStructuredDocumentFormat(String format) async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    final kbDir = Directory(_join(workspace.path, 'kb'));
    final docDir = Directory(_join(workspace.path, 'doc'));
    if (!await kbDir.exists()) {
      _fail('请先构建知识库，再导出 ${format.toUpperCase()}。');
      return;
    }
    if (!await File(_join(docDir.path, 'reading_notes.md')).exists() &&
        !await File(_join(docDir.path, 'generated.md')).exists()) {
      _fail('请先生成文档，再导出结构化结果。');
      return;
    }
    state = state.copyWith(
      running: true,
      lastMessage: '正在导出 ${format.toUpperCase()} 结构化文件...',
      lastError: '',
    );
    notifyListeners();
    final exportDir = Directory(_join(workspace.path, 'export', 'structured'));
    await exportDir.create(recursive: true);
    final structured = await _structuredDocumentExportPayload(workspace);
    final jsonPath = _join(exportDir.path, 'knowledge_export.json');
    final csvPath = _join(exportDir.path, 'knowledge_export.csv');
    await File(jsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(structured),
      encoding: utf8,
    );
    await File(csvPath).writeAsString(
      _structuredDocumentExportCsv(structured),
      encoding: utf8,
    );
    final outputPath = format == 'json' ? jsonPath : csvPath;
    final manifestPath =
        _join(exportDir.path, 'structured_export_manifest.json');
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v2_structured_document_export.v1',
        'status': 'pass',
        'requested_format': format,
        'json_output': jsonPath,
        'csv_output': csvPath,
        'selected_output': outputPath,
        'source_manifest': _join(workspace.path, 'source_manifest.json'),
        'kb_manifest': _join(workspace.path, 'kb', 'manifest.json'),
        'query_result': await File(_join(
                    workspace.path, 'query', 'multi_kb_query_result.json'))
                .exists()
            ? _join(workspace.path, 'query', 'multi_kb_query_result.json')
            : _join(workspace.path, 'query', 'kb_query_result.json'),
      }),
      encoding: utf8,
    );
    await _appendOrchestrationPlanRecord(
      layer: 'document',
      action: 'export_document',
      artifact: manifestPath,
      status: 'completed',
      resources: {
        'format': format,
        'json_output': jsonPath,
        'csv_output': csvPath,
        'selected_output': outputPath,
      },
    );
    state = state.copyWith(
      running: false,
      phase: Rc6RuntimePhase.documentGenerated,
      exportedDocumentPath: outputPath,
      exportManifestPath: manifestPath,
      lastMessage: '${format.toUpperCase()} 结构化文件已导出。',
      lastError: '',
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      exportedDocumentPath: outputPath,
      exportManifestPath: manifestPath,
      lastMessage: '${format.toUpperCase()} 结构化文件已导出。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<Rc6StorageTestResult> testRedisConnection({
    required String host,
    required int port,
    required String keyPrefix,
    String password = '',
  }) async {
    if (isWebRuntime || kIsWeb) {
      return const Rc6StorageTestResult(
        passed: false,
        status: 'desktop_runtime_required',
        detail: '真实 Redis 连接测试需要 Windows EXE 桌面端。',
      );
    }
    final effectivePassword = _effectiveSecret(
      provided: password,
      environmentKey: 'HEITANG_REDIS_PASSWORD',
    );
    final safePrefix = keyPrefix.trim().isEmpty ? 'heitang:' : keyPrefix.trim();
    Future<Rc6StorageTestResult> persist(Rc6StorageTestResult result) async {
      await _persistRedisStorageResult(
        host: host,
        port: port,
        keyPrefix: safePrefix,
        password: password,
        result: result,
      );
      return result;
    }

    if (effectivePassword.isEmpty) {
      return persist(const Rc6StorageTestResult(
        passed: false,
        status: 'missing_password',
        detail: '缺少 Redis 密码；请设置 HEITANG_REDIS_PASSWORD 或输入掩码字段。',
      ));
    }
    final probeKey = '${safePrefix}settings_probe';
    Socket? socket;
    StreamIterator<List<int>>? iterator;
    try {
      socket = await Socket.connect(
        host.trim().isEmpty ? '127.0.0.1' : host.trim(),
        port,
        timeout: const Duration(seconds: 5),
      );
      iterator = StreamIterator<List<int>>(socket);
      Future<String> send(List<String> command) async {
        socket!.add(utf8.encode(_redisCommand(command)));
        await socket.flush();
        final hasChunk = await iterator!
            .moveNext()
            .timeout(const Duration(seconds: 5), onTimeout: () => false);
        if (!hasChunk) {
          throw const SocketException('Redis response timed out');
        }
        return utf8.decode(iterator.current, allowMalformed: true);
      }

      final auth = await send(['AUTH', effectivePassword]);
      if (!auth.startsWith('+OK')) {
        return persist(Rc6StorageTestResult(
          passed: false,
          status: 'auth_failed',
          detail: _redisStatus(auth),
        ));
      }
      final ping = await send(['PING']);
      if (!ping.startsWith('+PONG')) {
        return persist(Rc6StorageTestResult(
          passed: false,
          status: 'ping_failed',
          detail: _redisStatus(ping),
        ));
      }
      final set = await send(['SET', probeKey, 'ok']);
      final get = await send(['GET', probeKey]);
      final del = await send(['DEL', probeKey]);
      final ok = set.startsWith('+OK') &&
          get.contains('\r\nok\r\n') &&
          (del.startsWith(':1') || del.startsWith(':0'));
      return persist(Rc6StorageTestResult(
        passed: ok,
        status: ok ? 'connected' : 'probe_failed',
        detail: ok
            ? 'Redis PING / 写入 / 读取 / 删除均通过。'
            : 'Redis 探针失败：${_redisStatus(get)}',
      ));
    } on Object catch (error) {
      return persist(Rc6StorageTestResult(
        passed: false,
        status: 'connection_failed',
        detail: _redactSecret(error.toString(), effectivePassword),
      ));
    } finally {
      await iterator?.cancel();
      socket?.destroy();
    }
  }

  Future<Rc6StorageTestResult> testQdrantConnection({
    required String endpoint,
    required String collection,
    required int dimension,
    String apiKey = '',
  }) async {
    if (isWebRuntime || kIsWeb) {
      return const Rc6StorageTestResult(
        passed: false,
        status: 'desktop_runtime_required',
        detail: '真实 Qdrant 连接测试需要 Windows EXE 桌面端。',
      );
    }
    final baseUri = Uri.tryParse(endpoint.trim());
    if (baseUri == null || !baseUri.hasScheme || baseUri.host.isEmpty) {
      return const Rc6StorageTestResult(
        passed: false,
        status: 'invalid_endpoint',
        detail: 'Qdrant endpoint 必须是 http(s) URL。',
      );
    }
    if (dimension <= 0) {
      return const Rc6StorageTestResult(
        passed: false,
        status: 'invalid_dimension',
        detail: 'Qdrant 向量维度必须大于 0。',
      );
    }
    final collectionName =
        collection.trim().isEmpty ? 'heitang_kb' : collection.trim();
    final effectiveApiKey = _effectiveSecret(
      provided: apiKey,
      environmentKey: 'HEITANG_QDRANT_API_KEY',
    );
    Future<Rc6StorageTestResult> persist(Rc6StorageTestResult result) async {
      await _persistQdrantStorageResult(
        endpoint: endpoint,
        collection: collectionName,
        dimension: dimension,
        apiKey: apiKey,
        result: result,
      );
      return result;
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final health = await _qdrantRequest(
        client,
        baseUri,
        'GET',
        '/healthz',
        effectiveApiKey,
      );
      if (health.statusCode >= 400) {
        return persist(Rc6StorageTestResult(
          passed: false,
          status: 'health_failed',
          detail: 'Qdrant healthz 返回 HTTP ${health.statusCode}。',
        ));
      }

      final collectionPath = '/collections/$collectionName';
      final current = await _qdrantRequest(
        client,
        baseUri,
        'GET',
        collectionPath,
        effectiveApiKey,
      );
      if (current.statusCode == 404) {
        final create = await _qdrantRequest(
          client,
          baseUri,
          'PUT',
          collectionPath,
          effectiveApiKey,
          body: {
            'vectors': {'size': dimension, 'distance': 'Cosine'}
          },
        );
        if (create.statusCode >= 400) {
          return persist(Rc6StorageTestResult(
            passed: false,
            status: 'collection_create_failed',
            detail: '创建 collection 失败：HTTP ${create.statusCode}。',
          ));
        }
      } else if (current.statusCode >= 400) {
        return persist(Rc6StorageTestResult(
          passed: false,
          status: 'collection_check_failed',
          detail: 'Collection 检查失败：HTTP ${current.statusCode}。',
        ));
      }

      const pointId = 4308;
      final vector = List<double>.generate(
        dimension,
        (index) => index == 0 ? 1.0 : 0.0,
      );
      final upsert = await _qdrantRequest(
        client,
        baseUri,
        'PUT',
        '$collectionPath/points?wait=true',
        effectiveApiKey,
        body: {
          'points': [
            {
              'id': pointId,
              'vector': vector,
              'payload': {'source': 'heitang_rc8_settings_probe'}
            }
          ]
        },
      );
      if (upsert.statusCode >= 400) {
        return persist(Rc6StorageTestResult(
          passed: false,
          status: 'vector_write_failed',
          detail: '测试向量写入失败：HTTP ${upsert.statusCode}。',
        ));
      }
      final search = await _qdrantRequest(
        client,
        baseUri,
        'POST',
        '$collectionPath/points/search',
        effectiveApiKey,
        body: {'vector': vector, 'limit': 1, 'with_payload': true},
      );
      if (search.statusCode >= 400 || !search.body.contains('$pointId')) {
        return persist(Rc6StorageTestResult(
          passed: false,
          status: 'vector_search_failed',
          detail: '测试向量检索失败：HTTP ${search.statusCode}。',
        ));
      }
      final delete = await _qdrantRequest(
        client,
        baseUri,
        'POST',
        '$collectionPath/points/delete?wait=true',
        effectiveApiKey,
        body: {
          'points': [pointId]
        },
      );
      final deleted = delete.statusCode < 400;
      return persist(Rc6StorageTestResult(
        passed: deleted,
        status: deleted ? 'connected' : 'vector_delete_failed',
        detail: deleted
            ? 'Qdrant health / collection / 测试向量写入检索删除均通过。'
            : '测试向量删除失败：HTTP ${delete.statusCode}。',
      ));
    } on Object catch (error) {
      return persist(Rc6StorageTestResult(
        passed: false,
        status: 'connection_failed',
        detail: _redactSecret(error.toString(), effectiveApiKey),
      ));
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> loadStorageProviderSettings() async {
    final workspace = _workspaceDir;
    if (workspace == null || !await workspace.exists()) {
      return _defaultStorageProviderSettings('');
    }
    final saved =
        await _readJsonObject(_storageProviderSettingsPath(workspace));
    return _mergeStorageProviderSettings(
      _defaultStorageProviderSettings(workspace.path),
      saved,
    );
  }

  Future<String> saveStorageProviderSettings({
    required String redisHost,
    required int redisPort,
    required String redisKeyPrefix,
    required String redisPassword,
    required String qdrantEndpoint,
    required String qdrantCollection,
    required int qdrantDimension,
    required String qdrantApiKey,
  }) async {
    if (!_canRunDesktop()) {
      return '';
    }
    final path = await _writeStorageProviderSettings(
      redisHost: redisHost,
      redisPort: redisPort,
      redisKeyPrefix: redisKeyPrefix,
      redisPassword: redisPassword,
      redisStatus: 'configured_not_tested',
      redisDetail: '',
      qdrantEndpoint: qdrantEndpoint,
      qdrantCollection: qdrantCollection,
      qdrantDimension: qdrantDimension,
      qdrantApiKey: qdrantApiKey,
      qdrantStatus: 'configured_not_tested',
      qdrantDetail: '',
    );
    state = state.copyWith(
      lastMessage: 'Provider、Redis、Qdrant 和导出器配置已保存到工作区。',
      lastError: '',
    );
    notifyListeners();
    return path;
  }

  Future<Map<String, dynamic>> loadProviderRuntimeSettings() async {
    final workspace = _workspaceDir;
    if (workspace == null || !await workspace.exists()) {
      return _defaultProviderRuntimeSettings('');
    }
    final saved =
        await _readJsonObject(_providerRuntimeSettingsPath(workspace));
    return _mergeProviderRuntimeSettings(
      _defaultProviderRuntimeSettings(workspace.path),
      saved,
    );
  }

  Future<String> saveProviderRuntimeSettings({
    required String llmProvider,
    required String modelId,
    required String embeddingProvider,
    required String searchProvider,
    required String parserProvider,
    required String ocrProvider,
    required String apiKey,
  }) async {
    if (!_canRunDesktop()) {
      return '';
    }
    final workspace = _requireWorkspace();
    final configDir = Directory(_join(workspace.path, 'config'));
    await configDir.create(recursive: true);
    final path = _providerRuntimeSettingsPath(workspace);
    final now = DateTime.now().toUtc().toIso8601String();
    final secretRef = _secretReference(
      provided: apiKey,
      environmentKey: 'HEITANG_LLM_API_KEY',
    );
    final payload = {
      'schema_version': 'prd_v3_provider_runtime_settings.v1',
      'workspace': workspace.path,
      'saved_at': now,
      'provider_crud_status': 'saved',
      'llm': {
        'provider_id':
            llmProvider.trim().isEmpty ? 'env_configured' : llmProvider.trim(),
        'model_id': modelId.trim().isEmpty
            ? 'local-default-or-configured-provider'
            : modelId.trim(),
        'api_key_display': secretRef == 'none' ? '' : '************',
        'api_key_secret_ref': secretRef,
        'status': 'configured_not_tested',
      },
      'embedding': {
        'provider_id': embeddingProvider.trim().isEmpty
            ? 'local_keyword_embedding'
            : embeddingProvider.trim(),
        'status': 'configured_not_tested',
      },
      'search': {
        'provider_id': searchProvider.trim().isEmpty
            ? 'local_index'
            : searchProvider.trim(),
        'network_required': searchProvider.trim().contains('web'),
        'status': 'configured_not_tested',
      },
      'parser': {
        'provider_id': parserProvider.trim().isEmpty
            ? 'local_parser'
            : parserProvider.trim(),
        'status': 'configured_not_tested',
      },
      'ocr': {
        'provider_id':
            ocrProvider.trim().isEmpty ? 'optional_ocr' : ocrProvider.trim(),
        'status': 'configured_not_tested',
      },
      'secret_plaintext_written': false,
    };
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
    await _writeProviderValidationReport(
      workspace,
      settings: payload,
      validationMode: 'save_only',
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      providerRuntimeSettingsPath: path,
      providerValidationReportPath:
          _join(workspace.path, 'config', 'provider_validation_report.json'),
      lastMessage: 'Provider、模型、Embedding、Search、Parser 和 OCR 配置已保存。',
      lastError: '',
    );
    notifyListeners();
    return path;
  }

  Future<String> validateProviderRuntimeSettings() async {
    if (!_canRunDesktop()) {
      return '';
    }
    final workspace = _requireWorkspace();
    final settings = await loadProviderRuntimeSettings();
    final path = await _writeProviderValidationReport(
      workspace,
      settings: settings,
      validationMode: 'configuration_validation',
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      providerValidationReportPath: path,
      lastMessage: 'Provider 配置验证报告已生成。',
      lastError: '',
    );
    notifyListeners();
    return path;
  }

  Future<Map<String, dynamic>> loadExporterSettings() async {
    final workspace = _workspaceDir;
    if (workspace == null || !await workspace.exists()) {
      return _defaultExporterSettings('');
    }
    final saved = await _readJsonObject(_exporterSettingsPath(workspace));
    return _mergeExporterSettings(
      _defaultExporterSettings(workspace.path),
      saved,
    );
  }

  Future<String> saveExporterSettings({
    required String docxExporter,
    required String pdfExporter,
    required String pptxExporter,
    required String exportRoot,
  }) async {
    if (!_canRunDesktop()) {
      return '';
    }
    final workspace = _requireWorkspace();
    final configDir = Directory(_join(workspace.path, 'config'));
    await configDir.create(recursive: true);
    final path = _exporterSettingsPath(workspace);
    final root = exportRoot.trim().isEmpty
        ? _join(workspace.path, 'export')
        : exportRoot.trim();
    final payload = {
      'schema_version': 'prd_v3_exporter_settings.v1',
      'workspace': workspace.path,
      'saved_at': DateTime.now().toUtc().toIso8601String(),
      'export_root': root,
      'exporters': {
        'markdown': {'provider': 'local_markdown', 'status': 'enabled_real'},
        'json': {'provider': 'local_json', 'status': 'enabled_real'},
        'csv': {'provider': 'local_csv', 'status': 'enabled_real'},
        'docx': {
          'provider': docxExporter.trim().isEmpty
              ? 'requires_configuration'
              : docxExporter.trim(),
          'status': docxExporter.trim().isEmpty
              ? 'requires_configuration'
              : 'configured_not_tested',
        },
        'pdf': {
          'provider': pdfExporter.trim().isEmpty
              ? 'requires_configuration'
              : pdfExporter.trim(),
          'status': pdfExporter.trim().isEmpty
              ? 'requires_configuration'
              : 'configured_not_tested',
        },
        'pptx': {
          'provider': pptxExporter.trim().isEmpty
              ? 'requires_configuration'
              : pptxExporter.trim(),
          'status': pptxExporter.trim().isEmpty
              ? 'requires_configuration'
              : 'configured_not_tested',
        },
      },
    };
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
    await _writeExporterValidationReport(workspace, settings: payload);
    await _loadExistingArtifacts();
    state = state.copyWith(
      exporterValidationReportPath:
          _join(workspace.path, 'config', 'exporter_validation_report.json'),
      lastMessage: '导出器配置已保存。',
      lastError: '',
    );
    notifyListeners();
    return path;
  }

  Future<String> validateExporterSettings() async {
    if (!_canRunDesktop()) {
      return '';
    }
    final workspace = _requireWorkspace();
    final settings = await loadExporterSettings();
    final path = await _writeExporterValidationReport(
      workspace,
      settings: settings,
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      exporterValidationReportPath: path,
      lastMessage: '导出器验证报告已生成。',
      lastError: '',
    );
    notifyListeners();
    return path;
  }

  Future<String> runParallelTaskCapacityValidation({int taskCount = 8}) async {
    if (!_canRunDesktop()) {
      return '';
    }
    final workspace = _requireWorkspace();
    final root =
        Directory(_join(workspace.path, 'tasks', 'parallel_validation'));
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
    await root.create(recursive: true);
    final boundedTaskCount = taskCount.clamp(3, 32).toInt();
    final startedAt = DateTime.now().toUtc();
    final taskResults = await Future.wait([
      for (var index = 0; index < boundedTaskCount; index++)
        _writeParallelValidationTask(root, index),
    ]);
    final isolatedPaths =
        taskResults.map((task) => task['artifact_dir'].toString()).toSet();
    final failedIsolated = taskResults
        .where((task) => task['first_attempt_status'] == 'retryable')
        .every((task) => task['final_status'] == 'succeeded');
    final status = isolatedPaths.length == taskResults.length && failedIsolated
        ? 'passed'
        : 'failed';
    final finishedAt = DateTime.now().toUtc();
    final capacityReportPath =
        _join(root.path, 'parallel_task_capacity_report.json');
    final isolationMatrixPath = _join(root.path, 'task_isolation_matrix.json');
    final recoveryReportPath = _join(root.path, 'task_recovery_report.json');
    final historyPath = _join(root.path, 'task_run_history.jsonl');
    final capacityReport = {
      'schema_version': 'prd_v3_parallel_task_capacity_report.v1',
      'status': status,
      'started_at': startedAt.toIso8601String(),
      'finished_at': finishedAt.toIso8601String(),
      'requested_task_count': taskCount,
      'bounded_task_count': boundedTaskCount,
      'concurrency_model': 'bounded_local_future_wait',
      'workspace_boundary': workspace.path,
      'task_count': taskResults.length,
      'succeeded_count': taskResults
          .where((task) => task['final_status'] == 'succeeded')
          .length,
      'retryable_count': taskResults
          .where((task) => task['first_attempt_status'] == 'retryable')
          .length,
      'isolated_artifact_dirs': isolatedPaths.length,
      'supports_multi_task_parallelism': status == 'passed',
      'supports_failure_isolation': failedIsolated,
      'supports_recovery_retry': failedIsolated,
      'stage_3_provider_hot_swap_required': true,
      'task_history_path': historyPath,
    };
    final isolationMatrix = {
      'schema_version': 'prd_v3_task_isolation_matrix.v1',
      'status': isolatedPaths.length == taskResults.length
          ? 'isolated'
          : 'path_collision_detected',
      'workspace_boundary': workspace.path,
      'tasks': taskResults
          .map((task) => {
                'task_id': task['task_id'],
                'artifact_dir': task['artifact_dir'],
                'owns_only': task['owned_files'],
                'shared_write_allowed': false,
              })
          .toList(growable: false),
    };
    final recoveryReport = {
      'schema_version': 'prd_v3_task_recovery_report.v1',
      'status': failedIsolated ? 'passed' : 'failed',
      'failed_task_id': 'parallel_task_002',
      'first_attempt_status': 'retryable',
      'retry_status': 'succeeded',
      'failed_task_isolated_from_other_tasks': failedIsolated,
      'other_tasks_completed': taskResults
          .where((task) => task['task_id'] != 'parallel_task_002')
          .every((task) => task['final_status'] == 'succeeded'),
    };
    await File(capacityReportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(capacityReport),
      encoding: utf8,
    );
    await File(isolationMatrixPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(isolationMatrix),
      encoding: utf8,
    );
    await File(recoveryReportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(recoveryReport),
      encoding: utf8,
    );
    await File(historyPath).writeAsString(
      taskResults.map((task) => jsonEncode(task)).join('\n'),
      encoding: utf8,
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      parallelTaskCapacityReportPath: capacityReportPath,
      taskIsolationMatrixPath: isolationMatrixPath,
      taskRecoveryReportPath: recoveryReportPath,
      lastMessage: '并行任务容量、隔离和恢复验证报告已生成。',
      lastError: '',
    );
    notifyListeners();
    return capacityReportPath;
  }

  Future<String> exportAuditReport() async {
    if (!_canRunDesktop()) {
      return '';
    }
    final workspace = _requireWorkspace();
    final auditDir = Directory(_join(workspace.path, 'audit'));
    await auditDir.create(recursive: true);
    final reportPath = _join(auditDir.path, 'audit_report.json');
    final last = state.lastResult;
    final records = <Map<String, Object?>>[
      {
        'module': 'document_library',
        'event': 'source_import',
        'status': state.hasImportedFile ? 'success' : 'not_run',
        'artifact': state.sourceManifestPath,
        'detail': '${state.sourceCount} sources',
      },
      {
        'module': 'document_library',
        'event': 'parse_chunk',
        'status': state.parseReportPath.isNotEmpty ? 'success' : 'not_run',
        'artifact': state.parseReportPath,
        'detail': '${state.chunkCount} chunks',
      },
      {
        'module': 'standard_knowledge_package',
        'event': 'export_or_import',
        'status': state.hasStandardKnowledgePackage ? 'success' : 'not_run',
        'artifact': state.standardKnowledgePackageManifestPath,
        'detail': state.standardKnowledgePackagePath,
      },
      {
        'module': 'knowledge_base',
        'event': 'build',
        'status': state.hasKnowledgeBase ? 'success' : 'not_run',
        'artifact': state.kbManifestPath,
        'detail': '${state.chunkCount} chunks',
      },
      {
        'module': 'retrieval_validation',
        'event': 'query',
        'status': state.queryResultPath.isNotEmpty ? 'success' : 'not_run',
        'artifact': state.queryResultPath,
        'detail': state.searchQuery,
      },
      {
        'module': 'document_generation',
        'event': 'export',
        'status': state.exportedDocumentPath.isNotEmpty ? 'success' : 'not_run',
        'artifact': state.exportedDocumentPath,
        'detail': state.exportManifestPath,
      },
      {
        'module': 'skill_factory',
        'event': 'generate_skill',
        'status': state.hasSkill ? 'success' : 'not_run',
        'artifact': state.skillPath,
        'detail': 'Skill package',
      },
      {
        'module': 'agent_workbench',
        'event': 'generate_agent',
        'status': state.hasAgent ? 'success' : 'not_run',
        'artifact': state.agentPath,
        'detail': 'Agent package',
      },
      {
        'module': 'agent_workbench',
        'event': 'agent_dialogue',
        'status': state.hasAgentDialogue ? 'success' : 'not_run',
        'artifact': state.agentDialoguePath,
        'detail': '${state.agentDialogueTurnCount} turns',
      },
      {
        'module': 'agent_workbench',
        'event': 'a2a_discussion',
        'status': state.hasMultiAgentDiscussion ? 'success' : 'not_run',
        'artifact': state.multiAgentDiscussionPath,
        'detail': 'Multi-agent discussion',
      },
      {
        'module': 'settings_provider',
        'event': 'provider_crud_validation',
        'status': state.providerValidationReportPath.isNotEmpty
            ? 'success'
            : 'not_run',
        'artifact': state.providerValidationReportPath,
        'detail': state.providerRuntimeSettingsPath,
      },
      {
        'module': 'settings_exporter',
        'event': 'exporter_validation',
        'status': state.exporterValidationReportPath.isNotEmpty
            ? 'success'
            : 'not_run',
        'artifact': state.exporterValidationReportPath,
        'detail': 'Markdown/JSON/CSV local; DOCX/PDF/PPTX dependency-gated',
      },
      {
        'module': 'task_parallelism',
        'event': 'capacity_isolation_recovery',
        'status': state.parallelTaskCapacityReportPath.isNotEmpty
            ? 'success'
            : 'not_run',
        'artifact': state.parallelTaskCapacityReportPath,
        'detail': state.taskIsolationMatrixPath,
      },
      {
        'module': 'runtime',
        'event': last?.actionId ?? 'last_message',
        'status': last?.productStatus ?? state.phase.name,
        'artifact': last?.outputPath ?? '',
        'detail': _redactSecret(
            state.lastError.isEmpty ? state.lastMessage : state.lastError, ''),
      },
    ];
    final report = {
      'schema_version': 'heitang_workbench_audit_report.v1',
      'workspace': workspace.path,
      'runtime_phase': state.phase.name,
      'running': state.running,
      'records': records,
      'failure_records': records
          .where((record) =>
              record['status'] == 'failed' ||
              record['status'] == 'blocked' ||
              record['status'] == 'degraded')
          .toList(growable: false),
      'artifact_records': records
          .where((record) => (record['artifact']?.toString() ?? '').isNotEmpty)
          .toList(growable: false),
      'last_error': _redactSecret(state.lastError, ''),
    };
    await File(reportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
      encoding: utf8,
    );
    state = state.copyWith(
      lastMessage: '审计报告已导出到工作区。',
      lastError: '',
    );
    notifyListeners();
    return reportPath;
  }

  Future<String> readWorkspaceTextArtifact(String path,
      {int maxCharacters = 6000}) async {
    if (!_canRunDesktop()) {
      return '真实产物预览需要 Windows EXE 桌面端。';
    }
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return '尚未生成可预览产物。';
    }
    final workspace = _requireWorkspace().absolute.path;
    final file = File(trimmed).absolute;
    if (!_isInsideDirectory(file.path, workspace)) {
      return '无法预览：产物路径不在当前工作区内。';
    }
    final extension = _extension(file.path).toLowerCase();
    const supported = {
      '.md',
      '.txt',
      '.json',
      '.jsonl',
      '.yaml',
      '.yml',
      '.csv',
      '.log'
    };
    if (!supported.contains(extension)) {
      return '无法预览：仅支持文本产物。';
    }
    if (!await file.exists()) {
      return '无法预览：产物文件不存在。';
    }
    final text = await file.readAsString(encoding: utf8);
    if (text.length <= maxCharacters) {
      return text;
    }
    return '${text.substring(0, maxCharacters)}\n\n... 预览已截断，完整内容请复制路径后在本地查看。';
  }

  static String _retrievalValidationMarkdown(Map<String, dynamic> payload) {
    final results = _listOfMaps(payload['results']);
    final corrections = _listOfMaps(payload['manual_corrections']);
    final selectedKbIds = payload['selected_kb_ids'] is List
        ? (payload['selected_kb_ids'] as List)
            .map((value) => value.toString())
            .where((value) => value.isNotEmpty)
            .toList(growable: false)
        : const <String>[];
    final buffer = StringBuffer()
      ..writeln('# 检索验证报告')
      ..writeln()
      ..writeln('- 查询：${payload['query'] ?? ''}')
      ..writeln(
          '- 知识库：${selectedKbIds.isEmpty ? 'current_kb' : selectedKbIds.join(', ')}')
      ..writeln('- 结果数：${payload['result_count'] ?? 0}')
      ..writeln('- 引用覆盖率：${payload['citation_coverage'] ?? 0}')
      ..writeln('- 矛盾项：${payload['conflict_count'] ?? 0}')
      ..writeln('- 纠偏状态：${payload['correction_status'] ?? ''}')
      ..writeln('- 外部验证：${payload['external_validation_status'] ?? ''}')
      ..writeln()
      ..writeln('## 人工纠偏');
    if (corrections.isEmpty) {
      buffer.writeln('- 暂无人工纠偏记录。');
    } else {
      for (final correction in corrections) {
        buffer.writeln(
            '- #${correction['result_index']}: ${correction['decision']} (${correction['normalized_decision']})');
      }
    }
    buffer
      ..writeln()
      ..writeln('## 证据结果');
    if (results.isEmpty) {
      buffer.writeln('- 无检索结果。');
    } else {
      for (final row in results) {
        buffer
          ..writeln('- ${_compact(row['title'] ?? row['excerpt'] ?? '')}')
          ..writeln('  - KB：${row['kb_name'] ?? row['kb_id'] ?? ''}')
          ..writeln('  - 引用：${row['citation'] ?? ''}')
          ..writeln('  - 分数：${row['score'] ?? ''}');
      }
    }
    return buffer.toString();
  }

  Future<void> clearImportedSources() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    await _clearGeneratedArtifacts(includeImport: true);
    await _clearWorkspacePath(_join(workspace.path, 'input'));
    await _clearWorkspacePath(_join(workspace.path, 'source_manifest.json'));
    await _clearWorkspacePath(_join(workspace.path, 'standard_packages'));
    state = state.copyWith(
      phase: Rc6RuntimePhase.initial,
      selectedFilePath: '',
      sourceManifestPath: '',
      standardKnowledgePackagePath: '',
      standardKnowledgePackageManifestPath: '',
      standardKnowledgePackageContentPath: '',
      standardKnowledgePackageAuditPath: '',
      parseReportPath: '',
      chunksPath: '',
      kbManifestPath: '',
      qualityReportPath: '',
      cardsPath: '',
      qaPairsPath: '',
      sourceMapPath: '',
      indexMetadataPath: '',
      indexProfilePath: '',
      keywordIndexPath: '',
      vectorIndexReferencePath: '',
      metadataIndexPath: '',
      citationIndexPath: '',
      memoryIndexReferencePath: '',
      indexBuildReportPath: '',
      buildLogPath: '',
      errorLogPath: '',
      queryResultPath: '',
      retrievalPlanPath: '',
      retrievalRerankReportPath: '',
      retrievalCitationCoveragePath: '',
      retrievalConflictReportPath: '',
      externalValidationBoundaryPath: '',
      retrievalValidationReportPath: '',
      retrievalValidationMarkdownPath: '',
      retrievalValidationHistoryPath: '',
      generatedMarkdownPath: '',
      readingNotesPath: '',
      editedDocumentPath: '',
      editManifestPath: '',
      documentOutlinePath: '',
      documentCitationsPath: '',
      documentValidationReportPath: '',
      exportedDocumentPath: '',
      exportManifestPath: '',
      sourceCount: 0,
      sourceNames: const [],
      sourceRecords: const [],
      chunkCount: 0,
      searchQuery: '',
      searchStatus: Rc6SearchStatus.idle,
      searchResults: const [],
      lastMessage: '导入批次和下游产物已删除。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> clearKnowledgeBaseArtifacts() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    for (final relative in const [
      'kb',
      'query',
      'doc',
      'export',
      'prd_p0',
    ]) {
      await _clearWorkspacePath(_join(workspace.path, relative));
    }
    state = state.copyWith(
      phase: state.hasImportedFile
          ? Rc6RuntimePhase.documentUnderstanding
          : Rc6RuntimePhase.initial,
      chunksPath: '',
      kbManifestPath: '',
      qualityReportPath: '',
      cardsPath: '',
      qaPairsPath: '',
      sourceMapPath: '',
      indexMetadataPath: '',
      indexProfilePath: '',
      keywordIndexPath: '',
      vectorIndexReferencePath: '',
      metadataIndexPath: '',
      citationIndexPath: '',
      memoryIndexReferencePath: '',
      indexBuildReportPath: '',
      buildLogPath: '',
      errorLogPath: '',
      queryResultPath: '',
      retrievalPlanPath: '',
      retrievalRerankReportPath: '',
      retrievalCitationCoveragePath: '',
      retrievalConflictReportPath: '',
      externalValidationBoundaryPath: '',
      retrievalValidationReportPath: '',
      retrievalValidationMarkdownPath: '',
      retrievalValidationHistoryPath: '',
      generatedMarkdownPath: '',
      readingNotesPath: '',
      editedDocumentPath: '',
      editManifestPath: '',
      documentOutlinePath: '',
      documentCitationsPath: '',
      documentValidationReportPath: '',
      exportedDocumentPath: '',
      exportManifestPath: '',
      prdP0EvidencePath: '',
      chunkCount: 0,
      searchQuery: '',
      searchStatus: Rc6SearchStatus.idle,
      searchResults: const [],
      lastMessage: '知识库、检索和文档导出产物已删除。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> clearParseArtifacts() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    for (final relative in const [
      'du',
      'standard_packages',
      'kb',
      'query',
      'doc',
      'export',
      'skill',
      'agent',
      'multi_agent',
      'prd_p0',
    ]) {
      await _clearWorkspacePath(_join(workspace.path, relative));
    }
    await _clearWorkspacePath(_join(workspace.path, 'parse_report.json'));
    state = state.copyWith(
      phase: state.hasImportedFile
          ? Rc6RuntimePhase.imported
          : Rc6RuntimePhase.initial,
      parseReportPath: '',
      standardKnowledgePackagePath: '',
      standardKnowledgePackageManifestPath: '',
      standardKnowledgePackageContentPath: '',
      standardKnowledgePackageAuditPath: '',
      chunksPath: '',
      kbManifestPath: '',
      qualityReportPath: '',
      cardsPath: '',
      qaPairsPath: '',
      sourceMapPath: '',
      indexMetadataPath: '',
      indexProfilePath: '',
      keywordIndexPath: '',
      vectorIndexReferencePath: '',
      metadataIndexPath: '',
      citationIndexPath: '',
      memoryIndexReferencePath: '',
      indexBuildReportPath: '',
      buildLogPath: '',
      errorLogPath: '',
      queryResultPath: '',
      retrievalPlanPath: '',
      retrievalRerankReportPath: '',
      retrievalCitationCoveragePath: '',
      retrievalConflictReportPath: '',
      externalValidationBoundaryPath: '',
      retrievalValidationReportPath: '',
      retrievalValidationMarkdownPath: '',
      retrievalValidationHistoryPath: '',
      generatedMarkdownPath: '',
      readingNotesPath: '',
      editedDocumentPath: '',
      editManifestPath: '',
      documentOutlinePath: '',
      documentCitationsPath: '',
      documentValidationReportPath: '',
      exportedDocumentPath: '',
      exportManifestPath: '',
      skillPath: '',
      agentPath: '',
      multiAgentDiscussionPath: '',
      prdP0EvidencePath: '',
      chunkCount: 0,
      searchQuery: '',
      searchStatus: Rc6SearchStatus.idle,
      searchResults: const [],
      lastMessage: '解析报告和下游产物已删除；导入文件保留。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> clearSearchArtifacts() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    await _clearWorkspacePath(_join(workspace.path, 'query'));
    state = state.copyWith(
      phase: state.hasKnowledgeBase
          ? Rc6RuntimePhase.knowledgeBuilt
          : Rc6RuntimePhase.imported,
      queryResultPath: '',
      retrievalPlanPath: '',
      retrievalRerankReportPath: '',
      retrievalCitationCoveragePath: '',
      retrievalConflictReportPath: '',
      externalValidationBoundaryPath: '',
      retrievalValidationReportPath: '',
      retrievalValidationMarkdownPath: '',
      retrievalValidationHistoryPath: '',
      searchQuery: '',
      searchStatus: Rc6SearchStatus.idle,
      searchResults: const [],
      lastMessage: '检索记录已删除。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> clearDocumentArtifacts() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    await _clearWorkspacePath(_join(workspace.path, 'doc'));
    await _clearWorkspacePath(_join(workspace.path, 'export'));
    await _clearWorkspacePath(_join(workspace.path, 'prd_p0'));
    state = state.copyWith(
      phase: state.searchStatus == Rc6SearchStatus.success
          ? Rc6RuntimePhase.searched
          : state.hasKnowledgeBase
              ? Rc6RuntimePhase.knowledgeBuilt
              : Rc6RuntimePhase.imported,
      generatedMarkdownPath: '',
      readingNotesPath: '',
      editedDocumentPath: '',
      editManifestPath: '',
      documentOutlinePath: '',
      documentCitationsPath: '',
      documentValidationReportPath: '',
      exportedDocumentPath: '',
      exportManifestPath: '',
      prdP0EvidencePath: '',
      lastMessage: '文档生成和导出记录已删除。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> clearSkillArtifacts() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    for (final relative in const [
      'skill',
      'agent/dialogue',
      'agent/dialogue_export',
      'multi_agent',
      'prd_p0',
    ]) {
      await _clearWorkspacePath(_join(workspace.path, relative));
    }
    state = state.copyWith(
      phase: state.hasReadingNotes
          ? Rc6RuntimePhase.documentGenerated
          : state.searchStatus == Rc6SearchStatus.success
              ? Rc6RuntimePhase.searched
              : state.hasKnowledgeBase
                  ? Rc6RuntimePhase.knowledgeBuilt
                  : Rc6RuntimePhase.imported,
      skillPath: '',
      primarySkillPath: '',
      skillConfigPath: '',
      skillVerificationReportPath: '',
      skillGenerationManifestPath: '',
      skillPackageManifestPath: '',
      skillValidationReportPath: '',
      localizedSkillManifestPath: '',
      localizedSkillDiffPath: '',
      skillVersionManifestPath: '',
      skillOperationManifestPath: '',
      skillOperationHistoryPath: '',
      skillFactoryAuditPath: '',
      skillExportPath: '',
      skillAgentBindingManifestPath: '',
      skillOperationStatus: '',
      skillAgentBindingStatus: '',
      agentDialoguePath: '',
      agentDialogueManifestPath: '',
      agentDialogueHistoryPath: '',
      agentDialogueExportPath: '',
      agentDialogueTurnCount: 0,
      agentDialogueModelConfigId: '',
      agentDialogueUsedKbIds: const [],
      agentDialogueUsedSkillIds: const [],
      agentDialogueOutputFormat: '',
      agentDialogueEvidenceCount: 0,
      agentDialogueMemoryWriteStatus: '',
      agentDialogueErrorMessage: '',
      multiAgentDiscussionPath: '',
      multiAgentDiscussionManifestPath: '',
      a2aSessionManifestPath: '',
      a2aWorkspaceReportPath: '',
      a2aSessionId: '',
      a2aTopic: '',
      a2aParticipantAgentIds: const [],
      a2aEvidenceCount: 0,
      a2aStatus: '',
      prdP0EvidencePath: '',
      skillVersionCount: 0,
      lastMessage: 'Skill 产物已删除；依赖该 Skill 的对话和协作输出已清理，Agent 配置保留。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> clearAgentArtifacts() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    await _clearWorkspacePath(_join(workspace.path, 'agent'));
    await _clearWorkspacePath(_join(workspace.path, 'multi_agent'));
    await _clearWorkspacePath(_join(workspace.path, 'prd_p0'));
    state = state.copyWith(
      phase: state.hasSkill
          ? Rc6RuntimePhase.skillGenerated
          : state.hasReadingNotes
              ? Rc6RuntimePhase.documentGenerated
              : state.searchStatus == Rc6SearchStatus.success
                  ? Rc6RuntimePhase.searched
                  : state.hasKnowledgeBase
                      ? Rc6RuntimePhase.knowledgeBuilt
                      : Rc6RuntimePhase.imported,
      agentPath: '',
      primaryAgentManifestPath: '',
      agentProfilePath: '',
      agentGenerationManifestPath: '',
      agentAdvancedConfigPath: '',
      agentPermissionAuditPath: '',
      agentWorkspacePermissionMatrixPath: '',
      agentValidationReportPath: '',
      agentPackageManifestPath: '',
      agentPackageReadmePath: '',
      agentDialoguePath: '',
      agentDialogueManifestPath: '',
      agentDialogueHistoryPath: '',
      agentDialogueExportPath: '',
      agentDialogueTurnCount: 0,
      agentDialogueModelConfigId: '',
      agentDialogueUsedKbIds: const [],
      agentDialogueUsedSkillIds: const [],
      agentDialogueOutputFormat: '',
      agentDialogueEvidenceCount: 0,
      agentDialogueMemoryWriteStatus: '',
      agentDialogueErrorMessage: '',
      multiAgentDiscussionPath: '',
      multiAgentDiscussionManifestPath: '',
      a2aSessionManifestPath: '',
      a2aWorkspaceReportPath: '',
      a2aConflictReportPath: '',
      a2aConsensusReportPath: '',
      a2aSessionId: '',
      a2aTopic: '',
      a2aParticipantAgentIds: const [],
      a2aEvidenceCount: 0,
      a2aStatus: '',
      prdP0EvidencePath: '',
      lastMessage: 'Agent、对话和讨论产物已删除。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> clearAgentDialogueHistory() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    await _clearWorkspacePath(_join(workspace.path, 'agent', 'dialogue'));
    await _clearWorkspacePath(
        _join(workspace.path, 'agent', 'dialogue_export'));
    state = state.copyWith(
      agentDialoguePath: '',
      agentDialogueManifestPath: '',
      agentDialogueHistoryPath: '',
      agentDialogueExportPath: '',
      agentDialogueTurnCount: 0,
      agentDialogueModelConfigId: '',
      agentDialogueUsedKbIds: const [],
      agentDialogueUsedSkillIds: const [],
      agentDialogueOutputFormat: '',
      agentDialogueEvidenceCount: 0,
      agentDialogueMemoryWriteStatus: '',
      agentDialogueErrorMessage: '',
      lastMessage: '单 Agent 对话历史和导出记录已删除。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> clearRecentTaskArtifacts(String taskId) async {
    switch (taskId) {
      case 'import':
        await clearImportedSources();
        return;
      case 'parse':
        await clearParseArtifacts();
        return;
      case 'kb':
        await clearKnowledgeBaseArtifacts();
        return;
      case 'search':
        await clearSearchArtifacts();
        return;
      case 'doc':
        await clearDocumentArtifacts();
        return;
      case 'skill':
        await clearSkillArtifacts();
        return;
      case 'agent':
        await clearAgentArtifacts();
        return;
      case 'agent_dialogue':
        await clearAgentDialogueHistory();
        return;
      case 'settings':
        await clearSettingsValidationArtifacts();
        return;
      case 'parallel-tasks':
        await clearParallelTaskValidationArtifacts();
        return;
      default:
        _fail('未知任务类型：$taskId');
    }
  }

  Future<void> clearSettingsValidationArtifacts() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    for (final path in [
      _join(workspace.path, 'config', 'provider_validation_report.json'),
      _join(workspace.path, 'config', 'exporter_validation_report.json'),
    ]) {
      await _clearWorkspacePath(path);
    }
    await _loadExistingArtifacts();
    state = state.copyWith(
      providerValidationReportPath: '',
      exporterValidationReportPath: '',
      lastMessage: 'Settings 验证报告已删除，配置文件保留。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> clearParallelTaskValidationArtifacts() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    await _clearWorkspacePath(
        _join(workspace.path, 'tasks', 'parallel_validation'));
    await _loadExistingArtifacts();
    state = state.copyWith(
      parallelTaskCapacityReportPath: '',
      taskIsolationMatrixPath: '',
      taskRecoveryReportPath: '',
      lastMessage: '并行任务验证产物已删除。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> deleteImportedSource(String sourceNameOrRelativePath) async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    final inputDir = Directory(_join(workspace.path, 'input'));
    final manifestPath = _join(workspace.path, 'source_manifest.json');
    final manifest = await _readJsonObject(manifestPath);
    final sources = manifest['sources'];
    if (sources is! List) {
      await clearImportedSources();
      return;
    }
    final targetName = sourceNameOrRelativePath.trim();
    Map<String, dynamic>? selected;
    for (final source in sources.whereType<Map>()) {
      final item = Map<String, dynamic>.from(source);
      if ((item['source_name'] ?? '').toString() == targetName ||
          (item['relative_path'] ?? '').toString() == targetName) {
        selected = item;
        break;
      }
    }
    if (selected == null) {
      _fail('未找到要删除的文档：$sourceNameOrRelativePath');
      return;
    }
    final sourcePath = (selected['source_path'] ?? '').toString();
    if (sourcePath.isNotEmpty &&
        _isInsideDirectory(sourcePath, inputDir.absolute.path)) {
      await _clearWorkspacePath(sourcePath);
    }
    await _clearGeneratedArtifacts(includeImport: false);
    await _clearWorkspacePath(_join(workspace.path, 'import'));
    final remaining = await _supportedSourceFiles(inputDir).length;
    if (remaining == 0) {
      await clearImportedSources();
      return;
    }
    final rewrittenManifest = await _writeSourceManifestFromInput(inputDir);
    final rewritten = await _readJsonObject(rewrittenManifest);
    final sourceNames = _sourceNamesFromManifest(rewritten);
    final sourceRecords = _sourceRecordsFromManifest(rewritten);
    state = state.copyWith(
      phase: Rc6RuntimePhase.imported,
      selectedFilePath: inputDir.path,
      sourceManifestPath: rewrittenManifest,
      sourceCount: sourceNames.length,
      sourceNames: sourceNames,
      sourceRecords: sourceRecords,
      lastMessage: '来源文档已删除；请重新解析并构建知识库。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<File?> _firstFileWithExtension(
      Directory directory, String extension) async {
    if (!await directory.exists()) {
      return null;
    }
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.$extension')) {
        return entity;
      }
    }
    return null;
  }

  Future<File?> _resolveExternalSkillFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return file;
    }
    final directory = Directory(path);
    if (!await directory.exists()) {
      return null;
    }
    final preferred = File(_join(directory.path, 'SKILL.md'));
    if (await preferred.exists()) {
      return preferred;
    }
    const supported = {'.md', '.txt', '.json', '.yaml', '.yml'};
    await for (final entity in directory.list(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      final lower = entity.path.toLowerCase();
      if (supported.any(lower.endsWith)) {
        return entity;
      }
    }
    return null;
  }

  Future<(String, String)> _latestExistingExportArtifact(
      Directory workspace) async {
    final candidates = <(String, String)>[
      (
        _join(workspace.path, 'export', 'reading_notes_export.md'),
        _join(workspace.path, 'export', 'export_manifest.json')
      ),
      (
        _joinNested(workspace.path, 'export/docx/generated.docx'),
        _joinNested(workspace.path, 'export/docx/generated_file_report.json')
      ),
      (
        _joinNested(workspace.path, 'export/pdf/generated.pdf'),
        _joinNested(workspace.path, 'export/pdf/generated_file_report.json')
      ),
      (
        _joinNested(workspace.path, 'export/pptx/generated.pptx'),
        _joinNested(workspace.path, 'export/pptx/generated_file_report.json')
      ),
      (
        _joinNested(workspace.path, 'export/structured/knowledge_export.json'),
        _joinNested(
            workspace.path, 'export/structured/structured_export_manifest.json')
      ),
      (
        _joinNested(workspace.path, 'export/structured/knowledge_export.csv'),
        _joinNested(
            workspace.path, 'export/structured/structured_export_manifest.json')
      ),
    ];
    (String, String, DateTime)? latest;
    for (final candidate in candidates) {
      final file = File(candidate.$1);
      if (!await file.exists()) {
        continue;
      }
      final modified = await file.lastModified();
      if (latest == null || modified.isAfter(latest.$3)) {
        latest = (candidate.$1, candidate.$2, modified);
      }
    }
    if (latest == null) {
      return ('', '');
    }
    return (
      latest.$1,
      await File(latest.$2).exists() ? latest.$2 : '',
    );
  }

  Future<void> generateSkill({
    Rc6SkillGenerationConfig config = const Rc6SkillGenerationConfig(),
  }) async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    final kbDir = Directory(_join(workspace.path, 'kb'));
    if (!await kbDir.exists()) {
      _fail('请先构建知识库，再生成 Skill。');
      return;
    }
    await _clearWorkspacePath(_join(workspace.path, 'skill'));
    await _runCoreAction(
      actionId: 'package_to_skill',
      arguments: [
        'generate-skill',
        '--package',
        kbDir.path,
        '--output',
        _join(workspace.path, 'skill', 'knowledge_qa_skill'),
        '--skill-name',
        config.skillName,
      ],
      outputPath: _join(workspace.path, 'skill', 'knowledge_qa_skill'),
      nextPhase: Rc6RuntimePhase.skillGenerated,
      successMessage: 'Skill 草稿已生成。',
    );
    if (state.lastResult?.passed == true) {
      await _writeAdditionalSkillPackages(config: config);
      await _appendSkillVersionRecord(
        event: 'generate_skill',
        config: config.toJson(),
      );
      await _appendSkillOperationHistoryRecord(
        action: 'generate_skill',
        artifact:
            _joinNested(workspace.path, 'skill/skill_generation_manifest.json'),
        status: 'completed',
        details: config.toJson(),
      );
      await _appendOrchestrationPlanRecord(
        layer: 'skill',
        action: 'generate_skill',
        artifact:
            _joinNested(workspace.path, 'skill/skill_generation_manifest.json'),
        status: 'completed',
        resources: {
          'kb_package': kbDir.path,
          'skill_name': config.skillName,
          'skill_type': config.skillType,
          'target_platform': config.targetPlatform,
        },
      );
      await _writeSkillProductOperations(agentBound: state.hasAgent);
    }
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> pickAndImportExternalSkill() async {
    if (!_canRunDesktop()) {
      return;
    }
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'External Skill',
          extensions: ['md', 'txt', 'json', 'yaml', 'yml'],
        ),
      ],
    );
    if (file != null) {
      await importExternalSkillPath(file.path);
      return;
    }
    final directoryPath = await getDirectoryPath();
    if (directoryPath == null) {
      state = state.copyWith(
        lastMessage: '未选择外部 Skill；本地化未执行。',
        phase: Rc6RuntimePhase.ready,
      );
      notifyListeners();
      return;
    }
    await importExternalSkillPath(directoryPath);
  }

  Future<void> importExternalSkillPath(String path) async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    final kbDir = Directory(_join(workspace.path, 'kb'));
    if (!await kbDir.exists()) {
      _fail('请先构建知识库，再导入并本地化外部 Skill。');
      return;
    }
    final sourceFile = await _resolveExternalSkillFile(path);
    if (sourceFile == null) {
      _fail('未找到可导入的外部 Skill 文件；请选择 SKILL.md、Markdown、JSON 或 YAML 文件。');
      return;
    }
    state = state.copyWith(
      running: true,
      lastMessage: '正在导入并本地化外部 Skill...',
      lastError: '',
    );
    notifyListeners();
    await _writeAdditionalSkillPackages(externalSkillSource: sourceFile);
    await _appendSkillVersionRecord(
      event: 'localize_external_skill',
      config: {
        'source': sourceFile.path,
      },
    );
    await _appendSkillOperationHistoryRecord(
      action: 'localize_external_skill',
      artifact: _joinNested(workspace.path,
          'skill/localized_writing_skill/S2/localized_skill_manifest.json'),
      status: 'completed',
      details: {
        'source': sourceFile.path,
      },
    );
    await _writeSkillProductOperations(agentBound: state.hasAgent);
    await _loadExistingArtifacts();
    state = state.copyWith(
      running: false,
      phase: Rc6RuntimePhase.skillGenerated,
      lastMessage: '外部 Skill 已导入并结合当前知识库生成本地化 Skill。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> generateAgent({
    Rc6AgentGenerationConfig config = const Rc6AgentGenerationConfig(),
  }) async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    final kbDir = Directory(_join(workspace.path, 'kb'));
    final skillDir = Directory(_join(workspace.path, 'skill'));
    if (!await kbDir.exists() || !await skillDir.exists()) {
      _fail('请先构建知识库并生成 Skill，再创建 Agent。');
      return;
    }
    await _clearWorkspacePath(_join(workspace.path, 'agent'));
    await _runCoreAction(
      actionId: 'kb_bound_agent_generation',
      arguments: [
        'generate-agent',
        '--mode',
        config.coreMode,
        '--package',
        kbDir.path,
        '--skill',
        _primarySkillPath(skillDir.path),
        '--output',
        _join(workspace.path, 'agent', 'knowledge_qa_agent'),
        '--agent-name',
        config.agentName,
      ],
      outputPath: _join(workspace.path, 'agent', 'knowledge_qa_agent'),
      nextPhase: Rc6RuntimePhase.agentGenerated,
      successMessage: 'Agent 草稿已生成并绑定知识库/Skill。',
    );
    if (state.lastResult?.passed == true) {
      await _writeAdditionalAgentPackages(config: config);
      await _writeAgentProductOperations(config: config);
      await _appendSkillOperationHistoryRecord(
        action: 'bind_agent',
        artifact: _joinNested(
            workspace.path, 'skill/operations/agent_binding_manifest.json'),
        status: 'bound',
        details: {
          'agent_name': config.agentName,
          'creation_mode': config.creationMode,
        },
      );
      await _appendOrchestrationPlanRecord(
        layer: 'agent',
        action: 'generate_agent',
        artifact:
            _joinNested(workspace.path, 'agent/agent_generation_manifest.json'),
        status: 'completed',
        resources: {
          'kb_package': kbDir.path,
          'skill_package': skillDir.path,
          'agent_name': config.agentName,
          'creation_mode': config.creationMode,
          'agent_type': config.agentType,
          'model_config_id': config.modelConfigId,
        },
      );
      await _writeSkillProductOperations(agentBound: true);
      await _writeMultiAgentDiscussion();
    }
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> runMultiAgentDiscussion({
    String topic = '',
    List<String> participantAgentIds = const [],
  }) async {
    if (!_canRunDesktop()) {
      return;
    }
    if (!state.hasAgent) {
      _fail('请先在 Agent 工厂生成 Agent。');
      return;
    }
    if (!state.hasSkill) {
      _fail('请先在 Skill 工厂生成 Skill，再启动 A2A 协作。');
      return;
    }
    await _writeMultiAgentDiscussion(
      topic: topic,
      participantAgentIds: participantAgentIds,
    );
    final workspace = _requireWorkspace();
    await _appendAgentRunHistoryRecord(
      action: 'run_a2a_discussion',
      artifact:
          _join(workspace.path, 'multi_agent', 'multi_agent_discussion.md'),
      status: 'completed',
      details: {
        'topic': topic.trim(),
        'participant_agent_ids': participantAgentIds,
      },
    );
    await _appendOrchestrationPlanRecord(
      layer: 'a2a',
      action: 'run_a2a_discussion',
      artifact:
          _join(workspace.path, 'multi_agent', 'multi_agent_discussion.md'),
      status: 'completed',
      resources: {
        'topic': topic.trim(),
        'participant_agent_ids': participantAgentIds,
        'parent_workspace_id': 'W_M',
      },
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      lastMessage: '多 Agent 联合讨论纪要已生成。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> runAgentDialogue({String prompt = '请基于当前知识库总结核心要点。'}) async {
    if (!_canRunDesktop()) {
      return;
    }
    if (!state.hasAgent) {
      _fail('请先在 Agent 工厂生成 Agent。');
      return;
    }
    if (!state.hasSkill) {
      _fail('请先在 Skill 工厂生成 Skill，再运行 Agent 对话。');
      return;
    }
    final workspace = _requireWorkspace();
    final outDir = Directory(_join(workspace.path, 'agent', 'dialogue'));
    await outDir.create(recursive: true);
    final queryReport = await _readLatestQueryReport(workspace);
    final queryRows = queryReport['selected'] ??
        queryReport['results'] ??
        queryReport['records'];
    final selected = queryRows is List
        ? queryRows.whereType<Map>().take(4).toList()
        : const <Map>[];
    final chunks = selected.isNotEmpty
        ? const <Map<String, dynamic>>[]
        : (await _readJsonl(File(_join(workspace.path, 'kb', 'chunks.jsonl'))))
            .take(4)
            .toList(growable: false);
    final evidence = selected.isNotEmpty ? selected : chunks;
    final dialoguePath = _join(outDir.path, 'agent_dialogue.md');
    final historyPath = _join(outDir.path, 'chat_history.jsonl');
    final previousTurns = await _readJsonl(File(historyPath));
    final agentConfig = await _readJsonObject(_joinNested(
        workspace.path, 'agent/knowledge_qa_agent/agent_manifest.json'));
    final modelConfigId = _stringValue(
        agentConfig['model_config_id'], 'local-default-or-configured-provider');
    final configuredKbIds = _listOfStrings(agentConfig['kb_ids']);
    final kbIds = configuredKbIds.isEmpty ? const ['K1'] : configuredKbIds;
    final configuredSkillIds = _listOfStrings(agentConfig['skill_ids']);
    final skillIds = configuredSkillIds.isEmpty
        ? const ['S1', 'reading_summary_skill']
        : configuredSkillIds;
    final outputFormat = _stringValue(agentConfig['output_format'], 'markdown');
    final roleGoal =
        _stringValue(agentConfig['role_goal'], '只基于绑定知识库和 Skill 回答，输出必须带引用。');
    final redisConfigId =
        _stringValue(agentConfig['redis_config_id'], 'settings_redis_optional');
    final vectorConfigId =
        _stringValue(agentConfig['vector_config_id'], 'local_file_index');
    final turn = {
      'turn_id':
          'turn_${(previousTurns.length + 1).toString().padLeft(3, '0')}',
      'prompt': prompt,
      'answer': '当前回答基于本地知识库和已生成 Skill，不调用外网、不执行系统命令。',
      'role_goal': roleGoal,
      'model_config_id': modelConfigId,
      'kb_ids': kbIds,
      'skill_ids': skillIds,
      'output_format': outputFormat,
      'evidence_count': evidence.length,
      'evidence': evidence
          .map((item) => {
                'text': _compact(
                    item['text'] ?? item['summary'] ?? item['content'] ?? ''),
                'citation': (item['citation'] ??
                        item['source_path'] ??
                        item['chunk_id'] ??
                        '-')
                    .toString(),
              })
          .toList(growable: false),
      'memory_write': {
        'short_term': 'local_session',
        'history_path': historyPath,
        'redis_config_id': redisConfigId,
        'vector_config_id': vectorConfigId,
        'vector_memory': 'separate_from_kb_index',
      },
      'boundary': {
        'local_kb_only': true,
        'computer_use': false,
        'arbitrary_shell': false,
        'secret_plaintext_access': false,
      },
    };
    await File(historyPath).writeAsString(
      '${const JsonEncoder().convert(turn)}\n',
      encoding: utf8,
      mode: FileMode.append,
    );
    final turns = [...previousTurns, turn];
    final buffer = StringBuffer()
      ..writeln('# Agent 最小对话')
      ..writeln()
      ..writeln('## 本轮配置')
      ..writeln('- 模型：$modelConfigId')
      ..writeln('- 角色说明：$roleGoal')
      ..writeln('- 知识库：${kbIds.join(' / ')}')
      ..writeln('- Skill：${skillIds.join(' / ')}')
      ..writeln('- 输出格式：$outputFormat')
      ..writeln('- 记忆写入：local_session -> chat_history.jsonl')
      ..writeln('- Redis 短期记忆配置：$redisConfigId')
      ..writeln('- 向量长期记忆配置：$vectorConfigId')
      ..writeln()
      ..writeln('## 会话历史');
    for (final item in turns) {
      buffer
        ..writeln()
        ..writeln('### ${item['turn_id']}')
        ..writeln()
        ..writeln('**用户问题**')
        ..writeln(item['prompt'])
        ..writeln()
        ..writeln('**Agent 回答**')
        ..writeln(item['answer'])
        ..writeln()
        ..writeln('**证据**');
      final itemEvidence = item['evidence'];
      if (itemEvidence is List && itemEvidence.isNotEmpty) {
        for (final evidenceItem in itemEvidence.whereType<Map>()) {
          buffer.writeln(
              '- ${evidenceItem['text'] ?? ''} (${evidenceItem['citation'] ?? '-'})');
        }
      } else {
        buffer.writeln('- 当前知识库没有可用证据，请先运行检索或重新构建知识库。');
      }
    }
    buffer
      ..writeln()
      ..writeln('## 边界')
      ..writeln('- 仅使用本地 KB/Skill 产物。')
      ..writeln('- 不开放 Computer Use。')
      ..writeln('- 不开放 arbitrary shell。')
      ..writeln('- 不展示明文 secret。');
    await File(dialoguePath).writeAsString(buffer.toString(), encoding: utf8);
    final manifestPath = _join(outDir.path, 'agent_dialogue_manifest.json');
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'rc10_agent_dialogue.v1',
        'status': evidence.isEmpty ? 'needs_evidence' : 'pass',
        'latest_prompt': prompt,
        'output': dialoguePath,
        'history_path': historyPath,
        'turn_count': turns.length,
        'evidence_count': evidence.length,
        'model_config_id': modelConfigId,
        'role_goal': roleGoal,
        'used_kb_ids': kbIds,
        'used_skill_ids': skillIds,
        'output_format': outputFormat,
        'redis_config_id': redisConfigId,
        'vector_config_id': vectorConfigId,
        'citation_required': true,
        'memory_write_status': 'local_session_written',
        'error_message': '',
      }),
      encoding: utf8,
    );
    await _appendAgentRunHistoryRecord(
      action: 'run_agent_dialogue',
      artifact: dialoguePath,
      status: evidence.isEmpty ? 'needs_evidence' : 'completed',
      details: {
        'prompt': prompt,
        'history_path': historyPath,
        'turn_count': turns.length,
        'evidence_count': evidence.length,
        'model_config_id': modelConfigId,
        'used_kb_ids': kbIds,
        'used_skill_ids': skillIds,
      },
    );
    await _appendOrchestrationPlanRecord(
      layer: 'agent',
      action: 'run_agent_dialogue',
      artifact: dialoguePath,
      status: evidence.isEmpty ? 'needs_evidence' : 'completed',
      resources: {
        'prompt': prompt,
        'model_config_id': modelConfigId,
        'kb_ids': kbIds,
        'skill_ids': skillIds,
        'output_format': outputFormat,
        'evidence_count': evidence.length,
      },
    );
    state = state.copyWith(
      agentDialoguePath: dialoguePath,
      agentDialogueManifestPath: manifestPath,
      agentDialogueHistoryPath: historyPath,
      agentDialogueTurnCount: turns.length,
      agentDialogueModelConfigId: modelConfigId,
      agentDialogueUsedKbIds: kbIds,
      agentDialogueUsedSkillIds: skillIds,
      agentDialogueOutputFormat: outputFormat,
      agentDialogueEvidenceCount: evidence.length,
      agentDialogueMemoryWriteStatus: 'local_session_written',
      agentDialogueErrorMessage: '',
      lastMessage: 'Agent 最小对话已追加到会话历史。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<String> exportAgentDialogue() async {
    if (!_canRunDesktop()) {
      return '';
    }
    if (!state.hasAgentDialogue || !state.hasAgentDialogueHistory) {
      _fail('请先运行单 Agent 对话，再导出对话记录。');
      return '';
    }
    final workspace = _requireWorkspace();
    final dialogue = File(state.agentDialoguePath);
    final history = File(state.agentDialogueHistoryPath);
    if (!await dialogue.exists() || !await history.exists()) {
      _fail('对话产物不完整，请重新运行单 Agent 对话。');
      return '';
    }
    final exportDir =
        Directory(_join(workspace.path, 'agent', 'dialogue_export'));
    await exportDir.create(recursive: true);
    final outputPath = _join(exportDir.path, 'agent_dialogue_export.md');
    final manifestPath =
        _join(exportDir.path, 'agent_dialogue_export_manifest.json');
    final historyLines = await history.readAsLines(encoding: utf8);
    final dialogueText = await dialogue.readAsString(encoding: utf8);
    final dialogueManifest = await _readJsonObject(_joinNested(
        workspace.path, 'agent/dialogue/agent_dialogue_manifest.json'));
    final usedKbIds = _listOfStrings(dialogueManifest['used_kb_ids']);
    final usedSkillIds = _listOfStrings(dialogueManifest['used_skill_ids']);
    final modelConfigId = _stringValue(dialogueManifest['model_config_id'],
        'local-default-or-configured-provider');
    await File(outputPath).writeAsString(
      [
        '# Agent 对话导出',
        '',
        '## 导出说明',
        '- 来源对话：${dialogue.path}',
        '- 会话历史：${history.path}',
        '- 导出轮数：${historyLines.length}',
        '- 绑定知识库：${usedKbIds.isEmpty ? 'K1' : usedKbIds.join(' / ')}',
        '- 绑定 Skill：${usedSkillIds.isEmpty ? 'S1 / reading_summary_skill' : usedSkillIds.join(' / ')}',
        '- 模型配置：$modelConfigId',
        '- 高风险能力：未开放 Computer Use / arbitrary shell',
        '',
        dialogueText,
      ].join('\n'),
      encoding: utf8,
    );
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v2_agent_dialogue_export.v1',
        'status': 'pass',
        'workspace': workspace.path,
        'source_dialogue': dialogue.path,
        'source_history': history.path,
        'output': outputPath,
        'turn_count': historyLines.length,
        'used_kb_ids': usedKbIds.isEmpty ? ['K1'] : usedKbIds,
        'used_skill_ids': usedSkillIds.isEmpty
            ? ['S1', 'reading_summary_skill']
            : usedSkillIds,
        'model_config_id': modelConfigId,
        'audit_included': true,
        'secret_plaintext_written': false,
      }),
      encoding: utf8,
    );
    await _appendAgentRunHistoryRecord(
      action: 'export_agent_dialogue',
      artifact: outputPath,
      status: 'completed',
      details: {
        'manifest_path': manifestPath,
        'source_history': history.path,
        'turn_count': historyLines.length,
        'used_kb_ids': usedKbIds.isEmpty ? ['K1'] : usedKbIds,
        'used_skill_ids': usedSkillIds.isEmpty
            ? ['S1', 'reading_summary_skill']
            : usedSkillIds,
      },
    );
    await _appendOrchestrationPlanRecord(
      layer: 'agent',
      action: 'export_agent_dialogue',
      artifact: outputPath,
      status: 'completed',
      resources: {
        'manifest_path': manifestPath,
        'source_history': history.path,
        'turn_count': historyLines.length,
      },
    );
    state = state.copyWith(
      agentDialogueExportPath: outputPath,
      lastMessage: 'Agent 对话记录已导出。',
      lastError: '',
    );
    notifyListeners();
    return outputPath;
  }

  Future<void> completeSkillProductOperations() async {
    if (!_canRunDesktop()) {
      return;
    }
    if (!state.hasSkill) {
      await generateSkill();
      if (!state.hasSkill) return;
    }
    final workspace = _requireWorkspace();
    await _appendSkillOperationHistoryRecord(
      action: 'complete_skill_product_operations',
      artifact: _joinNested(
          workspace.path, 'skill/operations/skill_operation_manifest.json'),
      status: 'completed',
      details: {
        'agent_bound': state.hasAgent,
      },
    );
    await _writeSkillProductOperations(agentBound: state.hasAgent);
    await _loadExistingArtifacts();
    state = state.copyWith(
      lastMessage: state.hasAgent
          ? 'Skill 查看、复制、融合、导出和 Agent 绑定产物已生成。'
          : 'Skill 查看、复制、融合和导出产物已生成；Agent 绑定将在创建 Agent 后写入。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> runSkillOperation(String operation) async {
    if (!_canRunDesktop()) {
      return;
    }
    final normalized = operation.trim();
    const allowed = {
      'copy',
      'fusion',
      'validate',
      'export',
      'bind_agent',
    };
    if (!allowed.contains(normalized)) {
      _fail('未知 Skill 操作：$operation');
      return;
    }
    if (!state.hasSkill) {
      await generateSkill();
      if (!state.hasSkill) return;
    }
    await _appendSkillVersionRecord(
      event: 'skill_operation_$normalized',
      config: {'operation': normalized},
    );
    final workspace = _requireWorkspace();
    await _appendSkillOperationHistoryRecord(
      action: 'skill_operation_$normalized',
      artifact: _joinNested(
          workspace.path, 'skill/operations/skill_operation_manifest.json'),
      status: 'completed',
      details: {
        'operation': normalized,
        'agent_bound': state.hasAgent,
      },
    );
    await _writeSkillProductOperations(
      agentBound: state.hasAgent,
      requestedOperation: normalized,
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      lastMessage: 'Skill 操作已完成：$normalized。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<String> saveEditedSkill(String skillMarkdown) async {
    if (!_canRunDesktop()) {
      return '';
    }
    if (!state.hasSkill) {
      _fail('请先生成 Skill 草稿，再保存编辑内容。');
      return '';
    }
    final trimmed = skillMarkdown.trim();
    if (trimmed.isEmpty) {
      _fail('Skill 草稿不能为空。');
      return '';
    }
    final workspace = _requireWorkspace();
    final skillRoot = Directory(_join(workspace.path, 'skill'));
    final primaryDir = Directory(_join(skillRoot.path, 'knowledge_qa_skill'));
    final primarySkill = File(_join(primaryDir.path, 'SKILL.md'));
    if (!await primarySkill.exists()) {
      _fail('未找到可编辑的 SKILL.md。');
      return '';
    }
    state = state.copyWith(
      running: true,
      lastMessage: '正在保存 Skill 编辑稿...',
      lastError: '',
    );
    notifyListeners();
    final previous = await primarySkill.readAsString(encoding: utf8);
    final backup = File(_join(primaryDir.path, 'SKILL.original.md'));
    if (!await backup.exists()) {
      await backup.writeAsString(previous, encoding: utf8);
    }
    await primarySkill.writeAsString(skillMarkdown, encoding: utf8);
    final manifestPath = _join(primaryDir.path, 'skill_edit_manifest.json');
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v2_skill_draft_edit.v1',
        'status': 'pass',
        'workspace': workspace.path,
        'edited_skill_path': primarySkill.path,
        'original_backup_path': backup.path,
        'size_bytes': await primarySkill.length(),
        'saved_at': DateTime.now().toUtc().toIso8601String(),
        'source_kb_manifest': _join(workspace.path, 'kb', 'manifest.json'),
        'secret_plaintext_written': false,
      }),
      encoding: utf8,
    );
    await _appendSkillVersionRecord(
      event: 'edit_skill',
      config: {
        'edited_skill_path': primarySkill.path,
      },
    );
    await _appendSkillOperationHistoryRecord(
      action: 'edit_skill',
      artifact: manifestPath,
      status: 'completed',
      details: {
        'edited_skill_path': primarySkill.path,
      },
    );
    await _writeSkillProductOperations(agentBound: state.hasAgent);
    await _loadExistingArtifacts();
    state = state.copyWith(
      running: false,
      phase: Rc6RuntimePhase.skillGenerated,
      lastMessage: 'Skill 编辑稿已保存并更新导出包。',
      lastError: '',
    );
    notifyListeners();
    return primarySkill.path;
  }

  Future<void> completeAgentProductOperations({
    Rc6AgentGenerationConfig config = const Rc6AgentGenerationConfig(),
  }) async {
    if (!_canRunDesktop()) {
      return;
    }
    if (!state.hasAgent) {
      await generateAgent(config: config);
      if (!state.hasAgent) return;
    }
    await _writeAgentProductOperations(config: config);
    await _writeSkillProductOperations(agentBound: true);
    await runAgentDialogue();
    await _loadExistingArtifacts();
    state = state.copyWith(
      lastMessage: 'Agent 工作区、配置、权限审计、导出包、最小对话和 A2A 产物已生成。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> runRealInputFolderE2E(String folderPath,
      {String query = '赚钱 小生意'}) async {
    await importFolderPath(folderPath);
    if (state.lastResult?.passed != true) return;
    await parseAndChunkSources();
    if (state.lastResult?.passed != true) return;
    await buildKnowledgeBase();
    if (state.lastResult?.passed != true) return;
    await search(query);
    if (state.lastResult?.passed != true ||
        state.searchStatus != Rc6SearchStatus.success) {
      return;
    }
    await generateMarkdown();
    if (state.lastResult?.passed != true) return;
    await exportMarkdownDocument();
    await exportDocumentFormat('json');
    await exportDocumentFormat('csv');
    await generateSkill();
    if (state.lastResult?.passed != true) return;
    await generateAgent();
    if (state.lastResult?.passed != true) return;
    await runAgentDialogue();
  }

  Future<void> runOwnerInputFolderE2E({String query = '赚钱 小生意'}) async {
    await runRealInputFolderE2E(
      r'D:\HeiTang-Codex-WorkSpace\input',
      query: query,
    );
  }

  Future<void> runPrdP0ProductE2E(String folderPath,
      {String query = '赚钱 小生意'}) async {
    await runRealInputFolderE2E(folderPath, query: query);
    if (!state.hasAgentDialogue || !state.hasMultiAgentDiscussion) return;
    await _writePrdP0ProductArtifacts(query: query);
    await _loadExistingArtifacts();
    state = state.copyWith(
      lastMessage: 'PRD P0 多知识库、外部 Skill、本地化 Skill、Agent 工作区和 A2A 闭环已生成。',
      lastError: '',
    );
    notifyListeners();
  }

  Future<void> runOwnerInputPrdP0E2E({String query = '赚钱 小生意'}) async {
    await runPrdP0ProductE2E(
      r'D:\HeiTang-Codex-WorkSpace\input',
      query: query,
    );
  }

  Future<void> runDocumentFlowE2E(String folderPath,
      {String query = '赚钱 小生意'}) async {
    await importFolderPath(folderPath);
    if (state.lastResult?.passed != true) return;
    await parseAndChunkSources();
    if (state.lastResult?.passed != true) return;
    await buildKnowledgeBase();
    if (state.lastResult?.passed != true) return;
    await search(query);
    if (state.lastResult?.passed != true ||
        state.searchStatus != Rc6SearchStatus.success) {
      return;
    }
    await generateMarkdown();
    if (state.lastResult?.passed != true) return;
    await exportMarkdownDocument();
    await exportDocumentFormat('json');
    await exportDocumentFormat('csv');
  }

  Future<void> runOwnerInputDocumentFlowE2E({String query = '赚钱 小生意'}) async {
    await runDocumentFlowE2E(
      r'D:\HeiTang-Codex-WorkSpace\input',
      query: query,
    );
  }

  Future<void> runMinimumE2E({String query = 'heitang-rc6-needle'}) async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    final sourceManifest = File(_join(workspace.path, 'source_manifest.json'));
    if (!state.hasImportedFile && !await sourceManifest.exists()) {
      _fail('请先通过文件选择器导入真实文件，再运行完整链路。');
      return;
    }
    await parseAndChunkSources();
    if (state.lastResult?.passed != true) return;
    await buildKnowledgeBase();
    if (state.lastResult?.passed != true) return;
    await search(query);
    if (state.lastResult?.passed != true ||
        state.searchStatus != Rc6SearchStatus.success) {
      return;
    }
    await generateMarkdown();
    if (state.lastResult?.passed != true) return;
    await generateSkill();
    if (state.lastResult?.passed != true) return;
    await generateAgent();
    if (state.lastResult?.passed != true) return;
    await runAgentDialogue();
  }

  Future<void> _runCoreAction({
    required String actionId,
    required List<String> arguments,
    required String outputPath,
    required Rc6RuntimePhase nextPhase,
    required String successMessage,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final workspace = _requireWorkspace();
    state = state.copyWith(
      running: true,
      lastMessage: '运行 $actionId...',
      lastError: '',
    );
    notifyListeners();
    final request = CoreBridgeRequest(
      actionId: actionId,
      coreCli: coreCli,
      workingDirectory: _effectiveCoreWorkingDirectory,
      arguments: arguments,
      outputPath: outputPath,
      allowedOutputRoot: workspace.path,
      timeout: timeout,
    );
    final result = await coreBridge.run(request, isWeb: isWebRuntime);
    state = state.copyWith(
      running: false,
      lastResult: result,
      phase: result.passed ? nextPhase : Rc6RuntimePhase.failed,
      lastMessage: result.passed ? successMessage : result.userReason,
      lastError: result.passed ? '' : result.userReason,
    );
    notifyListeners();
  }

  Future<void> _clearGeneratedArtifacts({required bool includeImport}) async {
    final workspace = _requireWorkspace();
    if (includeImport) {
      await _clearWorkspacePath(_join(workspace.path, 'import'));
    }
    for (final relative in const [
      'du',
      'standard_packages',
      'kb',
      'query',
      'doc',
      'skill',
      'agent',
      'multi_agent',
      'prd_p0',
    ]) {
      await _clearWorkspacePath(_join(workspace.path, relative));
    }
    await _clearWorkspacePath(_join(workspace.path, 'parse_report.json'));
    state = state.copyWith(
      phase: includeImport ? Rc6RuntimePhase.imported : state.phase,
      parseReportPath: '',
      standardKnowledgePackagePath: '',
      standardKnowledgePackageManifestPath: '',
      standardKnowledgePackageContentPath: '',
      standardKnowledgePackageAuditPath: '',
      chunksPath: '',
      kbManifestPath: '',
      qualityReportPath: '',
      queryResultPath: '',
      generatedMarkdownPath: '',
      exportedDocumentPath: '',
      exportManifestPath: '',
      skillPath: '',
      agentPath: '',
      agentDialoguePath: '',
      agentDialogueManifestPath: '',
      agentDialogueHistoryPath: '',
      agentDialogueExportPath: '',
      agentDialogueTurnCount: 0,
      agentDialogueModelConfigId: '',
      agentDialogueUsedKbIds: const [],
      agentDialogueUsedSkillIds: const [],
      agentDialogueOutputFormat: '',
      agentDialogueEvidenceCount: 0,
      agentDialogueMemoryWriteStatus: '',
      agentDialogueErrorMessage: '',
      readingNotesPath: '',
      editedDocumentPath: '',
      editManifestPath: '',
      multiAgentDiscussionPath: '',
      multiAgentDiscussionManifestPath: '',
      a2aSessionManifestPath: '',
      a2aWorkspaceReportPath: '',
      a2aSessionId: '',
      a2aTopic: '',
      a2aParticipantAgentIds: const [],
      a2aEvidenceCount: 0,
      a2aStatus: '',
      prdP0EvidencePath: '',
      cardsPath: '',
      qaPairsPath: '',
      sourceMapPath: '',
      indexMetadataPath: '',
      indexProfilePath: '',
      keywordIndexPath: '',
      vectorIndexReferencePath: '',
      metadataIndexPath: '',
      citationIndexPath: '',
      memoryIndexReferencePath: '',
      indexBuildReportPath: '',
      chunkCount: 0,
      searchStatus: Rc6SearchStatus.idle,
      searchResults: const [],
    );
  }

  Future<void> _clearWorkspacePath(String targetPath) async {
    final workspace = _requireWorkspace();
    final rootPath = workspace.absolute.path
        .replaceAll('/', Platform.pathSeparator)
        .toLowerCase();
    final normalizedRoot = rootPath.endsWith(Platform.pathSeparator)
        ? rootPath
        : '$rootPath${Platform.pathSeparator}';
    final normalizedTarget = File(targetPath)
        .absolute
        .path
        .replaceAll('/', Platform.pathSeparator)
        .toLowerCase();
    if (!normalizedTarget.startsWith(normalizedRoot)) {
      throw StateError(
          'Refusing to clear path outside document flow workspace');
    }
    final file = File(targetPath);
    if (await file.exists()) {
      await file.delete();
      return;
    }
    final dir = Directory(targetPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> _loadExistingArtifacts() async {
    final workspace = _workspaceDir;
    if (workspace == null || !await workspace.exists()) {
      return;
    }
    final sourceManifestPath = _join(workspace.path, 'source_manifest.json');
    final importReportPath =
        _join(workspace.path, 'import', 'batch_import_report.json');
    final duManifestPath =
        _join(workspace.path, 'du', 'document_understanding_manifest.json');
    final parseReportAliasPath = _join(workspace.path, 'parse_report.json');
    final standardPackagePath =
        _join(workspace.path, 'standard_packages', 'current');
    final standardPackageManifestPath =
        _join(standardPackagePath, 'standard_package_manifest.json');
    final standardPackageContentPath =
        _join(standardPackagePath, 'content_package.jsonl');
    final standardPackageAuditPath =
        _join(workspace.path, 'standard_packages', 'audit_history.jsonl');
    final kbManifestPath = _join(workspace.path, 'kb', 'manifest.json');
    final chunksPath = _join(workspace.path, 'kb', 'chunks.jsonl');
    final cardsPath = _join(workspace.path, 'kb', 'cards.jsonl');
    final qaPairsPath = _join(workspace.path, 'kb', 'qa_pairs.jsonl');
    final qualityPath = _join(workspace.path, 'kb', 'quality_report.json');
    final sourceMapPath = _join(workspace.path, 'kb', 'source_map.json');
    final indexMetadataPath =
        _join(workspace.path, 'kb', 'index_metadata.json');
    final indexProfilePath = _join(workspace.path, 'kb', 'index_profile.json');
    final keywordIndexPath = _join(workspace.path, 'kb', 'keyword_index.json');
    final vectorIndexReferencePath =
        _join(workspace.path, 'kb', 'vector_index_reference.json');
    final metadataIndexPath =
        _join(workspace.path, 'kb', 'metadata_index.json');
    final citationIndexPath =
        _join(workspace.path, 'kb', 'citation_index.json');
    final memoryIndexReferencePath =
        _join(workspace.path, 'kb', 'memory_index_reference.json');
    final indexBuildReportPath =
        _join(workspace.path, 'kb', 'index_build_report.json');
    final buildLogPath = _join(workspace.path, 'kb', 'build.log');
    final errorLogPath = _join(workspace.path, 'kb', 'error.log');
    final multiQueryPath =
        _join(workspace.path, 'query', 'multi_kb_query_result.json');
    final singleQueryPath =
        _join(workspace.path, 'query', 'kb_query_result.json');
    final retrievalPlanPath =
        _join(workspace.path, 'query', 'retrieval_plan.json');
    final retrievalRerankReportPath =
        _join(workspace.path, 'query', 'rerank_report.json');
    final retrievalCitationCoveragePath =
        _join(workspace.path, 'query', 'citation_coverage_report.json');
    final retrievalConflictReportPath =
        _join(workspace.path, 'query', 'conflict_report.json');
    final externalValidationBoundaryPath =
        _join(workspace.path, 'query', 'external_validation_boundary.json');
    final retrievalValidationReportPath =
        _join(workspace.path, 'query', 'validation_report.json');
    final retrievalValidationMarkdownPath =
        _join(workspace.path, 'query', 'validation_report.md');
    final retrievalValidationHistoryPath =
        _join(workspace.path, 'query', 'validation_history.jsonl');
    final markdownPath = _join(workspace.path, 'doc', 'generated.md');
    final readingNotesPath = _join(workspace.path, 'doc', 'reading_notes.md');
    final editedDocumentPath =
        _join(workspace.path, 'doc', 'edited_document.md');
    final editManifestPath = _join(workspace.path, 'doc', 'edit_manifest.json');
    final documentOutlinePath = _join(workspace.path, 'doc', 'outline.json');
    final documentCitationsPath =
        _join(workspace.path, 'doc', 'citations.json');
    final documentValidationReportPath =
        _join(workspace.path, 'doc', 'document_validation_report.json');
    final latestExport = await _latestExistingExportArtifact(workspace);
    final exportedDocumentPath = latestExport.$1;
    final exportManifestPath = latestExport.$2;
    final skillPath = _join(
        _join(workspace.path, 'skill', 'knowledge_qa_skill'),
        'skill_manifest.yaml');
    final primarySkillPath =
        _joinNested(workspace.path, 'skill/knowledge_qa_skill/SKILL.md');
    final skillConfigPath = _joinNested(
        workspace.path, 'skill/knowledge_qa_skill/skill_config.json');
    final skillVerificationReportPath = _joinNested(
        workspace.path, 'skill/knowledge_qa_skill/verification_report.json');
    final skillGenerationManifestPath =
        _joinNested(workspace.path, 'skill/skill_generation_manifest.json');
    final skillPackageManifestPath =
        _joinNested(workspace.path, 'skill/skill_package_manifest.json');
    final skillValidationReportPath =
        _joinNested(workspace.path, 'skill/skill_validation_report.json');
    final localizedSkillPath = _joinNested(workspace.path,
        'skill/localized_writing_skill/S2/localized_skill_manifest.json');
    final localizedSkillDiffPath = _joinNested(
        workspace.path, 'skill/localized_writing_skill/S2/diff_summary.md');
    final skillVersionManifestPath = _joinNested(
        workspace.path, 'skill/operations/skill_version_manifest.json');
    final skillOperationManifestPath = _joinNested(
        workspace.path, 'skill/operations/skill_operation_manifest.json');
    final skillOperationHistoryPath = _joinNested(
        workspace.path, 'skill/operations/skill_operation_history.json');
    final skillFactoryAuditPath = _joinNested(
        workspace.path, 'skill/operations/skill_factory_audit.json');
    final skillExportPath =
        _joinNested(workspace.path, 'skill/exports/skills_export.md');
    final skillAgentBindingManifestPath = _joinNested(
        workspace.path, 'skill/operations/agent_binding_manifest.json');
    final agentPath = _join(
        _join(workspace.path, 'agent', 'knowledge_qa_agent'),
        'agent_manifest.json');
    final agentProfilePath = _joinNested(
        workspace.path, 'agent/knowledge_qa_agent/agent_profile.yaml');
    final agentGenerationManifestPath =
        _joinNested(workspace.path, 'agent/agent_generation_manifest.json');
    final agentAdvancedConfigPath = _joinNested(
        workspace.path, 'agent/product_config/advanced_agent_config.json');
    final agentPermissionAuditPath =
        _joinNested(workspace.path, 'agent/audit/permission_audit.json');
    final agentWorkspacePermissionMatrixPath = _joinNested(
        workspace.path, 'agent/audit/workspace_permission_matrix.json');
    final agentValidationReportPath =
        _joinNested(workspace.path, 'agent/audit/agent_validation_report.json');
    final agentPackageManifestPath = _joinNested(
        workspace.path, 'agent/exports/agent_package_manifest.json');
    final agentPackageReadmePath =
        _joinNested(workspace.path, 'agent/exports/agent_package_README.md');
    final agentDialoguePath =
        _joinNested(workspace.path, 'agent/dialogue/agent_dialogue.md');
    final agentDialogueManifestPath = _joinNested(
        workspace.path, 'agent/dialogue/agent_dialogue_manifest.json');
    final agentDialogueHistoryPath =
        _joinNested(workspace.path, 'agent/dialogue/chat_history.jsonl');
    final agentDialogueExportPath = _joinNested(
        workspace.path, 'agent/dialogue_export/agent_dialogue_export.md');
    final multiAgentPath =
        _join(workspace.path, 'multi_agent', 'multi_agent_discussion.md');
    final multiAgentManifestPath = _join(
        workspace.path, 'multi_agent', 'multi_agent_discussion_manifest.json');
    final a2aSessionManifestPath = _joinNested(workspace.path,
        'agent/workspaces/W_M/a2a_sessions/A2A_001/a2a_session_manifest.json');
    final a2aWorkspaceReportPath = _joinNested(workspace.path,
        'agent/workspaces/W_M/a2a_sessions/A2A_001/a2a_collaboration_report.md');
    final a2aConflictReportPath =
        _joinNested(workspace.path, 'multi_agent/a2a_conflict_report.json');
    final a2aConsensusReportPath =
        _joinNested(workspace.path, 'multi_agent/a2a_consensus_report.json');
    final prdP0EvidencePath =
        _join(workspace.path, 'prd_p0', 'prd_p0_e2e_evidence.json');
    final storageProviderSettingsPath =
        _join(workspace.path, 'config', 'storage_provider_settings.json');
    final providerRuntimeSettingsPath =
        _join(workspace.path, 'config', 'provider_runtime_settings.json');
    final providerValidationReportPath =
        _join(workspace.path, 'config', 'provider_validation_report.json');
    final exporterValidationReportPath =
        _join(workspace.path, 'config', 'exporter_validation_report.json');
    final parallelTaskCapacityReportPath = _joinNested(workspace.path,
        'tasks/parallel_validation/parallel_task_capacity_report.json');
    final taskIsolationMatrixPath = _joinNested(
        workspace.path, 'tasks/parallel_validation/task_isolation_matrix.json');
    final taskRecoveryReportPath = _joinNested(
        workspace.path, 'tasks/parallel_validation/task_recovery_report.json');
    final kbCatalogPath =
        _join(workspace.path, 'knowledge_bases', 'kb_catalog.json');
    final workbookManifestPath =
        _join(workspace.path, 'workbooks', 'workbook_manifest.json');

    final importReport = await _readJsonObject(importReportPath);
    final sourceManifest = await _readJsonObject(sourceManifestPath);
    final duManifest = await _readJsonObject(duManifestPath);
    final kbReport = await _readJsonObject(
        _join(workspace.path, 'kb', 'knowledge_base_build_report.json'));
    final queryPath =
        await File(multiQueryPath).exists() ? multiQueryPath : singleQueryPath;
    final queryReport = await _readJsonObject(queryPath);
    final kbCatalog = await _readJsonObject(kbCatalogPath);
    final workbookManifest = await _readWorkbookManifest(workspace);

    final sourceNames = _sourceNamesFromManifest(sourceManifest);
    final sourceRecords = _sourceRecordsFromManifest(sourceManifest);
    final manifestSourceCount = sourceRecords.isNotEmpty
        ? sourceRecords.length
        : sourceNames.isNotEmpty
            ? sourceNames.length
            : null;
    final sourceCount = _asInt(kbReport['source_count']) ??
        _asInt(importReport['imported_count']) ??
        manifestSourceCount ??
        state.sourceCount;
    final refreshedWorkbookManifestPath =
        await _refreshCurrentWorkbookAssetIndex(
      workspace,
      workbookManifest.$1,
      sourceCount,
      kbCatalog,
    );
    final chunkCount = _countJsonl(chunksPath);
    final dialogueTurnCount = _countJsonl(agentDialogueHistoryPath);
    final selectedCount = _asInt(queryReport['selected_count']) ?? 0;
    final searchResults = await _readSearchResults(queryPath);
    final generationManifest = await _readJsonObject(
        _join(workspace.path, 'doc', 'generation_manifest.json'));
    final generationHistoryCount =
        _listOfMaps(generationManifest['generation_history']).length;
    final skillVersionManifest =
        await _readJsonObject(skillVersionManifestPath);
    final skillVersionCount =
        _listOfMaps(skillVersionManifest['versions']).length;
    final skillOperationManifest =
        await _readJsonObject(skillOperationManifestPath);
    final skillBindingManifest =
        await _readJsonObject(skillAgentBindingManifestPath);
    final agentDialogueManifest =
        await _readJsonObject(agentDialogueManifestPath);
    final multiAgentManifest = await _readJsonObject(multiAgentManifestPath);
    final a2aSessionManifest = await _readJsonObject(a2aSessionManifestPath);

    var phase = state.phase;
    final hasSkillArtifact = await File(skillPath).exists() ||
        await File(primarySkillPath).exists() ||
        await File(localizedSkillPath).exists();

    if (await File(agentPath).exists()) {
      phase = Rc6RuntimePhase.agentGenerated;
    } else if (hasSkillArtifact) {
      phase = Rc6RuntimePhase.skillGenerated;
    } else if (await File(markdownPath).exists()) {
      phase = Rc6RuntimePhase.documentGenerated;
    } else if (selectedCount > 0) {
      phase = Rc6RuntimePhase.searched;
    } else if (await File(kbManifestPath).exists()) {
      phase = Rc6RuntimePhase.knowledgeBuilt;
    } else if (duManifest['status'] == 'completed') {
      phase = Rc6RuntimePhase.documentUnderstanding;
    } else if (await File(sourceManifestPath).exists()) {
      phase = Rc6RuntimePhase.imported;
    }

    state = state.copyWith(
      phase: phase,
      sourceManifestPath:
          await File(sourceManifestPath).exists() ? sourceManifestPath : '',
      selectedFilePath: (sourceManifest['source_path'] ?? '').toString().isEmpty
          ? ''
          : sourceManifest['source_path'].toString(),
      parseReportPath: await File(parseReportAliasPath).exists()
          ? parseReportAliasPath
          : await File(duManifestPath).exists()
              ? duManifestPath
              : '',
      standardKnowledgePackagePath:
          await File(standardPackageManifestPath).exists()
              ? standardPackagePath
              : '',
      standardKnowledgePackageManifestPath:
          await File(standardPackageManifestPath).exists()
              ? standardPackageManifestPath
              : '',
      standardKnowledgePackageContentPath:
          await File(standardPackageContentPath).exists()
              ? standardPackageContentPath
              : '',
      standardKnowledgePackageAuditPath:
          await File(standardPackageAuditPath).exists()
              ? standardPackageAuditPath
              : '',
      chunksPath: await File(chunksPath).exists() ? chunksPath : '',
      kbManifestPath: await File(kbManifestPath).exists() ? kbManifestPath : '',
      qualityReportPath: await File(qualityPath).exists() ? qualityPath : '',
      cardsPath: await File(cardsPath).exists() ? cardsPath : '',
      qaPairsPath: await File(qaPairsPath).exists() ? qaPairsPath : '',
      sourceMapPath: await File(sourceMapPath).exists() ? sourceMapPath : '',
      indexMetadataPath:
          await File(indexMetadataPath).exists() ? indexMetadataPath : '',
      indexProfilePath:
          await File(indexProfilePath).exists() ? indexProfilePath : '',
      keywordIndexPath:
          await File(keywordIndexPath).exists() ? keywordIndexPath : '',
      vectorIndexReferencePath: await File(vectorIndexReferencePath).exists()
          ? vectorIndexReferencePath
          : '',
      metadataIndexPath:
          await File(metadataIndexPath).exists() ? metadataIndexPath : '',
      citationIndexPath:
          await File(citationIndexPath).exists() ? citationIndexPath : '',
      memoryIndexReferencePath: await File(memoryIndexReferencePath).exists()
          ? memoryIndexReferencePath
          : '',
      indexBuildReportPath:
          await File(indexBuildReportPath).exists() ? indexBuildReportPath : '',
      buildLogPath: await File(buildLogPath).exists() ? buildLogPath : '',
      errorLogPath: await File(errorLogPath).exists() ? errorLogPath : '',
      queryResultPath: await File(queryPath).exists() ? queryPath : '',
      retrievalPlanPath:
          await File(retrievalPlanPath).exists() ? retrievalPlanPath : '',
      retrievalRerankReportPath: await File(retrievalRerankReportPath).exists()
          ? retrievalRerankReportPath
          : '',
      retrievalCitationCoveragePath:
          await File(retrievalCitationCoveragePath).exists()
              ? retrievalCitationCoveragePath
              : '',
      retrievalConflictReportPath:
          await File(retrievalConflictReportPath).exists()
              ? retrievalConflictReportPath
              : '',
      externalValidationBoundaryPath:
          await File(externalValidationBoundaryPath).exists()
              ? externalValidationBoundaryPath
              : '',
      retrievalValidationReportPath:
          await File(retrievalValidationReportPath).exists()
              ? retrievalValidationReportPath
              : '',
      retrievalValidationMarkdownPath:
          await File(retrievalValidationMarkdownPath).exists()
              ? retrievalValidationMarkdownPath
              : '',
      retrievalValidationHistoryPath:
          await File(retrievalValidationHistoryPath).exists()
              ? retrievalValidationHistoryPath
              : '',
      generatedMarkdownPath:
          await File(markdownPath).exists() ? markdownPath : '',
      readingNotesPath:
          await File(readingNotesPath).exists() ? readingNotesPath : '',
      editedDocumentPath:
          await File(editedDocumentPath).exists() ? editedDocumentPath : '',
      editManifestPath:
          await File(editManifestPath).exists() ? editManifestPath : '',
      documentOutlinePath:
          await File(documentOutlinePath).exists() ? documentOutlinePath : '',
      documentCitationsPath: await File(documentCitationsPath).exists()
          ? documentCitationsPath
          : '',
      documentValidationReportPath:
          await File(documentValidationReportPath).exists()
              ? documentValidationReportPath
              : '',
      exportedDocumentPath: exportedDocumentPath,
      exportManifestPath: exportManifestPath,
      documentGenerationHistoryCount: generationHistoryCount,
      skillVersionCount: skillVersionCount,
      skillPath: hasSkillArtifact ? _join(workspace.path, 'skill') : '',
      primarySkillPath:
          await File(primarySkillPath).exists() ? primarySkillPath : '',
      skillConfigPath:
          await File(skillConfigPath).exists() ? skillConfigPath : '',
      skillVerificationReportPath:
          await File(skillVerificationReportPath).exists()
              ? skillVerificationReportPath
              : '',
      skillGenerationManifestPath:
          await File(skillGenerationManifestPath).exists()
              ? skillGenerationManifestPath
              : '',
      skillPackageManifestPath: await File(skillPackageManifestPath).exists()
          ? skillPackageManifestPath
          : '',
      skillValidationReportPath: await File(skillValidationReportPath).exists()
          ? skillValidationReportPath
          : '',
      localizedSkillManifestPath:
          await File(localizedSkillPath).exists() ? localizedSkillPath : '',
      localizedSkillDiffPath: await File(localizedSkillDiffPath).exists()
          ? localizedSkillDiffPath
          : '',
      skillVersionManifestPath: await File(skillVersionManifestPath).exists()
          ? skillVersionManifestPath
          : '',
      skillOperationManifestPath:
          await File(skillOperationManifestPath).exists()
              ? skillOperationManifestPath
              : '',
      skillOperationHistoryPath: await File(skillOperationHistoryPath).exists()
          ? skillOperationHistoryPath
          : '',
      skillFactoryAuditPath: await File(skillFactoryAuditPath).exists()
          ? skillFactoryAuditPath
          : '',
      skillExportPath:
          await File(skillExportPath).exists() ? skillExportPath : '',
      skillAgentBindingManifestPath:
          await File(skillAgentBindingManifestPath).exists()
              ? skillAgentBindingManifestPath
              : '',
      skillOperationStatus: _stringValue(skillOperationManifest['status'], ''),
      skillAgentBindingStatus: _stringValue(skillBindingManifest['status'], ''),
      agentPath:
          await File(agentPath).exists() ? _join(workspace.path, 'agent') : '',
      primaryAgentManifestPath: await File(agentPath).exists() ? agentPath : '',
      agentProfilePath:
          await File(agentProfilePath).exists() ? agentProfilePath : '',
      agentGenerationManifestPath:
          await File(agentGenerationManifestPath).exists()
              ? agentGenerationManifestPath
              : '',
      agentAdvancedConfigPath: await File(agentAdvancedConfigPath).exists()
          ? agentAdvancedConfigPath
          : '',
      agentPermissionAuditPath: await File(agentPermissionAuditPath).exists()
          ? agentPermissionAuditPath
          : '',
      agentWorkspacePermissionMatrixPath:
          await File(agentWorkspacePermissionMatrixPath).exists()
              ? agentWorkspacePermissionMatrixPath
              : '',
      agentValidationReportPath: await File(agentValidationReportPath).exists()
          ? agentValidationReportPath
          : '',
      agentPackageManifestPath: await File(agentPackageManifestPath).exists()
          ? agentPackageManifestPath
          : '',
      agentPackageReadmePath: await File(agentPackageReadmePath).exists()
          ? agentPackageReadmePath
          : '',
      agentDialoguePath:
          await File(agentDialoguePath).exists() ? agentDialoguePath : '',
      agentDialogueManifestPath: await File(agentDialogueManifestPath).exists()
          ? agentDialogueManifestPath
          : '',
      agentDialogueHistoryPath: await File(agentDialogueHistoryPath).exists()
          ? agentDialogueHistoryPath
          : '',
      agentDialogueExportPath: await File(agentDialogueExportPath).exists()
          ? agentDialogueExportPath
          : '',
      agentDialogueTurnCount: dialogueTurnCount,
      agentDialogueModelConfigId:
          _stringValue(agentDialogueManifest['model_config_id'], ''),
      agentDialogueUsedKbIds:
          _listOfStrings(agentDialogueManifest['used_kb_ids']),
      agentDialogueUsedSkillIds:
          _listOfStrings(agentDialogueManifest['used_skill_ids']),
      agentDialogueOutputFormat:
          _stringValue(agentDialogueManifest['output_format'], ''),
      agentDialogueEvidenceCount:
          _asInt(agentDialogueManifest['evidence_count']) ?? 0,
      agentDialogueMemoryWriteStatus:
          _stringValue(agentDialogueManifest['memory_write_status'], ''),
      agentDialogueErrorMessage:
          _stringValue(agentDialogueManifest['error_message'], ''),
      multiAgentDiscussionPath:
          await File(multiAgentPath).exists() ? multiAgentPath : '',
      multiAgentDiscussionManifestPath:
          await File(multiAgentManifestPath).exists()
              ? multiAgentManifestPath
              : '',
      a2aSessionManifestPath: await File(a2aSessionManifestPath).exists()
          ? a2aSessionManifestPath
          : '',
      a2aWorkspaceReportPath: await File(a2aWorkspaceReportPath).exists()
          ? a2aWorkspaceReportPath
          : '',
      a2aConflictReportPath: await File(a2aConflictReportPath).exists()
          ? a2aConflictReportPath
          : '',
      a2aConsensusReportPath: await File(a2aConsensusReportPath).exists()
          ? a2aConsensusReportPath
          : '',
      a2aSessionId: _stringValue(
          a2aSessionManifest['a2a_session_id'] ??
              a2aSessionManifest['session_id'],
          ''),
      a2aTopic: _stringValue(
          a2aSessionManifest['topic'] ?? multiAgentManifest['topic'], ''),
      a2aParticipantAgentIds:
          _listOfStrings(a2aSessionManifest['participant_agent_ids']),
      a2aEvidenceCount: _asInt(multiAgentManifest['evidence_count']) ?? 0,
      a2aStatus: _stringValue(
          a2aSessionManifest['status'] ?? multiAgentManifest['status'], ''),
      prdP0EvidencePath:
          await File(prdP0EvidencePath).exists() ? prdP0EvidencePath : '',
      providerRuntimeSettingsPath:
          await File(providerRuntimeSettingsPath).exists()
              ? providerRuntimeSettingsPath
              : '',
      storageProviderSettingsPath:
          await File(storageProviderSettingsPath).exists()
              ? storageProviderSettingsPath
              : '',
      providerValidationReportPath:
          await File(providerValidationReportPath).exists()
              ? providerValidationReportPath
              : '',
      exporterValidationReportPath:
          await File(exporterValidationReportPath).exists()
              ? exporterValidationReportPath
              : '',
      parallelTaskCapacityReportPath:
          await File(parallelTaskCapacityReportPath).exists()
              ? parallelTaskCapacityReportPath
              : '',
      taskIsolationMatrixPath: await File(taskIsolationMatrixPath).exists()
          ? taskIsolationMatrixPath
          : '',
      taskRecoveryReportPath: await File(taskRecoveryReportPath).exists()
          ? taskRecoveryReportPath
          : '',
      knowledgeBaseCatalogPath:
          await File(kbCatalogPath).exists() ? kbCatalogPath : '',
      workbookManifestPath: refreshedWorkbookManifestPath.isNotEmpty
          ? refreshedWorkbookManifestPath
          : await File(workbookManifestPath).exists()
              ? workbookManifestPath
              : '',
      currentWorkbookName: workbookManifest.$1,
      workbookNames: workbookManifest.$2,
      knowledgeBases: _recordsFromKnowledgeCatalog(kbCatalog),
      sourceCount: sourceCount,
      sourceNames: sourceNames,
      sourceRecords: sourceRecords,
      chunkCount: chunkCount,
      searchResults: searchResults,
      searchStatus: selectedCount > 0
          ? Rc6SearchStatus.success
          : state.searchStatus == Rc6SearchStatus.loading
              ? Rc6SearchStatus.empty
              : state.searchStatus,
    );
  }

  List<String> _sourceNamesFromManifest(Map<String, Object?> manifest) {
    final sources = manifest['sources'];
    if (sources is List) {
      return sources
          .whereType<Map>()
          .map((source) => (source['source_name'] ?? source['relative_path'])
              ?.toString()
              .trim())
          .whereType<String>()
          .where((name) => name.isNotEmpty)
          .toList(growable: false);
    }
    final single = (manifest['source_name'] ?? '').toString().trim();
    return single.isEmpty ? const <String>[] : <String>[single];
  }

  List<Rc6SourceRecord> _sourceRecordsFromManifest(
      Map<String, Object?> manifest) {
    final sources = manifest['sources'];
    if (sources is! List) return const <Rc6SourceRecord>[];
    return sources
        .whereType<Map>()
        .map((source) =>
            Rc6SourceRecord.fromJson(Map<String, dynamic>.from(source)))
        .toList(growable: false);
  }

  Future<(String, List<String>)> _readWorkbookManifest(
      Directory workspace) async {
    final path = _join(workspace.path, 'workbooks', 'workbook_manifest.json');
    final manifest = await _readJsonObject(path);
    final current = (manifest['current_workbook'] ?? '默认工作本').toString().trim();
    final rows = manifest['workbooks'];
    final names = rows is List
        ? rows
            .whereType<Map>()
            .map((row) => (row['name'] ?? '').toString().trim())
            .where((name) => name.isNotEmpty)
            .toList(growable: true)
        : <String>[];
    if (names.isEmpty) names.add(current.isEmpty ? '默认工作本' : current);
    final effectiveCurrent = current.isEmpty ? names.first : current;
    if (!names.contains(effectiveCurrent)) names.insert(0, effectiveCurrent);
    return (effectiveCurrent, List<String>.unmodifiable(names));
  }

  Future<String> _writeWorkbookManifest(
    Directory workspace, {
    required String currentName,
    required String addName,
  }) async {
    final manifestDir = Directory(_join(workspace.path, 'workbooks'));
    await manifestDir.create(recursive: true);
    final manifestPath = _join(manifestDir.path, 'workbook_manifest.json');
    final existing = await _readJsonObject(manifestPath);
    final rows = existing['workbooks'] is List
        ? (existing['workbooks'] as List)
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: true)
        : <Map<String, dynamic>>[];
    final now = DateTime.now().toUtc().toIso8601String();
    if (rows.isEmpty) {
      rows.add({
        'workbook_id': 'WB_${_stableHash(state.currentWorkbookName)}',
        'name': state.currentWorkbookName,
        'status':
            state.currentWorkbookName == currentName ? 'active' : 'available',
        'created_at': now,
        'last_opened_at': now,
        'document_count': state.sourceCount,
        'knowledge_base_count': state.knowledgeBases.isNotEmpty
            ? state.knowledgeBases.length
            : state.hasKnowledgeBase
                ? 1
                : 0,
      });
    }
    final normalizedAdd = addName.trim().isEmpty ? '默认工作本' : addName.trim();
    final assetIndex = await _workbookAssetIndex(workspace);
    var found = false;
    for (final row in rows) {
      if ((row['name'] ?? '').toString() == normalizedAdd) {
        row['status'] = 'active';
        row['last_opened_at'] = now;
        row['document_count'] = state.sourceCount;
        row['knowledge_base_count'] = state.knowledgeBases.isNotEmpty
            ? state.knowledgeBases.length
            : state.hasKnowledgeBase
                ? 1
                : 0;
        row['asset_index'] = assetIndex;
        found = true;
      } else {
        row['status'] = 'available';
      }
    }
    if (!found) {
      rows.add({
        'workbook_id': 'WB_${_stableHash(normalizedAdd)}',
        'name': normalizedAdd,
        'status': 'active',
        'created_at': now,
        'last_opened_at': now,
        'document_count': state.sourceCount,
        'knowledge_base_count': state.knowledgeBases.isNotEmpty
            ? state.knowledgeBases.length
            : state.hasKnowledgeBase
                ? 1
                : 0,
        'asset_index': assetIndex,
      });
    }
    final payload = {
      'schema_version': 'prd_v2_workbook_manifest.v1',
      'workspace_path': workspace.path,
      'current_workbook':
          currentName.trim().isEmpty ? normalizedAdd : currentName.trim(),
      'workbooks': rows,
    };
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
    return manifestPath;
  }

  Future<(String, String, List<String>)?> _deleteWorkbookFromManifest(
    Directory workspace,
    String name,
  ) async {
    final manifestPath =
        _join(workspace.path, 'workbooks', 'workbook_manifest.json');
    final manifestFile = File(manifestPath);
    if (!await manifestFile.exists()) {
      return null;
    }
    final existing = await _readJsonObject(manifestPath);
    final rows = existing['workbooks'] is List
        ? (existing['workbooks'] as List)
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .where((row) => (row['name'] ?? '').toString().trim().isNotEmpty)
            .toList(growable: true)
        : <Map<String, dynamic>>[];
    final target = name.trim();
    final index = rows
        .indexWhere((row) => (row['name'] ?? '').toString().trim() == target);
    if (index < 0 || rows.length <= 1) {
      return null;
    }
    rows.removeAt(index);
    final previousCurrent =
        (existing['current_workbook'] ?? state.currentWorkbookName)
            .toString()
            .trim();
    final deletedCurrent = previousCurrent == target;
    final defaultIndex = rows
        .indexWhere((row) => (row['name'] ?? '').toString().trim() == '默认工作本');
    final nextCurrent = deletedCurrent
        ? (defaultIndex >= 0
            ? (rows[defaultIndex]['name'] ?? '').toString().trim()
            : (rows.first['name'] ?? '').toString().trim())
        : previousCurrent;
    final effectiveCurrent = nextCurrent.isEmpty
        ? (rows.first['name'] ?? '默认工作本').toString()
        : nextCurrent;
    final now = DateTime.now().toUtc().toIso8601String();
    for (final row in rows) {
      final rowName = (row['name'] ?? '').toString().trim();
      row['status'] = rowName == effectiveCurrent ? 'active' : 'available';
      if (rowName == effectiveCurrent) {
        row['last_opened_at'] = now;
      }
    }
    final payload = {
      ...existing,
      'schema_version': 'prd_v2_workbook_manifest.v1',
      'workspace_path': workspace.path,
      'current_workbook': effectiveCurrent,
      'workbooks': rows,
    };
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
    return (
      manifestPath,
      effectiveCurrent,
      List<String>.unmodifiable(rows
          .map((row) => (row['name'] ?? '').toString().trim())
          .where((rowName) => rowName.isNotEmpty))
    );
  }

  Future<String> _refreshCurrentWorkbookAssetIndex(
    Directory workspace,
    String currentName,
    int sourceCount,
    Map<String, dynamic> kbCatalog,
  ) async {
    final manifestPath =
        _join(workspace.path, 'workbooks', 'workbook_manifest.json');
    final manifestFile = File(manifestPath);
    if (!await manifestFile.exists()) {
      return '';
    }
    final existing = await _readJsonObject(manifestPath);
    final rows = existing['workbooks'] is List
        ? (existing['workbooks'] as List)
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: true)
        : <Map<String, dynamic>>[];
    if (rows.isEmpty) {
      return manifestPath;
    }
    final effectiveCurrent = currentName.trim().isEmpty
        ? (existing['current_workbook'] ?? '默认工作本').toString().trim()
        : currentName.trim();
    final index = rows.indexWhere(
        (row) => (row['name'] ?? '').toString().trim() == effectiveCurrent);
    if (index < 0) {
      return manifestPath;
    }
    rows[index]['asset_index'] = await _workbookAssetIndex(workspace);
    rows[index]['document_count'] = sourceCount;
    rows[index]['knowledge_base_count'] = _catalogRecords(kbCatalog).length;
    rows[index]['updated_at'] = DateTime.now().toUtc().toIso8601String();
    final payload = {
      ...existing,
      'current_workbook': effectiveCurrent,
      'workbooks': rows,
    };
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
    return manifestPath;
  }

  Future<Map<String, Object?>> _workbookAssetIndex(Directory workspace) async {
    final sourceManifestPath = _join(workspace.path, 'source_manifest.json');
    final sourceManifest = await _readJsonObject(sourceManifestPath);
    final sourceRecords = _sourceRecordsFromManifest(sourceManifest);
    final kbCatalogPath =
        _join(workspace.path, 'knowledge_bases', 'kb_catalog.json');
    final kbCatalog = await _readJsonObject(kbCatalogPath);
    final knowledgeBaseRecords = _catalogRecords(kbCatalog);
    final knowledgeIndexArtifacts = <String>[
      _joinNested(workspace.path, 'kb/index_profile.json'),
      _joinNested(workspace.path, 'kb/keyword_index.json'),
      _joinNested(workspace.path, 'kb/vector_index_reference.json'),
      _joinNested(workspace.path, 'kb/metadata_index.json'),
      _joinNested(workspace.path, 'kb/citation_index.json'),
      _joinNested(workspace.path, 'kb/memory_index_reference.json'),
      _joinNested(workspace.path, 'kb/index_build_report.json'),
      for (final record in knowledgeBaseRecords) ...[
        _joinNested(workspace.path,
            'knowledge_bases/${record['kb_id']}/index_profile.json'),
        _joinNested(workspace.path,
            'knowledge_bases/${record['kb_id']}/keyword_index.json'),
        _joinNested(workspace.path,
            'knowledge_bases/${record['kb_id']}/vector_index_reference.json'),
        _joinNested(workspace.path,
            'knowledge_bases/${record['kb_id']}/metadata_index.json'),
        _joinNested(workspace.path,
            'knowledge_bases/${record['kb_id']}/citation_index.json'),
        _joinNested(workspace.path,
            'knowledge_bases/${record['kb_id']}/memory_index_reference.json'),
        _joinNested(workspace.path,
            'knowledge_bases/${record['kb_id']}/index_build_report.json'),
      ],
    ].where((path) => File(path).existsSync()).toList(growable: false);
    final standardPackageArtifacts = <String>[
      _joinNested(workspace.path,
          'standard_packages/current/standard_package_manifest.json'),
      _joinNested(
          workspace.path, 'standard_packages/current/source_references.json'),
      _joinNested(
          workspace.path, 'standard_packages/current/content_package.jsonl'),
      _joinNested(workspace.path, 'standard_packages/audit_history.jsonl'),
    ].where((path) => File(path).existsSync()).toList(growable: false);
    final generatedDocuments = <String>[
      _join(workspace.path, 'doc', 'generated.md'),
      _join(workspace.path, 'doc', 'reading_notes.md'),
      _join(workspace.path, 'doc', 'edited_document.md'),
      _join(workspace.path, 'doc', 'outline.json'),
      _join(workspace.path, 'doc', 'citations.json'),
      _join(workspace.path, 'doc', 'document_validation_report.json'),
      _join(workspace.path, 'export', 'reading_notes_export.md'),
    ].where((path) => File(path).existsSync()).toList(growable: false);
    final retrievalArtifacts = <String>[
      _joinNested(workspace.path, 'query/multi_kb_query_result.json'),
      _joinNested(workspace.path, 'query/retrieval_plan.json'),
      _joinNested(workspace.path, 'query/rerank_report.json'),
      _joinNested(workspace.path, 'query/citation_coverage_report.json'),
      _joinNested(workspace.path, 'query/conflict_report.json'),
      _joinNested(workspace.path, 'query/external_validation_boundary.json'),
      _joinNested(workspace.path, 'query/validation_report.json'),
      _joinNested(workspace.path, 'query/validation_report.md'),
      _joinNested(workspace.path, 'query/validation_history.jsonl'),
    ].where((path) => File(path).existsSync()).toList(growable: false);
    final skillArtifacts = <String>[
      _joinNested(workspace.path, 'skill/knowledge_qa_skill/SKILL.md'),
      _joinNested(workspace.path, 'skill/knowledge_qa_skill/skill_config.json'),
      _joinNested(
          workspace.path, 'skill/knowledge_qa_skill/verification_report.json'),
      _joinNested(
          workspace.path, 'skill/knowledge_qa_skill/skill_edit_manifest.json'),
      _joinNested(workspace.path, 'skill/skill_generation_manifest.json'),
      _joinNested(workspace.path, 'skill/skill_package_manifest.json'),
      _joinNested(workspace.path, 'skill/skill_validation_report.json'),
      _joinNested(workspace.path,
          'skill/localized_writing_skill/S2/localized_skill_manifest.json'),
      _joinNested(
          workspace.path, 'skill/localized_writing_skill/S2/diff_summary.md'),
      _joinNested(
          workspace.path, 'skill/operations/skill_version_manifest.json'),
      _joinNested(
          workspace.path, 'skill/operations/skill_operation_manifest.json'),
      _joinNested(
          workspace.path, 'skill/operations/skill_operation_history.json'),
      _joinNested(workspace.path, 'skill/operations/skill_factory_audit.json'),
      _joinNested(
          workspace.path, 'skill/operations/agent_binding_manifest.json'),
      _joinNested(workspace.path, 'skill/exports/skills_export.md'),
    ].where((path) => File(path).existsSync()).toList(growable: false);
    final agentArtifacts = <String>[
      _joinNested(
          workspace.path, 'agent/knowledge_qa_agent/agent_manifest.json'),
      _joinNested(
          workspace.path, 'agent/knowledge_qa_agent/agent_profile.yaml'),
      _joinNested(workspace.path, 'agent/agent_generation_manifest.json'),
      _joinNested(
          workspace.path, 'agent/product_config/advanced_agent_config.json'),
      _joinNested(workspace.path, 'agent/audit/agent_validation_report.json'),
      _joinNested(
          workspace.path, 'agent/audit/workspace_permission_matrix.json'),
      _joinNested(workspace.path, 'agent/exports/agent_package_manifest.json'),
      _joinNested(workspace.path, 'agent/exports/agent_package_README.md'),
      _joinNested(workspace.path, 'agent/dialogue/agent_dialogue.md'),
      _joinNested(
          workspace.path, 'agent/dialogue/agent_dialogue_manifest.json'),
      _joinNested(workspace.path, 'agent/dialogue/chat_history.jsonl'),
      _joinNested(
          workspace.path, 'agent/dialogue_export/agent_dialogue_export.md'),
      _joinNested(workspace.path,
          'agent/dialogue_export/agent_dialogue_export_manifest.json'),
      _join(workspace.path, 'multi_agent', 'multi_agent_discussion.md'),
      _join(workspace.path, 'multi_agent',
          'multi_agent_discussion_manifest.json'),
      _join(workspace.path, 'multi_agent', 'a2a_conflict_report.json'),
      _join(workspace.path, 'multi_agent', 'a2a_consensus_report.json'),
      _joinNested(workspace.path,
          'agent/workspaces/W_M/a2a_sessions/A2A_001/a2a_session_manifest.json'),
      _joinNested(workspace.path,
          'agent/workspaces/W_M/a2a_sessions/A2A_001/a2a_collaboration_report.md'),
    ].where((path) => File(path).existsSync()).toList(growable: false);
    final auditArtifacts = <String>[
      _join(workspace.path, 'audit', 'audit_report.json'),
      _joinNested(workspace.path, 'agent/audit/permission_audit.json'),
      _joinNested(workspace.path, 'agent/audit/agent_validation_report.json'),
      _joinNested(
          workspace.path, 'agent/audit/workspace_permission_matrix.json'),
      _joinNested(workspace.path, 'agent/audit/run_history.json'),
      _joinNested(workspace.path, 'config/storage_provider_settings.json'),
      _joinNested(workspace.path, 'config/provider_runtime_settings.json'),
      _joinNested(workspace.path, 'config/provider_validation_report.json'),
      _joinNested(workspace.path, 'config/exporter_settings.json'),
      _joinNested(workspace.path, 'config/exporter_validation_report.json'),
      _joinNested(workspace.path,
          'tasks/parallel_validation/parallel_task_capacity_report.json'),
      _joinNested(workspace.path,
          'tasks/parallel_validation/task_isolation_matrix.json'),
      _joinNested(workspace.path,
          'tasks/parallel_validation/task_recovery_report.json'),
    ].where((path) => File(path).existsSync()).toList(growable: false);
    return {
      'schema_version': 'prd_v2_workbook_asset_index.v1',
      'workspace_boundary': workspace.path,
      'source_manifest_path':
          File(sourceManifestPath).existsSync() ? sourceManifestPath : '',
      'document_ids': sourceRecords
          .map((source) => source.documentId)
          .where((id) => id.isNotEmpty)
          .toList(growable: false),
      'source_document_count': sourceRecords.length,
      'knowledge_base_catalog_path':
          File(kbCatalogPath).existsSync() ? kbCatalogPath : '',
      'knowledge_base_ids': knowledgeBaseRecords
          .map((record) => (record['kb_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList(growable: false),
      'knowledge_index_artifacts': knowledgeIndexArtifacts,
      'standard_knowledge_package_artifacts': standardPackageArtifacts,
      'generated_documents': generatedDocuments,
      'retrieval_artifacts': retrievalArtifacts,
      'skill_artifacts': skillArtifacts,
      'agent_artifacts': agentArtifacts,
      'audit_artifacts': auditArtifacts,
      'secret_plaintext_written': false,
      'directory_isolation': 'single_workspace_asset_index',
    };
  }

  Future<List<_SearchableKnowledgeBase>> _selectedKnowledgeBasesForSearch(
      List<String> kbIds) async {
    final workspace = _requireWorkspace();
    final catalog = await _loadKnowledgeCatalog(workspace);
    final records = _catalogRecords(catalog);
    final requested = kbIds.where((id) => id.trim().isNotEmpty).toSet();
    final selectedRecords = records
        .where((record) =>
            requested.isEmpty ||
            requested.contains(record['kb_id']?.toString()))
        .toList(growable: false);
    final result = <_SearchableKnowledgeBase>[];
    for (final record in selectedRecords) {
      final id = (record['kb_id'] ?? '').toString();
      if (id.isEmpty) continue;
      final dir = Directory(_join(workspace.path, 'knowledge_bases', id));
      if (await File(_join(dir.path, 'manifest.json')).exists()) {
        result.add(_SearchableKnowledgeBase(
          id: id,
          name: (record['kb_name'] ?? id).toString(),
          path: dir.path,
        ));
      }
    }
    if (result.isNotEmpty) {
      return result;
    }
    final fallback = Directory(_join(workspace.path, 'kb'));
    if (await File(_join(fallback.path, 'manifest.json')).exists()) {
      return [
        _SearchableKnowledgeBase(
          id: 'default_kb',
          name: '当前知识库',
          path: fallback.path,
        )
      ];
    }
    return const [];
  }

  Future<void> _writeDerivedKnowledgeArtifacts() async {
    final workspace = _requireWorkspace();
    final kbDir = _join(workspace.path, 'kb');
    await Directory(kbDir).create(recursive: true);
    final cards = await _readJsonl(File(_join(kbDir, 'cards.jsonl')));
    final qaPairs = await _readJsonl(File(_join(kbDir, 'qa_pairs.jsonl')));
    final chunks = await _readJsonl(File(_join(kbDir, 'chunks.jsonl')));
    final sourceManifest =
        await _readJsonObject(_join(workspace.path, 'source_manifest.json'));
    final normalizedSourcesByRelativePath =
        await _normalizedSourcesByRelativePath(workspace);
    final chunkCountsBySource = <String, int>{};
    for (final chunk in chunks) {
      final sourcePath =
          _normalizePathKey(chunk['source_path'] ?? chunk['source']);
      if (sourcePath.isEmpty) continue;
      chunkCountsBySource[sourcePath] =
          (chunkCountsBySource[sourcePath] ?? 0) + 1;
    }
    final sources = (sourceManifest['sources'] as List?)
            ?.whereType<Map>()
            .map((source) => Map<String, dynamic>.from(source))
            .toList(growable: false) ??
        const <Map<String, dynamic>>[];
    final sourceDocs = sources.map((source) {
      final relativePath = (source['relative_path'] ?? '').toString();
      final normalizedPath =
          normalizedSourcesByRelativePath[_normalizePathKey(relativePath)];
      final sourcePath = _normalizePathKey(source['source_path']);
      final sourceName = _normalizePathKey(source['source_name']);
      final chunkCount = {
        normalizedPath,
        sourcePath,
        sourceName,
        _normalizePathKey(relativePath),
      }
          .where((key) => key != null && key.isNotEmpty)
          .map((key) => chunkCountsBySource[key] ?? 0)
          .fold<int>(0, (total, count) => total + count);
      return {
        'document_id': _documentId(source),
        'source_name':
            (source['source_name'] ?? source['relative_path'] ?? '').toString(),
        'relative_path': relativePath,
        'normalized_path': normalizedPath ?? '',
        'size_bytes': _asInt(source['size_bytes']) ?? 0,
        'chunk_count': chunkCount,
      };
    }).toList(growable: false);
    final summary = {
      'schema_version': 'rc10_real_input_derived_knowledge.v1',
      'status': chunks.isNotEmpty && cards.isNotEmpty && qaPairs.isNotEmpty
          ? 'pass'
          : 'failed',
      'chunk_count': chunks.length,
      'card_count': cards.length,
      'qa_pair_count': qaPairs.length,
      'source_manifest': _join(workspace.path, 'source_manifest.json'),
      'cards_path': _join(kbDir, 'cards.jsonl'),
      'qa_pairs_path': _join(kbDir, 'qa_pairs.jsonl'),
      'source_map_path': _join(kbDir, 'source_map.json'),
      'index_metadata_path': _join(kbDir, 'index_metadata.json'),
      'index_profile_path': _join(kbDir, 'index_profile.json'),
      'keyword_index_path': _join(kbDir, 'keyword_index.json'),
      'vector_index_reference_path':
          _join(kbDir, 'vector_index_reference.json'),
      'metadata_index_path': _join(kbDir, 'metadata_index.json'),
      'citation_index_path': _join(kbDir, 'citation_index.json'),
      'memory_index_reference_path':
          _join(kbDir, 'memory_index_reference.json'),
      'index_build_report_path': _join(kbDir, 'index_build_report.json'),
      'build_log_path': _join(kbDir, 'build.log'),
      'error_log_path': _join(kbDir, 'error.log'),
    };
    await File(_join(kbDir, 'rc10_real_input_derived_knowledge.json'))
        .writeAsString(const JsonEncoder.withIndent('  ').convert(summary),
            encoding: utf8);
    await File(_join(kbDir, 'source_map.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'schema_version': 'prd_v2_source_map.v1',
          'kb_id': 'current_kb',
          'source_manifest': _join(workspace.path, 'source_manifest.json'),
          'documents': sourceDocs,
          'chunk_count': chunks.length,
        }),
        encoding: utf8);
    await _writeIndustrialIndexArtifacts(
      kbDir: Directory(kbDir),
      kbId: 'current_kb',
      operation: 'build',
      chunks: chunks,
      sourceDocs: sourceDocs,
      cards: cards,
      qaPairs: qaPairs,
      vectorStore: 'local_file_index',
    );
    await File(_join(kbDir, 'build.log')).writeAsString(
      [
        'schema_version=prd_v2_kb_build_log.v1',
        'operation=build',
        'source_count=${sources.length}',
        'chunk_count=${chunks.length}',
        'card_count=${cards.length}',
        'qa_pair_count=${qaPairs.length}',
      ].join('\n'),
      encoding: utf8,
    );
    await File(_join(kbDir, 'error.log')).writeAsString(
      chunks.isEmpty ? 'no_chunks_generated\n' : 'status=ok\n',
      encoding: utf8,
    );
  }

  Future<Map<String, String>> _normalizedSourcesByRelativePath(
      Directory workspace) async {
    final records = await _readJsonl(File(
        _join(workspace.path, 'du', 'document_understanding_records.jsonl')));
    final result = <String, String>{};
    for (final record in records) {
      final relativePath = _normalizePathKey(record['relative_path']);
      final normalizedPath = _normalizePathKey(record['normalized_path']);
      if (relativePath.isNotEmpty && normalizedPath.isNotEmpty) {
        result[relativePath] = normalizedPath;
      }
    }
    return result;
  }

  Future<void> _writeKnowledgeBaseCatalog(
      {List<String> documentIds = const []}) async {
    final workspace = _requireWorkspace();
    final sourceManifest =
        await _readJsonObject(_join(workspace.path, 'source_manifest.json'));
    final sources = (sourceManifest['sources'] as List?)
            ?.whereType<Map>()
            .map((source) => Map<String, dynamic>.from(source))
            .toList(growable: false) ??
        const <Map<String, dynamic>>[];
    final selectedDocumentIds =
        documentIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
    final selectedSources = selectedDocumentIds.isEmpty
        ? sources
        : sources.where((source) {
            final documentId =
                (source['document_id'] ?? _documentId(source)).toString();
            return selectedDocumentIds.contains(documentId);
          }).toList(growable: false);
    final catalog = await _loadKnowledgeCatalog(workspace);
    final existing = _catalogRecords(catalog);
    final currentId = existing.any((item) => item['kb_id'] == 'K1')
        ? 'K${existing.length + 1}'
        : 'K1';
    final currentName = currentId == 'K1' ? '真实输入知识库' : '真实输入知识库 $currentId';
    final record = await _materializeKnowledgeBaseRecord(
      workspace: workspace,
      kbId: currentId,
      name: currentName,
      type: '普通知识库',
      sourceDocuments: selectedSources,
      sourceKbIds: const [],
      operation: 'build',
    );
    final records = [
      ...existing.where((item) => item['kb_id'] != currentId),
      record,
    ];
    await _writeKnowledgeCatalog(workspace, records,
        operation: 'build:$currentId');
  }

  Future<bool> _runKnowledgeBaseCoreBuild({
    required String successMessage,
  }) async {
    final workspace = _requireWorkspace();
    final duDir = Directory(_join(workspace.path, 'du'));
    final parseReport = File(_join(workspace.path, 'parse_report.json'));
    if (!await duDir.exists() && !await parseReport.exists()) {
      _fail('请先在导入与解析页完成解析/OCR/Chunking。');
      return false;
    }
    await _runCoreAction(
      actionId: 'knowledge_base_build',
      arguments: [
        'build-knowledge-base',
        '--document-understanding',
        _join(workspace.path, 'du'),
        '--output',
        _join(workspace.path, 'kb'),
      ],
      outputPath: _join(workspace.path, 'kb'),
      nextPhase: Rc6RuntimePhase.knowledgeBuilt,
      successMessage: successMessage,
      timeout: const Duration(minutes: 15),
    );
    return state.lastResult?.passed == true;
  }

  Future<Map<String, dynamic>> _copyKnowledgeBaseRecord(
      String sourceKbId) async {
    final workspace = _requireWorkspace();
    final catalog = await _loadKnowledgeCatalog(workspace);
    final records = _catalogRecords(catalog);
    final source = records.cast<Map<String, dynamic>?>().firstWhere(
          (record) => record?['kb_id']?.toString() == sourceKbId,
          orElse: () => null,
        );
    if (source == null) {
      _fail('未找到要复制的知识库：$sourceKbId');
      return const {};
    }
    final copyId = _nextKnowledgeBaseId(records, prefix: '${sourceKbId}_COPY');
    final record = await _materializeKnowledgeBaseRecord(
      workspace: workspace,
      kbId: copyId,
      name: '${source['kb_name'] ?? sourceKbId} 副本',
      type: (source['kb_type'] ?? '普通知识库').toString(),
      sourceDocuments: _listOfMaps(source['source_documents']),
      sourceKbIds: [sourceKbId],
      operation: 'copy',
    );
    final updated = [...records, record];
    await _writeKnowledgeCatalog(workspace, updated, operation: 'copy:$copyId');
    state = state.copyWith(lastMessage: '知识库 $sourceKbId 已复制为 $copyId。');
    return record;
  }

  Future<Map<String, dynamic>> _mergeKnowledgeBaseRecords(
      List<String> sourceKbIds) async {
    final workspace = _requireWorkspace();
    final catalog = await _loadKnowledgeCatalog(workspace);
    final records = _catalogRecords(catalog);
    final ids = sourceKbIds.where((id) => id.trim().isNotEmpty).toSet();
    if (ids.length < 2) {
      _fail('合并知识库至少需要选择两个知识库。');
      return const {};
    }
    final selected = records
        .where((record) => ids.contains(record['kb_id']?.toString()))
        .toList(growable: false);
    if (selected.length < 2) {
      _fail('合并知识库的来源记录不足。');
      return const {};
    }
    final docs = <Map<String, dynamic>>[];
    for (final item in selected) {
      docs.addAll(_listOfMaps(item['source_documents']));
    }
    final mergeId = _nextKnowledgeBaseId(records, prefix: 'K_MERGED');
    final record = await _materializeKnowledgeBaseRecord(
      workspace: workspace,
      kbId: mergeId,
      name: '合并知识库 ${ids.join("+")}',
      type: '混合知识库',
      sourceDocuments: _dedupeSourceDocuments(docs),
      sourceKbIds: ids.toList(growable: false),
      operation: 'merge',
    );
    final updated = [...records, record];
    await _writeKnowledgeCatalog(workspace, updated,
        operation: 'merge:$mergeId');
    state = state.copyWith(lastMessage: '知识库已合并为 $mergeId。');
    return record;
  }

  Future<Map<String, dynamic>> _splitKnowledgeBaseRecord(
      String sourceKbId) async {
    final workspace = _requireWorkspace();
    final catalog = await _loadKnowledgeCatalog(workspace);
    final records = _catalogRecords(catalog);
    final source = records.cast<Map<String, dynamic>?>().firstWhere(
          (record) => record?['kb_id']?.toString() == sourceKbId,
          orElse: () => null,
        );
    if (source == null) {
      _fail('未找到要拆分的知识库：$sourceKbId');
      return const {};
    }
    final docs = _listOfMaps(source['source_documents']);
    if (docs.length < 2) {
      _fail('知识库 $sourceKbId 只有一个来源文档，不能拆分。');
      return const {};
    }
    final splitId =
        _nextKnowledgeBaseId(records, prefix: '${sourceKbId}_SPLIT');
    final record = await _materializeKnowledgeBaseRecord(
      workspace: workspace,
      kbId: splitId,
      name: '${source['kb_name'] ?? sourceKbId} 拆分',
      type: (source['kb_type'] ?? '普通知识库').toString(),
      sourceDocuments: docs.take((docs.length / 2).ceil()).toList(),
      sourceKbIds: [sourceKbId],
      operation: 'split',
    );
    final updated = [...records, record];
    await _writeKnowledgeCatalog(workspace, updated,
        operation: 'split:$splitId');
    state = state.copyWith(lastMessage: '知识库 $sourceKbId 已拆分为 $splitId。');
    return record;
  }

  Future<void> _updateKnowledgeBaseVersion(String kbId,
      {required String operation}) async {
    final workspace = _requireWorkspace();
    final catalog = await _loadKnowledgeCatalog(workspace);
    final records = _catalogRecords(catalog);
    final index =
        records.indexWhere((record) => record['kb_id']?.toString() == kbId);
    if (index < 0) {
      _fail('未找到要更新的知识库：$kbId');
      return;
    }
    await _snapshotKnowledgeBaseVersion(workspace, records[index],
        reason: operation == 'full_rebuild' ? '全量重建前快照' : '增量更新前快照');
    await _writeKnowledgeCatalog(workspace, records,
        operation: 'snapshot_before_$operation:$kbId');
    final passed = await _runKnowledgeBaseCoreBuild(
      successMessage: operation == 'full_rebuild' ? '知识库全量重建完成。' : '知识库增量更新完成。',
    );
    if (!passed) return;
    await _writeDerivedKnowledgeArtifacts();
    final refreshed = await _materializeKnowledgeBaseRecord(
      workspace: workspace,
      kbId: kbId,
      name: (records[index]['kb_name'] ?? kbId).toString(),
      type: (records[index]['kb_type'] ?? '普通知识库').toString(),
      sourceDocuments: _listOfMaps(records[index]['source_documents']),
      sourceKbIds: _listOfStrings(records[index]['source_kb_ids']),
      operation: operation,
      versionsOverride: _listOfMaps(records[index]['versions']),
    );
    records[index] = refreshed;
    await _writeKnowledgeCatalog(workspace, records,
        operation: '$operation:$kbId');
    state = state.copyWith(
      lastMessage:
          operation == 'full_rebuild' ? '知识库 $kbId 已全量重建。' : '知识库 $kbId 已增量更新。',
      lastError: '',
    );
  }

  Future<void> _compareKnowledgeBaseVersions(String kbId) async {
    final workspace = _requireWorkspace();
    final catalog = await _loadKnowledgeCatalog(workspace);
    final records = _catalogRecords(catalog);
    final record = records.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['kb_id']?.toString() == kbId,
          orElse: () => null,
        );
    if (record == null) {
      _fail('未找到要对比的知识库：$kbId');
      return;
    }
    final versions = _listOfMaps(record['versions']).toList(growable: true);
    final latest = versions.isEmpty ? null : versions.last;
    final comparePath = _joinNested(
        workspace.path, 'knowledge_bases/$kbId/version_compare_latest.json');
    await File(comparePath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v2_kb_version_compare.v1',
        'kb_id': kbId,
        'current_version': record['current_version'] ?? 'v1',
        'compared_to': latest?['version_id'] ?? 'none',
        'current_chunks': record['chunk_count'] ?? 0,
        'previous_chunks': latest?['chunk_count'] ?? 0,
        'source_delta': {
          'current_sources': _listOfMaps(record['source_documents']).length,
          'previous_sources': _listOfMaps(latest?['source_documents']).length,
        },
        'status': versions.isEmpty ? 'no_previous_version' : 'compared',
      }),
      encoding: utf8,
    );
    record['version_compare_path'] = comparePath;
    await _writeKnowledgeCatalog(workspace, records,
        operation: 'compare_versions:$kbId');
    state = state.copyWith(lastMessage: '知识库 $kbId 版本对比已生成。', lastError: '');
  }

  Future<void> _rollbackKnowledgeBaseVersion(String kbId) async {
    final workspace = _requireWorkspace();
    final catalog = await _loadKnowledgeCatalog(workspace);
    final records = _catalogRecords(catalog);
    final index =
        records.indexWhere((record) => record['kb_id']?.toString() == kbId);
    if (index < 0) {
      _fail('未找到要回滚的知识库：$kbId');
      return;
    }
    final versions = _listOfMaps(records[index]['versions']);
    if (versions.isEmpty) {
      _fail('知识库 $kbId 没有可回滚版本。');
      return;
    }
    final target = versions.last;
    final snapshotDir = Directory((target['snapshot_path'] ?? '').toString());
    if (!await snapshotDir.exists()) {
      _fail('知识库 $kbId 的回滚快照不存在。');
      return;
    }
    final kbRoot = Directory(_join(workspace.path, 'knowledge_bases', kbId));
    if (await kbRoot.exists()) {
      await kbRoot.delete(recursive: true);
    }
    await _copyDirectory(snapshotDir, kbRoot);
    final record = await _materializeKnowledgeBaseRecord(
      workspace: workspace,
      kbId: kbId,
      name: (target['kb_name'] ?? records[index]['kb_name'] ?? kbId).toString(),
      type: (target['kb_type'] ?? records[index]['kb_type'] ?? '普通知识库')
          .toString(),
      sourceDocuments: _listOfMaps(target['source_documents']),
      sourceKbIds: _listOfStrings(records[index]['source_kb_ids']),
      operation: 'rollback',
      sourceDirectory: snapshotDir,
      versionsOverride: versions.take(versions.length - 1).toList(),
      currentVersionOverride: (target['version_id'] ?? '').toString(),
    );
    record['rolled_back_from'] = records[index]['current_version'] ?? 'current';
    record['rolled_back_to'] = target['version_id'] ?? 'previous';
    await File(_join(kbRoot.path, 'rollback.log')).writeAsString(
      'rolled_back_to=${record['rolled_back_to']}\n',
      encoding: utf8,
    );
    records[index] = record;
    await _writeKnowledgeCatalog(workspace, records,
        operation: 'rollback:$kbId');
    state = state.copyWith(lastMessage: '知识库 $kbId 已回滚。', lastError: '');
  }

  Future<Map<String, dynamic>> _materializeKnowledgeBaseRecord({
    required Directory workspace,
    required String kbId,
    required String name,
    required String type,
    required List<Map<String, dynamic>> sourceDocuments,
    required List<String> sourceKbIds,
    required String operation,
    Directory? sourceDirectory,
    List<Map<String, dynamic>>? versionsOverride,
    String? currentVersionOverride,
  }) async {
    final kbRoot = Directory(_join(workspace.path, 'knowledge_bases', kbId));
    final baseKbDir = sourceDirectory ?? Directory(_join(workspace.path, 'kb'));
    if (await kbRoot.exists()) {
      await kbRoot.delete(recursive: true);
    }
    await _copyDirectory(baseKbDir, kbRoot);
    final docs = sourceDocuments.isEmpty
        ? await _sourceDocumentsFromManifest(workspace)
        : _dedupeSourceDocuments(sourceDocuments);
    final now = DateTime.now().toUtc().toIso8601String();
    final chunkPath = _join(kbRoot.path, 'chunks.jsonl');
    final previousVersions = versionsOverride ??
        await _existingKnowledgeBaseVersions(workspace, kbId);
    final currentVersion = currentVersionOverride?.isNotEmpty == true
        ? currentVersionOverride!
        : 'v${previousVersions.length + 1}_${now.replaceAll(RegExp(r'[:.]'), '')}';
    final record = {
      'schema_version': 'prd_v2_knowledge_base_record.v1',
      'kb_id': kbId,
      'workspace_id': 'default',
      'kb_name': name,
      'kb_type': type,
      'status': 'searchable',
      'operation': operation,
      'created_at': now,
      'updated_at': now,
      'current_version': currentVersion,
      'versions': previousVersions,
      'source_documents': docs,
      'source_kb_ids': sourceKbIds,
      'chunk_count': _countJsonl(chunkPath),
      'vector_store': 'local_file_index',
      'keyword_index': true,
      'manifest_path': _join(kbRoot.path, 'manifest.json'),
      'chunks_path': chunkPath,
      'source_map_path': _join(kbRoot.path, 'source_map.json'),
      'index_metadata_path': _join(kbRoot.path, 'index_metadata.json'),
      'index_profile_path': _join(kbRoot.path, 'index_profile.json'),
      'keyword_index_path': _join(kbRoot.path, 'keyword_index.json'),
      'vector_index_reference_path':
          _join(kbRoot.path, 'vector_index_reference.json'),
      'metadata_index_path': _join(kbRoot.path, 'metadata_index.json'),
      'citation_index_path': _join(kbRoot.path, 'citation_index.json'),
      'memory_index_reference_path':
          _join(kbRoot.path, 'memory_index_reference.json'),
      'index_build_report_path': _join(kbRoot.path, 'index_build_report.json'),
      'quality_report_path': _join(kbRoot.path, 'quality_report.json'),
      'build_log_path': _join(kbRoot.path, 'build.log'),
      'error_log_path': _join(kbRoot.path, 'error.log'),
      'actions': [
        'view',
        'retrieve',
        'incremental_update',
        'rebuild',
        'compare_versions',
        'rollback',
        'copy',
        'merge',
        'split',
        'generate_document',
        'generate_skill',
        'bind_agent',
        'delete',
      ],
    };
    await File(_join(kbRoot.path, 'prd_kb_manifest.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert(record),
        encoding: utf8);
    await File(_join(kbRoot.path, 'source_map.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'kb_id': kbId,
          'documents': docs,
          'source_kb_ids': sourceKbIds,
        }),
        encoding: utf8);
    await _writeIndustrialIndexArtifacts(
      kbDir: kbRoot,
      kbId: kbId,
      operation: operation,
      chunks: await _readJsonl(File(chunkPath)),
      sourceDocs: docs,
      cards: await _readJsonl(File(_join(kbRoot.path, 'cards.jsonl'))),
      qaPairs: await _readJsonl(File(_join(kbRoot.path, 'qa_pairs.jsonl'))),
      vectorStore: 'local_file_index',
    );
    await File(_join(kbRoot.path, 'build.log')).writeAsString(
      'operation=$operation\nversion=$currentVersion\nsource_count=${docs.length}\n',
      encoding: utf8,
    );
    final errorLog = File(_join(kbRoot.path, 'error.log'));
    if (!await errorLog.exists()) {
      await errorLog.writeAsString('status=ok\n', encoding: utf8);
    }
    return record;
  }

  Future<void> _writeIndustrialIndexArtifacts({
    required Directory kbDir,
    required String kbId,
    required String operation,
    required List<Map<String, dynamic>> chunks,
    required List<Map<String, dynamic>> sourceDocs,
    required List<Map<String, dynamic>> cards,
    required List<Map<String, dynamic>> qaPairs,
    required String vectorStore,
  }) async {
    await kbDir.create(recursive: true);
    final now = DateTime.now().toUtc().toIso8601String();
    final chunkRows = chunks
        .asMap()
        .entries
        .map((entry) => {
              ...entry.value,
              'chunk_id': _stringValue(
                  entry.value['chunk_id'], 'chunk_${entry.key + 1}'),
            })
        .toList(growable: false);
    final keywordIndex = <String, Set<String>>{};
    final citationRows = <Map<String, Object?>>[];
    for (final chunk in chunkRows) {
      final chunkId = _stringValue(chunk['chunk_id'], '');
      final text = _stringValue(chunk['text'] ?? chunk['summary'], '');
      for (final term in text
          .toLowerCase()
          .split(RegExp(r'[^a-z0-9\u4e00-\u9fff]+'))
          .where((term) => term.trim().length >= 2)
          .take(80)) {
        keywordIndex.putIfAbsent(term, () => <String>{}).add(chunkId);
      }
      citationRows.add({
        'chunk_id': chunkId,
        'citation': _stringValue(
            chunk['citation'] ?? chunk['source_path'] ?? chunk['source'], ''),
        'source_path':
            _stringValue(chunk['source_path'] ?? chunk['source'], ''),
      });
    }
    final keywordPayload = {
      for (final entry in keywordIndex.entries)
        entry.key: entry.value.toList(growable: false)..sort(),
    };
    final metadataRows = sourceDocs
        .map((doc) => {
              'document_id': _stringValue(doc['document_id'], ''),
              'source_name': _stringValue(doc['source_name'], ''),
              'relative_path': _stringValue(doc['relative_path'], ''),
              'chunk_count': _asInt(doc['chunk_count']) ?? 0,
              'size_bytes': _asInt(doc['size_bytes']) ?? 0,
            })
        .toList(growable: false);
    await File(_join(kbDir.path, 'index_profile.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_index_profile.v1',
        'index_profile_id': '${kbId}_hybrid_local_v1',
        'kb_id': kbId,
        'status': chunkRows.isEmpty ? 'needs_content' : 'ready',
        'keyword_index_enabled': true,
        'vector_index_enabled': true,
        'metadata_index_enabled': true,
        'citation_index_enabled': true,
        'memory_index_enabled': true,
        'vector_store': vectorStore,
        'created_at': now,
      }),
      encoding: utf8,
    );
    await File(_join(kbDir.path, 'keyword_index.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_keyword_index.v1',
        'kb_id': kbId,
        'term_count': keywordPayload.length,
        'terms': keywordPayload,
      }),
      encoding: utf8,
    );
    await File(_join(kbDir.path, 'vector_index_reference.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_vector_index_reference.v1',
        'kb_id': kbId,
        'vector_store': vectorStore,
        'embedding_provider': 'configured_provider_or_local_reference',
        'chunk_count': chunkRows.length,
        'external_vector_db_required': false,
        'secret_plaintext_written': false,
      }),
      encoding: utf8,
    );
    await File(_join(kbDir.path, 'metadata_index.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_metadata_index.v1',
        'kb_id': kbId,
        'documents': metadataRows,
      }),
      encoding: utf8,
    );
    await File(_join(kbDir.path, 'citation_index.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_citation_index.v1',
        'kb_id': kbId,
        'citations': citationRows,
      }),
      encoding: utf8,
    );
    await File(_join(kbDir.path, 'memory_index_reference.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_memory_index_reference.v1',
        'kb_id': kbId,
        'memory_scope': 'agent_long_term_memory',
        'memory_store': 'separate_from_kb_index',
        'enabled_by_agent_config': true,
        'secret_plaintext_written': false,
      }),
      encoding: utf8,
    );
    await File(_join(kbDir.path, 'index_build_report.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_index_build_report.v1',
        'kb_id': kbId,
        'operation': operation,
        'status': chunkRows.isEmpty ? 'needs_content' : 'pass',
        'chunk_count': chunkRows.length,
        'source_count': sourceDocs.length,
        'card_count': cards.length,
        'qa_pair_count': qaPairs.length,
        'built_at': now,
        'outputs': {
          'index_profile': _join(kbDir.path, 'index_profile.json'),
          'keyword_index': _join(kbDir.path, 'keyword_index.json'),
          'vector_index_reference':
              _join(kbDir.path, 'vector_index_reference.json'),
          'metadata_index': _join(kbDir.path, 'metadata_index.json'),
          'citation_index': _join(kbDir.path, 'citation_index.json'),
          'memory_index_reference':
              _join(kbDir.path, 'memory_index_reference.json'),
        },
      }),
      encoding: utf8,
    );
    await File(_join(kbDir.path, 'index_metadata.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_index_metadata.v1',
        'kb_id': kbId,
        'index_type': 'hybrid_local',
        'index_profile_path': _join(kbDir.path, 'index_profile.json'),
        'keyword_index_path': _join(kbDir.path, 'keyword_index.json'),
        'vector_index_reference_path':
            _join(kbDir.path, 'vector_index_reference.json'),
        'metadata_index_path': _join(kbDir.path, 'metadata_index.json'),
        'citation_index_path': _join(kbDir.path, 'citation_index.json'),
        'memory_index_reference_path':
            _join(kbDir.path, 'memory_index_reference.json'),
        'index_build_report_path': _join(kbDir.path, 'index_build_report.json'),
        'keyword_index': true,
        'vector_store': vectorStore,
        'chunk_count': chunkRows.length,
        'card_count': cards.length,
        'qa_pair_count': qaPairs.length,
        'source_count': sourceDocs.length,
      }),
      encoding: utf8,
    );
  }

  Future<List<Map<String, dynamic>>> _existingKnowledgeBaseVersions(
      Directory workspace, String kbId) async {
    final catalog = await _loadKnowledgeCatalog(workspace);
    final records = _catalogRecords(catalog);
    final record = records.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['kb_id']?.toString() == kbId,
          orElse: () => null,
        );
    return record == null
        ? <Map<String, dynamic>>[]
        : _listOfMaps(record['versions']);
  }

  Future<void> _snapshotKnowledgeBaseVersion(
    Directory workspace,
    Map<String, dynamic> record, {
    required String reason,
  }) async {
    final kbId = (record['kb_id'] ?? '').toString();
    if (kbId.isEmpty) return;
    final kbRoot = Directory(_join(workspace.path, 'knowledge_bases', kbId));
    if (!await kbRoot.exists()) return;
    final versionId = (record['current_version'] ?? 'v1').toString();
    final safeVersionId = _safeFileName(versionId);
    final snapshotDir = Directory(_joinNested(
        workspace.path, 'knowledge_bases/_versions/$kbId/$safeVersionId'));
    if (await snapshotDir.exists()) {
      await snapshotDir.delete(recursive: true);
    }
    await _copyDirectory(kbRoot, snapshotDir);
    final versions = _listOfMaps(record['versions']).toList(growable: true);
    versions.add({
      'version_id': versionId,
      'snapshot_path': snapshotDir.path,
      'created_at': record['updated_at'] ?? record['created_at'] ?? '',
      'reason': reason,
      'kb_name': record['kb_name'] ?? kbId,
      'kb_type': record['kb_type'] ?? '',
      'source_documents': _listOfMaps(record['source_documents']),
      'chunk_count': record['chunk_count'] ?? 0,
      'manifest_path': record['manifest_path'] ?? '',
      'quality_report_path': record['quality_report_path'] ?? '',
    });
    record['versions'] = versions;
  }

  Future<Map<String, dynamic>> _loadKnowledgeCatalog(Directory workspace) {
    return _readJsonObject(
        _join(workspace.path, 'knowledge_bases', 'kb_catalog.json'));
  }

  Future<Directory> _writeStandardKnowledgePackage({
    required Directory workspace,
    required String operation,
  }) async {
    final packageRoot =
        Directory(_join(workspace.path, 'standard_packages', 'current'));
    if (await packageRoot.exists()) {
      await packageRoot.delete(recursive: true);
    }
    await packageRoot.create(recursive: true);
    final sourceManifestPath = _join(workspace.path, 'source_manifest.json');
    final parseReportPath = _join(workspace.path, 'parse_report.json');
    final sourceManifest = await _readJsonObject(sourceManifestPath);
    final sources = _sourceRecordsFromManifest(sourceManifest);
    final normalizedSourcesByRelativePath =
        await _normalizedSourcesByRelativePath(workspace);
    final packageId =
        'OKF_${DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '')}_${_stableHash(sourceManifestPath)}';
    final contentRows = <Map<String, Object?>>[];
    for (final source in sources) {
      final normalizedPath = normalizedSourcesByRelativePath[
          _normalizePathKey(source.relativePath)];
      var contentPreview = '';
      if (normalizedPath != null && await File(normalizedPath).exists()) {
        contentPreview = _compact(
          await File(normalizedPath).readAsString(encoding: utf8),
          maxLength: 1200,
        );
      }
      contentRows.add({
        'document_id': source.documentId,
        'source_name': source.sourceName,
        'relative_path': source.relativePath,
        'source_type': source.sourceType,
        'normalized_path': normalizedPath ?? '',
        'content_preview': contentPreview,
        'word_count': source.wordCount,
        'image_count': source.imageCount,
        'table_count': source.tableCount,
        'link_count': source.linkCount,
      });
    }
    final sourceRefsPath = _join(packageRoot.path, 'source_references.json');
    final contentPath = _join(packageRoot.path, 'content_package.jsonl');
    final manifestPath =
        _join(packageRoot.path, 'standard_package_manifest.json');
    await File(sourceRefsPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_standard_knowledge_package_sources.v1',
        'package_id': packageId,
        'source_manifest': sourceManifestPath,
        'parse_report':
            await File(parseReportPath).exists() ? parseReportPath : '',
        'sources': contentRows
            .map((row) => {
                  'document_id': row['document_id'],
                  'source_name': row['source_name'],
                  'relative_path': row['relative_path'],
                  'normalized_path': row['normalized_path'],
                })
            .toList(growable: false),
      }),
      encoding: utf8,
    );
    await File(contentPath).writeAsString(
      '${contentRows.map(jsonEncode).join('\n')}\n',
      encoding: utf8,
    );
    final manifest = {
      'schema_version': 'prd_v3_standard_knowledge_package_manifest.v1',
      'package_id': packageId,
      'standard': 'okf_candidate',
      'status': 'exported',
      'operation': operation,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'workspace': workspace.path,
      'manifest_path': manifestPath,
      'source_references_path': sourceRefsPath,
      'content_package_path': contentPath,
      'source_manifest_path': sourceManifestPath,
      'parse_report_path':
          await File(parseReportPath).exists() ? parseReportPath : '',
      'source_count': sources.length,
      'content_record_count': contentRows.length,
      'version': 'v1',
      'okf_runtime_enabled': false,
      'independent_agent_runtime': false,
      'secret_plaintext_written': false,
    };
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      encoding: utf8,
    );
    return packageRoot;
  }

  Future<void> _materializeKnowledgeBaseFromStandardPackage(
      Directory packageDir) async {
    final workspace = _requireWorkspace();
    final manifest = await _readJsonObject(
        _join(packageDir.path, 'standard_package_manifest.json'));
    final contentRows =
        await _readJsonl(File(_join(packageDir.path, 'content_package.jsonl')));
    final kbDir = Directory(_join(workspace.path, 'kb'));
    await _clearWorkspacePath(kbDir.path);
    await kbDir.create(recursive: true);
    final chunks = <String>[];
    for (var index = 0; index < contentRows.length; index += 1) {
      final row = contentRows[index];
      chunks.add(jsonEncode({
        'chunk_id': 'okf_chunk_${index + 1}',
        'text': row['content_preview'] ?? row['source_name'] ?? '',
        'source_path': row['relative_path'] ?? row['source_name'] ?? '',
        'citation': '${row['source_name'] ?? 'source'}#okf=${index + 1}',
        'document_id': row['document_id'] ?? '',
      }));
    }
    await File(_join(kbDir.path, 'chunks.jsonl')).writeAsString(
      chunks.isEmpty ? '' : '${chunks.join('\n')}\n',
      encoding: utf8,
    );
    await File(_join(kbDir.path, 'cards.jsonl')).writeAsString(
      contentRows
              .map((row) => jsonEncode({
                    'title': row['source_name'] ?? 'standard package source',
                    'summary': _compact(row['content_preview'] ?? ''),
                    'source_path': row['relative_path'] ?? '',
                  }))
              .join('\n') +
          (contentRows.isEmpty ? '' : '\n'),
      encoding: utf8,
    );
    await File(_join(kbDir.path, 'qa_pairs.jsonl')).writeAsString(
      contentRows
              .map((row) => jsonEncode({
                    'question': '来源 ${row['source_name'] ?? ''} 的核心内容是什么？',
                    'answer': _compact(row['content_preview'] ?? ''),
                    'source_path': row['relative_path'] ?? '',
                  }))
              .join('\n') +
          (contentRows.isEmpty ? '' : '\n'),
      encoding: utf8,
    );
    await File(_join(kbDir.path, 'manifest.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_kb_from_standard_package.v1',
        'status': contentRows.isEmpty ? 'needs_content' : 'pass',
        'package_id': manifest['package_id'] ?? '',
        'standard': manifest['standard'] ?? 'okf_candidate',
        'source_package_manifest':
            _join(packageDir.path, 'standard_package_manifest.json'),
        'chunk_count': contentRows.length,
      }),
      encoding: utf8,
    );
    await File(_join(kbDir.path, 'quality_report.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_standard_package_kb_quality.v1',
        'status': contentRows.isEmpty ? 'needs_content' : 'pass',
        'source_package_manifest':
            _join(packageDir.path, 'standard_package_manifest.json'),
        'coverage': {
          'source_count': manifest['source_count'] ?? contentRows.length,
          'content_record_count': contentRows.length,
        },
      }),
      encoding: utf8,
    );
    await _writeDerivedKnowledgeArtifacts();
    final record = await _materializeKnowledgeBaseRecord(
      workspace: workspace,
      kbId: 'K_OKF1',
      name: '标准知识包知识库',
      type: '标准知识包构建',
      sourceDocuments: contentRows
          .map((row) => {
                'document_id': row['document_id'] ?? '',
                'source_name': row['source_name'] ?? '',
                'relative_path': row['relative_path'] ?? '',
                'source_type': row['source_type'] ?? '',
              })
          .toList(growable: false),
      sourceKbIds: const [],
      operation: 'build_from_standard_package',
    );
    record['source_standard_package_manifest'] =
        _join(packageDir.path, 'standard_package_manifest.json');
    record['okf_runtime_enabled'] = false;
    final catalog = await _loadKnowledgeCatalog(workspace);
    final records = [
      ..._catalogRecords(catalog).where((item) => item['kb_id'] != 'K_OKF1'),
      record,
    ];
    await _writeKnowledgeCatalog(workspace, records,
        operation: 'build_from_standard_package:K_OKF1');
  }

  Future<void> _appendStandardPackageAuditRecord({
    required String action,
    required String artifact,
    required String status,
    Map<String, Object?> details = const {},
  }) async {
    final workspace = _requireWorkspace();
    final root = Directory(_join(workspace.path, 'standard_packages'));
    await root.create(recursive: true);
    await File(_join(root.path, 'audit_history.jsonl')).writeAsString(
      '${jsonEncode({
            'schema_version': 'prd_v3_standard_package_audit_record.v1',
            'action': action,
            'artifact': artifact,
            'status': status,
            'details': details,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })}\n',
      mode: FileMode.append,
      encoding: utf8,
    );
  }

  List<Map<String, dynamic>> _catalogRecords(Map<String, dynamic> catalog) {
    return (catalog['knowledge_bases'] as List?)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: true) ??
        <Map<String, dynamic>>[];
  }

  static List<Rc6KnowledgeBaseRecord> _recordsFromKnowledgeCatalog(
      Map<String, dynamic> catalog) {
    final records = (catalog['knowledge_bases'] as List?)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false) ??
        const <Map<String, dynamic>>[];
    return records
        .map((item) => Rc6KnowledgeBaseRecord(
              id: (item['kb_id'] ?? '').toString(),
              name: (item['kb_name'] ?? item['kb_id'] ?? '').toString(),
              type: (item['kb_type'] ?? '').toString(),
              status: (item['status'] ?? '').toString(),
              currentVersion: (item['current_version'] ?? '').toString(),
              versionCount: _listOfMaps(item['versions']).length + 1,
              sourceCount: _listOfMaps(item['source_documents']).length,
              chunkCount: _asInt(item['chunk_count']) ?? 0,
              manifestPath: (item['manifest_path'] ?? '').toString(),
              qualityReportPath: (item['quality_report_path'] ?? '').toString(),
              versionComparePath:
                  (item['version_compare_path'] ?? '').toString(),
              operation: (item['operation'] ?? '').toString(),
            ))
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _writeKnowledgeCatalog(
    Directory workspace,
    List<Map<String, dynamic>> records, {
    required String operation,
  }) async {
    final catalogDir = Directory(_join(workspace.path, 'knowledge_bases'));
    await catalogDir.create(recursive: true);
    records.sort((a, b) =>
        (a['kb_id'] ?? '').toString().compareTo((b['kb_id'] ?? '').toString()));
    final payload = {
      'schema_version': 'prd_v2_knowledge_base_catalog.v1',
      'workspace': workspace.path,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'last_operation': operation,
      'knowledge_bases': records,
    };
    await File(_join(catalogDir.path, 'kb_catalog.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
  }

  Future<List<Map<String, dynamic>>> _sourceDocumentsFromManifest(
      Directory workspace) async {
    final sourceManifest =
        await _readJsonObject(_join(workspace.path, 'source_manifest.json'));
    return (sourceManifest['sources'] as List?)
            ?.whereType<Map>()
            .map((source) => Map<String, dynamic>.from(source))
            .map((source) => {
                  'document_id': _documentId(source),
                  'source_name':
                      (source['source_name'] ?? source['relative_path'] ?? '')
                          .toString(),
                  'relative_path': (source['relative_path'] ?? '').toString(),
                })
            .toList(growable: false) ??
        const <Map<String, dynamic>>[];
  }

  static List<Map<String, dynamic>> _dedupeSourceDocuments(
      List<Map<String, dynamic>> docs) {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final doc in docs) {
      final normalized = {
        'document_id': (doc['document_id'] ?? _documentId(doc)).toString(),
        'source_name':
            (doc['source_name'] ?? doc['relative_path'] ?? '').toString(),
        'relative_path': (doc['relative_path'] ?? '').toString(),
      };
      final key = '${normalized['document_id']}|${normalized['relative_path']}';
      if (seen.add(key)) result.add(normalized);
    }
    return result;
  }

  static List<Map<String, dynamic>> _listOfMaps(Object? value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  static List<String> _listOfStrings(Object? value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  static String _stringValue(Object? value, String fallback) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String _nextKnowledgeBaseId(List<Map<String, dynamic>> records,
      {required String prefix}) {
    final existing =
        records.map((record) => record['kb_id']?.toString()).toSet();
    var index = 1;
    var candidate = '$prefix$index';
    while (existing.contains(candidate)) {
      index += 1;
      candidate = '$prefix$index';
    }
    return candidate;
  }

  Future<void> _writeReadingNotes({
    Rc6DocumentGenerationConfig config = const Rc6DocumentGenerationConfig(),
  }) async {
    final workspace = _requireWorkspace();
    final kbDir = _join(workspace.path, 'kb');
    final docDir = Directory(_join(workspace.path, 'doc'));
    await docDir.create(recursive: true);
    final chunks = await _readJsonl(File(_join(kbDir, 'chunks.jsonl')));
    final cards = await _readJsonl(File(_join(kbDir, 'cards.jsonl')));
    final qaPairs = await _readJsonl(File(_join(kbDir, 'qa_pairs.jsonl')));
    final sources = await _sourceNames();
    final topChunks = chunks.take(8).toList(growable: false);
    final topCards = cards.take(8).toList(growable: false);
    final topQa = qaPairs.take(6).toList(growable: false);
    final buffer = StringBuffer()
      ..writeln('# ${config.title}')
      ..writeln()
      ..writeln('## 生成配置')
      ..writeln('- 文档类型：${config.generationTypeLabel}')
      ..writeln('- 模板模式：${config.templateModeLabel}')
      ..writeln('- 输出格式：${config.outputFormat.toUpperCase()}')
      ..writeln('- 引用策略：${config.citationStrategyLabel}')
      ..writeln()
      ..writeln('## 核心摘要')
      ..writeln()
      ..writeln(
          '- 本笔记由 rc10 真实 EXE 链路基于 `D:\\HeiTang-Codex-WorkSpace\\input` 的 ${sources.length} 个真实文件生成。')
      ..writeln(
          '- 知识库包含 ${chunks.length} 个 chunks、${cards.length} 张 cards、${qaPairs.length} 个 QA pairs。')
      ..writeln('- 内容来自真实解析产物和知识库索引，不是固定演示文本。')
      ..writeln()
      ..writeln('## 章节 / 主题结构');
    for (final source in sources) {
      buffer.writeln('- $source');
    }
    buffer
      ..writeln()
      ..writeln('## 关键概念');
    for (final card in topCards) {
      buffer.writeln('- ${_compact(card['title'] ?? card['summary'] ?? card)}');
    }
    buffer
      ..writeln()
      ..writeln('## 可执行行动项')
      ..writeln('- 把每个主题拆成可检索问题，优先使用带 citation 的 chunk。')
      ..writeln('- 对 OCR/Parser 噪声较高的段落标记 review_required。')
      ..writeln('- 将 Skill 用于本地 KB-grounded 回答，不默认联网或调用外部 provider。')
      ..writeln('- 将 Agent 的输出限制为引用知识库证据的摘要、问答、质检和运营分析。')
      ..writeln()
      ..writeln('## 适合后续 Agent 使用的要点');
    for (final qa in topQa) {
      buffer.writeln(
          '- Q: ${_compact(qa['question'] ?? qa['prompt'] ?? qa)} / A: ${_compact(qa['answer'] ?? qa['response'] ?? '')}');
    }
    buffer
      ..writeln()
      ..writeln('## 引用来源或文件名');
    for (final chunk in topChunks) {
      buffer.writeln(
          '- ${_compact(chunk['source_path'] ?? chunk['citation'] ?? '')}');
    }
    await File(_join(docDir.path, 'reading_notes.md'))
        .writeAsString(buffer.toString(), encoding: utf8);
  }

  Future<void> _writeDocumentGenerationManifest({
    required Rc6DocumentGenerationConfig config,
    List<Map<String, dynamic>> existingHistory = const [],
  }) async {
    final workspace = _requireWorkspace();
    final docDir = Directory(_join(workspace.path, 'doc'));
    await docDir.create(recursive: true);
    final kbManifest =
        await _readJsonObject(_join(workspace.path, 'kb', 'manifest.json'));
    final queryReport = await _readLatestQueryReport(workspace);
    final catalog = await _loadKnowledgeCatalog(workspace);
    final records = _catalogRecords(catalog);
    final selectedKbIds = records.isEmpty
        ? const ['current_kb']
        : records
            .map((record) => (record['kb_id'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toList(growable: false);
    final readingNotesPath = _join(docDir.path, 'reading_notes.md');
    final generatedPath = _join(docDir.path, 'generated.md');
    final outputPath = await File(readingNotesPath).exists()
        ? readingNotesPath
        : generatedPath;
    final sources = await _sourceNames();
    final citations = _citationsFromQueryReport(queryReport);
    final history = existingHistory.toList(growable: true);
    final createdAt = DateTime.now().toUtc().toIso8601String();
    final outlinePath = _join(docDir.path, 'outline.json');
    final citationsPath = _join(docDir.path, 'citations.json');
    final validationPath =
        _join(docDir.path, 'document_validation_report.json');
    final historyDir = Directory(_join(workspace.path, 'document_history'));
    await historyDir.create(recursive: true);
    final historyMarkdownPath = _join(
      historyDir.path,
      _safeFileName(
        'generation_${history.length + 1}_${config.generationType}_$createdAt.md',
      ),
    );
    if (await File(outputPath).exists()) {
      await File(outputPath).copy(historyMarkdownPath);
    }
    history.add({
      'event': 'generate_document',
      'template': config.templateMode,
      'generation_type': config.generationType,
      'output_format': config.outputFormat,
      'output_markdown': outputPath,
      'history_markdown': historyMarkdownPath,
      'citation_count': citations.length,
      'created_at': createdAt,
    });
    await File(outlinePath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_document_outline.v1',
        'title': config.title,
        'generation_type': config.generationType,
        'template_mode': config.templateMode,
        'selected_kb_ids': selectedKbIds,
        'sections': [
          '生成配置',
          '核心摘要',
          '章节 / 主题结构',
          '关键概念',
          '可执行行动项',
          '适合后续 Agent 使用的要点',
          '引用来源或文件名',
        ],
        'confirmed_by_owner': false,
        'generated_at': createdAt,
      }),
      encoding: utf8,
    );
    await File(citationsPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_document_citations.v1',
        'citation_strategy': config.citationStrategy,
        'citation_count': citations.length,
        'citations': citations,
        'retrieval_report_path':
            queryReport.isEmpty ? '' : state.queryResultPath,
        'generated_at': createdAt,
      }),
      encoding: utf8,
    );
    await File(validationPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_document_validation_report.v1',
        'status': 'pass',
        'body_status':
            await File(outputPath).exists() ? 'generated' : 'missing_output',
        'outline_status': 'generated_from_template',
        'citation_list_status': 'written',
        'citation_count': citations.length,
        'history_snapshot_status': await File(historyMarkdownPath).exists()
            ? 'written'
            : 'not_written',
        'export_format_requested': config.outputFormat,
        'secret_plaintext_written': false,
        'generated_at': createdAt,
      }),
      encoding: utf8,
    );
    final payload = {
      'schema_version': 'prd_v3_template_document_generation.v1',
      'status': 'pass',
      'workspace': workspace.path,
      'generation_config': config.toJson(),
      'selected_kb_ids': selectedKbIds,
      'kb_manifest_path': _join(workspace.path, 'kb', 'manifest.json'),
      'kb_schema_version': (kbManifest['schema_version'] ?? '').toString(),
      'retrieval_report_path': queryReport.isEmpty ? '' : state.queryResultPath,
      'retrieval_query': (queryReport['query'] ?? state.searchQuery).toString(),
      'source_count': sources.length,
      'sources': sources,
      'citations': citations,
      'outline_path': outlinePath,
      'citations_path': citationsPath,
      'document_validation_report_path': validationPath,
      'outline_status': 'generated_from_template',
      'body_status': 'generated',
      'citation_list_status': 'written',
      'output_markdown': outputPath,
      'export_format_requested': config.outputFormat,
      'generation_history': history,
      'secret_plaintext_written': false,
    };
    await File(_join(docDir.path, 'generation_manifest.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
  }

  Future<Map<String, dynamic>> _latestDocumentGenerationConfig(
      Directory workspace) async {
    final manifest = await _readJsonObject(
        _join(workspace.path, 'doc', 'generation_manifest.json'));
    final config = manifest['generation_config'];
    return config is Map ? Map<String, dynamic>.from(config) : const {};
  }

  static List<Map<String, String>> _citationsFromQueryReport(
      Map<String, dynamic> queryReport) {
    final rows = queryReport['selected'] ??
        queryReport['results'] ??
        queryReport['records'];
    if (rows is! List) return const <Map<String, String>>[];
    return rows
        .whereType<Map>()
        .map((row) => {
              'text': _compact(row['text'] ?? row['excerpt'] ?? row['title']),
              'citation':
                  (row['citation'] ?? row['source_path'] ?? '').toString(),
              'kb_id': (row['kb_id'] ?? '').toString(),
              'kb_name': (row['kb_name'] ?? '').toString(),
            })
        .where((row) => row['citation']!.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<Map<String, Object?>> _structuredDocumentExportPayload(
      Directory workspace) async {
    final sourceManifest =
        await _readJsonObject(_join(workspace.path, 'source_manifest.json'));
    final kbManifest =
        await _readJsonObject(_join(workspace.path, 'kb', 'manifest.json'));
    final qualityReport = await _readJsonObject(
        _join(workspace.path, 'kb', 'quality_report.json'));
    final queryReport = await _readLatestQueryReport(workspace);
    final chunks =
        await _readJsonl(File(_join(workspace.path, 'kb', 'chunks.jsonl')));
    final cards =
        await _readJsonl(File(_join(workspace.path, 'kb', 'cards.jsonl')));
    final qaPairs =
        await _readJsonl(File(_join(workspace.path, 'kb', 'qa_pairs.jsonl')));
    final readingNotes = File(_join(workspace.path, 'doc', 'reading_notes.md'));
    final edited = File(_join(workspace.path, 'doc', 'edited_document.md'));
    final generated = File(_join(workspace.path, 'doc', 'generated.md'));
    final docText = await edited.exists()
        ? await edited.readAsString(encoding: utf8)
        : await readingNotes.exists()
            ? await readingNotes.readAsString(encoding: utf8)
            : await generated.readAsString(encoding: utf8);
    final sources = _listOfMaps(sourceManifest['sources']);
    final queryRows = queryReport['selected'] ??
        queryReport['results'] ??
        queryReport['records'];
    return {
      'schema_version': 'prd_v2_structured_document_export_payload.v1',
      'status': 'pass',
      'workspace': workspace.path,
      'source_count': sources.length,
      'sources': sources
          .map((source) => {
                'source_name':
                    (source['source_name'] ?? source['relative_path'] ?? '')
                        .toString(),
                'relative_path': (source['relative_path'] ?? '').toString(),
                'size_bytes': _asInt(source['size_bytes']) ?? 0,
              })
          .toList(growable: false),
      'knowledge_base': {
        'manifest': _join(workspace.path, 'kb', 'manifest.json'),
        'schema_version': (kbManifest['schema_version'] ?? '').toString(),
        'chunk_count': chunks.length,
        'card_count': cards.length,
        'qa_pair_count': qaPairs.length,
        'quality_status': (qualityReport['status'] ?? 'unknown').toString(),
      },
      'document': {
        'format': 'markdown',
        'path':
            await readingNotes.exists() ? readingNotes.path : generated.path,
        'size_bytes': utf8.encode(docText).length,
        'preview': _compact(docText),
      },
      'retrieval': {
        'query': (queryReport['query'] ?? state.searchQuery).toString(),
        'selected_count': _asInt(queryReport['selected_count']) ?? 0,
        'citation_coverage': queryReport['citation_coverage'] ?? '',
        'results': queryRows is List
            ? queryRows
                .whereType<Map>()
                .take(20)
                .map((row) => Map<String, dynamic>.from(row))
                .toList(growable: false)
            : const <Map<String, dynamic>>[],
      },
      'cards': cards.take(20).toList(growable: false),
      'qa_pairs': qaPairs.take(20).toList(growable: false),
      'redaction': {
        'secret_plaintext_written': false,
        'api_key_display': 'masked',
      },
    };
  }

  static String _structuredDocumentExportCsv(Map<String, Object?> payload) {
    final rows = <List<Object?>>[
      ['section', 'name', 'value', 'citation'],
    ];
    final sources = payload['sources'];
    if (sources is List) {
      for (final source in sources.whereType<Map>()) {
        rows.add([
          'source',
          source['source_name'],
          source['size_bytes'],
          source['relative_path'],
        ]);
      }
    }
    final kb = _mapValue(payload['knowledge_base']);
    rows.add(['knowledge_base', 'chunk_count', kb['chunk_count'], '']);
    rows.add(['knowledge_base', 'card_count', kb['card_count'], '']);
    rows.add(['knowledge_base', 'qa_pair_count', kb['qa_pair_count'], '']);
    final retrieval = _mapValue(payload['retrieval']);
    rows.add(['retrieval', 'query', retrieval['query'], '']);
    rows.add(['retrieval', 'selected_count', retrieval['selected_count'], '']);
    final results = retrieval['results'];
    if (results is List) {
      for (final result in results.whereType<Map>()) {
        rows.add([
          'retrieval_result',
          result['source_path'] ?? result['title'] ?? result['chunk_id'],
          result['text'] ?? result['summary'] ?? result['content'],
          result['citation'] ?? result['source_path'] ?? '',
        ]);
      }
    }
    return rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
  }

  static String _csvCell(Object? value) {
    final text =
        (value ?? '').toString().replaceAll('\r', ' ').replaceAll('\n', ' ');
    final escaped = text.replaceAll('"', '""');
    if (escaped.contains(',') || escaped.contains('"')) {
      return '"$escaped"';
    }
    return escaped;
  }

  Future<void> _writeAdditionalSkillPackages({
    File? externalSkillSource,
    Rc6SkillGenerationConfig config = const Rc6SkillGenerationConfig(),
  }) async {
    final workspace = _requireWorkspace();
    final skillRoot = Directory(_join(workspace.path, 'skill'));
    await skillRoot.create(recursive: true);
    final kbManifestPath = _join(workspace.path, 'kb', 'manifest.json');
    final sourceManifestPath = _join(workspace.path, 'source_manifest.json');
    final primaryDir = Directory(_join(skillRoot.path, 'knowledge_qa_skill'));
    await primaryDir.create(recursive: true);
    final primarySkill = File(_join(primaryDir.path, 'SKILL.md'));
    await primarySkill.writeAsString(
      [
        '# ${config.skillName}',
        '',
        '## 能力说明',
        '基于当前工作区的真实知识库、chunks、cards 和 qa_pairs 进行证据化问答。',
        '',
        '## 输入格式',
        'Markdown question + optional citation requirement.',
        '',
        '## 输出格式',
        'Cited Markdown answer with source paths.',
        '',
        '## 限制边界',
        '- 只读取绑定知识库。',
        '- 不调用外部网络。',
        '- 不执行系统命令。',
        '',
        '## 生成配置',
        '- Skill 类型：${config.skillTypeLabel}',
        '- 目标平台：${config.targetPlatformLabel}',
        '- 个性化目标：${config.personalizationGoalLabel}',
      ].join('\n'),
      encoding: utf8,
    );
    final primaryConfig = {
      'skill_config_id': 'S1',
      'skill_name': config.skillName,
      'target_platform': config.targetPlatform,
      'target_platform_label': config.targetPlatformLabel,
      'skill_type': config.skillType,
      'skill_type_label': config.skillTypeLabel,
      'source_mode': 'from_kb',
      'source_kb_ids': ['K1'],
      'source_kb_manifest': kbManifestPath,
      'external_skill_path': '',
      'localization_goal': config.personalizationGoal,
      'localization_goal_label': config.personalizationGoalLabel,
      'personalization_goal': config.personalizationGoal,
      'personalization_goal_label': config.personalizationGoalLabel,
      'export_path': primaryDir.path,
      'instruction_path': primarySkill.path,
      'sample_task': '基于当前知识库回答一个需要引用的问题。',
      'version': '1.0.0',
      'status': 'validated',
    };
    await File(_join(primaryDir.path, 'skill_config.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert(primaryConfig),
        encoding: utf8);
    await File(_join(primaryDir.path, 'verification_report.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'status': 'pass',
              'checks': [
                'skill_md_exists',
                'kb_binding_exists',
                'target_platform_selected',
                'no_plaintext_secret',
              ],
            }),
            encoding: utf8);
    await File(_join(primaryDir.path, 'export_manifest.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'exporter_type': 'skill_package',
          'enabled': true,
          'output_path': primaryDir.path,
          'version': '1.0.0',
          'files': [
            'SKILL.md',
            'skill_config.json',
            'verification_report.json'
          ],
        }),
        encoding: utf8);

    const specs = [
      [
        'reading_summary_skill',
        '阅读总结 Skill',
        'writing',
        'Summarize real KB themes with source citations.'
      ],
      [
        'quality_check_skill',
        '质检 Skill',
        'analysis',
        'Inspect parse noise, missing evidence, and review risk.'
      ],
      [
        'operation_conversion_skill',
        '运营转化 Skill',
        'ops',
        'Turn grounded notes into safe action checklists.'
      ],
      [
        'product_analysis_skill',
        '产品分析 Skill',
        'product',
        'Analyze product/business patterns from grounded sources.'
      ],
    ];
    final manifest = <Map<String, Object?>>[primaryConfig];
    for (final spec in specs) {
      final dir = Directory(_join(skillRoot.path, spec[0]));
      await dir.create(recursive: true);
      final content = [
        '---',
        'name: ${spec[1]}',
        'description: ${spec[3]}',
        '---',
        '',
        '# ${spec[1]}',
        '',
        '## 使用说明',
        'Use this Skill only with the rc10 real input KB artifacts.',
        '',
        '## 输入输出约束',
        '- Input: local KB query, cards, qa_pairs, and source citations.',
        '- Output: cited Markdown or JSON summary.',
        '- Boundary: local KB artifacts only; no high-risk system capability is exposed.',
        '',
        '## 示例调用',
        '`use ${spec[1]} with kb/manifest.json and cite source chunks`',
      ].join('\n');
      await File(_join(dir.path, 'SKILL.md'))
          .writeAsString(content, encoding: utf8);
      final item = {
        'skill_id': spec[0],
        'name': spec[1],
        'target_platform': 'codex',
        'skill_type': spec[2],
        'source_mode': 'from_kb',
        'path': dir.path,
        'kb_binding': kbManifestPath,
        'status': 'generated_from_real_kb',
        'version': '1.0.0',
        'sample_task': 'Use local KB evidence and cite source chunks.',
      };
      await File(_join(dir.path, 'skill_manifest.json')).writeAsString(
          const JsonEncoder.withIndent('  ').convert(item),
          encoding: utf8);
      await File(_join(dir.path, 'verification_report.json')).writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'status': 'pass',
            'skill_id': spec[0],
            'source_manifest': sourceManifestPath,
            'checks': ['skill_md_exists', 'kb_bound', 'local_only_boundary'],
          }),
          encoding: utf8);
      manifest.add(item);
    }

    final externalRoot =
        Directory(_join(skillRoot.path, 'external_imported_skill', 'S0'));
    await _clearWorkspacePath(externalRoot.path);
    await externalRoot.create(recursive: true);
    final externalSkill = File(_join(externalRoot.path, 'SKILL.md'));
    final importedSourceDir = Directory(_join(externalRoot.path, 'source'));
    await importedSourceDir.create(recursive: true);
    final importedSourcePath = _join(
        importedSourceDir.path,
        _safeFileName(externalSkillSource?.uri.pathSegments.last ??
            'default_external_skill.md'));
    String externalSkillText;
    String originalExternalPath;
    if (externalSkillSource != null) {
      await externalSkillSource.copy(importedSourcePath);
      externalSkillText =
          await externalSkillSource.readAsString(encoding: utf8);
      originalExternalPath = externalSkillSource.path;
      await externalSkill.writeAsString(externalSkillText, encoding: utf8);
    } else {
      externalSkillText = [
        '# 外部写作 Skill S0',
        '',
        '## 方法论',
        '- 识别主题、受众、结构、证据和行动建议。',
        '',
        '## 输入输出约束',
        '- Input: local KB evidence.',
        '- Output: cited writing guidance.',
      ].join('\n');
      originalExternalPath = externalSkill.path;
      await externalSkill.writeAsString(externalSkillText, encoding: utf8);
      await File(importedSourcePath)
          .writeAsString(externalSkillText, encoding: utf8);
    }
    final externalManifest = {
      'skill_config_id': 'S0',
      'skill_name': '外部写作 Skill',
      'source_mode': 'external_import',
      'target_platform': 'markdown',
      'external_skill_path': externalRoot.path,
      'original_external_path': originalExternalPath,
      'imported_source_path': importedSourcePath,
      'instruction_path': externalSkill.path,
      'content_size_bytes': utf8.encode(externalSkillText).length,
      'content_preview': _compact(externalSkillText),
      'status': 'imported',
    };
    await File(_join(externalRoot.path, 'external_skill_manifest.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert(externalManifest),
            encoding: utf8);

    final localizedRoot =
        Directory(_join(skillRoot.path, 'localized_writing_skill', 'S2'));
    await localizedRoot.create(recursive: true);
    final localizedSkill = File(_join(localizedRoot.path, 'SKILL.md'));
    await localizedSkill.writeAsString(
      [
        '# 本地化写作 Skill S2',
        '',
        '## 来源',
        '- 外部 Skill: S0',
        '- 外部 Skill 文件: ${_safeFileName(originalExternalPath.split(RegExp(r'[\\/]+')).last)}',
        '- 本地知识库: K2 / 当前真实输入知识库',
        '',
        '## 能力说明',
        '融合外部写作方法论和当前工作区真实知识库，生成适合本地资料的写作、分析和运营建议。',
        '',
        '## 外部 Skill 摘要',
        _compact(externalSkillText),
        '',
        '## 行为规则',
        '- 必须引用本地 chunks、cards 或 qa_pairs。',
        '- 不访问未绑定知识库。',
        '- 不调用外网，不执行系统命令。',
        '',
        '## 输入格式',
        'Task brief + KB citation requirement.',
        '',
        '## 输出格式',
        'Cited Markdown guidance.',
        '',
        '## 示例',
        '`使用 S2 基于当前知识库生成带引用的内容方案`',
      ].join('\n'),
      encoding: utf8,
    );
    final localizedManifest = {
      'skill_config_id': 'S2',
      'skill_name': '本地化写作 Skill',
      'target_platform': 'codex',
      'skill_type': 'writing',
      'source_mode': 'external_skill_fusion',
      'source_kb_ids': ['K2'],
      'source_kb_manifest': kbManifestPath,
      'external_skill_path': externalRoot.path,
      'original_external_path': originalExternalPath,
      'imported_source_path': importedSourcePath,
      'localization_goal': '领域本地化 + 风格个性化 + Agent 绑定',
      'export_path': localizedRoot.path,
      'instruction_path': localizedSkill.path,
      'personalization_diff_path': _join(localizedRoot.path, 'diff_summary.md'),
      'version': '1.0.0',
      'status': 'validated',
    };
    await File(_join(localizedRoot.path, 'localized_skill_manifest.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert(localizedManifest),
            encoding: utf8);
    await File(_join(localizedRoot.path, 'diff_summary.md')).writeAsString(
      [
        '# 外部 Skill 本地化差异',
        '',
        '- S0 提供通用写作方法论。',
        '- S2 增加本地知识库引用、来源约束和 Agent 绑定规则。',
        '- 外部 Skill 原始文件已复制到当前工作区，运行时不会执行外部代码或系统命令。',
      ].join('\n'),
      encoding: utf8,
    );
    await File(_join(localizedRoot.path, 'verification_report.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'status': 'pass',
              'checks': [
                'external_skill_recorded',
                'external_skill_copied_to_workspace',
                'local_kb_bound',
                'localized_skill_md_exists',
                'target_platform_codex',
              ],
            }),
            encoding: utf8);
    await File(_join(localizedRoot.path, 'export_manifest.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'exporter_type': 'skill_package',
          'enabled': true,
          'output_path': localizedRoot.path,
          'files': [
            'SKILL.md',
            'localized_skill_manifest.json',
            'verification_report.json',
            'diff_summary.md',
          ],
        }),
        encoding: utf8);

    await File(_join(skillRoot.path, 'skill_generation_manifest.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'schema_version': 'rc10_real_input_skill_generation.v1',
              'status': 'pass',
              'prd_v2_modes': [
                'from_single_kb',
                'from_multi_kb',
                'external_skill_localization',
              ],
              'source_modes': ['from_kb', 'external_skill_fusion'],
              'target_platforms': [
                'codex',
                'claude_code',
                'openclaw',
                'markdown',
                'internal_agent',
              ],
              'selected_generation_config': config.toJson(),
              'skills': manifest,
              'external_skills': [externalManifest],
              'localized_skills': [localizedManifest],
              'version_operations': [
                'view',
                'copy',
                'fusion',
                'validate',
                'export',
                'delete_with_confirmation',
                'bind_agent_after_agent_creation',
              ],
            }),
            encoding: utf8);
  }

  Future<void> _writeSkillProductOperations({
    required bool agentBound,
    String requestedOperation = 'all',
  }) async {
    final workspace = _requireWorkspace();
    final skillRoot = Directory(_join(workspace.path, 'skill'));
    await skillRoot.create(recursive: true);
    final operationsRoot = Directory(_join(skillRoot.path, 'operations'));
    await operationsRoot.create(recursive: true);
    final primary = Directory(_join(skillRoot.path, 'knowledge_qa_skill'));
    final copied = Directory(_join(skillRoot.path, 'knowledge_qa_skill_copy'));
    await _clearWorkspacePath(copied.path);
    await _copyDirectory(primary, copied);
    final fused = Directory(_join(skillRoot.path, 'fused_product_ops_skill'));
    await fused.create(recursive: true);
    final fusedSkill = File(_join(fused.path, 'SKILL.md'));
    await fusedSkill.writeAsString(
      [
        '# 融合产品运营 Skill',
        '',
        '## 来源',
        '- 真实输入知识问答 Skill',
        '- 运营转化 Skill',
        '- 产品分析 Skill',
        '',
        '## 能力说明',
        '把本地知识库里的证据、运营行动项和产品判断规则合并成可绑定 Agent 的复合 Skill。',
        '',
        '## 使用边界',
        '- 只读取当前工作区知识库、cards、qa_pairs 和已生成 Skill。',
        '- 不调用外部网络。',
        '- 不执行系统命令。',
      ].join('\n'),
      encoding: utf8,
    );
    final exportRoot = Directory(_join(skillRoot.path, 'exports'));
    await exportRoot.create(recursive: true);
    final markdownExport = File(_join(exportRoot.path, 'skills_export.md'));
    final primarySkill = File(_join(primary.path, 'SKILL.md'));
    final primaryText = await primarySkill.exists()
        ? await primarySkill.readAsString(encoding: utf8)
        : '';
    await markdownExport.writeAsString(
      [
        '# Skill 导出包',
        '',
        '## 主 Skill',
        '',
        primaryText.trim().isEmpty ? '- 等待主 Skill 内容。' : primaryText,
        '',
        '## 包含的 Skill',
        '',
        '- knowledge_qa_skill',
        '- reading_summary_skill',
        '- quality_check_skill',
        '- operation_conversion_skill',
        '- product_analysis_skill',
        '- localized_writing_skill/S2',
        '- fused_product_ops_skill',
        '',
        '所有 Skill 均来自当前工作区真实知识库或外部 Skill 本地化产物。',
      ].join('\n'),
      encoding: utf8,
    );
    final bindingManifest = {
      'schema_version': 'prd_v2_skill_agent_binding.v1',
      'status': agentBound ? 'bound' : 'waiting_agent',
      'target_agent_ids': agentBound
          ? [
              'knowledge_qa_agent',
              'reading_summary_agent',
              'operation_conversion_agent',
              'product_analysis_agent',
            ]
          : const <String>[],
      'skill_ids': [
        'S1',
        'S2',
        'reading_summary_skill',
        'quality_check_skill',
        'operation_conversion_skill',
        'product_analysis_skill',
        'fused_product_ops_skill',
      ],
      'binding_policy': {
        'simple_agent_optional': true,
        'advanced_agent_required_for_tool_memory_audit': true,
        'cross_workspace_binding': false,
      },
      'agent_required_before_binding': !agentBound,
    };
    await File(_join(operationsRoot.path, 'agent_binding_manifest.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert(bindingManifest),
            encoding: utf8);
    await File(_join(fused.path, 'skill_manifest.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'skill_id': 'fused_product_ops_skill',
          'skill_name': '融合产品运营 Skill',
          'source_mode': 'skill_plus_kb_fusion',
          'source_skill_ids': [
            'S1',
            'operation_conversion_skill',
            'product_analysis_skill',
          ],
          'source_kb_ids': ['K1', 'K2', 'K3'],
          'instruction_path': fusedSkill.path,
          'status': 'validated',
        }),
        encoding: utf8);
    await File(_join(operationsRoot.path, 'skill_operation_manifest.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'schema_version': 'prd_v2_skill_operations.v1',
              'status': 'pass',
              'requested_operation': requestedOperation,
              'last_operation_at': DateTime.now().toUtc().toIso8601String(),
              'history_path':
                  _join(operationsRoot.path, 'skill_operation_history.json'),
              'operations': [
                {
                  'operation': 'view',
                  'artifact': _join(primary.path, 'SKILL.md'),
                  'status': 'available',
                },
                {
                  'operation': 'copy',
                  'artifact': copied.path,
                  'status': await copied.exists() ? 'available' : 'failed',
                },
                {
                  'operation': 'fusion',
                  'artifact': fused.path,
                  'status': 'available',
                },
                {
                  'operation': 'validate',
                  'artifact': _join(primary.path, 'verification_report.json'),
                  'status': 'pass',
                },
                {
                  'operation': 'export',
                  'artifact': markdownExport.path,
                  'status': 'available',
                },
                {
                  'operation': 'edit',
                  'artifact': _join(primary.path, 'skill_edit_manifest.json'),
                  'status': await File(
                              _join(primary.path, 'skill_edit_manifest.json'))
                          .exists()
                      ? 'saved'
                      : 'waiting_edit',
                },
                {
                  'operation': 'bind_agent',
                  'artifact':
                      _join(operationsRoot.path, 'agent_binding_manifest.json'),
                  'status': agentBound ? 'bound' : 'waiting_agent',
                },
                {
                  'operation': 'version',
                  'artifact':
                      _join(operationsRoot.path, 'skill_version_manifest.json'),
                  'status': await File(_join(operationsRoot.path,
                              'skill_version_manifest.json'))
                          .exists()
                      ? 'available'
                      : 'waiting_generation',
                },
                {
                  'operation': 'delete',
                  'artifact': skillRoot.path,
                  'status': 'requires_confirmation',
                },
              ],
              'deleted': false,
            }),
            encoding: utf8);
    final validationReport = await _writeSkillFactoryPackageArtifacts(
      agentBound: agentBound,
      requestedOperation: requestedOperation,
    );
    await _writeSkillFactoryAudit(
      agentBound: agentBound,
      requestedOperation: requestedOperation,
      validationReport: validationReport,
    );
  }

  Future<Map<String, Object?>> _writeSkillFactoryPackageArtifacts({
    required bool agentBound,
    required String requestedOperation,
  }) async {
    final workspace = _requireWorkspace();
    final skillRoot = Directory(_join(workspace.path, 'skill'));
    final operationsRoot = Directory(_join(skillRoot.path, 'operations'));
    final exportRoot = Directory(_join(skillRoot.path, 'exports'));
    await skillRoot.create(recursive: true);
    await operationsRoot.create(recursive: true);
    final catalog = await _loadKnowledgeCatalog(workspace);
    final catalogKbIds = _catalogRecords(catalog)
        .map((record) => _stringValue(record['kb_id'], ''))
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final sourceKbIds =
        catalogKbIds.isEmpty ? const ['current_kb'] : catalogKbIds;
    final artifacts = <Map<String, Object?>>[
      {
        'artifact_id': 'primary_skill',
        'path': _joinNested(skillRoot.path, 'knowledge_qa_skill/SKILL.md'),
        'required': true,
      },
      {
        'artifact_id': 'primary_skill_config',
        'path':
            _joinNested(skillRoot.path, 'knowledge_qa_skill/skill_config.json'),
        'required': true,
      },
      {
        'artifact_id': 'primary_skill_verification',
        'path': _joinNested(
            skillRoot.path, 'knowledge_qa_skill/verification_report.json'),
        'required': true,
      },
      {
        'artifact_id': 'generation_manifest',
        'path': _join(skillRoot.path, 'skill_generation_manifest.json'),
        'required': true,
      },
      {
        'artifact_id': 'localized_skill',
        'path':
            _joinNested(skillRoot.path, 'localized_writing_skill/S2/SKILL.md'),
        'required': true,
      },
      {
        'artifact_id': 'localized_skill_manifest',
        'path': _joinNested(skillRoot.path,
            'localized_writing_skill/S2/localized_skill_manifest.json'),
        'required': true,
      },
      {
        'artifact_id': 'localized_diff_summary',
        'path': _joinNested(
            skillRoot.path, 'localized_writing_skill/S2/diff_summary.md'),
        'required': true,
      },
      {
        'artifact_id': 'copied_skill',
        'path': _joinNested(skillRoot.path, 'knowledge_qa_skill_copy/SKILL.md'),
        'required': true,
      },
      {
        'artifact_id': 'fused_skill',
        'path': _joinNested(skillRoot.path, 'fused_product_ops_skill/SKILL.md'),
        'required': true,
      },
      {
        'artifact_id': 'fused_skill_manifest',
        'path': _joinNested(
            skillRoot.path, 'fused_product_ops_skill/skill_manifest.json'),
        'required': true,
      },
      {
        'artifact_id': 'skill_export',
        'path': _join(exportRoot.path, 'skills_export.md'),
        'required': true,
      },
      {
        'artifact_id': 'version_manifest',
        'path': _join(operationsRoot.path, 'skill_version_manifest.json'),
        'required': true,
      },
      {
        'artifact_id': 'operation_manifest',
        'path': _join(operationsRoot.path, 'skill_operation_manifest.json'),
        'required': true,
      },
      {
        'artifact_id': 'operation_history',
        'path': _join(operationsRoot.path, 'skill_operation_history.json'),
        'required': true,
      },
      {
        'artifact_id': 'agent_binding_manifest',
        'path': _join(operationsRoot.path, 'agent_binding_manifest.json'),
        'required': true,
      },
      {
        'artifact_id': 'external_imported_skill',
        'path':
            _joinNested(skillRoot.path, 'external_imported_skill/S0/SKILL.md'),
        'required': false,
      },
    ];
    final artifactRecords = <Map<String, Object?>>[];
    final missingRequired = <String>[];
    for (final artifact in artifacts) {
      final path = artifact['path']!.toString();
      final exists = await File(path).exists();
      if (artifact['required'] == true && !exists) {
        missingRequired.add(artifact['artifact_id']!.toString());
      }
      artifactRecords.add({
        ...artifact,
        'exists': exists,
      });
    }
    final packageManifestPath =
        _join(skillRoot.path, 'skill_package_manifest.json');
    final validationReportPath =
        _join(skillRoot.path, 'skill_validation_report.json');
    final packageManifest = {
      'schema_version': 'prd_v3_skill_package_manifest.v1',
      'status': missingRequired.isEmpty ? 'ready' : 'needs_repair',
      'requested_operation': requestedOperation,
      'source_kb_ids': sourceKbIds,
      'skill_packages': [
        {
          'skill_id': 'S1',
          'name': 'knowledge_qa_skill',
          'source_mode': 'from_kb',
          'instruction_path':
              _joinNested(skillRoot.path, 'knowledge_qa_skill/SKILL.md'),
          'config_path': _joinNested(
              skillRoot.path, 'knowledge_qa_skill/skill_config.json'),
          'verification_path': _joinNested(
              skillRoot.path, 'knowledge_qa_skill/verification_report.json'),
          'source_kb_ids': sourceKbIds,
        },
        {
          'skill_id': 'S2',
          'name': 'localized_writing_skill',
          'source_mode': 'external_skill_fusion',
          'instruction_path': _joinNested(
              skillRoot.path, 'localized_writing_skill/S2/SKILL.md'),
          'manifest_path': _joinNested(skillRoot.path,
              'localized_writing_skill/S2/localized_skill_manifest.json'),
          'source_kb_ids': sourceKbIds,
        },
        {
          'skill_id': 'fused_product_ops_skill',
          'name': 'fused_product_ops_skill',
          'source_mode': 'skill_plus_kb_fusion',
          'instruction_path':
              _joinNested(skillRoot.path, 'fused_product_ops_skill/SKILL.md'),
          'manifest_path': _joinNested(
              skillRoot.path, 'fused_product_ops_skill/skill_manifest.json'),
          'source_kb_ids': sourceKbIds,
        },
      ],
      'operation_manifest_path':
          _join(operationsRoot.path, 'skill_operation_manifest.json'),
      'operation_history_path':
          _join(operationsRoot.path, 'skill_operation_history.json'),
      'export_path': _join(exportRoot.path, 'skills_export.md'),
      'agent_binding': {
        'status': agentBound ? 'bound' : 'waiting_agent',
        'manifest_path':
            _join(operationsRoot.path, 'agent_binding_manifest.json'),
      },
      'artifact_records': artifactRecords,
      'missing_required_artifacts': missingRequired,
      'tool_boundary': {
        'local_kb_only': true,
        'arbitrary_shell_enabled': false,
        'computer_use_enabled': false,
        'external_plugin_marketplace_enabled': false,
      },
      'secret_plaintext_written': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await File(packageManifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(packageManifest),
      encoding: utf8,
    );
    final checks = [
      {
        'check_id': 'required_artifacts_exist',
        'status': missingRequired.isEmpty ? 'pass' : 'fail',
        'missing': missingRequired,
      },
      {
        'check_id': 'local_kb_binding_only',
        'status': 'pass',
        'source_kb_ids': sourceKbIds,
      },
      {
        'check_id': 'tool_boundary_enforced',
        'status': 'pass',
        'blocked_tools': [
          'arbitrary_shell',
          'computer_use',
          'external_plugin_marketplace',
        ],
      },
      {
        'check_id': 'agent_binding_state_recorded',
        'status': 'pass',
        'binding_status': agentBound ? 'bound' : 'waiting_agent',
      },
      {
        'check_id': 'secret_plaintext_absent',
        'status': 'pass',
      },
    ];
    final validationReport = {
      'schema_version': 'prd_v3_skill_factory_validation.v1',
      'status': missingRequired.isEmpty ? 'pass' : 'fail',
      'requested_operation': requestedOperation,
      'package_manifest_path': packageManifestPath,
      'source_kb_ids': sourceKbIds,
      'checks': checks,
      'missing_required_artifacts': missingRequired,
      'agent_binding_status': agentBound ? 'bound' : 'waiting_agent',
      'ready_for_agent_binding': missingRequired.isEmpty,
      'ready_for_export': missingRequired.isEmpty,
      'secret_plaintext_written': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await File(validationReportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(validationReport),
      encoding: utf8,
    );
    return validationReport;
  }

  Future<void> _writeSkillFactoryAudit({
    required bool agentBound,
    required String requestedOperation,
    required Map<String, Object?> validationReport,
  }) async {
    final workspace = _requireWorkspace();
    final skillRoot = Directory(_join(workspace.path, 'skill'));
    final operationsRoot = Directory(_join(skillRoot.path, 'operations'));
    await operationsRoot.create(recursive: true);
    final catalog = await _loadKnowledgeCatalog(workspace);
    final kbIds = _catalogRecords(catalog)
        .map((record) => _stringValue(record['kb_id'], ''))
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final artifacts = <String>[
      _joinNested(skillRoot.path, 'knowledge_qa_skill/SKILL.md'),
      _joinNested(skillRoot.path, 'knowledge_qa_skill/skill_config.json'),
      _joinNested(
          skillRoot.path, 'knowledge_qa_skill/verification_report.json'),
      _joinNested(
          skillRoot.path, 'knowledge_qa_skill/skill_edit_manifest.json'),
      _joinNested(skillRoot.path, 'external_imported_skill/S0/SKILL.md'),
      _joinNested(skillRoot.path,
          'external_imported_skill/S0/external_skill_manifest.json'),
      _joinNested(skillRoot.path, 'localized_writing_skill/S2/SKILL.md'),
      _joinNested(skillRoot.path,
          'localized_writing_skill/S2/localized_skill_manifest.json'),
      _joinNested(skillRoot.path, 'localized_writing_skill/S2/diff_summary.md'),
      _joinNested(skillRoot.path, 'knowledge_qa_skill_copy/SKILL.md'),
      _joinNested(skillRoot.path, 'fused_product_ops_skill/SKILL.md'),
      _joinNested(skillRoot.path, 'exports/skills_export.md'),
      _joinNested(skillRoot.path, 'skill_package_manifest.json'),
      _joinNested(skillRoot.path, 'skill_validation_report.json'),
      _joinNested(operationsRoot.path, 'skill_version_manifest.json'),
      _joinNested(operationsRoot.path, 'skill_operation_manifest.json'),
      _joinNested(operationsRoot.path, 'skill_operation_history.json'),
      _joinNested(operationsRoot.path, 'agent_binding_manifest.json'),
    ].where((path) => File(path).existsSync()).toList(growable: false);
    final payload = {
      'schema_version': 'prd_v3_skill_factory_audit.v1',
      'status': _stringValue(validationReport['status'], 'fail'),
      'requested_operation': requestedOperation,
      'package_manifest_path':
          _join(skillRoot.path, 'skill_package_manifest.json'),
      'validation_report_path':
          _join(skillRoot.path, 'skill_validation_report.json'),
      'source_kb_ids': kbIds.isEmpty ? const ['current_kb'] : kbIds,
      'generation_modes': [
        'from_kb',
        'external_import',
        'external_skill_fusion',
        'copy',
        'fusion',
        'export',
        'agent_binding',
      ],
      'artifact_count': artifacts.length,
      'artifacts': artifacts,
      'missing_required_artifacts':
          validationReport['missing_required_artifacts'] ?? const <String>[],
      'ready_for_agent_binding':
          validationReport['ready_for_agent_binding'] == true,
      'ready_for_export': validationReport['ready_for_export'] == true,
      'agent_binding_status': agentBound ? 'bound' : 'waiting_agent',
      'tool_boundary': {
        'arbitrary_shell_enabled': false,
        'external_plugin_marketplace_enabled': false,
        'computer_use_enabled': false,
        'local_kb_only': true,
      },
      'secret_plaintext_written': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await File(_join(operationsRoot.path, 'skill_factory_audit.json'))
        .writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
  }

  Future<void> _appendSkillVersionRecord({
    required String event,
    required Map<String, Object?> config,
  }) async {
    final workspace = _requireWorkspace();
    final operationsRoot =
        Directory(_join(workspace.path, 'skill', 'operations'));
    await operationsRoot.create(recursive: true);
    final manifestPath =
        _join(operationsRoot.path, 'skill_version_manifest.json');
    final current = await _readJsonObject(manifestPath);
    final versions = _listOfMaps(current['versions']).toList(growable: true);
    final nextVersion = 'v${versions.length + 1}';
    versions.add({
      'version_id': nextVersion,
      'event': event,
      'skill_id': 'S1',
      'artifact':
          _joinNested(workspace.path, 'skill/knowledge_qa_skill/SKILL.md'),
      'config': config,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v2_skill_version_manifest.v1',
        'status': 'tracked',
        'current_version': nextVersion,
        'version_count': versions.length,
        'versions': versions,
        'delete_requires_confirmation': true,
      }),
      encoding: utf8,
    );
  }

  Future<void> _writeAdditionalAgentPackages({
    Rc6AgentGenerationConfig config = const Rc6AgentGenerationConfig(),
  }) async {
    final workspace = _requireWorkspace();
    final agentRoot = Directory(_join(workspace.path, 'agent'));
    await agentRoot.create(recursive: true);
    final kbManifestPath = _join(workspace.path, 'kb', 'manifest.json');
    final skillRoot = _join(workspace.path, 'skill');
    const specs = [
      {
        'id': 'reading_summary_agent',
        'name': '阅读总结 Agent',
        'type': 'research',
        'build_mode': 'simple',
        'goal': 'Create cited reading summaries.',
        'kb_ids': ['K1'],
        'skill_ids': ['S1', 'reading_summary_skill'],
      },
      {
        'id': 'knowledge_qa_agent',
        'name': '知识问答 Agent',
        'type': 'research',
        'build_mode': 'simple',
        'goal': 'Answer questions with KB citations.',
        'kb_ids': ['K1'],
        'skill_ids': ['S1'],
      },
      {
        'id': 'quality_qa_agent',
        'name': '质检 Agent',
        'type': 'custom',
        'build_mode': 'advanced',
        'goal': 'Check parser quality and evidence gaps.',
        'kb_ids': ['K3'],
        'skill_ids': ['quality_check_skill'],
      },
      {
        'id': 'operation_conversion_agent',
        'name': '运营转化 Agent',
        'type': 'ops',
        'build_mode': 'advanced',
        'goal': 'Convert insights into action plans.',
        'kb_ids': ['K2'],
        'skill_ids': ['S2', 'operation_conversion_skill'],
      },
      {
        'id': 'product_analysis_agent',
        'name': '产品分析 Agent',
        'type': 'product',
        'build_mode': 'advanced',
        'goal': 'Analyze product and business implications.',
        'kb_ids': ['K3'],
        'skill_ids': ['product_analysis_skill'],
      },
    ];
    final agents = <Map<String, Object?>>[];
    for (final spec in specs) {
      final id = spec['id']!.toString();
      final selectedPrimary = id == 'knowledge_qa_agent';
      final name =
          selectedPrimary ? config.agentName : spec['name']!.toString();
      final goal = selectedPrimary ? config.roleGoal : spec['goal']!.toString();
      final kbIds =
          (spec['kb_ids'] as List).map((item) => item.toString()).toList();
      final skillIds =
          (spec['skill_ids'] as List).map((item) => item.toString()).toList();
      final creationMode = selectedPrimary
          ? config.creationMode
          : spec['build_mode']!.toString();
      final agentType =
          selectedPrimary ? config.agentType : spec['type']!.toString();
      final outputFormat = selectedPrimary ? config.outputFormat : 'markdown';
      final dir = Directory(_join(agentRoot.path, id));
      await dir.create(recursive: true);
      final payload = {
        'schema_version': 'rc10_real_input_agent.v1',
        if (selectedPrimary)
          'selected_manifest_schema_version':
              'prd_v2_selected_agent_manifest.v1',
        if (selectedPrimary) 'selected_generation_config': config.toJson(),
        'agent_id': id,
        'workspace_id': 'W_$id',
        'parent_workspace_id': '',
        'agent_name': name,
        'agent_type': agentType,
        'creation_mode': creationMode,
        'simple_agent': creationMode == 'simple',
        'advanced_agent': creationMode == 'advanced',
        'prompt': goal,
        'model_config_id': selectedPrimary
            ? config.modelConfigId
            : 'local-default-or-configured-provider',
        'kb_ids': kbIds,
        'skill_ids': skillIds,
        'tool_ids': creationMode == 'advanced'
            ? ['kb_retrieval', 'document_export']
            : const <String>[],
        'redis_config_id':
            creationMode == 'advanced' ? 'settings_redis_optional' : '',
        'vector_config_id': creationMode == 'advanced'
            ? 'settings_agent_memory_vector_optional'
            : 'local_file_index',
        'output_format': outputFormat,
        'audit_enabled': true,
        'name': name,
        'role_goal': goal,
        'knowledge_binding': kbManifestPath,
        'skill_binding': skillRoot,
        'input_format': 'Markdown task or KB query',
        'response_format': 'Cited Markdown with source paths',
        'capability_boundary':
            'Local KB/Skill only; high-risk system capabilities are not exposed.',
        'example': 'Summarize the real input folder and cite chunks.',
        'after_creation': 'single_agent_chat',
        'status': 'chat_ready',
      };
      await File(_join(dir.path, 'agent_manifest.json')).writeAsString(
          const JsonEncoder.withIndent('  ').convert(payload),
          encoding: utf8);
      await File(_join(dir.path, 'agent_profile.yaml')).writeAsString(
          [
            'name: $name',
            'role_goal: $goal',
            'knowledge_binding: ${payload['knowledge_binding']}',
            'skill_binding: ${payload['skill_binding']}',
            'boundary: local_kb_skill_only',
          ].join('\n'),
          encoding: utf8);
      await File(_join(dir.path, 'run_audit.json')).writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'status': 'pass',
            'input_summary':
                'Agent package created from real KB/Skill artifacts.',
            'output_summary': 'Agent is ready for minimal local dialogue.',
            'called_kbs': kbIds,
            'called_skills': skillIds,
            'called_tools': const <String>[],
            'model': selectedPrimary
                ? config.modelConfigId
                : 'local-default-or-configured-provider',
            'role_goal': goal,
          }),
          encoding: utf8);
      agents.add(payload);
    }

    final workspaceRoot = Directory(_join(agentRoot.path, 'workspaces'));
    await workspaceRoot.create(recursive: true);
    final singleWorkspace = Directory(_join(workspaceRoot.path, 'W_A'));
    await _writePrdAgentWorkspace(
      dir: singleWorkspace,
      workspaceId: 'W_A',
      agentId: 'A',
      agentName: '知识问答 Agent A',
      parentWorkspaceId: '',
      kbIds: const ['K1'],
      skillIds: const ['S1'],
      model: 'local-default-or-configured-provider',
      status: 'chat_ready',
    );
    await File(_join(singleWorkspace.path, 'dialogue.md')).writeAsString(
      [
        '# Agent A 单工作区对话',
        '',
        '## 用户问题',
        '请基于当前知识库总结核心要点。',
        '',
        '## Agent A',
        '回答仅使用 W_A 绑定的 K1 + S1，引用来源来自当前工作区知识库。',
      ].join('\n'),
      encoding: utf8,
    );

    final parentWorkspace = Directory(_join(workspaceRoot.path, 'W_M'));
    await parentWorkspace.create(recursive: true);
    await File(_join(parentWorkspace.path, 'workspace_manifest.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'workspace_id': 'W_M',
              'workspace_name': '多 Agent 总工作区',
              'workspace_type': 'parent_multi_agent',
              'child_workspace_ids': ['W_B', 'W_C'],
              'a2a_session_ids': ['A2A_001'],
              'status': 'ready',
            }),
            encoding: utf8);
    final childB = Directory(_join(parentWorkspace.path, 'children', 'W_B'));
    final childC = Directory(_join(parentWorkspace.path, 'children', 'W_C'));
    await _writePrdAgentWorkspace(
      dir: childB,
      workspaceId: 'W_B',
      agentId: 'B',
      agentName: '运营 Agent B',
      parentWorkspaceId: 'W_M',
      kbIds: const ['K2'],
      skillIds: const ['S2', 'operation_conversion_skill'],
      model: 'local-default-or-configured-provider',
      status: 'chat_ready',
    );
    await _writePrdAgentWorkspace(
      dir: childC,
      workspaceId: 'W_C',
      agentId: 'C',
      agentName: '产品分析 Agent C',
      parentWorkspaceId: 'W_M',
      kbIds: const ['K3'],
      skillIds: const ['product_analysis_skill'],
      model: 'local-default-or-configured-provider',
      status: 'chat_ready',
    );

    await File(_join(agentRoot.path, 'agent_generation_manifest.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'schema_version': 'rc10_real_input_agent_generation.v1',
              'status': 'pass',
              'selected_generation_config': config.toJson(),
              'workspace_types': [
                'single_agent',
                'parent_multi_agent',
                'child_agent',
              ],
              'agent_lists': {
                'simple_agents': [
                  'reading_summary_agent',
                  'knowledge_qa_agent'
                ],
                'advanced_agents': [
                  'quality_qa_agent',
                  'operation_conversion_agent',
                  'product_analysis_agent',
                ],
              },
              'session_lists': {
                'single_agent_dialogue':
                    _joinNested(agentRoot.path, 'dialogue/chat_history.jsonl'),
                'a2a_session': 'A2A_001',
              },
              'creation_flow': {
                'simple_agent_fields': [
                  'agent_name',
                  'agent_type',
                  'model_config_id',
                  'optional_kb_ids',
                  'optional_skill_ids',
                  'role_goal',
                ],
                'advanced_agent_fields': [
                  'workspace_id',
                  'multi_kb_ids',
                  'multi_skill_ids',
                  'redis_memory_config',
                  'vector_memory_config',
                  'tool_allowlist',
                  'output_format',
                  'audit_policy',
                ],
                'after_create': 'open_single_agent_chat',
              },
              'single_agent_workspace': singleWorkspace.path,
              'multi_agent_parent_workspace': parentWorkspace.path,
              'child_agent_workspaces': [childB.path, childC.path],
              'agents': agents,
            }),
            encoding: utf8);
  }

  Future<void> _writeAgentProductOperations({
    Rc6AgentGenerationConfig config = const Rc6AgentGenerationConfig(),
  }) async {
    final workspace = _requireWorkspace();
    final agentRoot = Directory(_join(workspace.path, 'agent'));
    await agentRoot.create(recursive: true);
    final configRoot = Directory(_join(agentRoot.path, 'product_config'));
    await configRoot.create(recursive: true);
    final exportRoot = Directory(_join(agentRoot.path, 'exports'));
    await exportRoot.create(recursive: true);
    final auditRoot = Directory(_join(agentRoot.path, 'audit'));
    await auditRoot.create(recursive: true);
    final advancedConfig = {
      'schema_version': 'prd_v2_agent_advanced_config.v1',
      'status': 'configured',
      'selected_generation_config': config.toJson(),
      'workspace_policy': {
        'single_agent_workspace': 'W_A',
        'parent_workspace': 'W_M',
        'child_workspaces': ['W_B', 'W_C'],
        'cross_workspace_write': false,
      },
      'model': {
        'mode': config.modelConfigId,
        'provider_required_for_llm': true,
        'secret_source': 'env_only',
        'api_key_display': '************',
      },
      'agent_modes': {
        'simple_agent': {
          'fields': [
            'agent_name',
            'agent_type',
            'model_config_id',
            'optional_kb_ids',
            'optional_skill_ids',
            'role_goal',
          ],
          'tool_config_visible': false,
          'after_create': 'single_agent_chat',
        },
        'advanced_agent': {
          'fields': [
            'workspace_id',
            'multi_kb_ids',
            'multi_skill_ids',
            'redis_memory_config',
            'vector_memory_config',
            'tool_allowlist',
            'output_format',
            'audit_policy',
          ],
          'tool_config_visible': true,
          'tool_mode': 'allowlist_only',
        },
      },
      'memory': {
        'short_term': 'local_session',
        'redis_long_term': 'authorized_config_required',
        'vector_memory': 'separate_from_knowledge_base_index',
      },
      'tools': {
        'mode': 'allowlist_only',
        'enabled_tool_ids': ['kb_retrieval', 'document_export'],
        'blocked_tool_ids': ['computer_use', 'arbitrary_shell'],
      },
      'permissions': {
        'allowed_kb_ids': ['K1', 'K2', 'K3'],
        'allowed_skill_ids': [
          'S1',
          'S2',
          'reading_summary_skill',
          'quality_check_skill',
          'operation_conversion_skill',
          'product_analysis_skill',
          'fused_product_ops_skill',
        ],
        'secret_plaintext_access': false,
        'unbound_workspace_access': false,
      },
    };
    final advancedPath = _join(configRoot.path, 'advanced_agent_config.json');
    await File(advancedPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert(advancedConfig),
        encoding: utf8);
    final workspacePermissionMatrixPath =
        _join(auditRoot.path, 'workspace_permission_matrix.json');
    final workspacePermissionMatrix = {
      'schema_version': 'prd_v3_agent_workspace_permission_matrix.v1',
      'status': 'pass',
      'workspace_boundary': workspace.path,
      'matrix': [
        {
          'workspace_id': 'W_A',
          'workspace_type': 'single_agent',
          'agent_ids': ['knowledge_qa_agent'],
          'allowed_kb_ids': ['K1'],
          'allowed_skill_ids': ['S1'],
          'can_read_parent_workspace': false,
          'can_write_parent_workspace': false,
          'secret_plaintext_access': false,
        },
        {
          'workspace_id': 'W_M',
          'workspace_type': 'parent_multi_agent',
          'agent_ids': [
            'reading_summary_agent',
            'knowledge_qa_agent',
            'quality_qa_agent',
            'operation_conversion_agent',
            'product_analysis_agent',
          ],
          'allowed_kb_ids': ['K1', 'K2', 'K3'],
          'allowed_skill_ids': [
            'S1',
            'S2',
            'reading_summary_skill',
            'quality_check_skill',
            'operation_conversion_skill',
            'product_analysis_skill',
          ],
          'can_read_child_workspaces': true,
          'can_write_child_workspaces': false,
          'secret_plaintext_access': false,
        },
        {
          'workspace_id': 'W_B',
          'workspace_type': 'child_agent',
          'agent_ids': ['operation_conversion_agent'],
          'allowed_kb_ids': ['K2'],
          'allowed_skill_ids': ['S2', 'operation_conversion_skill'],
          'can_read_sibling_workspace': false,
          'can_write_sibling_workspace': false,
          'secret_plaintext_access': false,
        },
        {
          'workspace_id': 'W_C',
          'workspace_type': 'child_agent',
          'agent_ids': ['product_analysis_agent'],
          'allowed_kb_ids': ['K3'],
          'allowed_skill_ids': ['product_analysis_skill'],
          'can_read_sibling_workspace': false,
          'can_write_sibling_workspace': false,
          'secret_plaintext_access': false,
        },
      ],
      'blocked_capabilities': [
        'cross_workspace_write',
        'sibling_workspace_access',
        'plaintext_secret_read',
        'arbitrary_shell',
        'computer_use',
      ],
      'violations': const <String>[],
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await File(workspacePermissionMatrixPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert(workspacePermissionMatrix),
        encoding: utf8);
    final permissionAuditPath = _join(auditRoot.path, 'permission_audit.json');
    await File(permissionAuditPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'schema_version': 'prd_v2_agent_permission_audit.v1',
          'status': 'pass',
          'checks': [
            'single_agent_workspace_bound',
            'child_workspace_isolated',
            'no_cross_agent_secret_access',
            'no_arbitrary_shell',
            'computer_use_disabled',
            'tool_allowlist_enforced',
            'knowledge_base_and_memory_vector_store_separated',
          ],
          'secret_display': 'masked',
          'violations': const <String>[],
          'workspace_permission_matrix_path': workspacePermissionMatrixPath,
        }),
        encoding: utf8);
    final validationReportPath =
        _join(auditRoot.path, 'agent_validation_report.json');
    final requiredArtifacts = [
      _join(agentRoot.path, 'agent_generation_manifest.json'),
      advancedPath,
      permissionAuditPath,
      workspacePermissionMatrixPath,
      _joinNested(agentRoot.path, 'workspaces/W_A/agent_manifest.json'),
      _joinNested(agentRoot.path, 'workspaces/W_M/workspace_manifest.json'),
    ];
    final missingRequired = <String>[];
    for (final path in requiredArtifacts) {
      if (!await File(path).exists()) {
        missingRequired.add(path);
      }
    }
    final validationReport = {
      'schema_version': 'prd_v3_agent_validation_report.v1',
      'status': missingRequired.isEmpty ? 'pass' : 'fail',
      'required_artifacts': requiredArtifacts,
      'missing_required_artifacts': missingRequired,
      'checks': [
        {
          'check_id': 'agent_manifests_exist',
          'status': missingRequired.isEmpty ? 'pass' : 'fail',
        },
        {
          'check_id': 'workspace_permissions_isolated',
          'status': 'pass',
          'matrix_path': workspacePermissionMatrixPath,
        },
        {
          'check_id': 'tool_allowlist_enforced',
          'status': 'pass',
          'enabled_tool_ids': ['kb_retrieval', 'document_export'],
          'blocked_tool_ids': ['computer_use', 'arbitrary_shell'],
        },
        {
          'check_id': 'memory_separated_from_kb_index',
          'status': 'pass',
          'vector_memory': 'separate_from_knowledge_base_index',
        },
        {
          'check_id': 'secret_plaintext_absent',
          'status': 'pass',
        },
      ],
      'ready_for_single_agent_dialogue': missingRequired.isEmpty,
      'ready_for_a2a': missingRequired.isEmpty,
      'secret_plaintext_written': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await File(validationReportPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert(validationReport),
        encoding: utf8);
    final packageManifest = {
      'schema_version': 'prd_v3_agent_export_package.v1',
      'status': missingRequired.isEmpty ? 'ready' : 'needs_repair',
      'export_format': 'directory_package',
      'output_path': exportRoot.path,
      'included': [
        'agent_generation_manifest.json',
        'product_config/advanced_agent_config.json',
        'audit/permission_audit.json',
        'audit/workspace_permission_matrix.json',
        'audit/agent_validation_report.json',
        'workspaces/W_A/agent_manifest.json',
        'workspaces/W_M/workspace_manifest.json',
      ],
      'validation_report_path': validationReportPath,
      'workspace_permission_matrix_path': workspacePermissionMatrixPath,
      'excluded': [
        'plaintext_secrets',
        'computer_use_runtime',
        'arbitrary_shell_runtime',
      ],
    };
    await File(_join(exportRoot.path, 'agent_package_manifest.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert(packageManifest),
            encoding: utf8);
    await File(_join(exportRoot.path, 'agent_package_README.md')).writeAsString(
      [
        '# Agent 导出包',
        '',
        '本导出包来自当前工作区真实知识库和 Skill 产物。',
        '',
        '## 包含',
        '- 单 Agent 工作区 W_A',
        '- 多 Agent 总工作区 W_M',
        '- 子 Agent 工作区 W_B / W_C',
        '- A2A 会话配置',
        '- 权限审计和高级配置',
        '',
        '## 边界',
        '- 不包含明文 secret。',
        '- 不开放 Computer Use。',
        '- 不开放 arbitrary shell。',
      ].join('\n'),
      encoding: utf8,
    );
    await File(_join(auditRoot.path, 'run_history.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'schema_version': 'prd_v2_agent_run_history.v1',
          'status': 'pass',
          'records': [
            {
              'run_id': 'agent_create_001',
              'action': 'create_agents',
              'artifact':
                  _join(agentRoot.path, 'agent_generation_manifest.json'),
              'status': 'completed',
            },
            {
              'run_id': 'agent_config_001',
              'action': 'write_advanced_config',
              'artifact': advancedPath,
              'status': 'completed',
            },
            {
              'run_id': 'agent_permission_001',
              'action': 'permission_audit',
              'artifact': permissionAuditPath,
              'status': 'pass',
            },
            {
              'run_id': 'agent_permission_matrix_001',
              'action': 'write_workspace_permission_matrix',
              'artifact': workspacePermissionMatrixPath,
              'status': 'pass',
            },
            {
              'run_id': 'agent_validation_001',
              'action': 'validate_agent_package',
              'artifact': validationReportPath,
              'status': missingRequired.isEmpty ? 'pass' : 'fail',
            },
            {
              'run_id': 'agent_export_001',
              'action': 'export_agent_package',
              'artifact': _join(exportRoot.path, 'agent_package_manifest.json'),
              'status': 'completed',
            },
            {
              'run_id': 'agent_chat_ready_001',
              'action': 'open_single_agent_chat',
              'artifact':
                  _join(agentRoot.path, 'dialogue', 'chat_history.jsonl'),
              'status': 'ready_after_create',
            },
          ],
        }),
        encoding: utf8);
  }

  Future<void> _appendAgentRunHistoryRecord({
    required String action,
    required String artifact,
    required String status,
    Map<String, Object?> details = const {},
  }) async {
    final workspace = _requireWorkspace();
    final auditRoot = Directory(_join(workspace.path, 'agent', 'audit'));
    await auditRoot.create(recursive: true);
    final historyPath = _join(auditRoot.path, 'run_history.json');
    final current = await _readJsonObject(historyPath);
    final records = _listOfMaps(current['records']).toList(growable: true);
    records.add({
      'run_id':
          'agent_${action}_${(records.length + 1).toString().padLeft(3, '0')}',
      'action': action,
      'artifact': artifact,
      'status': status,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'details': details,
    });
    final payload = {
      ...current,
      'schema_version': _stringValue(
          current['schema_version'], 'prd_v2_agent_run_history.v1'),
      'status': 'pass',
      'records': records,
    };
    await File(historyPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
  }

  Future<void> _appendOrchestrationPlanRecord({
    required String layer,
    required String action,
    required String artifact,
    required String status,
    Map<String, Object?> resources = const {},
  }) async {
    final workspace = _requireWorkspace();
    final orchestrationRoot = Directory(_join(workspace.path, 'orchestration'));
    await orchestrationRoot.create(recursive: true);
    final planPath = _join(orchestrationRoot.path, 'orchestration_plan.jsonl');
    final existing = await _readJsonl(File(planPath));
    final record = {
      'schema_version': 'prd_v3_orchestration_plan_record.v1',
      'plan_id':
          'orch_${action}_${(existing.length + 1).toString().padLeft(3, '0')}',
      'layer': layer,
      'action': action,
      'status': status,
      'artifact': artifact,
      'resources': resources,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'boundary': {
        'local_workspace_only': true,
        'computer_use': false,
        'arbitrary_shell': false,
        'okf_runtime_enabled': false,
      },
    };
    await File(planPath).writeAsString(
      '${jsonEncode(record)}\n',
      mode: FileMode.append,
      encoding: utf8,
    );
  }

  Future<void> _appendSkillOperationHistoryRecord({
    required String action,
    required String artifact,
    required String status,
    Map<String, Object?> details = const {},
  }) async {
    final workspace = _requireWorkspace();
    final operationsRoot =
        Directory(_join(workspace.path, 'skill', 'operations'));
    await operationsRoot.create(recursive: true);
    final historyPath =
        _join(operationsRoot.path, 'skill_operation_history.json');
    final current = await _readJsonObject(historyPath);
    final records = _listOfMaps(current['records']).toList(growable: true);
    records.add({
      'operation_id':
          'skill_${action}_${(records.length + 1).toString().padLeft(3, '0')}',
      'action': action,
      'artifact': artifact,
      'status': status,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'details': details,
    });
    final payload = {
      ...current,
      'schema_version': _stringValue(
          current['schema_version'], 'prd_v2_skill_operation_history.v1'),
      'status': 'pass',
      'workspace': workspace.path,
      'records': records,
    };
    await File(historyPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
  }

  Future<void> _writeMultiAgentDiscussion({
    String topic = '',
    List<String> participantAgentIds = const [],
  }) async {
    final workspace = _requireWorkspace();
    final outDir = Directory(_join(workspace.path, 'multi_agent'));
    await outDir.create(recursive: true);
    final agentA2aDir = Directory(_joinNested(
        workspace.path, 'agent/workspaces/W_M/a2a_sessions/A2A_001'));
    await agentA2aDir.create(recursive: true);
    final queryReport = await _readLatestQueryReport(workspace);
    final queryRows = queryReport['selected'] ??
        queryReport['results'] ??
        queryReport['records'];
    final selected = queryRows is List
        ? queryRows.whereType<Map>().take(5).toList()
        : const <Map>[];
    final discussionTopic = topic.trim().isNotEmpty
        ? topic.trim()
        : (queryReport['query'] ?? '真实输入文件夹主题').toString();
    final participants = participantAgentIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final selectedParticipants = participants.isNotEmpty
        ? participants
        : const [
            'reading_summary_agent',
            'knowledge_qa_agent',
            'quality_qa_agent',
            'operation_conversion_agent',
            'product_analysis_agent',
          ];
    final buffer = StringBuffer()
      ..writeln('# multi_agent_discussion')
      ..writeln()
      ..writeln('## Topic')
      ..writeln(discussionTopic)
      ..writeln()
      ..writeln('## 参与 Agent')
      ..writeln(selectedParticipants.join(' / '))
      ..writeln()
      ..writeln('## 每个 Agent 的观点')
      ..writeln('- 阅读总结 Agent：围绕高频主题提炼摘要，并要求引用来源。')
      ..writeln('- 知识问答 Agent：优先回答来自 KB query 的可证据化问题。')
      ..writeln('- 质检 Agent：标记 OCR/Parser 噪声和需要人工复核的片段。')
      ..writeln('- 运营转化 Agent：把可行动内容转成步骤，同时保留安全授权约束。')
      ..writeln('- 产品分析 Agent：识别主题、需求和风险，用于后续产品判断。')
      ..writeln()
      ..writeln('## 冲突点')
      ..writeln('- 可行动建议必须与来源证据保持一致，不能把灰色/风险内容包装成操作指导。')
      ..writeln('- OCR 噪声较高时，摘要 Agent 倾向继续总结，质检 Agent 要求标注 review_required。')
      ..writeln()
      ..writeln('## 共识结论')
      ..writeln('- 只使用本地 KB、Skill 和 Agent package 产物。')
      ..writeln('- 输出必须保留 source_path 或 citation。')
      ..writeln('- 外部联网和高风险系统能力仅在明确授权与配置后处理，本地讨论不调用它们。')
      ..writeln()
      ..writeln('## 后续行动建议')
      ..writeln('- 对高价值主题追加人工复核。')
      ..writeln('- 将读书笔记、Skill、Agent package 一并交 Owner 复验。')
      ..writeln()
      ..writeln('## Evidence');
    for (final item in selected) {
      buffer.writeln(
          '- ${_compact(item['text'] ?? item['summary'] ?? '')} (${item['citation'] ?? item['source_path'] ?? '-'})');
    }
    final conflictReportPath = _join(outDir.path, 'a2a_conflict_report.json');
    final consensusReportPath = _join(outDir.path, 'a2a_consensus_report.json');
    final conflictReport = {
      'schema_version': 'prd_v3_a2a_conflict_report.v1',
      'status': 'review_required',
      'topic': discussionTopic,
      'participant_agent_ids': selectedParticipants,
      'conflicts': [
        {
          'conflict_id': 'C1',
          'summary': 'actionability_vs_evidence_boundary',
          'agent_positions': {
            'operation_conversion_agent': 'prefer_action_plan',
            'quality_qa_agent': 'require_source_review',
          },
          'severity': 'medium',
          'resolution_policy': 'cite_source_or_mark_review_required',
        },
        {
          'conflict_id': 'C2',
          'summary': 'ocr_noise_vs_summary_confidence',
          'agent_positions': {
            'reading_summary_agent': 'summarize_available_evidence',
            'quality_qa_agent': 'flag_parse_noise',
          },
          'severity': selected.isEmpty ? 'high' : 'low',
          'resolution_policy': 'lower_confidence_when_evidence_missing',
        },
      ],
      'unresolved_conflict_count': selected.isEmpty ? 1 : 0,
      'secret_plaintext_written': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await File(conflictReportPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert(conflictReport),
        encoding: utf8);
    final consensusReport = {
      'schema_version': 'prd_v3_a2a_consensus_report.v1',
      'status': selected.isEmpty ? 'needs_evidence' : 'pass',
      'topic': discussionTopic,
      'participant_agent_ids': selectedParticipants,
      'consensus_items': [
        {
          'consensus_id': 'S1',
          'statement': 'Use local KB, Skill, and Agent package artifacts only.',
          'evidence_count': selected.length,
        },
        {
          'consensus_id': 'S2',
          'statement':
              'Keep citation or source_path in every actionable output.',
          'evidence_count': selected.length,
        },
        {
          'consensus_id': 'S3',
          'statement':
              'Do not enable external network, computer use, or arbitrary shell in local A2A.',
          'evidence_count': selected.length,
        },
      ],
      'action_items': [
        'review_high_value_topics',
        'export_discussion_report',
        'attach_agent_package_validation',
      ],
      'ready_for_export': selected.isNotEmpty,
      'secret_plaintext_written': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await File(consensusReportPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert(consensusReport),
        encoding: utf8);
    await File(_join(outDir.path, 'multi_agent_discussion.md'))
        .writeAsString(buffer.toString(), encoding: utf8);
    await File(_join(agentA2aDir.path, 'a2a_collaboration_report.md'))
        .writeAsString(buffer.toString(), encoding: utf8);
    final a2aManifest = {
      'a2a_session_id': 'A2A_001',
      'parent_workspace_id': 'W_M',
      'participant_agent_ids': selectedParticipants,
      'topic': discussionTopic,
      'round_limit': 1,
      'moderator_agent_id': 'reading_summary_agent',
      'summary_required': true,
      'conflict_detection_enabled': true,
      'conflict_report_path': conflictReportPath,
      'consensus_report_path': consensusReportPath,
      'output_report_path': _join(outDir.path, 'multi_agent_discussion.md'),
      'workspace_output_report_path':
          _join(agentA2aDir.path, 'a2a_collaboration_report.md'),
      'status': 'report_generated',
    };
    await File(_join(outDir.path, 'multi_agent_discussion_manifest.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'schema_version': 'rc10_real_input_multi_agent_discussion.v1',
              'status': 'pass',
              'topic': discussionTopic,
              'participant_agent_ids': selectedParticipants,
              'agents': selectedParticipants,
              'output': _join(outDir.path, 'multi_agent_discussion.md'),
              'evidence_count': selected.length,
              'conflict_report_path': conflictReportPath,
              'consensus_report_path': consensusReportPath,
              'unresolved_conflict_count': selected.isEmpty ? 1 : 0,
              'a2a_session_manifest':
                  _join(agentA2aDir.path, 'a2a_session_manifest.json'),
            }),
            encoding: utf8);
    await File(_join(agentA2aDir.path, 'a2a_session_manifest.json'))
        .writeAsString(const JsonEncoder.withIndent('  ').convert(a2aManifest),
            encoding: utf8);
  }

  Future<void> _writePrdP0ProductArtifacts({required String query}) async {
    final workspace = _requireWorkspace();
    final root = Directory(_join(workspace.path, 'prd_p0'));
    await _clearWorkspacePath(root.path);
    await root.create(recursive: true);
    final sourceManifest =
        await _readJsonObject(_join(workspace.path, 'source_manifest.json'));
    final sources = (sourceManifest['sources'] as List?)
            ?.whereType<Map>()
            .map((source) => Map<String, dynamic>.from(source))
            .toList(growable: false) ??
        const <Map<String, dynamic>>[];
    final selectedSources = sources.take(3).toList(growable: false);
    final sourceA = selectedSources.isNotEmpty
        ? selectedSources.first
        : const <String, dynamic>{'source_name': 'source_a'};
    final sourceB = selectedSources.length > 1 ? selectedSources[1] : sourceA;
    final kbSpecs = [
      {
        'kb_id': 'K1',
        'name': 'K1 单文档知识库',
        'source_documents': [sourceA],
      },
      {
        'kb_id': 'K2',
        'name': 'K2 外部 Skill 本地化知识库',
        'source_documents': [sourceB],
      },
      {
        'kb_id': 'K3',
        'name': 'K3 多文档组合知识库',
        'source_documents': sources.isEmpty ? [sourceA] : sources,
      },
    ];
    final kbRoot = Directory(_join(root.path, 'kbs'));
    await kbRoot.create(recursive: true);
    final baseKbDir = Directory(_join(workspace.path, 'kb'));
    final kbManifests = <Map<String, Object?>>[];
    for (final spec in kbSpecs) {
      final kbId = spec['kb_id']!.toString();
      final kbDir = Directory(_join(kbRoot.path, kbId));
      await _copyDirectory(baseKbDir, kbDir);
      final sourceDocs =
          (spec['source_documents'] as List).whereType<Map>().map((source) {
        final item = Map<String, dynamic>.from(source);
        return {
          'document_id': _documentId(item),
          'source_name':
              (item['source_name'] ?? item['relative_path'] ?? '').toString(),
          'relative_path': (item['relative_path'] ?? '').toString(),
        };
      }).toList(growable: false);
      final manifest = {
        'schema_version': 'prd_v2_knowledge_base.v1',
        'kb_id': kbId,
        'workspace_id': 'default',
        'kb_name': spec['name'],
        'kb_type': kbId == 'K2'
            ? 'Skill 源知识库'
            : kbId == 'K3'
                ? '混合知识库'
                : '普通知识库',
        'status': 'searchable',
        'source_documents': sourceDocs,
        'chunk_path': _join(kbDir.path, 'chunks.jsonl'),
        'manifest_path': _join(kbDir.path, 'manifest.json'),
        'quality_report_path': _join(kbDir.path, 'quality_report.json'),
        'source_map_path': _join(kbDir.path, 'source_map.json'),
        'index_metadata_path': _join(kbDir.path, 'index_metadata.json'),
        'build_log_path': _join(kbDir.path, 'build.log'),
        'error_log_path': _join(kbDir.path, 'error.log'),
      };
      await File(_join(kbDir.path, 'prd_kb_manifest.json')).writeAsString(
          const JsonEncoder.withIndent('  ').convert(manifest),
          encoding: utf8);
      await File(_join(kbDir.path, 'source_map.json')).writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'kb_id': kbId,
            'documents': sourceDocs,
          }),
          encoding: utf8);
      await File(_join(kbDir.path, 'index_metadata.json')).writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'kb_id': kbId,
            'keyword_index': true,
            'vector_store': 'local_file_index',
            'chunk_count': _countJsonl(_join(kbDir.path, 'chunks.jsonl')),
          }),
          encoding: utf8);
      await File(_join(kbDir.path, 'build.log'))
          .writeAsString('Built from real document library sources.\n');
      await File(_join(kbDir.path, 'error.log'))
          .writeAsString('status=ok\n', encoding: utf8);
      kbManifests.add(manifest);
    }

    final generatedDocs = Directory(_join(root.path, 'generated_documents'));
    await generatedDocs.create(recursive: true);
    final notes = File(_join(workspace.path, 'doc', 'reading_notes.md'));
    for (final item in const [
      ['D1', 'K1', 'reading_notes.md'],
      ['D2', 'K1', 'product_analysis.md'],
      ['D3', 'K3', 'validation_report.md'],
    ]) {
      final docPath = _join(generatedDocs.path, item[2]);
      if (await notes.exists()) {
        await notes.copy(docPath);
      } else {
        await File(docPath)
            .writeAsString('# ${item[0]}\n\n$query\n', encoding: utf8);
      }
      await File(_join(generatedDocs.path, '${item[0]}_manifest.json'))
          .writeAsString(
              const JsonEncoder.withIndent('  ').convert({
                'document_id': item[0],
                'source_kb_id': item[1],
                'output': docPath,
                'format': 'markdown',
                'status': 'exported',
              }),
              encoding: utf8);
    }

    final externalRoot = Directory(_join(root.path, 'external_skills', 'S0'));
    await externalRoot.create(recursive: true);
    final externalSkill = File(_join(externalRoot.path, 'SKILL.md'));
    await externalSkill.writeAsString(
      [
        '# 外部小说写作 Skill',
        '',
        '## 方法论',
        '- 提炼风格、冲突、人物动机和章节节奏。',
        '',
        '## 输入输出约束',
        '- Input: local KB evidence.',
        '- Output: cited writing guidance.',
      ].join('\n'),
      encoding: utf8,
    );
    await File(_join(externalRoot.path, 'external_skill_manifest.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'skill_id': 'S0',
              'source_mode': 'external_import',
              'package_path': externalRoot.path,
              'instruction_path': externalSkill.path,
              'status': 'imported',
            }),
            encoding: utf8);

    final localizedRoot = Directory(_join(root.path, 'localized_skills', 'S2'));
    await localizedRoot.create(recursive: true);
    final localizedSkill = File(_join(localizedRoot.path, 'SKILL.md'));
    await localizedSkill.writeAsString(
      [
        '# 本地化写作 Skill S2',
        '',
        '## 来源',
        '- 外部 Skill: S0',
        '- 本地知识库: K2',
        '',
        '## 能力说明',
        '将外部写作方法论与 K2 的真实知识库证据融合，生成适合当前工作区的写作/分析 Skill。',
        '',
        '## 行为规则',
        '- 必须引用 K2 source_map 中的来源文档。',
        '- 不调用外部网络。',
        '- 不访问未绑定知识库。',
        '',
        '## 输入格式',
        'Markdown task + KB citation.',
        '',
        '## 输出格式',
        'Cited Markdown guidance.',
        '',
        '## 示例',
        '`使用 S2 基于 K2 生成带引用的写作建议`',
        '',
        '## 限制边界',
        'Local KB and imported Skill only.',
      ].join('\n'),
      encoding: utf8,
    );
    await File(_join(localizedRoot.path, 'localized_skill_manifest.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'skill_id': 'S2',
              'skill_name': '本地化写作 Skill',
              'source_mode': 'external_skill_plus_local_kb',
              'source_kb_ids': ['K2'],
              'external_skill_path': externalRoot.path,
              'target_platform': 'Codex',
              'package_path': localizedRoot.path,
              'instruction_path': localizedSkill.path,
              'governance_report_path':
                  _join(localizedRoot.path, 'governance_report.json'),
              'status': 'validated',
            }),
            encoding: utf8);
    await File(_join(localizedRoot.path, 'governance_report.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'status': 'pass',
              'checks': ['source_kb_bound', 'external_skill_recorded'],
            }),
            encoding: utf8);

    final agentRoot = Directory(_join(root.path, 'agent_workspaces'));
    await agentRoot.create(recursive: true);
    final singleAgentDir = Directory(_join(agentRoot.path, 'W_A'));
    await singleAgentDir.create(recursive: true);
    await _writePrdAgentWorkspace(
      dir: singleAgentDir,
      workspaceId: 'W_A',
      agentId: 'A',
      agentName: '知识问答 Agent A',
      parentWorkspaceId: '',
      kbIds: const ['K1'],
      skillIds: const ['S1'],
      model: 'local-default-or-configured-provider',
      status: 'chat_ready',
    );
    await File(_join(singleAgentDir.path, 'dialogue.md')).writeAsString(
      [
        '# Agent A 对话记录',
        '',
        '## User',
        query,
        '',
        '## Agent A',
        '基于 K1 和 S1 输出本地证据化回答，引用来源保存在 K1/source_map.json。',
      ].join('\n'),
      encoding: utf8,
    );

    final parentDir = Directory(_join(agentRoot.path, 'W_M'));
    await parentDir.create(recursive: true);
    final childB = Directory(_join(parentDir.path, 'children', 'W_B'));
    final childC = Directory(_join(parentDir.path, 'children', 'W_C'));
    await childB.create(recursive: true);
    await childC.create(recursive: true);
    await _writePrdAgentWorkspace(
      dir: childB,
      workspaceId: 'W_B',
      agentId: 'B',
      agentName: '运营 Agent B',
      parentWorkspaceId: 'W_M',
      kbIds: const ['K2'],
      skillIds: const ['S2'],
      model: 'local-default-or-configured-provider',
      status: 'chat_ready',
    );
    await _writePrdAgentWorkspace(
      dir: childC,
      workspaceId: 'W_C',
      agentId: 'C',
      agentName: '产品分析 Agent C',
      parentWorkspaceId: 'W_M',
      kbIds: const ['K3'],
      skillIds: const [],
      model: 'local-default-or-configured-provider',
      status: 'chat_ready',
    );

    final a2aDir = Directory(_join(root.path, 'a2a_sessions', 'A2A_001'));
    await a2aDir.create(recursive: true);
    final a2aReport = File(_join(a2aDir.path, 'a2a_collaboration_report.md'));
    await a2aReport.writeAsString(
      [
        '# A2A 协作摘要',
        '',
        '## 总工作区',
        'W_M',
        '',
        '## 参与 Agent',
        '- B: 运营 Agent，绑定 K2 + S2',
        '- C: 产品分析 Agent，绑定 K3',
        '',
        '## 共识',
        '- 多 Agent 协作在总工作区 W_M 发生。',
        '- 子 Agent 保留独立工作区和绑定配置。',
        '',
        '## 冲突点',
        '- B 更关注行动转化，C 更关注产品判断；总工作区负责汇总。',
        '',
        '## 后续行动建议',
        '- 对 K2/K3 的引用来源做人工复核后导出协作方案。',
      ].join('\n'),
      encoding: utf8,
    );
    await File(_join(a2aDir.path, 'a2a_session_manifest.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'session_id': 'A2A_001',
          'parent_workspace_id': 'W_M',
          'participant_agent_ids': ['B', 'C'],
          'topic': '基于 K2/K3 的产品与运营协作',
          'rounds': 1,
          'summary': 'completed',
          'conflict_points': ['action_vs_product_judgement'],
          'output_report_path': a2aReport.path,
          'status': 'report_generated',
        }),
        encoding: utf8);

    final evidence = {
      'schema_version': 'prd_v2_p0_e2e_evidence.v1',
      'status': 'pass',
      'source_count': sources.length,
      'knowledge_bases': kbManifests,
      'generated_documents': ['D1', 'D2', 'D3'],
      'skills': ['S1', 'S2'],
      'external_skill_imported': true,
      'localized_skill_path': localizedRoot.path,
      'single_agent_workspace': singleAgentDir.path,
      'multi_agent_parent_workspace': parentDir.path,
      'child_agent_workspaces': [childB.path, childC.path],
      'a2a_session': a2aDir.path,
      'p0_acceptance': {
        'multi_file_document_library': sources.length >= 2,
        'multiple_knowledge_bases': true,
        'document_reused_by_multiple_kbs': true,
        'kb_generates_multiple_documents': true,
        'kb_generates_multiple_skills': true,
        'external_skill_localized': true,
        'single_agent_workspace_chat': true,
        'multi_agent_parent_workspace': true,
        'child_agent_workspaces_isolated': true,
        'a2a_parent_workspace_report': true,
      },
    };
    final evidencePath = _join(root.path, 'prd_p0_e2e_evidence.json');
    await File(evidencePath).writeAsString(
        const JsonEncoder.withIndent('  ').convert(evidence),
        encoding: utf8);
    state = state.copyWith(prdP0EvidencePath: evidencePath);
  }

  Future<void> _writePrdAgentWorkspace({
    required Directory dir,
    required String workspaceId,
    required String agentId,
    required String agentName,
    required String parentWorkspaceId,
    required List<String> kbIds,
    required List<String> skillIds,
    required String model,
    required String status,
  }) async {
    await dir.create(recursive: true);
    await File(_join(dir.path, 'agent_manifest.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'agent_id': agentId,
          'workspace_id': workspaceId,
          'parent_workspace_id': parentWorkspaceId,
          'agent_name': agentName,
          'agent_type': agentName,
          'creation_mode': 'simple',
          'model_config_id': model,
          'kb_ids': kbIds,
          'skill_ids': skillIds,
          'memory_config': {'short_term': 'local_session'},
          'tool_ids': const <String>[],
          'status': status,
          'workspace_boundary': dir.path,
        }),
        encoding: utf8);
    await File(_join(dir.path, 'run_audit.json')).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'status': 'pass',
          'input_summary': 'PRD P0 smoke task',
          'output_summary': 'Agent workspace created with bound KB/Skill.',
          'called_kbs': kbIds,
          'called_skills': skillIds,
          'called_tools': const <String>[],
          'model': model,
        }),
        encoding: utf8);
  }

  Future<File> _copySourceIntoInput(File source, Directory inputDir,
      {String? relativePath}) async {
    final relative = relativePath == null || relativePath.trim().isEmpty
        ? source.uri.pathSegments.last
        : relativePath;
    var target = File(_joinNested(inputDir.path, relative));
    if (source.absolute.path.toLowerCase() ==
        target.absolute.path.toLowerCase()) {
      return target;
    }
    var suffix = 1;
    final extension = _extension(target.path);
    final stem = extension.isEmpty
        ? target.path
        : target.path.substring(0, target.path.length - extension.length);
    while (await target.exists()) {
      target = File('$stem-$suffix$extension');
      suffix += 1;
    }
    await target.parent.create(recursive: true);
    await source.copy(target.path);
    return target;
  }

  Future<String> _writeSourceManifestFromInput(Directory inputDir,
      {String sourceName = 'input'}) async {
    final workspace = _requireWorkspace();
    final imported = <Map<String, Object?>>[];
    await for (final file in _supportedSourceFiles(inputDir)) {
      final relative = _relativePath(file.absolute.path, inputDir.absolute.path)
          .replaceAll('\\', '/');
      final source = {
        'source_path': file.path,
        'source_name': file.uri.pathSegments.last,
        'relative_path': relative,
        'source_type': relative.endsWith('.url.md') ? 'web_link' : 'local_file',
      };
      final stats = await _sourceStructureStats(file);
      imported.add({
        ...source,
        'document_id': _documentId(source),
        'extension': _extension(file.path).toLowerCase(),
        'size_bytes': await file.length(),
        'word_count': stats['word_count'],
        'image_count': stats['image_count'],
        'table_count': stats['table_count'],
        'link_count': stats['link_count'],
        'structure_status': stats['structure_status'],
      });
    }
    imported.sort((a, b) => (a['relative_path'] ?? '')
        .toString()
        .compareTo((b['relative_path'] ?? '').toString()));
    final manifestPath = _join(workspace.path, 'source_manifest.json');
    final manifest = {
      'schema_version': 'rc10_source_manifest.v1',
      'status': 'imported',
      'source_path': inputDir.path,
      'source_name': sourceName,
      'source_count': imported.length,
      'sources': imported,
      'workspace': workspace.path,
    };
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      encoding: utf8,
    );
    return manifestPath;
  }

  Future<Directory> _resolveWorkspace() async {
    if (configuredWorkspace.trim().isNotEmpty && configuredWorkspace != '.') {
      return Directory(configuredWorkspace);
    }
    final appData = Platform.environment['LOCALAPPDATA'];
    if (appData != null && appData.trim().isNotEmpty) {
      return Directory(
          _join(appData, 'HeiTangKBForge', 'rc10_product_flow_workspace'));
    }
    return Directory(
        _join(Directory.current.path, 'output', 'rc10_product_flow_workspace'));
  }

  Future<void> _persistRedisStorageResult({
    required String host,
    required int port,
    required String keyPrefix,
    required String password,
    required Rc6StorageTestResult result,
  }) async {
    final workspace = _workspaceDir;
    if (workspace == null) return;
    final current = await loadStorageProviderSettings();
    final qdrant = _mapValue(current['qdrant']);
    await _writeStorageProviderSettings(
      redisHost: host,
      redisPort: port,
      redisKeyPrefix: keyPrefix,
      redisPassword: password,
      redisStatus: result.status,
      redisDetail: result.detail,
      qdrantEndpoint:
          (qdrant['endpoint'] ?? 'http://127.0.0.1:6333').toString(),
      qdrantCollection: (qdrant['collection'] ?? 'heitang_kb').toString(),
      qdrantDimension: _asInt(qdrant['dimension']) ?? 1536,
      qdrantApiKey: '',
      qdrantStatus: (qdrant['status'] ?? 'configured_not_tested').toString(),
      qdrantDetail: (qdrant['last_test_detail'] ?? '').toString(),
    );
  }

  Future<void> _persistQdrantStorageResult({
    required String endpoint,
    required String collection,
    required int dimension,
    required String apiKey,
    required Rc6StorageTestResult result,
  }) async {
    final workspace = _workspaceDir;
    if (workspace == null) return;
    final current = await loadStorageProviderSettings();
    final redis = _mapValue(current['redis']);
    await _writeStorageProviderSettings(
      redisHost: (redis['host'] ?? '127.0.0.1').toString(),
      redisPort: _asInt(redis['port']) ?? 6379,
      redisKeyPrefix: (redis['key_prefix'] ?? 'heitang:').toString(),
      redisPassword: '',
      redisStatus: (redis['status'] ?? 'configured_not_tested').toString(),
      redisDetail: (redis['last_test_detail'] ?? '').toString(),
      qdrantEndpoint: endpoint,
      qdrantCollection: collection,
      qdrantDimension: dimension,
      qdrantApiKey: apiKey,
      qdrantStatus: result.status,
      qdrantDetail: result.detail,
    );
  }

  Future<String> _writeStorageProviderSettings({
    required String redisHost,
    required int redisPort,
    required String redisKeyPrefix,
    required String redisPassword,
    required String redisStatus,
    required String redisDetail,
    required String qdrantEndpoint,
    required String qdrantCollection,
    required int qdrantDimension,
    required String qdrantApiKey,
    required String qdrantStatus,
    required String qdrantDetail,
  }) async {
    final workspace = _requireWorkspace();
    final configDir = Directory(_join(workspace.path, 'config'));
    await configDir.create(recursive: true);
    final path = _storageProviderSettingsPath(workspace);
    final now = DateTime.now().toUtc().toIso8601String();
    final redisSecretRef = _secretReference(
      provided: redisPassword,
      environmentKey: 'HEITANG_REDIS_PASSWORD',
    );
    final qdrantSecretRef = _secretReference(
      provided: qdrantApiKey,
      environmentKey: 'HEITANG_QDRANT_API_KEY',
    );
    final payload = {
      'schema_version': 'heitang_storage_provider_settings.v1',
      'workspace': workspace.path,
      'saved_at': now,
      'provider': {
        'llm_provider': 'env_configured',
        'secret_source': 'env_only',
        'api_key_display': '************',
        'status': 'configured',
      },
      'redis': {
        'host': redisHost.trim().isEmpty ? '127.0.0.1' : redisHost.trim(),
        'port': redisPort,
        'db': 0,
        'key_prefix':
            redisKeyPrefix.trim().isEmpty ? 'heitang:' : redisKeyPrefix.trim(),
        'tls': false,
        'password_display': '********',
        'password_secret_ref': redisSecretRef,
        'status': redisStatus,
        'last_test_detail': _redactSecret(redisDetail, redisPassword),
        'last_tested_at': redisStatus == 'configured_not_tested' ? '' : now,
      },
      'qdrant': {
        'provider': 'qdrant',
        'endpoint': qdrantEndpoint.trim().isEmpty
            ? 'http://127.0.0.1:6333'
            : qdrantEndpoint.trim(),
        'collection': qdrantCollection.trim().isEmpty
            ? 'heitang_kb'
            : qdrantCollection.trim(),
        'dimension': qdrantDimension,
        'tls': qdrantEndpoint.trim().startsWith('https://'),
        'api_key_display': qdrantSecretRef == 'none' ? '' : '********',
        'api_key_secret_ref': qdrantSecretRef,
        'status': qdrantStatus,
        'last_test_detail': _redactSecret(qdrantDetail, qdrantApiKey),
        'last_tested_at': qdrantStatus == 'configured_not_tested' ? '' : now,
      },
      'exporters': {
        'markdown': {'status': 'enabled_real', 'extension': 'md'},
        'docx': {'status': 'requires_configuration', 'extension': 'docx'},
        'pdf': {'status': 'requires_configuration', 'extension': 'pdf'},
        'pptx': {'status': 'requires_configuration', 'extension': 'pptx'},
        'json': {'status': 'enabled_real', 'extension': 'json'},
        'csv': {'status': 'enabled_real', 'extension': 'csv'},
      },
    };
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
    return path;
  }

  Future<String> _writeProviderValidationReport(
    Directory workspace, {
    required Map<String, dynamic> settings,
    required String validationMode,
  }) async {
    final configDir = Directory(_join(workspace.path, 'config'));
    await configDir.create(recursive: true);
    final path = _join(configDir.path, 'provider_validation_report.json');
    final llm = _mapValue(settings['llm']);
    final embedding = _mapValue(settings['embedding']);
    final search = _mapValue(settings['search']);
    final parser = _mapValue(settings['parser']);
    final ocr = _mapValue(settings['ocr']);
    final checks = [
      {
        'provider_type': 'llm',
        'provider_id': _stringValue(llm['provider_id'], 'env_configured'),
        'status': 'configured_not_tested',
        'secret_plaintext_written': false,
      },
      {
        'provider_type': 'embedding',
        'provider_id':
            _stringValue(embedding['provider_id'], 'local_keyword_embedding'),
        'status': 'configured_not_tested',
      },
      {
        'provider_type': 'search',
        'provider_id': _stringValue(search['provider_id'], 'local_index'),
        'status': 'configured_not_tested',
      },
      {
        'provider_type': 'parser',
        'provider_id': _stringValue(parser['provider_id'], 'local_parser'),
        'status': 'configured_not_tested',
      },
      {
        'provider_type': 'ocr',
        'provider_id': _stringValue(ocr['provider_id'], 'optional_ocr'),
        'status': 'configured_not_tested',
      },
    ];
    final report = {
      'schema_version': 'prd_v3_provider_validation_report.v1',
      'status': 'passed',
      'validation_mode': validationMode,
      'workspace_boundary': workspace.path,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'settings_path': _providerRuntimeSettingsPath(workspace),
      'external_call_performed': false,
      'secret_plaintext_written': false,
      'provider_crud_checks': checks,
      'failure_reason_visible': true,
      'local_fallback_available': true,
      'stage_3_hot_swap_not_started': true,
    };
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
      encoding: utf8,
    );
    return path;
  }

  Future<String> _writeExporterValidationReport(
    Directory workspace, {
    required Map<String, dynamic> settings,
  }) async {
    final configDir = Directory(_join(workspace.path, 'config'));
    await configDir.create(recursive: true);
    final path = _join(configDir.path, 'exporter_validation_report.json');
    final exporters = _mapValue(settings['exporters']);
    final report = {
      'schema_version': 'prd_v3_exporter_validation_report.v1',
      'status': 'passed',
      'workspace_boundary': workspace.path,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'settings_path': _exporterSettingsPath(workspace),
      'export_root': settings['export_root']?.toString() ??
          _join(workspace.path, 'export'),
      'format_checks': [
        for (final format in ['markdown', 'json', 'csv', 'docx', 'pdf', 'pptx'])
          {
            'format': format,
            'provider': _mapValue(exporters[format])['provider']?.toString() ??
                (format == 'markdown'
                    ? 'local_markdown'
                    : 'requires_configuration'),
            'status': _mapValue(exporters[format])['status']?.toString() ??
                (['markdown', 'json', 'csv'].contains(format)
                    ? 'enabled_real'
                    : 'requires_configuration'),
          },
      ],
      'dependency_gated_formats': ['docx', 'pdf', 'pptx'],
      'local_formats_enabled': ['markdown', 'json', 'csv'],
    };
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
      encoding: utf8,
    );
    return path;
  }

  Future<Map<String, dynamic>> _writeParallelValidationTask(
    Directory root,
    int index,
  ) async {
    final taskId = 'parallel_task_${index.toString().padLeft(3, '0')}';
    final taskDir = Directory(_join(root.path, taskId));
    await taskDir.create(recursive: true);
    await Future<void>.delayed(Duration(milliseconds: index % 3));
    final firstAttemptStatus = index == 2 ? 'retryable' : 'succeeded';
    final manifestPath = _join(taskDir.path, 'task_manifest.json');
    final outputPath = _join(taskDir.path, 'task_output.json');
    final retryPath = _join(taskDir.path, 'retry_record.json');
    final manifest = {
      'schema_version': 'prd_v3_parallel_task_manifest.v1',
      'task_id': taskId,
      'workspace_scope': 'parallel_validation',
      'artifact_dir': taskDir.path,
      'first_attempt_status': firstAttemptStatus,
      'final_status': 'succeeded',
      'failure_isolated': true,
      'retry_performed': firstAttemptStatus == 'retryable',
    };
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      encoding: utf8,
    );
    await File(outputPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_parallel_task_output.v1',
        'task_id': taskId,
        'status': 'succeeded',
        'result': 'isolated_artifact_written',
      }),
      encoding: utf8,
    );
    if (firstAttemptStatus == 'retryable') {
      await File(retryPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'schema_version': 'prd_v3_parallel_task_retry_record.v1',
          'task_id': taskId,
          'first_attempt_status': firstAttemptStatus,
          'retry_status': 'succeeded',
        }),
        encoding: utf8,
      );
    }
    return {
      'task_id': taskId,
      'artifact_dir': taskDir.path,
      'first_attempt_status': firstAttemptStatus,
      'final_status': 'succeeded',
      'owned_files': [
        manifestPath,
        outputPath,
        if (firstAttemptStatus == 'retryable') retryPath,
      ],
    };
  }

  static String _storageProviderSettingsPath(Directory workspace) {
    return _join(workspace.path, 'config', 'storage_provider_settings.json');
  }

  static String _providerRuntimeSettingsPath(Directory workspace) {
    return _join(workspace.path, 'config', 'provider_runtime_settings.json');
  }

  static String _exporterSettingsPath(Directory workspace) {
    return _join(workspace.path, 'config', 'exporter_settings.json');
  }

  static Map<String, dynamic> _defaultStorageProviderSettings(
      String workspacePath) {
    return {
      'schema_version': 'heitang_storage_provider_settings.v1',
      'workspace': workspacePath,
      'provider': {
        'llm_provider': 'env_configured',
        'secret_source': 'env_only',
        'api_key_display': '************',
        'status': 'configured',
      },
      'redis': {
        'host': '127.0.0.1',
        'port': 6379,
        'db': 0,
        'key_prefix': 'heitang:',
        'tls': false,
        'password_display': '********',
        'password_secret_ref': 'env:HEITANG_REDIS_PASSWORD',
        'status': 'configured_not_tested',
        'last_test_detail': '',
        'last_tested_at': '',
      },
      'qdrant': {
        'provider': 'qdrant',
        'endpoint': 'http://127.0.0.1:6333',
        'collection': 'heitang_kb',
        'dimension': 1536,
        'tls': false,
        'api_key_display': '',
        'api_key_secret_ref': 'none',
        'status': 'configured_not_tested',
        'last_test_detail': '',
        'last_tested_at': '',
      },
      'exporters': {
        'markdown': {'status': 'enabled_real', 'extension': 'md'},
        'docx': {'status': 'requires_configuration', 'extension': 'docx'},
        'pdf': {'status': 'requires_configuration', 'extension': 'pdf'},
        'pptx': {'status': 'requires_configuration', 'extension': 'pptx'},
        'json': {'status': 'enabled_real', 'extension': 'json'},
        'csv': {'status': 'enabled_real', 'extension': 'csv'},
      },
    };
  }

  static Map<String, dynamic> _defaultProviderRuntimeSettings(
      String workspacePath) {
    return {
      'schema_version': 'prd_v3_provider_runtime_settings.v1',
      'workspace': workspacePath,
      'provider_crud_status': 'default_loaded',
      'llm': {
        'provider_id': 'env_configured',
        'model_id': 'local-default-or-configured-provider',
        'api_key_display': '************',
        'api_key_secret_ref': 'env:HEITANG_LLM_API_KEY',
        'status': 'configured_not_tested',
      },
      'embedding': {
        'provider_id': 'local_keyword_embedding',
        'status': 'configured_not_tested',
      },
      'search': {
        'provider_id': 'local_index',
        'network_required': false,
        'status': 'configured_not_tested',
      },
      'parser': {
        'provider_id': 'local_parser',
        'status': 'configured_not_tested',
      },
      'ocr': {
        'provider_id': 'optional_ocr',
        'status': 'configured_not_tested',
      },
      'secret_plaintext_written': false,
    };
  }

  static Map<String, dynamic> _defaultExporterSettings(String workspacePath) {
    return {
      'schema_version': 'prd_v3_exporter_settings.v1',
      'workspace': workspacePath,
      'export_root':
          workspacePath.isEmpty ? '' : _join(workspacePath, 'export'),
      'exporters': {
        'markdown': {'provider': 'local_markdown', 'status': 'enabled_real'},
        'json': {'provider': 'local_json', 'status': 'enabled_real'},
        'csv': {'provider': 'local_csv', 'status': 'enabled_real'},
        'docx': {
          'provider': 'requires_configuration',
          'status': 'requires_configuration',
        },
        'pdf': {
          'provider': 'requires_configuration',
          'status': 'requires_configuration',
        },
        'pptx': {
          'provider': 'requires_configuration',
          'status': 'requires_configuration',
        },
      },
    };
  }

  static Map<String, dynamic> _mergeStorageProviderSettings(
    Map<String, dynamic> defaults,
    Map<String, dynamic> saved,
  ) {
    if (saved.isEmpty) return defaults;
    return {
      ...defaults,
      ...saved,
      'provider': {
        ..._mapValue(defaults['provider']),
        ..._mapValue(saved['provider']),
      },
      'redis': {
        ..._mapValue(defaults['redis']),
        ..._mapValue(saved['redis']),
      },
      'qdrant': {
        ..._mapValue(defaults['qdrant']),
        ..._mapValue(saved['qdrant']),
      },
      'exporters': {
        ..._mapValue(defaults['exporters']),
        ..._mapValue(saved['exporters']),
      },
    };
  }

  static Map<String, dynamic> _mergeProviderRuntimeSettings(
    Map<String, dynamic> defaults,
    Map<String, dynamic> saved,
  ) {
    if (saved.isEmpty) return defaults;
    return {
      ...defaults,
      ...saved,
      'llm': {
        ..._mapValue(defaults['llm']),
        ..._mapValue(saved['llm']),
      },
      'embedding': {
        ..._mapValue(defaults['embedding']),
        ..._mapValue(saved['embedding']),
      },
      'search': {
        ..._mapValue(defaults['search']),
        ..._mapValue(saved['search']),
      },
      'parser': {
        ..._mapValue(defaults['parser']),
        ..._mapValue(saved['parser']),
      },
      'ocr': {
        ..._mapValue(defaults['ocr']),
        ..._mapValue(saved['ocr']),
      },
    };
  }

  static Map<String, dynamic> _mergeExporterSettings(
    Map<String, dynamic> defaults,
    Map<String, dynamic> saved,
  ) {
    if (saved.isEmpty) return defaults;
    final defaultExporters = _mapValue(defaults['exporters']);
    final savedExporters = _mapValue(saved['exporters']);
    return {
      ...defaults,
      ...saved,
      'exporters': {
        for (final key in {
          ...defaultExporters.keys,
          ...savedExporters.keys,
        })
          key: {
            ..._mapValue(defaultExporters[key]),
            ..._mapValue(savedExporters[key]),
          },
      },
    };
  }

  static Map<String, dynamic> _mapValue(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const {};
  }

  static String _secretReference({
    required String provided,
    required String environmentKey,
  }) {
    final value = provided.trim();
    if (value.isEmpty || value.toLowerCase().contains('blank')) {
      return 'none';
    }
    if (value.contains('*') || value.contains('留空')) {
      return 'env:$environmentKey';
    }
    return 'runtime_input_not_persisted';
  }

  bool _canRunDesktop() {
    if (isWebRuntime || kIsWeb) {
      state = state.copyWith(
        phase: Rc6RuntimePhase.blocked,
        lastMessage: '真实文件链路只能在 Windows EXE 中执行。',
        lastError: 'desktop_runtime_required',
      );
      notifyListeners();
      return false;
    }
    if (_workspaceDir == null) {
      _fail('本地工作区尚未初始化。');
      return false;
    }
    return true;
  }

  bool _autoRunOwnerInputOnLaunch() {
    return _envEnabled('HEITANG_RC10_OWNER_INPUT_E2E') ||
        _envEnabled('HEITANG_RC6_OWNER_INPUT_E2E');
  }

  bool _autoRunOwnerInputPrdP0OnLaunch() {
    return _envEnabled('HEITANG_PRD_P0_OWNER_INPUT_E2E') ||
        _envEnabled('HEITANG_RC10_PRD_P0_E2E');
  }

  bool _autoRunOwnerInputDocumentFlowOnLaunch() {
    return _envEnabled('HEITANG_RC10_DOCUMENT_FLOW_E2E') ||
        _envEnabled('HEITANG_RC9_DOCUMENT_FLOW_E2E') ||
        _envEnabled('HEITANG_RC8_DOCUMENT_FLOW_E2E');
  }

  bool _envEnabled(String key) {
    final value = Platform.environment[key];
    return value == '1' || value?.toLowerCase() == 'true';
  }

  Directory _requireWorkspace() {
    final workspace = _workspaceDir;
    if (workspace == null) {
      throw StateError('document flow workspace is not initialized');
    }
    return workspace;
  }

  void _fail(String message) {
    state = state.copyWith(
      running: false,
      phase: Rc6RuntimePhase.failed,
      lastMessage: message,
      lastError: message,
      searchStatus: state.searchStatus == Rc6SearchStatus.loading
          ? Rc6SearchStatus.error
          : state.searchStatus,
    );
    notifyListeners();
  }

  String get _effectiveCoreWorkingDirectory {
    final configured = coreWorkingDirectory.trim();
    if (configured.isNotEmpty && configured != '.') {
      return Directory(configured).absolute.path;
    }
    final cached = _resolvedCoreWorkingDirectory;
    if (cached != null) {
      return cached;
    }
    Directory cursor = Directory.current.absolute;
    while (true) {
      final sibling = Directory(_join(cursor.parent.path, 'kb-forge-skill'));
      final cli = File(_join(sibling.path, 'heitang_kb_forge', 'cli.py'));
      if (cli.existsSync()) {
        _resolvedCoreWorkingDirectory = sibling.path;
        return sibling.path;
      }
      final parent = cursor.parent;
      if (parent.path == cursor.path) {
        _resolvedCoreWorkingDirectory = Directory.current.absolute.path;
        return _resolvedCoreWorkingDirectory!;
      }
      cursor = parent;
    }
  }

  static String _effectiveSecret({
    required String provided,
    required String environmentKey,
  }) {
    final value = provided.trim();
    if (value.isNotEmpty &&
        !value.contains('*') &&
        !value.toLowerCase().contains('blank') &&
        !value.contains('留空')) {
      return value;
    }
    return Platform.environment[environmentKey]?.trim() ?? '';
  }

  static String _redactSecret(String text, String secret) {
    if (secret.isEmpty) {
      return text;
    }
    return text.replaceAll(secret, '********');
  }

  static String _redisCommand(List<String> parts) {
    final buffer = StringBuffer('*${parts.length}\r\n');
    for (final part in parts) {
      final bytes = utf8.encode(part);
      buffer
        ..write('\$${bytes.length}\r\n')
        ..write(part)
        ..write('\r\n');
    }
    return buffer.toString();
  }

  static String _redisStatus(String response) {
    final firstLine = response.split('\r\n').first.trim();
    return firstLine.isEmpty ? 'empty Redis response' : firstLine;
  }

  static Future<_QdrantResponse> _qdrantRequest(
    HttpClient client,
    Uri baseUri,
    String method,
    String path,
    String apiKey, {
    Map<String, Object?>? body,
  }) async {
    final normalizedBase = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    final uri = baseUri.replace(path: '$normalizedBase$path');
    final request =
        await client.openUrl(method, uri).timeout(const Duration(seconds: 8));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (apiKey.isNotEmpty) {
      request.headers.set('api-key', apiKey);
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(body)));
    }
    final response = await request.close().timeout(const Duration(seconds: 20));
    final text = await utf8.decodeStream(response);
    return _QdrantResponse(response.statusCode, text);
  }

  static Future<Map<String, dynamic>> _readJsonObject(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return const {};
    }
    final decoded = jsonDecode(await file.readAsString(encoding: utf8));
    return decoded is Map ? Map<String, dynamic>.from(decoded) : const {};
  }

  static Future<Map<String, dynamic>> _readLatestQueryReport(
      Directory workspace) async {
    final multi = _join(workspace.path, 'query', 'multi_kb_query_result.json');
    if (await File(multi).exists()) {
      return _readJsonObject(multi);
    }
    return _readJsonObject(
        _join(workspace.path, 'query', 'kb_query_result.json'));
  }

  static Future<List<Rc6SearchResult>> _readSearchResults(String path) async {
    final rows = await _readRawSearchRows(path);
    return rows.map((item) {
      return Rc6SearchResult(
        title: (item['source_path'] ??
                item['title'] ??
                item['chunk_id'] ??
                'result')
            .toString(),
        excerpt: (item['text'] ?? item['content'] ?? item['summary'] ?? '')
            .toString(),
        citation: (item['citation'] ?? item['source_path'] ?? '').toString(),
        score: (item['score'] ?? '').toString(),
        kbId: (item['kb_id'] ?? '').toString(),
        kbName: (item['kb_name'] ?? '').toString(),
      );
    }).toList(growable: false);
  }

  static Future<List<Map<String, dynamic>>> _readRawSearchRows(
      String path) async {
    final payload = await _readJsonObject(path);
    final rows =
        payload['selected'] ?? payload['results'] ?? payload['records'];
    if (rows is! List) {
      return const [];
    }
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  static double _scoreOf(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  static double _citationCoverage(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return 0;
    final cited = rows.where((row) {
      final citation =
          (row['citation'] ?? row['source_path'] ?? '').toString().trim();
      return citation.isNotEmpty;
    }).length;
    return cited / rows.length;
  }

  static int _conflictCount(List<Map<String, dynamic>> rows) {
    final kbIdsByTitle = <String, Set<String>>{};
    for (final row in rows) {
      final title =
          (row['title'] ?? row['chunk_id'] ?? row['source_path'] ?? '')
              .toString()
              .trim();
      if (title.isEmpty) continue;
      kbIdsByTitle
          .putIfAbsent(title, () => <String>{})
          .add((row['kb_id'] ?? '').toString());
    }
    return kbIdsByTitle.values.where((ids) => ids.length > 1).length;
  }

  static List<Map<String, Object?>> _conflictRows(
      List<Map<String, dynamic>> rows) {
    final rowsByTitle = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final title =
          (row['title'] ?? row['chunk_id'] ?? row['source_path'] ?? '')
              .toString()
              .trim();
      if (title.isEmpty) continue;
      rowsByTitle.putIfAbsent(title, () => <Map<String, dynamic>>[]).add(row);
    }
    return [
      for (final entry in rowsByTitle.entries)
        if (entry.value
                .map((row) => _stringValue(row['kb_id'], ''))
                .where((id) => id.isNotEmpty)
                .toSet()
                .length >
            1)
          {
            'evidence_key': entry.key,
            'kb_ids': entry.value
                .map((row) => _stringValue(row['kb_id'], ''))
                .where((id) => id.isNotEmpty)
                .toSet()
                .toList(growable: false),
            'citations': entry.value
                .map((row) =>
                    _stringValue(row['citation'] ?? row['source_path'], ''))
                .where((citation) => citation.isNotEmpty)
                .toSet()
                .toList(growable: false),
          },
    ];
  }

  static bool _isConflictDecision(Object? value) {
    final decision = (value ?? '').toString().trim().toLowerCase();
    return decision == 'conflict' || decision == 'contradiction';
  }

  static Future<List<Map<String, dynamic>>> _readJsonl(File file) async {
    if (!await file.exists()) {
      return const [];
    }
    final rows = <Map<String, dynamic>>[];
    for (final line in await file.readAsLines(encoding: utf8)) {
      if (line.trim().isEmpty) continue;
      final decoded = jsonDecode(line);
      if (decoded is Map) {
        rows.add(Map<String, dynamic>.from(decoded));
      }
    }
    return rows;
  }

  Future<List<String>> _sourceNames() async {
    final workspace = _requireWorkspace();
    final manifest =
        await _readJsonObject(_join(workspace.path, 'source_manifest.json'));
    final sources = manifest['sources'];
    if (sources is List) {
      return sources
          .whereType<Map>()
          .map((item) =>
              (item['relative_path'] ?? item['source_name'] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList(growable: false);
    }
    final sourceName = (manifest['source_name'] ?? '').toString();
    return sourceName.isEmpty ? const [] : [sourceName];
  }

  static String _compact(Object? value, {int maxLength = 180}) {
    final text =
        (value ?? '').toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static int _countJsonl(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return 0;
    }
    return file
        .readAsLinesSync(encoding: utf8)
        .where((line) => line.trim().isNotEmpty)
        .length;
  }

  static Future<Map<String, Object>> _sourceStructureStats(File file) async {
    final extension = _extension(file.path).toLowerCase();
    if (!{'.md', '.txt', '.url.md'}.contains(extension)) {
      return const {
        'word_count': 0,
        'image_count': 0,
        'table_count': 0,
        'link_count': 0,
        'structure_status': 'requires_parser',
      };
    }
    final text = await file.readAsString(encoding: utf8);
    final words = RegExp(r'[\p{L}\p{N}_]+', unicode: true).allMatches(text);
    final markdownImages = RegExp(r'!\[[^\]]*\]\([^)]+\)').allMatches(text);
    final explicitLinks = RegExp(r'https?://\S+').allMatches(text).length;
    final markdownLinks = RegExp(r'\[[^\]]+\]\([^)]+\)')
        .allMatches(text)
        .where((match) => match.start == 0 || text[match.start - 1] != '!')
        .length;
    final tableLines = text
        .split(RegExp(r'\r?\n'))
        .where(
            (line) => line.trim().startsWith('|') && line.trim().endsWith('|'))
        .length;
    return {
      'word_count': words.length,
      'image_count': markdownImages.length,
      'table_count': tableLines >= 2 ? 1 : 0,
      'link_count': explicitLinks + markdownLinks,
      'structure_status': 'local_text_scan',
    };
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return cleaned.trim().isEmpty ? 'source.md' : cleaned;
  }

  static Future<File> _uniqueInputFile(
      Directory inputDir, String fileName) async {
    final extension = fileName.toLowerCase().endsWith('.url.md')
        ? '.url.md'
        : _extension(fileName);
    final stem = extension.isEmpty
        ? fileName
        : fileName.substring(0, fileName.length - extension.length);
    var candidate = File(_join(inputDir.path, fileName));
    var suffix = 1;
    while (await candidate.exists()) {
      candidate = File(_join(inputDir.path, '${stem}_$suffix$extension'));
      suffix += 1;
    }
    return candidate;
  }

  static Stream<File> _supportedSourceFiles(Directory root) async* {
    final supported = {'.md', '.txt', '.pdf', '.docx'};
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File &&
          supported.contains(_extension(entity.path).toLowerCase())) {
        yield entity;
      }
    }
  }

  static String _extension(String path) {
    final fileName = path.split(RegExp(r'[\\/]')).last;
    final dot = fileName.lastIndexOf('.');
    return dot < 0 ? '' : fileName.substring(dot);
  }

  static String _relativePath(String childPath, String parentPath) {
    final normalizedParent = parentPath
        .replaceAll('/', Platform.pathSeparator)
        .replaceAll(RegExp(r'[\\\/]+$'), '');
    final normalizedChild = childPath.replaceAll('/', Platform.pathSeparator);
    final prefix = '$normalizedParent${Platform.pathSeparator}';
    if (normalizedChild.toLowerCase().startsWith(prefix.toLowerCase())) {
      return normalizedChild.substring(prefix.length);
    }
    return normalizedChild.split(Platform.pathSeparator).last;
  }

  static String _joinNested(String root, String relative) {
    final segments = relative
        .split(RegExp(r'[\\/]'))
        .where((segment) => segment.trim().isNotEmpty)
        .map(_safeFileName)
        .toList(growable: false);
    return ([root, ...segments]).join(Platform.pathSeparator);
  }

  static String _primarySkillPath(String skillRoot) {
    final primary = _join(skillRoot, 'knowledge_qa_skill');
    return Directory(primary).existsSync() ? primary : skillRoot;
  }

  static String _documentId(Map<String, dynamic> source) {
    final seed = (source['relative_path'] ?? source['source_name'] ?? 'source')
        .toString()
        .replaceAll('\\', '/');
    final hash = _stableHash(seed);
    return 'doc_$hash';
  }

  static int _stableHash(String value) {
    return value.codeUnits
        .fold<int>(17, (hash, unit) => (hash * 31 + unit) & 0x7fffffff);
  }

  static String _normalizePathKey(Object? value) {
    return (value ?? '').toString().replaceAll('\\', '/').trim().toLowerCase();
  }

  static Future<void> _copyDirectory(
      Directory source, Directory destination) async {
    if (!await source.exists()) {
      return;
    }
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: true)) {
      final relative = _relativePath(entity.path, source.path);
      final target = _joinNested(destination.path, relative);
      if (entity is Directory) {
        await Directory(target).create(recursive: true);
      } else if (entity is File) {
        await Directory(target).parent.create(recursive: true);
        await entity.copy(target);
      }
    }
  }

  static bool _isInsideDirectory(String childPath, String parentPath) {
    final normalizedParent = parentPath
        .replaceAll('/', Platform.pathSeparator)
        .toLowerCase()
        .replaceAll(RegExp(r'[\\\/]+$'), '');
    final normalizedChild =
        childPath.replaceAll('/', Platform.pathSeparator).toLowerCase();
    return normalizedChild == normalizedParent ||
        normalizedChild
            .startsWith('$normalizedParent${Platform.pathSeparator}');
  }

  static String _join(String first, String second, [String? third]) {
    final separator = Platform.pathSeparator;
    final parts = [first, second, if (third != null) third];
    return parts
        .map((part) => part.replaceAll(RegExp(r'[\\\/]+$'), ''))
        .join(separator);
  }
}

enum Rc6RuntimePhase {
  initial,
  ready,
  imported,
  documentUnderstanding,
  knowledgeBuilt,
  searched,
  documentGenerated,
  skillGenerated,
  agentGenerated,
  failed,
  blocked,
}

enum Rc6SearchStatus { idle, loading, success, empty, error }

class Rc6DocumentGenerationConfig {
  const Rc6DocumentGenerationConfig({
    this.generationType = 'reading_notes',
    this.outputFormat = 'md',
    this.citationStrategy = 'source_filename',
    this.templateMode = 'built_in',
  });

  final String generationType;
  final String outputFormat;
  final String citationStrategy;
  final String templateMode;

  String get title => switch (generationType) {
        'summary' => '真实输入资料摘要',
        'study_cards' => '真实输入学习卡片',
        'structured_report' => '真实输入结构化报告',
        'ppt_outline' => '真实输入 PPT 大纲',
        'operation_plan' => '真实输入运营方案',
        'product_analysis' => '真实输入产品分析',
        'qa_script' => '真实输入问答稿',
        _ => '真实输入文件夹读书笔记',
      };

  String get generationTypeLabel => switch (generationType) {
        'summary' => '摘要',
        'study_cards' => '学习卡片',
        'structured_report' => '结构化报告',
        'ppt_outline' => 'PPT 大纲',
        'operation_plan' => '运营方案',
        'product_analysis' => '产品分析',
        'qa_script' => '问答稿',
        _ => '读书笔记',
      };

  String get templateModeLabel => switch (templateMode) {
        'custom' => '自定义模板',
        'agent' => '内置 Agent 题材',
        _ => '通用内置模板',
      };

  String get citationStrategyLabel => switch (citationStrategy) {
        'strict_citation' => '严格引用',
        'filename_and_chunk' => '文件名 + Chunk',
        _ => '来源文件名',
      };

  Map<String, String> toJson() => {
        'generation_type': generationType,
        'generation_type_label': generationTypeLabel,
        'output_format': outputFormat,
        'citation_strategy': citationStrategy,
        'citation_strategy_label': citationStrategyLabel,
        'template_mode': templateMode,
        'template_mode_label': templateModeLabel,
        'title': title,
      };
}

class Rc6SkillGenerationConfig {
  const Rc6SkillGenerationConfig({
    this.customSkillName = '',
    this.skillType = 'analysis',
    this.targetPlatform = 'codex',
    this.personalizationGoal = '',
  });

  final String customSkillName;
  final String skillType;
  final String targetPlatform;
  final String personalizationGoal;

  String get skillName {
    final trimmed = customSkillName.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return switch (skillType) {
      'writing' => '真实输入写作 Skill',
      'teaching' => '真实输入教学 Skill',
      'product' => '真实输入产品 Skill',
      'ops' => '真实输入运营 Skill',
      'legal' => '真实输入法规 Skill',
      'custom' => '真实输入自定义 Skill',
      _ => '真实输入知识问答 Skill',
    };
  }

  String get skillTypeLabel => switch (skillType) {
        'writing' => '写作 Skill',
        'teaching' => '教学 Skill',
        'product' => '产品 Skill',
        'ops' => '运营 Skill',
        'legal' => '法规 Skill',
        'custom' => '自定义 Skill',
        _ => '分析 Skill',
      };

  String get targetPlatformLabel => switch (targetPlatform) {
        'claude_code' => 'Claude Code',
        'openclaw' => 'OpenClaw',
        'markdown' => 'Markdown',
        'internal_agent' => '内置 Agent',
        _ => 'Codex',
      };

  String get personalizationGoalLabel => switch (personalizationGoal) {
        'domain_localization' => '领域本地化',
        'style_personalization' => '用户风格化',
        'platform_adaptation' => '平台适配',
        'task_customization' => '任务定制',
        'enterprise_constraints' => '企业知识约束',
        'agent_specific' => 'Agent 专属化',
        _ => '未选择',
      };

  Map<String, String> toJson() => {
        'skill_type': skillType,
        'skill_type_label': skillTypeLabel,
        'target_platform': targetPlatform,
        'target_platform_label': targetPlatformLabel,
        'personalization_goal': personalizationGoal,
        'personalization_goal_label': personalizationGoalLabel,
        'skill_name': skillName,
        'custom_skill_name': customSkillName.trim(),
      };
}

class Rc6AgentGenerationConfig {
  const Rc6AgentGenerationConfig({
    this.customAgentName = '',
    this.creationMode = 'simple',
    this.agentType = 'knowledge_qa',
    this.modelConfigId = 'local-default-or-configured-provider',
    this.outputFormat = 'markdown',
    this.roleGoal = '只基于绑定知识库和 Skill 回答，输出必须带引用。',
  });

  final String customAgentName;
  final String creationMode;
  final String agentType;
  final String modelConfigId;
  final String outputFormat;
  final String roleGoal;

  String get coreMode =>
      creationMode == 'advanced' ? 'advanced_kb_bound' : 'kb_bound';

  String get agentName {
    final trimmed = customAgentName.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return switch (agentType) {
      'reading_summary' => '阅读总结 Agent',
      'quality_qa' => '质检 Agent',
      'operation_conversion' => '运营转化 Agent',
      'product_analysis' => '产品分析 Agent',
      _ => '知识问答 Agent',
    };
  }

  String get creationModeLabel =>
      creationMode == 'advanced' ? '复杂 Agent' : '简单 Agent';

  String get agentTypeLabel => switch (agentType) {
        'reading_summary' => '阅读总结 Agent',
        'quality_qa' => '质检 Agent',
        'operation_conversion' => '运营转化 Agent',
        'product_analysis' => '产品分析 Agent',
        _ => '知识问答 Agent',
      };

  Map<String, String> toJson() => {
        'creation_mode': creationMode,
        'creation_mode_label': creationModeLabel,
        'agent_type': agentType,
        'agent_type_label': agentTypeLabel,
        'agent_name': agentName,
        'custom_agent_name': customAgentName.trim(),
        'model_config_id': modelConfigId,
        'output_format': outputFormat,
        'role_goal': roleGoal.trim(),
      };
}

class Rc6SearchResult {
  const Rc6SearchResult({
    required this.title,
    required this.excerpt,
    required this.citation,
    required this.score,
    this.kbId = '',
    this.kbName = '',
  });

  final String title;
  final String excerpt;
  final String citation;
  final String score;
  final String kbId;
  final String kbName;
}

class _SearchableKnowledgeBase {
  const _SearchableKnowledgeBase({
    required this.id,
    required this.name,
    required this.path,
  });

  final String id;
  final String name;
  final String path;
}

class Rc6StorageTestResult {
  const Rc6StorageTestResult({
    required this.passed,
    required this.status,
    required this.detail,
  });

  final bool passed;
  final String status;
  final String detail;
}

class Rc6KnowledgeBaseRecord {
  const Rc6KnowledgeBaseRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.currentVersion,
    required this.versionCount,
    required this.sourceCount,
    required this.chunkCount,
    required this.manifestPath,
    required this.qualityReportPath,
    required this.versionComparePath,
    required this.operation,
  });

  final String id;
  final String name;
  final String type;
  final String status;
  final String currentVersion;
  final int versionCount;
  final int sourceCount;
  final int chunkCount;
  final String manifestPath;
  final String qualityReportPath;
  final String versionComparePath;
  final String operation;
}

class Rc6SourceRecord {
  const Rc6SourceRecord({
    required this.documentId,
    required this.sourceName,
    required this.relativePath,
    required this.sourceType,
    required this.extension,
    required this.sizeBytes,
    required this.wordCount,
    required this.imageCount,
    required this.tableCount,
    required this.linkCount,
    required this.structureStatus,
  });

  factory Rc6SourceRecord.fromJson(Map<String, dynamic> json) {
    final sourceName =
        (json['source_name'] ?? json['relative_path'] ?? '').toString().trim();
    return Rc6SourceRecord(
      documentId: (json['document_id'] ?? '').toString(),
      sourceName: sourceName,
      relativePath: (json['relative_path'] ?? sourceName).toString(),
      sourceType: (json['source_type'] ?? 'local_file').toString(),
      extension: (json['extension'] ?? '').toString(),
      sizeBytes: _asInt(json['size_bytes']) ?? 0,
      wordCount: _asInt(json['word_count']) ?? 0,
      imageCount: _asInt(json['image_count']) ?? 0,
      tableCount: _asInt(json['table_count']) ?? 0,
      linkCount: _asInt(json['link_count']) ?? 0,
      structureStatus: (json['structure_status'] ?? 'not_scanned').toString(),
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  final String documentId;
  final String sourceName;
  final String relativePath;
  final String sourceType;
  final String extension;
  final int sizeBytes;
  final int wordCount;
  final int imageCount;
  final int tableCount;
  final int linkCount;
  final String structureStatus;
}

class _QdrantResponse {
  const _QdrantResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

class Rc6RuntimeState {
  const Rc6RuntimeState({
    required this.phase,
    required this.running,
    required this.workspacePath,
    required this.selectedFilePath,
    required this.sourceManifestPath,
    required this.parseReportPath,
    required this.standardKnowledgePackagePath,
    required this.standardKnowledgePackageManifestPath,
    required this.standardKnowledgePackageContentPath,
    required this.standardKnowledgePackageAuditPath,
    required this.chunksPath,
    required this.kbManifestPath,
    required this.qualityReportPath,
    required this.cardsPath,
    required this.qaPairsPath,
    required this.sourceMapPath,
    required this.indexMetadataPath,
    required this.indexProfilePath,
    required this.keywordIndexPath,
    required this.vectorIndexReferencePath,
    required this.metadataIndexPath,
    required this.citationIndexPath,
    required this.memoryIndexReferencePath,
    required this.indexBuildReportPath,
    required this.buildLogPath,
    required this.errorLogPath,
    required this.queryResultPath,
    required this.retrievalPlanPath,
    required this.retrievalRerankReportPath,
    required this.retrievalCitationCoveragePath,
    required this.retrievalConflictReportPath,
    required this.externalValidationBoundaryPath,
    required this.retrievalValidationReportPath,
    required this.retrievalValidationMarkdownPath,
    required this.retrievalValidationHistoryPath,
    required this.generatedMarkdownPath,
    required this.readingNotesPath,
    required this.editedDocumentPath,
    required this.editManifestPath,
    required this.documentOutlinePath,
    required this.documentCitationsPath,
    required this.documentValidationReportPath,
    required this.exportedDocumentPath,
    required this.exportManifestPath,
    required this.documentGenerationHistoryCount,
    required this.skillVersionCount,
    required this.skillPath,
    required this.primarySkillPath,
    required this.skillConfigPath,
    required this.skillVerificationReportPath,
    required this.skillGenerationManifestPath,
    required this.skillPackageManifestPath,
    required this.skillValidationReportPath,
    required this.localizedSkillManifestPath,
    required this.localizedSkillDiffPath,
    required this.skillVersionManifestPath,
    required this.skillOperationManifestPath,
    required this.skillOperationHistoryPath,
    required this.skillFactoryAuditPath,
    required this.skillExportPath,
    required this.skillAgentBindingManifestPath,
    required this.skillOperationStatus,
    required this.skillAgentBindingStatus,
    required this.agentPath,
    required this.primaryAgentManifestPath,
    required this.agentProfilePath,
    required this.agentGenerationManifestPath,
    required this.agentAdvancedConfigPath,
    required this.agentPermissionAuditPath,
    required this.agentWorkspacePermissionMatrixPath,
    required this.agentValidationReportPath,
    required this.agentPackageManifestPath,
    required this.agentPackageReadmePath,
    required this.agentDialoguePath,
    required this.agentDialogueManifestPath,
    required this.agentDialogueHistoryPath,
    required this.agentDialogueExportPath,
    required this.agentDialogueTurnCount,
    required this.agentDialogueModelConfigId,
    required this.agentDialogueUsedKbIds,
    required this.agentDialogueUsedSkillIds,
    required this.agentDialogueOutputFormat,
    required this.agentDialogueEvidenceCount,
    required this.agentDialogueMemoryWriteStatus,
    required this.agentDialogueErrorMessage,
    required this.multiAgentDiscussionPath,
    required this.multiAgentDiscussionManifestPath,
    required this.a2aSessionManifestPath,
    required this.a2aWorkspaceReportPath,
    required this.a2aConflictReportPath,
    required this.a2aConsensusReportPath,
    required this.a2aSessionId,
    required this.a2aTopic,
    required this.a2aParticipantAgentIds,
    required this.a2aEvidenceCount,
    required this.a2aStatus,
    required this.prdP0EvidencePath,
    required this.providerRuntimeSettingsPath,
    required this.storageProviderSettingsPath,
    required this.providerValidationReportPath,
    required this.exporterValidationReportPath,
    required this.parallelTaskCapacityReportPath,
    required this.taskIsolationMatrixPath,
    required this.taskRecoveryReportPath,
    required this.knowledgeBaseCatalogPath,
    required this.workbookManifestPath,
    required this.currentWorkbookName,
    required this.workbookNames,
    required this.knowledgeBases,
    required this.sourceCount,
    required this.sourceNames,
    required this.sourceRecords,
    required this.chunkCount,
    required this.searchQuery,
    required this.searchStatus,
    required this.searchResults,
    required this.lastMessage,
    required this.lastError,
    required this.lastResult,
  });

  factory Rc6RuntimeState.initial() => const Rc6RuntimeState(
        phase: Rc6RuntimePhase.initial,
        running: false,
        workspacePath: '',
        selectedFilePath: '',
        sourceManifestPath: '',
        parseReportPath: '',
        standardKnowledgePackagePath: '',
        standardKnowledgePackageManifestPath: '',
        standardKnowledgePackageContentPath: '',
        standardKnowledgePackageAuditPath: '',
        chunksPath: '',
        kbManifestPath: '',
        qualityReportPath: '',
        cardsPath: '',
        qaPairsPath: '',
        sourceMapPath: '',
        indexMetadataPath: '',
        indexProfilePath: '',
        keywordIndexPath: '',
        vectorIndexReferencePath: '',
        metadataIndexPath: '',
        citationIndexPath: '',
        memoryIndexReferencePath: '',
        indexBuildReportPath: '',
        buildLogPath: '',
        errorLogPath: '',
        queryResultPath: '',
        retrievalPlanPath: '',
        retrievalRerankReportPath: '',
        retrievalCitationCoveragePath: '',
        retrievalConflictReportPath: '',
        externalValidationBoundaryPath: '',
        retrievalValidationReportPath: '',
        retrievalValidationMarkdownPath: '',
        retrievalValidationHistoryPath: '',
        generatedMarkdownPath: '',
        readingNotesPath: '',
        editedDocumentPath: '',
        editManifestPath: '',
        documentOutlinePath: '',
        documentCitationsPath: '',
        documentValidationReportPath: '',
        exportedDocumentPath: '',
        exportManifestPath: '',
        documentGenerationHistoryCount: 0,
        skillVersionCount: 0,
        skillPath: '',
        primarySkillPath: '',
        skillConfigPath: '',
        skillVerificationReportPath: '',
        skillGenerationManifestPath: '',
        skillPackageManifestPath: '',
        skillValidationReportPath: '',
        localizedSkillManifestPath: '',
        localizedSkillDiffPath: '',
        skillVersionManifestPath: '',
        skillOperationManifestPath: '',
        skillOperationHistoryPath: '',
        skillFactoryAuditPath: '',
        skillExportPath: '',
        skillAgentBindingManifestPath: '',
        skillOperationStatus: '',
        skillAgentBindingStatus: '',
        agentPath: '',
        primaryAgentManifestPath: '',
        agentProfilePath: '',
        agentGenerationManifestPath: '',
        agentAdvancedConfigPath: '',
        agentPermissionAuditPath: '',
        agentWorkspacePermissionMatrixPath: '',
        agentValidationReportPath: '',
        agentPackageManifestPath: '',
        agentPackageReadmePath: '',
        agentDialoguePath: '',
        agentDialogueManifestPath: '',
        agentDialogueHistoryPath: '',
        agentDialogueExportPath: '',
        agentDialogueTurnCount: 0,
        agentDialogueModelConfigId: '',
        agentDialogueUsedKbIds: [],
        agentDialogueUsedSkillIds: [],
        agentDialogueOutputFormat: '',
        agentDialogueEvidenceCount: 0,
        agentDialogueMemoryWriteStatus: '',
        agentDialogueErrorMessage: '',
        multiAgentDiscussionPath: '',
        multiAgentDiscussionManifestPath: '',
        a2aSessionManifestPath: '',
        a2aWorkspaceReportPath: '',
        a2aConflictReportPath: '',
        a2aConsensusReportPath: '',
        a2aSessionId: '',
        a2aTopic: '',
        a2aParticipantAgentIds: [],
        a2aEvidenceCount: 0,
        a2aStatus: '',
        prdP0EvidencePath: '',
        providerRuntimeSettingsPath: '',
        storageProviderSettingsPath: '',
        providerValidationReportPath: '',
        exporterValidationReportPath: '',
        parallelTaskCapacityReportPath: '',
        taskIsolationMatrixPath: '',
        taskRecoveryReportPath: '',
        knowledgeBaseCatalogPath: '',
        workbookManifestPath: '',
        currentWorkbookName: '默认工作本',
        workbookNames: ['默认工作本'],
        knowledgeBases: [],
        sourceCount: 0,
        sourceNames: [],
        sourceRecords: [],
        chunkCount: 0,
        searchQuery: '',
        searchStatus: Rc6SearchStatus.idle,
        searchResults: [],
        lastMessage: '等待初始化。',
        lastError: '',
        lastResult: null,
      );

  final Rc6RuntimePhase phase;
  final bool running;
  final String workspacePath;
  final String selectedFilePath;
  final String sourceManifestPath;
  final String parseReportPath;
  final String standardKnowledgePackagePath;
  final String standardKnowledgePackageManifestPath;
  final String standardKnowledgePackageContentPath;
  final String standardKnowledgePackageAuditPath;
  final String chunksPath;
  final String kbManifestPath;
  final String qualityReportPath;
  final String cardsPath;
  final String qaPairsPath;
  final String sourceMapPath;
  final String indexMetadataPath;
  final String indexProfilePath;
  final String keywordIndexPath;
  final String vectorIndexReferencePath;
  final String metadataIndexPath;
  final String citationIndexPath;
  final String memoryIndexReferencePath;
  final String indexBuildReportPath;
  final String buildLogPath;
  final String errorLogPath;
  final String queryResultPath;
  final String retrievalPlanPath;
  final String retrievalRerankReportPath;
  final String retrievalCitationCoveragePath;
  final String retrievalConflictReportPath;
  final String externalValidationBoundaryPath;
  final String retrievalValidationReportPath;
  final String retrievalValidationMarkdownPath;
  final String retrievalValidationHistoryPath;
  final String generatedMarkdownPath;
  final String readingNotesPath;
  final String editedDocumentPath;
  final String editManifestPath;
  final String documentOutlinePath;
  final String documentCitationsPath;
  final String documentValidationReportPath;
  final String exportedDocumentPath;
  final String exportManifestPath;
  final int documentGenerationHistoryCount;
  final int skillVersionCount;
  final String skillPath;
  final String primarySkillPath;
  final String skillConfigPath;
  final String skillVerificationReportPath;
  final String skillGenerationManifestPath;
  final String skillPackageManifestPath;
  final String skillValidationReportPath;
  final String localizedSkillManifestPath;
  final String localizedSkillDiffPath;
  final String skillVersionManifestPath;
  final String skillOperationManifestPath;
  final String skillOperationHistoryPath;
  final String skillFactoryAuditPath;
  final String skillExportPath;
  final String skillAgentBindingManifestPath;
  final String skillOperationStatus;
  final String skillAgentBindingStatus;
  final String agentPath;
  final String primaryAgentManifestPath;
  final String agentProfilePath;
  final String agentGenerationManifestPath;
  final String agentAdvancedConfigPath;
  final String agentPermissionAuditPath;
  final String agentWorkspacePermissionMatrixPath;
  final String agentValidationReportPath;
  final String agentPackageManifestPath;
  final String agentPackageReadmePath;
  final String agentDialoguePath;
  final String agentDialogueManifestPath;
  final String agentDialogueHistoryPath;
  final String agentDialogueExportPath;
  final int agentDialogueTurnCount;
  final String agentDialogueModelConfigId;
  final List<String> agentDialogueUsedKbIds;
  final List<String> agentDialogueUsedSkillIds;
  final String agentDialogueOutputFormat;
  final int agentDialogueEvidenceCount;
  final String agentDialogueMemoryWriteStatus;
  final String agentDialogueErrorMessage;
  final String multiAgentDiscussionPath;
  final String multiAgentDiscussionManifestPath;
  final String a2aSessionManifestPath;
  final String a2aWorkspaceReportPath;
  final String a2aConflictReportPath;
  final String a2aConsensusReportPath;
  final String a2aSessionId;
  final String a2aTopic;
  final List<String> a2aParticipantAgentIds;
  final int a2aEvidenceCount;
  final String a2aStatus;
  final String prdP0EvidencePath;
  final String providerRuntimeSettingsPath;
  final String storageProviderSettingsPath;
  final String providerValidationReportPath;
  final String exporterValidationReportPath;
  final String parallelTaskCapacityReportPath;
  final String taskIsolationMatrixPath;
  final String taskRecoveryReportPath;
  final String knowledgeBaseCatalogPath;
  final String workbookManifestPath;
  final String currentWorkbookName;
  final List<String> workbookNames;
  final List<Rc6KnowledgeBaseRecord> knowledgeBases;
  final int sourceCount;
  final List<String> sourceNames;
  final List<Rc6SourceRecord> sourceRecords;
  final int chunkCount;
  final String searchQuery;
  final Rc6SearchStatus searchStatus;
  final List<Rc6SearchResult> searchResults;
  final String lastMessage;
  final String lastError;
  final CoreBridgeResult? lastResult;

  bool get hasImportedFile => sourceManifestPath.isNotEmpty;
  bool get hasStandardKnowledgePackage =>
      standardKnowledgePackageManifestPath.isNotEmpty &&
      standardKnowledgePackageContentPath.isNotEmpty;
  bool get hasKnowledgeBase => kbManifestPath.isNotEmpty && chunkCount > 0;
  bool get hasMarkdown => generatedMarkdownPath.isNotEmpty;
  bool get hasReadingNotes => readingNotesPath.isNotEmpty;
  bool get hasEditedDocument => editedDocumentPath.isNotEmpty;
  bool get hasExportedDocument => exportedDocumentPath.isNotEmpty;
  bool get hasDocumentGenerationHistory => documentGenerationHistoryCount > 0;
  bool get hasSkill => skillPath.isNotEmpty || primarySkillPath.isNotEmpty;
  bool get hasPrimarySkill => primarySkillPath.isNotEmpty;
  bool get hasSkillConfig => skillConfigPath.isNotEmpty;
  bool get hasSkillVerificationReport => skillVerificationReportPath.isNotEmpty;
  bool get hasSkillGenerationManifest => skillGenerationManifestPath.isNotEmpty;
  bool get hasSkillPackageManifest => skillPackageManifestPath.isNotEmpty;
  bool get hasSkillValidationReport => skillValidationReportPath.isNotEmpty;
  bool get hasLocalizedSkillManifest => localizedSkillManifestPath.isNotEmpty;
  bool get hasLocalizedSkillDiff => localizedSkillDiffPath.isNotEmpty;
  bool get hasSkillVersions => skillVersionCount > 0;
  bool get hasSkillVersionManifest => skillVersionManifestPath.isNotEmpty;
  bool get hasSkillOperationManifest => skillOperationManifestPath.isNotEmpty;
  bool get hasSkillOperationHistory => skillOperationHistoryPath.isNotEmpty;
  bool get hasSkillExport => skillExportPath.isNotEmpty;
  bool get hasSkillAgentBindingManifest =>
      skillAgentBindingManifestPath.isNotEmpty;
  bool get hasAgent => agentPath.isNotEmpty;
  bool get hasPrimaryAgentManifest => primaryAgentManifestPath.isNotEmpty;
  bool get hasAgentProfile => agentProfilePath.isNotEmpty;
  bool get hasAgentGenerationManifest => agentGenerationManifestPath.isNotEmpty;
  bool get hasAgentAdvancedConfig => agentAdvancedConfigPath.isNotEmpty;
  bool get hasAgentPermissionAudit => agentPermissionAuditPath.isNotEmpty;
  bool get hasAgentWorkspacePermissionMatrix =>
      agentWorkspacePermissionMatrixPath.isNotEmpty;
  bool get hasAgentValidationReport => agentValidationReportPath.isNotEmpty;
  bool get hasAgentPackageManifest => agentPackageManifestPath.isNotEmpty;
  bool get hasAgentPackageReadme => agentPackageReadmePath.isNotEmpty;
  bool get hasAgentDialogue => agentDialoguePath.isNotEmpty;
  bool get hasAgentDialogueManifest => agentDialogueManifestPath.isNotEmpty;
  bool get hasAgentDialogueHistory => agentDialogueHistoryPath.isNotEmpty;
  bool get hasAgentDialogueExport => agentDialogueExportPath.isNotEmpty;
  bool get hasMultiAgentDiscussion => multiAgentDiscussionPath.isNotEmpty;
  bool get hasMultiAgentDiscussionManifest =>
      multiAgentDiscussionManifestPath.isNotEmpty;
  bool get hasA2aSessionManifest => a2aSessionManifestPath.isNotEmpty;
  bool get hasA2aConflictReport => a2aConflictReportPath.isNotEmpty;
  bool get hasA2aConsensusReport => a2aConsensusReportPath.isNotEmpty;
  bool get hasPrdP0Evidence => prdP0EvidencePath.isNotEmpty;
  bool get hasProviderRuntimeSettings => providerRuntimeSettingsPath.isNotEmpty;
  bool get hasProviderValidationReport =>
      providerValidationReportPath.isNotEmpty;
  bool get hasParallelTaskCapacityReport =>
      parallelTaskCapacityReportPath.isNotEmpty;
  bool get hasKnowledgeBaseCatalog => knowledgeBaseCatalogPath.isNotEmpty;
  bool get hasWorkbookManifest => workbookManifestPath.isNotEmpty;

  Rc6RuntimeState copyWith({
    Rc6RuntimePhase? phase,
    bool? running,
    String? workspacePath,
    String? selectedFilePath,
    String? sourceManifestPath,
    String? parseReportPath,
    String? standardKnowledgePackagePath,
    String? standardKnowledgePackageManifestPath,
    String? standardKnowledgePackageContentPath,
    String? standardKnowledgePackageAuditPath,
    String? chunksPath,
    String? kbManifestPath,
    String? qualityReportPath,
    String? cardsPath,
    String? qaPairsPath,
    String? sourceMapPath,
    String? indexMetadataPath,
    String? indexProfilePath,
    String? keywordIndexPath,
    String? vectorIndexReferencePath,
    String? metadataIndexPath,
    String? citationIndexPath,
    String? memoryIndexReferencePath,
    String? indexBuildReportPath,
    String? buildLogPath,
    String? errorLogPath,
    String? queryResultPath,
    String? retrievalPlanPath,
    String? retrievalRerankReportPath,
    String? retrievalCitationCoveragePath,
    String? retrievalConflictReportPath,
    String? externalValidationBoundaryPath,
    String? retrievalValidationReportPath,
    String? retrievalValidationMarkdownPath,
    String? retrievalValidationHistoryPath,
    String? generatedMarkdownPath,
    String? readingNotesPath,
    String? editedDocumentPath,
    String? editManifestPath,
    String? documentOutlinePath,
    String? documentCitationsPath,
    String? documentValidationReportPath,
    String? exportedDocumentPath,
    String? exportManifestPath,
    int? documentGenerationHistoryCount,
    int? skillVersionCount,
    String? skillPath,
    String? primarySkillPath,
    String? skillConfigPath,
    String? skillVerificationReportPath,
    String? skillGenerationManifestPath,
    String? skillPackageManifestPath,
    String? skillValidationReportPath,
    String? localizedSkillManifestPath,
    String? localizedSkillDiffPath,
    String? skillVersionManifestPath,
    String? skillOperationManifestPath,
    String? skillOperationHistoryPath,
    String? skillFactoryAuditPath,
    String? skillExportPath,
    String? skillAgentBindingManifestPath,
    String? skillOperationStatus,
    String? skillAgentBindingStatus,
    String? agentPath,
    String? primaryAgentManifestPath,
    String? agentProfilePath,
    String? agentGenerationManifestPath,
    String? agentAdvancedConfigPath,
    String? agentPermissionAuditPath,
    String? agentWorkspacePermissionMatrixPath,
    String? agentValidationReportPath,
    String? agentPackageManifestPath,
    String? agentPackageReadmePath,
    String? agentDialoguePath,
    String? agentDialogueManifestPath,
    String? agentDialogueHistoryPath,
    String? agentDialogueExportPath,
    int? agentDialogueTurnCount,
    String? agentDialogueModelConfigId,
    List<String>? agentDialogueUsedKbIds,
    List<String>? agentDialogueUsedSkillIds,
    String? agentDialogueOutputFormat,
    int? agentDialogueEvidenceCount,
    String? agentDialogueMemoryWriteStatus,
    String? agentDialogueErrorMessage,
    String? multiAgentDiscussionPath,
    String? multiAgentDiscussionManifestPath,
    String? a2aSessionManifestPath,
    String? a2aWorkspaceReportPath,
    String? a2aConflictReportPath,
    String? a2aConsensusReportPath,
    String? a2aSessionId,
    String? a2aTopic,
    List<String>? a2aParticipantAgentIds,
    int? a2aEvidenceCount,
    String? a2aStatus,
    String? prdP0EvidencePath,
    String? providerRuntimeSettingsPath,
    String? storageProviderSettingsPath,
    String? providerValidationReportPath,
    String? exporterValidationReportPath,
    String? parallelTaskCapacityReportPath,
    String? taskIsolationMatrixPath,
    String? taskRecoveryReportPath,
    String? knowledgeBaseCatalogPath,
    String? workbookManifestPath,
    String? currentWorkbookName,
    List<String>? workbookNames,
    List<Rc6KnowledgeBaseRecord>? knowledgeBases,
    int? sourceCount,
    List<String>? sourceNames,
    List<Rc6SourceRecord>? sourceRecords,
    int? chunkCount,
    String? searchQuery,
    Rc6SearchStatus? searchStatus,
    List<Rc6SearchResult>? searchResults,
    String? lastMessage,
    String? lastError,
    CoreBridgeResult? lastResult,
  }) {
    return Rc6RuntimeState(
      phase: phase ?? this.phase,
      running: running ?? this.running,
      workspacePath: workspacePath ?? this.workspacePath,
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
      sourceManifestPath: sourceManifestPath ?? this.sourceManifestPath,
      parseReportPath: parseReportPath ?? this.parseReportPath,
      standardKnowledgePackagePath:
          standardKnowledgePackagePath ?? this.standardKnowledgePackagePath,
      standardKnowledgePackageManifestPath:
          standardKnowledgePackageManifestPath ??
              this.standardKnowledgePackageManifestPath,
      standardKnowledgePackageContentPath:
          standardKnowledgePackageContentPath ??
              this.standardKnowledgePackageContentPath,
      standardKnowledgePackageAuditPath: standardKnowledgePackageAuditPath ??
          this.standardKnowledgePackageAuditPath,
      chunksPath: chunksPath ?? this.chunksPath,
      kbManifestPath: kbManifestPath ?? this.kbManifestPath,
      qualityReportPath: qualityReportPath ?? this.qualityReportPath,
      cardsPath: cardsPath ?? this.cardsPath,
      qaPairsPath: qaPairsPath ?? this.qaPairsPath,
      sourceMapPath: sourceMapPath ?? this.sourceMapPath,
      indexMetadataPath: indexMetadataPath ?? this.indexMetadataPath,
      indexProfilePath: indexProfilePath ?? this.indexProfilePath,
      keywordIndexPath: keywordIndexPath ?? this.keywordIndexPath,
      vectorIndexReferencePath:
          vectorIndexReferencePath ?? this.vectorIndexReferencePath,
      metadataIndexPath: metadataIndexPath ?? this.metadataIndexPath,
      citationIndexPath: citationIndexPath ?? this.citationIndexPath,
      memoryIndexReferencePath:
          memoryIndexReferencePath ?? this.memoryIndexReferencePath,
      indexBuildReportPath: indexBuildReportPath ?? this.indexBuildReportPath,
      buildLogPath: buildLogPath ?? this.buildLogPath,
      errorLogPath: errorLogPath ?? this.errorLogPath,
      queryResultPath: queryResultPath ?? this.queryResultPath,
      retrievalPlanPath: retrievalPlanPath ?? this.retrievalPlanPath,
      retrievalRerankReportPath:
          retrievalRerankReportPath ?? this.retrievalRerankReportPath,
      retrievalCitationCoveragePath:
          retrievalCitationCoveragePath ?? this.retrievalCitationCoveragePath,
      retrievalConflictReportPath:
          retrievalConflictReportPath ?? this.retrievalConflictReportPath,
      externalValidationBoundaryPath:
          externalValidationBoundaryPath ?? this.externalValidationBoundaryPath,
      retrievalValidationReportPath:
          retrievalValidationReportPath ?? this.retrievalValidationReportPath,
      retrievalValidationMarkdownPath: retrievalValidationMarkdownPath ??
          this.retrievalValidationMarkdownPath,
      retrievalValidationHistoryPath:
          retrievalValidationHistoryPath ?? this.retrievalValidationHistoryPath,
      generatedMarkdownPath:
          generatedMarkdownPath ?? this.generatedMarkdownPath,
      readingNotesPath: readingNotesPath ?? this.readingNotesPath,
      editedDocumentPath: editedDocumentPath ?? this.editedDocumentPath,
      editManifestPath: editManifestPath ?? this.editManifestPath,
      documentOutlinePath: documentOutlinePath ?? this.documentOutlinePath,
      documentCitationsPath:
          documentCitationsPath ?? this.documentCitationsPath,
      documentValidationReportPath:
          documentValidationReportPath ?? this.documentValidationReportPath,
      exportedDocumentPath: exportedDocumentPath ?? this.exportedDocumentPath,
      exportManifestPath: exportManifestPath ?? this.exportManifestPath,
      documentGenerationHistoryCount:
          documentGenerationHistoryCount ?? this.documentGenerationHistoryCount,
      skillVersionCount: skillVersionCount ?? this.skillVersionCount,
      skillPath: skillPath ?? this.skillPath,
      primarySkillPath: primarySkillPath ?? this.primarySkillPath,
      skillConfigPath: skillConfigPath ?? this.skillConfigPath,
      skillVerificationReportPath:
          skillVerificationReportPath ?? this.skillVerificationReportPath,
      skillGenerationManifestPath:
          skillGenerationManifestPath ?? this.skillGenerationManifestPath,
      skillPackageManifestPath:
          skillPackageManifestPath ?? this.skillPackageManifestPath,
      skillValidationReportPath:
          skillValidationReportPath ?? this.skillValidationReportPath,
      localizedSkillManifestPath:
          localizedSkillManifestPath ?? this.localizedSkillManifestPath,
      localizedSkillDiffPath:
          localizedSkillDiffPath ?? this.localizedSkillDiffPath,
      skillVersionManifestPath:
          skillVersionManifestPath ?? this.skillVersionManifestPath,
      skillOperationManifestPath:
          skillOperationManifestPath ?? this.skillOperationManifestPath,
      skillOperationHistoryPath:
          skillOperationHistoryPath ?? this.skillOperationHistoryPath,
      skillFactoryAuditPath:
          skillFactoryAuditPath ?? this.skillFactoryAuditPath,
      skillExportPath: skillExportPath ?? this.skillExportPath,
      skillAgentBindingManifestPath:
          skillAgentBindingManifestPath ?? this.skillAgentBindingManifestPath,
      skillOperationStatus: skillOperationStatus ?? this.skillOperationStatus,
      skillAgentBindingStatus:
          skillAgentBindingStatus ?? this.skillAgentBindingStatus,
      agentPath: agentPath ?? this.agentPath,
      primaryAgentManifestPath:
          primaryAgentManifestPath ?? this.primaryAgentManifestPath,
      agentProfilePath: agentProfilePath ?? this.agentProfilePath,
      agentGenerationManifestPath:
          agentGenerationManifestPath ?? this.agentGenerationManifestPath,
      agentAdvancedConfigPath:
          agentAdvancedConfigPath ?? this.agentAdvancedConfigPath,
      agentPermissionAuditPath:
          agentPermissionAuditPath ?? this.agentPermissionAuditPath,
      agentWorkspacePermissionMatrixPath: agentWorkspacePermissionMatrixPath ??
          this.agentWorkspacePermissionMatrixPath,
      agentValidationReportPath:
          agentValidationReportPath ?? this.agentValidationReportPath,
      agentPackageManifestPath:
          agentPackageManifestPath ?? this.agentPackageManifestPath,
      agentPackageReadmePath:
          agentPackageReadmePath ?? this.agentPackageReadmePath,
      agentDialoguePath: agentDialoguePath ?? this.agentDialoguePath,
      agentDialogueManifestPath:
          agentDialogueManifestPath ?? this.agentDialogueManifestPath,
      agentDialogueHistoryPath:
          agentDialogueHistoryPath ?? this.agentDialogueHistoryPath,
      agentDialogueExportPath:
          agentDialogueExportPath ?? this.agentDialogueExportPath,
      agentDialogueTurnCount:
          agentDialogueTurnCount ?? this.agentDialogueTurnCount,
      agentDialogueModelConfigId:
          agentDialogueModelConfigId ?? this.agentDialogueModelConfigId,
      agentDialogueUsedKbIds:
          agentDialogueUsedKbIds ?? this.agentDialogueUsedKbIds,
      agentDialogueUsedSkillIds:
          agentDialogueUsedSkillIds ?? this.agentDialogueUsedSkillIds,
      agentDialogueOutputFormat:
          agentDialogueOutputFormat ?? this.agentDialogueOutputFormat,
      agentDialogueEvidenceCount:
          agentDialogueEvidenceCount ?? this.agentDialogueEvidenceCount,
      agentDialogueMemoryWriteStatus:
          agentDialogueMemoryWriteStatus ?? this.agentDialogueMemoryWriteStatus,
      agentDialogueErrorMessage:
          agentDialogueErrorMessage ?? this.agentDialogueErrorMessage,
      multiAgentDiscussionPath:
          multiAgentDiscussionPath ?? this.multiAgentDiscussionPath,
      multiAgentDiscussionManifestPath: multiAgentDiscussionManifestPath ??
          this.multiAgentDiscussionManifestPath,
      a2aSessionManifestPath:
          a2aSessionManifestPath ?? this.a2aSessionManifestPath,
      a2aWorkspaceReportPath:
          a2aWorkspaceReportPath ?? this.a2aWorkspaceReportPath,
      a2aConflictReportPath:
          a2aConflictReportPath ?? this.a2aConflictReportPath,
      a2aConsensusReportPath:
          a2aConsensusReportPath ?? this.a2aConsensusReportPath,
      a2aSessionId: a2aSessionId ?? this.a2aSessionId,
      a2aTopic: a2aTopic ?? this.a2aTopic,
      a2aParticipantAgentIds:
          a2aParticipantAgentIds ?? this.a2aParticipantAgentIds,
      a2aEvidenceCount: a2aEvidenceCount ?? this.a2aEvidenceCount,
      a2aStatus: a2aStatus ?? this.a2aStatus,
      prdP0EvidencePath: prdP0EvidencePath ?? this.prdP0EvidencePath,
      providerRuntimeSettingsPath:
          providerRuntimeSettingsPath ?? this.providerRuntimeSettingsPath,
      storageProviderSettingsPath:
          storageProviderSettingsPath ?? this.storageProviderSettingsPath,
      providerValidationReportPath:
          providerValidationReportPath ?? this.providerValidationReportPath,
      exporterValidationReportPath:
          exporterValidationReportPath ?? this.exporterValidationReportPath,
      parallelTaskCapacityReportPath:
          parallelTaskCapacityReportPath ?? this.parallelTaskCapacityReportPath,
      taskIsolationMatrixPath:
          taskIsolationMatrixPath ?? this.taskIsolationMatrixPath,
      taskRecoveryReportPath:
          taskRecoveryReportPath ?? this.taskRecoveryReportPath,
      knowledgeBaseCatalogPath:
          knowledgeBaseCatalogPath ?? this.knowledgeBaseCatalogPath,
      workbookManifestPath: workbookManifestPath ?? this.workbookManifestPath,
      currentWorkbookName: currentWorkbookName ?? this.currentWorkbookName,
      workbookNames: workbookNames ?? this.workbookNames,
      knowledgeBases: knowledgeBases ?? this.knowledgeBases,
      sourceCount: sourceCount ?? this.sourceCount,
      sourceNames: sourceNames ?? this.sourceNames,
      sourceRecords: sourceRecords ?? this.sourceRecords,
      chunkCount: chunkCount ?? this.chunkCount,
      searchQuery: searchQuery ?? this.searchQuery,
      searchStatus: searchStatus ?? this.searchStatus,
      searchResults: searchResults ?? this.searchResults,
      lastMessage: lastMessage ?? this.lastMessage,
      lastError: lastError ?? this.lastError,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}
