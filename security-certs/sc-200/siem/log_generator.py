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


def _utcnow():
    return datetime.now(timezone.utc).replace(tzinfo=None)

SIEM_URL = "http://siem:8000"
NORMAL_USERS = ["alice@contoso.com", "bob@contoso.com", "carol@contoso.com", "dave@contoso.com", "eve@contoso.com"]
ATTACKER = "attacker@evil.com"
NORMAL_IPS = ["10.0.1.10", "10.0.1.11", "10.0.1.12", "10.0.2.10", "10.0.2.11"]
SUSPICIOUS_IPS = ["185.220.101.42", "45.33.32.156", "198.51.100.99"]
INTERNAL_HOSTS = ["vm-web-01", "vm-app-01", "vm-db-01", "laptop-alice", "laptop-bob"]
APPS = ["Azure Portal", "Outlook", "Teams", "SharePoint", "Custom App"]
LOCATIONS = ["Seattle", "London", "New York", "Office"]
SUSPICIOUS_LOCATIONS = ["Moscow", "Beijing", "Anonymous Proxy"]


def now_iso():
    return _utcnow().isoformat() + "Z"


def past_iso(minutes_ago: int):
    return (_utcnow() - timedelta(minutes=minutes_ago)).isoformat() + "Z"


def generate_signin_log(user: str, success: bool, ip: str, location: str):
    return {
        "table_name": "SigninLogs",
        "timestamp": now_iso(),
        "data": {
            "UserPrincipalName": user,
            "IPAddress": ip,
            "Location": location,
            "ResultType": "Success" if success else "Failure",
            "AppDisplayName": random.choice(APPS),
            "DeviceDetail": random.choice(["Windows 11", "macOS", "iOS", "Linux"]),
            "RiskLevel": "none" if success else random.choice(["none", "low", "medium"]),
            "MFACompleted": success and random.random() > 0.2,
        },
    }


def generate_firewall_log(src_ip: str, dst_ip: str, dst_port: int, action: str):
    return {
        "table_name": "AzureFirewall",
        "timestamp": now_iso(),
        "data": {
            "SourceIP": src_ip,
            "DestinationIP": dst_ip,
            "DestinationPort": dst_port,
            "Protocol": "TCP",
            "Action": action,
            "Rule": f"rule-{random.randint(1,20)}",
        },
    }


def generate_endpoint_event(host: str, user: str, process: str, action: str):
    return {
        "table_name": "DeviceEvents",
        "timestamp": now_iso(),
        "data": {
            "DeviceName": host,
            "AccountName": user.split("@")[0],
            "FileName": process,
            "ActionType": action,
            "FolderPath": random.choice(["/usr/bin/", "C:\\Windows\\System32\\", "/tmp/", "C:\\Users\\Downloads\\"]),
        },
    }


def generate_email_event(sender: str, recipient: str, subject: str, has_attachment: bool, is_phish: bool):
    return {
        "table_name": "EmailEvents",
        "timestamp": now_iso(),
        "data": {
            "SenderFromAddress": sender,
            "RecipientEmailAddress": recipient,
            "Subject": subject,
            "AttachmentCount": 1 if has_attachment else 0,
            "ThreatTypes": "Phish" if is_phish else "",
            "DeliveryAction": "Blocked" if is_phish and random.random() > 0.3 else "Delivered",
            "UrlCount": random.randint(0, 3),
        },
    }


def inject_normal_traffic(client: httpx.Client, count: int = 20):
    """Generate normal-looking activity."""
    entries = []
    for _ in range(count):
        entries.append(generate_signin_log(random.choice(NORMAL_USERS), True, random.choice(NORMAL_IPS), random.choice(LOCATIONS)))
        entries.append(generate_firewall_log(random.choice(NORMAL_IPS), "10.0.3.50", random.choice([443, 80, 8080]), "Allow"))
        entries.append(generate_endpoint_event(random.choice(INTERNAL_HOSTS), random.choice(NORMAL_USERS), random.choice(["chrome.exe", "code", "python3", "outlook.exe"]), "ProcessCreated"))
        entries.append(generate_email_event("newsletter@service.com", random.choice(NORMAL_USERS), "Weekly update", False, False))
    client.post(f"{SIEM_URL}/ingest/batch", json={"entries": entries})
    print(f"  ✅ Injected {len(entries)} normal events")


