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

const supportedLocaleCodes = <String>['zh-CN', 'en-US'];

const pages = <WorkbenchPage>[
  WorkbenchPage(
      'dashboard',
      'Dashboard',
      '工作台',
      'A guided local workbench for turning source material into a validated Agent.',
      '把本地资料加工为可验证 Agent 的引导式工作台。',
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
      'Agent',
      'Agent',
      'Create an Agent configuration and export artifact without claiming runtime completion.',
      '创建 Agent 配置与导出产物，不宣称运行时已完成。',
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
          Text(localeCode == 'zh-CN' ? '黑糖' : 'HeiTang',
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
              const SizedBox(width: 10),
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
              const SizedBox(width: 10),
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
          const SizedBox(height: 12),
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
    case 'import-parsing':
      return Icons.upload_file_outlined;
    case 'knowledge-package-management':
      return Icons.inventory_2_outlined;
    case 'skill-factory':
      return Icons.extension_outlined;
    case 'agent-factory-runtime':
      return Icons.smart_toy_outlined;
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

class _ProductPageOverview extends StatefulWidget {
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

  @override
  State<_ProductPageOverview> createState() => _ProductPageOverviewState();
}

class _ProductPageOverviewState extends State<_ProductPageOverview> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final page = widget.page.id;
    final tabCounts = <String, int>{
      'knowledge-package-management': 3,
      'agent-factory-runtime': 5,
      'reports-audit': 3,
      'workspace': 3,
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
        'knowledge-package-management' => _KnowledgeProductWorkflow(
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
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colors.onPrimary, size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
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
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < tabs.length; index++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                selected: selectedIndex == index,
                label: Text(tabs[index]),
                onSelected: (_) => onSelected(index),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
        ],
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
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;
  final String? subtitle;
  final String? keyName;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: keyName == null ? null : Key(keyName!),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent
            ? colors.primary.withValues(alpha: 0.05)
            : colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent
              ? colors.primary.withValues(alpha: 0.24)
              : colors.outlineVariant,
        ),
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
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    )),
          ],
          if (children.isNotEmpty) const SizedBox(height: 10),
          ...children,
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 34,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 40,
        columnSpacing: 20,
        horizontalMargin: 10,
        headingTextStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w900,
            ),
        dataTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        columns: [
          for (final column in columns) DataColumn(label: Text(column))
        ],
        rows: [
          for (final row in rows)
            DataRow(cells: [
              for (final value in row)
                DataCell(Text(value, overflow: TextOverflow.ellipsis)),
            ]),
        ],
      ),
    );
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 132,
            child: Text(label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    )),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
    return Tooltip(
      message: reason,
      child: OutlinedButton.icon(
        onPressed: null,
        icon: Icon(icon),
        label: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _DisplayAction extends StatelessWidget {
  const _DisplayAction({
    required this.label,
    this.icon = Icons.visibility_outlined,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}

class _ImportProductWorkflow extends StatelessWidget {
  const _ImportProductWorkflow({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductHeader(
          icon: Icons.upload_file_outlined,
          title: _zh ? '导入资料' : 'Import Materials',
          description: _zh
              ? '先建立真实文件队列，再解析、切分并生成导入清单。'
              : 'Build a real file queue before parsing, splitting, and manifest output.',
          trailing: _StatePill(
            label: isWebRuntime
                ? (_zh ? 'Web 预览' : 'Web preview')
                : (_zh ? '桌面输入' : 'Desktop input'),
            icon: Icons.shield_outlined,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;
          final intake = _ProductPanel(
            keyName: 'import-intake-surface',
            accent: true,
            icon: Icons.folder_open_outlined,
            title: _zh ? '文件 / 文件夹输入' : 'File / Folder Intake',
            subtitle: _zh
                ? 'Web 预览不读取本地文件；桌面端接入真实路径后启用。'
                : 'Web preview does not read local files; desktop path enables intake.',
            children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final format in [
                  'PDF',
                  'DOCX',
                  'PPTX',
                  'XLSX',
                  'MD',
                  'HTML'
                ])
                  _StatePill(label: format),
              ]),
              const SizedBox(height: 10),
              _DisabledAction(
                label: _zh ? '选择本地文件或文件夹' : 'Choose local file or folder',
                reason: _zh ? '需要桌面端真实路径能力。' : 'Requires a real desktop path.',
                icon: Icons.add_to_drive_outlined,
              ),
            ],
          );
          final queue = _ProductPanel(
            keyName: 'import-queue',
            icon: Icons.list_alt_outlined,
            title: _zh ? '导入队列' : 'Import Queue',
            children: [
              _ProductTable(
                columns: _zh
                    ? ['资料', '类型', '解析', '状态', '下一步']
                    : ['Material', 'Type', 'Parsing', 'Status', 'Next'],
                rows: _zh
                    ? [
                        ['等待本地文件', '-', '未开始', '待输入', '选择真实路径'],
                        ['导入清单', 'manifest', '未生成', '等待', '创建导入清单'],
                      ]
                    : [
                        [
                          'Waiting for local files',
                          '-',
                          'Not started',
                          'Pending',
                          'Choose real path'
                        ],
                        [
                          'Import manifest',
                          'manifest',
                          'Not generated',
                          'Waiting',
                          'Create manifest'
                        ],
                      ],
              ),
            ],
          );
          final settings = _ProductPanel(
            keyName: 'parser-settings',
            icon: Icons.tune_outlined,
            title: _zh ? '解析设置' : 'Parser Settings',
            children: [
              _FieldRow(
                  label: _zh ? '解析范围' : 'Parsing scope',
                  value: _zh ? '等待资料' : 'Waiting for material'),
              const SizedBox(height: 8),
              _FieldRow(
                  label: _zh ? '切分策略' : 'Split strategy',
                  value: _zh ? '中等粒度预览' : 'Medium granularity preview'),
              const SizedBox(height: 8),
              _FieldRow(
                  label: _zh ? '失败处理' : 'Failure handling',
                  value: _zh ? '失败项可重试' : 'Failed items can retry'),
            ],
          );
          final manifest = _ProductPanel(
            keyName: 'manifest-preview',
            icon: Icons.description_outlined,
            title: _zh ? '输出清单预览' : 'Output Manifest Preview',
            subtitle: '$workspace/workbench_runs/import_manifest',
            children: [
              _ProductTable(
                columns: _zh ? ['字段', '值'] : ['Field', 'Value'],
                rows: _zh
                    ? [
                        ['文件数量', '0'],
                        ['解析报告', '未生成'],
                        ['完成状态', '等待真实结果'],
                      ]
                    : [
                        ['File count', '0'],
                        ['Parsing report', 'Not generated'],
                        ['Completion state', 'Waiting for real result'],
                      ],
              ),
            ],
          );
          if (!wide) {
            return Column(children: [
              intake,
              const SizedBox(height: 10),
              queue,
              const SizedBox(height: 10),
              settings,
              const SizedBox(height: 10),
              manifest,
            ]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              flex: 7,
              child: Column(children: [
                intake,
                const SizedBox(height: 10),
                queue,
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: Column(children: [
                settings,
                const SizedBox(height: 10),
                manifest,
              ]),
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
        ? ['知识包', '文档库', '检索验证']
        : ['Packages', 'Document Library', 'Retrieval Verification'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductHeader(
          icon: Icons.inventory_2_outlined,
          title: _zh ? '知识库' : 'Knowledge Package',
          description: _zh
              ? '管理知识包、文档解析结果和检索验证流程。'
              : 'Manage packages, parsed documents, and retrieval verification.',
        ),
        const SizedBox(height: 12),
        _PageTabs(
            tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
        const SizedBox(height: 12),
        if (selectedTab == 1)
          _DocumentLibraryView(zh: _zh)
        else if (selectedTab == 2)
          _RetrievalVerificationView(zh: _zh)
        else
          _KnowledgePackageListView(zh: _zh, workspace: workspace),
      ],
    );
  }
}

class _KnowledgePackageListView extends StatelessWidget {
  const _KnowledgePackageListView({required this.zh, required this.workspace});

  final bool zh;
  final String workspace;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final list = _ProductPanel(
        keyName: 'knowledge-package-list',
        icon: Icons.storage_outlined,
        title: zh ? '知识包列表' : 'Package List',
        children: [
          _ProductTable(
            columns: zh
                ? ['名称', '版本', '文档', '质量', '状态']
                : ['Name', 'Version', 'Docs', 'Quality', 'Status'],
            rows: zh
                ? [
                    ['等待构建的知识包', 'draft', '0', '等待评分', '待输入'],
                    ['导入资料集合', 'manifest', '0', '未验证', '未生成'],
                  ]
                : [
                    [
                      'Package waiting for build',
                      'draft',
                      '0',
                      'Waiting score',
                      'Pending input'
                    ],
                    [
                      'Imported material set',
                      'manifest',
                      '0',
                      'Not validated',
                      'Not generated'
                    ],
                  ],
          ),
        ],
      );
      final detail = _ProductPanel(
        keyName: 'selected-package-detail',
        icon: Icons.fact_check_outlined,
        title: zh ? '选中知识包详情' : 'Selected Package Detail',
        subtitle: '$workspace/workbench_runs/knowledge_package',
        children: [
          _FieldRow(label: zh ? '版本状态' : 'Version state', value: 'draft'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '质量门禁' : 'Quality gate',
              value: zh ? '等待真实结果' : 'Waiting for real result'),
          const SizedBox(height: 8),
          _DisabledAction(
            label: zh ? '构建知识包草稿' : 'Build package draft',
            reason: zh
                ? '需要解析内容和 Core 返回结果。'
                : 'Requires parsed content and Core result.',
            icon: Icons.build_outlined,
          ),
        ],
      );
      if (!wide) {
        return Column(children: [list, const SizedBox(height: 10), detail]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 7, child: list),
        const SizedBox(width: 10),
        Expanded(flex: 4, child: detail),
      ]);
    });
  }
}

class _DocumentLibraryView extends StatelessWidget {
  const _DocumentLibraryView({required this.zh});

  final bool zh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final docs = _ProductPanel(
        keyName: 'document-library',
        icon: Icons.article_outlined,
        title: zh ? '文档库' : 'Document Library',
        children: [
          _ProductTable(
            columns: zh
                ? ['文档', '来源', '解析', 'chunks', '问题']
                : ['Document', 'Source', 'Parsing', 'chunks', 'Issues'],
            rows: zh
                ? [
                    ['等待导入文档', '本地', '未开始', '0', '无'],
                    ['解析产物', '导入清单', '待生成', '0', '无证据'],
                  ]
                : [
                    [
                      'Waiting for documents',
                      'Local',
                      'Not started',
                      '0',
                      'None'
                    ],
                    [
                      'Parsed artifact',
                      'Import manifest',
                      'Pending generation',
                      '0',
                      'No evidence'
                    ],
                  ],
          ),
        ],
      );
      final detail = _ProductPanel(
        keyName: 'document-detail',
        icon: Icons.subject_outlined,
        title: zh ? '文档详情' : 'Document Detail',
        children: [
          _FieldRow(
              label: zh ? '元数据' : 'Metadata',
              value: zh ? '等待真实文件' : 'Waiting for real file'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '解析摘要' : 'Parse summary',
              value: zh ? '尚无解析结果' : 'No parse result yet'),
        ],
      );
      if (!wide) {
        return Column(children: [docs, const SizedBox(height: 10), detail]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 7, child: docs),
        const SizedBox(width: 10),
        Expanded(flex: 4, child: detail),
      ]);
    });
  }
}

