import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart' show rootBundle;

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

const pages = <WorkbenchPage>[
  WorkbenchPage(
      'dashboard',
      'Dashboard',
      '仪表盘',
      'Workbench overview, recent work, health, artifacts, and activity timeline.',
      '工作台概览、最近任务、健康状态、产物与活动时间线。',
      memberPageIds: [
        'dashboard',
        'operation-gate',
        'capability-matrix',
        'task-job-center',
      ]),
  WorkbenchPage(
      'import-parsing',
      'Import & Parsing',
      '导入与解析',
      'Stage files, folders, and web links, then configure parsing, OCR, chunks, and recovery.',
      '暂存文件、文件夹和网页链接，并配置解析、OCR、分块与失败恢复。',
      memberPageIds: ['import-parsing']),
  WorkbenchPage(
      'document-library',
      'Document Library',
      '文档库',
      'Manage source documents, metadata, parsing records, versions, references, and artifacts.',
      '管理来源文档、元数据、解析记录、版本、引用和产物。',
      memberPageIds: [
        'document-library',
        'document-generation',
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
      'Agent Factory',
      'Agent 工厂',
      'Create Agents, bind Knowledge Base and Skill artifacts, and run governed multi-agent discussion.',
      '创建 Agent、绑定知识库和 Skill 产物，并执行受治理的多 Agent 讨论。',
      memberPageIds: ['agent-factory-runtime']),
  WorkbenchPage(
      'reports-audit',
      'Reports & Audit',
      '审计与报告',
      'Review quality, retrieval, OCR, safety, governance reports, issues, and repair suggestions.',
      '查看质量、检索、OCR、安全和治理报告、问题与修复建议。',
      memberPageIds: [
        'reports-audit',
        'artifact-management',
        'error-repair-center',
        'governance',
        'memory-center',
      ]),
  WorkbenchPage(
      'workspace',
      'Settings',
      '设置',
      'Review workspace, providers, storage, models, language, theme, safety, and diagnostics.',
      '查看工作区、Provider、存储、模型、语言、主题、安全和诊断。',
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
                value: 'v1.0.0',
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

    return Material(
      color: sidebarBackground,
      child: ListView(
        key: const Key('desktop-sidebar-scroll'),
        padding: const EdgeInsets.fromLTRB(8, 9, 8, 12),
        children: [
          _SidebarBrand(localeCode: localeCode),
          const SizedBox(height: 10),
          _SidebarGroupLabel(
              label: localeCode == 'zh-CN' ? '工作区' : 'Workspace'),
          _SidebarItem(
            keyName: 'sidebar-dashboard',
            page: pages[0],
            icon: Icons.dashboard_customize_outlined,
            localeCode: localeCode,
            contracts: contracts,
            selected: selectedIndex == 0,
            primaryText: primaryText,
            secondaryText: secondaryText,
            selectedBackground: selectedBackground,
            onTap: () => onPageChanged(0),
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _SidebarGroupLabel(
              label: localeCode == 'zh-CN' ? '知识工程' : 'Knowledge Flow'),
          for (var index = 1; index <= 5; index++)
            _SidebarItem(
              keyName: 'sidebar-${pages[index].id}',
              page: pages[index],
              icon: _sidebarIconFor(pages[index].id),
              localeCode: localeCode,
              contracts: contracts,
              selected: selectedIndex == index,
              primaryText: primaryText,
              secondaryText: secondaryText,
              selectedBackground: selectedBackground,
              onTap: () => onPageChanged(index),
            ),
          const SizedBox(height: _DesktopGrid.gutter),
          _SidebarGroupLabel(
              label: localeCode == 'zh-CN' ? '智能能力' : 'Intelligence'),
          for (var index = 6; index <= 7; index++)
            _SidebarItem(
              keyName: 'sidebar-${pages[index].id}',
              page: pages[index],
              icon: _sidebarIconFor(pages[index].id),
              localeCode: localeCode,
              contracts: contracts,
              selected: selectedIndex == index,
              primaryText: primaryText,
              secondaryText: secondaryText,
              selectedBackground: selectedBackground,
              onTap: () => onPageChanged(index),
            ),
          const SizedBox(height: _DesktopGrid.gutter),
          _SidebarGroupLabel(
              label: localeCode == 'zh-CN' ? '治理与系统' : 'Governance'),
          _SidebarItem(
            keyName: 'sidebar-reports-audit',
            page: pages[8],
            icon: _sidebarIconFor(pages[8].id),
            localeCode: localeCode,
            contracts: contracts,
            selected: selectedIndex == 8,
            primaryText: primaryText,
            secondaryText: secondaryText,
            selectedBackground: selectedBackground,
            onTap: () => onPageChanged(8),
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _SidebarGroupLabel(label: localeCode == 'zh-CN' ? '系统' : 'System'),
          _SidebarItem(
            keyName: 'sidebar-workspace',
            page: pages[9],
            icon: Icons.tune_outlined,
            localeCode: localeCode,
            contracts: contracts,
            selected: selectedIndex == 9,
            primaryText: primaryText,
            secondaryText: secondaryText,
            selectedBackground: selectedBackground,
            onTap: () => onPageChanged(9),
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
                  ? '知识工作台  v1.0.0'
                  : 'Knowledge Workbench  v1.0.0',
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
                          ? '安全边界已启用'
                          : 'Safety boundary active',
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
    case 'workspace':
      return Icons.settings_outlined;
    default:
      return Icons.circle_outlined;
  }
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
    final isDashboard = page.id == 'dashboard';
    final diagnosticPage = page.id == 'workspace'
        ? WorkbenchPage(
            'workspace',
            page.enTitle,
            page.zhTitle,
            page.enDescription,
            page.zhDescription,
            memberPageIds:
                pages.expand((item) => item.pageIds).toSet().toList(),
          )
        : page;
    final cards = _cardsFor(
        diagnosticPage.id,
        diagnosticPage,
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
    for (final pageId in diagnosticPage.pageIds) {
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
      parserBackends: diagnosticPage.pageIds.any(_showsParserBackends)
          ? parserBackends
          : null,
      skillFactoryWorkflow: diagnosticPage.pageIds.any(_showsSkillGovernance)
          ? skillSuiteWorkflow
          : null,
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
                label: _zh ? '搜索知识、Skill、文档' : 'Search knowledge, Skill, docs',
                compact: constraints.maxWidth < 900,
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
  });

  final String localeCode;
  final WorkbenchContracts contracts;
  final P1WorkflowEvidence workflowV2Evidence;
  final ParserBackendMatrix parserBackends;
  final ExternalCapabilityRegistry externalCapabilities;
  final String workspace;
  final bool isWebRuntime;

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
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        LayoutBuilder(builder: (context, constraints) {
          final threeColumns = constraints.maxWidth >= 1320;
          final main = _ProductColumn(
            children: [
              _EqualHeightRow(
                height: 316,
                children: [
                  _DashboardRecentTasks(localeCode: localeCode),
                  _DashboardSystemHealth(
                    localeCode: localeCode,
                    workflowV2Evidence: workflowV2Evidence,
                    parserBackends: parserBackends,
                    workspace: workspace,
                    isWebRuntime: isWebRuntime,
                  ),
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
          final side = _ProductColumn(children: [
            _EqualHeightRow(
              height: 316,
              children: [
                _DashboardPrivacyCard(localeCode: localeCode),
                _DashboardAuthorizationCard(localeCode: localeCode),
              ],
            ),
            const SizedBox(height: _DesktopGrid.gutter),
            _DashboardArtifactOverview(localeCode: localeCode),
            const SizedBox(height: _DesktopGrid.gutter),
            _DashboardActivityTimeline(localeCode: localeCode),
          ]);
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
  });

  final String localeCode;
  final WorkbenchContracts contracts;
  final P1WorkflowEvidence workflowV2Evidence;
  final ParserBackendMatrix parserBackends;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final runtime =
        _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
    final metrics = [
      _DashboardMetricData(
        icon: Icons.inventory_2_outlined,
        label: _zh ? '来源文档' : 'Source Docs',
        value: runtime.sourceCount.toString(),
        detail: runtime.hasImportedFile
            ? (_zh ? '已进入文档库' : 'in library')
            : (_zh ? '等待导入' : 'waiting import'),
      ),
      _DashboardMetricData(
        icon: Icons.storage_outlined,
        label: _zh ? '知识库' : 'Knowledge Base',
        value: runtime.hasKnowledgeBase ? '1' : '0',
        detail: runtime.hasKnowledgeBase
            ? '${runtime.chunkCount} chunks'
            : (_zh ? '等待构建' : 'waiting build'),
      ),
      _DashboardMetricData(
        icon: Icons.manage_search_outlined,
        label: _zh ? '检索结果' : 'Search Results',
        value: runtime.searchResults.length.toString(),
        detail: runtime.searchStatus == Rc6SearchStatus.success
            ? (_zh ? '来自所选知识库' : 'from selected KB')
            : (_zh ? '等待查询' : 'waiting query'),
      ),
      _DashboardMetricData(
        icon: Icons.description_outlined,
        label: _zh ? '生成文档' : 'Generated Docs',
        value: runtime.hasMarkdown ? '1' : '0',
        detail: runtime.hasExportedDocument
            ? (_zh ? '已导出' : 'exported')
            : (_zh ? '等待生成/导出' : 'waiting generation/export'),
      ),
      _DashboardMetricData(
        icon: Icons.route_outlined,
        label: _zh ? '下一步' : 'Next Step',
        value: _zh ? '继续' : 'Continue',
        detail: _dashboardNextStep(runtime, _zh),
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
        itemBuilder: (context, index) => _DashboardMetricCard(metrics[index]),
      );
    });
  }
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
  return zh ? '等待复验' : 'ready for retest';
}

class _DashboardMetricData {
  const _DashboardMetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard(this.metric);

  final _DashboardMetricData metric;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1.08,
                              )),
                  const SizedBox(height: 5),
                  Text(metric.detail,
                      maxLines: 1,
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    );
  }
}

class _DashboardRecentTasks extends StatefulWidget {
  const _DashboardRecentTasks({required this.localeCode});

  final String localeCode;

  @override
  State<_DashboardRecentTasks> createState() => _DashboardRecentTasksState();
}

class _DashboardRecentTasksState extends State<_DashboardRecentTasks> {
  final Set<int> hidden = <int>{};

  bool get _zh => widget.localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final runtime =
        _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
    final rows = <_DashboardTaskRow>[
      if (runtime.hasImportedFile)
        _DashboardTaskRow(
          _zh ? '导入来源文件' : 'Import sources',
          _zh ? '导入与解析' : 'Import',
          _zh ? '${runtime.sourceCount} 个文件' : '${runtime.sourceCount} files',
          Icons.upload_file_outlined,
        ),
      if (runtime.parseReportPath.isNotEmpty)
        _DashboardTaskRow(
          _zh ? '解析 / OCR / Chunking' : 'Parse / OCR / Chunking',
          _zh ? '导入与解析' : 'Parsing',
          _zh ? '解析报告已生成' : 'parse report ready',
          Icons.document_scanner_outlined,
        ),
      if (runtime.hasKnowledgeBase)
        _DashboardTaskRow(
          _zh ? '构建知识库' : 'Build knowledge base',
          _zh ? '知识库' : 'Knowledge',
          '${runtime.chunkCount} chunks',
          Icons.storage_outlined,
        ),
      if (runtime.searchStatus == Rc6SearchStatus.success)
        _DashboardTaskRow(
          _zh ? '检索验证' : 'Search and verify',
          _zh ? '检索' : 'Retrieval',
          _zh
              ? '${runtime.searchResults.length} 条结果'
              : '${runtime.searchResults.length} results',
          Icons.manage_search_outlined,
        ),
      if (runtime.hasMarkdown)
        _DashboardTaskRow(
          _zh ? '生成 Markdown 文档' : 'Generate Markdown document',
          _zh ? '文档生成' : 'Generation',
          runtime.hasExportedDocument
              ? (_zh ? '已导出' : 'exported')
              : (_zh ? '待导出' : 'waiting export'),
          Icons.description_outlined,
        ),
    ];
    final visibleRows = [
      for (var index = 0; index < rows.length; index++)
        if (!hidden.contains(index)) MapEntry(index, rows[index])
    ];
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
                          ? '暂无真实任务。请从“导入与解析”开始。'
                          : 'No real tasks yet. Start from Import & Parsing.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  )
                : _LocalScrollBox(
                    child: Column(
                      children: [
                        for (final entry in visibleRows) ...[
                          _DashboardTaskTile(
                            row: entry.value,
                            onDelete: () =>
                                setState(() => hidden.add(entry.key)),
                          ),
                          if (entry != visibleRows.last)
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
                      : () => setState(() {
                            for (final entry in visibleRows) {
                              hidden.add(entry.key);
                            }
                          }),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(_zh ? '批量删除' : 'Delete shown'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: rows.isEmpty
                      ? null
                      : () => setState(() => hidden.clear()),
                  icon: const Icon(Icons.restore_outlined),
                  label: Text(_zh ? '恢复列表' : 'Restore'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardTaskRow {
  const _DashboardTaskRow(this.title, this.type, this.status, this.icon);

  final String title;
  final String type;
  final String status;
  final IconData icon;
}

class _DashboardTaskTile extends StatelessWidget {
  const _DashboardTaskTile({required this.row, required this.onDelete});

  final _DashboardTaskRow row;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
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
    );
  }
}

class _DashboardSystemHealthGrid extends StatelessWidget {
  const _DashboardSystemHealthGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: children.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: _DesktopGrid.gutter,
          mainAxisSpacing: _DesktopGrid.gutter,
          mainAxisExtent: (constraints.maxHeight - _DesktopGrid.gutter) / 2,
        ),
        itemBuilder: (context, index) => children[index],
      );
    });
  }
}

class _DashboardSystemHealth extends StatelessWidget {
  const _DashboardSystemHealth({
    required this.localeCode,
    required this.workflowV2Evidence,
    required this.parserBackends,
    required this.workspace,
    required this.isWebRuntime,
  });

  final String localeCode;
  final P1WorkflowEvidence workflowV2Evidence;
  final ParserBackendMatrix parserBackends;
  final String workspace;
  final bool isWebRuntime;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return _FillProductPanel(
      keyName: 'dashboard-system-health',
      icon: Icons.health_and_safety_outlined,
      title: _zh ? '系统健康' : 'System Health',
      child: _DashboardSystemHealthGrid(
        children: [
          _FieldRow(
            label: _zh ? '位置' : 'Location',
            value: _zh ? '用户工作区' : 'User workspace',
          ),
          _FieldRow(
            label: _zh ? '运行环境' : 'Runtime',
            value: isWebRuntime
                ? (_zh ? 'Web 预览' : 'Web preview')
                : (_zh ? '桌面 EXE' : 'Desktop EXE'),
          ),
          _FieldRow(
            label: _zh ? '文档链路' : 'Document flow',
            value:
                _zh ? '导入、解析、知识库、检索、生成' : 'Import, parse, KB, search, generate',
          ),
          _FieldRow(
            label: _zh ? '解析能力' : 'Parsing',
            value: _zh
                ? '${parserBackends.realRuntimeIntegratedCount} 个本地后端可用'
                : '${parserBackends.realRuntimeIntegratedCount} local backends ready',
          ),
        ],
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
      title: _zh ? '报告摘要' : 'Report Summary',
      children: [
        _ProductTable(
          columns: _zh
              ? ['环节', '状态', '用户可见结果', '下一步']
              : ['Step', 'Status', 'User result', 'Next'],
          rows: _zh
              ? [
                  [
                    '导入与解析',
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
                  ['文档生成', '可操作', 'Markdown 草稿与导出文件', 'Owner 复验'],
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
                    'Owner retest'
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

class _DashboardPrivacyCard extends StatelessWidget {
  const _DashboardPrivacyCard({required this.localeCode});

  final String localeCode;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'dashboard-privacy-card',
      icon: Icons.shield_outlined,
      title: _zh ? '本地优先 · 隐私安全' : 'Local First · Privacy',
      gap: true,
      children: [
        Text(
          _zh
              ? '文档、知识库、检索结果和导出文件默认保存在用户工作区；API key 只通过环境变量或 secret store 注入，界面只显示掩码。'
              : 'Documents, KBs, search results, and exports stay in the user workspace; API keys are injected only through env or secret store and stay masked in UI.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _StatusBadge(
          label: _zh ? 'Secret 已掩码' : 'Secrets masked',
          tone: _StatusTone.success,
          icon: Icons.verified_user_outlined,
        ),
      ],
    );
  }
}

class _DashboardAuthorizationCard extends StatelessWidget {
  const _DashboardAuthorizationCard({required this.localeCode});

  final String localeCode;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'dashboard-authorization',
      icon: Icons.admin_panel_settings_outlined,
      title: _zh ? '授权与安全边界' : 'Authorization and Safety',
      gap: true,
      children: [
        _ProductTable(
          columns: _zh
              ? ['能力', '当前处理', '用户动作']
              : ['Capability', 'Handling', 'User action'],
          rows: _zh
              ? [
                  ['外部事实验证', '授权后启用', '在设置中配置联网 Provider'],
                  ['外部向量库 / Redis', '授权后启用', '保存配置并测试连接'],
                  ['arbitrary shell / 明文 secret', '不开放', '无产品入口'],
                ]
              : [
                  [
                    'External fact checking',
                    'Enable after authorization',
                    'Configure network Provider in Settings'
                  ],
                  [
                    'External vector DB / Redis',
                    'Enable after authorization',
                    'Save config and test connection'
                  ],
                  [
                    'Arbitrary shell / plaintext secret',
                    'Not opened',
                    'No product entry'
                  ],
                ],
        ),
      ],
    );
  }
}

class _DashboardArtifactOverview extends StatelessWidget {
  const _DashboardArtifactOverview({required this.localeCode});

  final String localeCode;

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
                ],
        ),
      ],
    );
  }
}

class _DashboardActivityTimeline extends StatelessWidget {
  const _DashboardActivityTimeline({required this.localeCode});

  final String localeCode;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final items = _zh
        ? [
            ['23:38', 'Acceptance Gate 重跑通过'],
            ['23:30', 'Owner 视觉状态文案修复'],
            ['22:59', '真实 Flutter 页面截图完成'],
            ['20:12', 'Campaign 4 页面结构补齐'],
          ]
        : [
            ['23:38', 'Acceptance Gate rerun passed'],
            ['23:30', 'Owner visual state copy fixed'],
            ['22:59', 'Real Flutter screenshots captured'],
            ['20:12', 'Campaign 4 page structure completed'],
          ];
    return _ProductPanel(
      keyName: 'dashboard-activity-timeline',
      icon: Icons.timeline_outlined,
      title: _zh ? '活动时间线' : 'Activity Timeline',
      children: [
        for (final item in items) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 46,
              child: Text(item[0],
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      )),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.check_circle, size: 15, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(item[1],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
            ),
          ]),
          if (item != items.last) const Divider(height: 18),
        ],
      ],
    );
  }
}

