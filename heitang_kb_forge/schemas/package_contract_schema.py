from pydantic import BaseModel, Field


class ContractCheckResult(BaseModel):
    contract_version: str = "2.0"
    status: str = "pass"
    missing_required_files: list[str] = Field(default_factory=list)
    missing_conditional_files: list[str] = Field(default_factory=list)
    missing_manifest_fields: list[str] = Field(default_factory=list)
    invalid_chunk_fields: list[str] = Field(default_factory=list)
    invalid_evidence_fields: list[str] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)
    errors: list[str] = Field(default_factory=list)
