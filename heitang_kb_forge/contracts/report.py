from heitang_kb_forge.schemas.package_contract_schema import ContractCheckResult


def make_contract_report(result: ContractCheckResult) -> str:
    def lines(items: list[str]) -> str:
        return "\n".join(f"- {item}" for item in items) or "- None"

    return f"""# Contract Check Report

## Summary

- Contract version: {result.contract_version}
- Status: {result.status}

## Missing Required Files

{lines(result.missing_required_files)}

## Missing Conditional Files

{lines(result.missing_conditional_files)}

## Missing Manifest Fields

{lines(result.missing_manifest_fields)}

## Invalid Chunk Fields

{lines(result.invalid_chunk_fields)}

## Invalid Evidence Fields

{lines(result.invalid_evidence_fields)}

## Warnings

{lines(result.warnings)}

## Errors

{lines(result.errors)}
"""
