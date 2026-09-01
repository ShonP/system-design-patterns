#!/usr/bin/env bash
# Render insecure/Dockerfile from insecure/Dockerfile.tmpl, substituting a freshly
# generated Stripe-shaped key for __STRIPE_SECRET_KEY__.
#
# The exercise measures 3 CRITICAL stripe-secret-token findings. That only happens if
# the planted value is shaped like a real key: Trivy's allow-rules discard anything
# containing EXAMPLE, and an earlier version of this lab used such a placeholder and
# reported zero -- teaching the opposite of the truth. The value is therefore generated
# at setup rather than committed. See 09-security/scripts/fake-secrets.sh.
#
# The template is line-for-line identical to the output, so the README's `Dockerfile:9`
# references stay correct.
#
#   ./scripts/plant-secrets.sh            # render if missing
#   ./scripts/plant-secrets.sh --force    # re-render with a new key (busts build cache)
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -f insecure/Dockerfile && "${1:-}" != "--force" ]]; then
  echo "✅ insecure/Dockerfile already rendered. Pass --force to regenerate."
  exit 0
fi

source "$(cd ../scripts && pwd)/fake-secrets.sh"

KEY=$(fake_stripe_secret_key) awk '{ gsub(/__STRIPE_SECRET_KEY__/, ENVIRON["KEY"]); print }' \
  insecure/Dockerfile.tmpl > insecure/Dockerfile

echo "✅ rendered insecure/Dockerfile (planted key on line $(grep -n API_KEY insecure/Dockerfile | cut -d: -f1))"
