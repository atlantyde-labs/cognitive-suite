# Trust Pack ATLANTYQA

Pieza central para decisores: un paquete descargable con evidencia y garantías regulatorias.

## Contenido
1. **One-pagers sectoriales**  
   - [UE / universidades](generated/eu.md)  
   - [CCAA / ayuntamientos](generated/state.md)  
   - [Regulados](generated/corp.md)  
   - [Municipal](generated/municipal.md)  
   - [Integradores](generated/integrator.md)
2. **Security & Compliance overview** (1–2 páginas)  
   - SBOM y SCA dentro del pipeline (`release-draft.yml`, `jsonl-validate-wizard.sh`).  
   - Logs y evidencia (`bot-review.yml`, `outputs/bot-evidence`).  
   - Hardening runtime + modelos de data residency.
3. **Modelo de despliegue**  
   - Diagrama micro-CPD + edge (ver `docs/internal/compute-strategy.md`).  
   - Lista de componentes (IA local, agentes, compliance, squads).
4. **Caso de uso breve**  
   - Auditoría o backoffice: reducción de tiempo/auditorías.  
   - KPI: % reducción en preparación de auditorías, horas de backoffice automatizadas.

## Cómo publicar en MkDocs
* Crea enlaces de descarga en el hub sectorial y en los one-pagers hacia este documento.
* Añade un badge "Trust Pack" junto al CTA institucional.
* Si generas PDF, publica `docs/sales/generated/one-pagers.zip` o la versión PDF equivalente.
