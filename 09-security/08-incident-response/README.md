# Lab 08 — Incident Response & Log Analysis

## 🎯 What you'll learn

- Stand up a small **Wazuh** SIEM (manager + indexer + dashboard) in Docker
- Generate suspicious activity from a "compromised" container; watch alerts fire
- Write an **incident timeline** by joining log sources
- Practice the **PICERL** framework (Preparation → Identification → Containment → Eradication → Recovery → Lessons learned)
- Use `jq` / `grep` / Wazuh dashboard to sift through Linux auth logs, web logs, and syscalls
- Write **Sigma**-style detection rules and translate them into Wazuh decoders/rules

## 📋 Prerequisites

- Docker + Docker Compose
- ≥ 4 GB RAM, ≥ 4 GB free disk (Wazuh is heavier than other labs)
- macOS users: increase Docker VM memory in Settings → Resources to ≥ 6 GB
- Linux users: ensure `vm.max_map_count >= 262144`:
  ```bash
  sudo sysctl -w vm.max_map_count=262144
  ```

## 🔧 Setup

This lab uses the **Wazuh single-node Docker deployment** plus a small "victim" container that we'll attack.

```bash
$ cd 08-incident-response
$ ./scripts/setup-wazuh.sh        # generates certs (one-time), starts the stack
$ docker compose ps               # 4 containers: wazuh.manager, wazuh.indexer, wazuh.dashboard, victim
$ open https://localhost:8443     # default creds printed by setup script
```

When done:

```bash
$ docker compose down -v
```

> ⏱ First start takes 2–4 minutes while the indexer initializes.

---

## 📝 Exercises

### Exercise 1 — Confirm the agent on the victim is reporting

The "victim" is a Debian container with the Wazuh agent installed and pointed at the manager.

```bash
$ ./scripts/wazuh-agent-status.sh
# Expected: agent_id=001, status=Active

# In the dashboard: Agents → you should see "victim" green.
```

### Exercise 2 — Trigger basic auth alerts (Sigma `T1110`)

The classic: brute-forcing SSH-like behavior triggers built-in Wazuh rules.

```bash
$ ./scripts/scenario-bruteforce.sh
# generates 20 failed sudo attempts in the victim container
```

In the dashboard: **Security events → Filter `rule.id: 5710` (multiple authentication failures)**. You should see the alert within ~30s.

> 💡 Wazuh ships with thousands of built-in rules. Filter by `rule.groups: authentication_failed` to scope.

### Exercise 3 — Trigger a webshell-like file integrity alert

Wazuh's File Integrity Monitoring (FIM) module watches `/var/www/html` on the victim by default in our config.

```bash
$ ./scripts/scenario-webshell.sh
# creates /var/www/html/shell.php with classic PHP webshell content
```

In the dashboard: **Integrity monitoring → /var/www/html/shell.php — added**.

Read the alert. The fields you care about in IR:

- `agent.name` / `agent.ip` — which host
- `syscheck.path` — what file
- `syscheck.event` — added/modified/deleted
- `syscheck.uid_after` — who did it (when collected)

### Exercise 4 — Container escape simulation

```bash
$ ./scripts/scenario-suid.sh
# chmod's a binary to setuid 0 in the victim — Wazuh's rootcheck flags it
```

> 💡 In real life, `find / -perm -4000` finding new SUID binaries is one of the cheapest signals of post-exploitation persistence.

### Exercise 5 — Build the timeline

You now have three incidents in the dashboard. Pretend it's Monday morning and you got a "spike of alerts overnight" notification.

Use `./scripts/timeline.sh` to produce a TSV of all alerts in the last hour:

```bash
$ ./scripts/timeline.sh > exercises/timeline.tsv
$ column -t -s $'\t' exercises/timeline.tsv | head -30
```

Order by timestamp; you should be able to read the story:

```
T+0s     bruteforce  multiple auth failures              (suspicious)
T+12s    bruteforce  successful login after failures     (alert!)
T+45s    fim         /var/www/html/shell.php created     (very alert!)
T+92s    rootcheck   new SUID binary detected            (RED)
```

This is **exactly** what a real triage looks like. The narrative is the deliverable.

### Exercise 6 — Containment runbook

Open `exercises/INCIDENT-PLAYBOOK.md`. It's a checklist for a confirmed-compromised host. Walk through it on the victim container:

