part of '../main.dart';

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconBox = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: colors.primary, size: 24),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
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
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconBox,
          const SizedBox(width: _DesktopGrid.gutter),
          Expanded(child: copy),
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
    this.keyPrefix = 'page-tab',
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 620;
      final veryCompact = constraints.maxWidth < 420;
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var index = 0; index < tabs.length; index++)
            _PageTabButton(
              key: Key('$keyPrefix-$index'),
              label: tabs[index],
              selected: selectedIndex == index,
              width: compact
                  ? veryCompact
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 6) / 2
                  : null,
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
    final background = selected ? colors.primary : colors.surfaceContainerLow;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 40, minWidth: width ?? 0),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_DesktopGrid.chipRadius),
            side: BorderSide(
              color: selected ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(_DesktopGrid.chipRadius),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      overflow: TextOverflow.visible,
                      maxLines: 1,
                      softWrap: false,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: foreground,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                            height: 1.16,
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
    final brightness = Theme.of(context).brightness;
    final visual = _HTKWTokens.visualTokens(brightness);
    final panelColor = gap
        ? colors.surfaceContainerLow.withValues(
            alpha: brightness == Brightness.dark ? 0.72 : 0.9,
          )
        : accent
            ? _HTKWTokens.moduleTint(
                'dashboard',
                brightness,
                lightAlpha: 0.08,
                darkAlpha: 0.14,
              )
            : _HTKWTokens.panelSurface(brightness);
    return Container(
      key: keyName == null ? null : Key(keyName!),
      width: double.infinity,
      constraints:
          BoxConstraints(minHeight: minHeight ?? _DesktopGrid.panelMinHeight),
      padding: const EdgeInsets.all(_DesktopGrid.panelPadding),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(_DesktopGrid.panelRadius),
        border: Border.all(
          color: accent
              ? colors.primary.withValues(
                  alpha: brightness == Brightness.dark ? 0.2 : 0.14,
                )
              : visual.borderSubtle,
        ),
        boxShadow: gap ? const [] : visual.shadow,
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final header = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: accent
                          ? colors.surface.withValues(alpha: 0.72)
                          : colors.primary.withValues(
                              alpha:
                                  brightness == Brightness.dark ? 0.13 : 0.09,
                            ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.primary.withValues(
                          alpha: brightness == Brightness.dark ? 0.18 : 0.11,
                        ),
                      ),
                    ),
                    child: Icon(icon, size: 17, color: colors.primary),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                height: 1.12,
                              )),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
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
              if (children.isNotEmpty) const SizedBox(height: 18),
              ...children,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            if (children.isNotEmpty) ...[
              const SizedBox(height: 18),
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

class _FigmaCard extends StatelessWidget {
  const _FigmaCard({
    required this.child,
    this.keyName,
    this.padding = const EdgeInsets.all(30),
    this.background,
    this.borderColor,
  });

  final Widget child;
  final String? keyName;
  final EdgeInsetsGeometry padding;
  final Color? background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final visual = _HTKWTokens.visualTokens(brightness);
    return Container(
      key: keyName == null ? null : Key(keyName!),
      width: double.infinity,
      height: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? _HTKWTokens.panelSurface(brightness),
        borderRadius: BorderRadius.circular(_DesktopGrid.panelRadius),
        border: Border.all(color: borderColor ?? visual.borderSubtle),
        boxShadow: visual.shadow,
      ),
      child: child,
    );
  }
}

class _FigmaHighlightCard extends StatelessWidget {
  const _FigmaHighlightCard({
    required this.title,
    required this.description,
    this.icon = Icons.lightbulb_outline,
    this.actions = const [],
    this.keyName,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<Widget> actions;
  final String? keyName;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact =
          constraints.maxHeight.isFinite && constraints.maxHeight <= 96;
      final iconSize = compact ? 46.0 : 58.0;
      final stackActions =
          actions.isNotEmpty && (compact || constraints.maxWidth < 640);
      final copy = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: compact ? 18 : 19,
                    fontWeight: FontWeight.w700,
                    height: 1.08,
                  )),
          SizedBox(height: compact ? 4 : 6),
          Text(description,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: compact ? 13 : null,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    height: compact ? 1.12 : 1.25,
                  )),
        ],
      );
      final actionWrap = Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: stackActions ? WrapAlignment.start : WrapAlignment.end,
        children: actions,
      );
      return _FigmaCard(
        keyName: keyName,
        background: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.42),
        borderColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 24 : 30,
          vertical: compact ? 12 : 20,
        ),
        child: stackActions
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: copy),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    actionWrap,
                  ],
                ],
              )
            : Row(
                children: [
                  Expanded(child: copy),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(width: 22),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: actionWrap,
                    ),
                  ] else ...[
                    const SizedBox(width: 22),
                    Container(
                      width: iconSize,
                      height: iconSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(compact ? 15 : 18),
                      ),
                      child: Icon(icon,
                          color: Theme.of(context).colorScheme.primary,
                          size: compact ? 24 : 28),
                    ),
                  ],
                ],
              ),
      );
    });
  }
}

