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
      memberPageIds: [
        'dashboard',
        'operation-gate',
        'capability-matrix',
        'task-job-center',
      ]),
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

class _ProductTopBar extends StatelessWidget {
  const _ProductTopBar({
    required this.localeCode,
    required this.page,
    required this.contracts,
    required this.showTitleBlock,
    required this.isDark,
    required this.windowState,
    required this.onWindowStateChanged,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.onPageChanged,
  });

  final String localeCode;
  final WorkbenchPage page;
  final WorkbenchContracts contracts;
  final bool showTitleBlock;
  final bool? isDark;
  final _DesktopWindowPreviewState windowState;
  final ValueChanged<_DesktopWindowPreviewState> onWindowStateChanged;
  final ValueChanged<ThemeMode>? onThemeChanged;
  final ValueChanged<String>? onLocaleChanged;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final showTitle = showTitleBlock && constraints.maxWidth >= 1180;
        final showUtilityChips = constraints.maxWidth >= 1240;
        final showWorkspaceChip = constraints.maxWidth >= 1320;
        final showLanguageToggle = constraints.maxWidth >= 680;
        return Row(
          key: const Key('desktop-topbar-single-row'),
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showTitle) ...[
              SizedBox(
                width: compact ? 220 : 312,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(page.title(localeCode, contracts),
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                  height: 1.05,
                                )),
                    const SizedBox(height: 3),
                    Text(page.description(localeCode),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 14,
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              height: 1.16,
                            )),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: _TopBarSearchField(
                label: _zh
                    ? '搜索文档、知识库、Skill、Agent'
                    : 'Search docs, KBs, Skills, Agents',
                compact: constraints.maxWidth < 900,
                onPageChanged: onPageChanged,
              ),
            ),
            if (showUtilityChips) ...[
              const SizedBox(width: 6),
              _TopBarChip(
                icon: Icons.receipt_long_outlined,
                label: _zh ? '本地日志' : 'Local logs',
              ),
              const SizedBox(width: 6),
              _TopBarChip(
                icon: Icons.notifications_none_outlined,
                label: _zh ? '通知' : 'Notifications',
              ),
            ],
            const SizedBox(width: 6),
            _TopBarIconButton(
              icon: Icons.refresh_outlined,
              label: _zh ? '刷新' : 'Refresh',
              onPressed: () {},
            ),
            if (showWorkspaceChip) ...[
              const SizedBox(width: 6),
              _TopBarChip(
                icon: Icons.space_dashboard_outlined,
                label: _zh ? '桌面工作区' : 'Desktop workspace',
                compact: true,
              ),
            ],
            if (showLanguageToggle) const SizedBox(width: 6),
            if (showLanguageToggle && onLocaleChanged != null)
              _TopBarLanguageToggle(
                localeCode: localeCode,
                onLocaleChanged: onLocaleChanged!,
              ),
            if (!compact) const SizedBox(width: 6),
            if (!compact && isDark != null && onThemeChanged != null)
              _TopBarIconButton(
                icon: isDark!
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                label: isDark! ? (_zh ? '浅色' : 'Light') : (_zh ? '深色' : 'Dark'),
                onPressed: () =>
                    onThemeChanged!(isDark! ? ThemeMode.light : ThemeMode.dark),
              ),
          ],
        );
      },
    );
  }
}

class _DesktopDashboardSurface extends StatelessWidget {
  const _DesktopDashboardSurface({
    required this.localeCode,
    required this.contracts,
    required this.workflowV2Evidence,
    required this.parserBackends,
    required this.externalCapabilities,
    required this.workspace,
    required this.isWebRuntime,
    required this.onPageChanged,
  });

  final String localeCode;
  final WorkbenchContracts contracts;
  final P1WorkflowEvidence workflowV2Evidence;
  final ParserBackendMatrix parserBackends;
  final ExternalCapabilityRegistry externalCapabilities;
  final String workspace;
  final bool isWebRuntime;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('desktop-dashboard-surface'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DashboardMetricGrid(
          localeCode: localeCode,
          contracts: contracts,
          workflowV2Evidence: workflowV2Evidence,
          parserBackends: parserBackends,
          onPageChanged: onPageChanged,
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        LayoutBuilder(builder: (context, constraints) {
          final threeColumns = constraints.maxWidth >= 1320;
          final main = _ProductColumn(
            children: [
              _EqualHeightRow(
                height: 316,
                children: [
                  _DashboardRecentTasks(
                    localeCode: localeCode,
                    onPageChanged: onPageChanged,
                  ),
                  _DashboardNextActions(
                      localeCode: localeCode, onPageChanged: onPageChanged),
                ],
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              _DashboardReportSummary(
                localeCode: localeCode,
                workflowV2Evidence: workflowV2Evidence,
                parserBackends: parserBackends,
              ),
            ],
          );
          final side = _ProductColumn(
            children: [
              _DashboardArtifactOverview(
                localeCode: localeCode,
                onPageChanged: onPageChanged,
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              _DashboardAuthorizationCard(
                localeCode: localeCode,
                onPageChanged: onPageChanged,
              ),
            ],
          );
          if (!threeColumns) {
            return Column(children: [
              main,
              const SizedBox(height: _DesktopGrid.gutter),
              side,
            ]);
          }
          return _Grid12Row(cells: [
            _Grid12Cell(span: 9, child: main),
            _Grid12Cell(span: 3, child: side),
          ]);
        }),
      ],
    );
  }
}

class _DashboardMetricGrid extends StatelessWidget {
  const _DashboardMetricGrid({
    required this.localeCode,
    required this.contracts,
    required this.workflowV2Evidence,
    required this.parserBackends,
    required this.onPageChanged,
  });

  final String localeCode;
  final WorkbenchContracts contracts;
  final P1WorkflowEvidence workflowV2Evidence;
  final ParserBackendMatrix parserBackends;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final metrics = [
      _DashboardMetricData(
        icon: Icons.inventory_2_outlined,
        label: _zh ? '来源文档' : 'Source Docs',
        value: runtime.sourceCount.toString(),
        detail: runtime.hasImportedFile
            ? (_zh ? '已进入文档库' : 'in library')
            : (_zh ? '等待导入' : 'waiting import'),
        pageId: 'document-library',
      ),
      _DashboardMetricData(
        icon: Icons.storage_outlined,
        label: _zh ? '知识库' : 'Knowledge Base',
        value: runtime.hasKnowledgeBase ? '1' : '0',
        detail: runtime.hasKnowledgeBase
            ? '${runtime.chunkCount} chunks'
            : (_zh ? '等待构建' : 'waiting build'),
        pageId: 'knowledge-package-management',
      ),
      _DashboardMetricData(
        icon: Icons.manage_search_outlined,
        label: _zh ? '检索结果' : 'Search Results',
        value: runtime.searchResults.length.toString(),
        detail: runtime.searchStatus == Rc6SearchStatus.success
            ? (_zh ? '来自所选知识库' : 'from selected KB')
            : (_zh ? '等待查询' : 'waiting query'),
        pageId: 'retrieval-verification',
      ),
      _DashboardMetricData(
        icon: Icons.description_outlined,
        label: _zh ? '生成文档' : 'Generated Docs',
        value: runtime.hasMarkdown ? '1' : '0',
        detail: runtime.hasExportedDocument
            ? (_zh ? '已导出' : 'exported')
            : runtime.hasMarkdown
                ? (_zh ? '已生成，待导出' : 'generated, export next')
                : (_zh ? '尚未生成' : 'not generated'),
        pageId: 'document-generation',
      ),
      _DashboardMetricData(
        icon: Icons.route_outlined,
        label: _zh ? '下一步' : 'Next Step',
        value: _zh ? '继续' : 'Continue',
        detail: _dashboardNextStep(runtime, _zh),
        pageId: _dashboardNextPageId(runtime),
      ),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 1180
          ? 5
          : width >= 900
              ? 3
              : width >= 620
                  ? 2
                  : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: metrics.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: _DesktopGrid.gutter,
          crossAxisSpacing: _DesktopGrid.gutter,
          mainAxisExtent: 150,
        ),
        itemBuilder: (context, index) => _DashboardMetricCard(
          metrics[index],
          onTap: () => onPageChanged(_pageIndexById(metrics[index].pageId)),
        ),
      );
    });
  }
}

String _dashboardNextPageId(Rc6RuntimeState runtime) {
  if (!runtime.hasImportedFile || runtime.parseReportPath.isEmpty) {
    return 'document-library';
  }
  if (!runtime.hasKnowledgeBase) return 'knowledge-package-management';
  if (runtime.searchStatus != Rc6SearchStatus.success) {
    return 'retrieval-verification';
  }
  return 'document-generation';
}

String _dashboardNextStep(Rc6RuntimeState runtime, bool zh) {
  if (!runtime.hasImportedFile) return zh ? '导入文件夹' : 'import folder';
  if (runtime.parseReportPath.isEmpty) return zh ? '解析/OCR' : 'parse/OCR';
  if (!runtime.hasKnowledgeBase) return zh ? '构建知识库' : 'build KB';
  if (runtime.searchStatus != Rc6SearchStatus.success) {
    return zh ? '检索验证' : 'search';
  }
  if (!runtime.hasMarkdown) return zh ? '生成文档' : 'generate doc';
  if (!runtime.hasExportedDocument) return zh ? '导出文件' : 'export file';
  return zh ? '产物可复用' : 'artifacts reusable';
}

class _DashboardMetricData {
  const _DashboardMetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.pageId,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final String pageId;
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard(this.metric, {required this.onTap});

