# Lab 07 — Infrastructure as Code (IaC) Security

## 🎯 What you'll learn

- Scan **Terraform** with **Checkov**, **KICS**, **tfsec** and **Trivy** — and measure,
  not assume, why you'd run more than one (they agree on only 4 of 8 planted flaws)
- Find common AWS misconfigs: public S3 buckets, open security groups, unencrypted RDS, IMDSv1, missing CloudTrail
- Fix the misconfigs by diffing `terraform-bad/` against `terraform-good/` — then find
  out that "zero findings" is a statement about one scanner, not about the code
- Use **Prowler** for **live cloud posture** scanning (CSPM), and see how little of
  CIS an IaC scanner can ever cover
- Build a CI gate that actually blocks — and recognise the two ways these templates
  fail silently green

## 📋 Prerequisites

- Docker
- Optional: Terraform CLI (`brew install hashicorp/tap/terraform`, or just
  `docker run --rm -v "$(pwd)":/tf -w /tf hashicorp/terraform:1.13 …`) for the
  plan-time challenge
- Optional: AWS account with read-only credentials to point Prowler at a live tenant.
  **Exercises 1–5 and 7 never touch a cloud.** Exercise 6 is honest about the split:
  Prowler's *catalogs* (checks, services, compliance frameworks and their control text)
  are all readable offline; an actual posture *scan* is not — see Exercise 6.

## 🔧 Setup

```bash
$ cd 07-infrastructure-as-code
$ ls terraform-bad/   # deliberately misconfigured S3 / EC2+SG / RDS+IAM / CloudTrail
$ ls terraform-good/  # the same four resource groups, hardened
```

Nothing here is ever applied. Every scanner in Exercises 1–5 reads the HCL as text —
no AWS account, no credentials, no `terraform init` required. (Challenge 1 is the one
exception, and it is optional.)

> ⚠️ `terraform-bad/s3.tf` sets `acl = "public-read"` directly on `aws_s3_bucket`.
> AWS provider v4 moved ACLs into a separate `aws_s3_bucket_acl` resource, but it
> **deprecated** the inline argument rather than removing it, and v5 still accepts it.
> Measured 2026-08-21, terraform 1.13 + hashicorp/aws v5.100.0:
>
> ```
> Warning: Argument is deprecated
>   on s3.tf line 3, in resource "aws_s3_bucket" "data":
>    3:   acl    = "public-read"
> acl is deprecated. Use the aws_s3_bucket_acl resource instead.
> Success! The configuration is valid, but there were some validation warnings
> ```
>
> So `terraform validate` *passes* — with a warning nobody reads — while all four
> scanners flag that exact line, and the three that assign severities call it CRITICAL
> (KICS) or HIGH (tfsec, Trivy). That gap is the lesson: **`validate` checks that the
> provider will accept your syntax, not that the result is safe.** And neither knows
> whether the bucket has any data in it. Different questions, and you need all of them.

---

## 📝 Exercises

### Exercise 1 — Checkov on the bad Terraform

```bash
$ ./scripts/run-checkov.sh -d terraform-bad/ \
    -o cli -o sarif --output-file-path console,exercises/checkov.sarif
```

Skim the output. Examples:

- `CKV_AWS_20`  S3 Bucket has an ACL defined which allows public access
- `CKV_AWS_21`  S3 versioning disabled
- `CKV_AWS_24`  Security group allows ingress from 0.0.0.0/0 on port 22
- `CKV_AWS_79`  EC2 instance metadata service v1 (IMDSv1) allowed
- `CKV_AWS_17`  RDS instance not encrypted

> ✅ Expected: two summary blocks. `terraform scan results: Passed checks: 16,
> Failed checks: 51, Skipped checks: 0` and `secrets scan results: Passed checks: 0,
> Failed checks: 1, Skipped checks: 0` — 44 distinct Terraform rule IDs across S3, EC2,
> RDS, IAM and CloudTrail, plus `CKV_SECRET_6`.
> (Measured 2026-08-21 with the pinned checkov 3.2.334. The count drifts *upward* as
> Prisma adds policies, so on a newer checkov expect "dozens", not exactly 51.)

Note the second block of output, `secrets scan results:` — `CKV_SECRET_6` fires on the
base64-ish string in `aws_instance.web`'s `user_data`. Checkov runs a secrets scanner over
IaC too; lab 02's point applies here as well.

