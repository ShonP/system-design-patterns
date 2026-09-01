-- Yelp Lab Demo Database
-- Businesses, users, and reviews for a Yelp-like system

-- ============================================================
-- Enable PostGIS for geospatial queries and pg_trgm for fuzzy text search
-- ============================================================
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ============================================================
-- Tables
-- ============================================================

-- Categories for businesses (restaurants, coffee shops, etc.)
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

-- Businesses with geospatial location
CREATE TABLE businesses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    address VARCHAR(500),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    zip_code VARCHAR(20),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location GEOGRAPHY(POINT, 4326),  -- PostGIS geography column
    category_id INTEGER REFERENCES categories(id),
    phone VARCHAR(20),
    website VARCHAR(255),
    price_range INTEGER CHECK (price_range >= 1 AND price_range <= 4),  -- $ to $$$$
    avg_rating DECIMAL(3,2) DEFAULT 0,   -- DERIVED display value: rating_sum / num_reviews
    rating_sum INTEGER NOT NULL DEFAULT 0,  -- exact numerator; integer addition commutes,
                                            -- so concurrent reviewers cannot disagree
    num_reviews INTEGER DEFAULT 0,
    is_open BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Users who search and leave reviews
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE NOT NULL,
    city VARCHAR(100),
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Reviews with one-review-per-user-per-business constraint
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    business_id INTEGER REFERENCES businesses(id) NOT NULL,
    user_id INTEGER REFERENCES users(id) NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
    text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_business UNIQUE (user_id, business_id)
);

-- ============================================================
-- Indexes
-- ============================================================

-- Geospatial index for fast proximity searches
CREATE INDEX idx_businesses_location ON businesses USING GIST (location);

-- B-tree indexes for common filters
CREATE INDEX idx_businesses_category ON businesses(category_id);
CREATE INDEX idx_businesses_city ON businesses(city);
CREATE INDEX idx_businesses_avg_rating ON businesses(avg_rating DESC);

-- Full-text search index on business name and description
CREATE INDEX idx_businesses_name_trgm ON businesses USING GIN (name gin_trgm_ops);

-- Review lookup indexes
CREATE INDEX idx_reviews_business ON reviews(business_id);
CREATE INDEX idx_reviews_user ON reviews(user_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);

-- ============================================================
-- Seed data
-- ============================================================

-- Pin random() for this session so `docker compose down -v && up -d` rebuilds
-- essentially the same 500 businesses and 3000 reviews instead of a fresh random
-- world every time, which makes the notebooks' printed numbers comparable across
-- rebuilds. (Caveat: the review generator uses DISTINCT ON without ORDER BY, so
-- which 3000 of the 5000 candidate pairs survive still depends on the plan.)
SELECT setseed(0.42);

-- Categories
INSERT INTO categories (name, description) VALUES
    ('Restaurants', 'Dining establishments serving prepared food'),
    ('Coffee & Tea', 'Cafes, coffee shops, and tea houses'),
    ('Bars & Nightlife', 'Bars, pubs, clubs, and lounges'),
    ('Shopping', 'Retail stores and boutiques'),
    ('Health & Medical', 'Doctors, dentists, and clinics'),
    ('Home Services', 'Plumbers, electricians, and contractors'),
    ('Auto Services', 'Mechanics, car washes, and dealerships'),
    ('Fitness & Gyms', 'Gyms, yoga studios, and fitness centers'),
    ('Beauty & Spas', 'Hair salons, spas, and barbershops'),
    ('Hotels & Travel', 'Hotels, hostels, and travel agencies');

-- Users (200 sample users)
INSERT INTO users (username, email, city)
SELECT
    'user_' || i,
    'user' || i || '@example.com',
    (ARRAY['New York', 'San Francisco', 'Los Angeles', 'Chicago', 'Seattle',
           'Austin', 'Portland', 'Denver', 'Boston', 'Miami'])[floor(random() * 10 + 1)::int]
FROM generate_series(1, 200) AS i;

