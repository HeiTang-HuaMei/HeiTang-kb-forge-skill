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
    expect(find.textContaining('release_candidate'), findsNothing);
    expect(find.textContaining('Core 证据快照'), findsNothing);
    expect(find.text('Skill 工厂'), findsWidgets);
    expect(
        find.byKey(const Key('skill-metadata-source-config')), findsOneWidget);
    expect(find.text('生成配置'), findsOneWidget);
    expect(find.text('外部本地化'), findsOneWidget);
    expect(find.text('包结构'), findsOneWidget);
    expect(find.text('验证导出'), findsOneWidget);
    await tester.tap(find.text('外部本地化').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('skill-external-localization')), findsOneWidget);
    await tester.tap(find.text('包结构').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skill-output-preview')), findsOneWidget);
    await tester.tap(find.text('验证导出').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skill-validation-summary')), findsOneWidget);
    expect(find.textContaining('Execute local runtime'), findsNothing);
    expect(find.textContaining('运行本地 runtime'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the Skill Factory workflow in the desktop target shell',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1100));
    await tester.pumpWidget(HeiTangWorkbenchApp(
      contracts: sampleWorkbenchContracts,
      skillSuiteWorkflow: sampleSkillSuiteWorkflow,
      initialSelectedIndex:
          pages.indexWhere((page) => page.id == 'skill-factory'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Knowledge-to-Skill Suite 工作流'), findsNothing);
    expect(find.textContaining('Web 仅展示可审计产物'), findsNothing);
    expect(find.byKey(const ValueKey('workflow-tab-overview')), findsNothing);
    expect(
        find.byKey(const Key('skill-metadata-source-config')), findsOneWidget);
    expect(find.byKey(const Key('skill-output-preview')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
