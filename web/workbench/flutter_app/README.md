# HeiTang Workbench Flutter Scaffold

This is the Flutter scaffold for the HeiTang Knowledge Workbench `v4.2.0` P2.2 Skill Factory industrial UI line, preserving `v4.1.0` Parser/OCR evidence sync fixtures and `v4.1.1` Test Governance as the Entry Gate baseline.

Current status:

- P1 Core contract-aligned viewer pages are implemented from deterministic copied fixtures.
- Fixture source: Core `workbench-contracts --profile p1`, synced to commit `f5fa13bb11211abb0bcecaccd845e545a2dacad3` with CI run `27210849617` green.
- P1-RWF-V2 evidence, top-level reports, and P1 final gate reports are copied as deterministic assets and displayed with `drift_count=0`.
- S/A external capability contract-inclusion fixtures are copied from Core commit `c30f8adcadfedb30cb974eb62cc02a38c35a5158` and shown as boundary-only planned/future/provider entries.
- P2.1 parser backend matrix evidence is copied from Core runtime baseline commit `576a62075dc1ecbe00388bb0569fd1fc767be7cb` into `assets/parser_backends/parser_backend_matrix.json`.
- Builtin fallback, Docling, PaddleOCR, and Unstructured are shown with install mode, acceptance status, stable surface, evidence path, and known limitations.
- Unstructured is displayed with stable `.md/.txt` surface only; PDF/DOCX/image extras remain future hardening.
- 57 local execution targets and 10 user paths are shown as passed from copied Core reports.
- `p1_full_operation_gate_status: ready_for_v4_rc`.
- `ready_for_v4_rc=true`.
- A desktop-only local Core CLI bridge contract exists in `lib/core_bridge/local_core_bridge.dart`.
- Default visual style is black / white / gray premium Windows desktop workbench.
- Light / dark mode and zh-CN / en-US language switching are supported.
- Provider, secret, network, and planned-adapter operations stay disabled with blocked reasons.
- External projects are not installed, not local-ready, and not executable from this UI.
- Parser/OCR backends are not executed from this UI; static Web Workbench only displays Core evidence and boundaries.
- v4.2.0 Skill Factory workflow displays Knowledge Package, Evidence, Methodology, Candidates, Hierarchy, Skill Suite, Reports, and Export evidence without executing local CLI from the web build.
- v4.1.1 validation governance lives in the Python test gate manifest and does not add parser/OCR runtime execution controls.
- The parser/OCR evidence fixture remains aligned to v4.1.0 Workbench evidence sync. The current UI package line is v4.2.0 P2.2 Skill Factory industrial workflow, v4.1.1 remains the Entry Gate baseline, and the historical `v4.0.0` and `v4.1.0` tags remain untouched.
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
