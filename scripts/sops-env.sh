#!/bin/bash
# Setup SOPS environment for working with encrypted secrets

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Check for age key in multiple locations
if [ -f "$REPO_ROOT/age.agekey" ]; then
    export SOPS_AGE_KEY_FILE="$REPO_ROOT/age.agekey"
    echo "✅ SOPS_AGE_KEY_FILE set to: $SOPS_AGE_KEY_FILE"
elif [ -f "$HOME/.config/sops/age/keys.txt" ]; then
    export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
    echo "✅ SOPS_AGE_KEY_FILE set to: $SOPS_AGE_KEY_FILE"
else
    echo "❌ No age key found!"
    echo ""
    echo "Please either:"
    echo "  1. Place your age.agekey in: $REPO_ROOT/age.agekey"
    echo "  2. Or copy it to: $HOME/.config/sops/age/keys.txt"
    echo ""
    echo "You can also manually set:"
    echo "  export SOPS_AGE_KEY_FILE=/path/to/age.agekey"
    return 1
fi

echo ""
echo "You can now use SOPS commands:"
echo "  sops clusters/home/apps/route53-ddns/route53-secret.yaml"
echo ""
echo "To make this permanent, add to your ~/.zshrc:"
echo "  export SOPS_AGE_KEY_FILE=\"$SOPS_AGE_KEY_FILE\""
