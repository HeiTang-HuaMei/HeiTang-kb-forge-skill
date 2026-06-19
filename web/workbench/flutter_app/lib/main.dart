import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, rootBundle;

import 'core_actions/core_action_panel.dart';
import 'core_actions/page_action_mapping.dart';
import 'core_actions/workbench_actions.dart';
import 'core_bridge/local_core_bridge.dart';
import 'contracts/workbench_contracts.dart';
import 'backend_evidence/parser_backend_dashboard.dart';
import 'rc6_runtime/rc6_runtime_controller.dart';
import 'skill_factory/skill_factory_workflow.dart';

part 'app/product_top_bar.dart';
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
  static const double minWindowWidth = 820;
  static const double compactSidebarWidth = 168;
  static const double gutter = 8;
  static const double sectionGap = 10;
  static const double panelPadding = 10;
  static const double panelRadius = 8;
  static const double maxPageWidth = 1720;
  static const double panelMinHeight = 126;
  static const double metricHeight = 114;
  static const double rowBreakpoint = 1120;
  static const double footerSafeArea = 84;
}

enum _DesktopWindowPreviewState { restored, maximized }

const supportedLocaleCodes = <String>['zh-CN', 'en-US'];
const _appVersionLabel = 'v4.3.0-rc10';

const pages = <WorkbenchPage>[
  WorkbenchPage(
      'dashboard',
      'Dashboard',
      '首页',
      'Workbench overview, recent work, health, artifacts, and next actions.',
      '工作台概览、最近任务、健康状态、产物与下一步行动。',
      memberPageIds: ['dashboard']),
  WorkbenchPage(
      'workbook',
      'Workbook',
      '工作本管理',
      'Review the current workbook, persistence state, recent assets, and handoff points.',
      '查看当前工作本、持久化状态、最近资产和下一步承接入口。',
      memberPageIds: ['workspace']),
  WorkbenchPage(
      'document-library',
      'Document Library',
      '文档库',
      'Manage source documents, metadata, parsing records, versions, references, and artifacts.',
      '管理来源文档、元数据、解析记录、版本、引用和产物。',
      memberPageIds: [
        'import-parsing',
        'document-library',
      ]),
  WorkbenchPage(
      'knowledge-package-management',
      'Knowledge Base',
      '知识库',
      'Manage knowledge bases, vector indexes, quality, versions, builds, and validation records.',
      '管理知识库、向量索引、质量、版本、构建与验证记录。',
      memberPageIds: [
        'knowledge-package-management',
        'vector-hub-provider-storage',
      ]),
  WorkbenchPage(
      'retrieval-verification',
      'Retrieval & Verification',
      '检索与验证',
      'Rewrite queries, plan retrieval, select evidence, rerank, and verify against local evidence.',
      '执行查询改写、检索规划、证据选择、重排，以及基于本地证据的验证。',
      memberPageIds: ['retrieval-verification']),
  WorkbenchPage(
      'document-generation',
      'Document Generation',
      '文档生成',
      'Choose a knowledge base, template, and output type, then generate, validate, and export documents inside this module.',
      '选择知识库、文档模板和输出类型，在本模块完成生成、验证与导出。',
      memberPageIds: ['document-generation']),
  WorkbenchPage(
      'skill-factory',
      'Skill Factory',
      'Skill 工厂',
      'Create, validate, and export governed Skill drafts from real knowledge bases.',
      '基于真实知识库创建、验证和导出经过治理的 Skill 草稿。',
      memberPageIds: ['skill-factory']),
  WorkbenchPage(
      'agent-factory-runtime',
      'Agent Workbench',
      'Agent 工作台',
      'Create Agents, run single-agent dialogue, and coordinate governed multi-agent discussion.',
      '创建 Agent、运行单 Agent 对话，并协调受治理的多 Agent 讨论。',
      memberPageIds: ['agent-factory-runtime']),
  WorkbenchPage(
      'reports-audit',
      'Audit Center',
      '审计中心',
      'Review quality, retrieval, OCR, safety, governance reports, issues, and repair suggestions.',
      '查看质量、检索、OCR、安全和治理报告、问题与修复建议。',
      memberPageIds: [
        'reports-audit',
        'error-repair-center',
        'governance',
        'memory-center',
      ]),
  WorkbenchPage(
      'artifact-center',
      'Artifact Center',
      '产物中心',
      'Browse generated documents, knowledge artifacts, Skills, Agents, dialogue records, and A2A outputs from real workspace state.',
      '从真实工作区状态浏览生成文档、知识库产物、Skill、Agent、对话记录和 A2A 输出。',
      memberPageIds: ['artifact-management']),
  WorkbenchPage(
      'workspace',
      'Run Settings',
      '运行设置',
      'Manage workspace, models, providers, Redis, vector database, storage, and security authorization.',
      '管理工作区、模型、Provider、Redis、向量库、存储和安全授权。',
      memberPageIds: [
        'workspace',
        'vector-hub-provider-storage',
      ]),
];

// Legacy web/P1 routes remain covered by the Flutter source contract, but they
// are not mounted into the user-facing dashboard product flow.
const productFlowHiddenContractRouteIds = <String>[
  'operation-gate',
  'capability-matrix',
  'task-job-center',
];

class WorkbenchPage {
  const WorkbenchPage(this.id, this.enTitle, this.zhTitle, this.enDescription,
      this.zhDescription,
      {this.memberPageIds = const <String>[]});

  final String id;
  final String enTitle;
  final String zhTitle;
  final String enDescription;
  final String zhDescription;
  final List<String> memberPageIds;

  List<String> get pageIds => memberPageIds.isEmpty ? [id] : memberPageIds;

  String title(String localeCode, WorkbenchContracts _) {
    if (localeCode == 'zh-CN') {
      return zhTitle;
    }
    return enTitle;
  }

