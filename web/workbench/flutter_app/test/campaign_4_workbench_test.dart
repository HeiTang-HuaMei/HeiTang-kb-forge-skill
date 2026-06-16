import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/contracts/sample_contracts.dart';
import 'package:heitang_workbench/main.dart';
import 'package:heitang_workbench/workbench/task_workbench.dart';

void main() {
  testWidgets('dashboard shows one current task and hides technical details',
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

    expect(
        find.byKey(const Key('dashboard-current-task-panel')), findsOneWidget);
    expect(find.text('当前任务'), findsOneWidget);
    expect(find.text('本地优先'), findsOneWidget);
    expect(find.text('导入资料'), findsWidgets);
    expect(find.text('一个主操作'), findsOneWidget);
    expect(find.text('选择本地文件或文件夹'), findsOneWidget);
    expect(find.text('当前阶段状态'), findsOneWidget);
    expect(find.text('预期产物'), findsOneWidget);
    expect(find.byKey(const Key('workbench-side-panel')), findsOneWidget);
    expect(find.text('工作台概览'), findsOneWidget);
    expect(find.text('真实完成度'), findsOneWidget);
    expect(find.text('运行状态'), findsOneWidget);
    expect(find.text('输出与活动'), findsOneWidget);
    expect(find.byKey(const Key('side-output-导入清单')), findsOneWidget);
    expect(find.text('最近活动'), findsWidgets);
    expect(find.text('现在'), findsOneWidget);
    expect(find.byKey(const Key('workbench-command-panel')), findsNothing);
    expect(find.byKey(const Key('workflow-stepper')), findsNothing);
    expect(find.text('工作流阶段 1'), findsNothing);
    expect(
        find.byKey(const Key('workbench-advanced-task-details')), findsNothing);
    expect(find.text('产物交接链'), findsOneWidget);
    expect(find.textContaining('承接: 新来源'), findsOneWidget);
    expect(find.textContaining('下一阶段: 解析资料'), findsWidgets);
    expect(find.text('等待开始'), findsWidgets);
    expect(find.text('pending'), findsNothing);
    expect(find.textContaining('Agent Runtime complete'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop navigation follows the real product chain',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(pages, hasLength(10));
    expect(
      pages.map((page) => page.zhTitle),
      [
        '仪表盘',
        '导入与解析',
        '文档库',
        '知识库',
        '检索与验证',
        '文档生成',
        'Skill 工厂',
        'Agent 工厂',
        '审计与报告',
        '设置',
      ],
    );
    expect(find.text('仪表盘'), findsWidgets);
    expect(find.text('导入与解析'), findsWidgets);
    expect(find.text('Agent 工厂'), findsWidgets);
    expect(find.text('Agent 包'), findsNothing);
    expect(find.text('Agent 工厂与运行'), findsNothing);
    expect(find.text('运行与编排'), findsNothing);
    expect(find.text('记忆中心'), findsNothing);
    expect(find.text('agent-factory-runtime'), findsNothing);
    expect(find.text('knowledge-package-management'), findsNothing);
    expect(find.byKey(const Key('action-capability-matrix')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider runtime marker is accepted while other gaps remain',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1400));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Provider Runtime'), findsOneWidget);
    expect(find.text('enabled_real'), findsWidgets);
    expect(find.text('live smoke accepted'), findsWidgets);
    expect(find.text('外部事实验证'), findsOneWidget);
    expect(find.text('enabled_real_degraded'), findsNothing);
    expect(find.text('Knowledge Quality Gate'), findsOneWidget);
    expect(find.text('Document Export'), findsOneWidget);
    expect(find.text('Skill Governance'), findsOneWidget);
    expect(find.text('Agent Creation Package'), findsWidgets);

    await tester.tap(find.text('设置').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Provider 与存储'));
    await tester.pumpAndSettle();

    expect(find.text('LLM Provider'), findsWidgets);
    expect(find.text('live smoke 通过'), findsWidgets);
    expect(find.text('API Key'), findsWidgets);
    expect(find.text('sk-************'), findsWidgets);
    expect(find.text('掩码展示'), findsWidgets);
    expect(find.text('Provider 运行状态'), findsOneWidget);
    for (final status in [
      'connected',
      'unavailable',
      'missing_key',
      'timeout',
      'fallback_used',
      'cost_blocked',
    ]) {
      expect(find.text(status), findsOneWidget);
    }
    expect(find.textContaining('sk-test-secret'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop business pages hide the old state strip',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < pages.length; index++) {
      final title = pages[index].zhTitle;
      if (index > 0) {
        await tester.tap(find.text(title).first);
        await tester.pumpAndSettle();
      }

      expect(
          find.byKey(Key('page-state-strip-${pages[index].id}')), findsNothing);
      expect(find.textContaining('正常态'), findsNothing);
      expect(find.textContaining('空态'), findsNothing);
      expect(find.textContaining('加载态'), findsNothing);
      expect(find.textContaining('错误态'), findsNothing);
      expect(find.textContaining('可用操作'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'knowledge page exposes knowledge base, document, and retrieval workflows',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        initialSelectedIndex: 3,
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(
            const Key('dense-page-workbench-knowledge-package-management')),
        findsOneWidget);
    expect(find.text('知识库'), findsWidgets);
    expect(find.text('向量索引'), findsOneWidget);
    expect(find.text('存储边界'), findsOneWidget);
    expect(find.byKey(const Key('knowledge-package-list')), findsOneWidget);
    expect(find.text('质量记录'), findsOneWidget);
    expect(find.text('输出目标'), findsNothing);
    expect(find.byKey(const Key('action-capability-matrix')), findsNothing);
    expect(find.byKey(const Key('product-status-panel')), findsNothing);
    expect(find.text('构建知识库草稿预览'), findsOneWidget);
    await tester.tap(find.text('质量记录'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('knowledge-quality-records')), findsOneWidget);
    expect(find.text('质量与验证记录'), findsOneWidget);
    expect(find.textContaining('实时外部比对均已验收'), findsOneWidget);
    await tester.tap(find.text('检索与验证').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('retrieval-workflow')), findsOneWidget);
    expect(find.text('运行检索验证预览'), findsOneWidget);
    expect(find.text('Document Library'), findsNothing);
    expect(find.text('Retrieval & Verification'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('documents are a first-class top-level workbench entry',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        initialSelectedIndex: 5,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dense-page-workbench-document-generation')),
        findsOneWidget);
    expect(find.text('文档生成'), findsWidgets);
    expect(find.byKey(const Key('document-generation-tasks')), findsOneWidget);
    expect(find.text('生成队列'), findsOneWidget);
    expect(find.byKey(const Key('document-central-preview')), findsOneWidget);
    await tester.tap(find.text('文档模板').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-template-library')), findsOneWidget);
    expect(find.text('文档模板归文档生成'), findsOneWidget);
    await tester.tap(find.text('导出预览'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-export-preview')), findsOneWidget);
    expect(find.text('PDF'), findsWidgets);
    expect(find.text('PPTX'), findsWidgets);
    expect(find.text('enabled_real'), findsWidgets);
    expect(find.textContaining('Release complete'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'skill builder uses page-specific builder surfaces without fake generation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        initialSelectedIndex: 6,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dense-page-workbench-skill-factory')),
        findsOneWidget);
    expect(
        find.byKey(const Key('skill-metadata-source-config')), findsOneWidget);
    expect(find.byKey(const Key('skill-output-preview')), findsOneWidget);
    expect(find.byKey(const Key('skill-validation-summary')), findsOneWidget);
    expect(find.text('Skill 元数据与来源配置'), findsOneWidget);
    expect(find.text('Skill 包结构预览'), findsOneWidget);
    expect(find.text('治理报告与验证'), findsOneWidget);
    expect(find.text('生成 Skill 草稿预览'), findsOneWidget);
    expect(find.text('Skill Governance Report'), findsOneWidget);
    expect(find.byKey(const Key('action-capability-matrix')), findsNothing);
    expect(find.text('Skill 模板驱动'), findsOneWidget);
    expect(find.text('generated'), findsNothing);
    expect(find.textContaining('生成完成'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('validation report reflects owner visual acceptance passed',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        initialSelectedIndex: 8,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('报告证据'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('report-evidence-list')), findsOneWidget);
    await tester.tap(find.text('打开验证报告预览'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Owner 视觉验收已通过'), findsWidgets);
    expect(find.textContaining('仍需 Owner 视觉验收'), findsNothing);
    expect(find.textContaining('Owner 视觉复查'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings owns providers and storage without template management',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        initialSelectedIndex: 9,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Provider 与存储'), findsOneWidget);
    expect(find.text('模板管理'), findsNothing);
    expect(find.byKey(const Key('settings-provider-storage')), findsNothing);
    await tester.tap(find.text('Provider 与存储'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-provider-storage')), findsOneWidget);
    expect(find.text('待接入'), findsWidgets);
    expect(find.textContaining('sk-************'), findsOneWidget);
    expect(find.textContaining('sk-test-secret'), findsNothing);
    expect(find.text('模板库'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('agent page is an Agent workspace, not primary Agent Package',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        initialSelectedIndex: 7,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dense-page-workbench-agent-factory-runtime')),
        findsOneWidget);
    expect(find.text('Agent Runtime'), findsWidgets);
    expect(find.byKey(const Key('campaign6-runtime-overview')), findsOneWidget);
    expect(find.text('执行总览'), findsOneWidget);
    expect(find.text('单 Agent'), findsOneWidget);
    expect(find.text('多 Agent / Memory'), findsOneWidget);
    expect(find.text('Tool Adapter'), findsOneWidget);
    expect(find.text('campaign6a_single_agent_runtime'), findsOneWidget);
    await tester.tap(find.text('单 Agent'));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('campaign6-single-agent-status')), findsOneWidget);
    expect(find.text('Knowledge QA Agent'), findsOneWidget);
    expect(find.text('Document Processing Agent'), findsOneWidget);
    expect(find.text('Workbench Operator Agent'), findsOneWidget);
    await tester.tap(find.text('多 Agent / Memory'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('campaign6-advanced-runtime-status')),
        findsOneWidget);
    expect(find.text('long_term_memory'), findsOneWidget);
    expect(find.text('a2a'), findsOneWidget);
    expect(find.text('computer_use_boundary'), findsOneWidget);
    expect(find.text('disabled_boundary'), findsWidgets);
    final toolAdapter = find.text('Tool Adapter');
    await tester.ensureVisible(toolAdapter);
    await tester.tap(toolAdapter);
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('campaign6-tool-adapter-status')), findsOneWidget);
    expect(find.text('provider_runtime_reimplemented'), findsOneWidget);
    expect(find.text('official_channel_tool_adapter_gate_required'),
        findsOneWidget);
    expect(find.text('enabled_real'), findsWidgets);
    expect(find.text('Agent 包'), findsNothing);
    expect(find.text('创建 Agent 草稿'), findsNothing);
    expect(find.text('保存版本与导出 Agent package'), findsNothing);
    expect(find.text('Workspace and Future Runtime'), findsNothing);
    expect(find.text('Subagent'), findsNothing);
    expect(find.text('Sandbox'), findsNothing);
    expect(find.text('agent-factory-runtime'), findsNothing);
    expect(find.textContaining('Agent Runtime complete'), findsNothing);
    expect(find.textContaining('自主执行'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('english mode switches the whole page language only',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        initialSelectedIndex: 3,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('EN').first);
    await tester.pumpAndSettle();

    expect(find.text('Knowledge Base'), findsWidgets);
    expect(find.text('Vector Index'), findsOneWidget);
    await tester.tap(find.text('Knowledge Base').last);
    await tester.pumpAndSettle();
    expect(find.text('Build Knowledge Base draft preview'), findsOneWidget);
    expect(find.text('知识库'), findsNothing);
    expect(find.text('文档库'), findsNothing);
    expect(find.text('检索与验证'), findsNothing);
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

  testWidgets('desktop shell exposes independent window controls',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('desktop-window-title-bar')), findsNothing);
    expect(find.byKey(const Key('desktop-topbar-single-row')), findsOneWidget);
    expect(find.byKey(const Key('desktop-window-controls')), findsOneWidget);
    expect(find.byKey(const Key('window-control-minimize')), findsOneWidget);
    expect(find.byKey(const Key('window-control-maximize')), findsOneWidget);
    expect(find.byKey(const Key('window-control-close')), findsOneWidget);
    expect(find.text('黑糖'), findsOneWidget);

    final topbarRect =
        tester.getRect(find.byKey(const Key('desktop-topbar-single-row')));
    final searchRect =
        tester.getRect(find.byKey(const Key('topbar-search-field')));
    expect((topbarRect.center.dy - searchRect.center.dy).abs(),
        lessThanOrEqualTo(1));

    for (final key in [
      'window-control-minimize',
      'window-control-maximize',
      'window-control-close',
    ]) {
      final controlRect = tester.getRect(find.byKey(Key(key)));
      expect((controlRect.center.dy - searchRect.center.dy).abs(),
          lessThanOrEqualTo(3));
    }

    await tester.tap(find.byKey(const Key('window-control-minimize')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('desktop-status-bar')), findsOneWidget);
    expect(find.byKey(const Key('page-scroll-dashboard')), findsOneWidget);

    await tester.tap(find.byKey(const Key('window-control-maximize')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.filter_none_outlined), findsOneWidget);
    expect(find.byKey(const Key('desktop-status-bar')), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(1920, 1000));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('desktop-status-bar')), findsOneWidget);
    expect(find.byKey(const Key('page-scroll-dashboard')), findsOneWidget);

    await tester.tap(find.byKey(const Key('window-control-maximize')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.crop_square_outlined), findsOneWidget);

    await tester.tap(find.byKey(const Key('window-control-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('desktop-window-controls')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
