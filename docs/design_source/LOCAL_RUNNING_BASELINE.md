# 本地运行基线

## 目的

本文件定义修复阶段如何确认 Owner 看到的是最新运行 UI，而不是旧 EXE、旧进程、旧 app.so 或旧 route。

## 默认启动方式

UI closure 修复默认使用：

```powershell
flutter run -d windows
```

工作目录：

```text
web/workbench/flutter_app
```

Package candidate build、EXE smoke、installer smoke 不属于普通 UI 修复默认动作，除非当前任务明确要求。

## 启动前检查

启动前必须确认：

- 旧 `heitang_workbench.exe` 进程已关闭。
- 旧 review build 窗口已关闭。
- Owner 当前验收窗口不是旧实例。
- 不删除源码。
- 不删除用户工作区。
- 不删除 output/report。
- 不修改 `capability_chain_status.json`。

如需清理，只允许清理明确的 build 产物或测试 workspace，并且必须符合当前任务授权。

## Provenance 记录

每次 running UI 验收必须记录：

```text
startup_method = flutter run -d windows | fresh local review build
git_head = <commit>
dirty_marker = clean | dirty
source_timestamp = <latest relevant source timestamp>
exe_timestamp = <timestamp or n/a>
app_so_timestamp = <timestamp or n/a>
old_process_closed = true
owner_visible_ui_tested = true
```

dirty 并不自动失败，但必须说明 dirty 文件是否属于当前修复。

## 旧 UI 识别

如果 running UI 仍显示旧入口或旧布局，先做 provenance check，不要继续声明 Phase closed。

必须回答：

- 当前运行应用是 `flutter run` 还是 build/windows EXE？
- 当前运行应用的 build 时间、版本号、commit hash 或源码标识是什么？
- 修改过的源码文件是否被当前运行实例加载？
- 关闭旧进程后重新启动，截图是否变化？
- 截图中仍存在的按钮或文案来自哪个源码文件或旧数据？

## 文案来源定位

定位旧按钮或旧文案时使用：

```powershell
rg -n "文案内容" web/workbench/flutter_app/lib web/workbench/flutter_app/assets
```

如果源码中找不到：

- 查运行时生成数据。
- 查 workspace 本地数据。
- 查 assets fixture。
- 查旧 build 是否仍在运行。

不得只凭源码 diff 判断 UI 已修复。

## 验收截图

每个关键状态建议保留截图：

- 空状态。
- 加载状态。
- 成功状态。
- 失败状态。
- 删除确认。
- 导出成功。
- KB 外拒答。
- 合并冲突提示。

截图只用于证明 Owner-visible UI，不替代后台真值对账。

## 本地运行最小闭环

一次 UI 修复完成后至少确认：

- 最新源码启动成功。
- 对应页面能打开。
- 修复点在 running UI 中可见。
- 旧文案或旧入口不再出现，或能解释来源。
- 操作后后台真值一致。
- 重启后状态一致。

## 常用只读命令

查看进程：

```powershell
Get-Process | Where-Object { $_.ProcessName -like '*heitang*' -or $_.ProcessName -like '*flutter*' }
```

查看 git 标识：

```powershell
git rev-parse --short HEAD
git status --short
```

查看源码时间：

```powershell
Get-ChildItem -Path .\lib -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 10 FullName,LastWriteTime
```

查看 build 时间：

```powershell
Get-ChildItem -Path .\build\windows -Recurse -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 20 FullName,LastWriteTime
```

## 通过标准

只有满足以下条件，才可把 running UI 结果写成通过：

```text
running_ui_verified_latest = true
old_build_not_used = true
owner_visible_ui_tested = true
source_or_data_origin_known = true
backend_oracle_matched = true
restart_recovery_checked = true
```

无法证明当前窗口是最新实例时，结论只能是：

```text
running_ui_provenance_unconfirmed
```
