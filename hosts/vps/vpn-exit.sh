# Keeps wg-upstream on the fastest server among the WireGuard client configs in
# $SERVERS_DIR/*.conf (standard wg-quick files: PrivateKey, Address, PublicKey, Endpoint).
# Usage: vpn-exit setup | check | select | teardown
# Env (set by vpn-exit.nix): SERVERS_DIR STATE_DIR TABLE CLIENT_IF PROBE_TARGET

servers="$SERVERS_DIR"
active_file="$STATE_DIR/active"
last_select_file="$STATE_DIR/last-select"
probe_ns=vpn-exit-probe
reselect_after=1800
# a better server must beat the active one by both margins, since switching changes the
# public IP and drops every open connection
min_gain_ms=5
min_gain_ratio=0.8
ping_args=(-q -c 5 -i 0.2 -W 2)

field() {
  awk -F' *= *' -v k="$1" '$1 == k { print $2; exit }' "$2"
}

# first IPv4 of the config's Address line, without the prefix length
address() {
  field Address "$1" | tr ',' '\n' | awk -F/ '$1 ~ /^[0-9.]+$/ { print $1; exit }' | tr -d ' '
}

# reads `ping -q` output; prints the average RTT in ms when at least 3 of 5 replies came back
avg_rtt() {
  awk '/packets transmitted/ { rx = $4 } /^rtt/ { split($4, a, "/"); avg = a[2] }
       END { if (rx >= 3 && avg != "") print avg; else exit 1 }'
}

active_rtt() {
  { ping "${ping_args[@]}" -I wg-upstream "$PROBE_TARGET" 2> /dev/null || true; } | avg_rtt
}

# Brings the candidate up in its own namespace so the probe never touches the live exit;
# the UDP socket stays in the root namespace, as for any WireGuard interface moved after creation.
probe() {
  local conf=$1 rtt
  ip -n "$probe_ns" link del wg-probe 2> /dev/null || true
  ip link add wg-probe type wireguard
  wg set wg-probe private-key <(field PrivateKey "$conf") \
    peer "$(field PublicKey "$conf")" endpoint "$(field Endpoint "$conf")" allowed-ips 0.0.0.0/0
  ip link set wg-probe netns "$probe_ns"
  ip -n "$probe_ns" addr add "$(address "$conf")/32" dev wg-probe
  ip -n "$probe_ns" link set wg-probe up
  ip -n "$probe_ns" route add default dev wg-probe
  # the first packet waits for the handshake, which the live tunnel has already done
  ip netns exec "$probe_ns" ping -q -c 1 -W 3 "$PROBE_TARGET" > /dev/null 2>&1 || true
  rtt=$({ ip netns exec "$probe_ns" ping "${ping_args[@]}" "$PROBE_TARGET" 2> /dev/null || true; } | avg_rtt) || rtt=''
  ip -n "$probe_ns" link del wg-probe
  [ -n "$rtt" ] && echo "$rtt"
}

switch_to() {
  local conf=$1 addr removals=() p
  addr=$(address "$conf")
  for p in $(wg show wg-upstream peers); do removals+=(peer "$p" remove); done
  wg set wg-upstream private-key <(field PrivateKey "$conf") "${removals[@]}" \
    peer "$(field PublicKey "$conf")" endpoint "$(field Endpoint "$conf")" \
    allowed-ips 0.0.0.0/0 persistent-keepalive 25
  ip addr flush dev wg-upstream
  ip addr add "$addr/32" dev wg-upstream
  ip route replace default dev wg-upstream table "$TABLE"
  ip rule del pref 1001 2> /dev/null || true
  ip rule add pref 1001 from "$addr" lookup "$TABLE"
  basename "$conf" > "$active_file"
  echo "switched to $(basename "$conf")"
}

select_server() {
  local active best='' best_rtt='' rtt active_ms='' conf name
  active=$(cat "$active_file" 2> /dev/null || true)
  shopt -s nullglob
  for conf in "$servers"/*.conf; do
    name=$(basename "$conf")
    if [ "$name" = "$active" ]; then
      rtt=$(active_rtt) || rtt=''
      active_ms=$rtt
    else
      rtt=$(probe "$conf") || rtt=''
    fi
    echo "$name: ${rtt:-unreachable}${rtt:+ ms}"
    [ -n "$rtt" ] || continue
    if [ -z "$best" ] || awk -v a="$rtt" -v b="$best_rtt" 'BEGIN { exit !(a < b) }'; then
      best=$conf best_rtt=$rtt
    fi
  done
  date +%s > "$last_select_file"

  if [ -z "$best" ]; then
    echo "no server in $servers answered; client traffic is blackholed until one does" >&2
    return 1
  fi
  if [ "$(basename "$best")" = "$active" ]; then
    return 0
  fi
  if [ -n "$active_ms" ] && ! awk -v b="$best_rtt" -v a="$active_ms" -v g="$min_gain_ms" -v r="$min_gain_ratio" \
      'BEGIN { exit !(a - b > g && b < a * r) }'; then
    echo "keeping $active ($active_ms ms), $(basename "$best") ($best_rtt ms) is not enough faster"
    return 0
  fi
  switch_to "$best"
}

check() {
  local last now
  last=$(cat "$last_select_file" 2> /dev/null || echo 0)
  now=$(date +%s)
  if [ -s "$active_file" ] && active_rtt > /dev/null && [ $((now - last)) -lt "$reselect_after" ]; then
    return 0
  fi
  select_server
}

setup() {
  ip link show wg-upstream > /dev/null 2>&1 || ip link add wg-upstream type wireguard
  ip link set wg-upstream up
  # kill switch: with wg-upstream down or unconfigured, client traffic dies here instead of
  # leaving via the WAN
  ip route replace blackhole default metric 4096 table "$TABLE"
  ip rule del pref 1000 2> /dev/null || true
  ip rule add pref 1000 iif "$CLIENT_IF" lookup "$TABLE"
  ip netns add "$probe_ns" 2> /dev/null || true
  : > "$active_file"
  rm -f "$last_select_file"
}

teardown() {
  ip rule del pref 1000 2> /dev/null || true
  ip rule del pref 1001 2> /dev/null || true
  ip link del wg-upstream 2> /dev/null || true
  ip netns del "$probe_ns" 2> /dev/null || true
}

case "${1:-}" in
  setup) setup ;;
  check) check ;;
  select) select_server ;;
  teardown) teardown ;;
  *) echo "usage: vpn-exit setup|check|select|teardown" >&2; exit 2 ;;
esac
