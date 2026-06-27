import 'dart:convert';
import 'dart:io';

class SkillSourceTraceWriteResult {
  const SkillSourceTraceWriteResult({
    required this.sourceTracePath,
    required this.rows,
    required this.sourceDocIds,
    required this.sourceChunkIds,
    required this.sourceTraceIds,
  });

  final String sourceTracePath;
  final List<Map<String, Object?>> rows;
  final List<String> sourceDocIds;
  final List<String> sourceChunkIds;
  final List<String> sourceTraceIds;

  Map<String, Object?> toJson() => {
    'source_trace_path': sourceTracePath,
    'source_doc_ids': sourceDocIds,
    'source_chunk_ids': sourceChunkIds,
    'source_trace_ids': sourceTraceIds,
    'source_trace_count': rows.length,
  };
}

class SkillSourceTraceRepository {
  const SkillSourceTraceRepository();

  Future<SkillSourceTraceWriteResult> writeSourceTrace({
    required Directory workspace,
    required Directory skillRoot,
    required Iterable<String> sourceKbIds,
    required String skillId,
  }) async {
    await skillRoot.create(recursive: true);
    final rows = await _buildRows(
      workspace: workspace,
      sourceKbIds: sourceKbIds.toList(growable: false),
      skillId: skillId,
    );
    final sourceTracePath = _join(skillRoot.path, 'source_trace.jsonl');
    await File(sourceTracePath).writeAsString(
      rows.isEmpty ? '' : '${rows.map(jsonEncode).join('\n')}\n',
      encoding: utf8,
    );
    return SkillSourceTraceWriteResult(
      sourceTracePath: sourceTracePath,
      rows: rows,
      sourceDocIds: _unique(rows.map((row) => row['source_doc_id'])),
      sourceChunkIds: _unique(rows.map((row) => row['source_chunk_id'])),
      sourceTraceIds: _unique(rows.map((row) => row['source_trace_id'])),
    );
  }

  Future<List<Map<String, Object?>>> _buildRows({
    required Directory workspace,
    required List<String> sourceKbIds,
    required String skillId,
  }) async {
    final sourceManifest = await _readJsonObject(
      _join(workspace.path, 'source_manifest.json'),
    );
    final sourceByPath = <String, Map<String, Object?>>{};
    for (final source in _listOfMaps(sourceManifest['sources'])) {
      final relativePath = _stringValue(source['relative_path'], '');
      final sourcePath = _stringValue(source['source_path'], relativePath);
      if (relativePath.isNotEmpty) {
        sourceByPath[_normalizePath(relativePath)] = source;
      }
      if (sourcePath.isNotEmpty) {
        sourceByPath[_normalizePath(sourcePath)] = source;
      }
      final sourceName = _stringValue(source['source_name'], '');
      if (sourceName.isNotEmpty) {
        sourceByPath[_normalizePath(sourceName)] = source;
      }
    }

    final chunksPath = _join(_join(workspace.path, 'kb'), 'chunks.jsonl');
    final chunks = await _readJsonl(File(chunksPath));
    final rows = <Map<String, Object?>>[];
    for (var index = 0; index < chunks.length; index += 1) {
      final chunk = chunks[index];
      final sourcePath = _firstString(chunk, const [
        'source_path',
        'relative_path',
        'source_name',
      ]);
      final source = sourceByPath[_normalizePath(sourcePath)] ?? const {};
      final sourceDocId = _firstNonEmpty([
        chunk['source_doc_id'],
        chunk['document_id'],
        chunk['doc_id'],
        source['source_doc_id'],
        source['document_id'],
        source['doc_id'],
        sourcePath.isEmpty ? '' : 'doc_${_stableHash(sourcePath)}',
      ]);
      final chunkId = _firstNonEmpty([
        chunk['source_chunk_id'],
        chunk['chunk_id'],
        chunk['id'],
        'chunk_${index + 1}_${_stableHash('${sourceDocId}_${chunk['text']}')}',
      ]);
      final sourceTraceId = _firstNonEmpty([
        chunk['source_trace_id'],
        source['source_trace_id'],
        'trace_${_stableHash('${sourceDocId}_$chunkId')}',
      ]);
      rows.add({
        'schema_version': 'prd_v3_skill_source_trace.v1',
        'skill_id': skillId,
        'kb_id': sourceKbIds.isEmpty ? 'current_kb' : sourceKbIds.first,
        'source_kb_ids': sourceKbIds.isEmpty
            ? const ['current_kb']
            : sourceKbIds,
        'source_doc_id': sourceDocId,
        'source_chunk_id': chunkId,
        'chunk_id': chunkId,
        'source_trace_id': sourceTraceId,
        'source_name': _firstNonEmpty([
          chunk['source_name'],
          source['source_name'],
          sourcePath,
        ]),
        'source_path': sourcePath,
        'block_ids': _listOfStrings(chunk['block_ids']),
        'heading_path': _listOfStrings(chunk['heading_path']),
        'semantic_unit_type': _firstNonEmpty([
          chunk['semantic_unit_type'],
          'source_chunk',
        ]),
        'text_preview': _compact(_stringValue(chunk['text'], '')),
        'lineage': _mapValue(chunk['lineage']).isEmpty
            ? {
                'source': 'kb_chunks',
                'source_doc_id': sourceDocId,
                'source_chunk_id': chunkId,
                'source_trace_id': sourceTraceId,
              }
            : _mapValue(chunk['lineage']),
      });
    }
    return rows;
  }

  static Future<Map<String, dynamic>> _readJsonObject(String path) async {
    final file = File(path);
    if (!await file.exists()) return <String, dynamic>{};
    final text = await file.readAsString(encoding: utf8);
    if (text.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(text);
    return decoded is Map
        ? decoded.cast<String, dynamic>()
        : <String, dynamic>{};
  }

  static Future<List<Map<String, dynamic>>> _readJsonl(File file) async {
    if (!await file.exists()) return const <Map<String, dynamic>>[];
    final rows = <Map<String, dynamic>>[];
    for (final line in await file.readAsLines(encoding: utf8)) {
      if (line.trim().isEmpty) continue;
      final decoded = jsonDecode(line);
      if (decoded is Map) rows.add(decoded.cast<String, dynamic>());
    }
    return rows;
  }

  static List<Map<String, dynamic>> _listOfMaps(Object? value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }

  static Map<String, dynamic> _mapValue(Object? value) {
    return value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};
  }

  static List<String> _listOfStrings(Object? value) {
    if (value is List) return _unique(value.map((item) => item?.toString()));
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? const <String>[] : <String>[text];
  }

  static List<String> _unique(Iterable<Object?> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && seen.add(text)) result.add(text);
    }
    return result;
  }

  static String _firstString(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final text = _stringValue(row[key], '');
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String _firstNonEmpty(Iterable<Object?> values) {
    for (final value in values) {
      final text = _stringValue(value, '');
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String _stringValue(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String _compact(String value, {int maxLength = 240}) {
    final compacted = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compacted.length <= maxLength) return compacted;
    return compacted.substring(0, maxLength);
  }

  static String _normalizePath(String value) {
    return value.replaceAll('\\', '/').trim().toLowerCase();
  }

  static String _join(String first, String second) {
    if (first.endsWith(Platform.pathSeparator)) return '$first$second';
    return '$first${Platform.pathSeparator}$second';
  }

  static String _stableHash(String value) {
    var hash = 17;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
