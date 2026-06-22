part of '../main.dart';

class _WorkbenchScaffold extends StatelessWidget {
  const _WorkbenchScaffold({
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
  final ProviderCapabilityStatus providerCapabilityStatus;
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
          providerCapabilityStatus: providerCapabilityStatus,
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
      final width = viewportWidth;
      final height = viewportHeight < 560 ? 560.0 : viewportHeight;
      final frame = widget.childBuilder(
        windowState,
        (state) => setState(() => windowState = state),
      );
      return Container(
        color: colors.surfaceContainerHighest,
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
              minHeight: 560,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.62),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: maximized ? 0 : 0.1),
                  blurRadius: maximized ? 0 : 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: frame,
          ),
        ),
      );
    });
  }
}
