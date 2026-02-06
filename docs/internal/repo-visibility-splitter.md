# Repo Visibility Splitter

Este script ayuda a segmentar el trabajo del repositorio actual en tres clasificaciones (secret, internal y public) y empujarlas hacia instancias de GitHub y/o Gitea según la sensibilidad del contenido. Está pensado para mantener los artefactos sensibles dentro de repositorios privados internos y públicos únicamente aquello que ya puede compartirse con terceros.

## Requisitos

- `bash`, `git`, `gh`, `gitea` y `python3` disponibles en el `PATH`.
- Acceso autenticado para `gh` (GitHub) y `gitea admin repo` con el token de servicio adecuado.
- El archivo de configuración `scripts/repo-visibility-plan.json` describe los targets y puede ajustarse a tus necesidades.

## Cómo funciona

1. Valida la presencia de los CLI (`git`, `gh`, `gitea`, `python3`) y carga `cs-common.sh`.
2. Para cada target definido en el JSON:
   - Copia los archivos rastreados por `git` que coinciden con las rutas (`paths`) y los filtros (`exclude`) al directorio temporal del target.
   - Inicializa un nuevo repo git en ese snapshot, calcula el branch y el commit.
   - En dry-run sólo reporta las acciones. Con `--run` o `--push`, crea/actualiza los repositorios en GitHub/Gitea, registra remotos y hace push.

## Configuración

El plan de visibilidad vive en `scripts/repo-visibility-plan.json`. Las claves principales son:

- `gitea_base_url`: URL base para construir la URL de clone cuando no se provee plantilla.
- `gitea_clone_url_template`: plantilla con `{owner}` y `{repo}` para la URL de push.
- `defaults`: valores por defecto para rama, mensaje de commit y otros campos que se repiten.
- `targets`: lista de objetos con:
  - `id`, `name`, `description`
  - `github_owner`, `gitea_owner`: destino de SCM para cada plataforma.
  - `visibility`: `secret`, `internal`, `public` (ayuda a inferir valores por omisión).
  - `platforms`: plataformas que deben recibir el target.
  - `paths`: glob patterns que se incluyen del monorepo.
  - `exclude`: glob patterns que se excluyen.

## Uso

```bash
bash scripts/repo-visibility-splitter.sh --config scripts/repo-visibility-plan.json  # dry-run
bash scripts/repo-visibility-splitter.sh --run                                          # crea y empuja
```

### Consejos adicionales

1. Ajustar `paths` y `exclude` a medida que cambian las fronteras sensibles.
2. Ejecutar primero en dry-run y revisar el resumen antes de habilitar `--run`.
3. Asegurarse de que las ramas no existan con historial conflictivo en los repositorios destino; el script siempre hace `git push -u`.

Mantén el archivo JSON actualizado con los nombres reales de organización/propietario cuando trabajes en producción.
