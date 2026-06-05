from pathlib import Path
import json


def load_workspace_packages(workspace: Path) -> list[dict]:
    registry = workspace / "package_registry.json"
    if not registry.exists():
        return []
    return json.loads(registry.read_text(encoding="utf-8")).get("packages", [])


def load_workspace_summary(workspace: Path) -> dict:
    summary: dict = {"workspace": str(workspace), "exists": workspace.exists()}
    if not workspace.exists():
        return summary
    for name in [
        "workspace_manifest.json",
        "registries/relationship_graph.json",
        "registries/provider_registry.json",
        "registries/prompt_profile_registry.json",
        "reports/workspace_health_result.json",
        "stable_check_result.json",
        "provider_health_result.json",
        "reliability_score.json",
        "studio_run_manifest.json",
    ]:
        path = workspace / name
        if path.exists():
            summary[name] = json.loads(path.read_text(encoding="utf-8"))
    for name in ["package_registry.jsonl", "skill_registry.jsonl", "agent_registry.jsonl", "llm_call_audit.jsonl"]:
        path = workspace / "registries" / name
        if path.exists():
            summary[name] = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    for report_name in [
        "reports/workspace_health_report.md",
        "stable_check_report.md",
        "provider_health_report.md",
        "reliability_report.md",
        "studio_run_report.md",
        "release_checklist.md",
    ]:
        report = workspace / report_name
        if report.exists():
            summary[report_name] = report.read_text(encoding="utf-8")
    return summary


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
        "skill_package/skill_manifest.yaml",
        "skill_validation/skill_validation_result.json",
        "agent_package/agent_profile.yaml",
        "agent_package/agent_compat_check_result.json",
        "batch_job_manifest.json",
        "batch_quality_summary.json",
        "batch_contract_summary.json",
        "batch_governance_summary.json",
        "package_version_graph.json",
        "impacted_skills.json",
        "impacted_agents.json",
        "workspace_refresh/source_change_report.json",
        "workspace_refresh/refresh_plan.json",
        "provider_readiness/provider_readiness_result.json",
        "prompt_profile_versions/prompt_profile_versions.json",
        "platform_distribution/platform_manifest.json",
        "platform_distribution/platform_upload_check_result.json",
        "platform_distribution/mock_publish_result.json",
        "platform_distribution/xhs_skill_manifest.json",
        "platform_distribution/xhs_skill_link_manifest.json",
        "workspace/action_center.json",
        "workspace/studio_v22_summary.json",
    ]:
        path = package / file_name
        if path.exists():
            if path.suffix == ".json":
                summary[file_name] = json.loads(path.read_text(encoding="utf-8"))
            else:
                summary[file_name] = path.read_text(encoding="utf-8")
    progress_path = package / "progress_events.jsonl"
    if progress_path.exists():
        summary["progress_event_count"] = len(progress_path.read_text(encoding="utf-8").splitlines())
    assets_path = package / "multimodal_assets.jsonl"
    if assets_path.exists():
        assets = [json.loads(line) for line in assets_path.read_text(encoding="utf-8").splitlines() if line.strip()]
        summary["multimodal_asset_count"] = len(assets)
        summary["review_required_assets"] = [asset for asset in assets if asset.get("review_required")]
    status_path = package / "batch_item_status.jsonl"
    if status_path.exists():
        summary["batch_item_status.jsonl"] = [json.loads(line) for line in status_path.read_text(encoding="utf-8").splitlines() if line.strip()]
    decisions_path = package / "governance_decisions.jsonl"
    if decisions_path.exists():
        summary["governance_decisions.jsonl"] = [json.loads(line) for line in decisions_path.read_text(encoding="utf-8").splitlines() if line.strip()]
    for jsonl_name in ["workspace/run_history.jsonl"]:
        path = package / jsonl_name
        if path.exists():
            summary[jsonl_name] = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
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
        "skill_package/SKILL.md",
        "skill_package/skill_generation_report.md",
        "skill_validation/skill_validation_report.md",
        "agent_package/soul.md",
        "agent_package/system_prompt.md",
        "agent_package/launch_checklist.md",
        "agent_package/agent_package_report.md",
        "skill_package/llm_skill_generation_report.md",
        "agent_package/llm_agent_generation_report.md",
        "batch_failure_report.md",
        "batch_performance_report.md",
        "package_lineage_report.md",
        "decision_audit_report.md",
        "update_required_report.md",
        "dependency_impact_report.md",
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
    st.subheader("Local Workspace UI v1")
    workspace_summary = load_workspace_summary(workspace_path)
    st.write(workspace_summary)
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
            "Skill generation",
            "Skill validation",
            "Agent package generation",
            "Agent prompt preview",
            "Agent compatibility",
            "Workspace refresh",
            "Provider readiness",
            "Prompt profile versioning",
            "Action center",
            "Run history",
            "Batch & Governance Center v2.3",
            "Platform Distribution v2.4",
            "Platform upload check",
            "Mock publish result",
            "Batch jobs",
            "Batch item status",
            "Package version graph",
            "Curated package",
            "Governance decision log",
            "Update impact",
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
        ("Skill Preview", "skill_package/SKILL.md"),
        ("Skill Generation Report", "skill_package/skill_generation_report.md"),
        ("Skill Validation Report", "skill_validation/skill_validation_report.md"),
        ("Agent Soul", "agent_package/soul.md"),
        ("Agent System Prompt", "agent_package/system_prompt.md"),
        ("Agent Launch Checklist", "agent_package/launch_checklist.md"),
        ("LLM Skill Generation", "skill_package/llm_skill_generation_report.md"),
        ("LLM Agent Generation", "agent_package/llm_agent_generation_report.md"),
        ("Agent Compatibility", "agent_package/agent_compat_check_report.md"),
        ("Workspace Refresh Impact", "workspace_refresh/refresh_impact_report.md"),
        ("Provider Readiness", "provider_readiness/provider_readiness_report.md"),
        ("Prompt Profile Usage", "prompt_profile_versions/prompt_profile_usage_report.md"),
        ("Platform Upload Check", "platform_distribution/platform_upload_check_report.md"),
        ("Platform Install Guide", "platform_distribution/install_guide.md"),
        ("Platform Upload Guide", "platform_distribution/upload_guide.md"),
        ("XHS Platform Policy", "platform_distribution/platform_policy.md"),
        ("XHS Violation Risk Checklist", "platform_distribution/violation_risk_checklist.md"),
        ("Batch Failure Report", "batch_failure_report.md"),
        ("Batch Performance Report", "batch_performance_report.md"),
        ("Package Lineage Report", "package_lineage_report.md"),
        ("Decision Audit Report", "decision_audit_report.md"),
        ("Update Required Report", "update_required_report.md"),
        ("Dependency Impact Report", "dependency_impact_report.md"),
    ]:
        if package_summary.get(key):
            st.subheader(title)
            st.markdown(package_summary[key])


if __name__ == "__main__":
    render_app()
