from pydantic import BaseModel, Field


class PromptProfile(BaseModel):
    profile_name: str
    language: str | None = None
    focus: list[str] = Field(default_factory=list)
    preferred_outputs: dict[str, bool] = Field(default_factory=dict)
    extraction_rules: list[str] = Field(default_factory=list)
