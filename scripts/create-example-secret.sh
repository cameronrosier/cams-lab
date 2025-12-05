#!/bin/bash
# Example script showing how to create and encrypt a secret for SOPS

cat <<EOF > /tmp/example-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: example-secret
  namespace: default
type: Opaque
stringData:
  username: myuser
  password: mypassword
  api-key: abc123xyz
EOF

echo "Created example secret at /tmp/example-secret.yaml"
echo ""
echo "To encrypt it with SOPS, run:"
echo "  sops --encrypt --in-place /tmp/example-secret.yaml"
echo ""
echo "After encryption, you can safely commit it to git"
