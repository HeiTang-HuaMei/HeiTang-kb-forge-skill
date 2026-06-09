# 外部项目加入政策

外部 GitHub 项目可以先以 registry、benchmark、template、planned_adapter、future_adapter、provider_required 或 capability_anchor 合同进入 HeiTang KB Forge。

加入合同不代表项目已经安装、ready、available、可执行或被打包。

## 规则

- 合同加入不复制外部项目代码。
- 合同加入不新增外部依赖。
- 合同加入不调用 provider API。
- 不提交 API key、token、本地 provider profile 或 raw private input。
- provider、network、secret、external runtime 需求必须保持 blocked，直到 post-v4 有显式用户配置和实现证据。
- planned_adapter 和 future_adapter 必须保持 not ready。
- needs_verification 项不得变成 executable action。
- template_reference 项只能作为场景或模板参考出现。
- 合同加入不得改变 P1 gate、启动 v4.0、创建 tag 或写 release。
