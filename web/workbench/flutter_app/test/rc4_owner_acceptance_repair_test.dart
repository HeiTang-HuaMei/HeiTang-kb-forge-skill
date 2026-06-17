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
        const MapEntry(Key('sidebar-agent-factory-runtime'),
            Key('campaign6-runtime-overview')),
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
    expect(find.textContaining('display_only'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('sidebar-import-parsing')));
    await tester.tap(find.byKey(const Key('sidebar-import-parsing')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rc6-runtime-truth-panel')), findsOneWidget);
    expect(find.text('选择文件'), findsWidgets);
    expect(find.text('运行完整链路'), findsWidgets);

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-retrieval-verification')));
    await tester.tap(find.byKey(const Key('sidebar-retrieval-verification')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('运行真实检索'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('执行外部事实验证'), findsOneWidget);
    expect(find.textContaining('opt-in'), findsWidgets);

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-document-generation')));
    await tester.tap(find.byKey(const Key('sidebar-document-generation')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('排队生成任务'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.textContaining('没有真实导出文件'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('sidebar-skill-factory')));
    await tester.tap(find.byKey(const Key('sidebar-skill-factory')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    final skillPreviewButton = find.text('准备 Skill 配置预览').first;
    await tester.ensureVisible(skillPreviewButton);
    await tester.tap(skillPreviewButton, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.textContaining('请先构建知识库'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rc4 status labels do not overstate preview-only surfaces',
      (tester) async {
    await pumpWorkbench(tester, const Size(1366, 768));

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-document-generation')));
    await tester.tap(find.byKey(const Key('sidebar-document-generation')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.textContaining('display_only'), findsWidgets);
    expect(find.textContaining('无真实文件产物则不标 accepted'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('sidebar-skill-factory')));
    await tester.tap(find.byKey(const Key('sidebar-skill-factory')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('书籍 / 文档转 Skill'), findsOneWidget);
    expect(find.textContaining('display_only'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('sidebar-workspace')));
    await tester.tap(find.byKey(const Key('sidebar-workspace')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    final desktopTab = find.text('桌面交付').first;
    await tester.ensureVisible(desktopTab);
    await tester.tap(desktopTab, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('v4.3.0-rc6'), findsWidgets);
    expect(find.textContaining('pending_owner_retest'), findsWidgets);
    expect(find.textContaining('GitHub Release'), findsWidgets);
    expect(find.textContaining('v4.3.0 stable'), findsNothing);
    expect(find.textContaining('arbitrary shell'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
