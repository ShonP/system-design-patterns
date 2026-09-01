# Temporal worker (support code)

This is **not** a lab — it is the worker image used by the Temporal lab's
`docker-compose.yml`. Start it with the rest of the stack from the lab root:

```bash
cd ..                 # 03-technologies/workflow-engines/temporal
docker compose up -d --build --wait
```

| File | Role |
|------|------|
| `workflows.py` | Workflow definitions the worker registers |
| `activities.py` | Activity implementations those workflows call |
| `run_worker.py` | Entrypoint: connects to `temporal:7233` and polls `demo-task-queue` |
| `Dockerfile` | Image built by the `worker` service in the lab's compose file |
| `pyproject.toml` | Dependencies for the worker image only — the notebooks use the lab's own `.venv` |

A worker is a plain process that polls a task queue and runs your code. The
notebooks start their own in-process workers, so you can learn Temporal without
this container; it exists to show what a production-shaped deployment looks
like, where workers are deployed and scaled separately from the server.

Note the notebooks pass `workflow_runner=UnsandboxedWorkflowRunner()` because a
notebook's workflow code lives in `__main__`, which the sandbox cannot re-import.
This worker keeps the **default sandbox**, which is the right choice in
production — that is the difference worth noticing between the two.
