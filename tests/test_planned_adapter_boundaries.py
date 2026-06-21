from pathlib import Path

from heitang_kb_forge.workbench.external_capabilities import make_external_capability_bundle


ROOT = Path(__file__).resolve().parents[1]


def _json(name: str) -> dict:
    return make_external_capability_bundle(ROOT)[name]


def test_planned_adapter_registry_contains_no_ready_or_local_executable_entries():
    payload = _json("planned_adapter_registry.json")

    assert payload["entry_count"] >= 7
    assert payload["ready_count"] == 0
    assert payload["can_execute_locally_before_v4_count"] == 0
    for entry in payload["entries"]:
        assert "planned_adapter" in entry["contract_status"]
        assert entry["can_execute_locally_before_v4"] is False
        if "optional_runtime_adapter" in entry["contract_status"]:
            assert "optional_runtime_dependency_missing" in entry["blocked_reasons"]
        else:
            assert "planned_adapter_not_implemented" in entry["blocked_reasons"]


def test_future_adapter_registry_contains_no_ready_or_local_executable_entries():
    payload = _json("future_adapter_registry.json")

    assert payload["entry_count"] >= 3
    assert payload["ready_count"] == 0
    assert payload["can_execute_locally_before_v4_count"] == 0
    for entry in payload["entries"]:
        assert "future_adapter" in entry["contract_status"]
        assert entry["can_execute_locally_before_v4"] is False
        assert "future_adapter_after_v4" in entry["blocked_reasons"]
    assert "skill_prompt_generator" not in {entry["project_id"] for entry in payload["entries"]}
    assert "mmskills" not in {entry["project_id"] for entry in payload["entries"]}


def test_provider_boundary_report_keeps_provider_network_and_runtime_disabled():
    payload = _json("provider_boundary_report.json")
    entries = {entry["project_id"]: entry for entry in payload["entries"]}

    assert payload["provider_network_api_ready"] is False
    assert payload["n8n_bundled_runtime"] is False
    assert payload["anysearchskill_api_callable"] is True
    assert payload["anysearchskill_real_smoke_passed"] is True
    assert payload["n8n_workflow_export_ready"] is True
    assert payload["weknora_embedded"] is False
    assert payload["llm_wiki_memory_engine_implemented"] is False
    assert entries["n8n"]["requires_external_runtime"] is True
    assert entries["anysearchskill"]["requires_api_key"] is False
    assert entries["anysearchskill"]["requires_network"] is True
    assert entries["last30days_skill"]["requires_network"] is True
    for entry in entries.values():
        assert entry["can_execute_locally_before_v4"] is False


def test_verified_closure_entries_are_not_executable():
    projects = {project["project_id"]: project for project in _json("external_capability_registry.json")["projects"]}

    for project_id in ["seedance2_skill", "rtk"]:
        assert "needs_verification" not in projects[project_id]["contract_status"]
        assert "needs_verification" not in projects[project_id]["blocked_reasons"]
        assert projects[project_id]["executable_action"] is False
        assert projects[project_id]["can_execute_locally_before_v4"] is False


def test_provider_capability_status_is_user_facing_and_not_project_loading():
    payload = _json("provider_capability_status.json")

    assert payload["schema_version"] == "prd_v3_provider_capability_status.v2"
    assert payload["product_baseline_chain"] == "文档库 -> 知识库 -> 索引层 -> RAG -> 编排层 -> 文档/Skill/Agent/A2A"
    assert payload["user_concept_boundary"] == {
        "external_project_names_visible_in_normal_ui": False,
        "hot_swap_project_concept_visible": False,
        "unverified_entries_marked_ready": False,
        "planned_adapters_marked_ready": False,
        "okf_runtime_added": False,
    }
    assert payload["indefinite_reference_state_allowed"] is False
    assert payload["legacy_reference_only_contracts_are_trace_only"] is True
    assert payload["registry_entry_class_counts"] == {
        "capability_provider": 19,
        "template_asset": 6,
        "architecture_reference": 1,
    }
    assert payload["architecture_reference_status_counts"] == {
        "candidate_reference": 0,
        "absorbed_into_architecture": 26,
        "rejected_no_architecture_gain": 0,
        "deferred_with_blocker": 0,
    }
    assert payload["architecture_reference_resolution_policy"] == {
        "candidate_reference_allowed": False,
        "learning_note_only_allowed": False,
        "indefinite_reference_allowed": False,
        "absorbed_requires_parallel_architecture_delivery": True,
        "deferred_requires_named_blocker": True,
        "rejected_requires_rejection_reason": True,
    }
    assert payload["future_reference_resolution_count"] == 7
    assert payload["future_reference_class_counts"] == {
        "capability_provider": 0,
        "template_asset": 1,
        "architecture_reference": 6,
    }
    assert payload["future_reference_status_counts"] == {
        "candidate_reference": 0,
        "absorbed_into_architecture": 1,
        "rejected_no_architecture_gain": 4,
        "deferred_with_blocker": 2,
    }
    assert payload["capability_count"] >= 8
    assert payload["ready_for_user_selection_count"] == 0
    labels = [
        entry["user_visible_name"].lower()
        for entry in payload["capabilities"]
    ]
    forbidden = [
        "hot-swap",
        "external project",
        "llm wiki",
        "weknora",
        "anysearchskill",
        "n8n",
        "docling",
        "paddleocr",
        "unstructured",
    ]
    for label in labels:
        for term in forbidden:
            assert term not in label


