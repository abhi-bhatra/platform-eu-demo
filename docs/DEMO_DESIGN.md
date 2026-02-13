# Demo Design — Backend-First IDP (KubeCon Europe)

## 1. Pre-Stage: What Must Be Running

| Component | Purpose | Check |
|-----------|---------|--------|
| **Orchestrator** | Crossplane + Provider (AWS/GCP/Azure) + XRD `DatabaseInstance` + Composition | `kubectl get xrd` and `kubectl get composition` |
| **State Engine** | Argo CD watching `platform/` (or your Git folder) | Argo CD UI shows Application; sync works |
| **Gatekeeper** | OPA with Rego bundle: no `public: true`, no `size: extra-large` | Constraint blocks bad YAML when applied |
| **View** | Backstage + Kubernetes plugin discovering resources in cluster | Backstage catalog lists K8s/CRs |

**Warm resources**: Have a pre-provisioned DB (or use a fast composition) so you don’t wait 10 minutes for RDS mid-talk.

---

## 2. Step-by-Step Walkthrough

### Step A: Happy Path (~3 min)

- **Terminal**: Split screen — terminal left, Argo CD right.
- **Action**: Create/commit `platform/prod-db.yaml` with the 10-line `DatabaseInstance` contract (Slide 6).
- **Sync**: `git push`; Argo CD picks up the change.
- **Result**: Argo CD goes green (Synced). Switch to Cloud Console and show the RDS/Cloud SQL instance created by Crossplane.

**Talking point**: “One file, one push. No portal, no ticket. The backend is the platform.”

---

### Step B: Security Gate (~4 min) — *Most important*

- **Breach**: Edit `platform/prod-db.yaml`: set `public: true` or `size: extra-large` (forbidden by OPA).
- **Sync**: `git push`.
- **Block**: Argo CD tries to sync and **fails**.
- **Error**: In Argo CD, open “Sync Failed” and show the OPA message: e.g. “Database must be private!” or “Instance size not allowed!”.
- **Takeaway**: “Backend-First means the developer can’t bypass this rule, no matter which tool they use.”

---

### Step C: Portal Reveal (~3 min)

- **Fix**: Revert/fix the YAML (remove `public: true` or set `size: small`), push again.
- **Success**: Resource provisions; Argo CD green.
- **UI**: Open Backstage.
- **Result**: New Database appears in the Software Catalog automatically.
- **Kicker**: “We didn’t click ‘Create’ in Backstage. The backend built the resource; the portal just observed the truth.”

---

## 3. Demo Preparation Checklist

- [ ] **Backup recording**: 1080p recording of the full flow (Happy Path → Security Fail → Portal Reveal). If Wi‑Fi fails, play the video and narrate.
- [ ] **Warm resources**: Pre-provisioned DB or fast composition so provisioning doesn’t block the talk.
- [ ] **Visuals**: High-contrast terminal theme, 18pt+ font so YAML is readable from the back of the room.
- [ ] **Git**: Repo pushed to GitHub (or your Git host); Argo CD has correct URL and path (`platform/`).
- [ ] **OPA**: Policy bundle loaded and Constraint(s) created and verified with a quick “bad” apply test.
- [ ] **Backstage**: Kubernetes plugin configured for the demo cluster/namespace; one manual refresh or auto-discovery verified.

---

## 4. Red-Flag Alignment (From Your Deck)

| Red-Flag Test | How the demo shows it |
|---------------|------------------------|
| **PR Test** | New parameter = change in Crossplane Composition; UI (Backstage) reflects it. No frontend PR. |
| **Dark API Test** | Same `DatabaseInstance` CR from Git/CLI/API; no UI-only path. |
| **Drift Test** | OPA blocks non-compliant YAML at sync; no way to bypass via portal or CLI. |

Use these as one-line callbacks if someone asks about “what if we only use the UI?” or “can someone skip policy?”.
