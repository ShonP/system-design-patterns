-- Vector Databases Lab
-- Demonstrates pgvector similarity search with movies and products

-- Enable the pgvector extension (pre-installed in pgvector/pgvector image)
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================
-- Movies table (used in notebooks 1 & 2)
-- 40 movies across 8 genres — embeddings are generated below
-- so that same-genre movies cluster together in vector space
-- ============================================================
CREATE TABLE movies (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    genre VARCHAR(100) NOT NULL,
    year INTEGER NOT NULL,
    rating DECIMAL(2,1) NOT NULL,
    description TEXT NOT NULL,
    embedding vector(128)
);

INSERT INTO movies (title, genre, year, rating, description) VALUES
-- Sci-Fi (ids 1-5)
('The Matrix', 'Sci-Fi', 1999, 8.7, 'A hacker discovers reality is a simulation controlled by machines'),
('Blade Runner 2049', 'Sci-Fi', 2017, 8.0, 'A blade runner uncovers a secret that threatens society'),
('Interstellar', 'Sci-Fi', 2014, 8.7, 'Explorers travel through a wormhole to find a new home for humanity'),
('Arrival', 'Sci-Fi', 2016, 7.9, 'A linguist learns to communicate with alien visitors'),
('Dune', 'Sci-Fi', 2021, 8.0, 'A young noble must navigate desert politics and giant sandworms'),
-- Action (ids 6-10)
('Die Hard', 'Action', 1988, 8.2, 'An off-duty cop battles terrorists in a skyscraper'),
('Mad Max Fury Road', 'Action', 2015, 8.1, 'A road warrior and rebel escape across a post-apocalyptic desert'),
('John Wick', 'Action', 2014, 7.4, 'A retired assassin seeks vengeance after a personal loss'),
('The Dark Knight', 'Action', 2008, 9.0, 'Batman faces a criminal mastermind who wants to watch the world burn'),
('Gladiator', 'Action', 2000, 8.5, 'A Roman general turned slave fights for freedom in the arena'),
-- Drama (ids 11-15)
('The Shawshank Redemption', 'Drama', 1994, 9.3, 'A banker wrongly imprisoned finds hope and redemption'),
('Forrest Gump', 'Drama', 1994, 8.8, 'A simple man unknowingly influences major historical events'),
('The Godfather', 'Drama', 1972, 9.2, 'The aging patriarch of a crime dynasty transfers power to his son'),
('Fight Club', 'Drama', 1999, 8.8, 'An insomniac and a soap maker form an underground fighting ring'),
('Good Will Hunting', 'Drama', 1997, 8.3, 'A janitor at MIT has a gift for mathematics'),
-- Comedy (ids 16-20)
('The Big Lebowski', 'Comedy', 1998, 8.1, 'A laid-back bowler gets caught up in a kidnapping scheme'),
('Groundhog Day', 'Comedy', 1993, 8.0, 'A weatherman relives the same day over and over'),
('Superbad', 'Comedy', 2007, 7.6, 'Two friends try to make the most of their last weeks of high school'),
('The Grand Budapest Hotel', 'Comedy', 2014, 8.1, 'A legendary concierge is framed for murder at a famous hotel'),
('Monty Python and the Holy Grail', 'Comedy', 1975, 8.2, 'King Arthur and his knights embark on a surreal quest'),
-- Horror (ids 21-25)
('The Shining', 'Horror', 1980, 8.4, 'A family moves into an isolated hotel with a sinister presence'),
('Get Out', 'Horror', 2017, 7.7, 'A young man uncovers a disturbing secret at his girlfriends parents estate'),
('Hereditary', 'Horror', 2018, 7.3, 'A family unravels terrifying secrets after their grandmother dies'),
('A Quiet Place', 'Horror', 2018, 7.5, 'A family must live in silence to avoid creatures that hunt by sound'),
('The Exorcist', 'Horror', 1973, 8.1, 'A mother seeks help when her daughter is possessed by a demon'),
-- Romance (ids 26-30)
('Pride and Prejudice', 'Romance', 2005, 7.8, 'A spirited young woman clashes with a wealthy gentleman'),
('Eternal Sunshine of the Spotless Mind', 'Romance', 2004, 8.3, 'A couple erases each other from their memories after a breakup'),
('Before Sunrise', 'Romance', 1995, 8.1, 'Two strangers meet on a train and spend one night together in Vienna'),
('When Harry Met Sally', 'Romance', 1989, 7.7, 'Two friends debate whether men and women can truly be just friends'),
('Titanic', 'Romance', 1997, 7.9, 'A young couple falls in love aboard the ill-fated ship'),
-- Animation (ids 31-35)
('Spirited Away', 'Animation', 2001, 8.6, 'A girl enters a magical world of spirits to save her parents'),
('Toy Story', 'Animation', 1995, 8.3, 'A cowboy doll feels threatened when a spaceman action figure arrives'),
('Up', 'Animation', 2009, 8.3, 'An elderly man ties balloons to his house to fulfill a dream'),
('Coco', 'Animation', 2017, 8.4, 'A boy journeys to the Land of the Dead to find his musician ancestor'),
('Finding Nemo', 'Animation', 2003, 8.2, 'A clownfish crosses the ocean to rescue his captured son'),
-- Thriller (ids 36-40)
('The Silence of the Lambs', 'Thriller', 1991, 8.6, 'An FBI trainee seeks help from an imprisoned cannibal to catch a killer'),
('Se7en', 'Thriller', 1995, 8.6, 'Two detectives hunt a serial killer who uses the seven deadly sins'),
('Zodiac', 'Thriller', 2007, 7.7, 'A cartoonist becomes obsessed with tracking the Zodiac killer'),
('Gone Girl', 'Thriller', 2014, 8.1, 'A man becomes the prime suspect when his wife disappears'),
('Parasite', 'Thriller', 2019, 8.5, 'A poor family schemes to infiltrate a wealthy household');

