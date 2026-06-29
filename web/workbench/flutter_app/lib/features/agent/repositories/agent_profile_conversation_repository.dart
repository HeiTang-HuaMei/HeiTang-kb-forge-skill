import 'dart:convert';
import 'dart:io';

class AgentProfileConversationRepository {
  const AgentProfileConversationRepository();

  static String catalogPath(Directory workspace) {
    return _joinNested(workspace.path, 'agent/catalog/agents.json');
  }

  static String conversationPath(Directory workspace, String agentId) {
    return _joinNested(
      workspace.path,
      'agent/conversations/${_safeId(agentId)}/conversation.json',
    );
  }

  static String conversationDir(Directory workspace, String agentId) {
    return _joinNested(
      workspace.path,
      'agent/conversations/${_safeId(agentId)}',
    );
  }

  static String activityLogPath(Directory workspace) {
    return _joinNested(workspace.path, 'agent/activity/agent_activity.jsonl');
  }

  static String runHistoryPath(Directory workspace) {
    return _joinNested(workspace.path, 'agent/audit/run_history.json');
  }

  static String citationTracePath(Directory workspace, String agentId) {
    return _joinNested(
      workspace.path,
      'agent/conversations/${_safeId(agentId)}/citation_trace.jsonl',
    );
  }

  static String skillRuleTracePath(Directory workspace, String agentId) {
    return _joinNested(
      workspace.path,
      'agent/conversations/${_safeId(agentId)}/skill_rule_trace.jsonl',
    );
  }

  static String dialogueExportPath(Directory workspace) {
    return _joinNested(
      workspace.path,
      'agent/dialogue_export/agent_dialogue_export.md',
    );
  }

  static String dialogueExportManifestPath(Directory workspace) {
    return _joinNested(
      workspace.path,
      'agent/dialogue_export/agent_dialogue_export_manifest.json',
    );
  }

  static String topLevelDialoguePath(Directory workspace) {
    return _joinNested(workspace.path, 'agent/dialogue/agent_dialogue.md');
  }

  static String topLevelDialogueHistoryPath(Directory workspace) {
    return _joinNested(workspace.path, 'agent/dialogue/chat_history.jsonl');
  }

  static String topLevelDialogueManifestPath(Directory workspace) {
    return _joinNested(
      workspace.path,
      'agent/dialogue/agent_dialogue_manifest.json',
    );
  }

