#!/bin/bash

# Default namespace
default_namespace="dotcms-dev"
grace_period=45 # Grace period in seconds before restore

# Function to check prerequisites
check_prerequisites() {
  echo "🔍 Validating prerequisites..."
  
  # Check kubectl
  if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed."
    exit 1
  fi

  # Check helm
  if ! command -v helm &> /dev/null; then
    echo "❌ Error: helm is not installed."
    exit 1
  fi

  # Check Kubernetes cluster
  if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: Kubernetes cluster is not running."
    exit 1
  fi

  echo "✅ All prerequisites are valid."
}

# Function to stop dotCMS services
stop_dotcms_services() {
  echo "🛑 Stopping dotCMS services in $namespace..."
  echo ""
  # Scale down dotcms StatefulSet
  kubectl scale statefulset/dotcms-cluster --replicas=0 -n "$namespace"

  # Scale down opensearch Deployment
  kubectl scale deployment/opensearch --replicas=0 -n "$namespace"

  # Scale down db Deployment
  kubectl scale deployment/db --replicas=0 -n "$namespace"
  echo ""
  echo "🚫 dotCMS services stopped."
}

# Function to start dotCMS services
start_dotcms_services() {
  echo "🔄 Starting dotCMS services in $namespace..."
  echo ""
  # Scale up db Deployment
  kubectl scale deployment/db --replicas=1 -n "$namespace"
  sleep 10

  # Scale up opensearch Deployment
  kubectl scale deployment/opensearch --replicas=1 -n "$namespace"
  sleep 10

  # Scale up dotcms StatefulSet
  kubectl scale statefulset/dotcms-cluster --replicas=1 -n "$namespace"
  echo ""
  echo "✅ dotCMS services started."
}

# Function to run backup
run_backup() {
  local hostpath=$1
  local backupfile=$2
  echo "📦 Running backup operation..."
  echo ""
  # Use Helm values for backup
  helm upgrade --install dotcms-backup ./backup \
    --namespace "$namespace" \
    --set operation=backup \
    --set hostPath="$hostpath" \
    --set fileName="$backupfile"
  echo ""
  echo "✅ Backup operation completed."
}

# Function to run restore
run_restore() {
  local hostpath=$1
  local backupfile=$2
  echo "🗄️  Running restore operation..."

  # Validate that the backup file exists
  if [ ! -f "$hostpath/$backupfile" ]; then
    echo "❌ Error: Backup file $hostpath/$backupfile does not exist."
    exit 1
  fi

  # Stop dotCMS services before restore
  stop_dotcms_services

  # Add a grace period before restore
  echo "⏳ Waiting for $grace_period seconds to ensure services are fully stopped..."
  sleep $grace_period
  echo ""
  # Use Helm values for restore
  helm upgrade --install dotcms-restore ./backup \
    --namespace "$namespace" \
    --set operation=restore \
    --set hostPath="$hostpath" \
    --set fileName="$backupfile"
  echo ""
  echo "✅ Restore operation completed."

  # Start dotCMS services after restore
  start_dotcms_services
}

# Function to cleanup Helm releases
cleanup_releases() {
  echo "🧹 Cleaning up backup and restore releases in $namespace..."

  helm uninstall dotcms-backup --namespace "$namespace" || echo "⚠️ Backup release not found."
  helm uninstall dotcms-restore --namespace "$namespace" || echo "⚠️ Restore release not found."

  echo "✅ Cleanup completed successfully."
}

# Main script logic
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <operation> <hostpath> <filename> [namespace]"
  echo "operation: 'backup', 'restore', or 'cleanup'"
  echo "hostpath: Path to the directory for backup or restore (not required for cleanup)"
  echo "filename: Name of the backup file (required for backup and restore)"
  echo "namespace (optional): Kubernetes namespace where the dotCMS cluster is deployed (default: $default_namespace)"
  exit 1
fi

operation=$1
hostpath=$2
filename=$3
namespace=${4:-$default_namespace} # Use default namespace if not provided

# Validate prerequisites
check_prerequisites

# Execute operation
case $operation in
  backup)
    if [ -z "$filename" ]; then
      echo "❌ Error: filename is required for backup operation."
      exit 1
    fi
    run_backup "$hostpath" "$filename"
    ;;
  restore)
    if [ -z "$filename" ]; then
      echo "❌ Error: filename is required for restore operation."
      exit 1
    fi
    run_restore "$hostpath" "$filename"
    ;;
  cleanup)
    cleanup_releases
    ;;
  *)
    echo "❌ Error: Invalid operation '$operation'. Must be 'backup', 'restore', or 'cleanup'."
    exit 1
    ;;
esac
