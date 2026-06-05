from pydantic import BaseModel, Field


class GoldenSampleRecord(BaseModel):
    sample_id: str
    path: str
    status: str
    warnings: list[str] = Field(default_factory=list)


class GoldenSampleValidation(BaseModel):
    status: str
    sample_count: int
    passed: int
    failed: int
    samples: list[GoldenSampleRecord] = Field(default_factory=list)

