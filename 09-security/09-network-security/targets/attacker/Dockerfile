FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      nmap nuclei tshark tcpdump curl ca-certificates \
      dnsutils netcat-openbsd nikto whois jq xsltproc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
