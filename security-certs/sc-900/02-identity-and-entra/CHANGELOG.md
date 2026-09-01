# Changelog

All notable changes to this lab will be documented here.
New content is **added**, never destructively replaced.

## 2026-08-21 (correctness audit)

Content review against current Microsoft Learn documentation and the SC-900 study guide
(skills measured as of 28 July 2026). Product names, licence claims and risk-detection names
were checked one by one rather than taken from the prose.

### Corrected

- **NB1 cell "Authentication vs Authorization"**: the demo labelled a request with *no token*
  as "failed authorization", printed the resulting **401**, and so contradicted the table two
  cells earlier that teaches authz failure = **403**. There is now a genuine authorization
  failure: sign in successfully, take a token whose `scp` is `Files.Write`, call `/files`, and
  get a real 403 from api-b's `require_scope`. The missing-token case is kept and relabelled as
  the second 401.
- **NB3 opening**: "The four pillars of Entra ID Governance" listed **Identity Protection** as
  one of them. ID Protection is a risk-detection service in Entra ID P2 — it is not part of the
  Microsoft Entra ID Governance product, whose features are entitlement management, access
  reviews, PIM and lifecycle workflows. Reframed around Microsoft's three lifecycles (identity,
  access, privileged access), with a callout explaining why ID Protection still appears in this
  notebook (the exam objective is "identity protection *and* governance").
- **NB3 ID Protection detections**: "Malware-linked IP" is not a current detection name — the
  documented one is **Malicious IP address**. `unfamiliar_device` renamed to
  `unfamiliar_sign_in_properties` and `anonymous_ip` to `anonymous_ip_address` to match the
  report names. Added *verified threat actor IP* to sign-in risk and *anomalous token* to user
  risk, and named *Microsoft Entra threat intelligence* properly (it was just "Threat
  intelligence"). Also added the self-remediation split the exam likes: MFA clears sign-in risk,
  a secure password change clears user risk.
- **NB3 licences**: PIM / access reviews / entitlement management are "Entra ID P2 **or**
  Microsoft Entra ID Governance", not P2 only. The cheat sheet said "all three require P2"
  under a table of four rows.
- **NB2 authentication-method table**: rewritten. SMS/voice was rated "Medium" — it is the
  weakest second factor in the list (SIM swap, SS7, and a code the user can read out to a
  caller) and is now rated and explained as such. Windows Hello was filed under "something you
  are"; it is a device-bound key unlocked by a PIN or biometric, i.e. multifactor on its own.
  Added an explicit **phishing-resistant** column and Microsoft's actual list (Windows Hello for
  Business, Platform Credential for macOS, passkeys/FIDO2, certificate-based authentication),
  plus the note that Authenticator push with number matching stops prompt-bombing but is still
  relayable by an adversary-in-the-middle proxy. "FIDO2 security key" updated to the current
  name **passkey (FIDO2)**.
- **NB2 MFA statistic**: "MFA blocks 99.9% of identity attacks" restated as Microsoft actually
  publishes it — an account is *more than 99.9% less likely to be compromised* — with the later
  Microsoft measurement study (99.2% population-wide, 98.6% with an already-leaked password)
  and the caveat about what still gets through.
- **NB2 Conditional Access licensing**: P1 is the floor, but the *risk* conditions come from ID
  Protection and need **P2**; security defaults named as the free all-or-nothing alternative
  (and the fact you cannot run both). Added that Conditional Access is evaluated *after* first
  factor.
- **NB2 hybrid identity**: separated the *sync tool* choice from the *sign-in method* choice,
  named **Microsoft Entra Connect** (formerly Azure AD Connect) and added **Microsoft Entra
  Cloud Sync**, which Microsoft states replaces it.
- **NB2** `evaluate_conditional_access` was annotated `-> list` but returns a dict.

### Added

- **NB1**: the **four pillars of identity** (administration, authentication, authorization,
  auditing) as a labelled "older phrasing you may meet" callout, and a
  **federation vs synchronisation vs cloud-only** comparison — the lab explained federation but
  never contrasted it with the two sync models the exam pairs it against.
- **NB2**: **agent identity (Microsoft Entra Agent ID)** in the identity-types table. The
  28 July 2026 study guide update spells out "types of identities, **including agent ID**".
- **NB2**: a **password protection and management** section (global banned password list, custom
  banned list, Password Protection for AD DS, smart lockout, and the normalisation +
  edit-distance matching that makes banning a base term block its variants). That is an explicit
  exam bullet the lab covered only as SSPR.
- **NB2**: the three **Zero Trust** principles stated by name — verify explicitly, use least
  privilege, assume breach — mapped onto what Conditional Access does.
- **NB3**: **lifecycle workflows** in the governance table.
- A **self-check quiz** at the end of all three notebooks (6 questions each, with an explanation
  of why the distractors are wrong), matching the format already used in labs 03 and 04. This
  lab was the only SC-900 lab with no self-check. Every quiz asserts that its answer key is
  internally consistent.

### Assertions added

The notebooks now fail loudly if they stop demonstrating their own lesson:

- NB1: token issuance is 200; `/files` with `Files.Read` is 200; a bad password is 401; a missing
  token is 401; an authenticated caller without the scope is **403**; the forged `alg: none`
  token is rejected (previously the `except` block would have printed nothing and passed
  silently if verification broke) and the real token resolves to Alice.
- NB2: password+security-question is not MFA; password+SMS is MFA but not phishing-resistant;
  push is not phishing-resistant; a passkey and Windows Hello are each multifactor on their own;
  every Conditional Access scenario lands on its stated decision; the bad→best progression is
  pinned (allowed → MFA-challenged → blocked) **and** the legitimate MFA'd user stays allowed at
  every stage, so tightening cannot degenerate into deny-all; Reader ⊂ Contributor ⊂ Owner and
  an unassigned user gets nothing.
- NB3: every PIM gate (justification, MFA, approval) actually denies; the standing-admin case
  really does show the breach; the access-review recommendations are pinned; the risk simulation
  keeps clean sign-ins clean and blocks the Tor + password-spray one; access packages stay
  approval-gated, time-bound and review-scheduled.

### Determinism

- **NB3 access review** computed staleness from `datetime.now()`, so the recommendations drifted
  with the wall clock — alice and carol would have flipped from APPROVE to DENY once their
  "last used" dates aged past a year. Pinned to a fixed `REVIEW_DATE`.
- **NB3 access review**: the "wrong department" branch was dead code — bob is in Marketing but
  was caught by the staleness branch first, so no member ever reached it. Added a recent
  Marketing user so all three outcomes appear, and asserted that they do.

### Not changed

- The lab still uses the ROPC password grant against the mock IdP to obtain a user token. It is
  the wrong flow for production and the notebook already says so; it stays because it is the
  shortest path to a real signed token for the authn/authz demo.
