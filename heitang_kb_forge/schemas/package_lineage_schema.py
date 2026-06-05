from pydantic import BaseModel, Field


class PackageVersionNode(BaseModel):
    package_id: str
    package_version: str
    package_path: str
    created_at: str
    status: str = "active"


class PackageVersionEdge(BaseModel):
    from_package: str
    to_package: str
    relationship: str = "updated_from"


class PackageVersionGraph(BaseModel):
    nodes: list[PackageVersionNode] = Field(default_factory=list)
    edges: list[PackageVersionEdge] = Field(default_factory=list)
