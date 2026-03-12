# Ticketmaster System Design

A hands-on system design exercise where we build a ticket booking platform step by step — learning from bad practices and evolving toward good ones.

---

## Functional Requirements

### In Scope

| # | Requirement |
|---|-------------|
| 1 | Users should be able to **view events** |
| 2 | Users should be able to **search for events** |
| 3 | Users should be able to **book tickets** to events |

### Out of Scope

- Users should be able to view their booked events
- Admins or event coordinators should be able to add events
- Popular events should have dynamic pricing

---

## Non-Functional Requirements

### In Scope

| # | Requirement | Details |
|---|-------------|---------|
| 1 | **Availability vs Consistency trade-off** | Prioritize **availability** for searching & viewing events, but prioritize **consistency** for booking events (no double booking) |
| 2 | **Scalability & high throughput** | Handle popular events at scale (10 million users, one event) |
| 3 | **Low latency search** | Search results returned in < 500ms |
| 4 | **High read throughput** | System is read-heavy with a 100:1 read-to-write ratio |

### Out of Scope

- GDPR compliance and user data protection
- Fault tolerance
- Secure payment transactions
- CI/CD pipelines and testing infrastructure
- Regular backups

---

## Planning the Approach

Before diving into the design, take a moment to plan your strategy. For common user-facing product-style questions, the plan should be straightforward: **build your design up sequentially**, going one by one through your functional requirements. This keeps you focused and prevents getting lost in the weeds. Once you've satisfied the functional requirements, use your non-functional requirements to guide deep dives.

---

## Core Entities

Start with a broad overview of the primary entities. At this stage, you don't need every column or detail — just enough to guide your thinking and lay a solid foundation for the API.

### Event

Stores essential information about an event: date, description, type, and the performer/team involved. Acts as the central point of information for each unique event.

### User

Represents the individual interacting with the system.

### Performer

Represents the individual or group performing or participating in the event. Key attributes include name, description, and links to their work or profiles.

> **Note:** This could be an artist, company, collective, or many other types. "Performer" is intentionally general enough to cover all possibilities.

### Venue

Represents the physical location where an event is held. Includes address, capacity, and a **seat map** — a layout of seating arrangements unique to the venue (e.g., a JSON structure defining sections, rows, and seat numbers along with coordinates for rendering).

### Ticket

Contains information for individual tickets: associated event ID, seat details (section, row, seat number), pricing, and status (`available` or `sold`).

When a new event is created, a ticket is generated for **each seat** in the venue based on the venue's seat map. The client uses the seat map data combined with each ticket's status to render the interactive seat selection UI.

### Booking

Records the details of a user's ticket purchase: user ID, list of ticket IDs, total price, and booking status (`in-progress` or `confirmed`).

> You could arguably fold booking data into the Ticket entity itself, but a separate Booking entity is useful when a user purchases multiple tickets in one transaction — it groups them under a single order with a shared payment status and total price.

---

## API Design

Start with simple APIs that you evolve as the design progresses. Communicate: *"Here is a simple API to start, but as we get into the design, we'll likely need to evolve this to handle more complex scenarios."*

### View Event

```
GET /events/:eventId -> Event & Venue & Performer & Ticket[]
```

Straightforward — takes an `eventId` and returns event details along with venue, performer, and all tickets (tickets are needed to render the seat map on the client).

### Search Events

```
GET /events/search?keyword={keyword}&start={start_date}&end={end_date}&pageSize={page_size}&page={page_number} -> Event[]
```

Takes a set of search parameters and returns a paginated list of matching events.

### Book Tickets

```
POST /bookings/:eventId -> bookingId

{
  "ticketIds": string[],
  "paymentDetails": ...
}
```

Takes a list of ticket IDs and payment details, returns a `bookingId`.

> Later in the design, we'll evolve this into **two separate endpoints** — one for reserving a ticket and one for confirming a purchase — but this is a good starting point.

---

## High-Level Design

We build the system sequentially, one functional requirement at a time.

### 1. View Events

```
Client  <-->  API Gateway  <-->  Event Service  <-->  Database
              - authentication                        - Event (id, venueId, performerId, tickets[], name, description, ...)
              - rate limiting                          - Venue (id, location, seatMap, ...)
              - routing                                - Performer (id, ...)
```

