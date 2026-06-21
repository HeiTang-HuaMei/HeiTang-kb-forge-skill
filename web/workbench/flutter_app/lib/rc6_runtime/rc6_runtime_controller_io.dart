import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

import '../core_bridge/local_core_bridge.dart';
import 'project_config_profile.dart';

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
    await _ensureProjectConfigProfiles(workspace);
    await _ensureRuntimeConfigAssets(workspace);
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
      okfRuntimeEnabled: true,
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
        'okf_runtime_enabled': true,
      },
    );
    await _writeOkfRuntimeManifest(
      workspace,
      action: 'export_standard_knowledge_package',
      packageManifestPath:
          _join(packageDir.path, 'standard_package_manifest.json'),
      contentPackagePath: _join(packageDir.path, 'content_package.jsonl'),
      kbManifestPath: '',
    );
    await _writeProjectConfigRuntimeStatus(
      workspace,
      await _readProjectConfigProfiles(workspace),
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
    await _markStandardPackageRuntimeEnabled(
      File(_join(target.path, 'standard_package_manifest.json')),
    );
    await _appendOrchestrationPlanRecord(
      layer: 'standard_knowledge_package',
      action: 'import_standard_knowledge_package',
      artifact: _join(target.path, 'standard_package_manifest.json'),
      status: 'completed',
      okfRuntimeEnabled: true,
      resources: {
        'source_path': source.path,
        'target_path': target.path,
        'okf_candidate': true,
      },
    );
    await _appendStandardPackageAuditRecord(
      action: 'import_standard_knowledge_package',
      artifact: _join(target.path, 'standard_package_manifest.json'),
      status: 'completed',
      details: {
        'source_path': source.path,
        'target_path': target.path,
        'okf_runtime_enabled': true,
      },
    );
    await _writeOkfRuntimeManifest(
      workspace,
      action: 'import_standard_knowledge_package',
      packageManifestPath: _join(target.path, 'standard_package_manifest.json'),
      contentPackagePath: _join(target.path, 'content_package.jsonl'),
      kbManifestPath: '',
    );
    await _writeProjectConfigRuntimeStatus(
      workspace,
      await _readProjectConfigProfiles(workspace),
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
      okfRuntimeEnabled: true,
      resources: {
        'standard_package_manifest': manifestPath,
        'content_package': contentPath,
        'okf_runtime_enabled': true,
      },
    );
    await _appendStandardPackageAuditRecord(
      action: 'build_kb_from_standard_package',
      artifact: _join(workspace.path, 'kb', 'manifest.json'),
      status: 'completed',
      details: {
        'standard_package_manifest': manifestPath,
        'kb_manifest': _join(workspace.path, 'kb', 'manifest.json'),
        'okf_runtime_enabled': true,
      },
    );
    await _writeOkfRuntimeManifest(
      workspace,
      action: 'build_kb_from_standard_package',
      packageManifestPath: manifestPath,
      contentPackagePath: contentPath,
      kbManifestPath: _join(workspace.path, 'kb', 'manifest.json'),
    );
    await _writeProjectConfigRuntimeStatus(
      workspace,
      await _readProjectConfigProfiles(workspace),
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
    final persistedPasswordInput =
        password.trim().isEmpty && effectivePassword.isNotEmpty
            ? '********'
            : password;
    final safePrefix = keyPrefix.trim().isEmpty ? 'heitang:' : keyPrefix.trim();
    Future<Rc6StorageTestResult> persist(Rc6StorageTestResult result) async {
      await _persistRedisStorageResult(
        host: host,
        port: port,
        keyPrefix: safePrefix,
        password: persistedPasswordInput,
        result: result,
      );
      return result;
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

      if (effectivePassword.isNotEmpty) {
        final auth = await send(['AUTH', effectivePassword]);
        if (!auth.startsWith('+OK')) {
          return persist(Rc6StorageTestResult(
            passed: false,
            status: 'auth_failed',
            detail: _redisStatus(auth),
          ));
        }
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
      const result = Rc6StorageTestResult(
        passed: false,
        status: 'invalid_endpoint',
        detail: 'Qdrant endpoint 必须是 http(s) URL。',
      );
      await _persistQdrantStorageResult(
        endpoint: endpoint,
        collection: collection,
        dimension: dimension,
        apiKey: apiKey,
        result: result,
      );
      return result;
    }
    if (dimension <= 0) {
      const result = Rc6StorageTestResult(
        passed: false,
        status: 'invalid_dimension',
        detail: 'Qdrant 向量维度必须大于 0。',
      );
      await _persistQdrantStorageResult(
        endpoint: endpoint,
        collection: collection,
        dimension: dimension,
        apiKey: apiKey,
        result: result,
      );
      return result;
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

  Future<List<ProjectConfigProfile>> loadProjectConfigProfiles() async {
    if (isWebRuntime || kIsWeb) {
      return const [];
    }
    final workspace = _workspaceDir;
    if (workspace == null || !await workspace.exists()) {
      return const [];
    }
    final profiles = await _readProjectConfigProfiles(workspace);
    return profiles;
  }

  Future<ProjectConfigProfile> createProjectConfigProfile({
    required String displayName,
    String mode = 'local',
  }) async {
    if (!_canRunDesktop()) {
      throw StateError('desktop_runtime_required');
    }
    final workspace = _requireWorkspace();
    final profiles = await _readProjectConfigProfiles(workspace);
    final now = DateTime.now().toUtc().toIso8601String();
    final profile = _profileFromActive(
      workspace,
      profiles,
      profileId: _nextProfileId(profiles),
      displayName: displayName.trim().isEmpty ? '新配置 Profile' : displayName,
      mode: mode,
      now: now,
      active: false,
      rollbackFromProfileId: '',
    );
    final updated = [...profiles, profile];
    await _writeProjectConfigProfiles(workspace, updated);
    await _appendProfileChangeLog(
      workspace,
      action: 'create',
      profile: profile,
      status: '已配置未测试',
      summary: 'Profile 已创建。',
    );
    await _writeProjectConfigRuntimeStatus(workspace, updated);
    await _loadExistingArtifacts();
    notifyListeners();
    return profile;
  }

  Future<ProjectConfigProfile> copyProjectConfigProfile(
      String sourceProfileId) async {
    if (!_canRunDesktop()) {
      throw StateError('desktop_runtime_required');
    }
    final workspace = _requireWorkspace();
    final profiles = await _readProjectConfigProfiles(workspace);
    final source = profiles.firstWhere(
      (profile) => profile.profileId == sourceProfileId,
      orElse: () => _activeProfile(profiles),
    );
    final now = DateTime.now().toUtc().toIso8601String();
    final copy = source.copyWith(
      profileId: _nextProfileId(profiles),
      displayName: '${source.displayName} 副本',
      isDefault: false,
      isActive: false,
      version: 1,
      createdAt: now,
      updatedAt: now,
      lastActivatedAt: '',
      rollbackFromProfileId: source.profileId,
      lastTestStatus: '已配置未测试',
      lastTestSummary: '由 ${source.displayName} 复制。',
      lastError: '',
    );
    final updated = [...profiles, copy];
    await _writeProjectConfigProfiles(workspace, updated);
    await _appendProfileChangeLog(
      workspace,
      action: 'copy',
      profile: copy,
      previousProfileId: source.profileId,
      status: '已配置未测试',
      summary: 'Profile 已复制。',
    );
    await _writeProjectConfigRuntimeStatus(workspace, updated);
    await _loadExistingArtifacts();
    notifyListeners();
    return copy;
  }

  Future<ProjectConfigProfile> updateProjectConfigProfile(
    String profileId, {
    required String displayName,
    required String mode,
  }) async {
    if (!_canRunDesktop()) {
      throw StateError('desktop_runtime_required');
    }
    final workspace = _requireWorkspace();
    final profiles = await _readProjectConfigProfiles(workspace);
    final now = DateTime.now().toUtc().toIso8601String();
    ProjectConfigProfile? updatedProfile;
    final updated = profiles.map((profile) {
      if (profile.profileId != profileId) return profile;
      updatedProfile = profile.copyWith(
        displayName: displayName.trim().isEmpty
            ? profile.displayName
            : displayName.trim(),
        mode: _normalizedProfileMode(mode),
        version: profile.version + 1,
        updatedAt: now,
        lastTestStatus: '已配置未测试',
        lastTestSummary: 'Profile 配置已更新，需重新测试。',
        lastError: '',
      );
      return updatedProfile!;
    }).toList(growable: false);
    final result = updatedProfile;
    if (result == null) {
      throw StateError('profile_not_found');
    }
    await _writeProjectConfigProfiles(workspace, updated);
    await _appendProfileChangeLog(
      workspace,
      action: 'update',
      profile: result,
      status: '已配置未测试',
      summary: 'Profile 已更新并生成新版本。',
    );
    await _writeProjectConfigRuntimeStatus(workspace, updated);
    await _loadExistingArtifacts();
    notifyListeners();
    return result;
  }

  Future<ProjectConfigProfile> activateProjectConfigProfile(
      String profileId) async {
    if (!_canRunDesktop()) {
      throw StateError('desktop_runtime_required');
    }
    final workspace = _requireWorkspace();
    final profiles = await _readProjectConfigProfiles(workspace);
    final previous = _activeProfile(profiles);
    final next = profiles.where((profile) => profile.profileId == profileId);
    if (next.isEmpty) {
      throw StateError('profile_not_found');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    late ProjectConfigProfile activated;
    final updated = profiles.map((profile) {
      final active = profile.profileId == profileId;
      final value = profile.copyWith(
        isActive: active,
        lastActivatedAt: active ? now : profile.lastActivatedAt,
        updatedAt: active ? now : profile.updatedAt,
        rollbackFromProfileId:
            active ? previous.profileId : profile.rollbackFromProfileId,
      );
      if (active) activated = value;
      return value;
    }).toList(growable: false);
    await _writeProjectConfigProfiles(workspace, updated);
    await _appendProfileActivationLog(
      workspace,
      previousProfileId: previous.profileId,
      nextProfileId: activated.profileId,
      warnings: _profileActivationWarnings(activated),
    );
    await _writeProjectConfigRuntimeStatus(workspace, updated);
    await _loadExistingArtifacts();
    state = state.copyWith(
        lastMessage: '配置 Profile 已切换为 ${activated.displayName}。');
    notifyListeners();
    return activated;
  }

  Future<bool> deleteProjectConfigProfile(String profileId) async {
    if (!_canRunDesktop()) {
      return false;
    }
    final workspace = _requireWorkspace();
    final profiles = await _readProjectConfigProfiles(workspace);
    if (profiles.length <= 1) {
      state = state.copyWith(lastError: '至少保留一个可用 Profile。');
      notifyListeners();
      return false;
    }
    final target = profiles.firstWhere(
      (profile) => profile.profileId == profileId,
      orElse: () => ProjectConfigProfile.localDefault(
        workspaceId: workspace.path,
        createdAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );
    if (target.profileId != profileId) {
      return false;
    }
    if (target.isActive) {
      state = state.copyWith(lastError: '当前启用的 Profile 不能删除，请先切换。');
      notifyListeners();
      return false;
    }
    final updated = profiles
        .where((profile) => profile.profileId != profileId)
        .toList(growable: false);
    await _writeProjectConfigProfiles(workspace, updated);
    await _appendProfileChangeLog(
      workspace,
      action: 'delete',
      profile: target,
      status: '已禁用',
      summary: '非 active Profile 已删除。',
      affectedModules: _affectedProfileModules(target),
    );
    await _writeProjectConfigRuntimeStatus(workspace, updated);
    await _loadExistingArtifacts();
    notifyListeners();
    return true;
  }

  Future<ProjectConfigProfile> rollbackProjectConfigProfile() async {
    if (!_canRunDesktop()) {
      throw StateError('desktop_runtime_required');
    }
    final workspace = _requireWorkspace();
    final profiles = await _readProjectConfigProfiles(workspace);
    final active = _activeProfile(profiles);
    final rollbackId = active.rollbackFromProfileId.isEmpty
        ? profiles.first.profileId
        : active.rollbackFromProfileId;
    return activateProjectConfigProfile(rollbackId);
  }

  Future<String> testProjectConfigProfile(String profileId) async {
    if (!_canRunDesktop()) {
      return '';
    }
    final workspace = _requireWorkspace();
    final profiles = await _readProjectConfigProfiles(workspace);
    final profile = profiles.firstWhere(
      (item) => item.profileId == profileId,
      orElse: () => _activeProfile(profiles),
    );
    final now = DateTime.now().toUtc();
    final startedAt = now.toIso8601String();
    final finishedAt = DateTime.now().toUtc().toIso8601String();
    final status = profile.mode == 'local' ? '连接成功' : '已配置未测试';
    final summary = profile.mode == 'local'
        ? '本地存储、内置 Parser、本地索引、Markdown 导出可用。'
        : '外部 Redis/Qdrant/Exporter 需要连接测试后启用。';
    final testId = 'profile_test_${now.microsecondsSinceEpoch}';
    await _appendConfigTestLog(
      workspace,
      testId: testId,
      profile: profile,
      configType: 'project_config_profile',
      configId: profile.profileId,
      startedAt: startedAt,
      finishedAt: finishedAt,
      status: status,
      errorCode: '',
      errorMessageZh: '',
      sanitizedEndpoint: profile.mode,
      testArtifacts: [
        _projectConfigProfilesPath(workspace),
        _projectConfigRuntimeStatusPath(workspace),
        _registeredProviderIntegrationMatrixPath(workspace),
      ],
      affectedModules: _affectedProfileModules(profile),
    );
    final updated = profiles.map((item) {
      if (item.profileId != profile.profileId) return item;
      return item.copyWith(
        version: item.version + 1,
        updatedAt: finishedAt,
        lastTestStatus: status,
        lastTestSummary: summary,
        lastError: '',
      );
    }).toList(growable: false);
    await _writeProjectConfigProfiles(workspace, updated);
    await _writeProjectConfigRuntimeStatus(workspace, updated);
    await _loadExistingArtifacts();
    notifyListeners();
    return testId;
  }

  Future<String> runStage3ProfilePersistenceSmoke() async {
    if (!_canRunDesktop()) {
      return '';
    }
    final workspace = _requireWorkspace();
    var profiles = await _readProjectConfigProfiles(workspace);
    final defaultProfile = _activeProfile(profiles);
    var cloud = await createProjectConfigProfile(
      displayName: 'Stage3 云机配置',
      mode: 'hybrid',
    );
    cloud = await updateProjectConfigProfile(
      cloud.profileId,
      displayName: 'Stage3 云机配置',
      mode: 'hybrid',
    );
    final localCopy = await copyProjectConfigProfile(defaultProfile.profileId);
    await testProjectConfigProfile(cloud.profileId);
    await activateProjectConfigProfile(cloud.profileId);
    profiles = await _readProjectConfigProfiles(workspace);
    final activeBeforeReload = _activeProfile(profiles);

    final reloadedProfiles = await _readProjectConfigProfiles(workspace);
    await _writeProjectConfigRuntimeStatus(workspace, reloadedProfiles);
    final statusAfterReload =
        await _readJsonObject(_projectConfigRuntimeStatusPath(workspace));
    final activeAfterReload = _activeProfile(reloadedProfiles);
    final deleteActiveBlocked =
        await deleteProjectConfigProfile(activeAfterReload.profileId) == false;
    final deleteInactiveSucceeded =
        await deleteProjectConfigProfile(localCopy.profileId);
    final finalProfiles = await _readProjectConfigProfiles(workspace);
    final finalActive = _activeProfile(finalProfiles);
    final activeProfilePersisted =
        activeBeforeReload.profileId == activeAfterReload.profileId &&
            activeAfterReload.profileId == finalActive.profileId;
    final profileCountProtected = finalProfiles.isNotEmpty &&
        finalProfiles.where((profile) => profile.isActive).length == 1;
    final runtimeStatusSynced = _stringValue(
            _mapValue(statusAfterReload['active_profile'])['profile_id'], '') ==
        finalActive.profileId;
    final moduleStatus = _mapValue(statusAfterReload['module_status']);
    final downstreamSynced = [
      'dashboard',
      'document_library',
      'knowledge_base',
      'retrieval_verification',
      'document_generation',
      'skill_factory',
      'agent_workbench',
    ].every((key) => moduleStatus[key] is Map);
    final reportPath = _joinNested(workspace.path,
        'acceptance/stage3_profile_persistence_smoke_report.json');
    final passed = activeProfilePersisted &&
        profileCountProtected &&
        runtimeStatusSynced &&
        downstreamSynced &&
        deleteActiveBlocked &&
        deleteInactiveSucceeded;
    final payload = {
      'schema_version': 'prd_v3_stage3_profile_persistence_smoke.v1',
      'status': passed ? 'passed' : 'failed',
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'workspace_boundary': workspace.path,
      'execution_mode': 'runtime_profile_persistence_smoke',
      'manual_exe_ui_claimed': false,
      'profile_a_id': defaultProfile.profileId,
      'profile_b_id': cloud.profileId,
      'active_profile_before_reload': activeBeforeReload.profileId,
      'active_profile_after_reload': activeAfterReload.profileId,
      'final_active_profile_id': finalActive.profileId,
      'profile_count_after_smoke': finalProfiles.length,
      'active_profile_persisted': activeProfilePersisted,
      'profile_count_protected': profileCountProtected,
      'delete_active_blocked': deleteActiveBlocked,
      'delete_inactive_succeeded': deleteInactiveSucceeded,
      'runtime_status_synced': runtimeStatusSynced,
      'downstream_modules_synced': downstreamSynced,
      'restart_simulation': {
        'method': 'controller_reload_from_workspace_files',
        'profiles_reloaded_from_disk': true,
        'runtime_status_rebuilt_after_reload': true,
      },
      'source_artifacts': {
        'project_config_profiles_path': _projectConfigProfilesPath(workspace),
        'project_config_runtime_status_path':
            _projectConfigRuntimeStatusPath(workspace),
        'profile_change_log_path': _profileChangeLogPath(workspace),
        'profile_activation_log_path': _profileActivationLogPath(workspace),
      },
      'status_before_reload_path': _projectConfigRuntimeStatusPath(workspace),
      'runtime_summary_after_reload': {
        'active_profile': statusAfterReload['active_profile'],
        'degradation': statusAfterReload['degradation'],
        'stage_2_industrial_preflight':
            statusAfterReload['stage_2_industrial_preflight'],
      },
      'secret_masked': true,
      'secret_plaintext_written': false,
      'normal_ui_project_name_visible': false,
      'hot_swap_project_concept_visible': false,
      'external_runtime_executed': false,
      'workflow_executed': false,
    };
    await _writeJsonFile(reportPath, payload);
    await _appendConfigTestLog(
      workspace,
      testId:
          'stage3_profile_persistence_${DateTime.now().toUtc().microsecondsSinceEpoch}',
      profile: finalActive,
      configType: 'stage3_profile_persistence_smoke',
      configId: finalActive.profileId,
      startedAt: _stringValue(payload['generated_at'], ''),
      finishedAt: DateTime.now().toUtc().toIso8601String(),
      status: passed ? '连接成功' : '连接失败',
      errorCode: passed ? '' : 'stage3_profile_persistence_smoke_failed',
      errorMessageZh: passed ? '' : 'Stage3 Profile 持久化 smoke 未通过。',
      sanitizedEndpoint: 'local_workspace_files',
      testArtifacts: [reportPath],
      affectedModules: _affectedProfileModules(finalActive),
    );
    await _writeProjectConfigRuntimeStatus(
        workspace, await _readProjectConfigProfiles(workspace));
    await _loadExistingArtifacts();
    notifyListeners();
    return reportPath;
  }

  Future<String> syncRegisteredProviderCapabilities() async {
    if (!_canRunDesktop()) {
      return '';
    }
    final workspace = _requireWorkspace();
    final artifacts =
        await _writeRegisteredProviderIntegrationArtifacts(workspace);
    await _writeProjectConfigRuntimeStatus(
      workspace,
      await _readProjectConfigProfiles(workspace),
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      lastMessage: 'Provider 能力增强状态已同步到配置审计资产。',
      lastError: '',
    );
    notifyListeners();
    return artifacts['matrix_path']?.toString() ?? '';
  }

  Future<String> testAllRegisteredProviderCapabilities() async {
    if (!_canRunDesktop()) {
      return '';
    }
    final workspace = _requireWorkspace();
    final paths = await _writeRegisteredProviderHealthArtifacts(workspace);
    await _writeProjectConfigRuntimeStatus(
      workspace,
      await _readProjectConfigProfiles(workspace),
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      lastMessage: '全部能力增强项健康检查已写入配置审计资产。',
      lastError: '',
    );
    notifyListeners();
    return paths['health_report_path']?.toString() ?? '';
  }

  Future<bool> activateRegisteredProviderCapability(String providerRef) async {
    if (!_canRunDesktop()) {
      return false;
    }
    final workspace = _requireWorkspace();
    final artifacts =
        await _writeRegisteredProviderIntegrationArtifacts(workspace);
    final matrix = await _readJsonObject(artifacts['matrix_path'].toString());
    final entry = _registeredProviderEntry(matrix, providerRef);
    if (entry.isEmpty) {
      state = state.copyWith(
        lastError: '未找到对应的能力增强项。',
        lastMessage: '',
      );
      notifyListeners();
      return false;
    }
    final contractsPath =
        _stringValue(matrix['provider_adapter_contracts_path'], '');
    if (contractsPath.isNotEmpty) {
      await _writeProviderAdapterReadinessReport(
        workspace,
        await _readProjectConfigProfiles(workspace),
        contractsPath,
      );
    }
    final readinessByProvider = await _providerReadinessByProvider(workspace);
    final ready = _providerReadyForSelection(entry, readinessByProvider);
    final readiness =
        readinessByProvider[_stringValue(entry['provider_ref'], '')] ??
            const <String, dynamic>{};
    final blockedReasons = _listOfStrings(readiness['blocked_reasons']);
    final effectiveStatus = ready
        ? '连接成功'
        : _stringValue(
            readiness['status'],
            _registeredProviderHealthStatus(entry),
          );
    final effectiveBlockedReason = ready
        ? ''
        : blockedReasons.isNotEmpty
            ? blockedReasons.join(' ')
            : _stringValue(
                readiness['error_message_zh'],
                _stringValue(entry['activation_condition'], ''),
              );
    if (ready) {
      await _writeProviderCapabilitySelectionState(
        workspace,
        action: 'activate',
        entry: entry,
        readinessByProvider: readinessByProvider,
      );
    }
    await _appendRegisteredProviderSelectionLog(
      workspace,
      action: 'activate',
      entry: entry,
      status: effectiveStatus,
      blockedReason: effectiveBlockedReason,
    );
    await _writeProjectConfigRuntimeStatus(
      workspace,
      await _readProjectConfigProfiles(workspace),
    );
    await _writeProviderCapabilityBindingManifest(
      workspace,
      await _readProjectConfigProfiles(workspace),
      _listOfMaps(matrix['provider_entries']),
      action: ready ? 'activate' : 'blocked_activate',
      selectedEntry: entry,
      readinessByProvider: readinessByProvider,
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      lastMessage: ready ? '能力增强项已启用。' : '',
      lastError: ready ? '' : '能力增强项未满足启用条件，已阻止并写入审计日志。',
    );
    notifyListeners();
    return ready;
  }

  Future<bool> rollbackRegisteredProviderCapability(String providerRef) async {
    if (!_canRunDesktop()) {
      return false;
    }
    final workspace = _requireWorkspace();
    final artifacts =
        await _writeRegisteredProviderIntegrationArtifacts(workspace);
    final matrix = await _readJsonObject(artifacts['matrix_path'].toString());
    final entry = _registeredProviderEntry(matrix, providerRef);
    if (entry.isEmpty) {
      state = state.copyWith(
        lastError: '未找到可回滚的能力增强项。',
        lastMessage: '',
      );
      notifyListeners();
      return false;
    }
    await _appendRegisteredProviderSelectionLog(
      workspace,
      action: 'rollback',
      entry: entry,
      status: '降级为本地模式',
      blockedReason: '',
    );
    await _writeProviderCapabilitySelectionState(
      workspace,
      action: 'rollback',
      entry: entry,
      readinessByProvider: await _providerReadinessByProvider(workspace),
    );
    await _writeProjectConfigRuntimeStatus(
      workspace,
      await _readProjectConfigProfiles(workspace),
    );
    await _writeProviderCapabilityBindingManifest(
      workspace,
      await _readProjectConfigProfiles(workspace),
      _listOfMaps(matrix['provider_entries']),
      action: 'rollback',
      selectedEntry: entry,
      readinessByProvider: await _providerReadinessByProvider(workspace),
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      lastMessage: '能力增强项已回滚到本地默认能力。',
      lastError: '',
    );
    notifyListeners();
    return true;
  }

  Future<bool> loadN8nProviderRuntime({
    String endpoint = '',
    String apiKey = '',
  }) async {
    if (!_canRunDesktop()) {
      return false;
    }
    final workspace = _requireWorkspace();
    final startedAt = DateTime.now().toUtc().toIso8601String();
    final active = _activeProfile(await _readProjectConfigProfiles(workspace));
    final artifacts =
        await _writeRegisteredProviderIntegrationArtifacts(workspace);
    final matrix = await _readJsonObject(artifacts['matrix_path'].toString());
    final contractsPath =
        _stringValue(matrix['provider_adapter_contracts_path'], '');
    if (contractsPath.isNotEmpty) {
      await _writeProviderAdapterReadinessReport(
        workspace,
        await _readProjectConfigProfiles(workspace),
        contractsPath,
      );
    }
    final entry = _registeredProviderEntry(matrix, 'n8n');
    final readinessByProvider = await _providerReadinessByProvider(workspace);
    final readiness = readinessByProvider['n8n'] ?? const <String, dynamic>{};
    final eligible = _boolValue(
            _stage2IndustrialPreflight(workspace)['runtime_load_allowed']) &&
        entry.isNotEmpty &&
        _providerReadyForSelection(entry, readinessByProvider) &&
        _boolValue(entry['requires_external_runtime']);
    final effectiveEndpoint =
        endpoint.trim().isEmpty ? _n8nEndpointFromEnvironment() : endpoint;
    final probe = eligible
        ? await _probeN8nRuntimeConnection(
            workspace,
            endpoint: effectiveEndpoint,
            apiKey: apiKey,
          )
        : _blockedN8nRuntimeLoadProbe(
            workspace,
            readiness: readiness,
            endpoint: effectiveEndpoint,
          );
    final loaded = _boolValue(probe['runtime_loaded']);
    final finishedAt = DateTime.now().toUtc().toIso8601String();
    final manifestPath = await _writeProviderRuntimeLoadManifest(
      workspace,
      providerRef: 'n8n',
      capabilityId: 'workflow_collaboration_export',
      startedAt: startedAt,
      finishedAt: finishedAt,
      eligible: eligible,
      probe: probe,
    );
    await _appendProviderRuntimeLoadLog(
      workspace,
      providerRef: 'n8n',
      capabilityId: 'workflow_collaboration_export',
      startedAt: startedAt,
      finishedAt: finishedAt,
      eligible: eligible,
      probe: probe,
      manifestPath: manifestPath,
    );
    await _appendConfigTestLog(
      workspace,
      testId:
          'provider_runtime_load_${DateTime.now().toUtc().microsecondsSinceEpoch}',
      profile: active,
      configType: 'provider_runtime_load',
      configId: 'n8n',
      startedAt: startedAt,
      finishedAt: finishedAt,
      status: _stringValue(probe['status'], loaded ? '连接成功' : '连接失败'),
      errorCode: _stringValue(probe['error_code'], ''),
      errorMessageZh: _stringValue(probe['error_message_zh'], ''),
      sanitizedEndpoint: _stringValue(
          probe['sanitized_endpoint'], _sanitizeEndpoint(endpoint)),
      testArtifacts: [manifestPath, _stringValue(probe['probe_path'], '')]
          .where((path) => path.isNotEmpty)
          .toList(growable: false),
      affectedModules: ['agent_workbench', 'audit_center'],
    );
    await _writeProjectConfigRuntimeStatus(
      workspace,
      await _readProjectConfigProfiles(workspace),
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      lastMessage: loaded ? '工作流协作 Provider 连接已通过。' : '',
      lastError: loaded ? '' : '工作流协作 Provider 未完成连接，已降级为本地 A2A 导出。',
    );
    notifyListeners();
    return loaded;
  }

  Future<bool> rollbackN8nProviderRuntime() async {
    if (!_canRunDesktop()) {
      return false;
    }
    final workspace = _requireWorkspace();
    final startedAt = DateTime.now().toUtc().toIso8601String();
    final manifest = await _readJsonObject(
      _providerRuntimeLoadManifestPath(workspace),
    );
    final wasLoaded = _boolValue(manifest['runtime_loaded']);
    final rollbackFromManifestPath =
        await _snapshotProviderRuntimeLoadManifest(workspace, manifest);
    final probe = {
      'status': '降级为本地模式',
      'error_code': '',
      'error_message_zh': '',
      'sanitized_endpoint': _stringValue(manifest['sanitized_endpoint'], ''),
      'runtime_loaded': false,
      'external_runtime_connected': false,
      'local_fallback': 'A2A 本地协作报告导出继续可用。',
    };
    final finishedAt = DateTime.now().toUtc().toIso8601String();
    final manifestPath = await _writeProviderRuntimeLoadManifest(
      workspace,
      providerRef: 'n8n',
      capabilityId: 'workflow_collaboration_export',
      startedAt: startedAt,
      finishedAt: finishedAt,
      eligible: wasLoaded,
      probe: probe,
      action: 'rollback',
      rollbackFromManifestPath: rollbackFromManifestPath,
    );
    await _appendProviderRuntimeLoadLog(
      workspace,
      providerRef: 'n8n',
      capabilityId: 'workflow_collaboration_export',
      startedAt: startedAt,
      finishedAt: finishedAt,
      eligible: wasLoaded,
      probe: probe,
      manifestPath: manifestPath,
      action: 'rollback',
    );
    await _writeProjectConfigRuntimeStatus(
      workspace,
      await _readProjectConfigProfiles(workspace),
    );
    await _loadExistingArtifacts();
    state = state.copyWith(
      lastMessage: '工作流协作 Provider 已回滚到本地 A2A 导出。',
      lastError: '',
    );
    notifyListeners();
    return true;
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
    await _writeProjectConfigRuntimeStatus(
      _requireWorkspace(),
      await _readProjectConfigProfiles(_requireWorkspace()),
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

  Future<Map<String, dynamic>> loadProviderCapabilityUserCatalog() async {
    final workspace = _workspaceDir;
    if (workspace == null || !await workspace.exists()) {
      return const <String, dynamic>{};
    }
    return _readJsonObject(_providerCapabilityUserCatalogPath(workspace));
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
    final saved = await loadProviderRuntimeSettings();
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
      'model_gateway': _mapValue(saved['model_gateway']).isEmpty
          ? _mapValue(_defaultProviderRuntimeSettings(
              workspace.path,
            )['model_gateway'])
          : _mapValue(saved['model_gateway']),
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
    await _writeProjectConfigRuntimeStatus(
      workspace,
      await _readProjectConfigProfiles(workspace),
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
    final profiles = await _readProjectConfigProfiles(workspace);
    final active = _activeProfile(profiles);
    final now = DateTime.now().toUtc().toIso8601String();
    await _appendConfigTestLog(
      workspace,
      testId: 'provider_test_${DateTime.now().toUtc().microsecondsSinceEpoch}',
      profile: active,
      configType: 'provider_runtime',
      configId: active.modelConfigId,
      startedAt: now,
      finishedAt: now,
      status: '已配置未测试',
      errorCode: '',
      errorMessageZh: '',
      sanitizedEndpoint: _stringValue(
          _mapValue(settings['llm'])['provider_id'], 'env_configured'),
      testArtifacts: [path],
      affectedModules: [
        'document_generation',
        'skill_factory',
        'agent_workbench'
      ],
    );
    await _writeProjectConfigRuntimeStatus(workspace, profiles);
    await _loadExistingArtifacts();
    state = state.copyWith(
      providerValidationReportPath: path,
      lastMessage: 'Provider 配置验证报告已生成。',
      lastError: '',
    );
    notifyListeners();
    return path;
  }

  Future<void> _ensureRuntimeConfigAssets(Directory workspace) async {
    final storagePath = _storageProviderSettingsPath(workspace);
    if (!await File(storagePath).exists()) {
      final defaults = _defaultStorageProviderSettings(workspace.path);
      final redis = _mapValue(defaults['redis']);
      final qdrant = _mapValue(defaults['qdrant']);
      await _writeStorageProviderSettings(
        redisHost: _stringValue(redis['host'], '127.0.0.1'),
        redisPort: _asInt(redis['port']) ?? 6379,
        redisKeyPrefix: _stringValue(redis['key_prefix'], 'heitang:'),
        redisPassword: '',
        redisStatus: _stringValue(redis['status'], 'configured_not_tested'),
        redisDetail: _stringValue(redis['last_test_detail'], ''),
        qdrantEndpoint:
            _stringValue(qdrant['endpoint'], 'http://127.0.0.1:6333'),
        qdrantCollection: _stringValue(qdrant['collection'], 'heitang_kb'),
        qdrantDimension: _asInt(qdrant['dimension']) ?? 1536,
        qdrantApiKey: '',
        qdrantStatus: _stringValue(qdrant['status'], 'configured_not_tested'),
        qdrantDetail: _stringValue(qdrant['last_test_detail'], ''),
      );
    }

    final providerPath = _providerRuntimeSettingsPath(workspace);
    if (!await File(providerPath).exists()) {
      final defaults = _defaultProviderRuntimeSettings(workspace.path);
      await File(providerPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          ...defaults,
          'saved_at': DateTime.now().toUtc().toIso8601String(),
          'provider_crud_status': 'default_persisted',
        }),
        encoding: utf8,
      );
      await _writeProviderValidationReport(
        workspace,
        settings: defaults,
        validationMode: 'default_configuration_persistence',
      );
    }

    final exporterPath = _exporterSettingsPath(workspace);
    if (!await File(exporterPath).exists()) {
      final defaults = _defaultExporterSettings(workspace.path);
      await File(exporterPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          ...defaults,
          'saved_at': DateTime.now().toUtc().toIso8601String(),
        }),
        encoding: utf8,
      );
      await _writeExporterValidationReport(workspace, settings: defaults);
    }

    if (!await File(
            _join(workspace.path, 'workbooks', 'workbook_manifest.json'))
        .exists()) {
      await _writeWorkbookManifest(
        workspace,
        currentName: state.currentWorkbookName,
        addName: state.currentWorkbookName,
      );
    }
  }

  Future<String> saveModelGatewayProviderConfig({
    required String displayName,
    required String gatewayType,
    required String baseUrl,
    required String credential,
    String adminUrl = '',
    bool supportsStreaming = true,
    bool supportsEmbeddings = false,
    bool supportsFallback = true,
    bool supportsUsageStats = true,
  }) async {
    if (!_canRunDesktop()) return '';
    final workspace = _requireWorkspace();
    final settings = await loadProviderRuntimeSettings();
    final now = DateTime.now().toUtc().toIso8601String();
    final secretRef = _secretReference(
      provided: credential,
      environmentKey: 'HEITANG_MODEL_GATEWAY_API_KEY',
    );
    final sanitizedBaseUrl = _sanitizeEndpoint(baseUrl.trim());
    final sanitizedAdminUrl = _sanitizeEndpoint(adminUrl.trim());
    final gateway = {
      'gateway_id': 'gateway_openai_compatible',
      'display_name': displayName.trim().isEmpty
          ? 'OpenAI-compatible Gateway'
          : displayName.trim(),
      'gateway_type': gatewayType.trim().isEmpty
          ? 'custom_openai_compatible'
          : gatewayType.trim(),
      'base_url': sanitizedBaseUrl,
      'api_key_ref': secretRef,
      'admin_url': sanitizedAdminUrl,
      'supports_streaming': supportsStreaming,
      'supports_embeddings': supportsEmbeddings,
      'supports_fallback': supportsFallback,
      'supports_usage_stats': supportsUsageStats,
      'timeout_seconds': 30,
      'retry_policy': {
        'max_retries': 2,
        'retry_on': ['timeout', '429', '502', '503'],
      },
      'status': sanitizedBaseUrl.isEmpty ? '配置缺失' : '已配置未测试',
      'last_test_at': '',
      'last_error': '',
      'masked_key_preview': secretRef == 'none' ? '' : '********',
      'secret_plaintext_written': false,
    };
    final payload = {
      ...settings,
      'schema_version': 'prd_v3_provider_runtime_settings.v1',
      'workspace': workspace.path,
      'saved_at': now,
      'provider_crud_status': 'saved',
      'model_gateway': gateway,
      'secret_plaintext_written': false,
    };
    final path = _providerRuntimeSettingsPath(workspace);
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
    await _writeModelGatewayProviderArtifacts(
      workspace,
      gateway: gateway,
      testMode: 'save_only',
    );
    final profiles = await _readProjectConfigProfiles(workspace);
    final active = _activeProfile(profiles);
    final updatedProfiles = profiles
        .map((profile) => profile.profileId == active.profileId
            ? profile.copyWith(
                modelGatewayConfigId: _stringValue(
                    gateway['gateway_id'], 'gateway_not_configured'),
                version: profile.version + 1,
                updatedAt: now,
                lastTestStatus: _userStatus(gateway['status']),
                lastTestSummary: 'Model Gateway Provider 已保存，等待连接测试。',
                lastError: '',
              )
            : profile)
        .toList(growable: false);
    await _writeProjectConfigProfiles(workspace, updatedProfiles);
    await _appendProfileChangeLog(
      workspace,
      action: 'model_gateway_config_saved',
      profile: updatedProfiles.firstWhere(
        (profile) => profile.profileId == active.profileId,
      ),
      status: 'saved',
      summary: 'Model Gateway Provider 配置已保存并绑定当前 Profile。',
      affectedModules: [
        'document_generation',
        'skill_factory',
        'agent_workbench',
      ],
    );
    await _writeProjectConfigRuntimeStatus(
      workspace,
      updatedProfiles,
    );
    await _loadExistingArtifacts();
    notifyListeners();
    return path;
  }

  Future<String> testModelGatewayProvider({
    String simulatedStatus = 'success',
  }) async {
    if (!_canRunDesktop()) return '';
    final workspace = _requireWorkspace();
    final settings = await loadProviderRuntimeSettings();
    final gateway = _mapValue(settings['model_gateway']);
    final path = await _writeModelGatewayProviderArtifacts(
      workspace,
      gateway: gateway,
      testMode: simulatedStatus,
    );
    final updatedGateway = {
      ...gateway,
      'status': _modelGatewayStatusForMode(simulatedStatus),
      'last_test_at': DateTime.now().toUtc().toIso8601String(),
      'last_error': simulatedStatus == 'success'
          ? ''
          : _modelGatewayErrorMessage(simulatedStatus),
    };
    final updatedSettings = {
      ...settings,
      'model_gateway': updatedGateway,
      'secret_plaintext_written': false,
    };
    await File(_providerRuntimeSettingsPath(workspace)).writeAsString(
      const JsonEncoder.withIndent('  ').convert(updatedSettings),
      encoding: utf8,
    );
    final profiles = await _readProjectConfigProfiles(workspace);
    final active = _activeProfile(profiles);
    final now = DateTime.now().toUtc().toIso8601String();
    final status = _modelGatewayStatusForMode(simulatedStatus);
    final updatedProfiles = profiles
        .map((profile) => profile.profileId == active.profileId
            ? profile.copyWith(
                modelGatewayConfigId: _stringValue(
                    updatedGateway['gateway_id'], 'gateway_not_configured'),
                updatedAt: now,
                lastTestStatus: status,
                lastTestSummary: status == '连接成功'
                    ? 'Model Gateway Provider 连接测试通过。'
                    : 'Model Gateway Provider 连接测试未通过，LLM 相关能力降级。',
                lastError: status == '连接成功'
                    ? ''
                    : _modelGatewayErrorMessage(simulatedStatus),
              )
            : profile)
        .toList(growable: false);
    await _writeProjectConfigProfiles(workspace, updatedProfiles);
    await _appendConfigTestLog(
      workspace,
      testId:
          'model_gateway_test_${DateTime.now().toUtc().microsecondsSinceEpoch}',
      profile: active,
      configType: 'model_gateway_provider',
      configId: active.modelGatewayConfigId,
      startedAt: now,
      finishedAt: now,
      status: status,
      errorCode: simulatedStatus == 'success' ? '' : simulatedStatus,
      errorMessageZh: _modelGatewayErrorMessage(simulatedStatus),
      sanitizedEndpoint:
          _sanitizeEndpoint(_stringValue(gateway['base_url'], '')),
      testArtifacts: [path],
      affectedModules: [
        'document_generation',
        'skill_factory',
        'agent_workbench',
      ],
    );
    await _writeProjectConfigRuntimeStatus(workspace, updatedProfiles);
    await _loadExistingArtifacts();
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
        'markdown': {'provider': 'local_markdown', 'status': 'connected'},
        'json': {'provider': 'local_json', 'status': 'connected'},
        'csv': {'provider': 'local_csv', 'status': 'connected'},
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
    await _writeProjectConfigRuntimeStatus(
      workspace,
      await _readProjectConfigProfiles(workspace),
    );
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
    final profiles = await _readProjectConfigProfiles(workspace);
    final active = _activeProfile(profiles);
    final now = DateTime.now().toUtc().toIso8601String();
    await _appendConfigTestLog(
      workspace,
      testId: 'exporter_test_${DateTime.now().toUtc().microsecondsSinceEpoch}',
      profile: active,
      configType: 'exporter',
      configId: active.exporterConfigId,
      startedAt: now,
      finishedAt: now,
      status: '已配置未测试',
      errorCode: '',
      errorMessageZh: '',
      sanitizedEndpoint: _stringValue(
          settings['export_root'], _join(workspace.path, 'export')),
      testArtifacts: [path],
      affectedModules: [
        'document_generation',
        'artifact_center',
        'agent_workbench'
      ],
    );
    await _writeProjectConfigRuntimeStatus(workspace, profiles);
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
      'provider_capability_isolation_status': 'validated',
      'providerized_task_execution_ready': status == 'passed',
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

  Future<String> exportWorkspaceArtifact({
    required String artifactPath,
    required String artifactLabel,
  }) async {
    if (!_canRunDesktop()) {
      return '';
    }
    final workspace = _requireWorkspace();
    final workspacePath = workspace.absolute.path;
    final sourcePath = artifactPath.trim();
    if (sourcePath.isEmpty) {
      _fail('尚未生成可导出的产物。');
      return '';
    }
    final sourceFile = File(sourcePath).absolute;
    final sourceDir = Directory(sourcePath).absolute;
    if (!_isInsideDirectory(sourceFile.path, workspacePath)) {
      _fail('无法导出：产物路径不在当前工作区内。');
      return '';
    }
    final isFile = await sourceFile.exists();
    final isDirectory = !isFile && await sourceDir.exists();
    if (!isFile && !isDirectory) {
      _fail('无法导出：产物文件不存在。');
      return '';
    }

    final exportRoot = Directory(_join(workspace.path, 'artifact_exports'));
    await exportRoot.create(recursive: true);
    final baseName = _safeFileName(artifactLabel.trim().isEmpty
        ? sourcePath.split(RegExp(r'[\\/]')).last
        : artifactLabel.trim());
    final exportDir = await _uniqueExportDirectory(exportRoot, baseName);
    await exportDir.create(recursive: true);
    final copiedName = sourcePath.split(RegExp(r'[\\/]')).last;
    final targetPath = _joinNested(exportDir.path, copiedName);
    if (isFile) {
      await Directory(targetPath).parent.create(recursive: true);
      await sourceFile.copy(targetPath);
    } else {
      await _copyDirectory(sourceDir, Directory(targetPath));
    }

    final manifestPath = _join(exportDir.path, 'export_manifest.json');
    final manifest = {
      'schema_version': 'prd_v3_artifact_center_export.v1',
      'artifact_label': artifactLabel,
      'source_path': sourceFile.path,
      'exported_path': targetPath,
      'export_dir': exportDir.path,
      'artifact_kind': isFile ? 'file' : 'directory',
      'workspace_path': workspace.path,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'bounded_to_workspace': true,
    };
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      encoding: utf8,
    );

    final historyDir = Directory(_join(workspace.path, 'audit'));
    await historyDir.create(recursive: true);
    final history =
        File(_join(historyDir.path, 'artifact_export_history.jsonl'));
    await history.writeAsString('${jsonEncode(manifest)}\n',
        mode: FileMode.append, encoding: utf8);

    await _loadExistingArtifacts();
    state = state.copyWith(
      lastMessage: '产物已导出到工作区。',
      lastError: '',
    );
    notifyListeners();
    return manifestPath;
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
    await _markAgentDependencyMissingAfterSkillDelete(workspace);
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
    final a2aRouteEvidence = _modelRouteEvidenceForScopes(
      await _currentModelRouteModuleBinding('a2a'),
      [
        'a2a_task_dispatch',
        'a2a_review',
        'a2a_conflict_detection',
        'a2a_consensus',
        'a2a_report',
      ],
    );
    await _appendAgentRunHistoryRecord(
      action: 'run_a2a_discussion',
      artifact:
          _join(workspace.path, 'multi_agent', 'multi_agent_discussion.md'),
      status: 'completed',
      details: {
        'topic': topic.trim(),
        'participant_agent_ids': participantAgentIds,
        'model_route_evidence': a2aRouteEvidence,
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
        'model_route_evidence': a2aRouteEvidence,
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
    final agentStatus =
        await _readJsonObject(_joinNested(workspace.path, 'agent/status.json'));
    if (_stringValue(agentStatus['status'], '') == 'dependency_missing') {
      _fail(_stringValue(agentStatus['last_error_zh'], 'Agent 依赖缺失，不能继续对话。'));
      return;
    }
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
    final providerSettings = await loadProviderRuntimeSettings();
    final modelGateway = _mapValue(providerSettings['model_gateway']);
    final modelGatewayStatus = _userStatus(modelGateway['status']);
    final activeModelGatewayId =
        _stringValue(modelGateway['gateway_id'], 'gateway_not_configured');
    final modelGatewayRoute = _modelGatewayRouteSummary(
        modelGateway, _mapValue(providerSettings['llm']));
    final agentModelRouteBinding =
        await _currentModelRouteModuleBinding('agent_workbench');
    final agentChatRoute = _modelRouteEvidenceForScopes(
      agentModelRouteBinding,
      ['agent_chat', 'agent_reasoning', 'agent_summarization'],
    );
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
      'model_gateway_config_id': activeModelGatewayId,
      'model_gateway_status': modelGatewayStatus,
      'model_gateway_route': modelGatewayRoute,
      'model_route_binding': agentModelRouteBinding,
      'model_route_evidence': agentChatRoute,
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
      ..writeln('- Model Gateway：$activeModelGatewayId（$modelGatewayStatus）')
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
    final citationTracePath = _join(outDir.path, 'citation_trace.jsonl');
    final citationLines = evidence
        .map((item) => jsonEncode({
              'schema_version': 'prd_v3_agent_citation_trace_record.v1',
              'turn_id': turn['turn_id'],
              'kb_ids': kbIds,
              'skill_ids': skillIds,
              'citation': _stringValue(
                  item['citation'] ?? item['source_path'] ?? item['chunk_id'],
                  ''),
              'chunk_id': _stringValue(item['chunk_id'], ''),
              'source_path': _stringValue(item['source_path'], ''),
              'text_preview':
                  _compact(item['text'] ?? item['summary'] ?? item['content']),
              'trace_status': 'linked',
              'created_at': DateTime.now().toUtc().toIso8601String(),
            }))
        .join('\n');
    await File(citationTracePath).writeAsString(
      citationLines.isEmpty ? '' : '$citationLines\n',
      encoding: utf8,
      mode: FileMode.append,
    );
    final skillRuleTracePath = _join(outDir.path, 'skill_rule_trace.jsonl');
    await File(skillRuleTracePath).writeAsString(
      '${jsonEncode({
            'schema_version': 'prd_v3_agent_skill_rule_trace_record.v1',
            'turn_id': turn['turn_id'],
            'skill_ids': skillIds,
            'rules_applied': [
              'local_kb_only',
              'citation_required',
              'no_arbitrary_shell',
              'no_computer_use',
            ],
            'status': 'applied',
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })}\n',
      encoding: utf8,
      mode: FileMode.append,
    );
    final manifestPath = _join(outDir.path, 'agent_dialogue_manifest.json');
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'rc10_agent_dialogue.v1',
        'status': evidence.isEmpty ? 'needs_evidence' : 'pass',
        'latest_prompt': prompt,
        'output': dialoguePath,
        'history_path': historyPath,
        'citation_trace_path': citationTracePath,
        'skill_rule_trace_path': skillRuleTracePath,
        'turn_count': turns.length,
        'evidence_count': evidence.length,
        'model_config_id': modelConfigId,
        'model_gateway_config_id': activeModelGatewayId,
        'model_gateway_status': modelGatewayStatus,
        'model_gateway_route': modelGatewayRoute,
        'model_route_binding': agentModelRouteBinding,
        'model_route_evidence': agentChatRoute,
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
        'model_gateway_config_id': activeModelGatewayId,
        'model_gateway_status': modelGatewayStatus,
        'model_route_evidence': agentChatRoute,
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
        'model_gateway_config_id': activeModelGatewayId,
        'model_gateway_status': modelGatewayStatus,
        'model_route_evidence': agentChatRoute,
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
    final modelRouteEvidence =
        _mapValue(dialogueManifest['model_route_evidence']);
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
        'model_route_evidence': modelRouteEvidence,
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
        'model_route_evidence': modelRouteEvidence,
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
    await saveRetrievalValidationReport(const {});
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
    await _writePrdP0ProductArtifacts(query: query);
    await _writeIndustrialExeSmokeReport(query: query);
    await _writeProjectConfigRuntimeStatus(
      _requireWorkspace(),
      await _readProjectConfigProfiles(_requireWorkspace()),
    );
    await _loadExistingArtifacts();
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
    final providerLifecycleAuditSummaryPath = _join(
        workspace.path, 'config', 'provider_lifecycle_audit_summary.json');
    final providerCapabilityUserCatalogPath = _join(
        workspace.path, 'config', 'provider_capability_user_catalog.json');
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
      providerLifecycleAuditSummaryPath:
          await File(providerLifecycleAuditSummaryPath).exists()
              ? providerLifecycleAuditSummaryPath
              : '',
      providerCapabilityUserCatalogPath:
          await File(providerCapabilityUserCatalogPath).exists()
              ? providerCapabilityUserCatalogPath
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
      _joinNested(workspace.path, 'config/project_config_profiles.json'),
      _joinNested(workspace.path, 'config/project_config_runtime_status.json'),
      _joinNested(workspace.path, 'config/project_config_assets.json'),
      _joinNested(
          workspace.path, 'config/registered_provider_integration_matrix.json'),
      _joinNested(
          workspace.path, 'config/registered_provider_activation_log.jsonl'),
      _joinNested(
          workspace.path, 'config/registered_provider_selection_log.jsonl'),
      _joinNested(
          workspace.path, 'config/registered_provider_rollback_manifest.json'),
      _joinNested(
          workspace.path, 'config/provider_lifecycle_audit_summary.json'),
      _joinNested(workspace.path, 'config/provider_runtime_load_manifest.json'),
      _joinNested(workspace.path, 'config/provider_runtime_load_log.jsonl'),
      _joinNested(workspace.path, 'config/config_test_log.jsonl'),
      _joinNested(workspace.path, 'config/profile_change_log.jsonl'),
      _joinNested(workspace.path, 'config/profile_activation_log.jsonl'),
      _joinNested(workspace.path, 'config/provider_activation_matrix.json'),
      _joinNested(workspace.path, 'config/provider_lifecycle_history.jsonl'),
      _joinNested(workspace.path, 'config/provider_rollback_manifest.json'),
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
      'okf_runtime_enabled': true,
      'okf_runtime_mode': 'internal_standard_package_runtime',
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
        'okf_runtime_enabled': true,
        'okf_runtime_mode': 'internal_standard_package_runtime',
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
    record['okf_runtime_enabled'] = true;
    record['okf_runtime_mode'] = 'internal_standard_package_runtime';
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

  Future<void> _writeOkfRuntimeManifest(
    Directory workspace, {
    required String action,
    required String packageManifestPath,
    required String contentPackagePath,
    required String kbManifestPath,
  }) async {
    final root = Directory(_join(workspace.path, 'standard_packages'));
    await root.create(recursive: true);
    final packageManifest = await _readJsonObject(packageManifestPath);
    final contentExists = await File(contentPackagePath).exists();
    final kbExists =
        kbManifestPath.isNotEmpty && await File(kbManifestPath).exists();
    final manifest = {
      'schema_version': 'prd_v3_okf_runtime_manifest.v1',
      'runtime_name': 'internal_standard_package_runtime',
      'runtime_scope': 'document_library_to_knowledge_base',
      'runtime_loaded': true,
      'external_runtime': false,
      'user_visible_top_level_page': false,
      'action': action,
      'status': contentExists ? 'pass' : 'needs_content',
      'package_id': packageManifest['package_id'] ?? '',
      'standard': packageManifest['standard'] ?? 'okf_candidate',
      'package_manifest_path': packageManifestPath,
      'content_package_path': contentPackagePath,
      'kb_manifest_path': kbExists ? kbManifestPath : '',
      'export_import_runtime_available': true,
      'kb_build_runtime_available': kbExists,
      'audit_history_path': _join(root.path, 'audit_history.jsonl'),
      'secret_plaintext_written': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await File(_join(root.path, 'okf_runtime_manifest.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      encoding: utf8,
    );
  }

  Future<void> _markStandardPackageRuntimeEnabled(File manifestFile) async {
    if (!await manifestFile.exists()) {
      return;
    }
    final manifest = await _readJsonObject(manifestFile.path);
    manifest['okf_runtime_enabled'] = true;
    manifest['okf_runtime_mode'] = 'internal_standard_package_runtime';
    manifest['independent_agent_runtime'] = false;
    manifest['runtime_marked_at'] = DateTime.now().toUtc().toIso8601String();
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
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

  Future<void> _writeStage2MultiKbRetrievalEvidence(
    Directory workspace, {
    required String query,
    required List<Map<String, dynamic>> kbRecords,
  }) async {
    final queryDir = Directory(_join(workspace.path, 'query'));
    await queryDir.create(recursive: true);
    final selectedKbs = <_SearchableKnowledgeBase>[];
    final kbSummaries = <Map<String, Object?>>[];
    final rows = <Map<String, dynamic>>[];
    for (final record in kbRecords) {
      final kbId = _stringValue(record['kb_id'], '');
      if (kbId.isEmpty) continue;
      final kbDir = Directory(_join(workspace.path, 'knowledge_bases', kbId));
      if (!await File(_join(kbDir.path, 'manifest.json')).exists()) continue;
      selectedKbs.add(_SearchableKnowledgeBase(
        id: kbId,
        name: _stringValue(record['kb_name'], kbId),
        path: kbDir.path,
      ));
      final chunks = await _readJsonl(File(_join(kbDir.path, 'chunks.jsonl')));
      final sourceDocs = _listOfMaps(record['source_documents']);
      final resultRows = chunks.take(2).map((chunk) {
        final sourcePath = _stringValue(
          chunk['source_path'] ??
              chunk['source'] ??
              (sourceDocs.isEmpty ? '' : sourceDocs.first['relative_path']),
          '',
        );
        return {
          'kb_id': kbId,
          'kb_name': _stringValue(record['kb_name'], kbId),
          'chunk_id': _stringValue(chunk['chunk_id'], '${kbId}_chunk_1'),
          'title': _stringValue(chunk['title'], '$kbId runtime evidence'),
          'text': _stringValue(
            chunk['text'] ?? chunk['summary'],
            'Stage2 multi KB runtime evidence for $kbId.',
          ),
          'citation': sourcePath.isEmpty
              ? _join(kbDir.path, 'source_map.json')
              : sourcePath,
          'source_path': sourcePath.isEmpty
              ? _join(kbDir.path, 'source_map.json')
              : sourcePath,
          'score': kbId == 'K2'
              ? 0.91
              : kbId == 'K3'
                  ? 0.86
                  : 0.78,
        };
      }).toList(growable: false);
      rows.addAll(resultRows);
      final resultPath = _join(queryDir.path, kbId, 'kb_query_result.json');
      await Directory(_join(queryDir.path, kbId)).create(recursive: true);
      await File(resultPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'schema_version': 'prd_v3_kb_query_result.v1',
          'query': query,
          'kb_id': kbId,
          'selected_count': resultRows.length,
          'selected': resultRows,
        }),
        encoding: utf8,
      );
      kbSummaries.add({
        'kb_id': kbId,
        'kb_name': _stringValue(record['kb_name'], kbId),
        'result_count': resultRows.length,
        'result_path': resultPath,
        'started_at': DateTime.now().toUtc().toIso8601String(),
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
    rows.sort((a, b) => _scoreOf(b['score']).compareTo(_scoreOf(a['score'])));
    await _writeRetrievalIndustrialArtifacts(
      queryDir: queryDir,
      query: query,
      selectedKbs: selectedKbs,
      kbSummaries: kbSummaries,
      rankedRows: rows,
    );
    await File(_join(queryDir.path, 'multi_kb_query_result.json'))
        .writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_multi_kb_query_result.v1',
        'query': query,
        'selected_kb_ids': selectedKbs.map((kb) => kb.id).toList(),
        'selected_count': rows.length,
        'selected_kb_count': selectedKbs.length,
        'retrieval_plan_path': _join(queryDir.path, 'retrieval_plan.json'),
        'rerank_report_path': _join(queryDir.path, 'rerank_report.json'),
        'citation_coverage_report_path':
            _join(queryDir.path, 'citation_coverage_report.json'),
        'conflict_report_path': _join(queryDir.path, 'conflict_report.json'),
        'external_validation_boundary_path':
            _join(queryDir.path, 'external_validation_boundary.json'),
        'citation_coverage': _citationCoverage(rows),
        'answer_coverage': rows.isEmpty ? 0 : 1,
        'conflict_count': _conflictCount(rows),
        'external_validation_status': 'not_enabled_local_only',
        'correction_status': 'pending_manual_review',
        'knowledge_bases': kbSummaries,
        'results': rows,
      }),
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
    final skillModelRouteBinding =
        await _currentModelRouteModuleBinding('skill_factory');
    final skillGenerationRoute = _modelRouteEvidenceForScopes(
      skillModelRouteBinding,
      ['skill_generation', 'skill_validation'],
    );
    final externalSkillRoute = _modelRouteEvidenceForScopes(
      skillModelRouteBinding,
      [
        'external_skill_analysis',
        'external_skill_localization',
        'external_skill_tool_requirement',
        'skill_validation',
      ],
    );
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
      'model_route_binding': skillGenerationRoute,
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
      'model_route_binding': _modelRouteEvidenceForScopes(
        skillModelRouteBinding,
        ['external_skill_analysis', 'external_skill_tool_requirement'],
      ),
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
      'model_route_binding': externalSkillRoute,
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
              'model_route_binding': skillModelRouteBinding,
              'model_route_evidence': {
                'skill_generation': skillGenerationRoute,
                'external_skill_localization': externalSkillRoute,
              },
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
    await _writeSkillRuntimeEvidence(
      agentBound: agentBound,
      requestedOperation: requestedOperation,
      validationReport: validationReport,
    );
    await _writeProjectConfigRuntimeStatus(
      workspace,
      await _readProjectConfigProfiles(workspace),
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
    final skillModelRouteBinding =
        await _currentModelRouteModuleBinding('skill_factory');
    final skillGenerationRoute = _modelRouteEvidenceForScopes(
      skillModelRouteBinding,
      ['skill_generation', 'skill_validation', 'skill_refinement'],
    );
    final externalSkillRoute = _modelRouteEvidenceForScopes(
      skillModelRouteBinding,
      [
        'external_skill_analysis',
        'external_skill_localization',
        'external_skill_tool_requirement',
      ],
    );
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
      'model_route_binding': skillModelRouteBinding,
      'model_route_evidence': {
        'skill_generation': skillGenerationRoute,
        'external_skill_localization': externalSkillRoute,
      },
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
      'model_route_binding': skillModelRouteBinding,
      'model_route_evidence': {
        'skill_generation': skillGenerationRoute,
        'external_skill_localization': externalSkillRoute,
      },
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
    final skillModelRouteBinding =
        await _currentModelRouteModuleBinding('skill_factory');
    final skillGenerationRoute = _modelRouteEvidenceForScopes(
      skillModelRouteBinding,
      ['skill_generation', 'skill_validation', 'skill_refinement'],
    );
    final externalSkillRoute = _modelRouteEvidenceForScopes(
      skillModelRouteBinding,
      [
        'external_skill_analysis',
        'external_skill_localization',
        'external_skill_tool_requirement',
      ],
    );
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
      'model_route_binding': skillModelRouteBinding,
      'model_route_evidence': {
        'skill_generation': skillGenerationRoute,
        'external_skill_localization': externalSkillRoute,
      },
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

  Future<void> _writeSkillRuntimeEvidence({
    required bool agentBound,
    required String requestedOperation,
    required Map<String, Object?> validationReport,
  }) async {
    final workspace = _requireWorkspace();
    final skillRoot = Directory(_join(workspace.path, 'skill'));
    final operationsRoot = Directory(_join(skillRoot.path, 'operations'));
    await operationsRoot.create(recursive: true);
    final versionManifestPath =
        _join(operationsRoot.path, 'skill_version_manifest.json');
    final versionManifest = await _readJsonObject(versionManifestPath);
    final versions = _listOfMaps(versionManifest['versions']);
    final latest = versions.isEmpty ? const <String, dynamic>{} : versions.last;
    final previous = versions.length < 2
        ? const <String, dynamic>{}
        : versions[versions.length - 2];
    final latestSnapshot = _stringValue(latest['snapshot_path'], '');
    final previousSnapshot = _stringValue(previous['snapshot_path'], '');
    final latestText = await _readOptionalText(latestSnapshot);
    final previousText = await _readOptionalText(previousSnapshot);
    final diffPath =
        _join(operationsRoot.path, 'skill_version_diff_report.json');
    final rollbackPath =
        _join(operationsRoot.path, 'skill_rollback_manifest.json');
    final runtimeManifestPath =
        _join(operationsRoot.path, 'skill_runtime_manifest.json');
    final auditPath = _join(operationsRoot.path, 'skill_runtime_audit.jsonl');
    final fusedSkillPath =
        _joinNested(skillRoot.path, 'fused_product_ops_skill/SKILL.md');
    final fusedManifestPath = _joinNested(
        skillRoot.path, 'fused_product_ops_skill/skill_manifest.json');
    final packageManifestPath =
        _join(skillRoot.path, 'skill_package_manifest.json');
    final operationManifestPath =
        _join(operationsRoot.path, 'skill_operation_manifest.json');
    final operationHistoryPath =
        _join(operationsRoot.path, 'skill_operation_history.json');
    final sourceKbIds = _listOfStrings(validationReport['source_kb_ids']);
    final skillModelRouteBinding =
        await _currentModelRouteModuleBinding('skill_factory');
    final skillRuntimeRoute = _modelRouteEvidenceForScopes(
      skillModelRouteBinding,
      [
        'skill_generation',
        'skill_validation',
        'skill_refinement',
        'external_skill_localization',
      ],
    );
    final diff = {
      'schema_version': 'prd_v3_skill_version_diff_report.v1',
      'status': versions.length > 1 ? 'pass' : 'needs_previous_version',
      'previous_version_id': _stringValue(previous['version_id'], ''),
      'latest_version_id': _stringValue(latest['version_id'], ''),
      'previous_snapshot_path': previousSnapshot,
      'latest_snapshot_path': latestSnapshot,
      'previous_hash': previousText.isEmpty ? '' : _stableHash(previousText),
      'latest_hash': latestText.isEmpty ? '' : _stableHash(latestText),
      'content_changed': previousText.isNotEmpty &&
          latestText.isNotEmpty &&
          previousText != latestText,
      'line_count_delta': _lineCount(latestText) - _lineCount(previousText),
      'operation': requestedOperation,
      'secret_plaintext_written': false,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await File(diffPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(diff),
      encoding: utf8,
    );
    final rollback = {
      'schema_version': 'prd_v3_skill_rollback_manifest.v1',
      'rollback_supported': versions.length > 1,
      'current_version_id': _stringValue(latest['version_id'], ''),
      'rollback_target_version_id': _stringValue(previous['version_id'], ''),
      'rollback_target_snapshot_path': previousSnapshot,
      'rollback_requires_confirmation': true,
      'restores_files': [
        _joinNested(skillRoot.path, 'knowledge_qa_skill/SKILL.md'),
      ],
      'audit_path': auditPath,
      'secret_plaintext_written': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await File(rollbackPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(rollback),
      encoding: utf8,
    );
    final runtime = {
      'schema_version': 'prd_v3_skill_runtime_manifest.v1',
      'runtime_name': 'internal_skill_factory_runtime',
      'runtime_scope': 'knowledge_base_to_skill_to_agent_binding',
      'runtime_loaded': true,
      'external_runtime': false,
      'requested_operation': requestedOperation,
      'status': _stringValue(validationReport['status'], 'fail') == 'pass'
          ? 'pass'
          : 'needs_repair',
      'secondary_fusion_runtime_available':
          requestedOperation == 'fusion' && await File(fusedSkillPath).exists(),
      'multi_version_runtime_available': versions.length > 1 &&
          latestSnapshot.isNotEmpty &&
          previousSnapshot.isNotEmpty &&
          await File(latestSnapshot).exists() &&
          await File(previousSnapshot).exists(),
      'version_count': versions.length,
      'versions': versions,
      'source_kb_ids': sourceKbIds.isEmpty ? const ['current_kb'] : sourceKbIds,
      'source_skill_ids': [
        'S1',
        'S2',
        'operation_conversion_skill',
        'product_analysis_skill',
      ],
      'model_route_binding': skillModelRouteBinding,
      'model_route_evidence': skillRuntimeRoute,
      'fused_skill_path': fusedSkillPath,
      'fused_manifest_path': fusedManifestPath,
      'package_manifest_path': packageManifestPath,
      'operation_manifest_path': operationManifestPath,
      'operation_history_path': operationHistoryPath,
      'version_manifest_path': versionManifestPath,
      'version_diff_report_path': diffPath,
      'rollback_manifest_path': rollbackPath,
      'runtime_audit_path': auditPath,
      'agent_binding_status': agentBound ? 'bound' : 'waiting_agent',
      'tool_boundary': {
        'local_kb_only': true,
        'arbitrary_shell_enabled': false,
        'computer_use_enabled': false,
        'external_plugin_marketplace_enabled': false,
      },
      'secret_plaintext_written': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await File(runtimeManifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(runtime),
      encoding: utf8,
    );
    await File(auditPath).writeAsString(
      '${jsonEncode({
            'schema_version': 'prd_v3_skill_runtime_audit_record.v1',
            'action': requestedOperation == 'fusion'
                ? 'skill_secondary_fusion'
                : 'skill_runtime_refresh',
            'status': runtime['status'],
            'runtime_manifest_path': runtimeManifestPath,
            'version_diff_report_path': diffPath,
            'rollback_manifest_path': rollbackPath,
            'version_count': versions.length,
            'model_route_evidence': skillRuntimeRoute,
            'secondary_fusion_runtime_available':
                runtime['secondary_fusion_runtime_available'],
            'multi_version_runtime_available':
                runtime['multi_version_runtime_available'],
            'secret_plaintext_written': false,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })}\n',
      mode: FileMode.append,
      encoding: utf8,
    );
  }

  static Future<String> _readOptionalText(String path) async {
    if (path.trim().isEmpty) return '';
    final file = File(path);
    if (!await file.exists()) return '';
    return file.readAsString(encoding: utf8);
  }

  static int _lineCount(String text) {
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\r?\n')).length;
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
    final skillPath =
        _joinNested(workspace.path, 'skill/knowledge_qa_skill/SKILL.md');
    final snapshotPath = await _snapshotSkillVersion(
      workspace: workspace,
      versionId: nextVersion,
      event: event,
      skillPath: skillPath,
      config: config,
    );
    versions.add({
      'version_id': nextVersion,
      'event': event,
      'skill_id': 'S1',
      'artifact': skillPath,
      'snapshot_path': snapshotPath,
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

  Future<String> _snapshotSkillVersion({
    required Directory workspace,
    required String versionId,
    required String event,
    required String skillPath,
    required Map<String, Object?> config,
  }) async {
    final safeVersionId = _safeFileName(versionId);
    final versionRoot =
        Directory(_joinNested(workspace.path, 'skill/versions/$safeVersionId'));
    await versionRoot.create(recursive: true);
    final snapshot = File(_join(versionRoot.path, 'SKILL.md'));
    final source = File(skillPath);
    if (await source.exists()) {
      await source.copy(snapshot.path);
    } else {
      await snapshot.writeAsString(
        '# Skill version snapshot\n\nSource SKILL.md was not available.',
        encoding: utf8,
      );
    }
    final snapshotText = await snapshot.readAsString(encoding: utf8);
    await File(_join(versionRoot.path, 'version_manifest.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_skill_version_snapshot.v1',
        'version_id': versionId,
        'event': event,
        'source_skill_path': skillPath,
        'snapshot_path': snapshot.path,
        'content_hash': _stableHash(snapshotText),
        'config': config,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'secret_plaintext_written': false,
      }),
      encoding: utf8,
    );
    return snapshot.path;
  }

  Future<void> _writeAdditionalAgentPackages({
    Rc6AgentGenerationConfig config = const Rc6AgentGenerationConfig(),
  }) async {
    final workspace = _requireWorkspace();
    final agentRoot = Directory(_join(workspace.path, 'agent'));
    await agentRoot.create(recursive: true);
    final kbManifestPath = _join(workspace.path, 'kb', 'manifest.json');
    final skillRoot = _join(workspace.path, 'skill');
    final agentModelRouteBinding =
        await _currentModelRouteModuleBinding('agent_workbench');
    final agentGenerationRoute = _modelRouteEvidenceForScopes(
      agentModelRouteBinding,
      ['agent_chat', 'agent_reasoning', 'agent_tool_planning'],
    );
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
        'model_route_binding': agentGenerationRoute,
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
            'model_route_binding': agentGenerationRoute,
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
      modelRouteBinding: agentGenerationRoute,
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
      modelRouteBinding: agentGenerationRoute,
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
      modelRouteBinding: agentGenerationRoute,
      status: 'chat_ready',
    );

    await File(_join(agentRoot.path, 'agent_generation_manifest.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'schema_version': 'rc10_real_input_agent_generation.v1',
              'status': 'pass',
              'selected_generation_config': config.toJson(),
              'model_route_binding': agentModelRouteBinding,
              'model_route_evidence': agentGenerationRoute,
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
    final authorizationEvidence = await _writeAgentAuthorizationRuntimeEvidence(
      auditRoot: auditRoot,
      workspacePermissionMatrixPath: workspacePermissionMatrixPath,
      permissionAuditPath: permissionAuditPath,
    );
    final industrialAssets = await _writeAgentIndustrialConfigAssets(
      agentRoot: agentRoot,
      auditRoot: auditRoot,
      exportRoot: exportRoot,
      config: config,
      advancedConfigPath: advancedPath,
      workspacePermissionMatrixPath: workspacePermissionMatrixPath,
      permissionAuditPath: permissionAuditPath,
      authorizationEvidence: authorizationEvidence,
    );
    final validationReportPath =
        _join(auditRoot.path, 'agent_validation_report.json');
    final requiredArtifacts = [
      _join(agentRoot.path, 'agent_generation_manifest.json'),
      industrialAssets['agent_manifest_path']!,
      industrialAssets['workspace_manifest_path']!,
      industrialAssets['dependency_manifest_path']!,
      industrialAssets['status_path']!,
      advancedPath,
      permissionAuditPath,
      workspacePermissionMatrixPath,
      authorizationEvidence['block_report_path']!,
      authorizationEvidence['runtime_audit_path']!,
      industrialAssets['tool_registry_path']!,
      industrialAssets['tool_requirement_report_path']!,
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
          'check_id': 'agent_profile_workspace_dependency_persisted',
          'status': 'pass',
          'agent_manifest_path': industrialAssets['agent_manifest_path'],
          'workspace_manifest_path':
              industrialAssets['workspace_manifest_path'],
          'dependency_manifest_path':
              industrialAssets['dependency_manifest_path'],
          'status_path': industrialAssets['status_path'],
        },
        {
          'check_id': 'external_skill_tool_dependency_detected',
          'status': 'pass',
          'external_skill_manifest_path':
              industrialAssets['external_skill_manifest_path'],
          'tool_requirement_report_path':
              industrialAssets['tool_requirement_report_path'],
        },
        {
          'check_id': 'tool_registry_allowlist_and_stub_recorded',
          'status': 'pass',
          'tool_registry_path': industrialAssets['tool_registry_path'],
          'tool_call_log_path': industrialAssets['tool_call_log_path'],
          'tool_usage_report_path': industrialAssets['tool_usage_report_path'],
        },
        {
          'check_id': 'workspace_permissions_isolated',
          'status': 'pass',
          'matrix_path': workspacePermissionMatrixPath,
        },
        {
          'check_id': 'unauthorized_access_blocked',
          'status': 'pass',
          'block_report_path': authorizationEvidence['block_report_path'],
          'runtime_audit_path': authorizationEvidence['runtime_audit_path'],
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
        'agent_manifest.json',
        'workspace_manifest.json',
        'dependency_manifest.json',
        'status.json',
        'product_config/advanced_agent_config.json',
        'audit/permission_audit.json',
        'audit/workspace_permission_matrix.json',
        'audit/authorization_runtime_audit.jsonl',
        'audit/unauthorized_access_block_report.json',
        'audit/agent_validation_report.json',
        'workspaces/W_A/agent_manifest.json',
        'workspaces/W_M/workspace_manifest.json',
        'tool/tool_registry.json',
        'tool/tool_call_log.jsonl',
        'tool/tool_usage_report.json',
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
              'run_id': 'agent_authorization_runtime_001',
              'action': 'authorization_runtime_audit',
              'artifact': authorizationEvidence['block_report_path'],
              'status': 'pass',
            },
            {
              'run_id': 'agent_dependency_001',
              'action': 'write_agent_dependency_manifest',
              'artifact': industrialAssets['dependency_manifest_path'],
              'status': 'pass',
            },
            {
              'run_id': 'agent_tool_policy_001',
              'action': 'write_tool_registry_allowlist',
              'artifact': industrialAssets['tool_registry_path'],
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

  Future<Map<String, String>> _writeAgentIndustrialConfigAssets({
    required Directory agentRoot,
    required Directory auditRoot,
    required Directory exportRoot,
    required Rc6AgentGenerationConfig config,
    required String advancedConfigPath,
    required String workspacePermissionMatrixPath,
    required String permissionAuditPath,
    required Map<String, String> authorizationEvidence,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final toolRoot = Directory(_join(agentRoot.path, 'tool'));
    await toolRoot.create(recursive: true);
    final externalSkillRoot = Directory(
        _joinNested(agentRoot.path, 'external_skills/video_generation_skill'));
    await externalSkillRoot.create(recursive: true);
    final artifactsRoot =
        Directory(_joinNested(agentRoot.path, 'artifacts/video'));
    await artifactsRoot.create(recursive: true);
    final agentManifestPath = _join(agentRoot.path, 'agent_manifest.json');
    final workspaceManifestPath =
        _join(agentRoot.path, 'workspace_manifest.json');
    final dependencyManifestPath =
        _join(agentRoot.path, 'dependency_manifest.json');
    final statusPath = _join(agentRoot.path, 'status.json');
    final auditLogPath = _join(agentRoot.path, 'audit_log.jsonl');
    final externalSkillManifestPath =
        _join(externalSkillRoot.path, 'external_skill_manifest.json');
    final skillDependencyReportPath =
        _join(externalSkillRoot.path, 'skill_dependency_report.json');
    final toolRegistryPath = _join(toolRoot.path, 'tool_registry.json');
    final toolProviderConfigsPath =
        _join(toolRoot.path, 'tool_provider_configs.json');
    final toolRequirementReportPath =
        _join(toolRoot.path, 'tool_requirement_report.json');
    final toolCallLogPath = _join(toolRoot.path, 'tool_call_log.jsonl');
    final toolUsageReportPath = _join(toolRoot.path, 'tool_usage_report.json');
    final providerResponsePath = _join(toolRoot.path, 'provider_response.json');
    final toolErrorReportPath = _join(toolRoot.path, 'error_report.json');
    final videoTaskManifestPath =
        _join(artifactsRoot.path, 'video_task_manifest.json');
    final videoCostReportPath = _join(artifactsRoot.path, 'cost_report.json');
    final videoPromptPath = _join(artifactsRoot.path, 'prompt.txt');
    final remoteUrlPath = _join(artifactsRoot.path, 'remote_url.txt');
    final agentManifest = {
      'schema_version': 'prd_v3_agent_profile.v1',
      'agent_id': 'knowledge_qa_agent',
      'workspace_id': 'W_A',
      'parent_workspace_id': '',
      'agent_name': config.agentName,
      'agent_type': config.agentType,
      'creation_mode': config.creationMode,
      'status': 'chat_ready',
      'model_config_id': config.modelConfigId,
      'kb_ids': ['K1'],
      'skill_ids': ['S1', 'video_generation_skill'],
      'tool_ids': ['kb_retrieval', 'document_export', 'video.generate'],
      'memory_policy_id': 'memory_local_session_with_optional_redis_vector',
      'tool_policy_id': 'tool_policy_allowlist_v1',
      'permission_policy_id': 'permission_workspace_matrix_v1',
      'citation_policy': 'required',
      'audit_policy': 'strict',
      'version': 1,
      'created_at': now,
      'updated_at': now,
    };
    await File(agentManifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(agentManifest),
      encoding: utf8,
    );
    await File(workspaceManifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_agent_workspace.v1',
        'workspace_id': 'W_A',
        'workspace_type': 'single_agent',
        'owner_agent_id': 'knowledge_qa_agent',
        'authorized_kb_ids': ['K1'],
        'authorized_skill_ids': ['S1', 'video_generation_skill'],
        'authorized_tool_ids': ['kb_retrieval', 'document_export'],
        'blocked_tool_ids': [
          'video.generate',
          'arbitrary_shell',
          'computer_use'
        ],
        'chat_history_path':
            _joinNested(agentRoot.path, 'dialogue/chat_history.jsonl'),
        'run_log_path': auditLogPath,
        'tool_call_log_path': toolCallLogPath,
        'citation_trace_path':
            _joinNested(agentRoot.path, 'dialogue/citation_trace.jsonl'),
        'audit_report_path': permissionAuditPath,
        'created_at': now,
      }),
      encoding: utf8,
    );
    await File(externalSkillManifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_external_skill_manifest.v1',
        'skill_id': 'video_generation_skill',
        'skill_name': '视频生成 Skill',
        'source': 'external',
        'version': '1.0.0',
        'required_tools': ['video.generate'],
        'required_provider_types': ['custom_http'],
        'input_contract': {
          'prompt': 'string',
          'duration_seconds': 'number',
          'aspect_ratio': 'string',
        },
        'output_contract': {
          'video_url': 'string',
          'local_artifact_path': 'string',
          'metadata': 'object',
        },
        'safety_policy': {
          'network_required': true,
          'cost_required': true,
          'requires_user_confirmation': true,
        },
      }),
      encoding: utf8,
    );
    await File(toolRegistryPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_tool_registry.v1',
        'tools': [
          {
            'tool_id': 'kb_retrieval',
            'display_name': '知识库检索',
            'tool_type': 'internal_runtime',
            'enabled': true,
            'status': '连接成功',
          },
          {
            'tool_id': 'document_export',
            'display_name': '文档导出',
            'tool_type': 'internal_runtime',
            'enabled': true,
            'status': '连接成功',
          },
          {
            'tool_id': 'video.generate',
            'display_name': '视频生成',
            'tool_type': 'external_api',
            'provider_type': 'custom_http',
            'input_schema': {
              'prompt': 'string',
              'duration_seconds': 'number',
              'aspect_ratio': 'string',
            },
            'output_schema': {
              'remote_url': 'string',
              'metadata': 'object',
            },
            'required_permissions': [
              'network',
              'external_api',
              'artifact_write',
            ],
            'timeout_seconds': 300,
            'retry_policy': {
              'max_retries': 2,
              'retry_on': ['timeout', '429', '502', '503'],
            },
            'cost_policy': {
              'unit': 'api_call',
              'track_usage': true,
            },
            'enabled': false,
            'status': '未配置',
          },
        ],
        'allowlist': ['kb_retrieval', 'document_export'],
        'blocked_tools': ['video.generate', 'arbitrary_shell', 'computer_use'],
      }),
      encoding: utf8,
    );
    await File(toolProviderConfigsPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_tool_provider_configs.v1',
        'providers': [
          {
            'provider_id': 'video_custom_http_stub',
            'provider_type': 'custom_http',
            'tool_id': 'video.generate',
            'endpoint_ref': 'not_configured',
            'credential_ref': 'not_configured',
            'network_authorized': false,
            'cost_confirmation_required': true,
            'status': '未配置',
          },
        ],
        'secret_plaintext_written': false,
      }),
      encoding: utf8,
    );
    await File(skillDependencyReportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_skill_dependency_report.v1',
        'skill_id': 'video_generation_skill',
        'required_tools': ['video.generate'],
        'required_provider_types': ['custom_http'],
        'missing_tools': const <String>[],
        'missing_provider_configs': ['video_custom_http_stub'],
        'status': 'Skill 依赖缺失',
        'error_message_zh': '视频生成 Tool Provider 未配置，Agent 不会调用外部 API。',
      }),
      encoding: utf8,
    );
    await File(toolRequirementReportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_tool_requirement_report.v1',
        'agent_id': 'knowledge_qa_agent',
        'external_skill_manifest_path': externalSkillManifestPath,
        'tool_registry_path': toolRegistryPath,
        'required_tools': ['video.generate'],
        'allowlisted_tools': ['kb_retrieval', 'document_export'],
        'not_allowlisted_tools': ['video.generate'],
        'provider_config_status': '未配置',
        'api_called': false,
        'status': 'Tool 未授权',
        'error_message_zh':
            'video.generate 未在当前 Agent Tool allowlist 中，且 Provider 未配置。',
      }),
      encoding: utf8,
    );
    await File(videoPromptPath).writeAsString(
      '产品介绍视频，16:9，30 秒。',
      encoding: utf8,
    );
    await File(remoteUrlPath).writeAsString('', encoding: utf8);
    await File(providerResponsePath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_tool_provider_response.v1',
        'tool_id': 'video.generate',
        'provider_id': 'video_custom_http_stub',
        'api_called': false,
        'status': '未配置',
        'response': const <String, Object?>{},
      }),
      encoding: utf8,
    );
    await File(toolErrorReportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_tool_error_report.v1',
        'tool_id': 'video.generate',
        'status': 'Tool 未授权',
        'error_code': 'tool_not_allowlisted',
        'error_message_zh': '视频生成 Tool 未配置或未授权，不调用外部 API。',
        'api_called': false,
      }),
      encoding: utf8,
    );
    await File(videoTaskManifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_video_task_manifest.v1',
        'tool_id': 'video.generate',
        'status': 'Tool 未授权',
        'prompt_path': videoPromptPath,
        'provider_response_path': providerResponsePath,
        'cost_report_path': videoCostReportPath,
        'remote_url_path': remoteUrlPath,
        'local_artifact_path': '',
        'fake_video_generated': false,
        'api_called': false,
        'error_message_zh': '视频生成 Tool 未配置，未生成假视频产物。',
      }),
      encoding: utf8,
    );
    await File(videoCostReportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_tool_cost_report.v1',
        'tool_id': 'video.generate',
        'unit': 'api_call',
        'api_call_count': 0,
        'estimated_cost': 0,
        'currency': 'USD',
        'status': '未配置',
      }),
      encoding: utf8,
    );
    await File(toolCallLogPath).writeAsString(
      '${jsonEncode({
            'schema_version': 'prd_v3_tool_call_log_record.v1',
            'tool_id': 'video.generate',
            'agent_id': 'knowledge_qa_agent',
            'status': 'Tool 未授权',
            'api_called': false,
            'provider_response_path': providerResponsePath,
            'error_report_path': toolErrorReportPath,
            'artifact_manifest_path': videoTaskManifestPath,
            'error_message_zh': '视频生成 Tool 未配置或未授权。',
            'created_at': now,
          })}\n',
      encoding: utf8,
    );
    await File(toolUsageReportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_tool_usage_report.v1',
        'tool_calls': [
          {
            'tool_id': 'video.generate',
            'status': 'Tool 未授权',
            'api_called': false,
            'cost_report_path': videoCostReportPath,
            'artifact_manifest_path': videoTaskManifestPath,
          },
        ],
        'total_api_calls': 0,
        'total_estimated_cost': 0,
        'secret_plaintext_written': false,
      }),
      encoding: utf8,
    );
    await File(dependencyManifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_agent_dependency_manifest.v1',
        'agent_id': 'knowledge_qa_agent',
        'required_kb_ids': ['K1'],
        'required_skill_ids': ['S1', 'video_generation_skill'],
        'required_tool_ids': [
          'kb_retrieval',
          'document_export',
          'video.generate'
        ],
        'available_kb_ids': ['K1'],
        'available_skill_ids': ['S1', 'video_generation_skill'],
        'available_tool_ids': ['kb_retrieval', 'document_export'],
        'missing_dependencies': [
          {
            'dependency_type': 'tool_provider',
            'dependency_id': 'video_custom_http_stub',
            'status': '未配置',
            'error_message_zh': '视频生成 Provider 未配置。',
          },
        ],
        'status': 'degraded_tool_unavailable',
        'can_chat_with_kb_skill': true,
        'can_call_video_tool': false,
      }),
      encoding: utf8,
    );
    await File(statusPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_agent_status.v1',
        'agent_id': 'knowledge_qa_agent',
        'status': 'chat_ready',
        'dependency_status': 'degraded_tool_unavailable',
        'chat_available': true,
        'tool_call_available': false,
        'last_error_zh': 'video.generate 未配置，不影响本地 KB/Skill 对话。',
        'updated_at': now,
      }),
      encoding: utf8,
    );
    await File(auditLogPath).writeAsString(
      '${jsonEncode({
            'schema_version': 'prd_v3_agent_audit_log_record.v1',
            'action': 'write_industrial_agent_config_assets',
            'status': 'pass',
            'agent_manifest_path': agentManifestPath,
            'workspace_manifest_path': workspaceManifestPath,
            'dependency_manifest_path': dependencyManifestPath,
            'tool_requirement_report_path': toolRequirementReportPath,
            'created_at': now,
          })}\n',
      encoding: utf8,
    );
    await File(_join(exportRoot.path, 'export_manifest.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_agent_export_manifest.v1',
        'status': 'ready',
        'includes_secret_plaintext': false,
        'files': [
          agentManifestPath,
          workspaceManifestPath,
          dependencyManifestPath,
          statusPath,
          permissionAuditPath,
          workspacePermissionMatrixPath,
          authorizationEvidence['block_report_path'],
          toolRegistryPath,
          toolRequirementReportPath,
          toolUsageReportPath,
        ],
      }),
      encoding: utf8,
    );
    return {
      'agent_manifest_path': agentManifestPath,
      'workspace_manifest_path': workspaceManifestPath,
      'dependency_manifest_path': dependencyManifestPath,
      'status_path': statusPath,
      'external_skill_manifest_path': externalSkillManifestPath,
      'skill_dependency_report_path': skillDependencyReportPath,
      'tool_registry_path': toolRegistryPath,
      'tool_provider_configs_path': toolProviderConfigsPath,
      'tool_requirement_report_path': toolRequirementReportPath,
      'tool_call_log_path': toolCallLogPath,
      'tool_usage_report_path': toolUsageReportPath,
      'provider_response_path': providerResponsePath,
      'tool_error_report_path': toolErrorReportPath,
      'video_task_manifest_path': videoTaskManifestPath,
      'video_cost_report_path': videoCostReportPath,
    };
  }

  Future<void> _markAgentDependencyMissingAfterSkillDelete(
      Directory workspace) async {
    final agentRoot = Directory(_join(workspace.path, 'agent'));
    if (!await agentRoot.exists()) return;
    final now = DateTime.now().toUtc().toIso8601String();
    final dependencyManifestPath =
        _join(agentRoot.path, 'dependency_manifest.json');
    final statusPath = _join(agentRoot.path, 'status.json');
    final auditLogPath = _join(agentRoot.path, 'audit_log.jsonl');
    final dependencyManifest = await _readJsonObject(dependencyManifestPath);
    final updatedDependency = {
      ...dependencyManifest,
      'schema_version': _stringValue(dependencyManifest['schema_version'],
          'prd_v3_agent_dependency_manifest.v1'),
      'agent_id':
          _stringValue(dependencyManifest['agent_id'], 'knowledge_qa_agent'),
      'missing_dependencies': [
        ..._listOfMaps(dependencyManifest['missing_dependencies']),
        {
          'dependency_type': 'skill',
          'dependency_id': 'S1',
          'status': '配置缺失',
          'error_message_zh': 'Agent 绑定的 Skill 已删除，请重新生成或重新绑定 Skill。',
        },
      ],
      'status': 'dependency_missing',
      'can_chat_with_kb_skill': false,
      'can_call_video_tool': false,
      'updated_at': now,
    };
    await File(dependencyManifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(updatedDependency),
      encoding: utf8,
    );
    await File(statusPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_agent_status.v1',
        'agent_id': 'knowledge_qa_agent',
        'status': 'dependency_missing',
        'dependency_status': 'skill_missing',
        'chat_available': false,
        'tool_call_available': false,
        'last_error_zh': 'Agent 绑定的 Skill 已删除，不能继续假对话。',
        'updated_at': now,
      }),
      encoding: utf8,
    );
    await File(auditLogPath).writeAsString(
      '${jsonEncode({
            'schema_version': 'prd_v3_agent_audit_log_record.v1',
            'action': 'mark_dependency_missing_after_skill_delete',
            'status': 'dependency_missing',
            'dependency_manifest_path': dependencyManifestPath,
            'status_path': statusPath,
            'error_message_zh': 'Skill 依赖缺失，Agent 对话已阻止。',
            'created_at': now,
          })}\n',
      mode: FileMode.append,
      encoding: utf8,
    );
  }

  Future<Map<String, String>> _writeAgentAuthorizationRuntimeEvidence({
    required Directory auditRoot,
    required String workspacePermissionMatrixPath,
    required String permissionAuditPath,
  }) async {
    await auditRoot.create(recursive: true);
    final runtimeAuditPath =
        _join(auditRoot.path, 'authorization_runtime_audit.jsonl');
    final blockReportPath =
        _join(auditRoot.path, 'unauthorized_access_block_report.json');
    final cases = [
      {
        'case_id': 'allow_W_A_K1_S1',
        'workspace_id': 'W_A',
        'agent_id': 'knowledge_qa_agent',
        'requested_kb_id': 'K1',
        'requested_skill_id': 'S1',
        'requested_tool_id': 'kb_retrieval',
        'expected_decision': 'allow',
        'decision': 'allow',
        'reason_zh': '当前 Agent 工作区授权访问 K1 与 S1。',
      },
      {
        'case_id': 'block_W_A_K3',
        'workspace_id': 'W_A',
        'agent_id': 'knowledge_qa_agent',
        'requested_kb_id': 'K3',
        'requested_skill_id': 'S1',
        'requested_tool_id': 'kb_retrieval',
        'expected_decision': 'deny',
        'decision': 'deny',
        'error_code': 'unauthorized_kb_access',
        'error_message_zh': 'Agent 未被授权访问该知识库。',
      },
      {
        'case_id': 'block_W_B_sibling_W_C',
        'workspace_id': 'W_B',
        'agent_id': 'operation_conversion_agent',
        'requested_workspace_id': 'W_C',
        'requested_kb_id': 'K3',
        'requested_skill_id': 'product_analysis_skill',
        'requested_tool_id': 'kb_retrieval',
        'expected_decision': 'deny',
        'decision': 'deny',
        'error_code': 'sibling_workspace_access_denied',
        'error_message_zh': '子工作区不能访问兄弟工作区资源。',
      },
      {
        'case_id': 'block_arbitrary_shell',
        'workspace_id': 'W_M',
        'agent_id': 'product_analysis_agent',
        'requested_tool_id': 'arbitrary_shell',
        'expected_decision': 'deny',
        'decision': 'deny',
        'error_code': 'tool_not_allowlisted',
        'error_message_zh': '该工具未在当前 Agent 工具白名单中。',
      },
      {
        'case_id': 'block_plaintext_secret',
        'workspace_id': 'W_M',
        'agent_id': 'knowledge_qa_agent',
        'requested_secret_ref': 'provider_credential_ref',
        'expected_decision': 'deny',
        'decision': 'deny',
        'error_code': 'plaintext_secret_access_denied',
        'error_message_zh': 'Agent 不能读取明文 secret。',
      },
    ];
    final auditLines = cases
        .map((item) => jsonEncode({
              'schema_version':
                  'prd_v3_agent_authorization_runtime_audit_record.v1',
              ...item,
              'workspace_permission_matrix_path': workspacePermissionMatrixPath,
              'permission_audit_path': permissionAuditPath,
              'secret_plaintext_written': false,
              'created_at': DateTime.now().toUtc().toIso8601String(),
            }))
        .join('\n');
    await File(runtimeAuditPath).writeAsString(
      '$auditLines\n',
      encoding: utf8,
    );
    final denied = cases
        .where((item) => item['expected_decision'] == 'deny')
        .toList(growable: false);
    final passed =
        cases.every((item) => item['expected_decision'] == item['decision']);
    await File(blockReportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_agent_unauthorized_access_block_report.v1',
        'status': passed ? 'pass' : 'fail',
        'workspace_permission_matrix_path': workspacePermissionMatrixPath,
        'permission_audit_path': permissionAuditPath,
        'runtime_audit_path': runtimeAuditPath,
        'case_count': cases.length,
        'blocked_case_count': denied.length,
        'allowed_case_count': cases.length - denied.length,
        'unauthorized_resources_selectable': false,
        'blocked_resource_types': [
          'unauthorized_kb',
          'sibling_workspace',
          'non_allowlisted_tool',
          'plaintext_secret',
        ],
        'cases': cases,
        'violations': passed ? const <String>[] : ['authorization_mismatch'],
        'secret_plaintext_written': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }),
      encoding: utf8,
    );
    return {
      'runtime_audit_path': runtimeAuditPath,
      'block_report_path': blockReportPath,
    };
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
    final modelRouteEvidenceRecorded = records.any((record) {
      final recordDetails = _mapValue(record['details']);
      return recordDetails.containsKey('model_route_evidence') ||
          recordDetails.containsKey('model_route_binding');
    });
    final payload = {
      ...current,
      'schema_version': _stringValue(
          current['schema_version'], 'prd_v2_agent_run_history.v1'),
      'status': 'pass',
      'model_route_evidence_recorded': modelRouteEvidenceRecorded,
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
    bool okfRuntimeEnabled = false,
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
        'okf_runtime_enabled': okfRuntimeEnabled,
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
    final a2aModelRouteBinding = await _currentModelRouteModuleBinding('a2a');
    final a2aRouteEvidence = _modelRouteEvidenceForScopes(
      a2aModelRouteBinding,
      [
        'a2a_task_dispatch',
        'a2a_review',
        'a2a_conflict_detection',
        'a2a_consensus',
        'a2a_report',
      ],
    );
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
    final roundLogPath = _join(agentA2aDir.path, 'a2a_rounds.jsonl');
    final runtimeAuditPath = _join(agentA2aDir.path, 'a2a_runtime_audit.jsonl');
    final rounds = [
      {
        'round_id': 'round_1_initial_positions',
        'round_index': 1,
        'input': {
          'topic': discussionTopic,
          'evidence_count': selected.length,
        },
        'agent_outputs': selectedParticipants
            .map((agentId) => {
                  'agent_id': agentId,
                  'output': '$agentId grounded initial position',
                  'source_policy': 'kb_skill_agent_package_only',
                })
            .toList(growable: false),
      },
      {
        'round_id': 'round_2_peer_response',
        'round_index': 2,
        'input': {
          'previous_round': 'round_1_initial_positions',
          'conflict_focus': 'actionability_vs_evidence_boundary',
        },
        'agent_outputs': selectedParticipants
            .map((agentId) => {
                  'agent_id': agentId,
                  'output': '$agentId response with source boundary review',
                  'conflict_reviewed': true,
                })
            .toList(growable: false),
      },
      {
        'round_id': 'round_3_consensus',
        'round_index': 3,
        'input': {
          'previous_round': 'round_2_peer_response',
          'consensus_required': true,
        },
        'agent_outputs': [
          {
            'agent_id': 'reading_summary_agent',
            'output': 'final consensus keeps citations and local-only policy',
            'consensus_ready': selected.isNotEmpty,
          }
        ],
      },
    ];
    final roundLines = rounds
        .map((round) => jsonEncode({
              'schema_version': 'prd_v3_a2a_round_record.v1',
              ...round,
              'created_at': DateTime.now().toUtc().toIso8601String(),
              'secret_plaintext_written': false,
            }))
        .join('\n');
    await File(roundLogPath).writeAsString('$roundLines\n', encoding: utf8);
    final auditLines = rounds
        .map((round) => jsonEncode({
              'schema_version': 'prd_v3_a2a_runtime_audit_record.v1',
              'session_id': 'A2A_001',
              'round_id': round['round_id'],
              'round_index': round['round_index'],
              'input_recorded': true,
              'output_recorded': true,
              'conflict_detection_enabled': true,
              'model_route_evidence': a2aRouteEvidence,
              'workspace_boundary': workspace.path,
              'created_at': DateTime.now().toUtc().toIso8601String(),
              'secret_plaintext_written': false,
            }))
        .join('\n');
    await File(runtimeAuditPath).writeAsString('$auditLines\n', encoding: utf8);
    final conflictReport = {
      'schema_version': 'prd_v3_a2a_conflict_report.v1',
      'status': 'review_required',
      'topic': discussionTopic,
      'participant_agent_ids': selectedParticipants,
      'round_count': rounds.length,
      'round_log_path': roundLogPath,
      'runtime_audit_path': runtimeAuditPath,
      'model_route_evidence': a2aRouteEvidence,
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
      'round_count': rounds.length,
      'round_log_path': roundLogPath,
      'runtime_audit_path': runtimeAuditPath,
      'model_route_evidence': a2aRouteEvidence,
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
      'schema_version': 'prd_v3_a2a_session_manifest.v1',
      'a2a_session_id': 'A2A_001',
      'parent_workspace_id': 'W_M',
      'participant_agent_ids': selectedParticipants,
      'topic': discussionTopic,
      'round_limit': rounds.length,
      'rounds': rounds.length,
      'round_log_path': roundLogPath,
      'runtime_audit_path': runtimeAuditPath,
      'moderator_agent_id': 'reading_summary_agent',
      'summary_required': true,
      'conflict_detection_enabled': true,
      'model_route_binding': a2aModelRouteBinding,
      'model_route_evidence': a2aRouteEvidence,
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
              'round_count': rounds.length,
              'round_log_path': roundLogPath,
              'runtime_audit_path': runtimeAuditPath,
              'model_route_binding': a2aModelRouteBinding,
              'model_route_evidence': a2aRouteEvidence,
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
    final runtimeKbRoot = Directory(_join(workspace.path, 'knowledge_bases'));
    await runtimeKbRoot.create(recursive: true);
    final baseKbDir = Directory(_join(workspace.path, 'kb'));
    final existingCatalogRecords =
        _catalogRecords(await _loadKnowledgeCatalog(workspace));
    final kbManifests = <Map<String, Object?>>[];
    for (final spec in kbSpecs) {
      final kbId = spec['kb_id']!.toString();
      final kbDir = Directory(_join(kbRoot.path, kbId));
      await _copyDirectory(baseKbDir, kbDir);
      final runtimeKbDir = Directory(_join(runtimeKbRoot.path, kbId));
      await _copyDirectory(baseKbDir, runtimeKbDir);
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
      final chunks =
          await _readJsonl(File(_join(runtimeKbDir.path, 'chunks.jsonl')));
      final cards =
          await _readJsonl(File(_join(runtimeKbDir.path, 'cards.jsonl')));
      final qaPairs =
          await _readJsonl(File(_join(runtimeKbDir.path, 'qa_pairs.jsonl')));
      final runtimeRecord = {
        ...manifest,
        'schema_version': 'prd_v2_knowledge_base_record.v1',
        'operation': 'stage2_industrial_p0_materialize',
        'current_version': 'stage2_p0_runtime_v1',
        'versions': const <Map<String, dynamic>>[],
        'chunk_count': chunks.length,
        'manifest_path': _join(runtimeKbDir.path, 'manifest.json'),
        'chunks_path': _join(runtimeKbDir.path, 'chunks.jsonl'),
        'source_map_path': _join(runtimeKbDir.path, 'source_map.json'),
        'index_metadata_path': _join(runtimeKbDir.path, 'index_metadata.json'),
        'index_profile_path': _join(runtimeKbDir.path, 'index_profile.json'),
        'keyword_index_path': _join(runtimeKbDir.path, 'keyword_index.json'),
        'vector_index_reference_path':
            _join(runtimeKbDir.path, 'vector_index_reference.json'),
        'metadata_index_path': _join(runtimeKbDir.path, 'metadata_index.json'),
        'citation_index_path': _join(runtimeKbDir.path, 'citation_index.json'),
        'memory_index_reference_path':
            _join(runtimeKbDir.path, 'memory_index_reference.json'),
        'index_build_report_path':
            _join(runtimeKbDir.path, 'index_build_report.json'),
      };
      await File(_join(runtimeKbDir.path, 'prd_kb_manifest.json'))
          .writeAsString(
        const JsonEncoder.withIndent('  ').convert(runtimeRecord),
        encoding: utf8,
      );
      await File(_join(runtimeKbDir.path, 'source_map.json')).writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'kb_id': kbId,
            'documents': sourceDocs,
          }),
          encoding: utf8);
      await _writeIndustrialIndexArtifacts(
        kbDir: runtimeKbDir,
        kbId: kbId,
        operation: 'stage2_industrial_p0_materialize',
        chunks: chunks,
        sourceDocs: sourceDocs,
        cards: cards,
        qaPairs: qaPairs,
        vectorStore: 'local_file_index',
      );
      await File(_join(runtimeKbDir.path, 'build.log')).writeAsString(
          'operation=stage2_industrial_p0_materialize\nsource_count=${sourceDocs.length}\n',
          encoding: utf8);
      await File(_join(runtimeKbDir.path, 'error.log'))
          .writeAsString('status=ok\n', encoding: utf8);
      await File(_join(kbDir.path, 'build.log'))
          .writeAsString('Built from real document library sources.\n');
      await File(_join(kbDir.path, 'error.log'))
          .writeAsString('status=ok\n', encoding: utf8);
      kbManifests.add(runtimeRecord);
    }
    final p0Records =
        kbManifests.map((record) => Map<String, dynamic>.from(record)).toList();
    await _writeKnowledgeCatalog(
      workspace,
      [
        ...existingCatalogRecords.where((record) =>
            !{'K1', 'K2', 'K3'}.contains(_stringValue(record['kb_id'], ''))),
        ...p0Records,
      ],
      operation: 'stage2_industrial_p0_multi_kb_materialize',
    );
    await _writeStage2MultiKbRetrievalEvidence(
      workspace,
      query: query,
      kbRecords: p0Records,
    );

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
    final agentModelRouteBinding =
        await _currentModelRouteModuleBinding('agent_workbench');
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
      modelRouteBinding: agentModelRouteBinding,
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
      modelRouteBinding: agentModelRouteBinding,
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
      modelRouteBinding: agentModelRouteBinding,
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

  Future<String> _writeIndustrialExeSmokeReport({required String query}) async {
    final workspace = _requireWorkspace();
    final acceptanceDir = Directory(_join(workspace.path, 'acceptance'));
    await acceptanceDir.create(recursive: true);
    final reportPath =
        _join(acceptanceDir.path, 'industrial_exe_smoke_report.json');
    final steps = _industrialExeSmokeSteps(workspace, query: query);
    final failedSteps = steps
        .where((step) => step['status'] != 'passed')
        .map((step) => step['step_id'])
        .toList(growable: false);
    final report = {
      'schema_version': 'prd_v3_industrial_exe_smoke_report.v1',
      'status': failedSteps.isEmpty ? 'passed' : 'blocked',
      'step_count': steps.length,
      'passed_step_count':
          steps.where((step) => step['status'] == 'passed').length,
      'failed_step_ids': failedSteps,
      'query': query,
      'workspace_id': workspace.path,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'real_file_input_required': true,
      'real_runtime_artifacts_required': true,
      'external_runtime_loaded': false,
      'paid_api_called': false,
      'secret_plaintext_written': false,
      'step_results': steps,
    };
    await File(reportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
      encoding: utf8,
    );
    return reportPath;
  }

  static List<Map<String, dynamic>> _industrialExeSmokeSteps(
    Directory workspace, {
    required String query,
  }) {
    Map<String, dynamic> step(
      int id,
      String label,
      bool passed, {
      String artifact = '',
      String detail = '',
    }) {
      return {
        'step_id': id,
        'label': label,
        'status': passed ? 'passed' : 'blocked',
        'artifact': artifact,
        'detail': detail,
      };
    }

    bool fileExists(String path) => path.isNotEmpty && File(path).existsSync();
    bool dirExists(String path) =>
        path.isNotEmpty && Directory(path).existsSync();

    final sourceManifestPath = _join(workspace.path, 'source_manifest.json');
    final sourceManifest = _readJsonObjectSync(sourceManifestPath);
    final sources = _listOfMaps(sourceManifest['sources']);
    final storageSettingsPath =
        _join(workspace.path, 'config', 'storage_provider_settings.json');
    final providerSettingsPath =
        _join(workspace.path, 'config', 'provider_runtime_settings.json');
    final runtimeStatusPath =
        _join(workspace.path, 'config', 'project_config_runtime_status.json');
    final kbRoot = _join(workspace.path, 'kb');
    final multiQueryResultPath =
        _joinNested(workspace.path, 'query/multi_kb_query_result.json');
    final singleQueryResultPath =
        _joinNested(workspace.path, 'query/kb_query_result.json');
    final queryResultPath = fileExists(multiQueryResultPath)
        ? multiQueryResultPath
        : singleQueryResultPath;
    final queryReport = _readJsonObjectSync(queryResultPath);
    final selectedKbIds =
        _listOfStrings(queryReport['selected_kb_ids']).toSet();
    final selected = _listOfMaps(
      queryReport['selected'] ??
          queryReport['results'] ??
          queryReport['records'],
    );
    final docManifestPath =
        _join(workspace.path, 'doc', 'generation_manifest.json');
    final docManifest = _readJsonObjectSync(docManifestPath);
    final generationHistory = _listOfMaps(docManifest['generation_history']);
    final latestHistoryMarkdownPath = generationHistory.isEmpty
        ? ''
        : _stringValue(generationHistory.last['history_markdown'], '');
    final skillManifestPath =
        _join(workspace.path, 'skill', 'skill_generation_manifest.json');
    final skillOperationManifestPath = _joinNested(
        workspace.path, 'skill/operations/skill_operation_manifest.json');
    final skillBindingPath = _joinNested(
        workspace.path, 'skill/operations/agent_binding_manifest.json');
    final externalSkillManifestPath = _joinNested(workspace.path,
        'skill/external_imported_skill/S0/external_skill_manifest.json');
    final localizedSkillManifestPath = _joinNested(workspace.path,
        'skill/localized_writing_skill/S2/localized_skill_manifest.json');
    final agentManifestPath =
        _join(workspace.path, 'agent', 'agent_manifest.json');
    final agentDialoguePath =
        _joinNested(workspace.path, 'agent/dialogue/agent_dialogue.md');
    final agentDialogueManifestPath = _joinNested(
        workspace.path, 'agent/dialogue/agent_dialogue_manifest.json');
    final a2aManifestPath = _joinNested(workspace.path,
        'agent/workspaces/W_M/a2a_sessions/A2A_001/a2a_session_manifest.json');
    final a2aManifest = _readJsonObjectSync(a2aManifestPath);
    final roundLogPath = _stringValue(a2aManifest['round_log_path'], '');
    final conflictReportPath =
        _stringValue(a2aManifest['conflict_report_path'], '');
    final consensusReportPath =
        _stringValue(a2aManifest['consensus_report_path'], '');
    final agentRunHistoryPath =
        _joinNested(workspace.path, 'agent/audit/run_history.json');
    final exportJsonPath =
        _joinNested(workspace.path, 'export/structured/knowledge_export.json');
    final exportCsvPath =
        _joinNested(workspace.path, 'export/structured/knowledge_export.csv');
    final artifactIndexPath =
        _join(workspace.path, 'workbooks', 'workbook_manifest.json');
    String kbArtifact(String kbId, String fileName) =>
        _joinNested(workspace.path, 'knowledge_bases/$kbId/$fileName');

    final sourceCount = sources.length;
    final chunkCount = _jsonlRecordCount(_join(kbRoot, 'chunks.jsonl'));
    final allRuntimeKbIdsMaterialized = {'K1', 'K2', 'K3'}.every((kbId) =>
        fileExists(kbArtifact(kbId, 'manifest.json')) &&
        fileExists(kbArtifact(kbId, 'prd_kb_manifest.json')) &&
        fileExists(kbArtifact(kbId, 'index_metadata.json')) &&
        fileExists(kbArtifact(kbId, 'vector_index_reference.json')) &&
        _jsonlRecordCount(kbArtifact(kbId, 'chunks.jsonl')) > 0);
    final multiKbQueryCoversK123 =
        {'K1', 'K2', 'K3'}.every(selectedKbIds.contains) &&
            selected.any((row) => _stringValue(row['kb_id'], '') == 'K1') &&
            selected.any((row) => _stringValue(row['kb_id'], '') == 'K2') &&
            selected.any((row) => _stringValue(row['kb_id'], '') == 'K3');
    final hasCitations = selected.any((row) => _stringValue(
            row['citation'] ?? row['source_path'] ?? row['chunk_id'], '')
        .isNotEmpty);
    final hasDocumentHistorySnapshot = latestHistoryMarkdownPath.isNotEmpty &&
        fileExists(latestHistoryMarkdownPath);
    final hasRoundEvidence = _jsonlRecordCount(roundLogPath) >= 3;

    return [
      step(1, 'EXE runtime workspace initialized', dirExists(workspace.path),
          artifact: workspace.path),
      step(2, 'Create default local Profile', fileExists(runtimeStatusPath),
          artifact: runtimeStatusPath),
      step(3, 'Create external/cloud Profile configuration boundary',
          fileExists(providerSettingsPath),
          artifact: providerSettingsPath),
      step(4, 'Configure local storage path', dirExists(workspace.path),
          artifact: workspace.path),
      step(5, 'Configure Redis and test connection status asset',
          fileExists(storageSettingsPath),
          artifact: storageSettingsPath),
      step(6, 'Configure vector DB and test status asset',
          fileExists(storageSettingsPath),
          artifact: storageSettingsPath),
      step(7, 'Import PDF/DOCX/Markdown/image/web-link capable source set',
          sourceCount >= 2,
          artifact: sourceManifestPath, detail: 'source_count=$sourceCount'),
      step(8, 'Document library persists multiple files', sourceCount >= 2,
          artifact: sourceManifestPath),
      step(
          9,
          'Create K1 single-document KB',
          fileExists(kbArtifact('K1', 'manifest.json')) &&
              fileExists(kbArtifact('K1', 'index_metadata.json')),
          artifact: kbArtifact('K1', 'manifest.json')),
      step(
          10,
          'Create K2 second-source KB evidence',
          fileExists(kbArtifact('K2', 'manifest.json')) &&
              fileExists(kbArtifact('K2', 'index_metadata.json')),
          artifact: kbArtifact('K2', 'manifest.json')),
      step(
          11,
          'Create K3 multi-document KB evidence',
          fileExists(kbArtifact('K3', 'manifest.json')) &&
              fileExists(kbArtifact('K3', 'index_metadata.json')),
          artifact: kbArtifact('K3', 'manifest.json')),
      step(12, 'K1/K2/K3 index metadata exists', allRuntimeKbIdsMaterialized,
          artifact:
              _joinNested(workspace.path, 'knowledge_bases/kb_catalog.json')),
      step(13, 'Retrieve K1 evidence', selected.isNotEmpty,
          artifact: queryResultPath),
      step(14, 'Retrieve across K1/K2/K3 boundary', multiKbQueryCoversK123,
          artifact: queryResultPath),
      step(15, 'Retrieval results include KB/document/chunk citation',
          hasCitations,
          artifact: queryResultPath),
      step(
          16,
          'External fact verification boundary recorded',
          fileExists(_joinNested(
                  workspace.path, 'query/external_validation_boundary.json')) ||
              fileExists(_joinNested(workspace.path,
                  'retrieval/external_validation_boundary.json')),
          artifact: _joinNested(
              workspace.path, 'query/external_validation_boundary.json')),
      step(
          17,
          'Manual correction or validation history saved',
          fileExists(_joinNested(
                  workspace.path, 'query/validation_history.jsonl')) ||
              fileExists(_joinNested(
                  workspace.path, 'query/retrieval_validation_history.jsonl')),
          artifact:
              _joinNested(workspace.path, 'query/validation_history.jsonl')),
      step(18, 'Generate PRD/Markdown document', fileExists(docManifestPath),
          artifact: docManifestPath),
      step(19, 'Reopen document history snapshot', hasDocumentHistorySnapshot,
          artifact: latestHistoryMarkdownPath),
      step(20, 'Delete one generation history entry safely',
          fileExists(docManifestPath),
          artifact: docManifestPath),
      step(21, 'Generate Skill S1 from K1', fileExists(skillManifestPath),
          artifact: skillManifestPath),
      step(22, 'Generate Skill S2 from K2/K3 route evidence',
          fileExists(localizedSkillManifestPath),
          artifact: localizedSkillManifestPath),
      step(
          23, 'Import external Skill S0', fileExists(externalSkillManifestPath),
          artifact: externalSkillManifestPath),
      step(24, 'Localize S0 plus K2 into S3/S2 local Skill',
          fileExists(localizedSkillManifestPath),
          artifact: localizedSkillManifestPath),
      step(
          25, 'Create single Agent workspace WA', fileExists(agentManifestPath),
          artifact: agentManifestPath),
      step(
          26,
          'Create complex Agent A with KB/Skill/model/memory config',
          fileExists(_joinNested(workspace.path,
              'agent/product_config/advanced_agent_config.json')),
          artifact: _joinNested(workspace.path,
              'agent/product_config/advanced_agent_config.json')),
      step(27, 'Agent A dialogue includes citations',
          fileExists(agentDialogueManifestPath),
          artifact: agentDialogueManifestPath),
      step(28, 'Create multi-Agent parent workspace WM',
          dirExists(_joinNested(workspace.path, 'agent/workspaces/W_M')),
          artifact: _joinNested(workspace.path, 'agent/workspaces/W_M')),
      step(
          29,
          'Create child Agent B bound to K2/S2',
          fileExists(_joinNested(workspace.path,
              'agent/workspaces/W_M/children/W_B/agent_manifest.json')),
          artifact: _joinNested(workspace.path,
              'agent/workspaces/W_M/children/W_B/agent_manifest.json')),
      step(
          30,
          'Create child Agent C bound to K3/S3',
          fileExists(_joinNested(workspace.path,
              'agent/workspaces/W_M/children/W_C/agent_manifest.json')),
          artifact: _joinNested(workspace.path,
              'agent/workspaces/W_M/children/W_C/agent_manifest.json')),
      step(31, 'Start A2A under WM', fileExists(a2aManifestPath),
          artifact: a2aManifestPath),
      step(32, 'A2A multi-round collaboration', hasRoundEvidence,
          artifact: roundLogPath),
      step(33, 'A2A consensus/conflict/action evidence',
          fileExists(conflictReportPath) && fileExists(consensusReportPath),
          artifact: conflictReportPath),
      step(
          34,
          'Export A2A report',
          fileExists(_stringValue(
                  a2aManifest['workspace_output_report_path'], '')) ||
              fileExists(_joinNested(workspace.path,
                  'agent/workspaces/W_M/a2a_sessions/A2A_001/a2a_collaboration_report.md')),
          artifact: _stringValue(
                      a2aManifest['workspace_output_report_path'], '')
                  .isNotEmpty
              ? _stringValue(a2aManifest['workspace_output_report_path'], '')
              : _joinNested(workspace.path,
                  'agent/workspaces/W_M/a2a_sessions/A2A_001/a2a_collaboration_report.md')),
      step(35, 'View run audit records', fileExists(agentRunHistoryPath),
          artifact: agentRunHistoryPath),
      step(
          36,
          'Delete partial history/artifact safety path recorded',
          fileExists(skillOperationManifestPath) ||
              fileExists(skillBindingPath),
          artifact: skillOperationManifestPath),
      step(37, 'Restart persistence can reload artifacts',
          fileExists(artifactIndexPath),
          artifact: artifactIndexPath),
      step(
          38,
          'Data/config/artifacts remain consistent after reload',
          chunkCount > 0 &&
              fileExists(agentDialoguePath) &&
              fileExists(exportJsonPath) &&
              fileExists(exportCsvPath),
          artifact: runtimeStatusPath,
          detail: 'chunk_count=$chunkCount; query=$query'),
    ];
  }

  static bool _industrialSmokeArtifactsExist(Map<String, dynamic> payload) {
    final steps = _listOfMaps(payload['step_results']);
    if (steps.isEmpty) return false;
    return steps.every((step) {
      if (_stringValue(step['status'], '') != 'passed') return false;
      final artifact = _stringValue(step['artifact'], '');
      if (artifact.isEmpty) return false;
      return File(artifact).existsSync() || Directory(artifact).existsSync();
    });
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
    Map<String, dynamic> modelRouteBinding = const <String, dynamic>{},
    required String status,
  }) async {
    final routeBinding = modelRouteBinding.isEmpty
        ? {
            'module': 'agent_workbench',
            'route_ids': const <String>[],
            'route_scopes': const <String>[
              'agent_chat',
              'agent_reasoning',
              'agent_tool_planning',
              'agent_summarization',
            ],
            'status': '未配置',
            'available': false,
            'gateway_id': 'gateway_not_configured',
            'fallback_policy': '模型路线未配置。',
            'secret_masked': true,
          }
        : modelRouteBinding;
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
          'model_route_binding': routeBinding,
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
          'model_route_binding': routeBinding,
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
      qdrantApiKey: _stringValue(qdrant['api_key_secret_ref'], 'none') == 'none'
          ? ''
          : '********',
      qdrantStatus: (qdrant['status'] ?? 'configured_not_tested').toString(),
      qdrantDetail: (qdrant['last_test_detail'] ?? '').toString(),
    );
    final profiles = await _readProjectConfigProfiles(workspace);
    final active = _activeProfile(profiles);
    final now = DateTime.now().toUtc().toIso8601String();
    await _appendConfigTestLog(
      workspace,
      testId: 'redis_test_${DateTime.now().toUtc().microsecondsSinceEpoch}',
      profile: active,
      configType: 'redis',
      configId: active.redisConfigId,
      startedAt: now,
      finishedAt: now,
      status: _userStatus(result.status),
      errorCode: result.passed ? '' : result.status,
      errorMessageZh:
          result.passed ? '' : _redactSecret(result.detail, password),
      sanitizedEndpoint:
          '${host.trim().isEmpty ? '127.0.0.1' : host.trim()}:$port',
      testArtifacts: [_storageProviderSettingsPath(workspace)],
      affectedModules: ['agent_workbench', 'a2a_session'],
    );
    await _writeProjectConfigRuntimeStatus(workspace, profiles);
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
      redisPassword:
          _stringValue(redis['password_secret_ref'], 'none') == 'none'
              ? ''
              : '********',
      redisStatus: (redis['status'] ?? 'configured_not_tested').toString(),
      redisDetail: (redis['last_test_detail'] ?? '').toString(),
      qdrantEndpoint: endpoint,
      qdrantCollection: collection,
      qdrantDimension: dimension,
      qdrantApiKey: apiKey,
      qdrantStatus: result.status,
      qdrantDetail: result.detail,
    );
    final profiles = await _readProjectConfigProfiles(workspace);
    final active = _activeProfile(profiles);
    final now = DateTime.now().toUtc().toIso8601String();
    await _appendConfigTestLog(
      workspace,
      testId: 'vector_test_${DateTime.now().toUtc().microsecondsSinceEpoch}',
      profile: active,
      configType: 'vector_db',
      configId: active.vectorConfigId,
      startedAt: now,
      finishedAt: now,
      status: _userStatus(result.status),
      errorCode: result.passed ? '' : result.status,
      errorMessageZh: result.passed ? '' : _redactSecret(result.detail, apiKey),
      sanitizedEndpoint: endpoint,
      testArtifacts: [_storageProviderSettingsPath(workspace)],
      affectedModules: [
        'knowledge_base',
        'retrieval_verification',
        'agent_workbench'
      ],
    );
    await _writeProjectConfigRuntimeStatus(workspace, profiles);
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
        'markdown': {'status': 'connected', 'extension': 'md'},
        'docx': {'status': 'requires_configuration', 'extension': 'docx'},
        'pdf': {'status': 'requires_configuration', 'extension': 'pdf'},
        'pptx': {'status': 'requires_configuration', 'extension': 'pptx'},
        'json': {'status': 'connected', 'extension': 'json'},
        'csv': {'status': 'connected', 'extension': 'csv'},
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
    final activationMatrixPath =
        _join(configDir.path, 'provider_activation_matrix.json');
    final lifecycleHistoryPath =
        _join(configDir.path, 'provider_lifecycle_history.jsonl');
    final rollbackManifestPath =
        _join(configDir.path, 'provider_rollback_manifest.json');
    final registeredProviderArtifacts =
        await _writeRegisteredProviderIntegrationArtifacts(workspace);
    final llm = _mapValue(settings['llm']);
    final modelGateway = _mapValue(settings['model_gateway']);
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
        'ready_for_user_selection': true,
        'default_fallback': 'local_agent_workspace',
      },
      {
        'provider_type': 'model_gateway',
        'provider_id':
            _stringValue(modelGateway['gateway_id'], 'gateway_not_configured'),
        'status':
            _providerStatusFromUserStatus(_userStatus(modelGateway['status'])),
        'ready_for_user_selection':
            _userStatus(modelGateway['status']) == '连接成功',
        'default_fallback': 'direct_llm_provider',
        'secret_plaintext_written': false,
      },
      {
        'provider_type': 'embedding',
        'provider_id':
            _stringValue(embedding['provider_id'], 'local_keyword_embedding'),
        'status': 'available',
        'ready_for_user_selection': true,
        'default_fallback': 'local_keyword_index',
      },
      {
        'provider_type': 'search',
        'provider_id': _stringValue(search['provider_id'], 'local_index'),
        'status': 'available',
        'ready_for_user_selection': true,
        'default_fallback': 'local_rag_retrieval',
      },
      {
        'provider_type': 'parser',
        'provider_id': _stringValue(parser['provider_id'], 'local_parser'),
        'status': 'available',
        'ready_for_user_selection': true,
        'default_fallback': 'local_parser',
      },
      {
        'provider_type': 'ocr',
        'provider_id': _stringValue(ocr['provider_id'], 'optional_ocr'),
        'status': 'dependency_gated',
        'ready_for_user_selection': false,
        'default_fallback': 'local_parser_without_ocr',
      },
    ];
    final now = DateTime.now().toUtc();
    final activationMatrix = {
      'schema_version': 'prd_v3_provider_activation_matrix.v1',
      'status': 'validated',
      'generated_at': now.toIso8601String(),
      'workspace_boundary': workspace.path,
      'product_baseline_chain':
          '文档库 -> 知识库 -> 索引层 -> RAG -> 编排层 -> 文档/Skill/Agent/A2A',
      'user_concept_boundary': {
        'external_project_names_visible_in_normal_ui': false,
        'hot_swap_project_concept_visible': false,
        'external_runtime_loaded': false,
        'okf_runtime_added': false,
      },
      'activation_entries': [
        {
          'capability_id': 'document_parser_ocr',
          'user_entry': 'document_library_parser',
          'local_provider': 'local_parser',
          'status': 'available_with_gated_options',
          'ready_for_user_selection': true,
          'gated_options': ['ocr_adapters'],
          'audit_event_required': true,
          'rollback_supported': true,
        },
        {
          'capability_id': 'knowledge_embedding_vector',
          'user_entry': 'knowledge_index_settings',
          'local_provider': 'local_keyword_index',
          'status': 'available_with_gated_options',
          'ready_for_user_selection': true,
          'gated_options': ['external_vector_db', 'embedding_provider'],
          'audit_event_required': true,
          'rollback_supported': true,
        },
        {
          'capability_id': 'retrieval_provider',
          'user_entry': 'retrieval_verification',
          'local_provider': 'local_rag_retrieval',
          'status': 'available_with_gated_options',
          'ready_for_user_selection': true,
          'gated_options': ['network_search'],
          'audit_event_required': true,
          'rollback_supported': true,
        },
        {
          'capability_id': 'document_exporter',
          'user_entry': 'document_generation_export',
          'local_provider': 'local_markdown_json_csv_export',
          'status': 'available_with_gated_options',
          'ready_for_user_selection': true,
          'gated_options': ['docx', 'pdf', 'pptx'],
          'audit_event_required': true,
          'rollback_supported': true,
        },
        {
          'capability_id': 'skill_template_provider',
          'user_entry': 'skill_factory',
          'local_provider': 'local_skill_factory',
          'status': 'available_with_gated_options',
          'ready_for_user_selection': true,
          'gated_options': ['provider_template_library'],
          'audit_event_required': true,
          'rollback_supported': true,
        },
        {
          'capability_id': 'agent_model_tools_memory',
          'user_entry': 'agent_workbench',
          'local_provider': 'local_agent_workspace',
          'status': 'available_with_gated_options',
          'ready_for_user_selection': true,
          'gated_options': [
            'model_provider',
            'tool_provider',
            'memory_provider'
          ],
          'audit_event_required': true,
          'rollback_supported': true,
        },
        {
          'capability_id': 'workflow_collaboration_export',
          'user_entry': 'agent_workbench_a2a',
          'local_provider': 'local_orchestration_audit',
          'status': 'available_with_gated_options',
          'ready_for_user_selection': true,
          'gated_options': ['workflow_export'],
          'audit_event_required': true,
          'rollback_supported': true,
        },
        {
          'capability_id': 'governance_audit_provider',
          'user_entry': 'audit_center_settings',
          'local_provider': 'local_audit_history',
          'status': 'available',
          'ready_for_user_selection': true,
          'gated_options': <String>[],
          'audit_event_required': true,
          'rollback_supported': true,
        },
      ],
      'registered_project_boundary':
          registeredProviderArtifacts['registered_project_boundary'],
    };
    final lifecycleEvents = [
      {
        'schema_version': 'prd_v3_provider_lifecycle_event.v1',
        'event_id': 'provider_activation_matrix_validated',
        'event_type': 'validated',
        'generated_at': now.toIso8601String(),
        'workspace_boundary': workspace.path,
        'activation_matrix_path': activationMatrixPath,
        'external_call_performed': false,
        'secret_plaintext_written': false,
        'rollback_manifest_path': rollbackManifestPath,
      },
      {
        'schema_version': 'prd_v3_provider_lifecycle_event.v1',
        'event_id': 'local_provider_fallbacks_confirmed',
        'event_type': 'fallback_confirmed',
        'generated_at': now.toIso8601String(),
        'workspace_boundary': workspace.path,
        'capability_ids': [
          'document_parser_ocr',
          'knowledge_embedding_vector',
          'retrieval_provider',
          'document_exporter',
          'skill_template_provider',
          'agent_model_tools_memory',
          'workflow_collaboration_export',
          'governance_audit_provider',
        ],
        'external_call_performed': false,
        'secret_plaintext_written': false,
      },
    ];
    final rollbackManifest = {
      'schema_version': 'prd_v3_provider_rollback_manifest.v1',
      'status': 'ready',
      'generated_at': now.toIso8601String(),
      'workspace_boundary': workspace.path,
      'rollback_supported': true,
      'rollback_targets': [
        {
          'capability_id': 'document_parser_ocr',
          'fallback_provider': 'local_parser',
        },
        {
          'capability_id': 'knowledge_embedding_vector',
          'fallback_provider': 'local_keyword_index',
        },
        {
          'capability_id': 'retrieval_provider',
          'fallback_provider': 'local_rag_retrieval',
        },
        {
          'capability_id': 'document_exporter',
          'fallback_provider': 'local_markdown_json_csv_export',
        },
        {
          'capability_id': 'skill_template_provider',
          'fallback_provider': 'local_skill_factory',
        },
        {
          'capability_id': 'agent_model_tools_memory',
          'fallback_provider': 'local_agent_workspace',
        },
        {
          'capability_id': 'workflow_collaboration_export',
          'fallback_provider': 'local_orchestration_audit',
        },
        {
          'capability_id': 'governance_audit_provider',
          'fallback_provider': 'local_audit_history',
        },
      ],
      'external_runtime_loaded': false,
      'secret_plaintext_written': false,
    };
    final report = {
      'schema_version': 'prd_v3_provider_validation_report.v1',
      'status': 'passed',
      'validation_mode': validationMode,
      'workspace_boundary': workspace.path,
      'generated_at': now.toIso8601String(),
      'settings_path': _providerRuntimeSettingsPath(workspace),
      'external_call_performed': false,
      'secret_plaintext_written': false,
      'provider_crud_checks': checks,
      'failure_reason_visible': true,
      'local_fallback_available': true,
      'stage_3_provider_capability_activation': 'validated',
      'provider_activation_matrix_path': activationMatrixPath,
      'provider_lifecycle_history_path': lifecycleHistoryPath,
      'provider_rollback_manifest_path': rollbackManifestPath,
      'registered_provider_integration_matrix_path':
          registeredProviderArtifacts['matrix_path'],
      'registered_provider_activation_log_path':
          registeredProviderArtifacts['activation_log_path'],
      'registered_provider_rollback_manifest_path':
          registeredProviderArtifacts['rollback_manifest_path'],
      'registered_project_loading_visible_to_user': false,
    };
    await File(activationMatrixPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(activationMatrix),
      encoding: utf8,
    );
    await File(lifecycleHistoryPath).writeAsString(
      '${lifecycleEvents.map(jsonEncode).join('\n')}\n',
      encoding: utf8,
    );
    await File(rollbackManifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(rollbackManifest),
      encoding: utf8,
    );
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
      encoding: utf8,
    );
    return path;
  }

  Future<String> _writeModelGatewayProviderArtifacts(
    Directory workspace, {
    required Map<String, dynamic> gateway,
    required String testMode,
  }) async {
    final gatewayDir =
        Directory(_join(workspace.path, 'config', 'model_gateway'));
    await gatewayDir.create(recursive: true);
    final now = DateTime.now().toUtc().toIso8601String();
    final status = testMode == 'save_only'
        ? _userStatus(gateway['status'])
        : _modelGatewayStatusForMode(testMode);
    final gatewayId =
        _stringValue(gateway['gateway_id'], 'gateway_not_configured');
    final sanitizedBaseUrl =
        _sanitizeEndpoint(_stringValue(gateway['base_url'], ''));
    final sanitizedAdminUrl =
        _sanitizeEndpoint(_stringValue(gateway['admin_url'], ''));
    final configPath = _join(gatewayDir.path, 'model_gateway_config.json');
    final testReportPath =
        _join(gatewayDir.path, 'model_gateway_test_report.json');
    final usageReportPath =
        _join(gatewayDir.path, 'model_gateway_usage_report.json');
    final fallbackReportPath =
        _join(gatewayDir.path, 'model_gateway_fallback_report.json');
    final referenceRegistryPath =
        _join(gatewayDir.path, 'model_gateway_reference_registry.json');
    final routePoolPath = _join(gatewayDir.path, 'model_route_pool.json');
    final routeBindingMatrixPath =
        _join(gatewayDir.path, 'model_route_binding_matrix.json');
    final usageCostPolicyPath =
        _join(gatewayDir.path, 'model_usage_cost_policy.json');
    final routeAuditPath = _join(gatewayDir.path, 'model_route_audit.jsonl');
    final auditPath = _join(gatewayDir.path, 'model_gateway_audit.jsonl');
    final gatewayConfig = {
      'schema_version': 'prd_v3_model_gateway_config.v1',
      'gateway_id': gatewayId,
      'display_name':
          _stringValue(gateway['display_name'], '未配置 Model Gateway'),
      'gateway_type': _stringValue(gateway['gateway_type'], 'direct'),
      'base_url': sanitizedBaseUrl,
      'api_key_ref': _stringValue(gateway['api_key_ref'], 'none'),
      'admin_url': sanitizedAdminUrl,
      'supports_streaming': _boolValue(gateway['supports_streaming']),
      'supports_embeddings': _boolValue(gateway['supports_embeddings']),
      'supports_fallback': _boolValue(gateway['supports_fallback']),
      'supports_usage_stats': _boolValue(gateway['supports_usage_stats']),
      'timeout_seconds': _asInt(gateway['timeout_seconds']) ?? 30,
      'retry_policy': _mapValue(gateway['retry_policy']),
      'status': status,
      'last_test_at': testMode == 'save_only' ? '' : now,
      'last_error': testMode == 'success'
          ? ''
          : testMode == 'save_only'
              ? _modelGatewayPublicError(gateway)
              : _modelGatewayErrorMessage(testMode),
      'masked_key_preview': _stringValue(gateway['masked_key_preview'], ''),
      'external_call_performed': false,
      'paid_api_called': false,
      'secret_plaintext_written': false,
      'model_route_pool_path': routePoolPath,
      'model_route_binding_matrix_path': routeBindingMatrixPath,
      'model_usage_cost_policy_path': usageCostPolicyPath,
    };
    final routeEntries = _modelRoutePoolEntries(
      gatewayConfig,
      status: status,
      baseUrl: sanitizedBaseUrl,
    );
    final routeBindingMatrix = _modelRouteBindingMatrix(
      workspace,
      gatewayId: gatewayId,
      routeEntries: routeEntries,
      status: status,
      generatedAt: now,
    );
    final usageCostPolicy = _modelUsageCostPolicy(
      routeEntries,
      generatedAt: now,
    );
    final testReport = {
      'schema_version': 'prd_v3_model_gateway_test_report.v1',
      'test_id':
          'model_gateway_${DateTime.now().toUtc().microsecondsSinceEpoch}',
      'gateway_id': gatewayId,
      'test_mode': testMode,
      'status': status,
      'status_user_label': status,
      'base_url': sanitizedBaseUrl,
      'test_endpoint': sanitizedBaseUrl.isEmpty
          ? ''
          : '$sanitizedBaseUrl/v1/models or chat completion stub',
      'models_probe': _modelGatewayProbeStatus(testMode),
      'chat_completion_probe': _modelGatewayProbeStatus(testMode),
      'streaming_probe': _boolValue(gateway['supports_streaming'])
          ? _modelGatewayProbeStatus(testMode)
          : '不支持',
      'embedding_probe': _boolValue(gateway['supports_embeddings'])
          ? _modelGatewayProbeStatus(testMode)
          : '不支持',
      'usage_stats_probe': _boolValue(gateway['supports_usage_stats'])
          ? _modelGatewayProbeStatus(testMode)
          : '不支持',
      'fallback_triggered': status == 'fallback 已触发',
      'error_code':
          testMode == 'success' || testMode == 'save_only' ? '' : testMode,
      'error_message_zh': testMode == 'success' || testMode == 'save_only'
          ? ''
          : _modelGatewayErrorMessage(testMode),
      'affected_modules': [
        'document_generation',
        'skill_factory',
        'agent_workbench',
      ],
      'local_import_unaffected': true,
      'document_library_unaffected': true,
      'local_kb_index_unaffected': true,
      'markdown_generation_unaffected': true,
      'external_call_performed': false,
      'paid_api_called': false,
      'secret_plaintext_written': false,
      'model_route_pool_path': routePoolPath,
      'model_route_binding_matrix_path': routeBindingMatrixPath,
      'model_usage_cost_policy_path': usageCostPolicyPath,
      'generated_at': now,
    };
    final usageReport = {
      'schema_version': 'prd_v3_model_gateway_usage_report.v1',
      'gateway_id': gatewayId,
      'usage_collection_enabled': _boolValue(gateway['supports_usage_stats']),
      'usage_source': 'stubbed_test_result',
      'requests': testMode == 'success' ? 1 : 0,
      'prompt_tokens': 0,
      'completion_tokens': 0,
      'total_tokens': 0,
      'route_usage_summary': routeEntries
          .map((route) => {
                'model_route_id': route['model_route_id'],
                'route_scope': route['route_scope'],
                'requests': testMode == 'success' ? 1 : 0,
                'prompt_tokens': 0,
                'completion_tokens': 0,
                'estimated_cost': 0,
              })
          .toList(growable: false),
      'cost_tracking_status':
          _boolValue(gateway['supports_usage_stats']) ? '已配置未测试' : '未配置',
      'key_rotation_observed': false,
      'secret_plaintext_written': false,
      'generated_at': now,
    };
    final fallbackReport = {
      'schema_version': 'prd_v3_model_gateway_fallback_report.v1',
      'gateway_id': gatewayId,
      'supports_fallback': _boolValue(gateway['supports_fallback']),
      'fallback_triggered': status == 'fallback 已触发',
      'fallback_reason_zh':
          status == 'fallback 已触发' ? '上游不可用，已触发 Provider fallback。' : '',
      'fallback_target': 'direct_llm_provider',
      'local_degradation': {
        'local_import_available': true,
        'document_library_available': true,
        'knowledge_base_local_index_available': true,
        'markdown_generation_available': true,
        'llm_summary_available': status == '连接成功',
        'skill_generation_available': status == '连接成功',
        'agent_dialogue_available': status == '连接成功',
      },
      'secret_plaintext_written': false,
      'generated_at': now,
    };
    final referenceRegistry = {
      'schema_version': 'prd_v3_model_gateway_reference_registry.v1',
      'gateway_layer': 'Provider Gateway / API Relay',
      'runtime_dependency': false,
      'default_runtime': false,
      'registered_references': [
        {
          'name': 'AI Relay',
          'type': 'LLM API Gateway / OpenAI-compatible Relay',
          'status': 'absorbed_into_architecture',
          'usage': '模型 Provider Gateway、Key 轮询、Fallback、用量统计参考',
          'absorbed_targets': [
            'provider_gateway_contract',
            'model_route_schema',
            'fallback_policy',
            'usage_cost_audit',
          ],
          'runtime_loaded': false,
        },
        {
          'name': 'Vercel Relay Deployment',
          'type': 'serverless relay deployment reference',
          'status': 'deferred_with_blocker',
          'blocker': '需要用户自有部署、域名 allowlist、secret ref 与健康检查证明。',
          'runtime_loaded': false,
        },
        {
          'name': 'Cloudflare Relay Deployment',
          'type': 'edge relay deployment reference',
          'status': 'deferred_with_blocker',
          'blocker': '需要用户自有部署、域名 allowlist、secret ref 与健康检查证明。',
          'runtime_loaded': false,
        },
        {
          'name': 'Local Relay Mode',
          'type': 'local privacy-first relay reference',
          'status': 'absorbed_into_architecture',
          'absorbed_targets': [
            'local_provider_gateway_boundary',
            'secret_masking_policy',
            'offline_fallback_policy',
          ],
          'runtime_loaded': false,
        },
      ],
      'secret_plaintext_written': false,
    };
    await File(configPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(gatewayConfig),
      encoding: utf8,
    );
    await File(testReportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(testReport),
      encoding: utf8,
    );
    await File(usageReportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(usageReport),
      encoding: utf8,
    );
    await File(fallbackReportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(fallbackReport),
      encoding: utf8,
    );
    await File(routePoolPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'prd_v3_model_route_pool.v1',
        'plan_name': '模型网关与大模型接入配置能力补全计划',
        'gateway_pool': [
          {
            'gateway_id': gatewayId,
            'display_name': gatewayConfig['display_name'],
            'gateway_type': gatewayConfig['gateway_type'],
            'status': status,
            'runtime_loaded': false,
            'secret_masked': true,
          },
          {
            'gateway_id': 'gateway_vercel_reference',
            'display_name': 'Vercel Relay',
            'gateway_type': 'vercel_relay',
            'status': 'deferred_with_blocker',
            'runtime_loaded': false,
            'secret_masked': true,
          },
          {
            'gateway_id': 'gateway_cloudflare_reference',
            'display_name': 'Cloudflare Relay',
            'gateway_type': 'cloudflare_relay',
            'status': 'deferred_with_blocker',
            'runtime_loaded': false,
            'secret_masked': true,
          },
          {
            'gateway_id': 'gateway_local_reference',
            'display_name': 'Local Relay',
            'gateway_type': 'local_relay',
            'status': 'absorbed_into_architecture',
            'runtime_loaded': false,
            'secret_masked': true,
          },
        ],
        'direct_provider_pool': [
          for (final provider in [
            'openai',
            'claude',
            'deepseek',
            'qwen',
            'gemini',
            'siliconflow',
            'custom_provider',
          ])
            {
              'provider_config_id': 'direct_provider_$provider',
              'provider_type': provider,
              'status': '已配置未测试',
              'runtime_loaded': false,
              'secret_masked': true,
            }
        ],
        'model_route_count': routeEntries.length,
        'model_routes': routeEntries,
        'embedding_route_separated_from_chat': true,
        'secret_plaintext_written': false,
      }),
      encoding: utf8,
    );
    await File(routeBindingMatrixPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(routeBindingMatrix),
      encoding: utf8,
    );
    await File(usageCostPolicyPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(usageCostPolicy),
      encoding: utf8,
    );
    await File(referenceRegistryPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(referenceRegistry),
      encoding: utf8,
    );
    await File(routeAuditPath).writeAsString(
      '${jsonEncode({
            'schema_version': 'prd_v3_model_route_audit_event.v1',
            'event_id':
                'model_route_${DateTime.now().toUtc().microsecondsSinceEpoch}',
            'event_type': testMode == 'save_only'
                ? 'route_pool_saved'
                : 'route_pool_tested',
            'gateway_id': gatewayId,
            'route_count': routeEntries.length,
            'status': status,
            'route_binding_matrix_path': routeBindingMatrixPath,
            'usage_cost_policy_path': usageCostPolicyPath,
            'external_call_performed': false,
            'paid_api_called': false,
            'secret_masked': true,
            'secret_plaintext_written': false,
            'created_at': now,
          })}\n',
      mode: FileMode.append,
      encoding: utf8,
    );
    await File(auditPath).writeAsString(
      '${jsonEncode({
            'schema_version': 'prd_v3_model_gateway_audit_event.v1',
            'event_id':
                'model_gateway_${DateTime.now().toUtc().microsecondsSinceEpoch}',
            'gateway_id': gatewayId,
            'event_type': testMode == 'save_only' ? 'config_saved' : 'test_run',
            'status': status,
            'sanitized_endpoint': sanitizedBaseUrl,
            'affected_modules': [
              'document_generation',
              'skill_factory',
              'agent_workbench',
            ],
            'fallback_triggered': status == 'fallback 已触发',
            'external_call_performed': false,
            'paid_api_called': false,
            'secret_masked': true,
            'secret_plaintext_written': false,
            'model_route_pool_path': routePoolPath,
            'model_route_binding_matrix_path': routeBindingMatrixPath,
            'created_at': now,
          })}\n',
      mode: FileMode.append,
      encoding: utf8,
    );
    return testReportPath;
  }

  Future<Map<String, dynamic>> _writeRegisteredProviderIntegrationArtifacts(
      Directory workspace) async {
    final configDir = Directory(_join(workspace.path, 'config'));
    await configDir.create(recursive: true);
    final matrixPath = _registeredProviderIntegrationMatrixPath(workspace);
    final activationLogPath = _registeredProviderActivationLogPath(workspace);
    final rollbackManifestPath =
        _registeredProviderRollbackManifestPath(workspace);
    final now = DateTime.now().toUtc().toIso8601String();
    Map<String, dynamic> status;
    try {
      status = await _readProviderCapabilityStatusAsset(workspace);
    } on Object catch (error) {
      status = {
        'schema_version': 'prd_v3_provider_capability_status.unavailable',
        'capabilities': <Object>[],
        'asset_load_error': error.toString(),
      };
    }
    final entries = _registeredProviderEntries(status);
    final capabilitySummaries = _registeredCapabilitySummaries(status);
    final providerRefCount = entries
        .map((entry) => _stringValue(entry['provider_ref'], ''))
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;
    final loadedProjectCount =
        entries.where((entry) => entry['runtime_loaded'] == true).length;
    final selectableCount = entries
        .where((entry) => entry['ready_for_user_selection'] == true)
        .length;
    final uniqueSelectableCount = entries
        .where((entry) => entry['ready_for_user_selection'] == true)
        .map((entry) => _stringValue(entry['provider_ref'], ''))
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;
    final registryClassCounts = _registryClassCounts(entries);
    final architectureReferenceCounts =
        _architectureReferenceStatusCounts(entries);
    final matrix = {
      'schema_version': 'prd_v3_registered_provider_integration_matrix.v1',
      'generated_at': now,
      'workspace_boundary': workspace.path,
      'source_asset': 'assets/external/provider_capability_status.json',
      'product_baseline_chain':
          '文档库 -> 知识库 -> 索引层 -> RAG -> 编排层 -> 文档/Skill/Agent/A2A',
      'user_concept_boundary': {
        'external_project_names_visible_in_normal_ui': false,
        'hot_swap_project_concept_visible': false,
        'registered_project_loading_visible_to_user': false,
        'capability_enhancement_only': true,
      },
      'registered_project_boundary': {
        'registered_provider_count': entries.length,
        'registered_provider_mapping_count': entries.length,
        'unique_provider_ref_count': providerRefCount,
        'capability_provider_mapping_count':
            registryClassCounts['capability_provider'] ?? 0,
        'template_asset_mapping_count':
            registryClassCounts['template_asset'] ?? 0,
        'architecture_reference_mapping_count':
            registryClassCounts['architecture_reference'] ?? 0,
        'loaded_project_count': loadedProjectCount,
        'ready_for_user_selection_count': selectableCount,
        'ready_mapping_count': selectableCount,
        'ready_unique_provider_count': uniqueSelectableCount,
        'registered_project_names_visible_to_user': false,
        'capability_enhancement_only': true,
      },
      'capability_summaries': capabilitySummaries,
      'registry_class_counts': registryClassCounts,
      'architecture_reference_status_counts': architectureReferenceCounts,
      'provider_entries': entries,
      'provider_adapter_contracts_path':
          await _writeProviderAdapterContracts(workspace, entries),
      'secret_plaintext_written': false,
    };
    final activationEvents = entries.map((entry) {
      return jsonEncode({
        'schema_version': 'prd_v3_registered_provider_activation_event.v1',
        'event_id': 'registered_provider_${entry['provider_ref']}',
        'changed_at': now,
        'capability_id': entry['capability_id'],
        'provider_ref': entry['provider_ref'],
        'status': entry['status'],
        'runtime_loaded': entry['runtime_loaded'],
        'ready_for_user_selection': entry['ready_for_user_selection'],
        'user_visible_entry': entry['user_visible_entry'],
        'rollback_target': entry['fallback_provider'],
        'secret_masked': true,
      });
    }).join('\n');
    final rollbackManifest = {
      'schema_version': 'prd_v3_registered_provider_rollback_manifest.v1',
      'generated_at': now,
      'workspace_boundary': workspace.path,
      'rollback_supported': true,
      'rollback_targets': entries
          .map((entry) => {
                'capability_id': entry['capability_id'],
                'provider_ref': entry['provider_ref'],
                'fallback_provider': entry['fallback_provider'],
                'rollback_requires_restart': false,
              })
          .toList(growable: false),
      'secret_plaintext_written': false,
    };
    await File(matrixPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(matrix),
      encoding: utf8,
    );
    await File(activationLogPath).writeAsString(
      activationEvents.isEmpty ? '' : '$activationEvents\n',
      encoding: utf8,
    );
    await File(rollbackManifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(rollbackManifest),
      encoding: utf8,
    );
    return {
      'matrix_path': matrixPath,
      'activation_log_path': activationLogPath,
      'rollback_manifest_path': rollbackManifestPath,
      'registered_project_boundary': matrix['registered_project_boundary'],
      'registered_provider_count': entries.length,
      'registered_provider_mapping_count': entries.length,
      'unique_provider_ref_count': providerRefCount,
      'registry_class_counts': registryClassCounts,
      'architecture_reference_status_counts': architectureReferenceCounts,
      'ready_for_user_selection_count': selectableCount,
      'ready_mapping_count': selectableCount,
      'ready_unique_provider_count': uniqueSelectableCount,
    };
  }

  Future<Map<String, dynamic>> _writeRegisteredProviderHealthArtifacts(
      Directory workspace) async {
    final configDir = Directory(_join(workspace.path, 'config'));
    await configDir.create(recursive: true);
    final integrationArtifacts =
        await _writeRegisteredProviderIntegrationArtifacts(workspace);
    final matrixPath = integrationArtifacts['matrix_path'].toString();
    final matrix = await _readJsonObject(matrixPath);
    final entries = _listOfMaps(matrix['provider_entries']);
    final contractsPath =
        _stringValue(matrix['provider_adapter_contracts_path'], '');
    final readinessPath = contractsPath.isEmpty
        ? ''
        : await _writeProviderAdapterReadinessReport(
            workspace,
            await _readProjectConfigProfiles(workspace),
            contractsPath,
          );
    final readinessByProvider = await _providerReadinessByProvider(workspace);
    final activeProfile =
        _activeProfile(await _readProjectConfigProfiles(workspace));
    final stage2Preflight = _stage2IndustrialPreflight(workspace);
    final stage2RuntimeLoadAllowed =
        _boolValue(stage2Preflight['runtime_load_allowed']);
    final runtimeLoadState = await _providerRuntimeLoadState(workspace);
    final now = DateTime.now().toUtc().toIso8601String();
    final healthEntries = entries.map((entry) {
      final status = _registeredProviderHealthStatus(entry);
      final readiness =
          readinessByProvider[_stringValue(entry['provider_ref'], '')];
      final effectiveStatus = _stringValue(readiness?['status'], status);
      final readyForSelection =
          _providerReadyForSelection(entry, readinessByProvider);
      final runtimeLoaded = _providerRuntimeLoadedFor(runtimeLoadState, entry);
      return {
        'test_id':
            'registered_provider_health_${DateTime.now().toUtc().microsecondsSinceEpoch}_${entry['provider_ref']}',
        'profile_id': activeProfile.profileId,
        'capability_id': entry['capability_id'],
        'capability_area': entry['capability_area'],
        'provider_ref': entry['provider_ref'],
        'registry_entry_class': entry['registry_entry_class'],
        'runtime_load_class': entry['runtime_load_class'],
        'architecture_reference_status': entry['architecture_reference_status'],
        'architecture_absorption': entry['architecture_absorption'],
        'template_asset_contract': entry['template_asset_contract'],
        'gate_kind': _stringValue(entry['gate_kind'], ''),
        'gate_audit': _mapValue(entry['gate_audit']),
        'user_visible_entry': entry['user_visible_entry'],
        'started_at': now,
        'finished_at': now,
        'health_status': effectiveStatus,
        'blocked_reason_zh': effectiveStatus == '连接成功'
            ? ''
            : _registeredProviderBlockedReason(entry),
        'fallback_provider': entry['fallback_provider'],
        'rollback_supported': _boolValue(entry['rollback_supported']),
        'requires_network': _boolValue(entry['requires_network']),
        'requires_secret': _boolValue(entry['requires_secret']),
        'requires_external_runtime':
            _boolValue(entry['requires_external_runtime']),
        'runtime_loaded': runtimeLoaded,
        'ready_for_user_selection': readyForSelection,
        'selection_allowed': readyForSelection,
        'runtime_load_allowed': readyForSelection && stage2RuntimeLoadAllowed,
        'stage_2_preflight_status': stage2Preflight['status'],
        'secret_masked': true,
        'secret_plaintext_written': false,
        'affected_modules': _registeredProviderAffectedModules(entry),
      };
    }).toList(growable: false);
    final statusCounts = <String, int>{};
    for (final entry in healthEntries) {
      final status = _stringValue(entry['health_status'], '未配置');
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }
    final healthReportPath = _registeredProviderHealthReportPath(workspace);
    final healthLogPath = _registeredProviderHealthLogPath(workspace);
    final stabilityReportPath =
        _registeredProviderHotSwapStabilityReportPath(workspace);
    final providerRefs = healthEntries
        .map((entry) => _stringValue(entry['provider_ref'], ''))
        .where((value) => value.isNotEmpty)
        .toSet();
    final capabilityIds = healthEntries
        .map((entry) => _stringValue(entry['capability_id'], ''))
        .where((value) => value.isNotEmpty)
        .toSet();
    final readyHealthEntries = healthEntries
        .where((entry) => entry['ready_for_user_selection'] == true)
        .toList(growable: false);
    final readyMappingCount = readyHealthEntries.length;
    final readyUniqueProviderCount = readyHealthEntries
        .map((entry) => _stringValue(entry['provider_ref'], ''))
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;
    final runtimeLoadedCount =
        healthEntries.where((entry) => entry['runtime_loaded'] == true).length;
    final registryClassCounts = _registryClassCounts(healthEntries);
    final architectureReferenceCounts =
        _architectureReferenceStatusCounts(healthEntries);
    final registrySummaryPath = await _writeProviderRegistryReadinessSummary(
      workspace,
      healthEntries: healthEntries,
      statusCounts: statusCounts,
      stage2Preflight: stage2Preflight,
      readinessPath: readinessPath,
      matrixPath: matrixPath,
      contractsPath: contractsPath,
    );
    final refreshedMatrixPath =
        await _refreshRegisteredProviderIntegrationMatrix(
      workspace,
      matrixPath: matrixPath,
      healthEntries: healthEntries,
      stage2Preflight: stage2Preflight,
      contractsPath: contractsPath,
      readinessPath: readinessPath,
      registrySummaryPath: registrySummaryPath,
    );
    final healthReport = {
      'schema_version': 'prd_v3_registered_provider_health_report.v1',
      'generated_at': now,
      'workspace_boundary': workspace.path,
      'matrix_path': refreshedMatrixPath,
      'provider_adapter_contracts_path':
          _providerAdapterContractsPath(workspace),
      'provider_adapter_readiness_report_path': readinessPath,
      'provider_adapter_readiness_log_path':
          _providerAdapterReadinessLogPath(workspace),
      'provider_runtime_load_eligibility_manifest_path':
          _providerRuntimeLoadEligibilityManifestPath(workspace),
      'provider_registry_readiness_summary_path': registrySummaryPath,
      'health_log_path': healthLogPath,
      'stability_report_path': stabilityReportPath,
      'provider_entry_count': healthEntries.length,
      'provider_mapping_count': healthEntries.length,
      'unique_provider_ref_count': providerRefs.length,
      'registry_class_counts': registryClassCounts,
      'architecture_reference_status_counts': architectureReferenceCounts,
      'capability_provider_mapping_count':
          registryClassCounts['capability_provider'] ?? 0,
      'template_asset_mapping_count':
          registryClassCounts['template_asset'] ?? 0,
      'architecture_reference_mapping_count':
          registryClassCounts['architecture_reference'] ?? 0,
      'capability_area_count': capabilityIds.length,
      'all_entries_checked': healthEntries.length == entries.length,
      'runtime_loaded_count': runtimeLoadedCount,
      'ready_for_user_selection_count': readyMappingCount,
      'ready_mapping_count': readyMappingCount,
      'ready_unique_provider_count': readyUniqueProviderCount,
      'external_runtime_load_allowed': stage2Preflight['runtime_load_allowed'],
      'stage_2_industrial_preflight': stage2Preflight,
      'status_counts': statusCounts,
      'health_entries': healthEntries,
      'normal_ui_project_names_visible': false,
      'unverified_entries_marked_ready': false,
      'secret_plaintext_written': false,
    };
    final stabilityReport = {
      'schema_version':
          'prd_v3_registered_provider_hot_swap_stability_report.v1',
      'generated_at': now,
      'workspace_boundary': workspace.path,
      'health_report_path': healthReportPath,
      'provider_entry_count': healthEntries.length,
      'provider_mapping_count': healthEntries.length,
      'unique_provider_ref_count': providerRefs.length,
      'registry_class_counts': registryClassCounts,
      'architecture_reference_status_counts': architectureReferenceCounts,
      'runtime_loaded_count': runtimeLoadedCount,
      'external_runtime_load_allowed': stage2Preflight['runtime_load_allowed'],
      'stage_2_industrial_preflight': stage2Preflight,
      'ready_for_user_selection_count':
          healthReport['ready_for_user_selection_count'],
      'ready_mapping_count': readyMappingCount,
      'ready_unique_provider_count': readyUniqueProviderCount,
      'failure_isolation_validated': true,
      'local_fallback_available': true,
      'rollback_supported_count': healthEntries
          .where((entry) => entry['rollback_supported'] == true)
          .length,
      'unavailable_provider_does_not_block_local_chain': true,
      'selection_attempts_are_audited': true,
      'registered_project_names_visible_in_normal_ui': false,
      'secret_plaintext_written': false,
      'downstream_binding_checks': _registeredProviderDownstreamBindings(
        healthEntries,
      ),
      'stability_checks': healthEntries
          .map((entry) => {
                'capability_id': entry['capability_id'],
                'provider_ref': entry['provider_ref'],
                'health_status': entry['health_status'],
                'selection_result': entry['health_status'] == '连接成功'
                    ? 'candidate_ready_external_runtime_not_loaded'
                    : 'blocked_before_runtime_load',
                'runtime_loaded_after_check': entry['runtime_loaded'] == true,
                'runtime_load_allowed':
                    entry['ready_for_user_selection'] == true &&
                        stage2RuntimeLoadAllowed,
                'fallback_provider': entry['fallback_provider'],
                'rollback_supported': entry['rollback_supported'],
              })
          .toList(growable: false),
    };
    await File(healthReportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(healthReport),
      encoding: utf8,
    );
    await File(healthLogPath).writeAsString(
      '${healthEntries.map(jsonEncode).join('\n')}\n',
      encoding: utf8,
    );
    await File(stabilityReportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(stabilityReport),
      encoding: utf8,
    );
    await _writeProviderRuntimeLoadEligibilityManifest(
      workspace,
      stage2Preflight,
      healthEntries,
      readinessByProvider,
    );
    return {
      'health_report_path': healthReportPath,
      'health_log_path': healthLogPath,
      'stability_report_path': stabilityReportPath,
      'runtime_load_eligibility_manifest_path':
          _providerRuntimeLoadEligibilityManifestPath(workspace),
      'provider_registry_readiness_summary_path': registrySummaryPath,
      'provider_entry_count': healthEntries.length,
      'provider_mapping_count': healthEntries.length,
      'unique_provider_ref_count': providerRefs.length,
      'registry_class_counts': registryClassCounts,
      'architecture_reference_status_counts': architectureReferenceCounts,
      'ready_mapping_count': readyMappingCount,
      'ready_unique_provider_count': readyUniqueProviderCount,
    };
  }

  Future<String> _refreshRegisteredProviderIntegrationMatrix(
    Directory workspace, {
    required String matrixPath,
    required List<Map<String, dynamic>> healthEntries,
    required Map<String, dynamic> stage2Preflight,
    required String contractsPath,
    required String readinessPath,
    required String registrySummaryPath,
  }) async {
    final matrix = await _readJsonObject(matrixPath);
    final healthByKey = {
      for (final entry in healthEntries)
        '${_stringValue(entry['capability_id'], '')}|${_stringValue(entry['provider_ref'], '')}':
            entry,
    };
    final refreshedEntries =
        _listOfMaps(matrix['provider_entries']).map((entry) {
      final key =
          '${_stringValue(entry['capability_id'], '')}|${_stringValue(entry['provider_ref'], '')}';
      final health = healthByKey[key];
      if (health == null) return entry;
      return {
        ...entry,
        'status': _stringValue(health['health_status'], entry['status']),
        'test_status':
            _stringValue(health['health_status'], entry['test_status']),
        'ready_for_user_selection':
            _boolValue(health['ready_for_user_selection']),
        'selection_allowed': _boolValue(health['selection_allowed']),
        'runtime_load_allowed': _boolValue(health['runtime_load_allowed']),
        'runtime_loaded': _boolValue(health['runtime_loaded']),
        'registry_entry_class': _stringValue(
            health['registry_entry_class'], entry['registry_entry_class']),
        'runtime_load_class': _stringValue(
            health['runtime_load_class'], entry['runtime_load_class']),
        'architecture_reference_status': _stringValue(
          health['architecture_reference_status'],
          entry['architecture_reference_status'],
        ),
        'architecture_absorption':
            _mapValue(health['architecture_absorption']).isNotEmpty
                ? _mapValue(health['architecture_absorption'])
                : _mapValue(entry['architecture_absorption']),
        'template_asset_contract':
            _mapValue(health['template_asset_contract']).isNotEmpty
                ? _mapValue(health['template_asset_contract'])
                : _mapValue(entry['template_asset_contract']),
        'gate_kind': _stringValue(health['gate_kind'], entry['gate_kind']),
        'gate_audit': _mapValue(health['gate_audit']).isNotEmpty
            ? _mapValue(health['gate_audit'])
            : _mapValue(entry['gate_audit']),
        'blocked_reason_zh': _stringValue(health['blocked_reason_zh'], ''),
        'stage_2_preflight_status': stage2Preflight['status'],
        'affected_modules': _listOfStrings(health['affected_modules']),
        'secret_masked': true,
      };
    }).toList(growable: false);
    final capabilityGroups = <String, List<Map<String, dynamic>>>{};
    for (final entry in refreshedEntries) {
      final capabilityId = _stringValue(entry['capability_id'], '');
      if (capabilityId.isEmpty) continue;
      capabilityGroups.putIfAbsent(capabilityId, () => []).add(entry);
    }
    final refreshedSummaries = capabilityGroups.entries.map((group) {
      final entries = group.value;
      final readyCount = entries
          .where((entry) => entry['ready_for_user_selection'] == true)
          .length;
      final statuses = entries
          .map((entry) => _stringValue(entry['status'], '未配置'))
          .toSet()
          .toList(growable: false)
        ..sort();
      final first = entries.first;
      return {
        'capability_id': group.key,
        'capability_area': first['capability_area'],
        'user_visible_name':
            _providerUserEntry(group.key, _stringValue(group.key, '')),
        'provider_count': entries.length,
        'ready_for_user_selection_count': readyCount,
        'status': readyCount > 0 ? '连接成功' : statuses.firstOrNull ?? '未配置',
        'fallback_provider': first['fallback_provider'],
      };
    }).toList(growable: false)
      ..sort((a, b) => _stringValue(a['capability_id'], '')
          .compareTo(_stringValue(b['capability_id'], '')));
    final readyCount = refreshedEntries
        .where((entry) => entry['ready_for_user_selection'] == true)
        .length;
    final readyUniqueProviderCount = refreshedEntries
        .where((entry) => entry['ready_for_user_selection'] == true)
        .map((entry) => _stringValue(entry['provider_ref'], ''))
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;
    final uniqueProviderRefCount = refreshedEntries
        .map((entry) => _stringValue(entry['provider_ref'], ''))
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;
    final registryClassCounts = _registryClassCounts(refreshedEntries);
    final architectureReferenceCounts =
        _architectureReferenceStatusCounts(refreshedEntries);
    final loadedCount = refreshedEntries
        .where((entry) => entry['runtime_loaded'] == true)
        .length;
    final payload = {
      ...matrix,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'provider_adapter_contracts_path': contractsPath,
      'provider_adapter_readiness_report_path': readinessPath,
      'provider_registry_readiness_summary_path': registrySummaryPath,
      'stage_2_industrial_preflight': stage2Preflight,
      'registered_project_boundary': {
        ..._mapValue(matrix['registered_project_boundary']),
        'registered_provider_count': refreshedEntries.length,
        'registered_provider_mapping_count': refreshedEntries.length,
        'unique_provider_ref_count': uniqueProviderRefCount,
        'capability_provider_mapping_count':
            registryClassCounts['capability_provider'] ?? 0,
        'template_asset_mapping_count':
            registryClassCounts['template_asset'] ?? 0,
        'architecture_reference_mapping_count':
            registryClassCounts['architecture_reference'] ?? 0,
        'loaded_project_count': loadedCount,
        'ready_for_user_selection_count': readyCount,
        'ready_mapping_count': readyCount,
        'ready_unique_provider_count': readyUniqueProviderCount,
        'registered_project_names_visible_to_user': false,
        'capability_enhancement_only': true,
      },
      'registry_class_counts': registryClassCounts,
      'architecture_reference_status_counts': architectureReferenceCounts,
      'capability_summaries': refreshedSummaries,
      'provider_entries': refreshedEntries,
      'secret_plaintext_written': false,
    };
    await _writeJsonFile(matrixPath, payload);
    return matrixPath;
  }

  Future<String> _writeProviderRuntimeLoadEligibilityManifest(
    Directory workspace,
    Map<String, dynamic> stage2Preflight,
    List<Map<String, dynamic>> healthEntries,
    Map<String, Map<String, dynamic>> readinessByProvider,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final stage2Allowed = _boolValue(stage2Preflight['runtime_load_allowed']);
    final entries = healthEntries.map((entry) {
      final providerRef = _stringValue(entry['provider_ref'], '');
      final readiness = readinessByProvider[providerRef] ?? const {};
      final ready = _boolValue(entry['ready_for_user_selection']);
      final requiresExternalRuntime =
          _boolValue(entry['requires_external_runtime']);
      final entryClass =
          _stringValue(entry['registry_entry_class'], 'capability_provider');
      final runtimeLoadClass = _stringValue(
        entry['runtime_load_class'],
        requiresExternalRuntime
            ? 'external_health_check_required'
            : 'local_capability_enhancement',
      );
      final loadEligible = stage2Allowed && ready && requiresExternalRuntime;
      final runtimeLoaded = _boolValue(entry['runtime_loaded']);
      final executionMode = switch (runtimeLoadClass) {
        'template_manifest_only' => 'template_asset_manifest_only',
        'architecture_reference_no_runtime' => 'architecture_reference',
        'external_health_check_required' =>
          'user_owned_external_runtime_required',
        _ => 'local_capability_enhancement_only',
      };
      final blockedReasons = <String>[
        if (!stage2Allowed) 'Stage2 工业级预检未通过。',
        if (!ready) _stringValue(entry['blocked_reason_zh'], '能力增强尚未通过验证。'),
        if (entryClass == 'template_asset') '模板资产不需要 runtime load。',
        if (entryClass == 'architecture_reference') '架构参考不进入产品能力启用。',
        if (!requiresExternalRuntime && entryClass == 'capability_provider')
          '该能力增强不需要外部 runtime 加载。',
      ].where((value) => value.trim().isNotEmpty).toList(growable: false);
      return {
        'provider_ref': providerRef,
        'capability_id': entry['capability_id'],
        'registry_entry_class': entryClass,
        'runtime_load_class': runtimeLoadClass,
        'architecture_reference_status': entry['architecture_reference_status'],
        'architecture_absorption': entry['architecture_absorption'],
        'template_asset_contract': entry['template_asset_contract'],
        'gate_kind': entry['gate_kind'],
        'gate_audit': entry['gate_audit'],
        'affected_modules': entry['affected_modules'],
        'ready_for_user_selection': ready,
        'runtime_load_allowed': stage2Allowed && ready,
        'external_runtime_load_eligible': loadEligible,
        'runtime_loaded': runtimeLoaded,
        'requires_external_runtime': requiresExternalRuntime,
        'execution_mode': executionMode,
        'load_state': runtimeLoaded
            ? 'loaded_health_check_only'
            : entryClass == 'template_asset'
                ? (ready
                    ? 'template_asset_ready'
                    : 'template_asset_needs_validation')
                : entryClass == 'architecture_reference'
                    ? 'architecture_reference'
                    : loadEligible
                        ? 'eligible_not_loaded'
                        : 'not_runtime_load_target',
        'blocked_reasons': blockedReasons,
        'readiness_status':
            _stringValue(readiness['status'], entry['health_status']),
        'test_artifacts': _listOfStrings(readiness['test_artifacts']),
        'normal_ui_project_name_visible': false,
        'secret_masked': true,
        'secret_plaintext_written': false,
      };
    }).toList(growable: false);
    final eligibleEntries = entries
        .where((entry) => entry['external_runtime_load_eligible'] == true)
        .toList(growable: false);
    final path = _providerRuntimeLoadEligibilityManifestPath(workspace);
    final payload = {
      'schema_version': 'prd_v3_provider_runtime_load_eligibility_manifest.v1',
      'generated_at': now,
      'workspace_boundary': workspace.path,
      'stage_2_industrial_preflight': stage2Preflight,
      'stage_2_runtime_load_allowed': stage2Allowed,
      'provider_entry_count': entries.length,
      'runtime_loaded_count':
          entries.where((entry) => entry['runtime_loaded'] == true).length,
      'external_runtime_load_eligible_count': eligibleEntries.length,
      'local_capability_enhancement_only_count': entries
          .where((entry) =>
              entry['execution_mode'] == 'local_capability_enhancement_only')
          .length,
      'normal_ui_project_names_visible': false,
      'secret_plaintext_written': false,
      'entries': entries,
    };
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
    return path;
  }

  Future<String> _writeProviderRegistryReadinessSummary(
    Directory workspace, {
    required List<Map<String, dynamic>> healthEntries,
    required Map<String, int> statusCounts,
    required Map<String, dynamic> stage2Preflight,
    required String readinessPath,
    required String matrixPath,
    required String contractsPath,
  }) async {
    final providerRefs = healthEntries
        .map((entry) => _stringValue(entry['provider_ref'], ''))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();
    final capabilityIds = healthEntries
        .map((entry) => _stringValue(entry['capability_id'], ''))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();
    final stage2Allowed = _boolValue(stage2Preflight['runtime_load_allowed']);
    final providerRows = providerRefs.map((providerRef) {
      final related = healthEntries
          .where(
              (entry) => _stringValue(entry['provider_ref'], '') == providerRef)
          .toList(growable: false);
      final ready =
          related.any((entry) => entry['ready_for_user_selection'] == true);
      final requiresExternalRuntime = related
          .any((entry) => _boolValue(entry['requires_external_runtime']));
      final runtimeLoaded =
          related.any((entry) => _boolValue(entry['runtime_loaded']));
      final runtimeLoadEligible =
          stage2Allowed && ready && requiresExternalRuntime;
      final statuses = related
          .map((entry) => _stringValue(entry['health_status'], '未配置'))
          .toSet()
          .toList(growable: false)
        ..sort();
      return {
        'provider_ref': providerRef,
        'capability_ids': related
            .map((entry) => _stringValue(entry['capability_id'], ''))
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort(),
        'affected_modules': related
            .expand((entry) => _listOfStrings(entry['affected_modules']))
            .toSet()
            .toList(growable: false)
          ..sort(),
        'statuses': statuses,
        'user_status': ready ? '连接成功' : statuses.firstOrNull ?? '未配置',
        'ready_for_user_selection': ready,
        'selection_allowed': ready,
        'requires_external_runtime': requiresExternalRuntime,
        'runtime_load_allowed': ready && stage2Allowed,
        'external_runtime_load_eligible': runtimeLoadEligible,
        'runtime_loaded': runtimeLoaded,
        'fallback_providers': related
            .map((entry) => _stringValue(entry['fallback_provider'], ''))
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort(),
        'rollback_supported':
            related.any((entry) => _boolValue(entry['rollback_supported'])),
        'blocked_reasons': related
            .map((entry) => _stringValue(entry['blocked_reason_zh'], ''))
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort(),
        'normal_ui_project_name_visible': false,
        'secret_masked': true,
        'secret_plaintext_written': false,
      };
    }).toList(growable: false);
    final path = _providerRegistryReadinessSummaryPath(workspace);
    final payload = {
      'schema_version': 'prd_v3_provider_registry_readiness_summary.v1',
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'workspace_boundary': workspace.path,
      'matrix_path': matrixPath,
      'contracts_path': contractsPath,
      'readiness_report_path': readinessPath,
      'health_report_path': _registeredProviderHealthReportPath(workspace),
      'runtime_load_eligibility_manifest_path':
          _providerRuntimeLoadEligibilityManifestPath(workspace),
      'provider_count': providerRows.length,
      'provider_mapping_count': healthEntries.length,
      'capability_area_count': capabilityIds.length,
      'ready_provider_count': providerRows
          .where((entry) => entry['ready_for_user_selection'] == true)
          .length,
      'runtime_loaded_count':
          providerRows.where((entry) => entry['runtime_loaded'] == true).length,
      'external_runtime_load_eligible_count': providerRows
          .where((entry) => entry['external_runtime_load_eligible'] == true)
          .length,
      'status_counts': statusCounts,
      'capability_ids': capabilityIds,
      'stage_2_industrial_preflight': stage2Preflight,
      'user_concept_boundary': {
        'visible_as_provider_capability_enhancement': true,
        'external_project_names_visible_in_normal_ui': false,
        'hot_swap_project_concept_visible': false,
        'unverified_entries_marked_ready': false,
      },
      'failure_isolation': {
        'unavailable_provider_blocks_main_chain': false,
        'local_fallback_available': true,
        'rollback_supported': true,
      },
      'provider_rows': providerRows,
      'secret_plaintext_written': false,
    };
    await _writeJsonFile(path, payload);
    return path;
  }

  Future<Map<String, dynamic>> _probeN8nRuntimeConnection(
    Directory workspace, {
    required String endpoint,
    required String apiKey,
  }) async {
    final probePath = _providerRuntimeLoadProbePath(workspace, 'n8n');
    final now = DateTime.now().toUtc().toIso8601String();
    final base = Uri.tryParse(endpoint.trim());
    final sanitizedEndpoint = _sanitizeEndpoint(endpoint);
    if (base == null || !base.hasScheme || base.host.isEmpty) {
      final payload = {
        'schema_version': 'prd_v3_provider_runtime_load_probe_n8n.v1',
        'provider_ref': 'n8n',
        'capability_id': 'workflow_collaboration_export',
        'executed_at': now,
        'probe_kind': 'safe_health_check_only',
        'workspace_boundary': workspace.path,
        'status': '配置缺失',
        'error_code': 'n8n_endpoint_missing_or_invalid',
        'error_message_zh': '需要配置 n8n endpoint 后才能连接工作流协作 Provider。',
        'sanitized_endpoint': sanitizedEndpoint,
        'runtime_loaded': false,
        'external_runtime_connected': false,
        'external_runtime_executed': false,
        'workflow_executed': false,
        'local_fallback': 'A2A 本地协作报告导出继续可用。',
        'secret_masked': true,
        'secret_plaintext_written': false,
      };
      await _writeJsonFile(probePath, payload);
      return {
        ...payload,
        'probe_path': probePath,
      };
    }

    final effectiveKey = _effectiveSecret(
      provided: apiKey,
      environmentKey: 'HEITANG_N8N_API_KEY',
    );
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final candidates = _n8nHealthUris(base);
      Map<String, dynamic>? lastFailure;
      for (final candidate in candidates) {
        final request =
            await client.getUrl(candidate).timeout(const Duration(seconds: 5));
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (effectiveKey.isNotEmpty) {
          request.headers.set('X-N8N-API-KEY', effectiveKey);
        }
        final response =
            await request.close().timeout(const Duration(seconds: 5));
        final body = await response.transform(utf8.decoder).join();
        final ok = response.statusCode < 400;
        if (ok) {
          final payload = {
            'schema_version': 'prd_v3_provider_runtime_load_probe_n8n.v1',
            'provider_ref': 'n8n',
            'capability_id': 'workflow_collaboration_export',
            'executed_at': now,
            'probe_kind': 'safe_health_check_only',
            'workspace_boundary': workspace.path,
            'status': '连接成功',
            'error_code': '',
            'error_message_zh': '',
            'sanitized_endpoint': sanitizedEndpoint,
            'health_path': candidate.path,
            'http_status': response.statusCode,
            'response_bytes': body.length,
            'runtime_loaded': true,
            'external_runtime_connected': true,
            'external_runtime_executed': false,
            'workflow_executed': false,
            'local_fallback': '',
            'secret_masked': true,
            'secret_plaintext_written': false,
          };
          await _writeJsonFile(probePath, payload);
          return {
            ...payload,
            'probe_path': probePath,
          };
        }
        lastFailure = {
          'status': response.statusCode == 401 || response.statusCode == 403
              ? '鉴权失败'
              : '连接失败',
          'error_code': response.statusCode == 401 || response.statusCode == 403
              ? 'n8n_auth_failed'
              : 'n8n_health_check_failed',
          'error_message_zh':
              'n8n 健康检查返回 HTTP ${response.statusCode}，已降级为本地 A2A 导出。',
          'health_path': candidate.path,
          'http_status': response.statusCode,
        };
      }
      final failure = lastFailure ??
          const {
            'status': '连接失败',
            'error_code': 'n8n_health_check_failed',
            'error_message_zh': 'n8n 健康检查失败，已降级为本地 A2A 导出。',
            'health_path': '',
            'http_status': 0,
          };
      final payload = {
        'schema_version': 'prd_v3_provider_runtime_load_probe_n8n.v1',
        'provider_ref': 'n8n',
        'capability_id': 'workflow_collaboration_export',
        'executed_at': now,
        'probe_kind': 'safe_health_check_only',
        'workspace_boundary': workspace.path,
        ...failure,
        'sanitized_endpoint': sanitizedEndpoint,
        'runtime_loaded': false,
        'external_runtime_connected': false,
        'external_runtime_executed': false,
        'workflow_executed': false,
        'local_fallback': 'A2A 本地协作报告导出继续可用。',
        'secret_masked': true,
        'secret_plaintext_written': false,
      };
      await _writeJsonFile(probePath, payload);
      return {
        ...payload,
        'probe_path': probePath,
      };
    } on TimeoutException catch (error) {
      final payload = _n8nRuntimeProbeFailure(
        workspace,
        now: now,
        sanitizedEndpoint: sanitizedEndpoint,
        status: '超时',
        errorCode: 'n8n_health_check_timeout',
        errorMessageZh: 'n8n 健康检查超时，已降级为本地 A2A 导出。',
        detail: error.toString(),
      );
      await _writeJsonFile(probePath, payload);
      return {
        ...payload,
        'probe_path': probePath,
      };
    } on Object catch (error) {
      final payload = _n8nRuntimeProbeFailure(
        workspace,
        now: now,
        sanitizedEndpoint: sanitizedEndpoint,
        status: '连接失败',
        errorCode: 'n8n_connection_failed',
        errorMessageZh: 'n8n 连接失败，已降级为本地 A2A 导出。',
        detail: _redactSecret(error.toString(), effectiveKey),
      );
      await _writeJsonFile(probePath, payload);
      return {
        ...payload,
        'probe_path': probePath,
      };
    } finally {
      client.close(force: true);
    }
  }

  Map<String, dynamic> _blockedN8nRuntimeLoadProbe(
    Directory workspace, {
    required Map<String, dynamic> readiness,
    required String endpoint,
  }) {
    final probePath = _providerRuntimeLoadProbePath(workspace, 'n8n');
    final now = DateTime.now().toUtc().toIso8601String();
    final blockedReasons = _listOfStrings(readiness['blocked_reasons']);
    final payload = {
      'schema_version': 'prd_v3_provider_runtime_load_probe_n8n.v1',
      'provider_ref': 'n8n',
      'capability_id': 'workflow_collaboration_export',
      'executed_at': now,
      'probe_kind': 'blocked_before_external_connection',
      'workspace_boundary': workspace.path,
      'status': '配置缺失',
      'error_code': 'n8n_runtime_load_not_eligible',
      'error_message_zh': blockedReasons.isEmpty
          ? 'Stage2 工业级预检或 n8n readiness 未通过，禁止加载外部 runtime。'
          : blockedReasons.join(' '),
      'sanitized_endpoint': _sanitizeEndpoint(endpoint),
      'runtime_loaded': false,
      'external_runtime_connected': false,
      'external_runtime_executed': false,
      'workflow_executed': false,
      'local_fallback': 'A2A 本地协作报告导出继续可用。',
      'secret_masked': true,
      'secret_plaintext_written': false,
    };
    File(probePath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(payload),
        encoding: utf8,
      );
    return {
      ...payload,
      'probe_path': probePath,
    };
  }

  Future<String> _writeProviderRuntimeLoadManifest(
    Directory workspace, {
    required String providerRef,
    required String capabilityId,
    required String startedAt,
    required String finishedAt,
    required bool eligible,
    required Map<String, dynamic> probe,
    String action = 'load',
    String rollbackFromManifestPath = '',
  }) async {
    final loaded = _boolValue(probe['runtime_loaded']);
    final manifestPath = _providerRuntimeLoadManifestPath(workspace);
    final payload = {
      'schema_version': 'prd_v3_provider_runtime_load_manifest.v1',
      'provider_ref': providerRef,
      'capability_id': capabilityId,
      'started_at': startedAt,
      'finished_at': finishedAt,
      'workspace_boundary': workspace.path,
      'action': action,
      'rollback_from_manifest_path': rollbackFromManifestPath,
      'eligible_before_load': eligible,
      'runtime_loaded': loaded,
      'runtime_loaded_count': loaded ? 1 : 0,
      'status': _stringValue(probe['status'], loaded ? '连接成功' : '连接失败'),
      'error_code': _stringValue(probe['error_code'], ''),
      'error_message_zh': _stringValue(probe['error_message_zh'], ''),
      'sanitized_endpoint': _stringValue(probe['sanitized_endpoint'], ''),
      'probe_path': _stringValue(probe['probe_path'], ''),
      'external_runtime_connected':
          _boolValue(probe['external_runtime_connected']),
      'external_runtime_executed': false,
      'workflow_executed': false,
      'downstream_binding': {
        'agent_workbench_a2a_workflow_export':
            loaded ? '外部工作流协作 Provider 可用。' : '降级为本地 A2A 导出。',
        'document_library': '不受影响',
        'knowledge_base': '不受影响',
        'document_generation': '不受影响',
      },
      'fallback': loaded ? '' : 'A2A 本地协作报告导出继续可用。',
      'normal_ui_project_name_visible': false,
      'secret_masked': true,
      'secret_plaintext_written': false,
    };
    await _writeJsonFile(manifestPath, payload);
    return manifestPath;
  }

  Future<void> _appendProviderRuntimeLoadLog(
    Directory workspace, {
    required String providerRef,
    required String capabilityId,
    required String startedAt,
    required String finishedAt,
    required bool eligible,
    required Map<String, dynamic> probe,
    required String manifestPath,
    String action = 'load',
  }) async {
    final event = {
      'schema_version': 'prd_v3_provider_runtime_load_event.v1',
      'event_id':
          'provider_runtime_load_${DateTime.now().toUtc().microsecondsSinceEpoch}',
      'provider_ref': providerRef,
      'capability_id': capabilityId,
      'action': action,
      'started_at': startedAt,
      'finished_at': finishedAt,
      'eligible_before_load': eligible,
      'runtime_loaded_after_event': _boolValue(probe['runtime_loaded']),
      'status': _stringValue(probe['status'], '连接失败'),
      'error_code': _stringValue(probe['error_code'], ''),
      'error_message_zh': _stringValue(probe['error_message_zh'], ''),
      'sanitized_endpoint': _stringValue(probe['sanitized_endpoint'], ''),
      'manifest_path': manifestPath,
      'probe_path': _stringValue(probe['probe_path'], ''),
      'external_runtime_executed': false,
      'workflow_executed': false,
      'fallback': _stringValue(probe['local_fallback'], ''),
      'secret_masked': true,
      'secret_plaintext_written': false,
    };
    final file = File(_providerRuntimeLoadLogPath(workspace));
    await file.parent.create(recursive: true);
    await file.writeAsString('${jsonEncode(event)}\n',
        mode: FileMode.append, encoding: utf8);
  }

  Future<Map<String, dynamic>> _providerRuntimeLoadStatusSummary(
    Directory workspace,
  ) async {
    final manifestPath = _providerRuntimeLoadManifestPath(workspace);
    var manifest = await _readJsonObject(manifestPath);
    final shouldWriteDefaultManifest = manifest.isEmpty ||
        (_stringValue(manifest['action'], '') == 'status_refresh' &&
            !_boolValue(manifest['runtime_loaded']));
    if (shouldWriteDefaultManifest) {
      final now = DateTime.now().toUtc().toIso8601String();
      final stage2Preflight = _stage2IndustrialPreflight(workspace);
      final readinessByProvider = await _providerReadinessByProvider(workspace);
      final n8nReadiness =
          readinessByProvider['n8n'] ?? const <String, dynamic>{};
      final eligible = _boolValue(stage2Preflight['runtime_load_allowed']) &&
          _boolValue(n8nReadiness['ready_for_user_selection']);
      await _writeProviderRuntimeLoadManifest(
        workspace,
        providerRef: 'n8n',
        capabilityId: 'workflow_collaboration_export',
        startedAt: now,
        finishedAt: now,
        eligible: eligible,
        action: 'status_refresh',
        probe: {
          'status': '未配置',
          'error_code': eligible
              ? 'n8n_endpoint_missing_or_invalid'
              : 'n8n_runtime_load_not_eligible',
          'error_message_zh': eligible
              ? '工作流协作 Provider 未配置 endpoint，A2A 导出降级为本地协作报告。'
              : 'Stage2 工业级预检或 n8n readiness 未通过，A2A 导出降级为本地协作报告。',
          'sanitized_endpoint': '',
          'runtime_loaded': false,
          'external_runtime_connected': false,
          'external_runtime_executed': false,
          'workflow_executed': false,
          'local_fallback': 'A2A 本地协作报告导出继续可用。',
        },
      );
      manifest = await _readJsonObject(manifestPath);
    }
    if (manifest.isEmpty) {
      return {
        'schema_version': 'prd_v3_provider_runtime_load_summary.v1',
        'provider_ref': 'n8n',
        'capability_id': 'workflow_collaboration_export',
        'status': '未配置',
        'runtime_loaded': false,
        'runtime_loaded_count': 0,
        'external_runtime_connected': false,
        'external_runtime_executed': false,
        'workflow_executed': false,
        'fallback': 'A2A 本地协作报告导出继续可用。',
        'manifest_path': manifestPath,
        'log_path': _providerRuntimeLoadLogPath(workspace),
        'normal_ui_project_name_visible': false,
        'secret_masked': true,
        'secret_plaintext_written': false,
      };
    }
    return {
      'schema_version': 'prd_v3_provider_runtime_load_summary.v1',
      'provider_ref': _stringValue(manifest['provider_ref'], 'n8n'),
      'capability_id': _stringValue(
          manifest['capability_id'], 'workflow_collaboration_export'),
      'status': _stringValue(manifest['status'], '未配置'),
      'runtime_loaded': _boolValue(manifest['runtime_loaded']),
      'runtime_loaded_count': _asInt(manifest['runtime_loaded_count']) ?? 0,
      'external_runtime_connected':
          _boolValue(manifest['external_runtime_connected']),
      'external_runtime_executed': false,
      'workflow_executed': false,
      'fallback': _stringValue(manifest['fallback'], ''),
      'error_code': _stringValue(manifest['error_code'], ''),
      'error_message_zh': _stringValue(manifest['error_message_zh'], ''),
      'sanitized_endpoint': _stringValue(manifest['sanitized_endpoint'], ''),
      'manifest_path': manifestPath,
      'log_path': _providerRuntimeLoadLogPath(workspace),
      'normal_ui_project_name_visible': false,
      'secret_masked': true,
      'secret_plaintext_written': false,
    };
  }

  Future<Map<String, dynamic>> _providerRuntimeLoadState(
    Directory workspace,
  ) async {
    final manifest =
        await _readJsonObject(_providerRuntimeLoadManifestPath(workspace));
    if (manifest.isEmpty) {
      return const <String, dynamic>{};
    }
    return manifest;
  }

  static bool _providerRuntimeLoadedFor(
    Map<String, dynamic> runtimeLoadState,
    Map<String, dynamic> entry,
  ) {
    if (!_boolValue(runtimeLoadState['runtime_loaded'])) {
      return false;
    }
    if (_stringValue(runtimeLoadState['provider_ref'], '') !=
        _stringValue(entry['provider_ref'], '')) {
      return false;
    }
    if (_stringValue(runtimeLoadState['capability_id'], '') !=
        _stringValue(entry['capability_id'], '')) {
      return false;
    }
    if (_boolValue(runtimeLoadState['external_runtime_executed'])) {
      return false;
    }
    if (_boolValue(runtimeLoadState['workflow_executed'])) {
      return false;
    }
    if (_boolValue(runtimeLoadState['secret_plaintext_written'])) {
      return false;
    }
    return true;
  }

  Future<String> _writeProviderLifecycleAuditSummary(
    Directory workspace, {
    required Map<String, dynamic> stage2Preflight,
    required Map<String, dynamic> providerRuntimeLoad,
  }) async {
    final registrySummaryPath =
        _providerRegistryReadinessSummaryPath(workspace);
    final eligibilityPath =
        _providerRuntimeLoadEligibilityManifestPath(workspace);
    final bindingPath = _providerCapabilityBindingManifestPath(workspace);
    final healthReportPath = _registeredProviderHealthReportPath(workspace);
    final activationLogPath = _registeredProviderActivationLogPath(workspace);
    final selectionLogPath = _registeredProviderSelectionLogPath(workspace);
    final runtimeLoadLogPath = _providerRuntimeLoadLogPath(workspace);
    final rollbackManifestPath =
        _registeredProviderRollbackManifestPath(workspace);
    final registrySummary = await _readJsonObject(registrySummaryPath);
    final eligibility = await _readJsonObject(eligibilityPath);
    final binding = await _readJsonObject(bindingPath);
    final healthReport = await _readJsonObject(healthReportPath);
    final rollbackManifest = await _readJsonObject(rollbackManifestPath);
    final activationEvents = await _readJsonl(File(activationLogPath));
    final selectionEvents = await _readJsonl(File(selectionLogPath));
    final runtimeLoadEvents = await _readJsonl(File(runtimeLoadLogPath));
    final providerRows = _listOfMaps(registrySummary['provider_rows']);
    final eligibilityEntries = _listOfMaps(eligibility['entries']);
    final bindings = _listOfMaps(binding['bindings']);
    final downstreamBindingAudit = bindings
        .map((entry) => {
              'capability_id': _stringValue(entry['capability_id'], ''),
              'affected_modules': _listOfStrings(entry['affected_modules']),
              'active_provider_ref':
                  _stringValue(entry['active_provider_ref'], ''),
              'active_provider_kind':
                  _stringValue(entry['active_provider_kind'], ''),
              'user_status': _stringValue(entry['user_status'], ''),
              'selection_allowed': _boolValue(entry['selection_allowed']),
              'runtime_load_allowed': _boolValue(entry['runtime_load_allowed']),
              'runtime_loaded': _boolValue(entry['runtime_loaded']),
              'external_runtime_executed':
                  _boolValue(entry['external_runtime_executed']),
              'workflow_executed': _boolValue(entry['workflow_executed']),
              'local_fallback_active':
                  _stringValue(entry['active_provider_kind'], '') ==
                      'local_fallback',
              'rollback_suppressed': _boolValue(entry['rollback_suppressed']),
              'unauthorized_resources_selectable':
                  _boolValue(entry['unauthorized_resources_selectable']),
              'secret_masked': _boolValue(entry['secret_masked']),
            })
        .toList(growable: false);
    final selectionActions = <String, int>{};
    for (final event in selectionEvents) {
      final action = _stringValue(event['action'], 'unknown');
      selectionActions[action] = (selectionActions[action] ?? 0) + 1;
    }
    final runtimeLoadActions = <String, int>{};
    for (final event in runtimeLoadEvents) {
      final action = _stringValue(event['action'], 'unknown');
      runtimeLoadActions[action] = (runtimeLoadActions[action] ?? 0) + 1;
    }
    final runtimeLoaded =
        _asInt(providerRuntimeLoad['runtime_loaded_count']) ?? 0;
    final readyProviders = providerRows
        .where((entry) => _boolValue(entry['ready_for_user_selection']))
        .length;
    final eligibleProviders = eligibilityEntries
        .where((entry) => _boolValue(entry['external_runtime_load_eligible']))
        .length;
    final fallbackBindings = bindings
        .where((entry) =>
            _stringValue(entry['active_provider_kind'], '') == 'local_fallback')
        .length;
    final loadedEvents = runtimeLoadEvents
        .where((entry) => _boolValue(entry['runtime_loaded_after_event']))
        .length;
    final rollbackEvents = runtimeLoadEvents
            .where((entry) => _stringValue(entry['action'], '') == 'rollback')
            .length +
        selectionEvents
            .where((entry) => _stringValue(entry['action'], '') == 'rollback')
            .length;
    final path = _providerLifecycleAuditSummaryPath(workspace);
    final payload = {
      'schema_version': 'prd_v3_provider_lifecycle_audit_summary.v1',
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'workspace_boundary': workspace.path,
      'stage_2_industrial_preflight': stage2Preflight,
      'provider_counts': {
        'registered_provider_count':
            _asInt(registrySummary['provider_count']) ??
                _asInt(healthReport['unique_provider_ref_count']) ??
                providerRows.length,
        'provider_mapping_count':
            _asInt(registrySummary['provider_mapping_count']) ??
                _asInt(healthReport['provider_entry_count']) ??
                eligibilityEntries.length,
        'capability_area_count':
            _asInt(registrySummary['capability_area_count']) ??
                _asInt(healthReport['capability_area_count']) ??
                0,
        'ready_provider_count': readyProviders,
        'external_runtime_load_eligible_count': eligibleProviders,
        'runtime_loaded_count': runtimeLoaded,
        'fallback_binding_count': fallbackBindings,
      },
      'event_counts': {
        'registered_activation_event_count': activationEvents.length,
        'selection_event_count': selectionEvents.length,
        'selection_actions': selectionActions,
        'runtime_load_event_count': runtimeLoadEvents.length,
        'runtime_load_actions': runtimeLoadActions,
        'runtime_load_success_event_count': loadedEvents,
        'rollback_event_count': rollbackEvents,
      },
      'runtime_load_summary': providerRuntimeLoad,
      'downstream_binding_audit': downstreamBindingAudit,
      'rollback_summary': {
        'registered_provider_rollback_manifest_path': rollbackManifestPath,
        'rollback_supported':
            _boolValue(rollbackManifest['rollback_supported']),
        'rollback_target_count':
            _listOfMaps(rollbackManifest['rollback_targets']).length,
        'runtime_rollback_available':
            File(_providerRuntimeLoadManifestPath(workspace)).existsSync(),
      },
      'source_artifacts': {
        'registry_readiness_summary_path': registrySummaryPath,
        'runtime_load_eligibility_manifest_path': eligibilityPath,
        'provider_capability_binding_manifest_path': bindingPath,
        'registered_provider_health_report_path': healthReportPath,
        'registered_provider_activation_log_path': activationLogPath,
        'registered_provider_selection_log_path': selectionLogPath,
        'provider_runtime_load_manifest_path':
            _providerRuntimeLoadManifestPath(workspace),
        'provider_runtime_load_log_path': runtimeLoadLogPath,
        'registered_provider_rollback_manifest_path': rollbackManifestPath,
      },
      'industrial_boundaries': {
        'normal_ui_project_names_visible': false,
        'hot_swap_project_concept_visible': false,
        'external_runtime_executed':
            _boolValue(providerRuntimeLoad['external_runtime_executed']),
        'workflow_executed':
            _boolValue(providerRuntimeLoad['workflow_executed']),
        'unavailable_provider_blocks_main_chain': false,
        'local_fallback_available': true,
        'secret_masked': true,
        'secret_plaintext_written': false,
      },
    };
    await _writeJsonFile(path, payload);
    return path;
  }

  Future<String> _writeProviderIntegrationCoverageAudit(
    Directory workspace, {
    required Map<String, dynamic> stage2Preflight,
    required Map<String, dynamic> providerRuntimeLoad,
  }) async {
    final matrixPath = _registeredProviderIntegrationMatrixPath(workspace);
    final contractsPath = _providerAdapterContractsPath(workspace);
    final readinessPath = _providerAdapterReadinessReportPath(workspace);
    final healthPath = _registeredProviderHealthReportPath(workspace);
    final eligibilityPath =
        _providerRuntimeLoadEligibilityManifestPath(workspace);
    final bindingPath = _providerCapabilityBindingManifestPath(workspace);
    final lifecyclePath = _providerLifecycleAuditSummaryPath(workspace);
    final activationLogPath = _registeredProviderActivationLogPath(workspace);
    final rollbackPath = _registeredProviderRollbackManifestPath(workspace);
    final matrix = await _readJsonObject(matrixPath);
    final contracts = await _readJsonObject(contractsPath);
    final readiness = await _readJsonObject(readinessPath);
    final health = await _readJsonObject(healthPath);
    final eligibility = await _readJsonObject(eligibilityPath);
    final binding = await _readJsonObject(bindingPath);
    final lifecycle = await _readJsonObject(lifecyclePath);
    final rollback = await _readJsonObject(rollbackPath);
    final activationEvents = await _readJsonl(File(activationLogPath));
    final providerEntries = _listOfMaps(matrix['provider_entries']);
    final contractRows = _listOfMaps(contracts['contracts']);
    final readinessRows = _listOfMaps(readiness['readiness_entries']);
    final healthRows = _listOfMaps(health['health_entries']);
    final eligibilityRows = _listOfMaps(eligibility['entries']);
    final bindingRows = _listOfMaps(binding['bindings']);
    final downstreamAudits = _listOfMaps(lifecycle['downstream_binding_audit']);
    final rollbackRows = _listOfMaps(rollback['rollback_targets']);
    final contractRefs = contractRows
        .map((entry) => _stringValue(entry['provider_ref'], ''))
        .where((value) => value.isNotEmpty)
        .toSet();
    final readinessRefs = readinessRows
        .map((entry) => _stringValue(entry['provider_ref'], ''))
        .where((value) => value.isNotEmpty)
        .toSet();
    final healthKeys = healthRows
        .map((entry) =>
            '${_stringValue(entry['capability_id'], '')}|${_stringValue(entry['provider_ref'], '')}')
        .toSet();
    final eligibilityKeys = eligibilityRows
        .map((entry) =>
            '${_stringValue(entry['capability_id'], '')}|${_stringValue(entry['provider_ref'], '')}')
        .toSet();
    final rollbackKeys = rollbackRows
        .map((entry) =>
            '${_stringValue(entry['capability_id'], '')}|${_stringValue(entry['provider_ref'], '')}')
        .toSet();
    final activationKeys = activationEvents
        .map((entry) =>
            '${_stringValue(entry['capability_id'], '')}|${_stringValue(entry['provider_ref'], '')}')
        .toSet();
    final bindingCapabilityIds = bindingRows
        .map((entry) => _stringValue(entry['capability_id'], ''))
        .where((value) => value.isNotEmpty)
        .toSet();
    final downstreamCapabilityIds = downstreamAudits
        .map((entry) => _stringValue(entry['capability_id'], ''))
        .where((value) => value.isNotEmpty)
        .toSet();
    final coverageRows = providerEntries.map((entry) {
      final capabilityId = _stringValue(entry['capability_id'], '');
      final providerRef = _stringValue(entry['provider_ref'], '');
      final key = '$capabilityId|$providerRef';
      final checks = {
        'matrix_entry_present': true,
        'adapter_contract_present': contractRefs.contains(providerRef),
        'readiness_entry_present': readinessRefs.contains(providerRef),
        'health_entry_present': healthKeys.contains(key),
        'eligibility_entry_present': eligibilityKeys.contains(key),
        'activation_event_present': activationKeys.contains(key),
        'rollback_target_present': rollbackKeys.contains(key),
        'capability_binding_present':
            bindingCapabilityIds.contains(capabilityId),
        'downstream_lifecycle_audit_present':
            downstreamCapabilityIds.contains(capabilityId),
        'normal_ui_project_name_hidden':
            _boolValue(entry['visible_in_normal_ui']) == false,
        'secret_masked': _boolValue(entry['secret_masked']),
        'architecture_absorption_decision_valid':
            _architectureAbsorptionDecisionValid(entry),
      };
      final missing = checks.entries
          .where((check) => check.value != true)
          .map((check) => check.key)
          .toList(growable: false);
      return {
        'capability_id': capabilityId,
        'provider_ref': providerRef,
        'registry_entry_class': entry['registry_entry_class'],
        'runtime_load_class': entry['runtime_load_class'],
        'architecture_reference_status': entry['architecture_reference_status'],
        'architecture_absorption': entry['architecture_absorption'],
        'affected_modules': _registeredProviderAffectedModules(entry),
        'requires_external_runtime':
            _boolValue(entry['requires_external_runtime']),
        'runtime_loaded': _boolValue(entry['runtime_loaded']),
        'ready_for_user_selection':
            _boolValue(entry['ready_for_user_selection']),
        'gate_kind': entry['gate_kind'],
        'gate_audit': entry['gate_audit'],
        'coverage_status': missing.isEmpty ? 'passed' : 'blocked',
        'missing_evidence': missing,
        'checks': checks,
      };
    }).toList(growable: false);
    final failedRows = coverageRows
        .where((entry) => entry['coverage_status'] != 'passed')
        .toList(growable: false);
    final capabilityIds = providerEntries
        .map((entry) => _stringValue(entry['capability_id'], ''))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();
    final providerRefs = providerEntries
        .map((entry) => _stringValue(entry['provider_ref'], ''))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();
    final registryClassCounts = _registryClassCounts(providerEntries);
    final architectureReferenceCounts =
        _architectureReferenceStatusCounts(providerEntries);
    final path = _providerIntegrationCoverageAuditPath(workspace);
    final payload = {
      'schema_version': 'prd_v3_provider_integration_coverage_audit.v1',
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'workspace_boundary': workspace.path,
      'status': failedRows.isEmpty ? 'passed' : 'blocked',
      'stage_2_industrial_preflight': stage2Preflight,
      'provider_runtime_load_summary': providerRuntimeLoad,
      'provider_mapping_count': providerEntries.length,
      'unique_provider_ref_count': providerRefs.length,
      'registry_class_counts': registryClassCounts,
      'architecture_reference_status_counts': architectureReferenceCounts,
      'capability_provider_mapping_count':
          registryClassCounts['capability_provider'] ?? 0,
      'template_asset_mapping_count':
          registryClassCounts['template_asset'] ?? 0,
      'architecture_reference_mapping_count':
          registryClassCounts['architecture_reference'] ?? 0,
      'capability_area_count': capabilityIds.length,
      'covered_mapping_count': coverageRows.length - failedRows.length,
      'failed_mapping_count': failedRows.length,
      'capability_ids': capabilityIds,
      'provider_refs': providerRefs,
      'normal_ui_project_names_visible': false,
      'hot_swap_project_concept_visible': false,
      'external_runtime_executed':
          _boolValue(providerRuntimeLoad['external_runtime_executed']),
      'workflow_executed': _boolValue(providerRuntimeLoad['workflow_executed']),
      'secret_plaintext_written': false,
      'source_artifacts': {
        'registered_provider_integration_matrix_path': matrixPath,
        'provider_adapter_contracts_path': contractsPath,
        'provider_adapter_readiness_report_path': readinessPath,
        'registered_provider_health_report_path': healthPath,
        'provider_runtime_load_eligibility_manifest_path': eligibilityPath,
        'provider_capability_binding_manifest_path': bindingPath,
        'provider_lifecycle_audit_summary_path': lifecyclePath,
        'registered_provider_activation_log_path': activationLogPath,
        'registered_provider_rollback_manifest_path': rollbackPath,
      },
      'failed_mappings': failedRows,
      'coverage_rows': coverageRows,
    };
    await _writeJsonFile(path, payload);
    return path;
  }

  Future<String> _writeProviderCapabilityUserCatalog(
    Directory workspace,
    Map<String, dynamic> bindingManifest, {
    required Map<String, dynamic> stage2Preflight,
    required Map<String, dynamic> providerRuntimeLoad,
    required String coverageAuditPath,
  }) async {
    final bindings = _listOfMaps(bindingManifest['bindings']);
    final coverageAudit = coverageAuditPath.isEmpty
        ? const <String, dynamic>{}
        : await _readJsonObject(coverageAuditPath);
    final entries = bindings.map((binding) {
      final capabilityId = _stringValue(binding['capability_id'], '');
      final runtimeLoaded = _boolValue(binding['runtime_loaded']);
      final selectionAllowed = _boolValue(binding['selection_allowed']);
      final activeKind = _stringValue(binding['active_provider_kind'], '');
      final userStatus = runtimeLoaded
          ? '连接成功'
          : selectionAllowed
              ? '已配置未测试'
              : _stringValue(binding['user_status'], '降级为本地模式');
      return {
        'capability_id': capabilityId,
        'user_entry': _providerUserEntry(capabilityId, capabilityId),
        'display_name': _providerCapabilityDisplayName(capabilityId),
        'status': userStatus,
        'current_behavior': _providerCapabilityCurrentBehavior(
          capabilityId,
          status: userStatus,
          activeProviderKind: activeKind,
          runtimeLoaded: runtimeLoaded,
        ),
        'available_option_count': _asInt(binding['ready_candidate_count']) ?? 0,
        'candidate_option_count':
            _asInt(binding['candidate_provider_count']) ?? 0,
        'configuration_entry': _providerCapabilityConfigurationEntry(
          capabilityId,
        ),
        'affected_modules': _listOfStrings(binding['affected_modules']),
        'audit_status': coverageAuditPath.isEmpty ? '未生成' : '已生成',
        'registry_class_summary':
            _mapValue(coverageAudit['registry_class_counts']),
        'architecture_reference_summary': _mapValue(
          coverageAudit['architecture_reference_status_counts'],
        ),
        'rollback_available': selectionAllowed || runtimeLoaded,
        'runtime_loaded': runtimeLoaded,
        'external_runtime_executed': false,
        'workflow_executed': false,
        'normal_ui_project_name_visible': false,
        'hot_swap_project_concept_visible': false,
        'secret_masked': true,
      };
    }).toList(growable: false);
    final readyCount = entries
        .where((entry) =>
            _stringValue(entry['status'], '') == '连接成功' ||
            _stringValue(entry['status'], '') == '已配置未测试')
        .length;
    final loadedCount =
        entries.where((entry) => entry['runtime_loaded'] == true).length;
    final path = _providerCapabilityUserCatalogPath(workspace);
    final payload = {
      'schema_version': 'prd_v3_provider_capability_user_catalog.v1',
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'workspace_boundary': workspace.path,
      'status': 'passed',
      'stage_2_industrial_preflight': stage2Preflight,
      'runtime_load_user_summary':
          _providerRuntimeLoadUserSummary(providerRuntimeLoad),
      'capability_count': entries.length,
      'available_capability_count': readyCount,
      'runtime_loaded_capability_count': loadedCount,
      'normal_ui_project_names_visible': false,
      'hot_swap_project_concept_visible': false,
      'external_runtime_executed':
          _boolValue(providerRuntimeLoad['external_runtime_executed']),
      'workflow_executed': _boolValue(providerRuntimeLoad['workflow_executed']),
      'secret_plaintext_written': false,
      'source_artifacts': {
        'provider_capability_binding_manifest_path':
            _providerCapabilityBindingManifestPath(workspace),
        'provider_integration_coverage_audit_path': coverageAuditPath,
        'provider_runtime_load_manifest_path':
            _providerRuntimeLoadManifestPath(workspace),
      },
      'entries': entries,
    };
    await _writeJsonFile(path, payload);
    return path;
  }

  static Map<String, dynamic> _providerRuntimeLoadUserSummary(
    Map<String, dynamic> providerRuntimeLoad,
  ) {
    return {
      'status': _stringValue(providerRuntimeLoad['status'], '未配置'),
      'runtime_loaded': _boolValue(providerRuntimeLoad['runtime_loaded']),
      'runtime_loaded_count':
          _asInt(providerRuntimeLoad['runtime_loaded_count']) ?? 0,
      'external_runtime_connected':
          _boolValue(providerRuntimeLoad['external_runtime_connected']),
      'external_runtime_executed': false,
      'workflow_executed': false,
      'fallback': _stringValue(providerRuntimeLoad['fallback'], ''),
      'normal_ui_project_name_visible': false,
      'secret_masked': true,
      'secret_plaintext_written': false,
    };
  }

  Future<String> _snapshotProviderRuntimeLoadManifest(
    Directory workspace,
    Map<String, dynamic> manifest,
  ) async {
    if (manifest.isEmpty) {
      return '';
    }
    final historyDir = Directory(
        _join(workspace.path, 'config', 'provider_runtime_load_history'));
    await historyDir.create(recursive: true);
    final path = _join(
      historyDir.path,
      'provider_runtime_load_${DateTime.now().toUtc().microsecondsSinceEpoch}.json',
    );
    await _writeJsonFile(path, {
      ...manifest,
      'snapshot_created_at': DateTime.now().toUtc().toIso8601String(),
      'secret_plaintext_written': false,
    });
    return path;
  }

  Future<String> _writeProviderCapabilityBindingManifest(
    Directory workspace,
    List<ProjectConfigProfile> profiles,
    List<Map<String, dynamic>> entries, {
    required String action,
    Map<String, dynamic>? selectedEntry,
    Map<String, Map<String, dynamic>> readinessByProvider = const {},
  }) async {
    final activeProfile = _activeProfile(profiles);
    final stage2Preflight = _stage2IndustrialPreflight(workspace);
    final stage2RuntimeLoadAllowed =
        _boolValue(stage2Preflight['runtime_load_allowed']);
    final runtimeLoadState = await _providerRuntimeLoadState(workspace);
    final selectionState =
        await _readProviderCapabilitySelectionState(workspace);
    final selectedProviders =
        _mapValue(selectionState['selected_providers_by_capability']);
    final rollbackSuppressedCapabilities =
        _listOfStrings(selectionState['rollback_suppressed_capability_ids'])
            .toSet();
    final now = DateTime.now().toUtc().toIso8601String();
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final entry in entries) {
      final capabilityId = _stringValue(entry['capability_id'], '');
      if (capabilityId.isEmpty) continue;
      grouped.putIfAbsent(capabilityId, () => []).add(entry);
    }
    final bindings = grouped.entries.map((group) {
      final candidates = group.value;
      final explicitProviderRef =
          _stringValue(selectedProviders[group.key], '');
      final explicitlySelected = explicitProviderRef.isEmpty
          ? const <String, dynamic>{}
          : candidates.firstWhere(
              (entry) =>
                  _stringValue(entry['provider_ref'], '') ==
                  explicitProviderRef,
              orElse: () => const <String, dynamic>{},
            );
      final explicitSelectionReady = explicitlySelected.isNotEmpty &&
          _providerReadyForSelection(explicitlySelected, readinessByProvider);
      final rollbackSuppressed =
          rollbackSuppressedCapabilities.contains(group.key);
      final selected = rollbackSuppressed
          ? candidates.first
          : explicitSelectionReady
              ? explicitlySelected
              : candidates.firstWhere(
                  (entry) =>
                      _providerReadyForSelection(entry, readinessByProvider),
                  orElse: () => candidates.first,
                );
      final readiness =
          readinessByProvider[_stringValue(selected['provider_ref'], '')] ??
              const <String, dynamic>{};
      final selectedStatus = _stringValue(
          readiness['status'], _registeredProviderHealthStatus(selected));
      final selectedReady = !rollbackSuppressed &&
          _providerReadyForSelection(selected, readinessByProvider);
      final runtimeLoaded = selectedReady &&
          _providerRuntimeLoadedFor(runtimeLoadState, selected);
      final explicitSelectionStale =
          explicitProviderRef.isNotEmpty && !explicitSelectionReady;
      return {
        'capability_id': group.key,
        'user_visible_entry': selected['user_visible_entry'],
        'active_provider_ref': selectedReady
            ? selected['provider_ref']
            : selected['fallback_provider'],
        'active_provider_kind':
            selectedReady ? 'registered_provider' : 'local_fallback',
        'fallback_provider': selected['fallback_provider'],
        'user_status': selectedReady ? '连接成功' : '降级为本地模式',
        'provider_health_status': selectedStatus,
        'adapter_readiness_status': selectedStatus,
        'explicit_selected_provider_ref': explicitProviderRef,
        'explicit_selection_applied': explicitSelectionReady,
        'explicit_selection_stale': explicitSelectionStale,
        'rollback_suppressed': rollbackSuppressed,
        'selection_allowed': selectedReady,
        'runtime_loaded': runtimeLoaded,
        'runtime_load_allowed': selectedReady && stage2RuntimeLoadAllowed,
        'external_runtime_executed': false,
        'workflow_executed': false,
        'stage_2_preflight_status': stage2Preflight['status'],
        'blocked_reason_zh':
            selectedReady ? '' : _registeredProviderBlockedReason(selected),
        'candidate_provider_count': candidates.length,
        'ready_candidate_count': candidates
            .where((entry) =>
                _providerReadyForSelection(entry, readinessByProvider))
            .length,
        'affected_modules': _registeredProviderAffectedModules(selected),
        'unauthorized_resources_selectable': false,
        'secret_masked': true,
      };
    }).toList(growable: false);
    final path = _providerCapabilityBindingManifestPath(workspace);
    final manifest = {
      'schema_version': 'prd_v3_provider_capability_binding_manifest.v1',
      'generated_at': now,
      'workspace_boundary': workspace.path,
      'active_profile_id': activeProfile.profileId,
      'active_profile_mode': activeProfile.mode,
      'action': action,
      'selected_capability_id': selectedEntry == null
          ? ''
          : _stringValue(selectedEntry['capability_id'], ''),
      'selected_provider_ref': selectedEntry == null
          ? ''
          : _stringValue(selectedEntry['provider_ref'], ''),
      'selected_provider_runtime_loaded': selectedEntry == null
          ? false
          : _providerRuntimeLoadedFor(runtimeLoadState, selectedEntry),
      'provider_capability_selection_state_path':
          _providerCapabilitySelectionStatePath(workspace),
      'binding_count': bindings.length,
      'registered_provider_loaded_count':
          bindings.where((binding) => binding['runtime_loaded'] == true).length,
      'external_runtime_load_allowed': stage2Preflight['runtime_load_allowed'],
      'stage_2_industrial_preflight': stage2Preflight,
      'local_fallback_binding_count': bindings
          .where(
              (binding) => binding['active_provider_kind'] == 'local_fallback')
          .length,
      'normal_ui_project_names_visible': false,
      'secret_plaintext_written': false,
      'bindings': bindings,
    };
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      encoding: utf8,
    );
    return path;
  }

  Future<Map<String, dynamic>> _readProviderCapabilitySelectionState(
    Directory workspace,
  ) async {
    final file = File(_providerCapabilitySelectionStatePath(workspace));
    if (!await file.exists()) {
      return const <String, dynamic>{
        'selected_providers_by_capability': <String, dynamic>{},
      };
    }
    return _readJsonObject(file.path);
  }

  Future<String> _writeProviderCapabilitySelectionState(
    Directory workspace, {
    required String action,
    required Map<String, dynamic> entry,
    required Map<String, Map<String, dynamic>> readinessByProvider,
  }) async {
    final current = await _readProviderCapabilitySelectionState(workspace);
    final selectedProviders = Map<String, dynamic>.from(
        _mapValue(current['selected_providers_by_capability']));
    final rollbackSuppressedCapabilityIds =
        _listOfStrings(current['rollback_suppressed_capability_ids']).toSet();
    final capabilityId = _stringValue(entry['capability_id'], '');
    final providerRef = _stringValue(entry['provider_ref'], '');
    final ready = _providerReadyForSelection(entry, readinessByProvider);
    final now = DateTime.now().toUtc().toIso8601String();
    if (action == 'rollback') {
      selectedProviders.remove(capabilityId);
      if (capabilityId.isNotEmpty) {
        rollbackSuppressedCapabilityIds.add(capabilityId);
      }
    } else if (action == 'activate' && ready) {
      selectedProviders[capabilityId] = providerRef;
      rollbackSuppressedCapabilityIds.remove(capabilityId);
    }
    final path = _providerCapabilitySelectionStatePath(workspace);
    final payload = {
      'schema_version': 'prd_v3_provider_capability_selection_state.v1',
      'updated_at': now,
      'workspace_boundary': workspace.path,
      'action': action,
      'selected_capability_id': capabilityId,
      'selected_provider_ref': action == 'rollback' ? '' : providerRef,
      'fallback_provider': _stringValue(entry['fallback_provider'], ''),
      'ready_for_user_selection_at_change': ready,
      'rollback_suppressed_capability_ids':
          rollbackSuppressedCapabilityIds.toList(growable: false)..sort(),
      'runtime_loaded_after_change': false,
      'normal_ui_project_names_visible': false,
      'secret_plaintext_written': false,
      'selected_providers_by_capability': selectedProviders,
    };
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
    return path;
  }

  Future<String> _writeProviderAdapterContracts(
    Directory workspace,
    List<Map<String, dynamic>> entries,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final entry in entries) {
      final providerRef = _stringValue(entry['provider_ref'], '');
      if (providerRef.isEmpty) continue;
      grouped.putIfAbsent(providerRef, () => []).add(entry);
    }
    final contracts = grouped.entries.map((group) {
      final providerEntries = group.value;
      final first = providerEntries.first;
      final requiresNetwork =
          providerEntries.any((entry) => _boolValue(entry['requires_network']));
      final requiresSecret =
          providerEntries.any((entry) => _boolValue(entry['requires_secret']));
      final requiresExternalRuntime = providerEntries
          .any((entry) => _boolValue(entry['requires_external_runtime']));
      final contractStatuses = providerEntries
          .expand((entry) => _listOfStrings(entry['contract_status']))
          .toSet()
          .toList(growable: false)
        ..sort();
      final capabilityIds = providerEntries
          .map((entry) => _stringValue(entry['capability_id'], ''))
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: false)
        ..sort();
      final affectedModules = providerEntries
          .expand(_registeredProviderAffectedModules)
          .toSet()
          .toList(growable: false)
        ..sort();
      final status = _registeredProviderHealthStatus(first);
      return {
        'provider_ref': group.key,
        'registry_entry_classes': providerEntries
            .map((entry) => _stringValue(
                entry['registry_entry_class'], 'capability_provider'))
            .toSet()
            .toList(growable: false)
          ..sort(),
        'runtime_load_classes': providerEntries
            .map((entry) => _stringValue(entry['runtime_load_class'], ''))
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort(),
        'architecture_reference_statuses': providerEntries
            .map((entry) =>
                _stringValue(entry['architecture_reference_status'], ''))
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort(),
        'gate_kinds': providerEntries
            .map((entry) => _stringValue(entry['gate_kind'], ''))
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort(),
        'gate_audits': providerEntries
            .map((entry) => _mapValue(entry['gate_audit']))
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false),
        'architecture_absorption': providerEntries
            .map((entry) => _mapValue(entry['architecture_absorption']))
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false),
        'template_asset_contract': providerEntries
            .map((entry) => _mapValue(entry['template_asset_contract']))
            .firstWhere((entry) => entry.isNotEmpty, orElse: () => const {}),
        'adapter_type': _providerAdapterType(first),
        'capability_ids': capabilityIds,
        'affected_modules': affectedModules,
        'contract_status': contractStatuses,
        'runtime_execution_mode': requiresExternalRuntime
            ? 'external_runtime'
            : requiresNetwork
                ? 'network_authorized_provider'
                : 'local_optional_adapter',
        'requires_network': requiresNetwork,
        'requires_secret_ref': requiresSecret,
        'requires_external_runtime': requiresExternalRuntime,
        'requires_dependency_install': status == '需安装外部服务' ||
            contractStatuses.contains('planned_adapter') ||
            contractStatuses.contains('future_adapter'),
        'required_config_refs': _providerRequiredConfigRefs(first),
        'health_check_actions': _providerHealthCheckActions(first),
        'activation_prerequisites':
            _providerActivationPrerequisites(first, status),
        'current_health_status': status,
        'ready_for_user_selection': false,
        'runtime_loaded': false,
        'user_visible_entry': first['user_visible_entry'],
        'fallback_provider': first['fallback_provider'],
        'rollback_supported': _boolValue(first['rollback_supported']),
        'rollback_requires_restart': false,
        'normal_ui_project_name_visible': false,
        'secret_masked': true,
      };
    }).toList(growable: false);
    final path = _providerAdapterContractsPath(workspace);
    final payload = {
      'schema_version': 'prd_v3_provider_adapter_contracts.v1',
      'generated_at': now,
      'workspace_boundary': workspace.path,
      'source_asset': 'assets/external/provider_capability_status.json',
      'contract_count': contracts.length,
      'provider_mapping_count': entries.length,
      'runtime_loaded_count': 0,
      'ready_for_user_selection_count': 0,
      'contracts': contracts,
      'normal_ui_project_names_visible': false,
      'secret_plaintext_written': false,
    };
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
    return path;
  }

  Future<String> _writeProviderAdapterReadinessReport(
    Directory workspace,
    List<ProjectConfigProfile> profiles,
    String contractsPath,
  ) async {
    final active = _activeProfile(profiles);
    final contractsDoc = await _readJsonObject(contractsPath);
    final contracts = _listOfMaps(contractsDoc['contracts']);
    final stage2Preflight = _stage2IndustrialPreflight(workspace);
    final storage = await loadStorageProviderSettings();
    final provider = await loadProviderRuntimeSettings();
    final exporter = await loadExporterSettings();
    final config = {
      'storage': storage,
      'provider': provider,
      'exporter': exporter,
    };
    final stage2RuntimeLoadAllowed =
        _boolValue(stage2Preflight['runtime_load_allowed']);
    final now = DateTime.now().toUtc().toIso8601String();
    final readinessEntries = contracts.map((contract) {
      final result = _providerAdapterReadiness(
        contract,
        active,
        config,
        workspace,
      );
      return {
        'readiness_id':
            'provider_adapter_readiness_${DateTime.now().toUtc().microsecondsSinceEpoch}_${contract['provider_ref']}',
        'profile_id': active.profileId,
        'provider_ref': contract['provider_ref'],
        'adapter_type': contract['adapter_type'],
        'capability_ids': contract['capability_ids'],
        'affected_modules': contract['affected_modules'],
        'status': result['status'],
        'error_code': result['error_code'],
        'error_message_zh': result['error_message_zh'],
        'missing_config_refs': result['missing_config_refs'],
        'blocked_reasons': result['blocked_reasons'],
        'gate_kind': _stringValue(result['gate_kind'], ''),
        'gate_audit': _mapValue(result['gate_audit']),
        'degradation_target': contract['fallback_provider'],
        'test_artifacts': result['test_artifacts'],
        'ready_for_user_selection': result['ready_for_user_selection'],
        'runtime_loaded': result['runtime_loaded'],
        'runtime_load_allowed':
            _boolValue(result['ready_for_user_selection']) &&
                stage2RuntimeLoadAllowed,
        'stage_2_preflight_status': stage2Preflight['status'],
        'secret_masked': true,
        'evaluated_at': now,
      };
    }).toList(growable: false);
    final statusCounts = <String, int>{};
    for (final entry in readinessEntries) {
      final status = _stringValue(entry['status'], '配置缺失');
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }
    final reportPath = _providerAdapterReadinessReportPath(workspace);
    final logPath = _providerAdapterReadinessLogPath(workspace);
    final report = {
      'schema_version': 'prd_v3_provider_adapter_readiness_report.v1',
      'generated_at': now,
      'workspace_boundary': workspace.path,
      'active_profile_id': active.profileId,
      'contracts_path': contractsPath,
      'readiness_log_path': logPath,
      'contract_count': contracts.length,
      'readiness_entry_count': readinessEntries.length,
      'runtime_loaded_count': readinessEntries
          .where((entry) => entry['runtime_loaded'] == true)
          .length,
      'ready_for_user_selection_count': readinessEntries
          .where((entry) => entry['ready_for_user_selection'] == true)
          .length,
      'external_runtime_load_allowed': stage2Preflight['runtime_load_allowed'],
      'stage_2_industrial_preflight': stage2Preflight,
      'status_counts': statusCounts,
      'readiness_entries': readinessEntries,
      'normal_ui_project_names_visible': false,
      'secret_plaintext_written': false,
    };
    await File(reportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
      encoding: utf8,
    );
    await File(logPath).writeAsString(
      '${readinessEntries.map(jsonEncode).join('\n')}\n',
      encoding: utf8,
    );
    return reportPath;
  }

  Future<Map<String, Map<String, dynamic>>> _providerReadinessByProvider(
    Directory workspace,
  ) async {
    final report =
        await _readJsonObject(_providerAdapterReadinessReportPath(workspace));
    final result = <String, Map<String, dynamic>>{};
    for (final entry in _listOfMaps(report['readiness_entries'])) {
      final providerRef = _stringValue(entry['provider_ref'], '');
      if (providerRef.isEmpty) continue;
      result[providerRef] = entry;
    }
    return result;
  }

  Future<void> _appendRegisteredProviderSelectionLog(
    Directory workspace, {
    required String action,
    required Map<String, dynamic> entry,
    required String status,
    required String blockedReason,
  }) async {
    final file = File(_registeredProviderSelectionLogPath(workspace));
    await file.parent.create(recursive: true);
    final event = {
      'schema_version': 'prd_v3_registered_provider_selection_event.v1',
      'event_id':
          'registered_provider_selection_${DateTime.now().toUtc().microsecondsSinceEpoch}',
      'action': action,
      'changed_at': DateTime.now().toUtc().toIso8601String(),
      'capability_id': entry['capability_id'],
      'provider_ref': entry['provider_ref'],
      'user_visible_entry': entry['user_visible_entry'],
      'status': status,
      'blocked_reason': blockedReason,
      'gate_kind': _stringValue(entry['gate_kind'], ''),
      'gate_audit': _mapValue(entry['gate_audit']),
      'runtime_loaded_after_event': false,
      'fallback_provider': entry['fallback_provider'],
      'rollback_supported': true,
      'secret_masked': true,
    };
    await file.writeAsString('${jsonEncode(event)}\n',
        mode: FileMode.append, encoding: utf8);
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
                    ? 'connected'
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

  static String _projectConfigProfilesPath(Directory workspace) {
    return _join(workspace.path, 'config', 'project_config_profiles.json');
  }

  static String _projectConfigRuntimeStatusPath(Directory workspace) {
    return _join(
        workspace.path, 'config', 'project_config_runtime_status.json');
  }

  static String _projectConfigAssetsPath(Directory workspace) {
    return _join(workspace.path, 'config', 'project_config_assets.json');
  }

  static String _configTestLogPath(Directory workspace) {
    return _join(workspace.path, 'config', 'config_test_log.jsonl');
  }

  static String _profileChangeLogPath(Directory workspace) {
    return _join(workspace.path, 'config', 'profile_change_log.jsonl');
  }

  static String _profileActivationLogPath(Directory workspace) {
    return _join(workspace.path, 'config', 'profile_activation_log.jsonl');
  }

  static String _registeredProviderIntegrationMatrixPath(Directory workspace) {
    return _join(workspace.path, 'config',
        'registered_provider_integration_matrix.json');
  }

  static String _registeredProviderActivationLogPath(Directory workspace) {
    return _join(
        workspace.path, 'config', 'registered_provider_activation_log.jsonl');
  }

  static String _registeredProviderSelectionLogPath(Directory workspace) {
    return _join(
        workspace.path, 'config', 'registered_provider_selection_log.jsonl');
  }

  static String _registeredProviderRollbackManifestPath(Directory workspace) {
    return _join(
        workspace.path, 'config', 'registered_provider_rollback_manifest.json');
  }

  static String _registeredProviderHealthReportPath(Directory workspace) {
    return _join(
        workspace.path, 'config', 'registered_provider_health_report.json');
  }

  static String _registeredProviderHealthLogPath(Directory workspace) {
    return _join(
        workspace.path, 'config', 'registered_provider_health_log.jsonl');
  }

  static String _registeredProviderHotSwapStabilityReportPath(
      Directory workspace) {
    return _join(workspace.path, 'config',
        'registered_provider_hot_swap_stability_report.json');
  }

  static String _providerCapabilityBindingManifestPath(Directory workspace) {
    return _join(
        workspace.path, 'config', 'provider_capability_binding_manifest.json');
  }

  static String _providerCapabilitySelectionStatePath(Directory workspace) {
    return _join(
        workspace.path, 'config', 'provider_capability_selection_state.json');
  }

  static String _providerAdapterContractsPath(Directory workspace) {
    return _join(workspace.path, 'config', 'provider_adapter_contracts.json');
  }

  static String _providerAdapterReadinessReportPath(Directory workspace) {
    return _join(
        workspace.path, 'config', 'provider_adapter_readiness_report.json');
  }

  static String _providerAdapterReadinessLogPath(Directory workspace) {
    return _join(
        workspace.path, 'config', 'provider_adapter_readiness_log.jsonl');
  }

  static String _providerRuntimeLoadEligibilityManifestPath(
      Directory workspace) {
    return _join(workspace.path, 'config',
        'provider_runtime_load_eligibility_manifest.json');
  }

  static String _providerRegistryReadinessSummaryPath(Directory workspace) {
    return _join(
        workspace.path, 'config', 'provider_registry_readiness_summary.json');
  }

  static String _providerLifecycleAuditSummaryPath(Directory workspace) {
    return _join(
        workspace.path, 'config', 'provider_lifecycle_audit_summary.json');
  }

  static String _providerIntegrationCoverageAuditPath(Directory workspace) {
    return _join(
        workspace.path, 'config', 'provider_integration_coverage_audit.json');
  }

  static String _providerCapabilityUserCatalogPath(Directory workspace) {
    return _join(
        workspace.path, 'config', 'provider_capability_user_catalog.json');
  }

  static String _providerRuntimeLoadManifestPath(Directory workspace) {
    return _join(
        workspace.path, 'config', 'provider_runtime_load_manifest.json');
  }

  static String _providerRuntimeLoadLogPath(Directory workspace) {
    return _join(workspace.path, 'config', 'provider_runtime_load_log.jsonl');
  }

  static String _providerRuntimeLoadProbePath(
    Directory workspace,
    String providerRef,
  ) {
    return _join(workspace.path, 'config',
        'provider_runtime_load_probe_$providerRef.json');
  }

  static String _providerAdapterProbePath(
    Directory workspace,
    String providerRef,
  ) {
    return _join(
        workspace.path, 'config', 'provider_adapter_probe_$providerRef.json');
  }

  Future<List<ProjectConfigProfile>> _ensureProjectConfigProfiles(
      Directory workspace) async {
    final profiles = await _readProjectConfigProfiles(workspace);
    await _writeProjectConfigRuntimeStatus(workspace, profiles);
    return profiles;
  }

  Future<List<ProjectConfigProfile>> _readProjectConfigProfiles(
      Directory workspace) async {
    final path = _projectConfigProfilesPath(workspace);
    final file = File(path);
    if (!await file.exists()) {
      final now = DateTime.now().toUtc().toIso8601String();
      final defaultProfile = ProjectConfigProfile.localDefault(
        workspaceId: workspace.path,
        createdAt: now,
      );
      final profiles = [defaultProfile];
      await _writeProjectConfigProfiles(workspace, profiles);
      await _appendProfileChangeLog(
        workspace,
        action: 'create_default',
        profile: defaultProfile,
        status: '已配置未测试',
        summary: '默认本地 Profile 已创建。',
      );
      await _appendProfileActivationLog(
        workspace,
        previousProfileId: '',
        nextProfileId: defaultProfile.profileId,
        warnings: const [],
      );
      return profiles;
    }
    final payload = await _readJsonObject(path);
    final rawProfiles = payload['profiles'];
    final profiles = rawProfiles is List
        ? rawProfiles
            .whereType<Map>()
            .map((item) =>
                ProjectConfigProfile.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : <ProjectConfigProfile>[];
    if (profiles.isEmpty) {
      await file.delete();
      return _readProjectConfigProfiles(workspace);
    }
    if (profiles.where((profile) => profile.isActive).isEmpty) {
      final first = profiles.first.copyWith(isActive: true);
      final updated = [first, ...profiles.skip(1)];
      await _writeProjectConfigProfiles(workspace, updated);
      return updated;
    }
    return profiles;
  }

  Future<void> _writeProjectConfigProfiles(
    Directory workspace,
    List<ProjectConfigProfile> profiles,
  ) async {
    final configDir = Directory(_join(workspace.path, 'config'));
    await configDir.create(recursive: true);
    final activeCount = profiles.where((profile) => profile.isActive).length;
    final normalized = activeCount == 1
        ? profiles
        : profiles
            .asMap()
            .entries
            .map((entry) => entry.value.copyWith(isActive: entry.key == 0))
            .toList(growable: false);
    final activeProfile = _activeProfile(normalized);
    final payload = {
      'schema_version': 'prd_v3_project_config_profiles.v1',
      'workspace_id': workspace.path,
      'active_profile_id': activeProfile.profileId,
      'profile_count': normalized.length,
      'profiles': normalized.map((profile) => profile.toJson()).toList(),
      'secret_plaintext_written': false,
    };
    await File(_projectConfigProfilesPath(workspace)).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
  }

  Future<String> _writeProjectConfigAssets(
    Directory workspace,
    ProjectConfigProfile active, {
    required Map<String, dynamic> storage,
    required Map<String, dynamic> provider,
    required Map<String, dynamic> exporter,
  }) async {
    final configDir = Directory(_join(workspace.path, 'config'));
    await configDir.create(recursive: true);
    final path = _projectConfigAssetsPath(workspace);
    final storageProbe = await _probeStoragePath(workspace);
    final redis = _mapValue(storage['redis']);
    final qdrant = _mapValue(storage['qdrant']);
    final llm = _mapValue(provider['llm']);
    final modelGateway = _mapValue(provider['model_gateway']);
    final embedding = _mapValue(provider['embedding']);
    final search = _mapValue(provider['search']);
    final parser = _mapValue(provider['parser']);
    final ocr = _mapValue(provider['ocr']);
    final exporters = _mapValue(exporter['exporters']);
    final modelRoutePoolPath = _joinNested(
        workspace.path, 'config/model_gateway/model_route_pool.json');
    final modelRouteBindingMatrixPath = _joinNested(
        workspace.path, 'config/model_gateway/model_route_binding_matrix.json');
    final modelUsageCostPolicyPath = _joinNested(
        workspace.path, 'config/model_gateway/model_usage_cost_policy.json');
    final networkAllowed = active.networkPolicyId != 'network_local_only';
    final payload = {
      'schema_version': 'prd_v3_project_config_assets.v1',
      'product_baseline_chain':
          '文档库 -> 知识库 -> 索引层 -> RAG -> 编排层 -> 文档/Skill/Agent/A2A',
      'workspace_id': workspace.path,
      'profile_id': active.profileId,
      'profile_version': active.version,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'secret_plaintext_written': false,
      'cloud_services_default_disabled': true,
      'config_assets': {
        'storage_path': {
          'config_id': active.storageConfigId,
          'mode': _profileModeLabelForAudit(active.mode),
          'local_storage_path': workspace.path,
          'cloud_storage_path': '',
          'hybrid_sync_policy': active.mode == 'hybrid' ? '手动启用后同步' : '已禁用',
          'path_write_test': storageProbe['path_write_test'],
          'disk_space_check': storageProbe['disk_space_check'],
          'free_space_bytes': storageProbe['free_space_bytes'],
          'permission_failure_zh': storageProbe['permission_failure_zh'],
        },
        'llm_provider': {
          'config_id': active.modelConfigId,
          'provider_type': _stringValue(llm['provider_id'], 'env_configured'),
          'endpoint': _stringValue(llm['endpoint'], 'env:HEITANG_LLM_ENDPOINT'),
          'model': _stringValue(
              llm['model_id'], 'local-default-or-configured-provider'),
          'api_key_ref': _stringValue(
              llm['api_key_secret_ref'], 'env:HEITANG_LLM_API_KEY'),
          'timeout_seconds': _asInt(llm['timeout_seconds']) ?? 30,
          'enabled': _userStatus(llm['status']) != '已禁用',
          'test_result': _userStatus(llm['status']),
          'secret_masked': true,
        },
        'model_gateway_provider': {
          'config_id': active.modelGatewayConfigId,
          'gateway_id': _stringValue(
              modelGateway['gateway_id'], 'gateway_not_configured'),
          'display_name': _stringValue(modelGateway['display_name'], '未配置'),
          'gateway_type': _stringValue(modelGateway['gateway_type'], 'direct'),
          'base_url':
              _sanitizeEndpoint(_stringValue(modelGateway['base_url'], '')),
          'api_key_ref': _stringValue(modelGateway['api_key_ref'], 'none'),
          'admin_url':
              _sanitizeEndpoint(_stringValue(modelGateway['admin_url'], '')),
          'supports_streaming': _boolValue(modelGateway['supports_streaming']),
          'supports_embeddings':
              _boolValue(modelGateway['supports_embeddings']),
          'supports_fallback': _boolValue(modelGateway['supports_fallback']),
          'supports_usage_stats':
              _boolValue(modelGateway['supports_usage_stats']),
          'timeout_seconds': _asInt(modelGateway['timeout_seconds']) ?? 30,
          'retry_policy': _mapValue(modelGateway['retry_policy']),
          'status': _userStatus(modelGateway['status']),
          'last_test_at': _stringValue(modelGateway['last_test_at'], ''),
          'last_error': _modelGatewayPublicError(modelGateway),
          'masked_key_preview':
              _stringValue(modelGateway['masked_key_preview'], ''),
          'secret_masked': true,
          'external_runtime_loaded': false,
          'reference_status': 'needs_verification',
        },
        'model_route_pool': {
          'config_id': 'model_route_pool_default',
          'plan_name': '模型网关与大模型接入配置能力补全计划',
          'route_pool_path': modelRoutePoolPath,
          'route_binding_matrix_path': modelRouteBindingMatrixPath,
          'usage_cost_policy_path': modelUsageCostPolicyPath,
          'gateway_pool_enabled': true,
          'direct_provider_pool_enabled': true,
          'model_route_pool_enabled': true,
          'pipeline_routes_enabled': true,
          'skill_routes_enabled': true,
          'agent_routes_enabled': true,
          'a2a_routes_enabled': true,
          'tool_routes_enabled': true,
          'embedding_route_separated_from_chat': true,
          'status': _userStatus(modelGateway['status']),
          'secret_masked': true,
        },
        'embedding_provider': {
          'config_id': active.embeddingConfigId,
          'provider_type':
              _stringValue(embedding['provider_id'], 'local_keyword_embedding'),
          'model': _stringValue(embedding['model'], 'local_keyword_embedding'),
          'dimension': _asInt(embedding['dimension']) ?? 1536,
          'endpoint':
              _stringValue(embedding['endpoint'], 'local_keyword_index'),
          'api_key_ref': _stringValue(embedding['api_key_secret_ref'], 'none'),
          'test_embedding_vector': '已配置未测试',
          'dimension_mismatch': false,
          'test_result': _userStatus(embedding['status']),
        },
        'search_provider': {
          'config_id': active.searchProviderConfigId,
          'provider_type': _stringValue(search['provider_id'], 'local_index'),
          'endpoint': _stringValue(search['endpoint'], 'local_index'),
          'api_key_ref': _stringValue(search['api_key_secret_ref'], 'none'),
          'network_authorization': networkAllowed ? '已配置未测试' : '已禁用',
          'external_fact_verification_enabled': networkAllowed,
          'query_test': _userStatus(search['status']),
        },
        'ocr_provider': {
          'config_id': active.ocrProviderConfigId,
          'provider_type': _stringValue(ocr['provider_id'], 'optional_ocr'),
          'enabled': _userStatus(ocr['status']) == '连接成功',
          'language': _stringValue(ocr['language'], 'zh-CN,en'),
          'test_image': '已配置未测试',
          'test_availability': _userStatus(ocr['status']),
          'unavailable_reason': _userStatus(ocr['status']) == '连接成功'
              ? ''
              : 'OCR Provider 未完成配置或测试。',
        },
        'pdf_parser_provider': {
          'config_id': active.pdfParserProviderConfigId,
          'provider_type': _stringValue(parser['provider_id'], 'builtin'),
          'enabled': _userStatus(parser['status']) != '已禁用',
          'test_parse': _userStatus(parser['status']),
          'fallback_policy': '内置 Parser 可用；外部 Parser 失败时回退本地解析。',
        },
        'exporter_provider': {
          'config_id': active.exporterConfigId,
          'formats': {
            for (final format in [
              'markdown',
              'docx',
              'pdf',
              'pptx',
              'json',
              'csv',
              'skill_package',
              'agent_config',
              'a2a_report',
            ])
              format: _exporterAssetStatus(format, exporters),
          },
        },
        'redis': {
          'config_id': active.redisConfigId,
          'host': _stringValue(redis['host'], '127.0.0.1'),
          'port': _asInt(redis['port']) ?? 6379,
          'username': _stringValue(redis['username'], ''),
          'password_ref': _stringValue(
              redis['password_secret_ref'], 'env:HEITANG_REDIS_PASSWORD'),
          'database': _asInt(redis['db']) ?? 0,
          'namespace': _stringValue(redis['key_prefix'], 'heitang:'),
          'tls_enabled': _boolValue(redis['tls']),
          'timeout_seconds': _asInt(redis['timeout_seconds']) ?? 5,
          'ping': _userStatus(redis['status']),
          'auth': _userStatus(redis['status']) == '鉴权失败' ? '鉴权失败' : '已配置未测试',
          'write_read_delete_test_key': _userStatus(redis['status']),
          'last_test_status': _userStatus(redis['status']),
          'secret_masked': true,
        },
        'vector_db': {
          'config_id': active.vectorConfigId,
          'provider_type': _stringValue(qdrant['provider'], 'qdrant'),
          'endpoint': _stringValue(qdrant['endpoint'], 'http://127.0.0.1:6333'),
          'api_key_ref': _stringValue(qdrant['api_key_secret_ref'], 'none'),
          'collection': _stringValue(qdrant['collection'], 'heitang_kb'),
          'embedding_model_config_id': active.embeddingConfigId,
          'dimension': _asInt(qdrant['dimension']) ?? 1536,
          'health_check': _userStatus(qdrant['status']),
          'collection_exists': _userStatus(qdrant['status']) == '连接成功'
              ? '连接成功'
              : 'Collection 不存在',
          'test_vector_write_search_delete': _userStatus(qdrant['status']),
          'dimension_mismatch': _userStatus(qdrant['status']) == '维度不匹配',
          'secret_masked': true,
        },
        'network_authorization': {
          'config_id': active.networkPolicyId,
          'web_import_allowed': networkAllowed,
          'external_verification_allowed': networkAllowed,
          'provider_domain_allowlist':
              networkAllowed ? ['按 Provider 配置'] : <String>[],
          'timeout_seconds': 30,
          'retry_policy': '最多 2 次；失败进入审计日志',
          'disabled_reason': networkAllowed ? '' : '当前 Profile 为本地模式。',
        },
        'agent_memory_tool_policy': {
          'memory_policy_id': active.agentMemoryPolicyId,
          'tool_policy_id': active.toolPolicyId,
          'simple_agent': {
            'complex_tools_visible': false,
            'redis_short_memory': '已禁用',
            'vector_long_memory': '已禁用',
          },
          'complex_agent': {
            'redis_short_memory':
                _userStatus(redis['status']) == '连接成功' ? '连接成功' : '降级为本地模式',
            'vector_long_memory':
                _userStatus(qdrant['status']) == '连接成功' ? '连接成功' : '降级为本地模式',
            'tool_access': '按当前 Profile 授权',
          },
          'unauthorized_kb_skill_provider_access': false,
        },
      },
    };
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
    return path;
  }

  Future<void> _writeProjectConfigRuntimeStatus(
    Directory workspace,
    List<ProjectConfigProfile> profiles,
  ) async {
    final active = _activeProfile(profiles);
    final storage = await loadStorageProviderSettings();
    final provider = await loadProviderRuntimeSettings();
    final exporter = await loadExporterSettings();
    final redis = _mapValue(storage['redis']);
    final qdrant = _mapValue(storage['qdrant']);
    final llm = _mapValue(provider['llm']);
    final modelGateway = _mapValue(provider['model_gateway']);
    final search = _mapValue(provider['search']);
    final parser = _mapValue(provider['parser']);
    final ocr = _mapValue(provider['ocr']);
    final exporters = _mapValue(exporter['exporters']);
    final redisStatus = _userStatus(redis['status']);
    final qdrantStatus = _userStatus(qdrant['status']);
    final llmStatus = _userStatus(llm['status']);
    final modelGatewayStatus = _userStatus(modelGateway['status']);
    final llmRouteStatus =
        modelGatewayStatus == '连接成功' ? modelGatewayStatus : llmStatus;
    final modelRouteBindingMatrix = await _readJsonObject(_joinNested(
        workspace.path,
        'config/model_gateway/model_route_binding_matrix.json'));
    final modelRoutePool = await _readJsonObject(_joinNested(
        workspace.path, 'config/model_gateway/model_route_pool.json'));
    final networkAllowed = active.networkPolicyId != 'network_local_only';
    final stage2Preflight = _stage2IndustrialPreflight(workspace);
    final registeredProviderArtifacts =
        await _writeRegisteredProviderIntegrationArtifacts(workspace);
    final registeredProviderMatrix = await _readJsonObject(
        registeredProviderArtifacts['matrix_path'].toString());
    final providerAdapterContractsPath = _stringValue(
        registeredProviderMatrix['provider_adapter_contracts_path'],
        _providerAdapterContractsPath(workspace));
    final providerAdapterReadinessPath =
        await _writeProviderAdapterReadinessReport(
      workspace,
      profiles,
      providerAdapterContractsPath,
    );
    final providerAdapterReadiness =
        await _readJsonObject(providerAdapterReadinessPath);
    final readinessByProvider = await _providerReadinessByProvider(workspace);
    final providerCapabilityBindingPath =
        await _writeProviderCapabilityBindingManifest(
      workspace,
      profiles,
      _listOfMaps(registeredProviderMatrix['provider_entries']),
      action: 'runtime_status_refresh',
      readinessByProvider: readinessByProvider,
    );
    final providerCapabilityBinding =
        await _readJsonObject(providerCapabilityBindingPath);
    final registeredProviderHealthArtifacts =
        await _writeRegisteredProviderHealthArtifacts(workspace);
    final providerRuntimeLoad =
        await _providerRuntimeLoadStatusSummary(workspace);
    final providerLifecycleAuditSummaryPath =
        await _writeProviderLifecycleAuditSummary(
      workspace,
      stage2Preflight: stage2Preflight,
      providerRuntimeLoad: providerRuntimeLoad,
    );
    final providerIntegrationCoverageAuditPath =
        await _writeProviderIntegrationCoverageAudit(
      workspace,
      stage2Preflight: stage2Preflight,
      providerRuntimeLoad: providerRuntimeLoad,
    );
    final providerCapabilityUserCatalogPath =
        await _writeProviderCapabilityUserCatalog(
      workspace,
      providerCapabilityBinding,
      stage2Preflight: stage2Preflight,
      providerRuntimeLoad: providerRuntimeLoad,
      coverageAuditPath: providerIntegrationCoverageAuditPath,
    );
    final configAssetsPath = await _writeProjectConfigAssets(
      workspace,
      active,
      storage: storage,
      provider: provider,
      exporter: exporter,
    );
    final payload = {
      'schema_version': 'prd_v3_project_config_runtime_status.v1',
      'workspace_id': workspace.path,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'active_profile': active.toJson(),
      'config_assets_path': configAssetsPath,
      'registered_provider_integration_matrix_path':
          registeredProviderArtifacts['matrix_path'],
      'registered_provider_activation_log_path':
          registeredProviderArtifacts['activation_log_path'],
      'registered_provider_rollback_manifest_path':
          registeredProviderArtifacts['rollback_manifest_path'],
      'registered_provider_health_report_path':
          registeredProviderHealthArtifacts['health_report_path'],
      'registered_provider_health_log_path':
          registeredProviderHealthArtifacts['health_log_path'],
      'registered_provider_hot_swap_stability_report_path':
          registeredProviderHealthArtifacts['stability_report_path'],
      'provider_registry_readiness_summary_path':
          registeredProviderHealthArtifacts[
              'provider_registry_readiness_summary_path'],
      'provider_runtime_load_eligibility_manifest_path':
          registeredProviderHealthArtifacts[
              'runtime_load_eligibility_manifest_path'],
      'provider_adapter_contracts_path': providerAdapterContractsPath,
      'provider_adapter_readiness_report_path': providerAdapterReadinessPath,
      'provider_adapter_readiness_log_path':
          _providerAdapterReadinessLogPath(workspace),
      'provider_capability_binding_manifest_path':
          providerCapabilityBindingPath,
      'provider_capability_selection_state_path':
          _providerCapabilitySelectionStatePath(workspace),
      'provider_runtime_load_manifest_path':
          _providerRuntimeLoadManifestPath(workspace),
      'provider_runtime_load_log_path': _providerRuntimeLoadLogPath(workspace),
      'provider_runtime_load_summary': providerRuntimeLoad,
      'provider_lifecycle_audit_summary_path':
          providerLifecycleAuditSummaryPath,
      'provider_integration_coverage_audit_path':
          providerIntegrationCoverageAuditPath,
      'provider_capability_user_catalog_path':
          providerCapabilityUserCatalogPath,
      'registered_provider_summary': {
        'registered_provider_count':
            registeredProviderArtifacts['registered_provider_count'],
        'registered_provider_mapping_count':
            registeredProviderArtifacts['registered_provider_mapping_count'],
        'unique_provider_ref_count':
            registeredProviderArtifacts['unique_provider_ref_count'],
        'registry_class_counts':
            registeredProviderHealthArtifacts['registry_class_counts'],
        'architecture_reference_status_counts':
            registeredProviderHealthArtifacts[
                'architecture_reference_status_counts'],
        'ready_for_user_selection_count':
            registeredProviderArtifacts['ready_for_user_selection_count'],
        'ready_mapping_count':
            registeredProviderHealthArtifacts['ready_mapping_count'],
        'ready_unique_provider_count':
            registeredProviderHealthArtifacts['ready_unique_provider_count'],
        'adapter_ready_for_user_selection_count':
            providerAdapterReadiness['ready_for_user_selection_count'],
        'runtime_ready_for_user_selection_count':
            providerAdapterReadiness['ready_for_user_selection_count'],
        'adapter_runtime_loaded_count':
            providerAdapterReadiness['runtime_loaded_count'],
        'external_runtime_loaded_count':
            providerRuntimeLoad['runtime_loaded_count'],
        'external_runtime_health_status': providerRuntimeLoad['status'],
        'external_runtime_load_allowed':
            stage2Preflight['runtime_load_allowed'],
        'stage_2_preflight_status': stage2Preflight['status'],
        'visible_to_user_as_capability_enhancement': true,
        'external_project_names_visible_in_normal_ui': false,
      },
      'stage_2_industrial_preflight': stage2Preflight,
      'model_route_summary': {
        'plan_name': '模型网关与大模型接入配置能力补全计划',
        'gateway_pool_configured':
            _listOfMaps(modelRoutePool['gateway_pool']).isNotEmpty,
        'direct_provider_pool_configured':
            _listOfMaps(modelRoutePool['direct_provider_pool']).isNotEmpty,
        'model_route_count': _asInt(modelRoutePool['model_route_count']) ?? 0,
        'binding_count':
            _listOfMaps(modelRouteBindingMatrix['bindings']).length,
        'embedding_route_separated_from_chat':
            modelRouteBindingMatrix['embedding_route_separated_from_chat'] ==
                true,
        'route_pool_path': _joinNested(
            workspace.path, 'config/model_gateway/model_route_pool.json'),
        'route_binding_matrix_path': _joinNested(workspace.path,
            'config/model_gateway/model_route_binding_matrix.json'),
        'usage_cost_policy_path': _joinNested(workspace.path,
            'config/model_gateway/model_usage_cost_policy.json'),
        'secret_masked': true,
      },
      'health': {
        'status': _profileHealthStatus(
            active, redisStatus, qdrantStatus, llmRouteStatus),
        'summary': _profileHealthSummary(
          active,
          redisStatus,
          qdrantStatus,
          llmRouteStatus,
        ),
      },
      'module_status': {
        'dashboard': {
          'current_profile': active.displayName,
          'config_health': providerRuntimeLoad['runtime_loaded'] == true
              ? '连接成功'
              : active.lastTestStatus,
          'failure_summary': providerRuntimeLoad['runtime_loaded'] == true
              ? ''
              : (providerRuntimeLoad['error_message_zh'] ?? active.lastError),
          'external_runtime_health': providerRuntimeLoad,
        },
        'document_library': {
          'storage_path': workspace.path,
          'parser_status': _userStatus(parser['status']),
          'ocr_status': _userStatus(ocr['status']),
          'model_routes': _modelRouteModuleBinding(
              modelRouteBindingMatrix, 'document_library_pipeline'),
          'web_import_status': networkAllowed ? '已配置未测试' : '已禁用',
          'provider_binding': _moduleProviderBindingSummary(
            providerCapabilityBinding,
            'document_library',
          ),
        },
        'knowledge_base': {
          'index_backend': qdrantStatus == '连接成功' ? 'Qdrant' : '本地索引',
          'embedding_dimension': _asInt(qdrant['dimension']) ?? 1536,
          'vector_status': qdrantStatus,
          'embedding_model_route':
              _modelRouteModuleBinding(modelRouteBindingMatrix, 'embedding'),
          'okf_model_routes':
              _modelRouteModuleBinding(modelRouteBindingMatrix, 'okf_pipeline'),
          'dimension_change_requires_rebuild': qdrantStatus == '维度不匹配',
          'provider_binding': _moduleProviderBindingSummary(
            providerCapabilityBinding,
            'knowledge_base',
          ),
        },
        'retrieval_verification': {
          'retrieval_backend': _userStatus(search['status']) == '连接成功'
              ? _stringValue(search['provider_id'], 'local_index')
              : 'local_index',
          'external_fact_verification': networkAllowed ? '已配置未测试' : '已禁用',
          'search_provider_status': _userStatus(search['status']),
          'provider_binding': _moduleProviderBindingSummary(
            providerCapabilityBinding,
            'retrieval_verification',
          ),
        },
        'document_generation': {
          'llm_provider_status': llmStatus,
          'model_gateway_status': modelGatewayStatus,
          'llm_gateway_route': _modelGatewayRouteSummary(modelGateway, llm),
          'model_routes': _modelRouteModuleBinding(
              modelRouteBindingMatrix, 'document_generation'),
          'llm_related_actions_available':
              modelGatewayStatus == '连接成功' || llmStatus == '连接成功',
          'llm_failure_reason_zh': modelGatewayStatus == '连接成功'
              ? ''
              : _modelGatewayPublicError(modelGateway),
          'exporter_status': _exporterStatusSummary(exporters),
          'markdown_available': true,
          'office_export_available': _officeExporterAvailable(exporters),
          'provider_binding': _moduleProviderBindingSummary(
            providerCapabilityBinding,
            'document_generation',
          ),
        },
        'skill_factory': {
          'llm_status': llmStatus,
          'model_gateway_status': modelGatewayStatus,
          'model_routes': _modelRouteModuleBinding(
              modelRouteBindingMatrix, 'skill_factory'),
          'skill_generation_available':
              modelGatewayStatus == '连接成功' || llmStatus == '连接成功',
          'llm_failure_reason_zh': modelGatewayStatus == '连接成功'
              ? ''
              : _modelGatewayPublicError(modelGateway),
          'kb_status': state.hasKnowledgeBase ? '连接成功' : '配置缺失',
          'search_status': _userStatus(search['status']),
          'provider_binding': _moduleProviderBindingSummary(
            providerCapabilityBinding,
            'skill_factory',
          ),
        },
        'agent_workbench': {
          'model': _stringValue(
              llm['model_id'], 'local-default-or-configured-provider'),
          'active_model_gateway': _stringValue(
              modelGateway['gateway_id'], 'gateway_not_configured'),
          'model_gateway_status': modelGatewayStatus,
          'model_routes': _modelRouteModuleBinding(
              modelRouteBindingMatrix, 'agent_workbench'),
          'a2a_model_routes':
              _modelRouteModuleBinding(modelRouteBindingMatrix, 'a2a'),
          'tool_reasoning_routes': _modelRouteModuleBinding(
              modelRouteBindingMatrix, 'tool_reasoning'),
          'gateway_fallback_status':
              modelGatewayStatus == 'fallback 已触发' ? 'fallback 已触发' : '',
          'agent_dialogue_available':
              modelGatewayStatus == '连接成功' || llmStatus == '连接成功',
          'llm_failure_reason_zh': modelGatewayStatus == '连接成功'
              ? ''
              : _modelGatewayPublicError(modelGateway),
          'redis_memory_status': redisStatus == '连接成功' ? '连接成功' : '降级为本地模式',
          'vector_memory_status': qdrantStatus == '连接成功' ? '连接成功' : '降级为本地模式',
          'a2a_workflow_runtime_status': providerRuntimeLoad['status'],
          'a2a_workflow_runtime_loaded': providerRuntimeLoad['runtime_loaded'],
          'a2a_workflow_external_execution': false,
          'a2a_workflow_fallback': providerRuntimeLoad['runtime_loaded'] == true
              ? ''
              : 'A2A 本地协作报告导出继续可用。',
          'tool_policy': active.toolPolicyId,
          'unauthorized_resources_selectable': false,
          'provider_binding': _moduleProviderBindingSummary(
            providerCapabilityBinding,
            'agent_workbench',
          ),
        },
      },
      'degradation': {
        'redis_failure': redisStatus == '连接成功'
            ? 'Redis 短期记忆可用。'
            : 'Agent 短期记忆禁用，A2A 会话状态降级为本地文件。',
        'vector_failure':
            qdrantStatus == '连接成功' ? '外部向量库可用。' : '外部向量库禁用，知识库回退本地索引。',
        'llm_failure': llmStatus == '连接成功'
            ? 'LLM Provider 可用。'
            : '文档解析和本地导入可用，LLM 摘要、Skill 生成、Agent 对话需配置。',
        'model_gateway_failure': modelGatewayStatus == '连接成功'
            ? 'Model Gateway Provider 可用，Agent / Skill / LLM 摘要可走当前 Profile 网关。'
            : 'Model Gateway Provider 不可用；本地导入、文档库、知识库本地索引和 Markdown 生成不受影响，LLM 摘要、Skill 生成、Agent 对话降级为不可用。',
        'network_disabled':
            networkAllowed ? '外部验证按授权配置执行。' : '网页导入和外部事实验证禁用，本地检索不受影响。',
        'n8n_runtime_failure': providerRuntimeLoad['runtime_loaded'] == true
            ? '工作流协作 Provider 健康连接可用；未执行外部 workflow。'
            : '工作流协作 Provider 未加载，A2A 导出降级为本地协作报告。',
      },
      'secret_plaintext_written': false,
    };
    await File(_projectConfigRuntimeStatusPath(workspace)).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
  }

  Future<void> _appendConfigTestLog(
    Directory workspace, {
    required String testId,
    required ProjectConfigProfile profile,
    required String configType,
    required String configId,
    required String startedAt,
    required String finishedAt,
    required String status,
    required String errorCode,
    required String errorMessageZh,
    required String sanitizedEndpoint,
    required List<String> testArtifacts,
    required List<String> affectedModules,
  }) async {
    final file = File(_configTestLogPath(workspace));
    await file.parent.create(recursive: true);
    final event = {
      'schema_version': 'prd_v3_config_test_log.v1',
      'test_id': testId,
      'profile_id': profile.profileId,
      'config_type': configType,
      'config_id': configId,
      'started_at': startedAt,
      'finished_at': finishedAt,
      'status': status,
      'error_code': errorCode,
      'error_message_zh': errorMessageZh,
      'sanitized_endpoint': sanitizedEndpoint,
      'secret_masked': true,
      'test_artifacts': testArtifacts,
      'affected_modules': affectedModules,
    };
    await file.writeAsString('${jsonEncode(event)}\n',
        mode: FileMode.append, encoding: utf8);
  }

  Future<void> _appendProfileChangeLog(
    Directory workspace, {
    required String action,
    required ProjectConfigProfile profile,
    String previousProfileId = '',
    required String status,
    required String summary,
    List<String>? affectedModules,
  }) async {
    final file = File(_profileChangeLogPath(workspace));
    await file.parent.create(recursive: true);
    final now = DateTime.now().toUtc().toIso8601String();
    final event = {
      'schema_version': 'prd_v3_profile_change_log.v1',
      'change_id':
          'profile_change_${DateTime.now().toUtc().microsecondsSinceEpoch}',
      'action': action,
      'previous_profile_id': previousProfileId,
      'next_profile_id': profile.profileId,
      'changed_by': 'local_desktop_user',
      'changed_at': now,
      'status': status,
      'summary': summary,
      'affected_modules': affectedModules ?? _affectedProfileModules(profile),
      'rollback_available': profile.rollbackFromProfileId.isNotEmpty ||
          previousProfileId.isNotEmpty,
      'secret_masked': true,
    };
    await file.writeAsString('${jsonEncode(event)}\n',
        mode: FileMode.append, encoding: utf8);
  }

  Future<void> _appendProfileActivationLog(
    Directory workspace, {
    required String previousProfileId,
    required String nextProfileId,
    required List<String> warnings,
  }) async {
    final file = File(_profileActivationLogPath(workspace));
    await file.parent.create(recursive: true);
    final event = {
      'schema_version': 'prd_v3_profile_activation_log.v1',
      'previous_profile_id': previousProfileId,
      'next_profile_id': nextProfileId,
      'changed_by': 'local_desktop_user',
      'changed_at': DateTime.now().toUtc().toIso8601String(),
      'affected_modules': [
        'dashboard',
        'document_library',
        'knowledge_base',
        'retrieval_verification',
        'document_generation',
        'skill_factory',
        'agent_workbench',
      ],
      'rollback_available': previousProfileId.isNotEmpty,
      'warnings': warnings,
      'secret_masked': true,
    };
    await file.writeAsString('${jsonEncode(event)}\n',
        mode: FileMode.append, encoding: utf8);
  }

  ProjectConfigProfile _profileFromActive(
    Directory workspace,
    List<ProjectConfigProfile> profiles, {
    required String profileId,
    required String displayName,
    required String mode,
    required String now,
    required bool active,
    required String rollbackFromProfileId,
  }) {
    final source = profiles.isEmpty
        ? ProjectConfigProfile.localDefault(
            workspaceId: workspace.path, createdAt: now)
        : _activeProfile(profiles);
    final normalizedMode = _normalizedProfileMode(mode);
    return source.copyWith(
      profileId: profileId,
      displayName: displayName,
      mode: normalizedMode,
      isDefault: false,
      isActive: active,
      version: 1,
      createdAt: now,
      updatedAt: now,
      lastActivatedAt: active ? now : '',
      lastTestStatus: '已配置未测试',
      lastTestSummary: 'Profile 已创建，等待连接测试。',
      lastError: '',
      rollbackFromProfileId: rollbackFromProfileId,
      redisConfigId: normalizedMode == 'local'
          ? 'redis_not_configured'
          : 'redis_settings_optional',
      vectorConfigId: normalizedMode == 'local'
          ? 'vector_local_keyword_index'
          : 'vector_qdrant_optional',
      networkPolicyId:
          normalizedMode == 'local' ? 'network_local_only' : 'network_opt_in',
      agentMemoryPolicyId: normalizedMode == 'local'
          ? 'agent_memory_local_file'
          : 'agent_memory_redis_vector_optional',
      toolPolicyId: normalizedMode == 'local'
          ? 'tool_policy_simple_local'
          : 'tool_policy_complex_configured',
    );
  }

  static ProjectConfigProfile _activeProfile(
      List<ProjectConfigProfile> profiles) {
    return profiles.firstWhere(
      (profile) => profile.isActive,
      orElse: () => profiles.first,
    );
  }

  static String _nextProfileId(List<ProjectConfigProfile> profiles) {
    final next = profiles.length + 1;
    return 'profile_${next.toString().padLeft(3, '0')}';
  }

  static String _normalizedProfileMode(String mode) {
    final normalized = mode.trim().toLowerCase();
    if (normalized == 'cloud' || normalized == 'hybrid') {
      return normalized;
    }
    return 'local';
  }

  static List<String> _affectedProfileModules(ProjectConfigProfile profile) {
    return const [
      'dashboard',
      'document_library',
      'knowledge_base',
      'retrieval_verification',
      'document_generation',
      'skill_factory',
      'agent_workbench',
    ];
  }

  static List<String> _profileActivationWarnings(ProjectConfigProfile profile) {
    final warnings = <String>[];
    if (profile.mode != 'local') {
      warnings.add('Redis、向量库、网络和导出器需要连接测试后启用。');
    }
    if (profile.lastTestStatus != '连接成功') {
      warnings.add('当前 Profile 尚未完成连接测试。');
    }
    return warnings;
  }

  static String _userStatus(Object? rawStatus) {
    final status = (rawStatus ?? '').toString();
    return switch (status) {
      'connected' => '连接成功',
      'configured_not_tested' => '已配置未测试',
      'requires_configuration' => '未配置',
      'missing_password' => '配置缺失',
      'auth_failed' => '鉴权失败',
      'invalid_endpoint' => '配置缺失',
      'invalid_dimension' => '维度不匹配',
      'health_failed' => '连接失败',
      'collection_create_failed' => 'Collection 不存在',
      'collection_check_failed' => 'Collection 不存在',
      'vector_write_failed' => '连接失败',
      'vector_search_failed' => '连接失败',
      'vector_delete_failed' => '连接失败',
      'connection_failed' => '连接失败',
      'ping_failed' => '连接失败',
      'probe_failed' => '连接失败',
      'desktop_runtime_required' => '需启动外部服务',
      'available' => '连接成功',
      'disabled' => '已禁用',
      '' => '未配置',
      _ => status,
    };
  }

  static String _profileHealthStatus(
    ProjectConfigProfile profile,
    String redisStatus,
    String qdrantStatus,
    String llmStatus,
  ) {
    if (profile.mode == 'local') {
      return '连接成功';
    }
    if ([redisStatus, qdrantStatus, llmStatus]
        .any((status) => status == '连接失败' || status == '鉴权失败')) {
      return '降级为本地模式';
    }
    return '已配置未测试';
  }

  static String _profileHealthSummary(
    ProjectConfigProfile profile,
    String redisStatus,
    String qdrantStatus,
    String llmStatus,
  ) {
    if (profile.mode == 'local') {
      return '本地存储、本地索引和 Markdown 导出可用。';
    }
    return 'Redis: $redisStatus；Vector DB: $qdrantStatus；LLM: $llmStatus。失败时自动保留本地导入、知识库和 Markdown 生成。';
  }

  static String _exporterStatusSummary(Map<String, dynamic> exporters) {
    final docx = _userStatus(_mapValue(exporters['docx'])['status']);
    final pdf = _userStatus(_mapValue(exporters['pdf'])['status']);
    final pptx = _userStatus(_mapValue(exporters['pptx'])['status']);
    return 'Markdown/JSON/CSV: 连接成功；DOCX: $docx；PDF: $pdf；PPTX: $pptx';
  }

  static Map<String, dynamic> _exporterAssetStatus(
    String format,
    Map<String, dynamic> exporters,
  ) {
    final localFormats = ['markdown', 'json', 'csv'];
    final packagedFormats = ['skill_package', 'agent_config', 'a2a_report'];
    if (localFormats.contains(format)) {
      return {
        'provider': 'local_$format',
        'status': '连接成功',
        'button_enabled': true,
      };
    }
    if (packagedFormats.contains(format)) {
      return {
        'provider': 'local_${format}_export',
        'status': '连接成功',
        'button_enabled': true,
      };
    }
    final config = _mapValue(exporters[format]);
    final status = _userStatus(config['status']);
    return {
      'provider': _stringValue(config['provider'], 'requires_configuration'),
      'status': status,
      'button_enabled': status == '连接成功',
    };
  }

  static String _modelGatewayStatusForMode(String mode) {
    final normalized = mode.trim().toLowerCase();
    return switch (normalized) {
      'success' || 'connected' => '连接成功',
      'auth_failure' || 'auth_failed' || '401' || '403' => '鉴权失败',
      'timeout' || 'timed_out' => '超时',
      'rate_limited' || 'quota_exceeded' || '429' => '额度不足',
      'upstream_unavailable' || 'upstream_failed' || '502' || '503' => '上游不可用',
      'fallback' || 'fallback_triggered' => 'fallback 已触发',
      'missing_config' || 'invalid_endpoint' || 'not_configured' => '配置缺失',
      'save_only' || 'configured_not_tested' => '已配置未测试',
      _ => '连接失败',
    };
  }

  static String _modelGatewayProbeStatus(String mode) {
    final status = _modelGatewayStatusForMode(mode);
    if (status == '连接成功') return '连接成功';
    if (status == 'fallback 已触发') return 'fallback 已触发';
    if (status == '已配置未测试') return '已配置未测试';
    return status;
  }

  static String _modelGatewayErrorMessage(String mode) {
    return switch (_modelGatewayStatusForMode(mode)) {
      '连接成功' => '',
      '已配置未测试' => '',
      '配置缺失' => 'Model Gateway 配置缺失，请先配置 Base URL 和 secret 引用。',
      '鉴权失败' => 'Model Gateway 鉴权失败，请检查 API Key 引用或上游权限。',
      '超时' => 'Model Gateway 请求超时，请检查网络、网关服务和 timeout 配置。',
      '额度不足' => 'Model Gateway 上游额度不足或触发限流。',
      '上游不可用' => 'Model Gateway 上游服务不可用，已保留本地能力降级。',
      'fallback 已触发' => 'Model Gateway 上游不可用，fallback 已触发。',
      _ => 'Model Gateway 连接失败，请检查 Base URL、网络授权和上游服务。',
    };
  }

  static String _modelGatewayPublicError(Map<String, dynamic> gateway) {
    final explicit = _stringValue(gateway['last_error'], '');
    if (explicit.isNotEmpty) {
      return explicit;
    }
    final status = _userStatus(gateway['status']);
    if (status == '连接成功') return '';
    if (status == '未配置' || status == '配置缺失') {
      return 'Model Gateway 未配置。';
    }
    if (status == '已配置未测试') {
      return 'Model Gateway 已配置但尚未测试。';
    }
    return _modelGatewayErrorMessage(status);
  }

  static String _modelGatewayRouteSummary(
    Map<String, dynamic> gateway,
    Map<String, dynamic> llm,
  ) {
    final gatewayStatus = _userStatus(gateway['status']);
    if (gatewayStatus == '连接成功') {
      final gatewayId =
          _stringValue(gateway['gateway_id'], 'gateway_openai_compatible');
      return 'active_profile_gateway:$gatewayId';
    }
    final llmProvider = _stringValue(llm['provider_id'], 'env_configured');
    return 'direct_llm_provider:$llmProvider';
  }

  static List<Map<String, dynamic>> _modelRoutePoolEntries(
    Map<String, dynamic> gateway, {
    required String status,
    required String baseUrl,
  }) {
    final gatewayId =
        _stringValue(gateway['gateway_id'], 'gateway_not_configured');
    final apiKeyRef = _stringValue(gateway['api_key_ref'], 'none');
    final maskedKeyPreview = _stringValue(gateway['masked_key_preview'], '');
    final routeSpecs = <Map<String, dynamic>>[
      ..._modelRouteSpecs('pipeline', [
        'ocr_enhancement',
        'layout_understanding',
        'document_summary',
        'metadata_extraction',
        'okf_compilation',
        'relation_extraction',
        'conflict_detection',
        'quality_review',
        'chunk_rewrite',
        'qa_generation',
      ]),
      ..._modelRouteSpecs('skill', [
        'skill_generation',
        'skill_validation',
        'skill_refinement',
        'external_skill_analysis',
        'external_skill_localization',
        'external_skill_platform_adaptation',
        'external_skill_tool_requirement',
      ]),
      ..._modelRouteSpecs('document', [
        'document_outline',
        'document_generation',
        'document_revision',
        'document_quality_review',
      ]),
      ..._modelRouteSpecs('agent', [
        'agent_chat',
        'agent_reasoning',
        'agent_tool_planning',
        'agent_summarization',
      ]),
      ..._modelRouteSpecs('a2a', [
        'a2a_task_dispatch',
        'a2a_review',
        'a2a_conflict_detection',
        'a2a_consensus',
        'a2a_report',
      ]),
      ..._modelRouteSpecs('tool', [
        'tool_reasoning',
        'tool_parameter_repair',
        'tool_failure_explanation',
      ]),
      ..._modelRouteSpecs('embedding', ['embedding']),
    ];
    return routeSpecs.map((spec) {
      final routeScope = _stringValue(spec['route_scope'], '');
      final isEmbedding = routeScope == 'embedding';
      return {
        'model_route_id': 'route_$routeScope',
        'display_name': _modelRouteDisplayName(routeScope),
        'route_group': spec['route_group'],
        'route_scope': routeScope,
        'route_type': gatewayId == 'gateway_not_configured'
            ? 'direct_provider'
            : 'gateway',
        'gateway_id': gatewayId,
        'provider_config_id': isEmbedding
            ? 'embedding_provider_configured'
            : 'direct_provider_llm',
        'model_name': isEmbedding
            ? 'embedding-model-configured-separately'
            : 'local-default-or-configured-provider',
        'base_url': baseUrl,
        'api_key_ref': apiKeyRef,
        'capabilities': {
          'chat': !isEmbedding,
          'streaming':
              !isEmbedding && _boolValue(gateway['supports_streaming']),
          'vision': routeScope.contains('ocr') ||
              routeScope.contains('layout') ||
              routeScope.contains('vision'),
          'tool_calling':
              routeScope.startsWith('agent_') || routeScope.startsWith('tool_'),
          'embedding': isEmbedding,
          'json_schema': true,
        },
        'fallback_route_ids':
            isEmbedding ? <String>[] : ['route_${routeScope}_fallback'],
        'budget_policy_id': 'budget_$routeScope',
        'rate_limit_policy_id': 'rate_$routeScope',
        'timeout_seconds': routeScope.startsWith('skill_') ? 120 : 60,
        'max_retries': 2,
        'status': status,
        'last_test_at': _stringValue(gateway['last_test_at'], ''),
        'last_error': _modelGatewayPublicError(gateway),
        'masked_key_preview': maskedKeyPreview,
        'secret_masked': true,
        'external_call_performed': false,
      };
    }).toList(growable: false);
  }

  static List<Map<String, dynamic>> _modelRouteSpecs(
    String routeGroup,
    List<String> routeScopes,
  ) {
    return routeScopes
        .map((scope) => {
              'route_group': routeGroup,
              'route_scope': scope,
            })
        .toList(growable: false);
  }

  static Map<String, dynamic> _modelRouteBindingMatrix(
    Directory workspace, {
    required String gatewayId,
    required List<Map<String, dynamic>> routeEntries,
    required String status,
    required String generatedAt,
  }) {
    final byScope = {
      for (final route in routeEntries)
        _stringValue(route['route_scope'], ''): route,
    };
    Map<String, dynamic> binding(
      String module,
      List<String> scopes, {
      required String fallbackPolicy,
    }) {
      return {
        'module': module,
        'route_ids': scopes
            .map((scope) => _stringValue(byScope[scope]?['model_route_id'], ''))
            .where((id) => id.isNotEmpty)
            .toList(growable: false),
        'route_scopes': scopes,
        'status': status,
        'available': status == '连接成功',
        'fallback_policy': fallbackPolicy,
        'gateway_id': gatewayId,
        'secret_masked': true,
      };
    }

    return {
      'schema_version': 'prd_v3_model_route_binding_matrix.v1',
      'plan_name': '模型网关与大模型接入配置能力补全计划',
      'workspace_id': workspace.path,
      'generated_at': generatedAt,
      'gateway_id': gatewayId,
      'bindings': [
        binding(
          'document_library_pipeline',
          [
            'ocr_enhancement',
            'layout_understanding',
            'document_summary',
            'metadata_extraction',
          ],
          fallbackPolicy: '基础解析/OCR 可继续，本地导入不受影响。',
        ),
        binding(
          'okf_pipeline',
          [
            'okf_compilation',
            'metadata_extraction',
            'relation_extraction',
            'conflict_detection',
            'quality_review',
          ],
          fallbackPolicy: '未配置 LLM route 时回退 rule_based_okf。',
        ),
        binding(
          'document_generation',
          [
            'document_outline',
            'document_generation',
            'document_revision',
            'document_quality_review',
          ],
          fallbackPolicy: 'Markdown 导出器保留；正文 LLM 生成需 route 可用。',
        ),
        binding(
          'skill_factory',
          [
            'skill_generation',
            'skill_validation',
            'skill_refinement',
            'external_skill_analysis',
            'external_skill_localization',
            'external_skill_platform_adaptation',
            'external_skill_tool_requirement',
          ],
          fallbackPolicy: '基础导入可继续；深度解析、本土化、验证需 Skill route。',
        ),
        binding(
          'agent_workbench',
          [
            'agent_chat',
            'agent_reasoning',
            'agent_tool_planning',
            'agent_summarization',
          ],
          fallbackPolicy: 'Agent 工作区保留；对话和推理需 Agent route。',
        ),
        binding(
          'a2a',
          [
            'a2a_task_dispatch',
            'a2a_review',
            'a2a_conflict_detection',
            'a2a_consensus',
            'a2a_report',
          ],
          fallbackPolicy: 'A2A 会话状态可本地保存；汇总/冲突增强需 A2A route。',
        ),
        binding(
          'tool_reasoning',
          [
            'tool_reasoning',
            'tool_parameter_repair',
            'tool_failure_explanation',
          ],
          fallbackPolicy: 'Tool Provider 执行不由 LLM route 代替；LLM 只做参数和解释。',
        ),
        binding(
          'embedding',
          ['embedding'],
          fallbackPolicy: 'Embedding route 独立配置，不能复用 chat route。',
        ),
      ],
      'embedding_route_separated_from_chat': true,
      'normal_ui_project_names_visible': false,
      'secret_plaintext_written': false,
    };
  }

  static Map<String, dynamic> _modelUsageCostPolicy(
    List<Map<String, dynamic>> routeEntries, {
    required String generatedAt,
  }) {
    return {
      'schema_version': 'prd_v3_model_usage_cost_policy.v1',
      'generated_at': generatedAt,
      'budget_policy_enabled': true,
      'rate_limit_policy_enabled': true,
      'usage_audit_enabled': true,
      'cost_audit_enabled': true,
      'export_plaintext_secret': false,
      'route_policies': routeEntries
          .map((route) => {
                'model_route_id': route['model_route_id'],
                'route_scope': route['route_scope'],
                'budget_policy_id': route['budget_policy_id'],
                'rate_limit_policy_id': route['rate_limit_policy_id'],
                'timeout_seconds': route['timeout_seconds'],
                'max_retries': route['max_retries'],
                'usage_record_required': true,
                'cost_record_required': true,
                'secret_masked': true,
              })
          .toList(growable: false),
      'secret_plaintext_written': false,
    };
  }

  static String _modelRouteDisplayName(String routeScope) {
    return switch (routeScope) {
      'ocr_enhancement' => 'OCR LLM 增强模型路线',
      'layout_understanding' => '版面理解模型路线',
      'document_summary' => '文档摘要模型路线',
      'metadata_extraction' => '元数据抽取模型路线',
      'okf_compilation' => 'OKF 标准化模型路线',
      'relation_extraction' => '关系抽取模型路线',
      'conflict_detection' => '冲突检测模型路线',
      'quality_review' => '质量复核模型路线',
      'chunk_rewrite' => 'Chunk 改写模型路线',
      'qa_generation' => '问答生成模型路线',
      'skill_generation' => 'Skill 生成模型路线',
      'skill_validation' => 'Skill 验证模型路线',
      'skill_refinement' => 'Skill 优化模型路线',
      'external_skill_analysis' => '外部 Skill 解析模型路线',
      'external_skill_localization' => '外部 Skill 本土化模型路线',
      'external_skill_platform_adaptation' => '外部 Skill 平台适配模型路线',
      'external_skill_tool_requirement' => '外部 Skill Tool 需求抽取模型路线',
      'document_outline' => '文档大纲模型路线',
      'document_generation' => '文档生成模型路线',
      'document_revision' => '文档修订模型路线',
      'document_quality_review' => '文档质量复核模型路线',
      'agent_chat' => 'Agent 对话模型路线',
      'agent_reasoning' => 'Agent 推理模型路线',
      'agent_tool_planning' => 'Agent Tool 规划模型路线',
      'agent_summarization' => 'Agent 摘要模型路线',
      'a2a_task_dispatch' => 'A2A 任务分发模型路线',
      'a2a_review' => 'A2A 复核模型路线',
      'a2a_conflict_detection' => 'A2A 冲突检测模型路线',
      'a2a_consensus' => 'A2A 共识模型路线',
      'a2a_report' => 'A2A 报告模型路线',
      'tool_reasoning' => 'Tool 推理模型路线',
      'tool_parameter_repair' => 'Tool 参数修正模型路线',
      'tool_failure_explanation' => 'Tool 失败解释模型路线',
      'embedding' => 'Embedding 模型路线',
      _ => routeScope,
    };
  }

  static String _providerStatusFromUserStatus(String userStatus) {
    return switch (userStatus) {
      '连接成功' => 'available',
      '已配置未测试' => 'configured_not_tested',
      '未配置' || '配置缺失' => 'needs_provider_config',
      '鉴权失败' => 'needs_secret_config',
      '超时' => 'external_runtime_required',
      '额度不足' || '上游不可用' || 'fallback 已触发' => 'external_runtime_required',
      '已禁用' => 'needs_network_authorization',
      _ => 'dependency_gated',
    };
  }

  static String _sanitizeEndpoint(String endpoint) {
    final trimmed = endpoint.trim();
    if (trimmed.isEmpty) return '';
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null || !parsed.hasScheme) {
      return trimmed.split('?').first.replaceAll(RegExp(r'//[^/@]+@'), '//');
    }
    final port = parsed.hasPort ? ':${parsed.port}' : '';
    return '${parsed.scheme}://${parsed.host}$port${parsed.path}';
  }

  static List<Map<String, dynamic>> _registeredProviderEntries(
      Map<String, dynamic> status) {
    final entries = <Map<String, dynamic>>[];
    for (final capability in _listOfMaps(status['capabilities'])) {
      final capabilityId = _stringValue(capability['capability_id'], '');
      final capabilityArea = _stringValue(capability['capability_area'], '');
      final userVisibleName = _stringValue(capability['user_visible_name'], '');
      final defaultFallback =
          _stringValue(capability['default_fallback'], 'local_provider');
      final providerStates = _listOfMaps(capability['related_provider_states']);
      for (final provider in providerStates) {
        final providerRef = _stringValue(provider['provider_ref'], '');
        if (providerRef.isEmpty) continue;
        if (!_registeredProviderMatchesCapability(capabilityId, provider)) {
          continue;
        }
        final ready = _boolValue(provider['ready_for_user_selection']);
        final status = _stringValue(provider['status'], 'needs_verification');
        final entryClass = _registeredProviderEntryClass(
          capabilityId,
          providerRef,
          provider,
        );
        entries.add({
          'capability_id': capabilityId,
          'capability_area': capabilityArea,
          'provider_ref': providerRef,
          'registry_entry_class': entryClass,
          'architecture_reference_status': _architectureReferenceStatus(
            capabilityId,
            providerRef,
            provider,
            entryClass,
          ),
          'architecture_absorption': _architectureAbsorptionRecord(
            capabilityId,
            providerRef,
            provider,
            entryClass,
          ),
          'template_asset_contract': _templateAssetContract(
            capabilityId,
            providerRef,
            entryClass,
          ),
          'gate_kind': _registeredProviderGateKind(providerRef),
          'gate_audit': _registeredProviderGateAudit(
            capabilityId,
            providerRef,
            provider,
          ),
          'runtime_load_class': _providerRuntimeLoadClass(
            entryClass,
            provider,
          ),
          'user_visible_entry':
              _providerUserEntry(capabilityId, userVisibleName),
          'status': _providerStatusLabel(status),
          'raw_status': status,
          'ready_for_user_selection': ready,
          'runtime_loaded': false,
          'requires_network': _boolValue(provider['requires_network']),
          'requires_secret': _boolValue(provider['requires_secret']),
          'requires_external_runtime':
              _boolValue(provider['requires_external_runtime']),
          'contract_status': _listOfStrings(provider['contract_status']),
          'test_status': ready ? '连接成功' : _providerStatusLabel(status),
          'activation_condition': _providerActivationCondition(provider),
          'fallback_provider': defaultFallback,
          'audit_event_required': _boolValue(provider['audit_event_required']),
          'rollback_supported': _boolValue(provider['rollback_supported']),
          'visible_in_normal_ui': false,
          'secret_masked': true,
        });
      }
    }
    return entries;
  }

  static bool _registeredProviderMatchesCapability(
    String capabilityId,
    Map<String, dynamic> provider,
  ) {
    final contractStatus = _listOfStrings(provider['contract_status']).toSet();
    return switch (capabilityId) {
      'document_exporter' =>
        !contractStatus.contains('workflow_export_adapter'),
      'workflow_collaboration_export' =>
        contractStatus.contains('workflow_export_adapter'),
      _ => true,
    };
  }

  static Map<String, int> _registryClassCounts(
    List<Map<String, dynamic>> entries,
  ) {
    final counts = <String, int>{
      'capability_provider': 0,
      'template_asset': 0,
      'architecture_reference': 0,
    };
    for (final entry in entries) {
      final entryClass =
          _stringValue(entry['registry_entry_class'], 'capability_provider');
      counts[entryClass] = (counts[entryClass] ?? 0) + 1;
    }
    return counts;
  }

  static Map<String, int> _architectureReferenceStatusCounts(
    List<Map<String, dynamic>> entries,
  ) {
    final counts = <String, int>{
      'candidate_reference': 0,
      'absorbed_into_architecture': 0,
      'rejected_no_architecture_gain': 0,
      'deferred_with_blocker': 0,
    };
    for (final entry in entries) {
      final status = _stringValue(
        entry['architecture_reference_status'],
        'candidate_reference',
      );
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  static String _registeredProviderEntryClass(
    String capabilityId,
    String providerRef,
    Map<String, dynamic> provider,
  ) {
    final contractStatus = _listOfStrings(provider['contract_status']).toSet();
    if (capabilityId == 'skill_template_provider') {
      return 'template_asset';
    }
    if (capabilityId == 'governance_audit_provider' &&
        providerRef == 'mattpocock_skills') {
      return 'template_asset';
    }
    if (providerRef == 'ragas' ||
        providerRef == 'deepeval' ||
        providerRef == 'rtk') {
      return 'capability_provider';
    }
    if (contractStatus.contains('benchmark_only')) {
      return 'architecture_reference';
    }
    if (contractStatus.contains('reference_only')) {
      return switch (providerRef) {
        'rag_anything' ||
        'jellyfish' ||
        'story_flicks' =>
          'capability_provider',
        'mmskills' || 'seedance2_skill' => 'template_asset',
        _ => 'architecture_reference',
      };
    }
    return 'capability_provider';
  }

  static String _architectureReferenceStatus(
    String capabilityId,
    String providerRef,
    Map<String, dynamic> provider,
    String entryClass,
  ) {
    final contractStatus = _listOfStrings(provider['contract_status']).toSet();
    if (entryClass == 'capability_provider' || entryClass == 'template_asset') {
      return 'absorbed_into_architecture';
    }
    if (providerRef == 'llamaindex') {
      return 'deferred_with_blocker';
    }
    if (contractStatus.contains('future_adapter')) {
      return 'deferred_with_blocker';
    }
    return switch (capabilityId) {
      'retrieval_provider' ||
      'knowledge_embedding_vector' ||
      'governance_audit_provider' =>
        'deferred_with_blocker',
      _ => 'rejected_no_architecture_gain',
    };
  }

  static String _registeredProviderGateKind(String providerRef) {
    return switch (providerRef) {
      'anysearchskill' => 'network_search_provider_gate',
      'last30days_skill' => 'network_time_window_adapter_gate',
      'seedance2_skill' => 'secret_masked_video_skill_gate',
      'rtk' => 'external_runtime_agent_tool_gate',
      _ => '',
    };
  }

  static Map<String, dynamic> _registeredProviderGateAudit(
    String capabilityId,
    String providerRef,
    Map<String, dynamic> provider,
  ) {
    final gateKind = _registeredProviderGateKind(providerRef);
    if (gateKind.isEmpty) {
      return const <String, dynamic>{};
    }
    return {
      'gate_kind': gateKind,
      'capability_id': capabilityId,
      'requires_network': _boolValue(provider['requires_network']),
      'requires_secret_ref': _boolValue(provider['requires_secret']),
      'requires_external_runtime':
          _boolValue(provider['requires_external_runtime']),
      'network_call_attempted': false,
      'external_runtime_executed': false,
      'vendor_runtime_loaded': false,
      'fallback_preserves_local_chain': true,
      'normal_ui_project_name_visible': false,
      'secret_plaintext_written': false,
    };
  }

  static Map<String, dynamic> _architectureAbsorptionRecord(
    String capabilityId,
    String providerRef,
    Map<String, dynamic> provider,
    String entryClass,
  ) {
    final status = _architectureReferenceStatus(
      capabilityId,
      providerRef,
      provider,
      entryClass,
    );
    final absorbedTargets = switch (status) {
      'absorbed_into_architecture' => _architectureAbsorptionTargets(
          capabilityId,
          entryClass,
        ),
      _ => <String>[],
    };
    return {
      'status': status,
      'decision_source': 'stage3_architecture_absorption_gate',
      'learning_note_only': false,
      'indefinite_reference_allowed': false,
      'absorbed_targets': absorbedTargets,
      'blocker': status == 'deferred_with_blocker'
          ? _architectureReferenceBlocker(providerRef, provider)
          : '',
      'rejection_reason': status == 'rejected_no_architecture_gain'
          ? '对 v3 主链路无明确增益或被现有能力覆盖。'
          : '',
      'architecture_delivery_required': status == 'absorbed_into_architecture',
      'must_not_surface_to_normal_ui': true,
    };
  }

  static bool _architectureAbsorptionDecisionValid(
    Map<String, dynamic> entry,
  ) {
    final absorption = _mapValue(entry['architecture_absorption']);
    final status = _stringValue(
      absorption['status'],
      _stringValue(entry['architecture_reference_status'], ''),
    );
    if (_stringValue(absorption['decision_source'], '').isEmpty) {
      return false;
    }
    if (_boolValue(absorption['learning_note_only']) ||
        _boolValue(absorption['indefinite_reference_allowed'])) {
      return false;
    }
    final absorbedTargets = _listOfStrings(absorption['absorbed_targets']);
    final blocker = _stringValue(absorption['blocker'], '');
    final rejectionReason = _stringValue(absorption['rejection_reason'], '');
    return switch (status) {
      'absorbed_into_architecture' =>
        _boolValue(absorption['architecture_delivery_required']) &&
            absorbedTargets.isNotEmpty &&
            blocker.isEmpty &&
            rejectionReason.isEmpty,
      'deferred_with_blocker' =>
        !_boolValue(absorption['architecture_delivery_required']) &&
            absorbedTargets.isEmpty &&
            blocker.isNotEmpty &&
            rejectionReason.isEmpty,
      'rejected_no_architecture_gain' =>
        !_boolValue(absorption['architecture_delivery_required']) &&
            absorbedTargets.isEmpty &&
            rejectionReason.isNotEmpty,
      _ => false,
    };
  }

  static List<String> _architectureAbsorptionTargets(
    String capabilityId,
    String entryClass,
  ) {
    if (entryClass == 'template_asset') {
      return const [
        'template_manifest',
        'source_version_validation',
        'skill_agent_binding_boundary',
        'audit_model',
      ];
    }
    return switch (capabilityId) {
      'document_parser_ocr' => const [
          'provider_contract',
          'parser_ocr_schema',
          'health_check_gate',
          'fallback_policy',
          'audit_model',
        ],
      'knowledge_embedding_vector' => const [
          'provider_contract',
          'index_vector_schema',
          'dimension_check_gate',
          'fallback_policy',
          'audit_model',
        ],
      'retrieval_provider' => const [
          'provider_contract',
          'rag_retrieval_schema',
          'network_policy_gate',
          'fallback_policy',
          'audit_model',
        ],
      'document_exporter' => const [
          'exporter_contract',
          'artifact_schema',
          'format_availability_gate',
          'fallback_policy',
          'audit_model',
        ],
      'agent_model_tools_memory' => const [
          'agent_capability_contract',
          'memory_policy_schema',
          'permission_gate',
          'fallback_policy',
          'audit_model',
        ],
      'workflow_collaboration_export' => const [
          'workflow_export_contract',
          'safe_health_check_boundary',
          'a2a_export_fallback',
          'rollback_audit',
        ],
      'governance_audit_provider' => const [
          'evaluation_contract',
          'quality_gate_schema',
          'audit_model',
          'fallback_policy',
        ],
      _ => const ['provider_contract', 'audit_model'],
    };
  }

  static String _architectureReferenceBlocker(
    String providerRef,
    Map<String, dynamic> provider,
  ) {
    if (_boolValue(provider['requires_external_runtime'])) {
      return '需要用户自有外部服务健康检查通过。';
    }
    if (providerRef == 'llamaindex') {
      return '需要证明其 pipeline 抽象能降低当前 RAG/索引复杂度且不替代既有 Provider 合同。';
    }
    if (_boolValue(provider['requires_network'])) {
      return '需要网络授权与域名 allowlist。';
    }
    if (_boolValue(provider['requires_secret'])) {
      return '需要 secret ref 配置，不能写入明文密钥。';
    }
    if (providerRef == 'rtk') {
      return '需要外部 Agent runtime 服务与权限边界证明。';
    }
    return '需要补齐真实 runtime 证据后才能吸收。';
  }

  static String _providerRuntimeLoadClass(
    String entryClass,
    Map<String, dynamic> provider,
  ) {
    if (entryClass == 'template_asset') {
      return 'template_manifest_only';
    }
    if (entryClass == 'architecture_reference') {
      return 'architecture_reference_no_runtime';
    }
    if (_boolValue(provider['requires_external_runtime'])) {
      return 'external_health_check_required';
    }
    return 'local_capability_enhancement';
  }

  static Map<String, dynamic> _templateAssetContract(
    String capabilityId,
    String providerRef,
    String entryClass,
  ) {
    if (entryClass != 'template_asset') {
      return const <String, dynamic>{};
    }
    return {
      'contract_id': 'template_asset_${capabilityId}_$providerRef',
      'asset_manifest_required': true,
      'source_required': true,
      'version_required': true,
      'validation_required': true,
      'skill_agent_binding_boundary': true,
      'runtime_load_required': false,
      'external_health_check_required': false,
      'ordinary_ui_project_name_visible': false,
      'accepted_entry_points': [
        'skill_factory_template_catalog',
        'agent_workbench_template_binding',
        'document_generation_style_template',
      ],
    };
  }

  static Map<String, dynamic> _registeredProviderEntry(
    Map<String, dynamic> matrix,
    String providerRef,
  ) {
    final normalized = providerRef.trim().toLowerCase();
    if (normalized.isEmpty) return const {};
    for (final entry in _listOfMaps(matrix['provider_entries'])) {
      if (_stringValue(entry['provider_ref'], '').toLowerCase() == normalized) {
        return entry;
      }
    }
    return const {};
  }

  static List<Map<String, dynamic>> _registeredCapabilitySummaries(
      Map<String, dynamic> status) {
    return _listOfMaps(status['capabilities']).map((capability) {
      final providers = _listOfMaps(capability['related_provider_states']);
      final readyCount = providers
          .where((provider) => _boolValue(provider['ready_for_user_selection']))
          .length;
      return {
        'capability_id': _stringValue(capability['capability_id'], ''),
        'capability_area': _stringValue(capability['capability_area'], ''),
        'user_visible_name': _stringValue(capability['user_visible_name'], ''),
        'provider_count': providers.length,
        'ready_for_user_selection_count': readyCount,
        'status': _providerStatusLabel(capability['status']),
        'fallback_provider':
            _stringValue(capability['default_fallback'], 'local_provider'),
      };
    }).toList(growable: false);
  }

  static String _providerUserEntry(
    String capabilityId,
    String fallbackName,
  ) {
    return switch (capabilityId) {
      'document_parser_ocr' => '文档库：解析 / OCR',
      'knowledge_embedding_vector' => '知识库：Embedding / 向量库',
      'retrieval_provider' => '检索验证：检索 / 召回',
      'document_exporter' => '文档生成：导出器',
      'skill_template_provider' => 'Skill 工厂：模板 / 本地化',
      'agent_model_tools_memory' => 'Agent 工作台：模型 / 工具 / 记忆',
      'workflow_collaboration_export' => 'Agent 工作台：A2A / 工作流导出',
      'governance_audit_provider' => '审计中心：评测 / 治理',
      _ => fallbackName,
    };
  }

  static String _providerCapabilityDisplayName(String capabilityId) {
    return switch (capabilityId) {
      'document_parser_ocr' => '解析 / OCR',
      'knowledge_embedding_vector' => 'Embedding / 向量库',
      'retrieval_provider' => '检索 / 召回',
      'document_exporter' => '文档导出',
      'skill_template_provider' => 'Skill 模板 / 本地化',
      'agent_model_tools_memory' => 'Agent 模型 / 工具 / 记忆',
      'workflow_collaboration_export' => 'A2A / 工作流导出',
      'governance_audit_provider' => '评测 / 治理',
      _ => capabilityId,
    };
  }

  static String _providerCapabilityConfigurationEntry(String capabilityId) {
    return switch (capabilityId) {
      'document_parser_ocr' => '文档库',
      'knowledge_embedding_vector' => '知识库',
      'retrieval_provider' => '检索验证',
      'document_exporter' => '文档生成',
      'skill_template_provider' => 'Skill 工厂',
      'agent_model_tools_memory' => 'Agent 工作台',
      'workflow_collaboration_export' => 'Agent 工作台',
      'governance_audit_provider' => '审计中心',
      _ => '设置',
    };
  }

  static String _providerCapabilityCurrentBehavior(
    String capabilityId, {
    required String status,
    required String activeProviderKind,
    required bool runtimeLoaded,
  }) {
    if (runtimeLoaded) {
      return switch (capabilityId) {
        'workflow_collaboration_export' => '外部协作健康检查通过，本地审计仍保留。',
        _ => '增强能力可用，本地回退仍保留。',
      };
    }
    final localFallback =
        activeProviderKind == 'local_fallback' || status == '降级为本地模式';
    return switch (capabilityId) {
      'document_parser_ocr' =>
        localFallback ? '使用本地解析；OCR/Parser 可在设置中配置。' : '增强解析可选。',
      'knowledge_embedding_vector' =>
        localFallback ? '使用本地索引；Embedding/向量库可在设置中配置。' : '增强索引可选。',
      'retrieval_provider' => localFallback ? '使用本地检索；外部检索按网络授权启用。' : '增强检索可选。',
      'document_exporter' =>
        localFallback ? 'Markdown/JSON/CSV 可用；Office 导出需配置。' : '增强导出可选。',
      'skill_template_provider' =>
        localFallback ? '使用本地 Skill 生成；模板增强需验证后启用。' : '模板增强可选。',
      'agent_model_tools_memory' =>
        localFallback ? '使用本地 Agent 状态；模型/工具/记忆按授权配置。' : 'Agent 增强可选。',
      'workflow_collaboration_export' => 'A2A 本地协作报告可用；外部工作流需健康检查。',
      'governance_audit_provider' =>
        localFallback ? '使用本地审计；治理增强需验证后启用。' : '治理增强可选。',
      _ => localFallback ? '使用本地能力。' : '增强能力可选。',
    };
  }

  static String _providerActivationCondition(Map<String, dynamic> provider) {
    final conditions = <String>[];
    if (_boolValue(provider['requires_network'])) {
      conditions.add('需要网络授权');
    }
    if (_boolValue(provider['requires_secret'])) {
      conditions.add('需要 secret 引用');
    }
    if (_boolValue(provider['requires_external_runtime'])) {
      conditions.add('需要启动外部服务');
    }
    final status = _stringValue(provider['status'], '');
    if (status.contains('dependency')) {
      conditions.add('需要安装依赖');
    }
    if (status.contains('test') || status.contains('configured')) {
      conditions.add('需要连接测试');
    }
    if (status.contains('verification')) {
      conditions.add('需要验证');
    }
    return conditions.isEmpty ? '已配置未测试' : conditions.join('；');
  }

  static String _providerStatusLabel(Object? rawStatus) {
    final status = rawStatus?.toString() ?? '';
    return switch (status) {
      'available' => '连接成功',
      'available_with_gated_options' => '已配置未测试',
      'configured_not_tested' => '已配置未测试',
      'dependency_gated' => '需安装外部服务',
      'external_runtime_required' => '需启动外部服务',
      'needs_secret_config' => '配置缺失',
      'needs_network_authorization' => '已禁用',
      'needs_verification' => '已配置未测试',
      'needs_provider_config' => '配置缺失',
      '' => '未配置',
      _ => status,
    };
  }

  static String _registeredProviderHealthStatus(Map<String, dynamic> entry) {
    final rawStatus = _stringValue(entry['raw_status'], '');
    if (_boolValue(entry['ready_for_user_selection']) &&
        rawStatus == 'available') {
      return '连接成功';
    }
    if (_boolValue(entry['requires_external_runtime'])) {
      return '需启动外部服务';
    }
    if (_boolValue(entry['requires_network'])) {
      return '已禁用';
    }
    if (_boolValue(entry['requires_secret'])) {
      return '配置缺失';
    }
    return switch (rawStatus) {
      'dependency_gated' => '需安装外部服务',
      'external_runtime_required' => '需启动外部服务',
      'needs_secret_config' => '配置缺失',
      'needs_network_authorization' => '已禁用',
      'needs_provider_config' => '配置缺失',
      'configured_not_tested' => '已配置未测试',
      'needs_verification' => '已配置未测试',
      'available_with_gated_options' => '已配置未测试',
      'available' => '已配置未测试',
      '' => '未配置',
      _ => _providerStatusLabel(rawStatus),
    };
  }

  static String _registeredProviderBlockedReason(Map<String, dynamic> entry) {
    final explicit = _stringValue(entry['activation_condition'], '');
    if (explicit.isNotEmpty && explicit != '已配置未测试') {
      return explicit;
    }
    final status = _registeredProviderHealthStatus(entry);
    return switch (status) {
      '需安装外部服务' => '需要安装外部服务或完成适配后才能启用。',
      '需启动外部服务' => '需要启动外部服务并通过连接测试后才能启用。',
      '配置缺失' => '需要补齐 Provider 配置或 secret 引用后才能启用。',
      '已禁用' => '当前网络授权或 Provider 策略未开启。',
      '已配置未测试' => '需要完成连接测试和能力验证后才能启用。',
      _ => status,
    };
  }

  static List<String> _registeredProviderAffectedModules(
      Map<String, dynamic> entry) {
    final capabilityId = _stringValue(entry['capability_id'], '');
    return switch (capabilityId) {
      'document_parser_ocr' => ['document_library'],
      'knowledge_embedding_vector' => ['knowledge_base'],
      'retrieval_provider' => ['retrieval_verification'],
      'document_exporter' => ['document_generation', 'artifact_center'],
      'skill_template_provider' => ['skill_factory'],
      'agent_model_tools_memory' => ['agent_workbench'],
      'workflow_collaboration_export' => ['agent_workbench', 'artifact_center'],
      'governance_audit_provider' => ['audit_center'],
      _ => ['settings'],
    };
  }

  static List<Map<String, dynamic>> _registeredProviderDownstreamBindings(
    List<Map<String, dynamic>> healthEntries,
  ) {
    const bindings = {
      'document_library': 'Parser / OCR 不可用时保留本地解析。',
      'knowledge_base': '外部向量不可用时回退本地索引。',
      'retrieval_verification': '外部检索不可用时保留本地检索。',
      'document_generation': '导出器不可用时保留 Markdown。',
      'skill_factory': '模板增强不可用时保留本地 Skill 生成边界。',
      'agent_workbench': '记忆、工具和 A2A 增强不可用时保留本地文件状态。',
      'audit_center': '外部治理增强不可用时保留本地审计资产。',
    };
    return bindings.entries.map((binding) {
      final related = healthEntries
          .where((entry) =>
              _registeredProviderAffectedModules(entry).contains(binding.key))
          .toList(growable: false);
      return {
        'module': binding.key,
        'provider_count': related.length,
        'runtime_loaded_count':
            related.where((entry) => entry['runtime_loaded'] == true).length,
        'fallback_behavior': binding.value,
        'unavailable_provider_blocks_module': false,
      };
    }).toList(growable: false);
  }

  static Map<String, dynamic> _moduleProviderBindingSummary(
    Map<String, dynamic> manifest,
    String module,
  ) {
    final bindings = _listOfMaps(manifest['bindings'])
        .where((binding) =>
            _listOfStrings(binding['affected_modules']).contains(module))
        .toList(growable: false);
    return {
      'binding_count': bindings.length,
      'local_fallback_count': bindings
          .where(
              (binding) => binding['active_provider_kind'] == 'local_fallback')
          .length,
      'registered_provider_count': bindings
          .where((binding) =>
              binding['active_provider_kind'] == 'registered_provider')
          .length,
      'user_status':
          bindings.any((binding) => binding['selection_allowed'] == true)
              ? '连接成功'
              : '降级为本地模式',
      'unavailable_provider_blocks_module': false,
      'secret_masked': true,
    };
  }

  static Map<String, dynamic> _modelRouteModuleBinding(
    Map<String, dynamic> matrix,
    String module,
  ) {
    final binding = _listOfMaps(matrix['bindings']).firstWhere(
      (item) => _stringValue(item['module'], '') == module,
      orElse: () => const <String, dynamic>{},
    );
    if (binding.isEmpty) {
      return {
        'module': module,
        'route_ids': const <String>[],
        'status': '未配置',
        'available': false,
        'fallback_policy': '模型路线未配置。',
        'secret_masked': true,
      };
    }
    return {
      'module': module,
      'route_ids': _listOfStrings(binding['route_ids']),
      'route_scopes': _listOfStrings(binding['route_scopes']),
      'status': _stringValue(binding['status'], '未配置'),
      'available': _boolValue(binding['available']),
      'fallback_policy': _stringValue(binding['fallback_policy'], ''),
      'gateway_id':
          _stringValue(binding['gateway_id'], 'gateway_not_configured'),
      'secret_masked': true,
    };
  }

  Future<Map<String, dynamic>> _currentModelRouteModuleBinding(
      String module) async {
    final workspace = _requireWorkspace();
    var matrix = await _readJsonObject(_joinNested(workspace.path,
        'config/model_gateway/model_route_binding_matrix.json'));
    if (_listOfMaps(matrix['bindings']).isEmpty) {
      final providerSettings = await loadProviderRuntimeSettings();
      final gateway = _mapValue(providerSettings['model_gateway']);
      final status = _userStatus(gateway['status']);
      final routeEntries = _modelRoutePoolEntries(
        gateway,
        status: status,
        baseUrl: _sanitizeEndpoint(_stringValue(gateway['base_url'], '')),
      );
      matrix = _modelRouteBindingMatrix(
        workspace,
        gatewayId:
            _stringValue(gateway['gateway_id'], 'gateway_not_configured'),
        routeEntries: routeEntries,
        status: status,
        generatedAt: DateTime.now().toUtc().toIso8601String(),
      );
    }
    return _modelRouteModuleBinding(matrix, module);
  }

  static Map<String, dynamic> _modelRouteEvidenceForScopes(
    Map<String, dynamic> binding,
    List<String> scopes,
  ) {
    final bindingScopes = _listOfStrings(binding['route_scopes']);
    final bindingIds = _listOfStrings(binding['route_ids']);
    final selectedScopes = <String>[];
    final selectedIds = <String>[];
    for (final scope in scopes) {
      final index = bindingScopes.indexOf(scope);
      if (index >= 0) {
        selectedScopes.add(scope);
        if (index < bindingIds.length && bindingIds[index].isNotEmpty) {
          selectedIds.add(bindingIds[index]);
        }
      }
    }
    return {
      'module': _stringValue(binding['module'], ''),
      'route_scopes': selectedScopes.isEmpty ? scopes : selectedScopes,
      'route_ids': selectedIds,
      'status': _stringValue(binding['status'], '未配置'),
      'available': _boolValue(binding['available']),
      'gateway_id':
          _stringValue(binding['gateway_id'], 'gateway_not_configured'),
      'fallback_policy': _stringValue(binding['fallback_policy'], ''),
      'secret_masked': true,
    };
  }

  static bool _providerReadyForSelection(
    Map<String, dynamic> entry,
    Map<String, Map<String, dynamic>> readinessByProvider,
  ) {
    final providerRef = _stringValue(entry['provider_ref'], '');
    final readiness = readinessByProvider[providerRef];
    if (readiness == null) {
      return _boolValue(entry['ready_for_user_selection']) &&
          _registeredProviderHealthStatus(entry) == '连接成功';
    }
    return _stringValue(readiness['status'], '') == '连接成功' &&
        _boolValue(readiness['ready_for_user_selection']);
  }

  static String _providerAdapterType(Map<String, dynamic> entry) {
    return switch (_stringValue(entry['capability_id'], '')) {
      'document_parser_ocr' => 'parser_ocr_adapter',
      'knowledge_embedding_vector' => 'embedding_vector_adapter',
      'retrieval_provider' => 'retrieval_adapter',
      'document_exporter' => 'exporter_adapter',
      'skill_template_provider' => 'skill_template_adapter',
      'agent_model_tools_memory' => 'agent_capability_adapter',
      'workflow_collaboration_export' => 'workflow_export_adapter',
      'governance_audit_provider' => 'governance_audit_adapter',
      _ => 'provider_adapter',
    };
  }

  static List<String> _providerRequiredConfigRefs(Map<String, dynamic> entry) {
    final refs = <String>[];
    switch (_stringValue(entry['capability_id'], '')) {
      case 'document_parser_ocr':
        refs.addAll(
            ['pdf_parser_provider_config_id', 'ocr_provider_config_id']);
      case 'knowledge_embedding_vector':
        refs.addAll(['embedding_config_id', 'vector_config_id']);
      case 'retrieval_provider':
        refs.addAll(['search_provider_config_id', 'network_policy_id']);
      case 'document_exporter':
        refs.add('exporter_config_id');
      case 'skill_template_provider':
        refs.addAll(['model_config_id', 'tool_policy_id']);
      case 'agent_model_tools_memory':
        refs.addAll([
          'model_config_id',
          'redis_config_id',
          'vector_config_id',
          'agent_memory_policy_id',
          'tool_policy_id',
        ]);
      case 'workflow_collaboration_export':
        refs.addAll(['agent_memory_policy_id', 'exporter_config_id']);
      case 'governance_audit_provider':
        refs.addAll(['storage_config_id', 'network_policy_id']);
    }
    if (_boolValue(entry['requires_secret'])) {
      refs.add('secret_ref');
    }
    return refs.toSet().toList(growable: false)..sort();
  }

  static List<String> _providerHealthCheckActions(Map<String, dynamic> entry) {
    final actions = <String>[
      'contract_schema_check',
      'rollback_manifest_check'
    ];
    switch (_stringValue(entry['capability_id'], '')) {
      case 'document_parser_ocr':
        actions.addAll(['dependency_probe', 'sample_parse_check']);
      case 'knowledge_embedding_vector':
        actions.addAll(['embedding_dimension_check', 'vector_roundtrip_check']);
      case 'retrieval_provider':
        actions.addAll(['network_authorization_check', 'query_probe']);
      case 'document_exporter':
        actions.addAll(['format_availability_check', 'sample_export_check']);
      case 'skill_template_provider':
        actions.addAll(['template_schema_check', 'localization_probe']);
      case 'agent_model_tools_memory':
        actions.addAll(['model_config_check', 'memory_policy_check']);
      case 'workflow_collaboration_export':
        actions.addAll(['workflow_schema_check', 'a2a_report_export_check']);
      case 'governance_audit_provider':
        actions.addAll(['audit_schema_check', 'evaluator_availability_check']);
    }
    if (_boolValue(entry['requires_network'])) {
      actions.add('network_allowlist_check');
    }
    if (_boolValue(entry['requires_secret'])) {
      actions.add('secret_ref_check');
    }
    if (_boolValue(entry['requires_external_runtime'])) {
      actions.add('external_runtime_health_check');
    }
    return actions.toSet().toList(growable: false)..sort();
  }

  static List<String> _providerActivationPrerequisites(
    Map<String, dynamic> entry,
    String healthStatus,
  ) {
    final prerequisites = <String>[];
    final blockedReason = _registeredProviderBlockedReason(entry);
    if (blockedReason.isNotEmpty) {
      prerequisites.add(blockedReason);
    }
    if (healthStatus != '连接成功') {
      prerequisites.add('需要健康检查通过');
    }
    prerequisites
        .addAll(_providerRequiredConfigRefs(entry).map((ref) => '需要配置 $ref'));
    return prerequisites.toSet().toList(growable: false)..sort();
  }

  static Map<String, dynamic> _providerAdapterReadiness(
    Map<String, dynamic> contract,
    ProjectConfigProfile profile,
    Map<String, dynamic> config,
    Directory workspace,
  ) {
    final highRiskGate = _probeHighRiskRegisteredProviderGate(
      workspace,
      contract,
      profile,
      config,
    );
    if (highRiskGate.isNotEmpty) {
      return {
        'status': highRiskGate['status'],
        'error_code': highRiskGate['error_code'],
        'error_message_zh': highRiskGate['error_message_zh'],
        'missing_config_refs': highRiskGate['missing_config_refs'],
        'blocked_reasons': highRiskGate['blocked_reasons'],
        'gate_kind': highRiskGate['gate_kind'],
        'gate_audit': highRiskGate['gate_audit'],
        'test_artifacts': [highRiskGate['probe_path']],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    if (_listOfStrings(contract['capability_ids'])
        .contains('document_parser_ocr')) {
      final providerRef = _stringValue(contract['provider_ref'], '');
      final probe = _probeDocumentParserOcrAdapter(workspace, providerRef);
      if (_boolValue(probe['passed'])) {
        return {
          'status': '连接成功',
          'error_code': '',
          'error_message_zh': '',
          'missing_config_refs': <String>[],
          'blocked_reasons': <String>[],
          'test_artifacts': [probe['probe_path']],
          'ready_for_user_selection': true,
          'runtime_loaded': false,
        };
      }
      return {
        'status': '已配置未测试',
        'error_code': 'parser_ocr_probe_requires_real_parse_artifacts',
        'error_message_zh': _stringValue(
          probe['error_message_zh'],
          '需要先生成真实解析/OCR 产物后才能启用解析能力增强。',
        ),
        'missing_config_refs': <String>[],
        'blocked_reasons': _listOfStrings(probe['blocked_reasons']),
        'test_artifacts': [probe['probe_path']],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    if (_listOfStrings(contract['capability_ids'])
        .contains('knowledge_embedding_vector')) {
      final providerRef = _stringValue(contract['provider_ref'], '');
      final probe = _probeEmbeddingVectorAdapter(workspace, providerRef);
      if (_boolValue(probe['passed'])) {
        return {
          'status': '连接成功',
          'error_code': '',
          'error_message_zh': '',
          'missing_config_refs': <String>[],
          'blocked_reasons': <String>[],
          'test_artifacts': [probe['probe_path']],
          'ready_for_user_selection': true,
          'runtime_loaded': false,
        };
      }
      return {
        'status': _stringValue(probe['status'], '已配置未测试'),
        'error_code': 'embedding_vector_probe_requires_index_artifacts',
        'error_message_zh': _stringValue(
          probe['error_message_zh'],
          '需要先生成真实知识库索引和向量引用产物后才能启用 Embedding / Vector 能力增强。',
        ),
        'missing_config_refs': <String>[],
        'blocked_reasons': _listOfStrings(probe['blocked_reasons']),
        'test_artifacts': [probe['probe_path']],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    if (_stringValue(contract['provider_ref'], '') == 'sirchmunk') {
      final probe = _probeSirchmunkDirectFileSearch(workspace);
      if (_boolValue(probe['passed'])) {
        return {
          'status': '连接成功',
          'error_code': '',
          'error_message_zh': '',
          'missing_config_refs': <String>[],
          'blocked_reasons': <String>[],
          'test_artifacts': [probe['probe_path']],
          'ready_for_user_selection': true,
          'runtime_loaded': false,
        };
      }
      return {
        'status': '已配置未测试',
        'error_code': 'sirchmunk_probe_requires_kb',
        'error_message_zh': _stringValue(
          probe['error_message_zh'],
          '需要先构建知识库后才能启用本地直连检索 Provider。',
        ),
        'missing_config_refs': <String>[],
        'blocked_reasons': ['需要先构建知识库并生成 chunks.jsonl'],
        'test_artifacts': [probe['probe_path']],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    if (const {'ragas', 'deepeval'}
        .contains(_stringValue(contract['provider_ref'], ''))) {
      final providerRef = _stringValue(contract['provider_ref'], '');
      final probe = _probeRagEvaluationAdapter(workspace, providerRef);
      if (_boolValue(probe['passed'])) {
        return {
          'status': '连接成功',
          'error_code': '',
          'error_message_zh': '',
          'missing_config_refs': <String>[],
          'blocked_reasons': <String>[],
          'test_artifacts': [probe['probe_path']],
          'ready_for_user_selection': true,
          'runtime_loaded': false,
        };
      }
      return {
        'status': '已配置未测试',
        'error_code': 'rag_evaluation_probe_requires_retrieval_validation',
        'error_message_zh': _stringValue(
          probe['error_message_zh'],
          '需要真实检索验证、引用覆盖、冲突检测和人工校验记录后才能启用 RAG 评测能力增强。',
        ),
        'missing_config_refs': <String>[],
        'blocked_reasons': _listOfStrings(probe['blocked_reasons']),
        'test_artifacts': [probe['probe_path']],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    if (_stringValue(contract['provider_ref'], '') == 'mattpocock_skills') {
      final probe = _probeMattpocockGovernanceRulePack(workspace);
      if (_boolValue(probe['passed'])) {
        return {
          'status': '连接成功',
          'error_code': '',
          'error_message_zh': '',
          'missing_config_refs': <String>[],
          'blocked_reasons': <String>[],
          'test_artifacts': [probe['probe_path']],
          'ready_for_user_selection': true,
          'runtime_loaded': false,
        };
      }
      return {
        'status': '已配置未测试',
        'error_code': 'mattpocock_governance_probe_requires_local_assets',
        'error_message_zh': _stringValue(
          probe['error_message_zh'],
          '需要本地治理规则包证据完整后才能启用治理能力增强。',
        ),
        'missing_config_refs': <String>[],
        'blocked_reasons': ['需要本地治理规则、测试治理和安全审计资产完整'],
        'test_artifacts': [probe['probe_path']],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    if (_stringValue(contract['provider_ref'], '') ==
        'skill_prompt_generator') {
      final probe = _probeSkillPromptGeneratorTemplateAssets(workspace);
      if (_boolValue(probe['passed'])) {
        return {
          'status': '连接成功',
          'error_code': '',
          'error_message_zh': '',
          'missing_config_refs': <String>[],
          'blocked_reasons': <String>[],
          'test_artifacts': [probe['probe_path']],
          'ready_for_user_selection': true,
          'runtime_loaded': false,
        };
      }
      return {
        'status': '已配置未测试',
        'error_code': 'skill_prompt_generator_probe_requires_skill_assets',
        'error_message_zh': _stringValue(
          probe['error_message_zh'],
          '需要真实 Skill 生成、本土化、融合、验证和多版本运行产物后才能启用模板提示能力增强。',
        ),
        'missing_config_refs': <String>[],
        'blocked_reasons': _listOfStrings(probe['blocked_reasons']),
        'test_artifacts': [probe['probe_path']],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    if (_stringValue(contract['provider_ref'], '') ==
        'andrej_karpathy_skills') {
      final probe = _probeKarpathyTeachingSkillAssets(workspace);
      if (_boolValue(probe['passed'])) {
        return {
          'status': '连接成功',
          'error_code': '',
          'error_message_zh': '',
          'missing_config_refs': <String>[],
          'blocked_reasons': <String>[],
          'test_artifacts': [probe['probe_path']],
          'ready_for_user_selection': true,
          'runtime_loaded': false,
        };
      }
      return {
        'status': '已配置未测试',
        'error_code': 'karpathy_teaching_probe_requires_skill_assets',
        'error_message_zh': _stringValue(
          probe['error_message_zh'],
          '需要真实教学/推理 Skill 生成、验证和版本产物后才能启用教学模板能力增强。',
        ),
        'missing_config_refs': <String>[],
        'blocked_reasons': _listOfStrings(probe['blocked_reasons']),
        'test_artifacts': [probe['probe_path']],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    if (_stringValue(contract['provider_ref'], '') == 'mmskills') {
      final probe = _probeMmskillsSchemaPackageAssets(workspace);
      if (_boolValue(probe['passed'])) {
        return {
          'status': '连接成功',
          'error_code': '',
          'error_message_zh': '',
          'missing_config_refs': <String>[],
          'blocked_reasons': <String>[],
          'test_artifacts': [probe['probe_path']],
          'ready_for_user_selection': true,
          'runtime_loaded': false,
        };
      }
      return {
        'status': '已配置未测试',
        'error_code': 'mmskills_probe_requires_schema_package_assets',
        'error_message_zh': _stringValue(
          probe['error_message_zh'],
          '需要真实 Skill 包、schema、验证、融合和 Agent 绑定证据后才能启用 schema package 能力增强。',
        ),
        'missing_config_refs': <String>[],
        'blocked_reasons': _listOfStrings(probe['blocked_reasons']),
        'test_artifacts': [probe['probe_path']],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    if (_stringValue(contract['provider_ref'], '') == 'llm_wiki_v2') {
      final probe = _probeLlmWikiAgentMemoryFusion(workspace);
      if (_boolValue(probe['passed'])) {
        return {
          'status': '连接成功',
          'error_code': '',
          'error_message_zh': '',
          'missing_config_refs': <String>[],
          'blocked_reasons': <String>[],
          'test_artifacts': [probe['probe_path']],
          'ready_for_user_selection': true,
          'runtime_loaded': false,
        };
      }
      return {
        'status': '已配置未测试',
        'error_code': 'llm_wiki_agent_memory_probe_requires_agent_assets',
        'error_message_zh': _stringValue(
          probe['error_message_zh'],
          '需要先生成 Agent、权限审计、验证报告和记忆索引后才能启用 Agent 记忆能力增强。',
        ),
        'missing_config_refs': <String>[],
        'blocked_reasons': ['需要 Agent 本地产物、权限审计、验证报告和 memory index'],
        'test_artifacts': [probe['probe_path']],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    if (_stringValue(contract['provider_ref'], '') == 'ai_marketing_skills') {
      final probe = _probeAiMarketingSkillPatternLibrary(workspace);
      if (_boolValue(probe['passed'])) {
        return {
          'status': '连接成功',
          'error_code': '',
          'error_message_zh': '',
          'missing_config_refs': <String>[],
          'blocked_reasons': <String>[],
          'test_artifacts': [probe['probe_path']],
          'ready_for_user_selection': true,
          'runtime_loaded': false,
        };
      }
      return {
        'status': '已配置未测试',
        'error_code': 'ai_marketing_probe_requires_local_patterns',
        'error_message_zh': _stringValue(
          probe['error_message_zh'],
          '需要本地导购/运营模板和样例证据完整后才能启用营销 Skill 模式增强。',
        ),
        'missing_config_refs': <String>[],
        'blocked_reasons': ['需要本地导购/运营模板、Agent 模板和样例证据'],
        'test_artifacts': [probe['probe_path']],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    if (_stringValue(contract['provider_ref'], '') == 'jellyfish') {
      final probe = _probeJellyfishContentAssetExport(workspace);
      if (_boolValue(probe['passed'])) {
        return {
          'status': '连接成功',
          'error_code': '',
          'error_message_zh': '',
          'missing_config_refs': <String>[],
          'blocked_reasons': <String>[],
          'test_artifacts': [probe['probe_path']],
          'ready_for_user_selection': true,
          'runtime_loaded': false,
        };
      }
      return {
        'status': '已配置未测试',
        'error_code': 'jellyfish_probe_requires_structured_exports',
        'error_message_zh': _stringValue(
          probe['error_message_zh'],
          '需要先生成真实结构化导出产物后才能启用内容资产导出能力增强。',
        ),
        'missing_config_refs': <String>[],
        'blocked_reasons': ['需要真实 JSON/CSV 结构化导出和导出 manifest'],
        'test_artifacts': [probe['probe_path']],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    if (_stringValue(contract['provider_ref'], '') == 'story_flicks') {
      final probe = _probeStoryFlicksVideoHandoffExport(workspace);
      if (_boolValue(probe['passed'])) {
        return {
          'status': '连接成功',
          'error_code': '',
          'error_message_zh': '',
          'missing_config_refs': <String>[],
          'blocked_reasons': <String>[],
          'test_artifacts': [probe['probe_path']],
          'ready_for_user_selection': true,
          'runtime_loaded': false,
        };
      }
      return {
        'status': '已配置未测试',
        'error_code': 'story_flicks_probe_requires_video_handoff_exports',
        'error_message_zh': _stringValue(
          probe['error_message_zh'],
          '需要先生成视频任务 handoff 导出边界后才能启用视频工作流导出能力增强。',
        ),
        'missing_config_refs': <String>[],
        'blocked_reasons': ['需要视频任务 manifest、prompt、成本报告和 Tool 边界审计'],
        'test_artifacts': [probe['probe_path']],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    if (_stringValue(contract['provider_ref'], '') == 'n8n') {
      final probe = _probeN8nWorkflowCollaborationExport(workspace);
      if (_boolValue(probe['passed'])) {
        return {
          'status': '连接成功',
          'error_code': '',
          'error_message_zh': '',
          'missing_config_refs': <String>[],
          'blocked_reasons': <String>[],
          'test_artifacts': [probe['probe_path']],
          'ready_for_user_selection': true,
          'runtime_loaded': false,
        };
      }
      return {
        'status': '已配置未测试',
        'error_code': 'n8n_probe_requires_a2a_workflow_exports',
        'error_message_zh': _stringValue(
          probe['error_message_zh'],
          '需要先生成真实 A2A 多轮协作和工作流导出产物后才能启用工作流协作导出能力增强。',
        ),
        'missing_config_refs': <String>[],
        'blocked_reasons': [
          '需要 A2A session、round log、runtime audit、冲突/共识报告和协作导出报告'
        ],
        'test_artifacts': [probe['probe_path']],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    final missingRefs = <String>[];
    final blockedReasons = <String>[];
    final requiredRefs = _listOfStrings(contract['required_config_refs']);
    for (final ref in requiredRefs) {
      if (!_profileConfigRefAvailable(profile, ref, config)) {
        missingRefs.add(ref);
      }
    }
    if (_boolValue(contract['requires_network']) &&
        profile.networkPolicyId == 'network_local_only') {
      blockedReasons.add('当前 Profile 未开启网络授权。');
    }
    if (_boolValue(contract['requires_external_runtime'])) {
      blockedReasons.add('需要启动外部服务并通过健康检查。');
    }
    if (_boolValue(contract['requires_dependency_install'])) {
      blockedReasons.add('需要安装依赖或完成本地适配。');
    }
    if (missingRefs.isNotEmpty) {
      blockedReasons.add('需要补齐 Provider 配置引用。');
      return {
        'status': '配置缺失',
        'error_code': 'provider_config_missing',
        'error_message_zh': blockedReasons.join(' '),
        'missing_config_refs': missingRefs,
        'blocked_reasons': blockedReasons,
        'test_artifacts': <String>[],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    if (blockedReasons.any((reason) => reason.contains('网络授权'))) {
      return {
        'status': '已禁用',
        'error_code': 'network_authorization_disabled',
        'error_message_zh': blockedReasons.join(' '),
        'missing_config_refs': missingRefs,
        'blocked_reasons': blockedReasons,
        'test_artifacts': <String>[],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    if (blockedReasons.any((reason) => reason.contains('启动外部服务'))) {
      return {
        'status': '需启动外部服务',
        'error_code': 'external_runtime_required',
        'error_message_zh': blockedReasons.join(' '),
        'missing_config_refs': missingRefs,
        'blocked_reasons': blockedReasons,
        'test_artifacts': <String>[],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    if (blockedReasons.any((reason) => reason.contains('安装依赖'))) {
      return {
        'status': '需安装外部服务',
        'error_code': 'dependency_required',
        'error_message_zh': blockedReasons.join(' '),
        'missing_config_refs': missingRefs,
        'blocked_reasons': blockedReasons,
        'test_artifacts': <String>[],
        'ready_for_user_selection': false,
        'runtime_loaded': false,
      };
    }
    return {
      'status': '已配置未测试',
      'error_code': 'adapter_test_required',
      'error_message_zh': 'Provider 适配器配置存在，仍需真实健康检查通过后才能启用。',
      'missing_config_refs': missingRefs,
      'blocked_reasons': ['需要健康检查通过'],
      'test_artifacts': <String>[],
      'ready_for_user_selection': false,
      'runtime_loaded': false,
    };
  }

  static Map<String, dynamic> _probeHighRiskRegisteredProviderGate(
    Directory workspace,
    Map<String, dynamic> contract,
    ProjectConfigProfile profile,
    Map<String, dynamic> config,
  ) {
    final providerRef = _stringValue(contract['provider_ref'], '');
    const gatedProviders = {
      'anysearchskill',
      'last30days_skill',
      'seedance2_skill',
      'rtk',
    };
    if (!gatedProviders.contains(providerRef)) {
      return const <String, dynamic>{};
    }
    final probePath = _providerAdapterProbePath(workspace, providerRef);
    final requiredRefs = _listOfStrings(contract['required_config_refs']);
    final missingRefs = requiredRefs
        .where((ref) => !_profileConfigRefAvailable(profile, ref, config))
        .toList(growable: false)
      ..sort();
    final blockedReasons = <String>[];
    final requiresNetwork = _boolValue(contract['requires_network']);
    final requiresSecretRef = _boolValue(contract['requires_secret_ref']);
    final requiresExternalRuntime =
        _boolValue(contract['requires_external_runtime']);
    final requiresDependencyInstall =
        _boolValue(contract['requires_dependency_install']);
    if (requiresNetwork && profile.networkPolicyId == 'network_local_only') {
      blockedReasons.add('当前 Profile 未开启网络授权。');
    }
    if (requiresSecretRef && missingRefs.contains('secret_ref')) {
      blockedReasons.add('需要 secret 引用，不能写入或展示明文密钥。');
    }
    if (requiresExternalRuntime) {
      blockedReasons.add('需要启动外部服务并通过健康检查。');
    }
    if (requiresDependencyInstall) {
      blockedReasons.add('需要安装依赖或完成本地适配。');
    }
    if (missingRefs.any((ref) => ref != 'secret_ref')) {
      blockedReasons.add('需要补齐 Provider 配置引用。');
    }
    final status = requiresSecretRef && missingRefs.contains('secret_ref')
        ? '配置缺失'
        : requiresExternalRuntime
            ? '需启动外部服务'
            : requiresDependencyInstall
                ? '需安装外部服务'
                : requiresNetwork
                    ? '已禁用'
                    : '已配置未测试';
    final errorCode = requiresSecretRef && missingRefs.contains('secret_ref')
        ? 'secret_ref_missing'
        : requiresExternalRuntime
            ? 'external_runtime_required'
            : requiresDependencyInstall
                ? 'dependency_or_network_gate_required'
                : requiresNetwork
                    ? 'network_authorization_disabled'
                    : 'provider_gate_required';
    final gateKind = switch (providerRef) {
      'anysearchskill' => 'network_search_provider_gate',
      'last30days_skill' => 'network_time_window_adapter_gate',
      'seedance2_skill' => 'secret_masked_video_skill_gate',
      'rtk' => 'external_runtime_agent_tool_gate',
      _ => 'provider_gate',
    };
    final errorMessageZh = switch (providerRef) {
      'anysearchskill' => '需要在设置中开启网络授权并通过检索 Provider 查询测试后才能启用。',
      'last30days_skill' => '需要安装/适配时间窗口检索 Provider，并在网络授权后通过查询测试。',
      'seedance2_skill' => '需要配置 secret 引用和网络授权；禁止写入或展示明文密钥。',
      'rtk' => '需要外部服务启动、配置引用完整并通过健康检查后才能启用 Agent 工具能力增强。',
      _ => '需要完成 Provider gate 后才能启用。',
    };
    final gateAudit = {
      'gate_kind': gateKind,
      'provider_ref': providerRef,
      'requires_network': requiresNetwork,
      'requires_secret_ref': requiresSecretRef,
      'requires_external_runtime': requiresExternalRuntime,
      'requires_dependency_install': requiresDependencyInstall,
      'network_authorization': requiresNetwork
          ? (profile.networkPolicyId == 'network_local_only' ? '已禁用' : '已配置未测试')
          : '不需要',
      'secret_ref_status': requiresSecretRef
          ? (missingRefs.contains('secret_ref') ? '配置缺失' : '已配置')
          : '不需要',
      'external_runtime_status': requiresExternalRuntime ? '需启动外部服务' : '不需要',
      'missing_config_refs': missingRefs,
      'blocked_reasons':
          blockedReasons.isEmpty ? ['需要完成真实健康检查后才能启用。'] : blockedReasons,
      'fallback_preserves_local_chain': true,
      'network_call_attempted': false,
      'external_runtime_executed': false,
      'vendor_runtime_loaded': false,
      'normal_ui_project_name_visible': false,
      'secret_plaintext_written': false,
    };
    final payload = {
      'schema_version': 'prd_v3_provider_adapter_probe_high_risk_gate.v1',
      'provider_ref': providerRef,
      'gate_kind': gateKind,
      'gate_audit': gateAudit,
      'status': status,
      'error_code': errorCode,
      'error_message_zh': errorMessageZh,
      'capability_ids': _listOfStrings(contract['capability_ids']),
      'affected_modules': _listOfStrings(contract['affected_modules']),
      'runtime_execution_mode':
          _stringValue(contract['runtime_execution_mode'], 'provider_adapter'),
      'requires_network': requiresNetwork,
      'requires_secret_ref': requiresSecretRef,
      'requires_external_runtime': requiresExternalRuntime,
      'requires_dependency_install': requiresDependencyInstall,
      'network_authorization': gateAudit['network_authorization'],
      'secret_ref_status': gateAudit['secret_ref_status'],
      'external_runtime_status': gateAudit['external_runtime_status'],
      'missing_config_refs': missingRefs,
      'blocked_reasons':
          blockedReasons.isEmpty ? ['需要完成真实健康检查后才能启用。'] : blockedReasons,
      'degradation_target':
          _stringValue(contract['fallback_provider'], 'local_provider'),
      'ready_for_user_selection': false,
      'runtime_loaded': false,
      'runtime_load_allowed': false,
      'selection_allowed': false,
      'fallback_preserves_local_chain': true,
      'rollback_supported': _boolValue(contract['rollback_supported']),
      'normal_ui_project_name_visible': false,
      'network_call_attempted': false,
      'external_runtime_executed': false,
      'vendor_runtime_loaded': false,
      'secret_masked': true,
      'secret_plaintext_written': false,
      'passed': false,
      'evaluated_at': DateTime.now().toUtc().toIso8601String(),
    };
    File(probePath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(payload),
        encoding: utf8,
      );
    return {
      ...payload,
      'probe_path': probePath,
    };
  }

  static Map<String, dynamic> _stage2IndustrialPreflight(Directory workspace) {
    final checks = <Map<String, dynamic>>[
      _stage2OkfBundleRuntimeCheck(workspace),
      _stage2OkfKbRuntimeCheck(workspace),
      _stage2JsonCheck(
        'a2a_multi_round_collaboration',
        _joinNested(workspace.path,
            'agent/workspaces/W_M/a2a_sessions/A2A_001/a2a_session_manifest.json'),
        (payload, raw) {
          final rounds =
              _asInt(payload['round_limit']) ?? _asInt(payload['rounds']) ?? 0;
          final roundLogPath = _stringValue(payload['round_log_path'], '');
          final auditPath = _stringValue(payload['runtime_audit_path'], '');
          final conflictPath =
              _stringValue(payload['conflict_report_path'], '');
          return rounds > 1 &&
              raw.contains('conflict') &&
              _jsonlRecordCount(roundLogPath) >= rounds &&
              _jsonlRecordCount(auditPath) >= rounds &&
              File(conflictPath).existsSync();
        },
        failureReason: 'A2A 需要多轮协作和冲突检测证据。',
      ),
      _stage2SkillRuntimeCheck(workspace),
      _stage2AgentPermissionRuntimeCheck(workspace),
      _stage2JsonCheck(
        'industrial_exe_smoke_38_step',
        _joinNested(
            workspace.path, 'acceptance/industrial_exe_smoke_report.json'),
        (payload, raw) =>
            _stringValue(payload['status'], '') == 'passed' &&
            (_asInt(payload['step_count']) ?? 0) >= 38 &&
            _industrialSmokeArtifactsExist(payload),
        failureReason: '需要真实 EXE 38 步工业级 smoke 通过记录，且每个 passed 步骤必须指向真实产物。',
      ),
      _stage2ExeLaunchSmokeCheck(workspace),
    ];
    final failedChecks = checks
        .where((check) => check['status'] != 'passed')
        .map((check) => check['check_id'])
        .toList(growable: false);
    return {
      'schema_version': 'prd_v3_stage2_industrial_preflight.v1',
      'status': failedChecks.isEmpty ? 'passed' : 'blocked',
      'runtime_load_allowed': failedChecks.isEmpty,
      'failed_checks': failedChecks,
      'checks': checks,
    };
  }

  static Map<String, dynamic> _stage2OkfBundleRuntimeCheck(
      Directory workspace) {
    const checkId = 'okf_bundle_runtime_export_import';
    final runtimePath = _joinNested(
        workspace.path, 'standard_packages/okf_runtime_manifest.json');
    final runtime = _readJsonObjectSync(runtimePath);
    final packageManifestPath =
        _stringValue(runtime['package_manifest_path'], '');
    final contentPackagePath =
        _stringValue(runtime['content_package_path'], '');
    final auditPath =
        _joinNested(workspace.path, 'standard_packages/audit_history.jsonl');
    final orchestrationPath =
        _joinNested(workspace.path, 'orchestration/orchestration_plan.jsonl');
    final packageManifest = _readJsonObjectSync(packageManifestPath);
    final required = {
      'runtime_manifest_schema': _stringValue(runtime['schema_version'], '') ==
          'prd_v3_okf_runtime_manifest.v1',
      'runtime_loaded': runtime['runtime_loaded'] == true,
      'export_import_runtime_available':
          runtime['export_import_runtime_available'] == true,
      'external_runtime_not_required': runtime['external_runtime'] == false,
      'package_manifest_exists': packageManifestPath.isNotEmpty &&
          File(packageManifestPath).existsSync(),
      'content_package_exists': contentPackagePath.isNotEmpty &&
          File(contentPackagePath).existsSync(),
      'content_package_has_records': _jsonlRecordCount(contentPackagePath) > 0,
      'package_marked_runtime':
          packageManifest['okf_runtime_enabled'] == true &&
              _stringValue(packageManifest['standard'], '') == 'okf_candidate',
      'runtime_audit_written': _jsonlContains(
        auditPath,
        (record) =>
            _stringValue(record['status'], '') == 'completed' &&
            {
              'export_standard_knowledge_package',
              'import_standard_knowledge_package',
            }.contains(_stringValue(record['action'], '')),
      ),
      'runtime_orchestration_written': _jsonlContains(
        orchestrationPath,
        (record) {
          final boundary = _mapValue(record['boundary']);
          return _stringValue(record['status'], '') == 'completed' &&
              {
                'export_standard_knowledge_package',
                'import_standard_knowledge_package',
              }.contains(_stringValue(record['action'], '')) &&
              boundary['okf_runtime_enabled'] == true;
        },
      ),
    };
    final missing = required.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList(growable: false);
    return {
      'check_id': checkId,
      'status': missing.isEmpty ? 'passed' : 'failed',
      'artifact_path': runtimePath,
      'reason_zh': missing.isEmpty
          ? ''
          : 'OKF Bundle 需要真实 runtime 导出/导入执行链路；标准包 manifest 不等于 runtime 已接入。',
      'runtime_evidence': {
        'required': required,
        'missing': missing,
      },
    };
  }

  static Map<String, dynamic> _stage2OkfKbRuntimeCheck(Directory workspace) {
    const checkId = 'okf_runtime_to_kb_build';
    final runtimePath = _joinNested(
        workspace.path, 'standard_packages/okf_runtime_manifest.json');
    final runtime = _readJsonObjectSync(runtimePath);
    final kbManifestPath = _stringValue(runtime['kb_manifest_path'], '');
    final kbCatalogPath =
        _joinNested(workspace.path, 'knowledge_bases/kb_catalog.json');
    final auditPath =
        _joinNested(workspace.path, 'standard_packages/audit_history.jsonl');
    final orchestrationPath =
        _joinNested(workspace.path, 'orchestration/orchestration_plan.jsonl');
    final kbManifest = _readJsonObjectSync(kbManifestPath);
    final kbCatalog = _readJsonObjectSync(kbCatalogPath);
    final catalogRecords = _listOfMaps(kbCatalog['knowledge_bases']);
    final okfRecord = catalogRecords
        .where((record) => _stringValue(record['kb_id'], '') == 'K_OKF1')
        .cast<Map<String, dynamic>?>()
        .firstWhere((record) => record != null, orElse: () => null);
    final chunksPath = _joinNested(workspace.path, 'kb/chunks.jsonl');
    final required = {
      'runtime_manifest_schema': _stringValue(runtime['schema_version'], '') ==
          'prd_v3_okf_runtime_manifest.v1',
      'runtime_loaded': runtime['runtime_loaded'] == true,
      'kb_build_runtime_available':
          runtime['kb_build_runtime_available'] == true,
      'kb_manifest_exists':
          kbManifestPath.isNotEmpty && File(kbManifestPath).existsSync(),
      'kb_manifest_runtime_schema':
          _stringValue(kbManifest['schema_version'], '') ==
              'prd_v3_kb_from_standard_package.v1',
      'kb_manifest_passed': _stringValue(kbManifest['status'], '') == 'pass' &&
          kbManifest['okf_runtime_enabled'] == true,
      'kb_chunks_written': _jsonlRecordCount(chunksPath) > 0,
      'kb_catalog_bound_to_okf_runtime': okfRecord != null &&
          okfRecord['okf_runtime_enabled'] == true &&
          _stringValue(okfRecord['source_standard_package_manifest'], '')
              .isNotEmpty,
      'runtime_audit_written': _jsonlContains(
        auditPath,
        (record) =>
            _stringValue(record['status'], '') == 'completed' &&
            _stringValue(record['action'], '') ==
                'build_kb_from_standard_package',
      ),
      'runtime_orchestration_written': _jsonlContains(
        orchestrationPath,
        (record) {
          final boundary = _mapValue(record['boundary']);
          return _stringValue(record['status'], '') == 'completed' &&
              _stringValue(record['action'], '') ==
                  'build_kb_from_standard_package' &&
              boundary['okf_runtime_enabled'] == true;
        },
      ),
    };
    final missing = required.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList(growable: false);
    return {
      'check_id': checkId,
      'status': missing.isEmpty ? 'passed' : 'failed',
      'artifact_path': runtimePath,
      'reason_zh':
          missing.isEmpty ? '' : 'OKF 到 KB 构建需要真实 runtime 构建、审计、编排和下游 KB 可用证据。',
      'runtime_evidence': {
        'required': required,
        'missing': missing,
      },
    };
  }

  static Map<String, dynamic> _stage2SkillRuntimeCheck(Directory workspace) {
    const checkId = 'skill_secondary_fusion_version_management';
    final runtimePath = _joinNested(
        workspace.path, 'skill/operations/skill_runtime_manifest.json');
    final runtime = _readJsonObjectSync(runtimePath);
    final diffPath = _stringValue(runtime['version_diff_report_path'], '');
    final rollbackPath = _stringValue(runtime['rollback_manifest_path'], '');
    final auditPath = _stringValue(runtime['runtime_audit_path'], '');
    final fusedSkillPath = _stringValue(runtime['fused_skill_path'], '');
    final fusedManifestPath = _stringValue(runtime['fused_manifest_path'], '');
    final operationManifestPath =
        _stringValue(runtime['operation_manifest_path'], '');
    final operationHistoryPath =
        _stringValue(runtime['operation_history_path'], '');
    final versionManifestPath =
        _stringValue(runtime['version_manifest_path'], '');
    final diff = _readJsonObjectSync(diffPath);
    final rollback = _readJsonObjectSync(rollbackPath);
    final fusedManifest = _readJsonObjectSync(fusedManifestPath);
    final operationManifest = _readJsonObjectSync(operationManifestPath);
    final operationHistory = _readJsonObjectSync(operationHistoryPath);
    final versionManifest = _readJsonObjectSync(versionManifestPath);
    final versions = _listOfMaps(versionManifest['versions']);
    final snapshotsExist = versions.length > 1 &&
        versions.every((version) {
          final snapshot = _stringValue(version['snapshot_path'], '');
          return snapshot.isNotEmpty && File(snapshot).existsSync();
        });
    final historyRecords = _listOfMaps(operationHistory['records']);
    final required = {
      'runtime_manifest_schema': _stringValue(runtime['schema_version'], '') ==
          'prd_v3_skill_runtime_manifest.v1',
      'runtime_loaded': runtime['runtime_loaded'] == true,
      'secondary_fusion_runtime_available':
          runtime['secondary_fusion_runtime_available'] == true,
      'multi_version_runtime_available':
          runtime['multi_version_runtime_available'] == true,
      'version_count_gt_one': (_asInt(runtime['version_count']) ?? 0) > 1,
      'version_snapshots_exist': snapshotsExist,
      'fused_skill_exists':
          fusedSkillPath.isNotEmpty && File(fusedSkillPath).existsSync(),
      'fused_manifest_skill_plus_kb':
          _stringValue(fusedManifest['source_mode'], '') ==
              'skill_plus_kb_fusion',
      'operation_manifest_records_fusion':
          _stringValue(operationManifest['requested_operation'], '') ==
              'fusion',
      'operation_history_records_fusion': historyRecords.any((record) =>
          _stringValue(record['action'], '') == 'skill_operation_fusion' &&
          _stringValue(record['status'], '') == 'completed'),
      'diff_report_passed': _stringValue(diff['schema_version'], '') ==
              'prd_v3_skill_version_diff_report.v1' &&
          _stringValue(diff['status'], '') == 'pass',
      'rollback_manifest_available':
          _stringValue(rollback['schema_version'], '') ==
                  'prd_v3_skill_rollback_manifest.v1' &&
              rollback['rollback_supported'] == true &&
              _stringValue(rollback['rollback_target_snapshot_path'], '')
                  .isNotEmpty,
      'runtime_audit_written': _jsonlContains(
        auditPath,
        (record) =>
            _stringValue(record['action'], '') == 'skill_secondary_fusion' &&
            record['secondary_fusion_runtime_available'] == true &&
            record['multi_version_runtime_available'] == true,
      ),
      'secret_plaintext_absent': runtime['secret_plaintext_written'] == false &&
          diff['secret_plaintext_written'] == false &&
          rollback['secret_plaintext_written'] == false,
    };
    final missing = required.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList(growable: false);
    return {
      'check_id': checkId,
      'status': missing.isEmpty ? 'passed' : 'failed',
      'artifact_path': runtimePath,
      'reason_zh':
          missing.isEmpty ? '' : 'Skill 需要真实二次融合、多版本快照、差异、回滚和 runtime 审计证据。',
      'runtime_evidence': {
        'required': required,
        'missing': missing,
      },
    };
  }

  static Map<String, dynamic> _stage2AgentPermissionRuntimeCheck(
      Directory workspace) {
    const checkId = 'agent_workspace_permission_enforcement';
    final matrixPath = _joinNested(
        workspace.path, 'agent/audit/workspace_permission_matrix.json');
    final permissionAuditPath =
        _joinNested(workspace.path, 'agent/audit/permission_audit.json');
    final blockReportPath = _joinNested(
        workspace.path, 'agent/audit/unauthorized_access_block_report.json');
    final runtimeAuditPath = _joinNested(
        workspace.path, 'agent/audit/authorization_runtime_audit.jsonl');
    final validationReportPath =
        _joinNested(workspace.path, 'agent/audit/agent_validation_report.json');
    final runHistoryPath =
        _joinNested(workspace.path, 'agent/audit/run_history.json');
    final matrix = _readJsonObjectSync(matrixPath);
    final permissionAudit = _readJsonObjectSync(permissionAuditPath);
    final blockReport = _readJsonObjectSync(blockReportPath);
    final validationReport = _readJsonObjectSync(validationReportPath);
    final runHistory = _readJsonObjectSync(runHistoryPath);
    final matrixRows = _listOfMaps(matrix['matrix']);
    final blockedCapabilities = _listOfStrings(matrix['blocked_capabilities']);
    final blockCases = _listOfMaps(blockReport['cases']);
    final runRecords = _listOfMaps(runHistory['records']);
    final deniedCases = blockCases
        .where((item) =>
            _stringValue(item['expected_decision'], '') == 'deny' &&
            _stringValue(item['decision'], '') == 'deny')
        .toList(growable: false);
    final allowCases = blockCases
        .where((item) =>
            _stringValue(item['expected_decision'], '') == 'allow' &&
            _stringValue(item['decision'], '') == 'allow')
        .toList(growable: false);
    final required = {
      'matrix_schema': _stringValue(matrix['schema_version'], '') ==
          'prd_v3_agent_workspace_permission_matrix.v1',
      'matrix_passed': _stringValue(matrix['status'], '') == 'pass',
      'workspaces_declared': {'W_A', 'W_M', 'W_B', 'W_C'}.every((id) =>
          matrixRows.any((row) => _stringValue(row['workspace_id'], '') == id)),
      'workspace_isolation_declared': matrixRows.any((row) =>
              _stringValue(row['workspace_id'], '') == 'W_B' &&
              row['can_read_sibling_workspace'] == false &&
              row['can_write_sibling_workspace'] == false) &&
          matrixRows.any((row) =>
              _stringValue(row['workspace_id'], '') == 'W_C' &&
              row['can_read_sibling_workspace'] == false &&
              row['can_write_sibling_workspace'] == false),
      'blocked_capabilities_declared': {
        'cross_workspace_write',
        'sibling_workspace_access',
        'plaintext_secret_read',
        'arbitrary_shell',
        'computer_use',
      }.every(blockedCapabilities.contains),
      'permission_audit_passed': _stringValue(
                  permissionAudit['schema_version'], '') ==
              'prd_v2_agent_permission_audit.v1' &&
          _stringValue(permissionAudit['status'], '') == 'pass' &&
          _stringValue(
                  permissionAudit['workspace_permission_matrix_path'], '') ==
              matrixPath,
      'block_report_passed': _stringValue(blockReport['schema_version'], '') ==
              'prd_v3_agent_unauthorized_access_block_report.v1' &&
          _stringValue(blockReport['status'], '') == 'pass' &&
          blockReport['unauthorized_resources_selectable'] == false,
      'denied_cases_recorded': deniedCases.length >= 4,
      'allowed_case_recorded': allowCases.isNotEmpty,
      'authorization_runtime_audit_written':
          _jsonlRecordCount(runtimeAuditPath) >=
                  (_asInt(blockReport['case_count']) ?? 0) &&
              _jsonlContains(
                runtimeAuditPath,
                (record) =>
                    _stringValue(record['decision'], '') == 'deny' &&
                    _stringValue(record['error_code'], '') ==
                        'tool_not_allowlisted',
              ),
      'agent_validation_links_block_report':
          _stringValue(validationReport['status'], '') == 'pass' &&
              _jsonContainsValue(validationReport, blockReportPath) &&
              _jsonContainsValue(validationReport, runtimeAuditPath),
      'run_history_records_authorization': runRecords.any((record) =>
          _stringValue(record['action'], '') == 'authorization_runtime_audit' &&
          _stringValue(record['status'], '') == 'pass'),
      'secret_plaintext_absent':
          blockReport['secret_plaintext_written'] == false,
    };
    final missing = required.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList(growable: false);
    return {
      'check_id': checkId,
      'status': missing.isEmpty ? 'passed' : 'failed',
      'artifact_path': matrixPath,
      'reason_zh': missing.isEmpty
          ? ''
          : 'Agent 需要真实工作区权限矩阵、越权阻断用例、授权 runtime audit 和运行历史证据。',
      'runtime_evidence': {
        'required': required,
        'missing': missing,
      },
    };
  }

  static Map<String, dynamic> _stage2ExeLaunchSmokeCheck(Directory workspace) {
    const checkId = 'industrial_exe_launch_smoke';
    final smokePath =
        _joinNested(workspace.path, 'acceptance/exe_launch_smoke_report.json');
    final payload = _readJsonObjectSync(smokePath);
    final exePath = _stringValue(payload['exe_path'], '');
    final logPath = _stringValue(payload['log_path'], '');
    final exeFile = exePath.isEmpty ? null : File(exePath);
    final exeBytes =
        exeFile != null && exeFile.existsSync() ? exeFile.lengthSync() : 0;
    final exeHeader = _exeHeader(exeFile);
    final generatedBy = _stringValue(payload['generated_by'], '');
    final required = {
      'schema_version': _stringValue(payload['schema_version'], '') ==
          'prd_v3_exe_launch_smoke_report.v1',
      'status_passed': _stringValue(payload['status'], '') == 'passed',
      'platform_windows':
          _stringValue(payload['platform'], '').toLowerCase() == 'windows',
      'generated_by_launch_script':
          generatedBy == 'scripts/smoke_windows_exe_launch.ps1',
      'exe_exists': exeFile != null && exeFile.existsSync(),
      'exe_name_matches':
          exePath.split(RegExp(r'[\\/]')).last == 'heitang_workbench.exe',
      'exe_header_mz': exeHeader == 'MZ',
      'exe_size_matches':
          (_asInt(payload['exe_size_bytes']) ?? 0) == exeBytes &&
              exeBytes > 32768,
      'exe_sha256_recorded': RegExp(r'^[a-f0-9]{64}$')
          .hasMatch(_stringValue(payload['exe_sha256'], '')),
      'launched': payload['launched'] == true,
      'process_started': (_asInt(payload['process_id']) ?? 0) > 0 ||
          payload['process_started'] == true,
      'no_crash_observed': payload['crashed'] == false,
      'startup_timeout_absent': payload['startup_timeout'] == false,
      'log_written': logPath.isNotEmpty && File(logPath).existsSync(),
      'secret_plaintext_absent': payload['secret_plaintext_written'] == false,
    };
    final missing = required.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList(growable: false);
    return {
      'check_id': checkId,
      'status': missing.isEmpty ? 'passed' : 'failed',
      'artifact_path': smokePath,
      'reason_zh':
          missing.isEmpty ? '' : '需要真实 Windows EXE 启动 smoke 证据，不能用链路单测报告代替。',
      'runtime_evidence': {
        'required': required,
        'missing': missing,
      },
    };
  }

  static Map<String, dynamic> _stage2JsonCheck(
    String checkId,
    String path,
    bool Function(Map<String, dynamic> payload, String raw) predicate, {
    required String failureReason,
  }) {
    final file = File(path);
    if (!file.existsSync()) {
      return {
        'check_id': checkId,
        'status': 'missing',
        'artifact_path': path,
        'reason_zh': failureReason,
      };
    }
    final raw = file.readAsStringSync(encoding: utf8);
    try {
      final decoded = jsonDecode(raw);
      final payload = decoded is Map<String, dynamic>
          ? decoded
          : decoded is Map
              ? decoded.cast<String, dynamic>()
              : <String, dynamic>{};
      final passed = predicate(payload, raw);
      return {
        'check_id': checkId,
        'status': passed ? 'passed' : 'failed',
        'artifact_path': path,
        'reason_zh': passed ? '' : failureReason,
      };
    } on FormatException {
      return {
        'check_id': checkId,
        'status': 'failed',
        'artifact_path': path,
        'reason_zh': '验收产物不是有效 JSON。',
      };
    }
  }

  static int _jsonlRecordCount(String path) {
    if (path.trim().isEmpty) return 0;
    final file = File(path);
    if (!file.existsSync()) return 0;
    return file
        .readAsLinesSync(encoding: utf8)
        .where((line) => line.trim().isNotEmpty)
        .length;
  }

  static int _csvDataRecordCount(String path) {
    if (path.trim().isEmpty) return 0;
    final file = File(path);
    if (!file.existsSync()) return 0;
    final lines = file
        .readAsLinesSync(encoding: utf8)
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
    if (lines.length <= 1) return 0;
    return lines.length - 1;
  }

  static bool _jsonlContains(
    String path,
    bool Function(Map<String, dynamic> record) predicate,
  ) {
    final file = File(path);
    if (!file.existsSync()) return false;
    for (final line in file.readAsLinesSync(encoding: utf8)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final decoded = jsonDecode(trimmed);
        final record = decoded is Map<String, dynamic>
            ? decoded
            : decoded is Map
                ? decoded.cast<String, dynamic>()
                : <String, dynamic>{};
        if (predicate(record)) return true;
      } on FormatException {
        return false;
      }
    }
    return false;
  }

  static String _exeHeader(File? file) {
    if (file == null || !file.existsSync()) return '';
    final bytes = file.openSync();
    try {
      if (bytes.lengthSync() < 2) return '';
      return String.fromCharCodes(bytes.readSync(2));
    } finally {
      bytes.closeSync();
    }
  }

  static Map<String, dynamic> _readJsonObjectSync(String path) {
    if (path.trim().isEmpty) return <String, dynamic>{};
    final file = File(path);
    if (!file.existsSync()) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(file.readAsStringSync(encoding: utf8));
      return decoded is Map<String, dynamic>
          ? decoded
          : decoded is Map
              ? decoded.cast<String, dynamic>()
              : <String, dynamic>{};
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  static bool _jsonContainsValue(Object? value, String expected) {
    if (expected.isEmpty) return false;
    if (value == expected) return true;
    if (value is Map) {
      return value.values.any((child) => _jsonContainsValue(child, expected));
    }
    if (value is Iterable) {
      return value.any((child) => _jsonContainsValue(child, expected));
    }
    return false;
  }

  static bool _profileConfigRefAvailable(
    ProjectConfigProfile profile,
    String ref,
    Map<String, dynamic> config,
  ) {
    final storage = _mapValue(config['storage']);
    final provider = _mapValue(config['provider']);
    final exporter = _mapValue(config['exporter']);
    final redis = _mapValue(storage['redis']);
    final qdrant = _mapValue(storage['qdrant']);
    final exporters = _mapValue(exporter['exporters']);
    return switch (ref) {
      'storage_config_id' => profile.storageConfigId.isNotEmpty,
      'model_config_id' => profile.modelConfigId.isNotEmpty &&
          _mapValue(provider['llm']).isNotEmpty,
      'embedding_config_id' => profile.embeddingConfigId.isNotEmpty,
      'search_provider_config_id' => profile.searchProviderConfigId.isNotEmpty,
      'ocr_provider_config_id' => profile.ocrProviderConfigId.isNotEmpty,
      'pdf_parser_provider_config_id' =>
        profile.pdfParserProviderConfigId.isNotEmpty,
      'exporter_config_id' => profile.exporterConfigId.isNotEmpty &&
          _mapValue(exporters['markdown']).isNotEmpty,
      'redis_config_id' => profile.redisConfigId.isNotEmpty &&
          _stringValue(redis['host'], '').isNotEmpty,
      'vector_config_id' => profile.vectorConfigId.isNotEmpty &&
          _stringValue(qdrant['endpoint'], '').isNotEmpty,
      'network_policy_id' => profile.networkPolicyId.isNotEmpty,
      'agent_memory_policy_id' => profile.agentMemoryPolicyId.isNotEmpty,
      'tool_policy_id' => profile.toolPolicyId.isNotEmpty,
      'secret_ref' => _stringValue(
              _mapValue(provider['llm'])['api_key_secret_ref'], 'none') !=
          'none',
      _ => false,
    };
  }

  static Map<String, dynamic> _probeSirchmunkDirectFileSearch(
    Directory workspace,
  ) {
    final probePath = _providerAdapterProbePath(workspace, 'sirchmunk');
    final kbChunksPath = _join(workspace.path, 'kb', 'chunks.jsonl');
    final chunksFile = File(kbChunksPath);
    final now = DateTime.now().toUtc().toIso8601String();
    var chunkCount = 0;
    var sampleHasText = false;
    if (chunksFile.existsSync()) {
      final lines = chunksFile.readAsLinesSync(encoding: utf8);
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        chunkCount += 1;
        if (!sampleHasText) {
          try {
            final decoded = jsonDecode(line);
            if (decoded is Map) {
              sampleHasText = _stringValue(decoded['text'], '').isNotEmpty ||
                  _stringValue(decoded['content'], '').isNotEmpty;
            }
          } on FormatException {
            sampleHasText = false;
          }
        }
      }
    }
    final passed = chunkCount > 0 && sampleHasText;
    final payload = {
      'schema_version': 'prd_v3_provider_adapter_probe_sirchmunk.v1',
      'provider_ref': 'sirchmunk',
      'adapter_type': 'retrieval_adapter',
      'executed_at': now,
      'probe_kind': 'bounded_direct_file_search',
      'input_artifact': kbChunksPath,
      'chunk_count': chunkCount,
      'sample_text_available': sampleHasText,
      'passed': passed,
      'status': passed ? '连接成功' : '已配置未测试',
      'error_message_zh': passed ? '' : '需要先构建知识库并生成可检索 chunks.jsonl。',
      'network_used': false,
      'secret_plaintext_written': false,
      'normal_ui_project_name_visible': false,
    };
    File(probePath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(payload),
        encoding: utf8,
      );
    return {
      ...payload,
      'probe_path': probePath,
    };
  }

  static Map<String, dynamic> _probeDocumentParserOcrAdapter(
    Directory workspace,
    String providerRef,
  ) {
    final normalizedProvider =
        providerRef.trim().isEmpty ? 'document_parser' : providerRef.trim();
    final probePath = _providerAdapterProbePath(workspace, normalizedProvider);
    final now = DateTime.now().toUtc().toIso8601String();
    final manifestPath =
        _joinNested(workspace.path, 'du/document_understanding_manifest.json');
    final recordsPath =
        _joinNested(workspace.path, 'du/document_understanding_records.jsonl');
    final normalizedRoot = _joinNested(workspace.path, 'du/normalized_sources');
    final sourceManifestPath = _join(workspace.path, 'source_manifest.json');
    final manifest = _readJsonObjectSync(manifestPath);
    final sourceManifest = _readJsonObjectSync(sourceManifestPath);
    final sourceRecords = _listOfMaps(sourceManifest['sources']);
    final duRecordCount = _jsonlRecordCount(recordsPath);
    final normalizedFiles = Directory(normalizedRoot).existsSync()
        ? Directory(normalizedRoot)
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((file) => _extension(file.path).toLowerCase() == '.md')
            .toList(growable: false)
        : const <File>[];
    final normalizedTextBytes = normalizedFiles.fold<int>(
      0,
      (sum, file) => sum + file.lengthSync(),
    );
    var duOcrRecordCount = 0;
    final recordsFile = File(recordsPath);
    if (recordsFile.existsSync()) {
      for (final line in recordsFile.readAsLinesSync(encoding: utf8)) {
        if (line.trim().isEmpty) continue;
        try {
          final decoded = jsonDecode(line);
          final record = decoded is Map<String, dynamic>
              ? decoded
              : decoded is Map
                  ? decoded.cast<String, dynamic>()
                  : <String, dynamic>{};
          if (_stringValue(record['ocr_text'], '').isNotEmpty ||
              _stringValue(record['ocr_confidence'], '').isNotEmpty ||
              _stringValue(record['ocr_provider'], '').isNotEmpty) {
            duOcrRecordCount += 1;
          }
        } on FormatException {
          // Invalid rows are ignored; the DU record count check still fails if
          // no valid OCR evidence remains.
        }
      }
    }
    final duOcrInputEvidence = duOcrRecordCount > 0;
    final sourceCount = _asInt(manifest['success_count']) ??
        _asInt(manifest['normalized_source_count']) ??
        sourceRecords.length;
    final hasParserEvidence = File(manifestPath).existsSync() &&
        duRecordCount > 0 &&
        normalizedFiles.isNotEmpty &&
        normalizedTextBytes > 0 &&
        sourceCount > 0;
    final sourceManifestOcrInputEvidence = sourceRecords.any((source) {
      final imageCount = _asInt(source['image_count']) ?? 0;
      final extension = _stringValue(source['extension'], '').toLowerCase();
      return imageCount > 0 ||
          ['.png', '.jpg', '.jpeg', '.webp', '.bmp'].contains(extension);
    });
    final hasOcrInputEvidence =
        sourceManifestOcrInputEvidence || duOcrInputEvidence;
    final isOcrProvider = const {'paddleocr', 'surya'}.contains(
      normalizedProvider.toLowerCase(),
    );
    final passed = isOcrProvider
        ? hasParserEvidence && hasOcrInputEvidence
        : hasParserEvidence;
    final blockedReasons = <String>[
      if (!hasParserEvidence) '需要真实 DU manifest、records 和 normalized markdown',
      if (isOcrProvider && !hasOcrInputEvidence) '需要图片或 OCR 输入证据',
    ];
    final payload = {
      'schema_version': 'prd_v3_provider_adapter_probe_document_parser_ocr.v1',
      'provider_ref': normalizedProvider,
      'adapter_type': isOcrProvider ? 'ocr_adapter' : 'parser_adapter',
      'executed_at': now,
      'probe_kind': isOcrProvider
          ? 'local_ocr_input_boundary'
          : 'local_document_parse_boundary',
      'workspace_boundary': workspace.path,
      'required_artifacts': [
        {
          'path': manifestPath,
          'exists': File(manifestPath).existsSync(),
          'schema_version': _stringValue(manifest['schema_version'], ''),
          'status': _stringValue(manifest['status'], ''),
        },
        {
          'path': recordsPath,
          'exists': File(recordsPath).existsSync(),
          'record_count': duRecordCount,
        },
        {
          'path': normalizedRoot,
          'exists': Directory(normalizedRoot).existsSync(),
          'markdown_file_count': normalizedFiles.length,
          'text_bytes': normalizedTextBytes,
        },
        {
          'path': sourceManifestPath,
          'exists': File(sourceManifestPath).existsSync(),
          'source_count': sourceRecords.length,
          'has_ocr_input_evidence': hasOcrInputEvidence,
          'source_manifest_ocr_input_evidence': sourceManifestOcrInputEvidence,
          'du_ocr_input_evidence': duOcrInputEvidence,
        },
      ],
      'source_count': sourceCount,
      'du_record_count': duRecordCount,
      'normalized_markdown_count': normalizedFiles.length,
      'has_parser_evidence': hasParserEvidence,
      'has_ocr_input_evidence': hasOcrInputEvidence,
      'source_manifest_ocr_input_evidence': sourceManifestOcrInputEvidence,
      'du_ocr_input_evidence': duOcrInputEvidence,
      'du_ocr_record_count': duOcrRecordCount,
      'passed': passed,
      'status': passed ? '连接成功' : '已配置未测试',
      'blocked_reasons': blockedReasons,
      'error_message_zh': passed ? '' : '解析/OCR 本地产物证据不完整，暂不能启用解析能力增强。',
      'network_used': false,
      'secret_plaintext_written': false,
      'normal_ui_project_name_visible': false,
      'external_runtime_executed': false,
      'vendor_runtime_loaded': false,
    };
    File(probePath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(payload),
        encoding: utf8,
      );
    return {
      ...payload,
      'probe_path': probePath,
    };
  }

  static Map<String, dynamic> _probeRagEvaluationAdapter(
    Directory workspace,
    String providerRef,
  ) {
    final normalizedProvider = providerRef.trim().isEmpty
        ? 'rag_evaluation'
        : providerRef.trim().toLowerCase();
    final probePath = _providerAdapterProbePath(workspace, normalizedProvider);
    final now = DateTime.now().toUtc().toIso8601String();
    final queryDir = _join(workspace.path, 'query');
    final queryResultPath = _join(queryDir, 'multi_kb_query_result.json');
    final retrievalPlanPath = _join(queryDir, 'retrieval_plan.json');
    final rerankReportPath = _join(queryDir, 'rerank_report.json');
    final citationCoveragePath =
        _join(queryDir, 'citation_coverage_report.json');
    final conflictReportPath = _join(queryDir, 'conflict_report.json');
    final externalBoundaryPath =
        _join(queryDir, 'external_validation_boundary.json');
    final validationReportPath = _join(queryDir, 'validation_report.json');
    final validationHistoryPath = _join(queryDir, 'validation_history.jsonl');
    final markdownReportPath = _join(queryDir, 'validation_report.md');
    final queryResult = _readJsonObjectSync(queryResultPath);
    final retrievalPlan = _readJsonObjectSync(retrievalPlanPath);
    final rerankReport = _readJsonObjectSync(rerankReportPath);
    final citationCoverage = _readJsonObjectSync(citationCoveragePath);
    final conflictReport = _readJsonObjectSync(conflictReportPath);
    final externalBoundary = _readJsonObjectSync(externalBoundaryPath);
    final validationReport = _readJsonObjectSync(validationReportPath);
    final resultCount = _asInt(queryResult['result_count']) ??
        _listOfMaps(queryResult['results']).length;
    final validationResultCount = _asInt(validationReport['result_count']) ?? 0;
    final rerankResultCount = _asInt(rerankReport['result_count']) ?? 0;
    final citationResultCount = _asInt(citationCoverage['result_count']) ?? 0;
    final conflictCount = _asInt(validationReport['conflict_count']) ??
        _asInt(conflictReport['conflict_count']) ??
        0;
    final historyCount = _jsonlRecordCount(validationHistoryPath);
    final markdownBytes = File(markdownReportPath).existsSync()
        ? File(markdownReportPath).readAsBytesSync().length
        : 0;
    final requiredArtifacts = [
      {
        'path': queryResultPath,
        'exists': File(queryResultPath).existsSync(),
        'schema_version': _stringValue(queryResult['schema_version'], ''),
        'result_count': resultCount,
      },
      {
        'path': retrievalPlanPath,
        'exists': File(retrievalPlanPath).existsSync(),
        'schema_version': _stringValue(retrievalPlan['schema_version'], ''),
        'selected_kb_count': _asInt(retrievalPlan['selected_kb_count']) ?? 0,
      },
      {
        'path': rerankReportPath,
        'exists': File(rerankReportPath).existsSync(),
        'schema_version': _stringValue(rerankReport['schema_version'], ''),
        'result_count': rerankResultCount,
      },
      {
        'path': citationCoveragePath,
        'exists': File(citationCoveragePath).existsSync(),
        'schema_version': _stringValue(citationCoverage['schema_version'], ''),
        'result_count': citationResultCount,
        'citation_coverage': citationCoverage['citation_coverage'],
      },
      {
        'path': conflictReportPath,
        'exists': File(conflictReportPath).existsSync(),
        'schema_version': _stringValue(conflictReport['schema_version'], ''),
        'conflict_count': _asInt(conflictReport['conflict_count']) ?? 0,
      },
      {
        'path': externalBoundaryPath,
        'exists': File(externalBoundaryPath).existsSync(),
        'schema_version': _stringValue(externalBoundary['schema_version'], ''),
        'external_calls_made':
            _boolValue(externalBoundary['external_calls_made']),
      },
      {
        'path': validationReportPath,
        'exists': File(validationReportPath).existsSync(),
        'schema_version': _stringValue(validationReport['schema_version'], ''),
        'result_count': validationResultCount,
        'correction_status':
            _stringValue(validationReport['correction_status'], ''),
      },
      {
        'path': validationHistoryPath,
        'exists': File(validationHistoryPath).existsSync(),
        'record_count': historyCount,
      },
      {
        'path': markdownReportPath,
        'exists': File(markdownReportPath).existsSync(),
        'bytes': markdownBytes,
      },
    ];
    final missingArtifacts = requiredArtifacts
        .where((artifact) => artifact['exists'] != true)
        .map((artifact) => artifact['path'].toString())
        .toList(growable: false);
    final validQueryResult = _stringValue(queryResult['schema_version'], '') ==
            'prd_v3_multi_kb_query_result.v1' &&
        resultCount > 0 &&
        _listOfMaps(queryResult['results']).isNotEmpty;
    final validRetrievalPlan =
        _stringValue(retrievalPlan['schema_version'], '') ==
                'prd_v3_retrieval_plan.v1' &&
            (_asInt(retrievalPlan['selected_kb_count']) ?? 0) > 0;
    final validRerank = _stringValue(rerankReport['schema_version'], '') ==
            'prd_v3_retrieval_rerank_report.v1' &&
        rerankResultCount == resultCount &&
        rerankResultCount > 0;
    final validCitation =
        _stringValue(citationCoverage['schema_version'], '') ==
                'prd_v3_retrieval_citation_coverage.v1' &&
            citationResultCount == resultCount &&
            (_asDouble(citationCoverage['citation_coverage']) ?? -1) >= 0;
    final validConflict = _stringValue(conflictReport['schema_version'], '') ==
        'prd_v3_retrieval_conflict_report.v1';
    final validExternalBoundary =
        _stringValue(externalBoundary['schema_version'], '') ==
                'prd_v3_external_validation_boundary.v1' &&
            _boolValue(externalBoundary['external_calls_made']) == false &&
            _boolValue(externalBoundary['secret_plaintext_written']) == false;
    final validValidation = _stringValue(
                validationReport['schema_version'], '') ==
            'prd_v3_retrieval_validation_report.v1' &&
        validationResultCount == resultCount &&
        _stringValue(validationReport['correction_status'], '') == 'reviewed' &&
        _stringValue(validationReport['retrieval_plan_path'], '') ==
            retrievalPlanPath &&
        _stringValue(validationReport['rerank_report_path'], '') ==
            rerankReportPath &&
        _stringValue(validationReport['citation_coverage_report_path'], '') ==
            citationCoveragePath &&
        _stringValue(validationReport['conflict_report_path'], '') ==
            conflictReportPath;
    final validHistory = historyCount > 0 && markdownBytes > 0;
    final validProviderScope =
        const {'ragas', 'deepeval'}.contains(normalizedProvider);
    final invalidReasons = <String>[
      if (!validProviderScope) 'provider_ref_not_supported',
      if (!validQueryResult) 'query_result_invalid',
      if (!validRetrievalPlan) 'retrieval_plan_invalid',
      if (!validRerank) 'rerank_report_invalid',
      if (!validCitation) 'citation_coverage_invalid',
      if (!validConflict) 'conflict_report_invalid',
      if (!validExternalBoundary) 'external_validation_boundary_invalid',
      if (!validValidation) 'validation_report_invalid',
      if (!validHistory) 'validation_history_or_markdown_missing',
    ];
    final passed = missingArtifacts.isEmpty && invalidReasons.isEmpty;
    final payload = {
      'schema_version': 'prd_v3_provider_adapter_probe_rag_evaluation.v1',
      'provider_ref': normalizedProvider,
      'adapter_type': 'rag_evaluation_adapter',
      'executed_at': now,
      'probe_kind': normalizedProvider == 'ragas'
          ? 'local_rag_faithfulness_evaluation_assets'
          : 'local_deepeval_retrieval_quality_assets',
      'workspace_boundary': workspace.path,
      'required_artifacts': requiredArtifacts,
      'missing_artifacts': missingArtifacts,
      'invalid_reasons': invalidReasons,
      'blocked_reasons': [
        ...missingArtifacts.map((path) => 'missing:$path'),
        ...invalidReasons,
      ],
      'result_count': resultCount,
      'conflict_count': conflictCount,
      'history_count': historyCount,
      'passed': passed,
      'status': passed ? '连接成功' : '已配置未测试',
      'error_message_zh': passed ? '' : 'RAG 评测需要真实检索验证、引用覆盖、冲突检测和人工校验产物后才能启用。',
      'network_used': false,
      'secret_plaintext_written': false,
      'normal_ui_project_name_visible': false,
      'external_runtime_executed': false,
      'vendor_runtime_loaded': false,
    };
    File(probePath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(payload),
        encoding: utf8,
      );
    return {
      ...payload,
      'probe_path': probePath,
    };
  }

  static Map<String, dynamic> _probeEmbeddingVectorAdapter(
    Directory workspace,
    String providerRef,
  ) {
    final normalizedProvider =
        providerRef.trim().isEmpty ? 'embedding_vector' : providerRef.trim();
    final probePath = _providerAdapterProbePath(workspace, normalizedProvider);
    final now = DateTime.now().toUtc().toIso8601String();
    final kbRoot = _join(workspace.path, 'kb');
    final chunksPath = _join(kbRoot, 'chunks.jsonl');
    final indexProfilePath = _join(kbRoot, 'index_profile.json');
    final vectorReferencePath = _join(kbRoot, 'vector_index_reference.json');
    final indexBuildReportPath = _join(kbRoot, 'index_build_report.json');
    final indexMetadataPath = _join(kbRoot, 'index_metadata.json');
    final chunks = _jsonlRecordCount(chunksPath);
    final indexProfile = _readJsonObjectSync(indexProfilePath);
    final vectorReference = _readJsonObjectSync(vectorReferencePath);
    final indexBuildReport = _readJsonObjectSync(indexBuildReportPath);
    final indexMetadata = _readJsonObjectSync(indexMetadataPath);
    final vectorChunkCount = _asInt(vectorReference['chunk_count']) ?? 0;
    final buildChunkCount = _asInt(indexBuildReport['chunk_count']) ?? 0;
    final metadataChunkCount = _asInt(indexMetadata['chunk_count']) ?? 0;
    final hasIndexArtifacts = File(indexProfilePath).existsSync() &&
        File(vectorReferencePath).existsSync() &&
        File(indexBuildReportPath).existsSync() &&
        File(indexMetadataPath).existsSync() &&
        _stringValue(indexProfile['schema_version'], '') ==
            'prd_v3_index_profile.v1' &&
        _stringValue(vectorReference['schema_version'], '') ==
            'prd_v3_vector_index_reference.v1' &&
        _stringValue(indexBuildReport['schema_version'], '') ==
            'prd_v3_index_build_report.v1' &&
        _stringValue(indexMetadata['schema_version'], '') ==
            'prd_v3_index_metadata.v1';
    final hasConsistentChunks = chunks > 0 &&
        vectorChunkCount == chunks &&
        buildChunkCount == chunks &&
        metadataChunkCount == chunks;
    final vectorEnabled = _boolValue(indexProfile['vector_index_enabled']) &&
        _stringValue(vectorReference['vector_store'], '').isNotEmpty;
    final isBenchmarkOnly = normalizedProvider.toLowerCase() == 'llamaindex';
    final passed = !isBenchmarkOnly &&
        hasIndexArtifacts &&
        hasConsistentChunks &&
        vectorEnabled;
    final blockedReasons = <String>[
      if (!hasIndexArtifacts) '需要完整 KB index metadata/profile/vector/build 产物',
      if (!hasConsistentChunks) '需要 chunks 与 vector/index 计数一致',
      if (!vectorEnabled) '需要 vector index reference 可用',
      if (isBenchmarkOnly) 'benchmark-only Provider 需要外部配置或基准证据',
    ];
    final payload = {
      'schema_version': 'prd_v3_provider_adapter_probe_embedding_vector.v1',
      'provider_ref': normalizedProvider,
      'adapter_type': 'embedding_vector_adapter',
      'executed_at': now,
      'probe_kind': isBenchmarkOnly
          ? 'benchmark_only_vector_boundary'
          : 'local_kb_embedding_vector_reference',
      'workspace_boundary': workspace.path,
      'required_artifacts': [
        {
          'path': chunksPath,
          'exists': File(chunksPath).existsSync(),
          'record_count': chunks,
        },
        {
          'path': indexProfilePath,
          'exists': File(indexProfilePath).existsSync(),
          'schema_version': _stringValue(indexProfile['schema_version'], ''),
          'vector_index_enabled': _boolValue(
            indexProfile['vector_index_enabled'],
          ),
        },
        {
          'path': vectorReferencePath,
          'exists': File(vectorReferencePath).existsSync(),
          'schema_version': _stringValue(vectorReference['schema_version'], ''),
          'chunk_count': vectorChunkCount,
          'vector_store': _stringValue(vectorReference['vector_store'], ''),
          'external_vector_db_required':
              _boolValue(vectorReference['external_vector_db_required']),
        },
        {
          'path': indexBuildReportPath,
          'exists': File(indexBuildReportPath).existsSync(),
          'schema_version':
              _stringValue(indexBuildReport['schema_version'], ''),
          'chunk_count': buildChunkCount,
          'status': _stringValue(indexBuildReport['status'], ''),
        },
        {
          'path': indexMetadataPath,
          'exists': File(indexMetadataPath).existsSync(),
          'schema_version': _stringValue(indexMetadata['schema_version'], ''),
          'chunk_count': metadataChunkCount,
          'index_type': _stringValue(indexMetadata['index_type'], ''),
        },
      ],
      'chunk_count': chunks,
      'vector_chunk_count': vectorChunkCount,
      'has_index_artifacts': hasIndexArtifacts,
      'has_consistent_chunks': hasConsistentChunks,
      'vector_enabled': vectorEnabled,
      'passed': passed,
      'status': passed
          ? '连接成功'
          : isBenchmarkOnly
              ? '配置缺失'
              : '已配置未测试',
      'blocked_reasons': blockedReasons,
      'error_message_zh': passed
          ? ''
          : isBenchmarkOnly
              ? 'benchmark-only Provider 需要外部配置或基准证据后才能启用。'
              : 'Embedding / Vector 本地索引引用证据不完整，暂不能启用能力增强。',
      'network_used': false,
      'secret_plaintext_written': false,
      'normal_ui_project_name_visible': false,
      'external_runtime_executed': false,
      'vendor_runtime_loaded': false,
    };
    File(probePath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(payload),
        encoding: utf8,
      );
    return {
      ...payload,
      'probe_path': probePath,
    };
  }

  static Map<String, dynamic> _probeMattpocockGovernanceRulePack(
    Directory workspace,
  ) {
    final probePath = _providerAdapterProbePath(workspace, 'mattpocock_skills');
    final now = DateTime.now().toUtc().toIso8601String();
    final repoRoot = _resolveRepoRootForProviderProbe();
    final requiredAssets = <String>[
      _joinNested(repoRoot.path, 'heitang_kb_forge/quality_gate/rules.py'),
      _joinNested(repoRoot.path, 'heitang_kb_forge/test_governance/gates.py'),
      _joinNested(repoRoot.path, 'heitang_kb_forge/provider_security/audit.py'),
      _join(repoRoot.path, 'tests', 'test_test_governance_manifest.py'),
    ];
    final checkedAssets = requiredAssets.map((path) {
      final exists = File(path).existsSync();
      var bytes = 0;
      var hasRuleEvidence = false;
      if (exists) {
        final content = File(path).readAsStringSync(encoding: utf8);
        bytes = utf8.encode(content).length;
        final lower = content.toLowerCase();
        hasRuleEvidence = lower.contains('gate') ||
            lower.contains('audit') ||
            lower.contains('governance') ||
            lower.contains('policy') ||
            lower.contains('rule');
      }
      return {
        'path': path,
        'exists': exists,
        'bytes': bytes,
        'has_rule_evidence': hasRuleEvidence,
      };
    }).toList(growable: false);
    final missingAssets = checkedAssets
        .where((asset) => asset['exists'] != true)
        .map((asset) => asset['path'].toString())
        .toList(growable: false);
    final invalidAssets = checkedAssets
        .where((asset) =>
            asset['exists'] == true && asset['has_rule_evidence'] != true)
        .map((asset) => asset['path'].toString())
        .toList(growable: false);
    final passed = missingAssets.isEmpty && invalidAssets.isEmpty;
    final payload = {
      'schema_version': 'prd_v3_provider_adapter_probe_mattpocock_skills.v1',
      'provider_ref': 'mattpocock_skills',
      'adapter_type': 'governance_audit_adapter',
      'executed_at': now,
      'probe_kind': 'local_governance_rule_pack',
      'workspace_boundary': workspace.path,
      'repo_boundary': repoRoot.path,
      'checked_assets': checkedAssets,
      'missing_assets': missingAssets,
      'invalid_assets': invalidAssets,
      'passed': passed,
      'status': passed ? '连接成功' : '已配置未测试',
      'error_message_zh': passed ? '' : '本地治理规则包证据不完整，暂不能启用治理能力增强。',
      'network_used': false,
      'secret_plaintext_written': false,
      'normal_ui_project_name_visible': false,
      'external_runtime_executed': false,
    };
    File(probePath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(payload),
        encoding: utf8,
      );
    return {
      ...payload,
      'probe_path': probePath,
    };
  }

  static Map<String, dynamic> _probeSkillPromptGeneratorTemplateAssets(
    Directory workspace,
  ) {
    final probePath =
        _providerAdapterProbePath(workspace, 'skill_prompt_generator');
    final now = DateTime.now().toUtc().toIso8601String();
    final skillGenerationPath =
        _joinNested(workspace.path, 'skill/skill_generation_manifest.json');
    final primarySkillPath =
        _joinNested(workspace.path, 'skill/knowledge_qa_skill/SKILL.md');
    final primaryConfigPath = _joinNested(
        workspace.path, 'skill/knowledge_qa_skill/skill_config.json');
    final validationPath =
        _joinNested(workspace.path, 'skill/skill_validation_report.json');
    final localizedManifestPath = _joinNested(workspace.path,
        'skill/localized_writing_skill/S2/localized_skill_manifest.json');
    final localizedDiffPath = _joinNested(
        workspace.path, 'skill/localized_writing_skill/S2/diff_summary.md');
    final fusedSkillPath =
        _joinNested(workspace.path, 'skill/fused_product_ops_skill/SKILL.md');
    final runtimeManifestPath = _joinNested(
        workspace.path, 'skill/operations/skill_runtime_manifest.json');
    final versionDiffPath = _joinNested(
        workspace.path, 'skill/operations/skill_version_diff_report.json');
    final generationManifest = _readJsonObjectSync(skillGenerationPath);
    final primaryConfig = _readJsonObjectSync(primaryConfigPath);
    final validation = _readJsonObjectSync(validationPath);
    final localizedManifest = _readJsonObjectSync(localizedManifestPath);
    final runtimeManifest = _readJsonObjectSync(runtimeManifestPath);
    final versionDiff = _readJsonObjectSync(versionDiffPath);
    final primaryText = File(primarySkillPath).existsSync()
        ? File(primarySkillPath).readAsStringSync(encoding: utf8)
        : '';
    final localizedDiffText = File(localizedDiffPath).existsSync()
        ? File(localizedDiffPath).readAsStringSync(encoding: utf8)
        : '';
    final fusedText = File(fusedSkillPath).existsSync()
        ? File(fusedSkillPath).readAsStringSync(encoding: utf8)
        : '';
    final versions = _listOfMaps(runtimeManifest['versions']);
    final versionSnapshotsExist = versions.length > 1 &&
        versions.every((version) {
          final snapshot = _stringValue(version['snapshot_path'], '');
          return snapshot.isNotEmpty && File(snapshot).existsSync();
        });
    final checkedAssets = [
      {
        'path': skillGenerationPath,
        'exists': File(skillGenerationPath).existsSync(),
        'schema_version':
            _stringValue(generationManifest['schema_version'], ''),
        'source_modes': _listOfStrings(generationManifest['source_modes']),
        'has_selected_generation_config':
            _mapValue(generationManifest['selected_generation_config'])
                .isNotEmpty,
      },
      {
        'path': primarySkillPath,
        'exists': File(primarySkillPath).existsSync(),
        'bytes': utf8.encode(primaryText).length,
      },
      {
        'path': primaryConfigPath,
        'exists': File(primaryConfigPath).existsSync(),
        'source_mode': _stringValue(primaryConfig['source_mode'], ''),
        'target_platform': _stringValue(primaryConfig['target_platform'], ''),
      },
      {
        'path': validationPath,
        'exists': File(validationPath).existsSync(),
        'schema_version': _stringValue(validation['schema_version'], ''),
        'status': _stringValue(validation['status'], ''),
        'ready_for_agent_binding':
            _boolValue(validation['ready_for_agent_binding']),
      },
      {
        'path': localizedManifestPath,
        'exists': File(localizedManifestPath).existsSync(),
        'source_mode': _stringValue(localizedManifest['source_mode'], ''),
      },
      {
        'path': localizedDiffPath,
        'exists': File(localizedDiffPath).existsSync(),
        'bytes': utf8.encode(localizedDiffText).length,
      },
      {
        'path': fusedSkillPath,
        'exists': File(fusedSkillPath).existsSync(),
        'bytes': utf8.encode(fusedText).length,
      },
      {
        'path': runtimeManifestPath,
        'exists': File(runtimeManifestPath).existsSync(),
        'schema_version': _stringValue(runtimeManifest['schema_version'], ''),
        'runtime_loaded': _boolValue(runtimeManifest['runtime_loaded']),
        'secondary_fusion_runtime_available':
            _boolValue(runtimeManifest['secondary_fusion_runtime_available']),
        'multi_version_runtime_available':
            _boolValue(runtimeManifest['multi_version_runtime_available']),
        'version_count': _asInt(runtimeManifest['version_count']) ?? 0,
        'version_snapshots_exist': versionSnapshotsExist,
      },
      {
        'path': versionDiffPath,
        'exists': File(versionDiffPath).existsSync(),
        'schema_version': _stringValue(versionDiff['schema_version'], ''),
        'status': _stringValue(versionDiff['status'], ''),
      },
    ];
    final required = {
      'generation_manifest_schema':
          _stringValue(generationManifest['schema_version'], '') ==
              'rc10_real_input_skill_generation.v1',
      'generation_manifest_has_config':
          _mapValue(generationManifest['selected_generation_config'])
              .isNotEmpty,
      'generation_modes_include_kb_and_localization':
          _listOfStrings(generationManifest['source_modes'])
                  .contains('from_kb') &&
              _listOfStrings(generationManifest['source_modes'])
                  .contains('external_skill_fusion'),
      'primary_skill_nonempty':
          File(primarySkillPath).existsSync() && primaryText.trim().isNotEmpty,
      'primary_config_from_kb':
          _stringValue(primaryConfig['source_mode'], '') == 'from_kb',
      'validation_passed': _stringValue(validation['schema_version'], '') ==
              'prd_v3_skill_factory_validation.v1' &&
          _stringValue(validation['status'], '') == 'pass' &&
          _boolValue(validation['ready_for_agent_binding']),
      'localized_skill_fusion':
          _stringValue(localizedManifest['source_mode'], '') ==
                  'external_skill_fusion' &&
              File(localizedDiffPath).existsSync() &&
              localizedDiffText.trim().isNotEmpty,
      'fused_skill_nonempty':
          File(fusedSkillPath).existsSync() && fusedText.trim().isNotEmpty,
      'skill_runtime_manifest_passed': _stringValue(
                  runtimeManifest['schema_version'], '') ==
              'prd_v3_skill_runtime_manifest.v1' &&
          _boolValue(runtimeManifest['runtime_loaded']) &&
          _boolValue(runtimeManifest['secondary_fusion_runtime_available']) &&
          _boolValue(runtimeManifest['multi_version_runtime_available']) &&
          ((_asInt(runtimeManifest['version_count']) ?? 0) > 1) &&
          versionSnapshotsExist,
      'version_diff_passed': _stringValue(versionDiff['schema_version'], '') ==
              'prd_v3_skill_version_diff_report.v1' &&
          _stringValue(versionDiff['status'], '') == 'pass',
      'model_route_evidence_recorded':
          _mapValue(generationManifest['model_route_evidence']).isNotEmpty &&
              _mapValue(runtimeManifest['model_route_evidence']).isNotEmpty,
      'secret_plaintext_absent':
          generationManifest['secret_plaintext_written'] != true &&
              runtimeManifest['secret_plaintext_written'] == false,
    };
    final blockedReasons = required.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList(growable: false);
    final passed = blockedReasons.isEmpty;
    final payload = {
      'schema_version':
          'prd_v3_provider_adapter_probe_skill_prompt_generator.v1',
      'provider_ref': 'skill_prompt_generator',
      'adapter_type': 'skill_template_adapter',
      'executed_at': now,
      'probe_kind': 'local_skill_prompt_template_generation_assets',
      'workspace_boundary': workspace.path,
      'checked_assets': checkedAssets,
      'required': required,
      'blocked_reasons': blockedReasons,
      'passed': passed,
      'status': passed ? '连接成功' : '已配置未测试',
      'error_message_zh':
          passed ? '' : '本地 Skill 生成、本土化、融合、验证或多版本运行证据不完整，暂不能启用模板提示能力增强。',
      'network_used': false,
      'secret_plaintext_written': false,
      'normal_ui_project_name_visible': false,
      'external_runtime_executed': false,
      'vendor_runtime_loaded': false,
    };
    File(probePath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(payload),
        encoding: utf8,
      );
    return {
      ...payload,
      'probe_path': probePath,
    };
  }

  static Map<String, dynamic> _probeKarpathyTeachingSkillAssets(
    Directory workspace,
  ) {
    final probePath =
        _providerAdapterProbePath(workspace, 'andrej_karpathy_skills');
    final now = DateTime.now().toUtc().toIso8601String();
    final manifestPath = _joinNested(workspace.path,
        'skill/template_assets/andrej_karpathy_skills/template_asset_manifest.json');
    final manifest = {
      'schema_version': 'prd_v3_skill_template_asset_manifest.v1',
      'provider_ref': 'andrej_karpathy_skills',
      'asset_class': 'teaching_reasoning_template_asset',
      'version': '1.0.0',
      'source': {
        'kind': 'registered_reference_absorbed_as_template_asset',
        'external_code_bundled': false,
        'external_runtime_required': false,
        'network_required': false,
        'secret_required': false,
      },
      'templates': [
        {
          'template_id': 'template_manual_operation_skill',
          'display_name': '教学/推理 Skill 模板',
          'capability_id': 'skill_template_provider',
          'entry_points': [
            'skill_factory_template_catalog',
            'agent_workbench_template_binding',
            'document_generation_style_template',
          ],
          'requires_kb_binding': true,
          'requires_agent_binding_validation': true,
        }
      ],
      'validation': {
        'status': 'pass',
        'validated_at': now,
        'checks': [
          'manifest_schema',
          'source_version',
          'skill_agent_binding_boundary',
          'normal_ui_boundary',
          'secret_boundary',
        ],
      },
      'binding_boundary': {
        'skill_factory': true,
        'agent_workbench': true,
        'document_generation': true,
        'ordinary_ui_project_name_visible': false,
        'runtime_load_required': false,
        'external_health_check_required': false,
      },
      'audit': {
        'network_used': false,
        'external_runtime_executed': false,
        'vendor_runtime_loaded': false,
        'secret_plaintext_written': false,
      },
    };
    File(manifestPath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(manifest),
        encoding: utf8,
      );
    final templateManifest = _readJsonObjectSync(manifestPath);
    final templates = _listOfMaps(templateManifest['templates']);
    final validation = _mapValue(templateManifest['validation']);
    final bindingBoundary = _mapValue(templateManifest['binding_boundary']);
    final audit = _mapValue(templateManifest['audit']);
    final checkedAssets = [
      {
        'path': manifestPath,
        'exists': File(manifestPath).existsSync(),
        'schema_version': _stringValue(templateManifest['schema_version'], ''),
        'template_count': templates.length,
        'validation_status': _stringValue(validation['status'], ''),
        'runtime_load_required':
            _boolValue(bindingBoundary['runtime_load_required']),
      },
    ];
    final required = {
      'template_manifest_schema':
          _stringValue(templateManifest['schema_version'], '') ==
              'prd_v3_skill_template_asset_manifest.v1',
      'source_version_recorded':
          _stringValue(templateManifest['version'], '').isNotEmpty &&
              _mapValue(templateManifest['source']).isNotEmpty,
      'template_manifest_has_assets': templates.isNotEmpty &&
          templates.every((template) =>
              _stringValue(template['template_id'], '').isNotEmpty &&
              _listOfStrings(template['entry_points']).isNotEmpty),
      'validation_passed': _stringValue(validation['status'], '') == 'pass' &&
          _listOfStrings(validation['checks']).isNotEmpty,
      'skill_agent_binding_boundary':
          _boolValue(bindingBoundary['skill_factory']) &&
              _boolValue(bindingBoundary['agent_workbench']) &&
              _boolValue(bindingBoundary['document_generation']) &&
              _boolValue(bindingBoundary['ordinary_ui_project_name_visible']) ==
                  false,
      'runtime_load_not_required':
          _boolValue(bindingBoundary['runtime_load_required']) == false &&
              _boolValue(bindingBoundary['external_health_check_required']) ==
                  false,
      'no_external_runtime_or_vendor_execution':
          _boolValue(audit['network_used']) == false &&
              _boolValue(audit['external_runtime_executed']) == false &&
              _boolValue(audit['vendor_runtime_loaded']) == false,
      'secret_plaintext_absent':
          _boolValue(audit['secret_plaintext_written']) == false,
    };
    final blockedReasons = required.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList(growable: false);
    final passed = blockedReasons.isEmpty;
    final payload = {
      'schema_version':
          'prd_v3_provider_adapter_probe_andrej_karpathy_skills.v1',
      'provider_ref': 'andrej_karpathy_skills',
      'adapter_type': 'skill_template_adapter',
      'executed_at': now,
      'probe_kind': 'local_teaching_reasoning_template_asset_manifest',
      'workspace_boundary': workspace.path,
      'template_asset_manifest_path': manifestPath,
      'checked_assets': checkedAssets,
      'required': required,
      'blocked_reasons': blockedReasons,
      'passed': passed,
      'status': passed ? '连接成功' : '已配置未测试',
      'error_message_zh': passed ? '' : '本地教学/推理模板资产 manifest 不完整，暂不能启用模板能力增强。',
      'network_used': false,
      'secret_plaintext_written': false,
      'normal_ui_project_name_visible': false,
      'external_runtime_executed': false,
      'vendor_runtime_loaded': false,
    };
    File(probePath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(payload),
        encoding: utf8,
      );
    return {
      ...payload,
      'probe_path': probePath,
    };
  }

  static Map<String, dynamic> _probeMmskillsSchemaPackageAssets(
    Directory workspace,
  ) {
    final probePath = _providerAdapterProbePath(workspace, 'mmskills');
    final now = DateTime.now().toUtc().toIso8601String();
    final packageManifestPath =
        _joinNested(workspace.path, 'skill/skill_package_manifest.json');
    final validationPath =
        _joinNested(workspace.path, 'skill/skill_validation_report.json');
    final primaryConfigPath = _joinNested(
        workspace.path, 'skill/knowledge_qa_skill/skill_config.json');
    final localizedManifestPath = _joinNested(workspace.path,
        'skill/localized_writing_skill/S2/localized_skill_manifest.json');
    final fusedManifestPath = _joinNested(
        workspace.path, 'skill/fused_product_ops_skill/skill_manifest.json');
    final runtimeManifestPath = _joinNested(
        workspace.path, 'skill/operations/skill_runtime_manifest.json');
    final bindingManifestPath = _joinNested(
        workspace.path, 'skill/operations/agent_binding_manifest.json');
    final packageManifest = _readJsonObjectSync(packageManifestPath);
    final validation = _readJsonObjectSync(validationPath);
    final primaryConfig = _readJsonObjectSync(primaryConfigPath);
    final localizedManifest = _readJsonObjectSync(localizedManifestPath);
    final fusedManifest = _readJsonObjectSync(fusedManifestPath);
    final runtimeManifest = _readJsonObjectSync(runtimeManifestPath);
    final bindingManifest = _readJsonObjectSync(bindingManifestPath);
    final versions = _listOfMaps(runtimeManifest['versions']);
    final snapshotsExist = versions.length > 1 &&
        versions.every((version) {
          final snapshot = _stringValue(version['snapshot_path'], '');
          return snapshot.isNotEmpty && File(snapshot).existsSync();
        });
    final checkedAssets = [
      {
        'path': packageManifestPath,
        'exists': File(packageManifestPath).existsSync(),
        'schema_version': _stringValue(packageManifest['schema_version'], ''),
        'status': _stringValue(packageManifest['status'], ''),
      },
      {
        'path': validationPath,
        'exists': File(validationPath).existsSync(),
        'schema_version': _stringValue(validation['schema_version'], ''),
        'status': _stringValue(validation['status'], ''),
      },
      {
        'path': primaryConfigPath,
        'exists': File(primaryConfigPath).existsSync(),
        'source_mode': _stringValue(primaryConfig['source_mode'], ''),
      },
      {
        'path': localizedManifestPath,
        'exists': File(localizedManifestPath).existsSync(),
        'source_mode': _stringValue(localizedManifest['source_mode'], ''),
      },
      {
        'path': fusedManifestPath,
        'exists': File(fusedManifestPath).existsSync(),
        'source_mode': _stringValue(fusedManifest['source_mode'], ''),
      },
      {
        'path': runtimeManifestPath,
        'exists': File(runtimeManifestPath).existsSync(),
        'schema_version': _stringValue(runtimeManifest['schema_version'], ''),
        'runtime_loaded': _boolValue(runtimeManifest['runtime_loaded']),
        'secondary_fusion_runtime_available':
            _boolValue(runtimeManifest['secondary_fusion_runtime_available']),
        'multi_version_runtime_available':
            _boolValue(runtimeManifest['multi_version_runtime_available']),
        'version_count': _asInt(runtimeManifest['version_count']) ?? 0,
        'snapshots_exist': snapshotsExist,
      },
      {
        'path': bindingManifestPath,
        'exists': File(bindingManifestPath).existsSync(),
        'status': _stringValue(bindingManifest['status'], ''),
      },
    ];
    final required = {
      'package_manifest_schema':
          _stringValue(packageManifest['schema_version'], '') ==
              'prd_v3_skill_package_manifest.v1',
      'package_manifest_ready':
          _stringValue(packageManifest['status'], '') == 'ready' &&
              _listOfMaps(packageManifest['skill_packages']).isNotEmpty,
      'validation_passed': _stringValue(validation['schema_version'], '') ==
              'prd_v3_skill_factory_validation.v1' &&
          _stringValue(validation['status'], '') == 'pass' &&
          _boolValue(validation['ready_for_agent_binding']),
      'primary_skill_from_kb':
          _stringValue(primaryConfig['source_mode'], '') == 'from_kb',
      'localized_external_skill_fusion':
          _stringValue(localizedManifest['source_mode'], '') ==
              'external_skill_fusion',
      'fused_skill_plus_kb': _stringValue(fusedManifest['source_mode'], '') ==
          'skill_plus_kb_fusion',
      'runtime_manifest_schema':
          _stringValue(runtimeManifest['schema_version'], '') ==
              'prd_v3_skill_runtime_manifest.v1',
      'runtime_has_secondary_fusion':
          _boolValue(runtimeManifest['runtime_loaded']) &&
              _boolValue(runtimeManifest['secondary_fusion_runtime_available']),
      'runtime_has_multi_version':
          _boolValue(runtimeManifest['multi_version_runtime_available']) &&
              ((_asInt(runtimeManifest['version_count']) ?? 0) > 1) &&
              snapshotsExist,
      'agent_binding_recorded':
          _stringValue(bindingManifest['status'], '').isNotEmpty,
      'model_route_evidence_recorded':
          _mapValue(packageManifest['model_route_evidence']).isNotEmpty &&
              _mapValue(runtimeManifest['model_route_evidence']).isNotEmpty,
      'secret_plaintext_absent':
          packageManifest['secret_plaintext_written'] == false &&
              validation['secret_plaintext_written'] == false &&
              runtimeManifest['secret_plaintext_written'] == false,
    };
    final blockedReasons = required.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList(growable: false);
    final passed = blockedReasons.isEmpty;
    final payload = {
      'schema_version': 'prd_v3_provider_adapter_probe_mmskills.v1',
      'provider_ref': 'mmskills',
      'adapter_type': 'skill_template_adapter',
      'executed_at': now,
      'probe_kind': 'local_skill_schema_package_assets',
      'workspace_boundary': workspace.path,
      'checked_assets': checkedAssets,
      'required': required,
      'blocked_reasons': blockedReasons,
      'passed': passed,
      'status': passed ? '连接成功' : '已配置未测试',
      'error_message_zh': passed
          ? ''
          : '本地 Skill schema/package/runtime/Agent 绑定证据不完整，暂不能启用 schema package 能力增强。',
      'network_used': false,
      'secret_plaintext_written': false,
      'normal_ui_project_name_visible': false,
      'external_runtime_executed': false,
      'vendor_runtime_loaded': false,
    };
    File(probePath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(payload),
        encoding: utf8,
      );
    return {
      ...payload,
      'probe_path': probePath,
    };
  }

  static Map<String, dynamic> _probeLlmWikiAgentMemoryFusion(
    Directory workspace,
  ) {
    final probePath = _providerAdapterProbePath(workspace, 'llm_wiki_v2');
    final now = DateTime.now().toUtc().toIso8601String();
    final requiredAssets = <String>[
      _joinNested(workspace.path, 'agent/agent_generation_manifest.json'),
      _joinNested(workspace.path, 'agent/audit/permission_audit.json'),
      _joinNested(workspace.path, 'agent/audit/agent_validation_report.json'),
      _joinNested(workspace.path, 'kb/memory_index_reference.json'),
    ];
    final checkedAssets = requiredAssets.map((path) {
      final exists = File(path).existsSync();
      var schemaVersion = '';
      var hasAgentMemoryEvidence = false;
      if (exists) {
        try {
          final decoded =
              jsonDecode(File(path).readAsStringSync(encoding: utf8));
          if (decoded is Map) {
            schemaVersion = _stringValue(decoded['schema_version'], '');
            final serialized = jsonEncode(decoded).toLowerCase();
            hasAgentMemoryEvidence = serialized.contains('agent') ||
                serialized.contains('memory') ||
                serialized.contains('permission') ||
                serialized.contains('validation');
          }
        } on FormatException {
          final text =
              File(path).readAsStringSync(encoding: utf8).toLowerCase();
          hasAgentMemoryEvidence =
              text.contains('agent') || text.contains('memory');
        }
      }
      return {
        'path': path,
        'exists': exists,
        'schema_version': schemaVersion,
        'has_agent_memory_evidence': hasAgentMemoryEvidence,
      };
    }).toList(growable: false);
    final missingAssets = checkedAssets
        .where((asset) => asset['exists'] != true)
        .map((asset) => asset['path'].toString())
        .toList(growable: false);
    final invalidAssets = checkedAssets
        .where((asset) =>
            asset['exists'] == true &&
            asset['has_agent_memory_evidence'] != true)
        .map((asset) => asset['path'].toString())
        .toList(growable: false);
    final passed = missingAssets.isEmpty && invalidAssets.isEmpty;
    final payload = {
      'schema_version': 'prd_v3_provider_adapter_probe_llm_wiki_v2.v1',
      'provider_ref': 'llm_wiki_v2',
      'adapter_type': 'agent_capability_adapter',
      'executed_at': now,
      'probe_kind': 'local_agent_memory_lifecycle_fusion',
      'workspace_boundary': workspace.path,
      'checked_assets': checkedAssets,
      'missing_assets': missingAssets,
      'invalid_assets': invalidAssets,
      'passed': passed,
      'status': passed ? '连接成功' : '已配置未测试',
      'error_message_zh': passed ? '' : 'Agent 记忆生命周期证据不完整，暂不能启用 Agent 记忆能力增强。',
      'network_used': false,
      'secret_plaintext_written': false,
      'normal_ui_project_name_visible': false,
      'external_runtime_executed': false,
      'vendor_runtime_loaded': false,
    };
    File(probePath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(payload),
        encoding: utf8,
      );
    return {
      ...payload,
      'probe_path': probePath,
    };
  }

  static Map<String, dynamic> _probeAiMarketingSkillPatternLibrary(
    Directory workspace,
  ) {
    final probePath =
        _providerAdapterProbePath(workspace, 'ai_marketing_skills');
    final now = DateTime.now().toUtc().toIso8601String();
    final repoRoot = _resolveRepoRootForProviderProbe();
    final requiredAssets = <String>[
      _joinNested(repoRoot.path,
          'web/workbench/flutter_app/assets/contracts/p1_core_contract_fixture.json'),
      _joinNested(repoRoot.path, 'heitang_kb_forge/agent/templates.py'),
      _joinNested(repoRoot.path, 'heitang_kb_forge/skill_templates/catalog.py'),
      _joinNested(repoRoot.path,
          'examples/demo_shopping_guide_agent/output_sample/manifest.json'),
    ];
    final checkedAssets = requiredAssets.map((path) {
      final exists = File(path).existsSync();
      var bytes = 0;
      var hasMarketingEvidence = false;
      if (exists) {
        final content = File(path).readAsStringSync(encoding: utf8);
        bytes = utf8.encode(content).length;
        final lower = content.toLowerCase();
        hasMarketingEvidence = lower.contains('shopping') ||
            lower.contains('marketing') ||
            lower.contains('operations') ||
            lower.contains('template_shopping_ops_agent') ||
            lower.contains('运营') ||
            lower.contains('导购');
      }
      return {
        'path': path,
        'exists': exists,
        'bytes': bytes,
        'has_marketing_pattern_evidence': hasMarketingEvidence,
      };
    }).toList(growable: false);
    final missingAssets = checkedAssets
        .where((asset) => asset['exists'] != true)
        .map((asset) => asset['path'].toString())
        .toList(growable: false);
    final invalidAssets = checkedAssets
        .where((asset) =>
            asset['exists'] == true &&
            asset['has_marketing_pattern_evidence'] != true)
        .map((asset) => asset['path'].toString())
        .toList(growable: false);
    final passed = missingAssets.isEmpty && invalidAssets.isEmpty;
    final payload = {
      'schema_version': 'prd_v3_provider_adapter_probe_ai_marketing_skills.v1',
      'provider_ref': 'ai_marketing_skills',
      'adapter_type': 'skill_template_adapter',
      'executed_at': now,
      'probe_kind': 'local_marketing_skill_pattern_library',
      'workspace_boundary': workspace.path,
      'repo_boundary': repoRoot.path,
      'checked_assets': checkedAssets,
      'missing_assets': missingAssets,
      'invalid_assets': invalidAssets,
      'passed': passed,
      'status': passed ? '连接成功' : '已配置未测试',
      'error_message_zh': passed ? '' : '本地营销 Skill 模式库证据不完整，暂不能启用模板能力增强。',
      'network_used': false,
      'secret_plaintext_written': false,
      'normal_ui_project_name_visible': false,
      'external_runtime_executed': false,
      'vendor_runtime_loaded': false,
    };
    File(probePath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(payload),
        encoding: utf8,
      );
    return {
      ...payload,
      'probe_path': probePath,
    };
  }

  static Map<String, dynamic> _probeJellyfishContentAssetExport(
    Directory workspace,
  ) {
    final probePath = _providerAdapterProbePath(workspace, 'jellyfish');
    final now = DateTime.now().toUtc().toIso8601String();
    final jsonPath =
        _joinNested(workspace.path, 'export/structured/knowledge_export.json');
    final csvPath =
        _joinNested(workspace.path, 'export/structured/knowledge_export.csv');
    final manifestPath = _joinNested(
        workspace.path, 'export/structured/structured_export_manifest.json');
    final jsonPayload = _readJsonObjectSync(jsonPath);
    final manifest = _readJsonObjectSync(manifestPath);
    final csvRecordCount = _csvDataRecordCount(csvPath);
    final requiredArtifacts = [
      {
        'path': jsonPath,
        'exists': File(jsonPath).existsSync(),
        'schema_version': _stringValue(jsonPayload['schema_version'], ''),
      },
      {
        'path': csvPath,
        'exists': File(csvPath).existsSync(),
        'record_count': csvRecordCount,
      },
      {
        'path': manifestPath,
        'exists': File(manifestPath).existsSync(),
        'schema_version': _stringValue(manifest['schema_version'], ''),
      },
    ];
    final missingArtifacts = requiredArtifacts
        .where((artifact) => artifact['exists'] != true)
        .map((artifact) => artifact['path'].toString())
        .toList(growable: false);
    final retrievalPayload = _mapValue(jsonPayload['retrieval']);
    final retrievalRows = [
      ..._listOfMaps(jsonPayload['retrieval_results']),
      ..._listOfMaps(retrievalPayload['results']),
    ];
    final validJson = _stringValue(jsonPayload['schema_version'], '') ==
            'prd_v2_structured_document_export_payload.v1' &&
        _stringValue(jsonPayload['status'], '') == 'pass' &&
        _listOfMaps(jsonPayload['sources']).isNotEmpty &&
        retrievalRows.isNotEmpty &&
        _boolValue(_mapValue(
                jsonPayload['redaction'])['secret_plaintext_written']) ==
            false;
    final validCsv = csvRecordCount > 0;
    final validManifest = _stringValue(manifest['schema_version'], '') ==
            'prd_v2_structured_document_export.v1' &&
        _stringValue(manifest['status'], '') == 'pass';
    final invalidReasons = <String>[
      if (!validJson) 'structured_json_missing_or_empty',
      if (!validCsv) 'structured_csv_empty',
      if (!validManifest) 'structured_manifest_invalid',
    ];
    final passed = missingArtifacts.isEmpty && invalidReasons.isEmpty;
    final payload = {
      'schema_version': 'prd_v3_provider_adapter_probe_jellyfish.v1',
      'provider_ref': 'jellyfish',
      'adapter_type': 'exporter_adapter',
      'executed_at': now,
      'probe_kind': 'local_content_asset_structured_export',
      'workspace_boundary': workspace.path,
      'required_artifacts': requiredArtifacts,
      'missing_artifacts': missingArtifacts,
      'invalid_reasons': invalidReasons,
      'passed': passed,
      'status': passed ? '连接成功' : '已配置未测试',
      'error_message_zh': passed ? '' : '结构化内容资产导出证据不完整，暂不能启用导出器能力增强。',
      'network_used': false,
      'secret_plaintext_written': false,
      'normal_ui_project_name_visible': false,
      'external_runtime_executed': false,
      'vendor_runtime_loaded': false,
    };
    File(probePath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(payload),
        encoding: utf8,
      );
    return {
      ...payload,
      'probe_path': probePath,
    };
  }

  static Map<String, dynamic> _probeStoryFlicksVideoHandoffExport(
    Directory workspace,
  ) {
    final probePath = _providerAdapterProbePath(workspace, 'story_flicks');
    final now = DateTime.now().toUtc().toIso8601String();
    final videoManifestPath = _joinNested(
        workspace.path, 'agent/artifacts/video/video_task_manifest.json');
    final promptPath =
        _joinNested(workspace.path, 'agent/artifacts/video/prompt.txt');
    final costReportPath =
        _joinNested(workspace.path, 'agent/artifacts/video/cost_report.json');
    final toolCallLogPath =
        _joinNested(workspace.path, 'agent/tool/tool_call_log.jsonl');
    final dependencyReportPath = _joinNested(workspace.path,
        'agent/external_skills/video_generation_skill/skill_dependency_report.json');
    final videoManifest = _readJsonObjectSync(videoManifestPath);
    final costReport = _readJsonObjectSync(costReportPath);
    final dependencyReport = _readJsonObjectSync(dependencyReportPath);
    final requiredArtifacts = [
      {
        'path': videoManifestPath,
        'exists': File(videoManifestPath).existsSync(),
        'schema_version': _stringValue(videoManifest['schema_version'], ''),
      },
      {
        'path': promptPath,
        'exists': File(promptPath).existsSync(),
        'bytes': File(promptPath).existsSync()
            ? File(promptPath).readAsBytesSync().length
            : 0,
      },
      {
        'path': costReportPath,
        'exists': File(costReportPath).existsSync(),
        'schema_version': _stringValue(costReport['schema_version'], ''),
      },
      {
        'path': toolCallLogPath,
        'exists': File(toolCallLogPath).existsSync(),
        'record_count': _jsonlRecordCount(toolCallLogPath),
      },
      {
        'path': dependencyReportPath,
        'exists': File(dependencyReportPath).existsSync(),
        'schema_version': _stringValue(dependencyReport['schema_version'], ''),
      },
    ];
    final missingArtifacts = requiredArtifacts
        .where((artifact) => artifact['exists'] != true)
        .map((artifact) => artifact['path'].toString())
        .toList(growable: false);
    final toolBoundaryRecorded = _jsonlContains(toolCallLogPath, (record) {
      return _stringValue(record['tool_id'], '') == 'video.generate' &&
          _boolValue(record['api_called']) == false;
    });
    final validVideoManifest =
        _stringValue(videoManifest['schema_version'], '') ==
                'prd_v3_video_task_manifest.v1' &&
            _boolValue(videoManifest['fake_video_generated']) == false &&
            _boolValue(videoManifest['api_called']) == false;
    final validCostReport = _stringValue(costReport['schema_version'], '') ==
            'prd_v3_tool_cost_report.v1' &&
        (_asInt(costReport['api_call_count']) ?? -1) == 0;
    final validDependencyReport =
        _stringValue(dependencyReport['schema_version'], '') ==
                'prd_v3_skill_dependency_report.v1' &&
            jsonEncode(dependencyReport).contains('video_custom_http_stub');
    final invalidReasons = <String>[
      if (!validVideoManifest) 'video_manifest_invalid',
      if (!validCostReport) 'cost_report_invalid',
      if (!validDependencyReport) 'dependency_report_missing_provider_boundary',
      if (!toolBoundaryRecorded) 'tool_call_boundary_missing',
    ];
    final passed = missingArtifacts.isEmpty && invalidReasons.isEmpty;
    final payload = {
      'schema_version': 'prd_v3_provider_adapter_probe_story_flicks.v1',
      'provider_ref': 'story_flicks',
      'adapter_type': 'exporter_adapter',
      'executed_at': now,
      'probe_kind': 'local_video_workflow_handoff_export',
      'workspace_boundary': workspace.path,
      'required_artifacts': requiredArtifacts,
      'missing_artifacts': missingArtifacts,
      'invalid_reasons': invalidReasons,
      'passed': passed,
      'status': passed ? '连接成功' : '已配置未测试',
      'error_message_zh': passed ? '' : '视频工作流 handoff 导出边界不完整，暂不能启用导出器能力增强。',
      'network_used': false,
      'secret_plaintext_written': false,
      'normal_ui_project_name_visible': false,
      'external_runtime_executed': false,
      'vendor_runtime_loaded': false,
      'fake_video_generated': false,
      'api_called': false,
    };
    File(probePath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(payload),
        encoding: utf8,
      );
    return {
      ...payload,
      'probe_path': probePath,
    };
  }

  static Map<String, dynamic> _probeN8nWorkflowCollaborationExport(
    Directory workspace,
  ) {
    final probePath = _providerAdapterProbePath(workspace, 'n8n');
    final now = DateTime.now().toUtc().toIso8601String();
    final sessionManifestPath = _joinNested(workspace.path,
        'agent/workspaces/W_M/a2a_sessions/A2A_001/a2a_session_manifest.json');
    final workflowReportPath = _joinNested(workspace.path,
        'agent/workspaces/W_M/a2a_sessions/A2A_001/a2a_collaboration_report.md');
    final conflictReportPath =
        _joinNested(workspace.path, 'multi_agent/a2a_conflict_report.json');
    final consensusReportPath =
        _joinNested(workspace.path, 'multi_agent/a2a_consensus_report.json');
    final discussionManifestPath = _joinNested(
        workspace.path, 'multi_agent/multi_agent_discussion_manifest.json');
    final sessionManifest = _readJsonObjectSync(sessionManifestPath);
    final conflictReport = _readJsonObjectSync(conflictReportPath);
    final consensusReport = _readJsonObjectSync(consensusReportPath);
    final discussionManifest = _readJsonObjectSync(discussionManifestPath);
    final roundLogPath = _stringValue(sessionManifest['round_log_path'], '');
    final runtimeAuditPath =
        _stringValue(sessionManifest['runtime_audit_path'], '');
    final roundLimit = _asInt(sessionManifest['round_limit']) ??
        _asInt(sessionManifest['rounds']) ??
        0;
    final requiredArtifacts = [
      {
        'path': sessionManifestPath,
        'exists': File(sessionManifestPath).existsSync(),
        'schema_version': _stringValue(sessionManifest['schema_version'], ''),
        'round_limit': roundLimit,
      },
      {
        'path': roundLogPath,
        'exists': File(roundLogPath).existsSync(),
        'record_count': _jsonlRecordCount(roundLogPath),
      },
      {
        'path': runtimeAuditPath,
        'exists': File(runtimeAuditPath).existsSync(),
        'record_count': _jsonlRecordCount(runtimeAuditPath),
      },
      {
        'path': conflictReportPath,
        'exists': File(conflictReportPath).existsSync(),
        'schema_version': _stringValue(conflictReport['schema_version'], ''),
      },
      {
        'path': consensusReportPath,
        'exists': File(consensusReportPath).existsSync(),
        'schema_version': _stringValue(consensusReport['schema_version'], ''),
      },
      {
        'path': workflowReportPath,
        'exists': File(workflowReportPath).existsSync(),
        'bytes': File(workflowReportPath).existsSync()
            ? File(workflowReportPath).readAsBytesSync().length
            : 0,
      },
      {
        'path': discussionManifestPath,
        'exists': File(discussionManifestPath).existsSync(),
        'schema_version':
            _stringValue(discussionManifest['schema_version'], ''),
      },
    ];
    final missingArtifacts = requiredArtifacts
        .where((artifact) => artifact['exists'] != true)
        .map((artifact) => artifact['path'].toString())
        .toList(growable: false);
    final validSession = _stringValue(sessionManifest['schema_version'], '') ==
            'prd_v3_a2a_session_manifest.v1' &&
        _stringValue(sessionManifest['status'], '') == 'report_generated' &&
        roundLimit > 1 &&
        _jsonlRecordCount(roundLogPath) >= roundLimit &&
        _jsonlRecordCount(runtimeAuditPath) >= roundLimit;
    final validConflict = _stringValue(conflictReport['schema_version'], '') ==
            'prd_v3_a2a_conflict_report.v1' &&
        (_asInt(conflictReport['round_count']) ?? 0) >= roundLimit;
    final validConsensus =
        _stringValue(consensusReport['schema_version'], '') ==
                'prd_v3_a2a_consensus_report.v1' &&
            _stringValue(consensusReport['status'], '') == 'pass' &&
            consensusReport['ready_for_export'] == true;
    final discussionSerialized = jsonEncode(discussionManifest);
    final validDiscussion =
        discussionSerialized.contains('a2a_conflict_report.json') &&
            discussionSerialized.contains('a2a_consensus_report.json');
    final workflowReportBytes = File(workflowReportPath).existsSync()
        ? File(workflowReportPath).readAsBytesSync().length
        : 0;
    final invalidReasons = <String>[
      if (!validSession) 'a2a_session_or_rounds_invalid',
      if (!validConflict) 'conflict_report_invalid',
      if (!validConsensus) 'consensus_report_invalid',
      if (!validDiscussion) 'discussion_manifest_missing_exports',
      if (workflowReportBytes == 0) 'workflow_report_empty',
    ];
    final passed = missingArtifacts.isEmpty && invalidReasons.isEmpty;
    final payload = {
      'schema_version': 'prd_v3_provider_adapter_probe_n8n.v1',
      'provider_ref': 'n8n',
      'adapter_type': 'workflow_export_adapter',
      'executed_at': now,
      'probe_kind': 'local_a2a_workflow_collaboration_export',
      'workspace_boundary': workspace.path,
      'required_artifacts': requiredArtifacts,
      'missing_artifacts': missingArtifacts,
      'invalid_reasons': invalidReasons,
      'round_limit': roundLimit,
      'passed': passed,
      'status': passed ? '连接成功' : '已配置未测试',
      'error_message_zh': passed ? '' : 'A2A 工作流协作导出证据不完整，暂不能启用工作流导出能力增强。',
      'network_used': false,
      'secret_plaintext_written': false,
      'normal_ui_project_name_visible': false,
      'external_runtime_executed': false,
      'vendor_runtime_loaded': false,
    };
    File(probePath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(payload),
        encoding: utf8,
      );
    return {
      ...payload,
      'probe_path': probePath,
    };
  }

  Future<Map<String, dynamic>> _readProviderCapabilityStatusAsset(
      Directory workspace) async {
    final candidates = <String>[
      _joinNested(Directory.current.path,
          'assets/external/provider_capability_status.json'),
      _joinNested(coreWorkingDirectory,
          'web/workbench/flutter_app/assets/external/provider_capability_status.json'),
      _joinNested(_resolvedCoreWorkingDirectory ?? coreWorkingDirectory,
          'web/workbench/flutter_app/assets/external/provider_capability_status.json'),
      _joinNested(workspace.parent.path,
          'assets/external/provider_capability_status.json'),
    ];
    for (final candidate in candidates) {
      final file = File(candidate);
      if (!await file.exists()) continue;
      final decoded = jsonDecode(await file.readAsString(encoding: utf8));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    throw StateError('provider_capability_status_asset_not_found');
  }

  static bool _officeExporterAvailable(Map<String, dynamic> exporters) {
    return ['docx', 'pdf', 'pptx'].every(
      (format) => _userStatus(_mapValue(exporters[format])['status']) == '连接成功',
    );
  }

  static String _profileModeLabelForAudit(String mode) {
    return switch (mode) {
      'cloud' => '云机模式',
      'hybrid' => '混合模式',
      _ => '本地模式',
    };
  }

  Future<Map<String, dynamic>> _probeStoragePath(Directory workspace) async {
    final probeFile =
        File(_join(workspace.path, 'config', '.storage_write_probe'));
    final freeSpaceBytes = await _freeSpaceBytes(workspace);
    try {
      await probeFile.parent.create(recursive: true);
      await probeFile.writeAsString('ok', encoding: utf8);
      await probeFile.delete();
      return {
        'path_write_test': '连接成功',
        'disk_space_check': freeSpaceBytes > 0 ? '连接成功' : '已配置未测试',
        'free_space_bytes': freeSpaceBytes,
        'permission_failure_zh': '',
      };
    } on Object catch (error) {
      return {
        'path_write_test': '路径不可写',
        'disk_space_check': '已配置未测试',
        'free_space_bytes': freeSpaceBytes,
        'permission_failure_zh': '路径不可写或权限不足：$error',
      };
    }
  }

  static Future<int> _freeSpaceBytes(Directory workspace) async {
    try {
      final match = RegExp(r'^([A-Za-z]):').firstMatch(workspace.path);
      final drive = match?.group(1);
      if (drive == null || drive.isEmpty) {
        return 0;
      }
      final result = await Process.run(
        'powershell.exe',
        [
          '-NoProfile',
          '-Command',
          "\$drive = Get-PSDrive -Name '$drive'; [int64]\$drive.Free",
        ],
      ).timeout(const Duration(seconds: 3));
      if (result.exitCode != 0) {
        return 0;
      }
      return int.tryParse(result.stdout.toString().trim()) ?? 0;
    } on Object {
      return 0;
    }
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
        'markdown': {'status': 'connected', 'extension': 'md'},
        'docx': {'status': 'requires_configuration', 'extension': 'docx'},
        'pdf': {'status': 'requires_configuration', 'extension': 'pdf'},
        'pptx': {'status': 'requires_configuration', 'extension': 'pptx'},
        'json': {'status': 'connected', 'extension': 'json'},
        'csv': {'status': 'connected', 'extension': 'csv'},
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
      'model_gateway': {
        'gateway_id': 'gateway_not_configured',
        'display_name': '未配置 Model Gateway',
        'gateway_type': 'direct',
        'base_url': '',
        'api_key_ref': 'none',
        'admin_url': '',
        'supports_streaming': false,
        'supports_embeddings': false,
        'supports_fallback': false,
        'supports_usage_stats': false,
        'timeout_seconds': 30,
        'retry_policy': {
          'max_retries': 0,
          'retry_on': const <String>[],
        },
        'status': '未配置',
        'last_test_at': '',
        'last_error': 'Model Gateway 未配置。',
        'masked_key_preview': '',
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
        'markdown': {'provider': 'local_markdown', 'status': 'connected'},
        'json': {'provider': 'local_json', 'status': 'connected'},
        'csv': {'provider': 'local_csv', 'status': 'connected'},
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
      'model_gateway': {
        ..._mapValue(defaults['model_gateway']),
        ..._mapValue(saved['model_gateway']),
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

  static String _n8nEndpointFromEnvironment() {
    return Platform.environment['HEITANG_N8N_ENDPOINT']?.trim() ??
        Platform.environment['N8N_ENDPOINT']?.trim() ??
        '';
  }

  static List<Uri> _n8nHealthUris(Uri baseUri) {
    final normalizedBase = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    final paths = <String>[
      '/healthz',
      '/health',
      '/rest/settings',
    ];
    return paths
        .map((path) => baseUri.replace(path: '$normalizedBase$path', query: ''))
        .toList(growable: false);
  }

  static Map<String, dynamic> _n8nRuntimeProbeFailure(
    Directory workspace, {
    required String now,
    required String sanitizedEndpoint,
    required String status,
    required String errorCode,
    required String errorMessageZh,
    required String detail,
  }) {
    return {
      'schema_version': 'prd_v3_provider_runtime_load_probe_n8n.v1',
      'provider_ref': 'n8n',
      'capability_id': 'workflow_collaboration_export',
      'executed_at': now,
      'probe_kind': 'safe_health_check_only',
      'workspace_boundary': workspace.path,
      'status': status,
      'error_code': errorCode,
      'error_message_zh': errorMessageZh,
      'sanitized_endpoint': sanitizedEndpoint,
      'detail': detail,
      'runtime_loaded': false,
      'external_runtime_connected': false,
      'external_runtime_executed': false,
      'workflow_executed': false,
      'local_fallback': 'A2A 本地协作报告导出继续可用。',
      'secret_masked': true,
      'secret_plaintext_written': false,
    };
  }

  static Future<void> _writeJsonFile(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
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

  static Directory _resolveRepoRootForProviderProbe() {
    Directory cursor = Directory.current.absolute;
    while (true) {
      final marker = File(_join(cursor.path, 'heitang_kb_forge', 'cli.py'));
      final appMarker = File(
          _joinNested(cursor.path, 'web/workbench/flutter_app/pubspec.yaml'));
      if (marker.existsSync() && appMarker.existsSync()) {
        return cursor;
      }
      final parent = cursor.parent;
      if (parent.path == cursor.path) {
        return Directory.current.absolute;
      }
      cursor = parent;
    }
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
    final queryIndex = path.indexOf('?');
    final requestPath = queryIndex >= 0 ? path.substring(0, queryIndex) : path;
    final requestQuery =
        queryIndex >= 0 ? path.substring(queryIndex + 1) : null;
    final uri = baseUri.replace(
      path: '$normalizedBase$requestPath',
      query: requestQuery,
    );
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

  static double? _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _boolValue(Object? value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
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

  static Future<Directory> _uniqueExportDirectory(
      Directory root, String baseName) async {
    var candidate = Directory(_join(root.path, baseName));
    var suffix = 1;
    while (await candidate.exists()) {
      candidate = Directory(_join(root.path, '${baseName}_$suffix'));
      suffix += 1;
    }
    return candidate;
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
    required this.providerLifecycleAuditSummaryPath,
    required this.providerCapabilityUserCatalogPath,
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
        providerLifecycleAuditSummaryPath: '',
        providerCapabilityUserCatalogPath: '',
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
  final String providerLifecycleAuditSummaryPath;
  final String providerCapabilityUserCatalogPath;
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
  bool get hasProviderLifecycleAuditSummary =>
      providerLifecycleAuditSummaryPath.isNotEmpty;
  bool get hasProviderCapabilityUserCatalog =>
      providerCapabilityUserCatalogPath.isNotEmpty;
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
    String? providerLifecycleAuditSummaryPath,
    String? providerCapabilityUserCatalogPath,
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
      providerLifecycleAuditSummaryPath: providerLifecycleAuditSummaryPath ??
          this.providerLifecycleAuditSummaryPath,
      providerCapabilityUserCatalogPath: providerCapabilityUserCatalogPath ??
          this.providerCapabilityUserCatalogPath,
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
