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

  bool get _zh => widget.localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final copy = _ProductPageCopy.forPage(widget.page.id, _zh);
    final activeTab = copy.tabs[selectedTab.clamp(0, copy.tabs.length - 1)];
    return Container(
      key: Key('dense-page-workbench-${widget.page.id}'),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DensePageHeader(
              localeCode: widget.localeCode,
              copy: copy,
              isWebRuntime: widget.isWebRuntime,
            ),
            const SizedBox(height: 12),
            _DenseTabStrip(
              tabs: copy.tabs,
              selectedIndex: selectedTab,
              onSelected: (index) => setState(() => selectedTab = index),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final main = _DenseTabBody(
                  localeCode: widget.localeCode,
                  tab: activeTab,
                );
                final rail = _DensePageRail(
                  localeCode: widget.localeCode,
                  copy: copy,
                  workspace: widget.workspace,
                  isWebRuntime: widget.isWebRuntime,
                );
                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      main,
                      const SizedBox(height: 12),
                      rail,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: main),
                    const SizedBox(width: 12),
                    SizedBox(width: 328, child: rail),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _ActionCapabilityMatrix(
              localeCode: widget.localeCode,
              actions: copy.actions,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPageBadge extends StatelessWidget {
  const _ProductPageBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  )),
        ],
      ),
    );
  }
}

enum _ActionCapability {
  enabledReal,
  disabledBoundary,
  displayOnly,
  omitted,
}

extension _ActionCapabilityCopy on _ActionCapability {
  String label(bool zh) {
    switch (this) {
      case _ActionCapability.enabledReal:
        return zh ? '已接入' : 'Enabled';
      case _ActionCapability.disabledBoundary:
        return zh ? '边界禁用' : 'Boundary disabled';
      case _ActionCapability.displayOnly:
        return zh ? '仅展示' : 'Display only';
      case _ActionCapability.omitted:
        return zh ? '不显示' : 'Omitted';
    }
  }

  Color color(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    switch (this) {
      case _ActionCapability.enabledReal:
        return Colors.green.shade700;
      case _ActionCapability.disabledBoundary:
        return colors.error;
      case _ActionCapability.displayOnly:
        return colors.primary;
      case _ActionCapability.omitted:
        return colors.onSurfaceVariant;
    }
  }
}

class _CapabilityAction {
  const _CapabilityAction({
    required this.zhLabel,
    required this.enLabel,
    required this.capability,
    required this.zhReason,
    required this.enReason,
  });

  final String zhLabel;
  final String enLabel;
  final _ActionCapability capability;
  final String zhReason;
  final String enReason;

  String label(bool zh) => zh ? zhLabel : enLabel;
  String reason(bool zh) => zh ? zhReason : enReason;
}

class _DensePageTab {
  const _DensePageTab({
    required this.zhTitle,
    required this.enTitle,
    required this.zhSubtitle,
    required this.enSubtitle,
    required this.icon,
    required this.columns,
    required this.rows,
    required this.metrics,
  });

  final String zhTitle;
  final String enTitle;
  final String zhSubtitle;
  final String enSubtitle;
  final IconData icon;
  final List<String> columns;
  final List<List<String>> rows;
  final List<_DenseMetric> metrics;

  String title(bool zh) => zh ? zhTitle : enTitle;
  String subtitle(bool zh) => zh ? zhSubtitle : enSubtitle;
}

class _DenseMetric {
  const _DenseMetric(this.zhLabel, this.enLabel, this.value);

  final String zhLabel;
  final String enLabel;
  final String value;

  String label(bool zh) => zh ? zhLabel : enLabel;
}

class _ProductPageCopy {
  const _ProductPageCopy({
    required this.title,
    required this.body,
    required this.statusLabel,
    required this.outputSuffix,
    required this.icon,
    required this.tabs,
    required this.actions,
  });

  final String title;
  final String body;
  final String statusLabel;
  final String outputSuffix;
  final IconData icon;
  final List<_DensePageTab> tabs;
  final List<_CapabilityAction> actions;

  String outputPath(String workspace) => '$workspace/$outputSuffix';

