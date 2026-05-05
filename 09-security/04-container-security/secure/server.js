// Same source as insecure/server.js — only the Dockerfile differs.
const express = require("express");
const app = express();
app.use(express.json());

const todos = [];
app.get("/todos", (_req, res) => res.json(todos));
app.post("/todos", (req, res) => {
  const t = { id: todos.length + 1, text: String(req.body.text || "") };
  todos.push(t);
  res.status(201).json(t);
});
app.get("/health", (_req, res) => res.json({ ok: true }));

const port = process.env.PORT || 3000;
const server = app.listen(port, "0.0.0.0", () => console.log(`todo on :${port}`));

const shutdown = () => server.close(() => process.exit(0));
process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