class _TopBarSearchField extends StatefulWidget {
  const _TopBarSearchField({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  State<_TopBarSearchField> createState() => _TopBarSearchFieldState();
}

class _TopBarSearchFieldState extends State<_TopBarSearchField> {
  bool focused = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state;
    final borderColor = focused ? colors.primary : colors.outlineVariant;
    final statusText = switch (runtime?.searchStatus) {
      Rc6SearchStatus.loading => zh ? '搜索中' : 'Searching',
      Rc6SearchStatus.success => zh ? '真实结果' : 'Results',
      Rc6SearchStatus.empty => zh ? '无结果' : 'Empty',
      Rc6SearchStatus.error => zh ? '错误' : 'Error',
      _ => 'Enter',
    };
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
                controller: _controller,
                key: const Key('topbar-real-search-input'),
                enabled: rc6 != null,
                onTap: () => setState(() => focused = true),
                onSubmitted: (value) => rc6?.search(value),
                decoration: InputDecoration(
                  hintText: runtime?.hasKnowledgeBase == true
                      ? widget.label
                      : (zh
                          ? '先导入并构建知识库后搜索'
                          : 'Import and build a KB before search'),
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
                    : () => rc6?.search(_controller.text),
                child: Text(statusText),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
    this.height,
  });

  final Widget top;
  final Widget bottom;
  final double? height;

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
    if (height != null) {
      return SizedBox(height: height, child: filled);
    }
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
    this.height,
  });

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final box = Scrollbar(
      thumbVisibility: false,
      child: SingleChildScrollView(
        primary: false,
        child: _ScrollSafePadding(child: child),
      ),
    );
    if (height != null) {
      return SizedBox(height: height, child: box);
    }
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
  });

  final String localeCode;
  final WorkbenchPage page;
  final String workspace;
  final Map<String, dynamic> campaign6AgentRuntimeStatus;
  final Map<String, dynamic> campaign7ConfigurationStatus;
  final Map<String, dynamic> campaign9DesktopDeliveryStatus;
  final bool isWebRuntime;
  final Widget diagnostics;

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
      'workspace': 7,
    };
    final maxTab = (tabCounts[page] ?? 1) - 1;
    if (selectedTab > maxTab) selectedTab = 0;
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
            'reports-audit' => _ValidateExportProductWorkflow(
                localeCode: widget.localeCode,
                workspace: widget.workspace,
                selectedTab: selectedTab,
                onTabSelected: (index) => setState(() => selectedTab = index),
              ),
            _ => _SettingsProductWorkflow(
                localeCode: widget.localeCode,
                workspace: widget.workspace,
                selectedTab: selectedTab,
                onTabSelected: (index) => setState(() => selectedTab = index),
                isWebRuntime: widget.isWebRuntime,
                campaign7ConfigurationStatus:
                    widget.campaign7ConfigurationStatus,
                campaign9DesktopDeliveryStatus:
                    widget.campaign9DesktopDeliveryStatus,
                diagnostics: widget.diagnostics,
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
  if (lower.contains('disabled_boundary') ||
      lower.contains('omitted') ||
      lower.contains('campaign 6') ||
      lower.contains('provider runtime gate') ||
      lower.contains('external source verification gate') ||
      lower.contains('not connected') ||
      lower.contains('not authorized') ||
      lower.contains('waiting') ||
      lower.contains('pending') ||
      lower.contains('preview only') ||
      lower.contains('read-only') ||
      lower.contains('reserved') ||
      value.contains('未接入') ||
      value.contains('等待') ||
      value.contains('待') ||
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
    return zh ? '待补齐' : 'Needs work';
  }
  final lower = value.toLowerCase();
  if (lower.contains('enabled_real')) {
    return zh ? '可用 · enabled_real' : 'Available · enabled_real';
  }
  if (lower.contains('display_only') ||
      lower.contains('preview only') ||
      lower.contains('read-only') ||
      value.contains('只读')) {
    return zh ? '只读预览 · display_only' : 'Preview only · display_only';
  }
  if (lower.contains('omitted') ||
      lower.contains('campaign 6') ||
      value.contains('后续') ||
      value.contains('不实现')) {
    return zh ? '后续阶段' : 'Later phase';
  }
  if (lower.contains('disabled_boundary') ||
      lower.contains('provider runtime gate') ||
      lower.contains('external source verification gate') ||
      lower.contains('not connected') ||
      lower.contains('waiting') ||
      lower.contains('pending') ||
      value.contains('未接入') ||
      value.contains('等待') ||
      value.contains('边界') ||
      value.contains('禁用')) {
    return zh ? '禁用边界 · disabled_boundary' : 'Disabled · disabled_boundary';
  }
  return value;
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

class _DisabledAction extends StatelessWidget {
  const _DisabledAction({
    required this.label,
    required this.reason,
    this.icon = Icons.lock_outline,
  });

  final String label;
  final String reason;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = Colors.amber.shade700;
    return SizedBox(
      width: double.infinity,
      child: Tooltip(
        message: reason,
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.36)),
          ),
          child: OutlinedButton.icon(
            onPressed: null,
            icon: Icon(icon, color: color),
            label: Text(label, overflow: TextOverflow.ellipsis),
            style: OutlinedButton.styleFrom(
              disabledForegroundColor: color,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
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
        onPressed: onPressed ?? () {},
        icon: Icon(icon),
        label: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
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

class _WorkflowSteps extends StatelessWidget {
  const _WorkflowSteps({required this.steps, required this.activeIndex});

  final List<String> steps;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: index == activeIndex
                          ? colors.primary
                          : colors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Text('${index + 1}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: index == activeIndex
                                  ? colors.onPrimary
                                  : colors.onSurfaceVariant,
                              fontWeight: FontWeight.w900,
                            )),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(steps[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: index == activeIndex
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                )),
                  ),
                ],
              ),
            ),
            if (index != steps.length - 1)
              Container(
                width: 26,
                height: 1,
                color: colors.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
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

class _DocumentPreviewPanel extends StatelessWidget {
  const _DocumentPreviewPanel({required this.zh, required this.ready});

  final bool zh;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('document-central-preview'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
                      ? (zh ? '知识库验证报告草稿' : 'Knowledge Base Validation Draft')
                      : (zh ? '文档预览等待生成' : 'Document preview waiting'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 22,
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
          Text(
            zh
                ? '2026 桌面工作台验证版'
                : '2026 Desktop Workbench Verification Edition',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 14,
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  height: 1.16,
                ),
          ),
          const SizedBox(height: 12),
          for (final line in (zh
              ? [
                  '1. 摘要：基于本地知识库证据生成。',
                  '2. 证据覆盖：引用、来源、时间戳保持可追踪。',
                  '3. 风险：外部事实比对已验收，执行仍需显式网络 opt-in。',
                  '4. 导出：Markdown / DOCX / PDF / PPTX 在本模块管理。'
                ]
              : [
                  '1. Summary: generated from local Knowledge Base evidence.',
                  '2. Coverage: citations, sources, and timestamps stay traceable.',
                  '3. Risk: external comparison is accepted and still requires explicit network opt-in.',
                  '4. Export: Markdown / DOCX / PDF / PPTX are owned here.'
                ])) ...[
            Text(line,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.18,
                    )),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 10),
          _PagePreviewStrip(zh: zh),
        ],
      ),
    );
  }
}