class _RetrievalVerificationView extends StatelessWidget {
  const _RetrievalVerificationView({required this.zh});

  final bool zh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final query = _ProductPanel(
        keyName: 'retrieval-workflow',
        icon: Icons.manage_search_outlined,
        title: zh ? '检索验证' : 'Retrieval Verification',
        subtitle:
            zh ? '等待真实查询和证据结果。' : 'Waiting for real query and evidence result.',
        children: [
          _FieldRow(
              label: zh ? '查询' : 'Query',
              value: zh ? '等待输入' : 'Waiting for input'),
          const SizedBox(height: 8),
          _ProductTable(
            columns: zh ? ['证据', '评分', '状态'] : ['Evidence', 'Score', 'Status'],
            rows: zh
                ? [
                    ['等待检索结果', '-', '未搜索'],
                    ['证据选择', '-', '未验证'],
                  ]
                : [
                    ['Waiting for retrieval result', '-', 'Not searched'],
                    ['Evidence selection', '-', 'Not validated'],
                  ],
          ),
        ],
      );
      final metrics = _ProductPanel(
        icon: Icons.analytics_outlined,
        title: zh ? '验证指标' : 'Verification Metrics',
        children: [
          _FieldRow(
              label: zh ? '准确性' : 'Accuracy', value: zh ? '等待' : 'Waiting'),
          const SizedBox(height: 8),
          _FieldRow(label: zh ? '矛盾项' : 'Contradictions', value: '0'),
          const SizedBox(height: 8),
          _DisabledAction(
            label: zh ? '运行检索验证' : 'Run retrieval verification',
            reason: zh
                ? '未连接真实查询输入和 Core 检索结果。'
                : 'No real query input or Core retrieval result.',
            icon: Icons.play_arrow_outlined,
          ),
        ],
      );
      if (!wide) {
        return Column(children: [query, const SizedBox(height: 10), metrics]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 7, child: query),
        const SizedBox(width: 10),
        Expanded(flex: 4, child: metrics),
      ]);
    });
  }
}

