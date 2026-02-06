# GitHub Lab Playbook

Este playbook documenta la “GitHub Lab compartida” que usan Kabehz y L0oky para practicar los cambios de visibilidad como un workshop Learning by Doing. Piensa en cada punto como una receta (“cookbook action”) que pueden ejecutar en pareja durante las videollamadas y registrar en `docs/internal/workshop-notes.md`.

## Acción 1 – Preparar la sesión

1. Abran un issue o project card en el repositorio `kabehz/cognitive-suite` (o un fork propio) que sirva como “ticket de laboratorio”. Anoten:
   - El objetivo del run (`secret`, `internal`, `public`).
   - Fecha y hora de la videollamada.
2. Cada contribuidor clona/forkea el repo, instala dependencias mínimas (`bash`, `git`, `gh`, `python3`) y verifica el script `scripts/workshop-learning-workflow.sh`.
3. Repasen `docs/internal/learning-by-doing-proxmox.md` para asegurar que los despliegues locales están en modo dry-run antes de avanzar.

## Acción 2 – Ejecutar el workflow

1. En la videollamada, uno de los dos controla la terminal y ejecuta:

   ```bash
   bash scripts/workshop-learning-workflow.sh --config scripts/repo-visibility-plan.json
   ```

   - En dry-run no se crean repositorios, sólo se generan los snapshots y los digests.
   - Para avanzar al modo push, añadan `--run` y asegúrense de contar con credenciales válidas para GitHub y Gitea.

2. Mientras la ejecución avanza, el segundo contribuidor:
   - Observa, toma notas cognitivas/emocionales para registrar en `docs/internal/workshop-notes.md`.
   - Revisa la carpeta `outputs/workshop-digests/<timestamp>` para validar los archivos resultantes (digest + respuestas de Open Notebook).
3. Si tienen Open Notebook desplegado, configuren las variables de entorno `OPEN_NOTEBOOK_API_URL`, `OPEN_NOTEBOOK_NOTEBOOK_ID` y (opcional) `OPEN_NOTEBOOK_API_KEY` antes de lanzar el workflow para generar los resúmenes/quizzes automáticos.

## Acción 3 – Retroalimentación y seguimiento

1. Cada contribuidor añade en `docs/internal/workshop-notes.md`:
   - Observaciones cognitivas: qué metáforas ayudaron, qué automatizaciones fueron útiles.
   - Estado emocional: motivación, frustraciones o energía tras el push.
2. Detallen en el issue de laboratorio los cambios de paths/visibilidad que detectaron para que la próxima sesión pueda ajustar el plan JSON.
3. Repare en los quizzes generados por Open Notebook, compártanlos en la llamada y decidan si deben convertirse en microlearning nudges (tarjetas, issues de seguimiento, etc.).

## Acciones futuras (Playbook extendido)

- Automatizar la creación de nuevos tickets desde un template `github-lab-workshop.yml` (puede ser un issue template con checklist).
- Usar GitHub Actions para ejecutar `scripts/workshop-learning-workflow.sh` en modo dry-run tras cada push a la rama del workshop y publicar los logs/digests como artefactos.
- Guardar las respuestas más útiles de Open Notebook en un subdirectorio compartido y usarlas como base para futuros prompts o sesiones de bienestar mental.
- Documentar y aplicar la política Codex→Gitea: cualquier rama `md` generada por el agente debe crear un registro `outputs/workshop-digests/<timestamp>/digest.md` con prompt_hash/response_hash (ver `scripts/workshop-learning-digest.py`), etiquetarse como `ai-generated`, y siempre abrir PR con revisión humana obligatoria antes de mergear.
 
## Sesión “Run Test” compartida

1. Durante la videollamada, ejecuten el workflow completo (`scripts/workshop-learning-workflow.sh --config scripts/repo-visibility-plan.json --run`) apuntando según objetivo a `confidentiality/*` o `ai/*` antes de empujar; habiliten las variables `OPEN_NOTEBOOK_API_URL/NOTEBOOK_ID` para que se generen resúmenes/quizzes en cada digest.
2. El script deja automáticamente `outputs/workshop-digests/<timestamp>/digest.md` y la sección de auditoría con hashes (`prompt_hash`/`response_hash`); enlacen ese artefacto en el issue del GitHub Lab y añadan el bloque del template (`docs/internal/workshop-notes-template.md`) para registrar decisiones cognitivas/emocionales.  
3. Después de cada push, verifiquen que las ramas `confidentiality/*` o `ai/*` se hayan creado correctamente en Gitea, que la PR se describa con el prompt utilizado y que el reviewer confirme la política de no mergear directamente: la evidencia del prompt + hash + revisión humana mantiene la trazabilidad principal.
- Automatizar la creación de nuevos tickets desde un template `github-lab-workshop.yml` (puede ser un issue template con checklist).
- Usar GitHub Actions para ejecutar `scripts/workshop-learning-workflow.sh` en modo dry-run tras cada push a la rama del workshop y publicar los logs/digests como artefactos.
- Guardar las respuestas más útiles de Open Notebook en un subdirectorio compartido y usarlas como base para futuros prompts o sesiones de bienestar mental.
