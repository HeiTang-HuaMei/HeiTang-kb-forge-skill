def render_workspace_report(manifest: dict) -> str:
    return f"""# Workspace Report

- Workspace ID: {manifest.get('workspace_id')}
- Packages: {manifest.get('package_count')}
- Skills: {manifest.get('skill_count')}
- Agents: {manifest.get('agent_count')}
- Health: {manifest.get('health_status')}
"""
