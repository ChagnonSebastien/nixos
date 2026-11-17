# Keeps wg-upstream on the fastest of a few candidate servers (lines: name endpoint publickey).
# Candidates are the best-scored entries of $API_SERVERS_FILE while vpn-exit-api keeps it fresh,
# else $STATIC_SERVERS_FILE, so the provider's API can break without taking the exit down.
# The live tunnel uses $LIVE_KEY and candidates are tested with $PROBE_KEY: a provider may allow
# one connection per key, and testing with the live key would cut the live tunnel.
# Usage: vpn-exit setup | check | select | teardown
# Env (set by vpn-exit.nix): STATIC_SERVERS_FILE API_SERVERS_FILE API_MAX_AGE API_CANDIDATES
#   LIVE_KEY PROBE_KEY ADDRESS STATE_DIR METRICS_FILE TABLE CLIENT_IF PROBE_TARGET

active_file="$STATE_DIR/active"
last_select_file="$STATE_DIR/last-select"
last_healthy_file="$STATE_DIR/last-healthy"
last_rtt_file="$STATE_DIR/last-rtt"
probe_ns=vpn-exit-probe
reselect_after=1800
# a better server must beat the active one by both margins, since switching changes the
# public IP and drops every open connection
min_gain_ms=5
min_gain_ratio=0.8
ping_args=(-q -c 5 -i 0.2 -W 2)

# reads `ping -q` output; prints the average RTT in ms when at least 3 of 5 replies came back
avg_rtt() {
  awk '/packets transmitted/ { rx = $4 } /^rtt/ { split($4, a, "/"); avg = a[2] }
       END { if (rx >= 3 && avg != "") print avg; else exit 1 }'
}

# replies only start a second or two after a (re)handshake; args are the ping command to use
warm_up() {
  local _
  for _ in 1 2 3 4 5 6 7 8; do
    "$@" -q -c 1 -W 1 "$PROBE_TARGET" > /dev/null 2>&1 && return 0
  done
}

active_rtt() {
  local rtt
  warm_up ping -I wg-upstream || true
  rtt=$({ ping "${ping_args[@]}" -I wg-upstream "$PROBE_TARGET" 2> /dev/null || true; } | avg_rtt) || return 1
  date +%s > "$last_healthy_file"
  echo "$rtt" | tee "$last_rtt_file"
}

api_age() {
  local mtime
  mtime=$(stat -c %Y "$API_SERVERS_FILE" 2> /dev/null) || { echo -1; return; }
  echo $(($(date +%s) - mtime))
}

# the active server is always measured, even when it dropped out of the candidates; servers are
# matched by public key, since the provider's name for a machine changes between refreshes
candidates() {
  local age active
  age=$(api_age)
  if [ "$age" -ge 0 ] && [ "$age" -le "$API_MAX_AGE" ]; then
    head -n "$API_CANDIDATES" "$API_SERVERS_FILE" | cut -d' ' -f1-3
  else
    if [ "$age" -lt 0 ]; then
      echo "no provider API data; using the static server list" >&2
    else
      echo "provider API data is ${age}s old; using the static server list" >&2
    fi
    cat "$STATIC_SERVERS_FILE"
  fi > "$STATE_DIR/candidates"
  active=$(cat "$active_file" 2> /dev/null || true)
  if [ -n "$active" ] && ! cut -d' ' -f3 "$STATE_DIR/candidates" | grep -qxF "${active##* }"; then
    echo "$active" >> "$STATE_DIR/candidates"
  fi
  cat "$STATE_DIR/candidates"
}

# Brings the candidate up in its own namespace so the probe never touches the live exit;
# the UDP socket stays in the root namespace, as for any WireGuard interface moved after creation.
probe() {
  local endpoint=$1 public_key=$2 rtt
  ip -n "$probe_ns" link del wg-probe 2> /dev/null || true
  ip link add wg-probe type wireguard
  wg set wg-probe private-key "$PROBE_KEY" peer "$public_key" endpoint "$endpoint" allowed-ips 0.0.0.0/0
  ip link set wg-probe netns "$probe_ns"
  ip -n "$probe_ns" addr add "$ADDRESS/32" dev wg-probe
  ip -n "$probe_ns" link set wg-probe up
  ip -n "$probe_ns" route add default dev wg-probe
  warm_up ip netns exec "$probe_ns" ping || true
  rtt=$({ ip netns exec "$probe_ns" ping "${ping_args[@]}" "$PROBE_TARGET" 2> /dev/null || true; } | avg_rtt) || rtt=''
  ip -n "$probe_ns" link del wg-probe
  [ -n "$rtt" ] && echo "$rtt"
}

switch_to() {
  local name=$1 endpoint=$2 public_key=$3 removals=() p
  for p in $(wg show wg-upstream peers); do removals+=(peer "$p" remove); done
  wg set wg-upstream private-key "$LIVE_KEY" "${removals[@]}" \
    peer "$public_key" endpoint "$endpoint" allowed-ips 0.0.0.0/0 persistent-keepalive 25
  echo "$name $endpoint $public_key" > "$active_file"
  echo "switched to $name"
}

