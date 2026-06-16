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
import 'skill_factory/skill_factory_workflow.dart';

void main() {
  runApp(const HeiTangWorkbenchApp());
}

abstract final class _DesktopGrid {
  static const double initialWindowWidth = 1440;
  static const double initialWindowHeight = 900;
  static const double minWindowWidth = 1180;
  static const double gutter = 8;
  static const double sectionGap = 10;
  static const double panelPadding = 10;
  static const double panelRadius = 8;
  static const double maxPageWidth = 1720;
  static const double panelMinHeight = 126;
  static const double metricHeight = 114;
  static const double rowBreakpoint = 900;
  static const double footerSafeArea = 24;
}

enum _DesktopWindowPreviewState { restored, maximized, minimized, closed }

const supportedLocaleCodes = <String>['zh-CN', 'en-US'];

const pages = <WorkbenchPage>[
  WorkbenchPage(
      'dashboard',
      'Dashboard',
      '仪表盘',
      'System overview, recent work, health, blockers, and activity timeline.',
      '系统概览、最近任务、健康状态、阻塞项与活动时间线。',
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
      'Manage source documents, metadata, parsing records, versions, references, and preview.',
      '管理来源文档、元数据、解析记录、版本、引用和预览。',
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
      'Choose a knowledge base, template, and output type, preview documents, validate, and export inside this module.',
      '选择知识库、文档模板和输出类型，在本模块完成预览、验证与导出。',
      memberPageIds: ['document-generation']),
  WorkbenchPage(
      'skill-factory',
      'Skill Factory',
      'Skill 工厂',
      'Create, preview, validate, and export governed Skill drafts.',
      '创建、预览、验证和导出经过治理的 Skill 草稿。',
      memberPageIds: ['skill-factory']),
  WorkbenchPage(
      'agent-factory-runtime',
      'Agent Factory',
      'Agent 工厂',
      'Display Campaign 6 Agent Runtime execution status, evidence, degraded modes, and Tool Adapter boundaries.',
      '展示 Campaign 6 Agent Runtime 执行状态、证据、降级模式与 Tool Adapter 边界。',
      memberPageIds: ['agent-factory-runtime']),
  WorkbenchPage(
      'reports-audit',
      'Reports & Audit',
      '审计与报告',
      'Review quality, retrieval, OCR, safety, and governance reports, blockers, and repair suggestions.',
      '查看质量、检索、OCR、安全和治理报告、阻塞项与修复建议。',
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

class HeiTangWorkbenchApp extends StatefulWidget {
  const HeiTangWorkbenchApp({
    super.key,
    this.contracts,
    this.workflowEvidence,
    this.workflowV2Evidence,
    this.externalCapabilities,
    this.parserBackends,
    this.campaign6AgentRuntimeStatus,
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
  late final Future<Map<String, dynamic>> _skillGovernanceReportFuture =
      Future<Map<String, dynamic>>.value(
          widget.skillGovernanceReport ?? sampleSkillGovernanceReport);

  bool get isDark => themeMode == ThemeMode.dark;

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
                    future: _skillGovernanceReportFuture,
                    initialData: widget.skillGovernanceReport ??
                        sampleSkillGovernanceReport,
                    builder: (context, skillGovernanceSnapshot) =>
                        _WorkbenchScaffold(
                      contracts:
                          contractsSnapshot.data ?? sampleWorkbenchContracts,
                      workflowEvidence:
                          evidenceSnapshot.data ?? sampleP1WorkflowEvidence,
                      workflowV2Evidence:
                          v2Snapshot.data ?? sampleP1WorkflowV2Evidence,
                      externalCapabilities: externalSnapshot.data ??
                          sampleExternalCapabilityRegistry,
                      parserBackends:
                          parserSnapshot.data ?? sampleParserBackendMatrix,
                      campaign6AgentRuntimeStatus: campaign6Snapshot.data ??
                          sampleCampaign6AgentRuntimeStatus,
                      skillGovernanceReport: skillGovernanceSnapshot.data ??
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
                      enableLocalCoreActions: widget.enableLocalCoreActions,
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
    const sidebarWidth = 268.0;

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
                  page: pages[selectedIndex],
                  localeCode: localeCode,
                  contracts: contracts,
                  workflowEvidence: workflowEvidence,
                  workflowV2Evidence: workflowV2Evidence,
                  externalCapabilities: externalCapabilities,
                  parserBackends: parserBackends,
                  campaign6AgentRuntimeStatus: campaign6AgentRuntimeStatus,
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
    return Container(
      key: const Key('desktop-status-bar'),
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 22),
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
          const SizedBox(width: 24),
          Expanded(
            child: _StatusBarItem(
              icon: Icons.folder_open_outlined,
              label: _zh ? '位置' : 'Location',
              value: workspace,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 24),
          _StatusBarItem(
            icon: isWebRuntime
                ? Icons.public_outlined
                : Icons.desktop_windows_outlined,
            label: _zh ? '模式' : 'Mode',
            value: isWebRuntime
                ? (_zh ? '预览模式' : 'Preview mode')
                : (_zh ? '桌面本地执行' : 'Desktop local'),
          ),
          const SizedBox(width: 24),
          _StatusBarItem(
            icon: Icons.info_outline,
            label: _zh ? '版本' : 'Version',
            value: 'v1.0.0',
          ),
          const SizedBox(width: 24),
          _StatusBarItem(
            icon: Icons.sync_outlined,
            label: _zh ? '检查更新' : 'Check updates',
            value: '',
          ),
        ],
      ),
    );
  }
}

class _WindowControlButton extends StatelessWidget {
  const _WindowControlButton({
    required this.keyName,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
  });

  final String keyName;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = danger ? colors.error : colors.onSurfaceVariant;
    final hover = danger
        ? colors.error.withValues(alpha: 0.12)
        : colors.surfaceContainerHighest;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: hover,
          child: SizedBox(
            key: Key(keyName),
            width: 46,
            height: 36,
            child: Icon(icon, size: 17, color: foreground),
          ),
        ),
      ),
    );
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
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
        children: [
          _SidebarBrand(localeCode: localeCode),
          const SizedBox(height: 18),
          _SidebarGroupLabel(
              label: localeCode == 'zh-CN' ? '工作区' : 'Workspace'),
          _SidebarItem(
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
          const SizedBox(height: 18),
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
          const SizedBox(height: 4),
          Text(
              localeCode == 'zh-CN'
                  ? '知识工作台  v1.0.0'
                  : 'Knowledge Workbench  v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: secondaryText,
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: 18),
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
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xff3a424b)
                      : const Color(0xff1a1f24),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon,
                    color: selected ? primaryText : secondaryText, size: 18),
              ),
              const SizedBox(width: _DesktopGrid.gutter),
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
      padding: const EdgeInsets.all(14),
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
                    const SizedBox(height: 4),
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
          const SizedBox(height: _DesktopGrid.gutter),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

class _PageSurface extends StatelessWidget {
  const _PageSurface({
    required this.page,
    required this.localeCode,
    required this.contracts,
    required this.workflowEvidence,
    required this.workflowV2Evidence,
    required this.externalCapabilities,
    required this.parserBackends,
    required this.campaign6AgentRuntimeStatus,
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
  Widget build(BuildContext context) {
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
          : availableWidth;
      return Scrollbar(
        child: SingleChildScrollView(
          key: ValueKey('page-scroll-${page.id}'),
          primary: false,
          padding: const EdgeInsets.all(horizontalPadding),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: contentWidth,
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
            'validation=${validationCheck['status']} · installability=${installabilityCheck['status']} · token=${tokenBudgetCheck['status']}'),
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
      final width = maximized
          ? (viewportWidth < _DesktopGrid.minWindowWidth
              ? _DesktopGrid.minWindowWidth
              : viewportWidth)
          : _DesktopGrid.initialWindowWidth;
      final height = maximized
          ? (viewportHeight < 760 ? 760.0 : viewportHeight)
          : _DesktopGrid.initialWindowHeight;
      final stageWidth = viewportWidth > width ? viewportWidth : width;
      final stageHeight = viewportHeight > height ? viewportHeight : height;
      final frame = widget.childBuilder(
        windowState,
        (state) => setState(() => windowState = state),
      );
      return Container(
        color: colors.surfaceContainerHighest,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: SizedBox(
              width: stageWidth,
              height: stageHeight,
              child: Align(
                alignment: Alignment.center,
                child: AnimatedContainer(
                  key: const Key('desktop-window-preview-frame'),
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  width: width,
                  height: height,
                  constraints: const BoxConstraints(
                    minWidth: _DesktopGrid.minWindowWidth,
                    minHeight: 760,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: maximized ? 0 : 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: frame,
                ),
              ),
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
        return Row(
          key: const Key('desktop-topbar-single-row'),
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showTitleBlock) ...[
              SizedBox(
                width: 312,
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
              ),
            ),
            const SizedBox(width: 6),
            _TopBarChip(
              icon: Icons.terminal,
              label: _zh ? '终端' : 'Terminal',
            ),
            const SizedBox(width: 6),
            _TopBarChip(
              icon: Icons.notifications_none_outlined,
              label: _zh ? '通知' : 'Notifications',
            ),
            const SizedBox(width: 6),
            _TopBarIconButton(
              icon: Icons.refresh_outlined,
              label: _zh ? '刷新' : 'Refresh',
              onPressed: () {},
            ),
            const SizedBox(width: 6),
            _TopBarChip(
              icon: Icons.space_dashboard_outlined,
              label: _zh ? '桌面工作区' : 'Desktop workspace',
              compact: true,
            ),
            const SizedBox(width: 6),
            if (onLocaleChanged != null)
              _TopBarLanguageToggle(
                localeCode: localeCode,
                onLocaleChanged: onLocaleChanged!,
              ),
            const SizedBox(width: 6),
            if (isDark != null && onThemeChanged != null)
              _TopBarIconButton(
                icon: isDark!
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                label: isDark! ? (_zh ? '浅色' : 'Light') : (_zh ? '深色' : 'Dark'),
                onPressed: () =>
                    onThemeChanged!(isDark! ? ThemeMode.light : ThemeMode.dark),
              ),
            const SizedBox(width: 6),
            _DesktopWindowControlGroup(
              localeCode: localeCode,
              windowState: windowState,
              onWindowStateChanged: onWindowStateChanged,
            ),
          ],
        );
      },
    );
  }
}

class _DesktopWindowControlGroup extends StatelessWidget {
  const _DesktopWindowControlGroup({
    required this.localeCode,
    required this.windowState,
    required this.onWindowStateChanged,
  });

  final String localeCode;
  final _DesktopWindowPreviewState windowState;
  final ValueChanged<_DesktopWindowPreviewState> onWindowStateChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final maximizedPreview =
        windowState == _DesktopWindowPreviewState.maximized;
    return Row(
      key: const Key('desktop-window-controls'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowControlButton(
          keyName: 'window-control-minimize',
          icon: Icons.remove,
          tooltip: _zh
              ? '最小化，EXE 构建绑定真实窗口行为'
              : 'Minimize, bound to real window behavior in EXE',
          onTap: () =>
              onWindowStateChanged(_DesktopWindowPreviewState.minimized),
        ),
        _WindowControlButton(
          keyName: 'window-control-maximize',
          icon: maximizedPreview
              ? Icons.filter_none_outlined
              : Icons.crop_square_outlined,
          tooltip: maximizedPreview
              ? (_zh
                  ? '还原，Web 预览为视觉模拟'
                  : 'Restore, visual simulation in Web preview')
              : (_zh
                  ? '最大化，Web 预览为视觉模拟'
                  : 'Maximize, visual simulation in Web preview'),
          onTap: () => onWindowStateChanged(maximizedPreview
              ? _DesktopWindowPreviewState.restored
              : _DesktopWindowPreviewState.maximized),
        ),
        _WindowControlButton(
          keyName: 'window-control-close',
          icon: Icons.close,
          tooltip: _zh
              ? '关闭，EXE 构建绑定真实窗口行为'
              : 'Close, bound to real window behavior in EXE',
          danger: true,
          onTap: () => onWindowStateChanged(_DesktopWindowPreviewState.closed),
        ),
      ],
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
          final threeColumns = constraints.maxWidth >= 1180;
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
                _DashboardBlockers(
                  localeCode: localeCode,
                  workflowV2Evidence: workflowV2Evidence,
                  externalCapabilities: externalCapabilities,
                ),
              ],
            ),
            const SizedBox(height: _DesktopGrid.gutter),
            _DashboardCapabilityGaps(localeCode: localeCode),
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
    final metrics = [
      _DashboardMetricData(
        icon: Icons.inventory_2_outlined,
        label: _zh ? '知识库' : 'Knowledge Bases',
        value: '${contracts.navigation.views.length}',
        detail: _zh ? '契约视图可用' : 'contract views',
      ),
      _DashboardMetricData(
        icon: Icons.extension_outlined,
        label: _zh ? 'Skill' : 'Skills',
        value: '${contracts.templates.templates.length}',
        detail: _zh ? '模板登记' : 'templates registered',
      ),
      _DashboardMetricData(
        icon: Icons.task_alt_outlined,
        label: _zh ? '本地动作' : 'Local Actions',
        value:
            '${workflowV2Evidence.passedActionCount}/${workflowV2Evidence.executionTargetCount}',
        detail: _zh ? '已验证本地目标' : 'verified local targets',
      ),
      _DashboardMetricData(
        icon: Icons.document_scanner_outlined,
        label: _zh ? 'OCR / Parser' : 'OCR / Parser',
        value: parserBackends.backends.length.toString(),
        detail: _zh ? '后端证据登记' : 'backend evidence records',
      ),
      _DashboardMetricData(
        icon: Icons.verified_user_outlined,
        label: _zh ? 'Final Gate' : 'Final Gate',
        value: workflowV2Evidence.readyForV4RcCandidate
            ? (_zh ? '就绪' : 'Ready')
            : (_zh ? '阻塞' : 'Blocked'),
        detail: _zh ? '候选状态' : 'candidate state',
      ),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: metrics.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: _DesktopGrid.gutter,
          crossAxisSpacing: _DesktopGrid.gutter,
          mainAxisExtent: 150,
        ),
        itemBuilder: (context, index) => _DashboardMetricCard(metrics[index]),
      );
    });
  }
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

