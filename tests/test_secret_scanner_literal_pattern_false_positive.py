from heitang_kb_forge.product_hardening.hardening import _secret_line_hits


def test_literal_scanner_patterns_are_not_secret_hits():
    text = 'SECRET_PATTERNS = ["api_key: sk-", "secret_key:", "client_secret:", "sk-live-", "sk-proj-"]'

    assert _secret_line_hits(text) == []


def test_realistic_fake_key_shape_is_detected_and_redacted():
    fake_key = "sk-" + "realisticfake1234567890"
    hits = _secret_line_hits("api_key: " + fake_key)

    assert hits
    assert fake_key not in hits[0]["preview"]
    assert "<redacted>" in hits[0]["preview"]
