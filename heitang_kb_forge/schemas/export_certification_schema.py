from pydantic import BaseModel, Field


class PlatformCertification(BaseModel):
    platform: str
    status: str
    certified: bool
    required_files_pass: bool
    policy_pass: bool
    security_pass: bool
    boundary_pass: bool
    warnings: list[str] = Field(default_factory=list)
    errors: list[str] = Field(default_factory=list)


class ExportCertificationResult(BaseModel):
    status: str
    certified: bool
    platforms: list[PlatformCertification] = Field(default_factory=list)