class _SkillBuilderProductWorkflow extends StatelessWidget {
  const _SkillBuilderProductWorkflow({
    required this.localeCode,
    required this.workspace,
  });

  final String localeCode;
  final String workspace;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.extension_outlined,
        title: _zh ? 'Skill 生成' : 'Skill Builder',
        description: _zh
            ? '配置元数据、知识源和输出结构，生成前保持草稿边界。'
            : 'Configure metadata, source, and output structure while staying draft-bound.',
      ),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        final config = _ProductPanel(
          keyName: 'skill-metadata-source-config',
          icon: Icons.edit_note_outlined,
          title: _zh ? '元数据与来源配置' : 'Metadata and Source Configuration',
          children: [
            _FieldRow(
                label: _zh ? 'Skill 名称' : 'Skill name',
                value: _zh ? '等待输入' : 'Waiting for input'),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '知识源' : 'Knowledge source',
                value: _zh ? '等待知识包草稿' : 'Waiting for package draft'),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '生成模式' : 'Generation mode',
                value: _zh ? '知识包到 Skill' : 'Package to Skill'),
          ],
        );
        final output = _ProductPanel(
          keyName: 'skill-output-preview',
          icon: Icons.folder_zip_outlined,
          title: _zh ? '输出结构预览' : 'Output Structure Preview',
          subtitle: '$workspace/workbench_runs/skill_draft',
          children: [
            _ProductTable(
              columns: _zh ? ['路径', '用途', '状态'] : ['Path', 'Purpose', 'Status'],
              rows: _zh
                  ? [
                      ['SKILL.md', '说明文档', '预览'],
                      ['prompts/', '提示词', '预览'],
                      ['manifests/', '清单', '预览'],
                      ['reports/', '验证报告', '等待'],
                    ]
                  : [
                      ['SKILL.md', 'Documentation', 'Preview'],
                      ['prompts/', 'Prompts', 'Preview'],
                      ['manifests/', 'Manifests', 'Preview'],
                      ['reports/', 'Validation report', 'Waiting'],
                    ],
            ),
          ],
        );
        final validation = _ProductPanel(
          keyName: 'skill-validation-summary',
          icon: Icons.rule_outlined,
          title: _zh ? '验证摘要' : 'Validation Summary',
          children: [
            _FieldRow(
                label: _zh ? '覆盖率' : 'Coverage',
                value: _zh ? '等待报告' : 'Waiting for report'),
            const SizedBox(height: 8),
            _FieldRow(
                label: _zh ? '可安装性' : 'Installability',
                value: _zh ? '等待报告' : 'Waiting for report'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _DisabledAction(
                label: _zh ? '生成 Skill 草稿' : 'Generate Skill draft',
                reason: _zh
                    ? '需要真实知识包草稿和 Core 操作结果。'
                    : 'Requires real package draft and Core result.',
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
            const SizedBox(height: 10),
            output,
            const SizedBox(height: 10),
            validation
          ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              flex: 6,
              child: Column(
                  children: [config, const SizedBox(height: 10), validation])),
          const SizedBox(width: 10),
          Expanded(flex: 5, child: output),
        ]);
      }),
    ]);
  }
}