  String description(String localeCode) =>
      localeCode == 'zh-CN' ? zhDescription : enDescription;
}

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

  @override
  Widget build(BuildContext context) {
    final currentPage = pages[selectedIndex];
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
      home: FutureBuilder<WorkbenchContracts>(
        future: _contractsFuture,
        initialData: widget.contracts ?? sampleWorkbenchContracts,
        builder: (context, contractsSnapshot) =>
            FutureBuilder<P1WorkflowEvidence>(
          future: _workflowEvidenceFuture,
          initialData: widget.workflowEvidence ?? sampleP1WorkflowEvidence,
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
                  FutureBuilder<ParserBackendMatrix>(
                future: _parserBackendsFuture,
                initialData: widget.parserBackends ?? sampleParserBackendMatrix,
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
                      initialData: widget.campaign9DesktopDeliveryStatus ??
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
                            workflowV2Evidence:
                                v2Snapshot.data ?? sampleP1WorkflowV2Evidence,
                            externalCapabilities: externalSnapshot.data ??
                                sampleExternalCapabilityRegistry,
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
                            methodologyMap:
                                widget.methodologyMap ?? sampleMethodologyMap,
                            skillSuiteWorkflow: widget.skillSuiteWorkflow,
                            localeCode: localeCode,
                            themeMode: themeMode,
                            selectedIndex: selectedIndex,
                            isDark: isDark,
                            coreBridge: widget.coreBridge,
                            coreCli: widget.coreCli,
                            coreWorkingDirectory: widget.coreWorkingDirectory,
                            coreWorkspace: widget.coreWorkspace,
                            enableLocalCoreActions:
                                widget.enableLocalCoreActions,
                            isWebRuntime: widget.isWebRuntime,
                            onThemeChanged: (value) =>
                                setState(() => themeMode = value),
                            onLocaleChanged: (value) =>
                                setState(() => localeCode = value),
                            onPageChanged: (index) =>
                                setState(() => selectedIndex = index),
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
    final colors = ColorScheme.fromSeed(
      seedColor:
          isDarkTheme ? const Color(0xfff7f7f5) : const Color(0xff111111),
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors.copyWith(
        primary:
            isDarkTheme ? const Color(0xfff7f7f5) : const Color(0xff111111),
        surface:
            isDarkTheme ? const Color(0xff181818) : const Color(0xffffffff),
      ),
      scaffoldBackgroundColor:
          isDarkTheme ? const Color(0xff0f0f0f) : const Color(0xfff4f4f2),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      final sidebarWidth = constraints.maxWidth < 1366
          ? _DesktopGrid.compactSidebarWidth
          : constraints.maxWidth < 1440
              ? 184.0
              : 248.0;

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
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _PageSurface(
                    key: ValueKey('page-surface-$selectedIndex'),
                    page: pages[selectedIndex],
                    localeCode: localeCode,
                    contracts: contracts,
                    workflowEvidence: workflowEvidence,
                    workflowV2Evidence: workflowV2Evidence,
                    externalCapabilities: externalCapabilities,
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
                _DesktopStatusBar(
                  localeCode: localeCode,
                  workspace: coreWorkspace,
                  isWebRuntime: isWebRuntime,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _DesktopStatusBar extends StatelessWidget {
  const _DesktopStatusBar({
    required this.localeCode,
    required this.workspace,
    required this.isWebRuntime,
  });

  final String localeCode;
  final String workspace;
  final bool isWebRuntime;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 720;
      final showVersion = constraints.maxWidth >= 760;
      final showUpdates = constraints.maxWidth >= 900;
      final gap = compact ? 10.0 : 24.0;
      return Container(
        key: const Key('desktop-status-bar'),
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 22),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          children: [
            _StatusBarItem(
              icon: Icons.circle,
              iconColor: Colors.green,
              label: _zh ? '系统状态' : 'System',
              value: _zh ? '正常运行' : 'Running',
            ),
            SizedBox(width: gap),
            Expanded(
              child: _StatusBarItem(
                icon: Icons.folder_open_outlined,
                label: _zh ? '位置' : 'Location',
                value: workspace,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: gap),
            _StatusBarItem(
              icon: isWebRuntime
                  ? Icons.public_outlined
                  : Icons.desktop_windows_outlined,
              label: _zh ? '模式' : 'Mode',
              value: isWebRuntime
                  ? (_zh ? '预览模式' : 'Preview mode')
                  : (_zh ? '桌面本地执行' : 'Desktop local'),
            ),
            if (showVersion) ...[
              SizedBox(width: gap),
              _StatusBarItem(
                icon: Icons.info_outline,
                label: _zh ? '版本' : 'Version',
                value: _appVersionLabel,
              ),
            ],
            if (showUpdates) ...[
              SizedBox(width: gap),
              _StatusBarItem(
                icon: Icons.sync_outlined,
                label: _zh ? '检查更新' : 'Check updates',
                value: '',
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _StatusBarItem extends StatelessWidget {
  const _StatusBarItem({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.overflow,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = value.isEmpty ? label : '$label: $value';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor ?? colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: overflow,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _WorkbenchSidebar extends StatelessWidget {
  const _WorkbenchSidebar({
    required this.localeCode,
    required this.contracts,
    required this.selectedIndex,
    required this.onPageChanged,
  });

  final String localeCode;
  final WorkbenchContracts contracts;
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    const sidebarBackground = Color(0xff12161a);
    const selectedBackground = Color(0xff2d3339);
    const primaryText = Color(0xfff7f7f5);
    const secondaryText = Color(0xffaeb6bf);
    final effectiveSelectedIndex = pages[selectedIndex].id == 'import-parsing'
        ? _pageIndexById('document-library')
        : selectedIndex;

    return Material(
      color: sidebarBackground,
      child: ListView(
        key: const Key('desktop-sidebar-scroll'),
        padding: const EdgeInsets.fromLTRB(8, 9, 8, 12),
        children: [
          _SidebarBrand(localeCode: localeCode),
          const SizedBox(height: 10),
          _SidebarGroupLabel(label: localeCode == 'zh-CN' ? '首页' : 'Home'),
          _SidebarItem(
            keyName: 'sidebar-dashboard',
            page: pages[0],
            icon: Icons.dashboard_customize_outlined,
            localeCode: localeCode,
            contracts: contracts,
            selected: effectiveSelectedIndex == 0,
            primaryText: primaryText,
            secondaryText: secondaryText,
            selectedBackground: selectedBackground,
            onTap: () => onPageChanged(0),
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _SidebarGroupLabel(label: localeCode == 'zh-CN' ? '工作本' : 'Workbook'),
          _SidebarItem(
            keyName: 'sidebar-workbook',
            page: pages[1],
            icon: Icons.workspaces_outline,
            localeCode: localeCode,
            contracts: contracts,
            selected: effectiveSelectedIndex == 1,
            primaryText: primaryText,
            secondaryText: secondaryText,
            selectedBackground: selectedBackground,
            onTap: () => onPageChanged(1),
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _SidebarGroupLabel(
              label: localeCode == 'zh-CN' ? '知识资产' : 'Knowledge Assets'),
          for (final index in [2, 3, 4])
            _SidebarItem(
              keyName: 'sidebar-${pages[index].id}',
              page: pages[index],
              icon: _sidebarIconFor(pages[index].id),
              localeCode: localeCode,
              contracts: contracts,
              selected: effectiveSelectedIndex == index,
              primaryText: primaryText,
              secondaryText: secondaryText,
              selectedBackground: selectedBackground,
              onTap: () => onPageChanged(index),
            ),
          const SizedBox(height: _DesktopGrid.gutter),
          _SidebarGroupLabel(
              label: localeCode == 'zh-CN' ? '知识应用' : 'Knowledge Apps'),
          for (final index in [5, 6, 7])
            _SidebarItem(
              keyName: 'sidebar-${pages[index].id}',
              page: pages[index],
              icon: _sidebarIconFor(pages[index].id),
              localeCode: localeCode,
              contracts: contracts,
              selected: effectiveSelectedIndex == index,
              primaryText: primaryText,
              secondaryText: secondaryText,
              selectedBackground: selectedBackground,
              onTap: () => onPageChanged(index),
            ),
          const SizedBox(height: _DesktopGrid.gutter),
          _SidebarGroupLabel(
              label: localeCode == 'zh-CN' ? '治理' : 'Governance'),
          for (final index in [8, 9])
            _SidebarItem(
              keyName: 'sidebar-${pages[index].id}',
              page: pages[index],
              icon: _sidebarIconFor(pages[index].id),
              localeCode: localeCode,
              contracts: contracts,
              selected: effectiveSelectedIndex == index,
              primaryText: primaryText,
              secondaryText: secondaryText,
              selectedBackground: selectedBackground,
              onTap: () => onPageChanged(index),
            ),
          const SizedBox(height: _DesktopGrid.gutter),
          _SidebarGroupLabel(label: localeCode == 'zh-CN' ? '系统' : 'System'),
          _SidebarItem(
            keyName: 'sidebar-workspace',
            page: pages[10],
            icon: Icons.tune_outlined,
            localeCode: localeCode,
            contracts: contracts,
            selected: effectiveSelectedIndex == 10,
            primaryText: primaryText,
            secondaryText: secondaryText,
            selectedBackground: selectedBackground,
            onTap: () => onPageChanged(10),
          ),
          const SizedBox(height: 10),
          _LocalFirstCard(localeCode: localeCode),
        ],
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({required this.localeCode});

  final String localeCode;

  @override
  Widget build(BuildContext context) {
    const primaryText = Color(0xfff7f7f5);
    const secondaryText = Color(0xffaeb6bf);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(localeCode == 'zh-CN' ? '黑糖' : 'HeiTang',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.w900,
                  )),
          const SizedBox(height: 2),
          Text(
              localeCode == 'zh-CN'
                  ? '知识工作台  $_appVersionLabel'
                  : 'Knowledge Workbench  $_appVersionLabel',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: secondaryText,
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: 10),
          const Divider(color: Color(0xff30363d), height: 1),
        ],
      ),
    );
  }
}

class _SidebarGroupLabel extends StatelessWidget {
  const _SidebarGroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 4, 7, 3),
      child: Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xff8d98a5),
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              )),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    this.keyName,
    required this.page,
    required this.icon,
    required this.localeCode,
    required this.contracts,
    required this.selected,
    required this.primaryText,
    required this.secondaryText,
    required this.selectedBackground,
    required this.onTap,
  });

  final String? keyName;
  final WorkbenchPage page;
  final IconData icon;
  final String localeCode;
  final WorkbenchContracts contracts;
  final bool selected;
  final Color primaryText;
  final Color secondaryText;
  final Color selectedBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: InkWell(
        key: keyName == null ? null : Key(keyName!),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? selectedBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? Border.all(color: const Color(0xff46515c))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xff3a424b)
                      : const Color(0xff1a1f24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon,
                    color: selected ? primaryText : secondaryText, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(page.title(localeCode, contracts),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? primaryText : secondaryText,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalFirstCard extends StatelessWidget {
  const _LocalFirstCard({required this.localeCode});

  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xff20262c),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff38414a)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined,
                  color: Color(0xfff7f7f5), size: 22),
              const SizedBox(width: _DesktopGrid.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(localeCode == 'zh-CN' ? '本地优先' : 'Local first',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: const Color(0xfff7f7f5),
                              fontWeight: FontWeight.w900,
                            )),
                    const SizedBox(height: 2),
                    Text(
                        localeCode == 'zh-CN'
                            ? '默认不连接云服务'
                            : 'Cloud is off by default',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xffaeb6bf),
                            )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xff12161a),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xff38414a)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline,
                    color: Color(0xffaeb6bf), size: 14),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                      localeCode == 'zh-CN'
                          ? '安全授权受保护'
                          : 'Authorization protected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: const Color(0xffaeb6bf),
                            fontWeight: FontWeight.w800,
                          )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _sidebarIconFor(String pageId) {
  switch (pageId) {
    case 'dashboard':
      return Icons.dashboard_customize_outlined;
    case 'import-parsing':
      return Icons.file_upload_outlined;
    case 'document-library':
      return Icons.library_books_outlined;
    case 'knowledge-package-management':
      return Icons.inventory_2_outlined;
    case 'retrieval-verification':
      return Icons.manage_search_outlined;
    case 'document-generation':
      return Icons.edit_document;
    case 'skill-factory':
      return Icons.extension_outlined;
    case 'agent-factory-runtime':
      return Icons.smart_toy_outlined;
    case 'reports-audit':
      return Icons.assignment_outlined;
    case 'artifact-center':
      return Icons.folder_copy_outlined;
    case 'workspace':
      return Icons.settings_outlined;
    default:
      return Icons.circle_outlined;
  }
}

int _pageIndexById(String pageId) {
  final normalizedPageId =
      pageId == 'import-parsing' ? 'document-library' : pageId;
  final index = pages.indexWhere((page) => page.id == normalizedPageId);
  return index < 0 ? 0 : index;
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
    final workflowEvidence = widget.workflowEvidence;
    final workflowV2Evidence = widget.workflowV2Evidence;
    final externalCapabilities = widget.externalCapabilities;
    final parserBackends = widget.parserBackends;
    final campaign6AgentRuntimeStatus = widget.campaign6AgentRuntimeStatus;
    final campaign7ConfigurationStatus = widget.campaign7ConfigurationStatus;
    final campaign9DesktopDeliveryStatus =
        widget.campaign9DesktopDeliveryStatus;
    final skillGovernanceReport = widget.skillGovernanceReport;
    final methodologyMap = widget.methodologyMap;
    final skillSuiteWorkflow = widget.skillSuiteWorkflow;
    final columns = widget.columns;
    final coreBridge = widget.coreBridge;
    final coreCli = widget.coreCli;
    final coreWorkingDirectory = widget.coreWorkingDirectory;
    final coreWorkspace = widget.coreWorkspace;
    final enableLocalCoreActions = widget.enableLocalCoreActions;
    final isWebRuntime = widget.isWebRuntime;
    final isDark = widget.isDark;
    final windowState = widget.windowState;
    final onWindowStateChanged = widget.onWindowStateChanged;
    final onThemeChanged = widget.onThemeChanged;
    final onLocaleChanged = widget.onLocaleChanged;
    final onPageChanged = widget.onPageChanged;
    final isDashboard = page.id == 'dashboard';
    final cards = _cardsFor(
        page.id,
        page,
        localeCode,
        contracts,
        workflowEvidence,
        workflowV2Evidence,
        externalCapabilities,
        parserBackends,
        skillGovernanceReport,
        methodologyMap);
    final corePanels = <Widget>[];
    final actionById = <String, ContractAction>{};
    for (final pageId in page.pageIds) {
      for (final action in coreActionsForPage(pageId, contracts)) {
        actionById[action.id] = action;
      }
    }
    final rc5RuntimeActions = _rc5RuntimeActionsForPage(page.id);
    for (final action in rc5RuntimeActions) {
      actionById[action.id] = action;
    }
    final pageActions = actionById.values.where(
      (action) =>
          page.id != 'dashboard' &&
          (page.id != 'agent-factory-runtime' ||
              const {
                'standalone_agent_generation',
                'kb_bound_agent_generation',
              }.contains(action.id)),
    );
    for (final action in pageActions) {
      final request = coreRequestForAction(
        action: action,
        coreCli: coreCli,
        workingDirectory: coreWorkingDirectory,
        workspace: coreWorkspace,
      );
      corePanels.add(
        CoreActionPanel(
          key: Key('diagnostic-core-action-${action.id}'),
          action: action,
          request: request,
          coreBridge: coreBridge,
          isWebRuntime: isWebRuntime,
          enabled: enableLocalCoreActions,
          localeCode: localeCode,
        ),
      );
    }
    final diagnostics = _DeveloperDiagnosticsDetails(
      localeCode: localeCode,
      cards: cards,
      columns: columns,
      corePanels: corePanels,
      parserBackends:
          page.pageIds.any(_showsParserBackends) ? parserBackends : null,
      skillFactoryWorkflow:
          page.pageIds.any(_showsSkillGovernance) ? skillSuiteWorkflow : null,
    );

    return LayoutBuilder(builder: (context, constraints) {
      const horizontalPadding = 16.0;
      final availableWidth = constraints.maxWidth - horizontalPadding * 2;
      final contentWidth = availableWidth > _DesktopGrid.maxPageWidth
          ? _DesktopGrid.maxPageWidth
          : availableWidth < 0
              ? 0.0
              : availableWidth;
      return Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          key: ValueKey('page-scroll-${page.id}'),
          primary: false,
          padding: const EdgeInsets.all(horizontalPadding),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 0,
                maxWidth: contentWidth,
                minHeight: constraints.maxHeight - horizontalPadding * 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductTopBar(
                    localeCode: localeCode,
                    page: page,
                    contracts: contracts,
                    showTitleBlock: isDashboard,
                    isDark: isDark,
                    windowState: windowState,
                    onWindowStateChanged: onWindowStateChanged,
                    onThemeChanged: onThemeChanged,
                    onLocaleChanged: onLocaleChanged,
                    onPageChanged: onPageChanged,
                  ),
                  const SizedBox(height: _DesktopGrid.sectionGap),
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
                    const SizedBox(height: _DesktopGrid.sectionGap),
                  ],
                  if (!isDashboard) ...[
                    _ProductPageOverview(
                      localeCode: localeCode,
                      page: page,
                      workspace: coreWorkspace,
                      campaign6AgentRuntimeStatus: campaign6AgentRuntimeStatus,
                      campaign7ConfigurationStatus:
                          campaign7ConfigurationStatus,
                      campaign9DesktopDeliveryStatus:
                          campaign9DesktopDeliveryStatus,
                      isWebRuntime: isWebRuntime,
                      diagnostics: diagnostics,
                      onPageChanged: onPageChanged,
                    ),
                    const SizedBox(height: _DesktopGrid.sectionGap),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  List<_CardCopy> _cardsFor(
    String id,
    WorkbenchPage page,
    String localeCode,
    WorkbenchContracts contracts,
    P1WorkflowEvidence workflowEvidence,
    P1WorkflowEvidence workflowV2Evidence,
    ExternalCapabilityRegistry externalCapabilities,
    ParserBackendMatrix parserBackends,
    Map<String, dynamic> skillGovernanceReport,
    Map<String, dynamic> methodologyMap,
  ) {
    final zh = localeCode == 'zh-CN';
    final views = page.pageIds
        .map((pageId) => _contractViewForId(pageId, contracts))
        .toList(growable: false);
    final actions = views
        .expand((view) => _actionsForView(view, contracts))
        .toList(growable: false);
    final reports = views
        .expand((view) => _reportsForView(view, contracts))
        .toList(growable: false);
    final artifacts = views
        .expand((view) => _artifactsForView(view, contracts))
        .toList(growable: false);
    final common = views.expand((view) => view.assetTypes).isEmpty
        ? (zh ? '合同样例' : 'Contract sample')
        : views.expand((view) => view.assetTypes).join(' · ');
    final externalProjects = views
        .map((view) => view.corePageId)
        .expand(externalCapabilities.projectsForCorePage)
        .fold(<String, ExternalCapabilityProject>{}, (projects, project) {
          projects[project.projectId] = project;
          return projects;
        })
        .values
        .toList(growable: false);
    final providerProjects = externalProjects
        .where((project) =>
            project.contractStatus.contains('provider_required') ||
            project.requiresApiKey ||
            project.requiresNetwork ||
            project.requiresExternalRuntime)
        .toList(growable: false);
    final templateProjects = externalProjects
        .where(
            (project) => project.contractStatus.contains('template_reference'))
        .toList(growable: false);
    final governanceChecks =
        (skillGovernanceReport['checks'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final governanceUiContract = (skillGovernanceReport['ui_contract'] as Map?)
            ?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final diffCheck = (governanceChecks['diff_comparison'] as Map?)
            ?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final installabilityCheck =
        (governanceChecks['installability'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final validationCheck =
        (governanceChecks['validation'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final tokenBudgetCheck =
        (governanceChecks['token_budget'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final methodologyModules =
        (methodologyMap['methodology_modules'] as List?) ?? const <dynamic>[];
    final firstMethodologyModule = methodologyModules.isEmpty
        ? const <String, dynamic>{}
        : (methodologyModules.first as Map).cast<String, dynamic>();
    final methodologyEvidence =
        (methodologyMap['source_evidence'] as List?) ?? const <dynamic>[];
    final methodologyRisks =
        (methodologyMap['risk_flags'] as List?) ?? const <dynamic>[];
    final unsupportedClaims =
        (methodologyMap['unsupported_claim_detection'] as Map?)
                ?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    return [
      _CardCopy(zh ? 'Core 来源' : 'Core source', contracts.source.coreCommit),
      _CardCopy(
          zh ? '操作契约' : 'Action contracts',
          actions.isEmpty
              ? common
              : actions.map((action) => action.id).take(3).join(' · ')),
      _CardCopy(
          zh ? '报告契约' : 'Report contracts',
          reports.isEmpty
              ? '${contracts.status.reportCount}'
              : reports.map((report) => report.id).take(3).join(' · ')),
      _CardCopy(
          zh ? '产物契约' : 'Artifact contracts',
          artifacts.isEmpty
              ? '${contracts.status.assetCount}'
              : artifacts.map((artifact) => artifact.id).take(3).join(' · ')),
      _CardCopy(zh ? '任务状态' : 'Task statuses',
          contracts.taskSchema.statuses.join(' · ')),
      _CardCopy(zh ? '门禁状态' : 'Gate status',
          '${contracts.gate.status} · not_v4_0_workbench_rc=${contracts.gate.notV4WorkbenchRc}'),
      if (page.pageIds.any(_showsWorkflowEvidence))
        _CardCopy(zh ? 'P1-RWF-V1 状态' : 'P1-RWF-V1 status',
            '${workflowEvidence.status} · full_gate=${workflowEvidence.fullGateStatus}'),
      if (page.pageIds.any(_showsWorkflowEvidence))
        _CardCopy(zh ? '命令漂移' : 'Command drift',
            'drift_count=${workflowEvidence.driftCount} · fixture_only_real=${workflowEvidence.fixtureOnlyCountedAsReal}'),
      if (page.pageIds.any(_showsWorkflowEvidence))
        _CardCopy(zh ? '黄金工作流' : 'Golden workflows',
            '${workflowEvidence.workflowCount} · ${workflowEvidence.evidenceLevelCounts.entries.map((entry) => '${entry.key}:${entry.value}').join(' · ')}'),
      if (page.pageIds.any(_showsWorkflowEvidence))
        _CardCopy(zh ? '剩余阻塞' : 'Remaining blockers',
            workflowEvidence.remainingBlockers.take(2).join(' · ')),
      if (page.pageIds.any(_showsV2Evidence))
        _CardCopy(zh ? 'P1-RWF-V2 状态' : 'P1-RWF-V2 status',
            '${workflowV2Evidence.status} · full_gate=${workflowV2Evidence.fullGateStatus}'),
      if (page.pageIds.any(_showsV2Evidence))
        _CardCopy(zh ? '57 action 矩阵' : '57 action matrix',
            '${workflowV2Evidence.passedActionCount}/${workflowV2Evidence.executionTargetCount} passed · failed=${workflowV2Evidence.failedActionCount}'),
      if (page.pageIds.any(_showsV2Evidence))
        _CardCopy(zh ? '产物 / 报告断言' : 'Artifact / report assertions',
            'artifact=${workflowV2Evidence.artifactAssertionStatus} · report=${workflowV2Evidence.reportAssertionStatus} · error=${workflowV2Evidence.errorBoundaryStatus}'),
      if (page.pageIds.any(_showsV2Evidence))
        _CardCopy(zh ? '用户路径闭环' : 'User path closure',
            '${workflowV2Evidence.userPathClosureStatus} · ${workflowV2Evidence.userPathPassedCount}/${workflowV2Evidence.userPathCount} paths'),
      if (page.pageIds.any(_showsV2Evidence))
        _CardCopy(zh ? 'UI 门禁' : 'UI gate',
            'ui_full_operation_pending=${workflowV2Evidence.uiFullOperationPending} · rc_candidate=${workflowV2Evidence.readyForV4RcCandidate} · ready_for_v4_rc=${workflowV2Evidence.readyForV4Rc}'),
      if (page.pageIds.any(_showsV2Evidence))
        _CardCopy(
            zh ? 'Provider/secret blocked' : 'Provider/secret blocked',
            workflowV2Evidence.blockedActions
                .map((action) => '${action.actionId}:${action.classification}')
                .take(2)
                .join(' · ')),
      if (page.pageIds.any(_showsExternalCapabilities))
        _CardCopy(zh ? 'S/A 外部能力' : 'S/A external capabilities',
            'S=${externalCapabilities.sProjectCount} · A=${externalCapabilities.aProjectCount} · anchors=${externalCapabilities.internalCapabilityAnchorCount}'),
      if (page.pageIds.any(_showsExternalCapabilities))
        _CardCopy(zh ? 'Adapter 边界' : 'Adapter boundary',
            'planned=${externalCapabilities.plannedAdapterCount} · future=${externalCapabilities.futureAdapterCount} · ready=false'),
      if (page.pageIds.any(_showsExternalCapabilities))
        _CardCopy(zh ? 'Provider 边界' : 'Provider boundary',
            'provider_required=${externalCapabilities.providerRequiredCount} · local_ready=false'),
      if (page.pageIds.any(_showsParserBackends))
        _CardCopy(zh ? 'Parser Backend Matrix' : 'Parser Backend Matrix',
            '${parserBackends.releaseVersion} · ${parserBackends.backends.length} backends · static_runtime=${parserBackends.staticWorkbenchRuntimeExecutionClaimed}'),
      if (page.pageIds.any(_showsParserBackends))
        _CardCopy(
            zh ? 'Backend Status Detail' : 'Backend Status Detail',
            parserBackends.backends
                .map((backend) => '${backend.backendId}:${backend.status}')
                .join(' · ')),
      if (page.pageIds.any(_showsParserBackends))
        _CardCopy(
            zh ? 'Backend Install Mode' : 'Backend Install Mode',
            parserBackends.backends
                .map((backend) =>
                    '${backend.backendId}:${backend.optionalExtra ?? backend.dependencyMode}')
                .join(' · ')),
      if (page.pageIds.any(_showsParserBackends))
        _CardCopy(
            zh ? 'Backend Last Acceptance' : 'Backend Last Acceptance',
            parserBackends.backends
                .map((backend) =>
                    '${backend.backendId}:dep=${backend.dependencyAvailable},run=${backend.runtimeInvoked}')
                .join(' · ')),
      if (page.pageIds.any(_showsParserBackends))
        _CardCopy(
            zh
                ? 'Backend Capability Boundaries'
                : 'Backend Capability Boundaries',
            parserBackends.backends
                .map((backend) =>
                    '${backend.backendId}:${backend.validatedStableSurface.join('/')}')
                .join(' · ')),
      if (page.pageIds.any(_showsParserBackends))
        _CardCopy(
            zh ? 'Backend Known Limitations' : 'Backend Known Limitations',
            '${parserBackends.backend('unstructured')?.knownLimitations.first ?? 'limited_surface'} · default_heavy_deps=${parserBackends.defaultHeavyDependenciesBundled}'),
      if (page.pageIds.any(_showsParserBackends))
        _CardCopy(zh ? 'Backend Evidence Link' : 'Backend Evidence Link',
            '${parserBackends.acceptanceReportPath} · ${parserBackends.knownLimitationReportPath}'),
      if (_showsParserBackends(id))
        _CardCopy(
            zh ? 'Optional Dependency Reason' : 'Optional Dependency Reason',
            'optional_gated=${parserBackends.optionalDependencyGatedCount} · no_static_execution=${parserBackends.backends.every((backend) => !backend.staticWorkbenchExecutable)}'),
      if (page.pageIds.any(_showsSkillGovernance))
        _CardCopy(zh ? 'Skill Governance Report' : 'Skill Governance Report',
            '${skillGovernanceReport['skill_name'] ?? 'unknown'} · status=${skillGovernanceReport['status']} · release_ready=${skillGovernanceReport['release_ready']}'),
      if (page.pageIds.any(_showsSkillGovernance))
        _CardCopy(zh ? 'Diff baseline' : 'Diff baseline',
            'diff=${diffCheck['status']} · baseline=${diffCheck['baseline_provided']} · changed=${diffCheck['changed_file_count']}'),
      if (page.pageIds.any(_showsSkillGovernance))
        _CardCopy(
            zh ? 'Validation / installability' : 'Validation / installability',
            'validation=${validationCheck['status']} · installability=${installabilityCheck['status']} · budget=${tokenBudgetCheck['status']}'),
      if (page.pageIds.any(_showsSkillGovernance))
        _CardCopy(
            zh ? 'Workbench display evidence' : 'Workbench display evidence',
            'asset=${governanceUiContract['asset_id']} · display=${governanceUiContract['ready_for_workbench_display']} · static_only=true'),
      if (page.pageIds.any(_showsMethodology))
        _CardCopy(zh ? '方法论地图' : 'Methodology Map',
            '${methodologyMap['source_package_id']} · modules=${methodologyMap['module_count']} · confidence=${methodologyMap['confidence']}'),
      if (page.pageIds.any(_showsMethodology))
        _CardCopy(zh ? 'Evidence Windows' : 'Evidence Windows',
            'count=${methodologyEvidence.length} · ${methodologyEvidence.take(3).join(' · ')}'),
      if (page.pageIds.any(_showsMethodology))
        _CardCopy(zh ? '方法论模块' : 'Methodology Module',
            '${firstMethodologyModule['title']} · concepts=${(firstMethodologyModule['concepts'] as List?)?.length ?? 0} · principles=${(firstMethodologyModule['principles'] as List?)?.length ?? 0} · workflows=${(firstMethodologyModule['workflows'] as List?)?.length ?? 0}'),
      if (page.pageIds.any(_showsMethodology))
        _CardCopy(zh ? '来源追踪 / 风险' : 'Source Trace / Risk',
            'trace=${methodologyEvidence.length} · unsupported=${unsupportedClaims['status']} · risks=${methodologyRisks.isEmpty ? 'none' : methodologyRisks.join('/')} · static_only=true'),
      if (externalProjects.isNotEmpty)
        _CardCopy(
            zh ? '页面映射' : 'Mapped external projects',
            externalProjects
                .map((project) =>
                    '${project.projectName}:${project.contractStatus.join('/')}')
                .take(2)
                .join(' · ')),
      if (providerProjects.isNotEmpty)
        _CardCopy(
            zh ? 'blocked_reason' : 'blocked_reason',
            providerProjects
                .map((project) =>
                    '${project.projectId}:${project.blockedReason}')
                .take(2)
                .join(' · ')),
      if (templateProjects.isNotEmpty)
        _CardCopy(
            zh ? '模板参考' : 'Template references',
            templateProjects
                .map((project) => project.projectName)
                .take(3)
                .join(' · ')),
      if (page.pageIds.contains('operation-gate'))
        _CardCopy(zh ? 'S/A 不影响 P1' : 'S/A does not affect P1',
            'p1_gate_changed=${externalCapabilities.releaseBoundary['p1_gate_changed']} · v4_0_started=${externalCapabilities.releaseBoundary['v4_0_started']}'),
      if (page.pageIds.contains('capability-matrix'))
        _CardCopy(
            zh ? 'Action 分类' : 'Action classification',
            workflowV2Evidence.actionResults
                .map((action) => '${action.actionId}:${action.status}')
                .take(2)
                .join(' · ')),
      if (page.pageIds.contains('capability-matrix'))
        _CardCopy(zh ? '能力域' : 'Capability areas',
            '${contracts.capabilities.areas.length}'),
      if (page.pageIds.contains('task-job-center'))
        _CardCopy(
            zh ? 'Task evidence' : 'Task evidence',
            workflowV2Evidence.actionResults
                .map((action) => '${action.actionId}:${action.assertionStatus}')
                .take(2)
                .join(' · ')),
      if (page.pageIds.contains('artifact-management'))
        _CardCopy(
            zh ? 'Artifact evidence' : 'Artifact evidence',
            workflowV2Evidence.actionResults
                .map((action) => '${action.actionId}:${action.artifactCount}')
                .take(2)
                .join(' · ')),
      if (page.pageIds.contains('reports-audit'))
        _CardCopy(
            zh ? 'Gate impact' : 'Gate impact',
            workflowV2Evidence.userPaths
                .map((path) => '${path.userPathId}:${path.gateImpact}')
                .take(1)
                .join('')),
      if (page.pageIds.contains('agent-factory-runtime'))
        _CardCopy(zh ? 'Agent 模式' : 'Agent modes',
            contracts.agent.supportedModes.join(' · ')),
      if (page.pageIds.contains('error-repair-center'))
        _CardCopy(zh ? '错误码' : 'Error codes',
            contracts.errors.errorStates.join(' · ')),
      if (page.pageIds.contains('error-repair-center'))
        _CardCopy(
            zh ? 'Blocked reason' : 'Blocked reason',
            workflowV2Evidence.blockedActions
                .map((action) => action.blockedReason)
                .take(1)
                .join('')),
      if (page.pageIds.contains('document-generation'))
        _CardCopy(
            zh ? '文档模板' : 'Document templates',
            contracts.templates.templates
                .map((template) => template.id)
                .take(3)
                .join(' · ')),
    ];
  }
}

class _WorkbenchScaffold extends StatelessWidget {
  const _WorkbenchScaffold({
    required this.contracts,
    required this.workflowEvidence,
    required this.workflowV2Evidence,
    required this.externalCapabilities,
    required this.parserBackends,
    required this.campaign6AgentRuntimeStatus,
    required this.campaign7ConfigurationStatus,
    required this.campaign9DesktopDeliveryStatus,
    required this.skillGovernanceReport,
    required this.methodologyMap,
    required this.skillSuiteWorkflow,
    required this.localeCode,
    required this.themeMode,
    required this.selectedIndex,
    required this.isDark,
    required this.coreBridge,
    required this.coreCli,
    required this.coreWorkingDirectory,
    required this.coreWorkspace,
    required this.enableLocalCoreActions,
    required this.isWebRuntime,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.onPageChanged,
  });

  final WorkbenchContracts contracts;
  final P1WorkflowEvidence workflowEvidence;
  final P1WorkflowEvidence workflowV2Evidence;
  final ExternalCapabilityRegistry externalCapabilities;
  final ParserBackendMatrix parserBackends;
  final Map<String, dynamic> campaign6AgentRuntimeStatus;
  final Map<String, dynamic> campaign7ConfigurationStatus;
  final Map<String, dynamic> campaign9DesktopDeliveryStatus;
  final Map<String, dynamic> skillGovernanceReport;
  final Map<String, dynamic> methodologyMap;
  final Map<String, dynamic>? skillSuiteWorkflow;
  final String localeCode;
  final ThemeMode themeMode;
  final int selectedIndex;
  final bool isDark;
  final LocalCoreBridge coreBridge;
  final String coreCli;
  final String coreWorkingDirectory;
  final String coreWorkspace;
  final bool enableLocalCoreActions;
  final bool isWebRuntime;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<String> onLocaleChanged;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _DesktopWindowPreviewShell(
        childBuilder: (windowState, onWindowStateChanged) => _DesktopWorkbench(
          localeCode: localeCode,
          contracts: contracts,
          workflowEvidence: workflowEvidence,
          workflowV2Evidence: workflowV2Evidence,
          externalCapabilities: externalCapabilities,
          parserBackends: parserBackends,
          campaign6AgentRuntimeStatus: campaign6AgentRuntimeStatus,
          campaign7ConfigurationStatus: campaign7ConfigurationStatus,
          campaign9DesktopDeliveryStatus: campaign9DesktopDeliveryStatus,
          skillGovernanceReport: skillGovernanceReport,
          methodologyMap: methodologyMap,
          skillSuiteWorkflow: skillSuiteWorkflow,
          selectedIndex: selectedIndex,
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
    );
  }
}

class _DesktopWindowPreviewShell extends StatefulWidget {
  const _DesktopWindowPreviewShell({required this.childBuilder});

  final Widget Function(
    _DesktopWindowPreviewState windowState,
    ValueChanged<_DesktopWindowPreviewState> onWindowStateChanged,
  ) childBuilder;

  @override
  State<_DesktopWindowPreviewShell> createState() =>
      _DesktopWindowPreviewShellState();
}

class _DesktopWindowPreviewShellState
    extends State<_DesktopWindowPreviewShell> {
  _DesktopWindowPreviewState windowState = _DesktopWindowPreviewState.restored;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final maximized = windowState == _DesktopWindowPreviewState.maximized;
      final viewportWidth = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : _DesktopGrid.initialWindowWidth;
      final viewportHeight = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : _DesktopGrid.initialWindowHeight;
      final width = viewportWidth < _DesktopGrid.minWindowWidth
          ? _DesktopGrid.minWindowWidth
          : viewportWidth;
      final height = viewportHeight < 560 ? 560.0 : viewportHeight;
      final frame = widget.childBuilder(
        windowState,
        (state) => setState(() => windowState = state),
      );
      return Container(
        color: colors.surfaceContainerHighest,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            height: height,
            child: AnimatedContainer(
              key: const Key('desktop-window-preview-frame'),
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              width: width,
              height: height,
              constraints: const BoxConstraints(
                minWidth: _DesktopGrid.minWindowWidth,
                minHeight: 560,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: maximized ? 0 : 0.08),
                    blurRadius: maximized ? 0 : 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: frame,
            ),
          ),
        ),
      );
    });
  }
}

class _CardCopy {
  const _CardCopy(this.title, this.body);

  final String title;
  final String body;
}

class _ProductColumn extends StatelessWidget {
  const _ProductColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final column = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
      if (!constraints.maxHeight.isFinite) {
        return column;
      }
      return Scrollbar(
        child: SingleChildScrollView(
          primary: false,
          child: column,
        ),
      );
    });
  }
}

class _Grid12Cell {
  const _Grid12Cell({
    required this.span,
    required this.child,
  });

  final int span;
  final Widget child;
}

class _Grid12Row extends StatelessWidget {
  const _Grid12Row({
    required this.cells,
  });

  final List<_Grid12Cell> cells;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < _DesktopGrid.rowBreakpoint) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < cells.length; index++) ...[
              if (index > 0) const SizedBox(height: _DesktopGrid.gutter),
              cells[index].child,
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < cells.length; index++) ...[
            if (index > 0) const SizedBox(width: _DesktopGrid.gutter),
            Expanded(flex: cells[index].span, child: cells[index].child),
          ],
        ],
      );
    });
  }
}

