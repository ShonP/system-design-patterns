-- Top-K Lab Demo Database
-- Simulates a video platform with view events for top-k analysis

-- Videos table — each video on the platform
CREATE TABLE videos (
    id SERIAL PRIMARY KEY,
    video_id VARCHAR(16) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    channel VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- View events — one row per view (raw event stream)
CREATE TABLE view_events (
    id BIGSERIAL PRIMARY KEY,
    video_id VARCHAR(16) NOT NULL REFERENCES videos(video_id),
    viewed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Hourly aggregates — pre-computed counts per video per hour (tumbling window)
CREATE TABLE hourly_views (
    video_id VARCHAR(16) NOT NULL REFERENCES videos(video_id),
    hour_bucket TIMESTAMP NOT NULL,
    view_count INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (video_id, hour_bucket)
);

-- All-time view totals — running counter per video
CREATE TABLE video_view_totals (
    video_id VARCHAR(16) NOT NULL PRIMARY KEY REFERENCES videos(video_id),
    total_views BIGINT NOT NULL DEFAULT 0
);

-- Indexes for fast top-k queries
CREATE INDEX idx_hourly_views_bucket ON hourly_views(hour_bucket);
CREATE INDEX idx_hourly_views_count ON hourly_views(view_count DESC);
CREATE INDEX idx_video_view_totals_views ON video_view_totals(total_views DESC);
CREATE INDEX idx_view_events_time ON view_events(viewed_at);

-- ============================================================
-- Seed data
-- ============================================================

-- 50 sample videos across different channels
INSERT INTO videos (video_id, title, channel) VALUES
    ('vid_001', 'Learn Python in 10 Minutes', 'CodeAcademy'),
    ('vid_002', 'Top 10 Travel Destinations', 'Wanderlust'),
    ('vid_003', 'Easy Pasta Recipe', 'ChefMike'),
    ('vid_004', 'Morning Yoga Routine', 'FitLife'),
    ('vid_005', 'Guitar Tutorial for Beginners', 'MusicMasters'),
    ('vid_006', 'How Computers Work', 'TechExplained'),
    ('vid_007', 'Best Movie Scenes 2025', 'CinemaFans'),
    ('vid_008', 'DIY Home Renovation', 'HandyDan'),
    ('vid_009', 'Space Exploration Documentary', 'CosmosTV'),
    ('vid_010', 'Funny Cat Compilation', 'PetWorld'),
    ('vid_011', 'Intro to Machine Learning', 'CodeAcademy'),
    ('vid_012', 'Street Food Around the World', 'Wanderlust'),
    ('vid_013', 'Chocolate Cake Tutorial', 'ChefMike'),
    ('vid_014', 'HIIT Workout 20 Minutes', 'FitLife'),
    ('vid_015', 'Piano Lessons Episode 1', 'MusicMasters'),
    ('vid_016', 'How the Internet Works', 'TechExplained'),
    ('vid_017', 'Anime Review 2025', 'CinemaFans'),
    ('vid_018', 'Budget Kitchen Makeover', 'HandyDan'),
    ('vid_019', 'Mars Mission Update', 'CosmosTV'),
    ('vid_020', 'Puppy Training 101', 'PetWorld'),
    ('vid_021', 'System Design Interview Tips', 'CodeAcademy'),
    ('vid_022', 'Hidden Gems in Europe', 'Wanderlust'),
    ('vid_023', 'Sushi Making at Home', 'ChefMike'),
    ('vid_024', 'Running for Beginners', 'FitLife'),
    ('vid_025', 'Drum Beat Patterns', 'MusicMasters'),
    ('vid_026', 'How Databases Work', 'TechExplained'),
    ('vid_027', 'Oscar Predictions 2026', 'CinemaFans'),
    ('vid_028', 'Bathroom Tile Guide', 'HandyDan'),
    ('vid_029', 'Black Hole Explained', 'CosmosTV'),
    ('vid_030', 'Bird Watching Tips', 'PetWorld'),
    ('vid_031', 'Docker for Beginners', 'CodeAcademy'),
    ('vid_032', 'Japan Travel Vlog', 'Wanderlust'),
    ('vid_033', 'BBQ Ribs Recipe', 'ChefMike'),
    ('vid_034', 'Meditation Guide', 'FitLife'),
    ('vid_035', 'Ukulele Songs Easy', 'MusicMasters'),
    ('vid_036', 'AI in 2026', 'TechExplained'),
    ('vid_037', 'Horror Movie Rankings', 'CinemaFans'),
    ('vid_038', 'Garden Shed Build', 'HandyDan'),
    ('vid_039', 'James Webb Discoveries', 'CosmosTV'),
    ('vid_040', 'Aquarium Setup Guide', 'PetWorld'),
    ('vid_041', 'Kubernetes Explained', 'CodeAcademy'),
    ('vid_042', 'Iceland Road Trip', 'Wanderlust'),
    ('vid_043', 'Bread Baking Basics', 'ChefMike'),
    ('vid_044', 'Stretching Routine', 'FitLife'),
    ('vid_045', 'Music Theory 101', 'MusicMasters'),
    ('vid_046', 'Quantum Computing Intro', 'TechExplained'),
    ('vid_047', 'Sci-Fi Movie Marathon', 'CinemaFans'),
    ('vid_048', 'Deck Building Tips', 'HandyDan'),
    ('vid_049', 'Solar System Tour', 'CosmosTV'),
    ('vid_050', 'Hamster Care Guide', 'PetWorld');

-- Generate view events over the last 48 hours with a Zipf-like distribution
-- (some videos get WAY more views than others, just like real life)
INSERT INTO view_events (video_id, viewed_at)
SELECT
    v.video_id,
    NOW() - (random() * interval '48 hours')
FROM
    -- Repeat each video a number of times based on its "popularity"
    -- vid_001 gets ~500 views, vid_010 gets ~800 (viral!), etc.
    generate_series(1, 50) AS vid_num,
    videos v,
    generate_series(1,
        CASE
            WHEN v.video_id = 'vid_010' THEN 80  -- viral video
            WHEN v.video_id = 'vid_001' THEN 50  -- very popular
            WHEN v.video_id = 'vid_021' THEN 45  -- trending
            WHEN v.video_id = 'vid_003' THEN 40
            WHEN v.video_id = 'vid_036' THEN 35
            WHEN v.video_id IN ('vid_007','vid_032','vid_002') THEN 25
            WHEN v.video_id IN ('vid_011','vid_015','vid_029','vid_042') THEN 15
            ELSE greatest(1, (5 - (substring(v.video_id from 5)::int / 10))::int)
        END
    ) AS repeat_num
WHERE vid_num = substring(v.video_id from 5)::int;

-- Populate hourly aggregates from the raw events
INSERT INTO hourly_views (video_id, hour_bucket, view_count)
SELECT
    video_id,
    date_trunc('hour', viewed_at) AS hour_bucket,
    COUNT(*) AS view_count
FROM view_events
GROUP BY video_id, date_trunc('hour', viewed_at);

-- Populate all-time totals
INSERT INTO video_view_totals (video_id, total_views)
SELECT video_id, COUNT(*)
FROM view_events
GROUP BY video_id;
