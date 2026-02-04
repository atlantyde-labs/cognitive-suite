# Arquitectura cognitiva legal para análisis profundo

## 1. Capas filosóficas

1. **Epistemología**: definimos qué constituye conocimiento legal (reglas escritas, precedentes, evidencia). Cada artefacto JSONL incluye la fuente, el nivel de autoridad y su confianza.
2. **Hermenéutica**: los textos se interpretan en contexto; el wizard contrasta preguntas y respuestas con dominios legales para detectar ambigüedad.
3. **Ontología**: se mantienen grafos conceptuales de entidades (`contrato`, `persona`, `obligación`) en `contributors-tags.jsonl` y en los metadatos del onboarding.
4. **Ética/IA responsable**: registro de decisiones (JSONL) con trazabilidad (timestamps, run IDs, DRY_RUN). El `gh-pr-checklist` recolecta evidencia del flujo de aprobación.
5. **Contextualismo**: los pipelines (ingesta → contexto → dominio → modelo → interpretación → juicio) se parametrizan por dominio (`legal`, `compliance`).

## 2. Pipeline cognitivo

```
Ingesta (textos, CSV, PDFs) → Contexto (dominial/tagging) → Modelo (NLP + ontologías) → Interpretación (razonamiento simbólico, heurísticas) → Juicio (explicación, confianza, control)
```

- **Ingesta** se captura con los wizards y scripts (`contributors.csv`, JSONL de evidencias, `bot-evidence`).
- **Contexto** queda en `contributors-tags.jsonl` y `proxmox-local-secrets-wizard.jsonl` (roles, dominios, riesgos).
- **Modelo** se ejemplifica en `ops/cognitive_report.py`, que combina reglas heurísticas con embeddings sencillos.
- **Interpretación** es el `interpretation` y `judgment` del JSON emitido por el script, enlazado a los checklists de PR.
- **Juicio** es la salida final (dominio, confianza, explicación, acciones recomendadas) que alimenta la observabilidad en Gitea/Proxmox.

## 3. Registro de evidencias

| Archivo | Qué describe |
| --- | --- |
| `/opt/cognitive-suite/secrets/proxmox-local-secrets-wizard.jsonl` | Valores finales del wizard, DRY_RUN, prompts completados.
| `outputs/secrets/contributors-tags.jsonl` | Roles, dominios, riesgos, controles (MFA/SSO/HITL) por colaborador.
| `outputs/ci-evidence/pr-checklist/summary.jsonl` | Checklist de PR + estado de milestones.
| `outputs/ci-evidence/bot-evidence/...` | Evidencias que el bot sube a Gitea.

## 4. Operación GitOps en Proxmox

1. Corremos `proxmox-local-secrets-wizard.sh` para generar envs de Proxmox/Gitea/bots y el CSV de onboarding.
2. Ejecutamos `gitea-onboard-contributors.sh` con el CSV para crear colaboradores, forzando MFA/SSO y registrando la salida en JSON.
3. Desplegamos LXC y runners desde los scripts (deploy, runner install) y habilitamos reboot guard.
4. Validamos en GitHub con `gh-pr-checklist.sh` y `gh-pr-errors.sh` que las aprobaciones y milestones están completadas, y guardamos sus JSONs.
5. Creamos el reporte cognitivo con `ops/cognitive_report.py` para cada texto, anotando dominio/confianza/interpretación.

## 5. Observabilidad y GUI

- El wizard muestra *tips* (`?` = ayuda, `skip` = omitir) y describe cada prompt.
- La salida JSON se puede exponer en dashboards internos (Grafana/Loki) para compliance.
- En Gitea y Proxmox, revisa los registros `/opt/cognitive-suite/secrets` y los servicios systemd (`reboot-guard`, `gitea-runner`).

## 6. Cómo usar el `cognitive_report.py`

```bash
python ops/cognitive_report.py \
  --text "La cláusula XYZ..." \
  --domain "legal" \
  --context "contrato mercantil"
```

La salida es un JSON con `domain`, `confidence`, `interpretation`, `judgment`, `knowledge_trace`, `recommendation`.

## 7. Validación Continua

* Ejecute `mock-e2e.sh` para dry-run completo con wizards + onboarding + evidence.
* Revise los JSONL generados con `jq` contra los esquemas (`schemas/*`).
* Documente cualquier desviación en `outputs/ci-evidence/dry-run-report.json`.
