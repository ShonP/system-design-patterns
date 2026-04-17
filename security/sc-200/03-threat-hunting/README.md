# Lab 3: Threat Hunting

📖 **Exam domain**: Perform threat hunting (20–25%)

## What you'll practice

- Writing hunting queries against the mini-SIEM
- KQL patterns for common threat scenarios
- Entity analysis and relationship mapping
- Advanced hunting query patterns
- Interpreting MITRE ATT&CK coverage

## Notebooks

| # | Notebook | Topics |
|---|----------|--------|
| 1 | [KQL hunting patterns](notebooks/01_kql_hunting_patterns.ipynb) | Core query patterns, aggregation, time analysis, entity extraction |
| 2 | [Advanced threat hunting](notebooks/02_advanced_hunting.ipynb) | Multi-table correlation, anomaly detection, hunt hypotheses |

## Quick start

```bash
cd security/sc-200/03-threat-hunting
# Uses the same SIEM from Lab 1
uv sync
uv run python -m ipykernel install --user --name=sc-200 --display-name="SC-200 (Python)"
```
