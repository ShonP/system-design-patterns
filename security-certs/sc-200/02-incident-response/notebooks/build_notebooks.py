"""Generate the SC-200 Lab 2 notebooks.

Run with:  uv run --project .. python build_notebooks.py
(from the notebooks/ directory). This file is a build tool only — the notebooks
themselves are what learners open.

WARNING: this regenerates the notebooks from the templates BELOW and will discard
any edit made directly to the .ipynb files. The committed notebooks have since been
hand-edited (corrected classification logic, campaign-link triage scoring, self-check
quizzes), so this script is kept for reference only. Do not run it unless you have
first ported those edits back into the templates here.
"""
import json
import uuid
from pathlib import Path

HERE = Path(__file__).parent


def md(src: str) -> dict:
    return {
        "cell_type": "markdown",
        "id": uuid.uuid4().hex[:8],
        "metadata": {},
        "source": src.splitlines(keepends=True),
    }


def code(src: str) -> dict:
    return {
        "cell_type": "code",
        "execution_count": None,
        "id": uuid.uuid4().hex[:8],
        "metadata": {},
        "outputs": [],
        "source": src.splitlines(keepends=True),
    }


def save(name: str, cells: list[dict]) -> None:
    nb = {
        "cells": cells,
        "metadata": {
            # Must match the repo-wide hygiene rule: notebooks bind to the local .venv.
            "kernelspec": {
                "display_name": "Python 3 (.venv)",
                "language": "python",
                "name": "python3",
            },
            "language_info": {"name": "python"},
        },
        "nbformat": 4,
        "nbformat_minor": 5,
    }
    (HERE / name).write_text(json.dumps(nb, indent=1, ensure_ascii=False) + "\n")


# ---------------------------------------------------------------------------
# Shared setup snippet reused at the top of every notebook
# ---------------------------------------------------------------------------
SETUP_MD = """## Setup

This lab reuses the mini-SIEM from Lab 1. Make sure it's running:

```bash
cd ../../01-build-a-siem && docker compose up -d
```

Then, in VS Code:
1. Pick the **`.venv` kernel** from this folder (top-right kernel picker).
2. If it's missing, reload the window (`Cmd+Shift+P` → `Reload Window`).

All cells talk to `http://localhost:8000` — the same mini-SIEM container seeded with a realistic multi-stage attack plus normal background traffic.
"""

SETUP_CODE = """import httpx
from collections import Counter, defaultdict
from datetime import datetime

SIEM = 'http://localhost:8000'

# Sanity check: can we reach the SIEM?
health = httpx.get(f'{SIEM}/health').json()
print('SIEM health:', health)

dashboard = httpx.get(f'{SIEM}/dashboard').json()
print('Dashboard:', dashboard)
"""


# ===========================================================================
# Notebook 1: Triage & correlation
# ===========================================================================
nb1: list[dict] = []

nb1.append(md("""# 1. Triage & Alert Correlation

Welcome to the SOC. A real analyst's day doesn't start with "hunt for evil" — it starts with **a queue of alerts**, and the first skill you need is deciding **what to look at first**.

This notebook teaches:

1. How raw alerts get grouped into **incidents** by shared entities (the "correlate" step).
2. How to **triage** an incident queue: not just severity, but recency, confidence, and blast radius.
3. A bad → best progression you can use on the exam AND in a real SOC.

> **SC-200 mapping**: "Triage security alerts and incidents" and "Manage incidents in Microsoft Defender XDR and Microsoft Sentinel".
"""))

nb1.append(md(SETUP_MD))
nb1.append(code(SETUP_CODE))

nb1.append(md("""## Step 1 — Look at raw alerts

Each **alert** is a single detection firing once. The mini-SIEM exposes them at `GET /alerts`.

Think of alerts as tickets an analyst could be asked to read. There are usually dozens per hour in a real tenant.
"""))

nb1.append(code("""alerts = httpx.get(f'{SIEM}/alerts').json()
print(f'Total alerts: {len(alerts)}\\n')

for a in alerts[:10]:
    print(f"[{a['severity']:<8}] {a['rule_name']:<32} tactic={a['tactic']!s:<18} status={a['status']}")
    print(f"           {a['title']}")
"""))

