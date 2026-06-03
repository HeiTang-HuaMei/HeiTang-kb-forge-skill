AGENT_DESCRIPTIONS = {
    "generic_agent": "通用知识库问答助手",
    "product_manager_agent": "需求分析、PRD、竞品、指标、用户场景",
    "shopping_guide_agent": "商品知识、卖点、适用人群、推荐理由、对比建议",
    "education_tutor_agent": "知识讲解、学习路径、复习、错题、练习建议",
    "customer_service_agent": "FAQ、政策、流程、售后、边界说明",
    "interview_coach_agent": "模拟面试、追问、评分、答案优化",
    "operations_agent": "用户标签、触达策略、活动运营、转化路径",
    "book_marketing_agent": "图书营销、卖点提炼、传播素材、读者画像",
    "publisher_sales_agent": "出版社和书商 B 端销售、渠道话术、选品对比",
    "enterprise_kb_agent": "企业知识库、制度流程、内部问答、知识沉淀",
}

AGENT_OUTPUT_FILES = [
    "agent_profile.yaml",
    "system_prompt.md",
    "retrieval_config.yaml",
    "tools.yaml",
    "eval_cases.jsonl",
]


def validate_agent_type(agent_type: str) -> None:
    if agent_type not in AGENT_DESCRIPTIONS:
        raise ValueError(f"Unsupported agent type: {agent_type}")
