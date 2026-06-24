from pydantic import BaseModel, Field


class PlanStep(BaseModel):
    step_id: str
    title: str
    depends_on: list[str] = Field(default_factory=list)
    blocked: bool = False
    completed: bool = False


class PlanExecuteInput(BaseModel):
    steps: list[PlanStep] = Field(default_factory=list)


class PlanExecuteReport(BaseModel):
    plan_execute_version: str = "1.0.0"
    status: str
    execution_order: list[str] = Field(default_factory=list)
    completed_step_ids: list[str] = Field(default_factory=list)
    remaining_step_ids: list[str] = Field(default_factory=list)
    blocked_step_ids: list[str] = Field(default_factory=list)
    missing_dependency_step_ids: list[str] = Field(default_factory=list)
    summary: str
