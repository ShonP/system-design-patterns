# Authentication & Authorization

> Part of `01-foundations/`. Scaffolded during Phase 3 of the repo restructure — this lab currently contains references and a notebook plan; notebooks will be added incrementally.

## Learning objectives

- Tell authentication from authorization and name canonical mechanisms for each.
- Compare server-stored sessions vs JWTs (trade-offs on revocation, size, statelessness).
- Explain OAuth 2.0 roles and flows at a conceptual level, plus where JWT fits in.
- Understand mTLS and when service-to-service auth needs it.

## Concepts covered

- AuthN vs AuthZ
- Sessions vs JWTs; refresh tokens; logout/revocation
- OAuth 2.0 core flows (at a high level)
- TLS vs mTLS
- Secrets management (env vars, KMS, Vault)
- Encryption at rest vs in transit

## Planned notebooks

> These are planned; files do not yet exist. Following the repo convention, each will be added as a separate numbered notebook (`NN_*.ipynb`) without renumbering earlier ones.

- `notebooks/01_authn_vs_authz.ipynb`
- `notebooks/02_sessions_vs_jwt.ipynb`
- `notebooks/03_oauth_flow_sketch.ipynb`
- `notebooks/04_mtls_service_to_service.ipynb`

## References

- [`references/designgurus.md`](./references/designgurus.md) — scraped lessons that feed this lab
- [`../../docs/restructure-proposal.md`](../../docs/restructure-proposal.md) — overall repo structure
- [`../../docs/content-map.md`](../../docs/content-map.md) — lesson → lab mapping
