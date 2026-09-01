#!/usr/bin/env bash
# Generators for fake-but-real-shaped credentials, used to seed the secret-scanning
# exercises in labs 01, 02 and 04.
#
# WHY THIS FILE EXISTS
#
# These labs need planted secrets that a scanner will actually fire on. A placeholder
# that says EXAMPLE or FAKE is discarded by every scanner's built-in allow-rules, so a
# lab seeded with one silently teaches the opposite of the truth (lab 04's README has
# the measurement: 3 CRITICAL findings with a real-shaped value, 0 with a placeholder).
#
# But a real-shaped credential committed to git is a credential as far as GitHub's push
# protection is concerned, and it blocks the push. Both constraints are satisfied by
# generating the values at setup time instead of committing them: git holds only this
# generator, the working tree holds values that are correctly shaped and freshly random,
# and every learner gets a different set.
#
# Nothing here authenticates to anything. The values are drawn from /dev/urandom.
#
# Usage:  source "$(git rev-parse --show-toplevel)/09-security/scripts/fake-secrets.sh"
#         key=$(fake_aws_access_key_id)

# Random string of $1 characters drawn from the character class $2.
# The subshell drops pipefail: `cut` closing early is expected, not an error.
_fake_rand() {
  ( set +o pipefail
    LC_ALL=C openssl rand -base64 $(( $1 * 3 + 32 )) \
      | LC_ALL=C tr -dc "$2" \
      | cut -c1-"$1"
  )
}

# AKIA + 16 characters of the *base32* alphabet — A-Z and 2-7, no 0/1/8/9. That is the
# shape AWS actually issues, and scanners match on it literally: gitleaks' rule is
# [A-Z2-7]{16}, so a key containing a 0 or an 8 is reported as a bland `generic-api-key`
# instead of `aws-access-token`, and lab 02's exercise 1 expectation silently breaks.
# Measured: 2/20 keys matched before this was narrowed, 20/20 after.
fake_aws_access_key_id()     { printf 'AKIA%s' "$(_fake_rand 16 'A-Z2-7')"; }

# 40 characters of base64 alphabet. Scanners gate on both shape and entropy here.
fake_aws_secret_access_key() { _fake_rand 40 'A-Za-z0-9/+'; }

fake_stripe_secret_key()     { printf 'sk_live_%s' "$(_fake_rand 24 'A-Za-z0-9')"; }
fake_github_pat()            { printf 'ghp_%s' "$(_fake_rand 36 'A-Za-z0-9')"; }
fake_sendgrid_api_key()      { printf 'SG.%s.%s' "$(_fake_rand 22 'A-Za-z0-9_-')" "$(_fake_rand 43 'A-Za-z0-9_-')"; }

# Slack's documented shape: /services/T<8+>/B<8+>/<24 alphanumerics>.
fake_slack_webhook_url() {
  printf 'https://hooks.slack.com/services/T%s/B%s/%s' \
    "$(_fake_rand 8 'A-Z0-9')" "$(_fake_rand 8 'A-Z0-9')" "$(_fake_rand 24 'A-Za-z0-9')"
}

fake_password()   { _fake_rand 20 'A-Za-z0-9'; }
fake_jwt_secret() { _fake_rand 48 'A-Za-z0-9'; }
