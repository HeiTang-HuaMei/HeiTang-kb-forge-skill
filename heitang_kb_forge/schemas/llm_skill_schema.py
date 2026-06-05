from pydantic import BaseModel, Field


class LLMSkillGenerationReport(BaseModel):
    enabled: bool
    provider: str
    fallback: bool
    generated_files: list[str] = Field(default_factory=list)
    generated_by: str
    review_required: list[str] = Field(default_factory=list)
