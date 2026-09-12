# Buildkite

`pipeline.yml` in this directory replaced CircleCI. There was one job there -
publishing the image on `main` - so there is one step here, and no build or test
step because the repository has none.

## Points worth knowing

- **There is deliberately no build cache.** The image wraps an upstream Go binary
  installed at build time, so every run has to fetch the latest upstream. A
  registry layer cache would pin an old one.
- **The registry credentials come from Doppler at runtime**, using the agent's
  `DOPPLER_TOKEN` (`GHCR_UPDATE_TOKEN` in `common/prd`), rather than from the
  agent environment - so no per-repo token is exposed to every job on the fleet.
- Publishing is `main`-only, matching CircleCI.

## What the agent has to provide

- **`plugins-path`** in `buildkite-agent.cfg`, and a unique agent `name` if the
  machine runs more than one agent.
- **Docker**, since the step runs a Docker build on the agent host.
