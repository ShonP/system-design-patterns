FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      nmap tshark tcpdump curl ca-certificates unzip \
      dnsutils netcat-openbsd whois jq xsltproc \
      iproute2 iptables procps \
      perl libnet-ssleay-perl \
    && rm -rf /var/lib/apt/lists/*

# nikto was removed from Debian in 2019 and is in neither bookworm nor bullseye --
# `apt-get install nikto` fails with "Unable to locate package" and takes the whole
# image build down with it. Install the upstream release instead; it is a Perl script,
# so it is architecture-independent (amd64 and arm64 both work).
ARG NIKTO_VERSION=2.5.0
RUN curl -fsSL -o /tmp/nikto.tar.gz \
      "https://github.com/sullo/nikto/archive/refs/tags/${NIKTO_VERSION}.tar.gz" \
 && mkdir -p /opt/nikto \
 && tar -xzf /tmp/nikto.tar.gz -C /opt/nikto --strip-components=1 \
 && rm -f /tmp/nikto.tar.gz \
 && cp /opt/nikto/program/nikto.conf.default /etc/nikto.conf \
 && printf '#!/bin/sh\nexec perl /opt/nikto/program/nikto.pl -config /etc/nikto.conf "$@"\n' \
      > /usr/local/bin/nikto \
 && chmod +x /usr/local/bin/nikto \
 && nikto -Version

# Nuclei is NOT in Debian's repositories -- `apt-get install nuclei` fails and takes the
# whole image build with it. Install the upstream release binary instead.
ARG NUCLEI_VERSION=3.3.4
RUN arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) na=amd64 ;; \
      arm64) na=arm64 ;; \
      *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/nuclei.zip \
      "https://github.com/projectdiscovery/nuclei/releases/download/v${NUCLEI_VERSION}/nuclei_${NUCLEI_VERSION}_linux_${na}.zip" \
 && unzip -q -o /tmp/nuclei.zip -d /usr/local/bin nuclei \
 && rm -f /tmp/nuclei.zip \
 && chmod +x /usr/local/bin/nuclei \
 && nuclei -version

# nmap-vulners is a third-party NSE script, not part of nmap. It also queries
# vulners.com at scan time, so it needs internet access to be useful. If this layer
# fails (offline build), use nmap's built-in `--script vuln` category instead.
RUN curl -fsSL -o /usr/share/nmap/scripts/vulners.nse \
      https://raw.githubusercontent.com/vulnersCom/nmap-vulners/master/vulners.nse \
 && nmap --script-updatedb \
 || echo "WARNING: nmap-vulners not installed; use --script vuln instead"

WORKDIR /workspace
