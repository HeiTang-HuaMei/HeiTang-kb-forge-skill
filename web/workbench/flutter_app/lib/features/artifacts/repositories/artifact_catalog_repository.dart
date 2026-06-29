import 'dart:convert';
import 'dart:io';

class ArtifactCatalogRepository {
  const ArtifactCatalogRepository();

  static String catalogPath(Directory workspace) {
    return _joinNested(workspace.path, 'artifacts/catalog.json');
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

  static Map<String, dynamic> readCatalogSync(Directory workspace) {
    final file = File(catalogPath(workspace));
    if (!file.existsSync()) return const <String, dynamic>{};
    final text = file.readAsStringSync(encoding: utf8);
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

  static List<Map<String, dynamic>> readRowsSync(Directory workspace) {
    final catalog = readCatalogSync(workspace);
    return _rows(catalog['artifacts']);
  }

  Future<void> writeCatalog({
    required Directory workspace,
    required String workspaceId,
    required List<Map<String, dynamic>> records,
    required String updatedAt,
    bool compatibilityMirror = false,
    String activeWorkbookPath = '',
  }) async {
    final payload = <String, Object?>{
      'schema_version': 'heitang_artifact_catalog.v1',
      'workspace_id': workspaceId,
      'status': _hasActiveRecord(records) ? 'active' : 'empty',
      if (compatibilityMirror) 'compatibility_mirror': true,
      if (activeWorkbookPath.isNotEmpty)
        'active_workbook_path': activeWorkbookPath,
      'artifacts': records,
      'updated_at': updatedAt,
    };
    await _writeJsonFile(File(catalogPath(workspace)), payload);
  }

  Future<List<Map<String, dynamic>>> upsertRecord({
    required Directory workspace,
    required String workspaceId,
    required Map<String, dynamic> record,
    required String updatedAt,
  }) async {
    final records = (await readRows(workspace)).toList(growable: true);
    final artifactId = (record['artifact_id'] ?? '').toString();
    final index = records.indexWhere(
        (row) => (row['artifact_id'] ?? '').toString() == artifactId);
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    await writeCatalog(
      workspace: workspace,
      workspaceId: workspaceId,
      records: records,
      updatedAt: updatedAt,
    );
    return records;
  }

  Future<List<Map<String, dynamic>>> markDeleted({
    required Directory workspace,
    required String workspaceId,
    required String artifactId,
    required String status,
    required String updatedAt,
    required Map<String, dynamic> missingRecord,
    required Map<String, dynamic> Function(Map<String, dynamic> row)
        updateExisting,
  }) async {
    final records = (await readRows(workspace)).toList(growable: true);
    final index = records.indexWhere(
        (row) => (row['artifact_id'] ?? '').toString() == artifactId);
    if (index >= 0) {
      records[index] = updateExisting(records[index]);
    } else {
      records.add(missingRecord);
    }
    await writeCatalog(
      workspace: workspace,
      workspaceId: workspaceId,
      records: records,
      updatedAt: updatedAt,
    );
    return records;
  }

  Future<List<Map<String, dynamic>>> reconcileMissingPaths({
    required Directory workspace,
    required String workspaceId,
    required String updatedAt,
  }) async {
    final records = (await readRows(workspace)).toList(growable: true);
    if (records.isEmpty) return const <Map<String, dynamic>>[];
    var changed = false;
    for (var index = 0; index < records.length; index++) {
      final status = (records[index]['status'] ?? '').toString();
      final path = (records[index]['file_path'] ?? '').toString().trim();
      if (status == 'deleted' || path.isEmpty) continue;
      final exists =
          await File(path).exists() || await Directory(path).exists();
      if (exists) continue;
      records[index] = {
        ...records[index],
        'updated_at': updatedAt,
        'status': 'deleted',
        'metadata': {
          ..._map(records[index]['metadata']),
          'deleted_by': 'artifact_catalog_reconcile',
          'missing_path': path,
        },
      };
      changed = true;
    }
    if (!changed) return const <Map<String, dynamic>>[];
    await writeCatalog(
      workspace: workspace,
      workspaceId: workspaceId,
      records: records,
      updatedAt: updatedAt,
    );
    return records;
  }

  static bool _hasActiveRecord(List<Map<String, dynamic>> records) {
    return records.any((row) =>
        (row['status'] ?? '').toString() != 'deleted' &&
        (row['file_path'] ?? '').toString().isNotEmpty);
  }

  static List<Map<String, dynamic>> _rows(Object? raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList(growable: false);
  }

  static Map<String, dynamic> _map(Object? raw) {
    return raw is Map ? raw.cast<String, dynamic>() : <String, dynamic>{};
  }

  static Future<void> _writeJsonFile(
    File file,
    Map<String, Object?> payload,
  ) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
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
