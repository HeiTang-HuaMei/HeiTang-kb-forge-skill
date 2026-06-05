from pydantic import BaseModel, Field


class SkillValidationResult(BaseModel):
    skill_id: str
    status: str
    release_ready: bool
    scores: dict[str, int]
    warnings: list[str] = Field(default_factory=list)
    errors: list[str] = Field(default_factory=list)
    review_required: list[str] = Field(default_factory=list)
