from pydantic import BaseModel, Field


class BatchItemStatus(BaseModel):
    item_id: str
    source_path: str
    output_path: str
    status: str
    error_type: str = ""
    error_message: str = ""
    started_at: str = ""
    finished_at: str = ""
    retry_count: int = 0
    outputs: list[str] = Field(default_factory=list)


class BatchJobManifest(BaseModel):
    batch_id: str
    created_at: str
    input_root: str
    output_root: str
    total_items: int
    success_count: int
    failed_count: int
    skipped_count: int = 0
    partial_count: int = 0
    profile: str = "production"
    resume_enabled: bool = True
    retry_enabled: bool = True
    status: str
