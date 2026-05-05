# Lab 07 — Infrastructure as Code (IaC) Security

## 🎯 What you'll learn

- Scan **Terraform** with **Checkov**, **KICS**, **tfsec**, and Trivy — and understand why you'd run more than one
- Find common AWS misconfigs: public S3 buckets, open security groups, unencrypted RDS, IMDSv1, missing CloudTrail
- Fix the misconfigs by diffing `terraform-bad/` against `terraform-good/`
- Use **Prowler** for **live cloud posture** scanning (CSPM)
- Read CIS / AWS Foundations Benchmark output and triage findings

## 📋 Prerequisites

- Docker
- Optional: Terraform CLI (`brew install terraform`) for `terraform plan` exercises
- Optional: AWS account with read-only credentials to try Prowler against a live tenant. **The lab works without this** — Prowler offers a sample/offline mode.

## 🔧 Setup

```bash
$ cd 07-infrastructure-as-code
$ ls terraform-bad/   # 4 files: 3 deliberately misconfigured AWS resources
$ ls terraform-good/  # the same resources, hardened
```

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

> ✅ Expected: 30+ failed checks across S3, EC2, RDS, IAM.

### Exercise 2 — KICS on the same code

```bash
$ ./scripts/run-kics.sh -p terraform-bad/ -o exercises --report-formats "json,sarif" --no-progress
$ jq '[.queries[] | select(.severity == "HIGH" or .severity == "CRITICAL") | .query_name] | unique | length' exercises/results.json
```

KICS uses Rego-style queries; you'll see overlapping but not identical findings vs Checkov. Compare:

```bash
$ ./scripts/diff-checkov-kics.sh
```

### Exercise 3 — tfsec / Trivy IaC

```bash
$ ./scripts/run-trivy.sh config terraform-bad/
$ ./scripts/run-tfsec.sh terraform-bad/
```

Same patterns again. **Why so many tools for one job?**

- Checkov has the broadest framework support (TF, CFN, K8s, ARM, Bicep, Helm, Dockerfile, …)
- KICS has good query coverage and is friendly to writing custom Rego
- tfsec was the OG fast Terraform scanner; now folded into Trivy
- Trivy gets you "one tool, two formats" workflows in CI

In real pipelines: pick **one primary** + **one for differential** to catch what your primary misses.

### Exercise 4 — Fix one finding end-to-end

Open `terraform-bad/s3.tf` and diff against `terraform-good/s3.tf`:

```bash
$ diff -u terraform-bad/s3.tf terraform-good/s3.tf
```

Apply each line of the diff conceptually:

1. `acl = "public-read"` → no ACL + `aws_s3_bucket_public_access_block` blocking everything
2. No versioning → `aws_s3_bucket_versioning { enabled }`
3. No encryption → `aws_s3_bucket_server_side_encryption_configuration` with KMS
4. No logging → `aws_s3_bucket_logging` to a separate access-log bucket

Rerun Checkov on `terraform-good/`:

```bash
$ ./scripts/run-checkov.sh -d terraform-good/ -o cli
```

> ✅ Expected: zero failures (or very few low-severity, e.g., MFA Delete on S3 which requires a TF state precondition).

### Exercise 5 — Custom Checkov policy

Companies often have policies like "all S3 buckets must be tagged with `data_classification`." Write `exercises/custom-policies/aws_s3_data_classification.py`:

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
        tags = conf.get("tags", [{}])[0]
        if isinstance(tags, dict) and "data_classification" in tags:
            return CheckResult.PASSED
        return CheckResult.FAILED

check = S3DataClassification()
```

Run it:

```bash
$ ./scripts/run-checkov.sh -d terraform-bad/ \
    --external-checks-dir exercises/custom-policies/
```

> ✅ Expected: your `CKV_CUSTOM_S3_TAG_DC` check fires on the bad bucket.

### Exercise 6 — Prowler (live cloud posture)

If you have AWS read-only creds set:

```bash
$ ./scripts/run-prowler.sh aws \
    --output-formats html,csv,json-ocsf \
    --output-directory exercises/prowler/
```

If you don't, run it with the bundled sample mode:

```bash
$ ./scripts/run-prowler.sh aws --offline-help    # see the help & framework list
```

Prowler runs ~500 checks across CIS, NIST, PCI, ISO, AWS Foundational Security Best Practices. **It's not a static IaC scanner — it asks AWS what's actually there.** Two reasons that matters:

1. People click in the console and bypass IaC.
2. Some misconfigs are only visible at runtime (e.g., a CloudTrail trail exists in the TF, but is paused).

### Exercise 7 — CI integration patterns

Pick one of the templates in `exercises/ci/`:

- `github-actions-checkov.yml` — fail PR on any new HIGH/CRITICAL finding
- `pre-commit-iac.yaml` — block commits on misconfigs in `*.tf` files

Both copy-paste into a real repo. The pattern is the same: scan on PR, post findings as comments, fail on net-new only.

---

## 💡 Key Concepts

| Concept                | TL;DR                                                                                          |
|------------------------|------------------------------------------------------------------------------------------------|
| **IaC scanning (SAST for infra)** | Static analysis of Terraform / CloudFormation / Bicep / K8s YAML. Cheap and pre-deploy.|
| **CSPM**               | Cloud Security Posture Management. Live scan of the cloud account (Prowler, ScoutSuite).       |
| **Misconfig vs vuln**  | Misconfig = your settings (public bucket). Vuln = vendor bug (CVE in EC2 AMI). Both matter.    |
| **CIS / NIST / PCI**   | Compliance frameworks. Tools tag findings by which framework they violate.                     |
| **Drift**              | When live cloud doesn't match IaC. Prowler catches drift; static scanners don't.               |
| **Plan-time vs apply-time** | Some checks need the actual `terraform plan` JSON; others read source. Scanners differ.   |

### The four classic AWS killers

1. **Public S3 bucket** — `acl = "public-read"` or no `PublicAccessBlock`. One greppable line; thousands of incidents.
2. **0.0.0.0/0 SG rule on 22/3389** — SSH/RDP exposed to the internet. Bots find it in minutes.
3. **IAM `*` on `*`** — admin everywhere. Use SCPs to forbid.
4. **No CloudTrail / unencrypted CloudTrail** — no audit trail = no incident response.

A good IaC scanner blocks these on the PR.

---

## 🏆 Challenge

1. **Plan-time scan.** Generate a `terraform plan -out=tfplan` then `terraform show -json tfplan > plan.json`. Run `checkov -f plan.json` and explain what extra checks become possible.
2. **OPA / Conftest.** Write Rego policies enforcing your org's tag scheme (env, owner, cost-center). Run via `conftest test terraform-good/`. Compare ergonomics with Checkov custom checks.
3. **Drift detection.** Take the good Terraform, apply it, then change one setting in the AWS console. Show that Prowler reports the drift but Checkov doesn't.
4. **Multi-cloud.** Add a bad Azure resource (storage account with `allow_blob_public_access = true`) and confirm Checkov flags it. Bonus: GCP IAM allUsers.

---

## 📚 Further reading

- [Checkov docs](https://www.checkov.io/) — especially the policy authoring guide
- [KICS](https://github.com/Checkmarx/kics) and its [query catalog](https://docs.kics.io/latest/queries/all-queries/)
- [tfsec / trivy config](https://aquasecurity.github.io/tfsec/)
- [Prowler](https://github.com/prowler-cloud/prowler)
- [AWS Well-Architected Security pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- `research-report.md` §2.4, §4.2 in this repo

➡️ Next: [Lab 08 — Incident Response](../08-incident-response/)
