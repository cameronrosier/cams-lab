# SOPS Configuration Directory

This directory contains SOPS-related documentation and examples.

## Quick Start

1. **Run the setup script** (from repository root):
   ```bash
   ./scripts/setup-sops.sh
   ```

2. **The script will**:
   - Check if required tools are installed (age, sops, kubectl)
   - Generate an age key pair if needed
   - Update `.sops.yaml` with your public key
   - Create the `sops-age` secret in your Kubernetes cluster

3. **Keep your private key safe**:
   - The private key is saved as `age.agekey` in the repository root
   - This file is excluded from git via `.gitignore`
   - Store it securely (password manager, vault, etc.)

## Files in This Directory

- `flux-kustomization-examples.md` - Examples of Flux Kustomizations configured for SOPS decryption

## Files in Repository Root

- `.sops.yaml` - SOPS configuration defining which files to encrypt and with which keys
- `SOPS-SETUP.md` - Comprehensive setup guide and reference documentation

## Common Commands

```bash
# Encrypt a secret file
sops --encrypt --in-place path/to/secret.yaml

# Decrypt and view (doesn't modify file)
sops --decrypt path/to/secret.yaml

# Edit an encrypted file
sops path/to/secret.yaml

# Check SOPS configuration
sops --help
```

## Workflow

1. Create a regular Kubernetes Secret YAML file
2. Encrypt it with SOPS: `sops --encrypt --in-place secret.yaml`
3. Commit the encrypted file to git (safe!)
4. Flux will automatically decrypt it when applying to the cluster

## Security Notes

- ✅ Encrypted secrets are safe to commit
- ❌ Never commit `*.agekey` files
- ✅ Only encrypt the `data` or `stringData` fields (configured in `.sops.yaml`)
- ✅ Metadata remains unencrypted for GitOps visibility
