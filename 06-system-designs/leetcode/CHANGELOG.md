# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-20
- Hardened the sandbox: added `memswap_limit: 256m` (makes the memory cap a real
  hard limit — no swap escape) and `pids_limit: 128` (blocks fork bombs) to
  `docker-compose.yml`.
- Notebook 2: rewrote the memory-limit test to actually force page residency
  (1-MB chunks filled with bytes) so it demonstrates the OOM-killer firing
  (exit 137) instead of misleadingly "succeeding".
- Notebook 2: removed dead code from `run_in_sandbox()` and clarified why the
  heredoc terminator is quoted (prevents shell expansion of `$` / backticks in
  user code).
- Notebook 2: added a new "Production-Grade Sandboxing" section covering
  gVisor, Firecracker, Kata Containers, and seccomp-BPF so readers know what
  the next step up from plain Docker looks like.
- Notebook 3: added a new "Scaling Past One Redis" section covering leaderboard
  sharding (scatter-gather reads) and primary-replica replication for HA.
- Verified all three notebooks execute end-to-end without errors.

## 2026-04-18
- Added `references/designgurus.md` pointing at scraped Design Gurus lessons for this lab.
- Added this changelog.
