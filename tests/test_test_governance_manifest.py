import json
from pathlib import Path
from types import SimpleNamespace

from heitang_kb_forge.test_governance import build_validation_plan, load_manifest, select_impact_rules, validate_manifest
from heitang_kb_forge.test_governance import gates


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "docs" / "testing" / "VALIDATION_GATE_MANIFEST.json"


def test_validation_gate_manifest_is_structurally_valid():
    manifest = load_manifest(MANIFEST_PATH)

    assert manifest["release_version"] == "v4.2.0"
    assert validate_manifest(manifest) == []
    assert manifest["reporting_policy"]["never_report_skipped_or_deferred_as_passed"] is True
    assert "passed by default" in manifest["reporting_policy"]["forbidden_skip_reasons"]
    assert "passed" not in manifest["reporting_policy"]["allowed_non_pass_status"]
    assert manifest["post_codex_review_gate"]["required"] is True

    release_gates = {gate["name"]: gate for gate in manifest["gates"] if gate["level"] == "chunked_full"}
    assert set(manifest["release_gate_sequence"]) <= set(release_gates)
    assert all(gate["release_blocking"] is True for gate in release_gates.values())
    assert all(gate["exit_code_required"] is True for gate in release_gates.values())
    assert all(gate["log_path"].startswith("docs/audits/test_engineering/full_gate_logs/") for gate in release_gates.values())


def test_pytest_markers_are_declared_for_gate_selection():
    manifest = load_manifest(MANIFEST_PATH)
    pyproject = (ROOT / "pyproject.toml").read_text(encoding="utf-8")

    for marker in manifest["pytest_markers"]:
        assert f"{marker}:" in pyproject


