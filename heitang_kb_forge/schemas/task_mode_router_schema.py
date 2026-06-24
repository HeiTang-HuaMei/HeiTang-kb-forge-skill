from pydantic import BaseModel, Field


class TaskModeRouterInput(BaseModel):
    task_text: str
    changed_file_count: int = 0
    estimated_minutes: int = 0
    affects_ui: bool = False
    affects_runtime: bool = False
    user_blackbox_required: bool = False
    review_requested: bool = False
    stage_gate_requested: bool = False
    hard_blocker_risk: bool = False


class TaskModeRouterDecision(BaseModel):
    task_mode_router_version: str = "1.0.0"
    mode: str
    auto_execute_allowed: bool
    owner_review_required: bool
    reason_codes: list[str] = Field(default_factory=list)
    validation_focus: list[str] = Field(default_factory=list)
    summary: str
