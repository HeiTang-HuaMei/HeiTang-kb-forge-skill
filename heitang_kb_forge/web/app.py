from pathlib import Path


def render_app() -> None:
    try:
        import streamlit as st
    except ImportError as exc:
        raise RuntimeError('Web UI dependencies are not installed. Install with: pip install -e ".[web]"') from exc

    st.title("HeiTang KB Forge Skill")
    st.caption("Local Knowledge Runtime & Web MVP")
    input_path = st.text_input("Input path", "./examples/input")
    output_path = st.text_input("Output path", "./examples/output")
    query = st.text_input("Ask query", "What is this knowledge package about?")
    st.write("Build and ask actions use local CLI/Python logic only.")
    st.write({"input": input_path, "output": output_path, "query": query})


if __name__ == "__main__":
    render_app()
