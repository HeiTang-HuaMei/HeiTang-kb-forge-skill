import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/contracts/workbench_contracts.dart';
import 'package:heitang_workbench/core_actions/workbench_actions.dart';
import 'package:heitang_workbench/core_bridge/local_core_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const schemaPath =
      'assets/contracts/provider_runtime_bridge_status_schema_delta_2026_06_16.json';

  Map<String, dynamic> loadSchema() {
    return jsonDecode(File(schemaPath).readAsStringSync())
        as Map<String, dynamic>;
  }

  test('provider bridge status schema enables only provider runtime binding',
      () {
    final schema = loadSchema();
    final scope = schema['scope'] as Map<String, dynamic>;
    final acceptedStatusSchema =
        schema['accepted_status_schema'] as Map<String, dynamic>;
    final markerPolicy = schema['ui_marker_policy'] as Map<String, dynamic>;
    final bridgeContract =
        schema['bridge_consumption_contract'] as Map<String, dynamic>;

    expect(schema['gate'],
        'provider_runtime_production_grade_completion_and_ui_binding_gate');
    expect(schema['delta_result'],
        'provider_runtime_production_grade_accepted_ui_bound');
    expect(schema['final_live_smoke_result'],
        'provider_runtime_final_live_smoke_reacceptance_passed_pending_ui_binding');
    expect(schema['production_grade_result'],
        'provider_runtime_production_grade_accepted_ui_bound');
    expect(scope['runtime_rewrite'], isFalse);
    expect(scope['new_provider_connected'], isFalse);
    expect(scope['new_dependency_added'], isFalse);
    expect(scope['yellow_marker_removed'], isTrue);
    expect(scope['provider_runtime_marker_only'], isTrue);
    expect(acceptedStatusSchema['ui_state_values'],
        contains('enabled_real_degraded'));
    expect(markerPolicy['provider_yellow_marker_removal_allowed'], isTrue);
    expect(markerPolicy['post_delta_ui_state'], 'enabled_real');
    expect(markerPolicy['non_provider_yellow_markers_unchanged'], isTrue);
    expect(bridgeContract['network_calls_require_explicit_opt_in'], isTrue);
    expect(bridgeContract['live_smoke_is_not_agent_runtime'], isTrue);
    expect(bridgeContract['raw_secret_display_allowed'], isFalse);
    expect(bridgeContract['secret_ui_remains_masked_display_only'], isTrue);
    expect(bridgeContract['rollback_disable_switch'], isNotEmpty);
    expect(bridgeContract['ui_enabled_real_requires_final_provider_acceptance'],
        isTrue);
  });

  test('provider bridge status schema is bundled for UI consumption', () async {
    final schema = jsonDecode(await rootBundle.loadString(schemaPath))
        as Map<String, dynamic>;

    expect(schema['gate'],
        'provider_runtime_production_grade_completion_and_ui_binding_gate');
    expect(schema['bridge_consumption_contract'], isA<Map<String, dynamic>>());
  });

  test('production availability and user-facing statuses are present', () {
    final schema = loadSchema();
    final availability =
        schema['production_runtime_availability'] as Map<String, dynamic>;
    final statuses = (schema['user_facing_status_matrix'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final byStatus = {
      for (final item in statuses) item['status'] as String: item
    };

    expect(availability['provider'], 'official_openai');
    expect(availability['models_probe']['status'], 'pass');
    expect(availability['chat_completions_probe']['status'], 'pass');
    expect(availability['responses_probe']['status'], 'pass');
    expect(availability['response_text_committed'], isFalse);
    expect(availability['api_key_source'], 'secure_env_only');
    expect(availability['raw_secret_display_allowed'], isFalse);

    expect(
        byStatus.keys,
        containsAll(<String>[
          'connected',
          'unavailable',
          'missing_key',
          'timeout',
          'fallback_used',
          'cost_blocked',
        ]));
    expect(byStatus['connected']!['ui_state'], 'enabled_real');
    expect(byStatus['unavailable']!['local_degraded_mode'], isTrue);
    expect(byStatus['missing_key']!['bridge_status'], 'blocked');
    expect(byStatus['timeout']!['log_required'], isTrue);
    expect(byStatus['fallback_used']!['ui_state'], 'display_only');
    expect(byStatus['cost_blocked']!['bridge_status'], 'warning_boundary');
  });

  test('provider runtime behavior matrix covers all acceptance items', () {
    final schema = loadSchema();
    final matrix = schema['runtime_behavior_matrix'] as List<dynamic>;
    final byId = {
      for (final item in matrix)
        (item as Map<String, dynamic>)['behavior_id'] as String: item
    };

    expect(
        byId.keys,
        containsAll(<String>[
          'provider_config_schema_validation',
          'provider_registry_profile_readiness',
          'secret_redaction_leak_prevention',
          'missing_key_behavior',
          'invalid_key_behavior',
          'timeout_behavior',
          'provider_unavailable_behavior',
          'fallback_behavior',
          'cancellation_behavior',
          'cost_token_guard_behavior',
          'live_smoke_opt_in_boundary',
          'provider_runtime_final_live_smoke_reacceptance',
          'production_runtime_availability',
          'degraded_mode_and_fallback',
          'ui_bridge_status_contract',
          'overclaim_scan',
        ]));

    expect(byId['provider_config_schema_validation']!['bridge_status'],
        'accepted');
    expect(
        byId['secret_redaction_leak_prevention']!['bridge_status'], 'accepted');
    expect(byId['missing_key_behavior']!['bridge_status'], 'blocked');
    expect(byId['missing_key_behavior']!['ui_state'], 'disabled_boundary');
    expect(byId['timeout_behavior']!['bridge_status'], 'partial');
    expect(byId['invalid_key_behavior']!['bridge_status'], 'partial');
    expect(byId['cost_token_guard_behavior']!['bridge_status'],
        'warning_boundary');
    expect(byId['cancellation_behavior']!['bridge_status'], 'accepted');
    expect(byId['cancellation_behavior']!['ui_state'], 'display_only');
    expect(byId['live_smoke_opt_in_boundary']!['bridge_status'], 'accepted');
    expect(byId['live_smoke_opt_in_boundary']!['ui_state'], 'enabled_real');
    expect(byId['provider_runtime_final_live_smoke_reacceptance']!['ui_state'],
        'enabled_real');
    expect(
        byId['production_runtime_availability']!['bridge_status'], 'accepted');
    expect(byId['degraded_mode_and_fallback']!['ui_state'], 'display_only');
    expect(byId['ui_bridge_status_contract']!['ui_state'], 'enabled_real');

    for (final item in matrix.cast<Map<String, dynamic>>()) {
      expect(item['evidence_path'], isNotEmpty, reason: item['behavior_id']);
      expect(item['removal_rule'], isNotEmpty, reason: item['behavior_id']);
      expect(<String>[
        'accepted',
        'warning_boundary',
        'blocked',
        'partial',
        'failed'
      ], contains(item['bridge_status']), reason: item['behavior_id']);
    }
  });

  test('existing UI contract keeps provider actions out of executable bridge',
      () {
    final contracts = sampleWorkbenchContracts;
    final providerActions = contracts.actions.actions
        .where((action) => action.id.contains('provider'))
        .toList();

    expect(providerActions, isNotEmpty);
    for (final action in providerActions) {
      expect(action.desktopEnabled, isFalse, reason: action.id);
      expect(action.blockedReason, isNotEmpty, reason: action.id);
      final request = coreRequestForAction(
        action: action,
        coreCli: 'heitang-kb-forge',
        workingDirectory: r'C:\repo',
        workspace: r'C:\workspace',
      );
      expect(request, isNull, reason: action.id);
    }
  });

  test('bridge rejects provider secrets in UI request environments', () {
    const bridge = LocalCoreBridge();
    final result = bridge.run(
      const CoreBridgeRequest(
        actionId: 'workspace_inspect',
        coreCli: 'heitang-kb-forge',
        workingDirectory: r'C:\repo',
        arguments: <String>['workspace-list'],
        environment: <String, String>{
          'OPENAI_API_KEY': 'sk-test-secret-value',
        },
      ),
    );

    expect(
      result,
      completion(
        isA<CoreBridgeResult>()
            .having((value) => value.status, 'status', 'blocked')
            .having((value) => value.errorId, 'errorId',
                'core_bridge_secret_env_rejected')
            .having(
                (value) => value.stderr,
                'stderr',
                contains(
                    'Provider secrets must stay outside UI bridge requests')),
      ),
    );
  });

  test('schema delta does not claim completed runtime families', () {
    final raw = File(schemaPath).readAsStringSync().toLowerCase();

    final forbiddenClaims = <String>[
      'provider runtime ' 'complete',
      'agent runtime ' 'complete',
      'memory runtime ' 'complete',
      'a2a ' 'complete',
      'collaboration runtime ' 'complete',
    ];
    for (final claim in forbiddenClaims) {
      expect(raw, isNot(contains(claim)));
    }
  });
}