def inject_brute_force(client: httpx.Client, target_user: str, count: int = 15):
    """Simulate brute force sign-in attack."""
    entries = []
    attacker_ip = random.choice(SUSPICIOUS_IPS)
    for _ in range(count):
        entries.append(generate_signin_log(target_user, False, attacker_ip, random.choice(SUSPICIOUS_LOCATIONS)))
    entries.append(generate_signin_log(target_user, True, attacker_ip, "Moscow"))
    client.post(f"{SIEM_URL}/ingest/batch", json={"entries": entries})
    print(f"  🔴 Injected brute force: {count} failures + 1 success for {target_user} from {attacker_ip}")


def inject_lateral_movement(client: httpx.Client):
    """Simulate lateral movement after compromise."""
    entries = []
    compromised_host = "laptop-alice"
    for target in ["vm-app-01", "vm-db-01", "vm-web-01"]:
        entries.append(generate_endpoint_event(compromised_host, "alice", "psexec.exe", "RemoteExecution"))
        entries.append(generate_firewall_log("10.0.1.10", "10.0.2.10", 445, "Allow"))
        entries.append(generate_endpoint_event(target, "alice", "cmd.exe", "ProcessCreated"))
        entries.append(generate_endpoint_event(target, "alice", "mimikatz.exe", "ProcessCreated"))
    client.post(f"{SIEM_URL}/ingest/batch", json={"entries": entries})
    print(f"  🔴 Injected lateral movement from {compromised_host} to 3 targets")


def inject_data_exfiltration(client: httpx.Client):
    """Simulate data exfiltration via large uploads."""
    entries = []
    for _ in range(10):
        entries.append(generate_firewall_log("10.0.2.10", random.choice(SUSPICIOUS_IPS), 443, "Allow"))
        entries.append(generate_endpoint_event("vm-app-01", "alice", "curl", "FileUploaded"))
    client.post(f"{SIEM_URL}/ingest/batch", json={"entries": entries})
    print(f"  🔴 Injected data exfiltration: 10 large uploads to external IPs")


def inject_phishing_campaign(client: httpx.Client):
    """Simulate phishing campaign targeting multiple users."""
    entries = []
    for user in NORMAL_USERS[:4]:
        entries.append(generate_email_event(
            "security-alert@m1crosoft-support.com", user,
            "Urgent: Your account has been compromised - verify now",
            True, True,
        ))
    client.post(f"{SIEM_URL}/ingest/batch", json={"entries": entries})
    print(f"  🔴 Injected phishing campaign: 4 emails from spoofed domain")


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
            "description": "Multiple failed sign-ins for a single user in 1 hour",
        },
        {
            "name": "Sign-in from suspicious location",
            "severity": "Medium",
            "tactic": "InitialAccess",
            "query_table": "SigninLogs",
            "query_filter": {"Location": "Moscow"},
            "threshold": 1,
            "window_minutes": 60,
        },
        {
            "name": "Suspicious process execution",
            "severity": "High",
            "tactic": "Execution",
            "query_table": "DeviceEvents",
            "query_filter": {"FileName": "mimikatz.exe"},
            "threshold": 1,
            "window_minutes": 120,
            "description": "Known attack tool detected on endpoint",
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
        },
        {
            "name": "Phishing email delivered",
            "severity": "Medium",
            "tactic": "InitialAccess",
            "query_table": "EmailEvents",
            "query_filter": {"ThreatTypes": "Phish", "DeliveryAction": "Delivered"},
            "threshold": 1,
            "window_minutes": 120,
        },
        {
            "name": "Outbound traffic to known malicious IP",
            "severity": "High",
            "tactic": "Exfiltration",
            "query_table": "AzureFirewall",
            "query_filter": {"DestinationIP": "185.220.101.42"},
            "threshold": 3,
            "window_minutes": 60,
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