class _AgentProductWorkflow extends StatelessWidget {
  const _AgentProductWorkflow({
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
        ? ['创建 Agent', '简单模式', '高级模式', '绑定', '预览与导出']
        : [
            'Create Agent',
            'Simple Mode',
            'Advanced Mode',
            'Bindings',
            'Preview / Export'
          ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.smart_toy_outlined,
        title: 'Agent',
        description: _zh
            ? '创建 Agent 草稿，绑定知识包和多个 Skill，预览配置与包导出。'
            : 'Create an Agent draft, bind packages and multiple Skills, and preview configuration plus package export.',
      ),
      const SizedBox(height: 12),
      _PageTabs(
          tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
      const SizedBox(height: 12),
      switch (selectedTab) {
        1 => _AgentModeView(zh: _zh, advanced: false),
        2 => _AgentModeView(zh: _zh, advanced: true),
        3 => _AgentBindingsView(zh: _zh),
        4 => _AgentExportView(zh: _zh, workspace: workspace),
        _ => _AgentCreateView(zh: _zh),
      },
    ]);
  }
}

class _AgentCreateView extends StatelessWidget {
  const _AgentCreateView({required this.zh});
  final bool zh;

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'agent-create-edit-form',
      icon: Icons.edit_note_outlined,
      title: zh ? '创建 / 编辑 Agent' : 'Create / Edit Agent',
      children: [
        _FieldRow(
            label: zh ? '名称' : 'Name',
            value: zh ? '等待输入' : 'Waiting for input'),
        const SizedBox(height: 8),
        _FieldRow(
            label: zh ? '目标任务' : 'Target task',
            value: zh ? '等待输入' : 'Waiting for input'),
        const SizedBox(height: 8),
        _FieldRow(
            label: zh ? '描述' : 'Description',
            value: zh ? '草稿预览' : 'Draft preview'),
        const SizedBox(height: 10),
        _DisabledAction(
          label: zh ? '创建 Agent 草稿' : 'Create Agent draft',
          reason: zh
              ? '需要真实知识包和 Skill 草稿。'
              : 'Requires real package and Skill draft.',
          icon: Icons.add_circle_outline,
        ),
      ],
    );
  }
}

