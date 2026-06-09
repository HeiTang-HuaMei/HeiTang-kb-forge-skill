from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


ActionStatus = Literal["ready", "dry_run", "planned_adapter", "ui_pending", "blocked"]
CommandKind = Literal["core_cli", "ui_safe_wrapper", "planned_adapter", "not_runnable"]
TaskStatus = Literal["queued", "running", "succeeded", "failed", "blocked", "cancelled", "timed_out", "review_required"]


class WorkbenchModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class WorkbenchCapabilityArea(WorkbenchModel):
    page_id: str
    title: str
    capability_area_id: str
    capability_summary: str
    capabilities: list[str]
    action_ids: list[str]
    report_ids: list[str]
    artifact_ids: list[str]
    desktop_web_boundary: str
    privacy_boundary: str


class WorkbenchActionContract(WorkbenchModel):
    action_id: str
    page_id: str
    capability_id: str
    label: str
    button_id: str
    status: ActionStatus
    command_kind: CommandKind
    command: str | None = None
    blocked_reason: str | None = None
    dry_run_supported: bool = True
    smoke_supported: bool = True
    requires_explicit_user_config: bool = False
    report_ids: list[str] = Field(default_factory=list)
    artifact_ids: list[str] = Field(default_factory=list)
    error_codes: list[str] = Field(default_factory=list)
    task_statuses: list[TaskStatus] = Field(default_factory=list)


class WorkbenchReportRegistryEntry(WorkbenchModel):
    report_id: str
    page_id: str
    title: str
    format: str
    deterministic_fixture_path: str
    owner_capability: str
    contains_raw_input: bool = False
    contains_secret: bool = False
    p1_ready: bool = True
    blocked_reason: str | None = None


class WorkbenchArtifactRegistryEntry(WorkbenchModel):
    artifact_id: str
    page_id: str
    title: str
    artifact_type: str
    deterministic_fixture_path: str
    managed_by_page_ids: list[str]
    contains_raw_input: bool = False
    contains_secret: bool = False
    p1_ready: bool = True
    blocked_reason: str | None = None


class WorkbenchErrorTaxonomyEntry(WorkbenchModel):
    error_code: str
    title: str
    severity: Literal["info", "warning", "error", "blocker"]
    repair_action_id: str | None = None
    user_visible: bool = True
    retryable: bool = False
    blocked_reason: str | None = None


class WorkbenchTaskField(WorkbenchModel):
    field_id: str
    type: str
    required: bool
    description: str


class WorkbenchTaskSchema(WorkbenchModel):
    task_schema_version: str
    statuses: list[TaskStatus]
    fields: list[WorkbenchTaskField]
    transitions: dict[str, list[TaskStatus]]
    deterministic_fixture_path: str


class WorkbenchProviderCandidate(WorkbenchModel):
    provider_id: str
    provider_type: str
    status: Literal["ready", "planned_adapter", "blocked"]
    ready: bool
    requires_explicit_user_config: bool
    local_first_default: bool
    blocked_reason: str | None = None


class WorkbenchProviderSchema(WorkbenchModel):
    provider_schema_version: str
    candidates: list[WorkbenchProviderCandidate]
    redaction_required: bool
    network_required_by_default: bool
    deterministic_fixture_path: str


class WorkbenchStorageSchema(WorkbenchModel):
    storage_schema_version: str
    local_workspace_storage: bool
    byo_storage_profile_schema: dict[str, str]
    external_provider_requires_explicit_config: bool
    deterministic_fixture_path: str


class WorkbenchWorkspaceSchema(WorkbenchModel):
    workspace_schema_version: str
    required_paths: list[str]
    registry_files: list[str]
    local_first_privacy_boundary: str
    deterministic_fixture_path: str


class WorkbenchTemplateRegistryEntry(WorkbenchModel):
    template_id: str
    title: str
    use_case: str
    recommended_inputs: list[str]
    chunk_strategy: str
    metadata_rules: list[str]
    retrieval_strategy: str
    skill_output_structure: list[str]
    agent_config: dict[str, str | bool]
    evaluation_questions: list[str]
    example_reports: list[str]
    p1_ready: bool
    blocked_reason: str | None = None


class WorkbenchP1GateReport(WorkbenchModel):
    gate_id: str
    core_contract_ready: bool
    ui_full_operation_pending: bool
    p1_full_operation_gate_status: Literal["blocked", "failed", "passed"]
    not_v4_0_workbench_rc: bool
    dashboard_readable: bool
    reports_readable: bool
    gate_page_readable: bool
    blocker_ids: list[str]
    evidence_files: list[str]


class WorkbenchProductizationBundle(WorkbenchModel):
    profile: Literal["p1"]
    productization_version: str
    manifest: dict[str, object]
    capability_areas: list[WorkbenchCapabilityArea]
    action_contracts: list[WorkbenchActionContract]
    report_registry: list[WorkbenchReportRegistryEntry]
    artifact_registry: list[WorkbenchArtifactRegistryEntry]
    error_taxonomy: list[WorkbenchErrorTaxonomyEntry]
    task_schema: WorkbenchTaskSchema
    provider_schema: WorkbenchProviderSchema
    storage_schema: WorkbenchStorageSchema
    workspace_schema: WorkbenchWorkspaceSchema
    template_registry: list[WorkbenchTemplateRegistryEntry]
    p1_gate_report: WorkbenchP1GateReport
    deterministic_fixtures: dict[str, object]