class _TopBarSearchField extends StatefulWidget {
  const _TopBarSearchField({
    required this.label,
    required this.onPageChanged,
    this.compact = false,
  });

  final String label;
  final ValueChanged<int> onPageChanged;
  final bool compact;

  @override
  State<_TopBarSearchField> createState() => _TopBarSearchFieldState();
}

class _TopBarSearchFieldState extends State<_TopBarSearchField> {
  bool focused = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state;
    final suggestions = _topBarSearchSuggestions(runtime, zh);
    final borderColor = focused ? colors.primary : colors.outlineVariant;
    final statusText = switch (runtime?.searchStatus) {
      Rc6SearchStatus.loading => zh ? '搜索中' : 'Searching',
      Rc6SearchStatus.success => zh ? '真实结果' : 'Results',
      Rc6SearchStatus.empty => zh ? '无结果' : 'Empty',
      Rc6SearchStatus.error => zh ? '错误' : 'Error',
      _ => zh ? '定位' : 'Open',
    };
    return RawAutocomplete<_TopBarSearchSuggestion>(
      key: const Key('topbar-search-menu'),
      textEditingController: _controller,
      focusNode: _focusNode,
      displayStringForOption: (suggestion) => suggestion.title,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return suggestions.take(8);
        final filtered = suggestions
            .where((item) => item.matches(query))
            .take(8)
            .toList(growable: false);
        return filtered.isEmpty ? [_noMatchSearchSuggestion(zh)] : filtered;
      },
      onSelected: (suggestion) {
        if (!suggestion.isNoMatch) {
          _controller.text = suggestion.title;
        }
        widget.onPageChanged(_pageIndexById(suggestion.pageId));
        setState(() => focused = false);
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: widget.compact ? 340 : 560,
                maxHeight: 360,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final item = options.elementAt(index);
                  return ListTile(
                    key: Key('topbar-search-option-${item.pageId}'),
                    dense: true,
                    leading: Icon(item.icon, size: 18),
                    title: Text(item.title, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${item.category} · ${item.subtitle}',
                        overflow: TextOverflow.ellipsis),
                    onTap: () => onSelected(item),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return Semantics(
          textField: true,
          label: widget.label,
          child: Container(
            key: const Key('topbar-search-field'),
            constraints: const BoxConstraints(minWidth: 120),
            height: 40,
            padding: const EdgeInsets.only(left: 12, right: 6),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: focused ? 1.4 : 1),
            ),
            child: Row(
              children: [
                Icon(Icons.search,
                    size: 17,
                    color: focused ? colors.primary : colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    key: const Key('topbar-real-search-input'),
                    enabled: rc6 != null,
                    onTap: () => setState(() => focused = true),
                    onChanged: (_) => setState(() => focused = true),
                    onSubmitted: (value) {
                      final matched = _bestSearchSuggestion(
                          suggestions, value.trim().toLowerCase());
                      widget.onPageChanged(_pageIndexById(
                          matched?.pageId ?? 'retrieval-verification'));
                    },
                    decoration: InputDecoration(
                      hintText: widget.label,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 13,
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.16,
                        ),
                  ),
                ),
                if (!widget.compact || focused) ...[
                  const SizedBox(width: 6),
                  TextButton(
                    key: const Key('topbar-real-search-submit'),
                    onPressed: runtime?.running == true
                        ? null
                        : () {
                            final matched = _bestSearchSuggestion(suggestions,
                                _controller.text.trim().toLowerCase());
                            widget.onPageChanged(_pageIndexById(
                                matched?.pageId ?? 'retrieval-verification'));
                          },
                    child: Text(statusText),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopBarSearchSuggestion {
  const _TopBarSearchSuggestion({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.pageId,
    required this.icon,
    this.keywords = const [],
    this.isNoMatch = false,
  });

  final String title;
  final String subtitle;
  final String category;
  final String pageId;
  final IconData icon;
  final List<String> keywords;
  final bool isNoMatch;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final haystack = [
      title,
      subtitle,
      category,
      ...keywords,
    ].join(' ').toLowerCase();
    return haystack.contains(normalized);
  }
}

_TopBarSearchSuggestion _noMatchSearchSuggestion(bool zh) {
  return _TopBarSearchSuggestion(
    title: zh ? '无匹配，前往查询控制台' : 'No match, open Query Console',
    subtitle: zh ? '用当前输入查询知识库内容' : 'Use this query against KB content',
    category: zh ? '查询控制台' : 'Query Console',
    pageId: 'retrieval-verification',
    icon: Icons.manage_search_outlined,
    isNoMatch: true,
  );
}

List<_TopBarSearchSuggestion> _topBarSearchSuggestions(
    Rc6RuntimeState? runtime, bool zh) {
  final suggestions = <_TopBarSearchSuggestion>[
    _TopBarSearchSuggestion(
      title: zh ? '文档库导入资料' : 'Import into Document Library',
      subtitle: zh ? '选择文件、解析、OCR、分块' : 'Choose files, parse, OCR, chunk',
      category: zh ? '文档库' : 'Document Library',
      pageId: 'document-library',
      icon: Icons.file_upload_outlined,
      keywords: const ['import', 'parse', 'ocr', 'chunk', '导入', '解析', '分块'],
    ),
    _TopBarSearchSuggestion(
      title: zh ? '文档库' : 'Document Library',
      subtitle: zh ? '查看已导入文件和预览' : 'View imported files and previews',
      category: zh ? '页面' : 'Page',
      pageId: 'document-library',
      icon: Icons.library_books_outlined,
      keywords: const ['document', 'source', 'preview', '文档', '来源', '预览'],
    ),
    _TopBarSearchSuggestion(
      title: zh ? '知识库' : 'Knowledge Base',
      subtitle: zh ? '构建本地知识库和向量索引' : 'Build local KB and vector index',
      category: zh ? '页面' : 'Page',
      pageId: 'knowledge-package-management',
      icon: Icons.storage_outlined,
      keywords: const ['kb', 'knowledge', 'vector', 'manifest', '知识库', '向量'],
    ),
    _TopBarSearchSuggestion(
      title: zh ? '查询控制台' : 'Query Console',
      subtitle: zh ? '检索知识库内容和证据片段' : 'Search KB content and evidence',
      category: zh ? '页面' : 'Page',
      pageId: 'retrieval-verification',
      icon: Icons.manage_search_outlined,
      keywords: const ['search', 'query', 'retrieval', 'evidence', '检索', '查询'],
    ),
    _TopBarSearchSuggestion(
      title: zh ? '文档生成' : 'Document Generation',
      subtitle: zh ? '生成并导出文档' : 'Generate and export documents',
      category: zh ? '页面' : 'Page',
      pageId: 'document-generation',
      icon: Icons.edit_document,
      keywords: const ['generate', 'export', 'markdown', 'docx', 'pdf', '文档生成'],
    ),
    _TopBarSearchSuggestion(
      title: zh ? 'Skill 工厂' : 'Skill Factory',
      subtitle: zh
          ? '从知识库生成 Skill，并绑定给 Agent'
          : 'Generate Skills from KBs and bind them to Agents',
      category: zh ? '页面' : 'Page',
      pageId: 'skill-factory',
      icon: Icons.extension_outlined,
      keywords: const ['skill', 'SKILL.md', '技能', '工厂'],
    ),
    _TopBarSearchSuggestion(
      title: zh ? 'Agent 工作台' : 'Agent Workbench',
      subtitle: zh
          ? '创建 Agent、单 Agent 对话和多 Agent 协作'
          : 'Create Agents, chat, and coordinate multi-agent work',
      category: zh ? '页面' : 'Page',
      pageId: 'agent-factory-runtime',
      icon: Icons.smart_toy_outlined,
      keywords: const ['agent', 'chat', 'a2a', 'discussion', '智能体', '对话'],
    ),
    _TopBarSearchSuggestion(
      title: zh ? '产物中心' : 'Artifact Center',
      subtitle: zh
          ? '查看生成文档、知识库、Skill、Agent 和对话产物'
          : 'Browse generated documents, KB, Skill, Agent, and dialogue artifacts',
      category: zh ? '治理' : 'Governance',
      pageId: 'artifact-center',
      icon: Icons.folder_copy_outlined,
      keywords: const ['artifact', 'output', '产物', '导出', '清单'],
    ),
  ];
  if (runtime != null) {
    for (final name in runtime.sourceNames.take(8)) {
      suggestions.add(_TopBarSearchSuggestion(
        title: name,
        subtitle: zh ? '来源文档' : 'Source document',
        category: zh ? '来源文档' : 'Source Document',
        pageId: 'document-library',
        icon: Icons.article_outlined,
        keywords: [name, _displayNameForPath(name), 'document', 'source', '文档'],
      ));
    }
    for (final kb in runtime.knowledgeBases.take(8)) {
      suggestions.add(_TopBarSearchSuggestion(
        title: kb.name,
        subtitle: zh
            ? '${kb.type} · ${kb.chunkCount} chunks · ${kb.sourceCount} 来源'
            : '${kb.type} · ${kb.chunkCount} chunks · ${kb.sourceCount} sources',
        category: zh ? '知识库' : 'Knowledge Base',
        pageId: 'knowledge-package-management',
        icon: Icons.account_tree_outlined,
        keywords: [kb.id, kb.operation, kb.status, kb.manifestPath],
      ));
    }
    if (runtime.hasKnowledgeBase) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? '真实输入知识库' : 'Real input Knowledge Base',
        subtitle: '${runtime.chunkCount} chunks',
        category: zh ? '知识库' : 'Knowledge Base',
        pageId: 'knowledge-package-management',
        icon: Icons.account_tree_outlined,
        keywords: [runtime.kbManifestPath, runtime.qualityReportPath],
      ));
    }
    for (final result in runtime.searchResults.take(8)) {
      suggestions.add(_TopBarSearchSuggestion(
        title: result.title,
        subtitle: result.kbName.isNotEmpty
            ? '${result.kbName} · ${result.citation}'
            : result.citation,
        category: zh ? '证据片段' : 'Evidence',
        pageId: 'retrieval-verification',
        icon: Icons.fact_check_outlined,
        keywords: [result.excerpt, result.kbId, result.score],
      ));
    }
    if (runtime.hasMarkdown) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? '读书笔记 Markdown' : 'Reading notes Markdown',
        subtitle: _displayNameForPath(runtime.generatedMarkdownPath),
        category: zh ? '生成文档' : 'Generated Document',
        pageId: 'document-generation',
        icon: Icons.notes_outlined,
        keywords: [runtime.generatedMarkdownPath, runtime.readingNotesPath],
      ));
    }
    if (runtime.hasExportedDocument) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? '已导出文档' : 'Exported document',
        subtitle: _displayNameForPath(runtime.exportedDocumentPath),
        category: zh ? '生成文档' : 'Generated Document',
        pageId: 'document-generation',
        icon: Icons.file_download_done_outlined,
        keywords: [runtime.exportedDocumentPath, runtime.exportManifestPath],
      ));
    }
    if (runtime.hasSkill) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? '已生成 Skill' : 'Generated Skill',
        subtitle: _displayNameForPath(runtime.skillPath),
        category: 'Skill',
        pageId: 'skill-factory',
        icon: Icons.extension_outlined,
        keywords: [
          runtime.skillPath,
          'SKILL.md',
          'knowledge_qa_skill',
          'localized_writing_skill'
        ],
      ));
    }
    if (runtime.hasAgent) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? '已生成 Agent' : 'Generated Agent',
        subtitle: _displayNameForPath(runtime.agentPath),
        category: 'Agent',
        pageId: 'agent-factory-runtime',
        icon: Icons.smart_toy_outlined,
        keywords: [
          runtime.agentPath,
          'agent_generation_manifest',
          'W_A',
          'W_M'
        ],
      ));
    }
    if (runtime.hasAgentDialogue) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? 'Agent 对话记录' : 'Agent dialogue',
        subtitle: _displayNameForPath(runtime.agentDialoguePath),
        category: 'Agent',
        pageId: 'agent-factory-runtime',
        icon: Icons.chat_bubble_outline,
        keywords: [runtime.agentDialoguePath, runtime.agentDialogueHistoryPath],
      ));
    }
    if (runtime.hasAgentDialogueExport) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? 'Agent 对话导出' : 'Agent dialogue export',
        subtitle: _displayNameForPath(runtime.agentDialogueExportPath),
        category: 'Agent',
        pageId: 'agent-factory-runtime',
        icon: Icons.file_download_done_outlined,
        keywords: [
          runtime.agentDialogueExportPath,
          'agent_dialogue_export',
          'dialogue export',
          '对话导出'
        ],
      ));
    }
    if (runtime.hasMultiAgentDiscussion) {
      suggestions.add(_TopBarSearchSuggestion(
        title: zh ? '多 Agent 联合讨论' : 'Multi-agent discussion',
        subtitle: _displayNameForPath(runtime.multiAgentDiscussionPath),
        category: 'Agent',
        pageId: 'agent-factory-runtime',
        icon: Icons.groups_2_outlined,
        keywords: [runtime.multiAgentDiscussionPath, 'A2A', 'discussion'],
      ));
    }
  }
  return suggestions;
}

