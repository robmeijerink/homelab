# homelab

A Kubernetes homelab run like a small production platform. Everything is declared in
this repository: Flux applies `main`, secrets are encrypted with SOPS and Renovate keeps
versions current. The goal is a full rebuild from git, backups and a few offline secrets.

The first cluster runs on Oracle Cloud Always Free (OKE, two Ampere A1 workers). The
configuration above the cluster is meant to move to Talos Linux on my own hardware later.

## Status

- CI is in place. `lint`, `validate` and `secrets` are required on every pull request,
  and `main` is protected.
- Renovate tracks the pinned tools, GitHub Actions, the OCI provider, the Cilium chart and
  the Flux Operator and Flux versions.
- The OKE cluster is built from `infra/` with OpenTofu, and Cilium replaces flannel through
  `task bootstrap:cilium`. A rebuild from scratch takes about half an hour.
- Flux Operator syncs `main` and manages itself. SOPS decryption is in place; the repository is
  public, so Flux needs no credentials.
- Networking, storage, backups and monitoring are not built yet.

## Layout

| Path | Content |
|---|---|
| `infra/` | OpenTofu for the OKE cluster |
| `bootstrap/` | What is applied outside Flux: Cilium and the Flux Operator |
| `kubernetes/` | Flux and app manifests |
| `talos/` | Talos configuration for the later bare-metal cluster |
| `scripts/` | Checks and bootstrap steps that do not fit a task |
| `.github/` | Workflows, Renovate config and the `main` ruleset |

## Getting started

Requires [mise](https://mise.jdx.dev/).

```sh
mise trust && mise install
task hooks:install
task --list
```
