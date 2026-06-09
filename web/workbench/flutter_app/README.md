# HeiTang Workbench Flutter Scaffold

This is the Flutter scaffold for the HeiTang Knowledge Workbench stable `v4.0.0` UI.

Current status:

- P1 Core contract-aligned viewer pages are implemented from deterministic copied fixtures.
- Fixture source: Core `workbench-contracts --profile p1`, synced to commit `f5fa13bb11211abb0bcecaccd845e545a2dacad3` with CI run `27210849617` green.
- P1-RWF-V2 evidence, top-level reports, and P1 final gate reports are copied as deterministic assets and displayed with `drift_count=0`.
- S/A external capability contract-inclusion fixtures are copied from Core commit `c30f8adcadfedb30cb974eb62cc02a38c35a5158` and shown as boundary-only planned/future/provider entries.
- 57 local execution targets and 10 user paths are shown as passed from copied Core reports.
- `p1_full_operation_gate_status: ready_for_v4_rc`.
- `ready_for_v4_rc=true`.
- A desktop-only local Core CLI bridge contract exists in `lib/core_bridge/local_core_bridge.dart`.
- Default visual style is black / white / gray premium Windows desktop workbench.
- Light / dark mode and zh-CN / en-US language switching are supported.
- Provider, secret, network, and planned-adapter operations stay disabled with blocked reasons.
- External projects are not installed, not local-ready, and not executable from this UI.
- This UI package is aligned to stable v4.0.0. Historical copied P1 evidence still records pre-stable release boundaries.
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