nb1.append(md("""## Step 2 — Correlate alerts into incidents

Several alerts can be **the same story**: a brute-force alert and a "sign-in from suspicious location" alert for the same user are almost certainly one incident, not two.

In Defender XDR and Sentinel, the platform groups them automatically. Our mini-SIEM exposes the same idea at `POST /incidents/correlate` — it groups "New" alerts by shared entities (e.g. `UserPrincipalName`).

The call is **idempotent-ish**: once an alert's status moves to `InIncident`, re-running won't create a duplicate incident for it.
"""))

nb1.append(code("""correlated = httpx.post(f'{SIEM}/incidents/correlate').json()
print('Correlation result:', correlated)

incidents = httpx.get(f'{SIEM}/incidents').json()
print(f'\\nTotal incidents now: {len(incidents)}')
for inc in incidents:
    print(f"  {inc['id']}  sev={inc['severity']:<8} status={inc['status']:<6}  {inc['title']}")
"""))

nb1.append(md("""## Step 3 — Bad triage: first-in-first-out

The **bad** approach is to just walk the queue top to bottom. You will burn hours on low-impact alerts while a real breach sits unanswered.
"""))

nb1.append(code("""print('❌ BAD: first-in-first-out (no prioritization)')
for inc in incidents:
    print(f"  → work on {inc['id']}  ({inc['severity']})")
""" ))

nb1.append(md("""## Step 4 — Better triage: severity + recency

A small step up is to sort by severity, tie-break by recency. This is what most junior SOCs actually do.
"""))

nb1.append(code("""SEV_ORDER = {'Critical': 4, 'High': 3, 'Medium': 2, 'Low': 1, 'Informational': 0}

better = sorted(
    incidents,
    key=lambda i: (SEV_ORDER.get(i['severity'], 0), i['created_at']),
    reverse=True,
)
print('⚠️  BETTER: severity then recency')
for inc in better:
    print(f"  {inc['severity']:<8} {inc['created_at']}  {inc['id']}  {inc['title']}")
"""))

nb1.append(md("""## Step 5 — Best triage: severity + confidence + blast radius + containment

Real SOC triage weighs four things, not one:

| Factor | Question |
|---|---|
| **Severity** | How bad is it if this is real? |
| **Confidence** | How likely is the detection real vs a false positive? Multiple correlated alerts ⇒ higher confidence. |
| **Blast radius** | How many users/devices/services are affected? |
| **Containment state** | Has automation already contained the threat? If yes, drop the urgency. |

We'll approximate each factor from the incident data and produce a **priority score**. Higher = look at first.
"""))

nb1.append(code("""# Pull each incident with its alerts (so we can count signal and entities)
def score(incident):
    detail = httpx.get(f"{SIEM}/incidents/{incident['id']}").json()
    alerts = detail.get('alerts', [])

    sev = SEV_ORDER.get(incident['severity'], 0)

    # Confidence: how many independent alerts fired for this story?
    confidence = min(len(alerts), 5)  # cap so one noisy rule doesn't dominate

    # Blast radius: unique devices + users mentioned in evidence
    actors = set()
    for a in alerts:
        import json as _json
        for ev in _json.loads(a['evidence'] or '[]'):
            for key in ('UserPrincipalName', 'DeviceName', 'AccountName', 'SourceIP'):
                if ev.get(key):
                    actors.add((key, ev[key]))
    blast = min(len(actors), 10)

    # Containment: new = not contained yet (add urgency), closed = contained
    containment_penalty = 0 if incident['status'] == 'New' else -2

    # Weighted priority score
    priority = sev * 10 + confidence * 3 + blast * 2 + containment_penalty
    return priority, {
        'severity': incident['severity'],
        'alerts': len(alerts),
        'blast': len(actors),
        'status': incident['status'],
        'priority': priority,
    }

ranked = [(score(i), i) for i in incidents]
ranked.sort(key=lambda x: x[0][0], reverse=True)

print('✅ BEST: severity + confidence + blast radius + containment')
print(f'{"incident":<12} {"prio":>4}  sev   alerts  blast  status   title')
for (p, meta), inc in ranked:
    print(f"{inc['id']:<12} {meta['priority']:>4}  {meta['severity']:<5} {meta['alerts']:>6}  {meta['blast']:>5}  {meta['status']:<7}  {inc['title']}")
"""))

