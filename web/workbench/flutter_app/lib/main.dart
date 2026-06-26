import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart'
    show Clipboard, LogicalKeyboardKey, rootBundle;

import 'core_bridge/local_core_bridge.dart';
import 'contracts/workbench_contracts.dart';
import 'rc6_runtime/rc6_runtime_controller.dart';

part 'app/product_top_bar.dart';
part 'app/desktop_status_bar.dart';
part 'app/workbench_sidebar.dart';
part 'app/workbench_shell.dart';
part 'app/workbench_pages.dart';
part 'shared/workbench_layout.dart';
part 'shared/product_components.dart';
part 'features/dashboard/dashboard_product_workflow.dart';
part 'features/import_parsing/import_product_workflow.dart';
part 'features/artifacts/artifact_center_product_workflow.dart';
part 'features/audit/audit_center_product_workflow.dart';
part 'features/settings/settings_product_workflow.dart';
part 'features/workbook/workbook_product_workflow.dart';
part 'features/retrieval/retrieval_verification_product_workflow.dart';
part 'features/document_library/document_library_product_workflow.dart';
part 'features/document_generation/document_generation_product_workflow.dart';
part 'features/knowledge_base/knowledge_base_product_workflow.dart';
part 'features/skill/skill_builder_product_workflow.dart';
part 'features/agent/agent_product_workflow.dart';

void main() {
  runApp(const HeiTangWorkbenchApp());
}

abstract final class _DesktopGrid {
  static const double initialWindowWidth = 1440;
  static const double initialWindowHeight = 900;
  static const double figmaContentWidth = 1112;
  static const double compactDesktopMax = 1440;
  static const double standardDesktopMax = 1920;
  static const double standardContentWidth = 1680;
  static const double wideContentWidth = 1840;
  static const double gutter = 16;
  static const double panelPadding = 18;
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusPanel = 18;
  static const double panelRadius = radiusLarge;
  static const double pageRadius = radiusMedium;
  static const double buttonRadius = radiusSmall;
  static const double chipRadius = 999;
  static const double panelMinHeight = 156;
  static const double metricHeight = 122;
  static const double rowBreakpoint = 960;
  static const double footerSafeArea = 84;
}

class _AppVisualTokens {
  const _AppVisualTokens({
    required this.appBackground,
    required this.sidebarBackground,
    required this.topBarBackground,
    required this.surfaceBase,
    required this.surfaceSubtle,
    required this.surfaceMuted,
    required this.surfaceRaised,
    required this.surfaceHighlight,
    required this.borderSubtle,
    required this.borderNormal,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentMacBlue,
    required this.success,
    required this.warning,
    required this.danger,
    required this.shadow,
  });

  final Color appBackground;
  final Color sidebarBackground;
  final Color topBarBackground;
  final Color surfaceBase;
  final Color surfaceSubtle;
  final Color surfaceMuted;
  final Color surfaceRaised;
  final Color surfaceHighlight;
  final Color borderSubtle;
  final Color borderNormal;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color accentMacBlue;
  final Color success;
  final Color warning;
  final Color danger;
  final List<BoxShadow> shadow;
}

abstract final class _HTKWTokens {
  static const Color background = Color(0xfff5f7fb);
  static const Color surface = Color(0xffffffff);
  static const Color softSurface = Color(0xfff8fafc);
  static const Color mutedSurface = Color(0xfff1f5f9);
  static const Color borderSubtle = Color(0x140f172a);
  static const Color border = Color(0x1f0f172a);
  static const Color textPrimary = Color(0xff111827);
  static const Color textSecondary = Color(0xff475569);
  static const Color textTertiary = Color(0xff94a3b8);
  static const Color sidebar = Color(0xc7ffffff);
  static const Color topBar = Color(0xd1ffffff);
  static const Color accent = Color(0xff6366f1);
  static const Color accentSoft = Color(0xffeef2ff);
  static const Color accentBlue = Color(0xff0a84ff);
  static const Color gold = accent;
  static const Color goldSoft = accentSoft;
  static const Color amber = Color(0xfff59e0b);
  static const Color amberSoft = Color(0xfffff7ed);
  static const Color sage = Color(0xff10b981);
  static const Color sageSoft = Color(0xffecfdf5);
  static const Color blue = accentBlue;
  static const Color blueSoft = Color(0xffe8f3ff);
  static const Color plum = accent;
  static const Color plumSoft = accentSoft;
  static const Color red = Color(0xffef4444);
  static const Color redSoft = Color(0xfffff1e8);

  static const Color moduleDocument = Color(0xff6366f1);
  static const Color moduleKnowledge = Color(0xff0a84ff);
  static const Color moduleRetrieval = Color(0xff14b8a6);
  static const Color moduleGeneration = Color(0xfff59e0b);
  static const Color moduleSkill = Color(0xff8b5cf6);
  static const Color moduleAssistant = Color(0xffec4899);
  static const Color moduleArtifact = Color(0xff10b981);
  static const Color moduleAudit = Color(0xff64748b);
  static const Color moduleSettings = Color(0xff6b7280);

  static const Color darkBackground = Color(0xff1c1c1e);
  static const Color darkWindowSurface = Color(0xff242426);
  static const Color darkSurface = Color(0xff2c2c2e);
  static const Color darkSurfaceRaised = Color(0xff343436);
  static const Color darkSurfaceHighlight = Color(0xff3a3a3c);
  static const Color darkSidebar = Color(0xd11c1c1e);
  static const Color darkTopBar = Color(0xdb1c1c1e);
  static const Color darkBorderSubtle = Color(0x14ffffff);
  static const Color darkBorderNormal = Color(0x1fffffff);
  static const Color darkTextPrimary = Color(0xebffffff);
  static const Color darkTextSecondary = Color(0xa3ffffff);
  static const Color darkTextTertiary = Color(0x66ffffff);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xff0f172a).withValues(alpha: 0.028),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];

  static _AppVisualTokens visualTokens(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    if (dark) {
      return const _AppVisualTokens(
        appBackground: darkBackground,
        sidebarBackground: darkSidebar,
        topBarBackground: darkTopBar,
        surfaceBase: darkWindowSurface,
        surfaceSubtle: darkSurface,
        surfaceMuted: darkSurface,
        surfaceRaised: darkSurfaceRaised,
        surfaceHighlight: darkSurfaceHighlight,
        borderSubtle: darkBorderSubtle,
        borderNormal: darkBorderNormal,
        textPrimary: darkTextPrimary,
        textSecondary: darkTextSecondary,
        textTertiary: darkTextTertiary,
        accent: accentBlue,
        accentMacBlue: accentBlue,
        success: Color(0xff30d158),
        warning: Color(0xffff9f0a),
        danger: Color(0xffff453a),
        shadow: [],
      );
    }
    return _AppVisualTokens(
      appBackground: background,
      sidebarBackground: sidebar,
      topBarBackground: topBar,
      surfaceBase: surface,
      surfaceSubtle: softSurface,
      surfaceMuted: mutedSurface,
      surfaceRaised: surface,
      surfaceHighlight: softSurface,
      borderSubtle: borderSubtle,
      borderNormal: border,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textTertiary: textTertiary,
      accent: accent,
      accentMacBlue: accentBlue,
      success: sage,
      warning: amber,
      danger: red,
      shadow: cardShadow,
    );
  }

  static Color panelSurface(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurface : surface;

  static Color recessedSurface(Brightness brightness) =>
      brightness == Brightness.dark ? darkWindowSurface : softSurface;

  static Color glassSurface(Brightness brightness) =>
      brightness == Brightness.dark
          ? darkSurfaceHighlight.withValues(alpha: 0.62)
          : surface.withValues(alpha: 0.72);

  static Color toneColor(_StatusTone tone) => switch (tone) {
        _StatusTone.success => sage,
        _StatusTone.warning => amber,
        _StatusTone.danger => red,
        _StatusTone.neutral => blue,
      };

  static Color toneSurface(_StatusTone tone) => switch (tone) {
        _StatusTone.success => sageSoft,
        _StatusTone.warning => amberSoft,
        _StatusTone.danger => redSoft,
        _StatusTone.neutral => blueSoft,
      };

  static Color moduleColor(String pageId) => switch (pageId) {
        'dashboard' => accent,
        'import-parsing' || 'document-library' => moduleDocument,
        'knowledge-package-management' => moduleKnowledge,
        'retrieval-verification' => moduleRetrieval,
        'document-generation' => moduleGeneration,
        'skill-factory' => moduleSkill,
        'agent-factory-runtime' => moduleAssistant,
        'artifact-center' => moduleArtifact,
        'reports-audit' => moduleAudit,
        'workspace' => moduleSettings,
        'workbook' => moduleAudit,
        _ => accent,
      };

  static Color moduleTint(
    String pageId,
    Brightness brightness, {
    double lightAlpha = 0.1,
    double darkAlpha = 0.14,
  }) {
    return moduleColor(pageId).withValues(
      alpha: brightness == Brightness.dark ? darkAlpha : lightAlpha,
    );
  }

  static Color moduleBorderTint(
    String pageId,
    Brightness brightness, {
    double lightAlpha = 0.18,
    double darkAlpha = 0.2,
  }) {
    return moduleColor(pageId).withValues(
      alpha: brightness == Brightness.dark ? darkAlpha : lightAlpha,
    );
  }
}

