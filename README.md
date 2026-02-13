# Backend-First IDP — KubeCon Europe Demo

Demo for the talk **"Backend-First IDP: A Production Roadmap with Argo CD, Crossplane, and OPA"**.

## Demo Arc

| Step | Name | Duration | Goal |
|------|------|----------|------|
| **A** | Happy Path | ~3 min | Developer commits a 10-line contract → Git push → Argo CD syncs → Crossplane provisions DB |
| **B** | Security Gate | ~4 min | Edit YAML to violate policy (e.g. `public: true` or `size: extra-large`) → Sync fails → OPA error visible in Argo CD |
| **C** | Portal Reveal | ~3 min | Fix YAML → sync succeeds → Backstage catalog shows the new DB (no "Create" button; backend built it, portal observed) |

## Architecture (Pre-Stage)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Backend-First IDP Demo                          │
├─────────────────────────────────────────────────────────────────────────┤
│  Developer (Git)                                                        │
│       │                                                                 │
│       ▼  git push                                                       │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────────────────────┐│
│  │  GitHub     │────▶│  Argo CD    │────▶│  Crossplane + Provider       ││
│  │  repo       │     │  (State     │     │  (Orchestrator)             ││
│  │  (source    │     │   Engine)   │     │  DatabaseInstance → RDS      ││
│  │   of truth) │     │             │     └─────────────────────────────┘│
│  └─────────────┘     └──────┬──────┘                                    │
│                             │                                            │
│                             │  OPA (Gatekeeper)                          │
│                             │  • public: true forbidden                  │
│                             │  • size: extra-large forbidden             │
│                             ▼                                            │
│  ┌─────────────┐     ┌─────────────┐                                    │
│  │  Backstage  │────▶│  Kubernetes │  "Discover" resources in cluster    │
│  │  (View)     │     │  plugin     │  → Catalog shows DB automatically  │
│  └─────────────┘     └─────────────┘                                    │
└─────────────────────────────────────────────────────────────────────────┘
```

## Repo Layout

```
kubecon-eu/
├── README.md                 # This file
├── docs/
│   ├── DEMO_DESIGN.md        # Full design and talking points
│   └── RUNBOOK.md            # Step-by-step demo runbook
├── crossplane/
│   ├── xrd-database-instance.yaml
│   └── composition-db-small-eu-west.yaml
├── argocd/
│   └── application.yaml     # Argo CD Application pointing at ./platform
├── platform/                 # GitOps target (Argo CD watches this folder)
│   └── prod-db.yaml         # The 10-line DatabaseInstance (happy path)
├── opa/
│   └── policies/            # Rego bundle (public + size checks)
│       └── ...
├── demo-scripts/            # Optional: backup recording script, warm-resource tips
└── backstage/               # Notes for Backstage + K8s plugin config
```

## What to set up before running

- **k3s + Crossplane already?** → **[docs/NEXT_STEPS.md](docs/NEXT_STEPS.md)** — GitHub repo, provider-kubernetes (no AWS), Gatekeeper, Argo CD, and a ready-to-run demo.
- **Full list from scratch:** see **[docs/SETUP.md](docs/SETUP.md)** — cluster, Crossplane (+ provider + credentials), Gatekeeper, Argo CD, Backstage, Git repo, and a pre-demo checklist.

**In short:**

1. **Kubernetes cluster** — any 1.24+ cluster.
2. **Crossplane** — install Crossplane, then a cloud provider (e.g. AWS), configure credentials, apply `crossplane/xrd-database-instance.yaml` and `crossplane/composition-db-small-eu-west.yaml`.
3. **Gatekeeper** — install Gatekeeper, then apply `opa/constraint-template-database-instance.yaml` and `opa/constraint-database-instance.yaml`.
4. **Argo CD** — install Argo CD, set `repoURL` in `argocd/application.yaml` to your Git repo URL, apply the Application.
5. **Backstage** (optional) — install Backstage, add Kubernetes plugin, point at the same cluster.
6. **Git repo** — push this repo to GitHub/GitLab and use that URL in the Argo CD Application.

See `docs/RUNBOOK.md` for the demo steps and `docs/DEMO_DESIGN.md` for talking points and backup-recording checklist.

## The 10-Line Contract (Slide 6)

The developer only writes this; Crossplane + Composition do the rest:

```yaml
apiVersion: myplatform.io/v1
kind: DatabaseInstance
metadata:
  name: checkout-db
spec:
  size: small
  region: eu-west-1
  team: checkout
```

No portal click. No dark API. State in Git; OPA enforces; Backstage discovers.
# platform-eu-demo
# platform-eu-demo
