# Setup Prior to Running the Demo

Everything you need to install and configure **before** running the Backend-First IDP demo.

---

## 1. Kubernetes cluster

- A running cluster (kind, minikube, EKS, GKE, AKS, or any Kubernetes 1.24+).
- `kubectl` configured to talk to that cluster.
- Enough resources for Crossplane, Argo CD, Gatekeeper, and (optionally) Backstage.

---

## 2. Git repository

- This repo (or a fork) pushed to a Git host (GitHub, GitLab, etc.).
- You have push access so you can demo `git push` in Step A/B/C.
- Note the **clone URL** — you will use it in the Argo CD Application (e.g. `https://github.com/yourorg/kubecon-eu.git`).

---

## 3. Crossplane (orchestrator)

### 3.1 Install Crossplane

```bash
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm install crossplane crossplane-stable/crossplane --namespace crossplane-system --create-namespace
```

### 3.2 Install a cloud provider

**Option A — AWS (Upbound provider-aws)**

```bash
kubectl apply -f https://raw.githubusercontent.com/crossplane-contrib/provider-aws/main/package/crossplane.yaml
# Wait for provider to be healthy
kubectl get provider
```

Create a `ProviderConfig` and store cloud credentials (e.g. via IRSA, static credentials, or env). Example with a secret:

```bash
kubectl create secret generic aws-creds -n crossplane-system \
  --from-file=credentials=~/.aws/credentials
```

Then a `ProviderConfig` that references this secret (see [provider-aws docs](https://marketplace.upbound.io/providers/crossplane-contrib/provider-aws/)).

**Option B — GCP / Azure**

- Install the corresponding Crossplane provider (e.g. provider-gcp, provider-azure) and configure credentials the same way.

### 3.3 Apply the DatabaseInstance API and composition

```bash
kubectl apply -f crossplane/xrd-database-instance.yaml
kubectl apply -f crossplane/composition-db-small-eu-west.yaml
```

Verify:

```bash
kubectl get xrd
kubectl get composition
```

You should see `databaseinstances.myplatform.io` and `db-small-eu-west`.

---

## 4. Gatekeeper (OPA policy enforcement)

### 4.1 Install Gatekeeper

```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.15/deploy/gatekeeper.yaml
# Wait for pods in gatekeeper-system
kubectl get pods -n gatekeeper-system
```

### 4.2 Apply the DatabaseInstance policy

```bash
kubectl apply -f opa/constraint-template-database-instance.yaml
# Wait for CRD to be ready
kubectl apply -f opa/constraint-database-instance.yaml
```

Verify:

```bash
kubectl get constrainttemplate
kubectl get databaseinstancepolicy
```

---

## 5. Argo CD (state engine)

### 5.1 Install Argo CD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# Optional: expose UI (e.g. port-forward or Ingress)
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Get initial admin password (if needed):

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 5.2 Configure the Application

1. Open `argocd/application.yaml`.
2. Replace **`REPO_URL`** with your repo URL, e.g. `https://github.com/yourorg/kubecon-eu.git`.
3. If the repo is **private**, add the repo in Argo CD (Settings → Repositories) and use SSH or a token; then ensure `application.yaml` uses that URL.

Apply the Application:

```bash
kubectl apply -f argocd/application.yaml
```

Verify in the Argo CD UI: the app `backend-first-platform` should appear and sync the `platform/` folder.

---

## 6. Backstage (portal view) — optional for “Portal Reveal”

### 6.1 Install Backstage

- Create a Backstage app (`npx create-app`) or use an existing one.
- Add the **Kubernetes** plugin and configure the backend to talk to your cluster (kubeconfig or in-cluster).

### 6.2 Point at the demo cluster

- Configure the Kubernetes plugin so it can list resources in the **same cluster and namespace** where Argo CD syncs (e.g. `default`).
- If you use custom resources, ensure the plugin can discover `databaseinstances.myplatform.io` (or use the generic resources view).

See `backstage/README.md` for the “portal observes the truth” talking point.

---

## 7. Pre-demo checklist

Before you run the demo:

| Item | Check |
|------|--------|
| Cluster up | `kubectl get nodes` |
| Crossplane + provider | `kubectl get provider`; provider is `HEALTHY` |
| XRD + Composition | `kubectl get xrd` and `kubectl get composition` |
| Provider credentials | ProviderConfig set; no credential errors in provider logs |
| Gatekeeper | Pods running in `gatekeeper-system` |
| ConstraintTemplate + Constraint | `kubectl get databaseinstancepolicy` |
| Argo CD | UI accessible; Application `backend-first-platform` exists |
| Repo URL in Application | `argocd/application.yaml` has correct `repoURL` (not `REPO_URL`) |
| Platform folder | `platform/prod-db.yaml` is the **happy path** (no `public: true`, `size: small`) |
| Backstage (optional) | Kubernetes plugin configured; can see cluster resources |
| Backup recording | 1080p recording of full flow (optional but recommended) |
| Warm resources | Consider pre-provisioning a DB so you don’t wait on stage |

---

## 8. Order of operations (summary)

1. Create cluster and Git repo.
2. Install Crossplane → install provider → configure credentials → apply XRD + Composition.
3. Install Gatekeeper → apply ConstraintTemplate → apply Constraint.
4. Install Argo CD → set `repoURL` in `argocd/application.yaml` → apply Application.
5. (Optional) Install and configure Backstage with Kubernetes plugin.
6. Run through the runbook once (`docs/RUNBOOK.md`) to verify Happy Path → Security Fail → Portal Reveal.

After this, you’re ready to run the app and the live demo.
