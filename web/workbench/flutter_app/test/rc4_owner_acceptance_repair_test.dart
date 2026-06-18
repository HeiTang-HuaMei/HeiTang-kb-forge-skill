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

    await tester.ensureVisible(find.byKey(const Key('sidebar-import-parsing')));
    await tester.tap(find.byKey(const Key('sidebar-import-parsing')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('import-intake-surface')), findsOneWidget);
    expect(find.text('选择来源'), findsWidgets);
    expect(find.text('导入 Owner input 文件夹'), findsNothing);
    expect(find.text('运行完整链路'), findsNothing);

    await tester
        .ensureVisible(find.byKey(const Key('sidebar-retrieval-verification')));
    await tester.tap(find.byKey(const Key('sidebar-retrieval-verification')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('运行真实检索'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('外部事实验证未启用'), findsWidgets);
    expect(find.textContaining('显式 opt-in'), findsWidgets);

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
    final skillButton = find.text('生成 Skill').first;
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
    expect(find.text('生成文档'), findsWidgets);
    expect(find.text('重新生成'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('sidebar-skill-factory')));
    await tester.tap(find.byKey(const Key('sidebar-skill-factory')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('从知识库生成 Skill'), findsOneWidget);
    expect(find.text('外部本地化'), findsOneWidget);
    expect(find.text('生成 Skill'), findsWidgets);
    expect(find.textContaining('display_only'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('sidebar-workspace')));
    await tester.tap(find.byKey(const Key('sidebar-workspace')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    final desktopTab = find.text('桌面交付').first;
    await tester.ensureVisible(desktopTab);
    await tester.tap(desktopTab, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('v4.3.0-rc10'), findsWidgets);
    expect(find.textContaining('pending_owner_retest'), findsWidgets);
    expect(find.textContaining('disabled_boundary'), findsNothing);
    expect(find.textContaining('enabled_real'), findsNothing);
    expect(find.textContaining('v4.3.0 stable'), findsNothing);
    expect(find.textContaining('arbitrary shell'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
