#!/usr/bin/env python3
import argparse
import contextlib
import fcntl
import json
import os
import shutil
import signal
import stat
import sys
import time
import urllib.error
import urllib.request
from collections import defaultdict
from typing import NamedTuple

BRANCHES = ["/media/bulk-seagate", "/media/bulk-toshiba"]
LIBRARIES = ["Series", "Movies"]
COMPLETED = "completed"
CONTAINER_ROOT = "/data"
RPC = "http://127.0.0.1:9091/transmission/rpc"
LOCK = "/run/bulk-consolidate.lock"
MARGIN = 100 * 2**30  # same as the pool's minfreespace, so mergerfs keeps the disk eligible
STOPPED = 0
STOP_WAIT = 60


def log(msg):
    print(msg, flush=True)


def gib(n):
    return f"{n / 2**30:.1f} GiB"


class Transmission:
    def __init__(self, url):
        self.url = url
        self.sid = ""

    def call(self, method, **args):
        body = json.dumps({"method": method, "arguments": args}).encode()
        for _ in range(2):
            req = urllib.request.Request(self.url, body, {
                "X-Transmission-Session-Id": self.sid,
                "Content-Type": "application/json",
            })
            try:
                with urllib.request.urlopen(req, timeout=30) as r:
                    reply = json.load(r)
            except urllib.error.HTTPError as e:
                if e.code == 409:
                    self.sid = e.headers["X-Transmission-Session-Id"]
                    continue
                raise
            if reply.get("result") != "success":
                raise RuntimeError(f"{method}: {reply.get('result')}")
            return reply.get("arguments", {})
        raise RuntimeError(f"{method}: no session id")

    def torrents_by_path(self):
        out = {}
        for t in self.call("torrent-get", fields=["id", "name", "status", "downloadDir", "files"])["torrents"]:
            for f in t["files"]:
                out[os.path.join(t["downloadDir"], f["name"])] = t
        return out

    def status(self, tid):
        return self.call("torrent-get", ids=[tid], fields=["status"])["torrents"][0]["status"]

    def stop(self, tid):
        self.call("torrent-stop", ids=[tid])
        for _ in range(STOP_WAIT):
            if self.status(tid) == STOPPED:
                return
            time.sleep(1)
        raise RuntimeError(f"did not stop within {STOP_WAIT}s")

    def start(self, tid):
        self.call("torrent-start", ids=[tid])


class PlainOp(NamedTuple):
    src: str
    target: str
    rel: str
    st: os.stat_result
    dup: bool


class SeedOp(NamedTuple):
    src: str
    target: str
    rel: str
    other: str
    st: os.stat_result
    dup: bool
    linked: bool


def is_mounted(path):
    return os.path.ismount(path)


def free_bytes(path):
    s = os.statvfs(path)
    return s.f_bavail * s.f_frsize


def regular_files(branch, rel_root):
    root = os.path.join(branch, rel_root)
    for d, _, names in os.walk(root):
        for n in names:
            if n.endswith(".consolidating"):
                continue
            p = os.path.join(d, n)
            try:
                st = os.lstat(p)
            except FileNotFoundError:
                continue
            if stat.S_ISREG(st.st_mode):
                yield os.path.relpath(p, branch), st


def inode_index(branch):
    return {(st.st_dev, st.st_ino): rel for rel, st in regular_files(branch, COMPLETED)}


def mirror_dirs(src_branch, dst_branch, rel_dir):
    cur = ""
    for part in rel_dir.split(os.sep):
        cur = os.path.join(cur, part)
        dst = os.path.join(dst_branch, cur)
        if os.path.isdir(dst):
            continue
        st = os.stat(os.path.join(src_branch, cur))
        os.mkdir(dst)
        os.chown(dst, st.st_uid, st.st_gid)
        os.chmod(dst, stat.S_IMODE(st.st_mode))


def prune_dirs(branch, rel_dir):
    # an empty leftover dir still counts as an existing path for mspmfs and would pull new files back
    while os.sep in rel_dir:
        try:
            os.rmdir(os.path.join(branch, rel_dir))
        except OSError:
            return
        rel_dir = os.path.dirname(rel_dir)


