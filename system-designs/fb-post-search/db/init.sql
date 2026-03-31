-- FB Post Search Lab — Database Schema and Seed Data
-- Models a simplified Facebook-like social network for search experiments

-- ============================================================
-- Schema
-- ============================================================

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(200) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    content TEXT NOT NULL,
    like_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE likes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    post_id INTEGER REFERENCES posts(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, post_id)
);

-- Indexes for common queries
CREATE INDEX idx_posts_user ON posts(user_id);
CREATE INDEX idx_posts_created ON posts(created_at DESC);
CREATE INDEX idx_posts_likes ON posts(like_count DESC);
CREATE INDEX idx_likes_post ON likes(post_id);

-- ============================================================
-- Seed Data — Users
-- ============================================================

INSERT INTO users (username, display_name) VALUES
    ('alice_dev',       'Alice Johnson'),
    ('bob_builder',     'Bob Smith'),
    ('carol_codes',     'Carol Williams'),
    ('dave_data',       'Dave Brown'),
    ('eve_engineer',    'Eve Davis'),
    ('frank_fullstack', 'Frank Miller'),
    ('grace_gopher',    'Grace Wilson'),
    ('henry_hacker',    'Henry Moore'),
    ('iris_infra',      'Iris Taylor'),
    ('jack_java',       'Jack Anderson'),
    ('karen_kotlin',    'Karen Thomas'),
    ('leo_linux',       'Leo Jackson'),
    ('mia_ml',          'Mia White'),
    ('noah_node',       'Noah Harris'),
    ('olivia_ops',      'Olivia Martin');

-- Generate 85 more users to reach 100 total
INSERT INTO users (username, display_name)
SELECT
    'user_' || i,
    'User Number ' || i
FROM generate_series(16, 100) AS i;

-- ============================================================
-- Seed Data — Posts (realistic social media content)
-- ============================================================

-- Hand-crafted posts with diverse, searchable content
INSERT INTO posts (user_id, content, like_count, created_at) VALUES
-- Tech and programming posts
(1,  'Just finished building a REST API with Python and FastAPI. The automatic docs are amazing! 🚀', 234, NOW() - interval '2 hours'),
(2,  'Docker containers changed how I think about deployment. No more "works on my machine" problems!', 567, NOW() - interval '5 hours'),
(3,  'Learning Kubernetes this week. The learning curve is steep but the orchestration power is incredible.', 123, NOW() - interval '1 day'),
(4,  'Big data processing with Apache Spark is fascinating. Processed 1TB of data in under 10 minutes today.', 89, NOW() - interval '1 day'),
(5,  'Machine learning tip: always normalize your features before training. Spent 3 hours debugging this.', 345, NOW() - interval '2 days'),
(6,  'React vs Vue debate again at the office. I think both are great tools, just pick one and ship! 🛠️', 678, NOW() - interval '2 days'),
(7,  'PostgreSQL is underrated. Full-text search, JSON support, and incredible reliability. Love it.', 901, NOW() - interval '3 days'),
(8,  'Wrote my first Rust program today. The borrow checker is strict but it catches so many bugs at compile time.', 456, NOW() - interval '3 days'),
(9,  'System design interview prep: the key is understanding trade-offs, not memorizing solutions.', 1234, NOW() - interval '4 days'),
(10, 'TypeScript has made JavaScript so much better. Static types catch bugs before they reach production.', 789, NOW() - interval '4 days'),

-- Food and cooking posts
(11, 'Made homemade pasta from scratch today. Fresh pasta is on a completely different level than dried!', 432, NOW() - interval '5 days'),
(12, 'Best pizza I have ever had was in Naples, Italy. The simplicity of margherita pizza is perfection.', 876, NOW() - interval '5 days'),
(1,  'Tried making sourdough bread again. This time the crust was perfect! Patience is the secret ingredient.', 543, NOW() - interval '6 days'),
(2,  'Sunday morning pancakes with maple syrup and fresh berries. Simple breakfast, pure happiness. 🥞', 321, NOW() - interval '6 days'),
(3,  'Discovered a tiny ramen shop in Tokyo that changed my life. The broth was simmered for 18 hours!', 1567, NOW() - interval '7 days'),

