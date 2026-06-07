from __future__ import annotations

import json
from pathlib import Path

from heitang_kb_forge.audit.architecture_gap import architecture_gap_audit_report
from heitang_kb_forge.audit.capability_gap import capability_gap_map
from heitang_kb_forge.audit.external_benchmark import external_project_benchmark_report
from heitang_kb_forge.audit.fusion_plan import external_fusion_plan


REPORT_FILES = {
    "architecture_gap_audit_report.json": architecture_gap_audit_report,
    "external_project_benchmark_report.json": external_project_benchmark_report,
    "capability_gap_map.json": capability_gap_map,
    "external_fusion_plan.json": external_fusion_plan,
}

DOC_FILES = {
    "docs/ARCHITECTURE_GAP_AUDIT.md": lambda: _architecture_doc("en"),
    "docs/ARCHITECTURE_GAP_AUDIT.zh-CN.md": lambda: _architecture_doc("zh"),
    "docs/EXTERNAL_PROJECT_BENCHMARK.md": lambda: _benchmark_doc("en"),
    "docs/EXTERNAL_PROJECT_BENCHMARK.zh-CN.md": lambda: _benchmark_doc("zh"),
    "docs/CAPABILITY_GAP_MAP.md": lambda: _capability_doc("en"),
    "docs/CAPABILITY_GAP_MAP.zh-CN.md": lambda: _capability_doc("zh"),
    "docs/EXTERNAL_FUSION_PLAN.md": lambda: _fusion_doc("en"),
    "docs/EXTERNAL_FUSION_PLAN.zh-CN.md": lambda: _fusion_doc("zh"),
}