class _AgentModeView extends StatelessWidget {
  const _AgentModeView({required this.zh, required this.advanced});
  final bool zh;
  final bool advanced;

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: advanced ? 'agent-advanced-mode' : 'agent-simple-mode',
      icon: advanced ? Icons.tune_outlined : Icons.bolt_outlined,
      title: advanced
          ? (zh ? '高级模式' : 'Advanced Mode')
          : (zh ? '简单模式' : 'Simple Mode'),
      subtitle: advanced
          ? (zh
              ? '展示允许的模型、工具、权限和分区字段。'
              : 'Shows allowed model, tool, permission, and partition fields.')
          : (zh
              ? '最少字段创建可验证 Agent 草稿。'
              : 'Minimal fields for a verifiable Agent draft.'),
      children: [
        _FieldRow(
            label: zh ? '模型配置' : 'Model configuration',
            value: zh ? '预览' : 'Preview'),
        const SizedBox(height: 8),
        if (advanced) ...[
          _FieldRow(
              label: zh ? 'Tool / MCP' : 'Tool / MCP',
              value: zh ? '等待配置' : 'Waiting for configuration'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '权限策略' : 'Permission policy',
              value: zh ? '预览' : 'Preview'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '工作区分区' : 'Workspace Partitions',
              value: zh ? '分区声明预览' : 'Partition declaration preview'),
        ] else
          _FieldRow(
              label: zh ? '输出语气' : 'Output style',
              value: zh ? '默认' : 'Default'),
      ],
    );
  }
}

