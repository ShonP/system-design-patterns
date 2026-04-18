"""
API Design Lab — FastAPI Server

A small event-ticketing API that demonstrates REST design principles,
pagination, rate limiting, and versioning.  Used by the Jupyter notebooks
in this lab.
"""

import os
import time
from typing import Optional

import psycopg2
import psycopg2.extras
from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel

# Deprecation headers attached to every /v1/* response. These follow the
# IETF "Deprecation" and "Sunset" HTTP header conventions — clients can
# detect them and warn developers to migrate.
V1_DEPRECATION_HEADERS = {
    "Deprecation": "true",
    "Sunset": "Wed, 01 Jan 2025 00:00:00 GMT",
    "Link": '</v2/events>; rel="successor-version"',
}

# ---------------------------------------------------------------------------
# App setup
# ---------------------------------------------------------------------------

app = FastAPI(title="Event Ticketing API", version="2.0.0")


@app.middleware("http")
async def attach_v1_deprecation_headers(request: Request, call_next):
    """Tag every response from /v1/* with standard deprecation headers.

    Well-designed HTTP clients read these and log a migration warning
    instead of surprising developers when V1 is eventually retired.
    """
    response = await call_next(request)
    if request.url.path.startswith("/v1/"):
        for k, v in V1_DEPRECATION_HEADERS.items():
            response.headers[k] = v
    return response

DATABASE_URL = os.getenv(
    "DATABASE_URL", "postgresql://demo:demo@localhost:5432/api_design_demo"
)


def get_db():
    """Return a new database connection."""
    return psycopg2.connect(DATABASE_URL, cursor_factory=psycopg2.extras.RealDictCursor)


# ---------------------------------------------------------------------------
# Pydantic models (request / response schemas)
# ---------------------------------------------------------------------------

class EventCreate(BaseModel):
    title: str
    description: Optional[str] = None
    venue_id: int
    event_date: str
    price: float
    total_tickets: int
    category: Optional[str] = None


class BookingCreate(BaseModel):
    user_id: int
    quantity: int


class EventUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    category: Optional[str] = None


# ---------------------------------------------------------------------------
# In-memory rate-limiter (simple fixed-window for demo)
# ---------------------------------------------------------------------------

# { client_ip: [timestamp, timestamp, ...] }
rate_limit_store: dict[str, list[float]] = {}

RATE_LIMIT = 10          # max requests
RATE_WINDOW = 60         # per 60 seconds


def check_rate_limit(client_id: str) -> tuple[bool, dict]:
    """Return (allowed, info_dict)."""
    now = time.time()
    window_start = now - RATE_WINDOW

    hits = rate_limit_store.setdefault(client_id, [])
    # prune old entries
    hits[:] = [t for t in hits if t > window_start]
    remaining = RATE_LIMIT - len(hits)
    reset_ts = int(window_start + RATE_WINDOW)

    if remaining <= 0:
        # Retry-After is the standard IETF header (RFC 6585). Seconds until
        # the client is allowed to retry.  It is the one header well-behaved
        # HTTP clients (and proxies) already know how to respect.
        retry_after = max(1, reset_ts - int(now))
        return False, {
            "X-RateLimit-Limit": str(RATE_LIMIT),
            "X-RateLimit-Remaining": "0",
            "X-RateLimit-Reset": str(reset_ts),
            "Retry-After": str(retry_after),
        }

    hits.append(now)
    return True, {
        "X-RateLimit-Limit": str(RATE_LIMIT),
        "X-RateLimit-Remaining": str(remaining - 1),
        "X-RateLimit-Reset": str(reset_ts),
    }


# ---------------------------------------------------------------------------
# Rate-limited endpoint (opt-in via /limited prefix)
# ---------------------------------------------------------------------------

@app.get("/limited/events")
def list_events_rate_limited(request: Request):
    """Same as GET /events but with rate limiting enforced.

    If the caller sends an ``X-API-Key`` header, the limiter counts per API
    key (so two different keys from the same IP each get their own quota).
    Otherwise it falls back to the client IP — which is what most public APIs
    do for anonymous traffic.
    """
    api_key = request.headers.get("x-api-key")
    if api_key:
        client_id = f"key:{api_key}"
    else:
        client_id = f"ip:{request.client.host}" if request.client else "ip:unknown"
    allowed, headers = check_rate_limit(client_id)
    if not allowed:
        return JSONResponse(
            status_code=429,
            content={"detail": "Too Many Requests"},
            headers=headers,
        )

    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT id, title, category FROM events ORDER BY id LIMIT 10")
    rows = cur.fetchall()
    conn.close()
    return JSONResponse(content={"events": [dict(r) for r in rows]}, headers=headers)