enum _DesktopWindowPreviewState { restored, maximized }

const supportedLocaleCodes = <String>['zh-CN', 'en-US'];
const _appVersionLabel = 'v4.3.0-rc10';

class _Rc6RuntimeScope extends InheritedNotifier<Rc6RuntimeController> {
  const _Rc6RuntimeScope({
    required Rc6RuntimeController controller,
    required super.child,
  }) : super(notifier: controller);

  static Rc6RuntimeController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_Rc6RuntimeScope>()
        ?.notifier;
  }
}

class HeiTangWorkbenchApp extends StatefulWidget {
  const HeiTangWorkbenchApp({
    super.key,
    this.contracts,
    this.workflowEvidence,
    this.workflowV2Evidence,
    this.externalCapabilities,
    this.providerCapabilityStatus,
    this.parserBackends,
    this.campaign6AgentRuntimeStatus,
    this.campaign7ConfigurationStatus,
    this.campaign9DesktopDeliveryStatus,
    this.skillGovernanceReport,
    this.methodologyMap,
    this.skillSuiteWorkflow,
    this.coreBridge = const LocalCoreBridge(),
    this.coreCli = 'heitang-kb-forge',
    this.coreWorkingDirectory = '.',
    this.coreWorkspace = '.',
    this.enableLocalCoreActions = true,
    this.isWebRuntime = kIsWeb,
    this.initialSelectedIndex = 0,
  });

  final WorkbenchContracts? contracts;
  final P1WorkflowEvidence? workflowEvidence;
  final P1WorkflowEvidence? workflowV2Evidence;
  final ExternalCapabilityRegistry? externalCapabilities;
  final ProviderCapabilityStatus? providerCapabilityStatus;
  final ParserBackendMatrix? parserBackends;
  final Map<String, dynamic>? campaign6AgentRuntimeStatus;
  final Map<String, dynamic>? campaign7ConfigurationStatus;
  final Map<String, dynamic>? campaign9DesktopDeliveryStatus;
  final Map<String, dynamic>? skillGovernanceReport;
  final Map<String, dynamic>? methodologyMap;
  final Map<String, dynamic>? skillSuiteWorkflow;
  final LocalCoreBridge coreBridge;
  final String coreCli;
  final String coreWorkingDirectory;
  final String coreWorkspace;
  final bool enableLocalCoreActions;
  final bool isWebRuntime;
  final int initialSelectedIndex;

  @override
  State<HeiTangWorkbenchApp> createState() => _HeiTangWorkbenchAppState();
}

class _HeiTangWorkbenchAppState extends State<HeiTangWorkbenchApp> {
  String localeCode = 'zh-CN';
  ThemeMode themeMode = ThemeMode.light;
  late int selectedIndex = widget.initialSelectedIndex;
  late Rc6RuntimeController _rc6RuntimeController;
  late final Future<WorkbenchContracts> _contractsFuture =
      widget.contracts == null
          ? const WorkbenchContractLoader()
              .loadFromAsset('assets/contracts/p1_core_contract_fixture.json')
              .catchError((_) => sampleWorkbenchContracts)
          : Future<WorkbenchContracts>.value(widget.contracts);
  late final Future<P1WorkflowEvidence> _workflowEvidenceFuture = widget
              .workflowEvidence ==
          null
      ? const P1WorkflowEvidenceLoader()
          .loadFromAsset('assets/workflows/p1_real_workflow_v1_evidence.json')
          .catchError((_) => sampleP1WorkflowEvidence)
      : Future<P1WorkflowEvidence>.value(widget.workflowEvidence);
  late final Future<P1WorkflowEvidence> _workflowV2EvidenceFuture = widget
              .workflowV2Evidence ==
          null
      ? const P1WorkflowEvidenceLoader()
          .loadFromAsset('assets/workflows/p1_real_workflow_v2_evidence.json')
          .catchError((_) => sampleP1WorkflowV2Evidence)
      : Future<P1WorkflowEvidence>.value(widget.workflowV2Evidence);
  late final Future<ExternalCapabilityRegistry> _externalCapabilitiesFuture =
      widget.externalCapabilities == null
          ? const ExternalCapabilityLoader()
              .loadFromAsset(
                  'assets/external/external_capability_registry.json')
              .catchError((_) => sampleExternalCapabilityRegistry)
          : Future<ExternalCapabilityRegistry>.value(
              widget.externalCapabilities);
  late final Future<ProviderCapabilityStatus> _providerCapabilityStatusFuture =
      widget.providerCapabilityStatus == null
          ? const ProviderCapabilityStatusLoader()
              .loadFromAsset('assets/external/provider_capability_status.json')
              .catchError((_) => sampleProviderCapabilityStatus)
          : Future<ProviderCapabilityStatus>.value(
              widget.providerCapabilityStatus);
  late final Future<ParserBackendMatrix> _parserBackendsFuture = widget
              .parserBackends ==
          null
      ? const ParserBackendMatrixLoader()
          .loadFromAsset('assets/parser_backends/parser_backend_matrix.json')
          .catchError((_) => sampleParserBackendMatrix)
      : Future<ParserBackendMatrix>.value(widget.parserBackends);
  late final Future<
      Map<String, dynamic>> _campaign6AgentRuntimeStatusFuture = widget
              .campaign6AgentRuntimeStatus ==
          null
      ? rootBundle
          .loadString(
              'assets/contracts/campaign6_agent_runtime_status_2026_06_17.json')
          .then((source) => jsonDecode(source) as Map<String, dynamic>)
          .catchError((_) => sampleCampaign6AgentRuntimeStatus)
      : Future<Map<String, dynamic>>.value(widget.campaign6AgentRuntimeStatus);
  late final Future<Map<String, dynamic>> _campaign7ConfigurationStatusFuture =
      widget.campaign7ConfigurationStatus == null
          ? rootBundle
              .loadString(
                  'assets/contracts/campaign7_configuration_system_status_2026_06_17.json')
              .then((source) => jsonDecode(source) as Map<String, dynamic>)
              .catchError((_) => sampleCampaign7ConfigurationStatus)
          : Future<Map<String, dynamic>>.value(
              widget.campaign7ConfigurationStatus);
  late final Future<Map<String, dynamic>>
      _campaign9DesktopDeliveryStatusFuture =
      widget.campaign9DesktopDeliveryStatus == null
          ? rootBundle
              .loadString(
                  'assets/contracts/campaign9_desktop_delivery_status_2026_06_17.json')
              .then((source) => jsonDecode(source) as Map<String, dynamic>)
              .catchError((_) => sampleCampaign9DesktopDeliveryStatus)
          : Future<Map<String, dynamic>>.value(
              widget.campaign9DesktopDeliveryStatus);
  late final Future<Map<String, dynamic>> _skillGovernanceReportFuture =
      Future<Map<String, dynamic>>.value(
          widget.skillGovernanceReport ?? sampleSkillGovernanceReport);