-- Businesses (500 sample businesses across 5 cities)
-- We generate businesses clustered around real city centers
INSERT INTO businesses (
    name, description, address, city, state, zip_code,
    latitude, longitude, location,
    category_id, phone, price_range, is_open
)
SELECT
    -- Generate realistic business names
    (ARRAY['Golden', 'Silver', 'Blue', 'Red', 'Green', 'Happy', 'Lucky', 'Sunny', 'Fresh', 'Urban',
           'Downtown', 'City', 'Central', 'Grand', 'Royal', 'Pacific', 'Atlantic', 'Mountain', 'Valley', 'Bay'])[floor(random() * 20 + 1)::int]
    || ' ' ||
    (ARRAY['Dragon', 'Phoenix', 'Garden', 'Kitchen', 'House', 'Place', 'Corner', 'Point', 'Square', 'Bridge',
           'Harbor', 'Meadow', 'Creek', 'Ridge', 'Springs', 'Terrace', 'Plaza', 'Court', 'Park', 'Lane'])[floor(random() * 20 + 1)::int]
    || ' ' ||
    CASE ((i - 1) % 10)
        WHEN 0 THEN 'Restaurant'
        WHEN 1 THEN 'Cafe'
        WHEN 2 THEN 'Bar & Grill'
        WHEN 3 THEN 'Boutique'
        WHEN 4 THEN 'Clinic'
        WHEN 5 THEN 'Repairs'
        WHEN 6 THEN 'Auto Shop'
        WHEN 7 THEN 'Fitness'
        WHEN 8 THEN 'Spa'
        WHEN 9 THEN 'Inn'
    END,

    'A wonderful local business loved by the community. Come visit us!',

    floor(random() * 999 + 1)::int || ' ' ||
    (ARRAY['Main St', 'Broadway', 'Market St', 'Oak Ave', 'Elm St',
           'Pine Rd', 'Cedar Ln', 'Park Ave', 'Lake Dr', 'Hill Rd'])[floor(random() * 10 + 1)::int],

    -- City, state, zip, lat, lon — clustered around real city centers
    city_data.city,
    city_data.state,
    city_data.zip,
    city_data.base_lat + (random() - 0.5) * 0.1,   -- spread ±0.05 degrees (~5.5 km)
    city_data.base_lon + (random() - 0.5) * 0.1,
    NULL::geography,  -- `location` is derived from latitude/longitude below — see the note after this INSERT

    ((i - 1) % 10) + 1,  -- category 1-10
    '(' || (200 + floor(random() * 800))::int || ') ' || (100 + floor(random() * 900))::int || '-' || (1000 + floor(random() * 9000))::int,
    floor(random() * 4 + 1)::int,
    random() > 0.1  -- 90% are open

FROM generate_series(1, 500) AS i
CROSS JOIN LATERAL (
    SELECT *
    FROM (VALUES
        ('New York',      'NY', '10001', 40.7580, -73.9855),
        ('San Francisco', 'CA', '94102', 37.7749, -122.4194),
        ('Los Angeles',   'CA', '90001', 34.0522, -118.2437),
        ('Chicago',       'IL', '60601', 41.8781, -87.6298),
        ('Seattle',       'WA', '98101', 47.6062, -122.3321)
    ) AS cities(city, state, zip, base_lat, base_lon)
    OFFSET ((i - 1) % 5)
    LIMIT 1
) AS city_data;

-- Derive the PostGIS `location` column from the latitude/longitude columns.
--
-- This looks redundant, but it is the whole point: `location` is a DERIVED copy of
-- (longitude, latitude). If the two are ever computed independently they silently
-- drift apart, and then ST_DWithin (which reads `location`) and a plain lat/lon
-- bounding box (which reads the columns) answer the same question differently.
-- Deriving it in one statement from the stored columns makes that impossible.
-- Note the argument order: ST_MakePoint takes (X, Y) = (longitude, latitude).
UPDATE businesses
SET location = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography;

-- Reviews (3000 sample reviews — ~6 per business on average)
INSERT INTO reviews (business_id, user_id, rating, text, created_at)
SELECT
    biz_id,
    usr_id,
    floor(random() * 5 + 1)::int,
    (ARRAY[
        'Amazing experience! The staff was incredibly friendly and the service was top-notch.',
        'Pretty good overall. Would come back again for sure.',
        'Average experience. Nothing special but nothing terrible either.',
        'Not great. Had some issues with the wait time and the quality.',
        'Absolutely loved it! Best place in the neighborhood. Highly recommend!',
        'Decent spot. Good for a quick visit but nothing extraordinary.',
        'Terrible experience. Would not recommend to anyone.',
        'Solid choice in the area. Consistent quality every time I visit.',
        'Outstanding! Exceeded all my expectations. A hidden gem.',
        'It was okay. Some things were good, others could use improvement.'
    ])[floor(random() * 10 + 1)::int],
    NOW() - (random() * interval '365 days')
FROM (
    -- Generate unique (business_id, user_id) pairs to respect the unique constraint
    SELECT DISTINCT ON (biz_id, usr_id)
        (floor(random() * 500) + 1)::int AS biz_id,
        (floor(random() * 200) + 1)::int AS usr_id
    FROM generate_series(1, 5000) AS i
    LIMIT 3000
) AS pairs;

-- Update rating_sum, num_reviews and the derived avg_rating from actual review data.
-- Note avg_rating is computed from the same integers stored in rating_sum, so the seeded
-- state is exactly what an incremental `rating_sum + rating` update would have produced.
UPDATE businesses b SET
    rating_sum = sub.total,
    num_reviews = sub.cnt,
    avg_rating = ROUND(sub.total::numeric / sub.cnt, 2)
FROM (
    SELECT business_id, SUM(rating) AS total, COUNT(*) AS cnt
    FROM reviews
    GROUP BY business_id
) sub
WHERE b.id = sub.business_id;