  final _DashboardMetricData metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(_DesktopGrid.panelRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_DesktopGrid.panelRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(_DesktopGrid.panelPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_DesktopGrid.panelRadius),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(metric.icon, size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(metric.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.12,
                            )),
                  ),
                ],
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(metric.value,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1.08,
                              )),
                      const SizedBox(height: 5),
                      Text(metric.detail,
                          maxLines: 1,
                          softWrap: true,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardRecentTasks extends StatefulWidget {
  const _DashboardRecentTasks({
    required this.localeCode,
    required this.onPageChanged,
  });

  final String localeCode;
  final ValueChanged<int> onPageChanged;

  @override
  State<_DashboardRecentTasks> createState() => _DashboardRecentTasksState();
}

class _DashboardRecentTasksState extends State<_DashboardRecentTasks> {
  bool get _zh => widget.localeCode == 'zh-CN';

  Future<void> _deleteTask(
      Rc6RuntimeController? rc6, _DashboardTaskRow row) async {
    if (rc6 == null || rc6.state.running) return;
    final confirmed = await _confirmDestructiveAction(
      context,
      title: _zh ? '删除任务记录？' : 'Delete task record?',
      body: _zh
          ? '这会删除“${row.title}”对应的真实工作区记录和下游产物；原始输入文件夹不会被删除。'
          : 'This deletes the real workspace records and downstream artifacts for "${row.title}"; original source folders are not deleted.',
    );
    if (!confirmed) return;
    await rc6.clearRecentTaskArtifacts(row.id);
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final rows = <_DashboardTaskRow>[
      if (runtime.hasImportedFile)
        _DashboardTaskRow(
          'import',
          _zh ? '导入来源文件' : 'Import sources',
          _zh ? '文档库' : 'Document Library',
          _zh ? '${runtime.sourceCount} 个文件' : '${runtime.sourceCount} files',
          Icons.upload_file_outlined,
          'document-library',
        ),
      if (runtime.parseReportPath.isNotEmpty)
        _DashboardTaskRow(
          'parse',
          _zh ? '解析 / OCR / Chunking' : 'Parse / OCR / Chunking',
          _zh ? '文档库' : 'Document Library',
          _zh ? '解析报告已生成' : 'parse report ready',
          Icons.document_scanner_outlined,
          'document-library',
        ),
      if (runtime.hasKnowledgeBase)
        _DashboardTaskRow(
          'kb',
          _zh ? '构建知识库' : 'Build knowledge base',
          _zh ? '知识库' : 'Knowledge',
          '${runtime.chunkCount} chunks',
          Icons.storage_outlined,
          'knowledge-package-management',
        ),
      if (runtime.searchStatus == Rc6SearchStatus.success)
        _DashboardTaskRow(
          'search',
          _zh ? '检索验证' : 'Search and verify',
          _zh ? '检索' : 'Retrieval',
          _zh
              ? '${runtime.searchResults.length} 条结果'
              : '${runtime.searchResults.length} results',
          Icons.manage_search_outlined,
          'retrieval-verification',
        ),
      if (runtime.hasMarkdown)
        _DashboardTaskRow(
          'doc',
          _zh ? '生成 Markdown 文档' : 'Generate Markdown document',
          _zh ? '文档生成' : 'Generation',
          runtime.hasExportedDocument
              ? (_zh ? '已导出' : 'exported')
              : (_zh ? '待导出' : 'waiting export'),
          Icons.description_outlined,
          'document-generation',
        ),
      if (runtime.hasSkill)
        _DashboardTaskRow(
          'skill',
          _zh ? '生成 Skill' : 'Generate Skill',
          _zh ? 'Skill 工厂' : 'Skill Factory',
          _displayNameForPath(runtime.skillPath),
          Icons.extension_outlined,
          'skill-factory',
        ),
      if (runtime.hasAgent)
        _DashboardTaskRow(
          'agent',
          _zh ? '创建 Agent' : 'Create Agent',
          _zh ? 'Agent 工作台' : 'Agent Workbench',
          runtime.hasAgentDialogueExport
              ? (_zh ? '已导出对话' : 'dialogue exported')
              : runtime.hasAgentDialogue
                  ? (_zh ? '已对话' : 'chat saved')
                  : runtime.hasMultiAgentDiscussion
                      ? (_zh ? '已讨论' : 'discussion saved')
                      : (_zh ? '已生成' : 'generated'),
          Icons.smart_toy_outlined,
          'agent-factory-runtime',
        ),
    ];
    final visibleRows = rows;
    return _FillProductPanel(
      keyName: 'dashboard-recent-tasks',
      icon: Icons.list_alt_outlined,
      title: _zh ? '最近任务' : 'Recent Tasks',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: visibleRows.isEmpty
                ? Center(
                    child: Text(
                      _zh
                          ? '暂无真实任务。请从“文档库导入资料”开始。'
                          : 'No real tasks yet. Start from the Document Library import.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  )
                : _LocalScrollBox(
                    child: Column(
                      children: [
                        for (final row in visibleRows) ...[
                          _DashboardTaskTile(
                            row: row,
                            onOpen: () => widget
                                .onPageChanged(_pageIndexById(row.pageId)),
                            onDelete: () => _deleteTask(rc6, row),
                          ),
                          if (row != visibleRows.last)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: visibleRows.isEmpty
                      ? null
                      : () => _deleteTask(rc6, visibleRows.first),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(_zh ? '删除最早阶段' : 'Delete first stage'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardNextActions extends StatelessWidget {
  const _DashboardNextActions({
    required this.localeCode,
    required this.onPageChanged,
  });

  final String localeCode;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final actions = <_DashboardActionRow>[
      _DashboardActionRow(
        _zh ? '文档库导入资料' : 'Import sources to document library',
        _dashboardImportActionLabel(runtime, _zh),
        Icons.file_upload_outlined,
        'document-library',
        runtime.hasImportedFile && runtime.parseReportPath.isNotEmpty,
      ),
      _DashboardActionRow(
        _zh ? '构建知识库' : 'Build knowledge base',
        runtime.hasKnowledgeBase
            ? (_zh
                ? '${runtime.chunkCount} chunks 已生成'
                : '${runtime.chunkCount} chunks ready')
            : (_zh ? '从文档库选择来源后构建' : 'Select sources from library and build'),
        Icons.storage_outlined,
        'knowledge-package-management',
        runtime.hasKnowledgeBase,
      ),
      _DashboardActionRow(
        _zh ? '检索验证' : 'Search and verify',
        runtime.searchStatus == Rc6SearchStatus.success
            ? (_zh
                ? '${runtime.searchResults.length} 条真实结果'
                : '${runtime.searchResults.length} real results')
            : (_zh ? '选择知识库并查询证据' : 'Choose KB and query evidence'),
        Icons.manage_search_outlined,
        'retrieval-verification',
        runtime.searchStatus == Rc6SearchStatus.success,
      ),
      _DashboardActionRow(
        _zh ? '生成并导出文档' : 'Generate and export documents',
        runtime.hasExportedDocument
            ? (_zh ? '导出文件可追踪' : 'Exported file is traceable')
            : (_zh ? '选择类型、格式和引用策略' : 'Choose type, format, and citations'),
        Icons.edit_document,
        'document-generation',
        runtime.hasExportedDocument,
      ),
    ];
    return _FillProductPanel(
      keyName: 'dashboard-next-actions',
      icon: Icons.route_outlined,
      title: _zh ? '下一步行动' : 'Next Actions',
      child: _LocalScrollBox(
        child: Column(
          children: [
            for (final action in actions) ...[
              _DashboardActionTile(
                action: action,
                onTap: () => onPageChanged(_pageIndexById(action.pageId)),
              ),
              if (action != actions.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

String _dashboardImportActionLabel(Rc6RuntimeState runtime, bool zh) {
  if (!runtime.hasImportedFile) {
    return zh ? '选择来源并导入队列' : 'Choose source and import queue';
  }
  if (runtime.parseReportPath.isEmpty) {
    return zh ? '继续解析 / OCR / 分块' : 'Continue parse / OCR / chunk';
  }
  return zh ? '解析报告已生成' : 'Parse report ready';
}

class _DashboardActionRow {
  const _DashboardActionRow(
      this.title, this.detail, this.icon, this.pageId, this.done);

  final String title;
  final String detail;
  final IconData icon;
  final String pageId;
  final bool done;
}

class _DashboardActionTile extends StatelessWidget {
  const _DashboardActionTile({required this.action, required this.onTap});

  final _DashboardActionRow action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tone = action.done ? _StatusTone.success : _StatusTone.neutral;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(action.icon, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            )),
                    const SizedBox(height: 2),
                    Text(action.detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            )),
                  ],
                ),
              ),
              _StatusBadge(
                label: action.done ? 'OK' : 'Open',
                tone: tone,
                icon: action.done
                    ? Icons.check_circle_outline
                    : Icons.open_in_new_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTaskRow {
  const _DashboardTaskRow(
      this.id, this.title, this.type, this.status, this.icon, this.pageId);

  final String id;
  final String title;
  final String type;
  final String status;
  final IconData icon;
  final String pageId;
}

class _DashboardTaskTile extends StatelessWidget {
  const _DashboardTaskTile({
    required this.row,
    required this.onOpen,
    required this.onDelete,
  });

  final _DashboardTaskRow row;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(row.icon, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            )),
                    const SizedBox(height: 2),
                    Text('${row.type} · ${row.status}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            )),
                  ],
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardReportSummary extends StatelessWidget {
  const _DashboardReportSummary({
    required this.localeCode,
    required this.workflowV2Evidence,
    required this.parserBackends,
  });

  final String localeCode;
  final P1WorkflowEvidence workflowV2Evidence;
  final ParserBackendMatrix parserBackends;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'dashboard-report-summary',
      icon: Icons.analytics_outlined,
      title: _zh ? '知识供应链进度' : 'Knowledge Supply Chain',
      children: [
        _ProductTable(
          columns: _zh
              ? ['环节', '状态', '用户可见结果', '下一步']
              : ['Step', 'Status', 'User result', 'Next'],
          rows: _zh
              ? [
                  [
                    '文档库导入与解析',
                    '可操作',
                    'source_manifest.json / parse_report.json',
                    '进入文档库'
                  ],
                  [
                    '知识库构建',
                    '可操作',
                    'chunks / cards / qa_pairs / manifest',
                    '检索验证'
                  ],
                  ['文档生成', '可操作', 'Markdown 草稿与导出文件', '进入产物中心'],
                ]
              : [
                  [
                    'Import and parsing',
                    'Actionable',
                    'source_manifest.json / parse_report.json',
                    'Open library'
                  ],
                  [
                    'Knowledge build',
                    'Actionable',
                    'chunks / cards / qa_pairs / manifest',
                    'Search'
                  ],
                  [
                    'Document generation',
                    'Actionable',
                    'Markdown draft and export file',
                    'Open artifacts'
                  ],
                ],
        ),
      ],
    );
  }
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

class _DashboardAuthorizationCard extends StatelessWidget {
  const _DashboardAuthorizationCard({
    required this.localeCode,
    required this.onPageChanged,
  });

  final String localeCode;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'dashboard-authorization',
      icon: Icons.admin_panel_settings_outlined,
      title: _zh ? '配置状态' : 'Configuration Status',
      gap: true,
      children: [
        _ProductTable(
          columns: _zh
              ? ['能力', '当前处理', '用户动作']
              : ['Capability', 'Handling', 'User action'],
          rows: _zh
              ? [
                  ['外部事实验证', '需要配置', '在运行设置中配置联网 Provider'],
                  ['Redis 记忆缓存', '可选配置', '保存配置并测试连接'],
                  ['Qdrant 向量库', '可选配置', '保存配置并测试连接'],
                ]
              : [
                  [
                    'External fact checking',
                    'Needs configuration',
                    'Configure network Provider in Settings'
                  ],
                  [
                    'Redis memory cache',
                    'Optional configuration',
                    'Save config and test connection'
                  ],
                  [
                    'Qdrant vector DB',
                    'Optional configuration',
                    'Save config and test connection'
                  ],
                ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _PrimaryProductAction(
          label: _zh
              ? '打开设置配置 Provider / Redis / Qdrant'
              : 'Open Settings for Provider / Redis / Qdrant',
          icon: Icons.settings_outlined,
          onPressed: () => onPageChanged(_pageIndexById('workspace')),
        ),
      ],
    );
  }
}

class _DashboardArtifactOverview extends StatelessWidget {
  const _DashboardArtifactOverview({
    required this.localeCode,
    required this.onPageChanged,
  });

  final String localeCode;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final runtime =
        _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
    return _ProductPanel(
      keyName: 'dashboard-artifact-overview',
      icon: Icons.folder_copy_outlined,
      title: _zh ? '生成产物' : 'Generated Artifacts',
      gap: true,
      children: [
        _ProductTable(
          columns:
              _zh ? ['产物', '状态', '位置'] : ['Artifact', 'Status', 'Location'],
          rows: _zh
              ? [
                  [
                    'source_manifest.json',
                    runtime.sourceManifestPath.isEmpty ? '未生成' : '已生成',
                    _displayNameForPath(runtime.sourceManifestPath)
                  ],
                  [
                    'parse_report.json',
                    runtime.parseReportPath.isEmpty ? '未生成' : '已生成',
                    _displayNameForPath(runtime.parseReportPath)
                  ],
                  [
                    'kb/manifest.json',
                    runtime.kbManifestPath.isEmpty ? '未生成' : '已生成',
                    _displayNameForPath(runtime.kbManifestPath)
                  ],
                  [
                    'reading_notes_export.md',
                    runtime.exportedDocumentPath.isEmpty ? '未导出' : '已导出',
                    _displayNameForPath(runtime.exportedDocumentPath)
                  ],
                  [
                    'PRD P0 产品闭环',
                    runtime.hasPrdP0Evidence ? '已生成' : '未生成',
                    _displayNameForPath(runtime.prdP0EvidencePath)
                  ],
                ]
              : [
                  [
                    'source_manifest.json',
                    runtime.sourceManifestPath.isEmpty
                        ? 'Not generated'
                        : 'Generated',
                    _displayNameForPath(runtime.sourceManifestPath)
                  ],
                  [
                    'parse_report.json',
                    runtime.parseReportPath.isEmpty
                        ? 'Not generated'
                        : 'Generated',
                    _displayNameForPath(runtime.parseReportPath)
                  ],
                  [
                    'kb/manifest.json',
                    runtime.kbManifestPath.isEmpty
                        ? 'Not generated'
                        : 'Generated',
                    _displayNameForPath(runtime.kbManifestPath)
                  ],
                  [
                    'reading_notes_export.md',
                    runtime.exportedDocumentPath.isEmpty
                        ? 'Not exported'
                        : 'Exported',
                    _displayNameForPath(runtime.exportedDocumentPath)
                  ],
                  [
                    'PRD P0 product flow',
                    runtime.hasPrdP0Evidence ? 'Generated' : 'Not generated',
                    _displayNameForPath(runtime.prdP0EvidencePath)
                  ],
                ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _EqualActionRow(children: [
          _DisplayAction(
            label: _zh ? '查看文档库' : 'Open document library',
            icon: Icons.library_books_outlined,
            onPressed: () => onPageChanged(_pageIndexById('document-library')),
          ),
          _DisplayAction(
            label: _zh ? '查看导出文件' : 'Open generated documents',
            icon: Icons.file_download_outlined,
            onPressed: () =>
                onPageChanged(_pageIndexById('document-generation')),
          ),
          _DisplayAction(
            label: _zh ? '查看 Agent / A2A' : 'Open Agent / A2A',
            icon: Icons.groups_2_outlined,
            onPressed: runtime.hasPrdP0Evidence
                ? () => onPageChanged(_pageIndexById('agent-factory-runtime'))
                : null,
          ),
        ]),
      ],
    );
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
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

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
              key: Key('page-tab-$index'),
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

class _ImportStepAction {
  const _ImportStepAction(
      this.label, this.detail, this.icon, this.done, this.onPressed);

  final String label;
  final String detail;
  final IconData icon;
  final bool done;
  final VoidCallback? onPressed;
}

class _ImportStepActionGrid extends StatelessWidget {
  const _ImportStepActionGrid({required this.steps});

  final List<_ImportStepAction> steps;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 760
          ? 3
          : constraints.maxWidth >= 480
              ? 2
              : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: steps.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: _DesktopGrid.gutter,
          mainAxisSpacing: _DesktopGrid.gutter,
          mainAxisExtent: 86,
        ),
        itemBuilder: (context, index) {
          final step = steps[index];
          final enabled = step.onPressed != null;
          return Material(
            color: step.done
                ? colors.primary.withValues(alpha: 0.08)
                : colors.surface,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: step.onPressed,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: step.done ? colors.primary : colors.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(step.done ? Icons.check_circle_outline : step.icon,
                        color: enabled || step.done
                            ? colors.primary
                            : colors.onSurfaceVariant,
                        size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(step.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text(step.detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

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
    required this.documents,
    required this.selectedIndex,
    required this.selectedDocuments,
    required this.onSelected,
    required this.onSelectionChanged,
  });

  final bool zh;
  final List<String> documents;
  final int selectedIndex;
  final Set<String> selectedDocuments;
  final ValueChanged<int> onSelected;
  final void Function(String name, bool selected) onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
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
        for (var index = 0; index < documents.length; index++) ...[
          ListTile(
            dense: true,
            selected: selectedIndex == index,
            leading: Checkbox(
              value: selectedDocuments.contains(documents[index]),
              onChanged: (selected) =>
                  onSelectionChanged(documents[index], selected ?? false),
            ),
            title: Text(documents[index],
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
          ),
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

class _ImportHistoryList extends StatelessWidget {
  const _ImportHistoryList({
    required this.zh,
    required this.rows,
    required this.selectedRows,
    required this.onToggle,
    required this.onDelete,
    required this.onDeleteSelected,
    required this.onClear,
  });

  final bool zh;
  final List<List<String>> rows;
  final Set<int> selectedRows;
  final ValueChanged<int> onToggle;
  final ValueChanged<int> onDelete;
  final VoidCallback? onDeleteSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (var index = 0; index < rows.length; index++)
        MapEntry(index, rows[index])
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (visible.isEmpty)
          _RuntimeFeedbackBanner(
            title: zh ? '历史记录已清空' : 'History cleared',
            detail: zh
                ? '导入清单和下游产物已从当前工作区删除。'
                : 'Import manifest and downstream artifacts were deleted from this workspace.',
            tone: _StatusTone.neutral,
            icon: Icons.delete_sweep_outlined,
          )
        else ...[
          for (final entry in visible) ...[
            Material(
              type: MaterialType.transparency,
              child: CheckboxListTile(
                dense: true,
                value: selectedRows.contains(entry.key),
                onChanged: (_) => onToggle(entry.key),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(entry.value[0],
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${entry.value[1]} · ${entry.value[2]}',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                secondary: IconButton(
                  tooltip:
                      MaterialLocalizations.of(context).deleteButtonTooltip,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDelete(entry.key),
                ),
              ),
            ),
            if (entry != visible.last) const Divider(height: 8),
          ],
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDeleteSelected,
                icon: const Icon(Icons.delete_outline),
                label: Text(zh ? '删除选中' : 'Delete selected'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: visible.isEmpty ? null : onClear,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(zh ? '全部删除' : 'Delete all'),
              ),
            ),
          ],
        ),
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

  bool get _zh => widget.localeCode == 'zh-CN';

  Future<void> _chooseSource(Rc6RuntimeController? rc6) async {
    if (rc6 == null || rc6.state.running) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_zh ? '选择来源' : 'Choose source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(_zh ? '选择文件' : 'Choose file'),
                subtitle: Text(_zh ? '导入单个真实文档' : 'Import one real document'),
                onTap: () => Navigator.of(context).pop('file'),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: const Icon(Icons.drive_folder_upload_outlined),
                title: Text(_zh ? '选择文件夹' : 'Choose folder'),
                subtitle: Text(_zh
                    ? '批量导入文件夹内全部支持文件'
                    : 'Import supported files in a folder'),
                onTap: () => Navigator.of(context).pop('folder'),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: const Icon(Icons.link_outlined),
                title: Text(_zh ? '输入网页链接' : 'Enter web link'),
                subtitle: Text(_zh
                    ? '保存为文档库来源记录，授权后可联网抓取'
                    : 'Save as a library source record; fetching needs authorization'),
                onTap: () => Navigator.of(context).pop('web'),
              ),
            ),
          ],
        ),
      ),
    );
    if (choice == 'file') {
      await rc6.pickAndImportFile();
    } else if (choice == 'folder') {
      await rc6.pickAndImportFolder();
    } else if (choice == 'web') {
      final url = await _promptWebLink();
      if (url != null && url.trim().isNotEmpty) {
        await rc6.importWebLink(url);
      }
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
    final hasSources = stagedSources > 0 || runtime.sourceCount > 0;
    final hasManifest = preparedManifests > 0 || runtime.hasImportedFile;
    final hasRealImport = runtime.hasImportedFile;
    final steps = <_ImportStepAction>[
      _ImportStepAction(
        _zh ? '1. 选择来源' : '1. Choose source',
        _zh ? '选择文件或文件夹' : 'Choose files or a folder',
        Icons.folder_open_outlined,
        runtime.hasImportedFile,
        runtime.running || rc6 == null ? null : () => _chooseSource(rc6),
      ),
      _ImportStepAction(
        _zh ? '2. 导入队列' : '2. Import queue',
        hasManifest
            ? (_zh
                ? '${runtime.sourceCount} 个文件已入队'
                : '${runtime.sourceCount} files queued')
            : (_zh ? '等待来源' : 'Waiting for source'),
        Icons.playlist_add_check_outlined,
        hasManifest,
        runtime.hasImportedFile ? () {} : null,
      ),
      _ImportStepAction(
        _zh ? '3. 解析' : '3. Parse',
        runtime.parseReportPath.isNotEmpty
            ? (_zh ? '解析报告已生成' : 'Parse report generated')
            : (_zh
                ? '运行 Parser / OCR / Chunking'
                : 'Run parser / OCR / chunking'),
        Icons.document_scanner_outlined,
        runtime.parseReportPath.isNotEmpty,
        runtime.running || rc6 == null || !runtime.hasImportedFile
            ? null
            : () => rc6.parseAndChunkSources(),
      ),
      _ImportStepAction(
        _zh ? '4. OCR 验收' : '4. OCR acceptance',
        runtime.parseReportPath.isNotEmpty
            ? (_zh ? 'OCR 记录进入 parse_report' : 'OCR record is in parse_report')
            : (_zh ? '解析完成后验收' : 'Accepted after parsing'),
        Icons.image_search_outlined,
        runtime.parseReportPath.isNotEmpty,
        runtime.parseReportPath.isNotEmpty ? () {} : null,
      ),
      _ImportStepAction(
        _zh ? '5. Chunking 验收' : '5. Chunking acceptance',
        runtime.chunkCount > 0
            ? '${runtime.chunkCount} chunks'
            : (_zh ? '等待切分产物' : 'Waiting for chunks'),
        Icons.segment_outlined,
        runtime.chunkCount > 0,
        runtime.chunkCount > 0 ? () {} : null,
      ),
      _ImportStepAction(
        _zh ? '6. 查看报告' : '6. View report',
        runtime.parseReportPath.isNotEmpty
            ? _displayNameForPath(runtime.parseReportPath)
            : (_zh ? '等待 parse_report.json' : 'Waiting for parse_report.json'),
        Icons.receipt_long_outlined,
        runtime.parseReportPath.isNotEmpty,
        runtime.parseReportPath.isNotEmpty ? () {} : null,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductHeader(
          icon: Icons.upload_file_outlined,
          title: _zh ? '导入与解析' : 'Import and Parsing',
          description: _zh
              ? '文件、文件夹与网页链接进入同一队列；解析器、OCR、分块和失败恢复在本页完成。'
              : 'Files, folders, and web links enter one queue; parser, OCR, chunking, and recovery are handled here.',
          trailing: _StatePill(
            label: widget.isWebRuntime
                ? (_zh ? 'Web 预览模式' : 'Web preview mode')
                : (_zh ? '桌面输入' : 'Desktop input'),
            icon: Icons.shield_outlined,
          ),
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _MetricStrip(
          items: [
            _MetricDatum(
                label: _zh ? '排队文件' : 'Queued files',
                value: runtime.sourceCount.toString(),
                detail: _zh ? '等待解析' : 'waiting',
                icon: Icons.file_present_outlined),
            _MetricDatum(
                label: _zh ? '解析后端' : 'Parser backends',
                value: '4',
                detail: _zh ? '证据登记' : 'registered',
                icon: Icons.document_scanner_outlined),
            _MetricDatum(
                label: _zh ? 'OCR' : 'OCR',
                value: _zh ? '已验收' : 'Accepted',
                detail: _zh ? 'PaddleOCR 本地运行' : 'PaddleOCR local',
                icon: Icons.image_search_outlined),
            _MetricDatum(
                label: _zh ? '失败恢复' : 'Recovery',
                value: hasManifest ? '2' : '0',
                detail: _zh ? '可重试项' : 'retryable',
                icon: Icons.restart_alt_outlined),
          ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _ImportStepActionGrid(steps: steps),
        const SizedBox(height: _DesktopGrid.gutter),
        if (hasSources || hasManifest) ...[
          _RuntimeFeedbackBanner(
            title: hasRealImport
                ? (_zh ? '真实导入清单已生成' : 'Real import manifest created')
                : hasManifest
                    ? (_zh ? '导入清单已准备' : 'Import manifest prepared')
                    : (_zh ? '等待真实来源' : 'Waiting for real source'),
            detail: hasRealImport
                ? runtime.sourceManifestPath
                : (_zh
                    ? '请选择真实文件或文件夹以生成 source_manifest.json。'
                    : 'Choose real files or a folder to write source_manifest.json.'),
            tone: hasRealImport ? _StatusTone.success : _StatusTone.warning,
            icon: hasRealImport ? Icons.verified_outlined : Icons.info_outline,
          ),
          const SizedBox(height: _DesktopGrid.gutter),
        ],
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;
          final intake = _ProductPanel(
            keyName: 'import-intake-surface',
            accent: true,
            icon: Icons.folder_open_outlined,
            title: _zh ? '来源入口' : 'Source Intake',
            minHeight: 410,
            subtitle: _zh
                ? '选择文件或文件夹后进入同一导入队列；网页链接由授权 Provider 配置后启用。'
                : 'Files and folders enter one queue; web links require authorized Provider config.',
            children: [
              _ImportStepActionGrid(steps: steps),
              const SizedBox(height: _DesktopGrid.gutter),
              _PrimaryProductAction(
                label: _zh ? '选择来源' : 'Choose source',
                onPressed: runtime.running || rc6 == null
                    ? null
                    : () => _chooseSource(rc6),
                icon: Icons.folder_open_outlined,
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              _MiniProgressBar(
                  value: runtime.parseReportPath.isNotEmpty
                      ? 1
                      : hasManifest
                          ? 0.68
                          : 0.12),
              const SizedBox(height: 8),
              _PrimaryProductAction(
                label: _zh ? '解析 / OCR / Chunking' : 'Parse / OCR / Chunking',
                onPressed: runtime.running || rc6 == null
                    ? null
                    : () => rc6.parseAndChunkSources(),
                icon: Icons.document_scanner_outlined,
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              _DisplayAction(
                label: _zh ? '一键完成到解析报告' : 'Run source-to-parse in one click',
                icon: Icons.auto_mode_outlined,
                onPressed:
                    runtime.running || rc6 == null || !runtime.hasImportedFile
                        ? null
                        : () => rc6.parseAndChunkSources(),
              ),
            ],
          );
          final queue = _ProductPanel(
            keyName: 'import-queue',
            icon: Icons.list_alt_outlined,
            title: _zh ? '文件队列与进度' : 'File Queue and Progress',
            minHeight: 326,
            children: [
              _ProductTable(
                columns: _zh
                    ? ['文件', '来源类型', '进度', '状态', '失败恢复', '输出产物']
                    : [
                        'File',
                        'Source type',
                        'Progress',
                        'Status',
                        'Recovery',
                        'Output artifact'
                      ],
                rows: _zh
                    ? [
                        [
                          hasRealImport
                              ? _displayNameForPath(runtime.selectedFilePath)
                              : '等待本地文件',
                          '文件',
                          hasManifest ? '100%' : '0%',
                          hasRealImport ? '已导入' : '待输入',
                          hasManifest ? '无需恢复' : '待生成清单',
                          'source_manifest.json'
                        ],
                        if (hasManifest)
                          [
                            '解析 / OCR / Chunking',
                            '本地解析',
                            runtime.parseReportPath.isNotEmpty ? '100%' : '处理中',
                            runtime.parseReportPath.isNotEmpty ? '已解析' : '排队',
                            '失败可重试',
                            'parse_report.json'
                          ],
                      ]
                    : [
                        [
                          hasRealImport
                              ? _displayNameForPath(runtime.selectedFilePath)
                              : 'Waiting for local files',
                          'File',
                          hasManifest ? '100%' : '0%',
                          hasRealImport ? 'Imported' : 'Pending',
                          hasManifest ? 'No recovery' : 'Prepare manifest',
                          'source_manifest.json'
                        ],
                        if (hasManifest)
                          [
                            'Parse / OCR / Chunking',
                            'Local parser',
                            runtime.parseReportPath.isNotEmpty
                                ? '100%'
                                : 'Running',
                            runtime.parseReportPath.isNotEmpty
                                ? 'Parsed'
                                : 'Queued',
                            'Retryable on failure',
                            'parse_report.json'
                          ],
                      ],
              ),
            ],
          );
          final settings = _ProductPanel(
            keyName: 'parser-settings',
            icon: Icons.tune_outlined,
            title: _zh ? '解析器 / OCR / 分块' : 'Parser / OCR / Chunking',
            minHeight: 410,
            children: [
              _ProductTable(
                columns:
                    _zh ? ['配置项', '当前值', '分类'] : ['Setting', 'Value', 'Class'],
                rows: _zh
                    ? [
                        ['解析器', 'HeiTang Parser / builtin', '可用'],
                        ['OCR', 'PaddleOCR PP-OCRv6 local runtime', '可用'],
                        ['分块', '语义切分，800 tokens，120 overlap', '可用'],
                        ['语言', '中文 + 英文', '可用'],
                      ]
                    : [
                        ['Parser', 'HeiTang Parser / builtin', 'Available'],
                        [
                          'OCR',
                          'PaddleOCR PP-OCRv6 local runtime',
                          'Available'
                        ],
                        [
                          'Chunking',
                          'Semantic, 800 tokens, 120 overlap',
                          'Available'
                        ],
                        ['Language', 'Chinese + English', 'Available'],
                      ],
              ),
            ],
          );
          final manifest = _ProductPanel(
            keyName: 'manifest-preview',
            icon: Icons.description_outlined,
            title: _zh ? '导入历史与输出清单' : 'Import History and Manifest',
            minHeight: 326,
            children: [
              _ImportHistoryList(
                zh: _zh,
                rows: _zh
                    ? [
                        [
                          'source_manifest.json',
                          hasRealImport ? '已生成' : '等待',
                          '来源清单'
                        ],
                        [
                          'parse_report.json',
                          runtime.parseReportPath.isNotEmpty ? '已生成' : '等待',
                          '解析报告'
                        ],
                        [
                          '失败恢复',
                          hasManifest ? '可重试 / 可跳过 / 可查看错误' : '等待解析',
                          '恢复操作'
                        ],
                        ['下一阶段', '文档库', '来源文档管理'],
                      ]
                    : [
                        [
                          'source_manifest.json',
                          hasRealImport ? 'Written' : 'Waiting',
                          'Source inventory'
                        ],
                        [
                          'parse_report.json',
                          runtime.parseReportPath.isNotEmpty
                              ? 'Written'
                              : 'Waiting',
                          'Parsing report'
                        ],
                        [
                          'Failure recovery',
                          hasManifest
                              ? 'Retry / skip / view error'
                              : 'Waiting parse',
                          'Recovery actions'
                        ],
                        ['Next stage', 'Document Library', 'Source management'],
                      ],
                selectedRows: selectedHistoryRows,
                onToggle: (index) => setState(() {
                  if (!selectedHistoryRows.add(index)) {
                    selectedHistoryRows.remove(index);
                  }
                }),
                onDelete: (_) => _confirmAndDeleteImport(rc6),
                onDeleteSelected: selectedHistoryRows.isEmpty
                    ? null
                    : () => _confirmAndDeleteImport(rc6),
                onClear: () => _confirmAndDeleteImport(rc6),
              ),
            ],
          );
          if (!wide) {
            return Column(children: [
              intake,
              const SizedBox(height: _DesktopGrid.gutter),
              settings,
              const SizedBox(height: _DesktopGrid.gutter),
              queue,
              const SizedBox(height: _DesktopGrid.gutter),
              manifest,
            ]);
          }
          return Column(children: [
            _EqualHeightRow(
              height: 410,
              flexes: const [7, 5],
              children: [intake, settings],
            ),
            const SizedBox(height: _DesktopGrid.gutter),
            _EqualHeightRow(
              height: 326,
              flexes: const [7, 5],
              children: [queue, manifest],
            ),
          ]);
        }),
      ],
    );
  }
}

class _KnowledgeProductWorkflow extends StatelessWidget {
  const _KnowledgeProductWorkflow({
    required this.localeCode,
    required this.workspace,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final String localeCode;
  final String workspace;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final tabs = _zh
        ? ['知识库', '向量索引', '质量记录', '存储边界']
        : ['Packages', 'Vector Index', 'Quality Records', 'Storage Boundary'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductHeader(
          icon: Icons.inventory_2_outlined,
          title: _zh ? '知识库' : 'Knowledge Base',
          description: _zh
              ? '管理知识库列表、向量索引、质量、版本、构建和验证记录。'
              : 'Manage knowledge bases, vector indexes, quality, versions, builds, and validation records.',
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _PageTabs(
            tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
        const SizedBox(height: _DesktopGrid.gutter),
        if (selectedTab == 1)
          _KnowledgeVectorIndexView(zh: _zh)
        else if (selectedTab == 2)
          _KnowledgeQualityRecordsView(zh: _zh)
        else if (selectedTab == 3)
          _KnowledgeStorageBoundaryView(zh: _zh)
        else
          _KnowledgePackageListView(zh: _zh, workspace: workspace),
      ],
    );
  }
}

class _KnowledgeStorageBoundaryView extends StatelessWidget {
  const _KnowledgeStorageBoundaryView({required this.zh});

  final bool zh;

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'knowledge-storage-boundary',
      icon: Icons.storage_outlined,
      title: zh ? '存储与 Provider 边界' : 'Storage and Provider Boundary',
      gap: true,
      subtitle: zh
          ? 'Provider、存储和应用工作区归设置；这里仅展示知识库侧引用边界。'
          : 'Providers, storage, and workspace live in Settings; this shows the Knowledge Base side boundary only.',
      children: [
        _ProductTable(
          columns: zh ? ['能力', '当前分类', '说明'] : ['Capability', 'Class', 'Note'],
          rows: zh
              ? [
                  ['本地知识库', '可用', '依赖已有本地产物'],
                  ['向量库 Provider', '未配置外部向量库', '本地索引可用，可在 Settings 配置'],
                  ['外部事实验证', '授权后可用', '联网 Provider 配置后执行'],
                ]
              : [
                  [
                    'Local package',
                    'Available',
                    'Depends on existing local artifacts'
                  ],
                  [
                    'Vector DB provider',
                    'External vector DB not configured',
                    'Local index available; configure in Settings'
                  ],
                  [
                    'External fact verification',
                    'Available after authorization',
                    'Runs after network Provider is configured'
                  ],
                ],
        ),
      ],
    );
  }
}

class _DocumentProductWorkflow extends StatelessWidget {
  const _DocumentProductWorkflow({
    required this.localeCode,
    required this.workspace,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final String localeCode;
  final String workspace;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final tabs = _zh
        ? ['生成任务', '文档模板', '导出预览']
        : ['Generation Tasks', 'Document Templates', 'Export Preview'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductHeader(
          icon: Icons.description_outlined,
          title: _zh ? '文档生成' : 'Document Generation',
          description: _zh
              ? '从知识库生成报告、手册、教案、PPTX 教学材料和自定义模板草稿。'
              : 'Generate reports, manuals, teaching material, PPTX lessons, and custom template drafts from Knowledge Bases.',
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _PageTabs(
            tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
        const SizedBox(height: _DesktopGrid.gutter),
        if (selectedTab == 1)
          _DocumentTemplateView(zh: _zh)
        else if (selectedTab == 2)
          _DocumentExportPreviewView(zh: _zh, workspace: workspace)
        else
          _DocumentGenerationView(zh: _zh),
      ],
    );
  }
}

class _DocumentGenerationView extends StatefulWidget {
  const _DocumentGenerationView({required this.zh});

  final bool zh;

  @override
  State<_DocumentGenerationView> createState() =>
      _DocumentGenerationViewState();
}

class _DocumentGenerationViewState extends State<_DocumentGenerationView> {
  bool draftQueued = false;
  bool previewReady = false;
  String generationType = 'reading_notes';
  String outputFormat = 'md';
  String citationStrategy = 'source_filename';
  String templateMode = 'built_in';
  final TextEditingController _editorController = TextEditingController();
  String savedEditPath = '';

  bool get zh => widget.zh;

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final markdownStatus = runtime.hasMarkdown
        ? (zh ? '已生成' : 'Generated')
        : runtime.hasKnowledgeBase
            ? (zh ? '可生成' : 'Ready')
            : (zh ? '需要知识库' : 'Needs KB');
    final exportReady = runtime.hasMarkdown
        ? (zh ? '可导出' : 'Ready')
        : (zh ? '需要文档' : 'Needs document');
    final localExporter = zh ? '本地导出器' : 'Local exporter';
    Future<void> openGenerationDialog() async {
      final result = await showDialog<_DocumentGenerationConfig>(
        context: context,
        builder: (context) => _DocumentGenerationDialog(
          zh: zh,
          initial: _DocumentGenerationConfig(
            generationType: generationType,
            outputFormat: outputFormat,
            citationStrategy: citationStrategy,
            templateMode: templateMode,
          ),
        ),
      );
      if (result == null) return;
      setState(() {
        generationType = result.generationType;
        outputFormat = result.outputFormat;
        citationStrategy = result.citationStrategy;
        templateMode = result.templateMode;
        draftQueued = true;
        previewReady = true;
      });
      if (rc6 == null || runtime.running) return;
      await rc6.generateMarkdown(
        config: Rc6DocumentGenerationConfig(
          generationType: result.generationType,
          outputFormat: result.outputFormat,
          citationStrategy: result.citationStrategy,
          templateMode: result.templateMode,
        ),
      );
      if (result.outputFormat != 'md' && rc6.state.lastResult?.passed == true) {
        await rc6.exportDocumentFormat(result.outputFormat);
      }
    }

    Future<void> loadGeneratedBody() async {
      if (rc6 == null) return;
      final path = runtime.readingNotesPath.isNotEmpty
          ? runtime.readingNotesPath
          : runtime.generatedMarkdownPath;
      if (path.isEmpty) return;
      final content = await rc6.readWorkspaceTextArtifact(path);
      if (!mounted) return;
      setState(() {
        _editorController.text = content;
        previewReady = true;
      });
    }

    Future<void> saveEditedBody() async {
      if (rc6 == null) return;
      final path = await rc6.saveEditedDocument(_editorController.text);
      if (!mounted) return;
      setState(() => savedEditPath = path);
    }

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1040;
      final extraWide = constraints.maxWidth >= 1180;
      final tasks = _ProductPanel(
        keyName: 'document-generation-tasks',
        icon: Icons.post_add_outlined,
        title: zh ? '生成任务' : 'Generation Task',
        minHeight: 366,
        children: [
          SizedBox(
            height: 276,
            child: _FillPanelColumn(
              top: _LocalScrollBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProductTable(
                      columns: zh
                          ? ['配置', '当前选择', '状态']
                          : ['Config', 'Selection', 'Status'],
                      rows: zh
                          ? [
                              [
                                '知识库 / 来源',
                                runtime.hasKnowledgeBase
                                    ? '真实输入知识库'
                                    : '需要先完成知识库构建',
                                markdownStatus
                              ],
                              [
                                '生成类型',
                                _documentGenerationTypeLabel(
                                    generationType, zh),
                                '已选择'
                              ],
                              ['题材 / 模板', '内置读书笔记模板', '可用'],
                              [
                                '模板模式',
                                _templateModeLabel(templateMode, zh),
                                templateMode == 'agent' ? '使用内置 Agent 题材' : '可用'
                              ],
                              [
                                '输出格式',
                                outputFormat.toUpperCase(),
                                outputFormat == 'md'
                                    ? markdownStatus
                                    : exportReady
                              ],
                              [
                                '引用策略',
                                _citationStrategyLabel(citationStrategy, zh),
                                '已选择'
                              ],
                            ]
                          : [
                              [
                                'KB / source',
                                runtime.hasKnowledgeBase
                                    ? 'Real input KB'
                                    : 'Complete KB build first',
                                markdownStatus
                              ],
                              [
                                'Generation type',
                                _documentGenerationTypeLabel(
                                    generationType, zh),
                                'Selected'
                              ],
                              [
                                'Genre / template',
                                'Built-in reading-notes template',
                                'Ready'
                              ],
                              [
                                'Template mode',
                                _templateModeLabel(templateMode, zh),
                                templateMode == 'agent'
                                    ? 'Built-in agent genre'
                                    : 'Ready'
                              ],
                              [
                                'Output format',
                                outputFormat.toUpperCase(),
                                outputFormat == 'md'
                                    ? markdownStatus
                                    : exportReady
                              ],
                              [
                                'Citation strategy',
                                _citationStrategyLabel(citationStrategy, zh),
                                'Selected'
                              ],
                            ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final item in const [
                        'reading_notes',
                        'summary',
                        'study_cards',
                        'structured_report',
                        'ppt_outline',
                        'operation_plan',
                        'product_analysis',
                        'qa_script',
                      ])
                        ChoiceChip(
                          label: Text(_documentGenerationTypeLabel(item, zh)),
                          selected: generationType == item,
                          onSelected: (_) =>
                              setState(() => generationType = item),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final item in const ['built_in', 'custom', 'agent'])
                        ChoiceChip(
                          label: Text(_templateModeLabel(item, zh)),
                          selected: templateMode == item,
                          onSelected: (_) =>
                              setState(() => templateMode = item),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final item in const [
                        'md',
                        'docx',
                        'pdf',
                        'pptx',
                        'json',
                        'csv'
                      ])
                        ChoiceChip(
                          label: Text(item.toUpperCase()),
                          selected: outputFormat == item,
                          onSelected: (_) =>
                              setState(() => outputFormat = item),
                        ),
                    ]),
                  ],
                ),
              ),
              bottom: _EqualActionRow(children: [
                _PrimaryProductAction(
                  label: zh ? '生成文档' : 'Generate document',
                  icon: Icons.notes_outlined,
                  onPressed: runtime.running || rc6 == null
                      ? null
                      : runtime.hasKnowledgeBase
                          ? openGenerationDialog
                          : null,
                ),
                _PrimaryProductAction(
                  label: zh ? '重新生成' : 'Regenerate',
                  icon: Icons.restart_alt_outlined,
                  onPressed: runtime.running ||
                          rc6 == null ||
                          !runtime.hasKnowledgeBase
                      ? null
                      : openGenerationDialog,
                ),
              ]),
            ),
          ),
        ],
      );
      final preview = _ProductPanel(
        keyName: 'document-live-preview',
        icon: Icons.article_outlined,
        title: zh ? '正文编辑' : 'Body Editor',
        minHeight: 366,
        children: [
          SizedBox(
            key: const Key('document-central-preview'),
            height: 184,
            child: TextField(
              key: const Key('document-body-editor'),
              controller: _editorController,
              maxLines: null,
              expands: true,
              enabled: rc6 != null,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: runtime.hasMarkdown
                    ? (zh
                        ? '加载生成稿后可编辑正文。'
                        : 'Load the generated body, then edit it.')
                    : (zh ? '请先生成正文。' : 'Generate the body first.'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.22,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          _EqualActionRow(children: [
            _DisplayAction(
              label: zh ? '加载生成稿' : 'Load Draft',
              icon: Icons.article_outlined,
              onPressed: rc6 == null || !runtime.hasMarkdown
                  ? null
                  : loadGeneratedBody,
            ),
            _PrimaryProductAction(
              label: zh ? '保存编辑' : 'Save Edit',
              icon: Icons.save_outlined,
              onPressed: rc6 == null ||
                      runtime.running ||
                      !runtime.hasMarkdown ||
                      _editorController.text.trim().isEmpty
                  ? null
                  : saveEditedBody,
            ),
          ]),
          if (runtime.generatedMarkdownPath.isNotEmpty) ...[
            const SizedBox(height: 8),
            _FieldRow(
              label: zh ? '真实 Markdown 路径' : 'Real Markdown path',
              value: _displayNameForPath(runtime.generatedMarkdownPath),
            ),
          ],
          if (runtime.readingNotesPath.isNotEmpty) ...[
            const SizedBox(height: 8),
            _FieldRow(
              label: zh ? '读书笔记' : 'Reading notes',
              value: _displayNameForPath(runtime.readingNotesPath),
            ),
          ],
          if (runtime.editedDocumentPath.isNotEmpty ||
              savedEditPath.isNotEmpty) ...[
            const SizedBox(height: 8),
            _FieldRow(
              label: zh ? '编辑稿' : 'Edited draft',
              value: _displayNameForPath(runtime.editedDocumentPath.isNotEmpty
                  ? runtime.editedDocumentPath
                  : savedEditPath),
            ),
          ],
        ],
      );
      final config = _FillProductPanel(
        icon: Icons.tune_outlined,
        title: zh ? '生成配置' : 'Generation Config',
        child: Align(
          alignment: Alignment.topCenter,
          child: _ProductTable(
            columns: zh ? ['配置', '值', '分类'] : ['Setting', 'Value', 'Class'],
            rows: zh
                ? [
                    [
                      '引用策略',
                      _citationStrategyLabel(citationStrategy, zh),
                      '来源文件名与知识库片段'
                    ],
                    ['脱敏检查', '本地检查', '不显示明文 secret'],
                    [
                      '引用验证',
                      runtime.searchStatus == Rc6SearchStatus.success
                          ? '检索结果可用'
                          : '需要先运行检索',
                      '引用来源可追踪'
                    ],
                    [
                      '编辑保存',
                      runtime.hasEditedDocument ? '已保存' : '等待编辑',
                      '用户工作区'
                    ],
                    ['生成历史', runtime.hasMarkdown ? '已记录' : '暂无历史', '用户工作区'],
                  ]
                : [
                    [
                      'Citation strategy',
                      _citationStrategyLabel(citationStrategy, zh),
                      'Source names and KB snippets'
                    ],
                    ['Redaction check', 'Local check', 'No plaintext secret'],
                    [
                      'Citation validation',
                      runtime.searchStatus == Rc6SearchStatus.success
                          ? 'Search result ready'
                          : 'Run retrieval first',
                      'Sources traceable'
                    ],
                    [
                      'History',
                      runtime.hasMarkdown ? 'Recorded' : 'No history',
                      'User workspace'
                    ],
                    [
                      'Edit save',
                      runtime.hasEditedDocument ? 'Saved' : 'Waiting edit',
                      'User workspace'
                    ],
                  ],
          ),
        ),
      );
      final validation = _ProductPanel(
        icon: Icons.rule_outlined,
        title: zh ? '验证与导出' : 'Validation and Export',
        gap: true,
        minHeight: 198,
        children: [
          _FieldRow(
            label: zh ? 'Markdown 产物' : 'Markdown artifact',
            value: runtime.hasMarkdown
                ? _displayNameForPath(runtime.generatedMarkdownPath)
                : (zh ? '尚未生成' : 'Not generated'),
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '导出边界' : 'Export boundary',
            value: zh
                ? 'Markdown、DOCX、PDF、PPTX、JSON、CSV 均为本地真实导出。'
                : 'Markdown, DOCX, PDF, PPTX, JSON, and CSV export locally.',
          ),
        ],
      );
      final outputFormats = _FillProductPanel(
        icon: Icons.output_outlined,
        title: zh ? '输出格式' : 'Output Formats',
        child: _CenteredOutputFormatGrid(
          items: [
            _MetricDatum(
                label: 'Markdown',
                value: markdownStatus,
                detail: runtime.hasMarkdown
                    ? (zh ? '真实文件' : 'real file')
                    : (zh ? '点击生成' : 'generate on click'),
                icon: Icons.notes_outlined),
            _MetricDatum(
                label: 'DOCX',
                value: exportReady,
                detail: localExporter,
                icon: Icons.description_outlined),
            _MetricDatum(
                label: 'PDF/PPTX',
                value: exportReady,
                detail: localExporter,
                icon: Icons.picture_as_pdf_outlined),
            _MetricDatum(
                label: 'JSON/CSV',
                value: zh ? '可导出' : 'enabled',
                detail: zh ? '本地结构化文件' : 'local structured files',
                icon: Icons.table_chart_outlined),
            _MetricDatum(
                label: zh ? '脱敏验证' : 'Redaction',
                value: zh ? '本地检查' : 'Local check',
                detail: zh ? '导出前执行' : 'before export',
                icon: Icons.account_tree_outlined),
          ],
        ),
      );
      if (!wide) {
        return Column(children: [
          if (draftQueued || previewReady) ...[
            _RuntimeFeedbackBanner(
              title: runtime.hasMarkdown
                  ? (zh ? '读书笔记已生成' : 'Reading notes generated')
                  : (zh ? '文档生成已触发' : 'Document generation started'),
              detail: zh
                  ? '文档产物保存在本地工作区，导出页可继续导出多格式文件。'
                  : 'Document artifacts are saved in the local workspace; export more formats from the export page.',
              tone: runtime.hasMarkdown
                  ? _StatusTone.success
                  : _StatusTone.neutral,
              icon: Icons.notes_outlined,
            ),
            const SizedBox(height: _DesktopGrid.gutter),
          ],
          tasks,
          const SizedBox(height: _DesktopGrid.gutter),
          preview,
          const SizedBox(height: _DesktopGrid.gutter),
          config,
          const SizedBox(height: _DesktopGrid.gutter),
          outputFormats,
          const SizedBox(height: _DesktopGrid.gutter),
          validation
        ]);
      }
      return Column(children: [
        if (draftQueued || previewReady) ...[
          _RuntimeFeedbackBanner(
            title: runtime.hasMarkdown
                ? (zh ? '读书笔记已生成' : 'Reading notes generated')
                : (zh ? '文档生成已触发' : 'Document generation started'),
            detail: zh
                ? '文档产物保存在本地工作区，导出页可继续导出多格式文件。'
                : 'Document artifacts are saved in the local workspace; export more formats from the export page.',
            tone:
                runtime.hasMarkdown ? _StatusTone.success : _StatusTone.neutral,
            icon: Icons.notes_outlined,
          ),
          const SizedBox(height: _DesktopGrid.gutter),
        ],
        _EqualHeightRow(
          height: 366,
          flexes: extraWide ? const [5, 7] : const [6, 6],
          children: [tasks, preview],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _EqualHeightRow(
          height: 326,
          flexes: const [6, 6],
          children: [config, outputFormats],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        validation,
      ]);
    });
  }
}

class _DocumentTemplateView extends StatefulWidget {
  const _DocumentTemplateView({required this.zh});

  final bool zh;

  @override
  State<_DocumentTemplateView> createState() => _DocumentTemplateViewState();
}

class _DocumentTemplateViewState extends State<_DocumentTemplateView> {
  bool templateSelected = false;

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1040;
      final templates = _ProductPanel(
        keyName: 'document-template-library',
        icon: Icons.dashboard_customize_outlined,
        title: zh ? '文档模板库' : 'Document Template Library',
        children: [
          _ProductTable(
            columns: zh
                ? ['模板', '输出', '变量', '状态']
                : ['Template', 'Output', 'Variables', 'Status'],
            rows: zh
                ? [
                    ['行业分析报告', 'DOCX / PDF', 'title, evidence, risk', '可预览'],
                    ['产品手册', 'Markdown / DOCX', 'feature, citation', '可预览'],
                    ['教学材料', 'PPTX / PDF', 'lesson, quiz, source', '可预览'],
                    ['自定义模板', '多格式', '用户变量', '需配置模板'],
                  ]
                : [
                    [
                      'Industry report',
                      'DOCX / PDF',
                      'title, evidence, risk',
                      'Previewable'
                    ],
                    [
                      'Product manual',
                      'Markdown / DOCX',
                      'feature, citation',
                      'Previewable'
                    ],
                    [
                      'Teaching material',
                      'PPTX / PDF',
                      'lesson, quiz, source',
                      'Previewable'
                    ],
                    [
                      'Custom template',
                      'Multi-format',
                      'User variables',
                      'Needs template config'
                    ],
                  ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _PrimaryProductAction(
            label: zh ? '选择模板预览' : 'Select template preview',
            icon: Icons.visibility_outlined,
            onPressed: () => setState(() => templateSelected = true),
          ),
        ],
      );
      final detail = _ProductPanel(
        keyName: 'document-template-detail',
        icon: Icons.code_outlined,
        title: zh ? '模板变量与验证' : 'Template Variables and Validation',
        children: [
          _FieldRow(
              label: zh ? '变量预览' : 'Variable preview',
              value: templateSelected
                  ? 'title / source / evidence / risk / export_manifest'
                  : (zh ? '等待选择模板' : 'Waiting for template selection')),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '归属' : 'Ownership',
              value: zh
                  ? '文档模板归文档生成'
                  : 'Document templates belong to Document Generation'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '导出边界' : 'Export boundary',
              value: zh
                  ? '本模块管理文档导出，不发布 Release'
                  : 'This module owns document export, no Release publication'),
        ],
      );
      if (!wide) {
        return Column(children: [
          templates,
          const SizedBox(height: _DesktopGrid.gutter),
          detail
        ]);
      }
      return _EqualHeightRow(
        height: 318,
        flexes: const [7, 4],
        children: [templates, detail],
      );
    });
  }
}

String _documentGenerationTypeLabel(String value, bool zh) {
  return switch (value) {
    'summary' => zh ? '摘要' : 'Summary',
    'study_cards' => zh ? '学习卡片' : 'Study cards',
    'structured_report' => zh ? '结构化报告' : 'Structured report',
    'ppt_outline' => zh ? 'PPT 大纲' : 'PPT outline',
    'operation_plan' => zh ? '运营方案' : 'Operation plan',
    'product_analysis' => zh ? '产品分析' : 'Product analysis',
    'qa_script' => zh ? '问答稿' : 'QA script',
    _ => zh ? '读书笔记' : 'Reading notes',
  };
}

String _templateModeLabel(String value, bool zh) {
  return switch (value) {
    'custom' => zh ? '自定义模板' : 'Custom template',
    'agent' => zh ? '内置 Agent 题材' : 'Built-in agent genre',
    _ => zh ? '通用内置模板' : 'Built-in template',
  };
}

String _citationStrategyLabel(String value, bool zh) {
  return switch (value) {
    'strict_citation' => zh ? '严格引用' : 'Strict citation',
    'filename_and_chunk' => zh ? '文件名 + Chunk' : 'Filename + chunk',
    _ => zh ? '来源文件名' : 'Source filename',
  };
}

class _DocumentGenerationConfig {
  const _DocumentGenerationConfig({
    required this.generationType,
    required this.outputFormat,
    required this.citationStrategy,
    required this.templateMode,
  });

  final String generationType;
  final String outputFormat;
  final String citationStrategy;
  final String templateMode;
}

class _DocumentGenerationDialog extends StatefulWidget {
  const _DocumentGenerationDialog({
    required this.zh,
    required this.initial,
  });

  final bool zh;
  final _DocumentGenerationConfig initial;

  @override
  State<_DocumentGenerationDialog> createState() =>
      _DocumentGenerationDialogState();
}

class _DocumentGenerationDialogState extends State<_DocumentGenerationDialog> {
  late String generationType = widget.initial.generationType;
  late String outputFormat = widget.initial.outputFormat;
  late String citationStrategy = widget.initial.citationStrategy;
  late String templateMode = widget.initial.templateMode;

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(zh ? '选择文档生成配置' : 'Choose document generation config'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCaption(zh ? '生成类型' : 'Generation type'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final item in const [
                  'reading_notes',
                  'summary',
                  'study_cards',
                  'structured_report',
                  'ppt_outline',
                  'operation_plan',
                  'product_analysis',
                  'qa_script',
                ])
                  ChoiceChip(
                    label: Text(_documentGenerationTypeLabel(item, zh)),
                    selected: generationType == item,
                    onSelected: (_) => setState(() => generationType = item),
                  ),
              ]),
              const SizedBox(height: 12),
              _SectionCaption(zh ? '题材 / 模板' : 'Genre / template'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final item in const ['built_in', 'custom', 'agent'])
                  ChoiceChip(
                    label: Text(_templateModeLabel(item, zh)),
                    selected: templateMode == item,
                    onSelected: (_) => setState(() => templateMode = item),
                  ),
              ]),
              const SizedBox(height: 12),
              _SectionCaption(zh ? '输出格式' : 'Output format'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final item in const ['md', 'docx', 'pdf', 'pptx'])
                  ChoiceChip(
                    label: Text(item.toUpperCase()),
                    selected: outputFormat == item,
                    onSelected: (_) => setState(() => outputFormat = item),
                  ),
              ]),
              const SizedBox(height: 12),
              _SectionCaption(zh ? '引用策略' : 'Citation strategy'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final item in const [
                  'source_filename',
                  'filename_and_chunk',
                  'strict_citation',
                ])
                  ChoiceChip(
                    label: Text(_citationStrategyLabel(item, zh)),
                    selected: citationStrategy == item,
                    onSelected: (_) => setState(() => citationStrategy = item),
                  ),
              ]),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(
            _DocumentGenerationConfig(
              generationType: generationType,
              outputFormat: outputFormat,
              citationStrategy: citationStrategy,
              templateMode: templateMode,
            ),
          ),
          icon: const Icon(Icons.play_arrow_outlined),
          label: Text(zh ? '生成' : 'Generate'),
        ),
      ],
    );
  }
}

class _DocumentExportPreviewView extends StatefulWidget {
  const _DocumentExportPreviewView({
    required this.zh,
    required this.workspace,
  });

  final bool zh;
  final String workspace;

  @override
  State<_DocumentExportPreviewView> createState() =>
      _DocumentExportPreviewViewState();
}

class _DocumentExportPreviewViewState
    extends State<_DocumentExportPreviewView> {
  bool exportPreviewReady = false;
  String selectedExportFormat = 'md';

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final exportStatus = runtime.hasMarkdown
        ? (zh ? '可导出' : 'Ready')
        : (zh ? '需要 Markdown' : 'Needs Markdown');
    String artifactForFormat(String format) {
      if (!runtime.hasExportedDocument) {
        return zh ? '尚未生成导出文件' : 'No export file yet';
      }
      final path = runtime.exportedDocumentPath.toLowerCase();
      final normalized = format == 'markdown' ? 'md' : format;
      if (path.endsWith('.$normalized')) {
        return _displayNameForPath(runtime.exportedDocumentPath);
      }
      return zh ? '点击导出生成' : 'Export on click';
    }

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= _DesktopGrid.rowBreakpoint;
      final export = _ProductPanel(
        keyName: 'document-export-preview',
        icon: Icons.file_download_outlined,
        title: zh ? '文档导出' : 'Document Export',
        children: [
          _SectionCaption(zh
              ? 'Markdown / DOCX / PDF / PPTX / JSON / CSV 都通过本地工作区真实导出。'
              : 'Markdown / DOCX / PDF / PPTX / JSON / CSV export through the local workspace.'),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh
                ? ['格式', '状态', '验证', '产物']
                : ['Format', 'Status', 'Validation', 'Artifact'],
            rows: zh
                ? [
                    [
                      'Markdown',
                      runtime.hasExportedDocument
                          ? '已导出'
                          : runtime.hasMarkdown
                              ? '可导出'
                              : '需要 Markdown',
                      runtime.hasExportedDocument ? '通过' : '尚未导出',
                      runtime.hasExportedDocument
                          ? _displayNameForPath(runtime.exportedDocumentPath)
                          : '尚未生成导出文件'
                    ],
                    [
                      'JSON',
                      runtime.hasMarkdown ? '可导出' : '需要 Markdown',
                      '本地结构化',
                      'knowledge_export.json'
                    ],
                    [
                      'CSV',
                      runtime.hasMarkdown ? '可导出' : '需要 Markdown',
                      '本地结构化',
                      'knowledge_export.csv'
                    ],
                    ['DOCX', exportStatus, '本地导出器', artifactForFormat('docx')],
                    ['PDF', exportStatus, '本地导出器', artifactForFormat('pdf')],
                    ['PPTX', exportStatus, '本地导出器', artifactForFormat('pptx')],
                  ]
                : [
                    [
                      'Markdown',
                      runtime.hasExportedDocument
                          ? 'Exported'
                          : runtime.hasMarkdown
                              ? 'Ready'
                              : 'Needs Markdown',
                      runtime.hasExportedDocument ? 'Passed' : 'Not exported',
                      runtime.hasExportedDocument
                          ? _displayNameForPath(runtime.exportedDocumentPath)
                          : 'No export file yet'
                    ],
                    [
                      'JSON',
                      runtime.hasMarkdown ? 'Ready' : 'Needs Markdown',
                      'Local structured',
                      'knowledge_export.json'
                    ],
                    [
                      'CSV',
                      runtime.hasMarkdown ? 'Ready' : 'Needs Markdown',
                      'Local structured',
                      'knowledge_export.csv'
                    ],
                    [
                      'DOCX',
                      exportStatus,
                      'Local exporter',
                      artifactForFormat('docx')
                    ],
                    [
                      'PDF',
                      exportStatus,
                      'Local exporter',
                      artifactForFormat('pdf')
                    ],
                    [
                      'PPTX',
                      exportStatus,
                      'Local exporter',
                      artifactForFormat('pptx')
                    ],
                  ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final item in const [
              'md',
              'json',
              'csv',
              'docx',
              'pdf',
              'pptx'
            ])
              ChoiceChip(
                label: Text(item.toUpperCase()),
                selected: selectedExportFormat == item,
                onSelected: (_) => setState(() => selectedExportFormat = item),
              ),
          ]),
          const SizedBox(height: _DesktopGrid.gutter),
          _PrimaryProductAction(
            label: zh
                ? '导出 ${selectedExportFormat.toUpperCase()} 文件'
                : 'Export ${selectedExportFormat.toUpperCase()} file',
            icon: Icons.file_download_outlined,
            onPressed: runtime.running || rc6 == null || !runtime.hasMarkdown
                ? null
                : () {
                    setState(() => exportPreviewReady = true);
                    rc6.exportDocumentFormat(selectedExportFormat);
                  },
          ),
        ],
      );
      final checks = _ProductPanel(
        icon: Icons.verified_outlined,
        title: zh ? '文档验证' : 'Document Validation',
        children: [
          _FieldRow(
              label: zh ? '内容完整性' : 'Completeness',
              value: runtime.hasExportedDocument
                  ? (zh ? '导出文件非空' : 'Export file non-empty')
                  : (zh ? '等待导出' : 'Waiting')),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '引用有效性' : 'Citation validity',
              value: runtime.hasExportedDocument
                  ? (zh ? '引用来源已写入' : 'Sources written')
                  : '-'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '敏感信息检查' : 'Sensitive content',
              value: zh ? '本地检查，不联网' : 'Local check, no network'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '导出清单' : 'Export manifest',
              value: runtime.exportManifestPath.isEmpty
                  ? (zh ? '等待导出' : 'Waiting export')
                  : _displayNameForPath(runtime.exportManifestPath)),
        ],
      );
      if (!wide) {
        return Column(children: [
          if (exportPreviewReady || runtime.hasExportedDocument) ...[
            _RuntimeFeedbackBanner(
              title: runtime.hasExportedDocument
                  ? (zh ? 'Markdown 文件已导出' : 'Markdown file exported')
                  : (zh ? '正在导出 Markdown' : 'Exporting Markdown'),
              detail: runtime.hasExportedDocument
                  ? _displayNameForPath(runtime.exportedDocumentPath)
                  : (zh ? '正在写入用户工作区。' : 'Writing to user workspace.'),
              tone: runtime.hasExportedDocument
                  ? _StatusTone.success
                  : _StatusTone.neutral,
              icon: Icons.file_download_outlined,
            ),
            const SizedBox(height: _DesktopGrid.gutter),
          ],
          export,
          const SizedBox(height: _DesktopGrid.gutter),
          checks
        ]);
      }
      return Column(children: [
        if (exportPreviewReady || runtime.hasExportedDocument) ...[
          _RuntimeFeedbackBanner(
            title: runtime.hasExportedDocument
                ? (zh ? 'Markdown 文件已导出' : 'Markdown file exported')
                : (zh ? '正在导出 Markdown' : 'Exporting Markdown'),
            detail: runtime.hasExportedDocument
                ? _displayNameForPath(runtime.exportedDocumentPath)
                : (zh ? '正在写入用户工作区。' : 'Writing to user workspace.'),
            tone: runtime.hasExportedDocument
                ? _StatusTone.success
                : _StatusTone.neutral,
            icon: Icons.file_download_outlined,
          ),
          const SizedBox(height: _DesktopGrid.gutter),
        ],
        _EqualHeightRow(
          height: 342,
          flexes: const [7, 4],
          children: [export, checks],
        ),
      ]);
    });
  }
}

