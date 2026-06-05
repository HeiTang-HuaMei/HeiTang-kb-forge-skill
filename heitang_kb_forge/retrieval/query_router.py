import re


def route_query(query: str) -> str:
    text = query.lower()
    if any(word in text for word in ["compare", "difference", "对比", "区别"]):
        return "comparison"
    if any(word in text for word in ["how", "steps", "流程", "步骤", "如何"]):
        return "process"
    if any(word in text for word in ["what is", "define", "是什么", "定义"]):
        return "definition"
    if any(word in text for word in ["evidence", "source", "依据", "来源"]):
        return "evidence"
    if not re.findall(r"[\w\u4e00-\u9fff]+", text):
        return "unknown"
    return "summary"
