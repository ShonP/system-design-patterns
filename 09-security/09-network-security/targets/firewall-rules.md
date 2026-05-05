# Sample iptables ruleset (to read for exercise 6)
# This is a hypothetical jump host. Read line by line; what does each rule do?

# Default policies
iptables -P INPUT  DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT  -i lo -j ACCEPT

# Stateful: keep established conns
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# SSH from office VPN only
iptables -A INPUT -p tcp -s 10.99.0.0/16 --dport 22 -j ACCEPT

# ICMP for monitoring
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Log+drop everything else (don't fill the disk: rate-limit logs)
iptables -A INPUT -m limit --limit 2/min -j LOG --log-prefix "IPTABLES-DROP: " --log-level 7
iptables -A INPUT -j DROP