nb1.append(md("""## What you just did (SC-200 mapping)

| You did... | Real portal equivalent |
|---|---|
| `GET /alerts` | Defender XDR → Alerts queue |
| `POST /incidents/correlate` | XDR's automatic alert-to-incident correlation |
| Ranked by severity + confidence + blast + containment | The **Priority** column and the analyst's mental model |
| Inspected incident with its alerts | Incident page → Alerts tab |

### Exam tips

- **Correlation is the point of an incident.** Don't work alerts one by one when they share entities.
- **Severity alone is a weak ranking.** Two High incidents with different blast radius are not equal.
- If **automatic attack disruption** already contained the threat, triage urgency drops — but investigation urgency does not.

➡️ Next: [02 — Entity-centric investigation](02_entity_pivot_investigation.ipynb)
"""))

save("01_triage_and_correlation.ipynb", nb1)


# ===========================================================================
# Notebook 2: Entity-centric investigation (replaces old multi_stage_attack)
# ===========================================================================
nb2: list[dict] = []

nb2.append(md("""# 2. Entity-Centric Investigation

In notebook 1 you picked the highest-priority incident. Now you have to **investigate** it.

The big lesson of this notebook: a detection tells you **one fact** (e.g. "15 failed sign-ins for alice"). A full investigation **pivots on entities** — user, IP, device, email — across every data source until the full kill chain is visible.

The seeded attack looks like this:

```
Stage 1  Phishing email delivered to alice@contoso.com
Stage 2  15 failed + 1 successful sign-in from Moscow (brute force)
Stage 3  psexec.exe + mimikatz.exe on laptop-alice → spread to VMs
Stage 4  Large outbound uploads to known-bad IPs (exfiltration)
```

Your job: **prove all four stages** by pivoting on entities.

> **SC-200 mapping**: "Investigate alerts and incidents in Microsoft Defender XDR" and "Hunt threats with KQL".
"""))

nb2.append(md(SETUP_MD))
nb2.append(code(SETUP_CODE))

nb2.append(md("""## ❌ Bad: tunnel vision on the triggering alert

A junior analyst reads the brute-force alert, says "alice's password is weak", forces a password reset, and closes the incident.

They just missed three other stages of the attack. Let's show what they saw:
"""))

nb2.append(code("""# Pick the brute-force incident (highest-severity, CredentialAccess tactic)
incidents = httpx.get(f'{SIEM}/incidents').json()
brute = next(
    (i for i in incidents if 'Brute force' in i['title']),
    incidents[0],
)
detail = httpx.get(f"{SIEM}/incidents/{brute['id']}").json()

print(f"Incident: {detail['title']}  ({detail['severity']})")
print(f"Alerts attached: {len(detail['alerts'])}")
for a in detail['alerts']:
    print(f"  • {a['rule_name']} — {a['title']}")
print('\\n❌ Stopping here would miss phishing, lateral movement, and exfiltration.')
"""))

nb2.append(md("""## ✅ Best: pivot on entities, across data sources

From the incident we pull the **primary entity** (the user) and let it drive queries into every relevant table.

> Real Defender XDR does this visually with the **Incident graph**; Sentinel does it with entity pages and KQL joins. We're rebuilding that flow by hand so the idea sticks.
"""))

nb2.append(code("""import json as _json
entities = _json.loads(detail['entities'] or '{}')
primary_user = entities.get('UserPrincipalName', 'alice@contoso.com')
print(f'Primary entity: user = {primary_user}')
"""))

nb2.append(md("""### Stage 1 — Initial Access (email)

**MITRE tactic**: `TA0001 Initial Access`. If the user was phished, we should see an email from a look-alike sender.
"""))

nb2.append(code("""r = httpx.post(f'{SIEM}/query', json={
    'table_name': 'EmailEvents',
    'filter': {'RecipientEmailAddress': primary_user},
    'limit': 20,
})
emails = r.json()['results']
phish = [e for e in emails if e.get('ThreatTypes') == 'Phish']

print(f"Emails to {primary_user}: {len(emails)}   Phish flagged: {len(phish)}")
for e in phish:
    mark = '📬 DELIVERED' if e['DeliveryAction'] == 'Delivered' else '🚫 blocked'
    print(f"  {mark}  from {e['SenderFromAddress']}  →  {e['Subject']}")
"""))

nb2.append(md("""### Stage 2 — Credential Access (sign-ins)

**MITRE tactic**: `TA0006 Credential Access`. Brute force usually looks like many failures from one or two IPs, possibly from unusual locations.
"""))

