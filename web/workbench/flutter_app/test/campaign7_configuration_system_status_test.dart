import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const schemaPath =
      'assets/contracts/campaign7_configuration_system_status_2026_06_17.json';

  Map<String, dynamic> loadSchema() {
    return jsonDecode(File(schemaPath).readAsStringSync())
        as Map<String, dynamic>;
  }

  test('campaign 7 configuration contract covers required config lifecycle',
      () {
    final schema = loadSchema();
    final config = schema['config_schema'] as Map<String, dynamic>;
    final capabilities =
        (schema['status_matrix'] as List<dynamic>).cast<Map<String, dynamic>>();
    final capabilityIds = {
      for (final capability in capabilities) capability['capability']
    };

    expect(schema['schema_id'], 'campaign7_configuration_system_status');
    expect(schema['overall_status'],
        'campaign7_configuration_system_production_grade_accepted_ui_bound');
    expect(config['schema_version'], 'campaign7.config.v1');
    expect(config['source_precedence'],
        <String>['default', 'workspace', 'user', 'env']);
    expect(
        config['sections'],
        containsAll(<String>[
          'provider_profiles',
          'agent_profiles',
          'tool_adapters',
          'skills',
          'rag',
          'workspace',
          'ui_settings',
        ]));
    expect(
        capabilityIds,
        containsAll(<String>{
          'unified_config_schema',
          'provider_profile_persistence',
          'agent_profile_persistence',
          'tool_adapter_config_persistence',
          'skill_rag_workspace_binding_config',
          'override_precedence',
          'env_only_secret_injection',
          'masked_ui_secret_display',
          'config_validation',
          'config_migration',
          'config_rollback',
          'config_diagnostics',
          'config_import_export',
          'degraded_status_mapping',
          'ui_settings_binding',
        }));
    for (final capability in capabilities) {
      expect(capability['status'], 'pass');
      expect(capability['ui_state'], 'enabled_real');
    }
  });

  test('campaign 7 contract keeps hard security and scope boundaries', () {
    final schema = loadSchema();
    final scope = schema['scope'] as Map<String, dynamic>;
    final security = schema['security_boundaries'] as Map<String, dynamic>;
    final config = schema['config_schema'] as Map<String, dynamic>;
    final runtimeReuse = config['runtime_reuse'] as Map<String, dynamic>;

    expect(scope['campaign_7_started'], isTrue);
    expect(scope['campaign_8_started'], isFalse);
    expect(scope['campaign_9_started'], isFalse);
    expect(scope['provider_runtime_reimplemented'], isFalse);
    expect(scope['agent_runtime_reimplemented'], isFalse);
    expect(scope['arbitrary_shell_allowed'], isFalse);
    expect(scope['computer_use_runtime_enabled'], isFalse);
    expect(scope['tag_or_release_allowed'], isFalse);
    expect(scope['secret_plaintext_written'], isFalse);
    expect(security.values, everyElement(isTrue));
    expect(
        runtimeReuse['provider_runtime'], 'accepted_env_only_provider_runtime');
    expect(runtimeReuse['agent_runtime'], 'campaign6_agent_runtime');
  });

  test('campaign 7 settings binding exposes diagnostics and degraded modes',
      () async {
    final schema = jsonDecode(await rootBundle.loadString(schemaPath))
        as Map<String, dynamic>;
    final uiSettings = schema['ui_settings'] as Map<String, dynamic>;
    final diagnostics = schema['diagnostics'] as Map<String, dynamic>;
    final degraded = (schema['degraded_modes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    expect(uiSettings['ui_state'], 'enabled_real');
    expect(uiSettings['masked_secret_display'], contains('*'));
    expect(uiSettings['masked_secret_display'], isNot(contains('secret')));
    expect(diagnostics['status'], 'pass');
    expect(diagnostics['provider_runtime'], 'available');
    expect(diagnostics['agent_runtime'], 'available');
    expect(degraded.map((item) => item['condition']),
        containsAll(<String>['missing_env_secret', 'rollback_restore']));
  });
}
