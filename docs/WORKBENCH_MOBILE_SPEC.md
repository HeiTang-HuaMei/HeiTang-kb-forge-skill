# HeiTang Knowledge Workbench Mobile Spec

Status: responsive web and PWA-ready prototype with Flutter platform scaffolds for Windows, Web, Android, and iOS.

## Mobile Strategy

- Use the same workbench information architecture as desktop.
- Collapse the desktop sidebar into a mobile page selector.
- Keep cards single-column on narrow screens.
- Keep tables horizontally scrollable when compact card conversion would hide contract details.
- Preserve theme and language controls in the topbar.
- Keep Flutter phone layout adaptive by switching from desktop rail navigation to a page selector, not by scaling the desktop layout.

## Breakpoints

- `980px`: collapse multi-column cards to wider rows where needed.
- `760px`: hide sidebar, show mobile navigation, reduce content padding, use single-column page layout.
- `480px`: tighten heading and metric sizes for small phones.

## Layout Rules

- Minimum viewport width: `320px`.
- No fixed-width content wider than the viewport.
- Cards, buttons, textareas, inputs, and selects must use responsive width.
- Navigation must remain reachable without horizontal scrolling.
- Text must wrap inside cards and buttons.

## PWA And Platform Readiness

- `index.html` includes viewport and theme-color metadata.
- Static Web includes `web/workbench/manifest.webmanifest`.
- Flutter Web includes `web/workbench/flutter_app/web/manifest.json`.
- Windows desktop scaffold exists under `web/workbench/flutter_app/windows/`.
- Android target scaffold exists under `web/workbench/flutter_app/android/`.
- iOS target scaffold exists under `web/workbench/flutter_app/ios/`.
- The prototype avoids backend coupling, so a future service worker can cache shell files and mock/API responses.
- This phase does not add a service worker because offline behavior and install prompts are reserved for later integration.

## Mobile Page Coverage

All workbench pages must be reachable from the mobile selector:

1. Dashboard
2. File upload
3. Job progress
4. Knowledge base list
5. Knowledge base detail
6. Review queue
7. Corrected text editor
8. KB query
9. Document generation
10. Agent / Skill management
11. Multi-agent workflow
12. Memory scope viewer
13. Settings
14. Export center

## Validation

Mobile smoke tests should verify:

- Viewport meta exists.
- Mobile navigation exists.
- Sidebar is hidden at the mobile breakpoint.
- Content grids collapse to one column.
- Required breakpoints exist in CSS.
- Flutter scaffold declares phone, tablet, and desktop layout branches.
- Web/PWA and Windows/Android/iOS target scaffold files exist.
