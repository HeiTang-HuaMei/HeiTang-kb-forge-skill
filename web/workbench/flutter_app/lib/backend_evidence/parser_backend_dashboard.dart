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
    final runtimeCount = matrix.realRuntimeIntegratedCount;
    final builtin = matrix.backend('builtin');
    final docling = matrix.backend('docling');
    final marker = matrix.backend('marker');
    final mineru = matrix.backend('mineru');
    final opendataloader = matrix.backend('opendataloader');
    final paddleocr = matrix.backend('paddleocr');
    final surya = matrix.backend('surya');
    final unstructured = matrix.backend('unstructured');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: _zh ? 'Parser/OCR 后端证据面板' : 'Parser/OCR Backend Evidence',
          subtitle: matrix.releaseTitle,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryTile(
              icon: Icons.memory_outlined,
              label: _zh ? 'Core 集成适配器' : 'Core Integrated Adapters',
              value: '$runtimeCount integrated',
              note: _zh
                  ? 'docling / marker / mineru / opendataloader / paddleocr / unstructured'
                  : 'docling / marker / mineru / opendataloader / paddleocr / unstructured',
            ),
            _SummaryTile(
              icon: Icons.restart_alt_outlined,
              label: _zh ? 'Builtin Fallback' : 'Builtin Fallback',
              value: builtin?.status ?? 'builtin_passed',
              note: builtin?.fallback.description ?? '',
            ),
            _SummaryTile(
              icon: Icons.extension_outlined,
              label: _zh ? 'Optional Dependencies' : 'Optional Dependencies',
              value: '${matrix.optionalDependencyGatedCount} gated',
              note: _zh
                  ? 'default install keeps heavy deps out'
                  : 'default install keeps heavy deps out',
            ),
            _SummaryTile(
              icon: Icons.article_outlined,
              label: _zh ? 'Docling 状态' : 'Docling Status',
              value: docling?.lastAcceptanceStatus ?? 'not_ready',
              note: docling == null
                  ? 'parser-docling'
                  : '${docling.installMode.label} · ${docling.validatedStableSurface.join(', ')}',
            ),
            _SummaryTile(
              icon: Icons.rule_folder_outlined,
              label: _zh ? 'Marker 状态' : 'Marker Status',
              value: marker?.status ?? 'dependency_missing',
              note: marker == null
                  ? 'parser-marker'
                  : marker.workbenchState.join(' / '),
            ),
            _SummaryTile(
              icon: Icons.auto_awesome_mosaic_outlined,
              label: _zh ? 'MinerU 状态' : 'MinerU Status',
              value: mineru?.lastAcceptanceStatus ?? 'not_ready',
              note: mineru == null
                  ? 'parser-mineru'
                  : '${mineru.installMode.label} · ${mineru.validatedStableSurface.join(', ')}',
            ),
            _SummaryTile(
              icon: Icons.picture_as_pdf_outlined,
              label: _zh ? 'OpenDataLoader 状态' : 'OpenDataLoader Status',
              value: opendataloader?.lastAcceptanceStatus ?? 'not_ready',
              note: opendataloader == null
                  ? 'parser-opendataloader'
                  : '${opendataloader.installMode.label} · ${opendataloader.validatedStableSurface.join(', ')}',
            ),
            _SummaryTile(
              icon: Icons.document_scanner_outlined,
              label: _zh ? 'PaddleOCR 状态' : 'PaddleOCR Status',
              value: paddleocr?.lastAcceptanceStatus ?? 'not_ready',
              note: paddleocr == null
                  ? 'parser-paddleocr'
                  : '${paddleocr.installMode.label} · ${paddleocr.validatedStableSurface.join(', ')}',
            ),
            _SummaryTile(
              icon: Icons.compare_arrows_outlined,
              label: _zh ? 'Surya 基准' : 'Surya Benchmark',
              value: surya?.status ?? 'needs_strengthening',
              note: surya == null
                  ? 'benchmark/reference'
                  : surya.workbenchState.join(' / '),
            ),
            _SummaryTile(
              icon: Icons.text_snippet_outlined,
              label: _zh ? 'Unstructured 状态' : 'Unstructured Status',
              value: unstructured?.lastAcceptanceStatus ?? 'dependency_missing',
              note: unstructured == null
                  ? 'parser-unstructured · .md, .txt'
                  : '${unstructured.installMode.label} · ${unstructured.validatedStableSurface.join(', ')}',
            ),
            _SummaryTile(
              icon: Icons.verified_outlined,
              label: _zh ? 'Release Boundary' : 'Release Boundary',
              value: matrix.releaseVersion,
              note: 'v4.0.0 tag untouched',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Callout(
          icon: Icons.info_outline,
          title: _zh ? 'Unstructured 稳定表面' : 'Unstructured Stable Surface',
          body: unstructured?.knownLimitations.first ??
              'Stable P2.1 surface is explicitly limited to .md/.txt.',
        ),
        const SizedBox(height: 8),
        _Callout(
          icon: Icons.restart_alt_outlined,
          title: _zh ? 'Fallback Parser Contract' : 'Fallback Parser Contract',
          body: _zh
              ? 'Builtin fallback 只稳定声明基础 .md/.txt 文本文档；它不是完整 Document Understanding / OCR / layout 后端。'
              : 'Builtin fallback only makes a stable basic .md/.txt text-document claim; it is not a full Document Understanding, OCR, or layout backend.',
        ),
        const SizedBox(height: 8),
        _Callout(
          icon: Icons.desktop_windows_outlined,
          title: _zh ? 'Workbench 执行边界' : 'Workbench Execution Boundary',
          body: _zh
              ? 'Static Web Workbench 和 Flutter evidence 面板只展示 Core 证据，不执行本地 parser/OCR runtime。'
              : 'Static Web Workbench and Flutter evidence panels display Core evidence only and do not execute local parser/OCR runtimes.',
        ),
        const SizedBox(height: 8),
        _Callout(
          icon: Icons.inventory_2_outlined,
          title: _zh ? '默认依赖边界' : 'Default Dependency Boundary',
          body: _zh
              ? 'Parser/OCR 可选后端依赖均为 optional dependency gated，不打包进默认安装。'
              : 'Parser/OCR optional backend dependencies are gated and are not bundled by default.',
        ),
        const SizedBox(height: 16),
        _DashboardPanel(
          title: _zh ? 'Backend Matrix Table' : 'Backend Matrix Table',
          subtitle: _zh
              ? '字段来自 Core parser_backend_matrix.json'
              : 'Fields are derived from Core parser_backend_matrix.json',
          child: _BackendMatrixTable(matrix: matrix, localeCode: localeCode),
        ),
        const SizedBox(height: 16),
        _DashboardPanel(
          title: _zh ? 'Backend Status Detail' : 'Backend Status Detail',
          subtitle: _zh
              ? '每个 backend 的证据、fallback、限制和修复边界'
              : 'Evidence, fallback, limitations, and repair boundaries per backend',
          child: _BackendDetailGrid(matrix: matrix, localeCode: localeCode),
        ),
        const SizedBox(height: 16),
        _DashboardPanel(
          title: _zh ? 'Reports & Audit Evidence' : 'Reports & Audit Evidence',
          subtitle: _zh
              ? '可发现的 Core-generated evidence 路径'
              : 'Discoverable Core-generated evidence paths',
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 42,
        dataRowMinHeight: 64,
        dataRowMaxHeight: 86,
        columns: [
          DataColumn(label: Text(_zh ? 'Backend' : 'Backend')),
          DataColumn(label: Text(_zh ? 'Status' : 'Status')),
          DataColumn(label: Text(_zh ? 'Install Mode' : 'Install Mode')),
          DataColumn(label: Text(_zh ? 'Dependency' : 'Dependency')),
          DataColumn(label: Text(_zh ? 'Stable Surface' : 'Stable Surface')),
          DataColumn(label: Text(_zh ? 'Evidence' : 'Evidence')),
          DataColumn(label: Text(_zh ? 'Fallback' : 'Fallback')),
        ],
        rows: [
          for (final backend in matrix.backends)
            DataRow(
              cells: [
                DataCell(_BackendName(backend: backend)),
                DataCell(_StatusBadge(label: backend.status)),
                DataCell(_MonoText(backend.installMode.label)),
                DataCell(_MonoText(backend.dependencyMode)),
                DataCell(_MonoText(backend.validatedStableSurface.join(', '))),
                DataCell(_PathText(backend.evidence.evidencePath)),
                DataCell(SizedBox(
                  width: 260,
                  child: Text(
                    backend.fallback.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
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
            for (final backend in matrix.backends)
              SizedBox(
                width: width,
                child: _DetailCard(
                  backend: backend,
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
  const _DetailCard({required this.backend, required this.zh});

  final ParserBackendRecord backend;
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
              Expanded(child: _BackendName(backend: backend)),
              const SizedBox(width: 8),
              _StatusBadge(label: backend.lastAcceptanceStatus),
            ],
          ),
          const SizedBox(height: 12),
          _KeyValue(
              label: zh ? 'Sample' : 'Sample',
              value: backend.evidence.sampleInputType),
          _KeyValue(
              label: zh ? 'Install' : 'Install',
              value: backend.installMode.label),
          _KeyValue(
            label: zh ? 'State' : 'State',
            value: backend.workbenchState.join(' / '),
          ),
          _KeyValue(
            label: zh ? 'Stable Surface' : 'Stable Surface',
            value: backend.capabilityBoundary.validatedStableSurface.join(', '),
          ),
          _KeyValue(
              label: zh ? 'Evidence' : 'Evidence',
              value: backend.evidence.evidencePath),
          const SizedBox(height: 8),
          Text(zh ? 'Known limitations' : 'Known limitations',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          for (final limitation in backend.limitations.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('- '),
                  Expanded(child: Text(limitation.description)),
                ],
              ),
            ),
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
        _zh ? 'P2.1 Acceptance Report' : 'P2.1 Acceptance Report',
        'docs/audits/p2_1_parser_ocr_backends/p2_1_acceptance_report.md',
        'pass'
      ),
      (
        _zh ? 'Parser Backend Matrix' : 'Parser Backend Matrix',
        'docs/audits/p2_1_parser_ocr_backends/parser_backend_matrix.json',
        'pass'
      ),
      (
        _zh ? 'Backend Capability Boundaries' : 'Backend Capability Boundaries',
        matrix.knownLimitationReportPath,
        'pass'
      ),
      (
        _zh ? 'Live Acceptance Replay' : 'Live Acceptance Replay',
        'docs/audits/p2_1_parser_ocr_backends/live_acceptance_replay.md',
        'pass'
      ),
      (
        _zh ? 'Failure Mode Report' : 'Failure Mode Report',
        'docs/audits/p2_1_parser_ocr_backends/failure_mode_report.md',
        'pass'
      ),
      (
        _zh ? 'Fresh Clone Reproducibility' : 'Fresh Clone Reproducibility',
        'docs/audits/p2_1_parser_ocr_backends/fresh_clone_reproducibility_report.md',
        'pass'
      ),
      (
        _zh
            ? 'Release Hygiene Evidence Index'
            : 'Release Hygiene Evidence Index',
        'docs/audits/p2_1_parser_ocr_backends/evidence_index.md',
        'indexed'
      ),
    ];

    return Column(
      children: [
        for (final row in rows)
          _EvidenceRow(title: row.$1, path: row.$2, status: row.$3),
      ],
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({
    required this.title,
    required this.path,
    required this.status,
  });

  final String title;
  final String path;
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
                _PathText(path),
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

class _BackendName extends StatelessWidget {
  const _BackendName({required this.backend});

  final ParserBackendRecord backend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(backend.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        _MonoText(backend.backendId),
      ],
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

class _PathText extends StatelessWidget {
  const _PathText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return _MonoText(value, maxLines: 2);
  }
}

class _MonoText extends StatelessWidget {
  const _MonoText(this.value, {this.maxLines = 1});

  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(fontFamily: 'monospace'),
    );
  }
}