class _AgentBindingsView extends StatelessWidget {
  const _AgentBindingsView({required this.zh});
  final bool zh;

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'agent-bindings',
      icon: Icons.hub_outlined,
      title:
          zh ? '知识包与多 Skill 绑定' : 'Knowledge Package and Multi-Skill Bindings',
      children: [
        _ProductTable(
          columns: zh ? ['绑定项', '来源', '状态'] : ['Binding', 'Source', 'Status'],
          rows: zh
              ? [
                  ['目标知识包', '知识库', '等待草稿'],
                  ['Skill 1', 'Skill 生成', '等待草稿'],
                  ['Skill 2', 'Skill 生成', '可选'],
                ]
              : [
                  ['Target package', 'Knowledge Package', 'Waiting for draft'],
                  ['Skill 1', 'Skill Builder', 'Waiting for draft'],
                  ['Skill 2', 'Skill Builder', 'Optional'],
                ],
        ),
      ],
    );
  }
}

class _AgentExportView extends StatelessWidget {
  const _AgentExportView({required this.zh, required this.workspace});
  final bool zh;
  final String workspace;

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'agent-preview-export',
      icon: Icons.archive_outlined,
      title: zh ? '预览与包导出' : 'Preview and Package Export',
      subtitle: '$workspace/workbench_runs/agent_package',
      children: [
        _ProductTable(
          columns: zh ? ['文件', '用途', '状态'] : ['File', 'Purpose', 'Status'],
          rows: zh
              ? [
                  ['agent.yaml', 'Agent 清单', '预览'],
                  ['skills/', 'Skill 引用', '等待'],
                  ['workspace_partitions/', '分区声明', '仅展示'],
                  ['reports/', '验证报告', '等待'],
                ]
              : [
                  ['agent.yaml', 'Agent manifest', 'Preview'],
                  ['skills/', 'Skill reference', 'Waiting'],
                  [
                    'workspace_partitions/',
                    'Partition declaration',
                    'Display only'
                  ],
                  ['reports/', 'Validation report', 'Waiting'],
                ],
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
        title: _zh ? '验证与导出' : 'Validate & Export',
        description: _zh
            ? '检查输出、报告和证据，再准备受控导出。'
            : 'Check outputs, reports, and evidence before controlled export.',
      ),
      const SizedBox(height: 12),
      _PageTabs(
          tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
      const SizedBox(height: 12),
      if (selectedTab == 1)
        _ReportsEvidenceView(zh: _zh)
      else if (selectedTab == 2)
        _ControlledExportView(zh: _zh, workspace: workspace)
      else
        _ValidationChecklistView(zh: _zh),
    ]);
  }
}

class _ValidationChecklistView extends StatelessWidget {
  const _ValidationChecklistView({required this.zh});
  final bool zh;

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'validation-checklist',
      icon: Icons.checklist_outlined,
      title: zh ? '验证清单' : 'Validation Checklist',
      children: [
        _ProductTable(
          columns: zh ? ['检查项', '状态', '证据'] : ['Check', 'Status', 'Evidence'],
          rows: zh
              ? [
                  ['输出路径', '等待', '无真实产物'],
                  ['报告', '等待', '无真实报告'],
                  ['恢复路径', '等待', '无失败样本'],
                ]
              : [
                  ['Output path', 'Waiting', 'No real artifact'],
                  ['Reports', 'Waiting', 'No real report'],
                  ['Recovery path', 'Waiting', 'No failure sample'],
                ],
        ),
      ],
    );
  }
}

