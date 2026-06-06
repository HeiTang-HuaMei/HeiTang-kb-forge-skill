# HeiTang Workbench Flutter Scaffold

This is a mock-only Flutter scaffold for the HeiTang Knowledge Workbench UI prototype.

The current execution environment does not have the `flutter` CLI installed, so this scaffold is verified by repository tests instead of a local `flutter run`. When Flutter is available, run from this directory:

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

The app keeps the same boundaries as the static workbench prototype:

- Mock data only.
- No imports from Core pipeline modules.
- Future backend integration should replace the reserved service boundary, not the UI pages.