**Flow:**
1. Client makes a REST `GET /events/:eventId` request
2. API Gateway forwards the request to the **Event Service**
3. Event Service queries the database for event, venue, performer, and ticket data
4. Returns the combined response to the client (including ticket statuses for seat map rendering)

**Components:**
- **Client** — web or mobile app the user interacts with
- **API Gateway** — entry point that routes requests and handles cross-cutting concerns (auth, rate limiting, logging)
- **Event Service** — microservice responsible for fetching event/venue/performer data from the database
- **Events DB** — stores tables for events, performers, venues, and tickets

### 2. Search Events

```
                              GET /search?term=...&location=...&type=...&date=...
Client  <-->  API Gateway  ──────────────────────────────────────────────────────>  Search Service  <-->  Database
                                                                                   (queries event table directly)
```

The most basic approach: a Search Service that accepts parameterized queries (keyword, location, type, date) and filters against the events table in the database. This has issues at scale, but it's a valid starting point — we'll explore better options (e.g., Elasticsearch) in deep dives.

**Flow:**
1. Client makes a REST `GET /search?term={term}&location={location}&type={type}&date={date}` request
2. API Gateway handles auth/rate limiting, then forwards to the **Search Service**
3. Search Service queries the Events DB, filtering by the provided parameters
4. Returns a paginated list of matching events (`Partial<Event>[]`)

**Components:**
- **Search Service** — microservice responsible for querying events based on search parameters

### 3. Book Tickets

```
Client  <-->  API Gateway  ──book(ticketIds, userId)──>  Booking Service  ──Transaction──>  Database
                                                              │                              - Ticket (id, eventId, seat, price, status, userId)
                                                              │                              - Booking (id, userId, tickets)
                                                              v
                                                           Stripe
                                                       (payment processor)
```

The critical requirement here is **consistency** — no double bookings. We use PostgreSQL transactions with proper isolation to ensure only one user can book a given ticket.

> Multiple services share the same database here. The "database per service" rule is not hard-and-fast — the data is tightly coupled (bookings need tickets need events), we need ACID transactions, and splitting would add complexity for no benefit.

**Flow:**
1. User selects seats and clicks "Book" — a `POST /bookings` request is sent with the ticket IDs
2. Booking Service starts a **database transaction**:
   - Checks if the selected tickets are still `available`
   - Updates ticket status to `booked`
   - Creates a Booking record
3. If the transaction succeeds, the Booking Service processes payment via **Stripe**
4. On payment success, returns the `bookingId` to the client
5. If another user already booked the ticket (transaction fails), returns an error

**Components:**
- **Booking Service** — handles the booking transaction, ticket status updates, and payment processing
- **Payment Processor (Stripe)** — external service for handling payments

> **Known issue:** Users can reach the booking page, fill in payment details, and _then_ discover the ticket is gone. We'll address this with ticket reservation (temporary holds) in the deep dives.

---

## Deep Dives

With all functional requirements met, we use non-functional requirements to guide deeper exploration.

### Deep Dive 1: Ticket Reservation with Distributed Locks

**Problem:** Users fill out payment details only to learn the ticket was snatched by someone faster. Terrible UX.

**Bad approach — Long-running DB locks:** Keep a `SELECT ... FOR UPDATE` transaction open for 10 minutes while the user pays. This strains the database, risks deadlocks, and doesn't scale.

**Better approach — Status + expiration in DB:** Add a `reserved` status and `reserved_until` timestamp to the ticket row. Use short transactions to reserve. But expiration requires either a cron job (delayed unlocking) or checking expiry inline on every read.

**Best approach — Redis distributed lock with TTL:**

```
                          reserve(ticketId, userId)
Client  ──>  API Gateway  ──────────────────────────>  Booking Service  ──>  Redis (Ticket Lock)
                          confirm(bookingId, token)          │                {ticketId: userId} TTL 10 min
                                                             │
                                                             ├──>  Database (PostgreSQL)
                                                             │      - Ticket: available / booked
                                                             │      - Booking: in-progress / confirmed
                                                             v
                                                          Stripe
```

Tickets have only two DB states: `available` and `booked`. Reservation lives entirely in Redis with automatic TTL expiration.

