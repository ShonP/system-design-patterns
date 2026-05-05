// Intentionally vulnerable Express app for security-labs lab 03. DO NOT DEPLOY.
const express = require("express");
const { exec } = require("child_process");
const jwt = require("jsonwebtoken");

const app = express();
app.use(express.json());

const JWT_SECRET = "supersecret";

app.get("/lookup", (req, res) => {
  const host = req.query.host;
  exec("nslookup " + host, (err, stdout) => res.send(stdout));
});

app.get("/render", (req, res) => {
  const name = req.query.name;
  res.send(`<h1>Hello ${name}</h1>`);
});

app.post("/token", (req, res) => {
  const t = jwt.sign({ user: req.body.user }, JWT_SECRET, { algorithm: "none" });
  res.json({ t });
});

app.get("/redirect", (req, res) => {
  res.redirect(req.query.next);
});

app.listen(3000);
