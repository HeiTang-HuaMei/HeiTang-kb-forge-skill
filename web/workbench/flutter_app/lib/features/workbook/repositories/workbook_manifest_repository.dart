import 'dart:convert';
import 'dart:io';

class WorkbookManifestRepository {
  const WorkbookManifestRepository();

  static const defaultWorkbookName = '默认工作本';

  static String manifestPath(Directory workspace) {
    return _join(workspace.path, 'workbooks', 'workbook_manifest.json');
  }

  Future<Map<String, dynamic>> readManifest(Directory workspace) async {
    final file = File(manifestPath(workspace));
    if (!await file.exists()) return const <String, dynamic>{};
    final text = await file.readAsString(encoding: utf8);
    if (text.trim().isEmpty) return const <String, dynamic>{};
    final decoded = jsonDecode(text);
    return decoded is Map
        ? decoded.cast<String, dynamic>()
        : const <String, dynamic>{};
  }

  Future<bool> exists(Directory workspace) async {
    return File(manifestPath(workspace)).exists();
  }

  Future<(String, List<String>)> readCurrentAndNames(
    Directory workspace,
  ) async {
    final manifest = await readManifest(workspace);
    final current = (manifest['current_workbook'] ?? defaultWorkbookName)
        .toString()
        .trim();
    final names = workbookRows(manifest)
        .map((row) => (row['name'] ?? '').toString().trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: true);
    if (names.isEmpty) names.add(current.isEmpty ? defaultWorkbookName : current);
    final effectiveCurrent = current.isEmpty ? names.first : current;
    if (!names.contains(effectiveCurrent)) names.insert(0, effectiveCurrent);
    return (effectiveCurrent, List<String>.unmodifiable(names));
  }

  Future<String> upsertWorkbook({
    required Directory workspace,
    required String currentName,
    required String addName,
    required Map<String, Object?> assetIndex,
    required int documentCount,
    required int knowledgeBaseCount,
    required int Function(String value) stableHash,
    required String updatedAt,
  }) async {
    final manifest = await readManifest(workspace);
    final rows = workbookRows(manifest).toList(growable: true);
    final normalizedAdd =
        addName.trim().isEmpty ? defaultWorkbookName : addName.trim();
    if (rows.isEmpty) {
      rows.add(_newWorkbookRow(
        name: normalizedAdd,
        currentName: currentName,
        stableHash: stableHash,
        now: updatedAt,
        assetIndex: assetIndex,
        documentCount: documentCount,
        knowledgeBaseCount: knowledgeBaseCount,
      ));
    }
    var found = false;
    for (final row in rows) {
      if ((row['name'] ?? '').toString() == normalizedAdd) {
        row['status'] = 'active';
        row['last_opened_at'] = updatedAt;
        row['document_count'] = documentCount;
        row['knowledge_base_count'] = knowledgeBaseCount;
        row['asset_index'] = assetIndex;
        found = true;
      } else {
        row['status'] = 'available';
      }
    }
    if (!found) {
      rows.add(_newWorkbookRow(
        name: normalizedAdd,
        currentName: normalizedAdd,
        stableHash: stableHash,
        now: updatedAt,
        assetIndex: assetIndex,
        documentCount: documentCount,
        knowledgeBaseCount: knowledgeBaseCount,
      ));
    }
    final effectiveCurrent =
        currentName.trim().isEmpty ? normalizedAdd : currentName.trim();
    await writeManifest(workspace, {
      'schema_version': 'prd_v2_workbook_manifest.v1',
      'workspace_path': workspace.path,
      'current_workbook': effectiveCurrent,
      'workbooks': rows,
    });
    return manifestPath(workspace);
  }

