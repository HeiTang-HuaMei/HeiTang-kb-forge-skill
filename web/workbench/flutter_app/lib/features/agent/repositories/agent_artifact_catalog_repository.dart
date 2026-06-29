import 'dart:convert';
import 'dart:io';

class AgentArtifactCatalogRepository {
  const AgentArtifactCatalogRepository();

  static String catalogPath(Directory workspace) {
    return _joinNested(workspace.path, 'agent/artifacts/artifact_catalog.json');
  }

  static String replyArtifactPath({
    required Directory workspace,
    required String agentId,
    required String messageId,
  }) {
    return _joinNested(
      workspace.path,
      'agent/artifacts/$agentId-${_safeId(messageId)}.md',
    );
  }

  Future<Map<String, dynamic>> readCatalog(Directory workspace) async {
    final file = File(catalogPath(workspace));
    if (!await file.exists()) return const <String, dynamic>{};
    final text = await file.readAsString(encoding: utf8);
    if (text.trim().isEmpty) return const <String, dynamic>{};
    final decoded = jsonDecode(text);
    return decoded is Map
        ? decoded.cast<String, dynamic>()
        : const <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> readRows(Directory workspace) async {
    final catalog = await readCatalog(workspace);
    return _rows(catalog['artifacts']);
  }

  Future<(String, List<Map<String, dynamic>>)> addReplyArtifact({
    required Directory workspace,
    required String catalogStatus,
    required Map<String, dynamic> record,
    required String updatedAt,
  }) async {
    final records = (await readRows(workspace)).toList(growable: true);
    records.add(record);
    await _writeCatalog(
      workspace: workspace,
      status: catalogStatus,
      records: records,
      updatedAt: updatedAt,
    );
    return (catalogPath(workspace), records);
  }

  Future<AgentReplyArtifactSaveResult> saveReplyArtifact({
    required Directory workspace,
    required String agentId,
    required String agentName,
    required String messageId,
    required List<String> markdownLines,
    required String savedStatus,
    required String catalogStatus,
    required String updatedAt,
  }) async {
    final artifactPath = replyArtifactPath(
      workspace: workspace,
      agentId: agentId,
      messageId: messageId,
    );
    await File(artifactPath).parent.create(recursive: true);
    await File(artifactPath).writeAsString(
      markdownLines.join('\n'),
      encoding: utf8,
    );
    final records = (await readRows(workspace)).toList(growable: true);
    final artifactId = 'agent_reply_${records.length + 1}';
    records.add({
      'artifact_id': artifactId,
      'agent_id': agentId,
      'agent_name': agentName,
      'message_id': messageId,
      'path': artifactPath,
      'status': savedStatus,
      'created_at': updatedAt,
    });
    await _writeCatalog(
      workspace: workspace,
      status: catalogStatus,
      records: records,
      updatedAt: updatedAt,
    );
    return AgentReplyArtifactSaveResult(
      artifactId: artifactId,
      artifactPath: artifactPath,
      catalogPath: catalogPath(workspace),
      records: records,
    );
  }

  Future<AgentArtifactDeleteResult?> deleteById({
    required Directory workspace,
    required String artifactId,
    required String updatedAt,
  }) async {
    final records = (await readRows(workspace)).toList(growable: true);
    final index = records.indexWhere(
        (artifact) => (artifact['artifact_id'] ?? '').toString() == artifactId);
    if (index < 0) return null;
    final removed = records.removeAt(index);
    await _writeCatalog(
      workspace: workspace,
      status: records.isEmpty
          ? 'no_agent_reply_artifacts'
          : 'local_fallback_artifacts_recorded',
      records: records,
      updatedAt: updatedAt,
    );
    return AgentArtifactDeleteResult(
      catalogPath: catalogPath(workspace),
      removed: removed,
      remaining: records,
    );
  }

  Future<void> _writeCatalog({
    required Directory workspace,
    required String status,
    required List<Map<String, dynamic>> records,
    required String updatedAt,
  }) async {
    final file = File(catalogPath(workspace));
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schema_version': 'heitang_agent_artifact_catalog.v1',
        'status': status,
        'artifacts': records,
        'updated_at': updatedAt,
      }),
      encoding: utf8,
    );
  }

  static List<Map<String, dynamic>> _rows(Object? raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList(growable: false);
  }

  static String _safeId(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_\-\u4e00-\u9fa5]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'item' : normalized;
  }

  static String _joinNested(String root, String nested) {
    final separator = Platform.pathSeparator;
    final parts = nested
        .split(RegExp(r'[\\/]'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    var current = root;
    for (final part in parts) {
      current =
          current.endsWith(separator) ? '$current$part' : '$current$separator$part';
    }
    return current;
  }
}

class AgentReplyArtifactSaveResult {
  const AgentReplyArtifactSaveResult({
    required this.artifactId,
    required this.artifactPath,
    required this.catalogPath,
    required this.records,
  });

  final String artifactId;
  final String artifactPath;
  final String catalogPath;
  final List<Map<String, dynamic>> records;
}

class AgentArtifactDeleteResult {
  const AgentArtifactDeleteResult({
    required this.catalogPath,
    required this.removed,
    required this.remaining,
  });

  final String catalogPath;
  final Map<String, dynamic> removed;
  final List<Map<String, dynamic>> remaining;
}
