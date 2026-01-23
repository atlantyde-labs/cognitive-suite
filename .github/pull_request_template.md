## Descripción del cambio

Describe qué se ha cambiado y por qué. Incluye referencia a issues o tareas cuando sea posible.

## Cumplimiento normativo

- [ ] He revisado que no se incluyen datos sensibles o secretos.
- [ ] Este cambio cumple con la CRA y la GDPR según lo documentado.
- [ ] Se adjuntan evidencias de auditoría (logs, informes). Opcional.

## Evidencias de ejecución (demo/lite GHCR)

Rellena si aplica. Usa `python3` para validar JSON y no incluyas tokens en claro.

- Fecha UTC:
- Auth GHCR (si aplica): `docker login ghcr.io` / `sudo docker login ghcr.io`
  - Nota: con `sudo` puede guardar credenciales sin cifrar en `/root/.docker/config.json`.
- Tag usado: `COGNITIVE_IMAGE_TAG=...`
- Comandos ejecutados:
  - `docker compose -f docker-compose.local-demo.yml pull`
  - `docker compose -f docker-compose.local-demo.yml up -d`
  - `docker compose -f docker-compose.local-demo.yml up -d --force-recreate ingestor pipeline`
  - `python3 -m json.tool outputs/insights/analysis.json`
  - `docker compose -f docker-compose.local-demo.yml down`
- Resultado:
  - `outputs/insights/analysis.json` generado: sí/no
  - UI: `http://localhost:8501`
  - Logs/errores relevantes:

## Checklist de PR

- [ ] Se han pasado los tests y linters (CI).
- [ ] He ejecutado el checklist demo/lite (`TESTING_GUIDE.md`) o he justificado si no aplica.
- [ ] La documentación se ha actualizado (README, docs/...).
- [ ] Las revisiones obligatorias se han asignado automáticamente mediante CODEOWNERS.
