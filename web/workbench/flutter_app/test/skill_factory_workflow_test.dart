import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/core_actions/page_action_mapping.dart';
import 'package:heitang_workbench/core_actions/workbench_actions.dart';
import 'package:heitang_workbench/core_bridge/local_core_bridge.dart';
import 'package:heitang_workbench/contracts/workbench_contracts.dart';
import 'package:heitang_workbench/main.dart';
import 'package:heitang_workbench/skill_factory/skill_factory_workflow.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('workflow fixture covers the P2.2 industrial UI chain', () async {
    final workflow = jsonDecode(await rootBundle
            .loadString('assets/fixtures/p2_2/skill_suite_workflow.json'))
        as Map<String, dynamic>;
    final metadata = workflow['metadata'] as Map<String, dynamic>;
    final reports = workflow['reports'] as Map<String, dynamic>;
    final export = workflow['export'] as Map<String, dynamic>;
    final boundary = export['runtime_boundary'] as Map<String, dynamic>;

    expect(metadata['release_version'], 'v4.2.0');
    expect(metadata['release_state'], 'release_candidate');
    expect(metadata['fixture_kind'], 'contract_evidence_snapshot');
    expect(metadata['runtime_execution_claimed'], isFalse);
    expect(workflow['evidence_windows'], isNotEmpty);
    expect((workflow['methodology'] as Map)['modules'], isNotEmpty);
    expect(workflow['candidates'], hasLength(3));
    expect((workflow['hierarchy'] as Map)['levels'], isNotEmpty);
    expect((workflow['suite'] as Map)['status'], 'ready');
    expect(reports.keys,
        containsAll(['validation', 'diff', 'installability', 'governance']));
    expect((reports['governance'] as Map)['release_ready'], isTrue);
    expect(export['status'], 'ready');
    expect(export['local_first'], isTrue);
    expect(boundary['provider_required'], isFalse);
    expect(boundary['external_runtime_required'], isFalse);
    expect(workflow['tests_require_real_llm_api_network'], isFalse);
  });

  test('skill factory maps and allowlists the P2.2 local CLI contract', () {
    final actions =
        coreActionsForPage('skill-factory', sampleWorkbenchContracts);
    const expectedIds = <String>[
      'extract_methodology',
      'plan_skill_suite',
      'build_skill_suite',
      'validate_skill_suite',
      'diff_skill_suite',
      'check_skill_suite_installability',
      'skill_suite_governance_report',
      'export_skill_pack',
    ];

    expect(actions.map((action) => action.id), containsAll(expectedIds));
    expect(
        actions
            .where((action) => action.id == 'plan_skill_suite')
            .single
            .command,
        contains('--methodology <methodology>'));
    expect(
        actions
            .where((action) => action.id == 'diff_skill_suite')
            .single
            .command,
        contains('--before <before> --after <after>'));

    const bridge = LocalCoreBridge();
    for (final action
        in actions.where((item) => expectedIds.contains(item.id))) {
      final request = coreRequestForAction(
        action: action,
        coreCli: 'python',
        workingDirectory: r'C:\repo',
        workspace: r'C:\workspace',
      );
      expect(request, isNotNull, reason: action.id);
      expect(bridge.buildCommand(request!).first, 'python');
    }
  });

  testWidgets('renders every Skill Factory workflow surface', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    await tester.pumpWidget(HeiTangWorkbenchApp(
      contracts: sampleWorkbenchContracts,
      skillSuiteWorkflow: sampleSkillSuiteWorkflow,
      initialSelectedIndex:
          pages.indexWhere((page) => page.id == 'skill-factory'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Knowledge-to-Skill Suite 工作流'), findsNothing);
    await _openDeveloperDiagnostics(tester);
    expect(find.text('Knowledge-to-Skill Suite 工作流'), findsOneWidget);
    expect(find.textContaining('release_candidate'), findsWidgets);
    expect(find.textContaining('Core 证据快照'), findsOneWidget);
    expect(find.text('知识包'), findsWidgets);
    expect(find.text('证据'), findsWidgets);
    expect(find.text('方法论'), findsWidgets);
    expect(find.text('候选'), findsWidgets);
    expect(find.text('层级'), findsWidgets);
    expect(find.text('Skill Suite'), findsWidgets);
    expect(find.text('报告'), findsWidgets);
    expect(find.text('导出'), findsWidgets);

    await _openTab(tester, 'evidence');
    expect(find.text('Evidence-led operations'), findsOneWidget);
    expect(
        find.textContaining('operations.md#review-boundary'), findsOneWidget);
    expect(find.textContaining('confidence=0.94'), findsOneWidget);

    await _openTab(tester, 'methodology');
    expect(find.text('Evidence-led Operations'), findsOneWidget);
    expect(find.textContaining('Inspect, classify, validate'), findsOneWidget);

    await _openTab(tester, 'candidates');
    expect(find.textContaining('planning · accepted'), findsOneWidget);
    expect(find.textContaining('functional · accepted'), findsOneWidget);
    expect(find.textContaining('atomic · accepted'), findsOneWidget);

    await _openTab(tester, 'hierarchy');
    expect(find.text('planning'), findsOneWidget);
    expect(find.text('functional'), findsOneWidget);
    expect(find.text('atomic'), findsOneWidget);

    await _openTab(tester, 'suite');
    expect(find.text('Routing Rules'), findsOneWidget);
    expect(find.text('Dependency Graph'), findsOneWidget);

    await _openTab(tester, 'reports');
    expect(find.text('validation'), findsOneWidget);
    expect(find.text('diff'), findsOneWidget);
    expect(find.text('installability'), findsOneWidget);
    expect(find.text('governance'), findsOneWidget);

    await _openTab(tester, 'export');
    expect(find.text('Skill Pack Export'), findsOneWidget);
    expect(find.text('local_first'), findsOneWidget);
    expect(find.text('external_runtime_required'), findsOneWidget);
    expect(find.textContaining('Execute local runtime'), findsNothing);
    expect(find.textContaining('运行本地 runtime'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the Skill Factory workflow on mobile', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(HeiTangWorkbenchApp(
      contracts: sampleWorkbenchContracts,
      skillSuiteWorkflow: sampleSkillSuiteWorkflow,
      initialSelectedIndex:
          pages.indexWhere((page) => page.id == 'skill-factory'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Knowledge-to-Skill Suite 工作流'), findsNothing);
    await _openDeveloperDiagnostics(tester);
    expect(find.text('Knowledge-to-Skill Suite 工作流'), findsOneWidget);
    expect(find.textContaining('Web 仅展示可审计产物'), findsOneWidget);
    expect(find.byKey(const ValueKey('workflow-tab-overview')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openDeveloperDiagnostics(WidgetTester tester) async {
  if (find.byType(DropdownButtonFormField<int>).evaluate().isNotEmpty) {
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    final settingsItem = find.text('设置').evaluate().isNotEmpty
        ? find.text('设置').last
        : find.text('Settings').last;
    await tester.tap(settingsItem);
    await tester.pumpAndSettle();
  } else {
    final settings = find.text('设置').evaluate().isNotEmpty
        ? find.text('设置').first
        : find.text('Settings').first;
    await tester.tap(settings);
    await tester.pumpAndSettle();
  }

  final diagnosticsTab = find.text('开发者诊断').evaluate().isNotEmpty
      ? find.text('开发者诊断').first
      : find.text('Developer Diagnostics').first;
  await tester.ensureVisible(diagnosticsTab);
  await tester.tap(diagnosticsTab, warnIfMissed: false);
  await tester.pumpAndSettle();

  final finder = find.byKey(const Key('developer-diagnostics-details')).first;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String id) async {
  final finder = find.byKey(ValueKey('workflow-tab-$id'));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
