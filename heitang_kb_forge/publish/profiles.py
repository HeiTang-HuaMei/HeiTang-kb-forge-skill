import shutil
from pathlib import Path

PUBLISH_OUTPUT_FILES = ["export_profile.yaml", "publish_manifest.json"]
SUPPORTED_PROFILES = {
    "generic_rag": ["generic_rag_package.json", "embedding_input.jsonl", "retrieval_metadata.jsonl"],
    "langchain": ["langchain_documents.jsonl"],
    "llamaindex": ["llamaindex_documents.jsonl"],
    "openai_files": ["openai_files_manifest.json"],
    "dify_import": ["embedding_input.jsonl", "citation_map.json"],
    "fastgpt_import": ["embedding_input.jsonl", "retrieval_metadata.jsonl"],
    "coze_knowledge": ["embedding_input.jsonl", "citation_map.json"],
}


def make_publish_package(package: Path, profile: str, output: Path) -> tuple[str, dict]:
    if profile not in SUPPORTED_PROFILES:
        raise ValueError(f"Unsupported publish profile: {profile}")
    publish_dir = output / "publish_package"
    publish_dir.mkdir(parents=True, exist_ok=True)
    copied = []
    missing = []
    for name in SUPPORTED_PROFILES[profile]:
        source = package / name
        if source.exists():
            shutil.copy2(source, publish_dir / name)
            copied.append(name)
        else:
            missing.append(name)
    profile_yaml = f"""profile: {profile}
target: {profile}
remote_publish_performed: false
notes:
  - This package is generated for import/adaptation only.
  - No platform API was called.
"""
    manifest = {
        "publish_version": "1.2.0",
        "profile": profile,
        "package": str(package).replace("\\", "/"),
        "publish_package": str(publish_dir).replace("\\", "/"),
        "copied_files": copied,
        "missing_files": missing,
        "remote_publish_performed": False,
    }
    return profile_yaml, manifest
