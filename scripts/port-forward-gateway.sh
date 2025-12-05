#!/bin/bash
# Local port forward to make gateway accessible on localhost:8080
# This is useful for development and testing

NODEPORT=$(kubectl get svc -n default cilium-gateway-home-gateway -o jsonpath='{.spec.ports[0].nodePort}')
CONTROLLER_IP="192.168.2.206"

echo "Starting port forward from localhost:8080 to gateway..."
echo "Access your services at: http://localhost:8080/"
echo ""
echo "Example:"
echo "  curl -H 'Host: echo.local' http://localhost:8080/"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Use socat if available, otherwise use SSH port forwarding
if command -v socat &> /dev/null; then
    socat TCP-LISTEN:8080,fork,reuseaddr TCP:$CONTROLLER_IP:$NODEPORT
elif command -v ssh &> /dev/null; then
    # Try SSH tunnel (requires SSH access to the node)
    ssh -L 8080:localhost:$NODEPORT pi@$CONTROLLER_IP -N
else
    echo "Error: Neither socat nor ssh found. Please install one of them."
    echo ""
    echo "On Ubuntu/Debian: sudo apt install socat"
    echo "On macOS: brew install socat"
    exit 1
fi
