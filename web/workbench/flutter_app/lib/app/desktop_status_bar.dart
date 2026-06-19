part of '../main.dart';

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
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 720;
      final showVersion = constraints.maxWidth >= 760;
      final showUpdates = constraints.maxWidth >= 900;
      final gap = compact ? 10.0 : 24.0;
      return Container(
        key: const Key('desktop-status-bar'),
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 22),
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
            SizedBox(width: gap),
            Expanded(
              child: _StatusBarItem(
                icon: Icons.folder_open_outlined,
                label: _zh ? '位置' : 'Location',
                value: workspace,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: gap),
            _StatusBarItem(
              icon: isWebRuntime
                  ? Icons.public_outlined
                  : Icons.desktop_windows_outlined,
              label: _zh ? '模式' : 'Mode',
              value: isWebRuntime
                  ? (_zh ? '预览模式' : 'Preview mode')
                  : (_zh ? '桌面本地执行' : 'Desktop local'),
            ),
            if (showVersion) ...[
              SizedBox(width: gap),
              _StatusBarItem(
                icon: Icons.info_outline,
                label: _zh ? '版本' : 'Version',
                value: _appVersionLabel,
              ),
            ],
            if (showUpdates) ...[
              SizedBox(width: gap),
              _StatusBarItem(
                icon: Icons.sync_outlined,
                label: _zh ? '检查更新' : 'Check updates',
                value: '',
              ),
            ],
          ],
        ),
      );
    });
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