class _FigmaSectionHeader extends StatelessWidget {
  const _FigmaSectionHeader({
    required this.title,
    this.subtitle,
    this.icon,
    this.accentColor,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = accentColor ?? colors.primary;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: dark ? 0.14 : 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accent.withValues(alpha: dark ? 0.18 : 0.12),
              ),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      )),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        )),
              ],
            ],
          ),
        ),
      ],
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
    final visual = _HTKWTokens.visualTokens(Theme.of(context).brightness);
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        key: keyName == null ? null : Key(keyName!),
        width: double.infinity,
        height: constraints.maxHeight.isFinite ? double.infinity : null,
        padding: const EdgeInsets.all(_DesktopGrid.panelPadding),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(_DesktopGrid.panelRadius),
          border: Border.all(color: visual.borderSubtle),
          boxShadow: visual.shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _HTKWTokens.blueSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 17, color: _HTKWTokens.blue),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                height: 1.12,
                              )),
                ),
              ],
            ),
            const SizedBox(height: 18),
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
    final brightness = Theme.of(context).brightness;
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 360) {
        final narrowTable = Column(
          children: [
            for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
              if (rowIndex > 0) const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _HTKWTokens.recessedSurface(brightness),
                  borderRadius:
                      BorderRadius.circular(_DesktopGrid.radiusMedium),
                  border: Border.all(
                    color: _HTKWTokens.visualTokens(brightness).borderSubtle,
                  ),
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
      final minContentWidth = columns.length * minCellWidth;
      final tableWidth = constraints.maxWidth > minContentWidth
          ? constraints.maxWidth
          : minContentWidth;
      final visual = _HTKWTokens.visualTokens(brightness);
      final borderColor = visual.borderSubtle;
      return Container(
        decoration: BoxDecoration(
          color: _HTKWTokens.recessedSurface(brightness),
          borderRadius: BorderRadius.circular(_DesktopGrid.radiusLarge),
          border: Border.all(
            color: visual.borderSubtle,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth.toDouble(),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: {
                for (var index = 0; index < columns.length; index++)
                  index: const FlexColumnWidth(),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: _HTKWTokens.moduleTint(
                      'knowledge-package-management',
                      brightness,
                      lightAlpha: 0.08,
                      darkAlpha: 0.12,
                    ),
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  children: [
                    for (final column in columns)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Text(
                          column,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
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
                          ? _HTKWTokens.panelSurface(brightness)
                          : _HTKWTokens.recessedSurface(brightness)
                              .withValues(alpha: 0.72),
                      border: Border(bottom: BorderSide(color: borderColor)),
                    ),
                    children: [
                      for (var index = 0; index < columns.length; index++)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
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
    final brightness = Theme.of(context).brightness;
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
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _HTKWTokens.recessedSurface(brightness),
        borderRadius: BorderRadius.circular(_DesktopGrid.radiusMedium),
        border: Border.all(
          color: _HTKWTokens.visualTokens(brightness).borderSubtle,
        ),
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
    this.kind,
  });

  final String? label;
  final _CapabilityStatusKind? kind;

  @override
  Widget build(BuildContext context) {
    final resolvedKind = kind ?? _capabilityStatusKind(label ?? '');
    final color = switch (resolvedKind) {
      _CapabilityStatusKind.displayOnly => _HTKWTokens.blue,
      _CapabilityStatusKind.disabledBoundary => _HTKWTokens.amber,
      _CapabilityStatusKind.available => _HTKWTokens.sage,
    };
    final background = switch (resolvedKind) {
      _CapabilityStatusKind.displayOnly => _HTKWTokens.blueSoft,
      _CapabilityStatusKind.disabledBoundary => _HTKWTokens.amberSoft,
      _CapabilityStatusKind.available => _HTKWTokens.sageSoft,
    };
    final icon = switch (resolvedKind) {
      _CapabilityStatusKind.displayOnly => Icons.visibility_outlined,
      _CapabilityStatusKind.disabledBoundary => Icons.info_outline,
      _CapabilityStatusKind.available => Icons.check_circle_outline,
    };
    final text = _capabilityStatusLabel(
      label,
      Localizations.localeOf(context).languageCode == 'zh',
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(_DesktopGrid.chipRadius),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 13,
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
  if (lower.contains('owner_authorization_required') ||
      lower.contains('not_available_in_product_flow')) {
    return _CapabilityStatusKind.disabledBoundary;
  }
  if (lower.contains('disabled_boundary') ||
      lower.contains('desktop_runtime_required') ||
      lower.contains('runtime_required') ||
      lower.contains('omitted') ||
      lower.contains('provider runtime gate') ||
      lower.contains('external source verification gate') ||
      lower.contains('not connected') ||
      lower.contains('not authorized') ||
      lower.contains('preview only') ||
      lower.contains('read-only') ||
      lower.contains('reserved') ||
      value.contains('未接入') ||
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
    return zh ? '需要配置' : 'Needs configuration';
  }
  final lower = value.toLowerCase();
  if (lower.contains('enabled_real')) {
    return zh ? '可用' : 'Available';
  }
  if (lower.contains('display_only') ||
      lower.contains('preview only') ||
      lower.contains('read-only') ||
      value.contains('只读')) {
    return zh ? '仅查看' : 'View only';
  }
  if (lower.contains('omitted') ||
      lower.contains('not_available_in_product_flow') ||
      value.contains('后续') ||
      value.contains('不实现')) {
    return zh ? '不在当前产品流程中' : 'Outside current product flow';
  }
  if (lower.contains('owner_authorization_required')) {
    return zh ? '需要 Owner 授权' : 'Owner authorization required';
  }
  if (lower.contains('desktop_runtime_required') ||
      lower.contains('runtime_required')) {
    return zh
        ? '暂不可用，需要桌面运行环境'
        : 'Temporarily unavailable; desktop runtime required';
  }
  if (lower.contains('disabled_boundary') ||
      lower.contains('provider runtime gate') ||
      lower.contains('external source verification gate') ||
      lower.contains('not connected') ||
      value.contains('未接入') ||
      value.contains('边界') ||
      value.contains('禁用')) {
    return zh ? '需要配置或授权' : 'Configuration or authorization required';
  }
  return value;
}

class _StatePill extends StatelessWidget {
  const _StatePill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    const color = _HTKWTokens.moduleKnowledge;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: brightness == Brightness.dark ? 0.13 : 0.08,
        ),
        borderRadius: BorderRadius.circular(_DesktopGrid.chipRadius),
        border: Border.all(
          color: color.withValues(
            alpha: brightness == Brightness.dark ? 0.2 : 0.14,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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

class _DisplayAction extends StatelessWidget {
  const _DisplayAction({
    required this.label,
    this.icon = Icons.visibility_outlined,
    this.onPressed,
    this.fullWidth = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: fullWidth ? TextOverflow.ellipsis : TextOverflow.visible,
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide(
            color: _HTKWTokens.visualTokens(Theme.of(context).brightness)
                .borderSubtle,
          ),
        ),
      ),
    );
  }
}

class _MoreMenuAction {
  const _MoreMenuAction({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.enabled = true,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool enabled;
  final bool destructive;
}

class _MoreActionsButton extends StatelessWidget {
  const _MoreActionsButton({
    required this.label,
    required this.actions,
  });

  final String label;
  final List<_MoreMenuAction> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = actions.any((action) => action.enabled);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(
        width: double.infinity,
        child: PopupMenuButton<int>(
          enabled: enabled,
          tooltip: label,
          onSelected: (index) => actions[index].onSelected(),
          itemBuilder: (context) => [
            for (var index = 0; index < actions.length; index++)
              PopupMenuItem<int>(
                value: index,
                enabled: actions[index].enabled,
                child: Row(
                  children: [
                    Icon(
                      actions[index].icon,
                      size: 18,
                      color: actions[index].destructive
                          ? colors.error
                          : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        actions[index].label,
                        overflow: TextOverflow.ellipsis,
                        style: actions[index].destructive
                            ? TextStyle(
                                color: colors.error,
                                fontWeight: FontWeight.w800,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          child: InputDecorator(
            decoration: InputDecoration(
              enabled: enabled,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: const OutlineInputBorder(),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.more_horiz_outlined,
                  size: 18,
                  color: enabled ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: enabled
                              ? colors.primary
                              : colors.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryProductAction extends StatelessWidget {
  const _PrimaryProductAction({
    required this.label,
    required this.onPressed,
    this.icon = Icons.play_arrow_outlined,
    this.automationKey,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final String? automationKey;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Semantics(
        button: true,
        label: automationKey ?? label,
        child: Tooltip(
          message: label,
          child: FilledButton.icon(
            key:
                automationKey == null ? null : ValueKey<String>(automationKey!),
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow:
                  fullWidth ? TextOverflow.ellipsis : TextOverflow.visible,
              style: const TextStyle(height: 1.15),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_DesktopGrid.buttonRadius),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
