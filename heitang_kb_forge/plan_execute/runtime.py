from heitang_kb_forge.schemas.plan_execute_schema import PlanExecuteInput, PlanExecuteReport, PlanStep


def run_plan_execute(payload: PlanExecuteInput | dict) -> PlanExecuteReport:
    data = payload if isinstance(payload, PlanExecuteInput) else PlanExecuteInput.model_validate(payload)
    steps_by_id = {step.step_id: step for step in data.steps}
    completed = {step.step_id for step in data.steps if step.completed}
    blocked_step_ids = [step.step_id for step in data.steps if step.blocked]
    missing_dependency_step_ids: list[str] = []
    execution_order: list[str] = []

    for step in data.steps:
        if step.completed or step.blocked:
            continue
        missing = [dependency for dependency in step.depends_on if dependency not in steps_by_id]
        unmet = [dependency for dependency in step.depends_on if dependency in steps_by_id and dependency not in completed]
        if missing:
            missing_dependency_step_ids.append(step.step_id)
            continue
        if unmet:
            continue
        execution_order.append(step.step_id)
        completed.add(step.step_id)

    completed_step_ids = [step.step_id for step in data.steps if step.step_id in completed]
    remaining_step_ids = [
        step.step_id
        for step in data.steps
        if step.step_id not in completed and step.step_id not in set(blocked_step_ids)
    ]
    status = _status(execution_order, blocked_step_ids, missing_dependency_step_ids, remaining_step_ids)
    return PlanExecuteReport(
        status=status,
        execution_order=execution_order,
        completed_step_ids=completed_step_ids,
        remaining_step_ids=remaining_step_ids,
        blocked_step_ids=blocked_step_ids,
        missing_dependency_step_ids=missing_dependency_step_ids,
        summary=(
            f"{len(execution_order)} executable step(s), {len(remaining_step_ids)} remaining, "
            f"{len(blocked_step_ids)} blocked."
        ),
    )


def _status(
    execution_order: list[str],
    blocked_step_ids: list[str],
    missing_dependency_step_ids: list[str],
    remaining_step_ids: list[str],
) -> str:
    if missing_dependency_step_ids:
        return "missing_dependencies"
    if blocked_step_ids:
        return "blocked"
    if remaining_step_ids:
        return "partial"
    if execution_order:
        return "executed"
    return "complete"
