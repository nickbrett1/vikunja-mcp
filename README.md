# vikunja-mcp

Thin container wrapper around [acidvegas/vikunja-mcp](https://github.com/acidvegas/vikunja-mcp)
— an MCP server for [Vikunja](https://vikunja.io) (Go binary, stdio + Streamable
HTTP transport). It does **not** vendor upstream source: the Dockerfile simply
`go install`s the upstream module and serves the resulting binary, so rebuilding
always pulls the latest upstream.

The repo only contains the packaging/config (Dockerfile + CircleCI + deploy
files) that turns the upstream binary into a `ghcr.io/nickbrett1/vikunja-mcp`
image your NAS can run and auto-update with Watchtower.

## Why this repo?

Previously the image was built by hand on the NAS (`docker compose build`), so
Watchtower could never update it. Now:

- Pushing to `main` (or **re-running the `publish` workflow** in CircleCI)
  rebuilds the image against the **latest** upstream `acidvegas/vikunja-mcp`
  and pushes `ghcr.io/nickbrett1/vikunja-mcp:latest`.
- Watchtower on the NAS pulls the new image and recreates the container —
  **no SSH/build on the NAS required**. Rebuild = press "Rerun" in CircleCI.

> Each CircleCI run builds from a clean cache (no layer cache), so the
> `go install ...@latest` step always fetches the newest upstream.

## Repo layout

- `Dockerfile` — multi-stage: `golang` builds `github.com/acidvegas/vikunja-mcp`,
  slim `alpine` runtime serves it. `--build-arg VERSION` to pin upstream.
- `.circleci/config.yml` — `docker-publish` job (login → buildx → push to GHCR),
  gated to `main`, using the `common` CircleCI context (`GHCR_USERNAME` /
  `GHCR_TOKEN`).
- `docker-compose.yml` / `.env.example` — NAS deployment reference.
- `.devcontainer/` — devcontainer for editing this repo (Python toolchain +
  zsh + goose + doppler); convenient but not required to rebuild.
- `deploy/README.md` — deployment runbook.

## Environment (runtime)

| Variable                | Default               | Purpose                        |
|-------------------------|-----------------------|--------------------------------|
| `VIKUNJA_URL`           | `http://vikunja:3456` | URL of the Vikunja API         |
| `VIKUNJA_TOKEN`         | *(required)*          | Vikunja API token              |
| `VIKUNJA_MCP_TRANSPORT` | `http`                | MCP transport (stdio/http)     |
| `VIKUNJA_MCP_HOST`      | `0.0.0.0`             | Bind host for HTTP transport   |
| `VIKUNJA_MCP_PORT`      | `8000`                | Port for HTTP transport        |

## Rebuilding to latest

1. Open the repo's project in CircleCI → `publish` workflow → **Rerun**.
2. CircleCI rebuilds and pushes `ghcr.io/nickbrett1/vikunja-mcp:latest`.
3. Watchtower recreates `vikunja-mcp` on the NAS automatically.

## Deploy

See `deploy/README.md` for the NAS / Watchtower steps.
