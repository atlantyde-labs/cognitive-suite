# Phase Merge Plan (cognitive-suite.zip + optimized bundle)

This plan splits the merge into phase commits and phase PRs, aligned with the
SCA and DevSecOps integration summary.

Prereqs
- Create a working branch for the merge.
- Apply the zip overlay in a non-destructive way (rsync or
  `./upgrade_rollback.sh upgrade <bundle.zip>`).
- Keep the git index clean before each phase commit.

Phases
1) Foundation and governance
   - Files: `README.md`, `LICENSE`, `SECURITY.md`, `CONTRIBUTING.md`,
     `CODE_OF_CONDUCT.md`, `.gitignore`, `.dockerignore`, `.gitattributes`,
     `.github/pull_request_template.md`, `.github/CODEOWNERS`,
     `PR_DESCRIPTION.md`
   - Commit: `phase(1): governance and onboarding`
   - PR: "Phase 1 - Governance and onboarding"

2) Docs and mkdocs site
   - Files: `mkdocs.yml`, `docs/`, `knowledge/`, `requirements-docs.txt`,
     `PATCH_MKDOCS_NAV_APPEND.md`
   - Commit: `phase(2): docs and mkdocs site`
   - PR: "Phase 2 - Documentation site"

3) CI/CD and security automation
   - Files: `.github/workflows/`, `.github/ISSUE_TEMPLATE/`,
     `.github/labels.yml`, `.github/project_v2/`, `.gitleaks.toml`,
     `requirements-ci.txt`, `scripts/validate-knowledge.py`
   - Commit: `phase(3): ci/cd workflows and security automation`
   - PR: "Phase 3 - CI/CD and security"

4) Tooling and ops
   - Files: `Makefile`, `dev/`, `ops/`, `scripts/`, `gitops/`,
     `test-bootstrap.sh`, `upgrade_rollback.sh`, `commit_from_bundles.sh`
   - Commit: `phase(4): tooling and ops automation`
   - PR: "Phase 4 - Tooling and ops"

5) Core app, schemas, datasets, compose, deps
   - Files: `ingestor/`, `pipeline/`, `frontend/`, `vectorstore/`,
     `wrappers/`, `cogctl.py`, `schemas/`, `datasets/`, `requirements.txt`,
     `docker-compose.yml`, `docker-compose.prod.yml`
   - Commit: `phase(5): core app and insight schema output`
   - PR: "Phase 5 - Core app and insight schema"

Notes
- If you want to version a sample insight output, commit it explicitly and
  ensure it contains no real data.

Helper
Use the helper script to stage and commit by phase:

```bash
bash scripts/phase-commit.sh --list
bash scripts/phase-commit.sh --phase 1
bash scripts/phase-commit.sh --all
```
