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
- **≥ 6 GB free to Docker, ≥ 12 GB free disk.** Measured steady-state on an idle stack:
  indexer 1.6 GB, manager 0.6 GB, dashboard 0.3 GB, victim 0.03 GB ≈ **2.5 GB RSS**, but
  the indexer's JVM will grab its full `-Xmx1g` under load and the images alone are
  8 GB on disk (2.9 GB to download). 4 GB is not enough.
- `jq` on the host (`brew install jq`) — most exercises pipe alerts through it.
- **Apple Silicon:** all three Wazuh 4.9.0 images are `linux/amd64` only, so they run
  under emulation. It works — every exercise below was verified this way — but expect
  `docker compose exec` into the manager to take a second or two, and expect FIM scans
  to take 1–2 minutes rather than seconds. You will see this warning on every `up`, and
  it is expected:
  `The requested image's platform (linux/amd64) does not match the detected host platform`
- `vm.max_map_count >= 262144` for the indexer:
  - **Linux:** `sudo sysctl -w vm.max_map_count=262144`
  - **Docker Desktop (macOS/Windows):** nothing to do. The setting lives in Docker's own
    Linux VM, not on your host — `sysctl` on macOS has no such key — and the VM already
    ships with 262144. Verify with:
    ```bash
    docker run --rm --privileged --pid=host alpine \
      nsenter -t 1 -m -u -n -i sysctl vm.max_map_count
    ```

## 🔧 Setup

This lab uses the **Wazuh single-node Docker deployment** plus a small "victim" container that we'll attack.

It publishes five host ports: **1514** and **1515** (agent traffic and enrollment),
**55000** (manager API), **9200** (indexer) and **8443** (dashboard). Check they are free
before you start — `lsof -nP -iTCP:9200 -sTCP:LISTEN` and friends.

```bash
$ cd 08-incident-response
$ ./scripts/setup-wazuh.sh        # generates certs (one-time), starts the stack, waits for health
$ docker compose ps               # 4 containers: wazuh.manager, wazuh.indexer, wazuh.dashboard, victim
$ open https://localhost:8443     # self-signed cert; admin / SecretPassword
```

`setup-wazuh.sh` ends by running `./scripts/wait-for-stack.sh`, which blocks until all
four components are genuinely usable and prints when each one arrives:

```text
t+22s  manager: analysisd + remoted running
t+32s  indexer:   cluster green
t+32s  dashboard: https://localhost:8443
t+43s  agent:     victim Active
```

> ⏱ **Measured, not estimated** — 2026-08-24, Docker Desktop 8 GB / 10 CPU, Apple Silicon
> (so amd64 emulation), Wazuh 4.9.0:
> - **~50 s** from `setup-wazuh.sh` to all four healthy, images already present.
> - **First ever run adds** the image pull (2.9 GB compressed / 8 GB on disk) plus the
>   victim image build (measured **19 s** with `--no-cache`). Almost all of the first-run
>   wall clock is the pull, so it is your connection, not this lab: budget 10–20 minutes.
>
> Run `./scripts/wait-for-stack.sh` on its own any time to re-check health.

> ⚠️ **The dashboard is optional.** Every exercise below can be done from the manager's
> CLI against `/var/ossec/logs/alerts/alerts.json`, and each one lists that command. If
> the dashboard misbehaves on your machine, do not spend an hour on it — the detection
> engineering is the lesson, the OpenSearch operations are not.

> 🔑 **Credentials are `admin` / `SecretPassword`,** and they only work because
> `config/wazuh_indexer/internal_users.yml` is mounted over the image's own copy. The
> stock `wazuh-indexer` image ships the OpenSearch *demo* user database, where `admin`'s
> password is `admin`. These are published Wazuh demo hashes — this stack belongs on
> localhost and nowhere else.

