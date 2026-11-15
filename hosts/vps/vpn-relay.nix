# Relay for the homelab's wg-home VPN, so phones/laptops reach it via the VPS instead of
# a DNS name pointing at the home IP:
#
#   phone ──WireGuard──▶ 198.245.55.120:51821 ──DNAT, inside wg-vps──▶ 10.8.0.2:51821 (wg-home)
#
# The VPS only forwards the encrypted UDP; the keys live on the devices and the homelab, so it
# can't read or inject VPN traffic. Masquerading to 10.8.0.1 makes the homelab answer back
# through wg-vps rather than from its public IP. Clients must use the IPv4 address (no v6 DNAT)
# and MTU 1280 (WireGuard inside WireGuard).
{ ... }:
let
  port = "51821";
  homelab = "10.8.0.2";
in
{
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # Own chains, flushed and re-filled on every firewall (re)start; FORWARD only allows the relay.
  networking.firewall.extraCommands = ''
    iptables -t nat -N vpn-relay-pre 2>/dev/null || iptables -t nat -F vpn-relay-pre
    iptables -t nat -A vpn-relay-pre -i ens3 -p udp --dport ${port} -j DNAT --to-destination ${homelab}:${port}
    iptables -t nat -C PREROUTING -j vpn-relay-pre 2>/dev/null || iptables -t nat -A PREROUTING -j vpn-relay-pre

    iptables -t nat -N vpn-relay-post 2>/dev/null || iptables -t nat -F vpn-relay-post
    iptables -t nat -A vpn-relay-post -o wg-vps -p udp -d ${homelab} --dport ${port} -j MASQUERADE
    iptables -t nat -C POSTROUTING -j vpn-relay-post 2>/dev/null || iptables -t nat -A POSTROUTING -j vpn-relay-post

    iptables -N vpn-relay-fwd 2>/dev/null || iptables -F vpn-relay-fwd
    iptables -A vpn-relay-fwd -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A vpn-relay-fwd -i ens3 -o wg-vps -p udp -d ${homelab} --dport ${port} -j ACCEPT
    iptables -A vpn-relay-fwd -j DROP
    iptables -C FORWARD -j vpn-relay-fwd 2>/dev/null || iptables -A FORWARD -j vpn-relay-fwd
  '';
  networking.firewall.extraStopCommands = ''
    iptables -t nat -D PREROUTING -j vpn-relay-pre 2>/dev/null || true
    iptables -t nat -D POSTROUTING -j vpn-relay-post 2>/dev/null || true
    iptables -D FORWARD -j vpn-relay-fwd 2>/dev/null || true
  '';
}
