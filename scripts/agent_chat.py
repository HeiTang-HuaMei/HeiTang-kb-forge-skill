#!/usr/bin/env python3
"""Git-ref backed review bus for Claude Code and Codex."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


CHAT_REF = "refs/agent-chat/kb-forge"
CHAT_FILE = "agent_chat.jsonl"
FETCH_HEAD = "FETCH_HEAD"
ALLOWED_TYPES = {"review", "risk", "done"}
MAX_BODY_CHARS = 4000
ZERO_OID = "0" * 40

SECRET_PATTERNS = [
    re.compile(r"sk-[A-Za-z0-9]{20,}"),
    re.compile(r"ghp_[A-Za-z0-9_]{20,}"),
    re.compile(r"github_pat_[A-Za-z0-9_]{20,}"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
    re.compile(
        r"(?i)\b(api[_-]?key|token|secret|password)\b\s*[:=]\s*['\"]?[A-Za-z0-9_./+=-]{16,}"
    ),
]


class AgentChatError(Exception):
    """User-facing command failure."""


def run_git(
    args: list[str],
    *,
    input_text: str | None = None,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        ["git", *args],
        input=input_text,
        text=True,
        capture_output=True,
    )
    if check and result.returncode != 0:
        detail = (result.stderr or result.stdout or "").strip()
        raise AgentChatError(f"git {' '.join(args)} failed: {detail}")
    return result


def resolve_ref(ref: str = CHAT_REF) -> str | None:
    result = run_git(["rev-parse", "--verify", ref], check=False)
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def read_ref_jsonl(ref: str | None = CHAT_REF) -> str:
    if ref is None or resolve_ref(ref) is None:
        return ""
    result = run_git(["show", f"{ref}:{CHAT_FILE}"], check=False)
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or "").strip()
        raise AgentChatError(f"{ref} exists but {CHAT_FILE} cannot be read: {detail}")
    return result.stdout


def parse_jsonl(text: str) -> tuple[list[dict[str, Any]], list[str]]:
    messages: list[dict[str, Any]] = []
    errors: list[str] = []
    for line_number, raw_line in enumerate(text.splitlines(), start=1):
        line = raw_line.strip()
        if not line:
            continue
        try:
            item = json.loads(line)
        except json.JSONDecodeError as exc:
            errors.append(f"line {line_number}: invalid JSON: {exc.msg}")
            continue
        if not isinstance(item, dict):
            errors.append(f"line {line_number}: message must be a JSON object")
            continue
        messages.append(item)
    return messages, errors


def _looks_secret(value: str) -> bool:
    return any(pattern.search(value) for pattern in SECRET_PATTERNS)


def _message_strings(message: dict[str, Any]) -> list[tuple[str, str]]:
    values: list[tuple[str, str]] = []
    for key, value in message.items():
        if isinstance(value, str):
            values.append((key, value))
    return values


def validate_messages(messages: list[dict[str, Any]]) -> list[str]:
    errors: list[str] = []
    seen_ids: set[str] = set()
    all_ids: set[str] = set()

    for index, message in enumerate(messages, start=1):
        prefix = f"message {index}"
        for field in ("id", "from", "type", "reply_to"):
            if field not in message:
                errors.append(f"{prefix}: missing required field {field}")

        message_id = message.get("id")
        if not isinstance(message_id, str) or not message_id.strip():
            errors.append(f"{prefix}: id must be a non-empty string")
        elif message_id in seen_ids:
            errors.append(f"{prefix}: duplicate id {message_id}")
        else:
            seen_ids.add(message_id)
            all_ids.add(message_id)

        sender = message.get("from")
        if not isinstance(sender, str) or not sender.strip():
            errors.append(f"{prefix}: from must be a non-empty string")

        message_type = message.get("type")
        if message_type not in ALLOWED_TYPES:
            allowed = ", ".join(sorted(ALLOWED_TYPES))
            errors.append(f"{prefix}: type must be one of {allowed}")

        reply_to = message.get("reply_to")
        if reply_to is not None and (not isinstance(reply_to, str) or not reply_to.strip()):
            errors.append(f"{prefix}: reply_to must be null or a non-empty string")

        body = message.get("body")
        if body is not None:
            if not isinstance(body, str):
                errors.append(f"{prefix}: body must be a string")
            elif len(body) > MAX_BODY_CHARS:
                errors.append(f"{prefix}: body exceeds {MAX_BODY_CHARS} characters")

        for key, value in _message_strings(message):
            if _looks_secret(value):
                errors.append(f"{prefix}: {key} appears to contain a secret")

    for index, message in enumerate(messages, start=1):
        reply_to = message.get("reply_to")
        if isinstance(reply_to, str) and reply_to not in all_ids:
            errors.append(f"message {index}: reply_to {reply_to} does not exist")

    return errors


def validate_jsonl(text: str) -> tuple[list[dict[str, Any]], list[str]]:
    messages, parse_errors = parse_jsonl(text)
    return messages, [*parse_errors, *validate_messages(messages)]


def next_message_id(messages: list[dict[str, Any]]) -> str:
    highest = 0
    for message in messages:
        message_id = message.get("id")
        if not isinstance(message_id, str):
            continue
        match = re.fullmatch(r"msg_(\d{6})", message_id)
        if match:
            highest = max(highest, int(match.group(1)))
    return f"msg_{highest + 1:06d}"


def build_message(
    *,
    sender: str,
    message_type: str,
    reply_to: str | None,
    body: str,
    commit: str | None = None,
    target: str | None = None,
    status: str | None = None,
    messages: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    if not sender or not sender.strip():
        raise AgentChatError("--from must be a non-empty string")
    if message_type not in ALLOWED_TYPES:
        allowed = ", ".join(sorted(ALLOWED_TYPES))
        raise AgentChatError(f"--type must be one of {allowed}")
    if reply_to is not None and not reply_to.strip():
        raise AgentChatError("--reply-to must be omitted, null, or a non-empty id")
    if not body or not body.strip():
        raise AgentChatError("--body must be a non-empty string")
    if len(body) > MAX_BODY_CHARS:
        raise AgentChatError(f"--body exceeds {MAX_BODY_CHARS} characters")
    if _looks_secret(body):
        raise AgentChatError("--body appears to contain a secret")

    current_messages = messages or []
    message: dict[str, Any] = {
        "id": next_message_id(current_messages),
        "from": sender.strip(),
        "type": message_type,
        "reply_to": reply_to,
        "body": body,
        "ts": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    }
    for key, value in (("commit", commit), ("target", target), ("status", status)):
        if value is not None and value != "":
            if _looks_secret(value):
                raise AgentChatError(f"--{key} appears to contain a secret")
            message[key] = value
    return message


def render_jsonl(messages: list[dict[str, Any]]) -> str:
    if not messages:
        return ""
    lines = [json.dumps(message, ensure_ascii=False, separators=(",", ":")) for message in messages]
    return "\n".join(lines) + "\n"


def fetch_latest_ref() -> tuple[str | None, str | None]:
    result = run_git(["fetch", "--no-tags", "origin", CHAT_REF], check=False)
    if result.returncode == 0:
        oid = resolve_ref(FETCH_HEAD)
        if oid is None:
            raise AgentChatError("fetch succeeded but FETCH_HEAD could not be resolved")
        return oid, FETCH_HEAD

    detail = (result.stderr or result.stdout or "").lower()
    if "couldn't find remote ref" in detail or "could not find remote ref" in detail:
        local_oid = resolve_ref(CHAT_REF)
        return local_oid, CHAT_REF if local_oid is not None else None

    raise AgentChatError(
        "failed to fetch latest chat ref; run chat/validate, fetch, then retry. "
        "The tool will not overwrite the remote ref."
    )


def write_chat_commit(jsonl_text: str, parent_oid: str | None) -> str:
    blob_oid = run_git(["hash-object", "-w", "--stdin"], input_text=jsonl_text).stdout.strip()
    tree_input = f"100644 blob {blob_oid}\t{CHAT_FILE}\n"
    tree_oid = run_git(["mktree"], input_text=tree_input).stdout.strip()
    args = ["commit-tree", tree_oid, "-m", "agent chat update"]
    if parent_oid is not None:
        args[2:2] = ["-p", parent_oid]
    return run_git(args).stdout.strip()


def update_local_ref(new_oid: str) -> None:
    run_git(["update-ref", CHAT_REF, new_oid])


def push_chat_ref() -> None:
    result = run_git(["push", "origin", f"{CHAT_REF}:{CHAT_REF}"], check=False)
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or "").strip()
        raise AgentChatError(
            "push rejected or failed; fetch the latest chat ref and retry. "
            f"Remote was not overwritten. Detail: {detail}"
        )


def send_message(
    *,
    sender: str,
    message_type: str,
    reply_to: str | None,
    body: str,
    commit: str | None = None,
    target: str | None = None,
    status: str | None = None,
) -> dict[str, Any]:
    old_oid, source_ref = fetch_latest_ref()
    current_text = read_ref_jsonl(source_ref)
    messages, errors = validate_jsonl(current_text)
    if errors:
        raise AgentChatError("existing chat ref is invalid:\n" + "\n".join(errors))

    message = build_message(
        sender=sender,
        message_type=message_type,
        reply_to=reply_to,
        body=body,
        commit=commit,
        target=target,
        status=status,
        messages=messages,
    )
    updated_messages = [*messages, message]
    errors = validate_messages(updated_messages)
    if errors:
        raise AgentChatError("new message is invalid:\n" + "\n".join(errors))

    new_oid = write_chat_commit(render_jsonl(updated_messages), old_oid)
    update_local_ref(new_oid)
    push_chat_ref()
    return message


def _coerce_reply_to(value: str | None) -> str | None:
    if value is None:
        return None
    if value.lower() == "null":
        return None
    return value


def _print_chat(messages: list[dict[str, Any]], *, as_json: bool) -> None:
    if as_json:
        print(json.dumps(messages, ensure_ascii=False, indent=2))
        return
    if not messages:
        print("empty chat")
        return
    for message in messages:
        reply = message.get("reply_to")
        reply_label = reply if reply is not None else "null"
        header = f"{message.get('id')} {message.get('type')} from={message.get('from')} reply_to={reply_label}"
        extras = []
        for key in ("status", "target", "commit", "ts"):
            if message.get(key):
                extras.append(f"{key}={message[key]}")
        if extras:
            header = f"{header} {' '.join(extras)}"
        print(header)
        body = message.get("body")
        if body:
            print(f"  {body}")


def cmd_chat(args: argparse.Namespace) -> int:
    text = read_ref_jsonl(CHAT_REF)
    messages, errors = validate_jsonl(text)
    if errors:
        raise AgentChatError("chat ref is invalid:\n" + "\n".join(errors))
    limit = args.limit
    if limit < 1:
        raise AgentChatError("--limit must be greater than 0")
    _print_chat(messages[-limit:], as_json=args.json)
    return 0


def cmd_send(args: argparse.Namespace) -> int:
    message = send_message(
        sender=args.sender,
        message_type=args.message_type,
        reply_to=_coerce_reply_to(args.reply_to),
        body=args.body,
        commit=args.commit,
        target=args.target,
        status=args.status,
    )
    print(f"sent {message['id']}")
    return 0


def cmd_validate(args: argparse.Namespace) -> int:
    if args.file:
        text = Path(args.file).read_text(encoding="utf-8")
    else:
        text = read_ref_jsonl(CHAT_REF)
    messages, errors = validate_jsonl(text)
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    print(f"valid chat ({len(messages)} messages)")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Git ref JSONL review bus")
    subparsers = parser.add_subparsers(dest="command", required=True)

    chat_parser = subparsers.add_parser("chat", help="show recent messages")
    chat_parser.add_argument("--limit", type=int, default=20)
    chat_parser.add_argument("--json", action="store_true")
    chat_parser.set_defaults(func=cmd_chat)

    send_parser = subparsers.add_parser("send", help="append and push one message")
    send_parser.add_argument("--from", dest="sender", required=True)
    send_parser.add_argument("--type", dest="message_type", required=True)
    send_parser.add_argument("--reply-to", dest="reply_to")
    send_parser.add_argument("--body", required=True)
    send_parser.add_argument("--commit")
    send_parser.add_argument("--target")
    send_parser.add_argument("--status")
    send_parser.set_defaults(func=cmd_send)

    validate_parser = subparsers.add_parser("validate", help="validate chat JSONL")
    validate_parser.add_argument("--file")
    validate_parser.set_defaults(func=cmd_validate)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except AgentChatError as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
