from datetime import UTC, datetime

from pydantic import BaseModel, Field


def _now_iso() -> str:
    return datetime.now(UTC).isoformat()


class PlatformManifest(BaseModel):
    platform_distribution_version: str = "2.4"
    generated_at: str = Field(default_factory=_now_iso)
    platform: str
    package_type: str = "local_platform_distribution"
    source_skill: str
    source_agent: str | None = None
    supported_platforms: list[str] = Field(default_factory=list)
    exported_files: list[str] = Field(default_factory=list)
    install_guide: str = "install_guide.md"
    upload_guide: str = "upload_guide.md"
    upload_check_file: str = "platform_upload_check_result.json"
    mock_publish_file: str = "mock_publish_result.json"
    policy_files: list[str] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)
    limits: list[str] = Field(default_factory=list)
    real_upload_performed: bool = False
    real_platform_runtime_started: bool = False


class PlatformUploadCheckResult(BaseModel):
    platform: str
    status: str
    required_files_present: bool
    missing_files: list[str] = Field(default_factory=list)
    api_key_risk_detected: bool = False
    dangerous_command_detected: bool = False
    risk_files: list[str] = Field(default_factory=list)
    checks: dict[str, bool] = Field(default_factory=dict)
    real_upload_allowed: bool = False


class MockPublishResult(BaseModel):
    platform: str
    status: str = "mock_success"
    real_upload_performed: bool = False
    external_platform_called: bool = False
    network_call_performed: bool = False
    xhs_account_used: bool = False
    automatic_note_publish: bool = False
    note: str = "Mock publish only. No external platform API was called."
