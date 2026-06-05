# Release Blockers

v2.5 检测发布阻塞项，例如必要文件缺失、本地检查失败、不安全的平台能力声明、mock 边界缺失、疑似密钥和危险命令片段。

critical blocker 会让 `release_ready=false`。

小红书必须说明不是官方上传 API。MCP 必须保持 stub-only。OpenClaw、Codex 和 Claude Code 不能被描述成 v2.5 已真实运行的 runtime。