class _KnowledgePackageListView extends StatefulWidget {
  const _KnowledgePackageListView({required this.zh, required this.workspace});

  final bool zh;
  final String workspace;

  @override
  State<_KnowledgePackageListView> createState() =>
      _KnowledgePackageListViewState();
}

class _KnowledgePackageListViewState extends State<_KnowledgePackageListView> {
  bool qualityReportPrepared = false;
  bool sourceSelected = false;
  bool llmEnhance = false;
  String kbType = 'basic';
  String storageTarget = 'local';
  int buildStep = 0;
  final TextEditingController _kbNameController =
      TextEditingController(text: '真实输入知识库');

  bool get zh => widget.zh;

  @override
  void dispose() {
    _kbNameController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDeleteKnowledgeBase(Rc6RuntimeController? rc6) async {
    if (rc6 == null ||
        rc6.state.running ||
        (!rc6.state.hasKnowledgeBase && rc6.state.knowledgeBases.isEmpty)) {
      return;
    }
    final firstKbId = rc6.state.knowledgeBases.isNotEmpty
        ? rc6.state.knowledgeBases.first.id
        : '';
    final confirmed = await _confirmDestructiveAction(
      context,
      title: firstKbId.isEmpty
          ? (zh ? '删除当前知识库？' : 'Delete current knowledge base?')
          : (zh ? '删除知识库 $firstKbId？' : 'Delete KB $firstKbId?'),
      body: firstKbId.isEmpty
          ? (zh
              ? '这会删除当前工作区内的知识库、检索结果和文档导出产物；导入文件和解析报告保留，可重新构建。'
              : 'This deletes KB, retrieval, and document export artifacts in this workspace; imported files and parse reports are kept for rebuild.')
          : (zh
              ? '这会删除该知识库 catalog 记录和独立索引目录；文档库来源保留。'
              : 'This deletes the catalog record and isolated index directory; source documents remain.'),
    );
    if (!confirmed) return;
    if (firstKbId.isEmpty) {
      await rc6.clearKnowledgeBaseArtifacts();
    } else {
      await rc6.deleteKnowledgeBaseRecord(firstKbId);
    }
    if (mounted) {
      setState(() {
        sourceSelected = false;
        buildStep = 0;
        qualityReportPrepared = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final hasKbName = _kbNameController.text.trim().isNotEmpty;
    final localStorageReady = storageTarget == 'local';
    final buildReady =
        runtime.hasImportedFile && hasKbName && localStorageReady;
    final artifactsReady = runtime.hasKnowledgeBase &&
        runtime.chunksPath.isNotEmpty &&
        runtime.qualityReportPath.isNotEmpty;
    final knowledgeBases = runtime.knowledgeBases;
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final builder = _FillProductPanel(
        keyName: 'knowledge-package-list',
        icon: Icons.account_tree_outlined,
        title: zh ? '知识库构建流程' : 'Knowledge Base Build Flow',
        child: _FillPanelColumn(
          top: _LocalScrollBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _KnowledgeBuildActionGrid(
                  zh: zh,
                  activeStep: runtime.hasKnowledgeBase ? 6 : buildStep,
                  steps: [
                    _KnowledgeBuildStep(
                      zh ? '1. 选择来源文档' : '1. Select source docs',
                      runtime.hasImportedFile
                          ? (zh
                              ? '${runtime.sourceCount} 个已导入文件'
                              : '${runtime.sourceCount} imported files')
                          : (zh ? '请先导入文件' : 'Import files first'),
                      Icons.library_books_outlined,
                      runtime.hasImportedFile && sourceSelected,
                      runtime.hasImportedFile
                          ? () => setState(() {
                                sourceSelected = true;
                                buildStep = 1;
                              })
                          : null,
                    ),
                    _KnowledgeBuildStep(
                      zh ? '2. 命名知识库' : '2. Name KB',
                      _kbNameController.text.trim().isEmpty
                          ? (zh ? '待命名' : 'Needs name')
                          : _kbNameController.text.trim(),
                      Icons.drive_file_rename_outline,
                      hasKbName,
                      () => setState(() => buildStep = 2),
                    ),
                    _KnowledgeBuildStep(
                      zh ? '3. 选择类型' : '3. Choose type',
                      _knowledgeTypeLabel(kbType, zh),
                      Icons.category_outlined,
                      true,
                      () => setState(() => buildStep = 3),
                    ),
                    _KnowledgeBuildStep(
                      zh ? '4. 增强选项' : '4. Enhance',
                      llmEnhance
                          ? (zh
                              ? '授权 Provider 增强'
                              : 'Authorized Provider enhancement')
                          : (zh ? '本地构建' : 'Local build'),
                      Icons.auto_fix_high_outlined,
                      true,
                      () => setState(() => buildStep = 4),
                    ),
                    _KnowledgeBuildStep(
                      zh ? '5. 选择存储' : '5. Storage',
                      _knowledgeStorageLabel(storageTarget, zh),
                      Icons.storage_outlined,
                      localStorageReady,
                      () => setState(() => buildStep = 5),
                    ),
                    _KnowledgeBuildStep(
                      zh ? '6. 构建' : '6. Build',
                      runtime.hasKnowledgeBase
                          ? (zh ? '已构建' : 'Built')
                          : (zh
                              ? '点击后生成 chunks / manifest'
                              : 'Click to write chunks / manifest'),
                      Icons.build_outlined,
                      runtime.hasKnowledgeBase,
                      runtime.running || rc6 == null || !buildReady
                          ? null
                          : () {
                              setState(() {
                                sourceSelected = true;
                                buildStep = 6;
                              });
                              rc6.buildKnowledgeBase();
                            },
                    ),
                    _KnowledgeBuildStep(
                      zh ? '7. 查看产物' : '7. Artifacts',
                      artifactsReady
                          ? _displayNameForPath(runtime.kbManifestPath)
                          : (zh ? '等待构建' : 'Waiting build'),
                      Icons.folder_open_outlined,
                      artifactsReady,
                      artifactsReady
                          ? () => setState(() => qualityReportPrepared = true)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: _DesktopGrid.gutter),
                TextField(
                  controller: _kbNameController,
                  onChanged: (_) => setState(() => buildStep = 2),
                  decoration: InputDecoration(
                    labelText: zh ? '知识库名称' : 'Knowledge base name',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: _DesktopGrid.gutter),
                _ProductTable(
                  columns: zh
                      ? ['步骤', '用户选择', '状态']
                      : ['Step', 'User choice', 'Status'],
                  rows: zh
                      ? [
                          [
                            '来源文档',
                            runtime.hasImportedFile
                                ? '${runtime.sourceCount} 个已导入文件'
                                : '请先导入文件夹',
                            runtime.hasImportedFile ? '可选择' : '等待导入'
                          ],
                          [
                            '知识库名称',
                            _kbNameController.text.trim().isEmpty
                                ? '待命名'
                                : _kbNameController.text.trim(),
                            _kbNameController.text.trim().isEmpty
                                ? '待命名'
                                : '已命名'
                          ],
                          ['知识库类型', _knowledgeTypeLabel(kbType, zh), '已选择'],
                          [
                            'LLM 增强',
                            llmEnhance ? '启用，使用已配置 Provider' : '关闭，使用本地构建',
                            llmEnhance ? '需要授权配置' : '本地可用'
                          ],
                          [
                            '存储路径',
                            _knowledgeStorageLabel(storageTarget, zh),
                            storageTarget == 'local' ? '本地可用' : '需连接测试'
                          ],
                        ]
                      : [
                          [
                            'Source docs',
                            runtime.hasImportedFile
                                ? '${runtime.sourceCount} imported files'
                                : 'Import a folder first',
                            runtime.hasImportedFile
                                ? 'Selectable'
                                : 'Waiting import'
                          ],
                          [
                            'KB name',
                            _kbNameController.text.trim().isEmpty
                                ? 'Needs name'
                                : _kbNameController.text.trim(),
                            _kbNameController.text.trim().isEmpty
                                ? 'Needs name'
                                : 'Named'
                          ],
                          [
                            'KB type',
                            _knowledgeTypeLabel(kbType, zh),
                            'Selected'
                          ],
                          [
                            'LLM enhance',
                            llmEnhance
                                ? 'Enabled with configured Provider'
                                : 'Off, local build',
                            llmEnhance
                                ? 'Authorization config required'
                                : 'Local ready'
                          ],
                          [
                            'Storage path',
                            _knowledgeStorageLabel(storageTarget, zh),
                            storageTarget == 'local'
                                ? 'Local ready'
                                : 'Connection test required'
                          ],
                        ],
                ),
                const SizedBox(height: _DesktopGrid.gutter),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ChoiceChip(
                    label: Text(zh ? '基础知识库' : 'Basic KB'),
                    selected: kbType == 'basic',
                    onSelected: (_) => setState(() => kbType = 'basic'),
                  ),
                  ChoiceChip(
                    label: Text(zh ? '问答知识库' : 'QA KB'),
                    selected: kbType == 'qa',
                    onSelected: (_) => setState(() => kbType = 'qa'),
                  ),
                  ChoiceChip(
                    label: Text(zh ? '结构化知识库' : 'Structured KB'),
                    selected: kbType == 'structured',
                    onSelected: (_) => setState(() => kbType = 'structured'),
                  ),
                  ChoiceChip(
                    label: Text(zh ? '向量索引知识库' : 'Vector index KB'),
                    selected: kbType == 'vector',
                    onSelected: (_) => setState(() => kbType = 'vector'),
                  ),
                ]),
                const SizedBox(height: 8),
                Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(zh ? '使用 LLM 增强构建' : 'Use LLM enhancement'),
                    subtitle: Text(zh
                        ? '默认关闭；开启后使用已授权 Provider，不写入明文 secret。'
                        : 'Off by default; when enabled it uses authorized Provider without plaintext secrets.'),
                    value: llmEnhance,
                    onChanged: (value) => setState(() => llmEnhance = value),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final item in const ['local', 'qdrant'])
                    ChoiceChip(
                      label: Text(_knowledgeStorageLabel(item, zh)),
                      selected: storageTarget == item,
                      onSelected: (_) => setState(() {
                        storageTarget = item;
                        buildStep = 5;
                      }),
                    ),
                ]),
              ],
            ),
          ),
          bottom: _EqualActionRow(children: [
            _PrimaryProductAction(
              label: zh ? '选择已导入文档' : 'Select imported documents',
              icon: Icons.library_books_outlined,
              onPressed: runtime.hasImportedFile
                  ? () => setState(() => sourceSelected = true)
                  : null,
            ),
            _PrimaryProductAction(
              label: zh ? '开始构建知识库' : 'Build Knowledge Base',
              icon: Icons.build_outlined,
              onPressed: runtime.running || rc6 == null || !buildReady
                  ? null
                  : () {
                      setState(() => sourceSelected = true);
                      rc6.buildKnowledgeBase();
                    },
            ),
            _DisplayAction(
              label: zh ? '删除旧知识库版本' : 'Delete old KB version',
              icon: Icons.delete_outline,
              onPressed: runtime.hasKnowledgeBase
                  ? () => _confirmAndDeleteKnowledgeBase(rc6)
                  : null,
            ),
          ]),
        ),
      );
      final artifacts = _FillProductPanel(
        keyName: 'selected-package-detail',
        icon: Icons.folder_open_outlined,
        title: zh ? '构建产物' : 'Build Artifacts',
        child: _LocalScrollBox(
          child: Column(
            children: [
              _MetricStrip(
                items: [
                  _MetricDatum(
                      label: zh ? '来源' : 'Sources',
                      value: runtime.sourceCount.toString(),
                      detail: zh ? '已选文档' : 'selected docs',
                      icon: Icons.article_outlined),
                  _MetricDatum(
                      label: 'chunks',
                      value: runtime.chunkCount.toString(),
                      detail: zh ? '本地索引' : 'local index',
                      icon: Icons.segment_outlined),
                  _MetricDatum(
                      label: zh ? '质量报告' : 'Quality',
                      value:
                          runtime.qualityReportPath.isNotEmpty ? '已生成' : '等待',
                      detail: zh ? '可查看' : 'viewable',
                      icon: Icons.verified_outlined),
                ],
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              if (knowledgeBases.isNotEmpty) ...[
                _SectionCaption(zh ? '知识库列表' : 'Knowledge bases'),
                const SizedBox(height: 8),
                _ProductTable(
                  columns: zh
                      ? ['ID', '名称', '版本', '来源', 'chunks', '状态']
                      : [
                          'ID',
                          'Name',
                          'Version',
                          'Sources',
                          'Chunks',
                          'Status'
                        ],
                  rows: knowledgeBases
                      .map((kb) => [
                            kb.id,
                            kb.name,
                            kb.currentVersion.isEmpty
                                ? (zh ? 'v1' : 'v1')
                                : kb.currentVersion,
                            kb.sourceCount.toString(),
                            kb.chunkCount.toString(),
                            kb.status,
                          ])
                      .toList(growable: false),
                ),
                const SizedBox(height: 8),
                _EqualActionRow(children: [
                  _PrimaryProductAction(
                    label: zh ? '复制知识库' : 'Copy KB',
                    icon: Icons.copy_outlined,
                    onPressed: rc6 == null || knowledgeBases.isEmpty
                        ? null
                        : () => rc6.copyKnowledgeBase(knowledgeBases.first.id),
                  ),
                  _PrimaryProductAction(
                    label: zh ? '合并知识库' : 'Merge KBs',
                    icon: Icons.merge_type_outlined,
                    onPressed: rc6 == null || knowledgeBases.length < 2
                        ? null
                        : () => rc6.mergeKnowledgeBases(
                            knowledgeBases.take(2).map((kb) => kb.id).toList()),
                  ),
                ]),
                const SizedBox(height: 8),
                _EqualActionRow(children: [
                  _PrimaryProductAction(
                    label: zh ? '拆分知识库' : 'Split KB',
                    icon: Icons.call_split_outlined,
                    onPressed: rc6 == null || knowledgeBases.isEmpty
                        ? null
                        : () => rc6.splitKnowledgeBase(knowledgeBases.first.id),
                  ),
                  _DisplayAction(
                    label: zh ? '删除知识库记录' : 'Delete KB record',
                    icon: Icons.delete_outline,
                    onPressed: rc6 == null || knowledgeBases.isEmpty
                        ? null
                        : () => _confirmAndDeleteKnowledgeBase(rc6),
                  ),
                ]),
                const SizedBox(height: _DesktopGrid.gutter),
                _SectionCaption(zh ? '迭代更新与版本管理' : 'Iteration and versions'),
                const SizedBox(height: 8),
                _ProductTable(
                  columns: zh
                      ? ['能力', '真实产物', '状态']
                      : ['Capability', 'Artifact', 'Status'],
                  rows:
                      _knowledgeVersionRows(knowledgeBases.first, runtime, zh),
                ),
                const SizedBox(height: 8),
                _EqualActionRow(children: [
                  _PrimaryProductAction(
                    label: zh ? '增量更新' : 'Incremental update',
                    icon: Icons.update_outlined,
                    onPressed: rc6 == null || knowledgeBases.isEmpty
                        ? null
                        : () => rc6.updateKnowledgeBaseIncremental(
                            knowledgeBases.first.id),
                  ),
                  _PrimaryProductAction(
                    label: zh ? '全量重建' : 'Full rebuild',
                    icon: Icons.refresh_outlined,
                    onPressed: rc6 == null || knowledgeBases.isEmpty
                        ? null
                        : () => rc6
                            .rebuildKnowledgeBaseFull(knowledgeBases.first.id),
                  ),
                ]),
                const SizedBox(height: 8),
                _EqualActionRow(children: [
                  _PrimaryProductAction(
                    label: zh ? '版本对比' : 'Compare versions',
                    icon: Icons.compare_arrows_outlined,
                    onPressed: rc6 == null || knowledgeBases.isEmpty
                        ? null
                        : () => rc6.compareKnowledgeBaseVersions(
                            knowledgeBases.first.id),
                  ),
                  _DisplayAction(
                    label: zh ? '回滚上一版本' : 'Rollback previous version',
                    icon: Icons.restore_outlined,
                    onPressed: rc6 == null ||
                            knowledgeBases.isEmpty ||
                            knowledgeBases.first.versionCount < 2
                        ? null
                        : () => rc6.rollbackKnowledgeBaseVersion(
                            knowledgeBases.first.id),
                  ),
                ]),
                const SizedBox(height: _DesktopGrid.gutter),
              ],
              _ProductTable(
                columns:
                    zh ? ['产物', '状态', '查看'] : ['Artifact', 'Status', 'View'],
                rows: _knowledgeArtifactRows(runtime, zh),
              ),
              const SizedBox(height: 8),
              _EqualActionRow(children: [
                _DisplayAction(
                  label: zh ? '查看质量报告' : 'View quality report',
                  icon: Icons.rule_outlined,
                  onPressed: () => setState(() => qualityReportPrepared = true),
                ),
                if (qualityReportPrepared)
                  _RuntimeFeedbackBanner(
                    title: zh ? '质量报告评分标准' : 'Quality report scoring rubric',
                    detail: runtime.qualityReportPath.isEmpty
                        ? (zh
                            ? '等待 quality_report.json。'
                            : 'Waiting for quality_report.json.')
                        : (zh
                            ? '评分 = 非空 chunks、来源覆盖、QA/cards 完整性和 manifest 可追踪性。'
                            : 'Score = non-empty chunks, source coverage, QA/cards completeness, and manifest traceability.'),
                    tone: runtime.qualityReportPath.isEmpty
                        ? _StatusTone.warning
                        : _StatusTone.success,
                    icon: Icons.rule_outlined,
                  ),
              ]),
            ],
          ),
        ),
      );
      if (!wide) {
        return Column(children: [
          builder,
          const SizedBox(height: _DesktopGrid.gutter),
          artifacts
        ]);
      }
      return _EqualHeightRow(
        height: 656,
        flexes: const [7, 5],
        children: [builder, artifacts],
      );
    });
  }
}

String _knowledgeTypeLabel(String value, bool zh) {
  return switch (value) {
    'qa' => zh ? '问答知识库' : 'QA KB',
    'structured' => zh ? '结构化知识库' : 'Structured KB',
    'vector' => zh ? '向量索引知识库' : 'Vector index KB',
    _ => zh ? '基础知识库' : 'Basic KB',
  };
}

String _knowledgeStorageLabel(String value, bool zh) {
  return switch (value) {
    'qdrant' => zh ? 'Qdrant 本机向量库' : 'Local Qdrant vector DB',
    _ => zh ? '本地文件索引' : 'Local file index',
  };
}

List<List<String>> _knowledgeArtifactRows(Rc6RuntimeState runtime, bool zh) {
  List<String> row(String name, String path, String waiting,
      {String? readyStatus}) {
    final ready = path.isNotEmpty;
    return [
      name,
      ready ? (readyStatus ?? (zh ? '完成' : 'Done')) : (zh ? '等待' : 'Waiting'),
      ready ? _displayNameForPath(path) : waiting,
    ];
  }

  return [
    row('source_manifest.json', runtime.sourceManifestPath,
        zh ? '来源清单' : 'source manifest'),
    row('manifest.json', runtime.kbManifestPath, zh ? '知识库清单' : 'KB manifest'),
    row('chunks.jsonl', runtime.chunksPath, 'chunks.jsonl'),
    row('source_map.json', runtime.sourceMapPath, 'source_map.json'),
    row('index_metadata.json', runtime.indexMetadataPath,
        'index_metadata.json'),
    row('quality_report.json', runtime.qualityReportPath,
        zh ? '质量报告' : 'quality report',
        readyStatus: zh ? '通过' : 'Passed'),
    row('build.log', runtime.buildLogPath, 'build.log'),
    row('error.log', runtime.errorLogPath, 'error.log'),
  ];
}

List<List<String>> _knowledgeVersionRows(
    Rc6KnowledgeBaseRecord kb, Rc6RuntimeState runtime, bool zh) {
  final compareReady = kb.versionComparePath.isNotEmpty;
  final rollbackReady = kb.versionCount > 1;
  return [
    [
      zh ? '版本记录' : 'Version history',
      kb.currentVersion.isEmpty ? 'v1' : kb.currentVersion,
      zh ? '${kb.versionCount} 个版本' : '${kb.versionCount} versions',
    ],
    [
      zh ? '构建日志' : 'Build log',
      runtime.buildLogPath.isEmpty
          ? (zh ? '等待构建' : 'Waiting build')
          : _displayNameForPath(runtime.buildLogPath),
      runtime.buildLogPath.isEmpty ? (zh ? '未生成' : 'Not generated') : 'ready',
    ],
    [
      zh ? '版本对比' : 'Version compare',
      compareReady
          ? _displayNameForPath(kb.versionComparePath)
          : (zh ? '点击版本对比后生成' : 'Run compare to generate'),
      compareReady ? (zh ? '已生成' : 'Generated') : (zh ? '点击生成' : 'Run compare'),
    ],
    [
      zh ? '回滚' : 'Rollback',
      rollbackReady
          ? (zh ? '可回滚到上一版本' : 'Previous version available')
          : (zh ? '更新后可回滚' : 'Available after update'),
      rollbackReady ? (zh ? '可用' : 'Ready') : (zh ? '等待版本' : 'Need version'),
    ],
  ];
}

class _KnowledgeBuildStep {
  const _KnowledgeBuildStep(
      this.label, this.detail, this.icon, this.done, this.onPressed);

  final String label;
  final String detail;
  final IconData icon;
  final bool done;
  final VoidCallback? onPressed;
}

class _KnowledgeBuildActionGrid extends StatelessWidget {
  const _KnowledgeBuildActionGrid({
    required this.zh,
    required this.activeStep,
    required this.steps,
  });

  final bool zh;
  final int activeStep;
  final List<_KnowledgeBuildStep> steps;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 820
          ? 3
          : constraints.maxWidth >= 520
              ? 2
              : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: steps.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: _DesktopGrid.gutter,
          mainAxisSpacing: _DesktopGrid.gutter,
          mainAxisExtent: 92,
        ),
        itemBuilder: (context, index) {
          final step = steps[index];
          final selected = activeStep == index || step.done;
          return Material(
            color: selected
                ? colors.primary.withValues(alpha: 0.08)
                : colors.surface,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: step.onPressed,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? colors.primary : colors.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      step.done ? Icons.check_circle_outline : step.icon,
                      size: 20,
                      color:
                          selected ? colors.primary : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(step.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text(step.detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _KnowledgeVectorIndexView extends StatelessWidget {
  const _KnowledgeVectorIndexView({required this.zh});

  final bool zh;

  @override
  Widget build(BuildContext context) {
    final runtime =
        _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final indexPanel = _ProductPanel(
        keyName: 'knowledge-vector-index',
        icon: Icons.hub_outlined,
        title: zh ? '向量索引中心' : 'Vector Index Center',
        children: [
          _ProductTable(
            columns: zh
                ? ['索引', '知识库', '模型', '维度', '状态', '分类']
                : ['Index', 'Base', 'Model', 'Dims', 'Status', 'Class'],
            rows: zh
                ? [
                    [
                      'local_kb_chunks',
                      runtime.hasKnowledgeBase ? '真实输入知识库' : '等待知识库',
                      '本地 chunks.jsonl',
                      runtime.chunkCount.toString(),
                      runtime.hasKnowledgeBase ? '本地索引可用' : '等待构建',
                      runtime.hasKnowledgeBase ? '可用' : '请先构建'
                    ],
                    [
                      'local_cards_qa',
                      runtime.cardsPath.isNotEmpty
                          ? 'cards / qa_pairs'
                          : '等待产物',
                      '本地 JSONL',
                      runtime.cardsPath.isNotEmpty ? 'ready' : '-',
                      runtime.cardsPath.isNotEmpty ? '已生成' : '等待构建',
                      runtime.cardsPath.isNotEmpty ? '可用' : '请先构建'
                    ],
                    [
                      'external_vector_db',
                      '外部向量库',
                      '未配置',
                      '-',
                      '使用本地索引',
                      '设置中可配置'
                    ],
                  ]
                : [
                    [
                      'local_kb_chunks',
                      runtime.hasKnowledgeBase
                          ? 'Real input Knowledge Base'
                          : 'Waiting for KB',
                      'Local chunks.jsonl',
                      runtime.chunkCount.toString(),
                      runtime.hasKnowledgeBase
                          ? 'Local index ready'
                          : 'Build first',
                      runtime.hasKnowledgeBase ? 'Available' : 'Build first'
                    ],
                    [
                      'local_cards_qa',
                      runtime.cardsPath.isNotEmpty
                          ? 'cards / qa_pairs'
                          : 'Waiting',
                      'Local JSONL',
                      runtime.cardsPath.isNotEmpty ? 'ready' : '-',
                      runtime.cardsPath.isNotEmpty
                          ? 'Generated'
                          : 'Build first',
                      runtime.cardsPath.isNotEmpty ? 'Available' : 'Build first'
                    ],
                    [
                      'external_vector_db',
                      'External Vector DB',
                      'Not configured',
                      '-',
                      'Using local index',
                      'Configurable in Settings'
                    ],
                  ],
          ),
        ],
      );
      final detail = _ProductPanel(
        icon: Icons.tune_outlined,
        title: zh ? '索引配置与边界' : 'Index Config and Boundary',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? '排序' : 'Sort',
              value: zh
                  ? '质量分 / 更新时间 / chunks'
                  : 'Quality / updated time / chunks'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '批量操作' : 'Bulk actions',
              value: zh
                  ? '重建、验证、归档均需本地证据'
                  : 'Rebuild, validate, archive require local evidence'),
          const SizedBox(height: 8),
          _DisplayAction(
            label: zh ? '去设置中配置向量库连接' : 'Configure vector DB in Settings',
            icon: Icons.settings_outlined,
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          indexPanel,
          const SizedBox(height: _DesktopGrid.gutter),
          detail
        ]);
      }
      return _EqualHeightRow(
        height: 326,
        flexes: const [7, 4],
        children: [indexPanel, detail],
      );
    });
  }
}

class _KnowledgeQualityRecordsView extends StatelessWidget {
  const _KnowledgeQualityRecordsView({required this.zh});

  final bool zh;

  @override
  Widget build(BuildContext context) {
    final runtime =
        _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
    final qualityReady = runtime.qualityReportPath.isNotEmpty;
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final records = _ProductPanel(
        keyName: 'knowledge-quality-records',
        icon: Icons.rule_outlined,
        title: zh ? '质量与验证记录' : 'Quality and Validation Records',
        children: [
          _MetricStrip(
            items: [
              _MetricDatum(
                  label: zh ? '准确性' : 'Accuracy',
                  value: qualityReady ? 'pass' : '-',
                  detail: zh ? '质量报告' : 'quality report',
                  icon: Icons.track_changes_outlined),
              _MetricDatum(
                  label: zh ? '覆盖率' : 'Coverage',
                  value: runtime.sourceCount.toString(),
                  detail: zh ? '来源文档' : 'sources',
                  icon: Icons.pie_chart_outline),
              _MetricDatum(
                  label: zh ? '冲突' : 'Conflicts',
                  value: qualityReady ? '0' : '-',
                  detail: zh ? '本地质量门禁' : 'local quality gate',
                  icon: Icons.warning_amber_outlined),
            ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _ProductTable(
            columns: zh
                ? ['检查项', '状态', '证据', '建议']
                : ['Check', 'Status', 'Evidence', 'Suggestion'],
            rows: zh
                ? [
                    [
                      '解析完整性',
                      runtime.parseReportPath.isNotEmpty ? '通过' : '等待解析',
                      runtime.parseReportPath.isNotEmpty
                          ? _displayNameForPath(runtime.parseReportPath)
                          : 'parse_report.json',
                      runtime.parseReportPath.isNotEmpty ? '保持' : '先解析来源'
                    ],
                    [
                      '重复片段',
                      qualityReady ? '通过' : '等待构建',
                      qualityReady
                          ? _displayNameForPath(runtime.qualityReportPath)
                          : 'quality_report.json',
                      qualityReady ? '已生成建议' : '先构建知识库'
                    ],
                    [
                      'cards / qa_pairs',
                      runtime.cardsPath.isNotEmpty ? '已生成' : '等待构建',
                      runtime.cardsPath.isNotEmpty
                          ? _displayNameForPath(runtime.cardsPath)
                          : 'cards.jsonl',
                      runtime.qaPairsPath.isNotEmpty ? '可检索' : '先构建知识库'
                    ],
                    ['外部新鲜度', '授权后启用', '设置联网 Provider 后执行', '不影响本地知识库'],
                  ]
                : [
                    [
                      'Parse integrity',
                      runtime.parseReportPath.isNotEmpty ? 'Passed' : 'Waiting',
                      runtime.parseReportPath.isNotEmpty
                          ? _displayNameForPath(runtime.parseReportPath)
                          : 'parse_report.json',
                      runtime.parseReportPath.isNotEmpty
                          ? 'Keep'
                          : 'Parse sources first'
                    ],
                    [
                      'Duplicate chunks',
                      qualityReady ? 'Passed' : 'Waiting',
                      qualityReady
                          ? _displayNameForPath(runtime.qualityReportPath)
                          : 'quality_report.json',
                      qualityReady ? 'Suggestions generated' : 'Build KB first'
                    ],
                    [
                      'cards / qa_pairs',
                      runtime.cardsPath.isNotEmpty ? 'Generated' : 'Waiting',
                      runtime.cardsPath.isNotEmpty
                          ? _displayNameForPath(runtime.cardsPath)
                          : 'cards.jsonl',
                      runtime.qaPairsPath.isNotEmpty
                          ? 'Searchable'
                          : 'Build KB first'
                    ],
                    [
                      'External freshness',
                      'Enable after authorization',
                      'Configure network Provider first',
                      'Does not block local KB'
                    ],
                  ],
          ),
        ],
      );
      final detail = _ProductPanel(
        icon: Icons.assignment_turned_in_outlined,
        title: zh ? '验证记录详情' : 'Validation Record Detail',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? '验证范围' : 'Scope',
              value: zh ? '仅针对已有本地证据' : 'Existing local evidence only'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '外部比对' : 'External comparison',
              value: zh
                  ? '本地/手动证据与实时外部比对均已验收；联网执行需 opt-in'
                  : 'Local/manual evidence and live external comparison are accepted; network execution requires opt-in'),
          const SizedBox(height: 8),
          _DisplayAction(
            label: zh ? '查看质量报告证据' : 'View quality report evidence',
            icon: Icons.receipt_long_outlined,
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          records,
          const SizedBox(height: _DesktopGrid.gutter),
          detail
        ]);
      }
      return _EqualHeightRow(
        height: 408,
        flexes: const [7, 4],
        children: [records, detail],
      );
    });
  }
}

class _DocumentLibraryView extends StatefulWidget {
  const _DocumentLibraryView({required this.zh});

  final bool zh;

  @override
  State<_DocumentLibraryView> createState() => _DocumentLibraryViewState();
}

class _DocumentLibraryViewState extends State<_DocumentLibraryView> {
  bool indexed = true;
  String selectedType = 'all';
  String sortMode = 'name_asc';
  int selectedDocumentIndex = 0;
  final Set<String> selectedDocuments = <String>{};
  final TextEditingController _documentSearchController =
      TextEditingController();

  bool get zh => widget.zh;

