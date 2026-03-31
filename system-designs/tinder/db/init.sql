-- ============================================================
-- Tinder System Design Lab — Database Schema
-- Uses PostGIS for geospatial queries (finding nearby users)
-- ============================================================

-- Enable PostGIS for geographic data types and spatial queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================
-- Core Tables
-- ============================================================

-- Users: people on the dating app
-- Each user has a profile with preferences and a current location
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    age INTEGER NOT NULL CHECK (age >= 18),
    gender VARCHAR(20) NOT NULL CHECK (gender IN ('male', 'female', 'non_binary')),
    bio TEXT,
    interested_in VARCHAR(20) NOT NULL CHECK (interested_in IN ('male', 'female', 'both')),
    age_min INTEGER DEFAULT 18,
    age_max INTEGER DEFAULT 100,
    max_distance_km INTEGER DEFAULT 50,
    location GEOGRAPHY(POINT, 4326),  -- current GPS position (lng, lat)
    is_active BOOLEAN DEFAULT TRUE,
    last_active TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Spatial index so PostGIS proximity queries are fast
CREATE INDEX idx_users_location ON users USING GIST (location);

-- Index on filters used for feed generation
CREATE INDEX idx_users_gender ON users(gender);
CREATE INDEX idx_users_age ON users(age);

-- Swipes: a record of one user swiping on another
-- direction is 'right' (like) or 'left' (pass)
CREATE TABLE swipes (
    id SERIAL PRIMARY KEY,
    swiper_id INTEGER NOT NULL REFERENCES users(id),
    target_id INTEGER NOT NULL REFERENCES users(id),
    direction VARCHAR(5) NOT NULL CHECK (direction IN ('right', 'left')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(swiper_id, target_id)  -- a user can only swipe once on another user
);

CREATE INDEX idx_swipes_swiper ON swipes(swiper_id);
CREATE INDEX idx_swipes_target ON swipes(target_id);
CREATE INDEX idx_swipes_pair ON swipes(swiper_id, target_id);

-- Matches: created when two users both swipe right on each other
CREATE TABLE matches (
    id SERIAL PRIMARY KEY,
    user1_id INTEGER NOT NULL REFERENCES users(id),
    user2_id INTEGER NOT NULL REFERENCES users(id),
    matched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user1_id, user2_id)
);

CREATE INDEX idx_matches_user1 ON matches(user1_id);
CREATE INDEX idx_matches_user2 ON matches(user2_id);

-- Notifications: tracks match notifications sent to users
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    type VARCHAR(50) NOT NULL DEFAULT 'match',
    message TEXT NOT NULL,
    match_id INTEGER REFERENCES matches(id),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);

-- ============================================================
-- Seed Data — Los Angeles area
-- 20 sample users scattered around LA for realistic demos
-- ============================================================

