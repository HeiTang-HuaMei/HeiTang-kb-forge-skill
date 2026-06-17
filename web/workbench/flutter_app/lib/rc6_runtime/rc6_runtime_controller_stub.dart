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

  Future<void> initialize() async {
    state = state.copyWith(
      phase: Rc6RuntimePhase.blocked,
      lastMessage: '真实文件链路需要 Windows EXE 桌面端；Flutter Web 保持 disabled_boundary。',
      lastError: 'desktop_runtime_required',
    );
    notifyListeners();
  }

  Future<void> pickAndImportFile() async => initialize();
  Future<void> pickAndImportFolder() async => initialize();
  Future<void> importOwnerInputFolder() async => initialize();
  Future<void> pickAndRunRealInputFolderE2E({String query = '赚钱 小生意'}) async =>
      initialize();
  Future<void> importFilePath(String filePath) async => initialize();
  Future<void> importFolderPath(String folderPath) async => initialize();
  Future<void> parseAndChunkSources() async => initialize();
  Future<void> buildKnowledgeBase() async => initialize();
  Future<void> search(String query) async => initialize();
  Future<void> generateMarkdown() async => initialize();
  Future<void> generateSkill() async => initialize();
  Future<void> generateAgent() async => initialize();
  Future<void> runMultiAgentDiscussion() async => initialize();
  Future<void> runRealInputFolderE2E(String folderPath,
          {String query = '赚钱 小生意'}) async =>
      initialize();
  Future<void> runOwnerInputFolderE2E({String query = '赚钱 小生意'}) async =>
      initialize();
  Future<void> runMinimumE2E({String query = 'heitang-rc6-needle'}) async =>
      initialize();
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