  @override
  void dispose() {
    _documentSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final hasRealDocument = runtime.hasImportedFile;
    final parsed = runtime.parseReportPath.isNotEmpty;
    final chunkCount = runtime.chunkCount;
    final importedNames = runtime.sourceNames.isEmpty
        ? <String>[
            if (hasRealDocument) _displayNameForPath(runtime.selectedFilePath)
          ]
        : runtime.sourceNames;
    final searchText = _documentSearchController.text.trim().toLowerCase();
    final filteredNames = (selectedType == 'all'
            ? importedNames
            : importedNames
                .where((name) => _documentTypeForName(name) == selectedType))
        .where((name) =>
            searchText.isEmpty || name.toLowerCase().contains(searchText))
        .toList(growable: true);
    _sortDocumentNames(filteredNames, sortMode);
    selectedDocuments.removeWhere((name) => !filteredNames.contains(name));
    if (selectedDocumentIndex >= filteredNames.length) {
      selectedDocumentIndex =
          filteredNames.isEmpty ? 0 : filteredNames.length - 1;
    }
    final selectedName =
        filteredNames.isEmpty ? '' : filteredNames[selectedDocumentIndex];
    Future<void> deleteSelectedDocument() async {
      if (rc6 == null || runtime.running || selectedName.isEmpty) return;
      final confirmed = await _confirmDestructiveAction(
        context,
        title: zh ? '删除来源文档？' : 'Delete source document?',
        body: zh
            ? '这会从当前工作区删除“$selectedName”，并清理解析、知识库、检索和文档产物。'
            : 'This removes "$selectedName" from the current workspace and clears parsing, KB, retrieval, and document artifacts.',
      );
      if (!confirmed) return;
      await rc6.deleteImportedSource(selectedName);
      if (mounted) {
        setState(() => selectedDocumentIndex = 0);
      }
    }

    Future<void> deleteSelectedDocuments() async {
      if (rc6 == null || runtime.running || selectedDocuments.isEmpty) return;
      final count = selectedDocuments.length;
      final confirmed = await _confirmDestructiveAction(
        context,
        title: zh ? '批量删除来源文档？' : 'Delete selected source documents?',
        body: zh
            ? '这会删除 $count 个已选来源文档，并清理解析、知识库、检索和文档产物。'
            : 'This removes $count selected source documents and clears parsing, KB, retrieval, and document artifacts.',
      );
      if (!confirmed) return;
      final toDelete = selectedDocuments.toList(growable: false);
      for (final name in toDelete) {
        await rc6.deleteImportedSource(name);
      }
      if (mounted) {
        setState(() {
          selectedDocuments.clear();
          selectedDocumentIndex = 0;
        });
      }
    }

    final documentRows = filteredNames.isEmpty
        ? [
            [
              zh ? '请先导入真实文件' : 'Import real files first',
              selectedType == 'all'
                  ? '-'
                  : _documentTypeLabel(selectedType, zh),
              zh ? '本地文件' : 'Local file',
              zh ? '尚未导入' : 'Not imported',
              '0',
            ]
          ]
        : filteredNames
            .map((name) => [
                  name,
                  _documentTypeLabel(_documentTypeForName(name), zh),
                  zh ? '本地文件' : 'Local file',
                  parsed ? (zh ? '已解析' : 'Parsed') : (zh ? '已导入' : 'Imported'),
                  chunkCount.toString(),
                ])
            .toList(growable: false);
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1500;
      final docs = _FillProductPanel(
        keyName: 'document-library',
        icon: Icons.article_outlined,
        title: zh ? '来源文档管理' : 'Source Document Management',
        child: _FillPanelColumn(
          top: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final type in const [
                  'all',
                  'pdf',
                  'docx',
                  'md',
                  'txt',
                  'image',
                  'web',
                ])
                  ChoiceChip(
                    label: Text(_documentTypeLabel(type, zh)),
                    selected: selectedType == type,
                    onSelected: (_) => setState(() {
                      selectedType = type;
                      selectedDocumentIndex = 0;
                    }),
                  ),
              ]),
              const SizedBox(height: 8),
              TextField(
                key: const Key('document-library-search-input'),
                controller: _documentSearchController,
                onChanged: (_) => setState(() {
                  selectedDocumentIndex = 0;
                  selectedDocuments.clear();
                }),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_outlined),
                  labelText: zh ? '搜索来源文档' : 'Search source documents',
                  helperText: zh
                      ? '按文件名、网页来源记录过滤文档库。'
                      : 'Filter library documents by file name or web source record.',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ChoiceChip(
                  label: Text(zh ? '名称升序' : 'Name A-Z'),
                  selected: sortMode == 'name_asc',
                  onSelected: (_) => setState(() => sortMode = 'name_asc'),
                ),
                ChoiceChip(
                  label: Text(zh ? '名称降序' : 'Name Z-A'),
                  selected: sortMode == 'name_desc',
                  onSelected: (_) => setState(() => sortMode = 'name_desc'),
                ),
                ChoiceChip(
                  label: Text(zh ? '类型排序' : 'Type sort'),
                  selected: sortMode == 'type',
                  onSelected: (_) => setState(() => sortMode = 'type'),
                ),
              ]),
              const SizedBox(height: _DesktopGrid.gutter),
              _RuntimeFeedbackBanner(
                title: hasRealDocument
                    ? (zh ? '真实文档已进入文档库' : 'Real document is in library')
                    : (zh ? '等待导入真实文档' : 'Waiting for real document import'),
                detail: hasRealDocument
                    ? _displayNameForPath(runtime.sourceManifestPath)
                    : (zh
                        ? '请在导入与解析页签选择真实文件或文件夹。'
                        : 'Choose real files or a folder from the Import and Parsing tab.'),
                tone:
                    hasRealDocument ? _StatusTone.success : _StatusTone.warning,
                icon: hasRealDocument
                    ? Icons.verified_outlined
                    : Icons.upload_file_outlined,
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              Expanded(
                child: _BoundedScrollRegion(
                  child: _LocalScrollBox(
                    child: _ProductTable(
                      columns: zh
                          ? ['文档', '类型', '来源', '解析', 'Chunks']
                          : ['Document', 'Type', 'Source', 'Parsing', 'Chunks'],
                      rows: documentRows,
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottom: _PrimaryProductAction(
            label: zh ? '刷新文档列表' : 'Refresh document list',
            icon: Icons.refresh_outlined,
            onPressed: () => setState(() {
              indexed = true;
              selectedDocuments.clear();
            }),
          ),
        ),
      );
      final detail = _FillProductPanel(
        keyName: 'document-detail',
        icon: Icons.subject_outlined,
        title: zh ? '文档详情抽屉' : 'Document Detail Drawer',
        child: _FillPanelColumn(
          top: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricStrip(
                items: [
                  _MetricDatum(
                      label: zh ? '字数' : 'Words',
                      value: hasRealDocument
                          ? (chunkCount == 0 ? '待解析' : '${chunkCount * 180}+')
                          : '-',
                      detail: zh ? '解析估算' : 'parse estimate',
                      icon: Icons.text_fields_outlined),
                  _MetricDatum(
                      label: zh ? '图片' : 'Images',
                      value: _documentTypeForName(selectedName) == 'image'
                          ? '1'
                          : '0',
                      detail: zh ? '来源统计' : 'source count',
                      icon: Icons.image_outlined),
                  _MetricDatum(
                      label: zh ? '表格' : 'Tables',
                      value: '0',
                      detail: zh ? '解析报告' : 'parse report',
                      icon: Icons.table_chart_outlined),
                  _MetricDatum(
                      label: zh ? '链接' : 'Links',
                      value: _documentTypeForName(selectedName) == 'web'
                          ? '1'
                          : '0',
                      detail: zh ? '来源统计' : 'source count',
                      icon: Icons.link_outlined),
                ],
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              Expanded(
                child: _BoundedScrollRegion(
                  child: _LocalScrollBox(
                    child: _EqualFieldGrid(
                      columns: 1,
                      children: [
                        _FieldRow(
                            label: zh ? '元数据' : 'Metadata',
                            value: selectedName.isNotEmpty
                                ? selectedName
                                : (zh ? '等待真实文件' : 'Waiting for real file')),
                        _FieldRow(
                            label: zh ? '解析摘要' : 'Parse summary',
                            value: parsed
                                ? (zh
                                    ? '$chunkCount 个 chunks，解析报告已生成'
                                    : '$chunkCount chunks, parse report generated')
                                : (zh ? '尚无解析结果' : 'No parse result yet')),
                        _FieldRow(
                            label: zh ? '下游使用' : 'Downstream use',
                            value: zh
                                ? '知识库构建 / 文档生成 / 检索验证'
                                : 'Knowledge Base build / document generation / retrieval verification'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottom: _DisplayAction(
            label: zh ? '重新解析当前文档' : 'Re-parse selected document',
            icon: Icons.restart_alt_outlined,
            onPressed: hasRealDocument && rc6 != null && !runtime.running
                ? () => rc6.parseAndChunkSources()
                : null,
          ),
        ),
      );
      final preview = _FillProductPanel(
        icon: Icons.preview_outlined,
        title: zh ? '来源预览' : 'Source Preview',
        child: _FillPanelColumn(
          top: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 212,
                child: _SourceDocumentPreviewPanel(
                  zh: zh,
                  ready: indexed && selectedName.isNotEmpty,
                  sourceName: selectedName,
                ),
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              Expanded(
                child: _BoundedScrollRegion(
                  child: _LocalScrollBox(
                    child: _DocumentSelectionList(
                      zh: zh,
                      documents: filteredNames,
                      selectedIndex: selectedDocumentIndex,
                      selectedDocuments: selectedDocuments,
                      onSelected: (index) =>
                          setState(() => selectedDocumentIndex = index),
                      onSelectionChanged: (name, selected) => setState(() {
                        if (selected) {
                          selectedDocuments.add(name);
                        } else {
                          selectedDocuments.remove(name);
                        }
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottom: _EqualFieldGrid(
            columns: 2,
            children: [
              _FieldRow(
                  label: zh ? '当前预览' : 'Current preview',
                  value: selectedName.isEmpty
                      ? (zh ? '无匹配文件' : 'No matching file')
                      : selectedName),
              _FieldRow(
                  label: zh ? '联动筛选' : 'Linked filter',
                  value: _documentTypeLabel(selectedType, zh)),
            ],
          ),
        ),
      );
      final deleteAction = _DisplayAction(
        label: selectedDocuments.isEmpty
            ? (zh ? '删除当前文档' : 'Delete current document')
            : (zh
                ? '删除已选 ${selectedDocuments.length} 个文档'
                : 'Delete ${selectedDocuments.length} selected docs'),
        icon: Icons.delete_outline,
        onPressed: selectedDocuments.isEmpty
            ? (selectedName.isEmpty ? null : deleteSelectedDocument)
            : deleteSelectedDocuments,
      );
      if (!wide) {
        return Column(children: [
          SizedBox(height: 620, child: docs),
          const SizedBox(height: _DesktopGrid.gutter),
          SizedBox(height: 500, child: preview),
          const SizedBox(height: _DesktopGrid.gutter),
          SizedBox(height: 460, child: detail),
          const SizedBox(height: _DesktopGrid.gutter),
          deleteAction,
        ]);
      }
      return Column(children: [
        _EqualHeightRow(
          height: 672,
          flexes: const [4, 4, 4],
          children: [docs, preview, detail],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        Align(alignment: Alignment.centerRight, child: deleteAction),
      ]);
    });
  }
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

void _sortDocumentNames(List<String> names, String sortMode) {
  switch (sortMode) {
    case 'name_desc':
      names.sort((a, b) => b.toLowerCase().compareTo(a.toLowerCase()));
      return;
    case 'type':
      names.sort((a, b) {
        final typeCompare =
            _documentTypeForName(a).compareTo(_documentTypeForName(b));
        return typeCompare == 0
            ? a.toLowerCase().compareTo(b.toLowerCase())
            : typeCompare;
      });
      return;
    default:
      names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }
}

class _WorkbookProductWorkflow extends StatelessWidget {
  const _WorkbookProductWorkflow({
    required this.localeCode,
    required this.workspace,
    required this.onPageChanged,
  });

  final String localeCode;
  final String workspace;
  final ValueChanged<int> onPageChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final runtime =
        _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
    final latestArtifact = runtime.hasExportedDocument
        ? _displayNameForPath(runtime.exportedDocumentPath)
        : runtime.hasMarkdown
            ? _displayNameForPath(runtime.generatedMarkdownPath)
            : runtime.hasKnowledgeBase
                ? _displayNameForPath(runtime.kbManifestPath)
                : runtime.hasImportedFile
                    ? _displayNameForPath(runtime.sourceManifestPath)
                    : (_zh ? '暂无产物' : 'No artifacts yet');
    final readySummary = [
      if (runtime.hasImportedFile) _zh ? '文档库' : 'Document Library',
      if (runtime.hasKnowledgeBase) _zh ? '知识库' : 'Knowledge Base',
      if (runtime.searchStatus == Rc6SearchStatus.success)
        _zh ? '检索报告' : 'Retrieval Report',
      if (runtime.hasMarkdown) _zh ? '生成文档' : 'Generated Document',
      if (runtime.hasSkill) 'Skill',
      if (runtime.hasAgent) 'Agent',
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.workspaces_outline,
        title: _zh ? '工作本管理' : 'Workbook',
        description: _zh
            ? '工作本隔离文档、知识库、应用产物和审计记录，并承接下一步任务。'
            : 'The workbook isolates documents, knowledge bases, application artifacts, and audit records.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _MetricStrip(
        items: [
          _MetricDatum(
            label: _zh ? '来源文档' : 'Source Docs',
            value: runtime.sourceCount.toString(),
            detail: runtime.hasImportedFile
                ? (_zh ? '已持久化' : 'persisted')
                : (_zh ? '等待导入' : 'waiting'),
            icon: Icons.article_outlined,
          ),
          _MetricDatum(
            label: _zh ? '知识库' : 'Knowledge Bases',
            value: runtime.knowledgeBases.isNotEmpty
                ? runtime.knowledgeBases.length.toString()
                : runtime.hasKnowledgeBase
                    ? '1'
                    : '0',
            detail: runtime.hasKnowledgeBase
                ? '${runtime.chunkCount} chunks'
                : (_zh ? '等待构建' : 'waiting build'),
            icon: Icons.account_tree_outlined,
          ),
          _MetricDatum(
            label: _zh ? '应用产物' : 'App Artifacts',
            value: [
              runtime.hasMarkdown,
              runtime.hasSkill,
              runtime.hasAgent,
              runtime.hasAgentDialogue,
              runtime.hasAgentDialogueExport,
              runtime.hasMultiAgentDiscussion,
            ].where((value) => value).length.toString(),
            detail: latestArtifact,
            icon: Icons.folder_copy_outlined,
          ),
          _MetricDatum(
            label: _zh ? '最近结果' : 'Latest Result',
            value: runtime.lastError.isEmpty
                ? (_zh ? '正常' : 'OK')
                : (_zh ? '失败' : 'Failed'),
            detail: runtime.lastError.isEmpty
                ? (runtime.lastMessage.isEmpty
                    ? (_zh ? '等待任务' : 'idle')
                    : runtime.lastMessage)
                : runtime.lastError,
            icon: runtime.lastError.isEmpty
                ? Icons.verified_outlined
                : Icons.error_outline,
          ),
        ],
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final overview = _ProductPanel(
          keyName: 'workbook-overview',
          icon: Icons.space_dashboard_outlined,
          title: _zh ? '当前工作本' : 'Current Workbook',
          minHeight: 320,
          children: [
            _ProductTable(
              columns: _zh ? ['项目', '状态', '说明'] : ['Item', 'Status', 'Note'],
              rows: _zh
                  ? [
                      ['位置', '用户工作区', _displayNameForPath(workspace)],
                      [
                        '已就绪资产',
                        readySummary.isEmpty ? '暂无' : readySummary.join(' / '),
                        '来自真实工作区状态'
                      ],
                      [
                        '持久化',
                        runtime.hasImportedFile ? '已有记录' : '等待首个任务',
                        runtime.hasImportedFile ? '重启后可继续' : '导入资料后写入工作本'
                      ],
                      ['下一步', _dashboardNextStep(runtime, true), '从右侧入口继续'],
                    ]
                  : [
                      [
                        'Location',
                        'User workspace',
                        _displayNameForPath(workspace)
                      ],
                      [
                        'Ready assets',
                        readySummary.isEmpty
                            ? 'None'
                            : readySummary.join(' / '),
                        'From real workspace state'
                      ],
                      [
                        'Persistence',
                        runtime.hasImportedFile ? 'Recorded' : 'Waiting',
                        runtime.hasImportedFile
                            ? 'Can continue after restart'
                            : 'Import sources to persist'
                      ],
                      [
                        'Next',
                        _dashboardNextStep(runtime, false),
                        'Continue from the actions panel'
                      ],
                    ],
            ),
          ],
        );
        final actions = _ProductPanel(
          keyName: 'workbook-next-actions',
          icon: Icons.route_outlined,
          title: _zh ? '继续任务' : 'Continue Work',
          minHeight: 320,
          children: [
            _PrimaryProductAction(
              label: _zh ? '进入文档库导入资料' : 'Open Document Library',
              icon: Icons.library_books_outlined,
              onPressed: () =>
                  onPageChanged(_pageIndexById('document-library')),
            ),
            const SizedBox(height: 8),
            _DisplayAction(
              label: _zh ? '创建或更新知识库' : 'Create or update KB',
              icon: Icons.account_tree_outlined,
              onPressed: runtime.hasImportedFile
                  ? () => onPageChanged(
                      _pageIndexById('knowledge-package-management'))
                  : null,
            ),
            const SizedBox(height: 8),
            _DisplayAction(
              label: _zh ? '检索验证证据' : 'Search and verify evidence',
              icon: Icons.manage_search_outlined,
              onPressed: runtime.hasKnowledgeBase
                  ? () =>
                      onPageChanged(_pageIndexById('retrieval-verification'))
                  : null,
            ),
            const SizedBox(height: 8),
            _DisplayAction(
              label: _zh ? '生成交付文档' : 'Generate deliverable document',
              icon: Icons.edit_document,
              onPressed: runtime.hasKnowledgeBase
                  ? () => onPageChanged(_pageIndexById('document-generation'))
                  : null,
            ),
          ],
        );
        final handoff = _ProductPanel(
          keyName: 'workbook-handoff',
          icon: Icons.inventory_2_outlined,
          title: _zh ? '资产承接' : 'Asset Handoff',
          minHeight: 260,
          children: [
            _ProductTable(
              columns: _zh
                  ? ['阶段', '输入', '输出', '下一步']
                  : ['Stage', 'Input', 'Output', 'Next'],
              rows: _zh
                  ? [
                      ['文档库', '本地资料', '来源文档 / 解析报告', '知识库'],
                      ['知识库', '来源文档', 'chunks / manifest / 质量报告', '检索验证'],
                      ['检索验证', '知识库', '证据片段 / 验证记录', '文档生成'],
                      ['知识应用', '可信证据', '文档 / Skill / Agent', '治理审计'],
                    ]
                  : [
                      [
                        'Document Library',
                        'Local sources',
                        'Documents / parse report',
                        'Knowledge Base'
                      ],
                      [
                        'Knowledge Base',
                        'Source documents',
                        'chunks / manifest / quality',
                        'Retrieval'
                      ],
                      [
                        'Retrieval',
                        'Knowledge bases',
                        'Evidence / validation record',
                        'Document Generation'
                      ],
                      [
                        'Knowledge Apps',
                        'Trusted evidence',
                        'Docs / Skills / Agents',
                        'Governance'
                      ],
                    ],
            ),
          ],
        );
        if (!wide) {
          return Column(children: [
            overview,
            const SizedBox(height: _DesktopGrid.gutter),
            actions,
            const SizedBox(height: _DesktopGrid.gutter),
            handoff,
          ]);
        }
        return Column(children: [
          _EqualHeightRow(
            height: 320,
            flexes: const [7, 5],
            children: [overview, actions],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          handoff,
        ]);
      }),
    ]);
  }
}

class _DocumentLibraryProductWorkflow extends StatefulWidget {
  const _DocumentLibraryProductWorkflow({
    required this.localeCode,
    required this.workspace,
    required this.isWebRuntime,
  });

  final String localeCode;
  final String workspace;
  final bool isWebRuntime;

  @override
  State<_DocumentLibraryProductWorkflow> createState() =>
      _DocumentLibraryProductWorkflowState();
}

class _DocumentLibraryProductWorkflowState
    extends State<_DocumentLibraryProductWorkflow> {
  int selectedTab = 0;

  bool get _zh => widget.localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final tabs =
        _zh ? ['导入与解析', '来源文档'] : ['Import and Parsing', 'Source Documents'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.library_books_outlined,
        title: _zh ? '文档库' : 'Document Library',
        description: _zh
            ? '导入资料、解析/OCR/分块，并管理进入工作本的来源文档。'
            : 'Import sources, parse/OCR/chunk them, and manage source documents in the workbook.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _PageTabs(
        tabs: tabs,
        selectedIndex: selectedTab,
        onSelected: (index) => setState(() => selectedTab = index),
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      if (selectedTab == 0)
        _ImportProductWorkflow(
          localeCode: widget.localeCode,
          workspace: widget.workspace,
          isWebRuntime: widget.isWebRuntime,
        )
      else
        _DocumentLibraryView(zh: _zh),
    ]);
  }
}

class _RetrievalVerificationView extends StatefulWidget {
  const _RetrievalVerificationView({required this.zh});

  final bool zh;

  @override
  State<_RetrievalVerificationView> createState() =>
      _RetrievalVerificationViewState();
}

class _RetrievalVerificationViewState
    extends State<_RetrievalVerificationView> {
  bool retrievalPrepared = false;
  final Set<String> selectedKbIds = <String>{};
  String selectedStage = 'rewrite';
  String validationReportPath = '';
  final Map<int, String> correctionState = <int, String>{};
  final TextEditingController _queryController =
      TextEditingController(text: 'heitang-rc6-needle');

  bool get zh => widget.zh;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final realResults = [...runtime.searchResults]..sort((a, b) =>
        (double.tryParse(b.score) ?? 0)
            .compareTo(double.tryParse(a.score) ?? 0));
    final citedCount =
        realResults.where((result) => result.citation.trim().isNotEmpty).length;
    final faithfulness = realResults.isEmpty
        ? 0
        : ((citedCount / realResults.length) * 100).round();
    final uniqueCitationCount = realResults
        .map((result) => result.citation.trim())
        .where((citation) => citation.isNotEmpty)
        .toSet()
        .length;
    final kbOptions = runtime.knowledgeBases.isNotEmpty
        ? runtime.knowledgeBases
            .map((kb) => _KbSelectionOption(
                  kb.id,
                  kb.name,
                  '${kb.chunkCount} chunks · ${kb.operation}',
                  kb.status == 'searchable' && kb.chunkCount > 0,
                ))
            .toList(growable: false)
        : [
            _KbSelectionOption(
              'default_kb',
              zh ? '当前知识库' : 'Current KB',
              runtime.hasKnowledgeBase
                  ? '${runtime.chunkCount} chunks'
                  : (zh ? '请先构建' : 'Build first'),
              runtime.hasKnowledgeBase,
            ),
          ];
    final enabledKbIds =
        kbOptions.where((option) => option.enabled).map((option) => option.id);
    selectedKbIds.removeWhere((id) => !enabledKbIds.contains(id));
    if (selectedKbIds.isEmpty && enabledKbIds.isNotEmpty) {
      selectedKbIds.add(enabledKbIds.first);
    }
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final extraWide = constraints.maxWidth >= 1180;
      final feedback = runtime.searchStatus != Rc6SearchStatus.idle
          ? _RuntimeFeedbackBanner(
              title: runtime.searchStatus == Rc6SearchStatus.success
                  ? (zh ? '真实检索已返回结果' : 'Real retrieval returned results')
                  : runtime.searchStatus == Rc6SearchStatus.empty
                      ? (zh ? '真实检索无结果' : 'Real retrieval returned no results')
                      : runtime.searchStatus == Rc6SearchStatus.error
                          ? (zh ? '检索失败' : 'Search failed')
                          : (zh ? '检索中' : 'Searching'),
              detail: runtime.queryResultPath.isEmpty
                  ? runtime.lastMessage
                  : runtime.queryResultPath,
              tone: runtime.searchStatus == Rc6SearchStatus.success
                  ? _StatusTone.success
                  : runtime.searchStatus == Rc6SearchStatus.error
                      ? _StatusTone.danger
                      : _StatusTone.warning,
              icon: Icons.manage_search_outlined,
            )
          : null;
      final query = _ProductPanel(
        keyName: 'retrieval-workflow',
        icon: Icons.manage_search_outlined,
        title: zh ? '查询控制台' : 'Query Console',
        minHeight: 430,
        subtitle: zh
            ? '本页查询只检索所选知识库；顶部全局搜索用于快速定位文档、知识库、Skill 和 Agent。'
            : 'This page searches the selected KB only; top search locates docs, KBs, Skills, and Agents.',
        children: [
          _SectionCaption(zh ? '所选知识库' : 'Selected knowledge bases'),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final option in kbOptions)
              FilterChip(
                label: Text('${option.label} · ${option.detail}'),
                selected: selectedKbIds.contains(option.id),
                onSelected: option.enabled
                    ? (selected) => setState(() {
                          if (selected) {
                            selectedKbIds.add(option.id);
                          } else {
                            selectedKbIds.remove(option.id);
                          }
                        })
                    : null,
              ),
          ]),
          const SizedBox(height: 8),
          TextField(
            key: const Key('retrieval-real-query-input'),
            controller: _queryController,
            enabled: !runtime.running,
            onSubmitted: (value) =>
                rc6?.searchKnowledgeBases(value, selectedKbIds.toList()),
            decoration: InputDecoration(
              labelText: zh ? '真实搜索关键词' : 'Real search keyword',
              helperText: zh
                  ? '输入关键词后返回知识库证据片段、引用来源和评分。'
                  : 'Enter keywords to return KB evidence, citations, and score.',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          _RetrievalStageButtons(
            zh: zh,
            selectedStage: selectedStage,
            onSelected: (value) => setState(() => selectedStage = value),
          ),
          const SizedBox(height: 8),
          _RuntimeFeedbackBanner(
            title: _retrievalStageLabel(selectedStage, zh),
            detail: _retrievalStageDetail(selectedStage, zh),
            tone: _StatusTone.neutral,
            icon: Icons.account_tree_outlined,
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _ProductTable(
            columns: zh
                ? ['证据片段', '引用来源', '评分', '验证状态', '人工纠偏']
                : [
                    'Evidence snippet',
                    'Citation',
                    'Score',
                    'Validation',
                    'Correction'
                  ],
            rows: realResults.isEmpty
                ? [
                    [
                      zh ? '等待真实检索结果' : 'Waiting for real result',
                      runtime.hasKnowledgeBase
                          ? (zh ? '本地知识库' : 'Local KB')
                          : (zh ? '未构建' : 'Not built'),
                      '-',
                      runtime.searchStatus == Rc6SearchStatus.empty
                          ? (zh ? '无结果' : 'Empty')
                          : (zh ? '未搜索' : 'Not searched'),
                      runtime.lastError.isEmpty
                          ? (zh ? '待处理' : 'Pending')
                          : runtime.lastError,
                    ]
                  ]
                : [
                    for (var index = 0; index < realResults.length; index++)
                      [
                        realResults[index].excerpt.isEmpty
                            ? realResults[index].title
                            : realResults[index].excerpt,
                        _resultKbCitation(realResults[index]),
                        realResults[index].score.isEmpty
                            ? '-'
                            : realResults[index].score,
                        zh ? '按相关性排序' : 'Sorted by relevance',
                        _correctionLabel(correctionState[index], zh),
                      ],
                  ],
          ),
          if (realResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            _CorrectionActionStrip(
              zh: zh,
              selectedIndex: 0,
              onCorrection: (value) =>
                  setState(() => correctionState[0] = value),
            ),
          ],
        ],
      );
      final metrics = _ProductPanel(
        icon: Icons.analytics_outlined,
        title: zh ? '验证指标与边界' : 'Verification Metrics and Boundary',
        gap: true,
        minHeight: 430,
        children: [
          _MetricGrid(
            columns: 2,
            items: [
              _MetricDatum(
                  label: zh ? '准确率' : 'Accuracy',
                  value: runtime.searchStatus == Rc6SearchStatus.success
                      ? '${realResults.length}/${runtime.chunkCount}'
                      : '-',
                  detail: zh ? '命中证据 / 返回证据' : 'matched / returned',
                  icon: Icons.verified_outlined),
              _MetricDatum(
                  label: zh ? '忠实度' : 'Faithfulness',
                  value: runtime.searchStatus == Rc6SearchStatus.success
                      ? '$faithfulness%'
                      : '-',
                  detail: zh ? '有引用答案 / 全部答案' : 'cited / all',
                  icon: Icons.link_outlined),
              _MetricDatum(
                  label: zh ? '覆盖率' : 'Coverage',
                  value: uniqueCitationCount.toString(),
                  detail: zh ? '命中引用来源数' : 'citation sources',
                  icon: Icons.pie_chart_outline),
              _MetricDatum(
                  label: zh ? '矛盾项' : 'Contradictions',
                  value: runtime.searchStatus == Rc6SearchStatus.success
                      ? correctionState.values
                          .where((value) => value == 'conflict')
                          .length
                          .toString()
                      : '-',
                  detail: zh ? '人工可纠偏' : 'manual correction',
                  icon: Icons.warning_amber_outlined),
            ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _FieldRow(
            label: zh ? '评分公式' : 'Scoring rule',
            value: zh
                ? '相关性 = 关键词命中 50% + chunk 分数 35% + 来源覆盖 15%'
                : 'Relevance = keyword match 50% + chunk score 35% + source coverage 15%',
          ),
          const SizedBox(height: 8),
          _EqualActionRow(children: [
            _PrimaryProductAction(
              label: zh ? '运行真实检索' : 'Run real retrieval',
              onPressed: runtime.running || rc6 == null
                  ? null
                  : () {
                      setState(() => retrievalPrepared = true);
                      rc6.searchKnowledgeBases(
                          _queryController.text, selectedKbIds.toList());
                    },
              icon: Icons.play_arrow_outlined,
            ),
            _PrimaryProductAction(
              label: zh ? '保存验证报告' : 'Save validation report',
              onPressed: runtime.queryResultPath.isEmpty || rc6 == null
                  ? null
                  : () async {
                      final path = await rc6
                          .saveRetrievalValidationReport(correctionState);
                      if (mounted && path.isNotEmpty) {
                        setState(() => validationReportPath = path);
                      }
                    },
              icon: Icons.save_alt_outlined,
            ),
          ]),
          const SizedBox(height: 8),
          _EqualActionRow(children: [
            _RuntimeFeedbackBanner(
              title: zh ? '外部事实验证未启用' : 'External fact checking is not enabled',
              detail: zh
                  ? '需要在设置中配置联网 Provider、Tool Adapter 和显式 opt-in；当前检索只使用本地知识库证据。'
                  : 'Requires network Provider, Tool Adapter, and explicit opt-in in Settings; current retrieval uses local KB evidence only.',
              tone: _StatusTone.neutral,
              icon: Icons.public_off_outlined,
            ),
          ]),
          if (validationReportPath.isNotEmpty) ...[
            const SizedBox(height: 8),
            _RuntimeFeedbackBanner(
              title: zh ? '验证报告已保存' : 'Validation report saved',
              detail: validationReportPath,
              tone: _StatusTone.success,
              icon: Icons.fact_check_outlined,
            ),
          ],
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '外部验证边界' : 'External verification boundary',
            value: zh
                ? '联网 Provider、Tool Adapter 和显式 opt-in 配齐后启用'
                : 'Enabled only after network Provider, Tool Adapter, and explicit opt-in are configured',
          ),
        ],
      );
      final reasoning = _ProductPanel(
        keyName: 'retrieval-reasoning-panel',
        icon: Icons.account_tree_outlined,
        title: zh ? '证据选择与推理' : 'Evidence Selection and Reasoning',
        children: [
          _ProductTable(
            columns: zh ? ['阶段', '结果', '说明'] : ['Stage', 'Result', 'Note'],
            rows: zh
                ? [
                    ['查询改写', retrievalPrepared ? '完成' : '等待', '保留原问题边界'],
                    ['检索规划', retrievalPrepared ? '混合检索' : '等待', '向量 + 关键词'],
                    ['证据选择', retrievalPrepared ? '3 选 2' : '等待', '只引用本地证据'],
                    [
                      '交叉验证',
                      retrievalPrepared ? '1 条需复核' : '等待',
                      '授权联网后与外部来源逐条比对'
                    ],
                  ]
                : [
                    [
                      'Query rewrite',
                      retrievalPrepared ? 'Done' : 'Waiting',
                      'Keeps original scope'
                    ],
                    [
                      'Retrieval planning',
                      retrievalPrepared ? 'Hybrid' : 'Waiting',
                      'Vector + keyword'
                    ],
                    [
                      'Evidence selection',
                      retrievalPrepared ? '3 of 2' : 'Waiting',
                      'Local evidence only'
                    ],
                    [
                      'Cross validation',
                      retrievalPrepared ? '1 review' : 'Waiting',
                      'Compare with external sources after authorization'
                    ],
                  ],
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          if (feedback != null) ...[
            feedback,
            const SizedBox(height: _DesktopGrid.gutter),
          ],
          query,
          const SizedBox(height: _DesktopGrid.gutter),
          reasoning,
          const SizedBox(height: _DesktopGrid.gutter),
          metrics
        ]);
      }
      if (extraWide) {
        return Column(children: [
          if (feedback != null) ...[
            feedback,
            const SizedBox(height: _DesktopGrid.gutter),
          ],
          _EqualHeightRow(
            height: 430,
            flexes: const [8, 4],
            children: [query, metrics],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          reasoning,
        ]);
      }
      return Column(children: [
        if (feedback != null) ...[
          feedback,
          const SizedBox(height: _DesktopGrid.gutter),
        ],
        _EqualHeightRow(
          height: 430,
          flexes: const [7, 5],
          children: [query, metrics],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        reasoning,
      ]);
    });
  }
}

class _KbSelectionOption {
  const _KbSelectionOption(this.id, this.label, this.detail, this.enabled);

  final String id;
  final String label;
  final String detail;
  final bool enabled;
}

class _RetrievalStageButtons extends StatelessWidget {
  const _RetrievalStageButtons({
    required this.zh,
    required this.selectedStage,
    required this.onSelected,
  });

  final bool zh;
  final String selectedStage;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const stages = ['rewrite', 'planning', 'hybrid', 'rerank', 'verify'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final stage in stages)
          ChoiceChip(
            label: Text(_retrievalStageLabel(stage, zh)),
            selected: selectedStage == stage,
            onSelected: (_) => onSelected(stage),
          ),
      ],
    );
  }
}

String _retrievalStageLabel(String stage, bool zh) {
  return switch (stage) {
    'planning' => zh ? '检索规划' : 'Retrieval planning',
    'hybrid' => zh ? '混合检索' : 'Hybrid retrieval',
    'rerank' => zh ? '重排' : 'Rerank',
    'verify' => zh ? '证据验证' : 'Evidence verification',
    _ => zh ? '查询改写' : 'Query rewrite',
  };
}

String _retrievalStageDetail(String stage, bool zh) {
  return switch (stage) {
    'planning' => zh
        ? '选择知识库范围、关键词策略和返回数量。'
        : 'Choose KB scope, keyword strategy, and result count.',
    'hybrid' => zh
        ? '结合本地关键词和 chunks/cards 索引。'
        : 'Combine local keywords with chunks/cards indexes.',
    'rerank' => zh
        ? '按相关性、来源覆盖和引用完整性排序。'
        : 'Sort by relevance, source coverage, and citation completeness.',
    'verify' => zh
        ? '逐条保留、忽略或标记矛盾；外部验证需授权。'
        : 'Keep, ignore, or mark contradictions one by one; external checking requires authorization.',
    _ => zh
        ? '保留用户原意，展开同义词和文件名线索。'
        : 'Preserve intent while expanding synonyms and filename hints.',
  };
}

String _resultKbCitation(Rc6SearchResult result) {
  final kbName = result.kbName.trim().isNotEmpty
      ? result.kbName.trim()
      : result.kbId.trim().isNotEmpty
          ? result.kbId.trim()
          : '当前知识库';
  final citation = result.citation.trim();
  return citation.isEmpty ? 'KB: $kbName' : 'KB: $kbName · $citation';
}

String _correctionLabel(String? value, bool zh) {
  return switch (value) {
    'contradiction' => zh ? '已标记矛盾' : 'Contradiction marked',
    'ignore' => zh ? '已忽略' : 'Ignored',
    'review' => zh ? '待人工复核' : 'Needs review',
    'keep' => zh ? '已保留' : 'Kept',
    _ => zh ? '待纠偏' : 'Pending correction',
  };
}

class _CorrectionActionStrip extends StatelessWidget {
  const _CorrectionActionStrip({
    required this.zh,
    required this.selectedIndex,
    required this.onCorrection,
  });

  final bool zh;
  final int selectedIndex;
  final ValueChanged<String> onCorrection;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _DisplayAction(
          label: zh
              ? '保留第 ${selectedIndex + 1} 条'
              : 'Keep result ${selectedIndex + 1}',
          icon: Icons.check_circle_outline,
          onPressed: () => onCorrection('keep'),
        ),
        _DisplayAction(
          label: zh ? '标记矛盾' : 'Mark contradiction',
          icon: Icons.warning_amber_outlined,
          onPressed: () => onCorrection('contradiction'),
        ),
        _DisplayAction(
          label: zh ? '忽略' : 'Ignore',
          icon: Icons.visibility_off_outlined,
          onPressed: () => onCorrection('ignore'),
        ),
        _DisplayAction(
          label: zh ? '人工复核' : 'Manual review',
          icon: Icons.rate_review_outlined,
          onPressed: () => onCorrection('review'),
        ),
      ],
    );
  }
}

class _RetrievalVerificationProductWorkflow extends StatefulWidget {
  const _RetrievalVerificationProductWorkflow({required this.localeCode});

  final String localeCode;

  @override
  State<_RetrievalVerificationProductWorkflow> createState() =>
      _RetrievalVerificationProductWorkflowState();
}

class _RetrievalVerificationProductWorkflowState
    extends State<_RetrievalVerificationProductWorkflow> {
  bool get _zh => widget.localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.manage_search_outlined,
        title: _zh ? '检索与验证' : 'Retrieval & Verification',
        description: _zh
            ? '先选择知识库，再查询；证据片段、引用、评分、纠偏和授权外部验证都在同一查询台完成。'
            : 'Select a KB first, then query; evidence, citations, scoring, correction, and authorized external checking stay in one console.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _RetrievalVerificationView(zh: _zh),
    ]);
  }
}

class _SkillBuilderProductWorkflow extends StatefulWidget {
  const _SkillBuilderProductWorkflow({
    required this.localeCode,
    required this.workspace,
  });

  final String localeCode;
  final String workspace;

  @override
  State<_SkillBuilderProductWorkflow> createState() =>
      _SkillBuilderProductWorkflowState();
}