**Before you tune anything, learn to read the noise.** Of those 51 findings, exactly eight
are things an attacker could use tomorrow (public ACL, SSH open to the world, IMDSv1,
unencrypted public RDS, `*` on `*` IAM, blind CloudTrail). The rest are hygiene and
compliance (no lifecycle rule, no event notifications, no cross-region replication).
A finding count is not a risk score:

```bash
# The eight that would actually get you owned
$ ./scripts/run-checkov.sh -d terraform-bad/ --compact --quiet \
    -c CKV_AWS_20,CKV_AWS_24,CKV_AWS_79,CKV_AWS_17,CKV_AWS_16,CKV_AWS_355,CKV_AWS_36,CKV_AWS_67
```

> ✅ Expected: `Passed checks: 1, Failed checks: 8, Skipped checks: 0`. Eight lines,
> four files, no scrolling. Keep this list — Exercise 7 turns it into the CI gate.

### Exercise 2 — KICS on the same code

```bash
$ ./scripts/run-kics.sh -p terraform-bad/ -o exercises --report-formats "json,sarif" --no-progress
$ jq '[.queries[] | select(.severity == "HIGH" or .severity == "CRITICAL") | .query_name] | unique | length' exercises/results.json
```

> ✅ Expected: the scan summary reads `CRITICAL: 2, HIGH: 5, MEDIUM: 12, LOW: 12,
> INFO: 9, TOTAL: 40`, and the `jq` prints **7** — the unique HIGH/CRITICAL query names
> are RDS publicly accessible, S3 ACL open to all users, DB storage not encrypted,
> IAM policy grants full permissions, generic password, sensitive port exposed,
> unrestricted SG ingress. (Measured 2026-08-21 with the pinned KICS v2.1.5.)

KICS uses Rego-style queries; you'll see overlapping but not identical findings vs Checkov. Compare:

```bash
$ ./scripts/diff-checkov-kics.sh
```

> ✅ Expected: `Checkov fired (45 unique IDs)` vs `KICS fired (26 unique queries)`,
> then both lists in full. Neither is a subset of the other — Exercise 3 quantifies that.

### Exercise 3 — tfsec / Trivy IaC, and why the four disagree

```bash
$ ./scripts/run-trivy.sh config terraform-bad/
$ ./scripts/run-tfsec.sh terraform-bad/
```

> ✅ Expected: Trivy prints a per-file breakdown summing to **36 failures**
> (CRITICAL 1, HIGH 20, MEDIUM 6, LOW 9). tfsec prints
> `4 passed, 39 potential problem(s) detected` (CRITICAL 3, HIGH 21, MEDIUM 8, LOW 7).
> Measured 2026-08-21 with the pinned trivy 0.58.1 and tfsec v1.28.14.

Two things you will notice immediately, and both are the point of the exercise.

**tfsec announces its own retirement.** Every run starts with a banner:
`tfsec is joining the Trivy family`. v1.28.14 (May 2025) is the last release — the
rule set is frozen. It still runs, it still finds things, and as you are about to see
it still finds one thing its successor does not.

**Trivy 0.58.1 prints three red `ERROR [rego]` lines** about
`aws/ec2/specify_ami_owners.rego`. That is not your Terraform. Trivy downloads the
*current* check bundle at runtime, and that bundle now contains a check written against
a newer schema than 0.58.1 understands, so it skips exactly that one check.

Confirm it is cosmetic by running with the checks baked into the image instead. Note
that `--skip-check-update` alone is **not** enough — it stops the download but still
reads the bundle already sitting in the shared `trivy-cache` volume, so you have to skip
that volume too:

```bash
# no -v trivy-cache, so the container starts with an empty cache and falls back
# to the checks embedded in the pinned image
$ docker run --rm -v "$(pwd)":/workspace -w /workspace \
    aquasec/trivy:0.58.1 config terraform-bad/ --skip-check-update
```

> ✅ Zero `ERROR` lines, and the same 36 failures. The drifted check was one Trivy was
> going to skip anyway.

That is a small thing, but it is the *shape* of a real supply-chain problem: your
scanner pulls its rules from the network at runtime, so "pinned image" does not mean
"pinned checks". Two runs of the same image on different days can disagree.

#### The measured comparison

All four scanners on the same five files, same day:

| Scanner | Version | Findings | Unique rule IDs |
|---|---|---|---|
| Checkov | 3.2.334 | 51 Terraform + 1 secret | 45 |
| KICS    | v2.1.5   | 40 | 26 |
| tfsec   | v1.28.14 | 39 | 28 |
| Trivy `config` | 0.58.1 | 36 | 26 |