@app.post("/limited/reset")
def reset_rate_limits():
    """Reset all rate-limit counters (for notebook demos)."""
    rate_limit_store.clear()
    return {"detail": "Rate limits reset"}


# ---------------------------------------------------------------------------
# V1 API — flat event structure
# ---------------------------------------------------------------------------

@app.get("/v1/events")
def list_events_v1(
    offset: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    category: Optional[str] = None,
):
    """V1: Returns events as a flat list (no nested venue)."""
    conn = get_db()
    cur = conn.cursor()
    where = ""
    params: list = []
    if category:
        where = "WHERE e.category = %s"
        params.append(category)

    cur.execute(
        f"""
        SELECT e.id, e.title, e.description, e.venue_id, e.event_date::text,
               e.price, e.total_tickets, e.tickets_sold, e.category
        FROM events e {where}
        ORDER BY e.id
        OFFSET %s LIMIT %s
        """,
        params + [offset, limit],
    )
    rows = cur.fetchall()

    cur.execute(f"SELECT count(*) AS total FROM events e {where}", params or [])
    total = cur.fetchone()["total"]
    conn.close()

    return {
        "api_version": "v1",
        "events": [dict(r) for r in rows],
        "pagination": {
            "offset": offset,
            "limit": limit,
            "total": total,
        },
    }


@app.get("/v1/events/{event_id}")
def get_event_v1(event_id: int):
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        """SELECT id, title, description, venue_id, event_date::text,
                  price, total_tickets, tickets_sold, category
           FROM events WHERE id = %s""",
        (event_id,),
    )
    row = cur.fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Event not found")
    return {"api_version": "v1", "event": dict(row)}


# ---------------------------------------------------------------------------
# V2 API — nested venue, cursor pagination
# ---------------------------------------------------------------------------

@app.get("/v2/events")
def list_events_v2(
    cursor: Optional[int] = None,
    limit: int = Query(10, ge=1, le=100),
    category: Optional[str] = None,
):
    """V2: Returns events with nested venue, uses cursor pagination."""
    conn = get_db()
    cur = conn.cursor()

    conditions = []
    params: list = []
    if cursor:
        conditions.append("e.id > %s")
        params.append(cursor)
    if category:
        conditions.append("e.category = %s")
        params.append(category)

    where = ("WHERE " + " AND ".join(conditions)) if conditions else ""

    cur.execute(
        f"""
        SELECT e.id, e.title, e.description, e.event_date::text,
               e.price, e.total_tickets, e.tickets_sold, e.category,
               v.id AS venue_id, v.name AS venue_name, v.city AS venue_city,
               v.capacity AS venue_capacity
        FROM events e
        JOIN venues v ON e.venue_id = v.id
        {where}
        ORDER BY e.id
        LIMIT %s
        """,
        params + [limit],
    )
    rows = cur.fetchall()
    conn.close()

    events = []
    for r in rows:
        events.append({
            "id": r["id"],
            "title": r["title"],
            "description": r["description"],
            "event_date": r["event_date"],
            "price": float(r["price"]),
            "total_tickets": r["total_tickets"],
            "tickets_sold": r["tickets_sold"],
            "category": r["category"],
            "venue": {
                "id": r["venue_id"],
                "name": r["venue_name"],
                "city": r["venue_city"],
                "capacity": r["venue_capacity"],
            },
        })

    next_cursor = events[-1]["id"] if events else None

    return {
        "api_version": "v2",
        "events": events,
        "pagination": {
            "next_cursor": next_cursor,
            "limit": limit,
            "has_more": len(events) == limit,
        },
    }


