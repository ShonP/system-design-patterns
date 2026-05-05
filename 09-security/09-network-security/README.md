# Lab 09 — Network Security: Nmap, Nuclei & Packet Analysis

## 🎯 What you'll learn

- Use **Nmap** for host discovery, port scanning, version detection, and NSE scripts
- Use **Nuclei** to fingerprint and confirm CVEs over the network
- Capture and analyze packets with `tshark` (Wireshark CLI)
- Read **firewall rules** and design a minimal allowlist
- Understand the difference between active scanning (with permission!) vs passive reconnaissance

> ⚠️ Run **only against the lab targets** in `targets/`, your own private VPN, or hosts you have explicit written permission to scan. Port scanning random IPs is illegal in many jurisdictions.

## 📋 Prerequisites

- Docker
- Lab 05 helpful for Nuclei context

## 🔧 Setup

This lab brings up three intentionally-imperfect targets on a private Docker network:

```text
seclabs09-net   (192.168.198.0/24)
├── target-web   (vulnerable Nginx + sample app)
├── target-ssh   (OpenSSH on a non-default port, weak banner)
└── attacker     (Kali-style toolbox: nmap + nuclei + tshark + nikto)
```

```bash
$ cd 09-network-security
$ docker compose up -d
$ docker compose exec attacker nmap --version
```

When done:

```bash
$ docker compose down -v
```

---

## 📝 Exercises

### Exercise 1 — Discover targets on the lab network

```bash
$ ./scripts/in-attacker.sh "nmap -sn 192.168.198.0/24"
```

> ✅ Expected: 2–3 hosts discovered (web, ssh, attacker itself).

### Exercise 2 — Port scan & service detection

Three increasingly thorough scans:

```bash
$ ./scripts/in-attacker.sh "nmap target-web"                           # default 1000-port TCP SYN
$ ./scripts/in-attacker.sh "nmap -p- target-web"                       # all 65k ports
$ ./scripts/in-attacker.sh "nmap -sV -sC -p 22,80,443,8080 target-web" # version + default scripts
```

Read the output:

- **Port state** = `open` / `closed` / `filtered` (filtered = something dropped the SYN)
- **Service** = banner-based guess
- **Version** = with `-sV`, Nmap probes for exact versions
- **NSE script output** = with `-sC`, runs the "default" scripts (e.g., HTTP title, SSL cert, DNS, robots.txt)

### Exercise 3 — Targeted NSE scripts

