# homelab

A single-cluster Kubernetes homelab run like a small production platform: Talos Linux,
Flux, SOPS, backups to off-site object storage, and automated updates.
Everything is declared in this repository. The goal is a full rebuild from git,
backups and the offline secrets alone.

Build plan: [docs/SPEC.md](docs/SPEC.md). Decisions: [docs/adr](docs/adr).
Hardware and accounts: [docs/inventory.md](docs/inventory.md).

## Status

| Phase | State |
|---|---|
| 0 Discovery and decisions | in progress |
| 1 CI, protection, updates | not started |
| 2 Nodes and cluster | not started |
| 3 GitOps core | not started |
| 4 Network, exposure, platform security | not started |
| 5 Storage and backups | not started |
| 6 Observability | not started |
| 7 Applications | not started |
| 9 Disaster recovery game day | not started |

## Getting started

```sh
mise install
task hooks:install
task --list
```
