from pydantic import BaseModel, Field


class RegressionCase(BaseModel):
    version: str
    capability: str
    status: str
    evidence: str


class RegressionResult(BaseModel):
    status: str
    covered_versions: list[str] = Field(default_factory=list)
    case_count: int
    failed_count: int
    warning_count: int