Four tools, four numbers, one codebase. Now the part that actually matters — **which
planted flaw does each one catch?**

| Planted flaw (in `terraform-bad/`) | Checkov | KICS | tfsec | Trivy |
|---|:--:|:--:|:--:|:--:|
| S3 `acl = "public-read"` | ✅ | ✅ | ✅ | ✅ |
| SG ingress 22 from `0.0.0.0/0` | ✅ | ✅ | ✅ | ✅ |
| RDS `publicly_accessible` + unencrypted | ✅ | ✅ | ✅ | ✅ |
| CloudTrail single-region / no validation / no KMS | ✅ | ✅ | ✅ | ✅ |
| IMDSv1 (`http_tokens = "optional"`) | ✅ | ❌ | ✅ | ✅ |
| IAM policy `Action: "*"` on `Resource: "*"` | ✅ | ✅ | ✅ | **❌** |
| Hardcoded `API_KEY` in `user_data` | ✅ | ❌ | ❌ | ❌ |
| Hardcoded RDS `password = "hunter2…"` | **❌** | ✅ | ❌ | ❌ |

Three findings deserve a paragraph each, because each one is a different *kind* of
disagreement:

1. **Trivy misses `*` on `*` IAM.** tfsec fires `AVD-AWS-0057`
   (`aws-iam-no-policy-wildcards`) twice on `rds-iam.tf` — once for the action wildcard,
   once for the resource wildcard. Trivy fires it zero times. This is not a parsing
   quirk: write the same policy three ways (heredoc JSON, `aws_iam_policy_document`,
   `jsonencode`) and tfsec flags all three while Trivy flags none — and Trivy 0.74.0
   behaves the same way. One of "the four classic AWS killers" is invisible to the tool
   that officially replaced tfsec. If you migrated tfsec → Trivy and deleted tfsec from
   CI, you lost that check and nothing told you.

2. **The two planted secrets split cleanly between two tools.** Checkov's secrets
   scanner is entropy-based, so it catches the base64-ish `API_KEY` in `user_data` and
   walks straight past `password = "hunter2hunter2"`. KICS's *Generic Password* query is
   pattern-based on the attribute name, so it does the exact opposite. tfsec and
   `trivy config` do no secret scanning at all here — zero secret rules fired.
   **No single tool in this lab finds both planted secrets.**

3. **tfsec's 39 vs Trivy's 36 is not three extra bugs.** Diff them by rule ID and
   location and the gap is exactly: `AVD-AWS-0057` ×2 (the real gap above) and
   `AVD-AWS-0082` ×1 — a legacy duplicate of `AVD-AWS-0180`, the same "RDS publicly
   accessible" finding reported twice under an old ID and a new one. So of the +3, one
   is double-counting. **A higher finding count is not better coverage.**

Severity is just as unstable. The CloudTrail weaknesses are `LOW` in KICS but `HIGH` in
tfsec. The `0.0.0.0/0` *egress* rule is `CRITICAL` in tfsec and Trivy, and in Checkov it
is `CKV_AWS_382` with no severity at all — open-source Checkov ships **no** severity
data, so every finding lands in SARIF as `"level": "error"` (all 52 of them; check with
`jq '[.runs[0].results[].level] | unique' exercises/checkov.sarif`). That has real
consequences for CI, which is what Exercise 7 is about. Do not build a gate on another
vendor's severity label.

**Why so many tools for one job?**

- Checkov has the broadest framework support (TF, CFN, K8s, ARM, Bicep, Helm, Dockerfile, …)
  and is the only one here that scans for secrets by default
- KICS has good query coverage, is friendly to writing custom Rego, and — as above —
  catches things Checkov's entropy heuristic cannot
- tfsec was the OG fast Terraform scanner; frozen since May 2025, folded into Trivy —
  and it still flags the wildcard IAM policy that its own successor dropped
- Trivy gets you "one tool, many scan types" workflows in CI

In real pipelines: pick **one primary** + **one for differential**, and know concretely
what the differential buys you. "We run two scanners" is not a strategy; "Checkov is our
gate and tfsec covers its IAM-wildcard blind spot" is. Run the eight-row table above
against *your* pair before you trust it.

### Exercise 4 — Fix the findings end-to-end

Open `terraform-bad/s3.tf` and diff against `terraform-good/s3.tf`:

```bash
$ diff -u terraform-bad/s3.tf terraform-good/s3.tf
```

Apply each line of the diff conceptually:

