from pydantic import BaseModel, Field


class RetrievalRegressionRecord(BaseModel):
    record_id: str
    citation: str


class RetrievalRegressionRun(BaseModel):
    query: str
    records: list[RetrievalRegressionRecord] = Field(default_factory=list)
    citation_trace_count: int = 0


class RetrievalRegressionInput(BaseModel):
    baseline: RetrievalRegressionRun
    current: RetrievalRegressionRun


class RetrievalRegressionReport(BaseModel):
    retrieval_regression_version: str = "1.0.0"
    status: str
    query_match: bool
    top_record_match: bool
    top_citation_match: bool
    citation_trace_count_match: bool
    baseline_top_record_id: str = ""
    current_top_record_id: str = ""
    baseline_top_citation: str = ""
    current_top_citation: str = ""
    regression_count: int = 0
    regressions: list[str] = Field(default_factory=list)
    summary: str
