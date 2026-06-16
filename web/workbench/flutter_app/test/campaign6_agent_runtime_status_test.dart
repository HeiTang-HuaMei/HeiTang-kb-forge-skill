import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const schemaPath =
      'assets/contracts/campaign6_agent_runtime_status_2026_06_17.json';

  Map<String, dynamic> loadSchema() {
    return jsonDecode(File(schemaPath).readAsStringSync())
        as Map<String, dynamic>;
  }

  test('campaign 6 runtime UI contract covers 6A, 6B, and tool adapter gate',
      () {
    final schema = loadSchema();
    final scope = schema['scope'] as Map<String, dynamic>;
    final phases =
        (schema['phase_status'] as List<dynamic>).cast<Map<String, dynamic>>();
    final phaseIds = {for (final phase in phases) phase['phase_id']};

    expect(schema['schema_id'], 'campaign6_agent_runtime_status');
    expect(schema['overall_status'],
        'campaign6a_6b_tool_adapter_production_grade_accepted_ui_bound');
    expect(scope['campaign_6a_started'], isTrue);
    expect(scope['campaign_6b_started'], isTrue);
    expect(scope['tool_adapter_configuration_gate_started'], isTrue);
    expect(scope['campaign_7_started'], isFalse);
    expect(scope['campaign_8_started'], isFalse);
    expect(scope['campaign_9_started'], isFalse);
    expect(scope['computer_use_runtime_enabled'], isFalse);
    expect(
        phaseIds,
        containsAll(<String>{
          'campaign6a_single_agent_runtime',
          'campaign6b_advanced_agent_runtime',
          'campaign6_tool_adapter_configuration_gate',
          'computer_use_boundary',
        }));
  });

  test('campaign 6A UI contract exposes all production agent types', () {
    final schema = loadSchema();
    final agents = (schema['agent_types_6a'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final byId = {for (final agent in agents) agent['agent_type']: agent};

    expect(
        byId.keys,
        containsAll(<String>{
          'knowledge_qa_agent',
          'document_processing_agent',
          'skill_builder_agent',
          'workbench_operator_agent',
          'external_verification_agent',
        }));
    for (final agent in agents) {
      expect(agent['ui_state'], 'enabled_real',
          reason: '${agent['agent_type']}');
      expect(agent['real_runtime_paths'], isNotEmpty,
          reason: '${agent['agent_type']}');
      expect(agent['degraded_modes'], isNotEmpty,
          reason: '${agent['agent_type']}');
      expect(agent['ui_status_fields'], isNotEmpty,
          reason: '${agent['agent_type']}');
    }
    expect(byId['document_processing_agent']!['runtime_status'],
        'partial_success');
  });

  test('campaign 6B and tool adapter contract keep security boundaries', () {
    final schema = loadSchema();
    final capabilities = (schema['advanced_capabilities_6b'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final byId = {
      for (final capability in capabilities)
        capability['capability_id']: capability
    };
    final adapter = schema['tool_adapter_gate'] as Map<String, dynamic>;
    final security = schema['security_boundaries'] as Map<String, dynamic>;

    expect(
        byId.keys,
        containsAll(<String>{
          'long_term_memory',
          'multi_agent_workflow',
          'a2a',
          'agent_teams',
          'multi_agent_security',
          'computer_use_boundary',
        }));
    expect(byId['computer_use_boundary']!['ui_state'], 'disabled_boundary');
    expect(adapter['provider_runtime_reimplemented'], isFalse);
    expect(adapter['unregistered_third_party_api_integrated'], isFalse);
    expect(adapter['official_channel_tool_adapter_gate_required'], isTrue);
    expect(adapter['secret_plaintext_written'], isFalse);
    expect(
        adapter['api_config_schema_fields'],
        containsAll(<String>[
          'base_url_env',
          'token_env',
          'auth_type',
          'timeout',
          'retry',
          'rate_limit',
          'permission_policy',
          'redaction',
        ]));
    expect(security.values, everyElement(isTrue));
  });

  test('campaign 6 runtime contract is bundled for UI consumption', () async {
    final schema = jsonDecode(await rootBundle.loadString(schemaPath))
        as Map<String, dynamic>;

    expect(schema['schema_id'], 'campaign6_agent_runtime_status');
    expect(schema['agent_types_6a'], isA<List<dynamic>>());
    expect(schema['advanced_capabilities_6b'], isA<List<dynamic>>());
  });
}
