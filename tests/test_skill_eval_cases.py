from heitang_kb_forge.skill.examples import make_examples
from tests.v17_helpers import write_sample_package


def test_skill_eval_cases_are_generated_from_qa_pairs(tmp_path):
    package = write_sample_package(tmp_path / "package")

    examples, cases = make_examples(package)

    assert cases
    assert "Examples" in examples
