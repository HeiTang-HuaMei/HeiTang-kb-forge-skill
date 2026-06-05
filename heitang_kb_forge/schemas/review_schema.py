from pydantic import BaseModel


class ReviewWorkflowItem(BaseModel):
    review_id: str
    item_type: str
    item_id: str
    severity: str
    status: str
