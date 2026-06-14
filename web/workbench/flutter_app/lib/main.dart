import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core_actions/core_action_panel.dart';
import 'core_actions/page_action_mapping.dart';
import 'core_actions/workbench_actions.dart';
import 'core_bridge/local_core_bridge.dart';
import 'contracts/workbench_contracts.dart';
import 'backend_evidence/parser_backend_dashboard.dart';
import 'skill_factory/skill_factory_workflow.dart';
import 'workbench/task_workbench.dart';

void main() {
  runApp(const HeiTangWorkbenchApp());
}

const brandAssets = <String>[
  'assets/brand/black_cat_head.svg',
  'assets/brand/black_tiger_head.svg',
];

const supportedLocaleCodes = <String>['zh-CN', 'en-US'];

const pages = <WorkbenchPage>[
  WorkbenchPage(
      'dashboard',
      'Dashboard',
      '工作台',
      'A guided local workbench for turning source material into a validated Agent package.',
      '把本地资料加工为可验证 Agent 包的引导式工作台。',
      memberPageIds: [
        'dashboard',
        'operation-gate',
        'capability-matrix',
        'task-job-center',
      ]),
  WorkbenchPage(
      'import-parsing',
      'Import Materials',
      '导入资料',
      'Bring local files into the workspace and prepare them for parsing.',
      '导入本地文件，并为解析处理做好准备。',
      memberPageIds: ['import-parsing']),
  WorkbenchPage(
      'knowledge-package-management',
      'Knowledge Package',
      '知识库',
      'Organize parsed content into a reusable knowledge package.',
      '把解析后的内容组织为可复用的知识包。',
      memberPageIds: [
        'knowledge-package-management',
        'retrieval-verification',
        'vector-hub-provider-storage',
        'document-generation',
      ]),
  WorkbenchPage(
      'skill-factory',
      'Skill Builder',
      'Skill 生成',
      'Convert the knowledge package into a governed Skill draft.',
      '把知识包转化为经过治理的 Skill 草稿。',
      memberPageIds: ['skill-factory']),
  WorkbenchPage(
      'agent-factory-runtime',
      'Agent Package',
      'Agent 包',
      'Generate an Agent package draft without claiming runtime completion.',
      '生成 Agent 包草稿，不宣称运行时已完成。',
      memberPageIds: ['agent-factory-runtime']),
  WorkbenchPage(
      'reports-audit',
      'Validate & Export',
      '验证与导出',
      'Validate outputs and prepare controlled export evidence.',
      '验证输出，并准备受控导出证据。',
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
      'Review local workspace paths and execution availability.',
      '查看本地工作区路径与执行可用性。',
      memberPageIds: ['workspace', 'template-library']),
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
  late final Future<Map<String, dynamic>> _skillGovernanceReportFuture =
      Future<Map<String, dynamic>>.value(
          widget.skillGovernanceReport ?? sampleSkillGovernanceReport);

  bool get isDark => themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeiTang Knowledge Workbench',
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
        style: FilledButton.styleFrom(shape: const StadiumBorder()),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: const StadiumBorder()),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.localeCode, required this.compact});

  final String localeCode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(localeCode == 'zh-CN' ? '黑糖' : 'HeiTang',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        if (!compact)
          Text(localeCode == 'zh-CN' ? '知识工作台' : 'Knowledge Workbench',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium),
      ],
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
    required this.skillGovernanceReport,
    required this.methodologyMap,
    required this.skillSuiteWorkflow,
    required this.selectedIndex,
    required this.isTablet,
    required this.coreBridge,
    required this.coreCli,
    required this.coreWorkingDirectory,
    required this.coreWorkspace,
    required this.enableLocalCoreActions,
    required this.isWebRuntime,
    required this.isDark,
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
  final Map<String, dynamic> skillGovernanceReport;
  final Map<String, dynamic> methodologyMap;
  final Map<String, dynamic>? skillSuiteWorkflow;
  final int selectedIndex;
  final bool isTablet;
  final LocalCoreBridge coreBridge;
  final String coreCli;
  final String coreWorkingDirectory;
  final String coreWorkspace;
  final bool enableLocalCoreActions;
  final bool isWebRuntime;
  final bool isDark;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<String> onLocaleChanged;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = isTablet ? 220.0 : 280.0;

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
                  skillGovernanceReport: skillGovernanceReport,
                  methodologyMap: methodologyMap,
                  skillSuiteWorkflow: skillSuiteWorkflow,
                  columns: isTablet ? 2 : 3,
                  coreBridge: coreBridge,
                  coreCli: coreCli,
                  coreWorkingDirectory: coreWorkingDirectory,
                  coreWorkspace: coreWorkspace,
                  enableLocalCoreActions: enableLocalCoreActions,
                  isWebRuntime: isWebRuntime,
                  isDark: isDark,
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
                ? Icons.public_off_outlined
                : Icons.desktop_windows_outlined,
            label: _zh ? '模式' : 'Mode',
            value: isWebRuntime
                ? (_zh ? 'Web 安全展示' : 'Web-safe view')
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          _SidebarGroupLabel(label: localeCode == 'zh-CN' ? '系统' : 'System'),
          _SidebarItem(
            page: pages[6],
            icon: Icons.tune_outlined,
            localeCode: localeCode,
            contracts: contracts,
            selected: selectedIndex == 6,
            primaryText: primaryText,
            secondaryText: secondaryText,
            selectedBackground: selectedBackground,
            onTap: () => onPageChanged(6),
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
          Text(localeCode == 'zh-CN' ? 'HeiTang 黑糖' : 'HeiTang',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: primaryText,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
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
                letterSpacing: 0.5,
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
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? selectedBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: selected ? primaryText : secondaryText, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(page.title(localeCode, contracts),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryText,
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
        color: const Color(0xff242a30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xff38414a)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xfff7f7f5), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localeCode == 'zh-CN' ? '本地优先' : 'Local first',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xfff7f7f5),
                          fontWeight: FontWeight.w800,
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
    );
  }
}

