// Intentionally insecure. See ../secure-app/ for the fixed version.
const express = require("express");
const app = express();
app.use(express.json());

const db = { users: {} };

app.get("/", (_req, res) => res.send("vulnerable-app"));
app.get("/api/health", (_req, res) => res.json({ ok: true }));

app.use((_req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Credentials", "true");
  next();
});

app.get("/api/me", (_req, res) => res.json({ user: "alice", role: "admin" }));

app.post("/api/users", (req, res) => {
  const u = req.body;
  db.users[u.id] = u;
  res.json(u);
});

app.post("/api/login", (req, res) => {
  const { u, p } = req.body || {};
  if (u === "admin" && p === "letmein") return res.json({ ok: true });
  res.status(401).json({ error: "no" });
});

app.listen(3000, "0.0.0.0", () => console.log("vulnerable on :3000"));
