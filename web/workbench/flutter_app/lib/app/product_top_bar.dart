part of '../main.dart';

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