-- Travel posts
(4,  'Hiking through the Swiss Alps was breathtaking. The mountains and lakes are like a painting come to life.', 2345, NOW() - interval '8 days'),
(5,  'Tokyo is the most fascinating city I have visited. Ancient temples next to neon-lit skyscrapers.', 1890, NOW() - interval '9 days'),
(6,  'Road trip along the California coast. Big Sur is absolutely stunning at sunset. 🌅', 1456, NOW() - interval '10 days'),
(7,  'Visited the ancient ruins of Machu Picchu. Standing above the clouds was a spiritual experience.', 2100, NOW() - interval '11 days'),
(8,  'Paris in spring is magical. Cherry blossoms along the Seine, croissants, and cafe culture.', 1678, NOW() - interval '12 days'),

-- Fitness and health
(9,  'Ran my first marathon today! 26.2 miles of pure determination. My legs are destroyed but my spirit is soaring.', 3456, NOW() - interval '13 days'),
(10, 'Morning yoga has transformed my productivity. 20 minutes of stretching sets the tone for the entire day.', 890, NOW() - interval '14 days'),
(11, 'Started swimming laps this month. Great cardio workout and so much easier on the joints than running.', 234, NOW() - interval '15 days'),
(12, 'Meal prep Sunday! Cooked chicken, rice, and veggies for the whole week. Healthy eating made easy.', 567, NOW() - interval '16 days'),
(1,  'Sleep is the most underrated performance enhancer. Since getting 8 hours consistently, everything improved.', 1234, NOW() - interval '17 days'),

-- Music and entertainment
(2,  'Just saw Taylor Swift in concert. The production quality and energy were absolutely incredible!', 4567, NOW() - interval '18 days'),
(3,  'Learning guitar is humbling. Three months in and my fingers still hurt but I can play basic chords now.', 345, NOW() - interval '19 days'),
(4,  'The new album from Kendrick Lamar is a masterpiece. Every track tells a story.', 2345, NOW() - interval '20 days'),
(5,  'Vinyl records sound warmer than digital. There is something magical about the crackle and pop.', 678, NOW() - interval '21 days'),
(6,  'Movie night recommendation: watching Interstellar again. The soundtrack by Hans Zimmer gives me chills every time.', 1890, NOW() - interval '22 days'),

-- Science and nature
(7,  'The James Webb telescope images are mind-blowing. We are looking at galaxies billions of light-years away!', 5678, NOW() - interval '23 days'),
(8,  'Planted a vegetable garden this spring. Watching tomatoes grow from tiny seeds is incredibly rewarding.', 432, NOW() - interval '24 days'),
(9,  'Climate change is the defining challenge of our generation. Small daily actions add up to big impact.', 2345, NOW() - interval '25 days'),
(10, 'Went stargazing in the desert last night. Zero light pollution and the Milky Way was clearly visible.', 3456, NOW() - interval '26 days'),
(11, 'Fascinating documentary about octopus intelligence. These creatures can solve puzzles and use tools!', 1234, NOW() - interval '27 days'),

-- Life and philosophy
(12, 'The best advice I ever received: focus on what you can control and let go of what you cannot.', 6789, NOW() - interval '28 days'),
(1,  'Remote work has given me back 2 hours a day that I used to spend commuting. Life-changing.', 3456, NOW() - interval '29 days'),
(2,  'Reading 30 minutes before bed instead of scrolling social media. My sleep quality improved dramatically.', 2345, NOW() - interval '30 days'),
(3,  'Gratitude journaling for 30 days straight. It genuinely shifts your perspective on daily life.', 1234, NOW() - interval '31 days'),
(4,  'Learned more from failing at my startup than I did in 4 years of university. Failure is the best teacher.', 4567, NOW() - interval '32 days'),

-- More tech posts for search variety
(5,  'Elasticsearch makes full-text search feel like magic. Inverted indexes are brilliant data structures.', 890, NOW() - interval '33 days'),
(6,  'Building a search engine from scratch taught me more about computer science than any textbook.', 567, NOW() - interval '34 days'),
(7,  'Redis sorted sets are perfect for leaderboards and ranking systems. Simple yet powerful.', 345, NOW() - interval '35 days'),
(8,  'Caching is not just about speed. It is about protecting your database from being overwhelmed by reads.', 678, NOW() - interval '36 days'),
(9,  'Inverted indexes explained simply: instead of searching every document for a word, you look up which documents contain that word. Like a book index!', 1234, NOW() - interval '37 days'),
(10, 'The difference between searching and browsing: search is pull (you ask), browsing is push (algorithm suggests).', 456, NOW() - interval '38 days'),
(11, 'Apache Kafka for event streaming is like a conveyor belt that never stops. Perfect for real-time data pipelines.', 789, NOW() - interval '39 days'),
(12, 'GraphQL vs REST: GraphQL lets the client ask for exactly what it needs. Less over-fetching, more flexibility.', 567, NOW() - interval '40 days'),
(1,  'Microservices are not always the answer. Start with a monolith and split when you actually need to scale.', 2345, NOW() - interval '41 days'),
(2,  'Database indexing is like adding a table of contents to a book. Without it, you read every page to find anything.', 1890, NOW() - interval '42 days'),

