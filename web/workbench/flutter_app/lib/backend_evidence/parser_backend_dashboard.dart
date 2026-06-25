import 'package:flutter/material.dart';

import '../contracts/workbench_contracts.dart';

class ParserBackendEvidenceDashboard extends StatelessWidget {
  const ParserBackendEvidenceDashboard({
    super.key,
    required this.matrix,
    required this.localeCode,
  });

  final ParserBackendMatrix matrix;
  final String localeCode;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: _zh ? '文档解析能力' : 'Document Parsing Capability',
          subtitle: _zh
              ? '用户上传文档后，系统自动选择合适的解析方式。'
              : 'After upload, the app chooses a suitable parsing path.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryTile(
              icon: Icons.memory_outlined,
              label: _zh ? '基础解析' : 'Basic parsing',
              value: _zh ? '已可用' : 'Available',
              note: _zh ? '普通文档自动处理' : 'Handles regular documents',
            ),
            _SummaryTile(
              icon: Icons.restart_alt_outlined,
              label: _zh ? '高级解析' : 'Advanced parsing',
              value: matrix.optionalDependencyGatedCount > 0
                  ? (_zh ? '可选，未安装' : 'Optional, not installed')
                  : (_zh ? '已可用' : 'Available'),
              note: _zh ? '复杂版式需要时启用' : 'Enable for complex layouts',
            ),
            _SummaryTile(
              icon: Icons.extension_outlined,
              label: _zh ? 'OCR' : 'OCR',
              value: matrix.optionalDependencyGatedCount > 0
                  ? (_zh ? '可选，未安装' : 'Optional, not installed')
                  : (_zh ? '已可用' : 'Available'),
              note: _zh ? '扫描件和图片文档使用' : 'Used for scans and images',
            ),
            _SummaryTile(
              icon: Icons.verified_outlined,
              label: _zh ? '外部服务连接能力' : 'External service connectivity',
              value: _zh ? '已配置，待测试' : 'Configured, needs test',
              note: _zh ? '测试通过后显示已连接' : 'Shows connected after test',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Callout(
          icon: Icons.info_outline,
          title: _zh ? '自动判断解析路线' : 'Automatic parsing route',
          body: _zh
              ? '普通文本、扫描件、多栏文档、表格密集文档和图片文档会进入不同处理路线。'
              : 'Text files, scans, multi-column documents, table-heavy files, and images use different handling paths.',
        ),
        const SizedBox(height: 8),
        _Callout(
          icon: Icons.desktop_windows_outlined,
          title: _zh ? '用户下一步' : 'Next step',
          body: _zh
              ? '直接上传文档；解析失败时再按提示启用高级解析。'
              : 'Upload documents directly; enable advanced parsing only when prompted.',
        ),
        const SizedBox(height: 8),
        _Callout(
          icon: Icons.inventory_2_outlined,
          title: _zh ? '默认安装边界' : 'Default install boundary',
          body: _zh
              ? '高级解析组件按需安装，不影响基础文档导入。'
              : 'Advanced parsing components are installed only when needed.',
        ),
        const SizedBox(height: 16),
        _DashboardPanel(
          title: _zh ? '能力状态摘要' : 'Capability status summary',
          subtitle: _zh
              ? '只展示用户能理解的能力和下一步。'
              : 'Only user-facing capability status and next steps are shown.',
          child: _BackendMatrixTable(matrix: matrix, localeCode: localeCode),
        ),
        const SizedBox(height: 16),
        _DashboardPanel(
          title: _zh ? '处理路线说明' : 'Handling paths',
          subtitle: _zh
              ? '系统内部自动选择，不要求用户理解底层实现。'
              : 'The app chooses internally; users do not need implementation details.',
          child: _BackendDetailGrid(matrix: matrix, localeCode: localeCode),
        ),
        const SizedBox(height: 16),
        _DashboardPanel(
          title: _zh ? '测试与记录' : 'Tests and records',
          subtitle: _zh
              ? '内部记录保留给审计，用户只看状态。'
              : 'Internal records are kept for audit; users see only status.',
          child: _AuditEvidenceRows(matrix: matrix, localeCode: localeCode),
        ),
      ],
    );
  }
}

class _BackendMatrixTable extends StatelessWidget {
  const _BackendMatrixTable({required this.matrix, required this.localeCode});

