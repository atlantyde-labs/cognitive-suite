# Local User View (UI) – Cognitive Suite

This section documents the **user view** of the Cognitive Suite when it is
**installed locally** (Docker or Kubernetes). The goal is that a third party
(public sector, banking, partner, QA) can understand:

- What the user sees when opening the suite
- How to start the local console
- Where outputs are located
- Minimal functional flow (MVP)

---

## 1. Quick access

### Option A: Local UI with Docker (recommended)

From the **repo root**:

```bash
make ui-build
make ui-up
```

Open: `http://localhost:8501`

The UI reads outputs by default from a mounted volume:

- Host: `./outputs`
- Container: `/data/outputs`

### Option B: Local UI without Docker

```bash
pip install -r requirements.txt
make ui-local
```

---

## 2. Expected outputs structure

The UI consumes:

- `outputs/insights/analysis.json`

You can change the outputs root with:

- `COGNITIVE_OUTPUTS=/path/to/outputs`

---

## 3. Screens and flow

### 3.1 Dashboard / Results explorer

- Table of analyzed documents
- Filter by cognitive tags
- UUID selection

### 3.2 Record details

- Metadata (file, type, tags)
- Summary
- Sentiment
- Extracted entities

---

## 4. Troubleshooting

### No results appear

1) Verify the file exists:

```bash
make ui-doctor
```

2) If running in Docker, ensure `./outputs` is mounted.

### UI does not load

- Confirm port `8501` is free
- Run `make ui-build` again

---

## 5. UX roadmap (next level)

- Export to Markdown/PDF from the UI
- GitOps panel (create issue/PR from insights)
- Local authentication (optional SSO/LDAP)
- Institutional screenshots and demo script
