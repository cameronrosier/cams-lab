# Flux Kustomization with SOPS Decryption

This directory contains examples of how to configure Flux Kustomizations to decrypt SOPS-encrypted secrets.

## Example 1: Simple Kustomization with SOPS

```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps
  namespace: flux-system
spec:
  interval: 10m
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./clusters/home/apps
  prune: true
  wait: true
  timeout: 5m
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

## Example 2: Infrastructure Kustomization with SOPS

```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: infra-configs
  namespace: flux-system
spec:
  interval: 10m
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./clusters/home/infra
  prune: true
  decryption:
    provider: sops
    secretRef:
      name: sops-age
  dependsOn:
    - name: flux-system
```

## Key Points

1. **decryption.provider**: Must be set to `sops`
2. **decryption.secretRef.name**: Must reference the Kubernetes secret containing your age key (typically `sops-age`)
3. The secret must exist in the same namespace as the Kustomization (typically `flux-system`)

## Updating Existing Kustomizations

To add SOPS decryption to an existing Kustomization, simply add the `decryption` section:

```yaml
spec:
  # ... existing spec fields ...
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

## Testing

After updating your Kustomizations:

1. Commit and push changes
2. Watch Flux reconciliation:
   ```bash
   flux get kustomizations --watch
   ```
3. Check for errors:
   ```bash
   kubectl logs -n flux-system deploy/kustomize-controller -f
   ```