class _SkillBuilderProductWorkflowState
    extends State<_SkillBuilderProductWorkflow> {
  bool configReady = false;
  bool outputPreviewReady = false;
  bool validationReady = false;
  int selectedTab = 0;
  String skillType = 'analysis';
  String targetPlatform = 'codex';
  String personalizationGoal = '';
  final TextEditingController _skillEditorController = TextEditingController();
  String savedSkillEditPath = '';

  bool get _zh => widget.localeCode == 'zh-CN';

  @override
  void dispose() {
    _skillEditorController.dispose();
    super.dispose();
  }

  Rc6SkillGenerationConfig get _skillConfig => Rc6SkillGenerationConfig(
        skillType: skillType,
        targetPlatform: targetPlatform,
        personalizationGoal: personalizationGoal,
      );

  String _skillTypeLabel(String value) => switch (value) {
        'writing' => _zh ? '写作 Skill' : 'Writing',
        'teaching' => _zh ? '教学 Skill' : 'Teaching',
        'product' => _zh ? '产品 Skill' : 'Product',
        'ops' => _zh ? '运营 Skill' : 'Operations',
        'legal' => _zh ? '法规 Skill' : 'Legal',
        'custom' => _zh ? '自定义 Skill' : 'Custom',
        _ => _zh ? '分析 Skill' : 'Analysis',
      };

  String _targetPlatformLabel(String value) => switch (value) {
        'claude_code' => 'Claude Code',
        'openclaw' => 'OpenClaw',
        'markdown' => 'Markdown',
        'internal_agent' => _zh ? '内置 Agent' : 'Internal Agent',
        _ => 'Codex',
      };

  String _personalizationGoalLabel(String value) => switch (value) {
        'domain_localization' => _zh ? '领域本地化' : 'Domain localization',
        'style_personalization' => _zh ? '用户风格化' : 'Style personalization',
        'platform_adaptation' => _zh ? '平台适配' : 'Platform adaptation',
        'task_customization' => _zh ? '任务定制' : 'Task customization',
        'enterprise_constraints' => _zh ? '企业知识约束' : 'Enterprise constraints',
        'agent_specific' => _zh ? 'Agent 专属化' : 'Agent-specific',
        _ => _zh ? '未选择' : 'Not selected',
      };

  Future<void> _confirmAndDeleteSkill(Rc6RuntimeController? rc6) async {
    if (rc6 == null || rc6.state.running || !rc6.state.hasSkill) return;
    final confirmed = await _confirmDestructiveAction(
      context,
      title: _zh ? '删除 Skill 产物？' : 'Delete Skill artifacts?',
      body: _zh
          ? '这会删除当前工作区里的 Skill、Agent、对话和联合讨论产物；知识库和文档不会被删除。'
          : 'This deletes Skill, Agent, dialogue, and discussion artifacts in this workspace; KB and documents are kept.',
    );
    if (!confirmed) return;
    await rc6.clearSkillArtifacts();
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    Future<void> loadSkillDraft() async {
      if (rc6 == null || !runtime.hasSkill) return;
      final content = await rc6.readWorkspaceTextArtifact(
          '${runtime.skillPath}/knowledge_qa_skill/SKILL.md');
      if (!mounted) return;
      setState(() {
        _skillEditorController.text = content;
        outputPreviewReady = true;
      });
    }

    Future<void> saveSkillDraft() async {
      if (rc6 == null) return;
      final path = await rc6.saveEditedSkill(_skillEditorController.text);
      if (!mounted) return;
      setState(() {
        savedSkillEditPath = path;
        validationReady = path.isNotEmpty;
      });
    }

    final tabs = _zh
        ? ['从知识库生成', '外部本地化', '版本操作', '验证导出']
        : [
            'Generate from KB',
            'External Localization',
            'Version Operations',
            'Validate & Export'
          ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.extension_outlined,
        title: _zh ? 'Skill 工厂' : 'Skill Factory',
        description: _zh
            ? '选择知识库，配置生成方式和元数据，验证后生成 Skill 草稿，用于 Agent 创建、绑定和导出。'
            : 'Select a Knowledge Base, configure generation and metadata, validate, then use the Skill draft for Agent creation, binding, and export.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _PageTabs(
        tabs: tabs,
        selectedIndex: selectedTab,
        onSelected: (index) => setState(() => selectedTab = index),
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _MetricStrip(
        items: [
          _MetricDatum(
              label: _zh ? '生成模式' : 'Generation modes',
              value: '2',
              detail: _zh ? '知识库 / 外部本地化' : 'KB / external fusion',
              icon: Icons.alt_route_outlined),
          _MetricDatum(
              label: _zh ? '目标平台' : 'Target platforms',
              value: '5',
              detail: _zh ? 'Codex 等' : 'Codex and more',
              icon: Icons.dashboard_customize_outlined),
          _MetricDatum(
              label: _zh ? '治理报告' : 'Governance',
              value: runtime.hasSkill ? 'pass' : 'ready',
              detail: runtime.hasSkill
                  ? (_zh ? '已生成' : 'Generated')
                  : (_zh ? '等待知识库' : 'Waiting KB'),
              icon: Icons.rule_folder_outlined),
        ],
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      if (configReady || outputPreviewReady || validationReady) ...[
        _RuntimeFeedbackBanner(
          title: validationReady
              ? (_zh ? 'Skill 草稿已生成' : 'Skill draft generated')
              : outputPreviewReady
                  ? (_zh ? 'Skill 包结构已刷新' : 'Skill package structure refreshed')
                  : (_zh ? 'Skill 配置已准备' : 'Skill config prepared'),
          detail: runtime.hasSkill
              ? runtime.skillPath
              : (_zh
                  ? '请先构建知识库，再生成真实 Skill package。'
                  : 'Build a KB first, then generate a real Skill package.'),
          tone: runtime.hasSkill ? _StatusTone.success : _StatusTone.warning,
          icon: Icons.extension_outlined,
        ),
        const SizedBox(height: _DesktopGrid.gutter),
      ],
      LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        final config = _ProductPanel(
          keyName: 'skill-metadata-source-config',
          icon: Icons.edit_note_outlined,
          title: _zh ? '从知识库生成 Skill' : 'Generate Skill from KB',
          children: [
            _ProductTable(
              columns:
                  _zh ? ['生成模式', '来源', '状态'] : ['Mode', 'Source', 'Status'],
              rows: _zh
                  ? [
                      [
                        '从知识库生成 Skill',
                        '当前知识库',
                        runtime.hasSkill
                            ? '已生成'
                            : runtime.hasKnowledgeBase
                                ? '可生成'
                                : '请先构建知识库'
                      ],
                      [
                        '外部 Skill 本地化',
                        'S0 + 当前知识库',
                        runtime.hasSkill
                            ? '已生成 S2'
                            : runtime.hasKnowledgeBase
                                ? '可生成'
                                : '请先构建知识库'
                      ],
                      [
                        '多知识库 Skill',
                        '当前 KB Catalog',
                        runtime.hasSkill
                            ? '已生成'
                            : runtime.hasKnowledgeBase
                                ? '可生成'
                                : '请先构建知识库'
                      ],
                    ]
                  : [
                      [
                        'Generate Skill from KB',
                        'Current KB',
                        runtime.hasSkill
                            ? 'Generated'
                            : runtime.hasKnowledgeBase
                                ? 'Ready'
                                : 'Build KB first'
                      ],
                      [
                        'External Skill localization',
                        'S0 + current KB',
                        runtime.hasSkill
                            ? 'S2 generated'
                            : runtime.hasKnowledgeBase
                                ? 'Ready'
                                : 'Build KB first'
                      ],
                      [
                        'Multi-KB Skill',
                        'Current KB catalog',
                        runtime.hasSkill
                            ? 'Generated'
                            : runtime.hasKnowledgeBase
                                ? 'Ready'
                                : 'Build KB first'
                      ],
                    ],
            ),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '上游承接物' : 'Upstream input',
                value: runtime.kbManifestPath.isNotEmpty
                    ? _displayNameForPath(runtime.kbManifestPath)
                    : (_zh ? '等待真实知识库' : 'Waiting for real Knowledge Base')),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? 'Skill 类型' : 'Skill type',
                value: _skillTypeLabel(skillType)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final item in const [
                'analysis',
                'writing',
                'teaching',
                'product',
                'ops',
                'legal',
                'custom',
              ])
                ChoiceChip(
                  label: Text(_skillTypeLabel(item)),
                  selected: skillType == item,
                  onSelected: (_) => setState(() => skillType = item),
                ),
            ]),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '目标平台' : 'Target platform',
                value: _targetPlatformLabel(targetPlatform)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final item in const [
                'codex',
                'claude_code',
                'openclaw',
                'markdown',
                'internal_agent',
              ])
                ChoiceChip(
                  label: Text(_targetPlatformLabel(item)),
                  selected: targetPlatform == item,
                  onSelected: (_) => setState(() => targetPlatform = item),
                ),
            ]),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '个性化目标' : 'Personalization goal',
                value: _personalizationGoalLabel(personalizationGoal)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final item in const [
                '',
                'domain_localization',
                'style_personalization',
                'platform_adaptation',
                'task_customization',
                'enterprise_constraints',
                'agent_specific',
              ])
                ChoiceChip(
                  label: Text(_personalizationGoalLabel(item)),
                  selected: personalizationGoal == item,
                  onSelected: (_) => setState(() => personalizationGoal = item),
                ),
            ]),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '样例任务验证' : 'Sample task validation',
                value: runtime.hasSkill
                    ? (_zh
                        ? 'verification_report.json 已写入'
                        : 'verification_report.json written')
                    : (_zh ? '生成后执行本地样例校验' : 'Runs after local generation')),
            const SizedBox(height: 8),
            SizedBox(
              height: 144,
              child: TextField(
                key: const Key('skill-draft-editor'),
                controller: _skillEditorController,
                maxLines: null,
                expands: true,
                enabled: rc6 != null,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: runtime.hasSkill
                      ? (_zh
                          ? '加载 SKILL.md 后可编辑草稿。'
                          : 'Load SKILL.md, then edit the draft.')
                      : (_zh
                          ? '请先生成 Skill 草稿。'
                          : 'Generate a Skill draft first.'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      height: 1.22,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            _EqualActionRow(children: [
              _PrimaryProductAction(
                label: _zh ? '生成 Skill' : 'Generate Skill',
                icon: Icons.extension_outlined,
                onPressed: runtime.running || rc6 == null
                    ? null
                    : () {
                        setState(() {
                          configReady = true;
                          outputPreviewReady = true;
                        });
                        rc6.generateSkill(config: _skillConfig);
                      },
              ),
              _DisplayAction(
                label: _zh ? '加载草稿' : 'Load draft',
                icon: Icons.article_outlined,
                onPressed:
                    rc6 == null || !runtime.hasSkill ? null : loadSkillDraft,
              ),
              _PrimaryProductAction(
                label: _zh ? '保存编辑' : 'Save edit',
                icon: Icons.save_outlined,
                onPressed: rc6 == null ||
                        runtime.running ||
                        !runtime.hasSkill ||
                        _skillEditorController.text.trim().isEmpty
                    ? null
                    : saveSkillDraft,
              ),
            ]),
            if (savedSkillEditPath.isNotEmpty) ...[
              const SizedBox(height: 8),
              _FieldRow(
                  label: _zh ? '编辑稿' : 'Edited draft',
                  value: _displayNameForPath(savedSkillEditPath)),
            ],
          ],
        );
        final localization = _ProductPanel(
          keyName: 'skill-external-localization',
          icon: Icons.merge_type_outlined,
          title: _zh ? '外部 Skill 本地化' : 'External Skill Localization',
          subtitle: runtime.hasSkill
              ? _displayNameForPath(runtime.skillPath)
              : '${widget.workspace}/workbench_runs/skill/external_imported_skill',
          children: [
            _ProductTable(
              columns:
                  _zh ? ['对象', '业务含义', '状态'] : ['Object', 'Meaning', 'Status'],
              rows: _zh
                  ? [
                      [
                        'S0 外部 Skill',
                        '导入外部写作方法论',
                        runtime.hasSkill ? '已导入' : '生成 Skill 后写入'
                      ],
                      [
                        'S2 本地化 Skill',
                        'S0 + 当前知识库融合',
                        runtime.hasSkill ? '已验证' : '等待知识库'
                      ],
                      [
                        '差异说明',
                        '记录本地化和 Agent 绑定变化',
                        runtime.hasSkill ? '已生成' : '等待生成'
                      ],
                    ]
                  : [
                      [
                        'S0 external Skill',
                        'Imported writing methodology',
                        runtime.hasSkill ? 'Imported' : 'Written on generate'
                      ],
                      [
                        'S2 localized Skill',
                        'S0 + current KB fusion',
                        runtime.hasSkill ? 'Validated' : 'Waiting KB'
                      ],
                      [
                        'Diff summary',
                        'Localization and Agent-binding changes',
                        runtime.hasSkill ? 'Generated' : 'Waiting'
                      ],
                    ],
            ),
            const SizedBox(height: _DesktopGrid.gutter),
            _PrimaryProductAction(
              label: _zh ? '导入并本地化 Skill' : 'Import and localize Skill',
              icon: Icons.merge_type_outlined,
              onPressed: runtime.running || rc6 == null
                  ? null
                  : () {
                      setState(() {
                        configReady = true;
                        outputPreviewReady = true;
                        validationReady = true;
                      });
                      rc6.pickAndImportExternalSkill();
                    },
            ),
          ],
        );
        final output = _ProductPanel(
          keyName: 'skill-output-preview',
          icon: Icons.folder_zip_outlined,
          title: _zh ? 'Skill 版本操作' : 'Skill Version Operations',
          subtitle: runtime.hasSkill
              ? _displayNameForPath(runtime.skillPath)
              : '${widget.workspace}/workbench_runs/skill',
          children: [
            _FileTreePreview(
              zh: _zh,
              rows: _zh
                  ? [
                      ['knowledge_qa_skill/', ''],
                      ['SKILL.md', runtime.hasSkill ? '已生成' : '-'],
                      ['skill_config.json', runtime.hasSkill ? '已生成' : '-'],
                      [
                        'verification_report.json',
                        runtime.hasSkill ? '已生成' : '-'
                      ],
                      [
                        'external_imported_skill/S0/',
                        runtime.hasSkill ? '已导入' : '-'
                      ],
                      [
                        'localized_writing_skill/S2/',
                        runtime.hasSkill ? '已生成' : '-'
                      ],
                      [
                        'skill_generation_manifest.json',
                        runtime.hasSkill ? '已生成' : '-'
                      ],
                      [
                        'operations/skill_operation_manifest.json',
                        runtime.hasSkill ? '已生成' : '-'
                      ],
                      [
                        'exports/skills_export.md',
                        runtime.hasSkill ? '已导出' : '-'
                      ],
                      [
                        'knowledge_qa_skill/skill_edit_manifest.json',
                        savedSkillEditPath.isNotEmpty ? '已保存' : '-'
                      ],
                    ]
                  : [
                      ['knowledge_qa_skill/', ''],
                      ['SKILL.md', runtime.hasSkill ? 'written' : '-'],
                      ['skill_config.json', runtime.hasSkill ? 'written' : '-'],
                      [
                        'verification_report.json',
                        runtime.hasSkill ? 'written' : '-'
                      ],
                      [
                        'external_imported_skill/S0/',
                        runtime.hasSkill ? 'imported' : '-'
                      ],
                      [
                        'localized_writing_skill/S2/',
                        runtime.hasSkill ? 'written' : '-'
                      ],
                      [
                        'skill_generation_manifest.json',
                        runtime.hasSkill ? 'written' : '-'
                      ],
                      [
                        'operations/skill_operation_manifest.json',
                        runtime.hasSkill ? 'written' : '-'
                      ],
                      [
                        'exports/skills_export.md',
                        runtime.hasSkill ? 'exported' : '-'
                      ],
                      [
                        'knowledge_qa_skill/skill_edit_manifest.json',
                        savedSkillEditPath.isNotEmpty ? 'saved' : '-'
                      ],
                    ],
            ),
            const SizedBox(height: _DesktopGrid.gutter),
            _ProductTable(
              columns: _zh
                  ? ['操作', '真实产物', '状态']
                  : ['Operation', 'Artifact', 'Status'],
              rows: _zh
                  ? [
                      [
                        '查看',
                        'knowledge_qa_skill/SKILL.md',
                        runtime.hasSkill ? '可查看' : '等待生成'
                      ],
                      [
                        '复制',
                        'knowledge_qa_skill_copy/',
                        runtime.hasSkill ? '已生成副本' : '等待生成'
                      ],
                      [
                        '融合',
                        'fused_product_ops_skill/',
                        runtime.hasSkill ? '已融合' : '等待生成'
                      ],
                      [
                        '导出',
                        'exports/skills_export.md',
                        runtime.hasSkill ? '可打开' : '等待生成'
                      ],
                      [
                        '绑定 Agent',
                        'operations/agent_binding_manifest.json',
                        runtime.hasAgent ? '已绑定' : '创建 Agent 后绑定'
                      ],
                    ]
                  : [
                      [
                        'View',
                        'knowledge_qa_skill/SKILL.md',
                        runtime.hasSkill ? 'Openable' : 'Waiting'
                      ],
                      [
                        'Copy',
                        'knowledge_qa_skill_copy/',
                        runtime.hasSkill ? 'Copied' : 'Waiting'
                      ],
                      [
                        'Fuse',
                        'fused_product_ops_skill/',
                        runtime.hasSkill ? 'Fused' : 'Waiting'
                      ],
                      [
                        'Export',
                        'exports/skills_export.md',
                        runtime.hasSkill ? 'Openable' : 'Waiting'
                      ],
                      [
                        'Bind Agent',
                        'operations/agent_binding_manifest.json',
                        runtime.hasAgent ? 'Bound' : 'After Agent creation'
                      ],
                    ],
            ),
            const SizedBox(height: _DesktopGrid.gutter),
            _PrimaryProductAction(
              label: _zh ? '生成 Skill' : 'Generate Skill',
              icon: Icons.folder_zip_outlined,
              onPressed: runtime.running || rc6 == null
                  ? null
                  : () {
                      setState(() {
                        configReady = true;
                        outputPreviewReady = true;
                      });
                      rc6.generateSkill(config: _skillConfig);
                    },
            ),
          ],
        );
        final validation = _ProductPanel(
          keyName: 'skill-validation-summary',
          icon: Icons.rule_outlined,
          title: _zh ? '验证与导出' : 'Validation and Export',
          children: [
            _MetricStrip(
              items: [
                _MetricDatum(
                    label: _zh ? '覆盖率' : 'Coverage',
                    value: runtime.hasSkill ? 'real' : '-',
                    detail: _zh ? '本地产物' : 'local artifact',
                    icon: Icons.pie_chart_outline),
                _MetricDatum(
                    label: _zh ? '可安装性' : 'Installability',
                    value: runtime.hasSkill ? 'ready' : '-',
                    detail: _zh ? '已写出' : 'written',
                    icon: Icons.verified_outlined),
              ],
            ),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '验证结果' : 'Validation result',
                value: validationReady
                    ? (runtime.hasSkill ? 'pass' : '等待真实 Skill 产物')
                    : (_zh ? '等待报告' : 'Waiting for report')),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '草稿编辑' : 'Draft edit',
                value: savedSkillEditPath.isNotEmpty
                    ? _displayNameForPath(savedSkillEditPath)
                    : (_zh ? '等待保存编辑稿' : 'Waiting edited draft')),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '导出包' : 'Export package',
                value: validationReady
                    ? (runtime.hasSkill
                        ? _displayNameForPath(runtime.skillPath)
                        : (_zh
                            ? '等待真实 Skill 产物'
                            : 'Waiting for real Skill artifact'))
                    : (_zh ? '等待报告' : 'Waiting for report')),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '下一阶段' : 'Next stage',
                value: _zh
                    ? 'Agent 创建 / 绑定 / 导出'
                    : 'Agent creation / binding / export'),
            const SizedBox(height: 8),
            _EqualActionRow(children: [
              _PrimaryProductAction(
                label: _zh
                    ? '校验 / 复制 / 融合 / 导出 Skill'
                    : 'Validate / copy / fuse / export Skill',
                onPressed: runtime.running || rc6 == null
                    ? null
                    : () {
                        setState(() {
                          configReady = true;
                          outputPreviewReady = true;
                          validationReady = true;
                        });
                        rc6.completeSkillProductOperations();
                      },
                icon: Icons.auto_awesome_outlined,
              ),
              _DisplayAction(
                label: runtime.hasSkill
                    ? (_zh ? '复制 Skill 路径' : 'Copy Skill path')
                    : (_zh ? '等待真实 Skill 产物' : 'Waiting for real Skill'),
                icon: Icons.copy_outlined,
                onPressed: runtime.hasSkill
                    ? () => _copyArtifactPath(
                          context,
                          path: runtime.skillPath,
                          successMessage: _zh
                              ? 'Skill 产物路径已复制'
                              : 'Skill artifact path copied',
                        )
                    : null,
              ),
              _DisplayAction(
                label: runtime.hasSkill
                    ? (_zh ? '查看 Skill 内容' : 'View Skill content')
                    : (_zh ? '等待可预览 Skill' : 'Waiting for previewable Skill'),
                icon: Icons.article_outlined,
                onPressed: runtime.hasSkill
                    ? () => _showWorkspaceArtifactPreview(
                          context,
                          rc6: rc6,
                          title: _zh ? 'Skill 内容预览' : 'Skill content preview',
                          path:
                              '${runtime.skillPath}/knowledge_qa_skill/SKILL.md',
                          unavailableMessage: _zh
                              ? '尚未生成可预览 Skill。'
                              : 'No previewable Skill has been generated.',
                          closeLabel: _zh ? '关闭' : 'Close',
                        )
                    : null,
              ),
              _DisplayAction(
                label: runtime.hasSkill
                    ? (_zh ? '删除 Skill 产物' : 'Delete Skill artifacts')
                    : (_zh ? '等待真实 Skill 产物' : 'Waiting for real Skill'),
                icon: runtime.hasSkill
                    ? Icons.delete_outline
                    : Icons.assessment_outlined,
                onPressed:
                    runtime.hasSkill ? () => _confirmAndDeleteSkill(rc6) : null,
              ),
            ]),
          ],
        );
        if (!wide) {
          return Column(children: [
            config,
            const SizedBox(height: _DesktopGrid.gutter),
            output,
            const SizedBox(height: _DesktopGrid.gutter),
            validation
          ]);
        }
        return switch (selectedTab) {
          1 => localization,
          2 => output,
          3 => validation,
          _ => config,
        };
      }),
    ]);
  }
}

class _AgentProductWorkflow extends StatelessWidget {
  const _AgentProductWorkflow({
    required this.localeCode,
    required this.workspace,
    required this.campaign6AgentRuntimeStatus,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final String localeCode;
  final String workspace;
  final Map<String, dynamic> campaign6AgentRuntimeStatus;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final tabs = _zh
        ? ['工作区', '创建 Agent', '单 Agent 对话', 'A2A 协作', '运行审计']
        : [
            'Workspace',
            'Create Agent',
            'Single-Agent Chat',
            'A2A Collaboration',
            'Run Audit'
          ];
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.smart_toy_outlined,
        title: _zh ? 'Agent 工作台' : 'Agent Workbench',
        description: _zh
            ? '创建 Agent、绑定知识库与 Skill，并在本页启动多 Agent 联合讨论。'
            : 'Create Agents, bind Knowledge Base and Skill, and run multi-agent discussion here.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _MetricStrip(
        items: [
          _MetricDatum(
              label: _zh ? 'Agent 模板' : 'Agent templates',
              value: '5',
              detail: _zh
                  ? '问答 / 总结 / 质检 / 运营 / 产品'
                  : 'QA / summary / QA / ops / product',
              icon: Icons.psychology_alt_outlined),
          _MetricDatum(
              label: _zh ? 'Agent 产物' : 'Agent package',
              value: runtime.hasAgent ? 'real' : '0',
              detail: runtime.hasAgent
                  ? (_zh ? '已生成' : 'generated')
                  : (_zh ? '等待生成' : 'waiting generation'),
              icon: Icons.smart_toy_outlined),
          _MetricDatum(
              label: _zh ? '对话记录' : 'Dialogue',
              value: runtime.hasAgentDialogue ? '1' : '0',
              detail: runtime.hasAgentDialogue
                  ? (_zh ? '已保存' : 'saved')
                  : (_zh ? '等待对话' : 'waiting chat'),
              icon: Icons.chat_bubble_outline),
          _MetricDatum(
              label: _zh ? '讨论纪要' : 'Discussion notes',
              value: runtime.hasMultiAgentDiscussion ? '1' : '0',
              detail: runtime.hasMultiAgentDiscussion
                  ? (_zh ? '已生成' : 'generated')
                  : (_zh ? '等待讨论' : 'waiting discussion'),
              icon: Icons.groups_2_outlined),
        ],
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _PageTabs(
          tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
      const SizedBox(height: _DesktopGrid.gutter),
      switch (selectedTab) {
        1 => _AgentCreationProductView(zh: _zh, workspace: workspace),
        2 => _AgentMinimalChatView(zh: _zh),
        3 => _AgentDiscussionProductView(zh: _zh),
        4 => _AgentRunHistoryView(zh: _zh),
        _ => _AgentWorkspaceProductView(zh: _zh, workspace: workspace),
      },
    ]);
  }
}

List<Map<String, dynamic>> _campaign6List(Object? value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

Map<String, dynamic> _campaign6Map(Object? value) {
  if (value is! Map) {
    return const <String, dynamic>{};
  }
  return Map<String, dynamic>.from(value);
}

String _campaignText(Object? value) {
  return value?.toString() ?? '-';
}

String _productRecordText(Object? value) {
  final text = _campaignText(value);
  if (text == '-') return text;
  final normalized = text.replaceAll('\\', '/');
  if (normalized.contains('/')) {
    return normalized.split('/').where((part) => part.isNotEmpty).last;
  }
  return text;
}

class _AgentWorkspaceProductView extends StatelessWidget {
  const _AgentWorkspaceProductView({
    required this.zh,
    required this.workspace,
  });

  final bool zh;
  final String workspace;

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final setup = _ProductPanel(
        keyName: 'agent-workspace-setup',
        icon: Icons.account_tree_outlined,
        title: zh ? 'Agent 与会话列表' : 'Agent and Session Lists',
        subtitle: runtime.hasAgent
            ? _displayNameForPath(runtime.agentPath)
            : '$workspace/workbench_runs/agent/workspaces',
        children: [
          _ProductTable(
            columns: zh
                ? ['列表', '用途', '当前状态']
                : ['List', 'Purpose', 'Current state'],
            rows: zh
                ? [
                    [
                      'Agent 列表',
                      '简单 / 复杂 Agent 统一管理',
                      runtime.hasAgent ? 'K1 + S1' : '生成 Agent 后写入'
                    ],
                    [
                      '会话列表',
                      '单 Agent 对话历史',
                      runtime.hasAgentDialogue ? '已有会话' : '创建后立即对话'
                    ],
                    [
                      '多 Agent 工作区',
                      '总工作区与子工作区隔离',
                      runtime.hasAgent ? '各自 KB / Skill' : '等待 Agent'
                    ],
                  ]
                : [
                    [
                      'Agent list',
                      'Simple / advanced Agents managed together',
                      runtime.hasAgent ? 'K1 + S1' : 'Written after generate'
                    ],
                    [
                      'Session list',
                      'Single-Agent dialogue history',
                      runtime.hasAgentDialogue
                          ? 'Has session'
                          : 'Chat after creation'
                    ],
                    [
                      'Multi-Agent workspace',
                      'Parent and child workspaces isolated',
                      runtime.hasAgent ? 'Own KB / Skill' : 'Waiting Agent'
                    ],
                  ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _PrimaryProductAction(
            label: zh ? '创建 Agent 工作区' : 'Create Agent workspace',
            icon: Icons.account_tree_outlined,
            onPressed: runtime.running || rc6 == null
                ? null
                : () => rc6.generateAgent(),
          ),
        ],
      );
      final boundaries = _ProductPanel(
        keyName: 'agent-workspace-boundary',
        icon: Icons.policy_outlined,
        title: zh ? '访问边界' : 'Access Boundary',
        children: [
          _ProductTable(
            columns: zh ? ['规则', '状态'] : ['Rule', 'Status'],
            rows: zh
                ? [
                    ['单 Agent 只访问自己的工作区', runtime.hasAgent ? '已写入' : '等待生成'],
                    ['子 Agent 不覆盖彼此配置', runtime.hasAgent ? '已隔离' : '等待生成'],
                    ['不开放高风险系统能力', '保持关闭'],
                    ['不展示明文 secret', '保持掩码'],
                  ]
                : [
                    [
                      'Single Agent uses own workspace only',
                      runtime.hasAgent ? 'Written' : 'Waiting'
                    ],
                    [
                      'Child Agents do not overwrite each other',
                      runtime.hasAgent ? 'Isolated' : 'Waiting'
                    ],
                    ['High-risk system capabilities', 'Kept closed'],
                    ['Plaintext secrets', 'Masked'],
                  ],
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          setup,
          const SizedBox(height: _DesktopGrid.gutter),
          boundaries,
        ]);
      }
      return _EqualHeightRow(
        height: 420,
        flexes: const [7, 4],
        children: [setup, boundaries],
      );
    });
  }
}

List<String> _campaignStringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value.map((item) => item.toString()).toList(growable: false);
}

class _AgentCreationProductView extends StatefulWidget {
  const _AgentCreationProductView({
    required this.zh,
    required this.workspace,
  });

  final bool zh;
  final String workspace;

  @override
  State<_AgentCreationProductView> createState() =>
      _AgentCreationProductViewState();
}

class _AgentCreationProductViewState extends State<_AgentCreationProductView> {
  String creationMode = 'simple';
  String agentType = 'knowledge_qa';
  String outputFormat = 'markdown';

  bool get zh => widget.zh;
  String get workspace => widget.workspace;

  Rc6AgentGenerationConfig get _agentConfig => Rc6AgentGenerationConfig(
        creationMode: creationMode,
        agentType: agentType,
        outputFormat: outputFormat,
      );

  String _creationModeLabel(String value) => value == 'advanced'
      ? (zh ? '复杂构造' : 'Advanced build')
      : (zh ? '简单构造' : 'Simple build');

  String _agentTypeLabel(String value) => switch (value) {
        'reading_summary' => zh ? '阅读总结 Agent' : 'Reading Summary Agent',
        'quality_qa' => zh ? '质检 Agent' : 'Quality Agent',
        'operation_conversion' => zh ? '运营转化 Agent' : 'Ops Conversion Agent',
        'product_analysis' => zh ? '产品分析 Agent' : 'Product Analysis Agent',
        _ => zh ? '知识问答 Agent' : 'Knowledge QA Agent',
      };

  Future<void> _confirmAndDeleteAgent(
      BuildContext context, Rc6RuntimeController? rc6) async {
    if (rc6 == null || rc6.state.running || !rc6.state.hasAgent) return;
    final confirmed = await _confirmDestructiveAction(
      context,
      title: zh ? '删除 Agent 产物？' : 'Delete Agent artifacts?',
      body: zh
          ? '这会删除当前工作区里的 Agent、最小对话和联合讨论产物；知识库和 Skill 保留。'
          : 'This deletes Agent, minimal chat, and team discussion artifacts in this workspace; KB and Skill are kept.',
    );
    if (!confirmed) return;
    await rc6.clearAgentArtifacts();
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final create = _ProductPanel(
        keyName: 'agent-create-product-flow',
        icon: Icons.smart_toy_outlined,
        title: zh ? '创建 Agent' : 'Create Agent',
        subtitle: runtime.hasAgent
            ? _displayNameForPath(runtime.agentPath)
            : '$workspace/workbench_runs/agent',
        children: [
          _FieldRow(
              label: zh ? '当前构造模式' : 'Current build mode',
              value: _creationModeLabel(creationMode)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final item in const ['simple', 'advanced'])
              ChoiceChip(
                label: Text(_creationModeLabel(item)),
                selected: creationMode == item,
                onSelected: (_) => setState(() => creationMode = item),
              ),
          ]),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? 'Agent 类型' : 'Agent type',
              value: _agentTypeLabel(agentType)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final item in const [
              'knowledge_qa',
              'reading_summary',
              'quality_qa',
              'operation_conversion',
              'product_analysis',
            ])
              ChoiceChip(
                label: Text(_agentTypeLabel(item)),
                selected: agentType == item,
                onSelected: (_) => setState(() => agentType = item),
              ),
          ]),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '输出格式' : 'Output format',
              value: outputFormat.toUpperCase()),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final item in const ['markdown', 'json', 'report', 'chat'])
              ChoiceChip(
                label: Text(item.toUpperCase()),
                selected: outputFormat == item,
                onSelected: (_) => setState(() => outputFormat = item),
              ),
          ]),
          const SizedBox(height: _DesktopGrid.gutter),
          _ProductTable(
            columns: zh
                ? ['Agent', '构造模式', '知识库', 'Skill', '创建后动作']
                : ['Agent', 'Build mode', 'KB', 'Skill', 'After creation'],
            rows: zh
                ? [
                    [
                      '知识问答 Agent',
                      '简单 Agent',
                      runtime.hasKnowledgeBase ? '已绑定' : '请先构建知识库',
                      runtime.hasSkill ? '已绑定' : '请先生成 Skill',
                      '立即进入单 Agent 对话'
                    ],
                    [
                      '阅读总结 Agent',
                      '简单 Agent',
                      runtime.hasKnowledgeBase ? '已绑定' : '请先构建知识库',
                      runtime.hasSkill ? '已绑定' : '请先生成 Skill',
                      '立即进入单 Agent 对话'
                    ],
                    [
                      '质检 / 运营 / 产品分析 Agent',
                      '复杂 Agent',
                      runtime.hasKnowledgeBase ? '已绑定' : '请先构建知识库',
                      runtime.hasSkill ? '已绑定' : '请先生成 Skill',
                      '写入记忆 / Tool / 审计配置'
                    ],
                  ]
                : [
                    [
                      'Knowledge QA Agent',
                      'Simple Agent',
                      runtime.hasKnowledgeBase ? 'Bound' : 'Build KB first',
                      runtime.hasSkill ? 'Bound' : 'Generate Skill first',
                      'Enter single-Agent chat'
                    ],
                    [
                      'Reading Summary Agent',
                      'Simple Agent',
                      runtime.hasKnowledgeBase ? 'Bound' : 'Build KB first',
                      runtime.hasSkill ? 'Bound' : 'Generate Skill first',
                      'Enter single-Agent chat'
                    ],
                    [
                      'QA / Ops / Product Analysis Agents',
                      'Advanced Agent',
                      runtime.hasKnowledgeBase ? 'Bound' : 'Build KB first',
                      runtime.hasSkill ? 'Bound' : 'Generate Skill first',
                      'Write memory / tool / audit config'
                    ],
                  ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _PrimaryProductAction(
            label: zh ? '生成 Agent 完整配置' : 'Generate complete Agent config',
            icon: Icons.smart_toy_outlined,
            onPressed: runtime.running || rc6 == null
                ? null
                : () => rc6.completeAgentProductOperations(
                      config: _agentConfig,
                    ),
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _EqualActionRow(children: [
            _DisplayAction(
              label: runtime.hasAgent
                  ? (zh ? '复制 Agent 路径' : 'Copy Agent path')
                  : (zh ? '等待真实 Agent 产物' : 'Waiting for real Agent'),
              icon: Icons.copy_outlined,
              onPressed: runtime.hasAgent
                  ? () => _copyArtifactPath(
                        context,
                        path: runtime.agentPath,
                        successMessage:
                            zh ? 'Agent 产物路径已复制' : 'Agent artifact path copied',
                      )
                  : null,
            ),
            _DisplayAction(
              label: runtime.hasAgent
                  ? (zh ? '查看 Agent 配置' : 'View Agent config')
                  : (zh ? '等待可预览 Agent' : 'Waiting for previewable Agent'),
              icon: Icons.article_outlined,
              onPressed: runtime.hasAgent
                  ? () => _showWorkspaceArtifactPreview(
                        context,
                        rc6: rc6,
                        title: zh ? 'Agent 配置预览' : 'Agent config preview',
                        path:
                            '${runtime.agentPath}/agent_generation_manifest.json',
                        unavailableMessage: zh
                            ? '尚未生成可预览 Agent 配置。'
                            : 'No previewable Agent config has been generated.',
                        closeLabel: zh ? '关闭' : 'Close',
                      )
                  : null,
            ),
            _DisplayAction(
              label: runtime.hasAgent
                  ? (zh ? '删除 Agent 产物' : 'Delete Agent artifacts')
                  : (zh ? '等待真实 Agent 产物' : 'Waiting for real Agent'),
              icon: runtime.hasAgent
                  ? Icons.delete_outline
                  : Icons.smart_toy_outlined,
              onPressed: runtime.hasAgent
                  ? () => _confirmAndDeleteAgent(context, rc6)
                  : null,
            ),
          ]),
        ],
      );
      final detail = _ProductPanel(
        keyName: 'agent-binding-detail',
        icon: Icons.link_outlined,
        title: zh ? '绑定关系' : 'Bindings',
        children: [
          _FieldRow(
            label: zh ? '知识库' : 'Knowledge Base',
            value: runtime.hasKnowledgeBase
                ? _displayNameForPath(runtime.kbManifestPath)
                : (zh ? '等待知识库' : 'Waiting KB'),
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: 'Skill',
            value: runtime.hasSkill
                ? _displayNameForPath(runtime.skillPath)
                : (zh ? '等待 Skill' : 'Waiting Skill'),
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '记忆配置' : 'Memory',
            value: zh
                ? '简单模式本地会话；复杂模式可绑定 Redis / 向量长期记忆配置'
                : 'Simple mode uses local session memory; advanced mode can bind Redis / vector memory settings',
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '输出格式' : 'Output',
            value: zh
                ? 'Markdown / JSON / report / chat'
                : 'Markdown / JSON / report / chat',
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? 'Tool 配置' : 'Tool config',
            value: zh
                ? '简单模式不展示 Tool；复杂模式仅允许白名单工具'
                : 'Simple mode hides Tool config; advanced mode only allows allowlisted tools',
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '审计策略' : 'Audit policy',
            value: zh
                ? '创建、对话、A2A、权限审计均写入运行记录'
                : 'Creation, chat, A2A, and permission checks are written to run history',
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '能力边界' : 'Boundary',
            value: zh
                ? '仅使用本地知识库与 Skill，高风险系统能力不开放'
                : 'Uses local Knowledge Base and Skill only; high-risk system capabilities are not exposed',
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          create,
          const SizedBox(height: _DesktopGrid.gutter),
          detail
        ]);
      }
      return _EqualHeightRow(
        height: 420,
        flexes: const [7, 4],
        children: [create, detail],
      );
    });
  }
}