> 🧩 **Why this compose mounts config files.** The three Wazuh images are not usable
> as-shipped. `wazuh-indexer`'s baked-in `opensearch.yml` points at
> `/etc/wazuh-indexer/certs/indexer.pem`, a path that does not exist in the image, and
> declares `nodes_dn: CN=node-1` while the certificate generator issues
> `CN=wazuh.indexer` — the security plugin fails to load and the container crash-loops
> forever. `wazuh-dashboard`'s baked-in config listens on **:443**, not :5601, and points
> at `https://localhost:9200`. So `config/wazuh_indexer/` and `config/wazuh_dashboard/`
> are mounted over both, mirroring upstream
> [`wazuh-docker` v4.9.0 `single-node/`](https://github.com/wazuh/wazuh-docker/tree/v4.9.0/single-node).
> Each file's header says exactly what it fixes. This is worth reading once: "the image
> runs but its default config refers to files it does not contain" is a very common shape
> of broken, and the symptom (a crash-loop with a Java `AccessControlException`) looks
> nothing like the cause.

When done:

```bash
$ docker compose down -v
$ docker images -q 'victim-evidence:*' | xargs -r docker rmi   # if you did exercise 6
```

---

## 📝 Exercises

### Exercise 1 — Confirm the agent on the victim is reporting

The "victim" is a Debian container with the Wazuh agent installed and pointed at the manager.

```bash
$ ./scripts/wazuh-agent-status.sh
```
```text
Wazuh agent_control. List of available agents:
   ID: 000, Name: wazuh.manager (server), IP: 127.0.0.1, Active/Local
   ID: 001, Name: victim, IP: any, Active
```

In the dashboard (optional): Agents → "victim" should be green.

> ⚠️ **Do not hardcode `001`.** The manager hands out the next free ID at enrollment, and
> the victim re-enrolls from scratch every time its *container* is recreated, because
> `client.keys` lives in the container filesystem and not in a volume. After one rebuild
> the victim is `002`, then `003`. Use `./scripts/victim-agent-id.sh` — the scenario
> scripts do. Commands like `agent_control -r -u 001` do not error on a wrong ID; they
> print the usage text and do nothing, which is much easier to miss.

If it says `Never connected`, work down this list.

**`Duplicate agent name: victim` in `docker compose logs victim`.** This is the one you
will actually hit, and it is a consequence of the previous paragraph: you rebuilt or
recreated the victim container, its `client.keys` went with it, and the manager still has
the old `victim` registered. authd refuses the new enrollment
(`Agent '001' doesn't comply with the registration time to be removed`) and the agent
retries forever. Delete the stale registration and restart:

```bash
$ docker compose exec -T wazuh.manager /var/ossec/bin/manage_agents -r 001   # old ID
$ docker compose restart victim
```

Prefer `docker compose restart victim` over `up -d --build victim` while working through
the lab; a restart keeps `client.keys` and the agent stays put.

**Everything looks dead and there are no alerts at all.** Check the manager is whole:

```bash
$ docker compose exec -T wazuh.manager /var/ossec/bin/wazuh-control status
```

If `wazuh-analysisd` and `wazuh-remoted` are *not running* while `authd` and `wazuh-db`
are, the manager lost a startup race and never built its `/var/ossec/logs` skeleton.
`./scripts/wait-for-stack.sh` detects this and repairs it automatically — it is why that
script exists. See its header comment for the mechanism.

**Otherwise:**

```bash
$ docker compose logs victim | tail -30                 # agent-side errors
$ docker compose exec -T victim /var/ossec/bin/wazuh-control status
$ docker compose logs wazuh.manager | grep -i authd     # enrollment listener on :1515
```

### Exercise 2 — Trigger auth alerts (MITRE `T1110`)

The classic: repeated failed authentications, then one that works.

```bash
$ ./scripts/scenario-bruteforce.sh
# 20 failed `sudo` attempts as alice, then one with the correct password
```

Check from the CLI (works with or without the dashboard):

```bash
$ docker compose exec -T wazuh.manager \
    sh -c "grep -E '\"id\":\"(5401|5503)\"' /var/ossec/logs/alerts/alerts.json | tail -5" | jq -r '.rule.id + " " + .rule.description'
```

Give it ~30 s, then count what actually fired:

```bash
$ docker compose exec -T wazuh.manager sh -c 'cat /var/ossec/logs/alerts/alerts.json' \
  | jq -r 'select((.rule.groups|index("authentication_failed")) or (.rule.groups|index("sudo")))
           | "\(.rule.id)|\(.rule.level)|\(.rule.description)"' | sort | uniq -c
```
```text
  20 5401|5|Failed attempt to run sudo.
   2 5403|4|First time user executed sudo.
   1 5501|3|PAM: Login session opened.
  20 5503|5|PAM: User login failed.
```
*(measured 2026-08-24, Wazuh 4.9.0. The `5403`/`5501` pair is the success at the end.)*

In the dashboard: **Security events → filter `rule.id: 5503`**.

> 🪤 **5710 and 5712 are SSHD rules and will never fire here.** There is no sshd on the
> victim; the failures come from `sudo`, which is PAM plus the syslog `sudo` decoder. It
> is worth internalising how ordinary this mistake is: the technique is right (T1110), the
> tactic is right, and the rule IDs are still for a service you are not running. Detection
> coverage is per-*log-source*, not per-*technique*.

> 🪤 **Two things have to be true before any of this works,** and both are configured in
> `scenarios/Dockerfile.victim` because neither is true by default in a container:
> 1. Something must **write** `/var/log/auth.log`. A container has no syslogd, so the
>    image installs `rsyslog` and the entrypoint starts it.
> 2. Something must **read** it. The stock Debian Wazuh agent monitors `apache2`,
>    `dpkg.log` and `active-responses.log` — **not** `auth.log`. The image appends a
>    `<localfile>` for it.
>
> Miss (2) and the failure is silent and very convincing: `/var/log/auth.log` fills up
> with exactly the events you expect, and the SIEM shows nothing. "The log exists" and
> "the log is collected" are separate claims; check both.

> 💡 **Notice what did *not* fire.** Wazuh's `5551` "Multiple failed logins in a small
> period of time" (level 10, 8 hits in 180 s) is exactly the correlation you would want
> here, and 20 failures in ~45 s clears its threshold easily. It stays silent because it
> is gated on `<same_source_ip />` and a local `sudo` event carries no source IP. Nothing
> is broken — the stock ruleset just has no correlation rule for this shape. You write one
> yourself in exercise 7.

> 💡 Wazuh ships with thousands of built-in rules. Filter by `rule.groups: authentication_failed` to scope.

### Exercise 3 — Trigger a webshell-like file integrity alert

Wazuh's File Integrity Monitoring (FIM) module watches `/var/www/html` on the victim by default in our config.

```bash
$ ./scripts/scenario-webshell.sh
# creates /var/www/html/shell.php with classic PHP webshell content
```

```bash
$ docker compose exec -T wazuh.manager \
    sh -c "grep shell.php /var/ossec/logs/alerts/alerts.json | tail -1" \
  | jq '{id: .rule.id, level: .rule.level, rule: .rule.description, path: .syscheck.path, event: .syscheck.event, mode: .syscheck.mode}'
```
```json
{
  "id": "554",
  "level": 5,
  "rule": "File added to the system.",
  "path": "/var/www/html/shell.php",
  "event": "added",
  "mode": "realtime"
}
```
*(measured 2026-08-24; arrives within ~20 s because this path is watched in realtime.)*

In the dashboard: **Integrity monitoring → /var/www/html/shell.php — added**.

> 💡 Level **5** for a webshell appearing in a web root. That is the stock rule doing its
> job — 554 is "a file was added", and it cannot know this one matters. Turning generic
> FIM events into ranked detections is the work; exercise 7 is where you start.

> ℹ️ Stock Wazuh FIM watches `/etc`, `/usr/bin`, `/usr/sbin`, `/bin`, `/sbin` and `/boot` —
> **not** `/var/www`. The victim image adds
> `<directories check_all="yes" realtime="yes">/var/www/html</directories>` to the agent's
> `ossec.conf`; without that line this exercise silently produces nothing. Coverage is a
> configuration decision, and the default coverage does not include the place your webshell
> is going to land.

Read the alert. The fields you care about in IR:

- `agent.name` / `agent.ip` — which host
- `syscheck.path` — what file
- `syscheck.event` — added/modified/deleted
- `syscheck.uid_after` — who did it (when collected)

### Exercise 4 — Spot a new SUID-root binary

```bash
$ ./scripts/scenario-suid.sh
# copies /bin/bash to /usr/bin/.s and chmods it 4755, then forces a FIM scan
```

> 💡 In real life, `find / -perm -4000` turning up a *new* SUID binary is one of the
> cheapest signals of post-exploitation persistence.

`/usr/bin` is on FIM's **scheduled** scan, not realtime, so this takes 1–2 minutes under
emulation. Then find it by the thing that makes it interesting — the setuid bit in
`syscheck.perm_after`:

```bash
$ docker compose exec -T wazuh.manager sh -c 'cat /var/ossec/logs/alerts/alerts.json' \
  | jq -r 'select(.syscheck.event=="added" and ((.syscheck.perm_after // "")|startswith("rws")))
           | "\(.rule.id)\t\(.rule.level)\t\(.syscheck.path)\t\(.syscheck.perm_after)"'
```
```text
554	5	/usr/bin/.s	rwsr-xr-x
```
*(measured 2026-08-24.)*

> 🪤 **Wazuh's rootcheck does not detect SUID binaries, and `/tmp` is not watched.** Both
> halves matter, and an earlier version of this exercise got both wrong:
>
> - **rootcheck is not a SUID scanner.** Its `check_files` / `check_trojans` /
>   `check_sys` / `check_pids` / `check_ports` hunt rootkits, trojaned binaries, hidden
>   processes and hidden ports. Planting a SUID file produces *zero* rootcheck findings.
>   What it does produce on a stock Debian container is a steady 12 × rule `510`
>   "Host-based anomaly detection event (rootcheck) — Trojaned version of file detected",
>   all of them false positives. That is a useful thing to see: a noisy module that never
>   fires on the actual attack is worse than no module.
> - **`agent_control -i <id>` does not show findings either.** It prints agent metadata
>   (version, OS, last keepalive, last syscheck run) and nothing else.
> - What *does* catch this is **FIM**, and only because `/usr/bin` is in FIM's default
>   coverage (`/etc`, `/usr/bin`, `/usr/sbin`, `/bin`, `/sbin`, `/boot`). Drop the same
>   file in `/tmp` and nothing happens at all — same attack, no detection, purely because
>   of where it landed.
>
> The alert you get is the same generic level-5 `554` as the webshell. Wazuh has no
> built-in "new SUID binary" rule; the setuid bit is sitting right there in
> `syscheck.perm_after` and nothing is looking at it. (`perm_after` is not addressable
> from a rule's `<field>` either — it is a syscheck alert field, not a decoder field — so
> the practical hunt for this is the `jq` above, or a query in the dashboard.)

### Exercise 5 — Build the timeline

You now have three incidents in the dashboard. Pretend it's Monday morning and you got a "spike of alerts overnight" notification.

`./scripts/timeline.sh` dumps the manager's **last 500 alerts** (not "the last hour" —
filter by timestamp yourself if you want a window) as TSV: time, agent, rule id, level,
description, and the one detail that identifies the event.

