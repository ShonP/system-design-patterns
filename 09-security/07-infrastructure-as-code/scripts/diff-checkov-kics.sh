#!/usr/bin/env bash
# Run both scanners on terraform-bad/ and diff the rule IDs that fired.
# Run from the lab root: ./scripts/diff-checkov-kics.sh
set -euo pipefail
mkdir -p exercises

echo "==> checkov (writes exercises/results_json.json)"
./scripts/run-checkov.sh -d terraform-bad/ -o json --output-file-path exercises/ >/dev/null 2>&1 || true

echo "==> kics (writes exercises/results.json)"
./scripts/run-kics.sh -p terraform-bad/ -o exercises --report-formats json --no-progress >/dev/null 2>&1 || true

CK_FILE=""
for f in exercises/results_json.json exercises/checkov_results.json; do
  [[ -f $f ]] && CK_FILE=$f && break
done

if [[ -z $CK_FILE ]]; then
  echo "No checkov JSON found. Is checkov installed / did the docker run succeed?" >&2
else
  # checkov emits either an object or an array of objects (one per check_type).
  CK=$(jq -r '(if type=="array" then . else [.] end)[].results.failed_checks[]?.check_id' "$CK_FILE" | sort -u)
  echo
  echo "Checkov fired ($(echo "$CK" | grep -c . ) unique IDs):"
  echo "$CK" | sed 's/^/  /' | head -60
fi

if [[ -f exercises/results.json ]]; then
  KICS=$(jq -r '.queries[]?.query_name' exercises/results.json | sort -u)
  echo
  echo "KICS fired ($(echo "$KICS" | grep -c . ) unique queries):"
  echo "$KICS" | sed 's/^/  /' | head -60
else
  echo "No KICS JSON found (exercises/results.json)." >&2
fi

cat <<'NOTE'

Rule IDs are not comparable between scanners (CKV_AWS_24 vs "SSH port is exposed to
the internet"), so there is no clean set intersection. Map them by description --
and notice that neither tool is a superset of the other. That is the whole argument
for a primary scanner plus a differential one.
NOTE
