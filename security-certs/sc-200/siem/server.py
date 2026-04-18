"""
Mini-SIEM Engine — implements core Sentinel concepts:
    - Log ingestion via REST API (like data connectors)
    - Tables stored in SQLite (like Log Analytics workspace)
    - Query engine with filtering, aggregation, time windows
    - Analytics rules that run on schedule and fire alerts
    - Alert correlation into incidents
    - Automated playbook triggers
"""
import json
import sqlite3
import time
import threading
import uuid
from datetime import datetime, timedelta
from typing import Any

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

DB_PATH = "/data/siem.db"
app = FastAPI(title="Mini-SIEM (Sentinel-like)")

_lock = threading.Lock()


def _db() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    return conn


def _init_db():
    conn = _db()
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            table_name TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            data JSON NOT NULL,
            ingested_at TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS analytics_rules (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            severity TEXT NOT NULL DEFAULT 'Medium',
            tactic TEXT,
            query_table TEXT NOT NULL,
            query_filter JSON,
            aggregate_by TEXT,
            threshold INTEGER DEFAULT 1,
            window_minutes INTEGER DEFAULT 60,
            enabled INTEGER DEFAULT 1,
            description TEXT
        );

        CREATE TABLE IF NOT EXISTS alerts (
            id TEXT PRIMARY KEY,
            rule_id TEXT NOT NULL,
            rule_name TEXT NOT NULL,
            severity TEXT NOT NULL,
            tactic TEXT,
            title TEXT NOT NULL,
            description TEXT,
            entities JSON,
            evidence JSON,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            status TEXT NOT NULL DEFAULT 'New'
        );

        CREATE TABLE IF NOT EXISTS incidents (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            severity TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'New',
            alert_ids JSON NOT NULL,
            entities JSON,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at TEXT NOT NULL DEFAULT (datetime('now')),
            assigned_to TEXT,
            classification TEXT,
            comments JSON DEFAULT '[]'
        );

        CREATE TABLE IF NOT EXISTS playbooks (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            trigger_severity TEXT,
            trigger_tactic TEXT,
            actions JSON NOT NULL,
            enabled INTEGER DEFAULT 1
        );

        CREATE TABLE IF NOT EXISTS playbook_runs (
            id TEXT PRIMARY KEY,
            playbook_id TEXT NOT NULL,
            incident_id TEXT,
            alert_id TEXT,
            actions_executed JSON,
            status TEXT NOT NULL DEFAULT 'Completed',
            run_at TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE INDEX IF NOT EXISTS idx_logs_table ON logs(table_name);
        CREATE INDEX IF NOT EXISTS idx_logs_ts ON logs(timestamp);
        CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts(status);
        CREATE INDEX IF NOT EXISTS idx_incidents_status ON incidents(status);
    """)
    conn.close()


_init_db()


# ---------------------------------------------------------------------------
# Models
# ---------------------------------------------------------------------------
class LogEntry(BaseModel):
    table_name: str
    timestamp: str | None = None
    data: dict[str, Any]


class LogBatch(BaseModel):
    entries: list[LogEntry]


class AnalyticsRule(BaseModel):
    name: str
    severity: str = "Medium"
    tactic: str | None = None
    query_table: str
    query_filter: dict[str, Any] | None = None
    aggregate_by: str | None = None
    threshold: int = 1
    window_minutes: int = 60
    description: str | None = None


class QueryRequest(BaseModel):
    table_name: str
    filter: dict[str, Any] | None = None
    time_range_minutes: int | None = None
    aggregate_by: str | None = None
    order_by: str | None = "timestamp"
    limit: int = 100


class Playbook(BaseModel):
    name: str
    trigger_severity: str | None = None
    trigger_tactic: str | None = None
    actions: list[dict[str, Any]]


class IncidentUpdate(BaseModel):
    status: str | None = None
    assigned_to: str | None = None
    classification: str | None = None
    comment: str | None = None


# ---------------------------------------------------------------------------
# Health
# ---------------------------------------------------------------------------
@app.get("/health")
def health():
    conn = _db()
    stats = {}
    for table in ["logs", "analytics_rules", "alerts", "incidents", "playbooks"]:
        stats[table] = conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
    conn.close()
    return {"status": "ok", "service": "mini-siem", "counts": stats}


# ---------------------------------------------------------------------------
# Log ingestion (Data Connectors)
# ---------------------------------------------------------------------------
@app.post("/ingest")
def ingest_log(entry: LogEntry):
    ts = entry.timestamp or datetime.utcnow().isoformat()
    conn = _db()
    conn.execute(
        "INSERT INTO logs (table_name, timestamp, data) VALUES (?, ?, ?)",
        (entry.table_name, ts, json.dumps(entry.data)),
    )
    conn.commit()
    conn.close()
    return {"status": "ingested", "table": entry.table_name}


@app.post("/ingest/batch")
def ingest_batch(batch: LogBatch):
    conn = _db()
    for entry in batch.entries:
        ts = entry.timestamp or datetime.utcnow().isoformat()
        conn.execute(
            "INSERT INTO logs (table_name, timestamp, data) VALUES (?, ?, ?)",
            (entry.table_name, ts, json.dumps(entry.data)),
        )
    conn.commit()
    conn.close()
    return {"status": "ingested", "count": len(batch.entries)}


# ---------------------------------------------------------------------------
# Query engine (KQL-like)
# ---------------------------------------------------------------------------
@app.post("/query")
def query_logs(req: QueryRequest):
    conn = _db()
    sql = "SELECT timestamp, data FROM logs WHERE table_name = ?"
    params: list[Any] = [req.table_name]

    if req.time_range_minutes:
        cutoff = (datetime.utcnow() - timedelta(minutes=req.time_range_minutes)).isoformat()
        sql += " AND timestamp >= ?"
        params.append(cutoff)

    if req.filter:
        for key, value in req.filter.items():
            sql += f" AND json_extract(data, '$.{key}') = ?"
            params.append(value)

    if req.aggregate_by:
        agg_field = req.aggregate_by
        sql = f"""
            SELECT json_extract(data, '$.{agg_field}') as group_key,
                   COUNT(*) as count,
                   MIN(timestamp) as first_seen,
                   MAX(timestamp) as last_seen
            FROM logs WHERE table_name = ?
        """
        params_agg = [req.table_name]
        if req.time_range_minutes:
            cutoff = (datetime.utcnow() - timedelta(minutes=req.time_range_minutes)).isoformat()
            sql += " AND timestamp >= ?"
            params_agg.append(cutoff)
        if req.filter:
            for key, value in req.filter.items():
                sql += f" AND json_extract(data, '$.{key}') = ?"
                params_agg.append(value)
        sql += f" GROUP BY group_key ORDER BY count DESC LIMIT ?"
        params_agg.append(req.limit)
        rows = conn.execute(sql, params_agg).fetchall()
        conn.close()
        return {"table": req.table_name, "aggregation": agg_field, "results": [dict(r) for r in rows]}

    sql += f" ORDER BY timestamp DESC LIMIT ?"
    params.append(req.limit)
    rows = conn.execute(sql, params).fetchall()
    conn.close()
    results = [{"timestamp": r["timestamp"], **json.loads(r["data"])} for r in rows]
    return {"table": req.table_name, "count": len(results), "results": results}


# ---------------------------------------------------------------------------
# Analytics rules (Detection)
# ---------------------------------------------------------------------------
@app.post("/rules")
def create_rule(rule: AnalyticsRule):
    rule_id = str(uuid.uuid4())[:8]
    conn = _db()
    conn.execute(
        "INSERT INTO analytics_rules (id, name, severity, tactic, query_table, query_filter, aggregate_by, threshold, window_minutes, description) VALUES (?,?,?,?,?,?,?,?,?,?)",
        (rule_id, rule.name, rule.severity, rule.tactic, rule.query_table,
         json.dumps(rule.query_filter) if rule.query_filter else None,
         rule.aggregate_by, rule.threshold, rule.window_minutes, rule.description),
    )
    conn.commit()
    conn.close()
    return {"id": rule_id, "name": rule.name, "status": "created"}


@app.get("/rules")
def list_rules():
    conn = _db()
    rows = conn.execute("SELECT * FROM analytics_rules").fetchall()
    conn.close()
    return [dict(r) for r in rows]


@app.post("/rules/evaluate")
def evaluate_all_rules():
    """Run all enabled analytics rules and generate alerts."""
    conn = _db()
    rules = conn.execute("SELECT * FROM analytics_rules WHERE enabled = 1").fetchall()
    alerts_created = []

    for rule in rules:
        cutoff = (datetime.utcnow() - timedelta(minutes=rule["window_minutes"])).isoformat()
        sql = "SELECT data, timestamp FROM logs WHERE table_name = ? AND timestamp >= ?"
        params: list[Any] = [rule["query_table"], cutoff]

        if rule["query_filter"]:
            for key, value in json.loads(rule["query_filter"]).items():
                sql += f" AND json_extract(data, '$.{key}') = ?"
                params.append(value)

        rows = conn.execute(sql, params).fetchall()

        if rule["aggregate_by"]:
            groups: dict[str, list] = {}
            for r in rows:
                d = json.loads(r["data"])
                gk = d.get(rule["aggregate_by"], "unknown")
                groups.setdefault(gk, []).append(d)

            for group_key, items in groups.items():
                if len(items) >= rule["threshold"]:
                    alert_id = str(uuid.uuid4())[:8]
                    conn.execute(
                        "INSERT INTO alerts (id, rule_id, rule_name, severity, tactic, title, description, entities, evidence) VALUES (?,?,?,?,?,?,?,?,?)",
                        (alert_id, rule["id"], rule["name"], rule["severity"], rule["tactic"],
                         f'{rule["name"]}: {group_key} ({len(items)} events)',
                         rule["description"],
                         json.dumps({rule["aggregate_by"]: group_key}),
                         json.dumps(items[:5])),
                    )
                    alerts_created.append({"alert_id": alert_id, "rule": rule["name"], "group": group_key, "count": len(items)})
        else:
            if len(rows) >= rule["threshold"]:
                alert_id = str(uuid.uuid4())[:8]
                evidence = [json.loads(r["data"]) for r in rows[:5]]
                conn.execute(
                    "INSERT INTO alerts (id, rule_id, rule_name, severity, tactic, title, description, entities, evidence) VALUES (?,?,?,?,?,?,?,?,?)",
                    (alert_id, rule["id"], rule["name"], rule["severity"], rule["tactic"],
                     f'{rule["name"]} ({len(rows)} events)',
                     rule["description"], json.dumps({}), json.dumps(evidence)),
                )
                alerts_created.append({"alert_id": alert_id, "rule": rule["name"], "count": len(rows)})

    conn.commit()
    conn.close()
    return {"evaluated": len(rules), "alerts_created": alerts_created}


# ---------------------------------------------------------------------------
# Alerts
# ---------------------------------------------------------------------------
@app.get("/alerts")
def list_alerts(status: str | None = None):
    conn = _db()
    sql = "SELECT * FROM alerts"
    params = []
    if status:
        sql += " WHERE status = ?"
        params.append(status)
    sql += " ORDER BY created_at DESC"
    rows = conn.execute(sql, params).fetchall()
    conn.close()
    return [dict(r) for r in rows]


# ---------------------------------------------------------------------------
# Incidents (Alert correlation)
# ---------------------------------------------------------------------------
@app.post("/incidents/correlate")
def correlate_alerts():
    """Group new alerts into incidents by entity overlap."""
    conn = _db()
    new_alerts = conn.execute("SELECT * FROM alerts WHERE status = 'New' ORDER BY created_at").fetchall()

    entity_groups: dict[str, list] = {}
    for alert in new_alerts:
        entities = json.loads(alert["entities"]) if alert["entities"] else {}
        key = json.dumps(entities, sort_keys=True) if entities else alert["id"]
        entity_groups.setdefault(key, []).append(dict(alert))

    incidents_created = []
    for entity_key, grouped_alerts in entity_groups.items():
        alert_ids = [a["id"] for a in grouped_alerts]
        severities = [a["severity"] for a in grouped_alerts]
        sev_order = {"Critical": 4, "High": 3, "Medium": 2, "Low": 1, "Informational": 0}
        max_sev = max(severities, key=lambda s: sev_order.get(s, 0))

        entities = json.loads(grouped_alerts[0]["entities"]) if grouped_alerts[0]["entities"] else {}
        entity_desc = ", ".join(f"{k}={v}" for k, v in entities.items()) if entities else "multiple"

        incident_id = f"INC-{str(uuid.uuid4())[:6]}"
        conn.execute(
            "INSERT INTO incidents (id, title, severity, alert_ids, entities) VALUES (?,?,?,?,?)",
            (incident_id,
             f"Incident: {grouped_alerts[0]['rule_name']} ({entity_desc})",
             max_sev,
             json.dumps(alert_ids),
             json.dumps(entities)),
        )
        for aid in alert_ids:
            conn.execute("UPDATE alerts SET status = 'InIncident' WHERE id = ?", (aid,))

        incidents_created.append({"incident_id": incident_id, "alert_count": len(alert_ids), "severity": max_sev})

    conn.commit()
    conn.close()
    return {"incidents_created": incidents_created}


@app.get("/incidents")
def list_incidents(status: str | None = None):
    conn = _db()
    sql = "SELECT * FROM incidents"
    params = []
    if status:
        sql += " WHERE status = ?"
        params.append(status)
    sql += " ORDER BY created_at DESC"
    rows = conn.execute(sql, params).fetchall()
    conn.close()
    return [dict(r) for r in rows]


@app.get("/incidents/{incident_id}")
def get_incident(incident_id: str):
    conn = _db()
    inc = conn.execute("SELECT * FROM incidents WHERE id = ?", (incident_id,)).fetchone()
    if not inc:
        conn.close()
        raise HTTPException(404, "Incident not found")
    inc = dict(inc)
    alert_ids = json.loads(inc["alert_ids"])
    placeholders = ",".join("?" * len(alert_ids))
    alerts = conn.execute(f"SELECT * FROM alerts WHERE id IN ({placeholders})", alert_ids).fetchall()
    conn.close()
    inc["alerts"] = [dict(a) for a in alerts]
    return inc


@app.patch("/incidents/{incident_id}")
def update_incident(incident_id: str, update: IncidentUpdate):
    conn = _db()
    inc = conn.execute("SELECT * FROM incidents WHERE id = ?", (incident_id,)).fetchone()
    if not inc:
        conn.close()
        raise HTTPException(404, "Incident not found")

    if update.status:
        conn.execute("UPDATE incidents SET status = ?, updated_at = datetime('now') WHERE id = ?", (update.status, incident_id))
    if update.assigned_to:
        conn.execute("UPDATE incidents SET assigned_to = ?, updated_at = datetime('now') WHERE id = ?", (update.assigned_to, incident_id))
    if update.classification:
        conn.execute("UPDATE incidents SET classification = ?, updated_at = datetime('now') WHERE id = ?", (update.classification, incident_id))
    if update.comment:
        comments = json.loads(inc["comments"] or "[]")
        comments.append({"text": update.comment, "time": datetime.utcnow().isoformat()})
        conn.execute("UPDATE incidents SET comments = ?, updated_at = datetime('now') WHERE id = ?", (json.dumps(comments), incident_id))

    conn.commit()
    conn.close()
    return {"status": "updated", "incident_id": incident_id}


# ---------------------------------------------------------------------------
# Playbooks (Automation)
# ---------------------------------------------------------------------------
@app.post("/playbooks")
def create_playbook(pb: Playbook):
    pb_id = str(uuid.uuid4())[:8]
    conn = _db()
    conn.execute(
        "INSERT INTO playbooks (id, name, trigger_severity, trigger_tactic, actions) VALUES (?,?,?,?,?)",
        (pb_id, pb.name, pb.trigger_severity, pb.trigger_tactic, json.dumps(pb.actions)),
    )
    conn.commit()
    conn.close()
    return {"id": pb_id, "name": pb.name}


@app.get("/playbooks")
def list_playbooks():
    conn = _db()
    rows = conn.execute("SELECT * FROM playbooks WHERE enabled = 1").fetchall()
    conn.close()
    return [dict(r) for r in rows]


@app.post("/playbooks/run/{incident_id}")
def run_playbooks_for_incident(incident_id: str):
    """Find matching playbooks for an incident and execute them."""
    conn = _db()
    inc = conn.execute("SELECT * FROM incidents WHERE id = ?", (incident_id,)).fetchone()
    if not inc:
        conn.close()
        raise HTTPException(404, "Incident not found")

    alert_ids = json.loads(inc["alert_ids"])
    placeholders = ",".join("?" * len(alert_ids))
    alerts = conn.execute(f"SELECT * FROM alerts WHERE id IN ({placeholders})", alert_ids).fetchall()
    tactics = list({a["tactic"] for a in alerts if a["tactic"]})

    playbooks = conn.execute("SELECT * FROM playbooks WHERE enabled = 1").fetchall()
    runs = []
    for pb in playbooks:
        sev_match = not pb["trigger_severity"] or pb["trigger_severity"] == inc["severity"]
        tac_match = not pb["trigger_tactic"] or pb["trigger_tactic"] in tactics
        if sev_match and tac_match:
            actions = json.loads(pb["actions"])
            run_id = str(uuid.uuid4())[:8]
            conn.execute(
                "INSERT INTO playbook_runs (id, playbook_id, incident_id, actions_executed, status) VALUES (?,?,?,?,?)",
                (run_id, pb["id"], incident_id, json.dumps(actions), "Completed"),
            )
            runs.append({"playbook": pb["name"], "run_id": run_id, "actions": actions})

    conn.commit()
    conn.close()
    return {"incident_id": incident_id, "playbooks_executed": runs}


# ---------------------------------------------------------------------------
# Dashboard
# ---------------------------------------------------------------------------
@app.get("/dashboard")
def dashboard():
    conn = _db()
    stats = {
        "total_logs": conn.execute("SELECT COUNT(*) FROM logs").fetchone()[0],
        "tables": [r[0] for r in conn.execute("SELECT DISTINCT table_name FROM logs").fetchall()],
        "active_rules": conn.execute("SELECT COUNT(*) FROM analytics_rules WHERE enabled=1").fetchone()[0],
        "open_alerts": conn.execute("SELECT COUNT(*) FROM alerts WHERE status='New'").fetchone()[0],
        "open_incidents": conn.execute("SELECT COUNT(*) FROM incidents WHERE status IN ('New','Active')").fetchone()[0],
        "severity_breakdown": {},
    }
    for row in conn.execute("SELECT severity, COUNT(*) as c FROM incidents GROUP BY severity"):
        stats["severity_breakdown"][row[0]] = row[1]
    conn.close()
    return stats
