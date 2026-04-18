-- ============================================================
-- Ticketmaster System Design - Database Schema & Seed Data
-- ============================================================
-- This schema models a simplified ticket booking platform
-- with events, venues, performers, tickets, and bookings.
-- ============================================================


-- ============================================================
-- SCHEMA
-- ============================================================

-- Performers: artists, bands, teams, speakers, etc.
CREATE TABLE performers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    genre VARCHAR(100),
    image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Venues: physical locations where events take place
-- seat_map is a JSON structure defining sections, rows, seats
CREATE TABLE venues (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(500) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    country VARCHAR(100) NOT NULL,
    capacity INTEGER NOT NULL,
    seat_map JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Events: a performer at a venue on a date
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    event_type VARCHAR(50) NOT NULL,
    venue_id INTEGER NOT NULL REFERENCES venues(id),
    performer_id INTEGER NOT NULL REFERENCES performers(id),
    event_date TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tickets: one per seat per event
CREATE TABLE tickets (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES events(id),
    section VARCHAR(10) NOT NULL,
    row_label VARCHAR(5) NOT NULL,
    seat_number INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'available',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(event_id, section, row_label, seat_number)
);

-- Bookings: groups one or more tickets into a single purchase
CREATE TABLE bookings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    event_id INTEGER NOT NULL REFERENCES events(id),
    total_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'in-progress',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Join table: which tickets belong to which booking
CREATE TABLE booking_tickets (
    booking_id INTEGER NOT NULL REFERENCES bookings(id),
    ticket_id INTEGER NOT NULL REFERENCES tickets(id),
    PRIMARY KEY (booking_id, ticket_id)
);

-- Indexes for common queries
CREATE INDEX idx_events_venue ON events(venue_id);
CREATE INDEX idx_events_performer ON events(performer_id);
CREATE INDEX idx_events_date ON events(event_date);
CREATE INDEX idx_tickets_event ON tickets(event_id);
CREATE INDEX idx_tickets_status ON tickets(event_id, status);
CREATE INDEX idx_bookings_user ON bookings(user_id);


-- ============================================================
-- SEED DATA
-- ============================================================

-- Performers
INSERT INTO performers (name, description, genre, image_url) VALUES
('Taylor Swift',        'Global pop superstar known for storytelling lyrics.',            'Pop',          'https://example.com/taylor.jpg'),
('Kendrick Lamar',      'Pulitzer Prize-winning rapper and lyricist.',                    'Hip-Hop',      'https://example.com/kendrick.jpg'),
('Coldplay',            'British rock band known for anthemic stadium shows.',             'Rock',         'https://example.com/coldplay.jpg'),
('Beyoncé',             'Iconic singer, songwriter, and performer.',                      'R&B/Pop',      'https://example.com/beyonce.jpg'),
('Los Angeles Lakers',  'NBA basketball team based in Los Angeles.',                      'Sports',       'https://example.com/lakers.jpg'),
('Dave Chappelle',      'Legendary stand-up comedian and social commentator.',            'Comedy',       'https://example.com/chappelle.jpg'),
('Adele',               'British singer known for powerful ballads.',                     'Pop/Soul',     'https://example.com/adele.jpg'),
('Cirque du Soleil',    'World-renowned theatrical circus entertainment company.',        'Theater',      'https://example.com/cirque.jpg');

-- Venues (each with a small seat_map for demo purposes)
-- In production the seat_map would have thousands of seats; here we keep it small.
INSERT INTO venues (name, address, city, state, country, capacity, seat_map) VALUES
(
    'Madison Square Garden',
    '4 Pennsylvania Plaza',
    'New York',
    'NY',
    'US',
    20000,
    '{
        "sections": [
            {
                "name": "FLOOR",
                "rows": [
                    {"label": "A", "seats": 10},
                    {"label": "B", "seats": 10},
                    {"label": "C", "seats": 10}
                ]
            },
            {
                "name": "LOWER",
                "rows": [
                    {"label": "A", "seats": 15},
                    {"label": "B", "seats": 15},
                    {"label": "C", "seats": 15}
                ]
            },
            {
                "name": "UPPER",
                "rows": [
                    {"label": "A", "seats": 20},
                    {"label": "B", "seats": 20}
                ]
            }
        ]
    }'::jsonb
),
(
    'SoFi Stadium',
    '1001 Stadium Dr',
    'Inglewood',
    'CA',
    'US',
    70000,
    '{
        "sections": [
            {
                "name": "FLOOR",
                "rows": [
                    {"label": "A", "seats": 12},
                    {"label": "B", "seats": 12}
                ]
            },
            {
                "name": "LOWER",
                "rows": [
                    {"label": "A", "seats": 20},
                    {"label": "B", "seats": 20},
                    {"label": "C", "seats": 20}
                ]
            },
            {
                "name": "UPPER",
                "rows": [
                    {"label": "A", "seats": 25},
                    {"label": "B", "seats": 25}
                ]
            }
        ]
    }'::jsonb
),
(
    'The O2 Arena',
    'Peninsula Square',
    'London',
    NULL,
    'UK',
    20000,
    '{
        "sections": [
            {
                "name": "FLOOR",
                "rows": [
                    {"label": "A", "seats": 8},
                    {"label": "B", "seats": 8}
                ]
            },
            {
                "name": "LOWER",
                "rows": [
                    {"label": "A", "seats": 12},
                    {"label": "B", "seats": 12}
                ]
            },
            {
                "name": "UPPER",
                "rows": [
                    {"label": "A", "seats": 15},
                    {"label": "B", "seats": 15}
                ]
            }
        ]
    }'::jsonb
);

