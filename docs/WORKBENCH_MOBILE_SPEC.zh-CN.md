# HeiTang Knowledge Workbench 移动端规格

状态：响应式 Web 与 PWA-ready 原型，并为 Windows、Web、Android、iOS 提供 Flutter 平台 scaffold。

## 移动端策略

- 移动端与桌面端使用同一套工作台信息架构。
- 桌面侧边栏在移动端折叠为页面选择器。
- 窄屏下卡片使用单列布局。
- 表格在移动端允许横向滚动，避免隐藏契约字段。
- 顶部保留主题和语言切换控件。
- Flutter 手机布局通过桌面导航栏切换为页面选择器实现自适应，而不是简单缩放桌面布局。

## 断点

- `980px`：必要时将多列卡片折叠为更宽的行。
- `760px`：隐藏侧边栏，显示移动导航，缩小内容间距，页面使用单列布局。
- `480px`：收紧小屏手机上的标题和指标字号。

## 布局规则

- 最小视口宽度：`320px`。
- 不出现超过视口的固定宽度内容。
- 卡片、按钮、文本域、输入框和选择器使用响应式宽度。
- 导航无需横向滚动即可访问。
- 卡片和按钮内文字必须正常换行。

## PWA 与平台就绪性

- `index.html` 包含 viewport 和 theme-color 元数据。
- 静态 Web 包含 `web/workbench/manifest.webmanifest`。
- Flutter Web 包含 `web/workbench/flutter_app/web/manifest.json`。
- Windows 桌面 scaffold 位于 `web/workbench/flutter_app/windows/`。
- Android target scaffold 位于 `web/workbench/flutter_app/android/`。
- iOS target scaffold 位于 `web/workbench/flutter_app/ios/`。
- 原型不耦合后端，因此未来 service worker 可缓存 shell 文件和 mock/API 响应。
- 本阶段不添加 service worker，因为离线行为和安装提示保留到后续集成。

## 移动端页面覆盖

所有工作台页面必须可通过移动端选择器访问：

1. 仪表盘
2. 文件上传
3. 任务进度
4. 知识库列表
5. 知识库详情
6. 复核队列
7. 校正文稿编辑器
8. 知识库查询
9. 文档生成
10. Agent / Skill 管理
11. 多 Agent 工作流
12. 记忆范围查看器
13. 设置
14. 导出中心

## 验证

移动端冒烟测试应验证：

- 存在 viewport meta。
- 存在移动导航。
- 移动断点下隐藏侧边栏。
- 内容网格折叠为单列。
- CSS 包含必要断点。
- Flutter scaffold 声明手机、平板和桌面布局分支。
- Web/PWA 与 Windows/Android/iOS target scaffold 文件存在。
