# 多模态知识资产

v1.6 增加 opt-in 多模态资产保留能力，用于真实资料文件夹。

## 目标

多模态资产用于避免图片、图表、流程图、思维导图、公式、slide 等内容在无法可靠转成文本时被静默丢失。

## 启用

```powershell
heitang-kb-forge build --input .\input --output .\output --multimodal
```

## 输出

- `multimodal_assets.jsonl`
- `multimodal_evidence_map.json`
- `multimodal_report.md`
- 成功抽取 slide 文本时生成 `slide_chunks.jsonl`

## 人工复核

fallback 或低置信资产会标记：

```json
{
  "confidence": "low",
  "extraction_method": "fallback",
  "review_required": true
}
```

best-effort asset 是可复核证据，不是模型断言的事实。
