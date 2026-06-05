from pydantic import BaseModel, Field


class SkillTemplate(BaseModel):
    skill_type: str
    title: str
    tasks: list[str] = Field(default_factory=list)
    inputs: list[str] = Field(default_factory=list)
    outputs: list[str] = Field(default_factory=list)
    failure_modes: list[str] = Field(default_factory=list)
