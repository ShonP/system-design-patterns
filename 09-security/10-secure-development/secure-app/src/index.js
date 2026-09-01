const express = require("express");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const { z } = require("zod");

const app = express();
app.disable("x-powered-by");
// Trust X-Forwarded-For ONLY when a proxy you control actually sets it. Turned on
// blindly, `req.ip` becomes whatever the client typed into a header, and every
// IP-keyed rate limit turns into a one-header bypass. See exercise 3.
if (process.env.TRUST_PROXY) app.set("trust proxy", Number(process.env.TRUST_PROXY));
app.use(express.json({ limit: "100kb" }));

app.use(
  helmet({
    contentSecurityPolicy: {
      useDefaults: true,
      directives: {
        "default-src": ["'self'"],
        "script-src":  ["'self'"],
        "img-src":     ["'self'", "data:"],
        "style-src":   ["'self'"],
        "object-src":  ["'none'"],
        "frame-ancestors": ["'none'"],
        "form-action": ["'self'"],
        "base-uri":    ["'self'"],
        "upgrade-insecure-requests": [],
      },
    },
    referrerPolicy: { policy: "strict-origin-when-cross-origin" },
    hsts: { maxAge: 31536000, includeSubDomains: true, preload: true },
    crossOriginOpenerPolicy: { policy: "same-origin" },
    crossOriginEmbedderPolicy: { policy: "require-corp" },
    crossOriginResourcePolicy: { policy: "same-origin" },
  }),
);

// helmet does not set Permissions-Policy (no stable cross-browser default), so it is
// on you. Deny the features this app never uses.
app.use((_req, res, next) => {
  res.setHeader(
    "Permissions-Policy",
    "camera=(), microphone=(), geolocation=(), payment=(), usb=(), interest-cohort=()",
  );
  next();
});

const allowedOrigins = (process.env.ALLOWED_ORIGINS || "")
  .split(",").map(s => s.trim()).filter(Boolean);

app.use((req, res, next) => {
  const origin = req.headers.origin;
  if (!origin) return next();
  if (!allowedOrigins.includes(origin)) {
    return res.status(403).json({ error: "origin not allowed" });
  }
  // Semgrep flags the echo as cors-misconfiguration. It is guarded by the allowlist
  // check immediately above, so this is a triaged false positive -- suppressed at the
  // site, with the reason, not silenced repo-wide.
  // nosemgrep: javascript.express.security.cors-misconfiguration.cors-misconfiguration
  res.setHeader("Access-Control-Allow-Origin", origin);
  res.setHeader("Vary", "Origin");
  res.setHeader("Access-Control-Allow-Credentials", "true");
  res.setHeader("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "content-type,authorization");
  if (req.method === "OPTIONS") return res.sendStatus(204);
  next();
});

const apiLimiter = rateLimit({ windowMs: 60_000, max: 60, standardHeaders: true, legacyHeaders: false });

// Two keys, because one is never enough. Per-IP stops one host hammering the endpoint;
// per-account stops a botnet spreading one account's guesses over thousands of IPs.
const authIpLimiter = rateLimit({ windowMs: 60_000, max: 5, standardHeaders: true, legacyHeaders: false });
const authUserLimiter = rateLimit({
  windowMs: 60_000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => `user:${String(req.body?.u ?? "").trim().toLowerCase()}`,
});

app.use("/api/", apiLimiter);

app.get("/", (_req, res) => res.send("secure-app"));
app.get("/api/health", (_req, res) => res.json({ ok: true }));
app.get("/api/me", (_req, res) => res.json({ user: "alice", role: "user" }));

const UserSchema = z.object({
  id:    z.string().uuid(),
  email: z.string().email().max(254),
  name:  z.string().min(1).max(100),
  role:  z.enum(["admin", "user"]),
}).strict();

const db = new Map();
app.post("/api/users", (req, res) => {
  const parsed = UserSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "validation", issues: parsed.error.issues });
  db.set(parsed.data.id, parsed.data);
  res.status(201).json(parsed.data);
});

const LoginSchema = z.object({
  u: z.string().min(1).max(100),
  p: z.string().min(1).max(200),
}).strict();

app.post("/api/login", authIpLimiter, authUserLimiter, (req, res) => {
  const parsed = LoginSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "validation" });
  return res.status(401).json({ error: "no" });
});

// Client errors carry their own status (body-parser's 413 for an oversized body, for
// one). Flattening everything to 500 hides the 413 and poisons your error budget with
// failures that were never yours.
app.use((err, _req, res, _next) => {
  const status = Number(err.status || err.statusCode) || 500;
  if (status >= 500) console.error(err);
  res.status(status).json({ error: status >= 500 ? "internal" : err.type || "bad request" });
});

const server = app.listen(3000, "0.0.0.0", () => console.log("secure on :3000"));
const shutdown = () => server.close(() => process.exit(0));
process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
