# Desafio de deteccion de talento (Labs + agentes IA)

Esta guia define un desafio estructurado para que los adoptantes tempranos revelen senales de talento mediante Labs, sistemas de recompensas y agentes de IA personales que acompanan la experiencia del usuario.

## Objetivos
- Detectar talento tecnico usando Labs practicos.
- Proveer un agente de IA personal para guia y retroalimentacion.
- Otorgar recompensas transparentes y auditables basadas en evidencia.
- Mantener privacidad, cumplimiento y restricciones soberanas.

## Concepto base
- Los Labs son misiones cortas y practicas que reflejan flujos reales.
- Cada Lab genera evidencia via GitOps (PRs, logs, artefactos).
- Las recompensas se otorgan por evidencia, no por opiniones.
- El agente personal es un acompanante: guia, revisor y guardia de seguridad.

## Recorrido del usuario
1) Incorporacion
   - Selecciona una ruta (Data, DevSecOps, ML, Product, Frontend, Docs).
   - Crea un perfil con consentimiento explicito para puntuacion.

2) Seleccion de Lab
   - Elige un Lab de una escalera de dificultad.
   - El agente explica objetivos, riesgos y reglas de recompensa.

3) Ejecucion
   - El usuario completa tareas en un fork o rama sandbox.
   - El agente ayuda con pistas, controles y validaciones.

4) Envio de evidencia
   - Envios via PR o sync GitOps.
   - CI registra evidencia: SBOM, SCA, tests, logs de auditoria.

5) Puntuacion y recompensas
   - Puntuacion automatica basada en evidencias.
   - Revision manual solo en casos limite.

6) Crecimiento
   - El siguiente Lab se ajusta segun fortalezas y brechas observadas.

## Estructura del Lab (plantilla)
- Titulo:
- Dificultad: L1 / L2 / L3 / L4
- Objetivo:
- Salidas requeridas:
- Fuentes de evidencia:
- Controles de riesgo y cumplimiento:
- Recompensa:

## Ejemplos de Labs

### Misiones Disponibles

#### Lab 01 - Línea Base de Pipeline Seguro (Expert Level)
Este Lab ha sido actualizado a un nivel de experto, incluyendo validación automática de IA y controles de privacidad avanzados.
👉 **Comenzar Misión**: [Lab 01 Deep Dive](file:///c:/Users/jose/AppData/Roaming/Code/User/globalStorage/google.coder-bot/brain/faa54a41-8368-462c-af2a-f90e70b46244/lab-01-deep-dive.md)

### Lab 02 - Sync GitOps con outputs redactados
- Dificultad: L2
- Objetivo: sincronizar outputs redactados a un repo remoto.
- Salidas requeridas: PR con solo outputs redactados.
- Evidencia: logs de CI, evidencia de `gitops/sync.sh`.
- Recompensa: 100 puntos + insignia `gitops-steward`.

### Lab 03 - Guia de endurecimiento
- Dificultad: L3
- Objetivo: aplicar endurecimiento de contenedores y documentar riesgos.
- Salidas requeridas: compose actualizado y nota corta de riesgo.
- Evidencia: diff de `docker-compose.prod.yml` + notas de revision.
- Recompensa: 200 puntos + insignia `runtime-guardian`.

## Sistema de recompensas
- Puntos: 0 a 1000 por Lab segun dificultad.
- Insignias: prueba permanente de capacidad.
- Niveles: L1 (Explorador) -> L4 (Experto).
- Bonos: puntos extra por SCA limpio, tests y docs.

## Rubrica de evaluacion
- Correccion (40%): objetivos cumplidos y reproducibles.
- Seguridad (25%): sin violaciones de politica; redaccion aplicada.
- Calidad (20%): diffs limpios, docs claras, tests.
- Colaboracion (15%): descripcion de PR, retroalimentacion de pares.

## Roles del agente de IA
- Agente de incorporacion: ayuda de config, prerequisitos, consentimiento.
- Guia de Lab: pistas, planificacion de tiempo, gestion de alcance.
- Guardia de seguridad: alerta acciones riesgosas (sync de datos en bruto, secretos).
- Revisor: destaca brechas antes de envio.
- Agente de carrera: sugiere el siguiente Lab segun tendencias de puntuacion.

## Cumplimiento y privacidad
- Consentimiento explicito para puntuacion y retencion de datos.
- Solo outputs redactados en evidencia prod.
- Logs de auditoria por cada ejecucion de Lab.
- Modo soberano: solo local, sin llamadas externas.

## Lista de verificacion de evidencia
- Logs de CI adjuntos
- Artefactos SBOM
- Resultados SCA
- Logs de auditoria
- PR con lista de verificacion completa

## Controles anti-fraude
- Revisiones aleatorias y tests ocultos.
- Recompensas requieren evidencia reproducible.
- Revision manual en patrones sospechosos.

## Proximos pasos
- Publicar Labs en un repo dedicado o carpeta `labs/`.
- Definir registro de recompensas (JSON o CSV simple).
- Asignar revisores para Labs L3 y L4.
