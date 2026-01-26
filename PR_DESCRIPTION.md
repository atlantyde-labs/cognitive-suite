# Documentation Premium Overhaul: i18n Architecture & UI Polish

## 📋 Descripción
Esta PR introduce una reestructuración completa de la arquitectura de documentación para soportar **internacionalización (i18n) nativa** y un rediseño visual "Premium" enfocado en la limpieza y la legibilidad técnica.

## 🔧 Cambios Estructurales Críticos

### 1. **Arquitectura i18n Sólida**
- **Migración a `mkdocs-static-i18n`**: Se ha abandonado el sistema de navegación manual por un plugin especializado que gestiona contextos de idioma aislados.
- **Estructura de Ficheros**: Migración de carpetas (`docs/en/file.md`) a sufijos (`docs/file.en.md`). Esto permite que el plugin enlace automáticamente las traducciones.
- **Navegación Aislada**:
    - **Español**: Menú exclusivo en español.
    - **Inglés**: Menú exclusivo en inglés (sin sangrado de "Inicio").
- **Selector de Idioma**: Selector nativo en el header (icono globo) totalmente funcional y contextual.

### 2. **Rediseño Visual & UX**
- **Limpieza de "Ruido"**:
    - Ocultado los símbolos de párrafo (`¶`) en los encabezados.
    - Ocultada la **barra lateral secundaria (Tabla de Contenidos)** para maximizar el espacio de lectura.
- **Diagramas Mermaid Optimizados**:
    - Layout Vertical (TD) para mejor flujo.
    - **Tipografía Ultra-Legible**: Textos forzados a **20px Bold** via CSS.
    - **Estética Limpia**: Eliminados los enlaces interactivos y subrayados que ensuciaban el diseño.
- **Animaciones**: Implementada animación `fadeInUp` suave en la carga de contenidos.

### 3. **Correcciones Técnicas**
- **Dependencias**: Añadido `mkdocs-static-i18n` al entorno virtual `.venv` y a `requirements.txt`.
- **Linting CSS**: Corregido warning de `background-clip` para compatibilidad estándar.

## 📊 Comparativa

| Característica | Antes | Después (Esta PR) |
|---|---|---|
| **Navegación** | Mezcla de idiomas ("Inicio" en menú EN) | Contextos 100% aislados |
| **Diagramas** | Texto pequeño, ilegible en móvil | **20px Bold**, Vertical, Alta claridad |
| **Estética** | Enlaces azules, símbolos ¶ visibles | **Clean Design**, sin subrayados, sin ¶ |
| **Arquitectura** | Manual, propensa a errores 404 | **Automática** via Plugin estándar |

## 🚀 Validaciones
- [x] `mkdocs serve` arranca sin errores ni warnings críticos.
- [x] Navegación ES -> EN -> ES fluida y sin 404s.
- [x] Mermaid legible en desktop y móvil.
- [x] Animaciones fluidas.

## 📝 Notas para Reviewer (Jimmy)
Recomiendo verificar especialmente la navegación cruzada entre idiomas. La estructura de archivos ha cambiado de carpetas anidadas a sufijos `.en.md` para cumplir con las mejores prácticas del plugin de i18n.
