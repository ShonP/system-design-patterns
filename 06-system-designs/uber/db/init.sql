-- ============================================================
-- Uber System Design Lab — Database Schema
-- Uses PostGIS for geospatial queries
-- ============================================================

-- Enable the PostGIS extension for geographic data types and functions
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================
-- Core Tables
-- ============================================================

-- Riders: people who request rides
CREATE TABLE riders (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    rating_avg DECIMAL(3,2) DEFAULT 5.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Drivers: people who provide rides
CREATE TABLE drivers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    vehicle_make VARCHAR(50),
    vehicle_model VARCHAR(50),
    vehicle_year INTEGER,
    license_plate VARCHAR(20),
    rating_avg DECIMAL(3,2) DEFAULT 5.00,
    status VARCHAR(20) DEFAULT 'offline'
        CHECK (status IN ('offline', 'available', 'busy', 'outstanding_request')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Driver locations: real-time GPS positions stored with PostGIS
-- This table is the "persistent" store; Redis is the fast layer
CREATE TABLE driver_locations (
    driver_id INTEGER PRIMARY KEY REFERENCES drivers(id),
    location GEOGRAPHY(POINT, 4326) NOT NULL,  -- lng/lat point on Earth
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Spatial index so PostGIS proximity queries are fast
CREATE INDEX idx_driver_locations_geo ON driver_locations USING GIST (location);

-- Fares: price estimates before a ride is confirmed
CREATE TABLE fares (
    id SERIAL PRIMARY KEY,
    rider_id INTEGER REFERENCES riders(id),
    pickup_location GEOGRAPHY(POINT, 4326) NOT NULL,
    dropoff_location GEOGRAPHY(POINT, 4326) NOT NULL,
    distance_km DECIMAL(8,2),
    estimated_duration_min INTEGER,
    base_fare DECIMAL(10,2),
    surge_multiplier DECIMAL(4,2) DEFAULT 1.00,
    estimated_fare DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Rides: the full lifecycle of a trip
CREATE TABLE rides (
    id SERIAL PRIMARY KEY,
    fare_id INTEGER REFERENCES fares(id),
    rider_id INTEGER REFERENCES riders(id),
    driver_id INTEGER REFERENCES drivers(id),
    status VARCHAR(30) DEFAULT 'requested'
        CHECK (status IN (
            'requested',       -- rider tapped "Request Ride"
            'matching',        -- system is looking for a driver
            'driver_assigned', -- driver found, waiting for accept/decline
            'accepted',        -- driver accepted
            'en_route',        -- driver is driving to pickup
            'arrived',         -- driver arrived at pickup
            'in_progress',     -- rider picked up, heading to destination
            'completed',       -- ride finished
            'cancelled'        -- rider or driver cancelled
        )),
    pickup_location GEOGRAPHY(POINT, 4326),
    dropoff_location GEOGRAPHY(POINT, 4326),
    actual_fare DECIMAL(10,2),
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP,
    pickup_at TIMESTAMP,
    dropoff_at TIMESTAMP,
    cancelled_at TIMESTAMP
);

-- Surge pricing zones: tracks demand/supply per geographic cell
CREATE TABLE surge_zones (
    id SERIAL PRIMARY KEY,
    zone_name VARCHAR(100),
    center GEOGRAPHY(POINT, 4326) NOT NULL,
    radius_km DECIMAL(6,2) DEFAULT 2.0,
    current_demand INTEGER DEFAULT 0,   -- ride requests in last window
    current_supply INTEGER DEFAULT 0,   -- available drivers in zone
    surge_multiplier DECIMAL(4,2) DEFAULT 1.00,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_surge_zones_geo ON surge_zones USING GIST (center);

-- ============================================================
-- Seed Data — San Francisco area
-- ============================================================

-- Riders
INSERT INTO riders (name, email, phone) VALUES
    ('Alice Johnson',  'alice@example.com',  '555-0101'),
    ('Bob Smith',      'bob@example.com',    '555-0102'),
    ('Carol Williams', 'carol@example.com',  '555-0103'),
    ('Dave Brown',     'dave@example.com',   '555-0104'),
    ('Eve Davis',      'eve@example.com',    '555-0105'),
    ('Frank Miller',   'frank@example.com',  '555-0106'),
    ('Grace Wilson',   'grace@example.com',  '555-0107'),
    ('Hank Moore',     'hank@example.com',   '555-0108'),
    ('Ivy Taylor',     'ivy@example.com',    '555-0109'),
    ('Jack Anderson',  'jack@example.com',   '555-0110');

-- Drivers (scattered around San Francisco)
INSERT INTO drivers (name, email, phone, vehicle_make, vehicle_model, vehicle_year, license_plate, status) VALUES
    ('Driver Alex',    'alex.d@example.com',    '555-0201', 'Toyota',  'Camry',   2022, 'ABC-1234', 'available'),
    ('Driver Bella',   'bella.d@example.com',   '555-0202', 'Honda',   'Civic',   2023, 'DEF-5678', 'available'),
    ('Driver Carlos',  'carlos.d@example.com',  '555-0203', 'Ford',    'Escape',  2021, 'GHI-9012', 'available'),
    ('Driver Diana',   'diana.d@example.com',   '555-0204', 'Tesla',   'Model 3', 2023, 'JKL-3456', 'available'),
    ('Driver Ethan',   'ethan.d@example.com',   '555-0205', 'Hyundai', 'Sonata',  2022, 'MNO-7890', 'available'),
    ('Driver Fiona',   'fiona.d@example.com',   '555-0206', 'Nissan',  'Altima',  2021, 'PQR-1234', 'offline'),
    ('Driver George',  'george.d@example.com',  '555-0207', 'Chevy',   'Malibu',  2023, 'STU-5678', 'available'),
    ('Driver Hannah',  'hannah.d@example.com',  '555-0208', 'Subaru',  'Outback', 2022, 'VWX-9012', 'available'),
    ('Driver Ivan',    'ivan.d@example.com',    '555-0209', 'Kia',     'Optima',  2021, 'YZA-3456', 'busy'),
    ('Driver Julia',   'julia.d@example.com',   '555-0210', 'Mazda',   'CX-5',   2023, 'BCD-7890', 'available');

-- Driver locations in San Francisco (longitude, latitude)
-- PostGIS uses ST_MakePoint(longitude, latitude)
INSERT INTO driver_locations (driver_id, location) VALUES
    (1,  ST_SetSRID(ST_MakePoint(-122.4194, 37.7749), 4326)),  -- Downtown SF
    (2,  ST_SetSRID(ST_MakePoint(-122.4089, 37.7837), 4326)),  -- Union Square
    (3,  ST_SetSRID(ST_MakePoint(-122.3930, 37.7956), 4326)),  -- North Beach
    (4,  ST_SetSRID(ST_MakePoint(-122.4378, 37.7594), 4326)),  -- Castro
    (5,  ST_SetSRID(ST_MakePoint(-122.4580, 37.7694), 4326)),  -- Sunset
    (6,  ST_SetSRID(ST_MakePoint(-122.4343, 37.8024), 4326)),  -- Marina
    (7,  ST_SetSRID(ST_MakePoint(-122.4862, 37.7568), 4326)),  -- Outer Sunset
    (8,  ST_SetSRID(ST_MakePoint(-122.4103, 37.7627), 4326)),  -- Mission
    (9,  ST_SetSRID(ST_MakePoint(-122.3895, 37.7867), 4326)),  -- Embarcadero
    (10, ST_SetSRID(ST_MakePoint(-122.4474, 37.7229), 4326));  -- Daly City border

-- Surge zones around SF hotspots
INSERT INTO surge_zones (zone_name, center, radius_km) VALUES
    ('Downtown/Financial',  ST_SetSRID(ST_MakePoint(-122.4000, 37.7900), 4326), 1.5),
    ('SoMa/Convention',     ST_SetSRID(ST_MakePoint(-122.4000, 37.7800), 4326), 1.0),
    ('Mission District',    ST_SetSRID(ST_MakePoint(-122.4200, 37.7600), 4326), 1.5),
    ('Castro/Noe Valley',   ST_SetSRID(ST_MakePoint(-122.4350, 37.7600), 4326), 1.0),
    ('Marina/Cow Hollow',   ST_SetSRID(ST_MakePoint(-122.4350, 37.8000), 4326), 1.0),
    ('SFO Airport',         ST_SetSRID(ST_MakePoint(-122.3790, 37.6213), 4326), 3.0);

-- A few sample completed rides for the lifecycle notebook
INSERT INTO fares (rider_id, pickup_location, dropoff_location, distance_km, estimated_duration_min, base_fare, surge_multiplier, estimated_fare) VALUES
    (1, ST_SetSRID(ST_MakePoint(-122.4194, 37.7749), 4326),
        ST_SetSRID(ST_MakePoint(-122.3895, 37.7867), 4326),
        3.2, 12, 8.50, 1.00, 8.50),
    (2, ST_SetSRID(ST_MakePoint(-122.4089, 37.7837), 4326),
        ST_SetSRID(ST_MakePoint(-122.4580, 37.7694), 4326),
        5.1, 18, 12.00, 1.50, 18.00),
    (3, ST_SetSRID(ST_MakePoint(-122.3930, 37.7956), 4326),
        ST_SetSRID(ST_MakePoint(-122.3790, 37.6213), 4326),
        19.5, 25, 35.00, 1.00, 35.00);

INSERT INTO rides (fare_id, rider_id, driver_id, status, pickup_location, dropoff_location, actual_fare, requested_at, accepted_at, pickup_at, dropoff_at) VALUES
    (1, 1, 1, 'completed',
        ST_SetSRID(ST_MakePoint(-122.4194, 37.7749), 4326),
        ST_SetSRID(ST_MakePoint(-122.3895, 37.7867), 4326),
        9.00,
        NOW() - INTERVAL '2 hours',
        NOW() - INTERVAL '1 hour 58 minutes',
        NOW() - INTERVAL '1 hour 55 minutes',
        NOW() - INTERVAL '1 hour 43 minutes'),
    (2, 2, 2, 'completed',
        ST_SetSRID(ST_MakePoint(-122.4089, 37.7837), 4326),
        ST_SetSRID(ST_MakePoint(-122.4580, 37.7694), 4326),
        19.50,
        NOW() - INTERVAL '1 hour',
        NOW() - INTERVAL '58 minutes',
        NOW() - INTERVAL '54 minutes',
        NOW() - INTERVAL '36 minutes');