-- Generate genre-clustered embeddings
-- Each genre gets a unique sinusoidal base pattern; random noise makes each movie
-- slightly different. Same-genre movies end up close in vector space.
DO $$
DECLARE
    r RECORD;
    genre_seed FLOAT;
    vals FLOAT[];
    i INT;
BEGIN
    FOR r IN SELECT id, genre FROM movies LOOP
        genre_seed := CASE r.genre
            WHEN 'Sci-Fi'    THEN 1.0
            WHEN 'Action'    THEN 2.0
            WHEN 'Drama'     THEN 3.0
            WHEN 'Comedy'    THEN 4.0
            WHEN 'Horror'    THEN 5.0
            WHEN 'Romance'   THEN 6.0
            WHEN 'Animation' THEN 7.0
            WHEN 'Thriller'  THEN 8.0
        END;

        vals := ARRAY[]::FLOAT[];
        FOR i IN 1..128 LOOP
            vals := array_append(vals,
                sin(i * 0.3 + genre_seed * 2.0) * 0.5
                + (random() - 0.5) * 0.3
            );
        END LOOP;

        UPDATE movies SET embedding = vals::vector(128) WHERE id = r.id;
    END LOOP;
END $$;

-- ============================================================
-- Products table (used in notebook 3 — hybrid search)
-- ============================================================
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    subcategory VARCHAR(100),
    price DECIMAL(10,2) NOT NULL,
    rating DECIMAL(2,1) NOT NULL,
    review_count INTEGER DEFAULT 0,
    in_stock BOOLEAN DEFAULT TRUE,
    description TEXT NOT NULL,
    embedding vector(128)
);

