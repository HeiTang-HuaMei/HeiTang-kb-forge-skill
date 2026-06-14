import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/contracts/sample_contracts.dart';
import 'package:heitang_workbench/main.dart';
import 'package:heitang_workbench/workbench/task_model.dart';
import 'package:heitang_workbench/workbench/task_workbench.dart';

void main() {
  testWidgets('workbench renders five areas and six task progress cards',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1800));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TaskWorkbenchSurface(
              localeCode: 'zh-CN',
              workspace: r'C:\workspace',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('workbench-input-area')), findsOneWidget);
    expect(find.byKey(const Key('workbench-progress-area')), findsOneWidget);
    expect(find.byKey(const Key('workbench-output-area')), findsOneWidget);
    expect(find.byKey(const Key('workbench-evidence-area')), findsOneWidget);
    expect(find.byKey(const Key('workbench-error-area')), findsOneWidget);
    for (final stage in WorkbenchTaskStage.values) {
      expect(find.byKey(Key('task-card-${stage.id}')), findsOneWidget);
      expect(find.byKey(Key('task-progress-${stage.id}')), findsOneWidget);
    }
    expect(find.text('completed'), findsOneWidget);
    expect(find.textContaining('Agent Runtime complete'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('top-level navigation is limited to seven entries',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(pages, hasLength(7));
    expect(find.text('工作台'), findsWidgets);
    expect(find.text('Agent 包生成'), findsWidgets);
    expect(find.text('Agent 工厂与运行'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workbench does not claim later campaign completion',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1800));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();

    for (final claim in [
      'Agent Runtime complete',
      'Memory Runtime complete',
      'Configuration complete',
      'Full Testing complete',
      'EXE complete',
      'Release complete',
    ]) {
      expect(find.textContaining(claim), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });
}
