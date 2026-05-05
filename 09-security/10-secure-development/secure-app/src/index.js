const express = require("express");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const { z } = require("zod");

const app = express();
app.disable("x-powered-by");
app.set("trust proxy", 1);
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

const allowedOrigins = (process.env.ALLOWED_ORIGINS || "")
  .split(",").map(s => s.trim()).filter(Boolean);

app.use((req, res, next) => {
  const origin = req.headers.origin;
  if (!origin) return next();
  if (!allowedOrigins.includes(origin)) {
    return res.status(403).json({ error: "origin not allowed" });
  }
  res.setHeader("Access-Control-Allow-Origin", origin);
  res.setHeader("Vary", "Origin");
  res.setHeader("Access-Control-Allow-Credentials", "true");
  res.setHeader("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "content-type,authorization");
  if (req.method === "OPTIONS") return res.sendStatus(204);
  next();
});

const apiLimiter  = rateLimit({ windowMs: 60_000, max: 60, standardHeaders: true, legacyHeaders: false });
const authLimiter = rateLimit({ windowMs: 60_000, max:  5, standardHeaders: true, legacyHeaders: false });
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

app.post("/api/login", authLimiter, (req, res) => {
  const parsed = LoginSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: "validation" });
  return res.status(401).json({ error: "no" });
});

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: "internal" });
});

const server = app.listen(3000, "0.0.0.0", () => console.log("secure on :3000"));
const shutdown = () => server.close(() => process.exit(0));
process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
