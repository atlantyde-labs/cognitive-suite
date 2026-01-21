# 🧠 User Vision: Local Suite (Cognitive Suite)

This document describes the user experience (UX) and workflows when the
*Atlantyqa Cognitive Suite* is deployed locally. Unlike institutional public
documentation, this guide focuses on real interaction with the product.

## 🧭 General Usage Flow (UI)

### 1. 🟢 Login / Authentication
The main entry point ensures only authorized users access the local enclave.
* **Capability**: Integration with local LDAP or corporate SSO.
* **Read-only mode**: Available for the *Executive Viewer* profile.

### 2. 📊 Main Dashboard
A consolidated view of system health and generated value.
* **KPIs**: Processed documents, GitOps success rates, detected semantic
  categories.
* **Events**: Timeline of latest commits, sync failures, and security alerts.

### 3. 📁 Multimodal Ingestion (New Analysis)
Interface to feed the system with heterogeneous data.
* **Formats**: PDF, DOCX, TXT, JSON, YAML.
* **Metadata**: Optional manual tagging and pre-classification.

### 4. 🧠 Semantic Analysis Results
The suite's "brain" visualized.
* **Entities**: Mapping of people, organizations, and dates.
* **Risk classification**: Automatic identification of critical points.
* **Decision timeline**: Trace of how document paragraphs were categorized.

### 5. 🔁 GitOps Integration
Control panel for persistence and traceability.
* **Sync Status**: Real-time state of the linked Git repository.
* **Automation**: Automatic Pull Requests (PRs) based on analysis findings.

---

## 🔐 Non-negotiable design requirements

1. **Local-first / Offline**: The design must inspire trust. "Your data never
   leaves your infrastructure." No external API calls by default.
2. **GitOps feedback**: Every action must have a clear sync trail.
3. **Aesthetic high-end**: The interface must be clean, modern, and functional
   ("Enterprise/Military Grade" aesthetic).

---

## 📐 Screen map (Mockups)

* `Dashboard`: command center.
* `Ingest`: dynamic upload form.
* `Results`: enriched reading panel.
* `GitOps`: sync monitor.