1. `acl = "public-read"` → no ACL + `aws_s3_bucket_public_access_block` blocking everything
2. No versioning → `aws_s3_bucket_versioning { enabled }`
3. No encryption → `aws_s3_bucket_server_side_encryption_configuration` with KMS
4. No logging → `aws_s3_bucket_logging` to a separate access-log bucket

Do the same for the other three:

```bash
$ diff -u terraform-bad/ec2.tf        terraform-good/ec2.tf
$ diff -u terraform-bad/rds-iam.tf    terraform-good/rds.tf
$ diff -u terraform-bad/cloudtrail.tf terraform-good/cloudtrail.tf
```

Then rescan the hardened tree — **this is the loop closing**:

```bash
$ ./scripts/run-checkov.sh -d terraform-good/ --compact --quiet
```

> ✅ Expected: `Passed checks: 135, Failed checks: 0, Skipped checks: 4`
> (measured 2026-08-21 with checkov 3.2.334; the passed count drifts with the version,
> the **0 failures and 4 skips** are the part that must hold).

The four *skipped* checks matter as much as the zero failures. Open `terraform-good/s3.tf`
and read the inline comments:

```hcl
# checkov:skip=CKV_AWS_144:Single-region lab bucket. Cross-region replication is a
# deliberate, documented acceptance -- not an oversight.
```

That is what a real remediation ends in: most findings fixed, a small number
**consciously accepted with a written reason that lives next to the code** and shows up
in the scanner output as `SKIPPED` rather than silently disappearing from a dashboard.
An untriaged finding and an accepted risk look identical in a CVE count; they are
completely different in a review.

#### "Zero findings" is a per-scanner statement

Now run the *other three* against the same hardened tree:

```bash
# --output-name keeps Exercise 2's results.json from being overwritten
$ ./scripts/run-kics.sh  -p terraform-good/ -o exercises --output-name results-good \
    --report-formats json --no-progress
$ ./scripts/run-tfsec.sh terraform-good/
$ ./scripts/run-trivy.sh config terraform-good/
```

> ✅ Expected (measured 2026-08-21):
> **KICS** `CRITICAL 0, HIGH 1, MEDIUM 2, LOW 6, INFO 10, TOTAL: 19` ·
> **tfsec** `54 passed, 4 potential problem(s) detected` (one each of
> CRITICAL/HIGH/MEDIUM/LOW) ·
> **Trivy** two file blocks totalling 3 failures (`CRITICAL 1` in `ec2.tf`,
> `LOW 2` in `s3.tf`) — against Checkov's 0.

`terraform-good/` was hardened until *Checkov* was quiet. It is not quiet anywhere else,
and that is the honest ending to this exercise. Read what is left:

| Residual finding | Verdict |
|---|---|
| tfsec/Trivy `AVD-AWS-0104` **CRITICAL**: "unrestricted egress to any IP" (`ec2.tf:18`) | **Accepted risk.** It is outbound TCP/443 to the internet, which is how the instance reaches AWS APIs. Rated CRITICAL anyway. |
| tfsec `AVD-AWS-0057` **HIGH**: IAM wildcard on `logs:CreateLogStream` (`cloudtrail.tf:29`) | **False positive.** The resource is `"${aws_cloudwatch_log_group.trail.arn}:*"` — the `:*` log-stream suffix that CloudTrail→CloudWatch *requires*. tfsec cannot resolve the ARN before apply, substitutes a placeholder, and sees a trailing wildcard. |
| KICS **HIGH** "Passwords And Secrets - Generic Password" (`rds.tf:51`) | **False positive.** The line is `password = random_password.db.result`. The query matches the attribute name, not the value. |
| tfsec/Trivy/KICS: log bucket has no access logging of its own (`s3.tf:79`) | **Accepted risk.** Logging the log bucket into itself is a loop; a second bucket just moves the question. Real answer is Object Lock, which is out of scope here. |
| KICS ×10 INFO "Resource Not Using Tags" (SGs, KMS keys, log groups, IAM roles, param groups) | **Noise here, policy elsewhere.** Untagged support resources. Enforce it with a custom check like Exercise 5's if your org cares. |
| KICS ×5 LOW "IAM Access Analyzer Not Enabled" | **Wrong layer.** That is an account setting, not something any `.tf` file in this directory can satisfy. Prowler (Exercise 6) is where that check belongs. |

That is the whole triage skill in one table: of the residual findings, **two are
deliberate acceptances, two are false positives caused by the scanner not being able to
resolve a value that only exists after apply, one is aimed at the wrong layer entirely,
and the rest is hygiene noise.** Zero of them are exploitable. None of that is visible
from a finding count — you have to open each one.

