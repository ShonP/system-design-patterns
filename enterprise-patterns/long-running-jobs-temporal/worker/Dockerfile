FROM python:3.11-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

WORKDIR /app

COPY pyproject.toml .
RUN uv pip install --system --no-cache -r pyproject.toml

COPY . .

# Wait a few seconds for Temporal to be fully ready, then start the worker.
# In production you'd use a proper health-check loop instead of sleep.
CMD ["sh", "-c", "sleep 5 && python run_worker.py"]
