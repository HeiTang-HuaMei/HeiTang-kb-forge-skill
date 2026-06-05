from pathlib import Path
import json


def load_workspace_packages(workspace: Path) -> list[dict]:
    registry = workspace / "package_registry.json"
    if not registry.exists():
        return []
    return json.loads(registry.read_text(encoding="utf-8")).get("packages", [])


def load_package_summary(package: Path) -> dict:
    summary: dict = {"package": str(package), "exists": package.exists()}
    if not package.exists():
        return summary
    for file_name in [
        "manifest.json",
        "quality_report.json",
        "contract_check_result.json",
        "multimodal_evidence_map.json",
        "package_diff.json",
        "lifecycle_manifest.json",
        "conflict_report.json",
        "staleness_report.json",
        "retrieval_manifest.json",
        "retrieval_trace.json",
        "evidence_gate_result.json",
        "llm_evidence_validation.json",
        "llm_boundary_judgment.json",
        "llm_hallucination_check.json",
    ]:
        path = package / file_name
        if path.exists():
            summary[file_name] = json.loads(path.read_text(encoding="utf-8"))
    progress_path = package / "progress_events.jsonl"
    if progress_path.exists():
        summary["progress_event_count"] = len(progress_path.read_text(encoding="utf-8").splitlines())
    assets_path = package / "multimodal_assets.jsonl"
    if assets_path.exists():
        assets = [json.loads(line) for line in assets_path.read_text(encoding="utf-8").splitlines() if line.strip()]
        summary["multimodal_asset_count"] = len(assets)
        summary["review_required_assets"] = [asset for asset in assets if asset.get("review_required")]
    report_path = package / "multimodal_report.md"
    if report_path.exists():
        summary["multimodal_report"] = report_path.read_text(encoding="utf-8")
    contract_report = package / "contract_check_report.md"
    if contract_report.exists():
        summary["contract_check_report"] = contract_report.read_text(encoding="utf-8")
    for report_name in [
        "governance_report.md",
        "review_queue_report.md",
        "context_pack.md",
        "evidence_gate_report.md",
        "llm_evidence_validation_report.md",
    ]:
        report = package / report_name
        if report.exists():
            summary[report_name] = report.read_text(encoding="utf-8")
    return summary


def render_app() -> None:
    try:
        import streamlit as st
    except ImportError as exc:
        raise RuntimeError('Web UI dependencies are not installed. Install with: pip install -e ".[web]"') from exc

    st.title("Knowledge Package Builder UI v1")
    st.caption("HeiTang KB Forge Skill presentation layer")
    workspace_path = Path(st.text_input("Workspace path", "./workspace"))
    packages = load_workspace_packages(workspace_path)
    st.subheader("Knowledge Packages")
    st.write(packages)
    input_path = st.text_input("Input path", "./examples/input")
    output_path = st.text_input("Output path", "./examples/output")
    package_path = Path(st.text_input("Package result path", "./examples/output"))
    query = st.text_input("Ask query", "What is this knowledge package about?")
    st.subheader("Ops Views")
    st.write(
        [
            "Package detail",
            "Version diff",
            "Quality report",
            "Risk labels",
            "Review queue",
            "Refresh plan",
            "Publish profile",
            "Ask runtime",
            "Knowledge governance",
            "Retrieval trace",
            "Evidence gate",
            "LLM evidence validation",
        ]
    )
    st.write("Build, review, publish, refresh, and ask actions use local CLI/Python logic only.")
    st.write({"input": input_path, "output": output_path, "query": query})
    st.subheader("Knowledge Package Result")
    package_summary = load_package_summary(package_path)
    st.write(package_summary)
    if package_summary.get("multimodal_report"):
        st.subheader("Multimodal Report")
        st.markdown(package_summary["multimodal_report"])
    if package_summary.get("contract_check_report"):
        st.subheader("Contract Check Report")
        st.markdown(package_summary["contract_check_report"])
    for title, key in [
        ("Knowledge Governance", "governance_report.md"),
        ("Review Queue", "review_queue_report.md"),
        ("Context Pack", "context_pack.md"),
        ("Evidence Gate", "evidence_gate_report.md"),
        ("LLM Evidence Validation", "llm_evidence_validation_report.md"),
    ]:
        if package_summary.get(key):
            st.subheader(title)
            st.markdown(package_summary[key])


if __name__ == "__main__":
    render_app()
