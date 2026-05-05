# Confirmed-Compromise Playbook (single host)

> Time-box yourself at each step. Don't go down a rabbit hole on step 1.

## Identification (≤ 10 min)
- [ ] Which host? Confirm hostname, IP, owner, environment.
- [ ] Which alerts triggered? Pull the related alerts as a timeline.
- [ ] Confirm — is this a real incident or a noisy detection? (False positives are fine; **document** the reasoning.)

## Containment (≤ 15 min)
- [ ] **Isolate at the network layer first.** Don't power off — you'll lose volatile memory.
  - K8s: `kubectl label pod <p> quarantine=true` + a `NetworkPolicy` that denies all egress for that label.
  - VM:   move SG to `quarantine-sg` (deny all).
  - Container: `docker network disconnect <net> <ctr>`.
- [ ] **Identity blast-radius.** Disable user/SP, rotate all keys/tokens this host had.
- [ ] **Pause auto-scalers / deployers** so the bad workload doesn't replicate.

## Evidence collection (≤ 30 min)
- [ ] Process tree: `ps -efww --forest > /evidence/ps.txt`
- [ ] Network: `ss -tunap > /evidence/ss.txt`, `lsof -i > /evidence/lsof.txt`
- [ ] Suspicious files: `find / -newer /tmp/timestamp -type f 2>/dev/null > /evidence/changed-files.txt`
- [ ] Memory dump if you have the tooling (`avml`, `lime`, cloud snapshot)
- [ ] Disk snapshot (cloud snapshot) — preserve before mutation.
- [ ] Logs: `journalctl --since='1 day ago' > /evidence/journal.txt`, `/var/log/*` tarball.

## Eradication
- [ ] Identify root cause. **Don't skip this.** Reimaging without fixing root cause = repeat in two weeks.
- [ ] Rebuild the host from a known-good image. Don't try to "clean" a compromised host.
- [ ] Remove backdoors at the IAM / cluster layer (sometimes attackers persist there, not on the host).

## Recovery
- [ ] Bring rebuilt workload back online.
- [ ] Watch closely for 72h.
- [ ] Re-enable auto-scaling / deploys.

## Lessons learned (within 1 week)
- [ ] How did the attacker get in? Where could we have detected sooner?
- [ ] What detection / control / process change makes this case impossible (or noisy enough to catch)?
- [ ] Update runbooks, detections, and the threat model.

---

## Don'ts

- ❌ Don't `rm -rf` the attacker's tools before snapshotting evidence.
- ❌ Don't reboot to "make it go away" — kills volatile data.
- ❌ Don't notify the attacker (hunting from the attacker's own session = bad).
- ❌ Don't skip rotation because the credential "should have been read-only."
