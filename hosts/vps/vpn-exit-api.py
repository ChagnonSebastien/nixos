"""Writes the provider's servers for one country, best score first, for vpn-exit.sh.

Uses Proton's own Linux client libraries, identified as their CLI, so the traffic matches the
official client. ProtonVPNAPI is never built: it is what turns on Proton's crash reporting.

  vpn-exit-api login   interactive, once; stores a session (not the password) in STATE_DIR
  vpn-exit-api update  refreshes the session, list and loads; writes STATE_DIR/servers
"""
import asyncio
import getpass
import os
import sys
import tempfile
from pathlib import Path

STATE_DIR = Path(os.environ.get("STATE_DIR", "/var/lib/vpn-exit-api"))
COUNTRY = os.environ.get("COUNTRY", "CA")
WG_PORT = 51820

# the libraries resolve their paths once, at import, from the XDG variables
for var, sub in (("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache"), ("XDG_RUNTIME_DIR", "run")):
    path = STATE_DIR / sub
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.environ[var] = str(path)

from proton.session.exceptions import ProtonAPIHumanVerificationNeeded  # noqa: E402
from proton.vpn.core.session_holder import ClientTypeMetadata, SessionHolder  # noqa: E402
from proton.vpn.session.servers.types import ServerFeatureEnum  # noqa: E402

EXCLUDED = ServerFeatureEnum.SECURE_CORE | ServerFeatureEnum.TOR


def holder():
    return SessionHolder(ClientTypeMetadata(type="cli"))


async def login():
    username = input("Proton username: ")
    password = getpass.getpass("Password: ")
    session = holder().get_session_for(username)
    headers = None
    while True:
        try:
            ok = await session.async_authenticate(username, password, additional_headers=headers)
            break
        except ProtonAPIHumanVerificationNeeded as e:
            token = e.HumanVerificationToken
            print(f"Proton wants human verification (methods: {', '.join(e.HumanVerificationMethods)}).")
            print(f"Open https://verify.proton.me/?methods=captcha&token={token} in a browser, solve it,")
            input("then press Enter to retry. ")
            headers = {
                "x-pm-human-verification-token": token,
                "x-pm-human-verification-token-type": "captcha",
            }
    if not ok:
        sys.exit("login failed: wrong username or password")
    while session.needs_twofa:
        result = await session.provide_2fa_code(input("2FA code: "))
        if not result.success:
            print("wrong code")
    await session.fetch_session_data()
    print(f"logged in; {write_servers(session)} servers in {COUNTRY} written to {STATE_DIR / 'servers'}")


def write_servers(session):
    tier = session.vpn_account.max_tier
    lines = []
    for server in sorted(session.server_list.logicals, key=lambda s: s.score):
        if server.exit_country.upper() != COUNTRY or not server.enabled or server.tier > tier:
            continue
        if any(f & EXCLUDED for f in server.features):
            continue
        physical = next((p for p in server.physical_servers if p.enabled and p.x25519_pk), None)
        if physical is None:
            continue
        name = server.name.replace(" ", "_")
        lines.append(f"{name} {physical.entry_ip}:{WG_PORT} {physical.x25519_pk} {server.score} {server.load}\n")
    if not lines:
        raise RuntimeError(f"no usable server in {COUNTRY}; keeping the previous list")
    with tempfile.NamedTemporaryFile("w", dir=STATE_DIR, delete=False) as f:
        f.writelines(lines)
    os.chmod(f.name, 0o644)
    os.replace(f.name, STATE_DIR / "servers")
    return len(lines)


async def update():
    session = holder().session
    if not session.logged_in:
        sys.exit("no session: run `vpn-exit-api login` on the VPS")
    if not session.loaded or session.server_list.expired:
        await session.fetch_session_data()
    elif session.server_list.loads_expired:
        await session.update_server_loads()
    print(f"{write_servers(session)} servers in {COUNTRY}")


def main():
    commands = {"login": login, "update": update}
    if len(sys.argv) != 2 or sys.argv[1] not in commands:
        sys.exit("usage: vpn-exit-api login|update")
    asyncio.run(commands[sys.argv[1]]())


main()
