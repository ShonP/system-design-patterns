#!/usr/bin/env bash
# Run both scanners on terraform-bad/ and diff the rule names that fired.
set -euo pipefail
mkdir -p exercises
./scripts/run-checkov.sh -d terraform-bad/ -o json --output-file-path exercises/ >/dev/null 2>&1 || true
./scripts/run-kics.sh    -p terraform-bad/ -o exercises --report-formats json --no-progress >/dev/null 2>&1 || true

CK=$(jq -r '.results.failed_checks[]?.check_id' exercises/results_json.json 2>/dev/null \
       || jq -r '.results.failed_checks[]?.check_id' exercises/checkov_results.json 2>/dev/null \
       || true | sort -u)
KICS=$(jq -r '.queries[].query_id' exercises/results.json 2>/dev/null | sort -u)

echo "Checkov fired:"; echo "$CK" | sed 's/^/  /' | head -30
echo
echo "KICS fired:";    echo "$KICS" | sed 's/^/  /' | head -30
echo
echo "(IDs are different between scanners — manually map by description for full overlap analysis.)"
