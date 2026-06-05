# LLM Provider Adapter

v1.7 新增最小 LLM provider adapter，用于证据校验流程。

支持模式：

* mock
* openai_compatible placeholder

mock provider 是确定性的，用于本地测试。OpenAI-compatible adapter 在测试中不发起网络调用，需要显式配置。

API key 不会写入输出文件、报告或调用日志。
