import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/contracts/workbench_contracts.dart';
import 'package:heitang_workbench/main.dart';

void main() {
  test('contract fixture parses core workbench contracts', () {
    final contracts = sampleWorkbenchContracts;

    expect(contracts.manifest.outputFiles, contains('workbench_navigation_contract.json'));
    expect(contracts.navigation.views, hasLength(14));
    expect(contracts.actions.actions.map((action) => action.id), contains('generate_documents'));
    expect(contracts.agent.supportedModes, containsAll(['standalone', 'kb_bound']));
    expect(contracts.hierarchy.bindingFields, containsAll(['parent', 'child', 'child_mode', 'bound_kbs']));
    expect(contracts.memory.lifecycleFields, contains('token_budget_policy'));
    expect(contracts.storage.storageAreas.keys, containsAll(['package_storage', 'skill_storage', 'agent_storage', 'memory_storage', 'index_storage']));
    expect(contracts.errors.errorStates, contains('contract_file_missing'));
  });

  testWidgets('renders desktop HeiTang workbench shell without Flutter exceptions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    expect(find.text('黑糖 HeiTang'), findsOneWidget);
    expect(find.text('Knowledge Workbench'), findsOneWidget);
    expect(find.text('仪表盘'), findsWidgets);
    expect(pages, hasLength(14));
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders mobile HeiTang workbench shell without Flutter exceptions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    expect(find.text('黑糖 HeiTang'), findsOneWidget);
    expect(find.text('Knowledge Workbench'), findsOneWidget);
    expect(find.text('页面'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    expect(find.text('仪表盘'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps English and dark mode controls usable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();

    expect(find.text('HeiTang'), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders contract-driven agent hierarchy memory and storage pages', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1120));
    await tester.pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    await tester.tap(find.text('多 Agent 工作流').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('parent'), findsWidgets);
    expect(find.textContaining('standalone'), findsWidgets);

    await tester.tap(find.text('记忆范围查看器').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('explicit_only'), findsWidgets);
    expect(find.textContaining('queue_memory_writeback'), findsWidgets);

    await tester.tap(find.text('设置').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('local_workspace'), findsWidgets);
    expect(find.textContaining('package_storage'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders contract-driven action and agent mode data in English', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(HeiTangWorkbenchApp(contracts: sampleWorkbenchContracts));
    await tester.pumpAndSettle();

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agent / Skill management').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('standalone'), findsWidgets);
    expect(find.textContaining('kb_bound'), findsWidgets);
    expect(find.textContaining('retrieval_config.yaml'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
