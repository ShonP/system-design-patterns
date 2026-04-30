# Lab 07: Dashboard & Monitoring — Observing Your Cluster

📖 **What you'll learn**: How to add the Orleans Dashboard for development-time visibility into silo state, grain activations, and method call metrics.

## How to Run

```bash
dotnet run
```

Then open: http://localhost:5000/dashboard

## Key Concepts

- **Dashboard**: A development UI for watching activity inside your Orleans silo.
- **Health checks**: Lightweight endpoints to confirm the app is alive.
- **Grain statistics**: Activation counts, call counts, and per-grain activity.
- **Silo diagnostics**: Runtime-level visibility into the Orleans host.

## Architecture

```text
Browser ──▶ ASP.NET Core app ──▶ Orleans silo ──▶ Dashboard metrics + grain activity
```

Use `POST /activate/{count}` to create grain activity so the dashboard has something interesting to show.

## Production Note

In production, use **OpenTelemetry + Prometheus + Grafana** instead of relying on the development dashboard alone.
