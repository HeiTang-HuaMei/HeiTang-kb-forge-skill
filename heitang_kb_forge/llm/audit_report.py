def render_llm_audit_report(records: list[dict]) -> str:
    return f"""# LLM Call Audit Report

- Imported calls: {len(records)}
- API keys stored: false
- Full sensitive prompts stored: false
"""
