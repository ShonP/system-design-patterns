"""Order Service — manages order data."""

from __future__ import annotations

from fastapi import FastAPI, HTTPException
from fastapi.responses import PlainTextResponse

app = FastAPI(title="Order Service", version="1.0.0")

ORDERS: dict[str, dict[str, object]] = {
    "o1": {"id": "o1", "user_id": "u1", "product": "Widget A", "amount": 29.99, "status": "shipped"},
    "o2": {"id": "o2", "user_id": "u2", "product": "Widget B", "amount": 49.99, "status": "pending"},
    "o3": {"id": "o3", "user_id": "u1", "product": "Widget C", "amount": 19.99, "status": "delivered"},
}


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok", "service": "order-service"}


@app.get("/orders")
async def list_orders() -> dict[str, object]:
    return {"orders": list(ORDERS.values()), "count": len(ORDERS)}


@app.get("/orders/{order_id}")
async def get_order(order_id: str) -> dict[str, object]:
    if order_id not in ORDERS:
        raise HTTPException(404, f"Order {order_id} not found")
    return ORDERS[order_id]


@app.get("/orders/user/{user_id}")
async def get_user_orders(user_id: str) -> dict[str, object]:
    user_orders = [o for o in ORDERS.values() if o["user_id"] == user_id]
    return {"orders": user_orders, "count": len(user_orders)}


# A bare `str` return value is serialised as JSON by FastAPI, which would emit
# "\"# HELP ...\\n...\"" -- not the Prometheus exposition format. PlainTextResponse
# is required for Prometheus to be able to scrape this endpoint at all.
@app.get("/metrics", response_class=PlainTextResponse)
async def metrics() -> str:
    lines = [
        "# HELP order_service_total_orders Total number of orders",
        "# TYPE order_service_total_orders gauge",
        f"order_service_total_orders {len(ORDERS)}",
        "# HELP order_service_requests_total Total requests served",
        "# TYPE order_service_requests_total counter",
        'order_service_requests_total{endpoint="/orders"} 0',
    ]
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8002)
