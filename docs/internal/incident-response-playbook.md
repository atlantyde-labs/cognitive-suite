# Playbook de respuesta a incidentes (Borrador)

## 0. Niveles de severidad
- SEV1: impacto critico, brecha de datos o caida prolongada
- SEV2: impacto mayor, servicio degradado
- SEV3: impacto menor, alcance limitado

## 1. Deteccion y triaje
- Fuentes de disparo: alertas, reportes de usuarios, monitoreo
- Checklist inicial de triaje:
  - Identificar servicios afectados
  - Determinar severidad
  - Iniciar log de incidente

## 2. Contencion
- Aislar componentes afectados
- Deshabilitar flujos riesgosos (sync GitOps, llamadas externas)
- Preservar evidencia (logs, configs)

## 3. Erradicacion
- Remover causa raiz
- Parchear vulnerabilidades
- Validar integridad

## 4. Recuperacion
- Restaurar servicios
- Monitorear recurrencia
- Verificar integridad de datos

## 5. Comunicacion
- Linea de tiempo de comunicaciones internas
- Notificaciones externas (si aplica)
- Reporte regulatorio (si aplica)

## 6. Revision post-incidente
- Linea de tiempo
- Analisis de causa raiz
- Acciones correctivas
- Lecciones aprendidas

## 7. Evidencias
- Log del incidente
- Artefactos forenses
- Aprobacion de cierre
