# homelab

A Kubernetes homelab run like a small production platform. Everything is declared in
this repository: Flux applies `main`, secrets are encrypted with SOPS and Renovate keeps
versions current. The goal is a full rebuild from git, backups and a few offline secrets.

The first cluster runs on Oracle Cloud Always Free (OKE, two Ampere A1 workers). The
configuration above the cluster is meant to move to Talos Linux on my own hardware later.

## Status

- CI is in place. `lint`, `validate` and `secrets` are required on every pull request,
  and `main` is protected.
- Renovate tracks the pinned tools, GitHub Actions and the OCI provider.
- The OKE infrastructure is written in OpenTofu under `infra/` but not applied yet.
- Flux, networking, storage, backups and monitoring are not built yet.

## Layout

| Path | Content |
|---|---|
| `infra/` | OpenTofu for the OKE cluster |
| `kubernetes/` | Flux and app manifests |
| `bootstrap/` | What is applied outside Flux |
| `talos/` | Talos configuration for the later bare-metal cluster |
| `scripts/` | Checks that do not fit a task |
| `.github/` | Workflows, Renovate config and the `main` ruleset |

## Getting started

Requires [mise](https://mise.jdx.dev/).

```sh
mise install
task hooks:install
task --list
```
