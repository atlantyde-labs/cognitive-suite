# Local User Interface

The user vision of the **Atlantyqa Cognitive Suite** focuses on a local-first,
secure experience oriented to operational efficiency through GitOps.

## 👥 System roles

| Role | Description | Key capabilities |
| :--- | :--- | :--- |
| **Local Administrator** | Infrastructure and policy manager. | Configuration, user management, data auditing. |
| **Knowledge Analyst** | Primary semantic analysis user. | Data ingestion, analysis execution, cognitive tagging. |
| **GitOps Operator** | Responsible for persistence and deployment. | Repository control, Pull Request management, policy validation. |
| **Executive Viewer** | Query and reporting user. | Access to critical dashboards and report export. |

## 🧭 General usage flow

Any interaction with the suite deployed in local environments (K8s / Docker)
follows this optimized flow:

1. **Authentication**: Secure access via local LDAP or corporate SSO.
2. **Dashboard**: Global view of enclave status and analysis KPIs.
3. **Ingestion**: Multimodal document upload (PDF, JSON, YAML, etc.).
4. **Analysis**: Semantic processing with automatic insight generation.
5. **GitOps**: Automatic persistence of results in Git repositories via
   branches and PRs.

## 🔐 Non-negotiable UX requirements

* **Offline mode**: All processing happens inside your infrastructure. "Your
  data never leaves your enclave."
* **GitOps feedback**: Sync status always visible for critical actions.
* **Version control**: Each analysis and report has full traceability in Git.
