from pydantic import BaseModel, Field


class StableCheckResult(BaseModel):
    status: str
    checked_contracts: dict[str, str]
    extension_readiness: dict[str, str] = Field(default_factory=dict)
    warnings: list[str] = Field(default_factory=list)
    errors: list[str] = Field(default_factory=list)
    release_ready: bool = False
