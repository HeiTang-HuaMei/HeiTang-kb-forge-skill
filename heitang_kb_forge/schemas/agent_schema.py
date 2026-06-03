from pydantic import BaseModel, Field


class AgentOptions(BaseModel):
    enabled: bool = False
    agent_type: str = "generic_agent"
    agent_name: str | None = None
    language: str = "zh-CN"


class EvalCase(BaseModel):
    eval_id: str
    question: str
    expected_behavior: str
    required_citation: str
    source_path: str
    chunk_id: str
    agent_type: str


class AgentTemplateResult(BaseModel):
    output_files: list[str]
    agent_profile: str
    system_prompt: str
    retrieval_config: str
    tools: str
    eval_cases: list[EvalCase] = Field(default_factory=list)
