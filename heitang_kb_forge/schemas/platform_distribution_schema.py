from pydantic import BaseModel, Field


class PlatformManifest(BaseModel):
    platform_distribution_version: str = "2.4"
    platform: str
    source_skill: str
    source_agent: str | None = None
    exported_files: list[str] = Field(default_factory=list)
    real_upload_performed: bool = False
    real_platform_runtime_started: bool = False


class PlatformUploadCheckResult(BaseModel):
    platform: str
    status: str
    required_files_present: bool
    missing_files: list[str] = Field(default_factory=list)
    real_upload_allowed: bool = False


class MockPublishResult(BaseModel):
    platform: str
    status: str = "mock_success"
    real_upload_performed: bool = False
    note: str = "Mock publish only. No external platform API was called."
