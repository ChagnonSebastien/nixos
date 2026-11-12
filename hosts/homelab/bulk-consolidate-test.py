#!/usr/bin/env python3
import contextlib
import errno
import fcntl
import http.server
import importlib.util
import io
import json
import os
import shutil
import signal
import sys
import tempfile
import threading
import traceback
import warnings

sys.dont_write_bytecode = True
script = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "bulk-consolidate.py")
spec = importlib.util.spec_from_file_location("bc", script)
bc = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bc)
bc.is_mounted = lambda p: True
bc.STOP_WAIT = 2
bc.time.sleep = lambda s: None

state = {}
gib = bc.gib


class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def do_POST(self):
        if self.headers.get("X-Transmission-Session-Id") != "sid":
            self.send_response(409)
            self.send_header("X-Transmission-Session-Id", "sid")
            self.end_headers()
            return
        req = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        m = req["method"]
        state["calls"].append(m)
        if m == "torrent-stop" and state["stop_works"]:
            state["status"] = 0
        if m == "torrent-start":
            state["status"] = 6
        args = {}
        if m == "torrent-get":
            args = {"torrents": [dict(t, status=state["status"]) for t in state["torrents"]]}
        out = json.dumps({"result": "success", "arguments": args}).encode()
        self.send_response(200)
        self.send_header("Content-Length", str(len(out)))
        self.end_headers()
        self.wfile.write(out)


srv = http.server.HTTPServer(("127.0.0.1", 0), H)
threading.Thread(target=srv.serve_forever, daemon=True).start()
RPC = f"http://127.0.0.1:{srv.server_port}/rpc"
SHOW_TORRENT = {"id": 7, "name": "Show.S01E05", "downloadDir": "/data/completed", "files": [{"name": "Show.S01E05/e5.mkv"}]}


def put(branch, rel, size, fill=b"x"):
    p = os.path.join(branch, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "wb") as f:
        f.write(fill * size)
    return p


def read(branch, rel):
    with open(os.path.join(branch, rel), "rb") as f:
        return f.read()


def nlink(branch, rel):
    return os.stat(os.path.join(branch, rel)).st_nlink


def exists(branch, rel):
    return os.path.lexists(os.path.join(branch, rel))


def show(A, B):
    for e in (1, 2, 3):
        put(A, f"Series/Show/Season 1/e{e}.mkv", 3000)
    put(B, "Series/Show/Season 1/e4.mkv", 1000)
    lib = put(B, "Series/Show/Season 1/e5.mkv", 1000)
    os.makedirs(os.path.join(B, "completed/Show.S01E05"))
    os.link(lib, os.path.join(B, "completed/Show.S01E05/e5.mkv"))


def tree(*branches):
    out = []
    for br in branches:
        for d, _, ns in os.walk(br):
            for n in ns:
                p = os.path.join(d, n)
                out.append(f"{p} links={os.stat(p).st_nlink}")
            out.append(f"{d}/")
    return sorted(out)


def run(A, B, execute=True, max_gib=200):
    argv = ["bc", "--branches", A, B, "--rpc", RPC, "--max-gib", str(max_gib)] + (["--execute"] if execute else [])
    buf = io.StringIO()
    code = 0
    old = sys.argv
    sys.argv = argv
    try:
        with contextlib.redirect_stdout(buf):
            bc.main()
    except SystemExit as e:
        code = e.code
    finally:
        sys.argv = old
    return code, buf.getvalue()


def t_happy_path(A, B):
    show(A, B)
    put(B, "Movies/Film (2020)/film.mkv", 5000)
    put(A, "Series/Show/Season 1/e1.nfo", 10)
    shutil.copy2(os.path.join(A, "Series/Show/Season 1/e1.nfo"), os.path.join(B, "Series/Show/Season 1/e1.nfo"))
    before = tree(A, B)
    code, out = run(A, B, execute=False)
    assert code == 0, out
    assert tree(A, B) == before, "dry run changed the tree"
    assert state["calls"].count("torrent-stop") == 0
    code, out = run(A, B)
    assert code == 0, out
    assert nlink(A, "Series/Show/Season 1/e4.mkv") == 1
    assert nlink(A, "Series/Show/Season 1/e5.mkv") == 2
    assert os.path.samefile(os.path.join(A, "Series/Show/Season 1/e5.mkv"), os.path.join(A, "completed/Show.S01E05/e5.mkv"))
    assert not exists(B, "Series/Show"), "emptied show dir left on the source"
    assert not exists(B, "completed/Show.S01E05"), "emptied torrent dir left on the source"
    assert exists(B, "completed") and exists(B, "Series"), "pruned a root"
    assert exists(B, "Movies/Film (2020)/film.mkv")
    assert state["calls"].count("torrent-stop") == 1 and state["calls"].count("torrent-start") == 1 and state["status"] == 6
    assert "Show.S01E05" in out
    after = tree(A, B)
    code, out = run(A, B)
    assert code == 0 and tree(A, B) == after, "second run is not a no-op"


