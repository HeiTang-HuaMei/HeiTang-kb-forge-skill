from pydantic import BaseModel, Field


class LangChainDocument(BaseModel):
    page_content: str
    metadata: dict = Field(default_factory=dict)


class LlamaIndexDocument(BaseModel):
    text: str
    metadata: dict = Field(default_factory=dict)
    doc_id: str
