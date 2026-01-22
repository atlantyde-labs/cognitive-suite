# GitOps Integration

The **GitOps Panel** is the bridge between cognitive analysis and institutional
persistence. It ensures each insight becomes a versioned and auditable digital
asset.

## 🔁 Sync panel

The panel offers full visibility into the knowledge infrastructure state:

### Connected repositories
* **Repository list**: Links to config and documentation repos.
* **Sync status**: Visual indicators of success/failure in the last sync.
* **Last commit**: Signature of the last change applied to the enclave.

### Insight lifecycle
The suite automates persistence following the standard development flow:
1. **Branching**: Create an ephemeral branch for the new analysis.
2. **Committing**: Save results as a structured file (Markdown/JSON).
3. **Pull Request**: Automatically generate a PR in the original repo for human review.

## 🛡️ Control policies (OPA / Conftest)
Before a change is persisted, the system validates:
* **Security**: Sensitive data exclusion rules.
* **Compliance**: Formal and structural validation.
* **Approval**: Integration checks status.

## 🛠️ Management actions
* **Force sync**: Retry the upstream connection.
* **Resolve conflicts**: Guided interface to resolve differences between local
  analysis and the remote repository.
* **PR audit**: List of open Pull Requests classified by cognitive origin.