@app.get("/v2/events/{event_id}")
def get_event_v2(event_id: int):
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT e.id, e.title, e.description, e.event_date::text,
               e.price, e.total_tickets, e.tickets_sold, e.category,
               v.id AS venue_id, v.name AS venue_name, v.city AS venue_city,
               v.capacity AS venue_capacity
        FROM events e
        JOIN venues v ON e.venue_id = v.id
        WHERE e.id = %s
        """,
        (event_id,),
    )
    row = cur.fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Event not found")

    event = {
        "id": row["id"],
        "title": row["title"],
        "description": row["description"],
        "event_date": row["event_date"],
        "price": float(row["price"]),
        "total_tickets": row["total_tickets"],
        "tickets_sold": row["tickets_sold"],
        "category": row["category"],
        "venue": {
            "id": row["venue_id"],
            "name": row["venue_name"],
            "city": row["venue_city"],
            "capacity": row["venue_capacity"],
        },
    }
    return {"api_version": "v2", "event": event}


# ---------------------------------------------------------------------------
# CRUD helpers (used by both versions, lives under /v2 for simplicity)
# ---------------------------------------------------------------------------

@app.post("/v2/events", status_code=201)
def create_event(event: EventCreate):
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        """INSERT INTO events (title, description, venue_id, event_date, price,
                               total_tickets, category)
           VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING id""",
        (event.title, event.description, event.venue_id, event.event_date,
         event.price, event.total_tickets, event.category),
    )
    new_id = cur.fetchone()["id"]
    conn.commit()
    conn.close()
    return {"id": new_id, "detail": "Event created"}


@app.put("/v2/events/{event_id}")
def replace_event(event_id: int, event: EventCreate):
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        """UPDATE events SET title=%s, description=%s, venue_id=%s,
                  event_date=%s, price=%s, total_tickets=%s, category=%s,
                  updated_at=NOW()
           WHERE id=%s RETURNING id""",
        (event.title, event.description, event.venue_id, event.event_date,
         event.price, event.total_tickets, event.category, event_id),
    )
    row = cur.fetchone()
    conn.commit()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Event not found")
    return {"detail": "Event replaced"}


@app.patch("/v2/events/{event_id}")
def update_event(event_id: int, patch: EventUpdate):
    fields, params = [], []
    for field, value in patch.model_dump(exclude_unset=True).items():
        fields.append(f"{field} = %s")
        params.append(value)
    if not fields:
        raise HTTPException(status_code=400, detail="No fields to update")
    params.append(event_id)

    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        f"UPDATE events SET {', '.join(fields)}, updated_at=NOW() WHERE id=%s RETURNING id",
        params,
    )
    row = cur.fetchone()
    conn.commit()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Event not found")
    return {"detail": "Event updated"}


@app.delete("/v2/events/{event_id}", status_code=204)
def delete_event(event_id: int):
    conn = get_db()
    cur = conn.cursor()
    cur.execute("DELETE FROM events WHERE id = %s RETURNING id", (event_id,))
    row = cur.fetchone()
    conn.commit()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Event not found")
    return None


# ---------------------------------------------------------------------------
# Bookings (nested resource)
# ---------------------------------------------------------------------------

@app.post("/v2/events/{event_id}/bookings", status_code=201)
def create_booking(event_id: int, booking: BookingCreate):
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT price, total_tickets, tickets_sold FROM events WHERE id=%s", (event_id,))
    event = cur.fetchone()
    if not event:
        conn.close()
        raise HTTPException(status_code=404, detail="Event not found")

    available = event["total_tickets"] - event["tickets_sold"]
    if booking.quantity > available:
        conn.close()
        raise HTTPException(status_code=400, detail=f"Only {available} tickets available")

    total_price = float(event["price"]) * booking.quantity
    cur.execute(
        """INSERT INTO bookings (user_id, event_id, quantity, total_price)
           VALUES (%s, %s, %s, %s) RETURNING id""",
        (booking.user_id, event_id, booking.quantity, total_price),
    )
    booking_id = cur.fetchone()["id"]
    cur.execute(
        "UPDATE events SET tickets_sold = tickets_sold + %s WHERE id = %s",
        (booking.quantity, event_id),
    )
    conn.commit()
    conn.close()
    return {"id": booking_id, "total_price": total_price, "detail": "Booking confirmed"}


@app.get("/v2/events/{event_id}/bookings")
def list_event_bookings(event_id: int):
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        """SELECT id, user_id, quantity, total_price, status, created_at::text
           FROM bookings WHERE event_id = %s ORDER BY id""",
        (event_id,),
    )
    rows = cur.fetchall()
    conn.close()
    return {"bookings": [dict(r) for r in rows]}


# ---------------------------------------------------------------------------
# Venues
# ---------------------------------------------------------------------------

@app.get("/v2/venues")
def list_venues():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT id, name, city, capacity FROM venues ORDER BY id")
    rows = cur.fetchall()
    conn.close()
    return {"venues": [dict(r) for r in rows]}


@app.get("/v2/venues/{venue_id}")
def get_venue(venue_id: int):
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT id, name, city, capacity FROM venues WHERE id = %s", (venue_id,))
    row = cur.fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Venue not found")
    return {"venue": dict(row)}


# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------

@app.get("/health")
def health():
    return {"status": "ok"}
