# Minimal firewall for a public web server (answer key)

```bash
# Default deny inbound; allow nothing unless explicit
iptables -P INPUT  DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT      # outbound is normally allowed; tighten with egress filtering separately

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Public web
iptables -A INPUT -p tcp --dport 80  -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Office SSH only
iptables -A INPUT -p tcp -s 203.0.113.0/24 --dport 22 -j ACCEPT

# Monitoring
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 5/sec -j ACCEPT

# Log slow, drop fast
iptables -A INPUT -m limit --limit 2/min -j LOG --log-prefix "IPTABLES-DROP: "
iptables -A INPUT -j DROP
```

Notes:
- We rate-limit ICMP so the host can still be pinged for monitoring without becoming a flood amplifier.
- We rate-limit drop logs to avoid filling the disk during a scan.
- We drop `INVALID` conntrack state explicitly — a common gap in copy-pasted rulesets.
- Outbound is left open; in higher-security environments, egress filter to known hosts only.
