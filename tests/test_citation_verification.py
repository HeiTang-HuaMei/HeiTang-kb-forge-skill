from heitang_kb_forge.citation_verification import verify_citations


def test_citation_verification_reports_missing_unresolved_and_out_of_scope():
    report = verify_citations(
        {
            "allowed_scope_ids": ["kb-a"],
            "claims": [
                {"claim_id": "claim-1", "text": "covered", "citation": "source-a.md#chunk=chunk-1"},
                {"claim_id": "claim-2", "text": "missing"},
                {"claim_id": "claim-3", "text": "unresolved", "citation": "source-z.md#chunk=chunk-z"},
                {"claim_id": "claim-4", "text": "wrong scope", "citation": "source-b.md#chunk=chunk-2"},
            ],
            "source_trace": [
                {
                    "source_id": "source-a",
                    "source_path": "source-a.md",
                    "chunk_id": "chunk-1",
                    "citation": "source-a.md#chunk=chunk-1",
                    "scope_id": "kb-a",
                },
                {
                    "source_id": "source-b",
                    "source_path": "source-b.md",
                    "chunk_id": "chunk-2",
                    "citation": "source-b.md#chunk=chunk-2",
                    "scope_id": "kb-b",
                },
            ],
        }
    )

    assert report.status == "citation_gaps_found"
    assert report.resolved_claim_ids == ["claim-1"]
    assert report.missing_citation_claim_ids == ["claim-2"]
    assert report.unresolved_citation_claim_ids == ["claim-3"]
    assert report.out_of_scope_claim_ids == ["claim-4"]
    assert report.citation_coverage == 0.25


def test_citation_verification_passes_when_all_claims_resolve_in_scope():
    report = verify_citations(
        {
            "allowed_scope_ids": ["kb-a"],
            "claims": [
                {"claim_id": "claim-1", "text": "covered", "citation": "source-a.md#chunk=chunk-1"},
                {"claim_id": "claim-2", "text": "also covered", "citation": "source-a.md#chunk=chunk-2"},
            ],
            "source_trace": [
                {
                    "source_id": "source-a-1",
                    "source_path": "source-a.md",
                    "chunk_id": "chunk-1",
                    "citation": "source-a.md#chunk=chunk-1",
                    "scope_id": "kb-a",
                },
                {
                    "source_id": "source-a-2",
                    "source_path": "source-a.md",
                    "chunk_id": "chunk-2",
                    "citation": "source-a.md#chunk=chunk-2",
                    "scope_id": "kb-a",
                },
            ],
        }
    )

    assert report.status == "pass"
    assert report.resolved_claim_count == 2
    assert report.citation_coverage == 1.0
