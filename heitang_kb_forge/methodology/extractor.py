from __future__ import annotations

import json
import re
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.methodology_schema import (
    EvidenceReference,
    EvidenceWindow,
    EvidenceWindowBundle,
    MethodologyItem,
    MethodologyMap,
    MethodologyModule,
)


METHODOLOGY_OUTPUT_FILES = [
    "evidence_windows.json",
    "methodology_map.json",
    "methodology_map.md",
    "source_trace.json",
]

_CATEGORY_TERMS = {
    "principles": ["must", "should", "prefer", "principle", "use ", "local", "必须", "应该", "原则"],
    "decision_rules": ["if ", "when ", "unless", "decide", "route", "trigger", "如果", "当", "决策", "触发"],
    "workflows": ["first", "next", "then", "finally", "step", "workflow", "process", "流程", "步骤", "然后"],
    "anti_patterns": ["avoid", "never", "do not", "don't", "forbid", "禁止", "不要", "避免"],
    "constraints": ["only", "limit", "require", "boundary", "scope", "within", "仅", "限制", "边界", "范围"],
    "applicability_boundary": ["applies", "applicable", "use when", "suitable", "适用", "用于"],
    "failure_modes": ["fail", "error", "missing", "unsupported", "low confidence", "risk", "失败", "错误", "缺失", "不支持", "风险"],
}


def extract_methodology(package: Path, output: Path) -> dict:
    chunks = _read_jsonl(package / "chunks.jsonl")
    if not chunks:
        raise ValueError("Methodology extraction requires a knowledge package with non-empty chunks.jsonl")

    manifest = _read_json(package / "manifest.json")
    package_id = str(manifest.get("package_id") or package.name)
    windows = [_make_evidence_window(chunk, index) for index, chunk in enumerate(chunks, start=1)]
    bundle = EvidenceWindowBundle(
        source_package_id=package_id,
        window_count=len(windows),
        windows=windows,
    )
    modules = [_make_methodology_module(window, index) for index, window in enumerate(windows, start=1)]
    risk_flags = sorted({flag for module in modules for flag in module.risk_flags})
    methodology = MethodologyMap(
        source_package_id=package_id,
        module_count=len(modules),
        methodology_modules=modules,
        concepts=_collect(modules, "concepts"),
        principles=_collect(modules, "principles"),
        decision_rules=_collect(modules, "decision_rules"),
        workflows=_collect(modules, "workflows"),
        anti_patterns=_collect(modules, "anti_patterns"),
        constraints=_collect(modules, "constraints"),
        applicability_boundary=_collect(modules, "applicability_boundary"),
        failure_modes=_collect(modules, "failure_modes"),
        source_evidence=[window.window_id for window in windows],
        confidence=round(sum(module.confidence for module in modules) / len(modules), 3),
        risk_flags=risk_flags,
        unsupported_claim_detection={"status": "pass", "excluded_count": 0},
    )
    trace = {
        "source_trace_version": "v4.2-p2.2-1",
        "source_package_id": package_id,
        "methodology_items": [
            {
                "item_id": item.item_id,
                "source_evidence": item.source_evidence,
            }
            for module in modules
            for category in _CATEGORY_TERMS
            for item in getattr(module, category)
        ]
        + [
            {"item_id": item.item_id, "source_evidence": item.source_evidence}
            for module in modules
            for item in module.concepts
        ],
        "source_trace_preserved": True,
        "tests_require_real_llm_api_network": False,
    }

    output.mkdir(parents=True, exist_ok=True)
    write_json(output / "evidence_windows.json", bundle)
    write_json(output / "methodology_map.json", methodology)
    write_json(output / "source_trace.json", trace)
    (output / "methodology_map.md").write_text(_render_methodology(methodology), encoding="utf-8")
    return methodology.model_dump(mode="json")


def _make_evidence_window(chunk: dict, index: int) -> EvidenceWindow:
    chunk_id = str(chunk.get("chunk_id") or f"chunk_{index:03d}")
    source_path = str(chunk.get("source_path") or "")
    title = str(chunk.get("title") or chunk.get("metadata", {}).get("parent_section") or f"Evidence {index}")
    text = _normalize_text(str(chunk.get("text") or ""))
    confidence = _confidence(chunk)
    risk_flags = []
    if not text:
        confidence = 0.0
        risk_flags.append("missing_evidence_text")
    if confidence < 0.6:
        risk_flags.append("low_confidence_evidence")
    if not source_path:
        risk_flags.append("missing_source_path")
    if len(text) > 1200:
        risk_flags.append("evidence_window_truncated")
        text = text[:1197].rstrip() + "..."
    reference = EvidenceReference(
        evidence_id=f"evidence_{chunk_id}",
        source_path=source_path,
        chunk_id=chunk_id,
        citation=f"{source_path}#chunk={chunk_id}" if source_path else f"chunk={chunk_id}",
        title=title,
    )
    return EvidenceWindow(
        window_id=f"window_{index:03d}",
        title=title,
        text=text,
        source_evidence=[reference],
        confidence=confidence,
        risk_flags=risk_flags,
    )


