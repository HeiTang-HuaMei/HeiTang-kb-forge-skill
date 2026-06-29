import 'dart:convert';
import 'dart:io';

class EventLedgerRepository {
  const EventLedgerRepository();

  static String eventLedgerPath(Directory workspace) {
    return _joinNested(workspace.path, 'audit/event_ledger.jsonl');
  }

  Future<void> appendRecord(
    Directory workspace,
    Map<String, Object?> record,
  ) async {
    final path = eventLedgerPath(workspace);
    await File(path).parent.create(recursive: true);
    await File(path).writeAsString(
      '${jsonEncode(record)}\n',
      mode: FileMode.append,
      encoding: utf8,
    );
  }

  void appendRecordSync(
    Directory workspace,
    Map<String, Object?> record,
  ) {
    final path = eventLedgerPath(workspace);
    File(path).parent.createSync(recursive: true);
    File(path).writeAsStringSync(
      '${jsonEncode(record)}\n',
      mode: FileMode.append,
      encoding: utf8,
    );
  }

  Future<List<Map<String, dynamic>>> readRows(Directory workspace) async {
    final file = File(eventLedgerPath(workspace));
    if (!await file.exists()) return const <Map<String, dynamic>>[];
    final rows = <Map<String, dynamic>>[];
    for (final line in await file.readAsLines(encoding: utf8)) {
      if (line.trim().isEmpty) continue;
      final decoded = jsonDecode(line);
      if (decoded is Map) rows.add(decoded.cast<String, dynamic>());
    }
    return rows;
  }

  static List<Map<String, dynamic>> readRowsSync(Directory workspace) {
    final file = File(eventLedgerPath(workspace));
    if (!file.existsSync()) return const <Map<String, dynamic>>[];
    final rows = <Map<String, dynamic>>[];
    for (final line in file.readAsLinesSync(encoding: utf8)) {
      if (line.trim().isEmpty) continue;
      final decoded = jsonDecode(line);
      if (decoded is Map) rows.add(decoded.cast<String, dynamic>());
    }
    return rows;
  }

  Future<void> clear(Directory workspace) async {
    final path = eventLedgerPath(workspace);
    final file = File(path);
    if (await file.exists()) {
      await file.writeAsString('', encoding: utf8);
    }
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