class _ReportsEvidenceView extends StatelessWidget {
  const _ReportsEvidenceView({required this.zh});
  final bool zh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final list = _ProductPanel(
        keyName: 'report-evidence-list',
        icon: Icons.receipt_long_outlined,
        title: zh ? '报告与证据' : 'Reports and Evidence',
        children: [
          _ProductTable(
            columns: zh ? ['报告', '状态', '证据'] : ['Report', 'Status', 'Evidence'],
            rows: zh
                ? [
                    ['validation_report', '等待', '无真实报告'],
                    ['governance_report', '可展示', 'fixture'],
                  ]
                : [
                    ['validation_report', 'Waiting', 'No real report'],
                    ['governance_report', 'Displayable', 'fixture'],
                  ],
          ),
        ],
      );
      final detail = _ProductPanel(
        keyName: 'selected-report-detail',
        icon: Icons.plagiarism_outlined,
        title: zh ? '选中报告详情' : 'Selected Report Detail',
        children: [
          _FieldRow(
              label: zh ? '摘要' : 'Summary',
              value: zh ? '等待报告产物' : 'Waiting for report artifact'),
          const SizedBox(height: 8),
          _FieldRow(
              label: zh ? '门禁影响' : 'Gate impact',
              value: zh ? '未通过' : 'Not passed'),
        ],
      );
      if (!wide) {
        return Column(children: [list, const SizedBox(height: 10), detail]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 7, child: list),
        const SizedBox(width: 10),
        Expanded(flex: 4, child: detail),
      ]);
    });
  }
}

class _ControlledExportView extends StatelessWidget {
  const _ControlledExportView({required this.zh, required this.workspace});
  final bool zh;
  final String workspace;

  @override
  Widget build(BuildContext context) {
    return _ProductPanel(
      keyName: 'controlled-export-summary',
      icon: Icons.outbox_outlined,
      title: zh ? '受控导出摘要' : 'Controlled Export Summary',
      subtitle: '$workspace/workbench_runs/validation_report',
      children: [
        _FieldRow(
            label: zh ? '工作台包' : 'Workbench package',
            value: zh ? '等待验证' : 'Waiting for validation'),
        const SizedBox(height: 8),
        _FieldRow(
            label: zh ? '导出状态' : 'Export state',
            value: zh ? '未导出' : 'Not exported'),
        const SizedBox(height: 10),
        _DisabledAction(
          label: zh ? '准备受控导出' : 'Prepare controlled export',
          reason: zh ? '需要真实验证结果。' : 'Requires real validation result.',
          icon: Icons.archive_outlined,
        ),
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
  });

  final String localeCode;
  final String workspace;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;
  final bool isWebRuntime;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final tabs = _zh
        ? ['工作区', '语言与主题', '安全']
        : ['Workspace', 'Language and Theme', 'Safety'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ProductHeader(
        icon: Icons.settings_outlined,
        title: _zh ? '设置' : 'Settings',
        description: _zh
            ? '管理工作区、语言主题和本地优先安全策略。'
            : 'Manage workspace, language/theme, and local-first safety policy.',
      ),
      const SizedBox(height: 12),
      _PageTabs(
          tabs: tabs, selectedIndex: selectedTab, onSelected: onTabSelected),
      const SizedBox(height: 12),
      _ProductPanel(
        keyName: 'settings-groups',
        icon: selectedTab == 1
            ? Icons.language_outlined
            : selectedTab == 2
                ? Icons.shield_outlined
                : Icons.folder_outlined,
        title: tabs[selectedTab],
        children: selectedTab == 1
            ? [
                _FieldRow(
                    label: _zh ? '当前语言' : 'Current language',
                    value: _zh ? '中文' : 'English'),
                const SizedBox(height: 8),
                _FieldRow(
                    label: _zh ? '主题' : 'Theme',
                    value: _zh ? '跟随切换' : 'Switchable'),
              ]
            : selectedTab == 2
                ? [
                    _FieldRow(
                        label: _zh ? '云服务' : 'Cloud services',
                        value: _zh ? '默认关闭' : 'Off by default'),
                    const SizedBox(height: 8),
                    _FieldRow(
                        label: _zh ? '敏感信息' : 'Sensitive data',
                        value: _zh ? '不收集' : 'Not collected'),
                    const SizedBox(height: 8),
                    _FieldRow(
                        label: _zh ? '本地执行' : 'Local execution',
                        value: isWebRuntime
                            ? (_zh ? 'Web 安全展示' : 'Web-safe view')
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
          const SizedBox(height: 12),
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
              const SizedBox(height: 12),
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
          const SizedBox(height: 12),
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
              const SizedBox(width: 10),
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
          const SizedBox(height: 10),
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
        const SizedBox(width: 10),
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