_TopBarSearchSuggestion? _bestSearchSuggestion(
    List<_TopBarSearchSuggestion> suggestions, String query) {
  if (suggestions.isEmpty) return null;
  if (query.isEmpty) return suggestions.first;
  for (final suggestion in suggestions) {
    if (suggestion.title.toLowerCase().contains(query)) {
      return suggestion;
    }
  }
  for (final suggestion in suggestions) {
    if (suggestion.matches(query)) {
      return suggestion;
    }
  }
  return null;
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

class _TopBarLanguageToggle extends StatelessWidget {
  const _TopBarLanguageToggle({
    required this.localeCode,
    required this.onLocaleChanged,
  });

  final String localeCode;
  final ValueChanged<String> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('topbar-language-toggle'),
      height: 40,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TopBarLanguageButton(
            label: '中',
            selected: localeCode == 'zh-CN',
            onTap: () => onLocaleChanged('zh-CN'),
          ),
          _TopBarLanguageButton(
            label: 'EN',
            selected: localeCode == 'en-US',
            onTap: () => onLocaleChanged('en-US'),
          ),
        ],
      ),
    );
  }
}

class _EqualHeightRow extends StatelessWidget {
  const _EqualHeightRow({
    required this.height,
    required this.children,
    this.flexes,
  });