select_server() {
  local active active_key best='' best_key='' best_line='' best_rtt='' rtt active_ms='' name endpoint public_key
  active=$(cut -d' ' -f1 "$active_file" 2> /dev/null || true)
  active_key=$(cut -d' ' -f3 "$active_file" 2> /dev/null || true)
  while read -r name endpoint public_key; do
    [ -n "$name" ] || continue
    if [ -n "$active_key" ] && [ "$public_key" = "$active_key" ]; then
      rtt=$(active_rtt) || rtt=''
      active_ms=$rtt
    else
      rtt=$(probe "$endpoint" "$public_key") || rtt=''
    fi
    echo "$name: ${rtt:-unreachable}${rtt:+ ms}"
    [ -n "$rtt" ] || continue
    if [ -z "$best" ] || awk -v a="$rtt" -v b="$best_rtt" 'BEGIN { exit !(a < b) }'; then
      best=$name best_key=$public_key best_line="$name $endpoint $public_key" best_rtt=$rtt
    fi
  done < <(candidates)
  date +%s > "$last_select_file"

  if [ -z "$best" ]; then
    echo "no candidate server answered; client traffic is blackholed until one does" >&2
    return 1
  fi
  if [ "$best_key" = "$active_key" ]; then
    return 0
  fi
  if [ -n "$active_ms" ] && ! awk -v b="$best_rtt" -v a="$active_ms" -v g="$min_gain_ms" -v r="$min_gain_ratio" \
      'BEGIN { exit !(a - b > g && b < a * r) }'; then
    echo "keeping $active ($active_ms ms), $best ($best_rtt ms) is not enough faster"
    return 0
  fi
  # shellcheck disable=SC2086
  switch_to $best_line
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

# node_exporter textfile collector format; written on every run, success or not
write_metrics() {
  local active rtt='' healthy tmp
  active=$(cut -d' ' -f1 "$active_file" 2> /dev/null || true)
  healthy=$(cat "$last_healthy_file" 2> /dev/null || echo 0)
  # every run measures the active server, so an older answer means it stopped answering
  if [ $(($(date +%s) - healthy)) -lt 120 ]; then
    rtt=$(cat "$last_rtt_file" 2> /dev/null || true)
  fi
  tmp=$(mktemp "$METRICS_FILE.XXXXXX")
  {
    echo "# HELP vpn_exit_up Whether the active upstream server answers through the live tunnel."
    echo "# TYPE vpn_exit_up gauge"
    if [ -n "$rtt" ]; then echo "vpn_exit_up 1"; else echo "vpn_exit_up 0"; fi
    echo "# HELP vpn_exit_active_rtt_seconds Round trip to the probe target through the live tunnel."
    echo "# TYPE vpn_exit_active_rtt_seconds gauge"
    [ -n "$rtt" ] && awk -v r="$rtt" 'BEGIN { printf "vpn_exit_active_rtt_seconds %.6f\n", r / 1000 }'
    echo "# HELP vpn_exit_last_healthy_timestamp_seconds Last time the live tunnel answered."
    echo "# TYPE vpn_exit_last_healthy_timestamp_seconds gauge"
    echo "vpn_exit_last_healthy_timestamp_seconds $healthy"
    echo "# HELP vpn_exit_api_servers_age_seconds Age of the provider API server list, -1 when missing."
    echo "# TYPE vpn_exit_api_servers_age_seconds gauge"
    echo "vpn_exit_api_servers_age_seconds $(api_age)"
    echo "# HELP vpn_exit_active_server The active upstream server."
    echo "# TYPE vpn_exit_active_server gauge"
    [ -n "$active" ] && echo "vpn_exit_active_server{server=\"$active\"} 1"
  } > "$tmp"
  chmod 644 "$tmp"
  mv "$tmp" "$METRICS_FILE"
}

setup() {
  ip link show wg-upstream > /dev/null 2>&1 || ip link add wg-upstream type wireguard
  ip addr replace "$ADDRESS/32" dev wg-upstream
  ip link set wg-upstream up
  ip route replace default dev wg-upstream table "$TABLE"
  # kill switch: with wg-upstream down or without a peer, client traffic dies here instead of
  # leaving via the WAN
  ip route replace blackhole default metric 4096 table "$TABLE"
  ip rule del pref 1000 2> /dev/null || true
  ip rule add pref 1000 iif "$CLIENT_IF" lookup "$TABLE"
  ip rule del pref 1001 2> /dev/null || true
  ip rule add pref 1001 from "$ADDRESS" lookup "$TABLE"
  ip netns add "$probe_ns" 2> /dev/null || true
  : > "$active_file"
  rm -f "$last_select_file"
}

teardown() {
  ip rule del pref 1000 2> /dev/null || true
  ip rule del pref 1001 2> /dev/null || true
  ip link del wg-upstream 2> /dev/null || true
  ip route flush table "$TABLE" 2> /dev/null || true
  ip netns del "$probe_ns" 2> /dev/null || true
}

status=0
case "${1:-}" in
  setup) setup ;;
  check) check || status=$? ;;
  select) select_server || status=$? ;;
  teardown) teardown ;;
  *) echo "usage: vpn-exit setup|check|select|teardown" >&2; exit 2 ;;
esac
case "${1:-}" in check | select) write_metrics ;; esac
exit "$status"
