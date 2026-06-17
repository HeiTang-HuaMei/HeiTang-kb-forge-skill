import importlib.util
import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "agent_chat.py"
SPEC = importlib.util.spec_from_file_location("agent_chat", SCRIPT)
agent_chat = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(agent_chat)


def _completed(args, returncode=0, stdout="", stderr=""):
    return subprocess.CompletedProcess(args, returncode, stdout=stdout, stderr=stderr)


class FakeGit:
    def __init__(self, jsonl="", ref_exists=True, remote_exists=True):
        self.jsonl = jsonl
        self.ref_exists = ref_exists
        self.remote_exists = remote_exists
        self.commands = []
        self.next_commit = "c" * 40

    def __call__(self, args, *, input_text=None, check=True):
        self.commands.append((args, input_text))
        if args[:3] == ["fetch", "--no-tags", "origin"]:
            if self.remote_exists:
                return _completed(args)
            return _completed(args, 128, stderr="fatal: couldn't find remote ref")
        if args[:2] == ["rev-parse", "--verify"]:
            if args[2] == agent_chat.FETCH_HEAD and self.remote_exists:
                return _completed(args, stdout="a" * 40 + "\n")
            if args[2] == agent_chat.CHAT_REF and self.ref_exists:
                return _completed(args, stdout="a" * 40 + "\n")
            return _completed(args, 1, stderr="missing")
        if args[:1] == ["show"]:
            if (args[1].startswith(agent_chat.CHAT_REF) and self.ref_exists) or (
                args[1].startswith(agent_chat.FETCH_HEAD) and self.remote_exists
            ):
                return _completed(args, stdout=self.jsonl)
            return _completed(args, 128, stderr="missing")
        if args[:3] == ["hash-object", "-w", "--stdin"]:
            self.jsonl = input_text
            return _completed(args, stdout="b" * 40 + "\n")
        if args[:1] == ["mktree"]:
            assert "agent_chat.jsonl" in input_text
            return _completed(args, stdout="d" * 40 + "\n")
        if args[:1] == ["commit-tree"]:
            return _completed(args, stdout=self.next_commit + "\n")
        if args[:1] == ["update-ref"]:
            assert args[1] == agent_chat.CHAT_REF
            assert len(args) == 3
            self.ref_exists = True
            return _completed(args)
        if args[:1] == ["push"]:
            assert args == ["push", "origin", f"{agent_chat.CHAT_REF}:{agent_chat.CHAT_REF}"]
            return _completed(args)
        raise AssertionError(f"unexpected git command: {args}")


def _message(message_id="msg_000001", message_type="review", reply_to=None, body="hello"):
    return {
        "id": message_id,
        "from": "claude-code",
        "type": message_type,
        "reply_to": reply_to,
        "body": body,
    }


def test_empty_ref_chat(monkeypatch, capsys):
    fake = FakeGit(ref_exists=False, remote_exists=False)
    monkeypatch.setattr(agent_chat, "run_git", fake)

    exit_code = agent_chat.main(["chat"])

    assert exit_code == 0
    assert capsys.readouterr().out.strip() == "empty chat"


def test_append_message(monkeypatch):
    fake = FakeGit(jsonl="", ref_exists=False, remote_exists=False)
    monkeypatch.setattr(agent_chat, "run_git", fake)

    message = agent_chat.send_message(
        sender="codex",
        message_type="review",
        reply_to=None,
        body="review bus ready",
    )

    stored = [json.loads(line) for line in fake.jsonl.splitlines()]
    assert message["id"] == "msg_000001"
    assert stored[0]["body"] == "review bus ready"
    assert stored[0]["reply_to"] is None
    assert stored[0]["type"] == "review"


def test_id_increments(monkeypatch):
    existing = json.dumps(_message("msg_000001")) + "\n"
    fake = FakeGit(jsonl=existing)
    monkeypatch.setattr(agent_chat, "run_git", fake)

    message = agent_chat.send_message(
        sender="codex",
        message_type="done",
        reply_to="msg_000001",
        body="fixed",
    )

    assert message["id"] == "msg_000002"
    stored = [json.loads(line) for line in fake.jsonl.splitlines()]
    assert [item["id"] for item in stored] == ["msg_000001", "msg_000002"]


def test_type_validation():
    messages = [_message(message_type="question")]

    errors = agent_chat.validate_messages(messages)

    assert any("type must be one of" in error for error in errors)


def test_reply_to_validation():
    messages = [_message("msg_000002", message_type="done", reply_to="msg_000001")]

    errors = agent_chat.validate_messages(messages)

    assert any("reply_to msg_000001 does not exist" in error for error in errors)


def test_secret_scan():
    suspect_body = "api_" + "key = " + '"1234567890123456"'
    messages = [_message(body=suspect_body)]

    errors = agent_chat.validate_messages(messages)

    assert any("appears to contain a secret" in error for error in errors)


def test_validate_jsonl():
    text = "\n".join(
        [
            json.dumps(_message("msg_000001")),
            json.dumps(_message("msg_000002", message_type="done", reply_to="msg_000001")),
        ]
    )

    messages, errors = agent_chat.validate_jsonl(text)

    assert errors == []
    assert [message["id"] for message in messages] == ["msg_000001", "msg_000002"]


def test_no_branch_pollution(monkeypatch):
    fake = FakeGit(jsonl="")
    monkeypatch.setattr(agent_chat, "run_git", fake)

    agent_chat.send_message(sender="codex", message_type="review", reply_to=None, body="ready")

    flattened = [" ".join(args) for args, _input in fake.commands]
    forbidden = ["branch", "checkout", "switch"]
    assert not any(command.startswith(word) or f" {word} " in command for command in flattened for word in forbidden)


def test_no_force_push_command_usage(monkeypatch):
    fake = FakeGit(jsonl="")
    monkeypatch.setattr(agent_chat, "run_git", fake)

    agent_chat.send_message(sender="codex", message_type="review", reply_to=None, body="ready")

    flattened = [" ".join(args) for args, _input in fake.commands]
    assert not any("--force" in command or "+refs/" in command for command in flattened)
