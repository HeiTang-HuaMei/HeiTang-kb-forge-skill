part of '../main.dart';

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
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final visual = _HTKWTokens.visualTokens(Theme.of(context).brightness);
    final sidebarBackground = visual.sidebarBackground;
    final primaryText = colors.onSurface;
    final secondaryText = colors.onSurfaceVariant;
    final effectiveSelectedIndex = switch (pages[selectedIndex].id) {
      'import-parsing' => _pageIndexById('document-library'),
      'retrieval-verification' =>
        _pageIndexById('knowledge-package-management'),
      'artifact-center' || 'reports-audit' => _pageIndexById('dashboard'),
      _ => selectedIndex,
    };

    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 110;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: sidebarBackground,
          border: Border(
            right: BorderSide(color: colors.outlineVariant),
          ),
          boxShadow: dark
              ? const []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.018),
                    blurRadius: 12,
                    offset: const Offset(4, 0),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: ListView(
            key: const Key('desktop-sidebar-scroll'),
            padding: EdgeInsets.fromLTRB(
                compact ? 10 : 18, 26, compact ? 10 : 18, 26),
            children: [
              compact
                  ? const _SidebarCompactBrand()
                  : _SidebarBrand(localeCode: localeCode),
              SizedBox(height: compact ? 24 : 34),
              _SidebarItem(
                keyName: 'sidebar-dashboard',
                page: pages[0],
                icon: Icons.dashboard_customize_outlined,
                localeCode: localeCode,
                contracts: contracts,
                selected: effectiveSelectedIndex == 0,
                primaryText: primaryText,
                secondaryText: secondaryText,
                onTap: () => onPageChanged(0),
              ),
              _SidebarItem(
                keyName: 'sidebar-workbook',
                page: pages[1],
                icon: Icons.workspaces_outline,
                localeCode: localeCode,
                contracts: contracts,
                selected: effectiveSelectedIndex == 1,
                primaryText: primaryText,
                secondaryText: secondaryText,
                onTap: () => onPageChanged(1),
              ),
              for (final index in [2, 3, 5, 6, 7])
                _SidebarItem(
                  keyName: 'sidebar-${pages[index].id}',
                  page: pages[index],
                  icon: _sidebarIconFor(pages[index].id),
                  localeCode: localeCode,
                  contracts: contracts,
                  selected: effectiveSelectedIndex == index,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  onTap: () => onPageChanged(index),
                ),
              const SizedBox(height: 8),
              _SidebarItem(
                keyName: 'sidebar-workspace',
                page: pages[10],
                icon: Icons.tune_outlined,
                localeCode: localeCode,
                contracts: contracts,
                selected: effectiveSelectedIndex == 10,
                primaryText: primaryText,
                secondaryText: secondaryText,
                onTap: () => onPageChanged(10),
              ),
              if (!compact) ...[
                const SizedBox(height: 72),
                _LocalFirstCard(localeCode: localeCode),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({required this.localeCode});

  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primaryText = colors.onSurface;
    final secondaryText = colors.onSurfaceVariant;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _HTKWTokens.moduleKnowledge.withValues(
                alpha: dark ? 0.18 : 0.12,
              ),
              borderRadius: BorderRadius.circular(_DesktopGrid.radiusMedium),
              border: Border.all(
                color: _HTKWTokens.moduleKnowledge.withValues(
                  alpha: dark ? 0.22 : 0.16,
                ),
              ),
            ),
            child: Text(
              'H',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _HTKWTokens.moduleKnowledge,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localeCode == 'zh-CN' ? '黑糖' : 'HeiTang',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: primaryText,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        )),
                const SizedBox(height: 2),
                Text(localeCode == 'zh-CN' ? '知识工作台' : 'Knowledge Workbench',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: secondaryText,
                          fontWeight: FontWeight.w500,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarCompactBrand extends StatelessWidget {
  const _SidebarCompactBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _HTKWTokens.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'H',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '黑糖',
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
        ),
      ],
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final dark = Theme.of(context).brightness == Brightness.dark;
      final compact = constraints.maxWidth < 110;
      final moduleColor = _HTKWTokens.moduleColor(page.id);
      final selectedBackground = _HTKWTokens.moduleTint(
        page.id,
        Theme.of(context).brightness,
        lightAlpha: 0.1,
        darkAlpha: 0.16,
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          key: keyName == null ? null : Key(keyName!),
          borderRadius: BorderRadius.circular(_DesktopGrid.radiusMedium),
          onTap: onTap,
          child: Container(
            height: 42,
            padding: EdgeInsets.only(
              left: compact ? 0 : 0,
              right: compact ? 0 : 12,
              top: compact ? 10 : 8,
              bottom: compact ? 10 : 8,
            ),
            decoration: BoxDecoration(
              color: selected ? selectedBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(_DesktopGrid.buttonRadius),
              border: selected
                  ? Border.all(
                      color: _HTKWTokens.moduleBorderTint(
                        page.id,
                        Theme.of(context).brightness,
                      ),
                    )
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              mainAxisAlignment:
                  compact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                if (!compact)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 2,
                    height: 20,
                    decoration: BoxDecoration(
                      color: selected ? moduleColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                if (!compact) const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: compact ? 20 : 24,
                  height: compact ? 20 : 24,
                  decoration: BoxDecoration(
                    color: selected
                        ? moduleColor.withValues(alpha: dark ? 0.14 : 0.12)
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(_DesktopGrid.radiusSmall),
                  ),
                  child: Icon(icon,
                      color: selected
                          ? moduleColor
                          : moduleColor.withValues(alpha: dark ? 0.62 : 0.76),
                      size: compact ? 15 : 18),
                ),
                if (!compact) const SizedBox(width: 10),
                if (!compact)
                  Expanded(
                    child: Text(page.title(localeCode, contracts),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? primaryText : secondaryText,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        )),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _LocalFirstCard extends StatelessWidget {
  const _LocalFirstCard({required this.localeCode});

  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: _HTKWTokens.moduleTint(
          'document-library',
          Theme.of(context).brightness,
          lightAlpha: 0.045,
          darkAlpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _HTKWTokens.moduleBorderTint(
            'document-library',
            Theme.of(context).brightness,
            lightAlpha: 0.1,
            darkAlpha: 0.12,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined,
                  color: _HTKWTokens.moduleDocument, size: 17),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  localeCode == 'zh-CN' ? '本地优先 · 默认不连接云服务' : 'Local first',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                ),
              ),
            ],
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