def write_v36_audit_outputs(root: Path) -> list[Path]:
    written = []
    for name, factory in REPORT_FILES.items():
        path = root / name
        path.write_text(json.dumps(factory(), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        written.append(path)
    for name, factory in DOC_FILES.items():
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(factory(), encoding="utf-8")
        written.append(path)
    return written


def _architecture_doc(language: str) -> str:
    audit = architecture_gap_audit_report()
    counts = audit["risk_summary"]
    category_lines = [
        f"- {category['name']}: {category['item_count']} items, P0={category['p0_count']}, P1={category['p1_count']}, P2={category['p2_count']}"
        for category in audit["categories"]
    ]
    p0_lines = [f"- {item['category']} / {item['capability']} -> {item['target_version']}" for item in audit["p0_items"]]
    if language == "zh":
        return "\n".join(
            [
                "# v3.6 架构差距审计",
                "",
                "本审计只记录能力差距、风险和未来版本映射，不实现 v3.7 功能，不修改 UI，也不复制外部项目代码或提示词。",
                "",
                f"- 审计版本: {audit['audit_version']}",
                f"- Core commit: {audit['current_core_commit']}",
                f"- UI commit: {audit['current_ui_commit']}",
                f"- 风险统计: P0={counts['P0']}, P1={counts['P1']}, P2={counts['P2']}",
                "",
                "## 外部检索用于知识准确性验证",
                "",
                "External Retrieval for Knowledge Accuracy Verification 是 S-level 核心差距。它的目的不是无边界收集更多内容，而是验证现有 KB 的准确性、时效性、一致性和证据充分性。v3.7 只定义验证型检索规划，并区分 answer retrieval 与 validation retrieval；v3.8 才实现 claim_check、source_cross_check、freshness_check、contradiction_detection、knowledge_accuracy_score、verification_retrieval_trace 和 claim_verification_report；v4.3 再进入长期治理。",
                "",
                "## 本地文档解析与 PDF Token 降耗",
                "",
                "Raw PDF 不应该默认整包发送给 LLM。产品应优先走 local parsing -> structured Markdown/JSON -> chunking -> retrieval：这样既保护隐私边界，也减少 token 成本。LiteDoc 的价值在于 100% client-side PDF to Markdown 和 no server upload；HeiTang 当前已有本地 PDF/OCR/parser backend 基础，但缺少 LiteDoc-like PDF-to-Markdown 中间产物、parser backend benchmark report 和 token cost reduction report。",
                "",
                "## LLM 可选辅助层",
                "",
                "LLM 必须被视为 optional assistive layer，而不是 required dependency。每个 gap item 都记录 deterministic/local implementation path、optional LLM-assisted enhancement path、offline fallback，以及 tests_require_real_llm_api_network=false。Core 功能必须在没有配置 LLM provider 时仍可用，测试不得依赖真实 LLM/API/网络调用。",
                "",
                "## 类别",
                "",
                *category_lines,
                "",
                "## P0 项",
                "",
                *p0_lines,
                "",
                "完整机器可读结果见 `architecture_gap_audit_report.json`。",
                "",
            ]
        )
    return "\n".join(
        [
            "# v3.6 Architecture Gap Audit",
            "",
            "This audit records capability gaps, risk, and future-version mapping only. It does not implement v3.7 features, modify UI, or copy external project code or prompts.",
            "",
            f"- Audit version: {audit['audit_version']}",
            f"- Core commit: {audit['current_core_commit']}",
            f"- UI commit: {audit['current_ui_commit']}",
            f"- Risk summary: P0={counts['P0']}, P1={counts['P1']}, P2={counts['P2']}",
            "",
            "## External Retrieval for Knowledge Accuracy Verification",
            "",
            "External Retrieval for Knowledge Accuracy Verification is an S-level core gap. Its primary value is not unrestricted information acquisition. It verifies whether the existing KB is accurate, fresh, consistent, and sufficiently evidenced. v3.7 should define verification-oriented retrieval planning and distinguish retrieval for answering from retrieval for validation. v3.8 should implement the first real claim_check, source_cross_check, freshness_check, contradiction_detection, knowledge_accuracy_score, verification_retrieval_trace, and claim_verification_report. v4.3 should extend this into long-term local governance.",
            "",
            "## Local Document Parsing & PDF Token Reduction",
            "",
            "Raw PDF should not be sent wholesale to an LLM by default. The product should prefer local parsing -> structured Markdown/JSON -> chunking -> retrieval. This protects privacy and reduces token cost. LiteDoc is valuable as a 100% client-side PDF-to-Markdown and no-server-upload benchmark. HeiTang already has local PDF/OCR/parser backend foundations, but still lacks a LiteDoc-like PDF-to-Markdown intermediate artifact, parser backend benchmark report, and token cost reduction report.",
            "",
            "## Optional LLM Assistive Layer",
            "",
            "LLM must be treated as an optional assistive layer, not a required dependency. Every gap item records deterministic/local implementation path, optional LLM-assisted enhancement path, offline fallback, and tests_require_real_llm_api_network=false. Core features must remain usable without configured LLM providers, and tests must not depend on real LLM/API/network calls.",
            "",
            "## Categories",
            "",
            *category_lines,
            "",
            "## P0 Items",
            "",
            *p0_lines,
            "",
            "See `architecture_gap_audit_report.json` for the full machine-readable audit.",
            "",
        ]
    )


def _benchmark_doc(language: str) -> str:
    report = external_project_benchmark_report()
    lines = [
        f"- {project['project_name']}: {project['repo_url']} -> {project['recommendation']} ({project['mapped_future_version']})"
        for project in report["projects"]
    ]
    local_pdf_lines = [
        "- LiteDoc: local browser-side PDF to Markdown, privacy-first, token-cost reduction, no server upload.",
        "- PaddleOCR: OCR recognition for scanned PDF / image text extraction.",
        "- MinerU: complex document parsing to Markdown/JSON with layout/table/formula orientation.",
        "- Marker / Docling: optional complex document parser backend strategy comparisons.",
    ]
    if language == "zh":
        title = "# v3.6 外部项目基准"
        intro = "本基准只吸收架构模式，不复制外部代码、提示词、数据集或技能文本。测试不需要网络。"
        local_pdf_heading = "## 本地 PDF 解析与 Token 降耗基准"
    else:
        title = "# v3.6 External Project Benchmark"
        intro = "This benchmark absorbs architecture patterns only. It does not copy external code, prompts, datasets, or skill text. Tests do not require network."
        local_pdf_heading = "## Local PDF Parsing and Token Reduction Benchmark"
    return "\n".join(
        [
            title,
            "",
            intro,
            "",
            f"- Benchmark version: {report['benchmark_version']}",
            f"- Project count: {report['benchmark_summary']['project_count']}",
            f"- Source method: {report['source_method']}",
            "",
            local_pdf_heading,
            "",
            *local_pdf_lines,
            "",
            "## Projects",
            "",
            *lines,
            "",
            "See `external_project_benchmark_report.json` for full fields.",
            "",
        ]
    )


def _capability_doc(language: str) -> str:
    report = capability_gap_map()
    s_lines = [f"- {item}" for item in report["s_level_capabilities"]]
    if language == "zh":
        title = "# v3.6 能力差距图"
        intro = "S-level 外部验证检索能力被标为 P0/P1 差距；本地 PDF 解析与 token 降耗能力被映射到 v3.9/parser hardening track。"
        llm_line = "每个 capability 都包含本地确定性路径、可选 LLM 辅助路径、离线 fallback，并声明 tests_require_real_llm_api_network=false。"
    else:
        title = "# v3.6 Capability Gap Map"
        intro = "S-level external verification retrieval capabilities are marked as P0/P1 gaps. Local PDF parsing and token reduction capabilities are mapped to v3.9/parser hardening track."
        llm_line = "Every capability includes a deterministic local path, optional LLM-assisted path, offline fallback, and tests_require_real_llm_api_network=false."
    return "\n".join(
        [
            title,
            "",
            intro,
            llm_line,
            "",
            f"- Capability count: {len(report['capabilities'])}",
            "- Network required for tests: false",
            "",
            "## S-level Verification Capabilities",
            "",
            *s_lines,
            "",
            "See `capability_gap_map.json` for the full map.",
            "",
        ]
    )


def _fusion_doc(language: str) -> str:
    plan = external_fusion_plan()
    safe = [f"- {item['pattern']} -> {item['target_version']}" for item in plan["safe_patterns_to_absorb"]]
    rejected = [f"- {item}" for item in plan["patterns_to_reject"]]
    if language == "zh":
        title = "# v3.6 外部模式融合计划"
        intro = "安全吸收原则：不要盲目把外部网页结果导入 KB；先用外部来源验证 claim；只有经过 review / trust policy 后才能提升为新知识。用户 PDF 不默认上传云端，也不默认整包送 LLM，应先本地解析成 Markdown/JSON。"
    else:
        title = "# v3.6 External Fusion Plan"
        intro = "Safe absorption principle: do not blindly import external web results into the KB. Use external sources to validate claims first. Promote new information only after review and trust policy approval. User PDFs should not be uploaded to cloud by default or sent wholesale to an LLM; parse locally into Markdown/JSON first."
    return "\n".join(
        [
            title,
            "",
            intro,
            "",
            "## Safe Patterns",
            "",
            *safe,
            "",
            "## Rejected Patterns",
            "",
            *rejected,
            "",
            "See `external_fusion_plan.json` for full details.",
            "",
        ]
    )
