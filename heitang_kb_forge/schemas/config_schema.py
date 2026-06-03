from pathlib import Path

from pydantic import BaseModel, Field


class BatchConfig(BaseModel):
    merge_same_sequence: bool = False


class LLMConfig(BaseModel):
    enabled: bool = False
    provider: str = "fake"
    model: str = "fake-model"
    cache: bool = True
    strict: bool = False


class RAGConfig(BaseModel):
    enabled: bool = False
    profile: str = "basic"
    include_llm: bool = False


class AgentConfig(BaseModel):
    enabled: bool = False
    type: str = "generic_agent"
    name: str | None = None
    language: str = "zh-CN"


class DemoConfig(BaseModel):
    enabled: bool = False


class ForgeConfig(BaseModel):
    task: str
    input: Path
    output: Path
    domain: str = "general"
    mode: str = "reference"
    max_chars: int = 1200
    overlap_chars: int = 120
    batch: BatchConfig = Field(default_factory=BatchConfig)
    llm: LLMConfig = Field(default_factory=LLMConfig)
    rag: RAGConfig = Field(default_factory=RAGConfig)
    agent: AgentConfig = Field(default_factory=AgentConfig)
    demo: DemoConfig = Field(default_factory=DemoConfig)