class _DashboardRecentTasks extends StatelessWidget {
  const _DashboardRecentTasks({required this.localeCode});

  final String localeCode;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return _FillProductPanel(
      keyName: 'dashboard-recent-tasks',
      icon: Icons.list_alt_outlined,
      title: _zh ? '最近任务' : 'Recent Tasks',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: _ProductTable(
                columns: _zh
                    ? ['任务', '类型', '状态', '耗时']
                    : ['Task', 'Type', 'Status', 'Duration'],
                rows: _zh
                    ? [
                        ['文档解析完成', '文档解析', '成功', '2m 18s'],
                        ['知识库构建', '知识库', '成功', '4m 07s'],
                        ['OCR 质量检查', 'OCR', '需复查', '11m 03s'],
                        ['UI Gate 记录', '审计', '已通过', '12m 11s'],
                      ]
                    : [
                        [
                          'Document parsing complete',
                          'Parsing',
                          'Passed',
                          '2m 18s'
                        ],
                        [
                          'Knowledge Base build',
                          'Knowledge',
                          'Passed',
                          '4m 07s'
                        ],
                        ['OCR quality check', 'OCR', 'Needs review', '11m 03s'],
                        ['UI Gate record', 'Audit', 'Passed', '12m 11s'],
                      ],
              ),
            ),
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
            label: _zh ? '工作区' : 'Workspace',
            value: workspace,
          ),
          _FieldRow(
            label: _zh ? '桌面目标' : 'Desktop target',
            value: isWebRuntime
                ? (_zh ? '当前为开发预览' : 'Development preview')
                : (_zh ? '桌面 EXE 目标' : 'Desktop EXE target'),
          ),
          _FieldRow(
            label: _zh ? '本地动作验证' : 'Local action validation',
            value:
                '${workflowV2Evidence.passedActionCount}/${workflowV2Evidence.executionTargetCount}',
          ),
          _FieldRow(
            label: _zh ? 'Parser 后端' : 'Parser backends',
            value: _zh
                ? '${parserBackends.backends.length} 个登记，${parserBackends.realRuntimeIntegratedCount} 个真实集成证据'
                : '${parserBackends.backends.length} registered, ${parserBackends.realRuntimeIntegratedCount} real integration evidence',
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
              ? ['报告', '状态', '证据来源', '边界']
              : ['Report', 'Status', 'Evidence', 'Boundary'],
          rows: _zh
              ? [
                  [
                    'Campaign 4 Acceptance Gate',
                    workflowV2Evidence.readyForV4RcCandidate ? '通过' : '阻塞',
                    '本地 Gate 证据',
                    '不代表 Release'
                  ],
                  [
                    'Parser / OCR 证据',
                    parserBackends.backends.isNotEmpty ? '可展示' : '待接入',
                    '后端矩阵',
                    '不执行外部 Provider'
                  ],
                  ['Agent Creation Package', '边界内', 'UI 映射/预览/导出', '不实现运行能力'],
                ]
              : [
                  [
                    'Campaign 4 Acceptance Gate',
                    workflowV2Evidence.readyForV4RcCandidate
                        ? 'Passed'
                        : 'Blocked',
                    'Local gate evidence',
                    'Not a Release'
                  ],
                  [
                    'Parser / OCR evidence',
                    parserBackends.backends.isNotEmpty
                        ? 'Displayable'
                        : 'Pending',
                    'Backend matrix',
                    'No external Provider execution'
                  ],
                  [
                    'Agent Creation Package',
                    'Within boundary',
                    'UI mapping / preview / export',
                    'No execution runtime'
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
              ? '所有数据默认仅保存在本地工作区；Provider Runtime 已通过真实 live smoke 复验，网络仍需显式授权。'
              : 'Data stays in the local workspace by default; Provider Runtime passed real live-smoke reacceptance, and network use still requires explicit approval.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _DisplayAction(
          label: _zh ? '查看 Provider 验收证据' : 'View Provider acceptance evidence',
          icon: Icons.verified_outlined,
        ),
      ],
    );
  }
}

class _DashboardBlockers extends StatelessWidget {
  const _DashboardBlockers({
    required this.localeCode,
    required this.workflowV2Evidence,
    required this.externalCapabilities,
  });

  final String localeCode;
  final P1WorkflowEvidence workflowV2Evidence;
  final ExternalCapabilityRegistry externalCapabilities;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final localBlockers = workflowV2Evidence.blockedActions.length;
    final externalPlanned = externalCapabilities.projects.length;
    return _ProductPanel(
      keyName: 'dashboard-blockers',
      icon: Icons.report_problem_outlined,
      title: _zh ? '阻塞项' : 'Blockers',
      gap: true,
      children: [
        _ProductTable(
          columns: _zh ? ['项目', '状态', '处理'] : ['Item', 'Status', 'Handling'],
          rows: _zh
              ? [
                  ['Secret 明文输入', '$localBlockers 个边界阻塞', '保持禁用'],
                  ['外部能力适配', '$externalPlanned 个登记项', '仅开发者诊断展示'],
                  ['后续战役能力', 'omitted', '当前隐藏，不作为可用入口'],
                ]
              : [
                  [
                    'Plaintext secret entry',
                    '$localBlockers blocked',
                    'Remain disabled'
                  ],
                  [
                    'External adapters',
                    '$externalPlanned registered',
                    'Diagnostics only'
                  ],
                  [
                    'Future campaign capabilities',
                    'omitted',
                    'Future campaigns'
                  ],
                ],
        ),
      ],
    );
  }
}

class _DashboardCapabilityGaps extends StatelessWidget {
  const _DashboardCapabilityGaps({required this.localeCode});

