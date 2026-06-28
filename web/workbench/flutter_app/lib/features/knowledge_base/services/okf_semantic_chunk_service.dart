import 'dart:convert';
import 'dart:io';

class OkfSemanticChunkResult {
  const OkfSemanticChunkResult({
    required this.chunks,
    required this.sourceTraceRows,
  });

  final List<Map<String, dynamic>> chunks;
  final List<Map<String, dynamic>> sourceTraceRows;
}

class OkfSemanticChunkService {
  const OkfSemanticChunkService();

  Future<OkfSemanticChunkResult> materialize({
    required Directory workspace,
    required Directory kbDir,
    required String kbId,
    required List<Map<String, dynamic>> sourceDocs,
    required List<Map<String, dynamic>> inputChunks,
  }) async {
    final records = await _readDocumentUnderstandingRecords(workspace);
    final normalizedByRelativePath = {
      for (final record in records) _normalize(record['relative_path']): record,
    };
    final sourceDocsByRelativePath = {
      for (final doc in sourceDocs) _normalize(doc['relative_path']): doc,
    };
    final allowedRelativePaths = sourceDocsByRelativePath.keys
        .where((key) => key.isNotEmpty)
        .toSet();
    final resultChunks = <Map<String, dynamic>>[];
    final traceRows = <Map<String, dynamic>>[];
    var fallbackIndex = 0;

    final parsedResult = await _semanticChunksFromParsedDocuments(
      kbId: kbId,
      sourceDocs: sourceDocs,
      normalizedByRelativePath: normalizedByRelativePath,
    );
    resultChunks.addAll(parsedResult.chunks);
    traceRows.addAll(parsedResult.sourceTraceRows);
    final parsedRelativePaths = parsedResult.chunks
        .map((chunk) => _normalize(chunk['relative_path']))
        .where((path) => path.isNotEmpty)
        .toSet();

    for (final entry in inputChunks.asMap().entries) {
      final input = entry.value;
      final relativePath = _relativePathForChunk(
        input,
        normalizedByRelativePath,
        fallbackRelativePath: sourceDocs.length == 1
            ? _stringValue(sourceDocs.single['relative_path'])
            : '',
      );
      if (allowedRelativePaths.isNotEmpty &&
          !allowedRelativePaths.contains(_normalize(relativePath))) {
        continue;
      }
      if (parsedRelativePaths.contains(_normalize(relativePath))) {
        continue;
      }
      final sourceDoc =
          sourceDocsByRelativePath[_normalize(relativePath)] ??
          (sourceDocs.length == 1 ? sourceDocs.single : <String, dynamic>{});
      final sourceDocId = _stringValue(
        sourceDoc['document_id'],
        _stringValue(
          input['source_doc_id'],
          _stringValue(input['document_id']),
        ),
      );
      final text = _stringValue(
        input['text'],
        _stringValue(input['content'], _stringValue(input['summary'])),
      );
      final blockIds = _blockIds(input, sourceDocId, entry.key);
      final sourceTraceId = _stringValue(
        input['source_trace_id'],
        'trace_${kbId}_${blockIds.first}',
      );
      final headingPath = _headingPath(input, relativePath);
      final chunkId = _stringValue(
        input['chunk_id'],
        'okf_${kbId}_chunk_${(resultChunks.length + 1).toString().padLeft(3, '0')}',
      );
      final chunkHash = _stringValue(
        input['chunk_hash'],
        _stableHash(text).toString(),
      );
      final pageOrSection = _stringValue(
        input['page_or_section'],
        headingPath.isEmpty ? relativePath : headingPath.join(' / '),
      );
      final pageNumber = input['page_number'];
      final sectionId = _stringValue(input['section_id']);
      final sourceSpan = _mapValue(input['source_span']);
      final lineage = _mapValue(input['lineage']);
      final normalizedLineage = {
        ...lineage,
        'kb_id': kbId,
        'source_doc_id': sourceDocId,
        'source_document': relativePath,
        'block_ids': blockIds,
        'source_trace_id': sourceTraceId,
        'source_path': _stringValue(input['source_path'], relativePath),
        'page_or_section': pageOrSection,
        'chunking_strategy': 'okf_fallback_from_input_chunk',
        'fallback_reason': 'parsed_document_unavailable',
        if (pageNumber != null) 'page_number': pageNumber,
        if (sectionId.isNotEmpty) 'section_id': sectionId,
        if (sourceSpan.isNotEmpty) 'source_span': sourceSpan,
      };
      final okfChunk = <String, dynamic>{
        ...input,
        'chunk_id': chunkId,
        'source_doc_id': sourceDocId,
        'document_id': sourceDocId,
        'block_ids': blockIds,
        'heading_path': headingPath,
        'semantic_unit_type': 'okf_semantic_chunk',
        'source_trace_id': sourceTraceId,
        'lineage': normalizedLineage,
        'page_or_section': pageOrSection,
        'chunk_hash': chunkHash,
        'text': text,
        'source_path': _stringValue(input['source_path'], relativePath),
        'citation': _stringValue(
          input['citation'],
          '$relativePath#${blockIds.first}',
        ),
        if (pageNumber != null) 'page_number': pageNumber,
        if (sectionId.isNotEmpty) 'section_id': sectionId,
        if (sourceSpan.isNotEmpty) 'source_span': sourceSpan,
      };
      resultChunks.add(okfChunk);
      traceRows.add({
        'schema_version': 'prd_v3_okf_source_trace.v1',
        'source_trace_id': sourceTraceId,
        'kb_id': kbId,
        'chunk_id': chunkId,
        'source_doc_id': sourceDocId,
        'source_document': relativePath,
        'source_path': okfChunk['source_path'],
        'page_or_section': pageOrSection,
        'block_ids': blockIds,
        'heading_path': headingPath,
        'chunk_hash': chunkHash,
        if (pageNumber != null) 'page_number': pageNumber,
        if (sectionId.isNotEmpty) 'section_id': sectionId,
        if (sourceSpan.isNotEmpty) 'source_span': sourceSpan,
        'lineage': normalizedLineage,
        'source_trace_status': 'linked',
      });
    }

    final coveredRelativePaths = resultChunks
        .map((chunk) => _normalize(chunk['relative_path'] ??
            chunk['source_document'] ??
            chunk['source_path']))
        .where((path) => path.isNotEmpty)
        .toSet();
    final missingSourceDocs = sourceDocs.where((sourceDoc) {
      final relativePath = _stringValue(sourceDoc['relative_path'],
          _stringValue(sourceDoc['source_name']));
      return relativePath.isNotEmpty &&
          !coveredRelativePaths.contains(_normalize(relativePath));
    }).toList(growable: false);

    if (missingSourceDocs.isNotEmpty) {
      for (final sourceDoc in missingSourceDocs) {
        fallbackIndex += 1;
        final relativePath = _stringValue(
          sourceDoc['relative_path'],
          _stringValue(sourceDoc['source_name'], 'source_$fallbackIndex'),
        );
        final sourceDocId = _stringValue(
          sourceDoc['document_id'],
          'doc_${_stableHash(relativePath)}',
        );
        final blockId = '${sourceDocId}_block_001';
        final sourceTraceId = 'trace_${kbId}_$blockId';
        final text = _stringValue(
          sourceDoc['summary'],
          _stringValue(sourceDoc['source_name'], relativePath),
        );
        final sourcePath = _stringValue(sourceDoc['source_path'], relativePath);
        final pageOrSection = _stringValue(
          sourceDoc['page_or_section'],
          relativePath,
        );
        final pageNumber = sourceDoc['page_number'];
        final sectionId = _stringValue(sourceDoc['section_id']);
        final sourceSpan = _mapValue(sourceDoc['source_span']);
        final lineage = {
          'kb_id': kbId,
          'source_doc_id': sourceDocId,
          'source_document': relativePath,
          'source_path': sourcePath,
          'block_ids': [blockId],
          'source_trace_id': sourceTraceId,
          'page_or_section': pageOrSection,
          'chunking_strategy': 'okf_fallback_from_source_manifest',
          'fallback_reason': 'no_core_chunk_matched_source_doc',
          if (pageNumber != null) 'page_number': pageNumber,
          if (sectionId.isNotEmpty) 'section_id': sectionId,
          if (sourceSpan.isNotEmpty) 'source_span': sourceSpan,
        };
        final chunkId =
            'okf_${kbId}_chunk_${(resultChunks.length + 1).toString().padLeft(3, '0')}';
        final chunk = {
          'chunk_id': chunkId,
          'source_doc_id': sourceDocId,
          'document_id': sourceDocId,
          'block_ids': [blockId],
          'heading_path': [relativePath],
          'semantic_unit_type': 'okf_semantic_chunk',
          'source_trace_id': sourceTraceId,
          'lineage': lineage,
          'page_or_section': pageOrSection,
          'chunk_hash': _stableHash(text).toString(),
          'text': text,
          'source_path': sourcePath,
          'citation': '$relativePath#$blockId',
          if (pageNumber != null) 'page_number': pageNumber,
          if (sectionId.isNotEmpty) 'section_id': sectionId,
          if (sourceSpan.isNotEmpty) 'source_span': sourceSpan,
        };
        resultChunks.add(chunk);
        traceRows.add({
          'schema_version': 'prd_v3_okf_source_trace.v1',
          'source_trace_id': sourceTraceId,
          'kb_id': kbId,
          'chunk_id': chunk['chunk_id'],
          'source_doc_id': sourceDocId,
          'source_document': relativePath,
          'source_path': sourcePath,
          'page_or_section': pageOrSection,
          'block_ids': [blockId],
          'heading_path': [relativePath],
          'chunk_hash': chunk['chunk_hash'],
          if (pageNumber != null) 'page_number': pageNumber,
          if (sectionId.isNotEmpty) 'section_id': sectionId,
          if (sourceSpan.isNotEmpty) 'source_span': sourceSpan,
          'lineage': lineage,
          'source_trace_status': 'linked',
        });
      }
    }

    final chunksPath = _join(kbDir.path, 'chunks.jsonl');
    final sourceTracePath = _join(kbDir.path, 'source_trace.jsonl');
    await _writeJsonl(File(chunksPath), resultChunks);
    await _writeJsonl(File(sourceTracePath), traceRows);
    await File(_join(kbDir.path, 'source_map.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(_buildSourceMap(
        kbId: kbId,
        chunksPath: chunksPath,
        sourceTracePath: sourceTracePath,
        sourceDocs: sourceDocs,
        chunks: resultChunks,
        traceRows: traceRows,
      )),
      encoding: utf8,
    );
    return OkfSemanticChunkResult(
      chunks: resultChunks,
      sourceTraceRows: traceRows,
    );
  }

  Future<OkfSemanticChunkResult> _semanticChunksFromParsedDocuments({
    required String kbId,
    required List<Map<String, dynamic>> sourceDocs,
    required Map<String, Map<String, dynamic>> normalizedByRelativePath,
  }) async {
    final chunks = <Map<String, dynamic>>[];
    final traceRows = <Map<String, dynamic>>[];
    for (final sourceDoc in sourceDocs) {
      final relativePath = _stringValue(
        sourceDoc['relative_path'],
        _stringValue(sourceDoc['source_name'], 'source'),
      );
      final sourceDocId = _stringValue(
        sourceDoc['document_id'],
        'doc_${_stableHash(relativePath)}',
      );
      final record = normalizedByRelativePath[_normalize(relativePath)];
      final normalizedPath = _stringValue(record?['normalized_path']);
      final sourcePath = _stringValue(
        sourceDoc['source_path'],
        _stringValue(record?['source_path'], normalizedPath),
      );
      final blocks = _parsedDocumentBlocks(record, sourceDocId, relativePath);
      if (blocks.isEmpty) {
        if (normalizedPath.isEmpty || !await File(normalizedPath).exists()) {
          continue;
        }
        final parsedText = await File(
          normalizedPath,
        ).readAsString(encoding: utf8);
        blocks.addAll(_semanticBlocks(parsedText, sourceDocId, relativePath));
        for (final block in blocks) {
          block['parsed_document_source'] = 'normalized_text';
          block['chunking_strategy'] = 'okf_fallback_from_normalized_text';
          block['fallback_reason'] = 'parsed_document_blocks_unavailable';
        }
      }
      for (final block in blocks) {
        final blockIds = [_stringValue(block['block_id'])];
        final sourceTraceId = 'trace_${kbId}_${blockIds.first}';
        final headingPath = block['heading_path'] as List<String>;
        final text = _stringValue(block['text']);
        final blockSourcePath = _stringValue(block['source_path'], sourcePath);
        final pageOrSection = _stringValue(
          block['page_or_section'],
          headingPath.isEmpty ? relativePath : headingPath.join(' / '),
        );
        final chunkId =
            'okf_${kbId}_chunk_${(chunks.length + 1).toString().padLeft(3, '0')}';
        final chunkHash = _stableHash(text).toString();
        final pageNumber = block['page_number'];
        final sectionId = _stringValue(block['section_id']);
        final sourceSpan = _mapValue(block['source_span']);
        final lineage = {
          'kb_id': kbId,
          'source_doc_id': sourceDocId,
          'source_document': relativePath,
          'source_path': blockSourcePath,
          'normalized_path': normalizedPath,
          'block_ids': blockIds,
          'source_trace_id': sourceTraceId,
          'page_or_section': pageOrSection,
          'parsed_block_type': block['block_type'],
          'chunking_strategy':
              block['chunking_strategy'] ?? 'okf_semantic_from_parsed_document',
          'parsed_document_source':
              block['parsed_document_source'] ?? 'normalized_text',
          if (block['fallback_reason'] != null)
            'fallback_reason': block['fallback_reason'],
          if (pageNumber != null) 'page_number': pageNumber,
          if (sectionId.isNotEmpty) 'section_id': sectionId,
          if (sourceSpan.isNotEmpty) 'source_span': sourceSpan,
        };
        final chunk = {
          'chunk_id': chunkId,
          'source_doc_id': sourceDocId,
          'document_id': sourceDocId,
          'relative_path': relativePath,
          'source_document': relativePath,
          'source_path': blockSourcePath,
          'normalized_path': normalizedPath,
          'block_ids': blockIds,
          'heading_path': headingPath,
          'semantic_unit_type': 'okf_semantic_chunk',
          'source_trace_id': sourceTraceId,
          'lineage': lineage,
          'page_or_section': pageOrSection,
          'chunk_hash': chunkHash,
          'text': text,
          'citation': '$relativePath#${blockIds.first}',
          if (pageNumber != null) 'page_number': pageNumber,
          if (sectionId.isNotEmpty) 'section_id': sectionId,
          if (sourceSpan.isNotEmpty) 'source_span': sourceSpan,
        };
        chunks.add(chunk);
        traceRows.add({
          'schema_version': 'prd_v3_okf_source_trace.v1',
          'source_trace_id': sourceTraceId,
          'kb_id': kbId,
          'chunk_id': chunkId,
          'source_doc_id': sourceDocId,
          'source_document': relativePath,
          'source_path': blockSourcePath,
          'normalized_path': normalizedPath,
          'page_or_section': pageOrSection,
          'block_ids': blockIds,
          'heading_path': headingPath,
          'chunk_hash': chunkHash,
          if (pageNumber != null) 'page_number': pageNumber,
          if (sectionId.isNotEmpty) 'section_id': sectionId,
          if (sourceSpan.isNotEmpty) 'source_span': sourceSpan,
          'lineage': lineage,
          'source_trace_status': 'linked',
        });
      }
    }
    return OkfSemanticChunkResult(chunks: chunks, sourceTraceRows: traceRows);
  }

  List<Map<String, Object?>> _parsedDocumentBlocks(
    Map<String, dynamic>? record,
    String sourceDocId,
    String relativePath,
  ) {
    if (record == null) return <Map<String, Object?>>[];
    final parsedDocument = _mapValue(record['parsed_document']);
    final rawBlocks = parsedDocument['blocks'] is List
        ? parsedDocument['blocks']
        : record['blocks'];
    if (rawBlocks is! List) return <Map<String, Object?>>[];
    final blocks = <Map<String, Object?>>[];
    for (final item in rawBlocks.whereType<Map>()) {
      final text = _stringValue(
        item['text'],
        _stringValue(item['content'], _stringValue(item['summary'])),
      );
      if (text.isEmpty) continue;
      final blockId = _stringValue(
        item['block_id'],
        '${sourceDocId}_block_${(blocks.length + 1).toString().padLeft(3, '0')}',
      );
      final headingPath = _stringList(item['heading_path']);
      final pageNumber = item['page_number'];
      final sectionId = _stringValue(item['section_id']);
      final sourcePath = _stringValue(item['source_path']);
      final pageOrSection = _stringValue(item['page_or_section']);
      final sourceSpan = _mapValue(item['source_span']);
      blocks.add({
        'block_id': blockId,
        'block_type': _stringValue(item['block_type'], 'paragraph'),
        'heading_path': headingPath.isEmpty
            ? <String>[relativePath]
            : headingPath,
        'text': text,
        'parsed_document_source': 'canonical_blocks',
        if (sourcePath.isNotEmpty) 'source_path': sourcePath,
        if (pageOrSection.isNotEmpty) 'page_or_section': pageOrSection,
        if (pageNumber != null) 'page_number': pageNumber,
        if (sectionId.isNotEmpty) 'section_id': sectionId,
        if (sourceSpan.isNotEmpty) 'source_span': sourceSpan,
      });
    }
    return blocks;
  }
  List<Map<String, Object?>> _semanticBlocks(
    String text,
    String sourceDocId,
    String relativePath,
  ) {
    final blocks = <Map<String, Object?>>[];
    final headingPath = <String>[];
    final buffer = <String>[];

    void flush(String blockType) {
      final content = buffer.join('\n').trim();
      buffer.clear();
      if (content.isEmpty) return;
      blocks.add({
        'block_id':
            '${sourceDocId}_block_${(blocks.length + 1).toString().padLeft(3, '0')}',
        'block_type': blockType,
        'heading_path': headingPath.isEmpty
            ? <String>[relativePath]
            : List<String>.from(headingPath),
        'text': content,
      });
    }

    for (final line in const LineSplitter().convert(text)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        flush('paragraph');
        continue;
      }
      final headingMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(trimmed);
      if (headingMatch != null) {
        flush('paragraph');
        final level = headingMatch.group(1)!.length;
        while (headingPath.length >= level) {
          headingPath.removeLast();
        }
        headingPath.add(headingMatch.group(2)!.trim());
        blocks.add({
          'block_id':
              '${sourceDocId}_block_${(blocks.length + 1).toString().padLeft(3, '0')}',
          'block_type': 'heading',
          'heading_path': List<String>.from(headingPath),
          'text': headingMatch.group(2)!.trim(),
        });
        continue;
      }
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        flush('paragraph');
        blocks.add({
          'block_id':
              '${sourceDocId}_block_${(blocks.length + 1).toString().padLeft(3, '0')}',
          'block_type': 'list_item',
          'heading_path': headingPath.isEmpty
              ? <String>[relativePath]
              : List<String>.from(headingPath),
          'text': trimmed.substring(2).trim(),
        });
        continue;
      }
      buffer.add(line);
    }
    flush('paragraph');
    if (blocks.isEmpty && text.trim().isNotEmpty) {
      blocks.add({
        'block_id': '${sourceDocId}_block_001',
        'block_type': 'paragraph',
        'heading_path': <String>[relativePath],
        'text': text.trim(),
      });
    }
    return blocks;
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  Future<List<Map<String, dynamic>>> _readDocumentUnderstandingRecords(
    Directory workspace,
  ) async {
    final file = File(
      _join(workspace.path, 'du', 'document_understanding_records.jsonl'),
    );
    if (!await file.exists()) return const [];
    final rows = <Map<String, dynamic>>[];
    for (final line in await file.readAsLines(encoding: utf8)) {
      if (line.trim().isEmpty) continue;
      final decoded = jsonDecode(line);
      if (decoded is Map<String, dynamic>) {
        rows.add(decoded);
      } else if (decoded is Map) {
        rows.add(decoded.cast<String, dynamic>());
      }
    }
    return rows;
  }

  String _relativePathForChunk(
    Map<String, dynamic> chunk,
    Map<String, Map<String, dynamic>> normalizedByRelativePath, {
    required String fallbackRelativePath,
  }) {
    final direct = _stringValue(
      chunk['relative_path'],
      _stringValue(
        chunk['source_document'],
        _stringValue(chunk['source_name']),
      ),
    );
    if (direct.isNotEmpty) return direct;
    final sourcePath = _normalize(chunk['source_path'] ?? chunk['source']);
    if (sourcePath.isNotEmpty) {
      for (final entry in normalizedByRelativePath.entries) {
        final normalizedPath = _normalize(entry.value['normalized_path']);
        if (normalizedPath.isNotEmpty && sourcePath == normalizedPath) {
          return _stringValue(entry.value['relative_path']);
        }
      }
      final lastSegment = sourcePath.split('/').last;
      if (lastSegment.isNotEmpty) return lastSegment;
    }
    return fallbackRelativePath;
  }

  List<String> _blockIds(
    Map<String, dynamic> chunk,
    String sourceDocId,
    int index,
  ) {
    final raw = chunk['block_ids'];
    if (raw is List) {
      final ids = raw
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      if (ids.isNotEmpty) return ids;
    }
    final blockId = _stringValue(
      chunk['block_id'],
      '${sourceDocId}_block_${(index + 1).toString().padLeft(3, '0')}',
    );
    return [blockId];
  }

  List<String> _headingPath(Map<String, dynamic> chunk, String relativePath) {
    final raw = chunk['heading_path'];
    if (raw is List) {
      return raw
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    final heading = _stringValue(chunk['heading'], '');
    if (heading.isNotEmpty) return [heading];
    return relativePath.isEmpty ? const <String>[] : [relativePath];
  }

  Future<void> _writeJsonl(File file, List<Map<String, dynamic>> rows) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      rows.isEmpty ? '' : '${rows.map(jsonEncode).join('\n')}\n',
      encoding: utf8,
    );
  }

  Map<String, dynamic> _buildSourceMap({
    required String kbId,
    required String chunksPath,
    required String sourceTracePath,
    required List<Map<String, dynamic>> sourceDocs,
    required List<Map<String, dynamic>> chunks,
    required List<Map<String, dynamic>> traceRows,
  }) {
    final documentsById = <String, Map<String, dynamic>>{};

    Map<String, dynamic> ensureDocument({
      required String sourceDocId,
      required String sourceDocument,
      required String sourcePath,
    }) {
      final key = _stringValue(
        sourceDocId,
        _stringValue(sourceDocument, sourcePath),
      );
      return documentsById.putIfAbsent(key, () {
        final relativePath = _stringValue(sourceDocument, sourcePath);
        return {
          'source_doc_id': key,
          'document_id': key,
          'source_document': relativePath,
          'relative_path': relativePath,
          'source_path': _stringValue(sourcePath, relativePath),
          'chunk_ids': <String>[],
          'source_trace_ids': <String>[],
          'block_ids': <String>[],
          'page_or_sections': <String>[],
          'page_numbers': <int>[],
          'section_ids': <String>[],
          'source_spans': <Map<String, dynamic>>[],
          'heading_paths': <String>[],
        };
      });
    }

    for (final sourceDoc in sourceDocs) {
      ensureDocument(
        sourceDocId: _stringValue(
          sourceDoc['document_id'],
          _stringValue(sourceDoc['source_doc_id']),
        ),
        sourceDocument: _stringValue(
          sourceDoc['relative_path'],
          _stringValue(sourceDoc['source_name']),
        ),
        sourcePath: _stringValue(sourceDoc['source_path']),
      );
    }

    for (final chunk in chunks) {
      final document = ensureDocument(
        sourceDocId: _stringValue(
          chunk['source_doc_id'],
          _stringValue(chunk['document_id']),
        ),
        sourceDocument: _stringValue(
          chunk['source_document'],
          _stringValue(chunk['relative_path']),
        ),
        sourcePath: _stringValue(chunk['source_path']),
      );
      _addUniqueString(document['chunk_ids'] as List<String>,
          _stringValue(chunk['chunk_id']));
      _addUniqueString(document['source_trace_ids'] as List<String>,
          _stringValue(chunk['source_trace_id']));
      for (final blockId in _stringList(chunk['block_ids'])) {
        _addUniqueString(document['block_ids'] as List<String>, blockId);
      }
      _addUniqueString(document['page_or_sections'] as List<String>,
          _stringValue(chunk['page_or_section']));
      _addUniqueInt(document['page_numbers'] as List<int>,
          _intValue(chunk['page_number']));
      _addUniqueString(document['section_ids'] as List<String>,
          _stringValue(chunk['section_id']));
      _addUniqueMap(document['source_spans'] as List<Map<String, dynamic>>,
          _mapValue(chunk['source_span']));
      final headingPath = _stringList(chunk['heading_path']).join(' / ');
      _addUniqueString(document['heading_paths'] as List<String>, headingPath);
    }

    for (final trace in traceRows) {
      final document = ensureDocument(
        sourceDocId: _stringValue(trace['source_doc_id']),
        sourceDocument: _stringValue(trace['source_document']),
        sourcePath: _stringValue(trace['source_path']),
      );
      _addUniqueString(document['source_trace_ids'] as List<String>,
          _stringValue(trace['source_trace_id']));
      _addUniqueString(document['chunk_ids'] as List<String>,
          _stringValue(trace['chunk_id']));
      for (final blockId in _stringList(trace['block_ids'])) {
        _addUniqueString(document['block_ids'] as List<String>, blockId);
      }
      _addUniqueString(document['page_or_sections'] as List<String>,
          _stringValue(trace['page_or_section']));
      _addUniqueInt(document['page_numbers'] as List<int>,
          _intValue(trace['page_number']));
      _addUniqueString(document['section_ids'] as List<String>,
          _stringValue(trace['section_id']));
      _addUniqueMap(document['source_spans'] as List<Map<String, dynamic>>,
          _mapValue(trace['source_span']));
      final headingPath = _stringList(trace['heading_path']).join(' / ');
      _addUniqueString(document['heading_paths'] as List<String>, headingPath);
    }

    final documents = documentsById.values.map((document) {
      final chunkIds = document['chunk_ids'] as List<String>;
      final sourceTraceIds = document['source_trace_ids'] as List<String>;
      return {
        ...document,
        'chunk_count': chunkIds.length,
        'source_trace_count': sourceTraceIds.length,
      };
    }).toList(growable: false);

    return {
      'schema_version': 'prd_v3_okf_source_map.v1',
      'kb_id': kbId,
      'chunks_path': chunksPath,
      'source_trace_path': sourceTracePath,
      'chunk_count': chunks.length,
      'source_trace_count': traceRows.length,
      'document_count': documents.length,
      'okf_semantic_chunking': true,
      'documents': documents,
    };
  }

  void _addUniqueString(List<String> values, String value) {
    if (value.isEmpty || values.contains(value)) return;
    values.add(value);
  }

  void _addUniqueInt(List<int> values, int? value) {
    if (value == null || values.contains(value)) return;
    values.add(value);
  }

  void _addUniqueMap(
    List<Map<String, dynamic>> values,
    Map<String, dynamic> value,
  ) {
    if (value.isEmpty) return;
    final encoded = jsonEncode(value);
    if (values.any((item) => jsonEncode(item) == encoded)) return;
    values.add(value);
  }

  Map<String, dynamic> _mapValue(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  String _stringValue(Object? value, [String fallback = '']) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  int? _intValue(Object? value) {
    if (value is int) return value;
    return int.tryParse(_stringValue(value));
  }

  String _normalize(Object? value) {
    return (value ?? '').toString().replaceAll('\\', '/').trim().toLowerCase();
  }

  int _stableHash(String value) {
    return value.codeUnits.fold<int>(
      17,
      (hash, unit) => (hash * 31 + unit) & 0x7fffffff,
    );
  }

  String _join(String part1, String part2, [String? part3]) {
    return [
      part1,
      part2,
      if (part3 != null) part3,
    ].where((part) => part.isNotEmpty).join(Platform.pathSeparator);
  }
}
