from pydantic import BaseModel


class SourceInventoryItem(BaseModel):
    source_id: str
    source_file: str
    source_type: str
    file_hash: str
    file_size: int
    parser: str
    parser_version: str = "2.1"
    parse_status: str
    error_type: str = ""
    warning_count: int = 0
    chunk_count: int = 0
    table_count: int = 0
    asset_count: int = 0
    created_at: str