Two rules follow, and they are the ones worth taking to work:

1. **Tune to your gate, then measure your gate's blind spots.** Getting to zero in your
   primary scanner is the goal. Believing zero means "secure" is the mistake.
2. **A finding you have read and rejected is a finding you have handled.** Write it down
   next to the code — a `checkov:skip` comment, a `tfsec:ignore`, a KICS
   `# kics-scan ignore-line` — so the *next* person sees the reasoning, not the finding.

### Exercise 5 — Custom Checkov policy

Companies often have policies like "all S3 buckets must be tagged with `data_classification`."
The policy is already written for you at `exercises/custom-policies/aws_s3_data_classification.py`
— read it, then run it:

```python
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckCategories, CheckResult

class S3DataClassification(BaseResourceCheck):
    def __init__(self):
        super().__init__(
            name="S3 buckets must carry data_classification tag",
            id="CKV_CUSTOM_S3_TAG_DC",
            categories=[CheckCategories.GENERAL_SECURITY],
            supported_resources=["aws_s3_bucket"],
        )

    def scan_resource_conf(self, conf):
        tags_conf = conf.get("tags", [{}])
        tags = tags_conf[0] if isinstance(tags_conf, list) else tags_conf
        if isinstance(tags, dict) and "data_classification" in tags:
            return CheckResult.PASSED
        return CheckResult.FAILED


check = S3DataClassification()
```

(`conf["tags"]` is normally a one-element list wrapping the dict, but not in every
parse path — hence the `isinstance` dance rather than a bare `[0]`.)

Run it:

```bash
$ ./scripts/run-checkov.sh -d terraform-bad/ \
    --external-checks-dir exercises/custom-policies/
```

> ✅ Expected: `CKV_CUSTOM_S3_TAG_DC` **FAILED** on `aws_s3_bucket.data` and
> `aws_s3_bucket.trail`. Run it against `terraform-good/` and the same check **PASSES**
> on both buckets there.

> 🪤 **Gotcha that will cost you an hour.** `--external-checks-dir` silently ignores any
> directory without an `__init__.py` — checkov logs
> `No __init__.py found in <dir>. Cannot load any check here.` at INFO level and then
> reports a perfectly clean run. That empty `exercises/custom-policies/__init__.py` is
> load-bearing. If a custom policy "doesn't fire", re-run with `LOG_LEVEL=INFO` (the
> message is logged at INFO, not DEBUG) before you start debugging the policy logic.
> Reproduce it: copy `aws_s3_data_classification.py` into an empty directory *without*
> the `__init__.py`, point `--external-checks-dir` at it, and watch `CKV_CUSTOM_S3_TAG_DC`
> vanish from the output with no error and no change in exit code.

### Exercise 6 — Prowler (live cloud posture)

**Read this before running anything.** Prowler is the only tool in this lab that talks to
a real cloud account, and it is blunt about the split:

- **A posture scan requires real credentials. There is no offline, demo, or sample
  dataset.** With no credentials Prowler prints its banner and then
  `CRITICAL: NoCredentialsError[1313]: Unable to locate credentials` and stops.
  Verified 2026-08-21 with Prowler 5.39.1. That is expected; do not chase it.
- **The catalogs are fully readable offline** — every check, every service, every
  compliance framework, and the control text of each framework. That is Exercise 6a,
  below, and it is the part everyone can actually do.

> 🔐 `scripts/run-prowler.sh` will bind-mount `~/.aws` read-only into the container
> **only if you set `PROWLER_MOUNT_AWS=1`**, and it tells you when it does. Nothing in
> this lab needs it. Do not set it against an account you would not want a 639-check
> read sweep running in — start with a read-only role in a sandbox.

#### 6a — What it would check (no credentials, run this one)

```bash
$ ./scripts/run-prowler.sh aws --list-checks        # every check ID, service, severity
$ ./scripts/run-prowler.sh aws --list-services
$ ./scripts/run-prowler.sh aws --list-compliance
$ ./scripts/run-prowler.sh aws --list-compliance-requirements cis_4.0_aws
```

> ✅ Expected (measured 2026-08-21, Prowler 5.39.1):
> `There are 639 available checks.` · `There are 89 available services.` ·
> `There are 49 available Compliance Frameworks.`

The fourth command is the one worth your time. It prints the CIS AWS Foundations
Benchmark **requirement by requirement, with the Prowler checks that satisfy each one**:

