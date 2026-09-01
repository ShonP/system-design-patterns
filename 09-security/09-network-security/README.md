# Lab 09 — Network Security: Nmap, Nuclei & Packet Analysis

## 🎯 What you'll learn

- Use **Nmap** for host discovery, port scanning, version detection, and NSE scripts
- Use **Nuclei** to fingerprint and confirm CVEs over the network
- Capture and analyze packets with `tshark` (Wireshark CLI)
- Read **firewall rules** and design a minimal allowlist
- Understand the difference between active scanning (with permission!) vs passive reconnaissance

> ## ⚠️ Read this before you run anything
>
> **Scanning a system you do not own and do not have written permission to test is a crime
> in most jurisdictions** — Computer Fraud and Abuse Act (US), Computer Misuse Act 1990 (UK),
> §202a–c StGB (Germany), and equivalents almost everywhere else. "I was only looking",
> "it was just a port scan" and "the port was open" are not defences. People have been
> prosecuted for less than what exercise 2 does.
>
> Everything in this lab targets `192.168.198.0/24`, a private Docker network created by
> this lab's `docker-compose.yml` and reachable only from the `attacker` container. Every
> command runs *inside* that container via `./scripts/in-attacker.sh`, which is what keeps
> the traffic scoped. Before you run a scan, check what you are pointed at:
>
> ```bash
> $ ./scripts/in-attacker.sh "ip route"           # only the lab subnet should be reachable
> $ docker compose ps                             # these three hosts are the entire scope
> ```
>
> If you want to practise against something bigger, the legal options are:
> [Hack The Box](https://www.hackthebox.com/), [TryHackMe](https://tryhackme.com/),
> `scanme.nmap.org` (Nmap's own permission-granted host, light scans only), or a VPS you
> pay for. Never your employer's network without a signed scope document.

## 📋 Prerequisites

- Docker
- Lab 05 helpful for Nuclei context

## 🔧 Setup

This lab brings up three intentionally-imperfect targets on a private Docker network:

```text
seclabs09-net   (192.168.198.0/24)
├── target-web   (vulnerable Nginx + sample app)
├── target-ssh   (current OpenSSH on a non-default port — 2222, not 22)
└── attacker     (Kali-style toolbox: nmap + nuclei + tshark + nikto)
```

```bash
$ cd 09-network-security
$ docker compose up -d --build
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

> ✅ Expected: **4 hosts** — `192.168.198.1` (the Docker bridge gateway, i.e. your host),
> `.5` (attacker, itself), `.10` (target-web) and `.20` (target-ssh). The gateway is the one
> people forget: a container network always has a route back to the host, and on a real
> engagement that is exactly the pivot you would be looking for.

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
$ ./scripts/in-attacker.sh "nmap --script=http-headers,http-security-headers -p 80 target-web"
$ ./scripts/in-attacker.sh "nmap --script=ssh2-enum-algos,ssh-hostkey -p 2222 target-ssh"
$ ./scripts/in-attacker.sh "nmap --script=ssl-enum-ciphers -p 443 target-web"   # see note
$ ./scripts/in-attacker.sh "nmap --script vuln -sV -p 80 target-web"
```

> ⚠️ `http-security-headers` does **not** print a report here. On nmap 7.93 (the version
> Debian 12 ships, and the one in this image) it aborts with:
>
> ```text
> Bug in http-security-headers: no string output.
> ```
>
> That is an upstream NSE bug, not something you did wrong — the script builds an empty
> result table when the target sets *none* of the headers it looks for, and NSE cannot
> stringify it. `target-web` sets none of them, so it trips every time. Read the headers
> out of `http-headers` instead and note what is *absent* — no `Content-Security-Policy`,
> no `Strict-Transport-Security`, no `X-Frame-Options`, no `X-Content-Type-Options`.
> Exercise 4 confirms the same gaps with nuclei, which reports them properly.
>
> ℹ️ The `ssl-enum-ciphers` run prints **nothing useful** — port 443 is closed on
> `target-web`, which serves plain HTTP only. That is deliberate: NSE scripts run against
> ports that are open and match the script's `portrule`, so pointing a TLS script at a
> non-TLS port is a no-op, not an error. Always scope scripts to what `-sV` actually found.

> ⏱️ The `--script vuln` run is the slow one — it fires ~105 scripts. Measured **77 s**
> against `target-web` on 2026-08-21 with nmap 7.93. Two things in its output are worth
> stopping on:
>
> - `http-vuln-cve2011-3192` reports **VULNERABLE: Apache byterange filter DoS**. `target-web`
>   is nginx. It is not Apache. This is a **false positive** — the script's check is loose
>   enough to fire on a server that merely honours `Range` headers. Do not paste it into a
>   report; this is what "confirm before you claim" means in practice.
> - `vulners` output appears in this run too, even though you did not ask for it. That is
>   because the Dockerfile drops `vulners.nse` into nmap's script directory, and the script
>   declares itself part of the `vuln` category — so `--script vuln` picks it up. A
>   third-party script installed into the scripts dir joins the categories it claims.
>
> 💡 `--script vuln` is nmap's **built-in** vulnerability category. The one every blog post
> shows — `--script vulners` — is a **third-party** script that is not bundled with nmap;
> `targets/attacker/Dockerfile` downloads it at build time. It also queries `vulners.com`
> over the internet at scan time, so it returns nothing on an air-gapped box:
>
> ```bash
> $ ./scripts/in-attacker.sh "nmap --script=vulners -sV -p 80 target-web"   # needs internet
> ```
>
> And note what it actually does: it maps a **banner** to a CVE list. `nginx/1.18.0` gets you
> every CVE ever filed against 1.18.0 — including ones your distro backported a fix for, and
> ones in modules that are not compiled in. It is a lead generator, not a finding. Confirming
> takes a targeted check (a nuclei template, a manual repro) — see exercise 4.

### Exercise 4 — Nuclei (templated CVE checks)

```bash
# First run downloads the template repo from GitHub into the container (needs internet):
$ ./scripts/in-attacker.sh "nuclei -update-templates"
$ ./scripts/in-attacker.sh "nuclei -u http://target-web -severity medium,high,critical -ni"
$ ./scripts/in-attacker.sh "nuclei -u http://target-web -t http/exposures -ni"
$ ./scripts/in-attacker.sh "nuclei -u http://target-web -type http -ni -silent"
```

> ✅ Expected — and this is the point of the exercise: the first two commands find
> **nothing at all**. Zero. `-severity medium,high,critical` returns 0 findings and
> `-t http/exposures` returns 0 findings. Only the last command, which drops the severity
> filter, prints anything: **14 findings, every one of them `info`** (measured 2026-08-21,
> nuclei 3.3.4, templates v10.4.7).
>
> A static nginx page serving two HTML files has no injectable parameter, no login, no
> admin framework, nothing for a `critical` template to match. That is the honest result,
> and the lesson is worth more than a padded finding count: **an empty nuclei run is not
> proof the host is safe.** It is proof that none of ~6,400 known-signature checks matched.
> The leaked `/admin/secret.html` on this very host is a real finding, and nuclei misses it
> completely — no template knows that path. Finding it needs directory brute-forcing with a
> wordlist (`ffuf`, `feroxbuster`, `gobuster`), which is a different tool class.
>
> The 14 `info` findings are still the useful part: `nginx-version` and `nginx-eol` pin the
> exact build, and ten `http-missing-security-headers` hits enumerate the headers nginx is
> not sending. Exercise 9 uses those counts as its before/after baseline.

> ℹ️ Two flags worth knowing:
> - `-ni` disables **interactsh**. By default nuclei registers with the public OAST server
>   `oast.me` so out-of-band templates can catch callbacks. In a sealed local lab that is
>   the one thing reaching the internet during a scan — turn it off and the run stays inside
>   `192.168.198.0/24`.
> - `-type http` skips the DNS templates, which otherwise fingerprint the resolver's root
>   nameservers and add a finding that has nothing to do with your target.

> ℹ️ nuclei is not a Debian package — the attacker image installs the upstream release
> binary. If you rebuild the image offline, this exercise is the one that breaks.

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

Those two filters give you *who talked to whom*. Now read the **body**:

```bash
$ ./scripts/in-attacker.sh "tshark -r /workspace/exercises/capture.pcap -Y 'http.request.method == \"POST\"' -T fields -e urlencoded-form.key -e urlencoded-form.value"
```

> ✅ Expected: `user,pass` and `admin,hunter2` — the credentials you posted, recovered from
> the capture with no decryption and no cracking, because there was never anything to
> decrypt. `-e http.file_data` on the same filter gives you the raw body
> (`user=admin&pass=hunter2`) if you would rather see it unparsed.
>
> 💡 **Anything not over TLS is on the wire in plaintext** — including that password. Don't
> take that on faith; you just extracted it. This is why every exercise in lab 10 enforces
> HTTPS.

> ℹ️ Capturing packets needs more than root — it needs the kernel to hand you a raw socket.
> That is why `attacker` is declared with `cap_add: ["NET_ADMIN", "NET_RAW"]` in
> `docker-compose.yml`. Drop those capabilities and `tshark -i eth0` fails with
> "You don't have permission to capture on that device", even as root. `tshark` also warns
> `Running as user "root" and group "root". This could be dangerous.` on every invocation
> here — that is expected inside a throwaway container, not a problem to fix.

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

> ⚠️ **This is a reading-and-writing exercise. Do not paste these rules into your own shell.**
>
> `iptables` is a Linux kernel interface. On **macOS or Windows it does not exist** — the
> commands fail with `command not found` and nothing happens. On a **Linux host they very
> much do exist**, and pasting the answer key would rewrite your machine's live firewall,
> starting with `iptables -P INPUT DROP`. If you are on a remote box, that is the command
> that locks you out of your own SSH session.
>
> If you want to actually run them, run them in the throwaway container, which has
> `iptables` installed and `NET_ADMIN` granted, and whose network namespace is its own:
>
> ```bash
> $ ./scripts/in-attacker.sh "iptables -L INPUT -n -v"          # empty, policy ACCEPT
> $ ./scripts/in-attacker.sh "iptables -A INPUT -p tcp --dport 80 -j ACCEPT; iptables -L INPUT -n"
> ```
>
> Anything you do there dies with the container. Note that Docker Desktop on macOS runs
> containers inside a Linux VM — so the container has a real Linux kernel to talk to even
> though your laptop does not.

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
$ ./scripts/in-attacker.sh "xsltproc -o /workspace/exercises/web-scan.html /usr/share/nmap/nmap.xsl /workspace/exercises/web-scan.xml"
```

> ⚠️ **Put `-o` before the positional arguments.** The obvious-looking
> `xsltproc <stylesheet> <input> -o <output>` writes the right file but exits **6** and
> spews parse errors, because `-o` and the filename after it get picked up a second time as
> input documents:
>
> ```text
> warning: failed to load external entity "-o"
> unable to parse -o
> unable to parse /workspace/exercises/web-scan.html
> ```
>
> In a script with `set -e`, or anywhere you check the exit code, that is a build failure
> on a command that appeared to work.
>
> 💡 Nmap embeds `<?xml-stylesheet href="file:///usr/share/nmap/nmap.xsl" type="text/xsl"?>`
> at the top of its XML, and **xsltproc does follow it** (libxslt implements
> `xsltLoadStylesheetPI`). So this shorter form works too, and produces a byte-identical
> file — verified with `md5sum` on 2026-08-21, libxslt 1.1.35:
>
> ```bash
> $ ./scripts/in-attacker.sh "xsltproc -o /workspace/exercises/web-scan.html /workspace/exercises/web-scan.xml"
> ```
>
> It only works because *nmap* puts that PI there and the stylesheet is on the local disk at
> the path the PI names. Name the stylesheet explicitly when you care about reproducibility.

Now you have the same scan in 4 formats. **`.xml`** is the one that pipes into other tools (Metasploit, Faraday, custom scripts). **`.gnmap`** (greppable) is great for quick `awk` work.

### Exercise 9 — Close the loop: remediate and rescan

You have findings. Fix them and prove it, which is the half of the job that scanning skips.

Baseline the vulnerable target:

```bash
$ ./scripts/in-attacker.sh "nmap -sV -p80 target-web | grep -i nginx"
$ ./scripts/in-attacker.sh "curl -s -o /dev/null -w '%{http_code}\n' http://target-web/admin/secret.html"
$ ./scripts/in-attacker.sh "nuclei -u http://target-web -type http -ni -silent -nc | tee /workspace/exercises/nuclei-before.txt | wc -l"
```

> ✅ Expected: `nginx 1.18.0`, `200` for the leaked admin page, and **14** nuclei findings
> (measured 2026-08-21, nuclei 3.3.4 / templates v10.4.7). Note the nuclei command here is
> **not** severity-filtered — as exercise 4 showed, `-severity medium,high,critical` returns
> **0** against this static site, which makes a useless baseline (0 → 0 proves nothing). The
> findings that *do* exist are all `info`, and two of them are exactly the ones the fix
> removes. That is what makes them a meaningful before/after.

Bring up the remediated target (patched nginx, `server_tokens off`, `/admin` not served)
and run **the same three commands** against it:

```bash
$ docker compose --profile fixed up -d target-web-fixed
$ ./scripts/in-attacker.sh "nmap -sV -p80 target-web-fixed | grep -i nginx"
$ ./scripts/in-attacker.sh "curl -s -o /dev/null -w '%{http_code}\n' http://target-web-fixed/admin/secret.html"
$ ./scripts/in-attacker.sh "nuclei -u http://target-web-fixed -type http -ni -silent -nc | tee /workspace/exercises/nuclei-after.txt | wc -l"
$ diff <(sed 's/ .*//' exercises/nuclei-before.txt | sort) <(sed 's/ .*//' exercises/nuclei-after.txt | sort)
```

> ✅ Expected: nmap reports `nginx` with **no version** (`server_tokens off` removed the
> banner), the admin page is `404`, and the nuclei count drops from **14 to 12**. The `diff`
> shows *exactly which two disappeared*:
>
> ```text
> < [nginx-eol:version]
> < [nginx-version]
> ```
>
> Both are banner findings. The ten `http-missing-security-headers` hits are **unchanged** —
> this remediation upgraded nginx and hid its version, but never added a single security
> header, so nuclei still flags every one of them on both targets. A count that drops by
> two, with the two named, is a far more honest result than "the list is shorter."

Now the important caveat, because two of those three "fixes" are not equal:

| Change | What it actually did |
|---|---|
| Upgraded nginx 1.18 → 1.27 | **Removed the vulnerability.** Real fix. |
| `server_tokens off` | **Hid the version from the banner.** The vulnerability, if any, is untouched — you defeated the *scanner*, not the attacker. Worth doing (it raises the cost of mass scanning), worth nothing on its own. |
| `/admin` returns 404 | Removed *this* path. If the file is still on disk and reachable by another route, nothing changed. |

Version-banner suppression is the most common way an organisation makes its scan report
look better without becoming safer. When you rescan and the number drops, always ask which
of the three columns above you are in.

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
- [Legal note: Nmap's own guidance on scanning permission](https://nmap.org/book/legal-issues.html)

➡️ Next: [Lab 10 — Secure Development](../10-secure-development/)
