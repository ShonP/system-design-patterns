# Networking Essentials

📖 **Source**: [Hello Interview – Networking Essentials for System Design Interviews](https://www.hellointerview.com/learn/system-design/core-concepts/networking-essentials)

## Overview

Networking is the foundation that connects every component in a distributed system. When you design a system with multiple servers, databases, and clients — they all communicate over a network. Understanding how that communication works is essential.

This lab gives you hands-on experience with the key networking concepts that come up in system design interviews: DNS, load balancing, TCP vs UDP, HTTP/2, gRPC, TLS, and mTLS. You'll run real servers, send real traffic, and see the differences for yourself.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | DNS and Load Balancing | DNS resolution, nginx reverse proxy, round-robin / least-conn / IP-hash / weighted algorithms, health checks, L4 vs L7, forward vs reverse proxy |
| 2 | TCP vs UDP Deep Dive | TCP 3-way handshake, reliable delivery, UDP connectionless messaging, performance comparison, connection overhead |
| 3 | HTTP/2 and gRPC | HTTP/1.1 head-of-line blocking, HTTP/2 multiplexing, Protocol Buffers, building a gRPC service, REST vs gRPC, HTTP/3 + QUIC |
| 4 | TLS and mTLS | TLS handshake, certificates, certificate chains, HTTPS connections, mutual TLS for microservices, TLS termination, performance impact |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of HTTP requests

## Quick Start

```bash
# Navigate to the lab directory
cd core-concepts/networking-essentials

# Generate TLS certificates (needed for notebooks 3 and 4)
bash nginx/generate_certs.sh

# Start nginx + 3 Flask backends
docker-compose up -d --build

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=networking --display-name="Networking (Python)"

# Open the first notebook and start learning!
```

## Architecture

```
┌─────────────┐     ┌─────────────────────────────────────────────┐
│             │     │  Docker Network                             │
│  Notebooks  │────→│                                             │
│  (your code)│     │  ┌───────────┐    ┌──────────┐             │
│             │     │  │   Nginx   │───→│ backend1 │ (Flask:5000)│
└─────────────┘     │  │  (LB/TLS) │───→│ backend2 │ (Flask:5000)│
                    │  │  :80/:443 │───→│ backend3 │ (Flask:5000)│
   Ports:           │  │  /:8443   │    └──────────┘             │
   8080 → HTTP      │  └───────────┘                             │
   8443 → HTTPS     └─────────────────────────────────────────────┘
   9443 → mTLS
   5001-5003 → backends directly
```

- **Nginx**: Layer 7 load balancer with 4 algorithms (round-robin, least-conn, IP-hash, weighted). Also serves HTTPS (TLS) and mTLS.
- **Flask Backends (×3)**: Identical servers that identify themselves by name, so you can see which one handled your request.

## Key Concepts Covered

### Transport Layer
- **TCP**: Reliable, ordered delivery — the default for almost everything
- **UDP**: Fast, connectionless — for real-time media and gaming

### Application Layer Protocols
- **HTTP/1.1**: Request-response, one request per connection
- **HTTP/2**: Multiplexing, header compression, binary framing
- **gRPC**: High-performance RPC using Protocol Buffers over HTTP/2
- **REST**: Simple, flexible APIs using JSON over HTTP

### Load Balancing
- **DNS Round-Robin**: Simplest form — multiple IPs for one domain
- **L7 Load Balancer**: Content-aware routing (URLs, headers, cookies)
- **L4 Load Balancer**: Fast TCP/UDP forwarding (no content inspection)
- **Algorithms**: Round-robin, least-connections, IP-hash, weighted

### Security
- **TLS**: Encrypts traffic, proves server identity
- **mTLS**: Both sides prove identity — for zero-trust microservices
- **Certificate Chains**: Root CA → Intermediate CA → Server cert

### Failure Handling
- **Health checks**: Automatically route around dead servers
- **Retries with backoff**: Handle transient failures gracefully
- **Circuit breakers**: Prevent cascading failures

## Real-World Examples

| System | Networking Concept |
|--------|--------------------|
| CDNs (Cloudflare) | DNS-based load balancing, TLS termination |
| Kubernetes | mTLS between pods (Istio/Linkerd service mesh) |
| Google microservices | gRPC for internal service-to-service calls |
| AWS ALB/NLB | L7 (ALB) vs L4 (NLB) load balancers |
| Video streaming | UDP for media, TCP for control/signaling |

## License

Educational content — feel free to use and modify for learning purposes.
