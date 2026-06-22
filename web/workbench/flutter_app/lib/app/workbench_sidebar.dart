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
    const sidebarBackground = _HTKWTokens.sidebar;
    const selectedBackground = _HTKWTokens.sidebarSelected;
    const primaryText = _HTKWTokens.surface;
    const secondaryText = Color(0xffb7b0a7);
    final effectiveSelectedIndex = pages[selectedIndex].id == 'import-parsing'
        ? _pageIndexById('document-library')
        : selectedIndex;

    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 110;
      return Material(
        color: sidebarBackground,
        child: ListView(
          key: const Key('desktop-sidebar-scroll'),
          padding:
              EdgeInsets.fromLTRB(compact ? 10 : 18, 26, compact ? 10 : 18, 26),
          children: [
            compact
                ? const _SidebarCompactBrand()
                : _SidebarBrand(localeCode: localeCode),
            SizedBox(height: compact ? 28 : 48),
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
            for (final index in [2, 3, 4, 5, 6, 7, 8])
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
            _SidebarItem(
              keyName: 'sidebar-reports-audit',
              page: pages[9],
              icon: Icons.history_outlined,
              localeCode: localeCode,
              contracts: contracts,
              selected: effectiveSelectedIndex == 9,
              primaryText: primaryText,
              secondaryText: secondaryText,
              selectedBackground: selectedBackground,
              onTap: () => onPageChanged(9),
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
              selectedBackground: selectedBackground,
              onTap: () => onPageChanged(10),
            ),
            if (!compact) ...[
              const SizedBox(height: 120),
              _LocalFirstCard(localeCode: localeCode),
            ],
          ],
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
    const primaryText = _HTKWTokens.surface;
    const secondaryText = Color(0xffb7b0a7);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _HTKWTokens.gold,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'H',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _HTKWTokens.sidebar,
                    fontWeight: FontWeight.w900,
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: primaryText,
                          fontWeight: FontWeight.w900,
                        )),
                const SizedBox(height: 2),
                Text(localeCode == 'zh-CN' ? '知识工作台' : 'Knowledge Workbench',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: secondaryText,
                          fontWeight: FontWeight.w600,
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
            color: _HTKWTokens.gold,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'H',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _HTKWTokens.sidebar,
                  fontWeight: FontWeight.w900,
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
                color: _HTKWTokens.surface,
                fontSize: 9,
                fontWeight: FontWeight.w800,
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
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 110;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          key: keyName == null ? null : Key(keyName!),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 44,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 0 : 14,
              vertical: compact ? 10 : 9,
            ),
            decoration: BoxDecoration(
              color: selected ? selectedBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: selected
                  ? Border.all(color: _HTKWTokens.gold.withValues(alpha: 0.42))
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              mainAxisAlignment:
                  compact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: compact ? 20 : 26,
                  height: compact ? 20 : 26,
                  decoration: BoxDecoration(
                    color: selected
                        ? _HTKWTokens.goldSoft
                        : const Color(0xff1a1f24),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(icon,
                      color: selected ? _HTKWTokens.sidebar : secondaryText,
                      size: compact ? 13 : 16),
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
                              selected ? FontWeight.w800 : FontWeight.w600,
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
      height: 108,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xff1a1e20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _HTKWTokens.sidebarBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined,
                  color: _HTKWTokens.goldSoft, size: 22),
              const SizedBox(width: _DesktopGrid.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(localeCode == 'zh-CN' ? '本地优先' : 'Local first',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: 12,
                              color: _HTKWTokens.surface,
                              fontWeight: FontWeight.w900,
                            )),
                    const SizedBox(height: 1),
                    Text(
                        localeCode == 'zh-CN'
                            ? '默认不连接云服务'
                            : 'Cloud is off by default',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: const Color(0xffb7b0a7),
                            )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _HTKWTokens.sidebar,
              borderRadius: BorderRadius.circular(999),
              border:
                  Border.all(color: _HTKWTokens.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline,
                    color: _HTKWTokens.goldSoft, size: 14),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                      localeCode == 'zh-CN'
                          ? '安全授权受保护'
                          : 'Authorization protected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: const Color(0xffd3c2aa),
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
