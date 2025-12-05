#!/bin/bash
# Helper script to configure and encrypt Route53 DDNS secret

set -e

SECRET_FILE="clusters/home/apps/route53-ddns/route53-secret.yaml"

# Set SOPS_AGE_KEY_FILE if not already set
if [ -z "$SOPS_AGE_KEY_FILE" ]; then
    if [ -f "age.agekey" ]; then
        export SOPS_AGE_KEY_FILE="$(pwd)/age.agekey"
        echo "📝 Using age key: $SOPS_AGE_KEY_FILE"
    elif [ -f "$HOME/.config/sops/age/keys.txt" ]; then
        export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
        echo "📝 Using age key: $SOPS_AGE_KEY_FILE"
    else
        echo "❌ No age key found!"
        echo "   Please set SOPS_AGE_KEY_FILE or place age.agekey in the repo root"
        exit 1
    fi
fi

echo "🔧 Route53 DDNS Configuration"
echo "=============================="
echo ""

# Check if secret is already encrypted
if grep -q "sops:" "$SECRET_FILE" 2>/dev/null; then
    echo "⚠️  Secret is already encrypted!"
    echo ""
    read -p "Do you want to edit it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sops "$SECRET_FILE"
        echo "✅ Secret updated and re-encrypted"
    fi
    exit 0
fi

echo "Current configuration:"
echo "====================="
grep -E "HOSTED_ZONE_ID|RECORD_NAME|AWS_REGION" "$SECRET_FILE" | sed 's/^/  /'
echo ""

read -p "Do you want to update the configuration? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    read -p "Enter your Route53 Hosted Zone ID: " ZONE_ID
    read -p "Enter the DNS record name (e.g., home.example.com): " RECORD
    read -p "Enter AWS region [us-east-1]: " REGION
    REGION=${REGION:-us-east-1}
    
    # Update the secret file
    sed -i "s/HOSTED_ZONE_ID: \".*\"/HOSTED_ZONE_ID: \"$ZONE_ID\"/" "$SECRET_FILE"
    sed -i "s/RECORD_NAME: \".*\"/RECORD_NAME: \"$RECORD\"/" "$SECRET_FILE"
    sed -i "s/AWS_REGION: \".*\"/AWS_REGION: \"$REGION\"/" "$SECRET_FILE"
    
    echo "✅ Configuration updated"
fi

echo ""
echo "📝 Encrypting secret with SOPS..."

if ! command -v sops &> /dev/null; then
    echo "❌ sops is not installed. Please install it first:"
    echo "   brew install sops  (or download from GitHub)"
    exit 1
fi

sops --encrypt --in-place "$SECRET_FILE"

echo "✅ Secret encrypted successfully!"
echo ""
echo "Next steps:"
echo "1. Review the changes: git diff"
echo "2. Commit: git add clusters/home/apps/ && git commit -m 'Add Route53 DDNS service'"
echo "3. Push: git push"
echo "4. Monitor: kubectl get all -n route53-ddns"