**Reserve flow:**
1. User selects a seat → `POST /bookings/reserve` with ticketId
2. Booking Service acquires a Redis lock: `SET ticket:{id} userId NX EX 600` (atomic, 10-min TTL)
3. If lock acquired → create Booking record with status `in-progress`, return `bookingId`
4. If lock fails → another user already reserved it, return error immediately
5. Client redirects to payment page with countdown timer

**Confirm flow:**
6. User submits payment → client tokenizes via Stripe.js, sends token + bookingId to server
7. Server creates Stripe PaymentIntent. On success, Stripe confirms via webhook
8. Webhook handler (idempotent): updates ticket status to `booked`, booking status to `confirmed`, releases Redis lock

**Expiration:** If TTL expires before payment, Redis auto-releases the lock. Ticket is available again — no cron needed.

**Edge cases:**
- **TTL expires during payment:** DB transaction uses `SELECT ... FOR UPDATE` as a safety net — only one write succeeds. Losing user gets an automatic refund. Set TTL generously and extend it when payment begins.
- **Redis goes down:** Degrades to Lab 3 behavior (no reservation, but `SELECT ... FOR UPDATE` still prevents double bookings). UX suffers, but correctness is preserved.
- **Read path:** Event Service queries Redis for reserved ticket IDs (`event:{id}:reserved` set) so the seat map shows reserved seats as unavailable.

### Deep Dive 2: Scaling the View Path (Caching + Horizontal Scaling)

**Problem:** Event pages get hammered when tickets go on sale — thousands of users refreshing the same page. Our system must handle 10s of millions of concurrent requests with high availability.

**Pattern:** Scaling Reads (see `patterns/scaling-reads/`)

**Strategy — three layers:**

```
Client  ──>  Load Balancer  ──>  Event Service (N instances)  ──>  Redis Cache  ──>  PostgreSQL
             (Round Robin /       (stateless, horizontally           (read-through)    (source of truth)
              Least Connections)    scaled)
```

**1. Caching (Redis):**
- Cache event details, venue info, performer bios — high read rate, low update frequency
- Key pattern: `event:{eventId}` → full event JSON
- **Read-through strategy:** cache miss → read from DB → populate cache → return
- TTL policy: long TTL for static data (venue, performer), shorter for event details
- Cache invalidation: DB triggers or application-level invalidation on updates

**2. Load Balancing:**
- Distribute traffic across Event Service instances (Round Robin / Least Connections)
- Applied to all horizontally scaled services

**3. Horizontal Scaling:**
- Event Service is stateless → spin up N instances behind a load balancer
- Each instance reads from the same Redis cache and PostgreSQL

**Challenges:**
- Cache-DB consistency during event detail updates (mitigated by TTL + invalidation)
- Managing many instances (deployment, rollback)

### Deep Dive 3: High-Demand Events (Real-Time Updates + Virtual Queue)

**Problem:** During a Taylor Swift-scale event, the seat map goes stale instantly. Users click seats that are already taken, leading to frustration and wasted effort.

**Good approach — SSE for real-time seat map updates:**

```
Client  <──SSE──  Event Service  <──subscribe──  Redis Pub/Sub
                                                   ↑
Booking Service ──publish seat change──────────────┘
```

Use Server-Sent Events (SSE) to push seat status changes to clients in real-time. When a ticket is booked or reserved, the Booking Service publishes the change via Redis Pub/Sub, and all connected clients see it instantly — no page refresh needed.

**Challenge:** For extremely popular events, the seat map fills up so fast that the UX is overwhelming. Users watch seats disappear faster than they can click.

**Great approach — Virtual waiting queue:**

```
Client  ──>  Queue Service  ──>  Redis Sorted Set (position by timestamp)
                │                   │
                │ SSE: position     │ Dequeue N users
                │ updates           │ when capacity available
                v                   v
             Client              Booking Page (admitted users only)
```

For admin-flagged high-demand events, users enter a **virtual queue** before seeing the seat map. The system:
1. Places users in a Redis sorted set (ordered by arrival timestamp)
2. Pushes position updates via SSE ("You are #4,521 in line...")
3. Periodically admits a batch of users to the booking page
4. Marks admitted users in Redis (`admitted:{eventId}` set with TTL)
5. Booking Service only accepts reservations from admitted users

This prevents system overload and gives users a fair, predictable experience instead of a frantic seat-clicking race.