-- Events
INSERT INTO events (name, description, event_type, venue_id, performer_id, event_date) VALUES
('The Eras Tour - NYC',         'Taylor Swift live at MSG. A journey through every musical era.', 'concert', 1, 1, '2026-06-15 20:00:00'),
('Championship Game',           'Lakers vs Celtics — the NBA Finals showdown.',                   'sports',  2, 5, '2026-07-01 19:30:00'),
('Renaissance World Tour',      'Beyoncé performs her latest album live.',                        'concert', 3, 4, '2026-08-10 21:00:00'),
('Kendrick Lamar: Big Steppers', 'Kendrick Lamar live — raw lyricism meets electrifying energy.', 'concert', 1, 2, '2026-09-20 20:00:00'),
('Music of the Spheres',        'Coldplay stadium tour with dazzling visuals.',                   'concert', 2, 3, '2026-10-05 19:00:00');

-- Generate tickets for every event based on the venue seat_map.
-- This function reads the seat_map JSON and creates one ticket per seat.
-- Pricing: FLOOR = $250, LOWER = $150, UPPER = $75.
DO $$
DECLARE
    ev RECORD;
    venue_map JSONB;
    section JSONB;
    row_obj JSONB;
    section_name TEXT;
    row_label TEXT;
    num_seats INTEGER;
    seat INTEGER;
    price DECIMAL(10,2);
BEGIN
    FOR ev IN SELECT e.id AS event_id, v.seat_map
              FROM events e JOIN venues v ON e.venue_id = v.id
    LOOP
        venue_map := ev.seat_map;
        FOR section IN SELECT * FROM jsonb_array_elements(venue_map -> 'sections')
        LOOP
            section_name := section ->> 'name';
            price := CASE section_name
                WHEN 'FLOOR' THEN 250.00
                WHEN 'LOWER' THEN 150.00
                WHEN 'UPPER' THEN 75.00
                ELSE 100.00
            END;
            FOR row_obj IN SELECT * FROM jsonb_array_elements(section -> 'rows')
            LOOP
                row_label := row_obj ->> 'label';
                num_seats := (row_obj ->> 'seats')::INTEGER;
                FOR seat IN 1..num_seats
                LOOP
                    INSERT INTO tickets (event_id, section, row_label, seat_number, price)
                    VALUES (ev.event_id, section_name, row_label, seat, price);
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- Mark some tickets as sold so the seat map is more realistic
UPDATE tickets SET status = 'sold' WHERE id IN (
    SELECT id FROM tickets WHERE event_id = 1 ORDER BY random() LIMIT 25
);
UPDATE tickets SET status = 'sold' WHERE id IN (
    SELECT id FROM tickets WHERE event_id = 2 ORDER BY random() LIMIT 30
);
UPDATE tickets SET status = 'sold' WHERE id IN (
    SELECT id FROM tickets WHERE event_id = 3 ORDER BY random() LIMIT 15
);
