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

  Future<void> buildKnowledgeBase() async {
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
      ],
      outputPath: _join(workspace.path, 'du'),
      nextPhase: Rc6RuntimePhase.documentUnderstanding,
      successMessage: 'Document Understanding 完成。',
    );
    if (state.lastResult?.passed != true) {
      return;
    }
    await _writeParseReportAlias();
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
    );
    await _loadExistingArtifacts();
    notifyListeners();
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
        'RC6 Runtime Truth Report',
      ],
      outputPath: _join(workspace.path, 'doc'),
      nextPhase: Rc6RuntimePhase.documentGenerated,
      successMessage: 'Markdown 文档已生成。',
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
        _join(workspace.path, 'skill'),
        '--skill-name',
        'RC6 Runtime Truth Skill',
      ],
      outputPath: _join(workspace.path, 'skill'),
      nextPhase: Rc6RuntimePhase.skillGenerated,
      successMessage: 'Skill 草稿已生成。',
    );
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
        skillDir.path,
        '--output',
        _join(workspace.path, 'agent'),
        '--agent-name',
        'RC6 Runtime Truth Agent',
      ],
      outputPath: _join(workspace.path, 'agent'),
      nextPhase: Rc6RuntimePhase.agentGenerated,
      successMessage: 'Agent 草稿已生成并绑定知识库/Skill。',
    );
    await _loadExistingArtifacts();
    notifyListeners();
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
      timeout: const Duration(minutes: 5),
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
      skillPath: '',
      agentPath: '',
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
    final qualityPath = _join(workspace.path, 'kb', 'quality_report.json');
    final queryPath = _join(workspace.path, 'query', 'kb_query_result.json');
    final markdownPath = _join(workspace.path, 'doc', 'generated.md');
    final skillPath = _join(workspace.path, 'skill', 'skill_manifest.yaml');
    final agentPath = _join(workspace.path, 'agent', 'agent_manifest.json');

    final importReport = await _readJsonObject(importReportPath);
    final sourceManifest = await _readJsonObject(sourceManifestPath);
    final duManifest = await _readJsonObject(duManifestPath);
    final kbReport = await _readJsonObject(
        _join(workspace.path, 'kb', 'knowledge_base_build_report.json'));
    final queryReport = await _readJsonObject(queryPath);

    final sourceCount = _asInt(kbReport['source_count']) ??
        _asInt(importReport['imported_count']) ??
        state.sourceCount;
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
      queryResultPath:
          await File(queryPath).exists() ? queryPath : state.queryResultPath,
      generatedMarkdownPath: await File(markdownPath).exists()
          ? markdownPath
          : state.generatedMarkdownPath,
      skillPath: await File(skillPath).exists()
          ? _join(workspace.path, 'skill')
          : state.skillPath,
      agentPath: await File(agentPath).exists()
          ? _join(workspace.path, 'agent')
          : state.agentPath,
      sourceCount: sourceCount,
      chunkCount: chunkCount,
      searchResults: searchResults,
      searchStatus: selectedCount > 0
          ? Rc6SearchStatus.success
          : state.searchStatus == Rc6SearchStatus.loading
              ? Rc6SearchStatus.empty
              : state.searchStatus,
    );
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
    required this.queryResultPath,
    required this.generatedMarkdownPath,
    required this.skillPath,
    required this.agentPath,
    required this.sourceCount,
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
        queryResultPath: '',
        generatedMarkdownPath: '',
        skillPath: '',
        agentPath: '',
        sourceCount: 0,
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
  final String queryResultPath;
  final String generatedMarkdownPath;
  final String skillPath;
  final String agentPath;
  final int sourceCount;
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
  bool get hasSkill => skillPath.isNotEmpty;
  bool get hasAgent => agentPath.isNotEmpty;

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
    String? queryResultPath,
    String? generatedMarkdownPath,
    String? skillPath,
    String? agentPath,
    int? sourceCount,
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
      queryResultPath: queryResultPath ?? this.queryResultPath,
      generatedMarkdownPath:
          generatedMarkdownPath ?? this.generatedMarkdownPath,
      skillPath: skillPath ?? this.skillPath,
      agentPath: agentPath ?? this.agentPath,
      sourceCount: sourceCount ?? this.sourceCount,
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
