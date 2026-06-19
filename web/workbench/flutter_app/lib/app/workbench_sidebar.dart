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