  Future<List<Map<String, dynamic>>> readProfileRows(
    Directory workspace,
  ) async {
    final payload = await _readJson(catalogPath(workspace));
    final rows = payload['agents'];
    if (rows is! List) return const <Map<String, dynamic>>[];
    return rows
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<void> writeProfileRows({
    required Directory workspace,
    required List<Map<String, Object?>> rows,
    required String updatedAt,
  }) async {
    await _writeJson(catalogPath(workspace), {
      'schema_version': 'heitang_agent_catalog.v1',
      'status': 'saved',
      'agents': rows,
      'updated_at': updatedAt,
    });
  }

  Future<Map<String, dynamic>> readConversation(
    Directory workspace,
    String agentId,
  ) async {
    return _readJson(conversationPath(workspace, agentId));
  }

  Future<void> writeConversation({
    required Directory workspace,
    required String agentId,
    required Map<String, Object?> payload,
  }) async {
    await _writeJson(conversationPath(workspace, agentId), payload);
  }

  Future<void> deleteConversationDirectory(
    Directory workspace,
    String agentId,
  ) async {
    final dir = Directory(conversationDir(workspace, agentId));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> appendActivityRecord({
    required Directory workspace,
    required Map<String, Object?> record,
  }) async {
    final path = activityLogPath(workspace);
    await File(path).parent.create(recursive: true);
    await File(path).writeAsString(
      '${jsonEncode(record)}\n',
      mode: FileMode.append,
      encoding: utf8,
    );
  }

  Future<String> appendRunHistoryRecord({
    required Directory workspace,
    required String action,
    required String artifact,
    required String status,
    required Map<String, Object?> details,
    required String createdAt,
  }) async {
    final path = runHistoryPath(workspace);
    final current = await _readJson(path);
    final records = _listOfMaps(current['records']).toList(growable: true);
    records.add({
      'run_id':
          'agent_${action}_${(records.length + 1).toString().padLeft(3, '0')}',
      'action': action,
      'artifact': artifact,
      'status': status,
      'created_at': createdAt,
      'details': details,
    });
    final modelRouteEvidenceRecorded = records.any((record) {
      final recordDetails = _mapValue(record['details']);
      return recordDetails.containsKey('model_route_evidence') ||
          recordDetails.containsKey('model_route_binding');
    });
    await _writeJson(path, {
      ...current,
      'schema_version': _stringValue(
          current['schema_version'], 'prd_v2_agent_run_history.v1'),
      'status': 'pass',
      'model_route_evidence_recorded': modelRouteEvidenceRecorded,
      'records': records,
    });
    return path;
  }

  Future<String> appendCitationTraceRow({
    required Directory workspace,
    required String agentId,
    required Map<String, Object?> record,
  }) async {
    final path = citationTracePath(workspace, agentId);
    await _appendJsonl(path, record);
    return path;
  }

  Future<String> ensureCitationTraceFile({
    required Directory workspace,
    required String agentId,
  }) async {
    final path = citationTracePath(workspace, agentId);
    await _ensureFile(path);
    return path;
  }

  Future<String> appendSkillRuleTraceRow({
    required Directory workspace,
    required String agentId,
    required Map<String, Object?> record,
  }) async {
    final path = skillRuleTracePath(workspace, agentId);
    await _appendJsonl(path, record);
    return path;
  }

  Future<String> ensureSkillRuleTraceFile({
    required Directory workspace,
    required String agentId,
  }) async {
    final path = skillRuleTracePath(workspace, agentId);
    await _ensureFile(path);
    return path;
  }

  Future<AgentDialogueExportResult> exportDialogue({
    required Directory workspace,
    required String dialoguePath,
    required String historyPath,
    required Map<String, Object?> manifestPayload,
    required List<String> Function(int turnCount) exportIntroBuilder,
  }) async {
    final historyFile = File(historyPath);
    final dialogueFile = File(dialoguePath);
    final historyLines = await historyFile.readAsLines(encoding: utf8);
    final dialogueText = await dialogueFile.readAsString(encoding: utf8);
    final outputPath = dialogueExportPath(workspace);
    final manifestPath = dialogueExportManifestPath(workspace);
    await File(outputPath).parent.create(recursive: true);
    await File(outputPath).writeAsString(
      [
        ...exportIntroBuilder(historyLines.length),
        '',
        dialogueText,
      ].join('\n'),
      encoding: utf8,
    );
    await _writeJson(manifestPath, {
      ...manifestPayload,
      'workspace': workspace.path,
      'source_dialogue': dialoguePath,
      'source_history': historyPath,
      'output': outputPath,
      'turn_count': historyLines.length,
    });
    return AgentDialogueExportResult(
      outputPath: outputPath,
      manifestPath: manifestPath,
      turnCount: historyLines.length,
    );
  }

  Future<List<Map<String, dynamic>>> readTopLevelDialogueTurns(
    Directory workspace,
  ) async {
    return _readJsonl(topLevelDialogueHistoryPath(workspace));
  }

  Future<AgentDialogueHistoryAppendResult> appendTopLevelDialogueTurn({
    required Directory workspace,
    required Map<String, Object?> turn,
  }) async {
    final path = topLevelDialogueHistoryPath(workspace);
    final previousTurns = await _readJsonl(path);
    await _appendJsonl(path, turn);
    return AgentDialogueHistoryAppendResult(
      historyPath: path,
      turns: [...previousTurns, turn],
    );
  }

  static Future<Map<String, dynamic>> _readJson(String path) async {
    final file = File(path);
    if (!await file.exists()) return const <String, dynamic>{};
    final text = await file.readAsString(encoding: utf8);
    if (text.trim().isEmpty) return const <String, dynamic>{};
    final decoded = jsonDecode(text);
    return decoded is Map
        ? decoded.cast<String, dynamic>()
        : const <String, dynamic>{};
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

  static Future<void> _appendJsonl(
    String path,
    Map<String, Object?> record,
  ) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      '${jsonEncode(record)}\n',
      mode: FileMode.append,
      encoding: utf8,
    );
  }

  static Future<List<Map<String, dynamic>>> _readJsonl(String path) async {
    final file = File(path);
    if (!await file.exists()) return const <Map<String, dynamic>>[];
    final rows = <Map<String, dynamic>>[];
    final lines = await file.readAsLines(encoding: utf8);
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        rows.add(decoded.cast<String, dynamic>());
      }
    }
    return rows;
  }

  static Future<void> _ensureFile(String path) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    if (!await file.exists()) {
      await file.writeAsString('', encoding: utf8);
    }
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

  static String _stringValue(Object? value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static Map<String, dynamic> _mapValue(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _listOfMaps(Object? raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
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

class AgentDialogueExportResult {
  const AgentDialogueExportResult({
    required this.outputPath,
    required this.manifestPath,
    required this.turnCount,
  });

  final String outputPath;
  final String manifestPath;
  final int turnCount;
}

class AgentDialogueHistoryAppendResult {
  const AgentDialogueHistoryAppendResult({
    required this.historyPath,
    required this.turns,
  });

  final String historyPath;
  final List<Map<String, Object?>> turns;

  int get turnCount => turns.length;
}
