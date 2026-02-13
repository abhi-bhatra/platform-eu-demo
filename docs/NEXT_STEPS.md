# Next Steps — You Have: k3s + Crossplane

You already have:
- **k3s** cluster (1 control plane)
- **Crossplane** installed via Helm
- **Personal GitHub** (you can create the repo)

Do the following in order. You can run the **full demo without AWS** by using the local demo composition (ConfigMap); optionally add AWS later for real RDS.

---

## Step 1. Create the GitHub repo and push this code

1. On GitHub, create a new repository (e.g. `kubecon-eu`). Do **not** add a README (you already have one).
2. In this project folder, add the remote and push:

```bash
cd /Users/abhinav/kodekloud/kubecon-eu
git init
git add .
git commit -m "Backend-First IDP demo"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/kubecon-eu.git
git push -u origin main
```

Replace `YOUR_USERNAME` with your GitHub username. Note the repo URL — you’ll need it for Argo CD (e.g. `https://github.com/YOUR_USERNAME/kubecon-eu.git`).

---

## Step 2. Crossplane: DatabaseInstance API + composition (no AWS)

Use the **demo composition** so the demo works on k3s without any cloud account.

### 2.1 Install provider-kubernetes (talks to your k3s cluster)

**Do not** use the repo’s `package/crossplane.yaml` — that uses `meta.pkg.crossplane.io/v1` (for building packages), which your cluster doesn’t have. Use the install manifest in this repo instead:

```bash
kubectl apply -f crossplane/provider-kubernetes-install.yaml
```

Wait until the provider is healthy (can take 1–2 minutes):

```bash
kubectl get providers.pkg.crossplane.io
# provider-kubernetes should show HEALTHY
```

### 2.2 Install the patch-and-transform function (required for pipeline compositions)

Crossplane v2 uses **pipeline** mode for Compositions. Install the function first:

```bash
kubectl apply -f crossplane/function-patch-and-transform-install.yaml
```

Wait until it’s healthy:

```bash
kubectl get functions.pkg.crossplane.io
# function-patch-and-transform should show HEALTHY
```

### 2.3 Default ProviderConfig for provider-kubernetes (in-cluster)

Create a config so the provider uses the same cluster (e.g. your k3s):

```bash
kubectl apply -f - <<'EOF'
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: InjectedIdentity
EOF
```

### 2.4 Apply the XRD and both compositions

```bash
kubectl apply -f crossplane/xrd-database-instance.yaml
kubectl apply -f crossplane/composition-db-small-eu-west.yaml   # AWS – optional for later
kubectl apply -f crossplane/composition-db-demo-local.yaml      # Demo – no cloud
```

The XRD’s default composition is still `db-small-eu-west` (AWS). For the **demo without AWS**, the claim will override it (see Step 4).

Verify:

```bash
kubectl get xrd
kubectl get composition
```

You should see `databaseinstances.myplatform.io`, `db-small-eu-west`, and `db-demo-local`.

---

## Step 3. Gatekeeper (OPA)

```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.15/deploy/gatekeeper.yaml
```

Wait for pods:

```bash
kubectl get pods -n gatekeeper-system
```

Then apply the DatabaseInstance policy. **Order matters:** the ConstraintTemplate creates the CRD; only then can you create the Constraint:

```bash
kubectl apply -f opa/constraint-template-database-instance.yaml
# Wait for Gatekeeper to create the DatabaseInstancePolicy CRD (10–30s)
kubectl wait --for=condition=Established crd/databaseinstancepolicies.constraints.gatekeeper.sh --timeout=60s
kubectl apply -f opa/constraint-database-instance.yaml
```

Verify:

```bash
kubectl get constrainttemplate
kubectl get databaseinstancepolicy
```

---

## Step 4. Argo CD

### 4.1 Install Argo CD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait for pods, then expose the UI (see below for **remote server**).

**Argo CD is on a remote server** (you can’t open a browser on the server):

- **Bind port-forward to all interfaces**  
  On the **remote server**, run:
  ```bash
  kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8080:443
  ```
  Then from your local browser open https://REMOTE_SERVER_IP:8080.  
  Ensure port 8080 is allowed in the server’s firewall/security group. Prefer Option A if the server is on the internet.

Login: `admin`, password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

### 4.2 Point Argo CD at your GitHub repo

Edit `argocd/application.yaml`: set `repoURL` to your repo (e.g. `https://github.com/YOUR_USERNAME/kubecon-eu.git`).

If the repo is **public**, apply the Application:

```bash
kubectl apply -f argocd/application.yaml
```

If the repo is **private**, add the repo in Argo CD first (Settings → Repositories → Connect repo with your GitHub token or SSH key), then apply `argocd/application.yaml`.

---

## Step 5. Use the demo composition in the platform manifest (no AWS)

So that Crossplane doesn’t try to use AWS, the claim in `platform/` must use the **demo** composition. Edit `platform/prod-db.yaml` and add `compositionRef`:

```yaml
apiVersion: myplatform.io/v1
kind: DatabaseInstance
metadata:
  name: checkout-db
spec:
  compositionRef:
    name: db-demo-local
  size: small
  region: eu-west-1
  team: checkout
```

Commit and push:

```bash
git add platform/prod-db.yaml
git commit -m "Use demo composition (no AWS)"
git push
```

Argo CD will sync and Crossplane will create a **ConfigMap** named `checkout-db` in the `default` namespace (no RDS, no cloud).

---

## Step 6. Verify the full flow

1. **Argo CD**: In the UI, open the `backend-first-platform` app. It should sync and show the `DatabaseInstance` (and the ConfigMap created by Crossplane).
2. **Happy path**: Already done if sync is green.
3. **Security gate**: Edit `platform/prod-db.yaml`, set `spec.public: true`, push. Argo CD should try to sync and **fail** with the Gatekeeper message.
4. **Portal reveal**: Remove `public: true`, push. Sync succeeds again. (Backstage is optional; you can show the ConfigMap in the cluster as “the backend built it.”)

---

## Optional: Add AWS later for real RDS

When you want to show real cloud provisioning:

1. Install **provider-aws** and set credentials + `ProviderConfig` (see `docs/SETUP.md`).
2. In `platform/prod-db.yaml` remove `compositionRef` (so the XRD default `db-small-eu-west` is used), or set `compositionRef.name: db-small-eu-west`.
3. Push; Crossplane will then create AWS resources (VPC, RDS, IAM). Use a “warm” resource or pre-provision for the talk so you don’t wait on stage.

---

## Quick reference

| Done | Step |
|------|------|
| ☐ | 1. Create GitHub repo, push this code |
| ☐ | 2. Install provider-kubernetes, function-patch-and-transform, ProviderConfig, apply XRD + compositions |
| ☐ | 3. Install Gatekeeper, apply ConstraintTemplate + Constraint |
| ☐ | 4. Install Argo CD, set repoURL, apply Application |
| ☐ | 5. Add `compositionRef: name: db-demo-local` to `platform/prod-db.yaml`, push |
| ☐ | 6. Verify sync → breach (public: true) → fix → sync |

After that, you’re ready to run the demo on k3s with no AWS required.