Nmap ships with [600+ NSE scripts](https://nmap.org/nsedoc/). Useful categories:

```bash
$ ./scripts/in-attacker.sh "nmap --script=ssl-enum-ciphers -p 443 target-web"
$ ./scripts/in-attacker.sh "nmap --script=http-headers,http-security-headers -p 80,8080 target-web"
$ ./scripts/in-attacker.sh "nmap --script=ssh2-enum-algos,ssh-hostkey -p 2222 target-ssh"
$ ./scripts/in-attacker.sh "nmap --script=vulners -sV -p 80 target-web"
```

> 💡 **`vulners`** correlates Nmap version output against the Vulners CVE DB. Cheap CVE finding from a port scan.

### Exercise 4 — Nuclei (templated CVE checks)

```bash
$ ./scripts/in-attacker.sh "nuclei -u http://target-web -severity medium,high,critical"
$ ./scripts/in-attacker.sh "nuclei -u http://target-web -t http/exposures"
```

This is the modern shape of "fast vuln scanning over the network" — every check is a YAML file, easy to read, easy to add.

### Exercise 5 — Packet capture with tshark

```bash
$ ./scripts/capture.sh 30   # captures 30 seconds of traffic into exercises/capture.pcap
```

In another terminal, generate traffic:

```bash
$ ./scripts/in-attacker.sh "curl http://target-web/login -d 'user=admin&pass=hunter2'"
```

Read the pcap:

```bash
$ ./scripts/in-attacker.sh "tshark -r /workspace/exercises/capture.pcap -Y 'http.request' -T fields -e ip.src -e http.request.method -e http.request.uri"
$ ./scripts/in-attacker.sh "tshark -r /workspace/exercises/capture.pcap -Y 'http' -T fields -e http.host -e http.user_agent | sort -u"
```

> 💡 **Anything not over TLS is on the wire in plaintext.** Including the password you just sent. This is why every exercise in lab 10 enforces HTTPS.

### Exercise 6 — Read firewall rules

Look at `targets/firewall-rules.md`. It's an iptables ruleset for a hypothetical jump host. Walk through it line-by-line:

- What's the **default policy** for INPUT? FORWARD? OUTPUT?
- Which sources can reach SSH?
- Which protocols are explicitly blocked?

Then design **the minimal ruleset** for a public web server that:
- Serves HTTP/HTTPS to the world
- Allows SSH only from your office's CIDR
- Allows ICMP echo-request (for monitoring)
- Drops everything else and logs the drops

Write your answer in `exercises/min-firewall.md`. Compare with the answer key (`targets/firewall-answer.md`).

### Exercise 7 — Network policy = firewall, but in Kubernetes

(Cross-reference for lab 06.)

```text
iptables INPUT chain   ↔   NetworkPolicy.ingress
iptables OUTPUT chain  ↔   NetworkPolicy.egress
default DROP           ↔   default-deny NetworkPolicy
```

The mental model is the same. The implementation moves from a kernel module to a CRD enforced by the CNI.

### Exercise 8 — Save and re-run a scan profile

Real engagements have many targets and consistent output formats:

```bash
$ ./scripts/in-attacker.sh "nmap -sV -sC -oA /workspace/exercises/web-scan target-web"
$ ls exercises/web-scan.*
# .nmap   .gnmap   .xml
$ ./scripts/in-attacker.sh "xsltproc /workspace/exercises/web-scan.xml -o /workspace/exercises/web-scan.html" || true
```

Now you have the same scan in 4 formats. **`.xml`** is the one that pipes into other tools (Metasploit, Faraday, custom scripts). **`.gnmap`** (greppable) is great for quick `awk` work.

---

## 💡 Key Concepts

| Concept                | TL;DR                                                                                     |
|------------------------|-------------------------------------------------------------------------------------------|
| **TCP SYN scan (`-sS`)**| Default. Fast. Doesn't complete the handshake — many IDS catch it anyway.                 |
| **Connect scan (`-sT`)**| Full TCP handshake. Slower, noisier. Use when you can't `RAW` socket (no root).           |
| **UDP scan (`-sU`)**   | Slow, unreliable. Don't forget DNS/53, NTP/123, SNMP/161, mDNS/5353.                       |
| **Service detection (`-sV`)**| Probes the port for banner + protocol fingerprint. Foundation for vuln matching.    |
| **NSE**                | Lua scripts that extend Nmap. Categories: `auth`, `default`, `discovery`, `vuln`, …       |
| **Banner grabbing**    | Reading the first bytes the service emits. The fastest version detection method.          |
| **Firewall: stateful** | Tracks connections; `ESTABLISHED, RELATED → ACCEPT` is the canonical first rule.          |
| **Default-deny**       | The single most important firewall principle. Every modern lab in this repo applies it.   |

### Recon → exploit kill chain

```text
1. Enumerate hosts (ping sweep, ARP, mDNS, DNS)
2. Scan ports     (nmap -sS)
3. Identify svcs  (nmap -sV)
4. Match CVEs     (nmap --script vulners,  nuclei -t http/cves)
5. Confirm        (nuclei templates, manual repro, exploit-db)
6. Exploit        (red-team only, with permission!)
```

You'll do steps 1–5 in this lab. Step 6 belongs in a CTF.

### Why most enterprise networks are flat (and how to fix it)

```text
        legacy:                                 modern:
   ┌──────────────┐                       ┌─────────────────────┐
   │  flat /16    │                       │  micro-segmented    │
   │  everyone    │                       │  per-workload SG /  │
   │  pings ev'one│       →               │  NetworkPolicy      │
   └──────────────┘                       └─────────────────────┘
   one bad pod = whole          one bad pod = blast radius
   network compromised          contained to its segment
```

---

## 🏆 Challenge

1. **Build an attack-surface report.** Scan the lab targets fully (`-p- -sV -sC`). Cross-reference with `nuclei` and `nikto`. Produce a single Markdown report grouped by host, listing service / version / CVEs / suggested mitigations.
2. **Stealth scan.** Use Nmap's timing templates (`-T0` `paranoid` to `-T5` `insane`), packet fragmentation (`-f`), and decoys (`-D RND:5`) to scan target-web without tripping `nmap-detect.sh`'s simple IDS we ship in `targets/`.
3. **Custom Nuclei template.** Identify a path / parameter combination on `target-web` that returns sensitive info. Write a Nuclei template (YAML) that detects it. Run it. Submit-quality.
4. **Tshark forensic prompt.** Capture 60 seconds of the lab. From the pcap **only**, answer: which IPs talked to which, what HTTP paths were requested, which user-agents were involved, were there any DNS queries to suspicious domains?

---

## 📚 Further reading

- [Nmap reference guide](https://nmap.org/book/man.html) — surprisingly readable
- [NSE script index](https://nmap.org/nsedoc/)
- [Nuclei templates](https://github.com/projectdiscovery/nuclei-templates)
- [Wireshark/tshark display filters](https://wiki.wireshark.org/DisplayFilters)
- [iptables tutorial (Frozentux, classic)](https://www.frozentux.net/iptables-tutorial/iptables-tutorial.html)
- [HackTricks Pentesting Network](https://book.hacktricks.wiki/en/generic-methodologies-and-resources/pentesting-methodology.html)
- `research-report.md` §4.3 in this repo

➡️ Next: [Lab 10 — Secure Development](../10-secure-development/)
