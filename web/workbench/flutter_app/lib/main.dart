import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, rootBundle;

import 'core_bridge/local_core_bridge.dart';
import 'contracts/workbench_contracts.dart';
import 'rc6_runtime/rc6_runtime_controller.dart';

part 'app/product_top_bar.dart';
part 'app/desktop_status_bar.dart';
part 'app/workbench_sidebar.dart';
part 'app/workbench_shell.dart';
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
      'artifact-center',
      'Artifact Center',
      '产物中心',
      'Browse generated documents, knowledge artifacts, Skills, Agents, dialogue records, and A2A outputs from real workspace state.',
      '从真实工作区状态浏览生成文档、知识库产物、Skill、Agent、对话记录和 A2A 输出。',
      memberPageIds: ['artifact-management']),
  WorkbenchPage(
      'reports-audit',
      'Governance & Audit',
      '治理与审计',
      'Review quality, retrieval, OCR, safety, governance reports, issues, and repair suggestions.',
      '查看质量、检索、OCR、安全和治理报告、问题与修复建议。',
      memberPageIds: [
        'reports-audit',
        'error-repair-center',
        'governance',
        'memory-center',
      ]),
  WorkbenchPage(
      'workspace',
      'Settings',
      '设置',
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
              .loadFromAsset(
                  'assets/external/provider_capability_status.json')
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
    final isDark = widget.isDark;
    final windowState = widget.windowState;
    final onWindowStateChanged = widget.onWindowStateChanged;
    final onThemeChanged = widget.onThemeChanged;
    final onLocaleChanged = widget.onLocaleChanged;
    final onPageChanged = widget.onPageChanged;
    final isDashboard = page.id == 'dashboard';
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
                      providerCapabilityStatus: providerCapabilityStatus,
                      campaign6AgentRuntimeStatus: campaign6AgentRuntimeStatus,
                      isWebRuntime: isWebRuntime,
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
      'agent-factory-runtime': 4,
      'reports-audit': 3,
      'workspace': 5,
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
                providerCapabilityStatus: widget.providerCapabilityStatus,
                selectedTab: selectedTab,
                onTabSelected: (index) => setState(() => selectedTab = index),
                isWebRuntime: widget.isWebRuntime,
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
      _StatusTone.warning => colors.onSurfaceVariant,
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
      _StatusTone.warning => colors.onSurfaceVariant,
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
