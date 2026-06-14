from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "governance"
POLICY = GOVERNANCE / "CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md"
PLAN_LOCK = GOVERNANCE / "PLAN_SEQUENCE_LOCK.md"
MATRIX = GOVERNANCE / "TARGET_ACCEPTANCE_MATRIX.md"
STAGE_GATE = GOVERNANCE / "CAMPAIGN_STAGE_GATE_POLICY.md"
SUPPLEMENT_3_0 = GOVERNANCE / "CAMPAIGN_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_PLAN.md"
SUPPLEMENT_4_0 = GOVERNANCE / "CAMPAIGN_3_SUPPLEMENT_4_0_KNOWLEDGE_TO_SKILL_TEMPLATE_GENERATOR_PLAN.md"
REPO_CLEANUP = GOVERNANCE / "REPOSITORY_PUBLIC_SURFACE_CLEANUP_RENAME_PUSH_TAG_SAFETY_GATE_PLAN.md"
CURRENT_RUN = ROOT / "artifacts" / "audits" / "current_run"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_integrated_closure_policy_exists_and_separates_4_0_from_campaign_4():
    text = _read(POLICY)

    for marker in [
        "Campaign 3 Supplement 4.0` | Knowledge-to-Skill-to-Agent Package & Product Handoff Contract",
        "Campaign 4` | Goal-Oriented Product UI Workbench",
        "Campaign 5` | Chain-Level Local Core Bridge",
        "`Campaign 3 Supplement 4.0` is not `Campaign 4`",
        "`Campaign 4` is not `4.0`",
    ]:
        assert marker in text


def test_post_3_0_sequence_keeps_supplement_4_0_before_stage_closure_and_campaign_4():
    combined = "\n".join(
        [
            _read(POLICY),
            _read(PLAN_LOCK),
            _read(MATRIX),
            _read(STAGE_GATE),
            _read(SUPPLEMENT_3_0),
            _read(SUPPLEMENT_4_0),
        ]
    )

    ordered_markers = [
        "Campaign 3 Supplement 3.0 completed",
        "Run Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate only.",
        "Run Campaign 3 Supplement 4.0 Entry Gate only.",
        "Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract",
        "Campaign 3 Final Consistency Gate",
        "Run Campaign 1-3 Stage Test Gate only.",
        "Campaign 1-3 Stage Test Gate",
        "Campaign 1-3 Integrated Closure Gate",
        "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate",
        "Repository push",
        "Campaign baseline RC tag creation",
        "CI green",
        "Campaign 1-3 Integrated Review and New Conversation Handoff Gate",
        "Campaign 4 Goal-Oriented Product UI Workbench Entry Gate",
    ]
    for marker in ordered_markers:
        assert marker in combined

    assert "Campaign 1-3 Stage Test Gate must not run immediately after Campaign 3 Supplement 3.0" in combined
    assert "Supplement 4.0 must still run as a Campaign 3 internal supplement" in combined
    assert "Campaign 1-3 Stage Test Gate cannot start immediately after Supplement 3.0" in combined


def test_failures_stop_before_upload_tag_ci_and_campaign_4():
    text = _read(POLICY)

    for marker in [
        "If any test fails:",
        "do not run Campaign 1-3 Integrated Closure Gate",
        "do not generate Closure Pack",
        "do not run Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate",
        "do not push",
        "do not tag",
            "do not verify CI/CL as green",
        "do not enter Campaign 4",
            "Any failure in tests, Integrated Closure Gate, Closure Pack generation, repository cleanup, push, campaign baseline RC tag creation, or CI verification must stop",
        "`resume_prompt`",
    ]:
        assert marker in text


def test_campaign_4_requires_full_closure_upload_tag_and_ci_green_chain():
    combined = "\n".join([_read(POLICY), _read(PLAN_LOCK), _read(MATRIX), _read(STAGE_GATE)])

    for marker in [
        "Campaign 4 prerequisite: Stage Test Gate passed, Integrated Closure Gate passed, Closure Pack generated, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate passed, repository push succeeded, tag created, CI/CL green, Closure Checklist green, and Campaign 1-3 Integrated Review and New Conversation Handoff Gate passed",
        "Campaign 4 may open only after Supplement 4.0 acceptance, Campaign 3 Final Consistency Gate, Campaign 1-3 Stage Test Gate, Campaign 1-3 Integrated Closure Gate, Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, campaign baseline RC tag creation, CI/CL green verification, Closure Checklist green verification, and the Campaign 1-3 Integrated Review and New Conversation Handoff Gate all pass",
        "Campaign 4 cannot become active from Campaign 3 2.0 or 3.0 completion alone",
        "repository push succeeds",
        "a campaign baseline RC tag is created",
        "tag-related CI/CL is green",
        "Closure Checklist green",
    ]:
        assert marker in combined


def test_forbidden_misinterpretations_cover_user_correction():
    text = _read(POLICY)

    for marker in [
        "Do not run Campaign 1-3 total closure directly after Campaign 3 Supplement 3.0",
        "Do not skip Campaign 3 Supplement 4.0",
        "Do not call Campaign 3 Supplement 4.0 `Campaign 4`",
        "Do not call Campaign 4 `4.0`",
        "Do not enter Campaign 4 before Supplement 4.0 completes",
        "Do not enter Campaign 4 before Campaign 3 Final Consistency Gate passes",
        "Do not enter Campaign 4 before Campaign 1-3 Stage Test Gate passes",
        "Do not enter Campaign 4 before Integrated Closure Gate passes",
        "Do not tag before repository push succeeds",
        "Do not enter Campaign 4 before CI/CL is green",
        "Do not treat TasteSkill or Product Design Plugin as Campaign 4 base acceptance",
        "Do not treat Campaign 5 raw allowlist presence as chain-level Bridge execution",
        "Do not generate Campaign 1-3 integrated review and new-conversation handoff reports before real push, tag, CI Green, and Closure Checklist Green evidence exists",
        "`not_goal_complete = true`",
    ]:
        assert marker in text


