#!/usr/bin/env bash
#
# Generate self-signed TLS certificates for the networking lab.
# Creates: CA cert, server cert, and client cert (for mTLS).
#
# Usage:  ./generate_certs.sh
# Output: ./certs/ directory with all certificates and keys
#

set -euo pipefail

CERTS_DIR="$(dirname "$0")/certs"
mkdir -p "$CERTS_DIR"

echo "=== Generating Certificate Authority (CA) ==="
openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$CERTS_DIR/ca.key" \
    -out "$CERTS_DIR/ca.crt" \
    -days 365 \
    -subj "/CN=Networking Lab CA/O=System Design Labs"

echo ""
echo "=== Generating Server Certificate ==="
# Create server private key and CSR (Certificate Signing Request)
openssl req -newkey rsa:2048 -nodes \
    -keyout "$CERTS_DIR/server.key" \
    -out "$CERTS_DIR/server.csr" \
    -subj "/CN=localhost/O=Networking Lab"

# Sign the server cert with our CA
openssl x509 -req \
    -in "$CERTS_DIR/server.csr" \
    -CA "$CERTS_DIR/ca.crt" \
    -CAkey "$CERTS_DIR/ca.key" \
    -CAcreateserial \
    -out "$CERTS_DIR/server.crt" \
    -days 365 \
    -extfile <(printf "subjectAltName=DNS:localhost,IP:127.0.0.1")

echo ""
echo "=== Generating Client Certificate (for mTLS) ==="
# Create client private key and CSR
openssl req -newkey rsa:2048 -nodes \
    -keyout "$CERTS_DIR/client.key" \
    -out "$CERTS_DIR/client.csr" \
    -subj "/CN=lab-client/O=Networking Lab"

# Sign the client cert with our CA
openssl x509 -req \
    -in "$CERTS_DIR/client.csr" \
    -CA "$CERTS_DIR/ca.crt" \
    -CAkey "$CERTS_DIR/ca.key" \
    -CAcreateserial \
    -out "$CERTS_DIR/client.crt" \
    -days 365

# Clean up CSR files (not needed after signing)
rm -f "$CERTS_DIR"/*.csr "$CERTS_DIR"/*.srl

echo ""
echo "=== Done! Certificates created in $CERTS_DIR ==="
echo ""
echo "Files:"
ls -la "$CERTS_DIR"
