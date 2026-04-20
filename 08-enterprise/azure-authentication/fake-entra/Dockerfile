FROM python:3.12-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv
WORKDIR /app
COPY pyproject.toml .
RUN uv pip install --system --no-cache -r pyproject.toml
COPY fake-entra/server.py ./server.py
COPY fake-entra/apps.json ./apps.json
EXPOSE 9100
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "9100"]
