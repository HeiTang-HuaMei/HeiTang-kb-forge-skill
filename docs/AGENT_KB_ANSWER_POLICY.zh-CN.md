# Agent 与知识库回答策略

## 1. 设计结论

HeiTang Knowledge Workbench 中，知识库不是 Agent 的全部大脑，而是 Agent 的可信资料层。

Agent 的回答策略不能只固定成一种模式。不同场景需要不同约束。

系统应支持以下回答策略：

```yaml
answer_policy: strict_grounded | knowledge_first | creative_grounded | open
```

默认策略建议：

```yaml
answer_policy: knowledge_first
require_citation_for_domain_facts: true
allow_external_knowledge: true
disclose_external_knowledge: true
refuse_when_no_evidence: configurable
```

## 2. Agent、知识库、大模型的关系

### Agent

Agent 负责：

- 理解用户问题。
- 判断是否需要检索知识库。
- 调用检索工具。
- 筛选证据。
- 判断能否回答。
- 组织回答。
- 引用来源。
- 拒答不确定内容。
- 调用文件生成、Skill 生成等工具。

### 知识库

知识库负责：

- 提供可信事实。
- 提供来源证据。
- 提供业务边界。
- 提供可追踪材料。
- 降低模型幻觉风险。

### 大模型

大模型负责：

- 理解问题。
- 归纳总结。
- 格式化回答。
- 生成文档。
- 生成方案。
- 在允许时补充通用知识。

## 3. 四种回答策略

### 3.1 strict_grounded

严格知识库模式。

适合：

- 企业制度问答。
- 教材知识库。
- 客服知识库。
- 法律、医疗、财务、合规类内容。
- 出版社图书知识服务。

规则：

- Agent 只能基于知识库和可追踪证据回答。
- 知识库没有证据时必须拒答。
- 不允许用模型常识补答案。
- 回答必须带来源引用。

示例配置：

```yaml
answer_policy: strict_grounded
allow_external_knowledge: false
require_citation_for_domain_facts: true
refuse_when_no_evidence: true
```

### 3.2 knowledge_first

知识库优先模式。

适合：

- 产品经理资料库。
- 学习助手。
- 企业内部知识助手。
- 个人知识库。
- 内容运营资料库。

规则：

- Agent 先检索知识库。
- 如果知识库有内容，优先基于知识库回答。
- 如果知识库没有内容，可以用通用模型能力补充。
- 模型补充内容必须明确标注“非知识库来源”。

示例配置：

```yaml
answer_policy: knowledge_first
allow_external_knowledge: true
require_citation_for_domain_facts: true
disclose_external_knowledge: true
refuse_when_no_evidence: false
```

### 3.3 creative_grounded

知识库素材创作模式。

适合：

- PPT。
- 报告。
- 文章。
- 方案。
- 课程讲义。
- 营销内容。

规则：

- 知识库作为素材和事实边界。
- 大模型可以改写、总结、扩写、组织结构。
- 涉及知识库事实时必须保留来源依据。
- 创作性表达可以不逐句引用，但事实点必须可追溯。

示例配置：

```yaml
answer_policy: creative_grounded
allow_external_knowledge: true
require_citation_for_domain_facts: true
allow_style_generation: true
```

### 3.4 open

开放助手模式。

适合：

- 头脑风暴。
- 通用咨询。
- 创意发散。
- 非事实型任务。

规则：

- 知识库只是参考材料。
- Agent 可以使用通用模型能力自由生成。
- 如果用户明确询问知识库事实，仍然优先知识库。
- 如果知识库与模型常识冲突，必须提示冲突。

示例配置：

```yaml
answer_policy: open
allow_external_knowledge: true
require_citation_for_domain_facts: false
refuse_when_no_evidence: false
```

## 4. 默认策略

Workbench 默认应采用：

```yaml
answer_policy: knowledge_first
```

原因：

- 不浪费大模型通用能力。
- 又能保证领域事实优先来自知识库。
- 能区分“知识库依据”和“模型补充”。
- 适合大多数个人、企业、内容和产品资料库场景。

## 5. 高风险场景策略

以下场景必须使用 strict_grounded：

- 合规制度。
- 法律条款。
- 医疗知识。
- 财务规则。
- 教材标准答案。
- 客服承诺。
- 企业内部流程。
- 出版社图书原文问答。

## 6. Agent 生成时的要求

生成 Knowledge-Bound Agent / Skill 时，必须写入：

```json
{
  "answer_policy": "knowledge_first",
  "knowledge_base_required": true,
  "require_citation_for_domain_facts": true,
  "allow_external_knowledge": true,
  "disclose_external_knowledge": true,
  "refuse_when_no_evidence": false
}
```

如果是 strict_grounded，则必须写入：

```json
{
  "answer_policy": "strict_grounded",
  "knowledge_base_required": true,
  "require_citation_for_domain_facts": true,
  "allow_external_knowledge": false,
  "refuse_when_no_evidence": true
}
```

## 7. 回答格式要求

### strict_grounded 回答格式

```text
根据当前知识库，可以确认：

...

来源：
- source_id / document / chunk_id

当前知识库未覆盖的部分：
...
```

### knowledge_first 回答格式

```text
知识库内结论：

...

来源：
- source_id / document / chunk_id

模型补充判断：
以下内容不是来自当前知识库，仅作为通用参考：
...
```

### creative_grounded 回答格式

```text
基于知识库素材生成：

...

引用依据：
- source_id / document / chunk_id

创作性补充：
...
```

## 8. Release Gate 要求

未来 release-readiness 应检查：

- Agent / Skill 是否声明 answer_policy。
- strict_grounded 是否禁止 external knowledge。
- domain facts 是否要求 citation。
- 是否存在 no-evidence refusal 策略。
- 是否存在 external knowledge disclosure。
- 是否存在 answer_policy 测试用例。

## 9. 版本落地位置

### v2.9 Knowledge Runtime Loop

实现：

- kb-answer --answer-policy。
- citation required mode。
- low-confidence refusal。
- external knowledge disclosure。

### v3.1 Knowledge-Bound Agent / Skill Factory

实现：

- Agent / Skill answer_policy 写入。
- evidence policy binding。
- refusal policy binding。
- answer policy smoke test。

### v3.2 Skill Reverse & Fusion

实现：

- 外部 Skill answer_policy 检测。
- 不安全回答策略风险标注。
- fused skill answer_policy 重写。
