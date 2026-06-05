from pydantic import BaseModel, Field


class MasterSkillInventory(BaseModel):
    master_skill_id: str
    skill_name: str
    source_path: str
    detected_files: list[str] = Field(default_factory=list)
    detected_skill_type: str = "generic_skill"
    parse_status: str = "success"
    warnings: list[str] = Field(default_factory=list)
    errors: list[str] = Field(default_factory=list)


class SkillDecomposition(BaseModel):
    skill_name: str
    positioning: str
    scenarios: list[str] = Field(default_factory=list)
    input_types: list[str] = Field(default_factory=list)
    output_types: list[str] = Field(default_factory=list)
    workflow_steps: list[str] = Field(default_factory=list)
    style_features: list[str] = Field(default_factory=list)
    boundary_rules: list[str] = Field(default_factory=list)
    prompt_patterns: list[str] = Field(default_factory=list)
