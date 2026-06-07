from heitang_kb_forge.retrieval.query_planning import (
    decompose_query,
    expand_query,
    generate_query_variants,
    normalize_query,
    rewrite_query,
)


def test_normalize_query_collapses_spacing_and_preserves_language():
    assert normalize_query("  pricing   revenue ?  ") == "pricing revenue?"
    assert normalize_query("  介绍   定价  流程  ") == "介绍 定价 流程"


def test_vague_query_rewrite_is_deterministic_and_traced():
    result = rewrite_query("summary")

    assert result["normalized_query"] == "summary"
    assert result["rewritten_query"] == "Summarize relevant evidence about summary from the knowledge package."
    assert result["rewrite_reason"] == "vague_query_grounded_summary"
    assert result["llm_used"] is False
    assert result["tests_require_real_llm_api_network"] is False


def test_keyword_and_domain_expansion_is_bounded_and_deduped():
    terms = expand_query("pricing revenue pricing", domain="finance")

    assert terms.count("pricing") == 1
    assert {"pricing", "price", "cost", "revenue", "income", "sales"}.issubset(set(terms))
    assert len(terms) <= 24


def test_compound_query_decomposition_adds_subquery_routes():
    subqueries = decompose_query("compare pricing and revenue vs margin")

    assert [item["query"] for item in subqueries] == ["pricing", "revenue", "margin"]
    assert all(item["reason"] == "compound_query_decomposition" for item in subqueries)
    assert all(item["route"] for item in subqueries)


def test_multi_turn_resolution_uses_explicit_context_only():
    without_context = rewrite_query("what about this")
    with_context = rewrite_query("what about this", conversation_context="pricing policy changed in Q4")

    assert without_context["rewrite_reason"] == "no_explicit_context_follow_up"
    assert with_context["rewrite_reason"] == "explicit_context_follow_up_resolution"
    assert "pricing policy changed in Q4" in with_context["rewritten_query"]
    assert with_context["conversation_context_used"] is True


def test_multi_query_generation_removes_duplicates_and_honors_max_rewrites():
    variants = generate_query_variants("pricing", domain="finance", max_rewrites=3)

    assert len(variants) <= 3
    assert len({item.lower() for item in variants}) == len(variants)
    assert variants[0] == "Summarize relevant evidence about pricing from the knowledge package."
