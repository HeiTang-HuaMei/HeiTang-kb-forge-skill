# Icon Guidelines

v1.2.3 treats icons as an asset checkpoint, not the core feature.

## Source Assets

```text
assets/icon_sources/tiger_source.png
assets/icon_sources/cat_source.png
```

## Split

- Black tiger head: large app identity, EXE icon, desktop shortcut, regular Tauri app icon, installer app icon.
- Black cat head: small / corner / system icon assets, taskbar best-effort, window top-left best-effort, tray future, file association future.

## Platform Limitation

Windows and Tauri may bind EXE icon, taskbar icon, and window icon to the same app icon. If the taskbar or window top-left icon cannot independently use the cat asset, the build should not be blocked. Cat assets are reserved for later best-effort integration.

## Non-Scope

Do not add:

- tiger hero image
- splash hero visual
- documentation cover image
- brand poster
- large illustration background