```
Requirement Id: 1.1
	- Description: Maintain current contact details
	- Checks:
 		[aws] account_maintain_current_contact_details
```

`cis_4.0_aws` has **64 requirements**, and every one of them maps to at least one check.
Now read the check names and ask the question this lab is actually about: *could a
Terraform file have prevented this?* Group them by check family and the answer splits
almost in half — **34 of the 64 map only to `account_*`, `iam_*`, `organizations_*`,
`accessanalyzer_*`, `securityhub_*`, `guardduty_*`, `config_*` or CloudWatch
metric-filter checks** (§1 almost in its entirety, plus most of §4). Count them yourself:

```bash
$ ./scripts/run-prowler.sh aws --list-compliance-requirements cis_4.0_aws \
  | sed 's/\x1b\[[0-9;]*m//g' \
  | awk '/^Requirement Id:/{id=$3; n=0; a=0} /\[aws\]/{n++; if ($2 ~ /^(account|iam|organizations|accessanalyzer|securityhub|guardduty|config)_|^cloudwatch_log_metric_filter/) a++} /^$/{if (id && n && n==a) c++; id=""} END{print c, "of 64 are account-state only"}'
```

Those are root-account MFA, unused credentials, an Access Analyzer being switched on, a
metric filter existing, log retention on the account's trail — *account state that no
`.tf` file in `terraform-good/` can express*, let alone that Checkov could have failed
a PR on.

Remember the five KICS "IAM Access Analyzer Not Enabled" findings from Exercise 4 that
had nowhere to go? **This is where they go.** IaC scanning and CSPM are not two tools
for one job. They cover two different halves of the problem, they barely overlap, and
CIS is scored across both — which is why an org with a perfectly clean Checkov gate can
still fail its benchmark by 50%.

#### 6b — An actual posture scan (needs your own AWS credentials)

Only if you have read-only creds for an account you are allowed to scan:

```bash
$ PROWLER_MOUNT_AWS=1 ./scripts/run-prowler.sh aws \
    --output-formats html,csv,json-ocsf \
    --output-directory /workspace/exercises/prowler/
```

Prowler runs 639 checks across CIS, NIST, PCI, ISO, AWS Foundational Security Best
Practices. **It's not a static IaC scanner — it asks AWS what's actually there.** Two
reasons that matters:

1. People click in the console and bypass IaC.
2. Some misconfigs are only visible at runtime (e.g., a CloudTrail trail exists in the TF, but is paused).

### Exercise 7 — CI integration patterns

Two templates in `exercises/ci/`. Both copy-paste into a real repo; both carry comments
explaining the traps, because each one has a trap that fails *silently*.

**`pre-commit-iac.yaml`** — blocks commits on misconfigs in `*.tf`. Try it:

```bash
$ mkdir /tmp/pc && cd /tmp/pc && git init -q .
$ cp <lab>/exercises/ci/pre-commit-iac.yaml .pre-commit-config.yaml
$ cp <lab>/terraform-bad/s3.tf . && git add -A
$ pre-commit run --all-files
```

> ✅ Expected: `Checkov......Failed`, `Passed checks: 3, Failed checks: 8`, exit 1.
> Verified 2026-08-21 with pre-commit 4.6.2 + checkov 3.2.334.

Two things that will cost you time, both handled in the template:

- The upstream hook's `entry` is already `checkov -d .`. Adding `-d, .` to `args` — the
  obvious thing to write — makes checkov scan the tree **twice** and print two summary
  blocks with cumulative counts (`Failed checks: 8`, then `Failed checks: 16`). Nothing
  errors. It just looks like your Terraform doubled.
- `id: checkov` builds checkov in a pre-commit virtualenv. On Python 3.14 that dies with
  `error: can't find Rust compiler` while building `rustworkx`. Hence the pinned
  `default_language_version`. The commented-out `checkov_container` hook is the
  Docker-only escape hatch.

**`github-actions-checkov.yml`** — scan on PR, publish to the Security tab, block on the
eight checks from Exercise 1. Two traps, both of which produce a **green build that
checks nothing**:

- `output_file_path: results.sarif` (no trailing comma) makes checkov treat the value as
  a *directory* and write `results.sarif/results_sarif.sarif`. The `upload-sarif` step
  then gets a directory. The template writes `"results.sarif,"` — the comma is load-bearing.
  Reproduce it locally:

  ```bash
  $ ./scripts/run-checkov.sh -d terraform-bad/ -o sarif --output-file-path exercises/out.sarif
  $ ls -d exercises/out.sarif     # a DIRECTORY, containing results_sarif.sarif
  $ rm -rf exercises/out.sarif
  $ ./scripts/run-checkov.sh -d terraform-bad/ -o sarif --output-file-path "exercises/out.sarif,"
  $ file exercises/out.sarif      # JSON data
  ```

