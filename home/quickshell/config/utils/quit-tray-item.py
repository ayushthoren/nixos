#!/usr/bin/env python3
import os
import re
import shlex
import signal
import subprocess
import sys


def busctl(*args):
    return subprocess.check_output(
        ["busctl", "--user", *args], text=True, stderr=subprocess.DEVNULL
    ).strip()


def owner_for_item(item_id):
    registered = shlex.split(busctl(
        "get-property", "org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher",
        "org.kde.StatusNotifierWatcher", "RegisteredStatusNotifierItems"
    ))[2:]
    matches = []
    for registered_item in registered:
        if "/" not in registered_item:
            continue
        service, path = registered_item.split("/", 1)
        path = "/" + path
        try:
            value = shlex.split(busctl(
                "get-property", service, path, "org.kde.StatusNotifierItem", "Id"
            ))
        except subprocess.CalledProcessError:
            continue
        if len(value) >= 2 and value[1] == item_id:
            matches.append(service)
    if len(matches) != 1:
        raise RuntimeError("Tray item is missing or ambiguous")
    return matches[0]


def main():
    if len(sys.argv) not in (2, 3):
        raise RuntimeError("Expected a tray item ID")
    service = owner_for_item(sys.argv[1])
    status = busctl("status", service)
    pid_match = re.search(r"^PID=(\d+)$", status, re.MULTILINE)
    uid_match = re.search(r"^UID=(\d+)$", status, re.MULTILINE)
    if not pid_match or not uid_match or int(uid_match.group(1)) != os.getuid():
        raise RuntimeError("Tray item has no local process owned by this user")
    pid = int(pid_match.group(1))
    if pid <= 1 or pid == os.getpid():
        raise RuntimeError("Unsafe process ID")
    if len(sys.argv) == 3 and sys.argv[2] == "--dry-run":
        print(pid)
        return
    os.kill(pid, signal.SIGTERM)


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, subprocess.CalledProcessError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