INSERT INTO products (name, category, subcategory, price, rating, review_count, in_stock, description) VALUES
-- Electronics
('Wireless Noise-Cancelling Headphones', 'Electronics', 'Audio', 299.99, 4.5, 1250, true, 'Premium headphones with active noise cancellation and 30-hour battery'),
('Bluetooth Portable Speaker', 'Electronics', 'Audio', 79.99, 4.2, 890, true, 'Waterproof speaker with deep bass and 12-hour battery life'),
('USB-C Fast Charger', 'Electronics', 'Accessories', 29.99, 4.0, 2100, true, 'Compact 65W charger compatible with laptops and phones'),
('Mechanical Gaming Keyboard', 'Electronics', 'Peripherals', 149.99, 4.7, 670, true, 'RGB mechanical keyboard with tactile switches'),
('4K Webcam', 'Electronics', 'Peripherals', 89.99, 3.8, 340, false, 'Ultra HD webcam with auto-focus and built-in microphone'),
('Wireless Mouse', 'Electronics', 'Peripherals', 49.99, 4.3, 1500, true, 'Ergonomic wireless mouse with silent clicks'),
('Portable SSD 1TB', 'Electronics', 'Storage', 109.99, 4.6, 780, true, 'Fast external SSD with USB-C connection'),
('Smart Watch', 'Electronics', 'Wearables', 249.99, 4.1, 920, true, 'Fitness tracker with heart rate monitor and GPS'),
-- Clothing
('Cotton Crew Neck T-Shirt', 'Clothing', 'Tops', 24.99, 4.3, 3200, true, 'Soft breathable cotton tee in multiple colors'),
('Slim Fit Jeans', 'Clothing', 'Bottoms', 59.99, 4.1, 1800, true, 'Classic slim fit denim with stretch comfort'),
('Running Shoes', 'Clothing', 'Footwear', 129.99, 4.5, 2400, true, 'Lightweight running shoes with cushioned sole'),
('Winter Parka', 'Clothing', 'Outerwear', 199.99, 4.4, 560, false, 'Insulated waterproof parka for extreme cold'),
('Wool Beanie', 'Clothing', 'Accessories', 19.99, 4.0, 890, true, 'Warm merino wool beanie for winter'),
('Leather Belt', 'Clothing', 'Accessories', 34.99, 4.2, 1100, true, 'Genuine leather belt with classic buckle'),
-- Home & Kitchen
('Stainless Steel Water Bottle', 'Home', 'Kitchen', 24.99, 4.6, 4500, true, 'Double-walled insulated bottle keeps drinks cold 24 hours'),
('Non-Stick Frying Pan', 'Home', 'Kitchen', 39.99, 4.3, 2100, true, 'Ceramic coated pan with cool-touch handle'),
('Robot Vacuum', 'Home', 'Appliances', 349.99, 4.0, 890, true, 'Smart vacuum with mapping and app control'),
('LED Desk Lamp', 'Home', 'Lighting', 44.99, 4.4, 1300, true, 'Adjustable desk lamp with multiple brightness levels'),
('Memory Foam Pillow', 'Home', 'Bedding', 49.99, 4.2, 1700, true, 'Contoured pillow for neck and shoulder support'),
('Air Purifier', 'Home', 'Appliances', 159.99, 4.1, 640, true, 'HEPA filter air purifier for rooms up to 300 sq ft'),
-- Books
('Python Programming Guide', 'Books', 'Technology', 39.99, 4.7, 890, true, 'Comprehensive guide to Python from beginner to advanced'),
('System Design Interview', 'Books', 'Technology', 35.99, 4.8, 1200, true, 'Step-by-step framework for system design interviews'),
('Science Fiction Anthology', 'Books', 'Fiction', 14.99, 4.3, 450, true, 'Collection of award-winning science fiction short stories'),
('Meditation Handbook', 'Books', 'Wellness', 18.99, 4.1, 670, true, 'Practical guide to mindfulness and daily meditation'),
('World History Atlas', 'Books', 'Education', 29.99, 4.5, 340, true, 'Illustrated atlas covering major historical events'),
-- Sports
('Yoga Mat', 'Sports', 'Fitness', 29.99, 4.4, 2800, true, 'Non-slip exercise mat with carrying strap'),
('Resistance Bands Set', 'Sports', 'Fitness', 19.99, 4.3, 3100, true, 'Set of 5 bands with different resistance levels'),
('Camping Tent 4-Person', 'Sports', 'Outdoors', 189.99, 4.2, 560, true, 'Waterproof tent with easy setup for family camping'),
('Hiking Backpack 40L', 'Sports', 'Outdoors', 89.99, 4.5, 780, true, 'Durable hiking pack with hydration bladder sleeve'),
('Dumbbell Set', 'Sports', 'Fitness', 149.99, 4.6, 1200, false, 'Adjustable dumbbell set from 5 to 50 pounds');

-- Generate category-clustered embeddings for products
DO $$
DECLARE
    r RECORD;
    cat_seed FLOAT;
    sub_seed FLOAT;
    vals FLOAT[];
    i INT;
BEGIN
    FOR r IN SELECT id, category, subcategory FROM products LOOP
        cat_seed := CASE r.category
            WHEN 'Electronics' THEN 1.0
            WHEN 'Clothing'    THEN 2.0
            WHEN 'Home'        THEN 3.0
            WHEN 'Books'       THEN 4.0
            WHEN 'Sports'      THEN 5.0
        END;

        sub_seed := CASE r.subcategory
            WHEN 'Audio'       THEN 0.1
            WHEN 'Accessories' THEN 0.2
            WHEN 'Peripherals' THEN 0.3
            WHEN 'Storage'     THEN 0.4
            WHEN 'Wearables'   THEN 0.5
            WHEN 'Tops'        THEN 0.1
            WHEN 'Bottoms'     THEN 0.2
            WHEN 'Footwear'    THEN 0.3
            WHEN 'Outerwear'   THEN 0.4
            WHEN 'Kitchen'     THEN 0.1
            WHEN 'Appliances'  THEN 0.2
            WHEN 'Lighting'    THEN 0.3
            WHEN 'Bedding'     THEN 0.4
            WHEN 'Technology'  THEN 0.1
            WHEN 'Fiction'     THEN 0.2
            WHEN 'Wellness'    THEN 0.3
            WHEN 'Education'   THEN 0.4
            WHEN 'Fitness'     THEN 0.1
            WHEN 'Outdoors'    THEN 0.2
            ELSE 0.0
        END;

        vals := ARRAY[]::FLOAT[];
        FOR i IN 1..128 LOOP
            vals := array_append(vals,
                sin(i * 0.25 + cat_seed * 1.8 + sub_seed * 3.0) * 0.5
                + (random() - 0.5) * 0.2
            );
        END LOOP;

        UPDATE products SET embedding = vals::vector(128) WHERE id = r.id;
    END LOOP;
END $$;

-- Traditional indexes for hybrid search filtering
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_products_rating ON products(rating);
CREATE INDEX idx_products_in_stock ON products(in_stock);
