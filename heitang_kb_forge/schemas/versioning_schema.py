from pydantic import BaseModel, Field


class PackageVersion(BaseModel):
    package_version: str = "1.1.0"
    generated_at: str
    package_path: str
    source_count: int = 0
    chunk_count: int = 0
    source_hashes: dict[str, str] = Field(default_factory=dict)
    chunk_hashes: dict[str, str] = Field(default_factory=dict)
    asset_hashes: dict[str, str] = Field(default_factory=dict)
    package_hash: str