  final double height;
  final List<Widget> children;
  final List<int>? flexes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < _DesktopGrid.rowBreakpoint) {
        return Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(height: _DesktopGrid.gutter),
              SizedBox(height: height, child: children[index]),
            ],
          ],
        );
      }
      return SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(width: _DesktopGrid.gutter),
              Expanded(
                flex: flexes == null ? 1 : flexes![index],
                child: children[index],
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _EqualActionRow extends StatelessWidget {
  const _EqualActionRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(height: _DesktopGrid.gutter),
          children[index],
        ],
      ],
    );
  }
}

class _EqualFieldGrid extends StatelessWidget {
  const _EqualFieldGrid({required this.children, this.columns = 2});

  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: _DesktopGrid.gutter,
        mainAxisSpacing: _DesktopGrid.gutter,
        mainAxisExtent: 94,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}

class _FillPanelColumn extends StatelessWidget {
  const _FillPanelColumn({
    required this.top,
    required this.bottom,
  });

  final Widget top;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    final filled = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: top),
        const SizedBox(height: _DesktopGrid.gutter),
        bottom,
      ],
    );
    return LayoutBuilder(builder: (context, constraints) {
      if (!constraints.maxHeight.isFinite) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [top, const SizedBox(height: _DesktopGrid.gutter), bottom],
        );
      }
      return SizedBox(
        height: constraints.maxHeight,
        child: filled,
      );
    });
  }
}

