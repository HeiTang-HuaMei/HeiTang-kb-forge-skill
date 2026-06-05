# High Precision Retrieval

v1.7 adds an opt-in local retrieval index for generated knowledge packages.

```powershell
python -m heitang_kb_forge.cli build-retrieval-index --package .\output --output .\retrieval_output
```

Outputs:

* retrieval_index.jsonl
* retrieval_manifest.json
* context_pack.json
* context_pack.md
* retrieval_trace.json

The index is provider-neutral and does not create embeddings or write to a vector database.