-- Taylor Swift related posts (for multi-keyword search demos)
(3,  'Taylor Swift Eras Tour broke every concert record. The setlist spans her entire career beautifully.', 8901, NOW() - interval '43 days'),
(4,  'My cat is named Taylor and she is swift at catching mice. Best name choice ever!', 234, NOW() - interval '44 days'),
(5,  'Taylor made a swift decision to learn programming. Three months later she built her first app!', 123, NOW() - interval '45 days'),

-- Posts with common words for relevance ranking demos
(6,  'The best coffee shop in San Francisco serves the most amazing pour-over coffee. Worth the wait!', 345, NOW() - interval '46 days'),
(7,  'Coffee is fuel for programmers. My morning ritual: brew coffee, open terminal, start coding.', 678, NOW() - interval '47 days'),
(8,  'Tried quitting coffee for a month. Worst month of my life. Coffee and I are back together forever.', 1234, NOW() - interval '48 days'),
(9,  'The science behind coffee: caffeine blocks adenosine receptors, which is why it keeps you awake.', 456, NOW() - interval '49 days'),
(10, 'Cold brew coffee recipe: coarse grounds, cold water, 12 hours in the fridge. Smooth and strong!', 890, NOW() - interval '50 days');

-- Generate 450 more posts with varied content for realistic search testing
INSERT INTO posts (user_id, content, like_count, created_at)
SELECT
    (floor(random() * 100) + 1)::int,
    CASE (i % 20)
        WHEN 0  THEN 'Working on a new project with Python and machine learning. The results are promising!'
        WHEN 1  THEN 'Beautiful sunset at the beach today. Nature never disappoints. 🌅'
        WHEN 2  THEN 'Just deployed my first application to the cloud. Feels great to see it live!'
        WHEN 3  THEN 'Reading a fascinating book about distributed systems and data replication.'
        WHEN 4  THEN 'Home cooked meal tonight: grilled salmon with roasted vegetables and lemon.'
        WHEN 5  THEN 'Morning run through the park. Fresh air and exercise are the best way to start the day.'
        WHEN 6  THEN 'Learning about search engines and how they index billions of web pages efficiently.'
        WHEN 7  THEN 'Weekend hiking trip planned. Any trail recommendations near the mountains?'
        WHEN 8  THEN 'Database optimization tip: always check your query execution plan before blaming the hardware.'
        WHEN 9  THEN 'Watched an incredible documentary about space exploration and the Mars missions.'
        WHEN 10 THEN 'Coding challenge completed! Solved the algorithm problem using dynamic programming.'
        WHEN 11 THEN 'New coffee shop opened downtown. The espresso is strong and the atmosphere is perfect for working.'
        WHEN 12 THEN 'Team standup went well today. Everyone is aligned and shipping fast this sprint.'
        WHEN 13 THEN 'Photography tip: golden hour light makes everything look magical. Shoot during sunrise or sunset.'
        WHEN 14 THEN 'System design interviews are all about showing you understand trade-offs and can think at scale.'
        WHEN 15 THEN 'Made fresh guacamole for game night. The secret is using perfectly ripe avocados and lime juice.'
        WHEN 16 THEN 'Kubernetes pod scaling saved us during the traffic spike. Auto-scaling for the win!'
        WHEN 17 THEN 'Piano practice going well. Finally learned to play my favorite song after weeks of practice.'
        WHEN 18 THEN 'The importance of good documentation cannot be overstated. Future you will thank present you.'
        WHEN 19 THEN 'Exploring the city on a bicycle is the best way to discover hidden gems and local spots.'
    END || ' Post variation ' || i || '.',
    floor(random() * 5000 + 1)::int,
    NOW() - (random() * interval '180 days')
FROM generate_series(1, 450) AS i;

-- ============================================================
-- Generate Likes (sample interactions)
-- ============================================================

INSERT INTO likes (user_id, post_id, created_at)
SELECT
    (floor(random() * 100) + 1)::int,
    (floor(random() * 500) + 1)::int,
    NOW() - (random() * interval '60 days')
FROM generate_series(1, 3000) AS i
ON CONFLICT (user_id, post_id) DO NOTHING;
