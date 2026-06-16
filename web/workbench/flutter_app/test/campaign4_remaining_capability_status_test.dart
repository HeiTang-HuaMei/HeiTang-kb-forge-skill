import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const schemaPath =
      'assets/contracts/campaign4_remaining_capability_status_2026_06_16.json';

  Map<String, dynamic> loadSchema() {
    return jsonDecode(File(schemaPath).readAsStringSync())
        as Map<String, dynamic>;
  }

  test('remaining campaign 4 capability fixture covers scoped capabilities',
      () {
    final schema = loadSchema();
    final scope = schema['scope'] as Map<String, dynamic>;
    final capabilities =
        (schema['capabilities'] as List<dynamic>).cast<Map<String, dynamic>>();
    final byId = {
      for (final capability in capabilities)
        capability['capability_id'] as String: capability
    };

    expect(schema['gate'],
        'campaign4_degraded_capabilities_finalization_long_run');
    expect(schema['overall_status'],
        'campaign4_remaining_capabilities_production_grade_accepted_ui_bound');
    expect(scope['campaign_4_remaining_yellow_gaps_only'], isTrue);
    expect(scope['campaign_5_started'], isFalse);
    expect(scope['campaign_6_started'], isFalse);
    expect(scope['campaign_9_started'], isFalse);
    expect(scope['agent_runtime_started'], isFalse);
    expect(scope['memory_runtime_started'], isFalse);
    expect(scope['a2a_started'], isFalse);

    expect(
        byId.keys,
        containsAll(<String>[
          'external_source_verification',
          'ocr_parser_chunking',
          'knowledge_quality_gate',
          'document_export',
          'skill_governance',
          'agent_creation_package',
        ]));
  });

  test('remaining capability statuses are accepted after degraded finalization',
      () {
    final schema = loadSchema();
    final capabilities =
        (schema['capabilities'] as List<dynamic>).cast<Map<String, dynamic>>();
    final byId = {
      for (final capability in capabilities)
        capability['capability_id'] as String: capability
    };

    expect(byId['external_source_verification']!['ui_state'], 'enabled_real');
    expect(byId['external_source_verification']!['yellow_marker_removed'],
        isTrue);
    expect(byId['external_source_verification']!['accepted_surface'],
        contains('Live public source fetch'));
    expect(byId['ocr_parser_chunking']!['ui_state'], 'enabled_real');
    expect(byId['ocr_parser_chunking']!['yellow_marker_removed'], isTrue);
    expect(byId['ocr_parser_chunking']!['accepted_surface'],
        contains('real PaddleOCR image OCR runtime invocation'));

    for (final id in [
      'external_source_verification',
      'ocr_parser_chunking',
      'knowledge_quality_gate',
      'document_export',
      'skill_governance',
      'agent_creation_package',
    ]) {
      expect(byId[id]!['ui_state'], 'enabled_real', reason: id);
      expect(byId[id]!['yellow_marker_removed'], isTrue, reason: id);
      expect(byId[id]!['evidence_path'], isNotEmpty, reason: id);
      expect(byId[id]!['rollback_disable_switch'], isNotEmpty, reason: id);
    }
  });

  test('remaining capability fixture is bundled for UI consumption', () async {
    final schema = jsonDecode(await rootBundle.loadString(schemaPath))
        as Map<String, dynamic>;

    expect(schema['schema_id'], 'campaign4_remaining_capability_status');
    expect(schema['capabilities'], isA<List<dynamic>>());
  });

  test('remaining capability fixture does not claim future runtimes', () {
    final raw = File(schemaPath).readAsStringSync().toLowerCase();

    for (final claim in [
      'agent runtime complete',
      'memory runtime complete',
      'a2a complete',
      'campaign 6 started',
      'exe packaging accepted',
      'stable release',
    ]) {
      expect(raw, isNot(contains(claim)));
    }
  });
}