```bash
$ ./scripts/timeline.sh > exercises/timeline.tsv
$ column -t -s $'\t' exercises/timeline.tsv | tail -30
```

Rootcheck's false positives (`510`) and the SCA benchmark results (`19xxx`) will drown
everything else — which is itself the lesson. Filter them out and the story is right there:

```bash
$ awk -F'\t' '$3!="510" && $3!~/^19/' exercises/timeline.tsv | column -t -s $'\t' | tail -20
```
```text
2026-08-24T11:12:53.431+0000  victim  5401    5   Failed attempt to run sudo.
2026-08-24T11:12:53.435+0000  victim  5503    5   PAM: User login failed.
  ... 18 more pairs ...
2026-08-24T11:13:01.444+0000  victim  5403    4   First time user executed sudo.
2026-08-24T11:13:01.452+0000  victim  5501    3   PAM: Login session opened.        root(uid=0)
2026-08-24T11:13:51.504+0000  victim  554     5   File added to the system.         /var/www/html/shell.php
2026-08-24T11:14:18.122+0000  victim  554     5   File added to the system.         /usr/bin/.s
2026-08-24T11:17:27.915+0000  victim  100101  10  App: 5 JWT failures in 60s ...    10.1.2.3
```
*(measured 2026-08-24; the `100101` line appears once you have done exercise 7.)*

