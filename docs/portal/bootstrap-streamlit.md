# Bootstrap de adopción (Streamlit)

Esta guía ofrece un onboarding completo para nuevos colaboradores usando Streamlit como experiencia inicial.

## 1. Objetivos
- Configurar el entorno local.
- Ejecutar ingest -> analyze.
- Completar Labs básicos y generar evidencia.

## 2. Preparación
```bash
python cogctl.py init
```

## 3. Ejecutar el onboarding
```bash
streamlit run frontend/onboarding_app.py --server.headless true --server.port 8501
```

Abre: http://localhost:8501

## 4. Configuración recomendada (prod simulado)
```bash
export COGNITIVE_ENV=prod
export COGNITIVE_HASH_SALT=change_me
export COGNITIVE_UI_TOKEN_VIEWER=viewer_token
export COGNITIVE_UI_TOKEN_ANALYST=analyst_token
export COGNITIVE_UI_TOKEN_ADMIN=admin_token
```

## 5. Ejecutar pipeline
```bash
python cogctl.py ingest demo_input.json
python cogctl.py analyze
```

## 6. Evidencia mínima
- `outputs/insights/analysis.json`
- `outputs/audit/analysis.jsonl`
- PR con outputs redacted (solo prod)

## 7. Labs disponibles
- Lab 01: Secure Pipeline Baseline
- Lab 02: GitOps Redacted Sync
- Lab 03: Hardening Runbook

## 8. Good practices
- No sincronizar outputs raw en prod.
- Mantener tokens separados por entorno.
- Adjuntar logs y SBOMs en la evidencia.
