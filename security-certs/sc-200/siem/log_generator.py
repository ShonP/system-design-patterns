"""
Log generator — simulates security events from multiple sources.
Produces realistic data for the mini-SIEM to ingest, including:
    - Sign-in logs (like Entra ID SigninLogs)
    - Firewall logs (like AzureFirewall)
    - Endpoint events (like DeviceEvents)
    - Email events (like EmailEvents)

Includes normal activity AND injected attack patterns:
    - Brute force SSH/sign-in
    - Lateral movement
    - Data exfiltration
    - Phishing campaigns
"""
import random
import time
import httpx
from datetime import datetime, timedelta, timezone

# Seeded so every `docker compose up` produces the SAME dataset. Without this the
# attack chain is re-rolled on every run and detections fire probabilistically --
# a lab whose lesson only shows up 70% of the time is not a lab.
random.seed(20260821)


def _utcnow():
    return datetime.now(timezone.utc).replace(tzinfo=None)

SIEM_URL = "http://siem:8000"
NORMAL_USERS = ["alice@contoso.com", "bob@contoso.com", "carol@contoso.com", "dave@contoso.com", "eve@contoso.com"]
ATTACKER = "attacker@evil.com"
NORMAL_IPS = ["10.0.1.10", "10.0.1.11", "10.0.1.12", "10.0.2.10", "10.0.2.11"]
# The threat-intel list the notebooks build watchlists from. Only CAMPAIGN_IP is
# actually active in this dataset -- a TI feed you match against is mostly IOCs that
# never fire, and a watchlist demo where every entry hits is not a watchlist demo.
SUSPICIOUS_IPS = ["185.220.101.42", "45.33.32.156", "198.51.100.99"]
# One campaign, one attacker IP. It is the join key between SigninLogs (who
# authenticated) and AzureFirewall (what talked to whom) -- entity pivoting only
# works if the same value actually appears in both tables.
CAMPAIGN_IP = "185.220.101.42"
INTERNAL_HOSTS = ["vm-web-01", "vm-app-01", "vm-db-01", "laptop-alice", "laptop-bob"]
# Host -> address, so a "lateral movement to vm-db-01" firewall row actually points
# at vm-db-01 instead of repeating one hard-coded flow three times.
HOST_IPS = {
    "vm-web-01": "10.0.3.11",
    "vm-app-01": "10.0.3.12",
    "vm-db-01": "10.0.3.13",
    "laptop-alice": "10.0.1.10",
    "laptop-bob": "10.0.1.11",
}
APPS = ["Azure Portal", "Outlook", "Teams", "SharePoint", "Custom App"]
LOCATIONS = ["Seattle", "London", "New York", "Office"]
SUSPICIOUS_LOCATIONS = ["Moscow", "Beijing", "Anonymous Proxy"]


def past_iso(minutes_ago: float):
    """Timestamp `minutes_ago` in the past.

    Naive-UTC with no trailing "Z" so it string-compares correctly against the
    cutoffs the SIEM builds with `datetime.isoformat()`. Everything the generator
    writes is time-spread: if every row carries the same instant then `ORDER BY
    timestamp` is an arbitrary tie-break and every time-window filter is a no-op.
    """
    return (_utcnow() - timedelta(minutes=minutes_ago)).isoformat()


def now_iso():
    """Right now. Kept for callers that want an un-shifted timestamp."""
    return past_iso(0)


def generate_signin_log(user: str, success: bool, ip: str, location: str,
                        minutes_ago: float = 0, risk: str | None = None):
    return {
        "table_name": "SigninLogs",
        "timestamp": past_iso(minutes_ago),
        "data": {
            "UserPrincipalName": user,
            "IPAddress": ip,
            "Location": location,
            "ResultType": "Success" if success else "Failure",
            "AppDisplayName": random.choice(APPS),
            "DeviceDetail": random.choice(["Windows 11", "macOS", "iOS", "Linux"]),
            "RiskLevel": risk if risk is not None else ("none" if success else random.choice(["low", "medium"])),
            "MFACompleted": success and random.random() > 0.2,
        },
    }


