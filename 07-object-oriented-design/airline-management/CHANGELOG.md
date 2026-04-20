# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-18
- Scaffolded `Airline Management` lab: `README.md`, `references/designgurus.md`, `CHANGELOG.md`.
- No notebooks yet — see README for planned notebooks.

## 2026-04-20
- Rewrote `01_class_design.ipynb` with a bad→best progression: God `Flight` class,
  subclass-per-seat-class "explosion", then a clean design justified decision by decision.
- Expanded `02_implementation.ipynb` with:
  - `Booking` status + `Flight.cancel` with a lead-time refund policy.
  - `FlightSearch` service querying across many flights.
  - `CrewMember` / `CrewRole` separate from `Passenger`.
  - Concurrency demo: 50 threads racing for one seat, guarded by `threading.Lock`.
- Verified both notebooks execute end-to-end with `jupyter nbconvert --execute`.