  static _ProductPageCopy forPage(String id, bool zh) {
    switch (id) {
      case 'import-parsing':
        return _ProductPageCopy(
          title: zh ? '导入资料' : 'Import Materials',
          body: zh
              ? '以本地文件队列、解析设置和失败恢复为中心，不伪造导入完成。'
              : 'Center the page on local file intake, parser settings, and recovery without fabricated import completion.',
          statusLabel: zh ? '等待本地输入' : 'Waiting for local input',
          outputSuffix: 'workbench_runs/import_manifest',
          icon: Icons.upload_file_outlined,
          tabs: _importTabs(zh),
          actions: _importActions(),
        );
      case 'knowledge-package-management':
        return _ProductPageCopy(
          title: zh ? '知识库' : 'Knowledge Package',
          body: zh
              ? '以知识包、文档库、检索验证和输出目标组成紧凑工作台。'
              : 'Expose packages, document library, retrieval verification, and output targets as a compact workbench.',
          statusLabel: zh ? '等待解析内容' : 'Waiting for parsed content',
          outputSuffix: 'workbench_runs/knowledge_package',
          icon: Icons.inventory_2_outlined,
          tabs: _knowledgeTabs(zh),
          actions: _knowledgeActions(),
        );
      case 'skill-factory':
        return _ProductPageCopy(
          title: zh ? 'Skill 生成' : 'Skill Builder',
          body: zh
              ? '以元数据、知识源、输出结构和验证报告组织 Skill 草稿生成。'
              : 'Organize Skill draft generation around metadata, knowledge source, output structure, and validation reports.',
          statusLabel: zh ? '等待知识包草稿' : 'Waiting for package draft',
          outputSuffix: 'workbench_runs/skill_draft',
          icon: Icons.auto_awesome_motion_outlined,
          tabs: _skillTabs(zh),
          actions: _skillActions(),
        );
      case 'agent-factory-runtime':
        return _ProductPageCopy(
          title: 'Agent',
          body: zh
              ? '配置 Agent、绑定知识与 Skill，并预览包导出产物；不展示运行时完成。'
              : 'Configure an Agent, bind knowledge and Skills, and preview package export artifacts without runtime completion claims.',
          statusLabel: zh ? '等待 Skill 草稿' : 'Waiting for Skill draft',
          outputSuffix: 'workbench_runs/agent_package',
          icon: Icons.developer_board_outlined,
          tabs: _agentTabs(zh),
          actions: _agentActions(),
        );
      case 'reports-audit':
        return _ProductPageCopy(
          title: zh ? '验证与导出' : 'Validate & Export',
          body: zh
              ? '作为最终门禁查看清单、报告、证据和受控导出边界。'
              : 'Use the final gate to review manifests, reports, evidence, and controlled export boundaries.',
          statusLabel: zh ? '等待草稿输出' : 'Waiting for draft outputs',
          outputSuffix: 'workbench_runs/validation_report',
          icon: Icons.fact_check_outlined,
          tabs: _validateTabs(zh),
          actions: _validateActions(),
        );
      default:
        return _ProductPageCopy(
          title: zh ? '设置' : 'Settings',
          body: zh
              ? '集中查看工作区路径、本地执行、语言主题和安全边界。'
              : 'Review workspace paths, local execution, language/theme, and safety boundaries in one place.',
          statusLabel: zh ? '本地优先' : 'Local first',
          outputSuffix: 'workbench_runs/settings',
          icon: Icons.settings_outlined,
          tabs: _settingsTabs(zh),
          actions: _settingsActions(),
        );
    }
  }
}

List<_DensePageTab> _importTabs(bool zh) => [
      _DensePageTab(
        zhTitle: '导入队列',
        enTitle: 'Import Queue',
        zhSubtitle: '展示本地资料等待状态，不伪造上传完成。',
        enSubtitle:
            'Shows local material waiting states without fabricated upload completion.',
        icon: Icons.upload_file_outlined,
        columns: zh
            ? ['资料', '类型', '状态', '下一步']
            : ['Material', 'Type', 'Status', 'Next'],
        rows: zh
            ? [
                ['等待本地文件', 'PDF/DOCX/PPTX', '待输入', '选择真实路径'],
                ['导入清单', 'manifest', '未生成', '等待 Core 结果'],
                ['解析报告', 'report', '未生成', '先完成导入'],
              ]
            : [
                [
                  'Waiting for local files',
                  'PDF/DOCX/PPTX',
                  'Pending input',
                  'Choose real path'
                ],
                [
                  'Import manifest',
                  'manifest',
                  'Not generated',
                  'Wait for Core result'
                ],
                [
                  'Parsing report',
                  'report',
                  'Not generated',
                  'Complete import first'
                ],
              ],
        metrics: [
          _DenseMetric(
              zh ? '支持格式' : 'Supported', zh ? '支持格式' : 'Supported', '6'),
          _DenseMetric(zh ? '真实完成' : 'Real completion',
              zh ? '真实完成' : 'Real completion', '0%'),
          _DenseMetric(zh ? '失败项' : 'Failures', zh ? '失败项' : 'Failures', '0'),
        ],
      ),
      _DensePageTab(
        zhTitle: '解析设置',
        enTitle: 'Parsing Settings',
        zhSubtitle: '解析策略和切分预览保持展示态。',
        enSubtitle:
            'Parser strategy and splitting preview remain display-only.',
        icon: Icons.tune_outlined,
        columns: zh ? ['设置', '当前值', '能力'] : ['Setting', 'Value', 'Capability'],
        rows: zh
            ? [
                ['解析范围', '等待资料', 'display_only'],
                ['切分策略', '中等粒度', 'display_only'],
                ['重型后端', '默认不启用', 'disabled_boundary'],
              ]
            : [
                ['Parsing scope', 'Waiting for material', 'display_only'],
                ['Split strategy', 'Medium granularity', 'display_only'],
                ['Heavy backend', 'Off by default', 'disabled_boundary'],
              ],
        metrics: const [
          _DenseMetric('默认云服务', 'Cloud default', 'off'),
          _DenseMetric('CLI', 'CLI', 'safe boundary'),
        ],
      ),
    ];