Read it out loud: twenty failed sudo attempts, then one that worked, then a PHP file in
the web root, then a setuid-root binary in `/usr/bin`. That is the report.

Note the levels. The failures are 5, the **successful** sudo is a **4**, and the two most
damning events are 5s. Sorting this list by severity destroys the finding; sorting it by
time reveals it.

This is **exactly** what a real triage looks like. The narrative is the deliverable — and
notice that no single line in it is conclusive. Failed sudo happens all day; a new file in
a web root happens on every deploy; a SUID binary can be a package update. The *sequence*
is the finding. This is why "how many alerts fired" is as useless a metric as "how many
CVEs" — one correlated story beats a thousand individually-plausible events.

### Exercise 6 — Containment runbook

Open `exercises/INCIDENT-PLAYBOOK.md`. It's a checklist for a confirmed-compromised host.
Actually run it against the victim container — the order below is the point of the exercise:

```bash
$ mkdir -p exercises/evidence

# 1. CONTAIN at the network layer. Do NOT stop or delete the container: `docker stop`
#    is the container equivalent of pulling the power cable, and it destroys process
#    state, open sockets and anything only in memory.
$ NET=$(docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{end}}' \
        "$(docker compose ps -q victim)")
$ docker network disconnect "$NET" "$(docker compose ps -q victim)"
$ docker compose exec -T victim sh -c "ping -c1 -W1 1.1.1.1 || echo ISOLATED"

# 2. PRESERVE evidence before you change anything else.
$ docker compose exec -T victim ps -efww           > exercises/evidence/ps.txt
$ docker compose exec -T victim sh -c 'ls -laR /tmp /var/www/html' > exercises/evidence/files.txt
$ docker compose exec -T victim sh -c 'cat /var/log/auth.log'      > exercises/evidence/auth.log
$ docker diff "$(docker compose ps -q victim)"     > exercises/evidence/docker-diff.txt
$ docker commit "$(docker compose ps -q victim)" victim-evidence:$(date +%s)   # disk image
$ ./scripts/timeline.sh                            > exercises/evidence/timeline.tsv

# 3. Only NOW eradicate.
$ docker compose exec -T victim rm -f /usr/bin/.s /var/www/html/shell.php

# 4. RECOVER. Put it back on the network and confirm it is reporting again — an isolated
#    host that nobody remembered to un-isolate is its own outage, and a "recovered" host
#    that stopped sending telemetry is worse than one that never had any.
$ docker network connect "$NET" "$(docker compose ps -q victim)"
$ docker compose restart victim          # restart, NOT recreate -- keeps client.keys
$ ./scripts/wait-for-stack.sh            # expect: agent: victim Active
```

