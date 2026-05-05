// Trivial TODO API — same source for insecure and secure builds.
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
app.listen(port, "0.0.0.0", () => console.log(`todo on :${port}`));