  final String localeCode;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'dashboard-capability-gaps',
      icon: Icons.warning_amber_outlined,
      title: _zh ? '能力缺口标记' : 'Capability Gap Marking',
      gap: true,
      children: [
        _ProductTable(
          columns:
              _zh ? ['能力', '当前标识', '后续归属'] : ['Capability', 'Mark', 'Owner'],
          rows: _zh
              ? [
                  ['Provider Runtime', 'enabled_real', 'live smoke accepted'],
                  ['外部事实验证', 'enabled_real', '实时外部来源比对已验收'],
                  [
                    'OCR / Parser / Chunking',
                    'enabled_real',
                    'Builtin + PaddleOCR OCR 路径已验收'
                  ],
                  ['Knowledge Quality Gate', 'enabled_real', '本地质量门禁已验收'],
                  ['Document Export', 'enabled_real', 'MD/DOCX/PDF/PPTX 已验收'],
                  ['Skill Governance', 'enabled_real', '治理报告已验收'],
                  ['Agent Creation Package', 'enabled_real', 'Package 导出已验收'],
                  ['Agent 创建/保存/版本', 'omitted', 'Campaign 6 Agent Foundation'],
                  ['Memory / 协作 / A2A', 'omitted', 'Post-9 Roadmap'],
                ]
              : [
                  ['Provider Runtime', 'enabled_real', 'live smoke accepted'],
                  [
                    'External fact verification',
                    'enabled_real',
                    'Live external source comparison accepted'
                  ],
                  [
                    'OCR / Parser / Chunking',
                    'enabled_real',
                    'Builtin + PaddleOCR OCR path accepted'
                  ],
                  [
                    'Knowledge Quality Gate',
                    'enabled_real',
                    'Local quality gate accepted'
                  ],
                  [
                    'Document Export',
                    'enabled_real',
                    'MD/DOCX/PDF/PPTX accepted'
                  ],
                  [
                    'Skill Governance',
                    'enabled_real',
                    'Governance report accepted'
                  ],
                  [
                    'Agent Creation Package',
                    'enabled_real',
                    'Package export accepted'
                  ],
                  [
                    'Agent create/save/version',
                    'omitted',
                    'Campaign 6 Agent Foundation'
                  ],
                  ['Memory / collaboration / A2A', 'omitted', 'Post-9 Roadmap'],
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

class _TopBarSearchField extends StatelessWidget {
  const _TopBarSearchField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('topbar-search-field'),
      constraints: const BoxConstraints(minWidth: 120),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 17, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      height: 1.16,
                    )),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Ctrl K',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
            ),
          ),
        ],
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
      if (constraints.maxWidth < 620) {
        return Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(height: _DesktopGrid.gutter),
              children[index],
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
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 520) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(height: 8),
              children[index],
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(child: children[index]),
          ],
        ],
      );
    });
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
    required this.isWebRuntime,
    required this.diagnostics,
  });

  final String localeCode;
  final WorkbenchPage page;
  final String workspace;
  final Map<String, dynamic> campaign6AgentRuntimeStatus;
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
      'workspace': 5,
    };
    final maxTab = (tabCounts[page] ?? 1) - 1;
    if (selectedTab > maxTab) selectedTab = 0;
    return _ProductWorkspaceFrame(
      key: Key('dense-page-workbench-${widget.page.id}'),
      child: switch (page) {
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
            diagnostics: widget.diagnostics,
          ),
      },
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
                  const _CapabilityGapMarker(compact: true),
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
    this.subtitle,
    this.keyName,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final String? subtitle;
  final String? keyName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: keyName == null ? null : Key(keyName!),
      width: double.infinity,
      height: double.infinity,
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        )),
              ),
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
          const SizedBox(height: _DesktopGrid.gutter),
          Expanded(child: child),
        ],
      ),
    );
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
        return Column(
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
      }
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth,
            maxWidth: columns.length >= 6
                ? constraints.maxWidth + 260
                : double.infinity,
          ),
          child: DataTable(
            headingRowHeight: 34,
            dataRowMinHeight: 42,
            dataRowMaxHeight: 46,
            columnSpacing: 26,
            horizontalMargin: 10,
            headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
            dataTextStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.16,
                ),
            columns: [
              for (final column in columns) DataColumn(label: Text(column))
            ],
            rows: [
              for (final row in rows)
                DataRow(cells: [
                  for (final value in row)
                    DataCell(_CapabilityTableCell(value: value)),
                ]),
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
    if (_isCapabilityGapText(value)) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _CapabilityGapMarker(label: value),
      );
    }
    return Tooltip(
      message: value,
      waitDuration: const Duration(milliseconds: 500),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }
}

