# Provider Registry

v1.9 新增 provider registry，用于管理 mock、openai-compatible 和 local provider 元数据。

registry 只保存 `api_key_env`，不会写入真实 API key。