def generate_firewall_log(src_ip: str, dst_ip: str, dst_port: int, action: str,
                          minutes_ago: float = 0, bytes_sent: int | None = None):
    return {
        "table_name": "AzureFirewall",
        "timestamp": past_iso(minutes_ago),
        "data": {
            "SourceIP": src_ip,
            "DestinationIP": dst_ip,
            "DestinationPort": dst_port,
            "Protocol": "TCP",
            "Action": action,
            "Rule": f"rule-{random.randint(1,20)}",
            "BytesSent": bytes_sent if bytes_sent is not None else random.randint(500, 20_000),
        },
    }


def generate_endpoint_event(host: str, user: str, process: str, action: str,
                            minutes_ago: float = 0, file_size: int | None = None):
    data = {
        "DeviceName": host,
        "AccountName": user.split("@")[0],
        "FileName": process,
        "ActionType": action,
        "FolderPath": random.choice(["/usr/bin/", "C:\\Windows\\System32\\", "/tmp/", "C:\\Users\\Downloads\\"]),
    }
    if file_size is not None:
        # "Large upload" has to be a number in the row, not an adjective in a print().
        data["FileSizeBytes"] = file_size
    return {"table_name": "DeviceEvents", "timestamp": past_iso(minutes_ago), "data": data}


def generate_email_event(sender: str, recipient: str, subject: str, has_attachment: bool,
                         is_phish: bool, minutes_ago: float = 0, delivered: bool | None = None):
    if delivered is None:
        delivered = not is_phish
    return {
        "table_name": "EmailEvents",
        "timestamp": past_iso(minutes_ago),
        "data": {
            "SenderFromAddress": sender,
            "RecipientEmailAddress": recipient,
            "Subject": subject,
            "AttachmentCount": 1 if has_attachment else 0,
            "ThreatTypes": "Phish" if is_phish else "",
            "DeliveryAction": "Delivered" if delivered else "Blocked",
            "UrlCount": random.randint(0, 3),
        },
    }


# The attack chain is laid down in kill-chain order over the last ~13 minutes:
# phish (T-13) -> brute force (T-11..T-8) -> lateral movement (T-6..T-4) ->
# exfiltration (T-3..T-0). Kept deliberately tight so every stage still sits inside
# the 60-minute rule windows even if you open the notebooks a while after seeding.
T_PHISH, T_BRUTE, T_LATERAL, T_EXFIL = 13.0, 11.0, 6.0, 3.0

# Benign failed sign-ins per normal user. Must stay BELOW the brute-force rule's
# threshold of 5 -- these are the "fat-fingered password" population the detection
# has to *not* alert on. Without them the rule's precision is unfalsifiable: it
# looks perfect because there is nothing in the data for it to be wrong about.
#
# alice is deliberately absent: she is the compromised account, and the labs
# attribute every one of her failures to the campaign IP. Giving her typos too
# would make those downstream counts subtly wrong.
BENIGN_FAILURES_PER_USER = {
    "bob@contoso.com": 3,
    "carol@contoso.com": 1,
    "dave@contoso.com": 4,
    "eve@contoso.com": 2,
}


def inject_normal_traffic(client: httpx.Client, count: int = 20):
    """Generate normal-looking activity, spread over the last ~55 minutes."""
    entries = []
    for _ in range(count):
        ago = random.uniform(15.0, 55.0)
        entries.append(generate_signin_log(random.choice(NORMAL_USERS), True, random.choice(NORMAL_IPS), random.choice(LOCATIONS), minutes_ago=ago))
        entries.append(generate_firewall_log(random.choice(NORMAL_IPS), "10.0.3.50", random.choice([443, 80, 8080]), "Allow", minutes_ago=ago))
        entries.append(generate_endpoint_event(random.choice(INTERNAL_HOSTS), random.choice(NORMAL_USERS), random.choice(["chrome.exe", "code", "python3", "outlook.exe"]), "ProcessCreated", minutes_ago=ago))
        entries.append(generate_email_event("newsletter@service.com", random.choice(NORMAL_USERS), "Weekly update", False, False, minutes_ago=ago))

    # Everyday password typos. Real environments are full of these; a detection that
    # has never met one has never been tested.
    benign_failures = 0
    for user, n in BENIGN_FAILURES_PER_USER.items():
        for _ in range(n):
            entries.append(generate_signin_log(
                user, False, random.choice(NORMAL_IPS), random.choice(LOCATIONS),
                minutes_ago=random.uniform(15.0, 55.0), risk="none",
            ))
            benign_failures += 1

    client.post(f"{SIEM_URL}/ingest/batch", json={"entries": entries})
    print(f"  ✅ Injected {len(entries)} normal events ({benign_failures} of them benign sign-in failures)")