**Challenges:**
- Long wait times → mitigated by real-time position updates and estimated wait times
- Admitted user TTL management — if they don't book in time, re-admit from queue

### Deep Dive 4: Low-Latency Search (Indexes → Full-Text → Elasticsearch)

**Problem:** Our Lab 2 search uses `ILIKE '%keyword%'` which causes full table scans — O(n) with data size. At 1M+ events, this blows past our 500ms SLA.

**Good approach — Database indexes:**

```sql
CREATE INDEX idx_events_name ON events(name);
CREATE INDEX idx_events_date ON events(event_date);
CREATE INDEX idx_performers_name ON performers(name);
```

Standard B-tree indexes speed up exact matches and prefix searches, but don't help with `%keyword%` patterns (substring in the middle). Also optimize queries with `EXPLAIN ANALYZE`, avoid `SELECT *`, use `UNION` instead of `OR`.

**Better approach — PostgreSQL full-text search:**

```sql
ALTER TABLE events ADD COLUMN search_vector tsvector;
CREATE INDEX idx_events_fts ON events USING GIN(search_vector);
-- Queries use ts_query instead of ILIKE — uses the GIN index, not a table scan
```

PostgreSQL's built-in `tsvector` + GIN indexes support word-based search. Faster than `ILIKE`, supports stemming and ranking. But no fuzzy matching, limited scalability, and adds write overhead.

**Great approach — Elasticsearch with CDC:**

```
Write path:  Event Service ──> PostgreSQL ──CDC──> Elasticsearch
Read path:   Search Service ──> Elasticsearch (inverted indexes, fuzzy search, relevance ranking)
```

Elasticsearch uses **inverted indexes** for O(1) lookups, supports **fuzzy matching** ("Tayler" → "Taylor"), **relevance scoring**, and handles millions of documents with sub-100ms latency. Data is synced from PostgreSQL via **Change Data Capture (CDC)** for near-real-time consistency.

**Challenges:**
- CDC setup and sync reliability (Debezium, Kafka Connect)
- Additional infrastructure cost (Elasticsearch cluster)
- Eventual consistency between PostgreSQL and Elasticsearch

### Deep Dive 5: Search Query Caching + CDN

**Problem:** Popular searches ("Taylor Swift", "concerts near me") hit Elasticsearch thousands of times per second with the same results. Wasteful and adds latency.

**Good approach — Redis search cache:**

```
Client ──> Search Service ──> Redis cache (key = normalized query hash)
                                  │
                            MISS? ──> Elasticsearch ──> cache result with TTL
                            HIT?  ──> return cached results
```

Cache key: `search:{hash(keyword+location+type+date+page)}` → cached result list. TTL 1–24 hours depending on how dynamic the results are.

**Great approach — Elasticsearch built-in caching + CDN:**

- **ES node query cache:** Automatically caches filter results at the shard level. No application code needed.
- **ES request cache:** Caches full search responses for aggregation-heavy queries.
- **CDN (CloudFront):** Cache non-personalized search results geographically closer to users. Same query = same results for everyone.

```
Client ──> CDN (CloudFront) ──> API Gateway ──> Search Service ──> ES (with query cache)
           ↑ cache HIT                                              ↑ shard-level cache
           returns in ~5ms                                          returns in ~20ms
```

**Challenges:**
- Cache invalidation when events are added/updated — search queries and results aren't directly linked
- CDN only works for non-personalized results
- Cache misses during peak times can spike ES load

---

## Labs

Hands-on notebooks that walk through each design decision with working code.

| # | Notebook | Topic |
|---|----------|-------|
| 1 | `01_view_events.ipynb` | View event flow — Event Service reading from PostgreSQL |
| 2 | `02_search_events.ipynb` | Search flow — querying events with filters and pagination |
| 3 | `03_book_tickets.ipynb` | Booking flow — transactions, locking, and preventing double bookings |
| 4 | `04_ticket_reservation.ipynb` | Deep dive — distributed locks with Redis for temporary reservations |
| 5 | `05_scaling_reads.ipynb` | Deep dive — caching event data with Redis for high-throughput reads |
| 6 | `06_high_demand.ipynb` | Deep dive — real-time seat updates (SSE) + virtual waiting queue |
| 7 | `07_scaling_search.ipynb` | Deep dive — indexes, full-text search, Elasticsearch, and search caching |