1. Snapshot evidence (logs, memory, fs)
2. Network-isolate (`docker network disconnect`)
3. Capture process tree (`ps -ef`, `lsof`)
4. Rotate any credentials touched by the attacker
5. Begin forensics

### Exercise 7 — Write a custom Wazuh rule

Suppose your app writes a known structured event when JWT validation fails (`jwt_validation_failed user_id=...`). Write a rule that fires when any IP fails 5 times in 60s.

`exercises/custom-rules.xml`:

```xml
<group name="myapp,jwt,">
  <rule id="100100" level="5">
    <decoded_as>json</decoded_as>
    <field name="event">^jwt_validation_failed$</field>
    <description>App: JWT validation failed</description>
  </rule>
  <rule id="100101" level="10" frequency="5" timeframe="60">
    <if_matched_sid>100100</if_matched_sid>
    <same_field>srcip</same_field>
    <description>App: 5 JWT failures in 60s from same IP — possible token brute-force</description>
    <mitre><id>T1110</id></mitre>
  </rule>
</group>
```

Drop it into the manager (`./scripts/install-custom-rules.sh`) and emit some fake events (`./scripts/scenario-jwt.sh`). Watch your custom rule fire.

### Exercise 8 — Sigma rule → Wazuh rule

Sigma is a vendor-neutral detection language. Look at `exercises/sigma/suspicious-curl.yml`. Convert it (manually, or with [`sigma-cli`](https://github.com/SigmaHQ/sigma-cli)) into a Wazuh rule and validate it triggers.

> 💡 Most modern detection engineering teams write Sigma and translate per platform. Saves a lot of duplicate work across SIEMs.

---

## 💡 Key Concepts

### PICERL (the IR loop)

```text
Preparation → Identification → Containment → Eradication → Recovery → Lessons Learned
   ↑                                                                          │
   └──────────────────────────────────────────────────────────────────────────┘
                          (every incident improves preparation)
```

### What "containment" actually means

| Layer        | Action                                                                       |
|--------------|------------------------------------------------------------------------------|
| Network      | Move host to quarantine VLAN / disconnect SG. Don't power off — lose memory. |
| Identity     | Disable user/SP, rotate keys, revoke sessions/tokens.                        |
| Endpoint     | Snapshot disk + memory; isolate from C2; pause workloads.                    |
| Cloud        | Scope IAM blast radius; revoke STS tokens; freeze affected accounts.         |

### MITRE ATT&CK in 30 seconds

ATT&CK is a public taxonomy of *what attackers do* — Tactics (high-level), Techniques (T-IDs), Sub-techniques. Tag every alert and detection with a T-ID. Coverage maps tell you where you're blind.

### Why a SIEM matters

Logs are useless individually. The value is in **joins**:

```text
auth.log says "user X logged in from IP Y"
+
nginx.log says "IP Y just made 10k requests"
+
EDR says "process Z spawned a shell on host of user X"
=  story
```

A SIEM (Wazuh / Splunk / Elastic / Sentinel) is "make joins fast."

---

## 🏆 Challenge

1. **End-to-end attack chain.** Use a Docker-based [DVWA](https://github.com/digininja/DVWA) or [Juice Shop](../05-web-app-security-owasp/) as the victim. Forward its logs to Wazuh. Replicate an XSS → cookie steal → privilege escalation chain and write the IR report.
2. **Custom decoder.** Your app emits logs in a custom format. Write a Wazuh **decoder** (regex-based parser) and rules. Validate with `wazuh-logtest`.
3. **Detection coverage map.** Take 10 ATT&CK techniques relevant to your stack. Write Sigma rules for each, convert to Wazuh, document residual gaps.
4. **Tabletop exercise.** With a friend, role-play this scenario: a developer's laptop is found beaconing to a known C2 IP. Walk PICERL out loud. Time it. Write the post-mortem.

---

## 📚 Further reading

- [Wazuh docs](https://documentation.wazuh.com/)
- [Sigma project](https://github.com/SigmaHQ/sigma)
- [MITRE ATT&CK](https://attack.mitre.org/)
- [SANS PICERL handbook](https://www.sans.org/white-papers/incident-handlers-handbook-33901/)
- [Atomic Red Team](https://github.com/redcanaryco/atomic-red-team) — small attack scripts to test detections
- [GoatLog](https://github.com/openappsec/goatlog) for synthetic log generation
- `research-report.md` (note: dedicated SIEM coverage is in §4 categories)

➡️ Next: [Lab 09 — Network Security](../09-network-security/)