def inject_brute_force(client: httpx.Client, target_user: str, count: int = 15):
    """Simulate brute force sign-in attack, then the success that ends it."""
    entries = []
    # One source, one location: a password-spray tool does not hop countries mid-run,
    # and the notebooks need a stable IP to pivot on.
    for i in range(count):
        ago = T_BRUTE - (i / count) * 2.0
        entries.append(generate_signin_log(target_user, False, CAMPAIGN_IP, "Moscow", minutes_ago=ago, risk="medium"))
    entries.append(generate_signin_log(target_user, True, CAMPAIGN_IP, "Moscow", minutes_ago=T_BRUTE - 2.2, risk="high"))
    client.post(f"{SIEM_URL}/ingest/batch", json={"entries": entries})
    print(f"  🔴 Injected brute force: {count} failures + 1 success for {target_user} from {CAMPAIGN_IP}")


def inject_lateral_movement(client: httpx.Client):
    """Simulate lateral movement after compromise."""
    entries = []
    compromised_host = "laptop-alice"
    src_ip = HOST_IPS[compromised_host]
    for i, target in enumerate(["vm-app-01", "vm-db-01", "vm-web-01"]):
        ago = T_LATERAL - i * 0.6
        entries.append(generate_endpoint_event(compromised_host, "alice", "psexec.exe", "RemoteExecution", minutes_ago=ago))
        # SMB to the host actually being reached, not the same hard-coded flow 3x.
        entries.append(generate_firewall_log(src_ip, HOST_IPS[target], 445, "Allow", minutes_ago=ago - 0.1))
        entries.append(generate_endpoint_event(target, "alice", "cmd.exe", "ProcessCreated", minutes_ago=ago - 0.2))
        entries.append(generate_endpoint_event(target, "alice", "mimikatz.exe", "ProcessCreated", minutes_ago=ago - 0.3))
    client.post(f"{SIEM_URL}/ingest/batch", json={"entries": entries})
    print(f"  🔴 Injected lateral movement from {compromised_host} to 3 targets")


def inject_data_exfiltration(client: httpx.Client, count: int = 10):
    """Simulate data exfiltration: large uploads out to the campaign's C2 address."""
    entries = []
    total_bytes = 0
    for i in range(count):
        ago = T_EXFIL - (i / count) * 3.0
        size = random.randint(40_000_000, 120_000_000)  # 40-120 MB per upload
        total_bytes += size
        entries.append(generate_firewall_log(HOST_IPS["vm-app-01"], CAMPAIGN_IP, 443, "Allow", minutes_ago=ago, bytes_sent=size))
        entries.append(generate_endpoint_event("vm-app-01", "alice", "curl", "FileUploaded", minutes_ago=ago, file_size=size))
    client.post(f"{SIEM_URL}/ingest/batch", json={"entries": entries})
    print(f"  🔴 Injected data exfiltration: {count} uploads ({total_bytes/1e6:.0f} MB) to {CAMPAIGN_IP}")