nb2.append(code("""r = httpx.post(f'{SIEM}/query', json={
    'table_name': 'SigninLogs',
    'filter': {'UserPrincipalName': primary_user},
    'limit': 50,
})
signins = r.json()['results']
fail = [s for s in signins if s['ResultType'] == 'Failure']
succ = [s for s in signins if s['ResultType'] == 'Success']
print(f'Sign-ins: {len(signins)}   failures: {len(fail)}   successes: {len(succ)}')

SUS_LOC = {'Moscow', 'Beijing', 'Anonymous Proxy'}
bad_ips = Counter(s['IPAddress'] for s in fail)
print('Top failure IPs:', bad_ips.most_common(3))
print('Locations:')
for loc, n in Counter(s['Location'] for s in signins).most_common():
    mark = ' ⚠️' if loc in SUS_LOC else ''
    print(f'  {loc}: {n}{mark}')

# Pivot: remember the suspicious IP — we'll use it in stage 4
attacker_ip = bad_ips.most_common(1)[0][0] if bad_ips else None
print(f'\\nPivot target → attacker IP: {attacker_ip}')
"""))

nb2.append(md("""### Stage 3 — Execution & Lateral Movement (endpoint)

**MITRE tactics**: `TA0002 Execution` + `TA0008 Lateral Movement`. After cred theft, attackers run tooling like `psexec`, `mimikatz`, `certutil`, `cmd`, or `powershell`.
"""))

nb2.append(code("""username = primary_user.split('@')[0]
r = httpx.post(f'{SIEM}/query', json={
    'table_name': 'DeviceEvents',
    'filter': {'AccountName': username},
    'limit': 50,
})
endpoint = r.json()['results']

SUS_TOOLS = {'mimikatz.exe', 'psexec.exe', 'certutil.exe'}
sus = [e for e in endpoint if e['FileName'] in SUS_TOOLS]
print(f'Endpoint events for {username}: {len(endpoint)}   known-bad tooling: {len(sus)}')

for e in sus:
    print(f"  🔴 {e['DeviceName']:<14}  {e['FileName']:<14} {e['ActionType']}   path={e['FolderPath']}")

print('\\nDevices touched:')
for dev, n in Counter(e['DeviceName'] for e in endpoint).most_common():
    print(f'  {dev}: {n} events')
"""))

nb2.append(md("""### Stage 4 — Exfiltration (network)

**MITRE tactic**: `TA0010 Exfiltration`. Connections to known-bad destinations are a strong signal. In a real tenant you'd match against a threat-intel feed — here we use a hard-coded list.
"""))

nb2.append(code("""KNOWN_BAD_IPS = ['185.220.101.42', '45.33.32.156', '198.51.100.99']
exfil = []
for ip in KNOWN_BAD_IPS:
    r = httpx.post(f'{SIEM}/query', json={
        'table_name': 'AzureFirewall',
        'filter': {'DestinationIP': ip},
        'limit': 20,
    })
    rows = r.json()['results']
    if rows:
        exfil.extend(rows)
        srcs = Counter(row['SourceIP'] for row in rows)
        print(f'⚠️  {len(rows)} connections to {ip}')
        for s, n in srcs.most_common():
            print(f'       from {s}  × {n}')

print(f'\\nTotal suspicious outbound flows: {len(exfil)}')
"""))

nb2.append(md("""## Write the incident report

The investigation isn't over until you **write it down**. A good incident summary contains: timeline, entities touched, MITRE tactics seen, and recommended response.

Below we generate one automatically from the data we collected, then attach it as a comment on the incident (`PATCH /incidents/{id}`).
"""))

nb2.append(code("""report_lines = [
    f"Incident {detail['id']} — {detail['title']}",
    f"User: {primary_user}    Attacker IP: {attacker_ip}",
    f"Stage 1 Initial Access : {len(phish)} phishing email(s) to the user",
    f"Stage 2 Credential Access: {len(fail)} failed sign-ins, {len(succ)} success from suspicious IP",
    f"Stage 3 Execution/LatMov : {len(sus)} known-bad tool executions across {len({e['DeviceName'] for e in sus})} device(s)",
    f"Stage 4 Exfiltration     : {len(exfil)} outbound flows to known-bad IPs",
    "Recommended response:",
    "  1. Contain — isolate laptop-alice, disable alice's account",
    "  2. Eradicate — remove mimikatz/psexec, reset credentials, revoke tokens",
    "  3. Recover — re-image affected hosts, re-enable account with MFA",
]
report = '\\n'.join(report_lines)
print(report)

# Persist the report as an incident comment (safe to re-run; PATCH will append)
httpx.patch(
    f"{SIEM}/incidents/{detail['id']}",
    json={'comment': report},
)
print('\\n📝 Report attached to incident as a comment.')
"""))

