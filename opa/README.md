# OPA / Gatekeeper — DatabaseInstance Policy

## What it does

- **Denies** `DatabaseInstance` with `spec.public: true` → message: *"Database must be private!"*
- **Denies** `spec.size: extra-large` → message: *"Instance size ... is not allowed. Use small or medium."*

## Apply order

1. Install Gatekeeper (if not already): [Gatekeeper install](https://open-policy-agent.github.io/gatekeeper/website/docs/install/).
2. Apply template, wait for CRD, then apply constraint. **From repo root**, either run the script:

```bash
./opa/apply-in-order.sh
```

   or do it manually (run from repo root so paths work):

```bash
kubectl apply -f opa/constraint-template-database-instance.yaml
kubectl wait --for=condition=Established crd/databaseinstancepolicies.constraints.gatekeeper.sh --timeout=60s
kubectl apply -f opa/constraint-database-instance.yaml
```

   If the wait fails, the CRD wasn’t created. Check: `kubectl get crd | grep gatekeeper` and `kubectl get pods -n gatekeeper-system`.

## Demo (Step B)

After pushing a manifest with `public: true` or `size: extra-large`, Argo CD will try to sync. The apply will be rejected by the API server (Gatekeeper); Argo CD shows "Sync Failed" and the violation message appears in the sync result / event details.

## Rego bundle (standalone OPA)

If you use OPA outside Gatekeeper (e.g. Conftest, policy server), the same logic lives in the ConstraintTemplate `rego` block. You can copy that into a `.rego` file and run:

```bash
conftest test platform/prod-db.yaml --policy opa/policies/
```
