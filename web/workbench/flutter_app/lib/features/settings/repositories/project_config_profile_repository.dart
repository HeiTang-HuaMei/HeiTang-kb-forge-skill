import 'dart:convert';
import 'dart:io';

import '../../../domain/config_profile/project_config_profile.dart';

class ProjectConfigProfileReadResult {
  const ProjectConfigProfileReadResult({
    required this.status,
    required this.profiles,
    this.backupPath = '',
  });

  final String status;
  final List<ProjectConfigProfile> profiles;
  final String backupPath;

  bool get hasProfiles => profiles.isNotEmpty;
}

class ProjectConfigProfileRepository {
  const ProjectConfigProfileRepository();

  static String profilesPath(Directory workspace) {
    return _join(workspace.path, 'config', 'project_config_profiles.json');
  }

  Future<ProjectConfigProfileReadResult> readProfiles(
    Directory workspace,
  ) async {
    final path = profilesPath(workspace);
    final file = File(path);
    if (!await file.exists()) {
      return const ProjectConfigProfileReadResult(
        status: 'missing',
        profiles: <ProjectConfigProfile>[],
      );
    }
    late final Map<String, dynamic> payload;
    try {
      payload = await _readJsonObject(path);
    } on FormatException {
      final backupPath =
          '$path.corrupt.${DateTime.now().toUtc().microsecondsSinceEpoch}.bak';
      await file.rename(backupPath);
      return ProjectConfigProfileReadResult(
        status: 'corrupt',
        profiles: const <ProjectConfigProfile>[],
        backupPath: backupPath,
      );
    }
    final rawProfiles = payload['profiles'];
    final profiles = rawProfiles is List
        ? rawProfiles
            .whereType<Map>()
            .map((item) =>
                ProjectConfigProfile.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : <ProjectConfigProfile>[];
    return ProjectConfigProfileReadResult(
      status: profiles.isEmpty ? 'empty' : 'loaded',
      profiles: profiles,
    );
  }

  Future<void> writeProfiles({
    required Directory workspace,
    required List<ProjectConfigProfile> profiles,
    required ProjectConfigProfile activeProfile,
  }) async {
    final path = profilesPath(workspace);
    await File(path).parent.create(recursive: true);
    final payload = {
      'schema_version': 'prd_v3_project_config_profiles.v1',
      'workspace_id': workspace.path,
      'active_profile_id': activeProfile.profileId,
      'profile_count': profiles.length,
      'profiles': profiles.map((profile) => profile.toJson()).toList(),
      'secret_plaintext_written': false,
    };
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
  }

  static Future<Map<String, dynamic>> _readJsonObject(String path) async {
    final file = File(path);
    final text = await file.readAsString(encoding: utf8);
    if (text.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(text);
    return decoded is Map
        ? decoded.cast<String, dynamic>()
        : <String, dynamic>{};
  }

  static String _join(String part1, String part2, String part3) {
    final separator = Platform.pathSeparator;
    String joinTwo(String left, String right) {
      if (left.isEmpty) return right;
      if (right.isEmpty) return left;
      return left.endsWith(separator) ? '$left$right' : '$left$separator$right';
    }

    return joinTwo(joinTwo(part1, part2), part3);
  }
}
