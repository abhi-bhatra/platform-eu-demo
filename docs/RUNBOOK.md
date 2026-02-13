# Demo Runbook — Backend-First IDP

Use this as a linear checklist during the talk. Assume Crossplane, Argo CD, OPA, and Backstage are already installed and configured.

---

## Before You Go On Stage

1. Argo CD UI open on the right screen; Application for `platform/` visible and **Synced** (or no app yet for Step A).
2. Terminal on the left: repo cloned, branch clean, remote correct.
3. Cloud Console (RDS/Cloud SQL) in a tab — optional for Step A if you have a warm resource to show.
4. Backstage tab ready; don’t open the catalog until Step C.
5. Backup video ready to play if Wi‑Fi fails.

---

## Step A: Happy Path

1. In repo, open or create `platform/prod-db.yaml`.
2. Paste or type the 10-line contract (see below).
3. Save, commit, push:
   ```bash
   git add platform/prod-db.yaml && git commit -m "Add prod checkout DB" && git push
   ```
4. Switch to Argo CD: wait for “Out of Sync” → “Syncing” → “Synced”.
5. (Optional) Show Cloud Console: new RDS/DB instance created by Crossplane.
6. **Say**: “One file, one push. No portal, no ticket.”

**Sample `platform/prod-db.yaml` (happy path):**

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

---

## Step B: Security Gate

1. Edit `platform/prod-db.yaml`: add `public: true` under `spec`, **or** set `size: extra-large`.
2. Save, commit, push:
   ```bash
   git add platform/prod-db.yaml && git commit -m "Try public/large DB" && git push
   ```
3. Switch to Argo CD: sync will run and **fail**.
4. Click “Sync Failed” (or equivalent) and show the OPA error message.
5. **Say**: “Backend-First means they can’t bypass this — same result from CLI, API, or UI.”

---

## Step C: Portal Reveal

1. Edit `platform/prod-db.yaml`: remove `public: true` and set `size: small` again.
2. Save, commit, push:
   ```bash
   git add platform/prod-db.yaml && git commit -m "Fix: private small DB" && git push
   ```
3. Argo CD: wait for “Synced”.
4. Open Backstage → Software Catalog (or Kubernetes view).
5. Show the new Database/entity appearing automatically.
6. **Say**: “We didn’t click Create in Backstage. The backend built it; the portal observed the truth.”

---

## If Something Breaks

- **Argo CD doesn’t see the repo**: Check Application source repo URL and path (`platform/`). Hard refresh.
- **Crossplane doesn’t create DB**: Check provider credentials and Composition selector; `kubectl get claim` and provider logs.
- **OPA doesn’t block**: Confirm Constraint and Rego are applied; test with `kubectl apply -f` of a bad manifest.
- **Backstage doesn’t show DB**: Confirm Kubernetes plugin points at the right cluster/namespace; refresh or wait for discovery.

---

## One-Line Cues

- **After Happy Path**: “State in Git. Argo syncs. Crossplane provisions.”
- **After Security Fail**: “Governance at the control plane. No bypass.”
- **After Portal**: “The UI is a lens. The backend is the platform.”
