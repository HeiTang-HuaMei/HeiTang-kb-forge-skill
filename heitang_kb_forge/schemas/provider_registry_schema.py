from datetime import datetime, timezone

from pydantic import BaseModel, Field


class ProviderRecord(BaseModel):
    provider_id: str
    provider_type: str = "mock"
    display_name: str
    base_url: str | None = None
    default_model: str = "mock-model"
    api_key_env: str | None = None
    enabled: bool = False
    network_required: bool = False
    health_status: str = "not_checked"
    created_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    updated_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