Check step 2 actually captured the attack before you deleted it:

```bash
$ grep -E 'shell\.php|/usr/bin/\.s$' exercises/evidence/docker-diff.txt
A /usr/bin/.s
A /var/www/html/shell.php
```

Then close the loop — **lessons learned** is a step, not a mood. Write three or four lines
in `exercises/evidence/postmortem.md` answering only these:

- How did they get in? (Here: a sudoer with a guessable password and no lockout.)
- What would have caught it sooner? (A correlation rule on failure-then-success — which
  the stock ruleset does not have for `sudo`, as exercise 2 showed.)
- What change makes this class of thing loud next time? (You wrote one in exercise 7.)
- What did we *not* have that we wished we had? (Here: no process telemetry at all —
  which is exactly why exercise 8's Sigma rule has nothing to run against.)

> `docker diff` is the container-native version of "what changed on this host": it lists
> every file added, changed or deleted relative to the image. On a container, that *is* your
> filesystem timeline, and it takes one second. There is no equivalent shortcut on a VM.

**Containment vs eradication vs recovery** — three different steps that people run together
and regret:

| Step | Goal | Typical mistake |
|---|---|---|
| **Containment** | Stop the bleeding *without destroying evidence*. Isolate the network, revoke credentials and sessions, freeze autoscaling and deploys. The attacker stays contained, not tipped off. | Powering the box off (loses memory), or `rm`-ing the tools (loses the timeline) |
| **Eradication** | Remove the attacker's access **and the way in**. Rebuild from a known-good image; close the vulnerability; kill persistence at the identity/cluster layer too, not just on the host. | "Cleaning" a compromised host and putting it back |
| **Recovery** | Return to service with monitoring turned up, and a defined watch period. | Restoring from a backup taken *after* the initial compromise |

Evidence preservation comes **before** eradication, always. The one exception is an active,
ongoing loss (data exfiltrating right now) — and even then you isolate rather than destroy.
Once you have deleted the webshell you can no longer answer "when was it dropped, by whom,
and what did it run" — which is the question that decides whether this is one host or the
whole estate.

### Exercise 7 — Write a custom Wazuh rule

Exercise 2 ended with a gap: 20 failed authentications produced 20 individual level-5
alerts and no correlation, because the only stock rule for that shape needs a source IP
that `sudo` does not have. Close that gap for your own application.

Suppose your app writes a structured event when JWT validation fails. Write a rule that
fires when one IP fails 5 times in 60 s.

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
    <same_source_ip />
    <description>App: 5 JWT failures in 60s from same IP — possible token brute-force</description>
    <mitre><id>T1110</id></mitre>
  </rule>
</group>
```

```bash
$ ./scripts/install-custom-rules.sh    # copies it in, fixes ownership, restarts, self-tests
$ ./scripts/scenario-jwt.sh            # emits 6 events from 10.1.2.3
$ sleep 30
$ docker compose exec -T wazuh.manager sh -c 'cat /var/ossec/logs/alerts/alerts.json' \
  | jq -r 'select(.rule.id|startswith("1001")) | "\(.rule.id)|\(.rule.level)|\(.rule.description)"' \
  | sort | uniq -c
```
```text
   5 100100|5|App: JWT validation failed
   1 100101|10|App: 5 JWT failures in 60s from same IP — possible token brute-force
```
*(measured 2026-08-24. Six events in, six alerts out — but the sixth fires as `100101`,
not `100100`. Wazuh reports one rule per event, the highest that matches.)*

> 🪤 **`<same_field>srcip</same_field>` looks right and does nothing.** `same_field` works
> on dynamic fields produced by a decoder; `srcip` is one of Wazuh's *static* fields, and
> the constraint silently never matches — you get the 5 base alerts and the composite rule
> never fires. Use `<same_source_ip />`. This was in this lab until it was run: the rule
> parsed, loaded and reported no errors, and the exercise just quietly did not work.

> 🪤 **`docker compose cp` will hand you a file the manager cannot read.** It preserves the
> *host* file's uid/gid and mode, so on macOS the ruleset lands as `-rw------- 501 games`
> and `wazuh-analysisd` (running as `wazuh`) logs one WARNING and loads no local rules:
> `(1103): Could not open file 'etc/rules/local_rules.xml' due to [(13)-(Permission denied)]`.
> The restart still succeeds and everything looks fine. `install-custom-rules.sh` chowns
> the file and then proves the rule is live with `wazuh-logtest` instead of trusting the
> restart — copy that habit.

> 💡 `wazuh-logtest` is the fastest loop in Wazuh rule development. It runs one log line
> through pre-decoding, decoding and the full ruleset and tells you which rule won, with
> no agent and no waiting:
> ```bash
> $ printf '%s\n' '{"event":"jwt_validation_failed","srcip":"10.1.2.3"}' \
>   | docker compose exec -T wazuh.manager /var/ossec/bin/wazuh-logtest
> ```

### Exercise 8 — Sigma rule → Wazuh rule

Sigma is a vendor-neutral detection language. Look at `exercises/sigma/suspicious-curl.yml`.

```bash
$ uv tool install sigma-cli --with pysigma-backend-opensearch   # or: pipx install sigma-cli
$ sigma check exercises/sigma/suspicious-curl.yml
```
```text
Found 0 errors, 0 condition errors and 0 issues.
```
*(measured 2026-08-24 with sigma-cli 3.1.0 / pySigma 1.5.0.)*

> 🪤 **`sigmac` is dead.** The old `sigmac` from the `sigma` repo was deprecated and
> removed; the current toolchain is [`sigma-cli`](https://github.com/SigmaHQ/sigma-cli)
> over pySigma, and backends are installed as plugins. If a tutorial tells you to run
> `sigmac -t ...`, it predates 2022.
>
> Also note `sigma plugin install <name>` fails inside a `uv tool` environment (no `pip`
> in it) — install backends with `--with` at tool-install time, as above.

Convert it. **There is no Wazuh backend** — `sigma plugin list` carries ~35 backends and
Wazuh is not among them, so for Wazuh the translation is always by hand. What the toolchain
gives you is validation and a reference query in a language that *does* have a backend:

```bash
$ sigma convert -t open_search_ppl exercises/sigma/suspicious-curl.yml
```
```text
source=linux-process_creation-* | where (LIKE(Image, "%/curl") OR LIKE(Image, "%/wget"))
  AND (LIKE(CommandLine, "%| sh%") OR LIKE(CommandLine, "%| bash%") OR LIKE(CommandLine, "%/tmp/%")
       OR LIKE(CommandLine, "%/dev/shm/%") OR LIKE(CommandLine, "%/var/tmp/%"))
```

Now write the Wazuh version yourself, then compare with the worked answer in
`exercises/sigma/suspicious-curl.wazuh.xml`. Install it alongside your exercise-7 rules
and validate it with `wazuh-logtest`:

```bash
$ ./scripts/install-custom-rules.sh exercises/sigma/suspicious-curl.wazuh.xml
$ printf '%s\n' 'type=EXECVE msg=audit(1755000000.123:456): argc=3 a0="curl" a1="-o" a2="/tmp/payload.sh"' \
  | docker compose exec -T wazuh.manager /var/ossec/bin/wazuh-logtest
```
```text
	id: '100300'
	level: '12'
	description: 'Sigma T1105: curl/wget downloading into a drop directory'
```
And confirm it stays quiet on a benign download — a detection you have not tested against
the negative case is not a detection:
```bash
$ printf '%s\n' 'type=EXECVE msg=audit(1755000000.125:458): argc=2 a0="curl" a1="https://example.com/index.html"' \
  | docker compose exec -T wazuh.manager /var/ossec/bin/wazuh-logtest
```
```text
	id: '80700'
	level: '0'
	description: 'Audit: Messages grouped.'
```
*(both measured 2026-08-24.)*

> 🪤 **You are validating the rule, not the pipeline.** The victim runs no auditd and no
> Sysmon-for-Linux, so it emits **no process-creation telemetry at all** — this rule can
> never fire from live traffic in this lab, which is why the check above feeds it a
> synthetic auditd line. That is not a workaround to be embarrassed about; it is the
> honest state of most Sigma rules people deploy. A rule whose log source you do not
> collect is a coverage map entry, not a detection. Wiring up auditd on the victim is the
> natural next step — see the challenges.

Note the `logsource:` block: `product: linux` + `category: process_creation`. The category
is what determines the field names — `Image` and `CommandLine` exist in the
`process_creation` taxonomy. If you write `service: auditd` instead, the fields are the raw
auditd ones (`exe`, `a0`, `a1`) and a rule using `Image` will convert to a query that can
never match. Field taxonomy is where most hand-written Sigma rules silently die; validate
with `sigma check` before you ship one.

> 💡 Notice what the hand-translation costs. Sigma matches structured `Image` and
> `CommandLine` fields; Wazuh's auditd decoder exposes only `audit.type` and `audit.id`,
> leaving `a0`/`a1`/`a2` in the raw message — so the structured match becomes a PCRE2
> regex over the whole line. Lossy translation is normal, and it is the reason you
> re-validate after converting rather than assuming the semantics survived.


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
2. **Give the victim process telemetry.** Exercise 8's Sigma rule has no log source to
   fire from. Add `auditd` to `scenarios/Dockerfile.victim` with an execve rule
   (`-a always,exit -F arch=b64 -S execve -k exec`), add a `<localfile>` with
   `<log_format>audit</log_format>` for `/var/log/audit/audit.log`, then run
   `curl -o /tmp/x https://example.com` on the victim and watch rule `100300` fire for
   real. Note that auditd in a container needs the host's audit subsystem — figuring out
   why it does or does not work is most of the value.
3. **Custom decoder.** Your app emits logs in a custom format. Write a Wazuh **decoder** (regex-based parser) and rules. Validate with `wazuh-logtest`.
4. **Detection coverage map.** Take 10 ATT&CK techniques relevant to your stack. Write Sigma rules for each, convert to Wazuh, document residual gaps.
5. **Tabletop exercise.** With a friend, role-play this scenario: a developer's laptop is found beaconing to a known C2 IP. Walk PICERL out loud. Time it. Write the post-mortem.

---

## 📚 Further reading

- [Wazuh docs](https://documentation.wazuh.com/)
- [Sigma project](https://github.com/SigmaHQ/sigma)
- [MITRE ATT&CK](https://attack.mitre.org/)
- [SANS PICERL handbook](https://www.sans.org/white-papers/incident-handlers-handbook-33901/)
- [Atomic Red Team](https://github.com/redcanaryco/atomic-red-team) — small attack scripts to test detections
- [GoatLog](https://github.com/openappsec/goatlog) for synthetic log generation
- [Wazuh: custom rules and decoders](https://documentation.wazuh.com/current/user-manual/ruleset/custom.html)

➡️ Next: [Lab 09 — Network Security](../09-network-security/)