def inject_phishing_campaign(client: httpx.Client):
    """Simulate phishing campaign targeting multiple users.

    The first recipient is the one the campaign lands on -- Defender blocks the rest.
    Fixed rather than random: 'Phishing email delivered' has to fire every run, and
    the delivered mail has to be the account the rest of the chain compromises.
    """
    entries = []
    targets = NORMAL_USERS[:4]
    for i, user in enumerate(targets):
        entries.append(generate_email_event(
            "security-alert@m1crosoft-support.com", user,
            "Urgent: Your account has been compromised - verify now",
            True, True, minutes_ago=T_PHISH - i * 0.1,
            delivered=(user == "alice@contoso.com"),
        ))
    client.post(f"{SIEM_URL}/ingest/batch", json={"entries": entries})
    print(f"  🔴 Injected phishing campaign: {len(targets)} emails from spoofed domain (1 delivered to alice@contoso.com)")


def setup_analytics_rules(client: httpx.Client):
    """Create detection rules in the SIEM."""
    rules = [
        {
            "name": "Brute force sign-in",
            "severity": "High",
            "tactic": "CredentialAccess",
            "query_table": "SigninLogs",
            "query_filter": {"ResultType": "Failure"},
            "aggregate_by": "UserPrincipalName",
            "threshold": 5,
            "window_minutes": 60,
            "description": "T1110 Brute Force - 5+ failed sign-ins for a single user in 1 hour. Threshold sits above the benign typo rate in this environment (max 4/user/hour).",
        },
        {
            "name": "Sign-in from suspicious location",
            "severity": "Medium",
            "tactic": "InitialAccess",
            "query_table": "SigninLogs",
            "query_filter": {"Location": "Moscow"},
            "threshold": 1,
            "window_minutes": 60,
            "description": "T1078 Valid Accounts - sign-in from a location this tenant never uses",
        },
        {
            "name": "Credential dumping tool executed",
            "severity": "High",
            "tactic": "CredentialAccess",
            "query_table": "DeviceEvents",
            "query_filter": {"FileName": "mimikatz.exe"},
            "threshold": 1,
            "window_minutes": 120,
            "description": "T1003 OS Credential Dumping - mimikatz on an endpoint. The observable is a process launch, but the TECHNIQUE is credential dumping, so the tactic is Credential Access (this is how Sentinel's own Mimikatz rules are tagged).",
        },
        {
            "name": "Lateral movement detected",
            "severity": "High",
            "tactic": "LateralMovement",
            "query_table": "DeviceEvents",
            "query_filter": {"ActionType": "RemoteExecution"},
            "aggregate_by": "AccountName",
            "threshold": 2,
            "window_minutes": 60,
            "description": "T1021 Remote Services - one account remote-executing on 2+ hosts in 1 hour",
        },
        {
            "name": "Phishing email delivered",
            "severity": "Medium",
            "tactic": "InitialAccess",
            "query_table": "EmailEvents",
            "query_filter": {"ThreatTypes": "Phish", "DeliveryAction": "Delivered"},
            "threshold": 1,
            "window_minutes": 120,
            "description": "T1566 Phishing - a phish that Defender for Office 365 did NOT block",
        },
        {
            "name": "Outbound traffic to known malicious IP",
            "severity": "High",
            "tactic": "Exfiltration",
            "query_table": "AzureFirewall",
            "query_filter": {"DestinationIP": CAMPAIGN_IP},
            "threshold": 3,
            "window_minutes": 60,
            "description": "T1041 Exfiltration Over C2 Channel - repeated egress to a threat-intel IP",
        },
    ]
    for rule in rules:
        r = client.post(f"{SIEM_URL}/rules", json=rule)
        print(f"  📋 Rule created: {rule['name']} ({rule['severity']})")