  final ParserBackendMatrix matrix;
  final String localeCode;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final advancedStatus = matrix.optionalDependencyGatedCount > 0
        ? (_zh ? '可选，未安装' : 'Optional, not installed')
        : (_zh ? '已可用' : 'Available');
    final rows = _zh
        ? [
            ['基础解析', '已可用', '上传文档后自动处理'],
            ['高级解析', advancedStatus, '复杂版式需要时启用'],
            ['OCR', advancedStatus, '扫描件或图片文档需要时启用'],
            ['表格解析', advancedStatus, '表格密集文档需要时启用'],
          ]
        : [
            ['Basic parsing', 'Available', 'Runs after upload'],
            ['Advanced parsing', advancedStatus, 'Enable for complex layouts'],
            ['OCR', advancedStatus, 'Enable for scans and images'],
            ['Table parsing', advancedStatus, 'Enable for table-heavy files'],
          ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 42,
        dataRowMinHeight: 54,
        dataRowMaxHeight: 72,
        columns: [
          DataColumn(label: Text(_zh ? '能力' : 'Capability')),
          DataColumn(label: Text(_zh ? '状态' : 'Status')),
          DataColumn(label: Text(_zh ? '下一步' : 'Next step')),
        ],
        rows: [
          for (final row in rows)
            DataRow(
              cells: [
                DataCell(Text(row[0])),
                DataCell(_StatusBadge(label: row[1])),
                DataCell(SizedBox(
                  width: 260,
                  child: Text(row[2], maxLines: 2),
                )),
              ],
            ),
        ],
      ),
    );
  }
}

class _BackendDetailGrid extends StatelessWidget {
  const _BackendDetailGrid({required this.matrix, required this.localeCode});

  final ParserBackendMatrix matrix;
  final String localeCode;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final routes = _zh
        ? [
            ('普通文本 PDF / Word / TXT', '基础解析', '上传后自动处理'),
            ('扫描 PDF', 'OCR 路线', '需要时启用图片文字能力'),
            ('多栏论文 / 合同 / 报告', '高级版式解析', '提示后按需安装'),
            ('表格密集文档', '表格解析', '生成结构化知识块'),
            ('图片文档', 'OCR + 版面恢复', '保留来源追踪'),
          ]
        : [
            ('Text PDF / Word / TXT', 'Basic parsing', 'Runs after upload'),
            (
              'Scanned PDF',
              'OCR route',
              'Enable image text capability if needed'
            ),
            (
              'Papers / contracts / reports',
              'Advanced layout parsing',
              'Install only when prompted'
            ),
            (
              'Table-heavy documents',
              'Table parsing',
              'Creates structured knowledge blocks'
            ),
            ('Image documents', 'OCR + layout recovery', 'Keeps source trace'),
          ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 860 ? 1 : 2;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final route in routes)
              SizedBox(
                width: width,
                child: _DetailCard(
                  title: route.$1,
                  status: route.$2,
                  nextStep: route.$3,
                  zh: _zh,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.status,
    required this.nextStep,
    required this.zh,
  });

  final String title;
  final String status;
  final String nextStep;
  final bool zh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              _StatusBadge(label: status),
            ],
          ),
          const SizedBox(height: 12),
          _KeyValue(label: zh ? '处理方式' : 'Handling', value: status),
          _KeyValue(
            label: zh ? '下一步' : 'Next step',
            value: nextStep,
          ),
          _KeyValue(
            label: zh ? '状态' : 'Status',
            value: status == (zh ? '基础解析' : 'Basic parsing')
                ? (zh ? '已可用' : 'Available')
                : (zh ? '可选，未安装' : 'Optional, not installed'),
          ),
          const SizedBox(height: 8),
          Text(zh ? '说明' : 'Note',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(zh
              ? '系统会根据文档内容自动选择路线；用户无需选择底层实现。'
              : 'The app chooses the route automatically; users do not choose implementation details.'),
        ],
      ),
    );
  }
}

class _AuditEvidenceRows extends StatelessWidget {
  const _AuditEvidenceRows({required this.matrix, required this.localeCode});

  final ParserBackendMatrix matrix;
  final String localeCode;

  bool get _zh => localeCode == 'zh-CN';

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        _zh ? '基础解析测试' : 'Basic parsing test',
        _zh ? '已可用' : 'Available',
        _zh ? '上传文档后自动处理' : 'Runs after upload'
      ),
      (
        _zh ? '高级解析测试' : 'Advanced parsing test',
        matrix.optionalDependencyGatedCount > 0
            ? (_zh ? '可选，未安装' : 'Optional, not installed')
            : (_zh ? '已可用' : 'Available'),
        _zh ? '需要时安装增强组件' : 'Install enhancement only when needed'
      ),
      (
        _zh ? 'OCR 测试' : 'OCR test',
        matrix.optionalDependencyGatedCount > 0
            ? (_zh ? '可选，未安装' : 'Optional, not installed')
            : (_zh ? '已可用' : 'Available'),
        _zh ? '扫描件或图片文档需要时启用' : 'Enable for scans and images'
      ),
    ];

    return Column(
      children: [
        for (final row in rows)
          _EvidenceRow(title: row.$1, nextStep: row.$3, status: row.$2),
      ],
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({
    required this.title,
    required this.nextStep,
    required this.status,
  });

  final String title;
  final String nextStep;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.description_outlined, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(nextStep),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusBadge(label: status),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
  });

  final IconData icon;
  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 250,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 12),
            Text(label, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(note, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
          Expanded(
              child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = label.toLowerCase();
    final color =
        normalized.contains('pass') || normalized.contains('integrated')
            ? Colors.green.shade700
            : normalized.contains('blocked') || normalized.contains('not')
                ? Colors.orange.shade800
                : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
