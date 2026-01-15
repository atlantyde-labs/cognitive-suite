# 🧠 Estrategia de Cómputo: Local vs GitHub Actions

Este documento define qué tareas ejecutar localmente y cuáles aprovechar desde runners públicos o contenedores GPU en GitHub Actions.

---

## ⚖️ Matriz de decisión

| Tarea | Recursos | Riesgo | ⚙️ Local | ☁️ GitHub Actions |
|-------|----------|--------|----------|------------------|
| 🧪 Pruebas YAML/Python | Bajo (CPU) | Bajo | ✅ | ✅ |
| 🧠 Análisis SpaCy | Medio (RAM) | Medio | ✅ | ✅ |
| 🧬 Entrenamiento ML | Alto (GPU) | Alto | ⚠️ Limitado | ✅ (Docker GPU) |
| 🎯 Análisis batch | Alto (CPU Hilos) | Medio | ⚠️ | ✅ |
| 📦 Build Docker | Medio | Bajo | ✅ | ✅ |
| 📤 GitOps auto-push | Bajo | Alto | ✅ | 🚫 |
| 🔍 Scan CodeQL/Rego | Medio | Alto | ✅ | ✅ |

---

## 🧭 Reglas generales

- **Local**: Pruebas iterativas rápidas, control de credenciales, GitOps controlado
- **GitHub Actions**: Validación pública, entrenamiento pesado, testing GPU

---

## 🔐 Seguridad
- Nunca subir `.env` o claves locales
- El push GitOps requiere validación manual o GPG firmado desde dev
- Recomendado usar Secrets de GitHub para acceso API/cloud