List<_CapabilityAction> _importActions() => const [
      _CapabilityAction(
        zhLabel: '选择本地资料',
        enLabel: 'Choose local material',
        capability: _ActionCapability.disabledBoundary,
        zhReason: 'Web 预览不能读取本地文件；桌面端真实路径接入后才可启用。',
        enReason:
            'The Web preview cannot read local files; enable only after a real desktop path is available.',
      ),
      _CapabilityAction(
        zhLabel: '生成导入清单',
        enLabel: 'Create import manifest',
        capability: _ActionCapability.disabledBoundary,
        zhReason: '需要真实输入和已接受 Core 操作结果。',
        enReason: 'Requires real input and an accepted Core operation result.',
      ),
      _CapabilityAction(
        zhLabel: '查看输出路径',
        enLabel: 'View output path',
        capability: _ActionCapability.displayOnly,
        zhReason: '输出路径契约可展示，但不代表文件已生成。',
        enReason:
            'The output path contract can be displayed, but it does not mean the file exists.',
      ),
    ];

List<_DensePageTab> _knowledgeTabs(bool zh) => [
      _DensePageTab(
        zhTitle: '知识包',
        enTitle: 'Packages',
        zhSubtitle: '知识包草稿、质量门禁和版本状态。',
        enSubtitle: 'Package drafts, quality gates, and version state.',
        icon: Icons.inventory_2_outlined,
        columns: zh
            ? ['名称', '版本', '来源', '状态']
            : ['Name', 'Version', 'Sources', 'Status'],
        rows: zh
            ? [
                ['等待构建的知识包', 'draft', '0', '待输入'],
                ['导入资料集合', 'manifest', '0', '未验证'],
                ['输出索引', 'local', '0', '未生成'],
              ]
            : [
                ['Package waiting for build', 'draft', '0', 'Pending input'],
                ['Imported material set', 'manifest', '0', 'Not validated'],
                ['Output index', 'local', '0', 'Not generated'],
              ],
        metrics: const [
          _DenseMetric('chunks', 'chunks', '0'),
          _DenseMetric('quality', 'quality', 'pending'),
        ],
      ),
      _DensePageTab(
        zhTitle: '文档库',
        enTitle: 'Document Library',
        zhSubtitle: '作为知识库内的二级页展示文档状态。',
        enSubtitle:
            'Document status appears as a secondary page inside Knowledge Package.',
        icon: Icons.article_outlined,
        columns: zh
            ? ['文档', '解析', 'chunks', '问题']
            : ['Document', 'Parsing', 'chunks', 'Issues'],
        rows: zh
            ? [
                ['等待导入文档', '未开始', '0', '无'],
                ['解析产物', '待生成', '0', '无证据'],
              ]
            : [
                ['Waiting for documents', 'Not started', '0', 'None'],
                ['Parsed artifact', 'Pending generation', '0', 'No evidence'],
              ],
        metrics: const [
          _DenseMetric('docs', 'docs', '0'),
          _DenseMetric('parsed', 'parsed', '0'),
        ],
      ),
      _DensePageTab(
        zhTitle: '检索与验证',
        enTitle: 'Retrieval & Verification',
        zhSubtitle: '检索验证是二级工作区，不新增一级导航。',
        enSubtitle:
            'Retrieval verification is a secondary workspace, not another primary nav item.',
        icon: Icons.manage_search_outlined,
        columns: zh
            ? ['查询', '证据', '状态', '边界']
            : ['Query', 'Evidence', 'Status', 'Boundary'],
        rows: zh
            ? [
                ['等待查询', '0', '未搜索', 'display_only'],
                ['证据选择', '0', '未验证', 'disabled_boundary'],
              ]
            : [
                ['Waiting for query', '0', 'Not searched', 'display_only'],
                [
                  'Evidence selection',
                  '0',
                  'Not validated',
                  'disabled_boundary'
                ],
              ],
        metrics: const [
          _DenseMetric('accuracy', 'accuracy', 'pending'),
          _DenseMetric('contradictions', 'contradictions', '0'),
        ],
      ),
      _DensePageTab(
        zhTitle: '输出目标',
        enTitle: 'Output Targets',
        zhSubtitle: '本地索引、向量库和对象存储均保持边界声明。',
        enSubtitle:
            'Local index, vector store, and object storage remain boundary declarations.',
        icon: Icons.account_tree_outlined,
        columns:
            zh ? ['目标', '路径/说明', '状态'] : ['Target', 'Path / note', 'Status'],
        rows: zh
            ? [
                ['本地索引', './workbench_runs/knowledge_package', '未生成'],
                ['向量库', 'provider required', 'disabled_boundary'],
                ['对象存储', 'cloud off by default', 'disabled_boundary'],
              ]
            : [
                [
                  'Local index',
                  './workbench_runs/knowledge_package',
                  'Not generated'
                ],
                ['Vector store', 'provider required', 'disabled_boundary'],
                ['Object storage', 'cloud off by default', 'disabled_boundary'],
              ],
        metrics: const [
          _DenseMetric('providers', 'providers', 'off'),
          _DenseMetric('storage', 'storage', 'local'),
        ],
      ),
    ];

List<_CapabilityAction> _knowledgeActions() => const [
      _CapabilityAction(
        zhLabel: '构建知识包草稿',
        enLabel: 'Build package draft',
        capability: _ActionCapability.disabledBoundary,
        zhReason: '需要解析内容和 Core 返回结果。',
        enReason: 'Requires parsed content and a Core result.',
      ),
      _CapabilityAction(
        zhLabel: '查看文档库',
        enLabel: 'View document library',
        capability: _ActionCapability.displayOnly,
        zhReason: '二级页可浏览等待状态。',
        enReason: 'The secondary page can display waiting state.',
      ),
      _CapabilityAction(
        zhLabel: '运行检索',
        enLabel: 'Run retrieval',
        capability: _ActionCapability.disabledBoundary,
        zhReason: '未连接真实查询输入和 Core 检索结果。',
        enReason: 'No real query input or Core retrieval result is connected.',
      ),
    ];

