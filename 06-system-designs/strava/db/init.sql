-- ============================================================
-- Strava Lab — GPS Activity Tracking & Social Fitness
-- ============================================================
-- This schema models the core of a Strava-like fitness app:
--   • Users and friendships
--   • Activities with GPS route points (PostGIS)
--   • Segments and leaderboards
-- ============================================================

-- Enable PostGIS for geographic queries (distance, containment, etc.)
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================
-- Users
-- ============================================================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    city VARCHAR(100),
    country VARCHAR(100) DEFAULT 'USA',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Friendships (bi-directional: two rows per friendship)
-- ============================================================
CREATE TABLE friends (
    user_id INTEGER NOT NULL REFERENCES users(id),
    friend_id INTEGER NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, friend_id)
);

CREATE INDEX idx_friends_user ON friends(user_id);

-- ============================================================
-- Activities (a single run or ride)
-- ============================================================
CREATE TABLE activities (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    type VARCHAR(10) NOT NULL CHECK (type IN ('RUN', 'RIDE')),
    state VARCHAR(15) NOT NULL DEFAULT 'STARTED'
        CHECK (state IN ('STARTED', 'PAUSED', 'COMPLETE')),
    title VARCHAR(200),
    distance_m DOUBLE PRECISION DEFAULT 0,     -- total distance in metres
    duration_s INTEGER DEFAULT 0,              -- active time in seconds
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_activities_user ON activities(user_id);
CREATE INDEX idx_activities_state ON activities(state);
CREATE INDEX idx_activities_completed ON activities(completed_at);

-- ============================================================
-- Route points (GPS breadcrumbs for each activity)
-- PostGIS lets us do real geographic math later
-- ============================================================
CREATE TABLE route_points (
    id SERIAL PRIMARY KEY,
    activity_id INTEGER NOT NULL REFERENCES activities(id),
    seq INTEGER NOT NULL,                     -- order within the activity
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    elevation_m DOUBLE PRECISION DEFAULT 0,
    recorded_at TIMESTAMP NOT NULL,
    geom GEOGRAPHY(Point, 4326)               -- PostGIS point (WGS-84)
);

CREATE INDEX idx_route_activity ON route_points(activity_id, seq);
CREATE INDEX idx_route_geom ON route_points USING GIST(geom);

-- ============================================================
-- Segments (famous stretches athletes compare times on)
-- ============================================================
CREATE TABLE segments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    type VARCHAR(10) NOT NULL CHECK (type IN ('RUN', 'RIDE')),
    start_lat DOUBLE PRECISION NOT NULL,
    start_lon DOUBLE PRECISION NOT NULL,
    end_lat DOUBLE PRECISION NOT NULL,
    end_lon DOUBLE PRECISION NOT NULL,
    distance_m DOUBLE PRECISION NOT NULL,
    city VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Segment efforts (one per athlete per segment per activity)
-- ============================================================
CREATE TABLE segment_efforts (
    id SERIAL PRIMARY KEY,
    segment_id INTEGER NOT NULL REFERENCES segments(id),
    activity_id INTEGER NOT NULL REFERENCES activities(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    elapsed_s INTEGER NOT NULL,               -- time to complete the segment
    started_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_efforts_segment ON segment_efforts(segment_id);
CREATE INDEX idx_efforts_user ON segment_efforts(user_id);

-- ============================================================
-- Activity state log (for accurate pause/resume timing)
-- ============================================================
CREATE TABLE activity_state_log (
    id SERIAL PRIMARY KEY,
    activity_id INTEGER NOT NULL REFERENCES activities(id),
    state VARCHAR(15) NOT NULL,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_state_log_activity ON activity_state_log(activity_id);

-- ============================================================
-- SEED DATA
-- ============================================================

-- 20 users
INSERT INTO users (username, display_name, city, country) VALUES
    ('alice',   'Alice Johnson',   'San Francisco', 'USA'),
    ('bob',     'Bob Smith',       'San Francisco', 'USA'),
    ('carol',   'Carol Williams',  'New York',      'USA'),
    ('dave',    'Dave Brown',      'Austin',        'USA'),
    ('eve',     'Eve Davis',       'London',        'UK'),
    ('frank',   'Frank Miller',    'London',        'UK'),
    ('grace',   'Grace Wilson',    'Sydney',        'Australia'),
    ('hank',    'Hank Moore',      'Sydney',        'Australia'),
    ('ivy',     'Ivy Taylor',      'Toronto',       'Canada'),
    ('jack',    'Jack Anderson',   'Toronto',       'Canada'),
    ('kate',    'Kate Thomas',     'Berlin',        'Germany'),
    ('leo',     'Leo Jackson',     'Berlin',        'Germany'),
    ('mia',     'Mia White',       'Tokyo',         'Japan'),
    ('nick',    'Nick Harris',     'Tokyo',         'Japan'),
    ('olivia',  'Olivia Martin',   'Paris',         'France'),
    ('peter',   'Peter Garcia',    'Paris',         'France'),
    ('quinn',   'Quinn Martinez',  'Seattle',       'USA'),
    ('rose',    'Rose Robinson',   'Seattle',       'USA'),
    ('sam',     'Sam Clark',       'Portland',      'USA'),
    ('tina',    'Tina Lewis',      'Portland',      'USA');

-- Friendships (bi-directional pairs)
INSERT INTO friends (user_id, friend_id) VALUES
    (1,2),(2,1), (1,3),(3,1), (1,4),(4,1), (1,5),(5,1),
    (2,3),(3,2), (2,6),(6,2), (3,7),(7,3), (4,8),(8,4),
    (5,6),(6,5), (7,8),(8,7), (9,10),(10,9), (11,12),(12,11),
    (13,14),(14,13), (15,16),(16,15), (17,18),(18,17), (19,20),(20,19),
    (1,17),(17,1), (2,9),(9,2), (3,11),(11,3), (5,15),(15,5);

-- ============================================================
-- Helper: generate a realistic GPS route as a series of points
-- along the San Francisco Embarcadero (~2.5 km run)
-- ============================================================

-- Activity 1: Alice — morning run along the Embarcadero
INSERT INTO activities (user_id, type, state, title, distance_m, duration_s, started_at, completed_at)
VALUES (1, 'RUN', 'COMPLETE', 'Morning Embarcadero Run', 2540.0, 780,
        NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1 hour 47 minutes');

INSERT INTO route_points (activity_id, seq, latitude, longitude, elevation_m, recorded_at, geom) VALUES
    (1,  1, 37.7955, -122.3935, 3, NOW()-INTERVAL '2 hours',         ST_Point(-122.3935, 37.7955)::geography),
    (1,  2, 37.7950, -122.3928, 3, NOW()-INTERVAL '119 minutes',     ST_Point(-122.3928, 37.7950)::geography),
    (1,  3, 37.7944, -122.3919, 3, NOW()-INTERVAL '118 minutes',     ST_Point(-122.3919, 37.7944)::geography),
    (1,  4, 37.7938, -122.3910, 2, NOW()-INTERVAL '117 minutes',     ST_Point(-122.3910, 37.7938)::geography),
    (1,  5, 37.7932, -122.3900, 2, NOW()-INTERVAL '116 minutes',     ST_Point(-122.3900, 37.7932)::geography),
    (1,  6, 37.7925, -122.3892, 2, NOW()-INTERVAL '115 minutes',     ST_Point(-122.3892, 37.7925)::geography),
    (1,  7, 37.7918, -122.3884, 2, NOW()-INTERVAL '114 minutes',     ST_Point(-122.3884, 37.7918)::geography),
    (1,  8, 37.7912, -122.3875, 3, NOW()-INTERVAL '113 minutes',     ST_Point(-122.3875, 37.7912)::geography),
    (1,  9, 37.7905, -122.3868, 3, NOW()-INTERVAL '112 minutes',     ST_Point(-122.3868, 37.7905)::geography),
    (1, 10, 37.7899, -122.3860, 3, NOW()-INTERVAL '111 minutes',     ST_Point(-122.3860, 37.7899)::geography);

-- Activity 2: Bob — bike ride through Golden Gate Park
INSERT INTO activities (user_id, type, state, title, distance_m, duration_s, started_at, completed_at)
VALUES (2, 'RIDE', 'COMPLETE', 'Golden Gate Park Ride', 8500.0, 1500,
        NOW() - INTERVAL '5 hours', NOW() - INTERVAL '4 hours 35 minutes');

INSERT INTO route_points (activity_id, seq, latitude, longitude, elevation_m, recorded_at, geom) VALUES
    (2,  1, 37.7694, -122.4862, 25, NOW()-INTERVAL '5 hours',       ST_Point(-122.4862, 37.7694)::geography),
    (2,  2, 37.7700, -122.4830, 28, NOW()-INTERVAL '298 minutes',   ST_Point(-122.4830, 37.7700)::geography),
    (2,  3, 37.7710, -122.4790, 30, NOW()-INTERVAL '296 minutes',   ST_Point(-122.4790, 37.7710)::geography),
    (2,  4, 37.7720, -122.4750, 27, NOW()-INTERVAL '294 minutes',   ST_Point(-122.4750, 37.7720)::geography),
    (2,  5, 37.7730, -122.4700, 22, NOW()-INTERVAL '292 minutes',   ST_Point(-122.4700, 37.7730)::geography),
    (2,  6, 37.7740, -122.4650, 20, NOW()-INTERVAL '290 minutes',   ST_Point(-122.4650, 37.7740)::geography),
    (2,  7, 37.7748, -122.4600, 18, NOW()-INTERVAL '288 minutes',   ST_Point(-122.4600, 37.7748)::geography),
    (2,  8, 37.7755, -122.4550, 15, NOW()-INTERVAL '286 minutes',   ST_Point(-122.4550, 37.7755)::geography);

-- Activity 3: Carol — Central Park loop
INSERT INTO activities (user_id, type, state, title, distance_m, duration_s, started_at, completed_at)
VALUES (3, 'RUN', 'COMPLETE', 'Central Park Loop', 5100.0, 1560,
        NOW() - INTERVAL '1 day 3 hours', NOW() - INTERVAL '1 day 2 hours 34 minutes');

-- Activity 4: Alice — afternoon ride
INSERT INTO activities (user_id, type, state, title, distance_m, duration_s, started_at, completed_at)
VALUES (1, 'RIDE', 'COMPLETE', 'Afternoon Bay Ride', 15200.0, 2700,
        NOW() - INTERVAL '1 day', NOW() - INTERVAL '23 hours 15 minutes');

-- Activity 5: Dave — Town Lake trail
INSERT INTO activities (user_id, type, state, title, distance_m, duration_s, started_at, completed_at)
VALUES (4, 'RUN', 'COMPLETE', 'Town Lake Trail Run', 4800.0, 1440,
        NOW() - INTERVAL '3 hours', NOW() - INTERVAL '2 hours 36 minutes');

-- Activity 6: Eve — Hyde Park run
INSERT INTO activities (user_id, type, state, title, distance_m, duration_s, started_at, completed_at)
VALUES (5, 'RUN', 'COMPLETE', 'Hyde Park Morning Run', 6200.0, 1860,
        NOW() - INTERVAL '8 hours', NOW() - INTERVAL '7 hours 29 minutes');

-- Activity 7: Quinn — Seattle waterfront ride
INSERT INTO activities (user_id, type, state, title, distance_m, duration_s, started_at, completed_at)
VALUES (17, 'RIDE', 'COMPLETE', 'Seattle Waterfront Ride', 12000.0, 2100,
        NOW() - INTERVAL '6 hours', NOW() - INTERVAL '5 hours 25 minutes');

-- Activity 8: Alice — in-progress run (for demo purposes)
INSERT INTO activities (user_id, type, state, title, distance_m, duration_s, started_at)
VALUES (1, 'RUN', 'STARTED', 'Lunchtime Jog', 0, 0, NOW());

-- Generate more completed activities for leaderboard demos
INSERT INTO activities (user_id, type, state, title, distance_m, duration_s, started_at, completed_at)
SELECT
    ((i % 20) + 1),
    CASE WHEN i % 3 = 0 THEN 'RIDE' ELSE 'RUN' END,
    'COMPLETE',
    'Activity #' || i,
    (random() * 15000 + 1000)::int,
    (random() * 3600 + 600)::int,
    NOW() - (random() * INTERVAL '30 days'),
    NOW() - (random() * INTERVAL '30 days') + INTERVAL '1 hour'
FROM generate_series(9, 200) AS i;

-- ============================================================
-- Segments (famous stretches to race on)
-- ============================================================
INSERT INTO segments (name, type, start_lat, start_lon, end_lat, end_lon, distance_m, city) VALUES
    ('Embarcadero Sprint',       'RUN',  37.7955, -122.3935, 37.7899, -122.3860, 850,  'San Francisco'),
    ('Golden Gate Park Climb',   'RIDE', 37.7694, -122.4862, 37.7748, -122.4600, 2800, 'San Francisco'),
    ('Central Park North Loop',  'RUN',  40.7968, -73.9495,  40.8005, -73.9580,  1200, 'New York'),
    ('Hyde Park Serpentine',     'RUN',  51.5073, -0.1657,   51.5050, -0.1580,   900,  'London'),
    ('Waterfront Dash',          'RIDE', 47.6062, -122.3421, 47.6205, -122.3493, 1700, 'Seattle');

-- Segment efforts (Alice and Bob ran the Embarcadero Sprint)
INSERT INTO segment_efforts (segment_id, activity_id, user_id, elapsed_s, started_at) VALUES
    (1, 1, 1, 210, NOW() - INTERVAL '2 hours'),
    (1, 5, 4, 225, NOW() - INTERVAL '3 hours'),
    (2, 2, 2, 480, NOW() - INTERVAL '5 hours'),
    (2, 7, 17, 510, NOW() - INTERVAL '6 hours');

-- Generate more segment efforts for leaderboard variety
INSERT INTO segment_efforts (segment_id, activity_id, user_id, elapsed_s, started_at)
SELECT
    ((i % 5) + 1),
    ((i % 192) + 9),
    ((i % 20) + 1),
    (random() * 300 + 150)::int,
    NOW() - (random() * INTERVAL '30 days')
FROM generate_series(1, 80) AS i;

-- Populate the PostGIS geom column from lat/lon (for any rows without it)
UPDATE route_points
SET geom = ST_Point(longitude, latitude)::geography
WHERE geom IS NULL;
