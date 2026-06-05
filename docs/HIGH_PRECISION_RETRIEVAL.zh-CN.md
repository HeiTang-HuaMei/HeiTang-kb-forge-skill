# 高精度检索

v1.7 新增可选本地检索索引，用于已有知识包。

```powershell
python -m heitang_kb_forge.cli build-retrieval-index --package .\output --output .\retrieval_output
```

输出：

* retrieval_index.jsonl
* retrieval_manifest.json
* context_pack.json
* context_pack.md
* retrieval_trace.json

该索引是 provider-neutral 中间层，不生成 embedding，也不写入向量数据库。
