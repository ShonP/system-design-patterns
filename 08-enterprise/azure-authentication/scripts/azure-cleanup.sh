#!/usr/bin/env bash
# Tear down everything azure-setup.sh created.
set -euo pipefail

RG="${RG:-rg-azure-auth-lab}"

if [ ! -f .env.azure ]; then
  echo "No .env.azure found. Pass PREFIX manually if you know it."
  exit 1
fi

source .env.azure

echo "Deleting app registrations..."
az ad app delete --id "$API_A_CLIENT_ID" || true
az ad app delete --id "$API_B_CLIENT_ID" || true
az ad app delete --id "$DAEMON_CLIENT_ID" || true

echo "Deleting resource group $RG ..."
az group delete -n "$RG" --yes --no-wait

echo "Removing .env.azure"
rm -f .env.azure

echo "Done."