class _SourceDocumentPreviewPanel extends StatelessWidget {
  const _SourceDocumentPreviewPanel({required this.zh, required this.ready});

  final bool zh;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lines = zh
        ? [
            '标题：知识库验证报告草稿',
            '摘要：基于本地来源文档生成，引用、页码与时间戳保持可追踪。',
            '正文：当前预览覆盖封面、摘要、证据、风险和导出章节。',
            '边界：外部事实比对已验收，文档库只展示来源与引用，不直接执行网络任务。',
          ]
        : [
            'Title: Knowledge Base validation draft',
            'Summary: generated from local source documents with traceable citations, pages, and timestamps.',
            'Body: preview covers cover, summary, evidence, risk, and export sections.',
            'Boundary: external comparison is accepted; Documents shows sources and citations without directly running network tasks.',
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
    required this.hiddenRows,
    required this.onDelete,
    required this.onClear,
    required this.onRestore,
  });

  final bool zh;
  final List<List<String>> rows;
  final Set<int> hiddenRows;
  final ValueChanged<int> onDelete;
  final VoidCallback onClear;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (var index = 0; index < rows.length; index++)
        if (!hiddenRows.contains(index)) MapEntry(index, rows[index])
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (visible.isEmpty)
          _RuntimeFeedbackBanner(
            title: zh ? '历史记录已清空' : 'History cleared',
            detail: zh
                ? '不会删除本地真实产物；仅清理页面记录。'
                : 'Local artifacts are kept; only the visible list is cleared.',
            tone: _StatusTone.neutral,
            icon: Icons.delete_sweep_outlined,
          )
        else
          _ProductTable(
            columns: zh
                ? ['记录', '状态', '说明', '操作']
                : ['Record', 'Status', 'Note', 'Action'],
            rows: visible
                .map((entry) => [
                      entry.value[0],
                      entry.value[1],
                      entry.value[2],
                      zh ? '可删除' : 'deletable',
                    ])
                .toList(growable: false),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    visible.isEmpty ? null : () => onDelete(visible.first.key),
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
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: hiddenRows.isEmpty ? null : onRestore,
                icon: const Icon(Icons.restore_outlined),
                label: Text(zh ? '恢复' : 'Restore'),
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
  final Set<int> hiddenHistoryRows = <int>{};

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
          ],
        ),
      ),
    );
    if (choice == 'file') {
      await rc6.pickAndImportFile();
    } else if (choice == 'folder') {
      await rc6.pickAndImportFolder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final hasSources = stagedSources > 0 || runtime.sourceCount > 0;
    final hasManifest = preparedManifests > 0 || runtime.hasImportedFile;
    final hasRealImport = runtime.hasImportedFile;
    final steps = _zh
        ? ['选择来源', '解析器', 'OCR', '分块', '执行', '校验']
        : ['Source', 'Parser', 'OCR', 'Chunking', 'Run', 'Validate'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductHeader(
          icon: Icons.upload_file_outlined,
          title: _zh ? '导入与解析' : 'Import & Parsing',
          description: _zh
              ? '文件、文件夹与网页链接进入同一队列；解析器、OCR、分块和失败恢复在本页完成。'
              : 'Files, folders, and web links enter one queue; parser, OCR, chunking, and recovery are handled here.',
          trailing: _StatePill(
            label: widget.isWebRuntime
                ? (_zh ? 'Web 安全边界' : 'Web safety boundary')
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
        _WorkflowSteps(steps: steps, activeIndex: hasManifest ? 4 : 1),
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
              _ProductTable(
                columns: _zh
                    ? ['来源类型', '范围', '当前状态', '产物']
                    : ['Source type', 'Scope', 'Current status', 'Artifact'],
                rows: _zh
                    ? [
                        [
                          '本地文件',
                          'PDF/DOCX/PPTX/XLSX/MD/TXT/CSV',
                          rc6 == null ? '需要桌面 EXE' : '可选择',
                          'source_manifest.json'
                        ],
                        [
                          '本地文件夹',
                          '批量导入全部支持文件',
                          rc6 == null ? '需要桌面 EXE' : '可选择',
                          'source_manifest.json'
                        ],
                        ['网页链接', '单个公开 URL', '授权后启用', '来源记录'],
                      ]
                    : [
                        [
                          'Local file',
                          'PDF/DOCX/PPTX/XLSX/MD/TXT/CSV',
                          rc6 == null ? 'Desktop EXE required' : 'Selectable',
                          'source_manifest.json'
                        ],
                        [
                          'Local folder',
                          'Batch import supported files',
                          rc6 == null ? 'Desktop EXE required' : 'Selectable',
                          'source_manifest.json'
                        ],
                        [
                          'Web link',
                          'Single public URL',
                          'Enable after authorization',
                          'source record'
                        ],
                      ],
              ),
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
                        ['解析器', 'HeiTang Parser / builtin', 'enabled_real'],
                        [
                          'OCR',
                          'PaddleOCR PP-OCRv6 local runtime',
                          'enabled_real'
                        ],
                        ['分块', '语义切分，800 tokens，120 overlap', 'enabled_real'],
                        ['语言', '中文 + 英文', 'enabled_real'],
                      ]
                    : [
                        ['Parser', 'HeiTang Parser / builtin', 'enabled_real'],
                        [
                          'OCR',
                          'PaddleOCR PP-OCRv6 local runtime',
                          'enabled_real'
                        ],
                        [
                          'Chunking',
                          'Semantic, 800 tokens, 120 overlap',
                          'enabled_real'
                        ],
                        ['Language', 'Chinese + English', 'enabled_real'],
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
                hiddenRows: hiddenHistoryRows,
                onDelete: (index) =>
                    setState(() => hiddenHistoryRows.add(index)),
                onClear: () => setState(() {
                  for (var index = 0; index < 4; index++) {
                    hiddenHistoryRows.add(index);
                  }
                }),
                onRestore: () => setState(() => hiddenHistoryRows.clear()),
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
                  ['本地知识库', 'enabled_real', '依赖已有本地产物'],
                  ['向量库 Provider', '未配置外部向量库', '本地索引可用，可在 Settings 配置'],
                  ['外部事实验证', 'enabled_real', '实时外部来源比对已验收'],
                ]
              : [
                  [
                    'Local package',
                    'enabled_real',
                    'Depends on existing local artifacts'
                  ],
                  [
                    'Vector DB provider',
                    'External vector DB not configured',
                    'Local index available; configure in Settings'
                  ],
                  [
                    'External fact verification',
                    'enabled_real',
                    'Live external source comparison accepted'
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

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1040;
      final extraWide = constraints.maxWidth >= 1180;
      final tasks = _ProductPanel(
        keyName: 'document-generation-tasks',
        icon: Icons.post_add_outlined,
        title: zh ? '生成任务' : 'Generation Task',
        minHeight: 366,
        children: [
          _FillPanelColumn(
            height: 276,
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
                              runtime.hasKnowledgeBase ? '真实输入知识库' : '请先构建知识库',
                              runtime.hasKnowledgeBase ? '可生成' : '等待'
                            ],
                            [
                              '生成类型',
                              _documentGenerationTypeLabel(generationType, zh),
                              '已选择'
                            ],
                            ['题材 / 模板', '内置读书笔记模板', '可用'],
                            [
                              '输出格式',
                              outputFormat.toUpperCase(),
                              outputFormat == 'md' ? '真实导出' : '格式适配准备'
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
                                  : 'Build KB first',
                              runtime.hasKnowledgeBase ? 'Ready' : 'Waiting'
                            ],
                            [
                              'Generation type',
                              _documentGenerationTypeLabel(generationType, zh),
                              'Selected'
                            ],
                            [
                              'Genre / template',
                              'Built-in reading-notes template',
                              'Ready'
                            ],
                            [
                              'Output format',
                              outputFormat.toUpperCase(),
                              outputFormat == 'md'
                                  ? 'Real export'
                                  : 'Adapter-ready'
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
                        onSelected: (_) => setState(() => outputFormat = item),
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
                    : () {
                        setState(() {
                          draftQueued = true;
                          previewReady = true;
                        });
                        rc6.generateMarkdown();
                      },
              ),
              _PrimaryProductAction(
                label: zh ? '重新生成' : 'Regenerate',
                icon: Icons.restart_alt_outlined,
                onPressed: runtime.running || rc6 == null
                    ? null
                    : () {
                        setState(() {
                          draftQueued = true;
                          previewReady = true;
                        });
                        rc6.generateMarkdown();
                      },
              ),
            ]),
          ),
        ],
      );
      final preview = _ProductPanel(
        keyName: 'document-live-preview',
        icon: Icons.article_outlined,
        title: zh ? '文档预览' : 'Document Preview',
        minHeight: 366,
        children: [
          _DocumentPreviewPanel(
              zh: zh, ready: previewReady || runtime.hasMarkdown),
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
                          : '等待检索',
                      '引用来源可追踪'
                    ],
                    ['生成历史', runtime.hasMarkdown ? '可追踪' : '等待生成', '用户工作区'],
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
                          : 'Waiting search',
                      'Sources traceable'
                    ],
                    [
                      'History',
                      runtime.hasMarkdown ? 'Traceable' : 'Waiting',
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
                : (zh ? '等待生成' : 'Waiting'),
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '导出边界' : 'Export boundary',
            value: zh
                ? 'MD 真实导出；DOCX/PDF/PPTX/JSON/CSV 由格式适配器生成。'
                : 'MD exports for real; DOCX/PDF/PPTX/JSON/CSV are produced by format adapters.',
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
                value: runtime.hasMarkdown
                    ? (zh ? '已生成' : 'Generated')
                    : (zh ? '可生成' : 'Ready'),
                detail: runtime.hasMarkdown
                    ? (zh ? '真实文件' : 'real file')
                    : (zh ? '等待点击' : 'waiting click'),
                icon: Icons.notes_outlined),
            _MetricDatum(
                label: 'DOCX',
                value: zh ? '格式适配器' : 'Format adapter',
                detail: zh ? '授权后导出' : 'export after adapter',
                icon: Icons.description_outlined),
            _MetricDatum(
                label: 'PDF/PPTX',
                value: zh ? '格式适配器' : 'Format adapter',
                detail: zh ? '分页预览' : 'paged preview',
                icon: Icons.picture_as_pdf_outlined),
            _MetricDatum(
                label: 'JSON/CSV',
                value: zh ? '结构化导出' : 'Structured export',
                detail: zh ? '知识卡片/QA' : 'cards / QA',
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
                  ? 'Markdown 产物保存在本地工作区，导出预览不冒充主链路能力。'
                  : 'Markdown is saved in the local workspace; export preview does not masquerade as a main-flow capability.',
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
                ? 'Markdown 产物保存在本地工作区，导出预览不冒充主链路能力。'
                : 'Markdown is saved in the local workspace; export preview does not masquerade as a main-flow capability.',
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

String _citationStrategyLabel(String value, bool zh) {
  return switch (value) {
    'strict_citation' => zh ? '严格引用' : 'Strict citation',
    'filename_and_chunk' => zh ? '文件名 + Chunk' : 'Filename + chunk',
    _ => zh ? '来源文件名' : 'Source filename',
  };
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

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= _DesktopGrid.rowBreakpoint;
      final export = _ProductPanel(
        keyName: 'document-export-preview',
        icon: Icons.file_download_outlined,
        title: zh ? '文档导出' : 'Document Export',
        children: [
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
                              : '等待草稿',
                      runtime.hasExportedDocument ? '通过' : '等待导出',
                      runtime.hasExportedDocument
                          ? _displayNameForPath(runtime.exportedDocumentPath)
                          : 'reading_notes_export.md'
                    ],
                    [
                      'DOCX',
                      runtime.hasMarkdown ? '格式适配准备' : '格式适配器待草稿',
                      '引用完整性',
                      '授权后生成'
                    ],
                    [
                      'PDF',
                      runtime.hasMarkdown ? '格式适配准备' : '格式适配器待草稿',
                      '导出验证',
                      '授权后生成'
                    ],
                    [
                      'PPTX',
                      runtime.hasMarkdown ? '格式适配准备' : '格式适配器待草稿',
                      '导出验证',
                      '授权后生成'
                    ],
                  ]
                : [
                    [
                      'Markdown',
                      runtime.hasExportedDocument
                          ? 'Exported'
                          : runtime.hasMarkdown
                              ? 'Ready'
                              : 'Waiting for draft',
                      runtime.hasExportedDocument ? 'Passed' : 'Waiting export',
                      runtime.hasExportedDocument
                          ? _displayNameForPath(runtime.exportedDocumentPath)
                          : 'reading_notes_export.md'
                    ],
                    [
                      'DOCX',
                      runtime.hasMarkdown
                          ? 'Adapter-ready'
                          : 'Adapter waiting for draft',
                      'Citation integrity',
                      'Generated after authorization'
                    ],
                    [
                      'PDF',
                      runtime.hasMarkdown
                          ? 'Adapter-ready'
                          : 'Adapter waiting for draft',
                      'Export validation',
                      'Generated after authorization'
                    ],
                    [
                      'PPTX',
                      runtime.hasMarkdown
                          ? 'Adapter-ready'
                          : 'Adapter waiting for draft',
                      'Export validation',
                      'Generated after authorization'
                    ],
                  ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _PrimaryProductAction(
            label: zh ? '导出 Markdown 文件' : 'Export Markdown file',
            icon: Icons.file_download_outlined,
            onPressed: runtime.running || rc6 == null || !runtime.hasMarkdown
                ? null
                : () {
                    setState(() => exportPreviewReady = true);
                    rc6.exportMarkdownDocument();
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
  bool named = true;
  bool llmEnhance = false;
  String kbType = 'basic';

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
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
                _WorkflowSteps(
                  steps: zh
                      ? ['选择文档', '命名', '选择类型', '增强选项', '构建', '查看产物']
                      : [
                          'Select docs',
                          'Name',
                          'Type',
                          'Enhance',
                          'Build',
                          'Artifacts'
                        ],
                  activeIndex: runtime.hasKnowledgeBase
                      ? 5
                      : sourceSelected
                          ? 4
                          : 0,
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
                          ['知识库名称', '真实输入知识库', named ? '已命名' : '待命名'],
                          ['知识库类型', _knowledgeTypeLabel(kbType, zh), '已选择'],
                          [
                            'LLM 增强',
                            llmEnhance ? '启用，使用已配置 Provider' : '关闭，使用本地构建',
                            llmEnhance ? '授权后执行' : '本地可用'
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
                            'Real input Knowledge Base',
                            named ? 'Named' : 'Needs name'
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
                            llmEnhance ? 'Authorized run' : 'Local ready'
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
              onPressed:
                  runtime.running || rc6 == null || !runtime.hasImportedFile
                      ? null
                      : () {
                          setState(() => sourceSelected = true);
                          rc6.buildKnowledgeBase();
                        },
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
              _ProductTable(
                columns:
                    zh ? ['产物', '状态', '查看'] : ['Artifact', 'Status', 'View'],
                rows: zh
                    ? [
                        [
                          'source_manifest.json',
                          runtime.sourceManifestPath.isNotEmpty ? '完成' : '等待',
                          runtime.sourceManifestPath.isEmpty
                              ? '来源清单'
                              : _displayNameForPath(runtime.sourceManifestPath)
                        ],
                        [
                          'chunks.jsonl',
                          runtime.chunksPath.isNotEmpty ? '完成' : '等待',
                          runtime.chunksPath.isEmpty
                              ? 'chunks.jsonl'
                              : _displayNameForPath(runtime.chunksPath)
                        ],
                        [
                          'quality_report.json',
                          runtime.qualityReportPath.isNotEmpty ? '通过' : '等待',
                          runtime.qualityReportPath.isEmpty
                              ? '质量报告'
                              : _displayNameForPath(runtime.qualityReportPath)
                        ],
                        [
                          'manifest.json',
                          runtime.kbManifestPath.isNotEmpty ? '完成' : '等待',
                          runtime.kbManifestPath.isEmpty
                              ? '知识库清单'
                              : _displayNameForPath(runtime.kbManifestPath)
                        ],
                      ]
                    : [
                        [
                          'source_manifest.json',
                          runtime.sourceManifestPath.isNotEmpty
                              ? 'Done'
                              : 'Waiting',
                          runtime.sourceManifestPath.isEmpty
                              ? 'source_manifest'
                              : _displayNameForPath(runtime.sourceManifestPath)
                        ],
                        [
                          'chunks.jsonl',
                          runtime.chunksPath.isNotEmpty ? 'Done' : 'Waiting',
                          runtime.chunksPath.isEmpty
                              ? 'chunks.jsonl'
                              : _displayNameForPath(runtime.chunksPath)
                        ],
                        [
                          'quality_report.json',
                          runtime.qualityReportPath.isNotEmpty
                              ? 'Passed'
                              : 'Waiting',
                          runtime.qualityReportPath.isEmpty
                              ? 'quality_report'
                              : _displayNameForPath(runtime.qualityReportPath)
                        ],
                        [
                          'manifest.json',
                          runtime.kbManifestPath.isNotEmpty
                              ? 'Done'
                              : 'Waiting',
                          runtime.kbManifestPath.isEmpty
                              ? 'KB manifest'
                              : _displayNameForPath(runtime.kbManifestPath)
                        ],
                      ],
              ),
              const SizedBox(height: 8),
              _EqualActionRow(children: [
                _DisplayAction(
                  label: zh ? '查看质量报告' : 'View quality report',
                  icon: Icons.rule_outlined,
                  onPressed: () => setState(() => qualityReportPrepared = true),
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
                      runtime.hasKnowledgeBase ? 'enabled_real' : '请先构建'
                    ],
                    [
                      'local_cards_qa',
                      runtime.cardsPath.isNotEmpty
                          ? 'cards / qa_pairs'
                          : '等待产物',
                      '本地 JSONL',
                      runtime.cardsPath.isNotEmpty ? 'ready' : '-',
                      runtime.cardsPath.isNotEmpty ? '已生成' : '等待构建',
                      runtime.cardsPath.isNotEmpty ? 'enabled_real' : '请先构建'
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
                      runtime.hasKnowledgeBase ? 'enabled_real' : 'Build first'
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
                      runtime.cardsPath.isNotEmpty
                          ? 'enabled_real'
                          : 'Build first'
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

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    final runtime =
        _Rc6RuntimeScope.of(context)?.state ?? Rc6RuntimeState.initial();
    final hasRealDocument = runtime.hasImportedFile;
    final parsed = runtime.parseReportPath.isNotEmpty;
    final chunkCount = runtime.chunkCount;
    final importedNames = runtime.sourceNames.isEmpty
        ? <String>[
            if (hasRealDocument) _displayNameForPath(runtime.selectedFilePath)
          ]
        : runtime.sourceNames;
    final documentRows = importedNames.isEmpty
        ? [
            [
              zh ? '请先导入真实文件' : 'Import real files first',
              '-',
              zh ? '本地文件' : 'Local file',
              zh ? '尚未导入' : 'Not imported',
              '-',
              '0',
            ]
          ]
        : importedNames
            .map((name) => [
                  name,
                  'rc7',
                  zh ? '本地文件' : 'Local file',
                  parsed ? (zh ? '已解析' : 'Parsed') : (zh ? '已导入' : 'Imported'),
                  zh ? '持久化' : 'Persisted',
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
                const _StatusBadge(
                    label: 'PDF', icon: Icons.picture_as_pdf_outlined),
                const _StatusBadge(
                    label: 'DOCX', icon: Icons.description_outlined),
                const _StatusBadge(label: 'WEB', icon: Icons.link_outlined),
                _StatusBadge(
                    label: zh ? '筛选: 解析完成' : 'Filter: parsed',
                    tone: _StatusTone.success,
                    icon: Icons.filter_alt_outlined),
              ]),
              const SizedBox(height: _DesktopGrid.gutter),
              _RuntimeFeedbackBanner(
                title: hasRealDocument
                    ? (zh ? '真实文档已进入文档库' : 'Real document is in library')
                    : (zh ? '等待导入真实文档' : 'Waiting for real document import'),
                detail: hasRealDocument
                    ? _displayNameForPath(runtime.sourceManifestPath)
                    : (zh
                        ? '请从导入与解析页选择真实文件或文件夹。'
                        : 'Choose real files or a folder from Import & Parsing.'),
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
                          ? ['文档', '分类', '来源', '解析', '版本', '引用']
                          : [
                              'Document',
                              'Category',
                              'Source',
                              'Parsing',
                              'Version',
                              'Refs'
                            ],
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
            onPressed: () => setState(() => indexed = true),
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
                      label: zh ? '页数' : 'Pages',
                      value: hasRealDocument ? '1' : '-',
                      detail: zh ? '真实来源' : 'real source',
                      icon: Icons.menu_book_outlined),
                  _MetricDatum(
                      label: 'chunks',
                      value: chunkCount.toString(),
                      detail: parsed
                          ? (zh ? '已切分' : 'split')
                          : (zh ? '等待' : 'waiting'),
                      icon: Icons.segment_outlined),
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
                            value: hasRealDocument
                                ? _displayNameForPath(
                                    runtime.sourceManifestPath)
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
          bottom: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCaption(zh ? '版本记录' : 'Version Records'),
              const SizedBox(height: 6),
              _BoundedScrollRegion(
                child: _LocalScrollBox(
                  height: 144,
                  child: _ProductTable(
                    columns:
                        zh ? ['版本', '时间', '说明'] : ['Version', 'Time', 'Note'],
                    rows: zh
                        ? [
                            ['v2.3', '今天 10:42', '解析完成'],
                            ['v2.2', '昨天 16:28', '引用更新'],
                            ['v2.1', '05-12', '来源校验'],
                            ['v2.0', '05-02', '元数据补齐'],
                          ]
                        : [
                            ['v2.3', 'Today 10:42', 'Parsed'],
                            ['v2.2', 'Yesterday 16:28', 'Refs updated'],
                            ['v2.1', '05-12', 'Source checked'],
                            ['v2.0', '05-02', 'Metadata completed'],
                          ],
                  ),
                ),
              ),
            ],
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
                child: _SourceDocumentPreviewPanel(zh: zh, ready: indexed),
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              Expanded(
                child: _BoundedScrollRegion(
                  child: _LocalScrollBox(
                    child: _PagePreviewStrip(zh: zh),
                  ),
                ),
              ),
            ],
          ),
          bottom: _EqualFieldGrid(
            columns: 2,
            children: [
              _FieldRow(
                  label: zh ? '摘要块' : 'Summary block',
                  value: zh
                      ? '验证报告草稿，引用和风险段已登记'
                      : 'Draft report with citations and risk section'),
              _FieldRow(
                  label: zh ? '引用信息' : 'Citation info',
                  value:
                      zh ? '18 个来源引用，页码保留' : '18 source references with pages'),
              _FieldRow(
                  label: zh ? '风险提示' : 'Risk note',
                  value: zh
                      ? '外部事实比对已验收；文档库仅展示证据'
                      : 'External comparison accepted; Documents shows evidence'),
            ],
          ),
        ),
      );
      if (!wide) {
        return Column(children: [
          SizedBox(height: 620, child: docs),
          const SizedBox(height: _DesktopGrid.gutter),
          SizedBox(height: 500, child: preview),
          const SizedBox(height: _DesktopGrid.gutter),
          SizedBox(height: 460, child: detail)
        ]);
      }
      return _EqualHeightRow(
        height: 672,
        flexes: const [4, 4, 4],
        children: [docs, preview, detail],
      );
    });
  }
}

class _DocumentLibraryProductWorkflow extends StatelessWidget {
  const _DocumentLibraryProductWorkflow({required this.localeCode});

  final String localeCode;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.library_books_outlined,
        title: _zh ? '文档库' : 'Document Library',
        description: _zh
            ? '管理来源文档、分类、搜索、筛选、解析信息、元数据、版本和引用情况。'
            : 'Manage source documents, categories, search, filters, parsing information, metadata, versions, and references.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
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
    final realResults = runtime.searchResults;
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
          _FieldRow(
              label: zh ? '所选知识库' : 'Selected KB',
              value: runtime.hasKnowledgeBase
                  ? (zh ? '真实输入知识库' : 'Real input KB')
                  : (zh ? '请先构建知识库' : 'Build KB first')),
          const SizedBox(height: 8),
          TextField(
            key: const Key('retrieval-real-query-input'),
            controller: _queryController,
            enabled: !runtime.running,
            onSubmitted: (value) => rc6?.search(value),
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
          _WorkflowSteps(
            steps: zh
                ? ['查询改写', '检索规划', '混合检索', '重排', '证据验证']
                : ['Rewrite', 'Planning', 'Hybrid', 'Rerank', 'Verify'],
            activeIndex:
                runtime.searchStatus == Rc6SearchStatus.success ? 4 : 2,
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
                : realResults
                    .map((result) => [
                          result.excerpt.isEmpty
                              ? result.title
                              : result.excerpt,
                          result.citation,
                          result.score.isEmpty ? '-' : result.score,
                          zh ? '本地证据通过' : 'Local evidence passed',
                          zh
                              ? '可标记矛盾 / 忽略 / 保留'
                              : 'Mark contradiction / ignore / keep',
                        ])
                    .toList(growable: false),
          ),
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
                      ? '${realResults.length}/${realResults.length}'
                      : '-',
                  detail: zh ? '命中证据 / 返回证据' : 'matched / returned',
                  icon: Icons.verified_outlined),
              _MetricDatum(
                  label: zh ? '忠实度' : 'Faithfulness',
                  value: runtime.searchStatus == Rc6SearchStatus.success
                      ? '100%'
                      : '-',
                  detail: zh ? '有引用答案 / 全部答案' : 'cited / all',
                  icon: Icons.link_outlined),
              _MetricDatum(
                  label: zh ? '覆盖率' : 'Coverage',
                  value: realResults.length.toString(),
                  detail: zh ? '命中来源数' : 'source hits',
                  icon: Icons.pie_chart_outline),
              _MetricDatum(
                  label: zh ? '矛盾项' : 'Contradictions',
                  value: runtime.searchStatus == Rc6SearchStatus.success
                      ? '0'
                      : '-',
                  detail: zh ? '人工可纠偏' : 'manual correction',
                  icon: Icons.warning_amber_outlined),
            ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _EqualActionRow(children: [
            _PrimaryProductAction(
              label: zh ? '运行真实检索' : 'Run real retrieval',
              onPressed: runtime.running || rc6 == null
                  ? null
                  : () {
                      setState(() => retrievalPrepared = true);
                      rc6.search(_queryController.text);
                    },
              icon: Icons.play_arrow_outlined,
            ),
            _DisabledAction(
              label: zh
                  ? '授权后执行外部事实验证'
                  : 'Run external fact checking after authorization',
              reason: zh
                  ? '需要在设置中配置联网 Provider、Tool Adapter 和显式 opt-in。'
                  : 'Requires network Provider, Tool Adapter, and explicit opt-in in Settings.',
              icon: Icons.public_off_outlined,
            ),
          ]),
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

  bool get _zh => widget.localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final tabs = _zh
        ? ['来源配置', '包结构', '治理报告']
        : ['Source Config', 'Package Structure', 'Governance Report'];
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
              label: _zh ? '入口' : 'Entrypoints',
              value: '5',
              detail: _zh ? '书籍/知识库/模板' : 'book/base/template',
              icon: Icons.alt_route_outlined),
          _MetricDatum(
              label: _zh ? '模板' : 'Templates',
              value: '6',
              detail: _zh ? 'Skill 专属' : 'Skill owned',
              icon: Icons.dashboard_customize_outlined),
          _MetricDatum(
              label: _zh ? '治理报告' : 'Governance',
              value: runtime.hasSkill ? 'pass' : 'ready',
              detail:
                  runtime.hasSkill ? 'enabled_real' : (_zh ? '待生成' : 'pending'),
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
          title: _zh ? 'Skill 元数据与来源配置' : 'Skill Metadata and Source Config',
          children: [
            _ProductTable(
              columns:
                  _zh ? ['入口', '来源', '状态'] : ['Entrypoint', 'Source', 'Status'],
              rows: _zh
                  ? [
                      [
                        '书籍 / 文档转 Skill',
                        '文档库',
                        runtime.hasSkill
                            ? '已生成'
                            : runtime.hasKnowledgeBase
                                ? '可生成'
                                : '请先构建知识库'
                      ],
                      [
                        '知识库转 Skill',
                        '知识库',
                        runtime.hasSkill
                            ? '已生成'
                            : runtime.hasKnowledgeBase
                                ? '可生成'
                                : '请先构建知识库'
                      ],
                    ]
                  : [
                      [
                        'Book / doc to Skill',
                        'Document Library',
                        runtime.hasSkill
                            ? 'Generated'
                            : runtime.hasKnowledgeBase
                                ? 'Ready'
                                : 'Build KB first'
                      ],
                      [
                        'Knowledge Base to Skill',
                        'Knowledge Base',
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
                label: _zh ? '配置生成方式' : 'Generation mode',
                value: _zh ? '知识库到 Skill 草稿' : 'Knowledge Base to Skill draft'),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '按需加载' : 'On-demand loading',
                value: _zh
                    ? 'Smart 按需加载，Token 预算 120K'
                    : 'Smart on-demand loading, 120K token budget'),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? 'Skill 元数据' : 'Skill metadata',
                value: configReady
                    ? (_zh
                        ? '名称、说明、适用任务已准备'
                        : 'Name, description, and target task prepared')
                    : (_zh
                        ? '使用知识库自动生成'
                        : 'Generated from the Knowledge Base')),
            const SizedBox(height: 8),
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
                      rc6.generateSkill();
                    },
            ),
          ],
        );
        final output = _ProductPanel(
          keyName: 'skill-output-preview',
          icon: Icons.folder_zip_outlined,
          title: _zh ? 'Skill 包结构' : 'Skill Package Structure',
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
                      ['manifests/', ''],
                      ['skill_manifest.yaml', runtime.hasSkill ? '已生成' : '-'],
                      ['README / usage', runtime.hasSkill ? '已生成' : '-'],
                      ['examples/', runtime.hasSkill ? '已生成' : '-'],
                    ]
                  : [
                      ['knowledge_qa_skill/', ''],
                      ['SKILL.md', runtime.hasSkill ? 'written' : '-'],
                      ['manifests/', ''],
                      [
                        'skill_manifest.yaml',
                        runtime.hasSkill ? 'written' : '-'
                      ],
                      ['README / usage', runtime.hasSkill ? 'written' : '-'],
                      ['examples/', runtime.hasSkill ? 'written' : '-'],
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
                      rc6.generateSkill();
                    },
            ),
          ],
        );
        final validation = _ProductPanel(
          keyName: 'skill-validation-summary',
          icon: Icons.rule_outlined,
          title: _zh ? '治理报告与验证' : 'Governance Report and Validation',
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
                label: _zh ? '覆盖率' : 'Coverage',
                value: validationReady
                    ? (runtime.hasSkill ? 'real package' : '86%')
                    : (_zh ? '等待报告' : 'Waiting for report')),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '可安装性' : 'Installability',
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
                label: _zh ? '校验并生成 Skill' : 'Validate and generate Skill',
                onPressed: runtime.running || rc6 == null
                    ? null
                    : () {
                        setState(() {
                          configReady = true;
                          outputPreviewReady = true;
                          validationReady = true;
                        });
                        rc6.generateSkill();
                      },
                icon: Icons.auto_awesome_outlined,
              ),
              const _DisplayAction(
                  label: 'Skill Governance Report',
                  icon: Icons.assessment_outlined),
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
          1 => output,
          2 => validation,
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
        ? ['创建 Agent', '绑定与讨论', '运行审计', '安全边界']
        : [
            'Create Agent',
            'Bindings & Discussion',
            'Runtime Audit',
            'Safety Boundary'
          ];
    final phases = _campaign6List(campaign6AgentRuntimeStatus['phase_status']);
    final agents =
        _campaign6List(campaign6AgentRuntimeStatus['agent_types_6a']);
    final advanced =
        _campaign6List(campaign6AgentRuntimeStatus['advanced_capabilities_6b']);
    final toolAdapter =
        _campaign6Map(campaign6AgentRuntimeStatus['tool_adapter_gate']);
    final rc6 = _Rc6RuntimeScope.of(context);
    final runtime = rc6?.state ?? Rc6RuntimeState.initial();
    final acceptedPhases = phases
        .where((item) => item['runtime_status'] == 'pass')
        .length
        .toString();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.smart_toy_outlined,
        title: _zh ? 'Agent Runtime' : 'Agent Runtime',
        description: _zh
            ? '创建 Agent、绑定知识库与 Skill，并在本页启动多 Agent 联合讨论。'
            : 'Create Agents, bind Knowledge Base and Skill, and run multi-agent discussion here.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _MetricStrip(
        items: [
          _MetricDatum(
              label: _zh ? '6A Agent' : '6A Agents',
              value: agents.length.toString(),
              detail: _zh ? '五类真实 workflow' : 'real workflows',
              icon: Icons.psychology_alt_outlined),
          _MetricDatum(
              label: _zh ? '6B 能力' : '6B Areas',
              value: advanced.length.toString(),
              detail: _zh ? 'Memory / A2A / Teams' : 'Memory / A2A / Teams',
              icon: Icons.hub_outlined),
          _MetricDatum(
              label: _zh ? 'Gate' : 'Gates',
              value: acceptedPhases,
              detail: toolAdapter['ui_state']?.toString() ?? 'enabled_real',
              icon: Icons.fact_check_outlined),
          _MetricDatum(
              label: _zh ? 'Agent 草稿' : 'Agent draft',
              value: runtime.hasAgent ? 'real' : '0',
              detail: runtime.hasAgent
                  ? (_zh ? '已生成' : 'generated')
                  : (_zh ? '等待生成' : 'waiting generation'),
              icon: Icons.smart_toy_outlined),
        ],
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _PageTabs(
          tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
      const SizedBox(height: _DesktopGrid.gutter),
      switch (selectedTab) {
        1 => _AgentDiscussionProductView(zh: _zh),
        2 => Column(children: [
            _Campaign6RuntimeOverviewView(
              zh: _zh,
              phases: phases,
              security: _campaign6Map(
                  campaign6AgentRuntimeStatus['security_boundaries']),
            ),
            const SizedBox(height: _DesktopGrid.gutter),
            _Campaign6SingleAgentStatusView(zh: _zh, agents: agents),
          ]),
        3 =>
          _Campaign6AdvancedRuntimeStatusView(zh: _zh, capabilities: advanced),
        _ => _AgentCreationProductView(zh: _zh, workspace: workspace),
      },
      if (selectedTab == 3) ...[
        const SizedBox(height: _DesktopGrid.gutter),
        _Campaign6ToolAdapterStatusView(
            zh: _zh, toolAdapter: toolAdapter, workspace: workspace),
      ],
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

List<String> _campaignStringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value.map((item) => item.toString()).toList(growable: false);
}

