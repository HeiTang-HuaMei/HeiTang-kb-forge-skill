# Campaign 9 Dependency and Asset Manifest

Date: 2026-06-17

Status: pass

## Release Bundle Manifest

| Field | Value |
| --- | --- |
| Manifest | `kb-forge-skill-ui/web/workbench/flutter_app/output/campaign9_desktop_smoke/release_bundle_manifest.json` |
| Release directory | `build/windows/x64/runner/Release` |
| File count | `49` |
| Total size | `31723100` bytes |
| EXE | `heitang_workbench.exe` |
| EXE SHA-256 | `d8e58accd56571fc08cfec3178b77ef7e1c3a58c5930c7d9d37718b1253e9d87` |

## Required Runtime Files

| Required file | Present |
| --- | --- |
| `heitang_workbench.exe` | yes |
| `flutter_windows.dll` | yes |
| `data/` | yes |
| `data/flutter_assets/` | yes |
| `data/icudtl.dat` | yes |

## Included Asset Classes

| Asset Class | Campaign 9 Treatment |
| --- | --- |
| Brand assets | bundled by Flutter asset manifest |
| Campaign 4/6/7 contract assets | bundled by Flutter asset manifest |
| Campaign 9 desktop delivery status | added and bundled |
| External capability registry | bundled as existing UI evidence registry |
| Parser backend matrix | bundled as existing UI evidence matrix |
| Skill governance fixtures | bundled as existing UI evidence fixtures |

## Optional Dependency Boundary

Optional dependencies are not represented as bundled runtime guarantees unless the release bundle manifest contains the required file. The legacy Tauri scaffold remains outside the accepted Campaign 9 packaging path.

## Secret Boundary

Provider and tool credentials remain env/secret-store only. No raw key or token is expected in Flutter assets, logs, reports, or the packaged release directory.
