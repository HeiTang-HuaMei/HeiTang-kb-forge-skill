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

    expect(pages, hasLength(11));
    expect(
      pages.map((page) => page.zhTitle),
      [
        '首页',
        '文档库导入',
        '文档库',
        '知识库',
        '检索与验证',
        '文档生成',
        'Skill 工厂',
        'Agent 工作台',
        '审计中心',
        '产物中心',
        '运行设置',
      ],
    );
    expect(find.text('首页'), findsWidgets);
    expect(find.text('导入与解析'), findsNothing);
    expect(find.text('Agent 工作台'), findsWidgets);
    expect(find.text('Agent 包'), findsNothing);
    expect(find.text('Agent 工厂与运行'), findsNothing);
    expect(find.text('运行与编排'), findsNothing);
    expect(find.text('记忆中心'), findsNothing);
    expect(find.text('agent-factory-runtime'), findsNothing);
    expect(find.text('knowledge-package-management'), findsNothing);
    expect(find.byKey(const Key('action-capability-matrix')), findsNothing);
    await tester.tap(find.text('文档库').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('document-library-open-import-flow')),
        findsOneWidget);
    await tester
        .tap(find.byKey(const Key('document-library-open-import-flow')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dense-page-workbench-import-parsing')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('top bar search exposes product destinations and no-match state',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('topbar-real-search-input')));
    await tester.pumpAndSettle();
    expect(find.text('页面 · 从知识库生成 Skill，并绑定给 Agent'), findsOneWidget);

    await tester
        .tap(find.byKey(const Key('topbar-search-option-skill-factory')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dense-page-workbench-skill-factory')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('topbar-real-search-input')));
    await tester.enterText(
        find.byKey(const Key('topbar-real-search-input')), 'Agent');
    await tester.pumpAndSettle();
    expect(find.text('页面 · 创建 Agent、单 Agent 对话和多 Agent 协作'), findsOneWidget);
    await tester.tap(
        find.byKey(const Key('topbar-search-option-agent-factory-runtime')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dense-page-workbench-agent-factory-runtime')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('topbar-real-search-input')));
    await tester.enterText(
        find.byKey(const Key('topbar-real-search-input')), '没有这个对象');
    await tester.pumpAndSettle();
    expect(find.text('无匹配，前往查询控制台'), findsOneWidget);
    await tester.tap(
        find.byKey(const Key('topbar-search-option-retrieval-verification')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dense-page-workbench-retrieval-verification')),
        findsOneWidget);

    expect(find.textContaining('disabled_boundary'), findsNothing);
    expect(find.textContaining('enabled_real'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider settings use product status labels and masked secrets',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1400));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('运行设置').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Provider 与存储'));
    await tester.pumpAndSettle();

    expect(find.text('enabled_real'), findsNothing);
    expect(find.text('LLM Provider'), findsWidgets);
    expect(find.text('Provider 与存储配置'), findsOneWidget);
    expect(find.text('live smoke 通过'), findsWidgets);
    expect(find.text('API Key'), findsWidgets);
    expect(find.text('************'), findsWidgets);
    expect(find.text('掩码展示'), findsWidgets);
    expect(find.text('可用'), findsWidgets);
    expect(find.textContaining('Provider Gate'), findsNothing);
    expect(find.textContaining('开发者诊断'), findsNothing);
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
    expect(find.text('开始构建知识库'), findsOneWidget);
    await tester.tap(find.text('质量记录'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('knowledge-quality-records')), findsOneWidget);
    expect(find.text('质量与验证记录'), findsOneWidget);
    expect(find.textContaining('实时外部比对均已验收'), findsOneWidget);
    await tester.tap(find.text('检索与验证').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('retrieval-workflow')), findsOneWidget);
    expect(find.text('运行真实检索'), findsOneWidget);
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
    expect(find.text('生成任务'), findsWidgets);
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
    expect(find.textContaining('display_only'), findsNothing);
    expect(find.textContaining('需要导出器配置'), findsNothing);
    expect(find.textContaining('本地 Core 生成'), findsWidgets);
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
    expect(find.text('生成配置'), findsOneWidget);
    expect(find.text('外部本地化'), findsOneWidget);
    expect(find.text('包结构'), findsOneWidget);
    expect(find.text('验证导出'), findsOneWidget);
    expect(find.text('Skill 生成配置'), findsOneWidget);
    expect(find.text('生成 Skill'), findsWidgets);
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
    expect(find.text('治理报告与验证'), findsNothing);
    expect(find.text('验证导出'), findsOneWidget);
    expect(find.text('校验 / 复制 / 融合 / 导出 Skill'), findsOneWidget);
    expect(find.text('复制 Skill 路径'), findsNothing);
    expect(find.text('等待真实 Skill 产物'), findsWidgets);
    expect(find.text('等待可预览 Skill'), findsOneWidget);
    expect(find.byKey(const Key('action-capability-matrix')), findsNothing);
    expect(find.textContaining('生成完成'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('audit center shows real execution records and export action',
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

    expect(find.byKey(const Key('validation-checklist')), findsOneWidget);
    expect(find.text('执行记录'), findsWidgets);
    expect(find.text('失败记录'), findsWidgets);
    expect(find.text('产物记录'), findsWidgets);

    await tester.tap(find.byKey(const Key('page-tab-1')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('report-evidence-list')), findsOneWidget);

    await tester.tap(find.byKey(const Key('page-tab-2')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('controlled-export-summary')), findsOneWidget);
    expect(find.text('导出审计报告'), findsOneWidget);
    expect(find.textContaining('rc10 等待 Owner 复验'), findsNothing);
    expect(find.textContaining('Owner 视觉验收已通过'), findsNothing);
    expect(find.textContaining('Release'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings owns providers and storage without template management',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        enableLocalCoreActions: false,
        initialSelectedIndex: 10,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Provider 与存储'), findsOneWidget);
    expect(find.text('模板管理'), findsNothing);
    expect(find.byKey(const Key('settings-provider-storage')), findsNothing);
    await tester.tap(find.text('Provider 与存储'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-provider-storage')), findsOneWidget);
    expect(find.textContaining('************'), findsOneWidget);
    expect(find.text('测试存储连接'), findsOneWidget);
    expect(find.text('保存配置'), findsOneWidget);
    expect(find.textContaining('sk-test-secret'), findsNothing);
    expect(find.text('模板库'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('agent page owns creation, minimal chat, discussion, and history',
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
    expect(find.text('Agent 工作台'), findsWidgets);
    expect(find.byKey(const Key('agent-workspace-setup')), findsOneWidget);
    expect(find.text('工作区创建'), findsOneWidget);
    expect(find.text('Agent 配置'), findsOneWidget);
    final configTab = find.byKey(const Key('page-tab-1'));
    await tester.ensureVisible(configTab);
    await tester.tap(configTab, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-create-product-flow')), findsOneWidget);
    expect(find.text('生成 Agent 完整配置'), findsWidgets);
    expect(find.text('复制 Agent 路径'), findsNothing);
    expect(find.text('等待真实 Agent 产物'), findsWidgets);
    expect(find.text('等待可预览 Agent'), findsOneWidget);
    expect(find.text('最小对话'), findsOneWidget);
    expect(find.text('A2A 协作'), findsOneWidget);
    expect(find.text('运行审计'), findsOneWidget);
    expect(find.text('选择文件夹'), findsNothing);
    expect(find.text('构建知识库'), findsNothing);
    expect(find.text('生成 Skill'), findsNothing);
    expect(find.text('搜索当前关键词'), findsNothing);

    final chatTab = find.byKey(const Key('page-tab-2'));
    await tester.ensureVisible(chatTab);
    await tester.tap(chatTab, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-minimal-chat')), findsOneWidget);
    expect(find.text('等待对话产物'), findsOneWidget);
    expect(find.text('等待会话历史'), findsOneWidget);
    expect(find.text('等待可预览对话'), findsOneWidget);
    expect(find.text('等待可预览历史'), findsOneWidget);

    final discussionTab = find.byKey(const Key('page-tab-3'));
    await tester.ensureVisible(discussionTab);
    await tester.tap(discussionTab, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('multi-agent-discussion-product-flow')),
        findsOneWidget);
    expect(find.text('启动联合讨论'), findsOneWidget);
    expect(find.text('等待讨论纪要'), findsOneWidget);
    expect(find.text('等待可预览纪要'), findsOneWidget);

    final historyTab = find.byKey(const Key('page-tab-4'));
    await tester.ensureVisible(historyTab);
    await tester.tap(historyTab, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-run-history')), findsOneWidget);
    expect(find.text('PRD P0 工作区 / A2A'), findsOneWidget);
    expect(find.textContaining('Campaign'), findsNothing);
    expect(find.textContaining('disabled_boundary'), findsNothing);
    expect(find.textContaining('enabled_real'), findsNothing);
    expect(find.textContaining('安全边界'), findsNothing);
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
    expect(find.text('Build Knowledge Base'), findsOneWidget);
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

  testWidgets('desktop shell does not duplicate native window controls',
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
    expect(find.byKey(const Key('desktop-window-controls')), findsNothing);
    expect(find.byKey(const Key('window-control-minimize')), findsNothing);
    expect(find.byKey(const Key('window-control-maximize')), findsNothing);
    expect(find.byKey(const Key('window-control-close')), findsNothing);
    expect(find.text('黑糖'), findsOneWidget);

    final topbarRect =
        tester.getRect(find.byKey(const Key('desktop-topbar-single-row')));
    final searchRect =
        tester.getRect(find.byKey(const Key('topbar-search-field')));
    expect((topbarRect.center.dy - searchRect.center.dy).abs(),
        lessThanOrEqualTo(1));

    await tester.binding.setSurfaceSize(const Size(1920, 1000));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('desktop-status-bar')), findsOneWidget);
    expect(find.byKey(const Key('page-scroll-dashboard')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
