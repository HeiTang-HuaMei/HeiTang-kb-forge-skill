# HeiTang Workbench Flutter Scaffold

This is the Flutter scaffold for the HeiTang Knowledge Workbench UI contract-alignment pass.

Current status:

- P1 Core contract-aligned viewer pages are implemented from deterministic copied fixtures.
- Fixture source: Core `workbench-contracts --profile p1`, verified against commit `fa00d6c00a11e7fda62919318f4cf17f9b72bfd9`.
- P1-RWF-V1 evidence is copied as a deterministic asset and displayed without changing the full P1 gate status.
- A desktop-only local Core CLI bridge contract exists in `lib/core_bridge/local_core_bridge.dart`.
- Default visual style is black / white / gray premium Windows desktop workbench.
- Light / dark mode and zh-CN / en-US language switching are supported.
- `not_full_operation_yet: true`.
- Page workflows are not wired end to end through the final P1 Integrated Gate, so this is not marked full operation passed.
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
