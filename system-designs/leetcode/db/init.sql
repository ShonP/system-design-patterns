-- ============================================================
-- LeetCode System Design Lab — Database Schema & Seed Data
-- ============================================================
-- Models a coding-challenge platform: problems, submissions,
-- competitions, and leaderboards.
-- ============================================================

-- ============================================================
-- Tables
-- ============================================================

-- Each coding problem (Two Sum, Merge Intervals, etc.)
CREATE TABLE problems (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    difficulty VARCHAR(10) NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
    tags TEXT[] DEFAULT '{}',
    -- Code stubs and test cases stored as JSON so one row works for every language
    code_stubs JSONB NOT NULL DEFAULT '{}',
    test_cases JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Registered platform users
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Every code submission a user makes
CREATE TABLE submissions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    problem_id INTEGER NOT NULL REFERENCES problems(id),
    language VARCHAR(20) NOT NULL,
    code TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'running', 'accepted', 'wrong_answer', 'runtime_error', 'time_limit')),
    -- Per-test-case results stored as JSON array
    results JSONB DEFAULT '[]',
    runtime_ms INTEGER,
    memory_kb INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- A timed coding competition
CREATE TABLE competitions (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    starts_at TIMESTAMP NOT NULL,
    ends_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Links problems to a competition
CREATE TABLE competition_problems (
    competition_id INTEGER NOT NULL REFERENCES competitions(id),
    problem_id INTEGER NOT NULL REFERENCES problems(id),
    ordering INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (competition_id, problem_id)
);

-- Submissions made during a competition
CREATE TABLE competition_submissions (
    id SERIAL PRIMARY KEY,
    competition_id INTEGER NOT NULL REFERENCES competitions(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    problem_id INTEGER NOT NULL REFERENCES problems(id),
    submission_id INTEGER NOT NULL REFERENCES submissions(id),
    passed BOOLEAN NOT NULL DEFAULT FALSE,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Indexes (each comment explains *why* we need it)
-- ============================================================

-- Fast lookup of a user's submissions for a problem
CREATE INDEX idx_submissions_user_problem ON submissions(user_id, problem_id);

-- Leaderboard query: all passing submissions for a competition
CREATE INDEX idx_comp_subs_competition ON competition_submissions(competition_id, passed);

-- Quick ranking by user inside a competition
CREATE INDEX idx_comp_subs_user ON competition_submissions(competition_id, user_id);

-- ============================================================
-- Seed data
-- ============================================================

-- 10 classic coding problems
INSERT INTO problems (title, description, difficulty, tags, code_stubs, test_cases) VALUES
(
    'Two Sum',
    'Given an array of integers nums and an integer target, return indices of the two numbers that add up to target.',
    'easy',
    ARRAY['array', 'hash-table'],
    '{"python": "class Solution:\n    def twoSum(self, nums: list[int], target: int) -> list[int]:\n        pass", "javascript": "var twoSum = function(nums, target) {\n    \n};"}',
    '[{"input": {"nums": [2,7,11,15], "target": 9}, "expected": [0,1]}, {"input": {"nums": [3,2,4], "target": 6}, "expected": [1,2]}]'
),
(
    'Valid Parentheses',
    'Given a string s containing just the characters ''('', '')'', ''{'', ''}'', ''['' and '']'', determine if the input string is valid.',
    'easy',
    ARRAY['string', 'stack'],
    '{"python": "class Solution:\n    def isValid(self, s: str) -> bool:\n        pass", "javascript": "var isValid = function(s) {\n    \n};"}',
    '[{"input": {"s": "()"}, "expected": true}, {"input": {"s": "()[]{}"}, "expected": true}, {"input": {"s": "(]"}, "expected": false}]'
),
(
    'Merge Intervals',
    'Given an array of intervals where intervals[i] = [starti, endi], merge all overlapping intervals.',
    'medium',
    ARRAY['array', 'sorting'],
    '{"python": "class Solution:\n    def merge(self, intervals: list[list[int]]) -> list[list[int]]:\n        pass"}',
    '[{"input": {"intervals": [[1,3],[2,6],[8,10],[15,18]]}, "expected": [[1,6],[8,10],[15,18]]}]'
),
(
    'LRU Cache',
    'Design a data structure that follows the constraints of a Least Recently Used (LRU) cache.',
    'medium',
    ARRAY['hash-table', 'linked-list', 'design'],
    '{"python": "class LRUCache:\n    def __init__(self, capacity: int):\n        pass\n    def get(self, key: int) -> int:\n        pass\n    def put(self, key: int, value: int) -> None:\n        pass"}',
    '[{"input": {"ops": ["LRUCache","put","put","get","put","get"], "args": [[2],[1,1],[2,2],[1],[3,3],[2]]}, "expected": [null,null,null,1,null,-1]}]'
),
(
    'Maximum Depth of Binary Tree',
    'Given the root of a binary tree, return its maximum depth.',
    'easy',
    ARRAY['tree', 'dfs', 'bfs'],
    '{"python": "class Solution:\n    def maxDepth(self, root) -> int:\n        pass"}',
    '[{"input": {"root": [3,9,20,null,null,15,7]}, "expected": 3}, {"input": {"root": [1,null,2]}, "expected": 2}]'
),
(
    'Longest Substring Without Repeating Characters',
    'Given a string s, find the length of the longest substring without repeating characters.',
    'medium',
    ARRAY['string', 'sliding-window', 'hash-table'],
    '{"python": "class Solution:\n    def lengthOfLongestSubstring(self, s: str) -> int:\n        pass"}',
    '[{"input": {"s": "abcabcbb"}, "expected": 3}, {"input": {"s": "bbbbb"}, "expected": 1}]'
),
(
    'Median of Two Sorted Arrays',
    'Given two sorted arrays nums1 and nums2, return the median of the two sorted arrays.',
    'hard',
    ARRAY['array', 'binary-search', 'divide-and-conquer'],
    '{"python": "class Solution:\n    def findMedianSortedArrays(self, nums1: list[int], nums2: list[int]) -> float:\n        pass"}',
    '[{"input": {"nums1": [1,3], "nums2": [2]}, "expected": 2.0}, {"input": {"nums1": [1,2], "nums2": [3,4]}, "expected": 2.5}]'
),
(
    'Trapping Rain Water',
    'Given n non-negative integers representing an elevation map where the width of each bar is 1, compute how much water it can trap after raining.',
    'hard',
    ARRAY['array', 'two-pointers', 'stack'],
    '{"python": "class Solution:\n    def trap(self, height: list[int]) -> int:\n        pass"}',
    '[{"input": {"height": [0,1,0,2,1,0,1,3,2,1,2,1]}, "expected": 6}]'
),
(
    'Number of Islands',
    'Given an m x n 2D binary grid which represents a map of ''1''s (land) and ''0''s (water), return the number of islands.',
    'medium',
    ARRAY['graph', 'dfs', 'bfs'],
    '{"python": "class Solution:\n    def numIslands(self, grid: list[list[str]]) -> int:\n        pass"}',
    '[{"input": {"grid": [["1","1","0","0","0"],["1","1","0","0","0"],["0","0","1","0","0"],["0","0","0","1","1"]]}, "expected": 3}]'
),
(
    'Serialize and Deserialize Binary Tree',
    'Design an algorithm to serialize and deserialize a binary tree.',
    'hard',
    ARRAY['tree', 'design', 'bfs'],
    '{"python": "class Codec:\n    def serialize(self, root) -> str:\n        pass\n    def deserialize(self, data: str):\n        pass"}',
    '[{"input": {"root": [1,2,3,null,null,4,5]}, "expected": [1,2,3,null,null,4,5]}]'
);

-- 50 sample users
INSERT INTO users (username, email)
SELECT
    'coder' || i,
    'coder' || i || '@example.com'
FROM generate_series(1, 50) AS i;

-- One active competition (90 minutes, 4 problems)
INSERT INTO competitions (title, starts_at, ends_at) VALUES
    ('Weekly Contest 42', NOW() - INTERVAL '30 minutes', NOW() + INTERVAL '60 minutes');

INSERT INTO competition_problems (competition_id, problem_id, ordering) VALUES
    (1, 1, 1),
    (1, 3, 2),
    (1, 6, 3),
    (1, 8, 4);

-- 200 regular submissions spread across users and problems
INSERT INTO submissions (user_id, problem_id, language, code, status, runtime_ms, memory_kb, created_at)
SELECT
    (floor(random() * 50) + 1)::int,
    (floor(random() * 10) + 1)::int,
    (ARRAY['python', 'javascript'])[floor(random() * 2 + 1)::int],
    'print("solution ' || i || '")',
    (ARRAY['accepted', 'wrong_answer', 'runtime_error', 'time_limit'])[floor(random() * 4 + 1)::int],
    floor(random() * 500 + 10)::int,
    floor(random() * 30000 + 5000)::int,
    NOW() - (random() * INTERVAL '30 days')
FROM generate_series(1, 200) AS i;

-- 80 competition submissions (some passing, some failing)
INSERT INTO competition_submissions (competition_id, user_id, problem_id, submission_id, passed, submitted_at)
SELECT
    1,
    s.user_id,
    s.problem_id,
    s.id,
    (s.status = 'accepted'),
    s.created_at
FROM (
    SELECT id, user_id, problem_id, status, created_at
    FROM submissions
    ORDER BY random()
    LIMIT 80
) s;