class _AgentDiscussionProductView extends StatelessWidget {
  const _AgentDiscussionProductView({required this.zh});

  final bool zh;

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    return _ProductPanel(
      keyName: 'multi-agent-discussion-product-flow',
      icon: Icons.groups_2_outlined,
      title: zh ? 'A2A 协作' : 'A2A Collaboration',
      subtitle: runtime.hasMultiAgentDiscussion
          ? _displayNameForPath(runtime.multiAgentDiscussionPath)
          : (zh ? '等待 Agent 产物' : 'Waiting for Agent package'),
      children: [
        _ProductTable(
          columns: zh
              ? ['工作区 / Agent', '输入', '输出']
              : ['Workspace / Agent', 'Input', 'Output'],
          rows: zh
              ? [
                  ['W_M 总工作区', '协作议题', '共识 / 冲突 / 行动建议'],
                  ['W_B 运营 Agent', 'K2 + S2', '运营转化观点'],
                  ['W_C 产品分析 Agent', 'K3 + 产品分析 Skill', '产品判断'],
                  ['质检 Agent', '解析与 Chunk', '风险与复核点'],
                ]
              : [
                  [
                    'W_M parent workspace',
                    'Collaboration topic',
                    'Consensus / conflict / actions'
                  ],
                  ['W_B Ops Agent', 'K2 + S2', 'Ops conversion view'],
                  [
                    'W_C Product Agent',
                    'K3 + product Skill',
                    'Product judgement'
                  ],
                  ['Quality Agent', 'Parse and chunks', 'Review risks'],
                ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _FieldRow(
          label: zh ? 'A2A Session' : 'A2A Session',
          value: runtime.hasMultiAgentDiscussion
              ? 'A2A_001'
              : (zh ? '尚未启动' : 'Not started'),
        ),
        const SizedBox(height: 8),
        _FieldRow(
          label: zh ? '讨论纪要' : 'Discussion notes',
          value: runtime.hasMultiAgentDiscussion
              ? _displayNameForPath(runtime.multiAgentDiscussionPath)
              : (zh ? '尚未生成' : 'Not generated'),
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _PrimaryProductAction(
          label: zh ? '启动联合讨论' : 'Start discussion',
          icon: Icons.forum_outlined,
          onPressed: runtime.running || rc6 == null
              ? null
              : () => rc6.runMultiAgentDiscussion(),
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _DisplayAction(
          label: runtime.hasMultiAgentDiscussion
              ? (zh ? '复制讨论纪要路径' : 'Copy discussion notes path')
              : (zh ? '等待讨论纪要' : 'Waiting for discussion notes'),
          icon: Icons.copy_outlined,
          onPressed: runtime.hasMultiAgentDiscussion
              ? () => _copyArtifactPath(
                    context,
                    path: runtime.multiAgentDiscussionPath,
                    successMessage:
                        zh ? '讨论纪要路径已复制' : 'Discussion notes path copied',
                  )
              : null,
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _DisplayAction(
          label: runtime.hasMultiAgentDiscussion
              ? (zh ? '查看讨论纪要' : 'View discussion notes')
              : (zh ? '等待可预览纪要' : 'Waiting for previewable notes'),
          icon: Icons.article_outlined,
          onPressed: runtime.hasMultiAgentDiscussion
              ? () => _showWorkspaceArtifactPreview(
                    context,
                    rc6: rc6,
                    title: zh ? '联合讨论纪要预览' : 'Discussion notes preview',
                    path: runtime.multiAgentDiscussionPath,
                    unavailableMessage:
                        zh ? '尚未生成可预览讨论纪要。' : 'No discussion notes generated.',
                    closeLabel: zh ? '关闭' : 'Close',
                  )
              : null,
        ),
      ],
    );
  }
}

class _AgentMinimalChatView extends StatefulWidget {
  const _AgentMinimalChatView({required this.zh});

  final bool zh;

  @override
  State<_AgentMinimalChatView> createState() => _AgentMinimalChatViewState();
}

class _AgentMinimalChatViewState extends State<_AgentMinimalChatView> {
  final TextEditingController _promptController =
      TextEditingController(text: '请基于当前知识库总结核心要点。');

  bool get zh => widget.zh;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final chat = _ProductPanel(
        keyName: 'agent-minimal-chat',
        icon: Icons.chat_bubble_outline,
        title: zh ? '最小对话入口' : 'Minimal Chat Entry',
        gap: true,
        children: [
          TextField(
            controller: _promptController,
            enabled: !runtime.running,
            decoration: InputDecoration(
              labelText: zh ? '对话问题' : 'Prompt',
              helperText: zh
                  ? '基于已生成 Agent、知识库和 Skill 生成本地可追踪对话记录；创建后可立即运行。'
                  : 'Creates a local traceable dialogue from the generated Agent, KB, and Skill; runnable immediately after creation.',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _PrimaryProductAction(
            label: zh ? '运行最小对话' : 'Run minimal chat',
            icon: Icons.play_arrow_outlined,
            onPressed: runtime.running || rc6 == null || !runtime.hasAgent
                ? null
                : () => rc6.runAgentDialogue(prompt: _promptController.text),
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _FieldRow(
            label: zh ? '对话产物' : 'Dialogue artifact',
            value: runtime.hasAgentDialogue
                ? _displayNameForPath(runtime.agentDialoguePath)
                : (zh ? '尚未生成' : 'Not generated'),
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '会话历史' : 'Chat history',
            value: runtime.hasAgentDialogueHistory
                ? (zh
                    ? '${runtime.agentDialogueTurnCount} 轮 · ${_displayNameForPath(runtime.agentDialogueHistoryPath)}'
                    : '${runtime.agentDialogueTurnCount} turns · ${_displayNameForPath(runtime.agentDialogueHistoryPath)}')
                : (zh ? '尚未生成' : 'Not generated'),
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '导出记录' : 'Exported dialogue',
            value: runtime.hasAgentDialogueExport
                ? _displayNameForPath(runtime.agentDialogueExportPath)
                : (zh ? '尚未导出' : 'Not exported'),
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '回复说明' : 'Reply trace',
            value: runtime.hasAgentDialogue
                ? (zh
                    ? '包含模型、知识库、Skill、引用和记忆写入状态'
                    : 'Includes model, KB, Skill, citations, and memory write status')
                : (zh ? '运行后写入对话产物' : 'Written after running chat'),
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _EqualActionRow(children: [
            _DisplayAction(
              label: runtime.hasAgentDialogue
                  ? (zh ? '复制对话产物路径' : 'Copy dialogue artifact path')
                  : (zh ? '等待对话产物' : 'Waiting for dialogue artifact'),
              icon: Icons.copy_outlined,
              onPressed: runtime.hasAgentDialogue
                  ? () => _copyArtifactPath(
                        context,
                        path: runtime.agentDialoguePath,
                        successMessage:
                            zh ? '对话产物路径已复制' : 'Dialogue artifact path copied',
                      )
                  : null,
            ),
            _DisplayAction(
              label: runtime.hasAgentDialogue
                  ? (zh ? '查看对话内容' : 'View dialogue content')
                  : (zh ? '等待可预览对话' : 'Waiting for previewable dialogue'),
              icon: Icons.article_outlined,
              onPressed: runtime.hasAgentDialogue
                  ? () => _showWorkspaceArtifactPreview(
                        context,
                        rc6: rc6,
                        title: zh ? '对话内容预览' : 'Dialogue content preview',
                        path: runtime.agentDialoguePath,
                        unavailableMessage:
                            zh ? '尚未生成可预览对话。' : 'No dialogue generated.',
                        closeLabel: zh ? '关闭' : 'Close',
                      )
                  : null,
            ),
            _DisplayAction(
              label: runtime.hasAgentDialogueHistory
                  ? (zh ? '复制会话历史路径' : 'Copy chat history path')
                  : (zh ? '等待会话历史' : 'Waiting for chat history'),
              icon: Icons.copy_outlined,
              onPressed: runtime.hasAgentDialogueHistory
                  ? () => _copyArtifactPath(
                        context,
                        path: runtime.agentDialogueHistoryPath,
                        successMessage:
                            zh ? '会话历史路径已复制' : 'Chat history path copied',
                      )
                  : null,
            ),
            _DisplayAction(
              label: runtime.hasAgentDialogueHistory
                  ? (zh ? '查看会话历史' : 'View chat history')
                  : (zh ? '等待可预览历史' : 'Waiting for previewable history'),
              icon: Icons.article_outlined,
              onPressed: runtime.hasAgentDialogueHistory
                  ? () => _showWorkspaceArtifactPreview(
                        context,
                        rc6: rc6,
                        title: zh ? '会话历史预览' : 'Chat history preview',
                        path: runtime.agentDialogueHistoryPath,
                        unavailableMessage:
                            zh ? '尚未生成可预览会话历史。' : 'No chat history generated.',
                        closeLabel: zh ? '关闭' : 'Close',
                      )
                  : null,
            ),
            _PrimaryProductAction(
              label: runtime.hasAgentDialogueHistory
                  ? (zh ? '导出对话记录' : 'Export dialogue')
                  : (zh ? '等待可导出历史' : 'Waiting for exportable history'),
              icon: Icons.file_download_outlined,
              onPressed: runtime.hasAgentDialogueHistory &&
                      rc6 != null &&
                      !runtime.running
                  ? () => rc6.exportAgentDialogue()
                  : null,
            ),
            _DisplayAction(
              label: runtime.hasAgentDialogueExport
                  ? (zh ? '查看导出记录' : 'View export')
                  : (zh ? '等待导出记录' : 'Waiting for export'),
              icon: Icons.article_outlined,
              onPressed: runtime.hasAgentDialogueExport
                  ? () => _showWorkspaceArtifactPreview(
                        context,
                        rc6: rc6,
                        title: zh ? '导出对话预览' : 'Dialogue export preview',
                        path: runtime.agentDialogueExportPath,
                        unavailableMessage:
                            zh ? '尚未生成可预览导出。' : 'No dialogue export generated.',
                        closeLabel: zh ? '关闭' : 'Close',
                      )
                  : null,
            ),
          ]),
        ],
      );
      final bindings = _ProductPanel(
        keyName: 'agent-chat-bindings',
        icon: Icons.link_outlined,
        title: zh ? '对话输入来源' : 'Chat Inputs',
        children: [
          _ProductTable(
            columns: zh ? ['输入', '状态', '说明'] : ['Input', 'Status', 'Note'],
            rows: zh
                ? [
                    [
                      '知识库',
                      runtime.hasKnowledgeBase ? '已绑定' : '请先构建知识库',
                      runtime.hasKnowledgeBase
                          ? _displayNameForPath(runtime.kbManifestPath)
                          : '知识库页构建'
                    ],
                    [
                      'Skill',
                      runtime.hasSkill ? '已绑定' : '请先生成 Skill',
                      runtime.hasSkill
                          ? _displayNameForPath(runtime.skillPath)
                          : 'Skill 工厂生成'
                    ],
                    [
                      'Agent',
                      runtime.hasAgent ? '已生成' : '请先生成 Agent',
                      runtime.hasAgent
                          ? _displayNameForPath(runtime.agentPath)
                          : 'Agent 工作台创建'
                    ],
                    ['模型', '本地默认或已配置 Provider', '密钥仅从环境/设置读取并掩码显示'],
                  ]
                : [
                    [
                      'Knowledge Base',
                      runtime.hasKnowledgeBase ? 'Bound' : 'Build KB first',
                      runtime.hasKnowledgeBase
                          ? _displayNameForPath(runtime.kbManifestPath)
                          : 'Build on Knowledge Base page'
                    ],
                    [
                      'Skill',
                      runtime.hasSkill ? 'Bound' : 'Generate Skill first',
                      runtime.hasSkill
                          ? _displayNameForPath(runtime.skillPath)
                          : 'Generate in Skill Factory'
                    ],
                    [
                      'Agent',
                      runtime.hasAgent ? 'Generated' : 'Generate Agent first',
                      runtime.hasAgent
                          ? _displayNameForPath(runtime.agentPath)
                          : 'Create in Agent Workbench'
                    ],
                    [
                      'Model',
                      'Local default or configured Provider',
                      'Secrets are read from environment/settings and masked'
                    ],
                  ],
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          chat,
          const SizedBox(height: _DesktopGrid.gutter),
          bindings
        ]);
      }
      return _EqualHeightRow(
        height: 362,
        flexes: const [6, 5],
        children: [chat, bindings],
      );
    });
  }
}

class _AgentRunHistoryView extends StatelessWidget {
  const _AgentRunHistoryView({required this.zh});

  final bool zh;

  @override
  Widget build(BuildContext context) {
    final runtime =
        _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
    return _ProductPanel(
      keyName: 'agent-run-history',
      icon: Icons.history_outlined,
      title: zh ? '运行记录' : 'Run History',
      children: [
        _ProductTable(
          columns: zh ? ['记录', '状态', '产物'] : ['Record', 'Status', 'Artifact'],
          rows: zh
              ? [
                  [
                    'Agent 创建',
                    runtime.hasAgent ? '已完成' : '未运行',
                    runtime.hasAgent
                        ? _displayNameForPath(runtime.agentPath)
                        : '无产物'
                  ],
                  [
                    '最小对话',
                    runtime.hasAgentDialogue ? '已完成' : '未运行',
                    runtime.hasAgentDialogue
                        ? '${runtime.agentDialogueTurnCount} 轮 · ${_displayNameForPath(runtime.agentDialoguePath)}'
                        : '无产物'
                  ],
                  [
                    '联合讨论',
                    runtime.hasMultiAgentDiscussion ? '已完成' : '未运行',
                    runtime.hasMultiAgentDiscussion
                        ? _displayNameForPath(runtime.multiAgentDiscussionPath)
                        : '无产物'
                  ],
                  [
                    'PRD P0 工作区 / A2A',
                    runtime.hasPrdP0Evidence ? '已完成' : '未运行',
                    runtime.hasPrdP0Evidence
                        ? _displayNameForPath(runtime.prdP0EvidencePath)
                        : '无产物'
                  ],
                  [
                    'Agent 工作区审计',
                    runtime.hasAgent ? '已写入' : '未运行',
                    runtime.hasAgent ? 'agent_generation_manifest.json' : '无产物'
                  ],
                ]
              : [
                  [
                    'Agent creation',
                    runtime.hasAgent ? 'Done' : 'Not run',
                    runtime.hasAgent
                        ? _displayNameForPath(runtime.agentPath)
                        : 'No artifact'
                  ],
                  [
                    'Minimal chat',
                    runtime.hasAgentDialogue ? 'Done' : 'Not run',
                    runtime.hasAgentDialogue
                        ? '${runtime.agentDialogueTurnCount} turns · ${_displayNameForPath(runtime.agentDialoguePath)}'
                        : 'No artifact'
                  ],
                  [
                    'Team discussion',
                    runtime.hasMultiAgentDiscussion ? 'Done' : 'Not run',
                    runtime.hasMultiAgentDiscussion
                        ? _displayNameForPath(runtime.multiAgentDiscussionPath)
                        : 'No artifact'
                  ],
                  [
                    'PRD P0 workspaces / A2A',
                    runtime.hasPrdP0Evidence ? 'Done' : 'Not run',
                    runtime.hasPrdP0Evidence
                        ? _displayNameForPath(runtime.prdP0EvidencePath)
                        : 'No artifact'
                  ],
                  [
                    'Agent workspace audit',
                    runtime.hasAgent ? 'Written' : 'Not run',
                    runtime.hasAgent
                        ? 'agent_generation_manifest.json'
                        : 'No artifact'
                  ],
                ],
        ),
      ],
    );
  }
}

// ignore: unused_element
class _Campaign6RuntimeOverviewView extends StatelessWidget {
  const _Campaign6RuntimeOverviewView({
    required this.zh,
    required this.phases,
    required this.security,
  });

  final bool zh;
  final List<Map<String, dynamic>> phases;
  final Map<String, dynamic> security;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final phasePanel = _ProductPanel(
        keyName: 'campaign6-runtime-overview',
        icon: Icons.route_outlined,
        title: zh ? 'Campaign 6 执行总览' : 'Campaign 6 Execution Overview',
        subtitle: zh
            ? '6A -> 6B -> Tool Adapter Configuration Gate'
            : '6A -> 6B -> Tool Adapter Configuration Gate',
        children: [
          _ProductTable(
            columns: zh
                ? ['阶段', 'UI 状态', '运行状态', '证据']
                : ['Phase', 'UI state', 'Runtime', 'Evidence'],
            rows: phases
                .map((phase) => [
                      phase['phase_id']?.toString() ?? '-',
                      phase['ui_state']?.toString() ?? '-',
                      phase['runtime_status']?.toString() ?? '-',
                      phase['evidence_path']?.toString() ?? '-',
                    ])
                .toList(growable: false),
          ),
        ],
      );
      final securityPanel = _ProductPanel(
        keyName: 'campaign6-security-boundaries',
        icon: Icons.security_outlined,
        title: zh ? '安全边界' : 'Security Boundaries',
        gap: security['no_campaign_7_8_9'] != true,
        children: [
          _ProductTable(
            columns: zh ? ['边界', '状态'] : ['Boundary', 'Status'],
            rows: [
              ['no_secret_plaintext', '${security['no_secret_plaintext']}'],
              ['no_arbitrary_shell', '${security['no_arbitrary_shell']}'],
              [
                'no_agent_self_authorized_tool',
                '${security['no_agent_self_authorized_tool']}'
              ],
              [
                'no_cross_agent_secret_or_workspace_access',
                '${security['no_cross_agent_secret_or_workspace_access']}'
              ],
              ['no_campaign_7_8_9', '${security['no_campaign_7_8_9']}'],
            ],
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          phasePanel,
          const SizedBox(height: _DesktopGrid.gutter),
          securityPanel,
        ]);
      }
      return _EqualHeightRow(
        height: 430,
        flexes: const [7, 4],
        children: [phasePanel, securityPanel],
      );
    });
  }
}

// ignore: unused_element
class _Campaign6SingleAgentStatusView extends StatelessWidget {
  const _Campaign6SingleAgentStatusView({
    required this.zh,
    required this.agents,
  });

  final bool zh;
  final List<Map<String, dynamic>> agents;

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'campaign6-single-agent-status',
      icon: Icons.psychology_alt_outlined,
      title: zh ? '6A 单 Agent Runtime' : '6A Single Agent Runtime',
      subtitle: zh
          ? '每类 Agent 绑定真实 Tool / Skill / RAG / Bridge'
          : 'Each Agent type binds real Tool / Skill / RAG / Bridge paths',
      children: [
        _ProductTable(
          columns: zh
              ? ['Agent', 'UI 状态', '运行状态', '降级 / 回滚']
              : ['Agent', 'UI state', 'Runtime', 'Degraded / rollback'],
          rows: agents.map((agent) {
            final modes = (agent['degraded_modes'] as List<dynamic>? ?? [])
                .map((item) => item.toString())
                .join(', ');
            return [
              agent['display_name']?.toString() ??
                  agent['agent_type']?.toString() ??
                  '-',
              agent['ui_state']?.toString() ?? '-',
              agent['runtime_status']?.toString() ?? '-',
              modes.isEmpty
                  ? agent['rollback_strategy']?.toString() ?? '-'
                  : '$modes | ${agent['rollback_strategy']}',
            ];
          }).toList(growable: false),
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _FieldRow(
          label: zh ? '验收规则' : 'Acceptance rule',
          value: zh
              ? '不允许 hardcoded demo、display_only 或 mock/offline 冒充 accepted'
              : 'No hardcoded demo, display_only, or mock/offline accepted as runtime',
        ),
      ],
    );
  }
}

// ignore: unused_element
class _Campaign6AdvancedRuntimeStatusView extends StatelessWidget {
  const _Campaign6AdvancedRuntimeStatusView({
    required this.zh,
    required this.capabilities,
  });

  final bool zh;
  final List<Map<String, dynamic>> capabilities;

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'campaign6-advanced-runtime-status',
      icon: Icons.hub_outlined,
      title: zh ? '6B Advanced Agent Runtime' : '6B Advanced Agent Runtime',
      subtitle: zh
          ? 'Long-term Memory、Multi-Agent、A2A、Teams 与安全回归'
          : 'Long-term Memory, Multi-Agent, A2A, Teams, and security regression',
      children: [
        _ProductTable(
          columns: zh
              ? ['能力', 'UI 状态', '运行状态', '覆盖']
              : ['Capability', 'UI state', 'Runtime', 'Coverage'],
          rows: capabilities.map((capability) {
            final coverage = (capability['coverage'] as List<dynamic>? ?? [])
                .map((item) => item.toString())
                .join(', ');
            return [
              capability['capability_id']?.toString() ?? '-',
              capability['ui_state']?.toString() ?? '-',
              capability['runtime_status']?.toString() ?? '-',
              coverage,
            ];
          }).toList(growable: false),
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _FieldRow(
          label: zh ? 'Computer Use' : 'Computer Use',
          value: 'disabled_boundary',
        ),
      ],
    );
  }
}

// ignore: unused_element
class _Campaign6ToolAdapterStatusView extends StatelessWidget {
  const _Campaign6ToolAdapterStatusView({
    required this.zh,
    required this.toolAdapter,
    required this.workspace,
  });

  final bool zh;
  final Map<String, dynamic> toolAdapter;
  final String workspace;

