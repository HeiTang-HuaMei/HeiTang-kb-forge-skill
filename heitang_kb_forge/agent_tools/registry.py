from heitang_kb_forge.schemas.agent_tool_schema import AgentTool


TOOL_NAMES = [
    "build_knowledge_package",
    "batch_build_packages",
    "check_source_changes",
    "run_incremental_update",
    "validate_package_quality",
    "import_package_to_store",
    "retrieve_knowledge",
    "ask_package",
    "publish_package",
    "generate_planning_readiness",
]


def list_agent_tools() -> list[AgentTool]:
    return [
        AgentTool(
            name=name,
            description=_description(name),
            input_schema=_input_schema(name),
            output_schema={"type": "object"},
            safety_notes=[
                "Local execution only.",
                "No external API calls are performed by the registry.",
                "Callers must provide explicit paths.",
            ],
        )
        for name in TOOL_NAMES
    ]


def get_agent_tool(name: str) -> AgentTool:
    for tool in list_agent_tools():
        if tool.name == name:
            return tool
    raise ValueError(f"Unknown tool: {name}")


def _description(name: str) -> str:
    descriptions = {
        "build_knowledge_package": "Build one standard knowledge package from local sources.",
        "batch_build_packages": "Build multiple numbered knowledge packages.",
        "check_source_changes": "Check source registry changes for a package.",
        "run_incremental_update": "Run lifecycle incremental update reporting.",
        "validate_package_quality": "Validate package quality and readiness.",
        "import_package_to_store": "Import a package into the local SQLite store.",
        "retrieve_knowledge": "Retrieve local knowledge records with citations.",
        "ask_package": "Answer from a package with local cited context.",
        "publish_package": "Generate local publish package artifacts.",
        "generate_planning_readiness": "Generate planning readiness artifacts.",
    }
    return descriptions[name]


def _input_schema(name: str) -> dict:
    common_path = {"type": "string", "description": "Local filesystem path."}
    if name == "retrieve_knowledge":
        return {
            "type": "object",
            "properties": {
                "package": common_path,
                "store": common_path,
                "query": {"type": "string"},
                "top_k": {"type": "integer", "default": 5},
            },
            "required": ["query"],
        }
    return {"type": "object", "properties": {"input": common_path, "output": common_path}}
