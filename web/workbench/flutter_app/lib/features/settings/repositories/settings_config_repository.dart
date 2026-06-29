import 'dart:convert';
import 'dart:io';

class SettingsConfigRepository {
  const SettingsConfigRepository();

  static String storageProviderSettingsPath(Directory workspace) {
    return _join(workspace.path, 'config', 'storage_provider_settings.json');
  }

  static String providerRuntimeSettingsPath(Directory workspace) {
    return _join(workspace.path, 'config', 'provider_runtime_settings.json');
  }

  static String exporterSettingsPath(Directory workspace) {
    return _join(workspace.path, 'config', 'exporter_settings.json');
  }

  Future<Map<String, dynamic>> readJson(String path) async {
    final file = File(path);
    if (!await file.exists()) return <String, dynamic>{};
    final text = await file.readAsString(encoding: utf8);
    if (text.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(text);
    return decoded is Map
        ? decoded.cast<String, dynamic>()
        : <String, dynamic>{};
  }

  Future<void> writeJson(String path, Map<String, dynamic> payload) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      encoding: utf8,
    );
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