- **Severity gating does not work in open-source checkov.** Severities come from the
  Prisma platform via an API key; without one, checkov has no severity for any check.
  So `soft_fail_on: LOW,MEDIUM` does nothing (the job fails on *every* finding), and
  `hard_fail_on: HIGH,CRITICAL` matches nothing and passes a repo full of critical
  findings. Prove it:

  ```bash
  # soft-fail on EVERY severity -- still exits 1
  $ ./scripts/run-checkov.sh -d terraform-bad/ --quiet --compact \
      --soft-fail-on LOW,MEDIUM,HIGH,CRITICAL; echo "exit=$?"     # exit=1

  # hard-fail on HIGH,CRITICAL -- exits 0 with 51 failed checks
  $ ./scripts/run-checkov.sh -d terraform-bad/ --quiet --compact \
      --hard-fail-on HIGH,CRITICAL; echo "exit=$?"                # exit=0

  # gate on check IDs instead -- this actually works
  $ ./scripts/run-checkov.sh -d terraform-bad/ --quiet --compact \
      --hard-fail-on CKV_AWS_20,CKV_AWS_24,CKV_AWS_79,CKV_AWS_17,CKV_AWS_16,CKV_AWS_355,CKV_AWS_36,CKV_AWS_67
  $ echo "exit=$?"                                                 # exit=1
  $ ./scripts/run-checkov.sh -d terraform-good/ --quiet --compact \
      --hard-fail-on CKV_AWS_20,CKV_AWS_24,CKV_AWS_79,CKV_AWS_17,CKV_AWS_16,CKV_AWS_355,CKV_AWS_36,CKV_AWS_67
  $ echo "exit=$?"                                                 # exit=0
  ```

  All four exit codes measured 2026-08-21 with checkov 3.2.334.

The pattern that survives contact with a real repo: **report everything, block on a
short explicit list.** Full scan `soft_fail: true` → SARIF → the Security tab, where
GitHub does the net-new diff for you; then a second, narrow step whose only job is to
turn the PR red on the handful of check IDs you decided are exploitable. A gate that
fires on all 51 findings gets disabled within a week; a gate that fires on eight does not.

---

## 💡 Key Concepts

| Concept                | TL;DR                                                                                          |
|------------------------|------------------------------------------------------------------------------------------------|
| **IaC scanning (SAST for infra)** | Static analysis of Terraform / CloudFormation / Bicep / K8s YAML. Cheap and pre-deploy.|
| **CSPM**               | Cloud Security Posture Management. Live scan of the cloud account (Prowler, ScoutSuite).       |
| **Misconfig vs vuln**  | Misconfig = your settings (public bucket). Vuln = vendor bug (CVE in EC2 AMI). Both matter.    |
| **CIS / NIST / PCI**   | Compliance frameworks. Tools tag findings by which framework they violate. 34 of the 64 CIS AWS 4.0 requirements describe *account state*, which no `.tf` file can satisfy — see Exercise 6a. |
| **Severity is vendor opinion** | The same CloudTrail gap is LOW in KICS and HIGH in tfsec, and open-source Checkov has no severities at all. Never build a CI gate on someone else's label. |
| **Drift**              | When live cloud doesn't match IaC. Prowler catches drift; static scanners don't.               |
| **Plan-time vs apply-time** | Some checks need the actual `terraform plan` JSON; others read source. Scanners differ.   |
| **Suppression with a reason** | `#checkov:skip=CKV_ID:reason` in the resource. Shows as `SKIPPED`, survives review, expires when someone re-reads it. Beats a wiki page of "known issues". |
| **Finding ≠ risk**     | A scanner reports on the code. Whether it matters depends on the account, the data, the network path and whether the resource is even deployed. Triage is the job; the scan is the input. |

### The four classic AWS killers

1. **Public S3 bucket** — `acl = "public-read"` or no `PublicAccessBlock`. One greppable line; thousands of incidents.
2. **0.0.0.0/0 SG rule on 22/3389** — SSH/RDP exposed to the internet. Bots find it in minutes.
3. **IAM `*` on `*`** — admin everywhere. Use SCPs to forbid. And note from Exercise 3:
   this is the one of the four that **Trivy does not flag at all**.
