import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heitang_workbench/contracts/sample_contracts.dart';
import 'package:heitang_workbench/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpWorkbench(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      HeiTangWorkbenchApp(
        contracts: sampleWorkbenchContracts,
        campaign6AgentRuntimeStatus: sampleCampaign6AgentRuntimeStatus,
        campaign7ConfigurationStatus: sampleCampaign7ConfigurationStatus,
        campaign9DesktopDeliveryStatus: sampleCampaign9DesktopDeliveryStatus,
        isWebRuntime: false,
        enableLocalCoreActions: false,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('rc4 keeps lower navigation reachable at EXE audit sizes',
      (tester) async {
    for (final size in <Size>[
      const Size(1280, 720),
      const Size(1366, 768),
      const Size(1440, 900),
    ]) {
      await pumpWorkbench(tester, size);

      for (final entry in <MapEntry<Key, Key>>[
        const MapEntry(
            Key('sidebar-agent-factory-runtime'), Key('agent-workspace-setup')),
        const MapEntry(
            Key('sidebar-reports-audit'), Key('validation-checklist')),
        const MapEntry(
            Key('sidebar-workspace'), Key('settings-workspace-overview')),
      ]) {
        final navItem = find.byKey(entry.key).first;
        await tester.ensureVisible(navItem);
        await tester.tap(navItem, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.byKey(entry.value), findsOneWidget,
            reason: '${entry.key} at $size');
        expect(tester.takeException(), isNull, reason: size.toString());
      }
    }
  });

  testWidgets('rc4 search and runtime preview clicks show visible feedback',
      (tester) async {
    await pumpWorkbench(tester, const Size(1280, 720));

    await tester.tap(find.byKey(const Key('topbar-search-field')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('topbar-real-search-input')), findsOneWidget);
    expect(find.textContaining('display_only'), findsNothing);

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-document-library')));
    await tester.tap(find.byKey(const Key('sidebar-document-library')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('添加资料'), findsWidgets);
    expect(find.byKey(const Key('document-library-tab-1')), findsOneWidget);
    expect(find.byKey(const Key('import-intake-surface')), findsOneWidget);
    expect(find.text('资料入口'), findsWidgets);
    expect(find.text('导入 Owner input 文件夹'), findsNothing);
    expect(find.text('运行完整链路'), findsNothing);

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-retrieval-verification')));
    await tester.tap(find.byKey(const Key('sidebar-retrieval-verification')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('测试知识库').last, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('外部来源核对未启用'), findsWidgets);
    expect(find.textContaining('网络权限'), findsWidgets);

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-document-generation')));
    await tester.tap(find.byKey(const Key('sidebar-document-generation')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('生成文档'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.textContaining('尚未生成'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('sidebar-skill-factory')));
    await tester.tap(find.byKey(const Key('sidebar-skill-factory')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    final skillButton = find.text('生成技能').first;
    await tester.ensureVisible(skillButton);
    await tester.tap(skillButton, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.textContaining('请先构建知识库'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rc7 main-flow status labels are product owned', (tester) async {
    await pumpWorkbench(tester, const Size(1366, 768));

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-document-generation')));
    await tester.tap(find.byKey(const Key('sidebar-document-generation')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.textContaining('display_only'), findsNothing);
    expect(find.byKey(const Key('document-generation-tasks')), findsOneWidget);
    expect(find.text('生成文档'), findsWidgets);
    expect(find.textContaining('display_only'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('sidebar-skill-factory')));
    await tester.tap(find.byKey(const Key('sidebar-skill-factory')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('从知识库生成技能'), findsWidgets);
    expect(find.text('导入模板技能'), findsWidgets);
    expect(find.text('生成技能'), findsWidgets);
    expect(find.textContaining('display_only'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('sidebar-workspace')));
    await tester.tap(find.byKey(const Key('sidebar-workspace')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsWidgets);
    expect(find.text('模型服务'), findsOneWidget);
    expect(find.text('记忆与存储'), findsOneWidget);
    expect(find.text('桌面交付'), findsNothing);
    expect(find.textContaining('disabled_boundary'), findsNothing);
    expect(find.textContaining('enabled_real'), findsNothing);
    expect(find.textContaining('v4.3.0 stable'), findsNothing);
    expect(find.textContaining('arbitrary shell'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
