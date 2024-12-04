#!/bin/bash

# Constants
NAMESPACE="dotcms-dev"
TLS_SECRET="developer-certificate-secret"
HOSTNAME="dotcms.local"
LOCALHOST="127.0.0.1"
CERT_DIR="$HOME/.dotcms/certificates"
CERT_FILE="${CERT_DIR}/${HOSTNAME}.pem"
KEY_FILE="${CERT_DIR}/${HOSTNAME}-key.pem"
INGRESS_TIMEOUT=300  # 5 minutes timeout

# Helper function to check if a command exists
function check_command() {
  if ! command -v $1 &> /dev/null; then
    echo "❌ $1 is not installed. Installing..."
    brew install $1 && echo "✅ $1 installed successfully."
  else
    echo "✅ $1 is already installed."
  fi
}

# Ensure the namespace exists or create it
function ensure_namespace_exists() {
  if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo "⏳ Namespace '$NAMESPACE' does not exist. Creating it..."
    kubectl create namespace $NAMESPACE && echo "✅ Namespace '$NAMESPACE' created successfully."
  else
    echo "✅ Namespace '$NAMESPACE' already exists."
  fi
}

# Check if Ingress Controller is installed and ready
function is_ingress_controller_installed() {
  # Use kubectl get pods -o json to verify pod readiness
  kubectl get pods -n ingress-nginx -o json 2>/dev/null | jq -e \
    '.items[] | select(.status.phase == "Running") | .status.conditions[] | select(.type == "Ready" and .status == "True")' >/dev/null
}

# Wait for the Ingress Controller to be ready
function wait_for_ingress_controller() {
  echo "⏳ Waiting for the NGINX Ingress Controller to be ready..."
  local timeout=$INGRESS_TIMEOUT
  local elapsed=0
  while [[ $elapsed -lt $timeout ]]; do
    if is_ingress_controller_installed; then
      echo "✅ Ingress Controller is ready!"
      return 0
    fi
    sleep 10
    elapsed=$((elapsed + 10))
    echo "⏳ Waiting for Ingress Controller pods... ($elapsed seconds elapsed)"
  done
  echo "❌ Error: Ingress Controller did not become ready within $timeout seconds."
  exit 1
}

# Check if the TLS secret exists in Kubernetes
function secret_exists() {
  kubectl get secret $TLS_SECRET -n $NAMESPACE &> /dev/null
}

# Generate a hash of the current certificate
function generate_cert_hash() {
  if [ -f "$CERT_FILE" ]; then
    openssl x509 -noout -modulus -in "$CERT_FILE" | openssl md5 | awk '{print $2}'
  else
    echo "no-cert"
  fi
}

# Get the hash of the stored Kubernetes secret certificate
function get_secret_cert_hash() {
  if secret_exists; then
    kubectl get secret $TLS_SECRET -n $NAMESPACE -o jsonpath='{.data.tls\.crt}' | base64 --decode | openssl x509 -noout -modulus | openssl md5 | awk '{print $2}'
  else
    echo "no-secret"
  fi
}

# Update the Kubernetes TLS secret if the certificate changes or expires
function update_tls_secret() {
  ensure_namespace_exists  # Ensure the namespace exists before updating the secret

  local cert_hash=$(generate_cert_hash)
  local secret_hash=$(get_secret_cert_hash)

  if [[ "$cert_hash" != "$secret_hash" ]]; then
    echo "⏳ Updating TLS Secret '$TLS_SECRET' in namespace '$NAMESPACE'..."
    kubectl delete secret $TLS_SECRET -n $NAMESPACE &> /dev/null || echo "✅ No existing secret to delete."
    kubectl create secret tls $TLS_SECRET \
      --cert="$CERT_FILE" \
      --key="$KEY_FILE" \
      -n $NAMESPACE && echo "✅ TLS Secret updated successfully."
  else
    echo "✅ TLS Secret is already up-to-date."
  fi
}

# Start of the script
echo ""
echo "🚀 Starting setup for DotCMS development environment on macOS..."
echo ""

echo "🔍 Checking required tools..."
echo ""
# Ensure Homebrew is installed
if ! command -v brew &> /dev/null; then
  echo "❌ Homebrew is not installed. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && echo "✅ Homebrew installed successfully."
else
  echo "✅ Homebrew is already installed."
fi

# Check and install required tools
check_command kubectl
check_command helm
check_command mkcert
check_command jq  # Validate jq is installed
echo ""

echo "🔧 K8s local setup..." 
echo ""
# Enable Kubernetes in Docker Desktop
if ! kubectl cluster-info &> /dev/null; then
  echo "❌ Kubernetes cluster not found. Starting Docker Desktop..."
  open --background -a Docker
  echo "⏳ Waiting for Docker Desktop to start Kubernetes..."
  sleep 30  # Wait for Docker Desktop to initialize Kubernetes
  if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: Kubernetes cluster is not available. Ensure Docker Desktop has Kubernetes enabled."
    exit 1
  fi
else
  echo "✅ Kubernetes cluster is already running."
fi

# Install NGINX Ingress Controller
if is_ingress_controller_installed; then
  echo "✅ NGINX Ingress Controller is already installed. Verifying readiness..."
  wait_for_ingress_controller
else
  echo "⏳ Installing NGINX Ingress Controller..."
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
  wait_for_ingress_controller
fi

# Generate TLS certificate using mkcert
if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
  echo "⏳ Generating TLS certificate using mkcert..."
  mkdir -p "$CERT_DIR"
  mkcert -install
  mkcert -cert-file "$CERT_FILE" -key-file "$KEY_FILE" $HOSTNAME && echo "✅ Certificate generated successfully."
else
  echo "✅ TLS certificate already exists."
fi

# Update the Kubernetes TLS secret
update_tls_secret

# Configure /etc/hosts file
if ! grep -q "$HOSTNAME" /etc/hosts; then
  echo "⏳ Adding '$HOSTNAME' to /etc/hosts..."
  sudo sh -c "echo '$LOCALHOST $HOSTNAME' >> /etc/hosts" && echo "✅ '$HOSTNAME' added to /etc/hosts."
else
  echo "✅ '$HOSTNAME' is already configured in /etc/hosts."
fi

echo ""
echo "🎉 Setup complete! Your local environment is ready for running DotCMS through the Helm Chart."