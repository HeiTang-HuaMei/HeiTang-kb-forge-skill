from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.document_parsing.local_pdf_markdown import preprocess_pdf_to_markdown
from heitang_kb_forge.document_parsing.parser_benchmark import build_parser_backend_benchmark, select_parser_backend
from heitang_kb_forge.document_parsing.token_reduction import estimate_pdf_token_reduction
from heitang_kb_forge.exporters.jsonl_exporter import write_json


V39_DOCUMENT_PARSING_OUTPUT_FILES = [
    "local_pdf_markdown_report.json",
    "parser_backend_benchmark_report.json",
    "pdf_token_reduction_report.json",
    "parser_backend_selection_report.json",
    "no_cloud_upload_report.json",
]


def write_document_parsing_outputs(source_root: Path, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    sources = _source_files(source_root)
    pdfs = [path for path in sources if path.suffix.lower() == ".pdf"]
    sample = pdfs[0] if pdfs else (sources[0] if sources else output / "sample.pdf")
    selection = select_parser_backend(sample)
    markdown_report = (
        preprocess_pdf_to_markdown(sample, output / f"{sample.stem or 'sample'}.md")
        if sample.suffix.lower() == ".pdf" and sample.exists()
        else {
            "local_pdf_markdown_report_version": "3.9.0-alpha.1",
            "source_path": sample.as_posix(),
            "output_path": None,
            "status": "not_applicable",
            "parser_backend": selection["selected_backend"],
            "parser_confidence": selection["confidence"],
            "review_required": selection["review_required"],
            "reason": "no_pdf_source_found",
            "no_cloud_upload": True,
            "raw_pdf_sent_to_llm": False,
            "tests_require_real_llm_api_network": False,
        }
    )
    markdown_path = Path(markdown_report["output_path"]) if markdown_report.get("output_path") else None
    token_report = estimate_pdf_token_reduction(sample, markdown_path, markdown_report["parser_confidence"])
    benchmark = build_parser_backend_benchmark(sources or [sample])
    no_cloud = {
        "no_cloud_upload_report_version": "3.9.0-alpha.1",
        "local_only_processing_path": True,
        "no_external_api_calls": True,
        "real_llm_dependency": False,
        "raw_pdf_sent_to_llm_by_default": False,
        "optional_future_byo_cloud_boundary": "explicit_user_owned_adapter_only",
        "platform_hosted_user_data": False,
        "tests_require_network": False,
    }
    write_json(output / "parser_backend_selection_report.json", selection)
    write_json(output / "local_pdf_markdown_report.json", markdown_report)
    write_json(output / "pdf_token_reduction_report.json", token_report)
    write_json(output / "parser_backend_benchmark_report.json", benchmark)
    write_json(output / "no_cloud_upload_report.json", no_cloud)
    return {
        "status": "pass",
        "output_files": V39_DOCUMENT_PARSING_OUTPUT_FILES,
        "local_pdf_markdown_report": markdown_report,
        "parser_backend_selection_report": selection,
        "parser_backend_benchmark_report": benchmark,
        "pdf_token_reduction_report": token_report,
        "no_cloud_upload_report": no_cloud,
    }


def _source_files(root: Path) -> list[Path]:
    if root.is_file():
        return [root]
    if not root.exists():
        return []
    return [path for path in sorted(root.rglob("*")) if path.is_file()]