nb2.append(md("""## What you just did (SC-200 mapping)

| You did... | Real portal equivalent |
|---|---|
| Picked the incident's primary entity | Incident page → Assets tab |
| Pivoted user → email / sign-in / endpoint / network | Defender XDR incident graph |
| Tagged each finding with a MITRE tactic | ATT&CK column on alerts & incidents |
| Wrote a timeline report as a comment | Incident → Comments / Activity log |

### Exam tips

- The investigation is complete only when you can name the **full kill chain** and every **entity** touched.
- A brute-force alert is rarely the whole story. Always pivot the user forward (exec, lateral, exfil) and backward (email, phishing).
- Network evidence (firewall + proxy) is the usual confirmation of exfiltration.

➡️ Next: [03 — Incident lifecycle & classification](03_incident_lifecycle.ipynb)
"""))

save("02_entity_pivot_investigation.ipynb", nb2)


# ===========================================================================
# Notebook 3: Incident lifecycle
# ===========================================================================
nb3: list[dict] = []

nb3.append(md("""# 3. Incident Lifecycle: Assign, Classify, Tune

An investigation isn't finished when you **know** what happened — it's finished when the incident is properly **closed**. SC-200 tests this heavily: you must know the classification taxonomy and how closing an incident feeds learning back into the system.

This notebook walks the lifecycle `New → Active → Closed` with assignment, comments, classification, and rule tuning — plus the bad-vs-best contrast.

> **SC-200 mapping**: "Manage incidents", "Classify and tune analytics rules".
"""))

nb3.append(md(SETUP_MD))
nb3.append(code(SETUP_CODE))

nb3.append(md("""## The classification taxonomy

When you close an incident you **must** classify it. This trains the ML and gives engineering a signal to tune rules.

| Classification | When to use | Example |
|---|---|---|
| **True Positive** | Real malicious activity, action required | Confirmed phishing + credential theft |
| **Benign Positive** | Real activity, but not malicious | Authorized pen-test triggered an alert |
| **False Positive** | The detection was wrong | Legitimate admin tool flagged as malware |
| **Undetermined** | Not enough evidence to decide yet | Suspicious but isolated signal |

Closing without classifying is the single most common SOC anti-pattern.
"""))

nb3.append(md("""## ❌ Bad: silent close

The bad analyst just flips the status to `Closed`. No comment. No classification. No one learns anything.
"""))

nb3.append(code("""incidents = httpx.get(f'{SIEM}/incidents').json()

# We'll demonstrate on a lower-severity incident so we don't close the real attack
target = next((i for i in incidents if i['severity'] != 'High' and i['status'] == 'New'), incidents[-1])
print(f"Demo target: {target['id']}  {target['title']}")

# BAD: just close it
httpx.patch(f"{SIEM}/incidents/{target['id']}", json={'status': 'Closed'})

closed = httpx.get(f"{SIEM}/incidents/{target['id']}").json()
print(f"\\n❌ status={closed['status']}  classification={closed['classification']!r}  comments={len(_json_loads(closed['comments']))} entries")
""".replace("_json_loads", "__import__('json').loads")))

nb3.append(md("""## ✅ Best: assign → comment → classify → close

A mature close does four things, in this order:

1. **Assign** the incident to a named analyst (accountability).
2. **Comment** with the timeline and the "why" of the classification (institutional memory).
3. **Classify** so the detection engine can learn.
4. **Close** the incident.

Our mini-SIEM exposes all four through `PATCH /incidents/{id}`. That endpoint is **not idempotent** — every call appends to comments and overwrites the other fields — so below we read the incident first and only update the fields that need updating.
"""))