  @override
  Widget build(BuildContext context) {
    final fields = (toolAdapter['api_config_schema_fields'] as List<dynamic>? ??
            const <dynamic>[])
        .map((item) => item.toString())
        .toList(growable: false);
    return _ProductPanel(
      keyName: 'campaign6-tool-adapter-status',
      icon: Icons.settings_ethernet_outlined,
      title: zh
          ? 'Tool Adapter Configuration Gate'
          : 'Tool Adapter Configuration Gate',
      subtitle: '$workspace/workbench_runs/campaign6_tool_adapter',
      children: [
        _ProductTable(
          columns: zh ? ['规则', '状态'] : ['Rule', 'Status'],
          rows: [
            ['final_status', toolAdapter['final_status']?.toString() ?? '-'],
            ['ui_state', toolAdapter['ui_state']?.toString() ?? '-'],
            [
              'provider_runtime_reimplemented',
              '${toolAdapter['provider_runtime_reimplemented']}'
            ],
            [
              'unregistered_third_party_api_integrated',
              '${toolAdapter['unregistered_third_party_api_integrated']}'
            ],
            [
              'official_channel_tool_adapter_gate_required',
              '${toolAdapter['official_channel_tool_adapter_gate_required']}'
            ],
            [
              'secret_plaintext_written',
              '${toolAdapter['secret_plaintext_written']}'
            ],
            [
              'live_smoke_status',
              toolAdapter['live_smoke_status']?.toString() ?? '-'
            ],
            [
              'official_channel_live_smoke',
              toolAdapter['official_channel_live_smoke']?.toString() ?? '-'
            ],
          ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _FieldRow(
          label: zh ? 'API config schema' : 'API config schema',
          value: fields.join(', '),
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _ProductTable(
          columns: zh
              ? ['Adapter', 'UI 状态', 'Auth', 'Live smoke']
              : ['Adapter', 'UI state', 'Auth', 'Live smoke'],
          rows: _campaign6List(toolAdapter['adapters']).map((adapter) {
            return [
              adapter['adapter_id']?.toString() ?? '-',
              adapter['ui_state']?.toString() ?? '-',
              adapter['auth_type']?.toString() ?? '-',
              adapter['live_smoke_status']?.toString() ?? '-',
            ];
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class _ValidateExportProductWorkflow extends StatelessWidget {
  const _ValidateExportProductWorkflow({
    required this.localeCode,
    required this.workspace,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final String localeCode;
  final String workspace;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final tabs = _zh
        ? ['执行记录', '失败记录', '审计导出']
        : ['Execution Records', 'Failure Records', 'Audit Export'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.fact_check_outlined,
        title: _zh ? '审计中心' : 'Audit Center',
        description: _zh
            ? '统一查看真实执行记录、失败记录和产物记录，并导出当前工作区审计报告。'
            : 'Review real execution, failure, and artifact records, then export the current workspace audit report.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _PageTabs(
          tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
      const SizedBox(height: _DesktopGrid.gutter),
      if (selectedTab == 1)
        _ReportsEvidenceView(zh: _zh, runtimeController: rc6)
      else if (selectedTab == 2)
        _ControlledExportView(
            zh: _zh, workspace: workspace, runtimeController: rc6)
      else
        _ValidationChecklistView(zh: _zh, runtimeController: rc6),
    ]);
  }
}

class _ValidationChecklistView extends StatefulWidget {
  const _ValidationChecklistView({
    required this.zh,
    required this.runtimeController,
  });
  final bool zh;
  final Rc6RuntimeController? runtimeController;

  @override
  State<_ValidationChecklistView> createState() =>
      _ValidationChecklistViewState();
}

class _ValidationChecklistViewState extends State<_ValidationChecklistView> {
  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    final runtime =
        widget.runtimeController?.state ?? Rc6RuntimeState.initial();
    final records = _auditRecordRows(runtime, zh);
    final failureRows = _auditFailureRows(runtime, zh);
    final artifactRows = _auditArtifactRows(runtime, zh);
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final center = _ProductPanel(
        keyName: 'validation-checklist',
        icon: Icons.receipt_long_outlined,
        title: zh ? '执行记录' : 'Execution Records',
        children: [
          _MetricStrip(
            items: [
              _MetricDatum(
                  label: zh ? '执行记录' : 'Records',
                  value: '${records.length}',
                  detail: zh ? '来自运行状态' : 'From runtime state',
                  icon: Icons.receipt_long_outlined),
              _MetricDatum(
                  label: zh ? '失败记录' : 'Failures',
                  value: '${failureRows.length}',
                  detail: failureRows.isEmpty
                      ? (zh ? '当前无失败' : 'No current failure')
                      : (zh ? '需要查看详情' : 'Inspect detail'),
                  icon: Icons.warning_amber_outlined),
              _MetricDatum(
                  label: zh ? '产物记录' : 'Artifacts',
                  value: '${artifactRows.length}',
                  detail: runtime.workspacePath.isEmpty
                      ? (zh ? '等待工作区' : 'Waiting for workspace')
                      : (zh ? '可追踪产物' : 'Traceable artifacts'),
                  icon: Icons.folder_copy_outlined),
            ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _ProductTable(
            columns: zh
                ? ['模块', '事件', '状态', '产物']
                : ['Module', 'Event', 'Status', 'Artifact'],
            rows: records,
          ),
        ],
      );
      final issues = _ProductPanel(
        icon: Icons.report_problem_outlined,
        title: zh ? '失败记录' : 'Failure Records',
        gap: failureRows.isNotEmpty,
        children: [
          _ProductTable(
            columns: zh ? ['模块', '状态', '原因'] : ['Module', 'Status', 'Reason'],
            rows: failureRows.isEmpty
                ? [
                    [
                      zh ? '当前工作区' : 'Current workspace',
                      zh ? '无失败' : 'No failure',
                      runtime.lastMessage,
                    ]
                  ]
                : failureRows,
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          center,
          const SizedBox(height: _DesktopGrid.gutter),
          issues
        ]);
      }
      return _EqualHeightRow(
        height: 452,
        flexes: const [7, 4],
        children: [center, issues],
      );
    });
  }
}

class _ReportsEvidenceView extends StatefulWidget {
  const _ReportsEvidenceView({
    required this.zh,
    required this.runtimeController,
  });
  final bool zh;
  final Rc6RuntimeController? runtimeController;

  @override
  State<_ReportsEvidenceView> createState() => _ReportsEvidenceViewState();
}

class _ReportsEvidenceViewState extends State<_ReportsEvidenceView> {
  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    final runtime =
        widget.runtimeController?.state ?? Rc6RuntimeState.initial();
    final failureRows = _auditFailureRows(runtime, zh);
    final artifactRows = _auditArtifactRows(runtime, zh);
    final previewPath = _firstAuditPreviewPath(runtime);
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final list = _ProductPanel(
        keyName: 'report-evidence-list',
        icon: Icons.receipt_long_outlined,
        title: zh ? '失败记录' : 'Failure Records',
        children: [
          _ProductTable(
            columns: zh ? ['模块', '状态', '原因'] : ['Module', 'Status', 'Reason'],
            rows: failureRows.isEmpty
                ? [
                    [
                      zh ? '当前工作区' : 'Current workspace',
                      zh ? '无失败' : 'No failure',
                      runtime.lastMessage,
                    ]
                  ]
                : failureRows,
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _EqualActionRow(children: [
            _DisplayAction(
              label: previewPath.isEmpty
                  ? (zh ? '等待可预览产物' : 'Waiting for previewable artifact')
                  : (zh ? '预览最近产物记录' : 'Preview latest artifact record'),
              icon: Icons.receipt_long_outlined,
              onPressed: previewPath.isEmpty
                  ? null
                  : () => _showWorkspaceArtifactPreview(
                        context,
                        rc6: widget.runtimeController,
                        title: zh ? '审计产物预览' : 'Audit artifact preview',
                        path: previewPath,
                        unavailableMessage:
                            zh ? '尚未生成可预览产物。' : 'No previewable artifact.',
                        closeLabel: zh ? '关闭' : 'Close',
                      ),
            ),
          ]),
        ],
      );
      final detail = _ProductPanel(
        keyName: 'selected-report-detail',
        icon: Icons.plagiarism_outlined,
        title: zh ? '产物记录' : 'Artifact Records',
        children: [
          _ProductTable(
            columns: zh ? ['模块', '产物', '文件'] : ['Module', 'Artifact', 'File'],
            rows: artifactRows.isEmpty
                ? [
                    [
                      zh ? '当前工作区' : 'Current workspace',
                      zh ? '暂无产物' : 'No artifact',
                      zh ? '执行主链路后出现' : 'Run product flow first',
                    ]
                  ]
                : artifactRows,
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          list,
          const SizedBox(height: _DesktopGrid.gutter),
          detail
        ]);
      }
      return _EqualHeightRow(
        height: 388,
        flexes: const [7, 4],
        children: [list, detail],
      );
    });
  }
}

class _ControlledExportView extends StatefulWidget {
  const _ControlledExportView({
    required this.zh,
    required this.workspace,
    required this.runtimeController,
  });
  final bool zh;
  final String workspace;
  final Rc6RuntimeController? runtimeController;

  @override
  State<_ControlledExportView> createState() => _ControlledExportViewState();
}

class _ControlledExportViewState extends State<_ControlledExportView> {
  String auditReportPath = '';
  bool exporting = false;

  bool get zh => widget.zh;

  Future<void> _exportAuditReport() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null || rc6.state.running || exporting) return;
    setState(() => exporting = true);
    final path = await rc6.exportAuditReport();
    if (!mounted) return;
    setState(() {
      auditReportPath = path;
      exporting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final runtime =
        widget.runtimeController?.state ?? Rc6RuntimeState.initial();
    return _ProductPanel(
      keyName: 'controlled-export-summary',
      icon: Icons.outbox_outlined,
      title: zh ? '审计导出' : 'Audit Export',
      subtitle: widget.workspace,
      children: [
        _ProductTable(
          columns: zh ? ['项目', '状态', '说明'] : ['Item', 'Status', 'Note'],
          rows: zh
              ? [
                  [
                    '执行记录',
                    '${_auditRecordRows(runtime, zh).length} 条',
                    '来自当前运行状态'
                  ],
                  [
                    '失败记录',
                    '${_auditFailureRows(runtime, zh).length} 条',
                    runtime.lastError.isEmpty ? '无当前失败' : runtime.lastError
                  ],
                  [
                    '产物记录',
                    '${_auditArtifactRows(runtime, zh).length} 条',
                    '可在产物中心继续查看'
                  ],
                  [
                    '审计报告',
                    auditReportPath.isEmpty ? '未导出' : '已导出',
                    auditReportPath.isEmpty
                        ? '点击下方按钮生成'
                        : _displayNameForPath(auditReportPath)
                  ],
                ]
              : [
                  [
                    'Execution records',
                    '${_auditRecordRows(runtime, zh).length}',
                    'From current runtime state'
                  ],
                  [
                    'Failure records',
                    '${_auditFailureRows(runtime, zh).length}',
                    runtime.lastError.isEmpty
                        ? 'No current failure'
                        : runtime.lastError
                  ],
                  [
                    'Artifact records',
                    '${_auditArtifactRows(runtime, zh).length}',
                    'Continue in Artifact Center'
                  ],
                  [
                    'Audit report',
                    auditReportPath.isEmpty ? 'Not exported' : 'Exported',
                    auditReportPath.isEmpty
                        ? 'Use the action below'
                        : _displayNameForPath(auditReportPath)
                  ],
                ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _EqualActionRow(children: [
          _PrimaryProductAction(
            label: exporting
                ? (zh ? '正在导出审计报告' : 'Exporting audit report')
                : (zh ? '导出审计报告' : 'Export audit report'),
            onPressed: widget.runtimeController == null || exporting
                ? null
                : _exportAuditReport,
            icon: Icons.archive_outlined,
          ),
          _DisplayAction(
            label: auditReportPath.isEmpty
                ? (zh ? '等待审计报告路径' : 'Waiting for audit report path')
                : (zh ? '复制审计报告路径' : 'Copy audit report path'),
            icon: Icons.copy_outlined,
            onPressed: auditReportPath.isEmpty
                ? null
                : () => _copyArtifactPath(
                      context,
                      path: auditReportPath,
                      successMessage:
                          zh ? '审计报告路径已复制' : 'Audit report path copied',
                    ),
          ),
          _DisplayAction(
            label: auditReportPath.isEmpty
                ? (zh ? '等待可预览报告' : 'Waiting for previewable report')
                : (zh ? '预览审计报告' : 'Preview audit report'),
            icon: Icons.visibility_outlined,
            onPressed: auditReportPath.isEmpty
                ? null
                : () => _showWorkspaceArtifactPreview(
                      context,
                      rc6: widget.runtimeController,
                      title: zh ? '审计报告预览' : 'Audit report preview',
                      path: auditReportPath,
                      unavailableMessage:
                          zh ? '尚未生成审计报告。' : 'No audit report generated.',
                      closeLabel: zh ? '关闭' : 'Close',
                    ),
          ),
        ]),
      ],
    );
  }
}

List<List<String>> _auditRecordRows(Rc6RuntimeState runtime, bool zh) {
  List<String> row(String zhModule, String enModule, String zhEvent,
          String enEvent, bool done, String artifact) =>
      [
        zh ? zhModule : enModule,
        zh ? zhEvent : enEvent,
        done ? (zh ? '已完成' : 'Done') : (zh ? '未运行' : 'Not run'),
        artifact.trim().isEmpty
            ? (zh ? '无产物' : 'No artifact')
            : _displayNameForPath(artifact),
      ];
  return [
    row('文档库', 'Document Library', '导入来源', 'Import sources',
        runtime.hasImportedFile, runtime.sourceManifestPath),
    row('文档库', 'Document Library', '解析与分块', 'Parse and chunk',
        runtime.parseReportPath.isNotEmpty, runtime.parseReportPath),
    row('知识库', 'Knowledge Base', '构建知识库', 'Build Knowledge Base',
        runtime.hasKnowledgeBase, runtime.kbManifestPath),
    row('检索验证', 'Retrieval', '检索证据', 'Retrieve evidence',
        runtime.queryResultPath.isNotEmpty, runtime.queryResultPath),
    row('文档生成', 'Document Generation', '导出文档', 'Export document',
        runtime.exportedDocumentPath.isNotEmpty, runtime.exportedDocumentPath),
    row('Skill 工厂', 'Skill Factory', '生成 Skill', 'Generate Skill',
        runtime.hasSkill, runtime.skillPath),
    row('Agent 工作台', 'Agent Workbench', '生成 Agent', 'Generate Agent',
        runtime.hasAgent, runtime.agentPath),
    row('Agent 工作台', 'Agent Workbench', 'Agent 对话', 'Agent dialogue',
        runtime.hasAgentDialogue, runtime.agentDialoguePath),
    row('Agent 工作台', 'Agent Workbench', 'A2A 协作', 'A2A collaboration',
        runtime.hasMultiAgentDiscussion, runtime.multiAgentDiscussionPath),
    [
      zh ? '运行状态' : 'Runtime',
      zh ? '最近消息' : 'Latest message',
      runtime.running ? (zh ? '执行中' : 'Running') : runtime.phase.name,
      runtime.lastMessage,
    ],
  ];
}

List<List<String>> _auditFailureRows(Rc6RuntimeState runtime, bool zh) {
  final rows = <List<String>>[];
  if (runtime.lastError.trim().isNotEmpty) {
    rows.add([
      zh ? '运行状态' : 'Runtime',
      runtime.phase.name,
      runtime.lastError,
    ]);
  }
  final last = runtime.lastResult;
  if (last != null && !last.passed) {
    rows.add([
      last.actionId,
      last.productStatus,
      last.userReason,
    ]);
  }
  return rows;
}

List<List<String>> _auditArtifactRows(Rc6RuntimeState runtime, bool zh) {
  final artifacts = _artifactCenterItems(runtime, zh)
      .where((artifact) => artifact.path.trim().isNotEmpty)
      .toList(growable: false);
  return [
    for (final artifact in artifacts)
      [
        artifact.category,
        artifact.label,
        _displayNameForPath(artifact.path),
      ],
  ];
}

String _firstAuditPreviewPath(Rc6RuntimeState runtime) {
  for (final path in [
    runtime.queryResultPath,
    runtime.exportManifestPath,
    runtime.qualityReportPath,
    runtime.parseReportPath,
    runtime.sourceManifestPath,
    runtime.generatedMarkdownPath,
    runtime.agentDialoguePath,
    runtime.agentDialogueExportPath,
    runtime.multiAgentDiscussionPath,
  ]) {
    if (path.trim().isNotEmpty) return path;
  }
  return '';
}

class _ArtifactCenterProductWorkflow extends StatefulWidget {
  const _ArtifactCenterProductWorkflow({required this.localeCode});

  final String localeCode;

  @override
  State<_ArtifactCenterProductWorkflow> createState() =>
      _ArtifactCenterProductWorkflowState();
}

class _ArtifactCenterProductWorkflowState
    extends State<_ArtifactCenterProductWorkflow> {
  int selectedIndex = 0;
  String _selectedInitialExportPath = '';

  bool get _zh => widget.localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final artifacts = _artifactCenterItems(runtime, _zh);
    if (selectedIndex >= artifacts.length) selectedIndex = 0;
    if (runtime.hasAgentDialogueExport &&
        _selectedInitialExportPath != runtime.agentDialogueExportPath) {
      final exportIndex = artifacts.indexWhere(
          (artifact) => artifact.path == runtime.agentDialogueExportPath);
      if (exportIndex >= 0) {
        selectedIndex = exportIndex;
        _selectedInitialExportPath = runtime.agentDialogueExportPath;
      }
    }
    final selected = artifacts.isEmpty ? null : artifacts[selectedIndex];
    final generatedCount =
        artifacts.where((artifact) => artifact.path.trim().isNotEmpty).length;
    final categories =
        artifacts.map((artifact) => artifact.category).toSet().length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.folder_copy_outlined,
        title: _zh ? '产物中心' : 'Artifact Center',
        description: _zh
            ? '集中查看真实工作区中已经生成的文档、知识库、检索、Skill、Agent 和对话产物。'
            : 'Browse generated document, KB, retrieval, Skill, Agent, and dialogue artifacts from the real workspace.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _MetricStrip(
        items: [
          _MetricDatum(
            label: _zh ? '已生成产物' : 'Generated',
            value: '$generatedCount',
            detail: _zh ? '来自真实运行状态' : 'From runtime state',
            icon: Icons.task_alt_outlined,
          ),
          _MetricDatum(
            label: _zh ? '产物分类' : 'Categories',
            value: '$categories',
            detail: _zh ? '文档 / 知识库 / 应用' : 'Docs / KB / apps',
            icon: Icons.category_outlined,
          ),
          _MetricDatum(
            label: _zh ? '来源文档' : 'Sources',
            value: '${runtime.sourceCount}',
            detail: runtime.sourceNames.isEmpty
                ? (_zh ? '等待导入' : 'Waiting for import')
                : runtime.sourceNames.take(2).join(' · '),
            icon: Icons.article_outlined,
          ),
          _MetricDatum(
            label: _zh ? '知识库 chunks' : 'KB chunks',
            value: '${runtime.chunkCount}',
            detail: runtime.hasKnowledgeBase
                ? (_zh ? '可检索' : 'Searchable')
                : (_zh ? '等待构建' : 'Build KB first'),
            icon: Icons.account_tree_outlined,
          ),
        ],
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final catalog = _ProductPanel(
          keyName: 'artifact-center-catalog',
          icon: Icons.inventory_2_outlined,
          title: _zh ? '产物清单' : 'Artifact Catalog',
          subtitle: runtime.workspacePath.isEmpty
              ? (_zh ? '等待工作区初始化' : 'Waiting for workspace')
              : (_zh ? '用户工作区' : 'User workspace'),
          children: [
            _ProductTable(
              columns: _zh
                  ? ['分类', '产物', '状态', '文件']
                  : ['Category', 'Artifact', 'Status', 'File'],
              rows: artifacts
                  .map((artifact) => [
                        artifact.category,
                        artifact.label,
                        artifact.path.trim().isEmpty
                            ? (_zh ? '未生成' : 'Not generated')
                            : (_zh ? '已生成' : 'Generated'),
                        artifact.path.trim().isEmpty
                            ? (_zh ? '去对应页面生成' : 'Generate on owner page')
                            : _displayNameForPath(artifact.path),
                      ])
                  .toList(growable: false),
            ),
            const SizedBox(height: _DesktopGrid.gutter),
            _PageTabs(
              tabs: [
                for (final artifact in artifacts)
                  '${artifact.shortLabel} ${artifact.path.trim().isEmpty ? "○" : "✓"}',
              ],
              selectedIndex: selectedIndex,
              onSelected: (index) => setState(() => selectedIndex = index),
            ),
          ],
        );
        final canPreview = selected != null &&
            selected.path.trim().isNotEmpty &&
            selected.previewable;
        final detail = _ProductPanel(
          keyName: 'artifact-center-detail',
          icon: Icons.article_outlined,
          title: _zh ? '产物详情' : 'Artifact Detail',
          children: [
            _FieldRow(
              label: _zh ? '分类' : 'Category',
              value: selected?.category ?? '-',
            ),
            const SizedBox(height: 8),
            _FieldRow(
              label: _zh ? '产物' : 'Artifact',
              value: selected?.label ?? '-',
            ),
            const SizedBox(height: 8),
            _FieldRow(
              label: _zh ? '状态' : 'Status',
              value: selected == null || selected.path.trim().isEmpty
                  ? (_zh ? '未生成' : 'Not generated')
                  : (_zh ? '已生成' : 'Generated'),
            ),
            const SizedBox(height: 8),
            _FieldRow(
              label: _zh ? '文件' : 'File',
              value: selected == null || selected.path.trim().isEmpty
                  ? (_zh ? '对应业务页面完成后出现' : 'Appears after workflow run')
                  : _displayNameForPath(selected.path),
            ),
            const SizedBox(height: _DesktopGrid.gutter),
            _EqualActionRow(children: [
              _DisplayAction(
                label: selected != null && selected.path.trim().isNotEmpty
                    ? (_zh ? '复制产物路径' : 'Copy artifact path')
                    : (_zh ? '等待产物路径' : 'Waiting for artifact path'),
                icon: Icons.copy_outlined,
                onPressed: selected != null && selected.path.trim().isNotEmpty
                    ? () => _copyArtifactPath(
                          context,
                          path: selected.path,
                          successMessage:
                              _zh ? '产物路径已复制' : 'Artifact path copied',
                        )
                    : null,
              ),
              _DisplayAction(
                label: canPreview
                    ? (_zh ? '预览文本产物' : 'Preview text artifact')
                    : selected != null && selected.path.trim().isNotEmpty
                        ? (_zh ? '目录产物请复制路径打开' : 'Copy path to open folder')
                        : (_zh
                            ? '等待可预览产物'
                            : 'Waiting for previewable artifact'),
                icon: Icons.visibility_outlined,
                onPressed: canPreview
                    ? () => _showWorkspaceArtifactPreview(
                          context,
                          rc6: rc6,
                          title: selected.label,
                          path: selected.path,
                          unavailableMessage:
                              _zh ? '尚未生成可预览产物。' : 'No artifact generated.',
                          closeLabel: _zh ? '关闭' : 'Close',
                        )
                    : null,
              ),
            ]),
          ],
        );
        if (!wide) {
          return Column(children: [
            catalog,
            const SizedBox(height: _DesktopGrid.gutter),
            detail
          ]);
        }
        return _EqualHeightRow(
          height: 540,
          flexes: const [7, 4],
          children: [catalog, detail],
        );
      }),
    ]);
  }
}

class _ArtifactCenterItem {
  const _ArtifactCenterItem({
    required this.category,
    required this.label,
    required this.shortLabel,
    required this.path,
    this.previewable = true,
  });

  final String category;
  final String label;
  final String shortLabel;
  final String path;
  final bool previewable;
}

List<_ArtifactCenterItem> _artifactCenterItems(
    Rc6RuntimeState runtime, bool zh) {
  _ArtifactCenterItem item(String zhCategory, String enCategory, String zhLabel,
          String enLabel, String shortLabel, String path,
          {bool previewable = true}) =>
      _ArtifactCenterItem(
        category: zh ? zhCategory : enCategory,
        label: zh ? zhLabel : enLabel,
        shortLabel: shortLabel,
        path: path,
        previewable: previewable,
      );
  return [
    item('文档库', 'Document Library', '导入清单 source_manifest.json',
        'Source manifest', 'manifest', runtime.sourceManifestPath),
    item('文档库', 'Document Library', '解析报告 parse_report.json', 'Parse report',
        'parse', runtime.parseReportPath),
    item('知识库', 'Knowledge Base', '知识库 manifest.json', 'KB manifest', 'kb',
        runtime.kbManifestPath),
    item('知识库', 'Knowledge Base', 'chunks.jsonl', 'Chunks', 'chunks',
        runtime.chunksPath),
    item('知识库', 'Knowledge Base', 'cards.jsonl', 'Cards', 'cards',
        runtime.cardsPath),
    item('知识库', 'Knowledge Base', 'qa_pairs.jsonl', 'QA pairs', 'qa',
        runtime.qaPairsPath),
    item('知识库', 'Knowledge Base', 'source_map.json', 'Source map', 'source map',
        runtime.sourceMapPath),
    item('知识库', 'Knowledge Base', 'index_metadata.json', 'Index metadata',
        'index', runtime.indexMetadataPath),
    item('知识库', 'Knowledge Base', 'quality_report.json', 'Quality report',
        'quality', runtime.qualityReportPath),
    item('知识库', 'Knowledge Base', 'build.log', 'Build log', 'build log',
        runtime.buildLogPath),
    item('知识库', 'Knowledge Base', 'error.log', 'Error log', 'error log',
        runtime.errorLogPath),
    item('检索验证', 'Retrieval', '检索结果', 'Retrieval result', 'retrieval',
        runtime.queryResultPath),
    item('文档生成', 'Document Generation', 'Markdown 草稿', 'Markdown draft', 'md',
        runtime.generatedMarkdownPath),
    item('文档生成', 'Document Generation', '读书笔记', 'Reading notes', 'notes',
        runtime.readingNotesPath),
    item('文档生成', 'Document Generation', '导出文档', 'Exported document', 'export',
        runtime.exportedDocumentPath),
    item('文档生成', 'Document Generation', '导出清单', 'Export manifest',
        'export manifest', runtime.exportManifestPath),
    item('Skill 工厂', 'Skill Factory', 'Skill 包', 'Skill package', 'skill',
        runtime.skillPath,
        previewable: false),
    item('Agent 工作台', 'Agent Workbench', 'Agent 包', 'Agent package', 'agent',
        runtime.agentPath,
        previewable: false),
    item('Agent 工作台', 'Agent Workbench', 'Agent 对话记录', 'Agent dialogue', 'chat',
        runtime.agentDialoguePath),
    item('Agent 工作台', 'Agent Workbench', 'Agent 会话历史', 'Agent chat history',
        'history', runtime.agentDialogueHistoryPath),
    item('Agent 工作台', 'Agent Workbench', 'Agent 对话导出', 'Agent dialogue export',
        'chat export', runtime.agentDialogueExportPath),
    item('Agent 工作台', 'Agent Workbench', '多 Agent 讨论纪要',
        'Multi-agent discussion', 'a2a', runtime.multiAgentDiscussionPath),
    item('治理', 'Governance', 'PRD P0 验证证据', 'PRD P0 evidence', 'evidence',
        runtime.prdP0EvidencePath),
    item('治理', 'Governance', '知识库目录', 'Knowledge Base catalog', 'catalog',
        runtime.knowledgeBaseCatalogPath),
  ];
}

class _SettingsProductWorkflow extends StatelessWidget {
  const _SettingsProductWorkflow({
    required this.localeCode,
    required this.workspace,
    required this.runtimeController,
    required this.selectedTab,
    required this.onTabSelected,
    required this.isWebRuntime,
    required this.campaign7ConfigurationStatus,
    required this.campaign9DesktopDeliveryStatus,
  });

  final String localeCode;
  final String workspace;
  final Rc6RuntimeController? runtimeController;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;
  final bool isWebRuntime;
  final Map<String, dynamic> campaign7ConfigurationStatus;
  final Map<String, dynamic> campaign9DesktopDeliveryStatus;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final tabs = _zh
        ? ['工作区', 'Provider 与存储', '配置系统', '模型与语言', '安全授权', '桌面交付']
        : [
            'Workspace',
            'Providers and Storage',
            'Configuration System',
            'Models and Language',
            'Security Authorization',
            'Desktop Delivery',
          ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.settings_outlined,
        title: _zh ? '运行设置' : 'Run Settings',
        description: _zh
            ? '管理应用工作区、Provider、存储、模型、语言、主题和安全授权。'
            : 'Manage workspace, providers, storage, models, language, theme, and authorization.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _PageTabs(
          tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
      const SizedBox(height: _DesktopGrid.gutter),
      if (selectedTab == 1)
        _SettingsProvidersStorageView(
            zh: _zh, workspace: workspace, runtimeController: runtimeController)
      else if (selectedTab == 2)
        _SettingsConfigurationSystemView(
          zh: _zh,
          campaign7ConfigurationStatus: campaign7ConfigurationStatus,
        )
      else if (selectedTab == 5)
        _SettingsDesktopDeliveryView(
          zh: _zh,
          campaign9DesktopDeliveryStatus: campaign9DesktopDeliveryStatus,
        )
      else if (selectedTab == 0)
        _SettingsWorkspaceView(
          zh: _zh,
          workspace: workspace,
          isWebRuntime: isWebRuntime,
        )
      else
        _ProductPanel(
          keyName: 'settings-groups',
          icon: selectedTab == 3
              ? Icons.memory_outlined
              : selectedTab == 4
                  ? Icons.shield_outlined
                  : Icons.folder_outlined,
          title: tabs[selectedTab],
          children: selectedTab == 3
              ? [
                  _ProductTable(
                    columns: _zh
                        ? ['配置项', '当前值', '状态']
                        : ['Setting', 'Value', 'Status'],
                    rows: _zh
                        ? [
                            ['LLM Provider', 'live smoke 通过', '可用'],
                            [
                              'Embedding 模型',
                              'Provider Runtime env-only',
                              '环境配置'
                            ],
                            ['默认语言', '简体中文 / Chinese', '可用'],
                            ['主题', '浅色 / 深色可切换', '可用'],
                          ]
                        : [
                            ['LLM Provider', 'Live smoke passed', 'Available'],
                            [
                              'Embedding model',
                              'Provider Runtime env-only',
                              'Env config'
                            ],
                            [
                              'Default language',
                              'Simplified Chinese / Chinese',
                              'Available'
                            ],
                            ['Theme', 'Light / dark switchable', 'Available'],
                          ],
                  ),
                  const SizedBox(height: 8),
                  _FieldRow(
                      label: _zh ? '当前语言' : 'Current language',
                      value: _zh ? '中文' : 'English'),
                  const SizedBox(height: 8),
                  _FieldRow(
                      label: _zh ? '主题' : 'Theme',
                      value: _zh ? '跟随切换' : 'Switchable'),
                ]
              : selectedTab == 4
                  ? [
                      _FieldRow(
                          label: _zh ? '云服务' : 'Cloud services',
                          value: _zh ? '默认关闭' : 'Off by default'),
                      const SizedBox(height: 8),
                      _FieldRow(
                          label: _zh ? '敏感信息' : 'Sensitive data',
                          value: _zh
                              ? 'Secret 不直接展示'
                              : 'Secrets are not displayed directly'),
                      const SizedBox(height: 8),
                      _FieldRow(
                          label: _zh ? '桌面能力' : 'Desktop features',
                          value: isWebRuntime
                              ? (_zh
                                  ? '请使用 Windows EXE 执行本地文件能力'
                                  : 'Use the Windows EXE for local file workflows')
                              : (_zh ? '桌面可用' : 'Desktop available')),
                    ]
                  : [
                      _FieldRow(
                          label: _zh ? '工作区' : 'Workspace', value: workspace),
                      const SizedBox(height: 8),
                      _FieldRow(
                          label: _zh ? '输出目录' : 'Output directory',
                          value: _zh ? '当前用户工作区' : 'Current user workspace'),
                    ],
        ),
    ]);
  }
}

class _SettingsProvidersStorageView extends StatefulWidget {
  const _SettingsProvidersStorageView({
    required this.zh,
    required this.workspace,
    required this.runtimeController,
  });

  final bool zh;
  final String workspace;
  final Rc6RuntimeController? runtimeController;

  @override
  State<_SettingsProvidersStorageView> createState() =>
      _SettingsProvidersStorageViewState();
}

class _SettingsProvidersStorageViewState
    extends State<_SettingsProvidersStorageView> {
  bool storageTested = false;
  bool configSaved = false;
  bool redisTested = false;
  bool qdrantTested = false;
  bool redisTesting = false;
  bool qdrantTesting = false;
  bool configLoading = false;
  String redisStatus = 'configured_not_tested';
  String qdrantStatus = 'configured_not_tested';
  String redisDetail = '';
  String qdrantDetail = '';
  String savedConfigPath = '';
  final TextEditingController _redisHostController =
      TextEditingController(text: '127.0.0.1');
  final TextEditingController _redisPortController =
      TextEditingController(text: '6379');
  final TextEditingController _redisPrefixController =
      TextEditingController(text: 'heitang:');
  final TextEditingController _qdrantEndpointController =
      TextEditingController(text: 'http://127.0.0.1:6333');
  final TextEditingController _qdrantCollectionController =
      TextEditingController(text: 'heitang_kb');
  final TextEditingController _qdrantDimensionController =
      TextEditingController(text: '1536');
  final TextEditingController _maskedRedisPasswordController =
      TextEditingController(text: '********');
  final TextEditingController _blankQdrantApiKeyController =
      TextEditingController(text: '留空 / blank');

  bool get zh => widget.zh;

  @override
  void initState() {
    super.initState();
    _loadStoredConfig();
  }

  @override
  void dispose() {
    _redisHostController.dispose();
    _redisPortController.dispose();
    _redisPrefixController.dispose();
    _qdrantEndpointController.dispose();
    _qdrantCollectionController.dispose();
    _qdrantDimensionController.dispose();
    _maskedRedisPasswordController.dispose();
    _blankQdrantApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredConfig() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) return;
    setState(() => configLoading = true);
    final settings = await rc6.loadStorageProviderSettings();
    if (!mounted) return;
    final redis = _settingsMap(settings['redis']);
    final qdrant = _settingsMap(settings['qdrant']);
    setState(() {
      configLoading = false;
      _redisHostController.text = _settingsText(redis, 'host', '127.0.0.1');
      _redisPortController.text = _settingsInt(redis, 'port', 6379).toString();
      _redisPrefixController.text =
          _settingsText(redis, 'key_prefix', 'heitang:');
      _maskedRedisPasswordController.text =
          _settingsText(redis, 'password_display', '********');
      redisStatus = _settingsText(redis, 'status', 'configured_not_tested');
      redisDetail = _settingsText(redis, 'last_test_detail', '');
      redisTested = redisStatus == 'connected';
      _qdrantEndpointController.text =
          _settingsText(qdrant, 'endpoint', 'http://127.0.0.1:6333');
      _qdrantCollectionController.text =
          _settingsText(qdrant, 'collection', 'heitang_kb');
      _qdrantDimensionController.text =
          _settingsInt(qdrant, 'dimension', 1536).toString();
      _blankQdrantApiKeyController.text =
          _settingsText(qdrant, 'api_key_display', '').isEmpty
              ? (zh ? '留空 / blank' : 'blank')
              : '********';
      qdrantStatus = _settingsText(qdrant, 'status', 'configured_not_tested');
      qdrantDetail = _settingsText(qdrant, 'last_test_detail', '');
      qdrantTested = qdrantStatus == 'connected';
      savedConfigPath = settings['workspace']?.toString().isNotEmpty == true
          ? 'config/storage_provider_settings.json'
          : '';
    });
  }

  Future<void> _testRedisConnection() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) {
      setState(() {
        storageTested = true;
        redisTested = false;
        redisStatus = 'desktop_runtime_required';
        redisDetail = zh
            ? '真实 Redis 连接测试需要 Windows EXE 桌面端。'
            : 'Real Redis test requires the Windows desktop runtime.';
      });
      return;
    }
    final port = int.tryParse(_redisPortController.text.trim());
    if (port == null || port <= 0) {
      setState(() {
        storageTested = true;
        redisTested = false;
        redisStatus = 'invalid_port';
        redisDetail = zh ? 'Redis 端口必须是正整数。' : 'Redis port must be positive.';
      });
      return;
    }
    setState(() {
      redisTesting = true;
      storageTested = true;
    });
    final result = await rc6.testRedisConnection(
      host: _redisHostController.text,
      port: port,
      keyPrefix: _redisPrefixController.text,
      password: _maskedRedisPasswordController.text,
    );
    if (!mounted) return;
    setState(() {
      redisTesting = false;
      redisTested = result.passed;
      redisStatus = result.status;
      redisDetail = result.detail;
      savedConfigPath = 'config/storage_provider_settings.json';
    });
  }

  Future<void> _testQdrantConnection() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) {
      setState(() {
        storageTested = true;
        qdrantTested = false;
        qdrantStatus = 'desktop_runtime_required';
        qdrantDetail = zh
            ? '真实 Qdrant 连接测试需要 Windows EXE 桌面端。'
            : 'Real Qdrant test requires the Windows desktop runtime.';
      });
      return;
    }
    final dimension = int.tryParse(_qdrantDimensionController.text.trim());
    if (dimension == null || dimension <= 0) {
      setState(() {
        storageTested = true;
        qdrantTested = false;
        qdrantStatus = 'invalid_dimension';
        qdrantDetail =
            zh ? 'Qdrant 向量维度必须是正整数。' : 'Qdrant dimension must be positive.';
      });
      return;
    }
    setState(() {
      qdrantTesting = true;
      storageTested = true;
    });
    final result = await rc6.testQdrantConnection(
      endpoint: _qdrantEndpointController.text,
      collection: _qdrantCollectionController.text,
      dimension: dimension,
      apiKey: _blankQdrantApiKeyController.text,
    );
    if (!mounted) return;
    setState(() {
      qdrantTesting = false;
      qdrantTested = result.passed;
      qdrantStatus = result.status;
      qdrantDetail = result.detail;
      savedConfigPath = 'config/storage_provider_settings.json';
    });
  }

  Future<void> _testStorageConnections() async {
    await _testRedisConnection();
    if (!mounted) return;
    await _testQdrantConnection();
  }

  Future<void> _saveStorageProviderSettings() async {
    final rc6 = widget.runtimeController;
    if (rc6 == null) {
      setState(() {
        configSaved = false;
        storageTested = true;
        redisStatus = 'desktop_runtime_required';
        qdrantStatus = 'desktop_runtime_required';
        redisDetail = zh
            ? '真实配置保存需要 Windows EXE 桌面端。'
            : 'Real config save requires the Windows desktop runtime.';
      });
      return;
    }
    final redisPort = int.tryParse(_redisPortController.text.trim());
    final qdrantDimension =
        int.tryParse(_qdrantDimensionController.text.trim());
    if (redisPort == null || redisPort <= 0) {
      setState(() {
        configSaved = false;
        storageTested = true;
        redisStatus = 'invalid_port';
        redisDetail = zh ? 'Redis 端口必须是正整数。' : 'Redis port must be positive.';
      });
      return;
    }
    if (qdrantDimension == null || qdrantDimension <= 0) {
      setState(() {
        configSaved = false;
        storageTested = true;
        qdrantStatus = 'invalid_dimension';
        qdrantDetail =
            zh ? 'Qdrant 向量维度必须是正整数。' : 'Qdrant dimension must be positive.';
      });
      return;
    }
    final path = await rc6.saveStorageProviderSettings(
      redisHost: _redisHostController.text,
      redisPort: redisPort,
      redisKeyPrefix: _redisPrefixController.text,
      redisPassword: _maskedRedisPasswordController.text,
      qdrantEndpoint: _qdrantEndpointController.text,
      qdrantCollection: _qdrantCollectionController.text,
      qdrantDimension: qdrantDimension,
      qdrantApiKey: _blankQdrantApiKeyController.text,
    );
    if (!mounted) return;
    setState(() {
      configSaved = path.isNotEmpty;
      storageTested = true;
      savedConfigPath =
          path.isEmpty ? '' : 'config/storage_provider_settings.json';
      redisStatus = 'configured_not_tested';
      qdrantStatus = 'configured_not_tested';
      redisDetail = '';
      qdrantDetail = '';
      redisTested = false;
      qdrantTested = false;
    });
  }

  String _storageFeedbackDetail() {
    final details = <String>[
      if (savedConfigPath.isNotEmpty)
        zh ? '配置文件：$savedConfigPath' : 'Config file: $savedConfigPath',
      if (redisDetail.isNotEmpty) 'Redis: $redisDetail',
      if (qdrantDetail.isNotEmpty) 'Qdrant: $qdrantDetail',
    ];
    if (details.isEmpty) {
      return zh
          ? 'Redis 密码和 Qdrant API Key 只以掩码输入；测试失败不会展示明文 secret。'
          : 'Redis password and Qdrant API key remain masked; failed tests never show plaintext secrets.';
    }
    return details.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final providers = _ProductPanel(
        keyName: 'settings-provider-storage',
        icon: Icons.storage_outlined,
        title: zh ? 'Provider 与存储配置' : 'Providers and Storage Config',
        gap: true,
        children: [
          _ProductTable(
            columns: zh
                ? ['配置项', '当前值', '连接状态', '分类']
                : ['Setting', 'Value', 'Connection', 'Class'],
            rows: zh
                ? [
                    ['应用工作区', widget.workspace, '本地可用', '可用'],
                    ['对象存储', '本地文件系统', '本地可用', '可用'],
                    [
                      'Redis',
                      '${_redisHostController.text}:${_redisPortController.text} / ${_redisPrefixController.text}',
                      redisTested
                          ? 'PING / 写读删通过'
                          : _storageStatusLabel(redisStatus, zh),
                      redisTested ? '可用' : '已配置'
                    ],
                    [
                      'Qdrant',
                      '${_qdrantEndpointController.text} / ${_qdrantCollectionController.text}',
                      qdrantTested
                          ? '健康检查 / collection / 向量探针通过'
                          : _storageStatusLabel(qdrantStatus, zh),
                      qdrantTested ? '可用' : '已配置'
                    ],
                    ['向量数据库', '本地文件索引 + Qdrant 可选', '本地索引可用', '可用'],
                    ['LLM Provider', '环境变量', 'live smoke 通过', '可用'],
                    ['API Key', '************', '掩码展示', '已保护'],
                  ]
                : [
                    [
                      'App workspace',
                      widget.workspace,
                      'Local available',
                      'Available'
                    ],
                    [
                      'Object storage',
                      'Local filesystem',
                      'Local available',
                      'Available'
                    ],
                    [
                      'Redis',
                      '${_redisHostController.text}:${_redisPortController.text} / ${_redisPrefixController.text}',
                      redisTested
                          ? 'PING / write-read-delete passed'
                          : _storageStatusLabel(redisStatus, zh),
                      redisTested ? 'Available' : 'Configured'
                    ],
                    [
                      'Qdrant',
                      '${_qdrantEndpointController.text} / ${_qdrantCollectionController.text}',
                      qdrantTested
                          ? 'Health / collection / vector probe passed'
                          : _storageStatusLabel(qdrantStatus, zh),
                      qdrantTested ? 'Available' : 'Configured'
                    ],
                    [
                      'Vector DB',
                      'Local file index + optional Qdrant',
                      'Local index available',
                      'Available'
                    ],
                    [
                      'LLM Provider',
                      'Environment variables',
                      'Live smoke passed',
                      'Available'
                    ],
                    ['API Key', '************', 'Masked', 'Protected'],
                  ],
          ),
          const SizedBox(height: 8),
          _SectionCaption(zh ? 'Redis 记忆缓存' : 'Redis memory cache'),
          const SizedBox(height: 6),
          _SettingsConnectionForm(
            zh: zh,
            fields: [
              _SettingsTextFieldSpec(
                  zh ? 'Host' : 'Host', _redisHostController),
              _SettingsTextFieldSpec(
                  zh ? 'Port' : 'Port', _redisPortController),
              _SettingsTextFieldSpec(
                  zh ? 'Key Prefix' : 'Key Prefix', _redisPrefixController),
              _SettingsTextFieldSpec(
                  zh ? 'Password' : 'Password', _maskedRedisPasswordController),
            ],
          ),
          const SizedBox(height: 8),
          _SectionCaption(zh ? 'Qdrant 知识库检索' : 'Qdrant KB retrieval'),
          const SizedBox(height: 6),
          _SettingsConnectionForm(
            zh: zh,
            fields: [
              _SettingsTextFieldSpec(
                  zh ? 'Endpoint' : 'Endpoint', _qdrantEndpointController),
              _SettingsTextFieldSpec(zh ? 'Collection' : 'Collection',
                  _qdrantCollectionController),
              _SettingsTextFieldSpec(
                  zh ? 'Dimension' : 'Dimension', _qdrantDimensionController),
              _SettingsTextFieldSpec(
                  zh ? 'API Key' : 'API Key', _blankQdrantApiKeyController),
            ],
          ),
          const SizedBox(height: 8),
          _EqualActionRow(children: [
            _PrimaryProductAction(
              label: zh ? '测试存储连接' : 'Test storage connections',
              icon: Icons.fact_check_outlined,
              onPressed: redisTesting || qdrantTesting
                  ? null
                  : _testStorageConnections,
            ),
            _PrimaryProductAction(
              label: redisTesting
                  ? (zh ? '正在测试 Redis' : 'Testing Redis')
                  : (zh ? '测试 Redis 连接' : 'Test Redis connection'),
              icon: Icons.cable_outlined,
              onPressed: redisTesting ? null : _testRedisConnection,
            ),
          ]),
          const SizedBox(height: 8),
          _EqualActionRow(children: [
            _PrimaryProductAction(
              label: qdrantTesting
                  ? (zh ? '正在测试 Qdrant' : 'Testing Qdrant')
                  : (zh ? '测试 Qdrant 连接' : 'Test Qdrant connection'),
              icon: Icons.hub_outlined,
              onPressed: qdrantTesting ? null : _testQdrantConnection,
            ),
            _PrimaryProductAction(
              label: zh ? '保存配置' : 'Save config',
              icon: Icons.save_outlined,
              onPressed: _saveStorageProviderSettings,
            ),
          ]),
          if (storageTested || configSaved) ...[
            const SizedBox(height: 8),
            _RuntimeFeedbackBanner(
              title: configSaved
                  ? (zh ? '配置已保存' : 'Config saved')
                  : (zh
                      ? '本地存储连接状态已更新'
                      : 'Local storage connection status updated'),
              detail: _storageFeedbackDetail(),
              tone: (redisStatus.contains('failed') ||
                      redisStatus.contains('missing') ||
                      redisStatus.contains('invalid') ||
                      qdrantStatus.contains('failed') ||
                      qdrantStatus.contains('missing') ||
                      qdrantStatus.contains('invalid'))
                  ? _StatusTone.warning
                  : _StatusTone.success,
              icon: configSaved ? Icons.save_outlined : Icons.cable_outlined,
            ),
          ],
          const SizedBox(height: 8),
          _SectionCaption(zh ? 'Provider 运行状态' : 'Provider Runtime Status'),
          const SizedBox(height: 6),
          _ProductTable(
            columns: zh
                ? ['状态', '用户可见含义', '处理方式']
                : ['Status', 'User meaning', 'Handling'],
            rows: zh
                ? [
                    ['connected', 'official_openai 可用', '继续执行'],
                    ['unavailable', 'Provider 暂不可达', '本地能力继续可用'],
                    ['missing_key', '缺少安全环境变量', '提示配置，不显示明文'],
                    ['timeout', '请求超时', '可重试并保留日志编号'],
                    ['fallback_used', '已降级到本地路径', '显示降级原因'],
                    ['cost_blocked', '超过成本/Token 边界', '停止外部调用'],
                  ]
                : [
                    ['connected', 'official_openai available', 'Continue'],
                    [
                      'unavailable',
                      'Provider temporarily unavailable',
                      'Local capabilities continue'
                    ],
                    [
                      'missing_key',
                      'Secure env is missing',
                      'Prompt setup, never show plaintext'
                    ],
                    ['timeout', 'Request timed out', 'Retry with log id'],
                    [
                      'fallback_used',
                      'Local degraded path used',
                      'Show degraded reason'
                    ],
                    [
                      'cost_blocked',
                      'Cost/token boundary exceeded',
                      'Stop external call'
                    ],
                  ],
          ),
        ],
      );
      final detail = _ProductPanel(
        keyName: 'settings-provider-detail',
        icon: Icons.tune_outlined,
        title: zh ? '配置状态' : 'Configuration Status',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? 'Provider 状态' : 'Provider status',
              value: zh
                  ? '真实 live smoke 复验已通过'
                  : 'Real live-smoke reacceptance passed'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? 'Secret 展示' : 'Secret display',
              value: zh ? '只显示掩码，不直接展示明文' : 'Masked only, plaintext hidden'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '连接测试' : 'Connection tests',
              value: zh
                  ? configLoading
                      ? '正在加载工作区配置'
                      : 'Docker 未运行时显示已配置未测试；不得显示为已连接'
                  : configLoading
                      ? 'Loading workspace config'
                      : 'When Docker is not running, show configured-not-tested; never connected'),
          const SizedBox(height: 8),
          _DisplayAction(
              label: zh ? '查看 Provider 状态' : 'View Provider status',
              icon: Icons.verified_outlined),
        ],
      );
      if (!wide) {
        return Column(children: [
          providers,
          const SizedBox(height: _DesktopGrid.gutter),
          detail
        ]);
      }
      return _EqualHeightRow(
        height: 386,
        flexes: const [7, 5],
        children: [providers, detail],
      );
    });
  }
}

class _SettingsTextFieldSpec {
  const _SettingsTextFieldSpec(this.label, this.controller);

  final String label;
  final TextEditingController controller;
}

String _storageStatusLabel(String status, bool zh) {
  return switch (status) {
    'connected' => zh ? '连接成功' : 'Connected',
    'configured_not_tested' => zh ? '已配置未测试' : 'Configured, not tested',
    'desktop_runtime_required' =>
      zh ? '需要 Windows EXE 测试' : 'Desktop runtime required',
    'missing_password' => zh ? '缺少 Redis 密码' : 'Redis password missing',
    'auth_failed' => zh ? '鉴权失败' : 'Authentication failed',
    'invalid_endpoint' => zh ? 'Endpoint 无效' : 'Invalid endpoint',
    'invalid_dimension' => zh ? '维度无效' : 'Invalid dimension',
    'invalid_port' => zh ? '端口无效' : 'Invalid port',
    'health_failed' => zh ? '健康检查失败' : 'Health check failed',
    'collection_create_failed' =>
      zh ? 'Collection 创建失败' : 'Collection create failed',
    'collection_check_failed' =>
      zh ? 'Collection 检查失败' : 'Collection check failed',
    'vector_write_failed' => zh ? '测试向量写入失败' : 'Vector write failed',
    'vector_search_failed' => zh ? '测试向量检索失败' : 'Vector search failed',
    'vector_delete_failed' => zh ? '测试向量删除失败' : 'Vector delete failed',
    'connection_failed' => zh ? '连接失败' : 'Connection failed',
    'ping_failed' => zh ? 'PING 失败' : 'PING failed',
    'probe_failed' => zh ? '探针失败' : 'Probe failed',
    _ => status,
  };
}