def t_plain_changed_during_copy(A, B):
    show(A, B)
    state["torrents"] = []
    real = bc.copy_file

    def copy_then_touch(src, dst):
        real(src, dst)
        if src.endswith("e4.mkv"):
            with open(src, "ab") as f:
                f.write(b"new")
    bc.copy_file = copy_then_touch
    try:
        code, out = run(A, B)
    finally:
        bc.copy_file = real
    assert read(B, "Series/Show/Season 1/e4.mkv") == b"x" * 1000 + b"new"
    assert not exists(A, "Series/Show/Season 1/e4.mkv"), "stale copy kept on the target"
    assert "abort Series/Show/Season 1/e4.mkv" in out, out


def t_seeding_replaced_during_copy(A, B):
    show(A, B)
    real = bc.copy_file

    def copy_then_upgrade(src, dst):
        real(src, dst)
        if src.endswith("e5.mkv"):
            put(B, "Series/Show/Season 1/.up", 2000, b"y")
            os.rename(os.path.join(B, "Series/Show/Season 1/.up"), src)
    bc.copy_file = copy_then_upgrade
    bc.gib = lambda n: f"{n} B"
    try:
        code, out = run(A, B)
    finally:
        bc.copy_file = real
        bc.gib = gib
    assert read(B, "Series/Show/Season 1/e5.mkv") == b"y" * 2000, "upgraded library file lost"
    assert read(B, "completed/Show.S01E05/e5.mkv") == b"x" * 1000, "seeding file lost"
    assert not exists(A, "Series/Show/Season 1/e5.mkv") and not exists(A, "completed/Show.S01E05/e5.mkv")
    assert state["status"] == 6, "torrent left stopped"
    assert "done: 1000 B moved" in out, out


def t_different_file_at_target(A, B):
    show(A, B)
    put(A, "Series/Show/Season 1/e4.mkv", 999, b"z")
    code, out = run(A, B)
    assert read(B, "Series/Show/Season 1/e4.mkv") == b"x" * 1000
    assert read(A, "Series/Show/Season 1/e4.mkv") == b"z" * 999
    assert "a different file already exists" in out, out


def t_unknown_torrent(A, B):
    show(A, B)
    state["torrents"] = []
    code, out = run(A, B)
    assert nlink(B, "Series/Show/Season 1/e5.mkv") == 2 and nlink(B, "completed/Show.S01E05/e5.mkv") == 2
    assert not exists(A, "Series/Show/Season 1/e5.mkv")
    assert "not in Transmission" in out, out
    assert "torrent-stop" not in state["calls"]


def t_over_budget(A, B):
    show(A, B)
    code, out = run(A, B, max_gib=0)
    assert exists(B, "Series/Show/Season 1/e4.mkv") and nlink(B, "Series/Show/Season 1/e5.mkv") == 2
    assert not exists(A, "Series/Show/Season 1/e4.mkv")
    assert "over this run's budget" in out, out


def t_no_room(A, B):
    show(A, B)
    bc.MARGIN = 2**62
    try:
        code, out = run(A, B)
    finally:
        bc.MARGIN = 0
    assert exists(B, "Series/Show/Season 1/e4.mkv") and not exists(A, "Series/Show/Season 1/e4.mkv")
    assert "not enough free space" in out, out


def t_stop_timeout(A, B):
    show(A, B)
    state["stop_works"] = False
    code, out = run(A, B)
    assert nlink(B, "Series/Show/Season 1/e5.mkv") == 2 and nlink(B, "completed/Show.S01E05/e5.mkv") == 2
    assert not exists(A, "Series/Show/Season 1/e5.mkv")
    assert state["calls"][-1] == "torrent-start", state["calls"]
    assert "stop failed" in out and code == 1, (code, out)


def t_copy_fails(A, B):
    show(A, B)
    state["torrents"] = []
    real = bc.shutil.copyfileobj

    def enospc(fi, fo, n):
        fo.write(fi.read(10))
        raise OSError(errno.ENOSPC, "No space left on device")
    bc.shutil.copyfileobj = enospc
    try:
        code, out = run(A, B)
    finally:
        bc.shutil.copyfileobj = real
    left = [p for p in tree(A) if ".consolidating" in p]
    assert not left, left
    assert read(B, "Series/Show/Season 1/e4.mkv") == b"x" * 1000
    assert code == 1 and "error Series/Show/Season 1/e4.mkv" in out, (code, out)


def t_crash_after_link(A, B):
    show(A, B)
    os.makedirs(os.path.join(A, "completed/Show.S01E05"))
    shutil.copy2(os.path.join(B, "Series/Show/Season 1/e5.mkv"), os.path.join(A, "Series/Show/Season 1/e5.mkv"))
    os.link(os.path.join(A, "Series/Show/Season 1/e5.mkv"), os.path.join(A, "completed/Show.S01E05/e5.mkv"))
    code, out = run(A, B)
    assert code == 0, out
    assert not exists(B, "Series/Show/Season 1/e5.mkv") and not exists(B, "completed/Show.S01E05/e5.mkv")
    assert nlink(A, "Series/Show/Season 1/e5.mkv") == 2


