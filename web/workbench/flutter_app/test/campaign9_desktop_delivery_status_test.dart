import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/contracts/sample_contracts.dart';
import 'package:heitang_workbench/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const schemaPath =
      'assets/contracts/campaign9_desktop_delivery_status_2026_06_17.json';

  Map<String, dynamic> loadSchema() {
    return jsonDecode(File(schemaPath).readAsStringSync())
        as Map<String, dynamic>;
  }

  test('campaign 9 desktop delivery contract records real local package smoke',
      () {
    final schema = loadSchema();
    final packageInfo = schema['package'] as Map<String, dynamic>;
    final checksum = schema['checksum'] as Map<String, dynamic>;
    final smoke = schema['desktop_shell_smoke'] as Map<String, dynamic>;
    final steps =
        (smoke['steps'] as List<dynamic>).cast<Map<String, dynamic>>();
    final stepIds = {for (final step in steps) step['step']};

    expect(schema['schema_id'], 'campaign9_desktop_delivery_status');
    expect(schema['overall_status'],
        'campaign9_windows_exe_packaging_local_smoke_passed_ui_bound');
    expect(schema['final_target_status'],
        'campaign9_windows_exe_packaging_accepted_pushed_ci_green_tagged_rc2_pending_release_decision');
    expect(schema['release_candidate_tag'], 'v4.3.0-rc2');
    expect(schema['package_version_baseline'], '4.2.0');
    expect(packageInfo['build_status'], 'pass');
    expect(packageInfo['exe'], 'heitang_workbench.exe');
    expect(packageInfo['file_count'], greaterThan(0));
    expect(packageInfo['total_size_bytes'], greaterThan(0));
    expect((packageInfo['required_files_present'] as Map).values,
        everyElement(isTrue));
    expect(checksum['status'], 'pass');
    expect((checksum['exe_sha256'] as String), hasLength(64));
    expect(smoke['status'], 'pass');
    expect(
        stepIds,
        containsAll(<String>{
          'launch',
          'minimize',
          'restore_after_minimize',
          'maximize',
          'restore_after_maximize',
          'resize',
          'close',
        }));
    for (final step in steps) {
      expect(step['result'], 'pass', reason: '${step['step']}');
    }
  });

  test('campaign 9 contract preserves release and security boundaries', () {
    final schema = loadSchema();
    final scope = schema['campaign_scope'] as Map<String, dynamic>;
    final security = schema['security_boundaries'] as Map<String, dynamic>;
    final delivery = schema['delivery_path'] as Map<String, dynamic>;
    final validation = (schema['validation_matrix'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final byCapability = {
      for (final item in validation) item['capability'] as String: item
    };

    expect(scope['campaign_7_restarted'], isFalse);
    expect(scope['campaign_8_restarted'], isFalse);
    expect(scope['campaign_9_started'], isTrue);
    expect(scope['computer_use_runtime_enabled'], isFalse);
    expect(scope['arbitrary_shell_allowed'], isFalse);
    expect(scope['github_release_created'], isFalse);
    expect(scope['tauri_accepted_path'], isFalse);
    expect(delivery['accepted_packaging_path'], 'flutter_windows_runner');
    expect(delivery['legacy_tauri_status'],
        'legacy_optional_scaffold_not_campaign9_accepted_path');
    expect(schema['github_release_created'], isFalse);
    expect(schema['stable_release_tag_authorized'], isFalse);
    expect(security.values, everyElement(isTrue));
    expect(byCapability['github_release_creation']!['ui_state'],
        'disabled_boundary');
    expect(
        byCapability['computer_use_runtime']!['status'], 'disabled_boundary');
  });

  test('campaign 9 desktop delivery contract is bundled for UI consumption',
      () async {
    final schema = jsonDecode(await rootBundle.loadString(schemaPath))
        as Map<String, dynamic>;

    expect(schema['schema_id'], 'campaign9_desktop_delivery_status');
    expect(schema['validation_matrix'], isA<List<dynamic>>());
    expect(schema['degraded_modes'], isA<List<dynamic>>());
  });

  testWidgets('settings exposes Campaign 9 desktop delivery status',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1100));
    await tester.pumpWidget(HeiTangWorkbenchApp(
      contracts: sampleWorkbenchContracts,
      campaign9DesktopDeliveryStatus: sampleCampaign9DesktopDeliveryStatus,
      isWebRuntime: false,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('设置').first);
    await tester.pumpAndSettle();
    final desktopTab = find.text('桌面交付').evaluate().isNotEmpty
        ? find.text('桌面交付').first
        : find.text('Desktop Delivery').first;
    await tester.ensureVisible(desktopTab);
    await tester.tap(desktopTab, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-desktop-delivery')), findsOneWidget);
    expect(find.text('v4.3.0-rc2'), findsWidgets);
    expect(find.text('heitang_workbench.exe'), findsWidgets);
    expect(find.textContaining('GitHub Release'), findsWidgets);
    expect(find.textContaining('v4.3.0'), findsWidgets);
    expect(find.textContaining('v4.3.0 stable'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