  bool get isDark => themeMode == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _rc6RuntimeController = _createRc6RuntimeController();
    if (_rc6RuntimeController.prefersAgentConsoleInitialPage) {
      selectedIndex = _pageIndexById('agent-factory-runtime');
    }
    unawaited(_rc6RuntimeController.initialize());
  }

  @override
  void didUpdateWidget(covariant HeiTangWorkbenchApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coreBridge != widget.coreBridge ||
        oldWidget.coreCli != widget.coreCli ||
        oldWidget.coreWorkingDirectory != widget.coreWorkingDirectory ||
        oldWidget.coreWorkspace != widget.coreWorkspace ||
        oldWidget.isWebRuntime != widget.isWebRuntime) {
      _rc6RuntimeController.dispose();
      _rc6RuntimeController = _createRc6RuntimeController();
      unawaited(_rc6RuntimeController.initialize());
    }
  }

  @override
  void dispose() {
    _rc6RuntimeController.dispose();
    super.dispose();
  }

  Rc6RuntimeController _createRc6RuntimeController() {
    return Rc6RuntimeController(
      coreBridge: widget.coreBridge,
      coreCli: widget.coreCli,
      coreWorkingDirectory: widget.coreWorkingDirectory,
      configuredWorkspace: widget.coreWorkspace,
      isWebRuntime: widget.isWebRuntime,
    );
  }

  Map<ShortcutActivator, VoidCallback> _automationShortcuts(
    BuildContext context,
  ) {
    void go(int index) {
      if (index >= 0 && index < pages.length) {
        setState(() => selectedIndex = index);
      }
    }

    void run(Future<void> Function(Rc6RuntimeController rc6) action) {
      if (_rc6RuntimeController.state.running) return;
      unawaited(action(_rc6RuntimeController));
    }

    void confirmAndRun({
      required String title,
      required String body,
      required Future<void> Function(Rc6RuntimeController rc6) action,
    }) {
      if (_rc6RuntimeController.state.running) return;
      unawaited(() async {
        final confirmed = await _confirmDestructiveAction(
          context,
          title: title,
          body: body,
        );
        if (!confirmed) return;
        await action(_rc6RuntimeController);
      }());
    }

    void runClipboardPathImport() {
      if (_rc6RuntimeController.state.running) return;
      unawaited(() async {
        final text = (await Clipboard.getData('text/plain'))?.text ?? '';
        await _rc6RuntimeController.importLocalPath(text);
      }());
    }

    SingleActivator combo(LogicalKeyboardKey key) =>
        SingleActivator(key, control: true, alt: true);

    final zh = localeCode == 'zh-CN';
    return <ShortcutActivator, VoidCallback>{
      combo(LogicalKeyboardKey.digit1): () => go(0),
      combo(LogicalKeyboardKey.digit2): () => go(1),
      combo(LogicalKeyboardKey.digit3): () => go(2),
      combo(LogicalKeyboardKey.digit4): () => go(3),
      combo(LogicalKeyboardKey.digit5): () => go(5),
      combo(LogicalKeyboardKey.digit6): () => go(6),
      combo(LogicalKeyboardKey.digit7): () => go(7),
      combo(LogicalKeyboardKey.digit8): () => go(10),
      combo(LogicalKeyboardKey.digit9): () => go(8),
      combo(LogicalKeyboardKey.digit0): () => go(9),
      combo(LogicalKeyboardKey.keyS): () => go(10),
      combo(LogicalKeyboardKey.keyI): () => run(
            (rc6) => rc6.importLocalPath(r'D:\HeiTang-Codex-WorkSpace\input'),
          ),
      combo(LogicalKeyboardKey.keyO): () => run(
            (rc6) => rc6.parseAndChunkSources(),
          ),
      combo(LogicalKeyboardKey.keyK): () => run(
            (rc6) => rc6.buildKnowledgeBase(),
          ),
      combo(LogicalKeyboardKey.keyT): () => run(
            (rc6) => rc6.search('赚钱 小生意'),
          ),
      combo(LogicalKeyboardKey.keyM): () => run(
            (rc6) => rc6.generateMarkdown(),
          ),
      combo(LogicalKeyboardKey.keyD): () => run(
            (rc6) => rc6.exportMarkdownDocument(),
          ),
      combo(LogicalKeyboardKey.keyG): () => run(
            (rc6) => rc6.generateSkill(),
          ),
      combo(LogicalKeyboardKey.keyA): () => run(
            (rc6) => rc6.completeAgentProductOperations(),
          ),
      combo(LogicalKeyboardKey.keyR): () => run(
            (rc6) => rc6.runRealInputFolderE2E(
              r'D:\HeiTang-Codex-WorkSpace\input',
            ),
          ),
      combo(LogicalKeyboardKey.keyU): () => run(
            (rc6) => rc6.exportAuditReport(),
          ),
      combo(LogicalKeyboardKey.keyV): () => run(
            (rc6) => rc6.runSettingsExportBasicAcceptance(),
          ),
      combo(LogicalKeyboardKey.keyP): () => run(
            (rc6) => rc6.runStage3ProfilePersistenceSmoke(),
          ),
      combo(LogicalKeyboardKey.keyN): () => run(
            (rc6) => rc6.runParallelTaskCapacityValidation(taskCount: 8),
          ),
      combo(LogicalKeyboardKey.keyB): runClipboardPathImport,
      combo(LogicalKeyboardKey.keyX): () => run((rc6) async {
            final text = (await Clipboard.getData('text/plain'))?.text ?? '';
            await rc6.importExternalSkillPath(text);
          }),
      combo(LogicalKeyboardKey.keyY): () => run(
            (rc6) => rc6.runStorageConnectionAcceptance(),
          ),
      combo(LogicalKeyboardKey.keyQ): () => confirmAndRun(
            title: zh ? '清空对话历史？' : 'Clear dialogue history?',
            body: zh
                ? '这会删除当前助手的对话内容、会话历史和对话导出；助手配置、技能、知识库和工作小组成果不会被删除。'
                : 'This deletes the current assistant dialogue, chat history, and dialogue export; assistant config, Skill, KB, and discussion artifacts are kept.',
            action: (rc6) => rc6.clearAgentDialogueHistory(),
          ),
      combo(LogicalKeyboardKey.keyE): () => confirmAndRun(
            title: zh ? '删除成果记录？' : 'Delete output record?',
            body: zh
                ? '这会删除当前工作区里的文档生成和导出产物；原始输入文件夹不会被删除。'
                : 'This deletes document generation and export artifacts in the current workspace; the original input folder is not touched.',
            action: (rc6) => rc6.clearDocumentArtifacts(),
          ),
      combo(LogicalKeyboardKey.keyL): () => confirmAndRun(
            title: zh ? '删除导入记录？' : 'Delete import records?',
            body: zh
                ? '这会删除当前工作区内的导入清单、解析、知识库、检索和文档导出产物；不会删除原始输入文件夹。'
                : 'This deletes imported manifest, parsing, KB, retrieval, and document export artifacts in this workspace; the original source folder is not touched.',
            action: (rc6) => rc6.clearImportedSources(),
          ),
      const SingleActivator(LogicalKeyboardKey.f9): () => run(
            (rc6) => rc6.runRealInputFolderE2E(
              r'D:\HeiTang-Codex-WorkSpace\input',
            ),
          ),
      const SingleActivator(LogicalKeyboardKey.f5): runClipboardPathImport,
      const SingleActivator(LogicalKeyboardKey.f10): () => run(
            (rc6) => rc6.runStage3ProfilePersistenceSmoke(),
          ),
      const SingleActivator(LogicalKeyboardKey.f11): () => run(
            (rc6) => rc6.exportAuditReport(),
          ),
      const SingleActivator(LogicalKeyboardKey.f12): () => run(
            (rc6) => rc6.runParallelTaskCapacityValidation(taskCount: 8),
          ),
      const SingleActivator(LogicalKeyboardKey.f6): () => confirmAndRun(
            title: zh ? '清空对话历史？' : 'Clear dialogue history?',
            body: zh
                ? '这会删除当前助手的对话内容、会话历史和对话导出；助手配置、技能、知识库和工作小组成果不会被删除。'
                : 'This deletes the current assistant dialogue, chat history, and dialogue export; assistant config, Skill, KB, and discussion artifacts are kept.',
            action: (rc6) => rc6.clearAgentDialogueHistory(),
          ),
      const SingleActivator(LogicalKeyboardKey.f7): () => confirmAndRun(
            title: zh ? '删除成果记录？' : 'Delete output record?',
            body: zh
                ? '这会删除当前工作区里的文档生成和导出产物；原始输入文件夹不会被删除。'
                : 'This deletes document generation and export artifacts in the current workspace; the original input folder is not touched.',
            action: (rc6) => rc6.clearDocumentArtifacts(),
          ),
      const SingleActivator(LogicalKeyboardKey.f8): () => confirmAndRun(
            title: zh ? '删除导入记录？' : 'Delete import records?',
            body: zh
                ? '这会删除当前工作区内的导入清单、解析、知识库、检索和文档导出产物；不会删除原始输入文件夹。'
                : 'This deletes imported manifest, parsing, KB, retrieval, and document export artifacts in this workspace; the original source folder is not touched.',
            action: (rc6) => rc6.clearImportedSources(),
          ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final safeSelectedIndex = selectedIndex.clamp(0, pages.length - 1).toInt();
    final currentPage = pages[safeSelectedIndex];
    final appTitle =
        '${currentPage.title(localeCode, sampleWorkbenchContracts)} - HeiTang Knowledge Workbench';

    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      locale: localeCode == 'zh-CN'
          ? const Locale('zh', 'CN')
          : const Locale('en', 'US'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      themeMode: themeMode,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: Builder(
        builder: (context) => CallbackShortcuts(
          bindings: _automationShortcuts(context),
          child: Focus(
            autofocus: true,
            child: FutureBuilder<WorkbenchContracts>(
              future: _contractsFuture,
              initialData: widget.contracts ?? sampleWorkbenchContracts,
              builder: (context, contractsSnapshot) =>
                  FutureBuilder<P1WorkflowEvidence>(
                future: _workflowEvidenceFuture,
                initialData:
                    widget.workflowEvidence ?? sampleP1WorkflowEvidence,
                builder: (context, evidenceSnapshot) =>
                    FutureBuilder<P1WorkflowEvidence>(
                  future: _workflowV2EvidenceFuture,
                  initialData:
                      widget.workflowV2Evidence ?? sampleP1WorkflowV2Evidence,
                  builder: (context, v2Snapshot) =>
                      FutureBuilder<ExternalCapabilityRegistry>(
                    future: _externalCapabilitiesFuture,
                    initialData: widget.externalCapabilities ??
                        sampleExternalCapabilityRegistry,
                    builder: (context, externalSnapshot) =>
                        FutureBuilder<ProviderCapabilityStatus>(
                      future: _providerCapabilityStatusFuture,
                      initialData: widget.providerCapabilityStatus ??
                          sampleProviderCapabilityStatus,
                      builder: (context, providerStatusSnapshot) =>
                          FutureBuilder<ParserBackendMatrix>(
                        future: _parserBackendsFuture,
                        initialData:
                            widget.parserBackends ?? sampleParserBackendMatrix,
                        builder: (context, parserSnapshot) =>
                            FutureBuilder<Map<String, dynamic>>(
                          future: _campaign6AgentRuntimeStatusFuture,
                          initialData: widget.campaign6AgentRuntimeStatus ??
                              sampleCampaign6AgentRuntimeStatus,
                          builder: (context, campaign6Snapshot) =>
                              FutureBuilder<Map<String, dynamic>>(
                            future: _campaign7ConfigurationStatusFuture,
                            initialData: widget.campaign7ConfigurationStatus ??
                                sampleCampaign7ConfigurationStatus,
                            builder: (context, campaign7Snapshot) =>
                                FutureBuilder<Map<String, dynamic>>(
                              future: _campaign9DesktopDeliveryStatusFuture,
                              initialData:
                                  widget.campaign9DesktopDeliveryStatus ??
                                      sampleCampaign9DesktopDeliveryStatus,
                              builder: (context, campaign9Snapshot) =>
                                  FutureBuilder<Map<String, dynamic>>(
                                future: _skillGovernanceReportFuture,
                                initialData: widget.skillGovernanceReport ??
                                    sampleSkillGovernanceReport,
                                builder: (context, skillGovernanceSnapshot) =>
                                    _Rc6RuntimeScope(
                                  controller: _rc6RuntimeController,
                                  child: _WorkbenchScaffold(
                                    contracts: contractsSnapshot.data ??
                                        sampleWorkbenchContracts,
                                    workflowEvidence: evidenceSnapshot.data ??
                                        sampleP1WorkflowEvidence,
                                    workflowV2Evidence: v2Snapshot.data ??
                                        sampleP1WorkflowV2Evidence,
                                    externalCapabilities:
                                        externalSnapshot.data ??
                                            sampleExternalCapabilityRegistry,
                                    providerCapabilityStatus:
                                        providerStatusSnapshot.data ??
                                            sampleProviderCapabilityStatus,
                                    parserBackends: parserSnapshot.data ??
                                        sampleParserBackendMatrix,
                                    campaign6AgentRuntimeStatus:
                                        campaign6Snapshot.data ??
                                            sampleCampaign6AgentRuntimeStatus,
                                    campaign7ConfigurationStatus:
                                        campaign7Snapshot.data ??
                                            sampleCampaign7ConfigurationStatus,
                                    campaign9DesktopDeliveryStatus:
                                        campaign9Snapshot.data ??
                                            sampleCampaign9DesktopDeliveryStatus,
                                    skillGovernanceReport:
                                        skillGovernanceSnapshot.data ??
                                            sampleSkillGovernanceReport,
                                    methodologyMap: widget.methodologyMap ??
                                        sampleMethodologyMap,
                                    skillSuiteWorkflow:
                                        widget.skillSuiteWorkflow,
                                    localeCode: localeCode,
                                    themeMode: themeMode,
                                    selectedIndex: safeSelectedIndex,
                                    isDark: isDark,
                                    coreBridge: widget.coreBridge,
                                    coreCli: widget.coreCli,
                                    coreWorkingDirectory:
                                        widget.coreWorkingDirectory,
                                    coreWorkspace: widget.coreWorkspace,
                                    enableLocalCoreActions:
                                        widget.enableLocalCoreActions,
                                    isWebRuntime: widget.isWebRuntime,
                                    onThemeChanged: (value) =>
                                        setState(() => themeMode = value),
                                    onLocaleChanged: (value) =>
                                        setState(() => localeCode = value),
                                    onPageChanged: (index) => setState(() =>
                                        selectedIndex = index
                                            .clamp(0, pages.length - 1)
                                            .toInt()),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final isDarkTheme = brightness == Brightness.dark;
    final visual = _HTKWTokens.visualTokens(brightness);
    final colors = ColorScheme.fromSeed(
      seedColor: visual.accent,
      brightness: brightness,
    );
    final lightScheme = colors.copyWith(
      primary: visual.accent,
      onPrimary: _HTKWTokens.surface,
      primaryContainer: _HTKWTokens.accentSoft,
      onPrimaryContainer: visual.textPrimary,
      secondary: visual.success,
      onSecondary: visual.textPrimary,
      surface: visual.surfaceBase,
      surfaceContainerLowest: visual.surfaceBase,
      surfaceContainerLow: visual.surfaceSubtle,
      surfaceContainer: visual.surfaceMuted,
      surfaceContainerHigh: visual.surfaceSubtle,
      surfaceContainerHighest: visual.appBackground,
      onSurface: visual.textPrimary,
      onSurfaceVariant: visual.textSecondary,
      outline: visual.borderNormal,
      outlineVariant: visual.borderSubtle,
      error: visual.danger,
    );
    final darkScheme = colors.copyWith(
      primary: visual.accent,
      onPrimary: const Color(0xffffffff),
      primaryContainer: visual.accent.withValues(alpha: 0.16),
      onPrimaryContainer: visual.textPrimary,
      secondary: visual.success,
      onSecondary: const Color(0xff07150e),
      surface: visual.surfaceBase,
      surfaceContainerLowest: visual.appBackground,
      surfaceContainerLow: visual.surfaceBase,
      surfaceContainer: visual.surfaceRaised,
      surfaceContainerHigh: visual.surfaceHighlight,
      surfaceContainerHighest: visual.appBackground,
      onSurface: visual.textPrimary,
      onSurfaceVariant: visual.textSecondary,
      outline: visual.borderNormal,
      outlineVariant: visual.borderSubtle,
      error: visual.danger,
    );
    final scheme = isDarkTheme ? darkScheme : lightScheme;
    TextStyle? shrinkText(TextStyle? style) {
      final fontSize = style?.fontSize;
      if (style == null || fontSize == null) return style;
      return style.copyWith(fontSize: (fontSize - 1).clamp(10.0, 80.0));
    }

    TextTheme compactTextTheme(TextTheme theme) => theme.copyWith(
          displayLarge: shrinkText(theme.displayLarge),
          displayMedium: shrinkText(theme.displayMedium),
          displaySmall: shrinkText(theme.displaySmall),
          headlineLarge: shrinkText(theme.headlineLarge),
          headlineMedium: shrinkText(theme.headlineMedium),
          headlineSmall: shrinkText(theme.headlineSmall),
          titleLarge: shrinkText(theme.titleLarge),
          titleMedium: shrinkText(theme.titleMedium),
          titleSmall: shrinkText(theme.titleSmall),
          bodyLarge: shrinkText(theme.bodyLarge),
          bodyMedium: shrinkText(theme.bodyMedium),
          bodySmall: shrinkText(theme.bodySmall),
          labelLarge: shrinkText(theme.labelLarge),
          labelMedium: shrinkText(theme.labelMedium),
          labelSmall: shrinkText(theme.labelSmall),
        );
    final baseTypography = Typography.material2021();
    final textTheme = compactTextTheme(
      isDarkTheme ? baseTypography.white : baseTypography.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: visual.appBackground,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(_DesktopGrid.panelRadius),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle:
              const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          elevation: 0,
          disabledBackgroundColor:
              scheme.surfaceContainerHigh.withValues(alpha: 0.72),
          disabledForegroundColor:
              scheme.onSurfaceVariant.withValues(alpha: 0.52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_DesktopGrid.buttonRadius)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
          textStyle:
              const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_DesktopGrid.buttonRadius)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle:
              const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_DesktopGrid.buttonRadius)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: isDarkTheme
            ? visual.accent.withValues(alpha: 0.16)
            : _HTKWTokens.accentSoft,
        disabledColor: scheme.surfaceContainerLow.withValues(alpha: 0.62),
        labelStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_DesktopGrid.chipRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDarkTheme
            ? scheme.surfaceContainer.withValues(alpha: 0.72)
            : scheme.surfaceContainerLow,
        labelStyle: const TextStyle(fontSize: 12),
        helperStyle: const TextStyle(fontSize: 11),
        hintStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DesktopGrid.buttonRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DesktopGrid.buttonRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DesktopGrid.buttonRadius),
          borderSide: BorderSide(color: scheme.primary, width: 1),
        ),
      ),
    );
  }
}

class _DesktopWorkbench extends StatelessWidget {
  const _DesktopWorkbench({
    required this.localeCode,
    required this.contracts,
    required this.workflowEvidence,
    required this.workflowV2Evidence,
    required this.externalCapabilities,
    required this.providerCapabilityStatus,
    required this.parserBackends,
    required this.campaign6AgentRuntimeStatus,
    required this.campaign7ConfigurationStatus,
    required this.campaign9DesktopDeliveryStatus,
    required this.skillGovernanceReport,
    required this.methodologyMap,
    required this.skillSuiteWorkflow,
    required this.selectedIndex,
    required this.coreBridge,
    required this.coreCli,
    required this.coreWorkingDirectory,
    required this.coreWorkspace,
    required this.enableLocalCoreActions,
    required this.isWebRuntime,
    required this.isDark,
    required this.windowState,
    required this.onWindowStateChanged,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.onPageChanged,
  });

  final String localeCode;
  final WorkbenchContracts contracts;
  final P1WorkflowEvidence workflowEvidence;
  final P1WorkflowEvidence workflowV2Evidence;
  final ExternalCapabilityRegistry externalCapabilities;
  final ProviderCapabilityStatus providerCapabilityStatus;
  final ParserBackendMatrix parserBackends;
  final Map<String, dynamic> campaign6AgentRuntimeStatus;
  final Map<String, dynamic> campaign7ConfigurationStatus;
  final Map<String, dynamic> campaign9DesktopDeliveryStatus;
  final Map<String, dynamic> skillGovernanceReport;
  final Map<String, dynamic> methodologyMap;
  final Map<String, dynamic>? skillSuiteWorkflow;
  final int selectedIndex;
  final LocalCoreBridge coreBridge;
  final String coreCli;
  final String coreWorkingDirectory;
  final String coreWorkspace;
  final bool enableLocalCoreActions;
  final bool isWebRuntime;
  final bool isDark;
  final _DesktopWindowPreviewState windowState;
  final ValueChanged<_DesktopWindowPreviewState> onWindowStateChanged;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<String> onLocaleChanged;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final sidebarWidth = constraints.maxWidth >= 1400
          ? 248.0
          : constraints.maxWidth < 600
              ? 72.0
              : 184.0;
      const compactTopBar = false;
      const topBarHeight = 72.0;
      const contentTop = topBarHeight + 8.0;
      const statusBarSafeBottom = 30.0;

      return Row(
        children: [
          SizedBox(
            width: sidebarWidth,
            child: _WorkbenchSidebar(
              localeCode: localeCode,
              contracts: contracts,
              selectedIndex: selectedIndex,
              onPageChanged: onPageChanged,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                if (topBarHeight > 0)
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    height: topBarHeight,
                    child: _ProductTopBar(
                      localeCode: localeCode,
                      page: pages[selectedIndex],
                      contracts: contracts,
                      compactForPage: compactTopBar,
                      isDark: isDark,
                      windowState: windowState,
                      onWindowStateChanged: onWindowStateChanged,
                      onThemeChanged: onThemeChanged,
                      onLocaleChanged: onLocaleChanged,
                      onPageChanged: onPageChanged,
                    ),
                  ),
                Positioned(
                  left: 10,
                  top: contentTop,
                  right: 10,
                  bottom: statusBarSafeBottom,
                  child: _PageSurface(
                    key: ValueKey('page-surface-$selectedIndex'),
                    page: pages[selectedIndex],
                    localeCode: localeCode,
                    contracts: contracts,
                    workflowEvidence: workflowEvidence,
                    workflowV2Evidence: workflowV2Evidence,
                    externalCapabilities: externalCapabilities,
                    providerCapabilityStatus: providerCapabilityStatus,
                    parserBackends: parserBackends,
                    campaign6AgentRuntimeStatus: campaign6AgentRuntimeStatus,
                    campaign7ConfigurationStatus: campaign7ConfigurationStatus,
                    campaign9DesktopDeliveryStatus:
                        campaign9DesktopDeliveryStatus,
                    skillGovernanceReport: skillGovernanceReport,
                    methodologyMap: methodologyMap,
                    skillSuiteWorkflow: skillSuiteWorkflow,
                    columns: 3,
                    coreBridge: coreBridge,
                    coreCli: coreCli,
                    coreWorkingDirectory: coreWorkingDirectory,
                    coreWorkspace: coreWorkspace,
                    enableLocalCoreActions: enableLocalCoreActions,
                    isWebRuntime: isWebRuntime,
                    isDark: isDark,
                    windowState: windowState,
                    onWindowStateChanged: onWindowStateChanged,
                    onThemeChanged: onThemeChanged,
                    onLocaleChanged: onLocaleChanged,
                    onPageChanged: onPageChanged,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 28,
                  child: _DesktopStatusBar(
                    localeCode: localeCode,
                    workspace: coreWorkspace,
                    isWebRuntime: isWebRuntime,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

int _pageIndexById(String pageId) {
  final normalizedPageId = switch (pageId) {
    'import-parsing' => 'document-library',
    _ => pageId,
  };
  final exactIndex = pages.indexWhere((page) => page.id == normalizedPageId);
  if (exactIndex >= 0) return exactIndex;
  final memberIndex =
      pages.indexWhere((page) => page.pageIds.contains(normalizedPageId));
  return memberIndex < 0 ? 0 : memberIndex;
}

class _PageSurface extends StatefulWidget {
  const _PageSurface({
    super.key,
    required this.page,
    required this.localeCode,
    required this.contracts,
    required this.workflowEvidence,
    required this.workflowV2Evidence,
    required this.externalCapabilities,
    required this.providerCapabilityStatus,
    required this.parserBackends,
    required this.campaign6AgentRuntimeStatus,
    required this.campaign7ConfigurationStatus,
    required this.campaign9DesktopDeliveryStatus,
    required this.skillGovernanceReport,
    required this.methodologyMap,
    required this.skillSuiteWorkflow,
    required this.columns,
    required this.coreBridge,
    required this.coreCli,
    required this.coreWorkingDirectory,
    required this.coreWorkspace,
    required this.enableLocalCoreActions,
    required this.isWebRuntime,
    required this.isDark,
    required this.windowState,
    required this.onWindowStateChanged,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.onPageChanged,
  });

  final WorkbenchPage page;
  final String localeCode;
  final WorkbenchContracts contracts;
  final P1WorkflowEvidence workflowEvidence;
  final P1WorkflowEvidence workflowV2Evidence;
  final ExternalCapabilityRegistry externalCapabilities;
  final ProviderCapabilityStatus providerCapabilityStatus;
  final ParserBackendMatrix parserBackends;
  final Map<String, dynamic> campaign6AgentRuntimeStatus;
  final Map<String, dynamic> campaign7ConfigurationStatus;
  final Map<String, dynamic> campaign9DesktopDeliveryStatus;
  final Map<String, dynamic> skillGovernanceReport;
  final Map<String, dynamic> methodologyMap;
  final Map<String, dynamic>? skillSuiteWorkflow;
  final int columns;
  final LocalCoreBridge coreBridge;
  final String coreCli;
  final String coreWorkingDirectory;
  final String coreWorkspace;
  final bool enableLocalCoreActions;
  final bool isWebRuntime;
  final bool? isDark;
  final _DesktopWindowPreviewState windowState;
  final ValueChanged<_DesktopWindowPreviewState> onWindowStateChanged;
  final ValueChanged<ThemeMode>? onThemeChanged;
  final ValueChanged<String>? onLocaleChanged;
  final ValueChanged<int> onPageChanged;

  @override
  State<_PageSurface> createState() => _PageSurfaceState();
}

class _PageSurfaceState extends State<_PageSurface> {
  final ScrollController _scrollController =
      ScrollController(keepScrollOffset: false);

  @override
  void didUpdateWidget(covariant _PageSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.id != widget.page.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final localeCode = widget.localeCode;
    final contracts = widget.contracts;
    final workflowV2Evidence = widget.workflowV2Evidence;
    final externalCapabilities = widget.externalCapabilities;
    final providerCapabilityStatus = widget.providerCapabilityStatus;
    final parserBackends = widget.parserBackends;
    final campaign6AgentRuntimeStatus = widget.campaign6AgentRuntimeStatus;
    final coreWorkspace = widget.coreWorkspace;
    final isWebRuntime = widget.isWebRuntime;
    final onPageChanged = widget.onPageChanged;
    final isDashboard = page.id == 'dashboard';
    final isAgentConsole = page.id == 'agent-factory-runtime';
    return LayoutBuilder(builder: (context, constraints) {
      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDashboard) ...[
            _DesktopDashboardSurface(
              localeCode: localeCode,
              contracts: contracts,
              workflowV2Evidence: workflowV2Evidence,
              parserBackends: parserBackends,
              externalCapabilities: externalCapabilities,
              workspace: coreWorkspace,
              isWebRuntime: isWebRuntime,
              onPageChanged: onPageChanged,
            ),
          ],
          if (!isDashboard) ...[
            _ProductPageOverview(
              localeCode: localeCode,
              page: page,
              workspace: coreWorkspace,
              providerCapabilityStatus: providerCapabilityStatus,
              campaign6AgentRuntimeStatus: campaign6AgentRuntimeStatus,
              isWebRuntime: isWebRuntime,
              onPageChanged: onPageChanged,
            ),
          ],
        ],
      );
      if (isAgentConsole) {
        return SizedBox.expand(
          child: _ProductWorkspaceFrame(
            key: ValueKey('page-scroll-${page.id}'),
            compact: true,
            child: _ProductPageOverview(
              localeCode: localeCode,
              page: page,
              workspace: coreWorkspace,
              providerCapabilityStatus: providerCapabilityStatus,
              campaign6AgentRuntimeStatus: campaign6AgentRuntimeStatus,
              isWebRuntime: isWebRuntime,
              onPageChanged: onPageChanged,
            ),
          ),
        );
      }
      return SizedBox.expand(
        child: _ProductWorkspaceFrame(
          key: ValueKey('page-scroll-${page.id}'),
          child: Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              primary: false,
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 44),
                child: content,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _ProductPageOverview extends StatefulWidget {
  const _ProductPageOverview({
    required this.localeCode,
    required this.page,
    required this.workspace,
    required this.providerCapabilityStatus,
    required this.campaign6AgentRuntimeStatus,
    required this.isWebRuntime,
    required this.onPageChanged,
  });

  final String localeCode;
  final WorkbenchPage page;
  final String workspace;
  final ProviderCapabilityStatus providerCapabilityStatus;
  final Map<String, dynamic> campaign6AgentRuntimeStatus;
  final bool isWebRuntime;
  final ValueChanged<int> onPageChanged;

  @override
  State<_ProductPageOverview> createState() => _ProductPageOverviewState();
}

class _ProductPageOverviewState extends State<_ProductPageOverview> {
  late int selectedTab = _defaultTabFor(widget.page.id);

  static int _defaultTabFor(String pageId) =>
      pageId == 'agent-factory-runtime' ? 1 : 0;

  @override
  void didUpdateWidget(covariant _ProductPageOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.id != widget.page.id) {
      selectedTab = _defaultTabFor(widget.page.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.page.id;
    final tabCounts = <String, int>{
      'knowledge-package-management': 5,
      'document-generation': 3,
      'agent-factory-runtime': 4,
      'reports-audit': 3,
      'workspace': 5,
    };
    final maxTab = (tabCounts[page] ?? 1) - 1;
    if (selectedTab > maxTab) selectedTab = 0;
    final rc6 = _Rc6RuntimeScope.of(context);
    final body = switch (page) {
      'import-parsing' => _ImportProductWorkflow(
          localeCode: widget.localeCode,
          workspace: widget.workspace,
          isWebRuntime: widget.isWebRuntime,
        ),
      'document-library' => _DocumentLibraryProductWorkflow(
          localeCode: widget.localeCode,
          workspace: widget.workspace,
          isWebRuntime: widget.isWebRuntime,
          onPageChanged: widget.onPageChanged,
        ),
      'knowledge-package-management' => _KnowledgeProductWorkflow(
          localeCode: widget.localeCode,
          workspace: widget.workspace,
          selectedTab: selectedTab,
          onPageChanged: widget.onPageChanged,
          onTabSelected: (index) => setState(() => selectedTab = index),
        ),
      'retrieval-verification' => _RetrievalVerificationProductWorkflow(
          localeCode: widget.localeCode,
        ),
      'document-generation' => _DocumentProductWorkflow(
          localeCode: widget.localeCode,
          workspace: widget.workspace,
          selectedTab: selectedTab,
          onTabSelected: (index) => setState(() => selectedTab = index),
        ),
      'skill-factory' => _SkillBuilderProductWorkflow(
          localeCode: widget.localeCode,
          workspace: widget.workspace,
        ),
      'agent-factory-runtime' => _AgentProductWorkflow(
          localeCode: widget.localeCode,
          workspace: widget.workspace,
          campaign6AgentRuntimeStatus: widget.campaign6AgentRuntimeStatus,
          selectedTab: selectedTab,
          onTabSelected: (index) => setState(() => selectedTab = index),
        ),
      'workbook' => _WorkbookProductWorkflow(
          localeCode: widget.localeCode,
          workspace: widget.workspace,
          onPageChanged: widget.onPageChanged,
        ),
      'reports-audit' => _ValidateExportProductWorkflow(
          localeCode: widget.localeCode,
          workspace: widget.workspace,
          selectedTab: selectedTab,
          onTabSelected: (index) => setState(() => selectedTab = index),
        ),
      'artifact-center' => _ArtifactCenterProductWorkflow(
          localeCode: widget.localeCode,
        ),
      _ => _SettingsProductWorkflow(
          localeCode: widget.localeCode,
          workspace: widget.workspace,
          runtimeController: rc6,
          providerCapabilityStatus: widget.providerCapabilityStatus,
          selectedTab: selectedTab,
          onTabSelected: (index) => setState(() => selectedTab = index),
          isWebRuntime: widget.isWebRuntime,
        ),
    };
    if (page == 'agent-factory-runtime') {
      return KeyedSubtree(
        key: Key('dense-page-workbench-${widget.page.id}'),
        child: SizedBox.expand(child: body),
      );
    }
    return KeyedSubtree(
      key: Key('dense-page-workbench-${widget.page.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [body],
      ),
    );
  }
}

class _ProductWorkspaceFrame extends StatelessWidget {
  const _ProductWorkspaceFrame({
    super.key,
    required this.child,
    this.compact = false,
  });

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: compact
          ? const EdgeInsets.fromLTRB(12, 10, 12, 10)
          : const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(_DesktopGrid.pageRadius),
      ),
      child: child,
    );
  }
}

Future<void> _showWorkspaceArtifactPreview(
  BuildContext context, {
  required Rc6RuntimeController? rc6,
  required String title,
  required String path,
  required String unavailableMessage,
  required String closeLabel,
}) async {
  if (rc6 == null || path.trim().isEmpty) return;
  final content = await rc6.readWorkspaceTextArtifact(path);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: SelectableText(
            content.trim().isEmpty ? unavailableMessage : content,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(closeLabel),
        ),
      ],
    ),
  );
}

class _MetricDatum {
  const _MetricDatum({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.items});

  final List<_MetricDatum> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 720
          ? items.length
          : items.length >= 3 && constraints.maxWidth >= 520
              ? 3
              : constraints.maxWidth >= 300
                  ? 2
                  : 1;
      final columnCount = columns > items.length ? items.length : columns;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnCount,
          crossAxisSpacing: _DesktopGrid.gutter,
          mainAxisSpacing: _DesktopGrid.gutter,
          mainAxisExtent: _DesktopGrid.metricHeight,
        ),
        itemBuilder: (context, index) => _MiniMetricCard(item: items[index]),
      );
    });
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.items,
    this.columns = 2,
  });

  final List<_MetricDatum> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: _DesktopGrid.gutter,
        mainAxisSpacing: _DesktopGrid.gutter,
        mainAxisExtent:
            columns == 2 && items.length == 4 ? 132 : _DesktopGrid.metricHeight,
      ),
      itemBuilder: (context, index) => _MiniMetricCard(item: items[index]),
    );
  }
}

class _CenteredOutputFormatGrid extends StatelessWidget {
  const _CenteredOutputFormatGrid({required this.items});

  final List<_MetricDatum> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1180
          ? items.length
          : constraints.maxWidth >= 720
              ? 3
              : constraints.maxWidth >= 420
                  ? 2
                  : 1;
      final rowCount = (items.length / columns).ceil();
      final cardHeight = columns == items.length ? 168.0 : 160.0;
      final gridHeight =
          rowCount * cardHeight + (rowCount - 1) * _DesktopGrid.gutter;
      return Center(
        child: SizedBox(
          height: gridHeight,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: _DesktopGrid.gutter,
              mainAxisSpacing: _DesktopGrid.gutter,
              mainAxisExtent: cardHeight,
            ),
            itemBuilder: (context, index) =>
                _OutputFormatCard(item: items[index]),
          ),
        ),
      );
    });
  }
}

class _OutputFormatCard extends StatelessWidget {
  const _OutputFormatCard({required this.item});

  final _MetricDatum item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_DesktopGrid.panelRadius),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _HTKWTokens.plumSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item.icon, size: 24, color: _HTKWTokens.plum),
                  ),
                  const SizedBox(height: 10),
                  Text(item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            height: 1.16,
                          )),
                  const SizedBox(height: 4),
                  Text(item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1.08,
                              )),
                  const SizedBox(height: 3),
                  Text(item.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontSize: 12.5,
                            color: _HTKWTokens.textTertiary,
                            fontWeight: FontWeight.w700,
                            height: 1.14,
                          )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuntimeFeedbackBanner extends StatelessWidget {
  const _RuntimeFeedbackBanner({
    required this.title,
    required this.detail,
    this.tone = _StatusTone.neutral,
    this.icon = Icons.info_outline,
  });

  final String title;
  final String detail;
  final _StatusTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = _HTKWTokens.toneColor(tone);
    final background = _HTKWTokens.toneSurface(tone);
    return Container(
      key: const Key('runtime-feedback-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        )),
                const SizedBox(height: 2),
                Text(detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          height: 1.18,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({required this.item});

  final _MetricDatum item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_DesktopGrid.panelRadius),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.028),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _HTKWTokens.blueSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, size: 21, color: _HTKWTokens.blue),
          ),
          const SizedBox(width: _DesktopGrid.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          height: 1.16,
                        )),
                const SizedBox(height: 2),
                Text(item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                        )),
                const SizedBox(height: 1),
                Text(item.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontSize: 12.5,
                          color: _HTKWTokens.textTertiary,
                          fontWeight: FontWeight.w700,
                          height: 1.14,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    this.tone = _StatusTone.neutral,
    this.icon,
  });

  final String label;
  final _StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = _HTKWTokens.toneColor(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _HTKWTokens.toneSurface(tone),
        borderRadius: BorderRadius.circular(_DesktopGrid.chipRadius),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  )),
        ],
      ),
    );
  }
}

