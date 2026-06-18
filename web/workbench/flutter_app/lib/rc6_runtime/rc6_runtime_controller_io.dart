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
    if (_autoRunOwnerInputDocumentFlowOnLaunch()) {
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
    state = state.copyWith(
      phase: Rc6RuntimePhase.imported,
      selectedFilePath: copied.path,
      sourceManifestPath: manifestPath,
      sourceCount: sourceNames.length,
      sourceNames: sourceNames,
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
    state = state.copyWith(
      phase: Rc6RuntimePhase.imported,
      selectedFilePath: inputDir.path,
      sourceManifestPath: manifestPath,
      sourceCount: sourceNames.length,
      sourceNames: sourceNames,
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

  Future<void> buildKnowledgeBase() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    final duDir = Directory(_join(workspace.path, 'du'));
    final parseReport = File(_join(workspace.path, 'parse_report.json'));
    if (!await duDir.exists() && !await parseReport.exists()) {
      _fail('请先在导入与解析页完成解析/OCR/Chunking。');
      return;
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
      successMessage: '知识库构建完成。',
      timeout: const Duration(minutes: 15),
    );
    if (state.lastResult?.passed == true) {
      await _writeDerivedKnowledgeArtifacts();
    }
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
      'working_directory': coreWorkingDirectory,
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
    if (!_canRunDesktop()) {
      return;
    }
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      _fail('请输入搜索关键词。');
      return;
    }
    final workspace = _requireWorkspace();
    final kbDir = Directory(_join(workspace.path, 'kb'));
    if (!await kbDir.exists()) {
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
      lastMessage: '正在检索真实知识库。',
      lastError: '',
    );
    notifyListeners();
    await _runCoreAction(
      actionId: 'rag_query',
      arguments: [
        'kb-query',
        '--package',
        kbDir.path,
        '--query',
        normalizedQuery,
        '--output',
        queryDir,
      ],
      outputPath: queryDir,
      nextPhase: Rc6RuntimePhase.searched,
      successMessage: '知识库搜索完成。',
    );
    if (state.lastResult?.passed != true) {
      state = state.copyWith(searchStatus: Rc6SearchStatus.error);
      notifyListeners();
      return;
    }
    await _loadExistingArtifacts();
    final hasResults = state.searchResults.isNotEmpty;
    state = state.copyWith(
      searchStatus:
          hasResults ? Rc6SearchStatus.success : Rc6SearchStatus.empty,
      lastMessage: hasResults ? '搜索命中真实结果。' : '搜索完成，无结果。',
    );
    notifyListeners();
  }

  Future<void> generateMarkdown() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    final kbDir = Directory(_join(workspace.path, 'kb'));
    if (!await kbDir.exists()) {
      _fail('请先构建知识库，再生成文档。');
      return;
    }
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
        '真实输入读书笔记',
      ],
      outputPath: _join(workspace.path, 'doc'),
      nextPhase: Rc6RuntimePhase.documentGenerated,
      successMessage: 'Markdown 文档已生成。',
    );
    if (state.lastResult?.passed == true) {
      await _writeReadingNotes();
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
    if (!await generated.exists() && !await notes.exists()) {
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
    final source = await notes.exists() ? notes : generated;
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
    };
    await File(_join(exportDir.path, 'export_manifest.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      encoding: utf8,
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

  Future<void> exportDocumentFormat(String format) async {
    final normalized = format.trim().toLowerCase();
    if (normalized == 'md' || normalized == 'markdown') {
      await exportMarkdownDocument();
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
    if (effectivePassword.isEmpty) {
      return const Rc6StorageTestResult(
        passed: false,
        status: 'missing_password',
        detail: '缺少 Redis 密码；请设置 HEITANG_REDIS_PASSWORD 或输入掩码字段。',
      );
    }
    final safePrefix = keyPrefix.trim().isEmpty ? 'heitang:' : keyPrefix.trim();
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
        return Rc6StorageTestResult(
          passed: false,
          status: 'auth_failed',
          detail: _redisStatus(auth),
        );
      }
      final ping = await send(['PING']);
      if (!ping.startsWith('+PONG')) {
        return Rc6StorageTestResult(
          passed: false,
          status: 'ping_failed',
          detail: _redisStatus(ping),
        );
      }
      final set = await send(['SET', probeKey, 'ok']);
      final get = await send(['GET', probeKey]);
      final del = await send(['DEL', probeKey]);
      final ok = set.startsWith('+OK') &&
          get.contains('\r\nok\r\n') &&
          (del.startsWith(':1') || del.startsWith(':0'));
      return Rc6StorageTestResult(
        passed: ok,
        status: ok ? 'connected' : 'probe_failed',
        detail: ok
            ? 'Redis PING / 写入 / 读取 / 删除均通过。'
            : 'Redis 探针失败：${_redisStatus(get)}',
      );
    } on Object catch (error) {
      return Rc6StorageTestResult(
        passed: false,
        status: 'connection_failed',
        detail: _redactSecret(error.toString(), effectivePassword),
      );
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
        return Rc6StorageTestResult(
          passed: false,
          status: 'health_failed',
          detail: 'Qdrant healthz 返回 HTTP ${health.statusCode}。',
        );
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
          return Rc6StorageTestResult(
            passed: false,
            status: 'collection_create_failed',
            detail: '创建 collection 失败：HTTP ${create.statusCode}。',
          );
        }
      } else if (current.statusCode >= 400) {
        return Rc6StorageTestResult(
          passed: false,
          status: 'collection_check_failed',
          detail: 'Collection 检查失败：HTTP ${current.statusCode}。',
        );
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
        return Rc6StorageTestResult(
          passed: false,
          status: 'vector_write_failed',
          detail: '测试向量写入失败：HTTP ${upsert.statusCode}。',
        );
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
        return Rc6StorageTestResult(
          passed: false,
          status: 'vector_search_failed',
          detail: '测试向量检索失败：HTTP ${search.statusCode}。',
        );
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
      return Rc6StorageTestResult(
        passed: deleted,
        status: deleted ? 'connected' : 'vector_delete_failed',
        detail: deleted
            ? 'Qdrant health / collection / 测试向量写入检索删除均通过。'
            : '测试向量删除失败：HTTP ${delete.statusCode}。',
      );
    } on Object catch (error) {
      return Rc6StorageTestResult(
        passed: false,
        status: 'connection_failed',
        detail: _redactSecret(error.toString(), effectiveApiKey),
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<void> clearImportedSources() async {
    if (!_canRunDesktop()) {
      return;
    }
    final workspace = _requireWorkspace();
    await _clearGeneratedArtifacts(includeImport: true);
    await _clearWorkspacePath(_join(workspace.path, 'input'));
    await _clearWorkspacePath(_join(workspace.path, 'source_manifest.json'));
    state = state.copyWith(
      phase: Rc6RuntimePhase.initial,
      selectedFilePath: '',
      sourceManifestPath: '',
      parseReportPath: '',
      chunksPath: '',
      kbManifestPath: '',
      qualityReportPath: '',
      cardsPath: '',
      qaPairsPath: '',
      queryResultPath: '',
      generatedMarkdownPath: '',
      readingNotesPath: '',
      exportedDocumentPath: '',
      exportManifestPath: '',
      sourceCount: 0,
      sourceNames: const [],
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
      queryResultPath: '',
      generatedMarkdownPath: '',
      readingNotesPath: '',
      exportedDocumentPath: '',
      exportManifestPath: '',
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
      'kb',
      'query',
      'doc',
      'export',
      'skill',
      'agent',
      'multi_agent',
    ]) {
      await _clearWorkspacePath(_join(workspace.path, relative));
    }
    await _clearWorkspacePath(_join(workspace.path, 'parse_report.json'));
    state = state.copyWith(
      phase: state.hasImportedFile
          ? Rc6RuntimePhase.imported
          : Rc6RuntimePhase.initial,
      parseReportPath: '',
      chunksPath: '',
      kbManifestPath: '',
      qualityReportPath: '',
      cardsPath: '',
      qaPairsPath: '',
      queryResultPath: '',
      generatedMarkdownPath: '',
      readingNotesPath: '',
      exportedDocumentPath: '',
      exportManifestPath: '',
      skillPath: '',
      agentPath: '',
      multiAgentDiscussionPath: '',
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
    state = state.copyWith(
      phase: state.searchStatus == Rc6SearchStatus.success
          ? Rc6RuntimePhase.searched
          : state.hasKnowledgeBase
              ? Rc6RuntimePhase.knowledgeBuilt
              : Rc6RuntimePhase.imported,
      generatedMarkdownPath: '',
      readingNotesPath: '',
      exportedDocumentPath: '',
      exportManifestPath: '',
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
      'agent',
      'multi_agent',
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
      agentPath: '',
      agentDialoguePath: '',
      multiAgentDiscussionPath: '',
      lastMessage: 'Skill、Agent 和讨论产物已删除。',
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
      agentDialoguePath: '',
      multiAgentDiscussionPath: '',
      lastMessage: 'Agent、对话和讨论产物已删除。',
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
      default:
        _fail('未知任务类型：$taskId');
    }
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
    state = state.copyWith(
      phase: Rc6RuntimePhase.imported,
      selectedFilePath: inputDir.path,
      sourceManifestPath: rewrittenManifest,
      sourceCount: sourceNames.length,
      sourceNames: sourceNames,
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

  Future<void> generateSkill() async {
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
        '真实输入知识问答 Skill',
      ],
      outputPath: _join(workspace.path, 'skill', 'knowledge_qa_skill'),
      nextPhase: Rc6RuntimePhase.skillGenerated,
      successMessage: 'Skill 草稿已生成。',
    );
    if (state.lastResult?.passed == true) {
      await _writeAdditionalSkillPackages();
    }
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> generateAgent() async {
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
        'kb_bound',
        '--package',
        kbDir.path,
        '--skill',
        _primarySkillPath(skillDir.path),
        '--output',
        _join(workspace.path, 'agent', 'knowledge_qa_agent'),
        '--agent-name',
        '知识问答 Agent',
      ],
      outputPath: _join(workspace.path, 'agent', 'knowledge_qa_agent'),
      nextPhase: Rc6RuntimePhase.agentGenerated,
      successMessage: 'Agent 草稿已生成并绑定知识库/Skill。',
    );
    if (state.lastResult?.passed == true) {
      await _writeAdditionalAgentPackages();
      await _writeMultiAgentDiscussion();
    }
    await _loadExistingArtifacts();
    notifyListeners();
  }

  Future<void> runMultiAgentDiscussion() async {
    if (!_canRunDesktop()) {
      return;
    }
    if (!state.hasAgent) {
      _fail('请先在 Agent 工厂生成 Agent。');
      return;
    }
    await _writeMultiAgentDiscussion();
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
    final workspace = _requireWorkspace();
    final outDir = Directory(_join(workspace.path, 'agent', 'dialogue'));
    await outDir.create(recursive: true);
    final queryReport = await _readJsonObject(
        _join(workspace.path, 'query', 'kb_query_result.json'));
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
    final buffer = StringBuffer()
      ..writeln('# Agent 最小对话')
      ..writeln()
      ..writeln('## 用户问题')
      ..writeln(prompt)
      ..writeln()
      ..writeln('## Agent 回答')
      ..writeln('当前回答基于本地知识库和已生成 Skill，不调用外网、不执行系统命令。');
    for (final item in evidence) {
      buffer.writeln(
          '- ${_compact(item['text'] ?? item['summary'] ?? item['content'] ?? '')} (${item['citation'] ?? item['source_path'] ?? item['chunk_id'] ?? '-'})');
    }
    if (evidence.isEmpty) {
      buffer.writeln('- 当前知识库没有可用证据，请先运行检索或重新构建知识库。');
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
        'prompt': prompt,
        'output': dialoguePath,
        'evidence_count': evidence.length,
      }),
      encoding: utf8,
    );
    state = state.copyWith(
      agentDialoguePath: dialoguePath,
      lastMessage: 'Agent 最小对话已生成。',
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
      workingDirectory: coreWorkingDirectory,
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
      'kb',
      'query',
      'doc',
      'skill',
      'agent',
      'multi_agent',
    ]) {
      await _clearWorkspacePath(_join(workspace.path, relative));
    }
    await _clearWorkspacePath(_join(workspace.path, 'parse_report.json'));
    state = state.copyWith(
      phase: includeImport ? Rc6RuntimePhase.imported : state.phase,
      parseReportPath: '',
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
      readingNotesPath: '',
      multiAgentDiscussionPath: '',
      cardsPath: '',
      qaPairsPath: '',
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
    final kbManifestPath = _join(workspace.path, 'kb', 'manifest.json');
    final chunksPath = _join(workspace.path, 'kb', 'chunks.jsonl');
    final cardsPath = _join(workspace.path, 'kb', 'cards.jsonl');
    final qaPairsPath = _join(workspace.path, 'kb', 'qa_pairs.jsonl');
    final qualityPath = _join(workspace.path, 'kb', 'quality_report.json');
    final queryPath = _join(workspace.path, 'query', 'kb_query_result.json');
    final markdownPath = _join(workspace.path, 'doc', 'generated.md');
    final readingNotesPath = _join(workspace.path, 'doc', 'reading_notes.md');
    final exportedDocumentPath =
        _join(workspace.path, 'export', 'reading_notes_export.md');
    final exportManifestPath =
        _join(workspace.path, 'export', 'export_manifest.json');
    final skillPath = _join(
        _join(workspace.path, 'skill', 'knowledge_qa_skill'),
        'skill_manifest.yaml');
    final agentPath = _join(
        _join(workspace.path, 'agent', 'knowledge_qa_agent'),
        'agent_manifest.json');
    final agentDialoguePath =
        _joinNested(workspace.path, 'agent/dialogue/agent_dialogue.md');
    final multiAgentPath =
        _join(workspace.path, 'multi_agent', 'multi_agent_discussion.md');

    final importReport = await _readJsonObject(importReportPath);
    final sourceManifest = await _readJsonObject(sourceManifestPath);
    final duManifest = await _readJsonObject(duManifestPath);
    final kbReport = await _readJsonObject(
        _join(workspace.path, 'kb', 'knowledge_base_build_report.json'));
    final queryReport = await _readJsonObject(queryPath);

    final sourceCount = _asInt(kbReport['source_count']) ??
        _asInt(importReport['imported_count']) ??
        state.sourceCount;
    final sourceNames = _sourceNamesFromManifest(sourceManifest);
    final chunkCount = _countJsonl(chunksPath);
    final selectedCount = _asInt(queryReport['selected_count']) ?? 0;
    final searchResults = await _readSearchResults(queryPath);

    var phase = state.phase;
    if (await File(agentPath).exists()) {
      phase = Rc6RuntimePhase.agentGenerated;
    } else if (await File(skillPath).exists()) {
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
      chunksPath: await File(chunksPath).exists() ? chunksPath : '',
      kbManifestPath: await File(kbManifestPath).exists() ? kbManifestPath : '',
      qualityReportPath: await File(qualityPath).exists() ? qualityPath : '',
      cardsPath: await File(cardsPath).exists() ? cardsPath : '',
      qaPairsPath: await File(qaPairsPath).exists() ? qaPairsPath : '',
      queryResultPath: await File(queryPath).exists() ? queryPath : '',
      generatedMarkdownPath:
          await File(markdownPath).exists() ? markdownPath : '',
      readingNotesPath:
          await File(readingNotesPath).exists() ? readingNotesPath : '',
      exportedDocumentPath:
          await File(exportedDocumentPath).exists() ? exportedDocumentPath : '',
      exportManifestPath:
          await File(exportManifestPath).exists() ? exportManifestPath : '',
      skillPath:
          await File(skillPath).exists() ? _join(workspace.path, 'skill') : '',
      agentPath:
          await File(agentPath).exists() ? _join(workspace.path, 'agent') : '',
      agentDialoguePath:
          await File(agentDialoguePath).exists() ? agentDialoguePath : '',
      multiAgentDiscussionPath:
          await File(multiAgentPath).exists() ? multiAgentPath : '',
      sourceCount: sourceCount,
      sourceNames: sourceNames,
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

  Future<void> _writeDerivedKnowledgeArtifacts() async {
    final workspace = _requireWorkspace();
    final kbDir = _join(workspace.path, 'kb');
    await Directory(kbDir).create(recursive: true);
    final cards = await _readJsonl(File(_join(kbDir, 'cards.jsonl')));
    final qaPairs = await _readJsonl(File(_join(kbDir, 'qa_pairs.jsonl')));
    final chunks = await _readJsonl(File(_join(kbDir, 'chunks.jsonl')));
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
    };
    await File(_join(kbDir, 'rc10_real_input_derived_knowledge.json'))
        .writeAsString(const JsonEncoder.withIndent('  ').convert(summary),
            encoding: utf8);
  }

  Future<void> _writeReadingNotes() async {
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
      ..writeln('# 真实输入文件夹读书笔记')
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

  Future<void> _writeAdditionalSkillPackages() async {
    final workspace = _requireWorkspace();
    final skillRoot = Directory(_join(workspace.path, 'skill'));
    await skillRoot.create(recursive: true);
    const specs = [
      [
        'reading_summary_skill',
        '阅读总结 Skill',
        'Summarize real KB themes with source citations.'
      ],
      [
        'quality_check_skill',
        '质检 Skill',
        'Inspect parse noise, missing evidence, and review risk.'
      ],
      [
        'operation_conversion_skill',
        '运营转化 Skill',
        'Turn grounded notes into safe action checklists.'
      ],
      [
        'product_analysis_skill',
        '产品分析 Skill',
        'Analyze product/business patterns from grounded sources.'
      ],
    ];
    final manifest = <Map<String, Object?>>[];
    for (final spec in specs) {
      final dir = Directory(_join(skillRoot.path, spec[0]));
      await dir.create(recursive: true);
      final content = [
        '---',
        'name: ${spec[1]}',
        'description: ${spec[2]}',
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
        'path': dir.path,
        'kb_binding': _join(workspace.path, 'kb', 'manifest.json'),
        'status': 'generated_from_real_kb',
      };
      await File(_join(dir.path, 'skill_manifest.json')).writeAsString(
          const JsonEncoder.withIndent('  ').convert(item),
          encoding: utf8);
      manifest.add(item);
    }
    await File(_join(skillRoot.path, 'skill_generation_manifest.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'schema_version': 'rc10_real_input_skill_generation.v1',
              'status': 'pass',
              'skills': manifest,
            }),
            encoding: utf8);
  }

  Future<void> _writeAdditionalAgentPackages() async {
    final workspace = _requireWorkspace();
    final agentRoot = Directory(_join(workspace.path, 'agent'));
    await agentRoot.create(recursive: true);
    const specs = [
      [
        'reading_summary_agent',
        '阅读总结 Agent',
        'Create cited reading summaries.'
      ],
      [
        'quality_qa_agent',
        '质检 Agent',
        'Check parser quality and evidence gaps.'
      ],
      [
        'operation_conversion_agent',
        '运营转化 Agent',
        'Convert insights into action plans.'
      ],
      [
        'product_analysis_agent',
        '产品分析 Agent',
        'Analyze product and business implications.'
      ],
    ];
    final agents = <Map<String, Object?>>[];
    for (final spec in specs) {
      final dir = Directory(_join(agentRoot.path, spec[0]));
      await dir.create(recursive: true);
      final skillDir = _join(_requireWorkspace().path, 'skill');
      final payload = {
        'schema_version': 'rc10_real_input_agent.v1',
        'agent_id': spec[0],
        'name': spec[1],
        'role_goal': spec[2],
        'knowledge_binding': _join(workspace.path, 'kb', 'manifest.json'),
        'skill_binding': skillDir,
        'input_format': 'Markdown task or KB query',
        'output_format': 'Cited Markdown with source paths',
        'capability_boundary':
            'Local KB/Skill only; high-risk system capabilities are not exposed.',
        'example': 'Summarize the real input folder and cite chunks.',
      };
      await File(_join(dir.path, 'agent_manifest.json')).writeAsString(
          const JsonEncoder.withIndent('  ').convert(payload),
          encoding: utf8);
      await File(_join(dir.path, 'agent_profile.yaml')).writeAsString(
          [
            'name: ${spec[1]}',
            'role_goal: ${spec[2]}',
            'knowledge_binding: ${payload['knowledge_binding']}',
            'skill_binding: ${payload['skill_binding']}',
            'boundary: local_kb_skill_only',
          ].join('\n'),
          encoding: utf8);
      agents.add(payload);
    }
    await File(_join(agentRoot.path, 'agent_generation_manifest.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'schema_version': 'rc10_real_input_agent_generation.v1',
              'status': 'pass',
              'agents': agents,
            }),
            encoding: utf8);
  }

  Future<void> _writeMultiAgentDiscussion() async {
    final workspace = _requireWorkspace();
    final outDir = Directory(_join(workspace.path, 'multi_agent'));
    await outDir.create(recursive: true);
    final queryReport = await _readJsonObject(
        _join(workspace.path, 'query', 'kb_query_result.json'));
    final queryRows = queryReport['selected'] ??
        queryReport['results'] ??
        queryReport['records'];
    final selected = queryRows is List
        ? queryRows.whereType<Map>().take(5).toList()
        : const <Map>[];
    final topic = (queryReport['query'] ?? '真实输入文件夹主题').toString();
    final buffer = StringBuffer()
      ..writeln('# multi_agent_discussion')
      ..writeln()
      ..writeln('## Topic')
      ..writeln(topic)
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
    await File(_join(outDir.path, 'multi_agent_discussion.md'))
        .writeAsString(buffer.toString(), encoding: utf8);
    await File(_join(outDir.path, 'multi_agent_discussion_manifest.json'))
        .writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'schema_version': 'rc10_real_input_multi_agent_discussion.v1',
              'status': 'pass',
              'topic': topic,
              'agents': [
                '阅读总结 Agent',
                '知识问答 Agent',
                '质检 Agent',
                '运营转化 Agent',
                '产品分析 Agent',
              ],
              'output': _join(outDir.path, 'multi_agent_discussion.md'),
              'evidence_count': selected.length,
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
      imported.add({
        'source_path': file.path,
        'source_name': file.uri.pathSegments.last,
        'relative_path': relative,
        'size_bytes': await file.length(),
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

  static Future<List<Rc6SearchResult>> _readSearchResults(String path) async {
    final payload = await _readJsonObject(path);
    final rows =
        payload['selected'] ?? payload['results'] ?? payload['records'];
    if (rows is! List) {
      return const [];
    }
    return rows.whereType<Map>().map((row) {
      final item = Map<String, dynamic>.from(row);
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
      );
    }).toList(growable: false);
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

  static String _compact(Object? value) {
    final text =
        (value ?? '').toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length <= 180) return text;
    return '${text.substring(0, 180)}...';
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

class Rc6SearchResult {
  const Rc6SearchResult({
    required this.title,
    required this.excerpt,
    required this.citation,
    required this.score,
  });

  final String title;
  final String excerpt;
  final String citation;
  final String score;
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
    required this.chunksPath,
    required this.kbManifestPath,
    required this.qualityReportPath,
    required this.cardsPath,
    required this.qaPairsPath,
    required this.queryResultPath,
    required this.generatedMarkdownPath,
    required this.readingNotesPath,
    required this.exportedDocumentPath,
    required this.exportManifestPath,
    required this.skillPath,
    required this.agentPath,
    required this.agentDialoguePath,
    required this.multiAgentDiscussionPath,
    required this.sourceCount,
    required this.sourceNames,
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
        chunksPath: '',
        kbManifestPath: '',
        qualityReportPath: '',
        cardsPath: '',
        qaPairsPath: '',
        queryResultPath: '',
        generatedMarkdownPath: '',
        readingNotesPath: '',
        exportedDocumentPath: '',
        exportManifestPath: '',
        skillPath: '',
        agentPath: '',
        agentDialoguePath: '',
        multiAgentDiscussionPath: '',
        sourceCount: 0,
        sourceNames: [],
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
  final String chunksPath;
  final String kbManifestPath;
  final String qualityReportPath;
  final String cardsPath;
  final String qaPairsPath;
  final String queryResultPath;
  final String generatedMarkdownPath;
  final String readingNotesPath;
  final String exportedDocumentPath;
  final String exportManifestPath;
  final String skillPath;
  final String agentPath;
  final String agentDialoguePath;
  final String multiAgentDiscussionPath;
  final int sourceCount;
  final List<String> sourceNames;
  final int chunkCount;
  final String searchQuery;
  final Rc6SearchStatus searchStatus;
  final List<Rc6SearchResult> searchResults;
  final String lastMessage;
  final String lastError;
  final CoreBridgeResult? lastResult;

  bool get hasImportedFile => sourceManifestPath.isNotEmpty;
  bool get hasKnowledgeBase => kbManifestPath.isNotEmpty && chunkCount > 0;
  bool get hasMarkdown => generatedMarkdownPath.isNotEmpty;
  bool get hasReadingNotes => readingNotesPath.isNotEmpty;
  bool get hasExportedDocument => exportedDocumentPath.isNotEmpty;
  bool get hasSkill => skillPath.isNotEmpty;
  bool get hasAgent => agentPath.isNotEmpty;
  bool get hasAgentDialogue => agentDialoguePath.isNotEmpty;
  bool get hasMultiAgentDiscussion => multiAgentDiscussionPath.isNotEmpty;

  Rc6RuntimeState copyWith({
    Rc6RuntimePhase? phase,
    bool? running,
    String? workspacePath,
    String? selectedFilePath,
    String? sourceManifestPath,
    String? parseReportPath,
    String? chunksPath,
    String? kbManifestPath,
    String? qualityReportPath,
    String? cardsPath,
    String? qaPairsPath,
    String? queryResultPath,
    String? generatedMarkdownPath,
    String? readingNotesPath,
    String? exportedDocumentPath,
    String? exportManifestPath,
    String? skillPath,
    String? agentPath,
    String? agentDialoguePath,
    String? multiAgentDiscussionPath,
    int? sourceCount,
    List<String>? sourceNames,
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
      chunksPath: chunksPath ?? this.chunksPath,
      kbManifestPath: kbManifestPath ?? this.kbManifestPath,
      qualityReportPath: qualityReportPath ?? this.qualityReportPath,
      cardsPath: cardsPath ?? this.cardsPath,
      qaPairsPath: qaPairsPath ?? this.qaPairsPath,
      queryResultPath: queryResultPath ?? this.queryResultPath,
      generatedMarkdownPath:
          generatedMarkdownPath ?? this.generatedMarkdownPath,
      readingNotesPath: readingNotesPath ?? this.readingNotesPath,
      exportedDocumentPath: exportedDocumentPath ?? this.exportedDocumentPath,
      exportManifestPath: exportManifestPath ?? this.exportManifestPath,
      skillPath: skillPath ?? this.skillPath,
      agentPath: agentPath ?? this.agentPath,
      agentDialoguePath: agentDialoguePath ?? this.agentDialoguePath,
      multiAgentDiscussionPath:
          multiAgentDiscussionPath ?? this.multiAgentDiscussionPath,
      sourceCount: sourceCount ?? this.sourceCount,
      sourceNames: sourceNames ?? this.sourceNames,
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