def copy_file(src, dst):
    tmp = os.path.join(os.path.dirname(dst), f".{os.path.basename(dst)}.consolidating")
    try:
        with open(src, "rb") as fi, open(tmp, "wb") as fo:
            shutil.copyfileobj(fi, fo, 16 * 2**20)
            fo.flush()
            os.fsync(fo.fileno())
        st = os.stat(src)
        os.chown(tmp, st.st_uid, st.st_gid)
        os.chmod(tmp, stat.S_IMODE(st.st_mode))
        # same mtime, so Transmission sees no reason to re-verify the moved file
        os.utime(tmp, ns=(st.st_atime_ns, st.st_mtime_ns))
        os.rename(tmp, dst)
    except BaseException:
        with contextlib.suppress(FileNotFoundError):
            os.unlink(tmp)
        raise


def matches(a, b):
    return a.st_size == b.st_size and a.st_mtime_ns == b.st_mtime_ns


def same_file(path, st):
    try:
        return matches(os.stat(path), st)
    except FileNotFoundError:
        return None


def inode(path):
    st = os.lstat(path)
    return (st.st_dev, st.st_ino) if stat.S_ISREG(st.st_mode) else None


class Tally:
    def __init__(self):
        self.moved = 0
        self.errors = 0


class Plan:
    def __init__(self):
        self.plain = []
        self.seeding = defaultdict(list)
        self.names = {}
        self.bytes = 0


def plan_item(lib, item, branches, indexes, torrents, budget):
    per_branch = {}
    for b in branches:
        files = list(regular_files(b, os.path.join(lib, item)))
        if files:
            per_branch[b] = files
    if len(per_branch) < 2:
        return None
    target = max(per_branch, key=lambda b: (sum(st.st_size for _, st in per_branch[b]), free_bytes(b)))
    plan = Plan()
    room = free_bytes(target) - MARGIN
    for src, files in per_branch.items():
        if src == target:
            continue
        for rel, st in files:
            dup = same_file(os.path.join(target, rel), st)
            if dup is False:
                log(f"  skip {rel}: a different file already exists on {target}")
                continue
            if dup is None and st.st_size > room:
                log(f"  skip {rel}: not enough free space on {target} (keeps {gib(MARGIN)} free)")
                continue
            if dup is None and plan.bytes + st.st_size > budget:
                log(f"  skip {rel}: over this run's budget, left for a later run")
                continue
            if st.st_nlink == 1:
                plan.plain.append(PlainOp(src, target, rel, st, bool(dup)))
            elif st.st_nlink == 2:
                other = indexes[src].get((st.st_dev, st.st_ino))
                t = torrents.get(os.path.join(CONTAINER_ROOT, other)) if other else None
                if t is None:
                    log(f"  skip {rel}: second name not found under {COMPLETED}/ or not in Transmission")
                    continue
                linked = False
                if os.path.lexists(os.path.join(target, other)):
                    # left by a run that died between linking on the target and unlinking the sources
                    linked = bool(dup) and inode(os.path.join(target, other)) == inode(os.path.join(target, rel))
                    if not linked:
                        log(f"  skip {rel}: {other} already exists on {target}")
                        continue
                plan.seeding[t["id"]].append(SeedOp(src, target, rel, other, st, bool(dup), linked))
                plan.names[t["id"]] = t["name"]
            else:
                log(f"  skip {rel}: {st.st_nlink} links")
                continue
            if not dup:
                plan.bytes += st.st_size
                room -= st.st_size
    return target, plan


def move_plain(op):
    s, d = os.path.join(op.src, op.rel), os.path.join(op.target, op.rel)
    if not op.dup:
        mirror_dirs(op.src, op.target, os.path.dirname(op.rel))
        copy_file(s, d)
    if not same_file(s, op.st):
        if not op.dup:
            os.unlink(d)
        log(f"  abort {op.rel}: changed since planning, kept on {op.src}")
        return 0
    os.unlink(s)
    prune_dirs(op.src, os.path.dirname(op.rel))
    return 0 if op.dup else op.st.st_size


