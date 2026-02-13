# Demo Scripts & Backup

## Breach variants (Step B)

- `prod-db-breach-public.yaml` — set `public: true`; OPA message: *"Database must be private!"*
- `prod-db-breach-extra-large.yaml` — set `size: extra-large`; OPA message: *"Instance size not allowed!"*

Use one per demo: copy to `../platform/prod-db.yaml`, commit, push. Then fix and push again for Step C.

## Backup recording

1. Record at **1080p** the full flow: Happy Path → Security Fail → Portal Reveal.
2. If conference Wi‑Fi fails, play the video and talk over it.

## Warm resources

- Pre-provision a DB (or use a composition that creates quickly) so you don’t wait 10 minutes for RDS on stage.
- Option: pre-apply the happy-path `prod-db.yaml` before the talk; for Step A do a no-op sync or show the existing resource.

## Terminal

- High-contrast theme, **18pt+** font so YAML is readable from the back of the room.