enum _StatusTone { neutral, success, warning, danger }

Future<bool> _confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(false),
        const SingleActivator(LogicalKeyboardKey.enter): () =>
            Navigator.of(context).pop(true),
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () =>
            Navigator.of(context).pop(true),
      },
      child: Focus(
        autofocus: true,
        child: AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.delete_outline),
              label:
                  Text(MaterialLocalizations.of(context).deleteButtonTooltip),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

class _PagePreviewDatum {
  const _PagePreviewDatum({
    required this.title,
    required this.status,
    required this.tone,
  });

  final String title;
  final String status;
  final _StatusTone tone;
}

class _PagePreviewStrip extends StatefulWidget {
  const _PagePreviewStrip({required this.zh});

  final bool zh;

  @override
  State<_PagePreviewStrip> createState() => _PagePreviewStripState();
}

class _PagePreviewStripState extends State<_PagePreviewStrip> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zh = widget.zh;
    final pages = zh
        ? const [
            _PagePreviewDatum(
                title: '第 1 页：封面', status: '已生成', tone: _StatusTone.success),
            _PagePreviewDatum(
                title: '第 2 页：摘要', status: '已生成', tone: _StatusTone.success),
            _PagePreviewDatum(
                title: '第 3 页：证据', status: '已生成', tone: _StatusTone.success),
            _PagePreviewDatum(
                title: '第 4 页：风险', status: '待校验', tone: _StatusTone.warning),
            _PagePreviewDatum(
                title: '第 5 页：导出', status: '待生成', tone: _StatusTone.warning),
            _PagePreviewDatum(
                title: '第 6 页：附录', status: '待生成', tone: _StatusTone.warning),
          ]
        : const [
            _PagePreviewDatum(
                title: 'Page 1: Cover',
                status: 'Generated',
                tone: _StatusTone.success),
            _PagePreviewDatum(
                title: 'Page 2: Summary',
                status: 'Generated',
                tone: _StatusTone.success),
            _PagePreviewDatum(
                title: 'Page 3: Evidence',
                status: 'Generated',
                tone: _StatusTone.success),
            _PagePreviewDatum(
                title: 'Page 4: Risks',
                status: 'Pending check',
                tone: _StatusTone.warning),
            _PagePreviewDatum(
                title: 'Page 5: Export',
                status: 'Pending',
                tone: _StatusTone.warning),
            _PagePreviewDatum(
                title: 'Page 6: Appendix',
                status: 'Pending',
                tone: _StatusTone.warning),
          ];
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(zh ? '页面预览' : 'Page Preview',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                )),
        const SizedBox(height: 8),
        Stack(
          children: [
            Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      for (var index = 0; index < pages.length; index++) ...[
                        Container(
                          width: 112,
                          height: 76,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: index == 0
                                ? colors.primary.withValues(alpha: 0.07)
                                : colors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: index == 0
                                  ? colors.primary.withValues(alpha: 0.28)
                                  : colors.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(pages[index].title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        height: 1.12,
                                      )),
                              _StatusBadge(
                                label: pages[index].status,
                                tone: pages[index].tone,
                              ),
                            ],
                          ),
                        ),
                        if (index < pages.length - 1) const SizedBox(width: 8),
                      ],
                      const SizedBox(width: 18),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              bottom: 10,
              child: IgnorePointer(
                child: Container(
                  width: 26,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.surface.withValues(alpha: 0),
                        colors.surface,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SourceDocumentPreviewPanel extends StatelessWidget {
  const _SourceDocumentPreviewPanel({
    required this.zh,
    required this.ready,
    required this.sourceName,
  });

  final bool zh;
  final bool ready;
  final String sourceName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lines = zh
        ? [
            '标题：知识库验证报告草稿',
            '文件：${sourceName.isEmpty ? '等待选择' : sourceName}',
            '摘要：预览跟随上方筛选和当前选中文档变化。',
            '正文：文档库只展示来源文档、解析状态和下游产物入口。',
          ]
        : [
            'Title: Knowledge Base validation draft',
            'File: ${sourceName.isEmpty ? 'Waiting selection' : sourceName}',
            'Summary: preview follows the filter and selected document.',
            'Body: Library shows source docs, parse status, and downstream artifact entry points.',
          ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ready
                      ? (zh ? '来源文档预览正文' : 'Source Document Preview')
                      : (zh ? '等待来源文档' : 'Waiting for source document'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                ),
              ),
              const _StatusBadge(
                label: '只读预览',
                tone: _StatusTone.neutral,
                icon: Icons.visibility_outlined,
              ),
            ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          for (final line in lines) ...[
            Text(
              line,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.18,
                  ),
            ),
            if (line != lines.last) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

class _DocumentSelectionList extends StatelessWidget {
  const _DocumentSelectionList({
    required this.zh,
    required this.sources,
    required this.selectedIndex,
    required this.selectedDocuments,
    required this.onSelected,
    required this.onSelectionChanged,
  });

  final bool zh;
  final List<Rc6SourceRecord> sources;
  final int selectedIndex;
  final Set<String> selectedDocuments;
  final ValueChanged<int> onSelected;
  final void Function(String name, bool selected) onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            zh ? '当前筛选下没有文档。' : 'No documents match the current filter.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            zh
                ? '导入文档后可在这里多选、预览和批量删除。'
                : 'Imported documents can be multi-selected, previewed, and batch deleted here.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCaption(zh ? '文档预览切换' : 'Preview document switcher'),
        const SizedBox(height: 8),
        for (var index = 0; index < sources.length; index++) ...[
          Builder(builder: (context) {
            final source = sources[index];
            final key = _documentKey(source);
            return ListTile(
              dense: true,
              selected: selectedIndex == index,
              leading: Checkbox(
                value: selectedDocuments.contains(key),
                onChanged: (selected) =>
                    onSelectionChanged(key, selected ?? false),
              ),
              title: Text(source.sourceName,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: source.documentId.isEmpty
                  ? null
                  : Text(source.documentId,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Icon(
                selectedIndex == index
                    ? Icons.visibility_outlined
                    : Icons.chevron_right_outlined,
              ),
              onTap: () => onSelected(index),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _FileTreePreview extends StatelessWidget {
  const _FileTreePreview({required this.zh, required this.rows});

  final bool zh;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final row in rows) ...[
          Row(
            children: [
              Icon(
                  row.first.endsWith('/')
                      ? Icons.folder_outlined
                      : Icons.description_outlined,
                  size: 17,
                  color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(row.first,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
              ),
              const SizedBox(width: 8),
              Text(row.last,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      )),
            ],
          ),
          if (row != rows.last) const Divider(height: 16),
        ],
      ],
    );
  }
}

String _displayNameForPath(String path) {
  final normalized = path.replaceAll('\\', '/').trim();
  if (normalized.isEmpty) {
    return '-';
  }
  final parts = normalized.split('/').where((part) => part.isNotEmpty);
  return parts.isEmpty ? normalized : parts.last;
}

String _documentTypeForName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.url.md')) return 'web';
  if (lower.endsWith('.pdf')) return 'pdf';
  if (lower.endsWith('.docx')) return 'docx';
  if (lower.endsWith('.md') || lower.endsWith('.markdown')) return 'md';
  if (lower.endsWith('.txt')) return 'txt';
  if (lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp')) {
    return 'image';
  }
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return 'web';
  }
  return 'other';
}

String _documentKey(Rc6SourceRecord source) {
  if (source.documentId.isNotEmpty) return source.documentId;
  if (source.relativePath.isNotEmpty) return source.relativePath;
  return source.sourceName;
}

String _documentTypeForSource(Rc6SourceRecord source) {
  if (source.sourceType == 'web_link') return 'web';
  if (source.extension.isNotEmpty) {
    final extension = source.extension.toLowerCase();
    if (extension == '.pdf') return 'pdf';
    if (extension == '.docx') return 'docx';
    if (extension == '.md' || extension == '.markdown') return 'md';
    if (extension == '.txt') return 'txt';
    if (extension == '.png' ||
        extension == '.jpg' ||
        extension == '.jpeg' ||
        extension == '.webp') {
      return 'image';
    }
  }
  return _documentTypeForName(
      source.relativePath.isNotEmpty ? source.relativePath : source.sourceName);
}

String _documentTypeLabel(String type, bool zh) {
  return switch (type) {
    'all' => zh ? '全部' : 'All',
    'pdf' => 'PDF',
    'docx' => 'DOCX',
    'md' => 'MD',
    'txt' => 'TXT',
    'image' => zh ? '图片' : 'Image',
    'web' => zh ? '网页链接' : 'Web link',
    _ => zh ? '其他' : 'Other',
  };
}

String _structureStatusLabel(String status, bool zh) {
  return switch (status) {
    'local_text_scan' => zh ? '文本已扫描' : 'Text scanned',
    'requires_parser' => zh ? '需要处理' : 'Needs action',
    'not_scanned' => zh ? '待扫描' : 'Not scanned',
    _ => status.isEmpty ? (zh ? '待扫描' : 'Not scanned') : status,
  };
}

void _sortDocumentSources(List<Rc6SourceRecord> sources, String sortMode) {
  switch (sortMode) {
    case 'name_desc':
      sources.sort((a, b) =>
          b.sourceName.toLowerCase().compareTo(a.sourceName.toLowerCase()));
      return;
    case 'type':
      sources.sort((a, b) {
        final typeCompare =
            _documentTypeForSource(a).compareTo(_documentTypeForSource(b));
        return typeCompare == 0
            ? a.sourceName.toLowerCase().compareTo(b.sourceName.toLowerCase())
            : typeCompare;
      });
      return;
    default:
      sources.sort((a, b) =>
          a.sourceName.toLowerCase().compareTo(b.sourceName.toLowerCase()));
  }
}

const sampleCampaign6AgentRuntimeStatus = <String, dynamic>{
  'schema_id': 'campaign6_agent_runtime_status',
  'schema_version': '2026-06-17',
  'overall_status':
      'campaign6a_6b_tool_adapter_production_grade_accepted_ui_bound',
  'phase_status': <Map<String, dynamic>>[
    {
      'phase_id': 'campaign6a_single_agent_runtime',
      'ui_state': 'enabled_real',
      'runtime_status': 'pass',
      'evidence_path': 'campaign6a_acceptance_report.json',
    },
    {
      'phase_id': 'campaign6b_advanced_agent_runtime',
      'ui_state': 'enabled_real',
      'runtime_status': 'pass',
      'evidence_path': 'campaign6b_acceptance_report.json',
    },
    {
      'phase_id': 'campaign6_tool_adapter_configuration_gate',
      'ui_state': 'enabled_real',
      'runtime_status': 'pass',
      'evidence_path': 'campaign6_tool_adapter_configuration_report.json',
    },
    {
      'phase_id': 'computer_use_boundary',
      'ui_state': 'disabled_boundary',
      'runtime_status': 'disabled_boundary',
      'evidence_path': 'computer_use_boundary_threat_model.json',
    },
  ],
  'agent_types_6a': <Map<String, dynamic>>[
    {
      'agent_type': 'knowledge_qa_agent',
      'display_name': 'Knowledge QA Agent',
      'ui_state': 'enabled_real',
      'runtime_status': 'succeeded',
      'degraded_modes': <String>['no_evidence', 'provider_unavailable'],
      'rollback_strategy': 'no_mutation_read_only',
    },
    {
      'agent_type': 'document_processing_agent',
      'display_name': 'Document Processing Agent',
      'ui_state': 'enabled_real',
      'runtime_status': 'partial_success',
      'degraded_modes': <String>['unsupported_file', 'ocr_unavailable'],
      'rollback_strategy': 'artifact_manifest_revert_where_supported',
    },
    {
      'agent_type': 'skill_builder_agent',
      'display_name': 'Skill Builder Agent',
      'ui_state': 'enabled_real',
      'runtime_status': 'succeeded',
      'degraded_modes': <String>['validation_failure'],
      'rollback_strategy': 'block_invalid_package_before_acceptance',
    },
    {
      'agent_type': 'workbench_operator_agent',
      'display_name': 'Workbench Operator Agent',
      'ui_state': 'enabled_real',
      'runtime_status': 'succeeded',
      'degraded_modes': <String>['unknown_action', 'rollback_unavailable'],
      'rollback_strategy': 'rollback_where_action_contract_supports_it',
    },
    {
      'agent_type': 'external_verification_agent',
      'display_name': 'External Verification Agent',
      'ui_state': 'enabled_real',
      'runtime_status': 'succeeded',
      'degraded_modes': <String>['unavailable_source', 'untrusted_source'],
      'rollback_strategy': 'no_external_mutation',
    },
  ],
  'advanced_capabilities_6b': <Map<String, dynamic>>[
    {
      'capability_id': 'long_term_memory',
      'ui_state': 'enabled_real',
      'runtime_status': 'pass',
      'coverage': <String>['write', 'read', 'expiration', 'deletion', 'audit'],
    },
    {
      'capability_id': 'multi_agent_workflow',
      'ui_state': 'enabled_real',
      'runtime_status': 'pass',
      'coverage': <String>[
        'scheduler',
        'handoff',
        'conflict_handling',
        'rollback'
      ],
    },
    {
      'capability_id': 'a2a',
      'ui_state': 'enabled_real',
      'runtime_status': 'pass',
      'coverage': <String>['message_contract', 'permissions', 'evidence_refs'],
    },
    {
      'capability_id': 'agent_teams',
      'ui_state': 'enabled_real',
      'runtime_status': 'pass',
      'coverage': <String>['roles', 'tool_permissions', 'per_agent_isolation'],
    },
    {
      'capability_id': 'multi_agent_security',
      'ui_state': 'enabled_real',
      'runtime_status': 'pass',
      'coverage': <String>['no_permission_escalation', 'no_arbitrary_shell'],
    },
    {
      'capability_id': 'computer_use_boundary',
      'ui_state': 'disabled_boundary',
      'runtime_status': 'disabled_boundary',
      'coverage': <String>['threat_model'],
    },
  ],
  'tool_adapter_gate': {
    'ui_state': 'enabled_real',
    'final_status':
        'tool_adapter_configuration_production_grade_accepted_ui_bound',
    'provider_runtime_reimplemented': false,
    'unregistered_third_party_api_integrated': false,
    'official_channel_tool_adapter_gate_required': true,
    'secret_plaintext_written': false,
    'network_source_policy_required': true,
    'live_smoke_status': 'pass',
    'official_channel_live_smoke': 'not_run_missing_owner_credentials',
    'auth_type_coverage': <String>['api_key', 'bearer', 'oauth', 'signature'],
    'api_config_schema_fields': <String>[
      'base_url_env',
      'token_env',
      'auth_type',
      'timeout',
      'retry',
      'rate_limit',
      'permission_policy',
      'redaction',
    ],
    'adapters': <Map<String, dynamic>>[
      {
        'adapter_id': 'provider_runtime',
        'ui_state': 'enabled_real',
        'auth_type': 'bearer',
        'live_smoke_status': 'configured_no_network_by_default',
      },
      {
        'adapter_id': 'workbench_bridge',
        'ui_state': 'enabled_real',
        'auth_type': 'none',
        'live_smoke_status': 'local_dry_run_pass',
      },
      {
        'adapter_id': 'external_source_verification',
        'ui_state': 'enabled_real',
        'auth_type': 'none',
        'live_smoke_status': 'local_manual_evidence_pass',
      },
      {
        'adapter_id': 'official_channel_api_key_future',
        'ui_state': 'disabled_boundary',
        'auth_type': 'api_key',
        'live_smoke_status': 'not_run_missing_credentials',
      },
      {
        'adapter_id': 'official_channel_oauth_future',
        'ui_state': 'disabled_boundary',
        'auth_type': 'oauth',
        'live_smoke_status': 'not_run_missing_oauth',
      },
      {
        'adapter_id': 'official_channel_signature_future',
        'ui_state': 'disabled_boundary',
        'auth_type': 'signature',
        'live_smoke_status': 'not_run_missing_signature_key',
      },
    ],
  },
  'security_boundaries': {
    'no_secret_plaintext': true,
    'no_arbitrary_shell': true,
    'no_agent_self_authorized_tool': true,
    'no_cross_agent_secret_or_workspace_access': true,
    'no_campaign_7_8_9': true,
  },
};

const sampleSkillGovernanceReport = <String, dynamic>{
  'skill_governance_report_version': 'v4.2-p2.2-1',
  'status': 'pass',
  'release_ready': true,
  'skill_name': 'README Operations Skill',
  'checks': {
    'validation': {'status': 'pass'},
    'diff_comparison': {
      'status': 'pass',
      'baseline_provided': true,
      'changed_file_count': 3,
    },
    'installability': {'status': 'pass'},
    'token_budget': {'status': 'pass'},
  },
  'ui_contract': {
    'asset_id': 'skill_governance_report_json',
    'ready_for_workbench_display': true,
  },
};

const sampleMethodologyMap = <String, dynamic>{
  'methodology_map_version': 'v4.2-p2.2-1',
  'source_package_id': 'pkg-operations',
  'module_count': 2,
  'confidence': 0.91,
  'risk_flags': <String>[],
  'source_evidence': <String>['window_001', 'window_002'],
  'unsupported_claim_detection': {
    'status': 'pass',
    'excluded_count': 0,
  },
  'methodology_modules': <Map<String, dynamic>>[
    {
      'module_id': 'methodology_module_001',
      'title': 'Evidence-led Operations',
      'concepts': <Map<String, dynamic>>[
        {'statement': 'Evidence-led Operations'}
      ],
      'principles': <Map<String, dynamic>>[
        {'statement': 'Use local evidence and prefer narrow scope.'}
      ],
      'workflows': <Map<String, dynamic>>[
        {'statement': 'First inspect the source, then apply the decision rule.'}
      ],
    },
    {
      'module_id': 'methodology_module_002',
      'title': 'Review Boundary',
      'concepts': <Map<String, dynamic>>[
        {'statement': 'Review Boundary'}
      ],
      'principles': <Map<String, dynamic>>[
        {'statement': 'Unsupported claims require review.'}
      ],
      'workflows': <Map<String, dynamic>>[],
    },
  ],
};