List<_DensePageTab> _skillTabs(bool zh) => [
      _DensePageTab(
        zhTitle: '生成器',
        enTitle: 'Builder',
        zhSubtitle: '紧凑展示元数据、来源和输出结构。',
        enSubtitle: 'Compact metadata, source, and output structure.',
        icon: Icons.auto_awesome_motion_outlined,
        columns: zh
            ? ['模块', '当前值', '能力']
            : ['Module', 'Current value', 'Capability'],
        rows: zh
            ? [
                ['Skill 元数据', '等待知识包', 'display_only'],
                ['知识源', '知识包草稿', 'disabled_boundary'],
                ['输出结构', 'SKILL.md / prompts / manifests', 'display_only'],
                ['验证', '等待报告', 'disabled_boundary'],
              ]
            : [
                ['Skill metadata', 'Waiting for package', 'display_only'],
                ['Knowledge source', 'Package draft', 'disabled_boundary'],
                [
                  'Output structure',
                  'SKILL.md / prompts / manifests',
                  'display_only'
                ],
                ['Validation', 'Waiting for report', 'disabled_boundary'],
              ],
        metrics: const [
          _DenseMetric('runtime claim', 'runtime claim', 'none'),
          _DenseMetric('report', 'report', 'pending'),
        ],
      ),
      _DensePageTab(
        zhTitle: '输出预览',
        enTitle: 'Output Preview',
        zhSubtitle: '文件树是预览，不代表已经生成。',
        enSubtitle: 'The file tree is a preview, not generated output.',
        icon: Icons.folder_zip_outlined,
        columns: zh ? ['路径', '类型', '状态'] : ['Path', 'Type', 'Status'],
        rows: zh
            ? [
                ['SKILL.md', '文档', '预览'],
                ['prompts/', '目录', '预览'],
                ['manifests/', '目录', '预览'],
                ['reports/', '目录', '等待验证'],
              ]
            : [
                ['SKILL.md', 'Document', 'Preview'],
                ['prompts/', 'Directory', 'Preview'],
                ['manifests/', 'Directory', 'Preview'],
                ['reports/', 'Directory', 'Waiting for validation'],
              ],
        metrics: const [
          _DenseMetric('files', 'files', '4'),
          _DenseMetric('generated', 'generated', '0'),
        ],
      ),
      _DensePageTab(
        zhTitle: '生成报告',
        enTitle: 'Generation Report',
        zhSubtitle: '报告指标必须来自证据，当前保持等待。',
        enSubtitle:
            'Report metrics must come from evidence; currently waiting.',
        icon: Icons.assessment_outlined,
        columns: zh ? ['指标', '状态', '说明'] : ['Metric', 'Status', 'Note'],
        rows: zh
            ? [
                ['覆盖率', '等待', '无真实报告'],
                ['可安装性', '等待', '无真实报告'],
                ['事实锚定', '等待', '无真实报告'],
              ]
            : [
                ['Coverage', 'Waiting', 'No real report'],
                ['Installability', 'Waiting', 'No real report'],
                ['Grounding', 'Waiting', 'No real report'],
              ],
        metrics: const [
          _DenseMetric('warnings', 'warnings', '0'),
          _DenseMetric('blocked', 'blocked', 'input'),
        ],
      ),
    ];

List<_CapabilityAction> _skillActions() => const [
      _CapabilityAction(
        zhLabel: '生成 Skill 草稿',
        enLabel: 'Generate Skill draft',
        capability: _ActionCapability.disabledBoundary,
        zhReason: '需要真实知识包草稿和 accepted Core action。',
        enReason: 'Requires a real package draft and accepted Core action.',
      ),
      _CapabilityAction(
        zhLabel: '查看输出树',
        enLabel: 'View output tree',
        capability: _ActionCapability.displayOnly,
        zhReason: '文件树为预览，不代表已生成。',
        enReason:
            'The file tree is a preview and does not mean files were generated.',
      ),
      _CapabilityAction(
        zhLabel: 'Skill Governance Report',
        enLabel: 'Skill Governance Report',
        capability: _ActionCapability.enabledReal,
        zhReason: '已有 Campaign 4/5 展示契约和 fixture 证据。',
        enReason:
            'Backed by accepted Campaign 4/5 display contract and fixture evidence.',
      ),
    ];

