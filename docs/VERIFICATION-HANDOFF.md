# Lab verification — what was done, and what to know

_Last updated: 2026-08-24._

This repo had never been run end to end. Every lab has now been reviewed for correctness
and executed against real infrastructure. This document records the state, the failure
patterns worth knowing, and the few things still open.

---

## Check the current state yourself

```bash
python3 tools/validate_labs.py                 # static checks over every lab (seconds)
python3 tools/check_ports.py                   # which labs would fail to start right now, and why
python3 tools/run_labs.py --all --no-docker    # every container-free lab (minutes)
python3 tools/run_labs.py 01-foundations/caching   # one lab, containers and all
```

`validate_labs.py` exits non-zero on any error and runs in CI
(`.github/workflows/validate-labs.yml`). Details in [`tools/README.md`](../tools/README.md).
Per-lab state is in [`tools/qa-status.json`](../tools/qa-status.json).

---

## Where things stand

| | Count |
|---|---:|
| Labs tracked | 160 |
| **Content-reviewed** | **160** |
| **Execution-verified** against real infrastructure | **160** |
| Static validation errors | **0** (was 68) |
| Broken relative links | **0** |
| Notebooks | 529, all valid JSON, all on the lab's own `.venv` kernel |

The Kubernetes lab needs a cluster; everything else needs only Docker:

```bash
minikube start --cpus=4 --memory=6144   # NOT 8192 — see the note below
python3 tools/run_labs.py 03-technologies/container-orchestration/kubernetes
```

---

## The one thing worth reading

**A lab that runs cleanly is not a lab that is correct.** Every lab in this repo executed
without error before this pass, and the review still found real defects in most of them.
Some representative examples, all from notebooks that exited 0:

- `top-k` — `TopKHeap` evicted genuine heavy hitters. With lazy deletion, `heap[0]` is often
  a stale entry, so a newcomer beating the stale root but not the true minimum was admitted
  anyway. 570 violations in a 4,000-push randomised check.
- `google-docs` — the operational-transform function was **not convergent**. Two inserts at
  the same position shifted each other right; two users backspacing the same three characters
  deleted six. 24 divergent pairs out of 529.
- `whatsapp` — the sequence number was allocated in one transaction and the row inserted in
  another, so per-conversation ordering, the lab's central claim, was not actually guaranteed.
- `robinhood` — `add_market_order` returned fills but never recorded the trade, and
  `cleanup_stuck_orders` marked orders filled with no ledger entry at all.
- `yelp` — `db/init.sql` filled `latitude`/`longitude` and the PostGIS `location` column from
  separate `random()` calls, so every business sat at two points ~5 km apart and the lab's
  three "comparisons" answered different questions.
- `metrics-monitoring` — the alert state machine could never reach `firing`, and the metric
  generator's ceiling was 75% against thresholds of 80 and 95.
- `09-security/06` — the NetworkPolicy proof ran a probe pod that PSA `restricted` rejected at
  admission, so `|| echo BLOCKED` printed BLOCKED without a packet being sent.
- `09-security/08` — the Wazuh compose file could not start the indexer or the dashboard at
  all, and the documented admin credentials were not the ones the image ships.

Assertions were added throughout, so a lab that stops reproducing its own lesson now fails
loudly instead of printing a checkmark. That is the durable part of this work: several
regressions were caught later *by those assertions* rather than by re-reading the code.

### Corollary: passing once is not passing

Three labs passed, then failed on a re-run — races that had simply been winning.
`metrics-monitoring` advanced a 5-second alert timer with `time.sleep(3)`; `robinhood` lost
one Kafka message in ten to a lazy offset reset; `distributed-cache` published before Redis
had registered its subscriber. All three were fixed by removing the race, not by widening a
timeout. When you change a lab, run it more than once.

---

## Things that will bite you

- **Docker Desktop memory.** `minikube start --memory=8192` is a hard failure on an 8 GB
  Docker Desktop. Worse, with the docker driver the kubelet reports the *host's* memory as
  node capacity while Docker caps the container lower — so it never evicts and stalls the
  whole node instead, which surfaces as `TLS handshake timeout` in unrelated notebooks.
- **`docker compose up -d` reuses a stale image.** Labs that build from source need
  `--build`, or your source edit silently isn't running. Two labs looked broken in this pass
  for exactly this reason; `tools/run_labs.py` now always passes `--build`.
- **Host ports.** Labs publish fixed ports and cannot run concurrently. `check_ports.py`
  names whatever is holding one. Nine labs used to bind 5433 and collide with an unrelated
  container of yours; they now use 55433 (and 55434/55435 where they need siblings).
- **`db/init.sql` only runs on a fresh volume.** After a seed-data change you need
  `docker compose down -v`. Several labs now assert their seed matches and fail with that
  instruction rather than producing nonsense.

---

## Still open

- **Notebook outputs are inconsistent.** Roughly 160 notebooks carry committed cell outputs;
  the rest were stripped. Stripping everything makes diffs clean and is the usual convention
  for a run-it-yourself repo; keeping them lets people read results on GitHub without running
  anything. Pick one and apply it repo-wide — this is a decision, not an oversight.
- **`09-security/08` has an intermittent manager init race** (~1 in 4 cold boots): analysisd
  dies on `CRITICAL: (1107)` and the manager comes up with only authd/wazuh-db/apid. The
  trigger was not found. `scripts/wait-for-stack.sh` detects and repairs it, and that repair
  was verified by forcing the broken state deliberately — but the underlying cause is unknown.
- **`09-security/08`'s dashboard UI was verified by API, not by eye.** Login page 200,
  authenticated `/api/status` green, and 20 indexer hits for `rule.id:5503` prove the data
  path; nobody clicked through the Security Events view.
- **NetworkPolicy is not enforced on minikube's default CNI.** The Kubernetes lab now asserts
  the honest outcome for whichever CNI you have rather than claiming a block that did not
  happen. Enforcement needs `--cni=calico` and a cluster rebuild.
- **Exercises that need a real cloud or a real GitHub repo** are marked as such rather than
  left as steps that cannot be completed: Prowler's live scan, Dependabot/Renovate PRs, and
  the CI workflow gates. Their config files are validated locally instead.

---

## A note on how this was verified

Most content review was done by reading, because reading finds different bugs than running
does — wrong arithmetic, prose contradicting output, a demo that cannot reproduce its lesson.
But reading also produces confident-and-wrong fixes. Every lab was therefore executed
afterwards, and that round found a further class of defect that reading had missed entirely:
a WebSocket client that treated a stream as request/response and wedged a thread; a Wazuh
indexer whose certificate CN never matched; a `pg_ctl` promotion that cannot run as root; a
Postgres snapshot stored with literal `\n` where the operations log had real newlines.

If you extend this repo, do both.