4. **No CloudTrail / unencrypted CloudTrail** — no audit trail = no incident response.
   Compare `terraform-bad/cloudtrail.tf` (single region, no log-file validation, no KMS,
   no CloudWatch stream) with the good one. Lab 08 is unrunnable without this file.

A good IaC scanner blocks these on the PR. *Your* IaC scanner blocks three of them —
which three depends on which scanner, and you only find out by measuring.

---

## 🏆 Challenge

1. **Plan-time scan.** `terraform plan` normally needs real credentials — the AWS
   provider calls `sts:GetCallerIdentity` before it will produce a plan, and fake keys
   get you `InvalidClientTokenId`. You can plan entirely offline by telling the provider
   to skip that handshake. Copy `terraform-bad/` somewhere scratch and replace its
   `provider "aws"` block with:

   ```hcl
   provider "aws" {
     region                      = "us-east-1"
     access_key                  = "mock"
     secret_key                  = "mock"
     skip_credentials_validation = true
     skip_requesting_account_id  = true
     skip_metadata_api_check     = true
     skip_region_validation      = true
   }
   ```

   Then:

   From inside that scratch copy (everything below runs in the current directory):

   ```bash
   $ D="docker run --rm -v $(pwd):/tf -w /tf"
   $ $D hashicorp/terraform:1.13 init
   $ $D hashicorp/terraform:1.13 plan -out=tfplan
   $ $D hashicorp/terraform:1.13 show -json tfplan > plan.json
   $ $D bridgecrew/checkov:3.2.334 -f plan.json --compact --quiet
   ```

   > ✅ Measured 2026-08-21 (terraform 1.13, aws v5.100.0, checkov 3.2.334):
   > `terraform_plan scan results: Passed checks: 18, Failed checks: 49`
   > — against `Passed checks: 16, Failed checks: 51` on the same code as source.
   >
   > The check type changed from `terraform` to `terraform_plan`, and **exactly two
   > checks flipped FAILED → PASSED**: `CKV_AWS_226` (RDS auto minor version upgrade)
   > and `CKV_AWS_23` (security group rule description). Neither `.tf` file changed.
   >
   > `CKV_AWS_226` is the interesting one. `terraform-bad/rds-iam.tf` never sets
   > `auto_minor_version_upgrade`, so the source scan calls it a finding — but the AWS
   > provider defaults it to `true`, and the plan says so. **Plan-time scanning deleted
   > a false positive that source scanning cannot know is false.** That is what the
   > extra fidelity buys you: provider defaults, resolved variables, expanded
   > `count`/`for_each`.
   >
   > Then notice what it costs: nothing new was found. Plan mode fired 42 distinct rule
   > IDs to source mode's 44 — a strict subset. Work out why `CKV_AWS_23` stopped firing
   > and decide whether you believe it.
2. **OPA / Conftest.** Write Rego policies enforcing your org's tag scheme (env, owner, cost-center). Run via `conftest test terraform-good/`. Compare ergonomics with Checkov custom checks.
3. **Drift detection.** Take the good Terraform, apply it, then change one setting in the
   AWS console. Show that Prowler reports the drift but Checkov doesn't. **This is the
   one thing in this lab that costs real money in a real account** — `terraform-good/`
   creates a Multi-AZ RDS instance with Performance Insights and `deletion_protection =
   true`. Budget for it, or do the same demo with the S3 bucket alone.
4. **Multi-cloud.** Add a bad Azure resource (storage account with `allow_blob_public_access = true`) and confirm Checkov flags it. Bonus: GCP IAM allUsers.

---

## 📚 Further reading

- [Checkov docs](https://www.checkov.io/) — especially the policy authoring guide
- [KICS](https://github.com/Checkmarx/kics) and its [query catalog](https://docs.kics.io/latest/queries/all-queries/)
- [tfsec](https://aquasecurity.github.io/tfsec/) (frozen at v1.28.14, May 2025) and the
  [tfsec → Trivy announcement](https://github.com/aquasecurity/tfsec/discussions/1994)
- [Trivy misconfiguration scanning](https://trivy.dev/latest/docs/scanner/misconfiguration/)
  and the [AVD check catalog](https://avd.aquasec.com/misconfig/)
- [Prowler](https://github.com/prowler-cloud/prowler)
- [AWS Well-Architected Security pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [Checkov custom policies (Python)](https://www.checkov.io/3.Custom%20Policies/Python%20Custom%20Policies.html)

➡️ Next: [Lab 08 — Incident Response](../08-incident-response/)