List<_DensePageTab> _agentTabs(bool zh) => [
      _DensePageTab(
        zhTitle: 'Agent 概览',
        enTitle: 'Agent Overview',
        zhSubtitle: 'Agent 域总览，包只是导出产物之一。',
        enSubtitle: 'Agent domain overview; package is one export artifact.',
        icon: Icons.smart_toy_outlined,
        columns: zh ? ['项目', '输入', '状态'] : ['Item', 'Input', 'Status'],
        rows: zh
            ? [
                ['Agent 名称', '等待配置', '待输入'],
                ['目标知识库', '等待知识包', '边界禁用'],
                ['绑定 Skill', '等待 Skill 草稿', '边界禁用'],
                ['包导出产物', 'manifest', '预览'],
              ]
            : [
                ['Agent name', 'Waiting for configuration', 'Pending input'],
                [
                  'Target knowledge package',
                  'Waiting for package',
                  'Boundary disabled'
                ],
                ['Bound Skill', 'Waiting for Skill draft', 'Boundary disabled'],
                ['Package export artifact', 'manifest', 'Preview'],
              ],
        metrics: [
          _DenseMetric(zh ? '运行时' : 'runtime', 'runtime',
              zh ? '未实现' : 'not implemented'),
          _DenseMetric(zh ? '包产物' : 'package artifact', 'package artifact',
              zh ? '预览' : 'preview'),
        ],
      ),
      _DensePageTab(
        zhTitle: '创建与编辑',
        enTitle: 'Create / Edit Agent',
        zhSubtitle: '仅配置 Agent 草稿，不启动自主执行。',
        enSubtitle:
            'Configure an Agent draft only; autonomous execution is not started.',
        icon: Icons.edit_note_outlined,
        columns: zh
            ? ['配置项', '当前值', '能力']
            : ['Field', 'Current value', 'Capability'],
        rows: zh
            ? [
                ['名称与描述', '等待输入', '边界禁用'],
                ['目标任务', '等待输入', '边界禁用'],
                ['配置预览', '草稿结构', '仅展示'],
              ]
            : [
                [
                  'Name and description',
                  'Waiting for input',
                  'Boundary disabled'
                ],
                ['Target task', 'Waiting for input', 'Boundary disabled'],
                ['Configuration preview', 'Draft structure', 'Display only'],
              ],
        metrics: [
          _DenseMetric(zh ? '简单模式' : 'simple mode', 'simple mode',
              zh ? '预览' : 'preview'),
          _DenseMetric(zh ? '高级模式' : 'advanced mode', 'advanced mode',
              zh ? '预览' : 'preview'),
        ],
      ),
      _DensePageTab(
        zhTitle: '模式与绑定',
        enTitle: 'Modes and Bindings',
        zhSubtitle: '简单/高级模式、知识包与 Skill 绑定保持草稿边界。',
        enSubtitle:
            'Simple/advanced modes, package binding, and Skill binding stay draft-bound.',
        icon: Icons.hub_outlined,
        columns:
            zh ? ['区域', '支持状态', '边界'] : ['Area', 'Support state', 'Boundary'],
        rows: zh
            ? [
                ['Simple Mode', '配置预览', '仅展示'],
                ['Advanced Mode', '配置预览', '仅展示'],
                ['知识库绑定', '等待知识包', '边界禁用'],
                ['Skill 绑定', '等待 Skill 草稿', '边界禁用'],
              ]
            : [
                ['Simple Mode', 'Configuration preview', 'Display only'],
                ['Advanced Mode', 'Configuration preview', 'Display only'],
                [
                  'Knowledge binding',
                  'Waiting for package',
                  'Boundary disabled'
                ],
                [
                  'Skill binding',
                  'Waiting for Skill draft',
                  'Boundary disabled'
                ],
              ],
        metrics: [
          _DenseMetric(zh ? '绑定' : 'bindings', 'bindings', '0'),
          _DenseMetric(zh ? '真实执行' : 'real execution', 'real execution', '0'),
        ],
      ),
      _DensePageTab(
        zhTitle: '工具与权限',
        enTitle: 'Tools and Permissions',
        zhSubtitle: '工具、MCP、模型和权限是 Agent 配置的一部分。',
        enSubtitle:
            'Tools, MCP, models, and permissions belong to Agent configuration.',
        icon: Icons.admin_panel_settings_outlined,
        columns: zh
            ? ['配置域', '状态', '能力']
            : ['Configuration domain', 'Status', 'Capability'],
        rows: zh
            ? [
                ['Tool 绑定', '等待配置', '边界禁用'],
                ['MCP 绑定', '等待配置', '边界禁用'],
                ['模型配置', '预览', '仅展示'],
                ['权限策略', '预览', '仅展示'],
              ]
            : [
                [
                  'Tool binding',
                  'Waiting for configuration',
                  'Boundary disabled'
                ],
                [
                  'MCP binding',
                  'Waiting for configuration',
                  'Boundary disabled'
                ],
                ['Model configuration', 'Preview', 'Display only'],
                ['Permission policy', 'Preview', 'Display only'],
              ],
        metrics: [
          _DenseMetric(zh ? '云沙箱' : 'cloud sandbox', 'cloud sandbox',
              zh ? '未实现' : 'not implemented'),
          _DenseMetric(zh ? '模型路由' : 'model router', 'model router',
              zh ? '未实现' : 'not implemented'),
        ],
      ),
      _DensePageTab(
        zhTitle: '工作区与未来运行时',
        enTitle: 'Workspace and Future Runtime',
        zhSubtitle: '工作区分区保留在 Agent 架构中，执行隔离后续实现。',
        enSubtitle:
            'Workspace partitions remain in Agent architecture; execution isolation is later work.',
        icon: Icons.account_tree_outlined,
        columns: zh
            ? ['长期域', '当前处理', '能力']
            : ['Long-term area', 'Current handling', 'Capability'],
        rows: zh
            ? [
                ['Workspace Partitions', '架构占位', '仅展示'],
                ['Agent Teams', '后续 Campaign', '不显示'],
                ['Subagent Policies', '后续 Campaign', '不显示'],
                ['Memory and Compaction', '后续 Campaign', '不显示'],
                ['Computer Use and Sandbox', '后续 Campaign', '不显示'],
                ['A2A Interoperability', '后续 Campaign', '不显示'],
                ['Runtime and Observability', '后续 Campaign', '不显示'],
              ]
            : [
                [
                  'Workspace Partitions',
                  'Architecture placeholder',
                  'Display only'
                ],
                ['Agent Teams', 'Later campaign', 'Omitted'],
                ['Subagent Policies', 'Later campaign', 'Omitted'],
                ['Memory and Compaction', 'Later campaign', 'Omitted'],
                ['Computer Use and Sandbox', 'Later campaign', 'Omitted'],
                ['A2A Interoperability', 'Later campaign', 'Omitted'],
                ['Runtime and Observability', 'Later campaign', 'Omitted'],
              ],
        metrics: [
          _DenseMetric(zh ? '运行时' : 'runtime', 'runtime',
              zh ? '未实现' : 'not implemented'),
          _DenseMetric(zh ? '记忆运行时' : 'memory runtime', 'memory runtime',
              zh ? '未实现' : 'not implemented'),
        ],
      ),
      _DensePageTab(
        zhTitle: '包与导出',
        enTitle: 'Package / Export',
        zhSubtitle: 'Agent 包是导出产物，交给验证与导出门禁。',
        enSubtitle:
            'Agent package is an export artifact handed to Validate & Export.',
        icon: Icons.archive_outlined,
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
        metrics: [
          _DenseMetric(zh ? '交接' : 'handoff', 'handoff',
              zh ? '验证与导出' : 'Validate & Export'),
        ],
      ),
    ];

