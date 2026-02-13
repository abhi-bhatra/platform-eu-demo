# Backstage — Portal View

## Role in the demo

Backstage is the **View**: it does not create resources. It discovers what already exists in the cluster (via the Kubernetes plugin). After Step C, the new `DatabaseInstance` / DB appears in the Software Catalog automatically — *"We didn't click Create; the backend built it, the portal observed the truth."*

## Setup

1. Install Backstage (create-app or your existing instance).
2. Add the **Kubernetes** plugin and configure it to talk to the same cluster where Argo CD / Crossplane run.
3. Ensure the plugin can list Custom Resources (e.g. `databaseinstances.myplatform.io`) in the target namespace(s).

## Discovery

- If your Backstage catalog is CRD-aware, register the `DatabaseInstance` kind so it appears as a catalog entity type.
- Alternatively, use the Kubernetes plugin’s “Resources” view to show cluster resources; the new DB will appear there after a successful sync.

## Kicker line

*"The UI is a lens. The real state lives in Git. The backend is the platform."*
