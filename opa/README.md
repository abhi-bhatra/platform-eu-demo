# OPA / Gatekeeper — DatabaseInstance Policy

## What it does

- **Denies** `DatabaseInstance` with `spec.public: true` → message: *"Database must be private!"*
- **Denies** `spec.size: extra-large` → message: *"Instance size ... is not allowed. Use small or medium."*

## Apply order

1. Install Gatekeeper (if not already): [Gatekeeper install](https://open-policy-agent.github.io/gatekeeper/website/docs/install/).
2. Apply the template, then the constraint:

```bash
kubectl apply -f constraint-template-database-instance.yaml
kubectl apply -f constraint-database-instance.yaml
```

## Demo (Step B)

After pushing a manifest with `public: true` or `size: extra-large`, Argo CD will try to sync. The apply will be rejected by the API server (Gatekeeper); Argo CD shows "Sync Failed" and the violation message appears in the sync result / event details.

## Rego bundle (standalone OPA)

If you use OPA outside Gatekeeper (e.g. Conftest, policy server), the same logic lives in the ConstraintTemplate `rego` block. You can copy that into a `.rego` file and run:

```bash
conftest test platform/prod-db.yaml --policy opa/policies/
```