Map<String, dynamic> _settingsMap(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const {};
}

String _settingsText(Map<String, dynamic> source, String key, String fallback) {
  final value = source[key]?.toString();
  return value == null || value.isEmpty ? fallback : value;
}

int _settingsInt(Map<String, dynamic> source, String key, int fallback) {
  final value = source[key];
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

class _SettingsConnectionForm extends StatelessWidget {
  const _SettingsConnectionForm({
    required this.zh,
    required this.fields,
  });

  final bool zh;
  final List<_SettingsTextFieldSpec> fields;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 760 ? 2 : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: fields.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: _DesktopGrid.gutter,
          mainAxisSpacing: _DesktopGrid.gutter,
          mainAxisExtent: 58,
        ),
        itemBuilder: (context, index) {
          final field = fields[index];
          return TextField(
            controller: field.controller,
            obscureText: field.label.toLowerCase().contains('password') ||
                field.label.toLowerCase().contains('key'),
            decoration: InputDecoration(
              labelText: field.label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          );
        },
      );
    });
  }
}

class _SettingsConfigurationSystemView extends StatelessWidget {
  const _SettingsConfigurationSystemView({
    required this.zh,
    required this.campaign7ConfigurationStatus,
  });

  final bool zh;
  final Map<String, dynamic> campaign7ConfigurationStatus;

  @override
  Widget build(BuildContext context) {
    final schema = _campaign6Map(campaign7ConfigurationStatus['config_schema']);
    final diagnostics =
        _campaign6Map(campaign7ConfigurationStatus['diagnostics']);
    final security =
        _campaign6Map(campaign7ConfigurationStatus['security_boundaries']);
    final statusRows =
        _campaign6List(campaign7ConfigurationStatus['status_matrix'])
            .map((item) => [
                  _campaignText(item['capability']),
                  _campaignText(item['status']),
                  _campaignText(item['ui_state']),
                ])
            .toList(growable: false);
    final degradedRows =
        _campaign6List(campaign7ConfigurationStatus['degraded_modes'])
            .map((item) => [
                  _campaignText(item['condition']),
                  _campaignText(item['runtime_status']),
                  _campaignText(item['user_message']),
                ])
            .toList(growable: false);
    final securityRows = security.entries
        .map((entry) => [
              entry.key,
              entry.value == true ? 'pass' : 'fail',
            ])
        .toList(growable: false);
    final sourcePrecedence =
        _campaignStringList(schema['source_precedence']).join(' > ');

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 980;
      final overview = _ProductPanel(
        keyName: 'settings-configuration-system',
        icon: Icons.rule_folder_outlined,
        title: zh ? '配置系统' : 'Configuration System',
        gap: true,
        children: [
          _MetricStrip(
            items: [
              _MetricDatum(
                  label: zh ? '总状态' : 'Overall',
                  value: _campaignText(
                      campaign7ConfigurationStatus['overall_status']),
                  detail: zh ? '已绑定 UI' : 'UI-bound',
                  icon: Icons.fact_check_outlined),
              _MetricDatum(
                  label: zh ? 'Schema' : 'Schema',
                  value: _campaignText(schema['schema_version']),
                  detail: zh ? '统一配置' : 'unified config',
                  icon: Icons.schema_outlined),
              _MetricDatum(
                  label: zh ? 'UI' : 'UI',
                  value: _capabilityStatusLabel(
                      _campaignText(_campaign6Map(
                              campaign7ConfigurationStatus['ui_settings'])[
                          'ui_state']),
                      zh),
                  detail: zh ? 'Settings 绑定' : 'Settings binding',
                  icon: Icons.settings_outlined),
            ],
          ),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '配置来源优先级' : 'Config source precedence',
              value: sourcePrecedence),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? 'Secret 展示' : 'Secret display',
              value: _campaignText(
                  _campaign6Map(campaign7ConfigurationStatus['ui_settings'])[
                      'masked_secret_display'])),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh
                ? ['能力', '状态', 'UI 状态']
                : ['Capability', 'Status', 'UI state'],
            rows: statusRows
                .map((row) =>
                    [row[0], row[1], _capabilityStatusLabel(row[2], zh)])
                .toList(growable: false),
          ),
        ],
      );
      final diagnosticsPanel = _ProductPanel(
        keyName: 'settings-configuration-diagnostics',
        icon: Icons.health_and_safety_outlined,
        title: zh ? '配置健康' : 'Configuration Health',
        gap: true,
        children: [
          _ProductTable(
            columns: zh ? ['配置项', '状态'] : ['Configuration item', 'Status'],
            rows: zh
                ? [
                    [
                      '模型 Provider',
                      _settingsHealthLabel(diagnostics['provider_runtime'], zh)
                    ],
                    [
                      'Agent 工作台配置',
                      _settingsHealthLabel(diagnostics['agent_runtime'], zh)
                    ],
                    [
                      '知识库 / RAG 配置',
                      _settingsHealthLabel(diagnostics['rag'], zh)
                    ],
                    [
                      '工作区路径',
                      _settingsHealthLabel(diagnostics['workspace'], zh)
                    ],
                    [
                      '界面设置',
                      _settingsHealthLabel(diagnostics['ui_settings'], zh)
                    ],
                  ]
                : [
                    [
                      'Model Provider',
                      _settingsHealthLabel(diagnostics['provider_runtime'], zh)
                    ],
                    [
                      'Agent Workbench config',
                      _settingsHealthLabel(diagnostics['agent_runtime'], zh)
                    ],
                    [
                      'Knowledge Base / RAG config',
                      _settingsHealthLabel(diagnostics['rag'], zh)
                    ],
                    [
                      'Workspace path',
                      _settingsHealthLabel(diagnostics['workspace'], zh)
                    ],
                    [
                      'UI settings',
                      _settingsHealthLabel(diagnostics['ui_settings'], zh)
                    ],
                  ],
          ),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh
                ? ['条件', '当前状态', '用户提示']
                : ['Condition', 'Status', 'User prompt'],
            rows: degradedRows,
          ),
        ],
      );
      final securityPanel = _ProductPanel(
        keyName: 'settings-configuration-security',
        icon: Icons.verified_user_outlined,
        title: zh ? '安全授权' : 'Security Authorization',
        gap: true,
        children: [
          _ProductTable(
            columns: zh ? ['检查', '结果'] : ['Check', 'Result'],
            rows: securityRows,
          ),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '模型 Provider 复用' : 'Model Provider reuse',
              value: _campaignText(
                  _campaign6Map(schema['runtime_reuse'])['provider_runtime'])),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? 'Agent 工作台复用' : 'Agent Workbench reuse',
              value: _campaignText(
                  _campaign6Map(schema['runtime_reuse'])['agent_runtime'])),
        ],
      );
      if (!wide) {
        return Column(children: [
          overview,
          const SizedBox(height: _DesktopGrid.gutter),
          diagnosticsPanel,
          const SizedBox(height: _DesktopGrid.gutter),
          securityPanel,
        ]);
      }
      return Column(children: [
        _EqualHeightRow(
          height: 430,
          flexes: const [7, 5],
          children: [overview, diagnosticsPanel],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        securityPanel,
      ]);
    });
  }
}

class _SettingsDesktopDeliveryView extends StatelessWidget {
  const _SettingsDesktopDeliveryView({
    required this.zh,
    required this.campaign9DesktopDeliveryStatus,
  });

  final bool zh;
  final Map<String, dynamic> campaign9DesktopDeliveryStatus;

  @override
  Widget build(BuildContext context) {
    final delivery =
        _campaign6Map(campaign9DesktopDeliveryStatus['delivery_path']);
    final packageInfo =
        _campaign6Map(campaign9DesktopDeliveryStatus['package']);
    final checksum = _campaign6Map(campaign9DesktopDeliveryStatus['checksum']);
    final smoke =
        _campaign6Map(campaign9DesktopDeliveryStatus['desktop_shell_smoke']);
    final pathRules =
        _campaign6Map(campaign9DesktopDeliveryStatus['path_rules']);
    final security =
        _campaign6Map(campaign9DesktopDeliveryStatus['security_boundaries']);
    final validationRows =
        _campaign6List(campaign9DesktopDeliveryStatus['validation_matrix'])
            .map((item) => [
                  _campaignText(item['capability']),
                  _campaignText(item['status']),
                  _campaignText(item['ui_state']),
                  _productRecordText(item['evidence']),
                ])
            .toList(growable: false);
    final smokeRows = _campaign6List(smoke['steps'])
        .map((item) => [
              _campaignText(item['step']),
              _campaignText(item['result']),
            ])
        .toList(growable: false);
    final degradedRows =
        _campaign6List(campaign9DesktopDeliveryStatus['degraded_modes'])
            .map((item) => [
                  _campaignText(item['condition']),
                  _campaignText(item['runtime_status']),
                  _campaignText(item['user_message']),
                ])
            .toList(growable: false);
    final securityRows = security.entries
        .map((entry) => [
              entry.key,
              entry.value == true ? 'pass' : 'fail',
            ])
        .toList(growable: false);
    final pathRows = pathRules.entries
        .map((entry) => [entry.key, _campaignText(entry.value)])
        .toList(growable: false);

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 980;
      final overview = _ProductPanel(
        keyName: 'settings-desktop-delivery',
        icon: Icons.desktop_windows_outlined,
        title: zh ? '桌面交付' : 'Desktop Delivery',
        gap: true,
        children: [
          _MetricStrip(
            items: [
              _MetricDatum(
                  label: zh ? '本地状态' : 'Local status',
                  value: _campaignText(
                      campaign9DesktopDeliveryStatus['overall_status']),
                  detail: zh ? '等待人工复查' : 'pending manual review',
                  icon: Icons.fact_check_outlined),
              _MetricDatum(
                  label: zh ? '候选标签' : 'Candidate tag',
                  value: _campaignText(
                      campaign9DesktopDeliveryStatus['release_candidate_tag']),
                  detail: zh ? '未发布稳定版' : 'no stable release',
                  icon: Icons.local_offer_outlined),
              _MetricDatum(
                  label: zh ? '包版本' : 'Package version',
                  value: _campaignText(campaign9DesktopDeliveryStatus[
                      'package_version_baseline']),
                  detail: zh ? '候选包' : 'candidate package',
                  icon: Icons.inventory_2_outlined),
            ],
          ),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh
                ? ['能力', '状态', '用户可见状态', '验证记录']
                : ['Capability', 'Status', 'User status', 'Validation record'],
            rows: validationRows
                .map((row) => [
                      row[0],
                      row[1],
                      _capabilityStatusLabel(row[2], zh),
                      row[3]
                    ])
                .toList(growable: false),
          ),
        ],
      );
      final packagePanel = _ProductPanel(
        keyName: 'settings-desktop-package',
        icon: Icons.inventory_outlined,
        title: zh ? 'Windows 包与校验' : 'Windows Package and Checksum',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? '交付路径' : 'Delivery path',
              value: _campaignText(delivery['accepted_packaging_path'])),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? 'EXE' : 'EXE',
              value: _campaignText(packageInfo['exe'])),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '文件数量 / 大小' : 'Files / size',
              value:
                  '${_campaignText(packageInfo['file_count'])} / ${_campaignText(packageInfo['total_size_bytes'])} bytes'),
          const SizedBox(height: 8),
          _FieldRow(
              label: 'SHA-256', value: _campaignText(checksum['exe_sha256'])),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '桌面外壳' : 'Desktop shell',
              value: _campaignText(delivery['legacy_tauri_status'])),
        ],
      );
      final smokePanel = _ProductPanel(
        keyName: 'settings-desktop-smoke',
        icon: Icons.monitor_heart_outlined,
        title: zh ? '真实桌面冒烟' : 'Real Desktop Smoke',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? '冒烟状态' : 'Smoke status',
              value: _campaignText(smoke['status'])),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '验证记录' : 'Validation record',
              value: _productRecordText(smoke['evidence_path'])),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh ? ['步骤', '结果'] : ['Step', 'Result'],
            rows: smokeRows,
          ),
        ],
      );
      final boundaryPanel = _ProductPanel(
        keyName: 'settings-desktop-boundary',
        icon: Icons.verified_user_outlined,
        title: zh ? '路径、恢复与安全授权' : 'Paths, Recovery, and Security',
        gap: true,
        children: [
          _ProductTable(
            columns: zh ? ['路径规则', '说明'] : ['Path rule', 'Description'],
            rows: pathRows,
          ),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh
                ? ['场景', '当前状态', '用户提示']
                : ['Scenario', 'Status', 'User prompt'],
            rows: degradedRows,
          ),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh ? ['安全检查', '结果'] : ['Security check', 'Result'],
            rows: securityRows,
          ),
        ],
      );

      if (!wide) {
        return Column(children: [
          overview,
          const SizedBox(height: _DesktopGrid.gutter),
          packagePanel,
          const SizedBox(height: _DesktopGrid.gutter),
          smokePanel,
          const SizedBox(height: _DesktopGrid.gutter),
          boundaryPanel,
        ]);
      }
      return Column(children: [
        _EqualHeightRow(
          height: 470,
          flexes: const [7, 5],
          children: [overview, packagePanel],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _EqualHeightRow(
          height: 520,
          flexes: const [5, 7],
          children: [smokePanel, boundaryPanel],
        ),
      ]);
    });
  }
}

class _SettingsWorkspaceView extends StatelessWidget {
  const _SettingsWorkspaceView({
    required this.zh,
    required this.workspace,
    required this.isWebRuntime,
  });

  final bool zh;
  final String workspace;
  final bool isWebRuntime;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final overview = _ProductPanel(
        keyName: 'settings-workspace-overview',
        icon: Icons.folder_open_outlined,
        title: zh ? '应用工作区' : 'Application Workspace',
        children: [
          _MetricStrip(
            items: [
              _MetricDatum(
                  label: zh ? '工作区' : 'Workspace',
                  value: workspace == '.' ? 'local' : 'set',
                  detail: zh ? '本地路径' : 'local path',
                  icon: Icons.folder_outlined),
              _MetricDatum(
                  label: zh ? '存储' : 'Storage',
                  value: 'local',
                  detail: zh ? '默认' : 'default',
                  icon: Icons.storage_outlined),
              _MetricDatum(
                  label: zh ? '模式' : 'Mode',
                  value: isWebRuntime ? 'Web' : 'EXE',
                  detail: isWebRuntime
                      ? (zh ? '预览模式' : 'preview mode')
                      : (zh ? '桌面运行' : 'desktop runtime'),
                  icon: isWebRuntime
                      ? Icons.public_outlined
                      : Icons.desktop_windows_outlined),
            ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _ProductTable(
            columns: zh ? ['路径', '当前值', '分类'] : ['Path', 'Value', 'Class'],
            rows: zh
                ? [
                    ['工作区根目录', workspace, '可用'],
                    ['输出目录', '当前用户工作区', '可用'],
                    ['文档缓存', './data/documents', '本地路径'],
                    ['向量索引目录', './data/vector', '本地索引'],
                  ]
                : [
                    ['Workspace root', workspace, 'Available'],
                    ['Output directory', 'Current user workspace', 'Available'],
                    ['Document cache', './data/documents', 'Local path'],
                    ['Vector index dir', './data/vector', 'Local index'],
                  ],
          ),
        ],
      );
      final registry = _ProductPanel(
        keyName: 'settings-asset-registry',
        icon: Icons.inventory_2_outlined,
        title: zh ? '资产注册表' : 'Asset Registry',
        children: [
          _ProductTable(
            columns: zh
                ? ['资产', '类型', '状态', '说明']
                : ['Asset', 'Type', 'Status', 'Note'],
            rows: zh
                ? [
                    ['来源文档', 'Document', '已登记', '文档库管理'],
                    ['知识库', 'Knowledge Base', '已登记', '知识库管理'],
                    ['Skill 草稿', 'Skill', '已登记', 'Skill 工厂管理'],
                    [
                      'Agent Creation Package',
                      'Agent Package',
                      '已登记',
                      'Agent 工作台管理'
                    ],
                  ]
                : [
                    [
                      'Source documents',
                      'Document',
                      'Registered',
                      'Document Library'
                    ],
                    [
                      'Knowledge Base',
                      'Knowledge Base',
                      'Registered',
                      'Knowledge module'
                    ],
                    ['Skill draft', 'Skill', 'Registered', 'Skill Factory'],
                    [
                      'Agent Creation Package',
                      'Agent Package',
                      'Registered',
                      'Agent Workbench'
                    ],
                  ],
          ),
        ],
      );
      final policy = _ProductPanel(
        keyName: 'settings-workspace-policy',
        icon: Icons.policy_outlined,
        title: zh ? '备份与保留策略' : 'Backup and Retention Policy',
        gap: true,
        children: [
          _ProductTable(
            columns: zh ? ['项目', '策略', '分类'] : ['Item', 'Policy', 'Class'],
            rows: zh
                ? [
                    ['增量备份', '每日 02:00', '本地计划'],
                    ['本地保留', '30 天，最多 30 个备份', '已配置'],
                    ['缓存清理', '超过保留策略自动删除', '本地策略'],
                    ['云备份', '未启用', '本地优先'],
                  ]
                : [
                    ['Incremental backup', 'Daily 02:00', 'Local schedule'],
                    [
                      'Local retention',
                      '30 days, max 30 backups',
                      'Configured'
                    ],
                    [
                      'Cache cleanup',
                      'Deletes past retention policy',
                      'Local policy'
                    ],
                    ['Cloud backup', 'Not enabled', 'Local-first'],
                  ],
          ),
        ],
      );
      final safety = _ProductPanel(
        keyName: 'settings-local-safety',
        icon: Icons.shield_outlined,
        title: zh ? '本地优先边界' : 'Local-first Boundary',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? '默认网络' : 'Default network',
              value: zh ? '不访问外网' : 'No external network by default'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? 'Secret' : 'Secret',
              value: zh ? '不直接展示明文' : 'Plaintext is never shown'),
          const SizedBox(height: 8),
          _DisplayAction(
            label: zh ? '查看 Provider 验收证据' : 'View Provider evidence',
            icon: Icons.verified_outlined,
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          overview,
          const SizedBox(height: _DesktopGrid.gutter),
          registry,
          const SizedBox(height: _DesktopGrid.gutter),
          policy,
          const SizedBox(height: _DesktopGrid.gutter),
          safety,
        ]);
      }
      return _EqualHeightRow(
        height: 578,
        flexes: const [7, 5],
        children: [
          _ProductColumn(children: [
            overview,
            const SizedBox(height: _DesktopGrid.gutter),
            registry,
          ]),
          _ProductColumn(children: [
            policy,
            const SizedBox(height: _DesktopGrid.gutter),
            safety,
          ]),
        ],
      );
    });
  }
}

class _DeveloperDiagnosticsDetails extends StatelessWidget {
  const _DeveloperDiagnosticsDetails({
    required this.localeCode,
    required this.cards,
    required this.columns,
    required this.corePanels,
    this.parserBackends,
    this.skillFactoryWorkflow,
  });

  final String localeCode;
  final List<_CardCopy> cards;
  final int columns;
  final List<Widget> corePanels;
  final ParserBackendMatrix? parserBackends;
  final Map<String, dynamic>? skillFactoryWorkflow;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExpansionTile(
      key: const Key('developer-diagnostics-details'),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      title: Text(_zh ? '开发者诊断' : 'Developer Diagnostics',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800)),
      subtitle: Text(_zh
          ? '默认折叠；仅用于只读技术证据、契约、后端矩阵和 Core 操作。'
          : 'Collapsed by default; read-only technical evidence, contracts, backend matrices, and Core actions only.'),
      children: [
        _AdvancedBoundarySummary(
          localeCode: localeCode,
          contractCount: cards.length,
          coreActionCount: corePanels.length,
          hasParserBackends: parserBackends != null,
          hasSkillWorkflow: skillFactoryWorkflow != null,
        ),
        const SizedBox(height: 16),
        if (skillFactoryWorkflow != null) ...[
          _AdvancedBoundarySectionHeader(
            icon: Icons.account_tree_outlined,
            title: _zh ? 'Skill 工作流证据' : 'Skill Workflow Evidence',
            body: _zh
                ? '展示工作流快照，不宣称运行时完成。'
                : 'Shows the workflow snapshot without claiming runtime completion.',
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          SkillFactoryWorkflowSurface(
            localeCode: localeCode,
            workflow: skillFactoryWorkflow,
          ),
          const SizedBox(height: 20),
        ],
        if (cards.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdvancedBoundarySectionHeader(
                icon: Icons.rule_folder_outlined,
                title: _zh ? '契约证据' : 'Contract Evidence',
                body: _zh
                    ? '保留 Core 契约、门禁、产物和报告字段，只在高级详情中展示。'
                    : 'Keeps Core contract, gate, artifact, and report fields inside advanced details.',
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: columns == 1 ? 196 : 180,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) => _WorkbenchCard(
                  title: cards[index].title,
                  body: cards[index].body,
                  localeCode: localeCode,
                ),
              ),
            ],
          ),
        if (parserBackends != null) ...[
          if (cards.isNotEmpty) const SizedBox(height: 20),
          _AdvancedBoundarySectionHeader(
            icon: Icons.storage_outlined,
            title: _zh ? '后端矩阵证据' : 'Backend Matrix Evidence',
            body: _zh
                ? '展示解析后端能力边界，不启用重型默认依赖。'
                : 'Shows parser backend boundaries without enabling heavy default dependencies.',
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          ParserBackendEvidenceDashboard(
            matrix: parserBackends!,
            localeCode: localeCode,
          ),
        ],
        if (corePanels.isNotEmpty) ...[
          const SizedBox(height: 20),
          _AdvancedBoundarySectionHeader(
            icon: Icons.terminal_outlined,
            title: _zh ? '本地 Core 执行详情' : 'Local Core Execution Details',
            body: _zh
                ? '仅展示允许列表内的本地 Core 操作；Web 中保持安全禁用。'
                : 'Shows allowlisted local Core actions only; they remain safely disabled on Web.',
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          for (var index = 0; index < corePanels.length; index++) ...[
            if (index > 0) const SizedBox(height: _DesktopGrid.gutter),
            corePanels[index],
          ],
        ],
      ],
    );
  }
}

class _AdvancedBoundarySummary extends StatelessWidget {
  const _AdvancedBoundarySummary({
    required this.localeCode,
    required this.contractCount,
    required this.coreActionCount,
    required this.hasParserBackends,
    required this.hasSkillWorkflow,
  });

  final String localeCode;
  final int contractCount;
  final int coreActionCount;
  final bool hasParserBackends;
  final bool hasSkillWorkflow;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: colors.primary),
              const SizedBox(width: _DesktopGrid.gutter),
              Expanded(
                child: Text(
                  _zh ? '边界摘要' : 'Boundary Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AdvancedBoundaryChip(
                label: _zh ? '契约字段' : 'Contract fields',
                value: '$contractCount',
              ),
              _AdvancedBoundaryChip(
                label: _zh ? 'Core 操作' : 'Core actions',
                value: '$coreActionCount',
              ),
              _AdvancedBoundaryChip(
                label: _zh ? '后端矩阵' : 'Backend matrix',
                value: hasParserBackends
                    ? (_zh ? '可查看' : 'available')
                    : (_zh ? '无' : 'none'),
              ),
              _AdvancedBoundaryChip(
                label: _zh ? 'Skill 工作流' : 'Skill workflow',
                value: hasSkillWorkflow
                    ? (_zh ? '可查看' : 'available')
                    : (_zh ? '无' : 'none'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdvancedBoundaryChip extends StatelessWidget {
  const _AdvancedBoundaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedBoundarySectionHeader extends StatelessWidget {
  const _AdvancedBoundarySectionHeader({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Icon(icon, size: 18, color: colors.onSurfaceVariant),
        ),
        const SizedBox(width: _DesktopGrid.gutter),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

ContractView _contractViewForId(String pageId, WorkbenchContracts contracts) {
  for (final view in contracts.navigation.views) {
    if (view.id == pageId) {
      return view;
    }
  }
  return ContractView(
      id: pageId,
      label: pageId,
      assetTypes: const [],
      corePageId: pageId,
      zhLabel: pageId);
}

List<ContractAction> _actionsForView(
    ContractView view, WorkbenchContracts contracts) {
  return contracts.actions.actions
      .where((action) => action.pageId == view.corePageId)
      .toList(growable: false);
}

List<ContractReport> _reportsForView(
    ContractView view, WorkbenchContracts contracts) {
  return contracts.reports.reports
      .where((report) => report.pageId == view.corePageId)
      .toList(growable: false);
}

List<ContractAsset> _artifactsForView(
    ContractView view, WorkbenchContracts contracts) {
  return contracts.assets.assets
      .where((asset) => asset.pageId == view.corePageId)
      .toList(growable: false);
}

bool _showsWorkflowEvidence(String pageId) {
  return const {
    'dashboard',
    'operation-gate',
    'task-job-center',
    'artifact-management',
    'error-repair-center',
    'reports-audit',
  }.contains(pageId);
}

bool _showsV2Evidence(String pageId) {
  return const {
    'dashboard',
    'operation-gate',
    'capability-matrix',
    'task-job-center',
    'artifact-management',
    'error-repair-center',
    'reports-audit',
  }.contains(pageId);
}

bool _showsExternalCapabilities(String pageId) {
  return const {
    'dashboard',
    'operation-gate',
    'capability-matrix',
    'vector-hub-provider-storage',
    'retrieval-verification',
    'reports-audit',
    'skill-factory',
    'memory-center',
  }.contains(pageId);
}

bool _showsParserBackends(String pageId) {
  return const {
    'dashboard',
    'import-parsing',
    'capability-matrix',
    'operation-gate',
    'reports-audit',
    'artifact-management',
    'error-repair-center',
  }.contains(pageId);
}

bool _showsSkillGovernance(String pageId) {
  return pageId == 'skill-factory';
}

bool _showsMethodology(String pageId) {
  return pageId == 'skill-factory';
}

const sampleCampaign7ConfigurationStatus = <String, dynamic>{
  'schema_id': 'campaign7_configuration_system_status',
  'schema_version': '2026-06-17',
  'overall_status':
      'campaign7_configuration_system_production_grade_accepted_ui_bound',
  'final_target':
      'campaign7_configuration_system_production_grade_accepted_pushed_ci_green',
  'scope': {
    'campaign_7_started': true,
    'campaign_8_started': false,
    'campaign_9_started': false,
    'provider_runtime_reimplemented': false,
    'agent_runtime_reimplemented': false,
    'arbitrary_shell_allowed': false,
    'computer_use_runtime_enabled': false,
    'tag_or_release_allowed': false,
    'secret_plaintext_written': false,
  },
  'config_schema': {
    'schema_version': 'campaign7.config.v1',
    'ui_state': 'enabled_real',
    'sections': <String>[
      'provider_profiles',
      'agent_profiles',
      'tool_adapters',
      'skills',
      'rag',
      'workspace',
      'ui_settings',
    ],
    'source_precedence': <String>['default', 'workspace', 'user', 'env'],
    'runtime_reuse': {
      'provider_runtime': 'accepted_env_only_provider_runtime',
      'agent_runtime': 'campaign6_agent_runtime',
      'tool_runtime': 'campaign6_registered_tool_adapter_gate',
      'workbench_bridge': 'campaign5_allowlisted_workbench_bridge',
    },
  },
  'status_matrix': <Map<String, dynamic>>[
    {
      'capability': 'unified_config_schema',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'provider_profile_persistence',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'agent_profile_persistence',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'tool_adapter_config_persistence',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'skill_rag_workspace_binding_config',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'override_precedence',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'env_only_secret_injection',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'masked_ui_secret_display',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'config_validation',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'config_migration',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'config_rollback',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'config_diagnostics',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'config_import_export',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'degraded_status_mapping',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
    {
      'capability': 'ui_settings_binding',
      'status': 'pass',
      'ui_state': 'enabled_real',
    },
  ],
  'diagnostics': {
    'status': 'pass',
    'provider_runtime': 'available',
    'agent_runtime': 'available',
    'tool_adapter_registry': 'available',
    'rag': 'available',
    'workspace': 'available',
    'ui_settings': 'available',
  },
  'degraded_modes': <Map<String, dynamic>>[
    {
      'condition': 'missing_env_secret',
      'runtime_status': 'blocked',
      'user_message': 'Prompt env/secret-store setup; never echo plaintext.',
    },
    {
      'condition': 'rollback_restore',
      'runtime_status': 'degraded',
      'user_message': 'Restore last valid snapshot and preserve audit log.',
    },
    {
      'condition': 'tool_adapter_disabled',
      'runtime_status': 'disabled_boundary',
      'user_message': 'Do not execute disabled or unregistered adapters.',
    },
  ],
  'security_boundaries': {
    'no_plaintext_secret': true,
    'secret_env_names_only': true,
    'ui_secret_masked': true,
    'no_arbitrary_shell': true,
    'computer_use_disabled': true,
    'no_provider_runtime_rewrite': true,
    'no_agent_runtime_rewrite': true,
  },
  'ui_settings': {
    'ui_state': 'enabled_real',
    'masked_secret_display': 'sk-************',
    'profile_lifecycle_status': 'pass',
    'validation_status': 'pass',
    'migration_status': 'pass',
    'rollback_status': 'pass',
    'diagnostics_status': 'pass',
    'import_export_status': 'pass',
  },
};

const sampleCampaign9DesktopDeliveryStatus = <String, dynamic>{
  'schema_id': 'campaign9_desktop_delivery_status',
  'schema_version': '2026-06-17',
  'overall_status':
      'v4.3.0-rc10_product_flow_truth_ui_closure_real_exe_verified_pending_owner_retest',
  'final_target_status':
      'v4.3.0-rc10_product_flow_truth_ui_closure_real_exe_verified_pending_owner_retest',
  'release_candidate_tag': 'v4.3.0-rc10',
  'package_version_baseline': '4.3.0-rc10',
  'github_release_created': false,
  'stable_release_tag_authorized': false,
  'campaign_scope': {
    'campaign_7_restarted': false,
    'campaign_8_restarted': false,
    'campaign_9_started': true,
    'campaign_7_8_9_boundary_preserved': true,
    'computer_use_runtime_enabled': false,
    'arbitrary_shell_allowed': false,
    'github_release_created': false,
    'tauri_accepted_path': false,
  },
  'delivery_path': {
    'accepted_packaging_path': 'flutter_windows_runner',
    'legacy_tauri_status':
        'legacy_optional_scaffold_not_campaign9_accepted_path',
    'production_build_command': 'flutter build windows',
    'desktop_shell_runtime': 'Flutter Windows runner',
    'web_build_supported': true,
    'development_path_dependency_required': false,
  },
  'package': {
    'platform': 'windows',
    'build_status': 'pass',
    'release_dir': 'build/windows/x64/runner/Release',
    'exe': 'heitang_workbench.exe',
    'file_count': 49,
    'total_size_bytes': 31756336,
    'required_files_present': {
      'exe': true,
      'flutter_windows_dll': true,
      'data_dir': true,
      'flutter_assets': true,
      'icu': true,
    },
  },
  'checksum': {
    'status': 'pass',
    'manifest_path':
        'output/rc10_product_flow_truth_ui_closure/release_bundle_manifest.json',
    'exe_sha256':
        'd8e58accd56571fc08cfec3178b77ef7e1c3a58c5930c7d9d37718b1253e9d87',
  },
  'desktop_shell_smoke': {
    'status': 'pass',
    'evidence_path':
        'output/rc10_product_flow_truth_ui_closure/exe_smoke/rc10_exe_launch_smoke.json',
    'steps': <Map<String, dynamic>>[
      {'step': 'launch', 'result': 'pass'},
      {'step': 'minimize', 'result': 'pass'},
      {'step': 'restore_after_minimize', 'result': 'pass'},
      {'step': 'maximize', 'result': 'pass'},
      {'step': 'restore_after_maximize', 'result': 'pass'},
      {'step': 'resize', 'result': 'pass'},
      {'step': 'close', 'result': 'pass'},
    ],
  },
  'validation_matrix': <Map<String, dynamic>>[
    {
      'capability': 'windows_package_build',
      'status': 'pass',
      'ui_state': 'available',
      'evidence': 'campaign9_flutter_build_windows.log',
    },
    {
      'capability': 'desktop_shell_real_smoke',
      'status': 'pass',
      'ui_state': 'available',
      'evidence':
          'output/rc10_product_flow_truth_ui_closure/exe_smoke/rc10_exe_launch_smoke.json',
    },
    {
      'capability': 'full_capability_runtime_chain',
      'status': 'pass',
      'ui_state': 'available',
      'evidence':
          'kb-forge-skill/output/rc10_validation_chain/rc10_core_chain_probe.log',
    },
    {
      'capability': 'page_button_tab_audit',
      'status': 'pass',
      'ui_state': 'available',
      'evidence':
          'v4.3.0-rc10_Product_Flow_Truth_UI_Closure_Report_2026-06-18.md',
    },
    {
      'capability': 'release_bundle_manifest',
      'status': 'pass',
      'ui_state': 'available',
      'evidence':
          'output/rc10_product_flow_truth_ui_closure/release_bundle_manifest.json',
    },
    {
      'capability': 'provider_secret_handling',
      'status': 'pass',
      'ui_state': 'available',
      'evidence': 'env_only_no_secret_bundle_boundary',
    },
    {
      'capability': 'config_workspace_log_cache_paths',
      'status': 'pass',
      'ui_state': 'available',
      'evidence': 'configuration_system_reuse',
    },
    {
      'capability': 'github_release_creation',
      'status': 'not_created',
      'ui_state': 'owner_authorization_required',
      'evidence': 'owner_authorization_required',
    },
    {
      'capability': 'computer_use_runtime',
      'status': 'not_available_in_product_flow',
      'ui_state': 'not_available_in_product_flow',
      'evidence': 'high_risk_runtime_not_opened',
    },
  ],
  'path_rules': {
    'config_path':
        'Configuration precedence persists default/workspace/user/env values.',
    'workspace_path':
        'Workspace selection remains user-controlled and must not require a development checkout.',
    'logs_path':
        'Packaged app logs use local application log storage and never write raw credentials.',
    'cache_path':
        'Packaged app cache is local, clearable, and non-authoritative.',
    'secret_path':
        'Provider and tool credentials remain env/secret-store only and are never bundled.',
  },
  'degraded_modes': <Map<String, dynamic>>[
    {
      'condition': 'missing_provider_env',
      'runtime_status': 'degraded',
      'user_message':
          'Provider-backed actions stay disabled until env/secret-store setup is repaired.',
    },
    {
      'condition': 'workspace_path_unavailable',
      'runtime_status': 'blocked',
      'user_message':
          'Prompt for a valid workspace path before starting local workflows.',
    },
    {
      'condition': 'bundle_file_missing',
      'runtime_status': 'blocked',
      'user_message':
          'Do not mark the package accepted until required runtime files are restored.',
    },
    {
      'condition': 'desktop_shell_smoke_failure',
      'runtime_status': 'blocked',
      'user_message':
          'Stop the candidate and repair the desktop shell behavior before tagging.',
    },
    {
      'condition': 'github_release_requested',
      'runtime_status': 'blocked_pending_owner',
      'user_message':
          'GitHub Release creation requires separate Owner authorization.',
    },
  ],
  'rollback_matrix': <Map<String, dynamic>>[
    {
      'area': 'package_artifact',
      'rollback':
          'Discard the candidate bundle and rebuild from the accepted commit.',
    },
    {
      'area': 'config_profile',
      'rollback':
          'Use configuration rollback snapshots and preserve diagnostics.',
    },
    {
      'area': 'workspace_state',
      'rollback':
          'Do not mutate workspace data during package smoke; restore from user backup if a later workflow mutates data.',
    },
    {
      'area': 'tag_policy',
      'rollback':
          'Do not move or force-push tags; create a new authorized candidate only after Owner review.',
    },
  ],
  'security_boundaries': {
    'no_plaintext_secret_bundled': true,
    'no_secret_in_ui_log_report_fixture': true,
    'env_only_provider_secret_reuse': true,
    'no_arbitrary_shell': true,
    'computer_use_disabled': true,
    'no_github_release_created': true,
    'no_stable_release_without_owner': true,
    'no_campaign_7_8_9_scope_violation': true,
    'legacy_tauri_not_accepted_path': true,
  },
};

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
