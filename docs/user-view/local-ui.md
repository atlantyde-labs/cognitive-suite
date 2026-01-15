# Local User View (UI) – Cognitive Suite

Esta sección documenta la **vista de usuario** de la Cognitive Suite cuando está **instalada en local** (Docker o Kubernetes). El objetivo es que un tercero (AAPP, banca, partner, QA) pueda entender:

- Qué ve el usuario al abrir la suite
- Cómo levantar la consola local
- Dónde se encuentran los outputs
- Flujo funcional mínimo (MVP)

---

## 1. Acceso rápido

### Opción A: UI local con Docker (recomendado)

Desde la **raíz del repo**:

```bash
make ui-build
make ui-up
```

Abre: `http://localhost:8501`

La UI lee por defecto los outputs desde un volumen montado en:

- Host: `./outputs`
- Contenedor: `/data/outputs`

### Opción B: UI local sin Docker

```bash
pip install -r requirements.txt
make ui-local
```

---

## 2. Estructura de outputs esperada

La UI consume:

- `outputs/insights/analysis.json`

Puedes cambiar la raíz de outputs con:

- `COGNITIVE_OUTPUTS=/ruta/a/outputs`

---

## 3. Pantallas y flujo

### 3.1 Dashboard / Explorador de resultados

- Tabla de documentos analizados
- Filtro por etiquetas cognitivas
- Selección por UUID

### 3.2 Detalle de registro

- Metadatos (archivo, tipo, etiquetas)
- Resumen
- Sentimiento
- Entidades extraídas

---

## 4. Troubleshooting

### No aparece ningún resultado

1) Verifica que exista el archivo:

```bash
make ui-doctor
```

2) Si ejecutas en Docker, asegúrate de montar `./outputs`.

### La UI no carga

- Confirma que el puerto `8501` está libre
- Ejecuta `make ui-build` de nuevo

---

## 5. Roadmap UX (siguiente nivel)

- Exportar a Markdown/PDF desde la UI
- Panel GitOps (crear issue/PR desde insights)
- Autenticación local (SSO/LDAP opcional)
- Capturas y demo script institucional