  Future<(String, String, List<String>)?> deleteWorkbook({
    required Directory workspace,
    required String name,
    required String fallbackCurrentName,
    required String updatedAt,
  }) async {
    final path = manifestPath(workspace);
    if (!await File(path).exists()) return null;
    final existing = await readManifest(workspace);
    final rows = workbookRows(existing)
        .where((row) => (row['name'] ?? '').toString().trim().isNotEmpty)
        .toList(growable: true);
    final target = name.trim();
    final index = rows
        .indexWhere((row) => (row['name'] ?? '').toString().trim() == target);
    if (index < 0 || rows.length <= 1) return null;
    rows.removeAt(index);
    final previousCurrent =
        (existing['current_workbook'] ?? fallbackCurrentName).toString().trim();
    final deletedCurrent = previousCurrent == target;
    final defaultIndex = rows.indexWhere(
        (row) => (row['name'] ?? '').toString().trim() == defaultWorkbookName);
    final nextCurrent = deletedCurrent
        ? (defaultIndex >= 0
            ? (rows[defaultIndex]['name'] ?? '').toString().trim()
            : (rows.first['name'] ?? '').toString().trim())
        : previousCurrent;
    final effectiveCurrent = nextCurrent.isEmpty
        ? (rows.first['name'] ?? defaultWorkbookName).toString()
        : nextCurrent;
    for (final row in rows) {
      final rowName = (row['name'] ?? '').toString().trim();
      row['status'] = rowName == effectiveCurrent ? 'active' : 'available';
      if (rowName == effectiveCurrent) {
        row['last_opened_at'] = updatedAt;
      }
    }
    await writeManifest(workspace, {
      ...existing,
      'schema_version': 'prd_v2_workbook_manifest.v1',
      'workspace_path': workspace.path,
      'current_workbook': effectiveCurrent,
      'workbooks': rows,
    });
    return (
      path,
      effectiveCurrent,
      List<String>.unmodifiable(rows
          .map((row) => (row['name'] ?? '').toString().trim())
          .where((rowName) => rowName.isNotEmpty))
    );
  }

  Future<String> updateAssetIndex({
    required Directory workspace,
    required String currentName,
    required Map<String, Object?> assetIndex,
    required int documentCount,
    required int knowledgeBaseCount,
    required String updatedAt,
  }) async {
    final path = manifestPath(workspace);
    if (!await File(path).exists()) return '';
    final existing = await readManifest(workspace);
    final rows = workbookRows(existing).toList(growable: true);
    if (rows.isEmpty) return path;
    final effectiveCurrent = currentName.trim().isEmpty
        ? (existing['current_workbook'] ?? defaultWorkbookName).toString().trim()
        : currentName.trim();
    final index = rows.indexWhere(
        (row) => (row['name'] ?? '').toString().trim() == effectiveCurrent);
    if (index < 0) return path;
    rows[index]['asset_index'] = assetIndex;
    rows[index]['document_count'] = documentCount;
    rows[index]['knowledge_base_count'] = knowledgeBaseCount;
    rows[index]['updated_at'] = updatedAt;
    await writeManifest(workspace, {
      ...existing,
      'current_workbook': effectiveCurrent,
      'workbooks': rows,
    });
    return path;
  }

  Future<void> writeManifest(
    Directory workspace,
    Map<String, Object?> payload,
  ) async {
    final file = File(manifestPath(workspace));
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
  }

  static List<Map<String, dynamic>> workbookRows(Map<String, dynamic> manifest) {
    final rows = manifest['workbooks'];
    if (rows is! List) return const <Map<String, dynamic>>[];
    return rows
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList(growable: false);
  }

  static Map<String, dynamic> _newWorkbookRow({
    required String name,
    required String currentName,
    required int Function(String value) stableHash,
    required String now,
    required Map<String, Object?> assetIndex,
    required int documentCount,
    required int knowledgeBaseCount,
  }) {
    return {
      'workbook_id': 'WB_${stableHash(name)}',
      'name': name,
      'status': name == currentName ? 'active' : 'available',
      'created_at': now,
      'last_opened_at': now,
      'document_count': documentCount,
      'knowledge_base_count': knowledgeBaseCount,
      'asset_index': assetIndex,
    };
  }

  static String _join(String part1, String part2, [String? part3]) {
    return [part1, part2, if (part3 != null) part3]
        .where((part) => part.isNotEmpty)
        .join(Platform.pathSeparator);
  }
}
