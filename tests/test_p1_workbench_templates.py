from heitang_kb_forge.workbench import make_p1_workbench_bundle


def test_p1_workbench_template_registry_contains_required_templates():
    templates = make_p1_workbench_bundle().template_registry

    assert {template.title for template in templates} == {
        "产品经理知识库模板",
        "图书/出版社知识库模板",
        "企业制度知识库模板",
        "教育伴学模板",
        "导购/运营 Agent 模板",
        "软件说明书 / 操作 Skill 模板",
    }


def test_p1_workbench_templates_include_required_product_fields():
    bundle = make_p1_workbench_bundle()
    report_ids = {report.report_id for report in bundle.report_registry}

    for template in bundle.template_registry:
        assert template.use_case
        assert template.recommended_inputs
        assert template.chunk_strategy
        assert template.metadata_rules
        assert template.retrieval_strategy
        assert template.skill_output_structure
        assert template.agent_config
        assert template.evaluation_questions
        assert set(template.example_reports) <= report_ids
        assert template.p1_ready is True
        assert template.blocked_reason is None
