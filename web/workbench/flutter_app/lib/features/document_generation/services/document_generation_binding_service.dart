class DocumentGenerationBinding {
  const DocumentGenerationBinding({
    required this.selectedKbId,
    required this.selectedKbIds,
    required this.sourceKbIds,
    required this.sourceKbNames,
  });

  final String selectedKbId;
  final List<String> selectedKbIds;
  final List<String> sourceKbIds;
  final List<String> sourceKbNames;

  Map<String, Object?> toJson() {
    return {
      'selected_kb_id': selectedKbId,
      'selected_kb_ids': selectedKbIds,
      'source_kb_ids': sourceKbIds,
      'source_kb_names': sourceKbNames,
    };
  }
}

class DocumentGenerationBindingService {
  const DocumentGenerationBindingService();

  DocumentGenerationBinding resolve({
    required Map<String, dynamic> queryReport,
    required List<Map<String, dynamic>> knowledgeBaseRecords,
  }) {
    final querySelectedIds = _stringList(queryReport['selected_kb_ids']);
    final queryResultIds = _idsFromRows(
      queryReport['selected'] ?? queryReport['results'] ?? queryReport['records'],
    );
    final catalogIds = knowledgeBaseRecords
        .map((record) => (record['kb_id'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final selectedKbIds = querySelectedIds.isNotEmpty
        ? querySelectedIds
        : queryResultIds.isNotEmpty
            ? queryResultIds
            : catalogIds.isNotEmpty
                ? _unique(catalogIds)
                : const ['current_kb'];
    final catalogNameById = {
      for (final record in knowledgeBaseRecords)
        if ((record['kb_id'] ?? '').toString().trim().isNotEmpty)
          (record['kb_id'] ?? '').toString().trim():
              (record['kb_name'] ?? record['kb_id'] ?? '').toString().trim(),
    };
    final resultNameById = _namesFromRows(
      queryReport['selected'] ?? queryReport['results'] ?? queryReport['records'],
    );
    final sourceKbNames = selectedKbIds
        .map((id) => resultNameById[id] ?? catalogNameById[id] ?? id)
        .where((name) => name.trim().isNotEmpty)
        .toList(growable: false);
    return DocumentGenerationBinding(
      selectedKbId: selectedKbIds.first,
      selectedKbIds: selectedKbIds,
      sourceKbIds: selectedKbIds,
      sourceKbNames: sourceKbNames,
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return _unique(value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty));
  }

  static List<String> _idsFromRows(Object? rows) {
    if (rows is! List) return const <String>[];
    return _unique(rows
        .whereType<Map>()
        .map((row) => (row['kb_id'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty));
  }

  static Map<String, String> _namesFromRows(Object? rows) {
    if (rows is! List) return const <String, String>{};
    return {
      for (final row in rows.whereType<Map>())
        if ((row['kb_id'] ?? '').toString().trim().isNotEmpty)
          (row['kb_id'] ?? '').toString().trim():
              (row['kb_name'] ?? row['kb_id'] ?? '').toString().trim(),
    };
  }

  static List<String> _unique(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) continue;
      seen.add(trimmed);
      result.add(trimmed);
    }
    return List<String>.unmodifiable(result);
  }
}
class DocumentCitationTraceService {
  const DocumentCitationTraceService();

  List<Map<String, Object?>> fromQueryReport(Map<String, dynamic> queryReport) {
    final rows = queryReport['selected'] ??
        queryReport['results'] ??
        queryReport['records'];
    if (rows is! List) return const <Map<String, Object?>>[];
    return rows
        .whereType<Map>()
        .map((row) => _citationFromRow(row))
        .where((row) => row['citation']!.toString().trim().isNotEmpty)
        .toList(growable: false);
  }

  Map<String, Object?> _citationFromRow(Map row) {
    final sourceDocId = _stringValue(row['source_doc_id'] ??
        row['source_document_id'] ??
        row['document_id']);
    final sourceDocument = _stringValue(
        row['source_document'] ?? row['source_path'] ?? row['source_name']);
    return {
      'text': _compact(row['text'] ?? row['excerpt'] ?? row['title']),
      'citation': _stringValue(row['citation'] ?? row['source_path']),
      'kb_id': _stringValue(row['kb_id']),
      'kb_name': _stringValue(row['kb_name']),
      'chunk_id': _stringValue(row['chunk_id']),
      'source_trace_id': _stringValue(row['source_trace_id']),
      'source_doc_id': sourceDocId,
      'source_document': sourceDocument,
      'source_path': _stringValue(row['source_path']),
      'page_number': row['page_number'],
      'section_id': _stringValue(row['section_id']),
      'block_ids': _stringList(row['block_ids']),
      'heading_path': _stringList(row['heading_path']),
      'lineage': row['lineage'] is Map
          ? Map<String, Object?>.from(row['lineage'] as Map)
          : const <String, Object?>{},
      'trace_complete': _stringValue(row['source_trace_id']).isNotEmpty &&
          _stringValue(row['chunk_id']).isNotEmpty &&
          sourceDocId.isNotEmpty,
    };
  }

  static String _stringValue(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static String _compact(Object? value, {int maxLength = 180}) {
    final text = value?.toString().replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
