from pydantic import BaseModel, Field


class CredentialProxyEntry(BaseModel):
    provider_id: str
    credential_env: str | None = None
    endpoint_env: str | None = None
    model_env: str | None = None
    inline_credential: str | None = None


class CredentialProxyReport(BaseModel):
    schema_version: str = "credential_proxy_design.v1"
    status: str
    provider_count: int
    failed_checks: list[str] = Field(default_factory=list)
    entries: list[dict] = Field(default_factory=list)
    output_files: list[str] = Field(default_factory=list)
    boundary: dict = Field(default_factory=dict)
