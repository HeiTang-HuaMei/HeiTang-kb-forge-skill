from pydantic import BaseModel, Field


class WorkbenchAgentHarnessInput(BaseModel):
    agent_name: str = "Workbench Agent"
    tool_name: str = "retrieve_knowledge"
    package: str | None = None
    store: str | None = None
    query: str
    top_k: int = 5


class WorkbenchAgentHarnessReport(BaseModel):
    schema_version: str = "workbench_agent_harness.v1"
    status: str
    agent_name: str
    tool_name: str
    execution_mode: str = "local_workbench_agent_harness"
    input_keys: list[str] = Field(default_factory=list)
    output_files: list[str] = Field(default_factory=list)
    failed_checks: list[str] = Field(default_factory=list)
    result_summary: dict = Field(default_factory=dict)
    boundary: dict = Field(default_factory=dict)
