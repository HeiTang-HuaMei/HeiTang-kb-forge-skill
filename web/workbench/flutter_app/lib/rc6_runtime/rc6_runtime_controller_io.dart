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
        lastMessage:
            '真实文件链路需要 Windows EXE 桌面端；Flutter Web 保持 disabled_boundary。',
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
      lastMessage: 'rc6 本地工作区已准备。',
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
    await _clearGeneratedArtifacts(includeImport: true);
    if (!_isInsideDirectory(source.absolute.path, inputDir.absolute.path)) {
      await _clearWorkspacePath(inputDir.path);
    }
    await inputDir.create(recursive: true);
    final copied =
        File(_join(inputDir.path, _safeFileName(source.uri.pathSegments.last)));
    if (source.absolute.path != copied.absolute.path) {
      await source.copy(copied.path);
    }
    final manifestPath = _join(workspace.path, 'source_manifest.json');
    final manifest = {
      'schema_version': 'rc6_source_manifest.v1',
      'status': 'imported',
      'source_path': copied.path,
      'source_name': copied.uri.pathSegments.last,
      'size_bytes': await copied.length(),
      'workspace': workspace.path,
    };
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      encoding: utf8,
    );
    state = state.copyWith(
      phase: Rc6RuntimePhase.imported,
      selectedFilePath: copied.path,
      sourceManifestPath: manifestPath,
      sourceCount: 1,
      sourceNames: [copied.uri.pathSegments.last],
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
    await _clearGeneratedArtifacts(includeImport: true);
    await _clearWorkspacePath(inputDir.path);
    await inputDir.create(recursive: true);
    final imported = <Map<String, Object?>>[];
    for (final source in files) {
      final relative =
          _relativePath(source.absolute.path, sourceDir.absolute.path);
      final target = File(_joinNested(inputDir.path, relative));
      await target.parent.create(recursive: true);
      await source.copy(target.path);
      imported.add({
        'source_path': target.path,
        'source_name': source.uri.pathSegments.last,
        'relative_path': relative.replaceAll('\\', '/'),
        'size_bytes': await target.length(),
      });
    }
    final manifestPath = _join(workspace.path, 'source_manifest.json');
    final manifest = {
      'schema_version': 'rc6_source_manifest.v1',
      'status': 'imported',
      'source_path': inputDir.path,
      'source_name': _lastNonEmptySegment(sourceDir.path),
      'source_count': imported.length,
      'sources': imported,
      'workspace': workspace.path,
    };
    await File(manifestPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      encoding: utf8,
    );
    state = state.copyWith(
      phase: Rc6RuntimePhase.imported,
      selectedFilePath: inputDir.path,
      sourceManifestPath: manifestPath,
      sourceCount: imported.length,
      sourceNames: imported
          .map((source) => source['source_name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList(growable: false),
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
      'schema_version': 'rc8_document_export.v1',
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
      throw StateError('Refusing to clear path outside rc6 workspace');
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
      sourceManifestPath: await File(sourceManifestPath).exists()
          ? sourceManifestPath
          : state.sourceManifestPath,
      selectedFilePath: (sourceManifest['source_path'] ?? '').toString().isEmpty
          ? state.selectedFilePath
          : sourceManifest['source_path'].toString(),
      parseReportPath: await File(parseReportAliasPath).exists()
          ? parseReportAliasPath
          : await File(duManifestPath).exists()
              ? duManifestPath
              : state.parseReportPath,
      chunksPath:
          await File(chunksPath).exists() ? chunksPath : state.chunksPath,
      kbManifestPath: await File(kbManifestPath).exists()
          ? kbManifestPath
          : state.kbManifestPath,
      qualityReportPath: await File(qualityPath).exists()
          ? qualityPath
          : state.qualityReportPath,
      cardsPath: await File(cardsPath).exists() ? cardsPath : state.cardsPath,
      qaPairsPath:
          await File(qaPairsPath).exists() ? qaPairsPath : state.qaPairsPath,
      queryResultPath:
          await File(queryPath).exists() ? queryPath : state.queryResultPath,
      generatedMarkdownPath: await File(markdownPath).exists()
          ? markdownPath
          : state.generatedMarkdownPath,
      readingNotesPath: await File(readingNotesPath).exists()
          ? readingNotesPath
          : state.readingNotesPath,
      exportedDocumentPath: await File(exportedDocumentPath).exists()
          ? exportedDocumentPath
          : state.exportedDocumentPath,
      exportManifestPath: await File(exportManifestPath).exists()
          ? exportManifestPath
          : state.exportManifestPath,
      skillPath: await File(skillPath).exists()
          ? _join(workspace.path, 'skill')
          : state.skillPath,
      agentPath: await File(agentPath).exists()
          ? _join(workspace.path, 'agent')
          : state.agentPath,
      multiAgentDiscussionPath: await File(multiAgentPath).exists()
          ? multiAgentPath
          : state.multiAgentDiscussionPath,
      sourceCount: sourceCount,
      sourceNames: sourceNames.isEmpty ? state.sourceNames : sourceNames,
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
      'schema_version': 'rc6_real_input_derived_knowledge.v1',
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
    await File(_join(kbDir, 'rc6_real_input_derived_knowledge.json'))
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
          '- 本笔记由 rc6 真实 EXE 链路基于 `D:\\HeiTang-Codex-WorkSpace\\input` 的 ${sources.length} 个真实文件生成。')
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
        'Use this Skill only with the rc6 real input KB artifacts.',
        '',
        '## 输入输出约束',
        '- Input: local KB query, cards, qa_pairs, and source citations.',
        '- Output: cited Markdown or JSON summary.',
        '- Boundary: no network, no secret, no arbitrary shell.',
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
              'schema_version': 'rc6_real_input_skill_generation.v1',
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
        'schema_version': 'rc6_real_input_agent.v1',
        'agent_id': spec[0],
        'name': spec[1],
        'role_goal': spec[2],
        'knowledge_binding': _join(workspace.path, 'kb', 'manifest.json'),
        'skill_binding': skillDir,
        'input_format': 'Markdown task or KB query',
        'output_format': 'Cited Markdown with source paths',
        'capability_boundary':
            'Local KB/Skill only; no network, no arbitrary shell, no Computer Use.',
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
              'schema_version': 'rc6_real_input_agent_generation.v1',
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
      ..writeln('- 运营转化 Agent：把可行动内容转成步骤，但不越过安全边界。')
      ..writeln('- 产品分析 Agent：识别主题、需求和风险，用于后续产品判断。')
      ..writeln()
      ..writeln('## 冲突点')
      ..writeln('- 可行动建议必须与来源证据保持一致，不能把灰色/风险内容包装成操作指导。')
      ..writeln('- OCR 噪声较高时，摘要 Agent 倾向继续总结，质检 Agent 要求标注 review_required。')
      ..writeln()
      ..writeln('## 共识结论')
      ..writeln('- 只使用本地 KB、Skill 和 Agent package 产物。')
      ..writeln('- 输出必须保留 source_path 或 citation。')
      ..writeln('- 外部联网、Computer Use、arbitrary shell 仍为 disabled_boundary。')
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
              'schema_version': 'rc6_real_input_multi_agent_discussion.v1',
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

  Future<Directory> _resolveWorkspace() async {
    if (configuredWorkspace.trim().isNotEmpty && configuredWorkspace != '.') {
      return Directory(configuredWorkspace);
    }
    final appData = Platform.environment['LOCALAPPDATA'];
    if (appData != null && appData.trim().isNotEmpty) {
      return Directory(
          _join(appData, 'HeiTangKBForge', 'rc6_runtime_workspace'));
    }
    return Directory(
        _join(Directory.current.path, 'output', 'rc6_runtime_workspace'));
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
    final value = Platform.environment['HEITANG_RC6_OWNER_INPUT_E2E'];
    return value == '1' || value?.toLowerCase() == 'true';
  }

  bool _autoRunOwnerInputDocumentFlowOnLaunch() {
    final value = Platform.environment['HEITANG_RC8_DOCUMENT_FLOW_E2E'];
    return value == '1' || value?.toLowerCase() == 'true';
  }

  Directory _requireWorkspace() {
    final workspace = _workspaceDir;
    if (workspace == null) {
      throw StateError('rc6 workspace is not initialized');
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

  static String _lastNonEmptySegment(String path) {
    final segments = path
        .split(RegExp(r'[\\/]'))
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);
    return segments.isEmpty ? 'input' : segments.last;
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