List<_CapabilityAction> _agentActions() => const [
      _CapabilityAction(
        zhLabel: '创建 Agent 草稿',
        enLabel: 'Create Agent draft',
        capability: _ActionCapability.disabledBoundary,
        zhReason: '需要真实知识包和 Skill 草稿；不实现 Agent Runtime。',
        enReason:
            'Requires a real package and Skill draft; Agent Runtime is not implemented.',
      ),
      _CapabilityAction(
        zhLabel: '预览 Agent 配置',
        enLabel: 'Preview Agent configuration',
        capability: _ActionCapability.displayOnly,
        zhReason: '配置结构可展示，但不代表 Agent 已创建或可运行。',
        enReason:
            'Configuration structure can be displayed, but it does not mean the Agent was created or can run.',
      ),
      _CapabilityAction(
        zhLabel: '预览包导出产物',
        enLabel: 'Preview package export artifact',
        capability: _ActionCapability.displayOnly,
        zhReason: 'Agent 包只是导出预览，等待验证门禁。',
        enReason:
            'Agent package is an export preview waiting for the validation gate.',
      ),
      _CapabilityAction(
        zhLabel: '运行 Agent',
        enLabel: 'Run Agent',
        capability: _ActionCapability.omitted,
        zhReason: 'Campaign 4/5 禁止 Agent Runtime 完成声明。',
        enReason: 'Campaign 4/5 forbids Agent Runtime completion claims.',
      ),
    ];

List<_DensePageTab> _validateTabs(bool zh) => [
      _DensePageTab(
        zhTitle: '验证门禁',
        enTitle: 'Validation Gate',
        zhSubtitle: '最终检查清单、报告和恢复路径。',
        enSubtitle: 'Final review of manifests, reports, and recovery paths.',
        icon: Icons.fact_check_outlined,
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
        metrics: const [
          _DenseMetric('release', 'release', 'not claimed'),
          _DenseMetric('EXE', 'EXE', 'not claimed'),
        ],
      ),
      _DensePageTab(
        zhTitle: '报告与审计',
        enTitle: 'Reports & Audit',
        zhSubtitle: '报告作为二级页展示，不占用一级导航。',
        enSubtitle:
            'Reports appear as a secondary page, not another primary nav item.',
        icon: Icons.receipt_long_outlined,
        columns: zh ? ['报告', '状态', '边界'] : ['Report', 'Status', 'Boundary'],
        rows: zh
            ? [
                ['validation_report', '等待', 'display_only'],
                ['governance_report', 'fixture 可展示', 'enabled_real'],
                ['release_report', '不显示', 'omitted'],
              ]
            : [
                ['validation_report', 'Waiting', 'display_only'],
                ['governance_report', 'Fixture displayable', 'enabled_real'],
                ['release_report', 'Hidden', 'omitted'],
              ],
        metrics: const [
          _DenseMetric('reports', 'reports', '2'),
          _DenseMetric('release', 'release', '0'),
        ],
      ),
      _DensePageTab(
        zhTitle: '受控导出',
        enTitle: 'Controlled Export',
        zhSubtitle: '导出等待验证，不创建 Release。',
        enSubtitle:
            'Export waits for validation and does not create a Release.',
        icon: Icons.archive_outlined,
        columns: zh ? ['目标', '状态', '原因'] : ['Target', 'Status', 'Reason'],
        rows: zh
            ? [
                ['工作台包', '等待', '需要验证'],
                ['GitHub Release', 'omitted', '禁止创建'],
                ['产品版本 tag', 'omitted', '禁止创建'],
              ]
            : [
                ['Workbench package', 'Waiting', 'Needs validation'],
                ['GitHub Release', 'omitted', 'Forbidden'],
                ['Product version tag', 'omitted', 'Forbidden'],
              ],
        metrics: const [
          _DenseMetric('exported', 'exported', '0'),
          _DenseMetric('tags', 'tags', '0'),
        ],
      ),
    ];

