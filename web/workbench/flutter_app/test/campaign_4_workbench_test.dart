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

    expect(find.text('Campaign 4 工作台'), findsOneWidget);
    expect(find.text('本地优先'), findsOneWidget);
    expect(find.text('本地 Agent 知识供应链'), findsOneWidget);
    expect(find.text('知识供应链'), findsOneWidget);
    expect(find.text('导入资料'), findsWidgets);
    expect(find.text('构建知识库'), findsWidgets);
    expect(find.text('生成 Skill'), findsWidgets);
    expect(find.text('生成 Agent 包'), findsWidgets);
    expect(find.text('验证与导出'), findsWidgets);
    expect(find.byKey(const Key('workbench-command-panel')), findsOneWidget);
    expect(find.text('本地资料输入台'), findsOneWidget);
    expect(find.text('资料来源'), findsOneWidget);
    expect(find.text('输出目标'), findsOneWidget);
    expect(find.text('导入门禁'), findsOneWidget);
    expect(find.text('等待本地输入'), findsOneWidget);
    expect(find.text('工作台概览'), findsOneWidget);
    expect(find.text('真实完成度'), findsOneWidget);
    expect(find.text('运行状态'), findsOneWidget);
    expect(find.text('输出与活动'), findsOneWidget);
    expect(find.text('最近活动'), findsOneWidget);
    expect(find.text('工作台操作'), findsOneWidget);
    expect(find.text('完成门禁保持关闭'), findsOneWidget);
    expect(find.text('查看输出路径'), findsOneWidget);
    expect(find.text('工作流阶段 1'), findsOneWidget);
    expect(find.text('工作流阶段 5'), findsOneWidget);
    expect(find.byKey(const Key('workflow-stepper')), findsOneWidget);
    expect(find.byKey(const Key('workbench-advanced-task-details')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('workbench-advanced-task-details')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workbench-input-area')), findsOneWidget);
    expect(find.byKey(const Key('workbench-progress-area')), findsWidgets);
    expect(find.byKey(const Key('workbench-output-area')), findsOneWidget);
    expect(find.byKey(const Key('workbench-evidence-area')), findsOneWidget);
    expect(find.byKey(const Key('workbench-error-area')), findsOneWidget);
    expect(find.text('任务阶段'), findsOneWidget);
    expect(find.textContaining('结果 + 证据'), findsOneWidget);
    expect(find.textContaining('没有 Core 结果不会展示完成'), findsOneWidget);
    for (final stage in WorkbenchTaskStage.values) {
      expect(find.byKey(Key('task-card-${stage.id}')), findsOneWidget);
      expect(find.byKey(Key('task-progress-${stage.id}')), findsOneWidget);
    }
    expect(find.text('等待开始'), findsWidgets);
    expect(find.text('pending'), findsNothing);
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
    expect(find.text('Agent 包'), findsWidgets);
    expect(find.text('设置'), findsWidgets);
    expect(find.text('Agent 工厂与运行'), findsNothing);
    expect(find.text('import-parsing'), findsNothing);
    expect(find.text('knowledge-package-management'), findsNothing);
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
