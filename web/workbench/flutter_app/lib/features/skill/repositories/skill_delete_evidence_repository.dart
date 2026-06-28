import 'dart:convert';
import 'dart:io';

class SkillDeleteEvidenceResult {
  const SkillDeleteEvidenceResult({
    required this.deleteDirPath,
    required this.tombstonePath,
    required this.historyPath,
    required this.manifestPath,
  });

  final String deleteDirPath;
  final String tombstonePath;
  final String historyPath;
  final String manifestPath;
}

class SkillDeleteEvidenceRepository {
  const SkillDeleteEvidenceRepository();

  Future<SkillDeleteEvidenceResult> writeDeleteEvidence({
    required Directory workspace,
    required Iterable<String> deletedSkillIds,
    required Iterable<String> sourceKbIds,
    required Iterable<String> deletedPaths,
    required bool kbAssetsDeleted,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final deleteRoot = Directory(_join(workspace.path, 'skill_deletions'));
    await deleteRoot.create(recursive: true);
    final deleteDir = Directory(_join(deleteRoot.path,
        'delete_${DateTime.now().microsecondsSinceEpoch}'));
    await deleteDir.create(recursive: true);

    final normalizedSkillIds = _unique(deletedSkillIds);
    final normalizedSourceKbIds = _unique(sourceKbIds);
    final normalizedDeletedPaths = _unique(deletedPaths);
    final tombstonePath = _join(deleteDir.path, 'skill_delete_tombstone.json');
    final historyPath = _join(deleteDir.path, 'skill_operation_history.json');
    final manifestPath = _join(deleteDir.path, 'skill_delete_manifest.json');
    final tombstone = {
      'schema_version': 'prd_v3_skill_delete_tombstone.v1',
      'status': 'deleted',
      'deleted_at': now,
      'deleted_skill_ids': normalizedSkillIds,
      'source_kb_ids': normalizedSourceKbIds,
      'deleted_paths': normalizedDeletedPaths,
      'kb_assets_deleted': kbAssetsDeleted,
      'real_user_data_deleted': false,
      'restart_recovery': {
        'tombstone_path': tombstonePath,
        'history_path': historyPath,
        'manifest_path': manifestPath,
      },
    };
    final history = {
      'schema_version': 'prd_v2_skill_operation_history.v1',
      'status': 'pass',
      'workspace': workspace.path,
      'records': [
        {
          'operation_id': 'skill_delete_001',
          'action': 'delete_skill',
          'artifact': tombstonePath,
          'status': 'deleted',
          'created_at': now,
          'details': {
            'deleted_skill_ids': normalizedSkillIds,
            'source_kb_ids': normalizedSourceKbIds,
            'kb_assets_deleted': kbAssetsDeleted,
            'deleted_paths': normalizedDeletedPaths,
          },
        }
      ],
    };
    final manifest = {
      'schema_version': 'prd_v3_skill_delete_manifest.v1',
      'status': 'deleted',
      'created_at': now,
      'tombstone_path': tombstonePath,
      'history_path': historyPath,
      'deleted_skill_ids': normalizedSkillIds,
      'source_kb_ids': normalizedSourceKbIds,
      'kb_assets_deleted': kbAssetsDeleted,
    };
    await _writeJson(tombstonePath, tombstone);
    await _writeJson(historyPath, history);
    await _writeJson(manifestPath, manifest);
    return SkillDeleteEvidenceResult(
      deleteDirPath: deleteDir.path,
      tombstonePath: tombstonePath,
      historyPath: historyPath,
      manifestPath: manifestPath,
    );
  }

  static Future<void> _writeJson(
    String path,
    Map<String, Object?> payload,
  ) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
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

  static String _join(String first, String second) {
    if (first.endsWith(Platform.pathSeparator)) return '$first$second';
    return '$first${Platform.pathSeparator}$second';
  }
}
