"""User Service — manages user data."""

from __future__ import annotations

from fastapi import FastAPI, HTTPException
from fastapi.responses import PlainTextResponse

app = FastAPI(title="User Service", version="1.0.0")

USERS: dict[str, dict[str, str]] = {
    "u1": {"id": "u1", "name": "Alice", "email": "alice@example.com", "role": "admin"},
    "u2": {"id": "u2", "name": "Bob", "email": "bob@example.com", "role": "user"},
    "u3": {"id": "u3", "name": "Charlie", "email": "charlie@example.com", "role": "user"},
}


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok", "service": "user-service"}


@app.get("/users")
async def list_users() -> dict[str, object]:
    return {"users": list(USERS.values()), "count": len(USERS)}


@app.get("/users/{user_id}")
async def get_user(user_id: str) -> dict[str, str]:
    if user_id not in USERS:
        raise HTTPException(404, f"User {user_id} not found")
    return USERS[user_id]


# A bare `str` return value is serialised as JSON by FastAPI, which would emit
# "\"# HELP ...\\n...\"" -- not the Prometheus exposition format. PlainTextResponse
# is required for Prometheus to be able to scrape this endpoint at all.
@app.get("/metrics", response_class=PlainTextResponse)
async def metrics() -> str:
    lines = [
        "# HELP user_service_total_users Total number of users",
        "# TYPE user_service_total_users gauge",
        f"user_service_total_users {len(USERS)}",
        "# HELP user_service_requests_total Total requests served",
        "# TYPE user_service_requests_total counter",
        'user_service_requests_total{endpoint="/users"} 0',
    ]
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8001)