def move_seeding(op):
    s_lib, s_tor = os.path.join(op.src, op.rel), os.path.join(op.src, op.other)
    d_lib, d_tor = os.path.join(op.target, op.rel), os.path.join(op.target, op.other)
    copied = not op.dup
    if copied:
        mirror_dirs(op.src, op.target, os.path.dirname(op.rel))
        copy_file(s_lib, d_lib)
    if not same_file(s_lib, op.st) or inode(s_tor) != (op.st.st_dev, op.st.st_ino):
        if copied:
            os.unlink(d_lib)
        log(f"  abort {op.rel}: changed since planning, kept on {op.src}")
        return 0
    if not op.linked:
        mirror_dirs(op.src, op.target, os.path.dirname(op.other))
        os.link(d_lib, d_tor)
    os.unlink(s_tor)
    os.unlink(s_lib)
    prune_dirs(op.src, os.path.dirname(op.rel))
    prune_dirs(op.src, os.path.dirname(op.other))
    return 0 if op.dup else op.st.st_size


def guarded(move, op, tally):
    try:
        tally.moved += move(op)
    except OSError as e:
        log(f"  error {op.rel}: {e}, left on {op.src}")
        tally.errors += 1


def move_torrent(tr, tid, name, ops, tally):
    was_running = tr.status(tid) != STOPPED
    if was_running:
        log(f"  torrent {tid} ({name}): stop, move {len(ops)} seeding files")
    else:
        log(f"  torrent {tid} ({name}): already stopped, move {len(ops)} seeding files, left stopped")
    try:
        if was_running:
            try:
                tr.stop(tid)
            except Exception as e:
                log(f"  skip torrent {tid} ({name}): stop failed ({e}), files left in place")
                tally.errors += 1
                return
        for op in ops:
            log(f"  move {op.rel} (+ {op.other})")
            guarded(move_seeding, op, tally)
    finally:
        if was_running:
            tr.start(tid)


def apply_plan(tr, plan, execute, tally):
    for op in plan.plain:
        verb = "drop duplicate" if op.dup else "move"
        log(f"  {verb if execute else 'would ' + verb} {op.rel}")
        if execute:
            guarded(move_plain, op, tally)
    for tid, ops in plan.seeding.items():
        if execute:
            move_torrent(tr, tid, plan.names[tid], ops, tally)
        else:
            log(f"  torrent {tid} ({plan.names[tid]}): would stop and move {len(ops)} seeding files")


def run(args):
    for b in args.branches:
        if not is_mounted(b):
            sys.exit(f"{b} is not mounted, refusing to run")
    tr = Transmission(args.rpc)
    torrents = tr.torrents_by_path()
    indexes = {b: inode_index(b) for b in args.branches}
    budget = args.max_gib * 2**30
    total = 0
    tally = Tally()
    items = [(lib, i) for lib in LIBRARIES
             for i in sorted({i for b in args.branches if os.path.isdir(os.path.join(b, lib))
                              for i in os.listdir(os.path.join(b, lib))
                              if os.path.isdir(os.path.join(b, lib, i))})]
    for lib, item in items:
        result = plan_item(lib, item, args.branches, indexes, torrents, budget - total)
        if not result:
            continue
        target, plan = result
        n = len(plan.plain) + sum(len(v) for v in plan.seeding.values())
        if not n:
            continue
        log(f"{lib}/{item}: {n} files ({gib(plan.bytes)}) to {target}")
        apply_plan(tr, plan, args.execute, tally)
        total += plan.bytes
        if total >= budget:
            log(f"budget of {args.max_gib} GiB reached")
            break
    if not args.execute:
        log(f"done: {gib(total)} would move")
        return
    log(f"done: {gib(tally.moved)} moved, {tally.errors} errors")
    if tally.errors:
        sys.exit(1)


def on_sigterm(*_):
    signal.signal(signal.SIGTERM, signal.SIG_IGN)
    sys.exit(143)


def main():
    p = argparse.ArgumentParser(description="Move each show or movie folder's minority files onto the disk holding most of it, under the mergerfs bulk pool.")
    p.add_argument("--execute", action="store_true", help="move files (default is a dry run)")
    p.add_argument("--max-gib", type=int, default=200, help="stop after this many GiB per run (default 200)")
    p.add_argument("--branches", nargs="+", default=BRANCHES)
    p.add_argument("--rpc", default=RPC)
    args = p.parse_args()
    # turns systemd stop into SystemExit, so the finally blocks restart the torrent and drop the temp file
    signal.signal(signal.SIGTERM, on_sigterm)
    with open(LOCK if args.execute else os.devnull, "w") as lock:
        if args.execute:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                sys.exit(f"another bulk-consolidate run holds {LOCK}")
        run(args)


if __name__ == "__main__":
    main()
