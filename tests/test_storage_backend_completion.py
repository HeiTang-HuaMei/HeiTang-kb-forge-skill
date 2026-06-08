from heitang_kb_forge.pre_v4_p0 import run_storage_completion


def test_storage_backend_completion_keeps_local_workspace_default(tmp_path):
    report = run_storage_completion(tmp_path)

    assert report["status"] == "pass"
    assert report["local_workspace_implemented"] is True
    assert report["no_platform_hosted_user_data"] is True
    assert report["no_hidden_upload"] is True
    assert report["unsupported_external_storage_blocked_truthfully"] is True
