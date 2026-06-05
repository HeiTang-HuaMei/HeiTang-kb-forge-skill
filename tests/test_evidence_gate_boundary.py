from heitang_kb_forge.evidence_gate.boundary import judge_boundary


def test_boundary_marks_outside_query_without_overlap():
    result = judge_boundary("outside weather", [{"text": "HeiTang evidence package"}])

    assert result["boundary"] == "outside"