class _LocalScrollBox extends StatelessWidget {
  const _LocalScrollBox({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final box = Scrollbar(
      thumbVisibility: false,
      child: SingleChildScrollView(
        primary: false,
        child: _ScrollSafePadding(child: child),
      ),
    );
    return box;
  }
}

class _ScrollSafePadding extends StatelessWidget {
  const _ScrollSafePadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _DesktopGrid.footerSafeArea),
      child: child,
    );
  }
}

class _BoundedScrollRegion extends StatelessWidget {
  const _BoundedScrollRegion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_DesktopGrid.panelRadius),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: child,
    );
  }
}

class _TopBarLanguageButton extends StatelessWidget {
  const _TopBarLanguageButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: selected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

class _TopBarChip extends StatelessWidget {
  const _TopBarChip({
    required this.icon,
    required this.label,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 104 : 86),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17),
            const SizedBox(width: 7),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPageOverview extends StatefulWidget {
  const _ProductPageOverview({
    required this.localeCode,
    required this.page,
    required this.workspace,
    required this.campaign6AgentRuntimeStatus,
    required this.campaign7ConfigurationStatus,
    required this.campaign9DesktopDeliveryStatus,
    required this.isWebRuntime,
    required this.diagnostics,
    required this.onPageChanged,
  });

  final String localeCode;
  final WorkbenchPage page;
  final String workspace;
  final Map<String, dynamic> campaign6AgentRuntimeStatus;
  final Map<String, dynamic> campaign7ConfigurationStatus;
  final Map<String, dynamic> campaign9DesktopDeliveryStatus;
  final bool isWebRuntime;
  final Widget diagnostics;
  final ValueChanged<int> onPageChanged;

  @override
  State<_ProductPageOverview> createState() => _ProductPageOverviewState();
}

class _ProductPageOverviewState extends State<_ProductPageOverview> {
  late int selectedTab = _defaultTabFor(widget.page.id);

  static int _defaultTabFor(String pageId) =>
      pageId == 'knowledge-package-management' ? 0 : 0;

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
      'knowledge-package-management': 4,
      'document-generation': 3,
      'agent-factory-runtime': 5,
      'reports-audit': 3,
      'workspace': 6,
    };
    final maxTab = (tabCounts[page] ?? 1) - 1;
    if (selectedTab > maxTab) selectedTab = 0;
    final rc6 = _Rc6RuntimeScope.of(context);
    return _ProductWorkspaceFrame(
      key: Key('dense-page-workbench-${widget.page.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (page) {
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
                selectedTab: selectedTab,
                onTabSelected: (index) => setState(() => selectedTab = index),
                isWebRuntime: widget.isWebRuntime,
                campaign7ConfigurationStatus:
                    widget.campaign7ConfigurationStatus,
                campaign9DesktopDeliveryStatus:
                    widget.campaign9DesktopDeliveryStatus,
              ),
          },
        ],
      ),
    );
  }
}

class _ProductWorkspaceFrame extends StatelessWidget {
  const _ProductWorkspaceFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.surface),
      child: child,
    );
  }
}

