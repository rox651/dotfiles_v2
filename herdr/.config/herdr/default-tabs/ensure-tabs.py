#!/usr/bin/env python3
"""Ensure workspace tabs: agent, code, server."""

import json
import os
import subprocess
import sys
import time

WANTED = ("agent", "code", "server")


def herdr_bin():
    return os.environ.get("HERDR_BIN_PATH") or "herdr"


def herdr(*args):
    return subprocess.check_output([herdr_bin(), *args], text=True)


def herdr_ok(*args):
    subprocess.run(
        [herdr_bin(), *args],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def walk_workspace_id(obj):
    if isinstance(obj, dict):
        if obj.get("workspace_id"):
            return obj["workspace_id"]
        for v in obj.values():
            found = walk_workspace_id(v)
            if found:
                return found
    elif isinstance(obj, list):
        for v in obj:
            found = walk_workspace_id(v)
            if found:
                return found
    return None


def workspace_id():
    env = os.environ.get("HERDR_WORKSPACE_ID")
    if env:
        return env
    for key in ("HERDR_PLUGIN_EVENT_JSON", "HERDR_PLUGIN_CONTEXT_JSON"):
        raw = os.environ.get(key)
        if not raw:
            continue
        try:
            found = walk_workspace_id(json.loads(raw))
        except json.JSONDecodeError:
            continue
        if found:
            return found
    return None


def list_tabs(ws):
    raw = herdr("tab", "list", "--workspace", ws)
    return json.loads(raw)["result"]["tabs"]


def ensure(ws):
    tabs = list_tabs(ws)
    if not tabs:
        # ponytail: one retry if create event races the first tab
        time.sleep(0.2)
        tabs = list_tabs(ws)
    labels = {t.get("label") for t in tabs}
    if all(name in labels for name in WANTED):
        return
    if "agent" not in labels and len(tabs) == 1:
        herdr_ok("tab", "rename", tabs[0]["tab_id"], "agent")
        labels.add("agent")
    for name in WANTED:
        if name in labels:
            continue
        herdr_ok("tab", "create", "--workspace", ws, "--label", name, "--no-focus")
        labels.add(name)


def default_session_workspace():
    raw = herdr("tab", "list")
    tabs = json.loads(raw)["result"]["tabs"]
    if len(tabs) != 1 or tabs[0].get("label") != "1":
        return None
    return tabs[0]["workspace_id"]


def main():
    ws = workspace_id() or default_session_workspace()
    if not ws:
        return 0
    ensure(ws)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as e:
        print(e, file=sys.stderr)
        raise SystemExit(e.returncode or 1)
