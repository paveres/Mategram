#!/usr/bin/env python3
import argparse
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOCAL_FILE = ROOT / "secrets.local.json"
NAMES = ("TELEGRAM_API_ID", "TELEGRAM_API_HASH")


def gh(args, stdin=None, check=True):
    p = subprocess.run(["gh"] + args, input=stdin, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if check and p.returncode != 0:
        raise SystemExit("gh %s failed: %s" % (" ".join(args[:3]), p.stderr.strip()))
    return p


def load_values(path):
    values = {}
    if path.exists():
        data = json.loads(path.read_text(encoding="utf-8"))
        for n in NAMES:
            if data.get(n):
                values[n] = str(data[n]).strip()
    for n in NAMES:
        if os.environ.get(n):
            values[n] = os.environ[n].strip()
    return values


def validate(values):
    errors = []
    for n in NAMES:
        if n not in values or not values[n]:
            errors.append("%s is missing (set the environment variable or put it in secrets.local.json)" % n)
    if "TELEGRAM_API_ID" in values and not re.fullmatch(r"\d{1,12}", values["TELEGRAM_API_ID"]):
        errors.append("TELEGRAM_API_ID must contain digits only")
    if "TELEGRAM_API_HASH" in values and not re.fullmatch(r"[0-9a-fA-F]{32}", values["TELEGRAM_API_HASH"]):
        errors.append("TELEGRAM_API_HASH must be 32 hexadecimal characters")
    return errors


def mask(value):
    if len(value) <= 4:
        return "*" * len(value)
    return value[:2] + "*" * (len(value) - 4) + value[-2:]


def repo_from_git(root):
    p = subprocess.run(["git", "remote", "get-url", "origin"], cwd=root, capture_output=True, text=True)
    if p.returncode != 0:
        return None
    m = re.search(r"github\.com[:/]+([^/]+/[^/]+?)(?:\.git)?$", p.stdout.strip())
    return m.group(1) if m else None


def main():
    ap = argparse.ArgumentParser(description="Write the Telegram api_id and api_hash into GitHub repository secrets")
    ap.add_argument("--repo", help="OWNER/NAME (default: origin of the project folder)")
    ap.add_argument("--create", action="store_true", help="create the repository as private if it does not exist")
    ap.add_argument("--public", action="store_true", help="with --create: make the new repository public")
    ap.add_argument("--file", default=str(LOCAL_FILE), help="local JSON with the values (never committed)")
    ap.add_argument("--dry-run", action="store_true", help="check everything, send nothing")
    args = ap.parse_args()

    values = load_values(Path(args.file))
    errors = validate(values)
    if errors:
        for e in errors:
            print("error:", e)
        return 2

    repo = args.repo or repo_from_git(ROOT)
    if not repo:
        print("error: repository not given; pass --repo OWNER/NAME")
        return 2

    status = gh(["auth", "status"], check=False)
    if status.returncode != 0 and "Logged in" not in (status.stdout + status.stderr):
        print("error: gh is not logged in (run: gh auth login)")
        return 2

    exists = gh(["repo", "view", repo, "--json", "name"], check=False).returncode == 0
    print("repository %s: %s" % (repo, "found" if exists else "not found"))
    if not exists:
        if not args.create:
            print("error: repository does not exist; use --create to create it (private by default)")
            return 3
        if args.dry_run:
            print("dry-run: would create %s repository %s" % ("public" if args.public else "private", repo))
        else:
            gh(["repo", "create", repo, "--public" if args.public else "--private"])
            print("created %s repository %s" % ("public" if args.public else "private", repo))

    for n in NAMES:
        if args.dry_run:
            print("dry-run: would set %s = %s (%d chars)" % (n, mask(values[n]), len(values[n])))
        else:
            gh(["secret", "set", n, "--repo", repo], stdin=values[n])
            print("set secret %s" % n)

    if not args.dry_run:
        listed = ""
        for attempt in range(3):
            res = gh(["secret", "list", "--repo", repo], check=False)
            if res.returncode == 0:
                listed = res.stdout
                break
            time.sleep(2)
        missing = [n for n in NAMES if n not in listed]
        if missing:
            print("error: secrets not visible after setting:", ", ".join(missing))
            return 4
        print("verified: %s are present in %s" % (", ".join(NAMES), repo))
    return 0


if __name__ == "__main__":
    sys.exit(main())
