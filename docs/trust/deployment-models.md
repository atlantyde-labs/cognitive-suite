# Deployment Models

ATLANTYQA puede desplegar en:

1. **Local-first / On-prem:** microCPDs y edge que ejecutan todos los agentes y guardan los datos sensibles.  
2. **Híbrido:** tareas menos críticas en cloud certificada, manteniendo data residency.  
3. **Air-gap:** enclaves aislados para decisiones de alto riesgo.

Nuestra estrategia de cómputo (`docs/internal/compute-strategy.md`) describe qué cargas se mantienen locales y cómo se gestiona la conectividad segura.

## Politica minima de implantacion

- Plazo minimo contractual: **180 dias** para cualquier implantacion en oferta publica.
- Reserva operativa obligatoria: **30 dias** adicionales para incidencias inesperadas sin degradar el servicio.
- Gates de calidad por fase: **UAT**, seguridad, compliance, readiness operativa y cierre documental de evidencias.
