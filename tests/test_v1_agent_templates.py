import pytest

from heitang_kb_forge.agent.generator import _role_focus
from heitang_kb_forge.agent.templates import AGENT_DESCRIPTIONS, validate_agent_type


def test_v1_agent_templates_are_available_and_distinct():
    for agent_type in ["book_marketing_agent", "publisher_sales_agent", "enterprise_kb_agent"]:
        validate_agent_type(agent_type)
        assert agent_type in AGENT_DESCRIPTIONS
        assert _role_focus(agent_type)

    assert _role_focus("book_marketing_agent") != _role_focus("publisher_sales_agent")


def test_unsupported_agent_type_still_errors():
    with pytest.raises(ValueError, match="Unsupported agent type"):
        validate_agent_type("unknown_v1_agent")
