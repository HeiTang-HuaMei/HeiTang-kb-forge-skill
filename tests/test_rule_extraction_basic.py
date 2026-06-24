from heitang_kb_forge.rule_extraction import extract_rules


def test_rule_extraction_finds_requirement_prohibition_boundary_and_citation_rules():
    report = extract_rules(
        {
            "sources": [
                {
                    "source_id": "policy-a",
                    "source_path": "policy.md",
                    "scope_id": "kb-public",
                    "text": "\n".join(
                        [
                            "- Answers must cite package evidence.",
                            "- Do not invent citations.",
                            "- Stay within scope.",
                            "- Include source_path when making factual claims.",
                        ]
                    ),
                }
            ]
        }
    )

    assert report.status == "rules_extracted"
    assert report.extracted_rule_count == 4
    assert [rule.rule_type for rule in report.extracted_rules] == [
        "requirement",
        "prohibition",
        "boundary",
        "citation",
    ]
    assert report.extracted_rules[0].source_id == "policy-a"


def test_rule_extraction_filters_out_disallowed_scope():
    report = extract_rules(
        {
            "allowed_scope_ids": ["kb-public"],
            "sources": [
                {
                    "source_id": "public",
                    "scope_id": "kb-public",
                    "text": "Rules must stay auditable.",
                },
                {
                    "source_id": "secret",
                    "scope_id": "kb-secret",
                    "text": "Secret rules must not leak.",
                },
            ],
        }
    )

    assert report.extracted_rule_count == 1
    assert report.extracted_rules[0].source_id == "public"
    assert report.skipped_source_ids == ["secret"]


def test_rule_extraction_reports_no_rules_found_for_plain_text():
    report = extract_rules({"sources": [{"source_id": "plain", "text": "A neutral paragraph."}]})

    assert report.status == "no_rules_found"
    assert report.extracted_rule_count == 0
