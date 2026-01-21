# 📊 Metrics (Learning + Delivery + Ecosystem)

> **Goal:** measure real learning, operational reliability, and ecosystem growth
> without falling into vanity metrics.
> These metrics are designed for **GitHub.com** (Issues + Projects v2 + Actions).

---

## 1) Learning Metrics (Learning by Doing)

### ✅ TTFP — Time To First PR (early adopter king metric)
- **Definition:** time from first issue / first interaction to first acceptable PR.
- **Why it matters:** if it goes down, onboarding works.

**How to measure in GitHub**
- Project v2: filter cohorts (labels `good first issue` + `learning-task`)
- Compare `created_at` of the initial issue vs `merged_at` of the first PR.

---

### ✅ Learning Velocity
- **Definition:** number of `learning-task` items completed per week/month.
- **Instrumentation:** Project v2 + field `Status=Done` + label `learning-task`.

---

### ✅ XP Earned (measurable gamification)
- **Definition:** sum of XP delivered per contributor per month.
- **Instrumentation:** Project v2 field `XP` (Number).
- **Suggested base rule:**
  - Level 1 → 10 XP
  - Level 2 → 25 XP
  - Level 3 → 50 XP
  - Level 4 → 100 XP

---

## 2) Flow Metrics (Delivery / Operations)

### ✅ Cycle Time (Issue → Done)
- **Definition:** total time from when an issue enters `In Progress` to `Done`.
- **Objective:** reduce blockers and increase flow.

### ✅ Flow Efficiency
- **Definition:** time in “active” status / total cycle time.
- **Instrumentation:** status timestamps (manual or automated).

---

## 3) Reliability Metrics (GitOps / CI)

### ✅ CI Reliability
- **Definition:** % of green runs per week + trend.
- **Source:** GitHub Actions.

### ✅ MTTR — Mean Time To Recovery (mean time to green)
- **Definition:** average time to recover a failed pipeline to green.
- **Source:** Actions run history.

### ✅ Build Cost Guardrails (resources / sustainability)
- **Definition:** average docker image size and build time.
- **Objective:** avoid dependency bloat (especially ML).

---

## 4) Ecosystem Metrics (ATLANTYDE / ATLANTYQA)

These metrics connect the repository with the **Identity and ecosystem summary**:
mission, sovereign infrastructure, territorial expansion, and founding community.

### ✅ Sovereign Stack Adoption
- **Definition:** % of contributions that preserve the *local-first* principle.
- **Signal:** PRs that:
  - do not depend on proprietary SaaS to function
  - document offline/hybrid mode
  - keep MicroK8s / k3s compatibility

**Instrumentation**
- Label `local-first`
- Checklist in PR template (optional)

---

### ✅ GitOps Coverage
- **Definition:** percentage of components that have:
  - manifests/helm/kustomize
  - policies (OPA) or security checks
  - reproducible pipelines

**Instrumentation**
- Project v2 field `Area=CI/GitOps`
- checklist per component

---

### ✅ Community Growth (collective health)
- **Definition:** active contributors/month and ratio of returning contributors.
- **Why it matters:** the cooperative lives on continuity, not spikes.

---

### ✅ Territorial Impact (ITI / Andalusia → EU)
- **Definition:** # events/bootcamps/labs executed + # active students.
- **Recommended instrumentation**
- “Ops Issues” per event (label `community-event`)
- Project v2 “Roadmap” view per quarter:
  - 2025–26 Andalusia (ITI)
  - 2026–27 Portugal/France/Germany
  - 2028+ LATAM/USA

---

## 5) Metrics map → GitHub Projects v2 (recommended fields)

**Fields**
- `Status` (Backlog/In Progress/In Review/Done/Blocked)
- `Area` (Learning, CI/GitOps, Docs, Backend, Frontend, LegalTech, Community)
- `Level` (1–4)
- `XP` (Number)
- `KPI` (Text) → “TTFP”, “CI Reliability”, etc.

**Views**
- Kanban by Status
- Table by Level/XP
- Charts by Area and Status
- Roadmap by quarter (if you use milestones)

---

## 6) Quick implementation checklist (15 min)

- [ ] Create a Project v2 in org `atlantyde-labs`
- [ ] Add fields `Status/Area/Level/XP/KPI`
- [ ] Add secrets `PROJECT_URL` and `PROJECT_TOKEN`
- [ ] Enable workflow `add_to_project.yml`
- [ ] Enable workflow `labels.yml`
- [ ] Define XP per label/level in your operations

---

> If you cannot measure it, you cannot improve it.
> And if you measure it poorly, you destroy culture.
> **We measure to learn and cooperate**, not to pressure.
