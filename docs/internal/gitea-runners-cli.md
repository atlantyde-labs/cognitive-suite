# Gitea Runners CLI (Local-First)

Objetivo: operar runners localmente con CLI y mantener el codigo siempre on-prem.

## Instalacion rapida

1) Copia el env:

```bash
cp bash/GitDevSecDataAIOps/proxmox/gitea-runner.env.example /tmp/gitea-runner.env
```

2) Instala el servicio:

```bash
sudo bash bash/GitDevSecDataAIOps/proxmox/install-gitea-runner-systemd.sh /tmp/gitea-runner.env
```

## Control via CLI

```bash
sudo ENV_FILE=/etc/gitea-runner.env bash /usr/local/bin/gitea-runner-service.sh status
sudo ENV_FILE=/etc/gitea-runner.env bash /usr/local/bin/gitea-runner-service.sh restart
```

## Buenas practicas

- Runner con etiquetas: `local,airgap,proxmox`.
- Tokens de registro solo en `/etc/gitea-runner.env` (0600).
- Rota tokens tras cada incidente.