nb3.append(code("""def mature_close(incident_id: str, analyst: str, summary: str, classification: str):
    current = httpx.get(f'{SIEM}/incidents/{incident_id}').json()

    # 1. Assign (only if not yet assigned — keeps reruns clean)
    if not current.get('assigned_to'):
        httpx.patch(f'{SIEM}/incidents/{incident_id}', json={'assigned_to': analyst})

    # 2. Add the summary comment (only once, to avoid duplicates on rerun)
    import json as _json
    existing = _json.loads(current.get('comments') or '[]')
    if not any(summary == c.get('text') for c in existing):
        httpx.patch(f'{SIEM}/incidents/{incident_id}', json={'comment': summary})

    # 3. Classify (only if not already classified)
    if not current.get('classification'):
        httpx.patch(f'{SIEM}/incidents/{incident_id}', json={'classification': classification})

    # 4. Close
    httpx.patch(f'{SIEM}/incidents/{incident_id}', json={'status': 'Closed'})

    return httpx.get(f'{SIEM}/incidents/{incident_id}').json()

# Walk every "New" incident and close it maturely
for inc in httpx.get(f'{SIEM}/incidents').json():
    if inc['status'] != 'New':
        continue
    cls = 'TruePositive' if inc['severity'] in ('High', 'Critical') else 'BenignPositive'
    result = mature_close(
        inc['id'],
        analyst='analyst1@contoso.com',
        summary=f"Triaged {inc['title']}. Evidence correlated across sources. Classified as {cls}.",
        classification=cls,
    )
    print(f"✅ {result['id']:<12} status={result['status']:<7} class={result['classification']:<14} assigned={result['assigned_to']}")
"""))

nb3.append(md("""## Tuning: the forgotten step

If you classify an incident as **False Positive**, the job isn't done — you should also **tune the rule** so it stops firing on the same false pattern. Otherwise you'll keep closing the same FP over and over.

Common tuning moves in Sentinel/Defender XDR:

| Tuning move | When to use |
|---|---|
| **Raise the threshold** | Rule fires on benign bursts of activity |
| **Add an exclusion filter** | A specific admin tool or scanner is triggering it |
| **Suppress for an entity** | A specific service account generates expected traffic |
| **Lower the severity** | The pattern is suspicious but rarely a real threat |
| **Disable the rule** | The rule is obsolete (only as a last resort) |

Let's simulate tuning: show that a `False Positive` incident points us at a rule we should adjust.
"""))

nb3.append(code("""fps = [i for i in httpx.get(f'{SIEM}/incidents').json() if i.get('classification') == 'FalsePositive']
print(f'False-positive incidents: {len(fps)}')
if fps:
    for i in fps:
        print(f"  → tune rule behind: {i['title']}")
else:
    print('None in this seed data — but in a real SOC, every FP should trigger a rule review within the week.')

# Show the rules that would be candidates for tuning review
rules = httpx.get(f'{SIEM}/rules').json()
print('\\nActive rules (candidates for tuning if misfiring):')
for r in rules:
    print(f"  {r['name']:<34}  sev={r['severity']:<6} threshold={r['threshold']:<3} window={r['window_minutes']}m")
"""))

nb3.append(md("""## What you just did (SC-200 mapping)

| You did... | Real portal equivalent |
|---|---|
| `PATCH /incidents/{id}` with `status/assigned_to/classification/comment` | Incident page → Manage incident panel |
| Guarded against duplicate comments on rerun | Real portals don't dedupe for you either — discipline matters |
| Listed rule parameters for tuning | Analytics rule → Edit → Query logic / thresholds |

### Exam tips

- Know the **four classifications** by name and when to use each.
- "Close" is **not** a classification — it's a status. Always classify.
- **False Positive ⇒ tune the rule.** Closing FPs without tuning is how alert fatigue starts.
- In Defender XDR, closing an incident closes all underlying alerts automatically.

➡️ Next: [04 — Automated response & IOCs](04_automated_response.ipynb)
"""))

save("03_incident_lifecycle.ipynb", nb3)


# ===========================================================================
# Notebook 4: Automated response & watchlists
# ===========================================================================
nb4: list[dict] = []

nb4.append(md("""# 4. Automated Response & IOC Matching

When the SOC gets paged at 3 a.m. it's too late to write a runbook. Your response should be **pre-authored** and, where safe, **automated**.

This notebook covers:

1. The response procedures SC-200 tests for each Defender product.
2. **Containment vs eradication vs recovery** — they're not the same thing.
3. **Playbooks**: create, trigger, inspect runs.
4. **Watchlists**: match logs against IOCs (indicators of compromise) exactly like Sentinel's `externaldata()` + `in (…)` pattern.

> **SC-200 mapping**: "Configure automation", "Respond to alerts and incidents across Defender XDR and Sentinel".
"""))

nb4.append(md(SETUP_MD))
nb4.append(code(SETUP_CODE))

