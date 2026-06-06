# Windows Desktop Scaffold

This directory reserves the Windows desktop target for the Flutter Workbench.

In this environment the Flutter CLI is unavailable, so the scaffold keeps a minimal Windows runner placeholder. When Flutter is installed, hydrate the platform files from `web/workbench/flutter_app`:

```powershell
flutter create --platforms=windows .
flutter run -d windows
```

The UI entrypoint remains `lib/main.dart` and stays mock-only.
