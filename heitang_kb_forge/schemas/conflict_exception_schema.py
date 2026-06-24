from pydantic import BaseModel, Field


class ConflictStatement(BaseModel):
    statement_id: str
    topic: str
    polarity: str
    text: str
    source_id: str = ""
    exception_of: str = ""


class ConflictRecord(BaseModel):
    conflict_id: str
    topic: str
    positive_statement_ids: list[str] = Field(default_factory=list)
    negative_statement_ids: list[str] = Field(default_factory=list)


class ExceptionRecord(BaseModel):
    exception_id: str
    statement_id: str
    exception_of: str
    topic: str


class ConflictExceptionInput(BaseModel):
    statements: list[ConflictStatement] = Field(default_factory=list)


class ConflictExceptionReport(BaseModel):
    conflict_exception_version: str = "1.0.0"
    status: str
    conflict_count: int = 0
    exception_count: int = 0
    conflicts: list[ConflictRecord] = Field(default_factory=list)
    exceptions: list[ExceptionRecord] = Field(default_factory=list)
    checked_statement_ids: list[str] = Field(default_factory=list)
    summary: str