def test_post_ci_review_and_new_conversation_handoff_gate_is_registered_but_not_executed_now():
    combined = "\n".join(
        [
            _read(POLICY),
            _read(PLAN_LOCK),
            _read(MATRIX),
            _read(STAGE_GATE),
            _read(REPO_CLEANUP),
        ]
    )

    for marker in [
        "Campaign 1-3 Integrated Review and New Conversation Handoff Gate",
        "docs/governance/CAMPAIGN_1_2_3_INTEGRATED_REVIEW_REPORT.md",
        "docs/governance/CAMPAIGN_1_2_3_EXTERNAL_PROJECT_INTEGRATION_REVIEW.md",
        "docs/governance/CAMPAIGN_1_2_3_CAPABILITY_REVIEW_MATRIX.md",
        "artifacts/audits/current_run/new_conversation_handoff_prompt.md",
        "artifacts/audits/current_run/campaign_1_2_3_handoff_manifest.json",
        "These outputs must not be generated before real final commit, push, tag, and CI evidence exists",
        "Open a new conversation and start Campaign 4 Entry Gate only",
    ]:
        assert marker in combined

    for future_output in [
        GOVERNANCE / "CAMPAIGN_1_2_3_INTEGRATED_REVIEW_REPORT.md",
        GOVERNANCE / "CAMPAIGN_1_2_3_EXTERNAL_PROJECT_INTEGRATION_REVIEW.md",
        GOVERNANCE / "CAMPAIGN_1_2_3_CAPABILITY_REVIEW_MATRIX.md",
        CURRENT_RUN / "new_conversation_handoff_prompt.md",
        CURRENT_RUN / "campaign_1_2_3_handoff_manifest.json",
    ]:
        assert not future_output.exists(), f"{future_output} must wait for post-CI handoff gate"


def test_post_ci_review_contract_covers_external_projects_capabilities_and_release_facts():
    text = _read(POLICY)

    for marker in [
        "Campaigns 1, 2, and 3 completed",
        "Supplement 2.0, Supplement 3.0, Pre-4.0, Supplement 4.0",
        "Repository cleanup / rename / push-tag safety completion",
        "final commit hash",
        "tag name",
        "push status",
        "CI status",
        "Stage / Functional Test result",
        "Integrated Closure result",
        "Repository Cleanup / Rename / Push-Tag Safety result",
        "`git diff --check` result",
        "JSON parse result",
        "forbidden tracked files check result",
        "secret check result",
    ]:
        assert marker in text

    for field in [
        "project_name",
        "source_url_or_registry_id",
        "campaign_section",
        "capability_domain",
        "integration_status",
        "implementation_mode",
        "runtime_dependency_added",
        "tests_added",
        "evidence_path",
        "current_boundary",
        "future_target",
    ]:
        assert field in text

    for status in [
        "real_integration",
        "reference_only",
        "planned_not_active",
        "needs_verification",
        "stopped_or_rejected",
    ]:
        assert status in text

    for marker in [
        "LLM Wiki v2 belongs to Campaign 3 Section 5.1",
        "Memory Separation / Knowledge Lifecycle has been integrated as a local capability",
        "Redis / Vector DB / external database-backed Memory Store Connector belongs to Campaign 8 future target",
        "andrej-karpathy-skills is a Knowledge-to-Skill methodology reference",
        "Presenton is a Document/PPT workflow reference",
        "CodeGraph and Understand Anything are future codebase graph / knowledge graph / Workbench UI references",
        "LongLive is not in the current product route",
        "this product does not add GPU video generation",
        "pi-mono is future Agent Runtime architecture reference",
        "claude-plugins-official is future plugin ecosystem reference",
    ]:
        assert marker in text

    for marker in [
        "Knowledge Package",
        "Document Outputs: Markdown / DOCX / PDF / PPTX",
        "Skill Outputs: Skill Template / Skill Suite",
        "Agent Creation Package",
        "Memory Separation / Knowledge Lifecycle",
        "Evidence Map / Source Trace",
        "Retrieval / Verification",
        "Workspace Partition / KB Access Scope",
        "External Source Memory & Verification",
        "Document generation",
        "Skill generation",
        "Agent package generation",
    ]:
        assert marker in text


def test_post_ci_review_forbidden_boundaries_match_user_lock():
    text = _read(POLICY)

    for marker in [
        "Campaign 4 has not started unless CI Green and the existing Closure Checklist Green gate allow the next safe action",
        "Campaign 8 Redis / Vector DB has not started",
        "EXE packaging has not started",
        "Local large model support is not planned",
        "GPU video generation is not planned",
        "Optional OCR and advanced parser providers are dependency-gated and not default bundled",
        "`_local_dependency_remediation/` is not a release artifact and must not be packaged into the main EXE",
        "Do not write `reference_only` as `real_integration`",
        "Do not write `planned_not_active` as completed",
        "Do not write Redis / Vector DB as completed in Campaign 3",
        "Do not write LongLive / GPU video into the current product route",
        "Do not write local large model support into the EXE packaging target",
        "Do not write push/tag/CI Green as commercial release completion",
        "Do not start Campaign 4 business implementation inside the report",
        "Do not delete valid audit evidence",
        "Do not write `_local_dependency_remediation/` as a release artifact",
    ]:
        assert marker in text
