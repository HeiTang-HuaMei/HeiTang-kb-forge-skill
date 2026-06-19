part of '../main.dart';

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
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var index = 0; index < tabs.length; index++)
            _PageTabButton(
              key: Key('$keyPrefix-$index'),
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
    return Container(
      key: keyName == null ? null : Key(keyName!),
      width: double.infinity,
      constraints:
          BoxConstraints(minHeight: minHeight ?? _DesktopGrid.panelMinHeight),
      padding: const EdgeInsets.all(_DesktopGrid.panelPadding),
      decoration: BoxDecoration(
        color: gap
            ? colors.surfaceContainerLow
            : accent
                ? colors.primary.withValues(alpha: 0.05)
                : colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_DesktopGrid.panelRadius),
        border: Border.all(
          color: gap
              ? colors.outlineVariant
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
                  Icon(icon, size: 18, color: colors.primary),
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
    this.keyName,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final String? keyName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        key: keyName == null ? null : Key(keyName!),
        width: double.infinity,
        height: constraints.maxHeight.isFinite ? double.infinity : null,
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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.12,
                              )),
                ),
              ],
            ),
            const SizedBox(height: _DesktopGrid.gutter),
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
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 360) {
        final narrowTable = Column(
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
      final tableWidth =
          (columns.length * minCellWidth).clamp(constraints.maxWidth, 1200.0);
      final borderColor = colors.outlineVariant.withValues(alpha: 0.7);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: tableWidth.toDouble()),
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              for (var index = 0; index < columns.length; index++)
                index: const FlexColumnWidth(),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.38),
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                children: [
                  for (final column in columns)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      child: Text(
                        column,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
                        ? colors.surface
                        : colors.surfaceContainerHighest
                            .withValues(alpha: 0.18),
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  children: [
                    for (var index = 0; index < columns.length; index++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
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
    final colors = Theme.of(context).colorScheme;
    final color = switch (resolvedKind) {
      _CapabilityStatusKind.displayOnly => colors.onSurfaceVariant,
      _CapabilityStatusKind.disabledBoundary => colors.onSurfaceVariant,
      _CapabilityStatusKind.available => Colors.green.shade700,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.42)),
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
        onPressed: onPressed,
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
  final VoidCallback? onPressed;
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