List<ContractAction> _rc5RuntimeActionsForPage(String pageId) {
  switch (pageId) {
    case 'import-parsing':
      return const <ContractAction>[
        ContractAction(
          id: 'document_preflight',
          label: 'Document Preflight',
          command: 'preflight-documents --input <input> --output <output>',
          requires: <String>['input', 'workspace'],
          pageId: 'import_parsing',
          status: 'ready',
          commandKind: 'core_cli',
          blockedReason: '',
          desktopEnabled: true,
          webEnabled: false,
          desktopBlockedReason: '',
          webBlockedReason: 'web_local_cli_unsupported',
          reportIds: <String>['document_preflight_report'],
          artifactIds: <String>['document_inventory'],
          errorCodes: <String>['document_preflight_failed'],
        ),
        ContractAction(
          id: 'batch_import_documents',
          label: 'Batch Import Documents',
          command: 'batch-import-documents --input <input> --output <output>',
          requires: <String>['input', 'workspace'],
          pageId: 'import_parsing',
          status: 'ready',
          commandKind: 'core_cli',
          blockedReason: '',
          desktopEnabled: true,
          webEnabled: false,
          desktopBlockedReason: '',
          webBlockedReason: 'web_local_cli_unsupported',
          reportIds: <String>['batch_import_report'],
          artifactIds: <String>['source_manifest'],
          errorCodes: <String>['batch_import_failed'],
        ),
      ];
    case 'document-library':
      return const <ContractAction>[
        ContractAction(
          id: 'document_preflight',
          label: 'Document Preflight',
          command: 'preflight-documents --input <input> --output <output>',
          requires: <String>['input', 'workspace'],
          pageId: 'document_library',
          status: 'ready',
          commandKind: 'core_cli',
          blockedReason: '',
          desktopEnabled: true,
          webEnabled: false,
          desktopBlockedReason: '',
          webBlockedReason: 'web_local_cli_unsupported',
          reportIds: <String>['document_preflight_report'],
          artifactIds: <String>['document_inventory'],
          errorCodes: <String>['document_preflight_failed'],
        ),
        ContractAction(
          id: 'batch_import_documents',
          label: 'Batch Import Documents',
          command: 'batch-import-documents --input <input> --output <output>',
          requires: <String>['input', 'workspace'],
          pageId: 'document_library',
          status: 'ready',
          commandKind: 'core_cli',
          blockedReason: '',
          desktopEnabled: true,
          webEnabled: false,
          desktopBlockedReason: '',
          webBlockedReason: 'web_local_cli_unsupported',
          reportIds: <String>['batch_import_report'],
          artifactIds: <String>['source_manifest'],
          errorCodes: <String>['batch_import_failed'],
        ),
      ];
    case 'knowledge-package-management':
      return const <ContractAction>[
        ContractAction(
          id: 'knowledge_base_build',
          label: 'Build Knowledge Base',
          command:
              'build-knowledge-base --document-understanding <source> --output <output>',
          requires: <String>['document_understanding', 'workspace'],
          pageId: 'knowledge_package_management',
          status: 'ready',
          commandKind: 'core_cli',
          blockedReason: '',
          desktopEnabled: true,
          webEnabled: false,
          desktopBlockedReason: '',
          webBlockedReason: 'web_local_cli_unsupported',
          reportIds: <String>['knowledge_base_build_report'],
          artifactIds: <String>['kb_manifest'],
          errorCodes: <String>['knowledge_base_build_failed'],
        ),
        ContractAction(
          id: 'knowledge_package_build',
          label: 'Build Knowledge Package',
          command:
              'build-knowledge-package --knowledge-base <package> --output <output>',
          requires: <String>['knowledge_base', 'workspace'],
          pageId: 'knowledge_package_management',
          status: 'ready',
          commandKind: 'core_cli',
          blockedReason: '',
          desktopEnabled: true,
          webEnabled: false,
          desktopBlockedReason: '',
          webBlockedReason: 'web_local_cli_unsupported',
          reportIds: <String>['knowledge_package_build_report'],
          artifactIds: <String>['portable_kb_package'],
          errorCodes: <String>['knowledge_package_build_failed'],
        ),
      ];
    case 'retrieval-verification':
      return const <ContractAction>[
        ContractAction(
          id: 'rag_query',
          label: 'Run RAG Query',
          command:
              'kb-query --package <package> --query <query> --output <output>',
          requires: <String>['package', 'query', 'workspace'],
          pageId: 'retrieval_verification',
          status: 'ready',
          commandKind: 'core_cli',
          blockedReason: '',
          desktopEnabled: true,
          webEnabled: false,
          desktopBlockedReason: '',
          webBlockedReason: 'web_local_cli_unsupported',
          reportIds: <String>['rag_query_report'],
          artifactIds: <String>['citation_trace'],
          errorCodes: <String>['rag_query_failed'],
        ),
        ContractAction(
          id: 'evidence_selection',
          label: 'Select Evidence',
          command:
              'select-evidence --package <package> --query <query> --output <output>',
          requires: <String>['package', 'query', 'workspace'],
          pageId: 'retrieval_verification',
          status: 'ready',
          commandKind: 'core_cli',
          blockedReason: '',
          desktopEnabled: true,
          webEnabled: false,
          desktopBlockedReason: '',
          webBlockedReason: 'web_local_cli_unsupported',
          reportIds: <String>['evidence_selection_report'],
          artifactIds: <String>['evidence_trace'],
          errorCodes: <String>['evidence_selection_failed'],
        ),
      ];
    case 'document-generation':
      return const <ContractAction>[
        ContractAction(
          id: 'generate_markdown',
          label: 'Generate Markdown',
          command: 'generate-md --package <package> --output <output>',
          requires: <String>['package', 'workspace'],
          pageId: 'document_generation',
          status: 'ready',
          commandKind: 'core_cli',
          blockedReason: '',
          desktopEnabled: true,
          webEnabled: false,
          desktopBlockedReason: '',
          webBlockedReason: 'web_local_cli_unsupported',
          reportIds: <String>['markdown_generation_report'],
          artifactIds: <String>['markdown_document'],
          errorCodes: <String>['document_generation_failed'],
        ),
        ContractAction(
          id: 'generate_manual_user_guide',
          label: 'Generate Document Bundle',
          command: 'generate-documents --package <package> --output <output>',
          requires: <String>['package', 'workspace'],
          pageId: 'document_generation',
          status: 'ready',
          commandKind: 'core_cli',
          blockedReason: '',
          desktopEnabled: true,
          webEnabled: false,
          desktopBlockedReason: '',
          webBlockedReason: 'web_local_cli_unsupported',
          reportIds: <String>['document_bundle_report'],
          artifactIds: <String>['generated_documents'],
          errorCodes: <String>['document_bundle_failed'],
        ),
      ];
    case 'skill-factory':
      return const <ContractAction>[
        ContractAction(
          id: 'package_to_skill',
          label: 'Generate Skill Package',
          command: 'generate-skill --package <package> --output <output>',
          requires: <String>['package', 'workspace'],
          pageId: 'skill_factory',
          status: 'ready',
          commandKind: 'core_cli',
          blockedReason: '',
          desktopEnabled: true,
          webEnabled: false,
          desktopBlockedReason: '',
          webBlockedReason: 'web_local_cli_unsupported',
          reportIds: <String>['skill_generation_report'],
          artifactIds: <String>['skill_package'],
          errorCodes: <String>['skill_generation_failed'],
        ),
        ContractAction(
          id: 'skill_governance_report',
          label: 'Skill Governance Report',
          command: 'skill-governance-report --skill <skill> --output <output>',
          requires: <String>['skill', 'workspace'],
          pageId: 'skill_factory',
          status: 'ready',
          commandKind: 'core_cli',
          blockedReason: '',
          desktopEnabled: true,
          webEnabled: false,
          desktopBlockedReason: '',
          webBlockedReason: 'web_local_cli_unsupported',
          reportIds: <String>['skill_governance_report'],
          artifactIds: <String>['governance_report'],
          errorCodes: <String>['skill_governance_failed'],
        ),
      ];
    case 'agent-factory-runtime':
      return const <ContractAction>[
        ContractAction(
          id: 'standalone_agent_generation',
          label: 'Generate Standalone Agent',
          command: 'generate-agent --mode standalone --output <output>',
          requires: <String>['workspace'],
          pageId: 'agent_factory_runtime',
          status: 'ready',
          commandKind: 'core_cli',
          blockedReason: '',
          desktopEnabled: true,
          webEnabled: false,
          desktopBlockedReason: '',
          webBlockedReason: 'web_local_cli_unsupported',
          reportIds: <String>['agent_generation_report'],
          artifactIds: <String>['agent_package'],
          errorCodes: <String>['agent_generation_failed'],
        ),
        ContractAction(
          id: 'kb_bound_agent_generation',
          label: 'Generate KB-bound Agent',
          command:
              'generate-agent --mode kb_bound --package <package> --skill <skill> --output <output>',
          requires: <String>['package', 'skill', 'workspace'],
          pageId: 'agent_factory_runtime',
          status: 'ready',
          commandKind: 'core_cli',
          blockedReason: '',
          desktopEnabled: true,
          webEnabled: false,
          desktopBlockedReason: '',
          webBlockedReason: 'web_local_cli_unsupported',
          reportIds: <String>['kb_bound_agent_generation_report'],
          artifactIds: <String>['agent_package'],
          errorCodes: <String>['agent_generation_failed'],
        ),
      ];
    case 'workspace':
      return const <ContractAction>[
        ContractAction(
          id: 'provider_config_validate',
          label: 'Validate Provider Config',
          command:
              'provider-config-validate --config <config> --output <output>',
          requires: <String>['config_profile', 'workspace'],
          pageId: 'workspace',
          status: 'ready',
          commandKind: 'core_cli',
          blockedReason: '',
          desktopEnabled: true,
          webEnabled: false,
          desktopBlockedReason: '',
          webBlockedReason: 'web_local_cli_unsupported',
          reportIds: <String>['provider_config_validation_report'],
          artifactIds: <String>['masked_provider_profile'],
          errorCodes: <String>['provider_config_invalid'],
        ),
        ContractAction(
          id: 'provider_readiness',
          label: 'Provider Readiness',
          command:
              'provider-readiness --workspace <workspace> --output <output>',
          requires: <String>['workspace'],
          pageId: 'workspace',
          status: 'ready',
          commandKind: 'core_cli',
          blockedReason: '',
          desktopEnabled: true,
          webEnabled: false,
          desktopBlockedReason: '',
          webBlockedReason: 'web_local_cli_unsupported',
          reportIds: <String>['provider_readiness_report'],
          artifactIds: <String>['provider_status'],
          errorCodes: <String>['provider_readiness_failed'],
        ),
      ];
  }
  return const <ContractAction>[];
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({
    required this.icon,
    required this.title,
    required this.description,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconBox = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: colors.onPrimary, size: 23),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                )),
      ],
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 560) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              iconBox,
              const SizedBox(width: _DesktopGrid.gutter),
              Expanded(child: copy),
            ]),
            if (trailing != null) ...[
              const SizedBox(height: _DesktopGrid.gutter),
              trailing!,
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconBox,
          const SizedBox(width: _DesktopGrid.gutter),
          Expanded(child: copy),
          if (trailing != null) ...[
            const SizedBox(width: _DesktopGrid.gutter),
            trailing!,
          ],
        ],
      );
    });
  }
}

class _PageTabs extends StatelessWidget {
  const _PageTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.keyPrefix = 'page-tab',
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 620;
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var index = 0; index < tabs.length; index++)
            _PageTabButton(
              key: Key('$keyPrefix-$index'),
              label: tabs[index],
              selected: selectedIndex == index,
              width: compact ? (constraints.maxWidth - 6) / 2 : null,
              onTap: () => onSelected(index),
            ),
        ],
      );
    });
  }
}

