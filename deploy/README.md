# Deployment runbook: vikunja-mcp

`vikunja-mcp` wraps the upstream [acidvegas/vikunja-mcp](https://github.com/acidvegas/vikunja-mcp)
Go binary. CircleCI publishes the image to
`ghcr.io/nickbrett1/vikunja-mcp` (public), and Watchtower on the NAS keeps the
running container up to date.

## 1. Build & publish (CircleCI)

- Push to `main` — or, to rebuild against the **latest upstream**, open
  CircleCI → repo → **`publish` workflow → Rerun**.
- The `docker-publish` job logs into GHCR (using the `common` CircleCI context's
  `GHCR_USERNAME` / `GHCR_TOKEN`) and runs `docker buildx build --push`,
  tagging `:latest` and the commit SHA.
- **No registry layer cache is used**, so every run does a fresh
  `go install github.com/acidvegas/vikunja-mcp@latest` — you always get the
  newest upstream.
- The Dockerfile's `org.opencontainers.image.source` label links the GHCR
  package to this repo, so the **public repo → public package** (no credentials
  needed to pull on the NAS).

### One-time CircleCI context (`common`)

Already configured for your other repos. If it ever needs recreating:
1. CircleCI → Organization Settings → Contexts → Create Context `common`.
2. Add `GHCR_USERNAME` (your GitHub username) and `GHCR_TOKEN` (a **classic**
   PAT with the `write:packages` scope). Fine-grained PATs can't push to GHCR.

## 2. Deploy on this NAS (integrated with the Vikunja project)

The service lives inside the Vikunja compose project at
`/volumeUSB1/usbshare/docker/vikunja/compose.yaml`, alongside the `vikunja`
container so `VIKUNJA_URL=http://vikunja:3456` resolves. Its `vikunja-mcp`
service is pointed at the published image and opted into Watchtower.

After a publish, Watchtower recreates `vikunja-mcp` automatically. To force a
refresh now:

```bash
cd /volumeUSB1/usbshare/docker/vikunja
docker compose pull vikunja-mcp
docker compose up -d vikunja-mcp
```

## 3. Standalone hosts / Container Manager "Project"

The repo root `docker-compose.yml` is a standalone equivalent. It publishes
`8086:8000` and joins an external `ai_proxy` network. On a Synology you can also
import it as a Container Manager Project; provide `.env` (see `.env.example`)
with `VIKUNJA_TOKEN`.

## 4. Auto-updates with Watchtower (poll model)

Watchtower polls GHCR and recreates the container when the digest changes.
- Opt-in via the `com.centurylinklabs.watchtower.enable=true` label.
- Public package → **no credentials needed** on the NAS.
- Set the main Watchtower's scope label to match if you run a scoped instance.

## 5. Rolling back a bad update

Watchtower recreates on every publish. Every image is also tagged with its
commit SHA, so pin a known-good build:

```yaml
image: ghcr.io/nickbrett1/vikunja-mcp:<commit-sha>
```

restart the project, and Watchtower won't overwrite the pinned tag.

## 6. Homepage dashboard

`deploy/homepage-services.yaml` has a snippet (icon + `http://nas:8086/` link)
to append to your Homepage `services.yaml`. There is no health endpoint on the
wrapper, so no widget is emitted (the MCP endpoint returns 404 to plain HTTP
GETs).
