# 发布检查清单

当前项目版本：2.5.0-alpha.1

每次打 checkpoint tag 前使用本清单。

## 必要检查

- [ ] pyproject.toml 与 skill.json 版本一致
- [ ] pytest 通过
- [ ] Quickstart build 通过
- [ ] Doctor 通过，如果该命令可用
- [ ] Quality gate 通过
- [ ] Release blockers 已检查
- [ ] Regression 已检查
- [ ] Golden samples 已检查
- [ ] Export certification 已检查
- [ ] Compatibility matrix 已生成
- [ ] Release readiness 已生成
- [ ] 无 tmp 临时目录
- [ ] 无密钥泄露
- [ ] 默认不真实调用外部平台
- [ ] README 能力声明已检查
- [ ] CHANGELOG 已更新
- [ ] Capability Status 已更新
- [ ] Version Matrix 已更新
- [ ] Tag 已规划

## 必要边界

- 真实 LLM API live smoke 通过前，不声明真实 LLM API 支持。
- 不声明小红书官方上传 API 支持。
- 不声明真实 OpenClaw / Codex / Claude Code / MCP runtime 已运行。
- v2.9 实现前，不声明飞书 / 移动端 / 安装端 / iOS 支持。
- v3.x 实现前，不声明 SaaS / 权限系统支持。

## Release Readiness Gate

以下情况必须让 `release_ready=false`：

- 项目版本不一致
- 存在 critical release blocker
- 缺少 Capability Status
- 缺少 Version Matrix
- 缺少 Release Checklist
- README 把 planned 能力写成 completed
- 检测到疑似密钥
- platform export 缺少 mock boundary