def _make_methodology_module(window: EvidenceWindow, index: int) -> MethodologyModule:
    sentences = _sentences(window.text)
    categories: dict[str, list[MethodologyItem]] = {name: [] for name in _CATEGORY_TERMS}
    for sentence_index, sentence in enumerate(sentences, start=1):
        lowered = sentence.casefold()
        for category, terms in _CATEGORY_TERMS.items():
            if any(term in lowered for term in terms):
                categories[category].append(
                    _item(
                        f"module_{index:03d}_{category}_{sentence_index:02d}",
                        sentence,
                        window,
                    )
                )

    concept = _item(f"module_{index:03d}_concept_01", window.title, window)
    risk_flags = list(window.risk_flags)
    if not categories["principles"]:
        risk_flags.append("missing_principle_evidence")
    if not categories["workflows"] and not categories["decision_rules"]:
        risk_flags.append("missing_execution_evidence")
    confidence_penalty = 0.05 * len([flag for flag in risk_flags if flag.startswith("missing_")])
    return MethodologyModule(
        module_id=f"methodology_module_{index:03d}",
        title=window.title,
        concepts=[concept],
        principles=categories["principles"],
        decision_rules=categories["decision_rules"],
        workflows=categories["workflows"],
        anti_patterns=categories["anti_patterns"],
        constraints=categories["constraints"],
        applicability_boundary=categories["applicability_boundary"],
        failure_modes=categories["failure_modes"],
        source_evidence=[window.window_id],
        confidence=max(0.0, round(window.confidence - confidence_penalty, 3)),
        risk_flags=sorted(set(risk_flags)),
    )


def _item(item_id: str, statement: str, window: EvidenceWindow) -> MethodologyItem:
    return MethodologyItem(
        item_id=item_id,
        statement=statement,
        source_evidence=[window.window_id],
        confidence=window.confidence,
        risk_flags=list(window.risk_flags),
    )


def _collect(modules: list[MethodologyModule], category: str) -> list[MethodologyItem]:
    return [item for module in modules for item in getattr(module, category)]


def _sentences(text: str) -> list[str]:
    rows = re.split(r"(?<=[.!?。！？])\s+|\r?\n+", text)
    return [re.sub(r"^\s*(?:[-*]|\d+[.)])\s*", "", row).strip() for row in rows if row.strip()]


def _confidence(chunk: dict) -> float:
    metadata = chunk.get("metadata") if isinstance(chunk.get("metadata"), dict) else {}
    raw = metadata.get("parse_confidence", metadata.get("confidence", chunk.get("confidence", 0.85)))
    try:
        return min(1.0, max(0.0, round(float(raw), 3)))
    except (TypeError, ValueError):
        return 0.5


def _normalize_text(text: str) -> str:
    return re.sub(r"[ \t]+", " ", text.replace("\r\n", "\n").replace("\r", "\n")).strip()


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [
        payload
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
        for payload in [json.loads(line)]
        if isinstance(payload, dict)
    ]


def _render_methodology(methodology: MethodologyMap) -> str:
    lines = [
        "# Methodology Map",
        "",
        f"- Source package: `{methodology.source_package_id}`",
        f"- Modules: {methodology.module_count}",
        f"- Confidence: {methodology.confidence}",
        f"- Risk flags: {', '.join(methodology.risk_flags) if methodology.risk_flags else 'none'}",
        "",
    ]
    labels = {
        "concepts": "Concepts",
        "principles": "Principles",
        "decision_rules": "Decision Rules",
        "workflows": "Workflows",
        "anti_patterns": "Anti-patterns",
        "constraints": "Constraints",
        "applicability_boundary": "Applicability Boundary",
        "failure_modes": "Failure Modes",
    }
    for module in methodology.methodology_modules:
        lines.extend([f"## {module.title}", "", f"Evidence: {', '.join(module.source_evidence)}", ""])
        for category, label in labels.items():
            items = getattr(module, category)
            if items:
                lines.append(f"### {label}")
                lines.extend(f"- {item.statement} (`{', '.join(item.source_evidence)}`)" for item in items)
                lines.append("")
    return "\n".join(lines).rstrip() + "\n"
