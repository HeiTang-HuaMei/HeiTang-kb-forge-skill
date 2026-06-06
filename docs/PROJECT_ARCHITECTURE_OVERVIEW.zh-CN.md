# 项目架构概览

## 架构分层

```text
[1] 资料接入层
    PDF / DOCX / Markdown / TXT / CSV / XLSX / 图片

[2] 知识资产包层
    chunks / cards / QA / glossary / manifest

[3] 质量与证据层
    quality gate / evidence gate / release blockers / regression

[4] Provider 治理层
    provider registry / security audit / redaction / fallback / cost guard

[5] 导出层
    Agent package / Skill package / platform export / mock publishing

[6] Demo-E2E 层
    portfolio report / evidence pack / runtime limitations
```

## 为什么默认离线重要

这个工具会处理知识资产和 Provider 配置。默认离线可以避免误联网、API key 泄露，以�
��把 mock 能力包装成真实平台运行。

## 真实 LLM 放在哪里

真实 LLM 是可选能力。Provider 治理层负责 env-only key、日志脱敏、fallback、cost guard 和显式 live smoke。

## demo-e2e 的作用

demo-e2e 用来证明项目可以不依赖外部服务，跑通一条本地作品集闭环。
