# 配置规格

## 目的

本文件定义配置页和配置存储的范围。配置是增强能力入口，不是本地基础链路的阻断器。

## 配置分类

配置页只展示：

- AI 模型接口。
- Embedding 接口。
- Redis 记忆库。
- 向量数据库。
- 文档解析能力。
- 外部服务连接。
- 导出位置。

## 配置状态

用户可见状态只能使用：

- 已可用
- 已连接
- 已配置，待测试
- 未配置
- 测试失败
- 可选，未安装
- 需要处理

## AI 模型接口

字段：

- provider_display_name
- endpoint
- model_name
- configured
- last_test_status
- last_test_time

不得保存 API key 明文。

## Embedding 接口

字段：

- endpoint
- model_name
- dimension 可选
- configured
- last_test_status

未配置时，基础导入和基础知识库流程不得整体阻塞。

## Redis 记忆库

字段：

- host 或脱敏连接摘要
- port
- database 可选
- configured
- last_test_status

Redis 是记忆增强项，不是普通资料导入前置条件。

## 向量数据库

字段：

- type_display_name
- endpoint 或本地路径摘要
- collection_name
- configured
- last_test_status

向量库未配置时，可使用本地基础索引或明确显示增强不可用。

## 文档解析能力

用户表达：

- 基础解析：已可用
- 高级解析：可选安装 / 已安装
- OCR：可选安装 / 已安装
- 操作：测试文档解析

不得显示 OCR Provider、Parser Matrix 等内部表达。

## 外部服务连接

字段：

- display_name
- configured
- last_test_status
- scope
- last_error_user_message

不得显示底层项目名，除非在高级诊断或审计报告。

## 导出位置

字段：

- default_export_dir
- last_export_dir
- writable_status

导出失败必须提供：

- 重新选择位置。
- 打开所在文件夹。
- 查看操作记录。

## 配置存储

配置文件不得保存密钥明文。

推荐保存：

- 配置是否存在。
- 脱敏 endpoint。
- 最近测试结果。
- 用户可见错误。

## 配置验收

必须验证：

- 清空配置后本地导入、整理、基础 KB、成果管理可用。
- 错误配置不导致 UI 崩溃。
- 测试失败有下一步。
- 不泄露密钥。
