from pydantic import BaseModel, Field


class LongDocumentSection(BaseModel):
    section_id: str
    title: str
    text: str = Field(min_length=1)
    required: bool = False
    already_read: bool = False


class LongDocumentStrategyInput(BaseModel):
    sections: list[LongDocumentSection] = Field(default_factory=list)
    max_chars_per_pass: int = Field(default=2000, gt=0)
    max_sections_per_pass: int = Field(default=6, gt=0)
    required_section_ids: list[str] = Field(default_factory=list)


class LongDocumentStrategyReport(BaseModel):
    long_document_strategy_version: str = "1.0.0"
    status: str
    reading_order: list[str] = Field(default_factory=list)
    remaining_section_ids: list[str] = Field(default_factory=list)
    already_read_section_ids: list[str] = Field(default_factory=list)
    missing_required_section_ids: list[str] = Field(default_factory=list)
    selected_char_count: int = 0
    summary: str