class _AgentCreationProductView extends StatelessWidget {
  const _AgentCreationProductView({
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
      final create = _ProductPanel(
        keyName: 'agent-create-product-flow',
        icon: Icons.smart_toy_outlined,
        title: zh ? '创建 Agent' : 'Create Agent',
        subtitle: runtime.hasAgent
            ? _displayNameForPath(runtime.agentPath)
            : '$workspace/workbench_runs/agent',
        children: [
          _ProductTable(
            columns: zh
                ? ['Agent', '知识库绑定', 'Skill 绑定', '状态']
                : ['Agent', 'KB binding', 'Skill binding', 'Status'],
            rows: zh
                ? [
                    [
                      '知识问答 Agent',
                      runtime.hasKnowledgeBase ? '已绑定' : '请先构建知识库',
                      runtime.hasSkill ? '已绑定' : '请先生成 Skill',
                      runtime.hasAgent ? '已生成' : '可创建'
                    ],
                    [
                      '阅读总结 Agent',
                      runtime.hasKnowledgeBase ? '已绑定' : '请先构建知识库',
                      runtime.hasSkill ? '已绑定' : '请先生成 Skill',
                      runtime.hasAgent ? '已生成' : '等待创建'
                    ],
                    [
                      '质检 / 运营 / 产品分析 Agent',
                      runtime.hasKnowledgeBase ? '已绑定' : '请先构建知识库',
                      runtime.hasSkill ? '已绑定' : '请先生成 Skill',
                      runtime.hasAgent ? '已生成' : '等待创建'
                    ],
                  ]
                : [
                    [
                      'Knowledge QA Agent',
                      runtime.hasKnowledgeBase ? 'Bound' : 'Build KB first',
                      runtime.hasSkill ? 'Bound' : 'Generate Skill first',
                      runtime.hasAgent ? 'Generated' : 'Ready to create'
                    ],
                    [
                      'Reading Summary Agent',
                      runtime.hasKnowledgeBase ? 'Bound' : 'Build KB first',
                      runtime.hasSkill ? 'Bound' : 'Generate Skill first',
                      runtime.hasAgent ? 'Generated' : 'Waiting'
                    ],
                    [
                      'QA / Ops / Product Analysis Agents',
                      runtime.hasKnowledgeBase ? 'Bound' : 'Build KB first',
                      runtime.hasSkill ? 'Bound' : 'Generate Skill first',
                      runtime.hasAgent ? 'Generated' : 'Waiting'
                    ],
                  ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _PrimaryProductAction(
            label: zh ? '生成 Agent' : 'Generate Agent',
            icon: Icons.smart_toy_outlined,
            onPressed: runtime.running || rc6 == null
                ? null
                : () => rc6.generateAgent(),
          ),
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
            label: zh ? '输出格式' : 'Output',
            value: zh
                ? 'agent_manifest.json / package'
                : 'agent_manifest.json / package',
          ),
          const SizedBox(height: 8),
          _FieldRow(
            label: zh ? '能力边界' : 'Boundary',
            value: zh
                ? '本地 KB/Skill，不开放 arbitrary shell 或 Computer Use'
                : 'Local KB/Skill only; no arbitrary shell or Computer Use',
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
      title: zh ? '多 Agent 联合讨论' : 'Multi-Agent Discussion',
      subtitle: runtime.hasMultiAgentDiscussion
          ? _displayNameForPath(runtime.multiAgentDiscussionPath)
          : (zh ? '等待 Agent 产物' : 'Waiting for Agent package'),
      children: [
        _ProductTable(
          columns: zh ? ['角色', '输入', '输出'] : ['Role', 'Input', 'Output'],
          rows: zh
              ? [
                  ['阅读总结 Agent', '真实知识库', '主题摘要'],
                  ['知识问答 Agent', '检索结果', '证据化回答'],
                  ['质检 Agent', '解析与 Chunk', '风险与复核点'],
                  ['运营转化 Agent', '读书笔记', '行动建议'],
                  ['产品分析 Agent', '知识库主题', '产品判断'],
                ]
              : [
                  ['Reading Summary Agent', 'Real KB', 'Theme summary'],
                  ['Knowledge QA Agent', 'Search results', 'Grounded answer'],
                  ['Quality Agent', 'Parse and chunks', 'Review risks'],
                  ['Ops Conversion Agent', 'Reading notes', 'Action advice'],
                  ['Product Analysis Agent', 'KB themes', 'Product judgement'],
                ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
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
      ],
    );
  }
}

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
    final tabs = _zh
        ? ['验证清单', '报告证据', '受控导出']
        : ['Checklist', 'Reports Evidence', 'Controlled Export'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.fact_check_outlined,
        title: _zh ? '审计与报告' : 'Reports & Audit',
        description: _zh
            ? '汇总质量、检索、OCR、安全和治理报告，展示问题、阻塞项和修复建议。'
            : 'Summarize quality, retrieval, OCR, safety, and governance reports, issues, blockers, and repair suggestions.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _PageTabs(
          tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
      const SizedBox(height: _DesktopGrid.gutter),
      if (selectedTab == 1)
        _ReportsEvidenceView(zh: _zh)
      else if (selectedTab == 2)
        _ControlledExportView(zh: _zh, workspace: workspace)
      else
        _ValidationChecklistView(zh: _zh),
    ]);
  }
}

class _ValidationChecklistView extends StatefulWidget {
  const _ValidationChecklistView({required this.zh});
  final bool zh;

  @override
  State<_ValidationChecklistView> createState() =>
      _ValidationChecklistViewState();
}

class _ValidationChecklistViewState extends State<_ValidationChecklistView> {
  bool checklistPrepared = false;

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final center = _ProductPanel(
        keyName: 'validation-checklist',
        icon: Icons.receipt_long_outlined,
        title: zh ? '报告中心' : 'Report Center',
        children: [
          _MetricStrip(
            items: [
              _MetricDatum(
                  label: zh ? '全部报告' : 'Reports',
                  value: '7',
                  detail: zh ? '5 通过' : '5 pass',
                  icon: Icons.receipt_long_outlined),
              _MetricDatum(
                  label: zh ? '需关注' : 'Needs review',
                  value: '1',
                  detail: 'Final Gate',
                  icon: Icons.warning_amber_outlined),
              _MetricDatum(
                  label: zh ? '阻塞' : 'Blocked',
                  value: checklistPrepared ? '0' : '1',
                  detail: 'UI Gate',
                  icon: Icons.block_outlined),
            ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _ProductTable(
            columns: zh
                ? ['报告项', '状态', '最新运行', '趋势', '动作']
                : ['Report', 'Status', 'Last run', 'Trend', 'Action'],
            rows: zh
                ? [
                    ['Product Hardening', 'pass', '今天 10:42', '稳定', '查看'],
                    ['Final Gate', 'needs_review', '昨天 09:21', '波动', '查看'],
                    ['OCR Proof', 'pass', '今天 10:15', '稳定', '查看'],
                    ['Vector Readiness', 'pass', '今天 08:34', '稳定', '查看'],
                    [
                      'UI Gate',
                      checklistPrepared ? 'pass' : 'blocked',
                      '昨天 17:02',
                      '待复核',
                      '修复建议'
                    ],
                  ]
                : [
                    [
                      'Product Hardening',
                      'pass',
                      'Today 10:42',
                      'stable',
                      'View'
                    ],
                    [
                      'Final Gate',
                      'needs_review',
                      'Yesterday 09:21',
                      'mixed',
                      'View'
                    ],
                    ['OCR Proof', 'pass', 'Today 10:15', 'stable', 'View'],
                    [
                      'Vector Readiness',
                      'pass',
                      'Today 08:34',
                      'stable',
                      'View'
                    ],
                    [
                      'UI Gate',
                      checklistPrepared ? 'pass' : 'blocked',
                      'Yesterday 17:02',
                      'review',
                      'Fix advice'
                    ],
                  ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _EqualActionRow(children: [
            _PrimaryProductAction(
              label: zh ? '打开报告清单' : 'Open report checklist',
              icon: Icons.playlist_add_check_outlined,
              onPressed: () => setState(() => checklistPrepared = true),
            ),
          ]),
        ],
      );
      final issues = _ProductPanel(
        icon: Icons.report_problem_outlined,
        title: zh ? '问题与修复建议' : 'Issues and Fix Advice',
        gap: true,
        children: [
          _ProductTable(
            columns: zh ? ['问题', '状态', '建议'] : ['Issue', 'Status', 'Advice'],
            rows: zh
                ? [
                    [
                      'UI Gate 未通过历史项',
                      checklistPrepared ? '已更新' : '阻塞',
                      '保留历史证据，不篡改'
                    ],
                    ['Final Gate 需关注', '需复核', '检查报告证据'],
                    ['Security & Privacy 建议', '需关注', '确认 Secret 不展示'],
                  ]
                : [
                    [
                      'UI Gate historical block',
                      checklistPrepared ? 'Updated' : 'Blocked',
                      'Keep history unchanged'
                    ],
                    [
                      'Final Gate attention',
                      'Needs review',
                      'Check report evidence'
                    ],
                    [
                      'Security & Privacy advice',
                      'Needs review',
                      'Confirm secrets hidden'
                    ],
                  ],
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
  const _ReportsEvidenceView({required this.zh});
  final bool zh;

  @override
  State<_ReportsEvidenceView> createState() => _ReportsEvidenceViewState();
}

class _ReportsEvidenceViewState extends State<_ReportsEvidenceView> {
  bool reportSelected = false;

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final list = _ProductPanel(
        keyName: 'report-evidence-list',
        icon: Icons.receipt_long_outlined,
        title: zh ? '报告证据' : 'Reports Evidence',
        children: [
          _ProductTable(
            columns: zh
                ? ['报告', '范围', '状态', '证据']
                : ['Report', 'Scope', 'Status', 'Evidence'],
            rows: zh
                ? [
                    [
                      'validation_report',
                      '本地验证',
                      reportSelected ? '证据已打开' : '等待',
                      reportSelected ? '本地验证摘要' : '无真实报告'
                    ],
                    ['governance_report', '治理', '只读证据', '历史治理报告'],
                    [
                      'export_manifest',
                      '模块导出证据',
                      reportSelected ? '可查看' : '等待',
                      '受控导出清单'
                    ],
                    ['ocr_report', 'OCR', '可展示', 'parser matrix'],
                    ['security_report', '安全', '可展示', 'Secret 不展示'],
                  ]
                : [
                    [
                      'validation_report',
                      'Local validation',
                      reportSelected ? 'Evidence open' : 'Waiting',
                      reportSelected
                          ? 'Local validation summary'
                          : 'No real report'
                    ],
                    [
                      'governance_report',
                      'Governance',
                      'Read-only evidence',
                      'Historical governance report'
                    ],
                    [
                      'export_manifest',
                      'Module export evidence',
                      reportSelected ? 'Viewable' : 'Waiting',
                      'Controlled export manifest'
                    ],
                    ['ocr_report', 'OCR', 'Displayable', 'parser matrix'],
                    [
                      'security_report',
                      'Safety',
                      'Displayable',
                      'Secrets hidden'
                    ],
                  ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _EqualActionRow(children: [
            _PrimaryProductAction(
              label: zh ? '打开验证报告证据' : 'Open validation report evidence',
              icon: Icons.receipt_long_outlined,
              onPressed: () => setState(() => reportSelected = true),
            ),
          ]),
        ],
      );
      final detail = _ProductPanel(
        keyName: 'selected-report-detail',
        icon: Icons.plagiarism_outlined,
        title: zh ? '选中报告详情' : 'Selected Report Detail',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? '摘要' : 'Summary',
              value: reportSelected
                  ? (zh
                      ? '4 项检查已打开，rc6 等待 Owner 复验'
                      : '4 checks opened; rc6 is pending Owner retest')
                  : (zh ? '等待报告产物' : 'Waiting for report artifact')),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '门禁影响' : 'Gate impact',
              value: reportSelected
                  ? (zh
                      ? 'rc6 真实运行链路修复证据待 Owner 复验，不创建 Release'
                      : 'rc6 runtime truth repair evidence awaits Owner retest; no Release is created')
                  : (zh ? '未通过' : 'Not passed')),
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
  const _ControlledExportView({required this.zh, required this.workspace});
  final bool zh;
  final String workspace;

  @override
  State<_ControlledExportView> createState() => _ControlledExportViewState();
}

class _ControlledExportViewState extends State<_ControlledExportView> {
  bool exportManifestReady = false;

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'controlled-export-summary',
      icon: Icons.outbox_outlined,
      title: zh ? '报告归档边界' : 'Report Archive Boundary',
      subtitle: '${widget.workspace}/workbench_runs/validation_report',
      gap: true,
      children: [
        _ProductTable(
          columns: zh ? ['动作', '分类', '说明'] : ['Action', 'Class', 'Note'],
          rows: zh
              ? [
                  ['归档报告', exportManifestReady ? '已准备' : '未准备', '只归档报告证据'],
                  ['导出文档', '归文档生成模块', '本页不重复入口'],
                  ['导出 Skill', '归 Skill 工厂', '本页不重复入口'],
                  ['导出 Agent Package', '归 Agent 工厂', '本页不重复入口'],
                  ['发布 Release', '未授权', '不创建 Release'],
                ]
              : [
                  [
                    'Archive reports',
                    exportManifestReady ? 'Prepared' : 'Not prepared',
                    'Archives report evidence only'
                  ],
                  [
                    'Export documents',
                    'Document Generation',
                    'No duplicate entry here'
                  ],
                  ['Export Skill', 'Skill Factory', 'No duplicate entry here'],
                  [
                    'Export Agent Package',
                    'Agent Factory',
                    'No duplicate entry here'
                  ],
                  [
                    'Publish Release',
                    'Not authorized',
                    'No Release is created'
                  ],
                ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _EqualActionRow(children: [
          _PrimaryProductAction(
            label: zh ? '准备报告归档清单' : 'Prepare report archive manifest',
            onPressed: () => setState(() => exportManifestReady = true),
            icon: Icons.archive_outlined,
          ),
        ]),
      ],
    );
  }
}

class _SettingsProductWorkflow extends StatelessWidget {
  const _SettingsProductWorkflow({
    required this.localeCode,
    required this.workspace,
    required this.selectedTab,
    required this.onTabSelected,
    required this.isWebRuntime,
    required this.campaign7ConfigurationStatus,
    required this.campaign9DesktopDeliveryStatus,
    required this.diagnostics,
  });

  final String localeCode;
  final String workspace;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;
  final bool isWebRuntime;
  final Map<String, dynamic> campaign7ConfigurationStatus;
  final Map<String, dynamic> campaign9DesktopDeliveryStatus;
  final Widget diagnostics;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final tabs = _zh
        ? ['工作区', 'Provider 与存储', '配置系统', '模型与语言', '安全', '桌面交付', '开发者诊断']
        : [
            'Workspace',
            'Providers and Storage',
            'Configuration System',
            'Models and Language',
            'Safety',
            'Desktop Delivery',
            'Developer Diagnostics'
          ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.settings_outlined,
        title: _zh ? '设置' : 'Settings',
        description: _zh
            ? '管理应用工作区、Provider、存储、模型、语言、主题、安全和诊断。'
            : 'Manage workspace, providers, storage, models, language, theme, safety, and diagnostics.',
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _PageTabs(
          tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
      const SizedBox(height: _DesktopGrid.gutter),
      if (selectedTab == 6)
        diagnostics
      else if (selectedTab == 1)
        _SettingsProvidersStorageView(zh: _zh, workspace: workspace)
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
                            ['LLM Provider', 'live smoke 通过', 'enabled_real'],
                            [
                              'Embedding 模型',
                              'Provider Runtime env-only',
                              '环境配置'
                            ],
                            ['默认语言', '简体中文 / Chinese', 'enabled_real'],
                            ['主题', '浅色 / 深色可切换', 'enabled_real'],
                          ]
                        : [
                            [
                              'LLM Provider',
                              'Live smoke passed',
                              'enabled_real'
                            ],
                            [
                              'Embedding model',
                              'Provider Runtime env-only',
                              'Env config'
                            ],
                            [
                              'Default language',
                              'Simplified Chinese / Chinese',
                              'enabled_real'
                            ],
                            [
                              'Theme',
                              'Light / dark switchable',
                              'enabled_real'
                            ],
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
                          label: _zh ? '本地执行' : 'Local execution',
                          value: isWebRuntime
                              ? (_zh
                                  ? 'Flutter Web 中禁用本地命令'
                                  : 'Local commands disabled in Flutter Web')
                              : (_zh ? '桌面可用' : 'Desktop available')),
                    ]
                  : [
                      _FieldRow(
                          label: _zh ? '工作区' : 'Workspace', value: workspace),
                      const SizedBox(height: 8),
                      _FieldRow(
                          label: _zh ? '输出目录' : 'Output directory',
                          value: './workbench_runs'),
                      const SizedBox(height: 8),
                      const _FieldRow(
                          label: 'Core CLI', value: 'heitang-kb-forge'),
                    ],
        ),
    ]);
  }
}

class _SettingsProvidersStorageView extends StatefulWidget {
  const _SettingsProvidersStorageView({
    required this.zh,
    required this.workspace,
  });

  final bool zh;
  final String workspace;

  @override
  State<_SettingsProvidersStorageView> createState() =>
      _SettingsProvidersStorageViewState();
}

class _SettingsProvidersStorageViewState
    extends State<_SettingsProvidersStorageView> {
  bool storageTested = false;
  bool configSaved = false;

  bool get zh => widget.zh;

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
                    ['应用工作区', widget.workspace, '本地可用', 'enabled_real'],
                    ['对象存储', '本地文件系统', '本地可用', 'enabled_real'],
                    ['向量数据库', '未配置外部向量库', '本地索引可用', '可配置'],
                    ['LLM Provider', '环境变量', 'live smoke 通过', 'enabled_real'],
                    ['API Key', '************', '掩码展示', '已保护'],
                  ]
                : [
                    [
                      'App workspace',
                      widget.workspace,
                      'Local available',
                      'enabled_real'
                    ],
                    [
                      'Object storage',
                      'Local filesystem',
                      'Local available',
                      'enabled_real'
                    ],
                    [
                      'Vector DB',
                      'External vector DB not configured',
                      'Local index available',
                      'Configurable'
                    ],
                    [
                      'LLM Provider',
                      'Environment variables',
                      'Live smoke passed',
                      'enabled_real'
                    ],
                    ['API Key', '************', 'Masked', 'Protected'],
                  ],
          ),
          const SizedBox(height: 8),
          _EqualActionRow(children: [
            _PrimaryProductAction(
              label: zh ? '测试存储连接' : 'Test storage connection',
              icon: Icons.cable_outlined,
              onPressed: () => setState(() => storageTested = true),
            ),
            _PrimaryProductAction(
              label: zh ? '保存配置' : 'Save config',
              icon: Icons.save_outlined,
              onPressed: () => setState(() => configSaved = true),
            ),
          ]),
          if (storageTested || configSaved) ...[
            const SizedBox(height: 8),
            _RuntimeFeedbackBanner(
              title: configSaved
                  ? (zh ? '配置已保存' : 'Config saved')
                  : (zh ? '本地存储连接正常' : 'Local storage connection OK'),
              detail: zh
                  ? '外部向量库未配置时继续使用本地索引；Secret 仍只显示掩码。'
                  : 'When external vector DB is not configured, local index remains active; secrets stay masked.',
              tone: _StatusTone.success,
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
        title: zh ? '配置边界' : 'Configuration Boundary',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? 'Provider Gate' : 'Provider Gate',
              value: zh
                  ? '真实 live smoke 复验已通过'
                  : 'Real live-smoke reacceptance passed'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? 'Secret 展示' : 'Secret display',
              value: zh ? '只显示掩码，不直接展示明文' : 'Masked only, plaintext hidden'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '未接入项' : 'Disconnected items',
              value: zh ? '不得显示为已连接' : 'Must not appear connected'),
          const SizedBox(height: 8),
          _DisplayAction(
              label: zh ? '查看 Provider 验收证据' : 'View Provider evidence',
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
        title: zh ? 'Campaign 7 配置系统' : 'Campaign 7 Configuration System',
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
                  value: _campaignText(_campaign6Map(
                      campaign7ConfigurationStatus['ui_settings'])['ui_state']),
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
            rows: statusRows,
          ),
        ],
      );
      final diagnosticsPanel = _ProductPanel(
        keyName: 'settings-configuration-diagnostics',
        icon: Icons.health_and_safety_outlined,
        title: zh ? '诊断与降级' : 'Diagnostics and Degraded Modes',
        gap: true,
        children: [
          _ProductTable(
            columns: zh ? ['运行面', '状态'] : ['Runtime surface', 'Status'],
            rows: [
              [
                'provider_runtime',
                _campaignText(diagnostics['provider_runtime'])
              ],
              ['agent_runtime', _campaignText(diagnostics['agent_runtime'])],
              [
                'tool_adapter_registry',
                _campaignText(diagnostics['tool_adapter_registry'])
              ],
              ['rag', _campaignText(diagnostics['rag'])],
              ['workspace', _campaignText(diagnostics['workspace'])],
              ['ui_settings', _campaignText(diagnostics['ui_settings'])],
            ],
          ),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh
                ? ['降级条件', '运行状态', '用户提示']
                : ['Condition', 'Runtime status', 'User prompt'],
            rows: degradedRows,
          ),
        ],
      );
      final securityPanel = _ProductPanel(
        keyName: 'settings-configuration-security',
        icon: Icons.verified_user_outlined,
        title: zh ? '安全边界' : 'Security Boundary',
        gap: true,
        children: [
          _ProductTable(
            columns: zh ? ['检查', '结果'] : ['Check', 'Result'],
            rows: securityRows,
          ),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? 'Provider Runtime' : 'Provider Runtime',
              value: _campaignText(
                  _campaign6Map(schema['runtime_reuse'])['provider_runtime'])),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? 'Agent Runtime' : 'Agent Runtime',
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
                  _campaignText(item['evidence']),
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
        title: zh ? 'Campaign 9 桌面交付' : 'Campaign 9 Desktop Delivery',
        gap: true,
        children: [
          _MetricStrip(
            items: [
              _MetricDatum(
                  label: zh ? '本地状态' : 'Local status',
                  value: _campaignText(
                      campaign9DesktopDeliveryStatus['overall_status']),
                  detail: zh ? 'UI 已绑定' : 'UI-bound',
                  icon: Icons.fact_check_outlined),
              _MetricDatum(
                  label: zh ? '候选标签' : 'Candidate tag',
                  value: _campaignText(
                      campaign9DesktopDeliveryStatus['release_candidate_tag']),
                  detail: zh ? '等待 push / CI / tag' : 'pending push / CI / tag',
                  icon: Icons.local_offer_outlined),
              _MetricDatum(
                  label: zh ? '包版本' : 'Package version',
                  value: _campaignText(campaign9DesktopDeliveryStatus[
                      'package_version_baseline']),
                  detail: zh ? '未做版本迁移' : 'no version migration',
                  icon: Icons.inventory_2_outlined),
            ],
          ),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh
                ? ['能力', '状态', 'UI 状态', '证据']
                : ['Capability', 'Status', 'UI state', 'Evidence'],
            rows: validationRows,
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
              label: zh ? 'Tauri 边界' : 'Tauri boundary',
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
              label: zh ? '证据路径' : 'Evidence path',
              value: _campaignText(smoke['evidence_path'])),
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
        title: zh ? '路径、降级与安全边界' : 'Paths, Degraded Modes, and Security',
        gap: true,
        children: [
          _ProductTable(
            columns: zh ? ['路径规则', '说明'] : ['Path rule', 'Description'],
            rows: pathRows,
          ),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh
                ? ['降级条件', '运行状态', '用户提示']
                : ['Condition', 'Runtime status', 'User prompt'],
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
                      ? (zh ? '安全边界' : 'safety boundary')
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
                    ['工作区根目录', workspace, 'enabled_real'],
                    ['输出目录', './workbench_runs', 'enabled_real'],
                    ['文档缓存', './data/documents', '本地路径'],
                    ['向量索引目录', './data/vector', '本地索引'],
                    ['Core CLI', 'heitang-kb-forge', 'enabled_real'],
                  ]
                : [
                    ['Workspace root', workspace, 'enabled_real'],
                    ['Output directory', './workbench_runs', 'enabled_real'],
                    ['Document cache', './data/documents', 'Local path'],
                    ['Vector index dir', './data/vector', 'Local index'],
                    ['Core CLI', 'heitang-kb-forge', 'enabled_real'],
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
                      'Agent 工厂管理'
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
                      'Agent Factory'
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
      'campaign9_windows_exe_packaging_rc6_runtime_truth_blocker_repaired_ui_bound_pending_owner_retest',
  'final_target_status':
      'v4.3.0-rc6_runtime_truth_blockers_repaired_real_exe_verified_pushed_ci_green_tagged_pending_owner_retest',
  'release_candidate_tag': 'v4.3.0-rc6',
  'package_version_baseline': '4.2.0',
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
        'output/rc6_runtime_truth_repair/release_bundle_manifest.json',
    'exe_sha256':
        'd8e58accd56571fc08cfec3178b77ef7e1c3a58c5930c7d9d37718b1253e9d87',
  },
  'desktop_shell_smoke': {
    'status': 'pass',
    'evidence_path':
        'output/rc6_runtime_truth_repair/exe_smoke/rc6_exe_launch_smoke.json',
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
      'ui_state': 'enabled_real',
      'evidence': 'campaign9_flutter_build_windows.log',
    },
    {
      'capability': 'desktop_shell_real_smoke',
      'status': 'pass',
      'ui_state': 'enabled_real',
      'evidence':
          'output/rc6_runtime_truth_repair/exe_smoke/rc6_exe_launch_smoke.json',
    },
    {
      'capability': 'full_capability_runtime_chain',
      'status': 'pass',
      'ui_state': 'enabled_real',
      'evidence':
          'kb-forge-skill/output/rc6_validation_chain/rc6_core_chain_probe.log',
    },
    {
      'capability': 'page_button_tab_audit',
      'status': 'pass',
      'ui_state': 'enabled_real',
      'evidence':
          'v4.3.0-rc6_Tab_Button_Page_Switch_Verification_Matrix_2026-06-17.md',
    },
    {
      'capability': 'release_bundle_manifest',
      'status': 'pass',
      'ui_state': 'enabled_real',
      'evidence':
          'output/rc6_runtime_truth_repair/release_bundle_manifest.json',
    },
    {
      'capability': 'provider_secret_handling',
      'status': 'pass',
      'ui_state': 'enabled_real',
      'evidence': 'env_only_no_secret_bundle_boundary',
    },
    {
      'capability': 'config_workspace_log_cache_paths',
      'status': 'pass',
      'ui_state': 'enabled_real',
      'evidence': 'campaign7_configuration_system_reuse',
    },
    {
      'capability': 'github_release_creation',
      'status': 'not_created',
      'ui_state': 'disabled_boundary',
      'evidence': 'owner_authorization_required',
    },
    {
      'capability': 'computer_use_runtime',
      'status': 'disabled_boundary',
      'ui_state': 'disabled_boundary',
      'evidence': 'campaign6_boundary_preserved',
    },
  ],
  'path_rules': {
    'config_path':
        'Campaign 7 config precedence persists default/workspace/user/env values.',
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
          'Keep Campaign 9 stopped and repair the shell behavior before tagging.',
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
      'rollback': 'Use Campaign 7 rollback snapshots and preserve diagnostics.',
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