nb4.append(md("""## Response procedure cheat sheet (per product)

Memorize these — the exam asks them directly.

### Defender for Office 365 (email)

| Step | Action |
|---|---|
| 1 | Open the email entity page; inspect headers, URLs, attachments (detonation results). |
| 2 | Find all recipients via Advanced Hunting (`EmailEvents`). |
| 3 | **Soft delete** the email from every mailbox (recoverable). |
| 4 | Block sender/domain in the Tenant Allow/Block List. |
| 5 | Check `UrlClickEvents` for anyone who clicked. |
| 6 | If clicked → expand to user-entity investigation. |

### Defender for Endpoint (device)

| Step | Action |
|---|---|
| 1 | Review device timeline and alert process tree. |
| 2 | **Isolate** the device (network containment). |
| 3 | Collect investigation package (forensic bundle). |
| 4 | Run AV scan; quarantine files via `remediate file …` in Live Response. |
| 5 | Release from isolation only after eradication + recovery. |

### Defender for Identity (on-prem AD)

Detects pass-the-hash, pass-the-ticket, golden ticket, DCSync, reconnaissance, lateral movement. Response: disable the account, reset KRBTGT twice if golden ticket, coordinate with AD team.

### Defender for Cloud Apps (SaaS)

Revoke OAuth consent, ban malicious apps, suspend compromised users, require MFA on impossible-travel alerts, block/sanction shadow IT.
"""))

nb4.append(md("""## Containment vs eradication vs recovery

| Phase | Goal | Typical actions |
|---|---|---|
| **Containment** | Stop the bleeding **right now**, even if ugly | Isolate device, disable account, revoke tokens, block IP |
| **Eradication** | Remove the attacker's foothold | Delete malware, reset creds, remove persistence, patch the entry point |
| **Recovery** | Return to normal, safely | Re-image hosts, re-enable accounts with MFA, restore data, monitor closely |

A common analyst mistake: calling containment "done" and skipping eradication. The attacker just re-enters.
"""))

nb4.append(md("""## Automated response with playbooks

A **playbook** is a set of actions that runs automatically when a rule matches. In Sentinel it's a Logic App; in Defender XDR it's a built-in automation rule.

Our mini-SIEM lets you POST a playbook and trigger it against an incident:

- `POST /playbooks` — create (⚠️ not upsert; we'll dedupe by name below).
- `GET /playbooks` — list enabled playbooks.
- `POST /playbooks/run/{incident_id}` — run every playbook whose trigger matches the incident's severity and tactic.

### ❌ Bad: one-off manual response every time
Each 3 a.m. page a human runs the same five steps by hand. Inconsistent, slow, exhausting.

### ✅ Best: codified playbooks triggered by severity + tactic
"""))

nb4.append(code("""# Idempotent playbook creation: skip if a playbook with this name already exists
def upsert_playbook(pb):
    existing = {p['name']: p for p in httpx.get(f'{SIEM}/playbooks').json()}
    if pb['name'] in existing:
        return existing[pb['name']]
    return httpx.post(f'{SIEM}/playbooks', json=pb).json()

pb_brute = upsert_playbook({
    'name': 'Contain-BruteForce',
    'trigger_severity': 'High',
    'trigger_tactic': 'CredentialAccess',
    'actions': [
        {'type': 'disable_user', 'note': 'Disable the account in Entra ID'},
        {'type': 'revoke_sessions', 'note': 'Revoke all refresh tokens'},
        {'type': 'require_mfa', 'note': 'Force MFA on next sign-in'},
    ],
})
pb_lat = upsert_playbook({
    'name': 'Contain-LateralMovement',
    'trigger_severity': 'High',
    'trigger_tactic': 'Execution',
    'actions': [
        {'type': 'isolate_device', 'note': 'Network-isolate via Defender for Endpoint'},
        {'type': 'collect_package', 'note': 'Collect investigation package'},
        {'type': 'run_av_scan', 'note': 'Full AV scan'},
    ],
})

print('Playbooks registered:')
for p in httpx.get(f'{SIEM}/playbooks').json():
    print(f"  {p['name']:<28} trigger sev={p['trigger_severity']!s:<6} tactic={p['trigger_tactic']}")
"""))

nb4.append(code("""# Trigger matching playbooks on the brute-force incident (if still present)
incidents = httpx.get(f'{SIEM}/incidents').json()
target = next((i for i in incidents if 'Brute force' in i['title']), None)
if target:
    result = httpx.post(f"{SIEM}/playbooks/run/{target['id']}").json()
    print(f"Ran playbooks on {target['id']}:")
    for r in result['playbooks_executed']:
        print(f"  ▶ {r['playbook']}  (run {r['run_id']})")
        for action in r['actions']:
            desc = action.get('note') or action.get('description') or ''
            print(f"      - {action['type']:<16} {desc}")
else:
    print('No brute-force incident present (notebook 3 may have closed all of them).')
"""))

