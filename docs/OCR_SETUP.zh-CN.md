# OCR 设置

OCR 是可选能力。Markdown、TXT、文本型 PDF、DOCX、CSV、TSV、XLSX 不需要 OCR extra。

安装 OCR extra：

```powershell
python -m pip install -e ".[ocr]"
```

本机还可能需要安装 Tesseract OCR，并把安装目录加入 PATH。

验证：

```powershell
tesseract --version
tesseract --list-langs
```

中文 OCR 需要 `chi_sim.traineddata`。

大文件 OCR 建议：

```powershell
heitang-kb-forge build --input .\input --output .\output --progress-jsonl --profile fast --ocr-mode first-pages --max-ocr-pages 10 --ocr-cache --resume
```
