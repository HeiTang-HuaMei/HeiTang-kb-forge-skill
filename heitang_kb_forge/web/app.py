from pathlib import Path
import json


def load_workspace_packages(workspace: Path) -> list[dict]:
    registry = workspace / "package_registry.json"
    if not registry.exists():
        return []
    return json.loads(registry.read_text(encoding="utf-8")).get("packages", [])


def render_app() -> None:
    try:
        import streamlit as st
    except ImportError as exc:
        raise RuntimeError('Web UI dependencies are not installed. Install with: pip install -e ".[web]"') from exc

    st.title("HeiTang KB Forge Skill")
    st.caption("Knowledge Ops & Governance Platform")
    workspace_path = Path(st.text_input("Workspace path", "./workspace"))
    packages = load_workspace_packages(workspace_path)
    st.subheader("Knowledge Packages")
    st.write(packages)
    input_path = st.text_input("Input path", "./examples/input")
    output_path = st.text_input("Output path", "./examples/output")
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
        ]
    )
    st.write("Build, review, publish, refresh, and ask actions use local CLI/Python logic only.")
    st.write({"input": input_path, "output": output_path, "query": query})


if __name__ == "__main__":
    render_app()