nb4.append(md("""## Watchlists and IOC matching

A **watchlist** is a named list of indicators (IPs, domains, file hashes, VIP users). You maintain it in one place and match every log against it.

In Sentinel:

```
let bad_ips = _GetWatchlist('KnownBadIPs') | project IPAddress;
AzureFirewall | where DestinationIP in (bad_ips)
```

Our mini-SIEM exposes the same shape: `POST /watchlists` (upsert) and `POST /watchlists/match`.
"""))

nb4.append(code("""# 1. Upsert a watchlist of known-bad IPs (upsert = safe to re-run)
httpx.post(f'{SIEM}/watchlists', json={
    'name': 'KnownBadIPs',
    'description': 'C2 infrastructure from threat intel feed',
    'items': ['185.220.101.42', '45.33.32.156', '198.51.100.99'],
})

# 2. Match firewall logs against the watchlist
match = httpx.post(f'{SIEM}/watchlists/match', json={
    'watchlist': 'KnownBadIPs',
    'table_name': 'AzureFirewall',
    'field': 'DestinationIP',
    'time_range_minutes': 1440,
    'limit': 50,
}).json()

print(f"Matches for KnownBadIPs: {match['match_count']}")
for m in match['matches'][:5]:
    print(f"  [{m['timestamp'][:19]}] {m['SourceIP']} → {m['DestinationIP']}:{m['DestinationPort']} ({m['Action']})")
"""))

nb4.append(code("""# IOC matching also works on user watchlists — e.g. VIP accounts to watch extra-closely
httpx.post(f'{SIEM}/watchlists', json={
    'name': 'VIPUsers',
    'description': 'Executives & privileged accounts — scrutinize every sign-in',
    'items': ['alice@contoso.com'],
})

vip_hits = httpx.post(f'{SIEM}/watchlists/match', json={
    'watchlist': 'VIPUsers',
    'table_name': 'SigninLogs',
    'field': 'UserPrincipalName',
    'time_range_minutes': 1440,
    'limit': 200,
}).json()

failed_vip = [m for m in vip_hits['matches'] if m['ResultType'] == 'Failure']
print(f"VIP sign-ins in last 24h: {vip_hits['match_count']}  (failures: {len(failed_vip)})")
"""))

nb4.append(md("""## When to trust automation (and when not to)

Automation is a force multiplier, but it can also do damage at machine speed. SC-200 expects you to reason about **blast radius of the automation itself**.

| Action | Safe to fully automate? | Why |
|---|---|---|
| **Isolate a device** | ✅ Usually | Reversible in one click; stops exfil immediately. |
| **Disable a user** | ⚠️ With care | Can page the whole exec team at 3 a.m. if wrong. Scope to non-VIP accounts or require analyst approval. |
| **Delete email from mailboxes** | ✅ Soft delete only | Soft delete is recoverable; **never** auto-hard-delete. |
| **Reset a password** | ⚠️ With care | Can lock out a real user mid-flight. Combine with token revocation + MFA. |
| **Re-image a device** | ❌ Never auto | Data-destructive; requires human sign-off. |

Defender XDR's **automatic attack disruption** follows exactly these rules: it disables users, contains devices, and blocks OAuth apps — but it does not delete user data.
"""))

nb4.append(md("""## What you just did (SC-200 mapping)

| You did... | Real portal equivalent |
|---|---|
| `POST /playbooks` | Sentinel → Automation rule + Logic App |
| `POST /playbooks/run/{incident}` | XDR automation rule firing on an incident |
| `POST /watchlists` | Sentinel → Watchlists |
| `POST /watchlists/match` | KQL `in (_GetWatchlist(…))` |

### Exam tips

- Know the **containment / eradication / recovery** phases and give an action for each.
- Know **soft vs hard delete** for email; only soft delete is auto-safe.
- **Playbook triggers** match on severity, tactic, or rule — not on free-text.
- **Watchlists** are the right tool for maintained lists of IOCs or VIPs; do not hard-code them in every rule.

🎉 You've completed Lab 2. In Lab 3 you'll proactively *hunt* with the same SIEM.
"""))

save("04_automated_response.ipynb", nb4)

print("OK — wrote 4 notebooks.")
