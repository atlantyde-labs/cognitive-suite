# Command Line Interface (CLI)

For system administrators and technical profiles (ASIR/DevOps), **Atlantyqa
Cognitive Suite** offers a powerful Python-based CLI. This enables automation,
scripting, and enclave management without using the graphical interface.

## Installation

The CLI is available as a Python package and can be installed in any
Linux/Unix-compatible environment within the local enclave:

```bash
pip install atlantyqa-cli
```

## Main commands

### 1. Document ingestion
Send files directly to the semantic processing engine.

```bash
atlantyqa ingest --file report_q1.pdf --title "Quarterly Analysis" --tags legal,risk
```

### 2. Real-time monitoring
View local worker logs directly in the terminal, ideal for infrastructure
debugging.

```bash
atlantyqa logs --follow
```

### 3. Enclave management (Local-first)
Check local model status and cognitive engine resource usage (GPU/RAM).

```bash
atlantyqa status --detailed
```

### 4. GitOps synchronization
Force persistence of results to the local repository and generate the
corresponding Pull Request.

```bash
atlantyqa gitops sync --message "feat: weekly-analysis-sync"
```

## Pipeline integration
The CLI is designed to be used in Bash scripts or local CI/CD pipelines, making
cognitive analysis another part of the IT workflow:

```bash
#!/bin/bash
# Nightly automated analysis script
FILES=$(ls /data/incoming/*.pdf)

for file in $FILES; do
    atlantyqa ingest --file "$file" --silent
done

atlantyqa gitops sync --message "auto: nightly-batch-process"
```

> [!TIP]
> You can list all commands and options by running `atlantyqa --help`.