IconData _sidebarIconFor(String pageId) {
  switch (pageId) {
    case 'import-parsing':
      return Icons.upload_file_outlined;
    case 'knowledge-package-management':
      return Icons.inventory_2_outlined;
    case 'skill-factory':
      return Icons.extension_outlined;
    case 'agent-factory-runtime':
      return Icons.archive_outlined;
    case 'reports-audit':
      return Icons.fact_check_outlined;
    default:
      return Icons.circle_outlined;
  }
}

class _PhoneWorkbench extends StatelessWidget {
  const _PhoneWorkbench({
    required this.localeCode,
    required this.contracts,
    required this.workflowEvidence,
    required this.workflowV2Evidence,
    required this.externalCapabilities,
    required this.parserBackends,
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
    required this.onPageChanged,
  });

  final String localeCode;
  final WorkbenchContracts contracts;
  final P1WorkflowEvidence workflowEvidence;
  final P1WorkflowEvidence workflowV2Evidence;
  final ExternalCapabilityRegistry externalCapabilities;
  final ParserBackendMatrix parserBackends;
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
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<int>(
            initialValue: selectedIndex,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: localeCode == 'zh-CN' ? '页面' : 'Page',
              border: const OutlineInputBorder(),
            ),
            items: [
              for (var index = 0; index < pages.length; index++)
                DropdownMenuItem(
                  value: index,
                  child: Text(pages[index].title(localeCode, contracts),
                      overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                onPageChanged(value);
              }
            },
          ),
        ),
        Expanded(
          child: _PageSurface(
            page: pages[selectedIndex],
            localeCode: localeCode,
            contracts: contracts,
            workflowEvidence: workflowEvidence,
            workflowV2Evidence: workflowV2Evidence,
            externalCapabilities: externalCapabilities,
            parserBackends: parserBackends,
            skillGovernanceReport: skillGovernanceReport,
            methodologyMap: methodologyMap,
            skillSuiteWorkflow: skillSuiteWorkflow,
            columns: 1,
            coreBridge: coreBridge,
            coreCli: coreCli,
            coreWorkingDirectory: coreWorkingDirectory,
            coreWorkspace: coreWorkspace,
            enableLocalCoreActions: enableLocalCoreActions,
            isWebRuntime: isWebRuntime,
            isDark: null,
            onThemeChanged: null,
            onLocaleChanged: null,
          ),
        ),
      ],
    );
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
  final ValueChanged<ThemeMode>? onThemeChanged;
  final ValueChanged<String>? onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final isSkillFactory = page.id == 'skill-factory';
    final isDashboard = page.id == 'dashboard';
    final cards = _cardsFor(
        page.id,
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(columns == 1 ? 14 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductTopBar(
            localeCode: localeCode,
            page: page,
            contracts: contracts,
            isWebRuntime: isWebRuntime,
            isDark: isDark,
            onThemeChanged: onThemeChanged,
            onLocaleChanged: onLocaleChanged,
          ),
          const SizedBox(height: 18),
          if (isDashboard) ...[
            TaskWorkbenchSurface(
              localeCode: localeCode,
              workspace: coreWorkspace,
              isWebRuntime: isWebRuntime,
            ),
            const SizedBox(height: 20),
          ],
          if (!isDashboard) ...[
            _ProductPageOverview(
              localeCode: localeCode,
              page: page,
              workspace: coreWorkspace,
              isWebRuntime: isWebRuntime,
            ),
            const SizedBox(height: 20),
          ],
          _AdvancedBoundaryDetails(
            localeCode: localeCode,
            cards: cards,
            columns: columns,
            corePanels: corePanels,
            parserBackends:
                page.id != 'dashboard' && page.pageIds.any(_showsParserBackends)
                    ? parserBackends
                    : null,
            skillFactoryWorkflow: isSkillFactory ? skillSuiteWorkflow : null,
          ),
        ],
      ),
    );
  }

  List<_CardCopy> _cardsFor(
    String id,
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
      if (page.pageIds.contains('template-library'))
        _CardCopy(
            zh ? '模板' : 'Templates',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = constraints.maxWidth < 720;
        final isTablet =
            constraints.maxWidth >= 720 && constraints.maxWidth < 1040;

        return Scaffold(
          appBar: isPhone
              ? AppBar(
                  titleSpacing: 16,
                  title: _BrandHeader(localeCode: localeCode, compact: true),
                  actions: [
                    IconButton(
                      tooltip: isDark ? 'Light mode' : 'Dark mode',
                      onPressed: () => onThemeChanged(
                          isDark ? ThemeMode.light : ThemeMode.dark),
                      icon: Icon(isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 12),
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 'zh-CN', label: Text('中')),
                          ButtonSegment(value: 'en-US', label: Text('EN')),
                        ],
                        selected: {localeCode},
                        onSelectionChanged: (value) =>
                            onLocaleChanged(value.first),
                      ),
                    ),
                  ],
                )
              : null,
          body: isPhone
              ? _PhoneWorkbench(
                  localeCode: localeCode,
                  contracts: contracts,
                  workflowEvidence: workflowEvidence,
                  workflowV2Evidence: workflowV2Evidence,
                  externalCapabilities: externalCapabilities,
                  parserBackends: parserBackends,
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
                  onPageChanged: onPageChanged,
                )
              : _DesktopWorkbench(
                  localeCode: localeCode,
                  contracts: contracts,
                  workflowEvidence: workflowEvidence,
                  workflowV2Evidence: workflowV2Evidence,
                  externalCapabilities: externalCapabilities,
                  parserBackends: parserBackends,
                  skillGovernanceReport: skillGovernanceReport,
                  methodologyMap: methodologyMap,
                  skillSuiteWorkflow: skillSuiteWorkflow,
                  selectedIndex: selectedIndex,
                  isTablet: isTablet,
                  coreBridge: coreBridge,
                  coreCli: coreCli,
                  coreWorkingDirectory: coreWorkingDirectory,
                  coreWorkspace: coreWorkspace,
                  enableLocalCoreActions: enableLocalCoreActions,
                  isWebRuntime: isWebRuntime,
                  isDark: isDark,
                  onThemeChanged: onThemeChanged,
                  onLocaleChanged: onLocaleChanged,
                  onPageChanged: onPageChanged,
                ),
        );
      },
    );
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
    required this.isWebRuntime,
    required this.isDark,
    required this.onThemeChanged,
    required this.onLocaleChanged,
  });

  final String localeCode;
  final WorkbenchPage page;
  final WorkbenchContracts contracts;
  final bool isWebRuntime;
  final bool? isDark;
  final ValueChanged<ThemeMode>? onThemeChanged;
  final ValueChanged<String>? onLocaleChanged;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(page.title(localeCode, contracts),
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.8)),
        const SizedBox(height: 6),
        Text(page.description(localeCode),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                )),
      ],
    );
    final actions = Wrap(
      alignment: WrapAlignment.end,
      spacing: 10,
      runSpacing: 10,
      children: [
        _TopBarSearchField(
            label: _zh ? '搜索知识、Skill、文档' : 'Search knowledge, Skill, docs'),
        _TopBarChip(
          icon: Icons.terminal,
          label: _zh ? '终端' : 'Terminal',
        ),
        _TopBarChip(
          icon: Icons.notifications_none_outlined,
          label: _zh ? '通知' : 'Notifications',
        ),
        _TopBarIconButton(
          icon: Icons.refresh_outlined,
          label: _zh ? '刷新' : 'Refresh',
          onPressed: () {},
        ),
        _TopBarChip(
          icon: isWebRuntime
              ? Icons.public_off_outlined
              : Icons.desktop_windows_outlined,
          label: isWebRuntime
              ? (_zh ? 'Web 安全展示' : 'Web-safe view')
              : (_zh ? '桌面本地执行' : 'Desktop local run'),
        ),
        if (isDark != null && onThemeChanged != null)
          _TopBarIconButton(
            icon:
                isDark! ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            label: isDark! ? (_zh ? '浅色' : 'Light') : (_zh ? '深色' : 'Dark'),
            onPressed: () =>
                onThemeChanged!(isDark! ? ThemeMode.light : ThemeMode.dark),
          ),
        if (onLocaleChanged != null)
          _TopBarLanguageToggle(
            localeCode: localeCode,
            onLocaleChanged: onLocaleChanged!,
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              actions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 18),
            Flexible(child: actions),
          ],
        );
      },
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
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
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
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    )),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Ctrl K',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
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
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
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
    return SegmentedButton<String>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
      segments: const [
        ButtonSegment(value: 'zh-CN', label: Text('中')),
        ButtonSegment(value: 'en-US', label: Text('EN')),
      ],
      selected: {localeCode},
      onSelectionChanged: (value) => onLocaleChanged(value.first),
    );
  }
}

