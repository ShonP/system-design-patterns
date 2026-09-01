# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-20 (repo-wide verification pass)
- **Fix**: `docker compose up` failed on a clean checkout. Nginx bind-mounts `./nginx/certs`, which only exists after you remember to run `nginx/generate_certs.sh` by hand, so nginx refused to start and notebooks 3 and 4 were unusable. Added a `certgen` service that generates the CA / server / client certificates before nginx boots, wired through `depends_on: condition: service_completed_successfully`.
- Corrected the setup path in the README and notebooks (`cd core-concepts/networking-essentials` → `01-foundations/networking-essentials`) and documented that certificates are now automatic.
- Normalised the notebook kernel to the lab's own `.venv`.
- All 4 notebooks executed end-to-end against the docker-compose stack to verify they run cleanly.
