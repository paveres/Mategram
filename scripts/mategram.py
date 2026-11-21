#!/usr/bin/env python3
import argparse
import datetime
import difflib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
UPSTREAM_URL = "https://github.com/TelegramMessenger/Telegram-iOS.git"
MARK = "MATE"
FUZZY_AUTO = 0.93
FUZZY_MIN_LINE = 0.85
FUZZY_MIN_TOTAL = 0.78


class Ctx:
    def __init__(self, root):
        self.root = Path(root)
        self.up = self.root / "upstream"
        self.overlay = self.root / "overlay"
        self.hooks = self.root / "hooks"
        self.state = self.root / ".mategram"
        self.lock = self.root / "upstream.lock.json"
        self.report_dir = self.root / "build-report"


def sh(args, cwd=None, check=True):
    p = subprocess.run(args, cwd=cwd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if check and p.returncode != 0:
        raise RuntimeError("command failed: %s\n%s" % (" ".join(args), p.stderr.strip()))
    return p.stdout


def norm(s):
    return " ".join(s.split())


def version_key(tag):
    nums = re.findall(r"\d+", tag)
    return tuple(int(x) for x in nums)


def git_show(ctx, rev, rel):
    p = subprocess.run(["git", "show", "%s:%s" % (rev, rel)], cwd=ctx.up, capture_output=True)
    if p.returncode != 0:
        return None
    return p.stdout.decode("utf-8", errors="replace")


def head_sha(ctx):
    return sh(["git", "rev-parse", "HEAD"], cwd=ctx.up).strip()


def tracked_files(ctx):
    out = sh(["git", "ls-files"], cwd=ctx.up)
    return out.split("\n")


def load_manifests(ctx, include_examples=False):
    hooks = []
    if not ctx.hooks.exists():
        return hooks
    for p in sorted(ctx.hooks.rglob("*.json")):
        rel = p.relative_to(ctx.hooks)
        is_example = any(part.startswith("_") for part in rel.parts)
        if is_example and not include_examples:
            continue
        data = json.loads(p.read_text(encoding="utf-8"))
        for h in data.get("hooks", []):
            if h.get("enabled", True) is False:
                continue
            h = dict(h)
            h["_manifest"] = str(p)
            hooks.append(h)
    return hooks


def clean_lines(lines):
    keep = []
    idx = []
    for i, l in enumerate(lines):
        if ("// %s:" % MARK) in l:
            continue
        keep.append(l)
        idx.append(i)
    return keep, idx


def context_score(lines, i, before, after):
    total = 0
    good = 0
    for k, b in enumerate(reversed(before)):
        j = i - 1 - k
        total += 1
        if j >= 0 and norm(lines[j]) == norm(b):
            good += 1
    for k, a in enumerate(after):
        j = i + 1 + k
        total += 1
        if j < len(lines) and norm(lines[j]) == norm(a):
            good += 1
    if total == 0:
        return 1.0
    return good / total


def context_ratio(lines, i, before, after):
    ratios = []
    for k, b in enumerate(reversed(before)):
        j = i - 1 - k
        if j >= 0:
            ratios.append(difflib.SequenceMatcher(None, norm(lines[j]), norm(b)).ratio())
        else:
            ratios.append(0.0)
    for k, a in enumerate(after):
        j = i + 1 + k
        if j < len(lines):
            ratios.append(difflib.SequenceMatcher(None, norm(lines[j]), norm(a)).ratio())
        else:
            ratios.append(0.0)
    if not ratios:
        return 1.0
    return sum(ratios) / len(ratios)


def find_anchor(lines, anchor):
    target = norm(anchor["line"])
    before = anchor.get("before", [])
    after = anchor.get("after", [])
    occurrence = anchor.get("occurrence")
    exact = [i for i, l in enumerate(lines) if norm(l) == target]
    if exact:
        scored = sorted(((context_score(lines, i, before, after), i) for i in exact), key=lambda x: (-x[0], x[1]))
        if occurrence and 1 <= occurrence <= len(exact) and len(exact) > 1 and not before and not after:
            return {"status": "exact", "index": exact[occurrence - 1], "score": 1.0}
        best = scored[0]
        if len(scored) > 1 and scored[1][0] == best[0] and best[0] < 1.0 and not occurrence:
            return {"status": "ambiguous", "candidates": [i + 1 for _, i in scored[:5]], "score": best[0]}
        if len(scored) > 1 and scored[1][0] == best[0] and best[0] == 1.0 and not occurrence:
            return {"status": "ambiguous", "candidates": [i + 1 for _, i in scored[:5]], "score": best[0]}
        if len(scored) > 1 and occurrence:
            ties = [i for sc, i in scored if sc == best[0]]
            if len(ties) > 1:
                ties.sort()
                pick = ties[min(occurrence, len(ties)) - 1]
                return {"status": "exact", "index": pick, "score": best[0]}
        status = "exact" if best[0] >= 0.5 or not (before or after) else "exact-weak"
        return {"status": status, "index": best[1], "score": best[0]}
    cands = []
    target_tokens = set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", target))
    for i, l in enumerate(lines):
        n = norm(l)
        if not n:
            continue
        r = line_similarity(n, target, target_tokens)
        if r >= FUZZY_MIN_LINE:
            cands.append((r, i))
    cands.sort(reverse=True)
    best = None
    for r, i in cands[:12]:
        cr = context_ratio(lines, i, before, after)
        total = 0.6 * r + 0.4 * cr
        if best is None or total > best["score"]:
            best = {"index": i, "score": total, "line_ratio": r}
    if best and best["score"] >= FUZZY_MIN_TOTAL:
        best["status"] = "fuzzy"
        return best
    if before or after:
        for k in range(len(lines)):
            pass
    return {"status": "missing"}


def line_similarity(n, target, target_tokens):
    best = 0.0
    sm = difflib.SequenceMatcher(None, n, target)
    if sm.real_quick_ratio() >= FUZZY_MIN_LINE and sm.quick_ratio() >= FUZZY_MIN_LINE:
        best = sm.ratio()
    if len(target_tokens) >= 2:
        toks = set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", n))
        if toks:
            small, big = (target_tokens, toks) if len(target_tokens) <= len(toks) else (toks, target_tokens)
            if small <= big and len(small) >= 2:
                best = max(best, 0.88 + 0.12 * (len(small) / len(big)))
    return best


def indent_of(line):
    return line[: len(line) - len(line.lstrip())]


def render(hook, anchor_line):
    base = indent_of(anchor_line)
    default_extra = 4 if hook.get("action", "insert_after") == "insert_after" and anchor_line.rstrip().endswith("{") else 0
    extra = " " * int(hook.get("indent_extra", default_extra))
    out = []
    for t in hook["text"]:
        stripped = t.strip()
        if not stripped:
            out.append("")
            continue
        out.append("%s%s%s  // %s:%s" % (base, extra, t.strip() if hook.get("strip", True) else t, MARK, hook["id"]))
    return out


def apply_hook(lines, idx, hook):
    action = hook.get("action", "insert_after")
    anchor_line = lines[idx]
    block = render(hook, anchor_line)
    if action == "insert_after":
        return lines[: idx + 1] + block + lines[idx + 1:]
    if action == "insert_before":
        return lines[:idx] + block + lines[idx:]
    if action == "replace":
        return lines[:idx] + block + lines[idx + 1:]
    raise ValueError("unknown action %s" % action)


def resolve_all(ctx, hooks, rev="HEAD", accept_fuzzy=False):
    by_file = {}
    for h in hooks:
        by_file.setdefault(h["file"], []).append(h)
    results = []
    patched = {}
    all_files = None
    for rel, group in by_file.items():
        text = git_show(ctx, rev, rel)
        if text is None:
            if all_files is None:
                all_files = tracked_files(ctx)
            base = rel.rsplit("/", 1)[-1]
            near = [f for f in all_files if f.endswith("/" + base) or f == base][:5]
            for h in group:
                results.append({"id": h["id"], "file": rel, "status": "file-missing", "required": h.get("required", True), "candidates": near, "note": h.get("note", "")})
            continue
        crlf = "\r\n" in text
        lines = text.replace("\r\n", "\n").split("\n")
        pending = []
        for h in group:
            lines_clean, _ = clean_lines(lines)
            r = find_anchor(lines_clean, h["anchor"])
            entry = {"id": h["id"], "file": rel, "required": h.get("required", True), "note": h.get("note", ""), "status": r["status"]}
            if r["status"] in ("exact", "exact-weak"):
                entry["line"] = r["index"] + 1
                entry["score"] = round(r.get("score", 1.0), 3)
                pending.append((r["index"], h, entry))
            elif r["status"] == "fuzzy":
                entry["line"] = r["index"] + 1
                entry["score"] = round(r["score"], 3)
                if accept_fuzzy or r["score"] >= FUZZY_AUTO:
                    pending.append((r["index"], h, entry))
                else:
                    entry["status"] = "needs-review"
                    entry["found_text"] = lines_clean[r["index"]].strip()
            elif r["status"] == "ambiguous":
                entry["candidates"] = r["candidates"]
            results.append(entry)
        pending.sort(key=lambda x: x[0], reverse=True)
        cur = lines
        for idx, h, entry in pending:
            cur = apply_hook(cur, idx, h)
        patched[rel] = ("\r\n" if crlf else "\n").join(cur)
    return results, patched


def old_context_diff(ctx, old_sha, rel, hook, limit=40):
    snap = ctx.state / "snapshots" / old_sha / rel
    if not snap.exists():
        return []
    new_text = git_show(ctx, "HEAD", rel)
    if new_text is None:
        return []
    old = snap.read_text(encoding="utf-8", errors="replace").splitlines()
    new = new_text.splitlines()
    key = norm(hook["anchor"]["line"])[:30]
    words = [w for w in re.findall(r"[A-Za-z_]{4,}", hook["anchor"]["line"])][:4]
    out = []
    for hunk in difflib.unified_diff(old, new, "old", "new", lineterm="", n=2):
        out.append(hunk)
    rel_lines = []
    keep = False
    for l in out:
        if l.startswith("@@"):
            keep = False
            block = [l]
            rel_lines.append(block)
            continue
        if rel_lines:
            rel_lines[-1].append(l)
    chosen = []
    for block in rel_lines:
        joined = "\n".join(block)
        if key and key in joined or any(w in joined for w in words):
            chosen.extend(block)
    return chosen[:limit]


def write_report(ctx, results, lock, mode):
    ctx.report_dir.mkdir(parents=True, exist_ok=True)
    old_sha = (lock.get("previous") or {}).get("commit")
    groups = {}
    for r in results:
        groups.setdefault(r["status"], []).append(r)
    md = []
    md.append("# Mategram sync report")
    md.append("")
    md.append("- mode: %s" % mode)
    md.append("- upstream: %s (%s)" % (lock.get("tag"), (lock.get("commit") or "")[:10]))
    if lock.get("previous"):
        md.append("- previous: %s (%s)" % (lock["previous"].get("tag"), (lock["previous"].get("commit") or "")[:10]))
    md.append("- generated: %s" % datetime.datetime.now().isoformat(timespec="seconds"))
    md.append("")
    total = len(results)
    ok = len(groups.get("exact", []))
    md.append("| result | count |")
    md.append("|---|---|")
    md.append("| total hooks | %d |" % total)
    md.append("| applied exactly | %d |" % ok)
    for k in ("exact-weak", "fuzzy", "needs-review", "ambiguous", "missing", "file-missing"):
        if groups.get(k):
            md.append("| %s | %d |" % (k, len(groups[k])))
    md.append("")
    def section(title, key, fmt):
        if groups.get(key):
            md.append("## %s" % title)
            md.append("")
            for r in groups[key]:
                md.append(fmt(r))
            md.append("")
    section("Applied, but the lines around the anchor changed (check the result)", "exact-weak", lambda r: "- `%s` in `%s` line %s, context score %s" % (r["id"], r["file"], r.get("line"), r.get("score")))
    section("Moved or slightly changed (applied automatically)", "fuzzy", lambda r: "- `%s` in `%s` line %s, score %s%s" % (r["id"], r["file"], r.get("line"), r.get("score"), "" if r["required"] else " (optional)"))
    section("Needs review (NOT applied)", "needs-review", lambda r: "- `%s` in `%s` line %s, score %s, found: `%s`" % (r["id"], r["file"], r.get("line"), r.get("score"), r.get("found_text", "")))
    section("Ambiguous anchor (NOT applied)", "ambiguous", lambda r: "- `%s` in `%s`, candidate lines %s" % (r["id"], r["file"], r.get("candidates")))
    section("Anchor not found (NOT applied)", "missing", lambda r: "- `%s` in `%s`%s" % (r["id"], r["file"], " (optional)" if not r["required"] else ""))
    section("File moved or deleted (NOT applied)", "file-missing", lambda r: "- `%s` file `%s`, same-name files: %s" % (r["id"], r["file"], r.get("candidates")))
    hooks_by_id = {h["id"]: h for h in load_manifests(ctx, include_examples=True)}
    broken = [r for k in ("needs-review", "ambiguous", "missing") for r in groups.get(k, [])]
    if broken and old_sha:
        md.append("## What changed upstream near the broken anchors")
        md.append("")
        for r in broken:
            h = hooks_by_id.get(r["id"])
            if not h:
                continue
            d = old_context_diff(ctx, old_sha, r["file"], h)
            md.append("### %s (%s)" % (r["id"], r["file"]))
            md.append("")
            md.append("old anchor: `%s`" % h["anchor"]["line"].strip())
            md.append("")
            if d:
                md.append("```diff")
                md.extend(d)
                md.append("```")
            else:
                md.append("(no related upstream diff found; the code may have been rewritten)")
            md.append("")
    (ctx.report_dir / "sync-report.md").write_text("\n".join(md), encoding="utf-8")
    (ctx.report_dir / "sync-report.json").write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
    bad = [r for r in results if r["status"] in ("needs-review", "ambiguous", "missing", "file-missing") and r["required"]]
    return len(bad)


def read_lock(ctx):
    if ctx.lock.exists():
        return json.loads(ctx.lock.read_text(encoding="utf-8"))
    if (ctx.up / ".git").exists():
        try:
            sha = head_sha(ctx)
            tag = sh(["git", "describe", "--tags", "--exact-match"], cwd=ctx.up, check=False).strip() or "unknown"
            lock = {"tag": tag, "commit": sha, "fetched": datetime.datetime.now().isoformat(timespec="seconds"), "previous": None}
            ctx.lock.write_text(json.dumps(lock, indent=2), encoding="utf-8")
            return lock
        except Exception:
            return {}
    return {}


def copy_overlay(ctx, dry):
    copied = []
    if not ctx.overlay.exists():
        return copied
    for src in ctx.overlay.rglob("*"):
        if src.is_dir():
            continue
        rel = src.relative_to(ctx.overlay)
        dst = ctx.up / rel
        copied.append(str(rel).replace(os.sep, "/"))
        if not dry:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
    return copied


def remove_old_overlay(ctx):
    rec = ctx.state / "applied.json"
    if rec.exists():
        data = json.loads(rec.read_text(encoding="utf-8"))
        for rel in data.get("overlay", []):
            p = ctx.up / rel
            if p.exists():
                p.unlink()
        for d in sorted({str(Path(r).parent) for r in data.get("overlay", [])}, key=len, reverse=True):
            p = ctx.up / d
            try:
                p.rmdir()
            except OSError:
                pass


def cmd_sync(ctx, args):
    if not (ctx.up / ".git").exists():
        raise SystemExit("upstream/ is not a git clone; run: git clone --depth 1 %s upstream" % UPSTREAM_URL)
    hooks = load_manifests(ctx, include_examples=args.examples)
    lock = read_lock(ctx)
    if not args.dry_run:
        sh(["git", "checkout", "--", "."], cwd=ctx.up)
        remove_old_overlay(ctx)
    results, patched = resolve_all(ctx, hooks, accept_fuzzy=args.accept_fuzzy)
    copied = copy_overlay(ctx, args.dry_run)
    if not args.dry_run:
        for rel, text in patched.items():
            p = ctx.up / rel
            p.write_text(text, encoding="utf-8", newline="")
        ctx.state.mkdir(parents=True, exist_ok=True)
        (ctx.state / "applied.json").write_text(json.dumps({"overlay": copied, "hooks": [r["id"] for r in results]}, indent=2), encoding="utf-8")
    bad = write_report(ctx, results, lock, "dry-run" if args.dry_run else "sync")
    print("hooks: %d, overlay files: %d, problems: %d" % (len(results), len(copied), bad))
    print("report: %s" % (ctx.report_dir / "sync-report.md"))
    return 1 if bad else 0


def cmd_fetch(ctx, args):
    if not (ctx.up / ".git").exists():
        raise SystemExit("upstream/ is not a git clone")
    lock = read_lock(ctx)
    old_sha = head_sha(ctx)
    tag = args.tag
    if args.latest or not (args.tag or args.branch):
        out = sh(["git", "ls-remote", "--tags", "--refs", "origin"], cwd=ctx.up)
        tags = [l.split("refs/tags/")[1] for l in out.split("\n") if "refs/tags/" in l]
        tags = [t for t in tags if re.match(r"^release-\d+(\.\d+)*$", t)]
        tags.sort(key=version_key)
        tag = tags[-1]
    ref = tag if tag else args.branch
    print("fetching %s" % ref)
    hooks = load_manifests(ctx, include_examples=True)
    snap = ctx.state / "snapshots" / old_sha
    for rel in sorted({h["file"] for h in hooks}):
        text = git_show(ctx, "HEAD", rel)
        if text is not None:
            dst = snap / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_text(text, encoding="utf-8")
    sh(["git", "checkout", "--", "."], cwd=ctx.up)
    remove_old_overlay(ctx)
    if tag:
        sh(["git", "fetch", "--depth", "1", "origin", "tag", tag, "--no-tags"], cwd=ctx.up)
        sh(["git", "checkout", "--detach", "-f", "refs/tags/%s" % tag], cwd=ctx.up)
    else:
        sh(["git", "fetch", "--depth", "1", "origin", args.branch], cwd=ctx.up)
        sh(["git", "checkout", "--detach", "-f", "FETCH_HEAD"], cwd=ctx.up)
    new_sha = head_sha(ctx)
    new_lock = {"tag": tag or args.branch, "commit": new_sha, "fetched": datetime.datetime.now().isoformat(timespec="seconds"), "previous": {"tag": lock.get("tag"), "commit": old_sha}}
    ctx.lock.write_text(json.dumps(new_lock, indent=2), encoding="utf-8")
    print("upstream now %s (%s), previous %s" % (new_lock["tag"], new_sha[:10], old_sha[:10]))
    if args.no_sync:
        return 0
    args2 = argparse.Namespace(dry_run=False, accept_fuzzy=args.accept_fuzzy, examples=False)
    return cmd_sync(ctx, args2)


def cmd_status(ctx, args):
    lock = read_lock(ctx)
    print("upstream:", lock.get("tag"), (lock.get("commit") or "")[:10])
    hooks = load_manifests(ctx, include_examples=True)
    print("hooks defined (incl. examples):", len(hooks))
    print("overlay files:", sum(1 for _ in ctx.overlay.rglob("*") if _.is_file()) if ctx.overlay.exists() else 0)
    return 0


def load_manifest_file(path):
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return {"hooks": []}


def build_anchor(text, line_no, n=3):
    lines = text.replace("\r\n", "\n").split("\n")
    i = line_no - 1
    return {
        "line": lines[i].strip(),
        "before": [l.strip() for l in lines[max(0, i - n): i] if "// %s:" % MARK not in l],
        "after": [l.strip() for l in lines[i + 1: i + 1 + n] if "// %s:" % MARK not in l],
    }


def cmd_add(ctx, args):
    text = git_show(ctx, "HEAD", args.file)
    if text is None:
        raise SystemExit("file not found in upstream: %s" % args.file)
    path = Path(args.manifest) if args.manifest else ctx.hooks / "hooks.json"
    if not path.is_absolute():
        path = ctx.root / path
    data = load_manifest_file(path)
    if any(h["id"] == args.id for h in data["hooks"]):
        raise SystemExit("hook id already exists: %s" % args.id)
    data["hooks"].append({
        "id": args.id,
        "file": args.file,
        "action": args.action,
        "anchor": build_anchor(text, args.line),
        "text": args.text,
        "required": not args.optional,
        "note": args.note or "",
    })
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("added %s to %s" % (args.id, path))
    return 0


def cmd_reanchor(ctx, args):
    hooks = load_manifests(ctx, include_examples=args.examples)
    results, _ = resolve_all(ctx, hooks, accept_fuzzy=True)
    byid = {r["id"]: r for r in results}
    changed = 0
    files = {}
    for h in hooks:
        r = byid.get(h["id"])
        if not r or r["status"] not in ("fuzzy", "exact", "exact-weak") or "line" not in r:
            continue
        if args.ids and h["id"] not in args.ids:
            continue
        if r["status"] == "exact" and r.get("score", 1.0) >= 1.0 and not args.force:
            continue
        text = git_show(ctx, "HEAD", h["file"])
        clean, _idx = clean_lines(text.replace("\r\n", "\n").split("\n"))
        n = r["line"]
        new_anchor = build_anchor("\n".join(clean), n)
        files.setdefault(h["_manifest"], {})[h["id"]] = new_anchor
        changed += 1
    for mp, upd in files.items():
        data = json.loads(Path(mp).read_text(encoding="utf-8"))
        for h in data["hooks"]:
            if h["id"] in upd:
                h["anchor"] = upd[h["id"]]
        Path(mp).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("re-anchored %d hooks" % changed)
    return 0


OLD_BUNDLE = "ph.telegra.Telegraph"
OLD_TEAM = "C67CF9S4VU"
DEFAULT_BUNDLE = "app.mategram.ios"
DEFAULT_TEAM = "MATEGRAM00"


def replace_ids(value, old_bundle, new_bundle, old_team, new_team):
    if isinstance(value, str):
        return value.replace(old_bundle, new_bundle).replace(old_team, new_team)
    if isinstance(value, list):
        return [replace_ids(v, old_bundle, new_bundle, old_team, new_team) for v in value]
    if isinstance(value, dict):
        return {replace_ids(k, old_bundle, new_bundle, old_team, new_team): replace_ids(v, old_bundle, new_bundle, old_team, new_team) for k, v in value.items()}
    return value


def openssl_exe():
    exe = shutil.which("openssl")
    if exe:
        return exe
    for p in (r"C:\Program Files\Git\usr\bin\openssl.exe", r"C:\Program Files\Git\mingw64\bin\openssl.exe"):
        if os.path.exists(p):
            return p
    raise SystemExit("openssl not found")


def read_profile(path):
    import plistlib
    p = subprocess.run([openssl_exe(), "smime", "-inform", "der", "-verify", "-noverify", "-in", str(path)], capture_output=True)
    if p.returncode != 0:
        raise RuntimeError("cannot read profile %s: %s" % (path, p.stderr.decode(errors="replace")))
    return plistlib.loads(p.stdout)


def write_profile(plist_dict, out_path, key_path, cert_path):
    import plistlib
    data = plistlib.dumps(plist_dict)
    tmp = Path(str(out_path) + ".plist")
    tmp.write_bytes(data)
    try:
        sh([openssl_exe(), "smime", "-sign", "-nodetach", "-binary", "-outform", "der", "-signer", str(cert_path), "-inkey", str(key_path), "-in", str(tmp), "-out", str(out_path)])
    finally:
        tmp.unlink(missing_ok=True)


def cmd_codesigning(ctx, args):
    src = ctx.up / "build-system" / "fake-codesigning"
    if not src.exists():
        raise SystemExit("upstream/build-system/fake-codesigning not found")
    out = Path(args.out) if args.out else ctx.root / "build" / "fake-codesigning"
    if out.exists():
        shutil.rmtree(out)
    (out / "profiles").mkdir(parents=True)
    shutil.copytree(src / "certs", out / "certs")
    work = Path(tempfile.mkdtemp(prefix="mategram-sign-"))
    try:
        key, cert = work / "k.pem", work / "c.pem"
        sh([openssl_exe(), "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-keyout", str(key), "-out", str(cert), "-days", "3650", "-subj", "/CN=Mategram"])
        count = 0
        for f in sorted((src / "profiles").glob("*.mobileprovision")):
            d = read_profile(f)
            d2 = replace_ids(d, OLD_BUNDLE, args.bundle, OLD_TEAM, args.team)
            write_profile(d2, out / "profiles" / f.name, key, cert)
            count += 1
        for f in sorted((out / "profiles").glob("*.mobileprovision")):
            d = read_profile(f)
            ident = d["Entitlements"]["application-identifier"]
            assert ident.startswith(args.team + "." + args.bundle), "identifier not rewritten: %s" % ident
        print("profiles written: %d to %s (%s.%s)" % (count, out, args.team, args.bundle))
    finally:
        shutil.rmtree(work, ignore_errors=True)
    return 0


def cmd_config(ctx, args):
    src = ctx.up / "build-system" / "appstore-configuration.json"
    conf = json.loads(src.read_text(encoding="utf-8"))
    conf["bundle_id"] = args.bundle
    conf["team_id"] = args.team
    conf["api_id"] = args.api_id or os.environ.get("TELEGRAM_API_ID", "")
    conf["api_hash"] = args.api_hash or os.environ.get("TELEGRAM_API_HASH", "")
    if not conf["api_id"] or not conf["api_hash"]:
        raise SystemExit("api_id and api_hash are required (pass --api-id/--api-hash or set TELEGRAM_API_ID/TELEGRAM_API_HASH)")
    conf["enable_icloud"] = False
    conf["is_appstore_build"] = "false"
    conf["appstore_id"] = "0"
    out = Path(args.out) if args.out else ctx.up / "build-system" / "mategram-configuration.json"
    out.write_text(json.dumps(conf, indent=4), encoding="utf-8")
    print("configuration written to %s (bundle %s, team %s)" % (out, args.bundle, args.team))
    return 0


def run_selftest():
    base = Path(tempfile.mkdtemp(prefix="mategram-selftest-"))
    try:
        ctx = Ctx(base)
        ctx.up.mkdir()
        sh(["git", "init", "-q"], cwd=ctx.up)
        sh(["git", "config", "user.email", "t@t"], cwd=ctx.up)
        sh(["git", "config", "user.name", "t"], cwd=ctx.up)
        f = ctx.up / "Sources" / "Presence.swift"
        f.parent.mkdir(parents=True)
        v1 = [
            "import Foundation",
            "",
            "final class Presence {",
            "    func sendReadReceipt(peerId: Int64, maxId: Int32) {",
            "        let request = makeRequest(peerId, maxId)",
            "        network.send(request)",
            "    }",
            "",
            "    func other() {",
            "        log(\"x\")",
            "    }",
            "}",
            "",
        ]
        f.write_text("\n".join(v1), encoding="utf-8", newline="")
        (ctx.up / "Sources" / "Other.swift").write_text("func a() {\n    return\n}\n", encoding="utf-8")
        sh(["git", "add", "-A"], cwd=ctx.up)
        sh(["git", "commit", "-qm", "v1"], cwd=ctx.up)
        ctx.hooks.mkdir()
        (ctx.overlay / "Mategram").mkdir(parents=True)
        (ctx.overlay / "Mategram" / "Core.swift").write_text("public enum Mategram {}\n", encoding="utf-8")
        h1 = {"id": "t.receipt", "file": "Sources/Presence.swift", "action": "insert_before", "anchor": {"line": "network.send(request)", "before": ["let request = makeRequest(peerId, maxId)"], "after": ["}"]}, "text": ["if !MategramGhost.allowReadReceipt(peerId) { return }"]}
        h2 = {"id": "t.other", "file": "Sources/Presence.swift", "action": "insert_after", "anchor": {"line": "log(\"x\")", "before": ["func other() {"], "after": ["}"]}, "text": ["Mategram.touch()"]}
        h3 = {"id": "t.gone", "file": "Sources/Other.swift", "action": "insert_after", "anchor": {"line": "return", "before": ["func a() {"], "after": ["}"]}, "text": ["Mategram.never()"]}
        (ctx.hooks / "hooks.json").write_text(json.dumps({"hooks": [h1, h2, h3]}, indent=2), encoding="utf-8")
        a = argparse.Namespace(dry_run=False, accept_fuzzy=False, examples=False)
        rc = cmd_sync(ctx, a)
        assert rc == 0, "sync v1 should be clean"
        txt = f.read_text(encoding="utf-8")
        assert "MategramGhost.allowReadReceipt" in txt and "Mategram.touch()" in txt, "hooks applied"
        assert txt.index("allowReadReceipt") < txt.index("network.send"), "insert_before position"
        assert (ctx.up / "Mategram" / "Core.swift").exists(), "overlay copied"
        assert cmd_sync(ctx, a) == 0
        assert f.read_text(encoding="utf-8").count("allowReadReceipt") == 1, "idempotent"
        v2 = [
            "import Foundation",
            "import Postbox",
            "",
            "final class Presence {",
            "    func prepare() {",
            "        warm()",
            "    }",
            "",
            "    func sendReadReceipt(peerId: Int64, maxId: Int32, thread: Int64?) {",
            "        let request = makeRequest(peerId, maxId, thread)",
            "        network.send(request)",
            "    }",
            "",
            "    func other() {",
            "        log(\"x\")",
            "    }",
            "}",
            "",
        ]
        f.write_text("\n".join(v2), encoding="utf-8", newline="")
        (ctx.up / "Sources" / "Other.swift").write_text("func b() {\n    doSomethingNew()\n}\n", encoding="utf-8")
        sh(["git", "add", "-A"], cwd=ctx.up)
        sh(["git", "commit", "-qm", "v2", "--", "Sources"], cwd=ctx.up)
        rc2 = cmd_sync(ctx, a)
        rep = json.loads((ctx.report_dir / "sync-report.json").read_text(encoding="utf-8"))
        st = {r["id"]: r["status"] for r in rep}
        assert st["t.receipt"] in ("exact", "exact-weak", "fuzzy"), "moved anchor still found: %s" % st["t.receipt"]
        assert st["t.other"] == "exact", "unchanged hook exact"
        assert st["t.gone"] == "missing", "removed code reported"
        assert rc2 == 1, "exit code flags problem"
        txt2 = f.read_text(encoding="utf-8")
        assert txt2.index("allowReadReceipt") < txt2.index("network.send"), "moved hook position ok"
        v3 = [l.replace("network.send(request)", "network.send(request, priority: .high)") for l in v2]
        f.write_text("\n".join(v3), encoding="utf-8", newline="")
        sh(["git", "add", "-A"], cwd=ctx.up)
        sh(["git", "commit", "-qm", "v3", "--", "Sources"], cwd=ctx.up)
        cmd_sync(ctx, a)
        rep3 = json.loads((ctx.report_dir / "sync-report.json").read_text(encoding="utf-8"))
        st3 = {r["id"]: r for r in rep3}
        assert st3["t.receipt"]["status"] in ("fuzzy", "needs-review"), "changed anchor line detected: %s" % st3["t.receipt"]["status"]
        a2 = argparse.Namespace(dry_run=False, accept_fuzzy=True, examples=False)
        cmd_sync(ctx, a2)
        assert "allowReadReceipt" in f.read_text(encoding="utf-8"), "fuzzy accepted on request"
        cmd_reanchor(ctx, argparse.Namespace(ids=[], force=False, examples=False))
        a3 = argparse.Namespace(dry_run=False, accept_fuzzy=False, examples=False)
        cmd_sync(ctx, a3)
        rep4 = json.loads((ctx.report_dir / "sync-report.json").read_text(encoding="utf-8"))
        assert {r["id"]: r["status"] for r in rep4}["t.receipt"] == "exact", "re-anchored hook is exact again"
        print("selftest ok: statuses", st, "then", st3["t.receipt"]["status"], st3["t.receipt"].get("score"), "then reanchored exact")
        return 0
    finally:
        shutil.rmtree(base, ignore_errors=True)


def main():
    ap = argparse.ArgumentParser(prog="mategram", description="Keep Mategram on top of the latest Telegram-iOS")
    ap.add_argument("--root", default=str(ROOT))
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("sync", help="reset upstream tree, copy overlay, apply hooks")
    s.add_argument("--dry-run", action="store_true")
    s.add_argument("--accept-fuzzy", action="store_true")
    s.add_argument("--examples", action="store_true", help="include hooks under hooks/_*")
    f = sub.add_parser("fetch", help="move upstream to a newer release and re-sync")
    f.add_argument("--latest", action="store_true")
    f.add_argument("--tag")
    f.add_argument("--branch")
    f.add_argument("--no-sync", action="store_true")
    f.add_argument("--accept-fuzzy", action="store_true")
    sub.add_parser("status")
    a = sub.add_parser("add", help="define a hook from a line of the upstream file")
    a.add_argument("--id", required=True)
    a.add_argument("--file", required=True)
    a.add_argument("--line", type=int, required=True)
    a.add_argument("--action", default="insert_after", choices=["insert_after", "insert_before", "replace"])
    a.add_argument("--text", nargs="+", required=True)
    a.add_argument("--manifest")
    a.add_argument("--optional", action="store_true")
    a.add_argument("--note")
    r = sub.add_parser("reanchor", help="refresh anchors after upstream moved")
    r.add_argument("ids", nargs="*")
    r.add_argument("--force", action="store_true")
    r.add_argument("--examples", action="store_true")
    sub.add_parser("selftest")
    c = sub.add_parser("codesigning", help="make fake provisioning profiles for our bundle id")
    c.add_argument("--bundle", default=DEFAULT_BUNDLE)
    c.add_argument("--team", default=DEFAULT_TEAM)
    c.add_argument("--out")
    g = sub.add_parser("config", help="write the Make.py build configuration")
    g.add_argument("--bundle", default=DEFAULT_BUNDLE)
    g.add_argument("--team", default=DEFAULT_TEAM)
    g.add_argument("--api-id")
    g.add_argument("--api-hash")
    g.add_argument("--out")
    args = ap.parse_args()
    if args.cmd == "selftest":
        sys.exit(run_selftest())
    ctx = Ctx(args.root)
    fn = {"sync": cmd_sync, "fetch": cmd_fetch, "status": cmd_status, "add": cmd_add, "reanchor": cmd_reanchor, "codesigning": cmd_codesigning, "config": cmd_config}[args.cmd]
    sys.exit(fn(ctx, args))


if __name__ == "__main__":
    main()
