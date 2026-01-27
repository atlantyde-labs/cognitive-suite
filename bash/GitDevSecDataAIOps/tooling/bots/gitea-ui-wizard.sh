#!/usr/bin/env bash
set -euo pipefail
umask 077

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CS_ROOT="${SCRIPT_DIR}"
while [[ ! -f "${CS_ROOT}/lib/cs-common.sh" ]]; do
  if [[ "${CS_ROOT}" == "/" ]]; then
    echo "cs-common.sh not found" >&2
    exit 1
  fi
  CS_ROOT=$(dirname "${CS_ROOT}")
done
# shellcheck disable=SC1090,SC1091
source "${CS_ROOT}/lib/cs-common.sh"

# shellcheck disable=SC2034
CS_LOG_PREFIX="gitea-ui-wizard"

if [[ ! -t 0 ]]; then
  cs_die "Interactive wizard requires a TTY"
fi

cs_ui_header "Gitea UI Wizard (On-Prem Bot Setup)"
cs_ui_note "Este wizard crea un checklist ClickOps y genera un .md con pasos."

GITEA_URL=$(cs_ui_prompt "Gitea URL" "https://gitea.example.local")
ORG_NAME=$(cs_ui_prompt "Organizacion/Owner" "founders")
TARGET_REPO=$(cs_ui_prompt "Repo objetivo (nombre)" "repo")
EVIDENCE_REPO=$(cs_ui_prompt "Repo de evidencias (owner/repo)" "founders/evidence")
BOT_USER=$(cs_ui_prompt "Usuario bot (machine user)" "ops-bot")
BOT_EMAIL=$(cs_ui_prompt "Email bot" "ops-bot@example.local")
BRANCH_NAME=$(cs_ui_prompt "Rama protegida" "main")
REQUIRED_APPROVALS=$(cs_ui_prompt "Aprobaciones requeridas" "2")
OUTPUT_PATH=$(cs_ui_prompt "Ruta del checklist .md" "${SCRIPT_DIR}/gitea-bot-clickops.md")

cs_ui_step "Generando checklist en ${OUTPUT_PATH}"

cat <<EOF > "${OUTPUT_PATH}"
# Gitea UI ClickOps - Bot Setup (On-Prem)

> URL: ${GITEA_URL}
> Owner: ${ORG_NAME}
> Repo objetivo: ${TARGET_REPO}
> Evidence repo: ${EVIDENCE_REPO}

## 1) Crear Machine User (Bot)
- UI: **Admin Panel** → **Users** → **Create User**
- Username: \`${BOT_USER}\`
- Email: \`${BOT_EMAIL}\`
- Role: **User** (no admin)
- Password: generar seguro
- Require password change: desactivado (solo si es bot)

## 2) Crear Token del Bot
- UI: **User Settings** → **Applications** → **Generate Token**
- Guardar token de forma segura (no en git)
- Scope mínimo: repo (write), pull requests

## 3) Añadir Bot a la Organización
- UI: **Organization** → **Teams** → crear team \`bots\`
- Permisos del team: **write** (o lo mínimo necesario)
- Añadir \`${BOT_USER}\` al team

## 4) Repo de evidencias (privado)
- UI: crear \`${EVIDENCE_REPO}\` en privado
- Añadir bot como **write**
- Activar **branch protection** para \`${BRANCH_NAME}\`

## 5) Reglas de aprobación (repo objetivo)
- UI: **Repo Settings** → **Branch Protection**
- Rama: \`${BRANCH_NAME}\`
- Require approvals: **${REQUIRED_APPROVALS}**
- Solo usuarios con write/admin cuentan

## 6) Etiquetas operativas (para bots)
- \`ops/bot-approve\`
- \`ops/hitl-approve\`

## 7) Variables y Secrets (en tu entorno de despliegue)
Configurar en tu runner/self-hosted:
- \`GITEA_URL=${GITEA_URL}\`
- \`GITEA_TOKEN=<bot-token>\`
- \`GITEA_EVIDENCE_REPO=${EVIDENCE_REPO}\`
- \`GITEA_EVIDENCE_USER=${BOT_USER}\`
- \`GITEA_REPO_OWNER=${ORG_NAME}\`
- \`GITEA_REPO_NAME=${TARGET_REPO}\`

## 8) Verificacion rapida
- Ejecutar \`bot-review.sh\` en modo dry-run
- Ejecutar \`bot-evidence-publish.sh\` en modo dry-run

## 9) Checklist de cumplimiento (humano + bot)
- 1 approval humano real
- 1 approval bot (solo si \`ALLOW_BOT_APPROVE=YES\` + \`HITL_APPROVE=YES\`)

---
Generado por wizard: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

chmod 600 "${OUTPUT_PATH}"
cs_ui_ok "Checklist creado: ${OUTPUT_PATH}"
cs_ui_note "No incluye tokens reales. Rellena en el sistema productivo."
