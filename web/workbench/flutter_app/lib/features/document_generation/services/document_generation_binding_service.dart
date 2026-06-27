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
