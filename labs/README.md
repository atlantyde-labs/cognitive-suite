# Labs (Talent Challenge)

This folder contains the practical Labs used to detect technical talent through real work. Each Lab is a short mission with clear outputs, evidence, and rewards.

## Structure
- `lab-XX-*.md`: individual Lab definitions
- `agents.md`: AI agent roles and guardrails
- `rewards.md`: reward model and scoring rules
- `ledger.json`: reward ledger (JSON)

## Lab format (summary)
- Title
- Difficulty (L1-L4)
- Objective
- Tasks
- Required outputs
- Evidence
- Guardrails (security/compliance)
- Rewards

## How to run
- Use the Streamlit onboarding app: `streamlit run frontend/onboarding_app.py`
- Or read the Lab files directly and submit via PR.

## Evidence rules
- Evidence must be reproducible.
- No raw data in prod evidence.
- Include audit logs and CI logs.

## Ledger usage
Append a reward entry:
```bash
python scripts/labs-ledger-add.py --user alice --lab lab-01-secure-pipeline --points 50 --badge secure-runner --evidence PR#123
```

Export ledger to CSV:
```bash
python scripts/labs-ledger-export.py --ledger labs/ledger.json --output labs/ledger.csv
```