def test_provider_capability_status_preserves_dependency_and_audit_boundaries():
    payload = _json("provider_capability_status.json")
    entries = {entry["capability_id"]: entry for entry in payload["capabilities"]}

    parser = entries["document_parser_ocr"]
    assert parser["status"] == "dependency_gated"
    assert parser["requires_dependency_install"] is True
    assert parser["ready_for_user_selection"] is False

    retrieval = entries["retrieval_provider"]
    assert retrieval["requires_network"] is True
    assert retrieval["ready_for_user_selection"] is False
    assert retrieval["status"] in {
        "dependency_gated",
        "needs_network_authorization",
        "needs_secret_config",
        "configured_not_tested",
    }

    exporter = entries["document_exporter"]
    assert exporter["requires_external_runtime"] is True
    assert exporter["ready_for_user_selection"] is False

    for entry in entries.values():
        assert entry["audit_event_required"] is True
        assert entry["rollback_supported"] is True
        assert entry["boundary"].startswith("User-facing capability status only.")
        for provider_state in entry["related_provider_states"]:
            assert provider_state["stage3_current_classification"] in {
                "capability_provider",
                "template_asset",
                "architecture_reference",
            }
            assert provider_state["registry_entry_class"] == provider_state["stage3_current_classification"]
            assert provider_state["architecture_reference_status"] in {
                "absorbed_into_architecture",
                "rejected_no_architecture_gain",
                "deferred_with_blocker",
            }
            assert provider_state["runtime_load_class"] in {
                "provider_capability_config_gated",
                "template_asset_manifest_only",
                "architecture_reference_no_runtime",
            }
            assert provider_state["ready_for_user_selection"] is False
            assert provider_state["audit_event_required"] is True
            assert provider_state["rollback_supported"] is True


def test_future_references_are_resolved_not_kept_as_notes():
    payload = _json("provider_capability_status.json")
    rows = {
        entry["project_id"]: entry
        for entry in payload["future_reference_resolutions"]
    }

    assert rows["andrej_karpathy_skills"]["architecture_reference_status"] == "absorbed_into_architecture"
    assert rows["andrej_karpathy_skills"]["registry_entry_class"] == "template_asset"
    assert rows["andrej_karpathy_skills"]["architecture_delivery_required"] is True
    assert set(rows["andrej_karpathy_skills"]["absorbed_targets"]) == {
        "contract",
        "schema",
        "runtime_boundary",
        "ui_information_architecture",
        "test_gate",
        "audit_model",
        "fallback_strategy",
        "provider_loading_rule",
    }

    for project_id in ["presenton", "pi_mono"]:
        row = rows[project_id]
        assert row["architecture_reference_status"] == "deferred_with_blocker"
        assert row["blocker"]
        assert row["rejection_reason"] == ""
        assert row["runtime_dependency_added"] is False
        assert row["normal_ui_visible"] is False

    for project_id in [
        "codegraph",
        "understand_anything",
        "nvlabs_longlive",
        "claude_plugins_official",
    ]:
        row = rows[project_id]
        assert row["architecture_reference_status"] == "rejected_no_architecture_gain"
        assert row["rejection_reason"]
        assert row["blocker"] == ""
        assert row["runtime_dependency_added"] is False
        assert row["normal_ui_visible"] is False

    for row in rows.values():
        assert row["learning_note_only"] is False
        assert row["indefinite_reference_allowed"] is False
        assert row["architecture_reference_status"] != "candidate_reference"
