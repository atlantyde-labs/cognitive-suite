# Aprender haciendo: GitOps + Streamlit (Adoptantes tempranos)

Esta guia es un recorrido practico para que los adoptantes tempranos ejecuten la suite en local, aprendan el flujo GitOps y validen la UI de Streamlit de forma segura.

## 0. Objetivos
- Ejecutar ingesta -> analisis -> vista en Streamlit.
- Practicar sync GitOps con salidas redactadas.
- Validar logs de auditoria y controles de acceso.

## 1. Prerrequisitos
- Python 3.10+
- Docker (opcional)
- Git

## 2. Ejecucion local (dev)
```bash
python cogctl.py init
python cogctl.py ingest demo_input.json
python cogctl.py analyze
```

Ver resultados:
```bash
python frontend/app.py
```

## 3. UI de Streamlit (local)
```bash
streamlit run frontend/streamlit_app.py --server.headless true --server.port 8501
```
Abrir: http://localhost:8501

## 4. Sync GitOps (dev con datos reales)
Configura el destino del repo:
```bash
export GIT_REPO_URL=git@github.com:example-org/example-repo.git
export GIT_BRANCH=main
export COGNITIVE_ENV=dev
```

Sincroniza (dev permite salidas en bruto):
```bash
bash gitops/sync.sh
```

## 5. Sync GitOps (prod solo salidas redactadas)
```bash
export COGNITIVE_ENV=prod
export GITOPS_DATA_MODE=redacted
export COGNITIVE_HASH_SALT=change_me
```

Ejecuta el analisis con redaccion:
```bash
python pipeline/analyze.py --input outputs/raw --output outputs/insights/analysis.json
```

Sincroniza salidas redactadas:
```bash
bash gitops/sync.sh
```

## 6. Autenticacion en Streamlit (comportamiento prod)
Define tokens:
```bash
export COGNITIVE_UI_TOKEN_VIEWER=viewer_token
export COGNITIVE_UI_TOKEN_ANALYST=analyst_token
export COGNITIVE_UI_TOKEN_ADMIN=admin_token
export COGNITIVE_ENV=prod
```

Inicia la UI:
```bash
streamlit run frontend/streamlit_app.py --server.headless true --server.port 8501
```

## 7. Logs de auditoria (evidencias)
- Log de auditoria de analisis: `outputs/audit/analysis.jsonl`
- Log de acceso UI: `outputs/audit/ui_access.jsonl`

## 8. Tareas de aprendizaje (lista de verificacion)
- [ ] Ejecutar ingesta -> analisis en local
- [ ] Abrir Streamlit y revisar un registro
- [ ] Activar redaccion y confirmar que las salidas se enmascaran
- [ ] Sincronizar salidas redactadas via GitOps
- [ ] Revisar logs de auditoria y registrar evidencia

## 9. Nota de air-gap
- Para builds soberanos, replica dependencias y modelos en offline.
- Deshabilita el egress de red externo en prod.

## Criterios de exito
- Solo salidas redactadas en GitOps prod
- Acceso UI protegido por token
- Logs de auditoria capturados para analisis y acceso