class _TopBarChip extends StatelessWidget {
  const _TopBarChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
          ),
        ],
      ),
    );
  }
}

class _ProductPageOverview extends StatelessWidget {
  const _ProductPageOverview({
    required this.localeCode,
    required this.page,
    required this.workspace,
    required this.isWebRuntime,
  });

  final String localeCode;
  final WorkbenchPage page;
  final String workspace;
  final bool isWebRuntime;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final copy = _ProductPageCopy.forPage(page.id, _zh);
    return Card(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(copy.title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(copy.body, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 920;
                final workflow = _ProductFlowPanel(
                  localeCode: localeCode,
                  copy: copy,
                  workspace: workspace,
                );
                final status = _ProductStatusPanel(
                  localeCode: localeCode,
                  copy: copy,
                  workspace: workspace,
                  isWebRuntime: isWebRuntime,
                );
                if (!wide) {
                  return Column(
                    children: [
                      workflow,
                      const SizedBox(height: 12),
                      status,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: workflow),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: status),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPageCopy {
  const _ProductPageCopy({
    required this.title,
    required this.body,
    required this.nextAction,
    required this.outputSuffix,
    required this.steps,
    required this.previewTitle,
  });

  final String title;
  final String body;
  final String nextAction;
  final String outputSuffix;
  final List<String> steps;
  final String previewTitle;

  String outputPath(String workspace) => '$workspace/$outputSuffix';

  static _ProductPageCopy forPage(String id, bool zh) {
    switch (id) {
      case 'import-parsing':
        return _ProductPageCopy(
          title: zh ? '导入资料' : 'Import Materials',
          body: zh
              ? '选择本地资料，确认解析范围，再进入知识构建。'
              : 'Choose local material, confirm the parsing scope, then move into knowledge building.',
          nextAction: zh ? '选择本地文件或文件夹' : 'Choose a local file or folder',
          outputSuffix: 'workbench_runs/import_manifest',
          previewTitle: zh ? '导入清单预览' : 'Import manifest preview',
          steps: zh
              ? ['选择资料', '确认解析范围', '生成导入清单']
              : [
                  'Choose material',
                  'Confirm parsing scope',
                  'Create import manifest'
                ],
        );
      case 'knowledge-package-management':
        return _ProductPageCopy(
          title: zh ? '知识库' : 'Knowledge Package',
          body: zh
              ? '把解析内容切分、整理并形成可复用的知识包草稿。'
              : 'Split and organize parsed content into a reusable knowledge package draft.',
          nextAction: zh ? '检查解析结果' : 'Review parsed content',
          outputSuffix: 'workbench_runs/knowledge_package',
          previewTitle: zh ? '知识包预览' : 'Knowledge package preview',
          steps: zh
              ? ['检查解析结果', '切分知识片段', '整理知识包草稿']
              : [
                  'Review parsed content',
                  'Split knowledge chunks',
                  'Organize package draft'
                ],
        );
      case 'skill-factory':
        return _ProductPageCopy(
          title: zh ? 'Skill 生成' : 'Skill Builder',
          body: zh
              ? '从知识包提炼方法论，并生成可治理的 Skill 草稿。'
              : 'Extract methodology from the package and generate a governed Skill draft.',
          nextAction: zh ? '确认知识包草稿' : 'Confirm the package draft',
          outputSuffix: 'workbench_runs/skill_draft',
          previewTitle: zh ? 'Skill 草稿预览' : 'Skill draft preview',
          steps: zh
              ? ['确认知识包', '提炼方法论', '生成 Skill 草稿']
              : [
                  'Confirm package',
                  'Extract methodology',
                  'Generate Skill draft'
                ],
        );
      case 'agent-factory-runtime':
        return _ProductPageCopy(
          title: zh ? 'Agent 包' : 'Agent Package',
          body: zh
              ? '生成 Agent 包草稿；这里只准备包，不宣称运行时已完成。'
              : 'Generate an Agent package draft; this prepares the package without claiming runtime completion.',
          nextAction: zh ? '生成包草稿' : 'Generate package draft',
          outputSuffix: 'workbench_runs/agent_package',
          previewTitle: zh ? 'Agent 包预览' : 'Agent package preview',
          steps: zh
              ? ['选择 Skill 草稿', '生成包结构', '等待验证导出']
              : [
                  'Select Skill draft',
                  'Generate package structure',
                  'Wait for validation'
                ],
        );
      case 'reports-audit':
        return _ProductPageCopy(
          title: zh ? '验证与导出' : 'Validate & Export',
          body: zh
              ? '检查输出、证据和失败恢复路径，再决定是否导出。'
              : 'Check outputs, evidence, and recovery paths before export.',
          nextAction: zh ? '验证清单与报告' : 'Validate manifests and reports',
          outputSuffix: 'workbench_runs/validation_report',
          previewTitle: zh ? '验证报告预览' : 'Validation report preview',
          steps: zh
              ? ['检查输出路径', '验证证据报告', '准备受控导出']
              : [
                  'Check output paths',
                  'Validate evidence reports',
                  'Prepare controlled export'
                ],
        );
      default:
        return _ProductPageCopy(
          title: zh ? '设置' : 'Settings',
          body: zh
              ? '确认工作区、本地执行可用性和安全边界。'
              : 'Review workspace paths, local execution availability, and safety boundaries.',
          nextAction: zh ? '检查工作区路径' : 'Check workspace path',
          outputSuffix: 'workbench_runs/settings',
          previewTitle: zh ? '工作区设置预览' : 'Workspace settings preview',
          steps: zh
              ? ['检查工作区', '确认本地执行', '保持安全边界']
              : [
                  'Check workspace',
                  'Confirm local execution',
                  'Keep safety boundaries'
                ],
        );
    }
  }
}

class _ProductFlowPanel extends StatelessWidget {
  const _ProductFlowPanel({
    required this.localeCode,
    required this.copy,
    required this.workspace,
  });

  final String localeCode;
  final _ProductPageCopy copy;
  final String workspace;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('product-flow-panel'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_zh ? '操作流程' : 'Operation Flow',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          for (var index = 0; index < copy.steps.length; index++) ...[
            _ProductFlowStep(index: index, label: copy.steps[index]),
            if (index != copy.steps.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 14),
          _ProductSignal(
            label: _zh ? '下一步' : 'Next action',
            value: copy.nextAction,
            wide: true,
          ),
        ],
      ),
    );
  }
}

class _ProductFlowStep extends StatelessWidget {
  const _ProductFlowStep({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: SizedBox.square(
            dimension: 26,
            child: Center(
              child: Text(
                '${index + 1}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
        ),
      ],
    );
  }
}

class _ProductStatusPanel extends StatelessWidget {
  const _ProductStatusPanel({
    required this.localeCode,
    required this.copy,
    required this.workspace,
    required this.isWebRuntime,
  });

  final String localeCode;
  final _ProductPageCopy copy;
  final String workspace;
  final bool isWebRuntime;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('product-status-panel'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(copy.previewTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _ProductSignal(
            label: _zh ? '当前状态' : 'Current status',
            value: _zh ? '等待输入' : 'Waiting for input',
            wide: true,
          ),
          _ProductSignal(
            label: _zh ? '输出位置' : 'Output path',
            value: copy.outputPath(workspace),
            wide: true,
          ),
          _ProductSignal(
            label: _zh ? '本地执行' : 'Local execution',
            value: isWebRuntime
                ? (_zh ? 'Web 中安全展示' : 'Web-safe view')
                : (_zh ? '桌面本地可用' : 'Available on desktop'),
            wide: true,
          ),
        ],
      ),
    );
  }
}

class _ProductSignal extends StatelessWidget {
  const _ProductSignal({
    required this.label,
    required this.value,
    this.wide = false,
  });

  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: wide ? double.infinity : 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AdvancedBoundaryDetails extends StatelessWidget {
  const _AdvancedBoundaryDetails({
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
      key: const Key('advanced-boundary-details'),
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
      title: Text(_zh ? '高级边界详情' : 'Advanced Boundary Details',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800)),
      subtitle: Text(_zh
          ? '展开后查看契约、后端矩阵、Core 操作和审计证据。'
          : 'Expand to inspect contracts, backend matrices, Core actions, and audit evidence.'),
      children: [
        if (skillFactoryWorkflow != null) ...[
          SkillFactoryWorkflowSurface(
            localeCode: localeCode,
            workflow: skillFactoryWorkflow,
          ),
          const SizedBox(height: 20),
        ],
        if (cards.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: columns == 1 ? 204 : 188,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) => _WorkbenchCard(
              title: cards[index].title,
              body: cards[index].body,
              localeCode: localeCode,
            ),
          ),
        if (parserBackends != null) ...[
          if (cards.isNotEmpty) const SizedBox(height: 20),
          ParserBackendEvidenceDashboard(
            matrix: parserBackends!,
            localeCode: localeCode,
          ),
        ],
        if (corePanels.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(_zh ? '本地 Core 执行详情' : 'Local Core Execution Details',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (var index = 0; index < corePanels.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            corePanels[index],
          ],
        ],
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
    'template-library',
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
    final textTheme = Theme.of(context).textTheme;
    return Card(
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
            FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: textTheme.labelMedium,
                ),
                child: Text(localeCode == 'zh-CN' ? '显示边界' : 'Show boundary')),
          ],
        ),
      ),
    );
  }
}