List<_CapabilityAction> _validateActions() => const [
      _CapabilityAction(
        zhLabel: '验证清单与报告',
        enLabel: 'Validate manifests and reports',
        capability: _ActionCapability.disabledBoundary,
        zhReason: '需要真实输出产物。',
        enReason: 'Requires real output artifacts.',
      ),
      _CapabilityAction(
        zhLabel: '查看审计报告',
        enLabel: 'View audit reports',
        capability: _ActionCapability.displayOnly,
        zhReason: '可展示 fixture/契约证据。',
        enReason: 'Can display fixture/contract evidence.',
      ),
      _CapabilityAction(
        zhLabel: '创建 Release',
        enLabel: 'Create Release',
        capability: _ActionCapability.omitted,
        zhReason: 'Campaign 4/5 明确禁止。',
        enReason: 'Explicitly forbidden in Campaign 4/5.',
      ),
    ];

List<_DensePageTab> _settingsTabs(bool zh) => [
      _DensePageTab(
        zhTitle: '工作区',
        enTitle: 'Workspace',
        zhSubtitle: '路径和本地执行状态集中展示。',
        enSubtitle: 'Paths and local execution state in one place.',
        icon: Icons.folder_outlined,
        columns:
            zh ? ['设置', '当前值', '状态'] : ['Setting', 'Current value', 'Status'],
        rows: zh
            ? [
                ['工作区', '.', 'display_only'],
                ['输出目录', './workbench_runs', 'display_only'],
                ['Core CLI', 'heitang-kb-forge', 'disabled_boundary'],
              ]
            : [
                ['Workspace', '.', 'display_only'],
                ['Output directory', './workbench_runs', 'display_only'],
                ['Core CLI', 'heitang-kb-forge', 'disabled_boundary'],
              ],
        metrics: const [
          _DenseMetric('cloud', 'cloud', 'off'),
          _DenseMetric('local first', 'local first', 'on'),
        ],
      ),
      _DensePageTab(
        zhTitle: '语言与主题',
        enTitle: 'Language & Theme',
        zhSubtitle: '保持单语言显示，不叠加双语标签。',
        enSubtitle:
            'Keep single-language display without stacked bilingual labels.',
        icon: Icons.language_outlined,
        columns: zh ? ['项目', '状态', '说明'] : ['Item', 'Status', 'Note'],
        rows: zh
            ? [
                ['中文模式', '可用', '只显示中文正常文案'],
                ['英文模式', '可用', '只显示英文正常文案'],
                ['技术名词', '例外', 'Skill / Agent / Core / Web'],
              ]
            : [
                ['Chinese mode', 'Available', 'Chinese normal copy only'],
                ['English mode', 'Available', 'English normal copy only'],
                ['Technical terms', 'Exception', 'Skill / Agent / Core / Web'],
              ],
        metrics: const [
          _DenseMetric('primary nav', 'primary nav', '7'),
        ],
      ),
      _DensePageTab(
        zhTitle: '安全边界',
        enTitle: 'Safety Boundary',
        zhSubtitle: '本地优先、云默认关闭、敏感信息不外发。',
        enSubtitle:
            'Local-first, cloud off by default, no sensitive data transmission.',
        icon: Icons.shield_outlined,
        columns: zh ? ['边界', '状态', '能力'] : ['Boundary', 'Status', 'Capability'],
        rows: zh
            ? [
                ['云服务', '默认关闭', 'display_only'],
                ['本地 Core', 'Web 禁用', 'disabled_boundary'],
                ['外部 provider', '需显式配置', 'disabled_boundary'],
              ]
            : [
                ['Cloud services', 'Off by default', 'display_only'],
                ['Local Core', 'Disabled on Web', 'disabled_boundary'],
                [
                  'External provider',
                  'Explicit config required',
                  'disabled_boundary'
                ],
              ],
        metrics: const [
          _DenseMetric('secrets', 'secrets', 'not collected'),
        ],
      ),
    ];

List<_CapabilityAction> _settingsActions() => const [
      _CapabilityAction(
        zhLabel: '检查工作区路径',
        enLabel: 'Check workspace path',
        capability: _ActionCapability.displayOnly,
        zhReason: '当前页面展示路径配置，不执行文件系统变更。',
        enReason:
            'This page displays path configuration and does not change the filesystem.',
      ),
      _CapabilityAction(
        zhLabel: '切换语言',
        enLabel: 'Switch language',
        capability: _ActionCapability.enabledReal,
        zhReason: '现有 UI 状态支持中英切换。',
        enReason: 'Existing UI state supports Chinese/English switching.',
      ),
      _CapabilityAction(
        zhLabel: '配置外部 provider',
        enLabel: 'Configure external provider',
        capability: _ActionCapability.disabledBoundary,
        zhReason: 'Campaign 4/5 不默认添加云依赖。',
        enReason: 'Campaign 4/5 does not add cloud dependency by default.',
      ),
    ];

class _DensePageHeader extends StatelessWidget {
  const _DensePageHeader({
    required this.localeCode,
    required this.copy,
    required this.isWebRuntime,
  });

  final String localeCode;
  final _ProductPageCopy copy;
  final bool isWebRuntime;

