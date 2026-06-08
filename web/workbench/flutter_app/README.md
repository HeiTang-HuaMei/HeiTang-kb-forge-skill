# HeiTang Workbench Flutter Scaffold

This is a Flutter scaffold for the HeiTang Knowledge Workbench UI prototype.

Current status:

- Mock and contract viewer pages are implemented.
- A desktop-only local Core CLI bridge contract exists in `lib/core_bridge/local_core_bridge.dart`.
- `not_full_operation_yet: true`.
- Page workflows are not wired end to end yet, so this is not a full user-operable Workbench.
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