def test_changed_file_impact_rules_select_development_and_release_gates():
    manifest = load_manifest(MANIFEST_PATH)
    rules = select_impact_rules(["docs/testing/VALIDATION_STRATEGY.md", "pyproject.toml"], manifest)

    assert {rule["name"] for rule in rules} >= {"test_governance", "version_metadata"}

    dev_plan = build_validation_plan(["docs/testing/VALIDATION_STRATEGY.md"], phase="development", manifest=manifest)
    assert {gate["name"] for gate in dev_plan["selected_gates"]} >= {
        "core_fast_test_governance",
        "core_fast_docs_truth",
    }
    assert dev_plan["release_blocking"] is False

    release_plan = build_validation_plan(["docs/testing/VALIDATION_STRATEGY.md"], phase="release", manifest=manifest)
    assert [gate["name"] for gate in release_plan["selected_gates"]] == manifest["release_gate_sequence"]
    assert release_plan["release_blocking"] is True

    doctor_plan = build_validation_plan(["heitang_kb_forge/doctor.py"], phase="development", manifest=manifest)
    assert [gate["name"] for gate in doctor_plan["selected_gates"]] == ["core_fast_doctor_release_readiness"]
    assert "doctor_release_readiness" in doctor_plan["matched_rules"]

    contract_plan = build_validation_plan(
        ["heitang_kb_forge/schemas/adapter_result_schema.json"],
        phase="development",
        manifest=manifest,
    )
    assert "core_fast_parser_backend" in {gate["name"] for gate in contract_plan["selected_gates"]}
    assert "parser_backend" in contract_plan["matched_rules"]

    skill_suite_plan = build_validation_plan(
        ["heitang_kb_forge/skill_suite/governance.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in skill_suite_plan["selected_gates"]] == [
        "core_fast_skill_suite"
    ]
    assert "skill_suite" in skill_suite_plan["matched_rules"]

    agent_binding_plan = build_validation_plan(
        ["heitang_kb_forge/agent_package/profile.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in agent_binding_plan["selected_gates"]] == [
        "core_fast_agent_binding"
    ]
    assert "agent_binding" in agent_binding_plan["matched_rules"]

    external_evidence_plan = build_validation_plan(
        ["heitang_kb_forge/verification/agent_output.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in external_evidence_plan["selected_gates"]] == [
        "core_fast_external_evidence_verification"
    ]
    assert "external_evidence_verification" in external_evidence_plan["matched_rules"]

    product_output_plan = build_validation_plan(
        ["docs/governance/PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.json"],
        phase="development",
        manifest=manifest,
    )
    assert {gate["name"] for gate in product_output_plan["selected_gates"]} >= {
        "core_fast_test_governance",
        "core_fast_docs_truth",
    }
    assert "test_governance" in product_output_plan["matched_rules"]

    knowledge_lifecycle_plan = build_validation_plan(
        ["heitang_kb_forge/knowledge_lifecycle/analyzer.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in knowledge_lifecycle_plan["selected_gates"]] == [
        "core_fast_knowledge_lifecycle"
    ]
    assert "knowledge_lifecycle" in knowledge_lifecycle_plan["matched_rules"]

    auto_wiki_plan = build_validation_plan(
        ["heitang_kb_forge/auto_wiki/builder.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in auto_wiki_plan["selected_gates"]] == [
        "core_fast_auto_wiki"
    ]
    assert "auto_wiki" in auto_wiki_plan["matched_rules"]

    anysearch_plan = build_validation_plan(
        ["heitang_kb_forge/external_retrieval/anysearch.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in anysearch_plan["selected_gates"]] == [
        "core_fast_anysearch_provider"
    ]
    assert "anysearch_provider" in anysearch_plan["matched_rules"]

    n8n_plan = build_validation_plan(
        ["heitang_kb_forge/external_automation/n8n.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in n8n_plan["selected_gates"]] == [
        "core_fast_n8n_workflow_export"
    ]
    assert "n8n_workflow_export" in n8n_plan["matched_rules"]

    mmskills_plan = build_validation_plan(
        ["heitang_kb_forge/multimodal_skill_package/builder.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in mmskills_plan["selected_gates"]] == [
        "core_fast_mmskills_multimodal_package"
    ]
    assert "mmskills_multimodal_package" in mmskills_plan["matched_rules"]

    prompt_asset_plan = build_validation_plan(
        ["heitang_kb_forge/prompt_asset_library/builder.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in prompt_asset_plan["selected_gates"]] == [
        "core_fast_skill_prompt_generator"
    ]
    assert "skill_prompt_generator" in prompt_asset_plan["matched_rules"]

    marketing_pattern_plan = build_validation_plan(
        ["heitang_kb_forge/marketing_skill_patterns/builder.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in marketing_pattern_plan["selected_gates"]] == [
        "core_fast_ai_marketing_skills"
    ]
    assert "ai_marketing_skills" in marketing_pattern_plan["matched_rules"]

    business_scenario_plan = build_validation_plan(
        ["heitang_kb_forge/business_scenario_templates/builder.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in business_scenario_plan["selected_gates"]] == [
        "core_fast_ai_money_maker_handbook"
    ]
    assert "ai_money_maker_handbook" in business_scenario_plan["matched_rules"]

    jellyfish_plan = build_validation_plan(
        ["heitang_kb_forge/content_asset_schema/builder.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in jellyfish_plan["selected_gates"]] == [
        "core_fast_jellyfish_content_asset_schema"
    ]
    assert "jellyfish_content_asset_schema" in jellyfish_plan["matched_rules"]

    story_flicks_plan = build_validation_plan(
        ["heitang_kb_forge/video_pipeline_schema/builder.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in story_flicks_plan["selected_gates"]] == [
        "core_fast_story_flicks_video_pipeline_schema"
    ]
    assert "story_flicks_video_pipeline_schema" in story_flicks_plan["matched_rules"]

    seedance2_plan = build_validation_plan(
        ["heitang_kb_forge/video_skill_template_metadata/builder.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in seedance2_plan["selected_gates"]] == [
        "core_fast_seedance2_skill_template_metadata"
    ]
    assert "seedance2_skill_template_metadata" in seedance2_plan["matched_rules"]

    rag_anything_plan = build_validation_plan(
        ["heitang_kb_forge/cross_modal_rag_schema/builder.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in rag_anything_plan["selected_gates"]] == [
        "core_fast_rag_anything_cross_modal_rag_schema"
    ]
    assert "rag_anything_cross_modal_rag_schema" in rag_anything_plan["matched_rules"]

    mattpocock_plan = build_validation_plan(
        ["heitang_kb_forge/engineering_governance_rules/builder.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in mattpocock_plan["selected_gates"]] == [
        "core_fast_mattpocock_engineering_governance"
    ]
    assert "mattpocock_engineering_governance" in mattpocock_plan["matched_rules"]

    sirchmunk_plan = build_validation_plan(
        ["heitang_kb_forge/external_retrieval/sirchmunk.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in sirchmunk_plan["selected_gates"]] == [
        "core_fast_sirchmunk_direct_file_search"
    ]
    assert "sirchmunk_direct_file_search" in sirchmunk_plan["matched_rules"]

    gbrain_plan = build_validation_plan(
        ["heitang_kb_forge/gbrain_strengthening/builder.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in gbrain_plan["selected_gates"]] == [
        "core_fast_gbrain_strengthening"
    ]
    assert "gbrain_strengthening" in gbrain_plan["matched_rules"]

    horizon_plan = build_validation_plan(
        ["heitang_kb_forge/horizon_strengthening/builder.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in horizon_plan["selected_gates"]] == [
        "core_fast_horizon_strengthening"
    ]
    assert "horizon_strengthening" in horizon_plan["matched_rules"]

    obsidian_plan = build_validation_plan(
        ["heitang_kb_forge/obsidian_vault_strengthening/builder.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in obsidian_plan["selected_gates"]] == [
        "core_fast_obsidian_vault_strengthening"
    ]
    assert "obsidian_vault_strengthening" in obsidian_plan["matched_rules"]

    obsidian_audit_plan = build_validation_plan(
        [
            "artifacts/audits/section_5/obsidian_vault_strengthening/"
            "obsidian_vault_integration_decision_report.json"
        ],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in obsidian_audit_plan["selected_gates"]] == [
        "core_fast_obsidian_vault_strengthening"
    ]
    assert "obsidian_vault_strengthening" in obsidian_audit_plan["matched_rules"]

    closure_gate_plan = build_validation_plan(
        ["heitang_kb_forge/campaign_3_closure/supplement_2_0.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in closure_gate_plan["selected_gates"]] == [
        "core_fast_campaign_3_supplement_2_0_closure_gate"
    ]
    assert "campaign_3_supplement_2_0_closure_gate" in closure_gate_plan["matched_rules"]

    closure_audit_plan = build_validation_plan(
        [
            "artifacts/audits/section_5/campaign_3_supplement_2_0_closure_gate/"
            "campaign_3_supplement_2_0_closure_gate.json"
        ],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in closure_audit_plan["selected_gates"]] == [
        "core_fast_campaign_3_supplement_2_0_closure_gate"
    ]
    assert "campaign_3_supplement_2_0_closure_gate" in closure_audit_plan["matched_rules"]

    entry_gate_plan = build_validation_plan(
        ["heitang_kb_forge/campaign_3_closure/supplement_3_0_entry.py"],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in entry_gate_plan["selected_gates"]] == [
        "core_fast_campaign_3_supplement_3_0_entry_gate"
    ]
    assert "campaign_3_supplement_3_0_entry_gate" in entry_gate_plan["matched_rules"]

    entry_audit_plan = build_validation_plan(
        [
            "artifacts/audits/section_5/campaign_3_supplement_3_0_entry_gate/"
            "campaign_3_supplement_3_0_entry_gate.json"
        ],
        phase="development",
        manifest=manifest,
    )
    assert [gate["name"] for gate in entry_audit_plan["selected_gates"]] == [
        "core_fast_campaign_3_supplement_3_0_entry_gate"
    ]
    assert "campaign_3_supplement_3_0_entry_gate" in entry_audit_plan["matched_rules"]

    campaign_3_0_plan = build_validation_plan(
        ["docs/governance/CAMPAIGN_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_PLAN.md"],
        phase="development",
        manifest=manifest,
    )
    assert "core_fast_campaign_3_supplement_3_0_entry_gate" in {
        gate["name"] for gate in campaign_3_0_plan["selected_gates"]
    }
    assert "campaign_3_supplement_3_0_entry_gate" in campaign_3_0_plan["matched_rules"]

    framework_plan = build_validation_plan(
        ["heitang_kb_forge/external_sources/framework.py"],
        phase="development",
        manifest=manifest,
    )
    assert "core_fast_external_source_framework" in {
        gate["name"] for gate in framework_plan["selected_gates"]
    }
    assert "external_source_memory_verification" in framework_plan["matched_rules"]

    framework_audit_plan = build_validation_plan(
        [
            "artifacts/audits/section_5/external_source_framework/framework/"
            "external_source_framework_manifest.json"
        ],
        phase="development",
        manifest=manifest,
    )
    assert "core_fast_external_source_framework" in {
        gate["name"] for gate in framework_audit_plan["selected_gates"]
    }
    assert "external_source_memory_verification" in framework_audit_plan["matched_rules"]

    generic_url_plan = build_validation_plan(
        ["heitang_kb_forge/external_sources/generic_url.py"],
        phase="development",
        manifest=manifest,
    )
    assert "core_fast_external_source_generic_url" in {
        gate["name"] for gate in generic_url_plan["selected_gates"]
    }
    assert "external_source_memory_verification" in generic_url_plan["matched_rules"]

    generic_url_audit_plan = build_validation_plan(
        [
            "artifacts/audits/section_5/external_source_generic_url/ingestion/"
            "link_ingestion_report.json"
        ],
        phase="development",
        manifest=manifest,
    )
    assert "core_fast_external_source_generic_url" in {
        gate["name"] for gate in generic_url_audit_plan["selected_gates"]
    }
    assert "external_source_memory_verification" in generic_url_audit_plan["matched_rules"]

    platform_preflight_plan = build_validation_plan(
        ["heitang_kb_forge/external_sources/platform_preflight.py"],
        phase="development",
        manifest=manifest,
    )
    assert "core_fast_external_source_platform_preflight" in {
        gate["name"] for gate in platform_preflight_plan["selected_gates"]
    }
    assert "external_source_memory_verification" in platform_preflight_plan["matched_rules"]

    platform_preflight_audit_plan = build_validation_plan(
        [
            "artifacts/audits/section_5/external_source_platform_preflight/preflight/"
            "platform_preflight_report.json"
        ],
        phase="development",
        manifest=manifest,
    )
    assert "core_fast_external_source_platform_preflight" in {
        gate["name"] for gate in platform_preflight_audit_plan["selected_gates"]
    }
    assert "external_source_memory_verification" in platform_preflight_audit_plan["matched_rules"]

    opencli_plan = build_validation_plan(
        ["heitang_kb_forge/external_sources/opencli_adapter.py"],
        phase="development",
        manifest=manifest,
    )
    assert "core_fast_external_source_opencli_verification" in {
        gate["name"] for gate in opencli_plan["selected_gates"]
    }
    assert "external_source_memory_verification" in opencli_plan["matched_rules"]

    opencli_audit_plan = build_validation_plan(
        [
            "artifacts/audits/section_5/external_source_opencli_verification/"
            "external_verification_report.json"
        ],
        phase="development",
        manifest=manifest,
    )
    assert "core_fast_external_source_opencli_verification" in {
        gate["name"] for gate in opencli_audit_plan["selected_gates"]
    }
    assert "external_source_memory_verification" in opencli_audit_plan["matched_rules"]

    manual_evidence_plan = build_validation_plan(
        ["heitang_kb_forge/external_sources/manual_evidence.py"],
        phase="development",
        manifest=manifest,
    )
    assert "core_fast_external_source_manual_evidence" in {
        gate["name"] for gate in manual_evidence_plan["selected_gates"]
    }
    assert "external_source_memory_verification" in manual_evidence_plan["matched_rules"]

    manual_evidence_audit_plan = build_validation_plan(
        [
            "artifacts/audits/section_5/external_source_manual_evidence/"
            "manual_evidence_manifest.json"
        ],
        phase="development",
        manifest=manifest,
    )
    assert "core_fast_external_source_manual_evidence" in {
        gate["name"] for gate in manual_evidence_audit_plan["selected_gates"]
    }
    assert "external_source_manual_evidence" in manual_evidence_audit_plan["impacted_surfaces"]

    campaign_3_4_0_plan = build_validation_plan(
        [
            "docs/governance/"
            "CAMPAIGN_3_SUPPLEMENT_4_0_KNOWLEDGE_TO_SKILL_TEMPLATE_GENERATOR_PLAN.md"
        ],
        phase="development",
        manifest=manifest,
    )
    assert "core_fast_test_governance" in {
        gate["name"] for gate in campaign_3_4_0_plan["selected_gates"]
    }
    assert "test_governance" in campaign_3_4_0_plan["matched_rules"]

    campaign_3_4_0_skill_template_plan = build_validation_plan(
        ["heitang_kb_forge/campaign_3_closure/supplement_4_0_skill_template.py"],
        phase="development",
        manifest=manifest,
    )
    assert "core_fast_campaign_3_supplement_4_0_skill_template" in {
        gate["name"] for gate in campaign_3_4_0_skill_template_plan["selected_gates"]
    }
    assert "campaign_3_supplement_4_0_skill_template" in campaign_3_4_0_skill_template_plan[
        "matched_rules"
    ]

    campaign_3_4_0_skill_template_audit_plan = build_validation_plan(
        [
            "artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template/"
            "skill_template_draft.json"
        ],
        phase="development",
        manifest=manifest,
    )
    assert "core_fast_campaign_3_supplement_4_0_skill_template" in {
        gate["name"] for gate in campaign_3_4_0_skill_template_audit_plan["selected_gates"]
    }
    assert "campaign_3_supplement_4_0_skill_template" in campaign_3_4_0_skill_template_audit_plan[
        "matched_rules"
    ]

    campaign_1_2_3_closure_plan = build_validation_plan(
        ["docs/governance/CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md"],
        phase="development",
        manifest=manifest,
    )
    assert "core_fast_test_governance" in {
        gate["name"] for gate in campaign_1_2_3_closure_plan["selected_gates"]
    }
    assert "test_governance" in campaign_1_2_3_closure_plan["matched_rules"]
    assert "campaign_1_2_3_integrated_closure_sequence" in campaign_1_2_3_closure_plan[
        "impacted_surfaces"
    ]

    repository_public_surface_plan = build_validation_plan(
        ["docs/governance/REPOSITORY_PUBLIC_SURFACE_CLEANUP_RENAME_PUSH_TAG_SAFETY_GATE_PLAN.md"],
        phase="development",
        manifest=manifest,
    )
    assert "core_fast_test_governance" in {
        gate["name"] for gate in repository_public_surface_plan["selected_gates"]
    }
    assert "test_governance" in repository_public_surface_plan["matched_rules"]
    assert "repository_public_surface_cleanup_gate" in repository_public_surface_plan[
        "impacted_surfaces"
    ]


def test_unmatched_changes_fall_back_to_governance_gate():
    manifest = load_manifest(MANIFEST_PATH)
    plan = build_validation_plan(["tmp/manual_note.txt"], phase="development", manifest=manifest)

    assert [gate["name"] for gate in plan["selected_gates"]] == manifest["default_gates"]["development"]


def test_test_pruning_register_names_canonical_replacements():
    register = (ROOT / "docs" / "testing" / "TEST_PRUNING_REGISTER.md").read_text(encoding="utf-8")
    zh_register = (ROOT / "docs" / "testing" / "TEST_PRUNING_REGISTER.zh-CN.md").read_text(encoding="utf-8")

    for text in [register, zh_register]:
        assert "canonical" in text.lower()
        assert "exact" in text.lower()
        assert "replacement" in text.lower()
        assert "skipped" in text.lower()
        assert "passed" in text.lower()


def test_validation_report_schema_fields_remain_required():
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))

    assert manifest["reporting_policy"]["required_command_fields"] == [
        "command",
        "exit_code",
        "status",
        "log_path",
        "summary",
    ]


def test_post_codex_review_gate_is_finite_and_release_blocking():
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    review_gate = manifest["post_codex_review_gate"]

    assert set(review_gate["levels"]) == {"light", "medium", "full"}
    assert review_gate["levels"]["light"]["when"] == "after_each_task"
    assert review_gate["levels"]["medium"]["when"] == "after_phase_closure"
    assert review_gate["levels"]["full"]["when"] == "before_tag_or_release"
    assert "v4.2.0 tag" in review_gate["levels"]["full"]["required_before"]
    assert "P3 recorded as non-blocking backlog" in review_gate["stop_conditions"]
    assert "no release-blocking P0/P1/P2" in review_gate["release_rule"]

    for field in ["id", "severity", "surface", "file/path", "evidence", "impact", "recommended_fix", "blocks_release"]:
        assert field in review_gate["issue_schema"]


def test_execute_mode_returns_nonzero_when_any_gate_fails(monkeypatch):
    monkeypatch.setattr(gates, "load_manifest", lambda path: {"release_version": "v4.2.0"})
    monkeypatch.setattr(gates, "build_validation_plan", lambda changed_files, phase, manifest: {"selected_gates": []})
    monkeypatch.setattr(gates, "run_validation_plan", lambda plan, repo_root: {"results": [{"status": "failed"}]})

    assert gates.main(["--execute"]) == 1


def test_run_validation_plan_writes_per_gate_exit_code_and_result(tmp_path, monkeypatch):
    tests_dir = tmp_path / "tests"
    tests_dir.mkdir()
    (tests_dir / "test_fake.py").write_text("def test_fake():\n    assert True\n", encoding="utf-8")
    captured = {}

    def fake_run(command, cwd, shell, text, stdout, stderr):
        captured["command"] = command
        stdout.write("fake gate passed   \nsecond line\t\n")
        return SimpleNamespace(returncode=0)

    monkeypatch.setattr(gates.subprocess, "run", fake_run)
    plan = {
        "selected_gates": [
            {
                "name": "fake_gate",
                "command": "fake command",
                "working_directory": ".",
                "test_file_patterns": ["tests/test_*.py"],
                "log_path": "docs/audits/test_engineering/full_gate_logs/fake_gate.log",
            }
        ]
    }

    result = gates.run_validation_plan(plan, tmp_path)["results"][0]

    exit_code_path = tmp_path / "docs/audits/test_engineering/full_gate_logs/fake_gate.log.exitcode"
    result_path = tmp_path / "docs/audits/test_engineering/full_gate_logs/fake_gate.log.result.json"
    assert exit_code_path.read_text(encoding="utf-8").strip() == "0"
    assert json.loads(result_path.read_text(encoding="utf-8"))["exit_code"] == 0
    assert result["exit_code_path"] == "docs/audits/test_engineering/full_gate_logs/fake_gate.log.exitcode"
    assert captured["command"] == "fake command tests/test_fake.py"
    assert (tmp_path / result["log_path"]).read_text(encoding="utf-8") == "fake gate passed\nsecond line\n"
