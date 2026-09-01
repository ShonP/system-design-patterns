// Intentionally insecure. See ../secure-app/ for the fixed version.
const express = require("express");
const _ = require("lodash");           // 4.17.4 -- prototype pollution in _.merge (CVE-2018-3721)
const app = express();
app.use(express.json());

const db = { users: {} };

app.get("/", (_req, res) => res.send("vulnerable-app"));
app.get("/api/health", (_req, res) => res.json({ ok: true }));

app.use((req, res, next) => {
  // VULN: reflects whatever Origin the caller sent (falling back to a wide-open "*"),
  // allows credentials, and never sets Vary. Any site can read this response as you.
  res.header("Access-Control-Allow-Origin", req.headers.origin || "*");
  res.header("Access-Control-Allow-Credentials", "true");
  next();
});

app.get("/api/me", (_req, res) => res.json({ user: "alice", role: "admin" }));

app.post("/api/users", (req, res) => {
  const u = req.body;
  // VULN: no schema, no length limits, and a deep merge with a vulnerable lodash.
  // The merge is what turns "weird input" into "attacker writes Object.prototype".
  db.users[u.id] = _.merge({}, u);
  res.json(u);
});

// Reports whether Object.prototype has been polluted. Nothing sets this property; if it
// ever returns true, someone else wrote to every object in the process.
app.get("/api/canary", (_req, res) => res.json({ polluted: {}.polluted === true }));

app.post("/api/login", (req, res) => {
  const { u, p } = req.body || {};
  if (u === "admin" && p === "letmein") return res.json({ ok: true });
  res.status(401).json({ error: "no" });
});

app.listen(3000, "0.0.0.0", () => console.log("vulnerable on :3000"));
