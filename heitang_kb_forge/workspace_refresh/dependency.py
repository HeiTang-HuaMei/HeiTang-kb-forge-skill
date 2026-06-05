def dependency_report(packages: list[dict], skills: list[dict], agents: list[dict]) -> dict:
    return {"package_count": len(packages), "skill_count": len(skills), "agent_count": len(agents)}
