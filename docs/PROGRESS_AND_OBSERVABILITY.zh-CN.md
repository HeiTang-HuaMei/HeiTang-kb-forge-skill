# 进度与可观测性

v1.6.2 增加 opt-in progress events，用于本地工业化任务。

```powershell
heitang-kb-forge build --input .\input --output .\output --progress --progress-jsonl
heitang-kb-forge batch --input .\input --output .\output --progress-jsonl
heitang-kb-forge pipeline --config .\examples\configs\kb_forge.build.yaml --progress-jsonl
```

`--progress-jsonl` 会在输出目录写出 `progress_events.jsonl`。

该文件用于查看 source scan、parser、PDF preflight、OCR page、OCR cache、clean、chunk、asset build、quality、performance report、batch item 和 done 等阶段。

进度层只负责可观测性，不替代 CLI、config、pipeline，也不改变标准输出契约。
