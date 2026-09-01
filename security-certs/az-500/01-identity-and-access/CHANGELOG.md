# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-04-17
- Scaffolded the AZ-500 `Secure identity and access` lab with three notebooks:
  `01_rbac_and_custom_roles.ipynb`, `02_pim_and_conditional_access.ipynb`,
  `03_app_registrations_and_managed_identities.ipynb`.

## 2026-04-20
- Fixed the Docker paths and port for the `fake-entra` / `api-b` mock borrowed from
  `08-enterprise/azure-authentication`; expanded the identity notebooks.

## 2026-08-21 (correctness audit)
Audited every product claim against the current Microsoft Learn documentation. Six
factual errors found, all of them the kind that costs an exam question.

- **NB1 — `Key Vault Administrator` was described as "full Key Vault management".**
  It is the opposite: all *data-plane* operations (`Microsoft.KeyVault/vaults/*` as a
  `DataAction`) and explicitly **cannot manage the vault resource**. Managing the vault is
  `Key Vault Contributor`. Corrected, and the Administrator/Contributor mirror-image is now
  called out.
- **NB1 — the simulated `Contributor` role denied *reading* role assignments.** The real
  `NotActions` are `Microsoft.Authorization/*/Write`, `Microsoft.Authorization/*/Delete`
  and `elevateAccess` — reads are not excluded. Replaced the invented `NotActions` with the
  real ones, and the matcher now uses case-insensitive globbing (`fnmatchcase`) because
  Azure action strings are case-insensitive and real definitions put `*` mid-string.
- **NB1 — the bad→best table claimed `Owner` can read Key Vault secrets.** Owner is
  `actions: ["*"], dataActions: []`, so it has *no* data-plane access at all — the same gap
  Contributor has. The table is now **computed** from the permission engine instead of
  hand-written, so it cannot drift again, and the takeaway explains the real risk: Owner
  can *assign itself* `Key Vault Secrets User` and come back a second later.
- **NB1 — deny assignments were attributed to "Azure Blueprints or managed apps".**
  Blueprints is retiring; the current sources are **deployment stack `denySettings`** and
  Azure managed applications, and all deny assignments are `IsSystemProtected`. Added the
  two properties role assignments do not have: `ExcludePrincipals` and
  `DoNotApplyToChildScopes` (deny assignments can opt out of inheritance).
- **NB2 — PIM maximum activation duration was given as "0.5 to 24 hours".** The documented
  range is **1 to 24 hours**. Corrected.
- **NB2 — a Conditional Access policy required `mfa` + `password_change` on a *sign-in
  risk* condition.** "Require password change" is only accepted with a **user-risk**
  condition, must target all resources, and cannot be combined with another grant control —
  and the notebook's own later table said as much, so the policy list contradicted the
  prose. Split into a sign-in-risk → MFA policy and a user-risk → password-change policy,
  with assertions enforcing all three portal rules.
- **NB3 — IMDS at `169.254.169.254` was claimed for App Service, Functions and Container
  Apps.** Those hosts expose a per-app local token service via `IDENTITY_ENDPOINT` /
  `IDENTITY_HEADER`; hard-coding the link-local address there hangs. Azure Arc servers are
  different again (`localhost:40342` plus a challenge token). Replaced with a
  host → endpoint table and added the matching CLI snippet.

Terminology and licensing, corrected against current SKU names:

- "Entra ID **Premium** P1/P2" → **Microsoft Entra ID P1 / P2** (the rename dropped
  "Premium"). Spelled out which tier buys what: Conditional Access is P1; risk-based
  conditions need Microsoft Entra ID Protection, which is P2; PIM needs P2 *or* a
  Microsoft Entra ID Governance licence; access reviews likewise.
- NB1: "Azure has 300+ built-in roles" → "hundreds" (the number was unverifiable and
  stale).

Content added where the lab's own stated scope had a hole:

- **NB1**: `Role Based Access Control Administrator` — the modern least-privilege
  alternative to User Access Administrator — and a corrected description of what UAA
  actually grants (`*/read` plus *all* of `Microsoft.Authorization/*`, not just role
  assignments). Added the documented `AssignableScopes` limits (5,000 custom roles per
  tenant, no root scope, no wildcards, at most one management group, `DataActions` roles
  cannot be assigned at management-group scope).
- **NB2**: the eligible/active × permanent/time-bound matrix the README already promised
  but the notebook never showed, and the real **two-phase CA evaluation model** — phase 1
  collects session details (report-only policies included), phase 2 enforces, block stops
  enforcement immediately, and unsatisfied grant controls are prompted in the documented
  order (MFA → compliant device → hybrid joined → approved client app → app protection →
  password change → terms of use). Also added the "policies targeting roles/groups are
  only evaluated at token issuance" gap.
- **NB3**: a third token request using `reporting-daemon-client-id`, which has no app role
  granted on `api://api-b`. It shows the trap that missing admin consent returns a valid
  **200 with an empty `roles` claim** — the 403 arrives later, at the resource. Added the
  federated-credential `subject` warning (pinning a branch vs `repo:org/repo:*`), the
  user-assigned-identity disambiguation requirement, and the system-assigned re-deployment
  trap (new object ID, stale role assignments).

Assertions added so each notebook fails loudly if it stops demonstrating its own lesson:

- NB1: Contributor cannot write but *can* read role assignments; neither Owner nor
  Contributor can read a secret on the data plane; User Access Administrator cannot create
  a VM; privilege strictly shrinks Owner ⊃ Contributor ⊃ custom role; the shipped custom
  role JSON matches the simulated role definition.
- NB2: activation fails without MFA, without justification, and when the requested duration
  exceeds the role maximum; Global Admin lands on `PENDING APPROVAL` while Contributor
  activates outright; the three password-change policy rules; break-glass is locked out by
  the misconfigured policy and allowed by the corrected one; **block beats an already
  satisfied grant**; a report-only block policy blocks nobody.
- NB3: a delegated token carries `scp` + `upn` and no `roles`; an app-only token carries
  `roles` and no `scp`/`upn`; an unconsented app gets `roles: []`; both tokens share the
  `api://api-b` audience.

Hygiene:

- Added a `## ✅ Self-check` question cell plus an answers cell to all three notebooks,
  matching the convention used by the other AZ-500 and SC-200 labs (this lab was the only
  one without them). 7 + 8 + 7 questions, answers written to the corrected facts above.
- Outputs stripped and `execution_count` reset on every edited cell.