def t_crash_after_link_source_replaced(A, B):
    show(A, B)
    os.makedirs(os.path.join(A, "completed/Show.S01E05"))
    shutil.copy2(os.path.join(B, "Series/Show/Season 1/e5.mkv"), os.path.join(A, "Series/Show/Season 1/e5.mkv"))
    os.link(os.path.join(A, "Series/Show/Season 1/e5.mkv"), os.path.join(A, "completed/Show.S01E05/e5.mkv"))
    os.unlink(os.path.join(A, "Series/Show/Season 1/e5.mkv"))
    put(A, "Series/Show/Season 1/e5.mkv", 1000)
    os.utime(os.path.join(A, "Series/Show/Season 1/e5.mkv"), ns=(0, os.stat(os.path.join(B, "Series/Show/Season 1/e5.mkv")).st_mtime_ns))
    code, out = run(A, B)
    assert nlink(B, "Series/Show/Season 1/e5.mkv") == 2, "sources deleted although the target names are different files"


def t_already_stopped(A, B):
    show(A, B)
    state["status"] = 0
    code, out = run(A, B)
    assert code == 0, out
    assert nlink(A, "Series/Show/Season 1/e5.mkv") == 2
    assert "already stopped" in out and ": stop," not in out, out
    assert "torrent-start" not in state["calls"] and state["status"] == 0


def t_file_vanishes_during_walk(A, B):
    show(A, B)
    real = os.walk

    def with_ghost(top, *a, **k):
        for d, ds, ns in real(top, *a, **k):
            yield d, ds, ns + ["ghost.mkv"]
    os.walk = with_ghost
    try:
        code, out = run(A, B)
    finally:
        os.walk = real
    assert code == 0, out
    assert exists(A, "Series/Show/Season 1/e4.mkv")


def in_child(A, B, patch):
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", DeprecationWarning)
        pid = os.fork()
    if pid == 0:
        code = 2
        try:
            patch()
            code, _ = run(A, B)
        finally:
            os._exit(code if isinstance(code, int) else 2)
    _, status = os.waitpid(pid, 0)
    return os.waitstatus_to_exitcode(status)


def term_on_e5_copy():
    def copy(fi, fo, n):
        fo.write(fi.read(10))
        if fi.name.endswith("e5.mkv"):
            os.kill(os.getpid(), signal.SIGTERM)
        fo.write(fi.read())
    bc.shutil.copyfileobj = copy


def t_sigterm_mid_copy(A, B):
    show(A, B)
    code = in_child(A, B, term_on_e5_copy)
    assert code == 143, code
    assert state["status"] == 6, "torrent left stopped"
    left = [p for p in tree(A) if ".consolidating" in p]
    assert not left, left
    assert nlink(B, "Series/Show/Season 1/e5.mkv") == 2


def t_sigterm_while_stopping(A, B):
    show(A, B)
    state["stop_works"] = False

    def patch():
        bc.time.sleep = lambda s: os.kill(os.getpid(), signal.SIGTERM)
    code = in_child(A, B, patch)
    assert code == 143, code
    assert state["calls"][-1] == "torrent-start", state["calls"]
    assert nlink(B, "Series/Show/Season 1/e5.mkv") == 2


def t_second_sigterm_during_restart(A, B):
    show(A, B)

    def patch():
        term_on_e5_copy()
        real = bc.Transmission.start

        def start(self, tid):
            os.kill(os.getpid(), signal.SIGTERM)
            real(self, tid)
        bc.Transmission.start = start
    code = in_child(A, B, patch)
    assert code == 143, code
    assert state["status"] == 6 and state["calls"][-1] == "torrent-start", state["calls"]


def t_lock_held(A, B):
    show(A, B)
    with open(bc.LOCK, "w") as held:
        fcntl.flock(held, fcntl.LOCK_EX)
        code, out = run(A, B)
    assert isinstance(code, str) and "another bulk-consolidate run" in code, code
    assert not exists(A, "Series/Show/Season 1/e4.mkv")


TESTS = [v for k, v in list(globals().items()) if k.startswith("t_")]


def main():
    failed = []
    with tempfile.TemporaryDirectory() as root:
        for t in TESTS:
            d = tempfile.mkdtemp(dir=root)
            A, B = os.path.join(d, "a"), os.path.join(d, "b")
            for br in (A, B):
                for lib in ("Series", "Movies", "completed"):
                    os.makedirs(os.path.join(br, lib))
            bc.LOCK = os.path.join(d, "lock")
            bc.MARGIN = 0
            signal.signal(signal.SIGTERM, signal.SIG_DFL)
            state.update(status=6, calls=[], stop_works=True, torrents=[SHOW_TORRENT])
            try:
                t(A, B)
                print(f"PASS {t.__name__}")
            except Exception:
                failed.append(t.__name__)
                print(f"FAIL {t.__name__}\n{traceback.format_exc()}")
    print("ALL OK" if not failed else f"FAILED: {' '.join(failed)}")
    sys.exit(1 if failed else 0)


main()
