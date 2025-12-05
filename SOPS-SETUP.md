# SOPS Setup Guide for Flux

This guide will help you set up SOPS (Secrets OPerationS) with Mozilla Age encryption for managing secrets in your Flux GitOps repository.

## Prerequisites

- `age` - Modern encryption tool
- `sops` - Secrets encryption tool
- `kubectl` - To create secrets in your cluster

## Step 1: Install Required Tools

```bash
# Install age
sudo apt-get update && sudo apt-get install -y age

# Or on macOS
brew install age

# Install sops
# Linux (AMD64)
wget https://github.com/getsops/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64 -O /usr/local/bin/sops
chmod +x /usr/local/bin/sops

# Or on macOS
brew install sops
```

## Step 2: Generate Age Key Pair

Generate a new age key pair for encrypting secrets:

```bash
# Create age key
age-keygen -o age.agekey

# Display the public key (you'll need this)
grep 'public key:' age.agekey
```

**IMPORTANT**: 
- Save `age.agekey` somewhere safe (like a password manager)
- **DO NOT** commit `age.agekey` to git
- The `.gitignore` file should already exclude `*.agekey` files

## Step 3: Configure SOPS to Find Your Age Key

SOPS needs to know where your private key is. Choose one of these options:

### Option 1: Add to your shell profile (Recommended)
```bash
# For zsh
echo 'export SOPS_AGE_KEY_FILE="$HOME/checkouts/cams-lab/age.agekey"' >> ~/.zshrc
source ~/.zshrc

# For bash
echo 'export SOPS_AGE_KEY_FILE="$HOME/checkouts/cams-lab/age.agekey"' >> ~/.bashrc
source ~/.bashrc
```

### Option 2: Move to standard SOPS location
```bash
mkdir -p ~/.config/sops/age
cp age.agekey ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

### Option 3: Set for current session only
```bash
export SOPS_AGE_KEY_FILE="$(pwd)/age.agekey"
```

### Option 4: Use the helper script
```bash
source scripts/sops-env.sh
```

## Step 4: Create SOPS Configuration

The `.sops.yaml` file at the repository root tells SOPS which files to encrypt and with which key.

This has already been created at the repository root. Update the `age:` field with your public key from step 2.

## Step 4: Create Kubernetes Secret with Age Key

Flux needs the age private key to decrypt secrets. Create a secret in your cluster:

```bash
# Create the sops-age secret in the flux-system namespace
cat age.agekey | kubectl create secret generic sops-age \
  --namespace=flux-system \
  --from-file=age.agekey=/dev/stdin

# Verify it was created
kubectl get secret -n flux-system sops-age
```

## Step 5: Configure Flux to Use SOPS

Update the Flux Kustomization resources to enable decryption. This is done by adding a `decryption` section to any Kustomization that manages encrypted secrets.

Example:
```yaml
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
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

## Step 6: Create and Encrypt a Secret

```bash
# Create a secret YAML file (don't commit unencrypted!)
cat <<EOF > /tmp/my-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-app-secrets
  namespace: default
type: Opaque
stringData:
  username: admin
  password: super-secret-password
EOF

# Encrypt it with SOPS
sops --encrypt --in-place /tmp/my-secret.yaml

# Now the file is encrypted and safe to commit
cp /tmp/my-secret.yaml clusters/home/apps/my-app/secret.yaml
```

## Step 7: Working with Encrypted Secrets

### Encrypt a file:
```bash
sops --encrypt --in-place path/to/secret.yaml
```

### Decrypt and view a file (doesn't modify the file):
```bash
sops --decrypt path/to/secret.yaml
```

### Edit an encrypted file:
```bash
sops path/to/secret.yaml
```
This will decrypt it in your editor, and re-encrypt when you save.

### Update encryption keys:
```bash
sops updatekeys path/to/secret.yaml
```

## Troubleshooting

### Check if Flux can decrypt:
```bash
kubectl logs -n flux-system deploy/kustomize-controller -f
```

### Manually test decryption in cluster:
```bash
kubectl run -it --rm sops-test --image=alpine --restart=Never -- sh
# Inside the pod, install sops and age, then test
```

### Common issues:
- **"no key found"**: Make sure the `sops-age` secret exists in `flux-system` namespace
- **"MAC mismatch"**: The file was modified after encryption, re-encrypt it
- **Flux not decrypting**: Add `decryption` section to Kustomization resource

## Security Best Practices

1. ✅ **DO** keep your `age.agekey` file in a secure location (password manager, vault)
2. ✅ **DO** commit encrypted files (`.yaml` files encrypted by SOPS)
3. ✅ **DO** use different keys for different environments (dev/staging/prod)
4. ❌ **DON'T** commit unencrypted secrets
5. ❌ **DON'T** commit your `*.agekey` files
6. ❌ **DON'T** share your private key in plain text

## File Naming Convention

Consider using a consistent naming for encrypted secrets:
- `*-secret.yaml` - For encrypted Secret resources
- Add them to your `.sops.yaml` rules

## References

- [Flux SOPS Guide](https://fluxcd.io/flux/guides/mozilla-sops/)
- [SOPS Documentation](https://github.com/getsops/sops)
- [Age Encryption](https://github.com/FiloSottile/age)
