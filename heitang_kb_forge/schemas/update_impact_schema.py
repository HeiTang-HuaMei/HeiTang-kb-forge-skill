from pydantic import BaseModel


class ImpactedSkill(BaseModel):
    skill_id: str
    skill_path: str
    source_package_id: str
    impact_level: str = "medium"
    reason: str = "Source package changed or was curated."
    suggested_action: str = "revalidate"


class ImpactedAgent(BaseModel):
    agent_id: str
    agent_path: str
    source_skill_id: str
    impact_level: str = "medium"
    reason: str = "Source skill or package changed."
    suggested_action: str = "revalidate"
