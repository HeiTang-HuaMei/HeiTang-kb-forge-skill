# HeiTang Workbench Flutter Scaffold

This is the Flutter scaffold for the HeiTang Knowledge Workbench P1-RWF-V2 evidence UI consumption pass.

Current status:

- P1 Core contract-aligned viewer pages are implemented from deterministic copied fixtures.
- Fixture source: Core `workbench-contracts --profile p1`, verified against commit `f9c9718666376adf8540fea075f916b3f22b85e4`.
- P1-RWF-V2 evidence and top-level reports are copied as deterministic assets and displayed with `drift_count=0`.
- 57 local execution targets and 10 user paths are shown as passed from copied Core reports.
- `p1_full_operation_gate_status: passed_for_v4_rc_candidate`.
- A desktop-only local Core CLI bridge contract exists in `lib/core_bridge/local_core_bridge.dart`.
- Default visual style is black / white / gray premium Windows desktop workbench.
- Light / dark mode and zh-CN / en-US language switching are supported.
- `not_full_operation_yet: true`.
- Provider, secret, network, and planned-adapter operations stay disabled with blocked reasons.
- This is not the v4.0 Workbench RC.
- Web builds do not execute local Core CLI commands.

When Flutter is available, run from this directory:

```powershell
flutter pub get
flutter run -d windows
flutter run -d chrome
```

Targets are scaffolded for:

- Windows desktop: `windows/`
- Web/PWA: `web/`
- Android: `android/`
- iOS: `ios/`

The app keeps these boundaries:

- Mock data for page rendering.
- Desktop local Core CLI bridge contract only.
- Web does not execute the local Core CLI.
- No imports from Core pipeline modules.
- No provider secrets in UI bridge requests.
- Future backend integration should replace the reserved service boundary, not the UI pages.
