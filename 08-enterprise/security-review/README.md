# Security Review — Enterprise Pattern Lab

📖 **Inspired by**: [Microsoft Security Development Lifecycle (SDL)](https://www.microsoft.com/en-us/securityengineering/sdl) and [OWASP Top 10](https://owasp.org/www-project-top-ten/)

## Overview

Every large tech company — Microsoft, Google, Amazon, Netflix — runs a formal **security review process** before shipping code. This isn't optional. At Microsoft, it's called the **Security Development Lifecycle (SDL)**, a mandatory set of practices that every product team must follow.

This lab teaches you how enterprise security review works in practice. You'll learn to **think like an attacker** (threat modeling), **find vulnerabilities** (OWASP Top 10), **protect secrets** (vault, env vars, managed identities), and **automate security checks** (SAST/DAST in CI/CD).

We've built an **intentionally vulnerable Flask web app** that you'll attack and then fix across the notebooks.

> ⚠️ **WARNING**: The Flask app in this lab contains **deliberate security vulnerabilities** for educational purposes. Never deploy it to a real environment.

## Notebooks in This Series

| # | Notebook | What You'll Learn |
|---|----------|-------------------|
| 1 | Threat Modeling (STRIDE) | How to systematically identify threats before writing code |
| 2 | Common Vulnerabilities | SQL injection, XSS, CSRF, SSRF, missing security headers — attack and fix each one |
| 3 | Secrets Management | Why hardcoded secrets are dangerous and how to fix it |
| 4 | Security Gates in CI/CD | Automated SAST/DAST scanning, dependency checks, sign-off |

## What is Microsoft SDL?

The **Security Development Lifecycle** is a set of security practices that Microsoft requires for every product. It was introduced in 2004 after major security incidents and has since been adopted (in various forms) across the industry.

### SDL Phases

```
┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│   Training   │──▶│ Requirements │──▶│    Design    │──▶│Implementation│──▶│ Verification │
│              │   │              │   │              │   │              │   │              │
│ Security     │   │ Security     │   │ Threat       │   │ Secure       │   │ SAST / DAST  │
│ awareness    │   │ requirements │   │ modeling     │   │ coding       │   │ Pen testing  │
│ for all devs │   │ Privacy reqs │   │ Attack       │   │ Banned APIs  │   │ Fuzz testing │
└──────────────┘   └──────────────┘   │ surface      │   │ Static       │   └──────────────┘
                                      │ reduction    │   │ analysis     │          │
                                      └──────────────┘   └──────────────┘          ▼
                                                                           ┌──────────────┐
                                                                           │   Release    │──▶ Response
                                                                           │              │    Plan
                                                                           │ Final        │
                                                                           │ security     │
                                                                           │ review       │
                                                                           │ Sign-off     │
                                                                           └──────────────┘
```

### Key Concepts

| Concept | What It Means | Why It Matters |
|---------|---------------|----------------|
| **Threat Modeling** | Structured way to find what can go wrong | Finds design-level bugs before code is written |
| **STRIDE** | Spoofing, Tampering, Repudiation, Info Disclosure, DoS, Elevation of Privilege | Framework for categorizing threats |
| **OWASP Top 10** | Most critical web application security risks | Industry standard vulnerability checklist |
| **SAST** | Static Application Security Testing — scans source code | Finds bugs without running the app |
| **DAST** | Dynamic Application Security Testing — scans running app | Finds bugs that only appear at runtime |
| **Penetration Testing** | Simulated attacks by security experts | Validates that defenses actually work |
| **Secrets Management** | Secure storage of passwords, keys, tokens | Prevents credential leaks |
| **Security Gates** | Automated checks that block insecure releases | Ensures every deployment meets security bar |

## OWASP Top 10 (2021)

The [OWASP Top 10](https://owasp.org/www-project-top-ten/) lists the most critical web application security risks:

| # | Risk | What It Means |
|---|------|---------------|
| A01 | Broken Access Control | Users can act outside their permissions |
| A02 | Cryptographic Failures | Weak encryption, exposed sensitive data |
| A03 | Injection | SQL injection, command injection, XSS |
| A04 | Insecure Design | Missing security controls in architecture |
| A05 | Security Misconfiguration | Default passwords, unnecessary features on |
| A06 | Vulnerable Components | Using libraries with known vulnerabilities |
| A07 | Authentication Failures | Weak passwords, missing MFA, session issues |
| A08 | Software & Data Integrity | Untrusted updates, insecure CI/CD pipelines |
| A09 | Logging & Monitoring Failures | Breaches go undetected |
| A10 | SSRF | Server-side request forgery to internal systems |

## Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Basic understanding of HTTP and web applications

## Quick Start

```bash
# Navigate to the lab directory
cd enterprise-patterns/security-review

# Start PostgreSQL + Redis + Flask App + Visualization Tools
docker-compose up -d

# Install dependencies
uv sync

# Register Jupyter kernel
uv run python -m ipykernel install --user --name=security-review --display-name="Security Review (Python)"

# Open the first notebook and start learning!
```

## 🔍 Visualization Tools (Included in Docker)

### Adminer (PostgreSQL GUI)
- **URL**: http://localhost:8080
- **Login**: System `PostgreSQL`, Server `postgres`, Username `demo`, Password `demo`, Database `security_demo`
- **Use for**: Inspect user tables, audit logs, see SQL injection effects

### RedisInsight (Redis GUI)
- **URL**: http://localhost:5540
- **First time setup**: Click "Add Redis Database" → Host `redis`, Port `6379`
- **Use for**: Monitor rate-limiting keys, session tokens, CSRF tokens

### Vulnerable Flask App
- **URL**: http://localhost:5001
- **Health check**: http://localhost:5001/health
- **Use for**: The notebooks interact with this app to demonstrate attacks and fixes

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Docker Compose                      │
│                                                      │
│  ┌──────────┐   ┌──────────┐   ┌──────────────────┐ │
│  │ Postgres │   │  Redis   │   │  Flask App       │ │
│  │ :5432    │   │  :6379   │   │  :5001           │ │
│  │          │   │          │   │                  │ │
│  │ Users    │   │ Sessions │   │ /api/products/*  │ │
│  │ Products │   │ Rate     │   │ /api/login       │ │
│  │ Comments │   │ Limits   │   │ /api/transfer    │ │
│  │ Audit    │   │ CSRF     │   │ /api/fetch-url   │ │
│  │ Log      │   │ Tokens   │   │ /comments/*      │ │
│  └──────────┘   └──────────┘   └──────────────────┘ │
│                                                      │
│  ┌──────────┐   ┌──────────────────┐                 │
│  │ Adminer  │   │  RedisInsight    │                 │
│  │ :8080    │   │  :5540           │                 │
│  └──────────┘   └──────────────────┘                 │
└─────────────────────────────────────────────────────┘
        ▲
        │ HTTP requests from Jupyter notebooks
        │
┌───────────────────────────┐
│   Jupyter Notebooks       │
│   (your local machine)    │
│                           │
│   01_threat_modeling      │
│   02_common_vulns         │
│   03_secrets_mgmt         │
│   04_security_gates_cicd  │
└───────────────────────────┘
```

## Real-World Examples

| Company | Security Practice | What They Do |
|---------|-------------------|-------------|
| Microsoft | SDL (Security Development Lifecycle) | Mandatory threat modeling, security gates before every release |
| Google | Project Zero | Dedicated team finding zero-day vulnerabilities |
| Netflix | Security Monkey / Repokid | Automated cloud security monitoring, least-privilege enforcement |
| Amazon | AWS Well-Architected Security Pillar | Security review framework for all cloud architectures |
| Meta | Zoncolan | Static analysis tool scanning millions of lines of code |

## Further Reading

- [Microsoft SDL Practices](https://www.microsoft.com/en-us/securityengineering/sdl/practices)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [STRIDE Threat Model](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CWE/SANS Top 25 Most Dangerous Software Weaknesses](https://cwe.mitre.org/top25/)

## License

Educational content — feel free to use and modify for learning purposes.