class _CapabilityGapMarker extends StatelessWidget {
  const _CapabilityGapMarker({
    this.label,
    this.compact = false,
  });

  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = Colors.amber.shade700;
    final text = _capabilityGapLabel(
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
          Icon(Icons.warning_amber_outlined,
              size: compact ? 13 : 14, color: color),
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

bool _isCapabilityGapText(String value) {
  final lower = value.toLowerCase();
  return lower.contains('disabled_boundary') ||
      lower.contains('display_only') ||
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
      value.contains('禁用');
}

String _capabilityGapLabel(String? value, bool zh) {
  if (value == null) {
    return zh ? '待补齐' : 'Needs work';
  }
  final lower = value.toLowerCase();
  if (lower.contains('enabled_real')) {
    return zh ? '可用' : 'Available';
  }
  if (lower.contains('display_only') ||
      lower.contains('preview only') ||
      lower.contains('read-only') ||
      value.contains('只读')) {
    return zh ? '只读预览' : 'Preview only';
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
    return zh ? '待接入' : 'Pending';
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
  final VoidCallback onPressed;
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
      final columns = constraints.maxWidth >= 540
          ? items.length
          : constraints.maxWidth >= 460
              ? 3
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

  bool get _zh => widget.localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final hasSources = stagedSources > 0;
    final hasManifest = preparedManifests > 0;
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
                ? (_zh ? '开发预览' : 'Development preview')
                : (_zh ? '桌面输入' : 'Desktop input'),
            icon: Icons.shield_outlined,
          ),
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _MetricStrip(
          items: [
            _MetricDatum(
                label: _zh ? '排队文件' : 'Queued files',
                value: hasSources ? '8' : '0',
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
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;
          final intake = _ProductPanel(
            keyName: 'import-intake-surface',
            accent: true,
            icon: Icons.folder_open_outlined,
            title: _zh ? '来源入口' : 'Source Intake',
            minHeight: 410,
            subtitle: _zh
                ? '网页链接导入生成来源证据；外部事实验证需显式网络 opt-in。'
                : 'Web-link import creates source evidence; external verification requires explicit network opt-in.',
            children: [
              _ProductTable(
                columns: _zh
                    ? ['入口', '范围', '动作分类', '边界']
                    : ['Input', 'Scope', 'Action class', 'Boundary'],
                rows: _zh
                    ? [
                        [
                          '文件',
                          'PDF/DOCX/PPTX/XLSX/MD/TXT/CSV',
                          'enabled_real',
                          '本地路径由桌面端承接'
                        ],
                        ['文件夹', '批量来源清单', 'enabled_real', '按工作区导入'],
                        [
                          '网页链接',
                          '单个公开 URL',
                          'enabled_real',
                          '公开网页来源抓取与外部验证已验收'
                        ],
                      ]
                    : [
                        [
                          'Files',
                          'PDF/DOCX/PPTX/XLSX/MD/TXT/CSV',
                          'enabled_real',
                          'Desktop path owned by EXE'
                        ],
                        [
                          'Folder',
                          'Batch source inventory',
                          'enabled_real',
                          'Workspace import'
                        ],
                        [
                          'Web link',
                          'Single public URL',
                          'enabled_real',
                          'Public web source fetch and verification accepted'
                        ],
                      ],
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              _EqualActionRow(children: [
                _PrimaryProductAction(
                  label: _zh ? '加入本地示例来源' : 'Stage local sample source',
                  icon: Icons.add_to_drive_outlined,
                  onPressed: () => setState(() => stagedSources++),
                ),
                _DisplayAction(
                  label: _zh ? '加入网页链接示例' : 'Stage web-link sample',
                  icon: Icons.link_outlined,
                  onPressed: () => setState(() => stagedSources++),
                ),
                _DisabledAction(
                  label: _zh ? '打开真实文件选择器' : 'Open real file picker',
                  reason:
                      _zh ? '需要桌面端真实路径能力。' : 'Requires a real desktop path.',
                  icon: Icons.folder_open_outlined,
                ),
              ]),
              const SizedBox(height: _DesktopGrid.gutter),
              _MiniProgressBar(value: hasManifest ? 0.68 : 0.12),
              const SizedBox(height: 8),
              _PrimaryProductAction(
                label: _zh ? '生成导入清单预览' : 'Prepare import manifest preview',
                onPressed: () => setState(() {
                  if (stagedSources == 0) stagedSources = 1;
                  preparedManifests++;
                }),
                icon: Icons.add_to_drive_outlined,
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
                          hasSources ? '产品手册 v2.3.pdf' : '等待本地文件',
                          '文件',
                          hasManifest ? '100%' : '0%',
                          hasSources ? '已暂存' : '待输入',
                          hasManifest ? '无需恢复' : '待生成清单',
                          'source_manifest.json'
                        ],
                        [
                          hasSources ? '合同扫描件_03.jpg' : '等待 OCR 文件',
                          '图片 / OCR',
                          hasManifest ? '72%' : '0%',
                          hasManifest ? '解析中' : '待输入',
                          hasManifest ? '可重试 OCR' : '待选择 OCR',
                          'parse_report.json'
                        ],
                        [
                          hasSources ? '公开网页链接' : '等待网页链接',
                          '网页链接',
                          hasManifest ? '已记录' : '0%',
                          hasManifest ? '来源边界已登记' : '待输入',
                          '联网许可必需',
                          'source_evidence.json'
                        ],
                      ]
                    : [
                        [
                          hasSources
                              ? 'product-manual-v2.3.pdf'
                              : 'Waiting for local files',
                          'File',
                          hasManifest ? '100%' : '0%',
                          hasSources ? 'Staged' : 'Pending',
                          hasManifest ? 'No recovery' : 'Prepare manifest',
                          'source_manifest.json'
                        ],
                        [
                          hasSources
                              ? 'contract-scan-03.jpg'
                              : 'Waiting for OCR file',
                          'Image / OCR',
                          hasManifest ? '72%' : '0%',
                          hasManifest ? 'Parsing' : 'Pending',
                          hasManifest ? 'OCR retry available' : 'Choose OCR',
                          'parse_report.json'
                        ],
                        [
                          hasSources
                              ? 'Public web link'
                              : 'Waiting for web URL',
                          'Web page URL',
                          hasManifest ? 'Recorded' : '0%',
                          hasManifest ? 'Source boundary recorded' : 'Pending',
                          'Network consent required',
                          'source_evidence.json'
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
            subtitle: '${widget.workspace}/workbench_runs/import_manifest',
            minHeight: 326,
            children: [
              _ProductTable(
                columns:
                    _zh ? ['记录', '状态', '证据'] : ['Record', 'Status', 'Evidence'],
                rows: _zh
                    ? [
                        [
                          'source_manifest.json',
                          hasManifest ? '已准备' : '等待',
                          '来源清单'
                        ],
                        [
                          'parse_report.json',
                          hasManifest ? '解析中' : '等待',
                          '解析报告'
                        ],
                        [
                          'recovery_queue.json',
                          hasManifest ? '2 个候选' : '空',
                          '失败恢复'
                        ],
                        ['下一阶段', '文档库', '来源文档管理'],
                      ]
                    : [
                        [
                          'source_manifest.json',
                          hasManifest ? 'Ready' : 'Waiting',
                          'Source inventory'
                        ],
                        [
                          'parse_report.json',
                          hasManifest ? 'Parsing' : 'Waiting',
                          'Parsing report'
                        ],
                        [
                          'recovery_queue.json',
                          hasManifest ? '2 candidates' : 'Empty',
                          'Recovery'
                        ],
                        [
                          'Next stage',
                          'Document Library',
                          'Source document management'
                        ],
                      ],
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
                  ['向量库 Provider', 'disabled_boundary', '外部向量库仍未接入'],
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
                    'Disabled boundary',
                    'External vector DB still not connected'
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
  bool draftQueued = true;
  bool previewReady = true;

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final extraWide = constraints.maxWidth >= 1180;
      final tasks = _ProductPanel(
        keyName: 'document-generation-tasks',
        icon: Icons.post_add_outlined,
        title: zh ? '生成队列' : 'Generation Queue',
        minHeight: 366,
        children: [
          _FillPanelColumn(
            height: 276,
            top: _LocalScrollBox(
              child: _ProductTable(
                columns: zh
                    ? ['任务', '知识库', '模板', '优先级', '状态']
                    : [
                        'Task',
                        'Knowledge Base',
                        'Template',
                        'Priority',
                        'Status'
                      ],
                rows: zh
                    ? [
                        [
                          '行业分析报告',
                          '企业知识库',
                          '报告模板',
                          'P1',
                          draftQueued ? '已排队' : '待选择',
                        ],
                        [
                          '产品手册更新',
                          '产品知识库',
                          '手册模板',
                          'P2',
                          previewReady ? '预览可用' : '待生成',
                        ],
                        ['PPTX 教学材料', '培训知识库', '教学模板', 'P3', '可排队'],
                      ]
                    : [
                        [
                          'Industry analysis report',
                          'Enterprise KB',
                          'Report template',
                          'P1',
                          draftQueued ? 'Queued' : 'Pending selection',
                        ],
                        [
                          'Product manual update',
                          'Product Knowledge Base',
                          'Manual template',
                          'P2',
                          previewReady ? 'Preview ready' : 'Pending generation',
                        ],
                        [
                          'PPTX teaching material',
                          'Training Knowledge Base',
                          'Teaching template',
                          'P3',
                          'Queueable'
                        ],
                      ],
              ),
            ),
            bottom: _EqualActionRow(children: [
              _PrimaryProductAction(
                label: zh ? '排队生成任务' : 'Queue generation task',
                icon: Icons.playlist_add_outlined,
                onPressed: () => setState(() => draftQueued = true),
              ),
              _DisplayAction(
                label: zh ? '生成文档预览' : 'Prepare document preview',
                icon: Icons.preview_outlined,
                onPressed: () => setState(() {
                  draftQueued = true;
                  previewReady = true;
                }),
              ),
            ]),
          ),
        ],
      );
      final preview = _ProductPanel(
        keyName: 'document-live-preview',
        icon: Icons.article_outlined,
        title: zh ? '中央文档预览' : 'Central Document Preview',
        minHeight: 366,
        children: [
          _DocumentPreviewPanel(zh: zh, ready: previewReady),
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
                    ['输出格式', 'Markdown / DOCX / PDF / PPTX', 'enabled_real'],
                    ['证据引用', '包含引用与页码', 'enabled_real'],
                    ['排序', '优先级 + 更新时间', 'enabled_real'],
                    ['暂停 / 重试 / 取消', '队列操作', 'enabled_real'],
                  ]
                : [
                    ['Output', 'Markdown / DOCX / PDF / PPTX', 'enabled_real'],
                    [
                      'Citations',
                      'References and pages included',
                      'enabled_real'
                    ],
                    ['Sort', 'Priority + updated time', 'enabled_real'],
                    [
                      'Pause / retry / cancel',
                      'Queue operations',
                      'enabled_real'
                    ],
                  ],
          ),
        ),
      );
      final validation = _ProductPanel(
        icon: Icons.rule_outlined,
        title: zh ? '验证与导出边界' : 'Validation and Export Boundary',
        gap: true,
        minHeight: 198,
        children: [
          _ProductTable(
            columns: zh ? ['项目', '当前结果', '说明'] : ['Item', 'Result', 'Note'],
            rows: zh
                ? [
                    ['结构完整性', '通过预览', '基于本地证据'],
                    ['引用覆盖', '128 / 128', '页码与来源保留'],
                    ['PDF / PPTX 渲染', '已生成', '导出验证报告已归档'],
                  ]
                : [
                    ['Structure', 'Preview passed', 'Local evidence'],
                    [
                      'Citation coverage',
                      '128 / 128',
                      'Pages and sources kept'
                    ],
                    [
                      'PDF / PPTX render',
                      'Generated',
                      'Export validation archived'
                    ],
                  ],
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
                value: '可用',
                detail: zh ? '结构导出' : 'structured',
                icon: Icons.notes_outlined),
            _MetricDatum(
                label: 'DOCX',
                value: '可用',
                detail: zh ? '引用检查' : 'citations',
                icon: Icons.description_outlined),
            _MetricDatum(
                label: 'PDF/PPTX',
                value: zh ? '可用' : 'Ready',
                detail: zh ? '已生成' : 'generated',
                icon: Icons.picture_as_pdf_outlined),
            _MetricDatum(
                label: zh ? '表格' : 'Table',
                value: zh ? '可用' : 'Ready',
                detail: zh ? '结构化输出' : 'structured',
                icon: Icons.table_chart_outlined),
            _MetricDatum(
                label: zh ? '思维导图' : 'Mind Map',
                value: zh ? '待验' : 'Pending',
                detail: zh ? '黄色边界' : 'yellow boundary',
                icon: Icons.account_tree_outlined),
          ],
        ),
      );
      if (!wide) {
        return Column(children: [
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
      final wide = constraints.maxWidth >= 900;
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
                    ['自定义模板', '多格式', '用户变量', 'display_only'],
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
                      'display_only'
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
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final export = _ProductPanel(
        keyName: 'document-export-preview',
        icon: Icons.file_download_outlined,
        title: zh ? '文档导出预览' : 'Document Export Preview',
        subtitle: '${widget.workspace}/workbench_runs/document_generation',
        children: [
          _ProductTable(
            columns: zh
                ? ['格式', '状态', '验证', '分类']
                : ['Format', 'Status', 'Validation', 'Class'],
            rows: zh
                ? [
                    [
                      'Markdown',
                      exportPreviewReady ? '预览已准备' : '等待草稿',
                      '结构检查',
                      'enabled_real'
                    ],
                    [
                      'DOCX',
                      exportPreviewReady ? '等待完整性检查' : '等待草稿',
                      '引用完整性',
                      'enabled_real'
                    ],
                    [
                      'PDF',
                      exportPreviewReady ? '等待渲染检查' : '等待草稿',
                      '导出验证',
                      'enabled_real'
                    ],
                    [
                      'PPTX',
                      exportPreviewReady ? '等待渲染检查' : '等待草稿',
                      '导出验证',
                      'enabled_real'
                    ],
                  ]
                : [
                    [
                      'Markdown',
                      exportPreviewReady
                          ? 'Preview ready'
                          : 'Waiting for draft',
                      'Structure check',
                      'enabled_real'
                    ],
                    [
                      'DOCX',
                      exportPreviewReady
                          ? 'Integrity pending'
                          : 'Waiting for draft',
                      'Citation integrity',
                      'enabled_real'
                    ],
                    [
                      'PDF',
                      exportPreviewReady
                          ? 'Render check pending'
                          : 'Waiting for draft',
                      'Export validation',
                      'enabled_real'
                    ],
                    [
                      'PPTX',
                      exportPreviewReady
                          ? 'Render check pending'
                          : 'Waiting for draft',
                      'Export validation',
                      'enabled_real'
                    ],
                  ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _PrimaryProductAction(
            label: zh ? '准备导出预览' : 'Prepare export preview',
            icon: Icons.file_download_outlined,
            onPressed: () => setState(() => exportPreviewReady = true),
          ),
        ],
      );
      final checks = _ProductPanel(
        icon: Icons.verified_outlined,
        title: zh ? '文档验证' : 'Document Validation',
        children: [
          _FieldRow(
              label: zh ? '内容完整性' : 'Completeness',
              value: exportPreviewReady
                  ? (zh ? '通过预览' : 'Preview passed')
                  : (zh ? '等待导出' : 'Waiting')),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '引用有效性' : 'Citation validity',
              value: exportPreviewReady ? '128 / 128' : '-'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '敏感信息检查' : 'Sensitive content',
              value: zh ? '本地检查，不联网' : 'Local check, no network'),
        ],
      );
      if (!wide) {
        return Column(children: [
          export,
          const SizedBox(height: _DesktopGrid.gutter),
          checks
        ]);
      }
      return _EqualHeightRow(
        height: 342,
        flexes: const [7, 4],
        children: [export, checks],
      );
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
  bool packageDraftBuilt = false;
  bool qualityReportPrepared = false;

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final list = _FillProductPanel(
        keyName: 'knowledge-package-list',
        icon: Icons.storage_outlined,
        title: zh ? '知识库列表' : 'Knowledge Base List',
        child: _FillPanelColumn(
          top: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EqualActionRow(children: [
                _PrimaryProductAction(
                  label: zh ? '新建知识库草稿' : 'New base draft',
                  icon: Icons.add_outlined,
                  onPressed: () => setState(() => packageDraftBuilt = true),
                ),
                _DisplayAction(
                  label: zh ? '导入解析产物' : 'Import parsed artifacts',
                  icon: Icons.file_upload_outlined,
                  onPressed: () => setState(() => packageDraftBuilt = true),
                ),
                _DisplayAction(
                  label: zh ? '筛选 / 排序 / 分页' : 'Filter / sort / paginate',
                  icon: Icons.filter_alt_outlined,
                  onPressed: () {},
                ),
              ]),
              const SizedBox(height: _DesktopGrid.gutter),
              Expanded(
                child: _BoundedScrollRegion(
                  child: _LocalScrollBox(
                    child: _ProductTable(
                      columns: zh
                          ? ['名称', '版本', '来源', 'chunks', '质量', '发布状态', '验证']
                          : [
                              'Name',
                              'Version',
                              'Source',
                              'chunks',
                              'Quality',
                              'Publish',
                              'Validation'
                            ],
                      rows: zh
                          ? [
                              [
                                packageDraftBuilt ? 'HeiTang 产品手册' : '等待构建的知识库',
                                'v2.3.0',
                                '文档库 / 本地文件',
                                packageDraftBuilt ? '18,742' : '0',
                                qualityReportPrepared ? '92.4' : '等待评分',
                                packageDraftBuilt ? '已发布' : '草稿',
                                qualityReportPrepared ? '通过' : '待验证'
                              ],
                              [
                                '企业制度知识库',
                                'v1.5.0',
                                '合同 / 制度文档',
                                packageDraftBuilt ? '41,209' : '0',
                                qualityReportPrepared ? '88.1' : '未评分',
                                '需复核',
                                'review_required'
                              ],
                              [
                                'API 参考文档',
                                'v1.1.0',
                                'Markdown / HTML',
                                packageDraftBuilt ? '7,884' : '0',
                                qualityReportPrepared ? '91.0' : '未评分',
                                '已发布',
                                '通过'
                              ],
                            ]
                          : [
                              [
                                packageDraftBuilt
                                    ? 'HeiTang product manual'
                                    : 'Base waiting for build',
                                'v2.3.0',
                                'Library / local files',
                                packageDraftBuilt ? '18,742' : '0',
                                qualityReportPrepared
                                    ? '82 / 100'
                                    : 'Waiting score',
                                packageDraftBuilt ? 'Published' : 'Draft',
                                qualityReportPrepared ? 'Passed' : 'Pending'
                              ],
                              [
                                'Enterprise policy base',
                                'v1.5.0',
                                'Contracts / policies',
                                packageDraftBuilt ? '41,209' : '0',
                                qualityReportPrepared ? '88.1' : 'Unscored',
                                'Needs review',
                                'review_required'
                              ],
                              [
                                'API reference docs',
                                'v1.1.0',
                                'Markdown / HTML',
                                packageDraftBuilt ? '7,884' : '0',
                                qualityReportPrepared ? '91.0' : 'Unscored',
                                'Published',
                                'Passed'
                              ],
                            ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottom: _BoundedScrollRegion(
            child: _MetricStrip(
              items: [
                _MetricDatum(
                    label: zh ? '来源文档' : 'Sources',
                    value: packageDraftBuilt ? '3' : '0',
                    detail: zh ? '已登记' : 'registered',
                    icon: Icons.article_outlined),
                _MetricDatum(
                    label: 'chunks',
                    value: packageDraftBuilt ? '67,835' : '0',
                    detail: zh ? '本地索引' : 'local index',
                    icon: Icons.segment_outlined),
                _MetricDatum(
                    label: zh ? '变更记录' : 'Changes',
                    value: packageDraftBuilt ? '12' : '0',
                    detail: zh ? '可追踪' : 'traceable',
                    icon: Icons.history_outlined),
              ],
            ),
          ),
        ),
      );
      final detail = _FillProductPanel(
        keyName: 'selected-package-detail',
        icon: Icons.fact_check_outlined,
        title: zh ? '知识库详情抽屉' : 'Knowledge Base Detail Drawer',
        subtitle: '${widget.workspace}/workbench_runs/knowledge_package',
        child: _LocalScrollBox(
          child: Column(
            children: [
              _MetricStrip(
                items: [
                  _MetricDatum(
                      label: zh ? '质量分' : 'Quality',
                      value: qualityReportPrepared ? '92.4' : '-',
                      detail: '/100',
                      icon: Icons.verified_outlined),
                  _MetricDatum(
                      label: zh ? '版本' : 'Version',
                      value: packageDraftBuilt ? 'v2.3' : (zh ? '草稿' : 'Draft'),
                      detail: zh ? '可追踪' : 'traceable',
                      icon: Icons.history_outlined),
                ],
              ),
              const SizedBox(height: _DesktopGrid.gutter),
              _EqualFieldGrid(
                columns: 2,
                children: [
                  _FieldRow(
                      label: zh ? '版本状态' : 'Version state',
                      value: packageDraftBuilt ? 'draft-preview' : 'draft'),
                  _FieldRow(
                      label: zh ? '质量门禁' : 'Quality gate',
                      value: qualityReportPrepared
                          ? (zh ? '预览报告已生成' : 'Preview report prepared')
                          : (zh ? '等待真实结果' : 'Waiting for real result')),
                ],
              ),
              const SizedBox(height: 8),
              _EqualFieldGrid(
                columns: 2,
                children: [
                  _FieldRow(
                      label: zh ? '上游承接物' : 'Upstream input',
                      value: zh
                          ? '解析内容 / 解析报告 / 恢复信息'
                          : 'Parsed content / parsing report / recovery info'),
                  _FieldRow(
                      label: zh ? '下游交接' : 'Downstream handoff',
                      value: zh
                          ? 'Skill 草稿生成配置'
                          : 'Skill draft generation config'),
                ],
              ),
              const SizedBox(height: 8),
              _FieldRow(
                  label: zh ? '版本链' : 'Version chain',
                  value: zh
                      ? 'v2.1 -> v2.2 -> v2.3 草稿'
                      : 'v2.1 -> v2.2 -> v2.3 draft'),
              const SizedBox(height: 8),
              _ProductTable(
                columns: zh
                    ? ['构建记录', '状态', '证据']
                    : ['Build record', 'Status', 'Evidence'],
                rows: zh
                    ? [
                        [
                          'source sync',
                          packageDraftBuilt ? '完成' : '等待',
                          'source_manifest'
                        ],
                        [
                          'chunk build',
                          packageDraftBuilt ? '完成' : '等待',
                          'parse_report'
                        ],
                        [
                          'quality gate',
                          qualityReportPrepared ? '通过' : '等待',
                          'quality_report'
                        ],
                      ]
                    : [
                        [
                          'source sync',
                          packageDraftBuilt ? 'Done' : 'Waiting',
                          'source_manifest'
                        ],
                        [
                          'chunk build',
                          packageDraftBuilt ? 'Done' : 'Waiting',
                          'parse_report'
                        ],
                        [
                          'quality gate',
                          qualityReportPrepared ? 'Passed' : 'Waiting',
                          'quality_report'
                        ],
                      ],
              ),
              const SizedBox(height: 8),
              _EqualActionRow(children: [
                _PrimaryProductAction(
                  label:
                      zh ? '构建知识库草稿预览' : 'Build Knowledge Base draft preview',
                  icon: Icons.build_outlined,
                  onPressed: () => setState(() => packageDraftBuilt = true),
                ),
                _DisplayAction(
                  label: zh ? '生成质量报告预览' : 'Prepare quality report preview',
                  icon: Icons.rule_outlined,
                  onPressed: () => setState(() {
                    packageDraftBuilt = true;
                    qualityReportPrepared = true;
                  }),
                ),
              ]),
            ],
          ),
        ),
      );
      if (!wide) {
        return Column(children: [
          list,
          const SizedBox(height: _DesktopGrid.gutter),
          detail
        ]);
      }
      return _EqualHeightRow(
        height: 656,
        flexes: const [7, 5],
        children: [list, detail],
      );
    });
  }
}

class _KnowledgeVectorIndexView extends StatelessWidget {
  const _KnowledgeVectorIndexView({required this.zh});

  final bool zh;

  @override
  Widget build(BuildContext context) {
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
                      'heitang_prod',
                      '产品手册',
                      'text-embedding-3-large',
                      '3072',
                      '成功',
                      'enabled_real'
                    ],
                    [
                      'policy_internal',
                      '企业制度',
                      'bge-m3',
                      '1024',
                      '需重建',
                      'enabled_real'
                    ],
                    [
                      'web_sources',
                      '网页来源',
                      '未配置',
                      '-',
                      '等待 Gate',
                      'disabled_boundary'
                    ],
                  ]
                : [
                    [
                      'heitang_prod',
                      'Product manual',
                      'text-embedding-3-large',
                      '3072',
                      'Success',
                      'enabled_real'
                    ],
                    [
                      'policy_internal',
                      'Enterprise policy',
                      'bge-m3',
                      '1024',
                      'Rebuild needed',
                      'enabled_real'
                    ],
                    [
                      'web_sources',
                      'Web sources',
                      'Not configured',
                      '-',
                      'Waiting Gate',
                      'disabled_boundary'
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
          _DisabledAction(
              label:
                  zh ? '连接外部向量库 Provider' : 'Connect external vector provider',
              reason: zh
                  ? '外部向量库 Provider 尚未接入。'
                  : 'External vector DB provider is not connected.',
              icon: Icons.lock_outline),
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
                  value: '92.7%',
                  detail: zh ? '本地证据' : 'local evidence',
                  icon: Icons.track_changes_outlined),
              _MetricDatum(
                  label: zh ? '覆盖率' : 'Coverage',
                  value: '87.4%',
                  detail: zh ? '来源覆盖' : 'source coverage',
                  icon: Icons.pie_chart_outline),
              _MetricDatum(
                  label: zh ? '冲突' : 'Conflicts',
                  value: '1',
                  detail: zh ? '待复核' : 'review',
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
                    ['解析完整性', '通过', 'parse_report.json', '保持'],
                    ['重复片段', '通过', 'quality_report.json', '已生成建议'],
                    [
                      '时效性',
                      'review_required',
                      'freshness_check_report.json',
                      '保留复核标记'
                    ],
                    [
                      '矛盾检测',
                      'review_required',
                      'contradiction_map.json',
                      '不静默通过'
                    ],
                  ]
                : [
                    ['Parse integrity', 'Passed', 'parse_report.json', 'Keep'],
                    [
                      'Duplicate chunks',
                      'Passed',
                      'quality_report.json',
                      'Suggestions generated'
                    ],
                    [
                      'Freshness',
                      'review_required',
                      'freshness_check_report.json',
                      'Keep review marker'
                    ],
                    [
                      'Contradiction',
                      'review_required',
                      'contradiction_map.json',
                      'Do not silently pass'
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
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
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
                      rows: zh
                          ? [
                              [
                                indexed ? '产品手册 v2.3.pdf' : '等待导入文档',
                                '产品',
                                '本地文件',
                                indexed ? '已解析' : '未开始',
                                'v2.3',
                                indexed ? '18' : '0'
                              ],
                              [
                                '合同评审样例.docx',
                                '合规',
                                '本地文件',
                                indexed ? '可查看' : '待生成',
                                'v1.4',
                                indexed ? '9' : '0'
                              ],
                              [
                                '公开政策网页',
                                '网页链接',
                                'URL 来源',
                                indexed ? '来源已登记' : '待登记',
                                'snapshot',
                                indexed ? '3' : '0'
                              ],
                              [
                                '知识库验证报告草稿.md',
                                '报告',
                                '生成产物',
                                indexed ? '可预览' : '待生成',
                                'draft',
                                indexed ? '12' : '0'
                              ],
                            ]
                          : [
                              [
                                indexed
                                    ? 'product-manual-v2.3.pdf'
                                    : 'Waiting for documents',
                                'Product',
                                'Local file',
                                indexed ? 'Parsed' : 'Not started',
                                'v2.3',
                                indexed ? '18' : '0'
                              ],
                              [
                                'contract-review-sample.docx',
                                'Compliance',
                                'Local file',
                                indexed ? 'Viewable' : 'Pending generation',
                                'v1.4',
                                indexed ? '9' : '0'
                              ],
                              [
                                'Public policy page',
                                'Web link',
                                'URL source',
                                indexed ? 'Source recorded' : 'Pending',
                                'snapshot',
                                indexed ? '3' : '0'
                              ],
                              [
                                'kb-validation-draft.md',
                                'Report',
                                'Generated artifact',
                                indexed ? 'Previewable' : 'Pending',
                                'draft',
                                indexed ? '12' : '0'
                              ],
                            ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottom: _PrimaryProductAction(
            label: zh ? '刷新文档索引预览' : 'Refresh document index preview',
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
                      value: indexed ? '32' : '-',
                      detail: zh ? '可预览' : 'preview',
                      icon: Icons.menu_book_outlined),
                  _MetricDatum(
                      label: 'chunks',
                      value: indexed ? '18' : '0',
                      detail: zh ? '已切分' : 'split',
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
                            value: indexed
                                ? (zh
                                    ? '来源、类型、页数、时间戳可查看'
                                    : 'Source, type, pages, and timestamp visible')
                                : (zh ? '等待真实文件' : 'Waiting for real file')),
                        _FieldRow(
                            label: zh ? '解析摘要' : 'Parse summary',
                            value: indexed
                                ? (zh
                                    ? '18 个 chunks，0 个阻塞项，2 个待确认项'
                                    : '18 chunks, 0 blockers, 2 review items')
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
          docs,
          const SizedBox(height: _DesktopGrid.gutter),
          preview,
          const SizedBox(height: _DesktopGrid.gutter),
          detail
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
  bool retrievalPrepared = true;

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final extraWide = constraints.maxWidth >= 1180;
      final query = _ProductPanel(
        keyName: 'retrieval-workflow',
        icon: Icons.manage_search_outlined,
        title: zh ? '查询控制台' : 'Query Console',
        minHeight: 430,
        subtitle: zh
            ? '查询改写、检索规划、证据选择、重排和本地证据验证。'
            : 'Query rewrite, retrieval planning, evidence selection, rerank, and local evidence validation.',
        children: [
          _FieldRow(
              label: zh ? '查询' : 'Query',
              value: retrievalPrepared
                  ? (zh
                      ? '示例问题：资料中的关键决策是什么？'
                      : 'Sample query: what decisions are in the material?')
                  : (zh ? '等待输入' : 'Waiting for input')),
          const SizedBox(height: 8),
          _WorkflowSteps(
            steps: zh
                ? ['查询改写', '检索规划', '混合检索', '重排', '证据验证']
                : ['Rewrite', 'Planning', 'Hybrid', 'Rerank', 'Verify'],
            activeIndex: retrievalPrepared ? 4 : 2,
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _ProductTable(
            columns: zh
                ? ['证据', '来源', '评分', '选择', '验证']
                : ['Evidence', 'Source', 'Score', 'Selected', 'Validation'],
            rows: zh
                ? [
                    [
                      retrievalPrepared ? '新能源汽车补贴政策通知' : '等待检索结果',
                      '政策文件',
                      retrievalPrepared ? '0.88' : '-',
                      retrievalPrepared ? '已选' : '未搜索',
                      retrievalPrepared ? '本地证据' : '未验证'
                    ],
                    [
                      retrievalPrepared ? '地方消费实施方案' : '证据选择',
                      '地方政策',
                      retrievalPrepared ? '0.76' : '-',
                      retrievalPrepared ? '待确认' : '未验证',
                      retrievalPrepared ? '需人工复核' : '未验证'
                    ],
                    [
                      retrievalPrepared ? '产业发展报告' : '重排候选',
                      '报告',
                      retrievalPrepared ? '0.62' : '-',
                      retrievalPrepared ? '未选' : '未验证',
                      retrievalPrepared ? '覆盖不足' : '未验证'
                    ],
                  ]
                : [
                    [
                      retrievalPrepared
                          ? 'New energy subsidy policy notice'
                          : 'Waiting for retrieval result',
                      'Policy file',
                      retrievalPrepared ? '0.88' : '-',
                      retrievalPrepared ? 'Selected' : 'Not searched',
                      retrievalPrepared ? 'Local evidence' : 'Not validated'
                    ],
                    [
                      retrievalPrepared
                          ? 'Local consumption plan'
                          : 'Evidence selection',
                      'Local policy',
                      retrievalPrepared ? '0.76' : '-',
                      retrievalPrepared
                          ? 'Needs human confirmation'
                          : 'Not validated',
                      retrievalPrepared ? 'Review required' : 'Not validated'
                    ],
                    [
                      retrievalPrepared
                          ? 'Industry report'
                          : 'Rerank candidate',
                      'Report',
                      retrievalPrepared ? '0.62' : '-',
                      retrievalPrepared ? 'Not selected' : 'Not validated',
                      retrievalPrepared ? 'Coverage low' : 'Not validated'
                    ],
                  ],
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
                  value: retrievalPrepared ? '92.7%' : '-',
                  detail: zh ? '本地证据' : 'local',
                  icon: Icons.verified_outlined),
              _MetricDatum(
                  label: zh ? '忠实度' : 'Faithfulness',
                  value: retrievalPrepared ? '0.93' : '-',
                  detail: zh ? '引用一致' : 'cited',
                  icon: Icons.link_outlined),
              _MetricDatum(
                  label: zh ? '覆盖率' : 'Coverage',
                  value: retrievalPrepared ? '87.4%' : '-',
                  detail: zh ? '来源覆盖' : 'covered',
                  icon: Icons.pie_chart_outline),
              _MetricDatum(
                  label: zh ? '矛盾项' : 'Contradictions',
                  value: retrievalPrepared ? '0' : '-',
                  detail: zh ? '本地检查' : 'local',
                  icon: Icons.warning_amber_outlined),
            ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _EqualActionRow(children: [
            _PrimaryProductAction(
              label: zh ? '运行检索验证预览' : 'Run retrieval verification preview',
              onPressed: () => setState(() => retrievalPrepared = true),
              icon: Icons.play_arrow_outlined,
            ),
            _DisplayAction(
                label: zh ? '执行外部事实验证' : 'Run external fact checking',
                icon: Icons.public_off_outlined),
          ]),
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
                      '外部比对可 opt-in 执行'
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
                      'External comparison can run with opt-in'
                    ],
                  ],
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          query,
          const SizedBox(height: _DesktopGrid.gutter),
          reasoning,
          const SizedBox(height: _DesktopGrid.gutter),
          metrics
        ]);
      }
      if (extraWide) {
        return Column(children: [
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

class _RetrievalVerificationProductWorkflow extends StatelessWidget {
  const _RetrievalVerificationProductWorkflow({required this.localeCode});

  final String localeCode;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.manage_search_outlined,
        title: _zh ? '检索与验证' : 'Retrieval & Verification',
        description: _zh
            ? '查询改写、检索规划、证据选择、重排、本地证据验证与已授权外部比对。'
            : 'Query rewriting, retrieval planning, evidence selection, rerank, local-evidence verification, and authorized external comparison.',
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

  bool get _zh => widget.localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.extension_outlined,
        title: _zh ? 'Skill 工厂' : 'Skill Factory',
        description: _zh
            ? '选择知识库，配置生成方式和元数据，验证后生成 Skill 草稿，用于 Agent Creation Package 映射/预览/导出。'
            : 'Select a Knowledge Base, configure generation and metadata, validate, then use the Skill draft for Agent Creation Package mapping, preview, and export.',
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
              value: validationReady ? 'pass' : 'ready',
              detail: _zh ? '只读证据' : 'read-only',
              icon: Icons.rule_folder_outlined),
        ],
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        final extraWide = constraints.maxWidth >= 1180;
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
                      ['书籍 / 文档转 Skill', '文档库', 'enabled_real'],
                      ['知识库转 Skill', '知识库', 'enabled_real'],
                      ['Skill 模板驱动', 'Skill 模板', 'enabled_real'],
                      ['组合 / 空白 / 高级定制', '预留入口', 'display_only'],
                    ]
                  : [
                      [
                        'Book / doc to Skill',
                        'Document Library',
                        'enabled_real'
                      ],
                      [
                        'Knowledge Base to Skill',
                        'Knowledge Base',
                        'enabled_real'
                      ],
                      [
                        'Template-driven Skill',
                        'Skill templates',
                        'enabled_real'
                      ],
                      [
                        'Compose / blank / advanced',
                        'Reserved entry',
                        'display_only'
                      ],
                    ],
            ),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '上游承接物' : 'Upstream input',
                value: _zh
                    ? '现有知识库或刚生成的知识库'
                    : 'Existing or newly built Knowledge Base'),
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
                        ? '名称、说明、适用任务已进入预览'
                        : 'Name, description, and target task previewed')
                    : (_zh
                        ? '名称、说明、适用任务等待输入'
                        : 'Name, description, and target task waiting for input')),
            const SizedBox(height: 8),
            _PrimaryProductAction(
              label: _zh ? '准备 Skill 配置预览' : 'Prepare Skill config preview',
              icon: Icons.edit_note_outlined,
              onPressed: () => setState(() => configReady = true),
            ),
          ],
        );
        final output = _ProductPanel(
          keyName: 'skill-output-preview',
          icon: Icons.folder_zip_outlined,
          title: _zh ? 'Skill 包结构预览' : 'Skill Package Structure Preview',
          subtitle: '${widget.workspace}/workbench_runs/skill_draft',
          children: [
            _FileTreePreview(
              zh: _zh,
              rows: _zh
                  ? [
                      ['contract-reviewer-v1.0.0/', ''],
                      ['SKILL.md', outputPreviewReady ? '5.2 KB' : '-'],
                      ['manifests/', ''],
                      ['skill.yaml', outputPreviewReady ? '2.1 KB' : '-'],
                      ['prompts/', ''],
                      [
                        'review_contract.prompt.md',
                        outputPreviewReady ? '4.8 KB' : '-'
                      ],
                      ['reports/', ''],
                      [
                        'governance-report.json',
                        validationReady ? '18.7 KB' : '-'
                      ],
                    ]
                  : [
                      ['contract-reviewer-v1.0.0/', ''],
                      ['SKILL.md', outputPreviewReady ? '5.2 KB' : '-'],
                      ['manifests/', ''],
                      ['skill.yaml', outputPreviewReady ? '2.1 KB' : '-'],
                      ['prompts/', ''],
                      [
                        'review_contract.prompt.md',
                        outputPreviewReady ? '4.8 KB' : '-'
                      ],
                      ['reports/', ''],
                      [
                        'governance-report.json',
                        validationReady ? '18.7 KB' : '-'
                      ],
                    ],
            ),
            const SizedBox(height: _DesktopGrid.gutter),
            _DisplayAction(
              label: _zh ? '刷新输出结构预览' : 'Refresh output preview',
              icon: Icons.folder_zip_outlined,
              onPressed: () => setState(() {
                configReady = true;
                outputPreviewReady = true;
              }),
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
                    value: validationReady ? '91.3%' : '-',
                    detail: _zh ? '预估' : 'estimated',
                    icon: Icons.pie_chart_outline),
                _MetricDatum(
                    label: _zh ? '可安装性' : 'Installability',
                    value: validationReady ? '98.7%' : '-',
                    detail: _zh ? '预览' : 'preview',
                    icon: Icons.verified_outlined),
              ],
            ),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '覆盖率' : 'Coverage',
                value: validationReady
                    ? '86%'
                    : (_zh ? '等待报告' : 'Waiting for report')),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '可安装性' : 'Installability',
                value: validationReady
                    ? (_zh ? '通过预览检查' : 'Preview check passed')
                    : (_zh ? '等待报告' : 'Waiting for report')),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '下一阶段' : 'Next stage',
                value: _zh
                    ? 'Agent Creation Package 映射 / 预览 / 导出'
                    : 'Agent Creation Package mapping / preview / export'),
            const SizedBox(height: 8),
            _EqualActionRow(children: [
              _PrimaryProductAction(
                label: _zh ? '生成 Skill 草稿预览' : 'Prepare Skill draft preview',
                onPressed: () => setState(() {
                  configReady = true;
                  outputPreviewReady = true;
                  validationReady = true;
                }),
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
        if (extraWide) {
          return _EqualHeightRow(
            height: 646,
            flexes: const [7, 4],
            children: [
              _ProductColumn(children: [
                config,
                const SizedBox(height: _DesktopGrid.gutter),
                validation,
              ]),
              output,
            ],
          );
        }
        return _EqualHeightRow(
          height: 646,
          flexes: const [6, 5],
          children: [
            _ProductColumn(children: [
              config,
              const SizedBox(height: _DesktopGrid.gutter),
              validation
            ]),
            output,
          ],
        );
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
        ? ['执行总览', '单 Agent', '多 Agent / Memory', 'Tool Adapter']
        : [
            'Execution Overview',
            'Single Agents',
            'Multi-Agent / Memory',
            'Tool Adapter'
          ];
    final phases = _campaign6List(campaign6AgentRuntimeStatus['phase_status']);
    final agents =
        _campaign6List(campaign6AgentRuntimeStatus['agent_types_6a']);
    final advanced =
        _campaign6List(campaign6AgentRuntimeStatus['advanced_capabilities_6b']);
    final toolAdapter =
        _campaign6Map(campaign6AgentRuntimeStatus['tool_adapter_gate']);
    final acceptedPhases = phases
        .where((item) => item['runtime_status'] == 'pass')
        .length
        .toString();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.smart_toy_outlined,
        title: _zh ? 'Agent Runtime' : 'Agent Runtime',
        description: _zh
            ? '展示 Campaign 6A / 6B / Tool Adapter Configuration Gate 的已验收运行状态、证据、降级和边界。'
            : 'Shows accepted Campaign 6A / 6B / Tool Adapter Configuration Gate runtime status, evidence, degraded modes, and boundaries.',
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
        ],
      ),
      const SizedBox(height: _DesktopGrid.gutter),
      _PageTabs(
          tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
      const SizedBox(height: _DesktopGrid.gutter),
      switch (selectedTab) {
        1 => _Campaign6SingleAgentStatusView(zh: _zh, agents: agents),
        2 =>
          _Campaign6AdvancedRuntimeStatusView(zh: _zh, capabilities: advanced),
        3 => _Campaign6ToolAdapterStatusView(
            zh: _zh, toolAdapter: toolAdapter, workspace: workspace),
        _ => _Campaign6RuntimeOverviewView(
            zh: _zh,
            phases: phases,
            security: _campaign6Map(
                campaign6AgentRuntimeStatus['security_boundaries']),
          ),
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

class _AgentInputMappingView extends StatefulWidget {
  const _AgentInputMappingView({required this.zh});
  final bool zh;

  @override
  State<_AgentInputMappingView> createState() => _AgentInputMappingViewState();
}

class _AgentInputMappingViewState extends State<_AgentInputMappingView> {
  bool mappingPreviewReady = true;

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final mapping = _ProductPanel(
        keyName: 'agent-input-mapping',
        icon: Icons.account_tree_outlined,
        title: zh
            ? 'Agent Creation Package 输入映射'
            : 'Agent Creation Package Input Mapping',
        children: [
          _ProductTable(
            columns: zh
                ? ['输入', '映射字段', '状态']
                : ['Input', 'Mapping field', 'Status'],
            rows: zh
                ? [
                    ['知识库', 'kb_binding.json', 'enabled_real'],
                    ['Skill 草稿', 'skill_binding.json', 'enabled_real'],
                    ['Agent 模板', 'agent_manifest.json', 'enabled_real'],
                    ['运行配置', 'runtime_boundary.json', 'omitted'],
                  ]
                : [
                    ['Knowledge Base', 'kb_binding.json', 'enabled_real'],
                    ['Skill draft', 'skill_binding.json', 'enabled_real'],
                    ['Agent template', 'agent_manifest.json', 'enabled_real'],
                    ['Execution config', 'runtime_boundary.json', 'omitted'],
                  ],
          ),
          const SizedBox(height: _DesktopGrid.gutter),
          _FieldRow(
              label: zh ? '映射校验' : 'Mapping check',
              value: zh
                  ? '知识库、Skill 与模板字段已对齐到 Package 草稿'
                  : 'Knowledge Base, Skill, and template fields align to the package draft'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '导出目标' : 'Export target',
              value: zh
                  ? './workbench_runs/agent_creation_package'
                  : './workbench_runs/agent_creation_package'),
          const SizedBox(height: _DesktopGrid.gutter),
          _EqualActionRow(children: [
            _PrimaryProductAction(
              label: zh ? '预览 Package 输入映射' : 'Preview package input mapping',
              icon: Icons.input_outlined,
              onPressed: () => setState(() => mappingPreviewReady = true),
            ),
          ]),
        ],
      );
      final detail = _ProductPanel(
        icon: Icons.info_outline,
        title: zh ? '边界摘要' : 'Boundary Summary',
        gap: true,
        children: [
          _FieldRow(
              label: zh ? '映射目标' : 'Mapping target',
              value: zh
                  ? 'Agent Creation Package draft'
                  : 'Agent Creation Package draft'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '当前边界' : 'Current boundary',
              value: zh
                  ? '可导出 Agent Creation Package；不保存 Agent 定义'
                  : 'Agent Creation Package export is available; no Agent definition save'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '下游产物' : 'Downstream artifact',
              value: mappingPreviewReady
                  ? (zh
                      ? 'Agent Creation Package 映射预览'
                      : 'Agent Creation Package mapping preview')
                  : 'Agent Creation Package'),
        ],
      );
      final governance = _ProductPanel(
        icon: Icons.policy_outlined,
        title: zh ? '治理检查' : 'Governance Checks',
        gap: true,
        children: [
          _ProductTable(
            columns: zh ? ['检查', '结果', '归属'] : ['Check', 'Result', 'Owner'],
            rows: zh
                ? [
                    ['创建 / 保存 Agent', '后续阶段', 'Campaign 6'],
                    ['Provider 绑定', '已验收', '安全 Provider 状态'],
                    ['运行时 / 记忆 / 协作', '后续阶段', 'Post-9'],
                  ]
                : [
                    ['Create / save Agent', 'Later phase', 'Campaign 6'],
                    ['Provider binding', 'Accepted', 'Secure provider status'],
                    [
                      'Runtime / memory / collaboration',
                      'Later phase',
                      'Post-9'
                    ],
                  ],
          ),
        ],
      );
      final packageTree = _ProductPanel(
        icon: Icons.folder_zip_outlined,
        title: zh ? 'Package 结构预览' : 'Package Structure Preview',
        subtitle: zh
            ? '只读展示，不保存 Agent 定义'
            : 'Read-only display; no Agent definition save',
        gap: true,
        children: [
          _FileTreePreview(
            zh: zh,
            rows: const [
              ['agent_creation_package/', ''],
              ['agent_manifest.json', '3.1 KB'],
              ['kb_binding.json', '1.8 KB'],
              ['skill_binding.json', '1.6 KB'],
              ['config_preview.yaml', 'display_only'],
              ['runtime_boundary.json', 'omitted'],
              ['export_manifest.json', '2.4 KB'],
            ],
          ),
        ],
      );
      if (!wide) {
        return Column(children: [
          mapping,
          const SizedBox(height: _DesktopGrid.gutter),
          detail,
          const SizedBox(height: _DesktopGrid.gutter),
          packageTree
        ]);
      }
      return _EqualHeightRow(
        height: 566,
        flexes: const [7, 4],
        children: [
          mapping,
          _ProductColumn(children: [
            detail,
            const SizedBox(height: _DesktopGrid.gutter),
            governance,
            const SizedBox(height: _DesktopGrid.gutter),
            packageTree,
          ]),
        ],
      );
    });
  }
}

class _AgentConfigPreviewView extends StatefulWidget {
  const _AgentConfigPreviewView({required this.zh});
  final bool zh;

  @override
  State<_AgentConfigPreviewView> createState() =>
      _AgentConfigPreviewViewState();
}

class _AgentConfigPreviewViewState extends State<_AgentConfigPreviewView> {
  bool configExpanded = true;

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'agent-config-preview',
      icon: Icons.tune_outlined,
      title: zh ? '配置预览' : 'Configuration Preview',
      subtitle: zh
          ? '简单/高级模式仅用于预览现有 package 声明字段；Campaign 6 才实现正式 Agent 配置编辑。'
          : 'Simple/advanced modes preview current package declarations only; formal editing belongs to Campaign 6.',
      gap: true,
      children: [
        _ProductTable(
          columns: zh
              ? ['字段', '简单模式', '高级模式', '边界']
              : ['Field', 'Simple', 'Advanced', 'Boundary'],
          rows: zh
              ? [
                  [
                    'role / objective',
                    configExpanded ? '已展开' : '可预览',
                    '可预览 JSON',
                    '不保存版本'
                  ],
                  [
                    'KB / Skill binding metadata',
                    '可预览',
                    '可预览声明',
                    '不做多 Skill 绑定编辑'
                  ],
                  [
                    'model / tools / permissions',
                    '只读',
                    '声明展示',
                    '不执行 Provider Gate'
                  ],
                  ['workspace partition', '只读', '声明展示', 'Agent 工作区分区预留'],
                ]
              : [
                  [
                    'role / objective',
                    configExpanded ? 'Expanded' : 'Previewable',
                    'JSON preview',
                    'No version save'
                  ],
                  [
                    'KB / Skill binding metadata',
                    'Previewable',
                    'Declaration preview',
                    'No multi-Skill binding editor'
                  ],
                  [
                    'model / tools / permissions',
                    'Read-only',
                    'Declaration display',
                    'No Provider Gate execution'
                  ],
                  [
                    'workspace partition',
                    'Read-only',
                    'Declaration display',
                    'Agent workspace partition reserved'
                  ],
                ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _DisplayAction(
          label: zh ? '展开配置预览' : 'Expand configuration preview',
          icon: Icons.tune_outlined,
          onPressed: () => setState(() => configExpanded = true),
        ),
      ],
    );
  }
}

class _AgentPackagePreviewView extends StatefulWidget {
  const _AgentPackagePreviewView({required this.zh});
  final bool zh;

  @override
  State<_AgentPackagePreviewView> createState() =>
      _AgentPackagePreviewViewState();
}

class _AgentPackagePreviewViewState extends State<_AgentPackagePreviewView> {
  bool packagePreviewReady = true;

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'agent-package-preview',
      icon: Icons.inventory_2_outlined,
      title:
          zh ? 'Agent Creation Package 预览' : 'Agent Creation Package Preview',
      children: [
        _FileTreePreview(
          zh: zh,
          rows: zh
              ? [
                  ['agent_creation_package/', ''],
                  ['agent_manifest.json', packagePreviewReady ? '3.1 KB' : '-'],
                  ['kb_binding.json', packagePreviewReady ? '1.8 KB' : '-'],
                  ['skill_binding.json', packagePreviewReady ? '1.6 KB' : '-'],
                  ['workspace_partition.json', 'display_only'],
                  [
                    'validation_report.json',
                    packagePreviewReady ? '6.4 KB' : '-'
                  ],
                ]
              : [
                  ['agent_creation_package/', ''],
                  ['agent_manifest.json', packagePreviewReady ? '3.1 KB' : '-'],
                  ['kb_binding.json', packagePreviewReady ? '1.8 KB' : '-'],
                  ['skill_binding.json', packagePreviewReady ? '1.6 KB' : '-'],
                  ['workspace_partition.json', 'display_only'],
                  [
                    'validation_report.json',
                    packagePreviewReady ? '6.4 KB' : '-'
                  ],
                ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _DisplayAction(
          label: zh ? '刷新 Package 预览' : 'Refresh package preview',
          icon: Icons.inventory_2_outlined,
          onPressed: () => setState(() => packagePreviewReady = true),
        ),
      ],
    );
  }
}

class _AgentExportBoundaryView extends StatefulWidget {
  const _AgentExportBoundaryView({required this.zh, required this.workspace});
  final bool zh;
  final String workspace;

  @override
  State<_AgentExportBoundaryView> createState() =>
      _AgentExportBoundaryViewState();
}

class _AgentExportBoundaryViewState extends State<_AgentExportBoundaryView> {
  bool exportDraftReady = false;

  bool get zh => widget.zh;

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'agent-export-boundary',
      icon: Icons.archive_outlined,
      title: zh
          ? 'Agent Creation Package 导出边界'
          : 'Agent Creation Package Export Boundary',
      subtitle: '${widget.workspace}/workbench_runs/agent_package',
      gap: true,
      children: [
        _ProductTable(
          columns: zh ? ['动作', '分类', '说明'] : ['Action', 'Class', 'Note'],
          rows: zh
              ? [
                  ['预览 package', 'enabled_real', '展示现有产物结构与导出清单'],
                  [
                    '导出 package draft',
                    exportDraftReady ? '预览已准备' : 'enabled_real',
                    '只导出 Agent Creation Package 草稿'
                  ],
                  ['保存 Agent 定义', 'omitted', 'Campaign 6'],
                  ['版本管理', 'omitted', 'Campaign 6'],
                  ['会话追踪 / 记忆 / 协作', 'omitted', '当前不展示为可用能力'],
                ]
              : [
                  [
                    'Preview package',
                    'enabled_real',
                    'Shows existing artifact structure and export manifest'
                  ],
                  [
                    'Export package draft',
                    exportDraftReady ? 'Preview ready' : 'enabled_real',
                    'Exports Agent Creation Package draft only'
                  ],
                  ['Save Agent definition', 'omitted', 'Campaign 6'],
                  ['Version management', 'omitted', 'Campaign 6'],
                  [
                    'Session trace / memory / collaboration',
                    'omitted',
                    'Not shown as usable'
                  ],
                ],
        ),
        const SizedBox(height: _DesktopGrid.gutter),
        _PrimaryProductAction(
          label: zh ? '准备 Package 导出预览' : 'Prepare package export preview',
          icon: Icons.archive_outlined,
          onPressed: () => setState(() => exportDraftReady = true),
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
              label: zh ? '运行报告清单预览' : 'Run report checklist preview',
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
                      reportSelected ? '预览已打开' : '等待',
                      reportSelected ? '本地验证摘要' : '无真实报告'
                    ],
                    ['governance_report', '治理', '可展示', 'fixture'],
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
                      reportSelected ? 'Preview open' : 'Waiting',
                      reportSelected
                          ? 'Local validation summary'
                          : 'No real report'
                    ],
                    [
                      'governance_report',
                      'Governance',
                      'Displayable',
                      'fixture'
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
              label: zh ? '打开验证报告预览' : 'Open validation report preview',
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
                      ? '4 项检查，0 个阻塞，Owner 视觉验收已通过'
                      : '4 checks, 0 blockers, Owner visual acceptance passed')
                  : (zh ? '等待报告产物' : 'Waiting for report artifact')),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '门禁影响' : 'Gate impact',
              value: reportSelected
                  ? (zh
                      ? 'Owner 视觉验收已通过，继续 Acceptance Gate 核验'
                      : 'Owner visual acceptance passed; Acceptance Gate checks continue')
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
                  [
                    '归档报告',
                    exportManifestReady ? 'enabled_real' : 'display_only',
                    '只归档报告证据'
                  ],
                  ['导出文档', 'omitted', '归文档生成模块'],
                  ['导出 Skill', 'omitted', '归 Skill 工厂'],
                  ['导出 Agent Package', 'omitted', '归 Agent 工厂'],
                  ['发布 Release', 'omitted', '未授权'],
                ]
              : [
                  [
                    'Archive reports',
                    exportManifestReady ? 'enabled_real' : 'display_only',
                    'Archives report evidence only'
                  ],
                  [
                    'Export documents',
                    'omitted',
                    'Owned by Document Generation'
                  ],
                  ['Export Skill', 'omitted', 'Owned by Skill Factory'],
                  ['Export Agent Package', 'omitted', 'Owned by Agent Factory'],
                  ['Publish Release', 'omitted', 'Not authorized'],
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
    required this.diagnostics,
  });

  final String localeCode;
  final String workspace;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;
  final bool isWebRuntime;
  final Widget diagnostics;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final tabs = _zh
        ? ['工作区', 'Provider 与存储', '模型与语言', '安全', '开发者诊断']
        : [
            'Workspace',
            'Providers and Storage',
            'Models and Language',
            'Safety',
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
      if (selectedTab == 4)
        diagnostics
      else if (selectedTab == 1)
        _SettingsProvidersStorageView(zh: _zh, workspace: workspace)
      else if (selectedTab == 0)
        _SettingsWorkspaceView(
          zh: _zh,
          workspace: workspace,
          isWebRuntime: isWebRuntime,
        )
      else
        _ProductPanel(
          keyName: 'settings-groups',
          icon: selectedTab == 2
              ? Icons.memory_outlined
              : selectedTab == 3
                  ? Icons.shield_outlined
                  : Icons.folder_outlined,
          title: tabs[selectedTab],
          children: selectedTab == 2
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
                              'text-embedding-3-large',
                              'display_only'
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
                              'text-embedding-3-large',
                              'display_only'
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
              : selectedTab == 3
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

class _SettingsProvidersStorageView extends StatelessWidget {
  const _SettingsProvidersStorageView({
    required this.zh,
    required this.workspace,
  });

  final bool zh;
  final String workspace;

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
                    ['应用工作区', workspace, '本地可用', 'enabled_real'],
                    ['对象存储', '本地文件系统', '本地可用', 'enabled_real'],
                    ['向量数据库', 'Qdrant / Milvus 预留', '未接入', 'disabled_boundary'],
                    ['LLM Provider', '环境变量', 'live smoke 通过', 'enabled_real'],
                    ['API Key', 'sk-************', '掩码展示', 'display_only'],
                  ]
                : [
                    [
                      'App workspace',
                      workspace,
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
                      'Qdrant / Milvus reserved',
                      'Not connected',
                      'disabled_boundary'
                    ],
                    [
                      'LLM Provider',
                      'Environment variables',
                      'Live smoke passed',
                      'enabled_real'
                    ],
                    ['API Key', 'sk-************', 'Masked', 'display_only'],
                  ],
          ),
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
                  detail: zh ? '开发预览' : 'dev preview',
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
                    ['文档缓存', './data/documents', 'display_only'],
                    ['向量索引目录', './data/vector', 'display_only'],
                    ['Core CLI', 'heitang-kb-forge', 'enabled_real'],
                  ]
                : [
                    ['Workspace root', workspace, 'enabled_real'],
                    ['Output directory', './workbench_runs', 'enabled_real'],
                    ['Document cache', './data/documents', 'display_only'],
                    ['Vector index dir', './data/vector', 'display_only'],
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
                      'display_only',
                      'Agent 工厂预览'
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
                      'display_only',
                      'Agent Factory preview'
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
                    ['增量备份', '每日 02:00', 'display_only'],
                    ['本地保留', '30 天，最多 30 个备份', 'display_only'],
                    ['缓存清理', '超过保留策略自动删除', 'disabled_boundary'],
                    ['云备份', '未接入', 'disabled_boundary'],
                  ]
                : [
                    ['Incremental backup', 'Daily 02:00', 'display_only'],
                    [
                      'Local retention',
                      '30 days, max 30 backups',
                      'display_only'
                    ],
                    [
                      'Cache cleanup',
                      'Deletes past retention policy',
                      'disabled_boundary'
                    ],
                    ['Cloud backup', 'Not connected', 'disabled_boundary'],
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