def setup_playbooks(client: httpx.Client):
    """Create automated response playbooks."""
    playbooks = [
        {
            "name": "Block compromised user",
            "trigger_severity": "High",
            "trigger_tactic": "CredentialAccess",
            "actions": [
                {"type": "disable_user", "description": "Disable user account in Entra ID"},
                {"type": "revoke_sessions", "description": "Revoke all active sessions"},
                {"type": "notify", "channel": "soc-team", "description": "Alert SOC team via Teams"},
            ],
        },
        {
            "name": "Isolate compromised endpoint",
            "trigger_severity": "High",
            "trigger_tactic": "LateralMovement",
            "actions": [
                {"type": "isolate_device", "description": "Network-isolate the device via Defender for Endpoint"},
                {"type": "collect_evidence", "description": "Trigger investigation package collection"},
                {"type": "notify", "channel": "soc-team", "description": "Alert SOC team"},
            ],
        },
        {
            "name": "Block exfiltration IP",
            "trigger_severity": "High",
            "trigger_tactic": "Exfiltration",
            "actions": [
                {"type": "block_ip", "description": "Add IP to Azure Firewall deny list"},
                {"type": "notify", "channel": "soc-lead", "description": "Escalate to SOC lead"},
            ],
        },
    ]
    for pb in playbooks:
        client.post(f"{SIEM_URL}/playbooks", json=pb)
        print(f"  🤖 Playbook created: {pb['name']}")


def main():
    print("⏳ Waiting for SIEM to start...")
    client = httpx.Client(timeout=10.0)
    for _ in range(30):
        try:
            r = client.get(f"{SIEM_URL}/health")
            if r.status_code == 200:
                break
        except Exception:
            pass
        time.sleep(2)

    print("\n=== Setting up analytics rules ===")
    setup_analytics_rules(client)

    print("\n=== Setting up playbooks ===")
    setup_playbooks(client)

    print("\n=== Generating log data ===")
    print("--- Normal traffic ---")
    inject_normal_traffic(client, count=30)

    print("--- Attack patterns ---")
    inject_brute_force(client, "alice@contoso.com", count=15)
    inject_lateral_movement(client)
    inject_data_exfiltration(client)
    inject_phishing_campaign(client)

    print("\n=== Running analytics rules ===")
    r = client.post(f"{SIEM_URL}/rules/evaluate")
    result = r.json()
    print(f"  Evaluated {result['evaluated']} rules, created {len(result['alerts_created'])} alerts")
    for a in result["alerts_created"]:
        print(f"    🚨 {a['rule']}: {a.get('group', '')} ({a['count']} events)")

    # Seeding is only useful if the seeded attack is actually DETECTABLE by the rules
    # the labs then reason about. Fail loudly here rather than handing the notebooks a
    # dataset in which half the detections quietly never fired.
    fired = {a["rule"] for a in result["alerts_created"]}
    expected = {
        "Brute force sign-in",
        "Sign-in from suspicious location",
        "Credential dumping tool executed",
        "Lateral movement detected",
        "Phishing email delivered",
        "Outbound traffic to known malicious IP",
    }
    missing = expected - fired
    assert not missing, f"seeded attack is not detectable by these rules: {sorted(missing)}"

    # ...and it must not fire on the benign population. Only alice should trip the
    # brute-force rule; the typo failures for everyone else must stay below threshold.
    brute_groups = {a["group"] for a in result["alerts_created"] if a["rule"] == "Brute force sign-in"}
    assert brute_groups == {"alice@contoso.com"}, (
        f"brute-force rule precision broken: expected only alice, got {sorted(brute_groups)}"
    )
    print(f"  ✅ all {len(expected)} seeded detections fired; brute force fired on alice only")

    print("\n=== Correlating alerts into incidents ===")
    r = client.post(f"{SIEM_URL}/incidents/correlate")
    result = r.json()
    for inc in result["incidents_created"]:
        print(f"  📋 {inc['incident_id']}: {inc['alert_count']} alerts, severity={inc['severity']}")

    print("\n=== Dashboard ===")
    dashboard = client.get(f"{SIEM_URL}/dashboard").json()
    print(f"  Logs: {dashboard['total_logs']}")
    print(f"  Tables: {dashboard['tables']}")
    print(f"  Active rules: {dashboard['active_rules']}")
    print(f"  Open alerts: {dashboard['open_alerts']}")
    print(f"  Open incidents: {dashboard['open_incidents']}")

    print("\n✅ SIEM ready for notebooks!")
    client.close()


if __name__ == "__main__":
    main()
