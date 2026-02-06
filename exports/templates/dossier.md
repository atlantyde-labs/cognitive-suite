# Dossier de Capacidades Técnicas y de Talento

## 1. Equipo validado
El equipo participante cuenta con perfiles evaluados mediante:
- contribuciones auditadas
- formación práctica certificada
- roles de confianza regulatoria

## 2. Métricas agregadas
- Nº perfiles activos: {{ users_total }}
- Auditores habilitados: {{ auditors }}
- Revisores habilitados: {{ reviewers }}

## 3. Capacidades regulatorias
- GDPR
- AI Act
- NIS2
- QA / Seguridad

## 4. Evidencias
{% for credential in credentials %}
- {{ credential.lab }} — credencial firmada
{% endfor %}

## 5. Trazabilidad
Toda la información es verificable mediante repositorio Git y firmas.
