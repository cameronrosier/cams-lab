#!/bin/bash
set -e

echo "🔐 SOPS Quick Setup Script"
echo "=========================="
echo ""

# Check if age is installed
if ! command -v age &> /dev/null; then
    echo "❌ 'age' is not installed. Please install it first:"
    echo "   Ubuntu/Debian: sudo apt-get install age"
    echo "   macOS: brew install age"
    exit 1
fi

# Check if sops is installed
if ! command -v sops &> /dev/null; then
    echo "❌ 'sops' is not installed. Please install it first:"
    echo "   Ubuntu/Debian: https://github.com/getsops/sops/releases"
    echo "   macOS: brew install sops"
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ 'kubectl' is not installed or not in PATH"
    exit 1
fi

echo "✅ All required tools are installed"
echo ""

# Check if age key already exists
if [ -f "age.agekey" ]; then
    echo "⚠️  age.agekey already exists in current directory"
    read -p "Do you want to use it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Please remove or rename the existing age.agekey file"
        exit 1
    fi
else
    echo "📝 Generating new age key pair..."
    age-keygen -o age.agekey
    echo "✅ Age key pair generated and saved to age.agekey"
    echo ""
fi

# Extract public key
PUBLIC_KEY=$(grep 'public key:' age.agekey | awk '{print $4}')
echo "🔑 Your public key is:"
echo "   $PUBLIC_KEY"
echo ""

# Update .sops.yaml with the public key
if [ -f ".sops.yaml" ]; then
    echo "📝 Updating .sops.yaml with your public key..."
    sed -i.bak "s/age1[a-z0-9]*/$PUBLIC_KEY/g" .sops.yaml
    rm -f .sops.yaml.bak
    echo "✅ .sops.yaml updated"
    echo ""
fi

# Create Kubernetes secret
echo "📦 Creating sops-age secret in flux-system namespace..."
if kubectl get namespace flux-system &> /dev/null; then
    if kubectl get secret sops-age -n flux-system &> /dev/null; then
        echo "⚠️  sops-age secret already exists"
        read -p "Do you want to recreate it? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kubectl delete secret sops-age -n flux-system
            cat age.agekey | kubectl create secret generic sops-age \
              --namespace=flux-system \
              --from-file=age.agekey=/dev/stdin
            echo "✅ sops-age secret recreated"
        fi
    else
        cat age.agekey | kubectl create secret generic sops-age \
          --namespace=flux-system \
          --from-file=age.agekey=/dev/stdin
        echo "✅ sops-age secret created"
    fi
else
    echo "⚠️  flux-system namespace not found. Please run this after Flux is installed."
    echo "    You can create the secret later with:"
    echo "    cat age.agekey | kubectl create secret generic sops-age --namespace=flux-system --from-file=age.agekey=/dev/stdin"
fi

echo ""
echo "🎉 SOPS setup complete!"
echo ""
echo "⚠️  IMPORTANT: Keep age.agekey safe and DO NOT commit it to git!"
echo "    Recommendation: Store it in a password manager or secure vault"
echo ""
echo "Next steps:"
echo "1. Create a secret file (e.g., my-secret.yaml)"
echo "2. Encrypt it: sops --encrypt --in-place my-secret.yaml"
echo "3. Commit the encrypted file to git"
echo "4. Update your Flux Kustomizations to enable decryption (see SOPS-SETUP.md)"
echo ""