INSERT INTO users (name, email, age, gender, bio, interested_in, age_min, age_max, max_distance_km, location) VALUES
    -- Female users
    ('Emma Chen',       'emma@example.com',    25, 'female', 'Coffee addict ☕ Love hiking and photography',         'male',   22, 32, 15,  ST_SetSRID(ST_MakePoint(-118.2437, 34.0522), 4326)),  -- Downtown LA
    ('Sofia Garcia',    'sofia@example.com',   28, 'female', 'Yoga instructor 🧘 Dog mom 🐕',                       'male',   25, 35, 20,  ST_SetSRID(ST_MakePoint(-118.3965, 34.0195), 4326)),  -- Culver City
    ('Olivia Kim',      'olivia@example.com',  23, 'female', 'UCLA grad 🎓 Foodie exploring LA one taco at a time', 'male',   21, 30, 10,  ST_SetSRID(ST_MakePoint(-118.4452, 34.0689), 4326)),  -- Westwood
    ('Mia Taylor',      'mia@example.com',     30, 'female', 'Screenwriter by day, karaoke queen by night 🎤',      'male',   26, 38, 25,  ST_SetSRID(ST_MakePoint(-118.3287, 34.0928), 4326)),  -- Hollywood
    ('Ava Martinez',    'ava@example.com',     26, 'female', 'Beach volleyball 🏐 and sunset chaser 🌅',            'both',   22, 34, 20,  ST_SetSRID(ST_MakePoint(-118.4695, 33.9850), 4326)),  -- Venice Beach
    ('Luna Park',       'luna@example.com',    24, 'female', 'K-pop fan 🎵 Boba tea enthusiast 🧋',                 'male',   22, 30, 10,  ST_SetSRID(ST_MakePoint(-118.3060, 34.0700), 4326)),  -- Koreatown
    ('Zoe Johnson',     'zoe@example.com',     27, 'female', 'Tech startup founder 💻 Weekend rock climber',        'male',   24, 34, 30,  ST_SetSRID(ST_MakePoint(-118.4004, 33.9425), 4326)),  -- El Segundo
    ('Isla Rivera',     'isla@example.com',    22, 'female', 'Art student 🎨 Museum hopper',                        'male',   20, 28, 15,  ST_SetSRID(ST_MakePoint(-118.2500, 34.0480), 4326)),  -- Arts District
    ('Chloe Brown',     'chloe@example.com',   29, 'female', 'Nurse 🏥 Marathon runner 🏃‍♀️',                     'male',   25, 36, 20,  ST_SetSRID(ST_MakePoint(-118.1553, 34.0195), 4326)),  -- Alhambra
    ('Aria Williams',   'aria@example.com',    31, 'female', 'Music producer 🎧 Cat person 🐱',                    'both',   26, 40, 25,  ST_SetSRID(ST_MakePoint(-118.3723, 34.0901), 4326)),  -- West Hollywood

    -- Male users
    ('James Wilson',    'james@example.com',   27, 'male',   'Software engineer 💻 Weekend surfer 🏄',              'female', 23, 32, 15,  ST_SetSRID(ST_MakePoint(-118.4920, 34.0118), 4326)),  -- Santa Monica
    ('Ethan Davis',     'ethan@example.com',   29, 'male',   'Chef 👨‍🍳 Always looking for the best ramen spot',  'female', 24, 34, 20,  ST_SetSRID(ST_MakePoint(-118.2606, 34.0478), 4326)),  -- Little Tokyo
    ('Liam Anderson',   'liam@example.com',    25, 'male',   'Gym rat 💪 Golden retriever dad',                     'female', 22, 30, 10,  ST_SetSRID(ST_MakePoint(-118.3533, 34.0561), 4326)),  -- Mid-Wilshire
    ('Noah Thompson',   'noah@example.com',    31, 'male',   'Architect 🏗️ Design nerd and vinyl collector',       'female', 25, 36, 25,  ST_SetSRID(ST_MakePoint(-118.2284, 34.0581), 4326)),  -- Boyle Heights
    ('Lucas White',     'lucas@example.com',   24, 'male',   'Film school student 🎬 Aspiring director',            'female', 21, 29, 15,  ST_SetSRID(ST_MakePoint(-118.3408, 34.0983), 4326)),  -- Hollywood Hills
    ('Oliver Lee',      'oliver@example.com',  28, 'male',   'Doctor 🏥 Tennis on weekends 🎾',                    'female', 24, 34, 20,  ST_SetSRID(ST_MakePoint(-118.1445, 34.1478), 4326)),  -- Pasadena
    ('Mason Clark',     'mason@example.com',   26, 'male',   'Musician 🎸 Plays at local bars on Fridays',          'both',   22, 32, 30,  ST_SetSRID(ST_MakePoint(-118.2816, 34.0244), 4326)),  -- USC area
    ('Aiden Harris',    'aiden@example.com',   23, 'male',   'Personal trainer 🏋️ Smoothie addict 🥤',            'female', 20, 28, 15,  ST_SetSRID(ST_MakePoint(-118.3965, 34.0260), 4326)),  -- Mar Vista
    ('Daniel Scott',    'daniel@example.com',  30, 'male',   'Lawyer ⚖️ Bookworm and coffee snob',                 'female', 26, 35, 20,  ST_SetSRID(ST_MakePoint(-118.1750, 34.0560), 4326)),  -- South Pasadena
    ('Jack Robinson',   'jack@example.com',    32, 'male',   'Firefighter 🚒 BBQ master 🍖',                       'female', 26, 38, 25,  ST_SetSRID(ST_MakePoint(-118.3090, 33.9425), 4326));  -- Gardena

-- ============================================================
-- Seed some swipes for demo purposes
-- (some mutual likes that form matches, some one-sided)
-- ============================================================

-- Mutual likes (these will become matches in the notebook demos)
INSERT INTO swipes (swiper_id, target_id, direction) VALUES
    (1, 11, 'right'),   -- Emma likes James
    (11, 1, 'right'),   -- James likes Emma → MATCH!
    (2, 12, 'right'),   -- Sofia likes Ethan
    (12, 2, 'right'),   -- Ethan likes Sofia → MATCH!
    (3, 13, 'right'),   -- Olivia likes Liam
    (13, 3, 'right');   -- Liam likes Olivia → MATCH!

-- One-sided swipes (no match yet)
INSERT INTO swipes (swiper_id, target_id, direction) VALUES
    (4, 14, 'right'),   -- Mia likes Noah (Noah hasn't swiped yet)
    (5, 15, 'right'),   -- Ava likes Lucas (Lucas hasn't swiped yet)
    (16, 6, 'right'),   -- Oliver likes Luna (Luna hasn't swiped yet)
    (7, 17, 'left'),    -- Zoe passed on Mason
    (8, 18, 'left'),    -- Isla passed on Aiden
    (19, 9, 'right'),   -- Daniel likes Chloe (Chloe hasn't swiped yet)
    (20, 10, 'right');  -- Jack likes Aria (Aria hasn't swiped yet)

-- Pre-existing matches from the mutual swipes above
INSERT INTO matches (user1_id, user2_id) VALUES
    (1, 11),   -- Emma & James
    (2, 12),   -- Sofia & Ethan
    (3, 13);   -- Olivia & Liam

-- Sample notifications
INSERT INTO notifications (user_id, type, message, match_id) VALUES
    (1,  'match', '🎉 You matched with James Wilson!',  1),
    (11, 'match', '🎉 You matched with Emma Chen!',     1),
    (2,  'match', '🎉 You matched with Ethan Davis!',   2),
    (12, 'match', '🎉 You matched with Sofia Garcia!',  2),
    (3,  'match', '🎉 You matched with Liam Anderson!', 3),
    (13, 'match', '🎉 You matched with Olivia Kim!',    3);
