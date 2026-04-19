# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-19
- Added Notebook 4: **Cache Patterns & Stampede Protection** covering cache-aside,
  read-through, write-through, write-behind, thundering-herd stampedes fixed with a
  Redis single-flight lock (`SET NX EX` + token + Lua compare-and-delete), and
  negative caching with a sentinel value.
- README updated with the new notebook and two new concept sections.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
