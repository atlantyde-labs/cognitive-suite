# Talent Detection Challenge (Labs + AI Agents)

This guide defines a structured challenge for early adopters to surface talent signals through Labs, reward systems, and personal AI agents that accompany the user experience.

## Goals
- Detect technical talent using practical Labs.
- Provide a personal AI agent for guidance and feedback.
- Award transparent, auditable rewards based on evidence.
- Maintain privacy, compliance, and sovereign constraints.

## Core concept
- Labs are short, practical missions that mirror real workflows.
- Each Lab produces evidence via GitOps (PRs, logs, artifacts).
- Rewards are granted from evidence, not opinions.
- The personal agent is a companion: coach, reviewer, and safety guard.

## User journey
1) Onboarding
   - Select track (Data, DevSecOps, ML, Product, Frontend, Docs).
   - Create a profile with opt-in consent for scoring.

2) Lab selection
   - Choose a Lab from a difficulty ladder.
   - The agent explains objectives, risks, and reward rules.

3) Execution
   - User completes tasks in a fork or sandbox branch.
   - Agent supports with hints, guardrails, and validation checks.

4) Evidence submission
   - Submit via PR or GitOps sync.
   - CI records evidence: SBOM, SCA, tests, audit logs.

5) Scoring and rewards
   - Automated scoring from evidence logs.
   - Manual review only for edge cases.

6) Growth
   - Next Lab is tailored from observed strengths and gaps.

## Lab structure (template)
- Title:
- Difficulty: L1 / L2 / L3 / L4
- Objective:
- Required outputs:
- Evidence sources:
- Risk and compliance guardrails:
- Reward:

## Example Labs

### Lab 01 - Secure pipeline baseline
- Difficulty: L1
- Objective: run pipeline with redaction and audit logs.
- **Detailed Guide**: [lab-01-deep-dive.md](lab-01-deep-dive.md)
- Required outputs: analysis.json, audit log entries.
- Evidence: `outputs/audit/analysis.jsonl` + GitOps PR.
- Reward: 50 points + badge `secure-runner`.

### Lab 02 - GitOps redacted sync
- Difficulty: L2
- Objective: sync redacted outputs to a remote repo.
- Required outputs: PR with redacted outputs only.
- Evidence: CI logs, gitops/sync.sh evidence.
- Reward: 100 points + badge `gitops-steward`.

### Lab 03 - Hardening runbook
- Difficulty: L3
- Objective: apply container hardening and document risks.
- Required outputs: updated compose and a short risk note.
- Evidence: `docker-compose.prod.yml` diff + review notes.
- Reward: 200 points + badge `runtime-guardian`.

## Rewards system
- Points: 0 to 1000 per Lab depending on difficulty.
- Badges: permanent proof of capability.
- Levels: L1 (Explorer) -> L4 (Expert).
- Bonuses: extra points for clean SCA, tests, and docs.

## Scoring rubric
- Correctness (40%): objectives met and reproducible.
- Security (25%): no policy violations; redaction applied.
- Quality (20%): clean diffs, clear docs, tests.
- Collaboration (15%): PR description, peer feedback.

## AI agent roles
- Onboarding agent: config help, prerequisites, consent.
- Lab coach: hints, time planning, scope management.
- Security guard: flags risky actions (raw data sync, secrets).
- Reviewer: highlights gaps before submission.
- Career agent: suggests next Lab based on score trends.

## Compliance and privacy
- Explicit opt-in for scoring and data retention.
- Only redacted outputs in prod evidence.
- Audit logs for each Lab run.
- Sovereign mode: local-only, no external calls.

## Evidence checklist
- CI logs attached
- SBOM artifacts
- SCA results
- Audit logs
- PR with checklist completed

## Anti-gaming controls
- Randomized checks and hidden tests.
- Rewards require reproducible evidence.
- Manual review for suspicious patterns.

## Next steps
- Publish Labs to a dedicated repo or `labs/` folder.
- Define reward ledger (JSON or simple CSV).
- Assign reviewers for L3 and L4 Labs.