  bool get _zh => localeCode == 'zh-CN';

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
          child: Icon(copy.icon, color: colors.onPrimary, size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _ProductPageBadge(
                    icon: Icons.view_agenda_outlined,
                    label: _zh ? '页面工作台' : 'Page workbench',
                  ),
                  _ProductPageBadge(
                    icon: Icons.shield_outlined,
                    label: isWebRuntime
                        ? (_zh ? 'Web 安全展示' : 'Web-safe view')
                        : (_zh ? '桌面本地执行' : 'Desktop local run'),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(copy.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                copy.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

class _DenseTabStrip extends StatelessWidget {
  const _DenseTabStrip({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_DensePageTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < tabs.length; index++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                selected: selectedIndex == index,
                label: Text(tabs[index].title(zh)),
                avatar: Icon(tabs[index].icon, size: 16),
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

class _DenseTabBody extends StatelessWidget {
  const _DenseTabBody({
    required this.localeCode,
    required this.tab,
  });

  final String localeCode;
  final _DensePageTab tab;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: Key('dense-tab-${tab.enTitle.toLowerCase().replaceAll(' ', '-')}'),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Icon(tab.icon, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tab.title(_zh),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900)),
                      Text(tab.subtitle(_zh),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _DenseDataTable(columns: tab.columns, rows: tab.rows, zh: _zh),
          if (tab.metrics.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final metric in tab.metrics)
                    _DenseMetricChip(
                        label: metric.label(_zh), value: metric.value, zh: _zh),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DenseDataTable extends StatelessWidget {
  const _DenseDataTable({
    required this.columns,
    required this.rows,
    required this.zh,
  });

  final List<String> columns;
  final List<List<String>> rows;
  final bool zh;

  String _displayValue(String value) {
    switch (value) {
      case 'enabled_real':
        return _ActionCapability.enabledReal.label(zh);
      case 'disabled_boundary':
        return _ActionCapability.disabledBoundary.label(zh);
      case 'display_only':
        return _ActionCapability.displayOnly.label(zh);
      case 'omitted':
        return _ActionCapability.omitted.label(zh);
      case 'provider required':
        return zh ? '需要 provider' : value;
      case 'cloud off by default':
        return zh ? '云默认关闭' : value;
      case 'out of scope':
        return zh ? '超出范围' : value;
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 36,
        dataRowMinHeight: 38,
        dataRowMaxHeight: 42,
        columnSpacing: 22,
        horizontalMargin: 12,
        headingTextStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w900,
            ),
        dataTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        columns: [
          for (final column in columns) DataColumn(label: Text(column)),
        ],
        rows: [
          for (final row in rows)
            DataRow(
              cells: [
                for (final value in row)
                  DataCell(Text(
                    _displayValue(value),
                    overflow: TextOverflow.ellipsis,
                  )),
              ],
            ),
        ],
      ),
    );
  }
}

class _DenseMetricChip extends StatelessWidget {
  const _DenseMetricChip({
    required this.label,
    required this.value,
    required this.zh,
  });

  final String label;
  final String value;
  final bool zh;

  String _displayValue() {
    if (!zh) return value;
    switch (value) {
      case 'pending':
        return '等待';
      case 'off':
        return '关闭';
      case 'on':
        return '开启';
      case 'local':
        return '本地';
      case 'safe boundary':
        return '安全边界';
      case 'not implemented':
        return '未实现';
      case 'not claimed':
        return '未声明';
      case 'not collected':
        return '不收集';
      case 'none':
        return '无';
      case 'input':
        return '等待输入';
      case 'Validate & Export':
        return '验证与导出';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  )),
          const SizedBox(width: 6),
          Text(_displayValue(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  )),
        ],
      ),
    );
  }
}

class _DensePageRail extends StatelessWidget {
  const _DensePageRail({
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_zh ? '状态与输出' : 'Status and Output',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _ProductSignal(
            label: _zh ? '当前状态' : 'Current status',
            value: copy.statusLabel,
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
          _ProductSignal(
            label: _zh ? '完成规则' : 'Completion rule',
            value: _zh ? '必须有真实结果和证据' : 'Requires real result and evidence',
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
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(6),
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

class _ActionCapabilityMatrix extends StatelessWidget {
  const _ActionCapabilityMatrix({
    required this.localeCode,
    required this.actions,
  });

  final String localeCode;
  final List<_CapabilityAction> actions;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final visibleActions = actions
        .where((action) => action.capability != _ActionCapability.omitted);
    return Container(
      key: const Key('action-capability-matrix'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_zh ? '动作能力边界' : 'Action Capability Boundary',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in visibleActions)
                _ActionCapabilityPill(localeCode: localeCode, action: action),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCapabilityPill extends StatelessWidget {
  const _ActionCapabilityPill({
    required this.localeCode,
    required this.action,
  });

  final String localeCode;
  final _CapabilityAction action;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final capabilityColor = action.capability.color(context);
    return Tooltip(
      message: action.reason(_zh),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: capabilityColor.withValues(alpha: 0.42)),
          color: capabilityColor.withValues(alpha: 0.06),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action.capability == _ActionCapability.enabledReal
                    ? Icons.play_circle_outline
                    : action.capability == _ActionCapability.disabledBoundary
                        ? Icons.block_outlined
                        : Icons.visibility_outlined,
                size: 15,
                color: capabilityColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(action.label(_zh),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 6),
              Text(action.capability.label(_zh),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: capabilityColor,
                        fontWeight: FontWeight.w900,
                      )),
            ],
          ),
        ),
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