class _PageTabButton extends StatelessWidget {
  const _PageTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.width,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.onPrimary : colors.onSurface;
    final background =
        selected ? colors.primary : colors.surfaceContainerLowest;
    return SizedBox(
      width: width,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: selected ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize:
                    width == null ? MainAxisSize.min : MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    Icon(Icons.check, size: 16, color: foreground),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: foreground,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                            height: 1.05,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductPanel extends StatelessWidget {
  const _ProductPanel({
    required this.title,
    required this.children,
    this.icon,
    this.subtitle,
    this.keyName,
    this.accent = false,
    this.gap = false,
    this.minHeight,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;
  final String? subtitle;
  final String? keyName;
  final bool accent;
  final bool gap;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final gapColor = Colors.amber.shade700;
    return Container(
      key: keyName == null ? null : Key(keyName!),
      width: double.infinity,
      constraints:
          BoxConstraints(minHeight: minHeight ?? _DesktopGrid.panelMinHeight),
      padding: const EdgeInsets.all(_DesktopGrid.panelPadding),
      decoration: BoxDecoration(
        color: gap
            ? gapColor.withValues(alpha: 0.08)
            : accent
                ? colors.primary.withValues(alpha: 0.05)
                : colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_DesktopGrid.panelRadius),
        border: Border.all(
          color: gap
              ? gapColor.withValues(alpha: 0.5)
              : accent
                  ? colors.primary.withValues(alpha: 0.24)
                  : colors.outlineVariant,
        ),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final header = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: gap ? gapColor : colors.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.12,
                              )),
                ),
                if (gap) ...[
                  const SizedBox(width: 8),
                  const _CapabilityStatusMarker(compact: true),
                ],
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        height: 1.16,
                      )),
            ],
          ],
        );
        final body = _ScrollSafePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        );
        if (!constraints.maxHeight.isFinite) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              if (children.isNotEmpty)
                const SizedBox(height: _DesktopGrid.gutter),
              ...children,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            if (children.isNotEmpty) ...[
              const SizedBox(height: _DesktopGrid.gutter),
              Expanded(
                child: Scrollbar(
                  thumbVisibility: false,
                  child: SingleChildScrollView(
                    primary: false,
                    child: body,
                  ),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _FillProductPanel extends StatelessWidget {
  const _FillProductPanel({
    required this.title,
    required this.child,
    this.icon,
    this.keyName,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final String? keyName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        key: keyName == null ? null : Key(keyName!),
        width: double.infinity,
        height: constraints.maxHeight.isFinite ? double.infinity : null,
        padding: const EdgeInsets.all(_DesktopGrid.panelPadding),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(_DesktopGrid.panelRadius),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.12,
                              )),
                ),
              ],
            ),
            const SizedBox(height: _DesktopGrid.gutter),
            if (constraints.maxHeight.isFinite)
              Expanded(child: child)
            else
              child,
          ],
        ),
      );
    });
  }
}

class _ProductTable extends StatelessWidget {
  const _ProductTable({
    required this.columns,
    required this.rows,
  });

  final List<String> columns;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 360) {
        final narrowTable = Column(
          children: [
            for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
              if (rowIndex > 0) const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < columns.length; index++) ...[
                      if (index > 0) const SizedBox(height: 5),
                      Text(columns[index],
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w900,
                                  )),
                      const SizedBox(height: 2),
                      _CapabilityTableCell(
                        value: index < rows[rowIndex].length
                            ? rows[rowIndex][index]
                            : '',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
        if (!constraints.maxHeight.isFinite) {
          return narrowTable;
        }
        return Scrollbar(
          thumbVisibility: false,
          child: SingleChildScrollView(
            primary: false,
            child: _ScrollSafePadding(child: narrowTable),
          ),
        );
      }
      final minCellWidth = columns.length >= 6 ? 136.0 : 116.0;
      final tableWidth =
          (columns.length * minCellWidth).clamp(constraints.maxWidth, 1200.0);
      final borderColor = colors.outlineVariant.withValues(alpha: 0.7);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: tableWidth.toDouble()),
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              for (var index = 0; index < columns.length; index++)
                index: const FlexColumnWidth(),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.38),
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                children: [
                  for (final column in columns)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      child: Text(
                        column,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: 13,
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                            ),
                      ),
                    ),
                ],
              ),
              for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
                TableRow(
                  decoration: BoxDecoration(
                    color: rowIndex.isEven
                        ? colors.surface
                        : colors.surfaceContainerHighest
                            .withValues(alpha: 0.18),
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  children: [
                    for (var index = 0; index < columns.length; index++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        child: DefaultTextStyle.merge(
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 1.22,
                                  ),
                          child: _CapabilityTableCell(
                            value: index < rows[rowIndex].length
                                ? rows[rowIndex][index]
                                : '',
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final labelText = Text(label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 12.5,
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              height: 1.16,
            ));
    final valueText = Text(value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.18,
            ));
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            labelText,
            const SizedBox(height: 5),
            valueText,
          ],
        );
      }),
    );
  }
}

class _SectionCaption extends StatelessWidget {
  const _SectionCaption(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.16,
            ),
      ),
    );
  }
}

class _CapabilityTableCell extends StatelessWidget {
  const _CapabilityTableCell({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final statusKind = _capabilityStatusKind(value);
    if (statusKind != _CapabilityStatusKind.available) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _CapabilityStatusMarker(label: value, kind: statusKind),
      );
    }
    return Tooltip(
      message: value,
      waitDuration: const Duration(milliseconds: 500),
      child: Text(
        value,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
      ),
    );
  }
}

enum _CapabilityStatusKind { available, displayOnly, disabledBoundary }

class _CapabilityStatusMarker extends StatelessWidget {
  const _CapabilityStatusMarker({
    this.label,
    this.compact = false,
    this.kind,
  });

  final String? label;
  final bool compact;
  final _CapabilityStatusKind? kind;

  @override
  Widget build(BuildContext context) {
    final resolvedKind = kind ?? _capabilityStatusKind(label ?? '');
    final colors = Theme.of(context).colorScheme;
    final color = switch (resolvedKind) {
      _CapabilityStatusKind.displayOnly => colors.onSurfaceVariant,
      _CapabilityStatusKind.disabledBoundary => Colors.amber.shade700,
      _CapabilityStatusKind.available => Colors.green.shade700,
    };
    final icon = switch (resolvedKind) {
      _CapabilityStatusKind.displayOnly => Icons.visibility_outlined,
      _CapabilityStatusKind.disabledBoundary => Icons.warning_amber_outlined,
      _CapabilityStatusKind.available => Icons.check_circle_outline,
    };
    final text = _capabilityStatusLabel(
      label,
      Localizations.localeOf(context).languageCode == 'zh',
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: compact ? 12.5 : 13,
                    color: color,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

_CapabilityStatusKind _capabilityStatusKind(String value) {
  final lower = value.toLowerCase();
  if (lower.contains('enabled_real')) {
    return _CapabilityStatusKind.available;
  }
  if (lower.contains('display_only') ||
      lower.contains('preview only') ||
      lower.contains('read-only') ||
      value.contains('只读')) {
    return _CapabilityStatusKind.displayOnly;
  }
  if (lower.contains('owner_authorization_required') ||
      lower.contains('not_available_in_product_flow')) {
    return _CapabilityStatusKind.disabledBoundary;
  }
  if (lower.contains('disabled_boundary') ||
      lower.contains('omitted') ||
      lower.contains('campaign 6') ||
      lower.contains('provider runtime gate') ||
      lower.contains('external source verification gate') ||
      lower.contains('not connected') ||
      lower.contains('not authorized') ||
      lower.contains('preview only') ||
      lower.contains('read-only') ||
      lower.contains('reserved') ||
      value.contains('未接入') ||
      value.contains('预留') ||
      value.contains('只读') ||
      value.contains('不实现') ||
      value.contains('未授权') ||
      value.contains('边界') ||
      value.contains('禁用')) {
    return _CapabilityStatusKind.disabledBoundary;
  }
  return _CapabilityStatusKind.available;
}

String _capabilityStatusLabel(String? value, bool zh) {
  if (value == null) {
    return zh ? '需要配置' : 'Needs configuration';
  }
  final lower = value.toLowerCase();
  if (lower.contains('enabled_real')) {
    return zh ? '可用' : 'Available';
  }
  if (lower.contains('display_only') ||
      lower.contains('preview only') ||
      lower.contains('read-only') ||
      value.contains('只读')) {
    return zh ? '仅查看' : 'View only';
  }
  if (lower.contains('omitted') ||
      lower.contains('campaign 6') ||
      lower.contains('not_available_in_product_flow') ||
      value.contains('后续') ||
      value.contains('不实现')) {
    return zh ? '不在当前产品流程中' : 'Outside current product flow';
  }
  if (lower.contains('owner_authorization_required')) {
    return zh ? '需要 Owner 授权' : 'Owner authorization required';
  }
  if (lower.contains('disabled_boundary') ||
      lower.contains('provider runtime gate') ||
      lower.contains('external source verification gate') ||
      lower.contains('not connected') ||
      value.contains('未接入') ||
      value.contains('边界') ||
      value.contains('禁用')) {
    return zh ? '需要配置或授权' : 'Configuration or authorization required';
  }
  return value;
}

String _settingsHealthLabel(Object? value, bool zh) {
  final text = value?.toString() ?? '';
  if (text.isEmpty) return zh ? '需要配置' : 'Needs configuration';
  final lower = text.toLowerCase();
  if (lower == 'available' ||
      lower == 'pass' ||
      lower == 'configured' ||
      lower == 'connected') {
    return zh ? '可用' : 'Available';
  }
  if (lower.contains('missing') ||
      lower.contains('not connected') ||
      lower.contains('not authorized')) {
    return zh ? '需要配置或测试' : 'Needs configuration or test';
  }
  return _capabilityStatusLabel(text, zh);
}

class _StatePill extends StatelessWidget {
  const _StatePill({
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  )),
        ],
      ),
    );
  }
}

class _DisplayAction extends StatelessWidget {
  const _DisplayAction({
    required this.label,
    this.icon = Icons.visibility_outlined,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

Future<void> _copyArtifactPath(
  BuildContext context, {
  required String path,
  required String successMessage,
}) async {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return;
  await Clipboard.setData(ClipboardData(text: trimmed));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(successMessage)),
  );
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

class _PrimaryProductAction extends StatelessWidget {
  const _PrimaryProductAction({
    required this.label,
    required this.onPressed,
    this.icon = Icons.play_arrow_outlined,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
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
                      color: colors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(item.icon, size: 24, color: colors.primary),
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
                            color: colors.onSurfaceVariant,
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
    final color = switch (tone) {
      _StatusTone.success => Colors.green.shade700,
      _StatusTone.warning => Colors.orange.shade700,
      _StatusTone.danger => colors.error,
      _StatusTone.neutral => colors.primary,
    };
    return Container(
      key: const Key('runtime-feedback-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.34)),
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
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_DesktopGrid.panelRadius),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 21, color: colors.primary),
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
                          color: colors.onSurfaceVariant,
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
    final colors = Theme.of(context).colorScheme;
    final color = switch (tone) {
      _StatusTone.success => Colors.green.shade700,
      _StatusTone.warning => Colors.orange.shade700,
      _StatusTone.danger => colors.error,
      _StatusTone.neutral => colors.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
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
    builder: (context) => AlertDialog(
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
          label: Text(MaterialLocalizations.of(context).deleteButtonTooltip),
        ),
      ],
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
    'requires_parser' => zh ? '待解析器' : 'Parser required',
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

class _WorkbenchCard extends StatelessWidget {
  const _WorkbenchCard(
      {required this.title, required this.body, required this.localeCode});

  final String title;
  final String body;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Expanded(
              child: Text(body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Text(
                  localeCode == 'zh-CN' ? '只读边界证据' : 'Read-only evidence',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
